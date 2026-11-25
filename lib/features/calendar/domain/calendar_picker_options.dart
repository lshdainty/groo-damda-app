import 'package:groo_damda_app/features/calendar/domain/calendar_visibility.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';

/// 일정 만들기·수정에서 **고를 수 있는** 캘린더.
///
/// 숨긴 캘린더는 뺀다. #336 이 "숨긴 캘린더의 일정은 달력에 안 그린다" 를 만들었으므로
/// 지금은 숨긴 캘린더에 저장하면 **저장하자마자 화면에서 사라진다.** 그러니 애초에
/// 못 고르게 한다.
///
/// **예외 하나** — [keepRowId](편집 중인 일정이 이미 든 캘린더)는 숨겨져 있어도 남긴다.
/// 안 남기면 그 일정을 여는 것만으로 소속 캘린더가 다른 값으로 바뀌어 저장된다.
/// 사용자가 안 건드린 값이 저장 때 바뀌는 것이 제일 나쁘다.
///
/// 표시 판정은 [isCalendarVisible] 하나만 쓴다 — 규칙을 두 벌 두면 언젠가 갈린다.
List<UserCalendar> selectableCalendars(
  List<UserCalendar> calendars, {
  int? keepRowId,
}) {
  final kept = calendarLockedTo(calendars, keepRowId);
  if (kept != null) return [kept];
  return [
    for (final c in calendars)
      if (c.rowId == keepRowId || isCalendarVisible(calendars, c.rowId)) c,
  ];
}

/// 편집 중인 일정이 든 캘린더가 **공유 중**이면 그 캘린더 — 캘린더 칸은 그 하나로 잠긴다.
///
/// 공유 중인 캘린더의 일정은 그 캘린더 안에서만 다룬다 — 다른 캘린더로 옮길 수 없다(소유자도).
/// 권한은 그 캘린더 안의 권한이지 일정을 밖으로 빼는 권한이 아니다(2026-11-24 사용자 결정,
/// 서버 `CALENDAR_EVENT_SHARED_MOVE_DENIED` · 웹 `use-event-form` 과 같다). 공유가 아니면 null.
UserCalendar? calendarLockedTo(List<UserCalendar> calendars, int? keepRowId) {
  if (keepRowId == null) return null;
  for (final c in calendars) {
    if (c.rowId == keepRowId) return c.isShared ? c : null;
  }
  return null;
}

/// 고를 수 있는 것들 중 기본 선택 — 기본 캘린더가 숨겨져 있으면 보이는 것 중 첫째다.
///
/// [options] 는 [selectableCalendars] 를 지난 목록이어야 한다. 거르기 전 목록에서
/// 고르면 **목록에 없는 값이 선택된 상태**가 되어, 셀렉트는 이름이 빈 칸을 그리고
/// 저장은 숨긴 캘린더로 나간다.
///
/// 고를 게 하나도 없으면 null — 캘린더를 안 실으면 서버가 알아서 정한다.
int? defaultCalendarRowId(List<UserCalendar> options) {
  for (final c in options) {
    if (c.isDefault) return c.rowId;
  }
  return options.isEmpty ? null : options.first.rowId;
}
