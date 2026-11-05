import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart'
    show PTouchTarget;
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';
import 'package:groo_damda_app/shared/ds/overflow_center/p_overflow_center.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

/// 변형 — 한 화면의 강조 버튼(Solid)은 하나.
enum PButtonVariant {
  /// 브랜드 색 채움 — 서비스 핵심 액션 하나(Desk 거래 추가)
  brandSolid,

  /// 짙은 회색 채움 — 대부분의 CTA(저장 · 확인 · 다음). 기본값
  neutralSolid,

  /// 옅은 회색 채움 — 대부분의 액션, CTA 옆 보조(취소)
  neutralWeak,

  /// 빨강 채움 — 되돌릴 수 없는 작업의 확정(주로 Alert Dialog)
  criticalSolid,

  /// 테두리 + 브랜드 글자 — neutralOutline 과 짝
  brandOutline,

  /// 테두리 + 본문 글자 — 가장 낮은 위계
  neutralOutline,

  /// 배경 없음 — 메뉴 · 툴바 · 목록의 가벼운 액션. 글자색은 [PButtonGhostColor]
  ghost,
}

/// 크기 — 이름이 아니라 높이로 고른다. xsmall 32(알약) · small 36 · medium 40(기본) · large 48.
enum PButtonSize { xsmall, small, medium, large }

/// ghost 의 글자색(SEED ghost 의 color) — 배경 · 누름은 ghost 그대로.
enum PButtonGhostColor { neutral, neutralSubtle, brand, critical }

/// 가장자리 맞춤(SEED bleed) — 그 방향 가로 여백만 0. ghost 는 텍스트 버튼이 되어 배경 없이 글자색으로만 반응한다.
enum PButtonFlush { left, right }

/// Button — 구조는 SEED Action Button(2026-09-30). 수치 원본은 groo-design `specs/components/button.yaml`
/// (값은 `test/fixtures/design_spec/button.json` — 테스트가 위젯이 그 값과 같은지 본다). 웹(desk-front
/// `src/shared/ds/button`)과 같은 값이다.
///
///   [PButton] — 글자, 앞 또는 뒤 아이콘 하나까지(둘 다는 쓰지 않는다)
///   [PButton.icon] — 아이콘만, 정사각. 이름(semanticLabel)이 반드시 있다
///
/// 상태 — 누르면 누름 색 + 세로 2px 거리 축소(배율 = (기준 − 2) ÷ 기준, 기준 = max(높이, 폭 ÷ 4, 24) — 모션
///   줄이기면 축소하지 않는다). loading 은 누름 색 위 로딩 원(라벨 자리는 그대로 — 글자 · 아이콘만 투명하게)이고
///   누르기를 삼킨다(두 번 제출 방지). onPressed 가 없으면 비활성 — 전용 색이고 흐리게 하지 않는다.
///   올림 · 포커스 링은 웹 상태라 앱에는 없다.
/// 누르는 영역은 보이는 크기와 따로 44 × 44 까지 넓힌다 — 놓인 자리를 넓히지 않는다(부모 상자 안에서만 받는다).
class PButton extends StatefulWidget {
  const PButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.variant = PButtonVariant.neutralSolid,
    this.size = PButtonSize.medium,
    this.ghostColor = PButtonGhostColor.neutral,
    this.prefixIcon,
    this.suffixIcon,
    this.flush,
    this.loading = false,
    this.labelLines = 1,
    this.focusNode,
    this.semanticLabel,
  }) : assert(
         prefixIcon == null || suffixIcon == null,
         '앞 · 뒤 아이콘은 하나만 쓴다(button.yaml layout withText)',
       ),
       icon = null;

  /// 아이콘만 — 정사각. [semanticLabel] 이 이 버튼의 이름이다.
  const PButton.icon({
    super.key,
    required IconData this.icon,
    required String this.semanticLabel,
    required this.onPressed,
    this.variant = PButtonVariant.neutralSolid,
    this.size = PButtonSize.medium,
    this.ghostColor = PButtonGhostColor.neutral,
    this.loading = false,
  }) : label = null,
       labelLines = 1,
       prefixIcon = null,
       suffixIcon = null,
       flush = null,
       focusNode = null;

  final String? label;
  final IconData? icon;
  final String? semanticLabel;

  /// 없으면 비활성. 누른 동작이 끝날 때까지 한 번이다 — [Future] 를 돌려주면(`async` 함수 · mutateAsync) 그것이
  /// 끝날 때(이행 · 거부)까지 다음 누름을 버린다(시간 창은 없다, 사용자 결정 2026-10-08). 돌려주지 않으면 잠그지 않는다.
  /// 거부는 삼키지 않고 그대로 넘긴다 — 부르는 쪽이 잡지 않은 오류는 전처럼 한 번 알려진다.
  final FutureOr<void> Function()? onPressed;
  final PButtonVariant variant;
  final PButtonSize size;
  final PButtonGhostColor ghostColor;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final PButtonFlush? flush;

  /// 누름 색 위 로딩 원 + 누르기 막기.
  final bool loading;

  /// 라벨 줄 수 — 기본 1(한 줄, 줄바꿈 · 말줄임 없음). 2 이상이면 글에 넣은 줄바꿈(`\n`)에서만 줄을 바꾼다(통계 기간 버튼의
  /// 다른 해 직접 기간 "2025-01-01 ~ / 2026-03-31"). 버튼 높이는 글을 따라 자란다(최소 높이는 그대로).
  final int labelLines;

  /// 초점 노드 — 밖에서 초점을 되돌릴 때(고르기 시트가 닫힌 뒤 열었던 단추로). 없으면 단추가 스스로 쥔다.
  final FocusNode? focusNode;

  bool get _iconOnly => icon != null;

  /// 이 버튼이 라벨 한 줄을 다 보이려면 필요한 폭 — 좌우 여백 + 글 + 아이콘. 짝 버튼([PResponsivePair])이 자기 몫(반 또는 비율)에
  /// 들어가는지 재는 데 쓴다.
  double naturalWidth(BuildContext context) {
    final s = _sizes[size]!;
    if (_iconOnly) return s.height;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: s.text.copyWith(fontWeight: FontWeight.w700),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final iconWidth = (prefixIcon != null || suffixIcon != null)
        ? s.textIcon + s.gap
        : 0;
    return painter.width + iconWidth + 2 * s.paddingX;
  }

  @override
  State<PButton> createState() => _PButtonState();
}

/// 크기마다의 값(button.yaml 크기 · 크기 × 배치).
class _SizeSpec {
  const _SizeSpec({
    required this.height,
    required this.radius,
    required this.circle,
    required this.paddingX,
    required this.paddingY,
    required this.gap,
    required this.text,
    required this.textIcon,
    required this.iconOnlyPadding,
    required this.iconOnlyIcon,
  });

  final double height;
  final double radius;
  final double circle;
  final double paddingX;
  final double paddingY;
  final double gap;
  final TextStyle text;
  final double textIcon;
  final double iconOnlyPadding;
  final double iconOnlyIcon;
}

const Map<PButtonSize, _SizeSpec> _sizes = {
  PButtonSize.xsmall: _SizeSpec(
    height: 32,
    radius: PRounded.full,
    circle: 14,
    paddingX: PSpacing.x3_5,
    paddingY: PSpacing.x1_5,
    gap: PSpacing.x1,
    text: PTypography.t3,
    textIcon: 14,
    iconOnlyPadding: PSpacing.x1_5,
    iconOnlyIcon: 14,
  ),
  PButtonSize.small: _SizeSpec(
    height: 36,
    radius: PRounded.r2,
    circle: 14,
    paddingX: PSpacing.x3_5,
    paddingY: PSpacing.x2,
    gap: PSpacing.x1,
    text: PTypography.t4,
    textIcon: 14,
    iconOnlyPadding: PSpacing.x2,
    iconOnlyIcon: 16,
  ),
  PButtonSize.medium: _SizeSpec(
    height: 40,
    radius: PRounded.r2,
    circle: 16,
    paddingX: PSpacing.x4,
    paddingY: PSpacing.x2_5,
    gap: PSpacing.x1_5,
    text: PTypography.t4,
    textIcon: 16,
    iconOnlyPadding: PSpacing.x2_5,
    iconOnlyIcon: 18,
  ),
  // SEED large 는 52 — groo 는 48(사용자 결정)
  PButtonSize.large: _SizeSpec(
    height: 48,
    radius: PRounded.r3,
    circle: 18,
    paddingX: PSpacing.x5,
    paddingY: PSpacing.x3,
    gap: PSpacing.x2,
    text: PTypography.t6,
    textIcon: 22,
    iconOnlyPadding: PSpacing.x3,
    iconOnlyIcon: 22,
  ),
};

/// 변형 · 상태의 색 — 바탕 · 글자 · 테두리 · 로딩 원(button.yaml 변형별 색).
typedef PButtonColors = ({
  Color background,
  Color foreground,
  Color? border,
  Color circleTrack,
  Color circleRange,
});

/// 스펙의 상태 — 웹의 hovered · focused 는 앱에 없다.
enum PButtonState { enabled, pressed, loading, disabled }

/// 변형 · ghost 글자색 · 가장자리 맞춤 · 상태의 색 — 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
PButtonColors resolvePButtonColors(
  PColors c, {
  required PButtonVariant variant,
  required PButtonState state,
  PButtonGhostColor ghostColor = PButtonGhostColor.neutral,
  PButtonFlush? flush,
}) {
  final pressedLike =
      state == PButtonState.pressed || state == PButtonState.loading;
  final outline =
      variant == PButtonVariant.brandOutline ||
      variant == PButtonVariant.neutralOutline;
  final (
    Color bg,
    Color bgPressed,
    Color fg,
    Color track,
    Color range,
  ) = switch (variant) {
    PButtonVariant.brandSolid => (
      c.bgBrandSolid,
      c.bgBrandSolidPressed,
      c.staticWhite,
      c.staticWhite.withValues(alpha: 0.3),
      c.staticWhite,
    ),
    PButtonVariant.neutralSolid => (
      c.bgNeutralInverted,
      c.bgNeutralInvertedPressed,
      c.fgNeutralInverted,
      c.fgNeutralInverted.withValues(alpha: 0.3),
      c.fgNeutralInverted,
    ),
    PButtonVariant.neutralWeak => (
      c.bgNeutralWeak,
      c.bgNeutralWeakPressed,
      c.fgNeutral,
      c.gray500,
      c.fgNeutral,
    ),
    PButtonVariant.criticalSolid => (
      c.bgCriticalSolid,
      c.bgCriticalSolidPressed,
      c.staticWhite,
      c.staticWhite.withValues(alpha: 0.3),
      c.staticWhite,
    ),
    // 로딩 원은 stroke-brand-solid — Progress Circle brand 톤(다크는 밝은 짝). 채움 색 bg-brand-solid 는 다크에서도 짙어
    // 투명한 버튼 위에서 1.73:1 이었다(2026-10-08 까지)
    PButtonVariant.brandOutline => (
      const Color(0x00000000),
      c.bgLayerDefaultPressed,
      c.fgBrand,
      c.bgBrandWeakPressed,
      c.strokeBrandSolid,
    ),
    PButtonVariant.neutralOutline => (
      const Color(0x00000000),
      c.bgLayerDefaultPressed,
      c.fgNeutral,
      c.gray500,
      c.fgNeutral,
    ),
    PButtonVariant.ghost => (
      const Color(0x00000000),
      c.bgLayerDefaultPressed,
      switch (ghostColor) {
        PButtonGhostColor.neutral => c.fgNeutral,
        PButtonGhostColor.neutralSubtle => c.fgNeutralSubtle,
        PButtonGhostColor.brand => c.fgBrand,
        PButtonGhostColor.critical => c.fgCritical,
      },
      c.gray500,
      c.fgNeutral,
    ),
  };
  final border = outline ? c.strokeNeutralWeak : null;

  if (state == PButtonState.disabled) {
    // 전용 색 — 흐리게 하지 않는다. 테두리 · ghost 는 바탕이 없다
    return (
      background: outline || variant == PButtonVariant.ghost
          ? const Color(0x00000000)
          : c.bgDisabled,
      foreground: c.fgDisabled,
      border: border,
      circleTrack: track,
      circleRange: range,
    );
  }

  // 가장자리에 맞춘 ghost 는 텍스트 버튼 — 바탕 없이 글자색으로만 반응한다(흐린 글자 → 누르면 본문 글자)
  if (variant == PButtonVariant.ghost && flush != null) {
    return (
      background: const Color(0x00000000),
      foreground: pressedLike ? c.fgNeutral : c.fgNeutralSubtle,
      border: null,
      circleTrack: track,
      circleRange: range,
    );
  }

  return (
    // 테두리 버튼은 로딩에 누름 색을 깔지 않는다(button.yaml 에 loading 바탕이 없다)
    background: switch (state) {
      PButtonState.pressed => bgPressed,
      PButtonState.loading => outline ? bg : bgPressed,
      _ => bg,
    },
    foreground: fg,
    border: border,
    circleTrack: track,
    circleRange: range,
  );
}

class _PButtonState extends State<PButton> {
  bool _pressed = false;

  /// 키보드로 초점이 와 링을 그리는 중.
  bool _ringVisible = false;

  /// 누른 동작이 끝나기 전 — [PButton.onPressed] 가 돌려준 Future 가 끝날 때까지 다음 누름을 버린다.
  bool _inFlight = false;

  /// 누름 축소의 기준 길이 max(높이, 폭 ÷ 4, 24) — 누르는 순간 그려진 크기에서 잰다.
  double _pressBasis = 24;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) {
        _pressBasis = math.max(size.height, math.max(size.width / 4, 24));
      }
    }
    setState(() => _pressed = value);
  }

  void _activate() {
    // 로딩 중 · 누른 동작이 끝나기 전엔 누르기를 삼킨다 — 두 번 제출 방지
    if (!_enabled || widget.loading || _inFlight) return;
    final result = widget.onPressed!();
    if (result is! Future<void>) return;
    _inFlight = true;
    // 끝나면(이행 · 거부) 푼다. whenComplete 는 거부를 그대로 넘긴다 — 잡지 않은 오류는 처리되지 않은 오류로 알려진다
    unawaited(
      result.whenComplete(() {
        _inFlight = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _sizes[widget.size]!;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final state = !_enabled
        ? PButtonState.disabled
        : widget.loading
        ? PButtonState.loading
        : _pressed
        ? PButtonState.pressed
        : PButtonState.enabled;
    final colors = resolvePButtonColors(
      c,
      variant: widget.variant,
      state: state,
      ghostColor: widget.ghostColor,
      flush: widget.flush,
    );

    final iconOnly = widget._iconOnly;
    final borderWidth = colors.border == null ? 0.0 : 1.0;
    final padding = iconOnly
        ? EdgeInsets.all(s.iconOnlyPadding)
        : EdgeInsets.only(
            // 테두리 1px 는 가로 여백에 더한다 — 웹 border-box(border + padding)와 같은 폭
            left: widget.flush == PButtonFlush.left
                ? 0
                : s.paddingX + borderWidth,
            right: widget.flush == PButtonFlush.right
                ? 0
                : s.paddingX + borderWidth,
            top: s.paddingY,
            bottom: s.paddingY,
          );

    Widget content = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: colors.foreground),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, fg, _) {
        final iconSize = iconOnly ? s.iconOnlyIcon : s.textIcon;
        Widget glyph(IconData data) => Icon(data, size: iconSize, color: fg);
        if (iconOnly) return glyph(widget.icon!);
        // 라벨은 한 줄이다 — 폭이 모자라도(200% · 좁은 칸) 줄바꿈 · 말줄임 없이 가운데에서 버튼 밖으로
        // 그려지고 레이아웃 오류(RenderFlex overflow)를 내지 않는다(I-05 Q-021, 받아들임).
        return POverflowCenter(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: s.gap,
            children: [
              if (widget.prefixIcon != null) glyph(widget.prefixIcon!),
              Text(
                widget.label!,
                maxLines: widget.labelLines,
                softWrap: false,
                textAlign: TextAlign.center,
                style: s.text.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
              if (widget.suffixIcon != null) glyph(widget.suffixIcon!),
            ],
          ),
        );
      },
    );
    if (widget.loading) {
      // 라벨 자리는 그대로 — 글자 · 아이콘만 투명하게 하고 그 위에 로딩 원. 이름은 계속 읽는다
      content = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, alwaysIncludeSemantics: true, child: content),
          PProgressCircle.inherit(
            diameter: s.circle,
            thickness: 2,
            trackColor: colors.circleTrack,
            rangeColor: colors.circleRange,
          ),
        ],
      );
    }

    // 바탕색만 바뀐다(color-transition) — 크기 · 여백은 움직이지 않는다
    final box = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: colors.background),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, background, child) => Container(
        // 높이는 최소 높이다 — 글자를 키우면 상자가 글을 따라 늘어난다(100% 는 36 · 40 · 48 그대로). 아이콘만 있는 버튼은 정사각
        constraints: iconOnly
            ? BoxConstraints.tightFor(width: s.height, height: s.height)
            : BoxConstraints(minHeight: s.height),
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(s.radius),
        ),
        // 테두리 1px 는 세로 여백을 늘리지 않게 안쪽에 덧그린다(웹은 border 라 가로는 위 padding 에 1씩 더했다) — 테두리 있는 버튼도 100% 높이 36 · 40 · 48
        foregroundDecoration: colors.border == null
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(s.radius),
                border: Border.all(color: colors.border!, width: 1),
              ),
        child: child,
      ),
      // 가로는 내용만큼(부모가 폭을 정하면 그 폭의 가운데), 세로는 상자 가운데
      child: Align(
        widthFactor: iconOnly ? null : 1,
        heightFactor: iconOnly ? null : 1,
        child: content,
      ),
    );

    // 누름 축소 — 기준 길이에서 2px. 모션 줄이기 · 로딩 · 비활성이면 없다
    final shrink = state == PButtonState.pressed && !reduceMotion;
    final pressedBox = AnimatedScale(
      scale: shrink ? (_pressBasis - 2) / _pressBasis : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: box,
    );

    final l10n = AppLocalizations.of(context);
    // 누르는 영역 상자가 가장 바깥이다 — 안쪽 상자는 제 크기 밖에서 누른 것을 받지 않는다
    return PTouchTarget(
      minSize: PTouch.min,
      child: Semantics(
        container: true,
        button: true,
        enabled: _enabled,
        label: widget.semanticLabel,
        // 웹의 aria-busy — 바쁘다는 것을 이름 뒤에 읽는다
        value: widget.loading ? l10n.dsProgressCircleLabel : null,
        onTap: _enabled && !widget.loading ? _activate : null,
        excludeSemantics: iconOnly || widget.semanticLabel != null,
        // 앱 버튼도 포커스를 받는다 — Tab 순서에 들고 Space · Enter 로 누른다(button.yaml Behavior, 사용자 결정 2026-10-08)
        child: CallbackShortcuts(
          bindings: _enabled && !widget.loading
              ? {
                  const SingleActivator(LogicalKeyboardKey.space): _activate,
                  const SingleActivator(LogicalKeyboardKey.enter): _activate,
                  const SingleActivator(LogicalKeyboardKey.numpadEnter):
                      _activate,
                }
              : const {},
          child: Focus(
            focusNode: widget.focusNode,
            canRequestFocus: _enabled && !widget.loading,
            onFocusChange: (focused) {
              final next = focused && keyboardHighlight();
              if (next != _ringVisible) setState(() => _ringVisible = next);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _enabled && !widget.loading
                  ? (_) => _setPressed(true)
                  : null,
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              onTap: _enabled ? _activate : null,
              excludeFromSemantics: true,
              child: MouseRegion(
                cursor: !_enabled
                    ? SystemMouseCursors.forbidden
                    : widget.loading
                    ? SystemMouseCursors.progress
                    : SystemMouseCursors.click,
                child: PFocusRing(
                  visible: _ringVisible && _enabled && !widget.loading,
                  style: PFocusRingStyle(radius: s.radius),
                  child: pressedBox,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
