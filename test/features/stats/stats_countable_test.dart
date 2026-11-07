// 통계의 일별 추이·지출 건수·요일별 합계가 **합계와 같은 규칙**으로 센다(23차 12).
//
// 환불한 거래는 삭제와 똑같이 빠지고, 카드 이월("이전 미결제 사용액")은 카드를 등록한
// 날의 지출이 아니다. 금액 합계(서버 값)에서는 빠지는데 이 셋에만 남으면 같은 화면
// 안에서 숫자가 어긋난다 — 이월이 등록한 날 추이 그래프에 솟았다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_screen.dart';

const _base = Expense(
  rowId: 1,
  expenseType: 'EXPENSE',
  amount: 10000,
  // 2026-09-07 은 월요일이다.
  expenseDate: '2026-09-07T10:00:00',
);

final _txs = [
  _base,
  // 환불한 거래 — 삭제와 같다.
  _base.copyWith(rowId: 2, amount: 3000, refundedAt: '2026-09-08T12:00:00'),
  // 카드 이월 — 등록한 날의 지출이 아니다.
  _base.copyWith(rowId: 3, amount: 500000, autoSource: 'CARD_CARRYOVER'),
  _base.copyWith(
    rowId: 4,
    expenseType: 'INCOME',
    amount: 7000,
    expenseDate: '2026-09-08T09:00:00',
  ),
];

void main() {
  test('일별 추이는 환불·이월을 빼고 모은다', () {
    final points = dailyTrendOf(
      _txs,
      DateTime(2026, 9, 7),
      DateTime(2026, 9, 8),
    );

    expect(points.map((p) => p.label), ['9. 7.', '9. 8.']);
    expect(points.first.expense, 10000);
    expect(points.last.income, 7000);
    expect(points.last.expense, 0);
  });

  test('지출 건수도 같은 규칙이다', () {
    expect(statsExpenseCount(_txs), 1);
  });

  test('요일별 합계도 같은 규칙이다', () {
    final sums = statsWeekdaySums(_txs);
    expect(sums[0], 10000, reason: '월요일 — 이월 500,000·환불 3,000 은 빠진다');
    expect(sums.fold<int>(0, (a, b) => a + b), 10000);
  });
}
