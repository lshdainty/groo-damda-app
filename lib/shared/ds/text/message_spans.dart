import 'package:flutter/painting.dart' show InlineSpan, TextSpan;

import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 로케일 문구 한 문장 안의 자리표시자 [index] 자리를 가리키는 표시 글자(Private Use Area U+E000 + index).
///
/// ARB 메시지에 값 대신 이 글자를 넣어 문장을 받은 뒤 [messageSpans] 로 자리마다 모양 있는 span 을 끼운다.
/// 화면에 그대로 나가는 일은 없다 — [messageSpans] 가 늘 이 글자를 걷는다.
String messageMark(int index) => String.fromCharCode(0xE000 + index);

/// 문장 하나를 자리표시자 기준으로 나눠 그린다 — 값(금액 · %)만 다른 모양으로, 문장의 나머지는 바깥 style 그대로.
///
/// 문구를 앞 조각 · 값 · 뒤 조각으로 잘라 이어 붙이면 어순이 언어마다 달라 영어에서 깨진다("Daily average ₩2,106
/// spent., vs last month …"). 그래서 문장은 ARB 메시지 하나로 두고, 값 자리에 [messageMark] 를 넣어 받은 [message]
/// 를 여기서 나눈다. [values] 의 i 번째 span 이 [messageMark]`(i)` 자리에 들어간다(언어마다 순서가 달라도 된다).
///
/// 글은 [keepAll](낱말 단위 줄바꿈)을 문장 통째로 거친 뒤 나눈다 — 값과 붙은 말("12%가")이 span 경계에서 갈라지지 않는다.
/// 값 span 의 글은 부르는 쪽이 만든다(금액은 [keepAllAmount]).
List<InlineSpan> messageSpans(String message, List<InlineSpan> values) {
  final text = keepAll(message);
  final out = <InlineSpan>[];
  final buf = StringBuffer();
  for (final rune in text.runes) {
    final i = rune - 0xE000;
    if (i >= 0 && i < values.length) {
      if (buf.isNotEmpty) out.add(TextSpan(text: buf.toString()));
      buf.clear();
      out.add(values[i]);
    } else {
      buf.writeCharCode(rune);
    }
  }
  if (buf.isNotEmpty) out.add(TextSpan(text: buf.toString()));
  return out;
}
