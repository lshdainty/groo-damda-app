// 결제가 끝난 회차 — 확인창 **한 문구**와 결과 토스트가 화면에 실제로 뜨는가(D1·D4·D16).
//
// 예전엔 서버에 "얼마가 돌아오나" 를 미리 물어 다섯 갈래 문장을 골랐다(3초 제한·실패
// 폴백·예고 금액 비교). 닫힌 회차는 이제 기록만 바뀌므로 묻지 않는다. 여기서 잠그는 것은
//   ① 스와이프·상세의 삭제 확인창이 같은 한 문구를 붙인다 — 열린 회차엔 안 붙인다
//   ② 미리 낸 돈이 계좌로 돌아왔으면 사후 토스트로 알린다(스와이프 삭제 포함)
//   ③ 환불 확인창: 금액 단위 · 닫힌 회차 한 문구 · 환불일은 거래일~오늘
//   ④ 환불 취소: 옛 환급 이체가 묶인 거래만 "환급된 금액도 되돌아가요"
//   ⑤ 새 저장: 닫힌 회차로 가면 한 번 묻고, 물러나면 아무것도 안 보낸다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/refund_step.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';

/// ds 확인창은 글자 사이에 낱말 단위 줄바꿈 U+2060 을 넣는다 — 그 글자를 뺀 글로 찾는다.
Finder _plain(String needle) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? w.textSpan?.toPlainText() ?? '')
          .replaceAll('\u2060', '')
          .replaceAll('\u200B', '')
          .contains(needle),
);

const _closedLine = '이미 결제가 끝난 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요.';

/// 결제일 12일 카드 — 8월분(9/12 결제)까지 닫혔다.
const _card = Asset(
  rowId: 9,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 12,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);

const _category = ExpenseCategory(
  rowId: 11,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

/// 닫힌 회차(8월)의 카드 지출.
const _closed = Expense(
  rowId: 77,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 40000,
  merchant: '버스',
  expenseDate: '2026-08-20T10:00:00',
);

/// 열린 회차(9월)의 카드 지출.
final _open = _closed.copyWith(rowId: 78, expenseDate: '2026-09-10T10:00:00');

/// 부른 경로·인자를 잡고 정해 둔 응답을 돌려주는 가짜 레포지토리.
class _FakeRepo extends ExpenseRepository {
  _FakeRepo({this.refundedOnDelete, this.refundedOnRefund})
    : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  final int? refundedOnDelete;
  final int? refundedOnRefund;
  final deleted = <int>[];
  final created = <Map<String, Object?>>[];
  String? refundedAt;

  @override
  Future<int?> delete(int id, {bool silent = false}) async {
    deleted.add(id);
    return refundedOnDelete;
  }

  @override
  Future<Expense> refund(
    int id, {
    String? refundedAt,
    bool silent = false,
  }) async {
    this.refundedAt = refundedAt;
    return _closed.copyWith(
      refundedAt: refundedAt,
      refundedAmount: refundedOnRefund,
    );
  }

  @override
  Future<Expense> create({
    required int categoryRowId,
    int? assetRowId,
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
    bool? isFixed,
    bool silent = false,
  }) async {
    created.add({
      'assetRowId': assetRowId,
      'amount': amount,
      'expenseDate': expenseDate,
    });
    return _closed;
  }

  @override
  Future<Expense> update({
    required int id,
    required int categoryRowId,
    Patch<int> assetRowId = const Patch.keep(),
    required String expenseType,
    required int amount,
    required String expenseDate,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    Patch<int> installmentMonths = const Patch.keep(),
    Patch<double> originalAmount = const Patch.keep(),
    Patch<String> originalCurrency = const Patch.keep(),
    Patch<double> exchangeRate = const Patch.keep(),
    List<SplitInput>? splits,
    Patch<bool> isFixed = const Patch.keep(),
    bool silent = false,
  }) async => _open.copyWith(refundedAmount: 30000);
}

Future<void> _pumpApp(
  WidgetTester tester,
  Widget home, {
  required _FakeRepo repo,
  Asset card = _card,
}) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        assetsProvider.overrideWith((ref) async => [card]),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        merchantMonthExpensesProvider.overrideWith(
          (ref, key) async => const [],
        ),
        recurringListProvider.overrideWith((ref) async => const []),
        dutchPayListProvider.overrideWith((ref) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: SlidableAutoCloseBehavior(child: home)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 토스트가 스스로 닫히게 둔다 — 남은 타이머가 있으면 테스트가 끝나며 실패한다.
Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}

/// 스와이프 액션만 단 행 하나 — 가계부 목록과 같은 조립(`expenseActions.swipeActions`).
Widget _swipeRow(Expense e) => Consumer(
  builder: (ctx, ref, _) => PSwipeActions(
    actions: expenseActions.dsSwipeActions(ctx, ref, e, asset: _card),
    child: const SizedBox(
      height: 64,
      width: double.infinity,
      child: Text('거래 행'),
    ),
  ),
);

Future<void> _swipeDelete(WidgetTester tester) async {
  await tester.drag(find.text('거래 행'), const Offset(-300, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('삭제'));
  await tester.pumpAndSettle();
}

Widget _opener(void Function(BuildContext) open) => Builder(
  builder: (ctx) =>
      TextButton(onPressed: () => open(ctx), child: const Text('open')),
);

void main() {
  group('스와이프 삭제', () {
    testWidgets('닫힌 회차 카드 거래는 확인창에 한 문구가 붙는다', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(tester, _swipeRow(_closed), repo: repo);

      await _swipeDelete(tester);

      expect(_plain('"버스" 거래를 삭제할까요?'), findsOneWidget);
      expect(_plain(_closedLine), findsOneWidget);
    });

    testWidgets('열린 회차는 문구가 없다', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(tester, _swipeRow(_open), repo: repo);

      await _swipeDelete(tester);

      expect(_plain('"버스" 거래를 삭제할까요?'), findsOneWidget);
      expect(_plain(_closedLine), findsNothing);
      expect(_plain('환급'), findsNothing, reason: '예고 문구는 걷었다');
    });

    testWidgets('미리 낸 돈이 돌아오면 지운 뒤 토스트로 알린다(D4)', (tester) async {
      final repo = _FakeRepo(refundedOnDelete: 30000);
      await _pumpApp(tester, _swipeRow(_open), repo: repo);

      await _swipeDelete(tester);
      // 확인창의 [삭제] — 트레이는 닫혔으니 남은 '삭제' 는 확인 버튼이다.
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      expect(repo.deleted, [78]);
      expect(find.text('미리 낸 돈 중 30,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });

    testWidgets('돌려준 돈이 없으면 토스트도 없다', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(tester, _swipeRow(_open), repo: repo);

      await _swipeDelete(tester);
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      expect(repo.deleted, [78]);
      expect(find.textContaining('계좌로 돌아왔어요'), findsNothing);
    });
  });

  group('상세 삭제', () {
    testWidgets('스와이프와 같은 문구 — 닫힌 회차 한 줄', (tester) async {
      final repo = _FakeRepo(refundedOnDelete: 12000);
      await _pumpApp(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _closed)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.textContaining(_closedLine), findsOneWidget);

      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.deleted, [77]);
      expect(find.text('미리 낸 돈 중 12,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });
  });

  group('환불 단계', () {
    /// 상세를 열어 "더 하기" 의 [환불] 줄을 눌러 같은 시트의 환불 단계로 들어간다(I-21 I 46).
    Future<void> openStep(
      WidgetTester tester,
      Expense e, {
      Asset card = _card,
    }) async {
      await _pumpApp(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, e)),
        repo: _FakeRepo(),
        card: card,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('more-refund')));
      await tester.pumpAndSettle();
    }

    // 닫힌 회차는 카드로 되돌아가는 돈이 없다 — "N원이 카드에 돌아가요" 를 쓰면 바로
    // 아래 "계좌 잔액은 그대로예요" 와 부딪친다. 본문도 갈린다(웹과 같은 문구).
    testWidgets('닫힌 회차면 돌아간다는 말 없이 표시만 하고 한 문구를 말한다', (tester) async {
      await openStep(tester, _closed);

      expect(find.text('이 거래를 환불로 표시해요. 합계에서 빠져요.'), findsOneWidget);
      expect(find.textContaining('돌아가요'), findsNothing);
      expect(find.text(_closedLine), findsOneWidget);
      expect(find.text('환불 처리'), findsWidgets, reason: '머리 제목 + 바닥 버튼');
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: '확인창이 아니라 같은 시트의 한 단계',
      );
    });

    testWidgets('열린 회차는 돌아가는 금액을 단위와 함께 말한다(조사가 이름에 붙지 않는다)', (tester) async {
      await openStep(tester, _open);

      expect(_plain('합계에서 빠지고 40,000원이 현대카드에 돌아가요.'), findsOneWidget);
      expect(find.textContaining('(으)로'), findsNothing);
      expect(find.text(_closedLine), findsNothing);
    });

    testWidgets('열린 회차 + 결제계좌 없는 카드는 그 안내만', (tester) async {
      await openStep(
        tester,
        _open,
        card: _card.copyWith(paymentAssetRowId: null),
      );

      expect(find.text(_closedLine), findsNothing);
      expect(find.text('결제계좌가 없어 카드 잔액만 정리돼요.'), findsOneWidget);
    });

    testWidgets('환불일은 거래일부터 오늘까지만 고를 수 있다(D16) — 확인창 안 날짜 칸은 없다', (
      tester,
    ) async {
      await openStep(tester, _closed);

      expect(find.byType(TextField), findsNothing, reason: '날짜 칸 없음');
      await tester.tap(find.byKey(const ValueKey('refund-date-row')));
      await tester.pumpAndSettle();

      final picker = tester.widget<PDatePicker>(find.byType(PDatePicker));
      final now = DateTime.now();
      expect(picker.min, DateTime(2026, 8, 20));
      expect(picker.max, DateTime(now.year, now.month, now.day));
    });

    test('범위는 날짜만 본다 — 거래 시각 때문에 당일이 빠지지 않는다', () {
      final r = refundDateRange(
        _closed.copyWith(expenseDate: '2026-09-21T23:59:00'),
        now: DateTime(2026, 9, 21, 8),
      );
      expect(r.first, DateTime(2026, 9, 21));
      expect(r.last, DateTime(2026, 9, 21));
    });

    // 예정 거래에는 [환불] 이 없다(canRefund) — 이건 달력이 깨지지 않게 두는 방어다.
    test('거래일이 오늘보다 뒤여도 범위가 뒤집히지 않는다', () {
      final r = refundDateRange(
        _closed.copyWith(expenseDate: '2026-10-01T09:00:00'),
        now: DateTime(2026, 9, 21, 8),
      );
      expect(r.first, DateTime(2026, 9, 21));
      expect(r.last, DateTime(2026, 9, 21));
    });

    testWidgets('환불해서 미리 낸 돈이 돌아오면 토스트로 알린다(D4)', (tester) async {
      final repo = _FakeRepo(refundedOnRefund: 8000);
      await _pumpApp(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _open)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('more-refund')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PButton, '환불 처리'));
      await tester.pumpAndSettle();

      expect(repo.refundedAt, endsWith('T12:00:00'));
      expect(find.text('미리 낸 돈 중 8,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });
  });

  group('환불 취소', () {
    Future<void> openCancel(WidgetTester tester, Expense e) async {
      await _pumpApp(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, e)),
        repo: _FakeRepo(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PButton, '환불 취소'));
      await tester.pumpAndSettle();
    }

    testWidgets('옛 환급 이체가 묶인 거래만 "환급된 금액도 되돌아가요"', (tester) async {
      await openCancel(
        tester,
        _closed.copyWith(
          refundedAt: '2026-09-15T12:00:00',
          refundTransferRowId: 501,
        ),
      );

      expect(find.textContaining('환급된 금액도 되돌아가요'), findsOneWidget);
      expect(
        find.textContaining(_closedLine),
        findsNothing,
        reason: '그 이체는 통장에서 다시 빠진다 — "잔액 그대로" 는 거짓이 된다',
      );
    });

    testWidgets('표식만 풀리는 닫힌 회차 거래는 기록만 바뀐다고 말한다', (tester) async {
      await openCancel(
        tester,
        _closed.copyWith(refundedAt: '2026-09-15T12:00:00'),
      );

      expect(find.textContaining('환급된 금액도 되돌아가요'), findsNothing);
      expect(find.textContaining('이 거래가 합계에 다시 들어가요.'), findsOneWidget);
      expect(find.textContaining(_closedLine), findsOneWidget);
    });
  });

  group('새 저장', () {
    Future<_FakeRepo> openAndFill(WidgetTester tester, String date) async {
      final repo = _FakeRepo();
      await _pumpApp(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, defaultDate: date)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '13000');
      await tester.pump();
      await tester.tap(find.text('식비').last);
      await tester.pumpAndSettle();
      // 계좌·카드 선택 — '선택 안 함' 이 둘(결제 수단·자산)이라 마지막 것이 자산이다.
      await tester.tap(find.text('선택 안 함').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('현대카드').last);
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('닫힌 회차 날짜면 한 번 묻고, 물러나면 보내지 않는다', (tester) async {
      final repo = await openAndFill(tester, '2026-08-20');

      await tester.tap(find.text('추가').last);
      await tester.pumpAndSettle();
      expect(find.text('저장할까요?'), findsOneWidget);
      expect(find.text(_closedLine), findsOneWidget);

      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      expect(repo.created, isEmpty);

      await tester.tap(find.text('추가').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();
      expect(repo.created.single['assetRowId'], 9);
    });

    testWidgets('열린 회차는 묻지 않고 저장한다', (tester) async {
      final repo = await openAndFill(tester, '2026-09-10');

      await tester.tap(find.text('추가').last);
      await tester.pumpAndSettle();

      expect(find.text('저장할까요?'), findsNothing);
      expect(repo.created, hasLength(1));
    });
  });

  group('편집 저장', () {
    testWidgets('미리 낸 돈이 돌아오면 저장 뒤 토스트로 알린다(D4)', (tester) async {
      final repo = _FakeRepo();
      await _pumpApp(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, edit: _open)),
        repo: repo,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();

      expect(find.text('미리 낸 돈 중 30,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drainToast(tester);
    });
  });
}
