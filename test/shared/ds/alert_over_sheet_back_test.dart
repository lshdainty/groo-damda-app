// 시트 위 확인창에서 기기 뒤로 가기 — 확인창만 닫히고 시트는 남는다(거래 삭제 · 이체 삭제가 이 모양이다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('뒤로 가기 한 번은 확인창만 닫고 취소와 같다 · 두 번째가 시트를 닫는다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPSheet<void>(
                context,
                title: '이체 상세',
                contentBuilder: (sheetCtx, _) => ListView(
                  children: [
                    TextButton(
                      onPressed: () async {
                        result = await PAlertDialog.show(
                          sheetCtx,
                          title: '이체 삭제',
                          description: '이 이체를 삭제할까요?',
                          cancelLabel: '취소',
                          actionLabel: '삭제',
                          destructive: true,
                        );
                      },
                      child: const Text('삭제하기'),
                    ),
                  ],
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('삭제하기'));
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsNothing);
    expect(findText('이체 상세'), findsOneWidget, reason: '시트는 남아야 한다');
    expect(result, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findText('이체 상세'), findsNothing);
  });
}
