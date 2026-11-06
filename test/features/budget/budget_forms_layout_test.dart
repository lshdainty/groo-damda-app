// I-19 틈 표 T1~T9 · 끝까지 닿기 — 폼 시트 360 폭에서 잰 값(가장 나쁜 값, 글자 100%).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/data/budget_repository.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_edit_dialog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

const _cats = [
  ExpenseCategory(
    rowId: 2,
    categoryName: '카페·간식·디저트 모임 지출 항목',
    expenseType: 'EXPENSE',
    color: '#2c70bf',
  ),
];
const _goal = SavingGoal(
  rowId: 2,
  title: '제주 한 달 살기 자금',
  targetAmount: 9876543210,
  currentAmount: 1234567890,
  deadlineDate: '2035-12-31',
  color: '#9e9e9e',
);

Future<void> _open(
  WidgetTester tester,
  void Function(BuildContext) open,
) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWith(
          (ref) async => BudgetRepository(Dio()),
        ),
        categoriesProvider.overrideWith((ref) async => _cats),
        savingGoalListProvider.overrideWith((ref) async => [_goal]),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Consumer(
            builder: (ctx, ref, _) {
              ref.watch(categoriesProvider);
              return TextButton(
                onPressed: () => open(ctx),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

Rect _r(WidgetTester t, Finder f, [int i = 0]) => t.getRect(f.at(i));

void main() {
  testWidgets('저축 목표 폼 — 360 에서 끝까지 닿고 틈이 틈 표와 같다', (tester) async {
    await _open(tester, (c) => showSavingGoalEditDialog(c, edit: _goal));
    expect(tester.takeException(), isNull);
    final header = _r(
      tester,
      find.byKey(const ValueKey('p-bottom-sheet-header')),
    );
    final fields = find.byType(PField);
    final f0 = _r(tester, fields, 0);
    final f1 = _r(tester, fields, 1);
    final f2 = _r(tester, fields, 2);
    final rows = find.byType(PListButtonItem);
    final r0 = _r(tester, rows, 0);
    final r2 = _r(tester, rows, 2);
    final footer = _r(
      tester,
      find.byKey(const ValueKey('p-bottom-sheet-footer')),
    );
    // 끝까지 닿기 — 시트 360, 칸은 좌우 24, 줄은 끝까지
    expect(header.right, 360);
    expect(f0.left, 24);
    expect(f0.right, 336);
    expect(r0.left, 0);
    expect(r0.right, 360);
    expect(r2.right, 360);
    // T1 머리 아래 16 은 머리 상자 안(첫 칸 라벨이 머리 바로 아래)
    expect(f0.top - header.bottom, 0);
    // T5 칸 ↔ 칸 24
    expect(f1.top - f0.bottom, 24);
    expect(f2.top - f1.bottom, 24);
    // T6 마지막 칸 ↔ 첫 줄 12(줄 안 위 여백 12 는 줄 상자 안)
    expect(r0.top - f2.bottom, 12);
    // T7 줄 ↔ 줄 0
    expect(_r(tester, rows, 1).top - r0.bottom, 0);
    // T8 마지막 줄 ↔ 바닥 : 8 + 바닥 위 12 는 바닥 상자 안
    expect(footer.top - r2.bottom, 8);
    // 시트 높이 < 화면 90%
    final sheet = _r(tester, find.byKey(const ValueKey('p-bottom-sheet-root')));
    expect(sheet.height, lessThanOrEqualTo(760 * 0.9));
  });

  testWidgets('예산 폼(카테고리 추가) — T2 T3 T4 · 끝까지 닿기', (tester) async {
    await _open(tester, (c) => showBudgetEditDialog(c, year: 2026, month: 10));
    expect(tester.takeException(), isNull);
    final row = _r(tester, find.byType(PListButtonItem));
    final field = _r(tester, find.byType(PField));
    final chips = find.byType(PChip);
    final chipTop = chips
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)).top)
        .reduce((a, b) => a < b ? a : b);
    final chipBottom = chips
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)).bottom)
        .reduce((a, b) => a > b ? a : b);
    final footer = _r(
      tester,
      find.byKey(const ValueKey('p-bottom-sheet-footer')),
    );
    expect(row.left, 0);
    expect(row.right, 360);
    expect(field.left, 24);
    expect(field.right, 336);
    // T2 줄 아래 12
    expect(field.top - row.bottom, 12);
    // T3 칸 ↔ 칩 12
    expect(chipTop - field.bottom, 12);
    // T4 칩 아래 24(+ 바닥 위 12 는 바닥 상자 안)
    expect(footer.top - chipBottom, 24);
    // 칩 높이 36
    expect(tester.getRect(chips.first).height, 36);
  });

  testWidgets('예산 폼(총 예산 · 가장 나쁜 값) — 밑줄 칸 높이 40 · 오른쪽 360 안', (tester) async {
    await _open(
      tester,
      (c) => showBudgetEditDialog(
        c,
        year: 2026,
        month: 10,
        edit: const Budget(
          rowId: 1,
          budgetAmount: 9876543210,
          budgetYear: 2026,
          budgetMonth: 10,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final input = _r(tester, find.byType(TextField));
    expect(input.right, lessThanOrEqualTo(336));
    // 밑줄 large — 높이 40
    expect(_r(tester, find.byType(PInput)).height, 40);
  });
}
