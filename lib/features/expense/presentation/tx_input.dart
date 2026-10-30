import 'package:flutter/material.dart';

import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_form_parts.dart'
    show groupWon;
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

// ─────────────────────────────────────────────
// 거래 입력 (inline) — recurring 과 독립. tx_input_form.dart 해체 후 add_tx 자체 보유.

const kTxPaymentMethodCodes = ['CASH', 'CARD', 'TRANSFER', 'OTHER'];

String txPaymentMethodLabel(AppLocalizations l, String code) => switch (code) {
  'CASH' => l.expPayCash,
  'CARD' => l.expPayCard,
  'TRANSFER' => l.expPayTransfer,
  'OTHER' => l.expPayOther,
  _ => code,
};

const Map<String, List<String>?> kTxPaymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

/// 카드사 공통 할부 개월 — 2~12, 18, 24.
const List<int> kTxInstallmentMonths = [
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  18,
  24,
];

/// 해외 결제는 $5.50 을 보고 입력하지 원화 환산액을 모른다 — 원 통화 × 환율로 금액을 채운다.
///
/// 카드사 실제 청구액이 다르면 금액 칸을 직접 고치면 된다. 원 통화·환율을 다시 건드릴
/// 때만 다시 계산하므로 손으로 고친 금액을 덮어쓰지 않는다.
/// 1400.000000 을 1400 으로 — 서버가 소수로 주는 값을 그대로 넣으면 입력칸이 지저분하다.
String trimNum(double? v) {
  if (v == null) return '';
  final s = v.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}

/// 현지 금액 · 환율이 **바뀐 순간에만** 원화 금액을 채운다 — 손으로 고친 원화 금액(카드사 청구액)을 덮지 않는다.
void fillKrwFromForeign(TxInput c) {
  final a = c.origAmountOrNull;
  final r = c.fxRateOrNull;
  if (a == null || r == null || a <= 0 || r <= 0) return;
  c.amountCtrl.text = groupWon((a * r).round());
}

/// 이자 입력을 보일지 — 대출 상환일 때만.
///
/// 원금은 부채가 줄어드는 자산 이동이지만 이자는 은행으로 아예 나가는 비용이라,
/// 입금 대상이 대출 자산일 때만 의미가 있다.
bool showTxInterest(TxInput c, List<Asset>? assets) =>
    c.type == 'TRANSFER' && isLoanTarget(assets, c.toAssetRowId);

/// 할부 입력을 보일지 — 신용카드 지출일 때만.
bool showTxInstallment(TxInput c, List<Asset>? assets) {
  if (c.type != 'EXPENSE' || c.assetRowId == null || assets == null) {
    return false;
  }
  final picked = assets.where((a) => a.rowId == c.assetRowId).firstOrNull;
  return picked?.assetType == 'CREDIT_CARD';
}

/// 결제 수단 + 거래 타입으로 계좌·카드 후보를 고른다.
///
/// 지출에선 예·적금(SAVINGS: 청약·정기예금·정기적금)을 뺀다 — 만기 전까지 묶인 돈이라
/// 거기서 직접 결제나 출금이 나가지 않는다(쓰려면 해지해서 입출금으로 옮긴다).
/// 납입·해지는 이체로 처리하므로 이체 목록에는 그대로 남는다.
/// 수입은 이자가 그 계좌로 직접 들어오므로 남긴다.
bool allowTxAsset(Asset a, String paymentMethod, String type) {
  final allowed = paymentMethod.isNotEmpty
      ? kTxPaymentAssetTypes[paymentMethod]
      : null;
  if (allowed != null && !allowed.contains(a.assetType)) return false;
  if (type == 'EXPENSE' && a.assetType == 'SAVINGS') return false;
  return true;
}

/// 거래 입력 상태 (지출/수입/이체).
class TxInput {
  TxInput({
    this.type = 'EXPENSE',
    String amount = '',
    String merchant = '',
    String memo = '',
    this.categoryRowId,
    this.assetRowId,
    this.paymentMethod = '',
    DateTime? date,
    TimeOfDay? time,
  }) : date = date ?? calendarNow(),
       time = time ?? TimeOfDay.fromDateTime(calendarNow()),
       amountCtrl = TextEditingController(
         text: groupWon(int.tryParse(amount) ?? 0),
       ),
       merchantCtrl = TextEditingController(text: merchant),
       memoCtrl = TextEditingController(text: memo),
       feeCtrl = TextEditingController(),
       interestCtrl = TextEditingController(),
       origAmountCtrl = TextEditingController(),
       fxRateCtrl = TextEditingController();

  final TextEditingController amountCtrl;
  final TextEditingController merchantCtrl;
  final TextEditingController memoCtrl;
  final TextEditingController feeCtrl;

  /// 대출 상환의 이자 — 상환액 중 이 금액은 부채를 줄이지 않고 지출로 잡힌다.
  final TextEditingController interestCtrl;

  /// 0·빈칸은 "없음" 이다 — 서버에 0 을 실어 보내도 뜻이 같아서 키를 뺀다.
  int? get feeOrNull {
    final v = int.tryParse(feeCtrl.text.replaceAll(',', '')) ?? 0;
    return v > 0 ? v : null;
  }

  int? get interestOrNull {
    final v = int.tryParse(interestCtrl.text.replaceAll(',', '')) ?? 0;
    return v > 0 ? v : null;
  }

  /// 해외 결제의 원 통화 금액·환율 — 셋이 함께여야 카드사 청구 환율과 대사할 수 있다.
  final TextEditingController origAmountCtrl;
  final TextEditingController fxRateCtrl;

  String type; // EXPENSE / INCOME / TRANSFER
  int? categoryRowId;
  int? assetRowId; // EXPENSE/INCOME 자산, TRANSFER 출금 자산
  int? toAssetRowId; // TRANSFER 입금 자산 (이체 시 폼에서 set)
  String paymentMethod;

  /// 할부 개월 — 신용카드 지출에만 의미. 0 = 일시불.
  int installmentMonths = 0;

  /// 사용자가 고른 결제 통화. `null` 이면 아직 아무것도 안 골랐다.
  String? currencyPick;

  /// 이 거래에 이미 적혀 있던 통화 — 편집·환불·문자 초안이 채운다.
  ///
  /// 원화 거래는 서버에서 `originalCurrency` 가 `null` 로 오지만 여기엔 `KRW` 를
  /// 넣는다. 비워 두면 아래 [currency] 가 설정의 기본 통화로 떨어져, 원화로 적어
  /// 둔 거래를 열기만 해도 해외 결제 입력이 펼쳐진다.
  String? txCurrency;

  /// 설정의 기본 통화 — 폼이 매 빌드 흘려 넣는다(D7 · QA #124).
  ///
  /// `/me/preferences` 는 설정 화면을 안 들른 세션에서 이 시트보다 늦게 도착한다.
  /// 열 때 한 번만 읽어 굳히면 첫 렌더의 원화에 잠기므로, 도착한 값을 매 빌드
  /// 다시 흘려 넣어 아직 안 고른 새 거래에 반영한다.
  String defaultCurrency = kDefaultCurrency;

  /// 결제 통화 — KRW 면 원화 결제(원 통화 기록 없음).
  ///
  /// 우선순위는 **고른 값 > 이 거래의 값 > 설정의 기본 통화**다. 기본 통화는
  /// 새 거래에만 닿는다 — 편집·환불·문자 초안은 [txCurrency] 에서 멈춘다.
  String get currency => currencyPick ?? txCurrency ?? defaultCurrency;
  DateTime date;
  TimeOfDay time;

  /// 고정 수입·지출 — 월세·월급처럼 매달 정해진 거래. 통계가 따로 나눠 본다(돈에는 영향 없음).
  /// 이체에는 없다.
  bool isFixed = false;

  /// 금액칸에 걸 상한 — 거래 상한(100억) 하나다.
  int get amountMaxForInput => kAmountMax;

  /// 시스템이 만든 거래의 출처 (TRADE_REALIZED / TRANSFER_INTEREST). null 이면 손으로 쓴 거래.
  /// 값이 있으면 금액·날짜·자산이 잠긴다 — 서버도 같은 규칙으로 거른다.
  String? autoSource;

  /// 결제 문자 초안에서 "이 카드로 기억" 을 물어볼 상황인가 (카드는 알아봤는데 아직 안 외움).
  bool smsRememberAsk = false;

  /// 사용자가 그 체크를 켰는가 — 저장 시 (카드 힌트 → 자산) 을 서버가 적어 둔다.
  bool smsRememberCard = false;

  /// 금액·날짜·자산을 못 고치는가 — 계산 결과라서.
  bool get isAutoGenerated => autoSource != null;

  /// 결제가 끝난 카드 거래라 돈 칸을 못 고치는가(D12) — 시트가 매 빌드 흘려 넣는다.
  bool moneyLocked = false;

  /// 돈 칸 전부 — 금액·날짜·시간·자산·결제수단·할부·통화 3칸 — 을 잠그는가.
  ///
  /// 자동 생성 거래와 결제가 끝난 거래가 같은 잠금을 쓴다. 통화·환율·결제수단·할부도
  /// 함께 잠근다 — 환율을 고치면 금액이 다시 계산돼 덮이고(`syncKrwFromForeign`),
  /// 결제수단을 바꾸면 안 맞는 자산이 풀린다. 한 칸만 열어 둬도 돈 칸이 새로 바뀐다.
  bool get moneyFieldsLocked => isAutoGenerated || moneyLocked;

  int get amountInt => int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String? get merchantOrNull =>
      merchantCtrl.text.trim().isEmpty ? null : merchantCtrl.text.trim();
  String? get memoOrNull =>
      memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim();
  String? get paymentMethodOrNull =>
      paymentMethod.isEmpty ? null : paymentMethod;

  /// 외화 결제인가 — 이체는 두 자산 사이의 이동이라 통화가 자산에 달려 있어 제외.
  bool get isForeignTx => type != 'TRANSFER' && isForeignCurrency(currency);
  double? get origAmountOrNull => isForeignTx
      ? double.tryParse(origAmountCtrl.text.replaceAll(',', ''))
      : null;
  double? get fxRateOrNull =>
      isForeignTx ? double.tryParse(fxRateCtrl.text.replaceAll(',', '')) : null;

  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    memoCtrl.dispose();
    feeCtrl.dispose();
    interestCtrl.dispose();
    origAmountCtrl.dispose();
    fxRateCtrl.dispose();
  }
}
