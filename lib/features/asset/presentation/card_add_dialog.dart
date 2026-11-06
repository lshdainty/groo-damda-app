import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
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
import 'package:groo_damda_app/features/asset/presentation/pickers/card_product_picker.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/picker_sheet.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

export 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart'
    show showCardAddDialog, showCardEditDialog;

/// "없음" 선택지의 값 — 실제 자산 rowId 는 양수라 겹치지 않는다.
const int _kNoAccount = -1;

/// 오늘 — 결제 대기 청구분 칸은 오늘이 이번 달 결제일 전인지로 열린다. 테스트가 날짜를
/// 고정하도록 갈아 끼운다(`freshnessClockProvider` 와 같은 모양).
final cardFormClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// 카드 추가/수정 폼의 몸 — 신용카드 · 체크카드(I-17 11). 표면(시트 · 단계)은 `asset_form_sheet.dart` 가 쥔다.
/// 칸 차례: (수정만: 종류) → 카드 상품 → 별칭 → (신용) 신용한도 → 결제일 → [{날짜}에 결제될 금액] → 그 뒤 쓴 금액 / 이전 미결제 사용액 →
/// 통화(+ 환율) → 결제 출금계좌(신용) / 연결 계좌(체크) → 체크 줄 둘. 체크카드는 잔액을 들지 않는다.
///
/// 저장 본문(payload) · 요청 · 무효화는 이 폼이 처음부터 해 온 그대로다.
class CardAddBody extends ConsumerStatefulWidget {
  const CardAddBody({
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
  ConsumerState<CardAddBody> createState() => _CardAddBodyState();
}

class _CardAddBodyState extends ConsumerState<CardAddBody> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _dueCtrl;
  late final TextEditingController _creditLimitCtrl;

  /// 카드(신용 · 체크)는 원화만이다(I-13 사용자 결정 4, 서버 AST_037) — 통화 칸이 없고 늘 원화로 보낸다. 해외 결제는 거래의
  /// 통화 칸으로 적는다. 웹 `use-asset-form` 의 카드 묶음과 같다(옛 USD 카드도 수정하면 원화 · 환율 없음으로 나간다).
  String get _currency => kDefaultCurrency;
  late AssetKind _kind;
  late bool _includeInTotal;
  late bool _hideAmount;
  CardCatalogSummary? _selected;
  int? _paymentDay; // 결제일 1~31
  int? _paymentAssetRowId; // 결제 출금계좌 자산 rowId

  /// "없음" 을 골랐나 — 저장된 값은 null 하나라 "안 고름" 과 "없다고 답함" 을 못 가른다. 저장된 카드를 열면 null 은 없다고 답한 것이고,
  /// 새로 추가할 때만 안 고른 상태(자리 글)다(select.md "'없음' 을 고르면 값을 고른 것"). 저장 본문은 어느 쪽이든 null.
  bool _noAccountChosen = false;
  bool _submitting = false;
  bool _failed = false;

  /// 마지막 저장 실패의 서버 코드 — Callout 고정 글을 가르는 데만 쓴다(서버 원문은 내지 않는다).
  String? _failCode;
  final _errorKey = GlobalKey();
  bool _touched = false;

  /// 같은 시트가 "금액 보기 인증" 단계인가 — 칸에 쓴 값은 이 State 가 그대로 쥐고 있다.
  bool _unlocking = false;

  late final String _initialSignature;
  late final bool Function() _dirtyProbe;

  bool get _isEdit => widget.edit != null;
  bool get _isCredit => _kind == AssetKind.credit;

  /// 편집 중인 신용카드의 이월 금액을 고칠 수 없는가 — 이월이 든 회차의 결제일이
  /// 됐다(D15). 결제가 끝난 회차라 기록을 바꿔도 통장은 그대로인데, 서버도 400 이다.
  bool get _carryoverLocked =>
      widget.edit?.assetType == 'CREDIT_CARD' &&
      (widget.edit?.carryoverLocked ?? false);

  String get _todayKey =>
      toIsoLocal(ref.read(cardFormClockProvider)()).substring(0, 10);

  /// 신용카드로 저장돼 있던 자산을 고치는 중 — 이월 금액·결제일 규칙이 여기에만 걸린다.
  bool get _isExistingCredit =>
      _isEdit && widget.edit!.assetType == 'CREDIT_CARD' && _isCredit;

  /// 새 신용카드의 결제 대기 청구분 창 — 오늘이 이번 달 결제일 전일 때만 있다. 결제일을
  /// 바꾸면 따라 바뀐다.
  ({String dueDate, String afterDate})? get _newCardBillWindow =>
      !_isEdit && _isCredit ? pendingBillWindow(_todayKey, _paymentDay) : null;

  /// 결제 대기 청구분 칸(2026-09-22 사용자 결정) — 웹 `dueField` 미러.
  ///
  /// 결제일 전에 카드를 등록하면 실제 카드사는 지난달 청구분을 다가오는 결제일에, 이번 달
  /// 쓴 금액을 그다음 결제일에 뺀다. 한 칸으로 받으면 전부 다음 달에 빠져 한 달 동안 통장
  /// 잔액이 실제보다 많았다. 그래서 두 칸으로 받는다.
  ///  - 새 카드: 오늘이 이번 달 결제일 전이면 연다
  ///  - 기존 카드: 서버가 칸을 줄 때만 — 청구분이 있거나 등록한 달의 그 회차가 아직 열려
  ///    있을 때. 그 회차 결제일이 되면 잠긴다(D15 와 같다)
  ({String paymentDate, bool locked})? get _dueField {
    final window = _newCardBillWindow;
    if (window != null) return (paymentDate: window.dueDate, locked: false);
    final e = widget.edit;
    final date = e?.dueCarryover?.paymentDate;
    if (e?.assetType == 'CREDIT_CARD' && _isCredit && date != null) {
      return (paymentDate: date, locked: e!.dueCarryover!.locked);
    }
    return null;
  }

  String get _nicknameTrim => _nicknameCtrl.text.trim();

  /// 별칭은 선택 입력이다 — 비우면 카드 상품명으로 떨어지므로 중복을 안 본다.
  bool get _nicknameDuplicate =>
      _nicknameTrim.isNotEmpty &&
      (ref.read(assetsProvider).value ?? const <Asset>[]).any(
        (a) =>
            a.assetName.trim() == _nicknameTrim &&
            a.rowId != widget.edit?.rowId,
      );

  String? get _nicknameError {
    if (!_touched) return null;
    final l = AppLocalizations.of(context);
    if (_nicknameTrim.length > kAssetNameMax) {
      return l.nameTooLong(kAssetNameMax);
    }
    if (_nicknameDuplicate) return l.assetNicknameDuplicate;
    return null;
  }

  bool get _nicknameValid =>
      _nicknameTrim.length <= kAssetNameMax && !_nicknameDuplicate;

  /// 편집은 상품을 다시 고르지 않아도 별칭·금액만 바꿔 저장할 수 있어야 한다 — 새 카드만 상품이 필수다.
  bool get _productMissing => !_isEdit && _selected == null;

  /// 신용카드는 결제일이 필수다 — 없으면 명세서(예정 회차·할부 구성)가 성립하지 않는다.
  /// 결제일 없는 카드는 체크카드뿐이고 체크카드는 할부를 안 받는다(사용자 결정).
  /// 기존에 결제일 없이 등록된 신용카드도 여기서 걸린다 — 수정하며 채우게 된다.
  bool get _dayMissing => _isCredit && _paymentDay == null;

  /// 별칭 오류(touched 뒤 30자 · 중복)가 남아 있나.
  bool get _nameBlocked => _touched && !_nicknameValid;

  /// 누르고도 못 보낸 적이 있으면 필수 칸 오류를 세운다 — 고치면 저절로 걷힌다.
  bool _showErrors = false;

  final _productFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _dayFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    // 새 자산은 2단계 첫 칸에 초점(웹 focusFirstField) — 시트 컨테이너가 처음 초점을 가져가므로 그려진 뒤 직접 준다.
    // 수정은 키보드 없이 표면
    if (widget.edit == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _productFocus.requestFocus();
      });
    }
    _kind = e?.assetType == 'CHECK_CARD'
        ? AssetKind.check
        : (e != null ? AssetKind.credit : widget.initialKind);
    _nicknameCtrl = TextEditingController(text: e?.assetName ?? '')
      ..addListener(_onNicknameChanged);
    // 이 칸은 "이전 미결제 사용액" — 카드를 만들 때 적은 **이월 금액**이다(D7). 편집은
    // 서버가 내려 준 이월 금액으로 채운다. 지금 총 미결제 잔액(balance)으로 채우면 저장만
    // 해도 이월이 잔액만큼 새로 생겨 빚이 두 배가 됐다(QA 23차 1). 부호는 저장 규약이라
    // 절댓값만 보인다. 새 카드는 빈 칸이다.
    _balanceCtrl = TextEditingController(
      text: e == null ? '' : initialAmountText((e.carryoverAmount ?? 0).abs()),
    );
    // 결제 대기 청구분 — 기존 카드는 서버가 준 값으로 연다. 칸이 없으면 안 쓴다(`_dueField`).
    _dueCtrl = TextEditingController(
      text: e == null
          ? ''
          : initialAmountText(
              (e.assetType == 'CREDIT_CARD' ? (e.dueCarryover?.amount ?? 0) : 0)
                  .abs(),
            ),
    );
    _creditLimitCtrl = TextEditingController(
      text: initialAmountText(e?.creditLimit),
    );
    _paymentDay = e?.paymentDay;
    _paymentAssetRowId = e?.paymentAssetRowId;
    _noAccountChosen = e != null && e.paymentAssetRowId == null;
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    // 새 자산은 가리지 않는다 — 만들자마자 금액이 안 보이면 잘못 만든 줄 안다.
    _hideAmount = e != null && e.isAmountHidden == 'Y';
    // 연결된 상품을 고른 상태로 되살린다. 카탈로그 목록은 rowId 로 하이라이트하므로
    // 요약(rowId·이름·이미지·발급사)만 있으면 충분하다.
    final c = e?.cardCatalog;
    if (c != null) {
      _selected = CardCatalogSummary(
        rowId: c.rowId,
        cardName: c.cardName,
        cardType: _kind.cardApiCode,
        imgUrl: c.imgUrl,
        company: c.companyName == null
            ? null
            : CardCompany(name: c.companyName, logoUrl: c.companyLogoUrl),
      );
    }
    _initialSignature = _signature();
    _dirtyProbe = () => _signature() != _initialSignature;
    widget.probe.dirty = _dirtyProbe;
  }

  /// 쓴 값 — 닫기 · 뒤로 가기 전에 "작성한 내용이 사라져요" 를 묻는다.
  String _signature() => [
    _kind.name,
    _selected?.rowId ?? '',
    _nicknameCtrl.text,
    _balanceCtrl.text,
    _dueCtrl.text,
    _creditLimitCtrl.text,
    _paymentDay ?? '',
    _paymentAssetRowId ?? '',
    _noAccountChosen,
    _includeInTotal,
    _hideAmount,
  ].join('\u0001');

  /// 별칭 리스너 — 카탈로그 검색과 달리 여기서만 touched 를 세운다.
  /// 검색어를 쳤다고 별칭 에러가 빨개지면 무슨 일이 났는지 알 수 없다.
  void _onNicknameChanged() => setState(() => _touched = true);

  @override
  void dispose() {
    if (widget.probe.dirty == _dirtyProbe) widget.probe.dirty = () => false;
    _productFocus.dispose();
    _nameFocus.dispose();
    _dayFocus.dispose();
    _nicknameCtrl.dispose();
    _balanceCtrl.dispose();
    _dueCtrl.dispose();
    _creditLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCard() async {
    final picked = await showCardProductPicker(
      context,
      cardType: _kind.cardApiCode!,
      currentRowId: _selected?.rowId,
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  /// [저장] — 숨김을 푸는 저장은 본인 확인을 거친다(QA 22차 #2). 앱은 생체인증이 먼저고, 안 되면 같은 시트의 "금액 보기 인증"
  /// 단계로 바뀐다(I-17 21) — 확인하기 전에는 요청이 나가지 않고, ←(취소)면 저장도 안 한다.
  /// [추가] · [저장] — 단추는 늘 켜 둔다. 필수가 비었으면 칸마다 안내를 세우고 첫 칸에 초점을 보낸다(요청은 안 나간다).
  void _attempt() {
    if (_submitting) return;
    if (_productMissing || _nameBlocked || _dayMissing) {
      setState(() => _showErrors = true);
      // 칸 차례대로 첫 칸 — 카드 상품 → 별칭 → 결제일
      (_productMissing
              ? _productFocus
              : _nameBlocked
              ? _nameFocus
              : _dayFocus)
          .requestFocus();
      return;
    }
    _submit();
  }

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

  /// 결제일 확인 · 저장 본문 · 요청 · 무효화 — 이 폼이 처음부터 해 온 그대로다.
  Future<void> _save() async {
    if (_submitting || _productMissing || _nameBlocked || _dayMissing) return;
    final l = AppLocalizations.of(context);
    final edit = widget.edit;
    // 결제일을 바꾸면 다음 회차부터다(D5) — 아직 결제 전인 회차는 옛 결제일에 결제된다.
    // 그걸 모르고 바꾸면 이번 달 결제가 사라진 줄 안다. 한 번 알리고 확인받는다.
    if (!await _confirmPaymentDayChange(l)) return;
    if (!mounted) return;
    final nickname = _nicknameCtrl.text.trim();
    // 편집에서 상품을 다시 고르지 않았으면 기존 값으로 채운다.
    final name = nickname.isNotEmpty
        ? nickname
        : (_selected?.cardName ?? edit?.assetName ?? l.assetNewCard);
    // 체크카드는 잔액을 들지 않는다 — 사용액은 연결 계좌에서 이미 빠져 있다.
    //
    // 신용카드의 이 칸은 이월 금액이다. 만들 때는 잔액(음수 — 미결제 사용액)으로 보내
    // 서버가 이월 거래를 만든다. 서버도 같은 정규화를 하지만 여기서도 맞춰 보낸다.
    final usage = parseAmountField(_balanceCtrl) ?? 0;
    // 결제 대기 청구분은 칸이 있을 때만 읽는다 — 결제일을 바꿔 칸이 사라졌으면 적어 둔
    // 값이 남아 있어도 안 보낸다.
    final dueField = _dueField;
    final due = dueField == null ? 0 : (parseAmountField(_dueCtrl) ?? 0);
    final outstanding = _isCredit ? signedBalance('CREDIT_CARD', usage) : 0;
    final company = _selected?.company?.name ?? edit?.institution;
    final catalogRowId = _selected?.rowId ?? edit?.cardCatalog?.rowId;
    // 청구 사이클 필드는 신용카드일 때만. 빈 한도는 null 로 전송.
    final isCredit = _isCredit;
    final creditLimit = isCredit ? parseAmountField(_creditLimitCtrl) : null;
    // 카드는 원화만 — 환율은 늘 명시적 null 로 지운다(옛 외화 카드도 원화로 돌아간다).
    const double? fxRate = null;

    setState(() {
      _failed = false;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      // brand color hex 는 모바일 측에선 별도 파싱이라 institution 으로 추후 매칭.
      // (web 의 color 필드는 같은 효과를 내는 보조 정보)
      if (edit != null) {
        // 이 화면이 소유한 칸(한도·결제일·결제 계좌·통화·환율)은 비운 상태 그대로
        // 실어야 지워진다 — 키를 빼면 서버가 옛 값을 지킨다(QA #99). 신용에서 체크로
        // 바꾸면 한도·결제일이 실제로 지워져야 청구 사이클이 남지 않는다.
        // 메모는 이 화면에 없는 칸이라 안 넘긴다 — 계좌 화면에서 적어 둔 값이 산다.
        //
        // 통화는 이제 이 화면의 칸이다(D1). 종전엔 고르는 자리가 없어 일부러 안 실었다
        // — 안 그러면 웹에서 USD 로 만든 해외 카드가 앱 편집 한 번에 원화가 되고
        // 서버가 환산율까지 1 로 정규화했다(`Asset.normalizeRate`). 이제 화면이
        // 지금 통화를 읽어 와 보여 주므로 그대로 실어도 값이 바뀌지 않는다.
        //
        // 신용카드는 잔액을 싣지 않는다 — 서버가 무시한다. 이월은 `carryoverAmount` 키로만
        // 고치고(D7), 결제가 끝나 잠긴 이월은 키째 뺀다(D15 — 값이 같아도 안 보낸다).
        // 체크카드는 종전처럼 0 을 싣는다.
        await repo.update(
          id: edit.rowId,
          assetName: name,
          assetType: _kind.assetType,
          balance: isCredit ? null : outstanding,
          carryoverAmount: isCredit && !_carryoverLocked ? usage : null,
          // 청구분 칸이 열려 있으면 0 도 싣는다 — 0 이면 서버가 지운다. 잠긴 칸은 키째 뺀다.
          dueCarryoverAmount: isCredit && dueField != null && !dueField.locked
              ? due
              : null,
          currency: _currency,
          exchangeRate: Patch.set(fxRate),
          institution: company,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          isAmountHidden: _hideAmount ? 'Y' : 'N',
          cardCatalogRowId: catalogRowId,
          creditLimit: Patch.set(creditLimit),
          paymentDay: Patch.set(isCredit ? _paymentDay : null),
          // 계좌 연결은 두 종류 다 쓴다 — 신용은 결제일 자동이체, 체크는 즉시 차감.
          paymentAssetRowId: Patch.set(_paymentAssetRowId),
          silent: true,
        );
      } else {
        await repo.create(
          assetName: name,
          assetType: _kind.assetType,
          balance: outstanding,
          currency: _currency,
          exchangeRate: fxRate,
          institution: company,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          isAmountHidden: _hideAmount ? 'Y' : 'N',
          cardCatalogRowId: catalogRowId,
          creditLimit: creditLimit,
          paymentDay: isCredit ? _paymentDay : null,
          // 계좌 연결은 두 종류 다 쓴다 — 신용은 결제일 자동이체, 체크는 즉시 차감.
          paymentAssetRowId: _paymentAssetRowId,
          // 만들 때는 청구분이 있을 때만 싣는다 — 없으면 [balance] 하나로 종전 그대로다.
          dueCarryoverAmount: isCredit && dueField != null && due > 0
              ? due
              : null,
          silent: true,
        );
      }
      // 자산이 하나 늘거나 줄면 순자산·추이·청구·실적이 함께 달라진다 —
      // 전부 별도 조회라 목록만 비우면 옛 값이 남는다.
      invalidateAfterAssetChange(ref);
      // 신용카드의 이월 금액은 **거래**다(이전 미결제 사용액) — 만들거나 고치면 가계부
      // 목록·자산 상세 이용 내역도 달라진다. 자산만 비우면 옛 이월 행이 남는다.
      if (isCredit) {
        ref.invalidate(monthExpensesProvider);
        invalidateAfterExpenseChange(ref);
      }
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 폼은 열린 채 쓴 값 · 단계가 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      // 고쳐 다시 할 수 있는 코드(AST_037 카드는 원화만)만 다른 고정 글로 가른다(I-13).
      if (!mounted) return;
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
      if (isUnconfirmedSave(e)) {
        invalidateAfterAssetChange(ref);
        ref.invalidate(monthExpensesProvider);
        invalidateAfterExpenseChange(ref);
      }
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

  /// 결제일을 바꾸는 저장이면 확인받는다(D5) — 옛 결제일로 결제되는 회차를 말한다.
  ///
  /// 신용카드 편집에서, 원래 결제일이 있고 다른 날로 바꿀 때만 묻는다(처음 넣는 결제일은
  /// 옛 결제일이 없다). 물러나면 false — 저장하지 않는다.
  Future<bool> _confirmPaymentDayChange(AppLocalizations l) async {
    final edit = widget.edit;
    final oldDay = edit?.paymentDay;
    final newDay = _paymentDay;
    if (edit == null ||
        !_isCredit ||
        edit.assetType != 'CREDIT_CARD' ||
        oldDay == null ||
        newDay == null ||
        oldDay == newDay) {
      return true;
    }
    final today = _todayKey;
    final pending = pendingCycleOnOldDay(
      oldPaymentDay: oldDay,
      cardClosedThrough: edit.cardClosedThrough,
      todayKey: today,
      // 결제일을 이미 한 번 바꿔 둔 카드면 그 회차는 더 옛 결제일로 나간다 — 서버가 준
      // 실제 결제일이 먼저다(QA 26 4).
      nextPaymentDate: edit.nextPaymentDate,
    );
    final date = monthDay(DateTime.parse(pending.paymentDate));
    // 폼 시트 위에 뜨는 확인창(ds Alert Dialog) — 취소 · 저장
    return PAlertDialog.show(
      context,
      title: l.assetPaymentDayChangeAsk,
      description: l.assetPaymentDayChangeConfirm(pending.month, date),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionSave,
    );
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
    final unit = currencyUnit(_currency);
    final isCredit = _isCredit;
    final newCardBillWindow = _newCardBillWindow;
    final dueField = _dueField;
    // 결제 출금계좌 후보 — 본인 소유 BANK_ACCOUNT 자산.
    final bankAccounts = (ref.watch(assetsProvider).value ?? const <Asset>[])
        .where((a) => a.assetType == 'BANK_ACCOUNT')
        .toList(growable: false);

    // 한도 초과 — 저장은 막지 않는다(QA #125). 기존 신용카드는 칸이 이월 금액이라 칸 값만으로는 사용액이 아니다 —
    // 지금 미결제 잔액에서 이월을 고친 만큼을 더하고 뺀 값이 저장 뒤 사용액이다.
    final edit = widget.edit;
    final currentUnpaid = _isExistingCredit
        ? ((edit!.balance ?? 0) < 0 ? -(edit.balance ?? 0) : 0)
        : 0;
    final dueAmount = dueField == null ? 0 : (parseAmountField(_dueCtrl) ?? 0);
    final balanceAmount = parseAmountField(_balanceCtrl) ?? 0;
    final usageForLimit = _isExistingCredit
        ? (currentUnpaid -
                  (edit!.carryoverAmount ?? 0).abs() +
                  balanceAmount -
                  (edit.dueCarryover?.amount ?? 0).abs() +
                  dueAmount)
              .clamp(0, 1 << 62)
        : balanceAmount + dueAmount;
    final limitAmount = isCredit
        ? (parseAmountField(_creditLimitCtrl) ?? 0)
        : 0;
    final overLimitBy = limitAmount > 0 && usageForLimit > limitAmount
        ? usageForLimit - limitAmount
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
      // 이 칸은 이월 금액이라 지금 갚을 돈과 다르다 — 지금 미결제 잔액을 설명으로 알려 둬서 둘을 헷갈리지 않게 한다(D7).
      if (_isExistingCredit)
        l.assetOutstandingNow(krwSigned(currentUnpaid, false, unit: true)),
      if (_carryoverLocked)
        l.assetCarryoverLocked
      else
        dueField == null
            ? l.assetCurrentUsageHint
            : newCardBillWindow != null
            ? l.assetCarryoverAfterHint(
                monthDay(DateTime.parse(newCardBillWindow.afterDate)),
              )
            : l.assetCarryoverAfterHintNoDate,
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
          // 신용 ↔ 체크 전환은 결제일 필수 여부를 바꾼다 — 고른 상품은 잃지 않는다(web 동일).
          AssetKindField(
            kind: _kind,
            onChanged: (k) => setState(() => _kind = k),
          ),
        PickerField(
          label: l.assetCardProduct,
          placeholder: l.assetCardPlaceholder,
          value: _selected?.cardName,
          onOpen: _pickCard,
          focusNode: _productFocus,
          invalid: _showErrors && _productMissing,
          errorMessage: l.assetFormErrCard,
        ),
        AssetNameField(
          controller: _nicknameCtrl,
          placeholder: _selected?.cardName ?? l.assetCardNicknamePlaceholder,
          errorMessage: _nicknameError,
          optional: true,
          focusNode: _nameFocus,
        ),
        // 신용카드 — 신용한도 → 결제일 → 청구분 → 사용액. 신용한도는 선택이다(저장 막힘에 한도 조건이 없다).
        if (isCredit) ...[
          AssetAmountField(
            label: l.assetCreditLimitLabel,
            controller: _creditLimitCtrl,
            unit: unit,
            optional: true,
            onChanged: (_) => setState(() {}),
          ),
          PField(
            label: l.assetPaymentDayLabel,
            invalid: _showErrors && _dayMissing,
            errorMessage: l.assetFormErrPaymentDay,
            child: PSelect<int>(
              focusNode: _dayFocus,
              groups: [
                PSelectGroup(
                  items: [
                    for (var d = 1; d <= 31; d++)
                      PSelectItem(value: d, label: l.dayN(d)),
                  ],
                ),
              ],
              value: _paymentDay,
              placeholder: l.assetPaymentDaySelect,
              onChanged: (v) => setState(() => _paymentDay = v),
            ),
          ),
          // 결제 대기 청구분(2026-09-22) — 결제일 전에 등록하면 지난달 청구분은 다가오는 결제일에,
          // 그 뒤 쓴 금액은 그다음 결제일에 빠진다. 칸 이름에 그 날짜를 쓴다.
          if (dueField != null)
            AssetAmountField(
              inputKey: const ValueKey('due-carryover-input'),
              label: l.assetDueCarryoverLabel(
                monthDay(DateTime.parse(dueField.paymentDate)),
              ),
              controller: _dueCtrl,
              unit: unit,
              readOnly: dueField.locked,
              description: dueField.locked
                  ? l.assetCarryoverLocked
                  : l.assetDueCarryoverHint,
              onChanged: (_) => setState(() {}),
            ),
          // 현재 사용액 — 체크카드는 잔액 개념이 없다(긁는 즉시 연결 계좌에서 빠진다). 신용카드만 결제일까지 사용액을 든다.
          AssetAmountField(
            label: dueField != null
                ? l.assetCarryoverAfterLabel
                : l.assetCurrentUsage,
            controller: _balanceCtrl,
            unit: unit,
            // 이월이 든 회차의 결제일이 됐으면 못 고친다(D15).
            readOnly: _carryoverLocked,
            description: balanceLines.join('\n'),
            descriptionIcon: overLimitBy > 0 ? LucideIcons.triangleAlert : null,
            onChanged: (_) => setState(() {}),
          ),
        ],
        // 계좌 연결 — 신용카드는 결제일에 여기서 한 번에 빠지고, 체크카드는 긁는 즉시 빠진다. 의미가 달라 라벨을 나눈다.
        PField(
          label: isCredit
              ? l.assetPaymentAccountLabel
              : l.assetLinkedAccountLabel,
          indicator: PFieldIndicator.optional,
          description: isCredit
              ? l.assetPaymentAccountHint
              : l.assetLinkedAccountHint,
          child: PSelect<int>(
            groups: [
              // 비울 수 있는 칸 — "{칸 이름} 없음" 을 맨 앞 따로 묶음에(select.md). 연결을 끊으면 명시적 null 로 실린다
              PSelectGroup(
                items: [
                  PSelectItem(
                    value: _kNoAccount,
                    label: isCredit
                        ? l.assetNoPaymentAccount
                        : l.assetNoLinkedAccount,
                  ),
                ],
              ),
              PSelectGroup(
                items: [
                  for (final a in bankAccounts)
                    PSelectItem(
                      value: a.rowId,
                      label: a.institution != null && a.institution!.isNotEmpty
                          ? '${a.institution} · ${a.assetName}'
                          : a.assetName,
                    ),
                ],
              ),
            ],
            value: _noAccountChosen && bankAccounts.isNotEmpty
                ? _kNoAccount
                : _paymentAssetRowId,
            placeholder: bankAccounts.isEmpty
                ? l.assetNoBankAccounts
                : (isCredit
                      ? l.assetPaymentAccountSelect
                      : l.assetLinkedAccountSelect),
            disabled: bankAccounts.isEmpty,
            onChanged: (v) => setState(() {
              _noAccountChosen = v == _kNoAccount;
              _paymentAssetRowId = v == _kNoAccount ? null : v;
            }),
          ),
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
