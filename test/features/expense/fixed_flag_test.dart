// 고정 수입·지출 — 거래 입력 시트가 표식을 **보내는** 것을 고정한다.
//
// 고정은 통계가 전체 · 고정 · 변동으로 나눠 보는 분류 표식이다(돈에는 영향 없음). 시트는 그 칸을
// 그리므로 켜고 끄는 대로 늘 싣는다 — 수정에서 키를 빼면 서버가 "유지" 로 읽어 끈 표식이 남는다.
//   ① 새 거래: 기본은 변동(false), 스위치를 켜면 true
//   ② 수정: 고정 거래를 열면 켜져 있고, 그대로 저장하면 고정을 지킨다(Patch.set(true))
//   ③ 수정: 끄면 변동(Patch.set(false))으로 되돌아간다
//   ④ 이체에는 스위치가 없다
//   ⑤ 결제 문자 초안에는 스위치가 없다 — 전용 저장 경로가 표식을 못 싣는다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_switch.dart';

const _category = ExpenseCategory(
  rowId: 11,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  bool? createdFixed = null;
  int created = 0;
  Patch<bool>? updatedFixed;

  @override
  Future<Expense> create({
    required int categoryRowId,
    int? assetRowId,
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
    bool? isFixed,
    bool silent = false,
  }) async {
    created++;
    createdFixed = isFixed;
    return Expense(
      rowId: 100,
      categoryRowId: categoryRowId,
      assetRowId: assetRowId,
      expenseType: expenseType,
      amount: amount,
      expenseDate: expenseDate,
    );
  }

  @override
  Future<Expense> update({
    required int id,
    required int categoryRowId,
    Patch<int> assetRowId = const Patch.keep(),
    required String expenseType,
    required int amount,
    required String expenseDate,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    Patch<int> installmentMonths = const Patch.keep(),
    Patch<double> originalAmount = const Patch.keep(),
    Patch<String> originalCurrency = const Patch.keep(),
    Patch<double> exchangeRate = const Patch.keep(),
    Patch<bool> isFixed = const Patch.keep(),
    List<SplitInput>? splits,
    bool silent = false,
  }) async {
    updatedFixed = isFixed;
    return Expense(
      rowId: id,
      categoryRowId: categoryRowId,
      expenseType: expenseType,
      amount: amount,
      expenseDate: expenseDate,
    );
  }
}

class _FakeSms extends SmsRepository {
  _FakeSms() : super(Dio());
}

Future<void> _open(
  WidgetTester tester, {
  required _FakeRepo repo,
  Expense? edit,
  SmsDraft? draft,
}) async {
  tester.view.physicalSize = const Size(1500, 7000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        smsRepositoryProvider.overrideWith((ref) async => _FakeSms()),
        assetsProvider.overrideWith((ref) async => const []),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAddTxSheet(
                ctx,
                defaultDate: '2026-09-10',
                edit: edit,
                smsDraft: draft,
              ),
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

Finder _submit(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

PSwitch _fixedSwitch(WidgetTester tester) =>
    tester.widget<PSwitch>(find.byType(PSwitch).first);

const _rent = Expense(
  rowId: 7,
  categoryRowId: 11,
  expenseType: 'EXPENSE',
  amount: 700000,
  expenseDate: '2026-09-05T09:00:00',
  merchant: '집주인',
  isFixed: true,
);

void main() {
  testWidgets('새 거래는 변동으로 시작하고, 스위치를 켜면 고정으로 나간다', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo: repo);
    expect(find.byType(PSwitch), findsOneWidget);
    expect(_fixedSwitch(tester).value, isFalse);

    await tester.enterText(find.byType(TextField).first, '700000');
    await tester.pump();
    await tester.tap(find.text('식비').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PSwitch).first);
    await tester.pumpAndSettle();
    expect(_fixedSwitch(tester).value, isTrue);

    await tester.tap(_submit('추가'));
    await tester.pumpAndSettle();

    expect(repo.created, 1);
    expect(repo.createdFixed, isTrue);
  });

  testWidgets('건드리지 않고 저장하면 변동(false)이 나간다 — 키가 빠지지 않는다', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo: repo);
    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.pump();
    await tester.tap(find.text('식비').last);
    await tester.pumpAndSettle();
    await tester.tap(_submit('추가'));
    await tester.pumpAndSettle();

    expect(repo.createdFixed, isFalse);
  });

  testWidgets('고정 거래를 열면 켜져 있고, 그대로 저장하면 고정을 지킨다', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo: repo, edit: _rent);
    expect(_fixedSwitch(tester).value, isTrue);

    await tester.tap(_submit('저장'));
    await tester.pumpAndSettle();

    expect(repo.updatedFixed, isNotNull);
    expect(repo.updatedFixed!.present, isTrue);
    expect(repo.updatedFixed!.value, isTrue);
  });

  testWidgets('고정 거래의 스위치를 끄면 변동으로 되돌아간다', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo: repo, edit: _rent);
    await tester.tap(find.byType(PSwitch).first);
    await tester.pumpAndSettle();
    expect(_fixedSwitch(tester).value, isFalse);

    await tester.tap(_submit('저장'));
    await tester.pumpAndSettle();

    expect(repo.updatedFixed!.value, isFalse);
  });

  testWidgets('이체에는 스위치가 없다 — 내 통장끼리 옮기는 돈이라 합계가 안 달라진다', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo: repo);
    expect(find.byType(PSwitch), findsOneWidget);

    await tester.tap(find.text('이체').first);
    await tester.pumpAndSettle();

    expect(find.byType(PSwitch), findsNothing);
  });
}
