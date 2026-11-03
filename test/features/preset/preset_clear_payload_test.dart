// 프리셋 편집 시트에서 **칸을 비우면 실제로 지워진다** (회귀 마무리 P2).
//
// 서버가 프리셋 수정 본문을 `Optional` 로 읽기 시작하면서(desk-back #325) 뜻이 셋으로
// 갈렸다 — 키가 없으면 유지, `"key": null` 이면 지움, 값이 오면 교체. 앱은 본문을
// Dart 의 널 인지 맵 엔트리(`'key': ?value`)로 만들어 **null 인 칸을 키째 뺐다.**
// 그래서 계좌·결제 수단을 '선택 안 함' 으로 되돌리거나 거래처를 지우고 저장해도
// 다시 열면 옛 값이 그대로 있었다.
//
// 리포지토리 본문은 `put_clear_payload_test.dart` 가 잰다. 여기서는 **시트를 실제로
// 조작해서**(입력 지우기 · '선택 안 함' 고르기) 그 본문이 나가는지까지 태운다 —
// 에뮬레이터를 쓸 수 없으므로(QA #23) 이게 "무엇을 보내는가" 의 마지막 잠금이다.
//
// 메모(description)도 여기 속한다. 종전엔 시트에 칸이 없어 읽어 온 값을 그대로
// 되돌려 보냈는데(#326), 칸이 생기면서(D2) 같은 규칙으로 들어왔다 — 비우면 지워지고
// 안 건드리면 그대로 남는다. 칸이 생겼는데 되돌려 보내기만 하면 지울 방법이 없다.
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

/// 자식이 없는 카테고리 하나만 둔다 — 자식이 있으면 세부 카테고리 select 가 하나 더
/// 생겨 `PSelect<int>` 가 둘이 된다.
const _category = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _asset = Asset(
  rowId: 7,
  assetName: '주거래',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);

/// 세 칸이 다 채워진 프리셋 — 여기서 하나씩 비운다.
const _filled = ExpenseTemplate(
  rowId: 5,
  templateName: '점심 도시락',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
  assetRowId: 7,
  merchant: '김밥천국',
  paymentMethod: 'CARD',
  description: '회사 근처 김밥천국',
);

/// 화면이 넘긴 인자를 그대로 잡아 둔다 — 값뿐 아니라 "키를 실었는가" 까지 본다.
class _CapturingRepo extends PresetRepository {
  _CapturingRepo() : super(Dio());

  bool called = false;
  Patch<int> assetRowId = const Patch.keep();
  Patch<String> merchant = const Patch.keep();
  Patch<String> paymentMethod = const Patch.keep();
  Patch<String> description = const Patch.keep();

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
    this.assetRowId = assetRowId;
    this.merchant = merchant;
    this.paymentMethod = paymentMethod;
    this.description = description;
    return _filled;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

/// select 를 펼친다 — 항목은 OverlayPortal 안에 뜬다.
Future<void> _openSelect(WidgetTester tester, Finder select) async {
  await tester.tap(select);
  await tester.pumpAndSettle();
}

Future<_CapturingRepo> _open(WidgetTester tester, ExpenseTemplate edit) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith((ref) async => [_filled]),
        presetRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_asset]),
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

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('거래처를 지우면 merchant 가 명시적 null 로 실린다', (tester) async {
    final repo = await _open(tester, _filled);
    await tester.enterText(_field(l.presetMerchantPlaceholder), '');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(
      repo.merchant.present,
      isTrue,
      reason: 'merchant 키가 빠지면 서버가 옛 거래처를 지킨다 — 비운 게 안 지워진다',
    );
    expect(repo.merchant.value, isNull);
  });

  testWidgets("결제 수단에서 '선택 안 함' 을 고르면 명시적 null 로 실린다", (tester) async {
    final repo = await _open(tester, _filled);
    await _openSelect(tester, find.byType(PSelect<String>));
    await tester.tap(find.text(l.presetSelectNone).last);
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다');
    expect(
      repo.paymentMethod.present,
      isTrue,
      reason: 'paymentMethod 키가 빠지면 옛 결제 수단이 남는다',
    );
    expect(repo.paymentMethod.value, isNull);
  });

  testWidgets("계좌에서 '선택 안 함' 을 고르면 명시적 null 로 실린다", (tester) async {
    final repo = await _open(tester, _filled);
    // 자식 없는 카테고리 하나뿐이라 `PSelect<int>` 는 계좌·카드 하나다.
    await _openSelect(tester, find.byType(PSelect<int>));
    await tester.tap(find.text(l.presetSelectNone).last);
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다');
    expect(
      repo.assetRowId.present,
      isTrue,
      reason: 'assetRowId 키가 빠지면 옛 계좌가 그대로 붙어 있다',
    );
    expect(repo.assetRowId.value, isNull);
  });

  testWidgets('메모를 지우면 description 이 명시적 null 로 실린다', (tester) async {
    final repo = await _open(tester, _filled);
    await tester.enterText(_field(l.expMemoPlaceholder), '');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다');
    expect(
      repo.description.present,
      isTrue,
      reason: 'description 키가 빠지면 지운 메모가 그대로 남는다 — 칸만 비고 값은 산다',
    );
    expect(repo.description.value, isNull);
  });

  testWidgets('안 건드린 칸은 지금 값이 그대로 실린다', (tester) async {
    final repo = await _open(tester, _filled);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.merchant.value, '김밥천국');
    expect(repo.paymentMethod.value, 'CARD');
    expect(repo.assetRowId.value, 7);
    // 다른 칸을 비우는 저장이 메모까지 지우면 안 된다 — 칸이 생기기 전의 사고다.
    expect(repo.description.value, '회사 근처 김밥천국');
  });

  // 거래처만 비운 저장이 메모까지 쓸어 가지 않는지 — 칸이 생겨도 남는 위험이다.
  testWidgets('거래처만 비워도 메모는 그대로 실린다', (tester) async {
    final repo = await _open(tester, _filled);
    await tester.enterText(_field(l.presetMerchantPlaceholder), '');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.merchant.value, isNull);
    expect(repo.description.value, '회사 근처 김밥천국');
  });
}
