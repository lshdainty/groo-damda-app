// 릴리스 노트 렌더 — 그룹 제목과 항목이 갈려 보여야 한다.
//
// 예전엔 노트가 커밋 제목의 나열이라 줄마다 같은 무게로 그렸다. CI 가 타입별로
// 묶어 보내기 시작하면서 '새 기능' 이 항목 하나처럼 보이는 문제가 생겼다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/update/presentation/release_notes_view.dart';
import '../../support/plain_text.dart';

const _notes = '''
새 기능
- 계좌 행을 밀면 수정·삭제

버그 수정
- 반복 거래 정지가 안 되던 문제
''';

Future<void> _pump(WidgetTester tester, String notes) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      home: Scaffold(body: PReleaseNotes(notes: notes)),
    ),
  );
}

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(findText(text)).style!;

void main() {
  testWidgets('그룹 제목은 굵게, 항목은 본문 무게로', (tester) async {
    await _pump(tester, _notes);

    expect(findText('새 기능'), findsOneWidget);
    expect(findText('버그 수정'), findsOneWidget);

    final header = _styleOf(tester, '새 기능');
    final item = _styleOf(tester, '계좌 행을 밀면 수정·삭제');

    expect(header.fontWeight, FontWeight.w500, reason: 'R6 줄 제목 t4 · 500');
    expect(item.fontWeight, FontWeight.w400);
    // 제목이 항목보다 진하다 — 색으로도 갈린다.
    expect(header.color, isNot(item.color));
  });

  testWidgets("항목의 '- ' 는 떼고 글머리를 붙인다", (tester) async {
    await _pump(tester, _notes);

    // 원문 그대로는 안 나온다.
    expect(findText('- 계좌 행을 밀면 수정·삭제'), findsNothing);
    expect(findText('계좌 행을 밀면 수정·삭제'), findsOneWidget);
    // 글머리는 항목 수만큼.
    expect(findText('· '), findsNWidgets(2));
  });

  testWidgets('빈 노트는 아무것도 그리지 않는다', (tester) async {
    await _pump(tester, '   \n  \n');
    expect(find.byType(Text), findsNothing);
    expect(PReleaseNotes.hasContent('   \n'), isFalse);
    expect(PReleaseNotes.hasContent('새 기능\n- 가'), isTrue);
  });
}
