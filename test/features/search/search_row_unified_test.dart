// 검색 결과가 **가계부 목록과 같은 모양**인지 고정한다(#166).
//
// 예전에는 검색이 자체 _ResultRow 를 그렸다 — 부제가 "카테고리 · 날짜" 이고 금액에
// 단위 '원' 이 없었으며(`-3,000`), 행 사이에 구분선(indent 60)이 있었다. 같은 거래가
// 가계부에서는 "카테고리 · 자산 · 시각" + `-3,000원` + 구분선 없음으로 보였다.
//
// 지금은 둘 다 ExpenseRow 를 쓰고 날짜는 PDayHeader 로 묶는다. 여기서 보는 것은
// 그 셋이다 — 행 위젯 · 금액 단위 · 구분선 없음. 탭 여백 24 도 같이 잠근다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/search/presentation/search_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import 'package:groo_damda_app/shared/widgets/p_divider.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/shared/widgets/p_tabs.dart';
import '../../support/plain_text.dart';

/// 검색만 답하는 대역 — 나머지 메서드는 이 화면이 안 부른다.
class _FakeRepo extends ExpenseRepository {
  _FakeRepo(this.rows) : super(Dio());
  final List<Expense> rows;

  @override
  Future<List<Expense>> search({
    int? categoryId,
    int? assetId,
    String? expenseType,
    String? keyword,
    String? merchant,
    int? minAmount,
    int? maxAmount,
    String? startDate,
    String? endDate,
    bool? fixed,
  }) async => rows;
}

Expense _e({
  required int rowId,
  required int amount,
  required String date,
  String type = 'EXPENSE',
  String? merchant,
}) => Expense(
  rowId: rowId,
  expenseType: type,
  amount: amount,
  expenseDate: date,
  merchant: merchant ?? '가맹점 $rowId',
  description: '메모 $rowId',
  categoryName: '식비',
);

Future<void> _pump(WidgetTester tester, List<Expense> rows) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/search',
    routes: [GoRoute(path: '/search', builder: (_, _) => const SearchScreen())],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => _FakeRepo(rows)),
        categoriesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 검색어를 넣고 디바운스(350ms)를 흘려 결과를 받는다.
Future<void> _search(WidgetTester tester, String q) async {
  await tester.enterText(find.byType(TextField).first, q);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('결과 행이 가계부와 같은 ExpenseRow 다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-12T18:00:00'),
    ]);
    await _search(tester, '커피');

    expect(find.byType(ExpenseRow), findsNWidgets(2));
  });

  testWidgets("금액에 단위 '원' 이 붙는다 — 예전에는 -3,000 이었다", (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
    ]);
    await _search(tester, '커피');

    // 행의 금액 텍스트를 찾는다. '원' 이 없으면 여기서 깨진다.
    expect(
      find.descendant(
        of: find.byType(ExpenseRow),
        matching: findTextContaining('원'),
      ),
      findsWidgets,
    );
  });

  testWidgets('행 사이에 구분선이 없다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-12T18:00:00'),
    ]);
    await _search(tester, '커피');

    expect(find.byType(PDivider), findsNothing);
  });

  testWidgets('날짜가 다르면 날짜 그룹 헤더로 묶인다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-11T18:00:00'),
    ]);
    await _search(tester, '커피');

    // 날짜가 둘이면 헤더도 둘 — 부제에 날짜를 넣던 옛 방식이면 0 이다.
    expect(find.byType(PDayHeader), findsNWidgets(2));
    expect(findTextContaining('26. 9. 12'), findsOneWidget);
    expect(findTextContaining('26. 9. 11'), findsOneWidget);
  });

  testWidgets('같은 날이면 헤더 하나로 묶인다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-12T18:00:00'),
    ]);
    await _search(tester, '커피');

    expect(find.byType(PDayHeader), findsOneWidget);
    // 헤더에 그날 합계(8,000원)가 선다.
    expect(findTextContaining('8,000'), findsOneWidget);
  });

  testWidgets('상단 탭(전체·지출·수입)의 좌측 여백이 24 다', (tester) async {
    await _pump(tester, const []);
    final tabs = tester.getRect(find.byType(PTabs<String?>));
    expect(tabs.left, closeTo(24, 0.5));
  });
}
