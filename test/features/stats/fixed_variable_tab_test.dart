// 통계 · 고정/변동 탭 — 서버가 내린 전체·고정 몫으로 세 숫자를 맞게 그리고, 가장 나쁜 값에서도
// 넘치지 않는지 본다. Flutter 테스트는 RenderFlex 넘침을 예외로 던지므로 "예외 없이 그려진다" 가
// 곧 넘치지 않는다는 검사다.
//   ① 지출·수입 각각 전체 · 고정 · 고정 제외 금액과 비율이 나온다(변동 = 전체 − 고정)
//   ② 폭 360 · 14억대 금액 · 긴 카테고리 이름에서도 넘치지 않는다
//   ③ 고정이 하나도 없으면 안내와 [정리] 버튼이 나온다
//   ④ 한 달만 고른 기간은 최근 6개월 추이를 쓴다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/fixed_bulk_page.dart';
import 'package:groo_damda_app/features/stats/presentation/fixed_variable_tab.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import '../../support/plain_text.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

const _range = (startDate: '2026-10-01', endDate: '2026-10-31');
final _period = StatsPeriod(
  seg: StatsSeg.month,
  from: DateTime(2026, 10, 1),
  to: DateTime(2026, 10, 31),
);

RangeSummary _summary({
  int scale = 1,
  int fixedExpense = 892000,
  String longName = '월세',
}) {
  return RangeSummary(
    startDate: '2026-10-01',
    endDate: '2026-10-31',
    totalIncome: 3200000 * scale,
    totalExpense: 1432000 * scale,
    fixedIncome: 3200000 * scale,
    fixedExpense: fixedExpense * scale,
    categoryBreakdown: [
      CategoryBreakdown(
        categoryRowId: 2,
        categoryName: longName,
        parentCategoryRowId: 1,
        parentCategoryName: longName,
        expenseType: 'EXPENSE',
        totalAmount: 700000 * scale,
        fixedAmount: fixedExpense == 0 ? 0 : 700000 * scale,
      ),
      CategoryBreakdown(
        categoryRowId: 4,
        categoryName: '식비',
        expenseType: 'EXPENSE',
        totalAmount: 540000 * scale,
        fixedAmount: 0,
      ),
    ],
    monthlyBuckets: const [],
  );
}

Future<void> _pump(
  WidgetTester tester,
  RangeSummary summary, {
  double width = 360,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width * 3, 6000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rangeSummaryProvider(_range).overrideWith((ref) async => summary),
        monthlyTrendProvider(6).overrideWith(
          (ref) async => [
            for (final m in [5, 6, 7, 8, 9, 10])
              MonthlyTrend(
                year: 2026,
                month: m,
                totalIncome: 3200000,
                totalExpense: 1400000 + m * 1000,
                fixedIncome: 3200000,
                fixedExpense: 892000,
              ),
          ],
        ),
        categoriesProvider.overrideWith(
          (ref) async => const [
            ExpenseCategory(
              rowId: 1,
              categoryName: '주거',
              expenseType: 'EXPENSE',
              sortOrder: 0,
              color: '#2c70bf',
            ),
          ],
        ),
        hideCardProvider.overrideWith((ref, card) => false),
        rangeExpensesProvider.overrideWith((ref, key) async => const []),
      ],
      child: MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: FixedVariableTab(period: _period, onPickPeriod: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('지출·수입의 전체 · 고정 · 고정 제외 금액과 비율이 나온다', (tester) async {
    await _pump(tester, _summary());

    // 지출: 전체 1,432,000 = 고정 892,000(62.3%) + 변동 540,000(37.7%) — 비중은 소수 첫째 자리
    expect(findPlain('1,432,000원'), findsOneWidget);
    expect(findPlain('892,000원'), findsOneWidget);
    expect(findRichPlain('고정 지출'), findsWidgets);
    expect(findRichPlain('고정 제외 지출'), findsWidgets);
    expect(findPlain('62.3%'), findsWidgets);
    expect(findPlain('37.7%'), findsWidgets);
    // 수입은 전부 고정
    expect(findPlain('3,200,000원'), findsWidgets);
    expect(findRichPlain('고정 제외 수입'), findsWidgets);
    // 한 줄 해설
    expect(findRichPlain('지출의 62.3%가 고정이에요'), findsOneWidget);
  });

  testWidgets('폭 360 · 14억대 금액 · 긴 카테고리 이름에서도 넘치지 않는다 (라이트)', (tester) async {
    await _pump(
      tester,
      _summary(
        scale: 1000,
        longName: '아주아주 긴 이름의 카테고리 때문에 줄이 넘칠 수 있는 경우를 확인합니다',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(findPlain('1,432,000,000원'), findsOneWidget);
  });

  testWidgets('다크에서도 넘치지 않는다', (tester) async {
    await _pump(tester, _summary(scale: 1000), dark: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('고정이 0.05% 미만이면 숫자 없는 문장 · 값은 "0.1% 미만"', (tester) async {
    await _pump(tester, _summary(fixedExpense: 100));
    expect(findPlainContaining('0.1% 미만'), findsWidgets);
    expect(findRichPlain('고정 지출이 거의 없어요. 고정을 뺀 지출은'), findsOneWidget);
    expect(findRichPlain('지출의 '), findsNothing);
  });

  testWidgets('고정이 하나도 없으면 안내와 정리 버튼이 나온다', (tester) async {
    await _pump(tester, _summary(fixedExpense: 0));

    expect(findPlainContaining('고정으로 표시하면 여기서 따로 볼 수 있어요'), findsWidgets);
    expect(findText('거래를 고정으로 정리하기'), findsWidgets);
    expect(findRichPlain('지출의 0%가 고정이에요'), findsNothing);
  });

  testWidgets('한 달만 고른 기간은 최근 6개월 추이를 쓴다', (tester) async {
    await _pump(tester, _summary());
    expect(findPlain('최근 6개월'), findsOneWidget);
  });

  testWidgets('"거래를 고정으로 정리하기" 는 시트가 아니라 페이지를 연다', (tester) async {
    await _pump(tester, _summary(fixedExpense: 0));
    await tester.tap(findText('거래를 고정으로 정리하기').first);
    await tester.pumpAndSettle();
    expect(find.byType(FixedBulkPage), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
  });
}
