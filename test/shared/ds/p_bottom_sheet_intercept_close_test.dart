// Bottom Sheet 닫기 청 가로채기(interceptClose) — 시트 안 한 단계가 열린 동안 뒤로 가기 · Esc · 닫기가 시트를 닫지 않고
// 그 단계로 쓰인다. 바뀐 값을 묻는 시트(isDirty)에서도 그 단계에서는 묻지 않는다(웹 `onOpenChange(false)` 가로채기와 같다).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import '../../support/plain_text.dart';

Widget _app(Widget home) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

void main() {
  testWidgets('가로채는 동안은 닫기 · 뒤로 가기 · Esc 가 시트를 닫지 않는다', (tester) async {
    var inStep = true;
    var intercepted = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => PBottomSheet.show<void>(
                context,
                form: true,
                isDirty: () => true,
                leaveCopy: const PLeaveConfirmCopy(
                  title: '작성한 내용이 사라져요',
                  description: '나가면 저장되지 않아요.',
                  stayLabel: '계속 작성',
                  leaveLabel: '나가기',
                ),
                interceptClose: () {
                  if (!inStep) return false;
                  intercepted++;
                  inStep = false;
                  return true;
                },
                builder: (_) => PBottomSheetContent(
                  title: '제목',
                  showCloseButton: false,
                  body: SizedBox(height: 40, child: Text('본문')),
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
    expect(findText('본문'), findsOneWidget);

    // 1. Esc — 단계만 닫힌다(시트는 남고, 묻지 않는다)
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(intercepted, 1);
    expect(findText('본문'), findsOneWidget);
    expect(find.byType(PAlertDialogView), findsNothing);

    // 2. 그 뒤 Esc — 가로채지 않으니 바뀐 값을 묻는다
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(intercepted, 1);
    expect(find.byType(PAlertDialogView), findsOneWidget);
  });

  testWidgets('시스템 뒤로 가기도 가로챈다', (tester) async {
    var inStep = true;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => PBottomSheet.show<void>(
                context,
                form: true,
                interceptClose: () {
                  final was = inStep;
                  inStep = false;
                  return was;
                },
                builder: (_) => PBottomSheetContent(
                  title: '제목',
                  showCloseButton: false,
                  body: SizedBox(height: 40, child: Text('본문')),
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

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findText('본문'), findsOneWidget, reason: '첫 뒤로 가기는 단계만 닫는다');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findText('본문'), findsNothing, reason: '그다음에는 시트가 닫힌다');
  });
}
