// 고정 금액을 껐다가 다시 켜면 **이자 칸이 비어 있어야 한다**(#175).
//
// 이자는 금액을 따라간다(2026-09-15 결정) — 고정을 끄면 이자도 안 저장한다. 저장하는
// 값은 처음부터 맞았지만(payload 가 null), 컨트롤러를 안 비워서 칸만 감춰졌다가 다시
// 켜면 **옛 이자가 되살아났다.** 화면에 지난달 이자가 떠 있으면 사용자는 그 값이
// 저장된 줄 안다. 웹은 같은 자리에서 비운다.
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
import 'package:groo_damda_app/shared/widgets/p_checkbox.dart';

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
  assetName: 'QA예금',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _loan = Asset(
  rowId: 8,
  assetName: 'QA대출',
  assetType: 'LOAN',
  institution: '신한',
);

/// 고정 금액 + 이자가 붙은 대출 상환 프리셋 — 여기서 고정을 껐다 켠다.
const _preset = ExpenseTemplate(
  rowId: 5,
  templateName: '대출상환',
  expenseType: 'TRANSFER',
  assetRowId: 7,
  toAssetRowId: 8,
  fee: 500,
  interestAmount: 20000,
  amount: 300000,
  lockAmount: 'Y',
);

class _CapturingRepo extends PresetRepository {
  _CapturingRepo() : super(Dio());
  Patch<int> interestAmount = const Patch.keep();

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
    this.interestAmount = interestAmount;
    return _preset;
  }
}

Future<void> _open(WidgetTester tester) async {
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith((ref) async => [_preset]),
        presetRepositoryProvider.overrideWith((ref) async => _CapturingRepo()),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_bank, _loan]),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showPresetEditDialog(ctx, edit: _preset),
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

Future<void> _toggleLock(WidgetTester tester) async {
  await tester.tap(find.byType(PCheckbox));
  await tester.pumpAndSettle();
}

/// '0' 을 힌트로 쓰는 입력들 — 이 폼에서는 순서가 정해져 있다.
///
/// 이자가 보일 때  [수수료, 이자, 고정 금액]
/// 안 보일 때      [수수료, 고정 금액]
///
/// 마지막은 항상 고정 금액 카드의 금액 칸이라 `last` 로 이자를 집으면 안 된다.
List<TextField> _zeroHintFields(WidgetTester tester) => tester
    .widgetList<TextField>(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '0',
      ),
    )
    .toList();

/// 이자 칸의 지금 값 — 칸이 없으면 null.
String? _interestText(WidgetTester tester, AppLocalizations l) {
  if (find.text(l.expInterest).evaluate().isEmpty) return null;
  final fields = _zeroHintFields(tester);
  expect(fields, hasLength(3), reason: '수수료·이자·고정 금액 셋이어야 한다');
  return fields[1].controller?.text;
}

/// 수수료 칸의 지금 값 — 이자가 보이든 말든 늘 첫째다.
String? _feeText(WidgetTester tester) =>
    _zeroHintFields(tester).first.controller?.text;

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('고정을 껐다 다시 켜면 이자 칸이 비어 있다', (tester) async {
    await _open(tester);

    // 처음엔 고정 금액이 켜져 있고 이자가 보인다.
    expect(_interestText(tester, l), '20000');

    await _toggleLock(tester); // 끔 — 이자 칸이 사라진다
    expect(find.text(l.expInterest), findsNothing);

    await _toggleLock(tester); // 다시 켬
    expect(
      _interestText(tester, l),
      '',
      reason: '옛 이자가 되살아나면 사용자는 그 값이 저장된 줄 안다',
    );
  });

  testWidgets('반대편 — 수수료는 고정을 꺼도 남는다(계좌 짝의 성질이다)', (tester) async {
    await _open(tester);
    await _toggleLock(tester);

    expect(_feeText(tester), '500');
  });
}
