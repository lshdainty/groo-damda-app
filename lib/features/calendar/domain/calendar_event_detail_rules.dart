import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 일정 상세의 [수정] · [삭제] 를 보일 사람인가(I-09b 7) — 서버 규칙 그대로(`CalendarMembershipValidator.canEditOrDelete`):
/// **일정을 만든 사람이거나, 그 일정 캘린더의 내 권한이 OWNER · EDIT**.
///
/// 캘린더 목록을 아직 못 받았거나(불러오는 중 · 실패) 그 캘린더를 못 찾으면 권한을 모르는 것이다 — 이때는 만든 사람 판정만 쓴다
/// (버튼이 떴다 사라지지 않게, 모르는 동안은 남의 일정에 버튼을 그리지 않는다). 공휴일은 [CalendarEvent] 가 아니라 이 길에 오지 않는다.
bool canEditCalendarEvent({
  required CalendarEvent event,
  required int? myUserRowId,
  required List<UserCalendar>? calendars,
}) {
  if (myUserRowId != null && event.userRowId == myUserRowId) return true;
  final calendarId = event.calendarRowId;
  if (calendarId == null || calendars == null) return false;
  for (final c in calendars) {
    if (c.rowId == calendarId) {
      return c.myRole == 'OWNER' || c.myRole == 'EDIT';
    }
  }
  return false;
}

/// 시작일 기준 D-day — 오늘 0, 지난 날은 음수(웹 `EventDetailBody` 와 같은 규칙, 시각은 보지 않는다).
int calendarDday(DateTime start, DateTime today) => DateTime(
  start.year,
  start.month,
  start.day,
).difference(DateTime(today.year, today.month, today.day)).inDays;

/// D-day 배지의 글 — "D-DAY" · "D-3" · "5일 지남".
String calendarDdayLabel(AppLocalizations l, int dday) => dday == 0
    ? l.calDetailDday
    : (dday > 0 ? l.calDetailDdayLeft(dday) : l.calDetailDdayPast(-dday));

/// 임박(오늘 ~ 3일 남음)이면 경고 톤, 그 밖(4일 이상 · 지남)은 중립(I-09b 공통 값 · 10-29 사용자 결정 — 홈 다가오는 일정과 같다).
bool calendarDdayImminent(int dday) => dday >= 0 && dday <= 3;

/// 종료 줄 뒤에 붙는 걸린 시간 — **같은 날 시각 일정만**. 종일 · 여러 날 · 0 분 이하는 null.
String? calendarDurationText(AppLocalizations l, CalendarEvent e) {
  if (e.isAllDayBool) return null;
  final s = e.start;
  final end = e.end;
  final sameDay =
      s.year == end.year && s.month == end.month && s.day == end.day;
  if (!sameDay) return null;
  final min = end.difference(s).inMinutes;
  if (min <= 0) return null;
  if (min < 60) return l.calDetailDurationM(min);
  return min % 60 == 0
      ? l.calDetailDurationH(min ~/ 60)
      : l.calDetailDurationHM(min ~/ 60, min % 60);
}
