// 거래에서 만드는 더치페이의 결제자는 늘 나다(QA 30 3).
//
// "나도 포함" 을 끄면 "내가 전액 결제, 다른 사람 몫만 받아요" 다 — 나는 결제자이고 내 몫은 0원.
// 종전엔 나를 빼고 전원 isPayer false 로 보내 서버가 400 "결제한 사람을 한 명 골라 주세요" 로
// 막아 토스트만 뜨고 정산이 안 생겼다. 이제 나를 0원 결제자로 함께 싣는다(서버는 결제자에게만
// 0원을 받는다, desk-back #360).
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
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';
import '../../support/plain_text.dart';

typedef _Row = ({String? name, int? userRowId, int amount, bool isPayer});

class _Me extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
    rowId: 1,
    userId: 'me',
    userName: '나',
    userEmail: 'me@example.com',
  );
}

class _Repo extends DutchPayRepository {
  _Repo() : super(Dio());
  List<_Row>? sent;

  @override
  Future<DutchPay> create({
    required String title,
    String? description,
    required int totalAmount,
    String? splitMethod,
    String? dutchPayDate,
    int? sourceExpenseRowId,
    required List<_Row> participants,
    bool silent = false,
  }) async {
    sent = participants;
    return DutchPay(rowId: 1, title: title, totalAmount: totalAmount);
  }
}

const _expense = Expense(
  rowId: 9,
  expenseType: 'EXPENSE',
  amount: 3000,
  expenseDate: '2026-09-25T12:00:00',
  merchant: '점심',
);

Future<(_Repo, AppLocalizations)> _open(WidgetTester tester) async {
  final repo = _Repo();
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_Me.new),
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
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => PBottomSheet.show<void>(
                ctx,
                builder: (_) => DutchStepFlow(
                  expense: _expense,
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

Future<void> _addFriend(WidgetTester tester, AppLocalizations l) async {
  await tester.enterText(find.byType(EditableText).first, '친구A');
  await tester.tap(findWidgetWithText(PButton, l.dutchAdd));
  await tester.pumpAndSettle();
}

Future<void> _create(WidgetTester tester, AppLocalizations l) async {
  await tester.tap(findWidgetWithText(PButton, l.dutchCreate));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('나도 포함(기본): 내가 결제자, 친구는 아니다', (tester) async {
    final (repo, l) = await _open(tester);
    await _addFriend(tester, l);
    await _create(tester, l);

    expect(repo.sent, isNotNull, reason: '정산을 안 만들었다');
    expect(repo.sent!.map((p) => (p.name, p.amount, p.isPayer)).toList(), [
      ('나', 1500, true),
      ('친구A', 1500, false),
    ]);
  });

  testWidgets('나도 포함 끔: 나를 0원 결제자로 싣고 친구가 총액을 낸다', (tester) async {
    final (repo, l) = await _open(tester);
    await _addFriend(tester, l);
    await tester.tap(findText(l.dutchMeIncludeTitle));
    await tester.pumpAndSettle();
    await _create(tester, l);

    expect(repo.sent, isNotNull, reason: '정산을 안 만들었다 — 결제자 없는 요청은 서버가 400 이다');
    expect(repo.sent!.map((p) => (p.name, p.amount, p.isPayer)).toList(), [
      ('나', 0, true),
      ('친구A', 3000, false),
    ]);
    expect(repo.sent!.where((p) => p.isPayer), hasLength(1));
  });
}
