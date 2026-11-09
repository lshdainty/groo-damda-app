import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/amount_limit_guard.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/asset_pick_gate.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/category_pick.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_schedule.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart'
    show Expense;
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart'
    hide dayKey;
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/forms/step_done.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 거래처(수입이면 수입처) 상한 · 메모 상한 · 끝 횟수 상한 — 웹 `recurring-steps-model.ts` 와 같은 값.
const int kRecurringMerchantMax = 50;
const int kRecurringMemoMax = 200;
const int kRecurringEndCountMax = 999;

const _kPaymentMethodValues = <String>['CASH', 'CARD', 'TRANSFER', 'OTHER'];

/// 결제 수단 → 허용 자산 타입. null 이면 전체(거래 시트와 같다).
const Map<String, List<String>?> _kPaymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

/// 계좌 고르기에서 "선택 안 함" 줄의 값 — rowId 는 1부터 시작한다.
const int _kNoAsset = 0;

/// 한 단계 들어가는 줄 — 치는 값(거래처 · 메모 · 수수료 · 이자) · 반복 · 끝.
enum _Step { none, merchant, memo, fee, interest, repeat, end }

bool _isAmountStep(_Step s) => s == _Step.fee || s == _Step.interest;

enum _EndMode { none, date, count }

PLeaveConfirmCopy _leaveCopy(AppLocalizations l) => PLeaveConfirmCopy(
  title: l.sheetLeaveTitle,
  description: l.sheetLeaveDescription,
  stayLabel: l.sheetLeaveStay,
  leaveLabel: l.sheetLeaveLeave,
);

class _Probe extends StepProbe {
  /// 새 폼의 첫 초점(금액 칸) — 시트가 열릴 때 내용에 넘겨 준다(일정 폼과 같은 길: `PBottomSheet.show(initialFocus:)`).
  final FocusNode amountFocus = FocusNode();
}

/// 횟수 칸 — 숫자만, [kRecurringEndCountMax] 를 넘으면 그 값으로 줄인다(웹과 같다: 999999 → 999).
class _CountFormatter extends TextInputFormatter {
  const _CountFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final n = int.tryParse(digits) ?? kRecurringEndCountMax + 1;
    final t = (n > kRecurringEndCountMax ? kRecurringEndCountMax : n)
        .toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// 반복 거래 추가 · 수정 폼 — 웹 `RecurringAddDialog.tsx` 미러(I-20 D 26 ~ 28). 입력 폼 시트: 맨 위 종류 Chip → 금액 칸 → 줄 칸
/// → 스위치 줄 → 다음 예정일 안내. 반복 · 끝 · 거래처 · 메모 · 수수료 · 이자는 같은 시트 안 한 단계 들어간다(머리 ← 와 "완료").
/// 바닥 주 버튼은 켜 두고 누를 때 칸 아래에 알린다. 저장 실패는 고정 글 Callout(서버 원문 없음)이다.
///
/// 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 묻는다. 저장하면 목록을 다시 받은 **뒤에** 닫힌다.
/// [recurring] 이 있으면 수정, [transferSeed] 는 새로 만들되 값만 물려받는다(이체 상세의 "반복 설정").
Future<void> showRecurringFormSheet(
  BuildContext context, {
  RecurringTransaction? recurring,
  AssetTransfer? transferSeed,
}) {
  final l = AppLocalizations.of(context);
  final probe = _Probe();
  return PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    interceptClose: () => probe.interceptClose(),
    // 새로 만들 때만 금액 칸이 첫 초점이다(수정은 시트에 둔다)
    initialFocus: recurring == null ? probe.amountFocus : null,
    leaveCopy: _leaveCopy(l),
    builder: (_) => _RecurringForm(
      recurring: recurring,
      transferSeed: transferSeed,
      probe: probe,
    ),
  ).whenComplete(probe.amountFocus.dispose);
}

/// 반복 거래 폼 — 상세 시트 안 한 단계로도 쓴다(I-21 H 44 · 45). [expenseSeed] 가 있으면 그 거래 값으로 채워 새로 만들고(종류는
/// 거래 그대로 막힘 · 저장 본문에 `sourceExpenseRowId` 를 싣는다), [recurring] 이 있으면 그 반복의 수정 폼이다. [onBack] 이 있으면 머리에
/// ← 가 서고 저장이 끝나도 시트를 닫지 않고 [onSaved] 를 부른다.
class RecurringFormFlow extends _RecurringForm {
  const RecurringFormFlow({
    super.key,
    super.recurring,
    required super.expenseSeed,
    required super.probe,
    required VoidCallback super.onBack,
    required VoidCallback super.onSaved,
  });
}

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({
    super.key,
    this.recurring,
    this.transferSeed,
    this.expenseSeed,
    required this.probe,
    this.onBack,
    this.onSaved,
  });
  final RecurringTransaction? recurring;
  final AssetTransfer? transferSeed;
  final Expense? expenseSeed;
  final StepProbe probe;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final _amountCtrl = TextEditingController();
  late final FocusNode _amountFocus = widget.probe is _Probe
      ? (widget.probe as _Probe).amountFocus
      : FocusNode();
  bool get _embedded => widget.onBack != null;
  final _draftCtrl = TextEditingController();

  /// 100억을 넘겨 입력을 막았나 — 금액 칸(`_amountLimit.over`)과 수수료 · 이자 단계 칸(`_draftLimit.over`) 아래에 오류를 띄우고
  /// 다음 유효한 입력에서 걷는다.
  late final _amountLimit = AmountLimitGuard(
    _amountCtrl,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  late final _draftLimit = AmountLimitGuard(
    _draftCtrl,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  final _draftFocus = FocusNode();
  final _countCtrl = TextEditingController();

  // 처음 값(바뀐 값 비교)
  late final Map<String, Object?> _initial;

  late String _type;
  int? _categoryRowId;
  String _merchant = '';
  String _description = '';
  String _paymentMethod = '';
  int? _assetRowId;
  int? _toAssetRowId;
  String _fee = '';
  String _interest = '';
  late DateTime _startDate;
  String _frequency = 'MONTHLY';
  int _dow = 1; // 0=일 ~ 6=토
  int _dom = 1;
  String _time = '09:00'; // HH:mm
  _EndMode _endMode = _EndMode.none;
  late DateTime _endDate;
  String _endCount = '12';
  bool _autoLog = true;
  bool _notify = true;
  bool _fixed = false;

  // 단계 초안
  String _dFrequency = 'MONTHLY';
  int _dDom = 1;
  int _dDow = 1;
  PTimeValue _dTime = const PTimeValue(9, 0);
  _EndMode _dEndMode = _EndMode.none;
  late DateTime _dEndDate;
  String? _stepCountError;

  bool _attempted = false;
  bool _saveError = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _saveErrorKey = GlobalKey();
  bool _submitting = false;
  _Step _step = _Step.none;
  String _stepOrigin = '';
  bool _leaving = false;

  bool get _isEdit => widget.recurring != null;
  bool get _isTransfer => _type == 'TRANSFER';

  static DateTime _today() {
    final n = recurringNow();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _addYears(DateTime d, int n) {
    final y = d.year + n;
    final last = DateTime(y, d.month + 1, 0).day;
    return DateTime(y, d.month, d.day < last ? d.day : last);
  }

  @override
  void initState() {
    super.initState();
    final r = widget.recurring;
    final seed = widget.transferSeed;
    // 거래 씨앗은 새로 만들 때만 — 수정은 그 반복의 값 그대로(빈 칸을 거래 값으로 채워 덮지 않는다)
    final x = r == null ? widget.expenseSeed : null;
    DateTime start = _today();
    if (r?.startDate != null) {
      start = parseDayKey(r!.startDate) ?? start;
    } else if (x != null && (x.expenseDate ?? '').length >= 10) {
      // 거래한 날이 시작일이다
      start = parseDayKey(x.expenseDate!.substring(0, 10)) ?? start;
    } else if (seed != null) {
      start = parseDayKey((seed.transferDate ?? '').padRight(10)) ?? start;
    }
    _startDate = start;
    _type =
        r?.expenseType ??
        x?.expenseType ??
        (seed != null ? 'TRANSFER' : 'EXPENSE');
    final amount = r != null
        ? r.amount.abs()
        : (x?.amount.abs() ?? seed?.amount.abs() ?? 0);
    _amountCtrl.text = amount > 0 ? formatAmountInput(amount) : '';
    _merchant = r?.merchant ?? x?.merchant ?? '';
    _paymentMethod = r?.paymentMethod ?? x?.paymentMethod ?? '';
    _categoryRowId = (r?.categoryRowId ?? 0) > 0
        ? r!.categoryRowId
        : x?.categoryRowId;
    _assetRowId = (r?.assetRowId ?? 0) > 0
        ? r!.assetRowId
        : (x?.assetRowId ?? seed?.fromAssetRowId);
    _description = r?.description ?? x?.description ?? seed?.description ?? '';
    _toAssetRowId = r?.toAssetRowId ?? seed?.toAssetRowId;
    final fee = r?.fee ?? seed?.fee;
    _fee = (fee ?? 0) > 0 ? '$fee' : '';
    final interest = r?.interestAmount ?? seed?.interestAmount;
    _interest = (interest ?? 0) > 0 ? '$interest' : '';
    _frequency = r?.frequency ?? 'MONTHLY';
    // 서버 ISO 1=월 ~ 7=일 → UI 0=일 ~ 6=토
    _dow = r?.dayOfWeek != null ? r!.dayOfWeek! % 7 : start.weekday % 7;
    _dom = (r?.dayOfMonth ?? start.day).clamp(1, 31);
    final et = (r?.executionTime ?? '09:00:00');
    _time = et.length >= 5 ? et.substring(0, 5) : '09:00';
    if (r == null) {
      _endMode = _EndMode.none;
    } else if (r.maxOccurrences != null && r.maxOccurrences! > 0) {
      _endMode = _EndMode.count;
    } else if (r.endDate != null) {
      _endMode = _EndMode.date;
    }
    _endCount = r?.maxOccurrences != null && r!.maxOccurrences! > 0
        ? '${r.maxOccurrences}'
        : '12';
    _endDate = r?.endDate != null
        ? (parseDayKey(r!.endDate) ?? _addYears(_today(), 1))
        : _addYears(_today(), 1);
    _dEndDate = _endDate;
    _autoLog = r?.autoLog ?? true;
    _notify = r?.notifyDayBefore ?? true;
    _fixed = r?.isFixed ?? x?.isFixed ?? false;
    _initial = _snapshot();
    widget.probe.dirty = () => _dirty && _step == _Step.none;
    widget.probe.interceptClose = _interceptClose;
    // 상세 안 새 폼은 첫 칸(금액)에 초점 — 시트 틀이 초점을 못 주므로 여기서 건다
    if (_embedded && r == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step == _Step.none) _amountFocus.requestFocus();
      });
    }
  }

  /// 상세 안 단계에서 ← — 바뀐 값이 있으면 먼저 "작성한 내용이 사라져요".
  Future<void> _leaveForm() async {
    if (_leaving || _submitting) return;
    if (_dirty) {
      _leaving = true;
      final leave = await PAlertDialog.confirmLeave(
        context,
        _leaveCopy(AppLocalizations.of(context)),
      );
      _leaving = false;
      if (!leave || !mounted) return;
    }
    widget.onBack!();
  }

  Map<String, Object?> _snapshot() => {
    'type': _type,
    'amount': _amountCtrl.text,
    'category': _categoryRowId,
    'merchant': _merchant,
    'memo': _description,
    'pay': _paymentMethod,
    'asset': _assetRowId,
    'to': _toAssetRowId,
    'fee': _fee,
    'interest': _interest,
    'start': dayKey(_startDate),
    'freq': _frequency,
    'dow': _dow,
    'dom': _dom,
    'time': _time,
    'endMode': _endMode,
    'endDate': dayKey(_endDate),
    'endCount': _endCount,
    'auto': _autoLog,
    'notify': _notify,
    'fixed': _fixed,
  };

  bool get _dirty {
    final now = _snapshot();
    for (final k in now.keys) {
      if (now[k] != _initial[k]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _amountLimit.dispose();
    _draftLimit.dispose();
    widget.probe.dirty = () => false;
    widget.probe.interceptClose = () => false;
    if (widget.probe is! _Probe) _amountFocus.dispose();
    _amountCtrl.dispose();
    _draftCtrl.dispose();
    _draftFocus.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  // ── 값 ────────────────────────────────────────────────────
  List<Asset> get _assets => ref.read(assetsProvider).value ?? const <Asset>[];
  List<ExpenseCategory> get _categories =>
      ref.read(categoriesProvider).value ?? const <ExpenseCategory>[];

  int get _amountValue => parseAmountInput(_amountCtrl.text) ?? 0;
  bool get _showInterest => _isTransfer && isLoanTarget(_assets, _toAssetRowId);

  ExpenseCategory? get _selectedCategory {
    final id = _categoryRowId;
    if (id == null) return null;
    return _categories.byRowId(id);
  }

  /// 결제 수단 + 거래 종류로 계좌 · 카드 후보를 거른다. 지출에선 예 · 적금을 뺀다(만기 전까지 묶인 돈).
  bool _allowAsset(Asset a) {
    final allowed = _paymentMethod.isNotEmpty
        ? _kPaymentAssetTypes[_paymentMethod]
        : null;
    if (allowed != null && !allowed.contains(a.assetType)) return false;
    if (_type == 'EXPENSE' && a.assetType == 'SAVINGS') return false;
    return true;
  }

  /// 종류 · 결제 수단 · 받는 계좌가 바뀌면 이어진 칸을 맞춘다 — 안 맞는 값이 실려 나가면 서버가 거절한다.
  void _normalize() {
    if (_isTransfer) {
      _categoryRowId = null;
    } else {
      _toAssetRowId = null;
      _fee = '';
      _interest = '';
      final cat = _selectedCategory;
      // 목록을 아직 못 받았으면 비우지 않는다(수정으로 열 때 저장된 카테고리를 날리지 않게)
      if (cat != null && cat.expenseType != _type) _categoryRowId = null;
      if (_assetRowId != null) {
        final picked = _assets.where((a) => a.rowId == _assetRowId).firstOrNull;
        if (picked != null && !_allowAsset(picked)) _assetRowId = null;
      }
    }
    if (!_showInterest) _interest = '';
  }

  void _onType(String next) {
    setState(() {
      _type = next;
      _normalize();
    });
  }

  List<String> get _nextDates => previewNextDateKeys(
    dayKey(_startDate),
    _frequency,
    _dow,
    _dom,
    3,
    endDate: _endMode == _EndMode.date ? dayKey(_endDate) : null,
    maxOccurrences: _endMode == _EndMode.count ? int.tryParse(_endCount) : null,
    intervalValue: widget.recurring?.intervalValue ?? 1,
    today: _today(),
  );

  // ── 검증(누를 때 보인다) ──────────────────────────────────
  String? _errAmount(AppLocalizations l) => _amountValue <= 0
      ? l.recErrAmount
      : _amountValue > kAmountMax
      ? l.amountTooLarge
      : null;

  // 목록을 아직 못 받았으면 저장된 id 를 그대로 인정한다(수정으로 열 때 막지 않게 — 20-2 와 같음)
  String? _errCategory(AppLocalizations l) {
    if (_isTransfer || _selectedCategory != null) return null;
    final loaded = ref.read(categoriesProvider).value != null;
    if (!loaded && _categoryRowId != null) return null;
    return l.recErrCategory;
  }

  String? _errInterest(AppLocalizations l) =>
      _showInterest && (int.tryParse(_interest) ?? 0) > _amountValue
      ? l.recErrInterestTooBig
      : null;

  /// 목록이 온 뒤 규칙 밖 값(지운 계좌 · 카드가 된 이체 계좌 · 상위가 된 카테고리)을 비운다 — 칸 오류가 알린다.
  void _clearOutOfRule() {
    final assets = ref.read(assetsProvider).value;
    final cats = ref.read(categoriesProvider).value;
    var changed = false;
    if (assets != null) {
      final ids = {for (final a in assets) a.rowId};
      if (_assetRowId != null && !ids.contains(_assetRowId)) {
        _assetRowId = null;
        changed = true;
      }
      if (_isTransfer && _toAssetRowId != null) {
        final ok = transferEligibleAssets(
          assets,
        ).any((a) => a.rowId == _toAssetRowId);
        if (!ok) {
          _toAssetRowId = null;
          changed = true;
        }
      }
    }
    if (cats != null && !_isTransfer && _categoryRowId != null) {
      final c = cats.byRowId(_categoryRowId!);
      // 목록에 없거나 하위가 생겨 상위가 된 카테고리 — 말단만 고른다
      if (c == null || c.hasChildren) {
        _categoryRowId = null;
        changed = true;
      }
    }
    if (changed) _normalize();
  }

  String? _errFrom(AppLocalizations l) =>
      _isTransfer && _assetRowId == null ? l.recErrFrom : null;

  String? _errTo(AppLocalizations l) =>
      _isTransfer && (_toAssetRowId == null || _toAssetRowId == _assetRowId)
      ? l.recErrTo
      : null;

  String? _errEnd(AppLocalizations l) {
    if (_endMode == _EndMode.date && _endDate.isBefore(_startDate)) {
      return l.recErrEndBeforeStart;
    }
    if (_endMode == _EndMode.count) {
      final n = int.tryParse(_endCount) ?? 0;
      if (n > kRecurringEndCountMax) {
        return l.recErrCountMax(kRecurringEndCountMax);
      }
      if (n < 1) return l.recErrCountMin;
    }
    return null;
  }

  // ── 한 단계 들어가기 ──────────────────────────────────────
  String _valueOf(_Step s) => switch (s) {
    _Step.merchant => _merchant,
    _Step.memo => _description,
    _Step.fee => _fee,
    _Step.interest => _interest,
    _ => '',
  };

  void _enterText(_Step s) {
    FocusScope.of(context).unfocus();
    final v = _valueOf(s);
    _draftCtrl.text = _isAmountStep(s) && v.isNotEmpty
        ? formatAmountInput(int.parse(v))
        : v;
    _stepOrigin = _draftCtrl.text;
    _draftLimit.dismiss();
    setState(() => _step = s);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _step == s) _draftFocus.requestFocus();
    });
  }

  String _repeatSig() =>
      '$_dFrequency|$_dDom|$_dDow|${_dTime.hour}:${_dTime.minute}';
  String _endSig() =>
      '${_dEndMode.name}|${dayKey(_dEndDate)}|${_countCtrl.text}';

  void _enterRepeat() {
    FocusScope.of(context).unfocus();
    final parts = _time.split(':');
    _dFrequency = _frequency;
    _dDom = _dom;
    _dDow = _dow;
    _dTime = PTimeValue(int.parse(parts[0]), int.parse(parts[1]));
    _stepOrigin = _repeatSig();
    setState(() => _step = _Step.repeat);
  }

  void _enterEnd() {
    FocusScope.of(context).unfocus();
    _dEndMode = _endMode;
    _dEndDate = _endDate;
    _countCtrl.text = _endCount;
    _stepCountError = null;
    _stepOrigin = _endSig();
    setState(() => _step = _Step.end);
  }

  bool get _stepDirty => switch (_step) {
    _Step.repeat => _repeatSig() != _stepOrigin,
    _Step.end => _endSig() != _stepOrigin,
    _Step.none => false,
    _ => _draftCtrl.text != _stepOrigin,
  };

  /// "완료" — 친 글 · 고른 값을 넣고 줄 칸으로 돌아간다(묻지 않는다).
  void _confirmStep() {
    final s = _step;
    if (s == _Step.none) return;
    if (s == _Step.end) {
      final n = int.tryParse(_countCtrl.text) ?? 0;
      if (_dEndMode == _EndMode.count && (n < 1 || n > kRecurringEndCountMax)) {
        final l = AppLocalizations.of(context);
        setState(
          () => _stepCountError = n > kRecurringEndCountMax
              ? l.recErrCountMax(kRecurringEndCountMax)
              : l.recErrCountMin,
        );
        return;
      }
    }
    setState(() {
      switch (s) {
        case _Step.merchant:
          _merchant = _draftCtrl.text.trim();
        case _Step.memo:
          _description = _draftCtrl.text;
        case _Step.fee:
          final n = parseAmountInput(_draftCtrl.text) ?? 0;
          _fee = n > 0 ? '$n' : '';
        case _Step.interest:
          final n = parseAmountInput(_draftCtrl.text) ?? 0;
          _interest = n > 0 ? '$n' : '';
        case _Step.repeat:
          _frequency = _dFrequency;
          _dom = _dDom;
          _dow = _dDow;
          _time =
              '${_dTime.hour.toString().padLeft(2, '0')}:${_dTime.minute.toString().padLeft(2, '0')}';
        case _Step.end:
          _endMode = _dEndMode;
          _endDate = _dEndDate;
          _endCount = _countCtrl.text;
        case _Step.none:
          break;
      }
      _step = _Step.none;
    });
  }

  /// ← · 기기 뒤로 가기 — 바뀐 값이 있으면 "작성한 내용이 사라져요" 를 묻고, 같으면 묻지 않고 줄 칸으로 돌아간다.
  Future<void> _requestLeaveStep() async {
    if (_step == _Step.none || _leaving) return;
    if (_stepDirty) {
      _leaving = true;
      final leave = await PAlertDialog.confirmLeave(
        context,
        _leaveCopy(AppLocalizations.of(context)),
      );
      _leaving = false;
      if (!leave || !mounted) return;
    }
    setState(() => _step = _Step.none);
  }

  bool _interceptClose() {
    if (!mounted) return false;
    if (_step == _Step.none) {
      if (!_embedded) return false;
      _leaveForm();
      return true;
    }
    _requestLeaveStep();
    return true;
  }

  // ── 고르기 ────────────────────────────────────────────────
  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();
    final picked = await showCategoryPickSheet(
      context,
      kind: _type == 'INCOME' ? 'INCOME' : 'EXPENSE',
      selectedRowId: _selectedCategory?.rowId,
    );
    if (picked == null || !mounted) return;
    setState(() => _categoryRowId = picked);
  }

  PickItem<int> _assetItem(Asset a) => PickItem<int>(
    value: a.rowId,
    title: a.assetName,
    detail: (a.institution ?? '').isEmpty ? null : a.institution,
    prefix: AssetLogo(asset: a),
  );

  /// [pool] 은 받은 계좌 목록에서 후보를 고른다 — 시트 안에서 다시 받아 오면 그 목록으로 다시 거른다(AssetPickGate).
  Future<int?> _pickAsset({
    required String title,
    required List<Asset> Function(List<Asset> assets) pool,
    required int? selected,
    required bool withNone,
  }) {
    FocusScope.of(context).unfocus();
    return PBottomSheet.show<int>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        return PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          flushBody: true,
          scrollFog: true,
          // 실패인데 "고를 수 있는 계좌가 없어요" 로 읽히면 안 된다 — 실패 · 받는 중은 AssetPickGate 가 가른다
          body: AssetPickGate(
            builder: (_, assets) {
              final candidates = pool(assets);
              return candidates.isEmpty && !withNone
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PSpacing.globalGutter,
                        vertical: PSpacing.x3,
                      ),
                      child: PText(
                        l.recNoAssets,
                        textAlign: TextAlign.center,
                        style: PTypography.t3.copyWith(
                          color: sheetContext.colors.fgNeutralSubtle,
                        ),
                      ),
                    )
                  : PickList<int>(
                      label: title,
                      selected: selected ?? (withNone ? _kNoAsset : null),
                      items: [
                        if (withNone)
                          PickItem<int>(
                            value: _kNoAsset,
                            title: l.recNoneOf(title),
                          ),
                        for (final a in candidates) _assetItem(a),
                      ],
                    );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickAssetRow() async {
    final l = AppLocalizations.of(context);
    final title = _type == 'INCOME'
        ? l.recDepositAccount
        : l.recurringAssetCard;
    final picked = await _pickAsset(
      title: title,
      pool: (assets) => [
        for (final a in assets)
          if (_allowAsset(a)) a,
      ],
      selected: _assetRowId,
      withNone: true,
    );
    if (picked == null || !mounted) return;
    setState(() => _assetRowId = picked == _kNoAsset ? null : picked);
  }

  Future<void> _pickFrom() async {
    final l = AppLocalizations.of(context);
    final picked = await _pickAsset(
      title: l.recTransferFrom,
      pool: transferEligibleAssets,
      selected: _assetRowId,
      withNone: false,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _assetRowId = picked;
      if (_toAssetRowId == picked) _toAssetRowId = null;
      _normalize();
    });
  }

  Future<void> _pickTo() async {
    final l = AppLocalizations.of(context);
    final picked = await _pickAsset(
      title: l.recTransferTo,
      pool: (assets) => [
        for (final a in transferEligibleAssets(assets))
          if (a.rowId != _assetRowId) a,
      ],
      selected: _toAssetRowId,
      withNone: false,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _toAssetRowId = picked;
      _normalize();
    });
  }

  String? _payLabel(AppLocalizations l, String v) => switch (v) {
    'CASH' => l.expPayCash,
    'CARD' => l.expPayCard,
    'TRANSFER' => l.expPayTransfer,
    'OTHER' => l.expPayOther,
    _ => null,
  };

  Future<void> _pickPayment() async {
    FocusScope.of(context).unfocus();
    final income = _type == 'INCOME';
    final picked = await PBottomSheet.show<String>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        final title = income ? l.recIncomeMethod : l.expPaymentMethod;
        return PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          flushBody: true,
          body: PickList<String>(
            label: title,
            selected: _paymentMethod,
            items: [
              PickItem(value: '', title: l.recNoneOf(title)),
              for (final v in _kPaymentMethodValues)
                PickItem(value: v, title: _payLabel(l, v)!),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _paymentMethod = picked;
      _normalize();
    });
  }

  /// 날짜 시트 — 달이 이어지는 달력 + "완료". [min] 앞 날은 흐리고 누르지 못한다. 닫으면 null.
  Future<DateTime?> _pickDate({
    required String title,
    required DateTime value,
    DateTime? min,
  }) {
    FocusScope.of(context).unfocus();
    return PBottomSheet.show<DateTime>(
      context,
      builder: (ctx) {
        DateTime? draft = value;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final l = AppLocalizations.of(ctx);
            return PBottomSheetContent(
              title: title,
              closeLabel: l.actionClose,
              flushBody: true,
              body: SizedBox(
                height: PDatePicker.sheetBodyHeight(ctx),
                child: PDatePicker.single(
                  labels: PDatePickerLabels.of(ctx),
                  semanticLabel: title,
                  value: draft,
                  today: _today(),
                  min: min,
                  visibleRange: PDateVisibleRange.continuous,
                  onChanged: (v) => setSheet(() => draft = v),
                ),
              ),
              footer: [
                PButton(
                  label: l.actionDone,
                  size: PButtonSize.large,
                  onPressed: draft == null
                      ? null
                      : () => PBottomSheet.of(ctx).close(draft),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickStart() async {
    final l = AppLocalizations.of(context);
    final picked = await _pickDate(title: l.recStartDay, value: _startDate);
    if (picked == null || !mounted) return;
    setState(
      () => _startDate = DateTime(picked.year, picked.month, picked.day),
    );
  }

  Future<void> _pickEndDate() async {
    final l = AppLocalizations.of(context);
    final picked = await _pickDate(
      title: l.recEndDay,
      value: _dEndDate.isBefore(_startDate) ? _startDate : _dEndDate,
      min: _startDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _dEndDate = DateTime(picked.year, picked.month, picked.day));
  }

  // ── 저장 ──────────────────────────────────────────────────
  /// 저장 실패 Callout 을 켜고 보이는 자리로 끌어온다(본문 맨 위라 아래로 내린 뒤엔 가려진다).
  void _showSaveError([Object? error]) {
    // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
    if (isUnconfirmedSave(error)) {
      ref.invalidate(recurringListProvider);
      ref.invalidate(monthExpensesProvider);
      invalidateAfterExpenseChange(ref);
    }
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

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    // 저장을 누른 순간엔 폼 검증 오류가 이긴다(가장 최근 일)
    _amountLimit.dismiss();
    setState(() {
      _attempted = true;
      _saveError = false;
    });
    final bad =
        _errAmount(l) != null ||
        _errCategory(l) != null ||
        _errInterest(l) != null ||
        (_isTransfer && !transferPartiesReady(_assetRowId, _toAssetRowId)) ||
        (_isTransfer && _toAssetRowId == _assetRowId) ||
        _errEnd(l) != null;
    if (bad) {
      if (_errAmount(l) != null) _amountFocus.requestFocus();
      return;
    }
    setState(() => _submitting = true);
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      // 이자 판정은 받는 계좌의 종류를 봐야 한다 — 목록이 없으면 받아 온 뒤 정한다. 못 받으면 요청 없이 알린다
      // (이자 키가 빠지면 서버가 지워 버린다)
      if (_isTransfer &&
          _toAssetRowId != null &&
          ref.read(assetsProvider).value == null) {
        try {
          await ref.read(assetsProvider.future);
        } catch (_) {
          if (!mounted) return;
          _showSaveError();
          return;
        }
        if (!mounted) return;
        if (_errInterest(l) != null) {
          setState(() {});
          return;
        }
      }
      final repo = await ref.read(recurringRepositoryProvider.future);
      final isWeekly = _frequency == 'WEEKLY';
      final isMonthlyish = _frequency == 'MONTHLY' || _frequency == 'YEARLY';
      final dow = isWeekly ? (_dow == 0 ? 7 : _dow) : null;
      final dom = isMonthlyish ? _dom : null;
      final merchant = _merchant.trim();
      final desc = _description.trim();
      final feeN = int.tryParse(_fee) ?? 0;
      final fee = _isTransfer && feeN > 0 ? feeN : null;
      final interestN = int.tryParse(_interest) ?? 0;
      final interest = _showInterest && interestN > 0 ? interestN : null;
      final r = widget.recurring;
      final categoryRowId = _isTransfer ? null : _categoryRowId;
      final toAsset = _isTransfer ? _toAssetRowId : null;
      final endDate = _endMode == _EndMode.date ? dayKey(_endDate) : null;
      final maxOcc = _endMode == _EndMode.count ? int.parse(_endCount) : null;
      final mer = _isTransfer || merchant.isEmpty ? null : merchant;
      final pay = _isTransfer || _paymentMethod.isEmpty ? null : _paymentMethod;
      if (r != null) {
        // 폼 값 전부를 보낸다 — 다음 실행분부터 이 값으로 만들어진다
        await repo.update(
          id: r.rowId,
          sourceExpenseRowId: r.sourceExpenseRowId,
          categoryRowId: categoryRowId,
          assetRowId: _assetRowId,
          toAssetRowId: toAsset,
          fee: fee,
          interestAmount: interest,
          expenseType: _type,
          amount: _amountValue,
          frequency: _frequency,
          intervalValue: r.intervalValue ?? 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          executionTime: '$_time:00',
          startDate: dayKey(_startDate),
          endDate: endDate,
          maxOccurrences: maxOcc,
          description: desc.isEmpty ? null : desc,
          merchant: mer,
          paymentMethod: pay,
          autoLog: _autoLog,
          notifyDayBefore: _notify,
          // 이체는 고정이 없다 — 켜 둔 채 이체로 바꿔도 싣지 않는다(서버도 꺼 버린다)
          isFixed: !_isTransfer && _fixed,
          silent: true,
        );
      } else {
        await repo.create(
          sourceExpenseRowId: widget.expenseSeed?.rowId,
          categoryRowId: categoryRowId,
          assetRowId: _assetRowId,
          toAssetRowId: toAsset,
          fee: fee,
          interestAmount: interest,
          expenseType: _type,
          amount: _amountValue,
          frequency: _frequency,
          intervalValue: 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          executionTime: '$_time:00',
          startDate: dayKey(_startDate),
          endDate: endDate,
          maxOccurrences: maxOcc,
          description: desc.isEmpty ? null : desc,
          merchant: mer,
          paymentMethod: pay,
          autoLog: _autoLog,
          notifyDayBefore: _notify,
          isFixed: !_isTransfer && _fixed,
          silent: true,
        );
      }
      // 목록을 다시 받은 **뒤에** 닫는다 — 닫혔을 때 줄이 이미 새 값이다. 만들거나 고친 규칙의 회차가 오늘이면 서버가 그 거래를
      // 바로 기록한다(QA 30 1) — 가계부 · 자산 · 홈도 함께 새로 받는다.
      ref.invalidate(recurringListProvider);
      ref.invalidate(monthExpensesProvider);
      invalidateAfterExpenseChange(ref);
      try {
        await ref.read(recurringListProvider.future);
      } catch (_) {}
      if (!mounted) return;
      if (_embedded) {
        widget.onSaved?.call();
      } else {
        PBottomSheet.of(context).close();
      }
    } on ApiException catch (e) {
      // 표면이 닫히지 않고 쓴 값이 남는다 — 알림은 폼 맨 위 Callout(고정 글, 서버 원문 없음)
      if (!mounted) return;
      _showSaveError(e);
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── 그리기 ────────────────────────────────────────────────
  String _stepTitle(AppLocalizations l, _Step s) => switch (s) {
    _Step.merchant =>
      _type == 'INCOME' ? l.expIncomeSource : l.recurringMerchant,
    _Step.memo => l.expDescription,
    _Step.fee => l.expFee,
    _Step.interest => l.expInterest,
    _Step.repeat => l.recRepeatRow,
    _Step.end => l.recEndRow,
    _Step.none => '',
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 카테고리 · 자산이 늦게 와도 줄이 새로 그려진다
    ref.watch(categoriesProvider);
    ref.watch(assetsProvider);
    // 목록이 온 뒤 규칙 밖 값을 비운다
    ref.listen(assetsProvider, (_, n) {
      if (n.hasValue && mounted) setState(_clearOutOfRule);
    });
    ref.listen(categoriesProvider, (_, n) {
      if (n.hasValue && mounted) setState(_clearOutOfRule);
    });
    if (_step != _Step.none) return _buildStep(l);
    return _buildForm(l);
  }

  /// 단계 틀 — 끝 흐림은 본문이 시트 90% 에 닿는 단계(반복의 매주 — 라디오 일곱 + 휠)만 켠다. 나머지 단계는 내용 높이라 끈다(넘치지 않는 곳에 위 20 · 아래 80 을 더하지 않는다).
  Widget _stepShell(AppLocalizations l, Widget body, {bool fog = false}) =>
      PBottomSheetContent(
        title: _stepTitle(l, _step),
        closeLabel: l.actionClose,
        showCloseButton: false,
        onBack: _requestLeaveStep,
        backLabel: l.actionBack,
        headerAction: StepDoneButton(
          label: l.actionDone,
          onPressed: _confirmStep,
        ),
        flushBody: true,
        scrollFog: fog,
        body: body,
      );

  Widget _buildStep(AppLocalizations l) {
    const gutter = EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x3,
      PSpacing.globalGutter,
      PSpacing.x2,
    );
    final title = _stepTitle(l, _step);
    switch (_step) {
      case _Step.merchant:
        return _stepShell(
          l,
          Padding(
            padding: gutter,
            child: PInput(
              controller: _draftCtrl,
              focusNode: _draftFocus,
              semanticLabel: title,
              placeholder: _type == 'INCOME'
                  ? l.recMerchantPlaceholderIncome
                  : l.recMerchantPlaceholderExpense,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                LengthLimitingTextInputFormatter(kRecurringMerchantMax),
              ],
              onSubmitted: (_) => _confirmStep(),
            ),
          ),
        );
      case _Step.memo:
        return _stepShell(
          l,
          Padding(
            padding: gutter,
            child: PField(
              maxGraphemeCount: kRecurringMemoMax,
              child: PTextarea(
                controller: _draftCtrl,
                focusNode: _draftFocus,
                semanticLabel: title,
                placeholder: l.recMemoPlaceholder,
                maxHeight: 200,
              ),
            ),
          ),
        );
      case _Step.fee:
      case _Step.interest:
        return _stepShell(
          l,
          Padding(
            padding: gutter,
            child: PField(
              description: _step == _Step.interest ? l.expInterestHint : null,
              invalid: _draftLimit.over,
              errorMessage: _draftLimit.over ? l.amountTooLarge : null,
              child: PInput(
                variant: PInputVariant.underline,
                controller: _draftCtrl,
                focusNode: _draftFocus,
                semanticLabel: title,
                placeholder: '0',
                suffixText: wonUnit(),
                tabularFigures: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: _draftLimit.formatters,
                onSubmitted: (_) => _confirmStep(),
              ),
            ),
          ),
        );
      case _Step.repeat:
        return _stepShell(l, _buildRepeatStep(l), fog: _dFrequency == 'WEEKLY');
      case _Step.end:
        return _stepShell(l, _buildEndStep(l));
      case _Step.none:
        return const SizedBox.shrink();
    }
  }

  // ── 반복 단계 ─────────────────────────────────────────────
  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x5,
      PSpacing.globalGutter,
      PSpacing.x2,
    ),
    child: Text(
      keepAll(text),
      semanticsLabel: text,
      style: PTypography.t4.copyWith(
        color: context.colors.fgNeutralSubtle,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x2,
      PSpacing.globalGutter,
      0,
    ),
    child: Text(
      keepAll(text),
      semanticsLabel: text,
      style: PTypography.t3.copyWith(color: context.colors.fgNeutralSubtle),
    ),
  );

  Widget _buildRepeatStep(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x4,
            PSpacing.globalGutter,
            0,
          ),
          child: PChipRadioGroup<String>(
            value: _dFrequency,
            onChanged: (v) => setState(() => _dFrequency = v),
            semanticLabel: l.recRepeatRow,
            children: [
              PChipRadio<String>(
                value: 'DAILY',
                label: l.recFreqDaily,
                variant: PChipVariant.outlineStrong,
              ),
              PChipRadio<String>(
                value: 'WEEKLY',
                label: l.recFreqWeekly,
                variant: PChipVariant.outlineStrong,
              ),
              PChipRadio<String>(
                value: 'MONTHLY',
                label: l.recFreqMonthly,
                variant: PChipVariant.outlineStrong,
              ),
              PChipRadio<String>(
                value: 'YEARLY',
                label: l.recFreqYearly,
                variant: PChipVariant.outlineStrong,
              ),
            ],
          ),
        ),
        if (_dFrequency == 'MONTHLY') ...[
          _sectionTitle(l.recOnWhichDay),
          _DayGrid(
            value: _dDom,
            label: l.recOnWhichDay,
            dayLabel: l.recDayN,
            onChanged: (d) => setState(() => _dDom = d),
          ),
          if (_dDom >= 29) _note(l.recMonthDayNote(_dDom)),
        ],
        if (_dFrequency == 'WEEKLY') ...[
          _sectionTitle(l.recOnWhichWeekday),
          PListRadioGroup<int>(
            semanticLabel: l.recOnWhichWeekday,
            value: _dDow,
            onChanged: (v) => setState(() => _dDow = v),
            children: [
              for (var d = 0; d < 7; d++)
                PListRadioItem<int>(value: d, title: recDowLong(l, d)),
            ],
          ),
        ],
        if (_dFrequency == 'YEARLY') _note(l.recYearlyHint),
        _sectionTitle(l.recAtWhatTime),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
          ),
          child: Center(
            child: PTimePicker(
              semanticLabel: l.recAtWhatTime,
              value: _dTime,
              onChanged: (v) => setState(() => _dTime = v),
            ),
          ),
        ),
        const SizedBox(height: PSpacing.x4),
      ],
    );
  }

  // ── 끝 단계 ───────────────────────────────────────────────
  Widget _buildEndStep(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListRadioGroup<_EndMode>(
          semanticLabel: l.recEndRow,
          value: _dEndMode,
          onChanged: (v) => setState(() {
            _dEndMode = v;
            _stepCountError = null;
          }),
          children: [
            PListRadioItem<_EndMode>(
              value: _EndMode.none,
              title: l.recEndNoneRadio,
            ),
            PListRadioItem<_EndMode>(
              value: _EndMode.date,
              title: l.recEndUntilDate,
            ),
            // 날짜까지를 고르면 그 줄 바로 아래 날짜 줄(줄 칸 — 시작일 앞 날은 흐리고 누르지 못한다)
            if (_dEndMode == _EndMode.date)
              PickerRow(
                title: l.recEndDay,
                value: recDateLong(_dEndDate),
                errorMessage: _dEndDate.isBefore(_startDate)
                    ? l.recErrEndBeforeStart
                    : null,
                onTap: _pickEndDate,
              ),
            PListRadioItem<_EndMode>(
              value: _EndMode.count,
              title: l.recEndCountTimes,
            ),
          ],
        ),
        if (_dEndMode == _EndMode.count)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x2,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PField(
              label: l.recEndCountLabel,
              invalid: _stepCountError != null,
              errorMessage: _stepCountError,
              child: PInput(
                controller: _countCtrl,
                semanticLabel: l.recEndCountLabel,
                placeholder: '0',
                suffixText: l.recTimesUnit,
                tabularFigures: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: const [_CountFormatter()],
                onChanged: (_) => setState(() => _stepCountError = null),
                onSubmitted: (_) => _confirmStep(),
              ),
            ),
          ),
      ],
    );
  }

  // ── 폼 ────────────────────────────────────────────────────
  /// 치는 값 줄 — 값 글(비었으면 안내 글) + 꺾쇠. 값은 줄 끝 오른쪽 맞춤이다.
  Widget _stepRow({
    required String title,
    required IconData icon,
    required String value,
    required String placeholder,
    required VoidCallback onTap,
    String? error,
  }) {
    final c = context.colors;
    final has = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListButtonItem(
          title: title,
          prefix: Icon(icon),
          onTap: onTap,
          suffix: PListSuffix(
            children: [
              Text(
                keepAll(has ? value : placeholder),
                semanticsLabel: has ? value : placeholder,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: has ? null : TextStyle(color: c.fgPlaceholder),
              ),
              const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
            ],
          ),
        ),
        if (error != null) _error(error),
      ],
    );
  }

  Widget _error(String text) => PickerErrorLine(text);

  String _won(String digits) => krwSigned(int.parse(digits), false, unit: true);

  String _cycleValue(AppLocalizations l) {
    final sentence = recCycleSentence(
      l,
      frequency: _frequency,
      dayOfWeek: _dow == 0 ? 7 : _dow,
      dayOfMonth: _dom,
      startDate: dayKey(_startDate),
    );
    return '$sentence · ${recClockText(_time)}';
  }

  String _endValue(AppLocalizations l) => switch (_endMode) {
    _EndMode.date => l.recEndValueDate(recDateLong(_endDate)),
    _EndMode.count => l.recEndValueCount(int.tryParse(_endCount) ?? 0),
    _EndMode.none => l.recNoneValue,
  };

  Widget _buildForm(AppLocalizations l) {
    final c = context.colors;
    final cat = _selectedCategory;
    final from = _assets.where((a) => a.rowId == _assetRowId).firstOrNull;
    final to = _assets.where((a) => a.rowId == _toAssetRowId).firstOrNull;
    final income = _type == 'INCOME';
    final amountError = _attempted ? _errAmount(l) : null;
    final nextDates = _nextDates;

    return PBottomSheetContent(
      title: _isEdit ? l.recurringEditTitle : l.recurringAddTitle,
      closeLabel: l.actionClose,
      onClose: _embedded
          ? () => PBottomSheet.of(context).requestClose(wholeSheet: true)
          : null,
      onBack: _embedded ? _leaveForm : null,
      backLabel: _embedded ? l.actionBack : null,
      flushBody: true,
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saveError)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                0,
                PSpacing.globalGutter,
                PSpacing.x3,
              ),
              child: PCallout(
                key: _saveErrorKey,
                tone: PCalloutTone.critical,
                alert: true,
                description: saveFailureText(l, _failure, l.recSaveFailed),
              ),
            ),
          // 종류 — 고른 값이 곧 폼의 갈래라 Chip 하나 고르기(좌우 24 · 아래 16)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x4,
            ),
            child: PChipRadioGroup<String>(
              value: _type,
              onChanged: _onType,
              semanticLabel: l.recTypeLabel,
              children: [
                PChipRadio<String>(
                  value: 'EXPENSE',
                  enabled:
                      widget.expenseSeed == null ||
                      widget.recurring != null ||
                      _type == 'EXPENSE',
                  label: l.expTypeExpense,
                  variant: PChipVariant.outlineStrong,
                ),
                PChipRadio<String>(
                  value: 'INCOME',
                  enabled:
                      widget.expenseSeed == null ||
                      widget.recurring != null ||
                      _type == 'INCOME',
                  label: l.expTypeIncome,
                  variant: PChipVariant.outlineStrong,
                ),
                PChipRadio<String>(
                  value: 'TRANSFER',
                  enabled:
                      widget.expenseSeed == null ||
                      widget.recurring != null ||
                      _type == 'TRANSFER',
                  label: l.expTypeTransfer,
                  variant: PChipVariant.outlineStrong,
                ),
              ],
            ),
          ),
          // 금액 — Field + Input large(글자 색 칠하지 않는다 · 새로 열면 초점)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PField(
              label: l.expAmount,
              invalid: amountError != null || _amountLimit.over,
              errorMessage: _amountLimit.over ? l.amountTooLarge : amountError,
              child: PInput(
                controller: _amountCtrl,
                focusNode: _amountFocus,
                semanticLabel: l.expAmount,
                placeholder: '0',
                suffixText: wonUnit(),
                tabularFigures: true,
                keyboardType: TextInputType.number,
                inputFormatters: _amountLimit.formatters,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          if (_isTransfer) ...[
            PickerRow(
              title: l.recTransferFrom,
              prefix: const Icon(LucideIcons.wallet),
              value: from?.assetName,
              placeholder: l.recSelectOf(l.recTransferFrom),
              errorMessage: _attempted ? _errFrom(l) : null,
              onTap: _pickFrom,
            ),
            PickerRow(
              title: l.recTransferTo,
              prefix: const Icon(LucideIcons.wallet),
              value: to?.assetName,
              placeholder: l.recSelectOf(l.recTransferTo),
              errorMessage: _attempted ? _errTo(l) : null,
              onTap: _pickTo,
            ),
            _stepRow(
              title: l.expFee,
              icon: LucideIcons.banknote,
              value: _fee.isEmpty ? '' : _won(_fee),
              placeholder: l.recNoneValue,
              onTap: () => _enterText(_Step.fee),
            ),
            if (_showInterest)
              _stepRow(
                title: l.expInterest,
                icon: LucideIcons.percent,
                value: _interest.isEmpty ? '' : _won(_interest),
                placeholder: l.recNoneValue,
                error: _attempted ? _errInterest(l) : null,
                onTap: () => _enterText(_Step.interest),
              ),
          ] else ...[
            PickerRow(
              title: l.expCategory,
              prefix: const Icon(LucideIcons.tags),
              value: cat?.categoryName,
              placeholder: l.recSelectOf(l.expCategory),
              leading: cat == null
                  ? null
                  : PickerDot(
                      color: resolveChartColor(
                        context,
                        cat.color,
                        fallback: c.fgBrand,
                      ),
                    ),
              errorMessage: _attempted ? _errCategory(l) : null,
              onTap: _pickCategory,
            ),
            _stepRow(
              title: income ? l.expIncomeSource : l.recurringMerchant,
              icon: LucideIcons.store,
              value: _merchant,
              placeholder: income
                  ? l.recMerchantPlaceholderIncome
                  : l.recMerchantPlaceholderExpense,
              onTap: () => _enterText(_Step.merchant),
            ),
            PickerRow(
              title: income ? l.recIncomeMethod : l.expPaymentMethod,
              prefix: const Icon(LucideIcons.creditCard),
              value: _payLabel(l, _paymentMethod),
              placeholder: l.recNoneOf(
                income ? l.recIncomeMethod : l.expPaymentMethod,
              ),
              onTap: _pickPayment,
            ),
            PickerRow(
              title: income ? l.recDepositAccount : l.recurringAssetCard,
              prefix: const Icon(LucideIcons.wallet),
              value: from?.assetName,
              placeholder: l.recNoneOf(
                income ? l.recDepositAccount : l.recurringAssetCard,
              ),
              onTap: _pickAssetRow,
            ),
          ],
          _stepRow(
            title: l.recRepeatRow,
            icon: LucideIcons.repeat,
            value: _cycleValue(l),
            placeholder: '',
            onTap: _enterRepeat,
          ),
          PickerRow(
            title: l.recStartDay,
            prefix: const Icon(LucideIcons.calendar),
            value: recDateLong(_startDate),
            onTap: _pickStart,
          ),
          _stepRow(
            title: l.recEndRow,
            icon: LucideIcons.calendarCheck,
            value: _endValue(l),
            placeholder: l.recNoneValue,
            onTap: _enterEnd,
            error: _attempted ? _errEnd(l) : null,
          ),
          _stepRow(
            title: l.expDescription,
            icon: LucideIcons.stickyNote,
            value: _description,
            placeholder: l.recNoneValue,
            onTap: () => _enterText(_Step.memo),
          ),
          PList(
            semanticLabel: l.recAutoLog,
            children: [
              PListSwitchItem(
                title: l.recAutoLog,
                detail: l.recAutoLogSub,
                prefix: const Icon(LucideIcons.zap),
                checked: _autoLog,
                onChanged: (v) => setState(() => _autoLog = v),
              ),
              PListSwitchItem(
                title: l.recNotifyDayBefore,
                detail: l.recNotifyDayBeforeSub,
                prefix: const Icon(LucideIcons.bell),
                checked: _notify,
                onChanged: (v) => setState(() => _notify = v),
              ),
              if (!_isTransfer)
                PListSwitchItem(
                  title: income ? l.fixedSwitchIncome : l.fixedSwitchExpense,
                  detail: l.recurringFixedSub,
                  prefix: const Icon(LucideIcons.pin),
                  checked: _fixed,
                  onChanged: (v) => setState(() => _fixed = v),
                ),
            ],
          ),
          if (nextDates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x2,
                PSpacing.globalGutter,
                PSpacing.x3,
              ),
              child: Text(
                keepAll(
                  l.recNextDatesLine(
                    nextDates.map((d) => recDateKeyText(d)).join(' · '),
                  ),
                ),
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
        ],
      ),
      footer: [
        PButton(
          label: _isEdit ? l.actionSave : l.recurringAdd,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// 매월 1 ~ 31 격자 — 7열 · 사이 4 · 칸 높이 40 · 원 모서리. 하나 고르기 묶음(칸마다 라디오 이름 "{d}일").
class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.value,
    required this.label,
    required this.dayLabel,
    required this.onChanged,
  });

  final int value;
  final String label;
  final String Function(int day) dayLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
        child: LayoutBuilder(
          builder: (context, box) {
            const gap = PSpacing.x1;
            final w = (box.maxWidth - gap * 6) / 7;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var d = 1; d <= 31; d++)
                  Semantics(
                    inMutuallyExclusiveGroup: true,
                    checked: d == value,
                    label: dayLabel(d),
                    button: true,
                    excludeSemantics: true,
                    onTap: () => onChanged(d),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(d),
                      child: SizedBox(
                        width: w,
                        height: 40,
                        child: Center(
                          child: Container(
                            alignment: Alignment.center,
                            width: d == value ? w : null,
                            decoration: d == value
                                ? BoxDecoration(
                                    color: c.bgNeutralInverted,
                                    borderRadius: BorderRadius.circular(
                                      PRounded.full,
                                    ),
                                  )
                                : null,
                            child: Text(
                              '$d',
                              style: PTypography.t5.copyWith(
                                color: d == value
                                    ? c.fgNeutralInverted
                                    : c.fgNeutral,
                                fontWeight: d == value
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
