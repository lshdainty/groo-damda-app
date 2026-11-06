// 앱 증권 체인 코드 검수(code-i13-app-chain.md) 중 13-1 몫 — 재조회 실패 · 시간 경과 · 백그라운드 · 전일 종가 · 통화 · KeepAlive.
// (사용자 지시: 만들기만 하고 로컬에서 돌리지 않는다 — CI 가 돈다)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/features/stocks/presentation/market_state.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/overrides.dart';

String _plain(Text w) => (w.data ?? w.textSpan?.toPlainText() ?? '')
    .replaceAll('⁠', '')
    .replaceAll('​', '');
Finder _t(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w) == s);
Finder _tc(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w).contains(s));

class _Fg extends AppForegroundNotifier {
  _Fg(this.initial);
  final bool initial;
  @override
  bool build() => initial;
  void set(bool v) => state = v;
}

TossCandle _c(String ts, String close) => TossCandle(
  timestamp: ts,
  openPrice: close,
  highPrice: close,
  lowPrice: close,
  closePrice: close,
  volume: '1',
);

TossHoldings _holdings() => TossHoldings(
  totalPurchaseAmount: '1000000',
  marketValueAmount: '1200000',
  profitLossAmount: '200000',
  profitLossRate: '20',
  dailyProfitLossAmount: '0',
  dailyProfitLossRate: '0',
  items: const [],
);

List<Override> _base({
  Future<TossHoldings?> Function()? holdings,
  Future<List<TossPrice>> Function(String)? prices,
  Future<TossStockInfo?> Function()? info,
  Future<TossOrderbook?> Function()? orderbook,
  void Function(String)? onCall,
  bool foreground = true,
  TossKrMarketCalendar? kr,
}) => [
  appForegroundProvider.overrideWith(() => _Fg(foreground)),
  tossHoldingsProvider.overrideWith((ref) async {
    onCall?.call('holdings');
    return holdings == null ? null : await holdings();
  }),
  tossExchangeRateProvider.overrideWith((ref) async {
    onCall?.call('fx');
    return const TossExchangeRate(rate: '1385.2');
  }),
  watchGroupsProvider.overrideWith((ref) async => <StockWatchGroup>[]),
  tossMarketCalendarKrProvider.overrideWith((ref) async {
    onCall?.call('calendarKr');
    return kr ?? TossKrMarketCalendar.fromJson(const {});
  }),
  tossMarketCalendarUsProvider.overrideWith(
    (ref) async => TossUsMarketCalendar.fromJson(const {}),
  ),
  tossIndicatorPricesProvider.overrideWith((ref) async {
    onCall?.call('indicators');
    return const [];
  }),
  tossIndicatorClosesProvider.overrideWith((ref, s) async => const <double>[]),
  tossPricesProvider.overrideWith((ref, key) async {
    onCall?.call('prices');
    return prices == null ? <TossPrice>[] : await prices(key);
  }),
  prevCloseProvider.overrideWith((ref, s) async => 73500.0),
  tossOrderbookProvider.overrideWith((ref, s) async {
    onCall?.call('orderbook');
    return orderbook == null ? null : await orderbook();
  }),
  tossTradesProvider.overrideWith((ref, s) async => null),
  tossCandlesProvider.overrideWith((ref, a) async => null),
  tossStockInfoProvider.overrideWith(
    (ref, s) async => info == null ? null : await info(),
  ),
  tossWarningsProvider.overrideWith((ref, s) async => <TossStockWarning>[]),
  tossPriceLimitsProvider.overrideWith((ref, s) async => null),
  tossBuyingPowerProvider.overrideWith(
    (ref, cur) async => BuyingPower(currency: cur, amount: 1),
  ),
  tossTodayCandlesProvider.overrideWith((ref, s) async {
    onCall?.call('today');
    return null;
  }),
  tossInvestorProvider.overrideWith((ref, s) async {
    onCall?.call('investor');
    return const <InvestorTradingDay>[];
  }),
  stockSearchProvider.overrideWith((ref, q) async => const []),
];

Widget _app(Widget home, List<Override> o) => ProviderScope(
  // 시험이 _base 뒤에 붙인 덮개가 이긴다 — riverpod 3 은 같은 provider 를 두 번 덮으면 멈춘다
  overrides: lastOverrideWins(o),
  child: MaterialApp(
    theme: GrooTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void _tall(WidgetTester t, {double h = 3000}) {
  t.view.physicalSize = Size(360 * 3, h * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Future<void> _run(WidgetTester t, int seconds) async {
  for (var i = 0; i < seconds * 2; i++) {
    await t.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  tearDown(() => stocksNow = DateTime.now);

  // ── H6 전일 종가 ─────────────────────────────────────────────────────────
  group('전일 종가 (H6) — 토스 봉은 최신순', () {
    test('내림차순(문서대로)이어도 오름차순이어도 같은 값', () {
      final desc = [
        _c('2026-10-29T09:00:00+09:00', '75000'),
        _c('2026-10-28T09:00:00+09:00', '73500'),
        _c('2026-10-27T09:00:00+09:00', '71000'),
      ];
      expect(prevCloseFromCandles(desc, '2026-10-29'), 73500);
      expect(prevCloseFromCandles(desc.reversed.toList(), '2026-10-29'), 73500);
    });
    test('장 시작 전 — 오늘 봉이 아직 없으면 가장 최근 봉이 전일', () {
      final c = [_c('2026-10-28', '73500'), _c('2026-10-27', '71000')];
      expect(prevCloseFromCandles(c, '2026-10-29'), 73500);
    });
    test('오늘 봉뿐이거나 비었으면 null — 이틀 전 종가를 전일로 읽지 않는다', () {
      expect(
        prevCloseFromCandles([_c('2026-10-29', '75000')], '2026-10-29'),
        isNull,
      );
      expect(prevCloseFromCandles(const [], '2026-10-29'), isNull);
    });
    test('0 이하 · 못 읽는 종가는 null', () {
      expect(
        prevCloseFromCandles([_c('2026-10-28', '0')], '2026-10-29'),
        isNull,
      );
      expect(
        prevCloseFromCandles([_c('2026-10-28', 'x')], '2026-10-29'),
        isNull,
      );
    });
    test('오프셋이 붙은 봉은 순간 → 시장 날짜(미국 일봉 +09:00 은 한국 낮이어도 현지는 전날)', () {
      // 2026-10-29T09:00+09:00 = 현지(동부) 10-28 20:00 → 미국 종목에서 "오늘(10-29)" 이전 봉
      final c = [_c('2026-10-29T09:00:00+09:00', '241')];
      expect(prevCloseFromCandles(c, '2026-10-29', symbol: 'AAPL'), 241);
      expect(prevCloseFromCandles(c, '2026-10-29', symbol: '005930'), isNull);
    });
    test('시장의 오늘 — 한국 새벽 3시 미국 종목은 아직 전날(동부), 국내는 한국 날짜', () {
      // 2026-10-30 03:00 KST = 2026-10-29 18:00 UTC
      final now = DateTime.utc(2026, 10, 29, 18);
      expect(marketToday('AAPL', now), '2026-10-29');
      expect(marketToday('005930', now), '2026-10-30');
    });
    test('미국 장중 한국 0~5시 — 오늘(현지) 봉은 전일이 아니다', () {
      final desc = [
        _c('2026-10-29', '231'), // 진행 중인 현지 10-29 봉
        _c('2026-10-28', '241'),
      ];
      final today = marketToday('AAPL', DateTime.utc(2026, 10, 29, 18));
      expect(prevCloseFromCandles(desc, today), 241);
    });
  });

  group('체결 시각 — 오프셋은 한국 시각으로, 없으면 벽시계 (웹 tradeClock)', () {
    test('Z · -04:00 · +09:00', () {
      expect(clock12Minutes('2026-10-29T14:11:12Z'), '오후 11:11');
      expect(clock12Minutes('2026-10-29T10:11:12-04:00'), '오후 11:11');
      expect(clock12Minutes('2026-10-29T23:11:12+09:00'), '오후 11:11');
    });
    test('오프셋 없는 글은 그대로', () {
      expect(clock12Minutes('10:11:12'), '오전 10:11');
    });
  });

  group('거래소 표 — KR_ETC · US_ETC (웹과 한 벌)', () {
    test('국내 기타 · 미국 기타', () {
      final l = AppLocalizationsKo();
      expect(stockMarketLabel(l, 'KR_ETC'), '국내 기타');
      expect(stockMarketLabel(l, 'US_ETC'), '미국 기타');
    });
  });

  // ── H2 재조회 실패에도 값을 둔다 ─────────────────────────────────────────
  testWidgets('H2 폴링 한 번 실패해도 평가금액이 0원이 되지 않는다', (tester) async {
    _tall(tester);
    var n = 0;
    await tester.pumpWidget(
      _app(
        const Scaffold(body: TossStocksView()),
        _base(
          holdings: () async {
            n++;
            if (n >= 2) throw StateError('x');
            return _holdings();
          },
        ),
      ),
    );
    await _run(tester, 2);
    expect(_tc('1,200,000원'), findsWidgets);
    await _run(tester, 12); // 10초 타이머가 재조회 → 실패
    expect(n, greaterThanOrEqualTo(2));
    expect(_tc('1,200,000원'), findsWidgets, reason: '이전 값이 남는다');
    expect(_t('0원'), findsNothing);
    expect(_t('내 투자를 불러오지 못했어요'), findsNothing);
  });

  // ── H3 시장 띠가 굳지 않는다 ──────────────────────────────────────────────
  testWidgets('H3 지수 · 환율은 60초마다, 달력은 5분마다 다시 받는다', (tester) async {
    _tall(tester);
    final calls = <String, int>{};
    await tester.pumpWidget(
      _app(
        const Scaffold(body: TossStocksView()),
        _base(onCall: (k) => calls[k] = (calls[k] ?? 0) + 1),
      ),
    );
    await _run(tester, 2);
    calls.clear();
    await _run(tester, 125);
    expect(calls['indicators'], greaterThanOrEqualTo(2));
    expect(calls['fx'], greaterThanOrEqualTo(2));
    expect(calls['calendarKr'] ?? 0, 0);
    await _run(tester, 200);
    expect(calls['calendarKr'], greaterThanOrEqualTo(1));
  });

  testWidgets('H3 앱을 켜 둔 채 날짜가 바뀌면 달력을 새로 받는다', (tester) async {
    _tall(tester);
    final calls = <String, int>{};
    stocksNow = () => DateTime.utc(2026, 10, 29, 3); // 한국 10-29 12:00
    final kr = TossKrMarketCalendar.fromJson(const {
      'today': {'date': '2026-10-29'},
    });
    await tester.pumpWidget(
      _app(
        const Scaffold(body: TossStocksView()),
        _base(kr: kr, onCall: (k) => calls[k] = (calls[k] ?? 0) + 1),
      ),
    );
    await _run(tester, 2);
    calls.clear();
    stocksNow = () => DateTime.utc(2026, 10, 30, 3); // 다음 날
    await _run(tester, 35); // 30초 tick
    expect(calls['calendarKr'], greaterThanOrEqualTo(1));
  });

  // ── H4 백그라운드에서는 멈춘다 ───────────────────────────────────────────
  testWidgets('H4 앱이 뒤로 가 있으면 목록 폴링이 멈추고, 돌아오면 바로 다시 받는다', (tester) async {
    _tall(tester);
    final calls = <String, int>{};
    late ProviderContainer container;
    await tester.pumpWidget(
      _app(
        const Scaffold(body: TossStocksView()),
        _base(foreground: false, onCall: (k) => calls[k] = (calls[k] ?? 0) + 1),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(TossStocksView)),
    );
    await _run(tester, 2);
    calls.clear();
    await _run(tester, 70);
    expect(calls['holdings'] ?? 0, 0);
    expect(calls['indicators'] ?? 0, 0);
    (container.read(appForegroundProvider.notifier) as _Fg).set(true);
    await _run(tester, 2);
    expect(calls['holdings'], greaterThanOrEqualTo(1), reason: '돌아오면 바로');
  });

  // ── M8 · M9 · M10 상세 ───────────────────────────────────────────────────
  group('상세 — 시세 실패 · 거래상태 · 통화', () {
    Future<void> pump(WidgetTester t, List<Override> o) async {
      _tall(t);
      await t.pumpWidget(_app(const TossStockDetailPage(symbol: 'A1'), o));
      await _run(t, 2);
    }

    testWidgets('M8 시세 조회가 실패하면 "토스 시세 미지원" 을 띄우지 않는다', (tester) async {
      await pump(tester, _base(prices: (_) async => throw StateError('x')));
      expect(_tc('미지원'), findsNothing);
      expect(_t('시세를 불러오지 못했어요'), findsOneWidget);
      expect(_t('다시 시도'), findsWidgets);
      // 웹 BandFailure 와 같은 Result Section — 아이콘 · 제목 · 설명 · [다시 시도] (구역 안 = medium)
      expect(_t('잠시 뒤 다시 시도해주세요.'), findsWidgets);
      expect(find.byType(PResultSection), findsWidgets);
    });

    testWidgets('M8 응답은 왔는데 값이 없으면 "미지원"', (tester) async {
      await pump(tester, _base(prices: (_) async => <TossPrice>[]));
      expect(_tc('미지원'), findsOneWidget);
    });

    testWidgets('M9 정보가 없으면(빈 응답) 거래상태 "정상" 을 지어내지 않는다', (tester) async {
      await pump(tester, _base());
      expect(_t('정상'), findsNothing);
    });

    testWidgets('M9 미국 종목(koreanMarketDetail 없음)은 거래상태 줄을 뺀다', (tester) async {
      await pump(
        tester,
        _base(
          info: () async => TossStockInfo.fromJson(const {
            'symbol': 'A1',
            'name': 'A',
            'market': 'NASDAQ',
            'securityType': 'STOCK',
            'status': 'NORMAL',
            'currency': 'USD',
          }),
        ),
      );
      expect(_t('정상'), findsNothing);
      expect(_t('거래상태'), findsNothing);
    });

    testWidgets('M9 국내 종목 정보가 있으면 정상 · 거래정지가 보인다', (tester) async {
      await pump(
        tester,
        _base(
          info: () async => TossStockInfo.fromJson(const {
            'symbol': 'A1',
            'name': '가',
            'market': 'KOSPI',
            'securityType': 'STOCK',
            'status': 'NORMAL',
            'currency': 'KRW',
            'koreanMarketDetail': {'krxTradingSuspended': false},
          }),
        ),
      );
      expect(_t('정상'), findsOneWidget);
    });

    testWidgets('M10 통화를 모르면 "원" 을 붙이지 않는다(숫자만)', (tester) async {
      await pump(
        tester,
        _base(
          prices: (_) async => [
            const TossPrice(symbol: 'A1', lastPrice: '190'),
          ],
          orderbook: () async => const TossOrderbook(
            asks: [TossOrderbookEntry(price: '190', volume: '10')],
            bids: [TossOrderbookEntry(price: '189', volume: '20')],
          ),
        ),
      );
      expect(_tc('190원'), findsNothing);
      expect(_t('190'), findsWidgets);
    });

    testWidgets('N6 앱이 뒤로 가 있으면 오늘 시세 60초 타이머가 돌지 않는다', (tester) async {
      final calls = <String>[];
      await pump(tester, _base(onCall: calls.add, foreground: false));
      final first = calls.where((c) => c == 'today').length;
      await _run(tester, 130);
      expect(
        calls.where((c) => c == 'today').length,
        first,
        reason: '앱을 내렸는데 일봉을 불렀다',
      );
    });

    testWidgets('N7 통화를 모르는 동안 투자자별을 부르지 않고 일별 시세에 "원" 을 붙이지 않는다', (
      tester,
    ) async {
      final calls = <String>[];
      await pump(tester, [
        ..._base(
          onCall: calls.add,
          prices: (_) async => [
            const TossPrice(symbol: 'A1', lastPrice: '190'),
          ],
        ),
        tossCandlesProvider.overrideWith(
          (ref, a) async => TossCandlePage(
            candles: [
              for (var d = 20; d <= 28; d++)
                TossCandle(
                  timestamp: '2026-10-${d}T00:00:00-04:00',
                  openPrice: '1',
                  highPrice: '1',
                  lowPrice: '1',
                  closePrice: '${190 + d}',
                  volume: '10',
                ),
            ],
          ),
        ),
      ]);
      expect(
        calls,
        isNot(contains('investor')),
        reason: '통화를 모르는 미국 종목으로 투자자별이 나갔다',
      );
      expect(_tc('원'), findsNothing, reason: '통화를 모르는데 "원" 이 붙었다');
    });

    testWidgets('M10 시세 응답의 통화(USD)를 쓴다', (tester) async {
      await pump(
        tester,
        _base(
          prices: (_) async => [
            const TossPrice(symbol: 'A1', lastPrice: '189.52', currency: 'USD'),
          ],
        ),
      );
      expect(_tc(r'$189.52'), findsWidgets);
    });

    testWidgets('M2 키-값 줄은 ds List 높이 그대로(덮어쓴 여백 없음)', (tester) async {
      await pump(
        tester,
        _base(
          info: () async => TossStockInfo.fromJson(const {
            'symbol': 'A1',
            'name': '가',
            'market': 'KOSPI',
            'securityType': 'STOCK',
            'status': 'NORMAL',
            'currency': 'KRW',
          }),
        ),
      );
      final items = tester.widgetList<PListItem>(find.byType(PListItem));
      expect(items, isNotEmpty);
      expect(items.every((i) => i.verticalPadding == null), isTrue);
    });
  });

  // ── M13 스크롤 왕복에도 고른 탭을 지킨다 ──────────────────────────────────
  testWidgets('M13 호가 · 체결의 고른 탭이 스크롤을 오가도 유지된다', (tester) async {
    _tall(tester, h: 700);
    await tester.pumpWidget(
      _app(const TossStockDetailPage(symbol: 'A1'), [
        ..._base(
          orderbook: () async => const TossOrderbook(
            asks: [TossOrderbookEntry(price: '75100', volume: '10')],
            bids: [TossOrderbookEntry(price: '75000', volume: '20')],
          ),
        ),
        // 체결이 있어야 체결 탭에 '체결시각' 머리가 선다(없으면 "체결 내역이 없어요")
        tossTradesProvider.overrideWith(
          (ref, s) async => const [
            TossTrade(price: '75100', volume: '3', timestamp: '10:11:12'),
          ],
        ),
      ]),
    );
    await _run(tester, 2);
    await tester.scrollUntilVisible(
      _t('체결'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(_t('체결'));
    await _run(tester, 1);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2500));
    await _run(tester, 1);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2500));
    await _run(tester, 1);
    await tester.scrollUntilVisible(
      _t('체결시각'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_t('체결시각'), findsOneWidget, reason: '호가로 돌아가지 않는다');
  });
}
