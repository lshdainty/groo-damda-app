// 프리셋 "모두 보기"(I-20 C 20) — 지금 종류의 프리셋이 칩 수(8)보다 많을 때만 칩 줄 끝에 뜨고, 누르면 고르기 시트가 열려
// 아홉 번째부터도 고를 수 있다. 전체 개수가 아니라 **지금 종류** 로 센다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

const _cat = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

List<ExpenseTemplate> _nine() => [
  for (var i = 0; i < 9; i++)
    ExpenseTemplate(
      rowId: i + 1,
      templateName: '지출$i',
      expenseType: 'EXPENSE',
      categoryRowId: 5,
      useCount: 100 - i,
    ),
];

// 지출 3 + 수입 6 — 전체는 9 여도 지출 탭에는 "모두 보기" 가 없다
List<ExpenseTemplate> _mixed() => [
  for (var i = 0; i < 3; i++)
    ExpenseTemplate(
      rowId: i + 1,
      templateName: '지출$i',
      expenseType: 'EXPENSE',
      categoryRowId: 5,
    ),
  for (var i = 0; i < 6; i++)
    ExpenseTemplate(rowId: i + 10, templateName: '수입$i', expenseType: 'INCOME'),
];

Future<void> _open(WidgetTester tester, List<ExpenseTemplate> presets) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_cat]),
        assetsProvider.overrideWith((ref) async => []),
        presetListProvider.overrideWith((ref) async => presets),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAddTxSheet(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  testWidgets('지금 종류가 9개면 "모두 보기" 가 보이고, 누르면 아홉째도 고를 수 있다', (tester) async {
    await _open(tester, _nine());
    await tester.drag(find.byType(ListView).first, const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(find.text(l.presetShowAll), findsOneWidget);
    await tester.tap(find.text(l.presetShowAll));
    await tester.pumpAndSettle();
    expect(find.text(l.presetPickTitle), findsOneWidget);
    expect(find.text('지출8'), findsOneWidget, reason: '칩에 못 든 아홉째가 고르기 목록에 있다');
  });

  testWidgets('지출 3 + 수입 6 이면 지출 탭에 "모두 보기" 가 없다', (tester) async {
    await _open(tester, _mixed());
    expect(find.text(l.presetShowAll), findsNothing);
  });

  testWidgets('찾기 0건이면 "찾는 프리셋이 없어요."', (tester) async {
    await _open(tester, _nine());
    await tester.drag(find.byType(ListView).first, const Offset(-3000, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.presetShowAll));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, '없는이름');
    await tester.pumpAndSettle();
    expect(find.text(l.presetNoResult), findsOneWidget);
  });
}
