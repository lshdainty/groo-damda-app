// 키보드가 떠 있을 때 초점 칸이 시트 본문 아래 끝 흐림(80) 위로 올라온다(시험 2026-11-11 7).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('초점 칸이 키보드 위 · 끝 흐림 80 위에 선다', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: 186, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 186, bottom: 102);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => PBottomSheet.show<void>(
                ctx,
                builder: (c) => PBottomSheetContent(
                  title: '폼',
                  closeLabel: '닫기',
                  scrollFog: true,
                  body: Column(
                    children: [
                      for (var i = 0; i < 8; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: PInput(
                            key: ValueKey('f$i'),
                            semanticLabel: '칸 $i',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    tester.view.viewInsets = const FakeViewPadding(bottom: 1008);
    await tester.pumpAndSettle();
    // 흐림 띠(아래 80)에 걸쳐 보이는 칸을 눌러 초점 — 흐림 위로 올라와야 한다
    final sheetBottom = tester
        .getBottomLeft(find.byType(PBottomSheetContent))
        .dy;
    Finder? target;
    for (var i = 0; i < 8; i++) {
      final f = find.byKey(ValueKey('f$i'));
      final bottom = tester.getBottomLeft(f).dy;
      if (bottom > sheetBottom - 80 + 4 && bottom < sheetBottom - 4) {
        target = f;
        break;
      }
    }
    expect(target, isNotNull, reason: '흐림 띠에 걸린 칸이 있어야 시험이 된다');
    await tester.tap(target!);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(target).dy,
      lessThanOrEqualTo(sheetBottom - 80 + 0.5),
      reason: '끝 흐림 80 위',
    );
  });
}
