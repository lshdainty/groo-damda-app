// DA-31 — 금액은 띄어쓰기에서 먼저 꺾고(금액 덩어리를 통째로 다음 줄로), 쉼표 뒤 줄바꿈은 금액 하나가 칸보다 길 때만 쓴다.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all_fit_text.dart';

Widget _host(Widget child, double scale, double width) => MaterialApp(
  theme: GrooTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(360, 640),
      textScaler: TextScaler.linear(scale),
    ),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
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

void main() {
  // 200% · Ahem(글자 하나 = 1em 정사각, 14 × 2 = 28) — 금액 하나는 들어가지만 앞 말과 한 줄에는 안 들어가는 폭
  const cases = {'12,000원 / 한도 1,000,000원': 330.0, '잔여 988,000원': 240.0};
  for (final e in cases.entries) {
    testWidgets('금액이 쪼개지지 않는다: ${e.key}', (tester) async {
      await tester.pumpWidget(_host(KeepAllFitText(e.key), 2, e.value));
      final lines = _lines(tester);
      for (final amount in ['1,000,000원', '988,000원', '12,000원']) {
        if (!e.key.contains(amount)) continue;
        expect(
          lines.any((l) => l.split(' ').contains(amount)),
          isTrue,
          reason: '$amount 가 한 줄에 통째로 있어야 한다: $lines',
        );
      }
    });
  }

  testWidgets('금액만으로 한 줄이 넘치면 쉼표 뒤에서 꺾는다', (tester) async {
    const big = '987,654,321,000원';
    await tester.pumpWidget(_host(const KeepAllFitText(big), 2, 200));
    final lines = _lines(tester);
    expect(lines.length, greaterThan(1));
    for (final l in lines.take(lines.length - 1)) {
      expect(l.endsWith(','), isTrue, reason: '쉼표 뒤에서만: $lines');
    }
    expect(lines.join(), big);
  });
}
