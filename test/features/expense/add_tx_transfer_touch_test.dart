// 이체를 프리셋으로 채워 저장하면 **사용 기록이 올라야 한다**(#174).
//
// `touch` 가 지출·수입 저장 꼬리에만 있었고, TRANSFER 분기는 그 앞에서 `return` 해
// 닿지 못했다. 프리셋 목록이 "사용 많은 순" 정렬이라 이체 프리셋만 영영 0 에 머물렀다
// — 쓸수록 아래로 밀리니 주 용도(매달 이자 이체)가 제일 불편해진다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
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

const _bank = Asset(
  rowId: 1,
  assetName: 'QA예금',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(
  rowId: 2,
  assetName: 'QA적금',
  assetType: 'SAVINGS',
  institution: '신한',
);

/// 금액 없는 이체 프리셋 — 칩으로 채우면 계좌·수수료만 들어오고 금액은 비어 있다.
const _preset = ExpenseTemplate(
  rowId: 77,
  templateName: '적금이체',
  expenseType: 'TRANSFER',
  assetRowId: 1,
  toAssetRowId: 2,
  fee: 500,
  lockAmount: 'N',
);

class _FakeAssetRepo extends AssetRepository {
  _FakeAssetRepo() : super(Dio());
  bool created = false;

  @override
  Future<void> createTransfer({
    required int fromAssetRowId,
    required int toAssetRowId,
    required int amount,
    int? fee,
    int? interestAmount,
    String? description,
    required String transferDate,
    bool silent = false,
  }) async {
    created = true;
  }
}

class _CapturingPresetRepo extends PresetRepository {
  _CapturingPresetRepo() : super(Dio());
  final List<int> touched = [];

  @override
  Future<void> touch(int id) async => touched.add(id);
}

Future<(_FakeAssetRepo, _CapturingPresetRepo)> _open(
  WidgetTester tester,
) async {
  final assetRepo = _FakeAssetRepo();
  final presetRepo = _CapturingPresetRepo();
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_bank, _savings]),
        presetListProvider.overrideWith((ref) async => [_preset]),
        assetRepositoryProvider.overrideWith((ref) async => assetRepo),
        presetRepositoryProvider.overrideWith((ref) async => presetRepo),
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
  return (assetRepo, presetRepo);
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('이체 칩으로 채워 저장하면 사용 기록이 오른다', (tester) async {
    final (assetRepo, presetRepo) = await _open(tester);

    await tester.tap(find.text(l.expTypeTransfer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적금이체'));
    await tester.pumpAndSettle();

    // 이 프리셋은 금액이 없다 — 1단계에 남아 금액 칸에 이번 달 금액을 적고 [다음] → [추가]
    await tester.enterText(find.byType(EditableText).first, '12345');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.actionNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.expAddShort).last);
    await tester.pumpAndSettle();

    expect(assetRepo.created, isTrue, reason: '이체가 저장되지 않았다');
    expect(presetRepo.touched, [77]);
  });
}
