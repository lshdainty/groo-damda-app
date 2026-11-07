// 거래 시각 · 확인창 날짜 — 화면에 ISO("2026-10-10 14:30")를 그대로 내지 않는다(DESIGN.desk.md 날짜: 요일 · 오전/오후 12시간).
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';

AssetTrade _t(String? date) => AssetTrade(
  rowId: 1,
  assetRowId: 2,
  tradeType: 'BUY',
  holdingKey: 'SPY',
  tradeDate: date,
);

void main() {
  setUpAll(() async => initializeDateFormatting());

  test('거래 시각 — 날짜 규칙 + 오전 · 오후 12시간', () {
    final year = DateTime.now().year;
    // 올해 날짜로 만들어 연도 없는 꼴을 본다
    final d = DateTime(year, 10, 10, 14, 30);
    final text = tradeDateTimeText(_t('$year-10-10T14:30:00'));
    expect(text, contains('10월 10일'));
    expect(text, contains('(${'월화수목금토일'[d.weekday - 1]})'));
    expect(text, endsWith('오후 2:30'));
    expect(text, isNot(contains('-')));
    expect(tradeDateTimeText(_t('$year-10-10T00:05:00')), endsWith('오전 12:05'));
  });

  test('읽지 못하는 값은 서버 값 그대로', () {
    expect(tradeDateTimeText(_t(null)), '');
    expect(tradeDateTimeText(_t('이상한 값')), '이상한 값');
  });

  test('확인창 날짜 — "10월 10일"', () {
    final year = DateTime.now().year;
    expect(tradeDateLabel(_t('$year-10-10T14:30:00')), '10월 10일');
    expect(tradeDateLabel(_t('2001-12-31T14:30:00')), '2001년 12월 31일');
    expect(tradeDateLabel(_t('몰라')), '몰라');
  });

  test('거래 기록 줄 날짜 — 올해는 연도 없이, 다른 해는 연도 붙여', () {
    final year = DateTime.now().year;
    expect(tradeRowDate(_t('$year-10-10T14:30:00')), '10월 10일');
    expect(tradeRowDate(_t('2001-10-10T14:30:00')), '2001년 10월 10일');
    expect(tradeRowDate(_t('몰라')), '몰라');
  });
}
