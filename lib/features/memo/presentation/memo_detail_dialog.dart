import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_colors.dart';
import 'package:groo_damda_app/features/memo/domain/memo_meta.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_actions.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';

enum _DetailAction { edit }

/// 메모 상세(I-15 14) — ds Bottom Sheet 조회. 바깥 누름 · 끌어내림으로 닫힌다.
///
/// 머리 제목 = 메모 제목(줄바꿈, 비면 "제목 없음"). 본문 맨 위 메타 = 색 점 8 + "{태그 또는 태그 없음} · {수정 시각} 수정 · 고정"(고정일 때만
/// 마지막 조각), 그 아래 본문 t5 줄바꿈 그대로(비면 "내용 없음"). 색 히어로 카드 · 테두리 본문 상자 · 핀 배지는 없다.
/// 머리 ⋮ = [고정 / 고정 해제, 삭제(빨강)] — 삭제는 확인창(Alert Dialog)을 먼저 연다. 바닥은 [수정] 하나(바닥 [삭제] 는 걷었다).
/// 상세는 목록의 최신 값으로 그려 고정을 바꾸면 메타 "· 고정" 과 메뉴 글이 바로 따라간다.
Future<void> showMemoDetailDialog(BuildContext context, Memo memo) async {
  final action = await PBottomSheet.show<_DetailAction>(
    context,
    builder: (_) => _MemoDetailSheet(memo: memo),
  );
  if (action == _DetailAction.edit && context.mounted) {
    showMemoEditDialog(context, edit: memo);
  }
}

class _MemoDetailSheet extends ConsumerStatefulWidget {
  const _MemoDetailSheet({required this.memo});
  final Memo memo;

  @override
  ConsumerState<_MemoDetailSheet> createState() => _MemoDetailSheetState();
}

class _MemoDetailSheetState extends ConsumerState<_MemoDetailSheet> {
  bool _busy = false;

  Future<void> _togglePin(Memo m) async {
    if (_busy) return;
    _busy = true;
    try {
      await memoActions.pin(context, m);
    } finally {
      _busy = false;
    }
  }

  Future<void> _delete(Memo m) async {
    if (_busy) return;
    _busy = true;
    try {
      final deleted = await memoActions.confirmAndDelete(context, m);
      if (deleted && mounted) PBottomSheet.of(context).close();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    // 목록의 최신 값으로 그린다 — 고정을 바꾸면 메타 · 메뉴 글이 따라간다. 목록에서 사라졌으면(다시 시도로 지움) 시트도 닫는다
    final list = ref.watch(memoListProvider).value;
    Memo memo = widget.memo;
    if (list != null) {
      final found = list.where((x) => x.rowId == memo.rowId).firstOrNull;
      if (found == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) PBottomSheet.of(context).close();
        });
      } else {
        memo = found;
      }
    }
    final name = memoLabelOf(l, memo);
    final content = (memo.content ?? '').trim();
    final stamp = formatMemoStamp(memo.modifyAt);
    return PBottomSheetContent(
      title: name,
      closeLabel: l.actionClose,
      scrollFog: true,
      headerAction: PButton.icon(
        icon: LucideIcons.ellipsisVertical,
        semanticLabel: l.memoMoreOf(name),
        variant: PButtonVariant.ghost,
        ghostColor: PButtonGhostColor.neutralSubtle,
        size: PButtonSize.small,
        onPressed: () => PMenuSheet.show(
          context,
          title: name,
          groups: [
            PMenuSheetGroup([
              PMenuSheetItem(
                label: memo.pinned ? l.memoUnpin : l.memoPin,
                icon: memo.pinned ? LucideIcons.pinOff : LucideIcons.pin,
                onSelect: () => _togglePin(memo),
              ),
            ]),
            PMenuSheetGroup([
              PMenuSheetItem(
                label: l.actionDelete,
                icon: LucideIcons.trash2,
                tone: PMenuSheetTone.critical,
                onSelect: () => _delete(memo),
              ),
            ]),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: PSpacing.x3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x2,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: 8,
                      child: DecoratedBox(
                        key: const ValueKey('memo-detail-dot'),
                        decoration: BoxDecoration(
                          color: memoSwatch(context, memo.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PTagGroup(
                    size: PTagGroupSize.t3,
                    items: [
                      PTag(memoTagLabel(l, memoTagKey(memo))),
                      if (stamp.isNotEmpty) PTag(l.memoModifiedAt(stamp)),
                      if (memo.pinned) PTag(l.memoPin),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: PSpacing.x2),
            child: Text(
              content.isEmpty ? l.memoDetailNoContent : content,
              key: const ValueKey('memo-detail-content'),
              style: PTypography.t5.copyWith(
                color: content.isEmpty ? c.fgNeutralSubtle : c.fgNeutral,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      footer: [
        PButton(
          label: l.actionEdit,
          size: PButtonSize.large,
          onPressed: () => PBottomSheet.of(context).close(_DetailAction.edit),
        ),
      ],
    );
  }
}
