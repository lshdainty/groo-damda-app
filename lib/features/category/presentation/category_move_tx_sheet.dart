import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/category/presentation/category_tile.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 새 하위 이름 상한 — 카테고리 이름과 같은 12자(I-20 B 11).
const int kCategoryChildNameMax = 12;

/// 카테고리에 달린 거래를 다른 카테고리로 옮긴다 (web `CategoryMoveTxDialog` 미러, I-20 B 11).
///
/// 거래가 직접 달린 카테고리는 하위 분류를 만들 수 없다(거래는 말단에만 달 수 있어서).
/// 그런데 옮길 하위가 없으면 거래도 못 옮기는 교착이 생기므로,
/// "새 하위 만들기" 는 생성과 이동을 서버에서 한 트랜잭션으로 처리한다.
/// 입력 폼 시트 — 수정 시트 머리 ⋮ 의 "거래 옮기기" 에서 수정 시트를 닫고 연다. 닫힐 때까지 기다린다.
Future<void> showCategoryMoveTxSheet(
  BuildContext context, {
  required ExpenseCategory source,
  required List<ExpenseCategory> categories,
}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  // 처음 모드가 "새 하위 만들기"(하위가 없는 최상위)면 이름 칸에 초점 — 시트가 처음 초점을 컨테이너에 두므로 첫 초점 노드를
  // 넘긴다(웹은 mode === "new" 일 때만). 기존 하위로 옮기는 모드는 입력 칸이 없어 표면에 둔다
  final nameFocus = FocusNode(debugLabel: 'MoveTx new child name');
  final canSplit =
      source.parentRowId == null &&
      !categories.any((c) => c.parentRowId == source.rowId);
  return PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: canSplit ? nameFocus : null,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _MoveTxForm(
      source: source,
      categories: categories,
      probe: probe,
      nameFocus: nameFocus,
    ),
  );
}

class _DirtyProbe {
  bool Function() dirty = () => false;
}

enum _Mode { newChild, existing }

class _MoveTxForm extends ConsumerStatefulWidget {
  const _MoveTxForm({
    required this.source,
    required this.categories,
    required this.probe,
    required this.nameFocus,
  });
  final ExpenseCategory source;
  final List<ExpenseCategory> categories;
  final _DirtyProbe probe;

  /// 새 하위 이름 칸 초점 노드 — 호출처가 시트의 첫 초점으로 넘기고 폼 State 가 버린다.
  final FocusNode nameFocus;

  @override
  ConsumerState<_MoveTxForm> createState() => _MoveTxFormState();
}

class _MoveTxFormState extends ConsumerState<_MoveTxForm> {
  final _nameCtrl = TextEditingController();
  late final FocusNode _nameFocus = widget.nameFocus;
  final _targetFocus = FocusNode();
  int? _targetRowId;
  late _Mode _mode;
  bool _showNameError = false;
  bool _showTargetError = false;
  bool _submitting = false;
  bool _failed = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _errorKey = GlobalKey();

  /// 하위가 없는 최상위만 "새 하위 만들기" 대상 — 교착이 생기는 자리가 정확히 여기다.
  /// 하위 카테고리엔 또 하위를 만들 수 없다(최대 2단계).
  bool get _canSplit =>
      widget.source.parentRowId == null &&
      !widget.categories.any((c) => c.parentRowId == widget.source.rowId);

  /// 옮길 수 있는 곳 = 같은 종류이고, 자기 자신이 아니고, 자식이 없는 말단.
  /// 서버도 같은 규칙으로 거부하므로 미리 걸러 고를 수 없게 한다.
  List<ExpenseCategory> get _options {
    final parentIds = widget.categories
        .where((c) => c.parentRowId != null)
        .map((c) => c.parentRowId!)
        .toSet();
    return widget.categories
        .where(
          (c) =>
              c.rowId != widget.source.rowId &&
              c.expenseType == widget.source.expenseType &&
              !parentIds.contains(c.rowId),
        )
        .toList();
  }

  String get _nameTrim => _nameCtrl.text.trim();

  @override
  void initState() {
    super.initState();
    _mode = _canSplit ? _Mode.newChild : _Mode.existing;
    widget.probe.dirty = () => _nameTrim.isNotEmpty || _targetRowId != null;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _targetFocus.dispose();
    super.dispose();
  }

  String? _parentNameOf(ExpenseCategory c) {
    if (c.parentRowId == null) return null;
    for (final p in widget.categories) {
      if (p.rowId == c.parentRowId) return p.categoryName;
    }
    return null;
  }

  Future<void> _pickTarget() async {
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<int>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        final c = sheetContext.colors;
        final options = _options;
        return PBottomSheetContent(
          title: l.categoryMoveTxTarget,
          closeLabel: l.actionClose,
          flushBody: true,
          scrollFog: true,
          body: options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpacing.globalGutter,
                    vertical: PSpacing.x3,
                  ),
                  child: PText(
                    l.categoryMoveTxNoTarget,
                    style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                  ),
                )
              : PickList<int>(
                  label: l.categoryMoveTxTarget,
                  selected: _targetRowId,
                  items: [
                    for (final o in options)
                      PickItem<int>(
                        value: o.rowId,
                        title: o.categoryName,
                        detail: _parentNameOf(o),
                        prefix: categoryTile(sheetContext, o),
                      ),
                  ],
                ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _targetRowId = picked;
      _showTargetError = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameTrim;
    if (_mode == _Mode.newChild && name.isEmpty) {
      setState(() => _showNameError = true);
      _nameFocus.requestFocus();
      return;
    }
    if (_mode == _Mode.existing && _targetRowId == null) {
      setState(() => _showTargetError = true);
      _targetFocus.requestFocus();
      return;
    }
    final l = AppLocalizations.of(context);
    setState(() {
      _failed = false;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(expenseRepositoryProvider.future);
      final moved = _mode == _Mode.newChild
          ? await repo.splitCategoryIntoChild(
              widget.source.rowId,
              childName: name,
              icon: widget.source.icon ?? 'tag',
              color: widget.source.color ?? '#9E9E9E',
              silent: true,
            )
          : await repo.moveCategoryTransactions(
              widget.source.rowId,
              _targetRowId!,
              silent: true,
            );
      // 거래의 카테고리가 바뀌므로 목록·통계까지 새로 받는다.
      container.invalidate(categoriesProvider);
      // 그 카테고리의 거래가 전 기간에 흩어져 있다 — 어느 달이 바뀌는지 모른다.
      container.invalidate(monthExpensesProvider);
      invalidateAfterExpenseChangeIn(container);
      if (!mounted) return;
      // 성공은 neutral 한 문장 — 스낵바 길은 시트를 닫기 전에 쥔다.
      final snack = PSnackbar.maybeOf(context);
      PBottomSheet.of(context).close();
      snack?.show(message: l.categoryMoveTxDone(moved));
    } on ApiException catch (e) {
      // 폼은 열린 채 쓴 값이 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      if (!mounted) return;
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다
      if (isUnconfirmedSave(e)) {
        container.invalidate(categoriesProvider);
        container.invalidate(monthExpensesProvider);
        invalidateAfterExpenseChangeIn(container);
      }
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    final target = _options.where((o) => o.rowId == _targetRowId).firstOrNull;

    return PBottomSheetContent(
      title: l.categoryMoveTxTitle,
      description: l.categoryMoveTxDesc(widget.source.categoryName),
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed)
            Padding(
              padding: gutter.copyWith(bottom: PSpacing.x4),
              child: FormErrorCallout(
                key: _errorKey,
                message: saveFailureText(l, _failure, l.categoryMoveTxFailed),
              ),
            ),
          if (_canSplit)
            Padding(
              padding: gutter.copyWith(bottom: PSpacing.x6),
              child: PSegmentedControl<_Mode>(
                semanticLabel: l.categoryMoveTxMode,
                value: _mode,
                onChanged: (v) => setState(() => _mode = v),
                items: [
                  PSegmentedItem(
                    value: _Mode.newChild,
                    label: l.categoryMoveTxModeNew,
                  ),
                  PSegmentedItem(
                    value: _Mode.existing,
                    label: l.categoryMoveTxModeExisting,
                  ),
                ],
              ),
            ),
          if (_mode == _Mode.newChild)
            Padding(
              padding: gutter,
              child: PField(
                label: l.categoryMoveTxChildName,
                maxGraphemeCount: kCategoryChildNameMax,
                description: l.categoryMoveTxNewHint(
                  widget.source.categoryName,
                ),
                invalid: _showNameError && _nameTrim.isEmpty,
                errorMessage: l.categoryMoveTxErrChildName,
                child: PInput(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  placeholder: l.categoryMoveTxChildPlaceholder,
                  onChanged: (_) => setState(() => _showNameError = false),
                ),
              ),
            )
          else ...[
            PickerRow(
              title: l.categoryMoveTxTarget,
              value: target?.categoryName,
              placeholder: l.categoryMoveTxTargetPlaceholder,
              semanticValue: target?.categoryName ?? l.expNone,
              leading: target == null
                  ? null
                  : PickerDot(
                      color: resolveChartColor(
                        context,
                        target.color,
                        fallback: c.fgBrand,
                      ),
                    ),
              errorMessage: _showTargetError && _targetRowId == null
                  ? l.categoryMoveTxErrTarget
                  : null,
              focusNode: _targetFocus,
              onTap: _pickTarget,
            ),
            Padding(
              padding: gutter.copyWith(top: PSpacing.x1_5),
              child: PText(
                _options.isEmpty
                    ? l.categoryMoveTxNoTarget
                    : l.categoryMoveTxHint,
                style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
          ],
          const SizedBox(height: PSpacing.x2),
        ],
      ),
      footer: [
        PButton(
          label: l.categoryMoveTxAction,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
