import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

/// 백엔드 `ExpenseApiDto.Response` 1:1 매핑.
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required int rowId,
    int? userRowId,
    int? categoryRowId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    int? assetRowId,
    String? assetName,
    required String expenseType, // 'EXPENSE' | 'INCOME'
    required int amount,
    String? description,
    String? expenseDate, // ISO LocalDateTime ('YYYY-MM-DDTHH:mm:ss')
    String? merchant,
    String? paymentMethod,

    /// 할부 개월 (null = 일시불). 신용카드 결제에만 의미.
    int? installmentMonths,

    /// 환불 처리 시각 (null = 환불 아님). ISO LocalDateTime.
    ///
    /// 환불은 **원거래에 찍는 표식**이다 — 수입 행을 만들지 않는다. 있으면
    /// 합계·예산·통계·카드 청구에서 삭제와 똑같이 빠지고, 내역·검색에는 남는다.
    String? refundedAt,

    /// 옛 환불 마크가 만든 카드→결제계좌 환급 이체 (null = 없음).
    ///
    /// 이제 환불은 이체를 만들지 않는다(D1). 이 값이 있는 옛 거래만 환불을 취소할 때
    /// 그 이체까지 되돌아간다 — 그래서 확인창이 "환급된 금액도 되돌아가요" 를 말한다.
    int? refundTransferRowId,

    /// 이 요청이 **방금** 결제계좌로 돌려준 금액 (null = 없음).
    ///
    /// 열린 회차에서 미리 낸 돈이 남을 때만 생긴다(D3). 거래의 속성이 아니라 그 요청의
    /// 결과다 — 조회로 받은 거래에는 늘 null 이다. 화면이 "미리 낸 돈 중 N원이 계좌로
    /// 돌아왔어요" 를 말할 재료다(D4).
    int? refundedAmount,

    /// 이 날짜(회차 말일)까지의 카드 회차분은 계좌 이체 없이 정리된 **기록용** (null = 정상).
    ///
    /// 결제가 끝난(닫힌) 회차에 뒤늦게 적은 카드 지출에 붙는다 — 가계부 합계에는 들어가지만
    /// 계좌에서는 빠지지 않았고 이후 청구에도 안 얹힌다(닫힌 회차 규칙 R2). 'YYYY-MM-DD'.
    String? cardSettledThrough,

    /// 그 가운데 기록만 남긴 금액 — 할부는 지난 회차분만이라 거래 금액보다 작을 수 있다.
    ///
    /// 금액과 같을 때만 목록 행에 "기록만" 배지를 단다. 작으면 할부 일부라 상세에서
    /// "이 중 N원" 으로 말한다(D10).
    int? recordOnlyAmount,

    /// 돈 칸 잠금(D12) — 결제일이 된 회차분이 하나라도 있는 신용카드 거래(또는 기록용
    /// 표식이 있는 거래)면 서버가 true 로 내린다.
    ///
    /// true 면 금액·날짜·시간·자산·할부·유형·통화 3칸·결제수단을 못 고친다. 카테고리·
    /// 가맹점·메모만 고치고, 돈 칸은 [고쳐 쓰기](`POST /expense/{id}/replace`)로 바꾼다.
    /// 옛 서버면 false.
    @Default(false) bool moneyLocked,

    /// [고쳐 쓰기] 를 쓸 수 있는 거래인가 — 잠겼고(`moneyLocked`) 환불 안 됐고 자동 생성이
    /// 아니고 중도 정리하지 않은 할부. 서버가 판정해 내려 준다(QA 26 3).
    ///
    /// 잠겼는데 이게 false 면 사실상 중도 정리한 할부다 — 서버가 교체를 EXP_047 로 거절한다.
    /// 옛 서버면 없다(null) — 그때는 잠금으로 본다.
    bool? replaceable,

    /// 원 통화 금액 (해외 결제). null 이면 원화 결제 — amount 가 곧 결제액이다.
    double? originalAmount,

    /// 원 통화 (ISO 4217, 예: USD).
    String? originalCurrency,

    /// 적용 환율 (원 통화 1단위당 원화). amount ≈ originalAmount × exchangeRate.
    double? exchangeRate,

    /// 시스템이 만든 거래의 출처 — `TRADE_REALIZED`(매도 실현손익) /
    /// `TRANSFER_INTEREST`(이체 이자). null 이면 손으로 쓴 거래다.
    ///
    /// 값이 있으면 금액·날짜·자산은 계산 결과라 고칠 수 없다. 원본 거래를 지우면
    /// 함께 사라진다. 카테고리·메모는 분류라서 그대로 고칠 수 있다.
    String? autoSource,

    /// 이 기록을 지금 직접 지울 수 있나 — 서버가 판정해 내려 준다. 자동 생성이 아니면 true,
    /// 자동 생성이어도 그 기록을 만든 증권 자산이 이미 삭제됐으면 true. **삭제 버튼 · 스와이프 [삭제] 만**
    /// 이 값을 본다(수정 · 환불 · 분할은 [autoSource] 그대로). 옛 서버면 없다(null) — [canDelete] 가 폴백한다.
    bool? deletable,
    int? calendarEventRowId,
    int? todoRowId,
    // 활성 분할 항목들의 카테고리 id (없으면 빈 리스트). 목록 카테고리 필터를 split-aware 하게 매칭.
    @Default(<int>[]) List<int> splitCategoryRowIds,

    /// 고정 수입·지출 — 월세·월급처럼 매달 정해진 거래. 통계가 전체 · 고정 · 변동으로 나눠 보는
    /// **분류 표식**이다(돈·잔액·카드 청구에는 영향 없음). 이체는 대상이 아니다. 옛 서버면 false.
    @Default(false) bool isFixed,
    String? createAt,
    String? modifyAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

extension ExpenseX on Expense {
  /// 표시용 부호 적용 (지출=음수, 수입/이체=양수).
  int get signedAmount => expenseType == 'EXPENSE' ? -amount : amount;

  /// 삭제할 수 있나 — 삭제 판정의 한 곳. 서버 값이 없으면(옛 서버) 손으로 쓴 거래만.
  bool get canDelete => deletable ?? autoSource == null;

  /// 환불된 거래인가 — 표식 하나로 판정한다.
  bool get isRefunded => refundedAt != null;

  /// 기록만 남긴 금액 — 서버가 금액을 안 주고 표식만 있으면(옛 서버) 전액으로 본다.
  int get recordOnlyShare =>
      recordOnlyAmount ?? (cardSettledThrough != null ? amount.abs() : 0);

  /// 기록만 남긴 몫이 있는가 — 상세 안내용(할부면 일부일 수 있다). 환불된 거래는
  /// "환불됨" 이 먼저라 여기서 뺀다.
  bool get hasRecordOnlyPart =>
      !isRefunded && cardSettledThrough != null && recordOnlyShare > 0;

  /// **통째로** 기록만 남긴 거래인가 — 목록 행의 "기록만" 배지(D10).
  ///
  /// 할부의 지난 회차분만 기록용인 거래에는 안 단다 — 남은 회차는 정상 청구된다.
  bool get isRecordOnly => hasRecordOnlyPart && recordOnlyShare >= amount.abs();

  /// 'YYYY-MM-DD' 부분만 (그룹화·필터용).
  String? get expenseDateOnly => expenseDate?.substring(0, 10);
}
