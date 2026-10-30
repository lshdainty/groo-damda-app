import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 반복 하나를 켜고 끈다 — 전역 오류 스낵바는 끈다(화면이 고정 글로 알린다). 다시 켤 때 오늘이 회차면 서버가 그 거래를 바로
/// 기록한다(QA 30 1 · 4) — 가계부 · 자산 · 홈도 함께 새로 받는다. 목록을 **다시 받은 뒤에** 끝난다(상세가 새 값으로 다시 그려질 때
/// 목록이 이미 새 값이다). 실패하면 던진다 — 알리는 일은 부른 쪽 몫이다.
Future<void> toggleRecurringRequest(WidgetRef ref, int rowId) async {
  final repo = await ref.read(recurringRepositoryProvider.future);
  await repo.toggle(rowId, silent: true);
  ref.invalidate(recurringListProvider);
  ref.invalidate(monthExpensesProvider);
  invalidateAfterExpenseChange(ref);
  try {
    await ref.read(recurringListProvider.future);
  } catch (_) {
    // 켜고 끄기는 이미 끝났다 — 목록을 못 받은 것은 목록 화면의 실패 갈래가 알린다
  }
}

/// 반복 하나를 지우고 목록을 다시 받는다. 실패하면 던진다. 이미 기록된 거래는 그대로다.
Future<void> deleteRecurringRequest(WidgetRef ref, int rowId) async {
  final repo = await ref.read(recurringRepositoryProvider.future);
  await repo.delete(rowId, silent: true);
  ref.invalidate(recurringListProvider);
  try {
    await ref.read(recurringListProvider.future);
  } catch (_) {
    // 지우기는 이미 끝났다
  }
}

/// 일시정지 · 다시 켜기 — 성공하면 알림("{이름} 반복을 멈췄어요" · "… 다시 켰어요"), 실패하면 스낵바(고정 글 + 다시 시도).
/// 성공하면 true.
Future<bool> toggleRecurringWithNotice(
  BuildContext context,
  WidgetRef ref,
  RecurringTransaction it,
) async {
  final l = AppLocalizations.of(context);
  final snack = PSnackbar.of(context);
  final wasActive = it.isActive == 'Y';
  final name = recDisplayTitle(l, it);
  try {
    await toggleRecurringRequest(ref, it.rowId);
  } catch (_) {
    snack.show(
      message: wasActive ? l.recPauseFailed : l.recResumeFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () => toggleRecurringWithNotice(context, ref, it),
      ),
    );
    return false;
  }
  snack.show(
    message: wasActive ? l.recToastPaused(name) : l.recToastResumed(name),
  );
  return true;
}

/// 삭제 확인창(PAlertDialog destructive) → 확정하면 지운다. [confirmed] 가 true 이고 [failure] 가 있으면 지우기가 실패한 것이다
/// (확인창은 닫혔다 — 알리는 자리는 부른 쪽이 정한다: 스낵바 + 다시 시도).
Future<({bool confirmed, Object? failure})> askDeleteRecurring(
  BuildContext context,
  WidgetRef ref,
  RecurringTransaction it,
) async {
  final l = AppLocalizations.of(context);
  Object? failure;
  final ok = await PAlertDialog.show(
    context,
    title: l.recDeleteTitle(recDisplayTitle(l, it)),
    description: l.recDeleteMessage,
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    destructive: true,
    // 확정이 끝날 때까지 확정 버튼이 로딩이고 다음 누름을 버린다
    onAction: () async {
      try {
        await deleteRecurringRequest(ref, it.rowId);
      } catch (e) {
        failure = e;
      }
    },
  );
  return (confirmed: ok, failure: failure);
}

/// 삭제 확인 → 지움 → 알림. 실패하면 스낵바("반복 설정을 삭제하지 못했어요" + 다시 시도 — 서버 글 없음). 지웠으면 true.
Future<bool> deleteRecurringWithNotice(
  BuildContext context,
  WidgetRef ref,
  RecurringTransaction it,
) async {
  final l = AppLocalizations.of(context);
  final snack = PSnackbar.of(context);
  final name = recDisplayTitle(l, it);
  final r = await askDeleteRecurring(context, ref, it);
  if (!r.confirmed) return false;
  if (r.failure != null) {
    _deleteFailed(snack, l, ref, it);
    return false;
  }
  snack.show(message: l.recToastDeleted(name));
  return true;
}

void _deleteFailed(
  PSnackbarApi snack,
  AppLocalizations l,
  WidgetRef ref,
  RecurringTransaction it,
) {
  snack.show(
    message: l.recDeleteFailed,
    tone: PSnackbarTone.critical,
    action: PSnackbarAction(
      label: l.actionRetry,
      // 이미 확인창에서 한 번 확정한 삭제 — 묻지 않고 바로 지운다
      onPressed: () async {
        try {
          await deleteRecurringRequest(ref, it.rowId);
          snack.show(message: l.recToastDeleted(recDisplayTitle(l, it)));
        } catch (_) {
          _deleteFailed(snack, l, ref, it);
        }
      },
    ),
  );
}
