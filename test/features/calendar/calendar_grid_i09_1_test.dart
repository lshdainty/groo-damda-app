// I-09 09-1 폰 달력 — 흰 면 하나 · 칸 103 · 칩 18 · "+N개" · 글자 200% 넘침 0 (6 · 8 · 9 · 10).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_month_row.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';

import '../../support/plain_text.dart';

const _cal = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);

CalendarEvent _ev(int id, String title, DateTime day, {String? color}) {
  String at(int h) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}T${h.toString().padLeft(2, '0')}:00:00';
  return CalendarEvent(
    rowId: id,
    title: title,
    calendarRowId: 1,
    startDate: at(9 + id % 8),
    endDate: at(10 + id % 8),
    calendarColor: color ?? '#2c70bf',
  );
}

/// 글자 폭을 실제 글꼴로 잰다 — 테스트 기본 글꼴은 글자마다 폭이 같아 한 줄에 드는지를 못 잰다.
Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  for (final family in const ['Pretendard', 'FlutterTest']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  final now = DateTime.now();
  final d22 = DateTime(now.year, now.month, 22);
  final five = [for (var i = 1; i <= 5; i++) _ev(i, '다섯째날일정$i', d22)];

  Future<void> pump(
    WidgetTester tester, {
    List<CalendarEvent> events = const [],
    double scale = 1.0,
    bool dark = false,
    Map<String, String> holidays = const {},
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCalendarListProvider.overrideWith((ref) async => const [_cal]),
          monthEventsProvider.overrideWith((ref, key) async => events),
          holidayListProvider.overrideWith(
            (ref, key) async => [
              for (final e in holidays.entries)
                Holiday(rowId: 1, holidayDate: e.key, holidayName: e.value),
            ],
          ),
        ],
        child: MaterialApp(
          theme: dark ? GrooTheme.dark() : GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(body: CalendarScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('흰 면 하나 — 달 줄 52 · 요일 줄 32 · 칸 103, 화면 폭 끝까지, 틈 0', (
    tester,
  ) async {
    await pump(tester);
    final band = tester.getRect(find.byKey(const ValueKey('calendar-band')));
    expect(band.left, 0);
    expect(band.right, 360);
    final month = tester.getRect(find.byType(CalendarMonthRow));
    final wk = tester.getRect(find.byType(CalendarWeekdayRow));
    final cell = tester.getRect(find.byType(CalendarDayCell).first);
    expect(month.top, band.top, reason: '머리 바로 아래 틈 0');
    expect(month.height, 52);
    expect(wk.top, month.bottom, reason: '달 줄 ↔ 요일 줄 틈 0');
    expect(wk.height, 32);
    expect(cell.top, wk.bottom, reason: '요일 줄 ↔ 격자 틈 0');
    for (final c in tester.widgetList(find.byType(CalendarDayCell))) {
      expect(tester.getSize(find.byWidget(c)).height, 103);
    }
    // 격자 폭: 좌우 2씩 안쪽, 칸 7개
    final cells = tester.widgetList(find.byType(CalendarDayCell)).length;
    expect(cells % 7, 0);
    expect(cells ~/ 7, inInclusiveRange(4, 6));
  });

  testWidgets('캘린더 고르기 칩 — 이름 · 점 8 겹침 −2', (tester) async {
    await pump(tester);
    expect(find.byType(PChip), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('캘린더 2개 보는 중')), findsOneWidget);
    final dots = tester.getSize(
      find.byKey(const ValueKey('calendar-filter-dots')),
    );
    expect(dots, const Size(8, 8), reason: '점 하나 · 겹침이 없다');
  });

  testWidgets('오늘 = 옅은 원 bg-neutral-weak + 700', (tester) async {
    await pump(tester);
    // 이웃 달 칸에 같은 숫자가 있을 수 있어 오늘 칸(이번 달)을 먼저 찾는다
    final todayCell = find.byWidgetPredicate(
      (w) =>
          w is CalendarDayCell &&
          !w.cell.isOutside &&
          w.cell.day == DateTime(now.year, now.month, now.day),
    );
    final todayText = find.descendant(
      of: todayCell,
      matching: findText('${now.day}'),
    );
    final text = tester.widget<Text>(todayText.first);
    expect(text.style?.fontWeight, FontWeight.w700);
    final box = tester.widget<Container>(
      find
          .ancestor(of: todayText.first, matching: find.byType(Container))
          .first,
    );
    final deco = box.decoration! as BoxDecoration;
    expect(deco.color, PColors.light.bgNeutralWeak);
  });

  testWidgets('22일 일정 다섯 → 칩 둘 + "+3개" (100%)', (tester) async {
    await pump(tester, events: five);
    expect(findPlainContaining('다섯째날일정'), findsNWidgets(2));
    expect(findText('+3개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('칸은 103 그대로 — 200% 에서 칩이 커지면 보이는 수가 줄고 넘침 0', (tester) async {
    await pump(tester, events: five, scale: 2.0);
    expect(tester.takeException(), isNull);
    expect(findText('+5개'), findsOneWidget);
    for (final c in tester.widgetList(find.byType(CalendarDayCell))) {
      expect(tester.getSize(find.byWidget(c)).height, 103);
    }
  });

  testWidgets('다크에서도 넘침 0', (tester) async {
    await pump(tester, events: five, dark: true, scale: 2.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('공휴일 칩이 첫 줄을 쓰고 그날 일정 수에 든다', (tester) async {
    final key =
        '${d22.year}-${d22.month.toString().padLeft(2, '0')}-${d22.day.toString().padLeft(2, '0')}';
    await pump(tester, events: five, holidays: {key: '큰공휴일'});
    expect(findPlain('큰공휴일'), findsOneWidget);
    // 공휴일 1 + 일정 5 = 6 → 칩 둘(공휴일 + 일정 하나) + "+4개"
    expect(findPlainContaining('다섯째날일정'), findsNWidgets(1));
    expect(findText('+4개'), findsOneWidget);
  });

  testWidgets('칸 전체가 누르는 자리 하나 — 칩 · "+N개" 가 따로 서지 않는다', (tester) async {
    await pump(tester, events: five);
    final handle = tester.ensureSemantics();
    final buttons = find.bySemanticsLabel(RegExp(r'^\d+월 \d+일 \(.\), \d+건$'));
    expect(buttons.evaluate().length, greaterThanOrEqualTo(28));
    handle.dispose();
  });

  testWidgets('이웃 달 칸을 누르면 달은 그대로 두고 그 날 시트를 연다(옛 앱 · 옛 웹과 같다)', (
    tester,
  ) async {
    await pump(tester);
    final cells = tester
        .widgetList<CalendarDayCell>(find.byType(CalendarDayCell))
        .toList();
    final outside = cells.firstWhere((c) => c.cell.isOutside);
    await tester.tap(find.byWidget(outside));
    await tester.pumpAndSettle();
    expect(findText('${now.year}년 ${now.month}월'), findsOneWidget);
    expect(findText('일정 추가'), findsOneWidget, reason: '그 날 시트가 열렸다');
  });
}
