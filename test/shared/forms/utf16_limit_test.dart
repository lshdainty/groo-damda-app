// 서버가 세는 단위(UTF-16)로 길이를 막는 포매터(I-15 M6) — 이모지로 한도를 넘겨 서버 400 이 나지 않게. 시험은 작성만 했다.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/forms/utf16_limit.dart';

TextEditingValue _v(String t) => TextEditingValue(
  text: t,
  selection: TextSelection.collapsed(offset: t.length),
);

void main() {
  const f = Utf16LengthLimitingFormatter(10);
  test('한도 안은 그대로', () {
    expect(f.formatEditUpdate(_v(''), _v('가나다')).text, '가나다');
  });
  test('넘치면 UTF-16 으로 자른다', () {
    expect(f.formatEditUpdate(_v(''), _v('a' * 15)).text.length, 10);
  });
  test('이모지(UTF-16 2 칸)는 한도 안에서만 — 쌍을 쪼개지 않는다', () {
    final out = f.formatEditUpdate(_v(''), _v('😀' * 9)).text;
    expect(out.length, 10);
    expect(out, '😀' * 5);
    final odd = f.formatEditUpdate(_v(''), _v('a${'😀' * 9}')).text;
    expect(odd.length, lessThanOrEqualTo(10));
    expect(odd.length, 9, reason: '한가운데가 서로게이트 쌍이면 그 앞에서 자른다');
  });
  test('LengthLimitingTextInputFormatter 와 달리 자소가 아니라 UTF-16 으로 센다', () {
    // 이모지 10 개 = 자소 10 = UTF-16 20 — 자소 포매터는 통과시키고(서버 400), 이쪽은 5 개로 자른다
    expect(f.formatEditUpdate(_v(''), _v('😀' * 10)).text.length, 10);
  });
}
