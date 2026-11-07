import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';
import 'package:groo_damda_app/shared/ds/notification_badge/p_notification_badge.dart';

/// 바의 타입 — root(탭 첫 화면 — 큰 제목 22, 왼쪽 버튼 없음) · standard(그 아래 화면 — 왼쪽 버튼 + 제목 18, 기본).
/// 스펙의 desktop(768 이상 Desk 의 머리)은 앱에 없다.
enum PTopNavigationType { root, standard }

/// 바 높이 — 폰 · 데스크톱 모든 화면이 같다. 위 안전 영역은 더한다.
const double kTopNavigationHeight = 56;

/// 아이콘 버튼 상자 = 누르는 영역 · 아이콘 크기.
const double kTopNavigationBox = PTouch.min;
const double kTopNavigationIcon = PSpacing.x6;

/// 화면 끝 → 맨 끝 버튼 상자(아이콘은 16).
const double kTopNavigationEdge = PSpacing.x1_5;

/// 제목 끝 ↔ 오른쪽 자리 최소 간격(SEED titleMinGap).
const double kTopNavigationTitleGap = PSpacing.x2;

/// 글자 크기 설정은 1.2배까지만 따른다 — 바 높이 56 은 그대로다.
const double kTopNavigationMaxTextScale = 1.2;

/// 왼쪽 버튼 → 제목(standard) — 화면 끝에서 제목까지 56 = 6 + 44 + 6.
const double _titleAfterLeading = PSpacing.x1_5;

/// 왼쪽 버튼이 없는 standard 제목 — 같은 자리(화면 끝 56)에 서려고 바의 6 을 뺀 50 을 띄운다(토큰 없음 — 6 + 44 에서 바의 6 을 뺀 값).
const double _titleWithoutLeading = 50;

/// root 제목 — 화면 끝에서 16 = 바의 6 + 10.
const double _titleRoot = PSpacing.x2_5;

/// 글 버튼 좌우 여백.
const double _textButtonPaddingX = PSpacing.x2_5;

TextScaler _scaler(BuildContext context) => MediaQuery.textScalerOf(
  context,
).clamp(minScaleFactor: 1, maxScaleFactor: kTopNavigationMaxTextScale);

/// 제목 글자 — root t8 22/30 · standard t6 18/24, 700.
@visibleForTesting
TextStyle topNavigationTitleStyle(PTopNavigationType type, Color color) =>
    (type == PTopNavigationType.root ? PTypography.t8 : PTypography.t6)
        .copyWith(color: color, fontWeight: FontWeight.w700);

/// 상단 바 — 화면 맨 위에서 지금 화면의 이름과 이동(뒤로 · 닫기 · 주 메뉴), 화면의 동작 두셋을 둔다. 구조는 SEED Top
/// Navigation(Root · Standard, 2026-10-04), 수치 원본은 groo-design `specs/components/top-navigation.yaml`
/// (값은 `test/fixtures/design_spec/top-navigation.json`). 웹(desk-front `src/shared/ds/top-navigation`)과 같은 값이다.
///
/// 높이 56 + 위 안전 영역 — 바탕(불투명 bg-layer-default)은 화면 끝까지, 버튼 · 제목은 안전 영역 안이다. 스크롤해도 선 ·
/// 그림자를 긋지 않고 숨지도 않는다(맨 위에 붙이는 것은 쓰는 쪽 — 본문 위에 두는 Column 의 첫 칸). `AppBar` 대신 쓴다.
///
/// 제목은 왼쪽 정렬 · 700 · 한 줄 말줄임이고 오른쪽 자리 앞 8 을 늘 비운다. 글자 크기 설정은 1.2배까지만 따른다.
/// 오른쪽은 [PTopNavigationIconButton] 3개까지(2개 권장) 또는 [PTopNavigationTextButton] 하나 — 섞지 않는다. 넘치면 ⋯
/// 하나에 모은다(Menu Sheet — 이름 "{화면 이름} 더보기").
///
/// 뒤로 가기는 스스로 처리하지 않는다 — 왼쪽 버튼의 콜백만 받는다(셸이 pop · 상위 화면 이동을 정한다). 제목은
/// `Semantics(header: true)` — 화면 이름을 머리로 읽는다. 거래 검색 화면은 제목 자리에 검색칸을 둔다([PTopNavigation.search]).
class PTopNavigation extends StatelessWidget {
  PTopNavigation({
    super.key,
    this.type = PTopNavigationType.standard,
    required this.title,
    this.leading,
    this.actions = const [],
  }) : assert(
         type == PTopNavigationType.standard || leading == null,
         'root(탭 첫 화면)에는 왼쪽 버튼이 없다',
       ),
       search = null,
       assert(
         actions.every((a) => a is PTopNavigationIconButton)
             ? actions.length <= 3
             : actions.length == 1 &&
                   actions.single is PTopNavigationTextButton,
         '오른쪽은 아이콘 버튼 3개까지(2개 권장) 또는 글 버튼 하나 — 섞지 않는다',
       );

  /// 제목 자리에 검색칸을 두는 standard 바 — 거래 검색 화면(top-navigation.md "검색칸" · Migration notes "Desk 앱 — 제목 위젯
  /// 슬롯 + 보이지 않는 머리말"). 칸([search] — Text Field 상자형 medium 40 · 앞 돋보기 · 지우기)은 ← 다음 6 에서 시작해 오른쪽
  /// 자리 앞 8 까지 늘어나고 바 56 의 가운데(위아래 8)에 선다. 화면 이름 대신 칸이 서므로 [title]("검색")은 보이지 않는 머리말
  /// (`header` · `headingLevel 1`)로만 읽힌다. 칸의 글자도 바처럼 1.2배까지만 따른다.
  PTopNavigation.search({
    super.key,
    required this.title,
    required Widget this.search,
    this.leading,
    this.actions = const [],
  }) : type = PTopNavigationType.standard,
       assert(
         actions.every((a) => a is PTopNavigationIconButton) &&
             actions.length <= 3,
         '검색 바의 오른쪽은 아이콘 버튼 3개까지(2개 권장)',
       );

  final PTopNavigationType type;

  /// 제목 자리의 검색칸 — [PTopNavigation.search] 만. 있으면 [title] 은 보이지 않는 머리말이다.
  final Widget? search;

  /// 화면 이름 — 짧은 명사("알림" · "카드 혜택"), 마침표 없이.
  final String title;

  /// 왼쪽 버튼 — standard 만. [PTopNavigationIconButton.back] · [.close] · [.menu].
  final PTopNavigationIconButton? leading;

  /// 오른쪽 자리 — [PTopNavigationIconButton] 3개까지 또는 [PTopNavigationTextButton] 하나.
  final List<Widget> actions;

  /// 위 안전 영역을 더한 바 높이.
  static double heightOf(BuildContext context) =>
      kTopNavigationHeight + MediaQuery.paddingOf(context).top;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final safe = MediaQuery.paddingOf(context);
    final root = type == PTopNavigationType.root;
    final titleLeft = root
        ? _titleRoot
        : (leading == null ? _titleWithoutLeading : _titleAfterLeading);

    return Container(
      key: const ValueKey('top-navigation'),
      // 바탕은 위 안전 영역까지 칠한다
      color: c.bgLayerDefault,
      padding: EdgeInsets.only(
        top: safe.top,
        left: kTopNavigationEdge + safe.left,
        right: kTopNavigationEdge + safe.right,
      ),
      child: SizedBox(
        height: kTopNavigationHeight,
        child: Row(
          children: [
            ?leading,
            if (search != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: titleLeft),
                  child: _SearchSlot(heading: title, child: search!),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: titleLeft),
                  child: Semantics(
                    header: true,
                    // 안드로이드는 headingLevel > 0 일 때만 머리말로 잡는다(제목 이동) — 화면 제목은 1단계
                    headingLevel: 1,
                    // 화면이 바뀔 때 안드로이드가 화면 이름으로 읽는다(AppBar 를 걷은 화면)
                    namesRoute: true,
                    child: Text(
                      title,
                      key: const ValueKey('top-navigation-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      textScaler: _scaler(context),
                      style: topNavigationTitleStyle(type, c.fgNeutral),
                    ),
                  ),
                ),
              ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: kTopNavigationTitleGap),
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

/// 검색칸 자리 — 보이지 않는 머리말(화면 이름) 위에 칸을 세운다. 머리말은 칸과 같은 자리를 차지해 읽는 순서가 바의 ← 다음이다.
class _SearchSlot extends StatelessWidget {
  const _SearchSlot({required this.heading, required this.child});

  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Semantics(
            key: const ValueKey('top-navigation-search-heading'),
            container: true,
            header: true,
            headingLevel: 1,
            namesRoute: true,
            label: heading,
            child: const SizedBox.expand(),
          ),
        ),
        // 바의 제목 · 글 버튼과 같은 1.0 ~ 1.2 — 글자를 줄인 설정에서도 칸 글만 작아지지 않는다
        MediaQuery.withClampedTextScaling(
          minScaleFactor: 1,
          maxScaleFactor: kTopNavigationMaxTextScale,
          child: KeyedSubtree(
            key: const ValueKey('top-navigation-search'),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// 상단 바의 아이콘 버튼 — 상자 44 = 누르는 영역 · 아이콘 24(lucide 선 아이콘). 버튼끼리 붙는다(아이콘 중심 간격 44).
/// 바탕은 누를 때만 bg-layer-default-pressed(모서리 8)이고 2px 거리 축소 — 본문의 Button iconOnly(40 · 18)와 다른 부품이다.
/// 막히면 아이콘이 fg-disabled(흐리게 하지 않는다).
///
/// [label] 은 이름 — 동작이나 대상("검색" · "알림" · "{화면 이름} 더보기"). [notification] 이면 벨 오른쪽 위에 알림 점(Notification
/// Badge small — 점만)을 달고 이름에 "새 알림 있음" 을 넣는 것은 부르는 쪽이다("알림, 새 알림 있음").
///
/// [selected] 를 주면 켜고 끄는 단추다(금액 가리기) — 이름은 그대로 두고 [icon] 은 지금 상태를 넘긴다. 켬은 선 2.5 · 끔은
/// 선 2 이고 색은 켬 · 끔 모두 fg-neutral 이다(끔을 흐리게 두지 않는다 — 아이콘 줄이 고르다). 켬의 선 2.5 는 [selectedIcon].
class PTopNavigationIconButton extends StatelessWidget {
  const PTopNavigationIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selectedIcon,
    this.notification = false,
    this.selected,
    this.enabled = true,
  });

  /// ← "뒤로" — 들어온 화면으로(History). 앞 화면이 없으면 상위 화면으로 가는 것은 셸이 정한다.
  const PTopNavigationIconButton.back({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  }) : icon = LucideIcons.chevronLeft,
       selectedIcon = null,
       notification = false,
       selected = null;

  /// ✕ "닫기" — 모달 · 독립 흐름을 닫는다(입력한 값이 있으면 확인은 부르는 쪽).
  const PTopNavigationIconButton.close({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  }) : icon = LucideIcons.x,
       selectedIcon = null,
       notification = false,
       selected = null;

  /// ☰ "주 메뉴" — 주 메뉴를 연다(HR 폰). Desk 폰은 하단 탭 바다.
  const PTopNavigationIconButton.menu({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  }) : icon = LucideIcons.menu,
       selectedIcon = null,
       notification = false,
       selected = null;

  /// 기본 굵기(선 2) lucide 아이콘.
  final IconData icon;

  /// [selected] 가 true 일 때의 선 2.5 판(`LucideIcons.eyeOff500` …) — 없으면 [icon] 그대로. 글꼴을 코드로 만들면 릴리스 빌드의
  /// 아이콘 트리 셰이킹이 막히므로 상수로 넘긴다.
  final IconData? selectedIcon;
  final String label;
  final VoidCallback? onPressed;
  final bool notification;

  /// 켜고 끄는 단추 — null 이면 보통 버튼.
  final bool? selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = enabled && onPressed != null;
    final color = active ? c.fgNeutral : c.fgDisabled;
    final glyph = selected == true ? (selectedIcon ?? icon) : icon;

    return PressArea(
      enabled: active,
      onTap: onPressed,
      // 상자 44 가 곧 누르는 영역이다 — 보이지 않는 여백을 더하지 않는다
      touchMin: 0,
      // 키보드 초점 링 — 상자 안쪽 2px (top-navigation.md focused)
      focusRing: const PFocusRingStyle(radius: PRounded.r2, inset: true),
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        toggled: selected,
        label: label,
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, size) => PressScale(
        pressed: pressed,
        size: size,
        child: AnimatedContainer(
          key: const ValueKey('top-navigation-icon-button'),
          duration: _colorDuration(context),
          curve: PEasing.easing,
          width: kTopNavigationBox,
          height: kTopNavigationBox,
          decoration: BoxDecoration(
            color: pressed ? c.bgLayerDefaultPressed : const Color(0x00000000),
            borderRadius: BorderRadius.circular(PRounded.r2),
          ),
          alignment: Alignment.center,
          child: PNotificationBadge(
            show: notification,
            child: SizedBox.square(
              dimension: kTopNavigationIcon,
              child: Icon(glyph, size: kTopNavigationIcon, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// 상단 바의 글 버튼 — 오른쪽 자리에 하나만("완료" · "모두 읽음"), 아이콘 버튼과 섞지 않는다. 높이 44 · 좌우 10 · t5 16/22 ·
/// 500 · 모서리 8. 누르면 바탕 + 2px 거리 축소(기준 max(44, 폭 ÷ 4, 24)), 막히면 fg-disabled. 동사로 짧게.
class PTopNavigationTextButton extends StatelessWidget {
  const PTopNavigationTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = enabled && onPressed != null;
    final color = active ? c.fgNeutral : c.fgDisabled;

    return PressArea(
      enabled: active,
      onTap: onPressed,
      touchMin: 0,
      focusRing: const PFocusRingStyle(radius: PRounded.r2, inset: true),
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: label,
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, size) => PressScale(
        pressed: pressed,
        size: size,
        child: AnimatedContainer(
          key: const ValueKey('top-navigation-text-button'),
          duration: _colorDuration(context),
          curve: PEasing.easing,
          height: kTopNavigationBox,
          padding: const EdgeInsets.symmetric(horizontal: _textButtonPaddingX),
          decoration: BoxDecoration(
            color: pressed ? c.bgLayerDefaultPressed : const Color(0x00000000),
            borderRadius: BorderRadius.circular(PRounded.r2),
          ),
          alignment: Alignment.center,
          // 이름은 버튼이 단다 — 글을 한 번 더 읽지 않는다
          child: ExcludeSemantics(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textScaler: _scaler(context),
              style: PTypography.t5.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Duration _colorDuration(BuildContext context) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
    ? Duration.zero
    : PDuration.colorTransition;
