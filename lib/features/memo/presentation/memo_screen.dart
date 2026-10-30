import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_list.dart';
import 'package:groo_damda_app/features/memo/domain/memo_meta.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_actions.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_detail_dialog.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:groo_damda_app/features/memo/presentation/widgets/memo_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/p_floating_action_button.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 메모 폰 화면(I-15 5 ~ 12) — 흰 면 하나: 상단 바(← "메모") → 밑줄형 검색칸 → 태그 칩 줄(가로로 밀림) → "고정 · N" + 줄 →
/// "모든 메모 · N" + 줄 → 떠 있는 [+](메모 추가). 띠 · 카드 · 줄 사이 선이 없고 흰 면이 화면 아래 끝까지 닿는다.
/// 줄을 밀면 [고정 / 해제, 수정, 삭제] — 줄 끝 ⋮ 는 두지 않는다(좁은 목록 줄 — 10-25).
///
/// 실패 안내는 서버 원문이 아니라 고정 글이다(요청은 전역 오류 알림을 끈다) — 목록 실패는 Result Section, 고정 · 삭제 실패는 스낵바 + [다시 시도].
class MemoScreen extends ConsumerStatefulWidget {
  const MemoScreen({super.key});
  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen> {
  String _query = '';

  /// 거르기 값 — [kMemoAllKey] 전체 · [kMemoNoTagKey] 태그 없음 · 그 밖은 태그 이름.
  String _tagFilter = kMemoAllKey;

  /// 고정 토글 진행 중인 메모 — 같은 메모의 두 번째 누름을 버린다.
  final _pinning = <int>{};

  Future<void> _togglePin(Memo m) async {
    if (!_pinning.add(m.rowId)) return;
    try {
      await memoActions.pin(context, m);
    } finally {
      _pinning.remove(m.rowId);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(memoListProvider);
    ref.invalidate(memoTagListProvider);
    try {
      await ref.read(memoListProvider.future);
    } on Object {
      // 실패는 화면의 실패 상자가 말한다
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final async = ref.watch(memoListProvider);
    final tags = ref.watch(memoTagListProvider).value;
    // 다시 받는 동안에도 이전 목록을 그대로 둔다
    final all = async.hasValue ? async.requireValue : null;
    final failed = all == null && async.hasError && !async.isLoading;
    final loading = all == null && !failed;

    final filtered = all == null
        ? const <Memo>[]
        : filterMemos(all, _query, _tagFilter);
    final pinned = [
      for (final m in filtered)
        if (m.pinned) m,
    ];
    final others = [
      for (final m in filtered)
        if (!m.pinned) m,
    ];
    // 고른 거르기 값이 사라졌으면(메모를 지워 0건) 전체로 — 칩이 없는데 걸린 채로 두지 않는다
    final chips = all == null ? const <MemoTagChip>[] : memoTagChips(all, tags);
    if (_tagFilter != kMemoAllKey && !chips.any((x) => x.key == _tagFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tagFilter = kMemoAllKey);
      });
    }

    final Widget body;
    if (failed) {
      // 질의 하나 = 실패 상자 하나 — 원문을 그리지 않는다.
      body = PResultSection(
        kind: PResultKind.failure,
        title: l.memoLoadError,
        description: l.memoLoadFailedDesc,
        primaryAction: PResultAction(
          label: l.actionRetry,
          onPressed: () => ref.invalidate(memoListProvider),
        ),
      );
    } else if (loading) {
      body = Column(
        children: [for (var i = 0; i < 4; i++) const _MemoRowSkeleton()],
      );
    } else if (filtered.isEmpty) {
      // 메모 0 — 버튼 없음(떠 있는 + 가 맡는다)
      body = _query.trim().isNotEmpty
          ? PResultSection(
              icon: LucideIcons.searchX,
              title: l.memoSearchEmpty,
              description: l.memoSearchEmptyDesc,
            )
          : PResultSection(
              icon: LucideIcons.stickyNote,
              title: l.memoEmpty,
              description: l.memoEmptyDesc,
            );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pinned.isNotEmpty) ...[
            PListHeader(title: l.memoSectionPinned(pinned.length)),
            _rows(pinned),
          ],
          if (others.isNotEmpty) ...[
            // "모든 메모" 위 16 — 고정이 없으면 제목도 두지 않는다
            if (pinned.isNotEmpty)
              PListHeader(
                title: l.memoSectionAll(others.length),
                topInset: PSpacing.x4,
              ),
            _rows(others),
          ],
        ],
      );
    }

    return Scaffold(
      // 흰 면 하나 — 상단 바 아래가 끝까지 흰 면이다(1-A). 띠 · 카드를 두지 않는다
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.memoTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Stack(
        key: const ValueKey('memo-white-screen'),
        children: [
          PSwipeActionsProvider(
            child: PPullToRefresh(
              onRefresh: _refresh,
              child: ListView(
                // 아래 96 은 떠 있는 [+] 가 마지막 줄을 가리지 않게 하는 흰 면 안 여백
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  // 검색칸 — 밑줄형 large. 흰 면 안 위 4 · 좌우 24
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PSpacing.globalGutter,
                      PSpacing.x1,
                      PSpacing.globalGutter,
                      0,
                    ),
                    child: PInput(
                      variant: PInputVariant.underline,
                      placeholder: l.memoSearchHint,
                      semanticLabel: l.memoSearchHint,
                      prefixIcon: LucideIcons.search,
                      clearable: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (!failed && !loading && all!.isNotEmpty)
                    // 칩 줄 — 위 12 · 아래 4. 한 줄로 가로로 밀린다
                    Padding(
                      padding: const EdgeInsets.only(
                        top: PSpacing.x3,
                        bottom: PSpacing.x1,
                      ),
                      child: PChipRadioGroup<String>(
                        layout: PChipGroupLayout.scroll,
                        semanticLabel: l.memoTagFilter,
                        value: _tagFilter,
                        onChanged: (v) => setState(() => _tagFilter = v),
                        children: [
                          PChipRadio<String>(
                            value: kMemoAllKey,
                            label: l.memoAllChip,
                            count: all.length,
                            variant: PChipVariant.outlineStrong,
                            size: PChipSize.small,
                          ),
                          for (final chip in chips)
                            PChipRadio<String>(
                              value: chip.key,
                              label: memoTagLabel(l, chip.key),
                              count: chip.count,
                              variant: PChipVariant.outlineStrong,
                              size: PChipSize.small,
                            ),
                        ],
                      ),
                    ),
                  body,
                ],
              ),
            ),
          ),
          // 떠 있는 [+] — 추가 폼을 연다
          PFloatingActionButton(
            icon: LucideIcons.plus500,
            label: l.memoNew,
            onPressed: () => showMemoEditDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _rows(List<Memo> items) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        for (final m in items)
          PSwipeActions(
            key: ValueKey('memo-${m.rowId}'),
            rowLabel: memoLabelOf(l, m),
            actions: [
              PSwipeAction(
                label: m.pinned ? l.memoSwipeUnpin : l.memoPin,
                icon: m.pinned ? LucideIcons.pinOff : LucideIcons.pin,
                onSelect: () => _togglePin(m),
              ),
              PSwipeAction(
                label: l.actionEdit,
                icon: LucideIcons.pencil,
                kind: PSwipeActionKind.primary,
                onSelect: () => showMemoEditDialog(context, edit: m),
              ),
              PSwipeAction(
                label: l.actionDelete,
                icon: LucideIcons.trash2,
                kind: PSwipeActionKind.destructive,
                // 상세에서 지울 때와 같은 확인창 · 같은 글
                onSelect: () => memoActions.confirmAndDelete(context, m),
              ),
            ],
            child: PList(
              semanticLabel: l.memoTitle,
              children: [
                MemoRow(
                  memo: m,
                  onOpen: () => showMemoDetailDialog(context, m),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 첫 진입 — 점 8 · 제목 · 본문 · 메타 세 줄 높이의 줄 자리(실제 줄과 같은 좌우 24 · 위아래 12).
class _MemoRowSkeleton extends StatelessWidget {
  const _MemoRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.globalGutter,
        vertical: PSpacing.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: PSkeleton(width: 8, height: 8, radius: PSkeletonRadius.full),
          ),
          const SizedBox(width: PSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x0_5,
              children: [
                PSkeleton.text(PTypography.t5, width: 140),
                PSkeleton.text(PTypography.t4, width: 200),
                PSkeleton.text(PTypography.t3, width: 96),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
