import 'package:flutter/services.dart';

/// 서버가 세는 단위(UTF-16 코드 유닛 — Java `@Size` · Dart `String.length`)로 길이를 막는 입력 포매터.
///
/// [LengthLimitingTextInputFormatter] 는 자소(글자 모양) 단위로 세어, 이모지 10,000 개(= UTF-16 20,000)를 통과시킨다 — 서버가 400 으로 되돌려
/// "저장하지 못했어요" 만 남고 다시 해도 안 된다(I-15 M6).
///
/// 한도를 넘으면 **넣은 부분만** 줄인다(앞뒤 글은 그대로) — 꽉 찬 글 한가운데에 한 글자를 쳐도 맨 끝 글자가 말없이 지워지지 않고, 길게
/// 붙여 넣어도 붙인 글의 뒤쪽만 잘린다. 남는 자리가 없으면 입력을 받지 않는다(이전 값 그대로). 서로게이트 쌍은 쪼개지 않는다.
class Utf16LengthLimitingFormatter extends TextInputFormatter {
  const Utf16LengthLimitingFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final text = newValue.text;
    if (text.length <= max) {
      return newValue;
    }
    // 바뀐 자리 — 앞에서 같은 만큼(prefix) · 뒤에서 같은 만큼(suffix)을 빼면 가운데가 넣은 글(바꾼 글)이다
    final shorter = oldText.length < text.length ? oldText.length : text.length;
    var prefix = 0;
    while (prefix < shorter &&
        oldText.codeUnitAt(prefix) == text.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shorter - prefix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            text.codeUnitAt(text.length - 1 - suffix)) {
      suffix++;
    }
    final inserted = text.substring(prefix, text.length - suffix);
    // 넣은 글이 쓸 수 있는 자리 = 한도 − (앞 + 뒤)
    final room = max - prefix - suffix;
    if (room <= 0) {
      return oldValue;
    }
    var keep = room < inserted.length ? room : inserted.length;
    if (keep > 0 && keep < inserted.length) {
      final unit = inserted.codeUnitAt(keep - 1);
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        keep -= 1; // 서로게이트 쌍 한가운데면 그 앞에서 자른다
      }
    }
    final cutText =
        text.substring(0, prefix) +
        inserted.substring(0, keep) +
        text.substring(text.length - suffix);
    return TextEditingValue(
      text: cutText,
      selection: TextSelection.collapsed(offset: prefix + keep),
    );
  }
}
