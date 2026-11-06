// 컴포넌트 카탈로그(/dev/ds)가 그려지는지 본다 — debug 빌드에서만 길이 있어 다른 테스트가
// 이 화면을 지나지 않는다. 컴포넌트를 만들 때마다 demo 가 여기 붙으므로, 깨진 demo 도 여기서 걸린다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/catalog/ds_catalog_screen.dart';
import 'package:groo_damda_app/shared/ds/catalog/ds_registry.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('앱 카탈로그는 58개를 싣고 라이트 · 다크 판을 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: GrooTheme.light(), home: const DsCatalogScreen()),
    );

    final entries = dsFamilies.expand((f) => f.entries).toList();
    // 웹에서 Dialog · Menu · Popover(1280 이상 전용)와 Table · Table Pagination · Pagination · Side Navigation(768 이상 전용)을 뺀 47개 + Infinite List(폰 전용) 1개 + 입력 묶음 6개 + 펼치고 접기 · 나누기 묶음 4개(Tree View · Resizable 은 HR 전용) = 58개
    expect(entries, hasLength(58));
    expect(
      entries.map((e) => e.spec),
      isNot(anyOf(contains('dialog'), contains('menu'), contains('popover'))),
    );

    final built = entries.where((e) => e.demo != null).length;
    expect(findTextContaining('확정 스펙 58개 중 $built개'), findsOneWidget);
    expect(findTextContaining(PDesignSource.sha256), findsOneWidget);
    // 역할 색 판 — 라이트 · 다크 하나씩
    expect(findText('라이트'), findsWidgets);
    expect(findText('다크'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다크 판 안에서는 역할 색이 다크 값이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: GrooTheme.light(), home: const DsCatalogScreen()),
    );

    final darkLabel = findText('다크').first;
    final ctx = tester.element(darkLabel);
    expect(ctx.colors.bgLayerDefault, PColors.dark.bgLayerDefault);
    final lightCtx = tester.element(findText('라이트').first);
    expect(lightCtx.colors.bgLayerDefault, PColors.light.bgLayerDefault);
  });

  // 카탈로그는 목록이 게을러 첫 화면 밖 견본을 그리지 않는다 — 견본을 하나씩 폰 폭(390)에서
  // 라이트 · 다크로 그려 넘침 · 예외를 잡는다.
  for (final entry in dsFamilies.expand((f) => f.entries)) {
    final demo = entry.demo;
    if (demo == null) continue;
    testWidgets('${entry.name} 견본이 폰 폭에서 라이트 · 다크로 그려진다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final theme in [GrooTheme.light(), GrooTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: ListView(
                // 카탈로그와 같은 안쪽 폭 — 목록 여백 16 + 판 여백 20
                padding: const EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
                children: [Builder(builder: demo)],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 1100));
        expect(tester.takeException(), isNull, reason: theme.brightness.name);
      }
      // 타이머 · 반복 애니메이션을 정리한다
      await tester.pumpWidget(const SizedBox());
    });
  }
}
