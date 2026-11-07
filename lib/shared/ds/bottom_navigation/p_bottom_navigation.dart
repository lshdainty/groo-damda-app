import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/notification_badge/p_notification_badge.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

/// 바 높이 — 펼침 66 · 줄어듦 48. 토큰에 없는 바 자신의 치수다(bottom-navigation.yaml root.height).
const double kBottomNavigationHeight = 66;
const double kBottomNavigationCompactHeight = 48;

/// 넓은 화면에서는 이 폭으로 가운데에 선다(SEED — 칸이 지나치게 퍼지지 않게).
const double kBottomNavigationMaxWidth = 480;

/// 줄어들기 기준(지금 Desk 웹 · 앱 값) — 아래로 20 이상 스크롤하면 줄고, 위로 28 이상 스크롤하거나 맨 위 40 안으로 오면 펴진다.
const double kBottomNavigationShrinkAfter = 20;
const double kBottomNavigationExpandAfter = 28;
const double kBottomNavigationTopZone = 40;

/// 화면 키보드가 이만큼 올라오면 바를 가린다(웹 visualViewport 150).
const double kBottomNavigationKeyboardGap = 150;

/// 칸 다섯 중 탭 칸은 넷이고 가운데 + 가 하나다. 알림 배지는 2칸까지(SEED).
const int kBottomNavigationItems = 4;
const int kBottomNavigationMaxBadges = 2;

/// 칸 사이.
const double _cellGap = PSpacing.x0_5;

/// 바의 치수 — 펼침 · 줄어듦마다. [safe] 는 화면의 안전 영역(홈 표시줄 · 좌우 노치). 스펙 JSON 값(`regular` · `compact`)과 같다.
@visibleForTesting
({
  double height,
  double marginX,
  double marginBottom,
  double paddingX,
  double paddingY,
  double addSize,
  double addIcon,
})
bottomNavigationMetrics({
  required bool compact,
  EdgeInsets safe = EdgeInsets.zero,
}) => compact
    ? (
        height: kBottomNavigationCompactHeight,
        marginX: PSpacing.x9,
        // 홈 표시줄이 있으면 안전 영역 − 8 — 칸(48)은 안전 영역 위에서 끝난다
        marginBottom: math.max(12, safe.bottom - 8),
        paddingX: PSpacing.x2,
        // 칸이 바 높이 48 을 다 채운다 — 누르는 영역 44 이상
        paddingY: 0,
        addSize: PSpacing.x9,
        addIcon: PSpacing.x5,
      )
    : (
        height: kBottomNavigationHeight,
        marginX: PSpacing.x3_5,
        // 홈 표시줄이 있으면 34 − 6 = 28 — 바의 아래 여백 6 만 안전 영역에 걸친다
        marginBottom: math.max(14, safe.bottom - 6),
        paddingX: PSpacing.x2_5,
        paddingY: PSpacing.x1_5,
        addSize: PTouch.min,
        addIcon: PSpacing.x6,
      );

/// 본문 스크롤 아래 여백 — 바의 아래 자리 + 66 + 24. 끝까지 내리면 마지막 줄이 바 위 24 에서 끝난다. 바가 줄어도 그대로 둔다
/// (줄 때마다 본문이 밀리지 않게) — 안전 영역이 없으면 104, 34 면 118.
double bottomNavigationInset(BuildContext context) =>
    math.max(14, MediaQuery.paddingOf(context).bottom - 6) +
    kBottomNavigationHeight +
    PSpacing.x6;

/// 바가 줄었는지를 쥐고 스크롤을 센다 — 셸이 본문 스크롤에 걸어 준다.
///
/// ```dart
/// NotificationListener<ScrollNotification>(onNotification: controller.handleScroll, child: body)
/// ```
///
/// 세로 스크롤만 센다(가로 줄은 세지 않는다). 시트 · 대화상자는 다른 길(route)이라 본문 아래에 없어 세지 않는다. 방향이 바뀌면 거리를
/// 다시 센다. 맨 위 40 안이면 늘 펴진다.
class PBottomNavigationController extends ChangeNotifier {
  PBottomNavigationController({bool compact = false}) : _compact = compact;

  bool _compact;
  int _direction = 0;
  double _distance = 0;

  /// 줄어든 바(48)인가.
  bool get compact => _compact;

  void setCompact(bool value) {
    if (_compact == value) return;
    _compact = value;
    notifyListeners();
  }

  /// 펴진다 — 줄어든 바를 누르거나 칸을 눌렀을 때.
  void expand() => setCompact(false);

  /// 스크롤 알림을 센다. 알림은 위로 흘려보낸다(false).
  bool handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification) return false;
    final delta = notification.scrollDelta ?? 0;
    if (delta == 0) return false;
    final y = notification.metrics.pixels;
    if (y <= kBottomNavigationTopZone) {
      _direction = 0;
      _distance = 0;
      setCompact(false);
      return false;
    }
    final next = delta > 0 ? 1 : -1;
    if (next != _direction) {
      _direction = next;
      _distance = 0;
    }
    _distance += delta.abs();
    if (_direction == 1 && _distance >= kBottomNavigationShrinkAfter) {
      setCompact(true);
    } else if (_direction == -1 && _distance >= kBottomNavigationExpandAfter) {
      setCompact(false);
    }
    return false;
  }
}

/// 탭 칸 — 아이콘 24 위 · 라벨 아래. 지금 탭은 짙은 글자색(fg-neutral) + 선 2.5, 다른 탭은 fg-neutral-subtle + 선 2 — 브랜드 색으로
/// 칠하지 않는다. [label] 은 한글 5자 이내의 명사 — 줄어든 바에서는 보이지 않지만 칸의 이름으로 남는다.
@immutable
class PBottomNavigationItem {
  const PBottomNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    this.current = false,
    this.onReselect,
    this.notification = false,
  });

  /// 기본 굵기(선 2) lucide 아이콘.
  final IconData icon;

  /// 지금 탭일 때의 선 2.5 판(`LucideIcons.house500` …) — 글꼴을 코드로 만들면 릴리스 빌드의 아이콘 트리 셰이킹이 막혀 상수로 받는다.
  final IconData selectedIcon;
  final String label;

  /// 다른 탭을 눌렀다 — 그 탭의 마지막 화면 · 스크롤 위치로(탭마다 기억하는 것은 셸의 몫).
  final VoidCallback onTap;

  /// 지금 탭을 다시 눌렀다 — 첫 화면이 아니면 첫 화면으로, 맨 위로 스크롤한다. 같은 주소를 쌓지 않는다.
  final VoidCallback? onReselect;

  /// 지금 탭 — 읽는 말에서 선택됨.
  final bool current;

  /// 알림 점 — 2칸까지.
  final bool notification;
}

/// 가운데 + — 탭이 아니라 그 화면의 추가 동작이다. 브랜드 원 44(줄어듦 36) + 흰 + 24(20), 라벨 없음, 누르는 영역은 칸 전체.
/// [label] 은 화면마다 다르다 — 홈 · 가계부 · 전체는 "거래 추가", 캘린더는 "일정 추가".
@immutable
class PBottomNavigationAdd {
  const PBottomNavigationAdd({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// 하단 탭 바 — 폰 화면 아래에 떠 있는 알약. 칸은 다섯이고 어느 화면에서나 같다(홈 · 가계부 · + · 캘린더 · 전체). 규칙은 SEED Bottom
/// Navigation(5칸 · 라벨 5자 · 최대 480 · 배지 2칸 · 글자 크기 설정을 따르지 않음), 바의 모양은 groo 가 지켜 온 떠 있는
/// 알약(2026-10-04 사용자 결정). 수치 원본은 groo-design `specs/components/bottom-navigation.yaml`(값은
/// `test/fixtures/design_spec/bottom-navigation.json`). 웹(desk-front `src/shared/ds/bottom-navigation`)과 같은 값이다.
///
/// 바 — 펼침 66(좌우 14 · 아래 max(14, 안전 영역 − 6)) · 줄어듦 48(좌우 36 · 아래 max(12, 안전 영역 − 8)), 칸 다섯을 똑같이 나눈다
/// (사이 2). 불투명한 bg-layer-floating(흐림 없음) · shadow-s3 · 안쪽 1px stroke-neutral-subtle. 화면 아래에 붙여 쓴다 —
/// `Stack` 의 `Positioned(left: 0, right: 0, bottom: 0)` 가 정석이고, 여백은 이 위젯이 가진다.
///
/// 칸 — 라벨은 t1 11/15 · 500 으로 글자 크기 설정을 따르지 않는다(커지면 칸 밖으로 넘친다). 줄어든 바에서는 라벨이 보이지 않지만 칸마다
/// 이름이 남는다. 알림 점은 Notification Badge small(2칸까지). 눌러도 색은 그대로이고 칸이 2px 거리 줄 뿐이다(손을 떼기 전에 고른
/// 것처럼 보이지 않게). +는 bg-brand-solid-pressed + 원 2px 거리 축소.
///
/// 줄어들기 — [controller] 가 센다(아래로 20 · 위로 28 · 맨 위 40). 줄어든 바를 누르면 펴진다 — 칸을 누르면 그 탭으로 가면서 바도
/// 펴진다. 라벨은 줄어들기 시작할 때 사라지고 다 펴진 뒤(200ms) 나타난다. 모션 줄이기면 바로 바뀐다. 화면 키보드가 올라오면 바를 가린다.
/// 스낵바는 바 위 8 에 뜬다([PSnackbarAvoidOverlap] 로 감쌌다). 탭 바가 있는 화면에는 Floating Action Button 을 두지 않는다.
///
/// 뒤로 가기는 처리하지 않는다 — 콜백만 받는다.
class PBottomNavigation extends StatefulWidget {
  PBottomNavigation({
    super.key,
    required this.semanticLabel,
    required this.items,
    required this.add,
    this.controller,
  }) : assert(
         items.length == kBottomNavigationItems,
         '탭 칸은 넷 — 홈 · 가계부 · 캘린더 · 전체. 칸을 늘리거나 줄이지 않는다',
       ),
       assert(
         items.where((i) => i.notification).length <=
             kBottomNavigationMaxBadges,
         '알림 배지는 2칸까지(SEED)',
       );

  /// 바의 이름 — "주 메뉴".
  final String semanticLabel;

  /// 탭 칸 넷 — 차례대로 가운데 + 의 왼쪽 둘, 오른쪽 둘.
  final List<PBottomNavigationItem> items;
  final PBottomNavigationAdd add;

  /// 줄어듦을 쥔 쪽 — 주지 않으면 이 바가 하나 갖고 있다(스크롤을 세지 않는다).
  final PBottomNavigationController? controller;

  @override
  State<PBottomNavigation> createState() => _PBottomNavigationState();
}

class _PBottomNavigationState extends State<PBottomNavigation> {
  PBottomNavigationController? _own;
  Timer? _labelTimer;
  late bool _labelsShown;

  PBottomNavigationController get _controller =>
      widget.controller ?? (_own ??= PBottomNavigationController());

  @override
  void initState() {
    super.initState();
    _labelsShown = !_controller.compact;
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(PBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_onChanged);
      _controller.addListener(_onChanged);
      _labelsShown = !_controller.compact;
    }
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    (widget.controller ?? _own)?.removeListener(_onChanged);
    _own?.dispose();
    super.dispose();
  }

  /// 라벨 — 줄어들기 시작하면 바로 숨기고, 펴질 때는 다 펴진 뒤에 보인다. 모션 줄이기면 바로.
  void _onChanged() {
    _labelTimer?.cancel();
    if (_controller.compact) {
      setState(() => _labelsShown = false);
      return;
    }
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _labelsShown = true);
      return;
    }
    setState(() {});
    _labelTimer = Timer(PDuration.d4, () {
      if (mounted) setState(() => _labelsShown = true);
    });
  }

  void _activate() => _controller.expand();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    final safe = media.padding;
    final compact = _controller.compact;
    final labelsHidden = compact || !_labelsShown;
    final m = bottomNavigationMetrics(compact: compact, safe: safe);
    final reduce = media.disableAnimations;
    final duration = reduce ? Duration.zero : PDuration.d4;
    final keyboardOpen = media.viewInsets.bottom > kBottomNavigationKeyboardGap;

    final items = widget.items;
    final cells = <Widget>[
      _cell(items[0], labelsHidden),
      _cell(items[1], labelsHidden),
      _AddCell(
        add: widget.add,
        compact: compact,
        onActivate: _activate,
        duration: duration,
      ),
      _cell(items[2], labelsHidden),
      _cell(items[3], labelsHidden),
    ];

    final pill = AnimatedContainer(
      key: const ValueKey('bottom-navigation-bar'),
      duration: duration,
      curve: PEasing.easing,
      height: m.height,
      padding: EdgeInsets.symmetric(
        horizontal: m.paddingX,
        vertical: m.paddingY,
      ),
      decoration: BoxDecoration(
        color: c.bgLayerFloating,
        borderRadius: BorderRadius.circular(PRounded.full),
        boxShadow: context.shadows.s3,
      ),
      // 안쪽 1px 은 자리를 차지하지 않는다(웹 inset box-shadow) — 위에 덧그린다
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PRounded.full),
        border: Border.all(color: c.strokeNeutralSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _cellGap,
        children: [for (final cell in cells) Expanded(child: cell)],
      ),
    );

    final bar = AnimatedPadding(
      duration: duration,
      curve: PEasing.easing,
      padding: EdgeInsets.fromLTRB(
        m.marginX + safe.left,
        0,
        m.marginX + safe.right,
        m.marginBottom,
      ),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kBottomNavigationMaxWidth,
          ),
          // 줄어든 바 어디를 눌러도 펴진다 — 칸을 눌렀으면 그 탭으로도 간다
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: compact ? _activate : null,
            child: PSnackbarAvoidOverlap(child: pill),
          ),
        ),
      ),
    );

    return Visibility(
      visible: !keyboardOpen,
      maintainState: true,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.semanticLabel,
        child: bar,
      ),
    );
  }

  Widget _cell(PBottomNavigationItem item, bool labelsHidden) =>
      _ItemCell(item: item, labelsHidden: labelsHidden, onActivate: _activate);
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({
    required this.item,
    required this.labelsHidden,
    required this.onActivate,
  });

  final PBottomNavigationItem item;
  final bool labelsHidden;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = item.current;
    final color = current ? c.fgNeutral : c.fgNeutralSubtle;
    final name = item.notification
        ? '${item.label} ${notificationBadgeNameOf(context)}'
        : item.label;
    final void Function()? tap = current ? item.onReselect : item.onTap;

    return PressArea(
      key: const ValueKey('bottom-navigation-item'),
      enabled: true,
      // 지금 탭을 다시 누르면 onReselect 가 없어도 눌린 것으로 친다 — 줄어든 바는 펴진다
      onTap: () {
        onActivate();
        tap?.call();
      },
      // 칸 전체가 누르는 영역이다
      touchMin: 0,
      focusRing: const PFocusRingStyle(radius: PRounded.r3),
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        selected: current,
        label: name,
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, size) => PressScale(
        pressed: pressed,
        size: size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: _cellGap,
            children: [
              PNotificationBadge(
                show: item.notification,
                child: SizedBox.square(
                  dimension: PSpacing.x6,
                  child: Icon(
                    current ? item.selectedIcon : item.icon,
                    size: PSpacing.x6,
                    color: color,
                  ),
                ),
              ),
              // 이름은 칸이 단다(줄어든 바에서도 남는다) — 보이는 라벨을 한 번 더 읽지 않는다
              if (!labelsHidden)
                ExcludeSemantics(
                  child: Text(
                    item.label,
                    key: const ValueKey('bottom-navigation-label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    // 글자 크기 설정을 따르지 않는다(SEED — 커지면 칸 밖으로 넘친다)
                    textScaler: TextScaler.noScaling,
                    style: PTypography.t1.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCell extends StatelessWidget {
  const _AddCell({
    required this.add,
    required this.compact,
    required this.onActivate,
    required this.duration,
  });

  final PBottomNavigationAdd add;
  final bool compact;
  final VoidCallback onActivate;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = bottomNavigationMetrics(compact: compact);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return PressArea(
      key: const ValueKey('bottom-navigation-add-cell'),
      enabled: true,
      onTap: () {
        onActivate();
        add.onPressed();
      },
      touchMin: 0,
      focusRing: const PFocusRingStyle(circle: true),
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: add.label,
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, size) => Center(
        // 누름 축소의 기준은 칸이 아니라 원 지름이다 — 펼침 44 · 줄어듦 36
        child: PressScale(
          pressed: pressed,
          size: Size.square(m.addSize),
          child: AnimatedContainer(
            duration: duration,
            curve: PEasing.easing,
            width: m.addSize,
            height: m.addSize,
            alignment: Alignment.center,
            child: AnimatedContainer(
              key: const ValueKey('bottom-navigation-add'),
              duration: reduce ? Duration.zero : PDuration.pressedScale,
              curve: PEasing.pressedScale,
              width: m.addSize,
              height: m.addSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pressed ? c.bgBrandSolidPressed : c.bgBrandSolid,
                shape: BoxShape.circle,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: m.addIcon),
                duration: duration,
                curve: PEasing.easing,
                builder: (context, size, _) =>
                    Icon(LucideIcons.plus500, size: size, color: c.staticWhite),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
