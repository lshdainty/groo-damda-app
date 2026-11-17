import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/colors.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_side_gutter.dart';

/// 그루 담다 모바일 앱의 light/dark ThemeData 빌더.
///
/// Material 3 베이스 위에 [GrooTokens] 를 [ThemeExtension] 으로 얹어 두 채널 사용:
/// - 표준 Material 위젯 (Buttons, AppBar 등) → ColorScheme + Material 톤
/// - 그루 커스텀 위젯 → `context.tokens.bgCanvas` 류
///
/// groo-design 이 만든 역할 색 · 그림자 · 그라디언트([PColors] · [PShadows] · [PGradients], `groo_tokens.g.dart`)도 같이
/// 얹는다 — 새 컴포넌트 라이브러리(`lib/shared/ds`)는 `context.colors.fgNeutral` 처럼 이것만 쓴다.
abstract final class GrooTheme {
  /// 늘 같은 ThemeData 를 돌려준다(처음 부를 때 한 번 만든다). 부를 때마다 새로 만들면 값이 같아도 다른 테마로 보여,
  /// MaterialApp 이 다시 그려질 때마다(설정 · 언어 바꿈 등) 같은 테마끼리 200ms 섞고(AnimatedTheme) 그동안 테마를
  /// 읽는 위젯이 매 프레임 다시 그려진다 — 목표 색을 견주는 색 전환은 멈춘 듯 보였다. 테마를 고쳤으면 hot reload 가
  /// 아니라 hot restart 로 본다.
  static ThemeData light() => _light;

  static ThemeData dark() => _dark;

  static final ThemeData _light = _build(
    brightness: Brightness.light,
    tokens: GrooTokens.light,
    colors: PColors.light,
    shadows: PShadows.light,
    gradients: PGradients.light,
    seed: GrooPalette.cobalt500,
  );

  static final ThemeData _dark = _build(
    brightness: Brightness.dark,
    tokens: GrooTokens.dark,
    colors: PColors.dark,
    shadows: PShadows.dark,
    gradients: PGradients.dark,
    seed: GrooPalette.cobalt400,
  );

  static ThemeData _build({
    required Brightness brightness,
    required GrooTokens tokens,
    required PColors colors,
    required PShadows shadows,
    required PGradients gradients,
    required Color seed,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: tokens.fgBrand,
      onPrimary: tokens.fgOnBrand,
      surface: tokens.bgSurface,
      onSurface: tokens.fgPrimary,
      surfaceContainer: tokens.bgMuted,
      surfaceContainerHigh: tokens.bgSurfaceRaised,
      surfaceContainerLow: tokens.bgCanvas,
      surfaceContainerLowest: tokens.bgCanvas,
      surfaceContainerHighest: tokens.bgSurfaceRaised,
      error: tokens.statusDanger,
      onError: tokens.fgOnDanger,
      outline: tokens.borderDefault,
      outlineVariant: tokens.borderSubtle,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.bgSurface,
      canvasColor: tokens.bgSurface,
      dividerColor: tokens.borderSubtle,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      extensions: [tokens, colors, shadows, gradients],
      // 화면 라우트는 모두 좌우 안전 영역 칸 안에 선다 — 그 칸은 뒷배경만(groo-design Layout "Safe Area")
      pageTransitionsTheme: kSideGutterPageTransitionsTheme,
      // 스크롤바 — 전역 한 벌(groo-design scroll-area.yaml). 막대는 `stroke-neutral-solid` 6px 알약, 바탕은 투명이고
      // 올리거나 끌어도 모양이 바뀌지 않는다. 앱은 스크롤할 때만 보이는 플랫폼 스크롤바를 둔다(웹은 넘치면 늘 보인다).
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.strokeNeutralSolid),
        trackColor: const WidgetStatePropertyAll(Color(0x00000000)),
        trackBorderColor: const WidgetStatePropertyAll(Color(0x00000000)),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(PRounded.full),
        thumbVisibility: const WidgetStatePropertyAll(false),
        trackVisibility: const WidgetStatePropertyAll(false),
      ),
      textTheme: _textTheme(tokens.fgPrimary, tokens.fgSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgSurface,
        foregroundColor: tokens.fgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: PTypo.h4.copyWith(color: tokens.fgPrimary),
      ),
      cardTheme: CardThemeData(
        color: tokens.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: PRadius.brLg),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PRadius.xl2),
          ),
        ),
        modalBackgroundColor: tokens.bgSurface,
        // 딤 — 라이트 0.50 · 다크 0.65(v43 overlay-dim). Colors.black54 는 두 모드 0.54 라 쓰지 않는다(01A-053)
        modalBarrierColor: colors.overlayDim,
      ),
      dialogTheme: DialogThemeData(
        barrierColor: colors.overlayDim,
        backgroundColor: tokens.bgSurface,
        surfaceTintColor: Colors.transparent,
        // specs/components/dialog.md: popup 은 세 사이즈 모두 radius-lg(12).
        // 시트/드로어(20)와 갈라 둔다 — popup 은 가운데 좁게 떠서 20 이 과하고,
        // 안에 놓이는 버튼이 radius-md(8)라 12 가 맞물린다.
        shape: RoundedRectangleBorder(borderRadius: PRadius.brLg),
        // dialog.md/alert-dialog.md SoT: title-md(18/600). 기본 titleLarge(h3 20) 대신 명시.
        titleTextStyle: PTypo.h4.copyWith(color: tokens.fgPrimary),
      ),
      // specs/components/input.md spec:
      // height 40 (minimumSize 외부에서) / radius-sm(4) / padding sm·md (8·12)
      // bg surface-input / border-default / border-focus(1.5)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.bgMuted,
        hintStyle: PTypo.bodyLg.copyWith(color: tokens.fgPlaceholder),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PSpace.md,
          vertical: PSpace.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.statusDangerBorder),
        ),
      ),
      // specs/components/button.md spec — md(default):
      // h=40 / padding y·x (8·12) / font body-md(15) weight-medium(500) / radius-sm(4)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 채운 버튼은 solid 고정 — 다크에서도 primary (bgBrand 는 light 라 부적합)
          backgroundColor: tokens.bgBrandSolid,
          foregroundColor: tokens.fgOnBrand,
          disabledBackgroundColor: tokens.bgDisabled,
          disabledForegroundColor: tokens.fgDisabled,
          shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.md,
            vertical: PSpace.sm,
          ),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.bodyMd,
            fontWeight: PFontWeight.medium,
            height: 1.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.fgBrand,
          shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.md,
            vertical: PSpace.sm,
          ),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.bodyMd,
            fontWeight: PFontWeight.medium,
            height: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.fgPrimary,
          side: BorderSide(color: tokens.borderDefault),
          shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.md,
            vertical: PSpace.sm,
          ),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.bodyMd,
            fontWeight: PFontWeight.medium,
            height: 1.0,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.fgBrand,
        circularTrackColor: tokens.bgBrandMuted,
        linearTrackColor: tokens.bgBrandMuted,
        strokeWidth: 2,
      ),
      // specs/components/checkbox.md spec — md(default):
      // 18×18 / border-strong 1px / radius-sm / checked = bgBrandSolid fill + fgOnBrand check
      // (흰 체크를 얹는 채움이라 채움 역할 — bgBrand 는 다크에서 밝은 글자 색이다. 웹 checkbox 와 같다)
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.bgDisabled;
          if (states.contains(WidgetState.selected)) return tokens.bgBrandSolid;
          return tokens.bgSurface;
        }),
        checkColor: WidgetStateProperty.all(tokens.fgOnBrand),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return BorderSide.none;
          return BorderSide(color: tokens.borderStrong, width: 1);
        }),
        shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // specs/components/switch.md — track + thumb, brand 채움(흰 손잡이를 얹으니 채움 역할)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.fgDisabled;
          return tokens.fgOnBrand;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.bgDisabled;
          if (states.contains(WidgetState.selected)) return tokens.bgBrandSolid;
          return tokens.bgTrack;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // Radio (사용처 적지만 일관 스타일)
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.fgDisabled;
          if (states.contains(WidgetState.selected)) return tokens.fgBrand;
          return tokens.borderStrong;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      iconTheme: IconThemeData(color: tokens.fgSecondary, size: 20),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.bgSurface,
        indicatorColor: tokens.bgBrandSubtle,
        labelTextStyle: WidgetStatePropertyAll(
          PTypo.micro.copyWith(color: tokens.fgSecondary),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: tokens.fgSecondary, size: 22),
        ),
        height: 72,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    TextStyle p(TextStyle s) => s.copyWith(color: primary);
    TextStyle s(TextStyle st) => st.copyWith(color: secondary);
    return TextTheme(
      displayLarge: p(PTypo.displayLg),
      displayMedium: p(PTypo.displayMd),
      displaySmall: p(PTypo.h1),
      headlineLarge: p(PTypo.h1),
      headlineMedium: p(PTypo.h2),
      headlineSmall: p(PTypo.h3),
      titleLarge: p(PTypo.h3),
      titleMedium: p(PTypo.h4),
      titleSmall: p(PTypo.bodyLg.copyWith(fontWeight: FontWeight.w600)),
      bodyLarge: p(PTypo.bodyLg),
      bodyMedium: p(PTypo.body),
      bodySmall: s(PTypo.bodySm),
      labelLarge: p(PTypo.body.copyWith(fontWeight: FontWeight.w600)),
      labelMedium: s(PTypo.caption),
      labelSmall: s(PTypo.micro),
    );
  }
}
