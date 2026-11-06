// 캘린더를 숨겨도 그 일정이 그대로 보였다 (QA #146).
//
// 캐시 문제가 아니라 **기능 누락**이었다. 서버는 표시 여부로 걸러 주지 않고
// (`CalendarEventServiceImpl` 에 필터가 없다), 앱은 `isVisible` 을 필터 시트
// 체크박스와 개수 표시에만 썼다 — 일정 목록에는 아무도 쓰지 않았다. 그래서
// 체크를 꺼도 월 그리드와 날짜 시트에는 그 캘린더의 일정이 그대로 남았다.
//
// 웹은 같은 응답을 받아 **화면에서** 거른다
// (`calendar-provider.tsx` `isCalendarVisible` → `CalendarContainer.filteredEvents`).
// 앱도 같은 규칙으로 맞춘다. 특히 **못 찾을 때의 기본값이 "보임"**(웹 `?? true`)
// 이라는 것 — 여기서 반대로 기울면 목록이 아직 안 온 순간이나 내 목록에 없는
// 캘린더를 가리키는 일정이 통째로 사라진다.
//
// 조회가 아니라 화면에서 거른다는 것도 함께 잠근다 — 조회 파라미터에 캘린더를
// 실으면 월 캐시가 캘린더 조합마다 갈려 체크 한 번에 같은 달을 다시 받는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_visibility.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

const _shown = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);
const _hidden = UserCalendar(rowId: 2, calendarName: '회사', isVisible: false);

CalendarEvent _event({
  required int rowId,
  required String title,
  int? calendarRowId,
  required DateTime day,
}) {
  String at(int h) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}T${h.toString().padLeft(2, '0')}:00:00';
  return CalendarEvent(
    rowId: rowId,
    title: title,
    calendarRowId: calendarRowId,
    startDate: at(9),
    endDate: at(10),
  );
}

void main() {
  final day = DateTime(2026, 3, 15);

  group('표시 규칙 — 웹 isCalendarVisible 정합', () {
    test('표시를 끈 캘린더의 일정은 빠진다', () {
      final events = [
        _event(rowId: 1, title: '보이는 일정', calendarRowId: 1, day: day),
        _event(rowId: 2, title: '숨긴 일정', calendarRowId: 2, day: day),
      ];

      final visible = visibleCalendarEvents(events, const [_shown, _hidden]);

      expect(visible.map((e) => e.title), ['보이는 일정']);
    });

    test('목록에 없는 캘린더의 일정은 그대로 보인다 — 웹 `?? true`', () {
      // 공유가 막 끊겼거나 서버가 내 목록 밖 캘린더를 가리키는 일정을 내려준 경우.
      // 숨김으로 기울면 멀쩡한 일정이 조용히 사라진다.
      final events = [
        _event(rowId: 3, title: '남의 캘린더 일정', calendarRowId: 99, day: day),
      ];

      expect(
        visibleCalendarEvents(events, const [
          _shown,
          _hidden,
        ]).map((e) => e.title),
        ['남의 캘린더 일정'],
      );
    });

    test('캘린더 목록이 아직 안 왔으면(빈 목록) 전부 보인다', () {
      final events = [
        _event(rowId: 1, title: '보이는 일정', calendarRowId: 1, day: day),
        _event(rowId: 2, title: '숨긴 일정', calendarRowId: 2, day: day),
      ];

      expect(visibleCalendarEvents(events, const <UserCalendar>[]).length, 2);
    });

    test('캘린더가 없는 일정은 거르지 않는다 — 웹도 값이 있을 때만 본다', () {
      final events = [_event(rowId: 4, title: '소속 없는 일정', day: day)];

      expect(visibleCalendarEvents(events, const [_hidden]).length, 1);
    });

    test('isCalendarVisible — 찾으면 그 값, 못 찾으면 보임', () {
      expect(isCalendarVisible(const [_shown, _hidden], 1), isTrue);
      expect(isCalendarVisible(const [_shown, _hidden], 2), isFalse);
      expect(isCalendarVisible(const [_shown, _hidden], 99), isTrue);
      expect(isCalendarVisible(const <UserCalendar>[], 1), isTrue);
    });
  });

  group('캘린더 화면', () {
    /// 이번 달 15일 — 월 그리드에 늘 그려지고, 이웃 달 이월 칸과 숫자가 겹치지
    /// 않는 날짜다(이월은 앞뒤로 최대 6·11일 남짓).
    DateTime thisMonth15() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, 15);
    }

    Future<void> pump(WidgetTester tester) async {
      final d = thisMonth15();
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userCalendarListProvider.overrideWith(
              (ref) async => const [_shown, _hidden],
            ),
            monthEventsProvider.overrideWith(
              (ref, key) async => [
                _event(rowId: 1, title: '보이는일정', calendarRowId: 1, day: d),
                _event(rowId: 2, title: '숨긴일정', calendarRowId: 2, day: d),
              ],
            ),
            holidayListProvider.overrideWith((ref, key) async => <Holiday>[]),
          ],
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const Scaffold(body: CalendarScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('월 그리드에 숨긴 캘린더의 일정이 그려지지 않는다', (tester) async {
      await pump(tester);

      expect(findText('보이는일정'), findsWidgets);
      expect(findText('숨긴일정'), findsNothing);
    });

    /// 달 줄 필터 칩의 8×8 색 점 — 칩 앞 점 묶음 안의 점이다.
    Finder headerDots() => find.descendant(
      of: find.byKey(const ValueKey('calendar-filter-dots')),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints == const BoxConstraints.tightFor(width: 8, height: 8),
      ),
    );

    testWidgets('헤더 색 점도 표시 중인 캘린더만 찍는다', (tester) async {
      // 개수는 visible 로 세면서 점은 전부에서 뽑으면 "1개" 옆에 점이 둘 찍힌다.
      // 웹 CalendarSourceToggle 은 둘 다 `filter(c => c.isVisible)` 를 지난다.
      await pump(tester);

      expect(headerDots(), findsOneWidget);
    });

    testWidgets('날짜 시트에도 숨긴 캘린더의 일정이 올라오지 않는다', (tester) async {
      await pump(tester);

      await tester.tap(findText('15'));
      await tester.pumpAndSettle();

      // 시트가 실제로 열렸는지 — 보이는 일정이 그리드 + 시트 두 곳에 있다.
      expect(findPlain('보이는일정'), findsNWidgets(2));
      expect(findPlain('숨긴일정'), findsNothing);
    });
  });
}
