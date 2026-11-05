// 더치페이 목록 셈(I-15-3) — 낸 수에 결제자 포함, 1인당 나머지 이름, 날짜 해 표시.
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay_model.dart';

DutchPayParticipant _p(
  int id,
  String n,
  int amt, {
  bool payer = false,
  bool paid = false,
}) => DutchPayParticipant(
  rowId: id,
  participantName: n,
  amount: amt,
  isPayer: payer,
  isPaid: paid,
);

DutchPay _d(
  List<DutchPayParticipant> ps, {
  int total = 184000,
  String date = '2026-10-14',
  bool settled = false,
}) => DutchPay(
  rowId: 1,
  title: 't',
  totalAmount: total,
  dutchPayDate: date,
  isSettled: settled,
  participants: ps,
);

void main() {
  test('낸 수는 결제자 + 낸 사람이다', () {
    final d = _d([
      _p(1, '나', 61334, payer: true),
      _p(2, '철수', 61333, paid: true),
      _p(3, '영희', 61333),
    ]);
    expect(dutchPaidCount(d), 2);
  });

  test('나머지는 결제자가 진다', () {
    final d = _d([
      _p(1, '나', 61334, payer: true),
      _p(2, '철수', 61333),
      _p(3, '영희', 61333),
    ]);
    final per = dutchPerPerson(d);
    expect(per.each, 61333);
    expect(per.restName, '나');
    expect(per.rest, 1);
    expect(per.even, isFalse);
  });

  test('나눠 떨어지면 나머지가 없다', () {
    final d = _d([_p(1, '나', 500, payer: true), _p(2, '철수', 500)], total: 1000);
    expect(dutchPerPerson(d).even, isTrue);
  });

  test('받을 돈은 안 낸 몫의 합이다', () {
    final d = _d([_p(1, '나', 500, payer: true), _p(2, '철수', 500)], total: 1000);
    final r = dutchReceivable([d]);
    expect(r.amount, 1000);
    expect(r.count, 2);
  });

  test('날짜는 올해만 해를 줄인다', () {
    final now = DateTime(2026, 11, 5);
    expect(dutchDateLabel('2026-10-14', now: now), '10월 14일');
    expect(dutchDateLabel('2025-10-14', now: now), contains('2025'));
    expect(dutchDateLabel(null, now: now), '');
  });

  test('날짜 내림차순으로 정렬한다', () {
    final a = _d([], date: '2026-10-01');
    final b = _d([], date: '2026-10-20');
    expect(
      dutchSorted([a, b], settled: false).first.dutchPayDate,
      '2026-10-20',
    );
  });
}
