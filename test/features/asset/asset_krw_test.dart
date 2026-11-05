// 외화 투자 자산의 원화 합계 — 서버와 같은 한 식(I-13 길 A): round(예수금 × 환율) + 보유 평가(원화).
// 웹 `entities/asset/lib/asset-krw.test.ts` 와 같은 기대값이다(통화는 바꾸지 않는다 — 라이브는 보유 평가 자리에만).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_krw.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_parts.dart';

/// 시드: USD · 환율 1,300 · 예수금 $100 · 보유 평가 10,000,000원(서버 응답 칸 그대로)
Asset _usd({
  int balance = 10000100,
  int cashBalance = 100,
  int holdingBalance = 10000000,
  int? balanceInKrw = 10130000,
  double exchangeRate = 1300,
}) => Asset(
  rowId: 1,
  assetName: '해외 증권계좌',
  assetType: 'INVESTMENT',
  balance: balance,
  cashBalance: cashBalance,
  holdingBalance: holdingBalance,
  balanceInKrw: balanceInKrw,
  currency: 'USD',
  exchangeRate: exchangeRate,
  isIncludedInTotal: 'Y',
);

Asset _won({
  String assetType = 'BANK_ACCOUNT',
  int balance = 1000000,
  int cashBalance = 1000000,
  int holdingBalance = 0,
  int? balanceInKrw = 1000000,
}) => Asset(
  rowId: 2,
  assetName: '생활비 통장',
  assetType: assetType,
  balance: balance,
  cashBalance: cashBalance,
  holdingBalance: holdingBalance,
  balanceInKrw: balanceInKrw,
  currency: 'KRW',
  exchangeRate: 1,
  isIncludedInTotal: 'Y',
);

Asset _acc(int rowId, String currency, double rate) => Asset(
  rowId: rowId,
  assetName: '계좌 $rowId',
  assetType: 'BANK_ACCOUNT',
  currency: currency,
  exchangeRate: rate,
);

void main() {
  group('① 외화 투자 1건 — 줄 금액은 서버 식과 같은 값', () {
    test('서버 balanceInKrw 를 그대로 읽는다: 10,130,000 (13,000,130,000 이 아니다)', () {
      expect(assetKrw(_usd()), 10130000);
    });

    test(
      '라이브 보유 10,000,000원 → round(100 × 1,300) + 10,000,000 = 10,130,000, 통화는 그대로',
      () {
        final live = withLiveHolding(_usd(holdingBalance: 9000000), 10000000);
        expect(assetKrw(live), 10130000);
        expect(live.currency, 'USD');
        expect(live.exchangeRate, 1300);
        expect(live.holdingBalance, 10000000);
        expect(live.cashBalance, 100);
      },
    );

    test('수동 보유 5,000원 → 100 × 1,300 + 5,000 = 135,000', () {
      final manual = _usd(
        balance: 5100,
        holdingBalance: 5000,
        balanceInKrw: 135000,
      );
      expect(assetKrw(manual), 135000);
    });

    test('옛 서버(balanceInKrw 없음)만 balance × 환율로 폴백', () {
      final old = _usd(balanceInKrw: null, balance: 100, holdingBalance: 0);
      expect(assetKrw(old), 130000);
    });
  });

  group('② 외화 투자 + 원화 계좌 — 묶음 합계 경로(assetSumIncluded)', () {
    test('두 값의 합: 10,130,000 + 1,000,000', () {
      final list = applyLiveValuation([_usd(), _won()], {1: 10000000});
      expect(assetSumIncluded(list), 11130000);
    });

    test('원화 자산은 라이브를 얹어도 예수금 + 라이브 그대로', () {
      final krwInvest = _won(
        assetType: 'INVESTMENT',
        cashBalance: 50000,
        holdingBalance: 900000,
        balance: 950000,
        balanceInKrw: 950000,
      );
      final live = withLiveHolding(krwInvest, 1000000);
      expect(assetKrw(live), 1050000);
      expect(live.currency, 'KRW');
    });

    test('원화 자산(라이브 없음)은 지금 값 그대로', () {
      expect(assetKrw(_won()), 1000000);
      expect(assetKrw(_won(balanceInKrw: null)), 1000000);
    });
  });

  group('③ 순자산 보정 — 라이브 − DB 보유분이 같은 단위(원화)로 빠진다', () {
    test('보유 평가는 외화 자산에서도 원화라 환율을 곱하지 않는다', () {
      final db = _usd(holdingBalance: 9900000, balance: 9900100);
      const liveKrw = 10000000;
      // 서버 순자산 기여 = round(100 × 1,300) + 9,900,000 = 10,030,000 → 보정 뒤 10,130,000 = 줄 금액
      final serverPart = cashInKrw(db) + db.holdingBalance!;
      final delta = liveValuationDelta([db], {1: liveKrw});
      expect(serverPart + delta, assetKrw(withLiveHolding(db, liveKrw)));
    });
  });

  group('④ 환율 없는 외화 자산', () {
    test('환율이 1 · 0 이면 환산 없이 그대로(서버 normalizeRate 와 같다)', () {
      expect(cashInKrw(_usd(exchangeRate: 1)), 100);
      expect(cashInKrw(_usd(exchangeRate: 0)), 100);
      final live = withLiveHolding(_usd(exchangeRate: 1), 500000);
      expect(assetKrw(live), 500100);
    });
  });

  group('⑤ 예수금 0 이면 평가금액만', () {
    test('라이브 2,000,000 → 2,000,000', () {
      expect(assetKrw(withLiveHolding(_usd(cashBalance: 0), 2000000)), 2000000);
    });
    test('음수 예수금도 부호를 살려 HALF_UP', () {
      expect(cashInKrw(_usd(cashBalance: -900)), -1170000);
      expect(halfUp(-1.5), -2);
      expect(halfUp(0.5), 1);
    });
  });

  group('이체 받는 금액 — 서버 resolveToAmount 와 같은 식(HALF_UP, 마지막 한 번)', () {
    final krwAcc = _acc(10, 'KRW', 1);
    final usdAcc = _acc(11, 'USD', 1300);
    final eurAcc = _acc(12, 'EUR', 1450);
    test('원 → USD: 1,300,000원 → \$1,000', () {
      expect(transferReceiveAmount(1300000, krwAcc, usdAcc), 1000);
    });
    test('USD → 원: \$1,000 → 1,300,000원', () {
      expect(transferReceiveAmount(1000, usdAcc, krwAcc), 1300000);
    });
    test('USD → EUR: \$1,000 → €897 (896.55)', () {
      expect(transferReceiveAmount(1000, usdAcc, eurAcc), 897);
    });
    test('같은 통화(USD 1,300 → USD 1,310)는 null — 보낸 만큼 받는다', () {
      expect(
        transferReceiveAmount(1000, usdAcc, _acc(13, 'USD', 1310)),
        isNull,
      );
      expect(transferReceiveAmount(50000, krwAcc, krwAcc), isNull);
    });
    test('어느 계좌를 모르면 null', () {
      expect(transferReceiveAmount(1000, usdAcc, null), isNull);
    });
  });

  group('이체 응답 toAmount', () {
    test('통화 다른 이체는 받는 금액이 실리고, 같은 통화 · 옛 서버는 null', () {
      final t = AssetTransfer.fromJson({
        'rowId': 1,
        'fromAssetRowId': 10,
        'toAssetRowId': 11,
        'amount': 1300000,
        'toAmount': 1000,
      });
      expect(t.toAmount, 1000);
      final same = AssetTransfer.fromJson({
        'rowId': 2,
        'fromAssetRowId': 10,
        'toAssetRowId': 12,
        'amount': 50000,
      });
      expect(same.toAmount, isNull);
    });
  });

  group('formatAssetAmount — 외화 예수금 · 잔액 · 이체는 정수 1단위(I-13)', () {
    test('소수 없이 — \$100 · \$1,000 · €897', () {
      expect(formatAssetAmount(100, 'USD', 'ko'), r'$100');
      expect(formatAssetAmount(1000, 'USD', 'en'), r'$1,000');
      expect(formatAssetAmount(897, 'EUR', 'ko'), '€897');
    });
    test('음수는 기호 앞 U+2212', () {
      expect(formatAssetAmount(-900, 'USD', 'ko'), '−\$900');
    });
    test('시세 · 단가는 지금 규칙(formatOriginalAmount) 그대로 — 소수 둘째 자리', () {
      expect(formatOriginalAmount(100, 'USD', 'en'), r'$100.00');
    });
  });

  group('주간 추이 점 — 원화 합계를 그린다(⑧)', () {
    test('balanceInKrw 가 있으면 그 값, 없으면(옛 서버) balance', () {
      // 같은 시드의 주간 점: balance 10,000,100(옛 뜻) · balanceInKrw 10,130,000
      final p = AssetBalancePoint.fromJson({
        'weekStart': '2026-11-02',
        'balance': 10000100,
        'balanceInKrw': 10130000,
      });
      expect(p.krwOrBalance, 10130000);
      final old = AssetBalancePoint.fromJson({
        'weekStart': '2026-11-02',
        'balance': 130000,
      });
      expect(old.balanceInKrw, isNull);
      expect(old.krwOrBalance, 130000);
    });
  });
}
