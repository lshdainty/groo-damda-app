// 확인창은 돈과 기록이 갈리는 자리에만(Q1), 예정 거래에는 [환불] 이 없다(Q2)
// — 사용자 결정 2026-09-21. 웹도 같은 규칙이다.
//
// Q1 저장 확인창
//   - 잠긴 거래(결제 끝남)의 편집 저장 — 묻지 않고 한 번에 저장한다(카테고리·가맹점·
//     메모만 바뀐다)
//   - 열린 회차 거래를 닫힌 회차 날짜로 옮기는 편집 저장 — 묻는다
//   - 열린 회차 거래를 열린 회차 안에서 고치는 저장 — 묻지 않는다
//   - 닫힌 회차로 들어가는 새 저장 — 묻는다
// Q2 [환불]
//   - 거래일이 오늘보다 뒤면 없다(환불일은 거래일~오늘이라 서버가 어떤 날짜로도 거절한다)
//   - 오늘·지난 날이면 있다. 오늘인데 시각만 뒤여도 있다
//   - 판정은 `expenseActions.canRefund` 하나다. 행 스와이프에는 [환불] 이 없다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/add_tx_drive.dart';

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
import 'package:groo_damda_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import '../../support/plain_text.dart';

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

/// 열린 회차(9월)의 카드 지출 — 잠기지 않았다.
const _open = Expense(
  rowId: 78,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 40000,
  merchant: '버스',
  paymentMethod: 'CARD',
  expenseDate: '2026-09-10T10:00:00',
);

/// 닫힌 회차(8월)의 카드 지출 — 서버가 잠갔다.
final _locked = _open.copyWith(
  rowId: 77,
  expenseDate: '2026-08-20T10:00:00',
  moneyLocked: true,
);

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  final updates = <String>[];
  final creates = <String>[];

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
  }) async {
    updates.add(expenseDate);
    return _open;
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
    creates.add(expenseDate);
    return _open;
  }
}

Future<_FakeRepo> _pump(WidgetTester tester, Widget home) async {
  final repo = _FakeRepo();
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        assetsProvider.overrideWith((ref) async => const [_card]),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        merchantMonthExpensesProvider.overrideWith(
          (ref, key) async => const [],
        ),
        recurringListProvider.overrideWith((ref) async => const []),
        dutchPayListProvider.overrideWith((ref) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Widget _opener(void Function(BuildContext) open) => Builder(
  builder: (ctx) =>
      TextButton(onPressed: () => open(ctx), child: const Text('open')),
);

/// 컨트롤러 글자로 찾는 입력칸 — 가맹점·날짜 칸.
Finder _fieldWith(String text) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller?.text == text);

/// 거래일을 [d] 로 — 날짜 칸은 입력칸이 아니라 고르는 줄의 날짜 조각이다(9cb9b91d · 95b698b3).
Future<void> _pickDate(WidgetTester tester, DateTime d) async {
  await tester.tap(
    find
        .descendant(
          of: find.byKey(const ValueKey('tx-row-date')),
          matching: find.byType(FormPiece),
        )
        .first,
  );
  await tester.pumpAndSettle();
  tester.widget<PDatePicker>(find.byType(PDatePicker)).onSingle!(d);
  await tester.pump();
  await tester.tap(findText('완료'));
  await tester.pumpAndSettle();
}

Finder _submit(String label) =>
    find.ancestor(of: findText(label), matching: find.byType(PButton)).last;

/// 기기 날짜 기준 [days] 날 뒤(음수면 앞)의 `yyyy-MM-dd`.
String _dayKey(int days) {
  final d = DateTime.now().add(Duration(days: days));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

void main() {
  group('Q1 편집 저장 — 확인창은 돈과 기록이 갈리는 자리에만', () {
    Future<_FakeRepo> openEdit(WidgetTester tester, Expense e) async {
      final repo = await _pump(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, edit: e)),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('잠긴 거래는 묻지 않고 저장 한 번', (tester) async {
      final repo = await openEdit(tester, _locked);

      await tester.enterText(_fieldWith('버스'), '시내버스');
      await tester.pump();
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(findText(_closedLine), findsNothing);
      expect(repo.updates, hasLength(1));
    });

    testWidgets('열린 회차 거래를 닫힌 회차 날짜로 옮기면 묻는다', (tester) async {
      final repo = await openEdit(tester, _open);

      await _pickDate(tester, DateTime(2026, 8, 20));
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(findText(_closedLine), findsOneWidget);
      expect(repo.updates, isEmpty, reason: '확인 전에는 보내지 않는다');

      await tester.tap(findText('저장').last);
      await tester.pumpAndSettle();
      expect(repo.updates.single, startsWith('2026-08-20'));
    });

    testWidgets('열린 회차 안에서 고치면 묻지 않는다', (tester) async {
      final repo = await openEdit(tester, _open);

      await _pickDate(tester, DateTime(2026, 9, 15));
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(findText(_closedLine), findsNothing);
      expect(repo.updates.single, startsWith('2026-09-15'));
    });

    testWidgets('닫힌 회차로 들어가는 새 저장은 묻는다', (tester) async {
      final repo = await _pump(
        tester,
        _opener((ctx) => showAddTxSheet(ctx, defaultDate: '2026-08-20')),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();
      await fillNewTx(tester, amount: '13000', asset: '현대카드');

      await tester.tap(_submit('추가'));
      await tester.pumpAndSettle();

      expect(findText(_closedLine), findsOneWidget);
      await tester.tap(findText('저장').last);
      await tester.pumpAndSettle();
      expect(repo.creates, hasLength(1));
    });
  });

  group('Q2 [환불] — 예정 거래에는 없다', () {
    test('판정 하나 — 거래일이 오늘보다 뒤면 거짓, 날짜만 본다', () {
      final now = DateTime(2026, 9, 21, 9, 30);
      bool can(String date) =>
          expenseActions.canRefund(_open.copyWith(expenseDate: date), now: now);

      expect(can('2026-09-22T00:00:00'), isFalse);
      expect(can('2026-10-01T09:00:00'), isFalse);
      expect(can('2026-09-21T23:59:00'), isTrue, reason: '오늘인데 시각만 뒤');
      expect(can('2026-09-21T00:00:00'), isTrue);
      expect(can('2026-08-20T10:00:00'), isTrue);
    });

    test('수입·환불된 거래·시스템 거래는 날짜와 무관하게 거짓', () {
      final now = DateTime(2026, 9, 21);
      expect(
        expenseActions.canRefund(
          _open.copyWith(expenseType: 'INCOME'),
          now: now,
        ),
        isFalse,
      );
      expect(
        expenseActions.canRefund(
          _open.copyWith(refundedAt: '2026-09-15T12:00:00'),
          now: now,
        ),
        isFalse,
      );
      expect(
        expenseActions.canRefund(
          _open.copyWith(autoSource: 'CARD_CARRYOVER'),
          now: now,
        ),
        isFalse,
      );
    });

    Future<void> openDetail(WidgetTester tester, Expense e) async {
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, e)));
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('상세 — 거래일이 내일 뒤면 [환불] 이 없다', (tester) async {
      await openDetail(
        tester,
        _open.copyWith(expenseDate: '${_dayKey(2)}T09:00:00'),
      );

      expect(findText('환불'), findsNothing);
      expect(findText('내역 분할'), findsOneWidget, reason: '다른 동작은 그대로');
    });

    testWidgets('상세 — 오늘 거래는 시각이 뒤여도 [환불] 이 있다', (tester) async {
      await openDetail(
        tester,
        _open.copyWith(expenseDate: '${_dayKey(0)}T23:59:59'),
      );

      expect(findText('환불'), findsOneWidget);
    });

    testWidgets('상세 — 지난 거래는 [환불] 이 있다', (tester) async {
      await openDetail(
        tester,
        _open.copyWith(expenseDate: '${_dayKey(-3)}T09:00:00'),
      );

      expect(findText('환불'), findsOneWidget);
    });

    testWidgets('스와이프 — [환불] 은 없다(수정·삭제뿐), 예정 거래도 같다', (tester) async {
      late List<PSwipeAction> future;
      late List<PSwipeAction> past;
      await _pump(
        tester,
        Consumer(
          builder: (ctx, ref, _) {
            future = expenseActions.dsSwipeActions(
              ctx,
              ref,
              _open.copyWith(expenseDate: '${_dayKey(2)}T09:00:00'),
              asset: _card,
            );
            past = expenseActions.dsSwipeActions(
              ctx,
              ref,
              _open.copyWith(expenseDate: '${_dayKey(-3)}T09:00:00'),
              asset: _card,
            );
            return const SizedBox.shrink();
          },
        ),
      );

      expect(future.map((a) => a.label), ['수정', '삭제']);
      expect(past.map((a) => a.label), ['수정', '삭제']);
    });
  });
}
