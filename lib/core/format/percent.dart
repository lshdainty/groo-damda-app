/// 퍼센트 표기 — 뜻이 셋이다(사용자 결정 2026-11-07 "B3 1A"). 한 함수로 합치지 않는다.
///
/// - **비중**(전체 중 몫: 도넛 범례 · 종목 구성 등) = [formatShare] — 소수 첫째 자리 늘 한 자리
///   ("30.0%"). 0 자리면 범례 합이 101% 가 되기 때문이다.
/// - **진행률**(예산 이행 · 사용 · 저축 달성 · 저축률 · 할인율) = [formatProgress] — 정수("76%").
///   막대 · 말풍선 · 범례 · 화면 낭독 이름이 같은 값이다.
/// - **등락률 · 수익률** = `change_rate.dart` 의 `formatChangeRate` — 둘째 자리. 여기서 부르지 않고
///   그대로 둔다(거절된 안: 합치기).
library;

/// JS `Math.round` 와 같은 반올림(.5 는 +무한 쪽) — 웹 `formatPercent` 와 같은 글자를 내려고 쓴다.
double _jsRound(double x) => (x + 0.5).floorToDouble();

const String _minus = '−'; // U+2212 — 금액 부호와 같은 글자(하이픈이 아니다)

/// 비중 — "30.0%". 0 은 "0.0%", 0 보다 크고 0.05% 미만은 [underOne]("0.1% 미만" · "<0.1%" —
/// 로케일 문구라 호출처가 `l.percentUnderTenth` 를 넘긴다). 유한하지 않은 값(NaN · 무한)은 "—".
/// 소수 첫째 자리는 웹과 같은 식(`Math.round(pct * 10) / 10`)으로 맞춘다 — 12.35 가 앱 12.3 · 웹 12.4 로 갈리지 않게.
/// 음수는 빼기 U+2212 를 앞에 붙인다("−12.3%"), 반올림해서 0 이 되면 부호 없이 "0.0%".
String formatShare(double pct, {required String underOne}) {
  if (!pct.isFinite) return '—';
  if (pct > 0 && pct < 0.05) return underOne;
  final v = _jsRound(pct * 10) / 10;
  if (v == 0) return '0.0%';
  final body = v.abs().toStringAsFixed(1);
  return v < 0 ? '$_minus$body%' : '$body%';
}

/// [part] 가 [total] 중 차지하는 비중. [total] 이 0 이하면 0.0%.
String formatShareOf(num part, num total, {required String underOne}) =>
    formatShare(total <= 0 ? 0 : part * 100 / total, underOne: underOne);

/// 진행률 — "76%". 정수 반올림이 기본이다(웹 `formatPercent` "progress" 와 같은 식). 반올림하면 100 이 되는 값만 예외 —
/// 100 미만은 99%(99.6), 100 초과는 101%(100.3), 정확히 100 만 "100%"(100 을 넘나드는 상태가 글에서 사라지지 않게).
/// 음수는 크기를 같은 식으로 센 뒤 U+2212 를 붙인다(반올림해서 0 이면 부호 없음). 유한하지 않은 값은 "—".
/// 막대가 넘치는 100 초과는 그대로 둔다(호출처가 자른다).
String formatProgress(num pct) {
  final v = pct.toDouble();
  if (!v.isFinite) return '—';
  if (v < 0) {
    final body = formatProgress(-v);
    return body == '0%' ? body : '$_minus$body';
  }
  final r = _jsRound(v).toInt();
  if (r == 100 && v != 100) return v < 100 ? '99%' : '101%';
  return '$r%';
}
