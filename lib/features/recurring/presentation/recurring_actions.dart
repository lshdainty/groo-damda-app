import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
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

/// 삭제 확인 → 지움 → 알림. 확인창 뒤 실패는 공용 [askConfirmThenRequest] — critical 스낵바 + [다시 시도](묻지 않고 바로 지움,
/// 요청 silent). 지웠으면 true. 다시 시도로 지워도 같은 알림 · 목록 갱신을 한다(시트는 목록에서 사라진 항목을 알아서 닫는다).
Future<bool> deleteRecurringWithNotice(
  BuildContext context,
  WidgetRef ref,
  RecurringTransaction it, {
  VoidCallback? onRetried,
}) async {
  final l = AppLocalizations.of(context);
  final snack = PSnackbar.maybeOf(context);
  final name = recDisplayTitle(l, it);
  final ok = await askConfirmThenRequest(
    context,
    title: l.recurringDeleteTitle,
    description: l.recurringDeleteConfirm(name),
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    request: () => deleteRecurringRequest(ref, it.rowId),
    failedMessage: l.recDeleteFailed,
    retryLabel: l.actionRetry,
    onRetried: () {
      snack?.show(message: l.recToastDeleted(name));
      onRetried?.call();
    },
  );
  if (ok) snack?.show(message: l.recToastDeleted(name));
  return ok;
}
