// 시험에서 글을 찾는 도우미 — ds 글에는 맨 `find.text` · `find.textContaining` 을 쓰지 않는다.
//
// ds 는 낱말 단위 줄바꿈(v114)으로 글자 사이에 U+2060(쉼표 뒤 U+200B)을 끼우고, 목록 제목 · Callout · 칩 · 태그 묶음을
// `Text.rich` 로 그린다(자리 표시 WidgetSpan 은 U+FFFC). 반복 줄 설명은 공백 대신 U+00A0 을 쓴다. 맨 `find.text('지출 상세')`
// 는 이 글자들 때문에 맞지 않고, "없다" 단언(`findsNothing`)은 헛통과한다. 아래 [findText] · [findTextContaining] 은
// `find.text` 와 같은 자리(Text · Text.rich · EditableText, `findRichText` 면 RichText)를 보되 이 글자들을 벗겨 견준다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 줄바꿈 보호 글자(U+2060 · U+200B — keepAll · keepAllAmount)와 자리 표시(U+FFFC)를 빼고, 줄바꿈 없는 공백(U+00A0)은
/// 보통 공백으로 바꾼 글.
String plainOf(String s) => s
    .replaceAll('⁠', '')
    .replaceAll('​', '')
    .replaceAll('￼', '')
    .replaceAll(' ', ' ');

/// [Text] 의 글 — `data` 가 없으면(Text.rich) span 을 이은 글.
String? _textOf(Widget w) {
  if (w is! Text) return null;
  return w.data ?? w.textSpan?.toPlainText(includePlaceholders: false);
}

class _PlainTextFinder extends MatchFinder {
  _PlainTextFinder(
    this._test,
    this._description, {
    required this.findRichText,
    super.skipOffstage,
  });

  final bool Function(String plain) _test;
  final String _description;
  final bool findRichText;

  @override
  String get description => _description;

  @override
  bool matches(Element candidate) {
    final w = candidate.widget;
    if (w is EditableText) return _test(plainOf(w.controller.text));
    if (findRichText) {
      return w is RichText && _test(plainOf(w.text.toPlainText()));
    }
    final t = _textOf(w);
    return t != null && _test(plainOf(t));
  }
}

/// `find.text` 와 같다 — 다만 줄바꿈 글자를 벗긴 글이 [s] 와 같은지 본다.
Finder findText(
  String s, {
  bool findRichText = false,
  bool skipOffstage = true,
}) => _PlainTextFinder(
  // 찾는 글에 줄바꿈 글자가 들어 있어도(keepAll 로 만든 기대값) 같이 벗겨 견준다
  (t) => t == plainOf(s),
  'text "$s"',
  findRichText: findRichText,
  skipOffstage: skipOffstage,
);

/// `find.textContaining` 과 같다 — 다만 줄바꿈 글자를 벗긴 글에서 [pattern] 을 찾는다.
Finder findTextContaining(
  Pattern pattern, {
  bool findRichText = false,
  bool skipOffstage = true,
}) => _PlainTextFinder(
  (t) => t.contains(pattern is String ? plainOf(pattern) : pattern),
  'text containing $pattern',
  findRichText: findRichText,
  skipOffstage: skipOffstage,
);

/// 줄바꿈 글자를 빼고 글이 같은 [Text](Text.rich 포함) — 입력칸 글은 보지 않는다(입력칸까지는 [findText]).
Finder findPlain(String s) => find.byWidgetPredicate((w) {
  final t = _textOf(w);
  return t != null && plainOf(t) == plainOf(s);
}, description: 'Text "$s"');

/// 줄바꿈 글자를 빼고 [part] 를 포함하는 [Text](Text.rich 포함).
Finder findPlainContaining(String part) => find.byWidgetPredicate((w) {
  final t = _textOf(w);
  return t != null && plainOf(t).contains(plainOf(part));
}, description: 'Text containing "$part"');

/// 줄바꿈 글자를 빼고 [part] 를 포함하는 글(Text · Text.rich 모두).
Finder findRichPlain(String part) => find.byWidgetPredicate(
  (w) => w is RichText && plainOf(w.text.toPlainText()).contains(part),
  description: 'RichText containing "$part"',
);

/// 목록 제목처럼 `Text.rich` 로 그린 글 — 줄바꿈 글자와 자리 표시(WidgetSpan)를 빼고 **정확히** [s] 인 것([findPlain] 은
/// `data` 가 있는 [Text] 도 본다).
Finder findRichText(String s) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      w.data == null &&
      w.textSpan != null &&
      plainOf(w.textSpan!.toPlainText()) == plainOf(s),
  description: 'Text.rich "$s"',
);

/// `find.widgetWithText` 와 같다 — [widgetType] 형 위젯 중 줄바꿈 글자를 벗긴 글이 [text] 인 후손을 가진 것.
Finder findWidgetWithText(
  Type widgetType,
  String text, {
  bool skipOffstage = true,
}) => find.ancestor(
  of: findText(text, skipOffstage: skipOffstage),
  matching: find.byType(widgetType, skipOffstage: skipOffstage),
);
