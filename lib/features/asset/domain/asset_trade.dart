import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:groo_damda_app/core/format/decimal_string.dart';

part 'asset_trade.freezed.dart';
part 'asset_trade.g.dart';

/// 투자 자산의 매수·매도 거래 — 백엔드 `AssetTradeApiDto.TradeResponse` 미러.
///
/// 예수금이 줄고 느는 진짜 사건이다. 이게 없으면 평가액 갱신을 보고 예수금을
/// 추측해야 하는데, 시세 변동·추가 매수·재등록이 전부 같은 갱신으로 들어와 구분되지 않는다.
///
/// `OPENING` 은 앱을 쓰기 전부터 갖고 있던 보유라 돈이 오가지 않는다.
@freezed
abstract class AssetTrade with _$AssetTrade {
  const factory AssetTrade({
    required int rowId,
    required int assetRowId,
    required String tradeType, // 'OPENING' | 'BUY' | 'SELL'
    String? holdingType, // 'STOCK' | 'GOLD' | 'CRYPTO'
    /// 종목 식별자 — 연동은 토스 종목코드, 미연동은 항목명.
    required String holdingKey,
    @Default(false) bool linked,

    /// 소수 허용이라 문자열로 주고받는다(AssetHolding.quantity 와 같은 이유).
    /// 서버 계약이 BigDecimal 이라 JSON 숫자로 온다 — 컨버터 없이 캐스트하면 터진다.
    @JsonKey(fromJson: decimalStringFromJson) String? quantity,

    /// 거래대금 — 수수료 제외.
    int? amount,
    int? fee,

    /// 실현손익 (매도 전용). 이익 양수 / 손실 음수.
    int? realizedPl,
    String? tradeDate,
    String? description,

    /// 결제 계좌 — 지정하면 증권계좌 예수금 대신 이 계좌에서 오간다.
    int? settlementAssetRowId,
  }) = _AssetTrade;

  factory AssetTrade.fromJson(Map<String, dynamic> json) =>
      _$AssetTradeFromJson(json);
}

/// 매매 미리보기 — 백엔드 `AssetTradeApiDto.TradePreviewResponse` 미러.
///
/// 실현손익·평균단가는 이동평균 원가 규칙을 타는데, 그 규칙을 앱에도 적어 두면
/// 서버와 갈라진다. Dart 의 `/` 는 double 나눗셈이라 끝자리도 어긋난다.
@freezed
abstract class AssetTradePreview with _$AssetTradePreview {
  const factory AssetTradePreview({
    /// 이번에 파는 만큼의 취득원가 (매도 전용).
    int? soldCost,

    /// 실현손익 — 이익 양수 / 손실 음수 (매도 전용).
    int? realizedPl,

    /// 이 거래로 예수금이 움직이는 양 — 매수 음수 / 매도 양수.
    @Default(0) int cashDelta,

    /// 거래 후 예수금.
    @Default(0) int cashAfter,

    /// 예수금이 모자라 결제 계좌에서 끌어올 금액(결제 계좌 통화) — 0 이면 이체가 생기지 않는다.
    @Default(0) int fundingAmount,

    /// [cashDelta] · [cashAfter] 의 통화(투자 계좌 통화). 옛 서버면 없다.
    String? cashCurrency,

    /// [fundingAmount] 의 통화(결제 계좌 통화). 결제 계좌가 없거나 옛 서버면 없다.
    String? fundingCurrency,
  }) = _AssetTradePreview;

  factory AssetTradePreview.fromJson(Map<String, dynamic> json) =>
      _$AssetTradePreviewFromJson(json);
}
