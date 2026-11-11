import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/domain/fixed_split.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all_fit_text.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

// 통계 구역 부품 — 카테고리 탭(도넛 · TOP 5 · 열지도 · 요약)과 탭들이 함께 쓰는 것(I-08 29 ~ 35).
// 구역 틀은 예산과 같은 `budget_parts.dart`(띠 안 구역 사이 48 · 머리 위 24 · 머리 ↔ 본문 8)를 쓴다.
// 금액은 원까지, 가리면 점. 눈금 글자만 줄여 쓴다(`formatAxisWon` — ds 기본).

/// 등락 % 를 한 곳에서 만든다 — 크기만(방향은 옆 ▲ ▼ 가 말한다), 어디서나 소수 둘째 자리(`formatChangeRateAbs`, 사용자 결정 10-25).
String statsChangeRate(num now, num prev) =>
    prev == 0 ? '—' : formatChangeRateAbs((now - prev) / prev * 100);

/// 머리 오른쪽에 두는 Segmented 의 자리 폭 — (가장 긴 칸 글 + 좌우 24) × 칸 수 + 8. 칸 글은 글자 배율을 따르지 않으므로(t5 700,
/// 배율 고정) 폭도 배율과 무관하다. 웹은 `w-max` + `max-w-[50%]` 로 같은 규칙이고, 머리 줄은 제목이 50% 를 못 지키면 이 Segmented 를
/// 제목 아래 오른쪽 끝으로 내린다. "지출 · 수입" 이면 약 120.
double statsSegmentedWidth(List<String> labels) {
  var widest = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: PTypography.t5.copyWith(fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }
  return (widest + PSpacing.x6) * labels.length + PSpacing.x2;
}

/// 금액 글 — 원까지, 가리면 점.
String statsWon(int n, bool masked, {String sign = ''}) => n < 0 && sign.isEmpty
    // 빼기는 U+2212 — ASCII 하이픈을 쓰지 않는다
    ? budgetWon(n.abs(), masked, sign: kChartMinus)
    : budgetWon(n, masked, sign: sign);

/// 차트 글 가림 — 가리면 눈금 · 툴팁 값도 점(null 이면 ds 기본).
String Function(double)? maskFormatter(bool masked) =>
    masked ? (_) => kBudgetMask : null;

PChartColor? savedChartColor(String? hex) {
  final key = chartKeyOfHex(hex);
  return key == null ? null : PChartColor.values.asNameMap()[key];
}

typedef CatIndex = Map<int, ExpenseCategory>;

CatIndex catIndex(List<ExpenseCategory>? list) => {
  for (final c in list ?? const <ExpenseCategory>[]) c.rowId: c,
};

/// 기간 버튼(31) — ds Button neutralOutline small 36 · 글 t4 · 700 · 뒤 꺾쇠 하나(button.md:67 "앞 · 뒤 아이콘을 함께 쓰지 않는다" —
/// 예산 "2026년 10월 ⌄" 와 같은 꼴, 앞 달력 아이콘은 두지 않는다). 글은 한 줄이라 긴 직접 기간은 머리 줄이 알아서 제목 아래로 내려 준다.
class StatsPeriodButton extends StatelessWidget {
  const StatsPeriodButton({
    super.key,
    required this.period,
    required this.onPressed,
  });

  final StatsPeriod period;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = period.label();
    return Semantics(
      container: true,
      button: true,
      label: l.statsPeriodButtonAria(text),
      onTap: onPressed,
      excludeSemantics: true,
      child: PButton(
        label: period.buttonLabel(),
        variant: PButtonVariant.neutralOutline,
        size: PButtonSize.small,
        suffixIcon: LucideIcons.chevronDown,
        onPressed: onPressed,
      ),
    );
  }
}

/// 띠 안 구역 — 머리(제목 + 오른쪽 동작)와 본문. 예산의 [BudgetSection] 그대로.
Widget statsSection({
  Widget? header,
  required List<Widget> children,
  double topPadding = PSpacing.x6,
}) => BudgetSection(header: header, topPadding: topPadding, children: children);

/// 한 질의가 실패한 구역 — 머리 아래 상자 하나(질의 하나 = 상자 하나, 오류 원문 없음).
Widget statsFailureSection({
  required Widget? header,
  required String title,
  required VoidCallback onRetry,
  bool retrying = false,
}) => BudgetSection(
  header: header,
  children: [BudgetFailure(title: title, retrying: retrying, onRetry: onRetry)],
);

/// 차트 자리 스켈레톤 — 높이만 같다.
class StatsChartSkeleton extends StatelessWidget {
  const StatsChartSkeleton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => PSkeleton(
    width: double.infinity,
    height: height,
    radius: PSkeletonRadius.r16,
  );
}

/// 구역 이름 · 금액 한 줄 — 이름은 줄바꿈, 금액은 한 줄 · 고정폭 · 오른쪽 끝. 한 줄에 이름 최소 폭(8rem)이 안 남으면 금액이 아래 줄
/// 오른쪽 끝으로 내려간다.
class StatsNameAmount extends StatelessWidget {
  const StatsNameAmount({
    super.key,
    required this.name,
    required this.amount,
    this.nameStyle,
    this.amountStyle,
    this.times,
  });

  final String name;
  final String amount;
  final TextStyle? nameStyle;
  final TextStyle? amountStyle;

  /// 이름 뒤 같은 줄 "{n}회".
  final String? times;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scaler = MediaQuery.textScalerOf(context);
    final nStyle = nameStyle ?? PTypography.t5.copyWith(color: c.fgNeutral);
    final aStyle = (amountStyle ?? PTypography.t5).copyWith(
      color: c.fgNeutral,
      fontWeight: FontWeight.w700,
      fontFeatures: tabularFigures,
    );
    final nameText = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: keepAll(name)),
          if (times != null)
            TextSpan(
              text: ' ${keepAll(times!)}',
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
        ],
        style: nStyle,
      ),
      semanticsLabel: times == null ? name : '$name $times',
    );
    final amountText = Text(
      amount,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.end,
      style: aStyle,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: amount, style: aStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        // 8rem = 글자 배율을 따르는 128
        final minName = scaler.scale(128);
        final fits =
            tp.width + PSpacing.x3 + minName <= constraints.maxWidth + 0.01;
        if (fits) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: nameText),
              const SizedBox(width: PSpacing.x3),
              amountText,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameText,
            Align(alignment: AlignmentDirectional.centerEnd, child: amountText),
          ],
        );
      },
    );
  }
}

/// 장식 막대 — 8 · 끝 둥글게 · 트랙 bg-neutral-weak. 값은 옆 금액 글이 말한다(보조 기술에는 숨긴다).
class StatsDecoBar extends StatelessWidget {
  const StatsDecoBar({super.key, required this.segments});

  /// (비율 0 ~ 1 — 전체 트랙에 대한 폭, 색). 앞에서부터 쌓는다.
  final List<({double ratio, Color color})> segments;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.full),
        child: SizedBox(
          height: PSpacing.x2,
          child: ColoredBox(
            color: c.bgNeutralWeak,
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  for (final s in segments)
                    if (s.ratio > 0)
                      SizedBox(
                        width: constraints.maxWidth * s.ratio.clamp(0.0, 1.0),
                        height: PSpacing.x2,
                        child: ColoredBox(color: s.color),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 카테고리별 지출 ───────────────────────────────────────────────

/// 도넛 구역(32) — 머리 "카테고리별 지출" + 기간 버튼, 아래 Segmented, 도넛 180(두께 24) · 가운데 글 없음 · 합계 줄 · 목록 범례.
class StatsDonutSection extends StatefulWidget {
  const StatsDonutSection({
    super.key,
    required this.period,
    required this.onPickPeriod,
    required this.summary,
    required this.categories,
    required this.masked,
  });

  final StatsPeriod period;
  final VoidCallback onPickPeriod;

  /// 값이 있으면 그린다(다시 받는 중에도), 없으면 [AsyncValue] 의 상태 — 실패는 탭이 걸러 이 부품에 넘기지 않는다.
  final RangeSummary? summary;
  final List<ExpenseCategory>? categories;
  final bool masked;

  @override
  State<StatsDonutSection> createState() => _StatsDonutSectionState();
}

class _StatsDonutSectionState extends State<StatsDonutSection> {
  int? _activeParentId;
  FixedView _view = FixedView.all;

  @override
  void didUpdateWidget(covariant StatsDonutSection old) {
    super.didUpdateWidget(old);
    // 기간이 바뀌면 드릴다운을 푼다
    if (old.period != widget.period) _activeParentId = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final masked = widget.masked;
    final summary = widget.summary;
    final byId = catIndex(widget.categories);
    final bd = summary?.categoryBreakdown ?? const <CategoryBreakdown>[];
    final parents = donutParents(bd, _view, byId, l.statsUnassigned);
    final drilled = _activeParentId != null;
    final children = drilled
        ? donutChildren(bd, _activeParentId!, _view, byId, l.statsUnassigned)
        : const <DonutRow>[];
    final rows = drilled && children.isNotEmpty ? children : parents;
    final total = rows.fold<int>(0, (s, r) => s + r.amount);
    final activeParent = drilled
        ? parents.where((r) => r.rowId == _activeParentId).firstOrNull
        : null;

    final totalLabel = drilled && activeParent != null
        ? l.statsCategoryDetail(activeParent.name)
        : switch (_view) {
            FixedView.variable => l.statsDonutCenterVariable,
            FixedView.fixed => l.statsDonutCenterFixed,
            FixedView.all => l.statsPeriodSpending(
              widget.period.seg == StatsSeg.custom
                  ? l.statsCustomPeriod
                  : widget.period.label(),
            ),
          };

    final head = BudgetHead(
      title: l.statsSpendingByCategory,
      titleChild: drilled
          ? Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: PSpacing.x1,
              children: [
                Transform.translate(
                  offset: const Offset(-kTextButtonPaddingX, 0),
                  child: PTextButton(
                    label: l.statsSpendingByCategory,
                    onPressed: () => setState(() => _activeParentId = null),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-kTextButtonPaddingX, 0),
                  child: Text(
                    '›',
                    style: PTypography.t5.copyWith(color: c.fgNeutralSubtle),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-kTextButtonPaddingX, 0),
                  child: Text(
                    keepAll(activeParent?.name ?? ''),
                    style: PTypography.t5.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : null,
      trailing: StatsPeriodButton(
        period: widget.period,
        onPressed: widget.onPickPeriod,
      ),
    );

    final segmented = PSegmentedControl<FixedView>(
      value: _view,
      semanticLabel: l.statsFixedViewAria,
      onChanged: (v) => setState(() {
        _view = v;
        _activeParentId = null;
      }),
      items: [
        PSegmentedItem(value: FixedView.all, label: l.statsFixedViewAll),
        PSegmentedItem(
          value: FixedView.variable,
          label: l.statsFixedViewVariable,
        ),
        PSegmentedItem(value: FixedView.fixed, label: l.statsFixedViewFixed),
      ],
    );

    if (summary == null) {
      // 첫 불러오기 — 도넛 지름 그대로 + 범례 줄 높이 그대로
      return statsSection(
        header: head,
        children: [
          segmented,
          const SizedBox(height: PSpacing.x5),
          loadingRegionWithText(
            Column(
              children: [
                const Center(
                  child: PSkeleton(
                    width: 180,
                    height: 180,
                    radius: PSkeletonRadius.full,
                  ),
                ),
                const SizedBox(height: PSpacing.x4),
                for (var i = 0; i < 5; i++)
                  SizedBox(
                    height: kChartDonutRowHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PSkeleton.text(PTypography.t4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    if (rows.isEmpty) {
      return statsSection(
        header: head,
        children: [segmented, BudgetEmptyLine(l.statsNoCategoryData)],
      );
    }

    final colored = assignChartColors<DonutRow>(
      rows,
      colorOf: (r) => savedChartColor(r.color),
      groupOthers: (rest) => DonutRow(
        rowId: -1,
        name: l.dashCategoryOthers,
        amount: rest.fold<int>(0, (s, e) => s + e.amount),
      ),
    );
    String pct(int v) => formatShareOf(v, total, underOne: l.percentUnderTenth);
    String money(int v) => statsWon(v, masked);
    final totalText = money(total);
    final name = l.statsChartDonutName(widget.period.label(), totalText);
    final keys = [
      for (var i = 0; i < colored.length; i++)
        '${colored[i].item.rowId < 0 ? 'others' : colored[i].item.rowId}-$i',
    ];
    return statsSection(
      header: head,
      children: [
        segmented,
        const SizedBox(height: PSpacing.x5),
        Center(
          child: PDonutChart(
            label: name,
            diameter: 180,
            slices: [
              for (var i = 0; i < colored.length; i++)
                PDonutSlice(
                  key: keys[i],
                  label: colored[i].item.name,
                  amount: colored[i].item.amount.toDouble(),
                  color: colored[i].color,
                ),
            ],
            valueFormatter: maskFormatter(masked),
          ),
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.expCategory),
            PChartDataColumn(l.dashTableShare),
            PChartDataColumn(l.dashTableAmount),
          ],
          rows: [
            for (final s in colored)
              [s.item.name, pct(s.item.amount), money(s.item.amount)],
          ],
        ),
        const SizedBox(height: PSpacing.x4),
        // 합계 줄 — 폰은 값과 상관없이 늘 목록 위 한 줄(가운데 글 없음). 큰 글자에서는 금액이 아래 줄 오른쪽 끝으로 내려간다
        StatsNameAmount(
          name: totalLabel,
          nameStyle: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          amount: totalText,
        ),
        const SizedBox(height: PSpacing.x1),
        PChartDonutLegend(
          items: [
            for (var i = 0; i < colored.length; i++)
              PChartDonutLegendItem(
                key: keys[i],
                label: colored[i].item.name,
                color: colored[i].color,
                percent: pct(colored[i].item.amount),
                amount: money(colored[i].item.amount),
                // 하위가 있는 줄만 누르는 줄 — 들어가면 그 안에서는 더 들어갈 곳이 없다
                onTap: !drilled && colored[i].item.hasChildren
                    ? () => setState(
                        () => _activeParentId = colored[i].item.rowId,
                      )
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

// ── 많이 쓴 가맹점 TOP 5 ──────────────────────────────────────────

/// TOP 5(33) — 순위 16 + 본문(이름 줄바꿈 · n회 · 금액 한 줄) + 아래 막대(카테고리 색 그대로, 장식).
class StatsMerchantsSection extends StatelessWidget {
  const StatsMerchantsSection({
    super.key,
    required this.merchants,
    required this.masked,
  });

  /// null 이면 첫 불러오기.
  final List<MerchantSummary>? merchants;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final head = BudgetHead(title: l.statsTopMerchantsTitle);
    Widget list(List<Widget> rows) =>
        BudgetListSection(header: head, children: rows);
    final all = merchants;
    if (all == null) {
      return list([
        loadingRegionWithText(
          Column(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpacing.x6,
                    vertical: PSpacing.x2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x2_5,
                    children: [
                      PSkeleton.text(PTypography.t4, width: PSpacing.x4),
                      Expanded(
                        child: Column(
                          spacing: PSpacing.x1_5,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                PSkeleton.text(PTypography.t5, width: 120),
                                PSkeleton.text(PTypography.t5, width: 64),
                              ],
                            ),
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
                ),
            ],
          ),
        ),
      ]);
    }
    final top = (List.of(
      all,
    )..sort((a, b) => b.totalAmount.compareTo(a.totalAmount))).take(5).toList();
    if (top.isEmpty) {
      return BudgetSection(
        header: head,
        children: [BudgetEmptyLine(l.statsNoMerchantData)],
      );
    }
    final maxAmt = top.first.totalAmount <= 0 ? 1 : top.first.totalAmount;
    return list([
      for (final (i, m) in top.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.x6,
            vertical: PSpacing.x2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x2_5,
            children: [
              SizedBox(
                width: PSpacing.x4,
                child: Text(
                  '${i + 1}',
                  style: PTypography.t4.copyWith(
                    color: c.fgBrand,
                    fontWeight: FontWeight.w700,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatsNameAmount(
                      name: m.merchant ?? l.statsNoName,
                      times: l.expTimesCount(m.count),
                      amount: statsWon(m.totalAmount, masked),
                    ),
                    const SizedBox(height: PSpacing.x1_5),
                    // 막대는 ProgressBar 가 아니다 — 카테고리 색 그대로, 장식(값은 옆 금액 글이 말한다)
                    StatsDecoBar(
                      segments: [
                        (
                          ratio: m.totalAmount / maxAmt,
                          color: kChartOrder[i % kChartOrder.length].of(c),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}

// ── 요일 · 시간대 열지도 ───────────────────────────────────────────

/// 열지도(34) — ds 열지도. 칸 글은 칸 폭 112 이상에서만(폰은 세기 색만), 값은 툴팁 · 표로 보기에서 읽는다.
class StatsHeatmapSection extends StatelessWidget {
  const StatsHeatmapSection({
    super.key,
    required this.period,
    required this.cells,
    required this.masked,
  });

  final StatsPeriod period;

  /// null 이면 첫 불러오기.
  final List<HeatmapCell>? cells;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final head = BudgetHead(title: l.statsPatternTitle);
    final data = cells;
    if (data == null) {
      return statsSection(
        header: head,
        children: [
          BudgetDesc(l.statsPatternDesc),
          const SizedBox(height: PSpacing.x3),
          loadingRegionWithText(
            const StatsChartSkeleton(height: 6 * 34 + 6 * 6 + 18),
          ),
        ],
      );
    }
    final matrix = heatMatrix(data);
    final total = matrix.fold<int>(
      0,
      (s, r) => s + r.fold<int>(0, (a, b) => a + b),
    );
    if (total == 0) {
      return statsSection(
        header: head,
        children: [
          BudgetEmptyLine(l.statsTooFewTx(periodInSentence(period.now(l)))),
        ],
      );
    }
    final days = weekdayLabels(mondayFirst: true);
    final totalText = statsWon(total, masked);
    final name = l.statsChartHeatName(period.label(), totalText);
    final rowDefs = [
      for (var r = 0; r < heatRowHours.length; r++)
        PHeatmapRow(key: 'row$r', label: heatRowLabel(l, r), sub: heatSub(r)),
    ];
    return statsSection(
      header: head,
      children: [
        BudgetDesc(l.statsPatternDesc),
        const SizedBox(height: PSpacing.x3),
        PHeatmap(
          label: name,
          rows: rowDefs,
          columns: [
            for (var i = 0; i < days.length; i++)
              PHeatmapColumn(key: 'col$i', label: days[i]),
          ],
          values: [
            for (final row in matrix)
              [for (final v in row) v > 0 ? v.toDouble() : null],
          ],
          formatValue: masked ? (_) => kBudgetMask : null,
          valueLabel: l.statsChartHeatValue,
          tooltipLabel: (row, col) => '${col.label} ${row.label} ${row.sub}',
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.statsTableTime),
            for (final d in days) PChartDataColumn(d),
          ],
          rows: [
            for (var r = 0; r < matrix.length; r++)
              [
                '${rowDefs[r].label} ${rowDefs[r].sub}',
                for (final v in matrix[r]) statsWon(v, masked),
              ],
          ],
        ),
        const SizedBox(height: PSpacing.x3),
        // 범례 — 적음 ▭▭▭▭▭ 많음 · 총 금액
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: PSpacing.x2,
          runSpacing: PSpacing.x1,
          children: [
            Text(
              l.statsLegendLow,
              style: PTypography.t2.copyWith(color: c.fgNeutralSubtle),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: PSpacing.x0_5,
                children: [
                  for (var i = 0; i < kHeatMix.length; i++)
                    Container(
                      width: PSpacing.x4,
                      height: PSpacing.x2_5,
                      decoration: BoxDecoration(
                        color: heatStepColor(c, i),
                        borderRadius: BorderRadius.circular(PRounded.r1),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              l.statsLegendHigh,
              style: PTypography.t2.copyWith(color: c.fgNeutralSubtle),
            ),
            // 앞 말 + 금액 — Wrap 이 줄 폭을 주므로 띄어쓰기에서 먼저 넘기고 쉼표 뒤는 금액이 칸보다 길 때만(keepAllFit)
            KeepAllFitText(
              '${l.statsTotalPrefix} $totalText',
              style: PTypography.t2.copyWith(
                color: c.fgNeutralSubtle,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 요약(하이라이트) ───────────────────────────────────────────────

/// 요약(35) — 머리 없는 띠. 블록 셋(가장 많이 쓴 카테고리 · 가맹점 · 평균), 블록 사이 16. 이름 줄바꿈.
class StatsHighlightsSection extends StatelessWidget {
  const StatsHighlightsSection({
    super.key,
    required this.period,
    required this.summary,
    required this.prevSummary,
    required this.prevLoading,
    required this.categories,
    required this.merchants,
    required this.expenses,
    required this.masked,
  });

  final StatsPeriod period;

  /// null 이면 첫 불러오기.
  final RangeSummary? summary;
  final RangeSummary? prevSummary;
  final bool prevLoading;
  final List<ExpenseCategory>? categories;
  final List<MerchantSummary>? merchants;
  final List<Expense>? expenses;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final loading = summary == null || merchants == null;
    final byId = catIndex(categories);

    Widget block({
      required String label,
      required String title,
      required Widget detail,
      required IconData icon,
      required Color fg,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: Padding(
              padding: const EdgeInsets.only(bottom: PSpacing.x2),
              child: Text(
                keepAll(label),
                style: PTypography.t3.copyWith(
                  color: c.fgNeutralSubtle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          PList(
            children: [
              PListItem(
                title: title,
                titleWeight: FontWeight.w700,
                detailChild: detail,
                prefix: PListTile(
                  background: softBg(context, fg),
                  color: fg,
                  child: Icon(icon),
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget skeleton() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
      child: Row(
        spacing: PSpacing.x3,
        children: [
          const PSkeleton(
            width: PSpacing.x10,
            height: PSpacing.x10,
            radius: PSkeletonRadius.r12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x0_5,
              children: [
                PSkeleton.text(PTypography.t5, width: 120),
                PSkeleton.text(PTypography.t3, width: 80),
              ],
            ),
          ),
        ],
      ),
    );

    Widget labelOnly(String label) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            0,
            PSpacing.x6,
            PSpacing.x2,
          ),
          child: Text(
            keepAll(label),
            style: PTypography.t3.copyWith(
              color: c.fgNeutralSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        skeleton(),
      ],
    );

    Widget detailText(String text) => Text(
      keepAll(text),
      style: TextStyle(color: c.fgNeutralSubtle, fontFeatures: tabularFigures),
    );

    final children = <Widget>[];
    if (loading) {
      children.add(
        loadingRegionWithText(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              labelOnly(l.statsTopCategory),
              const SizedBox(height: PSpacing.x4),
              labelOnly(l.statsTopMerchant),
              const SizedBox(height: PSpacing.x4),
              labelOnly(period.avgLabel(l)),
            ],
          ),
        ),
      );
    } else {
      final bd = summary!.categoryBreakdown;
      final groups = <int, ({int id, String name, int amount})>{};
      for (final cb in bd) {
        if (cb.expenseType != 'EXPENSE') continue;
        final id = cb.parentCategoryRowId ?? cb.categoryRowId;
        if (id == null) continue;
        final name =
            cb.parentCategoryName ?? cb.categoryName ?? l.statsUnassigned;
        final cur = groups[id];
        groups[id] = cur == null
            ? (id: id, name: name, amount: cb.totalAmount)
            : (id: id, name: cur.name, amount: cur.amount + cb.totalAmount);
      }
      final topCat =
          (groups.values.toList()..sort((a, b) => b.amount.compareTo(a.amount)))
              .firstOrNull;
      final topCatMeta = topCat == null ? null : byId[topCat.id];
      final catFg = resolveChartColor(
        context,
        topCatMeta?.color,
        fallback: c.fgBrand,
      );

      final ms = List.of(merchants!)
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      final topMerchant = ms.firstOrNull;
      // 가맹점 대표 카테고리 — 원시 거래에서 그 가맹점의 가장 큰 카테고리를 역산(없으면 상점 아이콘)
      IconData merchantIcon = LucideIcons.store;
      Color merchantFg = c.fgBrand;
      final mName = topMerchant?.merchant;
      if (mName != null) {
        final catTotals = <int, ({int amount, String? icon, String? color})>{};
        for (final e in expenses ?? const <Expense>[]) {
          if (e.merchant != mName || e.expenseType != 'EXPENSE') continue;
          final cid = e.categoryRowId;
          if (cid == null) continue;
          final cur = catTotals[cid];
          catTotals[cid] = cur == null
              ? (amount: e.amount, icon: e.categoryIcon, color: e.categoryColor)
              : (
                  amount: cur.amount + e.amount,
                  icon: cur.icon,
                  color: cur.color,
                );
        }
        ({int amount, String? icon, String? color})? best;
        for (final v in catTotals.values) {
          if (best == null || v.amount > best.amount) best = v;
        }
        if (best != null) {
          merchantFg = resolveChartColor(
            context,
            best.color,
            fallback: c.fgBrand,
          );
          merchantIcon = lucideByName(best.icon, fallback: LucideIcons.store);
        }
      }

      final periodTotal = summary!.totalExpense;
      final divisor = period.useDailyAvg
          ? period.days
          : summary!.monthlyBuckets.length.clamp(1, 9999);
      final avgValue = divisor > 0 ? periodTotal ~/ divisor : 0;

      // 하루 평균 부제 — 월 모드는 전월 대비 Delta(기준 글은 Delta 뒤 옅은 글), 그 외 기간은 합계
      Widget avgDetail;
      if (period.seg != StatsSeg.month) {
        avgDetail = detailText(
          '${l.statsDaysTotal(period.days)} ${statsWon(periodTotal, masked)}',
        );
      } else {
        final prevTotal = prevSummary?.totalExpense ?? 0;
        if (prevTotal > 0) {
          final diff = periodTotal - prevTotal;
          avgDetail = PDelta(
            direction: diff > 0
                ? PDeltaDirection.up
                : (diff < 0 ? PDeltaDirection.down : PDeltaDirection.flat),
            value: statsChangeRate(periodTotal, prevTotal),
            text: l.statsMomMonth(periodInSentence(period.previous(l))),
          );
        } else {
          avgDetail = detailText(
            prevLoading
                ? l.statsMomCalculating(periodInSentence(period.previous(l)))
                : l.statsMomUnavailable(periodInSentence(period.previous(l))),
          );
        }
      }

      children
        ..add(
          block(
            label: l.statsTopCategory,
            title: topCat?.name ?? '—',
            detail: detailText(
              topCat != null
                  ? statsWon(topCat.amount, masked)
                  : l.statsNoDataShort,
            ),
            icon: lucideByName(topCatMeta?.icon, fallback: LucideIcons.tag),
            fg: catFg,
          ),
        )
        ..add(const SizedBox(height: PSpacing.x4))
        ..add(
          block(
            label: l.statsTopMerchant,
            title: topMerchant?.merchant ?? '—',
            detail: detailText(
              topMerchant != null
                  ? '${l.expTimesCount(topMerchant.count)} · ${statsWon(topMerchant.totalAmount, masked)}'
                  : l.statsNoDataShort,
            ),
            icon: merchantIcon,
            fg: merchantFg,
          ),
        )
        ..add(const SizedBox(height: PSpacing.x4))
        ..add(
          block(
            label: period.avgLabel(l),
            title: statsWon(avgValue, masked),
            detail: avgDetail,
            icon: LucideIcons.calendarDays,
            fg: c.fgBrand,
          ),
        );
    }
    // 머리 없는 띠 — 위 24 에서 첫 글이 시작한다(블록은 제 좌우 24 를 가진다)
    return statsSection(
      children: [for (final w in children) BudgetFull(child: w)],
    );
  }
}
