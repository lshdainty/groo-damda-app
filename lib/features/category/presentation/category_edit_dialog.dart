import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/clock/clock.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/category/presentation/category_tile.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/category_icons.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/p_icon_picker.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/forms/color_pick.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 카테고리 이름 상한 — 목록 줄 한 칸에 들어가는 길이(서버 상한은 더 넓다).
const int kCategoryNameMax = 12;

/// 수정 시트 머리 ⋮ 의 동작 — 시트를 닫은 뒤 부르는 쪽(목록 화면)이 새 폼 · 옮기기 시트 · 확인창을 연다
/// (폼 위에 폼이 겹치지 않는다). 줄 끝 ⋮ 는 두지 않는다(2026-10-25 원칙).
enum CategoryEditAction { addChild, moveTx, delete }

/// 상위 카테고리 고르기의 "최상위" 줄 값 — rowId 는 1부터 시작한다.
const int _kRootParent = 0;

/// 카테고리 추가 · 수정 폼 — 웹 `CategoryEditDialog.tsx` 미러(I-20 B 12). 입력 폼 시트: 맨 위 한 줄에 미리보기 타일 + 이름 칸,
/// 그 아래 고르는 값 넷(종류 · 상위 · 색상 · 아이콘)은 줄이다. 바닥 주 버튼 하나(추가 · 저장)는 켜 두고 누를 때 칸 아래에 알린다.
///
/// 고치는 카테고리는 머리 오른쪽 ⋮ 에 [하위 카테고리 추가](최상위만) · [거래 옮기기](하위가 없을 때만) · [삭제](맨 아래 묶음)가
/// 있고, 고른 동작은 시트를 닫으며 [CategoryEditAction] 으로 돌려준다 — 바뀐 값이 있으면 닫을 때와 같은 "작성한 내용이 사라져요"
/// 를 먼저 묻는다. 저장하거나 그냥 닫으면 null.
Future<CategoryEditAction?> showCategoryEditDialog(
  BuildContext context, {
  ExpenseCategory? edit,
  String defaultExpenseType = 'EXPENSE',
  int? defaultParentRowId,
}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  // 새 폼은 이름 칸에 초점(시트가 처음 초점을 컨테이너에 두므로 첫 초점 노드를 넘긴다), 수정 폼은 키보드 없이 표면
  final nameFocus = FocusNode(debugLabel: 'Category name');
  return PBottomSheet.show<CategoryEditAction>(
    context,
    form: true,
    initialFocus: edit == null ? nameFocus : null,
    isDirty: () => probe.dirty(),
    leaveCopy: _leaveCopy(l),
    builder: (_) => _CategoryForm(
      edit: edit,
      defaultExpenseType: defaultExpenseType,
      defaultParentRowId: defaultParentRowId,
      probe: probe,
      nameFocus: nameFocus,
    ),
  );
}

PLeaveConfirmCopy _leaveCopy(AppLocalizations l) => PLeaveConfirmCopy(
  title: l.sheetLeaveTitle,
  description: l.sheetLeaveDescription,
  stayLabel: l.sheetLeaveStay,
  leaveLabel: l.sheetLeaveLeave,
);

class _DirtyProbe {
  bool Function() dirty = () => false;
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({
    this.edit,
    required this.defaultExpenseType,
    this.defaultParentRowId,
    required this.probe,
    required this.nameFocus,
  });
  final ExpenseCategory? edit;
  final String defaultExpenseType;
  final int? defaultParentRowId;
  final _DirtyProbe probe;

  /// 이름 칸 초점 노드 — 호출처가 시트의 첫 초점으로 넘기고 폼 State 가 버린다.
  final FocusNode nameFocus;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus = widget.nameFocus;

  late final String _initialName;
  late final String _initialKind;
  late final int? _initialParent;
  late final String _initialColor;
  late final String _initialIcon;

  late String _kind;
  int? _parentRowId;

  /// 고른 색 — 새 카테고리는 색을 고르기 전까지 고른 종류의 첫 안 쓴 색을 따라간다(null).
  String? _pickedColor;

  /// 고치는 카테고리가 팔레트 밖 색을 들고 있으면 그 값 — "지금 색" 칸이 된다.
  String? _foreignColor;
  late String _icon;
  String? _nameError;
  bool _submitting = false;
  bool _failed = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _errorKey = GlobalKey();

  bool get _isEdit => widget.edit != null;

  List<ExpenseCategory> get _categories =>
      ref.read(categoriesProvider).value ?? const [];

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _initialName = e?.categoryName ?? '';
    _initialKind = e?.expenseType ?? widget.defaultExpenseType;
    _initialParent = e?.parentRowId ?? widget.defaultParentRowId;
    _initialIcon = e?.icon == null || e!.icon!.isEmpty ? 'tag' : e.icon!;
    // 고치는 카테고리는 저장된 색을 그대로 — 팔레트 밖 색도 빨강으로 바꾸지 않는다
    _initialColor = e?.color?.trim().isNotEmpty == true
        ? e!.color!.trim()
        : _nextColor(_initialKind);
    if (e != null && chartColorOfHex(_initialColor) == null) {
      _foreignColor = _initialColor;
    }
    _nameCtrl = TextEditingController(text: _initialName);
    _kind = _initialKind;
    _parentRowId = _initialParent;
    _icon = _initialIcon;
    widget.probe.dirty = () => _dirty;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// 같은 종류 카테고리가 아직 쓰지 않은 첫 색(color-swatch.md) — 늘 빨강으로 시작하지 않는다.
  String _nextColor(String kind) => firstUnusedHex([
    for (final c in _categories)
      if (c.expenseType == kind) c.color,
  ]);

  String get _color =>
      _pickedColor ?? (_isEdit ? _initialColor : _nextColor(_kind));

  String get _nameTrim => _nameCtrl.text.trim();

  bool get _dirty =>
      _nameCtrl.text != _initialName ||
      _kind != _initialKind ||
      _parentRowId != _initialParent ||
      (_isEdit ? _color != _initialColor : _pickedColor != null) ||
      _icon != _initialIcon;

  bool get _selfHasChildren =>
      _isEdit &&
      (widget.edit!.hasChildren ||
          _categories.any((c) => c.parentRowId == widget.edit!.rowId));

  /// 이름 검사 — 같은 상위 · 같은 종류 안에서만 겹치면 안 된다(서버 규칙과 같다).
  String? _nameIssue(AppLocalizations l) {
    final name = _nameTrim;
    if (name.isEmpty) return l.categoryNameRequired;
    if (name.characters.length > kCategoryNameMax) {
      return l.categoryNameTooLong;
    }
    final taken = _categories.any(
      (c) =>
          c.rowId != widget.edit?.rowId &&
          c.expenseType == _kind &&
          c.parentRowId == _parentRowId &&
          c.categoryName == name,
    );
    return taken ? l.categoryNameDuplicate : null;
  }

  /// 카테고리 변경(특히 상위 재배치) 후 집계 캐시 무효화 — 웹 expenseKeys.all 정합.
  ///
  /// rangeSummaryProvider 등 family FutureProvider 는 non-autoDispose 라 세션 내내
  /// 캐시가 살아 있어, categoriesProvider 만 무효화하면 예산 게이지·통계 도넛의
  /// categoryBreakdown(부모 귀속)이 stale 로 남는다 (pull-to-refresh 전까지).
  void _invalidateAggregates(ProviderContainer container) {
    container.invalidate(categoriesProvider);
    container.invalidate(rangeSummaryProvider);
    container.invalidate(dashboardSummaryProvider);
  }

  /// 자식 이동 시 새 부모 예산 초과 확인 — 초과면 확인창 1회(승인=true) (룰3).
  /// 예산 없음·미초과면 true(그대로 진행), 사용자가 취소하면 false.
  Future<bool> _confirmMoveIfExceedsBudget(int newParentRowId) async {
    final now = ref.read(clockProvider)();
    final key = (year: now.year, month: now.month);
    final start =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final end =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final budgets = await ref.read(monthBudgetsProvider(key).future);
    final parentBudget = budgets
        .where((b) => b.categoryRowId == newParentRowId)
        .map((b) => b.budgetAmount)
        .firstOrNull;
    if (parentBudget == null) return true; // 새 부모에 예산 없음 → 경고 불필요

    final summary = await ref.read(
      rangeSummaryProvider((startDate: start, endDate: end)).future,
    );
    final breakdown = summary.categoryBreakdown;
    final parentRollup = breakdown
        .where(
          (c) =>
              c.categoryRowId == newParentRowId ||
              c.parentCategoryRowId == newParentRowId,
        )
        .fold<int>(0, (s, c) => s + c.totalAmount);
    final movingSpent = breakdown
        .where((c) => c.categoryRowId == widget.edit!.rowId)
        .fold<int>(0, (s, c) => s + c.totalAmount);
    final projected = parentRollup + movingSpent;
    if (projected <= parentBudget) return true;

    if (!mounted) return false;
    final l = AppLocalizations.of(context);
    final parentName =
        _categories
            .where((c) => c.rowId == newParentRowId)
            .map((c) => c.categoryName)
            .firstOrNull ??
        l.categoryParent;
    return PAlertDialog.show(
      context,
      title: l.categoryBudgetExceedTitle,
      description: l.categoryBudgetExceedMessage(
        parentName,
        krwSigned(projected - parentBudget, false, unit: true),
      ),
      cancelLabel: l.actionCancel,
      actionLabel: l.categoryMove,
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final issue = _nameIssue(l);
    if (issue != null) {
      setState(() => _nameError = issue);
      _nameFocus.requestFocus();
      return;
    }
    final name = _nameTrim;
    final parentDisabled = _selfHasChildren;

    // 자식을 다른 부모로 이동 — 새 부모 예산 초과 시 한 번 확인 (룰3).
    if (_isEdit &&
        !parentDisabled &&
        _parentRowId != null &&
        _parentRowId != widget.edit!.parentRowId) {
      final ok = await _confirmMoveIfExceedsBudget(_parentRowId!);
      if (!ok || !mounted) return;
    }

    setState(() {
      _failed = false;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(expenseRepositoryProvider.future);
      if (_isEdit) {
        await repo.updateCategory(
          id: widget.edit!.rowId,
          categoryName: name,
          icon: _icon,
          color: _color,
          expenseType: _kind,
          // 웹 정합 — parentRowId 는 항상 포함(null = 최상위). 자식 보유 시 기존 유지.
          includeParentRowId: true,
          parentRowId: parentDisabled ? widget.edit!.parentRowId : _parentRowId,
          silent: true,
        );
      } else {
        await repo.createCategory(
          categoryName: name,
          icon: _icon,
          color: _color,
          expenseType: _kind,
          parentRowId: _parentRowId,
          silent: true,
        );
      }
      _invalidateAggregates(container);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 폼은 열린 채 쓴 값이 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다
      if (isUnconfirmedSave(e)) {
        _invalidateAggregates(container);
      }
      if (!mounted) return;
      setState(() {
        _failed = true;
        _failure = e;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) revealBelowFog(ctx);
      });
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 머리 ⋮ 의 동작은 수정 시트를 떠난다 — 바뀐 값이 있으면 닫을 때와 같은 "작성한 내용이 사라져요" 를 먼저 묻는다.
  Future<void> _act(CategoryEditAction action) async {
    if (_dirty) {
      final leave = await PAlertDialog.confirmLeave(
        context,
        _leaveCopy(AppLocalizations.of(context)),
      );
      if (!leave || !mounted) return;
    }
    PBottomSheet.of(context).close(action);
  }

  Widget _headerAction(AppLocalizations l) {
    final cat = widget.edit!;
    return PButton.icon(
      icon: LucideIcons.ellipsisVertical,
      semanticLabel: l.categoryMoreOf(cat.categoryName),
      variant: PButtonVariant.ghost,
      ghostColor: PButtonGhostColor.neutralSubtle,
      size: PButtonSize.small,
      onPressed: () => PMenuSheet.show(
        context,
        title: cat.categoryName,
        groups: [
          PMenuSheetGroup([
            // 2단계까지 — 하위 줄에는 하위 추가를 두지 않는다
            if (cat.parentRowId == null)
              PMenuSheetItem(
                label: l.categoryAddSub,
                icon: LucideIcons.plus,
                onSelect: () => _act(CategoryEditAction.addChild),
              ),
            // 하위가 있는 부모에는 거래가 달릴 수 없어 옮길 것이 0 이다
            if (!_selfHasChildren)
              PMenuSheetItem(
                label: l.categoryMoveTxEntry,
                icon: LucideIcons.arrowRightLeft,
                onSelect: () => _act(CategoryEditAction.moveTx),
              ),
          ]),
          PMenuSheetGroup([
            PMenuSheetItem(
              label: l.actionDelete,
              icon: LucideIcons.trash2,
              tone: PMenuSheetTone.critical,
              onSelect: () => _act(CategoryEditAction.delete),
            ),
          ]),
        ],
      ),
    );
  }

  String _kindText(AppLocalizations l, String kind) =>
      kind == 'EXPENSE' ? l.expTypeExpense : l.expTypeIncome;

  Future<void> _pickKind() async {
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<String>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        return PBottomSheetContent(
          title: l.categoryKindLabel,
          closeLabel: l.actionClose,
          flushBody: true,
          body: PickList<String>(
            label: l.categoryKindLabel,
            selected: _kind,
            items: [
              PickItem(value: 'EXPENSE', title: l.expTypeExpense),
              PickItem(value: 'INCOME', title: l.expTypeIncome),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted || picked == _kind) return;
    setState(() {
      _kind = picked;
      // 다른 종류의 상위가 남으면 서버가 거절한다 — 최상위로 되돌린다
      _parentRowId = null;
    });
  }

  Future<void> _pickParent(List<ExpenseCategory> options) async {
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<int>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        final c = sheetContext.colors;
        return PBottomSheetContent(
          title: l.categoryParent,
          closeLabel: l.actionClose,
          flushBody: true,
          scrollFog: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 하위의 수정 — 최상위로 올리는 길을 알린다(서버도 승격을 막는다)
              if (_isEdit)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpacing.globalGutter,
                    vertical: PSpacing.x3,
                  ),
                  child: PText(
                    l.categoryParentMoveHint,
                    style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                  ),
                ),
              PickList<int>(
                label: l.categoryParent,
                selected: _parentRowId ?? _kRootParent,
                items: [
                  if (!_isEdit)
                    PickItem(
                      value: _kRootParent,
                      title: l.categoryMakeRoot,
                      // 다른 줄과 같은 40 타일 — 중립 바탕 + 나무 위 아이콘(제목이 한 세로선에 선다)
                      prefix: PListTile(
                        background: c.chartGrayWeak,
                        color: c.chartGray,
                        child: const Icon(LucideIcons.listTree),
                      ),
                    ),
                  for (final o in options)
                    PickItem(
                      value: o.rowId,
                      title: o.categoryName,
                      prefix: categoryTile(sheetContext, o),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _parentRowId = picked == _kRootParent ? null : picked);
  }

  Future<void> _pickColor() async {
    FocusScope.of(context).unfocus();
    final picked = await showColorPickSheet(
      context,
      title: AppLocalizations.of(context).calFieldColor,
      hex: _color,
      foreignHex: _foreignColor,
    );
    if (picked == null || !mounted) return;
    setState(() => _pickedColor = picked);
  }

  Future<void> _pickIcon() async {
    FocusScope.of(context).unfocus();
    await showPIconPickerSheet(
      context,
      value: _icon,
      onChanged: (id) => setState(() => _icon = id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    ref.watch(categoriesProvider);

    // 상위 후보: 같은 종류의 최상위, 본인 제외
    final parentOptions = [
      for (final o in _categories)
        if (o.expenseType == _kind &&
            o.parentRowId == null &&
            o.rowId != widget.edit?.rowId)
          o,
    ];
    final parent = _parentRowId == null
        ? null
        : _categories.where((o) => o.rowId == _parentRowId).firstOrNull;
    // 최상위의 수정: 강등 금지 — 보기만 "최상위". 하위의 수정: 다른 최상위로만(승격 금지)
    final parentReadOnly = _isEdit && widget.edit!.parentRowId == null;

    final color = _color;
    final previewFg = resolveChartColor(context, color, fallback: c.fgBrand);
    final iconEntry = findCategoryIcon(_icon);
    final iconName =
        iconEntry?.name ?? PIconPickerTexts.of(context).currentIconName;

    return PBottomSheetContent(
      title: _isEdit ? l.categoryEdit : l.categoryAdd,
      closeLabel: l.actionClose,
      flushBody: true,
      headerAction: _isEdit ? _headerAction(l) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                0,
                PSpacing.globalGutter,
                PSpacing.x4,
              ),
              child: FormErrorCallout(
                key: _errorKey,
                message: saveFailureText(l, _failure, l.categorySaveFailed),
              ),
            ),
          // 맨 위 줄 — 미리보기 타일 52 + 이름 칸(좌우 24 · 아래 8 · 사이 12)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x3,
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(
                    key: const ValueKey('category-preview-tile'),
                    dimension: PSpacing.x13,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: softBg(context, previewFg),
                        borderRadius: BorderRadius.circular(PRounded.r4),
                      ),
                      child: Center(
                        child: Icon(
                          categoryGlyph(_icon),
                          size: PSpacing.x5,
                          color: previewFg,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PField(
                    maxGraphemeCount: kCategoryNameMax,
                    invalid: _nameError != null,
                    errorMessage: _nameError,
                    child: PInput(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      semanticLabel: l.calFieldName,
                      placeholder: l.categoryNamePlaceholder,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 종류 — 추가에서만 고른다(수정은 보기만)
          PickerRow(
            title: l.categoryKindLabel,
            prefix: const Icon(LucideIcons.folder),
            value: _kindText(l, _kind),
            onTap: _isEdit ? null : _pickKind,
          ),
          parentReadOnly
              ? PickerRow(
                  title: l.categoryParent,
                  prefix: const Icon(LucideIcons.tags),
                  value: l.categoryMakeRoot,
                  onTap: null,
                )
              : PickerRow(
                  title: l.categoryParent,
                  prefix: const Icon(LucideIcons.tags),
                  value: parent?.categoryName ?? l.categoryMakeRoot,
                  leading: parent == null
                      ? null
                      : PickerDot(
                          color: resolveChartColor(
                            context,
                            parent.color,
                            fallback: c.fgBrand,
                          ),
                        ),
                  onTap: () => _pickParent(parentOptions),
                ),
          PickerRow(
            title: l.calFieldColor,
            prefix: const Icon(LucideIcons.palette),
            value: colorPickName(context, color),
            leading: PickerDot(size: 12, color: previewFg),
            onTap: _pickColor,
          ),
          PickerRow(
            title: l.categoryIconLabel,
            prefix: const Icon(LucideIcons.tag),
            value: iconName,
            leading: Icon(
              categoryGlyph(_icon),
              size: 20,
              color: c.fgNeutralMuted,
            ),
            onTap: _pickIcon,
          ),
          const SizedBox(height: PSpacing.x2),
        ],
      ),
      footer: [
        PButton(
          label: _isEdit ? l.actionSave : l.categorySubmitAdd,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
