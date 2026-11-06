import 'package:flutter/material.dart';

import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_month_model.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_tone.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';

/// 폰 달력 격자 — 칸 높이 103 고정 · 칸마다 위 1px 선 · 칸 안 글자 칩(I-09 9 10).
/// 격자가 화면보다 길면 화면이 스크롤하고, 마지막 주 아래에 탭 바 보상을 둔다.

/// 칸 높이.
const double kCalendarCellHeight = 103;

/// 요일 줄 · 격자의 좌우 안쪽 2.
const double kCalendarGridInset = PSpacing.x0_5;

/// 요일 줄 높이.
const double kCalendarWeekdayRowHeight = 32;

/// 칸 안 칩 높이(100% 글자) · 칩 사이.
const double kCalendarChipHeight = 18;
const double kCalendarChipGap = PSpacing.x0_5;

/// 칸 좌우 안쪽 1 · 칩 안쪽 좌우 3 — 간격 토큰에 없는 화면 값(그림 `.pc.tall` · `.ec`).
const double kCalendarCellInset = 1;
const double _chipPadX = 3;

/// 칸 위 선 1px 아래 여백 1 — 위 2(선 포함)에서 날 숫자가 시작한다.
const double kCalendarCellTopPad = 1;
const double _cellBorder = 1;

/// 칸 안 날 숫자 원 — 글자가 커지면 따라 커진다.
const double kCalendarDayCircle = 26;

/// 그날(`day`)에 걸친 일정 — 시작 시각 차례.
List<CalendarEvent> eventsOnDay(List<CalendarEvent> all, DateTime day) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
  return all.where((e) {
    return !(e.end.isBefore(dayStart) || e.start.isAfter(dayEnd));
  }).toList()..sort((a, b) => a.start.compareTo(b.start));
}

/// 'YYYY-MM-DD'.
String calendarDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 달 격자에 그릴 날 — 일요일 시작, 앞뒤 이웃 달 칸 포함, 5주 달은 5줄.
List<DateTime> calendarGridDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final lead = first.weekday % 7;
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final weeks = ((lead + daysInMonth) / 7).ceil();
  return [
    for (var i = 0; i < weeks * 7; i++)
      DateTime(first.year, first.month, 1 - lead + i),
  ];
}

/// 요일 줄 — 높이 32 · t3 · 평일 fg-neutral-subtle · 일 fg-critical · 토 지금 색 그대로(fg-brand).
class CalendarWeekdayRow extends StatelessWidget {
  const CalendarWeekdayRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labels = weekdayLabels();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCalendarGridInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kCalendarWeekdayRowHeight),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    labels[i],
                    style: PTypography.t3.copyWith(
                      color: switch (i) {
                        0 => c.fgCritical,
                        6 => c.fgBrand,
                        _ => c.fgNeutralSubtle,
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 칸 안 날 숫자 원의 한 변 — 글자가 커지면 따라 커진다.
double calendarNumberBox(TextScaler s) => s
    .scale(PTypography.t4.fontSize! * PTypography.t4.height!)
    .clamp(kCalendarDayCircle, double.infinity);

/// 칸 안 칩 한 줄 높이 — 글자 크기를 곱한다.
double calendarChipHeight(TextScaler s) =>
    s.scale(kCalendarChipHeight).clamp(kCalendarChipHeight, double.infinity);

/// 칸 안 칩 자리의 실측 — (칸 높이 − 위 2 − 날 숫자 − 사이 2) · 칩 · "+N개" · 줄 사이 2.
ChipMetrics calendarChipMetrics(TextScaler s) => ChipMetrics(
  avail:
      kCalendarCellHeight -
      PSpacing.x0_5 -
      calendarNumberBox(s) -
      kCalendarChipGap,
  chip: calendarChipHeight(s),
  more: s.scale(16).clamp(16, double.infinity),
  gap: kCalendarChipGap,
);

/// 달 격자 — 주마다 칸 7개. 칸 전체가 그날 시트를 여는 누르는 자리 하나다.
/// 칩 줄은 일정마다 달 전체에서 한 번 정한다(웹과 같은 규칙 — `calendar_month_model.dart`).
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.events,
    required this.holidays,
    required this.onDayTap,
  });

  final DateTime month;
  final List<CalendarEvent> events;

  /// 'YYYY-MM-DD' → 공휴일 이름. 공휴일을 끄면 빈 맵.
  final Map<String, String> holidays;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final days = calendarGridDays(month);
    final items = [
      for (final e in events) CalendarGridItem.ofEvent(e),
      for (final h in holidays.entries)
        CalendarGridItem.ofHoliday(h.key, h.value),
    ];
    final scaler = MediaQuery.textScalerOf(context);
    final metrics = calendarChipMetrics(scaler);
    final positions = calculateMonthPositions(items, month);
    final model = buildMonthModel(days, month, items, positions, metrics);
    final numberBox = calendarNumberBox(scaler);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCalendarGridInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellW = constraints.maxWidth / 7;
          return Column(
            children: [
              for (var w = 0; w < days.length ~/ 7; w++)
                SizedBox(
                  height: kCalendarCellHeight,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          for (var d = 0; d < 7; d++)
                            Expanded(
                              child: CalendarDayCell(
                                cell: model[w * 7 + d],
                                metrics: metrics,
                                isHoliday: holidays.containsKey(
                                  calendarDateKey(days[w * 7 + d]),
                                ),
                                onTap: () => onDayTap(days[w * 7 + d]),
                              ),
                            ),
                        ],
                      ),
                      // 이어지는 일정의 제목 — 이웃 조각 위로 넘쳐 그려야 해서 칸 위 한 겹에 따로 둔다
                      for (var d = 0; d < 7; d++)
                        for (var i = 0; i < model[w * 7 + d].slots.length; i++)
                          if (model[w * 7 + d].slots[i] case final slot?
                              when slot.labelDays > 0)
                            _bandLabel(
                              context,
                              slot: slot,
                              col: d,
                              row: i,
                              cellW: cellW,
                              numberBox: numberBox,
                              metrics: metrics,
                            ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _bandLabel(
    BuildContext context, {
    required ChipSlot slot,
    required int col,
    required int row,
    required double cellW,
    required double numberBox,
    required ChipMetrics metrics,
  }) {
    final tone = slot.item.isHoliday
        ? holidayTone(context)
        : eventTone(context, slot.item.event!);
    final leftInset = slot.part == ChipPart.first ? kCalendarCellInset : 0.0;
    // 띠가 이 일정의 끝 칸까지 이어지면 끝 칸 오른쪽 안쪽 1 이 빈다
    final rightInset = slot.labelReachesEnd ? kCalendarCellInset : 0.0;
    // 칸 위 선 1 + 위 여백 1 + 날 숫자 + 사이 2 + 줄마다
    final top =
        _cellBorder +
        kCalendarCellTopPad +
        numberBox +
        kCalendarChipGap +
        row * (metrics.chip + kCalendarChipGap);
    return Positioned(
      key: ValueKey('calendar-band-label-${slot.item.key}-$col'),
      left: col * cellW + leftInset,
      top: top,
      width: slot.labelDays * cellW - leftInset - rightInset,
      height: metrics.chip,
      child: IgnorePointer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x1),
            child: Text(
              slot.item.title,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: _chipStyle(tone),
            ),
          ),
        ),
      ),
    );
  }
}

const BorderRadius _chipRadius = BorderRadius.all(Radius.circular(PRounded.r1));

/// 칩 글 — t2 12 · 500, 줄 높이 18.
TextStyle _chipStyle(ChartTone tone) => PTypography.t2.copyWith(
  height: kCalendarChipHeight / 12,
  fontWeight: FontWeight.w500,
  color: tone.contrast,
);

/// 칸 하나 — 위 1px 선 · 날 숫자 원 · 줄 번호 자리의 글자 칩 · "+N개".
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.cell,
    required this.metrics,
    required this.isHoliday,
    required this.onTap,
  });

  final CellModel cell;
  final ChipMetrics metrics;

  /// 이 날이 공휴일인가 — 날 숫자 색.
  final bool isHoliday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final day = cell.day;
    final now = calendarNow();
    final isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;
    final isOutside = cell.isOutside;

    final Color dayColor;
    if (isOutside) {
      // 이웃 달은 날짜 숫자만 fg-disabled — 그 칸의 일정 · 휴일 이름은 이번 달과 같다(불투명도를 쓰지 않는다, 03-C 5A)
      dayColor = c.fgDisabled;
    } else if (isHoliday || day.weekday == DateTime.sunday) {
      dayColor = c.fgCritical;
    } else if (day.weekday == DateTime.saturday) {
      dayColor = c.fgBrand;
    } else {
      dayColor = c.fgNeutral;
    }

    final numberBox = calendarNumberBox(MediaQuery.textScalerOf(context));
    final dayNumber = Container(
      width: numberBox,
      height: numberBox,
      alignment: Alignment.center,
      // 오늘 = 옅은 원 bg-neutral-weak + 700 (date-picker.md — 브랜드 색으로 채우지 않는다)
      decoration: (isToday && !isOutside)
          ? BoxDecoration(color: c.bgNeutralWeak, shape: BoxShape.circle)
          : null,
      child: Text(
        '${day.day}',
        style: PTypography.t4.copyWith(
          color: dayColor,
          fontWeight: isToday && !isOutside ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    // 누르는 자리 — ds PressArea(누름 · 키보드). 누르는 동안 칸 바탕이 bg-layer-default-pressed(DESIGN.md 눌림 = 역할의
    // -pressed 색, 원장 주 띠 날짜 칸과 같다). Material 물결은 두지 않는다. 날짜 칸이라 줄지 않는다(date-picker.md).
    return PressArea(
      key: const ValueKey('calendar-day-cell'),
      enabled: true,
      onTap: onTap,
      touchMin: 0,
      semantics: (child, enabled, tap) => Semantics(
        container: true,
        button: true,
        excludeSemantics: true,
        label: '${monthDayDow(day)}, ${l.calEventTotalCount(cell.total)}',
        onTap: tap,
        child: child,
      ),
      builder: (context, pressed, _) => ColoredBox(
        color: pressed ? c.bgLayerDefaultPressed : const Color(0x00000000),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.strokeNeutralSubtle)),
          ),
          // 위 2 = 선 1 + 1
          child: Padding(
            padding: const EdgeInsets.only(top: kCalendarCellTopPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: dayNumber),
                const SizedBox(height: kCalendarChipGap),
                for (final slot in cell.slots)
                  slot == null
                      // 띠가 줄을 맞추려고 남긴 빈 줄 — 칩과 같은 높이
                      ? SizedBox(height: metrics.chip + metrics.gap)
                      : _EventChip(slot: slot, height: metrics.chip),
                if (cell.hidden > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _chipPadX),
                    // 개수라 말줄임 대신 칸 폭에 맞춰 줄여 보인다(글자 200% 에서도 "+3개" 가 읽힌다)
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.calMoreEvents(cell.hidden),
                        maxLines: 1,
                        softWrap: false,
                        style: PTypography.t2.copyWith(
                          color: c.fgNeutralMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

/// 칩 한 줄 — 높이 18(글자 크기를 곱한다) · 모서리 4 · 한 줄 끝 말줄임. 이어지는 일정은 첫 · 사이 · 끝 조각이 이웃 칸으로
/// 이어지고(연결 변은 안쪽 0) 제목은 주마다 한 번 위 겹(`CalendarMonthGrid._bandLabel`)에 그린다.
class _EventChip extends StatelessWidget {
  const _EventChip({required this.slot, required this.height});

  final ChipSlot slot;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tone = slot.item.isHoliday
        ? holidayTone(context)
        : eventTone(context, slot.item.event!);
    const r = Radius.circular(PRounded.r1);
    final part = slot.part;
    final radius = switch (part) {
      ChipPart.none => _chipRadius,
      ChipPart.first => const BorderRadius.horizontal(left: r),
      ChipPart.last => const BorderRadius.horizontal(right: r),
      ChipPart.middle => BorderRadius.zero,
    };
    final leftInset = part == ChipPart.none || part == ChipPart.first;
    final rightInset = part == ChipPart.none || part == ChipPart.last;
    return Padding(
      padding: EdgeInsets.only(
        left: leftInset ? kCalendarCellInset : 0,
        right: rightInset ? kCalendarCellInset : 0,
        bottom: kCalendarChipGap,
      ),
      child: Container(
        height: height,
        padding: part == ChipPart.none
            ? const EdgeInsets.symmetric(horizontal: _chipPadX)
            : EdgeInsets.zero,
        decoration: BoxDecoration(color: tone.weak, borderRadius: radius),
        alignment: Alignment.centerLeft,
        child: part == ChipPart.none
            ? Text(
                slot.item.title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: _chipStyle(tone),
              )
            : null,
      ),
    );
  }
}
