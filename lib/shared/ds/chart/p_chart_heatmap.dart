import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/core/format/date.dart' show fitWeekdayRowLabels;
import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_parts.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';

/// 열지도 줄 — 시간대 하나. [label] 은 이름("저녁" · 13 · 700), [sub] 는 시간("18~22시" · 11 · fg-neutral-subtle).
class PHeatmapRow {
  const PHeatmapRow({required this.key, required this.label, this.sub});

  final String key;
  final String label;
  final String? sub;
}

/// 열지도 칸 열 — 요일 하나("수" · 12 · fg-neutral-subtle). [label] 은 툴팁 · 읽는 이름의 글이고, 칸 위 머리는 [head](없으면
/// [label])다. 요일 머리는 영어 두 글자("Mo")이고 칸에 들지 않으면 한 글자([narrowHead] — "M")로 줄인다 — 모든 칸에
/// [narrowHead] 가 있을 때 칸 하나라도 두 글자가 넘치면 모두 한 글자다. 줄은 바꾸지 않는다(international-design.mdx "날짜",
/// groo-design #256 — 날짜 고르기 · 캘린더의 요일 줄과 같은 판정 [fitWeekdayRowLabels]).
class PHeatmapColumn {
  const PHeatmapColumn({
    required this.key,
    required this.label,
    this.head,
    this.narrowHead,
  });

  final String key;
  final String label;
  final String? head;
  final String? narrowHead;
}

const _tabular = [FontFeature.tabularFigures()];

/// 시간대 라벨 — 이름 13 · 700, 시간 11.
final TextStyle _rowLabelStyle = PTypography.t3.copyWith(
  fontWeight: FontWeight.w700,
);
const TextStyle _rowSubStyle = PTypography.t1;

/// 글 한 줄 높이(글자 크기 13 / 18 처럼 토큰 그대로).
double _lineOf(TextStyle style) => style.fontSize! * style.height!;

/// 열지도 — 요일 × 시간 같은 두 축의 세기. 왼쪽 시간대 라벨 열 56 + 요일 칸, 위 요일 머리 12. 칸은 정사각형 · 모서리 4 ·
/// 사이 6. 세기는 다섯 단계 — 브랜드 채움을 카드 면에 18 · 35 · 55 · 76 · 100% 섞은 색(가장 큰 값의 8 · 22 · 45 · 75%
/// 에서 끊는다), 값이 없으면 bg-neutral-weak. 가장 큰 칸에 고리를 두르지 않는다.
///
/// 열지도는 그림(디자인 틀)이라 칸 안 글 · 요일 머리 · 시간대 라벨이 글자 크기 설정을 따르지 않는다(chart.md "글자 크기" ·
/// DESIGN.md Typography "그대로 두는 것", groo-design #260) — 값은 툴팁 · 표로 보기에서 크게 읽는다.
///
/// 칸에 금액을 적는 것은 칸 폭이 [textMinCellWidth](112) 이상일 때뿐이다 — 원까지 11 / 15 · 700 · 고정폭 숫자(빈 칸은
/// "—" fg-neutral-subtle). 폰은 늘 좁아 세기 색만 칠한다 — 좁다고 돈을 줄여 쓰거나 글자를 줄이지 않는다. 글자색은 단계마다
/// 칸 바탕 위 4.5 를 넘는 쪽(라이트 76 · 100% 만 흰 글자, 다크는 전부 fg-neutral).
///
/// 칸을 누르면 툴팁(머리 "수요일 저녁 18~22시" · 줄 "■ 지출 35,000원", 네모는 그 칸의 세기 색)이 칸 위에 뜬다 — 손을 떼도
/// 남고, 다른 곳을 누르면 닫힌다. 값은 칸 글자가 아니라 툴팁 · 표로 보기에서 읽는다.
class PHeatmap extends StatefulWidget {
  const PHeatmap({
    super.key,
    required this.label,
    required this.rows,
    required this.columns,
    required this.values,
    this.formatValue,
    this.valueLabel,
    this.noValueText,
    this.textMinCellWidth = kHeatTextMinCellWidth,
    this.tooltipLabel,
    this.description,
  });

  /// 요약 이름 — "10월 요일 · 시간대별 지출, 가장 많은 때 토요일 저녁".
  final String label;
  final String? description;
  final List<PHeatmapRow> rows;
  final List<PHeatmapColumn> columns;

  /// 줄 × 칸 — 0 · null 은 값 없음.
  final List<List<double?>> values;

  /// 칸 · 툴팁의 값 — 기본 원까지("35,000원").
  final String Function(double value)? formatValue;

  /// 툴팁 줄의 이름 — 기본 "지출"("■ 지출 35,000원").
  final String? valueLabel;

  /// 값이 없는 칸의 툴팁 값.
  final String? noValueText;

  /// 칸 폭이 이보다 좁으면 칸에 글을 두지 않는다 — 기본 112.
  final double textMinCellWidth;

  /// 툴팁 머리 — 기본 "{요일} {시간대} {시간}".
  final String Function(PHeatmapRow row, PHeatmapColumn column)? tooltipLabel;

  @override
  State<PHeatmap> createState() => _PHeatmapState();
}

class _PHeatmapState extends State<PHeatmap> {
  ({int row, int col})? _active;

  // 툴팁은 Overlay 에 띄운다 — 위로 뜰지 아래로 뒤집을지를 차트 상자가 아니라 화면 기준으로 정한다(chart.yaml
  // heatmap tooltip placement 칸 위 · offset 8 · viewportMargin 8 — Q-012-6). 칸 위 자리는 눌렀을 때 화면 좌표로 적어 둔다.
  final GlobalKey _stackKey = GlobalKey();
  OverlayEntry? _entry;
  Offset _anchorGlobal = Offset.zero;
  double _max = 0;
  ScrollPosition? _scroll;

  void _open(int row, int col, Offset anchorLocal) {
    final box = _stackKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached) {
      _anchorGlobal = box.localToGlobal(anchorLocal);
    }
    setState(() => _active = (row: row, col: col));
    if (_entry == null) {
      final overlay = Overlay.of(context);
      _entry = OverlayEntry(builder: _buildTip);
      overlay.insert(_entry!);
      // 화면이 밀리면 띄운 자리가 어긋난다 — 닫는다
      _scroll = Scrollable.maybeOf(context)?.position?..addListener(_close);
    } else {
      _entry!.markNeedsBuild();
    }
  }

  void _close() {
    _removeEntry();
    if (_active == null || !mounted) return;
    setState(() => _active = null);
  }

  void _removeEntry() {
    _scroll?.removeListener(_close);
    _scroll = null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  @override
  void didUpdateWidget(PHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 값이 바뀌면 떠 있는 툴팁도 다시 만든다(빌드 중에는 건드릴 수 없다)
    if (_entry != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _entry?.markNeedsBuild(),
      );
    }
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  Widget _buildTip(BuildContext overlayContext) {
    final active = _active;
    if (!mounted || active == null) return const SizedBox.shrink();
    if (active.row >= widget.rows.length ||
        active.col >= widget.columns.length) {
      return const SizedBox.shrink();
    }
    final overlayBox = Overlay.of(context).context.findRenderObject();
    final anchor = overlayBox is RenderBox && overlayBox.attached
        ? overlayBox.globalToLocal(_anchorGlobal)
        : _anchorGlobal;
    final c = context.colors;
    final fmt = widget.formatValue ?? formatWon;
    return Positioned.fill(
      child: IgnorePointer(
        child: DefaultTextStyle(
          style: const TextStyle(decoration: TextDecoration.none),
          child: CustomSingleChildLayout(
            delegate: PChartTipLayout(
              anchor: anchor,
              side: PChartTipSide.above,
            ),
            child: _tip(
              c,
              fmt,
              widget.rows[active.row],
              widget.columns[active.col],
              _max,
              active,
            ),
          ),
        ),
      ),
    );
  }

  /// 칸에 적힐 글 가운데 가장 넓은 것의 폭 — 빈 칸의 "—" 도 센다.
  double _widestValue(
    BuildContext context,
    String Function(double) fmt,
    double max,
  ) {
    final style = PTypography.t1.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    );
    var widest = 0.0;
    void measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: TextScaler.noScaling,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }

    for (var r = 0; r < widget.rows.length; r++) {
      for (var c = 0; c < widget.columns.length; c++) {
        final v = _value(r, c);
        measure(heatStep(v, max) < 0 ? '—' : fmt(v!));
      }
    }
    return widest;
  }

  double? _value(int r, int c) {
    if (r >= widget.values.length) return null;
    final row = widget.values[r];
    return c < row.length ? row[c] : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fmt = widget.formatValue ?? formatWon;
    var max = 0.0;
    for (final row in widget.values) {
      for (final v in row) {
        if (v != null && v > 0) max = math.max(max, v);
      }
    }
    _max = max;
    final texts = heatTextColors(c);
    final cols = widget.columns.length;
    final hasSub = widget.rows.any((r) => r.sub != null);

    return PChartFrame(
      label: widget.label,
      description: widget.description,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = math.max(
            0.0,
            (constraints.maxWidth - kHeatLabelColumn - kHeatGap * cols) /
                math.max(1, cols),
          );
          // 칸 폭이 기준(112) 이상이어도 글이 칸보다 넓으면 글을 뺀다 — 세기 색만(03E-026b). 좁다고 돈을 줄이거나 글자를
          // 줄여 맞추지 않는다
          final showText =
              cell >= widget.textMinCellWidth &&
              _widestValue(context, fmt, max) <= cell - kHeatCellTextPadding;
          // 줄 높이 — 칸(정사각형)과 시간대 라벨(13 / 18 + 11 / 15) 중 큰 쪽. 글자 크기 설정을 따르지 않으므로 글 줄 높이 그대로다
          final labelH =
              _lineOf(_rowLabelStyle) + (hasSub ? _lineOf(_rowSubStyle) : 0);
          final rowH = math.max(cell, labelH);
          final headStyle = PTypography.t2.copyWith(color: c.fgNeutralSubtle);
          final headH = _lineOf(headStyle);
          final wideHeads = [
            for (final col in widget.columns) col.head ?? col.label,
          ];
          final heads = widget.columns.every((col) => col.narrowHead != null)
              ? fitWeekdayRowLabels(
                  cell,
                  headStyle,
                  labels: wideHeads,
                  narrow: [for (final col in widget.columns) col.narrowHead!],
                )
              : wideHeads;
          double cellLeft(int col) =>
              kHeatLabelColumn + kHeatGap + col * (cell + kHeatGap);
          double cellTop(int row) => headH + kHeatGap + row * (rowH + kHeatGap);
          return TapRegion(
            onTapOutside: (_) => _close(),
            child: Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                Column(
                  key: const ValueKey('chart-heatmap'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: kHeatGap,
                  children: [
                    SizedBox(
                      height: headH,
                      child: Row(
                        children: [
                          const SizedBox(width: kHeatLabelColumn + kHeatGap),
                          for (var col = 0; col < cols; col++) ...[
                            SizedBox(
                              width: cell,
                              child: Text(
                                heads[col],
                                key: ValueKey('chart-heatmap-column-$col'),
                                semanticsLabel: widget.columns[col].label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                textScaler: TextScaler.noScaling,
                                style: headStyle,
                              ),
                            ),
                            if (col < cols - 1) const SizedBox(width: kHeatGap),
                          ],
                        ],
                      ),
                    ),
                    for (var r = 0; r < widget.rows.length; r++)
                      SizedBox(
                        height: rowH,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: kHeatLabelColumn,
                              height: rowH,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.rows[r].label,
                                    key: ValueKey('chart-heatmap-row-$r'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textScaler: TextScaler.noScaling,
                                    style: _rowLabelStyle.copyWith(
                                      color: c.fgNeutral,
                                    ),
                                  ),
                                  if (widget.rows[r].sub != null)
                                    Text(
                                      widget.rows[r].sub!,
                                      key: ValueKey('chart-heatmap-row-sub-$r'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textScaler: TextScaler.noScaling,
                                      style: _rowSubStyle.copyWith(
                                        color: c.fgNeutralSubtle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: kHeatGap),
                            for (var col = 0; col < cols; col++) ...[
                              _Cell(
                                key: ValueKey('chart-heatmap-cell-$r-$col'),
                                size: cell,
                                step: heatStep(_value(r, col), max),
                                text: showText
                                    ? (heatStep(_value(r, col), max) < 0
                                          ? '—'
                                          : fmt(_value(r, col)!))
                                    : null,
                                colors: c,
                                textColors: texts,
                                onTap: () => _open(
                                  r,
                                  col,
                                  Offset(cellLeft(col) + cell / 2, cellTop(r)),
                                ),
                              ),
                              if (col < cols - 1)
                                const SizedBox(width: kHeatGap),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tip(
    PColors c,
    String Function(double) fmt,
    PHeatmapRow row,
    PHeatmapColumn col,
    double max,
    ({int row, int col}) active,
  ) {
    final v = _value(active.row, active.col);
    final step = heatStep(v, max);
    final head =
        widget.tooltipLabel?.call(row, col) ??
        [col.label, row.label, ?row.sub].join(' ');
    return PChartTooltip(
      head: head,
      rows: [
        PChartTooltipRow(
          swatch: step < 0 ? c.bgNeutralWeak : heatStepColor(c, step),
          name: widget.valueLabel ?? dsL(context)?.dsChartHeatValue ?? '지출',
          value: step < 0
              ? (widget.noValueText ?? dsL(context)?.dsChartHeatNone ?? '없음')
              : fmt(v!),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.size,
    required this.step,
    required this.text,
    required this.colors,
    required this.textColors,
    required this.onTap,
  });

  final double size;
  final int step;
  final String? text;
  final PColors colors;
  final List<Color> textColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => onTap(),
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PRounded.r1),
        color: step < 0 ? colors.bgNeutralWeak : heatStepColor(colors, step),
      ),
      child: text == null
          ? null
          : Text(
              text!,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textScaler: TextScaler.noScaling,
              style: PTypography.t1.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: _tabular,
                color: step < 0 ? colors.fgNeutralSubtle : textColors[step],
              ),
            ),
    ),
  );
}
