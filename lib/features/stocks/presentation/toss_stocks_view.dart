import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_web_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/market_state.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_broker_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 증권 — 시세 · 보유 · 관심 · 호가 (토스증권 Open API 실연동).
///
/// 폰 목록은 띠 셋이다 — 내 투자 → 시장 → 종목(I-13 B). 종목 상세와 포트폴리오 구성은 화면(주소)이다
/// (`/stocks/toss/:symbol` · `/stocks/toss/portfolio` — 3-B).
/// 상승 = 빨강(`fg-critical`) / 하락 = 파랑(`fg-informative`) — 국내 증권 통념, Delta 가 그대로 쓴다.
class TossStocksView extends ConsumerStatefulWidget {
  const TossStocksView({super.key});

  @override
  ConsumerState<TossStocksView> createState() => _TossStocksViewState();
}

enum _Seg { holdings, watch, discover }

String _detailPath(String symbol) =>
    '/stocks/toss/${Uri.encodeComponent(symbol)}';

class _TossStocksViewState extends ConsumerState<TossStocksView> {
  _Seg _seg = _Seg.holdings;
  Timer? _priceTimer;
  Timer? _marketTimer;
  Timer? _calendarTimer;
  Timer? _buyingPowerTimer;

  /// 화면에 들어와 300ms 머문 관심 그룹 — 이 그룹들의 심볼만 합쳐 시세를 부른다(I-13 22).
  final Set<int> _visible = {};
  final Map<int, Timer> _lingering = {};

  /// 받은 시세 — 그룹이 화면 밖으로 나가 부르기를 멈춰도 받은 값은 남긴다.
  final Map<String, double> _lastPrices = {};

  @override
  void initState() {
    super.initState();
    // 라이브 갱신 — 10초마다 지켜보는 키만 다시 부른다(family invalidate). prevClose 는 하루 단위라 제외.
    _priceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // 상세 · 포트폴리오가 위에 올라와 있으면 목록은 멈춘다(그 화면이 제 몫만 부른다 — 호출 두 배 방지, H3).
      // 앱이 뒤로 가 있으면(홈 · 화면 꺼짐) 받아도 아무도 안 본다 — 멈춘다(H4)
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      ref.invalidate(tossPricesProvider);
      ref.invalidate(tossHoldingsProvider);
    });
    // 시장 띠는 웹과 같은 박자로 다시 받는다(H3): 지수 · 환율 · 순위 60초, 달력 5분. 처음 값으로 굳지 않게.
    _marketTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      ref.invalidate(tossIndicatorPricesProvider);
      ref.invalidate(tossIndicatorClosesProvider);
      ref.invalidate(tossExchangeRateProvider);
      ref.invalidate(tossRankingsProvider);
      refreshStalePrevCloses(ref); // 날이 바뀌었으면 전일 종가를 다시(N3)
    });
    _calendarTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted || !ref.read(appForegroundProvider)) return;
      ref.invalidate(tossMarketCalendarKrProvider);
      ref.invalidate(tossMarketCalendarUsProvider);
    });
    // 주문 가능 금액은 초 단위로 볼 값이 아니다 — 60초마다, 앱이 보일 때만(보유 10초와 따로). 상세 · 시트가
    // 위에 올라와 있으면 멈춘다(H4, 시장 띠 타이머와 같게).
    _buyingPowerTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      ref.invalidate(tossBuyingPowerProvider);
    });
  }

  @override
  void dispose() {
    _buyingPowerTimer?.cancel();
    _priceTimer?.cancel();
    _marketTimer?.cancel();
    _calendarTimer?.cancel();
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

  /// 묶음의 dispose 에서 불리므로 트리가 잠긴 때다 — setState 는 다음 프레임에 한다(M7).
  void _blockHidden(int id) {
    _lingering.remove(id)?.cancel();
    if (!_visible.contains(id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _visible.contains(id)) {
        setState(() => _visible.remove(id));
      }
    });
  }

  void _openSearch() => showStockSearchSheet(
    context,
    onPick: (symbol) => context.push(_detailPath(symbol)),
  );

  void _openDetail(String symbol) => context.push(_detailPath(symbol));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    // 앱이 앞으로 돌아오면 멈춰 있던 동안 낡은 값을 바로 다시 받는다(H3 · H4)
    ref.listen<bool>(appForegroundProvider, (prev, next) {
      if (next && prev == false) {
        ref.invalidate(tossHoldingsProvider);
        ref.invalidate(tossPricesProvider);
        ref.invalidate(tossIndicatorPricesProvider);
        ref.invalidate(tossMarketCalendarKrProvider);
        ref.invalidate(tossMarketCalendarUsProvider);
        refreshStalePrevCloses(ref);
      }
    });
    final holdingsAsync = ref.watch(tossHoldingsProvider);
    final fxRaw = ref.watch(tossExchangeRateProvider).value?.rateValue;
    final fx = (fxRaw != null && fxRaw > 0) ? fxRaw : null;
    final holdings = holdingsAsync.value;
    final holdingItems = sortHoldings(holdings?.items ?? const [], fx);
    final watchAsync = ref.watch(watchGroupsProvider);
    final groups = watchAsync.value ?? const <StockWatchGroup>[];

    // 보이는 그룹의 심볼을 합쳐 50 씩 한 번에 — 그룹마다 따로 부르지 않는다.
    final symbols = visibleSymbols(groups, _visible);
    for (final chunk in chunkSymbols(symbols)) {
      final prices =
          ref.watch(tossPricesProvider(chunk.join(','))).value ??
          const <TossPrice>[];
      for (final p in prices) {
        final v = double.tryParse(p.lastPrice);
        if (v != null && v > 0) _lastPrices[p.symbol] = v;
      }
    }

    final head = <Widget>[
      _InvestBand(
        holdingsAsync: holdingsAsync,
        masked: masked,
        onRetry: () {
          ref.invalidate(tossAccountsProvider);
          ref.invalidate(tossHoldingsProvider);
        },
      ),
      const SizedBox(height: kScreenBandGap),
      const _MarketBand(),
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
                PTab(value: _Seg.discover, label: l.stocksTabDiscover),
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
        child: Text(
          l.stocksSourceNotice,
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
              onRetry: () => ref.invalidate(watchGroupsProvider),
            ),
          ),
        );
      } else if (watchAsync.isLoading && !watchAsync.hasValue) {
        slivers.add(const SliverToBoxAdapter(child: StocksGroupSkeleton()));
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
                lineBuilder: (item) => _WatchLine(
                  item: item,
                  last: _lastPrices[item.symbol],
                  onTap: () => _openDetail(item.symbol),
                ),
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
            child: _seg == _Seg.discover
                ? _DiscoverPanel(onPick: _openDetail)
                : _HoldingsList(
                    async: holdingsAsync,
                    items: holdingItems,
                    masked: masked,
                    onTap: _openDetail,
                    onRetry: () {
                      ref.invalidate(tossAccountsProvider);
                      ref.invalidate(tossHoldingsProvider);
                    },
                  ),
          ),
        ),
      );
    }
    slivers.add(SliverToBoxAdapter(child: tail));
    return CustomScrollView(slivers: slivers);
  }
}

// ---- 띠 ① 내 투자 -------------------------------------------------------------

class _InvestBand extends ConsumerWidget {
  const _InvestBand({
    required this.holdingsAsync,
    required this.masked,
    required this.onRetry,
  });

  final AsyncValue<TossHoldings?> holdingsAsync;
  final bool masked;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (holdingsAsync.hasError && !holdingsAsync.hasValue) {
      return PScreenSection(
        padding: EdgeInsets.zero,
        child: StocksFailure(title: l.stocksFailInvest, onRetry: onRetry),
      );
    }
    if (holdingsAsync.isLoading && !holdingsAsync.hasValue) {
      return PScreenSection(
        padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
        child: Semantics(
          label: l.stocksMyEval,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.stocksMyEval,
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
    final h = holdingsAsync.value;
    final s = h == null
        ? const InvestSummary(
            evalAmount: 0,
            purchaseAmount: 0,
            pnl: 0,
            pnlPct: 0,
            dailyPnl: 0,
            dailyPnlPct: 0,
            count: 0,
          )
        : investSummaryOf(h);
    String money(int v) => masked ? '••••' : krwSigned(v, false, unit: true);
    return PScreenSection(
      padding: const EdgeInsets.only(top: PSpacing.x6, bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: PCardStat(
              label: l.stocksMyEval,
              value: money(s.evalAmount),
              delta: stocksPnlDelta(
                s.pnl,
                s.pnlPct,
                masked,
                text: l.stocksVsPurchase,
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          PList(
            children: [
              PListItem(
                title: l.stocksPurchaseAmount,
                titleColor: c.fgNeutralSubtle,
                suffix: PListValue.amount(
                  money(s.purchaseAmount),
                  style: stocksMoneyStyle(context),
                ),
              ),
              PListItem(
                title: l.stocksDayPnl,
                titleColor: c.fgNeutralSubtle,
                suffix: PListValue(
                  child: stocksPnlDelta(s.dailyPnl, s.dailyPnlPct, masked),
                ),
              ),
              for (final cur in const ['KRW', 'USD']) ...[
                () {
                  final bp = ref.watch(tossBuyingPowerProvider(cur));
                  final st = AsyncValue3(
                    loading: bp.isLoading && !bp.hasValue,
                    failed: bp.hasError && !bp.hasValue,
                    amount: bp.value?.amount,
                  );
                  if (!st.hasRow) return const SizedBox.shrink();
                  return stocksBuyingPowerRow(
                    context,
                    title: cur == 'KRW'
                        ? l.stocksBuyingPowerKrw
                        : l.stocksBuyingPowerUsd,
                    state: st,
                    masked: masked,
                    format: (v) => fmtByCurrency(v, cur),
                  );
                }(),
              ],
              PListItem(
                title: l.stocksHoldingsLabel,
                titleColor: c.fgNeutralSubtle,
                suffix: PListValue(
                  child: Text(
                    l.stocksUnitCount(s.count),
                    style: stocksMoneyStyle(context),
                  ),
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
                onTap: () => context.push('/stocks/toss/portfolio'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- 띠 ② 시장 ---------------------------------------------------------------

class _MarketBand extends ConsumerWidget {
  const _MarketBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pricesAsync = ref.watch(tossIndicatorPricesProvider);
    final krAsync = ref.watch(tossMarketCalendarKrProvider);
    final usAsync = ref.watch(tossMarketCalendarUsProvider);
    bool failed(AsyncValue<Object?> v) => v.hasError && !v.hasValue;
    // 구역(지수 · 국내 장 · 미국 장 · 환율)별로 그린다 — 한 칸이 실패해도 나머지는 보이고 그 칸만 비운다.
    // 셋이 모두 실패일 때만 "시장 정보를 불러오지 못했어요" 한 벌(웹 `market-band` 와 같은 규칙: 결과표 H4).
    if (failed(pricesAsync) && failed(krAsync) && failed(usAsync)) {
      return PScreenSection(
        padding: const EdgeInsets.only(bottom: PSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StocksBandTitle(l.stocksSectionMarket),
            StocksFailure(
              title: l.stocksFailMarket,
              onRetry: () {
                ref.invalidate(tossIndicatorPricesProvider);
                ref.invalidate(tossMarketCalendarKrProvider);
                ref.invalidate(tossMarketCalendarUsProvider);
              },
            ),
          ],
        ),
      );
    }
    final indices = (pricesAsync.value ?? [])
        .where((i) => i.priceValue > 0 && indexNameOf(l, i.symbol) != null)
        .toList();
    final fxRaw = ref.watch(tossExchangeRateProvider).value?.rateValue;
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksSectionMarket),
          const _MarketStatusLine(),
          const SizedBox(height: PSpacing.x1),
          PList(
            children: [
              if (pricesAsync.isLoading && !pricesAsync.hasValue)
                for (var i = 0; i < 2; i++) const _IndexSkeleton(),
              for (final i in indices) _IndexLine(index: i),
              if (fxRaw != null && fxRaw > 0)
                PListItem(
                  title: l.stocksExchangeRate,
                  detail: l.stocksFxBasis,
                  suffix: PListValue.amount(
                    fmtFxRate(fxRaw),
                    style: stocksMoneyStyle(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 장 상태 줄 — "● 국내 장마감   ● 미국 개장 22:30". 줄바꿈 허용(항목 사이 16 · 줄 사이 4).
class _MarketStatusLine extends ConsumerStatefulWidget {
  const _MarketStatusLine();

  @override
  ConsumerState<_MarketStatusLine> createState() => _MarketStatusLineState();
}

class _MarketStatusLineState extends ConsumerState<_MarketStatusLine> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // 장 상태는 시각이 흐르면 바뀐다 — 30초마다 지금 시각으로 다시 판정한다. 달력의 "오늘" 이 한국 날짜와 다르면(앱을 켜 둔 채
    // 다음 날) 달력을 새로 받는다. 안 그러면 어제 세션이라 하루 종일 장마감으로 보인다(H3).
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !ref.read(appForegroundProvider)) return;
      final kr = ref.read(tossMarketCalendarKrProvider).value;
      final kst = stocksClock().toUtc().add(const Duration(hours: 9));
      String two(int n) => n.toString().padLeft(2, '0');
      final today = '${kst.year}-${two(kst.month)}-${two(kst.day)}';
      if (kr != null && kr.today.date.isNotEmpty && kr.today.date != today) {
        ref.invalidate(tossMarketCalendarKrProvider);
        ref.invalidate(tossMarketCalendarUsProvider);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    // 달력이 오는 중이면 그 칸은 Skeleton, 실패면 칸을 비운다 — 모를 때 "휴장" 이라는 틀린 사실을 그리지 않는다(H4).
    final krAsync = ref.watch(tossMarketCalendarKrProvider);
    final usAsync = ref.watch(tossMarketCalendarUsProvider);
    final markets = <({String name, bool open, String detail})?>[
      krAsync.hasValue
          ? () {
              final r = marketStateNow(
                krAsync.value!.today.regularMarket,
                StockTz.kr,
                l,
              );
              return (name: l.stocksMarketKr, open: r.open, detail: r.detail);
            }()
          : null,
      usAsync.hasValue
          ? () {
              final r = marketStateNow(
                usAsync.value!.today.regularMarket,
                StockTz.us,
                l,
              );
              return (name: l.stocksMarketUs, open: r.open, detail: r.detail);
            }()
          : null,
    ];
    final loading = [
      krAsync.isLoading && !krAsync.hasValue,
      usAsync.isLoading && !usAsync.hasValue,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
      child: Wrap(
        spacing: PSpacing.x4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < markets.length; i++)
            if (loading[i])
              Semantics(
                label: l.stocksRankingLoading,
                child: PSkeleton(width: 110, height: 19),
              )
            else if (markets[i] != null)
              _statusItem(c, markets[i]!),
        ],
      ),
    );
  }

  Widget _statusItem(PColors c, ({String name, bool open, String detail}) m) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: m.open ? c.fgPositive : c.strokeNeutralSolid,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: m.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.fgNeutral,
                  ),
                ),
                TextSpan(text: ' ${m.detail}'),
              ],
            ),
            style: PTypography.t4.copyWith(
              color: c.fgNeutralSubtle,
              fontFeatures: kStocksTnum,
            ),
          ),
        ),
      ],
    );
  }
}

/// 지수 로딩 줄 — 이름 · 값 자리만.
class _IndexSkeleton extends StatelessWidget {
  const _IndexSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.x6,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PSkeleton(width: 56, height: 22),
          PSkeleton(width: 84, height: 38),
        ],
      ),
    );
  }
}

/// 지수 줄 — 이름 + 추이선 56×20 + 포인트 / Delta(그 구간 시작 대비 %).
class _IndexLine extends ConsumerWidget {
  const _IndexLine({required this.index});
  final TossIndicatorPrice index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final closes =
        ref.watch(tossIndicatorClosesProvider(index.symbol)).value ??
        const <double>[];
    double? pct;
    if (closes.length >= 2 && closes.first > 0) {
      pct = (closes.last - closes.first) / closes.first * 100;
    }
    final up = (pct ?? 0) >= 0;
    return PListItem(
      title: indexNameOf(l, index.symbol)!,
      verticalPadding: 10,
      suffix: PListValue(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (closes.length >= 2)
              ExcludeSemantics(
                child: SizedBox(
                  width: 56,
                  height: 20,
                  child: CustomPaint(
                    painter: _SparkPainter(
                      closes,
                      up ? c.fgCritical : c.fgInformative,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: PSpacing.x2),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmtIndexPoint(index.priceValue),
                  style: stocksMoneyStyle(context),
                ),
                if (pct != null) ...[
                  const SizedBox(height: 2),
                  StocksPctDelta(pct),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - lo) / span * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || old.values != values;
}

// ---- 띠 ③ 종목 · 보유 ---------------------------------------------------------

class _HoldingsList extends StatelessWidget {
  const _HoldingsList({
    required this.async,
    required this.items,
    required this.masked,
    required this.onTap,
    required this.onRetry,
  });

  final AsyncValue<TossHoldings?> async;
  final List<TossHoldingsItem> items;
  final bool masked;
  final void Function(String symbol) onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (async.hasError && !async.hasValue) {
      return StocksFailure(title: l.stocksFailHoldings, onRetry: onRetry);
    }
    if (async.isLoading && !async.hasValue) {
      return Semantics(
        label: l.stocksRankingLoading,
        child: Column(
          children: [for (var i = 0; i < 5; i++) const StocksLineSkeleton()],
        ),
      );
    }
    if (items.isEmpty) {
      return PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.wallet,
        title: l.stocksNoHoldings,
        headingLevel: 3,
      );
    }
    return PList(
      semanticLabel: l.stocksTabHoldings,
      children: [
        for (final h in items)
          StocksLine(
            name: h.name.isNotEmpty ? h.name : h.symbol,
            detail:
                '${h.symbol} · ${l.stocksSharesUnit(stocksQty(h.quantityValue))}',
            amount: masked
                ? '••••'
                : fmtByCurrency(h.marketValueAmountValue, h.currency),
            pct: h.profitLossRateValue,
            onTap: () => onTap(h.symbol),
          ),
      ],
    );
  }
}

/// 관심 줄 — 전일 종가는 이 줄이 지어졌을 때(= 보이는 묶음)만 부른다.
class _WatchLine extends ConsumerWidget {
  const _WatchLine({
    required this.item,
    required this.last,
    required this.onTap,
  });

  final WatchItem item;
  final double? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prevClose = last == null
        ? null
        : ref.watch(prevCloseProvider(item.symbol)).value;
    return StocksLine(
      name: item.nameKr.isNotEmpty ? item.nameKr : item.symbol,
      detail: '${item.symbol} · ${stockMarketLabel(l, item.marketCode)}',
      amount: last == null ? null : fmtByCurrency(last!, item.currency),
      pct: changePctOf(last, prevClose),
      onTap: onTap,
    );
  }
}

// ---- 발견(디스커버리) 랭킹 — 토스 rankings 실데이터 -----------------------------

class _RankLine extends ConsumerWidget {
  const _RankLine({
    required this.item,
    required this.index,
    required this.onPick,
  });
  final TossRankingItem item;
  final int index;
  final void Function(String symbol) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(tossStockInfoProvider(item.symbol)).value?.name;
    final last = item.price.lastPriceValue;
    return StocksLine(
      name: (name != null && name.isNotEmpty) ? name : item.symbol,
      detail: item.symbol,
      amount: last > 0 ? fmtByCurrency(last, item.currency) : null,
      pct: item.price.changePct,
      rank: item.rank,
      topRank: index < 3,
      onTap: () => onPick(item.symbol),
    );
  }
}

class _DiscoverPanel extends ConsumerStatefulWidget {
  const _DiscoverPanel({required this.onPick});
  final void Function(String ticker) onPick;

  @override
  ConsumerState<_DiscoverPanel> createState() => _DiscoverPanelState();
}

class _DiscoverPanelState extends ConsumerState<_DiscoverPanel> {
  String _tab = 'gainers';
  String _market = 'KR';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // TOP_GAINERS/LOSERS 는 realtime 미지원 → 1d, 거래량은 실시간.
    final type = _tab == 'gainers'
        ? 'TOP_GAINERS'
        : (_tab == 'losers' ? 'TOP_LOSERS' : 'MARKET_TRADING_VOLUME');
    final duration = _tab == 'volume' ? 'realtime' : '1d';
    final key = '$type|$_market|$duration';
    final rankingsAsync = ref.watch(tossRankingsProvider(key));
    final rankings = rankingsAsync.value?.rankings ?? const <TossRankingItem>[];
    final Widget body;
    if (rankingsAsync.hasError && !rankingsAsync.hasValue) {
      body = StocksFailure(
        title: l.stocksFailRanking,
        onRetry: () => ref.invalidate(tossRankingsProvider(key)),
      );
    } else if (rankingsAsync.isLoading && !rankingsAsync.hasValue) {
      body = Semantics(
        label: l.stocksRankingLoading,
        child: Column(
          children: [for (var i = 0; i < 10; i++) const StocksLineSkeleton()],
        ),
      );
    } else if (rankings.isEmpty) {
      body = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.chartNoAxesColumn,
        title: l.stocksRankingEmpty,
        headingLevel: 3,
      );
    } else {
      body = PList(
        children: [
          for (var i = 0; i < rankings.length; i++)
            _RankLine(item: rankings[i], index: i, onPick: widget.onPick),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x2,
            PSpacing.x6,
            0,
          ),
          child: PSegmentedControl<String>(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            semanticLabel: l.stocksTabDiscover,
            items: [
              PSegmentedItem(value: 'gainers', label: l.stocksGainers),
              PSegmentedItem(value: 'losers', label: l.stocksLosers),
              PSegmentedItem(value: 'volume', label: l.stocksVolume),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x2,
            PSpacing.x6,
            PSpacing.x2,
          ),
          child: PSegmentedControl<String>(
            value: _market,
            onChanged: (v) => setState(() => _market = v),
            semanticLabel: l.stocksSectionMarket,
            items: [
              PSegmentedItem(value: 'KR', label: l.stocksMarketToggleKr),
              PSegmentedItem(value: 'US', label: l.stocksMarketToggleUs),
            ],
          ),
        ),
        body,
      ],
    );
  }
}

// ---- 종목 상세 = 화면(3-B) -------------------------------------------------------

/// 종목 상세 화면 — 폰은 띠 다섯(머리 · 차트 / 내 보유 / 호가 · 체결 / 기본 정보 / 일별 시세 + 매매).
/// 주소 `/stocks/toss/:symbol` 만으로 열린다(목록 상태를 넘겨받지 않는다).
class TossStockDetailPage extends ConsumerStatefulWidget {
  const TossStockDetailPage({super.key, required this.symbol});
  final String symbol;

  @override
  ConsumerState<TossStockDetailPage> createState() =>
      _TossStockDetailPageState();
}

class _TossStockDetailPageState extends ConsumerState<TossStockDetailPage> {
  String _range = '1D';
  Timer? _timer;
  Timer? _todayTimer;

  @override
  void initState() {
    super.initState();
    // 이 종목의 시세 · 호가 · 체결과 보유만 10초마다 다시 부른다. 목록 타이머는 이 화면이 위에 있으면 멈추고,
    // 일별 캔들(252봉 — 저장소가 커서로 나눠 부른다)은 하루 단위라 폴링하지 않는다(웹 staleTime 5분과 같은 뜻).
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      ref.invalidate(tossPricesProvider(widget.symbol));
      ref.invalidate(tossOrderbookProvider(widget.symbol));
      ref.invalidate(tossTradesProvider(widget.symbol));
      ref.invalidate(tossHoldingsProvider);
      refreshStalePrevCloses(ref);
    });
    // 오늘 시세의 일봉은 60초마다(웹 `useTossCandles` 와 같은 박자) — 앱이 보일 때 · 이 화면이 맨 위일 때만(N6).
    _todayTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted ||
          !ref.read(appForegroundProvider) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      ref.invalidate(tossTodayCandlesProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _todayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    final symbol = widget.symbol;

    final master = findMasterBySymbol(
      ref.watch(stockSearchProvider(symbol)).value ?? const <StockMasterItem>[],
      symbol,
    );
    final infoAsync = ref.watch(tossStockInfoProvider(symbol));
    final info = infoAsync.value;
    final holding = ref
        .watch(tossHoldingsProvider)
        .value
        ?.items
        .where((h) => h.symbol == symbol)
        .firstOrNull;
    final groups =
        ref.watch(watchGroupsProvider).value ?? const <StockWatchGroup>[];
    final watched = groups.any((g) => g.items.any((i) => i.symbol == symbol));
    final warnings =
        ref.watch(tossWarningsProvider(symbol)).value ??
        const <TossStockWarning>[];

    final name = master?.nameKr.isNotEmpty == true
        ? master!.nameKr
        : (info?.name.isNotEmpty == true
              ? info!.name
              : (holding?.name.isNotEmpty == true ? holding!.name : symbol));
    // 통화를 모르면 KRW 로 지어내지 않는다 — 응답이 오기 전 미국 종목이 "190원" 으로 보이던 것(M10). 시세 응답의 통화도 쓴다
    final priceCurrency = ref
        .watch(tossPricesProvider(symbol))
        .value
        ?.firstOrNull
        ?.currency;
    final currency = info?.currency.isNotEmpty == true
        ? info!.currency
        : (master?.currency.isNotEmpty == true
              ? master!.currency
              : (holding?.currency.isNotEmpty == true
                    ? holding!.currency
                    : (priceCurrency?.isNotEmpty == true
                          ? priceCurrency!
                          : '')));
    final isUs = currency == 'USD';

    final pricesAsync = ref.watch(tossPricesProvider(symbol));
    final lastRaw = pricesAsync.value?.firstOrNull?.lastPrice;
    final lastParsed = lastRaw == null ? null : double.tryParse(lastRaw);
    final last = (lastParsed != null && lastParsed > 0) ? lastParsed : null;
    final prevClose = ref.watch(prevCloseProvider(symbol)).value;
    final changePct = changePctOf(last, prevClose);
    final fxRaw = ref.watch(tossExchangeRateProvider).value?.rateValue;
    final fxRate = (fxRaw != null && fxRaw > 0) ? fxRaw : null;

    final marketText = master != null
        ? stockMarketLabel(l, master.marketCode)
        : stockMarketLabel(l, info?.market ?? '');
    final typeText = info?.isEtf == true
        ? 'ETF'
        : stockSecurityTypeLabel(l, master?.securityType ?? 'STOCK');
    final sub = [
      symbol,
      if (marketText.isNotEmpty) marketText,
      typeText,
    ].join(' · ');

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
                  // "▲ 45,200원 · 0.30%" — 금액(전일 종가 대비)과 등락률(M5)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: stocksPnlDelta(
                      last - prevClose,
                      changePct,
                      false,
                      currency: currency,
                    ),
                  ),
                ],
                if (isUs && last != null && fxRate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '≈ ${krwSigned((last * fxRate).round(), false, unit: true)}',
                    style: PTypography.t3.copyWith(
                      color: c.fgNeutralSubtle,
                      fontFeatures: kStocksTnum,
                    ),
                  ),
                ],
                // 시세 조회가 실패했고 받아 둔 값도 없으면 실패 안내 + [다시 시도](웹 `detail.priceFail`)
                if (last == null &&
                    pricesAsync.hasError &&
                    !pricesAsync.hasValue) ...[
                  // 웹 BandFailure 와 같은 Result Section(구역 안 = medium): 아이콘 · 제목 · 설명 · [다시 시도]
                  StocksFailure(
                    title: l.stocksFailPrice,
                    onRetry: () => ref.invalidate(tossPricesProvider(symbol)),
                  ),
                ],
                // 시세 조회가 실패했거나 오는 중이면 '미지원' 이 아니다 — 응답이 왔는데 값이 없을 때만(M8)
                if (last == null && pricesAsync.hasValue) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.stocksPriceUnavailable,
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ],
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: PSpacing.x2),
                  Wrap(
                    spacing: PSpacing.x1,
                    runSpacing: PSpacing.x1,
                    children: [
                      for (final w in warnings)
                        PBadge(
                          label: stocksWarningLabel(l, w.warningType),
                          tone: PBadgeTone.warning,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: PSpacing.x4),
                ChartWebView(
                  symbol: symbol,
                  isUs: isUs,
                  range: _range,
                  height: kStockChartWebViewHeight,
                  broker: 'toss',
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

    // 머리(차트 WebView)와 호가 · 체결(고른 탭)은 스크롤로 화면 밖에 나가도 지키고 있는다 — 안 그러면 내렸다 올릴 때마다
    // 차트가 새 토큰 · 캔들 호출로 다시 지어지고 호가 탭이 처음으로 돌아간다(M13).
    final bands = <Widget>[
      StocksKeepAlive(child: head),
      if (holding != null) _HoldingBand(holding: holding, masked: masked),
      _TossTodayBand(symbol: symbol, currency: currency),
      StocksKeepAlive(
        child: _QuotesBand(
          symbol: symbol,
          currency: currency,
          lastPrice: last,
          changePct: changePct,
        ),
      ),
      // 투자자별은 국내(KRW)로 확인된 종목만 부른다 — 통화를 모르는 틈에 미국 심볼로 호출이 나가지 않게(N7)
      if (currency == 'KRW') _TossInvestorBand(symbol: symbol),
      _InfoBand(
        symbol: symbol,
        currency: currency,
        info: info,
        lastPrice: last,
        fxRate: fxRate,
        failed: infoAsync.hasError && !infoAsync.hasValue,
      ),
      _DailyBand(symbol: symbol, currency: currency, name: name),
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

/// 띠 ② 내 보유 — 한 줄에 하나. 손익 · 수익률 · 일간 손익은 Delta, 금액은 굵은 고정폭.
class _HoldingBand extends StatelessWidget {
  const _HoldingBand({required this.holding, required this.masked});
  final TossHoldingsItem holding;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = holding;
    final cur = h.currency.isEmpty ? 'KRW' : h.currency;
    final pnl = h.profitLossAmountValue;
    final day = h.dailyProfitLossAmountValue;
    final avg = h.averagePurchasePriceValue;
    final qtyLabel = l.stocksSharesUnit(stocksQty(h.quantityValue));
    String money(num v) => masked ? '••••' : fmtByCurrency(v.toDouble(), cur);
    PDelta delta(num v) => stocksPnlDelta(v, null, masked, currency: cur);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksMyHoldings),
          PList(
            children: [
              stocksKvLine(
                context,
                l.stocksEvalAmount,
                money(h.marketValueAmountValue),
              ),
              stocksKvLine(
                context,
                l.stocksEvalPnl,
                '',
                valueWidget: delta(pnl),
              ),
              stocksKvLine(
                context,
                l.stocksReturnRate,
                '',
                valueWidget: StocksPctDelta(h.profitLossRateValue),
              ),
              stocksKvLine(context, l.stocksQuantityHeld, qtyLabel),
              stocksKvLine(
                context,
                l.stocksAvgPrice,
                masked ? '••••' : fmtByCurrency(avg, cur),
              ),
              stocksKvLine(
                context,
                l.stocksPurchaseAmount,
                money(h.purchaseAmountValue),
              ),
              stocksKvLine(
                context,
                l.stocksDayPnl,
                '',
                valueWidget: delta(day),
              ),
              stocksKvLine(
                context,
                l.stocksFeesTax,
                fmtByCurrency(h.feesValue, cur),
              ),
              stocksKvLine(context, l.stocksSellable, qtyLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// 띠 — 오늘 시세(토스). 시가 · 고가 · 저가 · 거래량 = 일봉 오늘 봉(마지막 봉 날짜가 오늘일 때만),
/// 상한가 · 하한가 = `/toss/price-limits`(국내만 — 미국은 줄 없음).
class _TossTodayBand extends ConsumerWidget {
  const _TossTodayBand({required this.symbol, required this.currency});
  final String symbol;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final candlesAsync = ref.watch(tossTodayCandlesProvider(symbol));
    final isKr = currency == 'KRW';
    final limits = isKr
        ? ref.watch(tossPriceLimitsProvider(symbol)).asData?.value
        : null;
    final candles = candlesAsync.value?.candles ?? const <TossCandle>[];
    // 그 시장의 오늘 봉만 쓴다(M11) — 미국은 현지 거래일로 견주고 기기 날짜로 견주지 않는다.
    final last = todayBarOf(candles, symbol, stocksClock().toUtc());
    final isToday = last != null;
    double? pos(String? v) {
      final d = v == null ? null : double.tryParse(v);
      return (d == null || d <= 0) ? null : d;
    }

    final rows = todayRowsOf(
      context,
      currency: currency,
      open: isToday ? pos(last.openPrice) : null,
      high: isToday ? pos(last.highPrice) : null,
      low: isToday ? pos(last.lowPrice) : null,
      volume: isToday && last.volumeValue > 0 ? last.volumeValue : null,
      upper: pos(limits?.upperLimitPrice),
      lower: pos(limits?.lowerLimitPrice),
    );
    return StocksTodayBand(
      rows: rows,
      loading: candlesAsync.isLoading && !candlesAsync.hasValue,
      failTitle: candlesAsync.hasError && !candlesAsync.hasValue
          ? l.stocksFailToday
          : null,
      onRetry: () => ref.invalidate(tossTodayCandlesProvider(symbol)),
    );
  }
}

/// 띠 — 투자자별 매매동향(토스, 국내 종목만).
class _TossInvestorBand extends ConsumerWidget {
  const _TossInvestorBand({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tossInvestorProvider(symbol));
    return StocksInvestorBand(
      days: async.value,
      loading: async.isLoading,
      failed: async.hasError,
      onRetry: () => ref.invalidate(tossInvestorProvider(symbol)),
    );
  }
}

/// 띠 ③ 호가 · 체결.
class _QuotesBand extends StatelessWidget {
  const _QuotesBand({
    required this.symbol,
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String symbol;
  final String currency;
  final double? lastPrice;
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksOrderbookTrades),
          StocksQuotesCard(
            symbol: symbol,
            currency: currency,
            lastPrice: lastPrice,
            changePct: changePct,
            watchBook: (ref) => ref.watch(tossOrderbookProvider(symbol)),
            watchTrades: (ref) => ref.watch(tossTradesProvider(symbol)),
            onRetryBook: (ref) => ref.invalidate(tossOrderbookProvider(symbol)),
            onRetryTrades: (ref) => ref.invalidate(tossTradesProvider(symbol)),
          ),
        ],
      ),
    );
  }
}

/// 띠 ⑤ 일별 시세 + 끝의 매매(토스만 — 이 화면이 토스 상세다).
class _DailyBand extends ConsumerWidget {
  const _DailyBand({
    required this.symbol,
    required this.currency,
    required this.name,
  });
  final String symbol;

  /// 통화를 모르면 빈 값 — 가격은 숫자만 보인다("원" 을 지어내지 않는다, N7).
  final String currency;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final candlesAsync = ref.watch(
      tossCandlesProvider((symbol: symbol, interval: '1d')),
    );
    final page = candlesAsync.value;
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
    String fmt(double v) =>
        currency.isEmpty ? krw(v.round()) : fmtByCurrency(v, currency);
    final Widget list;
    if (candlesAsync.hasError && !candlesAsync.hasValue) {
      list = StocksFailure(
        title: l.stocksFailDaily,
        onRetry: () => ref.invalidate(
          tossCandlesProvider((symbol: symbol, interval: '1d')),
        ),
      );
    } else if (candlesAsync.isLoading && !candlesAsync.hasValue) {
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
                      keepAllAmount(fmt(r.close)),
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
          // 매매 — 주문 기능이 아직 없다. 단추는 남기고 막고 이유 줄을 둔다(D3 B, 사용자 10-30).
          // 매도 = brandSolid · 매수 = criticalSolid, 사이 8. 누르면 뜨던 옛 띠는 없다.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x5,
              PSpacing.x6,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        hint: l.stocksTradeSoon,
                        child: PButton(
                          label: l.stocksSell,
                          size: PButtonSize.large,
                          variant: PButtonVariant.brandSolid,
                          onPressed: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: PSpacing.x2),
                    Expanded(
                      child: Semantics(
                        hint: l.stocksTradeSoon,
                        child: PButton(
                          label: l.stocksBuy,
                          size: PButtonSize.large,
                          variant: PButtonVariant.criticalSolid,
                          onPressed: null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PSpacing.x2),
                // 이유 줄 — 웹과 같은 Callout(아이콘 있는 회색 상자). 읽는 도구에는 단추 힌트로도 전한다.
                PCallout(
                  description: l.stocksTradeSoon,
                  icon: LucideIcons.info,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x3,
              PSpacing.x6,
              0,
            ),
            child: PCallout(
              tone: PCalloutTone.informative,
              icon: LucideIcons.info,
              description: currency == 'USD' ? l.stocksFeeUs : l.stocksFeeKr,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x3,
              PSpacing.x6,
              0,
            ),
            child: Text(
              '${l.stocksDisclaimerLine1}\n${l.stocksDisclaimerLine2}',
              textAlign: TextAlign.center,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- 포트폴리오 구성 = 화면 --------------------------------------------------------

/// 포트폴리오 구성 화면 — 도넛 112 + 범례(종목 이름 · 비중). 비중은 원화로 환산해 센다(Q5-A).
class TossPortfolioPage extends ConsumerWidget {
  const TossPortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final holdingsAsync = ref.watch(tossHoldingsProvider);
    // 금액 가리기 — 도넛을 눌러 뜨는 조각 금액도, 범례 비중도 가린다(H5, 웹과 같게)
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    final fxRaw = ref.watch(tossExchangeRateProvider).value?.rateValue;
    final fx = (fxRaw != null && fxRaw > 0) ? fxRaw : null;
    final items = holdingsAsync.value?.items ?? const [];
    final comp = compositionOf(items, fx);

    Widget content;
    if (holdingsAsync.hasError && !holdingsAsync.hasValue) {
      content = StocksFailure(
        title: l.stocksFailInvest,
        onRetry: () {
          ref.invalidate(tossAccountsProvider);
          ref.invalidate(tossHoldingsProvider);
        },
      );
    } else if (holdingsAsync.isLoading && !holdingsAsync.hasValue) {
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
    } else if (items.isEmpty) {
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
        title: l.stocksPortfolioNeedsFx,
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

// ---- 종목 기본정보 (토스 stocks + price-limits) ------------------------------

/// 시가총액 — en 은 ₩ + 로케일 compact(₩1.2T), ko 는 조/억/만 + 원.
///
/// 축약은 차트 축과 같은 함수 하나다. 손으로 짠 예전 코드는 구간마다 정밀도가
/// 달라(조는 `.0` 을 남겨 `5.0조원`, 억은 정수) 같은 규칙이 아니었고, 1억 밑을
/// 반올림해 5,000만원짜리를 `1억원` 이라고 했다.
String fmtCapKrw(double v) {
  if (localeIsEn()) return '₩${formatChartAxis(v)}';
  return '${formatChartAxis(v)}원';
}

/// 상장주식수 — 금액은 아니지만 같은 한국어 단위 사다리(만·억)를 쓴다.
///
/// 예전엔 10억 주를 넘으면 소수를 떼고(`60억 주`) 그 밑은 한 자리를 남겨
/// (`5.9억 주`) 같은 칸에서 규칙이 바뀌었다 — 축약 규칙은 하나다(QA #73).
/// 단위(주)는 ko 만 붙인다. en 은 행 라벨이 이미 들고 있다.
String fmtShares(double n) {
  if (localeIsEn()) return formatChartAxis(n);
  return '${formatChartAxis(n)} 주';
}

class _StockInfoCard extends ConsumerWidget {
  const _StockInfoCard({
    required this.symbol,
    required this.currency,
    required this.info,
    required this.lastPrice,
    required this.fxRate,
    this.failed = false,
  });
  final String symbol;
  final String currency;
  final TossStockInfo? info;
  final double? lastPrice;
  final double? fxRate;

  /// 정보 조회가 실패했다 — "정상" 같은 거짓 값을 그리지 않고 실패 한 벌로 보인다(H2).
  final bool failed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (failed) {
      return StocksFailure(
        title: l.stocksFailInfo,
        onRetry: () => ref.invalidate(tossStockInfoProvider(symbol)),
      );
    }
    final info = this.info; // 로컬 바인딩 → 널 승격(field promotion 불가) 위함.
    final isUs = currency == 'USD';
    final isKr = currency == 'KRW';
    final shares = info?.sharesValue ?? 0;
    // 시가총액 = 현재가 × 발행주식수 (USD 는 환율 환산). 시세 없으면 미표시. 웹 미러.
    final last = lastPrice;
    final fx = fxRate;
    final priceInKrw = last == null
        ? null
        : isUs
        ? (fx == null ? null : last * fx)
        : (isKr ? last : null);
    final mcKrw = (priceInKrw != null && shares > 0)
        ? priceInKrw * shares
        : null;
    final listDate = info?.listDate;

    final rows = <(String, String, Color?)>[
      (
        l.stocksMarket,
        info?.market.isNotEmpty == true
            ? stockMarketLabel(l, info!.market)
            : (isUs ? l.stocksMarketUs : l.stocksMarketKr),
        null,
      ),
      (
        l.stocksInstrumentType,
        info?.isEtf == true ? 'ETF' : l.stocksInstrumentStock,
        null,
      ),
      (
        l.stocksCurrency,
        info?.currency.isNotEmpty == true ? info!.currency : currency,
        null,
      ),
      if (mcKrw != null) (l.stocksMarketCap, fmtCapKrw(mcKrw), null),
      if (listDate != null && listDate.isNotEmpty)
        (l.stocksListingDate, fullDateOf(listDate), null),
      if (shares > 0) (l.stocksSharesOutstanding, fmtShares(shares), null),
      // 정보가 오기 전 · 빈 응답에는 "정상" 을 지어내지 않는다 — 거래정지 종목도 정상으로 보이던 것(M9)
      // 국내 종목 정보(koreanMarketDetail)가 있을 때만 — 미국이거나 빈 응답이면 줄을 뺀다(웹 M5)
      if (info?.koreanMarketDetail != null)
        (
          // 거래정지는 토스 status(분류성 값)가 아니라 KRX 거래정지 플래그로 판정.
          l.stocksTradingStatus,
          info?.koreanMarketDetail?.krxTradingSuspended == true
              ? l.stocksTradingSuspended
              : l.stocksTradingNormal,
          info?.koreanMarketDetail?.krxTradingSuspended == true
              ? context.colors.fgCritical
              : context.colors.fgPositive,
        ),
    ];

    return PList(
      semanticLabel: l.stocksBasicInfo,
      children: [
        for (final r in rows)
          stocksKvLine(context, r.$1, r.$2, valueColor: r.$3),
      ],
    );
  }
}

/// 띠 ④ 기본 정보.
class _InfoBand extends StatelessWidget {
  const _InfoBand({
    required this.symbol,
    required this.currency,
    required this.info,
    required this.lastPrice,
    required this.fxRate,
    this.failed = false,
  });
  final bool failed;
  final String symbol;
  final String currency;
  final TossStockInfo? info;
  final double? lastPrice;
  final double? fxRate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksBasicInfo),
          _StockInfoCard(
            symbol: symbol,
            currency: currency,
            info: info,
            lastPrice: lastPrice,
            fxRate: fxRate,
            failed: failed,
          ),
        ],
      ),
    );
  }
}

// ---- 호가창 (토스 orderbook · 실데이터 전용) ----------------------------------

/// 시험 · 렌더 하네스용 — 호가 표는 private 이라 이름만 열어 둔다.
@visibleForTesting
typedef OrderBookForTest = _OrderBook;

class _OrderBook extends StatelessWidget {
  const _OrderBook({
    required this.currency,
    required this.lastPrice,
    required this.book,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final TossOrderbook book;
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    // asks=낮은가격순 → 상단 표시(높은가격 위) 위해 5개 잘라 역순, bids=높은가격순 그대로.
    final asks = [
      for (final e in book.asks.take(5))
        (p: e.priceValue, q: e.volumeValue.round()),
    ].reversed.toList();
    final bids = [
      for (final e in book.bids.take(5))
        (p: e.priceValue, q: e.volumeValue.round()),
    ];
    var maxQ = 1;
    for (final a in asks) {
      if (a.q > maxQ) maxQ = a.q;
    }
    for (final b in bids) {
      if (b.q > maxQ) maxQ = b.q;
    }
    String fmt(double p) => fmtByCurrency(p, currency);

    Widget qtyBar({
      required int q,
      required Color tone,
      required bool alignRight,
    }) {
      final f = (maxQ <= 0 ? 0.0 : q / maxQ).clamp(0.0, 1.0);
      // 바는 항상 중심축(가격) 쪽에 붙어 바깥으로 자란다 — 매수=중심(오른쪽)에서 왼쪽으로,
      // 매도=중심(왼쪽)에서 오른쪽으로. FractionallySizedBox+Stack 은 좌측 고정 버그가 있어 Positioned 로 명시.
      // 높이는 글자를 따라 늘어난다(큰 글자에서 줄이 겹치지 않게) — 28 은 최소 높이. 잔량 글이 칸보다 넓으면
      // 글자를 줄이지 않고 쉼표 뒤에서만 줄을 바꾼다(DESIGN.md "금액은 쉼표 뒤에서만") — 바는 칸 높이를 따라간다.
      return LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned(
              top: 4,
              bottom: 4,
              left: alignRight ? null : 0,
              right: alignRight ? 0 : null,
              width: c.maxWidth * f,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone == context.colors.fgCritical
                      ? context.colors.bgCriticalWeak
                      : context.colors.bgInformativeWeak,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 28),
              child: Align(
                alignment: alignRight
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    alignRight ? 0 : 4,
                    4,
                    alignRight ? 4 : 0,
                    4,
                  ),
                  child: Text(
                    keepAllAmount(krw(q)),
                    textAlign: alignRight ? TextAlign.end : TextAlign.start,
                    style: PTypography.t3.copyWith(
                      color: context.colors.fgNeutralSubtle,
                      fontFeatures: kStocksTnum,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final l = AppLocalizations.of(context);
    Widget row({required double p, required int q, required bool isAsk}) {
      final priceColor = isAsk
          ? context.colors.fgInformative
          : context.colors.fgCritical;
      // 표 의미 구조(Q6) — 매수 · 매도 쪽과 가격 · 잔량을 한 줄로 읽는다
      return Semantics(
        label: isAsk
            ? l.stocksRowAsk(fmt(p), krw(q))
            : l.stocksRowBid(fmt(p), krw(q)),
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: isAsk
                    ? const SizedBox.shrink()
                    : qtyBar(
                        q: q,
                        tone: context.colors.fgCritical,
                        alignRight: true,
                      ),
              ),
              // 가격 칸은 줄지 않는다 — 최소 92, 큰 글자에서는 글자 폭만큼 넓어지고 잔량 칸이 먼저 줄어든다(잔량은 쉼표 뒤에서 줄바꿈).
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 92),
                child: Center(
                  child: Text(
                    fmt(p),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFeatures: kStocksTnum,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: priceColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isAsk
                    ? qtyBar(
                        q: q,
                        tone: context.colors.fgInformative,
                        alignRight: false,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: l.stocksOrderbookTableName,
      child: Column(
        children: [
          const _OrderBookHead(),
          const SizedBox(height: PSpacing.x1),
          for (final a in asks) row(p: a.p, q: a.q, isAsk: true),
          _OrderBookLast(
            currency: currency,
            lastPrice: lastPrice,
            changePct: changePct,
          ),
          for (final b in bids) row(p: b.p, q: b.q, isAsk: false),
        ],
      ),
    );
  }
}

/// 호가 테이블 헤더 — 정적 틀이라 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _OrderBookHead extends StatelessWidget {
  const _OrderBookHead();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: context.colors.fgNeutralSubtle,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            l.stocksBidVolume,
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        // 가격 칸(행)이 큰 글자에서 글자 폭만큼 넓어지므로 머리도 최소 92 로 두고 가운데 정렬 — 행과 같은 가운데에 선다
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 92),
          child: Text(
            l.stocksTradePrice,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        Expanded(child: Text(l.stocksAskVolume, style: style)),
      ],
    );
  }
}

/// 현재가 스트립 — 값이 호가 응답이 아니라 상위에서 이미 받아둔 시세라
/// 호가 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _OrderBookLast extends StatelessWidget {
  const _OrderBookLast({
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: context.colors.strokeNeutralSubtle),
        ),
      ),
      // 큰 글자 · 좁은 폭에서 현재가와 등락률이 한 줄에 못 들어가면 줄을 나눠 쌓는다 — 가격은 줄이지 않는다(N5)
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          Text(
            lastPrice != null ? fmtByCurrency(lastPrice!, currency) : '—',
            maxLines: 1,
            softWrap: false,
            style: PTypography.t4.copyWith(
              // 전일 종가를 못 받으면 등락을 모른다 — 방향 색 · 가짜 0.00% 를 그리지 않는다(M4)
              color: changePct == null
                  ? context.colors.fgNeutral
                  : stocksRoleTrend(context, changePct!),
              fontWeight: FontWeight.w700,
              fontFeatures: kStocksTnum,
            ),
          ),
          if (changePct != null) StocksPctDelta(changePct!),
        ],
      ),
    );
  }
}

/// 호가 로딩 스켈레톤 — [_OrderBook] 실렌더 구조를 그대로 따른다.
/// 헤더 행과 현재가 스트립은 실 위젯을 그대로 쓰고, 서버에서 오는 매도/매수
/// 5호가 자리만 placeholder — 행 26 / 잔량 바 22 / 가격 컬럼 92 고정.
class _OrderBookSkeleton extends StatelessWidget {
  const _OrderBookSkeleton({
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final double? changePct;

  /// 잔량 바 길이는 실렌더에서 maxQ 대비 비율이라 값을 알 수 없다 — 프레임마다
  /// 흔들리지 않도록 고정 시퀀스로 대체(랜덤 금지). asks 는 위가 고가라 역순 모양.
  static const _askBars = [0.34, 0.52, 0.41, 0.66, 0.47];
  static const _bidBars = [0.58, 0.44, 0.70, 0.38, 0.50];

  @override
  Widget build(BuildContext context) {
    // 실렌더 row(): SizedBox(height: 26) + 가운데 가격 컬럼 92 고정.
    // 잔량 바는 중심축(가격)에 붙어 바깥으로 자라므로 정렬도 매도=왼쪽/매수=오른쪽.
    Widget row(double factor, {required bool isAsk}) {
      // 실렌더 qtyBar 의 높이 22 · radius 4(=PRadius.brSm, PSkeleton 기본값).
      final bar = FractionallySizedBox(
        alignment: isAsk ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: factor,
        child: const PSkeleton(height: 28),
      );
      return SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(child: isAsk ? const SizedBox.shrink() : bar),
            const SizedBox(
              width: 92,
              child: Center(child: PSkeleton(width: 56, height: 12)),
            ),
            Expanded(child: isAsk ? bar : const SizedBox.shrink()),
          ],
        ),
      );
    }

    return Column(
      children: [
        const _OrderBookHead(),
        const SizedBox(height: PSpacing.x1),
        for (final f in _askBars) row(f, isAsk: true),
        _OrderBookLast(
          currency: currency,
          lastPrice: lastPrice,
          changePct: changePct,
        ),
        for (final f in _bidBars) row(f, isAsk: false),
      ],
    );
  }
}

// ---- 호가 / 체결 탭 카드 (실데이터 전용 · 로딩/빈 상태) -----------------------

typedef _Fill = ({String time, double p, int q, int dir});

/// 라이브 체결 테이프 변환 (토스 trades). dir=직전 체결가 대비 방향. 웹 `liveTradeFills` 미러.
List<_Fill> _liveTradeFills(List<TossTrade>? trades) {
  if (trades == null || trades.isEmpty) return const [];
  final out = <_Fill>[];
  final n = trades.length < 12 ? trades.length : 12;
  for (var i = 0; i < n; i++) {
    final tr = trades[i];
    final p = tr.priceValue;
    final prev = i + 1 < trades.length ? trades[i + 1].priceValue : p;
    final time = clock12Minutes(tr.timestamp);
    out.add((
      time: time,
      p: p,
      q: tr.volumeValue.round(),
      dir: p >= prev ? 1 : -1,
    ));
  }
  return out;
}

class _QuotesEmpty extends StatelessWidget {
  const _QuotesEmpty(this.msg);
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: PSpacing.x8,
        horizontal: 12,
      ),
      child: Center(
        child: Text(
          msg,
          style: PTypography.t4.copyWith(color: context.colors.fgNeutralSubtle),
        ),
      ),
    );
  }
}

/// 호가 · 체결 탭 카드 — 토스 · 나무가 같이 쓴다(I-13b 21). **고른 탭의 질의만 지켜본다** — 호가 탭일 때
/// 체결은 부르지 않는다(본인 키 호출을 줄인다). 값의 출처는 호출부가 [watchBook] · [watchTrades] 로 준다.
class StocksQuotesCard extends ConsumerStatefulWidget {
  const StocksQuotesCard({
    super.key,
    required this.symbol,
    required this.currency,
    required this.lastPrice,
    required this.changePct,
    required this.watchBook,
    required this.watchTrades,
    this.onTabChanged,
    this.onRetryBook,
    this.onRetryTrades,
  });

  /// 탭이 바뀔 때('book' | 'tape') — 체결 폴링을 탭에 맞춰 켜고 끄는 호출부가 쓴다.
  final ValueChanged<String>? onTabChanged;

  /// 호가 · 체결 실패 한 벌의 [다시 시도] — 호출부가 자기 질의를 비운다.
  final void Function(WidgetRef ref)? onRetryBook;
  final void Function(WidgetRef ref)? onRetryTrades;
  final String symbol;
  final String currency;
  final double? lastPrice;
  final double? changePct;
  final AsyncValue<TossOrderbook?> Function(WidgetRef ref) watchBook;
  final AsyncValue<List<TossTrade>?> Function(WidgetRef ref) watchTrades;

  @override
  ConsumerState<StocksQuotesCard> createState() => _StocksQuotesCardState();
}

class _StocksQuotesCardState extends ConsumerState<StocksQuotesCard> {
  String _tab = 'book';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    Widget content;
    if (_tab == 'book') {
      final orderbookAsync = widget.watchBook(ref);
      // `asData` 는 AsyncData 일 때만 값을 준다 — 폴링이 만드는 재조회 상태에서 들고 있던 호가를 버리므로 `value` 로 읽는다.
      final book = orderbookAsync.value;
      // 한쪽만 비어도(상한가 · 하한가) 있는 쪽 줄은 그린다 — 둘 다 비어야 "호가 정보가 없어요"(웹 M9)
      final hasBook =
          book != null && (book.asks.isNotEmpty || book.bids.isNotEmpty);
      // 호가는 주기마다 다시 받는다. 그때마다 스켈레톤을 깔면 들고 있던 호가창이 사라진다 — 새 호가가 닿을
      // 때까지 직전 호가를 그대로 둔다. 스켈레톤은 아직 아무것도 못 받았을 때만.
      if (orderbookAsync.isLoading && !orderbookAsync.hasValue) {
        content = Semantics(
          label: l.stocksOrderbookLoading,
          child: _OrderBookSkeleton(
            currency: widget.currency,
            lastPrice: widget.lastPrice,
            changePct: widget.changePct,
          ),
        );
      } else if (hasBook) {
        content = _OrderBook(
          currency: widget.currency,
          lastPrice: widget.lastPrice,
          book: book,
          changePct: widget.changePct,
        );
      } else if (orderbookAsync.hasError && !orderbookAsync.hasValue) {
        content = StocksFailure(
          title: l.stocksFailOrderbook,
          onRetry: () => widget.onRetryBook?.call(ref),
        );
      } else {
        content = _QuotesEmpty(l.stocksOrderbookEmpty);
      }
    } else {
      final tradesAsync = widget.watchTrades(ref);
      final fills = _liveTradeFills(tradesAsync.value);
      // 체결도 주기 폴링이다 — 직전 체결 테이프를 새 체결이 닿을 때까지 둔다.
      if (tradesAsync.isLoading && !tradesAsync.hasValue) {
        content = Semantics(
          label: l.stocksTradesLoading,
          child: const _TradeTapeSkeleton(),
        );
      } else if (tradesAsync.hasError && !tradesAsync.hasValue) {
        content = StocksFailure(
          title: l.stocksFailTrades,
          onRetry: () => widget.onRetryTrades?.call(ref),
        );
      } else if (fills.isEmpty) {
        content = _QuotesEmpty(l.stocksTradesEmpty);
      } else {
        content = _TradeTape(currency: widget.currency, fills: fills);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
          child: PSegmentedControl<String>(
            value: _tab,
            onChanged: (v) {
              setState(() => _tab = v);
              widget.onTabChanged?.call(v);
            },
            semanticLabel: l.stocksOrderbookTrades,
            items: [
              PSegmentedItem(value: 'book', label: l.stocksOrderbook),
              PSegmentedItem(value: 'tape', label: l.stocksTrades),
            ],
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
          child: content,
        ),
      ],
    );
  }
}

// ---- 체결 테이프 (토스 trades · 실데이터 전용) --------------------------------

/// 체결 표 열 폭 — 시각 · 가격 · 체결량. 가격 칸은 **글자 폭을 먼저 잡고**(큰 글자 · 7자리 가격에서도 안 잘린다), 남은 폭을
/// 시각 4 : 체결량 3 으로 나눈다. 평소에는 가격이 전체의 5/12 보다 좁지 않다(N5).
typedef _TapeCols = ({double time, double price, double qty});

_TapeCols _tapeCols(double total, double priceNeed) {
  final price = priceNeed > total * 5 / 12 ? priceNeed : total * 5 / 12;
  final rest = (total - price).clamp(0.0, double.infinity);
  return (time: rest * 4 / 7, price: price, qty: rest * 3 / 7);
}

class _TradeTape extends StatelessWidget {
  const _TradeTape({required this.currency, required this.fills});
  final String currency;
  final List<_Fill> fills;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String fmt(double p) => fmtByCurrency(p, currency);
    final priceStyle = TextStyle(
      fontFeatures: kStocksTnum,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      container: true,
      label: l.stocksTradesTableName,
      child: LayoutBuilder(
        builder: (context, box) {
          final scaler = MediaQuery.textScalerOf(context);
          double need = 0;
          for (final f in [
            for (final f in fills) fmt(f.p),
            l.stocksTradePrice,
          ]) {
            final tp = TextPainter(
              text: TextSpan(text: f, style: priceStyle),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            if (tp.width + 8 > need) need = tp.width + 8;
          }
          final cols = _tapeCols(box.maxWidth, need);
          return Column(
            children: [
              _TradeTapeHead(cols: cols),
              const SizedBox(height: PSpacing.x1),
              for (final f in fills)
                Semantics(
                  label: l.stocksRowTrade(f.time, fmt(f.p), krw(f.q)),
                  excludeSemantics: true,
                  // 줄 높이는 글자를 따라 늘어난다(32 는 최소) — 큰 글자에서 시각 · 가격이 겹치지 않게
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: cols.time,
                          child: Text(
                            f.time,
                            style: TextStyle(
                              fontFeatures: kStocksTnum,
                              fontSize: 13,
                              color: context.colors.fgNeutralSubtle,
                            ),
                          ),
                        ),
                        // 가격은 줄이지 않는다 — 칸이 글자 폭만큼 넓고 줄바꿈도 막는다
                        SizedBox(
                          width: cols.price,
                          child: Text(
                            fmt(f.p),
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: priceStyle.copyWith(
                              color: stocksRoleTrend(context, f.dir.toDouble()),
                            ),
                          ),
                        ),
                        // 체결량이 먼저 줄어든다
                        SizedBox(
                          width: cols.qty,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                krw(f.q),
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontFeatures: kStocksTnum,
                                  fontSize: 13,
                                  color: context.colors.fgNeutral,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 체결 테이블 헤더 — 정적 틀이라 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
/// [cols] 가 없으면(스켈레톤) 4 : 5 : 3 비로 나눈다.
class _TradeTapeHead extends StatelessWidget {
  const _TradeTapeHead({this.cols});
  final _TapeCols? cols;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final head = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: context.colors.fgNeutralSubtle,
    );
    Widget cell(double? w, int flex, Widget child) => w == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: w, child: child);
    return Row(
      children: [
        cell(cols?.time, 4, Text(l.stocksTradeTime, style: head)),
        cell(
          cols?.price,
          5,
          Text(l.stocksTradePrice, textAlign: TextAlign.right, style: head),
        ),
        cell(
          cols?.qty,
          3,
          Text(l.stocksTradeVolume, textAlign: TextAlign.right, style: head),
        ),
      ],
    );
  }
}

/// 체결 로딩 스켈레톤 — [_TradeTape] 실렌더 구조를 그대로 따른다.
/// 헤더는 실 위젯을 그대로 쓰고 체결 행만 placeholder — `_liveTradeFills` 상한인
/// 12행 · 행 높이 25 · 3등분 컬럼(시간 좌 / 가격 우 / 수량 우) 그대로.
class _TradeTapeSkeleton extends StatelessWidget {
  const _TradeTapeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TradeTapeHead(),
        const SizedBox(height: PSpacing.x1),
        for (var i = 0; i < 12; i++)
          const SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PSkeleton(width: 52, height: 12),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PSkeleton(width: 48, height: 12),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PSkeleton(width: 36, height: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
