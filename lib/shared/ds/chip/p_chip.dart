import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';

/// 변형 — solid(옅은 회색 채움 — 제안 · 필터 바, 흰 표면 위에서만) · outlineStrong(고르면 짙은 채움) · outlineWeak(기본 —
/// 고르면 옅은 바탕 + 짙은 1px, 글자 그대로).
enum PChipVariant { solid, outlineStrong, outlineWeak }

/// 크기 — small 32 · medium 36(기본) · large 40.
enum PChipSize { small, medium, large }

/// 묶음 배치 — wrap(폼 · 시트 안 — 줄바꿈) · scroll(목록 위 필터 바 · 제안 줄 — 한 줄 가로 스크롤).
enum PChipGroupLayout { wrap, scroll }

/// 크기마다의 값(chip.yaml 의 크기 규칙) — 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
@immutable
class PChipMetrics {
  const PChipMetrics._({
    required this.height,
    required this.paddingX,
    required this.minWidth,
    required this.prefixIcon,
    required this.suffixIcon,
    required this.removeIcon,
    required this.icon,
  });

  final double height;
  final double paddingX;
  final double minWidth;
  final double prefixIcon;
  final double suffixIcon;
  final double removeIcon;
  final double icon;

  static const small = PChipMetrics._(
    height: 32,
    paddingX: PSpacing.x3,
    minWidth: 44,
    prefixIcon: 14,
    suffixIcon: 14,
    removeIcon: 14,
    icon: 14,
  );
  static const medium = PChipMetrics._(
    height: 36,
    paddingX: PSpacing.x3_5,
    minWidth: 48,
    prefixIcon: 16,
    suffixIcon: 14,
    removeIcon: 14,
    icon: 16,
  );
  static const large = PChipMetrics._(
    height: 40,
    paddingX: PSpacing.x4,
    minWidth: 52,
    prefixIcon: 16,
    suffixIcon: 16,
    removeIcon: 16,
    icon: 16,
  );

  static PChipMetrics of(PChipSize size) => switch (size) {
    PChipSize.small => small,
    PChipSize.medium => medium,
    PChipSize.large => large,
  };
}

/// 칩의 세 색 — 변형 · 고름 · 상태에서 정해진다(chip.yaml 의 변형 × 고름 규칙). 테두리는 안쪽 1px 를 늘 그려 두고
/// 없을 때는 투명이다(칩 크기가 변하지 않는다). 앱 상태는 enabled · pressed · disabled(웹의 hovered 는 누름과 같고
/// focused 는 링이다 — 둘 다 앱에는 없다).
@visibleForTesting
SelectionColors chipColors(
  PColors c,
  PChipVariant variant, {
  required bool selected,
  required bool enabled,
  required bool pressed,
}) {
  const clear = Color(0x00000000);
  if (!enabled) {
    // 비활성 — 전용 색(흐리게 하지 않는다). 고른 채 막히면 짙은 1px 를 남겨 무엇을 골랐는지 보인다
    final outline = variant != PChipVariant.solid;
    return (
      // solid 안 고른 칩은 막혀도 바탕이 그대로다(bg-neutral-weak-alpha — 회색 바닥 위에서도 보이게, 03-B 결정 1 A).
      // 글 · 아이콘만 fg-disabled 로 바뀐다
      background: variant == PChipVariant.solid && !selected
          ? c.bgNeutralWeakAlpha
          : c.bgDisabled,
      border: selected
          ? c.strokeNeutralSolid
          : (outline ? c.strokeNeutralWeak : clear),
      foreground: c.fgDisabled,
    );
  }
  switch (variant) {
    case PChipVariant.solid:
      return selected
          ? (
              background: pressed
                  ? c.bgNeutralInvertedPressed
                  : c.bgNeutralInverted,
              border: clear,
              foreground: c.fgNeutralInverted,
            )
          : (
              // 회색 바닥 위에서도 보이는 반투명 채움(bg-neutral-weak-alpha, v120)
              background: pressed
                  ? c.bgNeutralWeakAlphaPressed
                  : c.bgNeutralWeakAlpha,
              border: clear,
              foreground: c.fgNeutral,
            );
    case PChipVariant.outlineStrong:
      return selected
          ? (
              // 짙은 채움 위 테두리는 지운다(SEED Chip Tabs 와 같다)
              background: pressed
                  ? c.bgNeutralInvertedPressed
                  : c.bgNeutralInverted,
              border: clear,
              foreground: c.fgNeutralInverted,
            )
          : (
              background: pressed ? c.bgLayerDefaultPressed : clear,
              border: c.strokeNeutralWeak,
              foreground: c.fgNeutral,
            );
    case PChipVariant.outlineWeak:
      return selected
          ? (
              background: pressed ? c.bgNeutralWeakPressed : c.bgNeutralWeak,
              border: c.strokeNeutralContrast,
              foreground: c.fgNeutral,
            )
          : (
              background: pressed ? c.bgLayerDefaultPressed : clear,
              border: c.strokeNeutralWeak,
              foreground: c.fgNeutral,
            );
  }
}

Widget _icon(IconData data, double size, Color color) => ExcludeSemantics(
  child: SizedBox.square(
    dimension: size,
    child: Icon(data, size: size, color: color),
  ),
);

/// 칩 글 한 줄의 높이(t4 14 / 19) — 위아래 여백 (높이 − 19) ÷ 2 의 19.
@visibleForTesting
const double kChipLineHeight = 19;

/// 가로 스크롤 줄 · Chip Tabs 가 칩에 알려 주는 최대 폭 — 보이는 줄 폭(화면 여백 안). 줄바꿈 묶음 · 그 밖에서는 놓인
/// 줄 폭이 곧 부모 제약이라 필요 없다(03-E 결정 2 A + 후속).
class ChipLineLimit extends InheritedWidget {
  const ChipLineLimit({
    super.key,
    required this.maxWidth,
    required super.child,
  });

  final double maxWidth;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChipLineLimit>()?.maxWidth;

  @override
  bool updateShouldNotify(ChipLineLimit oldWidget) =>
      maxWidth != oldWidget.maxWidth;
}

double _chipMaxWidth(BuildContext context) =>
    ChipLineLimit.maybeOf(context) ?? double.infinity;

/// 칩의 모습 — 알약 · 앞 아이콘 · 글 · 뒤 아이콘(· 탭의 알림 점). 색은 150ms 로 바뀌고, 누르면 칩 전체가 2px 거리
/// 준다. 누르기 · 읽기는 이 위에서 [PressArea] 가 맡는다. Chip · Chip Tabs 가 함께 쓴다.
class ChipVisual extends StatelessWidget {
  const ChipVisual({
    super.key,
    required this.variant,
    required this.size,
    required this.selected,
    required this.enabled,
    required this.pressed,
    required this.pressSize,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.icon,
    this.afterLabel,
    this.leading,
    this.count,
  }) : assert(
         (label == null) != (icon == null),
         '글이 있는 칩은 label, 아이콘만 있는 칩은 icon 하나만 준다',
       );

  final PChipVariant variant;
  final PChipSize size;
  final bool selected;
  final bool enabled;
  final bool pressed;
  final Size pressSize;
  final String? label;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  /// 아이콘만 있는 칩의 아이콘 — 원이다.
  final IconData? icon;

  /// 글 뒤에 6 을 두고 놓는 것 — Chip Tabs 의 알림 점.
  final Widget? afterLabel;

  /// 글 앞에 6 을 두고 놓는 것 — 아이콘 대신 색 점처럼 화면이 그린 표식(앞 아이콘과 같이 쓰지 않는다).
  final Widget? leading;

  /// 글 뒤 건수 — 같은 칩 안에서 글과 10(웹 칩 묶음 gap 6 + 건수 margin 4)을 두고 `fg-neutral-subtle` 로 놓는다(고른 칩에서는 칩의 글색 그대로). 메모 태그 필터 칩(I-15 8).
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = PChipMetrics.of(size);
    final look = chipColors(
      c,
      variant,
      selected: selected,
      enabled: enabled,
      pressed: pressed,
    );
    final iconOnly = icon != null;
    return TweenAnimationBuilder<SelectionColors>(
      tween: SelectionColorsTween(end: look),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, colors, _) {
        final fg = colors.foreground;
        return PressScale(
          pressed: pressed,
          size: pressSize,
          child: ConstrainedBox(
            constraints: iconOnly
                ? BoxConstraints.tightFor(width: m.height, height: m.height)
                : BoxConstraints(
                    minWidth: m.minWidth,
                    // 높이는 최소 높이다 — 글자를 키우면 글을 따라 늘어난다(03-E 결정 1 C)
                    minHeight: m.height,
                    maxWidth: _chipMaxWidth(context),
                  ),
            child: DecoratedBox(
              key: const ValueKey('chip-box'),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(PRounded.full),
                // 안쪽 1px — 칩 크기가 변하지 않는다(웹 inset box-shadow)
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: iconOnly ? 0 : m.paddingX,
                  // (높이 − 글 줄 19) ÷ 2 — 100% 에서 높이 그대로, 글자가 커지면 글을 따라 늘어난다
                  vertical: iconOnly ? 0 : (m.height - kChipLineHeight) / 2,
                ),
                child: Center(
                  widthFactor: iconOnly ? null : 1,
                  heightFactor: iconOnly ? null : 1,
                  child: iconOnly
                      ? _icon(icon!, m.icon, fg)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: PSpacing.x1_5,
                          children: [
                            ?leading,
                            if (prefixIcon != null)
                              _icon(prefixIcon!, m.prefixIcon, fg),
                            // 줄바꿈하지 않는다 — 글만큼 넓어지다가 줄 폭에 닿으면 글 끝만 말줄임한다(아이콘은 남는다)
                            Flexible(
                              child: ExcludeSemantics(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: label),
                                      if (count != null) ...[
                                        const WidgetSpan(
                                          child: SizedBox(
                                            width: PSpacing.x1_5 + PSpacing.x1,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$count',
                                          style: TextStyle(
                                            color: selected
                                                ? fg
                                                : c.fgNeutralSubtle,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: PTypography.t4.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: fg,
                                  ),
                                ),
                              ),
                            ),
                            if (suffixIcon != null)
                              _icon(suffixIcon!, m.suffixIcon, fg),
                            ?afterLabel,
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chip(버튼) — 제안(누르면 칸에 값을 넣는다 · 고른 모습 없음) · 필터 바의 여는 칩(뒤 아래 화살표, 걸린 조건이면
/// [selected]) · 아이콘만 있는 필터 지우기([PChip.icon]). 구조는 SEED Chip(2026-10-02), 수치 원본은 groo-design
/// `specs/components/chip.yaml`(값은 `test/fixtures/design_spec/chip.json` — 테스트가 위젯이 그 값과 같은지 본다).
/// 웹(desk-front `src/shared/ds/chip`)과 같은 값이다.
///
/// 모양 — 알약(모서리 full). 높이 32 · 36 · 40, 글은 세 크기 모두 t4 14 · 500, 가장자리 ↔ 글 12 · 14 · 16, 아이콘 ↔
/// 글 6, 앞 아이콘 14 · 16 · 16 · 뒤 아이콘 14 · 14 · 16. 글은 한 줄이고 줄바꿈 없이 글만큼 넓어지다가 줄 폭에 닿으면 글 끝만 말줄임한다(최소 폭
/// 44 · 48 · 52). 고른 칩은 브랜드가 아니라 중립색이다([PChipVariant] 가 고름의 모습을 정한다). 테두리는 안쪽 1px 라
/// 크기가 변하지 않는다.
///
/// 상태(색은 150ms) — 누르면 누름 바탕 + 칩 전체가 2px 거리 준다(기준 max(높이, 폭 ÷ 4, 24) — 모션 줄이기면 줄지
/// 않는다). 비활성은 전용 색(흐리게 하지 않는다)이고 고른 채 막히면 짙은 1px 를 남긴다. 올림(hovered) · 포커스 링
/// (focused)은 웹 상태라 앱에는 없다 — 키보드 포커스는 받고 링은 그리지 않는다. 누르는 영역은 보이는 칩과 따로 44 까지
/// 넓힌다(놓인 자리는 그대로).
///
/// [onPressed] 가 없으면 비활성이다. 읽기 — 버튼이다(웹 aria-pressed 는 쓰지 않는다 — [selected] 는 모습일 뿐). 여는
/// 칩이 무엇을 여는지는 [semanticLabel] 이나 글이 말한다(웹 aria-haspopup 에 맞는 Flutter 속성이 없다).
class PChip extends StatelessWidget {
  const PChip({
    super.key,
    required String this.label,
    required this.onPressed,
    this.variant = PChipVariant.outlineWeak,
    this.size = PChipSize.medium,
    this.selected = false,
    this.prefixIcon,
    this.suffixIcon,
    this.semanticLabel,
    this.leading,
  }) : icon = null;

  /// 아이콘만 있는 칩 — 원, 이름([semanticLabel])이 반드시 있다("필터 지우기").
  const PChip.icon({
    super.key,
    required IconData this.icon,
    required String this.semanticLabel,
    required this.onPressed,
    this.variant = PChipVariant.outlineWeak,
    this.size = PChipSize.medium,
    this.selected = false,
  }) : label = null,
       prefixIcon = null,
       suffixIcon = null,
       leading = null;

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PChipVariant variant;
  final PChipSize size;

  /// 고른 모습(짙은 채움) — 필터 바의 걸린 조건. 모습만 바꾼다(읽는 상태는 없다). 제안 칩에는 쓰지 않는다.
  final bool selected;

  /// 앞 아이콘 — 묶음 안에서 모두 두거나 모두 뺀다.
  final IconData? prefixIcon;

  /// 뒤 아이콘 — 여는 칩의 아래 화살표([LucideIcons.chevronDown]).
  final IconData? suffixIcon;

  /// 앞 표식 위젯 — 캘린더 색 점처럼 아이콘이 아닌 것. 앞 아이콘과 같이 쓰지 않는다. 읽는 이름은 [semanticLabel] 이 말한다.
  final Widget? leading;

  /// 읽는 이름 — 글이 없는 칩은 필수, 글이 있으면 글 대신 읽는다.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return PressArea(
      enabled: enabled,
      onTap: onPressed,
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: semanticLabel ?? label,
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
        label: label,
        icon: icon,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        leading: leading,
      ),
    );
  }
}

/// 여럿 고르기 칩 — 체크박스다. 다시 누르면 풀린다(일부 고름은 없다 — 칩은 고름 · 안 고름 둘뿐). 칩마다 Tab 이 선다.
/// 모양 · 상태는 [PChip] 과 같다. [onChanged] 가 없으면 비활성. 읽기 — 체크박스(checked). Space 로 누른다(Enter 는
/// 폼 제출에 둔다).
class PChipToggle extends StatelessWidget {
  const PChipToggle({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.variant = PChipVariant.outlineWeak,
    this.size = PChipSize.medium,
    this.prefixIcon,
  });

  final String label;
  final bool checked;

  /// 눌러 바뀐 값 — 없으면 비활성.
  final ValueChanged<bool>? onChanged;
  final PChipVariant variant;
  final PChipSize size;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return PressArea(
      enabled: enabled,
      activateOnEnter: false,
      onTap: enabled ? () => onChanged!(!checked) : null,
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        enabled: enabled,
        checked: checked,
        label: label,
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, pressSize) => ChipVisual(
        variant: variant,
        size: size,
        selected: checked,
        enabled: enabled,
        pressed: pressed,
        pressSize: pressSize,
        label: label,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

/// 입력값 칩 — 넣은 값(Outline Weak 의 고른 모습) + 뒤 지우기 버튼. 칩 자체는 누르지 않는다(호버 · 누름 없음) — 지우기가
/// 칩 안에서 따로 눌린다. 지우기는 아이콘 14 · 14 · 16(글자색 그대로), 누르는 영역 24 × 24, 눌리면 지우기만 2px 거리
/// 준다(기준 24). 비활성은 회색 바탕 + 짙은 1px. [onRemove] 가 없으면 비활성이다.
///
/// 읽기 — 글 + [removeLabel] 버튼("김하나 지우기"). 이름은 쓰는 쪽이 넘긴다(문자열은 호출하는 쪽 몫).
/// 웹은 지운 뒤 포커스를 다음 칩의 지우기로 옮기지만 앱은 옮기지 않는다 — Flutter 가 빠진 자리의 포커스를 거둔다.
class PInputChip extends StatelessWidget {
  const PInputChip({
    super.key,
    required this.label,
    required this.removeLabel,
    required this.onRemove,
    this.size = PChipSize.medium,
    this.prefixIcon,
  });

  final String label;

  /// 지우기 버튼의 이름 — "{글} 지우기".
  final String removeLabel;

  /// 이 값을 뺀다. 없으면 비활성.
  final VoidCallback? onRemove;
  final PChipSize size;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = PChipMetrics.of(size);
    final enabled = onRemove != null;
    final fg = enabled ? c.fgNeutral : c.fgDisabled;
    final bg = enabled ? c.bgNeutralWeak : c.bgDisabled;
    final border = enabled ? c.strokeNeutralContrast : c.strokeNeutralSolid;
    return TweenAnimationBuilder<SelectionColors>(
      tween: SelectionColorsTween(
        end: (background: bg, border: border, foreground: fg),
      ),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, colors, _) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: m.minWidth,
          minHeight: m.height,
          maxWidth: _chipMaxWidth(context),
        ),
        child: DecoratedBox(
          key: const ValueKey('input-chip-box'),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(PRounded.full),
            border: Border.all(color: colors.border),
          ),
          // 좌우 여백도 Row 안에 둔다 — 지우기의 누르는 영역(24 × 24)이 칩 가장자리 쪽으로 넓어져도 Row 안이라 받는다
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: m.paddingX),
              if (prefixIcon != null) ...[
                _icon(prefixIcon!, m.prefixIcon, colors.foreground),
                const SizedBox(width: PSpacing.x1_5),
              ],
              // 글 끝만 말줄임한다 — 지우기 ×는 줄지 않고 남는다
              // 위아래 여백은 글에 둔다 — 줄이 칩 높이 전체라 지우기의 누르는 영역이 칩 높이만큼 받는다
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: (m.height - kChipLineHeight) / 2,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: PTypography.t4.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PSpacing.x1_5),
              _RemoveButton(
                size: m.removeIcon,
                color: colors.foreground,
                label: removeLabel,
                onRemove: onRemove,
              ),
              SizedBox(width: m.paddingX),
            ],
          ),
        ),
      ),
    );
  }
}

/// 지우기 — 보이는 아이콘만큼 차지하고 누르는 영역은 24 × 24. 누르면 자기만 2px 거리 준다(기준 24).
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    required this.size,
    required this.color,
    required this.label,
    required this.onRemove,
  });

  final double size;
  final Color color;
  final String label;
  final VoidCallback? onRemove;

  /// 누르는 영역 — 24 × 24(AAA 44 밖이다 — 스펙이 정한 값).
  static const double touch = 24;

  @override
  Widget build(BuildContext context) {
    return PressArea(
      enabled: onRemove != null,
      onTap: onRemove,
      touchMin: touch,
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: label,
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, _) => PressScale(
        pressed: pressed,
        // 기준 24 — 칩이 아니라 지우기의 크기다
        size: const Size.square(touch),
        child: SizedBox.square(
          key: const ValueKey('input-chip-remove'),
          dimension: size,
          child: Icon(LucideIcons.x, size: size, color: color),
        ),
      ),
    );
  }
}

/// 묶음 — 칩 사이 8(`spacing-between-chips`). 폼 · 시트 안의 고르기 묶음은 줄바꿈하고(줄 사이 8), 목록 위 필터 바 · 제안
/// 줄은 한 줄 가로 스크롤이다. 비었을 때는 칩 한 줄(36) 높이를 남긴다. 읽기 — 묶음이고 [semanticLabel] 이 이름이다
/// (Field 안이면 Field 의 라벨이 이름이 되도록 쓰는 쪽이 같은 글을 준다).
///
/// scroll 은 목록 위 줄이다 — **화면 끝까지** 낸다(화면 여백 안에 두지 않는다). 줄 안쪽 좌우 여백이 화면 여백 24 라
/// 스크롤해도 첫 칩이 여백에서 시작하고, 양 끝 20 은 늘 흐린다(Scroll Fog row — 처음 · 끝의 칩은 여백이 더 넓어 흐리지
/// 않는다). 위아래 안쪽 6 은 줄 높이를 늘리지 않고(칩 그대로) 누르는 영역 · 칸 가장자리가 잘리지 않게 하는 자리다.
/// 웹의 bleed(부모 여백 밖으로 내기)는 없다 — Flutter 는 부모 밖에서 누르는 것을 받지 못해 처음부터 화면 끝까지 낸다.
class PChipGroup extends StatelessWidget {
  const PChipGroup({
    super.key,
    required this.children,
    this.layout = PChipGroupLayout.wrap,
    this.semanticLabel,
  });

  final List<Widget> children;
  final PChipGroupLayout layout;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ChipLayout(
      layout: layout,
      semantics: (child) => Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: child,
      ),
      children: children,
    );
  }
}

/// 칩들을 배치한다 — [PChipGroup] · [PChipRadioGroup] 이 함께 쓴다.
///
/// [semantics] 는 배치를 감싸는 읽는 말이다 — 스크롤 줄에서는 위아래 6 을 되돌리는 상자(누르는 영역이 그 바깥으로
/// 넘쳐 받는다)가 가장 바깥이어야 하므로, 읽는 말은 그 안쪽에 둔다.
class ChipLayout extends StatelessWidget {
  const ChipLayout({
    super.key,
    required this.layout,
    required this.children,
    this.semantics,
  });

  final PChipGroupLayout layout;
  final List<Widget> children;
  final Widget Function(Widget child)? semantics;

  /// 묶음 비었을 때의 높이 — 칩 한 줄(medium).
  static const double emptyHeight = 36;

  /// 스크롤 줄의 위아래 안쪽 여백 — 줄 높이는 칩 그대로(바깥 −6 으로 되돌린다).
  static const double scrollPaddingY = PSpacing.x1_5;

  @override
  Widget build(BuildContext context) {
    Widget wrapSemantics(Widget child) => semantics?.call(child) ?? child;
    if (children.isEmpty) {
      return wrapSemantics(
        const SizedBox(width: double.infinity, height: emptyHeight),
      );
    }
    switch (layout) {
      case PChipGroupLayout.wrap:
        return wrapSemantics(
          Wrap(
            spacing: PSpacing.betweenChips,
            runSpacing: PSpacing.betweenChips,
            children: children,
          ),
        );
      case PChipGroupLayout.scroll:
        return _NetZeroPadding(
          vertical: scrollPaddingY,
          child: wrapSemantics(
            PScrollFogMask(
              axis: Axis.horizontal,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: LayoutBuilder(
                  // 보이는 줄 폭(화면 여백 안)이 칩의 최대 폭이다
                  builder: (context, box) => ChipLineLimit(
                    maxWidth: box.maxWidth - 2 * PSpacing.globalGutter,
                    child: SingleChildScrollView(
                      key: const ValueKey('chip-scroll-row'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: PSpacing.globalGutter,
                      ),
                      // 위아래 안쪽 6 은 칩마다 둔다 — 칩의 누르는 영역 44 가 칩 둘레의 이 여백 안에서 받는다(부모 상자 밖은 받지
                      // 못하므로 줄 전체에 여백을 두면 칩 바깥 6 은 받지 못한다)
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: PSpacing.betweenChips,
                        children: [
                          for (final child in children)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: scrollPaddingY,
                              ),
                              child: child,
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
}

/// 안쪽 위아래 [vertical] 을 바깥에서 되돌린다(웹 안쪽 py-6 · 바깥 -my-6) — 줄 높이는 칩 그대로이고 부모의 위아래
/// 간격이 지워지지 않는다. 넘친 자리도 누른다(칸이 칩의 누르는 영역 44 를 자르지 않는다).
class _NetZeroPadding extends SingleChildRenderObjectWidget {
  const _NetZeroPadding({required this.vertical, required super.child});

  final double vertical;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNetZeroPadding(vertical);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderNetZeroPadding renderObject,
  ) {
    renderObject.vertical = vertical;
  }
}

class _RenderNetZeroPadding extends RenderShiftedBox {
  _RenderNetZeroPadding(this._vertical) : super(null);

  double _vertical;
  set vertical(double value) {
    if (value == _vertical) return;
    _vertical = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(child.size.width, child.size.height - 2 * _vertical),
    );
    (child.parentData! as BoxParentData).offset = Offset(0, -_vertical);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final area = Rect.fromLTRB(
      0,
      -_vertical,
      size.width,
      size.height + _vertical,
    );
    if (!area.contains(position)) return false;
    return hitTestChildren(result, position: position) || hitTestSelf(position);
  }
}

/// 하나 고르기 묶음 — 라디오 묶음이다. ← → ↑ ↓ 로 옮기면 바로 고르고(막힌 칩은 건너뛰고 끝에서 처음으로 돈다), Tab 은
/// 고른 칩 하나에만 선다. 고른 칩을 다시 눌러도 풀리지 않는다 — 늘 하나가 골라져 있다(거르기의 "전체" 는 맨 앞 선택지).
/// Flutter 의 RadioGroup 이 맡는다(웹 Radix 와 같은 APG 동작). 읽기 — 라디오 묶음이고 [semanticLabel] 이 이름이다.
/// Field 안이면 Field 의 막힘 · 오류 · 필수를 받는다(직접 준 값이 이긴다).
class PChipRadioGroup<T> extends StatelessWidget {
  const PChipRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.layout = PChipGroupLayout.wrap,
    this.semanticLabel,
    this.disabled,
    this.invalid,
    this.required,
  });

  /// 고른 값.
  final T? value;

  /// 다른 칩을 고르면 그 값. 없으면 묶음 전체가 비활성.
  final ValueChanged<T>? onChanged;

  /// [PChipRadio] 들(같은 값 타입).
  final List<Widget> children;
  final PChipGroupLayout layout;
  final String? semanticLabel;
  final bool? disabled;
  final bool? invalid;
  final bool? required;

  @override
  Widget build(BuildContext context) {
    final field = PFieldScope.maybeOf(context)?.data;
    final off = disabled ?? field?.disabled ?? false;
    final bad = invalid ?? field?.invalid ?? false;
    final need = required ?? field?.required ?? false;
    final onChanged = off ? null : this.onChanged;
    return _ChipRadioScope(
      enabled: onChanged != null,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (next) {
          if (onChanged == null || next == null || next == value) return;
          onChanged(next);
        },
        child: ChipLayout(
          layout: layout,
          semantics: (child) => Semantics(
            label: semanticLabel,
            isRequired: need ? true : null,
            validationResult: bad
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: child,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _ChipRadioScope extends InheritedWidget {
  const _ChipRadioScope({required this.enabled, required super.child});

  final bool enabled;

  static bool enabledOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ChipRadioScope>()?.enabled ??
      true;

  @override
  bool updateShouldNotify(_ChipRadioScope oldWidget) =>
      enabled != oldWidget.enabled;
}

/// 하나 고르기 칩 — [PChipRadioGroup] 안에서만 쓴다(같은 값 타입). 모양 · 상태는 [PChip] 과 같다. 고른 칩은
/// 묶음의 값과 같은 칩이다. [enabled] 가 false 면 이 칩만 막힌다.
class PChipRadio<T> extends StatefulWidget {
  const PChipRadio({
    super.key,
    required this.value,
    required this.label,
    this.variant = PChipVariant.outlineWeak,
    this.size = PChipSize.medium,
    this.prefixIcon,
    this.enabled = true,
    this.count,
  });

  final T value;
  final String label;

  /// 글 뒤 건수 — 읽을 때는 "{글} {건수}" 로 읽는다.
  final int? count;
  final PChipVariant variant;
  final PChipSize size;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  State<PChipRadio<T>> createState() => _PChipRadioState<T>();
}

class _PChipRadioState<T> extends State<PChipRadio<T>> with RadioClient<T> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'PChipRadio');
  bool _groupEnabled = true;

  @override
  FocusNode get focusNode => _focusNode;

  @override
  T get radioValue => widget.value;

  @override
  bool get tristate => false;

  // 화살표가 건너뛸 칩 — 이 칩 또는 묶음이 막혔다
  @override
  bool get enabled => widget.enabled && _groupEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registry = RadioGroup.maybeOf<T>(context);
    _groupEnabled = _ChipRadioScope.enabledOf(context);
  }

  /// 지난 그림에서 고른 칩이었나 — null 이면 아직 그린 적 없다.
  bool? _wasSelected;

  /// 가로 스크롤 줄 안의 칩이 화면 여백(24) 안에 들어오게 줄을 옮긴다 — 가로 스크롤이 아니면(wrap) 하지 않는다.
  void _reveal() {
    if (!mounted) return;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      return;
    }
    final dir = scrollable.axisDirection;
    if (dir != AxisDirection.right && dir != AxisDirection.left) {
      return;
    }
    final box = context.findRenderObject();
    final viewport = scrollable.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox) return;
    final left = box.localToGlobal(Offset.zero, ancestor: viewport).dx;
    final right = left + box.size.width;
    const edge = PSpacing.globalGutter;
    var delta = 0.0;
    if (right > viewport.size.width - edge) {
      delta = right - (viewport.size.width - edge);
    }
    if (left - delta < edge) delta = left - edge;
    if (delta == 0) return;
    final position = scrollable.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      position.jumpTo(target);
    } else {
      position.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: PEasing.easing,
      );
    }
  }

  @override
  void dispose() {
    registry = null;
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      registry != null,
      'PChipRadio 는 같은 값 타입(T)의 PChipRadioGroup 안에서만 쓴다 — T: $T',
    );
    final selected = registry?.groupValue == widget.value;
    // 고르는 순간 가로 스크롤 줄 안이면 고른 칩이 보이게 옮긴다(웹: 고른 칩이 줄 안으로 스크롤된다). 처음 그릴 때는 옮기지 않는다
    if (selected && _wasSelected == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
    _wasSelected = selected;
    final enabled = this.enabled;
    // iOS 의 VoiceOver 는 선택을 selected 로 읽는다 — 고르지 않은 칩은 "선택되지 않음" 을 덧붙인다(PRadio 와 같다)
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    return PressArea(
      enabled: enabled,
      focusNode: _focusNode,
      // 화살표는 라디오 묶음이 맡는다(옮기면 바로 고른다). Space 로 포커스된 칩을 고르고 Enter 는 고르지 않는다
      activateOnEnter: false,
      onTap: () {
        // 이미 고른 칩을 다시 눌러도 그대로다
        if (selected) return;
        registry?.onChanged(widget.value);
      },
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        enabled: enabled,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        selected: apple ? selected : null,
        hint: apple && !selected
            ? WidgetsLocalizations.of(context).radioButtonUnselectedLabel
            : null,
        label: widget.count == null
            ? widget.label
            : '${widget.label} ${widget.count}',
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, pressSize) => ChipVisual(
        variant: widget.variant,
        size: widget.size,
        selected: selected,
        enabled: enabled,
        pressed: pressed,
        pressSize: pressSize,
        label: widget.label,
        count: widget.count,
        prefixIcon: widget.prefixIcon,
      ),
    );
  }
}
