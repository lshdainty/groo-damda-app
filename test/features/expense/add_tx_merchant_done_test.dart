// 거래처 칸 키보드 ✓ 는 저장하지 않고 키보드만 내린다(사용자 결정 2026-11-11, 시험 DA-03 관찰).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

/// 망을 타지 않는 저장소 — 만들기 요청을 적어 두고, 저장 뒤 다시 받는 그 달 목록은 빈 목록.
class _Repo extends ExpenseRepository {
  _Repo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));
  final created = <int?>[];

  @override
  Future<List<Expense>> list({
    String? startDate,
    String? endDate,
    int? categoryId,
    int? assetId,
    String? expenseType,
  }) async => const [];

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
    created.add(assetRowId);
    return Expense(
      rowId: 1,
      categoryRowId: categoryRowId,
      expenseType: expenseType,
      amount: amount,
      expenseDate: expenseDate,
    );
  }
}

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

Future<AppLocalizations> _open(WidgetTester tester, _Repo repo) async {
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
        // 저장소를 덮지 않으면 진짜 망을 타 응답이 오지 않는다(저장 뒤 그 달 목록을 다시 받는다 — 1a9d9de7)
        expenseRepositoryProvider.overrideWith((ref) async => repo),
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
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('ko'));
}

void main() {
  testWidgets('거래처 칸에서 키보드 ✓ — 저장 요청이 나가지 않고 초점만 풀린다', (tester) async {
    final repo = _Repo();
    final l = await _open(tester, repo);
    await tester.enterText(find.byType(EditableText).first, '12000');
    await tester.tap(findText(l.actionNext));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tx-row-category')));
    await tester.pumpAndSettle();
    await tester.tap(findText('식비').last);
    await tester.pumpAndSettle();

    final merchant = find.byType(EditableText).first;
    await tester.tap(merchant);
    await tester.pump();
    await tester.enterText(merchant, '가게');
    await tester.pump();
    expect(tester.widget<EditableText>(merchant).focusNode.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(repo.created, isEmpty, reason: '✓ 는 저장하지 않는다');
    expect(tester.widget<EditableText>(merchant).focusNode.hasFocus, isFalse);

    // 저장은 [추가] 로
    await tester.tap(findText(l.expAddShort));
    await tester.pumpAndSettle();
    expect(repo.created, [null]);
  });
}
