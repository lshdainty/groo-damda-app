import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_edit_route.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 결제가 끝난 회차에 걸린 거래를 바꿀 때 하는 말 — 확인창 **한 문구**와 결과 토스트.
///
/// 닫힌 회차에 걸린 변경은 기록만 바뀌고 통장은 그대로다(D1). 예전엔 서버에 "얼마가
/// 돌아오나" 를 미리 물어 문장을 다섯 갈래로 골랐다. 이제 돌려주는 일이 없으니 묻지
/// 않는다 — 삭제·환불·환불 취소·저장·스와이프가 모두 같은 문장을 쓴다(웹과 한 벌).

/// 확인창에 덧붙일 한 줄 — 열린 회차면 null.
String? closedCycleNote(AppLocalizations l, ClosedCycleSpan span) =>
    switch (span) {
      ClosedCycleSpan.full => l.expClosedCycleLine,
      ClosedCycleSpan.partial => l.expClosedCyclePartLine,
      ClosedCycleSpan.none => null,
    };

/// 거래 하나가 지금 닫힌 회차에 걸렸나 — 그 거래의 날짜·할부·카드로 본다.
ClosedCycleSpan closedCycleSpanOfExpense(Expense e, Asset? asset) =>
    closedCycleSpanFor(
      asset,
      dateKey: e.expenseDate,
      installmentMonths: e.installmentMonths,
    );

/// 이 거래의 돈 칸이 잠겼나(D12) — 서버 플래그가 먼저고, 규칙으로 한 번 더 본다.
///
/// 잠금 = 신용카드 거래이고 (기록용 표식이 있거나 결제일이 된 회차분이 하나라도 있음).
/// 할부는 첫 회차부터 본다 — 첫 회차가 닫혔으면 걸친 것이다. 서버가 `moneyLocked` 를
/// 내려 주면 그것으로 충분하지만, 규칙을 같이 보면 자산 목록만 새로 받은 사이에도
/// 잠긴 거래를 풀어 놓지 않는다(서버는 돈 칸이 바뀌면 어차피 400 이다).
bool moneyLockedOf(Expense e, Asset? asset) {
  if (e.moneyLocked) return true;
  if (asset?.assetType != 'CREDIT_CARD') return false;
  return e.cardSettledThrough != null ||
      closedCycleSpanOfExpense(e, asset) != ClosedCycleSpan.none;
}

/// 고쳐 쓰기 확인창 본문(D13) — 첫 문장 "원래 거래는 지워지고 새 거래로 바뀌어요."
/// 뒤에 새 거래가 떨어지는 회차로 한 문장을 잇는다. 서버 조회 없음. 웹과 같은 문구다.
///
///   - 닫힌 회차(카드) — "기록만 바뀌고 계좌 잔액은 그대로예요."
///   - 할부가 닫힌 회차에 걸침 — "지난 회차분은 기록만 남아요."
///   - 열린 회차(카드) — "새 거래는 {그 회차 결제일} 결제에 청구돼요. 원래 거래는 이미
///     결제된 회차에서 기록만 빠져요." 결제일은 거래 달의 다음 달 결제일이다 — 결제일
///     변경이 대기 중인 회차면 서버가 준 실제 결제일(`nextPaymentDate`)
///   - 그 밖(계좌·현금·자산 없음·결제일 없는 카드) — 첫 문장만. 청구 회차가 없으니
///     결제일을 말할 수 없다
String rewriteConfirmMessage(
  AppLocalizations l, {
  required Asset? newAsset,
  required String dateKey,
  int? installmentMonths,
}) {
  final lead = l.expRewriteConfirmLead;
  if (newAsset == null || newAsset.assetType != 'CREDIT_CARD') return lead;
  final span = closedCycleSpanFor(
    newAsset,
    dateKey: dateKey,
    installmentMonths: installmentMonths,
  );
  switch (span) {
    case ClosedCycleSpan.full:
      return '$lead ${l.expRewriteConfirmClosed}';
    case ClosedCycleSpan.partial:
      return '$lead ${l.expClosedCyclePartLine}';
    case ClosedCycleSpan.none:
      final day = newAsset.paymentDay;
      if (day == null) return lead;
      // 결제일 변경이 대기 중이면 그 회차는 옛 결제일에 나간다(D5) — 서버가 준 실제
      // 결제일을 쓰고, 그 뒤 회차만 지금 결제일로 센다(QA 26 4).
      final pay = DateTime.parse(
        cyclePaymentDate(dateKey, day, newAsset.nextPaymentDate),
      );
      return '$lead ${l.expRewriteConfirmOpen(monthDay(pay))}';
  }
}

/// 확인창 본문 — 기본 문장 뒤에 닫힌 회차 한 줄을 문단으로 붙인다.
String withClosedCycleNote(
  AppLocalizations l,
  String message,
  ClosedCycleSpan span,
) {
  final note = closedCycleNote(l, span);
  return note == null ? message : '$message\n\n$note';
}

/// [잔액 고치기] 가 갈 결제계좌 — 닫힌 회차에 걸린 신용카드 거래이고 결제계좌가
/// 있을 때만(D9). 없으면 null.
///
/// 닫힌 회차의 변경은 통장을 안 움직인다. 카드사가 실제로 돈을 돌려줬다면 사용자가
/// 그 계좌의 잔액을 고쳐야 한다 — 그 수정 폼으로 바로 보내는 바로가기다.
int? fixBalanceTargetOf(Expense e, Asset? asset) => fixBalanceTargetFor(
  asset,
  dateKey: e.expenseDate,
  installmentMonths: e.installmentMonths,
);

/// [fixBalanceTargetOf] 의 재료판 — 아직 거래가 없는 자리(새 저장·문자 저장)가 폼의
/// 카드·날짜·할부로 묻는다.
int? fixBalanceTargetFor(
  Asset? asset, {
  required String? dateKey,
  int? installmentMonths,
}) {
  final span = closedCycleSpanFor(
    asset,
    dateKey: dateKey,
    installmentMonths: installmentMonths,
  );
  if (span == ClosedCycleSpan.none) return null;
  return asset?.paymentAssetRowId;
}

/// 바꾼 뒤의 결과 스낵바(ds, neutral) — 미리 낸 돈이 계좌로 돌아왔으면 그 금액을 말한다(D4).
///
/// 미리보기는 없다. 열린 회차에서 미리 낸 돈이 남을 때만 서버가 결제계좌로 돌려주고,
/// 그 금액이 응답에 실려 온다 — 사후에 한 번 알린다(스와이프 삭제 포함).
///
/// [fixBalanceAssetId] 가 있으면(닫힌 회차 거래의 환불·삭제·고쳐 쓰기, D9) 스낵바에
/// [잔액 고치기] 를 단다 — 돌려받은 돈이 없어도 한 문장("결제가 끝난 회차라 기록만
/// 바뀌고 계좌 잔액은 그대로예요.")으로 띄운다(웹과 같다). 확인창은 두 문장 그대로다. 둘 다
/// 없으면 조용히 끝난다. 호스트가 없으면 건너뛴다.
///
/// [host] 는 시트·행보다 오래 사는 context 다 — 지운 뒤 시트가 닫히고 행이 사라져도
/// 토스트는 떠야 하고, 버튼은 그 뒤에 눌린다.
void showChangeResultToast(
  BuildContext host, {
  required int? refundedAmount,
  int? fixBalanceAssetId,
}) {
  if (!host.mounted) return;
  final l = AppLocalizations.of(host);
  final refunded = refundedAmount ?? 0;
  final String message;
  if (refunded > 0) {
    message = l.expRefundedToast(krwSigned(refunded, false, unit: true));
  } else if (fixBalanceAssetId != null) {
    message = l.expClosedCycleToast;
  } else {
    return;
  }
  // 호스트가 없는 자리(시험 · 호스트 밖)는 조용히 건너뛴다.
  final snack = PSnackbar.maybeOf(host);
  if (snack == null) return;
  // 둘 다 neutral(D1 · D2) — 돈이 돌아온 것도, 통장이 그대로라는 안내도 이정표가 아니다. 액션이 있으면 6초는 ds 가 정한다.
  snack.show(
    message: message,
    action: fixBalanceAssetId == null
        ? null
        : PSnackbarAction(
            label: l.expFixBalance,
            onPressed: () => pushAssetEdit(host, fixBalanceAssetId),
          ),
  );
}

/// 토스트·확인창을 띄울 오래 사는 context — 루트 내비게이터의 것.
///
/// 시트 안의 context 는 시트가 닫히면 풀리고, 목록 행의 context 는 지운 행과 함께
/// 사라진다. 루트 내비게이터는 앱과 함께 산다(스와이프 확인창도 같은 자리를 쓴다).
BuildContext hostContextOf(BuildContext context) =>
    Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
