// 새 폼 = 첫 입력 칸에 초점, 수정 폼 = 키보드 없이 시트 표면. 시트 컨테이너가 처음 초점을 가져가므로(initialFocus 가
// 없으면 안쪽 autofocus 는 밀린다) 호출처가 initialFocus 를 넘기는지를 primaryFocus 로 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_edit_dialog.dart';
import 'package:groo_damda_app/features/category/presentation/category_edit_dialog.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../support/plain_text.dart';

const _cat = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
);

Future<bool> _inputFocused(
  WidgetTester tester,
  void Function(BuildContext, WidgetRef) open,
) async {
  tester.view.physicalSize = const Size(1170, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Consumer(
            builder: (c, ref, _) => TextButton(
              onPressed: () => open(c, ref),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final ctx = FocusManager.instance.primaryFocus?.context;
  return ctx?.findAncestorStateOfType<EditableTextState>() != null;
}

void main() {
  group('새 폼은 첫 입력 칸에 초점이 있다', () {
    testWidgets('예산', (t) async {
      expect(
        await _inputFocused(
          t,
          (c, r) => showBudgetEditDialog(c, year: 2026, month: 10),
        ),
        isTrue,
      );
    });
    testWidgets('저축 목표', (t) async {
      expect(
        await _inputFocused(t, (c, r) => showSavingGoalEditDialog(c)),
        isTrue,
      );
    });
    testWidgets('할 일', (t) async {
      expect(await _inputFocused(t, (c, r) => showTodoEditDialog(c)), isTrue);
    });
    testWidgets('카테고리', (t) async {
      expect(
        await _inputFocused(t, (c, r) => showCategoryEditDialog(c)),
        isTrue,
      );
    });
    testWidgets('관심 그룹', (t) async {
      expect(
        await _inputFocused(t, (c, r) => showWatchGroupForm(c, r)),
        isTrue,
      );
    });
  });

  group('수정 폼은 키보드 없이 표면에 둔다', () {
    testWidgets('예산', (t) async {
      expect(
        await _inputFocused(
          t,
          (c, r) => showBudgetEditDialog(
            c,
            year: 2026,
            month: 10,
            edit: const Budget(
              rowId: 1,
              categoryRowId: 1,
              budgetAmount: 300000,
              budgetYear: 2026,
              budgetMonth: 10,
            ),
          ),
        ),
        isFalse,
      );
    });
    testWidgets('저축 목표', (t) async {
      expect(
        await _inputFocused(
          t,
          (c, r) => showSavingGoalEditDialog(
            c,
            edit: const SavingGoal(rowId: 1, title: '여행', targetAmount: 1000),
          ),
        ),
        isFalse,
      );
    });
    testWidgets('할 일', (t) async {
      expect(
        await _inputFocused(
          t,
          (c, r) => showTodoEditDialog(
            c,
            edit: const Todo(rowId: 1, title: '할 일', type: 'TASK'),
          ),
        ),
        isFalse,
      );
    });
    testWidgets('카테고리', (t) async {
      expect(
        await _inputFocused(t, (c, r) => showCategoryEditDialog(c, edit: _cat)),
        isFalse,
      );
    });
    testWidgets('관심 그룹 이름 바꾸기', (t) async {
      expect(
        await _inputFocused(
          t,
          (c, r) => showWatchGroupForm(
            c,
            r,
            group: const StockWatchGroup(
              rowId: 1,
              groupName: '관심',
              sortOrder: 0,
              items: [],
            ),
          ),
        ),
        isFalse,
      );
    });
  });
}
