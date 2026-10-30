import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_edit_route.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_from_tx_dialog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/refund_step.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/presentation/split_tx_dialog.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_settings_drawer.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

/// 거래 상세(I-21 21-1 · B · A) — 읽는 상세 + "더 하기" 동작 줄. 같은 시트 안에서 상세 ↔ 환불 단계가 바뀐다(2-2A).
///
/// - 머리 `지출 상세` · 닫기 → 타일 48 + 이름 → 금액 → 날짜 · 시각 → (상태 Callout) → 키-값 줄 → "더 하기" 줄 넷 → 내역 분할 →
///   이 가맹점 이번 달 → 바닥 [삭제][수정].
/// - 환불은 상세 안 한 단계다(머리 ← · "환불 처리" · 닫기 · 바닥 [환불 처리]). 환불 · 환불 취소 응답으로 상세를 다시 그린다.
/// - 상세는 조회라 바깥 누르기 · 끌기로 닫히고, 환불 단계는 입력 폼이라 닫히지 않는다(단계마다 규칙이 바뀐다). ← · 뒤로 가기 = 상세,
///   닫기 원 · 바깥 · 끌기 = 시트 전체. 바뀐 값(환불일)이 있으면 먼저 "작성한 내용이 사라져요" 를 묻는다.
/// - [수정] 은 21-2 가 폼을 단계로 옮기기 전까지 지금 방식이다 — 상세를 내리고 옛 [showAddTxSheet] 를 연다. 저장하면 응답 값으로 상세를
///   다시 열고, 저장 없이 닫혀도 상세로 돌아온다. 고쳐 쓰기 저장은 돌아갈 상세가 없어 모두 닫는다.
/// - 나누기 · 반복 · 더치페이는 21-3 이 단계로 옮긴다 — 그때까지 지금처럼 시트를 닫고 옛 표면을 연다.
Future<void> showTxDetailDialog(BuildContext context, Expense expense) {
  final l = AppLocalizations.of(context);
  final hooks = _TxFlowHooks();
  final host = hostContextOf(context);
  return PBottomSheet.show<void>(
    context,
    isForm: () => hooks.isForm(),
    isDirty: () => hooks.isDirty(),
    interceptClose: () => hooks.interceptClose(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _TxDetailFlow(expense: expense, hooks: hooks, host: host),
  );
}

/// 시트의 닫는 길이 그 순간의 단계를 묻는 자리 — 단계의 주인은 [_TxDetailFlowState] 라 시트 밖에서 이 줄로 닿는다.
class _TxFlowHooks {
  bool Function() isForm = () => false;
  bool Function() isDirty = () => false;
  bool Function() interceptClose = () => false;
}

enum _Step { detail, refund }

/// 상세 본문 맨 위 실패 알림의 종류.
enum _Failure { none, delete, cancelRefund }

class _TxDetailFlow extends ConsumerStatefulWidget {
  const _TxDetailFlow({
    required this.expense,
    required this.hooks,
    required this.host,
  });

  final Expense expense;
  final _TxFlowHooks hooks;

  /// 시트보다 오래 사는 context — 시트를 닫고 다른 표면을 열 때 쓴다.
  final BuildContext host;

  @override
  ConsumerState<_TxDetailFlow> createState() => _TxDetailFlowState();
}

class _TxDetailFlowState extends ConsumerState<_TxDetailFlow> {
  _Step _step = _Step.detail;

  /// 화면이 그리는 거래 — 환불 · 환불 취소가 돌려준 거래로 갈아 끼운다.
  late Expense _e = widget.expense;

  /// 환불일(날짜만) — 처음은 오늘.
  late DateTime _refundDate = _today();
  bool _refundFailed = false;

  bool _deleting = false;
  bool _refunding = false;
  bool _cancelling = false;

  /// 지우기를 마치고 시트가 닫히는 중 — 닫히는 동안 버튼을 다시 열지 않는다.
  bool _closing = false;
  bool _leaving = false;
  _Failure _failure = _Failure.none;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _busy => _deleting || _refunding || _cancelling || _closing;

  @override
  void initState() {
    super.initState();
    final h = widget.hooks;
    h.isForm = () => mounted && _step == _Step.refund;
    h.isDirty = () => mounted && _step == _Step.refund && _refundDirty;
    h.interceptClose = _intercept;
  }

  @override
  void dispose() {
    final h = widget.hooks;
    h.isForm = () => false;
    h.isDirty = () => false;
    h.interceptClose = () => false;
    super.dispose();
  }

  bool get _refundDirty => _refundDate != _today();

  // ── 단계 ────────────────────────────────────────────────
  /// 뒤로 가기 · `Esc` 한 번 = 한 단계 뒤(환불 → 상세). 시트의 닫는 길이 먼저 묻는다.
  bool _intercept() {
    if (!mounted || _step == _Step.detail) return false;
    _leaveRefund();
    return true;
  }

  void _openRefund() {
    setState(() {
      _refundDate = _today();
      _refundFailed = false;
      _step = _Step.refund;
    });
  }

  /// 환불 → 상세. 바뀐 값이 있으면 먼저 "작성한 내용이 사라져요".
  Future<void> _leaveRefund() async {
    if (_leaving || _refunding) return;
    if (!_refundDirty) {
      _goDetail();
      return;
    }
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
    if (leave && mounted) _goDetail();
  }

  void _goDetail() => setState(() {
    _step = _Step.detail;
    _refundFailed = false;
  });

  // ── 동작 ────────────────────────────────────────────────
  Asset? _assetOf(Expense e) {
    final id = e.assetRowId;
    if (id == null) return null;
    return ref.read(assetsProvider).value?.byRowId(id);
  }

  /// 삭제 — 확인창 → 요청. 실패는 확인창을 닫은 뒤 시트 안 보이는 자리(본문 맨 위 Callout)에 알리고 [삭제] 로 다시 시도한다.
  /// 지운 뒤에는 목록을 다시 받고 시트를 닫으며, 그동안 버튼은 다시 열리지 않는다.
  Future<void> _delete() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final asset = _assetOf(_e);
    final ok = await PAlertDialog.show(
      context,
      title: expenseActions.deleteConfirmTitle(context, _e),
      description: expenseActions.deleteConfirmMessageWith(context, _e, asset),
      actionLabel: l.actionDelete,
      destructive: true,
      cancelLabel: l.actionCancel,
    );
    if (!ok || !mounted) return;
    setState(() {
      _deleting = true;
      _failure = _Failure.none;
    });
    try {
      await expenseActions.delete(
        context,
        ref,
        _e,
        asset: asset,
        silent: true,
        throwOnError: true,
      );
      if (!mounted) return;
      _closing = true;
      PBottomSheet.of(context).close();
    } on ApiException {
      if (mounted) setState(() => _failure = _Failure.delete);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  /// 환불 처리 — 요청이 끝나고 목록을 다시 받은 뒤에 상세로 돌아온다("환불됨" Callout 이 바로 보인다).
  Future<void> _refund() async {
    if (_busy) return;
    setState(() {
      _refunding = true;
      _refundFailed = false;
    });
    try {
      final updated = await expenseActions.refund(
        context,
        ref,
        _e,
        refundedAt: refundedAtIso(_refundDate),
        asset: _assetOf(_e),
        silent: true,
        throwOnError: true,
      );
      if (!mounted) return;
      setState(() {
        if (updated != null) _e = updated;
        _step = _Step.detail;
        _failure = _Failure.none;
      });
    } on ApiException {
      if (mounted) setState(() => _refundFailed = true);
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  /// 환불 취소 — 표식을 걷는다. 이 거래가 합계에 다시 들어간다. 옛 환급 이체가 묶인 거래만 그 이체까지 되돌아간다.
  Future<void> _cancelRefund() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final message = _e.refundTransferRowId != null
        ? l.expRefundCancelConfirm
        : withClosedCycleNote(
            l,
            l.expRefundCancelConfirmPlain,
            closedCycleSpanOfExpense(_e, _assetOf(_e)),
          );
    final ok = await PAlertDialog.show(
      context,
      title: l.expRefundCancel,
      description: message,
      actionLabel: l.expRefundCancel,
      cancelLabel: l.actionCancel,
    );
    if (!ok || !mounted) return;
    setState(() {
      _cancelling = true;
      _failure = _Failure.none;
    });
    try {
      final updated = await expenseActions.cancelRefund(
        ref,
        _e,
        silent: true,
        throwOnError: true,
      );
      if (mounted && updated != null) setState(() => _e = updated);
    } on ApiException {
      if (mounted) setState(() => _failure = _Failure.cancelRefund);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// [수정] — 상세를 내리고 옛 수정 시트를 연다(21-2 가 단계로 옮긴다). 저장하면 응답으로, 저장 없이 닫혀도 상세로 돌아온다.
  void _edit() {
    if (_busy) return;
    final host = widget.host;
    final current = _e;
    PBottomSheet.of(context).close();
    showAddTxSheet(
      host,
      edit: current,
      onSaved: (saved) => showTxDetailDialog(host, saved),
      onCancelled: () => showTxDetailDialog(host, current),
    );
  }

  /// [잔액 고치기] — 이 시트를 닫고 결제계좌의 수정 폼으로 간다(D9).
  void _openFixBalance(int paymentAssetRowId) {
    final host = widget.host;
    PBottomSheet.of(context).close();
    pushAssetEdit(host, paymentAssetRowId);
  }

  /// 21-3 이 단계로 옮길 표면들 — 그때까지 지금처럼 시트를 닫고 옛 표면을 연다.
  void _openLegacy(void Function(BuildContext host) open) {
    final host = widget.host;
    PBottomSheet.of(context).close();
    open(host);
  }

  // ── 그리기 ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isIncome = _e.expenseType == 'INCOME';
    if (_step == _Step.refund) return _buildRefund(l);
    return PBottomSheetContent(
      // 단계마다 다른 시트 내용이다 — 키가 없으면 스크롤 위치가 다음 단계에 따라온다
      key: const ValueKey('tx-detail'),
      title: isIncome ? l.expIncomeDetail : l.expExpenseDetail,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: _buildDetailBody(l),
      footerRow: _footerRow(l),
    );
  }

  /// 바닥 — 자동 거래는 없음 · 환불된 거래는 [삭제] 만 · 그 밖은 [삭제][수정].
  Widget? _footerRow(AppLocalizations l) {
    final auto = _e.autoSource != null;
    if (auto) return null;
    final delete = PButton(
      label: l.actionDelete,
      variant: PButtonVariant.ghost,
      ghostColor: PButtonGhostColor.critical,
      size: PButtonSize.large,
      loading: _deleting,
      onPressed: _busy ? null : _delete,
    );
    if (!expenseActions.canEdit(_e)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [delete],
      );
    }
    return PFormDeleteFooter(
      deleteLabel: l.actionDelete,
      onDelete: _busy ? null : _delete,
      save: PButton(
        label: l.actionEdit,
        size: PButtonSize.large,
        onPressed: _busy ? null : _edit,
      ),
    );
  }

  Widget _buildRefund(AppLocalizations l) {
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(_e.expenseType);
    return PBottomSheetContent(
      key: const ValueKey('tx-detail-refund-step'),
      title: l.expRefundConfirmTitle,
      closeLabel: l.actionClose,
      // 닫기 원은 한 단계가 아니라 시트 전체(← · 뒤로 가기가 한 단계)
      onClose: () => PBottomSheet.of(context).requestClose(wholeSheet: true),
      onBack: _leaveRefund,
      backLabel: l.actionBack,
      flushBody: true,
      scrollFog: true,
      body: RefundStepBody(
        expense: _e,
        asset: _assetOf(_e),
        value: _refundDate,
        masked: masked,
        failureMessage: _refundFailed ? l.expRefundFailed : null,
        onChanged: (d) => setState(() {
          _refundDate = DateTime(d.year, d.month, d.day);
          _refundFailed = false;
        }),
      ),
      footer: [
        PButton(
          label: l.expRefundConfirm,
          size: PButtonSize.large,
          loading: _refunding,
          onPressed: _refunding ? null : _refund,
        ),
      ],
    );
  }

  Widget _buildDetailBody(AppLocalizations l) {
    final c = context.colors;
    final e = _e;
    final isIncome = e.expenseType == 'INCOME';
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(e.expenseType);
    final flags = ref.watch(maskFlagsProvider('ledger.txDetail'));
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);
    final loading =
        (categoriesAsync.isLoading && !categoriesAsync.hasValue) ||
        (assetsAsync.isLoading && !assetsAsync.hasValue);
    final failure = _failure == _Failure.none
        ? const SizedBox.shrink()
        : TxFailureCallout(
            message: _failure == _Failure.delete
                ? l.expTxDeleteFailed
                : l.expRefundCancelFailed,
            onRetry: _busy
                ? null
                : (_failure == _Failure.delete ? _delete : _cancelRefund),
          );
    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [failure, const TxDetailSkeleton()],
      );
    }

    final categories = categoriesAsync.value ?? const <ExpenseCategory>[];
    final assets = assetsAsync.value ?? const <Asset>[];
    final asset = e.assetRowId == null ? null : assets.byRowId(e.assetRowId!);
    final category = e.categoryRowId == null
        ? null
        : categories.byRowId(e.categoryRowId!);

    // 카테고리 색은 다크에서 light variant 로 swap — parseColor(raw) 금지.
    final tileFg = resolveChartColor(
      context,
      category?.color ?? e.categoryColor,
      fallback: c.fgBrand,
    );
    final tileIcon = lucideByName(
      category?.icon ?? e.categoryIcon,
      fallback: LucideIcons.tag,
    );
    final amountText = krwSigned(
      e.amount.abs(),
      masked,
      sign: isIncome ? '+' : kMinus,
      unit: true,
    );
    final displayName = expenseActions.displayNameOf(context, e);

    // 상태 Callout — 결제가 끝난 회차의 카드 거래면 결제계좌 수정 폼으로 가는 [잔액 고치기] 를 단다(D9)
    final fixBalance = fixBalanceTargetOf(e, asset);
    final refundedDay = (e.refundedAt ?? '').length >= 10
        ? DateTime.tryParse(e.refundedAt!.substring(0, 10))
        : null;

    final splitsAsync = ref.watch(expenseSplitsProvider(e.rowId));
    final splits = splitsAsync.value ?? const [];
    final recurring = ref.watch(recurringListProvider).value;
    final dutch = ref.watch(dutchPayListProvider).value;
    final recurringCount = linkedRecurringCount(recurring, e.rowId);
    final dutchCount = linkedDutchPayCount(dutch, e.rowId);
    final auto = e.autoSource != null;

    final moreRows = [
      if (expenseActions.canRefund(e))
        TxMoreRow(
          key: 'refund',
          icon: LucideIcons.undo2,
          label: l.expRefund,
          onTap: _busy ? null : _openRefund,
        ),
      // 분할도 환불된 거래 · 시스템이 만든 거래에는 안 띄운다 — 서버가 막는다(EXP_043)
      if (!e.isRefunded && !auto)
        TxMoreRow(
          key: 'split',
          icon: LucideIcons.scissors,
          label: l.expSplit,
          value: splits.isNotEmpty ? l.expSplitValue(splits.length) : null,
          onTap: _busy
              ? null
              : () => _openLegacy((host) => showSplitTxDialog(host, e)),
        ),
      // 자동으로 만들어진 거래는 반복 · 더치페이의 원본이 될 수 없다 — 숨기지 않고 막힌 줄로(서버도 EXP_050)
      TxMoreRow(
        key: 'recurring',
        icon: LucideIcons.repeat,
        label: l.expConvertRecurring,
        value: recurringCount > 0 ? l.expLinked : null,
        disabled: auto,
        onTap: _busy
            ? null
            : () => _openLegacy(
                (host) => showRecurringSettingsDialog(host, expense: e),
              ),
      ),
      TxMoreRow(
        key: 'dutch',
        icon: LucideIcons.users,
        label: l.dutchTitle,
        value: dutchCount > 0 ? l.expTxCount(dutchCount) : null,
        disabled: auto,
        onTap: _busy
            ? null
            : () => _openLegacy((host) => showDutchPayFromTxDialog(host, e)),
      ),
    ];

    final merchant = (e.merchant ?? '').trim();
    final day = e.expenseDateOnly;
    final dayParsed = day == null ? null : DateTime.tryParse(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        failure,
        TxDetailHead(
          tileBackground: softBg(context, tileFg),
          tileColor: tileFg,
          tileIcon: tileIcon,
          name: displayName,
          amountText: amountText,
          amountColor: isIncome ? c.fgBrand : c.fgNeutral,
          dateTime: txDetailDateTimeLabel(e.expenseDate),
        ),
        if (e.isRefunded)
          TxNoticeCallout(
            icon: LucideIcons.undo2,
            text: l.expRefundedAt(
              refundedDay == null ? '' : monthDay(refundedDay),
            ),
            actions: [
              if (fixBalance != null)
                PButton(
                  label: l.expFixBalance,
                  variant: PButtonVariant.neutralOutline,
                  size: PButtonSize.small,
                  onPressed: _busy ? null : () => _openFixBalance(fixBalance),
                ),
              PButton(
                label: l.expRefundCancel,
                variant: PButtonVariant.neutralOutline,
                size: PButtonSize.small,
                loading: _cancelling,
                onPressed: _busy ? null : _cancelRefund,
              ),
            ],
          ),
        // 기록만 — 결제가 끝난 회차에 뒤늦게 적은 카드 지출. 할부는 지난 회차분만이라 금액이 거래보다 작으면 "이 중 N원" 으로 말한다
        if (e.hasRecordOnlyPart)
          TxNoticeCallout(
            icon: LucideIcons.info,
            text: e.isRecordOnly
                ? l.expRecordOnlyNote
                : l.expRecordOnlyPartNote(
                    krwSigned(e.recordOnlyShare, masked, unit: true),
                  ),
          ),
        // 시스템이 만든 거래 — 왜 못 고치는지 알려 준다. 버튼만 없으면 고장으로 보인다
        if (auto)
          TxNoticeCallout(
            icon: LucideIcons.lock,
            text: switch (e.autoSource) {
              'TRADE_REALIZED' => l.expAutoSourceTradeRealized,
              'TRANSFER_INTEREST' => l.expAutoSourceTransferInterest,
              // 카드 이월 — "원래 거래를 지우면…" 은 틀린 말이다. 원래 거래가 없다
              'CARD_CARRYOVER' ||
              'CARD_CARRYOVER_DUE' => l.expAutoSourceCardCarryover,
              _ => l.expAutoSourceDefault,
            },
          ),
        TxKvList(
          semanticLabel: l.expExpenseDetail,
          rows: [
            TxKvRow(
              label: l.expCategory,
              value: txCategoryLabel(e, categories, l.expUncategorized),
            ),
            if (e.originalCurrency != null && e.originalAmount != null)
              TxKvRow(label: l.expForeignPayment, value: _foreignText(e)),
            TxKvRow(
              label: l.expAccountCard,
              value: txAssetLabel(
                institution: asset?.institution,
                assetName: asset?.assetName,
                fallbackName: e.assetName,
              ),
            ),
            TxKvRow(
              label: l.expPaymentMethod,
              value: txPaymentMethodLabel(l, e.paymentMethod),
            ),
            TxKvRow(label: l.expDescription, value: e.description),
          ],
        ),
        TxMoreSection(rows: moreRows),
        if (splitsAsync.hasError && splits.isEmpty)
          TxSplitFailure(
            onRetry: () => ref.invalidate(expenseSplitsProvider(e.rowId)),
          )
        else if (splitsAsync.isLoading && splits.isEmpty)
          const TxSplitSkeleton()
        else if (splits.isNotEmpty)
          TxSplitSection(
            splits: splits,
            categories: categories,
            total: e.amount.abs(),
            isIncome: isIncome,
            masked: masked,
          ),
        if (merchant.isNotEmpty && dayParsed != null)
          _HistoryHost(
            expense: e,
            merchant: merchant,
            year: dayParsed.year,
            month: dayParsed.month,
            categories: categories,
            flags: flags,
            masked: masked,
          ),
      ],
    );
  }

  String _foreignText(Expense e) {
    final locale = Localizations.localeOf(context).toString();
    final base = formatOriginalAmount(
      e.originalAmount!,
      e.originalCurrency!,
      locale,
    );
    return e.exchangeRate != null
        ? '$base × ${txTrimRate(e.exchangeRate!)}'
        : base;
  }
}

/// "이 가맹점 이번 달" — 같은 가맹점 · 같은 달 거래를 받아 와 묶음을 그린다. 이 거래만 있으면 묶음이 없다.
class _HistoryHost extends ConsumerWidget {
  const _HistoryHost({
    required this.expense,
    required this.merchant,
    required this.year,
    required this.month,
    required this.categories,
    required this.flags,
    required this.masked,
  });

  final Expense expense;
  final String merchant;
  final int year;
  final int month;
  final List<ExpenseCategory> categories;
  final MaskFlags flags;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all =
        ref
            .watch(
              merchantMonthExpensesProvider((
                merchant: merchant,
                year: year,
                month: month,
              )),
            )
            .value ??
        const <Expense>[];
    final history = txHistoryOf(all, expense.rowId);
    if (history.rows.isEmpty) return const SizedBox.shrink();
    return TxHistorySection(
      history: history,
      categories: categories,
      flags: flags,
      isIncome: expense.expenseType == 'INCOME',
      masked: masked,
    );
  }
}
