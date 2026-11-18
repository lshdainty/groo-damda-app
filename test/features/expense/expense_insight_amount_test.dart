// 가계부 인사이트 한 줄("지난달보다 N 덜 쓰는 중")의 금액.
//
// 이 자리는 차액을 **만원으로 반올림**해서 문장에 넣었다 — 11,881원 차이를
// `1만원` 이라고 말했다(QA #38: 사용자에게 −16% 를 흘렸다). 축약이 필요하면
// 차트 축·도넛 중앙과 같은 함수 하나를 쓴다(만·억·조, 소수 첫째 자리까지).
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 띄워 글자를 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 지출 한 건. 시각은 **그날 00:00** — 아직 안 온 거래(`isScheduledTx`)는
/// 집계에서 빠지므로 오늘 건을 늦은 시각으로 찍으면 합계가 0 이 된다.
Expense _expense(int rowId, DateTime date, int amount) => Expense(
  rowId: rowId,
  expenseType: 'EXPENSE',
  amount: amount,
  expenseDate: '${_ymd(date)}T00:00:00',
);

/// 이번 달 [thisMonth] · 지난달 [lastMonth] 만큼 쓴 상태로 가계부를 띄운다.
Future<void> _pumpLedger(
  WidgetTester tester, {
  required int thisMonth,
  required int lastMonth,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final now = DateTime.now();
  final thisKey = (year: now.year, month: now.month);
  // 지난달 1일 — 12월이면 해가 넘어간다.
  final prev = DateTime(now.year, now.month - 1, 1);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => const []),
        assetsProvider.overrideWith((ref) async => const []),
        assetTransfersProvider.overrideWith((ref, key) async => const []),
        monthExpensesProvider.overrideWith(
          (ref, key) async => key == thisKey
              ? [_expense(1, DateTime(now.year, now.month, 1), thisMonth)]
              : [_expense(2, prev, lastMonth)],
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(body: ExpenseScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 인사이트 문장은 낱말 단위 줄바꿈(keepAll)이 글자 사이에 U+2060 을 넣는다 — 그 글자를 뺀 글로 찾는다.
Finder _rich(String needle) => find.byWidgetPredicate((w) {
  if (w is! Text) return false;
  final raw = (w.data ?? w.textSpan?.toPlainText() ?? '').replaceAll(
    '\u2060',
    '',
  );
  return raw.contains(needle);
});

void main() {
  testWidgets('지난달 대비 11,881원 차이를 `1만원` 으로 깎지 않는다', (tester) async {
    await _pumpLedger(tester, thisMonth: 100000, lastMonth: 111881);

    // 문장은 Text.rich 라 findRichText 로 본다. 문장 속 돈도 줄이지 않는다 — 원까지(groo-design #252)
    expect(_rich('11,881원'), findsOneWidget);
    expect(_rich('1.2만원'), findsNothing);
    expect(_rich('1만원'), findsNothing);
  });

  testWidgets('1만 아래 차액은 축약 없이 그대로 말한다', (tester) async {
    // 7,000원 차이 — 예전엔 `1만원`(+43%) 이라고 했다.
    await _pumpLedger(tester, thisMonth: 100000, lastMonth: 107000);

    expect(_rich('7,000원'), findsOneWidget);
  });

  testWidgets('5,000원 미만이면 "비슷하게" — 문턱은 그대로다', (tester) async {
    await _pumpLedger(tester, thisMonth: 100000, lastMonth: 104999);

    expect(_rich('비슷하게'), findsOneWidget);
  });
}
