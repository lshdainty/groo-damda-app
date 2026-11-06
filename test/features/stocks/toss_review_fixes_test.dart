// 13-1 앱 코드 검수 고침(H1~H5 · M2 ~ M7 · M15 · M18)의 회귀 시험 — 결함을 잡는 단언 · 경계 값.
// (사용자 지시 10-30: 만들기만 하고 로컬에서 돌리지 않는다 — CI 가 돈다)
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/stocks_repository.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_screen.dart';
import 'package:groo_damda_app/features/stocks/presentation/market_state.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_donut.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import '../../support/overrides.dart';
import '../../support/plain_text.dart';
import '../../support/semantics.dart';

// ── 공용 ────────────────────────────────────────────────────────────────────
String _plain(Text w) => (w.data ?? w.textSpan?.toPlainText() ?? '')
    .replaceAll('⁠', '')
    .replaceAll('​', '');
Finder _t(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w) == s);
Finder _tc(String s) =>
    find.byWidgetPredicate((w) => w is Text && _plain(w).contains(s));
Finder _chip(String s) => find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == 'ChipVisual' && (w as dynamic).label == s,
);

TossHoldingsItem _item(
  String symbol,
  String currency,
  String mv, {
  String pl = '685.55',
  String day = '-12.5',
}) => TossHoldingsItem(
  symbol: symbol,
  name: symbol,
  marketCountry: currency == 'USD' ? 'US' : 'KR',
  currency: currency,
  quantity: '24000',
  lastPrice: '75000',
  averagePurchasePrice: '68200',
  marketValueAmount: mv,
  profitLossAmount: pl,
  profitLossRate: '12.46',
  dailyProfitLossAmount: day,
  dailyProfitLossRate: '-0.2',
  purchaseAmount: '5500',
  commission: '0',
  tax: '0',
);

TossHoldings _holdings(List<TossHoldingsItem> items) => TossHoldings(
  totalPurchaseAmount: '1000',
  marketValueAmount: '2000',
  profitLossAmount: '1000',
  profitLossRate: '10',
  dailyProfitLossAmount: '0',
  dailyProfitLossRate: '0',
  items: items,
);

StockWatchGroup _group(int id, String name, int n) => StockWatchGroup(
  rowId: id,
  groupName: name,
  sortOrder: id,
  items: [
    for (var i = 0; i < n; i++)
      WatchItem(
        rowId: id * 100 + i,
        stockMasterRowId: 1,
        countryCode: 'KR',
        marketCode: 'KOSPI',
        symbol: 'S$id$i',
        nameKr: '종목 $id-$i',
        securityType: 'STOCK',
        currency: 'KRW',
      ),
  ],
);

final _emptyKr = TossKrMarketCalendar.fromJson(const {});
final _emptyUs = TossUsMarketCalendar.fromJson(const {});

/// 상세 · 목록이 부르는 provider 를 전부 덮는다 — 빠뜨리면 저장소 시도로 시험이 깨진다.
List<Override> _base({
  TossHoldings? holdings,
  bool masked = false,
  Future<TossOrderbook?> Function()? orderbook,
  Future<List<TossTrade>?> Function()? trades,
  Future<TossCandlePage?> Function()? candles,
  Future<TossStockInfo?> Function()? info,
  double? prevClose = 73500,
  double lastPrice = 75000,
  void Function(String)? onCall,
}) => [
  tossHoldingsProvider.overrideWith((ref) async {
    onCall?.call('holdings');
    return holdings;
  }),
  tossExchangeRateProvider.overrideWith(
    (ref) async => const TossExchangeRate(rate: '1385.2'),
  ),
  watchGroupsProvider.overrideWith((ref) async => <StockWatchGroup>[]),
  tossMarketCalendarKrProvider.overrideWith((ref) async => _emptyKr),
  tossMarketCalendarUsProvider.overrideWith((ref) async => _emptyUs),
  tossIndicatorPricesProvider.overrideWith((ref) async => const []),
  tossIndicatorClosesProvider.overrideWith((ref, s) async => const <double>[]),
  tossPricesProvider.overrideWith((ref, key) async {
    onCall?.call('prices');
    return [
      for (final s in key.split(',').where((e) => e.isNotEmpty))
        TossPrice(symbol: s, lastPrice: '$lastPrice', currency: 'KRW'),
    ];
  }),
  prevCloseProvider.overrideWith((ref, s) async => prevClose),
  tossOrderbookProvider.overrideWith((ref, s) async {
    onCall?.call('orderbook');
    return orderbook == null ? null : await orderbook();
  }),
  tossTradesProvider.overrideWith((ref, s) async {
    onCall?.call('trades');
    return trades == null ? null : await trades();
  }),
  tossCandlesProvider.overrideWith((ref, a) async {
    onCall?.call('candles-${a.interval}');
    return candles == null ? null : await candles();
  }),
  tossStockInfoProvider.overrideWith((ref, s) async {
    return info == null ? null : await info();
  }),
  tossWarningsProvider.overrideWith((ref, s) async => <TossStockWarning>[]),
  tossPriceLimitsProvider.overrideWith((ref, s) async => null),
  // 13b-1 — 주문 가능 · 오늘 시세(일봉 3봉) · 투자자별. 빠뜨리면 저장소 길을 탄다.
  tossBuyingPowerProvider.overrideWith((ref, cur) async {
    onCall?.call('buyingPower');
    return BuyingPower(currency: cur, amount: 1000);
  }),
  tossTodayCandlesProvider.overrideWith((ref, s) async => null),
  tossInvestorProvider.overrideWith((ref, s) async => const []),
  stockSearchProvider.overrideWith((ref, q) async => const []),
  if (masked) hideCardProvider.overrideWith((ref, card) => true),
];

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
  // 시험이 _base 뒤에 붙인 덮개가 이긴다 — riverpod 3 은 같은 provider 를 두 번 덮으면 멈춘다
  overrides: lastOverrideWins(overrides),
  child: MaterialApp(
    theme: GrooTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Future<void> _tall(WidgetTester t, {double h = 4000}) async {
  t.view.physicalSize = Size(360 * 3, h * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Future<void> _settle(WidgetTester t, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 250; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  // ── 모델 · 순수 함수 ─────────────────────────────────────────────────────
  group('체결 시각 12시간 (M15)', () {
    test('오전 · 오후 · 정오 · 자정 경계', () {
      expect(clock12Minutes('10:11:12'), '오전 10:11');
      expect(clock12Minutes('13:00:05'), '오후 1:00');
      expect(clock12Minutes('12:59:59'), '오후 12:59');
      expect(clock12Minutes('12:00:00'), '오후 12:00');
      expect(clock12Minutes('00:00:09'), '오전 12:00');
      expect(clock12Minutes('23:59:59'), '오후 11:59');
    });
    test('ISO 글에서도 시각만 읽고, 못 읽으면 받은 글 그대로', () {
      expect(clock12Minutes('2026-10-29T13:00:05'), '오후 1:00');
      expect(clock12Minutes('없음'), '없음');
      expect(clock12Minutes('25:00:00'), '25:00:00');
    });
  });

  group('장 상태 — 세션은 한국 시각 오프셋 ISO(토스 OpenAPI), 보이는 시각도 한국 시각 (M6)', () {
    late AppLocalizationsKo l;
    setUp(() => l = AppLocalizationsKo());
    // 미국 정규장 — 자정을 넘는다(UsRegularMarketSession example)
    const us = TossMarketSession(
      startTime: '2026-10-29T22:30:00+09:00',
      endTime: '2026-10-30T05:00:00+09:00',
    );
    const kr = TossMarketSession(
      startTime: '2026-10-29T09:00:00+09:00',
      endTime: '2026-10-29T15:30:00+09:00',
    );
    // 한국 시각 → UTC 순간
    DateTime kst(int d, int h, int m) =>
        DateTime.utc(2026, 10, d, h, m).subtract(const Duration(hours: 9));

    test('개장 전은 한국 시각 그대로 "개장 오후 10:30" — 이중 변환 없음', () {
      expect(marketStateAt(us, kst(29, 13, 0), l).detail, '개장 오후 10:30');
    });
    test('자정을 넘기는 장중 — 한국 새벽 3시도 열려 있다', () {
      final r = marketStateAt(us, kst(30, 3, 0), l);
      expect(r.open, isTrue);
      expect(r.detail, contains('오전 3:00'));
    });
    test('경계 — 시작 정각 열림, 끝 정각까지 열림, 끝 1분 뒤 장마감', () {
      expect(marketStateAt(us, kst(29, 22, 30), l).open, isTrue);
      expect(marketStateAt(us, kst(30, 5, 0), l).open, isTrue);
      expect(marketStateAt(us, kst(30, 5, 1), l).detail, '장마감');
    });
    test('국내 장 전 · 중 · 끝', () {
      expect(marketStateAt(kr, kst(29, 8, 59), l).detail, '개장 오전 9:00');
      expect(marketStateAt(kr, kst(29, 13, 0), l).detail, contains('오후 1:00'));
      expect(marketStateAt(kr, kst(29, 15, 31), l).detail, '장마감');
    });
    test('옛 "HH:MM:SS" 글은 그날 한국 시각으로 읽는다(오프셋 없는 자정 넘김 포함)', () {
      const old = TossMarketSession(startTime: '22:30:00', endTime: '05:00:00');
      expect(marketStateAt(old, kst(29, 13, 0), l).detail, '개장 오후 10:30');
      expect(marketStateAt(old, kst(29, 23, 0), l).open, isTrue);
      expect(marketStateAt(old, kst(30, 3, 0), l).open, isTrue);
    });
    test('세션이 없으면 휴장', () {
      expect(marketStateAt(null, kst(29, 13, 0), l).detail, '휴장');
    });
  });

  // ── H1 · M4 · M5 · H2 · M15 · M18: 상세 ─────────────────────────────────
  group('상세 화면', () {
    testWidgets('H1 미국 보유의 손익은 원이 아니라 달러로 나온다', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _app(
          const TossStockDetailPage(symbol: 'MOA'),
          _base(holdings: _holdings([_item('MOA', 'USD', '6185.55')])),
        ),
      );
      await _settle(tester);
      expect(_tc(r'$685.55'), findsWidgets, reason: '평가손익 ▲ \$685.55');
      expect(_tc(r'$12.50'), findsWidgets, reason: '일간 손익 ▼ \$12.50');
      expect(_tc('686원'), findsNothing, reason: '달러를 반올림해 원으로 그리던 결함');
      expect(_tc('13원'), findsNothing);
    });

    testWidgets('M5 머리 증감에 금액이 있다 — 전일 종가 대비 ▲ 1,500원 · 2.04%', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _app(
          const TossStockDetailPage(symbol: 'A1'),
          _base(prevClose: 73500, lastPrice: 75000),
        ),
      );
      await _settle(tester);
      expect(_tc('1,500원 · 2.04%'), findsOneWidget);
    });

    testWidgets('M4 전일 종가가 없으면 등락 자리를 비운다 — 가짜 0.00% 없음', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _app(
          const TossStockDetailPage(symbol: 'A1'),
          _base(
            prevClose: null,
            orderbook: () async => const TossOrderbook(
              asks: [TossOrderbookEntry(price: '75100', volume: '10')],
              bids: [TossOrderbookEntry(price: '75000', volume: '20')],
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_tc('0.00%'), findsNothing);
      expect(_tc('변화 없음'), findsNothing);
    });

    testWidgets('H2 호가 실패는 비어 있음이 아니라 실패 한 벌 + 다시 시도', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _app(
          const TossStockDetailPage(symbol: 'A1'),
          _base(orderbook: () async => throw StateError('x')),
        ),
      );
      await _settle(tester);
      expect(_t('호가를 불러오지 못했어요'), findsOneWidget);
      expect(_t('호가 정보가 없어요'), findsNothing);
      expect(_t('다시 시도'), findsWidgets);
      expect(_tc('StateError'), findsNothing, reason: '오류 원문은 그리지 않는다');
    });

    testWidgets('H2 체결 · 일별 시세 · 기본 정보 실패도 각자 실패 한 벌', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _app(
          const TossStockDetailPage(symbol: 'A1'),
          _base(
            trades: () async => throw StateError('x'),
            candles: () async => throw StateError('x'),
            info: () async => throw StateError('x'),
          ),
        ),
      );
      await _settle(tester);
      expect(_t('일별 시세를 불러오지 못했어요'), findsOneWidget);
      expect(_t('기본 정보를 불러오지 못했어요'), findsOneWidget);
      expect(_t('정상'), findsNothing, reason: '정보 실패를 "정상" 으로 그리지 않는다');
      await tester.tap(_chip('체결').evaluate().isEmpty ? _t('체결') : _chip('체결'));
      await _settle(tester);
      expect(_t('체결 내역을 불러오지 못했어요'), findsOneWidget);
      expect(_t('체결 내역이 없어요'), findsNothing);
    });

    testWidgets('M15 · M18 체결 가격은 원 · 시각은 12시간, 호가 줄은 한 줄로 읽는다', (
      tester,
    ) async {
      await _tall(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const TossStockDetailPage(symbol: 'A1'),
          _base(
            orderbook: () async => const TossOrderbook(
              asks: [TossOrderbookEntry(price: '75100', volume: '4259')],
              bids: [TossOrderbookEntry(price: '75000', volume: '3986')],
            ),
            trades: () async => const [
              TossTrade(price: '71150', volume: '7', timestamp: '13:00:05'),
            ],
          ),
        ),
      );
      await _settle(tester);
      // 호가 — 가격에 원, 줄 읽기에 매도/매수 쪽 + 잔량
      expect(_t('75,100원'), findsOneWidget);
      expect(findSemanticsContaining('매도 75,100원, 잔량 4,259'), findsOneWidget);
      expect(findSemanticsContaining('매수 75,000원, 잔량 3,986'), findsOneWidget);
      expect(findSemanticsContaining('호가 표'), findsOneWidget);
      await tester.tap(_t('체결'));
      await _settle(tester);
      expect(_t('71,150원'), findsOneWidget);
      expect(_t('오후 1:00'), findsOneWidget);
      expect(findSemanticsContaining('오후 1:00, 71,150원, 수량 7'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('H3 상세에 있는 동안 호출은 한 벌 — 일별 캔들은 다시 받지 않는다', (tester) async {
      await _tall(tester);
      final calls = <String, int>{};
      void hit(String k) => calls[k] = (calls[k] ?? 0) + 1;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: TossStocksView()),
          ),
          GoRoute(
            path: '/stocks/toss/:symbol',
            builder: (_, s) =>
                TossStockDetailPage(symbol: s.pathParameters['symbol']!),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: lastOverrideWins([
            ..._base(onCall: hit),
            watchGroupsProvider.overrideWith(
              (ref) async => [_group(1, '반도체', 3)],
            ),
          ]),
          child: MaterialApp.router(
            routerConfig: router,
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await _settle(tester, 1000);
      await tester.tap(_chip('관심'));
      await _settle(tester, 2000);
      router.push('/stocks/toss/A1');
      await _settle(tester, 2000);
      calls.clear();
      await _settle(tester, 60000);
      // 10초 주기 × 60초 = 6번. 목록 타이머가 같이 돌면 12번(두 배)이었다.
      expect(calls['orderbook'], lessThanOrEqualTo(6));
      // 체결은 체결 탭을 고를 때만 지켜본다(I-13b 21) — 호가 탭에서는 0
      expect(calls['trades'] ?? 0, lessThanOrEqualTo(6));
      expect(calls['prices'], lessThanOrEqualTo(6));
      expect(calls['candles-1d'] ?? 0, 0, reason: '일별 캔들(252봉)은 10초마다 받지 않는다');
      expect(
        calls['buyingPower'] ?? 0,
        0,
        reason: '상세가 위에 있는데 목록의 주문 가능 타이머가 돌았다(H4)',
      );
    });
  });

  testWidgets('H4 주문 가능은 60초마다 · 원화와 달러 한 번씩, 앱이 뒤로 가면 멈춘다', (tester) async {
    await _tall(tester);
    final calls = <String, int>{};
    void hit(String k) => calls[k] = (calls[k] ?? 0) + 1;
    await tester.pumpWidget(
      _app(const Scaffold(body: TossStocksView()), _base(onCall: hit)),
    );
    await _settle(tester, 1000);
    final first = calls['buyingPower'] ?? 0;
    expect(first, 2, reason: '처음에 원화 · 달러 한 번씩');
    await _settle(tester, 61000);
    expect(
      calls['buyingPower'],
      first + 2,
      reason: '60초 뒤 한 번씩 더(10초 보유 박자에 같이 돌지 않는다)',
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StringCodec().encodeMessage(AppLifecycleState.paused.toString()),
      (_) {},
    );
    final before = calls['buyingPower'];
    await _settle(tester, 130000);
    expect(calls['buyingPower'], before, reason: '앱이 뒤로 갔는데 주문 가능을 불렀다');
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StringCodec().encodeMessage(AppLifecycleState.resumed.toString()),
      (_) {},
    );
  });

  // ── M3: 그룹 질의가 안 왔을 때 ☆ ────────────────────────────────────────
  testWidgets('M3 그룹 질의가 로딩 중이면 ☆ 로 기본 그룹을 만들지 않는다', (tester) async {
    await _tall(tester);
    final requests = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            requests.add('${o.method} ${o.path}');
            h.reject(
              DioException(
                requestOptions: o,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
    await tester.pumpWidget(
      _app(const TossStockDetailPage(symbol: 'A1'), [
        ..._base(),
        stocksRepositoryProvider.overrideWith(
          (ref) async => StocksRepository(dio),
        ),
        // 끝나지 않는 질의 = 아직 오는 중
        watchGroupsProvider.overrideWith(
          (ref) => Completer<List<StockWatchGroup>>().future,
        ),
      ]),
    );
    await _settle(tester);
    await tester.tap(find.byIcon(LucideIcons.star));
    await _settle(tester);
    expect(
      requests.where((r) => r.startsWith('POST') && r.contains('/stock-watch')),
      isEmpty,
    );
  });

  // ── H5: 가리기 + 포트폴리오 ──────────────────────────────────────────────
  group('포트폴리오 구성', () {
    TossHoldings two() => _holdings([
      _item('KR1', 'KRW', '1000000'),
      _item('MOA', 'USD', '1000'),
    ]);

    testWidgets('H5 가리기를 켜면 범례 비중도 도넛 툴팁 금액도 가린다', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _app(const TossPortfolioPage(), _base(holdings: two(), masked: true)),
      );
      await _settle(tester);
      final donut = tester.widget<PDonutChart>(find.byType(PDonutChart));
      expect(donut.valueFormatter, isNotNull);
      expect(donut.valueFormatter!(8568000), '••••');
      expect(_tc('%'), findsNothing, reason: '범례 비중이 보이면 안 된다');
      expect(_t('••••'), findsWidgets);
    });

    testWidgets('가리지 않으면 비중이 보이고 도넛 가운데는 N종목', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        _app(const TossPortfolioPage(), _base(holdings: two())),
      );
      await _settle(tester);
      expect(_tc('%'), findsWidgets);
      expect(_t('2종목'), findsOneWidget);
      expect(
        tester.widget<PDonutChart>(find.byType(PDonutChart)).valueFormatter,
        isNull,
      );
    });
  });

  // ── H4 · 시장 띠 ─────────────────────────────────────────────────────────
  group('시장 띠', () {
    Widget list(List<Override> o) =>
        _app(const Scaffold(body: TossStocksView()), o);

    testWidgets('H4 달력이 오는 중이면 "휴장" 을 그리지 않고 Skeleton', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        list([
          ..._base(),
          tossMarketCalendarKrProvider.overrideWith(
            (ref) => Completer<TossKrMarketCalendar>().future,
          ),
          tossMarketCalendarUsProvider.overrideWith(
            (ref) => Completer<TossUsMarketCalendar>().future,
          ),
        ]),
      );
      await _settle(tester, 500);
      expect(_tc('휴장'), findsNothing);
      expect(find.byType(PSkeleton), findsWidgets);
    });

    testWidgets('H4 국내 달력만 실패하면 그 칸만 비우고 미국은 그대로, 한 벌 실패는 아님', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        list([
          ..._base(),
          tossMarketCalendarKrProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
        ]),
      );
      await _settle(tester);
      expect(_t('시장 정보를 불러오지 못했어요'), findsNothing);
      expect(_tc('휴장'), findsOneWidget, reason: '미국 칸만 — 달력이 휴장일이라고 말한 것');
    });

    testWidgets('H4 지수 · 국내 · 미국이 모두 실패할 때만 한 벌', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(
        list([
          ..._base(),
          tossIndicatorPricesProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
          tossMarketCalendarKrProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
          tossMarketCalendarUsProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
        ]),
      );
      await _settle(tester);
      expect(_t('시장 정보를 불러오지 못했어요'), findsOneWidget);
    });
  });

  // ── 거래소 이름 · 날짜 표기 ───────────────────────────────────────────────
  group('거래소 이름은 사용자 말로 (코드 그대로 노출 금지)', () {
    late AppLocalizationsKo l;
    setUp(() => l = AppLocalizationsKo());
    test('한 표 — 국내 · 미국 · 그 밖', () {
      const table = {
        'KOSPI': '코스피',
        'KOSDAQ': '코스닥',
        'KONEX': '코넥스',
        'NAS': '나스닥',
        'NASDAQ': '나스닥',
        'NYS': '뉴욕',
        'NYSE': '뉴욕',
        'AMS': '아멕스',
        'AMEX': '아멕스',
        'TSE': '도쿄',
        'HKS': '홍콩',
      };
      table.forEach((code, name) => expect(stockMarketLabel(l, code), name));
    });
    test('모르는 코드만 원문', () {
      expect(stockMarketLabel(l, 'ZZZ'), 'ZZZ');
      expect(stockMarketLabel(l, ''), '');
    });
  });

  group('날짜 표기 — 연도가 뜻인 값은 "2010년 1월 4일"', () {
    test('YYYY-MM-DD · ISO', () {
      expect(fullDateOf('2010-01-04'), '2010년 1월 4일');
      expect(fullDateOf('2026-12-31T00:00:00'), '2026년 12월 31일');
    });
    test('읽을 수 없으면 받은 글 그대로', () {
      expect(fullDateOf('없음'), '없음');
      expect(fullDateOf(''), '');
    });
  });

  testWidgets('미국 종목 상세 — 머리 · 기본 정보에 NAS 가 아니라 나스닥, 상장일은 한국어 날짜', (
    tester,
  ) async {
    await _tall(tester);
    await tester.pumpWidget(
      _app(
        const TossStockDetailPage(symbol: 'AAPL'),
        _base(
          info: () async => TossStockInfo.fromJson(const {
            'symbol': 'AAPL',
            'name': '애플',
            'market': 'NAS',
            'securityType': 'STOCK',
            'status': 'NORMAL',
            'currency': 'USD',
            'listDate': '2010-01-04',
            'sharesOutstanding': '1000000',
          }),
        ),
      ),
    );
    await _settle(tester);
    expect(_tc('AAPL · 나스닥 · 주식'), findsOneWidget);
    expect(_tc('NAS'), findsNothing);
    expect(_t('나스닥'), findsOneWidget, reason: '기본 정보 시장 칸');
    expect(_t('2010년 1월 4일'), findsOneWidget);
    expect(_tc('2010-01-04'), findsNothing);
  });

  // ── M17: 연결 0 안내 (Q4 안 A) ───────────────────────────────────────────
  testWidgets('연결 0 이면 Result Section empty — 제목 · 설명 · [증권사 연결하기]', (
    tester,
  ) async {
    await _tall(tester, h: 1200);
    await tester.pumpWidget(
      _app(const StocksScreen(), [
        ..._base(),
        myFeaturesLoadProvider.overrideWith(
          (ref) async => const MyFeatures(
            features: ['SECURITIES'],
            connectedBrokers: [],
            primaryBroker: null,
          ),
        ),
      ]),
    );
    await _settle(tester);
    expect(_t('증권사를 연결해주세요'), findsOneWidget);
    expect(_t('토스증권 · 나무증권 키를 연결하면 시세와 보유 종목을 볼 수 있어요.'), findsOneWidget);
    expect(_t('증권사 연결하기'), findsOneWidget);
    expect(find.byIcon(LucideIcons.plug), findsOneWidget);
    expect(
      find.byType(TossStocksView),
      findsNothing,
      reason: '연결 0 에 목록을 그리지 않는다',
    );
  });

  // ── H2: 순위 실패 ────────────────────────────────────────────────────────
  testWidgets('H2 순위 질의가 실패하면 실패 한 벌(빈 상태 아님)', (tester) async {
    await _tall(tester);
    await tester.pumpWidget(
      _app(const Scaffold(body: TossStocksView()), [
        ..._base(),
        tossRankingsProvider.overrideWith(
          (ref, k) async => throw StateError('x'),
        ),
      ]),
    );
    await _settle(tester, 500);
    await tester.tap(_chip('발견'));
    await _settle(tester);
    expect(_t('순위를 불러오지 못했어요'), findsOneWidget);
    expect(_t('집계된 순위가 없어요'), findsNothing);
  });

  // ── M7: 묶음이 스크롤로 사라져도 예외 없음 ────────────────────────────────
  testWidgets('M7 관심 묶음이 스크롤로 사라져도 예외가 없다', (tester) async {
    t(tester);
    await tester.pumpWidget(
      _app(const Scaffold(body: TossStocksView()), [
        ..._base(),
        watchGroupsProvider.overrideWith(
          (ref) async => [for (var i = 1; i <= 6; i++) _group(i, '그룹$i', 9)],
        ),
      ]),
    );
    await _settle(tester, 1000);
    await tester.tap(_chip('관심'));
    await _settle(tester, 1500);
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 400));
    }
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await _settle(tester, 1000);
    expect(tester.takeException(), isNull);
  });

  // ── M2: 찾기 ─────────────────────────────────────────────────────────────
  group('종목 찾기 (24)', () {
    List<StockMasterItem> found() => [
      StockMasterItem.fromJson(const {
        'countryCode': 'KR',
        'marketCode': 'KOSPI',
        'symbol': '000001',
        'nameKr': '가람전자',
        'securityType': 'STOCK',
        'currency': 'KRW',
      }),
    ];

    Future<void> open(WidgetTester tester, List<Override> o) async {
      await _tall(tester, h: 1600);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => showStockSearchSheet(ctx, onPick: (_) {}),
                child: const Text('열기'),
              ),
            ),
          ),
          o,
        ),
      );
      await tester.tap(findText('열기'));
      await _settle(tester, 800);
    }

    testWidgets('M2 첫 글자를 친 직후(300ms 안)에는 "결과 없음" 이 뜨지 않는다', (tester) async {
      await open(tester, [
        ..._base(),
        stockSearchResultProvider.overrideWith((ref, q) async => found()),
      ]);
      await tester.enterText(find.byType(EditableText).last, '가');
      await tester.pump(const Duration(milliseconds: 100));
      expect(_tc('에 대한 검색 결과가 없어요'), findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_t('가람전자'), findsOneWidget);
    });

    testWidgets('M2 다음 검색어를 기다리는 동안 옛 결과를 두고, 1초 넘으면 Skeleton', (tester) async {
      final gate = Completer<List<StockMasterItem>>();
      await open(tester, [
        ..._base(),
        stockSearchResultProvider.overrideWith(
          (ref, q) => q == '가' ? Future.value(found()) : gate.future,
        ),
      ]);
      await tester.enterText(find.byType(EditableText).last, '가');
      await _settle(tester, 800);
      expect(_t('가람전자'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).last, '가람');
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // 300ms 뒤 질의가 나갔지만 안 왔다
      expect(_t('가람전자'), findsOneWidget, reason: '옛 결과를 둔다');
      expect(
        find.byType(PSkeleton),
        findsNothing,
        reason: '1초 안에는 Skeleton 없음',
      );
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.byType(PSkeleton), findsWidgets);
      gate.complete(const []);
      await _settle(tester);
      expect(_tc('에 대한 검색 결과가 없어요'), findsOneWidget);
    });

    testWidgets('실패는 실패 한 벌 + 다시 시도', (tester) async {
      await open(tester, [
        ..._base(),
        stockSearchResultProvider.overrideWith(
          (ref, q) async => throw StateError('x'),
        ),
      ]);
      await tester.enterText(find.byType(EditableText).last, '가');
      await _settle(tester, 1500);
      expect(_t('검색 결과를 불러오지 못했어요'), findsOneWidget);
      expect(_t('다시 시도'), findsWidgets);
    });
  });

  // ── 12·13·15·16: 폼 · 삭제 확인 ─────────────────────────────────────────
  group('관심 그룹 폼 · 삭제 (15 · 16)', () {
    testWidgets('폼에 삭제 단추가 없고 빈 이름이면 [저장] 이 막힌다', (tester) async {
      await _tall(tester, h: 1600);
      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (ctx, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showWatchGroupForm(ctx, ref),
                child: const Text('열기'),
              ),
            ),
          ),
          _base(),
        ),
      );
      await tester.tap(findText('열기'));
      await _settle(tester, 800);
      expect(_t('그룹 추가'), findsWidgets);
      expect(_t('그룹 삭제'), findsNothing);
      final save =
          tester.widget(
                find.byWidgetPredicate(
                  (w) =>
                      w.runtimeType.toString() == 'PButton' &&
                      (w as dynamic).label == '저장',
                ),
              )
              as dynamic;
      expect(save.onPressed, isNull);
      await tester.enterText(find.byType(EditableText).last, '새 그룹');
      await tester.pump();
      final save2 =
          tester.widget(
                find.byWidgetPredicate(
                  (w) =>
                      w.runtimeType.toString() == 'PButton' &&
                      (w as dynamic).label == '저장',
                ),
              )
              as dynamic;
      expect(save2.onPressed, isNotNull);
    });

    testWidgets('삭제 확인 글 — 종목 n개가 함께 삭제돼요 / 0개면 그룹만', (tester) async {
      await _tall(tester, h: 1600);
      await tester.pumpWidget(
        _app(
          Consumer(
            builder: (ctx, ref, _) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () =>
                        confirmDeleteWatchGroup(ctx, ref, _group(1, '반도체', 3)),
                    child: const Text('삼'),
                  ),
                  TextButton(
                    onPressed: () =>
                        confirmDeleteWatchGroup(ctx, ref, _group(2, '빈', 0)),
                    child: const Text('영'),
                  ),
                ],
              ),
            ),
          ),
          _base(),
        ),
      );
      await tester.tap(findText('삼'));
      await _settle(tester, 800);
      expect(
        _tc('"반도체" 그룹과 담긴 종목 3개가 함께 삭제돼요. 삭제한 그룹은 되돌릴 수 없어요.'),
        findsOneWidget,
      );
      await tester.tap(_t('취소'));
      await _settle(tester, 800);
      await tester.tap(findText('영'));
      await _settle(tester, 800);
      expect(_tc('"빈" 그룹을 삭제해요. 삭제한 그룹은 되돌릴 수 없어요.'), findsOneWidget);
    });
  });
}

void t(WidgetTester tester) {
  tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
