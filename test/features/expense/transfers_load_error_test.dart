// 이체 조회가 실패하면 가계부 맨 위에서 말한다 — 이체 줄이 조용히 빠진 목록을 "이체 없음" 으로 읽지 않게(I-28-5-8).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Future<void> _pump(WidgetTester tester, {required bool transfersFail}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final now = DateTime.now();
  await tester.pumpWidget(
    ProviderScope(
      // 기본 재시도를 끈다 — 실패가 곧바로 에러 상태로 남는다.
      retry: (_, _) => null,
      overrides: [
        categoriesProvider.overrideWith((ref) async => const []),
        assetsProvider.overrideWith((ref) async => const []),
        assetTransfersProvider.overrideWith((ref, key) async {
          if (transfersFail) throw Exception('boom');
          return const [];
        }),
        monthExpensesProvider.overrideWith(
          (ref, key) async => [
            Expense(
              rowId: 1,
              expenseType: 'EXPENSE',
              amount: 1234,
              expenseDate: '${_ymd(DateTime(now.year, now.month, 1))}T00:00:00',
            ),
          ],
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

void main() {
  testWidgets('이체 조회 실패 — 문구 + 다시 시도, 거래 목록은 그대로', (tester) async {
    await _pump(tester, transfersFail: true);

    expect(findText('이체 내역을 불러오지 못했어요.'), findsOneWidget);
    expect(findText('다시 시도'), findsOneWidget);
    // 거래 목록 전체가 실패 화면으로 바뀌지 않는다.
    expect(findText('거래를 불러오지 못했어요'), findsNothing);
    expect(findTextContaining('1,234'), findsWidgets);
  });

  testWidgets('이체 조회가 성공하면 실패 안내가 없다', (tester) async {
    await _pump(tester, transfersFail: false);

    expect(findText('이체 내역을 불러오지 못했어요.'), findsNothing);
  });
}
