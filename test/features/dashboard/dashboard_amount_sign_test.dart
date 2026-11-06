// 홈 금액 부호 — QA #1(음수 0) · QA #22(하이픈 ↔ U+2212 혼용) 의 앱판.
//
// 웹 `shared/lib/groo/format.ts` 의 `minusOf` 와 **같은 규칙**이어야 한다.
//   0   → 부호 없음  (빈 계정에서 `−0원` 이 뜨던 자리)
//   양수 → U+2212 `−`
//   음수 → `+`       (선결제 카드가 부채를 깎아 `totalDebt < 0` 이 되는 경우)
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 직접 띄워 글자를 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:groo_damda_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import '../../support/plain_text.dart';

/// 이번 달 1일 (`_DashboardScreenState._ymdStart` 와 같은 규칙).
String _monthStart() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-01';
}

Future<void> _pumpHome(
  WidgetTester tester, {
  int totalAssets = 0,
  int totalDebt = 0,
  int income = 0,
  int expense = 0,
  List<Expense> todayTx = const [],
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final start = _monthStart();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetSummaryProvider.overrideWith(
          (ref, key) async =>
              AssetSummary(totalAssets: totalAssets, totalDebt: totalDebt),
        ),
        // 이번 달만 값을 준다 — 지난달(전월 대비 %)은 0 으로 둔다.
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
            totalIncome: range.startDate == start ? income : 0,
            totalExpense: range.startDate == start ? expense : 0,
          ),
        ),
        monthExpensesProvider.overrideWith((ref, key) async => todayTx),
        categoriesProvider.overrideWith((ref) async => const []),
        monthBudgetsProvider.overrideWith((ref, key) async => const []),
        budgetAlertThresholdProvider.overrideWith((ref) async => 85),
        dashboardSummaryProvider.overrideWith(
          (ref) async => DashboardSummary.fromJson(const <String, dynamic>{}),
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(body: DashboardScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('빈 계정 — 총 부채·지출이 `−0` 이 아니라 `0` 이다', (tester) async {
    await _pumpHome(tester);

    // 옛 코드는 `sign: '-'` 를 무조건 붙여 `-0` 을 냈다.
    expect(findPlain('-0원'), findsNothing);
    expect(findPlain('−0원'), findsNothing);
    expect(
      findTextContaining(RegExp(r'-\d'), findRichText: true),
      findsNothing,
    );
    // 총자산·총부채·지출 모두 부호 없는 '0'.
    expect(findPlain('0원'), findsWidgets);
  });

  testWidgets('부채가 있으면 U+2212 로 찍는다 — ASCII 하이픈이 아니다', (tester) async {
    await _pumpHome(tester, totalAssets: 1000000, totalDebt: 356800);

    expect(findPlain('−356,800원'), findsOneWidget);
    expect(findPlain('-356,800원'), findsNothing);
    // 없는 것만 보지 않는다 — 부호는 U+2212 로 있고, 숫자 앞 ASCII 하이픈은 어디에도 없다.
    expect(findTextContaining('−', findRichText: true), findsWidgets);
    expect(
      findTextContaining(RegExp(r'-\d'), findRichText: true),
      findsNothing,
    );
  });

  testWidgets('선결제로 총 부채가 음수면 부호를 겹치지 않고 `+` 로 뒤집는다', (tester) async {
    // desk-back #305 이후 `totalDebt = −Σ부채군` 이라 선결제한 카드가 부채를 깎는다.
    await _pumpHome(tester, totalAssets: 1000000, totalDebt: -356800);

    expect(findPlain('+356,800원'), findsOneWidget);
    // 옛 코드는 부호 글자와 값의 부호가 겹쳐 `--356,800` 을 냈다.
    expect(findPlain('--356,800원'), findsNothing);
    expect(
      findTextContaining(RegExp(r'-\d'), findRichText: true),
      findsNothing,
    );
    expect(findPlain('−-356,800원'), findsNothing);
  });

  testWidgets('이번 달 지출도 같은 규칙 — 값이 있으면 U+2212', (tester) async {
    await _pumpHome(tester, income: 2000000, expense: 123456);

    expect(findPlain('−123,456원'), findsOneWidget);
    expect(findPlain('-123,456원'), findsNothing);
    expect(findTextContaining('−', findRichText: true), findsWidgets);
    expect(
      findTextContaining(RegExp(r'-\d'), findRichText: true),
      findsNothing,
    );
    // 수입은 웹과 같이 늘 `+`.
    expect(findPlain('+2,000,000원'), findsOneWidget);
  });

  testWidgets('오늘 쓴 돈 합계도 U+2212 로 찍는다', (tester) async {
    // 자정 — 합계는 아직 오지 않은 거래를 안 세므로(`expenseSum`) 늘 지난 시각을 쓴다.
    final today = '${_todayKey()}T00:00:00';
    await _pumpHome(
      tester,
      todayTx: [
        Expense(
          rowId: 1,
          expenseType: 'EXPENSE',
          amount: 7560,
          expenseDate: today,
        ),
      ],
    );

    // 카드 헤더 합계와 행 금액 — 같은 카드 안 두 자리가 같은 기호를 쓴다
    // (QA #22 는 한 카드에서 `−`/`-` 가 섞여 정렬이 어긋난 걸 잡았다).
    expect(findPlain('−7,560원'), findsNWidgets(2));
    expect(findPlain('-7,560원'), findsNothing);
    expect(findTextContaining('−', findRichText: true), findsWidgets);
    expect(
      findTextContaining(RegExp(r'-\d'), findRichText: true),
      findsNothing,
    );
  });

  // 환불한 거래·카드 이월은 행으로는 보이되(환불은 취소선) 오늘 쓴 돈 합계에는 안 든다
  // — 가계부 합계와 같은 규칙이다(23차 12).
  testWidgets('오늘 쓴 돈 합계는 환불·카드 이월을 뺀다', (tester) async {
    final today = '${_todayKey()}T00:00:00';
    await _pumpHome(
      tester,
      todayTx: [
        Expense(
          rowId: 1,
          expenseType: 'EXPENSE',
          amount: 7560,
          expenseDate: today,
        ),
        Expense(
          rowId: 2,
          expenseType: 'EXPENSE',
          amount: 3000,
          expenseDate: today,
          refundedAt: today,
        ),
        Expense(
          rowId: 3,
          expenseType: 'EXPENSE',
          amount: 500000,
          expenseDate: today,
          autoSource: 'CARD_CARRYOVER',
        ),
      ],
    );

    // 헤더 합계 −7,560원 + 그 행 하나. 10,560·507,560 이면 빠뜨린 것이다.
    expect(findPlain('−7,560원'), findsNWidgets(2));
    expect(findPlain('−10,560원'), findsNothing);
    expect(findPlain('−510,560원'), findsNothing);
  });
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
