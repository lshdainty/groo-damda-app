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
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 메모 상세(I-15 14) — ds Bottom Sheet 조회. 바깥 누름 · 끌어내림으로 닫힌다.
///
/// 머리 제목 = 메모 제목(줄바꿈, 비면 "제목 없음"). 본문 맨 위 메타 = 색 점 8 + "{태그 또는 태그 없음} · {수정 시각} 수정 · 고정"(고정일 때만
/// 마지막 조각), 그 아래 본문 t5 줄바꿈 그대로(비면 "내용 없음"). 색 히어로 카드 · 테두리 본문 상자 · 핀 배지는 없다.
/// 머리 ⋮ = [고정 / 고정 해제, 삭제(빨강)] — 삭제는 확인창(Alert Dialog)을 먼저 연다. 바닥은 [수정] 하나(바닥 [삭제] 는 걷었다).
/// 상세는 목록의 최신 값으로 그려 고정을 바꾸면 메타 "· 고정" 과 메뉴 글이 바로 따라간다.
Future<void> showMemoDetailDialog(BuildContext context, Memo memo) async {
  // [수정] 은 상세가 그리던 **최신 값**(고정을 바꿨으면 바뀐 값)을 돌려준다 — 처음 받은 값으로 폼을 열면 고정 스위치가 어긋난다
  final toEdit = await PBottomSheet.show<Memo>(
    context,
    builder: (_) => _MemoDetailSheet(memo: memo),
  );
  if (toEdit != null && context.mounted) {
    showMemoEditDialog(context, edit: toEdit);
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

  /// 시트를 닫았다 — 삭제 성공 뒤 닫기와 "목록에서 사라졌다" 닫기가 겹쳐 두 번 pop 되면 시트 밑 화면(메모 화면)까지 빠진다. 한 번만 닫는다.
  bool _closed = false;

  void _closeOnce([Memo? result]) {
    if (_closed || !mounted) {
      return;
    }
    _closed = true;
    PBottomSheet.of(context).close(result);
  }

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
      if (deleted) {
        _closeOnce();
      }
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _closeOnce());
      } else {
        memo = found;
      }
    }
    final name = memoLabelOf(l, memo);
    // 본문은 trim 하지 않는다(들여쓰기도 사용자 글) — 비었는지만 trim 으로 본다
    final raw = memo.content ?? '';
    final blank = raw.trim().isEmpty;
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
              // 낱말 단위 줄바꿈(v114) — 읽는 글이라 건다. 읽는 이름은 원래 글
              keepAll(blank ? l.memoDetailNoContent : raw),
              semanticsLabel: blank ? l.memoDetailNoContent : raw,
              key: const ValueKey('memo-detail-content'),
              // 긴 글 본문 R11 16/24(DESIGN.desk.md:2688) — 일정 상세의 본문과 같다
              style: PTypography.articleBody.copyWith(
                color: blank ? c.fgNeutralSubtle : c.fgNeutral,
              ),
            ),
          ),
        ],
      ),
      footer: [
        PButton(
          label: l.actionEdit,
          size: PButtonSize.large,
          onPressed: () => _closeOnce(memo),
        ),
      ],
    );
  }
}
