import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/shared/ds/notification_badge/p_notification_badge.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

/// Line 의 폭 — fill(기본 — 칸을 똑같이 나눈다, 5개 이하 · 짧은 글) · hug(글만큼 — 6개 이상이거나 글이 길 때, 넘치면 가로
/// 스크롤).
enum PTabsLayout { fill, hug }

/// Line 의 크기 — small 40 · 글 t4 14(기본) · medium 44 · 글 t5 16.
enum PTabsSize { small, medium }

/// Chip Tabs 의 변형 — solid(기본 — 화면 전체를 바꾸는 2차 탭, Chip Solid) · outline(일부 내용을 바꾸는 2차 탭, Chip Outline
/// Strong).
enum PChipTabsVariant { solid, outline }

/// Chip Tabs 의 크기 — medium 36(기본 — 좁은 자리 · 스크롤 중간의 서브 내용) · large 40(화면 전체를 바꾸는 탭).
enum PChipTabsSize { medium, large }

/// 탭 하나 — 값 · 글 · 막힘 · 알림 점. 글은 이름만 쓴다(개수를 붙이지 않는다).
@immutable
class PTab<T> {
  const PTab({
    required this.value,
    required this.label,
    this.enabled = true,
    this.notification = false,
  });

  /// 이 탭의 값 — 목록의 값과 같으면 고른 탭이다. 글이 아니라 바뀌지 않는 id 를 쓴다.
  final T value;

  /// 글 — 이름만. 줄바꿈 · 말줄임하지 않고 탭이 넓어진다.
  final String label;

  /// false 면 이 탭만 막힌다 — 누를 수 없고 키보드 이동에서 건너뛴다.
  final bool enabled;

  /// 새 소식이 있는 탭의 알림 점 — 안 고른 탭에만 그린다(내용을 보면 사라진다). 한 목록에 하나만 단다.
  final bool notification;
}

/// 알림 점 — 6px 원, 브랜드 글자색(fg-brand — 다크에서 밝은 짝).
const double _dotSize = 6;

/// Line 알림 점 — 글 끝에서 2, 글 위쪽에 띄워 탭 폭을 넓히지 않는다.
const double _lineDotGap = 2;

/// 알림 점의 키 — 테스트가 찾는다.
const ValueKey<String> _lineDotKey = ValueKey('tabs-dot');
const ValueKey<String> _chipDotKey = ValueKey('chip-tabs-dot');

/// Line 의 크기마다의 값(tabs.yaml 의 크기 규칙) — 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
({double height, TextStyle text, double lineHeight}) tabsMetrics(
  PTabsSize size,
) => switch (size) {
  PTabsSize.small => (height: 40, text: PTypography.t4, lineHeight: 19),
  PTabsSize.medium => (height: 44, text: PTypography.t5, lineHeight: 22),
};

// ── 탭 목록의 키보드 ─────────────────────────────────────────────────────────

/// 탭 목록의 키보드 — 탭마다 포커스 노드를 쥐고, ← → 로 이웃 탭으로 옮기며 바로 고른다(끝에서 처음으로 돌고, 막힌 탭은
/// 건너뛴다). Home · End 는 첫 · 마지막 탭(막히지 않은). Tab 은 목록에서 고른 탭 하나에만 선다 — 나머지 탭은 순서에서
/// 빠지고 화살표로만 닿는다(웹 roving tabindex). [PTabs] · [PChipTabs] 가 쓴다.
class TabListFocus extends StatefulWidget {
  const TabListFocus({
    super.key,
    required this.count,
    required this.enabledAt,
    required this.onSelect,
    required this.builder,
  });

  final int count;
  final bool Function(int index) enabledAt;

  /// 화살표로 옮긴 탭을 고른다.
  final void Function(int index) onSelect;

  /// 탭마다의 포커스 노드를 받아 목록을 만든다.
  final Widget Function(BuildContext context, List<FocusNode> nodes) builder;

  @override
  State<TabListFocus> createState() => _TabListFocusState();
}

class _TabListFocusState extends State<TabListFocus> {
  final List<FocusNode> _nodes = [];

  void _sync() {
    while (_nodes.length < widget.count) {
      _nodes.add(FocusNode(debugLabel: 'PTab#${_nodes.length}'));
    }
    while (_nodes.length > widget.count) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(TabListFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  int _step(int from, int delta) {
    final n = widget.count;
    for (var i = 1; i <= n; i++) {
      final next = (from + delta * i) % n;
      final wrapped = next < 0 ? next + n : next;
      if (widget.enabledAt(wrapped)) return wrapped;
    }
    return from;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final at = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (at < 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    int? next;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      next = _step(at, rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      next = _step(at, rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      next = _step(-1, 1);
    } else if (key == LogicalKeyboardKey.end) {
      next = _step(widget.count, -1);
    }
    if (next == null) return KeyEventResult.ignored;
    if (next != at) {
      widget.onSelect(next);
      _nodes[next].requestFocus();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: widget.builder(context, _nodes),
    );
  }
}

/// 가로 스크롤 목록에서 고른 탭이 밖이면 가까운 쪽으로 [pad] 를 두고 스크롤한다 — Hug 16 · Chip Tabs 24(웹
/// scroll-padding). 처음 그릴 때는 바로, 그 뒤로는 부드럽게(모션 줄이기면 바로).
void revealInScroll(
  BuildContext context,
  ScrollController controller,
  Rect tab,
  double pad, {
  required bool animate,
}) {
  if (!controller.hasClients) return;
  final position = controller.position;
  if (position.maxScrollExtent <= 0) return;
  final start = tab.left - pad;
  final end = tab.right + pad - position.viewportDimension;
  final offset = position.pixels;
  final double? to = offset > start
      ? start
      : offset < end
      ? end
      : null;
  if (to == null) return;
  final target = to.clamp(0.0, position.maxScrollExtent);
  final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  if (animate && !reduceMotion) {
    controller.animateTo(target, duration: PDuration.d4, curve: PEasing.easing);
  } else {
    controller.jumpTo(target);
  }
}

/// 탭 이름 뒤에 붙는 자리 — "탭 2/3"(en "Tab 2 of 3"). Flutter(Android · iOS)는 tab 역할을 화면 읽기 도구에 전달하지 않아 이름으로
/// 알린다(Material TabBar 와 같다). 선택됨은 selected 상태가 알린다.
String tabPositionName(BuildContext context, int index, int count) =>
    dsL(context)?.dsTabPosition(index + 1, count) ?? '탭 ${index + 1}/$count';

/// Fill 의 탭 폭 — 칸을 똑같이 나누되 글(글 + 좌우 10)이 칸보다 긴 탭은 글 폭으로 넓어지고, 나머지 탭이 남은 폭을 똑같이 나눈다.
/// 합이 줄 폭 안일 때만 쓴다(넘치면 가로 스크롤).
@visibleForTesting
List<double> fillTabWidths(List<double> naturals, double total) {
  final n = naturals.length;
  final fixed = List<bool>.filled(n, false);
  final widths = List<double>.filled(n, 0);
  var changed = true;
  while (changed) {
    changed = false;
    var room = total;
    var free = 0;
    for (var i = 0; i < n; i++) {
      if (fixed[i]) {
        room -= naturals[i];
      } else {
        free++;
      }
    }
    if (free == 0) break;
    final share = room / free;
    for (var i = 0; i < n; i++) {
      if (!fixed[i] && naturals[i] > share + 0.001) {
        fixed[i] = true;
        changed = true;
      }
    }
  }
  var room = total;
  var free = 0;
  for (var i = 0; i < n; i++) {
    if (fixed[i]) {
      room -= naturals[i];
    } else {
      free++;
    }
  }
  for (var i = 0; i < n; i++) {
    widths[i] = fixed[i] ? naturals[i] : room / free;
  }
  return widths;
}

// ── Line ──────────────────────────────────────────────────────────────────────

/// Tabs(Line) — 화면 · 구역 맨 위의 1차 탭. 다른 구역으로 옮긴다. 구조는 SEED Tabs 의 Line 타입(2026-10-02), 수치 원본은
/// groo-design `specs/components/tabs.yaml`(값은 `test/fixtures/design_spec/tabs.json` — 테스트가 위젯이 그 값과 같은지
/// 본다). 웹(desk-front `src/shared/ds/tabs`)과 같은 값이다. 2차 탭은 [PChipTabs], 내용 칸은 [PTabPanels] 다.
///
/// 목록은 놓인 폭을 채우고 바탕이 불투명하다(bg-layer-default). 바닥 구획 선은 안쪽 1px 라 높이를 밀지 않는다. 탭은 위아래 ·
/// 좌우 10 이고 글을 아래로 붙인다 — 크기와 관계없이 막대와 글 사이가 10 이다. 글은 고르든 안 고르든 700 이고 줄바꿈 ·
/// 말줄임하지 않는다. 고르면 글자색만 fg-neutral-subtle → fg-neutral 로 바로 바뀐다(전환 없음). 막대는 목록에 하나 — 2px ·
/// fg-neutral · 끝이 각지다 — 이고 고른 탭이 바뀌면 left · width 로 200ms 미끄러진다(모션 줄이기에도 그대로다 — 마이크로
/// 모션). 크기가 바뀌어 다시 놓을 때는 바로 놓는다.
///
/// [PTabsLayout.fill] 은 칸을 똑같이 나누고 막대는 탭에서 좌우 16 들인다(360 폰 2 · 3 · 4 · 5개면 148 · 88 · 58 · 40). 글이 칸보다 긴 탭만 글 폭(글 + 좌우 10)으로 넓어지고 나머지가 남은 폭을 똑같이
/// 나눈다(웹과 같다). 글 폭의
/// 합(글 + 좌우 10)이 줄 폭을 넘으면 칸을 나누지 않고 Hug 처럼 가로 스크롤한다(스크롤바는 숨긴다) — 탭 칸 폭은 글 + 좌우 10
/// 이고 막대 들임 16 은 fill 값 그대로이며, 고른 탭은 목록 밖이면 드러낸다(03-G 결정 3B). [PTabsLayout.hug] 은 탭이 글 + 좌우 10 ·
/// 목록 좌우 16 이고 넘치면 가로 스크롤이며 막대는 탭 폭 그대로다. 고른 탭이 목록 밖이면 가장자리에서 16 띄워 가까운 쪽으로
/// 목록만 스크롤한다.
///
/// 상태 — 호버 모양은 없다. 누르면 탭만 2px 거리 준다(기준 max(높이, 폭 ÷ 4, 24) — 모션 줄이기면 줄지 않는다), 색은 그대로다.
/// 막힌 탭은 fg-disabled · 축소 없음이고, 목록 전체가 막혀 고른 탭이 막히면 막대도 fg-disabled 다. 포커스 링은 웹 상태라 앱에는
/// 없다(키보드 포커스는 받는다). 알림 점은 6px fg-brand — 글 끝에서 2 · 글 위쪽에 띄워 탭 폭을 넓히지 않는다. 고른 탭에는
/// 그리지 않는다. 한 목록에 하나만 단다.
///
/// 키보드 — Tab 은 목록에서 고른 탭 하나에만 선다. ← → 로 옮기면 바로 고르고(끝에서 처음으로 돈다, 막힌 탭은 건너뛴다),
/// Home · End 는 첫 · 마지막 탭이다. 읽기 — 목록은 이름 있는 탭 목록([semanticLabel]), 탭은 선택(selected)을 가진 탭이고,
/// 알림 점이 있는 탭은 이름 뒤에 "새 소식"([notificationBadgeName] — 호출부가 넘기지 않는다)을 덧붙인다. [onChanged] 가 없으면 탭이 모두 막힌다.
class PTabs<T> extends StatefulWidget {
  const PTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.semanticLabel,
    this.layout = PTabsLayout.fill,
    this.size = PTabsSize.small,
  }) : assert(items.length >= 2, '탭은 2개 이상이다');

  /// 고른 값.
  final T value;

  /// 다른 탭을 고르면 그 값. 없으면 목록 전체가 비활성.
  final ValueChanged<T>? onChanged;
  final List<PTab<T>> items;

  /// 목록의 이름 — 보이는 제목이 없으면 무엇을 나누는 탭인지("통계").
  final String semanticLabel;
  final PTabsLayout layout;
  final PTabsSize size;

  @override
  State<PTabs<T>> createState() => _PTabsState<T>();
}

class _PTabsState<T> extends State<PTabs<T>> {
  final GlobalKey _stackKey = GlobalKey(debugLabel: 'PTabs stack');
  final List<GlobalKey> _tabKeys = [];
  final ScrollController _scroll = ScrollController();

  /// 막대가 놓인 자리 — 목록 안(스크롤 내용) 좌표. 없으면 아직 재지 않았다.
  Rect? _placed;
  bool _animate = false;
  bool _valueChanged = false;
  bool _firstReveal = true;

  /// 이번에 가로 스크롤 목록으로 그리는가(hug, 또는 글 폭 합이 줄 폭을 넘는 fill) · 스크롤 내용 앞의 안쪽 여백.
  bool _scrolling = false;
  double? _lastWidth;
  double _scrollLead = 0;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    _afterLayout();
  }

  @override
  void didUpdateWidget(PTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (oldWidget.value != widget.value) _valueChanged = true;
    _afterLayout();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncKeys() {
    while (_tabKeys.length < widget.items.length) {
      _tabKeys.add(GlobalKey(debugLabel: 'PTab#${_tabKeys.length}'));
    }
    if (_tabKeys.length > widget.items.length) {
      _tabKeys.removeRange(widget.items.length, _tabKeys.length);
    }
  }

  int get _selectedIndex =>
      widget.items.indexWhere((item) => item.value == widget.value);

  void _afterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
  }

  /// 고른 탭을 재서 막대를 놓는다 — 값이 바뀌었으면 미끄러지고, 아니면 자리가 달라졌을 때만 바로 놓는다.
  void _measure() {
    final index = _selectedIndex;
    final stack = _stackKey.currentContext?.findRenderObject();
    if (index < 0 || stack is! RenderBox || !stack.hasSize) {
      if (_placed != null) setState(() => _placed = null);
      return;
    }
    final tab = _tabKeys[index].currentContext?.findRenderObject();
    if (tab is! RenderBox || !tab.hasSize) return;
    final origin = tab.localToGlobal(Offset.zero, ancestor: stack);
    final rect = origin & tab.size;
    if (_scrolling) {
      revealInScroll(
        context,
        _scroll,
        // 스크롤 내용 좌표 — hug 는 안쪽 여백 16 이 앞에 있다
        rect.shift(Offset(_scrollLead, 0)),
        PSpacing.x4,
        animate: !_firstReveal,
      );
      _firstReveal = false;
    }
    final animate = _valueChanged && _placed != null;
    _valueChanged = false;
    if (_placed == rect && _animate == animate) return;
    if (_placed == rect) {
      _animate = animate;
      return;
    }
    setState(() {
      _placed = rect;
      _animate = animate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = tabsMetrics(widget.size);
    final isHug = widget.layout == PTabsLayout.hug;
    final enabledAll = widget.onChanged != null;
    final selected = _selectedIndex;
    final placed = _placed;
    final barDisabled =
        selected >= 0 && !(enabledAll && widget.items[selected].enabled);

    // fill 은 글 폭의 합이 줄 폭을 넘으면 칸을 나누지 않고 hug 처럼 가로 스크롤한다(막대 들임 16 은 fill 값 그대로)
    return LayoutBuilder(
      builder: (context, constraints) {
        final naturals = _naturalWidths(context, m.text);
        final fillOverflows =
            !isHug &&
            constraints.hasBoundedWidth &&
            naturals.fold<double>(0, (a, b) => a + b) >
                constraints.maxWidth + 0.01;
        // 합이 줄 안이면 칸을 똑같이 나누되, 글이 칸보다 긴 탭만 글 폭으로 넓어지고 나머지가 남은 폭을 나눈다(웹과 같다)
        final fillWidths =
            !isHug && !fillOverflows && constraints.hasBoundedWidth
            ? fillTabWidths(naturals, constraints.maxWidth)
            : null;
        final hug = isHug || fillOverflows;
        final inset = isHug ? 0.0 : PSpacing.x4;
        // 줄 폭이나 스크롤 여부가 바뀌면 막대를 다시 놓는다
        if (_scrolling != hug || _lastWidth != constraints.maxWidth) {
          _afterLayout();
        }
        _lastWidth = constraints.maxWidth;
        _scrolling = hug;
        _scrollLead = isHug ? PSpacing.x4 : 0;
        return _buildList(
          context,
          m,
          hug,
          inset,
          enabledAll,
          selected,
          placed,
          barDisabled,
          fillWidths,
        );
      },
    );
  }

  /// 탭마다 글 폭 + 좌우 10 의 합 — fill 이 칸을 나눌 수 있는지 가르는 값.
  List<double> _naturalWidths(BuildContext context, TextStyle base) {
    final scaler = MediaQuery.textScalerOf(context);
    final out = <double>[];
    for (final item in widget.items) {
      final painter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: base.copyWith(fontWeight: FontWeight.w700),
        ),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      out.add(painter.width + 2 * PSpacing.x2_5);
      painter.dispose();
    }
    return out;
  }

  Widget _buildList(
    BuildContext context,
    ({double height, TextStyle text, double lineHeight}) m,
    bool hug,
    double inset,
    bool enabledAll,
    int selected,
    Rect? placed,
    bool barDisabled,
    List<double>? fillWidths,
  ) {
    final c = context.colors;
    final isHug = widget.layout == PTabsLayout.hug;
    return TabListFocus(
      count: widget.items.length,
      enabledAt: (i) => enabledAll && widget.items[i].enabled,
      onSelect: (i) => widget.onChanged?.call(widget.items[i].value),
      builder: (context, nodes) {
        final row = Row(
          mainAxisSize: hug ? MainAxisSize.min : MainAxisSize.max,
          children: [
            for (var i = 0; i < widget.items.length; i++)
              _wrap(
                hug: hug,
                width: fillWidths?[i],
                child: _LineTab<T>(
                  key: _tabKeys[i],
                  item: widget.items[i],
                  index: i,
                  count: widget.items.length,
                  selected: i == selected,
                  enabled: enabledAll && widget.items[i].enabled,
                  hug: hug,
                  size: widget.size,
                  focusNode: nodes[i],
                  onSelect: () => widget.onChanged?.call(widget.items[i].value),
                ),
              ),
          ],
        );
        final content = Stack(
          key: _stackKey,
          children: [
            // 막대 — 목록의 첫 자식이라 탭이 그 위에 그려진다
            if (placed != null)
              AnimatedPositioned(
                key: const ValueKey('tabs-indicator'),
                duration: _animate ? PDuration.d4 : Duration.zero,
                curve: PEasing.easing,
                left: placed.left + inset,
                bottom: 0,
                width: math.max(0, placed.width - 2 * inset),
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: barDisabled ? c.fgDisabled : c.fgNeutral,
                  ),
                ),
              ),
            row,
          ],
        );
        // 탭 목록의 읽는 말은 탭 바로 위에 둔다 — 스크롤 칸의 읽는 말이 그 사이에 끼면 탭 목록의 자식이 탭이 아니게 된다
        final bar = Semantics(
          container: true,
          explicitChildNodes: true,
          role: SemanticsRole.tabBar,
          label: widget.semanticLabel,
          child: content,
        );
        return DecoratedBox(
          key: const ValueKey('tabs-list'),
          decoration: BoxDecoration(
            color: c.bgLayerDefault,
            // 안쪽 1px — 선이 탭 높이를 밀지 않는다
            border: Border(bottom: BorderSide(color: c.strokeNeutralSubtle)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: m.height),
            child: hug
                ? ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      key: const ValueKey('tabs-scroll'),
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: isHug ? PSpacing.x4 : 0,
                      ),
                      child: bar,
                    ),
                  )
                : bar,
          ),
        );
      },
    );
  }

  // fill 은 칸을 똑같이 나눈다
  Widget _wrap({required bool hug, double? width, required Widget child}) => hug
      ? child
      : (width == null
            ? Expanded(child: child)
            : SizedBox(width: width, child: child));
}

class _LineTab<T> extends StatelessWidget {
  const _LineTab({
    super.key,
    required this.item,
    required this.index,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.hug,
    required this.size,
    required this.focusNode,
    required this.onSelect,
  });

  final PTab<T> item;
  final int index;
  final int count;
  final bool selected;
  final bool enabled;
  final bool hug;
  final PTabsSize size;
  final FocusNode focusNode;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = tabsMetrics(size);
    // 알림 점은 안 고른 탭에만 — 고르면 점도 "새 소식" 도 사라진다
    final showDot = item.notification && !selected;
    final name = showDot
        ? '${item.label} ${notificationBadgeNameOf(context)}'
        : item.label;
    final color = !enabled
        ? c.fgDisabled
        : selected
        ? c.fgNeutral
        : c.fgNeutralSubtle;
    // 포커스 순서는 고른 탭 하나 — 나머지는 화살표로만 닿는다
    return PressArea(
      enabled: enabled,
      focusNode: focusNode,
      skipTraversal: !selected,
      touchMin: 0,
      focusRing: const PFocusRingStyle(radius: PRounded.r2),
      // 이미 고른 탭을 다시 눌러도 그대로다
      onTap: selected ? () {} : onSelect,
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        role: SemanticsRole.tab,
        selected: selected,
        enabled: enabled,
        label: '$name, ${tabPositionName(context, index, count)}',
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, pressSize) => PressScale(
        pressed: pressed,
        size: pressSize,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: m.height),
          child: Padding(
            // 글을 아래로 붙인다 — 좌우 · 아래 10, 남는 높이는 위로(small 위 11 · medium 위 12 — 높이 40 · 44 에서 글 19 · 22 와
            // 아래 10 을 뺀 값)
            padding: EdgeInsets.fromLTRB(
              PSpacing.x2_5,
              m.height - m.lineHeight - PSpacing.x2_5,
              PSpacing.x2_5,
              PSpacing.x2_5,
            ),
            child: Align(
              alignment: Alignment.center,
              widthFactor: hug ? 1 : null,
              heightFactor: 1,
              child: ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: m.text.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (showDot)
                      // 글 끝에서 2 · 글 위쪽 — 띄워 두므로 탭 폭이 바뀌지 않는다
                      PositionedDirectional(
                        top: 0,
                        end: -(_lineDotGap + _dotSize),
                        child: SizedBox.square(
                          dimension: _dotSize,
                          child: DecoratedBox(
                            key: _lineDotKey,
                            decoration: BoxDecoration(
                              color: c.fgBrand,
                              borderRadius: BorderRadius.circular(
                                PRounded.full,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip Tabs ─────────────────────────────────────────────────────────────────

/// Chip Tabs — 1차 Line 탭 안의 2차 탭. 칩 하나는 [PChip] 그대로(Solid 는 Chip Solid, Outline 은 Chip Outline Strong,
/// medium 36 · large 40)이고, 고르면 짙은 채움이다. 구조는 SEED Tabs 의 Chip 타입, 수치 원본은 groo-design
/// `specs/components/chip-tabs.yaml`(값은 `test/fixtures/design_spec/chip-tabs.json`). 웹과 같은 값이다.
///
/// 목록은 바탕 · 바닥 선 없이 한 줄 가로 스크롤이다 — 좌우 화면 여백 24 · 위아래 8 · 칩 사이 8, 스크롤바는 숨긴다. 양 끝은
/// 늘 흐린다(Scroll Fog row — 좌우 20, 여백 24 가 흐림보다 넓어 처음 · 끝 칩은 흐리지 않는다). 칩은 줄어들지 않는다. 고른 칩이
/// 목록 밖이면 화면 여백 24 를 두고 가까운 쪽으로 목록만 스크롤한다. 알림 점은 글 **뒤** 6 에 세로 가운데로 두고(칩 폭이 그만큼
/// 넓어진다) 고른 칩(짙은 채움)에는 그리지 않는다. 누름 · 비활성 · 누르는 영역 44 는 Chip 그대로이고 키보드 · 읽기는 [PTabs] 와
/// 같다. 화면 끝까지 낸 자리에 둔다(화면 여백 안에 두지 않는다 — [PChipGroup] 의 스크롤 줄과 같다).
class PChipTabs<T> extends StatefulWidget {
  const PChipTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.semanticLabel,
    this.variant = PChipTabsVariant.solid,
    this.size = PChipTabsSize.medium,
  }) : assert(items.length >= 2, '탭은 2개 이상이다');

  final T value;
  final ValueChanged<T>? onChanged;
  final List<PTab<T>> items;
  final String semanticLabel;
  final PChipTabsVariant variant;
  final PChipTabsSize size;

  @override
  State<PChipTabs<T>> createState() => _PChipTabsState<T>();
}

class _PChipTabsState<T> extends State<PChipTabs<T>> {
  final GlobalKey _rowKey = GlobalKey(debugLabel: 'PChipTabs row');
  final List<GlobalKey> _tabKeys = [];
  final ScrollController _scroll = ScrollController();
  bool _firstReveal = true;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    _afterLayout();
  }

  @override
  void didUpdateWidget(PChipTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (oldWidget.value != widget.value) _afterLayout();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncKeys() {
    while (_tabKeys.length < widget.items.length) {
      _tabKeys.add(GlobalKey(debugLabel: 'PChipTab#${_tabKeys.length}'));
    }
    if (_tabKeys.length > widget.items.length) {
      _tabKeys.removeRange(widget.items.length, _tabKeys.length);
    }
  }

  void _afterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = widget.items.indexWhere((i) => i.value == widget.value);
      final row = _rowKey.currentContext?.findRenderObject();
      if (index < 0 || row is! RenderBox || !row.hasSize) return;
      final tab = _tabKeys[index].currentContext?.findRenderObject();
      if (tab is! RenderBox || !tab.hasSize) return;
      final origin = tab.localToGlobal(Offset.zero, ancestor: row);
      revealInScroll(
        context,
        _scroll,
        // 스크롤 내용 좌표 — 안쪽 여백 24 가 앞에 있다
        (origin & tab.size).shift(const Offset(PSpacing.globalGutter, 0)),
        PSpacing.globalGutter,
        animate: !_firstReveal,
      );
      _firstReveal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabledAll = widget.onChanged != null;
    final selected = widget.items.indexWhere((i) => i.value == widget.value);
    final chipVariant = switch (widget.variant) {
      PChipTabsVariant.solid => PChipVariant.solid,
      PChipTabsVariant.outline => PChipVariant.outlineStrong,
    };
    final chipSize = switch (widget.size) {
      PChipTabsSize.medium => PChipSize.medium,
      PChipTabsSize.large => PChipSize.large,
    };
    return TabListFocus(
      count: widget.items.length,
      enabledAt: (i) => enabledAll && widget.items[i].enabled,
      onSelect: (i) => widget.onChanged?.call(widget.items[i].value),
      builder: (context, nodes) => PScrollFogMask(
        axis: Axis.horizontal,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          // 칩 한 개의 최대 폭은 보이는 줄 폭(화면 여백 안)이다 — 넘치면 글 끝을 말줄임한다
          child: LayoutBuilder(
            builder: (context, box) => ChipLineLimit(
              maxWidth: box.maxWidth - 2 * PSpacing.globalGutter,
              child: SingleChildScrollView(
                key: const ValueKey('chip-tabs-scroll'),
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: PSpacing.globalGutter,
                ),
                // 탭 목록의 읽는 말은 탭 바로 위에 둔다 — 스크롤 칸의 읽는 말이 그 사이에 끼면 탭 목록의 자식이 탭이 아니게 된다
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  role: SemanticsRole.tabBar,
                  label: widget.semanticLabel,
                  child: Row(
                    key: _rowKey,
                    mainAxisSize: MainAxisSize.min,
                    spacing: PSpacing.betweenChips,
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        // 위아래 8 은 칩마다 둔다 — 칩의 누르는 영역 44 가 그 안에서 받는다
                        Padding(
                          key: _tabKeys[i],
                          padding: const EdgeInsets.symmetric(
                            vertical: PSpacing.x2,
                          ),
                          child: _ChipTab<T>(
                            item: widget.items[i],
                            index: i,
                            count: widget.items.length,
                            selected: i == selected,
                            enabled: enabledAll && widget.items[i].enabled,
                            variant: chipVariant,
                            size: chipSize,
                            dotColor: c.fgBrand,
                            focusNode: nodes[i],
                            onSelect: () =>
                                widget.onChanged?.call(widget.items[i].value),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipTab<T> extends StatelessWidget {
  const _ChipTab({
    required this.item,
    required this.index,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.variant,
    required this.size,
    required this.dotColor,
    required this.focusNode,
    required this.onSelect,
  });

  final PTab<T> item;
  final int index;
  final int count;
  final bool selected;
  final bool enabled;
  final PChipVariant variant;
  final PChipSize size;
  final Color dotColor;
  final FocusNode focusNode;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final showDot = item.notification && !selected;
    final name = showDot
        ? '${item.label} ${notificationBadgeNameOf(context)}'
        : item.label;
    return PressArea(
      focusRing: const PFocusRingStyle(radius: PRounded.full),
      enabled: enabled,
      focusNode: focusNode,
      skipTraversal: !selected,
      onTap: selected ? () {} : onSelect,
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        role: SemanticsRole.tab,
        selected: selected,
        enabled: enabled,
        label: '$name, ${tabPositionName(context, index, count)}',
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, pressSize) => ChipVisual(
        variant: variant,
        size: size,
        selected: selected,
        enabled: enabled,
        pressed: pressed,
        pressSize: pressSize,
        label: item.label,
        // 글 뒤 6 · 세로 가운데 — 칩 폭이 그만큼 넓어진다
        afterLabel: showDot
            ? ExcludeSemantics(
                child: SizedBox.square(
                  dimension: _dotSize,
                  child: DecoratedBox(
                    key: _chipDotKey,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(PRounded.full),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ── 내용 칸 ───────────────────────────────────────────────────────────────────

/// 내용 칸 하나 — 값 · 내용. [PTab] 과 같은 값이다.
@immutable
class PTabPanel<T> {
  const PTabPanel({
    required this.value,
    required this.child,
    this.enabled = true,
  });

  final T value;
  final Widget child;

  /// 밀어 넘길 때 이 칸의 탭이 막혔으면 건너뛴다.
  final bool enabled;
}

/// 밀어 넘기기의 값(tabs.md Behavior) — 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
abstract final class TabsSwipe {
  /// 손을 떼면 넘어가는 거리 — 칸 폭의 25%.
  static const double distance = 0.25;

  /// 빠르게 튕기면(0.4px/ms = 400px/s) 25% 가 안 돼도 넘어간다.
  static const double flickSpeed = 400;

  /// 튕겨서 넘어가는 최소 거리.
  static const double flickDistance = 24;

  /// 이웃이 없는 쪽으로 밀면 손의 1/3 만 따라온다.
  static const double edgeFollow = 1 / 3;

  /// 가로 · 세로를 가르는 거리.
  static const double slop = 10;
}

/// Tabs 의 내용 칸(tabpanel) — 고른 탭의 내용. 바로 바뀌고(애니메이션 없음) 다른 탭의 상태(스크롤 · 입력)를 남긴다 — 칸은
/// 모두 그려 두고 고르지 않은 칸을 숨긴다(Offstage — 상태 · 스크롤 위치가 그대로이고 타이머 · 포커스는 쉰다).
///
/// [swipe] 는 폰에서 화면 전체를 바꾸는 1차 탭만 둔다(2차 탭 · Segmented 에는 두지 않는다). 내용을 가로로 끌면 고른 칸이 손을
/// 따라 움직이고 이웃 칸이 옆에서 들어온다. 손을 떼면 칸 폭의 25% 를 넘었거나 빠르게 튕겼을 때(400px/s 이상 · 24 이상) 이웃
/// 탭(막힌 탭은 건너뛴다)으로 넘어가며 200ms 에 마저 미끄러지고, 아니면 제자리로 돌아온다. 값은 손을 뗄 때 [onChanged] 로
/// 알린다 — 막대 · 글자색이 칸과 함께 옮겨 간다. 이웃이 없는 쪽으로 밀면 손의 1/3 만 따라온다. 세로 스크롤은 그대로고, 가로로
/// 스크롤하는 칸 위에서 시작한 끌기는 그 칸이 맡는다(Flutter 의 제스처 경쟁 — 안쪽 스크롤이 이긴다). 모션 줄이기면 손을 따라
/// 움직이는 것은 그대로 두고, 손을 뗀 뒤 미끄러지지 않고 바로 바뀐다. 쓰는 쪽이 값을 받지 않으면(미끄러진 뒤에도 값이 그대로면)
/// 제자리로 돌아온다.
class PTabPanels<T> extends StatefulWidget {
  const PTabPanels({
    super.key,
    required this.value,
    required this.panels,
    this.onChanged,
    this.swipe = false,
  }) : assert(!swipe || onChanged != null, '밀어 넘기려면 onChanged 로 고른 값을 받는다');

  final T value;
  final List<PTabPanel<T>> panels;

  /// 밀어 넘겨 고른 값 — [swipe] 일 때만 부른다.
  final ValueChanged<T>? onChanged;
  final bool swipe;

  @override
  State<PTabPanels<T>> createState() => _PTabPanelsState<T>();
}

class _PTabPanelsState<T> extends State<PTabPanels<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PDuration.d4,
  )..addListener(() => setState(() {}));

  /// 손을 따라(또는 미끄러져) 움직이는 칸 — [_base] 가 [_offset] 에 있고, 이웃 [_other] 는 [_dir] 쪽으로 칸 폭만큼 떨어져 있다.
  /// 둘 다 끌기가 시작될 때 정해져 미끄러지는 동안 그대로다(값이 바뀌어도 칸이 뒤바뀌지 않는다).
  double _offset = 0;
  int? _base;
  int? _other;

  /// 이웃의 방향 — +1 = 다음 칸이 오른쪽(왼쪽으로 밀면 들어온다).
  int _dir = 1;
  double _width = 0;

  /// 미끄러지는 중 — 끝나면 값이 받아졌는지 본다.
  bool _settling = false;
  bool _committed = false;
  double _from = 0;
  double _to = 0;

  int get _index => widget.panels.indexWhere((p) => p.value == widget.value);

  bool get _moving => _base != null;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(PTabPanels<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 밖에서 값이 바뀌면(탭을 눌렀다) 끌던 것은 접고 바로 바꾼다 — 밀어 넘겨 값이 받아진 경우는 미끄러지는 채로 둔다
    if (oldWidget.value != widget.value && !(_settling && _committed)) {
      _reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    _controller.stop();
    _offset = 0;
    _base = null;
    _other = null;
    _settling = false;
    _committed = false;
  }

  int? _neighbor(int from, int dir) {
    for (var i = from + dir; i >= 0 && i < widget.panels.length; i += dir) {
      if (widget.panels[i].enabled) return i;
    }
    return null;
  }

  void _onStart(DragStartDetails d) {
    if (_settling) return;
    _base = _index < 0 ? null : _index;
    _offset = 0;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_settling || _base == null) return;
    final dir = _offset + d.delta.dx < 0 ? 1 : -1;
    final other = _neighbor(_base!, dir);
    setState(() {
      _dir = dir;
      _other = other;
      // 이웃이 없는 쪽은 손의 1/3 만 따라온다
      _offset += other == null ? d.delta.dx * TabsSwipe.edgeFollow : d.delta.dx;
    });
  }

  void _onEnd(DragEndDetails d) {
    if (_settling || _base == null) return;
    final other = _other;
    if (other == null || _width <= 0) {
      _slideTo(0, commit: false);
      return;
    }
    final moved = _offset.abs();
    final speed = d.velocity.pixelsPerSecond.dx;
    // 이웃 쪽으로 끌었을 때만 — 되돌아오는 손은 넘기지 않는다
    final toward = (_offset < 0) == (_dir == 1);
    final flick =
        toward &&
        speed.abs() >= TabsSwipe.flickSpeed &&
        (speed < 0) == (_dir == 1) &&
        moved >= TabsSwipe.flickDistance;
    final far = toward && moved > _width * TabsSwipe.distance;
    if (far || flick) {
      // 값은 손을 뗄 때 바뀐다 — 막대 · 글자색이 칸과 함께 옮겨 간다
      widget.onChanged?.call(widget.panels[other].value);
      _slideTo(-_dir * _width, commit: true);
    } else {
      _slideTo(0, commit: false);
    }
  }

  void _slideTo(double to, {required bool commit}) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion || _offset == to) {
      setState(_reset);
      return;
    }
    _settling = true;
    _committed = commit;
    _from = _offset;
    _to = to;
    _controller
      ..value = 0
      ..forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_settling) return;
    final other = _other;
    if (_committed &&
        other != null &&
        widget.panels[other].value != widget.value) {
      // 쓰는 쪽이 값을 받지 않았다 — 제자리로 돌아온다
      _committed = false;
      _from = _offset;
      _to = 0;
      _controller
        ..value = 0
        ..forward();
      return;
    }
    setState(_reset);
  }

  @override
  Widget build(BuildContext context) {
    final index = _index;
    if (_settling) {
      _offset =
          _from + (_to - _from) * PEasing.easing.transform(_controller.value);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        Widget pane(int i) {
          final panel = widget.panels[i];
          final isBase = _moving && i == _base;
          final isOther = _moving && i == _other;
          final shown = _moving ? (isBase || isOther) : i == index;
          final dx = isBase
              ? _offset
              : (isOther ? _offset + _dir * _width : 0.0);
          return Offstage(
            key: ValueKey(panel.value),
            offstage: !shown,
            child: ExcludeFocus(
              excluding: !shown,
              child: TickerMode(
                enabled: shown,
                child: ExcludeSemantics(
                  excluding: i != index,
                  child: Align(
                    alignment: Alignment.topLeft,
                    // 고른 칸만 높이를 정한다 — 들어오고 나가는 칸은 위에 얹힌다
                    heightFactor: i == index ? 1 : 0,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Semantics(
                        container: true,
                        role: SemanticsRole.tabPanel,
                        explicitChildNodes: true,
                        child: panel.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final body = Stack(
          // 미는 동안만 넘친 것을 자른다
          clipBehavior: _moving ? Clip.hardEdge : Clip.none,
          children: [for (var i = 0; i < widget.panels.length; i++) pane(i)],
        );
        if (!widget.swipe) return body;
        return RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(HorizontalDragGestureRecognizer.new, (instance) {
                  instance
                    ..gestureSettings = const DeviceGestureSettings(
                      touchSlop: TabsSwipe.slop,
                    )
                    ..onStart = _onStart
                    ..onUpdate = _onUpdate
                    ..onEnd = _onEnd
                    ..onCancel = () => _onEnd(DragEndDetails());
                }),
          },
          child: body,
        );
      },
    );
  }
}
