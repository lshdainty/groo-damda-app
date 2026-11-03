import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/todo/domain/todo_ledger.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';

/// 폰 거르기 시트(I-10 23) — ds Bottom Sheet(고르기). 바깥 누름 · 끌어내림으로 닫힌다.
///
/// 바꾸는 즉시 목록에 걸린다 — [onApply] 가 그때그때 화면에 값을 넘긴다. 바닥은 [초기화](걸린 것이 없으면 막힘) · [완료](닫기).
/// 본문은 태그 칩 묶음 · 우선순위 칩 묶음 · "완료한 할 일 숨기기" 스위치 줄. 칩에 색 점을 달지 않는다.
Future<void> showTodoFilterSheet(
  BuildContext context, {
  required TodoFilterState initial,
  required List<String> allTags,
  required ValueChanged<TodoFilterState> onApply,
}) => PBottomSheet.show<void>(
  context,
  builder: (_) =>
      _TodoFilterSheet(initial: initial, allTags: allTags, onApply: onApply),
);

class _TodoFilterSheet extends StatefulWidget {
  const _TodoFilterSheet({
    required this.initial,
    required this.allTags,
    required this.onApply,
  });

  final TodoFilterState initial;
  final List<String> allTags;
  final ValueChanged<TodoFilterState> onApply;

  @override
  State<_TodoFilterSheet> createState() => _TodoFilterSheetState();
}

class _TodoFilterSheetState extends State<_TodoFilterSheet> {
  late TodoFilterState _f = widget.initial;

  void _set(TodoFilterState next) {
    setState(() => _f = next);
    widget.onApply(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PBottomSheetContent(
      title: l.expFilter,
      closeLabel: l.actionClose,
      flushBody: true,
      body: TodoFilterBody(
        filter: _f,
        allTags: widget.allTags,
        onChanged: _set,
      ),
      footer: [
        PButton(
          label: l.actionReset,
          size: PButtonSize.large,
          variant: PButtonVariant.neutralWeak,
          onPressed: _f.active ? () => _set(TodoFilterState.empty) : null,
        ),
        PButton(
          label: l.actionDone,
          size: PButtonSize.large,
          onPressed: () => PBottomSheet.of(context).close(),
        ),
      ],
    );
  }
}

/// 거르기 본문 — 태그 · 우선순위 · 완료 숨기기. 시트가 쓰고, 넓은 화면의 필터 바(10-2)도 같은 묶음을 쓴다.
class TodoFilterBody extends StatelessWidget {
  const TodoFilterBody({
    super.key,
    required this.filter,
    required this.allTags,
    required this.onChanged,
  });

  final TodoFilterState filter;
  final List<String> allTags;
  final ValueChanged<TodoFilterState> onChanged;

  static Set<String> _toggle(Set<String> set, String key, bool on) {
    final next = {...set};
    on ? next.add(key) : next.remove(key);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget pad(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
      child: child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListHeader(title: l.tdmFilterTag),
        pad(
          PChipGroup(
            semanticLabel: l.tdmFilterTag,
            children: [
              for (final tag in allTags)
                PChipToggle(
                  // sentinel 은 문구로 바꿔 그린다 — 그대로 그리면 안 보이는 글자 하나가 칩 안에 남는다.
                  label: todoTagLabel(l, tag),
                  checked: filter.tags.contains(tag),
                  onChanged: (on) => onChanged(
                    filter.copyWith(tags: _toggle(filter.tags, tag, on)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PSpacing.x4),
        PListHeader(title: l.todoPriorityLabel),
        pad(
          PChipGroup(
            semanticLabel: l.todoPriorityLabel,
            children: [
              for (final p in kTodoPrios)
                PChipToggle(
                  label: todoPrioLabel(l, p.code),
                  checked: filter.prios.contains(p.code),
                  onChanged: (on) => onChanged(
                    filter.copyWith(prios: _toggle(filter.prios, p.code, on)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PSpacing.x4),
        PList(
          children: [
            PListSwitchItem(
              title: l.tdmHideDone,
              checked: filter.hideDone,
              onChanged: (v) => onChanged(filter.copyWith(hideDone: v)),
            ),
          ],
        ),
      ],
    );
  }
}
