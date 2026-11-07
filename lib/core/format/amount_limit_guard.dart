import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';

/// [text](쉼표 · 글자가 섞여도 숫자만 본다)가 상한 [max] 를 넘는가. 64비트를 넘는 자릿수도 문자열로 견준다.
bool amountTextExceeds(String text, int max) {
  final digits = text
      .replaceAll(RegExp(r'[^0-9]'), '')
      .replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final limit = max.toString();
  if (digits.length != limit.length) return digits.length > limit.length;
  return digits.compareTo(limit) > 0;
}

/// 금액 칸 하나의 상한 안내 — 칸이 [AmountInputFormatter] 로 넘는 입력을 막을 때 칸 아래 오류를 띄우는 데 쓴다
/// ("금액은 100억원까지 입력할 수 있어요.", DESIGN.desk.md · 웹 `useAmountLimit` 과 같은 규칙).
///
/// - 입력을 거절한 순간 오류가 선다. **지금 값에서 나온다**: 칸 안의 값이 상한 안으로 바뀌면(다음 유효한 입력 · 비우기 ·
///   프리셋 칩처럼 칸 밖에서 값을 넣는 것까지) 저절로 사라진다. 칸 값이 지금도 상한 위면(상한 전에 저장된 옛 값) 오류는 계속 보인다.
/// - 줄이는 입력은 늘 받는다(옛 초과 값을 줄여 나갈 수 있게) — 그 값으로 저장은 호출처의 저장 검증이 막는다(깎지 않는다).
/// - 저장을 누르면 [dismiss] — 가장 최근 일이 이긴다(거절 직후엔 상한 오류, 저장 직후엔 폼 검증 오류).
///
/// 칸이 든 State 에서 한 번 만들고 [dispose] 한다. [onChanged] 는 보통 `() => setState(() {})` 다.
class AmountLimitGuard {
  AmountLimitGuard(
    this.controller, {
    this.max = kAmountMax,
    this.grouped = true,
    required VoidCallback onChanged,
  }) : _onChanged = onChanged {
    controller.addListener(_onChanged);
  }

  final TextEditingController controller;
  final int max;

  /// 칸에 쉼표를 찍는가 — 아니면 숫자만(필터 칸처럼 칸 글을 그대로 숫자로 읽는 곳).
  final bool grouped;
  final VoidCallback _onChanged;
  bool _rejected = false;
  String _rejectedAt = '';

  /// 칸에 거는 포매터 — 한 번만 만든다.
  late final List<TextInputFormatter> formatters = grouped
      ? [AmountInputFormatter(max: max, onLimit: _onLimit)]
      : [
          FilteringTextInputFormatter.digitsOnly,
          AmountLimitFormatter(max, onLimit: _onLimit),
        ];

  /// 지금 오류를 보일까.
  bool get over =>
      amountTextExceeds(controller.text, max) ||
      (_rejected && controller.text == _rejectedAt);

  /// 저장을 눌렀다 — 거절 때 선 오류를 내려놓는다(폼 검증 오류가 자리를 받는다).
  void dismiss() => _rejected = false;

  void _onLimit(bool exceeded) {
    if (exceeded) {
      // 포매터는 칸에 값이 들어가기 전에 돈다 — 지금 칸의 글이 되돌아올 글이다
      if (_rejected && _rejectedAt == controller.text) return;
      _rejected = true;
      _rejectedAt = controller.text;
      _onChanged();
    } else if (_rejected) {
      _rejected = false;
      _onChanged();
    }
  }

  void dispose() => controller.removeListener(_onChanged);
}
