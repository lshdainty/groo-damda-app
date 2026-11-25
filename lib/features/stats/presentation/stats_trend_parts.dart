import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart'
    show kPListStackBelowEm;
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
    this.xTickPeers = const [],
  });

  final StatsPeriod period;
  final VoidCallback onPickPeriod;

  /// 같은 화면 · 같은 기간 · 같은 눈금 단위의 다른 차트([statsTrendPeers]) — 가로 눈금 건너뛰기를 함께 센다.
  final List<PCartesianChart> xTickPeers;

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
    if (!_trendChartShown(data)) {
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
        _trendChart(
          l,
          data,
          masked: masked,
          label: name,
          hidden: _hidden,
          xTickPeers: widget.xTickPeers,
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

/// 수입 · 지출 추이 선을 그리는가 — 점이 없거나 수입 · 지출이 모두 0 이면 빈 줄이다.
bool _trendChartShown(List<TrendPoint> data) =>
    data.any((p) => p.income != 0 || p.expense != 0);

/// 통계 › 추이 한 화면의 가로 눈금 묶음 — 보이는 차트마다 폭만 재는 짝(그리지 않으므로 이름은 비운다). 없는 차트는 null.
typedef StatsTrendPeers = ({
  PLineChart? trend,
  PBarChart? savings,
  PBarChart? catTrend,
});

/// 같은 기간 · 같은 눈금 단위(날 · 달) 차트는 화면에 보이는 것을 모두 한 묶음으로, 그리는 자리가 가장 좁은 차트로 가로 눈금
/// 건너뛰기를 한 번 센다(chart.md "같은 화면 · 같은 기간 차트는 같은 날짜 글", groo-design #247 · #248). 수입 · 지출 추이와 순저축은
/// 같은 점([points] — 실패 · 불러오는 중이면 null)을 먹고, 주요 카테고리 월별 추이([catSummary] — 띠가 없으면 null)는 달 눈금이라
/// 추이가 월별일 때만 묶는다(날별 대 월별은 묶지 않는다). 세 차트는 같은 폭 띠에 놓여 서로를 [PCartesianChart.xTickPeers] 로 넘긴다
/// — [StatsTrendPeers.others] 로 자기를 뺀 짝을 고른다.
StatsTrendPeers statsTrendPeers(
  AppLocalizations l, {
  required List<TrendPoint>? points,
  required bool daily,
  required RangeSummary? catSummary,
  required List<ExpenseCategory>? categories,
  required bool masked,
  DateTime? today,
}) {
  final cat = catSummary == null || daily
      ? null
      : _catTrendOf(l, catSummary, categories, today: today);
  return (
    trend: points != null && _trendChartShown(points)
        ? _trendChart(l, points, masked: masked)
        : null,
    savings: points != null && points.isNotEmpty
        ? _savingsChart(l, points, masked: masked)
        : null,
    catTrend: cat == null ? null : _catTrendChart(cat, masked: masked),
  );
}

/// [StatsTrendPeers] 에서 자기를 뺀 짝.
extension StatsTrendPeersOthers on StatsTrendPeers {
  List<PCartesianChart> others({
    bool trend = true,
    bool savings = true,
    bool catTrend = true,
  }) => [
    if (trend) ?this.trend,
    if (savings) ?this.savings,
    if (catTrend) ?this.catTrend,
  ];
}

/// 수입 · 지출 추이 — 선(영역) 이중 축(왼쪽 수입 · 오른쪽 지출).
PLineChart _trendChart(
  AppLocalizations l,
  List<TrendPoint> data, {
  required bool masked,
  String label = '',
  Set<String> hidden = const {},
  List<PCartesianChart> xTickPeers = const [],
}) => PLineChart(
  label: label,
  height: 200,
  hidden: hidden,
  dots: trendNeedsDots(data, hidden),
  categories: [for (final d in data) d.label],
  xTicks: trendXTicks(data),
  xTickPeers: xTickPeers,
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
);

/// 월별 · 일별 순저축 — 막대(음수는 아래로 · 빨강).
PBarChart _savingsChart(
  AppLocalizations l,
  List<TrendPoint> data, {
  required bool masked,
  String label = '',
  List<PCartesianChart> xTickPeers = const [],
}) => PBarChart(
  label: label,
  height: 180,
  categories: [for (final d in data) d.label],
  xTicks: trendXTicks(data),
  xTickPeers: xTickPeers,
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
  valueFormatter: (v) => _savingsText(v, masked),
);

/// 순저축 글 — 부호를 붙인 원까지("+12,000원" · "−3,000원"), 가리면 가림 글.
String _savingsText(double v, bool masked) {
  if (masked) return kHideMask;
  final n = v.round();
  final text = statsWon(n.abs(), false);
  return n > 0 ? '+$text' : (n < 0 ? '$kChartMinus$text' : text);
}

/// 0 이 대부분인 날마다의 합 — 켠 계열에서 값(0 이 아닌 점)이 있는 날이 [kTrendDotsMaxValues] 개 이하이면 늘 찍는 점(`dots`)을
/// 켠다(chart.md "늘 찍는 점"). 곡선(monotone)이 하루 값을 앞뒤 날까지 산 모양으로 이어 그려 그 사이에도 쓴 것처럼 보이므로,
/// 점이 실제로 값이 있는 날을 짚어 준다. 선 모양은 그대로 곡선이다.
bool trendNeedsDots(List<TrendPoint> data, Set<String> hidden) {
  final showIn = !hidden.contains('income');
  final showOut = !hidden.contains('expense');
  final valued = data
      .where((d) => (showIn && d.income != 0) || (showOut && d.expense != 0))
      .length;
  return valued > 0 && valued <= kTrendDotsMaxValues;
}

/// 늘 찍는 점을 켜는 값 개수의 문턱(이하) — chart.md "늘 찍는 점".
const int kTrendDotsMaxValues = 7;

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
    // 수입이 없으면 비율을 낼 수 없다 — 0 으로 나누지 않고 비율 자리를 모두 "—" 로 둔다(0% 로 꾸며 말하지 않는다)
    final rates = savingsRates(avgIn: avgIn, avgOut: avgOut);
    final saveRate = rates?.save;
    final spendRate = rates?.spend;
    String pct(double? v) => v == null ? kNoRate : formatProgress(v);
    final rows = <({String name, int value, Color dot})>[
      (
        name: single ? l.expTypeIncome : l.statsAvgIncome,
        value: avgIn,
        dot: c.fgNeutralSubtle,
      ),
      (
        name:
            '${single ? l.expTypeExpense : l.statsAvgExpense} ${pct(spendRate)}',
        value: avgOut,
        dot: c.fgCritical,
      ),
      (
        name:
            '${single ? l.statsNetSavings : l.statsAvgSavings} ${pct(saveRate)}',
        value: avgSave,
        dot: c.fgBrand,
      ),
    ];
    final insight = Text(
      keepAll(
        saveRate == null
            ? l.statsSavingsNoIncome
            : l.statsSavingsInsight(formatProgress(saveRate)),
      ),
      key: const ValueKey('savings-insight'),
      style: PTypography.t5.copyWith(
        color: c.fgNeutral,
        fontWeight: FontWeight.w700,
      ),
    );
    return statsSection(
      children: [
        // 고리는 모양(디자인 틀)이라 108 그대로이고 안의 글도 커지지 않는다(DESIGN.md Typography "그대로 두는 것",
        // groo-design #260) — 같은 저축률은 옆 문장 · 아래 범례에서 크게 읽는다. 문장이 커져 옆 자리가 모자라면 고리 아래로 내린다
        LayoutBuilder(
          builder: (context, constraints) {
            final ring = StatsSavingsRing(rate: saveRate);
            const size = kSavingsRingSize;
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
                if (spendRate != null && spendRate > 0)
                  Expanded(
                    flex: math.max(1, (spendRate * 100).round()),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.fgCritical,
                        borderRadius: BorderRadius.circular(PRounded.full),
                      ),
                    ),
                  ),
                if (saveRate != null && saveRate > 0)
                  Expanded(
                    flex: math.max(1, (saveRate * 100).round()),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.fgBrand,
                        borderRadius: BorderRadius.circular(PRounded.full),
                      ),
                    ),
                  ),
                if ((spendRate ?? 0) <= 0 && (saveRate ?? 0) <= 0)
                  const Spacer(),
              ],
            ),
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: PSpacing.x2),
          StatsSavingsLegendRow(
            name: r.name,
            amount: statsWon(r.value, masked),
            dot: r.dot,
          ),
        ],
      ],
    );
  }
}

/// 비율 자리에 낼 값이 없을 때(수입 0) — 퍼센트 규칙의 "숫자가 아니면 —" 와 같은 글자.
const String kNoRate = '—';

/// 저축률 · 지출 비율(0 ~ 100). 평균 수입이 0 이하면 낼 수 없어 null — 0 으로 나누지 않고, NaN · 무한이 화면에 나가지 않는다.
({double save, double spend})? savingsRates({
  required int avgIn,
  required int avgOut,
}) {
  if (avgIn <= 0) return null;
  return (
    save: ((avgIn - avgOut) / avgIn * 100).clamp(0.0, 100.0),
    spend: (avgOut / avgIn * 100).clamp(0.0, 100.0),
  );
}

/// 저축률 범례 줄 — 점 8 + 이름(t5) · 금액(t5 700, 줄 끝). 도넛 범례 줄([PChartDonutLegend])과 같은 배치다 — 이름이 남은 폭을
/// 먹고 금액은 줄 오른쪽 끝에 붙는다. 줄 안 폭이 글자 16개(16em)보다 좁으면(큰 글자) 이름이 한 글자 폭이 되지 않게 금액을
/// 이름 아래로 내린다(같은 문턱 [kPListStackBelowEm]).
class StatsSavingsLegendRow extends StatelessWidget {
  const StatsSavingsLegendRow({
    super.key,
    required this.name,
    required this.amount,
    required this.dot,
  });

  final String name;

  /// 원까지 — "−29,430원".
  final String amount;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final marker = Container(
      width: PSpacing.x2,
      height: PSpacing.x2,
      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
    );
    final label = Text(
      keepAll(name),
      style: PTypography.t5.copyWith(color: c.fgNeutral),
    );
    final value = Text(
      keepAllAmount(amount),
      key: const ValueKey('savings-legend-amount'),
      semanticsLabel: amount,
      textAlign: TextAlign.end,
      style: PTypography.t5.copyWith(
        color: c.fgNeutral,
        fontWeight: FontWeight.w700,
        fontFeatures: tabularFigures,
      ),
    );
    final narrowBelow =
        kPListStackBelowEm *
        MediaQuery.textScalerOf(context).scale(PTypography.t5.fontSize!);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < narrowBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: PSpacing.x2,
                children: [
                  marker,
                  Flexible(child: label),
                ],
              ),
              value,
            ],
          );
        }
        return Row(
          children: [
            marker,
            const SizedBox(width: PSpacing.x2),
            Expanded(child: label),
            const SizedBox(width: PSpacing.x3),
            value,
          ],
        );
      },
    );
  }
}

/// 저축률 고리 한 변 — 108 고정(글자 크기 설정을 따르지 않는다, groo-design #260).
const double kSavingsRingSize = 108;

/// 고리 옆 문장 칸의 최소 폭(글자 크기 em) — 이보다 좁으면 문장을 고리 아래로 내린다.
const double kSavingsSentenceMinEm = 8;

/// 저축률 고리 108 + 가운데 글(라벨 t2 · 값 t9 700, 정수 "100%"). 고리 · 안의 글은 글자 크기 설정을 따르지 않는다 — 고리
/// 모양의 일부라서다(DESIGN.md Typography "그대로 두는 것", groo-design #260). 같은 값은 고리 옆 문장 · 범례에서 크게 읽는다.
class StatsSavingsRing extends StatelessWidget {
  const StatsSavingsRing({super.key, required this.rate});

  /// 0 ~ 100. null 이면 낼 수 없는 값(수입 0) — 가운데 "—" · 호 없음.
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    const size = kSavingsRingSize;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: SavingsRingPainter(
              rate: rate ?? 0,
              track: c.bgNeutralWeak,
              progress: c.fgBrand,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.statsSavingsRate,
                textScaler: TextScaler.noScaling,
                style: PTypography.t2.copyWith(
                  color: c.fgNeutralSubtle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                rate == null ? kNoRate : formatProgress(rate!),
                key: const ValueKey('savings-ring-value'),
                textScaler: TextScaler.noScaling,
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
    // 그림 108 기준 값을 크기 비율로 맞춘다(고리는 108 고정이라 늘 1 — 견본이 다른 크기로 그려도 비율이 맞는다)
    final k = size.width / kSavingsRingSize;
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
    this.xTickPeers = const [],
  });

  final StatsPeriod period;

  /// null 이면 첫 불러오기.
  final List<TrendPoint>? points;
  final bool daily;
  final bool masked;

  /// 같은 화면 · 같은 기간 · 같은 눈금 단위의 다른 차트([statsTrendPeers]).
  final List<PCartesianChart> xTickPeers;

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
    String shown(double v) => _savingsText(v, masked);
    final name = l.statsChartSavingsName(period.label(), title);
    return statsSection(
      header: head,
      children: [
        _savingsChart(
          l,
          data,
          masked: masked,
          label: name,
          xTickPeers: xTickPeers,
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

/// 주요 카테고리 월별 추이의 값 — 지출 TOP 3 · 색 · 이번 달에서 자른 달.
typedef _CatTrend = ({
  List<PChartColored<CategoryBreakdown>> colored,
  List<String> names,
  List<RangeMonthlyBucket> buckets,
  List<({int year, int month})> months,
  List<String> labels,
});

int _catPart(RangeMonthlyBucket b, CategoryBreakdown t) => b.categoryExpenses
    .firstWhere(
      (ce) => ce.categoryRowId == t.categoryRowId,
      orElse: () => const CategoryAmount(),
    )
    .amount;

/// 지출 TOP 3 와 그 달별 금액. 그릴 것이 없으면(TOP 이 없거나 달마다 합이 0) null. 가로축은 이번 달에서 끝난다
/// ([bucketsToToday] — 수입 · 지출 추이와 같은 자르기).
_CatTrend? _catTrendOf(
  AppLocalizations l,
  RangeSummary s,
  List<ExpenseCategory>? categories, {
  DateTime? today,
}) {
  final top =
      (s.categoryBreakdown.where((b) => b.expenseType == 'EXPENSE').toList()
            ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)))
          .take(3)
          .toList();
  final buckets = bucketsToToday(s.monthlyBuckets, today: today);
  final maxSum = buckets.fold<int>(
    0,
    (m, b) => math.max(m, top.fold<int>(0, (a, t) => a + _catPart(b, t))),
  );
  if (top.isEmpty || maxSum <= 0) return null;
  final byId = catIndex(categories);
  final colored = assignChartColors<CategoryBreakdown>(
    top,
    colorOf: (t) => savedChartColor(byId[t.categoryRowId]?.color),
  );
  final months = [for (final b in buckets) (year: b.year, month: b.month)];
  return (
    colored: colored,
    names: [for (final t in colored) t.item.categoryName ?? l.statsUnassigned],
    buckets: buckets,
    months: months,
    labels: monthLabels(months),
  );
}

/// 주요 카테고리 월별 추이 — 쌓은 막대.
PBarChart _catTrendChart(
  _CatTrend t, {
  required bool masked,
  String label = '',
  List<PCartesianChart> xTickPeers = const [],
}) => PBarChart(
  label: label,
  height: 180,
  stacked: true,
  categories: t.labels,
  xTicks: monthAxisTicks(t.months),
  xTickPeers: xTickPeers,
  series: [
    for (final (i, c) in t.colored.indexed)
      PChartSeries(
        key: 'c$i',
        label: t.names[i],
        color: c.color,
        values: [for (final b in t.buckets) _catPart(b, c.item).toDouble()],
      ),
  ],
  axisFormatter: maskFormatter(masked),
  valueFormatter: maskFormatter(masked),
);

/// 주요 카테고리(지출 TOP 3) 월별 추이 — ds 쌓은 막대.
class StatsCatTrendSection extends StatelessWidget {
  const StatsCatTrendSection({
    super.key,
    required this.period,
    required this.summary,
    required this.categories,
    required this.masked,
    this.xTickPeers = const [],
    this.today,
  });

  final StatsPeriod period;

  /// null 이면 첫 불러오기.
  final RangeSummary? summary;
  final List<ExpenseCategory>? categories;
  final bool masked;

  /// 같은 화면 · 같은 기간 · 같은 눈금 단위의 다른 차트([statsTrendPeers]).
  final List<PCartesianChart> xTickPeers;

  /// 가로축이 끝나는 오늘 — 기본은 [statsNow].
  final DateTime? today;

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
    final t = _catTrendOf(l, s, categories, today: today);
    if (t == null) {
      return statsSection(
        header: head,
        children: [BudgetEmptyLine(l.statsNoData)],
      );
    }
    final colored = t.colored;
    final names = t.names;
    final labels = t.labels;
    String money(int v) => statsWon(v, masked);
    final name = l.statsChartCatTrendName(period.label());
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
        _catTrendChart(t, masked: masked, label: name, xTickPeers: xTickPeers),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.statsTableMonth),
            for (final n in names) PChartDataColumn(n),
          ],
          rows: [
            for (final (bi, b) in t.buckets.indexed)
              [labels[bi], for (final c in colored) money(_catPart(b, c.item))],
          ],
        ),
      ],
    );
  }
}
