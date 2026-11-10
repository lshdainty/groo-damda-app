// 프리셋 · 반복 폼 — 결제 수단을 고르면 계좌 · 카드 시트에는 그 수단에 맞는 것만 나온다(거래 입력과 같은 규칙 `allowTxAsset`).
// 사용자 결정 2026-11-10: "결제수단 클릭하면 해당 결제수단에 맞는 계좌 카드가 나오도록".
//   ① 수단별 후보(카드 · 현금 · 계좌이체 · 기타)  ② 맞는 게 없으면 "이 결제 수단에 맞는 계좌 · 카드가 없어요."
//   ③ 수단을 바꾸면 안 맞는 계좌 · 카드는 비워지고 맞는 것은 남는다(프리셋 — 반복은 원래 비움)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_edit_dialog.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/data/recurring_repository.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

const _empty = '이 결제 수단에 맞는 계좌 · 카드가 없어요.';

Asset _a(int id, String name, String type) =>
    Asset(rowId: id, assetName: name, assetType: type);
final _bank = _a(1, '주거래통장', 'BANK_ACCOUNT');
final _savings = _a(2, '비상적금', 'SAVINGS');
final _cash = _a(3, '지갑현금', 'CASH');
final _credit = _a(4, '신용카드A', 'CREDIT_CARD');
final _check = _a(5, '체크카드B', 'CHECK_CARD');
final _all = [_bank, _savings, _cash, _credit, _check];

Finder _t(String s) => find.byWidgetPredicate(
  (w) =>
      w is Text && plainOf(w.data ?? w.textSpan!.toPlainText()) == plainOf(s),
);

enum _Form { preset, recurring }

Future<void> _open(
  WidgetTester tester,
  _Form form, {
  List<Asset>? assets,
}) async {
  tester.view.physicalSize = const Size(1170, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith((ref) async => []),
        presetRepositoryProvider.overrideWith(
          (ref) async => PresetRepository(Dio()),
        ),
        recurringListProvider.overrideWith((ref) async => const []),
        recurringRepositoryProvider.overrideWith(
          (ref) async => RecurringRepository(Dio()),
        ),
        categoriesProvider.overrideWith(
          (ref) async => const [
            ExpenseCategory(
              rowId: 1,
              categoryName: '식비',
              expenseType: 'EXPENSE',
              sortOrder: 0,
              icon: 'utensils',
              color: '#2c70bf',
            ),
          ],
        ),
        assetsProvider.overrideWith((ref) async => assets ?? _all),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => form == _Form.preset
                  ? showPresetEditDialog(ctx)
                  : showRecurringFormSheet(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

Future<void> _pickMethod(WidgetTester tester, String label) async {
  await tester.tap(_t('결제 수단').first);
  await tester.pumpAndSettle();
  await tester.tap(_t(label).last);
  await tester.pumpAndSettle();
}

Future<List<String>> _candidates(WidgetTester tester) async {
  await tester.tap(_t('계좌 · 카드').first);
  await tester.pumpAndSettle();
  return [
    for (final a in _all)
      if (_t(a.assetName).evaluate().isNotEmpty) a.assetName,
  ];
}

void main() {
  for (final form in _Form.values) {
    final name = form == _Form.preset ? '프리셋' : '반복';
    testWidgets('$name — 결제 수단 줄이 계좌 · 카드 줄 위에 있다', (tester) async {
      await _open(tester, form);
      final m = tester.getTopLeft(_t('결제 수단').first).dy;
      final a = tester.getTopLeft(_t('계좌 · 카드').first).dy;
      expect(m < a, isTrue);
    });

    testWidgets('$name — 수단별 후보', (tester) async {
      final cases = <String, List<String>>{
        '카드': ['신용카드A', '체크카드B'],
        '현금': ['지갑현금'],
        '계좌이체': ['주거래통장'],
        '기타': ['주거래통장', '지갑현금', '신용카드A', '체크카드B'],
      };
      for (final e in cases.entries) {
        await _open(tester, form);
        await _pickMethod(tester, e.key);
        expect(await _candidates(tester), e.value, reason: '$name ${e.key}');
        expect(_t(_empty), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('$name — 맞는 게 없으면 안내, 수단이 없으면 안내 없음', (tester) async {
      await _open(tester, form, assets: [_bank]);
      await _pickMethod(tester, '카드');
      expect(await _candidates(tester), isEmpty);
      expect(_t(_empty), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await _pickMethod(tester, '결제 수단 없음');
      expect(await _candidates(tester), ['주거래통장']);
      expect(_t(_empty), findsNothing);
    });
  }

  testWidgets('프리셋 — 수단을 바꾸면 안 맞는 계좌 · 카드는 비워지고 맞는 것은 남는다', (tester) async {
    await _open(tester, _Form.preset);
    await tester.tap(_t('계좌 · 카드').first);
    await tester.pumpAndSettle();
    await tester.tap(_t('주거래통장').last);
    await tester.pumpAndSettle();
    expect(_t('주거래통장'), findsOneWidget);

    await _pickMethod(tester, '카드'); // 통장은 카드에 안 맞는다
    expect(_t('주거래통장'), findsNothing);

    await tester.tap(_t('계좌 · 카드').first);
    await tester.pumpAndSettle();
    await tester.tap(_t('신용카드A').last);
    await tester.pumpAndSettle();
    await _pickMethod(tester, '기타'); // 기타는 가리지 않는다
    expect(_t('신용카드A'), findsOneWidget);
    await _pickMethod(tester, '현금'); // 현금에 카드는 안 맞는다
    expect(_t('신용카드A'), findsNothing);
  });
}
