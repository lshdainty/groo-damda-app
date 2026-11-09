import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_limit_guard.dart';
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
import 'package:groo_damda_app/features/asset/domain/asset_krw.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/asset_pick_gate.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_pickers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/category_pick.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_pick_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_form_parts.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_input.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/expense_split/presentation/split_step.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/sms/data/sms_android.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/features/sms/domain/sms_prefilter.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/forms/time_sheet.dart';
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
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/forms/name_policy.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/features/category/presentation/category_tile.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

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
  reconcile,
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

  /// 금액 칸마다 100억 상한 안내 — 칸(컨트롤러)별로 하나씩 만든다(금액 · 원화 · 수수료 · 이자 · 프리셋 금액).
  final _limits = <TextEditingController, AmountLimitGuard>{};
  AmountLimitGuard _limitFor(TextEditingController c) => _limits.putIfAbsent(
    c,
    () => AmountLimitGuard(
      c,
      onChanged: () {
        if (mounted) setState(() {});
      },
    ),
  );

  /// 저장 · 다음을 눌렀다 — 거절 때 선 상한 오류를 내려놓고 폼 검증 오류가 자리를 받는다(가장 최근 일).
  void _dismissLimits() {
    for (final g in _limits.values) {
      g.dismiss();
    }
  }

  _S _returnTo = _S.one;

  /// 프리셋 저장 단계를 연 단계 — 금액 단계가 끝나도 이 값은 그대로다(N2).
  _S _presetOrigin = _S.one;

  /// 한 단계가 끝날 때 돌아갈 곳 — 프리셋 금액 → 프리셋 저장 → 연 단계.
  _S get _backTarget => switch (_step) {
    _S.presetAmount => _S.presetSave,
    _S.presetSave => _presetOrigin,
    _S.presetAll => _S.one,
    _ => _returnTo,
  };
  bool _submitting = false;

  /// 저장 흐름 안(확인창 · 자산 목록 기다림 포함) — 두 번 누름만 막고 화면에는 드러내지 않는다.
  bool _saveBusy = false;
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

  /// 프리셋 저장 요청 실패 — 맨 위 Callout(웹 TxSubs 와 같다).
  String? _presetSaveError;
  bool _presetSaving = false;
  int _presetNameGen = 0;

  // 편집 모드 분할 일치화: 서버 분할 + 이번 세션에서 맞춘 분할.
  List<SplitInput> _serverSplits = const [];
  bool _splitsPending = false;

  /// 나눈 내역 조회가 실패했다 — 저장 · 고쳐 쓰기를 막는다(N5). 분할을 모르는 채 보내면 서버가 옛 분할로 판정해 어긋난다.
  bool _splitsFailed = false;
  bool _splitsRetrying = false;
  List<SplitInput>? _reconciledSplits;
  final StepProbe _splitProbe = StepProbe();
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
    // 붙여넣기 화면 길은 초안을 들고 열린다 — 확신 낮은 안내를 시트 Callout 이 맡는다(B5)
    _smsLow = widget.smsDraft?.parsed.isLowConfidence ?? false;
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
    for (final g in _limits.values) {
      g.dispose();
    }
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

  /// 저장 중에는 시트가 닫히지 않는다(시트의 busy — [_save]) — 여기서는 입력 값만 본다.
  bool _dirty() => _sig(_input) != _initialSig;

  // ── 단계 ────────────────────────────────────────────────
  /// 기기 뒤로 가기 · Esc — 한 단계 안이면 그 단계만, 2단계면 1단계로(값은 버리지 않는다). 처음 단계면 시트의 닫는 길이 이어받는다.
  bool _intercept() {
    // 저장 중에는 시트의 busy 가 닫기 청을 먼저 막는다(이 판정까지 오지 않는다)
    if (!mounted) return false;
    if (_step == _S.reconcile) {
      _splitProbe.interceptClose();
      return true;
    }
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
    _dismissLimits();
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
      _step = _backTarget;
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
      _step = _backTarget;
      _errs = _Errs();
    });
  }

  // ── 값 바꿈 ─────────────────────────────────────────────
  /// 프리셋 · 문자로 채운 값이 지금 목록에 없으면 비우고 칸 오류로 안내한다(20-2 와 같은 규칙, N4). 거래에서 읽어 온 값(수정)은 기록이라 건드리지 않는다.
  void _dropUnknownRefs() {
    final c = _input;
    final cats = ref.read(categoriesProvider).value;
    if (cats != null &&
        c.categoryRowId != null &&
        cats.byRowId(c.categoryRowId!) == null) {
      c.categoryRowId = null;
      _errs.category = AppLocalizations.of(context).txfErrCategory;
    }
    final assets = ref.read(assetsProvider).value;
    if (assets != null &&
        c.assetRowId != null &&
        assets.byRowId(c.assetRowId!) == null) {
      c.assetRowId = null;
    }
    if (assets != null &&
        c.toAssetRowId != null &&
        assets.byRowId(c.toAssetRowId!) == null) {
      c.toAssetRowId = null;
    }
  }

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
      // 종류를 바꿔 지금 계좌가 허용 밖이 되면(수입 예적금 → 지출) 비운다
      final curAsset = _input.assetRowId == null
          ? null
          : ref
                .read(assetsProvider)
                .value
                ?.where((a) => a.rowId == _input.assetRowId)
                .firstOrNull;
      if (curAsset != null &&
          !allowTxAsset(curAsset, _input.paymentMethod, v)) {
        _input.assetRowId = null;
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
      _dropUnknownRefs();
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
      CategoryPickBody(kind: _input.type, selectedRowId: _input.categoryRowId),
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
    final bool transfer = c.type == 'TRANSFER';
    // 후보는 시트 안에서 받은 목록으로 거른다 — 못 받았다가 [다시 시도] 로 받아 오면 시트를 닫지 않아도 채워진다
    List<Asset> pool(List<Asset> assets) => transfer
        ? [
            for (final a in transferEligibleAssets(assets))
              if (!to ? true : a.rowId != c.assetRowId) a,
          ]
        : [
            for (final a in assets)
              if (allowTxAsset(a, c.paymentMethod, c.type)) a,
          ];
    final title = transfer
        ? (to ? l.transferToLabel : l.transferFromLabel)
        : (income ? l.expDepositAccount : l.expAccountCard);
    final selected = transfer
        ? (to ? c.toAssetRowId : c.assetRowId)
        : (c.assetRowId ?? -1);
    final v = await _sheet<int>(
      title,
      AssetPickGate(
        builder: (_, assets) {
          final list = pool(assets);
          return _AssetPickBody(
            assets: list,
            selected: selected,
            label: title,
            withNone: !transfer,
            noneLabel: l.txfNoAccountOption,
            emptyText: !transfer && c.paymentMethod.isNotEmpty && list.isEmpty
                ? l.txfNoPickableAsset
                : null,
          );
        },
      ),
    );
    if (v == null || !mounted) return;
    setState(() {
      if (transfer) {
        if (to) {
          c.toAssetRowId = v;
          // 받는 자산이 대출이 아니게 되면 이자는 버린다
          final assets = ref.read(assetsProvider).value ?? const <Asset>[];
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
    });
  }

  Future<void> _pickTime() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final t = _input.time;
    final picked = await showTimeSheet(
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
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
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
        _smsLow = parsed.isLowConfidence;
        _errs = _Errs();
        _dropUnknownRefs();
        _step = _S.two;
      });
    } on ApiException {
      if (!mounted) return;
      // 서버 글은 내지 않는다 — 우리 글만
      setState(() => _smsError = l.smsParseFailed);
    } finally {
      sheet?.setBusy(false);
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
    _presetOrigin = _step;
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
      _presetSaveError = null;
    });
    if (formError != null || nameError != null) return;
    final amount = parseAmountInput(_presetAmountCtrl.text) ?? 0;
    final lock = amount > 0;
    setState(() {
      _presetSaving = true;
      _saveError = null;
    });
    final name = _presetNameCtrl.text.trim();
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
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
      setState(() => _step = _presetOrigin);
      // 저장은 neutral(D1) — 시트 위 호스트. 호스트가 없는 자리(시험)는 조용히 건너뛴다.
      PSnackbar.maybeOf(
        hostContextOf(context),
      )?.show(message: l.txfPresetSaved(name));
    } on ApiException catch (e) {
      if (!mounted) return;
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
      if (isUnconfirmedSave(e)) ref.invalidate(presetListProvider);
      // 고칠 수 있는 서버 거절(이름 중복 등)은 위에서 먼저 막았다 — 남는 건 우리 글
      setState(() => _presetSaveError = saveFailureText(l, e, l.txfSaveFailed));
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _presetSaving = false);
    }
  }

  // ── 검증 · 저장 ─────────────────────────────────────────
  _Errs _validate() {
    _dismissLimits();
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
    if (c.amountInt > kAmountMax) e.krw = l.amountTooLarge;
    if (isTransfer) {
      if (c.assetRowId == null) e.from = l.txfErrFrom;
      if (c.toAssetRowId == null || c.toAssetRowId == c.assetRowId) {
        e.to = l.txfErrTo;
      }
      final interest = c.interestOrNull;
      if (showTxInterest(c, _assetsAtSave) &&
          interest != null &&
          interest > c.amountInt) {
        e.interest = l.txfErrInterest;
      }
    } else if (c.categoryRowId == null) {
      e.category = l.txfErrCategory;
    }
    if (_splitsPending) e.splits = l.txfSplitsLoading;
    if (_splitsFailed) e.splits = l.expSplitLoadFailed;
    return e;
  }

  /// [다음] — 금액이 비면 칸 아래 오류, 아니면 2단계로.
  void _next() {
    _dismissLimits();
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

  /// 저장 전에 자산 목록을 확보한다 — 목록이 없는 채로 판정하면 이자 · 할부가 조용히 지워진다(N1). 못 받으면 요청을 보내지 않는다.
  List<Asset>? _assetsAtSave;

  Future<bool> _ensureAssets() async {
    final cur = ref.read(assetsProvider);
    if (cur.hasValue) {
      _assetsAtSave = cur.value;
      return true;
    }
    try {
      _assetsAtSave = await ref.read(assetsProvider.future);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 저장 — 들어오는 순간 두 번 누름 막기를 켜고(자산 목록을 기다리는 동안 [추가] 를 또 눌러도 요청이 둘 나가지 않게) 어떤 길로
  /// 끝나도 푼다. 막기는 보이지 않는다 — 단추의 진행 원([_submitting])은 요청이 나간 동안만 돈다(웹 use-tx-form 의 savingRef ·
  /// mutation pending 과 같다). 확인창이 떠 있는 동안 뒤의 [추가] · [저장] 은 그대로다.
  Future<void> _save() async {
    if (_saveBusy || _submitting) return;
    _saveBusy = true;
    // 저장 중에는 시트를 닫지 않는다 — 실패 Callout 을 그릴 폼이 남아 있게(I-wrap-b2b 1)
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      await _saveInner();
    } finally {
      sheet?.setBusy(false);
      _saveBusy = false;
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

  Future<void> _saveInner() async {
    // 자산 목록을 받는 동안은 요청이 나가 있다 — 그때만 원을 돌린다
    final waitAssets = !ref.read(assetsProvider).hasValue;
    if (waitAssets) setState(() => _submitting = true);
    final assetsOk = await _ensureAssets();
    if (waitAssets && mounted) setState(() => _submitting = false);
    if (!assetsOk) {
      if (!mounted) return;
      setState(() => _saveError = AppLocalizations.of(context).txfSaveFailed);
      scrollSheetBodyToTop(context);
      return;
    }
    if (!mounted) return;
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
  ///
  /// 응답만 못 읽었으면(PARSE — 서버는 거래 · 이체를 만들었다) 실패라 하지 않는다: 성공 때처럼 가계부 · 자산 · 홈을 비우고
  /// "저장됐는지 확인하지 못했어요. 목록에서 확인해주세요." 를 둔다. 폼은 닫지 않는다(검수 M3 — 다시 누르면 두 번 생긴다).
  void _failSave(ApiException e) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (isUnconfirmedSave(e)) {
      ref.invalidate(monthExpensesProvider);
      invalidateAfterExpenseChange(ref);
      final edited = _edit ?? _replaceOf;
      if (edited != null) ref.invalidate(expenseSplitsProvider(edited.rowId));
    }
    setState(() => _saveError = saveFailureText(l, e, l.txfSaveFailed));
    scrollSheetBodyToTop(context);
  }

  Future<void> _submit() async {
    final c = _input;
    final amount = c.amountInt;
    final dateStr = '${c.isoDate}T${_formatTime(c.time)}:00';
    final desc = c.memoOrNull;
    final merchant = c.merchantOrNull;
    final payment = c.paymentMethodOrNull;
    // 할부는 신용카드 지출에만(웹과 같다) — 카드가 아니게 되었거나 수입이면 값을 싣지 않는다(N3)
    final installment =
        showTxInstallment(c, _assetsAtSave) && c.installmentMonths > 1
        ? c.installmentMonths
        : null;
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
      final interest = showTxInterest(c, _assetsAtSave)
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
      _saveError = null; // 지난 저장 실패를 새 모드로 끌고 가지 않는다(N6)
      _smsLow = false;
      _presetSaveError = null;
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

  /// "나눈 내역 맞추기" — 폼 안 한 단계(D 25). 서버에 보내지 않고 맞춘 분할을 폼으로 돌려준다.
  void _openReconcile() {
    if (_splitSource == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _returnTo = _step;
      _step = _S.reconcile;
    });
  }

  Widget _buildReconcile() {
    final edited = _splitSource!;
    return SplitStepFlow(
      key: ValueKey('tx-reconcile-${edited.rowId}'),
      expense: edited,
      probe: _splitProbe,
      overrideTotal: _input.amountInt,
      recordedTotal: edited.amount.abs(),
      initialSplits: _effectiveSplits,
      onBack: () {
        if (mounted) setState(() => _step = _returnTo);
      },
      onReconciled: (splits) {
        if (!mounted) return;
        setState(() {
          _reconciledSplits = splits;
          _step = _returnTo;
        });
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
      // 분할만은 마지막 받기가 실패면 막는다 — 값이 있어도(캐시) 다른 기기에서 바뀐 분할을 옛 값으로 덮을 수 있다(웹 검수 L4).
      // 실패 표시는 그 자리 실패 + [다시 시도] 그대로
      _splitsFailed = spAsync.hasError;
      _splitsRetrying = spAsync.hasError && spAsync.isLoading;
      final sp = spAsync.value;
      _serverSplits = sp == null
          ? const []
          : [
              for (final s in sp)
                SplitInput(
                  rowId: s.rowId,
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
      _S.reconcile => _buildReconcile(),
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
    // 쉼표 뒤에서만 줄을 바꾼다 — 숫자 중간 · 쉼표 앞에서 자르지 않는다. 이체는 보내는 계좌 통화(I-13 — "이체 $100")
    final text = c.type == 'TRANSFER'
        ? _transferMoney(v)
        : krwSigned(v, false, unit: true);
    return text.replaceAll(',', '\u2060,\u200B');
  }

  // ── 이체 통화(I-13) ─────────────────────────────────────
  // 이체 금액 · 수수료 · 이자는 **보내는 계좌 통화**다(서버 정의) — 칸 뒤 글자 · 줄 값이 그 통화를 따른다. 보내는 계좌를 아직 안
  // 골랐으면 원화. 외화 예수금은 정수 1단위라(센트 없음) 칸은 정수 그대로다. 웹 `use-tx-form` 의 transfer* 와 같은 셈이다.

  Asset? _transferAsset({bool to = false}) {
    final c = _input;
    if (c.type != 'TRANSFER') return null;
    final id = to ? c.toAssetRowId : c.assetRowId;
    if (id == null) return null;
    return (ref.watch(assetsProvider).value ?? const <Asset>[]).byRowId(id);
  }

  String get _transferCurrency => assetCurrencyOf(_transferAsset());

  /// 이체 칸 뒤 글자 — 원화 "원" · USD 계좌면 "$".
  String get _transferUnit => currencyUnit(_transferCurrency);

  /// 보내는 계좌 통화로 쓴 금액 글 — 원화 "1,300,000원" · 외화 "$1,000".
  String _transferMoney(int n) => isForeignCurrency(_transferCurrency)
      ? formatAssetAmount(
          n,
          _transferCurrency,
          Localizations.localeOf(context).toString(),
        )
      : krwSigned(n, false, unit: true);

  /// 이체 금액 칸 아래 · 2단계 받는 계좌 줄 아래 읽기 전용 글 — 원화 어림과 받는 금액(웹 transferHintText 와 같은 글).
  ///
  /// - 두 계좌 통화가 다르면 "받는 금액 약 $1,000" — round(금액 × 보내는 환율 ÷ 받는 환율) HALF_UP, 서버 resolveToAmount 와 같은 식.
  /// - 보내는 계좌가 외화면 "약 130,000원" — 원 단위로 친 줄 알았던 사람이 알아보게. 받는 쪽이 원화면 받는 금액 줄이 같은 말을
  ///   하므로 그때는 두지 않는다.
  String? _transferHint() {
    final c = _input;
    final amount = c.amountInt;
    if (c.type != 'TRANSFER' || amount <= 0) return null;
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final from = _transferAsset();
    final to = _transferAsset(to: true);
    final receive = transferReceiveAmount(amount, from, to);
    final receiveText = receive != null && to != null
        ? l.txfReceiveAmount(
            isForeignCurrency(to.currency)
                ? formatAssetAmount(receive, to.currency!, locale)
                : krwSigned(receive, false, unit: true),
          )
        : null;
    final approxText =
        from != null &&
            isForeignCurrency(from.currency) &&
            !(receive != null && !isForeignCurrency(to?.currency))
        ? l.fxApproxKrw(
            krwSigned(
              toKrw(amount, from.currency, from.exchangeRate),
              false,
              unit: true,
            ),
          )
        : null;
    final parts = [?approxText, ?receiveText];
    return parts.isEmpty ? null : parts.join(' · ');
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
  /// 맨 위 저장 실패 Callout — 좌우 24 · 위 12 · **아래 20**(14-1 비밀번호와 같다, 아래 칩 · 칸에 닿지 않게).
  Widget _failureCallout() => _saveError == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: PSpacing.x5),
          child: CalendarSaveErrorCallout(message: _saveError!),
        );

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
                : _limitFor(c.amountCtrl).formatters,
            // 이체에는 통화 칩이 없다 — 뒤 글자는 보내는 계좌 통화(I-13 — 원화 "원", USD 계좌면 "$")
            suffixText: c.type == 'TRANSFER' ? _transferUnit : wonUnit(),
            chip: c.type == 'TRANSFER' ? null : _currencyChip(l),
            invalid:
                _errs.amount != null ||
                (!foreign && _limitFor(c.amountCtrl).over),
            errorMessage: !foreign && _limitFor(c.amountCtrl).over
                ? l.amountTooLarge
                : _errs.amount,
            // 프리셋으로 계좌가 정해진 이체 — 칸 아래 원화 어림 · 받는 금액(읽기 전용)
            hintMessage: _emptyPresetName == null
                ? _transferHint()
                : l.txfEmptyPresetHint(_emptyPresetName!),
            onChanged: (_) {
              if (foreign) {
                fillKrwFromForeign(c);
                _clearPresetMark(); // 현지 금액을 고치면 프리셋 표시를 지운다(웹과 같다)
              }
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
    final catsAsync2 = ref.watch(categoriesProvider);
    final catsLoaded = catsAsync2.hasValue;
    final cats = catsAsync2.value ?? const <ExpenseCategory>[];
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
    } else if (c.categoryRowId != null) {
      catValue = catsLoaded ? l.txfDeletedCategory : '…';
    }
    String assetName(int? id) {
      if (id == null) return '';
      final a = assets.byRowId(id);
      // 목록에 없는 값 — 거래에서 읽어 온 기록은 유지하고 "지운 계좌" 로 보인다(본문은 지금 id 그대로, N4)
      return a == null
          // 목록을 받기 전 · 못 받은 동안은 "없음" 이 아니라 "…"(값이 있는데 없다고 말하지 않는다)
          ? (assetsAsync.hasValue ? l.txfDeletedAsset : '…')
          // 수정 폼의 계좌·카드 값은 이름만(기관은 고르기 시트 줄의 설명에 있다)
          : a.assetName;
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

    final transferHint = isTransfer ? _transferHint() : null;
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
          // 금액 줄 — 수정 · 고쳐 쓰기, 그리고 1단계가 없는 문자 초안(앱 밖 길). 시트 안 문자 길은 ← 가 있어 금액 줄이 없다(웹과 같다)
          if (_isEdit || _isReplace || (_isSms && !_hasStepOne))
            ..._amountRows(l, masked),
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
                  onChanged: (_) => setState(() {}),
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
            if (foreign && locked)
              PList(
                children: [
                  TxRow(
                    key: const ValueKey('tx-row-fx-locked'),
                    title: l.expExchangeRate,
                    icon: LucideIcons.percent,
                    value: groupDecimal(trimNum(c.fxRateOrNull)),
                    locked: true,
                    onTap: null,
                  ),
                  TxRow(
                    key: const ValueKey('tx-row-krw-locked'),
                    title: l.txfKrwAmount,
                    icon: LucideIcons.coins,
                    value: krwSigned(c.amountInt, false, unit: true),
                    locked: true,
                    onTap: null,
                  ),
                ],
              ),
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
              // 문자 카드 기억 — 계좌·카드 줄 바로 아래(지시서 D 22), 계좌를 고르기 전에는 막힌 줄. 줄 순서는 결제 수단 → 계좌·카드(2026-11-10 사용자 결정)
              if (c.smsRememberAsk)
                PListCheckItem(
                  key: const ValueKey('tx-sms-remember'),
                  title: l.smsRememberCard,
                  checked: c.assetRowId != null && c.smsRememberCard,
                  onChanged: c.assetRowId == null
                      ? null
                      : (v) => setState(() => c.smsRememberCard = v),
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
              // 금액은 보내는 계좌 통화(I-13) — 외화면 원화 어림, 두 계좌 통화가 다르면 받는 금액(읽기 전용, 서버와 같은 식 · HALF_UP)
              if (transferHint != null)
                Padding(
                  key: const ValueKey('tx-transfer-hint'),
                  padding: const EdgeInsets.fromLTRB(
                    PSpacing.globalGutter,
                    PSpacing.x1,
                    PSpacing.globalGutter,
                    PSpacing.x2,
                  ),
                  child: Text(
                    masked ? '••••' : transferHint,
                    style: PTypography.t3.copyWith(
                      color: context.colors.fgNeutralSubtle,
                    ),
                  ),
                ),
              TxRow(
                key: const ValueKey('tx-row-fee'),
                title: l.expFee,
                icon: LucideIcons.percent,
                value: c.feeOrNull == null
                    ? null
                    : _transferMoney(c.feeOrNull!),
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
                      : _transferMoney(c.interestOrNull!),
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
        : c.type == 'TRANSFER'
        // 이체는 보내는 계좌 통화(I-13)
        ? _transferMoney(c.amountInt)
        : krwSigned(c.amountInt, false, unit: true);
    final noteStyle = PTypography.t3.copyWith(
      color: context.colors.fgNeutralSubtle,
    );
    // [고쳐 쓰기] 는 서버 판정(replaceable)으로만 가른다 — 나눈 내역을 받는 동안에도 보이고, 고쳐 쓰기 폼의 저장만
    // "불러오는 중" 으로 막는다(_validate). 받는 동안 "중도 정리한 할부" 안내로 바꾸지 않는다.
    final rewritable = _edit != null && (_edit!.replaceable ?? c.moneyLocked);
    final splitSource = _splitSource;
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
          child: PText(switch (c.autoSource) {
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
      // 나눈 내역을 못 받았다 — 그 자리 실패 + [다시 시도](웹 상세 · 나누기 단계 SplitFailure 와 같은 꼴)
      if (_splitsFailed && splitSource != null)
        TxSplitFailure(
          retrying: _splitsRetrying,
          onRetry: () =>
              ref.invalidate(expenseSplitsProvider(splitSource.rowId)),
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
            : _limitFor(ctrl).formatters,
        invalid: !foreign && _limitFor(ctrl).over,
        errorMessage: !foreign && _limitFor(ctrl).over
            ? l.amountTooLarge
            : null,
        // 이체 금액은 보내는 계좌 통화(I-13) — 칸 뒤 글자 · 칸 아래 원화 어림 · 받는 금액
        suffixText: !presetAmount && c.type == 'TRANSFER'
            ? _transferUnit
            : wonUnit(),
        // 통화 칩은 금액 단계에만 — 원화 줄 단계 · 프리셋 금액에는 없다
        chip: krwOnly || c.type == 'TRANSFER' ? null : _currencyChip(l),
        hintMessage: presetAmount
            ? l.txfPresetAmountHint
            : (_step == _S.amount ? _transferHint() : null),
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
        formatters: _limitFor(isFee ? c.feeCtrl : c.interestCtrl).formatters,
        invalid: _limitFor(isFee ? c.feeCtrl : c.interestCtrl).over,
        errorMessage: _limitFor(isFee ? c.feeCtrl : c.interestCtrl).over
            ? l.amountTooLarge
            : null,
        // 수수료 · 이자도 보내는 계좌 통화다(I-13) — 뒤 글자가 그 통화
        suffixText: _transferUnit,
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
    return _frame(
      key: const ValueKey('tx-sub-preset-all'),
      title: l.presetPickTitle,
      onBack: _requestLeaveSub,
      body: PresetPickBody(presets: presets, onPick: _applyPreset),
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
          if (_presetSaveError != null)
            CalendarSaveErrorCallout(message: _presetSaveError!),
          PList(
            children: [
              PListItem(
                title: isTransfer || merchant.isEmpty
                    ? l.txfPresetNoMerchant
                    : merchant,
                detail: detailParts.isEmpty ? null : detailParts.join(' · '),
                // 이체 타일 — 프리셋 목록 · 이체 줄과 같은 회색 바탕 · 회색 아이콘(다크에서도 보인다)
                prefix: isTransfer
                    ? PListTile(
                        background: context.colors.chartGrayWeak,
                        color: context.colors.chartGray,
                        child: const Icon(LucideIcons.arrowRightLeft),
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

// ─── 고르기 본문 — 카테고리 · 프리셋은 20-2 의 부품(CategoryPickBody · PresetPickBody)이다 ───

/// 계좌 · 카드 고르기 — 받은 뒤의 본문(실패 · 받는 중은 AssetPickGate). 줄 = Logo Tile 40 + 이름 + 설명 기관. 맨 앞 "계좌·카드 없음"(지출 · 수입).
class _AssetPickBody extends StatelessWidget {
  const _AssetPickBody({
    required this.assets,
    required this.selected,
    required this.label,
    required this.withNone,
    required this.noneLabel,
    this.emptyText,
  });

  final List<Asset> assets;
  final int? selected;
  final String label;
  final bool withNone;
  final String noneLabel;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
