// I-09 09-1 불러오기 · 실패 (12) — 일정 질의 실패는 빈 격자가 아니라 실패 상자 하나, "다시 시도" 는 그 질의만.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_month_row.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

import '../../support/plain_text.dart';

void main() {
  const cal = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);

  Widget app(List<Override> overrides) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: const Scaffold(body: CalendarScreen()),
    ),
  );

  testWidgets('일정 질의 실패 — 달 줄은 그대로, 격자 자리에 실패 상자 하나, 원문 0', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    var eventCalls = 0;
    var calendarCalls = 0;
    await tester.pumpWidget(
      app([
        userCalendarListProvider.overrideWith((ref) async {
          calendarCalls++;
          return const [cal];
        }),
        monthEventsProvider.overrideWith((ref, key) async {
          eventCalls++;
          throw StateError('서버가 낸 원문 오류');
        }),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CalendarMonthRow), findsOneWidget);
    expect(find.byType(CalendarWeekdayRow), findsOneWidget);
    expect(find.byType(PResultSection), findsOneWidget);
    expect(find.byType(CalendarMonthGrid), findsNothing);
    expect(findPlain('일정을 불러오지 못했어요'), findsOneWidget);
    expect(findTextContaining('서버가 낸 원문'), findsNothing);
    expect(findTextContaining('StateError'), findsNothing);

    // 다시 시도 — 일정 질의만 다시 받는다(캘린더 목록은 그대로)
    final before = (eventCalls, calendarCalls);
    await tester.tap(findText('다시 시도'));
    await tester.pumpAndSettle();
    expect(eventCalls, before.$1 + 1);
    expect(calendarCalls, before.$2);
  });

  testWidgets('다시 시도가 성공하면 격자가 돌아온다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    var fail = true;
    await tester.pumpWidget(
      app([
        userCalendarListProvider.overrideWith((ref) async => const [cal]),
        monthEventsProvider.overrideWith((ref, key) async {
          if (fail) throw StateError('x');
          return const <CalendarEvent>[];
        }),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PResultSection), findsOneWidget);
    fail = false;
    await tester.tap(findText('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(PResultSection), findsNothing);
    expect(find.byType(CalendarMonthGrid), findsOneWidget);
  });

  testWidgets('공휴일 질의만 실패하면 상자 없이 공휴일 없는 격자를 그린다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app([
        userCalendarListProvider.overrideWith((ref) async => const [cal]),
        monthEventsProvider.overrideWith(
          (ref, key) async => const <CalendarEvent>[],
        ),
        holidayListProvider.overrideWith(
          (ref, key) async => throw StateError('h'),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PResultSection), findsNothing);
    expect(find.byType(CalendarMonthGrid), findsOneWidget);
  });

  testWidgets('처음 불러오는 동안 — 달 줄 · 요일 줄은 그려져 있고 격자만 Skeleton', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final never = Future<List<CalendarEvent>>.delayed(
      const Duration(days: 1),
      () => const <CalendarEvent>[],
    );
    await tester.pumpWidget(
      app([
        userCalendarListProvider.overrideWith((ref) async => const [cal]),
        monthEventsProvider.overrideWith((ref, key) => never),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(CalendarMonthRow), findsOneWidget);
    expect(find.byType(CalendarWeekdayRow), findsOneWidget);
    expect(find.byType(PSkeleton), findsWidgets);
    expect(find.byType(CalendarMonthGrid), findsNothing);
    expect(find.byType(PResultSection), findsNothing);
    await tester.pump(const Duration(days: 2));
  });
}
