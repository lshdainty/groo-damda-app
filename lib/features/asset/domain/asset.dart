import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:groo_damda_app/core/format/decimal_string.dart';

part 'asset.freezed.dart';
part 'asset.g.dart';

/// 백엔드 `AssetApiDto.AssetResponse` 1:1 매핑.
@freezed
abstract class Asset with _$Asset {
  const factory Asset({
    required int rowId,
    int? userRowId,
    required String assetName,
    required String
    assetType, // 'CASH' | 'BANK_ACCOUNT' | 'CARD' | 'INVESTMENT' | ...
    int? balance,

    /// 예수금·현금 잔액 (투자 계좌의 매수 대기 자금). balance = cashBalance + holdingBalance.
    int? cashBalance,

    /// 보유 종목 평가금액. 보유가 없으면 0.
    int? holdingBalance,
    String? currency,

    /// 원화 환산율 (통화 1단위당 원화). KRW 는 1 — 예수금(cashBalance)에만 곱한다(보유 평가는 원화, I-13 길 A).
    double? exchangeRate,

    /// 원화 합계 — 서버 한 식 `round(cashBalance × exchangeRate) + holdingBalance`(I-13 길 A). 줄 · 묶음 합계 · 상세 큰
    /// 금액 · 주간 추이가 이 값을 읽는다. 옛 서버면 없다(그때만 balance × 환율로 폴백 — `assetKrw`).
    int? balanceInKrw,
    String? color,
    String? institution,
    String? memo,
    int? sortOrder,
    String? isIncludedInTotal, // 'Y' | 'N'
    /// 이 자산의 금액만 가린다. 화면 카드 가리기와 별개 축, 합집합.
    String? isAmountHidden, // 'Y' | 'N'
    // 신용카드 청구 사이클 (CREDIT_CARD 전용, nullable).
    int? creditLimit, // 신용 한도
    int? paymentDay, // 결제일 (1~31)
    int? paymentAssetRowId, // 결제 출금계좌 자산 rowId
    /// 신용카드: 지금 이월 금액 — 카드를 만들 때 적은 "이전 미결제 사용액"(없으면 0).
    ///
    /// 카드 수정 폼의 그 칸은 **이 값**으로 채우고 `carryoverAmount` 키로 보낸다(D7).
    /// 지금 총 미결제 잔액([balance])이 아니다 — 그걸로 채워 저장하면 이월 거래가 잔액만큼
    /// 새로 생겨 빚이 두 배가 됐다(QA 23차 1). 신용카드가 아니거나 옛 서버면 null.
    int? carryoverAmount,

    /// 신용카드: 이월 거래가 든 회차의 결제일이 됐으면 true — 이월 금액 칸을 읽기
    /// 전용으로 둔다(D15). 서버도 값이 바뀌면 400 이다.
    @Default(false) bool carryoverLocked,

    /// 신용카드: **결제 대기 청구분** 칸(2026-09-22 사용자 결정) — 결제일 전에 카드를 등록할
    /// 때 따로 적은 지난달 청구분. 청구분이 있거나 등록한 달의 그 회차 결제일이 아직 안
    /// 왔으면 값(폼이 칸을 그린다), 아니면 null. 옛 서버도 null 이다.
    DueCarryover? dueCarryover,

    /// 신용카드: 결제일이 **오늘보다 뒤인 첫 회차**의 실제 결제일(`yyyy-MM-dd`).
    ///
    /// 결제일을 바꾸면 다음 회차부터 적용된다(D5) — 바꿀 때 아직 결제 전이던 회차는 옛
    /// 결제일로 나간다. 서버가 결제일 이력을 보고 그 회차의 날짜를 내려 준다. 그 회차는 이
    /// 날짜의 전달 1일~말일이고, 그 뒤 회차는 지금 [paymentDay] 로 결제된다. 결제일 없는
    /// 카드·신용카드가 아닌 자산·옛 서버면 null 이다(그때는 [paymentDay] 로만 센다).
    String? nextPaymentDate,

    /// 신용카드: **이 날짜(`yyyy-MM-dd`) 이하 거래는 결제가 끝난(닫힌) 회차**다.
    ///
    /// 결제일이 오늘(서울) 이하인 가장 최근 회차의 말일 — 서버가 결제일 이력·서울
    /// 시계로 정한다(D5·D11). 닫힌 회차에 걸린 변경은 기록만 바뀐다(D1). 결제일 없는
    /// 카드·신용카드가 아닌 자산·옛 서버면 null 이다(그때는 모두 열린 회차로 본다).
    String? cardClosedThrough,
    // 연결된 카드 상품 (카드 자산 전용, nullable) — 편집 진입 시 선택 상태 복원용.
    AssetCardCatalog? cardCatalog,
    // 토스 연동 (INVESTMENT 전용, nullable). 토스 현재가 × 보유수량으로 평가액 실시간 계산.
    // deprecated — holdings(다건)로 대체. 서버 필드 잔존으로 파싱만 유지.
    String? marketCode, // 종목 마스터 기준 시장코드 — 서버가 확정 못 했으면 없다
    String? tossSymbol, // 토스 연동 종목코드
    int? tossQuantity, // 토스 연동 보유수량
    // 보유 종목 (INVESTMENT 전용, design tossapi5) — linked(현재가×수량 연동) | manual(평가액 직접).
    // 구버전 서버 응답엔 없으므로 기본 빈 리스트로 안전 파싱.
    @Default(<AssetHolding>[]) List<AssetHolding> holdings,
    // 이번 달(1일~말일) 사용 합계 — CHECK_CARD 전용, 서버 계산(예정 제외·환불 상계).
    // 연결계좌 즉시 차감으로 잔액이 늘 0 이라, 행·상세는 잔액 대신 이 값을 보여준다.
    int? monthlyUsedAmount,
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}

/// 신용카드의 결제 대기 청구분 칸 — 백엔드 `AssetApiDto.DueCarryoverResponse`.
@freezed
abstract class DueCarryover with _$DueCarryover {
  const factory DueCarryover({
    /// 지금 청구분(없으면 0).
    @Default(0) int amount,

    /// 그 회차 결제일이 됐다 — 이미 결제에 들어가 칸이 읽기 전용이다(D15 와 같다).
    @Default(false) bool locked,

    /// 그 회차의 결제일(`yyyy-MM-dd`) — 칸 이름에 쓴다("9월 25일에 결제될 금액").
    String? paymentDate,
  }) = _DueCarryover;

  factory DueCarryover.fromJson(Map<String, dynamic> json) =>
      _$DueCarryoverFromJson(json);
}

/// 자산에 연결된 카드 상품 요약 — 백엔드 `CardCatalogBriefResponse` 미러.
/// 카드 편집 화면에서 기존 상품을 고른 상태로 되살리는 데 쓴다.
@freezed
abstract class AssetCardCatalog with _$AssetCardCatalog {
  const factory AssetCardCatalog({
    required int rowId,
    required String cardName,
    String? imgUrl,
    String? companyName,
    String? companyLogoUrl,
  }) = _AssetCardCatalog;

  factory AssetCardCatalog.fromJson(Map<String, dynamic> json) =>
      _$AssetCardCatalogFromJson(json);
}

/// 보유 유형 — 수량 단위가 다르다(주식 주 / 금 g / 코인 개).
/// 토스 시세 연동(linked)은 STOCK 만 가능 — 금·코인은 시세를 못 받는다.
enum AssetHoldingType {
  @JsonValue('STOCK')
  stock,
  @JsonValue('GOLD')
  gold,
  @JsonValue('CRYPTO')
  crypto;

  /// 서버 계약 값 — 요청 바디 직렬화용.
  String get wire => switch (this) {
    AssetHoldingType.stock => 'STOCK',
    AssetHoldingType.gold => 'GOLD',
    AssetHoldingType.crypto => 'CRYPTO',
  };
}

/// 투자 보유 종목 1건 — 백엔드 `holdings[]` 계약 미러.
/// linked=true → tossSymbol+quantity(현재가 연동), false → holdingName+holdingValue(직접 입력).
@freezed
abstract class AssetHolding with _$AssetHolding {
  const factory AssetHolding({
    int? rowId,
    // 구버전 응답엔 없음 — 없거나 모르는 값이면 주식으로 본다(하위호환).
    @JsonKey(unknownEnumValue: AssetHoldingType.stock)
    @Default(AssetHoldingType.stock)
    AssetHoldingType holdingType,
    @Default(false) bool linked,

    /// 종목 마스터 기준 시장코드(NAS·KOSPI …) — 선택.
    ///
    /// 같은 티커가 여러 시장에 걸린다(SPY·IVV·JEPI·SOXL). 종목 검색 응답이 이미 들고
    /// 있으니 저장할 때 그대로 돌려보내면 서버가 종목을 확정한다. 안 보내면 서버가
    /// 심볼로 해석하고, 여러 시장에 걸리면 비워 둔다.
    String? marketCode,
    String? tossSymbol,
    // 코인 0.05·금 3.75g 등 소수 허용. 미연동도 기록 가능(선택).
    // 서버 계약은 BigDecimal(decimal(28,8)) — double 로 담으면 십진 소수가 깎이므로
    // 클라이언트는 문자열로 들고 다닌다. 전송도 문자열 그대로(Jackson 이 BigDecimal 로 받는다).
    @JsonKey(fromJson: decimalStringFromJson) String? quantity,
    String? holdingName,
    int? holdingValue,

    /// 총 매수원가 (원화, 수수료 포함). 평가액과의 차이가 평가손익이다.
    int? totalCost,

    /// 평단가 — 총원가 / 수량. 서버 파생값이라 읽기 전용, 정밀도 때문에 문자열.
    /// 서버 계약이 BigDecimal 이라 JSON 숫자로 온다 — 컨버터 없이 캐스트하면 터진다.
    @JsonKey(fromJson: decimalStringFromJson) String? avgPrice,
    int? sortOrder,
  }) = _AssetHolding;

  factory AssetHolding.fromJson(Map<String, dynamic> json) =>
      _$AssetHoldingFromJson(json);
}

/// 표시·미리보기 계산용 수치. 저장·전송에는 절대 쓰지 않는다 — 그 경로는 문자열 그대로다.
/// (토스 `TossHolding.quantityValue` 와 같은 패턴)
extension AssetHoldingQuantity on AssetHolding {
  double get quantityValue => double.tryParse(quantity ?? '') ?? 0;
}
