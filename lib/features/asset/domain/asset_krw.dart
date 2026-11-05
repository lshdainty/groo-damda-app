import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';

// 자산 금액의 원화 셈(I-13 길 A) — 서버와 같은 한 식을 쓴다. 웹 `entities/asset/lib/asset-krw.ts` 와 같은 함수 · 같은 값이다.
//
// 투자 자산의 보유 평가(HOLDING)는 **원화**이고, 예수금(CASH)만 자산 통화다. 그래서 원화 합계는
// `round(예수금 × 환율) + 보유 평가` 다 — 서버 `Asset.balanceInKrw(cash, holding)` 와 같고, 응답 칸 `balanceInKrw` 가 그 값이다.
// 라이브 시세가 켜지면 보유 평가 자리만 라이브 원화 평가로 바꾼다. 통화는 바꾸지 않는다.
// 반올림은 서버와 같이 원 단위 HALF_UP(0.5 는 0 에서 먼 쪽 — Dart `round()` 가 그 규칙이다).

/// HALF_UP 정수 — 0.5 는 0 에서 먼 쪽(서버 BigDecimal HALF_UP 과 같다).
int halfUp(double x) => x.round();

/// 통화 1단위당 원화 — 원화 · 환율 없음 · 0 이하는 1(서버 normalizeRate 와 같다).
double krwRateOf(String? currency, double? exchangeRate) {
  if (!isForeignCurrency(currency) ||
      exchangeRate == null ||
      exchangeRate <= 0) {
    return 1;
  }
  return exchangeRate;
}

/// 자산 통화 금액 → 원화(정수, HALF_UP). 원화 자산은 그대로.
int toKrw(int amount, String? currency, double? exchangeRate) {
  final rate = krwRateOf(currency, exchangeRate);
  return rate == 1 ? amount : halfUp(amount * rate);
}

/// 예수금(자산 통화)의 원화 환산.
int cashInKrw(Asset a) => toKrw(a.cashBalance ?? 0, a.currency, a.exchangeRate);

/// 자산 한 건의 원화 합계 — 서버 `balanceInKrw` 를 읽는다. 칸이 없을 때(옛 서버)만 옛 식(balance × 환율)으로 폴백.
/// 줄 · 묶음 합계 · 상세 큰 금액이 모두 이 값을 본다.
int assetKrw(Asset a) =>
    a.balanceInKrw ?? balanceInKrw(a.balance ?? 0, a.currency, a.exchangeRate);

/// 라이브 원화 평가를 보유 평가 자리에만 얹는다 — 통화 · 환율은 그대로, 원화 합계는 round(예수금 × 환율) + 라이브.
/// `balance` 는 서버의 옛 뜻(예수금 + 보유)을 따라 맞춰 둘 뿐 원화 셈에는 쓰지 않는다.
Asset withLiveHolding(Asset a, int liveKrw) => a.copyWith(
  holdingBalance: liveKrw,
  balance: (a.cashBalance ?? 0) + liveKrw,
  balanceInKrw: cashInKrw(a) + liveKrw,
);

/// 이체 받는 금액 — 두 계좌 통화가 다를 때만 `round(금액 × 보내는 환율 ÷ 받는 환율)` HALF_UP(반올림은 마지막 한 번, 서버
/// `AssetTransfer.resolveToAmount` 와 같다). 같은 통화 · 어느 쪽을 모르면 null.
int? transferReceiveAmount(int amount, Asset? from, Asset? to) {
  if (from == null || to == null) return null;
  final fromCode = (from.currency ?? '').isEmpty
      ? kDefaultCurrency
      : from.currency!;
  final toCode = (to.currency ?? '').isEmpty ? kDefaultCurrency : to.currency!;
  if (fromCode == toCode) return null;
  return halfUp(
    amount *
        krwRateOf(from.currency, from.exchangeRate) /
        krwRateOf(to.currency, to.exchangeRate),
  );
}

/// 계좌 통화 — 안 적힌 자산은 원화.
String assetCurrencyOf(Asset? a) =>
    (a?.currency ?? '').isEmpty ? kDefaultCurrency : a!.currency!;
