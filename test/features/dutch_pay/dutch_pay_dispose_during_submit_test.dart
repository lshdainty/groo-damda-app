// 제출 중 위젯이 사라져도 await 뒤에서 ref · context 를 읽다 터지지 않는다(#542 · #543 사후 검수).
// 터져도 catch 가 삼키므로 "예외가 없다" 만으론 모자라다 — 성공 뒤 목록 비우기가 실제로 돌았는지 센다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import '../../support/dutch_flow_harness.dart';
import '../../support/plain_text.dart';

const _noDate = Expense(
  rowId: 9,
  expenseType: 'EXPENSE',
  amount: 3000,
  merchant: '점심',
);

void main() {
  testWidgets('저장소를 기다리는 사이 트리 전체가 빠져도 예외가 없다', (tester) async {
    final gate = Completer<void>();
    final errors = <Object>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exception);
    addTearDown(() => FlutterError.onError = prev);
    final (repo, l) = await openDutchFlow(
      tester,
      expense: _noDate,
      repoGate: gate.future,
    );
    await tester.enterText(find.byType(EditableText).first, '친구A');
    await tester.tap(findWidgetWithText(PButton, l.dutchAdd));
    await tester.pumpAndSettle();
    await tester.tap(findWidgetWithText(PButton, l.dutchCreate));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(errors, isEmpty);
    expect(repo.sent, isNotNull);
  });

  testWidgets('저장 중 시트만 닫혀도 저장 뒤 목록을 다시 받는다', (tester) async {
    final gate = Completer<void>();
    var listLoads = 0;
    final (repo, l) = await openDutchFlow(
      tester,
      expense: _noDate,
      repoGate: gate.future,
      onListLoad: () => listLoads++,
    );
    await tester.enterText(find.byType(EditableText).first, '친구A');
    await tester.tap(findWidgetWithText(PButton, l.dutchAdd));
    await tester.pumpAndSettle();
    await tester.tap(findWidgetWithText(PButton, l.dutchCreate));
    await tester.pump();
    final before = listLoads;

    // 시트(라우트)만 닫는다 — ProviderScope 는 살아 있다
    Navigator.of(tester.element(findText('open'))).pop();
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repo.sent, isNotNull);
    expect(
      listLoads,
      greaterThan(before),
      reason: 'dispose 뒤에도 목록을 비우고 다시 받아야 한다',
    );
  });
}
