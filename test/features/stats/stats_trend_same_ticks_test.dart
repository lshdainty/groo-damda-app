// 통계 › 추이 — 같은 화면 · 같은 기간 · 같은 눈금 단위 차트는 같은 날짜 글(chart.md "큰 글자", groo-design #247 · #248).
//
// 수입 · 지출 추이(선 · 이중 축) · 일별 · 월별 순저축(막대 · 축 하나) · 여러 달일 때 보이는 주요 카테고리 월별 추이(쌓은 막대)는
// 보이는 것을 모두 한 묶음으로 그리는 자리가 가장 좁은 차트로 가로 눈금 건너뛰기를 한 번 센다. 날별 추이와 월별 카테고리 추이는
// 묶지 않는다. 카테고리 추이도 다른 추이처럼 이번 달에서 끝난다(chart.md "오늘 뒤는 그리지 않습니다") — 끝 칸이 같아야 날짜 글도 같다.
// 가장 나쁜 값 — 폰 320 · 글자 200%.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_trend_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

final _today = DateTime(2026, 11, 30);

/// 30일 — 수입은 며칠에 크게, 지출은 날마다 작게(두 축이 열 배 넘게 다르다).
List<TrendPoint> _daily() => [
  for (var d = 1; d <= 30; d++)
    TrendPoint(
      label: '11. $d.',
      income: d % 10 == 0 ? 4200000 : 0,
      expense: 30000 + d * 4000,
    ),
];

/// 12개월.
List<TrendPoint> _monthly() => [
  for (var m = 1; m <= 12; m++)
    TrendPoint(
      label: '$m월',
      income: 3200000 + m * 50000,
      expense: 2100000 + (m % 4) * 600000,
    ),
];

/// 12개월 · 수입이 억 단위 — 세로축 글이 길어 이중 축 선은 끝 글 하나만, 축 하나인 막대는 둘이 들어가는 가장 나쁜 값.
List<TrendPoint> _monthlyLarge() => [
  for (var m = 1; m <= 12; m++)
    TrendPoint(
      label: '$m월',
      income: m % 3 == 0 ? 420000000 : 210000000,
      expense: 3000000 + m * 1000,
    ),
];

/// 통계 › 추이 탭과 같은 짜임 — 보이는 차트를 [statsTrendPeers] 로 묶어 서로를 짝으로 넘긴다.
Future<void> _host(
  WidgetTester tester,
  List<TrendPoint> points, {
  required double width,
  required double scale,
  bool daily = true,
  StatsPeriod? period,
  RangeSummary? catSummary,
  DateTime? today,
}) async {
  tester.view.physicalSize = Size(width, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final p = period ?? StatsPeriod.thisMonth(_today);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              final peers = statsTrendPeers(
                AppLocalizations.of(context),
                points: points,
                daily: daily,
                catSummary: catSummary,
                categories: const [],
                masked: false,
                today: today,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatsTrendSection(
                    period: p,
                    onPickPeriod: () {},
                    points: points,
                    daily: daily,
                    masked: false,
                    xTickPeers: peers.others(trend: false),
                  ),
                  StatsSavingsBarsSection(
                    period: p,
                    points: points,
                    daily: daily,
                    masked: false,
                    xTickPeers: peers.others(savings: false),
                  ),
                  if (catSummary != null)
                    StatsCatTrendSection(
                      period: p,
                      summary: catSummary,
                      categories: const [],
                      masked: false,
                      today: today,
                      xTickPeers: peers.others(catTrend: false),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// [of] 안에 그려진 가로 눈금 글(왼쪽부터).
List<String> _xLabels(WidgetTester tester, Finder of, List<String> cats) => [
  for (final c in cats)
    if (find.descendant(of: of, matching: findText(c)).evaluate().isNotEmpty) c,
];

// ── 여러 달 · 앞날 달이 든 기간(올해 1 ~ 12월, 오늘 11월) ──

final _yearToday = DateTime(2026, 11, 17);
final _year = StatsPeriod(
  seg: StatsSeg.year,
  from: DateTime(2026, 1, 1),
  to: DateTime(2026, 12, 31),
);

CategoryBreakdown _cat(int id, String name, int amount) => CategoryBreakdown(
  categoryRowId: id,
  categoryName: name,
  expenseType: 'EXPENSE',
  totalAmount: amount,
);

/// 1 ~ 12월 버킷(12월은 앞날 — 예약 거래가 잡힌 달). [incomeHeavy] 면 수입이 억 단위라 이중 축 선이 가장 좁다. 아니면 수입 ·
/// 지출 눈금 글이 아주 짧고(한 자리) 카테고리 지출이 천억 단위("4,000억")라 세로축 글이 가장 긴 카테고리 추이가 가장 좁다 —
/// 카테고리 추이를 묶지 않으면 위 두 차트가 달 글을 더 많이 보이는 가장 나쁜 값.
RangeSummary _yearSummary({bool incomeHeavy = true}) => RangeSummary(
  startDate: '2026-01-01',
  endDate: '2026-12-31',
  categoryBreakdown: [
    _cat(1, '식비', 9000000),
    _cat(2, '주거', 6000000),
    _cat(3, '교통', 3000000),
  ],
  monthlyBuckets: [
    for (var m = 1; m <= 12; m++)
      RangeMonthlyBucket(
        year: 2026,
        month: m,
        totalIncome: incomeHeavy ? (m % 3 == 0 ? 420000000 : 210000000) : 9,
        totalExpense: incomeHeavy ? 3000000 + m * 1000 : 1,
        categoryExpenses: [
          CategoryAmount(
            categoryRowId: 1,
            amount: incomeHeavy
                ? 700000 + m * 1000
                : 210000000000 + m * 1000000,
          ),
          CategoryAmount(
            categoryRowId: 2,
            amount: incomeHeavy ? 500000 : 120000000000,
          ),
          CategoryAmount(
            categoryRowId: 3,
            amount: incomeHeavy ? 200000 + m * 500 : 30000000000 + m * 5000,
          ),
        ],
      ),
  ],
);

void main() {
  group('수입 · 지출 · 순저축 — 위아래 차트가 같은 날짜 글', () {
    final cases = <String, List<TrendPoint> Function()>{
      '일별 30일': _daily,
      '월별 12개월': _monthly,
      '월별 12개월 · 수입 억 단위': _monthlyLarge,
    };
    for (final e in cases.entries) {
      for (final (width, scale) in [(320.0, 2.0), (320.0, 1.3), (360.0, 1.0)]) {
        testWidgets(
          '${e.key} · 폭 ${width.round()} · 글자 ${(scale * 100).round()}%',
          (tester) async {
            final points = e.value();
            final cats = [for (final p in points) p.label];
            await _host(tester, points, width: width, scale: scale);
            final line = _xLabels(tester, find.byType(PLineChart), cats);
            final bars = _xLabels(tester, find.byType(PBarChart), cats);
            expect(line, isNotEmpty);
            expect(line.last, cats.last, reason: '끝(가장 최근) 글은 늘 남는다');
            expect(bars, line, reason: '순저축 막대가 추이 선과 같은 날짜 글을 쓴다');
            // 서로를 짝으로 넘긴다 — 짝의 짝은 비운다(재귀 없이 폭만 잰다)
            final lineChart = tester.widget<PLineChart>(
              find.byType(PLineChart),
            );
            final barChart = tester.widget<PBarChart>(find.byType(PBarChart));
            expect(lineChart.xTickPeers.single, isA<PBarChart>());
            expect(barChart.xTickPeers.single, isA<PLineChart>());
            expect(lineChart.xTickPeers.single.xTickPeers, isEmpty);
          },
        );
      }
    }

    testWidgets('수입 · 지출이 모두 0 이면 추이 선이 없으니 순저축 막대는 짝 없이 센다', (tester) async {
      final points = [
        for (var d = 1; d <= 30; d++)
          TrendPoint(label: '11. $d.', income: 0, expense: 0),
      ];
      await _host(tester, points, width: 320, scale: 2);
      expect(find.byType(PLineChart), findsNothing);
      expect(
        tester.widget<PBarChart>(find.byType(PBarChart)).xTickPeers,
        isEmpty,
      );
    });
  });

  group('여러 달 — 주요 카테고리 월별 추이도 같은 묶음 · 이번 달에서 끝난다', () {
    for (final incomeHeavy in [true, false])
      for (final (width, scale) in [(320.0, 2.0), (320.0, 1.3), (360.0, 1.0)]) {
        testWidgets(
          '세 차트가 같은 달 글(${incomeHeavy ? '추이 선이 가장 좁음' : '카테고리 추이가 가장 좁음'}) · 폭 ${width.round()} · 글자 ${(scale * 100).round()}%',
          (tester) async {
            final summary = _yearSummary(incomeHeavy: incomeHeavy);
            final points = trendPoints(
              _year,
              summary,
              const [],
              today: _yearToday,
            );
            final cats = [for (final p in points) p.label];
            expect(cats.last, '11월', reason: '추이 점은 이번 달에서 끝난다');
            await _host(
              tester,
              points,
              width: width,
              scale: scale,
              daily: false,
              period: _year,
              catSummary: summary,
              today: _yearToday,
            );
            final bars = find.byType(PBarChart);
            final line = _xLabels(tester, find.byType(PLineChart), cats);
            final savings = _xLabels(tester, bars.at(0), cats);
            final catTrend = _xLabels(tester, bars.at(1), cats);
            expect(line.last, '11월');
            expect(savings, line, reason: '순저축이 추이 선과 같은 달 글');
            expect(catTrend, line, reason: '카테고리 추이가 추이 선과 같은 달 글');
            final cat = tester.widget<PBarChart>(bars.at(1));
            expect(cat.xTickPeers, hasLength(2), reason: '추이 선 · 순저축을 짝으로');
            expect(
              tester.widget<PLineChart>(find.byType(PLineChart)).xTickPeers,
              hasLength(2),
              reason: '추이 선도 순저축 · 카테고리 추이를 짝으로',
            );
          },
        );
      }

    testWidgets('기간에 앞날 달(12월)이 들어도 카테고리 추이는 이번 달(11월)에서 끝난다', (tester) async {
      final summary = _yearSummary();
      await _host(
        tester,
        trendPoints(_year, summary, const [], today: _yearToday),
        width: 360,
        scale: 1,
        daily: false,
        period: _year,
        catSummary: summary,
        today: _yearToday,
      );
      final cat = tester.widget<PBarChart>(find.byType(PBarChart).at(1));
      expect(cat.categories, hasLength(11));
      expect(cat.categories.last, '11월');
      expect(
        find.descendant(
          of: find.byType(PBarChart).at(1),
          matching: findText('12월'),
        ),
        findsNothing,
      );
      // 표로 보기도 같은 달까지
      expect(findText('12월'), findsNothing);
    });

    testWidgets('날별 추이와 월별 카테고리 추이는 묶지 않는다', (tester) async {
      final peers = statsTrendPeers(
        await AppLocalizations.delegate.load(const Locale('ko')),
        points: _daily(),
        daily: true,
        catSummary: _yearSummary(),
        categories: const [],
        masked: false,
        today: _yearToday,
      );
      expect(peers.catTrend, isNull);
      expect(peers.trend, isNotNull);
      expect(peers.savings, isNotNull);
    });
  });

  group('bucketsToToday — 이번 달에서 자른다', () {
    List<RangeMonthlyBucket> months(int year, List<int> ms) => [
      for (final m in ms) RangeMonthlyBucket(year: year, month: m),
    ];
    test('오늘을 품은 기간은 이번 달 뒤를 버린다', () {
      final cut = bucketsToToday(months(2026, [10, 11, 12]), today: _yearToday);
      expect([for (final b in cut) b.month], [10, 11]);
    });
    test('지난 기간 · 앞날에서 시작하는 기간은 그대로', () {
      expect(
        bucketsToToday(months(2025, [1, 2, 3]), today: _yearToday),
        hasLength(3),
      );
      expect(
        bucketsToToday(
          months(2026, [12]) + months(2027, [1]),
          today: _yearToday,
        ),
        hasLength(2),
      );
    });
  });
}
