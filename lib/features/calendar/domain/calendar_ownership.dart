import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';

/// 캘린더 관리 화면 맨 아래 동작 — 캘린더와 나의 관계로 하나만 정해진다(2026-11-24 사용자 결정).
///
/// - 공유받은 캘린더(내가 소유자 아님) → [leave] — 나만 빠진다
/// - 내 캘린더 + 다른 멤버 있음 → [transferAndLeave] — 공유 캘린더는 지우지 않는다. 소유자를 넘기고 나만 빠진다
///   (서버 `DELETE` 는 `CAL_019` 로 막는다). 기본 캘린더도 공유할 수 있어 넘길 수 있다(서버가 새 기본을 만든다)
/// - 내 캘린더 + 나 혼자 → [delete] — 마지막 한 사람만 지운다. 기본 캘린더는 지울 수 없어 [none]
enum CalendarExitAction { delete, transferAndLeave, leave, none }

CalendarExitAction calendarExitAction({
  required bool isOwner,
  required bool isDefault,
  required int otherMemberCount,
}) {
  if (!isOwner) return CalendarExitAction.leave;
  if (otherMemberCount > 0) return CalendarExitAction.transferAndLeave;
  return isDefault ? CalendarExitAction.none : CalendarExitAction.delete;
}

/// 나 말고 이 캘린더에 남은 멤버 — 소유자 줄(나)과 내 줄을 뺀다.
List<CalendarMember> otherCalendarMembers(
  List<CalendarMember> members, {
  required int? myUserRowId,
}) => [
  for (final m in members)
    if (m.permission != 'OWNER' &&
        (myUserRowId == null || m.userRowId != myUserRowId))
      m,
];

/// 소유자를 넘겨받을 수 있는지 — 편집 가능(EDIT) 멤버만. 편집 가능 멤버가 하나도 없을 때만 읽기 전용(READ)
/// 멤버도 고를 수 있다(넘기면 OWNER 로 오른다). 서버 `transfer-ownership` 이 같은 규칙으로 `CAL_020` 을 낸다.
///
/// [others] 는 [otherCalendarMembers] 결과(나 · 소유자 줄 제외).
bool canReceiveOwnership(CalendarMember member, List<CalendarMember> others) {
  if (member.permission == 'EDIT') return true;
  if (member.permission != 'READ') return false;
  return !others.any((m) => m.permission == 'EDIT');
}
