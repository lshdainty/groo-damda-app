// 캘린더 화면 월 격자 — 이웃 달 칸 (I-04 03-C 결정 5A).
//
// 이웃 달은 날짜 숫자만 fg-disabled 로 하고, 그 칸의 일정 · 휴일 이름은 이번 달과 같게 둔다. 불투명도를 쓰지 않는다
// (DESIGN State — "캘린더 화면의 월 격자도 같다"). 예전에는 숫자에 alpha 0.4, 일정 조각에 Opacity 0.5 를 걸었다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

const _cal = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);

void main() {
  testWidgets('이웃 달 칸 — 숫자만 fg-disabled, 그 칸의 일정에는 불투명도가 없다', (tester) async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month);
    final last = DateTime(now.year, now.month + 1, 0);
    final gridStart = first.subtract(Duration(days: first.weekday % 7));
    final gridEnd = last.add(Duration(days: 6 - last.weekday % 7));
    // 앞 이웃 칸이 있으면 그 첫 칸, 없으면 뒤 이웃 칸의 마지막 칸 — 둘 다 없는 달(일요일에 시작하는 4주 2월)은 잴 칸이 없다
    final outside = gridStart != first
        ? gridStart
        : (gridEnd != last ? gridEnd : null);
    if (outside == null) {
      markTestSkipped('이 달에는 이웃 달 칸이 없다');
      return;
    }
    String iso(DateTime d, int h) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}T${h.toString().padLeft(2, '0')}:00:00';
    // 이번 달 경계에서 이웃 달 칸으로 걸치는 일정(이번 달만 받아 오므로 이웃 칸에는 걸친 일정만 그려진다)
    final leading = outside == gridStart;
    final startDay = leading ? outside : last;
    final endDay = leading ? first : outside;

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCalendarListProvider.overrideWith((ref) async => const [_cal]),
          monthEventsProvider.overrideWith(
            (ref, key) async => [
              CalendarEvent(
                rowId: 1,
                title: '이웃달일정',
                calendarRowId: 1,
                startDate: iso(startDay, 9),
                endDate: iso(endDay, 10),
              ),
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

    // 일정은 이웃 달 칸에도 그려지고, 불투명도(Opacity)로 흐리지 않는다
    final title = findText('이웃달일정');
    expect(title, findsWidgets);
    expect(
      find.ancestor(
        of: title,
        matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1),
      ),
      findsNothing,
    );

    // 이웃 달 숫자는 fg-disabled(불투명도 없는 색)
    final disabled = PColors.light.fgDisabled;
    final numbers = tester
        .widgetList<Text>(findText('${outside.day}'))
        .where((t) => t.style?.color == disabled);
    expect(numbers, isNotEmpty, reason: '이웃 달 ${outside.day}일 숫자가 fg-disabled');
    expect(disabled.a, 1.0, reason: '색에 알파를 섞지 않는다');
  });
}
