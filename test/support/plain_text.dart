import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 줄바꿈 보호 글자(U+2060 · 쉼표 뒤 U+200B — keepAll · keepAllAmount)를 뺀 글.
String plainOf(String s) => s.replaceAll('⁠', '').replaceAll('​', '');

/// 보이지 않는 줄바꿈 글자를 빼고 글이 같은 [Text] — ds 금액 · 제목은 낱말 단위 줄바꿈 글자가 낀다.
Finder findPlain(String s) => find.byWidgetPredicate(
  (w) => w is Text && w.data != null && plainOf(w.data!) == s,
  description: 'Text "$s"',
);

/// 줄바꿈 글자를 빼고 [part] 를 포함하는 [Text].
Finder findPlainContaining(String part) => find.byWidgetPredicate(
  (w) => w is Text && w.data != null && plainOf(w.data!).contains(part),
  description: 'Text containing "$part"',
);

/// 줄바꿈 글자를 빼고 [part] 를 포함하는 글(Text · Text.rich 모두).
Finder findRichPlain(String part) => find.byWidgetPredicate(
  (w) => w is RichText && plainOf(w.text.toPlainText()).contains(part),
  description: 'RichText containing "$part"',
);

/// 목록 제목처럼 `Text.rich` 로 그린 글 — 줄바꿈 글자와 자리 표시(WidgetSpan)를 빼고 **정확히** [s] 인 것([findPlain] 은
/// `data` 가 있는 [Text] 만 본다).
Finder findRichText(String s) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      w.data == null &&
      w.textSpan != null &&
      plainOf(w.textSpan!.toPlainText().replaceAll('\uFFFC', '')) == s,
  description: 'Text.rich "$s"',
);
