// 거래 옮기기(I-20 B 11) — 입력 폼 시트, 갈래 둘, 켜 둔 [옮기기], 빈 채 누르면 칸 아래 오류.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/category/presentation/category_move_tx_sheet.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import '../../support/plain_text.dart';

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio());
  final calls = <String>[];

  @override
  Future<int> splitCategoryIntoChild(
    int id, {
    required String childName,
    required String icon,
    required String color,
    bool silent = false,
  }) async {
    calls.add('split:$id:$childName:$icon:$color');
    return 3;
  }

  @override
  Future<int> moveCategoryTransactions(
    int id,
    int targetCategoryRowId, {
    bool silent = false,
  }) async {
    calls.add('move:$id:$targetCategoryRowId');
    return 5;
  }
}

const _a = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  color: '#c73838',
);
const _a1 = ExpenseCategory(
  rowId: 4,
  categoryName: '점심',
  expenseType: 'EXPENSE',
  parentRowId: 1,
  color: '#c73838',
);
const _b = ExpenseCategory(
  rowId: 2,
  categoryName: '교통',
  expenseType: 'EXPENSE',
  color: '#2c70bf',
  icon: 'bus',
);
const _income = ExpenseCategory(
  rowId: 3,
  categoryName: '월급',
  expenseType: 'INCOME',
);
const _d = ExpenseCategory(
  rowId: 5,
  categoryName: '카페',
  expenseType: 'EXPENSE',
  color: '#2d8060',
);
const _all = [_a, _a1, _b, _income, _d];

String _plain(String s) =>
    s.replaceAll('⁠', '').replaceAll('​', '').replaceAll('￼', '');

Finder _t(String s) => find.byWidgetPredicate(
  (w) => w is Text && _plain(w.data ?? w.textSpan?.toPlainText() ?? '') == s,
  description: 'Text "$s"',
);

Future<_FakeRepo> _open(
  WidgetTester tester, {
  required ExpenseCategory source,
  List<ExpenseCategory> categories = _all,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => categories),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showCategoryMoveTxSheet(
                ctx,
                source: source,
                categories: categories,
              ),
              child: const Text('open'),
            ),
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

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(
    find.ancestor(of: _t('옮기기'), matching: find.byType(PButton)).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('하위 없는 최상위 — 설명 · 갈래 둘(새 하위가 먼저) · 빈 채 누르면 칸 아래 오류 · 요청 0', (
    tester,
  ) async {
    final repo = await _open(tester, source: _b);
    expect(_t('거래 옮기기'), findsOneWidget);
    expect(_t('교통에 달린 거래 · 반복 거래 · 나눈 거래를 모두 옮겨요.'), findsOneWidget);
    expect(find.byType(PSegmentedControl<Object?>), findsNothing);
    expect(_t('새 하위 만들기'), findsOneWidget);
    expect(_t('기존 카테고리로'), findsOneWidget);
    // 켜 둔 버튼 — 눌러도 요청이 없고 칸 아래에 알린다
    await _submit(tester);
    expect(_t('만들 하위 이름을 입력해주세요.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('새 하위 — 12자에서 멈추고 요청 본문은 원래 카테고리의 아이콘 · 색', (tester) async {
    final repo = await _open(tester, source: _b);
    await tester.enterText(find.byType(TextField), '열세글자를이어서쓰면열두자');
    await tester.pump();
    final typed = tester.widget<TextField>(find.byType(TextField)).controller!;
    expect(typed.text.characters.length, lessThanOrEqualTo(12));
    await tester.enterText(find.byType(TextField), '강의');
    await _submit(tester);
    expect(repo.calls, ['split:2:강의:bus:#2c70bf']);
  });

  testWidgets('기존 카테고리로 — 같은 종류의 말단만 고르고 옮긴다 · 빈 채 오류', (tester) async {
    final repo = await _open(tester, source: _b);
    await tester.tap(_t('기존 카테고리로'));
    await tester.pumpAndSettle();
    expect(_t('같은 종류의 맨 아래 카테고리만 고를 수 있어요.'), findsOneWidget);
    await _submit(tester);
    expect(_t('옮길 카테고리를 골라주세요.'), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.tap(_t('카테고리 고르기'));
    await tester.pumpAndSettle();
    // 말단 · 같은 종류 · 자기 뺌 — 점심 · 카페 (식비는 하위가 있고 월급은 수입)
    expect(_t('점심'), findsOneWidget);
    expect(_t('카페'), findsOneWidget);
    // 식비는 하위가 있어 고를 수 없다 — 점심 줄의 설명(상위 이름)으로만 보인다
    expect(_t('식비'), findsOneWidget);
    expect(_t('월급'), findsNothing);
    await tester.tap(_t('카페'));
    await tester.pumpAndSettle();
    await _submit(tester);
    expect(repo.calls, ['move:2:5']);
  });

  testWidgets('하위 카테고리 — 갈래 고르기 없이 기존 카테고리로만', (tester) async {
    await _open(tester, source: _a1);
    expect(_t('새 하위 만들기'), findsNothing);
    expect(_t('카테고리 고르기'), findsOneWidget);
  });

  testWidgets('고를 곳이 0 이면 안내 글', (tester) async {
    await _open(tester, source: _b, categories: const [_b, _income]);
    await tester.tap(_t('기존 카테고리로'));
    await tester.pumpAndSettle();
    expect(_t('옮길 수 있는 카테고리가 없어요. 먼저 하나 만들어주세요.'), findsOneWidget);
  });

  testWidgets('쓴 채 닫으면 "작성한 내용이 사라져요" 를 묻는다', (tester) async {
    await _open(tester, source: _b);
    await tester.enterText(find.byType(TextField), '강');
    await tester.tap(find.bySemanticsLabel('닫기').last);
    await tester.pumpAndSettle();
    expect(_t('작성한 내용이 사라져요'), findsOneWidget);
  });
}
