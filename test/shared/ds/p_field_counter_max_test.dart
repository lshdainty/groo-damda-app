// PField counterMax — 세는 줄 분모를 입력 상한과 따로 받는다. 시험은 작성만 했다.
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

  testWidgets('counterMax 가 없으면 maxGraphemeCount 가 분모(지금 그대로)', (tester) async {
    final ctrl = TextEditingController(text: 'abcd');
    await pumpApp(
      tester,
      Scaffold(
        body: PField(maxGraphemeCount: 12, child: PInput(controller: ctrl)),
      ),
    );
    expect(_count(tester, r'^\d+/12$'), '4/12');
  });

  testWidgets('옛 17자 이름에 한 글자 더하면 18 로 입력되고 "18/12" (분모는 규칙 값)', (
    tester,
  ) async {
    final ctrl = TextEditingController(text: 'a' * 17);
    await pumpApp(
      tester,
      Scaffold(
        body: PField(
          maxGraphemeCount: 17 > 12 ? 17 : 12,
          counterMax: 12,
          child: PInput(controller: ctrl),
        ),
      ),
    );
    expect(_count(tester, r'^\d+/12$'), '17/12');
  });

  testWidgets('입력 상한은 maxGraphemeCount — 상한 20, 분모 12 면 18 까지 입력되고 18/12', (
    tester,
  ) async {
    final ctrl = TextEditingController();
    await pumpApp(
      tester,
      Scaffold(
        body: PField(
          maxGraphemeCount: 20,
          counterMax: 12,
          child: PInput(controller: ctrl),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'a' * 18);
    await tester.pump();
    expect(ctrl.text.length, 18);
    expect(_count(tester, r'^\d+/12$'), '18/12');
  });
}
