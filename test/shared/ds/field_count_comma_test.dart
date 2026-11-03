// 글자 수 칸의 천 단위 쉼표 — "10,000/10,000" · 줄어든 값은 그대로 "4/200". 시험은 작성만 했다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import '../../features/todo/todo_test_support.dart';

String _count(WidgetTester tester, String re) => tester
    .widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && RegExp(re).hasMatch(w.text.toPlainText()),
      ),
    )
    .text
    .toPlainText();

void main() {
  setUpAll(loadRealFonts);

  testWidgets('천 이상이면 쉼표 — 0/10,000 · 10,000/10,000', (tester) async {
    final ctrl = TextEditingController();
    await pumpApp(
      tester,
      Scaffold(
        body: PField(maxGraphemeCount: 10000, child: PInput(controller: ctrl)),
      ),
    );
    expect(_count(tester, r'^\d+/10,000$'), '0/10,000');
    ctrl.text = 'a' * 10000;
    await tester.pump();
    expect(_count(tester, r'^[\d,]+/10,000$'), '10,000/10,000');
  });

  testWidgets('천 미만은 그대로 — 4/200', (tester) async {
    final ctrl = TextEditingController(text: 'abcd');
    await pumpApp(
      tester,
      Scaffold(
        body: PField(maxGraphemeCount: 200, child: PInput(controller: ctrl)),
      ),
    );
    expect(_count(tester, r'^\d+/200$'), '4/200');
  });
}
