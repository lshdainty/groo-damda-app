// 거래 나누기 금액 셈 — 합이 늘 총액과 같고, 균등 분배의 나머지는 첫 항목이다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/expense_split/domain/split_math.dart';

void main() {
  test('균등 분배: 나머지는 첫 항목', () {
    expect(evenAmounts(3, 10000), [3334, 3333, 3333]);
    expect(evenAmounts(2, 9999), [5000, 4999]);
    expect(evenAmounts(0, 100), isEmpty);
  });

  test('비례 배분: 합이 새 총액과 같다', () {
    final out = proportionalAmounts([30000, 10000], 50000);
    expect(out.fold<int>(0, (s, v) => s + v), 50000);
    expect(out[0] > out[1], isTrue);
  });

  test('큰 항목 반영: 모자란 만큼 가장 큰 항목에 싣는다', () {
    expect(toLargestAmounts([30000, 10000], 45000), [35000, 10000]);
  });

  test('큰 항목 반영: 넘치면 큰 항목부터 덜고 1 이하로는 내리지 않는다', () {
    final out = toLargestAmounts([30000, 10000], 20000);
    expect(out.fold<int>(0, (s, v) => s + v), 20000);
    expect(out.every((v) => v >= 1), isTrue);
  });
}
