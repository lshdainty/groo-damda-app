// DA-31 — 글자 200% · 좁은 폭에서 키-값 줄의 값이 낱말(10월) · 숫자 가운데서 끊기지 않는다.
// 줄이 바뀌는 자리는 공백 뒤(낱말 단위) 또는 금액의 쉼표 뒤(U+200B)뿐이다.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';

Widget _host(Widget child, double scale) => MaterialApp(
  theme: GrooTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(360, 640),
      textScaler: TextScaler.linear(scale),
    ),
    child: Scaffold(body: SizedBox(width: 360, child: child)),
  ),
);

/// 문단의 줄을 이은 글(줄 경계는 '|').
List<String> _lines(WidgetTester tester, Finder f) {
  final p = tester.renderObject<RenderParagraph>(f);
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
    out.add(text.substring(b.start, b.end));
    start = b.end;
  }
  return out;
}

void main() {
  const cases = {
    '카드 이용 기간': '10월 1일~10월 31일',
    '결제 예정': '1,000,000원',
    '잔여': '988,000원',
  };
  for (final scale in [1.0, 2.0]) {
    testWidgets('KvRow 값이 낱말 가운데서 끊기지 않는다 (글자 ${scale * 100}%)', (
      tester,
    ) async {
      for (final e in cases.entries) {
        await tester.pumpWidget(
          _host(KvRow(label: e.key, value: e.value), scale),
        );
        final value = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data ?? '').replaceAll(RegExp('[⁠​]'), '') == e.value,
        );
        expect(value, findsOneWidget, reason: e.value);
        final lines = _lines(
          tester,
          find.descendant(of: value, matching: find.byType(RichText)),
        );
        for (var i = 0; i < lines.length - 1; i++) {
          final last = lines[i].characters.last;
          final zw = String.fromCharCode(0x200B);
          expect(
            last == ' ' || last == zw,
            isTrue,
            reason: '${e.value} 줄 $i 끝 "${lines[i]}" 가 낱말 가운데',
          );
          if (last == zw) {
            final pre = lines[i].replaceAll(zw, '');
            // 쉼표(금액) · 구간 기호 뒤에서만
            expect(pre.endsWith(',') || pre.endsWith('~'), isTrue);
          }
        }
      }
    });
  }
}
