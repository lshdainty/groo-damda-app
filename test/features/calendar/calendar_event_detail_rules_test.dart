// I-09b 7 · 6 — 상세의 [수정][삭제] 를 보일 사람(서버 canEditOrDelete 와 같은 표) · D-day · 걸린 시간.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event_detail_rules.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

CalendarEvent _ev({
  int? user,
  int? calendar = 1,
  String start = '2026-10-29T10:00:00',
  String end = '2026-10-29T12:00:00',
  String allDay = 'N',
}) => CalendarEvent(
  rowId: 1,
  userRowId: user,
  title: '회의',
  startDate: start,
  endDate: end,
  isAllDay: allDay,
  calendarRowId: calendar,
);

UserCalendar _cal(String role) =>
    UserCalendar(rowId: 1, calendarName: '캘린더', myRole: role);

void main() {
  group('canEditCalendarEvent — 서버 규칙(만든 사람 || 소유자 · 편집)', () {
    bool can(CalendarEvent e, {int? me = 7, List<UserCalendar>? cals}) =>
        canEditCalendarEvent(event: e, myUserRowId: me, calendars: cals);

    test('내가 만든 일정은 읽기 전용 캘린더여도 버튼이 있다', () {
      expect(can(_ev(user: 7), cals: [_cal('READ')]), isTrue);
    });

    test('남이 만든 일정은 읽기 전용 캘린더면 버튼이 없다', () {
      expect(can(_ev(user: 9), cals: [_cal('READ')]), isFalse);
    });

    test('남이 만든 일정이어도 캘린더 권한이 편집 · 소유자면 있다', () {
      expect(can(_ev(user: 9), cals: [_cal('EDIT')]), isTrue);
      expect(can(_ev(user: 9), cals: [_cal('OWNER')]), isTrue);
    });

    test('권한을 모르는 동안(목록 없음 · 못 찾음)은 남의 일정에 버튼이 없고 내 일정에는 있다', () {
      expect(can(_ev(user: 9), cals: null), isFalse, reason: '불러오는 중 · 실패');
      expect(can(_ev(user: 9, calendar: 2), cals: [_cal('OWNER')]), isFalse);
      expect(can(_ev(user: 9, calendar: null), cals: [_cal('OWNER')]), isFalse);
      expect(can(_ev(user: 7), cals: null), isTrue);
    });

    test('내가 누구인지 모르면(로그인 확인 전) 만든 사람 판정은 거짓이다', () {
      expect(can(_ev(user: 7), me: null, cals: [_cal('READ')]), isFalse);
      expect(can(_ev(user: null), me: null, cals: null), isFalse);
    });
  });

  group('D-day', () {
    final today = DateTime(2026, 10, 29, 23, 59);

    test('시작일 기준 · 시각은 보지 않는다', () {
      expect(calendarDday(DateTime(2026, 10, 29, 0, 1), today), 0);
      expect(calendarDday(DateTime(2026, 10, 30, 9), today), 1);
      expect(calendarDday(DateTime(2026, 10, 24, 10), today), -5);
    });

    test('임박 = 오늘 ~ 3일 남음, 4일 이상 · 지난 날은 아니다(경계값)', () {
      expect(calendarDdayImminent(0), isTrue);
      expect(calendarDdayImminent(3), isTrue);
      expect(calendarDdayImminent(4), isFalse);
      expect(calendarDdayImminent(-1), isFalse);
    });

    test('글 — D-DAY · D-3 · 5일 지남', () async {
      final l = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(calendarDdayLabel(l, 0), 'D-DAY');
      expect(calendarDdayLabel(l, 3), 'D-3');
      expect(calendarDdayLabel(l, -5), '5일 지남');
    });
  });

  group('걸린 시간 — 같은 날 시각 일정만', () {
    late AppLocalizations l;
    setUp(
      () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
    );

    test('2시간 · 1시간 30분 · 45분', () {
      expect(calendarDurationText(l, _ev()), '2시간');
      expect(
        calendarDurationText(l, _ev(end: '2026-10-29T11:30:00')),
        '1시간 30분',
      );
      expect(calendarDurationText(l, _ev(end: '2026-10-29T10:45:00')), '45분');
    });

    test('종일 · 여러 날 · 시작과 끝이 같은 일정은 없다', () {
      expect(calendarDurationText(l, _ev(allDay: 'Y')), isNull);
      expect(
        calendarDurationText(l, _ev(end: '2026-10-30T10:00:00')),
        isNull,
        reason: '여러 날',
      );
      expect(
        calendarDurationText(l, _ev(end: '2026-10-29T10:00:00')),
        isNull,
        reason: '0 분',
      );
    });
  });
}
