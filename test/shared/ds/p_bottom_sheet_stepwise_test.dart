// Bottom Sheet 단계마다 달라지는 닫힘 규칙(I-09b 5 · 9) — 일정 목록 · 상세는 조회(바깥 누르기로 닫힘), 수정 폼은 입력(안 닫힘).
// 닫기 원 · 바깥 · 끌기는 한 단계가 아니라 시트 전체(wholeSheet), 뒤로 가기 · Esc 만 한 단계 뒤(interceptClose).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';

class _Steps {
  bool form = false;
  bool inner = true;
  int intercepted = 0;
}

Future<_Steps> _open(WidgetTester tester, {bool dirty = false}) async {
  final s = _Steps();
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => PBottomSheet.show<void>(
              context,
              isForm: () => s.form,
              isDirty: () => dirty && s.form,
              leaveCopy: const PLeaveConfirmCopy(
                title: '작성한 내용이 사라져요',
                description: '나가면 저장되지 않아요.',
                stayLabel: '계속 작성',
                leaveLabel: '나가기',
              ),
              interceptClose: () {
                if (!s.inner) return false;
                s.intercepted++;
                s.inner = false;
                return true;
              },
              builder: (ctx) => PBottomSheetContent(
                title: '제목',
                closeLabel: '닫기',
                // 닫기 원은 한 단계가 아니라 시트 전체
                onClose: () =>
                    PBottomSheet.of(ctx).requestClose(wholeSheet: true),
                body: const SizedBox(height: 40, child: Text('본문')),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return s;
}

void main() {
  testWidgets('조회 단계에서는 바깥을 누르면 한 단계가 아니라 시트 전체가 닫힌다', (tester) async {
    final s = await _open(tester);
    expect(find.text('본문'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('본문'), findsNothing);
    expect(s.intercepted, 0, reason: '바깥 누르기는 단계를 거치지 않는다');
  });

  testWidgets('입력 폼 단계에서는 바깥을 눌러도 닫히지 않는다', (tester) async {
    final s = await _open(tester);
    s.form = true;
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('본문'), findsOneWidget);
    // 단계를 조회로 되돌리면 같은 시트가 다시 바깥 누르기로 닫힌다
    s.form = false;
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('본문'), findsNothing);
  });

  testWidgets('닫기 원은 단계를 건너뛰고 시트 전체를 닫고, Esc 는 한 단계만 닫는다', (tester) async {
    final s = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(s.intercepted, 1);
    expect(find.text('본문'), findsOneWidget, reason: 'Esc 는 단계만');

    s.inner = true;
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(s.intercepted, 1, reason: '닫기 원은 가로채기를 거치지 않는다');
    expect(find.text('본문'), findsNothing);
  });

  testWidgets('입력 폼 단계에서 바뀐 값이 있으면 닫기 원이 먼저 묻는다', (tester) async {
    final s = await _open(tester, dirty: true);
    s.form = true;
    s.inner = false;
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsOneWidget);
    expect(find.text('본문'), findsOneWidget);
  });
}
