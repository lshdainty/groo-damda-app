// 프리셋 수정 요청의 **실제 본문** — dio 어댑터로 나가는 JSON 을 잡는다. 가짜 저장소는 `'key': ?value`(null 이면 키를 뺀다)가
// 키를 실었는지를 못 본다.
//  - 이체로 바꿔 저장하면 본문에 `categoryRowId: null` 이 **있어야** 한다. 서버는 키가 없으면 유지로 읽어(ExpenseTemplateServiceImpl)
//    옛 카테고리와 TRANSFER 가 짝이 안 맞아 400 이다.
//  - 자산을 받기 전에 저장해도 읽어 온 이자는 그대로 나간다.
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

import '../../support/capture_adapter.dart';

const _food = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
);
const _bank = Asset(rowId: 7, assetName: '주거래', assetType: 'BANK_ACCOUNT');
const _loan = Asset(rowId: 9, assetName: '대출', assetType: 'LOAN');
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

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  test('저장소 — 수정 본문은 카테고리 키를 명시 null 로도 싣는다', () async {
    final cap = CaptureAdapter();
    final repo = PresetRepository(Dio()..httpClientAdapter = cap);
    await repo.update(
      id: 5,
      templateName: '점심',
      categoryRowId: const Patch.set(null),
      expenseType: 'TRANSFER',
    );
    expect(cap.lastBody!.containsKey('categoryRowId'), isTrue);
    expect(cap.lastBody!['categoryRowId'], isNull);
    await repo.update(id: 5, templateName: '점심', expenseType: 'EXPENSE');
    expect(
      cap.lastBody!.containsKey('categoryRowId'),
      isFalse,
      reason: '안 건드리면 유지',
    );
  });

  Future<CaptureAdapter> open(
    WidgetTester tester,
    ExpenseTemplate edit, {
    Future<List<Asset>>? assets,
  }) async {
    final cap = CaptureAdapter();
    final repo = PresetRepository(Dio()..httpClientAdapter = cap);
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presetListProvider.overrideWith((ref) async => [edit]),
          presetRepositoryProvider.overrideWith((ref) async => repo),
          categoriesProvider.overrideWith((ref) async => [_food]),
          assetsProvider.overrideWith(
            (ref) => assets ?? Future.value([_bank, _loan]),
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showPresetEditDialog(ctx, edit: edit),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return cap;
  }

  Finder save() => find
      .ancestor(of: find.text(l.actionSave), matching: find.byType(PButton))
      .last;

  testWidgets('이체 프리셋을 저장하면 본문에 categoryRowId: null 이 있다', (tester) async {
    final cap = await open(tester, _loanPreset);
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(cap.lastBody!.containsKey('categoryRowId'), isTrue);
    expect(cap.lastBody!['categoryRowId'], isNull);
  });

  testWidgets('자산을 받기 전에 저장해도 본문 이자는 읽어 온 그대로', (tester) async {
    final cap = await open(
      tester,
      _loanPreset,
      assets: Completer<List<Asset>>().future,
    );
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(cap.lastBody!['interestAmount'], 20000);
  });

  testWidgets('자산을 받은 뒤 대출이 아닌 받는 계좌면 이자는 null 로 나간다(지금 규칙)', (tester) async {
    final cap = await open(
      tester,
      const ExpenseTemplate(
        rowId: 6,
        templateName: '이동',
        expenseType: 'TRANSFER',
        assetRowId: 7,
        toAssetRowId: 7,
        amount: 1000,
        lockAmount: 'Y',
        interestAmount: 20000,
      ),
    );
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(cap.lastBody!.containsKey('interestAmount'), isTrue);
    expect(cap.lastBody!['interestAmount'], isNull);
  });
}
