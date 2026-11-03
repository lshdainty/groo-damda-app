// 호가 표 잔량 — 글자를 줄여 맞추지 않고(FittedBox 없음) 쉼표 뒤에서만 줄을 바꾼다.
// 소스 · 위젯 두 겹으로 잠근다. DESIGN.md "금액이 칸보다 길면 쉼표 뒤에서만 줄을 바꾼다".
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

void main() {
  test('호가 표 소스에 FittedBox · scaleDown 이 없다', () {
    final src = File(
      'lib/features/stocks/presentation/toss_stocks_view.dart',
    ).readAsStringSync();
    final start = src.indexOf('class _OrderBook extends');
    final end = src.indexOf('class _OrderBookHead');
    final body = src.substring(start, end);
    expect(body.contains('FittedBox'), isFalse);
    expect(body.contains('scaleDown'), isFalse);
    expect(body.contains('keepAllAmount(krw(q))'), isTrue);
  });

  testWidgets('잔량 글은 쉼표 뒤 U+200B 문자열이고 큰 글자에서 여러 줄이 된다', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const book = TossOrderbook(
      asks: [TossOrderbookEntry(price: '70500', volume: '12345678')],
      bids: [TossOrderbookEntry(price: '70400', volume: '1234567')],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(
            c,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: OrderBookForTest(
              currency: 'KRW',
              lastPrice: 70450,
              book: book,
              changePct: 1.2,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(FittedBox), findsNothing);
    final want = keepAllAmount('12,345,678');
    expect(want.contains(',​'), isTrue);
    final t = tester.widget<Text>(find.text(want));
    expect(t.softWrap, isNot(false));
    expect(t.maxLines, isNull);
    // 줄이 늘면 칸(행)이 따라 커진다 — 한 줄 글(345)보다 세 줄 글이 더 높다
    expect(
      tester.getSize(find.text(want)).height,
      greaterThan(
        tester.getSize(find.text(keepAllAmount('1,234,567'))).height - 1,
      ),
    );
  });
}
