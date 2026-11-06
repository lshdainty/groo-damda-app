import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/presentation/fixed_variable_tab.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_compare_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_range_sheet.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_trend_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';

// 집계 도우미(일별 추이 · 건수 · 요일 합)는 stats_model.dart 에 있다 — 시험이 이 화면 파일로 불러 쓰므로 다시 내보낸다.
export 'package:groo_damda_app/features/stats/presentation/stats_model.dart'
    show dailyTrendOf, statsExpenseCount, statsNow, statsWeekdaySums;

/// 통계 화면(I-08 29 ~ 42) — 가계부 묶음 Line 탭 아래 칩 탭(Chip Tabs solid large 40, 위아래 틈 0), 그 아래 구역마다 흰 띠(사이 8).
/// 칩 탭은 눌러서만 바뀐다(2차 탭은 밀어 넘기지 않는다 — Tabs 7A). 기간 버튼은 첫 띠 머리 오른쪽에 있다(따로 띠를 두지 않는다).
/// 머리 없는 띠(요약 · 지표 · 저축률)는 위 24 에서 첫 글이 시작한다. 폰은 질의 하나 = 실패 상자 하나 — 같은 질의를 먹는 뒤 띠는
/// 상자를 또 그리지 않는다. 웹 `StatsMobile.tsx` 짝.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsTab _tab = StatsTab.category;
  StatsPeriod _period = StatsPeriod.thisMonth(statsNow());

  Future<void> _pickRange() async {
    final picked = await showStatsRangeSheet(
      context,
      _period,
      today: statsNow(),
    );
    if (picked != null && mounted) setState(() => _period = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      // 폰 구역 화면 — 구역마다 흰 띠, 사이 8 은 회색 바닥. 칩 탭 줄은 흰 면(위 가계부 묶음 탭과 붙는다).
      backgroundColor: c.bgLayerBasement,
      body: Column(
        children: [
          ColoredBox(
            color: c.bgLayerDefault,
            child: SizedBox(
              width: double.infinity,
              child: PChipTabs<StatsTab>(
                value: _tab,
                semanticLabel: l.statsTabsAria,
                size: PChipTabsSize.large,
                onChanged: (v) => setState(() => _tab = v),
                items: [
                  PTab(value: StatsTab.category, label: l.expCategory),
                  PTab(value: StatsTab.trend, label: l.statsTabTrend),
                  PTab(value: StatsTab.compare, label: l.statsTabCompare),
                  PTab(value: StatsTab.fixed, label: l.statsTabFixed),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              StatsTab.category => _CategoryTab(
                period: _period,
                onPickPeriod: _pickRange,
              ),
              StatsTab.trend => _TrendTab(
                period: _period,
                onPickPeriod: _pickRange,
              ),
              StatsTab.compare => _CompareTab(period: _period),
              StatsTab.fixed => FixedVariableTab(
                period: _period,
                onPickPeriod: _pickRange,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// 탭 하나의 스크롤 목록 — 띠 사이 8, 맨 위 · 맨 아래 틈 없음(떠 있는 하단 바 보상만).
Widget _bandList(
  BuildContext context, {
  required String storageKey,
  required List<Widget> bands,
  required Future<void> Function() onRefresh,
}) {
  return PPullToRefresh(
    onRefresh: () async {
      await onRefresh();
    },
    child: ListView(
      // 탭을 넘겼다 돌아와도 보던 위치를 지킨다
      key: PageStorageKey(storageKey),
      padding: EdgeInsets.only(bottom: bottomNavigationInset(context)),
      children: PScreenBands.children(bands),
    ),
  );
}

// ─── 카테고리 탭 ────────────────────────────────────────────

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({required this.period, required this.onPickPeriod});

  final StatsPeriod period;
  final VoidCallback onPickPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final range = period.range;
    final merchantKey = (startDate: range.startDate, endDate: range.endDate);
    final rangeAsync = ref.watch(rangeSummaryProvider(range));
    final categoriesAsync = ref.watch(categoriesProvider);
    final merchantAsync = ref.watch(merchantSummaryProvider(merchantKey));
    final heatAsync = ref.watch(heatmapProvider(range));
    // 가맹점 대표 카테고리 아이콘 역산용 원시 거래 · 하루 평균 전월 대비용 이전 기간
    final expensesAsync = ref.watch(rangeExpensesProvider(range));
    final prevAsync = ref.watch(rangeSummaryProvider(period.prevRange));
    final masked = ref.watch(hideCardProvider('stats.category'));

    final rangeFailed = rangeAsync.hasError && rangeAsync.value == null;
    final merchantFailed =
        merchantAsync.hasError && merchantAsync.value == null;
    final heatFailed = heatAsync.hasError && heatAsync.value == null;

    final bands = <Widget>[
      budgetBand([
        rangeFailed
            ? statsFailureSection(
                header: BudgetHead(
                  title: l.statsSpendingByCategory,
                  trailing: StatsPeriodButton(
                    period: period,
                    onPressed: onPickPeriod,
                  ),
                ),
                title: l.statsLoadFailedCategory,
                retrying: rangeAsync.loadRetrying,
                onRetry: () => ref.invalidate(rangeSummaryProvider(range)),
              )
            : StatsDonutSection(
                period: period,
                onPickPeriod: onPickPeriod,
                summary: rangeAsync.value,
                categories: categoriesAsync.value,
                masked: masked,
              ),
      ]),
      budgetBand([
        merchantFailed
            ? statsFailureSection(
                header: BudgetHead(title: l.statsTopMerchantsTitle),
                title: l.statsLoadFailedMerchant,
                retrying: merchantAsync.loadRetrying,
                onRetry: () =>
                    ref.invalidate(merchantSummaryProvider(merchantKey)),
              )
            : StatsMerchantsSection(
                merchants: merchantAsync.value,
                masked: masked,
              ),
      ]),
      budgetBand([
        heatFailed
            ? statsFailureSection(
                header: BudgetHead(title: l.statsPatternTitle),
                title: l.statsLoadFailedHeatmap,
                retrying: heatAsync.loadRetrying,
                onRetry: () => ref.invalidate(heatmapProvider(range)),
              )
            : StatsHeatmapSection(
                period: period,
                cells: heatAsync.value,
                masked: masked,
              ),
      ]),
      // 요약은 합계 · 가맹점 질의를 먹는다 — 둘 중 하나가 실패하면 앞 띠가 이미 말했으니 이 띠는 그리지 않는다
      if (!rangeFailed && !merchantFailed)
        budgetBand([
          StatsHighlightsSection(
            period: period,
            summary: rangeAsync.value,
            prevSummary: prevAsync.value,
            prevLoading: prevAsync.isLoading && !prevAsync.hasValue,
            categories: categoriesAsync.value,
            merchants: merchantAsync.value,
            expenses: expensesAsync.value,
            masked: masked,
          ),
        ]),
    ];

    return _bandList(
      context,
      storageKey: 'stats-category',
      bands: bands,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(range));
        ref.invalidate(merchantSummaryProvider(merchantKey));
        ref.invalidate(heatmapProvider(range));
        ref.invalidate(rangeExpensesProvider(range));
        await Future.wait([
          ref.read(rangeSummaryProvider(range).future),
          ref.read(heatmapProvider(range).future),
          ref.read(rangeExpensesProvider(range).future),
        ]);
      },
    );
  }
}

// ─── 추이 탭 ────────────────────────────────────────────────

class _TrendTab extends ConsumerWidget {
  const _TrendTab({required this.period, required this.onPickPeriod});

  final StatsPeriod period;
  final VoidCallback onPickPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final range = period.range;
    final rangeAsync = ref.watch(rangeSummaryProvider(range));
    final expensesAsync = ref.watch(rangeExpensesProvider(range));
    final categoriesAsync = ref.watch(categoriesProvider);
    final masked = ref.watch(hideCardProvider('stats.trend'));

    final summary = rangeAsync.value;
    final buckets = summary?.monthlyBuckets.length ?? 0;
    final daily = period.useDailyTrend(buckets);
    final rangeFailed = rangeAsync.hasError && summary == null;
    final expensesFailed =
        daily && expensesAsync.hasError && expensesAsync.value == null;
    // 추이 · 순저축은 같은 점을 먹는다 — 한쪽이 실패하면 첫 띠 하나가 말한다
    final trendFailed = rangeFailed || expensesFailed;
    final loading = summary == null || (daily && expensesAsync.value == null);
    final points = loading
        ? null
        : trendPoints(period, summary, expensesAsync.value ?? const []);

    final bands = <Widget>[
      budgetBand([
        trendFailed
            ? statsFailureSection(
                header: BudgetHead(
                  title: l.statsIncomeExpenseTrend,
                  trailing: StatsPeriodButton(
                    period: period,
                    onPressed: onPickPeriod,
                  ),
                ),
                title: l.statsLoadFailedTrend,
                retrying: anyLoadRetrying([rangeAsync, expensesAsync]),
                onRetry: () {
                  if (rangeFailed) ref.invalidate(rangeSummaryProvider(range));
                  if (expensesFailed) {
                    ref.invalidate(rangeExpensesProvider(range));
                  }
                },
              )
            : StatsTrendSection(
                period: period,
                onPickPeriod: onPickPeriod,
                points: points,
                daily: daily,
                masked: masked,
              ),
      ]),
      if (!rangeFailed)
        budgetBand([
          StatsSavingsRateSection(
            period: period,
            buckets: summary?.monthlyBuckets,
            masked: masked,
          ),
        ]),
      if (!trendFailed)
        budgetBand([
          StatsSavingsBarsSection(
            period: period,
            points: points,
            daily: daily,
            masked: masked,
          ),
        ]),
      // 카테고리 월별 추이는 여러 달(2+)일 때만 — 단일 월은 카테고리 탭 도넛이 담당(웹 showCatTrend)
      if (!rangeFailed && buckets >= 2)
        budgetBand([
          StatsCatTrendSection(
            period: period,
            summary: summary,
            categories: categoriesAsync.value,
            masked: masked,
          ),
        ]),
    ];
    return _bandList(
      context,
      storageKey: 'stats-trend',
      bands: bands,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(range));
        ref.invalidate(rangeExpensesProvider(range));
        await Future.wait([
          ref.read(rangeSummaryProvider(range).future),
          ref.read(rangeExpensesProvider(range).future),
        ]);
      },
    );
  }
}

// ─── 비교 탭 ────────────────────────────────────────────────

class _CompareTab extends ConsumerWidget {
  const _CompareTab({required this.period});

  final StatsPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final range = period.range;
    final prevRange = period.prevRange;
    final rangeAsync = ref.watch(rangeSummaryProvider(range));
    final prevAsync = ref.watch(rangeSummaryProvider(prevRange));
    final categoriesAsync = ref.watch(categoriesProvider);
    // 지표 건수 · 요일별 지출 비교 — 이번/지난 기간 원시 거래
    final nowExpAsync = ref.watch(rangeExpensesProvider(range));
    final prevExpAsync = ref.watch(rangeExpensesProvider(prevRange));
    final masked = ref.watch(hideCardProvider('stats.compare'));

    final rangeFailed = rangeAsync.hasError && rangeAsync.value == null;
    final prevFailed = prevAsync.hasError && prevAsync.value == null;
    final summaryFailed = rangeFailed || prevFailed;
    final nowExpFailed = nowExpAsync.hasError && nowExpAsync.value == null;
    final prevExpFailed = prevExpAsync.hasError && prevExpAsync.value == null;
    final expFailed = nowExpFailed || prevExpFailed;

    void retryExpenses() {
      if (nowExpFailed) ref.invalidate(rangeExpensesProvider(range));
      if (prevExpFailed) ref.invalidate(rangeExpensesProvider(prevRange));
    }

    final bands = <Widget>[
      budgetBand([
        summaryFailed
            ? statsFailureSection(
                header: null,
                title: l.statsLoadFailedCompare,
                retrying: anyLoadRetrying([rangeAsync, prevAsync]),
                onRetry: () {
                  if (rangeFailed) ref.invalidate(rangeSummaryProvider(range));
                  if (prevFailed) {
                    ref.invalidate(rangeSummaryProvider(prevRange));
                  }
                },
              )
            : StatsCompareSummarySection(
                period: period,
                now: rangeAsync.value,
                prev: prevAsync.value,
                masked: masked,
              ),
      ]),
      // 지표 · 카테고리 증감은 합계 질의(지표는 거래 질의도)를 먹는다 — 앞 띠 · 요일 띠가 이미 말했으니 그리지 않는다
      if (!summaryFailed && !expFailed)
        budgetBand([
          StatsCompareMetricsSection(
            period: period,
            now: rangeAsync.value,
            prev: prevAsync.value,
            nowExpenses: nowExpAsync.value,
            prevExpenses: prevExpAsync.value,
            masked: masked,
          ),
        ]),
      if (!summaryFailed)
        budgetBand([
          StatsCompareCategorySection(
            now: rangeAsync.value,
            prev: prevAsync.value,
            categories: categoriesAsync.value,
            masked: masked,
          ),
        ]),
      budgetBand([
        expFailed
            ? statsFailureSection(
                header: BudgetHead(title: l.statsWeekdayTitle),
                title: l.statsLoadFailedWeekday,
                retrying: anyLoadRetrying([nowExpAsync, prevExpAsync]),
                onRetry: retryExpenses,
              )
            : StatsCompareWeekdaySection(
                period: period,
                nowExpenses: nowExpAsync.value,
                prevExpenses: prevExpAsync.value,
                masked: masked,
              ),
      ]),
    ];
    return _bandList(
      context,
      storageKey: 'stats-compare',
      bands: bands,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(range));
        ref.invalidate(rangeSummaryProvider(prevRange));
        ref.invalidate(rangeExpensesProvider(range));
        ref.invalidate(rangeExpensesProvider(prevRange));
        await Future.wait([
          ref.read(rangeSummaryProvider(range).future),
          ref.read(rangeSummaryProvider(prevRange).future),
          ref.read(rangeExpensesProvider(range).future),
          ref.read(rangeExpensesProvider(prevRange).future),
        ]);
      },
    );
  }
}
