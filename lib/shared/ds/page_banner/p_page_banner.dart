import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/callout/feedback_parts.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_content.dart';

/// 톤 — neutral(상태가 따로 없는 안내, 기본) · informative(새 버전 · 베타 · 권한 제한) · positive(승인됨 · 완료) ·
/// warning(만료 임박 · 누락) · critical(연결 끊김 · 거절 · 편집 불가).
enum PPageBannerTone { neutral, informative, positive, warning, critical }

/// 바탕 — weak(옅은 바탕, 기본 — Callout 과 같은 짝) · solid(짙은 바탕 — 연결 끊김 · 거절 · 편집 불가처럼 무거운 상태에만).
enum PPageBannerVariant { weak, solid }

/// 상호작용 — display(보이기만, 기본 — 글 버튼 하나를 둘 수 있다) · actionable(띠 전체가 버튼 — 뒤 화살표) ·
/// dismissible(닫기 — 한 번 보면 되는 안내에만, 경고 · 오류는 닫지 못한다).
enum PPageBannerInteraction { display, actionable, dismissible }

/// 글 버튼 — 동작 이름 하나("다시 연결" · "업데이트" · "구독 보기").
class PPageBannerButton {
  const PPageBannerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// 바탕 × 톤의 색 — 바탕 · 누름 바탕 · 글(아이콘 · 버튼 · 화살표 · 닫기도 같은 색). 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
({Color background, Color pressedBackground, Color foreground})
resolvePPageBannerColors(
  PColors c,
  PPageBannerVariant variant,
  PPageBannerTone tone,
) => switch ((variant, tone)) {
  (PPageBannerVariant.weak, PPageBannerTone.neutral) => (
    background: c.bgNeutralWeak,
    pressedBackground: c.bgNeutralWeakPressed,
    foreground: c.fgNeutral,
  ),
  (PPageBannerVariant.weak, PPageBannerTone.informative) => (
    background: c.bgInformativeWeak,
    pressedBackground: c.bgInformativeWeakPressed,
    foreground: c.fgInformativeContrast,
  ),
  (PPageBannerVariant.weak, PPageBannerTone.positive) => (
    background: c.bgPositiveWeak,
    pressedBackground: c.bgPositiveWeakPressed,
    foreground: c.fgPositiveContrast,
  ),
  (PPageBannerVariant.weak, PPageBannerTone.warning) => (
    background: c.bgWarningWeak,
    pressedBackground: c.bgWarningWeakPressed,
    foreground: c.fgWarningContrast,
  ),
  (PPageBannerVariant.weak, PPageBannerTone.critical) => (
    background: c.bgCriticalWeak,
    pressedBackground: c.bgCriticalWeakPressed,
    foreground: c.fgCriticalContrast,
  ),
  (PPageBannerVariant.solid, PPageBannerTone.neutral) => (
    background: c.bgNeutralInverted,
    pressedBackground: c.bgNeutralInvertedPressed,
    foreground: c.fgNeutralInverted,
  ),
  (PPageBannerVariant.solid, PPageBannerTone.informative) => (
    background: c.bgInformativeSolid,
    pressedBackground: c.bgInformativeSolidPressed,
    foreground: c.staticWhite,
  ),
  (PPageBannerVariant.solid, PPageBannerTone.positive) => (
    background: c.bgPositiveSolid,
    pressedBackground: c.bgPositiveSolidPressed,
    foreground: c.staticWhite,
  ),
  (PPageBannerVariant.solid, PPageBannerTone.warning) => (
    background: c.bgWarningSolid,
    pressedBackground: c.bgWarningSolidPressed,
    foreground: c.staticWhite,
  ),
  (PPageBannerVariant.solid, PPageBannerTone.critical) => (
    background: c.bgCriticalSolid,
    pressedBackground: c.bgCriticalSolidPressed,
    foreground: c.staticWhite,
  ),
};

/// 톤의 기본 앞 아이콘 — Callout 과 같다(info · info · circle-check · triangle-alert · circle-alert).
@visibleForTesting
IconData pPageBannerToneIcon(PPageBannerTone tone) => switch (tone) {
  PPageBannerTone.neutral || PPageBannerTone.informative => LucideIcons.info,
  PPageBannerTone.positive => LucideIcons.circleCheck,
  PPageBannerTone.warning => LucideIcons.triangleAlert,
  PPageBannerTone.critical => LucideIcons.circleAlert,
};

// 띠 · 글 · 아이콘 치수(page-banner.yaml 공통)
const double _minHeight = 40;
const double _paddingX = PSpacing.globalGutter;
const double _paddingY = PSpacing.x2_5;
const double _gap = PSpacing.x2;
const double _iconSize = 16;
const double _iconTop = PSpacing.x0_5;
const double _closeBox = 40;
const double _buttonBleed = 11;
const double _buttonGap = PSpacing.x1_5;

typedef _Look = ({Color background, Color pressedBackground, Color foreground});

/// Page Banner — 페이지 맨 위(머리 바로 아래)에 화면 폭 전체로 놓이는 띠. 그 페이지 전체의 상태를 알린다(증권 연결
/// 끊김 · Pro 만료 예정 · 새 버전). 한 화면에 하나. 구조는 SEED Page Banner(2026-10-02), 수치 원본은 groo-design
/// `specs/components/page-banner.yaml`(값은 `test/fixtures/design_spec/page-banner.json`). 웹(desk-front
/// `src/shared/ds/page-banner`)과 같은 값이다.
///
///   [tone]         다섯 톤
///   [variant]      weak(기본 — bg-*-weak + fg-*-contrast) · solid(bg-*-solid + 흰 글, neutral 은 반전 짝)
///   [interaction]  display([button] 하나) · actionable([onPressed], 뒤 화살표) · dismissible([dismissLabel] 닫기)
///   [title]        상태를 나타내는 짧은 말(연결 끊김 · 곧 만료) — 꼭 필요할 때만
///   [description]  본문 — 제목을 되풀이하지 않는다
///   [alert]        나중에 나타나는 경고 · 위험(연결이 끊김)은 보조 기술에 알린다(웹 role="alert")
///
/// 띠 — 화면 폭 · 모서리 0 · 좌우 화면 여백 24 · 위아래 10 · 최소 40. 아이콘 16 은 위 2 를 두어 첫 줄 가운데에
/// 붙고(여러 줄이어도 첫 줄), 아이콘 ↔ 글 8. 제목(700) · 본문(500)은 t4 한 문단(사이 띄어쓰기 두 칸). 본문과 버튼은
/// 한 줄이면 양 끝 — 한 줄에 안 들어가면 버튼이 다음 줄 본문 시작선으로 간다(줄 사이 6). 버튼은 t3 · 700 글 버튼이고
/// 누르는 높이 40(글 + 사방 11)에 띠 높이는 그대로다. 뒤 화살표 16 · 닫기는 띠 가운데에 서고 글과 8. 닫기는
/// 투명 상자 40 × 40 · 모서리 8, 아이콘은 오른쪽 끝에서 24.
/// Actionable — 누르면 그 바탕의 누름 색 + 안의 내용만 세로 2px 거리 축소(바탕은 그대로 — 기준 max(높이, 폭 ÷ 4, 24)을
///   띠에서 누르는 순간 잰다). 버튼 · 닫기는 바탕 없이 각자 축소(기준 40). 모션 줄이기면 축소하지 않는다.
/// 닫기 — 바로 걷고(모션 없음) 초점이 닫기에 있었으면 다음 요소로 간다. [open] · [onDismiss] 로 닫음을 기억한다 —
///   [open] 을 주지 않으면 스스로 닫는다.
/// 웹의 hover · 키보드 포커스 링은 앱에 없다.
class PPageBanner extends StatefulWidget {
  const PPageBanner({
    super.key,
    required this.description,
    this.tone = PPageBannerTone.neutral,
    this.variant = PPageBannerVariant.weak,
    this.interaction = PPageBannerInteraction.display,
    this.title,
    this.icon,
    this.hideIcon = false,
    this.button,
    this.onPressed,
    this.open,
    this.onDismiss,
    this.dismissLabel,
    this.alert = false,
  }) : assert(
         interaction != PPageBannerInteraction.actionable || onPressed != null,
         'actionable 은 띠를 누르면 하는 일(onPressed)이 있다',
       ),
       assert(
         interaction == PPageBannerInteraction.actionable || onPressed == null,
         'onPressed 는 actionable 에만 쓴다',
       ),
       assert(
         button == null || interaction == PPageBannerInteraction.display,
         '버튼은 display 에만 둔다 — actionable 은 띠 전체를 누르고, 닫기와 버튼은 함께 두지 않는다',
       ),
       assert(
         interaction != PPageBannerInteraction.dismissible ||
             (dismissLabel != null && dismissLabel != ''),
         'dismissible 의 닫기에는 이름(dismissLabel)이 꼭 있다',
       ),
       assert(
         interaction == PPageBannerInteraction.dismissible ||
             (open == null && onDismiss == null),
         'open · onDismiss 는 dismissible 에만 쓴다',
       );

  final PPageBannerTone tone;
  final PPageBannerVariant variant;
  final PPageBannerInteraction interaction;
  final String? title;
  final String description;

  /// 앞 아이콘 — 주지 않으면 톤의 기본 아이콘.
  final IconData? icon;

  /// 앞 아이콘을 두지 않는다.
  final bool hideIcon;

  /// 글 버튼 하나 — display 에만.
  final PPageBannerButton? button;

  /// 띠를 누르면 하는 일 — actionable 에만.
  final VoidCallback? onPressed;

  /// 보이는지 — 주면 부르는 쪽이 정한다(닫은 것을 기억해 다시 띄우지 않는다). 주지 않으면 스스로 닫는다.
  final bool? open;

  /// 닫기를 누르면.
  final VoidCallback? onDismiss;

  /// 닫기 버튼의 이름("닫기") — 호출하는 쪽이 지역화해 넘긴다.
  final String? dismissLabel;

  /// 나중에 나타나는 경고 · 위험이면 보조 기술에 알린다.
  final bool alert;

  @override
  State<PPageBanner> createState() => _PPageBannerState();
}

class _PPageBannerState extends State<PPageBanner> {
  bool _selfOpen = true;
  final FocusNode _closeFocus = FocusNode(debugLabel: 'PPageBanner close');

  bool get _dismissible =>
      widget.interaction == PPageBannerInteraction.dismissible;
  bool get _actionable =>
      widget.interaction == PPageBannerInteraction.actionable;

  @override
  void dispose() {
    _closeFocus.dispose();
    super.dispose();
  }

  void _dismiss() {
    moveFocusAfterDismiss(_closeFocus);
    widget.onDismiss?.call();
    if (widget.open == null) setState(() => _selfOpen = false);
  }

  /// 제목 · 본문 — 한 문단. 제목 700 · 본문 500.
  TextSpan _bodySpan(Color color) => TextSpan(
    style: PTypography.t4.copyWith(color: color, fontWeight: FontWeight.w500),
    children: [
      if (widget.title != null) ...[
        TextSpan(
          text: keepAll(widget.title!),
          semanticsLabel: widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const TextSpan(text: '  '),
      ],
      TextSpan(
        text: keepAll(widget.description),
        semanticsLabel: widget.description,
      ),
    ],
  );

  TextStyle _buttonStyle(Color color) =>
      PTypography.t3.copyWith(color: color, fontWeight: FontWeight.w700);

  /// 본문 + 버튼 — 한 줄에 들어가면 버튼은 오른쪽 끝, 안 들어가면 다음 줄 본문 시작선(줄 사이 6). 띠의 위아래
  /// 여백 10 은 줄 안의 것마다 둔다 — 버튼의 누르는 자리(글 + 사방 11)가 줄 안에 들어오게.
  Widget _content(BuildContext context, _Look look) {
    final body = Text.rich(
      key: const ValueKey('page-banner-text'),
      _bodySpan(look.foreground),
    );
    final button = widget.button;
    if (button == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: _paddingY),
        child: body,
      );
    }
    final buttonView = _bannerButton(button, look);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyWidth = measureTextWidth(context, _bodySpan(look.foreground));
        final buttonWidth = measureTextWidth(
          context,
          TextSpan(text: button.label, style: _buttonStyle(look.foreground)),
        );
        final oneLine =
            bodyWidth + _buttonGap + buttonWidth <= constraints.maxWidth;
        if (oneLine) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _paddingY),
                  child: body,
                ),
              ),
              const SizedBox(width: _buttonGap),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: _paddingY),
                child: buttonView,
              ),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: _paddingY),
              child: body,
            ),
            const SizedBox(height: _buttonGap),
            Padding(
              padding: const EdgeInsets.only(bottom: _paddingY),
              child: buttonView,
            ),
          ],
        );
      },
    );
  }

  /// 글 버튼 — t3 · 700, 바탕 없이 눌리면 2px 축소(기준: 글 + 사방 11 의 40).
  Widget _bannerButton(PPageBannerButton button, _Look look) {
    return FeedbackPress(
      onPressed: button.onPressed,
      slop: const EdgeInsets.all(_buttonBleed),
      basisInflate: const EdgeInsets.all(_buttonBleed),
      builder: (context, pressed, scale) => FeedbackScale(
        scale: scale,
        child: Text(
          button.label,
          key: const ValueKey('page-banner-button'),
          maxLines: 1,
          softWrap: false,
          style: _buttonStyle(look.foreground),
        ),
      ),
    );
  }

  Widget _closeButton(_Look look) {
    return FeedbackPress(
      focusNode: _closeFocus,
      semanticLabel: widget.dismissLabel,
      excludeChildSemantics: true,
      onPressed: _dismiss,
      builder: (context, pressed, scale) => FeedbackScale(
        scale: scale,
        child: SizedBox(
          key: const ValueKey('page-banner-close'),
          width: _closeBox,
          height: _closeBox,
          child: Center(
            child: Icon(LucideIcons.x, size: _iconSize, color: look.foreground),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissible && !(widget.open ?? _selfOpen)) {
      return const SizedBox.shrink();
    }
    final c = context.colors;
    final look = resolvePPageBannerColors(c, widget.variant, widget.tone);
    final icon = widget.hideIcon
        ? null
        : (widget.icon ?? pPageBannerToneIcon(widget.tone));
    final trailing = _actionable || _dismissible;

    // 안의 내용 — 아이콘 · 글 · 화살표 · 닫기 자리. Actionable 을 누르는 동안 이 층만 준다(바탕은 그대로)
    final inner = Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: _paddingX),
            if (icon != null) ...[
              // 첫 줄 가운데 — 위 2(위 여백 10 + 2)
              Padding(
                padding: const EdgeInsets.only(top: _paddingY + _iconTop),
                child: Icon(
                  icon,
                  key: const ValueKey('page-banner-icon'),
                  size: _iconSize,
                  color: look.foreground,
                ),
              ),
              const SizedBox(width: _gap),
            ],
            Expanded(child: _content(context, look)),
            if (trailing) const SizedBox(width: _gap + _iconSize),
            const SizedBox(width: _paddingX),
          ],
        ),
        if (_actionable)
          Positioned(
            right: _paddingX,
            top: 0,
            bottom: 0,
            width: _iconSize,
            child: Center(
              child: Icon(
                LucideIcons.chevronRight,
                key: const ValueKey('page-banner-chevron'),
                size: _iconSize,
                color: look.foreground,
              ),
            ),
          ),
        if (_dismissible)
          // 아이콘은 오른쪽 끝에서 24 — 40 × 40 상자는 오른쪽 가장자리에서 12(= 24 − 12)
          Positioned(
            right: _paddingX - (_closeBox - _iconSize) / 2,
            top: 0,
            bottom: 0,
            width: _closeBox,
            child: Center(child: _closeButton(look)),
          ),
      ],
    );

    Widget band(Color background, {Widget Function(Widget)? wrapInner}) {
      return DecoratedBox(
        key: const ValueKey('page-banner-box'),
        decoration: BoxDecoration(color: background),
        // 바탕은 화면 끝까지, 아이콘 · 글 · 화살표 · 닫기는 좌우 안전 영역 안
        child: PScreenContent(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minHeight),
            child: wrapInner == null ? inner : wrapInner(inner),
          ),
        ),
      );
    }

    if (_actionable) {
      return FeedbackPress(
        onPressed: widget.onPressed,
        builder: (context, pressed, scale) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: pressed ? look.pressedBackground : look.background,
          ),
          duration: PDuration.colorTransition,
          curve: PEasing.easing,
          builder: (context, background, _) => band(
            background!,
            wrapInner: (child) => FeedbackScale(scale: scale, child: child),
          ),
        ),
      );
    }
    // 글 버튼의 누르는 자리(글 + 사방 11)는 줄 밖으로 번지므로 띠 전체가 받는다
    return Semantics(
      container: true,
      liveRegion: widget.alert,
      child: FeedbackSlopRoot(child: band(look.background)),
    );
  }
}
