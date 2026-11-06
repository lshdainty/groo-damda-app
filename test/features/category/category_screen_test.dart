// 카테고리 관리(I-20 B) — 나무 줄 · 줄 끝 ⋮ 없음 · 줄 누름 = 수정 시트 · 수정 시트 머리 ⋮ 의 동작 · 삭제 확인 · 폼 규칙 ·
// 순서 모드 · 상태 한 벌. 웹 `CategoryManager.test.tsx` · `CategoryEditDialog.test.tsx` 와 같은 시나리오.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/category/presentation/category_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_parent_item.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import '../../support/line_breaks.dart';
import '../../support/plain_text.dart';

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio());
  final calls = <String>[];

  @override
  Future<ExpenseCategory> createCategory({
    required String categoryName,
    String? icon,
    String? color,
    required String expenseType,
    int? parentRowId,
    bool silent = false,
  }) async {
    calls.add(
      'create:$categoryName:$icon:$color:$expenseType:${parentRowId ?? '-'}',
    );
    return ExpenseCategory(rowId: 99, categoryName: categoryName);
  }

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
    calls.add(
      'update:$id:$categoryName:$icon:$color:$expenseType:${parentRowId ?? '-'}',
    );
    return ExpenseCategory(rowId: id, categoryName: categoryName);
  }

  @override
  Future<void> deleteCategory(int id, {bool silent = false}) async {
    calls.add('delete:$id');
  }
}

const _food = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#c73838',
  hasChildren: true,
);
const _lunch = ExpenseCategory(
  rowId: 2,
  categoryName: '점심',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  parentRowId: 1,
  icon: 'utensils',
  color: '#c73838',
);
const _dinner = ExpenseCategory(
  rowId: 3,
  categoryName: '저녁',
  expenseType: 'EXPENSE',
  sortOrder: 1,
  parentRowId: 1,
);
const _bus = ExpenseCategory(
  rowId: 4,
  categoryName: '교통',
  expenseType: 'EXPENSE',
  sortOrder: 1,
  icon: 'bus',
  color: '#2c70bf',
);
// 팔레트 밖 색 + 세트 밖 아이콘 — 가장 나쁜 값
const _odd = ExpenseCategory(
  rowId: 5,
  categoryName: '카페·간식·디저트 모임',
  expenseType: 'EXPENSE',
  sortOrder: 2,
  icon: 'not-a-real-icon',
  color: '#9E9E9E',
);
const _salary = ExpenseCategory(
  rowId: 6,
  categoryName: '월급',
  expenseType: 'INCOME',
  sortOrder: 0,
  icon: 'wallet',
  color: '#2d8060',
);
const _all = [_food, _lunch, _dinner, _bus, _odd, _salary];

RecurringTransaction _rec(int id, int categoryRowId) => RecurringTransaction(
  rowId: id,
  categoryRowId: categoryRowId,
  expenseType: 'EXPENSE',
  frequency: 'MONTHLY',
);

String _plain(String s) =>
    s.replaceAll('⁠', '').replaceAll('​', '').replaceAll('￼', '');

Finder _t(String s) => find.byWidgetPredicate(
  (w) => w is Text && _plain(w.data ?? w.textSpan?.toPlainText() ?? '') == s,
  description: 'Text "$s"',
);

Finder _tc(String s) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      _plain(w.data ?? w.textSpan?.toPlainText() ?? '').contains(s),
  description: 'Text containing "$s"',
);

Future<_FakeRepo> _open(
  WidgetTester tester, {
  List<ExpenseCategory> categories = _all,
  List<RecurringTransaction>? recurring,
  double scale = 1,
  Future<List<ExpenseCategory>> Function()? loader,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith(
          (ref) => loader != null ? loader() : Future.value(categories),
        ),
        recurringListProvider.overrideWith(
          (ref) async => recurring ?? <RecurringTransaction>[],
        ),
        ...extra,
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const CategoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// 줄을 눌러 수정 시트를 연다.
Future<void> _openEditOf(WidgetTester tester, String name) async {
  await tester.tap(_t(name));
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester, String name) async {
  await tester.tap(find.bySemanticsLabel('$name 더보기'));
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.tap(
    find.ancestor(of: _t(label), matching: find.byType(PButton)).last,
  );
  await tester.pumpAndSettle();
}

/// 시트 안 이름 칸(화면의 검색칸과 가른다).
Finder get _sheetField => find.descendant(
  of: find.byKey(const ValueKey('p-bottom-sheet-root')),
  matching: find.byType(TextField),
);

String? _focusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  testWidgets('목록 — 탭 개수 · 목록 제목 · 줄 어디에도 ⋮ 가 없고 꺾쇠 단추 이름은 고정', (tester) async {
    await _open(tester);
    // 탭 글은 이름만 — 개수는 목록 제목이 말한다
    final tabs = find.byType(PTabs<int>);
    expect(find.descendant(of: tabs, matching: _t('지출')), findsOneWidget);
    expect(find.descendant(of: tabs, matching: _t('수입')), findsOneWidget);
    expect(_t('지출 5'), findsNothing);
    expect(_t('수입 1'), findsNothing);
    expect(_t('지출 카테고리 5개'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('더보기')), findsNothing);
    expect(find.bySemanticsLabel('식비 하위 카테고리'), findsOneWidget);
    // 하위는 처음 모두 펼침
    expect(_t('점심'), findsOneWidget);
    expect(_t('저녁'), findsOneWidget);
    // 설명 줄 없음
    expect(_tc('하위 카테고리 있음'), findsNothing);
  });

  testWidgets('꺾쇠 단추는 펴고 접기만 — 수정 시트는 열리지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(find.bySemanticsLabel('식비 하위 카테고리'));
    await tester.pumpAndSettle();
    expect(_t('점심'), findsNothing);
    expect(_t('카테고리 수정'), findsNothing);
  });

  testWidgets('줄 누름 = 수정 시트 — 머리 ⋮ 이름 "{이름} 더보기"', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '교통');
    expect(_t('카테고리 수정'), findsOneWidget);
    expect(find.bySemanticsLabel('교통 더보기'), findsOneWidget);
  });

  testWidgets('머리 ⋮ 메뉴 갈래 — 최상위(하위 없음) 셋 · 최상위(하위 있음) 둘 · 하위 둘', (
    tester,
  ) async {
    await _open(tester);
    // 최상위 · 하위 없음
    await _openEditOf(tester, '교통');
    await _openMenu(tester, '교통');
    expect(_t('하위 카테고리 추가'), findsOneWidget);
    expect(_t('거래 옮기기'), findsOneWidget);
    expect(_t('삭제'), findsOneWidget);
    await tester.tapAt(const Offset(180, 40)); // 딤을 눌러 메뉴만 닫는다
    await tester.pumpAndSettle();
  });

  testWidgets('머리 ⋮ 메뉴 — 하위가 있는 최상위는 거래 옮기기가 없다', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '식비');
    await _openMenu(tester, '식비');
    expect(_t('하위 카테고리 추가'), findsOneWidget);
    expect(_t('거래 옮기기'), findsNothing);
    expect(_t('삭제'), findsOneWidget);
  });

  testWidgets('머리 ⋮ 메뉴 — 하위는 하위 카테고리 추가가 없다', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '점심');
    await _openMenu(tester, '점심');
    expect(_t('하위 카테고리 추가'), findsNothing);
    expect(_t('거래 옮기기'), findsOneWidget);
    expect(_t('삭제'), findsOneWidget);
  });

  testWidgets('새 카테고리 폼에는 머리 ⋮ 가 없다', (tester) async {
    await _open(tester);
    await tester.tap(_t('추가').first);
    await tester.pumpAndSettle();
    expect(_t('카테고리 추가'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('더보기')), findsNothing);
  });

  testWidgets('하위 카테고리 추가 — 수정 시트를 닫고 새 폼(상위 = 그 줄)을 연다', (tester) async {
    final repo = await _open(tester);
    await _openEditOf(tester, '교통');
    await _openMenu(tester, '교통');
    await tester.tap(_t('하위 카테고리 추가'));
    await tester.pumpAndSettle();
    // 폼 위에 폼이 겹치지 않는다 — 수정 제목은 사라지고 추가 제목 하나
    expect(_t('카테고리 수정'), findsNothing);
    expect(_t('카테고리 추가'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(PListButtonItem), matching: _t('교통')),
      findsWidgets,
    );
    await tester.enterText(_sheetField, '버스');
    await _tapButton(tester, '추가');
    expect(repo.calls.single, startsWith('create:버스:tag:'));
    expect(repo.calls.single, endsWith(':EXPENSE:4'));
  });

  testWidgets('거래 옮기기 — 수정 시트를 닫고 옮기기 시트를 연다 · 닫으면 초점은 그 줄로', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '교통');
    await _openMenu(tester, '교통');
    await tester.tap(_t('거래 옮기기'));
    await tester.pumpAndSettle();
    expect(_t('카테고리 수정'), findsNothing);
    expect(
      find.descendant(of: find.byType(PButton), matching: _t('옮기기')),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('닫기').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(_focusLabel(), 'cat-4');
  });

  testWidgets('K1 — 고친 값이 있으면 ⋮ 동작 전에 "작성한 내용이 사라져요" 를 먼저 묻는다', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '교통');
    await tester.enterText(_sheetField, '교통비');
    await _openMenu(tester, '교통');
    await tester.tap(_t('거래 옮기기'));
    await tester.pumpAndSettle();
    expect(_t('작성한 내용이 사라져요'), findsOneWidget);
    expect(_t('카테고리 수정'), findsOneWidget, reason: '묻는 동안 수정 시트는 그대로');
    // 계속 작성 — 동작하지 않는다
    await tester.tap(_t('계속 작성'));
    await tester.pumpAndSettle();
    expect(_t('카테고리 수정'), findsOneWidget);
    // 나가기 — 동작한다
    await _openMenu(tester, '교통');
    await tester.tap(_t('거래 옮기기'));
    await tester.pumpAndSettle();
    await tester.tap(_t('나가기'));
    await tester.pumpAndSettle();
    expect(_t('카테고리 수정'), findsNothing);
    expect(
      find.descendant(of: find.byType(PButton), matching: _t('옮기기')),
      findsOneWidget,
    );
  });

  testWidgets('K1 — 고치지 않았으면 묻지 않고 바로 동작한다', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '교통');
    await _openMenu(tester, '교통');
    await tester.tap(_t('거래 옮기기'));
    await tester.pumpAndSettle();
    expect(_t('작성한 내용이 사라져요'), findsNothing);
  });

  testWidgets('삭제 — 두 문장 늘(예산 얘기) · 반복 거래가 있으면 셋째 문장 · 요청 한 번', (tester) async {
    final repo = await _open(
      tester,
      recurring: [_rec(1, 4), _rec(2, 4), _rec(3, 1)],
    );
    await _openEditOf(tester, '교통');
    await _openMenu(tester, '교통');
    await tester.tap(_t('삭제'));
    await tester.pumpAndSettle();
    expect(_t('"교통" 카테고리를 삭제할까요?'), findsOneWidget);
    expect(
      _t(
        '이미 기록된 거래는 삭제되지 않고 그대로 남아요. 이 카테고리에 걸린 예산은 함께 삭제돼요. '
        '이 카테고리를 쓰는 반복 거래 2개는 계속 이 카테고리로 기록돼요.',
      ),
      findsOneWidget,
    );
    await _tapButton(tester, '삭제');
    expect(repo.calls, ['delete:4']);
  });

  testWidgets('삭제 — 반복 거래가 없으면 두 문장 · 취소하면 요청이 없고 초점은 그 줄로', (tester) async {
    final repo = await _open(tester);
    await _openEditOf(tester, '교통');
    await _openMenu(tester, '교통');
    await tester.tap(_t('삭제'));
    await tester.pumpAndSettle();
    expect(
      _t('이미 기록된 거래는 삭제되지 않고 그대로 남아요. 이 카테고리에 걸린 예산은 함께 삭제돼요.'),
      findsOneWidget,
    );
    await tester.tap(_t('취소'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(repo.calls, isEmpty);
    expect(_focusLabel(), 'cat-4');
  });

  testWidgets('삭제 뒤 초점은 이웃 줄(다음, 없으면 앞 줄)', (tester) async {
    final repo = await _open(tester);
    await _openEditOf(tester, '카페·간식·디저트 모임');
    await _openMenu(tester, '카페·간식·디저트 모임');
    await tester.tap(_t('삭제'));
    await tester.pumpAndSettle();
    await _tapButton(tester, '삭제');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(repo.calls, ['delete:5']);
    // 마지막 줄이었다 — 앞 줄(교통)
    expect(_focusLabel(), 'cat-4');
  });

  testWidgets('삭제 — 하위가 있으면 막는 확인 하나', (tester) async {
    final repo = await _open(tester);
    await _openEditOf(tester, '식비');
    await _openMenu(tester, '식비');
    await tester.tap(_t('삭제'));
    await tester.pumpAndSettle();
    expect(_t('삭제할 수 없어요'), findsOneWidget);
    await tester.tap(_t('확인'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
  });

  testWidgets('수정 — 종류 줄은 보기만 · 최상위의 상위 줄도 보기만', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '교통');
    for (final title in ['종류', '상위 카테고리']) {
      expect(
        find.ancestor(of: _t(title), matching: find.byType(PListButtonItem)),
        findsNothing,
        reason: '$title 줄은 누르지 못한다',
      );
    }
    // 색상 · 아이콘 줄은 누른다
    expect(
      find.ancestor(of: _t('색상'), matching: find.byType(PListButtonItem)),
      findsOneWidget,
    );
  });

  testWidgets('팔레트 밖 색 · 세트 밖 아이콘으로 열어 이름만 고쳐 저장 → 색 그대로', (tester) async {
    final repo = await _open(tester);
    await _openEditOf(tester, '카페·간식·디저트 모임');
    expect(_t('지금 색'), findsOneWidget);
    expect(_t('지금 아이콘'), findsOneWidget);
    await tester.enterText(_sheetField, '카페');
    await _tapButton(tester, '저장');
    expect(repo.calls.single, 'update:5:카페:not-a-real-icon:#9E9E9E:EXPENSE:-');
  });

  testWidgets('새 카테고리 처음 색 = 같은 종류가 쓰지 않은 첫 색 — 늘 빨강이 아니다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(_t('추가').first);
    await tester.pumpAndSettle();
    await tester.enterText(_sheetField, '여행');
    await _tapButton(tester, '추가');
    final color = repo.calls.single.split(':')[3];
    // 식비(#c73838 빨강)가 이미 쓰는 색이다
    expect(color.toLowerCase(), isNot('#c73838'));
  });

  testWidgets('검증 — 빈 이름 · 중복은 누를 때 칸 아래에 알리고 요청이 없다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(_t('추가').first);
    await tester.pumpAndSettle();
    await _tapButton(tester, '추가');
    expect(_t('이름을 입력해주세요.'), findsOneWidget);
    await tester.enterText(_sheetField, '교통');
    await _tapButton(tester, '추가');
    expect(_t('같은 자리에 같은 이름의 카테고리가 있어요.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('이름은 12자에서 멈춘다', (tester) async {
    await _open(tester);
    await tester.tap(_t('추가').first);
    await tester.pumpAndSettle();
    await tester.enterText(_sheetField, '가나다라마바사아자차카타파하');
    await tester.pump();
    final text = tester.widget<TextField>(_sheetField).controller!.text;
    expect(text.characters.length, 12);
  });

  testWidgets('쓴 채 닫으면 묻고 안 쓰고 닫으면 묻지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(_t('추가').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('닫기').last);
    await tester.pumpAndSettle();
    expect(_t('작성한 내용이 사라져요'), findsNothing);
    expect(_t('카테고리 추가'), findsNothing);
    await tester.tap(_t('추가').first);
    await tester.pumpAndSettle();
    await tester.enterText(_sheetField, '여행');
    await tester.tap(find.bySemanticsLabel('닫기').last);
    await tester.pumpAndSettle();
    expect(_t('작성한 내용이 사라져요'), findsOneWidget);
  });

  testWidgets('종류를 바꾸면 상위는 "최상위" 로 되돌아간다', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '교통');
    await _openMenu(tester, '교통');
    await tester.tap(_t('하위 카테고리 추가'));
    await tester.pumpAndSettle();
    // 상위 = 교통 · 종류를 수입으로 → 최상위
    await tester.tap(_t('종류'));
    await tester.pumpAndSettle();
    await tester.tap(_t('수입').last);
    await tester.pumpAndSettle();
    final parentRow = find.ancestor(
      of: _t('상위 카테고리'),
      matching: find.byType(PListButtonItem),
    );
    expect(find.descendant(of: parentRow, matching: _t('최상위')), findsOneWidget);
  });

  testWidgets('상위 고르기 — "최상위" 줄에도 타일 40 (제목이 다른 줄과 한 세로선)', (tester) async {
    await _open(tester);
    await tester.tap(_t('추가').first);
    await tester.pumpAndSettle();
    await tester.tap(_t('상위 카테고리'));
    await tester.pumpAndSettle();
    final rootTile = find.descendant(
      of: find.ancestor(
        of: _t('최상위').last,
        matching: find.byType(PListButtonItem),
      ),
      matching: find.byType(PListTile),
    );
    expect(rootTile, findsOneWidget);
    expect(tester.getSize(rootTile), const Size(40, 40));
    final rootX = tester.getTopLeft(_t('최상위').last).dx;
    final foodX = tester.getTopLeft(_t('식비').last).dx;
    expect(rootX, foodX);
  });

  testWidgets('하위 수정 — 상위 고르기 맨 위에 승격 안내 한 문장, "최상위" 줄은 없다', (tester) async {
    await _open(tester);
    await _openEditOf(tester, '점심');
    await tester.tap(_t('상위 카테고리'));
    await tester.pumpAndSettle();
    expect(_t('최상위로 올리려면 새 최상위를 만들어 거래를 옮겨주세요.'), findsOneWidget);
    expect(
      find.ancestor(of: _t('최상위'), matching: find.byType(PListTile)),
      findsNothing,
    );
  });

  testWidgets('순서 모드 — 검색 비움 · 안내 · 손잡이 이름 · 줄 누름 막힘', (tester) async {
    await _open(tester);
    await tester.tap(_t('순서 바꾸기'));
    await tester.pumpAndSettle();
    expect(_t('완료'), findsOneWidget);
    expect(_tc('손잡이를 끌어 순서를 바꿔요.'), findsOneWidget);
    expect(find.bySemanticsLabel('식비 순서 바꾸기'), findsOneWidget);
    expect(find.bySemanticsLabel('점심 순서 바꾸기'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('더보기')), findsNothing);
    // 줄을 눌러도 수정 시트가 열리지 않는다
    await tester.tap(_t('교통'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_t('카테고리 수정'), findsNothing);
    await tester.tap(_t('완료'));
    await tester.pumpAndSettle();
    expect(_t('순서 바꾸기'), findsOneWidget);
  });

  testWidgets('찾기 0건 · 카테고리 0개 안내 글', (tester) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField).first, '없는이름');
    await tester.pumpAndSettle();
    expect(_t('찾는 카테고리가 없어요.'), findsOneWidget);
  });

  testWidgets('카테고리 0개', (tester) async {
    await _open(tester, categories: const []);
    expect(_t('카테고리가 없어요.'), findsOneWidget);
  });

  testWidgets('실패 — 그 자리 Result Section 하나 + [다시 시도] · 오류 원문 없음', (
    tester,
  ) async {
    await _open(tester, loader: () async => throw Exception('boom'));
    expect(find.byType(PResultSection), findsOneWidget);
    expect(_t('카테고리를 불러오지 못했어요'), findsOneWidget);
    expect(_tc('boom'), findsNothing);
    expect(_t('다시 시도'), findsOneWidget);
  });

  testWidgets('불러오는 중 — 목록 제목은 두지 않는다', (tester) async {
    final c = Completer<List<ExpenseCategory>>();
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoriesProvider.overrideWith((ref) => c.future)],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const CategoryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(_tc('카테고리 0개'), findsNothing);
    expect(findText('순서 바꾸기'), findsNothing);
    c.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('글자 200% — 12자 이름 줄바꿈 · 넘침 오류 없음', (tester) async {
    await _open(tester, scale: 2);
    expect(tester.takeException(), isNull);
    await _openEditOf(tester, '카페·간식·디저트 모임');
    expect(tester.takeException(), isNull);
  });

  testWidgets('하위를 예산이 걸린 다른 부모로 옮기면 넘음 확인 — 버튼 "옮기기" · 취소하면 요청 없음', (
    tester,
  ) async {
    final repo = await _open(
      tester,
      extra: [
        monthBudgetsProvider.overrideWith(
          (ref, key) async => [
            Budget(
              rowId: 1,
              categoryRowId: 4,
              budgetAmount: 100,
              budgetYear: key.year,
              budgetMonth: key.month,
            ),
          ],
        ),
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
            categoryBreakdown: const [
              CategoryBreakdown(categoryRowId: 4, totalAmount: 90),
              CategoryBreakdown(
                categoryRowId: 2,
                parentCategoryRowId: 1,
                totalAmount: 50,
              ),
            ],
          ),
        ),
      ],
    );
    await _openEditOf(tester, '점심');
    await tester.tap(_t('상위 카테고리'));
    await tester.pumpAndSettle();
    await tester.tap(_t('교통').last);
    await tester.pumpAndSettle();
    await _tapButton(tester, '저장');
    expect(_t('예산 초과 확인'), findsOneWidget);
    expect(_t('옮기면 "교통" 예산을 40원 넘어요. 그래도 옮길까요?'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(PButton), matching: _t('옮기기')),
      findsOneWidget,
    );
    await tester.tap(_t('취소'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    // 다시 저장해서 [옮기기] 를 누르면 요청이 나간다
    await _tapButton(tester, '저장');
    await tester.tap(
      find.descendant(of: find.byType(PButton), matching: _t('옮기기')),
    );
    await tester.pumpAndSettle();
    expect(repo.calls.single, startsWith('update:2:점심:'));
    expect(repo.calls.single, endsWith(':EXPENSE:4'));
  });

  testWidgets('순서 모드 — 부모 줄 글 · 타일은 보기 줄과 같은 색, 누름만 막힌다', (tester) async {
    await _open(tester);
    Color titleColor(String name) => tester
        .widget<Text>(
          find
              .descendant(
                of: find.ancestor(
                  of: _t(name),
                  matching: find.byType(PListParentItem),
                ),
                matching: find.byKey(const ValueKey('plist-title')),
              )
              .first,
        )
        .style!
        .color!;
    Color tileBg(String name) =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.ancestor(
                          of: _t(name),
                          matching: find.byType(PListParentItem),
                        ),
                        matching: find.byKey(const ValueKey('plist-tile')),
                      )
                      .first,
                )
                .decoration
                .runtimeType ==
            BoxDecoration
        ? (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.ancestor(
                                of: _t(name),
                                matching: find.byType(PListParentItem),
                              ),
                              matching: find.byKey(
                                const ValueKey('plist-tile'),
                              ),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color!
        : Colors.transparent;
    final viewTitle = titleColor('교통');
    final viewTile = tileBg('교통');
    await tester.tap(_t('순서 바꾸기'));
    await tester.pumpAndSettle();
    expect(titleColor('교통'), viewTitle);
    expect(tileBg('교통'), viewTile);
    // 누르면 수정 시트가 열리지 않는다
    await tester.tap(_t('교통'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_t('카테고리 수정'), findsNothing);
  });

  testWidgets('순서 모드 — 손잡이는 줄 끝에서 12 안쪽(부모 · 하위 같음)', (tester) async {
    await _open(tester);
    await tester.tap(_t('순서 바꾸기'));
    await tester.pumpAndSettle();
    for (final name in ['식비', '점심']) {
      final grip = tester.getRect(find.bySemanticsLabel('$name 순서 바꾸기'));
      // 보이는 단추 40 의 오른쪽 끝 = 360 − 12 (누르는 영역 44 는 사방 2 넓다)
      expect(grip.right, anyOf(360 - 12, 360 - 12 + 2), reason: name);
    }
  });

  testWidgets('순서 모드 안내 줄은 낱말 단위로 줄을 바꾼다 — 글자 200% 에서도 낱말 중간 줄바꿈 0', (
    tester,
  ) async {
    await _open(tester, scale: 2);
    await tester.tap(_t('순서 바꾸기'));
    await tester.pumpAndSettle();
    final hint = findText(
      keepAll('손잡이를 끌어 순서를 바꿔요. 상위는 상위끼리, 하위는 같은 상위 안에서 옮겨요.'),
    );
    expect(hint, findsOneWidget);
    expect(midWordBreaks(tester, hint), isEmpty);
  });
}
