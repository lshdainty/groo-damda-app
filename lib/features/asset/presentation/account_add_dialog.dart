import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_unlock_step.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_sign.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_currency_fields.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_parts.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/institution_picker.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/picker_sheet.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/brand/bank_colors.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';

export 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart'
    show showAccountAddDialog, showAccountEditDialog;

/// 계좌 추가/수정 폼의 몸 — 입출금 · 예금 · 적금 · 마이너스 통장 · 현금 · 대출(I-17 11). 표면(시트 · 단계)은
/// `asset_form_sheet.dart` 가 쥔다. 칸 차례: (수정만: 종류) → 기관 → 별칭 → 메모 → 금액 → (마이너스 통장) 약정 한도 → 통화(+ 환율) → 체크 줄 둘.
///
/// 저장 본문(payload) · 요청 · 무효화는 이 폼이 처음부터 해 온 그대로다.
class AccountAddBody extends ConsumerStatefulWidget {
  const AccountAddBody({
    super.key,
    required this.edit,
    required this.initialKind,
    required this.probe,
    this.onBack,
  });

  final Asset? edit;
  final AssetKind initialKind;
  final AssetFormProbe probe;
  final VoidCallback? onBack;

  @override
  ConsumerState<AccountAddBody> createState() => _AccountAddBodyState();
}

class _AccountAddBodyState extends ConsumerState<AccountAddBody> {
  final _nameFocus = FocusNode();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _fxRateCtrl;

  /// 사용자가 고른 통화. `null` 이면 아직 아무것도 안 골랐다.
  String? _currencyPick;

  /// 이 폼이 지금 쓰는 통화 — **고른 값 > 이 자산의 값 > 설정의 기본 통화**(D7).
  ///
  /// 기본 통화를 `initState` 에서 굳히면 안 된다. `/me/preferences` 는 설정 화면을
  /// 안 들른 세션에서 이 폼보다 늦게 도착해서, 초기값으로 받으면 첫 렌더의 원화에
  /// 잠긴 채 열린다. `build` 가 구독해 두고 저장할 때까지 매번 여기서 읽는다.
  ///
  /// 기본 통화는 **새 자산에만** 흘린다. 기존 자산에까지 쓰면 기본 통화를 USD 로
  /// 바꾼 순간 원화 자산이 전부 USD 로 열리고, 그대로 저장만 해도 통화가 바뀐다 —
  /// 고치라고 만든 칸이 고장을 내는 쪽이다. 통화가 안 적힌 옛 자산도 원화로 연다
  /// (웹 `Asset.currency` 는 non-null 이라 그쪽엔 없는 갈래다).
  String get _currency =>
      _currencyPick ??
      (widget.edit != null
          ? (widget.edit!.currency ?? kDefaultCurrency)
          : ref.read(defaultCurrencyProvider));
  late String _brand;
  late AssetKind _kind;
  late bool _includeInTotal;
  late bool _hideAmount;
  bool _submitting = false;
  bool _failed = false;

  /// 마지막 저장 실패의 서버 코드 — Callout 고정 글을 가르는 데만 쓴다(서버 원문은 내지 않는다).
  String? _failCode;
  final _errorKey = GlobalKey();
  bool _touched = false;

  /// [추가] · [저장] 을 한 번이라도 눌렀나 — 필수 칸(별칭)의 안내는 이때부터 보인다.
  bool _showErrors = false;

  /// 같은 시트가 "금액 보기 인증" 단계인가 — 칸에 쓴 값은 이 State 가 그대로 쥐고 있다.
  bool _unlocking = false;

  late final String _initialSignature;
  late final bool Function() _dirtyProbe;

  bool get _isEdit => widget.edit != null;

  /// 이 폼이 다루는 자산 유형 — [AssetKind] 가 매핑하는 것과 같다.
  static const _accountTypes = {'BANK_ACCOUNT', 'SAVINGS', 'CASH', 'LOAN'};

  String get _nicknameTrim => _nicknameCtrl.text.trim();

  /// 같은 별칭이 둘이면 거래 입력의 계좌 선택에서 어느 쪽인지 알 수 없다. 별칭은 필수다(카드만 선택).
  bool get _nicknameDuplicate =>
      _nicknameTrim.isNotEmpty &&
      (ref.read(assetsProvider).value ?? const <Asset>[]).any(
        (a) =>
            a.assetName.trim() == _nicknameTrim &&
            a.rowId != widget.edit?.rowId,
      );

  /// 카테고리 다이얼로그와 같은 규칙 — touched 전에는 빨갛게 만들지 않는다.
  /// 기존에 100자로 저장된 별칭을 편집하려고 열자마자 에러가 뜨면 안 된다.
  String? get _nicknameError {
    final l = AppLocalizations.of(context);
    if (_showErrors && _nicknameTrim.isEmpty) return l.assetNicknameRequired;
    if (!_touched) return null;
    if (_nicknameTrim.length > kAssetNameMax) {
      return l.nameTooLong(kAssetNameMax);
    }
    if (_nicknameDuplicate) return l.assetNicknameDuplicate;
    return null;
  }

  bool get _nicknameValid =>
      _nicknameTrim.length <= kAssetNameMax && !_nicknameDuplicate;

  /// 웹과 같은 흐름 — touched 전엔 눌러서 에러를 노출하고, 그 뒤엔 valid 일 때만 저장한다. 단추는 늘 켜 두고 누르면 알린다.
  bool get _nameBlocked =>
      _nicknameTrim.isEmpty || (_touched && !_nicknameValid);

  /// 외화면 환율이 필수다(서버 AST_036, I-13) — 비우면 칸 오류로 막는다.
  bool get _blocked =>
      _nameBlocked || exchangeRateMissing(_currency, _fxRateCtrl);

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    // 새 자산은 2단계 첫 칸에 초점(웹 focusFirstField) — 시트 컨테이너가 처음 초점을 가져가므로 그려진 뒤 직접 준다.
    // 수정은 키보드 없이 표면
    if (widget.edit == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocus.requestFocus();
      });
    }
    _kind = widget.initialKind;
    // 저장된 기관 이름은 목록에 없어도 그대로 둔다(웹과 같다) — 첫 기관으로 바꾸면 고치기만 해도 기관이 바뀐다.
    // 기관이 없는 자산은 빈 칸이다. 새 자산만 첫 항목이 기본이다.
    _brand = e == null ? bankEntries.first.name : (e.institution ?? '');
    _nicknameCtrl = TextEditingController(text: e?.assetName ?? '')
      ..addListener(_onNicknameChanged);
    // 부호는 시스템이 정한다(QA #19). 화면은 늘 '얼마' 만 묻는다 —
    // 마이너스 통장이면 사용 중인 금액, 대출이면 남은 빚. 새 자산은 빈 칸이다.
    _balanceCtrl = TextEditingController(
      text: e == null ? '' : initialAmountText((e.balance ?? 0).abs()),
    );
    _limitCtrl = TextEditingController(text: initialAmountText(e?.creditLimit));
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    _fxRateCtrl = TextEditingController(
      text: e?.exchangeRate != null ? trimExchangeRate(e!.exchangeRate!) : '',
    );
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    // 새 자산은 가리지 않는다 — 만들자마자 금액이 안 보이면 잘못 만든 줄 안다.
    _hideAmount = e != null && e.isAmountHidden == 'Y';
    _initialSignature = _signature();
    _dirtyProbe = () => _signature() != _initialSignature;
    widget.probe.dirty = _dirtyProbe;
  }

  /// 쓴 값 — 닫기 · 뒤로 가기 전에 "작성한 내용이 사라져요" 를 묻는다. 통화는 고른 것만 본다(기본 통화가 늦게 와도 쓴 값이 아니다).
  String _signature() => [
    _kind.name,
    _brand,
    _nicknameCtrl.text,
    _balanceCtrl.text,
    _limitCtrl.text,
    _memoCtrl.text,
    _fxRateCtrl.text,
    _currencyPick ?? '',
    _includeInTotal,
    _hideAmount,
  ].join('\u0001');

  void _onNicknameChanged() => setState(() => _touched = true);

  @override
  void dispose() {
    if (widget.probe.dirty == _dirtyProbe) widget.probe.dirty = () => false;
    _nameFocus.dispose();
    _nicknameCtrl.dispose();
    _balanceCtrl.dispose();
    _limitCtrl.dispose();
    _fxRateCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBrand() async {
    final picked = await showInstitutionPicker(
      context,
      invest: false,
      current: _brand,
    );
    if (picked != null && mounted) setState(() => _brand = picked);
  }

  /// [추가] · [저장] — 단추는 늘 켜 둔다. 막힌 값(별칭 오류)이 있으면 그 칸에 초점을 보내 안내를 보게 하고 요청은 안 나간다.
  void _attempt() {
    if (_submitting) return;
    if (_blocked) {
      setState(() => _showErrors = true);
      if (_nameBlocked) _nameFocus.requestFocus();
      return;
    }
    _submit();
  }

  /// 숨김을 푸는 저장은 본인 확인을 거친다(QA 22차 #2). 앱은 생체인증이 먼저고, 안 되면 같은 시트의 "금액 보기 인증"
  /// 단계로 바뀐다(I-17 21) — 확인하기 전에는 요청이 나가지 않고, ←(취소)면 저장도 안 한다.
  Future<void> _submit() async {
    if (_submitting) return;
    if (assetUnhideNeedsConfirm(
      wasHidden: widget.edit?.isAmountHidden == 'Y',
      nowHidden: _hideAmount,
    )) {
      final ok = await tryHideAmountsBiometric(context, ref);
      if (!mounted) return;
      if (!ok) {
        setState(() => _unlocking = true);
        return;
      }
    }
    await _save();
  }

  /// 저장 본문 · 요청 · 무효화 — 이 폼이 처음부터 해 온 그대로다.
  Future<void> _save() async {
    if (_submitting) return;
    final brand = _brand;
    final nickname = _nicknameCtrl.text.trim();
    final name = nickname;
    // 기관이 없는 자산은 키를 보내지 않는다 — 빈 문자열이 서버에 기관으로 남지 않게.
    final institution = brand.isEmpty ? null : brand;
    // 환율은 외화일 때만 보낸다. 비우면 서버가 1로 잡아 환산 없이 더해진다.
    final fxRate = isForeignCurrency(_currency)
        ? double.tryParse(_fxRateCtrl.text.replaceAll(',', ''))
        : null;
    // 메모는 칸 하나다(추가 · 수정 모두) — 비면 null.
    final memo = _memoCtrl.text.trim();
    final memoForApi = memo.isEmpty ? null : memo;
    // 계좌 그룹 밖 자산(카드·투자)이 흘러들어오면 원본 유형을 유지한다 —
    // `AssetKind.of` 가 모르는 유형을 입출금으로 떨어뜨리므로,
    // 저장하며 조용히 BANK_ACCOUNT 로 바뀌는 사고를 막는다.
    final original = widget.edit?.assetType;
    final assetType = original != null && !_accountTypes.contains(original)
        ? original
        : _kind.assetType;
    // 부호는 사용자가 아니라 종류가 정한다(QA #19) — 입력칸은 절대값만 받는다.
    final isOverdraft = _kind == AssetKind.overdraft;
    final balance = signedBalance(
      assetType,
      parseAmountField(_balanceCtrl) ?? 0,
      isOverdraft: isOverdraft,
    );
    // 마이너스 한도는 신용카드 한도와 같은 컬럼(`credit_limit`)을 쓴다 — 선택 입력.
    final limit = isOverdraft ? parseAmountField(_limitCtrl) : null;

    setState(() {
      _failed = false;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        // 이 화면이 소유한 칸(환율·메모·마이너스 한도)은 비운 상태 그대로 실어야
        // 지워진다 — 키를 빼면 서버가 옛 값을 지킨다(QA #99). 카드 전용 칸
        // (결제일·결제 계좌·카탈로그)은 여기 없으므로 안 넘겨 그대로 둔다.
        await repo.update(
          id: widget.edit!.rowId,
          assetName: name,
          assetType: assetType,
          balance: balance,
          currency: _currency,
          exchangeRate: Patch.set(fxRate),
          institution: institution,
          memo: Patch.set(memoForApi),
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          isAmountHidden: _hideAmount ? 'Y' : 'N',
          creditLimit: Patch.set(limit),
          isOverdraft: isOverdraft,
          silent: true,
        );
      } else {
        await repo.create(
          assetName: name,
          assetType: assetType,
          balance: balance,
          currency: _currency,
          exchangeRate: fxRate,
          institution: institution,
          memo: memoForApi,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          isAmountHidden: _hideAmount ? 'Y' : 'N',
          creditLimit: limit,
          isOverdraft: isOverdraft,
          silent: true,
        );
      }
      // 자산이 하나 늘거나 줄면 순자산·추이·청구·실적이 함께 달라진다 —
      // 전부 별도 조회라 목록만 비우면 옛 값이 남는다.
      invalidateAfterAssetChange(ref);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 폼은 열린 채 쓴 값 · 단계가 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      // 고쳐 다시 할 수 있는 코드(AST_036 · AST_037)만 다른 고정 글로 가른다(I-13).
      if (!mounted) return;
      setState(() {
        _failed = true;
        _failCode = e.code;
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
    if (_unlocking) {
      return HideAmountsUnlockStep(
        onBack: () => setState(() => _unlocking = false),
        onVerified: () {
          setState(() => _unlocking = false);
          _save();
        },
      );
    }
    // 설정의 기본 통화가 늦게 도착하면 이 폼을 다시 그린다 — 값은 `_currency` 가
    // 읽는다(고른 값 > 이 자산의 값 > 기본 통화).
    ref.watch(defaultCurrencyProvider);
    // 별칭 중복은 자산 목록 캐시를 읽는다 — 읽기만 하면 목록이 먼저 비워질 수 있어 폼이 열려 있는 동안 붙들어 둔다.
    ref.watch(assetsProvider);
    // 단위는 칸 뒤 글자다. 표기 규칙은 `currencyUnit` 한 곳이고 웹도 그걸 쓴다.
    final unit = currencyUnit(_currency);
    final isOverdraft = _kind == AssetKind.overdraft;
    final balanceLabel = switch (_kind) {
      // 무엇을 묻는지가 종류마다 다르다 — 마이너스 통장은 '얼마나 썼나', 대출은 '얼마나 남았나' 다. 둘 다 양수로 받는다.
      AssetKind.overdraft => l.assetOverdraftUsedLabel,
      AssetKind.loan => l.assetLoanRemainingLabel,
      _ => l.assetBalanceLabel,
    };
    // 한도 초과 — 저장은 막지 않는다(사용자 결정, QA #125). 넘겼다는 사실만 보인다. 한도를 안 적었으면 견줄 값이 없다.
    final limitAmount = isOverdraft ? (parseAmountField(_limitCtrl) ?? 0) : 0;
    final usage = parseAmountField(_balanceCtrl) ?? 0;
    final overLimitBy = limitAmount > 0 && usage > limitAmount
        ? usage - limitAmount
        : 0;
    final balanceLines = <String>[
      if (overLimitBy > 0)
        l.assetOverLimitHelp(
          formatOriginalAmount(
            overLimitBy.toDouble(),
            _currency,
            Localizations.localeOf(context).languageCode,
          ),
        ),
      if (isOverdraft) l.assetOverdraftHint,
      if (_kind == AssetKind.loan) l.assetLoanHint,
      // 잔액 수동 수정 = 새 앵커. 그 시각 이전 내역은 이 잔액에 이미 들어 있는 것으로 보고 이후 내역만 더해진다 —
      // 모르고 고치면 방금 한 이체가 잔액에서 사라진 것처럼 보인다.
      if (_isEdit) l.assetBalanceEditHint,
    ];
    return AssetFormFrame(
      title: _isEdit
          ? l.assetFormTitleEdit(_kind.label(l))
          : l.assetFormTitleAdd(_kind.label(l)),
      submitLabel: _isEdit ? l.actionSave : l.calAdd,
      onBack: widget.onBack,
      submitting: _submitting,
      errorMessage: _failed ? assetSaveFailedText(l, _failCode) : null,
      errorKey: _errorKey,
      onSubmit: _attempt,
      fields: [
        if (_isEdit)
          AssetKindField(
            kind: _kind,
            onChanged: (k) => setState(() => _kind = k),
          ),
        PickerField(
          label: l.assetInstitutionBrand,
          placeholder: l.assetInstitutionPlaceholder,
          value: _brand.isEmpty ? null : _brand,
          onOpen: _pickBrand,
        ),
        AssetNameField(
          controller: _nicknameCtrl,
          placeholder: l.assetNicknamePlaceholder,
          errorMessage: _nicknameError,
          focusNode: _nameFocus,
        ),
        AssetMemoField(controller: _memoCtrl),
        AssetAmountField(
          label: balanceLabel,
          controller: _balanceCtrl,
          unit: unit,
          description: balanceLines.isEmpty ? null : balanceLines.join('\n'),
          descriptionIcon: overLimitBy > 0 ? LucideIcons.triangleAlert : null,
          onChanged: (_) => setState(() {}),
        ),
        // 약정 한도 (선택) — 신용카드 한도와 같은 컬럼을 쓴다. 한도는 사용액과 견주는 값이라 같은 통화 단위를 쓴다.
        if (isOverdraft)
          AssetAmountField(
            label: l.assetOverdraftLimitLabel,
            controller: _limitCtrl,
            unit: unit,
            optional: true,
            onChanged: (_) => setState(() {}),
          ),
        // 통화·환율 — 외화통장. 통화는 자산 유형과 무관하게 연다(해외 카드·외화 대출).
        // 카드·투자 폼도 같은 위젯을 쓴다 — 세 폼이 각자 베끼면 한쪽만 고쳐진다.
        AssetCurrencyFields(
          currency: _currency,
          rateController: _fxRateCtrl,
          onCurrencyChanged: (v) => setState(() => _currencyPick = v),
          showErrors: _showErrors,
        ),
      ],
      checks: AssetCheckRows(
        includeInTotal: _includeInTotal,
        onIncludeInTotal: (v) => setState(() => _includeInTotal = v),
        hideAmount: _hideAmount,
        onHideAmount: (v) => setState(() => _hideAmount = v),
      ),
    );
  }
}
