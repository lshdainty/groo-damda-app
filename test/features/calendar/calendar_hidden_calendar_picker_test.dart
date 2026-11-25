// 일정 만들기 선택 목록에서 숨긴 캘린더를 뺀다 (QA 결정 2).
//
// #336 이 "숨긴 캘린더의 일정은 달력에 안 그린다" 를 만들었다. 그래서 그 뒤로는
// **숨긴 캘린더에 일정을 저장하면 저장 직후 사라진다** — 저장은 성공했는데 화면에
// 아무것도 안 남으니 사용자는 저장이 실패했다고 읽는다. 고를 수 없게 막는다.
//
// 목록과 기본 선택을 **둘 다** 막아야 한다. 목록만 거르고 기본 선택을 그대로 두면
// 목록에 없는 값이 선택된 상태가 되고, PSelect 는 그 값을 이름 없는 칸으로 그린다.
//
// **기본 캘린더는 이 규칙 밖이다** (QA 결정 5) — 숨길 수 없으므로 언제나 목록에 남는다.
// 아래 `_hiddenDefault` 는 토글을 막기 전 옛 데이터가 와도 그렇게 읽히는지를 본다.
//
// **예외 하나** — 편집 중인 일정이 이미 숨긴 캘린더에 있으면 그 캘린더는 남긴다.
// 안 남기면 그 일정을 여는 것만으로 소속 캘린더가 다른 값으로 바뀌어 저장된다.
// 사용자가 안 건드린 값이 저장 때 바뀌는 것이 제일 나쁘다.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_picker_options.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale, ValueKey;
import 'package:flutter/material.dart' show Text;
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

import 'support/event_form_support.dart';

const _personal = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);
const _work = UserCalendar(rowId: 2, calendarName: '회사', isVisible: false);
const _family = UserCalendar(rowId: 3, calendarName: '가족');

/// 서버가 기본 캘린더를 `isVisible: false` 로 내려준 배치 — 표시 토글을 막기 전에
/// 꺼 둔 옛 데이터다. 기본 캘린더는 표시 고정이라(QA 결정 5) 그래도 보임으로 읽힌다.
const _hiddenDefault = UserCalendar(
  rowId: 1,
  calendarName: '개인',
  isDefault: true,
  isVisible: false,
);

/// 숨긴 캘린더(rowId 2)에 든 일정 — 편집 예외의 주인공.
CalendarEvent _eventIn(int? calendarRowId) => CalendarEvent(
  rowId: 42,
  title: '주간 회의',
  eventType: 'WORK',
  calendarRowId: calendarRowId,
  startDate: '2026-09-10T09:00:00',
  endDate: '2026-09-10T10:00:00',
);

/// 화면이 저장에 실은 캘린더를 그대로 잡아 둔다.
class _CapturingRepo extends CalendarRepository {
  _CapturingRepo() : super(Dio());

  int? createdCalendarRowId;
  int? updatedCalendarRowId;
  bool created = false;
  bool updated = false;

  @override
  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    int? labelRowId,
    String? location,
    String? rrule,
    List<int>? reminderMinutes,
  }) async {
    created = true;
    createdCalendarRowId = calendarRowId;
    return _eventIn(calendarRowId);
  }

  @override
  Future<CalendarEvent> updateEvent({
    required int id,
    required String title,
    Patch<String> description = const Patch.keep(),
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    Patch<int> labelRowId = const Patch.keep(),
    Patch<String> location = const Patch.keep(),
    Patch<String> rrule = const Patch.keep(),
    List<int>? reminderMinutes,
    String? occurrenceStartDate,
  }) async {
    updated = true;
    updatedCalendarRowId = calendarRowId;
    return _eventIn(calendarRowId);
  }
}

/// 폼 캘린더 줄의 값 글 — 줄 값은 고른 캘린더 이름이다.
Finder _calendarValue(String name) => find.descendant(
  of: find.byType(PList),
  matching: valueTextContaining(name),
);

/// 캘린더 고르기 시트를 열어 보이는 줄 이름을 읽는다(숨긴 캘린더가 있나 보려고).
Future<List<String>> _calendarChoices(
  WidgetTester tester,
  AppLocalizations l,
) async {
  await tapRow(tester, l.calFieldCalendar);
  final names = [
    for (final w in tester.widgetList<Text>(
      find.byKey(const ValueKey('plist-title')),
    ))
      w.semanticsLabel ?? '',
  ];
  return names;
}

Future<_CapturingRepo> _open(
  WidgetTester tester, {
  required List<UserCalendar> calendars,
  CalendarEvent? edit,
}) async {
  final repo = _CapturingRepo();
  await openEventForm(tester, repo: repo, calendars: calendars, edit: edit);
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('고를 수 있는 캘린더 — selectableCalendars', () {
    test('숨긴 캘린더는 빠진다', () {
      expect(
        selectableCalendars(const [
          _personal,
          _work,
          _family,
        ]).map((c) => c.rowId),
        [1, 3],
      );
    });

    test('편집 중인 일정이 든 캘린더는 숨겨져 있어도 남는다', () {
      expect(
        selectableCalendars(const [
          _personal,
          _work,
          _family,
        ], keepRowId: 2).map((c) => c.rowId),
        [1, 2, 3],
        reason: '빼면 그 일정을 여는 것만으로 소속 캘린더가 바뀌어 저장된다',
      );
    });

    test('예외는 딱 그 하나다 — 다른 숨긴 캘린더까지 딸려 오지 않는다', () {
      const other = UserCalendar(
        rowId: 4,
        calendarName: '비밀',
        isVisible: false,
      );
      expect(
        selectableCalendars(const [
          _personal,
          _work,
          other,
        ], keepRowId: 2).map((c) => c.rowId),
        [1, 2],
      );
    });

    test('편집 중인 일정이 공유 중인 캘린더에 있으면 그 하나로 잠긴다(소유자도)', () {
      const shared = UserCalendar(
        rowId: 5,
        calendarName: '팀',
        isShared: true,
        memberCount: 3,
      );
      expect(
        selectableCalendars(const [
          _personal,
          shared,
          _family,
        ], keepRowId: 5).map((c) => c.rowId),
        [5],
        reason: '공유 캘린더 일정은 다른 캘린더로 옮길 수 없다(2026-11-24 사용자 결정)',
      );
      expect(calendarLockedTo(const [_personal, shared], 5), shared);
      expect(calendarLockedTo(const [_personal, shared], 1), isNull);
      expect(calendarLockedTo(const [_personal, shared], null), isNull);
    });

    test('내 목록에 없는 캘린더를 남기라 해도 없던 것이 생기지는 않는다', () {
      expect(
        selectableCalendars(const [
          _personal,
        ], keepRowId: 99).map((c) => c.rowId),
        [1],
      );
    });
  });

  group('기본 선택 — defaultCalendarRowId', () {
    test('보이는 기본 캘린더가 있으면 그것', () {
      expect(
        defaultCalendarRowId(selectableCalendars(const [_personal, _family])),
        1,
      );
    });

    // 기본 캘린더는 숨길 수 없다 (QA 결정 5) — 필터 시트에 스위치가 없고 서버도
    // 토글을 400 으로 막는다. 그래서 "숨긴 기본 캘린더" 라는 상태가 아예 없다.
    // 옛 데이터가 `isVisible: false` 로 남아 있어도 표시 판정이 보임으로 고정한다.
    test('기본 캘린더는 숨김 값이 와도 목록에 남고 그대로 잡힌다', () {
      expect(
        selectableCalendars(const [
          _hiddenDefault,
          _work,
          _family,
        ]).map((c) => c.calendarName),
        ['개인', '가족'],
      );
      expect(
        defaultCalendarRowId(
          selectableCalendars(const [_hiddenDefault, _work, _family]),
        ),
        1,
        reason: '기본 캘린더를 빼면 서버가 자동 대입하는 캘린더와 화면이 갈린다',
      );
    });

    test('고를 게 없으면 null — 캘린더를 안 실으면 서버가 정한다', () {
      expect(defaultCalendarRowId(selectableCalendars(const [_work])), isNull);
      expect(defaultCalendarRowId(const []), isNull);
    });
  });

  group('신규 일정', () {
    testWidgets('숨긴 캘린더가 목록에 없다', (tester) async {
      await _open(tester, calendars: const [_personal, _work, _family]);

      expect(_calendarValue('개인'), findsOneWidget, reason: '기본 선택이 줄 값이다');
      final names = await _calendarChoices(tester, l);
      expect(names, containsAll(['개인', '가족']));
      expect(names, isNot(contains('회사')));
    });

    testWidgets('기본 캘린더는 숨김 값이 와도 목록에 남고 저장에도 그게 실린다', (tester) async {
      final repo = await _open(
        tester,
        calendars: const [_hiddenDefault, _work, _family],
      );

      expect(_calendarValue('개인'), findsOneWidget);
      final names = await _calendarChoices(tester, l);
      expect(names, containsAll(['개인', '가족']));
      expect(names, isNot(contains('회사')));
      await tester.tapAt(const Offset(195, 20)); // 딤 — 고르기 시트는 바깥으로 닫힌다
      await tester.pumpAndSettle();

      await enterTitle(tester, '스탠드업');
      await tapButton(tester, l.actionSave);

      expect(repo.created, isTrue, reason: '생성이 안 불렸다 — 테스트가 아무것도 안 본다');
      expect(
        repo.createdCalendarRowId,
        1,
        reason: '기본 캘린더를 빼면 사용자가 안 고른 캘린더로 저장이 나간다',
      );
    });

    testWidgets('다른 캘린더를 고르면 그 캘린더가 저장에 실린다', (tester) async {
      final repo = await _open(
        tester,
        calendars: const [_personal, _work, _family],
      );
      await tapRow(tester, l.calFieldCalendar);
      await tapRow(tester, '가족');
      expect(_calendarValue('가족'), findsOneWidget);
      await enterTitle(tester, '스탠드업');
      await tapButton(tester, l.actionSave);

      expect(repo.createdCalendarRowId, 3);
    });
  });

  group('일정 수정', () {
    testWidgets('숨긴 캘린더의 일정을 편집하면 그 캘린더가 목록에 남고 선택돼 있다', (tester) async {
      await _open(
        tester,
        calendars: const [_personal, _work, _family],
        edit: _eventIn(2),
      );

      expect(
        _calendarValue('회사'),
        findsOneWidget,
        reason: '목록에 없는 값이 선택되면 이름 없는 줄이 그려진다',
      );
      final names = await _calendarChoices(tester, l);
      expect(
        names,
        containsAll(['개인', '회사', '가족']),
        reason: '빼면 여는 순간 다른 캘린더로 바뀐다',
      );
    });

    testWidgets('안 건드리고 저장하면 화면에 보이던 그 캘린더가 그대로 나간다', (tester) async {
      final repo = await _open(
        tester,
        calendars: const [_personal, _work, _family],
        edit: _eventIn(2),
      );

      // 예외를 빼면 여기가 갈린다 — 줄은 '개인' 을 그리는데 저장은 '회사' 로 나간다.
      expect(_calendarValue('회사'), findsOneWidget);

      await tapButton(tester, l.actionSave);

      expect(repo.updated, isTrue, reason: '수정이 안 불렸다');
      expect(
        repo.updatedCalendarRowId,
        2,
        reason: '사용자가 안 건드린 값이 저장 한 번에 바뀌는 것이 제일 나쁘다',
      );
    });

    testWidgets('보이는 캘린더의 일정을 편집할 때는 숨긴 캘린더가 안 보인다', (tester) async {
      await _open(
        tester,
        calendars: const [_personal, _work, _family],
        edit: _eventIn(1),
      );

      expect(_calendarValue('개인'), findsOneWidget);
      final names = await _calendarChoices(tester, l);
      expect(names, containsAll(['개인', '가족']));
      expect(names, isNot(contains('회사')));
    });
  });
}
