import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 반복 하나를 켜고 끈다 — 요청은 silent 로 보낸다(화면이 고정 글로 알린다). 다시 켤 때 오늘이 회차면 서버가 그 거래를 바로
/// 기록한다(QA 30 1 · 4) — 가계부 · 자산 · 홈도 함께 새로 받는다. 목록을 **다시 받은 뒤에** 끝난다(상세가 새 값으로 다시 그려질 때
/// 목록이 이미 새 값이다). 실패하면 던진다 — 알리는 일은 부른 쪽 몫이다. 화면이 사라진 뒤에도 쓰도록 컨테이너로 받는다.
Future<void> toggleRecurringRequest(
  ProviderContainer container,
  int rowId,
) async {
  final repo = await container.read(recurringRepositoryProvider.future);
  await repo.toggle(rowId, silent: true);
  container.invalidate(recurringListProvider);
  container.invalidate(monthExpensesProvider);
  invalidateAfterExpenseChangeIn(container);
  try {
    await container.read(recurringListProvider.future);
  } catch (_) {
    // 켜고 끄기는 이미 끝났다 — 목록을 못 받은 것은 목록 화면의 실패 갈래가 알린다
  }
}

/// 반복 하나를 지우고 목록을 다시 받는다. 실패하면 던진다. 이미 기록된 거래는 그대로다.
Future<void> deleteRecurringRequest(
  ProviderContainer container,
  int rowId,
) async {
  final repo = await container.read(recurringRepositoryProvider.future);
  await repo.delete(rowId, silent: true);
  container.invalidate(recurringListProvider);
  try {
    await container.read(recurringListProvider.future);
  } catch (_) {
    // 지우기는 이미 끝났다
  }
}

/// 일시정지 · 다시 켜기 — 성공하면 알림("{이름} 반복을 멈췄어요" · "… 다시 켰어요"), 실패하면 스낵바(고정 글 + 다시 시도).
/// 성공하면 true. API 는 뒤집기만 하므로 [다시 시도] 는 **목표 상태**를 기준으로 한다 — 응답만 실패하고 서버엔 반영됐다면
/// 목록을 먼저 받아 이미 목표 상태면 요청을 보내지 않는다. 스낵바가 시트보다 오래 살 수 있어 context · ref 를 쥐지 않는다.
Future<bool> toggleRecurringWithNotice(
  BuildContext context,
  WidgetRef ref,
  RecurringTransaction it, {
  bool retry = false,
}) async {
  final l = AppLocalizations.of(context);
  final snack = PSnackbar.of(context);
  final container = ProviderScope.containerOf(context);
  return _toggleWithNotice(container, snack, l, it, retry: retry);
}

Future<bool> _toggleWithNotice(
  ProviderContainer container,
  PSnackbarApi snack,
  AppLocalizations l,
  RecurringTransaction it, {
  required bool retry,
}) async {
  // 진행 중인 같은 반복의 켜기/끄기는 막는다(다시 시도를 거듭 눌러도 한 번)
  if (!_toggling.add(it.rowId)) return false;
  try {
    return await _toggleBody(container, snack, l, it, retry: retry);
  } finally {
    _toggling.remove(it.rowId);
  }
}

final _toggling = <int>{};

Future<bool> _toggleBody(
  ProviderContainer container,
  PSnackbarApi snack,
  AppLocalizations l,
  RecurringTransaction it, {
  required bool retry,
}) async {
  final wantActive = it.isActive != 'Y'; // 목표: 지금 꺼져 있으면 켜기
  final name = recDisplayTitle(l, it);
  try {
    if (retry) {
      // 이전 요청이 서버엔 반영됐을 수 있다 — 최신 상태를 받아 이미 목표면 보내지 않는다
      container.invalidate(recurringListProvider);
      final list = await container.read(recurringListProvider.future);
      final now = list.where((e) => e.rowId == it.rowId).firstOrNull;
      if (now != null && (now.isActive == 'Y') == wantActive) {
        snack.show(
          message: wantActive
              ? l.recToastResumed(name)
              : l.recToastPaused(name),
        );
        return true;
      }
    }
    await toggleRecurringRequest(container, it.rowId);
  } catch (e) {
    if (isUnconfirmedSave(e)) {
      // 응답을 못 받았다 — 뒤집혔을 수 있다(API 는 뒤집기만 한다). [다시 시도] 없이 서버 값을 다시 받아 맞추고 한 문장(판단 ②)
      container.invalidate(recurringListProvider);
      container.invalidate(monthExpensesProvider);
      invalidateAfterExpenseChangeIn(container);
      snack.show(message: l.unconfirmedToggle, tone: PSnackbarTone.critical);
      return false;
    }
    snack.show(
      message: wantActive ? l.recResumeFailed : l.recPauseFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () =>
            unawaited(_toggleWithNotice(container, snack, l, it, retry: true)),
      ),
    );
    return false;
  }
  snack.show(
    message: wantActive ? l.recToastResumed(name) : l.recToastPaused(name),
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
  final container = ProviderScope.containerOf(context);
  final name = recDisplayTitle(l, it);
  final ok = await askConfirmThenRequest(
    context,
    title: l.recurringDeleteTitle,
    description: l.recurringDeleteConfirm(name),
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    request: () => deleteRecurringRequest(container, it.rowId),
    failedMessage: l.recDeleteFailed,
    retryLabel: l.actionRetry,
    onRetried: () {
      snack?.show(message: l.recToastDeleted(name));
      onRetried?.call();
    },
    kind: WriteKind.delete,
    onUnconfirmed: () => container.invalidate(recurringListProvider),
  );
  if (ok) snack?.show(message: l.recToastDeleted(name));
  return ok;
}
