import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/category/presentation/category_edit_dialog.dart';
import 'package:groo_damda_app/features/category/presentation/category_move_tx_sheet.dart';
import 'package:groo_damda_app/features/category/presentation/category_tile.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_parent_item.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

const _kindValues = ['EXPENSE', 'INCOME'];

/// 카테고리 관리 (설정 > 카테고리 관리) — 웹 `CategoryManager.tsx` 미러(I-20 B).
///
/// 폰은 흰 면 하나다: 머리(← + "추가") → 탭(지출 · 수입) → 밑줄 검색칸 → 목록 제목("지출 카테고리 n개" + "순서 바꾸기") →
/// 나무 줄. 줄 끝 ⋮ 는 없다 — 줄을 누르면 수정 시트가 열리고 [하위 카테고리 추가] · [거래 옮기기] · [삭제] 는 그 시트 머리 ⋮ 에
/// 있다(2026-10-25 원칙). 순서 바꾸기 모드에서는 줄 끝에 끄는 손잡이가 서고 줄 누름은 막힌다.
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  int _tabIndex = 0;
  String _query = '';
  // 순서 모드 — 켜야만 손잡이 노출 · 드래그 가능, 하위 강제 표시, 줄 누름 막힘.
  bool _editMode = false;
  final Set<int> _collapsed = <int>{};
  // 낙관적 재정렬 오버레이: 드롭 즉시 로컬 순서를 반영하고 refetch가 끝나면 비운다.
  final Map<int, ({int sortOrder, int? parentRowId})> _optimistic = {};

  // 표면이 닫힌 뒤 초점을 돌려 줄 줄 · 목록 머리(K2)
  final Map<int, FocusNode> _rowFocus = {};
  final FocusNode _headerFocus = FocusNode(debugLabel: 'category list header');
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 갱신 — categoriesProvider 는 keepAlive 라 자동 refetch 되지
    // 않으므로, 다른 클라이언트(웹 등) 변경을 따라잡기 위해 진입할 때 무효화한다.
    Future.microtask(() {
      if (mounted) ref.invalidate(categoriesProvider);
    });
  }

  @override
  void dispose() {
    for (final n in _rowFocus.values) {
      n.dispose();
    }
    _headerFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  FocusNode _focusFor(int rowId) =>
      _rowFocus.putIfAbsent(rowId, () => FocusNode(debugLabel: 'cat-$rowId'));

  /// 표면이 닫힌 뒤 초점을 그 카테고리 줄로 돌린다 — 수정 시트와 함께 ⋮ 가 사라지므로 줄로(삭제 뒤에는 이웃 줄, 줄이 없으면
  /// 목록 머리). 닫는 모션이 끝난 뒤에 건다(웹과 같은 200ms).
  void _focusRow(int? rowId) {
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final node = rowId == null ? null : _rowFocus[rowId];
      (node ?? _headerFocus).requestFocus();
    });
  }

  List<ExpenseCategory> get _all =>
      ref.read(categoriesProvider).value ?? const [];

  List<ExpenseCategory> _withOptimistic(List<ExpenseCategory> categories) =>
      _optimistic.isEmpty
      ? categories
      : categories
            .map((c) {
              final o = _optimistic[c.rowId];
              return o == null
                  ? c
                  : c.copyWith(
                      sortOrder: o.sortOrder,
                      parentRowId: o.parentRowId,
                    );
            })
            .toList(growable: false);

  void _toggleCollapse(int parentRowId) {
    setState(() {
      if (!_collapsed.remove(parentRowId)) _collapsed.add(parentRowId);
    });
  }

  void _startReorder(bool on) {
    setState(() {
      _editMode = on;
      // 편집 진입 시 검색 초기화 — 필터된 일부만 보며 정렬하는 혼란 방지.
      if (on) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  Future<void> _handleReorder(
    List<({int categoryRowId, int sortOrder, int? parentRowId})> items,
  ) async {
    // 낙관적 업데이트: 드롭 즉시 로컬 순서를 반영(스냅백 방지).
    setState(() {
      for (final it in items) {
        _optimistic[it.categoryRowId] = (
          sortOrder: it.sortOrder,
          parentRowId: it.parentRowId,
        );
      }
    });
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.reorderCategories(items, silent: true);
      // 서버 권위 데이터로 재동기 후 오버레이 제거 — refetch 완료를 기다려 깜빡임 방지.
      ref.invalidate(categoriesProvider);
      await ref.read(categoriesProvider.future);
    } catch (e) {
      debugPrint('reorderCategories failed: $e');
      // 낙관 순서는 finally 에서 걷혀 서버 순서로 되돌아간다 — 스낵바 두 문장("… 잠시 뒤 다시 시도해주세요."), 다시 시도 버튼 없음.
      if (mounted) {
        PSnackbar.maybeOf(context)?.show(
          message: AppLocalizations.of(context).categoryReorderFailed,
          tone: PSnackbarTone.critical,
        );
      }
    } finally {
      if (mounted) setState(() => _optimistic.clear());
    }
  }

  // ───────── 줄 누름 → 수정 시트 → (머리 ⋮ 의 동작) ─────────

  /// 수정 시트(또는 새 카테고리 폼)를 열고, 머리 ⋮ 에서 고른 동작은 시트가 닫힌 뒤 이어 연다 — 폼 위에 폼이 겹치지 않는다.
  Future<void> _openEdit({ExpenseCategory? cat, int? parentRowId}) async {
    final action = await showCategoryEditDialog(
      context,
      edit: cat,
      defaultExpenseType: _kindValues[_tabIndex],
      defaultParentRowId: parentRowId,
    );
    if (!mounted) return;
    switch (action) {
      case null:
        _focusRow(cat?.rowId ?? parentRowId);
      case CategoryEditAction.addChild:
        await _openEdit(parentRowId: cat!.rowId);
      case CategoryEditAction.moveTx:
        await showCategoryMoveTxSheet(context, source: cat!, categories: _all);
        _focusRow(cat.rowId);
      case CategoryEditAction.delete:
        await _delete(cat!);
    }
  }

  /// 삭제 — 하위가 있으면 막는 확인 하나, 아니면 거래는 남고 예산은 함께 지워진다고 말하는 확인(I-20 B 9 · 10).
  Future<void> _delete(ExpenseCategory cat) async {
    final l = AppLocalizations.of(context);
    final all = _all;
    final hasChildren =
        cat.hasChildren || all.any((c) => c.parentRowId == cat.rowId);
    if (hasChildren) {
      // 고를 것이 없는 차단 통지 — 확인 하나(spec alert-dialog.md · acknowledge).
      await PAlertDialog.show(
        context,
        title: l.categoryDeleteBlockedTitle,
        description: l.categoryDeleteHasChildren(cat.categoryName),
        actionLabel: l.actionConfirm,
      );
      _focusRow(cat.rowId);
      return;
    }
    // 이 카테고리를 쓰는 반복 거래 — 못 받았으면 개수 문장만 뺀다(확인창을 막지 않는다)
    final recurring = ref.read(recurringListProvider).value;
    final using = recurring == null
        ? 0
        : recurring.where((r) => r.categoryRowId == cat.rowId).length;
    final description = using > 0
        ? '${l.categoryDeleteMessage} ${l.categoryDeleteRecurring(using)}'
        : l.categoryDeleteMessage;
    final next = _neighborOf(cat.rowId);
    final container = ProviderScope.containerOf(context);
    void refresh() {
      container.invalidate(categoriesProvider);
      container.invalidate(rangeSummaryProvider);
      container.invalidate(dashboardSummaryProvider);
    }

    final deleted = await askConfirmThenRequest(
      context,
      title: l.categoryDeleteConfirm(cat.categoryName),
      description: description,
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      request: () async {
        final repo = await container.read(expenseRepositoryProvider.future);
        await repo.deleteCategory(cat.rowId, silent: true);
      },
      failedMessage: l.categoryDeleteFailed,
      retryLabel: l.actionRetry,
      onRetried: refresh,
      kind: WriteKind.delete,
      // 응답을 못 받았다 — 지워졌을 수 있다. 목록만 다시 받는다(포커스 이동 같은 성공 뒷정리는 하지 않는다)
      onUnconfirmed: refresh,
    );
    if (!mounted) return;
    if (deleted) {
      refresh();
      _focusRow(next);
    } else {
      _focusRow(cat.rowId);
    }
  }

  /// 지금 탭의 보이는 줄 차례에서 [rowId] 의 이웃 — 다음 줄, 없으면 앞 줄, 줄이 없으면 null(목록 머리).
  int? _neighborOf(int rowId) {
    final ordered = <int>[];
    for (final e in _buildTree(
      _withOptimistic(_all),
      _kindValues[_tabIndex],
      _query,
    )) {
      ordered.add(e.parent.rowId);
      // 하위는 부모 바로 뒤에 선다 — 접힌 부모의 하위는 보이지 않는다
      if (_editMode || !_collapsed.contains(e.parent.rowId)) {
        ordered.addAll(e.children.map((c) => c.rowId));
      }
    }
    final i = ordered.indexOf(rowId);
    if (i < 0) return null;
    if (i + 1 < ordered.length) return ordered[i + 1];
    if (i > 0) return ordered[i - 1];
    return null;
  }

  // ───────── 화면 ─────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final categoriesAsync = ref.watch(categoriesProvider);
    // 삭제 확인이 "이 카테고리를 쓰는 반복 거래" 개수를 말한다 — 미리 받아 둔다(못 받으면 개수 문장만 뺀다)
    ref.watch(recurringListProvider);
    // 이전 값이 있으면 다시 받는 동안에도 그대로 그린다(깜빡임 없음)
    final allCats = categoriesAsync.value;
    int countOf(int i) => allCats == null
        ? 0
        : allCats
              .where((e) => (e.expenseType ?? 'EXPENSE') == _kindValues[i])
              .length;
    // 탭 글은 이름만 — 개수는 바로 아래 목록 제목이 말한다(tabs.md)
    String tabLabel(int i) => i == 0 ? l.expTypeExpense : l.expTypeIncome;

    final Widget body;
    if (allCats != null) {
      final effective = _withOptimistic(allCats);
      body = IndexedStack(
        index: _tabIndex,
        children: [
          for (final k in _kindValues)
            _CategoryList(
              kind: k,
              categories: effective
                  .where((e) => (e.expenseType ?? 'EXPENSE') == k)
                  .toList(growable: false),
              query: _query,
              editMode: _editMode,
              collapsed: _collapsed,
              onToggleCollapse: _toggleCollapse,
              onEdit: (cat) => _openEdit(cat: cat),
              onReorderSiblings: _handleReorder,
              focusFor: _focusFor,
              listLabel: k == 'EXPENSE'
                  ? l.categoryListTitleExpense(countOf(0))
                  : l.categoryListTitleIncome(countOf(1)),
            ),
        ],
      );
    } else if (categoriesAsync.hasError) {
      body = ListView(
        padding: EdgeInsets.zero,
        children: [
          BudgetFailure(
            title: l.categoryLoadFailed,
            retrying: categoriesAsync.isLoading,
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        ],
      );
    } else {
      body = loadingRegion(const _CategorySkeleton());
    }

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목 + 글 버튼 "추가") — 높이 56, 스크롤해도 선이 없다(I-16 14 · 15)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.categoryManageTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
          actions: [
            PTopNavigationTextButton(
              label: l.categoryAddAction,
              onPressed: () => _openEdit(),
            ),
          ],
        ),
      ),
      body: PScreenBandBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 탭(지출 · 수입) — 머리 밖, 본문 맨 위. 화면 폭 끝까지(T1 0)
            PTabs<int>(
              value: _tabIndex,
              onChanged: (v) => setState(() => _tabIndex = v),
              semanticLabel: l.expCategory,
              size: PTabsSize.medium,
              items: [
                for (var i = 0; i < _kindValues.length; i++)
                  PTab(value: i, label: tabLabel(i)),
              ],
            ),
            // 순서 모드는 검색칸 자리에 안내 한 줄 / 평시는 밑줄 검색칸(탭 아래 8 · 목록 제목 위 8 — T2 · T3)
            if (_editMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter,
                  PSpacing.x2,
                  PSpacing.globalGutter,
                  PSpacing.x2,
                ),
                child: Text(
                  keepAll(l.categoryReorderHint),
                  semanticsLabel: l.categoryReorderHint,
                  style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter,
                  PSpacing.x2,
                  PSpacing.globalGutter,
                  PSpacing.x2,
                ),
                child: PInput(
                  variant: PInputVariant.underline,
                  controller: _searchCtrl,
                  placeholder: l.categorySearchHint,
                  semanticLabel: l.categorySearchHint,
                  prefixIcon: LucideIcons.search,
                  clearable: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            // 목록 제목 — 불러오는 중 · 실패에서는 개수를 모른다(두지 않는다)
            if (allCats != null)
              Focus(
                focusNode: _headerFocus,
                skipTraversal: true,
                child: PListHeader(
                  title: _tabIndex == 0
                      ? l.categoryListTitleExpense(countOf(0))
                      : l.categoryListTitleIncome(countOf(1)),
                  action: PTextButton(
                    label: _editMode ? l.actionDone : l.categoryReorderEdit,
                    onPressed: () => _startReorder(!_editMode),
                  ),
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _TreeEntry {
  const _TreeEntry(this.parent, this.children);
  final ExpenseCategory parent;
  final List<ExpenseCategory> children;
}

/// 트리 변환 (parentRowId + sortOrder) — 웹 CategoryManager.tree 미러. 검색은 그룹 단위(부모 매치 or 자식 매치 시 그룹 노출).
List<_TreeEntry> _buildTree(
  List<ExpenseCategory> categories,
  String kind,
  String query,
) {
  final sorted =
      categories
          .where((c) => (c.expenseType ?? 'EXPENSE') == kind)
          .toList(growable: false)
        ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  final byParent = <int, List<ExpenseCategory>>{};
  final parents = <ExpenseCategory>[];
  for (final c in sorted) {
    if (c.parentRowId == null) {
      parents.add(c);
    } else {
      byParent.putIfAbsent(c.parentRowId!, () => <ExpenseCategory>[]).add(c);
    }
  }
  final q = query.trim();
  final tree = <_TreeEntry>[];
  for (final p in parents) {
    final children = byParent[p.rowId] ?? const <ExpenseCategory>[];
    if (q.isEmpty) {
      tree.add(_TreeEntry(p, children));
      continue;
    }
    final parentMatch = p.categoryName.contains(q);
    final filtered = parentMatch
        ? children
        : children
              .where((c) => c.categoryName.contains(q))
              .toList(growable: false);
    if (!parentMatch && filtered.isEmpty) continue;
    tree.add(_TreeEntry(p, filtered));
  }
  return tree;
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.kind,
    required this.categories,
    required this.query,
    required this.editMode,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.onEdit,
    required this.onReorderSiblings,
    required this.focusFor,
    required this.listLabel,
  });
  final String kind;
  final List<ExpenseCategory> categories;
  final String query;
  final bool editMode;
  final Set<int> collapsed;
  final void Function(int parentRowId) onToggleCollapse;
  final void Function(ExpenseCategory cat) onEdit;
  final void Function(
    List<({int categoryRowId, int sortOrder, int? parentRowId})> items,
  )
  onReorderSiblings;
  final FocusNode Function(int rowId) focusFor;
  final String listLabel;

  /// 같은 형제끼리만 옮긴다 — 형제 차례를 서버에 보낼 값으로 바꾼다.
  void _reorder(List<ExpenseCategory> siblings, int oldIndex, int newIndex) {
    final reordered = [...siblings];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    onReorderSiblings([
      for (var idx = 0; idx < reordered.length; idx++)
        (
          categoryRowId: reordered[idx].rowId,
          sortOrder: idx,
          parentRowId: reordered[idx].parentRowId,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tree = _buildTree(categories, kind, query);

    if (categories.isEmpty) return BudgetEmptyLine(l.categoryEmpty);
    if (tree.isEmpty) return BudgetEmptyLine(l.categoryNoResults);

    return ListView(
      // 마지막 줄 아래 흰 면 안 24(T8)
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      children: [
        PList(
          semanticLabel: listLabel,
          children: editMode ? _reorderRows(context, tree) : _rows(tree),
        ),
      ],
    );
  }

  List<Widget> _rows(List<_TreeEntry> tree) => [
    for (final e in tree)
      Builder(
        key: ValueKey('row-${e.parent.rowId}'),
        builder: (context) {
          final l = AppLocalizations.of(context);
          return PListParentItem(
            key: ValueKey('p-${e.parent.rowId}'),
            title: e.parent.categoryName,
            prefix: categoryTile(context, e.parent),
            expandLabel: l.categoryExpandOf(e.parent.categoryName),
            open: !collapsed.contains(e.parent.rowId),
            onOpenChange: (_) => onToggleCollapse(e.parent.rowId),
            focusNode: focusFor(e.parent.rowId),
            onTap: () => onEdit(e.parent),
            children: [
              for (final c in e.children)
                PListButtonItem(
                  key: ValueKey('c-${c.rowId}'),
                  title: c.categoryName,
                  prefix: categoryTile(context, c),
                  focusNode: focusFor(c.rowId),
                  onTap: () => onEdit(c),
                ),
            ],
          );
        },
      ),
  ];

  /// 순서 모드 — 하위는 늘 보이고(꺾쇠 자리는 빈 채) 줄 누름은 막힌다. 줄 끝에 끄는 손잡이가 선다.
  List<Widget> _reorderRows(BuildContext context, List<_TreeEntry> tree) => [
    Material(
      color: Colors.transparent,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: tree.length,
        // onReorderItem 은 newIndex 를 프레임워크가 보정해 넘기고, oldIndex == newIndex 면 아예 호출하지 않는다.
        onReorderItem: (oldIndex, newIndex) =>
            _reorder([for (final e in tree) e.parent], oldIndex, newIndex),
        itemBuilder: (ctx, pi) {
          final e = tree[pi];
          return PListParentItem(
            key: ValueKey('p-${e.parent.rowId}'),
            collapsible: false,
            title: e.parent.categoryName,
            prefix: categoryTile(ctx, e.parent),
            // 누름만 막는다 — 글 · 타일은 보통 색(막힌 줄의 비활성 색이 아니다)
            readOnly: true,
            onTap: null,
            endInset: _kGripEndInset,
            suffix: _Grip(index: pi, name: e.parent.categoryName),
            children: [
              if (e.children.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: e.children.length,
                    onReorderItem: (oldIndex, newIndex) =>
                        _reorder(e.children, oldIndex, newIndex),
                    itemBuilder: (ctx, ci) {
                      final c = e.children[ci];
                      return PListItem(
                        key: ValueKey('c-${c.rowId}'),
                        title: c.categoryName,
                        prefix: categoryTile(ctx, c),
                        endInset: _kGripEndInset,
                        suffix: _Grip(index: ci, name: c.categoryName),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ),
  ];
}

/// 손잡이가 줄 끝에서 안쪽으로 서는 거리 — 줄 끝 여백 24 중 12 를 단추가 쓴다(웹 `-mr-x3`).
const double _kGripEndInset = PSpacing.x3;

/// 끄는 손잡이 — grip-vertical 20 · `fg-neutral-subtle` · 누르는 44 · 이름 "{이름} 순서 바꾸기". 줄 끝에서 12 안쪽에 선다.
class _Grip extends StatelessWidget {
  const _Grip({required this.index, required this.name});
  final int index;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ReorderableDragStartListener(
      index: index,
      child: PButton.icon(
        icon: LucideIcons.gripVertical,
        semanticLabel: l.categoryDragReorderOf(name),
        variant: PButtonVariant.ghost,
        ghostColor: PButtonGhostColor.neutralSubtle,
        size: PButtonSize.medium,
        onPressed: () {},
      ),
    );
  }
}

/// 불러오는 중 — 목록 제목 자리 아래 부모 줄 넷(꺾쇠 자리 · 타일 40 · 한 줄) · 하위 둘(I-20 F).
class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    // 부모 타일은 52(앞 4 + 꺾쇠 44 + 4), 하위 타일은 104 에서 선다
    const rows = <bool>[true, false, false, true, true, true];
    return Column(
      children: [
        for (final parent in rows)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: parent ? PSpacing.x13 : PSpacing.x13 * 2,
              end: PSpacing.globalGutter,
              top: PSpacing.x3,
              bottom: PSpacing.x3,
            ),
            child: Row(
              spacing: PSpacing.x3,
              children: [
                const PSkeleton(
                  width: PListTile.size,
                  height: PListTile.size,
                  radius: PSkeletonRadius.r12,
                ),
                Expanded(child: PSkeleton.text(PTypography.t5)),
              ],
            ),
          ),
      ],
    );
  }
}
