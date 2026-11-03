// 자산을 받기 전에 저장을 눌러도 읽어 온 이체 이자가 지워지지 않는다(웹 20-2 후속과 같은 순서 문제).
// 종전엔 `_showInterest` 가 자산이 없으면 false 라 저장 본문이 `interestAmount: null` 을 실었다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';

const _expensePreset = ExpenseTemplate(
  rowId: 5,
  templateName: '점심',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
);

const _loanPreset = ExpenseTemplate(
  rowId: 6,
  templateName: '대출 상환',
  expenseType: 'TRANSFER',
  assetRowId: 7,
  toAssetRowId: 9,
  amount: 300000,
  lockAmount: 'Y',
  interestAmount: 20000,
);

class _Repo extends PresetRepository {
  _Repo() : super(Dio());
  Patch<int> interest = const Patch.keep();
  int? categorySent;
  bool called = false;

  @override
  Future<ExpenseTemplate> update({
    required int id,
    required String templateName,
    Patch<int> categoryRowId = const Patch.keep(),
    Patch<int> assetRowId = const Patch.keep(),
    Patch<int> toAssetRowId = const Patch.keep(),
    Patch<int> fee = const Patch.keep(),
    Patch<int> interestAmount = const Patch.keep(),
    required String expenseType,
    int? amount,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    bool lockAmount = false,
    bool isFixed = false,
  }) async {
    interest = interestAmount;
    categorySent = categoryRowId.value;
    called = true;
    return _loanPreset;
  }
}

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  testWidgets('자산이 오기 전에 저장해도 이자가 그대로 실린다', (tester) async {
    final repo = _Repo();
    final never = Completer<List<Asset>>();
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presetListProvider.overrideWith((ref) async => [_loanPreset]),
          presetRepositoryProvider.overrideWith((ref) async => repo),
          categoriesProvider.overrideWith((ref) async => []),
          assetsProvider.overrideWith((ref) => never.future),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showPresetEditDialog(ctx, edit: _loanPreset),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(of: find.text(l.actionSave), matching: find.byType(PButton))
          .last,
    );
    await tester.pumpAndSettle();
    expect(repo.interest.present, isTrue);
    expect(
      repo.interest.value,
      20000,
      reason: '자산을 모르는 채로 이자를 null 로 실으면 저장된 이자가 지워진다',
    );
  });

  Future<_Repo> openExpense(
    WidgetTester tester,
    Future<List<ExpenseCategory>> categories,
  ) async {
    final repo = _Repo();
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presetListProvider.overrideWith((ref) async => [_expensePreset]),
          presetRepositoryProvider.overrideWith((ref) async => repo),
          categoriesProvider.overrideWith((ref) => categories),
          assetsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () =>
                    showPresetEditDialog(ctx, edit: _expensePreset),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(of: find.text(l.actionSave), matching: find.byType(PButton))
          .last,
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('카테고리를 받기 전에는 읽어 온 카테고리가 그대로 실린다', (tester) async {
    final repo = await openExpense(
      tester,
      Completer<List<ExpenseCategory>>().future,
    );
    expect(repo.called, isTrue);
    expect(repo.categorySent, 1);
  });

  testWidgets('카테고리를 받았는데 목록에 없으면(지운 카테고리) 지운 id 가 나가지 않는다', (tester) async {
    final repo = await openExpense(
      tester,
      Future.value(const [
        ExpenseCategory(
          rowId: 2,
          categoryName: '교통',
          expenseType: 'EXPENSE',
          sortOrder: 0,
        ),
      ]),
    );
    expect(repo.called, isFalse, reason: '카테고리를 다시 골라야 저장된다');
  });
}
