// 증권 차트 WebView 높이 — 그래프 168 + 범례 두 줄 44 = 212.
// 웹 임베드가 범례를 자기 줄로 빼므로 앱 높이가 168 이면 그래프가 124 로 줄어든다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/stocks/presentation/chart_web_view.dart';

void main() {
  test('차트 WebView 높이 상수는 212 다', () {
    expect(kStockChartWebViewHeight, 212);
  });

  test('namu · toss 모두 상수를 쓰고 168 이 남지 않는다 (PSkeleton 포함)', () {
    for (final f in const [
      'lib/features/stocks/presentation/namu_stock_pages.dart',
      'lib/features/stocks/presentation/toss_stocks_view.dart',
    ]) {
      final src = File(f).readAsStringSync();
      expect(src.contains('kStockChartWebViewHeight'), isTrue, reason: f);
      expect(RegExp(r'height:\s*168\b').hasMatch(src), isFalse, reason: f);
    }
  });
}
