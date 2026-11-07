import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_ledger.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart'
    show PTouchTarget, PTouchTargetScope;
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';

/// 할 일 줄(I-10 12 · 13) — ds List 누르는 줄 + 앞 Checkbox(24 · square · neutral). 줄을 누르면 상세, 체크는 따로 누르는 자리다.
///
/// 제목은 줄바꿈(말줄임 없음) · 위 맞춤, 설명은 Tag Group 한 줄(태그 이름 또는 "태그 없음" · 메모가 있으면 "메모"), 뒤는 우선순위
/// Badge(중요만 critical, 보통 · 여유 neutral — 사용자 결정 10-23). 줄 끝에 ⋮ 를 두지 않는다(사용자 10-25) — 수정 · 삭제는
/// 줄을 눌러 상세로 가거나 밀어서 한다.
///
/// 끝낸 줄은 취소선 + `fg-disabled` 로 그리고 흐리지 않는다 — 누름 · 상세는 그대로다(막힌 줄이 아니다).
/// 체크 이름은 "{제목} 완료"(끝냄은 체크 상태가 읽는다), 지난 마감이면 ", 마감 지남" — 색만으로 알리지 않는다.
/// 누르면 바로 바뀐다: 요청 중에도 칸을 막지 않고 스피너를 그리지 않는다(낙관 갱신은 화면이 한다).
class TodoRow extends StatelessWidget {
  const TodoRow({
    super.key,
    required this.todo,
    required this.today,
    required this.onToggle,
    required this.onOpen,
  });

  final Todo todo;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final done = todo.done;
    final overdue = !done && isTodoOverdue(todo.due, today);
    final hasNote = (todo.content ?? '').trim().isNotEmpty;
    final tone = done ? PTagTone.disabled : null;
    return PTouchTargetScope(
      child: PListButtonItem(
        align: PListAlign.top,
        title: todo.title,
        titleStrike: done,
        titleColor: done ? c.fgDisabled : null,
        onTap: onOpen,
        detailChild: _ColorFade(
          // 끝냄 ↔ 안 끝냄이 바뀌면 설명 색이 옮겨 간다(제목 색은 List 가 같은 시간 · 곡선으로 옮긴다)
          stateKey: done,
          child: PTagGroup(
            size: PTagGroupSize.t3,
            overflow: PTagGroupOverflow.truncate,
            items: [
              PTag(todoTagLabel(l, todoTagOf(todo)), tone: tone),
              if (hasNote) PTag(l.todoMemoTag, tone: tone, shrink: 0),
            ],
          ),
        ),
        prefix: PListAction(
          child: _TodoCheck(
            title: todo.title,
            done: done,
            overdue: overdue,
            onToggle: onToggle,
          ),
        ),
        // 값(PListValue)으로 감싸 좁은 줄(큰 글자)에서 설명 아래로 내려가게 한다 — _ColorFade 가 배지를 한 겹 싸고 있어서다
        suffix: PListValue(
          child: _ColorFade(
            stateKey: done,
            child: PBadge(
              label: todoPrioLabel(l, todo.priority),
              tone: todo.priority == 'HIGH'
                  ? PBadgeTone.critical
                  : PBadgeTone.neutral,
              disabled: done,
            ),
          ),
        ),
      ),
    );
  }
}

/// 색이 바뀌는 순간의 모션 — `motion-duration-color-transition`(150ms) × `motion-ease-easing`, 모션 줄이기면 바로 바뀐다(I-10 13).
///
/// 글자 색이 조각마다 정해지는 부품(Tag Group · Badge)은 색 하나를 옮길 수 없어, 같은 자리에 같은 크기로 서는 앞뒤 모습을
/// 서로 비춰 보인다(웹 `transition-colors` 와 같은 시간 · 곡선). [stateKey] 가 바뀔 때만 움직인다.
class _ColorFade extends StatelessWidget {
  const _ColorFade({required this.stateKey, required this.child});

  final bool stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : PDuration.colorTransition,
      switchInCurve: PEasing.easing,
      switchOutCurve: PEasing.easing,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

/// 체크 — Checkbox large 24 · square · neutral. 칸만 그리고 누르는 자리는 44(칸 둘레로 넓힌다). 지난 마감은 칸 테두리만
/// `stroke-critical-solid`.
class _TodoCheck extends StatelessWidget {
  const _TodoCheck({
    required this.title,
    required this.done,
    required this.overdue,
    required this.onToggle,
  });

  final String title;
  final bool done;
  final bool overdue;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return PTouchTarget(
      minSize: PTouch.min,
      child: PressArea(
        enabled: true,
        onTap: onToggle,
        activateOnEnter: false,
        touchMin: 0,
        semantics: (child, enabled, onTap) => Semantics(
          container: true,
          enabled: enabled,
          checked: done,
          label: overdue
              ? l.todoCheckNameOverdue(title)
              : l.todoCheckName(title),
          onTap: onTap,
          child: child,
        ),
        builder: (context, pressed, _) => Stack(
          children: [
            PCheckmark(
              checked: done,
              size: PCheckboxSize.large,
              pressed: pressed,
            ),
            if (overdue && !done)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('todo-check-overdue'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(PRounded.r1),
                      border: Border.all(color: c.strokeCriticalSolid),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 날짜 묶음 하나 — 머리(List Header mediumWeak + 오른쪽 "2/5 완료") + 할 일 줄. 묶음 위 16 · 첫 묶음 8(I-10 16 — 가계부 12 / 4 와
/// 다르다, 그림대로).
///
/// 줄은 밀면 [수정, 삭제](ds Swipe Actions)가 나온다 — 줄을 누르면 상세다. 마감일 없는 묶음([ymd] 가 null)은 날짜 대신 "마감일 없음".
class TodoDayGroup extends ConsumerWidget {
  const TodoDayGroup({
    super.key,
    required this.ymd,
    required this.items,
    required this.today,
    required this.first,
    required this.onToggle,
    required this.onOpen,
  });

  /// `YYYY-MM-DD` — null 이면 마감일 없는 묶음.
  final String? ymd;
  final List<Todo> items;
  final DateTime today;
  final bool first;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<Todo> onOpen;

  /// 머리 글 — "10월 21일 (수) · 어제" · 마감일 없으면 "마감일 없음".
  static String headText(AppLocalizations l, String? ymd, DateTime today) {
    if (ymd == null) return l.todoNoDue;
    final d = DateTime.parse(ymd);
    final rel = switch (todoRelDayOf(d, today)) {
      TodoRelDay.today => l.dateToday,
      TodoRelDay.tomorrow => l.dateTomorrow,
      TodoRelDay.yesterday => l.dateYesterday,
      null => null,
    };
    return '${monthDayDow(d)}${rel == null ? '' : ' · $rel'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final doneN = items.where((x) => x.done).length;
    return Padding(
      padding: EdgeInsets.only(top: first ? PSpacing.x2 : PSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PDayHeaderRow(
            text: headText(l, ymd, today),
            trailing: PText(
              l.tdmDoneRatio(doneN, items.length),
              maxLines: 1,
              softWrap: false,
              style: PDayHeaderRow.textStyle(c),
            ),
          ),
          for (final x in items)
            PSwipeActions(
              key: ValueKey('todo-${x.rowId}'),
              rowLabel: x.title,
              actions: todoActions.dsSwipeActions(context, ref, x),
              child: TodoRow(
                todo: x,
                today: today,
                onToggle: () => onToggle(x),
                onOpen: () => onOpen(x),
              ),
            ),
        ],
      ),
    );
  }
}

/// 불러오는 동안의 날짜 묶음 — 머리 한 줄 + 할 일 줄 [rows] 개(체크 24 · 제목 · 설명). 실제 줄과 같은 여백이다.
class TodoDaySkeleton extends StatelessWidget {
  const TodoDaySkeleton({super.key, required this.rows, this.first = false});

  final int rows;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? PSpacing.x2 : PSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x2,
            ),
            child: Row(
              children: [
                PSkeleton.text(PTypography.t4, width: 96),
                const Spacer(),
                PSkeleton.text(PTypography.t4, width: 56),
              ],
            ),
          ),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
                vertical: PSpacing.x3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PSkeleton(
                    width: 24,
                    height: 24,
                    radius: PSkeletonRadius.r4,
                  ),
                  const SizedBox(width: PSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: PSpacing.x0_5,
                      children: [
                        PSkeleton.text(PTypography.t5, width: 160),
                        PSkeleton.text(PTypography.t3, width: 56),
                      ],
                    ),
                  ),
                  const SizedBox(width: PSpacing.x2),
                  const PSkeleton(width: 40, height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
