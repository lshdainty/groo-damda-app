// 확인창 뒤 실패 표시 공용 함수 — 확인창 닫기 + critical 스낵바 + [다시 시도](묻지 않고 바로 요청).
// (작성만 — 실행은 UI 이관이 끝난 뒤 한꺼번에.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';

final _action = find.byKey(const ValueKey('snackbar-action'));

Future<void> _mount(WidgetTester tester, Widget Function(BuildContext) body) {
  return tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (context, child) => Material(
        type: MaterialType.transparency,
        child: PSnackbarHost(
          closeLabel: '닫기',
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(body: Builder(builder: body)),
    ),
  );
}

void main() {
  testWidgets('실패하면 확인창을 닫고 critical 스낵바를 띄우며, 다시 시도는 묻지 않고 바로 요청한다', (
    tester,
  ) async {
    var calls = 0;
    bool? result;
    await _mount(
      tester,
      (context) => TextButton(
        onPressed: () async {
          result = await askConfirmThenRequest(
            context,
            title: '삭제할까요?',
            description: '지우면 돌릴 수 없어요.',
            actionLabel: '삭제',
            request: () async {
              calls++;
              if (calls == 1) throw StateError('boom');
            },
            failedMessage: '삭제하지 못했어요.',
            retryLabel: '다시 시도',
          );
        },
        child: const Text('열기'),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    // 확인창은 닫혔고, 스낵바가 떠 있다
    expect(find.byType(PAlertDialogView), findsNothing);
    expect(find.text('삭제하지 못했어요.'), findsOneWidget);
    expect(result, isFalse);
    expect(calls, 1);

    // 다시 시도 — 확인창을 다시 열지 않고 바로 요청한다
    await tester.tap(_action);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(PAlertDialogView), findsNothing);
  });

  testWidgets('다시 시도도 실패하면 같은 띠가 다시 뜬다', (tester) async {
    var calls = 0;
    await _mount(
      tester,
      (context) => TextButton(
        onPressed: () => askConfirmThenRequest(
          context,
          description: '지울까요?',
          actionLabel: '삭제',
          request: () async {
            calls++;
            throw StateError('boom');
          },
          failedMessage: '삭제하지 못했어요.',
          retryLabel: '다시 시도',
        ),
        child: const Text('열기'),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(_action);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(calls, 2);
    expect(find.text('삭제하지 못했어요.'), findsOneWidget);
  });

  testWidgets('성공하면 스낵바 없이 true, 취소하면 요청하지 않고 false', (tester) async {
    var calls = 0;
    bool? result;
    await _mount(
      tester,
      (context) => TextButton(
        onPressed: () async {
          result = await askConfirmThenRequest(
            context,
            description: '지울까요?',
            cancelLabel: '취소',
            actionLabel: '삭제',
            request: () async => calls++,
            failedMessage: '삭제하지 못했어요.',
            retryLabel: '다시 시도',
          );
        },
        child: const Text('열기'),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(calls, 0);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(calls, 1);
    expect(find.text('삭제하지 못했어요.'), findsNothing);
  });
}
