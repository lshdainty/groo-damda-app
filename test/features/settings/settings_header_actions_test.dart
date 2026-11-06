// 설정 하위 화면 머리 오른쪽 글 버튼(I-16 14 · 15 · S1) — 실제 화면에 데이터를 넣고 잰다.
//
//  - 카테고리: 머리 "추가" 하나 · 순서 바꾸기 ↔ 완료 는 목록 제목(List Header) 오른쪽
//  - 반복 거래 · 프리셋: 머리 "추가" 는 목록이 비어 있지 않을 때만(빈 화면 · 불러오는 중에는 숨김)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/category/presentation/category_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_screen.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import '../../support/plain_text.dart';

final _cats = <ExpenseCategory>[
  const ExpenseCategory(
    rowId: 1,
    categoryName: '식비',
    expenseType: 'EXPENSE',
    sortOrder: 1,
    icon: 'utensils',
    color: '#2c70bf',
  ),
  const ExpenseCategory(
    rowId: 2,
    categoryName: '교통',
    expenseType: 'EXPENSE',
    sortOrder: 2,
    icon: 'bus',
    color: '#2c70bf',
  ),
  const ExpenseCategory(
    rowId: 3,
    categoryName: '급여',
    expenseType: 'INCOME',
    sortOrder: 1,
    icon: 'wallet',
    color: '#2c70bf',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides,
) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _headerAdd => find.descendant(
  of: find.byType(PTopNavigation),
  matching: find.byType(PTopNavigationTextButton),
);

void main() {
  testWidgets('카테고리 — 머리 "추가" 하나 · 순서 바꾸기 는 목록 제목 오른쪽 · 누르면 완료', (
    tester,
  ) async {
    await _pump(tester, const CategoryScreen(), [
      categoriesProvider.overrideWith((ref) async => _cats),
    ]);
    expect(_headerAdd, findsOneWidget);
    expect(
      find.descendant(of: _headerAdd, matching: findText('추가')),
      findsOneWidget,
    );
    final header = find.byType(PListHeader);
    expect(header, findsOneWidget);
    final title = find.byKey(const ValueKey('plist-header-title'));
    expect(
      // 목록 제목은 Text.rich 다(075866bc)
      plainOf(tester.widget<Text>(title).textSpan!.toPlainText()),
      '지출 카테고리 2개',
    );
    final toggle = find.descendant(
      of: header,
      matching: find.byType(PTextButton),
    );
    expect(
      find.descendant(of: toggle, matching: findText('순서 바꾸기')),
      findsOneWidget,
    );
    // 제목 줄 오른쪽 끝 — 제목은 왼쪽, 버튼은 오른쪽
    expect(
      tester.getRect(toggle).left,
      greaterThan(tester.getRect(title).right),
    );
    // 머리(상단 바)에는 "편집" · "순서 바꾸기" 가 없다
    expect(
      find.descendant(
        of: find.byType(PTopNavigation),
        matching: findText('순서 바꾸기'),
      ),
      findsNothing,
    );

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: header, matching: findText('완료')),
      findsOneWidget,
    );
    expect(
      findTextContaining(keepAll('손잡이를 끌어')),
      findsOneWidget,
      reason: '편집 모드 안내 줄',
    );
    await tester.tap(
      find.descendant(of: header, matching: find.byType(PTextButton)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: header, matching: findText('순서 바꾸기')),
      findsOneWidget,
    );
  });

  testWidgets('카테고리 — 불러오는 중 · 실패에서는 "0개" 를 그리지 않는다', (tester) async {
    // 끝나지 않는 조회(불러오는 중)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith(
            (ref) => Completer<List<ExpenseCategory>>().future,
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const CategoryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PListHeader), findsNothing);
    expect(findTextContaining('0개'), findsNothing);
  });

  testWidgets('카테고리 — 조회 실패에서도 "0개" 를 그리지 않는다', (tester) async {
    await _pump(tester, const CategoryScreen(), [
      categoriesProvider.overrideWith((ref) async => throw Exception('x')),
    ]);
    expect(find.byType(PListHeader), findsNothing);
    expect(findTextContaining('0개'), findsNothing);
  });

  testWidgets('반복 거래 — 머리 "추가" 는 목록이 있을 때만', (tester) async {
    await _pump(tester, const RecurringScreen(), [
      recurringListProvider.overrideWith(
        (ref) async => [
          RecurringTransaction(
            rowId: 1,
            expenseType: 'EXPENSE',
            amount: 9000,
            frequency: 'MONTHLY',
            isActive: 'Y',
          ),
        ],
      ),
      categoriesProvider.overrideWith((ref) async => const []),
    ]);
    expect(_headerAdd, findsOneWidget);
    expect(
      find.descendant(of: _headerAdd, matching: findText('추가')),
      findsOneWidget,
    );
  });

  testWidgets('반복 거래 — 빈 화면에서는 머리 "추가" 를 숨긴다', (tester) async {
    await _pump(tester, const RecurringScreen(), [
      recurringListProvider.overrideWith((ref) async => const []),
      categoriesProvider.overrideWith((ref) async => const []),
    ]);
    expect(find.byType(PTopNavigation), findsOneWidget);
    expect(_headerAdd, findsNothing);
  });

  testWidgets('프리셋 — 머리 "추가" 는 목록이 있을 때', (tester) async {
    final base = [
      categoriesProvider.overrideWith((ref) async => _cats),
      assetsProvider.overrideWith((ref) async => []),
    ];
    await _pump(tester, const PresetScreen(), [
      ...base,
      presetListProvider.overrideWith(
        (ref) async => [
          const ExpenseTemplate(
            rowId: 1,
            templateName: '점심',
            expenseType: 'EXPENSE',
            categoryRowId: 1,
            amount: 4500,
            lockAmount: 'Y',
            useCount: 3,
            merchant: '가맹점',
          ),
        ],
      ),
    ]);
    expect(_headerAdd, findsOneWidget);
    expect(
      find.descendant(of: _headerAdd, matching: findText('추가')),
      findsOneWidget,
    );
  });

  testWidgets('프리셋 — 빈 화면에서는 머리 "추가" 를 숨긴다', (tester) async {
    await _pump(tester, const PresetScreen(), [
      categoriesProvider.overrideWith((ref) async => _cats),
      assetsProvider.overrideWith((ref) async => []),
      presetListProvider.overrideWith((ref) async => const <ExpenseTemplate>[]),
    ]);
    expect(find.byType(PTopNavigation), findsOneWidget);
    expect(_headerAdd, findsNothing);
  });
}
