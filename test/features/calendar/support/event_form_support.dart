// 일정 폼(시트) 시험의 공통 길잡이 — 시트를 띄우고, 줄을 누르고, 고르기 시트에서 고르고, 한 단계에 글을 쓴다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import '../../../support/plain_text.dart';

/// 일정 시트를 띄운다 — 폰 폭 390 · 아주 긴 높이(줄 아홉이 다 그려진다).
Future<void> openEventForm(
  WidgetTester tester, {
  required CalendarRepository repo,
  List<UserCalendar> calendars = const [
    UserCalendar(rowId: 1, calendarName: '개인', isDefault: true),
  ],
  List<EventLabel>? labels = const [],
  CalendarEvent? edit,
  DateTime? defaultDate,
  double scale = 1,
  Size size = const Size(390, 2000),
  Map<MonthYM, int>? monthBuilds,
  List<MonthYM> watchMonths = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final savedNow = calendarNow;
  calendarNow = () => DateTime(2026, 10, 29, 13);
  addTearDown(() => calendarNow = savedNow);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calendarRepositoryProvider.overrideWith((ref) async => repo),
        eventLabelsProvider.overrideWith(
          (ref) async => labels ?? (throw Exception('boom')),
        ),
        userCalendarListProvider.overrideWith((ref) async => calendars),
        monthEventsProvider.overrideWith((ref, key) async {
          if (monthBuilds != null) {
            monthBuilds[key] = (monthBuilds[key] ?? 0) + 1;
          }
          return <CalendarEvent>[];
        }),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showCalendarEventDialog(
                    ctx,
                    edit: edit,
                    defaultDate: defaultDate ?? DateTime(2026, 10, 29),
                  ),
                  child: const Text('open'),
                ),
              ),
              // 이미 받아 둔 달 — 저장 · 삭제가 어느 달을 다시 받게 하는지 센다
              for (final m in watchMonths)
                Consumer(
                  builder: (context, ref, _) {
                    ref.watch(monthEventsProvider(m));
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

/// 줄 제목(ds List 의 제목 글) — 시트 위 고르기 시트의 줄도 같은 글이다.
Finder rowTitle(String title) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      w.key == const ValueKey('plist-title') &&
      w.semanticsLabel == title,
);

Future<void> tapRow(WidgetTester tester, String title) async {
  await tester.tap(rowTitle(title).last);
  await tester.pumpAndSettle();
}

/// 제목 칸에 쓴다.
Future<void> enterTitle(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pumpAndSettle();
}

/// 시트의 [PButton] 을 라벨로 집는다(맨 위 시트의 것).
Finder button(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(button(label).last);
  await tester.pumpAndSettle();
}

/// 장소 · 설명 한 단계에 글을 쓰고 "완료" 한다 — 줄을 눌러 들어가 → 쓰고 → 완료.
Future<void> writeStep(
  WidgetTester tester, {
  required String row,
  required String text,
  required String done,
}) async {
  await tapRow(tester, row);
  await tester.enterText(find.byType(TextField).last, text);
  await tester.pumpAndSettle();
  await tapButton(tester, done);
}

String _plain(Text w) => (w.data ?? w.textSpan?.toPlainText() ?? '')
    .replaceAll('⁠', '')
    .replaceAll('￼', '');

/// 줄 값 글 — 값은 낱말 단위 줄바꿈(keepAll)이 끼어 있어 그것을 걷고 비교한다.
Finder valueText(String text) => find.byWidgetPredicate(
  (w) => w is Text && _plain(w) == text,
  description: 'Text "$text"',
);

Finder valueTextContaining(String text) => find.byWidgetPredicate(
  (w) => w is Text && _plain(w).contains(text),
  description: 'Text containing "$text"',
);
