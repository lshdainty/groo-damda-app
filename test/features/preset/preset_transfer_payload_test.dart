// 이체 프리셋이 **보내는 것**을 고정한다.
//
// 이체 칸(받는 계좌·수수료·이자)과 지출·수입 칸(카테고리·거래처·결제 수단)은 서로
// 배타다 — 섞여 실리면 서버가 400 으로 거절한다(`RecurringTransferValidator`).
// 그래서 두 방향을 함께 잰다.
//
// - 이체로 저장하면 받는 계좌·수수료가 실리고 카테고리는 안 실린다.
// - 이체를 지출로 바꿔 저장하면 이체 칸이 **명시적 null** 로 나가 지워진다.
//   키를 빼면 서버가 "안 고침" 으로 읽어, 지출인데 받는 계좌가 남은 행이 된다.
//
// 카드가 이체 상대 후보에 없다는 것도 여기서 잠근다 — 화면에서 못 고르게 하는 것과
// 서버가 거절하는 것은 별개고(옛 앱·API 직접 호출), 둘 다 있어야 한다.
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
import 'package:groo_damda_app/shared/widgets/p_select.dart';

const _category = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _bank = Asset(
  rowId: 7,
  assetName: '주거래',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(
  rowId: 8,
  assetName: '청약',
  assetType: 'SAVINGS',
  institution: '신한',
);

/// 이체 후보에서 빠져야 하는 카드.
const _card = Asset(
  rowId: 9,
  assetName: '체크',
  assetType: 'CHECK_CARD',
  institution: '신한',
);

/// 이미 이체로 저장된 프리셋 — 여기서 종류를 지출로 되돌린다.
const _transferPreset = ExpenseTemplate(
  rowId: 5,
  templateName: '적금 이체',
  expenseType: 'TRANSFER',
  assetRowId: 7,
  toAssetRowId: 8,
  fee: 500,
);

class _CapturingRepo extends PresetRepository {
  _CapturingRepo() : super(Dio());

  bool called = false;
  Map<String, Object?> created = {};
  Patch<int> toAssetRowId = const Patch.keep();
  Patch<int> fee = const Patch.keep();
  int? updatedCategoryRowId;
  String? updatedType;

  @override
  Future<ExpenseTemplate> create({
    required String templateName,
    int? categoryRowId,
    int? assetRowId,
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    required String expenseType,
    int? amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? sortOrder,
    bool lockAmount = false,
    bool isFixed = false,
  }) async {
    called = true;
    created = {
      'categoryRowId': categoryRowId,
      'assetRowId': assetRowId,
      'toAssetRowId': toAssetRowId,
      'fee': fee,
      'expenseType': expenseType,
      'merchant': merchant,
      'paymentMethod': paymentMethod,
    };
    return _transferPreset;
  }

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
    called = true;
    this.toAssetRowId = toAssetRowId;
    this.fee = fee;
    updatedCategoryRowId = categoryRowId.value;
    updatedType = expenseType;
    return _transferPreset;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _open(WidgetTester tester, ExpenseTemplate? edit) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith(
          (ref) async => const <ExpenseTemplate>[],
        ),
        presetRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_bank, _savings, _card]),
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
  return repo;
}

Future<void> _pickSelect(WidgetTester tester, int index, String label) async {
  await tester.tap(find.byType(PSelect<int>).at(index));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('이체로 저장하면 받는 계좌·수수료가 실리고 카테고리는 안 실린다', (tester) async {
    final repo = await _open(tester, null);
    await tester.tap(find.text(l.expTypeTransfer));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l.expPresetNamePlaceholder), '적금 이체');
    await tester.pumpAndSettle();
    await _pickSelect(tester, 0, '신한 · 주거래');
    await _pickSelect(tester, 1, '신한 · 청약');
    await tester.enterText(_field('0'), '500');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.presetSubmitAdd));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(repo.created['expenseType'], 'TRANSFER');
    expect(repo.created['assetRowId'], 7);
    expect(repo.created['toAssetRowId'], 8);
    expect(repo.created['fee'], 500);
    // 이체에는 카테고리·거래처·결제 수단이 없다 — 실려 가면 서버가 400 이다.
    expect(repo.created['categoryRowId'], isNull);
    expect(repo.created['merchant'], isNull);
    expect(repo.created['paymentMethod'], isNull);
  });

  testWidgets('카드는 이체 상대 후보에 없다', (tester) async {
    await _open(tester, null);
    await tester.tap(find.text(l.expTypeTransfer));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PSelect<int>).first);
    await tester.pumpAndSettle();

    expect(find.text('신한 · 주거래'), findsWidgets);
    expect(find.text('신한 · 청약'), findsWidgets);
    expect(find.text('신한 · 체크'), findsNothing);
  });

  testWidgets('이체를 지출로 바꿔 저장하면 이체 칸이 명시적 null 로 지워진다', (tester) async {
    final repo = await _open(tester, _transferPreset);
    await tester.tap(find.text(l.expTypeExpense));
    await tester.pumpAndSettle();
    // 지출에는 카테고리가 필요하다 — 타일을 눌러 고른다.
    await tester.tap(find.text('식비').last);
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue);
    expect(repo.updatedType, 'EXPENSE');
    expect(
      repo.toAssetRowId.present,
      isTrue,
      reason: '키가 빠지면 서버가 옛 받는 계좌를 지킨다 — 지출인데 이체 칸이 남는다',
    );
    expect(repo.toAssetRowId.value, isNull);
    expect(repo.fee.present, isTrue);
    expect(repo.fee.value, isNull);
    expect(repo.updatedCategoryRowId, 1);
  });
}
