// 나무 폰 화면(I-13 13-3) — 토스와 같은 띠 틀, 국내 · 해외 한 목록, 상세 · 포트폴리오 페이지, 관심 시세 호출.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stock_pages.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_web_view.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_donut.dart';
import '../../support/plain_text.dart';

NamuHoldingItem _item(
  String symbol,
  String name,
  String eval, {
  String pnl = '1000',
  String qty = '3',
  String price = '70000',
}) => NamuHoldingItem(
  symbol: symbol,
  name: name,
  quantity: qty,
  avgPrice: '60000',
  currentPrice: price,
  evalAmount: eval,
  profitLoss: pnl,
);

NamuHoldings _h(String cur, List<NamuHoldingItem> items) => NamuHoldings(
  accountNo: 'a',
  currency: cur,
  totalEvalAmount: '0',
  totalProfitLoss: '0',
  profitRate: '0',
  items: items,
);

final _krw = _h('KRW', [
  _item('A900001', '가람전자 아주 긴 종목 이름 우선주 테스트', '1834567890', pnl: '300000000'),
  _item('A900002', '숲길증권', '8760000'),
]);
final _usd = _h('USD', [
  _item('MOA', '모아 테크놀로지스', '6185.55', pnl: '685.55', price: '412.37'),
]);

StockWatchGroup _group(int id, String name, List<String> symbols) =>
    StockWatchGroup(
      rowId: id,
      groupName: name,
      sortOrder: id,
      items: [
        for (final (i, s) in symbols.indexed)
          WatchItem(
            rowId: id * 100 + i,
            stockMasterRowId: 1,
            countryCode: 'KR',
            marketCode: 'KOSPI',
            symbol: s,
            nameKr: '종목 $s',
            securityType: 'STOCK',
            currency: 'KRW',
          ),
      ],
    );

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

final quotesAsked = <String>[];
final detailAsked = <String>[];
final executionsAsked = <String>[];
final investorsAsked = <String>[];

Future<void> _pump(
  WidgetTester tester, {
  Widget home = const Scaffold(body: NamuStocksView()),
  Size size = const Size(360, 2400),
  double textScale = 1,
  NamuHoldings? krw,
  NamuHoldings? usd,
  bool krwFail = false,
  bool usdFail = false,
  bool holdingsPending = false,
  double? fx = 1385.2,
  List<StockWatchGroup> groups = const [],
  bool masked = false,
  bool quotesFail = false,
  bool executionsFail = false,
  Future<List<StockMasterItem>> Function(String q)? search,
}) async {
  quotesAsked.clear();
  detailAsked.clear();
  executionsAsked.clear();
  investorsAsked.clear();
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        namuHoldingsProvider.overrideWith((ref, c) async {
          if (holdingsPending) return Completer<NamuHoldings>().future;
          final fail = c == 'KRW' ? krwFail : usdFail;
          if (fail) throw StateError('x');
          return c == 'KRW' ? (krw ?? _krw) : (usd ?? _usd);
        }),
        namuExchangeRateProvider.overrideWith((ref) async => fx),
        watchGroupsProvider.overrideWith((ref) async => groups),
        namuQuotesProvider.overrideWith((ref, key) async {
          // 시장 띠의 장 상태 조회(대표 종목: 보유 첫 종목)는 관심 시세 기록에 넣지 않는다.
          if (!key.contains('A900001')) quotesAsked.add(key);
          if (quotesFail) throw StateError('x');
          return [
            for (final s in key.split(',').where((e) => e.isNotEmpty))
              NamuListQuote(
                symbol: s,
                price: 70000,
                currency: 'KRW',
                previousClose: 69000,
                marketState: 'REGULAR',
              ),
          ];
        }),
        // 13b-1 — 상세 시세 · 체결 · 투자자별 · 주문 가능(달러). 칸이 빠진 응답도 화면이 깨지지 않아야 한다.
        namuQuoteDetailProvider.overrideWith((ref, key) async {
          detailAsked.add(key.symbol);
          if (quotesFail) throw StateError('x');
          return NamuQuoteDetail(
            symbol: key.symbol,
            price: 70000,
            previousClose: 69000,
            open: 69500,
            high: 70500,
            low: 69000,
            volume: 1234567,
            upperLimit: 89700,
            lowerLimit: 48300,
            warnings: const ['INVESTMENT_ATTENTION'],
            sector: '전기전자',
            marketCap: 4.2e14,
            listedShares: 5.9e9,
            listingDate: '20040101',
          );
        }),
        namuExecutionsProvider.overrideWith((ref, key) async {
          executionsAsked.add(key.symbol);
          if (executionsFail) throw StateError('x');
          return const [];
        }),
        namuInvestorsProvider.overrideWith((ref, s) async {
          investorsAsked.add(s);
          return const [
            InvestorTradingDay(
              date: '2026-10-23',
              individual: -1200,
              foreigner: 3400,
              institution: null,
            ),
          ];
        }),
        namuUsdDepositProvider.overrideWith(
          (ref) async => const BuyingPower(currency: 'USD', amount: 1234.5),
        ),
        namuDailyCandlesProvider.overrideWith(
          (ref, s) async => TossCandlePage(
            candles: [
              for (var d = 20; d <= 28; d++)
                TossCandle(
                  timestamp: '2026-10-${d}T00:00:00+09:00',
                  openPrice: '1',
                  highPrice: '1',
                  lowPrice: '1',
                  closePrice: '${70000 + d * 100}',
                  volume: '1000',
                ),
            ],
          ),
        ),
        if (masked) hideCardProvider.overrideWith((ref, card) => true),
        // 상세는 실패를 던지는 검색을 쓴다(H5) — 시장을 알 때까지 기다리고, 실패는 안내로 보인다
        stockSearchResultProvider.overrideWith(
          (ref, q) async => search != null
              ? search(q)
              : const [
                  StockMasterItem(
                    countryCode: 'KR',
                    marketCode: 'KOSPI',
                    symbol: 'A900001',
                    nameKr: '가람전자 아주 긴 종목 이름 우선주 테스트',
                    securityType: 'STOCK',
                    currency: 'KRW',
                  ),
                ],
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 3,
            textScaler: TextScaler.linear(textScale),
          ),
          child: home,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('띠 차례 — 내 투자 → 시장 → 종목, 띠 사이 8, 시장 띠는 장 상태 + 환율 줄', (
    tester,
  ) async {
    await _pump(tester);
    final invest = _t('원화 환산 합계');
    final market = _t('시장');
    final stocks = _t('종목');
    expect(invest, findsOneWidget);
    expect(market, findsOneWidget);
    expect(stocks, findsOneWidget);
    expect(
      tester.getTopLeft(invest).dy < tester.getTopLeft(market).dy &&
          tester.getTopLeft(market).dy < tester.getTopLeft(stocks).dy,
      isTrue,
    );
    final bands = find.byKey(const ValueKey('screen-section'));
    expect(bands, findsNWidgets(2));
    expect(
      tester.getRect(bands.at(1)).top - tester.getRect(bands.at(0)).bottom,
      8,
    );
    expect(_t('환율(USD)'), findsOneWidget);
    expect(_t('1,385.20원'), findsOneWidget);
    // 장 상태는 대표 종목의 시세에 딸려 온다(13b-1 17) — 나무에 없는 지수 · 발견은 그리지 않는다
    // 기본 데이터에는 국내 · 미국 보유가 다 있어 시장마다 한 줄씩 둘이다
    expect(_tc('장중 · '), findsNWidgets(2));
    expect(_t('코스피'), findsNothing);
    expect(_tc('장마감'), findsNothing);
    expect(_chip('발견'), findsNothing);
    expect(_chip('보유'), findsOneWidget);
    expect(_chip('관심'), findsOneWidget);
    expect(_tc('토스'), findsNothing);
    expect(_t('나무증권 Open API · 시세 지연 표시'), findsOneWidget);
  });

  testWidgets('틈 — 내 투자 ↔ 시장 8, 시장 ↔ 종목 띠 8 (T3 · T4, 나무도 같다 T8)', (
    tester,
  ) async {
    await _pump(tester);
    final bands = find.byKey(const ValueKey('screen-section'));
    final marketBottom = tester.getRect(bands.at(1)).bottom;
    // 종목 띠는 제목 위 여백 24 가 띠 안이다 — 제목 글 위쪽에서 24 를 뺀 자리가 띠의 위
    final stocksTop = tester.getTopLeft(_t('종목')).dy - 24;
    expect(stocksTop - marketBottom, 8);
  });

  testWidgets('섞이면 원화 환산 합계 + 환율 적용 글, 국내 · 해외 줄과 "국내 2 · 해외 1"', (
    tester,
  ) async {
    await _pump(tester);
    final stat = tester.widget<Text>(
      find.byKey(const ValueKey('card-stat-value')),
    );
    // 1,834,567,890 + 8,760,000 + 6185.55 × 1385.2 = 1,851,895,… 원 (쉼표 뒤 줄바꿈 U+200B)
    expect(stat.data, contains('​'));
    expect(stat.semanticsLabel, startsWith('≈ 1,85'));
    expect(_t('환율 1,385 적용'), findsOneWidget);
    expect(_tc('+'), findsNothing, reason: 'Delta 에 + 부호 없음');
    expect(_t('국내 평가금액'), findsOneWidget);
    expect(_t('해외 평가금액'), findsOneWidget);
    expect(_t('국내 2 · 해외 1'), findsOneWidget);
    expect(_t('포트폴리오 구성'), findsOneWidget);
    // 나무 잔고에는 일간 손익이 없다
    expect(_t('일간 손익'), findsNothing);
  });

  testWidgets('환율이 없으면 합계는 없고 통화별로만 — 시장 띠 환율 줄은 "환율 없음"', (tester) async {
    await _pump(tester, fx: null);
    expect(_t('시장'), findsOneWidget);
    expect(_t('환율 없음'), findsOneWidget);
    expect(_t('원화 환산 합계'), findsNothing);
    expect(_t('국내 평가금액'), findsWidgets);
    expect(find.byKey(const ValueKey('screen-section')), findsNWidgets(2));
  });

  group('시장 띠 장 상태 — 대표 종목을 기다리는 동안(13b-1 후속)', () {
    final kGroups = [
      _group(1, '관심', ['K1']),
    ];

    testWidgets('보유 로딩 중 — 값 자리는 기다리고 시장 띠는 실패 한 벌이 아니다, 장 상태 줄은 아직 없다', (
      tester,
    ) async {
      await _pump(tester, holdingsPending: true, groups: kGroups);
      expect(_t('시장'), findsOneWidget);
      expect(_t('시장 정보를 불러오지 못했어요'), findsNothing);
      expect(_tc('장중 · '), findsNothing);
      expect(quotesAsked, isEmpty, reason: '대표를 정하기 전에는 장 상태 시세를 부르지 않는다');
      // 환율 줄은 기다리지 않는다 — 환율 질의는 보유와 따로다
      expect(_t('1,385.20원'), findsOneWidget);
    });

    testWidgets('보유 실패 — 관심 첫 종목이 대표가 되어 장 상태 줄이 나온다', (tester) async {
      await _pump(tester, krwFail: true, usdFail: true, groups: kGroups);
      expect(_t('시장 정보를 불러오지 못했어요'), findsNothing);
      expect(quotesAsked, contains('K1'));
      expect(_tc('장중 · '), findsOneWidget);
      expect(_tc('프리마켓'), findsNothing, reason: '미국 대표는 없다 — 그 시장은 그리지 않는다');
    });

    testWidgets('보유 0 — 마찬가지로 관심 첫 종목이 대표, 관심도 없으면 장 상태 없이 환율 줄만', (
      tester,
    ) async {
      await _pump(
        tester,
        krw: _h('KRW', const []),
        usd: _h('USD', const []),
        groups: kGroups,
      );
      expect(quotesAsked, contains('K1'));
      expect(_tc('장중 · '), findsOneWidget);
      // 먼저 비운다 — 같은 모양이면 ProviderScope 가 재사용돼 받아 둔 대표 시세가 남는다
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, krw: _h('KRW', const []), usd: _h('USD', const []));
      expect(quotesAsked, isEmpty);
      expect(_tc('장중 · '), findsNothing);
      expect(_t('환율(USD)'), findsOneWidget);
      expect(_t('시장 정보를 불러오지 못했어요'), findsNothing);
    });

    testWidgets('보유 로딩 중에 대표 시세가 실패해도 시장 띠 전체가 실패가 되지 않는다 — 환율이 남는다', (
      tester,
    ) async {
      await _pump(tester, holdingsPending: true, groups: kGroups, fx: 1385.2);
      expect(_t('환율(USD)'), findsOneWidget);
      expect(findText('다시 시도'), findsNothing);
    });
  });

  testWidgets('주문 가능 — 원화는 국내 잔고에서, 달러는 "예수금 · 달러"(margin)', (tester) async {
    await _pump(
      tester,
      krw: NamuHoldings(
        accountNo: 'a',
        currency: 'KRW',
        totalEvalAmount: '100',
        totalProfitLoss: '1',
        profitRate: '1',
        items: [_item('A1', '가', '100')],
        deposit: '5000',
        orderableAmount: '200000000',
      ),
    );
    expect(_t('주문 가능 · 원화'), findsOneWidget);
    expect(_t('예수금 · 달러'), findsOneWidget);
    expect(_t('주문 가능 · 달러'), findsNothing);
  });

  testWidgets('한 통화뿐이면 그 통화 지표 + Delta, 거르기 Segmented 없음', (tester) async {
    await _pump(tester, usd: _h('USD', const []));
    expect(_t('국내 평가금액'), findsOneWidget);
    expect(_t('해외 평가금액'), findsNothing);
    expect(_t('매입금액보다'), findsOneWidget);
    expect(_t('전체'), findsNothing);
    expect(_t('3개'), findsNothing);
    expect(_t('2개'), findsOneWidget);
  });

  testWidgets('보유 줄 — 미국은 달러, 원화는 원, 긴 이름 줄바꿈, 타일 없음, Chip 글에 숫자 없음', (
    tester,
  ) async {
    await _pump(tester);
    expect(_tc(r'$6,185.55'), findsWidgets);
    expect(_tc('8,760,000원'), findsWidgets);
    final name = _t('가람전자 아주 긴 종목 이름 우선주 테스트');
    expect(name, findsOneWidget);
    expect(tester.widget<Text>(name).maxLines, isNull);
    expect(_chip('보유 3'), findsNothing);
  });

  testWidgets('거르기 — 섞였을 때만 전체 · 국내 · 해외, 해외를 고르면 달러 줄만', (tester) async {
    await _pump(tester);
    expect(_t('전체'), findsOneWidget);
    await tester.tap(_t('해외'));
    await tester.pump();
    expect(_t('모아 테크놀로지스'), findsOneWidget);
    expect(_t('숲길증권'), findsNothing);
    await tester.tap(_t('국내'));
    await tester.pump();
    expect(_t('모아 테크놀로지스'), findsNothing);
    expect(_t('숲길증권'), findsOneWidget);
  });

  testWidgets('둘 다 실패 — 실패 한 벌(설명은 계좌 안내), 연결 안내 아님', (tester) async {
    await _pump(tester, krwFail: true, usdFail: true);
    expect(_t('내 투자를 불러오지 못했어요'), findsOneWidget);
    expect(_t('보유 종목을 불러오지 못했어요'), findsOneWidget);
    expect(_t('계좌가 없거나 조회 권한이 없을 수 있어요.'), findsNWidgets(2));
    expect(_tc('연결'), findsNothing);
  });

  testWidgets('한쪽만 실패하면 남은 통화가 보인다', (tester) async {
    await _pump(tester, usdFail: true);
    expect(_t('내 투자를 불러오지 못했어요'), findsNothing);
    expect(_t('국내 평가금액'), findsOneWidget);
    expect(_t('숲길증권'), findsOneWidget);
  });

  testWidgets('보유 0 — 지표 0원과 안내', (tester) async {
    await _pump(tester, krw: _h('KRW', const []), usd: _h('USD', const []));
    expect(_t('보유 중인 종목이 없어요'), findsWidgets);
    expect(_t('0원'), findsOneWidget);
  });

  testWidgets('관심 — 그룹마다 제목 · ⋮ · 맨 끝 "그룹 추가", 보이는 묶음만 시세 한 번에', (
    tester,
  ) async {
    await _pump(
      tester,
      groups: [
        _group(1, '반도체', ['A1', 'A2']),
        _group(2, '배당', ['A2', 'A3']),
        _group(3, '비어 있는 그룹', []),
      ],
    );
    await tester.tap(_chip('관심'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_t('반도체 · 2'), findsOneWidget);
    expect(_t('아직 담은 종목이 없어요'), findsOneWidget);
    expect(find.bySemanticsLabel('반도체 더보기'), findsOneWidget);
    expect(quotesAsked, isNotEmpty);
    // 겹친 종목은 한 번만 — 그룹마다 따로 부르지 않는다
    expect(quotesAsked.toSet().length, 1);
    expect(quotesAsked.first, 'A1,A2,A3');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_tc('70,000원'), findsWidgets);
    await tester.scrollUntilVisible(
      _t('그룹 추가'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_t('그룹 추가'), findsOneWidget);
  });

  testWidgets(
    '관심에서 보유로 돌아와도 예외가 나지 않는다 — 묶음이 사라질 때 잠긴 트리에서 setState 를 부르지 않는다',
    (tester) async {
      await _pump(
        tester,
        groups: [
          _group(1, '반도체', ['A1', 'A2']),
        ],
      );
      await tester.tap(_chip('관심'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_t('반도체 · 2'), findsOneWidget);
      await tester.tap(_chip('보유'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(_t('반도체 · 2'), findsNothing);
    },
  );

  testWidgets('보유 탭에서는 관심 시세를 부르지 않는다', (tester) async {
    await _pump(
      tester,
      groups: [
        _group(1, '반도체', ['A1']),
      ],
    );
    expect(quotesAsked, isEmpty);
  });

  testWidgets('글자 200% 에서도 가로 넘침 없음', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  group('상세', () {
    testWidgets('보유 종목 — 내 보유 여섯 줄, 호가 · 체결 · 매매 없음, 둘째 안내 줄만', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900001'),
        size: const Size(360, 3000),
      );
      expect(_t('종목 상세'), findsOneWidget);
      expect(_t('내 보유'), findsOneWidget);
      for (final k in ['평가금액', '평가손익', '보유수량', '수익률', '평균단가', '매입금액']) {
        expect(_t(k), findsOneWidget, reason: k);
      }
      expect(_t('수수료·세금'), findsNothing);
      // 13b-1 — 오늘 시세 · 호가 · 체결 · 투자자별 · 업종 · 투자유의 배지가 더해졌다. 매매 단추는 없다.
      expect(_t('오늘 시세'), findsOneWidget);
      expect(_t('호가 · 체결'), findsOneWidget);
      expect(_t('투자자별 매매동향'), findsOneWidget);
      expect(_t('업종'), findsOneWidget);
      expect(_t('투자유의'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is PButton && (w.label == '매도' || w.label == '매수'),
        ),
        findsNothing,
      );
      expect(_t('기본 정보'), findsOneWidget);
      expect(_t('일별 시세'), findsOneWidget);
      expect(_tc('토스'), findsNothing);
      expect(_tc('Open API 연동 시'), findsNothing);
      expect(_tc('시세는 투자 참고용이에요.'), findsOneWidget);
      expect(_tc('+'), findsNothing);
    });

    testWidgets('보유가 아닌 종목 — 내 보유 띠 없음, 상세 시세로 등락을 보인다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'ZZ0001'),
        size: const Size(360, 3000),
      );
      expect(_t('내 보유'), findsNothing);
      // 상세 시세는 `/namu/*/quote` 하나 — 목록 시세(`/namu/prices`)는 부르지 않는다.
      expect(quotesAsked, isEmpty);
      expect(_tc('70,000원'), findsWidgets);
      expect(_tc('1.45%'), findsOneWidget);
    });
  });

  group('상세 — 13-1 검수 고침(H5 · M4 · M13)', () {
    const usMaster = StockMasterItem(
      countryCode: 'US',
      marketCode: 'NAS',
      symbol: 'ZZUS',
      nameKr: '구름 소프트',
      securityType: 'STOCK',
      currency: 'USD',
    );

    testWidgets('H5 시장을 알 때까지 기다린다 — 시세도 차트도 부르지 않는다', (tester) async {
      final gate = Completer<List<StockMasterItem>>();
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'ZZUS'),
        size: const Size(360, 3000),
        search: (_) => gate.future,
      );
      expect(
        detailAsked,
        isEmpty,
        reason: '시장을 모르는 채 국내로 가정해 시세를 불렀다(호가 카드 포함 — N4)',
      );
      expect(_t('KRW'), findsNothing, reason: '시장을 모르는데 통화를 KRW 로 지어냈다');
      expect(find.byType(ChartWebView), findsNothing);
      expect(_t('—'), findsOneWidget);
      expect(_t('현재가가 없는 종목이에요'), findsNothing);

      gate.complete(const [usMaster]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(detailAsked, ['ZZUS']);
      expect(find.byType(ChartWebView), findsOneWidget);
      final chart = tester.widget<ChartWebView>(find.byType(ChartWebView));
      expect(chart.isUs, isTrue, reason: '미국 종목이 국내 차트로 열렸다');
    });

    testWidgets('H5 검색이 실패하면 실패 안내 + [다시 시도], 국내로 가정하지 않는다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'ZZUS'),
        size: const Size(360, 3000),
        search: (_) async => throw StateError('x'),
      );
      expect(_t('기본 정보를 불러오지 못했어요'), findsOneWidget);
      expect(_t('다시 시도'), findsOneWidget);
      expect(find.byType(ChartWebView), findsNothing);
      expect(detailAsked, isEmpty);
      // 10초 폴링이 돌아도 국내 경로로 계속 나가지 않는다(N4)
      await tester.pump(const Duration(seconds: 25));
      expect(detailAsked, isEmpty, reason: '검색이 실패했는데 국내 경로를 10초마다 불렀다');
    });

    testWidgets('M4 시세 실패는 실패 한 벌 + [다시 시도]', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'ZZ0001'),
        size: const Size(360, 3000),
        quotesFail: true,
      );
      expect(_t('시세를 불러오지 못했어요'), findsOneWidget);
      expect(_t('잠시 뒤 다시 시도해주세요.'), findsOneWidget);
      expect(_t('다시 시도'), findsOneWidget);
      expect(_t('현재가가 없는 종목이에요'), findsNothing);
    });

    testWidgets('N8 체결 탭을 고르고 아래로 내렸다 올려도 체결 탭이 호가로 돌아가지 않는다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900001'),
        size: const Size(360, 700),
      );
      // 아래쪽 띠는 지연 목록이라 아직 그려지지 않았다 — 나타날 때까지 내린다(.first 는 빈 찾기에서 멈춘다)
      for (var i = 0; i < 30 && _t('체결').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pump();
      }
      await tester.ensureVisible(_t('체결').first);
      await tester.pumpAndSettle();
      await tester.tap(_t('체결').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_t('체결 내역이 없어요'), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 30 && _t('체결').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pump();
      }
      await tester.ensureVisible(_t('체결').first);
      await tester.pumpAndSettle();
      expect(_t('체결 내역이 없어요'), findsOneWidget, reason: '내렸다 올리니 호가 탭으로 돌아갔다');
    });

    testWidgets('M13 아래로 내렸다 올려도 차트가 폐기되지 않는다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900001'),
        size: const Size(360, 700),
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byType(ChartWebView, skipOffstage: false),
        findsOneWidget,
        reason: '화면 밖으로 나간 머리가 폐기됐다 — 올라올 때 차트가 다시 지어진다',
      );
    });
  });

  testWidgets('H1 가리기를 켜면 포트폴리오 도넛 조각 금액도 범례 비중도 가린다', (tester) async {
    await _pump(
      tester,
      home: const NamuPortfolioPage(),
      size: const Size(360, 1200),
      masked: true,
    );
    final donut = tester.widget<PDonutChart>(find.byType(PDonutChart));
    expect(donut.valueFormatter, isNotNull);
    expect(donut.valueFormatter!(8568000), '••••');
    expect(_t('••••'), findsWidgets);
    expect(_tc('%'), findsNothing, reason: '가렸는데 비중이 보인다');
  });

  group('상세 — 13-1 검수 고침 중 13b-1 몫(M3 · M5 · M6)', () {
    testWidgets('M3 나무 체결 실패는 실패 한 벌 + [다시 시도]가 실제로 다시 부른다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900002'),
        size: const Size(360, 3000),
        executionsFail: true,
      );
      await tester.tap(_t('체결').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_t('체결 내역을 불러오지 못했어요'), findsOneWidget);
      final asked = executionsAsked.length;
      await tester.tap(findText('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(executionsAsked.length, greaterThan(asked), reason: '버튼이 죽어 있다');
    });

    testWidgets('M3 호가(상세 시세) 실패도 [다시 시도]가 상세 시세를 다시 부른다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900002'),
        size: const Size(360, 3000),
        quotesFail: true,
      );
      expect(
        _t('호가를 불러오지 못했어요'),
        findsNothing,
        reason: '상세 시세 실패는 머리 실패 한 벌이 맡고 호가 띠는 그리지 않는다',
      );
      final asked = detailAsked.length;
      await tester.tap(findText('다시 시도').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(detailAsked.length, greaterThan(asked));
    });

    testWidgets('M5 국내 잔고만 실패해도 "주문 가능 · 원화" 줄은 "—" 로 남는다', (tester) async {
      await _pump(tester, krwFail: true);
      expect(_t('주문 가능 · 원화'), findsOneWidget);
      expect(
        tester.getTopLeft(_t('—').first).dy,
        greaterThan(tester.getTopLeft(_t('주문 가능 · 원화')).dy - 30),
      );
      expect(_t('0원'), findsNothing, reason: '실패가 0 원처럼 읽히면 안 된다');
    });

    testWidgets('M5 해외 잔고 실패는 원화 줄에 영향이 없다', (tester) async {
      await _pump(
        tester,
        usdFail: true,
        krw: NamuHoldings(
          accountNo: 'a',
          currency: 'KRW',
          totalEvalAmount: '100',
          totalProfitLoss: '1',
          profitRate: '1',
          items: [_item('A1', '가', '100')],
          orderableAmount: '5000',
        ),
      );
      expect(_t('5,000원'), findsOneWidget);
    });

    testWidgets('M6 나무 상장일은 연도가 붙은 날짜로(원문 20040101 도 읽는다)', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900002'),
        size: const Size(360, 3000),
      );
      expect(_t('2004년 1월 1일'), findsOneWidget);
      expect(_t('20040101'), findsNothing);
    });
  });

  group('상세 — 호출 규칙(13b-1 D)', () {
    testWidgets('체결은 체결 탭을 골랐을 때만 부른다 · 투자자별은 상세를 열 때 한 번', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900002'),
        size: const Size(360, 3000),
      );
      expect(executionsAsked, isEmpty, reason: '호가 탭일 때 체결을 부르지 않는다');
      expect(investorsAsked, ['A900002']);
      await tester.tap(_t('체결').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(executionsAsked, ['A900002']);
      expect(_t('체결 내역이 없어요'), findsOneWidget);
    });

    testWidgets('미국 종목은 투자자별 띠도 호출도 없고 매도가능 줄이 있다', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'MOA'),
        size: const Size(360, 3000),
        usd: _h('USD', [
          NamuHoldingItem(
            symbol: 'MOA',
            name: '모아 테크놀로지스',
            quantity: '15',
            avgPrice: '366.67',
            currentPrice: '412.37',
            evalAmount: '6185.55',
            profitLoss: '685.55',
            sellableQuantity: '12',
          ),
        ]),
      );
      expect(_t('투자자별 매매동향'), findsNothing);
      expect(investorsAsked, isEmpty);
      expect(_t('매도가능'), findsOneWidget);
      expect(_t('12주'), findsOneWidget);
    });

    testWidgets('국내 종목에는 매도가능 줄이 없다(국내 잔고에 칸이 없다)', (tester) async {
      await _pump(
        tester,
        home: const NamuStockDetailPage(symbol: 'A900002'),
        size: const Size(360, 3000),
      );
      expect(_t('매도가능'), findsNothing);
    });
  });

  group('포트폴리오', () {
    testWidgets('환율이 있으면 도넛 + 범례(원화 환산 비중)', (tester) async {
      await _pump(
        tester,
        home: const NamuPortfolioPage(),
        size: const Size(360, 1200),
      );
      expect(_t('포트폴리오 구성'), findsOneWidget);
      expect(_t('모아 테크놀로지스'), findsOneWidget);
      expect(_tc('%'), findsWidgets);
    });

    testWidgets('환율이 없으면 도넛 대신 안내', (tester) async {
      await _pump(
        tester,
        home: const NamuPortfolioPage(),
        size: const Size(360, 1200),
        fx: null,
      );
      expect(_t('환율을 못 받아 구성 비중을 낼 수 없어요'), findsOneWidget);
      expect(_t('모아 테크놀로지스'), findsNothing);
    });
  });
}
