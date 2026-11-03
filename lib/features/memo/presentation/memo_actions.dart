import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/actions/item_actions.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 메모 하나에 할 수 있는 일 — 목록 줄(밀기)과 상세가 같은 것을 부른다.
const memoActions = MemoActions();

/// 메모가 불릴 이름 — 서버에 빈 제목이 이미 있으면 "제목 없음" (웹 `memoLabel`).
String memoLabelOf(AppLocalizations l, Memo m) {
  final t = m.title;
  return (t == null || t.isEmpty) ? l.memoUntitled : t;
}

class MemoActions implements ItemActions<Memo> {
  const MemoActions();

  @override
  bool canDelete(Memo m) => true;

  @override
  bool canEdit(Memo m) => true;

  @override
  String deleteConfirmTitle(BuildContext context, Memo m) =>
      AppLocalizations.of(context).memoDeleteTitle;

  /// `"{name}" 메모를 삭제할까요? 삭제한 메모는 되돌릴 수 없어요.` — 웹 · #508 짝 표(F-i28-5)와 글자까지 같다.
  @override
  String deleteConfirmMessage(BuildContext context, Memo m) {
    final l = AppLocalizations.of(context);
    return l.memoDeleteConfirm(memoLabelOf(l, m));
  }

  /// 서버에서 지우고 목록을 비워 **다시 받은 뒤** 끝낸다. 던지면 실패다.
  Future<void> remove(ProviderContainer c, Memo m) async {
    final repo = await c.read(memoRepositoryProvider.future);
    await repo.delete(m.rowId);
    c.invalidate(memoListProvider);
    // 홈 위젯(메모 개수·최근 메모)의 원본 — 셸 상주라 스스로 안 받는다.
    c.invalidate(dashboardSummaryProvider);
    // 메모는 별자리(할일 게이미피케이션)에도 점수로 들어간다 — 지우면 같이 다시 센다.
    c
      ..invalidate(constellationTodayProvider)
      ..invalidate(constellationSkyProvider)
      ..invalidate(constellationCollectionProvider);
    await _refetch(c);
  }

  /// 고정 토글 — 별도 엔드포인트. 목록을 다시 받은 뒤 끝낸다. 던지면 실패다.
  Future<void> togglePinRaw(ProviderContainer c, Memo m) async {
    final repo = await c.read(memoRepositoryProvider.future);
    await repo.pin(m.rowId);
    c.invalidate(memoListProvider);
    await _refetch(c);
  }

  Future<void> _refetch(ProviderContainer c) async {
    try {
      await c.read(memoListProvider.future);
    } on Object {
      // 목록을 다시 못 받아도 쓰기는 끝났다 — 화면은 보던 목록을 그대로 둔다.
    }
  }

  /// 고정 / 고정 해제 — 실패하면 critical 스낵바 + [다시 시도]. 끝났으면 true.
  /// 띠는 앱 뿌리 호스트에 있어 화면을 나가도 남으므로 컨테이너 · 호스트 · 글을 미리 잡아 둔다.
  Future<bool> pin(BuildContext context, Memo m) async {
    final c = ProviderScope.containerOf(context, listen: false);
    final snack = PSnackbar.maybeOf(context);
    final l = AppLocalizations.of(context);
    return pinDetached(c, snack, l, m);
  }

  Future<bool> pinDetached(
    ProviderContainer c,
    PSnackbarApi? snack,
    AppLocalizations l,
    Memo m,
  ) async {
    try {
      await togglePinRaw(c, m);
      return true;
    } catch (_) {
      snack?.show(
        message: l.memoPinFailed,
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(
          label: l.actionRetry,
          onPressed: () => pinDetached(c, snack, l, m),
        ),
      );
      return false;
    }
  }

  /// 삭제 확인(ds Alert Dialog) → 지움. 실패하면 확인창을 닫고 critical 스낵바 + [다시 시도](묻지 않고 같은 삭제를 바로).
  /// 지웠으면 true.
  Future<bool> confirmAndDelete(BuildContext context, Memo m) async {
    final c = ProviderScope.containerOf(context, listen: false);
    final snack = PSnackbar.maybeOf(context);
    final l = AppLocalizations.of(context);
    Object? failure;
    final ok = await PAlertDialog.show(
      context,
      title: deleteConfirmTitle(context, m),
      description: deleteConfirmMessage(context, m),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
      onAction: () async {
        try {
          await remove(c, m);
        } catch (e) {
          failure = e;
        }
      },
    );
    if (!ok) return false;
    if (failure != null) {
      _deleteFailed(c, snack, l, m);
      return false;
    }
    return true;
  }

  void _deleteFailed(
    ProviderContainer c,
    PSnackbarApi? snack,
    AppLocalizations l,
    Memo m,
  ) {
    snack?.show(
      message: l.memoDeleteFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () async {
          try {
            await remove(c, m);
          } catch (_) {
            _deleteFailed(c, snack, l, m);
          }
        },
      ),
    );
  }

  @override
  Future<bool> delete(BuildContext context, WidgetRef ref, Memo m) async {
    try {
      await remove(ProviderScope.containerOf(context, listen: false), m);
      return true;
    } on ApiException {
      return false;
    }
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Memo m) async {
    // showMemoEditDialog 는 void — 닫히기를 기다릴 이유가 없다.
    showMemoEditDialog(context, edit: m);
  }
}
