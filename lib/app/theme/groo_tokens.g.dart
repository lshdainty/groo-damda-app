// GENERATED — groo-design scripts/build-dart-tokens.mjs 가 DESIGN.desk.md 에서 만든다. 손으로 고치지 않는다.
// 바꾸려면 groo-design 의 DESIGN.desk.md 를 고치고 다시 만든다.
// source: DESIGN.desk.md · sha256 ce410e4e7025
//
// 새 이름(SEED 구조)만 담는다 — 옛 이름(primary · text-secondary · xs ~ 3xl · shadow-sm …)은 새 이름의 별칭이라 뺐다.
// 글자는 웹(CSS)처럼 줄 높이의 남는 간격을 위아래에 똑같이 나눈다(leadingDistribution: even) — 스펙의 줄 높이가 CSS 값이다.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// 원본 — 제품이 이 파일이 어느 DESIGN 에서 왔는지 볼 수 있게.
abstract final class PDesignSource {
  static const String file = 'DESIGN.desk.md';
  static const String sha256 = 'ce410e4e7025';
}

/// 간격(px) — SEED 눈금 x0_5 ~ x16 + 역할 간격(DESIGN.md v98 · v101). 옛 xs ~ 3xl 은 뺐다.
abstract final class PSpacing {
  /// spacing-x0_5
  static const double x0_5 = 2;

  /// spacing-x1
  static const double x1 = 4;

  /// spacing-x1_5
  static const double x1_5 = 6;

  /// spacing-x2
  static const double x2 = 8;

  /// spacing-x2_5
  static const double x2_5 = 10;

  /// spacing-x3
  static const double x3 = 12;

  /// spacing-x3_5
  static const double x3_5 = 14;

  /// spacing-x4
  static const double x4 = 16;

  /// spacing-x4_5
  static const double x4_5 = 18;

  /// spacing-x5
  static const double x5 = 20;

  /// spacing-x6
  static const double x6 = 24;

  /// spacing-x7
  static const double x7 = 28;

  /// spacing-x8
  static const double x8 = 32;

  /// spacing-x9
  static const double x9 = 36;

  /// spacing-x10
  static const double x10 = 40;

  /// spacing-x12
  static const double x12 = 48;

  /// spacing-x13
  static const double x13 = 52;

  /// spacing-x14
  static const double x14 = 56;

  /// spacing-x16
  static const double x16 = 64;

  /// spacing-global-gutter
  static const double globalGutter = 24;

  /// spacing-between-chips
  static const double betweenChips = 8;

  /// spacing-component-default
  static const double componentDefault = 12;

  /// spacing-between-text
  static const double betweenText = 6;

  /// spacing-nav-to-title
  static const double navToTitle = 20;

  /// spacing-screen-bottom
  static const double screenBottom = 56;
}

/// 모서리(px) — SEED 눈금 r0_5 ~ r6 + full(DESIGN.md v99). 옛 xs ~ 2xl 은 뺐다.
abstract final class PRounded {
  /// radius-r0_5
  static const double r0_5 = 2;

  /// radius-r1
  static const double r1 = 4;

  /// radius-r1_5
  static const double r1_5 = 6;

  /// radius-r2
  static const double r2 = 8;

  /// radius-r2_5
  static const double r2_5 = 10;

  /// radius-r3
  static const double r3 = 12;

  /// radius-r3_5
  static const double r3_5 = 14;

  /// radius-r4
  static const double r4 = 16;

  /// radius-r5
  static const double r5 = 20;

  /// radius-r6
  static const double r6 = 24;

  /// radius-full
  static const double full = 9999;
}

/// 글자 — SEED t1 ~ t14 + 역할 스타일(DESIGN.md v100). 옛 15단계(v82)는 뺐다.
/// 굵기를 컴포넌트가 따로 정하면(버튼 700 …) copyWith 로 덮는다. 색은 쓰는 쪽이 정한다.
abstract final class PTypography {
  static const String fontFamily = 'Pretendard';

  /// t1 — 11/15 · 400
  static const TextStyle t1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 15 / 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t2 — 12/16 · 400
  static const TextStyle t2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t3 — 13/18 · 400
  static const TextStyle t3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t4 — 14/19 · 400
  static const TextStyle t4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 19 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t5 — 16/22 · 400
  static const TextStyle t5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t6 — 18/24 · 400
  static const TextStyle t6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t7 — 20/27 · 400
  static const TextStyle t7 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 27 / 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t8 — 22/30 · 400
  static const TextStyle t8 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t9 — 24/32 · 400
  static const TextStyle t9 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t10 — 26/35 · 400
  static const TextStyle t10 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 35 / 26,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t11 — 28/38 · 400
  static const TextStyle t11 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 38 / 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t12 — 32/42 · 400
  static const TextStyle t12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 42 / 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t13 — 40/52 · 400
  static const TextStyle t13 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 52 / 40,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// t14 — 48/60 · 400
  static const TextStyle t14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    height: 60 / 48,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// screen-title — 26/35 · 700
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 35 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// article-body — 16/24 · 400
  static const TextStyle articleBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// article-note — 14/22 · 400
  static const TextStyle articleNote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// 지속 시간 — SEED d1 ~ d6 + 역할(DESIGN.md v104). 옛 fast · base · slow · slower 는 뺐다.
abstract final class PDuration {
  /// motion-duration-d1 — 50ms
  static const Duration d1 = Duration(milliseconds: 50);

  /// motion-duration-d2 — 100ms
  static const Duration d2 = Duration(milliseconds: 100);

  /// motion-duration-d3 — 150ms
  static const Duration d3 = Duration(milliseconds: 150);

  /// motion-duration-d4 — 200ms
  static const Duration d4 = Duration(milliseconds: 200);

  /// motion-duration-d5 — 250ms
  static const Duration d5 = Duration(milliseconds: 250);

  /// motion-duration-d6 — 300ms
  static const Duration d6 = Duration(milliseconds: 300);

  /// motion-duration-color-transition — 150ms
  static const Duration colorTransition = Duration(milliseconds: 150);

  /// motion-duration-pressed-scale — 150ms
  static const Duration pressedScale = Duration(milliseconds: 150);

  /// motion-duration-loop — 1500ms
  static const Duration loop = Duration(milliseconds: 1500);
}

/// 이징 — SEED(DESIGN.md v104). 옛 ease-out 은 뺐다.
abstract final class PEasing {
  /// motion-ease-easing — cubic-bezier(0.35, 0, 0.35, 1)
  static const Curve easing = Cubic(0.35, 0, 0.35, 1);

  /// motion-ease-enter — cubic-bezier(0, 0, 0.15, 1)
  static const Curve enter = Cubic(0, 0, 0.15, 1);

  /// motion-ease-exit — cubic-bezier(0.35, 0, 1, 1)
  static const Curve exit = Cubic(0.35, 0, 1, 1);

  /// motion-ease-enter-expressive — cubic-bezier(0.03, 0.4, 0.1, 1)
  static const Curve enterExpressive = Cubic(0.03, 0.4, 0.1, 1);

  /// motion-ease-exit-expressive — cubic-bezier(0.35, 0, 0.95, 0.55)
  static const Curve exitExpressive = Cubic(0.35, 0, 0.95, 0.55);

  /// motion-ease-pressed-scale — cubic-bezier(0, 0, 0.15, 1)
  static const Curve pressedScale = Cubic(0, 0, 0.15, 1);

  /// motion-ease-linear — linear
  static const Curve linear = Curves.linear;
}

/// 누르는 영역(px) — WCAG 2.5.5(DESIGN.md v59).
abstract final class PTouch {
  /// touch-min
  static const double min = 44;

  /// touch-pill-w
  static const double pillW = 100;

  /// touch-circular
  static const double circular = 44;
}

/// 색 — 역할(fg · bg · stroke) · 팔레트 · 차트 + 딤, 라이트 · 다크(DESIGN.md v102 · v108 · v110 · v111).
/// 화면 · 컴포넌트는 역할 이름만 부른다. 팔레트는 스펙이 단계를 직접 적은 자리와 차트에서만.
/// `context.colors.fgNeutral`
@immutable
class PColors extends ThemeExtension<PColors> {
  const PColors({
    required this.brand100,
    required this.brand200,
    required this.brand300,
    required this.brand400,
    required this.brand500,
    required this.brand600,
    required this.brand700,
    required this.brand800,
    required this.brand900,
    required this.brand1000,
    required this.gray00,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
    required this.gray1000,
    required this.red100,
    required this.red200,
    required this.red300,
    required this.red400,
    required this.red500,
    required this.red600,
    required this.red700,
    required this.red800,
    required this.red900,
    required this.red1000,
    required this.green100,
    required this.green200,
    required this.green300,
    required this.green400,
    required this.green500,
    required this.green600,
    required this.green700,
    required this.green800,
    required this.green900,
    required this.green1000,
    required this.orange100,
    required this.orange200,
    required this.orange300,
    required this.orange400,
    required this.orange500,
    required this.orange600,
    required this.orange700,
    required this.orange800,
    required this.orange900,
    required this.orange1000,
    required this.blue100,
    required this.blue200,
    required this.blue300,
    required this.blue400,
    required this.blue500,
    required this.blue600,
    required this.blue700,
    required this.blue800,
    required this.blue900,
    required this.blue1000,
    required this.yellow100,
    required this.yellow200,
    required this.yellow300,
    required this.yellow400,
    required this.yellow500,
    required this.yellow600,
    required this.yellow700,
    required this.yellow800,
    required this.yellow900,
    required this.yellow1000,
    required this.indigo100,
    required this.indigo200,
    required this.indigo300,
    required this.indigo400,
    required this.indigo500,
    required this.indigo600,
    required this.indigo700,
    required this.indigo800,
    required this.indigo900,
    required this.indigo1000,
    required this.violet100,
    required this.violet200,
    required this.violet300,
    required this.violet400,
    required this.violet500,
    required this.violet600,
    required this.violet700,
    required this.violet800,
    required this.violet900,
    required this.violet1000,
    required this.pink100,
    required this.pink200,
    required this.pink300,
    required this.pink400,
    required this.pink500,
    required this.pink600,
    required this.pink700,
    required this.pink800,
    required this.pink900,
    required this.pink1000,
    required this.brown100,
    required this.brown200,
    required this.brown300,
    required this.brown400,
    required this.brown500,
    required this.brown600,
    required this.brown700,
    required this.brown800,
    required this.brown900,
    required this.brown1000,
    required this.chartRed,
    required this.chartOrange,
    required this.chartYellow,
    required this.chartGreen,
    required this.chartBlue,
    required this.chartIndigo,
    required this.chartViolet,
    required this.chartPink,
    required this.chartBrown,
    required this.chartGray,
    required this.chartRedWeak,
    required this.chartRedSubtle,
    required this.chartRedContrast,
    required this.chartOrangeWeak,
    required this.chartOrangeSubtle,
    required this.chartOrangeContrast,
    required this.chartYellowWeak,
    required this.chartYellowSubtle,
    required this.chartYellowContrast,
    required this.chartGreenWeak,
    required this.chartGreenSubtle,
    required this.chartGreenContrast,
    required this.chartBlueWeak,
    required this.chartBlueSubtle,
    required this.chartBlueContrast,
    required this.chartIndigoWeak,
    required this.chartIndigoSubtle,
    required this.chartIndigoContrast,
    required this.chartVioletWeak,
    required this.chartVioletSubtle,
    required this.chartVioletContrast,
    required this.chartPinkWeak,
    required this.chartPinkSubtle,
    required this.chartPinkContrast,
    required this.chartBrownWeak,
    required this.chartBrownSubtle,
    required this.chartBrownContrast,
    required this.chartGrayWeak,
    required this.chartGraySubtle,
    required this.chartGrayContrast,
    required this.fgBrand,
    required this.fgBrandContrast,
    required this.fgBrandInverted,
    required this.bgBrandSolid,
    required this.bgBrandSolidPressed,
    required this.bgBrandWeak,
    required this.bgBrandWeakPressed,
    required this.strokeFocusRing,
    required this.strokeBrandSolid,
    required this.strokeBrandWeak,
    required this.fgNeutral,
    required this.fgNeutralMuted,
    required this.fgNeutralSubtle,
    required this.fgNeutralInverted,
    required this.fgPlaceholder,
    required this.fgDisabled,
    required this.staticWhite,
    required this.fgCritical,
    required this.fgPositive,
    required this.fgWarning,
    required this.fgInformative,
    required this.fgCriticalContrast,
    required this.fgPositiveContrast,
    required this.fgWarningContrast,
    required this.fgInformativeContrast,
    required this.fgPositiveInverted,
    required this.fgCriticalInverted,
    required this.bgLayerBasement,
    required this.bgLayerDefault,
    required this.bgLayerDefaultPressed,
    required this.bgLayerFloating,
    required this.bgLayerFloatingPressed,
    required this.bgNeutralWeak,
    required this.bgNeutralWeakPressed,
    required this.bgNeutralWeakAlpha,
    required this.bgNeutralWeakAlphaPressed,
    required this.bgNeutralInverted,
    required this.bgNeutralInvertedPressed,
    required this.bgDisabled,
    required this.bgCriticalSolid,
    required this.bgCriticalSolidPressed,
    required this.bgCriticalWeak,
    required this.bgCriticalWeakPressed,
    required this.bgPositiveSolid,
    required this.bgPositiveSolidPressed,
    required this.bgPositiveWeak,
    required this.bgPositiveWeakPressed,
    required this.bgWarningSolid,
    required this.bgWarningSolidPressed,
    required this.bgWarningWeak,
    required this.bgWarningWeakPressed,
    required this.bgInformativeSolid,
    required this.bgInformativeSolidPressed,
    required this.bgInformativeWeak,
    required this.bgInformativeWeakPressed,
    required this.strokeNeutralSubtle,
    required this.strokeNeutralWeak,
    required this.strokeNeutralSolid,
    required this.strokeNeutralContrast,
    required this.strokeNeutralOverlay,
    required this.strokeCriticalSolid,
    required this.strokePositiveSolid,
    required this.strokeWarningSolid,
    required this.strokeInformativeSolid,
    required this.strokeCriticalWeak,
    required this.strokePositiveWeak,
    required this.strokeWarningWeak,
    required this.strokeInformativeWeak,
    required this.overlayDim,
  });

  /// brand-100
  final Color brand100;

  /// brand-200
  final Color brand200;

  /// brand-300
  final Color brand300;

  /// brand-400
  final Color brand400;

  /// brand-500
  final Color brand500;

  /// brand-600
  final Color brand600;

  /// brand-700
  final Color brand700;

  /// brand-800
  final Color brand800;

  /// brand-900
  final Color brand900;

  /// brand-1000
  final Color brand1000;

  /// gray-00
  final Color gray00;

  /// gray-100
  final Color gray100;

  /// gray-200
  final Color gray200;

  /// gray-300
  final Color gray300;

  /// gray-400
  final Color gray400;

  /// gray-500
  final Color gray500;

  /// gray-600
  final Color gray600;

  /// gray-700
  final Color gray700;

  /// gray-800
  final Color gray800;

  /// gray-900
  final Color gray900;

  /// gray-1000
  final Color gray1000;

  /// red-100
  final Color red100;

  /// red-200
  final Color red200;

  /// red-300
  final Color red300;

  /// red-400
  final Color red400;

  /// red-500
  final Color red500;

  /// red-600
  final Color red600;

  /// red-700
  final Color red700;

  /// red-800
  final Color red800;

  /// red-900
  final Color red900;

  /// red-1000
  final Color red1000;

  /// green-100
  final Color green100;

  /// green-200
  final Color green200;

  /// green-300
  final Color green300;

  /// green-400
  final Color green400;

  /// green-500
  final Color green500;

  /// green-600
  final Color green600;

  /// green-700
  final Color green700;

  /// green-800
  final Color green800;

  /// green-900
  final Color green900;

  /// green-1000
  final Color green1000;

  /// orange-100
  final Color orange100;

  /// orange-200
  final Color orange200;

  /// orange-300
  final Color orange300;

  /// orange-400
  final Color orange400;

  /// orange-500
  final Color orange500;

  /// orange-600
  final Color orange600;

  /// orange-700
  final Color orange700;

  /// orange-800
  final Color orange800;

  /// orange-900
  final Color orange900;

  /// orange-1000
  final Color orange1000;

  /// blue-100
  final Color blue100;

  /// blue-200
  final Color blue200;

  /// blue-300
  final Color blue300;

  /// blue-400
  final Color blue400;

  /// blue-500
  final Color blue500;

  /// blue-600
  final Color blue600;

  /// blue-700
  final Color blue700;

  /// blue-800
  final Color blue800;

  /// blue-900
  final Color blue900;

  /// blue-1000
  final Color blue1000;

  /// yellow-100
  final Color yellow100;

  /// yellow-200
  final Color yellow200;

  /// yellow-300
  final Color yellow300;

  /// yellow-400
  final Color yellow400;

  /// yellow-500
  final Color yellow500;

  /// yellow-600
  final Color yellow600;

  /// yellow-700
  final Color yellow700;

  /// yellow-800
  final Color yellow800;

  /// yellow-900
  final Color yellow900;

  /// yellow-1000
  final Color yellow1000;

  /// indigo-100
  final Color indigo100;

  /// indigo-200
  final Color indigo200;

  /// indigo-300
  final Color indigo300;

  /// indigo-400
  final Color indigo400;

  /// indigo-500
  final Color indigo500;

  /// indigo-600
  final Color indigo600;

  /// indigo-700
  final Color indigo700;

  /// indigo-800
  final Color indigo800;

  /// indigo-900
  final Color indigo900;

  /// indigo-1000
  final Color indigo1000;

  /// violet-100
  final Color violet100;

  /// violet-200
  final Color violet200;

  /// violet-300
  final Color violet300;

  /// violet-400
  final Color violet400;

  /// violet-500
  final Color violet500;

  /// violet-600
  final Color violet600;

  /// violet-700
  final Color violet700;

  /// violet-800
  final Color violet800;

  /// violet-900
  final Color violet900;

  /// violet-1000
  final Color violet1000;

  /// pink-100
  final Color pink100;

  /// pink-200
  final Color pink200;

  /// pink-300
  final Color pink300;

  /// pink-400
  final Color pink400;

  /// pink-500
  final Color pink500;

  /// pink-600
  final Color pink600;

  /// pink-700
  final Color pink700;

  /// pink-800
  final Color pink800;

  /// pink-900
  final Color pink900;

  /// pink-1000
  final Color pink1000;

  /// brown-100
  final Color brown100;

  /// brown-200
  final Color brown200;

  /// brown-300
  final Color brown300;

  /// brown-400
  final Color brown400;

  /// brown-500
  final Color brown500;

  /// brown-600
  final Color brown600;

  /// brown-700
  final Color brown700;

  /// brown-800
  final Color brown800;

  /// brown-900
  final Color brown900;

  /// brown-1000
  final Color brown1000;

  /// chart-red
  final Color chartRed;

  /// chart-orange
  final Color chartOrange;

  /// chart-yellow
  final Color chartYellow;

  /// chart-green
  final Color chartGreen;

  /// chart-blue
  final Color chartBlue;

  /// chart-indigo
  final Color chartIndigo;

  /// chart-violet
  final Color chartViolet;

  /// chart-pink
  final Color chartPink;

  /// chart-brown
  final Color chartBrown;

  /// chart-gray
  final Color chartGray;

  /// chart-red-weak
  final Color chartRedWeak;

  /// chart-red-subtle
  final Color chartRedSubtle;

  /// chart-red-contrast
  final Color chartRedContrast;

  /// chart-orange-weak
  final Color chartOrangeWeak;

  /// chart-orange-subtle
  final Color chartOrangeSubtle;

  /// chart-orange-contrast
  final Color chartOrangeContrast;

  /// chart-yellow-weak
  final Color chartYellowWeak;

  /// chart-yellow-subtle
  final Color chartYellowSubtle;

  /// chart-yellow-contrast
  final Color chartYellowContrast;

  /// chart-green-weak
  final Color chartGreenWeak;

  /// chart-green-subtle
  final Color chartGreenSubtle;

  /// chart-green-contrast
  final Color chartGreenContrast;

  /// chart-blue-weak
  final Color chartBlueWeak;

  /// chart-blue-subtle
  final Color chartBlueSubtle;

  /// chart-blue-contrast
  final Color chartBlueContrast;

  /// chart-indigo-weak
  final Color chartIndigoWeak;

  /// chart-indigo-subtle
  final Color chartIndigoSubtle;

  /// chart-indigo-contrast
  final Color chartIndigoContrast;

  /// chart-violet-weak
  final Color chartVioletWeak;

  /// chart-violet-subtle
  final Color chartVioletSubtle;

  /// chart-violet-contrast
  final Color chartVioletContrast;

  /// chart-pink-weak
  final Color chartPinkWeak;

  /// chart-pink-subtle
  final Color chartPinkSubtle;

  /// chart-pink-contrast
  final Color chartPinkContrast;

  /// chart-brown-weak
  final Color chartBrownWeak;

  /// chart-brown-subtle
  final Color chartBrownSubtle;

  /// chart-brown-contrast
  final Color chartBrownContrast;

  /// chart-gray-weak
  final Color chartGrayWeak;

  /// chart-gray-subtle
  final Color chartGraySubtle;

  /// chart-gray-contrast
  final Color chartGrayContrast;

  /// fg-brand
  final Color fgBrand;

  /// fg-brand-contrast
  final Color fgBrandContrast;

  /// fg-brand-inverted
  final Color fgBrandInverted;

  /// bg-brand-solid
  final Color bgBrandSolid;

  /// bg-brand-solid-pressed
  final Color bgBrandSolidPressed;

  /// bg-brand-weak
  final Color bgBrandWeak;

  /// bg-brand-weak-pressed
  final Color bgBrandWeakPressed;

  /// stroke-focus-ring
  final Color strokeFocusRing;

  /// stroke-brand-solid
  final Color strokeBrandSolid;

  /// stroke-brand-weak
  final Color strokeBrandWeak;

  /// fg-neutral
  final Color fgNeutral;

  /// fg-neutral-muted
  final Color fgNeutralMuted;

  /// fg-neutral-subtle
  final Color fgNeutralSubtle;

  /// fg-neutral-inverted
  final Color fgNeutralInverted;

  /// fg-placeholder
  final Color fgPlaceholder;

  /// fg-disabled
  final Color fgDisabled;

  /// static-white
  final Color staticWhite;

  /// fg-critical
  final Color fgCritical;

  /// fg-positive
  final Color fgPositive;

  /// fg-warning
  final Color fgWarning;

  /// fg-informative
  final Color fgInformative;

  /// fg-critical-contrast
  final Color fgCriticalContrast;

  /// fg-positive-contrast
  final Color fgPositiveContrast;

  /// fg-warning-contrast
  final Color fgWarningContrast;

  /// fg-informative-contrast
  final Color fgInformativeContrast;

  /// fg-positive-inverted
  final Color fgPositiveInverted;

  /// fg-critical-inverted
  final Color fgCriticalInverted;

  /// bg-layer-basement
  final Color bgLayerBasement;

  /// bg-layer-default
  final Color bgLayerDefault;

  /// bg-layer-default-pressed
  final Color bgLayerDefaultPressed;

  /// bg-layer-floating
  final Color bgLayerFloating;

  /// bg-layer-floating-pressed
  final Color bgLayerFloatingPressed;

  /// bg-neutral-weak
  final Color bgNeutralWeak;

  /// bg-neutral-weak-pressed
  final Color bgNeutralWeakPressed;

  /// bg-neutral-weak-alpha
  final Color bgNeutralWeakAlpha;

  /// bg-neutral-weak-alpha-pressed
  final Color bgNeutralWeakAlphaPressed;

  /// bg-neutral-inverted
  final Color bgNeutralInverted;

  /// bg-neutral-inverted-pressed
  final Color bgNeutralInvertedPressed;

  /// bg-disabled
  final Color bgDisabled;

  /// bg-critical-solid
  final Color bgCriticalSolid;

  /// bg-critical-solid-pressed
  final Color bgCriticalSolidPressed;

  /// bg-critical-weak
  final Color bgCriticalWeak;

  /// bg-critical-weak-pressed
  final Color bgCriticalWeakPressed;

  /// bg-positive-solid
  final Color bgPositiveSolid;

  /// bg-positive-solid-pressed
  final Color bgPositiveSolidPressed;

  /// bg-positive-weak
  final Color bgPositiveWeak;

  /// bg-positive-weak-pressed
  final Color bgPositiveWeakPressed;

  /// bg-warning-solid
  final Color bgWarningSolid;

  /// bg-warning-solid-pressed
  final Color bgWarningSolidPressed;

  /// bg-warning-weak
  final Color bgWarningWeak;

  /// bg-warning-weak-pressed
  final Color bgWarningWeakPressed;

  /// bg-informative-solid
  final Color bgInformativeSolid;

  /// bg-informative-solid-pressed
  final Color bgInformativeSolidPressed;

  /// bg-informative-weak
  final Color bgInformativeWeak;

  /// bg-informative-weak-pressed
  final Color bgInformativeWeakPressed;

  /// stroke-neutral-subtle
  final Color strokeNeutralSubtle;

  /// stroke-neutral-weak
  final Color strokeNeutralWeak;

  /// stroke-neutral-solid
  final Color strokeNeutralSolid;

  /// stroke-neutral-contrast
  final Color strokeNeutralContrast;

  /// stroke-neutral-overlay
  final Color strokeNeutralOverlay;

  /// stroke-critical-solid
  final Color strokeCriticalSolid;

  /// stroke-positive-solid
  final Color strokePositiveSolid;

  /// stroke-warning-solid
  final Color strokeWarningSolid;

  /// stroke-informative-solid
  final Color strokeInformativeSolid;

  /// stroke-critical-weak
  final Color strokeCriticalWeak;

  /// stroke-positive-weak
  final Color strokePositiveWeak;

  /// stroke-warning-weak
  final Color strokeWarningWeak;

  /// stroke-informative-weak
  final Color strokeInformativeWeak;

  /// overlay-dim-light · overlay-dim-dark — 모달 · 시트 뒤 딤
  final Color overlayDim;

  static const PColors light = PColors(
    brand100: Color(0xFFE8F1FE),
    brand200: Color(0xFFD7E5FC),
    brand300: Color(0xFF79A6F3),
    brand400: Color(0xFF6587C1),
    brand500: Color(0xFF3765B1),
    brand600: Color(0xFF0147AD),
    brand700: Color(0xFF013D96),
    brand800: Color(0xFF00307A),
    brand900: Color(0xFF002460),
    brand1000: Color(0xFF001948),
    gray00: Color(0xFFFFFFFF),
    gray100: Color(0xFFF7F8FD),
    gray200: Color(0xFFF5F6FA),
    gray300: Color(0xFFEDEFF3),
    gray400: Color(0xFFE5E8EF),
    gray500: Color(0xFF8A91A0),
    gray600: Color(0xFF767C8B),
    gray700: Color(0xFF62697A),
    gray800: Color(0xFF535866),
    gray900: Color(0xFF2F3541),
    gray1000: Color(0xFF1A1F2E),
    red100: Color(0xFFFFEFEC),
    red200: Color(0xFFFFDEDA),
    red300: Color(0xFFFEC4BC),
    red400: Color(0xFFFCA195),
    red500: Color(0xFFF8776B),
    red600: Color(0xFFE95046),
    red700: Color(0xFFD72323),
    red800: Color(0xFFC01016),
    red900: Color(0xFF96030C),
    red1000: Color(0xFF5C0004),
    green100: Color(0xFFEAF5EC),
    green200: Color(0xFFD8EADB),
    green300: Color(0xFFBBDAC1),
    green400: Color(0xFF95C49E),
    green500: Color(0xFF6AAC7A),
    green600: Color(0xFF43955B),
    green700: Color(0xFF167F3F),
    green800: Color(0xFF026E33),
    green900: Color(0xFF075527),
    green1000: Color(0xFF023214),
    orange100: Color(0xFFFFEFE8),
    orange200: Color(0xFFFAE0D5),
    orange300: Color(0xFFF5C7B6),
    orange400: Color(0xFFEDA98E),
    orange500: Color(0xFFE18663),
    orange600: Color(0xFFD1673B),
    orange700: Color(0xFFBE490D),
    orange800: Color(0xFFA53E0A),
    orange900: Color(0xFF822E02),
    orange1000: Color(0xFF4E1801),
    blue100: Color(0xFFEAF3FE),
    blue200: Color(0xFFD7E6FB),
    blue300: Color(0xFFB9D4F6),
    blue400: Color(0xFF92BCF0),
    blue500: Color(0xFF69A0E7),
    blue600: Color(0xFF4387DA),
    blue700: Color(0xFF1D6EC9),
    blue800: Color(0xFF0F5FB3),
    blue900: Color(0xFF06498D),
    blue1000: Color(0xFF022956),
    yellow100: Color(0xFFF5F2E8),
    yellow200: Color(0xFFEAE6D4),
    yellow300: Color(0xFFDAD2B4),
    yellow400: Color(0xFFC5B98A),
    yellow500: Color(0xFFAF9E5D),
    yellow600: Color(0xFF998331),
    yellow700: Color(0xFF8C7400),
    yellow800: Color(0xFF725E01),
    yellow900: Color(0xFF574805),
    yellow1000: Color(0xFF332902),
    indigo100: Color(0xFFEFF2FF),
    indigo200: Color(0xFFE1E4FC),
    indigo300: Color(0xFFCACFF7),
    indigo400: Color(0xFFADB4F1),
    indigo500: Color(0xFF9098E9),
    indigo600: Color(0xFF767CDC),
    indigo700: Color(0xFF5E60C8),
    indigo800: Color(0xFF5354B6),
    indigo900: Color(0xFF3F3E92),
    indigo1000: Color(0xFF242359),
    violet100: Color(0xFFF7EFFE),
    violet200: Color(0xFFECE1F8),
    violet300: Color(0xFFDEC9F2),
    violet400: Color(0xFFCCACEA),
    violet500: Color(0xFFB88BDF),
    violet600: Color(0xFFA46DD1),
    violet700: Color(0xFF8B4DBA),
    violet800: Color(0xFF7F44AA),
    violet900: Color(0xFF633089),
    violet1000: Color(0xFF3B1A53),
    pink100: Color(0xFFFFEEF4),
    pink200: Color(0xFFFBDEE9),
    pink300: Color(0xFFF5C5D7),
    pink400: Color(0xFFEDA3C2),
    pink500: Color(0xFFE07FAA),
    pink600: Color(0xFFD05E93),
    pink700: Color(0xFFB83B7A),
    pink800: Color(0xFFA7326D),
    pink900: Color(0xFF851F55),
    pink1000: Color(0xFF510E31),
    brown100: Color(0xFFF8F0EB),
    brown200: Color(0xFFEFE3DA),
    brown300: Color(0xFFE3CEBD),
    brown400: Color(0xFFD2B399),
    brown500: Color(0xFFC09573),
    brown600: Color(0xFFAC7B51),
    brown700: Color(0xFF9A6536),
    brown800: Color(0xFF855428),
    brown900: Color(0xFF693F18),
    brown1000: Color(0xFF3F240A),
    chartRed: Color(0xFFD72323),
    chartOrange: Color(0xFFBE490D),
    chartYellow: Color(0xFF8C7400),
    chartGreen: Color(0xFF167F3F),
    chartBlue: Color(0xFF1D6EC9),
    chartIndigo: Color(0xFF5E60C8),
    chartViolet: Color(0xFF8B4DBA),
    chartPink: Color(0xFFB83B7A),
    chartBrown: Color(0xFF9A6536),
    chartGray: Color(0xFF62697A),
    chartRedWeak: Color(0xFFFFDEDA),
    chartRedSubtle: Color(0xFFFFEFEC),
    chartRedContrast: Color(0xFFC01016),
    chartOrangeWeak: Color(0xFFFAE0D5),
    chartOrangeSubtle: Color(0xFFFFEFE8),
    chartOrangeContrast: Color(0xFFA53E0A),
    chartYellowWeak: Color(0xFFEAE6D4),
    chartYellowSubtle: Color(0xFFF5F2E8),
    chartYellowContrast: Color(0xFF725E01),
    chartGreenWeak: Color(0xFFD8EADB),
    chartGreenSubtle: Color(0xFFEAF5EC),
    chartGreenContrast: Color(0xFF026E33),
    chartBlueWeak: Color(0xFFD7E6FB),
    chartBlueSubtle: Color(0xFFEAF3FE),
    chartBlueContrast: Color(0xFF0F5FB3),
    chartIndigoWeak: Color(0xFFE1E4FC),
    chartIndigoSubtle: Color(0xFFEFF2FF),
    chartIndigoContrast: Color(0xFF5354B6),
    chartVioletWeak: Color(0xFFECE1F8),
    chartVioletSubtle: Color(0xFFF7EFFE),
    chartVioletContrast: Color(0xFF7F44AA),
    chartPinkWeak: Color(0xFFFBDEE9),
    chartPinkSubtle: Color(0xFFFFEEF4),
    chartPinkContrast: Color(0xFFA7326D),
    chartBrownWeak: Color(0xFFEFE3DA),
    chartBrownSubtle: Color(0xFFF8F0EB),
    chartBrownContrast: Color(0xFF855428),
    chartGrayWeak: Color(0xFFE5E8EF),
    chartGraySubtle: Color(0xFFEDEFF3),
    chartGrayContrast: Color(0xFF535866),
    fgBrand: Color(0xFF0147AD),
    fgBrandContrast: Color(0xFF013D96),
    fgBrandInverted: Color(0xFF7AA9F6),
    bgBrandSolid: Color(0xFF0147AD),
    bgBrandSolidPressed: Color(0xFF013D96),
    bgBrandWeak: Color(0xFFE8F1FE),
    bgBrandWeakPressed: Color(0xFFD7E5FC),
    strokeFocusRing: Color(0xFF0147AD),
    strokeBrandSolid: Color(0xFF0147AD),
    strokeBrandWeak: Color(0xFF79A6F3),
    fgNeutral: Color(0xFF1A1F2E),
    fgNeutralMuted: Color(0xFF535866),
    fgNeutralSubtle: Color(0xFF62697A),
    fgNeutralInverted: Color(0xFFFFFFFF),
    fgPlaceholder: Color(0xFF767C8B),
    fgDisabled: Color(0xFF8A91A0),
    staticWhite: Color(0xFFFFFFFF),
    fgCritical: Color(0xFFD72323),
    fgPositive: Color(0xFF167F3F),
    fgWarning: Color(0xFFBE490D),
    fgInformative: Color(0xFF1D6EC9),
    fgCriticalContrast: Color(0xFFC01016),
    fgPositiveContrast: Color(0xFF026E33),
    fgWarningContrast: Color(0xFFA53E0A),
    fgInformativeContrast: Color(0xFF0F5FB3),
    fgPositiveInverted: Color(0xFF25C062),
    fgCriticalInverted: Color(0xFFFF8477),
    bgLayerBasement: Color(0xFFF5F6FA),
    bgLayerDefault: Color(0xFFFFFFFF),
    bgLayerDefaultPressed: Color(0xFFF7F8FD),
    bgLayerFloating: Color(0xFFFFFFFF),
    bgLayerFloatingPressed: Color(0xFFF7F8FD),
    bgNeutralWeak: Color(0xFFF5F6FA),
    bgNeutralWeakPressed: Color(0xFFEDEFF3),
    bgNeutralWeakAlpha: Color(0x0C000000),
    bgNeutralWeakAlphaPressed: Color(0x10000000),
    bgNeutralInverted: Color(0xFF1A1F2E),
    bgNeutralInvertedPressed: Color(0xFF535866),
    bgDisabled: Color(0xFFF5F6FA),
    bgCriticalSolid: Color(0xFFD72323),
    bgCriticalSolidPressed: Color(0xFFC01016),
    bgCriticalWeak: Color(0xFFFFEFEC),
    bgCriticalWeakPressed: Color(0xFFFFDEDA),
    bgPositiveSolid: Color(0xFF167F3F),
    bgPositiveSolidPressed: Color(0xFF026E33),
    bgPositiveWeak: Color(0xFFEAF5EC),
    bgPositiveWeakPressed: Color(0xFFD8EADB),
    bgWarningSolid: Color(0xFFBE490D),
    bgWarningSolidPressed: Color(0xFFA53E0A),
    bgWarningWeak: Color(0xFFFFEFE8),
    bgWarningWeakPressed: Color(0xFFFAE0D5),
    bgInformativeSolid: Color(0xFF1D6EC9),
    bgInformativeSolidPressed: Color(0xFF0F5FB3),
    bgInformativeWeak: Color(0xFFEAF3FE),
    bgInformativeWeakPressed: Color(0xFFD7E6FB),
    strokeNeutralSubtle: Color(0xFFEDEFF3),
    strokeNeutralWeak: Color(0xFFE5E8EF),
    strokeNeutralSolid: Color(0xFF767C8B),
    strokeNeutralContrast: Color(0xFF1A1F2E),
    strokeNeutralOverlay: Color(0x0C000000),
    strokeCriticalSolid: Color(0xFFD72323),
    strokePositiveSolid: Color(0xFF167F3F),
    strokeWarningSolid: Color(0xFFBE490D),
    strokeInformativeSolid: Color(0xFF1D6EC9),
    strokeCriticalWeak: Color(0xFFFEC4BC),
    strokePositiveWeak: Color(0xFFBBDAC1),
    strokeWarningWeak: Color(0xFFF5C7B6),
    strokeInformativeWeak: Color(0xFFB9D4F6),
    overlayDim: Color(0x80000000),
  );

  static const PColors dark = PColors(
    brand100: Color(0xFF202A3C),
    brand200: Color(0xFF20314E),
    brand300: Color(0xFF1F3A69),
    brand400: Color(0xFF1A4386),
    brand500: Color(0xFF1049A4),
    brand600: Color(0xFF1052B8),
    brand700: Color(0xFF1A5AC2),
    brand800: Color(0xFF4C83DC),
    brand900: Color(0xFF7AA9F6),
    brand1000: Color(0xFFCCD5E3),
    gray00: Color(0xFF1A1F2E),
    gray100: Color(0xFF242938),
    gray200: Color(0xFF2D3346),
    gray300: Color(0xFF353B4D),
    gray400: Color(0xFF404757),
    gray500: Color(0xFF656B78),
    gray600: Color(0xFF838997),
    gray700: Color(0xFFA2A8B7),
    gray800: Color(0xFFB7BDCC),
    gray900: Color(0xFFD6DDEC),
    gray1000: Color(0xFFF5F6FA),
    red100: Color(0xFF3E231F),
    red200: Color(0xFF532722),
    red300: Color(0xFF722722),
    red400: Color(0xFF93231F),
    red500: Color(0xFFB51317),
    red600: Color(0xFFCC0E17),
    red700: Color(0xFFD82424),
    red800: Color(0xFFFF8477),
    red900: Color(0xFFFFBCB3),
    red1000: Color(0xFFFEEDEA),
    green100: Color(0xFF202D23),
    green200: Color(0xFF223927),
    green300: Color(0xFF20482B),
    green400: Color(0xFF1A582F),
    green500: Color(0xFF076931),
    green600: Color(0xFF117539),
    green700: Color(0xFF198140),
    green800: Color(0xFF25C062),
    green900: Color(0xFFAED6B6),
    green1000: Color(0xFFE9F4EB),
    orange100: Color(0xFF39251E),
    orange200: Color(0xFF4B2B1F),
    orange300: Color(0xFF65321D),
    orange400: Color(0xFF833615),
    orange500: Color(0xFF9F3901),
    orange600: Color(0xFFB04209),
    orange700: Color(0xFFBF4A10),
    orange800: Color(0xFFFF8758),
    orange900: Color(0xFFF9BFA9),
    orange1000: Color(0xFFFEEEE7),
    blue100: Color(0xFF1F2A39),
    blue200: Color(0xFF21344D),
    blue300: Color(0xFF204069),
    blue400: Color(0xFF1C4E8A),
    blue500: Color(0xFF125AAA),
    blue600: Color(0xFF0F65BF),
    blue700: Color(0xFF1F70CB),
    blue800: Color(0xFF69ABFF),
    blue900: Color(0xFFACCEFB),
    blue1000: Color(0xFFE8F2FE),
    yellow100: Color(0xFF2D2A1D),
    yellow200: Color(0xFF3A331D),
    yellow300: Color(0xFF4A4019),
    yellow400: Color(0xFF5C4D0B),
    yellow500: Color(0xFF6C5906),
    yellow600: Color(0xFF796400),
    yellow700: Color(0xFF846E04),
    yellow800: Color(0xFFC5A721),
    yellow900: Color(0xFFD7CCA6),
    yellow1000: Color(0xFFF3F1E6),
    indigo100: Color(0xFF26293A),
    indigo200: Color(0xFF2F324E),
    indigo300: Color(0xFF383C6A),
    indigo400: Color(0xFF44468B),
    indigo500: Color(0xFF4F51AB),
    indigo600: Color(0xFF585AC1),
    indigo700: Color(0xFF6264CC),
    indigo800: Color(0xFF99A1FE),
    indigo900: Color(0xFFC3C9FC),
    indigo1000: Color(0xFFEEF0FE),
    violet100: Color(0xFF302638),
    violet200: Color(0xFF3D2E4B),
    violet300: Color(0xFF4F3565),
    violet400: Color(0xFF643C83),
    violet500: Color(0xFF7842A1),
    violet600: Color(0xFF8749B5),
    violet700: Color(0xFF9153C0),
    violet800: Color(0xFFC793F3),
    violet900: Color(0xFFDCC1F6),
    violet1000: Color(0xFFF5EEFC),
    pink100: Color(0xFF38242C),
    pink200: Color(0xFF4C2938),
    pink300: Color(0xFF642D47),
    pink400: Color(0xFF813058),
    pink500: Color(0xFF9E3067),
    pink600: Color(0xFFB23574),
    pink700: Color(0xFFBD407F),
    pink800: Color(0xFFF485B6),
    pink900: Color(0xFFF9BBD3),
    pink1000: Color(0xFFFEECF3),
    brown100: Color(0xFF322821),
    brown200: Color(0xFF3F3024),
    brown300: Color(0xFF533B26),
    brown400: Color(0xFF694628),
    brown500: Color(0xFF7E5127),
    brown600: Color(0xFF8E5A2A),
    brown700: Color(0xFF986334),
    brown800: Color(0xFFCF9F77),
    brown900: Color(0xFFE2C7B2),
    brown1000: Color(0xFFF7F0EA),
    chartRed: Color(0xFFFF8477),
    chartOrange: Color(0xFFFF8758),
    chartYellow: Color(0xFFC5A721),
    chartGreen: Color(0xFF25C062),
    chartBlue: Color(0xFF69ABFF),
    chartIndigo: Color(0xFF99A1FE),
    chartViolet: Color(0xFFC793F3),
    chartPink: Color(0xFFF485B6),
    chartBrown: Color(0xFFCF9F77),
    chartGray: Color(0xFFB7BDCC),
    chartRedWeak: Color(0xFF722722),
    chartRedSubtle: Color(0xFF532722),
    chartRedContrast: Color(0xFFFFBCB3),
    chartOrangeWeak: Color(0xFF65321D),
    chartOrangeSubtle: Color(0xFF4B2B1F),
    chartOrangeContrast: Color(0xFFF9BFA9),
    chartYellowWeak: Color(0xFF4A4019),
    chartYellowSubtle: Color(0xFF3A331D),
    chartYellowContrast: Color(0xFFD7CCA6),
    chartGreenWeak: Color(0xFF20482B),
    chartGreenSubtle: Color(0xFF223927),
    chartGreenContrast: Color(0xFFAED6B6),
    chartBlueWeak: Color(0xFF204069),
    chartBlueSubtle: Color(0xFF21344D),
    chartBlueContrast: Color(0xFFACCEFB),
    chartIndigoWeak: Color(0xFF383C6A),
    chartIndigoSubtle: Color(0xFF2F324E),
    chartIndigoContrast: Color(0xFFC3C9FC),
    chartVioletWeak: Color(0xFF4F3565),
    chartVioletSubtle: Color(0xFF3D2E4B),
    chartVioletContrast: Color(0xFFDCC1F6),
    chartPinkWeak: Color(0xFF642D47),
    chartPinkSubtle: Color(0xFF4C2938),
    chartPinkContrast: Color(0xFFF9BBD3),
    chartBrownWeak: Color(0xFF533B26),
    chartBrownSubtle: Color(0xFF3F3024),
    chartBrownContrast: Color(0xFFE2C7B2),
    chartGrayWeak: Color(0xFF404757),
    chartGraySubtle: Color(0xFF353B4D),
    chartGrayContrast: Color(0xFFD6DDEC),
    fgBrand: Color(0xFF7AA9F6),
    fgBrandContrast: Color(0xFF7AA9F6),
    fgBrandInverted: Color(0xFF0147AD),
    bgBrandSolid: Color(0xFF1049A4),
    bgBrandSolidPressed: Color(0xFF1A5AC2),
    bgBrandWeak: Color(0xFF20314E),
    bgBrandWeakPressed: Color(0xFF1F3A69),
    strokeFocusRing: Color(0xFF7AA9F6),
    strokeBrandSolid: Color(0xFF7AA9F6),
    strokeBrandWeak: Color(0xFF4C83DC),
    fgNeutral: Color(0xFFF5F6FA),
    fgNeutralMuted: Color(0xFFB7BDCC),
    fgNeutralSubtle: Color(0xFFA2A8B7),
    fgNeutralInverted: Color(0xFF242938),
    fgPlaceholder: Color(0xFF838997),
    fgDisabled: Color(0xFF838997),
    staticWhite: Color(0xFFFFFFFF),
    fgCritical: Color(0xFFFF8477),
    fgPositive: Color(0xFF25C062),
    fgWarning: Color(0xFFFF8758),
    fgInformative: Color(0xFF69ABFF),
    fgCriticalContrast: Color(0xFFFFBCB3),
    fgPositiveContrast: Color(0xFFAED6B6),
    fgWarningContrast: Color(0xFFF9BFA9),
    fgInformativeContrast: Color(0xFFACCEFB),
    fgPositiveInverted: Color(0xFF167F3F),
    fgCriticalInverted: Color(0xFFD72323),
    bgLayerBasement: Color(0xFF1A1F2E),
    bgLayerDefault: Color(0xFF242938),
    bgLayerDefaultPressed: Color(0xFF353B4D),
    bgLayerFloating: Color(0xFF2D3346),
    bgLayerFloatingPressed: Color(0xFF353B4D),
    bgNeutralWeak: Color(0xFF353B4D),
    bgNeutralWeakPressed: Color(0xFF404757),
    bgNeutralWeakAlpha: Color(0x20FFFFFF),
    bgNeutralWeakAlphaPressed: Color(0x2EFFFFFF),
    bgNeutralInverted: Color(0xFFF5F6FA),
    bgNeutralInvertedPressed: Color(0xFFB7BDCC),
    bgDisabled: Color(0xFF353B4D),
    bgCriticalSolid: Color(0xFFCC0E17),
    bgCriticalSolidPressed: Color(0xFFD82424),
    bgCriticalWeak: Color(0xFF532722),
    bgCriticalWeakPressed: Color(0xFF722722),
    bgPositiveSolid: Color(0xFF117539),
    bgPositiveSolidPressed: Color(0xFF198140),
    bgPositiveWeak: Color(0xFF223927),
    bgPositiveWeakPressed: Color(0xFF20482B),
    bgWarningSolid: Color(0xFFB04209),
    bgWarningSolidPressed: Color(0xFFBF4A10),
    bgWarningWeak: Color(0xFF4B2B1F),
    bgWarningWeakPressed: Color(0xFF65321D),
    bgInformativeSolid: Color(0xFF0F65BF),
    bgInformativeSolidPressed: Color(0xFF1F70CB),
    bgInformativeWeak: Color(0xFF21344D),
    bgInformativeWeakPressed: Color(0xFF204069),
    strokeNeutralSubtle: Color(0xFF353B4D),
    strokeNeutralWeak: Color(0xFF404757),
    strokeNeutralSolid: Color(0xFF838997),
    strokeNeutralContrast: Color(0xFFF5F6FA),
    strokeNeutralOverlay: Color(0x0DFFFFFF),
    strokeCriticalSolid: Color(0xFFFF8477),
    strokePositiveSolid: Color(0xFF25C062),
    strokeWarningSolid: Color(0xFFFF8758),
    strokeInformativeSolid: Color(0xFF69ABFF),
    strokeCriticalWeak: Color(0xFF93231F),
    strokePositiveWeak: Color(0xFF1A582F),
    strokeWarningWeak: Color(0xFF833615),
    strokeInformativeWeak: Color(0xFF1C4E8A),
    overlayDim: Color(0xA6000000),
  );

  @override
  PColors copyWith({
    Color? brand100,
    Color? brand200,
    Color? brand300,
    Color? brand400,
    Color? brand500,
    Color? brand600,
    Color? brand700,
    Color? brand800,
    Color? brand900,
    Color? brand1000,
    Color? gray00,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray600,
    Color? gray700,
    Color? gray800,
    Color? gray900,
    Color? gray1000,
    Color? red100,
    Color? red200,
    Color? red300,
    Color? red400,
    Color? red500,
    Color? red600,
    Color? red700,
    Color? red800,
    Color? red900,
    Color? red1000,
    Color? green100,
    Color? green200,
    Color? green300,
    Color? green400,
    Color? green500,
    Color? green600,
    Color? green700,
    Color? green800,
    Color? green900,
    Color? green1000,
    Color? orange100,
    Color? orange200,
    Color? orange300,
    Color? orange400,
    Color? orange500,
    Color? orange600,
    Color? orange700,
    Color? orange800,
    Color? orange900,
    Color? orange1000,
    Color? blue100,
    Color? blue200,
    Color? blue300,
    Color? blue400,
    Color? blue500,
    Color? blue600,
    Color? blue700,
    Color? blue800,
    Color? blue900,
    Color? blue1000,
    Color? yellow100,
    Color? yellow200,
    Color? yellow300,
    Color? yellow400,
    Color? yellow500,
    Color? yellow600,
    Color? yellow700,
    Color? yellow800,
    Color? yellow900,
    Color? yellow1000,
    Color? indigo100,
    Color? indigo200,
    Color? indigo300,
    Color? indigo400,
    Color? indigo500,
    Color? indigo600,
    Color? indigo700,
    Color? indigo800,
    Color? indigo900,
    Color? indigo1000,
    Color? violet100,
    Color? violet200,
    Color? violet300,
    Color? violet400,
    Color? violet500,
    Color? violet600,
    Color? violet700,
    Color? violet800,
    Color? violet900,
    Color? violet1000,
    Color? pink100,
    Color? pink200,
    Color? pink300,
    Color? pink400,
    Color? pink500,
    Color? pink600,
    Color? pink700,
    Color? pink800,
    Color? pink900,
    Color? pink1000,
    Color? brown100,
    Color? brown200,
    Color? brown300,
    Color? brown400,
    Color? brown500,
    Color? brown600,
    Color? brown700,
    Color? brown800,
    Color? brown900,
    Color? brown1000,
    Color? chartRed,
    Color? chartOrange,
    Color? chartYellow,
    Color? chartGreen,
    Color? chartBlue,
    Color? chartIndigo,
    Color? chartViolet,
    Color? chartPink,
    Color? chartBrown,
    Color? chartGray,
    Color? chartRedWeak,
    Color? chartRedSubtle,
    Color? chartRedContrast,
    Color? chartOrangeWeak,
    Color? chartOrangeSubtle,
    Color? chartOrangeContrast,
    Color? chartYellowWeak,
    Color? chartYellowSubtle,
    Color? chartYellowContrast,
    Color? chartGreenWeak,
    Color? chartGreenSubtle,
    Color? chartGreenContrast,
    Color? chartBlueWeak,
    Color? chartBlueSubtle,
    Color? chartBlueContrast,
    Color? chartIndigoWeak,
    Color? chartIndigoSubtle,
    Color? chartIndigoContrast,
    Color? chartVioletWeak,
    Color? chartVioletSubtle,
    Color? chartVioletContrast,
    Color? chartPinkWeak,
    Color? chartPinkSubtle,
    Color? chartPinkContrast,
    Color? chartBrownWeak,
    Color? chartBrownSubtle,
    Color? chartBrownContrast,
    Color? chartGrayWeak,
    Color? chartGraySubtle,
    Color? chartGrayContrast,
    Color? fgBrand,
    Color? fgBrandContrast,
    Color? fgBrandInverted,
    Color? bgBrandSolid,
    Color? bgBrandSolidPressed,
    Color? bgBrandWeak,
    Color? bgBrandWeakPressed,
    Color? strokeFocusRing,
    Color? strokeBrandSolid,
    Color? strokeBrandWeak,
    Color? fgNeutral,
    Color? fgNeutralMuted,
    Color? fgNeutralSubtle,
    Color? fgNeutralInverted,
    Color? fgPlaceholder,
    Color? fgDisabled,
    Color? staticWhite,
    Color? fgCritical,
    Color? fgPositive,
    Color? fgWarning,
    Color? fgInformative,
    Color? fgCriticalContrast,
    Color? fgPositiveContrast,
    Color? fgWarningContrast,
    Color? fgInformativeContrast,
    Color? fgPositiveInverted,
    Color? fgCriticalInverted,
    Color? bgLayerBasement,
    Color? bgLayerDefault,
    Color? bgLayerDefaultPressed,
    Color? bgLayerFloating,
    Color? bgLayerFloatingPressed,
    Color? bgNeutralWeak,
    Color? bgNeutralWeakPressed,
    Color? bgNeutralWeakAlpha,
    Color? bgNeutralWeakAlphaPressed,
    Color? bgNeutralInverted,
    Color? bgNeutralInvertedPressed,
    Color? bgDisabled,
    Color? bgCriticalSolid,
    Color? bgCriticalSolidPressed,
    Color? bgCriticalWeak,
    Color? bgCriticalWeakPressed,
    Color? bgPositiveSolid,
    Color? bgPositiveSolidPressed,
    Color? bgPositiveWeak,
    Color? bgPositiveWeakPressed,
    Color? bgWarningSolid,
    Color? bgWarningSolidPressed,
    Color? bgWarningWeak,
    Color? bgWarningWeakPressed,
    Color? bgInformativeSolid,
    Color? bgInformativeSolidPressed,
    Color? bgInformativeWeak,
    Color? bgInformativeWeakPressed,
    Color? strokeNeutralSubtle,
    Color? strokeNeutralWeak,
    Color? strokeNeutralSolid,
    Color? strokeNeutralContrast,
    Color? strokeNeutralOverlay,
    Color? strokeCriticalSolid,
    Color? strokePositiveSolid,
    Color? strokeWarningSolid,
    Color? strokeInformativeSolid,
    Color? strokeCriticalWeak,
    Color? strokePositiveWeak,
    Color? strokeWarningWeak,
    Color? strokeInformativeWeak,
    Color? overlayDim,
  }) {
    return PColors(
      brand100: brand100 ?? this.brand100,
      brand200: brand200 ?? this.brand200,
      brand300: brand300 ?? this.brand300,
      brand400: brand400 ?? this.brand400,
      brand500: brand500 ?? this.brand500,
      brand600: brand600 ?? this.brand600,
      brand700: brand700 ?? this.brand700,
      brand800: brand800 ?? this.brand800,
      brand900: brand900 ?? this.brand900,
      brand1000: brand1000 ?? this.brand1000,
      gray00: gray00 ?? this.gray00,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray600: gray600 ?? this.gray600,
      gray700: gray700 ?? this.gray700,
      gray800: gray800 ?? this.gray800,
      gray900: gray900 ?? this.gray900,
      gray1000: gray1000 ?? this.gray1000,
      red100: red100 ?? this.red100,
      red200: red200 ?? this.red200,
      red300: red300 ?? this.red300,
      red400: red400 ?? this.red400,
      red500: red500 ?? this.red500,
      red600: red600 ?? this.red600,
      red700: red700 ?? this.red700,
      red800: red800 ?? this.red800,
      red900: red900 ?? this.red900,
      red1000: red1000 ?? this.red1000,
      green100: green100 ?? this.green100,
      green200: green200 ?? this.green200,
      green300: green300 ?? this.green300,
      green400: green400 ?? this.green400,
      green500: green500 ?? this.green500,
      green600: green600 ?? this.green600,
      green700: green700 ?? this.green700,
      green800: green800 ?? this.green800,
      green900: green900 ?? this.green900,
      green1000: green1000 ?? this.green1000,
      orange100: orange100 ?? this.orange100,
      orange200: orange200 ?? this.orange200,
      orange300: orange300 ?? this.orange300,
      orange400: orange400 ?? this.orange400,
      orange500: orange500 ?? this.orange500,
      orange600: orange600 ?? this.orange600,
      orange700: orange700 ?? this.orange700,
      orange800: orange800 ?? this.orange800,
      orange900: orange900 ?? this.orange900,
      orange1000: orange1000 ?? this.orange1000,
      blue100: blue100 ?? this.blue100,
      blue200: blue200 ?? this.blue200,
      blue300: blue300 ?? this.blue300,
      blue400: blue400 ?? this.blue400,
      blue500: blue500 ?? this.blue500,
      blue600: blue600 ?? this.blue600,
      blue700: blue700 ?? this.blue700,
      blue800: blue800 ?? this.blue800,
      blue900: blue900 ?? this.blue900,
      blue1000: blue1000 ?? this.blue1000,
      yellow100: yellow100 ?? this.yellow100,
      yellow200: yellow200 ?? this.yellow200,
      yellow300: yellow300 ?? this.yellow300,
      yellow400: yellow400 ?? this.yellow400,
      yellow500: yellow500 ?? this.yellow500,
      yellow600: yellow600 ?? this.yellow600,
      yellow700: yellow700 ?? this.yellow700,
      yellow800: yellow800 ?? this.yellow800,
      yellow900: yellow900 ?? this.yellow900,
      yellow1000: yellow1000 ?? this.yellow1000,
      indigo100: indigo100 ?? this.indigo100,
      indigo200: indigo200 ?? this.indigo200,
      indigo300: indigo300 ?? this.indigo300,
      indigo400: indigo400 ?? this.indigo400,
      indigo500: indigo500 ?? this.indigo500,
      indigo600: indigo600 ?? this.indigo600,
      indigo700: indigo700 ?? this.indigo700,
      indigo800: indigo800 ?? this.indigo800,
      indigo900: indigo900 ?? this.indigo900,
      indigo1000: indigo1000 ?? this.indigo1000,
      violet100: violet100 ?? this.violet100,
      violet200: violet200 ?? this.violet200,
      violet300: violet300 ?? this.violet300,
      violet400: violet400 ?? this.violet400,
      violet500: violet500 ?? this.violet500,
      violet600: violet600 ?? this.violet600,
      violet700: violet700 ?? this.violet700,
      violet800: violet800 ?? this.violet800,
      violet900: violet900 ?? this.violet900,
      violet1000: violet1000 ?? this.violet1000,
      pink100: pink100 ?? this.pink100,
      pink200: pink200 ?? this.pink200,
      pink300: pink300 ?? this.pink300,
      pink400: pink400 ?? this.pink400,
      pink500: pink500 ?? this.pink500,
      pink600: pink600 ?? this.pink600,
      pink700: pink700 ?? this.pink700,
      pink800: pink800 ?? this.pink800,
      pink900: pink900 ?? this.pink900,
      pink1000: pink1000 ?? this.pink1000,
      brown100: brown100 ?? this.brown100,
      brown200: brown200 ?? this.brown200,
      brown300: brown300 ?? this.brown300,
      brown400: brown400 ?? this.brown400,
      brown500: brown500 ?? this.brown500,
      brown600: brown600 ?? this.brown600,
      brown700: brown700 ?? this.brown700,
      brown800: brown800 ?? this.brown800,
      brown900: brown900 ?? this.brown900,
      brown1000: brown1000 ?? this.brown1000,
      chartRed: chartRed ?? this.chartRed,
      chartOrange: chartOrange ?? this.chartOrange,
      chartYellow: chartYellow ?? this.chartYellow,
      chartGreen: chartGreen ?? this.chartGreen,
      chartBlue: chartBlue ?? this.chartBlue,
      chartIndigo: chartIndigo ?? this.chartIndigo,
      chartViolet: chartViolet ?? this.chartViolet,
      chartPink: chartPink ?? this.chartPink,
      chartBrown: chartBrown ?? this.chartBrown,
      chartGray: chartGray ?? this.chartGray,
      chartRedWeak: chartRedWeak ?? this.chartRedWeak,
      chartRedSubtle: chartRedSubtle ?? this.chartRedSubtle,
      chartRedContrast: chartRedContrast ?? this.chartRedContrast,
      chartOrangeWeak: chartOrangeWeak ?? this.chartOrangeWeak,
      chartOrangeSubtle: chartOrangeSubtle ?? this.chartOrangeSubtle,
      chartOrangeContrast: chartOrangeContrast ?? this.chartOrangeContrast,
      chartYellowWeak: chartYellowWeak ?? this.chartYellowWeak,
      chartYellowSubtle: chartYellowSubtle ?? this.chartYellowSubtle,
      chartYellowContrast: chartYellowContrast ?? this.chartYellowContrast,
      chartGreenWeak: chartGreenWeak ?? this.chartGreenWeak,
      chartGreenSubtle: chartGreenSubtle ?? this.chartGreenSubtle,
      chartGreenContrast: chartGreenContrast ?? this.chartGreenContrast,
      chartBlueWeak: chartBlueWeak ?? this.chartBlueWeak,
      chartBlueSubtle: chartBlueSubtle ?? this.chartBlueSubtle,
      chartBlueContrast: chartBlueContrast ?? this.chartBlueContrast,
      chartIndigoWeak: chartIndigoWeak ?? this.chartIndigoWeak,
      chartIndigoSubtle: chartIndigoSubtle ?? this.chartIndigoSubtle,
      chartIndigoContrast: chartIndigoContrast ?? this.chartIndigoContrast,
      chartVioletWeak: chartVioletWeak ?? this.chartVioletWeak,
      chartVioletSubtle: chartVioletSubtle ?? this.chartVioletSubtle,
      chartVioletContrast: chartVioletContrast ?? this.chartVioletContrast,
      chartPinkWeak: chartPinkWeak ?? this.chartPinkWeak,
      chartPinkSubtle: chartPinkSubtle ?? this.chartPinkSubtle,
      chartPinkContrast: chartPinkContrast ?? this.chartPinkContrast,
      chartBrownWeak: chartBrownWeak ?? this.chartBrownWeak,
      chartBrownSubtle: chartBrownSubtle ?? this.chartBrownSubtle,
      chartBrownContrast: chartBrownContrast ?? this.chartBrownContrast,
      chartGrayWeak: chartGrayWeak ?? this.chartGrayWeak,
      chartGraySubtle: chartGraySubtle ?? this.chartGraySubtle,
      chartGrayContrast: chartGrayContrast ?? this.chartGrayContrast,
      fgBrand: fgBrand ?? this.fgBrand,
      fgBrandContrast: fgBrandContrast ?? this.fgBrandContrast,
      fgBrandInverted: fgBrandInverted ?? this.fgBrandInverted,
      bgBrandSolid: bgBrandSolid ?? this.bgBrandSolid,
      bgBrandSolidPressed: bgBrandSolidPressed ?? this.bgBrandSolidPressed,
      bgBrandWeak: bgBrandWeak ?? this.bgBrandWeak,
      bgBrandWeakPressed: bgBrandWeakPressed ?? this.bgBrandWeakPressed,
      strokeFocusRing: strokeFocusRing ?? this.strokeFocusRing,
      strokeBrandSolid: strokeBrandSolid ?? this.strokeBrandSolid,
      strokeBrandWeak: strokeBrandWeak ?? this.strokeBrandWeak,
      fgNeutral: fgNeutral ?? this.fgNeutral,
      fgNeutralMuted: fgNeutralMuted ?? this.fgNeutralMuted,
      fgNeutralSubtle: fgNeutralSubtle ?? this.fgNeutralSubtle,
      fgNeutralInverted: fgNeutralInverted ?? this.fgNeutralInverted,
      fgPlaceholder: fgPlaceholder ?? this.fgPlaceholder,
      fgDisabled: fgDisabled ?? this.fgDisabled,
      staticWhite: staticWhite ?? this.staticWhite,
      fgCritical: fgCritical ?? this.fgCritical,
      fgPositive: fgPositive ?? this.fgPositive,
      fgWarning: fgWarning ?? this.fgWarning,
      fgInformative: fgInformative ?? this.fgInformative,
      fgCriticalContrast: fgCriticalContrast ?? this.fgCriticalContrast,
      fgPositiveContrast: fgPositiveContrast ?? this.fgPositiveContrast,
      fgWarningContrast: fgWarningContrast ?? this.fgWarningContrast,
      fgInformativeContrast:
          fgInformativeContrast ?? this.fgInformativeContrast,
      fgPositiveInverted: fgPositiveInverted ?? this.fgPositiveInverted,
      fgCriticalInverted: fgCriticalInverted ?? this.fgCriticalInverted,
      bgLayerBasement: bgLayerBasement ?? this.bgLayerBasement,
      bgLayerDefault: bgLayerDefault ?? this.bgLayerDefault,
      bgLayerDefaultPressed:
          bgLayerDefaultPressed ?? this.bgLayerDefaultPressed,
      bgLayerFloating: bgLayerFloating ?? this.bgLayerFloating,
      bgLayerFloatingPressed:
          bgLayerFloatingPressed ?? this.bgLayerFloatingPressed,
      bgNeutralWeak: bgNeutralWeak ?? this.bgNeutralWeak,
      bgNeutralWeakPressed: bgNeutralWeakPressed ?? this.bgNeutralWeakPressed,
      bgNeutralWeakAlpha: bgNeutralWeakAlpha ?? this.bgNeutralWeakAlpha,
      bgNeutralWeakAlphaPressed:
          bgNeutralWeakAlphaPressed ?? this.bgNeutralWeakAlphaPressed,
      bgNeutralInverted: bgNeutralInverted ?? this.bgNeutralInverted,
      bgNeutralInvertedPressed:
          bgNeutralInvertedPressed ?? this.bgNeutralInvertedPressed,
      bgDisabled: bgDisabled ?? this.bgDisabled,
      bgCriticalSolid: bgCriticalSolid ?? this.bgCriticalSolid,
      bgCriticalSolidPressed:
          bgCriticalSolidPressed ?? this.bgCriticalSolidPressed,
      bgCriticalWeak: bgCriticalWeak ?? this.bgCriticalWeak,
      bgCriticalWeakPressed:
          bgCriticalWeakPressed ?? this.bgCriticalWeakPressed,
      bgPositiveSolid: bgPositiveSolid ?? this.bgPositiveSolid,
      bgPositiveSolidPressed:
          bgPositiveSolidPressed ?? this.bgPositiveSolidPressed,
      bgPositiveWeak: bgPositiveWeak ?? this.bgPositiveWeak,
      bgPositiveWeakPressed:
          bgPositiveWeakPressed ?? this.bgPositiveWeakPressed,
      bgWarningSolid: bgWarningSolid ?? this.bgWarningSolid,
      bgWarningSolidPressed:
          bgWarningSolidPressed ?? this.bgWarningSolidPressed,
      bgWarningWeak: bgWarningWeak ?? this.bgWarningWeak,
      bgWarningWeakPressed: bgWarningWeakPressed ?? this.bgWarningWeakPressed,
      bgInformativeSolid: bgInformativeSolid ?? this.bgInformativeSolid,
      bgInformativeSolidPressed:
          bgInformativeSolidPressed ?? this.bgInformativeSolidPressed,
      bgInformativeWeak: bgInformativeWeak ?? this.bgInformativeWeak,
      bgInformativeWeakPressed:
          bgInformativeWeakPressed ?? this.bgInformativeWeakPressed,
      strokeNeutralSubtle: strokeNeutralSubtle ?? this.strokeNeutralSubtle,
      strokeNeutralWeak: strokeNeutralWeak ?? this.strokeNeutralWeak,
      strokeNeutralSolid: strokeNeutralSolid ?? this.strokeNeutralSolid,
      strokeNeutralContrast:
          strokeNeutralContrast ?? this.strokeNeutralContrast,
      strokeNeutralOverlay: strokeNeutralOverlay ?? this.strokeNeutralOverlay,
      strokeCriticalSolid: strokeCriticalSolid ?? this.strokeCriticalSolid,
      strokePositiveSolid: strokePositiveSolid ?? this.strokePositiveSolid,
      strokeWarningSolid: strokeWarningSolid ?? this.strokeWarningSolid,
      strokeInformativeSolid:
          strokeInformativeSolid ?? this.strokeInformativeSolid,
      strokeCriticalWeak: strokeCriticalWeak ?? this.strokeCriticalWeak,
      strokePositiveWeak: strokePositiveWeak ?? this.strokePositiveWeak,
      strokeWarningWeak: strokeWarningWeak ?? this.strokeWarningWeak,
      strokeInformativeWeak:
          strokeInformativeWeak ?? this.strokeInformativeWeak,
      overlayDim: overlayDim ?? this.overlayDim,
    );
  }

  @override
  PColors lerp(ThemeExtension<PColors>? other, double t) {
    if (other is! PColors) return this;
    return PColors(
      brand100: Color.lerp(brand100, other.brand100, t)!,
      brand200: Color.lerp(brand200, other.brand200, t)!,
      brand300: Color.lerp(brand300, other.brand300, t)!,
      brand400: Color.lerp(brand400, other.brand400, t)!,
      brand500: Color.lerp(brand500, other.brand500, t)!,
      brand600: Color.lerp(brand600, other.brand600, t)!,
      brand700: Color.lerp(brand700, other.brand700, t)!,
      brand800: Color.lerp(brand800, other.brand800, t)!,
      brand900: Color.lerp(brand900, other.brand900, t)!,
      brand1000: Color.lerp(brand1000, other.brand1000, t)!,
      gray00: Color.lerp(gray00, other.gray00, t)!,
      gray100: Color.lerp(gray100, other.gray100, t)!,
      gray200: Color.lerp(gray200, other.gray200, t)!,
      gray300: Color.lerp(gray300, other.gray300, t)!,
      gray400: Color.lerp(gray400, other.gray400, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      gray600: Color.lerp(gray600, other.gray600, t)!,
      gray700: Color.lerp(gray700, other.gray700, t)!,
      gray800: Color.lerp(gray800, other.gray800, t)!,
      gray900: Color.lerp(gray900, other.gray900, t)!,
      gray1000: Color.lerp(gray1000, other.gray1000, t)!,
      red100: Color.lerp(red100, other.red100, t)!,
      red200: Color.lerp(red200, other.red200, t)!,
      red300: Color.lerp(red300, other.red300, t)!,
      red400: Color.lerp(red400, other.red400, t)!,
      red500: Color.lerp(red500, other.red500, t)!,
      red600: Color.lerp(red600, other.red600, t)!,
      red700: Color.lerp(red700, other.red700, t)!,
      red800: Color.lerp(red800, other.red800, t)!,
      red900: Color.lerp(red900, other.red900, t)!,
      red1000: Color.lerp(red1000, other.red1000, t)!,
      green100: Color.lerp(green100, other.green100, t)!,
      green200: Color.lerp(green200, other.green200, t)!,
      green300: Color.lerp(green300, other.green300, t)!,
      green400: Color.lerp(green400, other.green400, t)!,
      green500: Color.lerp(green500, other.green500, t)!,
      green600: Color.lerp(green600, other.green600, t)!,
      green700: Color.lerp(green700, other.green700, t)!,
      green800: Color.lerp(green800, other.green800, t)!,
      green900: Color.lerp(green900, other.green900, t)!,
      green1000: Color.lerp(green1000, other.green1000, t)!,
      orange100: Color.lerp(orange100, other.orange100, t)!,
      orange200: Color.lerp(orange200, other.orange200, t)!,
      orange300: Color.lerp(orange300, other.orange300, t)!,
      orange400: Color.lerp(orange400, other.orange400, t)!,
      orange500: Color.lerp(orange500, other.orange500, t)!,
      orange600: Color.lerp(orange600, other.orange600, t)!,
      orange700: Color.lerp(orange700, other.orange700, t)!,
      orange800: Color.lerp(orange800, other.orange800, t)!,
      orange900: Color.lerp(orange900, other.orange900, t)!,
      orange1000: Color.lerp(orange1000, other.orange1000, t)!,
      blue100: Color.lerp(blue100, other.blue100, t)!,
      blue200: Color.lerp(blue200, other.blue200, t)!,
      blue300: Color.lerp(blue300, other.blue300, t)!,
      blue400: Color.lerp(blue400, other.blue400, t)!,
      blue500: Color.lerp(blue500, other.blue500, t)!,
      blue600: Color.lerp(blue600, other.blue600, t)!,
      blue700: Color.lerp(blue700, other.blue700, t)!,
      blue800: Color.lerp(blue800, other.blue800, t)!,
      blue900: Color.lerp(blue900, other.blue900, t)!,
      blue1000: Color.lerp(blue1000, other.blue1000, t)!,
      yellow100: Color.lerp(yellow100, other.yellow100, t)!,
      yellow200: Color.lerp(yellow200, other.yellow200, t)!,
      yellow300: Color.lerp(yellow300, other.yellow300, t)!,
      yellow400: Color.lerp(yellow400, other.yellow400, t)!,
      yellow500: Color.lerp(yellow500, other.yellow500, t)!,
      yellow600: Color.lerp(yellow600, other.yellow600, t)!,
      yellow700: Color.lerp(yellow700, other.yellow700, t)!,
      yellow800: Color.lerp(yellow800, other.yellow800, t)!,
      yellow900: Color.lerp(yellow900, other.yellow900, t)!,
      yellow1000: Color.lerp(yellow1000, other.yellow1000, t)!,
      indigo100: Color.lerp(indigo100, other.indigo100, t)!,
      indigo200: Color.lerp(indigo200, other.indigo200, t)!,
      indigo300: Color.lerp(indigo300, other.indigo300, t)!,
      indigo400: Color.lerp(indigo400, other.indigo400, t)!,
      indigo500: Color.lerp(indigo500, other.indigo500, t)!,
      indigo600: Color.lerp(indigo600, other.indigo600, t)!,
      indigo700: Color.lerp(indigo700, other.indigo700, t)!,
      indigo800: Color.lerp(indigo800, other.indigo800, t)!,
      indigo900: Color.lerp(indigo900, other.indigo900, t)!,
      indigo1000: Color.lerp(indigo1000, other.indigo1000, t)!,
      violet100: Color.lerp(violet100, other.violet100, t)!,
      violet200: Color.lerp(violet200, other.violet200, t)!,
      violet300: Color.lerp(violet300, other.violet300, t)!,
      violet400: Color.lerp(violet400, other.violet400, t)!,
      violet500: Color.lerp(violet500, other.violet500, t)!,
      violet600: Color.lerp(violet600, other.violet600, t)!,
      violet700: Color.lerp(violet700, other.violet700, t)!,
      violet800: Color.lerp(violet800, other.violet800, t)!,
      violet900: Color.lerp(violet900, other.violet900, t)!,
      violet1000: Color.lerp(violet1000, other.violet1000, t)!,
      pink100: Color.lerp(pink100, other.pink100, t)!,
      pink200: Color.lerp(pink200, other.pink200, t)!,
      pink300: Color.lerp(pink300, other.pink300, t)!,
      pink400: Color.lerp(pink400, other.pink400, t)!,
      pink500: Color.lerp(pink500, other.pink500, t)!,
      pink600: Color.lerp(pink600, other.pink600, t)!,
      pink700: Color.lerp(pink700, other.pink700, t)!,
      pink800: Color.lerp(pink800, other.pink800, t)!,
      pink900: Color.lerp(pink900, other.pink900, t)!,
      pink1000: Color.lerp(pink1000, other.pink1000, t)!,
      brown100: Color.lerp(brown100, other.brown100, t)!,
      brown200: Color.lerp(brown200, other.brown200, t)!,
      brown300: Color.lerp(brown300, other.brown300, t)!,
      brown400: Color.lerp(brown400, other.brown400, t)!,
      brown500: Color.lerp(brown500, other.brown500, t)!,
      brown600: Color.lerp(brown600, other.brown600, t)!,
      brown700: Color.lerp(brown700, other.brown700, t)!,
      brown800: Color.lerp(brown800, other.brown800, t)!,
      brown900: Color.lerp(brown900, other.brown900, t)!,
      brown1000: Color.lerp(brown1000, other.brown1000, t)!,
      chartRed: Color.lerp(chartRed, other.chartRed, t)!,
      chartOrange: Color.lerp(chartOrange, other.chartOrange, t)!,
      chartYellow: Color.lerp(chartYellow, other.chartYellow, t)!,
      chartGreen: Color.lerp(chartGreen, other.chartGreen, t)!,
      chartBlue: Color.lerp(chartBlue, other.chartBlue, t)!,
      chartIndigo: Color.lerp(chartIndigo, other.chartIndigo, t)!,
      chartViolet: Color.lerp(chartViolet, other.chartViolet, t)!,
      chartPink: Color.lerp(chartPink, other.chartPink, t)!,
      chartBrown: Color.lerp(chartBrown, other.chartBrown, t)!,
      chartGray: Color.lerp(chartGray, other.chartGray, t)!,
      chartRedWeak: Color.lerp(chartRedWeak, other.chartRedWeak, t)!,
      chartRedSubtle: Color.lerp(chartRedSubtle, other.chartRedSubtle, t)!,
      chartRedContrast: Color.lerp(
        chartRedContrast,
        other.chartRedContrast,
        t,
      )!,
      chartOrangeWeak: Color.lerp(chartOrangeWeak, other.chartOrangeWeak, t)!,
      chartOrangeSubtle: Color.lerp(
        chartOrangeSubtle,
        other.chartOrangeSubtle,
        t,
      )!,
      chartOrangeContrast: Color.lerp(
        chartOrangeContrast,
        other.chartOrangeContrast,
        t,
      )!,
      chartYellowWeak: Color.lerp(chartYellowWeak, other.chartYellowWeak, t)!,
      chartYellowSubtle: Color.lerp(
        chartYellowSubtle,
        other.chartYellowSubtle,
        t,
      )!,
      chartYellowContrast: Color.lerp(
        chartYellowContrast,
        other.chartYellowContrast,
        t,
      )!,
      chartGreenWeak: Color.lerp(chartGreenWeak, other.chartGreenWeak, t)!,
      chartGreenSubtle: Color.lerp(
        chartGreenSubtle,
        other.chartGreenSubtle,
        t,
      )!,
      chartGreenContrast: Color.lerp(
        chartGreenContrast,
        other.chartGreenContrast,
        t,
      )!,
      chartBlueWeak: Color.lerp(chartBlueWeak, other.chartBlueWeak, t)!,
      chartBlueSubtle: Color.lerp(chartBlueSubtle, other.chartBlueSubtle, t)!,
      chartBlueContrast: Color.lerp(
        chartBlueContrast,
        other.chartBlueContrast,
        t,
      )!,
      chartIndigoWeak: Color.lerp(chartIndigoWeak, other.chartIndigoWeak, t)!,
      chartIndigoSubtle: Color.lerp(
        chartIndigoSubtle,
        other.chartIndigoSubtle,
        t,
      )!,
      chartIndigoContrast: Color.lerp(
        chartIndigoContrast,
        other.chartIndigoContrast,
        t,
      )!,
      chartVioletWeak: Color.lerp(chartVioletWeak, other.chartVioletWeak, t)!,
      chartVioletSubtle: Color.lerp(
        chartVioletSubtle,
        other.chartVioletSubtle,
        t,
      )!,
      chartVioletContrast: Color.lerp(
        chartVioletContrast,
        other.chartVioletContrast,
        t,
      )!,
      chartPinkWeak: Color.lerp(chartPinkWeak, other.chartPinkWeak, t)!,
      chartPinkSubtle: Color.lerp(chartPinkSubtle, other.chartPinkSubtle, t)!,
      chartPinkContrast: Color.lerp(
        chartPinkContrast,
        other.chartPinkContrast,
        t,
      )!,
      chartBrownWeak: Color.lerp(chartBrownWeak, other.chartBrownWeak, t)!,
      chartBrownSubtle: Color.lerp(
        chartBrownSubtle,
        other.chartBrownSubtle,
        t,
      )!,
      chartBrownContrast: Color.lerp(
        chartBrownContrast,
        other.chartBrownContrast,
        t,
      )!,
      chartGrayWeak: Color.lerp(chartGrayWeak, other.chartGrayWeak, t)!,
      chartGraySubtle: Color.lerp(chartGraySubtle, other.chartGraySubtle, t)!,
      chartGrayContrast: Color.lerp(
        chartGrayContrast,
        other.chartGrayContrast,
        t,
      )!,
      fgBrand: Color.lerp(fgBrand, other.fgBrand, t)!,
      fgBrandContrast: Color.lerp(fgBrandContrast, other.fgBrandContrast, t)!,
      fgBrandInverted: Color.lerp(fgBrandInverted, other.fgBrandInverted, t)!,
      bgBrandSolid: Color.lerp(bgBrandSolid, other.bgBrandSolid, t)!,
      bgBrandSolidPressed: Color.lerp(
        bgBrandSolidPressed,
        other.bgBrandSolidPressed,
        t,
      )!,
      bgBrandWeak: Color.lerp(bgBrandWeak, other.bgBrandWeak, t)!,
      bgBrandWeakPressed: Color.lerp(
        bgBrandWeakPressed,
        other.bgBrandWeakPressed,
        t,
      )!,
      strokeFocusRing: Color.lerp(strokeFocusRing, other.strokeFocusRing, t)!,
      strokeBrandSolid: Color.lerp(
        strokeBrandSolid,
        other.strokeBrandSolid,
        t,
      )!,
      strokeBrandWeak: Color.lerp(strokeBrandWeak, other.strokeBrandWeak, t)!,
      fgNeutral: Color.lerp(fgNeutral, other.fgNeutral, t)!,
      fgNeutralMuted: Color.lerp(fgNeutralMuted, other.fgNeutralMuted, t)!,
      fgNeutralSubtle: Color.lerp(fgNeutralSubtle, other.fgNeutralSubtle, t)!,
      fgNeutralInverted: Color.lerp(
        fgNeutralInverted,
        other.fgNeutralInverted,
        t,
      )!,
      fgPlaceholder: Color.lerp(fgPlaceholder, other.fgPlaceholder, t)!,
      fgDisabled: Color.lerp(fgDisabled, other.fgDisabled, t)!,
      staticWhite: Color.lerp(staticWhite, other.staticWhite, t)!,
      fgCritical: Color.lerp(fgCritical, other.fgCritical, t)!,
      fgPositive: Color.lerp(fgPositive, other.fgPositive, t)!,
      fgWarning: Color.lerp(fgWarning, other.fgWarning, t)!,
      fgInformative: Color.lerp(fgInformative, other.fgInformative, t)!,
      fgCriticalContrast: Color.lerp(
        fgCriticalContrast,
        other.fgCriticalContrast,
        t,
      )!,
      fgPositiveContrast: Color.lerp(
        fgPositiveContrast,
        other.fgPositiveContrast,
        t,
      )!,
      fgWarningContrast: Color.lerp(
        fgWarningContrast,
        other.fgWarningContrast,
        t,
      )!,
      fgInformativeContrast: Color.lerp(
        fgInformativeContrast,
        other.fgInformativeContrast,
        t,
      )!,
      fgPositiveInverted: Color.lerp(
        fgPositiveInverted,
        other.fgPositiveInverted,
        t,
      )!,
      fgCriticalInverted: Color.lerp(
        fgCriticalInverted,
        other.fgCriticalInverted,
        t,
      )!,
      bgLayerBasement: Color.lerp(bgLayerBasement, other.bgLayerBasement, t)!,
      bgLayerDefault: Color.lerp(bgLayerDefault, other.bgLayerDefault, t)!,
      bgLayerDefaultPressed: Color.lerp(
        bgLayerDefaultPressed,
        other.bgLayerDefaultPressed,
        t,
      )!,
      bgLayerFloating: Color.lerp(bgLayerFloating, other.bgLayerFloating, t)!,
      bgLayerFloatingPressed: Color.lerp(
        bgLayerFloatingPressed,
        other.bgLayerFloatingPressed,
        t,
      )!,
      bgNeutralWeak: Color.lerp(bgNeutralWeak, other.bgNeutralWeak, t)!,
      bgNeutralWeakPressed: Color.lerp(
        bgNeutralWeakPressed,
        other.bgNeutralWeakPressed,
        t,
      )!,
      bgNeutralWeakAlpha: Color.lerp(
        bgNeutralWeakAlpha,
        other.bgNeutralWeakAlpha,
        t,
      )!,
      bgNeutralWeakAlphaPressed: Color.lerp(
        bgNeutralWeakAlphaPressed,
        other.bgNeutralWeakAlphaPressed,
        t,
      )!,
      bgNeutralInverted: Color.lerp(
        bgNeutralInverted,
        other.bgNeutralInverted,
        t,
      )!,
      bgNeutralInvertedPressed: Color.lerp(
        bgNeutralInvertedPressed,
        other.bgNeutralInvertedPressed,
        t,
      )!,
      bgDisabled: Color.lerp(bgDisabled, other.bgDisabled, t)!,
      bgCriticalSolid: Color.lerp(bgCriticalSolid, other.bgCriticalSolid, t)!,
      bgCriticalSolidPressed: Color.lerp(
        bgCriticalSolidPressed,
        other.bgCriticalSolidPressed,
        t,
      )!,
      bgCriticalWeak: Color.lerp(bgCriticalWeak, other.bgCriticalWeak, t)!,
      bgCriticalWeakPressed: Color.lerp(
        bgCriticalWeakPressed,
        other.bgCriticalWeakPressed,
        t,
      )!,
      bgPositiveSolid: Color.lerp(bgPositiveSolid, other.bgPositiveSolid, t)!,
      bgPositiveSolidPressed: Color.lerp(
        bgPositiveSolidPressed,
        other.bgPositiveSolidPressed,
        t,
      )!,
      bgPositiveWeak: Color.lerp(bgPositiveWeak, other.bgPositiveWeak, t)!,
      bgPositiveWeakPressed: Color.lerp(
        bgPositiveWeakPressed,
        other.bgPositiveWeakPressed,
        t,
      )!,
      bgWarningSolid: Color.lerp(bgWarningSolid, other.bgWarningSolid, t)!,
      bgWarningSolidPressed: Color.lerp(
        bgWarningSolidPressed,
        other.bgWarningSolidPressed,
        t,
      )!,
      bgWarningWeak: Color.lerp(bgWarningWeak, other.bgWarningWeak, t)!,
      bgWarningWeakPressed: Color.lerp(
        bgWarningWeakPressed,
        other.bgWarningWeakPressed,
        t,
      )!,
      bgInformativeSolid: Color.lerp(
        bgInformativeSolid,
        other.bgInformativeSolid,
        t,
      )!,
      bgInformativeSolidPressed: Color.lerp(
        bgInformativeSolidPressed,
        other.bgInformativeSolidPressed,
        t,
      )!,
      bgInformativeWeak: Color.lerp(
        bgInformativeWeak,
        other.bgInformativeWeak,
        t,
      )!,
      bgInformativeWeakPressed: Color.lerp(
        bgInformativeWeakPressed,
        other.bgInformativeWeakPressed,
        t,
      )!,
      strokeNeutralSubtle: Color.lerp(
        strokeNeutralSubtle,
        other.strokeNeutralSubtle,
        t,
      )!,
      strokeNeutralWeak: Color.lerp(
        strokeNeutralWeak,
        other.strokeNeutralWeak,
        t,
      )!,
      strokeNeutralSolid: Color.lerp(
        strokeNeutralSolid,
        other.strokeNeutralSolid,
        t,
      )!,
      strokeNeutralContrast: Color.lerp(
        strokeNeutralContrast,
        other.strokeNeutralContrast,
        t,
      )!,
      strokeNeutralOverlay: Color.lerp(
        strokeNeutralOverlay,
        other.strokeNeutralOverlay,
        t,
      )!,
      strokeCriticalSolid: Color.lerp(
        strokeCriticalSolid,
        other.strokeCriticalSolid,
        t,
      )!,
      strokePositiveSolid: Color.lerp(
        strokePositiveSolid,
        other.strokePositiveSolid,
        t,
      )!,
      strokeWarningSolid: Color.lerp(
        strokeWarningSolid,
        other.strokeWarningSolid,
        t,
      )!,
      strokeInformativeSolid: Color.lerp(
        strokeInformativeSolid,
        other.strokeInformativeSolid,
        t,
      )!,
      strokeCriticalWeak: Color.lerp(
        strokeCriticalWeak,
        other.strokeCriticalWeak,
        t,
      )!,
      strokePositiveWeak: Color.lerp(
        strokePositiveWeak,
        other.strokePositiveWeak,
        t,
      )!,
      strokeWarningWeak: Color.lerp(
        strokeWarningWeak,
        other.strokeWarningWeak,
        t,
      )!,
      strokeInformativeWeak: Color.lerp(
        strokeInformativeWeak,
        other.strokeInformativeWeak,
        t,
      )!,
      overlayDim: Color.lerp(overlayDim, other.overlayDim, t)!,
    );
  }
}

/// 그림자 s1 ~ s4, 라이트 · 다크(DESIGN.md v104 고도). 다크의 inset 하이라이트는 BlurStyle.inner 로 옮겼다.
/// `context.shadows.s3`
@immutable
class PShadows extends ThemeExtension<PShadows> {
  const PShadows({
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
  });

  /// shadow-s1
  final List<BoxShadow> s1;

  /// shadow-s2
  final List<BoxShadow> s2;

  /// shadow-s3
  final List<BoxShadow> s3;

  /// shadow-s4
  final List<BoxShadow> s4;

  static const PShadows light = PShadows(
    s1: [
      BoxShadow(color: Color(0x0D0F121C), offset: Offset(0, 1), blurRadius: 2),
    ],
    s2: [
      BoxShadow(
        color: Color(0x140F121C),
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Color(0x0A0F121C),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: -1,
      ),
    ],
    s3: [
      BoxShadow(
        color: Color(0x1A0F121C),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color(0x0D0F121C),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: -2,
      ),
    ],
    s4: [
      BoxShadow(
        color: Color(0x290F121C),
        offset: Offset(0, 24),
        blurRadius: 48,
        spreadRadius: -8,
      ),
      BoxShadow(
        color: Color(0x140F121C),
        offset: Offset(0, 8),
        blurRadius: 16,
        spreadRadius: -4,
      ),
    ],
  );

  static const PShadows dark = PShadows(
    s1: [
      BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(
        color: Color(0x0DFFFFFF),
        offset: Offset(0, 1),
        blurStyle: BlurStyle.inner,
      ),
    ],
    s2: [
      BoxShadow(
        color: Color(0x66000000),
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Color(0x33000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Color(0x0FFFFFFF),
        offset: Offset(0, 1),
        blurStyle: BlurStyle.inner,
      ),
    ],
    s3: [
      BoxShadow(
        color: Color(0x80000000),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color(0x40000000),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Color(0x14FFFFFF),
        offset: Offset(0, 1),
        blurStyle: BlurStyle.inner,
      ),
    ],
    s4: [
      BoxShadow(
        color: Color(0x99000000),
        offset: Offset(0, 24),
        blurRadius: 48,
        spreadRadius: -8,
      ),
      BoxShadow(
        color: Color(0x4D000000),
        offset: Offset(0, 8),
        blurRadius: 16,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color(0x1AFFFFFF),
        offset: Offset(0, 1),
        blurStyle: BlurStyle.inner,
      ),
    ],
  );

  @override
  PShadows copyWith({
    List<BoxShadow>? s1,
    List<BoxShadow>? s2,
    List<BoxShadow>? s3,
    List<BoxShadow>? s4,
  }) {
    return PShadows(
      s1: s1 ?? this.s1,
      s2: s2 ?? this.s2,
      s3: s3 ?? this.s3,
      s4: s4 ?? this.s4,
    );
  }

  @override
  PShadows lerp(ThemeExtension<PShadows>? other, double t) {
    if (other is! PShadows) return this;
    return PShadows(
      s1: BoxShadow.lerpList(s1, other.s1, t) ?? s1,
      s2: BoxShadow.lerpList(s2, other.s2, t) ?? s2,
      s3: BoxShadow.lerpList(s3, other.s3, t) ?? s3,
      s4: BoxShadow.lerpList(s4, other.s4, t) ?? s4,
    );
  }
}

/// 그라디언트 — 가림 마스크 · 스켈레톤 반짝임, 라이트 · 다크(DESIGN.md v104).
/// 마스크(fadeMask)는 위 → 아래로 적었다 — 쓰는 자리에서 begin · end 만 바꿔 방향을 붙인다(색 · 비율은 그대로).
/// `context.gradients.shimmerNeutral`
@immutable
class PGradients extends ThemeExtension<PGradients> {
  const PGradients({required this.fadeMask, required this.shimmerNeutral});

  /// gradient-fade-mask
  final LinearGradient fadeMask;

  /// gradient-shimmer-neutral
  final LinearGradient shimmerNeutral;

  static const PGradients light = PGradients(
    fadeMask: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x00000000),
        Color(0x03000000),
        Color(0x05000000),
        Color(0x0D000000),
        Color(0x14000000),
        Color(0x21000000),
        Color(0x2E000000),
        Color(0x40000000),
        Color(0x52000000),
        Color(0x66000000),
        Color(0x7A000000),
        Color(0x94000000),
        Color(0xAB000000),
        Color(0xC7000000),
        Color(0xE3000000),
        Color(0xFF000000),
      ],
      stops: [
        0,
        0.08,
        0.16,
        0.22,
        0.29,
        0.35,
        0.41,
        0.47,
        0.53,
        0.59,
        0.65,
        0.71,
        0.78,
        0.84,
        0.92,
        1,
      ],
    ),
    shimmerNeutral: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0x00FFFFFF),
        Color(0xABFFFFFF),
        Color(0xABFFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: [0, 0.46, 0.54, 1],
    ),
  );

  static const PGradients dark = PGradients(
    fadeMask: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x00000000),
        Color(0x03000000),
        Color(0x05000000),
        Color(0x0D000000),
        Color(0x14000000),
        Color(0x21000000),
        Color(0x2E000000),
        Color(0x40000000),
        Color(0x52000000),
        Color(0x66000000),
        Color(0x7A000000),
        Color(0x94000000),
        Color(0xAB000000),
        Color(0xC7000000),
        Color(0xE3000000),
        Color(0xFF000000),
      ],
      stops: [
        0,
        0.08,
        0.16,
        0.22,
        0.29,
        0.35,
        0.41,
        0.47,
        0.53,
        0.59,
        0.65,
        0.71,
        0.78,
        0.84,
        0.92,
        1,
      ],
    ),
    shimmerNeutral: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0x00FFFFFF),
        Color(0x1AFFFFFF),
        Color(0x1AFFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: [0, 0.46, 0.54, 1],
    ),
  );

  @override
  PGradients copyWith({
    LinearGradient? fadeMask,
    LinearGradient? shimmerNeutral,
  }) {
    return PGradients(
      fadeMask: fadeMask ?? this.fadeMask,
      shimmerNeutral: shimmerNeutral ?? this.shimmerNeutral,
    );
  }

  @override
  PGradients lerp(ThemeExtension<PGradients>? other, double t) {
    if (other is! PGradients) return this;
    return PGradients(
      fadeMask: LinearGradient.lerp(fadeMask, other.fadeMask, t)!,
      shimmerNeutral: LinearGradient.lerp(
        shimmerNeutral,
        other.shimmerNeutral,
        t,
      )!,
    );
  }
}

/// 컨텍스트에서 꺼내는 짧은 이름.
extension PDesignTokensContext on BuildContext {
  PColors get colors => Theme.of(this).extension<PColors>()!;
  PShadows get shadows => Theme.of(this).extension<PShadows>()!;
  PGradients get gradients => Theme.of(this).extension<PGradients>()!;
}
