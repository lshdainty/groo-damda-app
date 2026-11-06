// 예산 폼(I-19 C) — 총 예산 · 카테고리 예산 추가 · 수정 한 시트.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/data/budget_repository.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_edit_dialog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

class _FakeRepo extends BudgetRepository {
  _FakeRepo() : super(Dio());
  final calls = <String>[];
  bool fail = false;

  /// 있으면 응답을 이 값이 끝날 때까지 미룬다 — 저장 중인 시트를 본다.
  Completer<void>? gate;

  @override
  Future<int?> create({
    int? categoryRowId,
    required int budgetAmount,
    required int budgetYear,
    required int budgetMonth,
    bool silent = false,
  }) async {
    calls.add('create:$categoryRowId:$budgetAmount:$budgetYear-$budgetMonth');
    return null;
  }

  @override
  Future<void> update({
    required int id,
    required int budgetAmount,
    bool silent = false,
  }) async {
    calls.add('update:$id:$budgetAmount');
    if (!silent) calls.add('NOT-SILENT');
    if (gate != null) await gate!.future;
    if (fail) throw ApiException(code: 'X', message: '서버 원문');
  }
}

const _cats = [
  ExpenseCategory(
    rowId: 1,
    categoryName: '식비',
    expenseType: 'EXPENSE',
    color: '#c73838',
    icon: 'utensils',
  ),
  ExpenseCategory(
    rowId: 2,
    categoryName: '카페·간식·디저트 모임 지출 항목',
    expenseType: 'EXPENSE',
    color: '#2c70bf',
  ),
  ExpenseCategory(rowId: 3, categoryName: '월급', expenseType: 'INCOME'),
];

String _plain(String s) =>
    s.replaceAll('⁠', '').replaceAll('​', '').replaceAll('￼', '');

Finder _t(String s) => find.byWidgetPredicate(
  (w) => w is Text && _plain(w.data ?? w.textSpan?.toPlainText() ?? '') == s,
  description: 'Text "$s"',
);

Finder _inputs() => find.byType(TextField);
String _amount(WidgetTester t) =>
    t.widget<TextField>(_inputs().first).controller!.text;

Future<_FakeRepo> _open(
  WidgetTester tester, {
  Budget? edit,
  bool overallNew = false,
  Set<int> used = const {},
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        budgetRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => _cats),
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
                onPressed: () => showBudgetEditDialog(
                  ctx,
                  year: 2026,
                  month: 10,
                  edit: edit,
                  overallNew: overallNew,
                  usedCategoryIds: used,
                ),
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
  return repo;
}

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(
    find.ancestor(of: _t(label), matching: find.byType(PButton)).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('총 예산(없음) — 제목 · 칸 이름 · 제안 칩 넷 · 머리 카드 없음 · [추가]', (
    tester,
  ) async {
    final repo = await _open(tester, overallNew: true);
    expect(_t('10월 총 예산'), findsOneWidget);
    expect(_t('총 예산'), findsOneWidget);
    expect(find.byType(PChip), findsNWidgets(4));
    expect(_t('150만원'), findsOneWidget);
    expect(_t('300만원'), findsOneWidget);
    expect(_t('카테고리'), findsNothing);
    expect(_t('월 한도'), findsNothing);
    // 빈 채 누르면 칸 아래 오류 · 요청 0 · 버튼은 켜져 있다
    await _press(tester, l.budgetSubmitAdd);
    expect(_t(l.budgetFormErrTotal), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('칩을 누르면 칸에 쉼표로 넣고 쓰는 동안 쉼표가 찍힌다', (tester) async {
    final repo = await _open(tester, overallNew: true);
    await tester.tap(_t('200만원'));
    await tester.pumpAndSettle();
    expect(_amount(tester), '2,000,000');
    // 칩은 골라지지 않는다 — 다시 눌러도 같은 값
    await tester.tap(_t('150만원'));
    await tester.pumpAndSettle();
    expect(_amount(tester), '1,500,000');
    await tester.enterText(_inputs().first, '1234');
    expect(_amount(tester), '1,234');
    await _press(tester, l.budgetSubmitAdd);
    expect(repo.calls, ['create:null:1234:2026-10']);
  });

  testWidgets('총 예산(있음) — [저장] 은 금액만 고친다', (tester) async {
    const edit = Budget(
      rowId: 7,
      budgetAmount: 9876543210,
      budgetYear: 2026,
      budgetMonth: 10,
    );
    final repo = await _open(tester, edit: edit);
    expect(_amount(tester), '9,876,543,210');
    await _press(tester, l.actionSave);
    expect(repo.calls, ['update:7:9876543210']);
  });

  testWidgets('저장 실패 — 시트는 열린 채 맨 위에 우리 글 Callout, 서버 글 없음, 값은 남는다', (
    tester,
  ) async {
    const edit = Budget(
      rowId: 7,
      budgetAmount: 500000,
      budgetYear: 2026,
      budgetMonth: 10,
    );
    final repo = await _open(tester, edit: edit);
    repo.fail = true;
    await _press(tester, l.actionSave);
    expect(_t(l.budgetSaveFailed), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
    expect(_amount(tester), '500,000');
    expect(repo.calls, ['update:7:500000']);
  });

  testWidgets('100억 넘게 저장된 옛 값은 누를 때 칸 아래에 말이 나온다', (tester) async {
    const edit = Budget(
      rowId: 7,
      budgetAmount: 20000000000,
      budgetYear: 2026,
      budgetMonth: 10,
    );
    final repo = await _open(tester, edit: edit);
    expect(_t(l.amountTooLarge), findsNothing);
    await _press(tester, l.actionSave);
    expect(_t(l.amountTooLarge), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('카테고리 추가 — 처음엔 고르지 않음 · 제안 여섯 · 빈 저장은 두 칸 오류', (tester) async {
    final repo = await _open(tester, used: {1});
    expect(_t('카테고리 추가'), findsNothing);
    expect(_t(l.budgetCategoryAdd), findsOneWidget);
    expect(_t(l.budgetFormCategoryPlaceholder), findsOneWidget);
    expect(_t(l.budgetFormAmountLabel), findsOneWidget);
    expect(find.byType(PChip), findsNWidgets(6));
    expect(_amount(tester), '');
    await _press(tester, l.budgetSubmitAdd);
    expect(_t(l.budgetFormErrCategory), findsOneWidget);
    expect(_t(l.budgetFormErrAmount), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('카테고리 줄 오류 글은 줄의 설명으로 읽힌다', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    await _press(tester, l.budgetSubmitAdd);
    // 이름이 "카테고리…" 이고 버튼인 노드 — 낭독기가 읽는 그 노드에 오류가 붙어야 한다
    final nodes = find.semantics.byPredicate(
      (n) => n.label.startsWith('카테고리') && n.flagsCollection.isButton,
    );
    expect(nodes, findsOneWidget);
    expect(nodes.evaluate().single.hint, contains(l.budgetFormErrCategory));
    handle.dispose();
  });

  testWidgets('고르기 시트 — 예산 있는 카테고리는 막힌 줄 · 누르면 바로 넣고 닫힌다', (tester) async {
    final repo = await _open(tester, used: {1});
    await tester.tap(_t(l.budgetFormCategoryPlaceholder));
    await tester.pumpAndSettle();
    // 지출 최상위만 — 월급(수입)은 없다
    expect(_t('월급'), findsNothing);
    expect(_t(l.budgetPickUsed), findsOneWidget);
    final used = tester.widget<PListButtonItem>(
      find.ancestor(of: _t('식비'), matching: find.byType(PListButtonItem)).first,
    );
    expect(used.onTap, isNull);
    // 18자 이름이 말줄임 없이 그대로
    await tester.tap(
      find.ancestor(of: _t(_longName), matching: find.byType(PListButtonItem)),
    );
    await tester.pumpAndSettle();
    expect(_t(l.budgetPickUsed), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            _plain(w.textSpan?.toPlainText() ?? '').endsWith(_longName),
      ),
      findsOneWidget,
    );
    await tester.tap(_t('30만원'));
    await tester.pumpAndSettle();
    expect(_amount(tester), '300,000');
    await _press(tester, l.budgetSubmitAdd);
    expect(repo.calls, ['create:2:300000:2026-10']);
  });

  testWidgets('카테고리 수정 — 줄은 읽기만이고 저장은 금액만', (tester) async {
    const edit = Budget(
      rowId: 5,
      categoryRowId: 1,
      categoryName: '식비',
      budgetAmount: 400000,
      budgetYear: 2026,
      budgetMonth: 10,
    );
    final repo = await _open(tester, edit: edit, used: {1});
    expect(_t(l.budgetCategoryEdit), findsOneWidget);
    expect(find.byType(PListButtonItem), findsNothing);
    expect(find.byType(PListItem), findsOneWidget);
    await tester.enterText(_inputs().first, '450000');
    await _press(tester, l.actionSave);
    expect(repo.calls, ['update:5:450000']);
  });

  testWidgets('저장 중에는 X · 뒤로 · Esc 로 닫히지 않고 묻지도 않는다 — 실패하면 맨 위 Callout', (
    tester,
  ) async {
    const edit = Budget(
      rowId: 7,
      budgetAmount: 500000,
      budgetYear: 2026,
      budgetMonth: 10,
    );
    final repo = await _open(tester, edit: edit);
    await tester.enterText(_inputs().first, '600000');
    repo
      ..fail = true
      ..gate = Completer<void>();
    await tester.tap(
      find.ancestor(of: _t(l.actionSave), matching: find.byType(PButton)).last,
    );
    await tester.pump();
    expect(repo.calls, ['update:7:600000']);
    final close = find.byKey(const ValueKey('p-bottom-sheet-close'));
    await tester.tap(close, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_t(l.sheetLeaveTitle), findsNothing, reason: '저장 중에는 묻지도 않는다');
    expect(find.byKey(const ValueKey('p-bottom-sheet-root')), findsOneWidget);

    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('p-bottom-sheet-root')), findsOneWidget);
    expect(_t(l.budgetSaveFailed), findsOneWidget);
    expect(_amount(tester), '600,000');
  });

  testWidgets('바뀐 채 닫으면 확인창 · 안 바뀌면 묻지 않는다', (tester) async {
    await _open(tester, overallNew: true);
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(_t(l.sheetLeaveTitle), findsNothing);

    await _open(tester, overallNew: true);
    await tester.enterText(_inputs().first, '5');
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(_t(l.sheetLeaveTitle), findsOneWidget);
  });
}

const _longName = '카페·간식·디저트 모임 지출 항목';
