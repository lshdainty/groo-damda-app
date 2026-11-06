// 확인창 뒤 실패 표시 공용 함수 — 확인창 닫기 + critical 스낵바 + [다시 시도](묻지 않고 바로 요청).
// (작성만 — 실행은 UI 이관이 끝난 뒤 한꺼번에.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import '../../support/plain_text.dart';

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
  for (final code in [kApiParseErrorCode, kApiNoResponseCode]) {
    testWidgets(
      '응답을 읽지/받지 못한 실패($code)는 [다시 시도] 없이 확인 글 · 다시 받기만 — false(검수 M3)',
      (tester) async {
        var calls = 0;
        var refreshed = 0;
        var succeeded = 0;
        bool? result;
        await _mount(
          tester,
          (context) => TextButton(
            onPressed: () async {
              result = await askConfirmThenRequest(
                context,
                title: '취소할까요?',
                description: '결제를 취소해요.',
                actionLabel: '취소하기',
                request: () async {
                  calls++;
                  throw ApiException(code: code, message: 'raw');
                },
                failedMessage: '취소하지 못했어요.',
                retryLabel: '다시 시도',
                onRetried: () => succeeded++,
                kind: WriteKind.process,
                onUnconfirmed: () => refreshed++,
              );
            },
            child: const Text('열기'),
          ),
        );
        await tester.tap(findText('열기'));
        await tester.pumpAndSettle();
        await tester.tap(findText('취소하기'));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(result, isFalse);
        expect(refreshed, 1, reason: '서버가 처리했을 수 있다 — 다시 받는다');
        expect(succeeded, 0, reason: '성공 뒷정리(알림)는 하지 않는다');
        expect(
          findText('처리됐는지 확인하지 못했어요.'),
          findsOneWidget,
          reason: '스낵바는 한 문장 — kind 대로(판단 ①)',
        );
        expect(findText('저장됐는지 확인하지 못했어요. 목록에서 확인해주세요.'), findsNothing);
        expect(findText('취소하지 못했어요.'), findsNothing);
        expect(_action, findsNothing, reason: '[다시 시도] 를 주면 두 번 처리된다');
      },
    );
  }

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
            kind: WriteKind.delete,
            onUnconfirmed: () {},
          );
        },
        child: const Text('열기'),
      ),
    );

    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    expect(find.byType(PAlertDialogView), findsOneWidget);

    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();

    // 확인창은 닫혔고, 스낵바가 떠 있다
    expect(find.byType(PAlertDialogView), findsNothing);
    expect(findText('삭제하지 못했어요.'), findsOneWidget);
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
          title: '삭제할까요?',
          description: '지울까요?',
          actionLabel: '삭제',
          request: () async {
            calls++;
            throw StateError('boom');
          },
          failedMessage: '삭제하지 못했어요.',
          retryLabel: '다시 시도',
          kind: WriteKind.delete,
          onUnconfirmed: () {},
        ),
        child: const Text('열기'),
      ),
    );
    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(_action);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(calls, 2);
    expect(findText('삭제하지 못했어요.'), findsOneWidget);
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
            title: '삭제할까요?',
            description: '지울까요?',
            cancelLabel: '취소',
            actionLabel: '삭제',
            request: () async => calls++,
            failedMessage: '삭제하지 못했어요.',
            retryLabel: '다시 시도',
            kind: WriteKind.delete,
            onUnconfirmed: () {},
          );
        },
        child: const Text('열기'),
      ),
    );

    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(calls, 0);

    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(calls, 1);
    expect(findText('삭제하지 못했어요.'), findsNothing);
  });

  testWidgets('실패 → 다시 시도 성공이면 onRetried 가 한 번 불린다', (tester) async {
    var calls = 0;
    var retried = 0;
    await _mount(
      tester,
      (context) => TextButton(
        onPressed: () => askConfirmThenRequest(
          context,
          title: '삭제할까요?',
          description: '지울까요?',
          actionLabel: '삭제',
          request: () async {
            calls++;
            if (calls == 1) throw StateError('boom');
          },
          failedMessage: '삭제하지 못했어요.',
          retryLabel: '다시 시도',
          onRetried: () => retried++,
          kind: WriteKind.delete,
          onUnconfirmed: () {},
        ),
        child: const Text('열기'),
      ),
    );
    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();
    expect(retried, 0);
    await tester.tap(_action);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(retried, 1);
  });

  testWidgets('다시 시도도 실패하면 같은 띠가 다시 뜨고 onRetried 는 불리지 않는다', (tester) async {
    var retried = 0;
    await _mount(
      tester,
      (context) => TextButton(
        onPressed: () => askConfirmThenRequest(
          context,
          title: '삭제할까요?',
          description: '지울까요?',
          actionLabel: '삭제',
          request: () async => throw StateError('boom'),
          failedMessage: '삭제하지 못했어요.',
          retryLabel: '다시 시도',
          onRetried: () => retried++,
          kind: WriteKind.delete,
          onUnconfirmed: () {},
        ),
        child: const Text('열기'),
      ),
    );
    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(_action);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(findText('삭제하지 못했어요.'), findsOneWidget);
    expect(retried, 0);
  });

  testWidgets('호출한 위젯이 사라진 뒤에도 다시 시도는 요청을 한 번 보낸다', (tester) async {
    var calls = 0;
    var retried = 0;
    final show = ValueNotifier<bool>(true);
    addTearDown(show.dispose);
    await _mount(
      tester,
      (context) => ValueListenableBuilder<bool>(
        valueListenable: show,
        builder: (context, on, _) => on
            ? Builder(
                builder: (context) => TextButton(
                  onPressed: () => askConfirmThenRequest(
                    context,
                    title: '삭제할까요?',
                    description: '지울까요?',
                    actionLabel: '삭제',
                    request: () async {
                      calls++;
                      if (calls == 1) throw StateError('boom');
                    },
                    failedMessage: '삭제하지 못했어요.',
                    retryLabel: '다시 시도',
                    onRetried: () => retried++,
                    kind: WriteKind.delete,
                    onUnconfirmed: () {},
                  ),
                  child: const Text('열기'),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();
    // 시트(호출한 위젯)가 닫힌다
    show.value = false;
    await tester.pumpAndSettle();
    expect(findText('열기'), findsNothing);
    await tester.tap(_action);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(retried, 1);
  });
}
