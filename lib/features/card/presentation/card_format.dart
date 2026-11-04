import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 카드 혜택 화면의 글 만들기(I-20 E 31 ~ 34) — 웹 `card-format.ts` 와 같은 갈래 · 같은 글이다.

const _htmlNamed = {
  'nbsp': '\u00a0',
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'middot': '·',
  'hellip': '…',
  'rarr': '→',
  'larr': '←',
  'uarr': '↑',
  'darr': '↓',
  'times': '×',
  'divide': '÷',
  'mdash': '—',
  'ndash': '–',
  'lsquo': '‘',
  'rsquo': '’',
  'ldquo': '“',
  'rdquo': '”',
  'copy': '©',
  'reg': '®',
  'trade': '™',
  'bull': '•',
  'deg': '°',
};

/// HTML 엔티티 풀기 — 웹 `shared/lib/html.ts` `decodeHtml` 과 같은 규칙(숫자 · 16진 · 이름표, 모르는 이름은 그대로).
String decodeHtml(String? input) {
  if (input == null || input.isEmpty) return '';
  int? safe(int? n) => n != null && n >= 0 && n <= 0x10FFFF ? n : null;
  return input
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
        final n = safe(int.tryParse(m[1]!));
        return n == null ? m[0]! : String.fromCharCode(n);
      })
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
        final n = safe(int.tryParse(m[1]!, radix: 16));
        return n == null ? m[0]! : String.fromCharCode(n);
      })
      .replaceAllMapped(
        RegExp(r'&([a-zA-Z][a-zA-Z0-9]+);'),
        (m) => _htmlNamed[m[1]!] ?? m[0]!,
      );
}

/// 글 속 네 자리 이상 숫자에 쉼표 — 서버 라벨 원문 "국내 5000원" 을 "국내 5,000원" 으로 보이기만 한다.
String commaDigits(String text) =>
    text.replaceAllMapped(RegExp(r'\d{4,}'), (m) {
      // 너무 긴 숫자(int 를 넘는)는 원문 그대로 둔다
      final n = int.tryParse(m[0]!);
      return n == null ? m[0]! : krw(n);
    });

String _won(int amount) => krwSigned(amount, false, unit: true);

/// 줄의 연회비 글(E 32) — 금액 > 0 "연회비 {n}원" · 라벨만 "연회비 {라벨}" · 무료 "연회비 없음" · 모름 "연회비 정보 없음".
/// `annualFee` 가 null 이면 서버가 "연회비 정보를 모른다" 고 알린 것이고, 금액 0 · 라벨 없음은 안 받는 카드다.
String annualFeeRowText(AppLocalizations l, CardAnnualFee? fee) {
  if (fee == null) return l.cardRowFeeUnknown;
  final amount = fee.amount ?? 0;
  if (amount > 0) return l.cardRowFeeAmount(_won(amount));
  final label = fee.label;
  if (label != null && label.isNotEmpty) {
    return l.cardRowFeeLabel(commaDigits(decodeHtml(label)));
  }
  return l.cardRowFeeNone;
}

/// 줄의 실적 글 — "실적 {n}원" · "실적 없음".
String performanceRowText(AppLocalizations l, CardPerformance? perf) {
  if (perf != null && perf.isRequired == 'Y') {
    final amount = perf.requiredAmount ?? 0;
    if (amount > 0) return l.cardPerfMonthly(_won(amount));
    final text = perf.requiredText;
    if (text != null && text.isNotEmpty) return decodeHtml(text);
  }
  return l.cardPerfNone;
}

/// 상세 키-값의 연회비(E 34) — 라벨 그대로, 4자리 이상 숫자에 쉼표.
String annualFeeDetailText(AppLocalizations l, CardAnnualFee? fee) {
  if (fee == null) return l.cardFeeUnknown;
  final amount = fee.amount ?? 0;
  if (amount > 0) return l.cardFeeDomesticOnly(_won(amount));
  final label = fee.label;
  return label != null && label.isNotEmpty
      ? commaDigits(decodeHtml(label))
      : l.cardFeeFree;
}

/// 상세 키-값의 전월 실적 — "{n}원 이상" · "실적 없음".
String performanceDetailText(AppLocalizations l, CardPerformance? perf) {
  if (perf != null && perf.isRequired == 'Y') {
    final amount = perf.requiredAmount ?? 0;
    if (amount > 0) return l.cardPerfMin(_won(amount));
    final text = perf.requiredText;
    if (text != null && text.isNotEmpty) return decodeHtml(text);
  }
  return l.cardPerfNone;
}

/// 혜택 유형 글 — 할인 · 적립 · 마일리지(서버 값은 셋뿐이다). 모르는 값이면 null.
String? benefitTypeText(AppLocalizations l, String? type) => switch (type) {
  'DISCOUNT' => l.cardBenefitTypeDiscount,
  'POINT' => l.cardBenefitTypePoint,
  'MILEAGE' => l.cardBenefitTypeMileage,
  _ => null,
};

/// "{카드사} · {신용|체크} · {혜택 유형}" 세 조각(없는 조각은 뺀다).
List<String> cardMetaParts(AppLocalizations l, CardCatalogSummary s) => [
  decodeHtml(s.company?.name).trim(),
  switch (s.cardType) {
    'CREDIT' => l.assetCardShortCredit,
    'CHECK' => l.assetCardShortCheck,
    _ => '',
  },
  benefitTypeText(l, s.benefitType) ?? '',
].where((x) => x.trim().isNotEmpty).toList();

/// 거르기 값 — 서버는 DISCOUNT · MILEAGE · POINT 셋뿐이다("캐시백" 칩은 걷었다 — E 31).
const List<String?> kBenefitFilterValues = [
  null,
  'DISCOUNT',
  'POINT',
  'MILEAGE',
];
const List<String?> kTypeFilterValues = [null, 'CREDIT', 'CHECK'];
