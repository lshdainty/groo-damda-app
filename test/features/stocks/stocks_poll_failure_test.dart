// 증권 조회 실패(I-wrap-b2b 4) — 조용히 틀린 값을 보이지 않는다. 받아 둔 숫자는 두고 그 섹션 머리 아래에 "시세를 불러오지
// 못했어요" + [다시 시도] 띠 한 줄. 다음 받기가 성공하면 저절로 걷힌다. 스낵바는 쓰지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_parts.dart';
import 'package:groo_damda_app/features/stocks/application/live_prices.dart';
import 'package:groo_damda_app/features/stocks/application/namu_model.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/stale_value_callout.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/plain_text.dart';

const _fail = '시세를 불러오지 못했어요';
const _staleBody = '보이는 값은 마지막으로 받은 시세예요.';

/// 값이 하나도 없는 처음 실패 — 그 자리 Result Section.
final _band = find.byKey(const ValueKey('stocks-price-failure'));

/// 받아 둔 값이 보이는 채 실패 — 섹션 머리 아래 Callout critical · actionable(디자인시스템 판단).
final _stale = find.byKey(const ValueKey('stocks-price-stale'));

final _holdings = TossHoldings(
  totalPurchaseAmount: '1500000',
  marketValueAmount: '1834567',
  profitLossAmount: '334567',
  profitLossRate: '22.31',
  dailyProfitLossAmount: '-1234',
  dailyProfitLossRate: '-0.67',
  items: const [
    TossHoldingsItem(
      symbol: 'A100',
      name: '가람전자',
      marketCountry: 'KR',
      currency: 'KRW',
      quantity: '3',
      lastPrice: '70000',
      averagePurchasePrice: '60000',
      marketValueAmount: '210000',
      profitLossAmount: '30000',
      profitLossRate: '16.6',
      dailyProfitLossAmount: '0',
      dailyProfitLossRate: '0',
      purchaseAmount: '180000',
      commission: '0',
      tax: '0',
    ),
  ],
);

final _group = StockWatchGroup(
  rowId: 1,
  groupName: '관심',
  sortOrder: 1,
  items: [
    for (final s in ['A1', 'A2'])
      WatchItem(
        rowId: s.hashCode,
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

/// 토스 목록 — 각 조회를 바깥에서 실패시킨다.
class _Toss {
  bool holdingsFail = false;
  bool pricesFail = false;
  bool fxFail = false;
  late ProviderContainer container;
}

Future<_Toss> _pumpToss(WidgetTester tester, {_Toss? state}) async {
  final s = state ?? _Toss();
  tester.view.physicalSize = const Size(390 * 2, 2400 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tossHoldingsProvider.overrideWith(
          (ref) async => s.holdingsFail ? throw StateError('x') : _holdings,
        ),
        tossExchangeRateProvider.overrideWith(
          (ref) async => s.fxFail
              ? throw StateError('x')
              : const TossExchangeRate(rate: '1385.2'),
        ),
        watchGroupsProvider.overrideWith((ref) async => [_group]),
        tossMarketCalendarKrProvider.overrideWith(
          (ref) async => TossKrMarketCalendar.fromJson(const {}),
        ),
        tossMarketCalendarUsProvider.overrideWith(
          (ref) async => TossUsMarketCalendar.fromJson(const {}),
        ),
        tossIndicatorPricesProvider.overrideWith(
          (ref) async => const [
            TossIndicatorPrice(symbol: 'KOSPI', lastPrice: '2650.5'),
          ],
        ),
        tossIndicatorClosesProvider.overrideWith(
          (ref, symbol) async => const [100.0],
        ),
        tossPricesProvider.overrideWith(
          (ref, key) async => s.pricesFail
              ? throw StateError('x')
              : [
                  for (final sym in key.split(',').where((e) => e.isNotEmpty))
                    TossPrice(symbol: sym, lastPrice: '70000'),
                ],
        ),
        prevCloseProvider.overrideWith((ref, sym) async => 69000.0),
        tossBuyingPowerProvider.overrideWith(
          (ref, cur) async => BuyingPower(currency: cur, amount: 1000),
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              s.container = ProviderScope.containerOf(context);
              return const TossStocksView();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return s;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _chip(String s) => find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == 'ChipVisual' && (w as dynamic).label == s,
);

NamuHoldings _namu(String currency) => NamuHoldings(
  accountNo: 'a',
  currency: currency,
  totalEvalAmount: '0',
  totalProfitLoss: '0',
  profitRate: '0',
  items: [
    NamuHoldingItem(
      symbol: '${currency}1',
      name: '${currency}1',
      quantity: '2',
      avgPrice: '10',
      currentPrice: '12',
      evalAmount: currency == 'KRW' ? '1200000' : '5000',
      profitLoss: '0',
    ),
  ],
);

void main() {
  group('토스 목록', () {
    testWidgets('내 투자 — 받아 둔 보유가 있는 채 다시 받기 실패면 숫자는 두고 띠, 다음에 성공하면 걷힌다', (
      tester,
    ) async {
      final s = await _pumpToss(tester);
      expect(_stale, findsNothing);
      final stat = find.byKey(const ValueKey('card-stat-value'));
      final before = plainOf(tester.widget<Text>(stat).data ?? '');
      s.holdingsFail = true;
      s.container.invalidate(tossHoldingsProvider);
      await _settle(tester);
      expect(findText('가람전자'), findsOneWidget, reason: '보유 탭 줄도 보인다');
      expect(
        _stale,
        findsOneWidget,
        reason:
            '보이는 숫자 위에 실패 상자를 얹지 않고, 같은 실패에 Callout 은 맨 위 하나(보유 탭에 또 띄우지 않는다)',
      );
      expect(_band, findsNothing);
      expect(findTextContaining(_fail), findsOneWidget);
      expect(findTextContaining(_staleBody), findsOneWidget);
      expect(find.byType(PCallout), findsOneWidget);
      expect(
        plainOf(tester.widget<Text>(stat).data ?? ''),
        before,
        reason: '숫자는 그대로',
      );
      // 띠가 머리(내 투자 평가금액) 위가 아니라 내 투자 섹션 안에 있다
      expect(find.byType(PSnackbarHost), findsOneWidget);
      expect(findText('새로 고치지 못했어요.'), findsNothing, reason: '스낵바는 쓰지 않는다');
      s.holdingsFail = false;
      s.container.invalidate(tossHoldingsProvider);
      await _settle(tester);
      expect(_stale, findsNothing, reason: '다음 받기가 성공하면 저절로 걷힌다');
    });

    testWidgets('시장 — 환율을 못 받으면 그 줄이 조용히 빠지지 않고 섹션 머리 아래 Callout(지수는 보인다)', (
      tester,
    ) async {
      await _pumpToss(tester, state: _Toss()..fxFail = true);
      expect(_stale, findsOneWidget);
      expect(
        tester.getTopLeft(findText('시장')).dy < tester.getTopLeft(_stale).dy,
        isTrue,
      );
    });

    testWidgets('관심 — 시세를 처음부터 못 받으면 줄은 "—" 만이 아니라 묶음 위에 띠', (tester) async {
      await _pumpToss(tester, state: _Toss()..pricesFail = true);
      await tester.tap(_chip('관심'));
      await _settle(tester);
      await _settle(tester);
      await _settle(tester);
      expect(findText('종목 A1'), findsOneWidget);
      // 값이 하나도 없는 처음 실패(줄이 "—" 만) — 그 자리 Result Section
      expect(_band, findsOneWidget);
      expect(_stale, findsNothing);
      expect(findText('종목 A1'), findsOneWidget);
    });
  });

  group('나무 내 투자', () {
    Future<void> pumpBand(
      WidgetTester tester, {
      required AsyncValue<NamuHoldings> krw,
      required AsyncValue<NamuHoldings> usd,
    }) async {
      tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [namuUsdDepositProvider.overrideWith((ref) async => null)],
          child: MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: NamuInvestBand(
                  krwAsync: krw,
                  usdAsync: usd,
                  view: mergeNamuHoldings(krw.value, usd.value, 1400),
                  loading: false,
                  failed: false,
                  masked: false,
                  onRetry: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('한쪽 통화를 못 받으면 그 통화가 조용히 빠지지 않고 띠 한 줄', (tester) async {
      await pumpBand(
        tester,
        krw: AsyncData(_namu('KRW')),
        usd: AsyncError(StateError('x'), StackTrace.empty),
      );
      // 남은 통화가 보인다 — 섹션 맨 위 Callout 하나
      expect(_stale, findsOneWidget);
      expect(findTextContaining(_fail), findsOneWidget);
    });

    testWidgets('두 통화 모두 받았으면 띠 없음', (tester) async {
      await pumpBand(
        tester,
        krw: AsyncData(_namu('KRW')),
        usd: AsyncData(_namu('USD')),
      );
      expect(_stale, findsNothing);
      expect(_band, findsNothing);
    });
  });

  testWidgets('Callout 은 상자 전체가 다시 시도 — 다시 받는 동안은 누름을 무시한다(진행 원 없음)', (
    tester,
  ) async {
    var taps = 0;
    Future<void> show(bool retrying) => tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Scaffold(
          body: StaleValueCallout(
            title: _fail,
            description: _staleBody,
            retrying: retrying,
            onRetry: () => taps++,
          ),
        ),
      ),
    );
    await show(false);
    await tester.tap(find.byType(PCallout));
    await tester.pump();
    expect(taps, 1);
    await show(true);
    await tester.tap(find.byType(PCallout));
    await tester.pump();
    expect(taps, 1, reason: '다시 받는 동안은 무시');
  });

  group('자산 평가', () {
    final inv = Asset(
      rowId: 1,
      assetName: '주식 계좌',
      assetType: 'INVESTMENT',
      balance: 500000,
      holdings: const [
        AssetHolding(linked: true, tossSymbol: '005930', quantity: '10'),
      ],
    );

    ProviderContainer container({required bool pricesFail}) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          myFeaturesProvider.overrideWith(
            (ref) async => const MyFeatures(
              features: ['SECURITIES'],
              connectedBrokers: ['TOSS'],
              primaryBroker: 'TOSS',
            ),
          ),
          assetsProvider.overrideWith((ref) async => [inv]),
          livePricesProvider.overrideWith(
            (ref, key) async =>
                pricesFail ? throw StateError('x') : const LivePrices.empty(),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('시세를 못 받으면 valuationPriceFailed 가 참 — 평가는 서버 잔액으로 남는다', () async {
      final c = container(pricesFail: true);
      c.listen(valuationPriceFailedProvider, (_, _) {});
      await c.read(myFeaturesProvider.future);
      await c.read(assetsProvider.future);
      await c.read(investmentValuationMapProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(valuationPriceFailedProvider), isTrue);
      expect(c.read(investmentValuationMapProvider).value?[1], isNull);
    });

    test('시세를 받았으면 거짓', () async {
      final c = container(pricesFail: false);
      c.listen(valuationPriceFailedProvider, (_, _) {});
      await c.read(myFeaturesProvider.future);
      await c.read(assetsProvider.future);
      await c.read(investmentValuationMapProvider.future);
      expect(c.read(valuationPriceFailedProvider), isFalse);
    });

    testWidgets('투자 묶음 — notice 가 머리 아래, 줄 위에 선다(서버 잔액 숫자는 그대로)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            valuationPricesProvider.overrideWith(
              (ref) =>
                  AsyncError<LivePrices>(StateError('x'), StackTrace.empty),
            ),
          ],
          child: MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AssetGroupSection(
                  title: '투자',
                  assets: [inv],
                  total: 500000,
                  masked: false,
                  loading: false,
                  notice: AssetPriceFailure(onRetry: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final band = find.byKey(const ValueKey('asset-price-failure'));
      expect(band, findsOneWidget);
      expect(findTextContaining(_fail), findsOneWidget);
      // 한 번도 시세를 못 받았다 — 숫자는 서버 잔액
      expect(findTextContaining('보이는 값은 시세가 아닌 마지막 잔액이에요.'), findsOneWidget);
      expect(find.byType(PCallout), findsOneWidget);
      expect(
        tester.getTopLeft(band).dy <
            tester.getTopLeft(find.byKey(const ValueKey('asset-row-1'))).dy,
        isTrue,
      );
    });
  });
}
