// I-09 09-1 그날 시트 (11) — 줄 목록 · 줄 사이 선 0 · 꺾쇠 0 · 바닥 "일정 추가" 폭 전체 · 빈 날 R9.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

import '../../support/plain_text.dart';

const _cal = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);
const _longTitle = '분기 회고 · 다음 분기 목표 정리 회의(길게 쓴 제목이 줄을 바꿔 모두 보여야 한다)';

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
  String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  CalendarEvent ev(int id, String title, {bool allDay = false}) {
    String at(int h) => '${key(d22)}T${h.toString().padLeft(2, '0')}:00:00';
    return CalendarEvent(
      rowId: id,
      title: title,
      calendarRowId: 1,
      startDate: at(9 + id),
      endDate: at(10 + id),
      isAllDay: allDay ? 'Y' : 'N',
      calendarColor: '#2c70bf',
      labelName: id == 1 ? '라벨하나' : null,
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required List<CalendarEvent> events,
    Map<String, String> holidays = const {},
    double scale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCalendarListProvider.overrideWith((ref) async => const [_cal]),
          monthEventsProvider.overrideWith((ref, k) async => events),
          holidayListProvider.overrideWith(
            (ref, k) async => [
              for (final e in holidays.entries)
                Holiday(rowId: 1, holidayDate: e.key, holidayName: e.value),
            ],
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
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

  Future<void> openDay(WidgetTester tester, int day) async {
    await tester.tap(
      find
          .descendant(
            of: find.byType(CalendarScreen),
            matching: findText('$day'),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('그날 시트 — 제목 "M월 D일 (요)" · 공휴일 먼저 · 줄 사이 선 0 · 꺾쇠 0', (
    tester,
  ) async {
    await pump(
      tester,
      events: [ev(1, '첫째일정'), ev(2, '종일일정', allDay: true)],
      holidays: {key(d22): '공휴일하나'},
    );
    await openDay(tester, 22);
    const dows = ['일', '월', '화', '수', '목', '금', '토'];
    expect(
      findPlain('${d22.month}월 22일 (${dows[d22.weekday % 7]})'),
      findsOneWidget,
    );
    // 공휴일 줄은 보기만 하는 줄, 일정 줄은 누르는 줄
    expect(find.byType(PListItem), findsOneWidget);
    expect(find.byType(PListButtonItem), findsNWidgets(2));
    final holidayY = tester.getTopLeft(find.byType(PListItem)).dy;
    final firstEventY = tester
        .getTopLeft(find.byType(PListButtonItem).first)
        .dy;
    expect(holidayY, lessThan(firstEventY));
    // 꺾쇠 없음 · 줄 사이 선 없음
    expect(
      find.descendant(
        of: find.byType(PList),
        matching: find.byIcon(LucideIcons.chevronRight),
      ),
      findsNothing,
    );
    expect(find.byType(PListDivider), findsNothing);
    // 설명 "{시각} · {캘린더} · {라벨}"
    expect(findPlainContaining('개인 · 라벨하나'), findsOneWidget);
    expect(findPlainContaining('종일 · 개인'), findsOneWidget);
    expect(findPlain('공휴일'), findsOneWidget);
  });

  testWidgets('바닥 "일정 추가" 는 폭 전체 large 48 이고 머리 아래 "N건 +" 줄이 없다', (
    tester,
  ) async {
    await pump(tester, events: [ev(1, '첫째일정')]);
    await openDay(tester, 22);
    final add = find.widgetWithText(PButton, '일정 추가');
    expect(add, findsOneWidget);
    final r = tester.getRect(add);
    expect(r.left, 24);
    expect(r.right, 336);
    expect(r.height, 48);
    expect(findTextContaining('건'), findsNothing);
    expect(find.byIcon(LucideIcons.plus), findsNothing);
  });

  testWidgets('일정 없는 날 — 해요체 한 문장 · 바닥 버튼은 그대로', (tester) async {
    await pump(tester, events: [ev(1, '첫째일정')]);
    await openDay(tester, 10);
    expect(findPlain('이 날에 일정이 없어요.'), findsOneWidget);
    expect(find.widgetWithText(PButton, '일정 추가'), findsOneWidget);
  });

  testWidgets('가장 나쁜 값 — 50자 제목이 모두 보이고 200% 에서도 넘침 0', (tester) async {
    await pump(tester, events: [ev(1, _longTitle)], scale: 2.0);
    await openDay(tester, 22);
    // 격자 칩(말줄임)과 시트 줄 둘 — 시트 줄은 줄 수 제한 · 말줄임이 없다
    expect(findPlain(_longTitle), findsNWidgets(2));
    final sheetTitle = tester.widget<Text>(
      find.descendant(
        of: find.byType(PListButtonItem),
        matching: find.byKey(const ValueKey('plist-title')),
      ),
    );
    expect(sheetTitle.maxLines, isNull);
    expect(sheetTitle.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  testWidgets('일정 줄을 누르면 시트가 닫히고 상세가 뜬다', (tester) async {
    await pump(tester, events: [ev(1, '첫째일정')]);
    await openDay(tester, 22);
    await tester.tap(find.byType(PListButtonItem));
    await tester.pumpAndSettle();
    expect(find.byType(PList), findsNothing, reason: '그날 시트가 닫혔다');
  });
}
