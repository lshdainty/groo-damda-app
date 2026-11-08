// 더치페이 실제 DutchStepFlow 를 시트로 띄우는 시험 하네스 — 가짜는 override 넷 + Expense 한 건.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/data/dutch_pay_repository.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_step.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';
import 'plain_text.dart';

typedef DutchRow = ({String? name, int? userRowId, int amount, bool isPayer});

class DutchMe extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
    rowId: 1,
    userId: 'me',
    userName: '나',
    userEmail: 'me@example.com',
  );
}

class DutchFakeRepo extends DutchPayRepository {
  DutchFakeRepo() : super(Dio());
  List<DutchRow>? sent;

  @override
  Future<DutchPay> create({
    required String title,
    String? description,
    required int totalAmount,
    String? splitMethod,
    String? dutchPayDate,
    int? sourceExpenseRowId,
    required List<DutchRow> participants,
    bool silent = false,
  }) async {
    sent = participants;
    return DutchPay(rowId: 1, title: title, totalAmount: totalAmount);
  }
}

const dutchTestExpense = Expense(
  rowId: 9,
  expenseType: 'EXPENSE',
  amount: 3000,
  expenseDate: '2026-09-25T12:00:00',
  merchant: '점심',
);

Future<(DutchFakeRepo, AppLocalizations)> openDutchFlow(
  WidgetTester tester, {
  Size size = const Size(1200, 3000),
  double textScale = 1.0,
}) async {
  final repo = DutchFakeRepo();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(DutchMe.new),
        categoriesProvider.overrideWith((ref) async => const []),
        dutchPayRepositoryProvider.overrideWith((ref) async => repo),
        // 만든 뒤 목록을 다시 받을 때까지 기다린다(7bd39865) — 가짜 저장소에 list 가 없어 덮는다
        dutchPayListProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(
            c,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => PBottomSheet.show<void>(
                ctx,
                builder: (_) => DutchStepFlow(
                  expense: dutchTestExpense,
                  probe: StepProbe(),
                  onBack: () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  final l = await AppLocalizations.delegate.load(const Locale('ko'));
  return (repo, l);
}
