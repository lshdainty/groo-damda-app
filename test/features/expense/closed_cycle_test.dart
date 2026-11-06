// 결제가 끝난 회차는 기록만(2026-09-21 확정 D1·D2) — 앱이 서버 조회 없이 가르는 판정.
//
//   - 닫힌 회차 = 거래 날짜 ≤ 카드의 `cardClosedThrough`(서버가 내려 준다)
//   - 할부가 닫힌 회차와 열린 회차에 걸치면 "지난 회차분은 기록만 남아요" 로 갈린다
//     (첫 회차 말일 ≤ 경계 < 마지막 회차 말일)
//   - 목록 행 "기록만" 배지
//
// 회차 경계는 서버가 정한다(결제일 이력·서울 시계). 여기서 다시 계산하면 결제일을
// 바꾼 카드에서 어긋난다 — 그래서 날짜만 견주는지 고정한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: child),
);

const _expense = Expense(
  rowId: 1,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 25000,
  merchant: '가맹점',
  expenseDate: '2026-08-20T10:00:00',
);

/// 결제일 12일 카드 — 오늘 9/21 이면 8월분(9/12 결제)까지 닫혔다.
const _card = Asset(
  rowId: 9,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  paymentDay: 12,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);

void main() {
  group('카드 회차 결제일', () {
    test('거래 달의 다음 달 결제일이다', () {
      expect(cardCyclePaymentDate('2026-08-20', 12), '2026-09-12');
    });

    test('그 달에 없는 날이면 말일이다', () {
      expect(cardCyclePaymentDate('2027-01-10', 31), '2027-02-28');
    });

    test('12월 거래는 다음 해 1월에 결제된다', () {
      expect(cardCyclePaymentDate('2026-12-05', 12), '2027-01-12');
    });
  });

  // 결제일을 바꿔도 아직 결제 전인 회차는 옛 결제일에 결제된다(D5) — 확인창 문구의 재료.
  // 결제일 변경이 대기 중인 카드 — 서버가 첫 열린 회차의 실제 결제일(`nextPaymentDate`)을
  // 내려 준다. 그 회차는 그 날짜로, 그 뒤 회차는 지금 결제일로 센다(QA 26 4).
  group('회차의 실제 결제일 — nextPaymentDate', () {
    test('결제일의 전달이 그 회차의 이용 달이다', () {
      expect(cycleMonthOfPaymentDate('2026-09-25'), '2026-08');
      expect(cycleMonthOfPaymentDate('2027-01-10'), '2026-12');
    });

    test('그 회차 날짜면 서버가 준 결제일, 그 뒤 회차는 지금 결제일', () {
      // 25일 → 21일 → 10일로 바꾼 카드: 8월분은 옛 결제일 9/25, 9월분부터 10일.
      expect(cyclePaymentDate('2026-08-20', 10, '2026-09-25'), '2026-09-25');
      expect(cyclePaymentDate('2026-09-03', 10, '2026-09-25'), '2026-10-10');
    });

    test('서버가 안 주면 지금 결제일로만 센다', () {
      expect(cyclePaymentDate('2026-08-20', 10, null), '2026-09-10');
    });

    test('결제일 변경 확인창도 그 회차를 쓴다', () {
      final p = pendingCycleOnOldDay(
        oldPaymentDay: 21,
        cardClosedThrough: '2026-07-31',
        todayKey: '2026-09-21',
        nextPaymentDate: '2026-09-25',
      );
      expect((p.year, p.month, p.paymentDate), (2026, 8, '2026-09-25'));
    });
  });

  group('결제일 변경 — 옛 결제일로 결제되는 회차', () {
    test('닫힌 회차 경계의 다음 달 회차다', () {
      // 25일 카드, 9/14 — 7월분까지 닫혔다. 8월분은 옛 결제일 9/25 에 결제된다.
      final p = pendingCycleOnOldDay(
        oldPaymentDay: 25,
        cardClosedThrough: '2026-07-31',
        todayKey: '2026-09-14',
      );
      expect((p.year, p.month, p.paymentDate), (2026, 8, '2026-09-25'));
    });

    test('12월 경계면 다음 해 1월 회차다', () {
      final p = pendingCycleOnOldDay(
        oldPaymentDay: 10,
        cardClosedThrough: '2026-12-31',
        todayKey: '2027-01-12',
      );
      expect((p.year, p.month, p.paymentDate), (2027, 1, '2027-02-10'));
    });

    test('경계가 없으면 오늘 기준 결제일이 안 온 첫 회차다', () {
      final before = pendingCycleOnOldDay(
        oldPaymentDay: 25,
        cardClosedThrough: null,
        todayKey: '2026-09-14',
      );
      expect((before.month, before.paymentDate), (8, '2026-09-25'));
      // 결제일 당일부터 닫힌다(D2) — 그날이면 다음 회차다.
      final onDay = pendingCycleOnOldDay(
        oldPaymentDay: 25,
        cardClosedThrough: null,
        todayKey: '2026-09-25',
      );
      expect((onDay.month, onDay.paymentDate), (9, '2026-10-25'));
      final january = pendingCycleOnOldDay(
        oldPaymentDay: 10,
        cardClosedThrough: null,
        todayKey: '2026-01-05',
      );
      expect((january.year, january.month), (2025, 12));
    });
  });

  group('닫힌 회차 판정 — 날짜 ≤ cardClosedThrough', () {
    ClosedCycleSpan span(String date, {int? months, String? through}) =>
        closedCycleSpan(
          cardClosedThrough: through ?? '2026-08-31',
          dateKey: date,
          installmentMonths: months,
        );

    test('경계 날짜와 그 이전은 닫힌 회차다', () {
      expect(span('2026-08-31T23:59:00'), ClosedCycleSpan.full);
      expect(span('2026-08-01'), ClosedCycleSpan.full);
      expect(span('2025-12-31T10:00:00'), ClosedCycleSpan.full);
    });

    test('경계 다음 날부터는 열린 회차다', () {
      expect(span('2026-09-01T00:00:00'), ClosedCycleSpan.none);
      expect(span('2026-09-21'), ClosedCycleSpan.none);
    });

    test('서버가 경계를 안 주면(결제일 없는 카드·옛 서버) 모두 열린 회차다', () {
      expect(
        closedCycleSpan(cardClosedThrough: null, dateKey: '2020-01-01'),
        ClosedCycleSpan.none,
      );
    });

    test('일시불·1개월은 통째로다', () {
      expect(span('2026-08-20', months: 1), ClosedCycleSpan.full);
      expect(span('2026-08-20', months: 0), ClosedCycleSpan.full);
    });

    test('할부가 경계를 넘어가면 걸친 것이다', () {
      // 7월 3개월 = 7·8·9월 회차 — 9월 회차는 아직 열려 있다.
      expect(span('2026-07-15', months: 3), ClosedCycleSpan.partial);
      // 마지막 회차 말일이 곧 경계면 통째로 닫혔다.
      expect(span('2026-07-15', months: 2), ClosedCycleSpan.full);
    });

    test('할부 마지막 회차가 해를 넘겨도 말일을 맞게 센다', () {
      // 2026-11 부터 3개월 = 11·12·1월 → 마지막 회차 말일 2027-01-31.
      expect(
        span('2026-11-10', months: 3, through: '2027-01-31'),
        ClosedCycleSpan.full,
      );
      expect(
        span('2026-11-10', months: 3, through: '2026-12-31'),
        ClosedCycleSpan.partial,
      );
    });

    test('신용카드가 아니면 판정하지 않는다', () {
      const account = Asset(
        rowId: 3,
        assetName: '통장',
        assetType: 'BANK_ACCOUNT',
        cardClosedThrough: '2026-08-31',
      );
      expect(
        closedCycleSpanFor(account, dateKey: '2026-08-20'),
        ClosedCycleSpan.none,
      );
      expect(
        closedCycleSpanFor(null, dateKey: '2026-08-20'),
        ClosedCycleSpan.none,
      );
    });
  });

  group('확인창 한 문구', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await AppLocalizations.delegate.load(const Locale('ko'));
    });

    test('닫힌 회차면 기록만 바뀌고 계좌 잔액은 그대로라고 말한다', () {
      expect(
        closedCycleNote(l, closedCycleSpanOfExpense(_expense, _card)),
        '이미 결제가 끝난 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요.',
      );
    });

    test('할부가 걸치면 지난 회차분만 기록이라고 말한다', () {
      final e = _expense.copyWith(
        expenseDate: '2026-07-15T10:00:00',
        installmentMonths: 3,
      );
      expect(
        closedCycleNote(l, closedCycleSpanOfExpense(e, _card)),
        '지난 회차분은 기록만 남아요.',
      );
    });

    test('열린 회차는 말이 없다', () {
      final e = _expense.copyWith(expenseDate: '2026-09-10T10:00:00');
      expect(closedCycleNote(l, closedCycleSpanOfExpense(e, _card)), isNull);
    });

    test('본문 뒤에 문단으로 붙는다', () {
      expect(
        withClosedCycleNote(l, '지울까요?', ClosedCycleSpan.full),
        '지울까요?\n\n${l.expClosedCycleLine}',
      );
      expect(withClosedCycleNote(l, '지울까요?', ClosedCycleSpan.none), '지울까요?');
    });
  });

  group('목록 행 "기록만" 배지', () {
    Future<void> pumpRow(WidgetTester tester, Expense e) => tester.pumpWidget(
      _host(
        ExpenseRow(
          expense: e,
          category: null,
          flags: const MaskFlags.cardOnly(false),
          interactive: false,
        ),
      ),
    );

    testWidgets('표식이 있으면 단다', (tester) async {
      await pumpRow(
        tester,
        _expense.copyWith(cardSettledThrough: '2026-08-31'),
      );
      expect(findText('기록만'), findsOneWidget);
    });

    testWidgets('정상 거래에는 없다', (tester) async {
      await pumpRow(tester, _expense);
      expect(findText('기록만'), findsNothing);
    });

    // 할부의 지난 회차분만 기록용이면 남은 회차는 정상 청구된다 — 행 배지는 통째로
    // 기록용인 거래에만 단다(D10). 일부는 상세가 "이 중 N원" 으로 말한다.
    testWidgets('기록만 금액이 거래 금액보다 작으면 없다', (tester) async {
      await pumpRow(
        tester,
        _expense.copyWith(
          amount: 90000,
          installmentMonths: 3,
          cardSettledThrough: '2026-08-31',
          recordOnlyAmount: 30000,
        ),
      );
      expect(findText('기록만'), findsNothing);
    });

    testWidgets('기록만 금액이 거래 금액과 같으면 단다', (tester) async {
      await pumpRow(
        tester,
        _expense.copyWith(
          cardSettledThrough: '2026-08-31',
          recordOnlyAmount: 25000,
        ),
      );
      expect(findText('기록만'), findsOneWidget);
    });

    testWidgets('환불된 거래는 환불됨만 — 합계에서 빠진 쪽이 먼저다', (tester) async {
      await pumpRow(
        tester,
        _expense.copyWith(
          cardSettledThrough: '2026-08-31',
          refundedAt: '2026-09-15T12:00:00',
        ),
      );
      expect(findText('기록만'), findsNothing);
      expect(findText('환불됨'), findsOneWidget);
    });
  });
}
