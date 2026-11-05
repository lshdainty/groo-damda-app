import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/format/krw.dart';

/// 지원 통화 — 외화통장·해외 결제에서 쓴다.
///
/// 통화명은 다국어 대상이 아니다. ISO 코드(USD)와 기호($)는 로케일과 무관한 국제
/// 표기라 화면에도 `$ USD` 처럼 코드로 보여 준다(브랜드 고유명과 같은 취급).
class CurrencyOption {
  const CurrencyOption(this.code, this.symbol);

  final String code;
  final String symbol;
}

const String kDefaultCurrency = 'KRW';

const List<CurrencyOption> kCurrencies = [
  CurrencyOption('KRW', '₩'),
  CurrencyOption('USD', r'$'),
  CurrencyOption('JPY', '¥'),
  CurrencyOption('EUR', '€'),
  CurrencyOption('CNY', '¥'),
  CurrencyOption('GBP', '£'),
  CurrencyOption('AUD', r'A$'),
  CurrencyOption('CAD', r'C$'),
  CurrencyOption('HKD', r'HK$'),
  CurrencyOption('SGD', r'S$'),
  CurrencyOption('THB', '฿'),
  CurrencyOption('VND', '₫'),
  CurrencyOption('TWD', r'NT$'),
  CurrencyOption('CHF', 'CHF'),
];

String currencySymbol(String? code) {
  if (code == null) return '';
  for (final c in kCurrencies) {
    if (c.code == code) return c.symbol;
  }
  return code;
}

bool isForeignCurrency(String? code) =>
    code != null && code.isNotEmpty && code != kDefaultCurrency;

/// 라벨 괄호 안에 붙는 통화 단위 — `잔액 (원)` · `잔액 ($)` 의 그 자리.
///
/// 잔액·한도 라벨이 `(원)` 으로 박혀 있어 USD 를 골라도 원화처럼 보였다(QA 12차).
/// 단위는 **고른 통화**를 따라야 한다.
///
/// 기호는 새로 세지 않고 위 [kCurrencies] 한 벌을 그대로 쓴다 — 두 벌이 되면 통화를
/// 하나 늘릴 때 한쪽만 늘어나고, 그 어긋남은 화면에서만 보인다.
///
/// **원화만 로케일을 탄다.** 한국어 화면은 `₩` 를 안 쓰고 `원` 을 접미로 붙이고
/// (`krwSigned` · [wonUnit] 이 이미 그 규칙이다), 영어 화면은 `₩10,000` 처럼 앞에
/// 붙인다. 그래서 여기서도 ko `원` / en `₩` 로 갈린다 — `잔액 (₩)` 도 `Balance (원)`
/// 도 그 화면에서는 남의 글자다. 나머지 통화는 로케일과 무관한 국제 표기라 기호 그대로다.
///
/// 통화를 모르면(`null`·빈 문자열) 원화로 본다 — 안 적힌 자산은 원화라는 게
/// [kDefaultCurrency] 다. 모르는 코드는 코드를 그대로 낸다(빈 괄호보다 낫다).
///
/// **웹도 같은 규칙을 쓴다** — `shared/lib/groo/currency.ts` 의 `currencyUnit`
/// (desk-front #369). 갈리면 같은 자산을 웹과 앱에서 다른 단위로 읽는다.
String currencyUnit(String? code) =>
    (code == null || code.isEmpty || code == kDefaultCurrency)
    ? wonUnit()
    : currencySymbol(code);

/// 원 통화 금액 표기 — `$5.50` / `¥1,280`.
///
/// 소수 자리는 통화별로 다르다(엔·원·동은 0). 기호는 우리가 붙이므로 숫자만 뽑는다.
String formatOriginalAmount(double amount, String code, String locale) {
  final digits = (code == 'JPY' || code == 'KRW' || code == 'VND') ? 0 : 2;
  final f = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: digits,
  );
  // 음수는 기호 앞에 U+2212 — intl 은 숫자 앞에 ASCII '-' 를 붙여 `$-5.50` 이 된다.
  final body = '${currencySymbol(code)}${f.format(amount.abs())}';
  return amount < 0 ? '$kMinus$body' : body;
}

/// 자산 금액 표기 — 외화 예수금 · 잔액 · 이체 금액은 서버가 **정수 1단위**로 저장하므로 소수 없이 `$100` · `−$1,000`(I-13).
///
/// 시세 · 단가 · 해외 결제의 원 통화 금액처럼 원래 소수가 있는 값은 [formatOriginalAmount](소수 자리 늘 보임) 그대로다.
/// 웹 `shared/lib/groo/currency.ts` 의 `formatAssetAmount` 와 같은 규칙이다.
String formatAssetAmount(num amount, String code, String locale) {
  final f = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0);
  final body = '${currencySymbol(code)}${f.format(amount.abs().round())}';
  return amount < 0 ? '$kMinus$body' : body;
}

/// 옛 식(balance × 환율) — 서버 원화 합계 칸(`balanceInKrw`)이 없는 옛 서버일 때만 쓰는 폴백이다.
///
/// 투자 자산의 보유 평가는 원화라 balance 전체에 환율을 곱하면 보유분이 두 번 환산된다(I-13 길 A). 화면은
/// `features/asset/domain/asset_krw.dart` 의 `assetKrw` 를 거친다 — 서버 칸이 있으면 그 값, 없을 때만 여기로 온다.
int balanceInKrw(int balance, String? currency, double? exchangeRate) {
  if (!isForeignCurrency(currency) ||
      exchangeRate == null ||
      exchangeRate <= 0) {
    return balance;
  }
  return (balance * exchangeRate).round();
}
