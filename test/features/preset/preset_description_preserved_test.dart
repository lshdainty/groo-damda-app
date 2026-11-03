// 프리셋 메모(description)는 **화면에 칸이 있고**, 그 칸이 서버 값과 왕복한다 (D2).
//
// 종전엔 편집 시트에 메모 칸이 없었다. 서버 `ExpenseTemplate.updateTemplate` 은 이 칸을
// 무조건 대입해서, 이름만 고쳐 저장해도 메모가 null 로 덮였다 — 그래서 화면이 읽은 값을
// 그대로 되돌려 보내는 임시 처방을 썼다(#326). 되살릴 입력칸이 웹·앱 어디에도 없었기
// 때문이다.
//
// 이제 칸이 생겼으므로 처방을 걷고 원래 규칙으로 돌린다. 여기서 잠그는 것은 셋이다.
//   ① 편집 시트를 열면 서버 메모가 칸에 **채워져 있다** — 안 채우면 저장 한 번에
//      빈 값이 실려 지워진다. 칸이 생겨서 더 위험해진 자리다
//   ② 고쳐 쓰면 고친 값이 실린다
//   ③ 새 프리셋도 적어 넣은 메모를 싣는다 — 종전 생성 경로는 칸이 없어 늘 비었다
//
// 앱에서 이 메모를 실제로 쓴다: 프리셋을 불러오면 거래 메모 칸에 그대로 들어간다
// (`_applyPreset` 의 `memoCtrl.text = p.description`).
//
// 비우면 명시적 null 이 실리는 쪽은 `preset_clear_payload_test.dart` 가 잰다.
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

const _category = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

/// 웹에서 메모를 적어 둔 프리셋.
const _withMemo = ExpenseTemplate(
  rowId: 5,
  templateName: '점심 도시락',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
  description: '회사 근처 김밥천국',
);

/// 메모가 없는 프리셋 — 없는 값을 억지로 만들어 보내지 않는지 본다.
const _withoutMemo = ExpenseTemplate(
  rowId: 6,
  templateName: '커피',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
);

class _CapturingRepo extends PresetRepository {
  _CapturingRepo() : super(Dio());

  bool called = false;
  Patch<String> description = const Patch.keep();
  String? createdDescription;

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
    this.description = description;
    return _withMemo;
  }

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
    createdDescription = description;
    return _withMemo;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _open(WidgetTester tester, ExpenseTemplate? edit) async {
  final repo = _CapturingRepo();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith(
          (ref) async => [_withMemo, _withoutMemo],
        ),
        presetRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => <Asset>[]),
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

  testWidgets('편집 시트를 열면 서버 메모가 칸에 채워져 있다', (tester) async {
    await _open(tester, _withMemo);

    expect(
      find.widgetWithText(TextField, '회사 근처 김밥천국'),
      findsOneWidget,
      reason: '안 채우면 이름만 고쳐 저장해도 빈 값이 실려 메모가 지워진다',
    );
  });

  testWidgets('이름만 고쳐 저장해도 메모가 그대로 실린다', (tester) async {
    final repo = await _open(tester, _withMemo);
    await tester.enterText(_field(l.expPresetNamePlaceholder), '점심');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(repo.description.value, '회사 근처 김밥천국');
  });

  testWidgets('메모를 고쳐 쓰면 고친 값이 실린다', (tester) async {
    final repo = await _open(tester, _withMemo);
    await tester.enterText(_field(l.expMemoPlaceholder), '회사 앞 분식집');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다');
    expect(repo.description.present, isTrue);
    expect(repo.description.value, '회사 앞 분식집');
  });

  testWidgets('원래 메모가 없으면 없는 채로 둔다', (tester) async {
    final repo = await _open(tester, _withoutMemo);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다');
    expect(repo.description.value, isNull);
  });

  testWidgets('새 프리셋도 적어 넣은 메모를 싣는다', (tester) async {
    final repo = await _open(tester, null);
    await tester.enterText(_field(l.expPresetNamePlaceholder), '점심');
    await tester.pumpAndSettle();
    await tester.enterText(_field(l.expMemoPlaceholder), '회사 앞 분식집');
    await tester.pumpAndSettle();
    await tester.tap(find.text('식비').last);
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '생성이 안 불렸다');
    expect(
      repo.createdDescription,
      '회사 앞 분식집',
      reason: '칸을 만들어 놓고 안 실으면 적은 메모가 저장 즉시 사라진다',
    );
  });
}
