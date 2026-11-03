import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_ledger.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_actions.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/widgets/markdown_preview.dart';

enum _DetailAction { edit }

/// 할 일 상세(I-10 21) — ds Bottom Sheet 조회. 행을 누르면 읽기 전용 상세가 열리고, 바깥 누름 · 끌어내림으로 닫힌다.
///
/// 맨 위는 할 일 제목(t6 · 700 · 줄바꿈, 끝냈으면 취소선 + `fg-disabled`)이고 우선순위 틴트 머리 카드 · 원 아이콘 · 가운데 맞춤은 없다.
/// 그 아래 보기만 하는 List 줄(마감일 · 태그 · 우선순위 · 상태 · 완료 일시), 메모는 줄 아래 따로 둔다. 바닥은 [삭제] · [수정].
/// [수정] 은 상세를 닫고 수정 폼을 연다. [삭제] 는 확인(Alert Dialog)을 거쳐 지운 뒤 상세를 닫는다.
Future<void> showTodoDetailDialog(BuildContext context, Todo todo) async {
  final action = await PBottomSheet.show<_DetailAction>(
    context,
    builder: (_) => _TodoDetailSheet(todo: todo),
  );
  if (action == _DetailAction.edit && context.mounted) {
    showTodoEditDialog(context, edit: todo);
  }
}

class _TodoDetailSheet extends ConsumerStatefulWidget {
  const _TodoDetailSheet({required this.todo});
  final Todo todo;

  @override
  ConsumerState<_TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends ConsumerState<_TodoDetailSheet> {
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;
    final l = AppLocalizations.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: todoActions.deleteConfirmTitle(context, widget.todo),
      description: todoActions.deleteConfirmMessage(context, widget.todo),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      // 삭제는 todoActions 가 한다 — 목록 줄(밀기)도 같은 것을 부른다.
      final deleted = await todoActions.delete(context, ref, widget.todo);
      if (deleted && mounted) PBottomSheet.of(context).close();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final todo = widget.todo;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = !todo.done && isTodoOverdue(todo.due, today);
    final content = (todo.content ?? '').trim();
    // completedAt 은 서버 `[UTC]` — 잘라 쓰면 UTC 벽시계가 그대로 나와 KST(+9)에서 9시간 전으로, 자정 근처면 날짜까지 하루 어긋나
    // 보였다. 웹 TodoPage 상세와 같은 모양(yyyy-MM-dd HH:mm)으로 파싱해 찍고, 못 읽는 값만 원문을 그대로 둔다.
    final completedAt = localDateTime(todo.completedAt) ?? todo.completedAt;
    final due = todo.due;

    Widget value(String text, {Color? color, FontWeight? weight}) => Text(
      text,
      style: TextStyle(color: color, fontWeight: weight),
    );

    return PBottomSheetContent(
      title: l.todoDetailTitle,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
            ),
            child: Text(
              todo.title,
              key: const ValueKey('todo-detail-title'),
              style: PTypography.t6.copyWith(
                color: todo.done ? c.fgDisabled : c.fgNeutral,
                fontWeight: FontWeight.w700,
                decoration: todo.done ? TextDecoration.lineThrough : null,
                decorationColor: todo.done ? c.fgDisabled : null,
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x2),
          PList(
            semanticLabel: l.todoDetailTitle,
            children: [
              PListItem(
                title: l.todoDueDate,
                // 지난 마감이면 값 글자를 빨갛게 하고 ", 마감 지남" 을 덧붙인다 — 색만으로 알리지 않는다.
                suffix: value(
                  due == null
                      ? l.todoNoDue
                      : '${monthDayDow(due)}${overdue ? ', ${l.todoDetailOverdue}' : ''}',
                  color: overdue ? c.fgCritical : null,
                ),
              ),
              PListItem(
                title: l.todoTag,
                suffix: value(todoTagLabel(l, todoTagOf(todo))),
              ),
              PListItem(
                title: l.todoPriorityLabel,
                suffix: PBadge(
                  label: todoPrioLabel(l, todo.priority),
                  tone: todo.priority == 'HIGH'
                      ? PBadgeTone.critical
                      : PBadgeTone.neutral,
                ),
              ),
              PListItem(
                title: l.todoDetailStatus,
                suffix: value(
                  todo.done ? l.todoStatusCompleted : l.todoStatusPending,
                ),
              ),
              if (todo.done && completedAt != null)
                PListItem(
                  title: l.todoDetailCompletedAt,
                  suffix: value(completedAt),
                ),
            ],
          ),
          const SizedBox(height: PSpacing.x2),
          // 메모는 키-값 줄 값으로 두지 않고 줄 아래 따로 — 긴 메모가 값 칸에 들지 않는다.
          PListHeader(title: l.todoContentLabel, headingLevel: 3),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
            ),
            child: content.isEmpty
                ? Text(
                    l.todoNoContent,
                    style: PTypography.t5.copyWith(color: c.fgNeutralSubtle),
                  )
                : MarkdownPreview(content),
          ),
          const SizedBox(height: PSpacing.x2),
        ],
      ),
      footer: [
        PButton(
          label: l.actionDelete,
          size: PButtonSize.large,
          variant: PButtonVariant.neutralWeak,
          loading: _deleting,
          onPressed: _deleting ? null : _delete,
        ),
        PButton(
          label: l.actionEdit,
          size: PButtonSize.large,
          onPressed: _deleting
              ? null
              : () => PBottomSheet.of(context).close(_DetailAction.edit),
        ),
      ],
    );
  }
}
