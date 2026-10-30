import 'package:flutter/services.dart';

/// 서버가 세는 단위(UTF-16 코드 유닛 — Java `@Size` · Dart `String.length`)로 길이를 막는 입력 포매터.
///
/// [LengthLimitingTextInputFormatter] 는 자소(글자 모양) 단위로 세어, 이모지 10,000 개(= UTF-16 20,000)를 통과시킨다 — 서버가 400 으로 되돌려
/// "저장하지 못했어요" 만 남고 다시 해도 안 된다(I-15 M6). 이 포매터는 UTF-16 로 [max] 를 넘는 끝을 자르되 서로게이트 쌍은 쪼개지 않는다.
class Utf16LengthLimitingFormatter extends TextInputFormatter {
  const Utf16LengthLimitingFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length <= max) {
      return newValue;
    }
    var end = max;
    // 서로게이트 쌍 한가운데면 그 앞에서 자른다
    final unit = text.codeUnitAt(end - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      end -= 1;
    }
    final cut = text.substring(0, end);
    return TextEditingValue(
      text: cut,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, end),
      ),
    );
  }
}
