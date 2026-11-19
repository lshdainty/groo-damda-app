import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 변형 — weak(옅은 바탕 + 진한 글자, 기본) · solid(채움 + 흰 글자) · outline(테두리 + 의미 색 글자).
enum PBadgeVariant { weak, solid, outline }

/// 톤 — 뜻을 나타낸다. neutral(분류 · 기본) · brand(요금제 · 본인 표시만) · informative · positive · warning · critical.
enum PBadgeTone { neutral, brand, informative, positive, warning, critical }

/// 크기 — medium 20(목록 줄 · 표 · 이름 옆, 기본) · large 24(상세 머리 · 카드 제목 옆).
enum PBadgeSize { medium, large }

/// 변형 · 톤의 색 — 위젯과 테스트가 같은 표를 본다(badge.yaml 의 weak · solid · outline 규칙).
@visibleForTesting
({Color background, Color foreground, Color? border}) resolvePBadgeColors(
  PColors c,
  PBadgeVariant variant,
  PBadgeTone tone,
) {
  const clear = Color(0x00000000);
  return switch ((variant, tone)) {
    (PBadgeVariant.weak, PBadgeTone.neutral) => (
      background: c.bgNeutralWeak,
      foreground: c.fgNeutralMuted,
      border: null,
    ),
    (PBadgeVariant.weak, PBadgeTone.brand) => (
      background: c.bgBrandWeak,
      foreground: c.fgBrandContrast,
      border: null,
    ),
    (PBadgeVariant.weak, PBadgeTone.informative) => (
      background: c.bgInformativeWeak,
      foreground: c.fgInformativeContrast,
      border: null,
    ),
    (PBadgeVariant.weak, PBadgeTone.positive) => (
      background: c.bgPositiveWeak,
      foreground: c.fgPositiveContrast,
      border: null,
    ),
    (PBadgeVariant.weak, PBadgeTone.warning) => (
      background: c.bgWarningWeak,
      foreground: c.fgWarningContrast,
      border: null,
    ),
    (PBadgeVariant.weak, PBadgeTone.critical) => (
      background: c.bgCriticalWeak,
      foreground: c.fgCriticalContrast,
      border: null,
    ),
    (PBadgeVariant.solid, PBadgeTone.neutral) => (
      background: c.bgNeutralInverted,
      foreground: c.fgNeutralInverted,
      border: null,
    ),
    (PBadgeVariant.solid, PBadgeTone.brand) => (
      background: c.bgBrandSolid,
      foreground: c.staticWhite,
      border: null,
    ),
    (PBadgeVariant.solid, PBadgeTone.informative) => (
      background: c.bgInformativeSolid,
      foreground: c.staticWhite,
      border: null,
    ),
    (PBadgeVariant.solid, PBadgeTone.positive) => (
      background: c.bgPositiveSolid,
      foreground: c.staticWhite,
      border: null,
    ),
    (PBadgeVariant.solid, PBadgeTone.warning) => (
      background: c.bgWarningSolid,
      foreground: c.staticWhite,
      border: null,
    ),
    (PBadgeVariant.solid, PBadgeTone.critical) => (
      background: c.bgCriticalSolid,
      foreground: c.staticWhite,
      border: null,
    ),
    (PBadgeVariant.outline, PBadgeTone.neutral) => (
      background: clear,
      foreground: c.fgNeutralMuted,
      border: c.strokeNeutralWeak,
    ),
    (PBadgeVariant.outline, PBadgeTone.brand) => (
      background: clear,
      foreground: c.fgBrand,
      border: c.strokeBrandWeak,
    ),
    (PBadgeVariant.outline, PBadgeTone.informative) => (
      background: clear,
      foreground: c.fgInformative,
      border: c.strokeInformativeWeak,
    ),
    (PBadgeVariant.outline, PBadgeTone.positive) => (
      background: clear,
      foreground: c.fgPositive,
      border: c.strokePositiveWeak,
    ),
    (PBadgeVariant.outline, PBadgeTone.warning) => (
      background: clear,
      foreground: c.fgWarning,
      border: c.strokeWarningWeak,
    ),
    (PBadgeVariant.outline, PBadgeTone.critical) => (
      background: clear,
      foreground: c.fgCritical,
      border: c.strokeCriticalWeak,
    ),
  };
}

/// Badge — 대상의 상태 · 분류를 보이는 작은 라벨. 구조는 SEED Badge(2026-10-03), 수치 원본은 groo-design
/// `specs/components/badge.yaml`(값은 `test/fixtures/design_spec/badge.json`). 웹(desk-front `src/shared/ds/badge`)과
/// 같은 값이다. 옛 위젯(lib/shared/widgets/p_badge.dart)과 이름이 같다 — 자리로 가른다.
///
/// 누르지 않는다(상태가 하나뿐). 고르고 거르는 것은 Chip, 시간 · 개수 같은 메타는 Tag Group, 안 읽은 알림은
/// Notification Badge 다. 글만큼 넓어지고 최대 폭이 없다 — 부모가 좁을 때만 한 줄 말줄임. 글 · 상자는 글자 크기 설정을
/// 따르지 않는다(badge.yaml `$text-t1-static` · `$text-t2-static` — 정해진 디자인 틀, groo-design #260). outline 테두리는 안쪽 1px — 상자 크기가 변하지 않는다.
/// 글은 그대로 읽힌다(앞뒤 글과 이어 읽힌다). 앞 아이콘은 글자색을 따르고 읽지 않는다.
class PBadge extends StatelessWidget {
  const PBadge({
    super.key,
    required this.label,
    this.prefixIcon,
    this.variant = PBadgeVariant.weak,
    this.tone = PBadgeTone.neutral,
    this.size = PBadgeSize.medium,
    this.disabled = false,
  });

  final String label;
  final IconData? prefixIcon;
  final PBadgeVariant variant;
  final PBadgeTone tone;
  final PBadgeSize size;

  /// 끝낸 줄 안의 배지 — 바탕 `bg-disabled` · 글 `fg-disabled`(List 의 비활성과 같은 색, 흐리게 하지 않는다). 변형 · 톤은 무시한다
  /// (웹 할 일 줄이 `bg-bg-disabled text-fg-disabled` 로 덮는 것과 같다).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = disabled
        ? (
            background: context.colors.bgDisabled,
            foreground: context.colors.fgDisabled,
            border: null,
          )
        : resolvePBadgeColors(context.colors, variant, tone);
    final large = size == PBadgeSize.large;
    final radius = BorderRadius.circular(large ? PRounded.r1_5 : PRounded.r1);
    final weight = variant == PBadgeVariant.weak
        ? FontWeight.w500
        : FontWeight.w700;

    return Container(
      constraints: BoxConstraints(minHeight: large ? 24 : 20),
      padding: EdgeInsets.symmetric(
        horizontal: large ? PSpacing.x2 : PSpacing.x1_5,
        vertical: large ? PSpacing.x1 : PSpacing.x0_5,
      ),
      decoration: BoxDecoration(color: colors.background, borderRadius: radius),
      // 안쪽 1px — 위에 그려 상자 · 여백을 바꾸지 않는다(웹의 inset box-shadow)
      foregroundDecoration: colors.border == null
          ? null
          : BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: colors.border!, width: 1),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: PSpacing.x0_5,
        children: [
          if (prefixIcon != null)
            ExcludeSemantics(
              child: Icon(
                prefixIcon,
                size: large ? 14 : 12,
                color: colors.foreground,
              ),
            ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: (large ? PTypography.t2 : PTypography.t1).copyWith(
                color: colors.foreground,
                fontWeight: weight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 배지 여럿 — 한 대상에 둘까지, 사이 4. 넘치면 줄바꿈하지 않고 배지가 각자 말줄임한다.
class PBadgeGroup extends StatelessWidget {
  const PBadgeGroup({super.key, required this.children});

  final List<PBadge> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: PSpacing.x1,
      children: [for (final badge in children) Flexible(child: badge)],
    );
  }
}
