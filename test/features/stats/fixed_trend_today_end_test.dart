// 통계 › 고정 · 변동 — 월별 고정 · 변동 추이는 이번 달에서 끝난다(chart.md "오늘 뒤는 그리지 않습니다").
//
// 서버는 기간 끝까지 0 인 달을 채워 보낸다. 올해(1 ~ 12월)를 고르고 오늘이 11월이면 12월을 0 막대로 그리지 않는다 — 수입 · 지출
// 추이 · 순저축 · 카테고리 추이와 같은 자르기([bucketsToToday]). 지난 기간은 끝까지 그린다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/fixed_variable_tab.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

/// [year] 1 ~ 12월 — 서버처럼 기간 끝까지 달을 채운다.
RangeSummary _yearSummary(int year) => RangeSummary(
  startDate: '$year-01-01',
  endDate: '$year-12-31',
  totalIncome: 38400000,
  totalExpense: 17184000,
  fixedIncome: 38400000,
  fixedExpense: 10704000,
  monthlyBuckets: [
    for (var m = 1; m <= 12; m++)
      RangeMonthlyBucket(
        year: year,
        month: m,
        totalIncome: 3200000,
        totalExpense: 1400000 + m * 1000,
        fixedIncome: 3200000,
        fixedExpense: 892000,
      ),
  ],
);

Future<void> _pump(WidgetTester tester, int year) async {
  tester.view.physicalSize = const Size(360, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final period = StatsPeriod(
    seg: StatsSeg.year,
    from: DateTime(year, 1, 1),
    to: DateTime(year, 12, 31),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rangeSummaryProvider(
          period.range,
        ).overrideWith((ref) async => _yearSummary(year)),
        monthlyTrendProvider(6).overrideWith((ref) async => const []),
        categoriesProvider.overrideWith((ref) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
        rangeExpensesProvider.overrideWith((ref, key) async => const []),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: FixedVariableTab(period: period, onPickPeriod: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() => statsNow = () => DateTime(2026, 11, 17));
  tearDown(() => statsNow = DateTime.now);

  testWidgets('올해(1 ~ 12월) · 오늘 11월 — 막대는 11월에서 끝나고 12월을 0 으로 그리지 않는다', (
    tester,
  ) async {
    await _pump(tester, 2026);
    final chart = tester.widget<PBarChart>(find.byType(PBarChart));
    expect(chart.categories, hasLength(11));
    expect(chart.categories.last, '11월');
    for (final s in chart.series) {
      expect(s.values, hasLength(11));
    }
    // 차트 눈금 · 표로 보기 어디에도 앞날 달이 없다
    expect(findText('12월'), findsNothing);
  });

  testWidgets('지난해(1 ~ 12월) — 끝까지 그린다', (tester) async {
    await _pump(tester, 2025);
    final chart = tester.widget<PBarChart>(find.byType(PBarChart));
    expect(chart.categories, hasLength(12));
    expect(chart.categories.last, '12월');
  });
}
