import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_actions.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_detail_sheet.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_edit_dialog.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

enum PresetSortKey { used, recent, name }

/// 정렬 — 이름과 순서는 지금 그대로(화면에만 둔다, 서버 · 주소에 싣지 않는다). 웹 `PresetManager` 와 같은 셈이다.
List<ExpenseTemplate> sortPresets(
  List<ExpenseTemplate> items,
  PresetSortKey key,
) {
  final arr = [...items];
  switch (key) {
    case PresetSortKey.used:
      arr.sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
    case PresetSortKey.recent:
      arr.sort((a, b) => (b.lastUsedAt ?? '').compareTo(a.lastUsedAt ?? ''));
    case PresetSortKey.name:
      // 한국어 로케일 오름차순 (Dart 기본 코드포인트 비교 = 한글 가나다순 정합).
      arr.sort((a, b) => a.templateName.compareTo(b.templateName));
  }
  return arr;
}

/// 프리셋 관리(설정 > 프리셋 관리) — 웹 `PresetManager.tsx` 미러(I-20 C 13 ~ 18).
///
/// 폰은 흰 면 하나다: 머리(← + "추가") → 목록 제목("프리셋 n개") → 정렬 Segmented → 줄. 안내 상자 · 숫자 셋은 없고 안내는 빈 화면에만
/// 있다. 줄 누름 = 상세(수정 · 삭제는 상세 바닥), 밀면 [수정][삭제] 지름길이다 — 줄 끝 ⋮ 는 없다(2026-10-25 원칙).
class PresetScreen extends ConsumerStatefulWidget {
  const PresetScreen({super.key});

  @override
  ConsumerState<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends ConsumerState<PresetScreen> {
  PresetSortKey _sortBy = PresetSortKey.used;

  void _add() => showPresetEditDialog(context);

  Future<void> _openDetail(ExpenseTemplate p) async {
    final act = await showPresetDetailSheet(context, template: p);
    if (act == PresetDetailAction.edit && mounted) {
      await showPresetEditDialog(context, edit: p);
    }
  }

  /// 밀기의 [삭제] — 확인창 한 번. 실패하면 확인창을 닫고 스낵바(고정 글 + 다시 시도)로 알린다(전역 오류 토스트와 겹치지 않는다).
  Future<void> _confirmDelete(ExpenseTemplate p) async {
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.of(context);
    final container = ProviderScope.containerOf(context);
    final r = await askDeletePreset(context, p);
    if (r.confirmed && r.failure != null) {
      // 응답을 못 받았으면 지워졌을 수 있다 — [다시 시도] 없이 다시 받고 한 문장(판단 ①). 아니면 실패 띠 + [다시 시도]
      // (묻지 않고 바로 지운다 — 이미 확인창에서 한 번 확정한 삭제다)
      showConfirmFailSnackbar(
        snack,
        error: r.failure,
        message: l.presetDeleteFailed,
        retryLabel: l.actionRetry,
        retry: () => deletePresetRequest(container, p.rowId),
        unconfirmedMessage: unconfirmedWriteText(l, WriteKind.delete),
        onUnconfirmed: () => container.invalidate(presetListProvider),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final listAsync = ref.watch(presetListProvider);
    final catsAsync = ref.watch(categoriesProvider);
    // 두 조회 중 하나라도 값 없이 실패면 실패 화면이다 — 다시 받는 동안(AsyncLoading + 이전 오류)도 실패를 그대로 두고
    // [다시 시도] 에 진행 원(skeleton.md:139). 그 밖에 값이 없는 쪽이 있으면 첫 로딩이다.
    final failed = listAsync.loadFailed || catsAsync.loadFailed;
    final loading = !failed && (!listAsync.hasValue || !catsAsync.hasValue);
    final items = listAsync.value ?? const <ExpenseTemplate>[];

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목 + 글 버튼 "추가") — 비어 있거나 불러오는 중 · 실패에서는 "추가" 를 두지 않는다
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.presetManageTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
          actions: [
            if (!loading && !failed && items.isNotEmpty)
              PTopNavigationTextButton(
                label: l.presetAddAction,
                onPressed: _add,
              ),
          ],
        ),
      ),
      body: PScreenBandBody(
        child: PSwipeActionsProvider(
          child: PPullToRefresh(
            onRefresh: () async {
              ref.invalidate(presetListProvider);
              ref.invalidate(categoriesProvider);
              try {
                await ref.read(presetListProvider.future);
              } catch (_) {}
            },
            child: loading
                ? loadingRegion(const _PresetSkeleton())
                : failed
                ? _failure(l)
                : items.isEmpty
                ? _empty(l)
                : _list(l, items, catsAsync.requireValue),
          ),
        ),
      ),
    );
  }

  /// 본문 높이를 채워 가운데에 놓는다(웹과 같다) — 새로 고침은 그대로 된다.
  Widget _centered(Widget child) => CustomScrollView(
    slivers: [
      SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
    ],
  );

  Widget _failure(AppLocalizations l) => _centered(
    PResultSection(
      kind: PResultKind.failure,
      size: PResultSize.large,
      title: l.presetLoadFailed,
      description: l.dashFailDesc,
      primaryAction: PResultAction(
        label: l.actionRetry,
        loading: anyLoadRetrying([
          ref.watch(presetListProvider),
          ref.watch(categoriesProvider),
        ]),
        onPressed: () {
          if (!ref.read(presetListProvider).hasValue) {
            ref.invalidate(presetListProvider);
          }
          if (!ref.read(categoriesProvider).hasValue) {
            ref.invalidate(categoriesProvider);
          }
        },
      ),
    ),
  );

  /// 빈 화면 — 안내는 여기에만. 머리 버튼이 없어서 본문 버튼이 하나다.
  Widget _empty(AppLocalizations l) => _centered(
    PResultSection(
      kind: PResultKind.empty,
      size: PResultSize.large,
      icon: LucideIcons.bookmark,
      title: l.presetEmptyTitle,
      description: l.presetEmptyDesc,
      primaryAction: PResultAction(
        label: l.presetAdd,
        onPressed: _add,
        icon: LucideIcons.plus,
      ),
    ),
  );

  Widget _list(
    AppLocalizations l,
    List<ExpenseTemplate> items,
    List<ExpenseCategory> categories,
  ) {
    final masked = ref.watch(hideCardProvider('etc.preset'));
    final sorted = sortPresets(items, _sortBy);
    final title = l.presetListTitle(items.length);
    return ListView(
      // 끝 숨 24 는 흰 면 안(T8)
      padding: EdgeInsets.only(
        bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        PListHeader(title: title, variant: PListHeaderVariant.boldSolid),
        // 정렬은 그 목록을 조절하는 줄 — 목록 제목과 한 덩어리(T6 — 0 + 위아래 4)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
            vertical: PSpacing.x1,
          ),
          child: PSegmentedControl<PresetSortKey>(
            value: _sortBy,
            semanticLabel: l.presetSortLabel,
            onChanged: (v) => setState(() => _sortBy = v),
            items: [
              PSegmentedItem(
                value: PresetSortKey.used,
                label: l.presetSortUsed,
              ),
              PSegmentedItem(
                value: PresetSortKey.recent,
                label: l.presetSortRecent,
              ),
              PSegmentedItem(
                value: PresetSortKey.name,
                label: l.presetSortName,
              ),
            ],
          ),
        ),
        PList(
          semanticLabel: title,
          children: [
            for (final p in sorted)
              // 밀면 수정 · 삭제 — 줄을 누르면 상세이므로 밀기는 손가락 지름길이다(WCAG 2.1.1)
              PSwipeActions(
                key: ValueKey('preset-${p.rowId}'),
                rowLabel: p.templateName,
                actions: [
                  PSwipeAction(
                    label: l.actionEdit,
                    icon: LucideIcons.pencil,
                    kind: PSwipeActionKind.primary,
                    onSelect: () => showPresetEditDialog(context, edit: p),
                  ),
                  PSwipeAction(
                    label: l.actionDelete,
                    icon: LucideIcons.trash2,
                    kind: PSwipeActionKind.destructive,
                    // 확인은 _confirmDelete 가 한 번만 묻는다
                    onSelect: () => _confirmDelete(p),
                  ),
                ],
                child: PresetListRow(
                  preset: p,
                  category: p.categoryRowId == null
                      ? null
                      : categories.byRowId(p.categoryRowId!),
                  masked: masked,
                  onTap: () => _openDetail(p),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 불러오는 중 — 목록 제목 · 정렬 자리는 그대로, 줄만 Skeleton 넷(타일 40 · 두 줄 · 오른쪽 두 줄).
class _PresetSkeleton extends StatelessWidget {
  const _PresetSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
            vertical: PSpacing.x2,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PSkeleton.text(PTypography.t4, width: PSpacing.x10 * 2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
            vertical: PSpacing.x1,
          ),
          child: const PSkeleton(
            width: double.infinity,
            height: PSpacing.x10,
            radius: PSkeletonRadius.full,
          ),
        ),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x3,
              children: [
                const PSkeleton(
                  width: PListTile.size,
                  height: PListTile.size,
                  radius: PSkeletonRadius.r12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x1,
                    children: [
                      PSkeleton.text(PTypography.t5, width: 140),
                      PSkeleton.text(PTypography.t3, width: 100),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: PSpacing.x1,
                  children: [
                    PSkeleton.text(PTypography.t5, width: PSpacing.x10 * 2),
                    PSkeleton.text(PTypography.t3, width: PSpacing.x10),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
