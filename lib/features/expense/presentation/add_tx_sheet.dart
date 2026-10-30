import 'package:flutter/material.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/widgets/p_badge.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_category_tile.dart';
import 'package:groo_damda_app/shared/widgets/p_checkbox.dart';
import 'package:groo_damda_app/shared/widgets/p_date_input.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_progress.dart';
import 'package:groo_damda_app/shared/widgets/p_section_label.dart';
import 'package:groo_damda_app/shared/widgets/p_switch.dart';
import 'package:groo_damda_app/shared/widgets/p_select.dart';
import 'package:groo_damda_app/shared/widgets/p_tabs.dart';
import 'package:groo_damda_app/shared/widgets/p_text_input.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/asset/presentation/transfer_account_fields.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_pick_sheet.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/expense_split/presentation/split_tx_dialog.dart';
import 'package:groo_damda_app/features/sms/data/sms_android.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';

String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 거래 추가/편집 시트 (front `AddTxSheet` 미러).
///
/// [edit] 가 주어지면 편집 모드 (PUT /expense/{id}), 아니면 신규 (POST /expense).
/// 성공 시 해당 월 expensesProvider invalidate.
void showAddTxSheet(
  BuildContext context, {
  String? defaultDate,
  Expense? edit,

  /// 이체 편집 모드 — 서버가 이자 지출·잔액 이력을 되돌렸다 다시 만든다(rowId 유지).
  AssetTransfer? editTransfer,

  /// 결제 문자 초안 — 파싱 결과로 폼을 채우고, 저장은 문자 전용 경로로 보낸다
  /// (카드 연결 기억·취소 문자 차단이 그 경로에 있다).
  SmsDraft? smsDraft,

  /// 고쳐 쓰기(D13) — 결제가 끝나 돈 칸이 잠긴 거래. 그 값이 전부 채워진 **새 거래**
  /// 시트로 열고, 저장은 `POST /expense/{id}/replace` 로 보낸다(옛 거래 삭제 + 새 거래
  /// 생성 + 분할·연결 이전이 서버 한 트랜잭션). 문자 초안과 같은 자리의 시드다.
  Expense? replaceOf,
}) {
  final controller = PSheetController();
  final l = AppLocalizations.of(context);
  final isEdit = edit != null || editTransfer != null;
  final isReplace = replaceOf != null && !isEdit;
  showPSheet<void>(
    context,
    title: isReplace ? l.expRewrite : (isEdit ? l.expEdit : l.expAdd),
    contentBuilder: (ctx, scrollCtrl) => _AddTxBody(
      defaultDate: defaultDate,
      edit: edit,
      editTransfer: editTransfer,
      smsDraft: smsDraft,
      replaceOf: isReplace ? replaceOf : null,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: isEdit || isReplace ? l.actionSave : l.expAddShort,
    ),
  ).whenComplete(controller.dispose);
}

class _AddTxBody extends ConsumerStatefulWidget {
  const _AddTxBody({
    this.defaultDate,
    this.edit,
    this.editTransfer,
    this.smsDraft,
    this.replaceOf,
    required this.scrollController,
    required this.controller,
  });
  final String? defaultDate;
  final Expense? edit;
  final AssetTransfer? editTransfer;
  final SmsDraft? smsDraft;
  final Expense? replaceOf;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_AddTxBody> createState() => _AddTxBodyState();
}

class _AddTxBodyState extends ConsumerState<_AddTxBody> {
  late final _TxInputController _input;
  bool _submitting = false;

  /// 프리셋을 통해 폼이 초기화된 경우 해당 프리셋 ID — 저장 성공 후 /touch.
  int? _appliedPresetId;

  // 편집 모드 분할 일치화: 서버 분할(build 에서 적재) + 이번 세션에서 맞춘 분할.
  List<SplitInput> _serverSplits = const [];

  /// 고쳐 쓰기 시트가 원거래의 분할을 아직 불러오는 중인가 — 그동안 저장을 막는다.
  bool _splitsPending = false;
  List<SplitInput>? _reconciledSplits;
  List<SplitInput> get _effectiveSplits => _reconciledSplits ?? _serverSplits;
  int get _splitSum => _effectiveSplits.fold<int>(0, (s, x) => s + x.amount);
  // 금액을 바꿔 분할 합과 어긋남(편집·고쳐 쓰기, 지출/수입만). 이때 저장을 막고
  // 일치화 유도 — 고쳐 쓰기도 서버가 분할 합을 새 금액과 견줘 400 을 낸다.
  bool get _splitMismatch =>
      _splitSource != null &&
      _input.type != 'TRANSFER' &&
      _input.amountInt > 0 &&
      _effectiveSplits.isNotEmpty &&
      _input.amountInt != _splitSum;

  /// 분할을 적재할 원거래 — 지출·수입 편집이나 고쳐 쓰기의 옛 거래. 이체는 분할이 없다.
  Expense? get _splitSource => widget.edit ?? widget.replaceOf;

  /// 고쳐 쓰기 시트인가(D13) — 새 거래 모드로 열리고 저장은 replace API 다.
  bool get _isReplace => widget.replaceOf != null;

  /// 편집 모드인가 — **지출·수입 편집과 이체 수정 둘 다** 여기 든다.
  ///
  /// 그래서 이 값으로 `widget.edit!` 를 감싸면 안 된다. 이체 수정은 `editTransfer` 로
  /// 오고 `edit` 은 **null** 이라 그 자리에서 죽는다. 릴리스 빌드의 기본 `ErrorWidget` 은
  /// 아무 글자 없는 회색 사각형이라, 본문이 통째로 회색으로 나오고 무슨 일이 난 건지도
  /// 안 보였다(2026-09-18). 지출·수입만 뜻할 때는 `widget.edit != null` 을 직접 본다.
  bool get _isEdit => widget.edit != null || widget.editTransfer != null;

  /// 결제 문자에서 온 초안인가 — 저장이 `/import/sms/commit` 으로 간다.
  bool get _isSmsDraft => widget.smsDraft != null;

  /// 종류 토글을 잠그는가 — 편집뿐이다.
  ///
  /// 결제 문자 초안도 한동안 잠겨 있었다(#326). 저장 경로인 `/import/sms/commit` 이
  /// `expenseType` 을 안 받고 서버가 `EXPENSE` 를 박아 넣어서, 수입으로 바꿔 저장해도
  /// 지출로 남았기 때문이다 — 화면만 수입이라 말하느니 못 고르게 두는 게 나았다.
  /// **서버가 이제 그 값을 받으므로**(desk-back #326) 잠금을 푼다. 환불·입금 문자를
  /// 수입으로 남길 수 있어야 그 달 지출이 부풀지 않는다.
  bool get _typeLocked => _isEdit;

  @override
  void initState() {
    super.initState();
    // 고쳐 쓰기는 편집과 같은 값으로 채운다 — 원거래의 모든 칸이 시드다(D13).
    final e = widget.edit ?? widget.replaceOf;
    DateTime date;
    TimeOfDay time = TimeOfDay.now();
    final tr = widget.editTransfer;
    if (tr?.transferDate != null) {
      date = parseIsoDate(tr!.transferDate!.substring(0, 10));
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(tr.transferDate!);
      if (m != null) {
        time = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
      }
    } else if (e?.expenseDate != null) {
      date = parseIsoDate(e!.expenseDate!.substring(0, 10));
      // 시간 추출 (T 또는 공백 뒤 HH:mm)
      final raw = e.expenseDate!;
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(raw);
      if (m != null) {
        time = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
      }
    } else if (widget.smsDraft?.parsed.expenseDate != null) {
      final raw = widget.smsDraft!.parsed.expenseDate!;
      date = parseIsoDate(raw.substring(0, 10));
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(raw);
      if (m != null) {
        time = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
      }
    } else if (widget.defaultDate != null) {
      date = parseIsoDate(widget.defaultDate!);
    } else {
      date = DateTime.now();
    }
    // 결제 문자 초안 — 카드 결제라 유형·결제수단은 고정이고, 나머지는 파싱 값을 채운다.
    final sms = widget.smsDraft?.parsed;
    _input = _TxInputController(
      type: tr != null ? 'TRANSFER' : (e?.expenseType ?? 'EXPENSE'),
      amount: tr != null
          ? tr.amount.toString()
          : e != null
          ? e.amount.toString()
          : (sms?.amount?.toString() ?? ''),
      memo: tr?.description ?? e?.description ?? '',
      merchant: e?.merchant ?? sms?.merchant ?? '',
      paymentMethod: e?.paymentMethod ?? (sms != null ? 'CARD' : ''),
      categoryRowId: e?.categoryRowId ?? sms?.categoryRowId,
      // 이체는 출금 자산이 assetRowId, 입금 자산이 toAssetRowId 다.
      assetRowId: tr?.fromAssetRowId ?? e?.assetRowId ?? sms?.assetRowId,
      date: date,
      time: time,
    );
    if (tr != null) {
      _input.toAssetRowId = tr.toAssetRowId;
      if ((tr.fee ?? 0) > 0) _input.feeCtrl.text = tr.fee.toString();
      if ((tr.interestAmount ?? 0) > 0) {
        _input.interestCtrl.text = tr.interestAmount.toString();
      }
    }
    // 편집은 그 거래의 통화를 승계한다 — 해외 결제를 고치는데 원화로 되돌아가면
    // 원 통화 기록이 조용히 지워진다.
    final src = e;
    if (src != null) {
      // 원화 거래는 `originalCurrency` 가 `null` 로 온다 — 그때도 원화라고 못
      // 박는다. 안 박으면 설정의 기본 통화가 흘러들어, 원화로 적어 둔 거래를
      // 열기만 해도 해외 결제 입력이 펼쳐진다(D7).
      _input.txCurrency = src.originalCurrency ?? kDefaultCurrency;
      if (src.originalCurrency != null) {
        _input.origAmountCtrl.text = _trimNum(src.originalAmount);
        _input.fxRateCtrl.text = _trimNum(src.exchangeRate);
      }
    }
    if (e?.installmentMonths != null) {
      _input.installmentMonths = e!.installmentMonths!;
    } else if (sms?.installmentMonths != null) {
      _input.installmentMonths = sms!.installmentMonths!;
    }
    if (sms != null) {
      // 문자에 외화가 안 실렸으면 원화 결제다 — 설정의 기본 통화가 외화여도
      // 여기선 문자가 맞다. 안 막으면 원화 결제 문자가 해외 결제 입력으로 열린다.
      _input.txCurrency = sms.originalCurrency ?? kDefaultCurrency;
      if (sms.originalCurrency != null) {
        _input.origAmountCtrl.text = _trimNum(sms.originalAmount?.toDouble());
      }
    }
    // 카드를 알아봤는데 아직 안 외운 경우에만 "이 카드로 기억" 을 물어본다.
    _input.smsRememberAsk = widget.smsDraft?.canRememberCard ?? false;
    _input.autoSource = e?.autoSource;
    _input.isFixed = e?.isFixed ?? false;
    widget.controller.onSubmit = _submit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
  }

  void _syncController() {
    widget.controller.setCanSubmit(_canSubmit);
    widget.controller.setSubmitting(_submitting);
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _applyPreset(ExpenseTemplate p) {
    final locked = (p.lockAmount ?? 'N') == 'Y';
    setState(() {
      _appliedPresetId = p.rowId;
      _input.type = p.expenseType;
      // 웹과 동일: lockAmount === 'Y' 일 때만 금액 채움, 아니면 비워둠
      _input.amountCtrl.text = locked ? (p.amount ?? 0).toString() : '';
      _input.categoryRowId = p.categoryRowId;
      _input.assetRowId = p.assetRowId;
      _input.memoCtrl.text = p.description ?? '';
      _input.merchantCtrl.text = p.merchant ?? '';
      _input.paymentMethod = p.paymentMethod ?? '';
      // 이체 프리셋은 받는 계좌·수수료·이자를 함께 들고 온다. 보내는 계좌는
      // assetRowId 한 칸을 지출·수입과 같이 쓴다(서버도 같은 컬럼이다).
      _input.toAssetRowId = p.toAssetRowId;
      _input.feeCtrl.text = p.fee != null ? '${p.fee}' : '';
      _input.interestCtrl.text = p.interestAmount != null
          ? '${p.interestAmount}'
          : '';
      _input.amountLocked = locked;
      // 프리셋의 고정 표식이 기본값이 된다 — 월세 프리셋을 불러오면 고정으로 켜져 있다. 이체는 해당 없음.
      _input.isFixed = p.expenseType == 'TRANSFER' ? false : p.isFixed;
    });
  }

  /// "모두 보기"(I-20 C 20) — 지금 종류의 프리셋 모두를 고르는 시트. 고르면 [_applyPreset] 으로 채운다.
  /// 칩은 8개까지라 아홉 번째부터는 여기서만 쓸 수 있다.
  Future<void> _showAllPresets() async {
    final type = _input.type;
    final categoriesAsync = ref.read(categoriesProvider);
    final mine = [
      for (final p
          in ref.read(presetListProvider).value ?? const <ExpenseTemplate>[])
        if (p.expenseType == type) p,
    ];
    final picked = await showPresetPickSheet(
      context,
      presets: mine,
      categories: categoriesAsync.value ?? const [],
      categoriesFailed:
          !categoriesAsync.hasValue &&
          categoriesAsync.hasError &&
          !categoriesAsync.isLoading,
      onRetry: () => ref.invalidate(categoriesProvider),
    );
    if (picked == null || !mounted) return;
    _applyPreset(picked);
  }

  void _clearPresetMark() {
    if (_appliedPresetId == null) return;
    setState(() => _appliedPresetId = null);
  }

  /// 프리셋으로 저장할 수 있는가 — 종류마다 있어야 하는 칸이 다르다.
  /// 지출·수입은 카테고리가, 이체는 양쪽 계좌가 프리셋의 뼈대다.
  bool get _canSavePreset {
    if (_input.amountInt <= 0) return false;
    return _input.type == 'TRANSFER'
        ? transferPartiesReady(_input.assetRowId, _input.toAssetRowId)
        : _input.categoryRowId != null;
  }

  /// 프리셋으로 채운 뒤 저장한 경우 useCount/lastUsedAt 갱신.
  ///
  /// 지출·수입과 이체가 같이 쓴다 — 저장 경로가 갈려도 사용 기록 규칙은 하나다.
  Future<void> _touchAppliedPreset() async {
    if (_isEdit || _appliedPresetId == null) return;
    try {
      final pRepo = await ref.read(presetRepositoryProvider.future);
      await pRepo.touch(_appliedPresetId!);
      ref.invalidate(presetListProvider);
    } catch (_) {
      /* touch 실패는 본 거래 저장에 영향 없음 */
    }
  }

  Future<void> _showSavePresetDialog() async {
    if (!_canSavePreset) return;
    final isTransfer = _input.type == 'TRANSFER';
    await showDialog<void>(
      context: context,
      builder: (_) => _SavePresetDialog(
        seedExpenseType: _input.type,
        seedAmount: _input.amountInt,
        seedCategoryRowId: isTransfer ? null : _input.categoryRowId,
        seedAssetRowId: _input.assetRowId,
        seedToAssetRowId: isTransfer ? _input.toAssetRowId : null,
        seedFee: isTransfer ? _input.feeOrNull : null,
        seedInterest: isTransfer ? _input.interestOrNull : null,
        seedMerchant: isTransfer ? '' : _input.merchantCtrl.text.trim(),
        seedDescription: _input.memoCtrl.text.trim(),
        seedPaymentMethod: isTransfer ? '' : _input.paymentMethod,
        seedIsFixed: !isTransfer && _input.isFixed,
      ),
    );
  }

  bool get _canSubmit {
    final amount = _input.amountInt;
    if (_submitting || amount <= 0) return false;
    if (_input.type == 'TRANSFER') {
      return _input.assetRowId != null &&
          _input.toAssetRowId != null &&
          _input.assetRowId != _input.toAssetRowId;
    }
    // 자산은 선택사항 — 자산까지 관리하지 않고 가계부로만 쓰는 사용법을 막지 않는다(웹 정합).
    if (_input.categoryRowId == null) return false;
    // 분할 합 불일치 시 저장 보류 — 배너의 '분할 내역 맞추기'로 먼저 일치화.
    if (_splitMismatch) return false;
    // 고쳐 쓰기는 분할을 본문에 싣는다 — 다 불러오기 전이면 빈 채로 나간다.
    if (_splitsPending) return false;
    return true;
  }

  Future<void> _submit() async {
    final amount = _input.amountInt;
    final isoDate = _input.isoDate;
    final dateStr = '${isoDate}T${_formatTime(_input.time)}:00';
    final desc = _input.memoOrNull;
    final merchant = _input.merchantOrNull;
    final payment = _input.paymentMethodOrNull;
    // 할부는 신용카드 지출에만 — 그 밖의 조합에선 값을 흘리지 않는다.
    final installment = _input.installmentMonths > 1
        ? _input.installmentMonths
        : null;
    // 원 통화는 셋이 함께여야 의미가 있다 — 서버도 반쪽이면 전부 비운다.
    final origAmount = _input.origAmountOrNull;
    final origCurrency = origAmount != null ? _input.currency : null;
    final fxRate = origAmount != null ? _input.fxRateOrNull : null;
    final d = _input.date;

    if (_input.type == 'TRANSFER') {
      _setSubmitting(true);
      try {
        final fee = int.tryParse(_input.feeCtrl.text.replaceAll(',', ''));
        // 이자는 대출 상환에만 — 그 밖의 이체엔 값을 흘리지 않는다.
        final interest = _showInterest(_input, ref.read(assetsProvider).value)
            ? int.tryParse(_input.interestCtrl.text.replaceAll(',', ''))
            : null;
        final aRepo = await ref.read(assetRepositoryProvider.future);
        final editing = widget.editTransfer;
        if (editing != null) {
          await aRepo.updateTransfer(
            rowId: editing.rowId,
            fromAssetRowId: _input.assetRowId!,
            toAssetRowId: _input.toAssetRowId!,
            amount: amount,
            fee: fee,
            interestAmount: interest,
            description: desc,
            transferDate: dateStr,
          );
        } else {
          await aRepo.createTransfer(
            fromAssetRowId: _input.assetRowId!,
            toAssetRowId: _input.toAssetRowId!,
            amount: amount,
            fee: fee,
            interestAmount: interest,
            description: desc,
            transferDate: dateStr,
          );
        }
        ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
        invalidateAfterExpenseChange(ref);
        // 이체도 프리셋으로 채웠으면 사용 기록을 올린다 — 지출·수입(아래 공통 꼬리)과
        // 같은 규칙. 이 분기가 여기서 return 해 그 꼬리에 못 닿는 바람에, 목록이
        // "사용 많은 순" 정렬인데 이체 프리셋만 영영 0 이었다(#174).
        // 시트를 닫기 전에 부른다 — 닫고 나면 이 State 가 사라진다.
        await _touchAppliedPreset();
        if (!mounted) return;
        Navigator.of(context).pop();
      } on ApiException {
        if (!mounted) return;
      } finally {
        if (mounted) _setSubmitting(false);
      }
      return;
    }

    // 고쳐 쓰기는 따로 묻고 따로 보낸다(D13) — 옛 거래를 지우고 새 거래를 만든다.
    if (_isReplace) {
      await _submitReplace(
        amount: amount,
        dateStr: dateStr,
        desc: desc,
        merchant: merchant,
        payment: payment,
        installment: installment,
        origAmount: origAmount,
        origCurrency: origCurrency,
        fxRate: fxRate,
      );
      return;
    }

    // 결제가 끝난 회차로 가는 저장이면 먼저 한 번 묻는다 — 기록만 바뀌고 계좌 잔액은
    // 그대로다(D1). 서버에 묻지 않는다 — 판정은 카드의 cardClosedThrough 하나다.
    // 물러나면 아무것도 보내지 않는다.
    if (!await _confirmClosedCycleSave(installment: installment)) return;
    if (!mounted) return;

    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final edited = widget.edit;
      if (edited != null) {
        // 이 시트가 소유한 칸은 비운 상태 그대로 실어야 지워진다 — 키를 빼면
        // 서버가 옛 값을 지킨다(QA #99). 환불 표식은 이 시트의 칸이 아니다 —
        // 전용 경로(`POST/DELETE /expense/{id}/refund`)만 건드린다.
        //
        // 돈 칸이 잠긴 거래(D12)는 카테고리·가맹점·메모만 고친다. 돈 칸은 **원래 값
        // 그대로** 돌려보낸다 — 폼을 거치며 초·환율 소수점이 깎이면 서버가 "바뀌었다"
        // 고 보고 거절한다(EXP_045). 지울 수 있는 돈 칸은 키째 빼서 서버가 지키게 한다.
        final locked = _input.moneyLocked;
        final saved = await repo.update(
          id: edited.rowId,
          categoryRowId: _input.categoryRowId!,
          assetRowId: locked
              ? const Patch.keep()
              : Patch.set(_input.assetRowId),
          expenseType: locked ? edited.expenseType : _input.type,
          amount: locked ? edited.amount : amount,
          expenseDate: locked ? (edited.expenseDate ?? dateStr) : dateStr,
          description: Patch.set(desc),
          merchant: Patch.set(merchant),
          paymentMethod: locked ? const Patch.keep() : Patch.set(payment),
          installmentMonths: locked
              ? const Patch.keep()
              : Patch.set(installment),
          originalAmount: locked ? const Patch.keep() : Patch.set(origAmount),
          originalCurrency: locked
              ? const Patch.keep()
              : Patch.set(origCurrency),
          exchangeRate: locked ? const Patch.keep() : Patch.set(fxRate),
          // 고정 표식은 돈이 아니라 분류라서 잠긴 거래도 고칠 수 있다 — 늘 싣는다.
          isFixed: Patch.set(_input.isFixed),
          // 일치화한 분할이 있으면 금액과 함께 원자적으로 교체(백엔드가 합==금액 검증).
          // 잠긴 거래는 금액이 안 바뀌니 맞출 분할도 없다.
          splits: locked ? null : _reconciledSplits,
        );
        // 열린 회차에서 미리 낸 돈이 남아 계좌로 돌아갔으면 사후에 알린다(D4).
        if (mounted) {
          showChangeResultToast(
            hostContextOf(context),
            refundedAmount: saved.refundedAmount,
          );
        }
        // 분할이 교체됐을 수 있으니 분할 쿼리도 무효화.
        ref.invalidate(expenseSplitsProvider(edited.rowId));
      } else if (widget.smsDraft != null) {
        // 결제 문자는 전용 경로로 저장한다 — 서버가 원문을 다시 봐 취소 문자를 막고,
        // 체크했다면 (카드 힌트 → 자산) 을 기억한다. 저장 자체는 같은 지출 생성이다.
        final smsRepo = await ref.read(smsRepositoryProvider.future);
        final committed = await smsRepo.commit(
          text: widget.smsDraft!.text,
          assetRowId: _input.assetRowId,
          categoryRowId: _input.categoryRowId,
          // 종류를 안 실으면 서버가 지출로 본다 — 환불 문자를 수입으로 골라도
          // 지출로 남아 그 달 지출이 부푼다(desk-back #326).
          expenseType: _input.type,
          amount: amount,
          merchant: merchant,
          description: desc,
          expenseDate: dateStr,
          paymentMethod: payment,
          installmentMonths: installment,
          originalAmount: origAmount,
          originalCurrency: origCurrency,
          exchangeRate: fxRate,
          rememberCard: _input.assetRowId != null && _input.smsRememberCard,
        );
        _notifyCreated(refundedAmount: committed.refundedAmount);
        // 수신 보관함에서 온 문자면 기록됐으니 목록에서 뺀다.
        // 실패해도 본 저장에는 영향이 없다 — 목록에 한 줄 남을 뿐이다.
        final inboxId = widget.smsDraft!.inboxId;
        if (inboxId != null) {
          try {
            await SmsAndroid.removeFromInbox(inboxId);
          } catch (_) {
            /* 보관함 정리 실패는 저장 결과를 바꾸지 않는다 */
          }
        }
      } else {
        final created = await repo.create(
          categoryRowId: _input.categoryRowId!,
          assetRowId: _input.assetRowId,
          expenseType: _input.type,
          amount: amount,
          expenseDate: dateStr,
          description: desc,
          merchant: merchant,
          paymentMethod: payment,
          installmentMonths: installment,
          originalAmount: origAmount,
          originalCurrency: origCurrency,
          exchangeRate: fxRate,
          isFixed: _input.isFixed,
        );
        _notifyCreated(refundedAmount: created.refundedAmount);
      }
      await _touchAppliedPreset();
      // 원래 거래의 월 + 새 월 모두 invalidate (날짜 변경 가능성)
      if (edited?.expenseDate != null) {
        final orig = parseIsoDate(edited!.expenseDate!.substring(0, 10));
        if (orig.year != d.year || orig.month != d.month) {
          ref.invalidate(
            monthExpensesProvider((year: orig.year, month: orig.month)),
          );
        }
      }
      ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
      invalidateAfterExpenseChange(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  /// 새 거래를 저장한 뒤의 결과 토스트 — 웹 `notifyResult(created)` 와 같다.
  ///
  /// 생성 응답에도 선결제 환급액이 실린다 — 열린 회차에 카드 수입을 넣어 미리 낸 돈이
  /// 청구보다 많아지면 서버가 그만큼 결제계좌로 돌려준다(D3). 통장이 움직였으니 그 금액만
  /// 알린다(D4, QA 26 1). 닫힌 회차 새 입력의 [잔액 고치기](D9)는 달지 않는다 — D9 는 환불·
  /// 삭제·고쳐 쓰기의 자리이고, 새 입력은 저장 전 확인창이 이미 "기록만" 을 말했다.
  ///
  /// 시트는 곧 닫힌다 — 토스트는 루트 쪽 context 에 띄워 페이지에 남긴다.
  void _notifyCreated({required int? refundedAmount}) {
    if (!mounted) return;
    showChangeResultToast(
      hostContextOf(context),
      refundedAmount: refundedAmount,
      fixBalanceAssetId: null,
    );
  }

  /// 고쳐 쓰기 저장(D13) — 확인받고 `POST /expense/{id}/replace` 로 보낸다.
  ///
  /// 옛 거래는 이미 결제가 끝난 회차다. 새 거래가 닫힌 회차에 떨어지면 기록만 바뀌고,
  /// 열린 회차면 그 회차 결제일에 정상 청구된다(D14 — 재청구 방지 표식은 없다). 어느
  /// 쪽인지 확인창이 말한다. 성공하면 결제계좌가 있는 카드에 [잔액 고치기] 토스트(D9),
  /// 미리 낸 돈이 돌아왔으면 그 금액(D4).
  Future<void> _submitReplace({
    required int amount,
    required String dateStr,
    String? desc,
    String? merchant,
    String? payment,
    int? installment,
    double? origAmount,
    String? origCurrency,
    double? fxRate,
  }) async {
    final original = widget.replaceOf!;
    final l = AppLocalizations.of(context);
    final assets = ref.read(assetsProvider).value ?? const <Asset>[];
    Asset? assetOf(int? id) => id == null ? null : assets.byRowId(id);
    final ok = await PAlertDialog.show(
      context,
      title: l.expRewrite,
      description: rewriteConfirmMessage(
        l,
        newAsset: assetOf(_input.assetRowId),
        dateKey: _input.isoDate,
        installmentMonths: installment,
      ),
      actionLabel: l.actionSave,
      cancelLabel: l.actionCancel,
    );
    if (!ok || !mounted) return;
    // 시트가 닫혀도 토스트·[잔액 고치기] 는 남는다 — 오래 사는 자리를 먼저 짚는다.
    final host = hostContextOf(context);
    final fixBalance = fixBalanceTargetOf(
      original,
      assetOf(original.assetRowId),
    );

    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      // 분할은 시트가 적재·일치화한 값을 싣는다. 비었거나 아직 못 읽었으면 키를
      // 빼고 서버가 옛 분할을 옮긴다 — 빈 리스트를 실으면 분할이 지워진다.
      final splits = _effectiveSplits.isEmpty ? null : _effectiveSplits;
      final saved = await repo.replace(
        original.rowId,
        categoryRowId: _input.categoryRowId!,
        assetRowId: _input.assetRowId,
        expenseType: _input.type,
        amount: amount,
        expenseDate: dateStr,
        description: desc,
        merchant: merchant,
        paymentMethod: payment,
        installmentMonths: installment,
        originalAmount: origAmount,
        originalCurrency: origCurrency,
        exchangeRate: fxRate,
        isFixed: _input.isFixed,
        splits: splits,
      );
      // 옛 거래의 달·새 거래의 달이 함께 바뀐다. 분할도 옛 거래에서 새 거래로 옮겨졌다.
      final origDate = original.expenseDate;
      if (origDate != null && origDate.length >= 10) {
        final o = parseIsoDate(origDate.substring(0, 10));
        ref.invalidate(monthExpensesProvider((year: o.year, month: o.month)));
      }
      final d = _input.date;
      ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
      ref.invalidate(expenseSplitsProvider(original.rowId));
      ref.invalidate(expenseSplitsProvider(saved.rowId));
      invalidateAfterExpenseChange(ref);
      if (mounted) Navigator.of(context).pop();
      if (host.mounted) {
        showChangeResultToast(
          host,
          refundedAmount: saved.refundedAmount,
          fixBalanceAssetId: fixBalance,
        );
      }
    } on ApiException catch (e) {
      // 서버 메시지는 전역 인터셉터가 띄운다.
      //
      // 404 = 옛 거래가 이미 없다 — 응답만 못 받은 채 다시 눌렀으면 교체는 앞선 요청에서
      // 끝났다(다른 기기에서 지웠어도 같다). 붙들고 있으면 사라진 거래를 또 고치려 들고
      // 목록엔 옛 행이 남아 보인다 — 가계부·자산을 다시 읽게 하고 시트를 닫는다(QA 26 5).
      // 새 거래가 어느 달에 생겼는지 모르므로 달을 가리지 않는다.
      //
      // 그 밖의 실패(잠기지 않은 거래·중도 정리한 할부 등)는 시트를 둔다 — 고친 값을
      // 잃지 않고 다시 시도할 수 있다.
      if (e.statusCode == 404) {
        ref.invalidate(monthExpensesProvider);
        ref.invalidate(expenseSplitsProvider(original.rowId));
        invalidateAfterExpenseChange(ref);
        if (mounted) Navigator.of(context).pop();
      }
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  /// [고쳐 쓰기] — 이 편집 시트를 닫고 같은 값이 채워진 새 거래 시트를 연다(D13).
  void _openRewrite() {
    final e = widget.edit;
    if (e == null) return;
    final host = hostContextOf(context);
    Navigator.of(context).pop();
    showAddTxSheet(host, replaceOf: e);
  }

  /// 결제가 끝난 회차에 걸리는 카드 거래면 저장 전에 한 번 묻는다(D1·D2).
  ///
  /// 저장될 날짜·카드·할부가 그 카드의 `cardClosedThrough` 이하면 "이미 결제가 끝난
  /// 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요", 할부가 걸치면 "지난 회차분은
  /// 기록만 남아요". **서버에 묻지 않는다** — 예전의 저장 미리보기(3초 제한·실패
  /// 폴백)는 걷었다.
  ///
  /// 확인창은 **돈과 기록이 갈리는 자리에만** 둔다(사용자 결정 2026-09-21).
  ///   - 새 저장(문자 저장 포함) — 닫힌 회차로 들어가면 묻는다
  ///   - 편집 저장 — 원래 거래가 **안 잠겼고** 새 날짜·새 카드가 닫힌 회차에 들면 묻는다
  ///     (열린 회차 거래를 닫힌 회차로 옮기는 저장)
  ///   - 잠긴 거래(D12)의 편집 저장 — 묻지 않는다. 돈 칸이 잠겨 카테고리·가맹점·메모만
  ///     바뀌고, 돈 칸은 원래 값 그대로 나간다 — 통장에 일어나는 일이 없다
  ///
  /// 열린 회차는 묻지 않는다 — 평소대로 청구될 뿐이다. 돌려주는 값이 false 면 사용자가
  /// 물러난 것이다.
  Future<bool> _confirmClosedCycleSave({int? installment}) async {
    if (_input.type == 'TRANSFER') return true;
    if (widget.edit != null && _input.moneyLocked) return true;
    final id = _input.assetRowId;
    if (id == null) return true;
    final asset = (ref.read(assetsProvider).value ?? const <Asset>[]).byRowId(
      id,
    );
    final l = AppLocalizations.of(context);
    final note = closedCycleNote(
      l,
      closedCycleSpanFor(
        asset,
        dateKey: _input.isoDate,
        installmentMonths: installment,
      ),
    );
    if (note == null) return true;
    return PAlertDialog.show(
      context,
      title: widget.edit != null ? l.expEdit : l.expSaveConfirmTitle,
      description: note,
      actionLabel: l.actionSave,
      cancelLabel: l.actionCancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 설정의 기본 통화를 매 빌드 흘려 넣는다(D7 · QA #124) — `/me/preferences` 는
    // 이 시트보다 늦게 도착할 수 있고, 열 때 한 번만 읽으면 첫 렌더의 원화에
    // 잠긴다. 아직 안 고른 **새 거래**에만 닿는다(`_TxInputController.currency`).
    _input.defaultCurrency = ref.watch(defaultCurrencyProvider);
    // 고쳐 쓰기는 원거래 값으로 채운 시트다 — 프리셋이 그 값을 덮어쓰면 안 된다.
    final presetsAsync = _isEdit || _isReplace
        ? const AsyncValue<List<ExpenseTemplate>>.data(<ExpenseTemplate>[])
        : ref.watch(presetListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    // 돈 칸 잠금(D12) — 지출·수입 편집에서만. 서버 플래그가 먼저고, 카드의 닫힌 회차
    // 경계로 한 번 더 본다(`moneyLockedOf`).
    final editedForLock = widget.edit;
    final lockAssetId = editedForLock?.assetRowId;
    _input.moneyLocked =
        editedForLock != null &&
        moneyLockedOf(
          editedForLock,
          lockAssetId == null
              ? null
              : ref.watch(assetsProvider).value?.byRowId(lockAssetId),
        );

    // 지출·수입 편집·고쳐 쓰기: 기존 분할을 적재해 금액↔분할 합 불일치 판정(일치화
    // 유도). 이체에는 분할이 없다 — `_isEdit` 로 묶으면 이체 수정에서 `edit` 이 null
    // 이라 죽는다.
    final editedExpense = _splitSource;
    if (editedExpense != null) {
      final spAsync = ref.watch(expenseSplitsProvider(editedExpense.rowId));
      final sp = spAsync.value;
      // 고쳐 쓰기는 이 분할을 새 거래의 분할로 싣는다. 다 불러오기 전에 저장하면 분할 없이
      // 나가 서버가 옛 분할을 옮기고, 금액을 바꿨다면 합이 안 맞아 400 이다 — 처음 불러오는
      // 동안 저장을 막는다. 한 번이라도 실패했으면 막지 않는다(뒤에서 다시 시도하는 동안
      // 저장을 붙잡아 두지 않는다) — 그때는 서버가 옛 분할로 판정한다.
      _splitsPending =
          _isReplace &&
          spAsync.isLoading &&
          !spAsync.hasValue &&
          !spAsync.hasError;
      _serverSplits = sp == null
          ? const []
          : [
              for (final s in sp)
                SplitInput(
                  categoryRowId: s.categoryRowId,
                  amount: s.amount,
                  label: s.label,
                  sortOrder: s.sortOrder,
                ),
            ];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        _TxInputForm(
          controller: _input,
          onChanged: () => setState(_syncController),
          typeReadOnly: _typeLocked,
          typeDisabledFor: _typeLocked ? _input.type : null,
          // 문자 초안은 지출↔수입만 오간다. 이체를 고르면 저장이 일반 이체 경로로
          // 새고(`_submit` 의 TRANSFER 분기가 먼저다) 취소 문자 차단·카드 기억이
          // 조용히 빠진다 — 그 경로에만 있는 가드다. 고쳐 쓰기도 같다 — replace
          // 본문은 지출·수입 생성 본문이다.
          allowTransfer: !_isSmsDraft && !_isReplace,
          // 문자 초안은 전용 저장 경로(`/import/sms/commit`)라 고정 표식을 못 싣는다 — 스위치를
          // 두면 켜도 조용히 무시된다. 저장한 뒤 거래를 열어 켜거나 통계의 정리 화면에서 바꾼다.
          showFixed: !_isSmsDraft,
          // [고쳐 쓰기] 는 서버가 교체를 받는 거래에만 — 중도 정리한 할부는 잠겼어도 못
          // 고쳐 쓴다(EXP_047). 판정이 없는 옛 서버면 잠금으로 본다(QA 26 3).
          onRewrite:
              editedForLock != null &&
                  (editedForLock.replaceable ?? _input.moneyLocked)
              ? _openRewrite
              : null,
          presetSlot: _isEdit || _isReplace
              ? null
              : _PresetSection(
                  presets: presetsAsync.value ?? const [],
                  type: _input.type,
                  categories: categoriesAsync.value ?? const [],
                  appliedId: _appliedPresetId,
                  canSave: _canSavePreset,
                  onTap: _applyPreset,
                  onShowAll: _showAllPresets,
                  onSave: _showSavePresetDialog,
                  onClear: _clearPresetMark,
                  tokens: t,
                ),
        ),
        if (_splitMismatch) ...[
          const SizedBox(height: PSpace.x16),
          _splitMismatchBanner(t),
        ],
      ],
    );
  }

  /// 분할 합 불일치 경고 — 금액을 바꿔 기존 분할 합과 어긋날 때. '분할 내역 맞추기'로 일치화 진입.
  Widget _splitMismatchBanner(GrooTokens t) {
    final l = AppLocalizations.of(context);
    final amount = _input.amountInt;
    final diff = amount - _splitSum;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: t.statusWarningSubtle,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.statusWarningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, size: 16, color: t.statusWarningFg),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.expSplitMismatch,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.expSplitDiff(
                    krw(amount),
                    krw(_splitSum),
                    '${diff > 0 ? '+' : kMinus}${krw(diff.abs())}',
                  ),
                  style: PTypo.caption.copyWith(
                    color: t.fgSecondary,
                    height: PLineHeight.normal,
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                PButton(
                  label: l.expSplitReconcile,
                  icon: LucideIcons.scissors,
                  size: PButtonSize.sm,
                  onPressed: _submitting ? null : _openReconcile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openReconcile() {
    // 분할은 지출·수입만 갖는다 — 이체 수정에는 이 버튼이 뜨지 않는다(`_splitMismatch`).
    // 고쳐 쓰기는 옛 거래의 분할을 새 금액에 맞춘다.
    final edited = _splitSource;
    if (edited == null) return;
    showSplitTxDialog(
      context,
      edited,
      overrideTotal: _input.amountInt,
      recordedTotal: edited.amount.abs(),
      initialSplits: _effectiveSplits,
      onReconciled: (splits) {
        if (!mounted) return;
        setState(() => _reconciledSplits = splits);
        _syncController();
      },
    );
  }
}

/// 프리셋 섹션 — 헤더 (라벨 + 적용됨 뱃지 + 저장 버튼) + 칩 strip + 적용 배너.
/// 웹 `AddTxSheet` 의 "프리셋 불러오기" 영역 1:1 미러.
class _PresetSection extends StatelessWidget {
  const _PresetSection({
    required this.presets,
    required this.type,
    required this.categories,
    required this.appliedId,
    required this.canSave,
    required this.onTap,
    required this.onShowAll,
    required this.onSave,
    required this.onClear,
    required this.tokens,
  });

  final List<ExpenseTemplate> presets;

  /// 지금 탭의 종류 — 이 종류의 프리셋만 칩으로 띄운다.
  final String type;
  final List<ExpenseCategory> categories;
  final int? appliedId;
  final bool canSave;
  final ValueChanged<ExpenseTemplate> onTap;

  /// 칩 줄 끝 "모두 보기" — 지금 종류의 프리셋이 칩 수(8)보다 많을 때만 보인다.
  final VoidCallback onShowAll;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // **지금 탭의 종류만** 사용 빈도 desc 로 8개 (웹과 동일).
    //
    // 종전엔 종류와 무관하게 8개라, 지출 탭에서 수입 프리셋을 누르면 `_applyPreset` 이
    // 탭을 통째로 바꿨다 — 누른 사람은 "지출 하나를 빨리 넣으려고" 누른 것이다.
    final mine = presets.where((p) => p.expenseType == type).toList();
    final sorted = [...mine]
      ..sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
    final top = sorted.take(8).toList();
    final hasMore = mine.length > top.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: PSpace.x8),
          child: Row(
            children: [
              Icon(LucideIcons.bookmark, size: 13, color: tokens.fgTertiary),
              const SizedBox(width: 6),
              Text(
                l.expPresetLoad,
                style: TextStyle(
                  fontSize: PFontSize.micro,
                  color: tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                  letterSpacing: 0.44, // micro size × wide tracking
                ),
              ),
              if (appliedId != null) ...[
                const SizedBox(width: 6),
                PBadge(
                  label: l.expPresetApplied,
                  variant: PBadgeVariant.softBrand,
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: canSave ? onSave : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: canSave ? tokens.fgBrandStrong : tokens.fgTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l.expPresetSaveCurrent,
                      style: TextStyle(
                        fontSize: PFontSize.caption,
                        color: canSave
                            ? tokens.fgBrandStrong
                            : tokens.fgTertiary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Strip
        if (top.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: top.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                if (i == top.length) {
                  return PChip(
                    label: l.presetShowAll,
                    variant: PChipVariant.outlineWeak,
                    suffixIcon: LucideIcons.chevronRight,
                    onPressed: onShowAll,
                  );
                }
                final p = top[i];
                final active = p.rowId == appliedId;
                final showAmount =
                    (p.lockAmount ?? 'N') == 'Y' && (p.amount ?? 0) > 0;
                final cat = p.categoryRowId == null
                    ? null
                    : categories.byRowId(p.categoryRowId!);
                return _PresetChip(
                  preset: p,
                  category: cat,
                  active: active,
                  showAmount: showAmount,
                  onTap: () => onTap(p),
                  tokens: tokens,
                );
              },
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgMuted,
              border: Border.all(color: tokens.borderDefault),
              borderRadius: PRadius.brSm,
            ),
            child: Text(
              l.expPresetEmpty,
              style: TextStyle(
                fontSize: PFontSize.caption,
                color: tokens.fgTertiary,
              ),
            ),
          ),

        // Active preset banner
        if (appliedId != null) ...[
          const SizedBox(height: PSpace.x8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              border: Border.all(color: tokens.borderBrand),
              borderRadius: PRadius.brSm,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 13, color: tokens.fgBrandStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.expPresetFilled,
                    style: TextStyle(
                      fontSize: PFontSize.caption,
                      color: tokens.fgBrandStrong,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    l.expClear,
                    style: TextStyle(
                      fontSize: PFontSize.micro,
                      color: tokens.fgBrandStrong,
                      fontWeight: PFontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.category,
    required this.active,
    required this.showAmount,
    required this.onTap,
    required this.tokens,
  });

  final ExpenseTemplate preset;
  final ExpenseCategory? category;
  final bool active;
  final bool showAmount;
  final VoidCallback onTap;
  final GrooTokens tokens;

  /// 칩에 붙는 금액 — 사용자가 프리셋을 만들 때 자유입력한 값이라 임의값이다.
  /// 그래서 축약도 차트 축·도넛 중앙과 같은 함수 하나([formatChartAxis])를 쓴다.
  ///
  /// 예전엔 1만 위를 `${(n / 1000).floor()}k` 로 냈다. `k` 는 한국어 화면에서
  /// 합의한 단위가 아니고(만·억·조), floor 라 19,900 이 `19k`(=19,000)로 900원을
  /// 버렸다. 1만 아래(`9,900`)는 예전과 같은 글자다.
  String _shortAmount(int n) => formatChartAxis(n.toDouble());

  @override
  Widget build(BuildContext context) {
    final catColor = resolveChartColor(
      context,
      category?.color,
      fallback: tokens.fgBrand,
    );
    final iconData = lucideByName(category?.icon, fallback: LucideIcons.tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          // border 사각형 제거 — 아이콘+글씨만 노출. active 만 subtle 채움으로 강조.
          color: active ? tokens.bgBrandSubtle : Colors.transparent,
          borderRadius: PRadius.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: softBg(context, catColor),
                  borderRadius: PRadius.tile(18),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, size: 11, color: catColor),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              preset.templateName,
              style: TextStyle(
                fontSize: PFontSize.bodySm,
                fontWeight: active ? PFontWeight.bold : PFontWeight.semi,
                color: active ? tokens.fgBrandStrong : tokens.fgPrimary,
              ),
            ),
            if (showAmount) ...[
              const SizedBox(width: 7),
              Text(
                _shortAmount(preset.amount ?? 0),
                style: TextStyle(
                  fontSize: PFontSize.micro,
                  color: active ? tokens.fgBrandStrong : tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 현재 입력값을 프리셋으로 저장. 웹 `SavePresetDialog` 1:1 미러.
class _SavePresetDialog extends ConsumerStatefulWidget {
  const _SavePresetDialog({
    required this.seedExpenseType,
    required this.seedAmount,
    required this.seedCategoryRowId,
    required this.seedAssetRowId,
    required this.seedToAssetRowId,
    required this.seedFee,
    required this.seedInterest,
    required this.seedMerchant,
    required this.seedDescription,
    required this.seedPaymentMethod,
    required this.seedIsFixed,
  });

  final String seedExpenseType;
  final int seedAmount;

  /// 이체면 null — 이체에는 카테고리가 없다.
  final int? seedCategoryRowId;

  /// 이체면 **보내는** 자산.
  final int? seedAssetRowId;
  final int? seedToAssetRowId;
  final int? seedFee;
  final int? seedInterest;
  final String seedMerchant;
  final String seedDescription;
  final String seedPaymentMethod;

  /// 고정 수입·지출 기본값 — 프리셋으로 거래를 만들 때 스위치의 초기값이 된다.
  final bool seedIsFixed;

  @override
  ConsumerState<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends ConsumerState<_SavePresetDialog> {
  late final TextEditingController _nameCtrl;
  bool _lockAmount = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 이름을 칠 때마다 다시 그린다 — [저장] 이 이름 칸을 보고 켜지는데, 듣는 쪽이 없어 이름을
    // 쳐도 안 켜지다가 '금액 고정' 을 건드려야 켜졌다(QA 30 14).
    _nameCtrl = TextEditingController(text: widget.seedMerchant)
      ..addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    // 계좌 없이도 저장한다 — 서버·리포지토리는 비운 계좌를 받는다. 종전엔 계좌가 비면 안내 없이
    // 그냥 끝나 누른 게 아무 일도 안 한 것처럼 보였다(QA 30 14).
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      await repo.create(
        templateName: name,
        categoryRowId: widget.seedCategoryRowId,
        assetRowId: widget.seedAssetRowId,
        toAssetRowId: widget.seedToAssetRowId,
        fee: widget.seedFee,
        // 이자는 금액을 따라간다 — 금액을 안 저장하면 이자도 안 저장한다
        // (사용자 결정 2026-09-15). 금액이 매달 다르면 이자도 매달 다르니, 박아 둔
        // 이자는 불러올 때마다 틀린 값이 된다. 수수료는 계좌 짝의 성질이라 그대로 둔다.
        interestAmount: _lockAmount ? widget.seedInterest : null,
        expenseType: widget.seedExpenseType,
        amount: _lockAmount ? widget.seedAmount : 0,
        description: widget.seedDescription.isEmpty
            ? null
            : widget.seedDescription,
        merchant: widget.seedMerchant.isEmpty ? null : widget.seedMerchant,
        paymentMethod: widget.seedPaymentMethod.isEmpty
            ? null
            : widget.seedPaymentMethod,
        lockAmount: _lockAmount,
        isFixed: widget.seedIsFixed,
      );
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return PFormAlertDialog(
      title: l.expPresetSaveTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PTextInput(
            controller: _nameCtrl,
            autofocus: true,
            placeholder: l.expPresetNamePlaceholder,
          ),
          const SizedBox(height: PSpace.x12),
          InkWell(
            onTap: () => setState(() => _lockAmount = !_lockAmount),
            borderRadius: PRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  PCheckbox(
                    value: _lockAmount,
                    onChanged: (v) => setState(() => _lockAmount = v ?? false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l.expPresetLockAmount(krw(widget.seedAmount)),
                      style: TextStyle(
                        fontSize: PFontSize.caption,
                        color: t.fgSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        PButton(
          label: l.actionCancel,
          // ghost 는 배경이 없어 전체 폭 배치에서 버튼으로 안 보인다
          // (spec button.md Migration notes 2026-08).
          variant: PButtonVariant.secondary,
          size: PButtonSize.lg,
          fullWidth: true,
          onPressed: _submitting ? null : Navigator.of(context).pop,
        ),
        PButton(
          label: l.actionSave,
          size: PButtonSize.lg,
          fullWidth: true,
          loading: _submitting,
          onPressed: (_submitting || _nameCtrl.text.trim().isEmpty)
              ? null
              : _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 거래 입력 (inline) — recurring 과 독립. tx_input_form.dart 해체 후 add_tx 자체 보유.

const _txPaymentMethodCodes = ['CASH', 'CARD', 'TRANSFER', 'OTHER'];

String _txPaymentMethodLabel(AppLocalizations l, String code) => switch (code) {
  'CASH' => l.expPayCash,
  'CARD' => l.expPayCard,
  'TRANSFER' => l.expPayTransfer,
  'OTHER' => l.expPayOther,
  _ => code,
};

const Map<String, List<String>?> _txPaymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

/// 카드사 공통 할부 개월 — 2~12, 18, 24.
const List<int> _installmentMonths = [
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  18,
  24,
];

/// 해외 결제는 $5.50 을 보고 입력하지 원화 환산액을 모른다 — 원 통화 × 환율로 금액을 채운다.
///
/// 카드사 실제 청구액이 다르면 금액 칸을 직접 고치면 된다. 원 통화·환율을 다시 건드릴
/// 때만 다시 계산하므로 손으로 고친 금액을 덮어쓰지 않는다.
/// 1400.000000 을 1400 으로 — 서버가 소수로 주는 값을 그대로 넣으면 입력칸이 지저분하다.
String _trimNum(double? v) {
  if (v == null) return '';
  final s = v.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}

VoidCallback _syncKrwFromForeign(_TxInputController c) => () {
  final a = c.origAmountOrNull;
  final r = c.fxRateOrNull;
  if (a == null || r == null || a <= 0 || r <= 0) return;
  c.amountCtrl.text = (a * r).round().toString();
};

/// 이자 입력을 보일지 — 대출 상환일 때만.
///
/// 원금은 부채가 줄어드는 자산 이동이지만 이자는 은행으로 아예 나가는 비용이라,
/// 입금 대상이 대출 자산일 때만 의미가 있다.
bool _showInterest(_TxInputController c, List<Asset>? assets) =>
    c.type == 'TRANSFER' && isLoanTarget(assets, c.toAssetRowId);

/// 할부 입력을 보일지 — 신용카드 지출일 때만.
bool _showInstallment(_TxInputController c, List<Asset>? assets) {
  if (c.type != 'EXPENSE' || c.assetRowId == null || assets == null) {
    return false;
  }
  final picked = assets.where((a) => a.rowId == c.assetRowId).firstOrNull;
  return picked?.assetType == 'CREDIT_CARD';
}

/// 결제 수단 + 거래 타입으로 계좌·카드 후보를 고른다.
///
/// 지출에선 예·적금(SAVINGS: 청약·정기예금·정기적금)을 뺀다 — 만기 전까지 묶인 돈이라
/// 거기서 직접 결제나 출금이 나가지 않는다(쓰려면 해지해서 입출금으로 옮긴다).
/// 납입·해지는 이체로 처리하므로 이체 목록에는 그대로 남는다.
/// 수입은 이자가 그 계좌로 직접 들어오므로 남긴다.
bool _allowTxAsset(Asset a, String paymentMethod, String type) {
  final allowed = paymentMethod.isNotEmpty
      ? _txPaymentAssetTypes[paymentMethod]
      : null;
  if (allowed != null && !allowed.contains(a.assetType)) return false;
  if (type == 'EXPENSE' && a.assetType == 'SAVINGS') return false;
  return true;
}

/// 거래 입력 상태 (지출/수입/이체).
class _TxInputController {
  _TxInputController({
    this.type = 'EXPENSE',
    String amount = '',
    String merchant = '',
    String memo = '',
    this.categoryRowId,
    this.assetRowId,
    this.paymentMethod = '',
    DateTime? date,
    TimeOfDay? time,
  }) : date = date ?? DateTime.now(),
       time = time ?? TimeOfDay.now(),
       amountCtrl = TextEditingController(text: amount),
       merchantCtrl = TextEditingController(text: merchant),
       memoCtrl = TextEditingController(text: memo),
       feeCtrl = TextEditingController(),
       interestCtrl = TextEditingController(),
       origAmountCtrl = TextEditingController(),
       fxRateCtrl = TextEditingController();

  final TextEditingController amountCtrl;
  final TextEditingController merchantCtrl;
  final TextEditingController memoCtrl;
  final TextEditingController feeCtrl;

  /// 대출 상환의 이자 — 상환액 중 이 금액은 부채를 줄이지 않고 지출로 잡힌다.
  final TextEditingController interestCtrl;

  /// 0·빈칸은 "없음" 이다 — 서버에 0 을 실어 보내도 뜻이 같아서 키를 뺀다.
  int? get feeOrNull {
    final v = int.tryParse(feeCtrl.text.replaceAll(',', '')) ?? 0;
    return v > 0 ? v : null;
  }

  int? get interestOrNull {
    final v = int.tryParse(interestCtrl.text.replaceAll(',', '')) ?? 0;
    return v > 0 ? v : null;
  }

  /// 해외 결제의 원 통화 금액·환율 — 셋이 함께여야 카드사 청구 환율과 대사할 수 있다.
  final TextEditingController origAmountCtrl;
  final TextEditingController fxRateCtrl;

  String type; // EXPENSE / INCOME / TRANSFER
  int? categoryRowId;
  int? assetRowId; // EXPENSE/INCOME 자산, TRANSFER 출금 자산
  int? toAssetRowId; // TRANSFER 입금 자산 (이체 시 폼에서 set)
  String paymentMethod;

  /// 할부 개월 — 신용카드 지출에만 의미. 0 = 일시불.
  int installmentMonths = 0;

  /// 사용자가 고른 결제 통화. `null` 이면 아직 아무것도 안 골랐다.
  String? currencyPick;

  /// 이 거래에 이미 적혀 있던 통화 — 편집·환불·문자 초안이 채운다.
  ///
  /// 원화 거래는 서버에서 `originalCurrency` 가 `null` 로 오지만 여기엔 `KRW` 를
  /// 넣는다. 비워 두면 아래 [currency] 가 설정의 기본 통화로 떨어져, 원화로 적어
  /// 둔 거래를 열기만 해도 해외 결제 입력이 펼쳐진다.
  String? txCurrency;

  /// 설정의 기본 통화 — 폼이 매 빌드 흘려 넣는다(D7 · QA #124).
  ///
  /// `/me/preferences` 는 설정 화면을 안 들른 세션에서 이 시트보다 늦게 도착한다.
  /// 열 때 한 번만 읽어 굳히면 첫 렌더의 원화에 잠기므로, 도착한 값을 매 빌드
  /// 다시 흘려 넣어 아직 안 고른 새 거래에 반영한다.
  String defaultCurrency = kDefaultCurrency;

  /// 결제 통화 — KRW 면 원화 결제(원 통화 기록 없음).
  ///
  /// 우선순위는 **고른 값 > 이 거래의 값 > 설정의 기본 통화**다. 기본 통화는
  /// 새 거래에만 닿는다 — 편집·환불·문자 초안은 [txCurrency] 에서 멈춘다.
  String get currency => currencyPick ?? txCurrency ?? defaultCurrency;
  DateTime date;
  TimeOfDay time;
  bool amountLocked = false; // 프리셋 금액 잠금 (applyPreset 에서 set)

  /// 고정 수입·지출 — 월세·월급처럼 매달 정해진 거래. 통계가 따로 나눠 본다(돈에는 영향 없음).
  /// 이체에는 없다.
  bool isFixed = false;

  /// 금액칸에 걸 상한 — 거래 상한(100억) 하나다.
  int get amountMaxForInput => kAmountMax;

  /// 시스템이 만든 거래의 출처 (TRADE_REALIZED / TRANSFER_INTEREST). null 이면 손으로 쓴 거래.
  /// 값이 있으면 금액·날짜·자산이 잠긴다 — 서버도 같은 규칙으로 거른다.
  String? autoSource;

  /// 결제 문자 초안에서 "이 카드로 기억" 을 물어볼 상황인가 (카드는 알아봤는데 아직 안 외움).
  bool smsRememberAsk = false;

  /// 사용자가 그 체크를 켰는가 — 저장 시 (카드 힌트 → 자산) 을 서버가 적어 둔다.
  bool smsRememberCard = false;

  /// 금액·날짜·자산을 못 고치는가 — 계산 결과라서.
  bool get isAutoGenerated => autoSource != null;

  /// 결제가 끝난 카드 거래라 돈 칸을 못 고치는가(D12) — 시트가 매 빌드 흘려 넣는다.
  bool moneyLocked = false;

  /// 돈 칸 전부 — 금액·날짜·시간·자산·결제수단·할부·통화 3칸 — 을 잠그는가.
  ///
  /// 자동 생성 거래와 결제가 끝난 거래가 같은 잠금을 쓴다. 통화·환율·결제수단·할부도
  /// 함께 잠근다 — 환율을 고치면 금액이 다시 계산돼 덮이고(`_syncKrwFromForeign`),
  /// 결제수단을 바꾸면 안 맞는 자산이 풀린다. 한 칸만 열어 둬도 돈 칸이 새로 바뀐다.
  bool get moneyFieldsLocked => isAutoGenerated || moneyLocked;

  int get amountInt => int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String? get merchantOrNull =>
      merchantCtrl.text.trim().isEmpty ? null : merchantCtrl.text.trim();
  String? get memoOrNull =>
      memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim();
  String? get paymentMethodOrNull =>
      paymentMethod.isEmpty ? null : paymentMethod;

  /// 외화 결제인가 — 이체는 두 자산 사이의 이동이라 통화가 자산에 달려 있어 제외.
  bool get isForeignTx => type != 'TRANSFER' && isForeignCurrency(currency);
  double? get origAmountOrNull => isForeignTx
      ? double.tryParse(origAmountCtrl.text.replaceAll(',', ''))
      : null;
  double? get fxRateOrNull =>
      isForeignTx ? double.tryParse(fxRateCtrl.text.replaceAll(',', '')) : null;

  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    memoCtrl.dispose();
    feeCtrl.dispose();
    interestCtrl.dispose();
    origAmountCtrl.dispose();
    fxRateCtrl.dispose();
  }
}

/// 거래 입력 폼 (지출/수입/이체) — add_tx_sheet 자체 보유.
class _TxInputForm extends ConsumerWidget {
  const _TxInputForm({
    required this.controller,
    required this.onChanged,
    this.typeReadOnly = false,
    this.typeDisabledFor,
    this.allowTransfer = true,
    this.presetSlot,
    this.onRewrite,
    this.showFixed = true,
  });

  /// 고정 스위치를 내놓는가 — 저장 경로가 고정 표식을 못 받는 화면(결제 문자 초안)은 false 다.
  final bool showFixed;

  final _TxInputController controller;
  final VoidCallback onChanged;
  final bool typeReadOnly;
  final String? typeDisabledFor;

  /// 이체 선택지를 내놓는가 — 저장 경로가 이체를 못 받는 화면은 false 다.
  final bool allowTransfer;
  final Widget? presetSlot;

  /// 돈 칸이 잠긴 거래의 [고쳐 쓰기] — 잠금 안내 옆에 단다(D13).
  final VoidCallback? onRewrite;

  void _set(VoidCallback mutate) {
    mutate();
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final c = controller;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);

    final amountInt = c.amountInt;
    final amountColor = c.type == 'EXPENSE'
        ? t.fgExpense
        : (c.type == 'INCOME' ? t.fgIncome : t.fgTransfer);
    final amountPrefix = c.type == 'EXPENSE'
        ? '−'
        : (c.type == 'INCOME' ? '+' : '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 토글
        PTabs<String>(
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          value: c.type,
          onChanged: typeReadOnly
              ? (_) {}
              : (v) => _set(() {
                  c.type = v;
                  // 종류를 바꾸면 안 맞는 카테고리는 놓는다(웹 `AddTxSheet` 정합).
                  // 서버가 종류≠카테고리 종류를 400 으로 막으므로(`ExpenseServiceImpl`)
                  // 들고 있어 봐야 저장이 실패한다 — 문자 초안은 지출 카테고리를
                  // 미리 채워 오므로 수입으로 바꾸는 순간 바로 걸린다.
                  final cats = categoriesAsync.value;
                  if (cats != null) {
                    final cat = cats
                        .where((x) => x.rowId == c.categoryRowId)
                        .firstOrNull;
                    if (cat == null || cat.expenseType != v) {
                      c.categoryRowId = null;
                    }
                  }
                }),
          items: [
            PTabItem(
              value: 'EXPENSE',
              label: l.expTypeExpense,
              disabled: typeReadOnly && typeDisabledFor != 'EXPENSE',
            ),
            PTabItem(
              value: 'INCOME',
              label: l.expTypeIncome,
              disabled: typeReadOnly && typeDisabledFor != 'INCOME',
            ),
            if (allowTransfer && (!typeReadOnly || c.type == 'TRANSFER'))
              PTabItem(
                value: 'TRANSFER',
                label: l.expTypeTransfer,
                disabled: typeReadOnly && typeDisabledFor != 'TRANSFER',
              ),
          ],
        ),
        const SizedBox(height: PSpace.x12),

        if (presetSlot != null) ...[
          presetSlot!,
          const SizedBox(height: PSpace.x20),
        ],

        // 금액
        Row(
          children: [
            Expanded(child: PSectionLabel(l.expAmount)),
            if (c.amountLocked || c.isAutoGenerated) ...[
              Icon(LucideIcons.lock, size: 11, color: t.fgTertiary),
              const SizedBox(width: 3),
              Text(
                c.isAutoGenerated ? l.expAutoLock : l.expPresetLock,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.amountCtrl,
          numbersOnly: true,
          // 거래 100억 상한 — 넘는 값은 타이핑 자체가 안 된다
          // (`AmountLimitFormatter`).
          amountMax: c.amountMaxForInput,
          enabled: !c.amountLocked && !c.moneyFieldsLocked,
          placeholder: '0',
          prefixText: amountInt > 0 ? amountPrefix : null,
          suffixText: wonUnit(),
          style: PTypo.h4.copyWith(
            color: amountColor,
            fontWeight: PFontWeight.bold,
          ),
          onChanged: (_) => onChanged(),
        ),
        // 왜 못 고치는지 알려 준다 — 잠긴 칸만 보여 주면 고장으로 보인다.
        if (c.isAutoGenerated) ...[
          const SizedBox(height: PSpace.x4),
          Text(switch (c.autoSource) {
            'TRADE_REALIZED' => l.expAutoSourceTradeRealized,
            'TRANSFER_INTEREST' => l.expAutoSourceTransferInterest,
            'CARD_CARRYOVER' ||
            'CARD_CARRYOVER_DUE' => l.expAutoSourceCardCarryover,
            _ => l.expAutoSourceDefault,
          }, style: PTypo.micro.copyWith(color: t.fgTertiary)),
        ]
        // 결제가 끝난 카드 거래(D12) — 돈 칸은 회색이고, 바꾸려면 그 자리의
        // [고쳐 쓰기] 로 새 거래를 쓴다(D13). 카테고리·가맹점·메모는 그대로 고친다.
        // 고쳐 쓸 수 없는 잠긴 거래(중도 정리한 할부)는 버튼 없이 왜 못 바꾸는지만
        // 말한다 — 없는 버튼을 가리키면 안 된다(QA 26 3).
        else if (c.moneyLocked) ...[
          const SizedBox(height: PSpace.x8),
          Container(
            key: const ValueKey('money-lock-note'),
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x12,
              vertical: PSpace.x8,
            ),
            decoration: BoxDecoration(
              color: t.bgMuted,
              borderRadius: PRadius.brMd,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lock, size: 14, color: t.fgTertiary),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: Text(
                    onRewrite != null
                        ? l.expMoneyLockedNote
                        : l.expMoneyLockedPaidOffNote,
                    style: PTypo.caption.copyWith(color: t.fgSecondary),
                  ),
                ),
                if (onRewrite != null) ...[
                  const SizedBox(width: PSpace.x8),
                  PButton(
                    label: l.expRewrite,
                    variant: PButtonVariant.outline,
                    size: PButtonSize.sm,
                    onPressed: onRewrite,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: PSpace.x16),

        if (c.type != 'TRANSFER') ...[
          PSectionLabel(l.expCategory, variant: PSectionLabelVariant.eyebrow),
          const SizedBox(height: PSpace.x8),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: PCircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '${l.categoryLoadError}: $e',
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
            data: (categories) {
              final topCategories =
                  categories
                      .where(
                        (cat) =>
                            cat.expenseType == c.type &&
                            (cat.parentRowId == null || cat.parentRowId == 0),
                      )
                      .toList()
                    ..sort(
                      (a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0),
                    );
              if (topCategories.isEmpty) {
                return Text(
                  l.expNoCategoryForType,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                );
              }

              final childrenByParent = <int, List<dynamic>>{};
              for (final cat in categories) {
                if (cat.parentRowId == null ||
                    cat.parentRowId == 0 ||
                    cat.expenseType != c.type) {
                  continue;
                }
                childrenByParent
                    .putIfAbsent(cat.parentRowId!, () => [])
                    .add(cat);
              }
              for (final list in childrenByParent.values) {
                list.sort(
                  (a, b) => ((a.sortOrder ?? 0) as int).compareTo(
                    (b.sortOrder ?? 0) as int,
                  ),
                );
              }

              final selectedCat = c.categoryRowId == null
                  ? null
                  : categories
                        .where((cat) => cat.rowId == c.categoryRowId)
                        .firstOrNull;
              final selectedParentId = selectedCat == null
                  ? null
                  : (selectedCat.parentRowId == null ||
                            selectedCat.parentRowId == 0
                        ? selectedCat.rowId
                        : selectedCat.parentRowId);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 6.0;
                      const columns = 5;
                      final cellWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final cat in topCategories)
                            SizedBox(
                              width: cellWidth,
                              child: PCategoryTile(
                                name: cat.categoryName,
                                color: resolveChartColor(
                                  context,
                                  cat.color,
                                  fallback: t.fgBrand,
                                ),
                                icon: lucideByName(cat.icon ?? 'tag'),
                                active: selectedParentId == cat.rowId,
                                onTap: () => _set(() {
                                  final firstChild =
                                      childrenByParent[cat.rowId]?.first;
                                  c.categoryRowId = firstChild != null
                                      ? firstChild.rowId
                                      : cat.rowId;
                                }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (selectedParentId != null &&
                      (childrenByParent[selectedParentId]?.isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: 10),
                    _SelectField<int>(
                      value: c.categoryRowId,
                      hint: l.expSubcategory,
                      // 상위 자신은 고를 수 없다 — 이 칸은 하위가 있는 상위에서만 뜨고, 하위가
                      // 있는 상위에는 서버가 거래를 안 받는다(EXP_009). 종전엔 첫 칸이 상위라
                      // 고르면 저장에서 막혔다(QA 30 13, 웹과 같다).
                      items: [
                        for (final child in childrenByParent[selectedParentId]!)
                          _SelectOption<int>(
                            child.rowId as int,
                            child.categoryName as String,
                          ),
                      ],
                      onChanged: (v) => _set(() => c.categoryRowId = v),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: PSpace.x12),
        ],

        if (c.type != 'TRANSFER') ...[
          // 거래처
          PSectionLabel(c.type == 'INCOME' ? l.expIncomeSource : l.expPayee),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: c.merchantCtrl,
            placeholder: c.type == 'INCOME'
                ? l.expIncomeSourcePlaceholder
                : l.expPayeePlaceholder,
          ),
          const SizedBox(height: PSpace.x12),

          // 결제 수단 (Select)
          PSectionLabel(
            c.type == 'INCOME' ? l.expIncomeMethod : l.expPaymentMethod,
          ),
          const SizedBox(height: PSpace.x4),
          _SelectField<String>(
            // ''(선택 안 함)도 유효 default — null 변환 금지(웹 정합: '선택 안 함' selected).
            value: c.paymentMethod,
            enabled: !c.moneyFieldsLocked,
            hint: l.expNone,
            items: [
              _SelectOption<String>('', l.expNone),
              for (final code in _txPaymentMethodCodes)
                _SelectOption<String>(code, _txPaymentMethodLabel(l, code)),
            ],
            onChanged: (v) => _set(() {
              c.paymentMethod = v ?? '';
              if (c.paymentMethod.isNotEmpty && c.assetRowId != null) {
                final assets = assetsAsync.value ?? const [];
                final cur = assets
                    .where((a) => a.rowId == c.assetRowId)
                    .firstOrNull;
                if (cur != null &&
                    !_allowTxAsset(cur, c.paymentMethod, c.type)) {
                  c.assetRowId = null;
                }
              }
            }),
          ),
          const SizedBox(height: PSpace.x12),

          // 계좌·카드 (Select, payment method 로 필터)
          PSectionLabel(
            c.type == 'INCOME' ? l.expDepositAccount : l.expAccountCard,
          ),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: PCircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '${l.expAssetLoadError}: $e',
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
            data: (assets) {
              final filtered = assets
                  .where((a) => _allowTxAsset(a, c.paymentMethod, c.type))
                  .toList();
              return _SelectField<int>(
                // null(미선택)도 '선택 안 함'(-1) default로 표시 — 웹 정합.
                value: c.assetRowId ?? -1,
                enabled: !c.moneyFieldsLocked,
                hint: l.expNone,
                items: [
                  _SelectOption<int>(-1, l.expNone),
                  for (final a in filtered)
                    _SelectOption<int>(
                      a.rowId,
                      a.institution != null
                          ? '${a.institution} · ${a.assetName}'
                          : a.assetName,
                    ),
                ],
                onChanged: (v) => _set(() => c.assetRowId = v == -1 ? null : v),
              );
            },
          ),
          // 결제 문자로 들어온 카드를 아직 안 외운 경우에만 물어본다.
          // 한 번 켜 두면 다음 문자부터는 자산을 고르는 단계가 사라진다.
          if (c.smsRememberAsk) ...[
            const SizedBox(height: PSpace.x8),
            InkWell(
              onTap: c.assetRowId == null
                  ? null
                  : () => _set(() => c.smsRememberCard = !c.smsRememberCard),
              borderRadius: PRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    PCheckbox(
                      // 자산을 안 골랐으면 기억할 대상이 없다.
                      value: c.assetRowId != null && c.smsRememberCard,
                      onChanged: c.assetRowId == null
                          ? null
                          : (v) => _set(() => c.smsRememberCard = v ?? false),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l.smsRememberCard,
                        style: TextStyle(
                          fontSize: PFontSize.caption,
                          color: c.assetRowId == null
                              ? t.fgTertiary
                              : t.fgSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: PSpace.x12),

          // 할부 — 신용카드 지출에만. 청구는 이 개월 수로 나뉘어 잡힌다.
          // (체크카드는 긁는 즉시 계좌에서 빠지고, 현금·이체는 나눌 수 없다)
          if (_showInstallment(c, assetsAsync.value)) ...[
            PSectionLabel(l.expInstallment),
            const SizedBox(height: PSpace.x4),
            _SelectField<int>(
              value: c.installmentMonths,
              enabled: !c.moneyFieldsLocked,
              hint: l.expLumpSum,
              items: [
                _SelectOption<int>(0, l.expLumpSum),
                for (final m in _installmentMonths)
                  _SelectOption<int>(m, l.expInstallmentMonths(m)),
              ],
              onChanged: (v) => _set(() => c.installmentMonths = v ?? 0),
            ),
            if (c.installmentMonths > 1 && c.amountInt > 0) ...[
              const SizedBox(height: PSpace.x4),
              Text(
                l.expInstallmentHint(
                  krw(c.amountInt ~/ c.installmentMonths),
                  c.installmentMonths,
                ),
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
            const SizedBox(height: PSpace.x12),
          ],

          // 통화 — 외화면 원 통화 금액·환율이 열리고, 금액(원화)이 자동으로 채워진다.
          PSectionLabel(l.expCurrency),
          const SizedBox(height: PSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SelectField<String>(
                  value: c.currency,
                  enabled: !c.moneyFieldsLocked,
                  hint: kDefaultCurrency,
                  items: [
                    for (final cur in kCurrencies)
                      _SelectOption<String>(
                        cur.code,
                        '${cur.symbol} ${cur.code}',
                      ),
                  ],
                  onChanged: (v) => _set(() {
                    c.currencyPick = v ?? kDefaultCurrency;
                    // 원화로 돌아오면 남은 외화 입력을 지운다(저장 시 흘러들지 않도록).
                    if (!isForeignCurrency(c.currency)) {
                      c.origAmountCtrl.clear();
                      c.fxRateCtrl.clear();
                    }
                  }),
                ),
              ),
              if (c.isForeignTx) ...[
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: PTextInput(
                    controller: c.origAmountCtrl,
                    enabled: !c.moneyFieldsLocked,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: l.expOriginalAmount,
                    onChanged: (_) => _set(_syncKrwFromForeign(c)),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: PTextInput(
                    controller: c.fxRateCtrl,
                    enabled: !c.moneyFieldsLocked,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: l.expExchangeRate,
                    onChanged: (_) => _set(_syncKrwFromForeign(c)),
                  ),
                ),
              ],
            ],
          ),
          if (c.isForeignTx &&
              (c.origAmountOrNull ?? 0) > 0 &&
              (c.fxRateOrNull ?? 0) > 0) ...[
            const SizedBox(height: PSpace.x4),
            Text(
              l.expFxHint(
                formatOriginalAmount(
                  c.origAmountOrNull!,
                  c.currency,
                  Localizations.localeOf(context).toString(),
                ),
                krwSigned(
                  (c.origAmountOrNull! * c.fxRateOrNull!).round(),
                  false,
                  unit: true,
                ),
              ),
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ],
          const SizedBox(height: PSpace.x12),
        ] else ...[
          // 이체 — 규칙과 화면 모두 반복 설정·프리셋 폼과 한 벌이다.
          TransferAccountFields(
            assets: assetsAsync,
            fromAssetRowId: c.assetRowId,
            toAssetRowId: c.toAssetRowId,
            feeController: c.feeCtrl,
            interestController: c.interestCtrl,
            amountForHint: c.amountInt,
            onFromChanged: (v) => _set(() => c.assetRowId = v),
            onToChanged: (v) => _set(() => c.toAssetRowId = v),
            onInterestChanged: () => _set(() {}),
            labelBuilder: (text) => PSectionLabel(text),
          ),
        ],

        // 날짜(·시간)
        // 이체도 시각을 받는다 — transfer_date 가 DATETIME 이라, 시각이 있어야
        // 같은 날 잔액수정보다 뒤에 일어난 이체가 절대 앵커에 지워지지 않는다.
        PSectionLabel(l.expDateTime),
        const SizedBox(height: PSpace.x4),
        Row(
          children: [
            Expanded(
              child: PDateInput(
                value: c.date,
                enabled: !c.moneyFieldsLocked,
                onChanged: (d) {
                  if (d != null) _set(() => c.date = d);
                },
                firstDate: DateTime(2020),
                lastDate: DateTime(2030, 12, 31),
              ),
            ),
            const SizedBox(width: PSpace.x8),
            SizedBox(
              width: 116,
              child: PTimeInput(
                value: c.time,
                enabled: !c.moneyFieldsLocked,
                onChanged: (tm) {
                  if (tm != null) _set(() => c.time = tm);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // 고정 수입·지출 — 이체에는 없다(내 통장끼리 옮기는 돈이라 합계가 안 달라진다).
        if (showFixed && c.type != 'TRANSFER') ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.type == 'INCOME'
                          ? l.fixedSwitchIncome
                          : l.fixedSwitchExpense,
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.type == 'INCOME'
                          ? l.fixedHintIncome
                          : l.fixedHintExpense,
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x12),
              PSwitch(
                value: c.isFixed,
                onChanged: (v) => _set(() => c.isFixed = v),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
        ],

        PSectionLabel(l.expDescription),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.memoCtrl,
          maxLines: 2,
          placeholder: l.expMemoPlaceholder,
        ),
      ],
    );
  }
}

class _SelectOption<T> {
  const _SelectOption(this.value, this.label);
  final T value;
  final String label;
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.enabled = true,
  });
  final T? value;
  final List<_SelectOption<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PSelect<T>(
      value: items.any((i) => i.value == value) ? value : null,
      placeholder: hint,
      enabled: enabled,
      onChanged: onChanged,
      items: [
        for (final opt in items)
          PSelectItem<T>(value: opt.value, label: opt.label),
      ],
    );
  }
}
