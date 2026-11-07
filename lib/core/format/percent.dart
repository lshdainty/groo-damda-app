/// 퍼센트 표기 — 뜻이 셋이다(사용자 결정 2026-11-07 "B3 1A"). 한 함수로 합치지 않는다.
///
/// - **비중**(전체 중 몫: 도넛 범례 · 종목 구성 등) = [formatShare] — 소수 첫째 자리 늘 한 자리
///   ("30.0%"). 0 자리면 범례 합이 101% 가 되기 때문이다.
/// - **진행률**(예산 이행 · 사용 · 저축 달성 · 저축률 · 할인율) = [formatProgress] — 정수("76%").
///   막대 · 말풍선 · 범례 · 화면 낭독 이름이 같은 값이다.
/// - **등락률 · 수익률** = `change_rate.dart` 의 `formatChangeRate` — 둘째 자리. 여기서 부르지 않고
///   그대로 둔다(거절된 안: 합치기).
library;

/// 비중 — "30.0%". 0 은 "0.0%", 0 보다 크고 0.05% 미만은 [underOne]("0.1% 미만" · "<0.1%" —
/// 로케일 문구라 호출처가 `l.percentUnderTenth` 를 넘긴다). 음수 · NaN 은 0 으로 본다.
String formatShare(double pct, {required String underOne}) {
  if (pct.isNaN || pct <= 0) return '0.0%';
  if (pct < 0.05) return underOne;
  return '${pct.toStringAsFixed(1)}%';
}

/// [part] 가 [total] 중 차지하는 비중. [total] 이 0 이하면 0.0%.
String formatShareOf(num part, num total, {required String underOne}) =>
    formatShare(total <= 0 ? 0 : part * 100 / total, underOne: underOne);

/// 진행률 — "76%". 정수로 반올림한다. 막대가 넘치는 100 초과는 그대로 둔다(호출처가 자른다).
String formatProgress(num pct) => '${pct.isNaN ? 0 : pct.round()}%';
