// 더치페이 몫 셈(I-21 G 40) — 남는 원은 결제자(나)의 몫이고, 비율 1:1:1 도 합이 총액과 같다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/dutch_pay/domain/dutch_shares.dart';

void main() {
  test('N분의 1: 내림을 모두에게, 나머지는 결제자에게', () {
    final s = computeDutchShares(
      total: 10000,
      method: DutchSplitMethod.equal,
      count: 3,
      payerIndex: 0,
    );
    expect(s.shares, [3334, 3333, 3333]);
    expect(s.sum, 10000);
  });

  test('비율 1:1:1 — 합이 1원 모자라지 않는다(나머지는 결제자)', () {
    final s = computeDutchShares(
      total: 10000,
      method: DutchSplitMethod.ratio,
      count: 3,
      payerIndex: 1,
      ratios: ['1', '1', '1'],
    );
    expect(s.shares, [3333, 3334, 3333]);
    expect(s.sum, 10000);
  });

  test('비율은 소수 몫도 정수로 셈한다', () {
    final s = computeDutchShares(
      total: 1000,
      method: DutchSplitMethod.ratio,
      count: 2,
      payerIndex: 0,
      ratios: ['1.5', '1'],
    );
    expect(s.shares, [600, 400]);
  });

  test('나 포함을 끄면 남는 원이 내 몫(payerOut)', () {
    final s = computeDutchShares(
      total: 10000,
      method: DutchSplitMethod.equal,
      count: 3,
      payerIndex: -1,
    );
    expect(s.shares, [3333, 3333, 3333]);
    expect(s.payerOut, 1);
    expect(s.sum, 10000);
  });

  test('개별 금액: 결제자는 총액 − 다른 사람 합', () {
    final s = computeDutchShares(
      total: 10000,
      method: DutchSplitMethod.custom,
      count: 3,
      payerIndex: 0,
      customs: [0, 2000, 3000],
    );
    expect(s.shares, [5000, 2000, 3000]);
  });

  test('M 셈 표: 100원 · 0.71 / 0.29 → 71 / 29', () {
    final s = computeDutchShares(
      total: 100,
      method: DutchSplitMethod.ratio,
      count: 2,
      payerIndex: 0,
      ratios: ['0.71', '0.29'],
    );
    expect(s.shares, [71, 29]);
  });

  test('M 셈 표: 1,234,567,890 ÷ 4 → 나머지 2원은 결제자', () {
    final s = computeDutchShares(
      total: 1234567890,
      method: DutchSplitMethod.equal,
      count: 4,
      payerIndex: 0,
    );
    expect(s.shares, [308641974, 308641972, 308641972, 308641972]);
    expect(s.sum, 1234567890);
  });

  test('M 셈 표: 184,000 ÷ 3 → 61,334 / 61,333 / 61,333', () {
    final s = computeDutchShares(
      total: 184000,
      method: DutchSplitMethod.equal,
      count: 3,
      payerIndex: 0,
    );
    expect(s.shares, [61334, 61333, 61333]);
  });

  test('M 셈 표: 2몫 — 나 1 · 김가람 2', () {
    final s = computeDutchShares(
      total: 10000,
      method: DutchSplitMethod.ratio,
      count: 2,
      payerIndex: 0,
      ratios: ['1', '2'],
    );
    expect(s.shares, [3334, 6666]);
  });

  test('큰 금액(100억)도 넘치지 않는다', () {
    final s = computeDutchShares(
      total: 10000000000,
      method: DutchSplitMethod.ratio,
      count: 2,
      payerIndex: 0,
      ratios: ['1000000', '1000000'],
    );
    expect(s.shares, [5000000000, 5000000000]);
  });
}
