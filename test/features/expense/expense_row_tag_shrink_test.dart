// 가계부 줄 설명(Tag Group truncate)의 줄어드는 정도 — 이름 항목이 줄고 할부 · 시각은 줄지 않는다(tag-group.md "줄어드는 정도").
// 긴 카테고리(shrink 0)가 줄지 않아 시각이 화면 밖으로 잘리던 것을 잠근다. **작성만 했다(돌리지 않음).**
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';

void main() {
  testWidgets('카테고리 1 · 계좌 2 · 할부 0 · 시각 0', (tester) async {
    const e = Expense(
      rowId: 1,
      categoryName: '카페·간식·디저트·베이커리 아주 긴 카테고리',
      assetName: '주거래 월급 통장 아주 긴 이름',
      expenseType: 'EXPENSE',
      amount: 123456,
      merchant: '다온배달',
      installmentMonths: 3,
      expenseDate: '2026-10-28T09:30:00',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hideCardProvider.overrideWith((ref, card) => false)],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Consumer(
              builder: (c, ref, _) => ExpenseRow(
                expense: e,
                category: null,
                flags: ref.watch(maskFlagsProvider('ledger.list')),
                interactive: false,
                showInstallment: true,
              ),
            ),
          ),
        ),
      ),
    );
    final items = tester.widget<PTagGroup>(find.byType(PTagGroup)).items;
    expect(items.map((t) => t.shrink).toList(), [1, 2, 0, 0]);
    expect(items.last.label, '09:30');
  });
}
