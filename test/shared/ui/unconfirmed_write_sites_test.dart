// 응답을 못 받은 쓰기(NO_RESPONSE) — 자리마다 동작에 맞는 한 문장 · [다시 시도] 없음 · 목록 다시 받기(I-wrap-b2b 판단 ① · ②).
//
// - 삭제(더치페이 확인창 삭제) → "삭제됐는지 확인하지 못했어요."
// - 모두 받음(더치페이 정산, 확인창 없는 처리) → "처리됐는지 확인하지 못했어요."
// - 토글(메모 고정) → "바뀌었는지 확인하지 못했어요." — 보통 실패도 [다시 시도] 를 주지 않는다(다시 누르면 한 번 더 뒤집힌다)
// 기기 로그아웃은 기기 화면 시험(i12_1_menu_more_devices_test)에 있다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/data/dutch_pay_repository.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_actions.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/data/memo_repository.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../../support/plain_text.dart';

final _action = find.byKey(const ValueKey('snackbar-action'));

const _dp = DutchPay(
  rowId: 7,
  title: '회식',
  totalAmount: 30000,
  dutchPayDate: '2026-10-14',
  isSettled: false,
  participants: [
    DutchPayParticipant(
      rowId: 71,
      participantName: '나',
      amount: 15000,
      isPayer: true,
      isPaid: true,
    ),
    DutchPayParticipant(
      rowId: 72,
      participantName: '철수',
      amount: 15000,
      isPayer: false,
      isPaid: false,
    ),
  ],
);

const _memo = Memo(
  rowId: 3,
  title: '장보기',
  isPinned: 'N',
  modifyAt: '2026-10-01T00:00:00',
);

ApiException _noResponse() =>
    ApiException(code: kApiNoResponseCode, message: 'raw');

class _DutchRepo extends DutchPayRepository {
  _DutchRepo() : super(Dio());
  int lists = 0;
  int deletes = 0;
  int settles = 0;

  @override
  Future<List<DutchPay>> list() async {
    lists++;
    return const [_dp];
  }

  @override
  Future<void> delete(int id, {bool silent = false}) async {
    deletes++;
    throw _noResponse();
  }

  @override
  Future<void> settle(int id, {bool silent = false}) async {
    settles++;
    throw _noResponse();
  }
}

class _MemoRepo extends MemoRepository {
  _MemoRepo(this.fail) : super(Dio());
  final ApiException Function() fail;
  int lists = 0;
  int pins = 0;

  @override
  Future<List<Memo>> list({String? search}) async {
    lists++;
    return const [_memo];
  }

  @override
  Future<void> pin(int id) async {
    pins++;
    throw fail();
  }
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  List<Override> overrides,
  void Function(BuildContext context) onTap,
) async {
  final container = ProviderContainer(
    overrides: overrides,
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
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
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => onTap(context),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('삭제 응답 없음 — "삭제됐는지 확인하지 못했어요." · [다시 시도] 없음 · 목록 다시 받음', (
    tester,
  ) async {
    final repo = _DutchRepo();
    final c = await _mount(tester, [
      dutchPayRepositoryProvider.overrideWith((ref) async => repo),
    ], (context) => deleteDutchWithConfirm(context, _dp));
    c.listen(dutchPayListProvider, (_, _) {});
    await c.read(dutchPayListProvider.future);
    expect(repo.lists, 1);

    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: findText('삭제'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.deletes, 1);
    expect(findPlain('삭제됐는지 확인하지 못했어요.'), findsOneWidget);
    expect(findPlainContaining('저장됐는지'), findsNothing);
    expect(findPlainContaining('목록에서 확인'), findsNothing, reason: '스낵바는 한 문장');
    expect(_action, findsNothing, reason: '지워졌을 수 있다 — 다시 누르면 두 번 처리된다');
    expect(repo.lists, 2, reason: '지워졌는지 서버 목록으로 맞춘다');
  });

  testWidgets('모두 받음 응답 없음 — "처리됐는지 확인하지 못했어요." · [다시 시도] 없음 · 목록 다시 받음', (
    tester,
  ) async {
    final repo = _DutchRepo();
    final c = await _mount(tester, [
      dutchPayRepositoryProvider.overrideWith((ref) async => repo),
    ], (context) => settleDutch(context, _dp));
    c.listen(dutchPayListProvider, (_, _) {});
    await c.read(dutchPayListProvider.future);

    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();

    expect(repo.settles, 1);
    expect(findPlain('처리됐는지 확인하지 못했어요.'), findsOneWidget);
    expect(findPlainContaining('저장됐는지'), findsNothing);
    expect(_action, findsNothing);
    expect(repo.lists, 2);
  });

  group('메모 고정(토글)', () {
    testWidgets(
      '응답 없음 — 되돌리지 않고 목록을 다시 받아 맞춘 뒤 "바뀌었는지 확인하지 못했어요." · [다시 시도] 없음',
      (tester) async {
        final repo = _MemoRepo(_noResponse);
        final c = await _mount(tester, [
          memoRepositoryProvider.overrideWith((ref) async => repo),
        ], (context) => memoActions.pin(context, _memo));
        c.listen(memoListProvider, (_, _) {});
        await c.read(memoListProvider.future);
        expect(repo.lists, 1);

        await tester.tap(findText('열기'));
        await tester.pumpAndSettle();

        expect(repo.pins, 1);
        expect(findPlain('바뀌었는지 확인하지 못했어요.'), findsOneWidget);
        expect(findPlain('고정을 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsNothing);
        expect(_action, findsNothing, reason: '뒤집기만 하는 요청 — 다시 누르면 한 번 더 뒤집힌다');
        expect(repo.lists, 2, reason: '서버 값으로 맞춘다');
      },
    );

    testWidgets(
      '실패 — 두 문장 "고정을 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요." · [다시 시도] 없음(판단 ②)',
      (tester) async {
        final repo = _MemoRepo(
          () => ApiException(code: 'HTTP_500', message: 'raw', statusCode: 500),
        );
        await _mount(tester, [
          memoRepositoryProvider.overrideWith((ref) async => repo),
        ], (context) => memoActions.pin(context, _memo));

        await tester.tap(findText('열기'));
        await tester.pumpAndSettle();

        expect(findPlain('고정을 바꾸지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
        expect(_action, findsNothing);
      },
    );
  });
}
