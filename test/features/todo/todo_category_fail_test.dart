// 할 일 · 카테고리 실패 — 폼 저장은 맨 위 Callout(값 유지 · silent · 서버 글 없음),
// 할 일 삭제는 확인창 뒤 스낵바 + [다시 시도](묻지 않고 한 번 더).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/category/presentation/category_edit_dialog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/data/todo_repository.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_actions.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';

import '../../support/plain_text.dart';

const _todo = Todo(rowId: 7, title: 'QA 할 일');
const _cat = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#c73838',
);

class _TodoRepo extends TodoRepository {
  _TodoRepo() : super(Dio());
  final silent = <String>[];
  int deletes = 0;

  @override
  Future<Todo> update({
    required int id,
    required String title,
    Patch<String> content = const Patch.keep(),
    String? priority,
    Patch<String> category = const Patch.keep(),
    Patch<String> dueDate = const Patch.keep(),
    bool silent = false,
  }) async {
    if (silent) this.silent.add('update');
    throw ApiException(code: 'X', message: '서버 원문');
  }

  @override
  Future<void> delete(int id, {bool silent = false}) async {
    if (silent) this.silent.add('delete');
    deletes++;
    throw ApiException(code: 'X', message: '서버 원문');
  }
}

class _CatRepo extends ExpenseRepository {
  _CatRepo() : super(Dio());
  final silent = <String>[];

  @override
  Future<ExpenseCategory> updateCategory({
    required int id,
    required String categoryName,
    String? icon,
    String? color,
    String? expenseType,
    int? sortOrder,
    bool includeParentRowId = false,
    int? parentRowId,
    bool silent = false,
  }) async {
    if (silent) this.silent.add('update');
    throw ApiException(code: 'X', message: '서버 원문');
  }
}

Future<void> _pump(
  WidgetTester tester,
  List overrides,
  Widget Function(BuildContext, WidgetRef) open,
) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
        home: Scaffold(body: Consumer(builder: (c, ref, _) => open(c, ref))),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('할 일 저장 실패 — 맨 위 Callout · silent · 값 유지 · 서버 글 없음', (
    tester,
  ) async {
    final repo = _TodoRepo();
    await _pump(
      tester,
      [
        todoRepositoryProvider.overrideWith((ref) async => repo),
        todoTagListProvider.overrideWith((ref) async => const []),
      ],
      (c, ref) => TextButton(
        onPressed: () => showTodoEditDialog(c, edit: _todo),
        child: const Text('open'),
      ),
    );
    await tester.tap(
      find
          .ancestor(of: findPlain(l.actionSave), matching: find.byType(PButton))
          .last,
    );
    await tester.pumpAndSettle();
    expect(repo.silent, ['update']);
    expect(l.todoSaveFailed, '할 일을 저장하지 못했어요.');
    expect(findPlain(l.todoSaveFailed), findsOneWidget);
    expect(find.byType(FormErrorCallout), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
    expect(findText('QA 할 일'), findsWidgets);
  });

  testWidgets('카테고리 저장 실패 — 맨 위 Callout · silent · 서버 글 없음', (tester) async {
    final repo = _CatRepo();
    await _pump(
      tester,
      [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => const [_cat]),
      ],
      (c, ref) => TextButton(
        onPressed: () => showCategoryEditDialog(
          c,
          edit: _cat,
          defaultExpenseType: 'EXPENSE',
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(
      find
          .ancestor(of: findPlain(l.actionSave), matching: find.byType(PButton))
          .last,
    );
    await tester.pumpAndSettle();
    expect(repo.silent, ['update']);
    expect(l.categorySaveFailed, '카테고리를 저장하지 못했어요.');
    expect(findPlain(l.categorySaveFailed), findsOneWidget);
    expect(find.byType(FormErrorCallout), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
  });

  testWidgets('할 일 삭제 실패 — 확인창 뒤 스낵바 + 다시 시도 · 서버 글 없음', (tester) async {
    final repo = _TodoRepo();
    await _pump(
      tester,
      [todoRepositoryProvider.overrideWith((ref) async => repo)],
      (c, ref) => TextButton(
        onPressed: () => todoActions.confirmAndDelete(c, ref, _todo),
        child: const Text('open'),
      ),
    );
    await tester.tap(findPlain(l.actionDelete).last);
    await tester.pumpAndSettle();
    expect(repo.deletes, 1);
    expect(repo.silent, ['delete']);
    expect(l.todoDeleteFailed, '할 일을 삭제하지 못했어요.');
    expect(findPlain(l.todoDeleteFailed), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
    await tester.tap(findPlain(l.actionRetry));
    await tester.pumpAndSettle();
    expect(repo.deletes, 2);
  });
}
