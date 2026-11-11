// 거래 · 이체 상세 키-값 줄의 금액(TxKvRow → PListValue.fit) — 띄어쓰기에서 먼저 넘기고 쉼표 뒤는 마지막 수단.
//
// 폭 가정: 시험 글꼴은 Ahem(글자 하나 = 1em 정사각) 이고 값 글자는 t5(16)다. 줄 안 폭 = 화면 360 − 좌우 여백 24 × 2 = 312.
//   글자 200%(em 32)면 312 < 16em(512) 이라 값이 본문 아래로 내려오는 "좁은 줄"이고 값 칸 폭은 312 이다.
//   "100,000원"(8자) = 256 ≤ 312 이라 한 줄에 들지만 "이체 100,000원"(11자) = 352 는 못 든다.
//   "987,654,321,000원"(14자) = 448 > 312 이라 그 낱말 하나가 칸보다 길다. 글자 180%(em 28.8)에서는 "1,000,000원"(10자) = 288 이 든다.
// 실제 글꼴(Pretendard)의 자폭은 달라서 어디서 넘치는지는 실기기에서 본다(실기기 목록 참고).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all_fit_text.dart';

Widget _host(Widget child, double scale) => MaterialApp(
  theme: GrooTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(360, 800),
      textScaler: TextScaler.linear(scale),
    ),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 360, child: child),
      ),
    ),
  ),
);

List<String> _lines(WidgetTester tester) {
  final p = tester.renderObject<RenderParagraph>(
    find.descendant(
      of: find.byType(KeepAllFitText),
      matching: find.byType(RichText),
    ),
  );
  final text = p.text.toPlainText();
  final tp = TextPainter(
    text: p.text,
    textDirection: TextDirection.ltr,
    textScaler: p.textScaler,
  )..layout(maxWidth: p.size.width);
  final out = <String>[];
  var start = 0;
  while (start < text.length) {
    final b = tp.getLineBoundary(TextPosition(offset: start));
    if (b.end <= start) break;
    out.add(
      text.substring(b.start, b.end).replaceAll(RegExp('[⁠​]'), '').trimRight(),
    );
    start = b.end;
  }
  return out;
}

Future<List<String>> _linesOf(
  WidgetTester tester,
  String label,
  String value, {
  double scale = 2,
}) async {
  await tester.pumpWidget(
    _host(
      PList(
        children: [TxKvRow(label: label, value: value)],
      ),
      scale,
    ),
  );
  expect(tester.takeException(), isNull, reason: 'overflow 오류 0');
  return _lines(tester);
}

void main() {
  group('한국어 · 360 · 200%', () {
    testWidgets('앞 말 + 금액 — 금액째 다음 줄로 간다', (tester) async {
      final lines = await _linesOf(tester, '금액', '이체 100,000원');
      expect(lines, ['이체', '100,000원']);
    });

    testWidgets('아주 큰 금액은 쉼표 뒤에서만 꺾이고 숫자 한가운데는 안 끊긴다', (tester) async {
      final lines = await _linesOf(tester, '금액', '987,654,321,000원');
      expect(lines.length, greaterThan(1));
      for (final l in lines.take(lines.length - 1)) {
        expect(l.endsWith(','), isTrue, reason: '쉼표 뒤에서만 꺾는다: $lines');
      }
      expect(lines.join(), '987,654,321,000원');
    });

    testWidgets('앞 말 + 아주 큰 금액 — 금액이 칸보다 길면 쉼표 뒤에서만 꺾는다(앞 말은 첫 줄에 붙는다)', (
      tester,
    ) async {
      final lines = await _linesOf(tester, '금액', '이체 987,654,321,000원');
      expect(lines.first.startsWith('이체 '), isTrue, reason: '$lines');
      for (final l in lines.take(lines.length - 1)) {
        expect(l.endsWith(','), isTrue, reason: '$lines');
      }
    });

    testWidgets('글자 180% — 이체 1,000,000원 도 금액째 다음 줄로', (tester) async {
      final lines = await _linesOf(tester, '금액', '이체 1,000,000원', scale: 1.8);
      expect(lines, ['이체', '1,000,000원']);
    });

    testWidgets('읽는 이름은 원래 글이다', (tester) async {
      await _linesOf(tester, '금액', '이체 100,000원');
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(KeepAllFitText),
          matching: find.byType(Text),
        ),
      );
      expect(text.semanticsLabel, '이체 100,000원');
    });
  });

  group('영어 · 360 · 200%', () {
    testWidgets('앞 말 + 금액 — 금액째 다음 줄로 간다', (tester) async {
      final lines = await _linesOf(tester, 'Amount', 'Fee ₩100,000');
      expect(lines, ['Fee', '₩100,000']);
    });

    testWidgets('아주 큰 금액은 쉼표 뒤에서만 꺾인다', (tester) async {
      final lines = await _linesOf(tester, 'Amount', '₩987,654,321,000');
      expect(lines.length, greaterThan(1));
      for (final l in lines.take(lines.length - 1)) {
        expect(l.endsWith(','), isTrue, reason: '$lines');
      }
    });
  });

  testWidgets('글자 100% — 한 줄에 들면 그대로 한 줄', (tester) async {
    final lines = await _linesOf(tester, '금액', '이체 1,000,000원', scale: 1);
    expect(lines, ['이체 1,000,000원']);
  });
}
