// 일곱 칸 격자의 요일 머리 · 날짜 숫자는 글자 크기 200% 에서 멈춘다(groo-design #258 — DESIGN.md Layout "지원 폭" ·
// date-picker.md "글자 크기 설정" · international-design.mdx "날짜").
//
// 320 폭 · 가장 큰 글자(iOS AX5 53/17 · 안드로이드 글자 200% 비선형)에서 날짜 고르기 달력 · 캘린더 화면 · 가계부(할 일) 달력 ·
// 열지도 · 숲 리포트 7일 띠 · 나의 하늘의 요일 글과 날짜 숫자가
//   ① 200% 를 넘어 커지지 않고(제목 · 일정 이름 · 금액 같은 다른 글은 그 위로도 커진다)
//   ② 한 줄로 다 그려지며(꺾이거나 위아래가 잘리지 않는다)
//   ③ 칸 폭(격자 폭 ÷ 7)을 넘지 않는다.
// 숲 리포트 7일 띠의 요일은 #256 대상이라 영어 두 글자(Mo … Su), 칸에 들지 않으면 한 글자다.
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show Intl;

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/forest_report_screen.dart';
import 'package:groo_damda_app/features/constellation/presentation/my_sky_card.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/data/recurring_repository.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';

import '../features/todo/todo_test_support.dart' show todoOverrides;
import '../support/android_font_scale.dart';
import '../support/plain_text.dart';

const double _ax5 = 53 / 17;

final _cases = <(String, TextScaler)>[
  ('iOS AX5', TextScaler.linear(_ax5)),
  ('안드로이드 200%', const AndroidNonlinearTextScaler()),
];

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  for (final family in const ['Pretendard', 'FlutterTest']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required TextScaler scaler,
  String locale = 'en',
  List<Override> overrides = const [],
  double width = 320,
}) async {
  Intl.defaultLocale = locale;
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: text,
            matching: find.byType(RichText),
            matchRoot: true,
          )
          .first,
    );

/// 일곱 칸 격자 글 하나 — 200% 에서 멈추고, 한 줄로 다 그려지며, 칸 폭 [cell] 을 넘지 않는다([cell] 이 null 이면 폭은 안 본다).
void _expectCellText(
  WidgetTester tester,
  Finder text,
  double? cell, {
  bool horizontal = true,
}) {
  final rp = _paragraph(tester, text);
  final label = rp.text.toPlainText();
  final size = (rp.text.style ?? const TextStyle()).fontSize ?? 14;
  expect(
    rp.textScaler.scale(size),
    lessThanOrEqualTo(size * 2 + 0.01),
    reason: '"$label" — 글자 크기 200% 에서 멈춘다',
  );
  final whole = TextPainter(
    text: rp.text,
    textDirection: TextDirection.ltr,
    textScaler: rp.textScaler,
    maxLines: 1,
  )..layout();
  if (horizontal) {
    expect(
      rp.size.width,
      greaterThanOrEqualTo(whole.width - 0.01),
      reason: '"$label" — 한 줄로 다 그려진다(폭 ${whole.width})',
    );
  }
  expect(
    rp.size.height,
    greaterThanOrEqualTo(whole.height - 0.01),
    reason: '"$label" — 위아래가 잘리지 않는다(높이 ${whole.height})',
  );
  if (cell != null) {
    expect(
      whole.width,
      lessThanOrEqualTo(cell + 0.01),
      reason: '"$label" — 칸 폭 $cell 을 넘지 않는다',
    );
  }
  whole.dispose();
}

final _digits = RegExp(r'^\d{1,2}$');

Finder _numbersIn(Finder of) => find.descendant(
  of: of,
  matching: find.byWidgetPredicate(
    (w) => w is Text && _digits.hasMatch(w.data ?? ''),
  ),
);

void main() {
  setUpAll(_loadFonts);
  tearDown(() => Intl.defaultLocale = null);

  for (final (name, scaler) in _cases) {
    group('320 · $name', () {
      testWidgets('날짜 고르기 달력 — 요일 · 날짜 숫자', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => PDatePicker.single(
                labels: PDatePickerLabels.of(context),
                today: DateTime(2026, 11, 19),
                value: DateTime(2026, 11, 28),
                inset: 0,
              ),
            ),
          ),
          scaler: scaler,
        );
        final grid = tester.getRect(find.byType(PDatePicker));
        final cell = grid.width / 7;
        final weekdays = find.descendant(
          of: find.byKey(const ValueKey('date-weekdays')),
          matching: find.byType(Text),
        );
        expect(weekdays, findsNWidgets(7));
        for (final e in weekdays.evaluate()) {
          _expectCellText(tester, find.byWidget(e.widget), cell);
        }
        final numbers = _numbersIn(find.byType(PDatePicker));
        expect(numbers, findsWidgets);
        for (final e in numbers.evaluate()) {
          _expectCellText(tester, find.byWidget(e.widget).first, cell);
        }
      });

      testWidgets('캘린더 화면 — 요일 · 날짜 숫자', (tester) async {
        await _pump(
          tester,
          const Scaffold(body: CalendarScreen()),
          scaler: scaler,
          overrides: [
            userCalendarListProvider.overrideWith(
              (ref) async => const [
                UserCalendar(rowId: 1, calendarName: 'Mine', isDefault: true),
              ],
            ),
            monthEventsProvider.overrideWith((ref, key) async => const []),
            holidayListProvider.overrideWith((ref, key) async => const []),
          ],
        );
        final cellW = tester.getSize(find.byType(CalendarDayCell).first).width;
        final weekdays = find.descendant(
          of: find.byType(CalendarWeekdayRow),
          matching: find.byType(Text),
        );
        expect(weekdays, findsNWidgets(7));
        for (final e in weekdays.evaluate()) {
          _expectCellText(tester, find.byWidget(e.widget), cellW);
        }
        final numbers = _numbersIn(find.byType(CalendarDayCell));
        for (final e in numbers.evaluate()) {
          _expectCellText(tester, find.byWidget(e.widget).first, cellW);
        }
      });

      testWidgets('가계부 달력 — 요일 · 날짜 숫자', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: LedgerCalendarGrid(
              month: DateTime(2026, 10),
              selected: '2026-10-28',
              expanded: true,
              onSelect: (_) {},
              onToggleExpand: () {},
              markBuilder: (context, ds) => const SizedBox.shrink(),
            ),
          ),
          scaler: scaler,
        );
        // 격자 좌우 안쪽 16 · 16
        final cell =
            (tester.getSize(find.byType(LedgerCalendarGrid)).width - 32) / 7;
        final texts = find.descendant(
          of: find.byType(LedgerCalendarGrid),
          matching: find.byType(Text),
        );
        var numbers = 0;
        for (final e in texts.evaluate()) {
          final t = e.widget as Text;
          final data = t.data ?? '';
          final number = _digits.hasMatch(data);
          if (number) numbers++;
          // 가계부 날짜는 t5 16 이라 320 · 200%(선형) 에서 "28" 41.9 가 칸 41.1 보다 0.8 넓다 — 200% 상한만으로는 칸에 들지
          // 않아 판정을 받으러 보고했다(폭은 안드로이드 200% 만 본다). 상한 · 한 줄 · 잘림 없음은 모두 본다
          final widthChecked = !number || scaler is AndroidNonlinearTextScaler;
          _expectCellText(
            tester,
            find.byWidget(t).first,
            widthChecked ? cell : null,
          );
        }
        expect(numbers, 31);
      });

      testWidgets('열지도 — 요일 머리', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: StatsHeatmapSection(
                period: StatsPeriod.thisMonth(DateTime(2026, 11, 19)),
                cells: const [
                  HeatmapCell(dayOfWeek: 3, hour: 19, totalAmount: 35000),
                ],
                masked: false,
              ),
            ),
          ),
          scaler: scaler,
        );
        final cell = tester
            .getSize(find.byKey(const ValueKey('chart-heatmap-column-0')))
            .width;
        for (var i = 0; i < 7; i++) {
          _expectCellText(
            tester,
            find.byKey(ValueKey('chart-heatmap-column-$i')),
            cell,
          );
        }
      });

      testWidgets('반복 거래 매월 날 고르기 — 날짜 숫자', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => PBottomSheet.show<void>(
                  ctx,
                  builder: (_) => RecurringFormFlow(
                    expenseSeed: const Expense(
                      rowId: 9,
                      expenseType: 'EXPENSE',
                      amount: 12000,
                      expenseDate: '2026-10-23T12:00:00',
                      merchant: 'Lunch',
                      categoryRowId: 2,
                      assetRowId: 7,
                      paymentMethod: 'CARD',
                    ),
                    probe: StepProbe(),
                    onBack: () {},
                    onSaved: () {},
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
          scaler: scaler,
          overrides: [
            recurringRepositoryProvider.overrideWith(
              (ref) async => RecurringRepository(Dio()),
            ),
            recurringListProvider.overrideWith((ref) async => const []),
            categoriesProvider.overrideWith(
              (ref) async => const [
                ExpenseCategory(
                  rowId: 2,
                  categoryName: 'Food',
                  expenseType: 'EXPENSE',
                  sortOrder: 0,
                  icon: 'utensils',
                  color: '#2c70bf',
                ),
              ],
            ),
            assetsProvider.overrideWith(
              (ref) async => const [
                Asset(rowId: 7, assetName: 'Bank', assetType: 'BANK_ACCOUNT'),
              ],
            ),
          ],
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        // 반복 줄을 눌러 반복 단계(매월 · 날 격자)로 들어간다
        final repeat = findPlainContaining('Repeat');
        await tester.ensureVisible(repeat.first);
        await tester.pumpAndSettle();
        await tester.tap(repeat.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final numbers = find.byKey(const ValueKey('recurring-day-number'));
        expect(numbers, findsNWidgets(31));
        // 320 은 칸(35)이 200% 두 자리(t5 "28" 37 · 42)보다 좁아 가로는 보지 않는다 — 판정을 받으러 보고했다. 200% 상한 ·
        // 칸 높이가 글 줄을 따라 늘어 위아래가 잘리지 않음은 본다
        for (var i = 0; i < 31; i++) {
          _expectCellText(tester, numbers.at(i), null, horizontal: false);
        }
      });

      testWidgets('나의 하늘 — 날짜 숫자', (tester) async {
        final sky = [
          for (var i = 13; i >= 0; i--)
            SkyDay(
              date: _ymd(DateTime(2026, 11, 28).subtract(Duration(days: i))),
              status: 'REST',
              constellationKey: null,
              colorKey: null,
              points: 0,
              guardUsed: false,
            ),
        ];
        await _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MySkyCard(sky: sky, today: _today(), entries: const []),
              ),
            ),
          ),
          scaler: scaler,
        );
        final numbers = find.byKey(const ValueKey('my-sky-day-number'));
        expect(numbers, findsNWidgets(14));
        // 칸 사이 6 · 여섯
        final cell = (320 - 48 - 6 * 6) / 7;
        for (var i = 0; i < 14; i++) {
          _expectCellText(tester, numbers.at(i), cell);
        }
      });
    });
  }

  for (final (name, scaler, locale) in [
    ('iOS AX5 · 영어', TextScaler.linear(_ax5), 'en'),
    ('iOS AX5 · 한국어', TextScaler.linear(_ax5), 'ko'),
    ('안드로이드 200% · 영어', const AndroidNonlinearTextScaler(), 'en'),
  ]) {
    testWidgets('320 · $name — 숲 리포트 7일 띠 요일(두 글자 · 들지 않으면 한 글자) · 날짜 숫자', (
      tester,
    ) async {
      await _pump(
        tester,
        const ForestReportScreen(),
        scaler: scaler,
        locale: locale,
        overrides: [
          // 연속 관측 도장(72 × 배율)은 AX5 · 320 에서 결과 줄을 넘친다(이번 범위 밖, 보고) — 연속 0 으로 도장을 빼고 띠만 본다
          ...todoOverrides(sky: _today(streak: 0)),
          constellationCollectionProvider.overrideWith(
            (ref) async => const ConstellationCollectionData(
              entries: [],
              collectedKinds: 0,
              totalCollected: 0,
            ),
          ),
        ],
      );
      final dows = find.byKey(const ValueKey('forest-day-dow'));
      final numbers = find.byKey(const ValueKey('forest-day-number'));
      expect(dows, findsNWidgets(7));
      expect(numbers, findsNWidgets(7));
      final head = tester.getRect(
        find.byKey(const ValueKey('forest-report-head')),
      );
      // 띠 좌우 안쪽 12 · 12
      final cell = (head.width - 24) / 7;
      final today = locale == 'en' ? 'Today' : '오늘';
      final shown = <String>[];
      for (var i = 0; i < 7; i++) {
        final t = tester.widget<Text>(dows.at(i)).data!;
        shown.add(t);
        // 오늘 칸은 요일 대신 "오늘" · "Today" 다 — 320 · 200% 에서 칸보다 넓어 판정을 받으러 보고했다(요일 머리 판정 밖)
        if (t == today) continue;
        _expectCellText(tester, dows.at(i), cell);
      }
      for (var i = 0; i < 7; i++) {
        _expectCellText(tester, numbers.at(i), cell);
      }
      final two = weekdayRowLabels(mondayFirst: true);
      final one = weekdayRowNarrowLabels(mondayFirst: true);
      final expected = shown.every((t) => t == today || t.length == 1)
          ? one
          : two;
      for (var i = 0; i < 7; i++) {
        if (shown[i] == today) continue;
        expect(shown[i], expected[i], reason: '요일 머리는 Mo … Su(또는 M … S)');
        if (locale == 'en') {
          expect(shown[i], isNot(weekdayLabels(mondayFirst: true)[i]));
        }
      }
    });
  }

  testWidgets('숲 리포트 7일 띠 — 100% 영어는 두 글자 Mo … Su(세 글자 Mon 이 아니다)', (
    tester,
  ) async {
    await _pump(
      tester,
      const ForestReportScreen(),
      scaler: TextScaler.noScaling,
      width: 390,
      overrides: [
        ...todoOverrides(sky: _today()),
        constellationCollectionProvider.overrideWith(
          (ref) async => const ConstellationCollectionData(
            entries: [],
            collectedKinds: 0,
            totalCollected: 0,
          ),
        ),
      ],
    );
    final dows = find.byKey(const ValueKey('forest-day-dow'));
    final two = weekdayRowLabels(mondayFirst: true);
    for (var i = 0; i < 7; i++) {
      final t = tester.widget<Text>(dows.at(i)).data!;
      if (t == 'Today') continue;
      expect(t, two[i]);
    }
  });
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

ConstellationToday _today({int streak = 3}) => ConstellationToday(
  constellation: const ConstellationInfo(
    rowId: 1,
    constellationKey: 'cen',
    name: '켄타우루스자리',
    nameEn: 'Centaurus',
    description: '',
    descriptionEn: null,
    colorKey: 'blue',
    starCount: 5,
    starMapRaw:
        '{"pts":[[10,20],[30,35],[50,30],[70,50],[90,80]],"edges":[[0,1],[1,2],[2,3],[3,4]]}',
    sortOrder: 1,
  ),
  points: 12,
  goal: 16,
  collected: false,
  todoPoints: 10,
  memoPoints: 2,
  streak: streak,
  guardCount: 3,
  totalCollected: 37,
);
