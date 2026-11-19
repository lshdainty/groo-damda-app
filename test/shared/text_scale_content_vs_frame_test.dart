// 글자 크기 두 갈래 — 크게 보여 줄 내용만 커지고 디자인 틀은 그대로 둔다(groo-design #260 · #261, DESIGN.md Typography
// "글자 크기 설정을 따르는 것과 그대로 두는 것", 사용자 결정 2026-11-19).
//
// ⓐ 그대로 두는 것 — 글자를 키워도(선형 200% · 300%, 안드로이드 200% 비선형) 글이 배율 없이(TextScaler.noScaling) 그려지고 칸 ·
//    원 · 줄 높이가 100% 와 같다: 날짜 고르기 달력 · 기간 시트 · 캘린더 칸 · 가계부 · 할 일 달력(칸 아래 표시까지) · 열지도 ·
//    반복 매월 날 고르기 · 나의 하늘 · 숲 리포트 7일 띠 · 요일 막대 · 연속 관측 도장 · 저축률 고리 · 배지. 칸마다 상한을 두지
//    않는다.
// ⓑ 커지는 것 — 시트 내용 · 버튼 글 · 툴팁 · 지표 타일 합계 · 표로 보기 · 저축률 범례 금액 · 날짜 고르기 머리 제목은 글자를
//    따라 커진다. 버튼이 커지면 놓인 자리(가계부 "소비 요약" 44)도 최소 높이로 따라 늘어난다.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show Intl;

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/forest_report_screen.dart';
import 'package:groo_damda_app/features/constellation/presentation/my_sky_card.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/data/recurring_repository.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_trend_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';

import '../features/todo/todo_test_support.dart' show todoOverrides;
import '../support/android_font_scale.dart';
import '../support/plain_text.dart';

/// 큰 글자 — 선형 200% · 300%, 안드로이드 글자 200%(비선형).
final _big = <(String, TextScaler)>[
  ('200%', const TextScaler.linear(2)),
  ('300%', const TextScaler.linear(3)),
  ('안드로이드 200%', const AndroidNonlinearTextScaler()),
];

const double _ax4 = 47 / 17;
const double _ax5 = 53 / 17;

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
  String locale = 'ko',
  List<Override> overrides = const [],
  double width = 320,
  double height = 900,
}) async {
  Intl.defaultLocale = locale;
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // 앞 배율에서 연 시트 · 고른 상태를 버리고 새로 그린다
  await tester.pumpWidget(const SizedBox.shrink());
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

/// 그려진 글 하나가 키운 배율 — 글자 크기 [fontSize] 를 몇 배로 그리는가.
double _drawnScale(RenderParagraph rp) {
  final size = rp.text.style?.fontSize ?? 14;
  return rp.textScaler.scale(size) / size;
}

/// [of] 안의 그려진 글 모두 — 배율 없이(100% 크기로) 그려진다. 적어도 [min] 개는 있다.
void _expectStatic(WidgetTester tester, Finder of, {int min = 1}) {
  final paragraphs = find
      .descendant(of: of, matching: find.byType(RichText), matchRoot: true)
      .evaluate()
      .map((e) => e.renderObject! as RenderParagraph)
      .toList();
  expect(paragraphs.length, greaterThanOrEqualTo(min));
  for (final rp in paragraphs) {
    expect(
      _drawnScale(rp),
      1,
      reason: '"${rp.text.toPlainText()}" 은 글자 크기 설정을 따르지 않는다(그대로 두는 것)',
    );
  }
}

/// [text] 가 글자 크기 설정을 따라 커진다 — 100% 보다 1.4 배 이상(안드로이드 비선형 200% 의 큰 글도 넘는다).
void _expectGrows(WidgetTester tester, Finder text) {
  final rp = tester.renderObject<RenderParagraph>(
    find
        .descendant(of: text, matching: find.byType(RichText), matchRoot: true)
        .first,
  );
  expect(
    _drawnScale(rp),
    greaterThan(1.4),
    reason: '"${rp.text.toPlainText()}" 은 글자 크기 설정을 따라 커진다(커지는 것)',
  );
}

/// [finders] 의 크기 — 100% 와 견주려고 잰다.
List<Size> _sizes(WidgetTester tester, List<Finder> finders) => [
  for (final f in finders) tester.getSize(f),
];

Future<void> _expectFrameSame(
  WidgetTester tester, {
  required String name,
  required Future<void> Function(TextScaler scaler) pump,
  required List<Finder> Function() boxes,
  required Finder Function() texts,
  int minTexts = 1,
}) async {
  await pump(TextScaler.noScaling);
  final base = _sizes(tester, boxes());
  for (final (label, scaler) in _big) {
    await pump(scaler);
    _expectStatic(tester, texts(), min: minTexts);
    expect(
      _sizes(tester, boxes()),
      base,
      reason: '$name · $label — 칸 · 원 · 줄 높이가 100% 와 같다',
    );
  }
}

CalendarEvent _ev(int id, String title, DateTime day) {
  String at(int h) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}T${h.toString().padLeft(2, '0')}:00:00';
  return CalendarEvent(
    rowId: id,
    title: title,
    calendarRowId: 1,
    startDate: at(9 + id),
    endDate: at(10 + id),
    calendarColor: '#2c70bf',
  );
}

void main() {
  setUpAll(_loadFonts);
  tearDown(() => Intl.defaultLocale = null);

  group('ⓐ 그대로 두는 것 — 큰 글자에서도 글 · 칸이 100% 와 같다', () {
    testWidgets('날짜 고르기 달력 — 요일 · 날짜 숫자 · 칸 48 · 요일 줄 48(머리 제목만 커진다)', (
      tester,
    ) async {
      final day = find.byKey(const ValueKey('date-2026-11-19'));
      await _expectFrameSame(
        tester,
        name: '날짜 고르기',
        pump: (s) => _pump(
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
          scaler: s,
        ),
        boxes: () => [find.byKey(const ValueKey('date-weekdays')), day],
        texts: () => find.byType(PDatePickerDayCell),
        minTexts: 28,
      );
      _expectStatic(
        tester,
        find.byKey(const ValueKey('date-weekdays')),
        min: 7,
      );
      // 머리 제목은 커지는 쪽이다
      _expectGrows(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('date-title')),
          matching: find.byType(Text),
        ),
      );
    });

    test('기간 시트 본문 바닥 — 칩 줄만 커지고 요일 줄 + 2주(48 × 3)는 그대로', () {
      for (final (_, s) in [('100%', TextScaler.noScaling), ..._big]) {
        expect(
          PDatePicker.sheetBodyMinHeight(s) - chipHeight(PChipSize.medium, s),
          12 + 3 * kDatePickerCellHeight,
        );
      }
    });

    testWidgets('캘린더 칸 — 요일 · 날짜 · 일정 이름 · "+N개" · 날 숫자 원 26 · 칸 103', (
      tester,
    ) async {
      final month = DateTime(2026, 11);
      final d22 = DateTime(2026, 11, 22);
      final five = [for (var i = 1; i <= 5; i++) _ev(i, '일정$i', d22)];
      Future<void> pump(TextScaler s) => _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const CalendarWeekdayRow(),
                CalendarMonthGrid(
                  month: month,
                  events: five,
                  holidays: const {'2026-11-03': '개천절'},
                  onDayTap: (_) {},
                ),
              ],
            ),
          ),
        ),
        scaler: s,
      );
      await _expectFrameSame(
        tester,
        name: '캘린더',
        pump: pump,
        boxes: () => [
          find.byType(CalendarWeekdayRow),
          find.byType(CalendarDayCell).first,
          find.byType(CalendarMonthGrid),
        ],
        texts: () => find.byType(CalendarMonthGrid),
        minTexts: 30,
      );
      _expectStatic(tester, find.byType(CalendarWeekdayRow), min: 7);
      // 칸 안 글이 커지지 않으니 보이는 칩 수도 100% 와 같다 — 칩 둘 + "+3개"
      expect(findText('+3개'), findsOneWidget);
      expect(findPlain('개천절'), findsOneWidget);
    });

    testWidgets('가계부 · 할 일 달력 — 요일 · 날짜 숫자 · 칸 아래 표시(groo-design #261)', (
      tester,
    ) async {
      await _expectFrameSame(
        tester,
        name: '가계부 달력',
        pump: (s) => _pump(
          tester,
          Scaffold(
            body: LedgerCalendarGrid(
              month: DateTime(2026, 10),
              selected: '2026-10-28',
              expanded: true,
              onSelect: (_) {},
              onToggleExpand: () {},
              markBuilder: (context, ds) => Text(
                '−4,500',
                key: ValueKey('mark-$ds'),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
          scaler: s,
        ),
        boxes: () => [find.byType(LedgerCalendarGrid)],
        texts: () => find.byType(LedgerCalendarGrid),
        minTexts: 7 + 31 * 2,
      );
    });

    testWidgets('열지도 — 요일 머리 · 시간대 라벨 · 줄 높이', (tester) async {
      await _expectFrameSame(
        tester,
        name: '열지도',
        pump: (s) => _pump(
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
          scaler: s,
        ),
        boxes: () => [find.byKey(const ValueKey('chart-heatmap'))],
        texts: () => find.byKey(const ValueKey('chart-heatmap')),
        minTexts: 7 + 12,
      );
    });

    testWidgets('반복 거래 매월 날 고르기 — 날짜 숫자 · 칸 40', (tester) async {
      final overrides = <Override>[
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
      ];
      final numbers = find.byKey(const ValueKey('recurring-day-number'));
      Future<void> open(TextScaler s) async {
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
          scaler: s,
          locale: 'en',
          overrides: overrides,
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
        expect(numbers, findsNWidgets(31));
      }

      // 칸(누르는 자리) — 날짜 글을 담은 가장 가까운 SizedBox
      Finder cell(int i) => find
          .ancestor(of: numbers.at(i), matching: find.byType(SizedBox))
          .first;
      await _expectFrameSame(
        tester,
        name: '반복 날 고르기',
        pump: open,
        boxes: () => [cell(0), cell(30)],
        texts: () => numbers,
        minTexts: 31,
      );
      expect(tester.getSize(cell(0)).height, 40);
    });

    testWidgets('나의 하늘 — 날짜 숫자 · 칸', (tester) async {
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
      await _expectFrameSame(
        tester,
        name: '나의 하늘',
        pump: (s) => _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MySkyCard(sky: sky, today: _today(), entries: const []),
              ),
            ),
          ),
          scaler: s,
        ),
        boxes: () => [find.byKey(const ValueKey('my-sky-day-number')).first],
        texts: () => find.byKey(const ValueKey('my-sky-day-number')),
        minTexts: 14,
      );
    });

    testWidgets('숲 리포트 — 7일 띠(요일 · "오늘" · 날짜 · 원 36) · 요일 막대 원 28 · 도장 72', (
      tester,
    ) async {
      final overrides = <Override>[
        ...todoOverrides(sky: _today()),
        constellationCollectionProvider.overrideWith(
          (ref) async => const ConstellationCollectionData(
            entries: [],
            collectedKinds: 0,
            totalCollected: 0,
          ),
        ),
      ];
      final number = find.byKey(const ValueKey('forest-day-number'));
      Finder circle(int i) => find
          .ancestor(of: number.at(i), matching: find.byType(Container))
          .first;
      Finder all() => find.byWidgetPredicate(
        (w) =>
            w.key == const ValueKey('forest-day-dow') ||
            w.key == const ValueKey('forest-day-number') ||
            w.key == const ValueKey('forest-bar-dow'),
      );
      await _expectFrameSame(
        tester,
        name: '숲 리포트',
        pump: (s) => _pump(
          tester,
          const ForestReportScreen(),
          scaler: s,
          width: 390,
          height: 2400,
          overrides: overrides,
        ),
        boxes: () => [
          circle(0),
          circle(6),
          find.byKey(const ValueKey('report-stamp')),
          for (final e
              in find
                  .byKey(const ValueKey('forest-bar-dow'))
                  .evaluate()
                  .take(1))
            find
                .ancestor(
                  of: find.byWidget(e.widget),
                  matching: find.byType(Container),
                )
                .first,
        ],
        texts: all,
        minTexts: 21,
      );
      _expectStatic(tester, find.byKey(const ValueKey('report-stamp')), min: 2);
      expect(tester.getSize(circle(0)), const Size(36, 36));
      expect(
        tester.getSize(find.byKey(const ValueKey('report-stamp'))).width,
        72,
      );
    });

    testWidgets('저축률 고리 — 108 · 안의 글 그대로, 옆 범례 금액은 커진다', (tester) async {
      await _expectFrameSame(
        tester,
        name: '저축률 고리',
        pump: (s) => _pump(
          tester,
          Scaffold(
            body: Column(
              children: [
                const StatsSavingsRing(rate: 42),
                StatsSavingsLegendRow(
                  name: '순저축 42%',
                  amount: '420,000원',
                  dot: Colors.blue,
                ),
              ],
            ),
          ),
          scaler: s,
        ),
        boxes: () => [find.byType(StatsSavingsRing)],
        texts: () => find.byType(StatsSavingsRing),
        minTexts: 2,
      );
      expect(
        tester.getSize(find.byType(StatsSavingsRing)),
        const Size(108, 108),
      );
      _expectGrows(tester, find.byKey(const ValueKey('savings-legend-amount')));
    });

    testWidgets('배지 — 글 · 상자 그대로(badge.yaml text-t1-static · t2-static)', (
      tester,
    ) async {
      await _expectFrameSame(
        tester,
        name: '배지',
        pump: (s) => _pump(
          tester,
          const Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PBadge(label: '예정'),
                PBadge(label: '연체', size: PBadgeSize.large),
              ],
            ),
          ),
          scaler: s,
        ),
        boxes: () => [find.byType(PBadge).first, find.byType(PBadge).last],
        texts: () => find.byType(PBadge),
        minTexts: 2,
      );
    });
  });

  group('ⓑ 커지는 것 — 글자 크기 설정을 따라 커진다', () {
    for (final (name, scaler) in _big) {
      testWidgets('$name — 시트 내용 · 버튼 글 · 글 버튼 · 툴팁 · 지표 타일 합계 · 표로 보기', (
        tester,
      ) async {
        await _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PButton(label: '저장', onPressed: () {}),
                  PTextButton(label: '설정', onPressed: () {}),
                  const PChartTooltip(
                    head: '11월 19일',
                    rows: [PChartTooltipRow(name: '지출', value: '35,000원')],
                  ),
                  const PChartLegendTiles(
                    items: [
                      PChartLegendItem(
                        key: 'out',
                        label: '지출',
                        color: PChartColor.red,
                        total: '1,240,000원',
                      ),
                    ],
                  ),
                  const PChartDataTable(
                    caption: '날짜별 지출',
                    visuallyHidden: false,
                    columns: [PChartDataColumn('날짜'), PChartDataColumn('지출')],
                    rows: [
                      ['11월 19일', '35,000원'],
                    ],
                  ),
                  Builder(
                    builder: (ctx) => TextButton(
                      onPressed: () => PBottomSheet.show<void>(
                        ctx,
                        builder: (_) => const Text(
                          '시트 본문',
                          key: ValueKey('sheet-body-text'),
                        ),
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          scaler: scaler,
          width: 402,
        );
        _expectGrows(tester, findText('저장'));
        _expectGrows(tester, find.byKey(const ValueKey('text-button-label')));
        _expectGrows(tester, find.byKey(const ValueKey('chart-tooltip-value')));
        _expectGrows(tester, find.byKey(const ValueKey('chart-legend-total')));
        _expectGrows(
          tester,
          find.descendant(
            of: find.byKey(const ValueKey('chart-data-table')),
            matching: findText('35,000원'),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        _expectGrows(tester, find.byKey(const ValueKey('sheet-body-text')));
      });
    }

    group('가계부 "소비 요약" 단추 — 단추가 커지면 놓인 자리 44 도 최소 높이로 따라 늘어난다', () {
      Widget row() => LedgerTotalRow(
        total: '29,430원',
        insight: null,
        summaryOpen: false,
        onToggleSummary: () {},
      );
      for (final (name, scale) in [('AX4', _ax4), ('AX5', _ax5)]) {
        for (final width in [320.0, 402.0]) {
          testWidgets(
            'iOS $name · ${width.round()} — 단추 글이 위아래 잘리지 않고 자리가 단추를 담는다',
            (tester) async {
              await _pump(
                tester,
                Scaffold(body: SingleChildScrollView(child: row())),
                scaler: TextScaler.linear(scale),
                width: width,
              );
              final button = find.byType(PButton);
              expect(button, findsOneWidget);
              final label = find.descendant(
                of: button,
                matching: findText('소비 요약'),
              );
              _expectGrows(tester, label);
              final rp = tester.renderObject<RenderParagraph>(
                find
                    .descendant(of: label, matching: find.byType(RichText))
                    .first,
              );
              final whole = TextPainter(
                text: rp.text,
                textDirection: TextDirection.ltr,
                textScaler: rp.textScaler,
                maxLines: 1,
              )..layout();
              expect(rp.size.height, greaterThanOrEqualTo(whole.height - 0.01));
              whole.dispose();
              final box = tester.getRect(button);
              final text = tester.getRect(label);
              expect(box.top, lessThanOrEqualTo(text.top + 0.01));
              expect(box.bottom, greaterThanOrEqualTo(text.bottom - 0.01));
              final slot = tester.getRect(
                find.byKey(const ValueKey('ledger-summary-slot')),
              );
              expect(slot.height, greaterThanOrEqualTo(44));
              expect(slot.top, lessThanOrEqualTo(box.top + 0.01));
              expect(slot.bottom, greaterThanOrEqualTo(box.bottom - 0.01));
            },
          );
        }
      }

      testWidgets('100% — 놓인 자리는 44 그대로', (tester) async {
        await _pump(
          tester,
          Scaffold(body: SingleChildScrollView(child: row())),
          scaler: TextScaler.noScaling,
          width: 402,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('ledger-summary-slot')))
              .height,
          44,
        );
      });
    });
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
