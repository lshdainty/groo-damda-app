import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 정산 하나에 하는 쓰기 — 상세 시트가 부른다. 요청은 모두 silent(서버 원문 없음)이고 **목록을 다시 받은 뒤에** 끝난다.
/// 컨테이너를 미리 잡아 두므로 시트가 먼저 닫혀도 안전하다.
Future<void> _refetch(ProviderContainer c) async {
  c.invalidate(dutchPayListProvider);
  try {
    await c.read(dutchPayListProvider.future);
  } on Object {
    // 쓰기는 끝났다 — 화면은 보던 목록을 그대로 둔다
  }
}

Future<void> dutchDeleteRequest(ProviderContainer c, int id) async {
  final repo = await c.read(dutchPayRepositoryProvider.future);
  await repo.delete(id, silent: true);
  await _refetch(c);
}

Future<void> dutchSettleRequest(ProviderContainer c, int id) async {
  final repo = await c.read(dutchPayRepositoryProvider.future);
  await repo.settle(id, silent: true);
  await _refetch(c);
}

Future<void> dutchMarkPaidRequest(ProviderContainer c, int id, int pid) async {
  final repo = await c.read(dutchPayRepositoryProvider.future);
  await repo.markPaid(id, pid, silent: true);
  await _refetch(c);
}

/// 삭제 — 확인창 → 지움. 실패는 확인창을 닫고 critical 스낵바 + [다시 시도](묻지 않고 바로, 요청 silent). 지웠으면 true.
Future<bool> deleteDutchWithConfirm(BuildContext context, DutchPay dp) {
  final l = AppLocalizations.of(context);
  final c = ProviderScope.containerOf(context, listen: false);
  return askConfirmThenRequest(
    context,
    title: l.dutchDeleteTitle,
    description: l.dutchDeleteConfirm(dp.title),
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    request: () => dutchDeleteRequest(c, dp.rowId),
    failedMessage: l.dutchDeleteFailed,
    retryLabel: l.actionRetry,
    // 응답을 못 받았다 — 지워졌을 수 있다. 다시 받기만(검수 M3)
    onUnconfirmed: () => c.invalidate(dutchPayListProvider),
  );
}

/// 모두 받음 — 확인 없이 바로(되돌릴 수 있는 한 번의 처리가 아니라 서버 PATCH 하나). 실패는 스낵바 + [다시 시도] 로 같은 요청을 바로 한다.
Future<bool> settleDutch(BuildContext context, DutchPay dp) => _runWithRetry(
  context,
  (l) => l.dutchSettleFailed,
  (c) => dutchSettleRequest(c, dp.rowId),
);

/// 한 줄 받음 — 실패는 스낵바 + [다시 시도].
Future<bool> markDutchPaid(
  BuildContext context,
  DutchPay dp,
  DutchPayParticipant p,
) => _runWithRetry(
  context,
  (l) => l.dutchMarkFailed,
  (c) => dutchMarkPaidRequest(c, dp.rowId, p.rowId),
);

Future<bool> _runWithRetry(
  BuildContext context,
  String Function(AppLocalizations) failed,
  Future<void> Function(ProviderContainer) request,
) async {
  final c = ProviderScope.containerOf(context, listen: false);
  final snack = PSnackbar.maybeOf(context);
  final l = AppLocalizations.of(context);
  Future<bool> go() async {
    try {
      await request(c);
      return true;
    } catch (e) {
      // 응답을 못 받았다 — 처리됐을 수 있다. [다시 시도] 없이 다시 받고 확인을 부탁한다(검수 M3)
      if (isUnconfirmedSave(e)) {
        c.invalidate(dutchPayListProvider);
        snack?.show(message: l.saveUnconfirmed, tone: PSnackbarTone.critical);
        return false;
      }
      snack?.show(
        message: failed(l),
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(label: l.actionRetry, onPressed: go),
      );
      return false;
    }
  }

  return go();
}
