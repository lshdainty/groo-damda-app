// 공유 캘린더 소유자 넘기기 · 나가기 · 삭제 판정(2026-11-24 사용자 결정).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/calendar/domain/calendar_ownership.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';

CalendarMember _m(int rowId, int userRowId, String permission) =>
    CalendarMember(
      rowId: rowId,
      userRowId: userRowId,
      userName: 'u$userRowId',
      permission: permission,
    );

void main() {
  group('calendarExitAction', () {
    test('공유받은 캘린더는 나가기', () {
      expect(
        calendarExitAction(
          isOwner: false,
          isDefault: false,
          otherMemberCount: 3,
        ),
        CalendarExitAction.leave,
      );
    });

    test('내 캘린더 + 다른 멤버 → 넘기고 나가기(지우지 않는다)', () {
      expect(
        calendarExitAction(
          isOwner: true,
          isDefault: false,
          otherMemberCount: 1,
        ),
        CalendarExitAction.transferAndLeave,
      );
    });

    test('기본 캘린더도 멤버가 있으면 넘길 수 있다', () {
      expect(
        calendarExitAction(isOwner: true, isDefault: true, otherMemberCount: 2),
        CalendarExitAction.transferAndLeave,
      );
    });

    test('내 캘린더 + 나 혼자 → 삭제, 기본 캘린더면 없음', () {
      expect(
        calendarExitAction(
          isOwner: true,
          isDefault: false,
          otherMemberCount: 0,
        ),
        CalendarExitAction.delete,
      );
      expect(
        calendarExitAction(isOwner: true, isDefault: true, otherMemberCount: 0),
        CalendarExitAction.none,
      );
    });
  });

  group('otherCalendarMembers', () {
    test('소유자 줄과 내 줄을 뺀다', () {
      final others = otherCalendarMembers([
        _m(1, 10, 'OWNER'),
        _m(2, 11, 'EDIT'),
        _m(3, 12, 'READ'),
      ], myUserRowId: 10);
      expect(others.map((m) => m.rowId), [2, 3]);
    });

    test('내 id 를 모르면 소유자 줄만 뺀다', () {
      final others = otherCalendarMembers([
        _m(1, 10, 'OWNER'),
        _m(2, 11, 'EDIT'),
      ], myUserRowId: null);
      expect(others.map((m) => m.rowId), [2]);
    });
  });

  group('canReceiveOwnership', () {
    test('편집 가능 멤버가 있으면 그 멤버만 받는다', () {
      final others = [_m(2, 11, 'EDIT'), _m(3, 12, 'READ')];
      expect(canReceiveOwnership(others[0], others), isTrue);
      expect(canReceiveOwnership(others[1], others), isFalse);
    });

    test('편집 가능 멤버가 없으면 읽기 전용 멤버도 받는다', () {
      final others = [_m(3, 12, 'READ'), _m(4, 13, 'READ')];
      expect(canReceiveOwnership(others[0], others), isTrue);
      expect(canReceiveOwnership(others[1], others), isTrue);
    });

    test('소유자 줄은 받지 못한다', () {
      final owner = _m(1, 10, 'OWNER');
      expect(canReceiveOwnership(owner, [owner]), isFalse);
    });
  });
}
