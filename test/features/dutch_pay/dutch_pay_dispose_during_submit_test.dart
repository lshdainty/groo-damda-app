// 제출 중 위젯이 사라져도 날짜를 읽다 터지지 않는다(#542 사후 검수) — _day 는 await 전에 잡는다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import '../../support/dutch_flow_harness.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('저장소를 기다리는 사이 트리에서 빠져도 예외가 없다', (tester) async {
    final gate = Completer<void>();
    // 날짜가 없는 거래 — _day 가 ref.read(clockProvider) 로 간다
    final (repo, l) = await openDutchFlow(
      tester,
      expense: const Expense(
        rowId: 9,
        expenseType: 'EXPENSE',
        amount: 3000,
        merchant: '점심',
      ),
      repoGate: gate.future,
    );
    await tester.enterText(find.byType(EditableText).first, '친구A');
    await tester.tap(findWidgetWithText(PButton, l.dutchAdd));
    await tester.pumpAndSettle();
    await tester.tap(findWidgetWithText(PButton, l.dutchCreate));
    await tester.pump();

    // 제출이 repo 를 기다리는 중에 화면 전체를 걷는다
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repo.sent, isNotNull, reason: '걷혀도 요청은 이미 시작된 제출이라 끝까지 간다');
  });
}
