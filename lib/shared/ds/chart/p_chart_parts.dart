import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart'
    show kPListStackBelowEm;
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

/// Chart 의 부품 — 차트 상자 · 툴팁 · 지표 타일 · 도넛 범례 · 표로 보기. 규칙은 p_chart.dart 머리 설명이다.

const _tabular = [FontFeature.tabularFigures()];

// ── 그려짐 ───────────────────────────────────────────────────

/// 그려짐 — 처음 그릴 때 한 번 300ms(막대 높이 · 선 길이 · 조각 각도), 모션 줄이기면 바로 그린다. [builder] 가 0 → 1 의
/// 진행을 받아 그린다. 다 그려진 뒤에는 늘 1 이다(다시 그려도 처음처럼 돌지 않는다).
class PChartDrawIn extends StatefulWidget {
  const PChartDrawIn({super.key, required this.builder});

  final Widget Function(BuildContext context, double progress) builder;

  @override
  State<PChartDrawIn> createState() => _PChartDrawInState();
}

class _PChartDrawInState extends State<PChartDrawIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PDuration.d6,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) =>
        widget.builder(context, PEasing.enter.transform(_controller.value)),
  );
}

// ── 차트 상자 ─────────────────────────────────────────────────

/// 차트 상자 — 카드 본문 안 폭 100% · 바탕 없음. 높이는 쓰는 자리가 정한다(고정 비율을 두지 않는다).
///
/// 접근성: 상자 하나가 이름 있는 이미지다 — [label] 이 요약 이름("10월 수입 · 지출 추이, 수입 4,200,000원 · …"),
/// [description] 이 대체 글(지표 타일 · 목록 범례의 요약). 안의 그림 · 툴팁은 보조 기술에서 뺀다 — 같은 값은 범례 · 표로 보기가
/// 준다.
class PChartFrame extends StatelessWidget {
  const PChartFrame({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.height,
  });

  /// 요약 이름 — "{기간} {무엇} — {핵심 값}".
  final String label;

  /// 대체가 되는 범례(지표 타일 · 목록)의 글 — 읽는 값.
  final String? description;

  /// 높이(px) — 쓰는 자리가 정한다.
  final double? height;

  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    image: true,
    label: label,
    value: description,
    child: ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('chart-frame'),
        width: double.infinity,
        height: height,
        child: child,
      ),
    ),
  );
}

// ── 툴팁 ─────────────────────────────────────────────────────

/// 툴팁 줄 "■ 라벨 값" — 색 네모 8(모서리 2) ↔ 라벨 6 · 라벨 13 fg-neutral-muted ↔ 값(12 이상) · 값 13 · 700 · fg-neutral ·
/// 고정폭 숫자(오른쪽).
class PChartTooltipRow extends StatelessWidget {
  const PChartTooltipRow({
    super.key,
    this.swatch,
    required this.name,
    required this.value,
  });

  /// 색 네모 — 없으면(지출 · 한도 같은 덧줄) 네모 없이 글만.
  final Color? swatch;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      key: const ValueKey('chart-tooltip-row'),
      children: [
        if (swatch != null) ...[
          Container(
            key: const ValueKey('chart-tooltip-swatch'),
            width: PSpacing.x2,
            height: PSpacing.x2,
            decoration: BoxDecoration(
              color: swatch,
              borderRadius: BorderRadius.circular(PRounded.r0_5),
            ),
          ),
          const SizedBox(width: PSpacing.x1_5),
        ],
        Text(
          name,
          key: const ValueKey('chart-tooltip-label'),
          style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
        ),
        const SizedBox(width: PSpacing.x3),
        Expanded(
          child: Text(
            value,
            key: const ValueKey('chart-tooltip-value'),
            textAlign: TextAlign.end,
            style: PTypography.t3.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: _tabular,
            ),
          ),
        ),
      ],
    );
  }
}

/// 툴팁 — 떠 있는 표면: bg-layer-floating · s3 · 모서리 12 · 위아래 10 · 좌우 12 · 최소 128 · 테두리 없음 · 머리 ↔ 줄 ·
/// 줄 사이 4. 머리는 날짜 · 기간(12 · fg-neutral-subtle). 터치로 띄우면 손을 떼도 남고, 다른 곳을 누르면 닫힌다.
class PChartTooltip extends StatelessWidget {
  const PChartTooltip({super.key, this.head, required this.rows});

  final String? head;
  final List<PChartTooltipRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 128),
      child: IntrinsicWidth(
        child: DecoratedBox(
          key: const ValueKey('chart-tooltip'),
          decoration: BoxDecoration(
            color: c.bgLayerFloating,
            borderRadius: BorderRadius.circular(PRounded.r3),
            boxShadow: context.shadows.s3,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x3,
              vertical: PSpacing.x2_5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PSpacing.x1,
              children: [
                if (head != null && head!.isNotEmpty)
                  Text(
                    head!,
                    key: const ValueKey('chart-tooltip-head'),
                    style: PTypography.t2.copyWith(color: c.fgNeutralSubtle),
                  ),
                ...rows,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 툴팁을 앵커 곁에 둔다 — [side] 가 [PChartTipSide.beside] 면 앵커 오른쪽 12(모자라면 왼쪽), [above] 면 앵커 위 8(모자라면
/// 아래). 가장자리와 8 을 지킨다. 크기는 툴팁이 정하므로 배치는 크기를 안 뒤에 한다. [above] 는 Overlay(화면 기준)에서 쓴다.
enum PChartTipSide { beside, above }

class PChartTipLayout extends SingleChildLayoutDelegate {
  PChartTipLayout({required this.anchor, required this.side});

  final Offset anchor;
  final PChartTipSide side;

  static const double _edge = PSpacing.x2;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: math.max(0, constraints.maxWidth - 2 * _edge));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double clampX(double x) => math.max(
      _edge,
      math.min(x, math.max(_edge, size.width - _edge - childSize.width)),
    );
    double clampY(double y) =>
        math.max(0, math.min(y, math.max(0, size.height - childSize.height)));
    switch (side) {
      case PChartTipSide.beside:
        final right = anchor.dx + PSpacing.x3;
        final x = right + childSize.width + _edge <= size.width
            ? right
            : anchor.dx - PSpacing.x3 - childSize.width;
        return Offset(clampX(x), clampY(anchor.dy - childSize.height / 2));
      case PChartTipSide.above:
        // 칸 위 8 — 화면 가장자리 8 안에 못 들어가면 아래로 뒤집고, 아래도 가장자리를 넘지 않게 민다
        final above = anchor.dy - PSpacing.x2 - childSize.height;
        final y = above >= _edge
            ? above
            : math.min(
                anchor.dy + PSpacing.x2,
                math.max(_edge, size.height - _edge - childSize.height),
              );
        return Offset(clampX(anchor.dx - childSize.width / 2), y);
    }
  }

  @override
  bool shouldRelayout(PChartTipLayout old) =>
      old.anchor != anchor || old.side != side;
}

/// 툴팁 층 — 차트 상자 위에 겹쳐 띄운다(터치를 받지 않는다). 상자 밖으로 나가지 않는다.
class PChartTipLayer extends StatelessWidget {
  const PChartTipLayer({
    super.key,
    required this.anchor,
    required this.side,
    required this.child,
  });

  final Offset anchor;
  final PChartTipSide side;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: CustomSingleChildLayout(
        delegate: PChartTipLayout(anchor: anchor, side: side),
        child: child,
      ),
    ),
  );
}

// ── 지표 타일 ─────────────────────────────────────────────────

/// 지표 타일 하나 — 계열 하나.
class PChartLegendItem {
  const PChartLegendItem({
    required this.key,
    required this.label,
    required this.color,
    required this.total,
    this.weak = false,
  });

  final String key;
  final String label;
  final PChartColor color;

  /// 합계 — 원까지 만든 글("4,200,000원").
  final String total;

  /// 같은 색의 옅은 단계 — 강조하지 않는 비교 계열의 점. 켠 타일 바탕은 그 색의 옅은 바탕 그대로다.
  final bool weak;
}

/// 지표 타일 높이 — 위 10 + 이름 18 + 2 + 합계 22 + 아래 10.
const double kChartLegendTileHeight = 62;

/// 지표 타일 최소 폭.
const double kChartLegendTileMinWidth = 100;

/// 선 · 막대 차트 위 지표 타일 — 범례 겸 합계. 타일 하나가 계열 하나, 누르면 그 계열을 켜고 끈다. 마지막 하나는 끌 수 없다
/// (잠김 — 눌러도 그대로이고 읽는 쪽에는 막힌 버튼이다). 켠 타일은 그 색의 옅은 바탕(테두리 없음), 끈 타일은 흰 면 + 안쪽 1px
/// stroke-neutral-weak. 타일 사이 8, 타일 ↔ 차트 8. 누르면 2px 거리 축소(모션 줄이기면 하지 않는다). 이름은 읽는 쪽에
/// "{이름} {합계}" 이고 켬 · 끔이 눌림 상태다.
class PChartLegendTiles extends StatelessWidget {
  const PChartLegendTiles({
    super.key,
    required this.items,
    this.hidden = const {},
    this.onHiddenChanged,
    this.semanticLabel,
  });

  final List<PChartLegendItem> items;

  /// 숨긴 계열의 key.
  final Set<String> hidden;
  final ValueChanged<Set<String>>? onHiddenChanged;

  /// 묶음의 이름.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shown = items.where((i) => !hidden.contains(i.key)).length;
    return Semantics(
      container: true,
      label: semanticLabel ?? dsL(context)?.dsChartLegend ?? '범례',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // 한 줄에 들어가는 개수 — 넘치면 줄바꿈하고, 줄마다 타일이 그 줄의 폭을 똑같이 나눈다(flex 1 1 0)
          final perLine = math.max(
            1,
            ((width + PSpacing.x2) / (kChartLegendTileMinWidth + PSpacing.x2))
                .floor(),
          );
          final lines = <List<PChartLegendItem>>[];
          for (var i = 0; i < items.length; i += perLine) {
            lines.add(items.sublist(i, math.min(i + perLine, items.length)));
          }
          return Column(
            key: const ValueKey('chart-legend-list'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PSpacing.x2,
            children: [
              for (final line in lines)
                Row(
                  spacing: PSpacing.x2,
                  children: [
                    for (final item in line)
                      Expanded(
                        child: _LegendTile(
                          item: item,
                          on: !hidden.contains(item.key),
                          locked: !hidden.contains(item.key) && shown <= 1,
                          onToggle: () {
                            final next = {...hidden};
                            if (hidden.contains(item.key)) {
                              next.remove(item.key);
                            } else {
                              next.add(item.key);
                            }
                            onHiddenChanged?.call(next);
                          },
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({
    required this.item,
    required this.on,
    required this.locked,
    required this.onToggle,
  });

  final PChartLegendItem item;
  final bool on;
  final bool locked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressArea(
      enabled: true,
      // 마지막 하나는 끌 수 없다
      onTap: locked ? null : onToggle,
      touchMin: 0,
      focusRing: const PFocusRingStyle(radius: PRounded.r3),
      semantics: (child, enabled, tap) => Semantics(
        button: true,
        toggled: on,
        enabled: !locked,
        onTap: locked ? null : tap,
        child: child,
      ),
      builder: (context, pressed, size) => PressScale(
        pressed: pressed && !locked,
        size: size,
        child: Container(
          key: ValueKey('chart-legend-tile-${item.key}'),
          constraints: const BoxConstraints(minHeight: kChartLegendTileHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.x3,
            vertical: PSpacing.x2_5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PRounded.r3),
            color: on ? item.color.subtleOf(c) : c.bgLayerDefault,
          ),
          // 끈 타일의 안쪽 1px 은 레이아웃을 밀지 않게 위에 덧그린다(웹 inset 그림자) — 켠 타일과 높이가 같다
          foregroundDecoration: on
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(PRounded.r3),
                  border: Border.all(
                    color: c.strokeNeutralWeak,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    key: const ValueKey('chart-legend-dot'),
                    width: PSpacing.x2,
                    height: PSpacing.x2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.weak
                          ? item.color.weakOf(c)
                          : item.color.of(c),
                    ),
                  ),
                  const SizedBox(width: PSpacing.x1_5),
                  Flexible(
                    child: Text(
                      item.label,
                      key: const ValueKey('chart-legend-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PSpacing.x0_5),
              Text(
                // 금액은 쉼표 뒤에서만 줄을 바꾼다 — 숫자 가운데 · "원" 앞에서 꺾지 않는다(v114)
                keepAllAmount(item.total),
                semanticsLabel: item.total,
                key: const ValueKey('chart-legend-total'),
                style: PTypography.t5.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 도넛 범례 ─────────────────────────────────────────────────

/// 도넛 범례 줄 하나 — 카테고리 하나.
class PChartDonutLegendItem {
  const PChartDonutLegendItem({
    required this.key,
    required this.label,
    required this.color,
    required this.percent,
    required this.amount,
    this.onTap,
  });

  final String key;
  final String label;
  final PChartColor color;

  /// "31%".
  final String percent;

  /// 원까지 — "384,400원".
  final String amount;

  /// 하위 카테고리가 있는 줄만 — 누르는 줄.
  final VoidCallback? onTap;
}

/// 도넛 범례 줄 최소 높이.
const double kChartDonutRowHeight = 44;

/// 도넛 범례 — 카테고리 목록. 줄마다 색 네모 10(모서리 2) · 이름 14 · % 14 fg-neutral-subtle · 금액 14 · 700 · "원", 사이 8,
/// 높이 44 이상. [PChartDonutLegendItem.onTap] 이 있는 줄만 누르는 줄이다 — List 줄처럼 카드 끝까지 [bleed] 만큼 넓게 그리고
/// (본문 여백 24 를 되돌린다) 글자는 그대로 선다. 눌린 줄은 `bg-layer-default-pressed` 알약(좌우 6 들어온 모서리 10).
class PChartDonutLegend extends StatelessWidget {
  const PChartDonutLegend({super.key, required this.items, this.bleed = 0});

  final List<PChartDonutLegendItem> items;

  /// 누르는 줄을 양옆으로 이만큼 넓힌다 — 카드 본문 여백(24)을 되돌릴 때 [PSpacing.x6]. 넓힌 자리는 눈에만 보이고 누르는
  /// 자리는 이 목록의 폭 안이다(Flutter 는 부모 상자 밖을 받지 않는다).
  final double bleed;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('chart-donut-legend'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in items)
        item.onTap == null
            ? _DonutRow(item: item)
            : _PressableDonutRow(item: item, bleed: bleed),
    ],
  );
}

class _DonutRow extends StatelessWidget {
  const _DonutRow({required this.item, this.pressed = false});

  final PChartDonutLegendItem item;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = PTypography.t4;
    final swatch = Container(
      key: const ValueKey('chart-donut-swatch'),
      width: PSpacing.x2_5,
      height: PSpacing.x2_5,
      decoration: BoxDecoration(
        color: item.color.of(c),
        borderRadius: BorderRadius.circular(PRounded.r0_5),
      ),
    );
    final label = Text(
      keepAll(item.label),
      semanticsLabel: item.label,
      key: const ValueKey('chart-donut-label'),
      style: base.copyWith(color: c.fgNeutral),
    );
    final percent = Text(
      item.percent,
      key: const ValueKey('chart-donut-percent'),
      style: base.copyWith(color: c.fgNeutralSubtle, fontFeatures: _tabular),
    );
    final amount = Text(
      keepAllAmount(item.amount),
      semanticsLabel: item.amount,
      key: const ValueKey('chart-donut-amount'),
      style: base.copyWith(
        color: c.fgNeutral,
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
      ),
    );
    // 줄 안 폭이 글자 16개(16em)보다 좁으면(큰 글자) 이름이 한 글자 폭이 되지 않게 % · 금액을 이름 아래로 내린다
    // (List "큰 글자에서 값을 본문 아래로" 와 같은 문턱 — I-06 20, 스펙 보강 질문)
    final narrowBelow =
        kPListStackBelowEm *
        MediaQuery.textScalerOf(context).scale(PTypography.t5.fontSize!);
    return ConstrainedBox(
      key: const ValueKey('chart-donut-row'),
      constraints: const BoxConstraints(minHeight: kChartDonutRowHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < narrowBelow) {
            return Padding(
              // 줄 위아래는 List 줄과 같은 12, 네모는 첫 글줄 가운데
              padding: const EdgeInsets.symmetric(vertical: PSpacing.x3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PSpacing.x2,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: (base.fontSize! * base.height! - PSpacing.x2_5) / 2,
                    ),
                    child: swatch,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        Wrap(spacing: PSpacing.x2, children: [percent, amount]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Row(
            spacing: PSpacing.x2,
            children: [
              swatch,
              Expanded(child: label),
              percent,
              amount,
            ],
          );
        },
      ),
    );
  }
}

class _PressableDonutRow extends StatelessWidget {
  const _PressableDonutRow({required this.item, required this.bleed});

  final PChartDonutLegendItem item;
  final double bleed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final row = PressArea(
          enabled: true,
          onTap: item.onTap,
          touchMin: 0,
          focusRing: const PFocusRingStyle(inset: true),
          semantics: (child, enabled, tap) =>
              Semantics(button: true, onTap: tap, child: child),
          builder: (context, pressed, size) => Stack(
            children: [
              // 눌림 바탕(알약) — 좌우 6 들어온 모서리 10(카드 16 − 6 — List 의 동심 모서리)
              Positioned.fill(
                left: PSpacing.x1_5,
                right: PSpacing.x1_5,
                child: AnimatedContainer(
                  key: const ValueKey('chart-donut-pill'),
                  duration: PDuration.colorTransition,
                  curve: PEasing.easing,
                  decoration: BoxDecoration(
                    color: pressed
                        ? c.bgLayerDefaultPressed
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(PRounded.r2_5),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: bleed),
                child: _DonutRow(item: item, pressed: pressed),
              ),
            ],
          ),
        );
        if (bleed == 0) return row;
        // 부모 폭보다 넓게 깐다 — 높이는 줄이 정하므로 OverflowBox(늘 최대 크기)가 아니라 이 상자를 쓴다
        return FractionallySizedBox(
          widthFactor:
              (constraints.maxWidth + 2 * bleed) /
              math.max(1, constraints.maxWidth),
          child: row,
        );
      },
    );
  }
}

// ── 표로 보기 ─────────────────────────────────────────────────

/// 표로 보기 열 — [align] 을 주지 않으면 첫 열은 왼쪽(그 줄의 이름), 나머지는 오른쪽(숫자).
class PChartDataColumn {
  const PChartDataColumn(this.label, {this.align});

  final String label;
  final TextAlign? align;
}

/// 표로 보기 — 날짜마다 값을 읽어야 하는 차트의 대체(앱은 단순한 표다 — Table 은 768 이상 전용). [visuallyHidden] 이 true(기본)
/// 면 눈에는 보이지 않고 보조 기술에만 줄마다 한 문장("이름, 열 값 …")으로 읽힌다. false 면 차트 아래 펼친 표다.
/// 첫 열은 그 줄의 이름(날짜), 돈은 원까지 만든 글을 넘긴다.
class PChartDataTable extends StatelessWidget {
  const PChartDataTable({
    super.key,
    required this.caption,
    required this.columns,
    required this.rows,
    this.visuallyHidden = true,
  });

  /// 표 이름 — "10월 날짜별 수입 · 지출".
  final String caption;
  final List<PChartDataColumn> columns;
  final List<List<String>> rows;
  final bool visuallyHidden;

  TextAlign _align(int i) =>
      columns[i].align ?? (i == 0 ? TextAlign.start : TextAlign.end);

  @override
  Widget build(BuildContext context) {
    if (visuallyHidden) {
      // 줄마다 "이름, 열 이름 값, …" — 표가 아니라 읽을 글로 준다
      final lines = [
        for (final row in rows)
          [
            row.first,
            for (var i = 1; i < row.length; i++)
              '${columns[i].label} ${row[i]}',
          ].join(', '),
      ];
      return Semantics(
        container: true,
        label: caption,
        value: lines.join('\n'),
        child: const SizedBox.shrink(key: ValueKey('chart-data-table')),
      );
    }
    final c = context.colors;
    return Column(
      key: const ValueKey('chart-data-table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: PSpacing.x2),
          child: Text(
            caption,
            style: PTypography.t3.copyWith(
              color: c.fgNeutralMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(PSpacing.x2),
                  child: Text(
                    columns[i].label,
                    textAlign: _align(i),
                    style: PTypography.t2.copyWith(
                      color: c.fgNeutralSubtle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (final row in rows)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.strokeNeutralWeak)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(PSpacing.x2),
                      child: Text(
                        row[i],
                        textAlign: _align(i),
                        style: PTypography.t3.copyWith(
                          color: c.fgNeutral,
                          fontFeatures: i == 0 ? null : _tabular,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
