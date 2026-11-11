/// 등락률(%) 표기 — **어디서나 소수 둘째 자리**(0.43% · 5.00% · −12.30% · 천 퍼센트 이상은 쉼표 `1,234.50%`). 사용자 결정 2026-10-25
/// (`decisions/migration-stocks.md` "숫자 표기 둘"). 증권 · 홈 · 자산 · 통계가 이 함수 하나를 쓴다.
///
/// - 빼기는 U+2212 하나(앞의 하이픈이 아니다 — 금액 부호와 같은 글자).
/// - 둘째 자리까지 반올림한 값이 0 이면 부호를 붙이지 않는다("-0.00%" · "+0.00%" 가 나오지 않는다).
/// - 거절된 안: "첫째 자리" · ".0 빼기" · "첫째 자리 늘".
library;

import 'package:groo_damda_app/core/format/percent.dart';

const String _minus = '−';

/// 소수 둘째 자리 + 정수부 천 단위 쉼표 — 금액·숫자 표기와 같은 결(웹 formatChangeRate 와 같다).
/// 천 퍼센트 이상: `1,234.50%`. 로케일과 무관하게 ko · en 모두 쉼표다.
String _body(double rate) => groupPercentDigits(rate.abs().toStringAsFixed(2));

/// 부호가 있는 등락률 — 음수는 "−", [signed] 가 true 면 양수에 "+" 를 붙인다(증권 목록 · 손익). 0 은 부호 없음.
String formatChangeRate(double rate, {bool signed = false}) {
  final body = _body(rate);
  if (body == '0.00') return '$body%';
  if (rate < 0) return '$_minus$body%';
  return '${signed ? '+' : ''}$body%';
}

/// 크기만 — 방향은 옆의 화살표(Delta)가 말한다. 부호를 붙이지 않는다.
String formatChangeRateAbs(double rate) => '${_body(rate)}%';
