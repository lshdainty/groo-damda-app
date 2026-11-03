/// 나무 종목 상세 · 포트폴리오 구성 — 화면(주소)이다(I-13 13-3 · 3-B).
/// `/stocks/namu/:symbol` · `/stocks/namu/portfolio` 만으로 열린다(목록 상태를 넘겨받지 않는다).
///
/// 13b-1: 상세 시세는 `/namu/{kr|gb}/quote` 하나(머리 · 오늘 시세 · 호가 · 경고 · 기본 정보), 체결은 `/namu/*/executions`,
/// 투자자별은 `/namu/kr/investors`(국내만). 투자 지표 · ETF · 시간외 · 5년 차트는 13b-3 몫이다.
/// 나무 상세에는 매도 · 매수가 없다(읽기 전용).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/stocks/application/namu_model.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_web_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_broker_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart'
    show StocksQuotesCard, fmtCapKrw, fmtShares;
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 종목 상세 화면 — 폰 띠 차례(U3): 머리 · 차트 / 내 보유 / 오늘 시세 / 호가 · 체결 / 투자자별(국내) / 기본 정보 / 일별 시세.
/// 보유 종목이 아니면 내 보유 띠가 없고, 미국 종목은 투자자별 띠가 없다.
class NamuStockDetailPage extends ConsumerStatefulWidget {
  const NamuStockDetailPage({super.key, required this.symbol});
  final String symbol;

  @override
  ConsumerState<NamuStockDetailPage> createState() =>
      _NamuStockDetailPageState();
}

class _NamuStockDetailPageState extends ConsumerState<NamuStockDetailPage> {
  String _range = '1D';
  Timer? _timer;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    // 상세 시세(머리 · 오늘 시세 · 호가 · 기본 정보)는 10초마다 — 상세가 보일 때만. 서버가 사용자 × 종목 20초
    // 캐시를 쥐어 상류는 20초에 한 번이다.
    _timer = Timer.periodic(namuDetailPollInterval, (_) {
      // 앱이 뒤로 가 있거나(H4) 다른 화면 · 시트가 위에 올라와 있으면 멈춘다.
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      ref.invalidate(namuQuoteDetailProvider);
      // 일별 시세는 하루 단위라 5분마다만 다시 받는다 — 열어 둔 채 굳지 않게(H3). 10초 박자 × 30.
      if (++_ticks % (kNamuDailyRefreshTicks * 3) == 0) {
        ref.invalidate(namuDailyCandlesProvider(widget.symbol));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 오늘 시세 · 호가 · 체결 띠 — 상세 시세 응답에 기댄다.
  List<Widget> _detailBands(
    BuildContext context,
    NamuQuoteDetail? detail,
    NamuDetailKey key,
    double? last,
    double? changePct, {
    required bool marketKnown,
  }) {
    final l = AppLocalizations.of(context);
    final currency = key.us ? 'USD' : 'KRW';
    final loading = detail == null;
    // 시장(국내 · 미국)을 모르는 동안은 호가 카드가 시세를 부르지 않는다 — 국내 경로로 가정해 부르면 미국 종목이
    // 실패하고, 검색이 실패하면 10초마다 계속 나간다(N4). 자리만 Skeleton 으로 둔다.
    if (!marketKnown) {
      return [
        const StocksTodayBand(rows: [], loading: true),
        PScreenSection(
          padding: const EdgeInsets.only(bottom: PSpacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StocksBandTitle(l.stocksOrderbookTrades),
              Semantics(
                label: l.stocksOrderbookLoading,
                child: Column(
                  children: [
                    for (var i = 0; i < 4; i++) const StocksLineSkeleton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      StocksTodayBand(
        rows: detail == null
            ? const []
            : todayRowsOf(
                context,
                currency: currency,
                open: detail.open,
                high: detail.high,
                low: detail.low,
                volume: detail.volume,
                upper: detail.upperLimit,
                lower: detail.lowerLimit,
              ),
        loading: loading,
      ),
      // 호가 · 체결(고른 탭 · 체결 타이머)도 스크롤로 화면 밖에 나가도 지킨다(N8, 토스와 같다)
      StocksKeepAlive(
        child: PScreenSection(
          padding: const EdgeInsets.only(bottom: PSpacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StocksBandTitle(l.stocksOrderbookTrades),
              _NamuQuotesBand(
                detailKey: key,
                currency: currency,
                lastPrice: last,
                changePct: changePct,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    final symbol = widget.symbol;

    // 시장(통화)을 알 때까지 기다린다(H5, 웹처럼 market=null) — 모르는 채 국내로 가정해 값 · 차트를 그리지 않는다.
    // 검색은 실패를 던지는 쪽을 쓴다(자산의 종목 추가가 쓰는 swallow 판은 실패를 빈 결과로 삼킨다).
    final searchAsync = ref.watch(stockSearchResultProvider(symbol));
    final master = findMasterBySymbol(
      searchAsync.value ?? const <StockMasterItem>[],
      symbol,
    );
    final krwAsync = ref.watch(namuHoldingsProvider('KRW'));
    final usdAsync = ref.watch(namuHoldingsProvider('USD'));
    final fx = ref.watch(namuExchangeRateProvider).value;
    final view = mergeNamuHoldings(krwAsync.value, usdAsync.value, fx);
    final holding = view.rows.where((r) => r.symbol == symbol).firstOrNull;
    final groups =
        ref.watch(watchGroupsProvider).value ?? const <StockWatchGroup>[];
    final watched = groups.any((g) => g.items.any((i) => i.symbol == symbol));

    final name = master?.nameKr.isNotEmpty == true
        ? master!.nameKr
        : (holding?.name ?? symbol);
    // 보유 종목이면 행이 자기 통화를 안다. 아니면 마스터가 안다.
    final currency =
        holding?.currency ??
        (master?.currency.isNotEmpty == true ? master!.currency : 'KRW');
    final isUs = currency == 'USD';
    // 보유 종목이면 행이 통화를 안다. 아니면 마스터 검색이 끝나야 안다(받는 중 · 실패면 모르는 상태).
    final marketKnown =
        holding != null || master != null || searchAsync.hasValue;
    final marketFailed = !marketKnown && searchAsync.hasError;

    // 상세 시세 — 보유 종목도 부른다(오늘 시세 · 호가 · 기본 정보가 같은 응답). 시장(국내 · 미국)을 알 때까지는
    // 부르지 않는다(H5) — 모르는 채 국내 경로로 가정하지 않는다. 머리 가격은 이 응답이 먼저, 아직 못 받았거나
    // 실패했으면 보유 종목의 잔고 값을 임시로 쓴다.
    final key = (symbol: symbol, us: isUs);
    final detailAsync = marketKnown
        ? ref.watch(namuQuoteDetailProvider(key))
        : null;
    final detail = detailAsync?.value;
    final lastRaw = detail?.price ?? holding?.currentPrice;
    final last = (lastRaw != null && lastRaw > 0) ? lastRaw : null;
    final prevClose = detail?.previousClose;
    final changePct = changePctOf(last, prevClose);
    final detailFailed =
        detailAsync != null && detailAsync.hasError && !detailAsync.hasValue;
    // 상세 시세 질의가 끝난 뒤(성공 · 실패 모두) 투자자별 · 일별 시세를 연다 — 나무 초당 5회 제한을 몰아치지 않는다.
    final detailSettled =
        detailAsync != null && (!detailAsync.isLoading || detailAsync.hasValue);

    final sub = master != null
        ? '$symbol · ${stockMarketLabel(l, master.marketCode)}'
        : symbol;

    final head = PScreenSection(
      padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  keepAll(name),
                  style: PTypography.t7.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.fgNeutral,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                ),
                const SizedBox(height: PSpacing.x4),
                Text(
                  keepAllAmount(
                    last != null ? fmtByCurrency(last, currency) : '—',
                  ),
                  style: PTypography.t12.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.fgNeutral,
                    fontFeatures: kStocksTnum,
                  ),
                ),
                if (changePct != null && last != null && prevClose != null) ...[
                  const SizedBox(height: PSpacing.x1),
                  // "▲ 45,200원 · 0.30%" — 금액(전일 종가 대비)과 등락률(13-1 M5 와 같게)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: namuPnlDelta(
                      last - prevClose,
                      changePct,
                      currency,
                      false,
                    ),
                  ),
                ],
                if (detailAsync != null &&
                    detailAsync.hasError &&
                    !detailAsync.hasValue)
                  // 시세 실패는 글 한 줄이 아니라 실패 한 벌 + [다시 시도](M4)
                  StocksFailure(
                    title: l.stocksFailPrice,
                    onRetry: () => ref.invalidate(namuQuoteDetailProvider(key)),
                  )
                else if (marketKnown &&
                    last == null &&
                    !(detailAsync?.isLoading ?? false)) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.namuPriceEmpty,
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ],
                if ((detail?.warnings ?? const <String>[]).isNotEmpty) ...[
                  const SizedBox(height: PSpacing.x2),
                  Wrap(
                    spacing: PSpacing.x1,
                    runSpacing: PSpacing.x1,
                    children: [
                      for (final w in detail!.warnings)
                        PBadge(
                          label: stocksWarningLabel(l, w),
                          tone: PBadgeTone.warning,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: PSpacing.x4),
                if (marketFailed)
                  StocksFailure(
                    title: l.stocksFailInfo,
                    onRetry: () =>
                        ref.invalidate(stockSearchResultProvider(symbol)),
                  )
                else if (!marketKnown)
                  const PSkeleton(height: kStockChartWebViewHeight)
                else
                  ChartWebView(
                    symbol: symbol,
                    isUs: isUs,
                    range: _range,
                    height: kStockChartWebViewHeight,
                    broker: 'namu',
                  ),
                const SizedBox(height: PSpacing.x3),
              ],
            ),
          ),
          // 차트 기간 5칸 — 전용 Segmented(칸 좌우 4). 글은 static 16 이라 글자 200% 에서도 안 꺾인다.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: PSegmentedControl<String>.chartPeriod(
              value: _range,
              onChanged: (v) => setState(() => _range = v),
              semanticLabel: l.stocksDetailTitle,
              items: [
                for (final r in kStockRanges)
                  PSegmentedItem(value: r, label: stockRangeLabel(l, r)),
              ],
            ),
          ),
        ],
      ),
    );

    // 머리(차트 WebView)는 스크롤로 화면 밖에 나가도 지키고 있는다 — 내렸다 올릴 때 차트가 다시 지어지지 않게(M13).
    final bands = <Widget>[
      StocksKeepAlive(child: head),
      if (holding != null) _NamuHoldingBand(holding: holding, masked: masked),
      // 시세 질의에 기대는 띠는 질의가 실패하면 그리지 않는다(머리에 "시세를 불러오지 못했어요" 한 번).
      if (!detailFailed)
        ..._detailBands(
          context,
          detail,
          key,
          last,
          changePct,
          marketKnown: marketKnown,
        ),
      if (!isUs || !marketKnown)
        detailSettled
            ? _NamuInvestorBand(symbol: symbol)
            : StocksInvestorBand(
                days: null,
                loading: true,
                failed: false,
                onRetry: () {},
              ),
      // 시장을 모르면 시장 · 통화 줄을 지어내지 않는다(국내 · KRW 로 가정하지 않는다)
      if (marketKnown)
        _NamuInfoBand(
          master: master,
          currency: currency,
          detail: detail,
          isUs: isUs,
          fx: fx,
        )
      else
        PScreenSection(
          padding: const EdgeInsets.only(bottom: PSpacing.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StocksBandTitle(l.stocksBasicInfo),
              for (var i = 0; i < 3; i++) const StocksLineSkeleton(),
            ],
          ),
        ),
      detailSettled
          ? _NamuDailyBand(symbol: symbol, currency: currency)
          : _NamuDailyPlaceholder(),
    ];

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.stocksDetailTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/stocks'),
          ),
          actions: [
            PTopNavigationIconButton(
              icon: LucideIcons.star,
              // 켬은 선 2.5(toggle.md:31) — 끔은 선 2. 색은 상단 바 안이라 둘 다 fg-neutral
              selectedIcon: LucideIcons.star500,
              label: l.stocksWatchToggleLabel,
              selected: watched,
              onPressed: () => toggleWatch(
                context,
                ref,
                symbol,
                marketCode: master?.marketCode,
              ),
            ),
          ],
        ),
      ),
      body: ListView(children: PScreenBands.children(bands)),
    );
  }
}

/// 띠 ② 내 보유 — 잔고 응답이 주는 여섯 줄 + 미국 종목의 매도가능(국내 잔고에는 수수료 · 세금 · 매도가능이 없다). 한 줄에 하나.
class _NamuHoldingBand extends StatelessWidget {
  const _NamuHoldingBand({required this.holding, required this.masked});
  final NamuMergedHolding holding;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = holding;
    final cur = h.currency;
    String money(double v) => masked ? '••••' : fmtByCurrency(v, cur);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksMyHoldings),
          PList(
            children: [
              stocksKvLine(context, l.stocksEvalAmount, money(h.evalAmount)),
              stocksKvLine(
                context,
                l.stocksEvalPnl,
                '',
                valueWidget: namuPnlDelta(
                  h.profitLoss,
                  h.returnPct,
                  cur,
                  masked,
                ),
              ),
              stocksKvLine(
                context,
                l.stocksQuantityHeld,
                l.stocksSharesUnit(stocksQty(h.quantity)),
              ),
              stocksKvLine(
                context,
                l.stocksReturnRate,
                '',
                valueWidget: StocksPctDelta(h.returnPct),
              ),
              stocksKvLine(context, l.stocksAvgPrice, money(h.avgPrice)),
              stocksKvLine(
                context,
                l.stocksPurchaseAmount,
                money(h.costAmount),
              ),
              // 매도가능 — 미국 종목만(국내 잔고에는 이 칸이 없어 줄을 그리지 않는다).
              if (h.sellable != null)
                stocksKvLine(
                  context,
                  l.stocksSellable,
                  l.stocksSharesUnit(stocksQty(h.sellable!)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 띠 — 기본 정보. 시장 · 유형 · 통화는 마스터, 업종 · 시가총액 · 상장일 · 상장(발행)주식수는 상세 시세 응답.
/// 시가총액 꼴은 토스와 같다(원으로 줄여 쓴다). 나무 현재가 응답에는 거래정지 칸이 없어 "거래상태" 줄은 없다.
class _NamuInfoBand extends StatelessWidget {
  const _NamuInfoBand({
    required this.master,
    required this.currency,
    required this.detail,
    required this.isUs,
    required this.fx,
  });
  final StockMasterItem? master;
  final String currency;
  final NamuQuoteDetail? detail;
  final bool isUs;
  final double? fx;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = master;
    final d = detail;
    // 미국 시가총액은 달러로 온다 — 환율이 있으면 토스처럼 원으로, 없으면 달러 그대로.
    String? cap;
    if (d?.marketCap != null) {
      cap = !isUs
          ? fmtCapKrw(d!.marketCap!)
          : (fx != null && fx! > 0
                ? fmtCapKrw(d!.marketCap! * fx!)
                : fmtCapUsd(d!.marketCap!));
    }
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksBasicInfo),
          PList(
            semanticLabel: l.stocksBasicInfo,
            children: [
              stocksKvLine(
                context,
                l.stocksMarket,
                m != null
                    ? stockMarketLabel(l, m.marketCode)
                    : (currency == 'USD' ? l.stocksMarketUs : l.stocksMarketKr),
              ),
              stocksKvLine(
                context,
                l.stocksInstrumentType,
                m?.securityType == 'ETF' ? 'ETF' : l.stocksInstrumentStock,
              ),
              stocksKvLine(context, l.stocksCurrency, currency),
              if (d?.sector != null)
                stocksKvLine(context, l.stocksSector, d!.sector!),
              if (cap != null) stocksKvLine(context, l.stocksMarketCap, cap),
              if (d?.listingDate != null)
                stocksKvLine(
                  context,
                  l.stocksListingDate,
                  fullDateOf(d!.listingDate!),
                ),
              if (d?.listedShares != null)
                stocksKvLine(
                  context,
                  isUs ? l.stocksSharesOutstanding : l.stocksListedShares,
                  fmtShares(d!.listedShares!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 띠 — 호가 · 체결. 호가는 상세 시세 응답의 `orderbook`(20초에 한 번 바뀐다), 체결은 `/namu/*/executions`
/// (5초 · **체결 탭이 골라져 있고 화면이 보일 때만**).
class _NamuQuotesBand extends ConsumerStatefulWidget {
  const _NamuQuotesBand({
    required this.detailKey,
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final NamuDetailKey detailKey;
  final String currency;
  final double? lastPrice;
  final double? changePct;

  @override
  ConsumerState<_NamuQuotesBand> createState() => _NamuQuotesBandState();
}

class _NamuQuotesBandState extends ConsumerState<_NamuQuotesBand> {
  Timer? _tradesTimer;

  void _onTab(String tab) {
    _tradesTimer?.cancel();
    _tradesTimer = null;
    if (tab == 'tape') {
      _tradesTimer = Timer.periodic(namuTradesPollInterval, (_) {
        // 앱이 뒤로 가 있거나 다른 화면 · 시트가 위에 올라와 있으면 멈춘다(H4).
        if (!mounted ||
            !ref.read(appForegroundProvider) ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        ref.invalidate(namuExecutionsProvider(widget.detailKey));
      });
    }
  }

  @override
  void dispose() {
    _tradesTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.detailKey;
    return StocksQuotesCard(
      symbol: key.symbol,
      currency: widget.currency,
      lastPrice: widget.lastPrice,
      changePct: widget.changePct,
      onTabChanged: _onTab,
      onRetryBook: (ref) => ref.invalidate(namuQuoteDetailProvider(key)),
      onRetryTrades: (ref) => ref.invalidate(namuExecutionsProvider(key)),
      watchBook: (ref) =>
          ref.watch(namuQuoteDetailProvider(key)).whenData((d) => d.orderbook),
      watchTrades: (ref) => ref.watch(namuExecutionsProvider(key)),
    );
  }
}

/// 띠 — 투자자별 매매동향(국내 종목만).
class _NamuInvestorBand extends ConsumerWidget {
  const _NamuInvestorBand({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(namuInvestorsProvider(symbol));
    return StocksInvestorBand(
      days: async.value,
      loading: async.isLoading,
      failed: async.hasError,
      onRetry: () => ref.invalidate(namuInvestorsProvider(symbol)),
    );
  }
}

/// 상세 시세 질의가 끝나기 전의 일별 시세 자리 — 일별 시세 질의는 아직 열지 않는다.
class _NamuDailyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksDailyPrices),
          Semantics(
            label: l.stocksDailyPricesLoading,
            child: Column(
              children: [
                for (var i = 0; i < 5; i++) const StocksLineSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 띠 — 일별 시세. 일봉(`/namu/candles`)에서 파생한다. 끝에 시세는 참고용 안내 한 줄(첫 증권사 안내는 없다).
class _NamuDailyBand extends ConsumerWidget {
  const _NamuDailyBand({required this.symbol, required this.currency});
  final String symbol;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(namuDailyCandlesProvider(symbol));
    final page = async.value;
    final asc = page == null
        ? const <TossCandle>[]
        : ([...page.candles]
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
    final recent = asc.length > 9 ? asc.sublist(asc.length - 9) : asc;
    final rows = <({String date, double close, double chg, int vol})>[];
    for (var i = recent.length - 1; i >= 1; i--) {
      final cd = recent[i];
      final prev = recent[i - 1].closeValue;
      final close = cd.closeValue;
      final chg = prev > 0 ? (close - prev) / prev * 100 : 0.0;
      final ts = cd.timestamp;
      final d = ts.length >= 10 ? DateTime.tryParse(ts.substring(0, 10)) : null;
      rows.add((
        date: d == null ? ts : l.stocksDailyDate(d.month, d.day),
        close: close,
        chg: chg,
        vol: cd.volumeValue.round(),
      ));
      if (rows.length >= 8) break;
    }
    final Widget list;
    if (async.hasError && !async.hasValue) {
      list = StocksFailure(
        title: l.stocksFailDaily,
        onRetry: () => ref.invalidate(namuDailyCandlesProvider(symbol)),
      );
    } else if (async.isLoading && !async.hasValue) {
      list = Semantics(
        label: l.stocksDailyPricesLoading,
        child: Column(
          children: [for (var i = 0; i < 5; i++) const StocksLineSkeleton()],
        ),
      );
    } else if (rows.isEmpty) {
      list = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.chartCandlestick,
        title: l.stocksDailyPricesEmpty,
        headingLevel: 3,
      );
    } else {
      list = PList(
        children: [
          for (final r in rows)
            PListItem(
              title: r.date,
              detail: l.stocksDailyVolume(krw(r.vol)),
              suffix: PListValue(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      keepAllAmount(fmtByCurrency(r.close, currency)),
                      style: stocksMoneyStyle(context),
                    ),
                    const SizedBox(height: 2),
                    StocksPctDelta(r.chg),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksDailyPrices),
          list,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x3,
              PSpacing.x6,
              0,
            ),
            child: Text(
              l.stocksDisclaimerLine2,
              textAlign: TextAlign.center,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

/// 포트폴리오 구성 화면 — 도넛 112 + 범례. 비중은 원화로 환산해 센다. 환율이 없으면 도넛 대신 안내.
class NamuPortfolioPage extends ConsumerWidget {
  const NamuPortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final krwAsync = ref.watch(namuHoldingsProvider('KRW'));
    final usdAsync = ref.watch(namuHoldingsProvider('USD'));
    final fxAsync = ref.watch(namuExchangeRateProvider);
    final view = mergeNamuHoldings(
      krwAsync.value,
      usdAsync.value,
      fxAsync.value,
    );
    final loading =
        (krwAsync.isLoading && !krwAsync.hasValue) ||
        (usdAsync.isLoading && !usdAsync.hasValue);
    final failed =
        krwAsync.hasError &&
        !krwAsync.hasValue &&
        usdAsync.hasError &&
        !usdAsync.hasValue;
    final comp = namuCompositionOf(view);
    // 금액 가리기 — 도넛 조각 금액도, 범례 비중도 가린다(13-1 H5 와 같게)
    final masked = ref.watch(hideCardProvider('stocks.summary'));

    Widget content;
    if (failed) {
      content = StocksFailure(
        title: l.stocksFailInvest,
        description: l.namuFailDesc,
        onRetry: () {
          ref.invalidate(namuHoldingsProvider('KRW'));
          ref.invalidate(namuHoldingsProvider('USD'));
        },
      );
    } else if (loading) {
      content = Padding(
        padding: const EdgeInsets.all(PSpacing.x6),
        child: Center(
          child: PSkeleton(
            width: 112,
            height: 112,
            radius: PSkeletonRadius.full,
          ),
        ),
      );
    } else if (view.count == 0) {
      content = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.wallet,
        title: l.stocksNoHoldings,
        headingLevel: 2,
      );
    } else if (comp == null) {
      content = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.chartPie,
        title: l.namuDonutNeedsFx,
        headingLevel: 2,
      );
    } else {
      content = StocksCompositionBody(comp: comp, masked: masked);
    }

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.stocksPortfolioTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/stocks'),
          ),
        ),
      ),
      body: ListView(
        children: [PScreenSection(padding: EdgeInsets.zero, child: content)],
      ),
    );
  }
}
