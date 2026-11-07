import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/amount_input_formatter.dart';

TextEditingValue _type(String old, String next, {int? cursor}) =>
    const AmountInputFormatter().formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: cursor ?? next.length),
      ),
    );

void main() {
  test('쓰는 동안 쉼표를 찍는다', () {
    expect(_type('123', '1234').text, '1,234');
    expect(_type('1,234', '12,345').text, '12,345');
    expect(_type('', '9876543210').text, '9,876,543,210');
  });

  test('숫자 아닌 글자는 지우고 앞쪽 0 은 뗀다', () {
    expect(_type('', '-1.5e').text, '15');
    expect(_type('', '007').text, '7');
    expect(_type('1', '').text, '');
  });

  test('붙여넣기로 쉼표가 섞여 와도 읽는다', () {
    expect(_type('', '1,500,000').text, '1,500,000');
  });

  test('상한(100억)을 넘는 입력은 받지 않는다', () {
    expect(_type('10,000,000,000', '100,000,000,001').text, '10,000,000,000');
    expect(_type('1,000,000,000', '10000000000').text, '10,000,000,000');
  });

  test('상한 위로 저장된 옛 값은 줄이는 편집만 통과한다', () {
    expect(_type('99,999,999,999', '9,999,999,999').text, '9,999,999,999');
    expect(_type('99,999,999,999', '999,999,999,999').text, '99,999,999,999');
  });

  test('캐럿은 앞 숫자 개수를 지킨다', () {
    // 1,234 의 맨 앞에서 9 를 쳐 91,234 — 캐럿은 9 바로 뒤
    final v = _type('1,234', '91,234', cursor: 1);
    expect(v.text, '91,234');
    expect(v.selection.baseOffset, 1);
    // 1,234 가운데에서 지워 1,34 → 134
    final w = _type('1,234', '1,34', cursor: 2);
    expect(w.text, '134');
    expect(w.selection.baseOffset, 1);
  });

  test('저장 때 쉼표를 떼고 읽는다', () {
    expect(parseAmountInput('1,500,000'), 1500000);
    expect(parseAmountInput(''), isNull);
    expect(formatAmountInput(1500000), '1,500,000');
  });

  group('onLimit — 막았다고 알린다 (칸 아래 "금액은 100억원까지 입력할 수 있어요.")', () {
    List<bool> run(List<(String, String)> edits) {
      final seen = <bool>[];
      final f = AmountInputFormatter(onLimit: seen.add);
      for (final (old, next) in edits) {
        f.formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          ),
        );
      }
      return seen;
    }

    test('넘는 입력을 막으면 true, 다음 유효한 입력은 false', () {
      expect(
        run([
          ('1,000,000,000', '10000000000'), // 정확히 100억 — 받는다
          ('10,000,000,000', '100,000,000,001'), // 넘는다 — 막는다
          ('10,000,000,000', '1,000,000,000'), // 줄인다 — 받는다
        ]),
        [false, true, false],
      );
    });

    test('비우는 입력도 걷는다', () {
      expect(run([('10,000,000,000', '')]), [false]);
    });

    test('상한 위 옛 값을 줄이는 편집은 막지 않는다(알리지도 않는다)', () {
      expect(run([('99,999,999,999', '9,999,999,999')]), [false]);
    });
  });
}
