import 'package:flutter/services.dart';

import 'package:groo_damda_app/core/format/amount_limits.dart';

/// 금액 칸 공용 입력 포매터 — 쓰는 동안 천 단위 쉼표를 찍는다(`1234` → `1,234`).
///
/// 숫자가 아닌 글자(부호 · 소수점 · 붙여넣은 문자)는 지우고, 앞쪽 0 은 떼고, 값이 [max]를 넘는 입력은 받지 않는다
/// (웹 `sanitizeAmountInput` 과 같은 규칙). 캐럿은 "캐럿 앞 숫자 개수"를 지켜 쉼표가 끼어도 치던 자리에 남는다.
///
/// 상한이 생기기 전에 저장된 값(100억 넘는 옛 값)을 열었을 때 한 글자도 못 지우면 안 되므로, **줄이는 편집**은
/// 상한을 넘더라도 통과시킨다([AmountLimitFormatter] 와 같은 이유).
///
/// 저장할 때는 [parseAmountInput] 으로 쉼표를 떼고 읽는다. 처음 값은 [formatAmountInput] 으로 쉼표를 찍어 넣는다.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter({this.max = kAmountMax, this.onLimit});

  /// 넣을 수 있는 가장 큰 값 — 기본은 거래 · 예산 · 목표 상한(100억).
  final int max;

  /// 상한 때문에 입력이 막혔는지 알린다 — 넘는 글자를 받지 않으면 `true`, 그 뒤 상한 안의 입력을 받으면 `false`.
  /// 막기만 하고 말이 없으면 눌러도 안 써지는 칸으로 보인다. 칸 아래에 "금액은 100억원까지 입력할 수 있어요."
  /// (오류, 다음 유효한 입력에서 사라진다)를 띄우는 데 쓴다. 칸이 가진 상태로 두고 formatter 는 한 번만 만든다.
  final void Function(bool exceeded)? onLimit;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _stripZeros(_digitsOf(newValue.text));
    if (digits.isEmpty) {
      onLimit?.call(false);
      return const TextEditingValue();
    }

    if (_exceeds(digits)) {
      if (!_shrinks(_stripZeros(_digitsOf(oldValue.text)), digits)) {
        onLimit?.call(true);
        return oldValue;
      }
    } else {
      onLimit?.call(false);
    }

    final text = _group(digits);
    // 캐럿 앞에 있던 숫자 개수 — 앞쪽 0 을 뗀 만큼 줄어들 수 있다
    final raw = newValue.text;
    final cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, raw.length)
        : raw.length;
    final lead = _digitsOf(raw).length - digits.length;
    var before = _digitsOf(raw.substring(0, cursor)).length - lead;
    before = before.clamp(0, digits.length);

    var offset = 0;
    var seen = 0;
    while (offset < text.length && seen < before) {
      if (text.codeUnitAt(offset) != 0x2C) seen++;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  bool _exceeds(String digits) {
    final limit = max.toString();
    if (digits.length != limit.length) return digits.length > limit.length;
    return digits.compareTo(limit) > 0;
  }

  static bool _shrinks(String prev, String next) {
    if (prev.length != next.length) return next.length < prev.length;
    return next.compareTo(prev) < 0;
  }

  static String _digitsOf(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  static String _stripZeros(String s) =>
      s.replaceFirst(RegExp(r'^0+(?=\d)'), '');

  static String _group(String digits) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}

/// 처음 값에 쉼표를 찍는다 — 칸에 넣는 글(`1500000` → `1,500,000`).
String formatAmountInput(int value) =>
    AmountInputFormatter._group(value.toString());

/// 칸의 글에서 쉼표를 떼고 값을 읽는다 — 비었거나 숫자가 아니면 null.
int? parseAmountInput(String text) =>
    int.tryParse(text.replaceAll(',', '').trim());
