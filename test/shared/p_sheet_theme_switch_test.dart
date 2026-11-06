// 시트를 연 채 다크로 바뀌어도 배경이 따라 바뀐다(2026-09-22 iOS 시뮬레이터).
//
// showPSheet 가 `backgroundColor: context.tokens.bgSurface` 를 넘기던 동안 **여는 순간의
// 색**이 박혔다. iOS 자동 다크 전환 시각에 시트를 보고 있으면 배경은 흰색 그대로인데
// 글자만 밝은색으로 바뀌어 거의 안 보였다. 시트를 닫았다 열어야 풀렸다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import '../support/plain_text.dart';

void main() {
  final light = GrooTheme.light().extension<GrooTokens>()!;
  final dark = GrooTheme.dark().extension<GrooTokens>()!;

  for (final shrinkWrap in [false, true]) {
    testWidgets('shrinkWrap=$shrinkWrap — 시트를 연 채 다크로 바뀌면 배경도 다크다', (
      tester,
    ) async {
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: mode,
          builder: (_, m, _) => MaterialApp(
            theme: GrooTheme.light(),
            darkTheme: GrooTheme.dark(),
            themeMode: m,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showPSheet<void>(
                    ctx,
                    title: '시트',
                    shrinkWrap: shrinkWrap,
                    contentBuilder: (c, _) => const SizedBox(height: 120),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();

      Color sheetColor() => tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(BottomSheet),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      expect(sheetColor(), light.bgSurface);

      mode.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(
        sheetColor(),
        dark.bgSurface,
        reason: '배경이 여는 순간의 흰색으로 남으면 밝은 글자가 안 보인다',
      );
    });
  }
}
