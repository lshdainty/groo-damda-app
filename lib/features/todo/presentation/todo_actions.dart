import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/actions/item_actions.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart'
    as ds;
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';

/// 할일 하나에 할 수 있는 일 — 목록 행(스와이프)과 상세 다이얼로그가 같은 것을 부른다.
const todoActions = TodoActions();

class TodoActions implements ItemActions<Todo> {
  const TodoActions();

  /// 할일은 전부 사용자가 만든 것이라 막을 게 없다.
  @override
  bool canDelete(Todo t) => true;

  @override
  bool canEdit(Todo t) => true;

  @override
  String deleteConfirmTitle(BuildContext context, Todo t) =>
      AppLocalizations.of(context).todoDeleteTitle;

  @override
  String deleteConfirmMessage(BuildContext context, Todo t) =>
      AppLocalizations.of(context).todoDeleteConfirm(t.title);

  @override
  Future<bool> delete(BuildContext context, WidgetRef ref, Todo t) async {
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.delete(t.rowId);
      ref.invalidate(todoListProvider);
      // 홈 위젯(할 일 개수·최근 할 일)의 원본 — 셸 상주라 스스로 안 받는다.
      // 저장 경로(`todo_edit_dialog`)와 같은 짝을 맞춘다: 지운 항목이 홈에
      // 남아 있으면 목록에서 없는 것을 탭하게 된다.
      ref.invalidate(dashboardSummaryProvider);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// 삭제 확인 → 지움. 확인창 뒤 실패는 공용 [askConfirmThenRequest] — critical 스낵바 + [다시 시도](묻지 않고 바로 지움).
  /// 목록 줄(밀기)과 상세가 같은 길을 쓴다. 지웠으면 true.
  Future<bool> confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Todo t,
  ) async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    void refresh() {
      container.invalidate(todoListProvider);
      // 홈 위젯의 원본 — 지운 항목이 홈에 남지 않게 같은 짝을 맞춘다.
      container.invalidate(dashboardSummaryProvider);
    }

    final ok = await askConfirmThenRequest(
      context,
      title: deleteConfirmTitle(context, t),
      description: deleteConfirmMessage(context, t),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      request: () async {
        final repo = await container.read(todoRepositoryProvider.future);
        await repo.delete(t.rowId, silent: true);
      },
      failedMessage: l.todoDeleteFailed,
      retryLabel: l.actionRetry,
      onRetried: refresh,
    );
    if (ok) refresh();
    return ok;
  }

  /// 밀면 나오는 [수정, 삭제] — 줄을 누르면 상세로 간다(밀기는 지름길이다). 삭제는 상세에서 지울 때와 같은 확인 글을 먼저 묻는다.
  List<ds.PSwipeAction> dsSwipeActions(
    BuildContext context,
    WidgetRef ref,
    Todo t,
  ) {
    final l = AppLocalizations.of(context);
    return [
      ds.PSwipeAction(
        label: l.actionEdit,
        icon: LucideIcons.pencil,
        kind: ds.PSwipeActionKind.primary,
        onSelect: () => edit(context, ref, t),
      ),
      ds.PSwipeAction(
        label: l.actionDelete,
        icon: LucideIcons.trash2,
        kind: ds.PSwipeActionKind.destructive,
        onSelect: () => confirmAndDelete(context, ref, t),
      ),
    ];
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Todo t) async {
    // showTodoEditDialog 는 void — 닫히기를 기다릴 이유가 없다.
    showTodoEditDialog(context, edit: t);
  }
}
