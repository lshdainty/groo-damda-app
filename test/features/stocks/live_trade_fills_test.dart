// 체결 테이프의 오름 · 내림 — 바로 앞(더 오래된) 체결과 견주고, 견줄 체결이 없는 가장 오래된 줄은 중립(dir 0)이다.
// 웹 detail-parts `fills`(groo-damda-front eeea9cdf)와 같은 규칙.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';

TossTrade _t(String price) => TossTrade(
  price: price,
  volume: '10',
  timestamp: '2026-11-06T10:00:00+09:00',
);

void main() {
  test('받은 것 중 가장 오래된 체결은 중립 — 오름으로 칠하지 않는다', () {
    // 새것 → 옛것 차례
    final fills = liveTradeFillsForTest([
      _t('75100'),
      _t('75000'),
      _t('75200'),
    ]);
    expect(fills.map((f) => f.dir).toList(), [1, -1, 0]);
  });

  test('체결이 하나뿐이면 그 줄도 중립', () {
    expect(liveTradeFillsForTest([_t('75100')]).single.dir, 0);
  });

  test('보이는 12줄 밖의 체결과도 견준다 — 12번째 줄은 13번째와 견준다', () {
    final trades = [
      for (var i = 0; i < 12; i++) _t('75100'),
      _t('75200'), // 13번째 — 보이지 않지만 12번째의 앞 체결
    ];
    final fills = liveTradeFillsForTest(trades);
    expect(fills, hasLength(12));
    expect(fills.last.dir, -1);
  });

  test('같은 가격은 오름(웹과 같다)', () {
    expect(liveTradeFillsForTest([_t('75100'), _t('75100')]).first.dir, 1);
  });
}
