import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/format/format_locale.dart';

/// porest-desk-front `KRW(n, {sign, abs})` 포팅.
///
/// 천단위 콤마, 부호 옵션, 절댓값 옵션.
String krw(int n, {bool sign = false, bool abs = false}) {
  final v = abs ? n.abs() : n;
  // 천단위 콤마 그룹핑은 ko/en 동일('10,000') → ko 출력 회귀 0. locale 만 현재값으로.
  // 음수 부호는 intl 의 ASCII '-' 가 아니라 U+2212 다(chart.md "빼기는 U+2212").
  // 절댓값을 포맷한 뒤 앞에 붙인다. 호출부가 abs/sign 으로 직접 붙이는 자리와 같은 모양이다.
  final formatted = NumberFormat.decimalPattern(
    localeIsEn() ? 'en' : 'ko_KR',
  ).format(v.abs());
  if (v < 0) return '$kMinus$formatted';
  if (sign && n > 0) return '+$formatted';
  return formatted;
}

/// web `HIDE_AMOUNTS_MASK` 정합 — 기본 마스크는 점 6개. 작은/compact 표기는 `mask: '••••'`(4개).
const String kHideMask = '••••••';

/// 금액 숨김(마스킹) 토글이 켜진 경우 [mask] 점으로 대체.
String krwMasked(
  int n,
  bool masked, {
  bool sign = false,
  bool abs = false,
  String mask = kHideMask,
}) {
  if (masked) return mask;
  return krw(n, sign: sign, abs: abs);
}

/// 부호(±)·단위(원) 포함 금액 표기. masked면 부호·원 없이 [mask] 점만 노출.
///
/// web `MaskAmount`(부호를 마스크 안에 포함) + `HideUnit`(원) 정합 —
/// 금액을 숨겼을 때 `+`/`-`·`원` 이 같이 사라지고 점만 남도록.
String krwSigned(
  int n,
  bool masked, {
  String sign = '',
  bool unit = false,
  String mask = kHideMask,
}) {
  if (masked) return mask;
  // 통화 단위: ko '원' 접미 / en '₩' 접두 (부호는 항상 최선두). unit=false 면 숫자만.
  // 음수면 U+2212 도 ₩ 앞에 온다 — `−₩1,000` (웹 money() en 과 같다).
  if (unit && localeIsEn()) {
    return n < 0 ? '$sign$kMinus₩${krw(n.abs())}' : '$sign₩${krw(n)}';
  }
  return '$sign${krw(n)}${unit ? '원' : ''}';
}

/// 통화 단위 라벨(정적) — ko '원' / en '₩'.
///
/// 입력필드 suffixText·표시 라벨 등 **독립 단위 라벨 자리** 정적 분기용.
/// (금액+단위 동시 포맷은 [krwSigned]`(unit:true)` 사용 — en 은 접두 ₩.)
String wonUnit() => localeIsEn() ? '₩' : '원';

/// 손으로 붙이는 금액 부호는 U+2212(−) 하나로 통일한다.
///
/// ASCII 하이픈과 폭이 달라 한 카드 안에서 섞이면 tabular figures 정렬이 어긋난다
/// (QA #22 — 홈 9월 카드에서 지출은 `−7,560`, 잔액은 `-7,560` 이었다).
/// web `shared/lib/groo/format.ts` 의 `MINUS` 미러.
const String kMinus = '−';

/// **크기만** 들고 있는 값(총 부채·지출처럼 절댓값으로 오는 값) 앞에 붙일 부호.
/// web `shared/lib/groo/format.ts` 의 `minusOf` 미러 — 같은 화면을 두 플랫폼이 그린다.
///
/// - `0` → 부호 없음. 빈 계정에서 `−0원` 으로 보이던 걸 `0원` 으로 (QA #1 · #69).
/// - 음수 → `+`. 크기값이 음수로 오는 자리가 있다 — 총 부채는 선결제한 카드 때문에
///   음수가 될 수 있다(서버가 유형 기준으로 세면서 `totalDebt = −Σ부채군` 이 되어
///   선결제 양수가 부채를 깎는다). 그때 `−` 를 그대로 박으면 `−-356,800` 처럼
///   부호가 겹쳐 찍힌다.
///
/// 값은 반드시 `krwSigned(v.abs(), ...)` 처럼 **절댓값**으로 넘겨라.
String minusOf(int n) => n > 0 ? kMinus : (n < 0 ? '+' : '');

/// [minusOf] 의 거울 — **크기만** 들고 있는 수입·이익 값 앞에 붙일 부호.
///
/// `+{KRW(v)}` 처럼 플러스를 문자로 박아 두던 자리를 이걸로 바꾼다.
/// `0` → 부호 없음. 반복 수입이 하나도 없을 때 `+0` 으로 보이던 걸 `0` 으로
/// (QA #1 이 지출 쪽 `−0` 을 잡을 때 수입 쪽은 남아 있었다).
///
/// 규칙을 두 벌 쓰지 않으려고 [minusOf] 에 부호를 뒤집어 위임한다 — "0 이면
/// 부호 없음 · 반대 부호로 폴백" 이 한 곳에만 있어야 웹·앱이 같은 글자를 낸다.
///
/// 값은 반드시 `krwSigned(v.abs(), ...)` 처럼 **절댓값**으로 넘겨라.
String plusOf(int n) => minusOf(-n);

/// 규모 값 줄임 — 한국어 조 · 억 · 만, 영어 T · B · M · K(차트 축과 같은 셈 — 한 단위 · 소수 한 자리).
/// Web `shared/lib/groo/format.ts` 의 `formatChartAxis` 와 **한 글자도 갈리면
/// 안 된다** — 같은 화면을 두 플랫폼이 그린다.
///
/// **사용자 돈(거래 · 잔액 · 평가액)에는 쓰지 않는다** — 돈은 줄이지 않는다(international-design, groo-design #252). 줄임은
/// 규모를 보이는 값(시가총액 · 주식 수)에만 쓴다: `1.2조` · `₩1.2T`.
///
/// 규칙은 구간과 상관없이 하나다(QA #73). 한국어는 만 단위, 영어는 천 단위로 센다.
///
///   ko  n < 1만   정수 + 천단위 콤마   `5,000` · `9,999`
///       1만 ~     만                 `1만` · `1.2만` · `1,230.5만`
///       1억 ~     억                 `1.2억` · `5억` · `9,999억`
///       1조 ~     조                 `1조` · `1.2조`
///   en  n < 1K    정수               `999`
///       1K ~      K                  `1K` · `1.2K` · `999K`
///       1M ~ · 1B ~ · 1T ~           `1.2M` · `1B` · `1.2T`
///
/// 값은 늘 소수 첫째 자리까지 쓰고 `.0` 은 뗀다 — `5.0만` 이 아니라 `5만`(QA #73).
/// 예전엔 구간마다 정밀도가 달라(10억 위는 정수 억, 10만 위는 정수 만) 같은 축
/// 안에서 규칙이 바뀌었다. 1만 미만에 천단위 콤마가 없던 것도 여기서 같이 잡힌다
/// (QA #70 — 웹은 `5,000`, 앱만 `5000` 이었다). 영어는 예전엔 intl compact(유효 숫자 셋 — `1.23K`)라 한국어와 셈이 달랐다.
///
/// 반올림한 값이 다음 단위에 닿으면 그 단위로 올린다 — 99,999,999 는 `10,000만`
/// 이 아니라 `1억`, 999,999,999,999 는 `10,000억` 이 아니라 `1조`, 영어 999,999 는 `1,000K` 가 아니라 `1M` 이다.
///
/// 음수 부호는 [kMinus](U+2212).
String formatChartAxis(double v) {
  final en = localeIsEn();
  final units = en ? const ['', 'K', 'M', 'B', 'T'] : const ['', '만', '억', '조'];
  final base = en ? 1000.0 : 10000.0;
  var scaled = v.abs();
  var unit = 0;
  while (unit < units.length - 1) {
    // 판정은 **찍을 값**으로 한다 — 9,999.9999만 은 소수 한 자리로 반올림하면
    // 10,000.0만 이고, 그건 곧 1억이다. 원값으로 재면 `10,000.0만` 이 나온다.
    final shown = unit == 0
        ? scaled.roundToDouble()
        : (scaled * 10).roundToDouble() / 10;
    if (shown < base) {
      scaled = shown;
      break;
    }
    scaled /= base;
    unit++;
  }

  // 정수부는 천단위 콤마, 소수부는 한 자리(0 이면 뗀다).
  final tenths = (scaled * 10).round();
  final head = NumberFormat.decimalPattern(
    en ? 'en' : 'ko_KR',
  ).format(tenths ~/ 10);
  final frac = tenths % 10;
  final body = '$head${frac == 0 ? '' : '.$frac'}${units[unit]}';
  return v < 0 ? '$kMinus$body' : body;
}
