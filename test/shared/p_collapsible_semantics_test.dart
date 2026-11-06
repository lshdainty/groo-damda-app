// 옛 PCollapsible 의 트리거 읽기 (I-04 03G-012) — 트리거를 버튼 · 펼침 상태로 감싼다.
//
// 호출부(카드 상세의 주의 사항 · 혜택 줄)가 InkWell 만 넘기므로 누르기만 있고 "펼침" 을 알릴 길이 없었다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/widgets/p_collapsible.dart';
import '../support/plain_text.dart';

void main() {
  testWidgets('트리거는 버튼이고 펼침 전후 expanded 가 바뀐다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Scaffold(
          body: PCollapsible(
            trigger: (context, isOpen, toggle) => InkWell(
              onTap: toggle,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('혜택 상세'),
              ),
            ),
            content: const Text('상세 내용'),
          ),
        ),
      ),
    );
    SemanticsData data() =>
        tester.getSemantics(findText('혜택 상세')).getSemanticsData();
    expect(data().flagsCollection.isButton, isTrue);
    expect(data().flagsCollection.isExpanded, Tristate.isFalse, reason: '접힘');
    await tester.tap(findText('혜택 상세'));
    await tester.pumpAndSettle();
    expect(data().flagsCollection.isExpanded, Tristate.isTrue, reason: '펼침');
    expect(findText('상세 내용'), findsOneWidget);
    await tester.tap(findText('혜택 상세'));
    await tester.pumpAndSettle();
    expect(
      data().flagsCollection.isExpanded,
      Tristate.isFalse,
      reason: '다시 접힘',
    );
    handle.dispose();
  });
}
