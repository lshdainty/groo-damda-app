// 통계 추이 차트 Y축 눈금 표기 — 도넛 중앙·히트맵과 **같은 글자**인지.
//
// 축약 함수는 하나다(QA #73). 예전엔 추이 축만 쓰는 함수가 따로 있어서 만을 정수로
// 깎고(2.5만 → `3만`), 억에 `.0` 을 남기고(`5.0억`), 조를 아예 몰랐다(1.2조 →
// `12000.0억`). 같은 화면 안에서 도넛 중앙은 `5억`, 그 아래 축은 `5.0억` 이었다.
//
// 여기 테스트는 축이 `formatChartAxis` 를 **쓰고 있다**는 사실을 화면으로 고정한다.
// 값별 기대 문자열 표 자체는 `test/core/format/formatters_locale_test.dart` 에 있다
// (웹 `shared/lib/groo/format.ts` 테스트와 글자 그대로 같은 표).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_screen.dart';
import '../../support/plain_text.dart';

/// 오늘(이번 달 안) 지출 한 건. 기본 기간이 이번 달이라 추이 축의 최대값이 된다.
///
/// 시각은 **오늘 00:00** 이다. 예정 거래(`isScheduledTx` — `DateTime.now()` 보다
/// 뒤인 건)는 추이 집계에서 빠지므로, `09:00` 으로 찍으면 오전 9시 전에 돌린 테스트는
/// 차트가 통째로 비어 축 라벨을 하나도 못 찾는다(CI 는 UTC 라 더 자주 걸린다).
Expense _todayExpense(int amount) {
  final n = DateTime.now();
  return Expense(
    rowId: 1,
    expenseType: 'EXPENSE',
    amount: amount,
    expenseDate:
        '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}T00:00:00',
  );
}

/// 통계 화면을 띄우고 '추이' 탭으로 넘긴다.
Future<void> _pumpTrend(WidgetTester tester, int expenseAmount) async {
  // 폭을 조금 넉넉히 준다 — 390 에서는 옆 '비교' 탭의 지표 Row 가 큰 금액에서
  // 넘쳐(pre-existing) 축 라벨과 무관한 오버플로 예외가 테스트를 깬다.
  tester.view.physicalSize = const Size(480 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => const []),
        rangeExpensesProvider.overrideWith(
          (ref, key) async => [_todayExpense(expenseAmount)],
        ),
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
            totalExpense: expenseAmount,
          ),
        ),
        heatmapProvider.overrideWith(
          (ref, range) async => const <HeatmapCell>[],
        ),
        merchantSummaryProvider.overrideWith(
          (ref, range) async => const <MerchantSummary>[],
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const StatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // 카테고리 → 추이(칩 탭은 눌러서만 바뀐다)
  await tester.tap(findText('추이'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('만 단위 눈금에 천단위 콤마가 붙는다 — 웹 `1,000만` 과 같은 글자', (tester) async {
    // 12,340,000 → nice ceil 5틱: 0 / 500만 / 1,000만 / 1,500만 / 2,000만
    await _pumpTrend(tester, 12340000);

    expect(findText('1,000만'), findsWidgets);
    expect(findText('1000만'), findsNothing);
    expect(findText('500만'), findsWidgets);
  });

  testWidgets('1만 아래 눈금에도 콤마가 붙는다 — 웹 `8,000` 과 같은 글자', (tester) async {
    // 8,000 → nice ceil 5틱: 0 / 2,000 / 4,000 / 6,000 / 8,000
    await _pumpTrend(tester, 8000);

    expect(findText('8,000'), findsWidgets);
    expect(findText('8000'), findsNothing);
    expect(findText('2,000'), findsWidgets);
  });

  testWidgets('만 눈금의 소수 첫째 자리를 깎지 않는다 — `2.5만` 이지 `3만` 이 아니다', (tester) async {
    // 100,000 → nice ceil 5틱: 0 / 25,000 / 50,000 / 75,000 / 100,000
    // 축 전용 함수는 만을 정수로 반올림해 `3만` · `8만` 으로 찍었다 — 눈금 간격이
    // 2.5만인데 라벨은 3-5-8-10 으로 뛰어 축을 읽으면 값이 틀린다.
    await _pumpTrend(tester, 100000);

    expect(findText('2.5만'), findsWidgets);
    expect(findText('7.5만'), findsWidgets);
    expect(findText('3만'), findsNothing);
    expect(findText('8만'), findsNothing);
  });

  testWidgets('억 눈금에 `.0` 을 남기지 않는다 — 도넛 중앙과 같은 `5억`', (tester) async {
    // 2,000,000,000 → nice ceil 5틱: 0 / 5억 / 10억 / 15억 / 20억
    await _pumpTrend(tester, 2000000000);

    expect(findText('5억'), findsWidgets);
    expect(findText('5.0억'), findsNothing);
    expect(findText('20억'), findsWidgets);
    expect(findText('20.0억'), findsNothing);
  });

  testWidgets('조 단위를 억으로 늘려 쓰지 않는다 — `1조` 이지 `10000.0억` 이 아니다', (tester) async {
    // 4,000,000,000,000 → nice ceil 5틱: 0 / 1조 / 2조 / 3조 / 4조
    await _pumpTrend(tester, 4000000000000);

    expect(findText('1조'), findsWidgets);
    expect(findText('4조'), findsWidgets);
    expect(findText('10000.0억'), findsNothing);
    expect(findText('40000.0억'), findsNothing);
  });

  group('축 라벨 폭 — reservedSize 44 안에 들어가는 길이인가', () {
    setUp(() => Intl.defaultLocale = 'ko');

    test('nice step 이 만들 수 있는 모든 눈금이 6글자를 넘지 않는다', () {
      // 추이 축(`_niceCeil`)·순저축 축(`niceStep`) 둘 다 눈금 간격을
      // 1 · 2 · 2.5 · 5 · 10 × 10ⁿ 로 고른다. 눈금은 그 간격의 1~4배다.
      // 축 폭은 44(좌우 패딩 6) 고정이라 라벨이 길어지면 잘린다 — 통일 전
      // 최장은 `12000.0억`(9글자)였고 지금은 조로 올라가 짧아졌다.
      const mantissas = [1.0, 2.0, 2.5, 5.0, 10.0];
      for (var exp = 0; exp <= 12; exp++) {
        final pow10 = math.pow(10, exp).toDouble();
        for (final m in mantissas) {
          for (var i = 1; i <= 4; i++) {
            final v = m * pow10 * i;
            final s = formatChartAxis(v);
            expect(s.length, lessThanOrEqualTo(6), reason: '$v 라벨이 길다: $s');
            // 음수 축(순저축)은 부호 한 글자가 더 붙는다.
            expect(
              formatChartAxis(-v).length,
              lessThanOrEqualTo(7),
              reason: '-$v 라벨이 길다: ${formatChartAxis(-v)}',
            );
          }
        }
      }
    });
  });
}
