import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart' show weekdayRowScaler;

// 날짜 칸 하나 — 달력(p_date_picker.dart)이 그리고, 카탈로그 견본이 상태별로 한 칸씩 그린다. 웹
// `date-picker-day.tsx` 와 같은 값 · 같은 겹침 규칙이다.

/// 칸 높이(최소) · 원 크기 — date-picker.yaml cell.height 48 · dayVisual.size 42(칸 위 3 · 가로 가운데).
/// 칸 · 머리 · 요일 줄은 **최소** 48 이고 글이 크면 그만큼만 늘어난다 — 글자만 배율을 따르고 원 42 · 이전 · 다음 40 은 px
/// 그대로다(03-C 결정 1B).
const double kDatePickerCellHeight = 48;
const double kDatePickerDaySize = 42;

/// 숫자 글의 줄 높이(t5 16 / 22) — 글자 배율을 곱하면 칸이 얼마나 커야 하는지 나온다.
const double _kDayLineHeight = 22;

/// 칸 높이 — 최소 48, 글이 원 42 보다 크면 글 + 위아래 3. 날짜 숫자는 글자 크기 200% 에서 멈추므로([weekdayRowScaler],
/// groo-design #258) 칸도 멈춘 글로 잰다 — 200% 이상이면 44 + 6 = 50(6주 300). [scaler] 는 화면 배율 그대로 넘긴다.
double datePickerCellHeight(TextScaler scaler) => math.max(
  kDatePickerCellHeight,
  math.max(
        kDatePickerDaySize,
        weekdayRowScaler(scaler).scale(_kDayLineHeight),
      ) +
      6,
);

/// 머리 · 요일 줄 · 달 이름 줄 높이 — 최소 48, 글줄([lineHeight])이 더 크면 그만큼.
double datePickerRowHeight(TextScaler scaler, {double lineHeight = 22}) =>
    math.max(kDatePickerCellHeight, scaler.scale(lineHeight));

/// 원 크기 — 칸이 44 보다 좁으면(320 화면) 칸 폭 − 2(date-picker.yaml dayVisual.size).
double datePickerDaySize(double cellWidth) =>
    math.min(kDatePickerDaySize, cellWidth - 2);

/// 한 날짜의 모양을 정하는 상태 — 달력이 셈해 넘긴다. 겹침 규칙은 date-picker.md "상태가 겹칠 때".
@immutable
class PDatePickerDayState {
  const PDatePickerDayState({
    this.today = false,
    this.selected = false,
    this.rangeStart = false,
    this.rangeEnd = false,
    this.inRange = false,
    this.complete = false,
    this.singleDayRange = false,
    this.disabled = false,
    this.readOnly = false,
  });

  final bool today;
  final bool selected;
  final bool rangeStart;
  final bool rangeEnd;
  final bool inRange;

  /// 기간이 시작 · 끝 모두 골라졌다 — 띠는 완성된 기간에만.
  final bool complete;

  /// 하루짜리 기간(시작 = 끝) — 띠가 없다.
  final bool singleDayRange;
  final bool disabled;
  final bool readOnly;
}

/// 날짜의 톤 — 읽기 전용 > 고름 > 막힘 > 기간 사이 > 오늘 > 보통.
enum PDatePickerDayTone {
  enabled,
  today,
  selected,
  inRange,
  disabled,
  readOnly,
}

PDatePickerDayTone datePickerDayTone(PDatePickerDayState s) => s.readOnly
    ? PDatePickerDayTone.readOnly
    : s.selected
    ? PDatePickerDayTone.selected
    : s.disabled
    ? PDatePickerDayTone.disabled
    : s.inRange
    ? PDatePickerDayTone.inRange
    : s.today
    ? PDatePickerDayTone.today
    : PDatePickerDayTone.enabled;

/// 기간 띠의 자리 — 시작 칸은 원 가운데부터 오른쪽, 끝 칸은 왼쪽부터 원 가운데까지, 사이 칸은 칸 폭 전체.
enum PDatePickerBand { start, middle, end }

PDatePickerBand? datePickerBand(PDatePickerDayState s) {
  if (!s.complete || s.singleDayRange) return null;
  if (s.rangeStart) return PDatePickerBand.start;
  if (s.rangeEnd) return PDatePickerBand.end;
  if (s.inRange) return PDatePickerBand.middle;
  return null;
}

/// 숫자 글 — 16 / 22 · 500, 숫자 폭을 같게. 오늘은 700.
TextStyle datePickerDayText(Color color, {bool bold = false}) =>
    PTypography.t5.copyWith(
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// 날짜 칸 — 칸 전체(폭 [width] × 높이 48)가 누르는 자리다. 원 42(칸 가운데) · 숫자 · 기간 띠.
///
///   보통       숫자 fg-neutral-muted · 원 없음
///   누름       원 bg-neutral-weak-alpha-pressed(터치는 누르는 동안). 오늘(옅은 원) · 기간 사이 날(띠) 위에서는 불투명
///              bg-neutral-weak-pressed. 날짜는 줄지 않는다. 고른 날 · 막힌 날 · 읽기 전용에는 없다
///   오늘       원 bg-neutral-weak + 숫자 700 · fg-neutral. 고른 날 · 기간 안에서도 700 은 남는다
///   고름       원 bg-neutral-inverted + 숫자 fg-neutral-inverted — 오늘이어도 이 모양
///   기간 사이   원 없이 띠(bg-neutral-weak, 원 높이)
///   막힌 날    fg-disabled + 취소선. 미완성 기간의 시작이면 취소선을 긋지 않는다. 누르면 아무 일도 없다
///   읽기 전용   원 stroke-neutral-solid + 숫자 fg-neutral-inverted. 누르면 아무 일도 없다
///
/// 읽기 — 이름 있는 버튼([label] "2026년 10월 15일 목요일"), 고른 날 · 기간 사이는 선택됨, 막힌 날 · 읽기 전용은 비활성.
class PDatePickerDayCell extends StatefulWidget {
  const PDatePickerDayCell({
    super.key,
    required this.date,
    required this.state,
    required this.label,
    required this.width,
    required this.onTap,
    this.focused = false,
  });

  final DateTime date;
  final PDatePickerDayState state;

  /// 키보드 초점이 온 날 — 원 둘레 안쪽에 링(stroke-focus-ring 2). 달력이 키보드로 옮긴 때만 켠다(터치 모드에는 없다).
  final bool focused;

  /// 버튼 이름 — "2026년 10월 15일 목요일"(읽기 전용이면 뒤에 말이 붙은 것).
  final String label;

  /// 칸 폭 — 달력 폭 ÷ 7.
  final double width;
  final VoidCallback onTap;

  @override
  State<PDatePickerDayCell> createState() => _PDatePickerDayCellState();
}

class _PDatePickerDayCellState extends State<PDatePickerDayCell> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.state;
    final tone = datePickerDayTone(s);
    final band = datePickerBand(s);
    final day = datePickerDaySize(widget.width);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final cellHeight = datePickerCellHeight(MediaQuery.textScalerOf(context));

    // 눌리는 날 — 보통은 투명 짝 bg-neutral-weak-alpha-pressed(03-C 결정 2B), 오늘 · 기간 사이 날은 불투명
    // bg-neutral-weak-pressed(투명 색을 띠에 얹으면 또 다른 색이 된다). 그 밖에는 없다
    final pressedColor = switch (tone) {
      PDatePickerDayTone.enabled => c.bgNeutralWeakAlphaPressed,
      PDatePickerDayTone.today ||
      PDatePickerDayTone.inRange => c.bgNeutralWeakPressed,
      _ => null,
    };
    final circle = switch (tone) {
      PDatePickerDayTone.selected => c.bgNeutralInverted,
      PDatePickerDayTone.readOnly => c.strokeNeutralSolid,
      PDatePickerDayTone.today =>
        _pressed && pressedColor != null ? pressedColor : c.bgNeutralWeak,
      _ =>
        _pressed && pressedColor != null
            ? pressedColor
            : const Color(0x00000000),
    };
    final textColor = switch (tone) {
      PDatePickerDayTone.enabled => c.fgNeutralMuted,
      PDatePickerDayTone.today => c.fgNeutral,
      PDatePickerDayTone.selected => c.fgNeutralInverted,
      PDatePickerDayTone.inRange => c.fgNeutralMuted,
      PDatePickerDayTone.disabled => c.fgDisabled,
      PDatePickerDayTone.readOnly => c.fgNeutralInverted,
    };
    // 미완성 기간의 시작은 막힌 날이어도 취소선을 긋지 않는다
    final strike = s.disabled && !s.readOnly && !(s.rangeStart && !s.complete);
    final tappable = !s.disabled && !s.readOnly;

    // 날짜 숫자는 글자 크기 200% 에서 멈춘다(일곱 칸 격자, groo-design #258) — 칸 높이도 같은 배율로 잰다
    final text = Text(
      '${widget.date.day}',
      maxLines: 1,
      softWrap: false,
      textScaler: weekdayRowScaler(MediaQuery.textScalerOf(context)),
      style: datePickerDayText(textColor, bold: s.today).copyWith(
        decoration: strike ? TextDecoration.lineThrough : TextDecoration.none,
        decorationColor: textColor,
      ),
    );

    Widget visual = SizedBox(
      width: widget.width,
      height: cellHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (band != null)
            Positioned(
              key: ValueKey('date-band-${band.name}'),
              left: band == PDatePickerBand.start ? widget.width / 2 : 0,
              right: band == PDatePickerBand.end ? widget.width / 2 : 0,
              top: (cellHeight - day) / 2,
              height: day,
              child: ColoredBox(color: c.bgNeutralWeak),
            ),
          AnimatedContainer(
            key: const ValueKey('date-day-visual'),
            duration: reduceMotion ? Duration.zero : PDuration.colorTransition,
            curve: PEasing.easing,
            width: day,
            height: day,
            decoration: BoxDecoration(
              color: circle,
              borderRadius: BorderRadius.circular(PRounded.full),
              // 초점 링 — 원 둘레 안쪽 2(date-picker.yaml focused.focusRing offset −2)
              border: widget.focused
                  ? Border.all(color: c.strokeFocusRing, width: 2)
                  : null,
            ),
          ),
          text,
        ],
      ),
    );

    visual = MouseRegion(
      cursor: tappable
          ? SystemMouseCursors.click
          : (s.readOnly
                ? SystemMouseCursors.basic
                : SystemMouseCursors.forbidden),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: pressedColor != null && tappable
            ? (_) => _setPressed(true)
            : null,
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: tappable ? widget.onTap : null,
        child: visual,
      ),
    );

    // 격자의 칸(cell)은 달력이 감싼다(role: cell) — 이 버튼이 그 안에 든다(03C-004)
    return Semantics(
      container: true,
      button: true,
      enabled: tappable,
      selected: s.selected || s.inRange,
      focused: widget.focused,
      label: widget.label,
      onTap: tappable ? widget.onTap : null,
      excludeSemantics: true,
      child: visual,
    );
  }
}

/// 앞뒤 달 날짜 — 흐리게 보이기만 하고 누르지 못한다(버튼이 아니다). 숫자는 보조 기술에 숨기되 칸은 남겨 요일 짝을 지킨다.
/// [show] 가 false 면 칸만 남기고 숫자를 그리지 않는다(이어지는 달 — 앞뒤 달 날짜는 비운다).
class PDatePickerOutsideCell extends StatelessWidget {
  const PDatePickerOutsideCell({
    super.key,
    required this.date,
    required this.width,
    this.show = true,
  });

  final DateTime date;
  final double width;
  final bool show;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: datePickerCellHeight(MediaQuery.textScalerOf(context)),
        child: show
            ? Center(
                child: Text(
                  '${date.day}',
                  key: const ValueKey('date-outside'),
                  maxLines: 1,
                  softWrap: false,
                  textScaler: weekdayRowScaler(
                    MediaQuery.textScalerOf(context),
                  ),
                  style: datePickerDayText(c.fgDisabled),
                ),
              )
            : null,
      ),
    );
  }
}
