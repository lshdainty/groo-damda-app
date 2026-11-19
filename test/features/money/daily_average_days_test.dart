// 하루 평균의 날수 — DESIGN.md "하루 평균"(groo-design #259, 사용자 결정).
//
// 기간이 오늘을 품으면 기간 첫날부터 오늘까지(오늘 포함), 지난 기간은 기간 전체 날수로 나눈다. 반올림은 원 단위 half-up. 홈 · 통계
// (하이라이트 · 비교) · 예산이 모두 [dailyAverageWon] 하나를 쓴다 — 예전엔 통계 하이라이트만 기간 전체 날수(이번 달이면 30일)로
// 나눠 작게 보였다. 오늘은 기기 시계(statsNow 등)다. 이 파일은 셈과 통계 두 화면을 본다 — 홈 · 예산은 각 화면 시험
// (home_i06_test · budget_screens_test)이 같은 셈을 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_compare_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

const _total = 29430;

/// 시험 경우 — 이름 · 오늘 · 기간 · 기대 날수.
final _cases = [
  (
    name: '이번 달(오늘 18일)',
    today: DateTime(2026, 11, 18),
    from: DateTime(2026, 11, 1),
    to: DateTime(2026, 11, 30),
    days: 18,
  ),
  (
    name: '지난 달(10월 전체)',
    today: DateTime(2026, 11, 18),
    from: DateTime(2026, 10, 1),
    to: DateTime(2026, 10, 31),
    days: 31,
  ),
  (
    name: '오늘이 기간 첫날',
    today: DateTime(2026, 11, 1),
    from: DateTime(2026, 11, 1),
    to: DateTime(2026, 11, 30),
    days: 1,
  ),
];

RangeSummary _summary(DateTime from, DateTime to, int total) =>
    RangeSummary(startDate: ymd(from), endDate: ymd(to), totalExpense: total);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void main() {
  tearDown(() => statsNow = DateTime.now);

  group('날수 · 하루 평균 셈', () {
    for (final c in _cases) {
      test('${c.name} — ${c.days}일', () {
        expect(averageDays(c.from, c.to, c.today), c.days);
        expect(
          dailyAverageWon(_total, c.from, c.to, c.today),
          averageWon(_total, c.days),
        );
      });
    }
    test('아직 오지 않은 기간은 기간 전체', () {
      expect(
        averageDays(
          DateTime(2026, 12, 1),
          DateTime(2026, 12, 31),
          DateTime(2026, 11, 18),
        ),
        31,
      );
    });
    test('시각은 보지 않는다 · 서머타임 무관(날짜로만 센다)', () {
      expect(
        averageDays(
          DateTime(2026, 3, 1, 23, 59),
          DateTime(2026, 3, 31),
          DateTime(2026, 3, 18, 0, 1),
        ),
        18,
      );
    });
    test('29,430 · 이번 달 18일 → 1,635 · 반올림 half-up', () {
      expect(
        dailyAverageWon(
          _total,
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 30),
          DateTime(2026, 11, 18),
        ),
        1635,
      );
      expect(averageWon(_total, 19), 1549);
    });
    test('웹과 같은 정수 반올림 — 부호는 합을 따른다', () {
      expect(averageWon(29439, 18), 1636);
      expect(averageWon(-29439, 18), -1636);
      expect(averageWon(3, 2), 2);
      expect(averageWon(-3, 2), -2);
      expect(averageWon(-1, 3), 0);
      expect(
        averageDays(
          DateTime(2026, 1, 1),
          DateTime(2026, 1, 31),
          DateTime(2026, 11, 18),
        ),
        31,
        reason: '지난 1월은 31일',
      );
    });
  });

  group('통계 하이라이트 · 통계 비교가 같은 값', () {
    for (final c in _cases) {
      testWidgets(c.name, (tester) async {
        statsNow = () => c.today;
        final period = StatsPeriod(
          seg: StatsSeg.custom,
          from: c.from,
          to: c.to,
        );
        final expected = '${krw(averageWon(_total, c.days))}원';
        await _pump(
          tester,
          Column(
            children: [
              StatsHighlightsSection(
                period: period,
                summary: _summary(c.from, c.to, _total),
                prevSummary: _summary(period.prev.from, period.prev.to, 0),
                prevLoading: false,
                categories: const [],
                merchants: const [],
                expenses: const [],
                masked: false,
              ),
              StatsCompareMetricsSection(
                period: period,
                now: _summary(c.from, c.to, _total),
                // 지난 기간도 같은 합 — 지난 기간은 기간 전체 날수로 나눈다
                prev: _summary(period.prev.from, period.prev.to, _total),
                nowExpenses: const [],
                prevExpenses: const [],
                masked: false,
              ),
            ],
          ),
        );
        expect(
          findPlain(expected),
          findsNWidgets(2),
          reason: '하이라이트 · 비교의 이번 기간 하루 평균이 모두 $expected',
        );
      });
    }
  });
}
