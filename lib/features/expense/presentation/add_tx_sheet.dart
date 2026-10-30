import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_pickers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart'
    show scrollSheetBodyToTop;
import 'package:groo_damda_app/features/expense/presentation/tx_form_parts.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_input.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/expense_split/presentation/split_tx_dialog.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/sms/data/sms_android.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/features/sms/domain/sms_prefilter.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart'
    show formatDateValue;
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/forms/name_policy.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/features/category/presentation/category_tile.dart';

String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

const int _kPresetNameMax = 12;

/// 거래 추가/수정 시트(I-21 21-2 · D · E) — **금액을 먼저 받는 두 단계**. 새로 추가는 ① 종류 칩 · 밑줄 금액 · 프리셋 · 결제 문자 줄 → [다음] →
/// ② 거래처 칸 · 줄 칸 · 고정 스위치 → [추가]. 수정 · 고쳐 쓰기 · 문자 초안은 ② 로 바로 열린다(금액은 줄 › 한 단계).
/// 메모 · 수수료 · 이자 · 결제 문자 · 프리셋 고르기 · 프리셋 저장은 모두 **같은 시트 안 한 단계**다(폼 위 폼 · 폼 위 확인창 안 입력칸 없음).
/// 고르기(카테고리 · 계좌 · 결제 수단 · 할부 · 통화 · 날짜 · 시각)만 이 시트 위의 고르기 시트다(고른 값은 줄에 그대로).
///
/// [edit] 이 있으면 수정(PUT /expense/{id}), [editTransfer] 는 이체 수정, [replaceOf] 는 고쳐 쓰기(POST /expense/{id}/replace),
/// [smsDraft] 는 결제 문자 초안(저장은 문자 전용 경로). 아무것도 없으면 새 거래다.
void showAddTxSheet(
  BuildContext context, {
  String? defaultDate,
  Expense? edit,

  /// 이체 편집 모드 — 서버가 이자 지출·잔액 이력을 되돌렸다 다시 만든다(rowId 유지).
  AssetTransfer? editTransfer,

  /// 결제 문자 초안 — 파싱 결과로 폼을 채우고, 저장은 문자 전용 경로로 보낸다.
  SmsDraft? smsDraft,

  /// 고쳐 쓰기(D13) — 결제가 끝나 돈 칸이 잠긴 거래. 그 값이 전부 채워진 새 거래로 열고, 저장은 replace 로 보낸다.
  Expense? replaceOf,

  /// 저장하면 응답 값(수정한 거래)을 넘기고, 저장 없이 닫히면 [onCancelled]. 시트가 닫힌 뒤에 부른다(목록을 다시 받은 다음).
  ValueChanged<Expense>? onSaved,

  /// 이체 수정 저장 — 저장한 값으로 만든 이체를 넘긴다.
  ValueChanged<AssetTransfer>? onTransferSaved,

  /// 저장하지 않고 닫혔다.
  VoidCallback? onCancelled,
}) {
  final l = AppLocalizations.of(context);
  final probe = TxFormProbe();
  var done = false;
  PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    interceptClose: () => probe.interceptClose(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (sheet) => TxFormFlow(
      defaultDate: defaultDate,
      edit: edit,
      editTransfer: editTransfer,
      smsDraft: smsDraft,
      replaceOf: replaceOf,
      probe: probe,
      onSaved: onSaved == null
          ? null
          : (saved) async {
              done = true;
              final host = hostContextOf(sheet);
              PBottomSheet.of(sheet).close();
              if (host.mounted) onSaved(saved);
            },
      onTransferSaved: onTransferSaved == null
          ? null
          : (saved) async {
              done = true;
              final host = hostContextOf(sheet);
              PBottomSheet.of(sheet).close();
              if (host.mounted) onTransferSaved(saved);
            },
      onFinished: () => done = true,
    ),
  ).whenComplete(() {
    if (!done) onCancelled?.call();
  });
}

/// 시트의 닫는 길이 이 폼의 그 순간 상태를 묻는 자리 — 폼의 주인은 [TxFormFlow] 라 시트 밖에서 이 줄로 닿는다.
class TxFormProbe {
  /// 바뀐 값이 있는가(처음 값과 견줘).
  bool Function() dirty = () => false;

  /// 한 단계가 열려 있으면 그 단계만 닫고(또는 묻고) 참 — 시트는 닫지 않는다.
  bool Function() interceptClose = () => false;
}

enum _S {
  one,
  two,
  amount,
  krw,
  memo,
  fee,
  interest,
  sms,
  presetAll,
  presetSave,
  presetAmount,
}

class _Errs {
  String? amount;
  String? category;
  String? from;
  String? to;
  String? fx;
  String? krw;
  String? interest;
  String? splits;
  bool get any =>
      amount != null ||
      category != null ||
      from != null ||
      to != null ||
      fx != null ||
      krw != null ||
      interest != null ||
      splits != null;
}

/// 폼의 값을 한 줄로 — 처음 값과 견줘 바뀜을 본다.
String _sig(TxInput c) => [
  c.type,
  c.amountCtrl.text,
  c.origAmountCtrl.text,
  c.fxRateCtrl.text,
  c.currency,
  c.merchantCtrl.text,
  c.memoCtrl.text,
  c.categoryRowId,
  c.assetRowId,
  c.toAssetRowId,
  c.paymentMethod,
  c.installmentMonths,
  c.isoDate,
  _formatTime(c.time),
  c.feeCtrl.text,
  c.interestCtrl.text,
  c.isFixed,
].join('|');

class TxFormFlow extends ConsumerStatefulWidget {
  const TxFormFlow({
    super.key,
    this.defaultDate,
    this.edit,
    this.editTransfer,
    this.smsDraft,
    this.replaceOf,
    required this.probe,
    this.onBack,
    this.onSaved,
    this.onTransferSaved,
    this.onFinished,
  });

  final String? defaultDate;
  final Expense? edit;
  final AssetTransfer? editTransfer;
  final SmsDraft? smsDraft;
  final Expense? replaceOf;
  final TxFormProbe probe;

  /// 상세 시트 안의 한 단계로 그릴 때 — 머리에 ← 를 달고(상세로) 저장이 끝나도 시트를 닫지 않는다.
  final VoidCallback? onBack;

  /// 수정 저장이 끝났다 — 부모가 새 값을 받아 단계를 옮길 때까지 [저장] 은 기다림 모양으로 남는다. 목록을 다시 받은 뒤 부른다.
  final Future<void> Function(Expense saved)? onSaved;
  final Future<void> Function(AssetTransfer saved)? onTransferSaved;

  /// 저장 · 넘김이 끝나 닫힘이 "취소" 가 아니다.
  final VoidCallback? onFinished;

  @override
  ConsumerState<TxFormFlow> createState() => _TxFormFlowState();
}

class _TxFormFlowState extends ConsumerState<TxFormFlow> {
  late TxInput _input;
  _S _step = _S.one;
  _S _returnTo = _S.one;
  bool _submitting = false;
  bool _leaving = false;

  /// 지금 모드 — 고쳐 쓰기로 갈아 끼우면 [_edit] 가 비고 [_replaceOf] 가 선다.
  Expense? _edit;
  Expense? _replaceOf;
  SmsDraft? _smsDraft;

  /// 새로 추가로 열렸다 — 1단계가 있고, 2단계 ← 가 1단계로 간다.
  late bool _startedAtOne;

  int? _appliedPresetId;
  String? _emptyPresetName;
  _Errs _errs = _Errs();
  String? _saveError;
  late String _initialSig;
  String _subSig = '';
  Map<String, String>? _snap;

  final _amountFocus = FocusNode();
  final _merchantFocus = FocusNode();
  final _subFocus = FocusNode();
  final _smsFocus = FocusNode();
  final _smsCtrl = TextEditingController();
  final _presetNameCtrl = TextEditingController();
  final _presetAmountCtrl = TextEditingController();
  String? _smsError;
  bool _smsBusy = false;
  bool _smsLow = false;
  String? _presetNameError;
  String? _presetFormError;
  bool _presetSaving = false;
  int _presetNameGen = 0;

  // 편집 모드 분할 일치화: 서버 분할 + 이번 세션에서 맞춘 분할.
  List<SplitInput> _serverSplits = const [];
  bool _splitsPending = false;
  List<SplitInput>? _reconciledSplits;
  List<SplitInput> get _effectiveSplits => _reconciledSplits ?? _serverSplits;
  int get _splitSum => _effectiveSplits.fold<int>(0, (s, x) => s + x.amount);
  Expense? get _splitSource => _edit ?? _replaceOf;
  bool get _splitMismatch =>
      _splitSource != null &&
      _input.type != 'TRANSFER' &&
      _input.amountInt > 0 &&
      _effectiveSplits.isNotEmpty &&
      _input.amountInt != _splitSum;

  bool get _isReplace => _replaceOf != null;
  bool get _isEdit => _edit != null || widget.editTransfer != null;
  bool get _isSms => _smsDraft != null;
  bool get _embedded => widget.onBack != null;
  bool get _typeLocked => _isEdit;
  bool get _isSub =>
      _step != _S.one && _step != _S.two && _step != _S.presetAll;

  bool get _hasStepOne => _startedAtOne;

  @override
  void initState() {
    super.initState();
    _edit = widget.edit;
    _replaceOf = widget.edit == null && widget.editTransfer == null
        ? widget.replaceOf
        : null;
    _smsDraft = widget.smsDraft;
    _startedAtOne =
        _edit == null &&
        widget.editTransfer == null &&
        _replaceOf == null &&
        _smsDraft == null;
    _seed();
    _step = _startedAtOne ? _S.one : _S.two;
    widget.probe.dirty = _dirty;
    widget.probe.interceptClose = _intercept;
    // 새 거래는 1단계 금액 칸에 초점(숫자 키보드) — 시트가 그려진 뒤에 옮긴다
    if (_startedAtOne) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step == _S.one) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    widget.probe.interceptClose = () => false;
    _input.dispose();
    _amountFocus.dispose();
    _merchantFocus.dispose();
    _subFocus.dispose();
    _smsFocus.dispose();
    _smsCtrl.dispose();
    _presetNameCtrl.dispose();
    _presetAmountCtrl.dispose();
    super.dispose();
  }

  /// 값을 처음으로 채운다 — 모드마다 시드가 다르다(수정 · 고쳐 쓰기: 그 거래 · 문자 초안: 해석 결과).
  void _seed() {
    final e = _edit ?? _replaceOf;
    final tr = widget.editTransfer;
    final sms = _smsDraft?.parsed;
    DateTime date;
    TimeOfDay time = TimeOfDay.fromDateTime(calendarNow());
    String? raw = tr?.transferDate ?? e?.expenseDate ?? sms?.expenseDate;
    if (raw != null && raw.length >= 10) {
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
      date = calendarNow();
    }
    final old = _inputOrNull;
    old?.dispose();
    final c = TxInput(
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
      assetRowId: tr?.fromAssetRowId ?? e?.assetRowId ?? sms?.assetRowId,
      date: date,
      time: time,
    );
    if (tr != null) {
      c.toAssetRowId = tr.toAssetRowId;
      if ((tr.fee ?? 0) > 0) c.feeCtrl.text = groupWon(tr.fee!);
      if ((tr.interestAmount ?? 0) > 0) {
        c.interestCtrl.text = groupWon(tr.interestAmount!);
      }
    }
    // 편집은 그 거래의 통화를 승계한다 — 원화 거래는 originalCurrency 가 null 이라 KRW 로 박는다(기본 통화가 흘러들지 않게).
    if (e != null) {
      c.txCurrency = e.originalCurrency ?? kDefaultCurrency;
      if (e.originalCurrency != null) {
        c.origAmountCtrl.text = groupDecimal(trimNum(e.originalAmount));
        c.fxRateCtrl.text = groupDecimal(trimNum(e.exchangeRate));
      }
    }
    if (e?.installmentMonths != null) {
      c.installmentMonths = e!.installmentMonths!;
    } else if (sms?.installmentMonths != null) {
      c.installmentMonths = sms!.installmentMonths!;
    }
    if (sms != null) {
      // 문자에 외화가 안 실렸으면 원화 결제다 — 설정의 기본 통화가 외화여도 문자가 맞다.
      c.txCurrency = sms.originalCurrency ?? kDefaultCurrency;
      if (sms.originalCurrency != null) {
        c.origAmountCtrl.text = groupDecimal(
          trimNum(sms.originalAmount?.toDouble()),
        );
      }
    }
    c.smsRememberAsk = _smsDraft?.canRememberCard ?? false;
    c.autoSource = e?.autoSource;
    c.isFixed = e?.isFixed ?? false;
    _input = c;
    _initialSig = _sig(c);
  }

  TxInput? get _inputOrNull {
    try {
      return _input;
    } catch (_) {
      return null;
    }
  }

  bool _dirty() => _sig(_input) != _initialSig;

  // ── 단계 ────────────────────────────────────────────────
  /// 기기 뒤로 가기 · Esc — 한 단계 안이면 그 단계만, 2단계면 1단계로(값은 버리지 않는다). 처음 단계면 시트의 닫는 길이 이어받는다.
  bool _intercept() {
    if (!mounted || _submitting) return _submitting;
    if (_isSub || _step == _S.presetAll) {
      _requestLeaveSub();
      return true;
    }
    if (_step == _S.two && _hasStepOne) {
      _goOne();
      return true;
    }
    return false;
  }

  void _goOne() {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = _S.one;
      _saveError = null;
    });
  }

  void _openSub(_S step, {FocusNode? focus}) {
    FocusScope.of(context).unfocus();
    _returnTo = _step;
    _snap = {
      'amount': _input.amountCtrl.text,
      'orig': _input.origAmountCtrl.text,
      'fx': _input.fxRateCtrl.text,
      'cur': _input.currencyPick ?? '',
      'memo': _input.memoCtrl.text,
      'fee': _input.feeCtrl.text,
      'interest': _input.interestCtrl.text,
      'presetAmount': _presetAmountCtrl.text,
    };
    _subSig = _snap!.values.join('|');
    setState(() => _step = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _step == step) (focus ?? _subFocus).requestFocus();
    });
  }

  bool _subDirty() => switch (_step) {
    _S.amount || _S.krw || _S.memo || _S.fee || _S.interest =>
      [
            _input.amountCtrl.text,
            _input.origAmountCtrl.text,
            _input.fxRateCtrl.text,
            _input.currencyPick ?? '',
            _input.memoCtrl.text,
            _input.feeCtrl.text,
            _input.interestCtrl.text,
            _presetAmountCtrl.text,
          ].join('|') !=
          _subSig,
    _S.presetAmount => _presetAmountCtrl.text != (_snap?['presetAmount'] ?? ''),
    _ => false,
  };

  /// "완료" — 친 값을 넣고 연 단계로 돌아간다.
  void _doneSub() {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _errs = _Errs();
      _step = _returnTo;
    });
  }

  /// ← · 뒤로 가기 — 친 값을 버리고 연 단계로. 바뀐 값이 있으면 먼저 "작성한 내용이 사라져요".
  Future<void> _requestLeaveSub() async {
    if (_leaving || _submitting) return;
    if (!_subDirty()) {
      _leaveSub();
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
    if (leave && mounted) _leaveSub();
  }

  void _leaveSub() {
    final s = _snap;
    if (s != null) {
      _input.amountCtrl.text = s['amount']!;
      _input.origAmountCtrl.text = s['orig']!;
      _input.fxRateCtrl.text = s['fx']!;
      _input.currencyPick = s['cur']!.isEmpty ? null : s['cur'];
      _input.memoCtrl.text = s['memo']!;
      _input.feeCtrl.text = s['fee']!;
      _input.interestCtrl.text = s['interest']!;
      _presetAmountCtrl.text = s['presetAmount']!;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _step = _step == _S.presetAll ? _S.one : _returnTo;
      _errs = _Errs();
    });
  }

  // ── 값 바꿈 ─────────────────────────────────────────────
  void _clearPresetMark() {
    if (_appliedPresetId == null && _emptyPresetName == null) return;
    _appliedPresetId = null;
    _emptyPresetName = null;
  }

  void _setType(String v, List<ExpenseCategory>? cats) {
    if (_typeLocked || _input.type == v) return;
    setState(() {
      _input.type = v;
      // 종류를 바꾸면 안 맞는 카테고리는 놓는다(서버가 종류≠카테고리 종류를 400 으로 막는다)
      if (cats != null) {
        final cat = cats
            .where((x) => x.rowId == _input.categoryRowId)
            .firstOrNull;
        if (cat == null || cat.expenseType != v) _input.categoryRowId = null;
      }
      if (v == 'TRANSFER') {
        // 이체에는 통화 칩이 없다 — 원화 값으로
        _toKrw();
      }
      _clearPresetMark();
      _errs = _Errs();
    });
  }

  /// 원화로 — 외화 입력을 지우고 현지 금액이 있었으면 원화 금액으로 이어 받는다.
  void _toKrw({bool keepEntry = true}) {
    final c = _input;
    final carried = c.origAmountCtrl.text.replaceAll(',', '');
    c.currencyPick = kDefaultCurrency;
    if (keepEntry && carried.isNotEmpty) {
      final n = double.tryParse(carried);
      if (n != null) c.amountCtrl.text = groupWon(n.round());
    }
    c.origAmountCtrl.clear();
    c.fxRateCtrl.clear();
  }

  /// 통화 칩으로 통화를 바꾼다 — 원화 → 외화: 친 값이 현지 금액이 되고 원화 금액은 환율이 들어올 때 채운다 · 외화 → 원화: 친 값이 원화 금액이 된다.
  void _pickCurrency(String code) {
    final c = _input;
    final wasForeign = c.isForeignTx;
    setState(() {
      if (!isForeignCurrency(code)) {
        if (wasForeign) _toKrw();
        c.currencyPick = code;
      } else {
        if (!wasForeign) {
          c.origAmountCtrl.text = c.amountCtrl.text; // 쉼표 그대로(읽을 때 뗀다)
          c.amountCtrl.clear();
        }
        c.currencyPick = code;
        fillKrwFromForeign(c);
      }
      _clearPresetMark();
      _errs = _Errs();
    });
  }

  // ── 프리셋 ──────────────────────────────────────────────
  /// 프리셋 칩 · 모두 보기 — 값을 채운다. 금액이 있는 프리셋은 2단계로, 금액이 빈 프리셋은 1단계에 남아 금액 칸에 초점(Q4 B).
  /// 프리셋 금액은 채운 값일 뿐이다 — 금액 칸을 잠그지 않는다(Q7 A).
  void _applyPreset(ExpenseTemplate p) {
    final c = _input;
    final fixed = (p.lockAmount ?? 'N') == 'Y' && (p.amount ?? 0) > 0;
    setState(() {
      _appliedPresetId = p.rowId;
      c.type = p.expenseType;
      // 프리셋에는 통화가 없다 — 칩은 ₩ KRW
      c.currencyPick = kDefaultCurrency;
      c.origAmountCtrl.clear();
      c.fxRateCtrl.clear();
      c.amountCtrl.text = fixed ? groupWon(p.amount ?? 0) : '';
      c.categoryRowId = p.categoryRowId;
      c.assetRowId = p.assetRowId;
      c.memoCtrl.text = p.description ?? '';
      c.merchantCtrl.text = p.merchant ?? '';
      c.paymentMethod = p.paymentMethod ?? '';
      c.toAssetRowId = p.toAssetRowId;
      c.feeCtrl.text = p.fee != null ? groupWon(p.fee!) : '';
      c.interestCtrl.text = p.interestAmount != null
          ? '${p.interestAmount}'
          : '';
      c.isFixed = p.expenseType == 'TRANSFER' ? false : p.isFixed;
      _emptyPresetName = fixed ? null : p.templateName;
      _errs = _Errs();
      _saveError = null;
      _step = fixed ? _S.two : _S.one;
    });
    if (!fixed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step == _S.one) _amountFocus.requestFocus();
      });
    }
  }

  /// 적용한 칩을 다시 누르면 표시만 지운다(값은 그대로 · 저장 때 사용 기록을 보내지 않는다).
  void _onPresetTap(ExpenseTemplate p) {
    if (_appliedPresetId == p.rowId) {
      setState(() {
        _appliedPresetId = null;
        _emptyPresetName = null;
      });
      return;
    }
    _applyPreset(p);
  }

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

  // ── 고르기 시트 ─────────────────────────────────────────
  /// 고르기 시트의 틀 — 목록형(카테고리 · 계좌 · 할부 · 통화)은 끝 흐림을 켜고, 줄이 정해진 고정형(결제 수단)은 끈다.
  Future<T?> _sheet<T>(String title, Widget body, {bool fog = true}) =>
      PBottomSheet.show<T>(
        context,
        builder: (ctx) => PBottomSheetContent(
          title: title,
          closeLabel: AppLocalizations.of(ctx).actionClose,
          flushBody: true,
          scrollFog: fog,
          body: body,
        ),
      );

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final v = await _sheet<int>(
      l.expCategory,
      _CategoryPickBody(kind: _input.type, selected: _input.categoryRowId),
    );
    if (v == null || !mounted) return;
    setState(() {
      _input.categoryRowId = v;
      _errs.category = null;
      _clearPresetMark();
    });
  }

  Future<void> _pickAsset({required bool income, bool to = false}) async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final c = _input;
    final assets = ref.read(assetsProvider).value ?? const <Asset>[];
    final bool transfer = c.type == 'TRANSFER';
    final List<Asset> list;
    if (transfer) {
      list = [
        for (final a in transferEligibleAssets(assets))
          if (!to ? true : a.rowId != c.assetRowId) a,
      ];
    } else {
      list = [
        for (final a in assets)
          if (allowTxAsset(a, c.paymentMethod, c.type)) a,
      ];
    }
    final title = transfer
        ? (to ? l.transferToLabel : l.transferFromLabel)
        : (income ? l.expDepositAccount : l.expAccountCard);
    final selected = transfer
        ? (to ? c.toAssetRowId : c.assetRowId)
        : (c.assetRowId ?? -1);
    final v = await _sheet<int>(
      title,
      _AssetPickBody(
        assets: list,
        selected: selected,
        label: title,
        withNone: !transfer,
        noneLabel: l.txfNoAccountOption,
        emptyText: !transfer && c.paymentMethod.isNotEmpty && list.isEmpty
            ? l.txfNoPickableAsset
            : null,
        failed:
            ref.read(assetsProvider).hasError &&
            !ref.read(assetsProvider).hasValue,
        failedText: l.txfAssetLoadFailed,
        onRetry: () => ref.invalidate(assetsProvider),
      ),
    );
    if (v == null || !mounted) return;
    setState(() {
      if (transfer) {
        if (to) {
          c.toAssetRowId = v;
          // 받는 자산이 대출이 아니게 되면 이자는 버린다
          if (!isLoanTarget(assets, v)) c.interestCtrl.clear();
          _errs.to = null;
        } else {
          c.assetRowId = v;
          if (c.toAssetRowId == v) c.toAssetRowId = null;
          _errs.from = null;
        }
      } else {
        c.assetRowId = v == -1 ? null : v;
      }
      _clearPresetMark();
    });
  }

  Future<void> _pickMethod() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final c = _input;
    final title = c.type == 'INCOME' ? l.expIncomeMethod : l.expPaymentMethod;
    final v = await _sheet<String>(
      title,
      PickList<String>(
        label: title,
        selected: c.paymentMethod,
        items: [
          PickItem(value: '', title: l.txfNoMethodOption),
          for (final code in kTxPaymentMethodCodes)
            PickItem(value: code, title: txPaymentMethodLabel(l, code)),
        ],
      ),
      fog: false,
    );
    if (v == null || !mounted) return;
    final assets = ref.read(assetsProvider).value ?? const <Asset>[];
    setState(() {
      c.paymentMethod = v;
      if (v.isNotEmpty && c.assetRowId != null) {
        final cur = assets.where((a) => a.rowId == c.assetRowId).firstOrNull;
        if (cur != null && !allowTxAsset(cur, v, c.type)) c.assetRowId = null;
      }
      _clearPresetMark();
    });
  }

  Future<void> _pickInstallment() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final v = await _sheet<int>(
      l.expInstallment,
      PickList<int>(
        label: l.expInstallment,
        selected: _input.installmentMonths,
        items: [
          PickItem(value: 0, title: l.expLumpSum),
          for (final m in kTxInstallmentMonths)
            PickItem(value: m, title: l.expInstallmentMonths(m)),
        ],
      ),
    );
    if (v == null || !mounted) return;
    setState(() {
      _input.installmentMonths = v;
      _clearPresetMark();
    });
  }

  Future<void> _pickCurrencyChip() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final v = await _sheet<String>(
      l.expCurrency,
      PickList<String>(
        label: l.expCurrency,
        selected: _input.currency,
        items: [
          for (final cur in kCurrencies)
            PickItem(value: cur.code, title: '${cur.symbol} ${cur.code}'),
        ],
      ),
    );
    if (v == null || !mounted) return;
    _pickCurrency(v);
  }

  Future<void> _pickDay() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final picked = await showCalendarDaySheet(
      context,
      title: l.expDate,
      value: _input.date,
      today: calendarNow(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _input.date = DateTime(picked.year, picked.month, picked.day);
      _clearPresetMark();
    });
  }

  Future<void> _pickTime() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final t = _input.time;
    final picked = await showCalendarTimeSheet(
      context,
      title: l.txfTimeTitle,
      value: roundTimeToStep(PTimeValue(t.hour, t.minute), 5),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _input.time = TimeOfDay(hour: picked.hour, minute: picked.minute),
    );
  }

  // ── 문자 단계 ───────────────────────────────────────────
  Future<void> _readSms() async {
    final text = _smsCtrl.text.trim();
    if (_smsBusy) return;
    final l = AppLocalizations.of(context);
    if (text.isEmpty || !looksLikePaymentSms(text)) {
      setState(() => _smsError = l.smsNotRecognized);
      return;
    }
    setState(() {
      _smsBusy = true;
      _smsError = null;
    });
    try {
      final repo = await ref.read(smsRepositoryProvider.future);
      final parsed = await repo.parse(text, silent: true);
      if (!mounted) return;
      if (!parsed.matched) {
        setState(() => _smsError = l.smsNotRecognized);
        return;
      }
      if (parsed.cancel) {
        setState(() => _smsError = l.smsCancelNotice);
        return;
      }
      // 성공 — 같은 값으로 채우고 2단계로(금액은 늘 채워진다)
      setState(() {
        _smsDraft = SmsDraft(text: text, parsed: parsed);
        _clearPresetMark();
        _seed();
        _initialSig = _sig(_input);
        _smsLow = parsed.isLowConfidence;
        _errs = _Errs();
        _step = _S.two;
      });
    } on ApiException {
      if (!mounted) return;
      // 서버 글은 내지 않는다 — 우리 글만
      setState(() => _smsError = l.smsParseFailed);
    } finally {
      if (mounted) setState(() => _smsBusy = false);
    }
  }

  // ── 프리셋 저장 단계 ────────────────────────────────────
  void _openPresetSave() {
    final c = _input;
    final merchant = c.type == 'TRANSFER' ? '' : c.merchantCtrl.text.trim();
    final name = merchant.length > _kPresetNameMax
        ? merchant.substring(0, _kPresetNameMax)
        : merchant;
    _presetNameCtrl.text = name;
    _presetAmountCtrl.text = groupWon(c.amountInt);
    _presetNameError = null;
    _presetFormError = null;
    _presetNameGen++;
    _openSub(_S.presetSave, focus: _subFocus);
  }

  Future<void> _savePreset() async {
    if (_presetSaving) return;
    final l = AppLocalizations.of(context);
    final c = _input;
    final isTransfer = c.type == 'TRANSFER';
    String? formError;
    if (isTransfer) {
      if (!transferPartiesReady(c.assetRowId, c.toAssetRowId)) {
        formError = l.txfPresetNeedParties;
      }
    } else if (c.categoryRowId == null) {
      formError = l.txfPresetNeedCategory;
    }
    final taken = [
      for (final p
          in ref.read(presetListProvider).value ?? const <ExpenseTemplate>[])
        p.templateName,
    ];
    final issue = nameIssue(_presetNameCtrl.text, _kPresetNameMax, taken);
    final nameError = switch (issue) {
      NameIssue.required => l.txfPresetNameRequired,
      NameIssue.tooLong => l.txfPresetNameTooLong,
      NameIssue.duplicate => l.presetNameDuplicate,
      null => null,
    };
    setState(() {
      _presetFormError = formError;
      _presetNameError = nameError;
    });
    if (formError != null || nameError != null) return;
    final amount = parseAmountInput(_presetAmountCtrl.text) ?? 0;
    final lock = amount > 0;
    setState(() {
      _presetSaving = true;
      _saveError = null;
    });
    final name = _presetNameCtrl.text.trim();
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      await repo.create(
        templateName: name,
        categoryRowId: isTransfer ? null : c.categoryRowId,
        assetRowId: c.assetRowId,
        toAssetRowId: isTransfer ? c.toAssetRowId : null,
        fee: isTransfer ? c.feeOrNull : null,
        // 이자는 금액을 따라간다 — 금액을 안 저장하면 이자도 안 저장한다
        interestAmount: isTransfer && lock ? c.interestOrNull : null,
        expenseType: c.type,
        amount: lock ? amount : 0,
        description: c.memoCtrl.text.trim().isEmpty
            ? null
            : c.memoCtrl.text.trim(),
        merchant: isTransfer || c.merchantCtrl.text.trim().isEmpty
            ? null
            : c.merchantCtrl.text.trim(),
        paymentMethod: isTransfer || c.paymentMethod.isEmpty
            ? null
            : c.paymentMethod,
        lockAmount: lock,
        isFixed: !isTransfer && c.isFixed,
        silent: true,
      );
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      setState(() => _step = _returnTo);
      showPSnackBar(
        hostContextOf(context),
        l.txfPresetSaved(name),
        severity: PSnackSeverity.success,
      );
    } on ApiException {
      if (!mounted) return;
      // 고칠 수 있는 서버 거절(이름 중복 등)은 위에서 먼저 막았다 — 남는 건 우리 글
      setState(() => _presetFormError = l.txfSaveFailed);
    } finally {
      if (mounted) setState(() => _presetSaving = false);
    }
  }

  // ── 검증 · 저장 ─────────────────────────────────────────
  _Errs _validate() {
    final l = AppLocalizations.of(context);
    final c = _input;
    final e = _Errs();
    final isTransfer = c.type == 'TRANSFER';
    final foreign = c.isForeignTx;
    if (foreign) {
      if ((c.origAmountOrNull ?? 0) <= 0) e.amount = l.txfEntryRequired;
    } else if (c.amountInt <= 0) {
      e.amount = l.txfEntryRequired;
    }
    if (foreign && e.amount == null && c.amountInt <= 0) {
      e.fx = l.txfErrFx;
    }
    if (c.amountInt > kAmountMax) e.krw = l.txfAmountTooLarge;
    if (isTransfer) {
      if (c.assetRowId == null) e.from = l.txfErrFrom;
      if (c.toAssetRowId == null || c.toAssetRowId == c.assetRowId) {
        e.to = l.txfErrTo;
      }
      final interest = c.interestOrNull;
      if (showTxInterest(c, ref.read(assetsProvider).value) &&
          interest != null &&
          interest > c.amountInt) {
        e.interest = l.txfErrInterest;
      }
    } else if (c.categoryRowId == null) {
      e.category = l.txfErrCategory;
    }
    if (_splitsPending) e.splits = l.txfSplitsLoading;
    return e;
  }

  /// [다음] — 금액이 비면 칸 아래 오류, 아니면 2단계로.
  void _next() {
    final l = AppLocalizations.of(context);
    final c = _input;
    final foreign = c.isForeignTx;
    final empty = foreign ? (c.origAmountOrNull ?? 0) <= 0 : c.amountInt <= 0;
    if (empty) {
      setState(() => _errs.amount = l.txfEntryRequired);
      _amountFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _errs = _Errs();
      _emptyPresetName = null;
      _step = _S.two;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _step == _S.two && _startedAtOne && _smsDraft == null) {
        _merchantFocus.requestFocus();
      }
    });
  }

  Future<void> _save() async {
    if (_submitting) return;
    final errs = _validate();
    if (errs.any) {
      setState(() {
        _errs = errs;
        // 오류가 2단계 밖(1단계 금액)이면 그 단계로 돌아가 그 칸에 초점
        if (errs.amount != null && _hasStepOne && _step == _S.two) {
          _step = _S.one;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _amountFocus.requestFocus();
          });
        }
      });
      return;
    }
    // 분할이 금액과 어긋나면 먼저 맞추게 한다 — 맞추기 단계에서 저장
    if (_splitMismatch) {
      _openReconcile();
      return;
    }
    setState(() => _errs = _Errs());
    await _submit();
  }

  /// 저장 실패 — 웹과 같은 한 글(서버 원문 없음). 확인창을 거친 저장의 실패도 보이게 본문을 맨 위로 올린다.
  void _failSave(ApiException e) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    setState(() => _saveError = l.txfSaveFailed);
    scrollSheetBodyToTop(context);
  }

  Future<void> _submit() async {
    final c = _input;
    final amount = c.amountInt;
    final dateStr = '${c.isoDate}T${_formatTime(c.time)}:00';
    final desc = c.memoOrNull;
    final merchant = c.merchantOrNull;
    final payment = c.paymentMethodOrNull;
    final installment = c.installmentMonths > 1 ? c.installmentMonths : null;
    final origAmount = c.origAmountOrNull;
    final origCurrency = origAmount != null ? c.currency : null;
    final fxRate = origAmount != null ? c.fxRateOrNull : null;
    final d = c.date;

    if (c.type == 'TRANSFER') {
      await _submitTransfer(amount: amount, dateStr: dateStr, desc: desc);
      return;
    }
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
    // 결제가 끝난 회차로 가는 저장이면 먼저 한 번 묻는다 — 기록만 바뀌고 계좌 잔액은 그대로다(D1)
    if (!await _confirmClosedCycleSave(installment: installment)) return;
    if (!mounted) return;

    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      Expense? savedEdit;
      final edited = _edit;
      if (edited != null) {
        final locked = c.moneyLocked;
        final saved = await repo.update(
          id: edited.rowId,
          categoryRowId: c.categoryRowId!,
          assetRowId: locked ? const Patch.keep() : Patch.set(c.assetRowId),
          expenseType: locked ? edited.expenseType : c.type,
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
          isFixed: Patch.set(c.isFixed),
          splits: locked ? null : _reconciledSplits,
          silent: true,
        );
        savedEdit = saved;
        if (mounted) {
          showChangeResultToast(
            hostContextOf(context),
            refundedAmount: saved.refundedAmount,
          );
        }
        ref.invalidate(expenseSplitsProvider(edited.rowId));
      } else if (_smsDraft != null) {
        final smsRepo = await ref.read(smsRepositoryProvider.future);
        final committed = await smsRepo.commit(
          text: _smsDraft!.text,
          assetRowId: c.assetRowId,
          categoryRowId: c.categoryRowId,
          expenseType: c.type,
          amount: amount,
          merchant: merchant,
          description: desc,
          expenseDate: dateStr,
          paymentMethod: payment,
          installmentMonths: installment,
          originalAmount: origAmount,
          originalCurrency: origCurrency,
          exchangeRate: fxRate,
          rememberCard: c.assetRowId != null && c.smsRememberCard,
          silent: true,
        );
        _notifyCreated(refundedAmount: committed.refundedAmount);
        final inboxId = _smsDraft!.inboxId;
        if (inboxId != null) {
          try {
            await SmsAndroid.removeFromInbox(inboxId);
          } catch (_) {
            /* 보관함 정리 실패는 저장 결과를 바꾸지 않는다 */
          }
        }
      } else {
        final created = await repo.create(
          categoryRowId: c.categoryRowId!,
          assetRowId: c.assetRowId,
          expenseType: c.type,
          amount: amount,
          expenseDate: dateStr,
          description: desc,
          merchant: merchant,
          paymentMethod: payment,
          installmentMonths: installment,
          originalAmount: origAmount,
          originalCurrency: origCurrency,
          exchangeRate: fxRate,
          isFixed: c.isFixed,
          silent: true,
        );
        _notifyCreated(refundedAmount: created.refundedAmount);
      }
      await _touchAppliedPreset();
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
      // 상세로 돌아가는 길이면 목록을 다시 받은 다음 단계를 옮긴다 — 돌아간 상세가 옛 값을 먼저 그리지 않게(I-21 ⑧)
      if (savedEdit != null && widget.onSaved != null) {
        await _refetchMonth(d.year, d.month);
      }
      if (!mounted) return;
      if (savedEdit != null && widget.onSaved != null) {
        await widget.onSaved!(savedEdit);
        return;
      }
      widget.onFinished?.call();
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      _failSave(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitTransfer({
    required int amount,
    required String dateStr,
    String? desc,
  }) async {
    final c = _input;
    final d = c.date;
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      final fee = int.tryParse(c.feeCtrl.text.replaceAll(',', ''));
      final interest = showTxInterest(c, ref.read(assetsProvider).value)
          ? int.tryParse(c.interestCtrl.text.replaceAll(',', ''))
          : null;
      final aRepo = await ref.read(assetRepositoryProvider.future);
      final editing = widget.editTransfer;
      AssetTransfer? savedTransfer;
      if (editing != null) {
        await aRepo.updateTransfer(
          rowId: editing.rowId,
          fromAssetRowId: c.assetRowId!,
          toAssetRowId: c.toAssetRowId!,
          amount: amount,
          fee: fee,
          interestAmount: interest,
          description: desc,
          transferDate: dateStr,
          silent: true,
        );
        if (widget.onTransferSaved != null) {
          final assets = ref.read(assetsProvider).value;
          savedTransfer = AssetTransfer(
            rowId: editing.rowId,
            userRowId: editing.userRowId,
            fromAssetRowId: c.assetRowId!,
            fromAssetName: assets?.byRowId(c.assetRowId!)?.assetName,
            toAssetRowId: c.toAssetRowId!,
            toAssetName: assets?.byRowId(c.toAssetRowId!)?.assetName,
            amount: amount,
            fee: fee,
            interestAmount: interest,
            autoSource: editing.autoSource,
            principalAmount: amount - (interest ?? 0),
            description: desc,
            transferDate: dateStr,
            createAt: editing.createAt,
          );
        }
      } else {
        await aRepo.createTransfer(
          fromAssetRowId: c.assetRowId!,
          toAssetRowId: c.toAssetRowId!,
          amount: amount,
          fee: fee,
          interestAmount: interest,
          description: desc,
          transferDate: dateStr,
          silent: true,
        );
      }
      ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
      invalidateAfterExpenseChange(ref);
      await _touchAppliedPreset();
      if (savedTransfer != null) await _refetchMonth(d.year, d.month);
      if (!mounted) return;
      if (savedTransfer != null && widget.onTransferSaved != null) {
        await widget.onTransferSaved!(savedTransfer);
        return;
      }
      widget.onFinished?.call();
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      _failSave(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refetchMonth(int year, int month) async {
    try {
      await ref.read(monthExpensesProvider((year: year, month: month)).future);
    } catch (_) {
      // 받지 못해도 돌아간다
    }
  }

  void _notifyCreated({required int? refundedAmount}) {
    if (!mounted) return;
    showChangeResultToast(
      hostContextOf(context),
      refundedAmount: refundedAmount,
      fixBalanceAssetId: null,
    );
  }

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
    final c = _input;
    final original = _replaceOf!;
    final l = AppLocalizations.of(context);
    final assets = ref.read(assetsProvider).value ?? const <Asset>[];
    Asset? assetOf(int? id) => id == null ? null : assets.byRowId(id);
    final ok = await PAlertDialog.show(
      context,
      title: l.expRewrite,
      description: rewriteConfirmMessage(
        l,
        newAsset: assetOf(c.assetRowId),
        dateKey: c.isoDate,
        installmentMonths: installment,
      ),
      actionLabel: l.actionSave,
      cancelLabel: l.actionCancel,
    );
    if (!ok || !mounted) return;
    final host = hostContextOf(context);
    final fixBalance = fixBalanceTargetOf(
      original,
      assetOf(original.assetRowId),
    );

    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final splits = _effectiveSplits.isEmpty ? null : _effectiveSplits;
      final saved = await repo.replace(
        original.rowId,
        categoryRowId: c.categoryRowId!,
        assetRowId: c.assetRowId,
        expenseType: c.type,
        amount: amount,
        expenseDate: dateStr,
        description: desc,
        merchant: merchant,
        paymentMethod: payment,
        installmentMonths: installment,
        originalAmount: origAmount,
        originalCurrency: origCurrency,
        exchangeRate: fxRate,
        isFixed: c.isFixed,
        splits: splits,
        silent: true,
      );
      final origDate = original.expenseDate;
      if (origDate != null && origDate.length >= 10) {
        final o = parseIsoDate(origDate.substring(0, 10));
        ref.invalidate(monthExpensesProvider((year: o.year, month: o.month)));
      }
      final d = c.date;
      ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
      ref.invalidate(expenseSplitsProvider(original.rowId));
      ref.invalidate(expenseSplitsProvider(saved.rowId));
      invalidateAfterExpenseChange(ref);
      // 옛 거래가 지워졌으니 돌아갈 상세가 없다 — 모두 닫는다
      widget.onFinished?.call();
      if (mounted) PBottomSheet.of(context).close();
      if (host.mounted) {
        showChangeResultToast(
          host,
          refundedAmount: saved.refundedAmount,
          fixBalanceAssetId: fixBalance,
        );
      }
    } on ApiException catch (e) {
      // 404 = 옛 거래가 이미 없다 — 교체는 앞선 요청에서 끝났다. 목록을 다시 읽게 하고 닫는다(QA 26 5).
      if (e.statusCode == 404) {
        ref.invalidate(monthExpensesProvider);
        ref.invalidate(expenseSplitsProvider(original.rowId));
        invalidateAfterExpenseChange(ref);
        widget.onFinished?.call();
        if (mounted) PBottomSheet.of(context).close();
      } else {
        _failSave(e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// [고쳐 쓰기] — 이 시트를 새 거래 모드로 갈아 끼운다(새 시트를 띄우지 않는다, D13).
  void _openRewrite() {
    final e = _edit;
    if (e == null) return;
    setState(() {
      _replaceOf = e;
      _edit = null;
      _startedAtOne = false;
      _seed();
      _reconciledSplits = null;
      _errs = _Errs();
      _saveError = null;
      _step = _S.two;
    });
  }

  Future<bool> _confirmClosedCycleSave({int? installment}) async {
    final c = _input;
    if (c.type == 'TRANSFER') return true;
    if (_edit != null && c.moneyLocked) return true;
    final id = c.assetRowId;
    if (id == null) return true;
    final asset = (ref.read(assetsProvider).value ?? const <Asset>[]).byRowId(
      id,
    );
    final l = AppLocalizations.of(context);
    final note = closedCycleNote(
      l,
      closedCycleSpanFor(
        asset,
        dateKey: c.isoDate,
        installmentMonths: installment,
      ),
    );
    if (note == null) return true;
    return PAlertDialog.show(
      context,
      title: _edit != null ? l.expEdit : l.expSaveConfirmTitle,
      description: note,
      actionLabel: l.actionSave,
      cancelLabel: l.actionCancel,
    );
  }

  /// "나눈 내역 맞추기" — 21-3 까지 폼 위 대화상자(시트)로 둔다.
  void _openReconcile() {
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
      },
    );
  }

  // ── 그리기 ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _input;
    // 설정의 기본 통화를 매 빌드 흘려 넣는다(D7 · QA #124)
    c.defaultCurrency = ref.watch(defaultCurrencyProvider);

    // 돈 칸 잠금(D12)
    final edited = _edit;
    final lockAssetId = edited?.assetRowId;
    c.moneyLocked =
        edited != null &&
        moneyLockedOf(
          edited,
          lockAssetId == null
              ? null
              : ref.watch(assetsProvider).value?.byRowId(lockAssetId),
        );

    // 분할 적재 — 금액 ↔ 분할 합 어긋남 판정
    final source = _splitSource;
    if (source != null) {
      final spAsync = ref.watch(expenseSplitsProvider(source.rowId));
      _splitsPending =
          (_isReplace || _edit != null) &&
          spAsync.isLoading &&
          !spAsync.hasValue &&
          !spAsync.hasError;
      final sp = spAsync.value;
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

    return switch (_step) {
      _S.one => _buildOne(l),
      _S.two => _buildTwo(l),
      _S.amount || _S.krw || _S.presetAmount => _buildAmountSub(l),
      _S.memo => _buildMemoSub(l),
      _S.fee || _S.interest => _buildMoneySub(l),
      _S.sms => _buildSms(l),
      _S.presetAll => _buildPresetAll(l),
      _S.presetSave => _buildPresetSave(l),
    };
  }

  String get _typeName {
    final l = AppLocalizations.of(context);
    return switch (_input.type) {
      'INCOME' => l.expTypeIncome,
      'TRANSFER' => l.expTypeTransfer,
      _ => l.expTypeExpense,
    };
  }

  /// 머리 제목 속 금액 — 외화면 "$5.50", 원화면 "10,000원".
  String _titleAmount() {
    final l = AppLocalizations.of(context);
    final c = _input;
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(c.type);
    if (masked) return '••••${wonUnit()}';
    if (c.isForeignTx) {
      final a = c.origAmountOrNull;
      if (a != null && a > 0) {
        return formatOriginalAmount(
          a,
          c.currency,
          Localizations.localeOf(context).toString(),
        );
      }
    }
    final v = c.amountInt;
    if (v <= 0) return l.txfNone;
    // 쉼표 뒤에서만 줄을 바꾼다 — 숫자 중간 · 쉼표 앞에서 자르지 않는다
    return krwSigned(v, false, unit: true).replaceAll(',', '\u2060,\u200B');
  }

  PBottomSheetContent _frame({
    required String title,
    required Widget body,
    String? eyebrow,
    VoidCallback? onBack,
    Widget? headerAction,
    bool showClose = true,
    List<PButton> footer = const [],
    Key? key,
  }) {
    final l = AppLocalizations.of(context);
    return PBottomSheetContent(
      key: key,
      title: title,
      eyebrow: eyebrow,
      closeLabel: l.actionClose,
      showCloseButton: showClose,
      // 닫기 원은 한 단계가 아니라 시트 전체(← · 뒤로 가기가 한 단계)
      onClose: () => PBottomSheet.of(context).requestClose(wholeSheet: true),
      onBack: onBack,
      backLabel: onBack == null ? null : l.actionBack,
      headerAction: headerAction,
      flushBody: true,
      scrollFog: true,
      body: body,
      footer: footer,
    );
  }

  Widget _doneAction(AppLocalizations l) =>
      CalendarStepDone(label: l.actionDone, onPressed: _doneSub);

  /// 저장 실패 Callout — 폼 맨 위(우리 글).
  Widget _failureCallout() => _saveError == null
      ? const SizedBox.shrink()
      : CalendarSaveErrorCallout(message: _saveError!);

  Widget _currencyChip(AppLocalizations l) {
    final c = _input;
    final cur = kCurrencies.firstWhere(
      (x) => x.code == c.currency,
      orElse: () => CurrencyOption(c.currency, c.currency),
    );
    return PChip(
      key: const ValueKey('tx-currency-chip'),
      label: '${cur.symbol} ${cur.code}',
      size: PChipSize.small,
      variant: PChipVariant.solid,
      suffixIcon: LucideIcons.chevronDown,
      semanticLabel: l.txfCurrencyChip(cur.code),
      onPressed: _pickCurrencyChip,
    );
  }

  // ── 1단계 ───────────────────────────────────────────────
  Widget _typeChips(AppLocalizations l, List<ExpenseCategory>? cats) {
    final c = _input;
    final types = <(String, String)>[
      ('EXPENSE', l.expTypeExpense),
      ('INCOME', l.expTypeIncome),
      ('TRANSFER', l.expTypeTransfer),
    ];
    // 이체 수정은 이체 칩 하나(웹과 같다)
    if (widget.editTransfer != null) {
      types.removeWhere((t) => t.$1 != 'TRANSFER');
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x1,
        PSpacing.globalGutter,
        PSpacing.x2,
      ),
      child: Semantics(
        container: true,
        label: l.txfTypeGroup,
        child: Wrap(
          spacing: PSpacing.x2,
          runSpacing: PSpacing.x2,
          children: [
            for (final (code, label) in types)
              // 막힌 칩은 보이되 비활성이다(웹과 같다) — 수정은 지금 종류만, 문자 초안 · 고쳐 쓰기는 이체가 막힌다
              PChip(
                key: ValueKey('tx-type-$code'),
                label: label,
                variant: PChipVariant.outlineStrong,
                selected: c.type == code,
                onPressed:
                    (_typeLocked && code != c.type) ||
                        ((_isSms || _isReplace) && code == 'TRANSFER')
                    ? null
                    : () => _setType(code, cats),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOne(AppLocalizations l) {
    final c = _input;
    final cats = ref.watch(categoriesProvider);
    final presetsAsync = ref.watch(presetListProvider);
    final mine = [
      for (final p in presetsAsync.value ?? const <ExpenseTemplate>[])
        if (p.expenseType == c.type) p,
    ]..sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
    final applied = mine.where((p) => p.rowId == _appliedPresetId).firstOrNull;
    final foreign = c.isForeignTx;
    return _frame(
      key: const ValueKey('tx-step-one'),
      title: l.expAdd,
      eyebrow: l.txfStepMeta('1', '2'),
      footer: [
        PButton(
          label: l.actionNext,
          size: PButtonSize.large,
          onPressed: _submitting ? null : _next,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _typeChips(l, cats.value),
          TxUnderlineAmount(
            controller: foreign ? c.origAmountCtrl : c.amountCtrl,
            focusNode: _amountFocus,
            semanticLabel: l.expAmount,
            decimal: foreign,
            formatters: foreign
                ? const [DecimalFormatter(maxFrac: 2)]
                : kWonFormatters,
            suffixText: wonUnit(),
            // 이체에는 통화 칩이 없다
            chip: c.type == 'TRANSFER' ? null : _currencyChip(l),
            invalid: _errs.amount != null,
            errorMessage: _errs.amount,
            hintMessage: _emptyPresetName == null
                ? null
                : l.txfEmptyPresetHint(_emptyPresetName!),
            onChanged: (_) {
              if (foreign) fillKrwFromForeign(c);
              setState(() => _errs.amount = null);
            },
            onSubmitted: (_) => _next(),
          ),
          TxPresetBlock(
            title: applied == null
                ? l.txfPresetsTitle
                : l.txfPresetApplied(applied.templateName),
            presets: mine,
            categories: cats.value ?? const [],
            appliedId: _appliedPresetId,
            loadFailed: presetsAsync.hasError && !presetsAsync.hasValue,
            onTap: _onPresetTap,
            onSave: _openPresetSave,
            onShowAll: () => _openSub(_S.presetAll),
          ),
          // 결제 문자 줄 — 지출 · 새로 추가에서만
          if (_startedAtOne && c.type == 'EXPENSE')
            PList(
              children: [
                PListButtonItem(
                  key: const ValueKey('tx-sms-row'),
                  title: l.txfSmsStepTitle,
                  prefix: const Icon(LucideIcons.clipboardPaste, size: 22),
                  suffix: const ExcludeSemantics(
                    child: Icon(LucideIcons.chevronRight),
                  ),
                  onTap: () {
                    _smsError = null;
                    _openSub(_S.sms, focus: _smsFocus);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── 2단계 ───────────────────────────────────────────────
  Widget _buildTwo(AppLocalizations l) {
    final c = _input;
    final assetsAsync = ref.watch(assetsProvider);
    final assets = assetsAsync.value ?? const <Asset>[];
    final cats =
        ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];
    final isTransfer = c.type == 'TRANSFER';
    final isIncome = c.type == 'INCOME';
    final locked = c.moneyFieldsLocked;
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(c.type);

    final cat = c.categoryRowId == null ? null : cats.byRowId(c.categoryRowId!);
    String? catValue;
    Color? catDot;
    if (cat != null) {
      final parent = cat.parentRowId == null
          ? null
          : cats.byRowId(cat.parentRowId!);
      catValue = parent == null
          ? cat.categoryName
          : '${parent.categoryName} · ${cat.categoryName}';
      catDot = chartToneOf(context, cat.color).solid;
    }
    String assetName(int? id) {
      if (id == null) return '';
      final a = assets.byRowId(id);
      return a == null
          ? ''
          : (a.institution != null && a.institution!.isNotEmpty
                ? '${a.institution} · ${a.assetName}'
                : a.assetName);
    }

    final dayText = formatDateValue(c.date, calendarNow());
    final timeText = formatTimeValue(
      PTimeValue(c.time.hour, c.time.minute),
      labels: PTimePickerLabels.of(context),
    );
    final memoValue = c.memoCtrl.text.trim();

    // 제목 — 새로: "{종류} {금액}" · 수정: "거래 수정" · 고쳐 쓰기: "고쳐 쓰기"
    final String title;
    if (_isReplace) {
      title = l.expRewrite;
    } else if (_isEdit) {
      title = l.expEdit;
    } else {
      title = '$_typeName ${_titleAmount()}';
    }

    final mismatch = _splitMismatch;
    final saveLabel = mismatch
        ? l.txfSaveSplitAndSave
        : (_isEdit || _isReplace ? l.actionSave : l.expAddShort);

    Widget section(List<Widget> rows) => PList(children: rows);

    final fixedRows = <Widget>[];
    if (!_isSms && !isTransfer) {
      fixedRows.add(
        PListSwitchItem(
          key: const ValueKey('tx-fixed-switch'),
          title: isIncome ? l.fixedSwitchIncome : l.fixedSwitchExpense,
          detail: isIncome ? l.fixedHintIncome : l.fixedHintExpense,
          checked: c.isFixed,
          onChanged: (v) => setState(() {
            c.isFixed = v;
            _clearPresetMark();
          }),
        ),
      );
    }

    final foreign = c.isForeignTx;
    final fxHint =
        foreign &&
            (c.origAmountOrNull ?? 0) > 0 &&
            (c.fxRateOrNull ?? 0) > 0 &&
            c.amountInt > 0
        // 웹과 같다 — 마지막 값은 계산값이 아니라 원화 금액 줄의 값이다(카드사 청구액으로 고친 값이 그대로 보인다)
        ? l.txfFxHint(
            groupDecimal(trimNum(c.origAmountOrNull)),
            c.currency,
            groupDecimal(trimNum(c.fxRateOrNull)),
            krw(c.amountInt),
          )
        : null;

    return _frame(
      key: ValueKey(
        'tx-step-two-${_isEdit
            ? 'edit'
            : _isReplace
            ? 'replace'
            : 'new'}',
      ),
      title: title,
      eyebrow: _hasStepOne ? l.txfStepMeta('2', '2') : null,
      onBack: _hasStepOne
          ? _goOne
          : (_embedded
                ? () {
                    if (!_submitting) widget.onBack!();
                  }
                : null),
      footer: [
        PButton(
          label: saveLabel,
          size: PButtonSize.large,
          variant: !_isEdit && !_isReplace && !mismatch
              ? PButtonVariant.brandSolid
              : PButtonVariant.neutralSolid,
          loading: _submitting,
          onPressed: _submitting ? null : _save,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _failureCallout(),
          // 낮은 확신 문자 — 칸 위 안내
          if (_smsLow)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x3,
                PSpacing.globalGutter,
                0,
              ),
              child: PCallout(
                tone: PCalloutTone.warning,
                description: l.smsLowConfidence,
              ),
            ),
          if (_isEdit || _isReplace || _isSms) _typeChips(l, cats),
          if (_isEdit || _isReplace || _isSms) ..._amountRows(l, masked),
          if (!isTransfer) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x1,
                PSpacing.globalGutter,
                PSpacing.x4,
              ),
              child: PField(
                label: isIncome ? l.expIncomeSource : l.expPayee,
                child: PInput(
                  controller: c.merchantCtrl,
                  focusNode: _merchantFocus,
                  semanticLabel: isIncome ? l.expIncomeSource : l.expPayee,
                  placeholder: isIncome
                      ? l.expIncomeSourcePlaceholder
                      : l.expPayeePlaceholder,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  onChanged: (_) => setState(() => _clearPresetMark()),
                  // 한글 조합 중 Enter 는 저장이 아니라 글자 확정이다(L2)
                  onSubmitted: (_) {
                    if (c.merchantCtrl.value.composing.isValid &&
                        !c.merchantCtrl.value.composing.isCollapsed) {
                      return;
                    }
                    _save();
                  },
                ),
              ),
            ),
            if (foreign && !locked) ..._fxRows(l, fxHint),
          ],
          section([
            if (!isTransfer) ...[
              TxRow(
                key: const ValueKey('tx-row-category'),
                title: l.expCategory,
                icon: LucideIcons.tags,
                value: catValue,
                placeholder: l.txfNoCategory,
                dot: catDot,
                onTap: _pickCategory,
                errorMessage: _errs.category,
              ),
              TxRow(
                key: const ValueKey('tx-row-asset'),
                title: isIncome ? l.expDepositAccount : l.expAccountCard,
                icon: LucideIcons.wallet,
                value: assetName(c.assetRowId),
                placeholder: isIncome
                    ? l.txfNoDepositAccount
                    : l.txfNoAccountOption,
                locked: locked,
                onTap: () => _pickAsset(income: isIncome),
              ),
              TxRow(
                key: const ValueKey('tx-row-method'),
                title: isIncome ? l.expIncomeMethod : l.expPaymentMethod,
                icon: LucideIcons.creditCard,
                value: c.paymentMethod.isEmpty
                    ? null
                    : txPaymentMethodLabel(l, c.paymentMethod),
                placeholder: isIncome
                    ? l.txfNoIncomeMethod
                    : l.txfNoMethodOption,
                locked: locked,
                onTap: _pickMethod,
              ),
              if (showTxInstallment(c, assets))
                TxRow(
                  key: const ValueKey('tx-row-installment'),
                  title: l.expInstallment,
                  icon: LucideIcons.calendarDays,
                  value: c.installmentMonths > 1
                      ? (c.amountInt > 0
                            ? l.txfInstallmentValue(
                                '${c.installmentMonths}',
                                krw(c.amountInt ~/ c.installmentMonths),
                              )
                            : l.expInstallmentMonths(c.installmentMonths))
                      : l.expLumpSum,
                  locked: locked,
                  onTap: _pickInstallment,
                ),
              // 문자 카드 기억 — 계좌를 고르기 전에는 막힌 줄
              if (c.smsRememberAsk)
                PListCheckItem(
                  key: const ValueKey('tx-sms-remember'),
                  title: l.smsRememberCard,
                  checked: c.assetRowId != null && c.smsRememberCard,
                  onChanged: c.assetRowId == null
                      ? null
                      : (v) => setState(() => c.smsRememberCard = v),
                ),
            ] else ...[
              TxRow(
                key: const ValueKey('tx-row-from'),
                title: l.transferFromLabel,
                icon: LucideIcons.wallet,
                value: assetName(c.assetRowId),
                placeholder: l.txfSelectFrom,
                locked: locked,
                onTap: () => _pickAsset(income: false),
                errorMessage: _errs.from,
              ),
              TxRow(
                key: const ValueKey('tx-row-to'),
                title: l.transferToLabel,
                icon: LucideIcons.wallet,
                value: assetName(c.toAssetRowId),
                placeholder: l.txfSelectTo,
                locked: locked,
                onTap: () => _pickAsset(income: false, to: true),
                errorMessage: _errs.to,
              ),
              TxRow(
                key: const ValueKey('tx-row-fee'),
                title: l.expFee,
                icon: LucideIcons.percent,
                value: c.feeOrNull == null
                    ? null
                    : krwSigned(c.feeOrNull!, false, unit: true),
                placeholder: l.txfNone,
                chevron: true,
                onTap: () => _openSub(_S.fee),
              ),
              if (showTxInterest(c, assets))
                TxRow(
                  key: const ValueKey('tx-row-interest'),
                  title: l.expInterest,
                  icon: LucideIcons.percent,
                  value: c.interestOrNull == null
                      ? null
                      : krwSigned(c.interestOrNull!, false, unit: true),
                  placeholder: l.txfNone,
                  chevron: true,
                  onTap: () => _openSub(_S.interest),
                  errorMessage: _errs.interest,
                ),
            ],
            TxDateRow(
              key: const ValueKey('tx-row-date'),
              title: l.expDate,
              dayName: l.expDate,
              timeName: l.txfTimeTitle,
              dayText: dayText,
              timeText: timeText,
              locked: locked,
              onDay: _pickDay,
              onTime: _pickTime,
            ),
            TxRow(
              key: const ValueKey('tx-row-memo'),
              title: l.expDescription,
              icon: LucideIcons.stickyNote,
              value: memoValue.isEmpty ? null : memoValue,
              placeholder: l.txfNone,
              maxLines: 2,
              chevron: true,
              onTap: () => _openSub(_S.memo),
            ),
          ]),
          if (fixedRows.isNotEmpty) PList(children: fixedRows),
          // 분할 어긋남 — 금액 줄 아래가 아니라 맨 아래에 두면 안 보인다. 금액 줄 바로 아래(위 _amountRows) 에서 그린다.
          if (_errs.fx != null && !(foreign && !locked))
            TxFieldError(message: _errs.fx!),
          if (_errs.splits != null) TxFieldError(message: _errs.splits!),
          if (mismatch) const SizedBox.shrink(),
        ],
      ),
    );
  }

  /// 수정 · 고쳐 쓰기 · 문자 초안의 금액 줄(+ 잠금 안내 · 분할 어긋남 Callout).
  List<Widget> _amountRows(AppLocalizations l, bool masked) {
    final c = _input;
    final auto = c.isAutoGenerated;
    final locked = c.moneyFieldsLocked;
    final amountValue = masked
        ? '••••${wonUnit()}'
        : c.isForeignTx && (c.origAmountOrNull ?? 0) > 0
        ? formatOriginalAmount(
            c.origAmountOrNull!,
            c.currency,
            Localizations.localeOf(context).toString(),
          )
        : krwSigned(c.amountInt, false, unit: true);
    final noteStyle = PTypography.t3.copyWith(
      color: context.colors.fgNeutralSubtle,
    );
    final rewritable =
        _edit != null &&
        (_edit!.replaceable ?? c.moneyLocked) &&
        !_splitsPending;
    return [
      PList(
        children: [
          TxRow(
            key: const ValueKey('tx-row-amount'),
            title: l.expAmount,
            icon: LucideIcons.coins,
            value: c.amountInt <= 0 && (c.origAmountOrNull ?? 0) <= 0
                ? null
                : amountValue,
            placeholder: l.txfNone,
            chevron: true,
            locked: locked,
            onTap: () => _openSub(_S.amount, focus: _amountFocus),
            errorMessage: _errs.amount ?? _errs.krw,
          ),
        ],
      ),
      if (auto)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x1,
            PSpacing.globalGutter,
            PSpacing.x3,
          ),
          child: Text(switch (c.autoSource) {
            'TRADE_REALIZED' => l.expAutoSourceTradeRealized,
            'TRANSFER_INTEREST' => l.expAutoSourceTransferInterest,
            'CARD_CARRYOVER' ||
            'CARD_CARRYOVER_DUE' => l.expAutoSourceCardCarryover,
            _ => l.expAutoSourceDefault,
          }, style: noteStyle),
        )
      else if (c.moneyLocked)
        Padding(
          key: const ValueKey('money-lock-note'),
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x1,
            PSpacing.globalGutter,
            PSpacing.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                keepAll(
                  rewritable
                      ? l.expMoneyLockedNote
                      : l.expMoneyLockedPaidOffNote,
                ),
                style: noteStyle,
              ),
              if (rewritable) ...[
                const SizedBox(height: PSpacing.x2),
                PButton(
                  label: l.expRewrite,
                  variant: PButtonVariant.neutralOutline,
                  size: PButtonSize.small,
                  onPressed: _openRewrite,
                ),
              ],
            ],
          ),
        ),
      if (_splitMismatch)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x1,
            PSpacing.globalGutter,
            PSpacing.x3,
          ),
          child: PCallout(
            key: const ValueKey('tx-split-mismatch'),
            tone: PCalloutTone.warning,
            title: l.txfSplitMismatchTitle,
            description: l.txfSplitMismatchBody(
              krw(c.amountInt),
              krw(_splitSum),
              c.amountInt - _splitSum > 0
                  ? l.txfSplitOver(krw((c.amountInt - _splitSum).abs()))
                  : l.txfSplitShort(krw((c.amountInt - _splitSum).abs())),
            ),
            actions: [
              PButton(
                label: l.txfMatchSplits,
                size: PButtonSize.small,
                variant: PButtonVariant.neutralOutline,
                onPressed: _submitting ? null : _openReconcile,
              ),
            ],
          ),
        ),
    ];
  }

  /// 외화 — 환율 칸 + 원화 금액 줄(›). 원화 줄은 **원화만** 고치는 전용 단계로 간다(현지 금액 · 환율은 그대로 — H1).
  List<Widget> _fxRows(AppLocalizations l, String? fxHint) {
    final c = _input;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          0,
          PSpacing.globalGutter,
          PSpacing.x4,
        ),
        child: PField(
          label: l.expExchangeRate,
          invalid: _errs.fx != null,
          errorMessage: _errs.fx,
          description: fxHint,
          child: PInput(
            controller: c.fxRateCtrl,
            semanticLabel: l.expExchangeRate,
            placeholder: '0',
            invalid: _errs.fx != null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [DecimalFormatter(maxFrac: 6)],
            onChanged: (_) => setState(() {
              fillKrwFromForeign(c);
              _errs.fx = null;
              _clearPresetMark();
            }),
          ),
        ),
      ),
      PList(
        children: [
          TxRow(
            key: const ValueKey('tx-row-krw'),
            title: l.txfKrwAmount,
            icon: LucideIcons.coins,
            value: c.amountInt > 0
                ? krwSigned(c.amountInt, false, unit: true)
                : null,
            placeholder: l.txfNone,
            chevron: true,
            onTap: () => _openSub(_S.krw, focus: _amountFocus),
            errorMessage: _errs.krw,
          ),
        ],
      ),
    ];
  }

  // ── 한 단계 ─────────────────────────────────────────────
  Widget _buildAmountSub(AppLocalizations l) {
    final c = _input;
    final presetAmount = _step == _S.presetAmount;
    final krwOnly = _step == _S.krw || presetAmount;
    final foreign = !krwOnly && c.isForeignTx;
    final ctrl = presetAmount
        ? _presetAmountCtrl
        : foreign
        ? c.origAmountCtrl
        : c.amountCtrl;
    return _frame(
      key: ValueKey('tx-sub-${_step.name}'),
      title: _step == _S.krw ? l.txfKrwAmount : l.expAmount,
      onBack: _requestLeaveSub,
      showClose: false,
      headerAction: _doneAction(l),
      body: TxUnderlineAmount(
        controller: ctrl,
        focusNode: _amountFocus,
        semanticLabel: _step == _S.krw ? l.txfKrwAmount : l.expAmount,
        decimal: foreign,
        formatters: foreign
            ? const [DecimalFormatter(maxFrac: 2)]
            : kWonFormatters,
        suffixText: wonUnit(),
        // 통화 칩은 금액 단계에만 — 원화 줄 단계 · 프리셋 금액에는 없다
        chip: krwOnly || c.type == 'TRANSFER' ? null : _currencyChip(l),
        hintMessage: presetAmount ? l.txfPresetAmountHint : null,
        onChanged: (_) {
          if (foreign) fillKrwFromForeign(c);
          setState(() {});
        },
        onSubmitted: (_) => _doneSub(),
      ),
    );
  }

  Widget _buildMemoSub(AppLocalizations l) {
    return _frame(
      key: const ValueKey('tx-sub-memo'),
      title: l.txfMemoStepTitle,
      onBack: _requestLeaveSub,
      showClose: false,
      headerAction: _doneAction(l),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          PSpacing.x3,
          PSpacing.globalGutter,
          PSpacing.x2,
        ),
        child: PField(
          maxGraphemeCount: 500,
          child: PTextarea(
            controller: _input.memoCtrl,
            focusNode: _subFocus,
            semanticLabel: l.expDescription,
            placeholder: l.expMemoPlaceholder,
            maxHeight: 200,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildMoneySub(AppLocalizations l) {
    final c = _input;
    final isFee = _step == _S.fee;
    final amount = c.amountInt;
    final interest = c.interestOrNull ?? 0;
    return _frame(
      key: ValueKey('tx-sub-${_step.name}'),
      title: isFee ? l.expFee : l.expInterest,
      onBack: _requestLeaveSub,
      showClose: false,
      headerAction: _doneAction(l),
      body: TxUnderlineAmount(
        controller: isFee ? c.feeCtrl : c.interestCtrl,
        focusNode: _subFocus,
        semanticLabel: isFee ? l.expFee : l.expInterest,
        formatters: kWonFormatters,
        suffixText: wonUnit(),
        hintMessage: isFee
            ? null
            : (amount > 0 && interest > 0
                  ? l.expInterestSplit(
                      krw(amount - interest < 0 ? 0 : amount - interest),
                      krw(interest),
                    )
                  : l.expInterestHint),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _doneSub(),
      ),
    );
  }

  Widget _buildSms(AppLocalizations l) {
    return _frame(
      key: const ValueKey('tx-sub-sms'),
      title: l.txfSmsStepTitle,
      onBack: _requestLeaveSub,
      footer: [
        PButton(
          label: l.smsPasteAction,
          size: PButtonSize.large,
          loading: _smsBusy,
          onPressed: _smsBusy ? null : _readSms,
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          PSpacing.x3,
          PSpacing.globalGutter,
          PSpacing.x2,
        ),
        child: PField(
          label: l.smsPasteFieldLabel,
          description: l.txfSmsHelp,
          invalid: _smsError != null,
          errorMessage: _smsError,
          child: PTextarea(
            controller: _smsCtrl,
            focusNode: _smsFocus,
            semanticLabel: l.smsPasteFieldLabel,
            placeholder: l.smsPastePlaceholder,
            invalid: _smsError != null,
            maxHeight: 200,
            onChanged: (_) {
              if (_smsError != null) setState(() => _smsError = null);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPresetAll(AppLocalizations l) {
    final c = _input;
    final presets = [
      for (final p
          in ref.watch(presetListProvider).value ?? const <ExpenseTemplate>[])
        if (p.expenseType == c.type) p,
    ]..sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
    final cats =
        ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];
    return _frame(
      key: const ValueKey('tx-sub-preset-all'),
      title: l.txfPresetAllTitle,
      onBack: _requestLeaveSub,
      body: PList(
        semanticLabel: l.txfPresetAllTitle,
        children: [
          for (final p in presets)
            PListButtonItem(
              key: ValueKey('tx-preset-row-${p.rowId}'),
              title: p.templateName,
              detail: p.merchant,
              prefix:
                  p.categoryRowId == null ||
                      cats.byRowId(p.categoryRowId!) == null
                  ? null
                  : categoryTile(context, cats.byRowId(p.categoryRowId!)!),
              suffix: (p.lockAmount ?? 'N') == 'Y' && (p.amount ?? 0) > 0
                  ? Text(krwSigned(p.amount!, false, unit: true))
                  : null,
              onTap: () => _applyPreset(p),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetSave(AppLocalizations l) {
    final c = _input;
    final cats =
        ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];
    final assets = ref.watch(assetsProvider).value ?? const <Asset>[];
    final isTransfer = c.type == 'TRANSFER';
    final cat = c.categoryRowId == null ? null : cats.byRowId(c.categoryRowId!);
    final from = c.assetRowId == null ? null : assets.byRowId(c.assetRowId!);
    final to = c.toAssetRowId == null ? null : assets.byRowId(c.toAssetRowId!);
    final parent = cat?.parentRowId == null
        ? null
        : cats.byRowId(cat!.parentRowId!);
    final merchant = c.merchantCtrl.text.trim();
    final amount = parseAmountInput(_presetAmountCtrl.text) ?? 0;
    final detailParts = isTransfer
        ? [transferPartiesLabel(from?.assetName, to?.assetName)]
        : [
            if (parent != null) parent.categoryName,
            if (cat != null) cat.categoryName,
            if (from != null) from.assetName,
          ];
    return _frame(
      key: const ValueKey('tx-sub-preset-save'),
      title: l.expPresetSaveTitle,
      onBack: _requestLeaveSub,
      footer: [
        PButton(
          label: l.actionSave,
          size: PButtonSize.large,
          loading: _presetSaving,
          onPressed: _presetSaving ? null : _savePreset,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PList(
            children: [
              PListItem(
                title: isTransfer || merchant.isEmpty
                    ? l.txfPresetNoMerchant
                    : merchant,
                detail: detailParts.isEmpty ? null : detailParts.join(' · '),
                prefix: isTransfer
                    ? const PListTile(
                        background: Color(0x00000000),
                        color: Color(0xFF000000),
                        child: Icon(LucideIcons.arrowRightLeft),
                      )
                    : (cat == null ? null : categoryTile(context, cat)),
                suffix: Text(krwSigned(c.amountInt, false, unit: true)),
              ),
            ],
          ),
          if (_presetFormError != null)
            TxFieldError(message: _presetFormError!),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x3,
              PSpacing.globalGutter,
              PSpacing.x4,
            ),
            child: PField(
              key: ValueKey('tx-preset-name-$_presetNameGen'),
              label: l.presetName,
              invalid: _presetNameError != null,
              errorMessage: _presetNameError,
              maxGraphemeCount: _kPresetNameMax,
              child: PInput(
                controller: _presetNameCtrl,
                focusNode: _subFocus,
                semanticLabel: l.presetName,
                placeholder: l.expPresetNamePlaceholder,
                invalid: _presetNameError != null,
                onChanged: (_) {
                  if (_presetNameError != null) {
                    setState(() => _presetNameError = null);
                  }
                },
              ),
            ),
          ),
          PList(
            children: [
              TxRow(
                key: const ValueKey('tx-preset-amount-row'),
                title: l.expAmount,
                icon: LucideIcons.coins,
                value: amount > 0 ? krwSigned(amount, false, unit: true) : null,
                placeholder: l.txfPresetAmountEmpty,
                chevron: true,
                onTap: () {
                  // 이름 · 금액은 이 단계 안의 값 — 금액 단계는 이 단계 위의 한 단계다
                  final keepName = _presetNameCtrl.text;
                  _openSub(_S.presetAmount, focus: _amountFocus);
                  _returnTo = _S.presetSave;
                  _presetNameCtrl.text = keepName;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 고르기 본문 ────────────────────────────────────────────

/// 카테고리 고르기 — 지금 종류의 말단만. 하위가 있는 상위는 고를 수 없는 목록 제목이고 그 아래가 하위 줄이다.
/// 20-2 앱이 먼저 머지되면 rebase 때 그쪽 `CategoryPickBody` 로 교체한다.
class _CategoryPickBody extends ConsumerWidget {
  const _CategoryPickBody({required this.kind, required this.selected});
  final String kind;
  final int? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(categoriesProvider);
    if (!async.hasValue) {
      return Padding(
        padding: const EdgeInsets.all(PSpacing.globalGutter),
        child: Text(
          async.hasError ? l.txfCategoryLoadFailed : l.actionLoading,
          style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
        ),
      );
    }
    final inKind = [
      for (final cat in async.requireValue)
        if (cat.expenseType == kind) cat,
    ]..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    final tops = [
      for (final cat in inKind)
        if (cat.parentRowId == null || cat.parentRowId == 0) cat,
    ];
    if (tops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(PSpacing.globalGutter),
        child: Text(
          l.txfNoCategoryOfType,
          textAlign: TextAlign.center,
          style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
        ),
      );
    }
    PickItem<int> item(ExpenseCategory cat) => PickItem<int>(
      value: cat.rowId,
      title: cat.categoryName,
      prefix: categoryTile(context, cat),
    );
    final blocks = <Widget>[];
    var run = <ExpenseCategory>[];
    void flush() {
      if (run.isEmpty) return;
      blocks.add(
        PickList<int>(
          label: l.expCategory,
          selected: selected,
          items: [for (final cat in run) item(cat)],
        ),
      );
      run = [];
    }

    for (final top in tops) {
      final kids = [
        for (final cat in inKind)
          if (cat.parentRowId == top.rowId) cat,
      ];
      if (kids.isEmpty) {
        run.add(top);
        continue;
      }
      flush();
      blocks.add(PListHeader(title: top.categoryName, headingLevel: 3));
      blocks.add(
        PickList<int>(
          label: top.categoryName,
          selected: selected,
          items: [for (final k in kids) item(k)],
        ),
      );
    }
    flush();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }
}

/// 계좌 · 카드 고르기 — 줄 = Logo Tile 40 + 이름 + 설명 기관. 맨 앞 "계좌·카드 없음"(지출 · 수입).
class _AssetPickBody extends StatelessWidget {
  const _AssetPickBody({
    required this.assets,
    required this.selected,
    required this.label,
    required this.withNone,
    required this.noneLabel,
    required this.failed,
    required this.failedText,
    required this.onRetry,
    this.emptyText,
  });

  final List<Asset> assets;
  final int? selected;
  final String label;
  final bool withNone;
  final String noneLabel;
  final String? emptyText;
  final bool failed;
  final String failedText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (failed) {
      return Padding(
        padding: const EdgeInsets.all(PSpacing.globalGutter),
        child: Text(
          failedText,
          style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickList<int>(
          label: label,
          selected: selected,
          items: [
            if (withNone) PickItem(value: -1, title: noneLabel),
            for (final a in assets)
              PickItem(
                value: a.rowId,
                title: a.assetName,
                detail: a.institution,
                prefix: AssetLogo(asset: a, size: 40),
              ),
          ],
        ),
        if (emptyText != null)
          Padding(
            padding: const EdgeInsets.all(PSpacing.globalGutter),
            child: Text(
              emptyText!,
              textAlign: TextAlign.center,
              style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
      ],
    );
  }
}
