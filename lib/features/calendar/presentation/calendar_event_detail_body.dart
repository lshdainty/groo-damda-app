import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event_detail_rules.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event_form_rules.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';

const double _rowIcon = 22;

/// 일정 상세의 본문(I-09b 6 · 1-2B) — 제목 + D-day 배지 아래 List 줄. 줄 차례 · 아이콘은 일정 폼과 같고(캘린더 · 라벨 · 시작 · 종료 ·
/// 반복 · 알림 · 장소 · 설명) 꺾쇠만 없다. 없는 값(라벨 · 알림 · 장소 · 설명)은 줄을 두지 않는다. 색은 줄 앞 점으로만 — 캘린더 줄 점은
/// 캘린더 색, 라벨 줄 점은 라벨 색이고 일정 색(`event.color`)은 어디에도 그리지 않는다(09-25 데이터 원칙).
class CalendarEventDetailBody extends StatelessWidget {
  const CalendarEventDetailBody({
    super.key,
    required this.event,
    required this.calendars,
    required this.today,
  });

  final CalendarEvent event;

  /// 캘린더 이름 · 색을 찾는 목록 — 못 찾으면 캘린더 줄을 두지 않는다.
  final List<UserCalendar> calendars;

  /// D-day 와 "올해" 를 가르는 오늘.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final e = event;
    final cal = e.calendarRowId == null
        ? null
        : calendars.where((x) => x.rowId == e.calendarRowId).firstOrNull;
    final labelName = (e.labelName ?? '').trim();
    final location = (e.location ?? '').trim();
    final description = (e.description ?? '').trim();
    final reminders = e.reminderMinutes;
    final dday = calendarDday(e.start, today);
    final imminent = calendarDdayImminent(dday);
    final labels = PTimePickerLabels.of(context);

    return LayoutBuilder(
      builder: (context, box) {
        Widget row({
          required String title,
          required IconData icon,
          required String value,
          Color? dot,
        }) => PListItem(
          title: title,
          prefix: Icon(icon, size: _rowIcon),
          suffix: PListSuffix(
            children: [CalendarRowValue(text: value, dot: dot).build(context)],
          ),
        );

        String timeOf(DateTime d) =>
            formatTimeValue(PTimeValue.fromDateTime(d), labels: labels);

        /// 시작 · 종료 줄 — 날짜 조각 + 시각 조각(+ 걸린 시간 조각). 조각은 자르지 않고 줄을 바꾼다.
        Widget when({
          required String title,
          required IconData icon,
          required List<String> pieces,
        }) => PListItem(
          title: title,
          prefix: Icon(icon, size: _rowIcon),
          // 조각 묶음도 값이다 — 좁은 줄에서 제목 아래로 내려가고 폭 제한은 ds 가 한다
          suffix: PListValue(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: PSpacing.x2,
              children: [for (final p in pieces) Text(keepAll(p))],
            ),
          ),
        );

        final startDay = formatDateValue(e.start, today);
        final endDay = formatDateValue(e.end, today);
        final duration = calendarDurationText(l, e);
        final multiDay =
            !(e.start.year == e.end.year &&
                e.start.month == e.end.month &&
                e.start.day == e.end.day);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상세 머리 — 제목 t7 20 / 27 · 700, 아래 8, D-day 배지 large 24. 좌우 24 · 아래 8(시트)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                0,
                PSpacing.globalGutter,
                PSpacing.x2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PSpacing.x2,
                children: [
                  Text(
                    keepAll(e.title),
                    key: const ValueKey('calendar-detail-title'),
                    style: PTypography.t7.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PBadge(
                    label: calendarDdayLabel(l, dday),
                    size: PBadgeSize.large,
                    tone: imminent ? PBadgeTone.warning : PBadgeTone.neutral,
                  ),
                ],
              ),
            ),
            PList(
              semanticLabel: l.calFormRows,
              children: [
                if (cal != null)
                  row(
                    title: l.calFieldCalendar,
                    icon: LucideIcons.calendar,
                    value: cal.calendarName,
                    dot: chartToneOf(
                      context,
                      cal.color ?? e.calendarColor,
                    ).solid,
                  ),
                if (labelName.isNotEmpty)
                  row(
                    title: l.calFieldLabel,
                    icon: LucideIcons.tag,
                    value: labelName,
                    dot: chartToneOf(context, e.labelColor).solid,
                  ),
                if (e.isAllDayBool)
                  when(
                    title: l.calAllDay,
                    icon: LucideIcons.sun,
                    pieces: [startDay, if (multiDay) '~ $endDay'],
                  )
                else ...[
                  when(
                    title: l.calStartDate,
                    icon: LucideIcons.clock,
                    pieces: [startDay, timeOf(e.start)],
                  ),
                  when(
                    title: l.calEndDate,
                    icon: LucideIcons.clock,
                    pieces: [endDay, timeOf(e.end), ?duration],
                  ),
                ],
                // 반복 줄은 늘 둔다 — 다섯 밖 규칙은 폼과 같이 "반복 안 함" 으로 보인다
                row(
                  title: l.calRepeat,
                  icon: LucideIcons.repeat,
                  value: recurrenceLabel(l, rruleToRecurrence(e.rrule)),
                ),
                if (reminders.isNotEmpty)
                  row(
                    title: l.calFieldReminder,
                    icon: LucideIcons.bell,
                    value: reminderValueText(l, reminders),
                  ),
                if (location.isNotEmpty)
                  row(
                    title: l.calLocation,
                    icon: LucideIcons.mapPin,
                    value: location,
                  ),
                if (description.isNotEmpty)
                  PListItem(
                    title: l.calFieldDescription,
                    prefix: const Icon(LucideIcons.text, size: _rowIcon),
                  ),
              ],
            ),
            // 설명 본문 — 줄 제목 글 시작에 맞춰(24 + 아이콘 22 + 12 = 58) 다 보인다(말줄임 없음 · 길면 본문이 스크롤)
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter + _rowIcon + PSpacing.x3,
                  0,
                  PSpacing.globalGutter,
                  PSpacing.x4,
                ),
                child: Text(
                  keepAll(description),
                  key: const ValueKey('calendar-detail-description'),
                  style: PTypography.articleBody.copyWith(color: c.fgNeutral),
                ),
              ),
          ],
        );
      },
    );
  }
}
