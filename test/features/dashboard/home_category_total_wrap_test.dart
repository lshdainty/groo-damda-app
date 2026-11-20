// 홈 카테고리 카드 합계 줄 — 큰 글자에서 금액이 숫자 중간(쉼표 뒤)에서 끊기지 않는다(QA 2026-11-20).
//
// Typography v114 "띄어쓰기에서 먼저 넘긴다"(DESIGN.md 금액 줄바꿈) — 라벨 옆에 금액이 한 줄로 들지 않으면 금액 낱말을 통째로
// 아래 줄로 넘기고, 쉼표 뒤 꺾기는 금액 하나가 줄보다 길 때만 쓴다. 실제 글꼴(Pretendard)로 QA 조건(iOS AX5 402 · 안드로이드
// 200% 411)을 그대로 재현해 줄 수를 잰다.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:groo_damda_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/android_font_scale.dart';
import '../../support/hide_cards_fake.dart';
import '../../support/real_fonts.dart';

/// QA 데이터 — 교통 10,030 · 문화여가 7,000 · 쇼핑 5,800 · 생활 4,600 · 카페간식 2,000 = 29,430
const _qa = [10030, 7000, 5800, 4600, 2000];

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required TextScaler scaler,
  required String locale,
  List<int> amounts = _qa,
}) async {
  // 돈 · 날짜 포맷터의 전역 로케일 — 설정(pd-locale)이 정한다
  addTearDown(() => Intl.defaultLocale = null);
  tester.view.physicalSize = Size(width * 3, 6000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'pd-locale': locale});
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        hideCardsRepositoryProvider.overrideWith(
          (ref) async => OkHideCardsRepository(),
        ),
        assetSummaryProvider.overrideWith(
          (ref, key) async => const AssetSummary(
            netWorth: 476000,
            totalAssets: 488000,
            totalDebt: 12000,
          ),
        ),
        rangeSummaryProvider.overrideWith(
          (ref, r) async => RangeSummary(
            startDate: r.startDate,
            endDate: r.endDate,
            totalExpense: amounts.fold(0, (a, b) => a + b),
            categoryBreakdown: [
              for (var i = 0; i < amounts.length; i++)
                CategoryBreakdown(
                  categoryRowId: i + 1,
                  categoryName: '분류 $i',
                  expenseType: 'EXPENSE',
                  totalAmount: amounts[i],
                ),
            ],
          ),
        ),
        monthExpensesProvider.overrideWith(
          (ref, key) async => const <Expense>[],
        ),
        categoriesProvider.overrideWith(
          (ref) async => [
            for (var i = 0; i < amounts.length; i++)
              ExpenseCategory(
                rowId: i + 1,
                categoryName: '분류 $i',
                expenseType: 'EXPENSE',
              ),
          ],
        ),
        monthBudgetsProvider.overrideWith((ref, key) async => const <Budget>[]),
        dashboardSummaryProvider.overrideWith(
          (ref) async => DashboardSummary.fromJson(const {
            'todoSummary': {'overDueCount': 0},
            'upcomingEvents': <Object>[],
            'recentTodos': <Object>[],
          }),
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child!,
        ),
        home: const Scaffold(body: DashboardScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  expect(tester.takeException(), isNull);
}

/// 합계 금액 글 — 읽는 이름(또는 글)이 [total] 인 Text 하나
Finder _amountText(String total) => find.byWidgetPredicate(
  (w) => w is Text && (w.semanticsLabel == total || w.data == total),
);

Finder _labelText(String label) => find.byWidgetPredicate(
  (w) => w is Text && (w.semanticsLabel == label || w.data == label),
);

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)).first,
    );

/// 그린 글의 줄 수 — 글자 상자의 서로 다른 위쪽 자리 수
int _lines(RenderParagraph p) {
  final n = p.text.toPlainText().length;
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: n),
  );
  final tops = <int>{for (final b in boxes) b.top.round()};
  return tops.length;
}

/// 줄이 바뀐 자리 바로 앞의 보이는 글자(이음 문자 · 너비 0 공백 빼고)
List<String> _breakBefore(RenderParagraph p) {
  final text = p.text.toPlainText();
  const invisible = {'⁠', '​'};
  final out = <String>[];
  double? lastY;
  for (var i = 0; i < text.length; i++) {
    final y = p.getOffsetForCaret(TextPosition(offset: i), Rect.zero).dy;
    if (lastY != null && y > lastY + 1) {
      var j = i - 1;
      while (j > 0 && invisible.contains(text[j])) {
        j--;
      }
      out.add(text[j]);
    }
    lastY = y;
  }
  return out;
}

void main() {
  setUpAll(loadRealFonts);

  final cases = [
    (
      name: 'iOS AX5 · 402 · 한국어',
      width: 402.0,
      scaler: const TextScaler.linear(53 / 17),
      locale: 'ko',
      label: '이번 달 지출',
      total: '29,430원',
      // 8rem(글자 배율 3.1 → 399) + 금액이 줄 폭을 넘는다 — 금액이 라벨 아래 줄로
      below: true,
    ),
    (
      name: '안드로이드 200% · 411 · 영어',
      width: 411.0,
      scaler: const AndroidNonlinearTextScaler() as TextScaler,
      locale: 'en',
      label: "This month's expense",
      total: '₩29,430',
      // 안드로이드 비선형 배율은 128 을 키우지 않는다(8rem 그대로) — 금액 + 12 + 128 이 줄에 들어 라벨 옆 한 줄로 남고 라벨이 줄을 바꾼다
      below: false,
    ),
  ];

  for (final c in cases) {
    testWidgets('${c.name} — 금액이 줄보다 짧으면 쉼표에서 꺾지 않는다(한 줄 · 오른쪽 끝)', (
      tester,
    ) async {
      await _pump(tester, width: c.width, scaler: c.scaler, locale: c.locale);
      final amount = _amountText(c.total);
      expect(amount, findsOneWidget);
      await tester.ensureVisible(amount);
      await tester.pump();
      expect(
        _lines(_paragraph(tester, amount)),
        1,
        reason:
            '"${c.total}" 은 줄 폭보다 짧다 — "${c.total.split(',').first}," / … 로 끊기면 안 된다',
      );
      final label = tester.getRect(_labelText(c.label).first);
      final value = tester.getRect(amount);
      if (c.below) {
        expect(
          value.top,
          greaterThanOrEqualTo(label.bottom - 0.5),
          reason: '라벨 옆에 들지 않으면 금액은 통째로 아래 줄로 넘어간다',
        );
      }
      expect(
        value.right,
        moreOrLessEquals(
          tester.getRect(find.byType(PChartDonutLegend)).right,
          epsilon: 0.5,
        ),
        reason: '금액은 줄 오른쪽 끝(범례와 같은 끝선)',
      );
    });
  }

  testWidgets('100% · 402 — 라벨 옆 같은 줄 그대로', (tester) async {
    await _pump(tester, width: 402, scaler: TextScaler.noScaling, locale: 'ko');
    final amount = _amountText('29,430원');
    expect(amount, findsOneWidget);
    final label = tester.getRect(_labelText('이번 달 지출').first);
    final value = tester.getRect(amount);
    expect(value.top, lessThan(label.bottom), reason: '한 줄에 들면 옆에 둔다');
    expect(_lines(_paragraph(tester, amount)), 1);
  });

  testWidgets('iOS AX5 · 402 — 금액 하나가 줄보다 길 때만 쉼표 뒤에서 꺾는다(세 자리 묶음을 가르지 않는다)', (
    tester,
  ) async {
    await _pump(
      tester,
      width: 402,
      scaler: const TextScaler.linear(53 / 17),
      locale: 'ko',
      amounts: const [1234567000, 890],
    );
    final amount = _amountText('1,234,567,890원');
    expect(amount, findsOneWidget);
    await tester.ensureVisible(amount);
    await tester.pump();
    final p = _paragraph(tester, amount);
    expect(_lines(p), greaterThan(1), reason: '줄보다 긴 금액 — 쉼표 뒤 줄바꿈이 남는다');
    expect(_breakBefore(p), everyElement(','), reason: '줄은 쉼표 뒤에서만 바뀐다');
  });
}
