// 통계 › 추이 QA(2026-11-17, iPad 11.17) 결함 4개.
//
// ⓐ 0 이 대부분인 날별 선 — 값(0 이 아닌 날)이 7 개 이하면 늘 찍는 점(`dots`)을 켠다(chart.md "늘 찍는 점", groo-design #235)
// ⓑ 수입이 0 이면 저축률 · 지출 % · 순저축 % 를 "—" 로, 문장은 "수입이 없어 저축률을 낼 수 없어요" — NaN · 무한 · "0%" 가 안 나간다
// ⓒ 저축률 범례 금액은 도넛 범례처럼 줄 끝(오른쪽)에 붙는다(넓은 iPad 에서 가운데 x≈416 에 떠 있었다)
// ⓓ 오늘을 품은 기간의 가로축은 오늘에서 끝난다 — 오늘 뒤 날짜 · 달을 0 으로 그리지 않는다(chart.md "축"). 지난 기간은 말일까지
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_trend_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

final _today = DateTime(2026, 11, 17);

Future<void> _host(
  WidgetTester tester,
  Widget child, {
  double width = 360,
  Locale locale = const Locale('ko'),
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// 30일 중 [valued] 날에만 지출이 있는 날별 점.
List<TrendPoint> _daily(Set<int> valued) => [
  for (var d = 1; d <= 30; d++)
    TrendPoint(
      label: '11. $d.',
      income: 0,
      expense: valued.contains(d) ? 29430 : 0,
    ),
];

List<String> _texts(WidgetTester tester) => [
  for (final e in find.byType(Text).evaluate())
    plainOf(
      (e.widget as Text).data ??
          (e.widget as Text).textSpan!.toPlainText(includePlaceholders: false),
    ),
];

void main() {
  group('ⓐ 0 이 대부분인 날별 선 — 값 7 개 이하면 dots', () {
    test('문턱 — 7 개는 켜고 8 개는 끈다 · 값이 없으면 끈다', () {
      expect(trendNeedsDots(_daily({11}), const {}), isTrue);
      expect(trendNeedsDots(_daily({1, 2, 3, 4, 5, 6, 7}), const {}), isTrue);
      expect(
        trendNeedsDots(_daily({1, 2, 3, 4, 5, 6, 7, 8}), const {}),
        isFalse,
      );
      expect(trendNeedsDots(_daily({}), const {}), isFalse);
    });

    test('켠 계열만 센다 — 끈 계열의 값은 세지 않는다', () {
      final data = [
        for (var d = 1; d <= 30; d++)
          TrendPoint(label: '$d', income: d == 5 ? 100 : 0, expense: 1000),
      ];
      expect(trendNeedsDots(data, const {}), isFalse, reason: '지출이 매일 있다');
      expect(trendNeedsDots(data, const {'expense'}), isTrue, reason: '수입만 켬');
    });

    testWidgets('QA 그림 그대로(지출 하루) — 선 차트가 dots 를 켜고, 곡선 · 채움은 그대로다', (
      tester,
    ) async {
      await _host(
        tester,
        StatsTrendSection(
          period: StatsPeriod.thisMonth(_today),
          onPickPeriod: () {},
          points: _daily({11}),
          daily: true,
          masked: false,
        ),
      );
      final chart = tester.widget<PLineChart>(find.byType(PLineChart));
      expect(chart.dots, isTrue);
      expect(chart.area, isTrue, reason: '선 모양 · 채움은 바꾸지 않는다');
    });

    testWidgets('값이 많은 달은 dots 를 켜지 않는다', (tester) async {
      await _host(
        tester,
        StatsTrendSection(
          period: StatsPeriod.thisMonth(_today),
          onPickPeriod: () {},
          points: _daily({for (var d = 1; d <= 20; d++) d}),
          daily: true,
          masked: false,
        ),
      );
      expect(tester.widget<PLineChart>(find.byType(PLineChart)).dots, isFalse);
    });
  });

  group('ⓑ 수입 0 — 비율은 "—"', () {
    test('savingsRates — 수입 0 이하면 null, 있으면 0 ~ 100', () {
      expect(savingsRates(avgIn: 0, avgOut: 29430), isNull);
      expect(savingsRates(avgIn: 0, avgOut: 0), isNull);
      final r = savingsRates(avgIn: 1000, avgOut: 400)!;
      expect(r.save, 60);
      expect(r.spend, 40);
      final over = savingsRates(avgIn: 1000, avgOut: 3000)!;
      expect(over.save, 0);
      expect(over.spend, 100);
    });

    for (final locale in const [Locale('ko'), Locale('en')]) {
      testWidgets('수입 0 · 지출 29,430원(${locale.languageCode})', (tester) async {
        await _host(
          tester,
          StatsSavingsRateSection(
            period: StatsPeriod.thisMonth(_today),
            buckets: const [
              RangeMonthlyBucket(
                year: 2026,
                month: 11,
                totalIncome: 0,
                totalExpense: 29430,
              ),
            ],
            masked: false,
          ),
          locale: locale,
        );
        final l = await AppLocalizations.delegate.load(locale);
        final ring = tester.widget<Text>(
          find.byKey(const ValueKey('savings-ring-value')),
        );
        expect(ring.data, '—');
        final insight = tester.widget<Text>(
          find.byKey(const ValueKey('savings-insight')),
        );
        expect(plainOf(insight.data!), l.statsSavingsNoIncome);
        final texts = _texts(tester);
        expect(texts, contains('${l.expTypeExpense} —'));
        expect(texts, contains('${l.statsNetSavings} —'));
        for (final t in texts) {
          expect(t, isNot(contains('NaN')));
          expect(t, isNot(contains('Infinity')));
          expect(t, isNot(contains('0%')), reason: '"$t" — 0% 로 꾸며 말하지 않는다');
        }
      });
    }

    testWidgets('수입이 있으면 그대로 정수 % 문장', (tester) async {
      await _host(
        tester,
        StatsSavingsRateSection(
          period: StatsPeriod.thisMonth(_today),
          buckets: const [
            RangeMonthlyBucket(
              year: 2026,
              month: 11,
              totalIncome: 1000,
              totalExpense: 400,
            ),
          ],
          masked: false,
        ),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('savings-ring-value')))
            .data,
        '60%',
      );
      expect(findPlainContaining('저축하고 있어요'), findsOneWidget);
    });
  });

  group('ⓒ 저축률 범례 — 금액은 줄 끝', () {
    for (final width in [360.0, 820.0]) {
      testWidgets('폭 ${width.round()} — 세 줄 모두 금액 오른쪽 끝 = 줄 오른쪽 끝', (
        tester,
      ) async {
        await _host(
          tester,
          StatsSavingsRateSection(
            period: StatsPeriod.thisMonth(_today),
            buckets: const [
              RangeMonthlyBucket(
                year: 2026,
                month: 11,
                totalIncome: 0,
                totalExpense: 29430,
              ),
            ],
            masked: false,
          ),
          width: width,
        );
        final rows = find.byType(StatsSavingsLegendRow);
        expect(rows, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          final row = tester.getRect(rows.at(i));
          final amountFinder = find.descendant(
            of: rows.at(i),
            matching: find.byKey(const ValueKey('savings-legend-amount')),
          );
          // 글 상자가 아니라 글자가 끝나는 자리 — 끝 정렬이면 마지막 글자 끝 = 줄 끝
          final amount = tester.getRect(amountFinder);
          final rp = tester.renderObject<RenderParagraph>(
            find.descendant(of: amountFinder, matching: find.byType(RichText)),
          );
          final boxes = rp.getBoxesForSelection(
            TextSelection(
              baseOffset: 0,
              extentOffset: rp.text.toPlainText().length,
            ),
          );
          final glyphRight = amount.left + boxes.last.right;
          expect(
            glyphRight,
            closeTo(row.right, 0.5),
            reason: '줄 ${i + 1}: 금액 끝 $glyphRight = 줄 끝 ${row.right}',
          );
          expect(
            amount.left,
            greaterThan(row.center.dx),
            reason: '가운데에 떠 있지 않다',
          );
        }
      });
    }

    testWidgets('큰 글자(200%) 폰 — 넘침 없이 금액이 이름 아래로 내려간다', (tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: StatsSavingsLegendRow(
                name: '순저축 —',
                amount: '−1,234,567,890원',
                dot: Color(0xFF000000),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final amount = tester.getRect(
        find.byKey(const ValueKey('savings-legend-amount')),
      );
      final name = tester.getRect(findPlainContaining('순저축'));
      expect(amount.top, greaterThanOrEqualTo(name.bottom));
    });
  });

  group('ⓓ 가로축은 오늘에서 끝난다', () {
    // 매일 지출 1,000 — 오늘 뒤 날도 있는 것처럼(미래 거래는 서버 · countableTx 가 거른다는 전제와 상관없이 축만 본다)
    List<Expense> exps(DateTime from, DateTime to) => [
      for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1)))
        Expense(
          rowId: d.day,
          expenseType: 'EXPENSE',
          amount: 1000,
          expenseDate: '${ymd(d)}T00:00:00',
        ),
    ];

    test('이번 달 — 11.1 ~ 11.17 (17 점), 오늘 뒤 0 이 없다', () {
      final p = StatsPeriod.thisMonth(_today);
      final pts = trendPoints(
        p,
        const RangeSummary(startDate: '2026-11-01', endDate: '2026-11-30'),
        exps(DateTime(2026, 11, 1), DateTime(2026, 11, 17)),
        today: _today,
      );
      expect(pts, hasLength(17));
      expect(pts.last.label, contains('17'));
      expect(pts.every((x) => x.expense == 1000), isTrue);
    });

    test('오늘이 말일이어도 말일까지', () {
      final last = DateTime(2026, 11, 30, 23, 59);
      final pts = trendPoints(
        StatsPeriod.thisMonth(last),
        const RangeSummary(startDate: '2026-11-01', endDate: '2026-11-30'),
        const [],
        today: last,
      );
      expect(pts, hasLength(30));
    });

    test('지난 달은 말일까지(10월 31 점)', () {
      final p = StatsPeriod.thisMonth(DateTime(2026, 10, 5));
      final pts = trendPoints(
        p,
        const RangeSummary(startDate: '2026-10-01', endDate: '2026-10-31'),
        const [],
        today: _today,
      );
      expect(pts, hasLength(31));
    });

    test('올해(월별) — 12월 버킷은 그리지 않는다', () {
      final p = StatsPeriod.thisMonth(_today).ofSeg(StatsSeg.year, _today);
      final pts = trendPoints(
        p,
        RangeSummary(
          startDate: '2026-01-01',
          endDate: '2026-12-31',
          monthlyBuckets: [
            for (var m = 1; m <= 12; m++)
              RangeMonthlyBucket(year: 2026, month: m, totalExpense: 1000),
          ],
        ),
        const [],
        today: _today,
      );
      expect(pts, hasLength(11));
    });

    test('지난 해(월별) — 12월까지', () {
      final p = StatsPeriod.thisMonth(
        DateTime(2025, 3, 1),
      ).ofSeg(StatsSeg.year, DateTime(2025, 3, 1));
      final pts = trendPoints(
        p,
        RangeSummary(
          startDate: '2025-01-01',
          endDate: '2025-12-31',
          monthlyBuckets: [
            for (var m = 1; m <= 12; m++)
              RangeMonthlyBucket(year: 2025, month: m),
          ],
        ),
        const [],
        today: _today,
      );
      expect(pts, hasLength(12));
    });

    testWidgets('일별 순저축 막대도 같은 점 — 가로축이 오늘에서 끝난다', (tester) async {
      final pts = trendPoints(
        StatsPeriod.thisMonth(_today),
        const RangeSummary(startDate: '2026-11-01', endDate: '2026-11-30'),
        const [],
        today: _today,
      );
      await _host(
        tester,
        StatsSavingsBarsSection(
          period: StatsPeriod.thisMonth(_today),
          points: pts,
          daily: true,
          masked: false,
        ),
      );
      final bars = tester.widget<PBarChart>(find.byType(PBarChart));
      expect(bars.categories, hasLength(17));
    });
  });
}
