import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_parts.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';

/// 도넛 조각 하나 — 카테고리 하나. 색은 [assignChartColors] 로 정한다.
class PDonutSlice {
  const PDonutSlice({
    required this.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  final String key;
  final String label;
  final double amount;
  final PChartColor color;
}

const _tabular = [FontFeature.tabularFigures()];

/// 도넛 차트 — 카테고리 비율. 조각 사이 0 · 두께는 지름 160 에서 22(폰 120 에서 18) · 12시에서 시계 방향. 가운데는 합계
/// (16 / 22 · 700)와 위 라벨(12) — 돈은 가운데서도 줄이지 않고, 도넛 모양과 함께 글자 크기 설정을 따르지 않는다(합계는 범례 ·
/// 목록에서 크게 읽는다). 가운데에 들어가지 않으면 가운데 글을 그리지 않고
/// [onFitChanged] 로 알린다 — 부르는 쪽이 목록 위에 합계를 둔다. 범례는 [PChartDonutLegend] 다.
///
/// 그리는 자리가 [diameter] 보다 좁으면 자리 폭을 지름으로 쓰고 두께 · 가운데 글 자리도 그 지름으로 다시 낸다(320 보다 좁은
/// 화면 — Layout "지원 폭").
///
/// 조각을 누르면 "■ 라벨 값" 툴팁이 뜬다 — 손을 떼도 남고, 다른 곳을 누르면 닫힌다.
class PDonutChart extends StatefulWidget {
  const PDonutChart({
    super.key,
    required this.label,
    required this.slices,
    this.diameter = 160,
    this.centerLabel,
    this.centerAmount,
    this.onFitChanged,
    this.description,
    this.valueFormatter,
  });

  /// 요약 이름 — "10월 카테고리별 지출, 합계 927,400원".
  final String label;

  /// 대체가 되는 범례(목록)의 글.
  final String? description;
  final List<PDonutSlice> slices;

  /// 지름 — 160 · 폰은 120.
  final double diameter;

  /// 가운데 위 라벨 — "10월 지출"(12 · fg-neutral-subtle).
  final String? centerLabel;

  /// 가운데 합계 — 원까지("1,240,000원"). 줄여 쓰지 않는다.
  final String? centerAmount;

  /// 가운데 글이 구멍에 들어가는지 바뀔 때(그린 뒤 한 번 — 처음 들어가면 부르지 않는다).
  final ValueChanged<bool>? onFitChanged;

  /// 툴팁 값 — 기본 원까지.
  final String Function(double value)? valueFormatter;

  @override
  State<PDonutChart> createState() => _PDonutChartState();
}

class _PDonutChartState extends State<PDonutChart> {
  int? _active;
  Offset? _touch;
  bool _reported = true;

  void _report(bool fits) {
    if (fits == _reported) return;
    _reported = fits;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFitChanged?.call(fits);
    });
  }

  void _close() {
    if (_active == null) return;
    setState(() {
      _active = null;
      _touch = null;
    });
  }

  // 그리는 자리가 지름보다 좁으면(320 보다 좁은 화면) 자리 폭에 맞춰 지름을 줄인다 — 두께도 같은 셈(지름 ÷ 10 + 6)으로 다시
  // 낸다. 도넛이 자리 밖으로 잘려 나가지 않게(chart.md 도넛 · Layout "지원 폭"). 자리가 지름 이상이면 쓰는 쪽이 준 지름 그대로다
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _donut(
      context,
      constraints.hasBoundedWidth && constraints.maxWidth < widget.diameter
          ? constraints.maxWidth
          : widget.diameter,
    ),
  );

  Widget _donut(BuildContext context, double d) {
    final c = context.colors;
    final thickness = chartDonutThickness(d);
    final hole = d - 2 * thickness;
    final slices = [
      for (final s in widget.slices)
        if (s.amount > 0) s,
    ];
    if (_active != null && _active! >= slices.length) _active = null;

    final amountStyle = PTypography.t5.copyWith(
      fontWeight: FontWeight.w700,
      color: c.fgNeutral,
      fontFeatures: _tabular,
    );
    final labelStyle = PTypography.t2.copyWith(color: c.fgNeutralSubtle);
    // 가운데 글 묶음(폭 × 높이)의 모서리가 구멍(원) 안에 들어가는지 — 도넛 모양과 함께 글자 크기 설정을 따르지 않는다
    // (chart.yaml 가운데 합계 text-t5-static · 위 라벨 text-t2-static, groo-design #263). 재는 쪽도 그리는 쪽도
    // [TextScaler.noScaling] 이라 판정과 그림이 같은 글이다.
    var fits = true;
    if (widget.centerAmount != null) {
      final w = math.max(
        measureText(widget.centerAmount!, amountStyle),
        widget.centerLabel == null
            ? 0.0
            : measureText(widget.centerLabel!, labelStyle),
      );
      final h =
          chartTickLineHeight(amountStyle) +
          (widget.centerLabel == null ? 0 : chartTickLineHeight(labelStyle));
      fits = math.sqrt(w * w + h * h) / 2 <= hole / 2 - kChartHoleInset;
      _report(fits);
    }

    return PChartFrame(
      label: widget.label,
      description: widget.description,
      height: d,
      child: slices.isEmpty
          ? const SizedBox.shrink()
          : PChartDrawIn(
              builder: (context, progress) => LayoutBuilder(
                builder: (context, constraints) {
                  final left = (constraints.maxWidth - d) / 2;
                  Widget pie = SizedBox(
                    key: const ValueKey('chart-donut'),
                    width: d,
                    height: d,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: hole / 2,
                        // 12시에서 시계 방향
                        startDegreeOffset: -90,
                        borderData: FlBorderData(show: false),
                        sections: [
                          for (final s in slices)
                            PieChartSectionData(
                              value: s.amount,
                              color: s.color.of(c),
                              radius: thickness,
                              showTitle: false,
                            ),
                        ],
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions) return;
                            final i =
                                response?.touchedSection?.touchedSectionIndex;
                            if (i == null || i < 0) {
                              _close();
                              return;
                            }
                            if (_active == i) return;
                            setState(() {
                              _active = i;
                              _touch = event.localPosition;
                            });
                          },
                        ),
                      ),
                      duration: Duration.zero,
                    ),
                  );
                  if (progress < 1) {
                    // 조각 각도 — 12시에서 시계 방향으로 드러난다
                    pie = ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => SweepGradient(
                        transform: const GradientRotation(-math.pi / 2),
                        colors: const [
                          Color(0xFF000000),
                          Color(0xFF000000),
                          Color(0x00000000),
                          Color(0x00000000),
                        ],
                        stops: [0, progress, progress + 0.0001, 1],
                      ).createShader(rect),
                      child: pie,
                    );
                  }
                  return TapRegion(
                    onTapOutside: (_) => _close(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(left: left, top: 0, child: pie),
                        if (widget.centerAmount != null && fits)
                          Positioned(
                            left: left,
                            top: 0,
                            width: d,
                            height: d,
                            child: IgnorePointer(
                              child: Center(
                                key: const ValueKey('chart-donut-center'),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.centerLabel != null)
                                      Text(
                                        widget.centerLabel!,
                                        key: const ValueKey(
                                          'chart-donut-center-label',
                                        ),
                                        textScaler: TextScaler.noScaling,
                                        style: labelStyle,
                                      ),
                                    Text(
                                      widget.centerAmount!,
                                      key: const ValueKey(
                                        'chart-donut-center-amount',
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                      textScaler: TextScaler.noScaling,
                                      style: amountStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_active != null)
                          PChartTipLayer(
                            anchor: Offset(
                              left + (_touch?.dx ?? d / 2),
                              _touch?.dy ?? d / 2,
                            ),
                            side: PChartTipSide.beside,
                            child: PChartTooltip(
                              rows: [
                                PChartTooltipRow(
                                  swatch: slices[_active!].color.of(c),
                                  name: slices[_active!].label,
                                  value: (widget.valueFormatter ?? formatWon)(
                                    slices[_active!].amount,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
