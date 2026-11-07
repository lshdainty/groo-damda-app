import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/amount_limit_guard.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 총 예산 제안 · 카테고리 예산 제안(웹 `MonthlyBudgetDialog` · `PRESETS` 와 같은 값) — 갈래마다 따로다.
const kBudgetTotalPresets = [1500000, 2000000, 2500000, 3000000];
const kBudgetCategoryPresets = [
  100000,
  200000,
  300000,
  500000,
  800000,
  1000000,
];

/// 한국어는 '10만원', 영어는 통화 포맷 — 웹 `isEn() ? money(p) : `${p/10000}만원`` 미러.
String _presetLabel(BuildContext context, int v) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'en') return krw(v);
  return '${(v / 10000).round()}만원';
}

/// 예산 폼 — 총 예산 · 카테고리 예산 추가 · 수정을 한 시트로(I-19 C). 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면
/// 닫기 전에 묻는다.
void showBudgetEditDialog(
  BuildContext context, {
  required int year,
  required int month,
  Budget? edit,
  Set<int> usedCategoryIds = const {},
  bool overallNew = false,
}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  // 새 폼은 금액 칸에 초점 — 시트가 처음 초점을 컨테이너에 두므로(안쪽 autofocus 는 밀린다) 첫 초점 노드를 넘긴다.
  // 수정 폼은 키보드 없이 표면. 노드는 폼 State 가 버린다
  final amountFocus = FocusNode(debugLabel: 'Budget amount');
  PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: edit == null ? amountFocus : null,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => BudgetFormSheet(
      probe: probe,
      year: year,
      month: month,
      edit: edit,
      usedCategoryIds: usedCategoryIds,
      overallNew: overallNew,
      amountFocus: amountFocus,
    ),
  );
}

/// 예산 삭제 — ds 확인창(Alert Dialog)으로 묻고(삭제는 criticalSolid), 확정하면 지운다. 밀기 트레이와 수정 시트 바닥
/// [삭제] 가 같은 길이다. 실패하면 확인창을 닫고 스낵바(critical + 다시 시도)로 알린다 — 다시 시도는 묻지 않고 바로 지운다.
/// 이미 확인창에서 한 번 확정한 삭제이고, 띠는 앱 뿌리 호스트에 있어 화면을 나가도 남는다(미리 잡아 둔 컨테이너로 돈다).
/// 확인창에서 지우기를 눌렀으면(성공이든 실패든) true.
Future<bool> confirmDeleteBudget(
  BuildContext context, {
  required BudgetMonthKey key,
  required Budget budget,
  required String name,
}) async {
  final l = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final snack = PSnackbar.of(context);
  Object? failure;
  final ok = await PAlertDialog.show(
    context,
    title: l.budgetDeleteTitle(name),
    description: l.budgetDeleteConfirm,
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    destructive: true,
    onAction: () async {
      try {
        await _deleteBudget(container, key, budget);
      } catch (e) {
        failure = e;
      }
    },
  );
  if (ok && failure != null) {
    // 응답을 못 받았으면 지워졌을 수 있다 — [다시 시도] 없이 다시 받고 한 문장(판단 ①). 아니면 실패 띠 + [다시 시도]
    showConfirmFailSnackbar(
      snack,
      error: failure,
      message: l.budgetDeleteFailed,
      retryLabel: l.actionRetry,
      retry: () => _deleteBudget(container, key, budget),
      unconfirmedMessage: unconfirmedWriteText(l, WriteKind.delete),
      onUnconfirmed: () => container
        ..invalidate(monthBudgetsProvider(key))
        ..invalidate(budgetComplianceProvider),
    );
  }
  return ok;
}

/// 수정 시트가 쓰던 저장소·무효화 경로. 실패하면 던진다(호출한 쪽 스낵바가 알리므로 요청은 silent 표식을 싣는다).
Future<void> _deleteBudget(
  ProviderContainer container,
  BudgetMonthKey key,
  Budget budget,
) async {
  final repo = await container.read(budgetRepositoryProvider.future);
  await repo.delete(budget.rowId, silent: true);
  container.invalidate(monthBudgetsProvider(key));
  // 준수율은 keepAlive — 지운 예산이 남아 있으면 달성률이 옛 값으로 굳는다.
  container.invalidate(budgetComplianceProvider);
}

/// 시트가 바뀐 값을 가졌는지 — 입력칸의 주인은 시트 State 라, 닫을 때 그쪽에 묻는다.
class _DirtyProbe {
  bool Function() dirty = () => false;
}

class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({
    super.key,
    required this.year,
    required this.month,
    this.edit,
    this.usedCategoryIds = const {},
    this.overallNew = false,
    this.probe,
    this.amountFocus,
  });

  final int year;
  final int month;
  final Budget? edit;
  final Set<int> usedCategoryIds;
  final bool overallNew;
  final Object? probe;

  /// 금액 칸 초점 노드 — 호출처가 시트의 첫 초점으로 넘기면 여기서 받아 버린다. 없으면 자기 것.
  final FocusNode? amountFocus;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _amountCtrl;
  late final FocusNode _amountFocus = widget.amountFocus ?? FocusNode();
  final _catFocus = FocusNode();
  late final String _initialAmount;
  int? _categoryRowId;
  late final int? _initialCategory;
  bool _submitting = false;
  bool _failed = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _errorKey = GlobalKey();
  String? _catError;
  String? _amountError;

  /// 100억을 넘겨 입력을 막았나 — 칸 아래 오류를 띄우고 다음 유효한 입력에서 걷는다.
  late final _amountLimit = AmountLimitGuard(
    _amountCtrl,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  bool get _isEdit => widget.edit != null;

  /// 카테고리 예산만 지운다(전체 예산은 밀기에도 없다).
  bool get _canDelete => _isEdit && widget.edit!.categoryRowId != null;

  Future<void> _delete() async {
    final edit = widget.edit!;
    final l = AppLocalizations.of(context);
    final sheet = PBottomSheet.of(context);
    final category = ref
        .read(categoriesProvider)
        .value
        ?.byRowId(edit.categoryRowId!);
    final ok = await confirmDeleteBudget(
      context,
      key: (year: widget.year, month: widget.month),
      budget: edit,
      name: budgetRowName(l, category, edit),
    );
    if (ok && mounted) sheet.close();
  }

  bool get _isOverall =>
      widget.overallNew || (_isEdit && widget.edit!.categoryRowId == null);

  @override
  void initState() {
    super.initState();
    _initialAmount = widget.edit == null
        ? ''
        : formatAmountInput(widget.edit!.budgetAmount);
    _amountCtrl = TextEditingController(text: _initialAmount);
    _categoryRowId = widget.edit?.categoryRowId;
    _initialCategory = _categoryRowId;
    final probe = widget.probe;
    if (probe is _DirtyProbe) {
      probe.dirty = () =>
          _amountCtrl.text != _initialAmount ||
          _categoryRowId != _initialCategory;
    }
  }

  @override
  void dispose() {
    _amountLimit.dispose();
    final probe = widget.probe;
    if (probe is _DirtyProbe) probe.dirty = () => false;
    _amountCtrl.dispose();
    _amountFocus.dispose();
    _catFocus.dispose();
    super.dispose();
  }

  ExpenseCategory? _categoryOf(List<ExpenseCategory>? all, int? id) {
    if (id == null) return null;
    return all?.where((c) => c.rowId == id).firstOrNull;
  }

  Future<void> _pickCategory() async {
    final picked = await PBottomSheet.show<int>(
      context,
      builder: (_) => _CategoryPickSheet(
        selectedId: _categoryRowId,
        usedCategoryIds: widget.usedCategoryIds,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _categoryRowId = picked;
      _catError = null;
    });
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    _amountLimit.dismiss();
    final l = AppLocalizations.of(context);
    final amount = parseAmountInput(_amountCtrl.text);
    final catErr = !_isEdit && !_isOverall && _categoryRowId == null
        ? l.budgetFormErrCategory
        : null;
    String? amountErr;
    if (amount == null || amount <= 0) {
      amountErr = _isOverall ? l.budgetFormErrTotal : l.budgetFormErrAmount;
    } else if (amount > kAmountMax) {
      amountErr = l.amountTooLarge;
    }
    if (catErr != null || amountErr != null) {
      setState(() {
        _catError = catErr;
        _amountError = amountErr;
      });
      if (catErr != null) {
        _catFocus.requestFocus();
      } else {
        _amountFocus.requestFocus();
      }
      return;
    }
    setState(() {
      _failed = false;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          budgetAmount: amount!,
          silent: true,
        );
      } else {
        await repo.create(
          categoryRowId: _isOverall ? null : _categoryRowId!,
          budgetAmount: amount!,
          budgetYear: widget.year,
          budgetMonth: widget.month,
          silent: true,
        );
      }
      ref.invalidate(
        monthBudgetsProvider((year: widget.year, month: widget.month)),
      );
      // 준수율은 keepAlive 라 스스로 다시 받지 않는다 — 예산을 고치면 같이 비운다.
      ref.invalidate(budgetComplianceProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 폼은 열린 채 쓴 값이 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      if (!mounted) return;
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다
      if (isUnconfirmedSave(e)) {
        ref.invalidate(
          monthBudgetsProvider((year: widget.year, month: widget.month)),
        );
        ref.invalidate(budgetComplianceProvider);
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
    final categories = ref.watch(categoriesProvider).value;
    final canDelete = _canDelete;
    final presets = _isOverall ? kBudgetTotalPresets : kBudgetCategoryPresets;
    final title = _isOverall
        ? l.budgetMonthTotal(widget.month)
        : (_isEdit ? l.budgetCategoryEdit : l.budgetCategoryAdd);

    Widget? categoryRow;
    if (!_isOverall) {
      final cat = _categoryOf(categories, _categoryRowId);
      final name = cat?.categoryName ?? widget.edit?.categoryName;
      final hasName = _categoryRowId != null && name != null;
      categoryRow = PickerRow(
        title: l.expCategory,
        value: hasName ? name : null,
        placeholder: l.budgetFormCategoryPlaceholder,
        semanticValue: hasName ? name : l.expNone,
        leading: hasName
            ? PickerDot(
                color: resolveChartColor(
                  context,
                  cat?.color,
                  fallback: c.fgBrand,
                ),
              )
            : null,
        errorMessage: _catError,
        focusNode: _catFocus,
        onTap: _isEdit ? null : _pickCategory,
      );
    }

    return PBottomSheetContent(
      title: title,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
              ),
              child: FormErrorCallout(
                key: _errorKey,
                message: saveFailureText(l, _failure, l.budgetSaveFailed),
              ),
            ),
          ?categoryRow,
          if (categoryRow != null) const SizedBox(height: PSpacing.x3),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
            ),
            child: PField(
              label: _isOverall
                  ? l.budgetOverallCapLabel
                  : l.budgetFormAmountLabel,
              invalid: _amountError != null || _amountLimit.over,
              errorMessage: _amountLimit.over
                  ? AppLocalizations.of(context).amountTooLarge
                  : _amountError,
              child: PInput(
                variant: PInputVariant.underline,
                controller: _amountCtrl,
                focusNode: _amountFocus,
                placeholder: '0',
                suffixText: wonUnit(),
                tabularFigures: true,
                keyboardType: TextInputType.number,
                inputFormatters: _amountLimit.formatters,
                onChanged: (_) => setState(() => _amountError = null),
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x6,
            ),
            child: PChipGroup(
              semanticLabel: l.budgetFormQuickAmounts,
              children: [
                for (final v in presets)
                  PChip(
                    label: _presetLabel(context, v),
                    variant: PChipVariant.solid,
                    onPressed: () => setState(() {
                      _amountCtrl.text = formatAmountInput(v);
                      _amountError = null;
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
      footer: canDelete
          ? const []
          : [
              PButton(
                label: _isEdit ? l.actionSave : l.budgetSubmitAdd,
                size: PButtonSize.large,
                loading: _submitting,
                onPressed: _submitting ? null : _onSubmit,
              ),
            ],
      // 카테고리 예산 수정 — 바닥 왼쪽 [삭제](밀기와 같은 동작 · 확인창 한 번). 밀기는 지름길이라 닫는 길은 여기에도 있다
      footerRow: canDelete
          ? Row(
              spacing: PSpacing.x2,
              children: [
                // 내용 폭 ghost critical — 안쪽 여백 20 을 바깥으로 내어 글이 화면 여백 24 에 선다
                Transform.translate(
                  offset: const Offset(-20, 0),
                  child: PButton(
                    label: l.actionDelete,
                    variant: PButtonVariant.ghost,
                    ghostColor: PButtonGhostColor.critical,
                    size: PButtonSize.large,
                    onPressed: _submitting ? null : _delete,
                  ),
                ),
                Expanded(
                  child: PButton(
                    label: l.actionSave,
                    size: PButtonSize.large,
                    loading: _submitting,
                    onPressed: _submitting ? null : _onSubmit,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

/// 카테고리 고르기 — 폼 시트 위에 뜨는 시트. 지출 최상위 카테고리 모두, 이번 달 예산이 있는 것은 막힌 줄.
/// 누르면 바로 고르고 닫는다.
class _CategoryPickSheet extends ConsumerWidget {
  const _CategoryPickSheet({
    required this.selectedId,
    required this.usedCategoryIds,
  });

  final int? selectedId;
  final Set<int> usedCategoryIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(categoriesProvider);

    Widget body;
    if (async.loadFailed) {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
        child: PResultSection(
          kind: PResultKind.failure,
          size: PResultSize.medium,
          title: l.budgetPickLoadFailTitle,
          description: l.budgetPickLoadFailDesc,
          primaryAction: PResultAction(
            label: l.actionRetry,
            loading: async.loadRetrying,
            onPressed: () => ref.invalidate(categoriesProvider),
          ),
        ),
      );
    } else if (!async.hasValue) {
      body = loadingRegion(
        Column(
          children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PSpacing.globalGutter,
                  vertical: PSpacing.x3,
                ),
                child: Row(
                  spacing: PSpacing.x3,
                  children: [
                    const PSkeleton(
                      width: PListTile.size,
                      height: PListTile.size,
                      radius: PSkeletonRadius.r12,
                    ),
                    PSkeleton.text(PTypography.t5, width: 140),
                  ],
                ),
              ),
          ],
        ),
      );
    } else {
      // 웹 기준 통일: 예산 가능 카테고리 = EXPENSE 최상위(부모)만. 자식 지출은 부모로 roll-up 집계된다.
      final list = [
        for (final cat in async.requireValue)
          if (cat.expenseType == 'EXPENSE' && cat.parentRowId == null) cat,
      ];
      final allUsed =
          list.isNotEmpty &&
          list.every((e) => usedCategoryIds.contains(e.rowId));
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (list.isEmpty || allUsed)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
                vertical: PSpacing.x3,
              ),
              child: PText(
                list.isEmpty ? l.budgetPickNoCategory : l.budgetPickAllBudgeted,
                style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
          PList(
            semanticLabel: l.expCategory,
            children: [
              for (final cat in list)
                _pickItem(context, cat, usedCategoryIds.contains(cat.rowId), l),
            ],
          ),
        ],
      );
    }

    return PBottomSheetContent(
      title: l.expCategory,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: body,
    );
  }

  Widget _pickItem(
    BuildContext context,
    ExpenseCategory cat,
    bool used,
    AppLocalizations l,
  ) {
    final c = context.colors;
    final fg = resolveChartColor(context, cat.color, fallback: c.fgBrand);
    final selected = !used && cat.rowId == selectedId;
    return Semantics(
      selected: selected,
      child: PListButtonItem(
        title: cat.categoryName,
        detail: used ? l.budgetPickUsed : null,
        prefix: PListTile(
          background: softBg(context, fg),
          color: fg,
          child: Icon(lucideByName(cat.icon)),
        ),
        suffix: selected
            ? Icon(LucideIcons.check500, color: c.fgNeutral)
            : null,
        onTap: used ? null : () => PBottomSheet.of(context).close(cat.rowId),
      ),
    );
  }
}
