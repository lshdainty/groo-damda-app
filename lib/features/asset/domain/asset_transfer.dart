/// 백엔드 `AssetApiDto.TransferResponse` 매핑.
class AssetTransfer {
  const AssetTransfer({
    required this.rowId,
    this.userRowId,
    required this.fromAssetRowId,
    this.fromAssetName,
    required this.toAssetRowId,
    this.toAssetName,
    required this.amount,
    this.fee,
    this.interestAmount,
    this.autoSource,
    this.deletable,
    this.principalAmount,
    this.description,
    this.transferDate,
    this.createAt,
    this.toAmount,
  });

  final int rowId;
  final int? userRowId;
  final int fromAssetRowId;
  final String? fromAssetName;
  final int toAssetRowId;
  final String? toAssetName;
  final int amount;
  final int? fee;

  /// 이자 (대출 상환 시). amount 중 이 금액은 부채를 줄이지 않고 지출로 잡힌다.
  final int? interestAmount;

  /// 시스템이 만든 이체의 출처 — `TRADE_SETTLEMENT`(매수 예수금 충당) /
  /// `CARD_PAYMENT`(카드 자동결제) / `CARD_REFUND`(카드 과납금을 결제계좌로 환급).
  /// null 이면 사용자가 직접 만든 이체다.
  ///
  /// 값이 있으면 금액이 원본(매수·청구)과 묶여 있어 고칠 수 없다.
  final String? autoSource;

  /// 이 이체를 지금 직접 지울 수 있나 — 서버 판정. 자동 생성이어도 원본 증권 자산이 삭제됐으면 true.
  /// 옛 서버면 null — [canDelete] 가 [autoSource] 로 폴백한다. 수정 잠금은 이 값과 무관하다.
  final bool? deletable;

  /// 삭제 판정의 한 곳.
  bool get canDelete => deletable ?? autoSource == null;

  /// 원금 = amount − interestAmount. 입금 자산(대출)에 실제로 반영된 금액.
  final int? principalAmount;
  final String? description;
  final String? transferDate; // ISO-LOCAL-DATETIME (YYYY-MM-DDTHH:mm:ss)
  final String? createAt;

  /// 받는 쪽 자산 통화로 받은 금액 — 두 계좌 통화가 다를 때만 값(서버 round(amount × 보내는 환율 ÷ 받는 환율)).
  /// null = [amount] 와 같은 값을 받았다(같은 통화 · 옛 이체 · 옛 서버). amount · fee · interestAmount 는 보내는 계좌 통화다(I-13).
  final int? toAmount;

  factory AssetTransfer.fromJson(Map<String, dynamic> json) {
    return AssetTransfer(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      fromAssetRowId: (json['fromAssetRowId'] as num).toInt(),
      fromAssetName: json['fromAssetName'] as String?,
      toAssetRowId: (json['toAssetRowId'] as num).toInt(),
      toAssetName: json['toAssetName'] as String?,
      amount: (json['amount'] as num).toInt(),
      fee: (json['fee'] as num?)?.toInt(),
      interestAmount: (json['interestAmount'] as num?)?.toInt(),
      autoSource: json['autoSource'] as String?,
      deletable: json['deletable'] as bool?,
      principalAmount: (json['principalAmount'] as num?)?.toInt(),
      description: json['description'] as String?,
      transferDate: json['transferDate'] as String?,
      createAt: json['createAt'] as String?,
      toAmount: (json['toAmount'] as num?)?.toInt(),
    );
  }
}

/// 자산 잔액 추이 1개 시점 — `AssetApiDto.AssetBalanceTrendResponse.points` 의 한 항목.
class AssetBalancePoint {
  const AssetBalancePoint({
    required this.weekStart,
    required this.balance,
    this.balanceInKrw,
  });
  final String weekStart; // YYYY-MM-DD

  /// 그 주 말 시점 자산 잔액(자산 통화 · 옛 뜻 예수금 + 보유).
  final int balance;

  /// 같은 시점 원화 합계(자산 화면과 같은 한 식, I-13). 옛 서버면 없다 — 차트는 [krwOrBalance] 를 그린다.
  final int? balanceInKrw;

  /// 차트에 그릴 값 — 원화 합계, 옛 서버면 [balance].
  int get krwOrBalance => balanceInKrw ?? balance;

  factory AssetBalancePoint.fromJson(Map<String, dynamic> json) {
    return AssetBalancePoint(
      weekStart: (json['weekStart'] as String?) ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      balanceInKrw: (json['balanceInKrw'] as num?)?.toInt(),
    );
  }
}
