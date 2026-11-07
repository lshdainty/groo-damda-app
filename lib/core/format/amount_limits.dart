import 'package:flutter/services.dart';

/// 거래·예산·목표 금액 상한 — 백엔드 `@Max` · 웹 `parseAmount` 와 같은 값(100억).
///
/// 여기서 막는 건 '틀린 값이 서버까지 가서 400 으로 되돌아오는' 왕복을 없애기
/// 위해서다. 진짜 게이트는 서버다 — 앱만 막으면 API 를 직접 부르는 경로가 남는다.
const int kAmountMax = 10000000000; // 100억

/// 자산 잔액·한도 상한 — 거래(100억)와 별개다(사용자 확정, QA #17).
/// 계좌 잔액은 거래 한 건보다 큰 값을 들 수 있어 한 자릿수 더 준다.
const int kBalanceMax = 100000000000; // 1,000억

/// 값으로 타이핑을 막는 포매터.
///
/// 자릿수만 세면 안 된다 — 100억은 11자리(`10000000000`)라
/// `LengthLimitingTextInputFormatter(11)` 은 999억(`99999999999`)을 그대로 통과시킨다.
/// 그래서 값을 파싱해 판정한다. 넘으면 [TextEditingValue] 를 이전 값으로 되돌려
/// 타이핑 자체가 안 먹게 한다(웹의 "타이핑 자체를 100억에서 막기" 와 같은 동작).
///
/// 앞단에 [FilteringTextInputFormatter.digitsOnly] 가 붙는 걸 전제한다 —
/// 숫자가 아닌 문자가 남아 있으면 파싱이 실패해 이전 값으로 되돌아간다.
class AmountLimitFormatter extends TextInputFormatter {
  const AmountLimitFormatter(this.max, {this.onLimit});

  final int max;

  /// 상한 때문에 막았으면 `true`, 상한 안의 입력을 받으면 `false` — [AmountInputFormatter.onLimit] 과 같다.
  final void Function(bool exceeded)? onLimit;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final next = _digits(newValue.text);
    // 비우는 건 언제나 허용한다.
    if (next.isEmpty) {
      onLimit?.call(false);
      return newValue;
    }
    final n = int.tryParse(next);
    if (n != null && n <= max) {
      onLimit?.call(false);
      return newValue;
    }
    // 상한을 넘겼다. 다만 **줄이는 편집**은 통과시킨다 — 상한이 생기기 전에 저장된
    // 값(QA 가 만든 99조 잔액)을 열면 한 글자도 못 지우고 통째로 비우는 수밖에
    // 없어진다. 줄이는 방향이면 어차피 상한 아래로 내려가는 길이다.
    if (_shrinks(_digits(oldValue.text), next)) return newValue;
    onLimit?.call(true);
    return oldValue;
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  /// [next] 가 [prev] 보다 작은 수인가.
  ///
  /// 64비트를 넘겨 `int.tryParse` 가 못 읽는 자릿수도 다뤄야 해서 문자열로 비교한다 —
  /// 선행 0 을 떼고 자릿수 → 사전순으로 본다.
  static bool _shrinks(String prev, String next) {
    final p = prev.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final q = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (p.length != q.length) return q.length < p.length;
    return q.compareTo(p) < 0;
  }
}
