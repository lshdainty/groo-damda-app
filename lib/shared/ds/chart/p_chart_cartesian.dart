import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_parts.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';

/// 계열 하나 — 선 · 막대 차트의 줄 하나. [values] 는 [categories] 와 같은 순서(없는 날은 null — 오늘 뒤 날짜는 0 으로 채우지
/// 않고 아예 넘기지 않는다).
class PChartSeries {
  const PChartSeries({
    required this.key,
    required this.label,
    required this.color,
    required this.values,
    this.onRight = false,
    this.weak = false,
  });

  final String key;
  final String label;
  final PChartColor color;
  final List<double?> values;

  /// 오른쪽 축 — 두 계열의 크기가 열 배 넘게 다를 때(수입 0 ~ 400만 · 지출 0 ~ 40만). 이 축이 맡은 계열의 눈금 글자는 그
  /// 계열의 색이다. 계열이 셋 이상이거나 단위가 같은 두 계열은 축 하나다.
  final bool onRight;

  /// 같은 색의 옅은 단계로 그린다 — 강조하지 않는 비교 계열(지난 기간). 선 · 막대 · 툴팁 네모 모두.
  final bool weak;

  Color colorOf(PColors c) => weak ? color.weakOf(c) : color.of(c);
}

/// 차트 맨 위 여백 — 맨 위 눈금 글자(15)의 윗 절반이 잘리지 않게.
const double kChartTopPad = 8;

/// 막대 위 값 글을 둘 때 더하는 맨 위 자리 — 글 16 + 사이 4.
const double _kBarLabelRoom = 20;

/// 아래 눈금(가로축) 자리 — 눈금 15 + 눈금과 그리는 자리 사이 8.
const double kChartBottomReserved = 15 + kChartTickMargin;

/// 막대 최대 폭 · 한 묶음 안 막대 사이 · 위(아래) 모서리.
const double kChartBarMaxWidth = 28;
const double kChartBarGap = PSpacing.x1;
const double kChartBarRadius = PRounded.r1;

/// 선 두께 · 가리킨 점(r 3 + 테두리 2 = 바깥 지름 10).
const double kChartLineWidth = 2;
const double kChartPointRadius = 3;
const double kChartPointStroke = 2;

/// 가로 점선 격자 · 가리킴 선의 점선(3 · 3).
const List<int> kChartDash = [3, 3];

/// 선 · 막대 차트가 같이 쓰는 값.
abstract class PCartesianChart extends StatefulWidget {
  const PCartesianChart({
    super.key,
    required this.label,
    required this.categories,
    required this.series,
    this.height = 200,
    this.description,
    this.hidden = const {},
    this.headFormatter,
    this.valueFormatter,
    this.axisFormatter,
  });

  /// 요약 이름 — "10월 수입 · 지출 추이, 수입 4,200,000원 · 지출 1,240,000원".
  final String label;

  /// 대체가 되는 범례(지표 타일)의 글.
  final String? description;

  /// 가로축 — 날짜 · 기간 이름. 하루 · 한 달 같은 짧은 글("8일").
  final List<String> categories;
  final List<PChartSeries> series;

  /// 높이(px) — 쓰는 자리가 정한다(고정 비율을 두지 않는다).
  final double height;

  /// 숨긴 계열의 key(지표 타일에서 끈 것).
  final Set<String> hidden;

  /// 툴팁 머리 — 기본은 가로축 이름 그대로("10월 8일 (목)" 으로 바꿔 넘긴다).
  final String Function(String category)? headFormatter;

  /// 툴팁 값 — 기본 원까지(빼기 U+2212).
  final String Function(double value)? valueFormatter;

  /// 세로축 눈금 — 기본 만 · 억 · 조 단위.
  final String Function(double value)? axisFormatter;
}

/// 선(영역) 차트 — 곡선 monotone · 선 2 · 점 없음(가리킨 자리에만 계열 색 점 r 3 + 카드 면 색 테두리 2). [area] 면
/// 영역은 같은 색 25% → 0% 세로 그라디언트(겹쳐도 아래 선이 보인다). 규칙은 p_chart.dart 머리 설명이다.
class PLineChart extends PCartesianChart {
  const PLineChart({
    super.key,
    required super.label,
    required super.categories,
    required super.series,
    super.height,
    super.description,
    super.hidden,
    super.headFormatter,
    super.valueFormatter,
    super.axisFormatter,
    this.area = true,
    this.dots = false,
  });

  final bool area;

  /// 데이터 점마다 늘 찍는 점 — 지름 6(r 3) · 계열 색 채움 · 테두리 없음. 기본은 없음(가리킨 자리에만 점이 선다). 점이 적은
  /// 추이를 영역 채움 없이 선 + 점으로 그릴 때만 켠다(I-05 57 — chart.md 선 줄 "점이 적은 추이는 선 + 점도 된다").
  /// 가리킨 점은 스펙 그대로(r 3 + 카드 면 색 테두리 2)라 이 점 위에 커져 겹친다.
  final bool dots;

  @override
  State<PLineChart> createState() => _PLineChartState();
}

/// 막대 차트 — 최대 폭 28 · 위 두 모서리 4(음수 막대는 아래 두 모서리) · 한 묶음 안 막대 사이 4.
class PBarChart extends PCartesianChart {
  const PBarChart({
    super.key,
    required super.label,
    required super.categories,
    required super.series,
    super.height,
    super.description,
    super.hidden,
    super.headFormatter,
    super.valueFormatter,
    super.axisFormatter,
    this.barColor,
    this.barLabel,
    this.referenceLines = const [],
    this.showValueAxis = true,
    this.emphasizedIndex,
    this.tooltipFooter,
    this.stacked = false,
  });

  /// 막대마다 색 — 주면 그 칸의 막대를 이 색으로 칠한다(null 이면 계열 색). 예산 이행률: 넘음 · 이번 달 · 지난 달.
  final Color? Function(int category, PColors colors)? barColor;

  /// 막대 위 값 글(t2 · 700 · fg-neutral) — 글이 null 이면 그 칸은 글 없음. 맨 위에 글 자리 20 을 더 둔다.
  final String? Function(int category, double value)? barLabel;

  /// 가로 기준선 값들 — 점선 3 · 3 stroke-neutral-weak 1px(예산 이행률 100%). 눈금 범위에 든다.
  final List<double> referenceLines;

  /// 세로축 눈금 글 · 가로 점선 격자를 둔다(기본). false 면 둘 다 없다 — 값은 막대 위 글이 말한다.
  final bool showValueAxis;

  /// 강조할 가로축 칸(이번 달) — 글 700 · fg-neutral.
  final int? emphasizedIndex;

  /// 툴팁 덧줄(글만, 색 네모 없음) — 지출 · 한도처럼 계열 밖 값.
  final List<({String name, String value})> Function(int category)?
  tooltipFooter;

  /// 계열을 칸 하나에 쌓는다(양수만 — 고정 · 변동, 카테고리 월별 추이). 막대는 칸마다 하나이고 맨 위 계열만 위 두 모서리가
  /// 둥글다. 눈금은 쌓은 합으로 정한다.
  final bool stacked;

  @override
  State<PBarChart> createState() => _PBarChartState();
}

/// 눈금 계산 결과 — 값은 눈금 칸 수(`ticks`) 단위로 옮겨 그린다(두 축의 0 이 같은 자리에 선다).
class _Plan {
  _Plan({
    required this.below,
    required this.above,
    required this.stepLeft,
    required this.stepRight,
    required this.leftWidth,
    required this.rightWidth,
    required this.labelInterval,
    required this.plotLeft,
    required this.plotWidth,
    required this.bottomReserved,
  });

  /// 0 아래 · 위로 눈금이 몇 칸인가.
  final int below;
  final int above;

  /// 왼쪽 · 오른쪽 축의 눈금 한 칸이 가리키는 값(오른쪽 축이 없으면 null).
  final double stepLeft;
  final double? stepRight;
  final double leftWidth;
  final double rightWidth;
  final int labelInterval;
  final double plotLeft;
  final double plotWidth;

  /// 아래 눈금(가로축) 자리 — 글자 배율을 곱한 눈금 높이 + 사이 8.
  final double bottomReserved;

  double get minY => -below.toDouble();
  double get maxY => above.toDouble();
}

abstract class _CartesianState<W extends PCartesianChart> extends State<W> {
  int? _active;
  Offset? _touch;

  /// 맨 위 여백 · 세로축 · 강조 칸 · 기준선 — 막대 차트가 덮어쓴다.
  double get _topPad => kChartTopPad;
  bool get _valueAxis => true;
  int? get _emphasized => null;
  List<double> get _referenceValues => const [];
  bool get _stacked => false;

  String _axisText(double v) => (widget.axisFormatter ?? formatAxisWon)(v);
  String _valueText(double v) => (widget.valueFormatter ?? formatWon)(v);

  List<PChartSeries> get _visible => [
    for (final s in widget.series)
      if (!widget.hidden.contains(s.key)) s,
  ];

  bool get _dual => widget.series.any((s) => s.onRight);

  /// 눈금을 정한다 — 숨긴 계열도 포함해 정한다(지표 타일을 눌러도 축이 흔들리지 않는다).
  _Plan _plan(double width, PColors c, TextScaler scaler) {
    final leftSeries = [
      for (final s in widget.series)
        if (!s.onRight) s,
    ];
    final rightSeries = [
      for (final s in widget.series)
        if (s.onRight) s,
    ];
    PChartAxis axisOf(List<PChartSeries> list) {
      double? lo;
      double? hi;
      if (_stacked) {
        // 쌓은 막대 — 칸마다 계열을 더한 합으로 눈금을 정한다
        for (var i = 0; i < widget.categories.length; i++) {
          var sum = 0.0;
          for (final s in list) {
            final v = i < s.values.length ? s.values[i] : null;
            if (v != null && v > 0) sum += v;
          }
          lo = 0;
          hi = hi == null ? sum : math.max(hi, sum);
        }
      } else {
        for (final s in list) {
          for (final v in s.values) {
            if (v == null) continue;
            lo = lo == null ? v : math.min(lo, v);
            hi = hi == null ? v : math.max(hi, v);
          }
        }
      }
      for (final v in _referenceValues) {
        lo = lo == null ? v : math.min(lo, v);
        hi = hi == null ? v : math.max(hi, v);
      }
      return niceChartAxis(lo ?? 0, hi ?? 0);
    }

    final l = axisOf(leftSeries.isEmpty ? rightSeries : leftSeries);
    final r = rightSeries.isEmpty || leftSeries.isEmpty
        ? null
        : axisOf(rightSeries);
    int ticksAbove(PChartAxis a) => (a.max / a.step).round();
    int ticksBelow(PChartAxis a) => (-a.min / a.step).round();
    final above = math.max(ticksAbove(l), r == null ? 0 : ticksAbove(r));
    final below = math.max(ticksBelow(l), r == null ? 0 : ticksBelow(r));
    // 맨 위 · 아래가 같은 칸 수라 위 · 아래가 없으면 한 칸은 둔다(모두 0 인 차트)
    final aboveFix = above == 0 && below == 0 ? 4 : above;

    final tickStyle = chartTickStyle(c);
    double axisWidth(double step) => chartAxisWidth(
      [for (var t = -below; t <= aboveFix; t++) _axisText(t * step)],
      tickStyle,
      scaler: scaler,
    );

    final leftW = _valueAxis ? axisWidth(l.step) : 0.0;
    final rightW = r == null ? 0.0 : axisWidth(r.step);
    var labelW = 0.0;
    for (final cat in widget.categories) {
      labelW = math.max(labelW, measureText(cat, tickStyle, scaler: scaler));
    }
    // 가로축 끝 글자가 반쯤 삐져나가므로 오른쪽 축이 없으면 그만큼 비워 둔다
    var rightPad = r == null ? math.max(PSpacing.x2, labelW / 2) : rightW;
    var plotW = math.max(1.0, width - leftW - rightPad);
    final fit = math.max(1, (plotW / (labelW + PSpacing.x2)).floor());
    if (fit < 2 && r == null) {
      // 글 하나도 둘이 못 들어가면 첫 글만 남는다(간격 = 칸 수) — 끝 글이 없으니 오른쪽을 비워 둘 까닭이 없다.
      // 비우면 그릴 폭이 더 줄어 fl_chart 가 가로 눈금을 하나도 부르지 않았다(200% · 긴 달 글자에서 가로 눈금이 통째로 사라졌다)
      rightPad = PSpacing.x2;
      plotW = math.max(1.0, width - leftW - rightPad);
    }
    final interval = math.max(1, (widget.categories.length / fit).ceil());
    return _Plan(
      below: below,
      above: aboveFix,
      stepLeft: l.step,
      stepRight: r?.step,
      leftWidth: leftW,
      rightWidth: rightPad,
      labelInterval: interval,
      plotLeft: leftW,
      plotWidth: plotW,
      bottomReserved: scaler.scale(15) + kChartTickMargin,
    );
  }

  /// 값 → 눈금 칸 수 단위 y.
  double _y(PChartSeries s, double v, _Plan p) =>
      v / (s.onRight && p.stepRight != null ? p.stepRight! : p.stepLeft);

  FlTitlesData _titles(PColors c, _Plan p, {required bool dual}) {
    final leftColor = dual
        ? widget.series.firstWhere((s) => !s.onRight).color
        : null;
    final rightColor = dual
        ? widget.series.firstWhere((s) => s.onRight).color
        : null;
    Widget side(double v, TitleMeta meta, double? step, PChartColor? color) {
      if (v != v.roundToDouble() || step == null) return const SizedBox();
      return SideTitleWidget(
        meta: meta,
        space: kChartTickMargin,
        child: Text(
          _axisText(v * step),
          maxLines: 1,
          style: chartTickStyle(c, color: color),
        ),
      );
    }

    return FlTitlesData(
      topTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: _valueAxis,
          reservedSize: p.leftWidth,
          interval: 1,
          getTitlesWidget: (v, meta) => side(v, meta, p.stepLeft, leftColor),
        ),
      ),
      rightTitles: dual
          ? AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: p.rightWidth,
                interval: 1,
                getTitlesWidget: (v, meta) =>
                    side(v, meta, p.stepRight, rightColor),
              ),
            )
          : AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: p.rightWidth,
                getTitlesWidget: (v, meta) => const SizedBox(),
              ),
            ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: p.bottomReserved,
          interval: p.labelInterval.toDouble(),
          getTitlesWidget: (v, meta) {
            final i = v.round();
            if (v != i.toDouble() || i < 0 || i >= widget.categories.length) {
              return const SizedBox();
            }
            // fl_chart 는 간격에 안 맞아도 마지막 눈금을 더 찍는다 — 앞 글자와 겹쳐 "11월12월" 이 된다(막대 차트는 interval 을 아예 따르지 않아 칸마다 부른다 — 간격 칸만 그린다)
            if (i % p.labelInterval != 0) return const SizedBox();
            return SideTitleWidget(
              meta: meta,
              space: kChartTickMargin,
              child: Text(
                widget.categories[i],
                maxLines: 1,
                style: i == _emphasized
                    ? chartTickStyle(c).copyWith(
                        color: c.fgNeutral,
                        fontWeight: FontWeight.w700,
                      )
                    : chartTickStyle(c),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 가로 점선 격자만 — 세로 격자 · 축 선은 긋지 않는다.
  FlGridData _grid(PColors c) => FlGridData(
    show: _valueAxis,
    drawVerticalLine: false,
    horizontalInterval: 1,
    getDrawingHorizontalLine: (_) => FlLine(
      color: c.strokeNeutralSubtle,
      strokeWidth: 1,
      dashArray: kChartDash,
    ),
  );

  /// 가리킨 자리의 x(차트 상자 안) — 그 자리의 가운데.
  double _xOf(int index, _Plan p);

  void _setActive(int? index, Offset? local) {
    if (index == null) return;
    if (_active == index && _touch == local) return;
    setState(() {
      _active = index;
      _touch = local;
    });
  }

  void _close() {
    if (_active == null) return;
    setState(() {
      _active = null;
      _touch = null;
    });
  }

  Widget _tip(PColors c, _Plan p, double plotHeight) {
    final i = _active!;
    final rows = <PChartTooltipRow>[
      for (final s in _visible)
        if (i < s.values.length && s.values[i] != null)
          PChartTooltipRow(
            swatch: s.colorOf(c),
            name: s.label,
            value: _valueText(s.values[i]!),
          ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    rows.addAll(_tipFooter(i));
    final cat = widget.categories[i];
    final dy = (_touch?.dy ?? plotHeight / 2) + _topPad;
    return PChartTipLayer(
      anchor: Offset(_xOf(i, p), dy),
      side: PChartTipSide.beside,
      child: PChartTooltip(
        head: widget.headFormatter?.call(cat) ?? cat,
        rows: rows,
      ),
    );
  }

  /// 차트 그림 — 선 · 막대가 다르다. [progress] 는 그려짐(0 → 1).
  Widget _chart(
    BuildContext context,
    PColors c,
    _Plan p,
    double h,
    double progress,
  );

  /// 툴팁 덧줄 — 막대 차트만.
  List<PChartTooltipRow> _tipFooter(int index) => const [];

  /// 막대는 그림 위에 가리킴 선을 따로 그린다.
  Widget? _overlay(PColors c, _Plan p, double h) => null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 가리킨 자리가 데이터 밖으로 나갔으면(데이터가 바뀜) 닫는다
    if (_active != null && _active! >= widget.categories.length) {
      _active = null;
    }
    return PChartFrame(
      label: widget.label,
      description: widget.description,
      height: widget.height,
      child: PChartDrawIn(
        builder: (context, progress) => LayoutBuilder(
          builder: (context, constraints) {
            final p = _plan(
              constraints.maxWidth,
              c,
              MediaQuery.textScalerOf(context),
            );
            final h = math.max(1.0, widget.height - _topPad);
            final overlay = _overlay(c, p, h);
            return TapRegion(
              // 다른 곳을 누르면 닫는다 — 손을 떼도 남는다
              onTapOutside: (_) => _close(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: _topPad,
                    child: _chart(context, c, p, h, progress),
                  ),
                  ?overlay,
                  if (_active != null) _tip(c, p, h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 선 ───────────────────────────────────────────────────────

class _PLineChartState extends _CartesianState<PLineChart> {
  double get _minX => widget.categories.length <= 1 ? -0.5 : 0;
  double get _maxX => widget.categories.length <= 1
      ? 0.5
      : (widget.categories.length - 1).toDouble();

  @override
  double _xOf(int index, _Plan p) =>
      p.plotLeft + (index - _minX) / (_maxX - _minX) * p.plotWidth;

  @override
  Widget _chart(
    BuildContext context,
    PColors c,
    _Plan p,
    double h,
    double progress,
  ) {
    final visible = _visible;
    if (visible.isEmpty) return const SizedBox.shrink();
    final bars = <LineChartBarData>[
      for (final s in visible)
        LineChartBarData(
          spots: [
            for (var i = 0; i < widget.categories.length; i++)
              if (i < s.values.length && s.values[i] != null)
                FlSpot(i.toDouble(), _y(s, s.values[i]!, p))
              else
                FlSpot.nullSpot,
          ],
          isCurved: true,
          // monotone — 값 사이에서 선이 넘치지 않는다
          preventCurveOverShooting: true,
          color: s.colorOf(c),
          barWidth: kChartLineWidth,
          dotData: widget.dots
              ? FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: kChartPointRadius,
                        color: s.color.of(c),
                        strokeWidth: 0,
                      ),
                )
              : const FlDotData(show: false),
          showingIndicators: _active == null ? const [] : [_active!],
          belowBarData: widget.area
              ? BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      s.colorOf(c).withValues(alpha: 0.25),
                      s.colorOf(c).withValues(alpha: 0),
                    ],
                  ),
                )
              : BarAreaData(show: false),
        ),
    ];
    final chart = LineChart(
      LineChartData(
        minX: _minX,
        maxX: _maxX,
        minY: p.minY,
        maxY: p.maxY,
        lineBarsData: bars,
        gridData: _grid(c),
        borderData: FlBorderData(show: false),
        titlesData: _titles(c, p, dual: _dual),
        lineTouchData: LineTouchData(
          // 툴팁은 직접 그린다("머리 + ■ 라벨 값" 표면 — 터치는 손을 떼도 남는다)
          handleBuiltInTouches: false,
          touchSpotThreshold: 4000,
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions) return;
            final spots = response?.lineBarSpots;
            if (spots == null || spots.isEmpty) return;
            _setActive(spots.first.spotIndex, event.localPosition);
          },
          getTouchLineStart: (bar, index) => p.minY,
          getTouchLineEnd: (bar, index) => p.maxY,
          getTouchedSpotIndicator: (bar, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                // 가리킴 선 — 세로 점선, 가리킨 점 — r 3 + 카드 면 색 테두리 2(바깥 지름 10)
                FlLine(
                  color: c.strokeNeutralWeak,
                  strokeWidth: 1,
                  dashArray: kChartDash,
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, b, i) => FlDotCirclePainter(
                    radius: kChartPointRadius,
                    color: b.color ?? c.fgNeutral,
                    strokeWidth: kChartPointStroke,
                    strokeColor: c.bgLayerDefault,
                  ),
                ),
              ),
          ],
        ),
      ),
      // 그려짐은 직접 한다 — 라이브러리의 값 사이 애니메이션은 끈다
      duration: Duration.zero,
    );
    if (progress >= 1) return chart;
    // 선 길이 — 왼쪽에서 오른쪽으로 드러난다
    return ClipRect(clipper: _RevealClipper(progress), child: chart);
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  _RevealClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_RevealClipper old) => old.progress != progress;
}

// ── 막대 ─────────────────────────────────────────────────────

class _PBarChartState extends _CartesianState<PBarChart> {
  @override
  double get _topPad =>
      kChartTopPad + (widget.barLabel == null ? 0 : _kBarLabelRoom);

  @override
  bool get _valueAxis => widget.showValueAxis;

  @override
  int? get _emphasized => widget.emphasizedIndex;

  @override
  List<double> get _referenceValues => widget.referenceLines;

  @override
  bool get _stacked => widget.stacked;

  @override
  List<PChartTooltipRow> _tipFooter(int index) {
    final footer = widget.tooltipFooter?.call(index) ?? const [];
    return [
      for (final r in footer) PChartTooltipRow(name: r.name, value: r.value),
    ];
  }

  @override
  double _xOf(int index, _Plan p) =>
      p.plotLeft + (index + 0.5) / widget.categories.length * p.plotWidth;

  double _barWidth(_Plan p, int count) {
    final slot = p.plotWidth / math.max(1, widget.categories.length);
    final room = slot * 0.8 - kChartBarGap * (count - 1);
    return math.max(2.0, math.min(kChartBarMaxWidth, room / count));
  }

  /// 쌓은 막대 한 칸 — 보이는 계열을 아래부터 쌓고, 맨 위 계열만 위 두 모서리가 둥글다.
  BarChartRodData _stackedRod(
    PColors c,
    _Plan p,
    int i,
    List<PChartSeries> visible,
    double width,
    double progress,
  ) {
    final items = <BarChartRodStackItem>[];
    var from = 0.0;
    for (final s in visible) {
      final v = i < s.values.length ? s.values[i] : null;
      if (v == null || v <= 0) continue;
      final to = from + _y(s, v, p) * progress;
      items.add(BarChartRodStackItem(from, to, s.colorOf(c)));
      from = to;
    }
    return BarChartRodData(
      toY: from,
      width: width,
      color: c.fgNeutral,
      rodStackItems: items,
      borderRadius: from == 0
          ? BorderRadius.zero
          : const BorderRadius.vertical(top: Radius.circular(kChartBarRadius)),
    );
  }

  @override
  Widget? _overlay(PColors c, _Plan p, double h) {
    final parts = <Widget>[];
    final label = widget.barLabel;
    if (label != null) {
      final visible = _visible;
      final plotH = h - p.bottomReserved;
      final range = p.maxY - p.minY;
      for (var i = 0; i < widget.categories.length; i++) {
        for (final s in visible) {
          final v = i < s.values.length ? s.values[i] : null;
          if (v == null) continue;
          final text = label(i, v);
          if (text == null) continue;
          // 막대 윗끝(음수는 쓰지 않는다) 바로 위 — 글 높이 16 · 사이 4
          final top = _topPad + (p.maxY - _y(s, v, p)) / range * plotH - 20;
          parts.add(
            Positioned(
              key: ValueKey('chart-bar-label-$i'),
              left: _xOf(i, p) - 40,
              width: 80,
              top: top,
              child: IgnorePointer(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: PTypography.t2.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    if (_active != null) {
      // 가리킴 선 — 그 칸의 가운데에 세로 점선(그림 위)
      parts.add(
        Positioned(
          left: _xOf(_active!, p) - 0.5,
          top: _topPad,
          height: h - p.bottomReserved,
          width: 1,
          child: IgnorePointer(
            child: CustomPaint(
              key: const ValueKey('chart-crosshair'),
              painter: PChartCrosshairPainter(c.strokeNeutralWeak),
            ),
          ),
        ),
      );
    }
    if (parts.isEmpty) return null;
    return Positioned.fill(child: Stack(children: parts));
  }

  @override
  Widget _chart(
    BuildContext context,
    PColors c,
    _Plan p,
    double h,
    double progress,
  ) {
    final visible = _visible;
    if (visible.isEmpty) return const SizedBox.shrink();
    final width = _barWidth(p, widget.stacked ? 1 : visible.length);
    final slot = p.plotWidth / math.max(1, widget.categories.length);
    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: p.minY,
        maxY: p.maxY,
        barGroups: [
          for (var i = 0; i < widget.categories.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: kChartBarGap,
              barRods: widget.stacked
                  ? [_stackedRod(c, p, i, visible, width, progress)]
                  : [
                      for (final s in visible)
                        () {
                          final v = i < s.values.length ? s.values[i] : null;
                          final y = v == null ? 0.0 : _y(s, v, p) * progress;
                          return BarChartRodData(
                            toY: y,
                            width: width,
                            color: widget.barColor?.call(i, c) ?? s.colorOf(c),
                            // 위 두 모서리만 4 — 음수 막대는 아래 두 모서리
                            borderRadius: y == 0
                                ? BorderRadius.zero
                                : y > 0
                                ? const BorderRadius.vertical(
                                    top: Radius.circular(kChartBarRadius),
                                  )
                                : const BorderRadius.vertical(
                                    bottom: Radius.circular(kChartBarRadius),
                                  ),
                          );
                        }(),
                    ],
            ),
        ],
        gridData: _grid(c),
        borderData: FlBorderData(show: false),
        titlesData: _titles(c, p, dual: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            for (final v in widget.referenceLines)
              HorizontalLine(
                y: _y(visible.first, v, p),
                color: c.strokeNeutralWeak,
                strokeWidth: 1,
                dashArray: kChartDash,
              ),
          ],
        ),
        barTouchData: BarTouchData(
          handleBuiltInTouches: false,
          // 막대 위 · 아래 빈자리와 묶음 사이도 그 칸으로 친다
          touchExtraThreshold: EdgeInsets.symmetric(
            horizontal: math.max(0, slot / 2),
            vertical: 4000,
          ),
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions) return;
            final spot = response?.spot;
            if (spot == null) return;
            _setActive(spot.touchedBarGroupIndex, event.localPosition);
          },
        ),
      ),
      duration: Duration.zero,
    );
    return chart;
  }
}

/// 막대 차트의 가리킴 선 — 1px 점선(3 · 3) stroke-neutral-weak.
class PChartCrosshairPainter extends CustomPainter {
  const PChartCrosshairPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0.5, y),
        Offset(0.5, math.min(y + kChartDash[0], size.height)),
        paint,
      );
      y += kChartDash[0] + kChartDash[1];
    }
  }

  @override
  bool shouldRepaint(PChartCrosshairPainter old) => old.color != color;
}
