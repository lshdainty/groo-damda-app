import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// rrule → 반복 글(편집 폼 `_rruleToRecurrence` 와 같은 매핑). 반복이 아니면 null, 다섯 밖 규칙은 원문 그대로.
String? eventRepeatLabel(AppLocalizations l, String? rrule) {
  if (rrule == null || rrule.isEmpty) return null;
  if (rrule.contains('FREQ=DAILY')) return l.calRepeatDaily;
  if (rrule.contains('FREQ=WEEKLY')) return l.calRepeatWeekly;
  if (rrule.contains('FREQ=MONTHLY')) return l.calRepeatMonthly;
  if (rrule.contains('FREQ=YEARLY')) return l.calRepeatYearly;
  return rrule;
}

/// 일정 줄 설명 첫 조각 — 종일 "종일"(이어지는 종일은 "종일 · 10월 10일~11일"), 그 밖 "오전 10:00~오후 12:00"(구간 기호는 붙여 쓰고 로케일 문구 — DESIGN.desk.md 날짜).
String eventTimeText(AppLocalizations l, CalendarEvent e) {
  final s = e.start;
  final end = e.end;
  if (e.isAllDayBool) {
    final sd = DateTime(s.year, s.month, s.day);
    final ed = DateTime(end.year, end.month, end.day);
    if (!ed.isAfter(sd)) return l.calAllDay;
    // 같은 달이면 끝 날짜는 일만 — ko "10월 25일~27일" · en "Oct 25–27"(웹 · 스펙과 같다)
    final endText = sd.month == ed.month && sd.year == ed.year
        ? (localeIsEn() ? '${ed.day}' : '${ed.day}일')
        : monthDay(ed);
    return '${l.calAllDay} · ${monthDay(sd)}${rangeSeparator()}$endText';
  }
  return '${timeOfDay12(s)}${rangeSeparator()}${timeOfDay12(end)}';
}
