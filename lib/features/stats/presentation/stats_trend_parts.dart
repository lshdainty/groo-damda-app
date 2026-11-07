import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

// 통계 · 추이 탭 구역(I-08 36) — 수입 · 지출 추이(ds 선 이중 축 + 지표 타일) · 저축률(고리 게이지는 화면 그림) · 월별 순저축(ds 막대, 음수 포함) ·
// 주요 카테고리 월별 추이(ds 쌓은 막대). 차트마다 이름 + 표로 보기(42).

/// 수입 · 지출 추이 — 지표 타일(켜고 끄기) + 선(영역) 이중 축.
class StatsTrendSection extends StatefulWidget {
  const StatsTrendSection({
    super.key,
    required this.period,
    required this.onPickPeriod,
    required this.points,
    required this.daily,
    required this.masked,
  });

  final StatsPeriod period;
  final VoidCallback onPickPeriod;

  /// null 이면 첫 불러오기.
  final List<TrendPoint>? points;

  /// 점이 일별인가(표로 보기 머리 "날짜" · "월").
  final bool daily;
  final bool masked;

  @override
  State<StatsTrendSection> createState() => _StatsTrendSectionState();
}

class _StatsTrendSectionState extends State<StatsTrendSection> {
  Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final masked = widget.masked;
    final head = BudgetHead(
      title: l.statsIncomeExpenseTrend,
      trailing: StatsPeriodButton(
        period: widget.period,
        onPressed: widget.onPickPeriod,
      ),
    );
    final data = widget.points;
    if (data == null) {
      return statsSection(
        header: head,
        children: [
          loadingRegionWithText(const StatsChartSkeleton(height: 200)),
        ],
      );
    }
    if (data.isEmpty || data.every((p) => p.income == 0 && p.expense == 0)) {
      return statsSection(
        header: head,
        children: [BudgetEmptyLine(l.statsNoTrendData)],
      );
    }
    final sumIn = data.fold<int>(0, (s, d) => s + d.income);
    final sumOut = data.fold<int>(0, (s, d) => s + d.expense);
    String money(int v) => statsWon(v, masked);
    final name = l.statsChartTrendName(
      widget.period.label(),
      money(sumIn),
      money(sumOut),
    );
    return statsSection(
      header: head,
      children: [
        PChartLegendTiles(
          items: [
            PChartLegendItem(
              key: 'income',
              label: l.expTypeIncome,
              color: PChartColor.blue,
              total: money(sumIn),
            ),
            PChartLegendItem(
              key: 'expense',
              label: l.expTypeExpense,
              color: PChartColor.red,
              total: money(sumOut),
            ),
          ],
          hidden: _hidden,
          onHiddenChanged: (h) => setState(() => _hidden = h),
        ),
        const SizedBox(height: PSpacing.x2),
        PLineChart(
          label: name,
          height: 200,
          hidden: _hidden,
          categories: [for (final d in data) d.label],
          series: [
            PChartSeries(
              key: 'income',
              label: l.expTypeIncome,
              color: PChartColor.blue,
              values: [for (final d in data) d.income.toDouble()],
            ),
            PChartSeries(
              key: 'expense',
              label: l.expTypeExpense,
              color: PChartColor.red,
              onRight: true,
              values: [for (final d in data) d.expense.toDouble()],
            ),
          ],
          axisFormatter: maskFormatter(masked),
          valueFormatter: maskFormatter(masked),
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(
              widget.daily ? l.statsTableDate : l.statsTableMonth,
            ),
            PChartDataColumn(l.expTypeIncome),
            PChartDataColumn(l.expTypeExpense),
          ],
          rows: [
            for (final d in data) [d.label, money(d.income), money(d.expense)],
          ],
        ),
      ],
    );
  }
}

// ── 저축률 ──────────────────────────────────────────────────────

/// 저축률 — 머리 없는 구역. 고리 게이지 108 은 화면 그림(스펙 부품 없음)이라 모양 그대로, 글은 역할 이름(눈금 t2 · 값 t9 · 문장 t5).
/// 지출 · 저축 비율 막대는 장식 막대(8 · 끝 둥글게 · 값은 글이 말한다).
class StatsSavingsRateSection extends StatelessWidget {
  const StatsSavingsRateSection({
    super.key,
    required this.period,
    required this.buckets,
    required this.masked,
  });

  final StatsPeriod period;

  /// null 이면 첫 불러오기.
  final List<RangeMonthlyBucket>? buckets;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final list = buckets;
    if (list == null) {
      return statsSection(
        children: [
          Row(
            spacing: PSpacing.x4,
            children: [
              const PSkeleton(
                width: 108,
                height: 108,
                radius: PSkeletonRadius.full,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSkeleton.text(PTypography.t5, width: 140),
                    const SizedBox(height: PSpacing.x3),
                    const PSkeleton(
                      width: double.infinity,
                      height: PSpacing.x2,
                      radius: PSkeletonRadius.full,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
    final sumIn = list.fold<int>(0, (s, b) => s + b.totalIncome);
    final sumOut = list.fold<int>(0, (s, b) => s + b.totalExpense);
    final n = list.isEmpty ? 1 : list.length;
    final avgIn = sumIn ~/ n;
    final avgOut = sumOut ~/ n;
    final avgSave = avgIn - avgOut;
    final single = period.seg == StatsSeg.month;
    final saveRate = avgIn > 0
        ? (avgSave / avgIn * 100).clamp(0.0, 100.0)
        : 0.0;
    final spendRate = avgIn > 0
        ? (avgOut / avgIn * 100).clamp(0.0, 100.0)
        : 0.0;
    final rows = <({String name, int value, Color dot})>[
      (
        name: single ? l.expTypeIncome : l.statsAvgIncome,
        value: avgIn,
        dot: c.fgNeutralSubtle,
      ),
      (
        name:
            '${single ? l.expTypeExpense : l.statsAvgExpense} ${spendRate.round()}%',
        value: avgOut,
        dot: c.fgCritical,
      ),
      (
        name:
            '${single ? l.statsNetSavings : l.statsAvgSavings} ${saveRate.round()}%',
        value: avgSave,
        dot: c.fgBrand,
      ),
    ];
    final insight = Text(
      keepAll(l.statsSavingsInsight(saveRate.round())),
      style: PTypography.t5.copyWith(
        color: c.fgNeutral,
        fontWeight: FontWeight.w700,
      ),
    );
    return statsSection(
      children: [
        // 고리 크기 = 글자 배율 × 108 — 크게 보면 고리도 같이 커져 가운데 글이 안쪽에 든다(사용자 결정 10-25). 고리가 커서
        // 문장 자리가 모자라면 문장을 고리 아래로 내린다
        LayoutBuilder(
          builder: (context, constraints) {
            final ring = StatsSavingsRing(rate: saveRate);
            final size = savingsRingSize(context);
            // 문장 칸 = 띠 폭 − 고리 − 간격. 글자 크기 기준 8em(= t5 16 × 배율 × 8)보다 좁으면 낱말이 칸보다 길어져 낱말 가운데서
            // 꺾이므로(v114 단어 단위) 문장을 고리 아래로 내린다 — 100% 360 은 188 이라 옆에 선다
            final em = MediaQuery.textScalerOf(
              context,
            ).scale(PTypography.t5.fontSize!);
            final sentenceWidth = constraints.maxWidth - size - PSpacing.x4;
            if (sentenceWidth < kSavingsSentenceMinEm * em) {
              return Column(
                spacing: PSpacing.x4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: ring),
                  insight,
                ],
              );
            }
            return Row(
              spacing: PSpacing.x4,
              children: [
                ring,
                Expanded(child: insight),
              ],
            );
          },
        ),
        const SizedBox(height: PSpacing.x5),
        // 장식 막대 — 값은 아래 글이 말한다
        ExcludeSemantics(
          child: SizedBox(
            height: PSpacing.x2,
            child: Row(
              spacing: PSpacing.x0_5,
              children: [
                if (spendRate > 0)
                  Expanded(
                    flex: math.max(1, (spendRate * 100).round()),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.fgCritical,
                        borderRadius: BorderRadius.circular(PRounded.full),
                      ),
                    ),
                  ),
                if (saveRate > 0)
                  Expanded(
                    flex: math.max(1, (saveRate * 100).round()),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.fgBrand,
                        borderRadius: BorderRadius.circular(PRounded.full),
                      ),
                    ),
                  ),
                if (spendRate <= 0 && saveRate <= 0) const Spacer(),
              ],
            ),
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: PSpacing.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: PSpacing.x2,
                      height: PSpacing.x2,
                      decoration: BoxDecoration(
                        color: r.dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: PSpacing.x2),
                    Flexible(
                      child: Text(
                        keepAll(r.name),
                        style: PTypography.t5.copyWith(color: c.fgNeutral),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PSpacing.x3),
              Flexible(
                child: Text(
                  keepAllAmount(statsWon(r.value, masked)),
                  semanticsLabel: statsWon(r.value, masked),
                  textAlign: TextAlign.end,
                  style: PTypography.t5.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 저축률 고리 한 변 — 글자 배율 × 108(100% 108 · 200% 216).
double savingsRingSize(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(kSavingsRingBase);

const double kSavingsRingBase = 108;

/// 고리 옆 문장 칸의 최소 폭(글자 크기 em) — 이보다 좁으면 문장을 고리 아래로 내린다.
const double kSavingsSentenceMinEm = 8;

/// 저축률 고리 + 가운데 글(라벨 t2 · 값 t9 700, 정수 "100%"). 고리의 선 두께 · 반지름도 같은 비율로 커진다.
class StatsSavingsRing extends StatelessWidget {
  const StatsSavingsRing({super.key, required this.rate});

  /// 0 ~ 100
  final double rate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final size = savingsRingSize(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: SavingsRingPainter(
              rate: rate,
              track: c.bgNeutralWeak,
              progress: c.fgBrand,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.statsSavingsRate,
                style: PTypography.t2.copyWith(
                  color: c.fgNeutralSubtle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${rate.round()}%',
                key: const ValueKey('savings-ring-value'),
                style: PTypography.t9.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                  fontFeatures: tabularFigures,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 저축률 고리 — 트랙 전체 원 + 진행 호(맨 위에서 시작 · 끝 둥글게).
class SavingsRingPainter extends CustomPainter {
  SavingsRingPainter({
    required this.rate,
    required this.track,
    required this.progress,
  });

  final double rate; // 0 ~ 100
  final Color track;
  final Color progress;

  @override
  void paint(Canvas canvas, Size size) {
    // 그림 108 기준 값을 크기 비율로 키운다
    final k = size.width / kSavingsRingBase;
    final stroke = 10.0 * k;
    final r = 48.0 * k;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (rate > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        (rate / 100) * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = progress,
      );
    }
  }

  @override
  bool shouldRepaint(SavingsRingPainter old) =>
      old.rate != rate || old.track != track || old.progress != progress;
}

// ── 월별(일별) 순저축 ────────────────────────────────────────────

/// 월별 · 일별 순저축 — ds 막대(음수는 아래로 · 빨강).
class StatsSavingsBarsSection extends StatelessWidget {
  const StatsSavingsBarsSection({
    super.key,
    required this.period,
    required this.points,
    required this.daily,
    required this.masked,
  });

  final StatsPeriod period;

  /// null 이면 첫 불러오기.
  final List<TrendPoint>? points;
  final bool daily;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = daily ? l.statsDailyNetSavings : l.statsMonthlyNetSavings;
    final head = BudgetHead(title: title, note: l.statsIncomeMinusExpense);
    final data = points;
    if (data == null) {
      return statsSection(
        header: head,
        children: [
          loadingRegionWithText(const StatsChartSkeleton(height: 180)),
        ],
      );
    }
    if (data.isEmpty) {
      return statsSection(
        header: head,
        children: [BudgetEmptyLine(l.statsNoMonthlyData)],
      );
    }
    String signed(double v) {
      final n = v.round();
      final text = statsWon(n.abs(), false);
      return n > 0 ? '+$text' : (n < 0 ? '$kChartMinus$text' : text);
    }

    String shown(double v) => masked ? kBudgetMask : signed(v);
    final name = l.statsChartSavingsName(period.label(), title);
    return statsSection(
      header: head,
      children: [
        PBarChart(
          label: name,
          height: 180,
          categories: [for (final d in data) d.label],
          series: [
            PChartSeries(
              key: 'savings',
              label: l.statsNetSavings,
              color: PChartColor.blue,
              values: [for (final d in data) d.savings.toDouble()],
            ),
          ],
          barColor: (i, colors) =>
              data[i].savings < 0 ? colors.chartRed : colors.chartBlue,
          axisFormatter: maskFormatter(masked),
          valueFormatter: shown,
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(daily ? l.statsTableDate : l.statsTableMonth),
            PChartDataColumn(l.statsNetSavings),
          ],
          rows: [
            for (final d in data) [d.label, shown(d.savings.toDouble())],
          ],
        ),
      ],
    );
  }
}

// ── 주요 카테고리 월별 추이 ──────────────────────────────────────

/// 주요 카테고리(지출 TOP 3) 월별 추이 — ds 쌓은 막대.
class StatsCatTrendSection extends StatelessWidget {
  const StatsCatTrendSection({
    super.key,
    required this.period,
    required this.summary,
    required this.categories,
    required this.masked,
  });

  final StatsPeriod period;

  /// null 이면 첫 불러오기.
  final RangeSummary? summary;
  final List<ExpenseCategory>? categories;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final head = BudgetHead(
      title: l.statsCatTrendTitle,
      note: l.statsCatTrendTop3,
    );
    final s = summary;
    if (s == null) {
      return statsSection(
        header: head,
        children: [
          loadingRegionWithText(const StatsChartSkeleton(height: 180)),
        ],
      );
    }
    final top =
        (s.categoryBreakdown.where((b) => b.expenseType == 'EXPENSE').toList()
              ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)))
            .take(3)
            .toList();
    final buckets = s.monthlyBuckets;
    int partOf(RangeMonthlyBucket b, CategoryBreakdown t) => b.categoryExpenses
        .firstWhere(
          (ce) => ce.categoryRowId == t.categoryRowId,
          orElse: () => const CategoryAmount(),
        )
        .amount;
    final maxSum = buckets.fold<int>(
      0,
      (m, b) => math.max(m, top.fold<int>(0, (a, t) => a + partOf(b, t))),
    );
    if (top.isEmpty || maxSum <= 0) {
      return statsSection(
        header: head,
        children: [BudgetEmptyLine(l.statsNoData)],
      );
    }
    final byId = catIndex(categories);
    final colored = assignChartColors<CategoryBreakdown>(
      top,
      colorOf: (t) => savedChartColor(byId[t.categoryRowId]?.color),
    );
    final labels = monthLabels([
      for (final b in buckets) (year: b.year, month: b.month),
    ]);
    String money(int v) => statsWon(v, masked);
    final name = l.statsChartCatTrendName(period.label());
    final names = [
      for (final t in colored) t.item.categoryName ?? l.statsUnassigned,
    ];
    return statsSection(
      header: head,
      children: [
        Wrap(
          spacing: PSpacing.x3,
          runSpacing: PSpacing.x1,
          children: [
            for (final (i, t) in colored.indexed)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: PSpacing.x1_5,
                children: [
                  Container(
                    width: PSpacing.x2,
                    height: PSpacing.x2,
                    decoration: BoxDecoration(
                      color: t.color.of(c),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      keepAll(names[i]),
                      style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: PSpacing.x2),
        PBarChart(
          label: name,
          height: 180,
          stacked: true,
          categories: labels,
          series: [
            for (final (i, t) in colored.indexed)
              PChartSeries(
                key: 'c$i',
                label: names[i],
                color: t.color,
                values: [for (final b in buckets) partOf(b, t.item).toDouble()],
              ),
          ],
          axisFormatter: maskFormatter(masked),
          valueFormatter: maskFormatter(masked),
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.statsTableMonth),
            for (final n in names) PChartDataColumn(n),
          ],
          rows: [
            for (final (bi, b) in buckets.indexed)
              [labels[bi], for (final t in colored) money(partOf(b, t.item))],
          ],
        ),
      ],
    );
  }
}
