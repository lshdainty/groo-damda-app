import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/category_pick.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_form_parts.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/expense_split/domain/expense_split.dart';
import 'package:groo_damda_app/features/expense_split/domain/split_math.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/forms/step_done.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 항목 이름 길이 상한 — 지금 그대로(서버 label 상한).
const int kSplitLabelMax = 50;

class _Row {
  _Row({this.rowId, this.categoryRowId, required this.amount, this.label = ''});
  final int? rowId;
  int? categoryRowId;
  int amount;
  String label;
}

/// 거래 나누기 단계(I-21 F 34 ~ 38) — 같은 시트 안 한 단계. 머리 ← "내역 분할" 닫기 → 원 거래 줄 → (맞추기 Callout) → "나눈 내역 n개" +
/// "균등 분배" → 항목 줄 → "항목 추가" → "내역 분할 풀기" → 바닥 위 "남은 금액" → [저장]. 항목을 누르면 같은 시트 한 단계 더(항목 n).
///
/// - 열린 길 둘: 상세 "내역 분할" 줄(저장하면 서버에 보내고 [onFinished]) · 수정 · 고쳐 쓰기의 [나눈 내역 맞추기]([onReconciled] 가 있으면
///   서버에 보내지 않고 폼으로 돌려준다 — 맞추기 모드).
/// - 저장은 켜 둔다 — 남은 금액 ≠ 0 이거나 항목이 둘 미만이면 누를 때 알린다.
/// - 저장 본문에 항목 `rowId` 를 싣는다(row_id 정체성 — 제자리 수정).
class SplitStepFlow extends ConsumerStatefulWidget {
  const SplitStepFlow({
    super.key,
    required this.expense,
    required this.probe,
    required this.onBack,
    this.onFinished,
    this.overrideTotal,
    this.recordedTotal,
    this.initialSplits,
    this.onReconciled,
  });

  final Expense expense;
  final StepProbe probe;

  /// 저장 없이 떠난다(호스트가 연 곳으로 돌아간다) — 바뀐 값은 이 단계가 먼저 묻는다.
  final VoidCallback onBack;

  /// 서버에 저장했거나 분할을 풀었다 — 호스트가 상세로 돌아간다.
  final VoidCallback? onFinished;

  /// 맞추기 목표 총액(폼에서 바뀐 금액) · 변경 전 총액 · 진행 중 분할.
  final int? overrideTotal;
  final int? recordedTotal;
  final List<SplitInput>? initialSplits;

  /// 있으면 맞추기 모드 — 저장 대신 이 콜백으로 분할을 돌려준다.
  final void Function(List<SplitInput> splits)? onReconciled;

  @override
  ConsumerState<SplitStepFlow> createState() => _SplitStepFlowState();
}

class _SplitStepFlowState extends ConsumerState<SplitStepFlow> {
  List<_Row>? _rows;
  String _initialSig = '';
  bool _hasExisting = false;
  bool _submitting = false;
  bool _leaving = false;
  bool _attempted = false;
  bool _saveError = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _saveErrorKey = GlobalKey();

  // 항목 단계 — null 이면 목록. -1 이면 새 항목, 0 이상이면 그 차례 항목.
  int? _item;
  int? _itemCat;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _amountFocus = FocusNode();
  bool _itemAttempted = false;
  String _itemSig = '';

  Expense get _e => widget.expense;
  int get _totalAbs => widget.overrideTotal ?? _e.amount.abs();
  int get _recordedTotal => widget.recordedTotal ?? _e.amount.abs();
  bool get _reconcileMode => widget.onReconciled != null;
  bool get _totalChanged =>
      widget.overrideTotal != null && widget.overrideTotal != _recordedTotal;

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () => mounted && (_submitting || _dirty);
    widget.probe.interceptClose = _intercept;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    widget.probe.interceptClose = () => false;
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _nameFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  // ── 값 ────────────────────────────────────────────────────
  String _sigOf(List<_Row> rows) => [
    for (final r in rows)
      '${r.rowId}:${r.categoryRowId}:${r.amount}:${r.label}',
  ].join('|');

  bool get _dirty => _rows != null && _sigOf(_rows!) != _initialSig;

  void _initRows(List<ExpenseSplit> splits) {
    _hasExisting = splits.isNotEmpty;
    final init = widget.initialSplits;
    if (init != null && init.isNotEmpty) {
      _rows = [
        for (final s in init)
          _Row(
            rowId: s.rowId,
            categoryRowId: s.categoryRowId,
            amount: s.amount,
            label: s.label ?? '',
          ),
      ];
    } else if (splits.isNotEmpty) {
      _rows = [
        for (final s in splits)
          _Row(
            rowId: s.rowId,
            categoryRowId: s.categoryRowId,
            amount: s.amount,
            label: s.label ?? '',
          ),
      ];
    } else {
      // 저장된 분할이 없으면 반반
      final half = _totalAbs ~/ 2;
      _rows = [
        _Row(
          categoryRowId: _e.categoryRowId,
          amount: _totalAbs - half,
          label: _e.merchant ?? _e.description ?? '',
        ),
        _Row(categoryRowId: _e.categoryRowId, amount: half),
      ];
    }
    _initialSig = _sigOf(_rows!);
  }

  int get _sum => _rows!.fold(0, (s, r) => s + r.amount);
  int get _remainder => _totalAbs - _sum;

  void _applyAmounts(List<int> amts) {
    setState(() {
      for (var i = 0; i < _rows!.length; i++) {
        _rows![i].amount = amts[i];
      }
    });
  }

  void _splitEvenly() => _applyAmounts(evenAmounts(_rows!.length, _totalAbs));

  void _reconcileProportional() => _applyAmounts(
    proportionalAmounts([for (final r in _rows!) r.amount], _totalAbs),
  );

  void _reconcileToLargest() => _applyAmounts(
    toLargestAmounts([for (final r in _rows!) r.amount], _totalAbs),
  );

  void _reconcileAddRow() {
    if (_remainder <= 0) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _rows!.add(
        _Row(
          categoryRowId: _e.categoryRowId,
          amount: _remainder,
          label: l.expAddAmount,
        ),
      );
    });
  }

  // ── 단계 ────────────────────────────────────────────────
  /// 뒤로 가기 · Esc — 항목 단계면 그 단계만, 목록이면 이 단계를 떠난다(바뀐 값이 있으면 먼저 묻는다). 시트는 닫지 않는다.
  bool _intercept() {
    if (!mounted) return false;
    if (_submitting) return true;
    if (_item != null) {
      _leaveItem();
    } else {
      _leaveList();
    }
    return true;
  }

  Future<bool> _confirmLeave() async {
    if (_leaving) return false;
    _leaving = true;
    final l = AppLocalizations.of(context);
    final leave = await PAlertDialog.confirmLeave(
      context,
      PLeaveConfirmCopy(
        title: l.sheetLeaveTitle,
        description: l.sheetLeaveDescription,
        stayLabel: l.sheetLeaveStay,
        leaveLabel: l.sheetLeaveLeave,
      ),
    );
    _leaving = false;
    return leave && mounted;
  }

  Future<void> _leaveList() async {
    if (_submitting || _leaving) return;
    if (_dirty && !await _confirmLeave()) return;
    widget.onBack();
  }

  String get _currentItemSig =>
      '$_itemCat|${_nameCtrl.text}|${_amountCtrl.text}';

  Future<void> _leaveItem() async {
    if (_leaving) return;
    if (_currentItemSig != _itemSig && !await _confirmLeave()) return;
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _item = null);
  }

  void _openItem(int index) {
    FocusScope.of(context).unfocus();
    final rows = _rows!;
    final isNew = index < 0;
    final r = isNew ? null : rows[index];
    _itemCat = isNew ? _e.categoryRowId : r!.categoryRowId;
    _nameCtrl.text = isNew ? '' : r!.label;
    _amountCtrl.text = groupWon(
      isNew ? (_remainder > 0 ? _remainder : 0) : r!.amount,
    );
    _itemAttempted = false;
    _itemSig = _currentItemSig;
    setState(() => _item = index);
  }

  void _doneItem() {
    final l = AppLocalizations.of(context);
    final amount = parseAmountInput(_amountCtrl.text) ?? 0;
    if (_itemCat == null || amount <= 0) {
      setState(() => _itemAttempted = true);
      if (amount <= 0) _amountFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      final label = _nameCtrl.text.trim();
      if (_item! < 0) {
        _rows!.add(_Row(categoryRowId: _itemCat, amount: amount, label: label));
      } else {
        final r = _rows![_item!];
        r.categoryRowId = _itemCat;
        r.amount = amount;
        r.label = label;
      }
      _item = null;
    });
    assert(l.actionDone.isNotEmpty);
  }

  /// "이 항목 지우기" — 바로 빼고 목록으로(확인 없음 — 저장 전이라 되돌릴 수 있다).
  void _dropItem() {
    final i = _item;
    if (i == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (i >= 0) _rows!.removeAt(i);
      _item = null;
    });
  }

  Future<void> _pickItemCategory() async {
    FocusScope.of(context).unfocus();
    final picked = await showCategoryPickSheet(
      context,
      kind: _e.expenseType == 'INCOME' ? 'INCOME' : 'EXPENSE',
      selectedRowId: _itemCat,
    );
    if (picked == null || !mounted) return;
    setState(() => _itemCat = picked);
  }

  // ── 저장 ────────────────────────────────────────────────
  void _showSaveError([Object? error]) {
    // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
    if (isUnconfirmedSave(error)) unawaited(_refreshAfterChange());
    setState(() {
      _saveError = true;
      _failure = error;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _saveErrorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      revealBelowFog(ctx);
    });
  }

  Future<void> _save() async {
    if (_submitting) return;
    // 이중 제출 막기는 await 앞에서 — 진입 즉시 켜고 모든 return 에서 푼다
    setState(() {
      _submitting = true;
      _attempted = true;
      _saveError = false;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final rows = _rows!;
      if (_remainder != 0 || rows.length < 2) return;
      if (rows.any((r) => r.categoryRowId == null || r.amount <= 0)) return;
      final inputs = <SplitInput>[
        for (var i = 0; i < rows.length; i++)
          SplitInput(
            rowId: rows[i].rowId,
            categoryRowId: rows[i].categoryRowId!,
            amount: rows[i].amount,
            label: rows[i].label.trim().isEmpty ? null : rows[i].label.trim(),
            sortOrder: i,
          ),
      ];
      final onReconciled = widget.onReconciled;
      if (onReconciled != null) {
        onReconciled(inputs);
        return;
      }
      final repo = await ref.read(expenseSplitRepositoryProvider.future);
      await repo.replace(_e.rowId, splits: inputs, silent: true);
      await _refreshAfterChange();
      if (!mounted) return;
      widget.onFinished?.call();
    } catch (e) {
      if (mounted) _showSaveError(e);
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 분할은 거래 목록 · 자산 잔액에 영향 — 관련 캐시를 다시 받는다. 상세가 새 값으로 그려지도록 분할 목록은 받은 뒤에 돌아간다.
  Future<void> _refreshAfterChange() async {
    final iso = _e.expenseDate;
    if (iso != null && iso.length >= 10) {
      final p = iso.substring(0, 10).split('-');
      ref.invalidate(
        monthExpensesProvider((year: int.parse(p[0]), month: int.parse(p[1]))),
      );
    }
    invalidateAfterExpenseChange(ref);
    ref.invalidate(expenseSplitsProvider(_e.rowId));
    try {
      await ref.read(expenseSplitsProvider(_e.rowId).future);
    } catch (_) {}
  }

  Future<void> _removeAll() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final e = _e;
    final ok = await askConfirmThenRequest(
      context,
      title: l.expSplitRemoveTitle,
      description: l.expSplitRemoveBody,
      actionLabel: l.expSplitRemoveAction,
      cancelLabel: l.actionCancel,
      request: () async {
        final repo = await container.read(
          expenseSplitRepositoryProvider.future,
        );
        await repo.deleteAll(e.rowId, silent: true);
        final iso = e.expenseDate;
        if (iso != null && iso.length >= 10) {
          final p = iso.substring(0, 10).split('-');
          container.invalidate(
            monthExpensesProvider((
              year: int.parse(p[0]),
              month: int.parse(p[1]),
            )),
          );
        }
        invalidateAfterExpenseChangeIn(container);
        container.invalidate(expenseSplitsProvider(e.rowId));
        try {
          await container.read(expenseSplitsProvider(e.rowId).future);
        } catch (_) {}
      },
      failedMessage: l.expSplitRemoveFailed,
      retryLabel: l.actionRetry,
      // 다시 시도가 성공하면 풀린 것이다 — 지운 항목이 남은 채 저장되지 않게 상세로 돌아간다
      onRetried: () {
        container.invalidate(expenseSplitsProvider(e.rowId));
        if (mounted) widget.onFinished?.call();
      },
      kind: WriteKind.delete,
      // 응답을 못 받았다 — 풀렸을 수 있다. 다시 받기만(검수 M3)
      onUnconfirmed: () {
        container.invalidate(monthExpensesProvider);
        invalidateAfterExpenseChangeIn(container);
        container.invalidate(expenseSplitsProvider(e.rowId));
      },
    );
    if (ok && mounted) widget.onFinished?.call();
  }

  // ── 그리기 ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_rows == null) {
      final init = widget.initialSplits;
      if (init != null && init.isNotEmpty) {
        _initRows(const []);
      } else {
        final async = ref.watch(expenseSplitsProvider(_e.rowId));
        if (async.hasValue) {
          _initRows(async.value!);
        } else {
          return _frame(
            l,
            body: async.loadFailed
                ? PResultSection(
                    kind: PResultKind.failure,
                    size: PResultSize.medium,
                    title: l.expSplitLoadFailed,
                    description: l.expSplitLoadFailedDesc,
                    primaryAction: PResultAction(
                      label: l.actionRetry,
                      loading: async.loadRetrying,
                      onPressed: () =>
                          ref.invalidate(expenseSplitsProvider(_e.rowId)),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: PSpacing.globalGutter,
                      vertical: PSpacing.x4,
                    ),
                    child: PSkeleton(height: 120),
                  ),
          );
        }
      }
    }
    return _item != null ? _buildItem(l) : _buildList(l);
  }

  PBottomSheetContent _frame(
    AppLocalizations l, {
    required Widget body,
    Widget? footerRow,
  }) => PBottomSheetContent(
    key: const ValueKey('split-step'),
    title: l.expSplit,
    closeLabel: l.actionClose,
    onClose: () => PBottomSheet.of(context).requestClose(wholeSheet: true),
    onBack: _leaveList,
    backLabel: l.actionBack,
    flushBody: true,
    scrollFog: true,
    body: body,
    footerRow: footerRow,
  );

  Widget _tile(BuildContext context, ExpenseCategory? cat, Color fg) =>
      PListTile(
        background: softBg(context, fg),
        color: fg,
        child: Icon(lucideByName(cat?.icon, fallback: LucideIcons.tag)),
      );

  Widget _buildList(AppLocalizations l) {
    final c = context.colors;
    final rows = _rows!;
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(_e.expenseType);
    final catsAsync = ref.watch(categoriesProvider);
    final cats = catsAsync.value;
    final isIncome = _e.expenseType == 'INCOME';
    final sign = isIncome ? '+' : kMinus;
    final remainder = _remainder;
    final srcCat = _e.categoryRowId == null
        ? null
        : cats?.byRowId(_e.categoryRowId!);
    final srcFg = resolveChartColor(
      context,
      srcCat?.color ?? _e.categoryColor,
      fallback: c.fgBrand,
    );
    final srcName = expenseActions.displayNameOf(context, _e);
    final remainErr = _attempted && !_submitting && remainder != 0
        ? l.expSplitErrRemain
        : null;
    final rowErr =
        _attempted &&
            !_submitting &&
            rows.any((r) => r.categoryRowId == null || r.amount <= 0)
        ? l.expSplitErrRow
        : null;
    final countErr = _attempted && !_submitting && rows.length < 2
        ? l.expSplitErrCount
        : null;
    final showReconcile = _reconcileMode && remainder != 0;
    final over = remainder < 0;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_saveError)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
            ),
            child: Container(
              key: _saveErrorKey,
              child: FormErrorCallout(
                message: saveFailureText(l, _failure, l.expSplitSaveFailed),
              ),
            ),
          ),
        PList(
          semanticLabel: l.expSplitSourceNote,
          children: [
            PListItem(
              key: const ValueKey('split-source'),
              title: srcName,
              prefix: _tile(context, srcCat, srcFg),
              detail: _reconcileMode && _totalChanged
                  ? null
                  : l.expSplitSourceNote,
              detailChild: _reconcileMode && _totalChanged
                  ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: txMoney(_recordedTotal, masked),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          TextSpan(text: ' → ${txMoney(_totalAbs, masked)}'),
                        ],
                      ),
                      semanticsLabel:
                          '${l.expSplitOldTotal(txMoney(_recordedTotal, masked))} → ${txMoney(_totalAbs, masked)}',
                    )
                  : null,
              suffix: PListValue.amount(
                krwSigned(_totalAbs, masked, sign: sign, unit: true),
                style: TextStyle(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        if (showReconcile)
          TxStatusSlot(
            child: PCallout(
              key: const ValueKey('split-reconcile'),
              tone: PCalloutTone.warning,
              title: l.expSplitReconcileTitle,
              description: over
                  ? l.expSplitReconcileOver(
                      txMoney(_sum, masked),
                      txMoney(_totalAbs, masked),
                      txMoney(remainder, masked),
                    )
                  : l.expSplitReconcileShort(
                      txMoney(_sum, masked),
                      txMoney(_totalAbs, masked),
                      txMoney(remainder, masked),
                    ),
              actions: [
                PButton(
                  label: l.expSplitActProportional,
                  variant: PButtonVariant.neutralOutline,
                  size: PButtonSize.small,
                  onPressed: _reconcileProportional,
                ),
                PButton(
                  label: l.expSplitActLargest,
                  variant: PButtonVariant.neutralOutline,
                  size: PButtonSize.small,
                  onPressed: _reconcileToLargest,
                ),
                if (remainder > 0)
                  PButton(
                    label: l.expSplitActAdjust,
                    variant: PButtonVariant.neutralOutline,
                    size: PButtonSize.small,
                    onPressed: _reconcileAddRow,
                  ),
              ],
            ),
          ),
        PListHeader(
          title: l.expSplitItemsHeader(rows.length),
          variant: PListHeaderVariant.boldSolid,
          headingLevel: 3,
          topInset: PSpacing.x1,
          action: PTextButton(
            label: l.expSplitEven,
            onPressed: _submitting ? null : _splitEvenly,
          ),
        ),
        PList(
          semanticLabel: l.expSplitItemsHeader(rows.length),
          children: [
            for (var i = 0; i < rows.length; i++)
              _itemRow(context, l, i, rows[i], cats, masked, sign),
            PListButtonItem(
              key: const ValueKey('split-add'),
              title: l.expSplitAddItem,
              titleColor: c.fgBrand,
              prefix: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PRounded.r3),
                  border: Border.all(color: c.strokeNeutralWeak),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(LucideIcons.plus, size: 22, color: c.fgBrand),
                ),
              ),
              onTap: _submitting ? null : () => _openItem(-1),
            ),
            if (_hasExisting && !_reconcileMode)
              PListButtonItem(
                key: const ValueKey('split-remove-all'),
                title: l.expSplitRemoveAll,
                titleColor: c.fgCritical,
                onTap: _submitting ? null : _removeAll,
              ),
          ],
        ),
      ],
    );

    return _frame(
      l,
      body: body,
      footerRow: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _remainRow(l, remainder, masked),
          if (remainErr != null || countErr != null || rowErr != null)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpacing.x2),
              child: Text(
                keepAll(remainErr ?? countErr ?? rowErr!),
                key: const ValueKey('split-error'),
                textAlign: TextAlign.end,
                style: PTypography.t3.copyWith(color: c.fgCritical),
              ),
            ),
          PButton(
            label: l.actionSave,
            size: PButtonSize.large,
            loading: _submitting,
            onPressed: _submitting ? null : _save,
          ),
        ],
      ),
    );
  }

  /// 바닥 버튼 바로 위 한 줄 — 0 이면 확인 아이콘 + "0원", 모자라면 경고 + "{금액}원 모자라요", 넘치면 "{금액}원 넘쳐요".
  Widget _remainRow(AppLocalizations l, int remainder, bool masked) {
    final c = context.colors;
    final ok = remainder == 0;
    final color = ok ? c.fgPositive : c.fgWarningContrast;
    final text = ok
        ? txMoney(0, masked)
        : remainder > 0
        ? l.expSplitShortBy(txMoney(remainder, masked))
        : l.expSplitOverBy(txMoney(remainder, masked));
    return Padding(
      key: const ValueKey('split-remaining'),
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.expSplitRemaining,
              style: PTypography.t4.copyWith(color: c.fgNeutral),
            ),
          ),
          Icon(
            ok ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
            size: 16,
            color: color,
          ),
          const SizedBox(width: PSpacing.x1),
          Text(
            // 쉼표 뒤에서만 줄을 바꾼다
            text.replaceAll(',', '⁠,​'),
            semanticsLabel: text,
            style: PTypography.t4.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(
    BuildContext context,
    AppLocalizations l,
    int i,
    _Row r,
    List<ExpenseCategory>? cats,
    bool masked,
    String sign,
  ) {
    final c = context.colors;
    final cat = r.categoryRowId == null
        ? null
        : cats?.byRowId(r.categoryRowId!);
    final parent = cat?.parentRowId == null
        ? null
        : cats?.byRowId(cat!.parentRowId!);
    final fg = resolveChartColor(context, cat?.color, fallback: c.fgBrand);
    final pct = _totalAbs > 0 ? ((r.amount / _totalAbs) * 100).round() : 0;
    // 목록을 받기 전은 "…" — 없음으로 보이지 않게
    final catName = cats == null ? '…' : (cat?.categoryName ?? '-');
    final title = r.label.trim().isNotEmpty ? r.label.trim() : catName;
    return PListButtonItem(
      key: ValueKey('split-item-$i'),
      title: title,
      prefix: _tile(context, cat, fg),
      detailChild: PTagGroup(
        size: PTagGroupSize.t3,
        overflow: PTagGroupOverflow.truncate,
        items: [
          if (parent != null) PTag(parent.categoryName, shrink: 2),
          PTag(catName, shrink: 1),
          PTag('$pct%', shrink: 0),
        ],
      ),
      onTap: _submitting ? null : () => _openItem(i),
      suffix: PListSuffix(
        children: [
          PListValue.amount(
            krwSigned(r.amount, masked, sign: sign, unit: true),
            style: TextStyle(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
        ],
      ),
    );
  }

  // ── 항목 단계 ────────────────────────────────────────────
  Widget _buildItem(AppLocalizations l) {
    final c = context.colors;
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(_e.expenseType);
    final cats = ref.watch(categoriesProvider).value;
    final index = _item!;
    final catName = _itemCat == null
        ? null
        : (cats == null ? '…' : cats.byRowId(_itemCat!)?.categoryName);
    final others = _rows!
        .asMap()
        .entries
        .where((e) => e.key != index)
        .fold<int>(0, (s, e) => s + e.value.amount);
    final amount = parseAmountInput(_amountCtrl.text) ?? 0;
    final amountErr = _itemAttempted && amount <= 0 ? l.recErrAmount : null;
    final catErr = _itemAttempted && _itemCat == null ? l.recErrCategory : null;
    final nameTail = index < 0 ? _rows!.length + 1 : index + 1;
    return PBottomSheetContent(
      key: ValueKey('split-item-step-$index'),
      title: l.expSplitItemTitle(nameTail),
      closeLabel: l.actionClose,
      showCloseButton: false,
      onBack: _leaveItem,
      backLabel: l.actionBack,
      headerAction: StepDoneButton(label: l.actionDone, onPressed: _doneItem),
      flushBody: true,
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickerRow(
            title: l.expCategory,
            prefix: const Icon(LucideIcons.tag),
            value: catName,
            placeholder: l.recSelectOf(l.expCategory),
            errorMessage: catErr,
            onTap: _pickItemCategory,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x3,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PField(
              label: l.expSplitItemName,
              indicator: PFieldIndicator.optional,
              maxGraphemeCount: kSplitLabelMax,
              child: PInput(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                semanticLabel: l.expSplitItemName,
                placeholder: l.expSplitItemNamePh,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x2,
              PSpacing.globalGutter,
              PSpacing.x4,
            ),
            child: PField(
              label: l.expAmount,
              invalid: amountErr != null,
              errorMessage: amountErr,
              description: amountErr != null
                  ? null
                  : l.expSplitItemHelp(
                      txMoney(others, masked),
                      txMoney(_totalAbs, masked),
                    ),
              child: PInput(
                controller: _amountCtrl,
                focusNode: _amountFocus,
                variant: PInputVariant.underline,
                semanticLabel: l.expAmount,
                placeholder: '0',
                suffixText: wonUnit(),
                tabularFigures: true,
                keyboardType: TextInputType.number,
                inputFormatters: kWonFormatters,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _doneItem(),
              ),
            ),
          ),
          if (index >= 0)
            PList(
              semanticLabel: l.expSplitDropItem,
              children: [
                PListButtonItem(
                  key: const ValueKey('split-drop-item'),
                  title: l.expSplitDropItem,
                  titleColor: c.fgCritical,
                  onTap: _dropItem,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
