// 겹친 시트를 닫으면 초점이 거래처 칸이 아니라 연 줄로 돌아온다(시험 2026-11-11 DA-03 6).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/forms/focus_release.dart';
import '../../support/plain_text.dart';

void main() {
  for (final mode in ['old', 'release', 'row']) {
    testWidgets('겹친 시트를 닫은 뒤 초점 — $mode', (tester) async {
      tester.view.physicalSize = const Size(1170, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      final merchant = FocusNode();
      final row = FocusNode();
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
                    title: '거래 추가',
                    closeLabel: '닫기',
                    body: Column(
                      children: [
                        PInput(focusNode: merchant, semanticLabel: '거래처'),
                        TextButton(
                          focusNode: row,
                          onPressed: () async {
                            if (mode == 'old') {
                              FocusScope.of(c).unfocus();
                            } else {
                              releaseFocusForSheet(
                                c,
                                returnTo: mode == 'row' ? row : null,
                              );
                            }
                            await PBottomSheet.show<void>(
                              c,
                              builder: (c2) => PBottomSheetContent(
                                title: '카테고리',
                                closeLabel: '닫기',
                                body: const SizedBox(height: 100),
                              ),
                            );
                          },
                          child: const Text('카테고리 줄'),
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
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(merchant.hasFocus, isTrue);
      await tester.tap(findText('카테고리 줄'));
      await tester.pumpAndSettle();
      expect(merchant.hasFocus, isFalse, reason: '열려 있는 동안 거래처 초점 없음');
      // 겹친 시트 닫기
      await tester.tap(find.bySemanticsLabel('닫기').last);
      await tester.pumpAndSettle();
      if (mode == 'old') {
        // 지금 동작 — 거래처로 돌아온다(결함 재현)
        expect(merchant.hasFocus, isTrue);
      } else {
        expect(merchant.hasFocus, isFalse, reason: '거래처로 돌아가지 않는다');
        if (mode == 'row') expect(row.hasFocus, isTrue, reason: '연 줄로 돌아온다');
      }
    });
  }
}
