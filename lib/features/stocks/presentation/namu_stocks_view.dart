import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/sync/query_freshness.dart';
import 'package:groo_damda_app/features/stocks/application/namu_model.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_broker_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 나무증권 폰 화면 — 토스와 같은 띠 틀(내 투자 → 시장 → 종목, I-13 13-3).
///
/// 나무에 없는 것(지수 · 발견 · 일간 손익)은 그리지 않는다. 국내 · 해외 두 응답은 한 목록으로 합쳐
/// 보이고, 통화를 나눠 보려면 목록 위 Segmented 로 거른다. 종목 상세와 포트폴리오 구성은 화면(주소)이다
/// (`/stocks/namu/:symbol` · `/stocks/namu/portfolio`).
///
/// 13b-1 이 더한 것: 시장 띠의 장 상태 줄, 내 투자의 주문 가능 줄(원화 · 예수금 달러). 투자 지표 · ETF · 시간외 ·
/// 계좌 자세히는 13b-3 몫이다.
class NamuStocksView extends ConsumerStatefulWidget {
  const NamuStocksView({super.key});

  @override
  ConsumerState<NamuStocksView> createState() => _NamuStocksViewState();
}

enum _Seg { holdings, watch }

String namuDetailPath(String symbol) =>
    '/stocks/namu/${Uri.encodeComponent(symbol)}';

class _NamuStocksViewState extends ConsumerState<NamuStocksView> {
  _Seg _seg = _Seg.holdings;
  String _filter = 'ALL';
  Timer? _priceTimer;
  int _ticks = 0;

  /// 지금 지켜보는 관심 시세 키(콤마 심볼 묶음) — 박자마다 이 키만 다시 부른다.
  Set<String> _quoteKeys = const {};

  /// 시장 띠 장 상태의 대표 종목 — 정한 뒤에는 정렬이 바뀌어도 그대로 둔다(M14).
  String? _repKr;
  String? _repUs;

  /// 화면에 들어와 300ms 머문 관심 그룹 — 이 그룹들의 심볼만 합쳐 시세를 부른다(I-13 22).
  final Set<int> _visible = {};
  final Map<int, Timer> _lingering = {};

  /// 받은 시세 — 그룹이 화면 밖으로 나가 부르기를 멈춰도 받은 값은 남긴다.
  final Map<String, NamuListQuote> _lastQuotes = {};

  @override
  void initState() {
    super.initState();
    // 박자는 웹 나무 화면과 같다(namu_providers.dart 의 표). 관심 시세는 30초마다 — 앱이 가려진 동안은 멈춘다.
    // 보유 종목은 주기로 조르지 않는다. 화면에 들어올 때 · 앱으로 돌아올 때 받은 지 30초가 지났으면 다시 받는다.
    _priceTimer = Timer.periodic(namuPricePollInterval, (_) {
      // 앱이 뒤로 가 있거나(H4) 상세 · 포트폴리오 · 시트가 위에 올라와 있으면 멈춘다 — 그 화면이 제 몫만 부른다(H3).
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      // 지켜보는 키만 다시 부른다 — family 전체를 비우면 다른 화면(상세)의 시세까지 같이 나간다(H4).
      if (_seg == _Seg.watch) {
        for (final key in _quoteKeys) {
          ref.invalidate(namuQuotesProvider(key));
        }
      }
      // 환율은 웹처럼 10분마다 다시 받는다 — 처음 값으로 굳지 않게(H3).
      if (++_ticks % kNamuFxRefreshTicks == 0) {
        ref.invalidate(namuExchangeRateProvider);
      }
    });
    ref.listenManual(appForegroundProvider, (wasForeground, isForeground) {
      if (isForeground && wasForeground == false) _refreshHoldingsIfStale();
    });
    // 첫 판정은 microtask 로 미룬다 — initState 안에서는 provider 를 비우지 못한다(빌드 중이다).
    Future.microtask(_refreshHoldingsIfStale);
  }

  /// 두 통화 보유 종목이 낡았으면 다시 받는다.
  void _refreshHoldingsIfStale() {
    if (!mounted) return;
    for (final currency in const ['KRW', 'USD']) {
      final provider = namuHoldingsProvider(currency);
      // 아직 안 읽은 통화는 화면이 그려지면서 처음 받는다. 받는 중이면 그 결과를 기다린다.
      if (!ref.exists(provider) || ref.read(provider).isLoading) continue;
      // 시각은 성공한 조회만 남긴다 — 실패한 조회는 늘 낡은 것으로 읽힌다.
      final fetchedAt = ref.read(namuHoldingsFetchedAtProvider)[currency];
      if (namuHoldingsStale(fetchedAt, ref.read(freshnessClockProvider)())) {
        ref.invalidate(provider);
      }
    }
    // 주문 가능 · 달러(margin)는 보유와 같은 규칙 — 진입 · 창 복귀 때 60초 지났으면 다시.
    if (ref.exists(namuUsdDepositProvider) &&
        !ref.read(namuUsdDepositProvider).isLoading) {
      final at = ref.read(namuMarginFetchedAtProvider)['USD'];
      if (namuMarginStale(at, ref.read(freshnessClockProvider)())) {
        ref.invalidate(namuUsdDepositProvider);
      }
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    for (final t in _lingering.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _blockShown(int id) {
    if (_visible.contains(id) || _lingering.containsKey(id)) return;
    _lingering[id] = Timer(const Duration(milliseconds: 300), () {
      _lingering.remove(id);
      if (mounted) setState(() => _visible.add(id));
    });
  }

  void _blockHidden(int id) {
    _lingering.remove(id)?.cancel();
    if (!_visible.contains(id)) return;
    // 묶음이 사라지는 자리(트리를 걷는 중)에서 불린다 — 바로 setState 하면 "잠긴 트리" 예외라 한 프레임 뒤로 미룬다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _visible.contains(id)) {
        setState(() => _visible.remove(id));
      }
    });
  }

  void _openSearch() => showStockSearchSheet(
    context,
    onPick: (symbol) => context.push(namuDetailPath(symbol)),
  );

  void _openDetail(String symbol) => context.push(namuDetailPath(symbol));

  void _retryInvest() {
    ref.invalidate(namuHoldingsProvider('KRW'));
    ref.invalidate(namuHoldingsProvider('USD'));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    final krwAsync = ref.watch(namuHoldingsProvider('KRW'));
    final usdAsync = ref.watch(namuHoldingsProvider('USD'));
    final fxRaw = ref.watch(namuExchangeRateProvider).value;
    final fx = (fxRaw != null && fxRaw > 0) ? fxRaw : null;
    final view = mergeNamuHoldings(krwAsync.value, usdAsync.value, fx);
    // 둘 다 실패해야 오류다 — 한쪽만 실패하면 남은 통화만 보인다. 다시 받는 동안에도 실패를 그대로 두고 단추에 진행 원
    final bothFailed = krwAsync.loadFailed && usdAsync.loadFailed;
    final investRetrying = anyLoadRetrying([krwAsync, usdAsync]);
    final loading =
        !bothFailed &&
        ((krwAsync.isLoading && !krwAsync.hasValue) ||
            (usdAsync.isLoading && !usdAsync.hasValue));

    final watchAsync = ref.watch(watchGroupsProvider);
    final groups = watchAsync.value ?? const <StockWatchGroup>[];
    // 보이는 그룹의 심볼을 합쳐 50 씩 한 번에 — 그룹마다 따로 부르지 않는다.
    final keys = <String>{};
    // 관심 시세 — 처음부터 실패면 줄이 "—" 만, 받아 둔 값이 있으면 옛 값이다. 묶음 위에 띠 한 줄(I-wrap-b2b 4)
    final watchQuotes = <AsyncValue<List<NamuListQuote>>>[];
    if (_seg == _Seg.watch) {
      for (final chunk in chunkSymbols(visibleSymbols(groups, _visible))) {
        keys.add(chunk.join(','));
        final quotesAsync = ref.watch(namuQuotesProvider(chunk.join(',')));
        watchQuotes.add(quotesAsync);
        final quotes = quotesAsync.value ?? const <NamuListQuote>[];
        for (final q in quotes) {
          if (q.price > 0) _lastQuotes[q.symbol] = q;
        }
      }
    }

    _quoteKeys = keys;
    final reps = namuMarketRepresentatives(
      view,
      groups,
      prevKr: _repKr,
      prevUs: _repUs,
    );
    _repKr = reps.kr;
    _repUs = reps.us;

    final head = <Widget>[
      NamuInvestBand(
        krwAsync: krwAsync,
        usdAsync: usdAsync,
        view: view,
        loading: loading,
        failed: bothFailed,
        retrying: investRetrying,
        masked: masked,
        onRetry: _retryInvest,
      ),
      const SizedBox(height: kScreenBandGap),
      NamuMarketBand(
        krSymbol: reps.kr,
        usSymbol: reps.us,
        // 보유 질의(와 관심 그룹)가 끝나기 전에는 대표를 못 정한다 — 그동안 장 상태 자리는 Skeleton 이다.
        // 보유 질의가 실패했거나 보유가 0 이면 "끝난 것" 이라 관심 첫 종목 · 대표 없음으로 넘어간다.
        ready: !loading && !(watchAsync.isLoading && !watchAsync.hasValue),
      ),
      const SizedBox(height: kScreenBandGap),
    ];

    final tabs = ColoredBox(
      color: c.bgLayerDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksSectionStocks),
          StocksSearchEntry(onTap: _openSearch),
          Padding(
            padding: const EdgeInsets.only(top: PSpacing.x2),
            child: PChipTabs<_Seg>(
              value: _seg,
              onChanged: (v) => setState(() => _seg = v),
              semanticLabel: l.stocksSectionStocks,
              items: [
                PTab(value: _Seg.holdings, label: l.stocksTabHoldings),
                PTab(value: _Seg.watch, label: l.stocksTabWatch),
              ],
            ),
          ),
        ],
      ),
    );

    final tail = ColoredBox(
      color: c.bgLayerDefault,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.x6,
          PSpacing.x2,
          PSpacing.x6,
          PSpacing.x6,
        ),
        child: PText(
          l.namuDataNotice,
          style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
        ),
      ),
    );

    // 관심 갈래는 게으른 sliver — 지어진 묶음만 시세를 지켜본다. 나머지는 한 덩어리.
    final slivers = <Widget>[
      SliverList(delegate: SliverChildListDelegate(head)),
      SliverToBoxAdapter(child: tabs),
    ];
    if (_seg == _Seg.watch) {
      if (watchAsync.hasError && !watchAsync.hasValue) {
        slivers.add(
          SliverToBoxAdapter(
            child: StocksFailure(
              title: l.stocksFailWatch,
              retrying: watchAsync.isLoading,
              onRetry: () => ref.invalidate(watchGroupsProvider),
            ),
          ),
        );
      } else if (watchAsync.isLoading && !watchAsync.hasValue) {
        slivers.add(
          SliverToBoxAdapter(child: loadingRegion(const StocksGroupSkeleton())),
        );
      } else if (groups.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: ColoredBox(
              color: c.bgLayerDefault,
              child: PResultSection(
                kind: PResultKind.empty,
                size: PResultSize.medium,
                icon: LucideIcons.star,
                title: l.stocksNoWatchlist,
                description: l.stocksNoWatchlistDesc,
                headingLevel: 3,
              ),
            ),
          ),
        );
      } else {
        if (watchQuotes.any((v) => v.pollFailed)) {
          slivers.add(
            SliverToBoxAdapter(
              child: StocksPriceFailure(
                stale: watchQuotes.any((v) => v.hasValue),
                retrying: watchQuotes.any((v) => v.pollFailed && v.isLoading),
                onRetry: () => ref.invalidate(namuQuotesProvider),
              ),
            ),
          );
        }
        slivers.add(
          SliverList.builder(
            itemCount: groups.length + 1,
            itemBuilder: (context, i) {
              if (i == groups.length) {
                return ColoredBox(
                  color: c.bgLayerDefault,
                  child: PList(
                    children: [
                      PListButtonItem(
                        title: l.stocksWatchGroupAdd,
                        titleColor: c.fgBrand,
                        prefix: Icon(
                          LucideIcons.plus,
                          size: 20,
                          color: c.fgBrand,
                        ),
                        onTap: () => showWatchGroupForm(context, ref),
                      ),
                    ],
                  ),
                );
              }
              final g = groups[i];
              return WatchGroupBlock(
                key: ValueKey('watch-group-${g.rowId}'),
                group: g,
                first: i == 0,
                onShown: () => _blockShown(g.rowId),
                onHidden: () => _blockHidden(g.rowId),
                lineBuilder: (item) => _watchLine(l, item),
              );
            },
          ),
        );
      }
    } else {
      slivers.add(
        SliverToBoxAdapter(
          child: ColoredBox(
            color: c.bgLayerDefault,
            child: _holdingsBand(
              l,
              view,
              loading,
              bothFailed,
              masked,
              retrying: investRetrying,
            ),
          ),
        ),
      );
    }
    slivers.add(SliverToBoxAdapter(child: tail));
    return CustomScrollView(slivers: slivers);
  }

  Widget _watchLine(AppLocalizations l, WatchItem item) {
    final q = _lastQuotes[item.symbol];
    return StocksLine(
      name: item.nameKr.isNotEmpty ? item.nameKr : item.symbol,
      detail: '${item.symbol} · ${stockMarketLabel(l, item.marketCode)}',
      amount: q == null ? null : fmtByCurrency(q.price, q.currency),
      pct: q == null ? null : changePctOf(q.price, q.previousClose),
      onTap: () => _openDetail(item.symbol),
    );
  }

  Widget _holdingsBand(
    AppLocalizations l,
    NamuMergedView view,
    bool loading,
    bool failed,
    bool masked, {
    bool retrying = false,
  }) {
    if (loading) {
      return Semantics(
        label: l.stocksRankingLoading,
        child: loadingRegion(
          Column(
            children: [for (var i = 0; i < 5; i++) const StocksLineSkeleton()],
          ),
        ),
      );
    }
    if (failed) {
      return StocksFailure(
        title: l.stocksFailHoldings,
        retrying: retrying,
        onRetry: _retryInvest,
        description: l.namuFailDesc,
      );
    }
    // 섞이지 않았으면 거를 게 없다 — 남은 거르기 값은 전체로 읽는다.
    final filter = view.mixed ? _filter : 'ALL';
    final shown = filter == 'ALL'
        ? view.rows
        : [
            for (final r in view.rows)
              if (r.currency == filter) r,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (view.mixed)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x1,
              PSpacing.x6,
              PSpacing.x2,
            ),
            child: PSegmentedControl<String>(
              value: filter,
              onChanged: (v) => setState(() => _filter = v),
              semanticLabel: l.namuFilterAria,
              items: [
                PSegmentedItem(value: 'ALL', label: l.namuFilterAll),
                PSegmentedItem(value: 'KRW', label: l.namuTabDomestic),
                PSegmentedItem(value: 'USD', label: l.namuTabOverseas),
              ],
            ),
          ),
        if (shown.isEmpty)
          PResultSection(
            kind: PResultKind.empty,
            size: PResultSize.medium,
            icon: LucideIcons.wallet,
            title: view.rows.isEmpty ? l.stocksNoHoldings : l.namuFilterEmpty,
            headingLevel: 3,
          )
        else
          PList(
            semanticLabel: l.stocksTabHoldings,
            children: [
              for (final r in shown)
                StocksLine(
                  key: ValueKey(r.key),
                  name: r.name,
                  detail:
                      '${r.symbol} · ${l.stocksSharesUnit(stocksQty(r.quantity))}',
                  amount: masked
                      ? '••••'
                      : fmtByCurrency(r.evalAmount, r.currency),
                  pct: r.returnPct,
                  onTap: () => _openDetail(r.symbol),
                ),
            ],
          ),
      ],
    );
  }
}

// ---- 띠 ① 내 투자 -------------------------------------------------------------

/// 통화 금액 + 손익 Delta("▲ 1,200원 · 3.10%") — 가리면 금액 대신 점.
PDelta namuPnlDelta(
  double pnl,
  double pct,
  String currency,
  bool masked, {
  String? text,
}) {
  final d = directionOf(pnl);
  final amount = masked ? '••••' : fmtByCurrency(pnl.abs(), currency);
  return PDelta(
    direction: stocksDir(d),
    value: d == StockDirection.flat
        ? null
        : '$amount · ${formatChangeRateAbs(pct)}',
    text: text,
  );
}

class NamuInvestBand extends ConsumerWidget {
  const NamuInvestBand({
    super.key,
    required this.krwAsync,
    required this.usdAsync,
    required this.view,
    required this.loading,
    required this.failed,
    required this.masked,
    required this.onRetry,
    this.retrying = false,
  });

  final AsyncValue<NamuHoldings> krwAsync;
  final AsyncValue<NamuHoldings> usdAsync;
  final NamuMergedView view;
  final bool loading;
  final bool failed;
  final bool masked;
  final VoidCallback onRetry;

  /// 실패 뒤 다시 받는 중 — [다시 시도] 에 진행 원.
  final bool retrying;

  List<Widget> _buyingPowerRows(
    BuildContext context,
    WidgetRef ref,
    bool masked,
  ) {
    final l = AppLocalizations.of(context);
    final usd = ref.watch(namuUsdDepositProvider);
    final krwOrderable = krwAsync.value?.orderableValue;
    // 국내 잔고 질의가 실패했으면(값이 없으면) 줄을 없애지 않고 "—" 로 둔다(M5) — 줄이 사라지면 0 원처럼 읽힌다.
    final krwFailed = krwAsync.hasError && !krwAsync.hasValue;
    return [
      if (krwOrderable != null || krwFailed)
        stocksBuyingPowerRow(
          context,
          title: l.stocksBuyingPowerKrw,
          state: AsyncValue3(failed: krwFailed, amount: krwOrderable),
          masked: masked,
          format: (v) => fmtByCurrency(v, 'KRW'),
        ),
      if ((usd.value?.amount != null) ||
          (usd.isLoading && !usd.hasValue) ||
          (usd.hasError && !usd.hasValue))
        stocksBuyingPowerRow(
          context,
          title: l.namuDepositUsd,
          state: AsyncValue3(
            loading: usd.isLoading && !usd.hasValue,
            failed: usd.hasError && !usd.hasValue,
            amount: usd.value?.amount,
          ),
          masked: masked,
          format: (v) => fmtByCurrency(v, 'USD'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (failed) {
      return PScreenSection(
        padding: EdgeInsets.zero,
        child: StocksFailure(
          title: l.stocksFailInvest,
          retrying: retrying,
          onRetry: onRetry,
          description: l.namuFailDesc,
        ),
      );
    }
    if (loading) {
      return PScreenSection(
        padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
        child: Semantics(
          label: l.stocksMyEval,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PText(
                  l.namuDomesticValue,
                  style: PTypography.t3.copyWith(
                    color: c.fgNeutralSubtle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: PSpacing.x1),
                PSkeleton(width: 200, height: 32),
                const SizedBox(height: PSpacing.x1),
                PSkeleton(width: 160, height: 18),
              ],
            ),
          ),
        ),
      );
    }

    String won(double v) =>
        masked ? '••••' : krwSigned(v.round(), false, unit: true);
    String cur(NamuCurrencyTotal t) =>
        masked ? '••••' : fmtByCurrency(t.evalAmount, t.currency);
    PDelta pnl(NamuCurrencyTotal t, {String? text}) => namuPnlDelta(
      t.profitLoss,
      t.profitRatePct,
      t.currency,
      masked,
      text: text,
    );

    // 지표 — 섞였고 환율이 있으면 원화 환산 합계, 아니면 있는 통화 하나(국내 먼저).
    final total = view.mixed && view.totalKrw != null;
    final main = total ? null : (view.krw ?? view.usd);
    final String label;
    final String amount;
    PDelta? delta;
    String? note;
    if (total) {
      label = l.namuKrwTotal;
      amount = masked ? '••••' : '≈ ${won(view.totalKrw!)}';
      note = l.namuFxApplied(krw((view.appliedFxRate ?? 0).round()));
    } else if (main != null) {
      label = main.currency == 'KRW'
          ? l.namuDomesticValue
          : l.namuOverseasValue;
      amount = cur(main);
      delta = pnl(main, text: l.stocksVsPurchase);
    } else {
      label = l.namuDomesticValue;
      amount = won(0);
    }

    Widget row(String title, Widget value) => PListItem(
      title: title,
      titleColor: c.fgNeutralSubtle,
      suffix: PListValue(child: value),
    );
    Widget lineValue(NamuCurrencyTotal t) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(cur(t), style: stocksMoneyStyle(context)),
        const SizedBox(height: 2),
        pnl(t),
      ],
    );

    // 한 통화를 못 받았다(그 통화가 조용히 빠진다) · 받아 둔 보유를 다시 받지 못했다(옛 값) — 숫자는 두고 띠 한 줄(I-wrap-b2b 4).
    // 둘 다 처음부터 실패면 위 [failed] 가 맡는다. 한쪽이 빠지면 지표는 남은 통화 하나라 합계가 아니다 — 띠는 하나다
    final currencyFailed = krwAsync.pollFailed || usdAsync.pollFailed;
    return PScreenSection(
      padding: const EdgeInsets.only(top: PSpacing.x6, bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currencyFailed)
            StocksPriceFailure(
              // 남은 통화 · 옛 값이 섹션에 보인다 — Callout 하나(합계도 이 섹션 안이라 덮인다)
              stale: true,
              retrying: [
                krwAsync,
                usdAsync,
              ].any((v) => v.pollFailed && v.isLoading),
              onRetry: onRetry,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "≈ 합계" 는 앞 기호 + 금액 — 폭이 정해진 자리라 fit 경로(띄어쓰기에서 먼저 넘기기)
                PCardStat(label: label, value: amount, delta: delta, fit: true),
                if (note != null) ...[
                  const SizedBox(height: PSpacing.x1),
                  Text(
                    note,
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ],
                if (view.count == 0) ...[
                  const SizedBox(height: PSpacing.x1),
                  PText(
                    l.stocksNoHoldings,
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          PList(
            children: [
              // 합계가 지표일 때는 두 통화를 줄로 풀어 보이고, 하나가 지표일 때는 다른 통화만 줄로.
              if (view.krw != null && (total || main == view.usd))
                row(l.namuDomesticValue, lineValue(view.krw!)),
              if (view.usd != null && (total || main == view.krw))
                row(l.namuOverseasValue, lineValue(view.usd!)),
              // 주문 가능 — 원화는 국내 잔고 응답에서(새 호출 없음), 달러는 margin 의 예수금(주문 가능 칸이 없다).
              ..._buyingPowerRows(context, ref, masked),
              row(
                l.stocksHoldingsLabel,
                PText(
                  view.mixed
                      ? l.namuCountSplit(view.krw!.count, view.usd!.count)
                      : l.stocksUnitCount(view.count),
                  style: stocksMoneyStyle(context),
                ),
              ),
              PListButtonItem(
                title: l.stocksPortfolioTitle,
                detail: l.stocksPortfolioSub,
                prefix: PListTile(
                  background: c.bgNeutralWeak,
                  color: c.fgNeutral,
                  child: const Icon(LucideIcons.chartPie),
                ),
                suffix: Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: c.fgNeutralSubtle,
                ),
                onTap: () => context.push('/stocks/namu/portfolio'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- 띠 ② 시장 ---------------------------------------------------------------

/// 나무 시장 띠 — 장 상태 줄 + 환율 줄(지수 · 다음 개장 시각은 토스만 — 다른 증권사를 권하는 글 없음).
///
/// 장 상태는 나무가 시세에 딸려 주므로 시장마다 **대표 종목 하나**(보유 첫 종목, 없으면 관심 첫 종목)의 시세를
/// `/namu/prices` 로 한 번에(최대 2종목) 60초마다, 앱이 보일 때만 받는다. 대표가 없는 시장은 그리지 않고,
/// 둘 다 없으면 장 상태 줄 없이 환율 줄만 남는다. 환율을 못 받으면 값은 "환율 없음".
class NamuMarketBand extends ConsumerStatefulWidget {
  const NamuMarketBand({
    super.key,
    required this.krSymbol,
    required this.usSymbol,
    this.ready = true,
  });
  final String? krSymbol;
  final String? usSymbol;
  final bool ready;

  @override
  ConsumerState<NamuMarketBand> createState() => _NamuMarketBandState();
}

class _NamuMarketBandState extends ConsumerState<NamuMarketBand> {
  Timer? _timer;

  String get _csv {
    final set = <String>{
      if (widget.krSymbol != null) widget.krSymbol!,
      if (widget.usSymbol != null) widget.usSymbol!,
    };
    return (set.toList()..sort()).join(',');
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(namuMarketStatePollInterval, (_) {
      // 앱이 뒤로 가 있거나 상세 · 시트가 위에 올라와 있으면 멈춘다(H4).
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      ref.invalidate(namuQuotesProvider(_csv));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fxAsync = ref.watch(namuExchangeRateProvider);
    final fx = fxAsync.value;
    final csv = _csv;
    final quotesAsync = (widget.ready && csv.isNotEmpty)
        ? ref.watch(namuQuotesProvider(csv))
        : null;
    final quotes = quotesAsync?.value ?? const <NamuListQuote>[];
    String? stateOf(String? symbol) => symbol == null
        ? null
        : quotes.where((q) => q.symbol == symbol).firstOrNull?.marketState;
    final kr = namuMarketStateText(l, stateOf(widget.krSymbol));
    final us = namuMarketStateText(l, stateOf(widget.usSymbol));
    final markets = [
      if (kr != null) (name: l.stocksMarketKr, open: kr.open, detail: kr.text),
      if (us != null) (name: l.stocksMarketUs, open: us.open, detail: us.text),
    ];
    // 대표를 기다리는 동안(ready 아님)에도 값 자리는 Skeleton — 시장 띠 전체가 실패 한 벌로 바뀌지 않는다.
    final stateLoading =
        !widget.ready ||
        (quotesAsync != null && quotesAsync.isLoading && !quotesAsync.hasValue);
    final fxLoading = fxAsync.isLoading && !fxAsync.hasValue;
    final bothFailed =
        (quotesAsync?.hasError ?? false) &&
        !(quotesAsync?.hasValue ?? false) &&
        fxAsync.hasError &&
        !fxAsync.hasValue;
    if (bothFailed) {
      return PScreenSection(
        padding: const EdgeInsets.only(bottom: PSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StocksBandTitle(l.stocksSectionMarket),
            StocksFailure(
              title: l.stocksFailMarket,
              retrying: anyLoadRetrying([fxAsync, ?quotesAsync]),
              onRetry: () {
                ref.invalidate(namuQuotesProvider(csv));
                ref.invalidate(namuExchangeRateProvider);
              },
            ),
          ],
        ),
      );
    }
    // 장 상태 시세 · 환율 실패 — 처음이면 그 칸이 비거나 "환율 없음", 받아 둔 값이 있으면 옛 값이다. 섹션 머리 아래 띠(I-wrap-b2b 4)
    final priceFailed =
        (quotesAsync?.pollFailed ?? false) || fxAsync.pollFailed;
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksSectionMarket),
          if (priceFailed)
            StocksPriceFailure(
              stale: (quotesAsync?.hasValue ?? false) || fxAsync.hasValue,
              retrying: (quotesAsync?.isLoading ?? false) || fxAsync.isLoading,
              onRetry: () {
                ref.invalidate(namuQuotesProvider(csv));
                ref.invalidate(namuExchangeRateProvider);
              },
            ),
          if (markets.isNotEmpty) ...[
            StocksMarketStatusLine(markets: markets),
            const SizedBox(height: PSpacing.x1),
          ] else if (stateLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
              // 장 상태 줄(t4) 줄 높이
              child: PSkeleton.text(PTypography.t4, width: 160),
            ),
            const SizedBox(height: PSpacing.x1),
          ],
          PList(
            children: [
              PListItem(
                title: l.stocksExchangeRate,
                detail: l.stocksFxBasis,
                suffix: PListValue(
                  child: fxLoading
                      ? PSkeleton.text(PTypography.t5, width: 80)
                      : (fx != null && fx > 0)
                      ? Text(
                          keepAllAmount(fmtFxRate(fx)),
                          style: stocksMoneyStyle(context),
                        )
                      : PText(
                          l.namuFxUnavailableShort,
                          style: PTypography.t4.copyWith(
                            color: context.colors.fgNeutralSubtle,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
