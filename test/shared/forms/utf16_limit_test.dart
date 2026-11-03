// 서버가 세는 단위(UTF-16)로 길이를 막는 포매터(I-15 M6 · N1) — 넣은 부분만 줄이고 꼬리는 지키지 않는 일이 없게. 시험은 작성만 했다.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/forms/utf16_limit.dart';

TextEditingValue _v(String t, [int? caret]) => TextEditingValue(
  text: t,
  selection: TextSelection.collapsed(offset: caret ?? t.length),
);

void main() {
  const f = Utf16LengthLimitingFormatter(10);

  test('한도 안은 그대로', () {
    expect(f.formatEditUpdate(_v(''), _v('가나다')).text, '가나다');
  });

  test('끝에 이어 붙이면 붙인 글의 뒤쪽이 잘린다', () {
    expect(
      f.formatEditUpdate(_v('a' * 8), _v('${'a' * 8}bcdef')).text,
      '${'a' * 8}bc',
    );
  });

  test('꽉 찬 글 한가운데에 한 글자를 치면 입력이 거절되고 맨 끝 글자는 그대로다', () {
    const old = '0123456789';
    final out = f.formatEditUpdate(_v(old, 5), _v('01234X56789', 6));
    expect(out.text, old);
  });

  test('남는 자리가 둘인 채 한가운데에 다섯 글자를 붙이면 붙인 글만 둘로 줄고 꼬리는 남는다', () {
    // 앞 4 + 꼬리 4 = 8 → 자리 2
    final out = f.formatEditUpdate(_v('abcdWXYZ', 4), _v('abcd12345WXYZ', 9));
    expect(out.text, 'abcd12WXYZ');
    expect(out.text.endsWith('WXYZ'), isTrue);
    expect(out.selection.baseOffset, 6);
  });

  test('이모지(UTF-16 2 칸)는 쌍을 쪼개지 않는다', () {
    final out = f.formatEditUpdate(_v(''), _v('😀' * 9));
    expect(out.text, '😀' * 5);
    final odd = f.formatEditUpdate(_v(''), _v('a${'😀' * 9}')).text;
    expect(odd.length, 9);
  });
}
