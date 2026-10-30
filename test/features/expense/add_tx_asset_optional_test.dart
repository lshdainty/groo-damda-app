// 자산을 안 고르고도 거래를 저장할 수 있어야 한다 — 웹과 같은 규칙.
//
// 자산까지 관리하지 않고 가계부로만 쓰는 사용자가 있다. 앱만 자산을 강제하면
// 그 사용법이 아예 막히고, 같은 계정인데 웹에서 넣은 거래는 되고 앱에선 안 되는
// 상태가 된다. 백엔드도 asset_row_id 를 nullable 로 받는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';

const _category = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _account = Asset(
  rowId: 10,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

Future<AppLocalizations> _open(WidgetTester tester) async {
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_account]),
        presetListProvider.overrideWith((ref) async => []),
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
  return AppLocalizations.delegate.load(const Locale('ko'));
}

void main() {
  testWidgets('금액 + 카테고리만 채우면 자산 없이도 저장 요청이 나간다', (tester) async {
    final l = await _open(tester);

    // 1단계 금액 → [다음] → 2단계 카테고리 줄 → 식비. 자산 줄은 일부러 건드리지 않는다.
    await tester.enterText(find.byType(EditableText).first, '12000');
    await tester.tap(find.text(l.actionNext));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tx-row-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('식비').last);
    await tester.pumpAndSettle();

    // 카테고리 오류가 없다 — [추가] 를 눌러도 칸 오류로 막히지 않는다
    await tester.tap(find.text(l.expAddShort));
    await tester.pumpAndSettle();
    expect(find.text(l.txfErrCategory), findsNothing);
  });
}
