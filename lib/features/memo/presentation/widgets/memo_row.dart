import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_colors.dart';
import 'package:groo_damda_app/features/memo/domain/memo_meta.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 메모 줄(I-15 9) — ds List 누르는 줄. 위 맞춤(제목이 두 줄을 넘는다) · 앞 색 점 8(위 7 — 제목 첫 줄 가운데) · 제목 t5 줄바꿈
/// (말줄임 없음, 비면 "제목 없음") · 본문 한 줄(t4 muted, 한 줄 말줄임, 비면 줄을 두지 않는다) · 메타 Tag Group t3 한 줄 말줄임
/// "{태그 또는 태그 없음} · {수정 시각}"(시각이 비면 조각을 뺀다).
///
/// 줄 안 고정 표시 · 줄 사이 선 · 줄 끝 ⋮ 는 두지 않는다 — 고정은 묶음 제목 "고정 · N" 이 말하고, 고정 / 수정 / 삭제는 밀기 · 상세 · 폼이 맡는다
/// (좁은 목록 줄에는 ⋮ 를 두지 않는다 — 10-25).
class MemoRow extends StatelessWidget {
  const MemoRow({super.key, required this.memo, required this.onOpen});

  final Memo memo;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final hasTitle = (memo.title ?? '').isNotEmpty;
    // 줄바꿈 · 연속 공백은 공백 하나로 이어 한 줄 말줄임(웹과 같은 규칙) — 첫 줄만 보이지 않는다
    final content = memoPreview(memo.content);
    final stamp = formatMemoStamp(memo.modifyAt);
    return PListButtonItem(
      align: PListAlign.top,
      title: hasTitle ? memo.title! : l.memoUntitled,
      titleColor: hasTitle ? null : c.fgNeutralSubtle,
      onTap: onOpen,
      // 장식 — 색 점 8 은 제목 첫 줄(22) 가운데에 오게 위 7
      prefix: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: 8,
            child: DecoratedBox(
              key: const ValueKey('memo-dot'),
              decoration: BoxDecoration(
                color: memoSwatch(context, memo.color),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
      detailChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.isNotEmpty)
            Text(
              keepAll(content),
              semanticsLabel: content,
              key: const ValueKey('memo-body'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PTypography.t4.copyWith(
                color: c.fgNeutralMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          PTagGroup(
            size: PTagGroupSize.t3,
            overflow: PTagGroupOverflow.truncate,
            items: [
              PTag(memoTagLabel(l, memoTagKey(memo))),
              if (stamp.isNotEmpty) PTag(stamp),
            ],
          ),
        ],
      ),
    );
  }
}
