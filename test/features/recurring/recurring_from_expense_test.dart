// 거래 상세 안 반복 단계(I-21 H 44 · 45) — 씨앗 처음 값, 연결된 반복 수정은 반복 값 그대로.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/data/recurring_repository.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';

import 'recurring_test_support.dart';
import '../../support/plain_text.dart';

const _bank = Asset(rowId: 7, assetName: '주거래', assetType: 'BANK_ACCOUNT');

const _expense = Expense(
  rowId: 9,
  expenseType: 'EXPENSE',
  amount: 12000,
  expenseDate: '2026-10-23T12:00:00',
  merchant: '점심',
  categoryRowId: 2,
  assetRowId: 7,
  paymentMethod: 'CARD',
  description: '메모',
);

class _Repo extends RecurringRepository {
  _Repo() : super(Dio());
  Map<String, Object?>? created;
  Map<String, Object?>? updated;

  @override
  Future<void> create({
    int? categoryRowId,
    int? assetRowId,
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    int? sourceExpenseRowId,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    String? executionTime,
    required String startDate,
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,
    bool isFixed = false,
    bool silent = false,
  }) async {
    created = {
      'sourceExpenseRowId': sourceExpenseRowId,
      'assetRowId': assetRowId,
      'startDate': startDate,
      'frequency': frequency,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate,
      'maxOccurrences': maxOccurrences,
      'merchant': merchant,
      'paymentMethod': paymentMethod,
      'amount': amount,
    };
  }

  @override
  Future<void> update({
    required int id,
    int? categoryRowId,
    int? assetRowId,
    int? toAssetRowId,
    int? sourceExpenseRowId,
    int? fee,
    int? interestAmount,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    String? executionTime,
    required String startDate,
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,
    bool isFixed = false,
    bool silent = false,
  }) async {
    updated = {
      'sourceExpenseRowId': sourceExpenseRowId,
      'assetRowId': assetRowId,
      'merchant': merchant,
      'paymentMethod': paymentMethod,
      'description': description,
      'startDate': startDate,
    };
  }
}

Future<_Repo> _open(WidgetTester tester, {RecurringTransaction? linked}) async {
  final repo = _Repo();
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => PBottomSheet.show<void>(
            ctx,
            builder: (_) => RecurringFormFlow(
              expenseSeed: _expense,
              recurring: linked,
              probe: StepProbe(),
              onBack: () {},
              onSaved: () {},
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
    [
      recurringRepositoryProvider.overrideWith((ref) async => repo),
      recurringListProvider.overrideWith(
        (ref) async => linked == null ? const [] : [linked],
      ),
      categoriesProvider.overrideWith((ref) async => const []),
      assetsProvider.overrideWith((ref) async => [_bank]),
    ],
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('씨앗: 거래 값 · 거래한 날 · 매월 그날 · 끝 없음 · sourceExpenseRowId', (
    tester,
  ) async {
    final repo = await _open(tester);
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.widgetWithText(PButton, l.recurringAdd));
    await tester.pumpAndSettle();
    final c = repo.created!;
    expect(c['sourceExpenseRowId'], 9);
    expect(c['assetRowId'], 7);
    expect(c['startDate'], '2026-10-23');
    expect(c['frequency'], 'MONTHLY');
    expect(c['dayOfMonth'], 23);
    expect(c['endDate'], isNull);
    expect(c['maxOccurrences'], isNull);
    expect(c['merchant'], '점심');
    expect(c['paymentMethod'], 'CARD');
    expect(c['amount'], 12000);
  });

  testWidgets('연결된 반복 수정: 빈 계좌 · 결제 수단 · 거래처 · 메모를 거래 값으로 채우지 않는다', (
    tester,
  ) async {
    const linked = RecurringTransaction(
      rowId: 3,
      sourceExpenseRowId: 9,
      expenseType: 'EXPENSE',
      amount: 5000,
      categoryRowId: 2,
      frequency: 'MONTHLY',
      dayOfMonth: 5,
      startDate: '2026-09-05',
      executionTime: '09:00:00',
    );
    final repo = await _open(tester, linked: linked);
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.widgetWithText(PButton, l.actionSave));
    await tester.pumpAndSettle();
    final u = repo.updated!;
    expect(u['assetRowId'], isNull);
    expect(u['paymentMethod'], isNull);
    expect(u['merchant'], isNull);
    expect(u['description'], isNull);
    expect(u['startDate'], '2026-09-05');
    expect(u['sourceExpenseRowId'], 9);
  });
}
