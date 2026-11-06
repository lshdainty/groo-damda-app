import 'dart:math' as math;

import 'package:flutter/gestures.dart' show Drag;
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 스냅 기준 — 숨는 영역 높이의 50%(SEED `SNAP_THRESHOLD_RATIO`).
const double kScrollAutoHideSnapRatio = 0.5;

/// 안의 스크롤 상자를 만드는 함수 — [controller] 는 그 스크롤 상자에 그대로 넘긴다(영역 위의 끌기를 목록에 이어 준다),
/// [headerHeight] 는 숨는 영역의 높이다. 스크롤 상자의 맨 위 여백으로 넣어 목록이 숨는 영역 아래에서 시작하게 한다(웹은 영역이
/// 스크롤 상자 안 맨 위에 sticky 로 놓여 영역 위를 끌어도 스크롤된다).
typedef PScrollAutoHideBuilder =
    Widget Function(
      BuildContext context,
      ScrollController controller,
      double headerHeight,
    );

/// Scroll Auto Hide — 스크롤 상자 맨 위에 붙은 영역이 아래로 스크롤하면 그 거리만큼 위로 숨고, 위로 스크롤하면 같은 거리만큼
/// 드러난다. 구조는 SEED Breeze ScrollAutoHide(Apache-2.0), 수치 원본은 groo-design
/// `specs/components/scroll-auto-hide.yaml`(값은 `test/fixtures/design_spec/scroll-auto-hide.json`), 웹은 desk-front
/// `src/shared/ds/scroll-auto-hide` 다 — 같은 규칙이다.
///
///   따라가기 — 스크롤 거리를 1:1 로(시간 · 곡선 없음). 맨 위 근처에서는 스크롤한 거리보다 더 숨지 않는다
///   스냅 — 스크롤이 끝나면 영역 높이의 50% 를 기준으로 다 숨거나 다 드러난다(200ms [PEasing.enter])
///   높이 — 바꾸지 않고 위로 옮기기만 한다(레이아웃은 그대로). 영역은 스크롤 상자 위에 겹쳐 서고 목록은 [builder] 가 받은 높이만큼
///   위 여백을 둔다
///   모션 줄이기 — 자동 숨김을 끈다(늘 보인다)
///   포커스 — 숨은 영역 안으로 포커스가 오면 바로 다 드러난다. 숨겨도 의미 트리에서 빼지 않는다(inert · aria-hidden 을 걸지
///   않는다 — 포커스가 오면 드러나므로)
///
/// 고정 줄 — [pinnedTop] · [pinnedBottom] 을 주면 그 둘은 숨지 않고 [header] 만 숨는다. 위 고정 줄은 그 자리에 있고, 아래 고정
/// 줄은 [header] 가 숨는 거리만큼 함께 올라가 위 고정 줄 바로 아래에 붙는다(원장 — 달 이동 줄 · 주 달력 · 펼침 꺾쇠는 남고 총액 ·
/// 지난달 비교 · 소비 요약만 숨는다). 이것도 옮기기만 한다 — 레이아웃 높이는 그대로라 목록이 당겨지지 않는다(짧은 목록에서 깜빡이지
/// 않는다).
///
/// 상단 바 · Line Tabs · 시트 머리는 숨기지 않는다. 바탕은 [color] 로 정한다(기본 `bg-layer-default` — 목록이 영역 뒤로 비치지
/// 않게). 웹과 달리 키보드로 스크롤한 뒤의 즉시 스냅은 없다(앱은 손가락 스크롤이 중심이다).
class PScrollAutoHide extends StatefulWidget {
  const PScrollAutoHide({
    super.key,
    required this.header,
    required this.builder,
    this.controller,
    this.color,
    this.pinnedTop,
    this.pinnedBottom,
    this.onMoved,
  });

  /// 숨는 영역이 옮겨질 때마다(따라가기 · 스냅) — 옮긴 거리(0 ~ −높이). 스냅은 목록을 스크롤하지 않고 남는 머리를 옮기므로, 남는 머리
  /// 아래 선에 기대는 쪽(원장의 스크롤 스파이)은 이것도 듣는다.
  final ValueChanged<double>? onMoved;

  /// 숨는 영역 — 원장 머리의 총액 · 지난달 비교 · 소비 요약.
  final Widget header;

  /// 숨는 영역 위의 고정 줄 — 원장의 달 이동 줄. 숨지 않는다.
  final Widget? pinnedTop;

  /// 숨는 영역 아래의 고정 줄 — 원장의 주 달력(펼친 월 달력) · 펼침 꺾쇠 · 구분선. 숨지 않고 [header] 가 숨는 만큼 올라간다.
  final Widget? pinnedBottom;

  /// 스크롤 상자 — 안의 스크롤은 세로여야 한다.
  final PScrollAutoHideBuilder builder;

  /// 스크롤 제어 — 없으면 이 위젯이 만들어 [builder] 에 넘긴다.
  final ScrollController? controller;

  /// 영역의 바탕 — 기본 `bg-layer-default`.
  final Color? color;

  @override
  State<PScrollAutoHide> createState() => PScrollAutoHideState();
}

/// 목록을 프로그램으로 옮기는 쪽(날짜로 가기)이 [scrollTargetFor] 로 남는 머리 바로 아래에 맞출 수 있게 열어 둔다 —
/// `GlobalKey<PScrollAutoHideState>` 로 잡는다.
class PScrollAutoHideState extends State<PScrollAutoHide>
    with SingleTickerProviderStateMixin {
  /// 영역의 위로 옮긴 거리 — 0(다 드러남) ~ −높이(다 숨음).
  final ValueNotifier<double> _translate = ValueNotifier<double>(0);

  late final AnimationController _snap;
  Animation<double>? _snapAnimation;

  ScrollController? _ownController;
  ScrollController get _controller =>
      widget.controller ?? (_ownController ??= ScrollController());
  Drag? _headerDrag;

  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _hideKey = GlobalKey();

  /// 숨는 영역의 높이 — 옮기는 범위(0 ~ −높이).
  double _height = 0;

  /// 머리 전체(고정 줄 + 숨는 영역)의 높이 — 목록 위 여백.
  double _total = 0;
  double _previousPixels = 0;
  bool _reduceMotion = false;

  void _onMoved() => widget.onMoved?.call(_translate.value);

  void _onSnapTick() {
    final a = _snapAnimation;
    if (a != null) _translate.value = a.value;
  }

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(vsync: this)..addListener(_onSnapTick);
    _translate.addListener(_onMoved);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      // 모션 줄이기를 켜고 끄면 — 켜면 늘 보인다
      _stopSnap();
      _translate.value = 0;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    _snap.dispose();
    _translate.dispose();
    super.dispose();
  }

  static double _heightOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0.0;
  }

  /// 영역 높이를 잰다 — 바뀌면 목록 위 여백을 다시 준다.
  void _measure() {
    if (!mounted) return;
    final h = _heightOf(_hideKey);
    final total = _heightOf(_headerKey);
    if (h == _height && total == _total) return;
    setState(() {
      _height = h;
      _total = total;
      _translate.value = _translate.value.clamp(-h, 0.0).toDouble();
    });
  }

  void _stopSnap() {
    _snap.stop();
    _snapAnimation = null;
  }

  /// 스크롤한 거리보다 더 숨지 않는다 — 맨 위 근처에서는 스크롤한 만큼만.
  double _minTranslate(double scrollTop) {
    if (_height == 0 || scrollTop <= 0) return 0;
    if (scrollTop >= _height) return -_height;
    return -scrollTop;
  }

  double _pixels(ScrollMetrics m) =>
      m.pixels.clamp(0.0, math.max(0.0, m.maxScrollExtent));

  bool _mine(ScrollNotification n) =>
      n.depth == 0 && n.metrics.axis == Axis.vertical;

  // 스크롤하는 동안 — 거리를 1:1 로 따라간다
  void _follow(ScrollMetrics metrics) {
    final scrollTop = _pixels(metrics);
    final delta = scrollTop - _previousPixels;
    _previousPixels = scrollTop;
    if (_reduceMotion) {
      _translate.value = 0;
      return;
    }
    _stopSnap();
    _translate.value = (_translate.value - delta)
        .clamp(_minTranslate(scrollTop), 0.0)
        .toDouble();
  }

  // 스크롤이 끝남 — 50% 를 기준으로 다 숨거나 다 드러난다
  void _settle(ScrollMetrics metrics) {
    if (_reduceMotion || _height == 0) return;
    final from = _translate.value;
    final visibleRatio = 1 + from / _height;
    final min = _minTranslate(_pixels(metrics));
    final target = visibleRatio >= kScrollAutoHideSnapRatio
        ? 0.0
        : (-_height).clamp(min, 0.0).toDouble();
    if (target == from) return;
    _snapAnimation = Tween<double>(
      begin: from,
      end: target,
    ).animate(CurvedAnimation(parent: _snap, curve: PEasing.enter));
    _snap
      ..duration = PDuration.d4
      ..forward(from: 0);
  }

  bool _onScroll(ScrollNotification n) {
    if (!_mine(n)) return false;
    if (n is ScrollStartNotification) {
      _stopSnap();
      _previousPixels = _pixels(n.metrics);
    } else if (n is ScrollUpdateNotification) {
      _follow(n.metrics);
    } else if (n is ScrollEndNotification) {
      _follow(n.metrics);
      _settle(n.metrics);
    }
    return false;
  }

  /// 목록을 [from] 에서 [to] 로 곧장 옮겨 멈췄을 때 숨는 영역이 옮겨진 거리(0 ~ −높이) — 따라가기와 스냅을 그대로 셈한다.
  double _translateAfter(double from, double to) {
    if (_reduceMotion || _height == 0) return 0;
    final lo = _minTranslate(to);
    final t = _translate.value;
    final follow = to >= from
        ? math.max(t - (to - from), lo)
        : math.max(math.min(0.0, t + (from - to)), lo);
    return 1 + follow / _height >= kScrollAutoHideSnapRatio ? 0.0 : lo;
  }

  /// 남는 머리(위 고정 줄 + 아직 보이는 숨는 영역 + 아래 고정 줄)의 아래 끝 — 스크롤 상자 맨 위 기준 y.
  double get visibleBottom => _total + _translate.value;

  /// [ctx] 의 항목이 남는 머리 바로 아래(+[gap])에 오게 할 스크롤 값 — 옮긴 뒤 숨는 영역이 숨거나 드러나는 거리까지 친다(내려가면
  /// 숨고 올라가면 드러나므로 맞출 선이 움직인다). 스크롤 상자를 못 찾으면 `null`.
  double? scrollTargetFor(BuildContext ctx, {double gap = 0}) {
    final box = ctx.findRenderObject();
    final scrollable = Scrollable.maybeOf(ctx);
    final viewport = scrollable?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || scrollable == null) {
      return null;
    }
    final itemTop =
        box.localToGlobal(Offset.zero).dy -
        viewport.localToGlobal(Offset.zero).dy;
    final p = scrollable.position;
    final from = p.pixels;
    var to = from;
    // 맞출 선이 옮긴 거리에 따라 달라진다 — 몇 번 되풀이해 맞춘다
    for (var i = 0; i < 4; i++) {
      final line = _total + _translateAfter(from, to);
      to = (from + itemTop - line - gap)
          .clamp(p.minScrollExtent, p.maxScrollExtent)
          .toDouble();
    }
    return to;
  }

  void _dragStart(DragStartDetails details) {
    if (!_controller.hasClients) return;
    _headerDrag = _controller.position.drag(details, () => _headerDrag = null);
  }

  // 숨은 영역 안으로 포커스가 오면 바로 다 드러낸다
  void _onFocusChange(bool focused) {
    if (!focused) return;
    _stopSnap();
    _translate.value = 0;
  }

  /// 영역 위를 끌어도 목록이 스크롤된다 — 영역이 목록 위에 겹쳐 서 있어 끌기를 이어 준다. 조각마다 따로 건다 — 숨는 영역이 숨고
  /// 아래 고정 줄이 올라가면 머리 틀의 맨 아래가 비는데, 그 빈 자리는 목록이 받아야 한다.
  Widget _part(Widget child, Color color, {Key? key}) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onVerticalDragStart: _dragStart,
    onVerticalDragUpdate: (d) => _headerDrag?.update(d),
    onVerticalDragEnd: (d) {
      _headerDrag?.end(d);
      _headerDrag = null;
    },
    onVerticalDragCancel: () {
      _headerDrag?.cancel();
      _headerDrag = null;
    },
    child: ColoredBox(key: key, color: color, child: child),
  );

  Widget _moved(Key key, Widget child) => ValueListenableBuilder<double>(
    valueListenable: _translate,
    builder: (context, dy, child) =>
        Transform.translate(key: key, offset: Offset(0, dy), child: child),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.bgLayerDefault;
    final top = widget.pinnedTop;
    final bottom = widget.pinnedBottom;
    return ClipRect(
      clipper: const _VisualClip(),
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.builder(context, _controller, _total),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
                return false;
              },
              child: SizeChangedLayoutNotifier(
                child: Column(
                  key: _headerKey,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (top != null) _part(top, color),
                    // 숨는 영역 — 제 자리 밖(위 고정 줄 쪽)으로 옮겨진 부분은 잘라 그리지 않는다
                    ClipRect(
                      clipper: const _VisualClip(),
                      child: _moved(
                        const ValueKey('pscrollautohide-header'),
                        SizeChangedLayoutNotifier(
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onFocusChange: _onFocusChange,
                            child: _part(widget.header, color, key: _hideKey),
                          ),
                        ),
                      ),
                    ),
                    // 아래 고정 줄 — 숨는 만큼 함께 올라가 위 고정 줄 바로 아래에 붙는다(뒤에 그려 숨는 영역을 덮는다)
                    if (bottom != null)
                      _moved(
                        const ValueKey('pscrollautohide-pinned-bottom'),
                        _part(bottom, color),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 보이는 곳만 자른다 — 영역이 위로 옮겨져 잘려 나가도 의미 트리에서는 빠지지 않는다(웹은 inert · aria-hidden 을 걸지 않는다 —
/// 포커스가 오면 드러나므로). 기본 [ClipRect] 는 잘린 노드를 의미 트리에서 뺀다.
class _VisualClip extends CustomClipper<Rect> {
  const _VisualClip();

  @override
  Rect getClip(Size size) => Offset.zero & size;

  @override
  Rect getApproximateClipRect(Size size) =>
      Rect.fromLTRB(0, -size.height * 8, size.width, size.height * 9);

  @override
  bool shouldReclip(_VisualClip oldClipper) => false;
}
