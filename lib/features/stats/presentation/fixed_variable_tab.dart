import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/fixed_split.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/fixed_bulk_page.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 통계 · 고정/변동 탭 — 한 기간의 수입·지출을 **고정**과 **변동(고정 제외)** 으로 나눠 보여 준다(I-08 38).
/// 웹 `fixed-parts.tsx` 짝.
///
/// 서버가 내리는 건 전체와 그 가운데 고정인 몫뿐이다. 변동은 `전체 − 고정` 으로 이 화면이 구한다
/// ([splitFixed]). 두 계열의 색은 차트 배정 차례 첫 두 색 — 고정 파랑 · 변동 초록(Q1-A1, 지출 · 수입 탭 같은 색).
/// 색만으로 가르지 않는다 — 막대 옆에는 늘 이름과 숫자가 붙는다.
enum _Kind { expense, income }

const _fixedColor = PChartColor.blue;
const _variableColor = PChartColor.green;

/// 질의 하나 = 상자 하나 — 합계 질의가 실패하면 첫 띠에만 상자를 두고 같은 질의를 먹는 뒤 띠는 그리지 않는다.
/// 고정 · 변동 비중 한 자리("33.2%") — 0 초과 0.05% 미만은 "0.1% 미만".
String _share(AppLocalizations l, double pct) =>
    formatShare(pct, underOne: l.percentUnderTenth);

/// 한 줄 안내 — 고정 비중이 "0.1% 미만" 이면 숫자 없는 글로 간다(조사가 어색해서).
String _insight(AppLocalizations l, FixedSplit s, bool isExpense) {
  final tiny = s.fixed > 0 && s.fixedShare < 0.05;
  if (tiny) {
    return isExpense
        ? l.statsFixedInsightExpenseNone
        : l.statsFixedInsightIncomeNone;
  }
  final pct = _share(l, s.fixedShare);
  return isExpense
      ? l.statsFixedInsightExpense(pct)
      : l.statsFixedInsightIncome(pct);
}

class FixedVariableTab extends ConsumerWidget {
  const FixedVariableTab({
    super.key,
    required this.period,
    required this.onPickPeriod,
  });

  final StatsPeriod period;
  final VoidCallback onPickPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final range = period.range;
    final rangeAsync = ref.watch(rangeSummaryProvider(range));
    final categoriesAsync = ref.watch(categoriesProvider);
    final masked = ref.watch(hideCardProvider('stats.fixed'));
    final summary = rangeAsync.value;
    final failed = rangeAsync.hasError && summary == null;
    void retry() => ref.invalidate(rangeSummaryProvider(range));
    void manage() => openFixedBulkPage(context, range);

    BudgetHead head(_Kind kind) => BudgetHead(
      title: kind == _Kind.expense
          ? l.statsFixedExpenseTitle
          : l.statsFixedIncomeTitle,
      trailing: kind == _Kind.expense
          ? StatsPeriodButton(period: period, onPressed: onPickPeriod)
          : null,
    );

    final bands = <Widget>[];
    if (failed) {
      bands.add(
        budgetBand([
          statsFailureSection(
            header: head(_Kind.expense),
            title: l.statsLoadFailedFixed,
            retrying: rangeAsync.loadRetrying,
            onRetry: retry,
          ),
        ]),
      );
    } else {
      bands.add(
        budgetBand([
          _Overview(
            kind: _Kind.expense,
            head: head(_Kind.expense),
            split: summary == null
                ? null
                : splitFixed(summary.totalExpense, summary.fixedExpense),
            masked: masked,
            onManage: manage,
          ),
        ]),
      );
      bands.add(
        budgetBand([
          _Overview(
            kind: _Kind.income,
            head: head(_Kind.income),
            split: summary == null
                ? null
                : splitFixed(summary.totalIncome, summary.fixedIncome),
            masked: masked,
            onManage: manage,
          ),
        ]),
      );
      bands.add(budgetBand([_MonthlyStack(summary: summary, masked: masked)]));
      if (summary != null) {
        final rows = _categoryRows(
          summary.categoryBreakdown,
          catIndex(categoriesAsync.value),
          l.statsUnassigned,
        );
        if (rows.isNotEmpty) {
          bands.add(
            budgetBand([
              _CategoryBars(rows: rows, masked: masked, onManage: manage),
            ]),
          );
        }
      }
    }

    return PPullToRefresh(
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(range));
        ref.invalidate(monthlyTrendProvider(6));
        await Future.wait([
          ref.read(rangeSummaryProvider(range).future),
          ref.read(monthlyTrendProvider(6).future),
        ]);
      },
      child: ListView(
        key: const PageStorageKey('stats-fixed'),
        padding: EdgeInsets.only(bottom: bottomNavigationInset(context)),
        children: PScreenBands.children(bands),
      ),
    );
  }
}

/// 고정(파랑) / 변동(초록) 견본 — 범례와 숫자 줄이 같은 모양을 쓴다.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final PChartColor color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: PSpacing.x2_5,
      height: PSpacing.x2_5,
      decoration: BoxDecoration(
        color: color.of(context.colors),
        borderRadius: BorderRadius.circular(PRounded.r0_5),
      ),
    ),
  );
}

/// 지출 또는 수입 한 종류의 개요 — 비율 막대 + 전체·고정·고정 제외 숫자 + 한 줄 해설.
class _Overview extends StatelessWidget {
  const _Overview({
    required this.kind,
    required this.head,
    required this.split,
    required this.masked,
    required this.onManage,
  });

  final _Kind kind;
  final Widget head;

  /// null 이면 첫 불러오기.
  final FixedSplit? split;
  final bool masked;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final isExpense = kind == _Kind.expense;
    final s = split;
    if (s == null) {
      return statsSection(
        header: head,
        children: const [
          PSkeleton(
            width: double.infinity,
            height: PSpacing.x7,
            radius: PSkeletonRadius.r8,
          ),
          SizedBox(height: PSpacing.x4),
          PSkeleton(width: 160, height: 22),
        ],
      );
    }
    if (s.total == 0) {
      return statsSection(
        header: head,
        children: [
          BudgetEmptyLine(
            isExpense ? l.statsFixedExpenseNone : l.statsFixedIncomeNone,
          ),
        ],
      );
    }
    final noFixed = s.fixed == 0;
    final totalLabel = isExpense
        ? l.statsFixedTotalExpense
        : l.statsFixedTotalIncome;
    final figures =
        <({String label, int value, PChartColor? swatch, String? sub})>[
          (label: totalLabel, value: s.total, swatch: null, sub: null),
          (
            label: isExpense
                ? l.statsFixedFixedExpense
                : l.statsFixedFixedIncome,
            value: s.fixed,
            swatch: _fixedColor,
            sub: _share(l, s.fixedShare),
          ),
          (
            label: isExpense
                ? l.statsFixedVariableExpense
                : l.statsFixedVariableIncome,
            value: s.variable,
            swatch: _variableColor,
            sub: _share(l, s.variableShare),
          ),
        ];
    return statsSection(
      header: head,
      children: [
        _RatioBar(
          split: s,
          semanticLabel: l.statsFixedBarSemantics(
            totalLabel,
            _share(l, s.fixedShare),
            _share(l, s.variableShare),
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        // 폰은 한 줄에 하나 — 이름 · 값 키-값 줄
        BudgetFull(
          child: PList(
            children: [
              for (final f in figures)
                PListItem(
                  // 비율은 제목 글에 붙인다 — 제목 뒤 붙이개(WidgetSpan)는 큰 글자에서 글자 배율이 두 번 먹어 제목보다 커진다
                  title: f.sub == null ? f.label : '${f.label} ${f.sub}',
                  verticalPadding: PSpacing.x2,
                  prefix: f.swatch == null ? null : _Swatch(color: f.swatch!),
                  suffix: PListValue.amount(
                    statsWon(f.value, masked),
                    style: TextStyle(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        if (noFixed) ...[
          BudgetDesc(l.statsFixedEmptyDesc),
          const SizedBox(height: PSpacing.x3),
          Align(
            alignment: Alignment.centerLeft,
            child: PButton(
              label: l.statsFixedManage,
              variant: PButtonVariant.neutralOutline,
              size: PButtonSize.small,
              onPressed: onManage,
            ),
          ),
        ] else
          Text.rich(
            TextSpan(
              style: PTypography.t3.copyWith(color: c.fgNeutralMuted),
              children: [
                TextSpan(text: '${keepAll(_insight(l, s, isExpense))} '),
                TextSpan(
                  text: keepAllAmount(statsWon(s.variable, masked)),
                  style: TextStyle(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: keepAll(l.statsFixedInsightTail)),
              ],
            ),
          ),
      ],
    );
  }
}

/// 한 줄 비율 막대 — 왼쪽이 고정(파랑), 오른쪽이 변동(초록). 폭은 전체에 대한 비율이다. 안의 % 글은 차트 색 위 글자색 fg-neutral-inverted(chart.md:446 — 테마를 따라가고
/// 막대 색 위 4.5 이상).
class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.split, required this.semanticLabel});

  final FixedSplit split;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fixedFrac = split.total == 0 ? 0.0 : split.fixed / split.total;
    Widget cell(String? text, Color fill) => ColoredBox(
      color: fill,
      child: Center(
        child: text == null
            ? null
            : Text(
                text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: PTypography.t2.copyWith(
                  color: c.fgNeutralInverted,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.r2),
        child: SizedBox(
          height: PSpacing.x7,
          child: ColoredBox(
            color: c.bgNeutralWeak,
            child: Row(
              children: [
                if (split.fixed > 0)
                  Expanded(
                    flex: math.max(1, (fixedFrac * 10000).round()),
                    child: cell(
                      fixedFrac >= 0.14
                          ? _share(
                              AppLocalizations.of(context),
                              split.fixedShare,
                            )
                          : null,
                      _fixedColor.of(c),
                    ),
                  ),
                if (split.variable > 0)
                  Expanded(
                    flex: math.max(1, ((1 - fixedFrac) * 10000).round()),
                    child: cell(
                      1 - fixedFrac >= 0.14
                          ? _share(
                              AppLocalizations.of(context),
                              split.variableShare,
                            )
                          : null,
                      _variableColor.of(c),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 월별 누적 막대 ──────────────────────────────────────────

class _MonthRow {
  const _MonthRow(this.label, this.fixed, this.variable);
  final String label;
  final int fixed;
  final int variable;
  int get total => fixed + variable;
}

List<_MonthRow> _toRows(
  List<({int year, int month, int total, int fixed})> src,
) {
  final labels = monthLabels([
    for (final r in src) (year: r.year, month: r.month),
  ]);
  return [
    for (final (i, r) in src.indexed)
      () {
        final s = splitFixed(r.total, r.fixed);
        return _MonthRow(labels[i], s.fixed, s.variable);
      }(),
  ];
}

class _MonthlyStack extends ConsumerStatefulWidget {
  const _MonthlyStack({required this.summary, required this.masked});

  /// null 이면 첫 불러오기.
  final RangeSummary? summary;
  final bool masked;

  @override
  ConsumerState<_MonthlyStack> createState() => _MonthlyStackState();
}

class _MonthlyStackState extends ConsumerState<_MonthlyStack> {
  _Kind _kind = _Kind.expense;
  Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final masked = widget.masked;
    final s = widget.summary;
    final segmented = PSegmentedControl<_Kind>(
      value: _kind,
      semanticLabel: l.statsFixedTrendKindAria,
      onChanged: (v) => setState(() => _kind = v),
      items: [
        PSegmentedItem(value: _Kind.expense, label: l.statsFixedKindExpense),
        PSegmentedItem(value: _Kind.income, label: l.statsFixedKindIncome),
      ],
    );
    // 머리 오른쪽(지시서 38) — 트랙은 놓인 자리 폭을 채우므로 자리에 폭을 준다. 모자라면 머리 줄이 제목 아래 오른쪽 끝으로 내린다
    final head = BudgetHead(
      title: l.statsFixedTrendTitle,
      trailing: SizedBox(
        width: statsSegmentedWidth([
          l.statsFixedKindExpense,
          l.statsFixedKindIncome,
        ]),
        child: segmented,
      ),
    );
    if (s == null) {
      return statsSection(
        header: head,
        children: [const StatsChartSkeleton(height: 200)],
      );
    }
    // 한 달만 고른 기간이면 막대가 하나뿐이라 의미가 없다 — 그때는 최근 6개월을 보여 준다
    final useRange = s.monthlyBuckets.length >= 2;
    final trendAsync = useRange ? null : ref.watch(monthlyTrendProvider(6));
    final isExpense = _kind == _Kind.expense;
    if (trendAsync != null && trendAsync.hasError && trendAsync.value == null) {
      return statsFailureSection(
        header: head,
        title: l.statsLoadFailedFixed,
        retrying: trendAsync.isLoading,
        onRetry: () => ref.invalidate(monthlyTrendProvider(6)),
      );
    }
    final loading =
        trendAsync != null && trendAsync.isLoading && !trendAsync.hasValue;
    final rows = useRange
        ? _toRows([
            for (final b in s.monthlyBuckets)
              (
                year: b.year,
                month: b.month,
                total: isExpense ? b.totalExpense : b.totalIncome,
                fixed: isExpense ? b.fixedExpense : b.fixedIncome,
              ),
          ])
        : _toRows([
            for (final m in trendAsync?.value ?? const <MonthlyTrend>[])
              (
                year: m.year,
                month: m.month,
                total: isExpense ? m.totalExpense : m.totalIncome,
                fixed: isExpense ? m.fixedExpense : m.fixedIncome,
              ),
          ]);
    if (loading) {
      return statsSection(
        header: head,
        children: [const StatsChartSkeleton(height: 200)],
      );
    }
    if (!rows.any((r) => r.total > 0)) {
      return statsSection(
        header: head,
        children: [BudgetEmptyLine(l.statsNoTrendData)],
      );
    }
    final sumFixed = rows.fold<int>(0, (a, r) => a + r.fixed);
    final sumVariable = rows.fold<int>(0, (a, r) => a + r.variable);
    String money(int v) => statsWon(v, masked);
    final kindName = isExpense
        ? l.statsFixedKindExpense
        : l.statsFixedKindIncome;
    final name = l.statsChartFixedName(kindName);
    return statsSection(
      header: head,
      children: [
        if (!useRange) ...[
          BudgetDesc(l.statsFixedTrendRecent),
          const SizedBox(height: PSpacing.x2),
        ],
        PChartLegendTiles(
          items: [
            PChartLegendItem(
              key: 'fixed',
              label: l.statsFixedLegendFixed,
              color: _fixedColor,
              total: money(sumFixed),
            ),
            PChartLegendItem(
              key: 'variable',
              label: l.statsFixedLegendVariable,
              color: _variableColor,
              total: money(sumVariable),
            ),
          ],
          hidden: _hidden,
          onHiddenChanged: (h) => setState(() => _hidden = h),
        ),
        const SizedBox(height: PSpacing.x2),
        PBarChart(
          label: name,
          height: 200,
          stacked: true,
          hidden: _hidden,
          categories: [for (final r in rows) r.label],
          series: [
            PChartSeries(
              key: 'fixed',
              label: l.statsFixedLegendFixed,
              color: _fixedColor,
              values: [for (final r in rows) r.fixed.toDouble()],
            ),
            PChartSeries(
              key: 'variable',
              label: l.statsFixedLegendVariable,
              color: _variableColor,
              values: [for (final r in rows) r.variable.toDouble()],
            ),
          ],
          axisFormatter: maskFormatter(masked),
          valueFormatter: maskFormatter(masked),
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.statsTableMonth),
            PChartDataColumn(l.statsFixedLegendFixed),
            PChartDataColumn(l.statsFixedLegendVariable),
          ],
          rows: [
            for (final r in rows) [r.label, money(r.fixed), money(r.variable)],
          ],
        ),
      ],
    );
  }
}

// ─── 카테고리별 고정/변동 ─────────────────────────────────────

class _CategoryRow {
  _CategoryRow({required this.key, required this.name});
  final String key;
  final String name;
  int total = 0;
  int fixed = 0;
}

/// 지출 카테고리를 부모 단위로 묶어 고정·변동 몫을 합친다 — 도넛과 같은 묶음 규칙.
List<_CategoryRow> _categoryRows(
  List<CategoryBreakdown> breakdown,
  Map<int, ExpenseCategory> byId,
  String uncategorized,
) {
  final map = <String, _CategoryRow>{};
  for (final c in breakdown) {
    if (c.expenseType != 'EXPENSE') continue;
    final groupId = c.parentCategoryRowId ?? c.categoryRowId;
    final key = groupId == null ? 'none' : '$groupId';
    final row = map.putIfAbsent(
      key,
      () => _CategoryRow(
        key: key,
        name:
            c.parentCategoryName ??
            c.categoryName ??
            (groupId == null ? null : byId[groupId]?.categoryName) ??
            uncategorized,
      ),
    );
    final s = splitFixed(c.totalAmount, c.fixedAmount);
    row.total += s.total;
    row.fixed += s.fixed;
  }
  return map.values.where((r) => r.total > 0).toList()
    ..sort((a, b) => b.total.compareTo(a.total));
}

const _kCategoryLimit = 8;

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({
    required this.rows,
    required this.masked,
    required this.onManage,
  });

  final List<_CategoryRow> rows;
  final bool masked;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final shown = rows.take(_kCategoryLimit).toList();
    final max = math.max(1, shown.map((r) => r.total).fold<int>(1, math.max));
    return statsSection(
      header: BudgetHead(title: l.statsFixedCategoryTitle),
      children: [
        for (final (i, r) in shown.indexed) ...[
          if (i > 0) const SizedBox(height: PSpacing.x4),
          Builder(
            builder: (context) {
              final s = splitFixed(r.total, r.fixed);
              final w = s.total / max;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatsNameAmount(
                    name: r.name,
                    amount: statsWon(s.total, masked),
                    nameStyle: PTypography.t4.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                    amountStyle: PTypography.t4,
                  ),
                  const SizedBox(height: PSpacing.x1_5),
                  // 장식 막대 — 값은 옆 금액이 말한다
                  StatsDecoBar(
                    segments: [
                      (
                        ratio: s.total == 0 ? 0 : w * (s.fixed / s.total),
                        color: _fixedColor.of(c),
                      ),
                      (
                        ratio: s.total == 0 ? 0 : w * (s.variable / s.total),
                        color: _variableColor.of(c),
                      ),
                    ],
                  ),
                  if (s.fixed > 0) ...[
                    const SizedBox(height: PSpacing.x1),
                    Text(
                      keepAll(
                        l.statsFixedCategoryFixedPart(_share(l, s.fixedShare)),
                      ),
                      style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
        const SizedBox(height: PSpacing.x5),
        // 바닥 버튼 영역 — 위 끝까지 선 1px
        BudgetFull(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.strokeNeutralSubtle)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                PSpacing.x4,
                PSpacing.x6,
                0,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: PSpacing.x3,
                runSpacing: PSpacing.x3,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: PSpacing.x1_5,
                    children: [
                      Icon(LucideIcons.pin, size: 16, color: c.fgNeutralSubtle),
                      Flexible(
                        child: Text(
                          keepAll(l.statsFixedManageHint),
                          style: PTypography.t3.copyWith(
                            color: c.fgNeutralSubtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  PButton(
                    label: l.statsFixedManage,
                    variant: PButtonVariant.neutralOutline,
                    size: PButtonSize.small,
                    onPressed: onManage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
