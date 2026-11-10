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
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/asset_pick_gate.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/category_pick.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_input.dart'
    show allowTxAsset;
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/forms/name_policy.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/forms/step_done.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 프리셋 이름 상한 — 카테고리 · 라벨 · 태그와 같은 12자. 목록 줄에 한 줄로 들어간다(웹 `PRESET_NAME_MAX`).
const int kPresetNameMax = 12;

/// 기본 내역(거래처) 상한 — 거래 시트 · 서버 컬럼과 같은 100자.
const int kPresetMerchantMax = 100;

/// 기본 메모 상한 — 이 값이 그대로 거래 메모가 된다. 시트 · 서버 컬럼과 같은 500자.
const int kPresetDescriptionMax = 500;

const _kPaymentMethodValues = <String>['CASH', 'CARD', 'TRANSFER', 'OTHER'];

/// 계좌 고르기에서 "계좌·카드 없음" 줄의 값 — rowId 는 1부터 시작한다.
const int _kNoAsset = 0;

/// 한 단계 들어가는 줄 — 치는 값(기본 내역 · 메모 · 금액 · 수수료 · 이자).
enum _Step { none, merchant, memo, amount, fee, interest }

bool _isAmountStep(_Step s) =>
    s == _Step.amount || s == _Step.fee || s == _Step.interest;

PLeaveConfirmCopy _leaveCopy(AppLocalizations l) => PLeaveConfirmCopy(
  title: l.sheetLeaveTitle,
  description: l.sheetLeaveDescription,
  stayLabel: l.sheetLeaveStay,
  leaveLabel: l.sheetLeaveLeave,
);

class _Probe {
  bool Function() dirty = () => false;
  bool Function() interceptClose = () => false;
}

/// 프리셋 추가 · 수정 폼 — 웹 `PresetEditDialog.tsx` 미러(I-20 C 19). 입력 폼 시트: 맨 위 종류 Chip 하나 고르기 → 미리보기 타일 52 +
/// 이름 칸 → 줄 칸(고르는 값은 그 위 고르기 시트, 치는 값은 같은 시트 안 한 단계 들어감) → 스위치 줄. 금액은 "고정 금액 사용" 스위치 없이
/// 줄 하나다 — 금액이 있으면 고정(`lockAmount: Y`), 비우면 불러올 때 직접 넣는다(`N`). 바닥 주 버튼은 켜 두고 누를 때 칸 아래에 알린다.
///
/// 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 묻는다. 저장하면 목록을 다시 받은 **뒤에** 닫힌다.
Future<void> showPresetEditDialog(
  BuildContext context, {
  ExpenseTemplate? edit,
}) {
  final l = AppLocalizations.of(context);
  final probe = _Probe();
  // 새 폼은 첫 칸(이름)에 초점이 간다 — 시트가 처음 초점을 컨테이너에 두므로(autofocus 가 이긴다) 시트에 첫 초점 노드를 넘긴다.
  // 노드의 주인은 폼 State 다(닫힐 때 거기서 버린다)
  final nameFocus = FocusNode(debugLabel: 'PresetForm name');
  return PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: edit == null ? nameFocus : null,
    isDirty: () => probe.dirty(),
    interceptClose: () => probe.interceptClose(),
    leaveCopy: _leaveCopy(l),
    builder: (_) => _PresetForm(edit: edit, probe: probe, nameFocus: nameFocus),
  );
}

class _PresetForm extends ConsumerStatefulWidget {
  const _PresetForm({this.edit, required this.probe, required this.nameFocus});
  final ExpenseTemplate? edit;
  final _Probe probe;

  /// 이름 칸의 초점 노드 — 호출처가 만들어 시트의 첫 초점으로 넘기고, 폼 State 가 버린다.
  final FocusNode nameFocus;

  @override
  ConsumerState<_PresetForm> createState() => _PresetFormState();
}

class _PresetFormState extends ConsumerState<_PresetForm> {
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus = widget.nameFocus;
  final _draftCtrl = TextEditingController();

  /// 100억을 넘겨 입력을 막았나(금액 · 수수료 · 이자 단계) — 칸 아래 오류를 띄우고 다음 유효한 입력에서 걷는다.
  late final _draftLimit = AmountLimitGuard(
    _draftCtrl,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  final _draftFocus = FocusNode();

  late final String _iType;
  late final String _iName;
  late final int? _iCategory;
  late final String _iMerchant;
  late final String _iDescription;
  late final String _iPayment;
  late final int? _iAsset;
  late final int? _iToAsset;
  late final String _iFee;
  late final String _iInterest;
  late final String _iAmount;
  late final bool _iFixed;

  late String _type;
  int? _categoryRowId;
  String _merchant = '';
  String _description = '';
  String _paymentMethod = '';
  int? _assetRowId;
  int? _toAssetRowId;

  /// 금액 칸들은 숫자만 든 글이다(쉼표 없음) — 비었으면 "비워 둠" · "없음".
  String _fee = '';
  String _interest = '';
  String _amount = '';
  bool _isFixed = false;

  bool _attempted = false;
  bool _saveError = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  bool _submitting = false;
  _Step _step = _Step.none;
  String _stepOrigin = '';
  bool _leaving = false;

  /// 규칙(받았는데 없음 · 카드 · 같은 계좌)이 화면 모르게 비운 칸 — 사용자가 바꾼 값이 아니므로 "바뀐 값" 으로 세지 않는다.
  bool _catAuto = false;
  bool _assetAuto = false;
  bool _toAuto = false;
  final _saveErrorKey = GlobalKey();

  bool get _isNew => widget.edit == null;
  bool get _isTransfer => _type == 'TRANSFER';
  bool get _isIncome => _type == 'INCOME';

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _iType = e?.expenseType ?? 'EXPENSE';
    _iName = e?.templateName ?? '';
    _iCategory = e?.categoryRowId;
    _iMerchant = e?.merchant ?? '';
    _iDescription = e?.description ?? '';
    _iPayment = e?.paymentMethod ?? '';
    _iAsset = e?.assetRowId;
    _iToAsset = e?.toAssetRowId;
    _iFee = e?.fee != null && e!.fee! > 0 ? '${e.fee}' : '';
    _iInterest = (e?.interestAmount ?? 0) > 0 ? '${e!.interestAmount}' : '';
    // 금액이 있으면 고정(서버 resolveAmount: 고정 켬 ⇔ 금액 > 0)
    _iAmount = e != null && (e.lockAmount ?? 'N') == 'Y' && (e.amount ?? 0) > 0
        ? '${e.amount}'
        : '';
    _iFixed = e?.isFixed ?? false;
    _type = _iType;
    _nameCtrl = TextEditingController(text: _iName);
    _categoryRowId = _iCategory;
    _merchant = _iMerchant;
    _description = _iDescription;
    _paymentMethod = _iPayment;
    _assetRowId = _iAsset;
    _toAssetRowId = _iToAsset;
    _fee = _iFee;
    _interest = _iInterest;
    _amount = _iAmount;
    _isFixed = _iFixed;
    widget.probe.dirty = () => _dirty && _step == _Step.none;
    widget.probe.interceptClose = _interceptClose;
  }

  @override
  void dispose() {
    _draftLimit.dispose();
    widget.probe.dirty = () => false;
    widget.probe.interceptClose = () => false;
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _draftCtrl.dispose();
    _draftFocus.dispose();
    super.dispose();
  }

  // ── 값 ────────────────────────────────────────────────────
  List<Asset> get _assets => ref.read(assetsProvider).value ?? const <Asset>[];
  List<ExpenseCategory> get _categories =>
      ref.read(categoriesProvider).value ?? const <ExpenseCategory>[];

  int get _amountValue => int.tryParse(_amount) ?? 0;

  /// 금액이 있으면 고정 — 서버 규칙과 같다.
  bool get _lock => _amountValue > 0;

  /// 자산을 받았는가 — 못 받았으면 "받는 계좌가 대출인가" 를 모른다.
  bool get _assetsLoaded => ref.read(assetsProvider).hasValue;

  /// 이자는 **금액이 있을 때만** 받는다(금액이 매달 다르면 이자도 매달 다르다 — 2026-09-15). 받는 계좌가 대출일 때만 보인다.
  /// 자산을 아직 못 받았으면 읽어 온 이자가 있는 한 보인다 — 모르는 채로 지우거나 저장에서 빼면 자산이 온 뒤에도 비어 이자가 사라진다
  /// (웹 20-2 후속에서 찾은 순서 문제).
  bool get _showInterest =>
      _isTransfer &&
      _lock &&
      (_assetsLoaded
          ? isLoanTarget(_assets, _toAssetRowId)
          : _interest.isNotEmpty);

  /// 이자는 금액을 넘을 수 없다 — 서버 `ASSET_TRANSFER_INVALID_INTEREST`. 저장을 누르면 이자 칸 아래에 알린다.
  bool get _interestTooLarge =>
      _showInterest &&
      _interest.isNotEmpty &&
      (int.tryParse(_interest) ?? 0) > _amountValue;

  String get _nameTrim => _nameCtrl.text.trim();

  /// 카테고리를 받았는가 — 못 받았으면 읽어 온 카테고리가 지워진 것인지 모른다.
  bool get _categoriesLoaded => ref.read(categoriesProvider).hasValue;

  /// 고른 카테고리 — 받은 목록에 있는 것만. 지워진 카테고리를 가리키는 프리셋도 열린다(웹과 같다).
  ExpenseCategory? get _selectedCategory {
    final id = _categoryRowId;
    if (id == null) return null;
    return _categories.byRowId(id);
  }

  /// 카테고리가 정해져 있는가 — **받기 전에는 읽어 온 값을 그대로 둔다**(모르는 채로 없다고 보면 저장 · 검증이 틀린다). 받았는데
  /// 목록에 없으면(지운 카테고리) 없는 것이다 — 저장하려면 다시 골라야 하고 지운 카테고리 id 는 나가지 않는다.
  bool get _hasCategory =>
      _categoryRowId != null &&
      (!_categoriesLoaded || _selectedCategory != null);

  bool get _dirty =>
      _type != _iType ||
      _nameCtrl.text != _iName ||
      (_categoryRowId != _iCategory && !_catAuto) ||
      _merchant != _iMerchant ||
      _description != _iDescription ||
      _paymentMethod != _iPayment ||
      (_assetRowId != _iAsset && !_assetAuto) ||
      (_toAssetRowId != _iToAsset && !_toAuto) ||
      _fee != _iFee ||
      _interest != _iInterest ||
      _amount != _iAmount ||
      _isFixed != _iFixed;

  /// 종류 · 계좌 · 금액이 바뀌면 이어진 칸을 맞춘다 — **규칙 밖 값은 서버가 거절하기 전에 화면이 먼저 비우고** 그 칸 아래 오류 글로
  /// 안내한다(저장 때 누르면 보인다). 목록을 **받기 전에는** 지우지 않는다(모르는 채로 지우면 읽어 온 값이 사라진다 — 웹 20-2 후속).
  /// - 받았는데 목록에 없는(지운) 계좌 · 카테고리 · 하위가 생겨 상위가 된 카테고리
  /// - 이체인데 카드인 계좌(카드는 이체 상대가 될 수 없다 — 서버 `RecurringTransferValidator`)
  /// - 보내는 계좌와 같은 받는 계좌
  void _normalize() {
    if (_assetsLoaded) {
      final all = _assets;
      bool exists(int? id) => id == null || all.any((a) => a.rowId == id);
      if (!exists(_assetRowId)) {
        _assetRowId = null;
        _assetAuto = true;
      }
      if (!exists(_toAssetRowId)) {
        _toAssetRowId = null;
        _toAuto = true;
      }
      if (_isTransfer) {
        final ok = transferEligibleAssets(all);
        if (_assetRowId != null && !ok.any((a) => a.rowId == _assetRowId)) {
          _assetRowId = null;
          _assetAuto = true;
        }
        if (_toAssetRowId != null && !ok.any((a) => a.rowId == _toAssetRowId)) {
          _toAssetRowId = null;
          _toAuto = true;
        }
      }
    }
    if (_isTransfer) {
      _categoryRowId = null;
      if (_assetRowId != null && _assetRowId == _toAssetRowId) {
        _toAssetRowId = null;
        _toAuto = true;
      }
    } else {
      _toAssetRowId = null;
      _fee = '';
      _interest = '';
      final cat = _selectedCategory;
      if (cat != null && cat.expenseType != _type) _categoryRowId = null;
      if (_categoriesLoaded) {
        final id = _categoryRowId;
        // 받았는데 목록에 없거나 하위가 생겨 상위가 됐으면(고를 수 없다) 비운다
        if (id != null &&
            (cat == null || _categories.any((c) => c.parentRowId == id))) {
          _categoryRowId = null;
          _catAuto = true;
        }
      }
    }
    if (!_showInterest) _interest = '';
  }

  void _onType(String next) {
    setState(() {
      // 종류가 바뀌면 카테고리는 늘 비운다 — 다른 종류의 카테고리는 틀리다(목록을 받기 전이라 종류를 못 읽어도)
      if (next != _type) _categoryRowId = null;
      _type = next;
      _normalize();
    });
  }

  NameIssue? get _issue {
    final taken = [
      for (final p
          in ref.read(presetListProvider).value ?? const <ExpenseTemplate>[])
        if (p.rowId != widget.edit?.rowId) p.templateName,
    ];
    final issue = nameIssue(_nameCtrl.text, kPresetNameMax, taken);
    // 안 바꾼 옛 이름은 12자 검사에서 뺀다(웹과 같다) — 12자가 넘는 옛 프리셋도 다른 칸은 고칠 수 있어야 한다
    if (issue == NameIssue.tooLong && _nameCtrl.text == _iName) return null;
    return issue;
  }

  String? _nameError(AppLocalizations l) {
    final issue = _issue;
    if (!_attempted) {
      return issue == NameIssue.duplicate ? l.presetNameDuplicate : null;
    }
    return switch (issue) {
      NameIssue.required => l.presetNameRequired,
      NameIssue.tooLong => l.presetNameTooLong,
      NameIssue.duplicate => l.presetNameDuplicate,
      null => null,
    };
  }

  // ── 한 단계 들어가기 ──────────────────────────────────────
  String _valueOf(_Step s) => switch (s) {
    _Step.merchant => _merchant,
    _Step.memo => _description,
    _Step.amount => _amount,
    _Step.fee => _fee,
    _Step.interest => _interest,
    _Step.none => '',
  };

  void _enterStep(_Step s) {
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

  /// "완료" — 친 글을 넣고 줄 칸으로 돌아간다(묻지 않는다).
  void _confirmStep() {
    final s = _step;
    if (s == _Step.none) return;
    final text = _draftCtrl.text;
    setState(() {
      if (_isAmountStep(s)) {
        final n = parseAmountInput(text) ?? 0;
        final digits = n > 0 ? '$n' : '';
        if (s == _Step.amount) _amount = digits;
        // 수수료 0 은 수수료가 없는 것이다 — 비운 것과 같이 "없음" · null (서버도 null 과 0 을 같게 읽는다)
        if (s == _Step.fee) _fee = digits;
        if (s == _Step.interest) _interest = digits;
      } else if (s == _Step.merchant) {
        _merchant = text;
      } else {
        _description = text;
      }
      // 금액을 비우면 이자도 비운다(이자는 금액을 따라간다)
      _normalize();
      _step = _Step.none;
    });
  }

  /// ← · 기기 뒤로 가기 — 친 글이 들어올 때와 다르면 "작성한 내용이 사라져요" 를 묻고, 같으면 묻지 않고 줄 칸으로 돌아간다.
  Future<void> _requestLeaveStep() async {
    if (_step == _Step.none || _leaving) return;
    if (_draftCtrl.text != _stepOrigin) {
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
    if (_step == _Step.none || !mounted) return false;
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
    setState(() {
      _categoryRowId = picked;
      _catAuto = false;
    });
  }

  PickItem<int> _assetItem(Asset a) => PickItem<int>(
    value: a.rowId,
    title: a.assetName,
    detail: (a.institution ?? '').isEmpty ? null : a.institution,
    prefix: AssetLogo(asset: a),
  );

  /// 계좌 · 카드 고르기 — 지금 규칙 그대로 전체 자산이다(거르지 않는다). 이체는 카드를 뺀 자산 · 받는 계좌는 보내는 계좌를 뺀다.
  /// [pool] 은 받은 계좌 목록에서 후보를 고른다 — 시트 안에서 다시 받아 오면 그 목록으로 다시 거른다(AssetPickGate).
  Future<int?> _pickAsset({
    required String title,
    required List<Asset> Function(List<Asset> assets) pool,
    required int? selected,
    required bool withNone,
    String? emptyText,
    String? noneLabel,
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
          body: AssetPickGate(
            builder: (_, assets) {
              final list = pool(assets);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PickList<int>(
                    label: title,
                    selected: selected ?? (withNone ? _kNoAsset : null),
                    items: [
                      if (withNone)
                        PickItem<int>(
                          value: _kNoAsset,
                          title: noneLabel ?? l.presetNoAccount,
                        ),
                      for (final a in list) _assetItem(a),
                    ],
                  ),
                  // 결제 수단에 맞는 계좌 · 카드가 하나도 없을 때(수단을 고른 뒤에만)
                  if (emptyText != null && list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(PSpacing.globalGutter),
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: PTypography.t4.copyWith(
                          color: sheetContext.colors.fgNeutralSubtle,
                        ),
                      ),
                    ),
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
    final picked = await _pickAsset(
      title: _isIncome ? l.expDepositAccount : l.presetAssetCard,
      noneLabel: _isIncome ? l.txfNoDepositAccount : null,
      // 결제 수단을 골랐으면 그 수단에 맞는 계좌 · 카드만(거래 입력과 같은 규칙 — allowTxAsset)
      pool: (assets) => [
        for (final a in assets)
          if (allowTxAsset(a, _paymentMethod, _type)) a,
      ],
      selected: _assetRowId,
      withNone: true,
      emptyText: _paymentMethod.isNotEmpty
          ? (_isIncome ? l.txfNoPickableDepositAsset : l.txfNoPickableAsset)
          : null,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _assetRowId = picked == _kNoAsset ? null : picked;
      _assetAuto = false;
    });
  }

  Future<void> _pickFrom() async {
    final l = AppLocalizations.of(context);
    final picked = await _pickAsset(
      title: l.presetFromAccount,
      pool: transferEligibleAssets,
      selected: _assetRowId,
      withNone: false,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _assetRowId = picked;
      _assetAuto = false;
      // 받는 계좌와 같으면 받는 계좌를 비운다 — 후보에서 빼지 않는다. 저장을 누르면 "받는 계좌를 골라주세요." 가 그 칸 아래에 뜬다
      if (_toAssetRowId == picked) {
        _toAssetRowId = null;
        _toAuto = false;
      }
    });
  }

  Future<void> _pickTo() async {
    final l = AppLocalizations.of(context);
    final picked = await _pickAsset(
      title: l.presetToAccount,
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
      _toAuto = false;
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
    final income = _isIncome;
    final picked = await PBottomSheet.show<String>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        final title = income ? l.expIncomeMethod : l.expPaymentMethod;
        return PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          flushBody: true,
          body: PickList<String>(
            label: title,
            selected: _paymentMethod,
            items: [
              PickItem(
                value: '',
                title: income ? l.txfNoIncomeMethod : l.presetNoPayment,
              ),
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
      // 안 맞는 계좌 · 카드는 비운다(사용자가 바꾼 결과라 바뀐 값으로 친다)
      if (picked.isNotEmpty && _assetRowId != null && !_isTransfer) {
        final cur = _assets.where((a) => a.rowId == _assetRowId).firstOrNull;
        if (cur != null && !allowTxAsset(cur, picked, _type)) {
          _assetRowId = null;
          _assetAuto = false;
        }
      }
    });
  }

  // ── 저장 ──────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_submitting) return;
    _draftLimit.dismiss();
    setState(() {
      _attempted = true;
      _saveError = false;
      _normalize();
    });
    final issue = _issue;
    final bad =
        issue != null ||
        (_isTransfer
            ? !transferPartiesReady(_assetRowId, _toAssetRowId)
            : !_hasCategory) ||
        _amountValue > kAmountMax ||
        _interestTooLarge;
    if (bad) {
      if (issue != null) _nameFocus.requestFocus();
      return;
    }
    // 요청이 오가는 동안 시트가 닫힐 수 있다 — 닫힌 뒤에는 ref 를 못 쓰므로 컨테이너를 먼저 잡는다
    final container = ProviderScope.containerOf(context);
    setState(() => _submitting = true);
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await container.read(presetRepositoryProvider.future);
      final name = _nameTrim;
      final merchant = _merchant.trim();
      final desc = _description.trim();
      final lock = _lock;
      final amount = lock ? _amountValue : null;
      final interest = _showInterest && _interest.isNotEmpty
          ? int.parse(_interest)
          : null;
      final fee = _isTransfer && _fee.isNotEmpty ? int.parse(_fee) : null;
      if (!_isNew) {
        // 이 폼이 가진 칸(거래처 · 메모 · 결제 수단 · 계좌 · 이체 칸)은 **비운 상태 그대로** 실어야 지워진다 — 서버가 키가 없으면
        // 유지로 읽는다(desk-back #325). 금액만 계약이 다르다: 금액이 없으면 고정이 아니므로 서버가 실린 금액을 버린다.
        await repo.update(
          id: widget.edit!.rowId,
          templateName: name,
          // 이체는 명시적 null — 키를 빼면 서버가 옛 카테고리를 유지해 TRANSFER 와 짝이 안 맞아 400 이다
          categoryRowId: Patch.set(_isTransfer ? null : _categoryRowId),
          assetRowId: Patch.set(_assetRowId),
          toAssetRowId: Patch.set(_isTransfer ? _toAssetRowId : null),
          fee: Patch.set(fee),
          interestAmount: Patch.set(interest),
          expenseType: _type,
          amount: amount,
          description: Patch.set(desc.isEmpty ? null : desc),
          merchant: Patch.set(
            _isTransfer || merchant.isEmpty ? null : merchant,
          ),
          paymentMethod: Patch.set(
            _isTransfer || _paymentMethod.isEmpty ? null : _paymentMethod,
          ),
          lockAmount: lock,
          // 이체는 고정이 없다 — 켜 둔 채 이체로 바꿔도 싣지 않는다(서버도 꺼 버린다).
          isFixed: !_isTransfer && _isFixed,
          silent: true,
        );
      } else {
        await repo.create(
          templateName: name,
          categoryRowId: _isTransfer ? null : _categoryRowId,
          assetRowId: _assetRowId,
          toAssetRowId: _isTransfer ? _toAssetRowId : null,
          fee: fee,
          interestAmount: interest,
          expenseType: _type,
          amount: amount,
          description: desc.isEmpty ? null : desc,
          merchant: _isTransfer || merchant.isEmpty ? null : merchant,
          paymentMethod: _isTransfer || _paymentMethod.isEmpty
              ? null
              : _paymentMethod,
          lockAmount: lock,
          isFixed: !_isTransfer && _isFixed,
          silent: true,
        );
      }
      // 목록을 다시 받은 **뒤에** 닫는다 — 닫혔을 때 줄이 이미 새 값이다
      container.invalidate(presetListProvider);
      try {
        await container.read(presetListProvider.future);
      } catch (_) {}
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } catch (e) {
      // 표면이 닫히지 않고 쓴 값이 남는다 — 알림은 폼 맨 위 Callout(고정 글). 서버가 거절하든 저장소를 못 만들든 같다
      if (!mounted) return;
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
      if (isUnconfirmedSave(e)) container.invalidate(presetListProvider);
      setState(() {
        _saveError = true;
        _failure = e;
      });
      // 폼을 아래까지 내려 저장했으면 Callout 이 화면 밖이다 — 보이는 자리로 올린다
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = _saveErrorKey.currentContext;
        if (c != null) {
          revealBelowFog(c);
        }
      });
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── 그리기 ────────────────────────────────────────────────
  String _stepTitle(AppLocalizations l, _Step s) => switch (s) {
    _Step.merchant => l.presetMerchant,
    _Step.memo => l.expDescription,
    _Step.amount => l.presetAmountLabel,
    _Step.fee => l.presetFeeLabel,
    _Step.interest => l.expInterest,
    _Step.none => '',
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 카테고리 · 자산 · 목록이 늦게 와도 줄이 새로 그려진다
    ref.watch(categoriesProvider);
    ref.watch(assetsProvider);
    ref.watch(presetListProvider);
    if (_step != _Step.none) return _buildStep(l);
    return _buildForm(l);
  }

  Widget _buildStep(AppLocalizations l) {
    // 머리 아래 16 에서 바로 첫 칸 — 본문 위 여백을 더하지 않는다(제목 줄 하단 → 입력 상자 위 끝 16, 라벨이 있으면 라벨 위 끝)
    const gutter = EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      0,
      PSpacing.globalGutter,
      PSpacing.x2,
    );
    final title = _stepTitle(l, _step);
    final Widget body;
    switch (_step) {
      case _Step.merchant:
        body = Padding(
          padding: gutter,
          child: PInput(
            controller: _draftCtrl,
            focusNode: _draftFocus,
            semanticLabel: title,
            placeholder: l.presetMerchantPlaceholder,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(kPresetMerchantMax),
            ],
            onSubmitted: (_) => _confirmStep(),
          ),
        );
      case _Step.memo:
        body = Padding(
          padding: gutter,
          child: PField(
            maxGraphemeCount: kPresetDescriptionMax,
            child: PTextarea(
              controller: _draftCtrl,
              focusNode: _draftFocus,
              semanticLabel: title,
              placeholder: l.presetMemoPlaceholder,
              maxHeight: 200,
            ),
          ),
        );
      default:
        body = Padding(
          padding: gutter,
          child: PField(
            description: _step == _Step.amount
                ? l.presetAmountHint
                : (_step == _Step.interest ? l.expInterestHint : null),
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
        );
    }
    return PBottomSheetContent(
      title: title,
      closeLabel: l.actionClose,
      showCloseButton: false,
      onBack: _requestLeaveStep,
      backLabel: l.actionBack,
      headerAction: StepDoneButton(
        label: l.actionDone,
        onPressed: _confirmStep,
      ),
      flushBody: true,
      body: body,
    );
  }

  /// 치는 값 줄 — 값 글(비었으면 안내 글) + 꺾쇠. 누르면 같은 시트 안에서 한 단계 들어간다. 값은 줄 끝 오른쪽 맞춤이다.
  Widget _stepRow({
    required String title,
    required IconData icon,
    required String value,
    required _Step step,
    int maxLines = 2,
    String? errorMessage,
  }) => _withError(
    errorMessage,
    PListButtonItem(
      title: title,
      prefix: Icon(icon),
      onTap: () => _enterStep(step),
      suffix: PListSuffix(
        children: [
          Text(
            keepAll(value),
            semanticsLabel: value,
            textAlign: TextAlign.end,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
        ],
      ),
    ),
  );

  /// 줄 아래 오류 한 줄(좌우 24) — [PickerRow] 의 오류와 같은 모양이다.
  Widget _withError(String? message, Widget row) {
    if (message == null) return row;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            0,
            PSpacing.globalGutter,
            PSpacing.x2,
          ),
          child: Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x1_5,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: PSpacing.x0_5),
                  child: ExcludeSemantics(
                    child: Icon(
                      LucideIcons.circleAlert,
                      size: 16,
                      color: c.fgCritical,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    message,
                    style: PTypography.t4.copyWith(color: c.fgCritical),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AppLocalizations l) {
    final c = context.colors;
    final cat = _selectedCategory;
    final from = _assets.where((a) => a.rowId == _assetRowId).firstOrNull;
    final to = _assets.where((a) => a.rowId == _toAssetRowId).firstOrNull;
    final nameError = _nameError(l);
    final categoryError = _attempted && !_isTransfer && !_hasCategory
        ? l.presetCategoryRequired
        : null;
    final fromError = _attempted && _isTransfer && _assetRowId == null
        ? l.presetFromRequired
        : null;
    final toError = _attempted && _isTransfer && _toAssetRowId == null
        ? l.presetToRequired
        : null;
    String won(String digits) =>
        krwSigned(int.parse(digits), false, unit: true);
    final amountValue = _amount.isEmpty ? l.presetAmountBlank : won(_amount);
    final amountError = _attempted && _amountValue > kAmountMax
        ? l.amountTooLarge
        : null;
    final interestError = _attempted && _interestTooLarge
        ? l.presetInterestTooLarge
        : null;
    final preview = ExpenseTemplate(
      rowId: 0,
      templateName: '',
      expenseType: _type,
    );

    return PBottomSheetContent(
      title: _isNew ? l.presetAdd : l.presetEditTitle,
      closeLabel: l.actionClose,
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
                description: saveFailureText(l, _failure, l.presetSaveFailed),
              ),
            ),
          // 종류 — 고른 값이 곧 폼의 갈래라 Chip 하나 고르기(좌우 24 · 아래 8)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PChipRadioGroup<String>(
              value: _type,
              onChanged: _onType,
              semanticLabel: l.presetTypeLabel,
              children: [
                PChipRadio<String>(
                  value: 'EXPENSE',
                  label: l.expTypeExpense,
                  variant: PChipVariant.outlineStrong,
                ),
                PChipRadio<String>(
                  value: 'INCOME',
                  label: l.expTypeIncome,
                  variant: PChipVariant.outlineStrong,
                ),
                PChipRadio<String>(
                  value: 'TRANSFER',
                  label: l.expTypeTransfer,
                  variant: PChipVariant.outlineStrong,
                ),
              ],
            ),
          ),
          // 미리보기 타일 52 + 이름 칸(좌우 24 · 아래 8 · 사이 12)
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
                SizedBox.square(
                  key: const ValueKey('preset-preview-tile'),
                  dimension: PSpacing.x13,
                  child: presetTile(
                    context,
                    preview,
                    cat,
                    size: PSpacing.x13,
                    iconSize: PSpacing.x6,
                  ),
                ),
                Expanded(
                  child: PField(
                    maxGraphemeCount: kPresetNameMax,
                    invalid: nameError != null,
                    errorMessage: nameError,
                    child: PInput(
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                      semanticLabel: l.presetName,
                      placeholder: l.expPresetNamePlaceholder,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isTransfer) ...[
            PickerRow(
              title: l.presetFromAccount,
              prefix: const Icon(LucideIcons.wallet),
              value: from?.assetName,
              placeholder: l.presetSelectOf(l.presetFromAccount),
              errorMessage: fromError,
              onTap: _pickFrom,
            ),
            PickerRow(
              title: l.presetToAccount,
              prefix: const Icon(LucideIcons.wallet),
              value: to?.assetName,
              placeholder: l.presetSelectOf(l.presetToAccount),
              errorMessage: toError,
              onTap: _pickTo,
            ),
            _stepRow(
              title: l.presetAmountLabel,
              icon: LucideIcons.coins,
              value: amountValue,
              step: _Step.amount,
              errorMessage: amountError,
            ),
            _stepRow(
              title: l.presetFeeLabel,
              icon: LucideIcons.percent,
              value: _fee.isEmpty
                  ? l.presetNoneOf(l.presetFeeLabel)
                  : won(_fee),
              step: _Step.fee,
            ),
            if (_showInterest)
              _stepRow(
                title: l.expInterest,
                icon: LucideIcons.percent,
                value: _interest.isEmpty
                    ? l.presetNoneOf(l.expInterest)
                    : won(_interest),
                step: _Step.interest,
                errorMessage: interestError,
              ),
          ] else ...[
            PickerRow(
              title: l.expCategory,
              prefix: const Icon(LucideIcons.tags),
              value: cat?.categoryName,
              placeholder: l.presetSelectOf(l.expCategory),
              leading: cat == null
                  ? null
                  : PickerDot(
                      color: resolveChartColor(
                        context,
                        cat.color,
                        fallback: c.fgBrand,
                      ),
                    ),
              errorMessage: categoryError,
              onTap: _pickCategory,
            ),
            _stepRow(
              title: l.presetMerchant,
              icon: LucideIcons.fileText,
              value: _merchant.isEmpty
                  ? l.presetNoneOf(l.presetMerchant)
                  : _merchant,
              step: _Step.merchant,
            ),
            PickerRow(
              title: _isIncome ? l.expIncomeMethod : l.expPaymentMethod,
              prefix: const Icon(LucideIcons.creditCard),
              value:
                  _payLabel(l, _paymentMethod) ??
                  (_isIncome ? l.txfNoIncomeMethod : l.presetNoPayment),
              onTap: _pickPayment,
            ),
            PickerRow(
              title: _isIncome ? l.expDepositAccount : l.presetAssetCard,
              prefix: const Icon(LucideIcons.wallet),
              value:
                  from?.assetName ??
                  (_isIncome ? l.txfNoDepositAccount : l.presetNoAccount),
              onTap: _pickAssetRow,
            ),
            _stepRow(
              title: l.presetAmountLabel,
              icon: LucideIcons.coins,
              value: amountValue,
              step: _Step.amount,
              errorMessage: amountError,
            ),
          ],
          _stepRow(
            title: l.expDescription,
            icon: LucideIcons.stickyNote,
            value: _description.isEmpty ? l.presetMemoNone : _description,
            step: _Step.memo,
          ),
          if (!_isTransfer)
            PList(
              semanticLabel: l.presetFixedTitleExpense,
              children: [
                PListSwitchItem(
                  title: _type == 'INCOME'
                      ? l.presetFixedTitleIncome
                      : l.presetFixedTitleExpense,
                  detail: l.presetFixedDesc,
                  checked: _isFixed,
                  onChanged: (v) => setState(() => _isFixed = v),
                ),
              ],
            ),
        ],
      ),
      footer: [
        PButton(
          label: _isNew ? l.presetSubmitAdd : l.actionSave,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
