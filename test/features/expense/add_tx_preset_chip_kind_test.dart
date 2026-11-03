// 프리셋 칩은 **지금 탭의 종류만** 보여 준다.
//
// 종전엔 종류와 무관하게 사용 많은 순 8개였다. 지출 탭에서 수입 프리셋을 누르면
// `_applyPreset` 이 탭을 통째로 바꿔 버렸다 — 누른 사람은 "지출 하나를 빨리 넣으려고"
// 누른 것이라, 화면이 다른 탭으로 건너뛰는 건 사고다.
//
// 이체 탭에도 이제 칩이 뜬다. 필터가 없으면 이체 탭에 지출 프리셋이 뜨는, 반대 방향의
// 같은 사고가 난다.
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 시트를 띄워 글자를 읽는다.
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

const _category = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _presets = [
  ExpenseTemplate(
    rowId: 1,
    templateName: '점심',
    expenseType: 'EXPENSE',
    categoryRowId: 5,
  ),
  ExpenseTemplate(rowId: 2, templateName: '월급', expenseType: 'INCOME'),
  ExpenseTemplate(
    rowId: 3,
    templateName: '적금이체',
    expenseType: 'TRANSFER',
    assetRowId: 7,
    toAssetRowId: 8,
  ),
];

Future<void> _open(WidgetTester tester) async {
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => []),
        presetListProvider.overrideWith((ref) async => _presets),
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
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('지출 탭 — 지출 프리셋만', (tester) async {
    await _open(tester);

    expect(find.textContaining('점심'), findsOneWidget);
    expect(find.textContaining('월급'), findsNothing);
    expect(find.textContaining('적금이체'), findsNothing);
  });

  testWidgets('수입 탭 — 수입 프리셋만', (tester) async {
    await _open(tester);
    await tester.tap(find.text(l.expTypeIncome));
    await tester.pumpAndSettle();

    expect(find.textContaining('월급'), findsOneWidget);
    expect(find.textContaining('점심'), findsNothing);
    expect(find.textContaining('적금이체'), findsNothing);
  });

  testWidgets('이체 탭 — 이체 프리셋만. 칩 줄 자체는 뜬다', (tester) async {
    await _open(tester);
    await tester.tap(find.text(l.expTypeTransfer));
    await tester.pumpAndSettle();

    expect(find.textContaining('적금이체'), findsOneWidget);
    expect(find.textContaining('점심'), findsNothing);
    expect(find.textContaining('월급'), findsNothing);
  });
}
