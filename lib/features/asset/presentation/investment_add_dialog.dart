import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_unlock_step.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_currency_fields.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_parts.dart';
import 'package:groo_damda_app/features/asset/presentation/holding_format.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/institution_picker.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/picker_sheet.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/stock_add_picker.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/stocks/application/live_prices.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/brand/bank_colors.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';

export 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart'
    show showInvestmentAddDialog, showInvestmentEditDialog;

/// 투자에 노출되는 브랜드만 평탄화 (증권사 + 가상자산거래소).
List<BankEntry> get _investBrands => [
  for (final cat in investCategories) ...?bankEntriesByCategory[cat],
];

/// 편집 중 보유 1행 — 도메인 값 + 리스트가 바뀌어도 유지되는 위젯 key.
/// 이름 인라인 수정·행 삭제에도 입력 State 가 엉키지 않게 한다 (front `EditHolding.key` 미러).
typedef _EditRow = ({String key, AssetHolding holding});

int _editRowSeq = 0;
String _nextRowKey() => 'eh-${++_editRowSeq}';

/// 투자 추가/수정 폼의 몸 — design `AssetEditDialog`(group='invest', tossapi5) 미러. 표면(시트 · 단계)은 `asset_form_sheet.dart` 가 쥔다.
/// 칸 차례: 증권사 · 거래소 → 별칭 → 보유 종목 → 예수금(보유 없을 때) / 평가액 합계(보유 있을 때 · 읽기 전용) → 통화(+ 환율) → 메모 →
/// 체크 줄 둘. 보유 종목은 연동(종목 검색 → 현재가 × 수량) · 직접(이름 + 평가액). 저장하면 보유 전체를 교체한다.
///
/// 저장 본문(payload) · 요청 · 무효화는 이 폼이 처음부터 해 온 그대로다.
class InvestmentAddBody extends ConsumerStatefulWidget {
  const InvestmentAddBody({
    super.key,
    required this.edit,
    required this.probe,
    this.onBack,
  });

  final Asset? edit;
  final AssetFormProbe probe;
  final VoidCallback? onBack;

  @override
  ConsumerState<InvestmentAddBody> createState() => _InvestmentAddBodyState();
}

class _InvestmentAddBodyState extends ConsumerState<InvestmentAddBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _memoCtrl;
  late final TextEditingController _cashCtrl;
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
  late bool _includeInTotal;
  late bool _hideAmount;
  late List<_EditRow> _rows;
  bool _submitting = false;
  bool _failed = false;
  final _errorKey = GlobalKey();

  /// [추가] · [저장] 을 한 번이라도 눌렀나 — 필수 칸(별칭)의 안내는 이때부터 보인다.
  bool _showErrors = false;
  final _nameFocus = FocusNode();

  /// 같은 시트가 "금액 보기 인증" 단계인가 — 칸에 쓴 값은 이 State 가 그대로 쥐고 있다.
  bool _unlocking = false;

  late final String _initialSignature;
  late final bool Function() _dirtyProbe;

  bool get _isEdit => widget.edit != null;

  Iterable<AssetHolding> get _holdings => _rows.map((r) => r.holding);

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
    // 기관이 없는 자산은 비워 둔다 — 첫 기관으로 채우면 고치기만 해도 엉뚱한 기관이 저장된다. 새 자산만 첫 항목이 기본이다.
    // 저장된 기관 이름은 목록에 없어도 그대로 둔다(웹과 같다) — 첫 기관으로 바꾸면 고치기만 해도 기관이 바뀐다.
    // 기관이 없는 자산은 빈 칸이다. 새 자산만 첫 항목이 기본이다.
    _brand = e == null ? _investBrands.first.name : (e.institution ?? '');
    // 별칭 — 사용자가 지은 이름을 보존한다. 저장 때 기관명으로 덮으면
    // "금 현물" 같은 이름이 "NH투자" 로 사라진다(웹 AssetEditDialog 미러).
    _nameCtrl = TextEditingController(text: e?.assetName ?? '');
    _memoCtrl = TextEditingController(text: e?.memo ?? '');
    // 예수금 — 보유가 없을 때만 쓰인다(전량 매도 대금 등). 새 자산은 빈 칸이다.
    _cashCtrl = TextEditingController(
      text: e == null ? '' : initialAmountText(e.cashBalance ?? e.balance ?? 0),
    );
    _fxRateCtrl = TextEditingController(
      text: e?.exchangeRate != null ? trimExchangeRate(e!.exchangeRate!) : '',
    );
    _includeInTotal = e == null ? true : e.isIncludedInTotal == 'Y';
    // 새 자산은 가리지 않는다 — 만들자마자 금액이 안 보이면 잘못 만든 줄 안다.
    _hideAmount = e != null && e.isAmountHidden == 'Y';
    // 기존 보유 복사. 레거시 단일 연동(tossSymbol/tossQuantity)은 보유 1건으로 이관.
    _rows = e == null
        ? []
        : e.holdings.isNotEmpty
        ? [for (final h in e.holdings) (key: _nextRowKey(), holding: h)]
        : (e.tossSymbol?.isNotEmpty ?? false) && e.tossQuantity != null
        ? [
            (
              key: _nextRowKey(),
              holding: AssetHolding(
                linked: true,
                marketCode: e.marketCode,
                tossSymbol: e.tossSymbol,
                quantity: e.tossQuantity?.toString(),
              ),
            ),
          ]
        : [];
    _initialSignature = _signature();
    _dirtyProbe = () => _signature() != _initialSignature;
    widget.probe.dirty = _dirtyProbe;
  }

  /// 쓴 값 — 닫기 · 뒤로 가기 전에 "작성한 내용이 사라져요" 를 묻는다. 보유 줄의 위젯 key 는 뺀다.
  String _signature() => [
    _brand,
    _nameCtrl.text,
    _memoCtrl.text,
    _cashCtrl.text,
    _fxRateCtrl.text,
    _currencyPick ?? '',
    _includeInTotal,
    _hideAmount,
    for (final h in _holdings)
      [
        h.linked,
        h.holdingType.name,
        h.holdingName ?? '',
        h.tossSymbol ?? '',
        h.marketCode ?? '',
        h.quantity ?? '',
        h.holdingValue ?? '',
        h.totalCost ?? '',
      ].join('|'),
  ].join('\u0001');

  @override
  void dispose() {
    if (widget.probe.dirty == _dirtyProbe) widget.probe.dirty = () => false;
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _memoCtrl.dispose();
    _cashCtrl.dispose();
    _fxRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBrand() async {
    final picked = await showInstitutionPicker(
      context,
      invest: true,
      current: _brand,
    );
    if (picked != null && mounted) setState(() => _brand = picked);
  }

  // ── 보유 종목 상태 조작 ────────────────────────────────────────
  Future<void> _openStockSheet() async {
    final picked = await showStockAddPicker(
      context,
      excludeSymbols: {
        for (final h in _holdings)
          if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) h.tossSymbol!,
      },
    );
    if (picked == null || !mounted) return;
    final found = picked.found;
    if (found != null) {
      _addLinked(found);
    } else {
      _addManual(picked.manualName ?? '');
    }
  }

  void _addLinked(StockMasterItem s) {
    // 시세 게이트 OFF(비구독·토스 미연결)면 연동해도 평가액을 못 구하므로 수동 항목으로 추가
    // — 사용자가 평가액을 직접 입력해 합계에 반영(사용자 결정).
    if (!_liveEnabled) {
      _addManual(s.nameKr);
      return;
    }
    setState(() {
      _rows = [
        ..._rows,
        (
          key: _nextRowKey(),
          holding: AssetHolding(
            linked: true,
            // 검색 결과가 시장을 알고 있다 — 여기서 안 담으면 서버는 심볼로 되짚어야 하고,
            // 여러 시장에 걸리는 티커(SPY·IVV 등)는 확정하지 못한다.
            marketCode: s.marketCode,
            tossSymbol: s.symbol,
            quantity: '1',
            holdingName: s.nameKr, // 표시용 — 직렬화 시 linked 는 심볼·수량만 전송.
            sortOrder: _rows.length,
          ),
        ),
      ];
    });
  }

  void _addManual(String name) {
    setState(() {
      _rows = [
        ..._rows,
        (
          key: _nextRowKey(),
          holding: AssetHolding(
            holdingType: _manualHoldingType,
            holdingName: name,
            holdingValue: 0,
            sortOrder: _rows.length,
          ),
        ),
      ];
    });
  }

  /// 금·코인은 검색 대상이 아니다(토스·마스터 모두 미제공) — 빈 행으로만 담는다.
  /// 기관이 보유 유형을 정한다 — 증권사에서 코인을, 금거래소에서 주식을 담을 일은 없다.
  /// 모르는 기관(구버전 데이터·직접 입력)이면 종전대로 셋 다 열어 둔다.
  String? get _brandHoldingType {
    for (final e in bankEntries) {
      if (e.name == _brand) return categoryHoldingType[e.category];
    }
    return null;
  }

  bool get _allowStock =>
      _brandHoldingType == null || _brandHoldingType == 'STOCK';

  /// 손으로 추가하는 보유의 유형.
  ///
  /// 기관이 정해져 있으면 그 카테고리를 따른다(상품거래소=금, 코인거래소=코인).
  /// 기관을 안 골랐으면 **이미 담아 둔 보유**를 본다 — 금만 있는 자산에 항목을
  /// 추가했는데 주식으로 저장되면 단위가 "주" 로 나오고 유형 분리가 무의미해진다.
  /// 둘 다 단서가 없을 때만 주식이다.
  AssetHoldingType get _manualHoldingType {
    switch (_brandHoldingType) {
      case 'GOLD':
        return AssetHoldingType.gold;
      case 'CRYPTO':
        return AssetHoldingType.crypto;
      case 'STOCK':
        return AssetHoldingType.stock;
      default:
        final types = _rows.map((r) => r.holding.holdingType).toSet();
        return types.length == 1 ? types.first : AssetHoldingType.stock;
    }
  }

  List<AssetHoldingType> get _manualAddTypes {
    switch (_brandHoldingType) {
      case 'GOLD':
        return const [AssetHoldingType.gold];
      case 'CRYPTO':
        return const [AssetHoldingType.crypto];
      case 'STOCK':
        return const [];
      default:
        return const [AssetHoldingType.gold, AssetHoldingType.crypto];
    }
  }

  void _addTyped(AssetHoldingType type) {
    setState(() {
      _rows = [
        ..._rows,
        (
          key: _nextRowKey(),
          holding: AssetHolding(
            holdingType: type,
            holdingName: '',
            holdingValue: 0,
            sortOrder: _rows.length,
          ),
        ),
      ];
    });
  }

  void _updateRow(String key, AssetHolding next) {
    setState(() {
      _rows = [
        for (final r in _rows)
          if (r.key == key) (key: r.key, holding: next) else r,
      ];
    });
  }

  void _removeRow(String key) {
    setState(() {
      _rows = [
        for (final r in _rows)
          if (r.key != key) r,
      ];
    });
  }

  /// 시세 연동 가능 여부 — 증권 구독 + 토스 연결 둘 다여야 실시간 평가가 가능하다.
  bool get _liveEnabled {
    final features = ref.read(myFeaturesProvider).asData?.value;
    return (features?.hasSecurities ?? false) &&
        (features?.hasBrokerConnection ?? false);
  }

  /// 연동 심볼 1주 KRW 환산가 맵 — 게이트 OFF·시세 미확보 심볼은 null.
  ///
  /// 환산 규칙은 [livePricesProvider] 한 곳에 있다 — 자산 목록·상세와 같은 걸 써야
  /// 한 화면에서 총액과 종목별 금액이 어긋나지 않는다(실제로 어긋난 적이 있다).
  Map<String, double?> _unitKrwMap() {
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final gate =
        (features?.hasSecurities ?? false) &&
        (features?.hasBrokerConnection ?? false);
    final symbols = {
      for (final h in _holdings)
        if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) h.tossSymbol!,
    }.toList()..sort();
    if (!gate || symbols.isEmpty) return const {};
    // 다시 받는 동안·실패한 동안에도 앞 시세를 쓴다 — 자산 목록·상세와 같은 값을 보여야 한다.
    final live = ref.watch(livePricesProvider(livePricesKey(symbols))).value;
    if (live == null) return const {};
    return {for (final s in symbols) s: live.unitKrw(s)};
  }

  /// 보유 합계(KRW) — manual 합 + 시세 확보된 linked 합.
  /// **미리보기 표시 전용** — 저장되는 평가액은 서버가 BigDecimal 로 산정한다.
  int _totalOf(Map<String, double?> unitMap, Iterable<AssetHolding> holdings) {
    var total = 0.0;
    for (final h in holdings) {
      if (h.linked) {
        final unit = unitMap[h.tossSymbol];
        if (unit != null) total += unit * h.quantityValue;
      } else {
        total += (h.holdingValue ?? 0).toDouble();
      }
    }
    return total.round();
  }

  /// [저장] — 숨김을 푸는 저장은 본인 확인을 거친다(QA 22차 #2). 앱은 생체인증이 먼저고, 안 되면 같은 시트의 "금액 보기 인증"
  /// 단계로 바뀐다(I-17 21) — 확인하기 전에는 요청이 나가지 않고, ←(취소)면 저장도 안 한다.
  Future<void> _submit() async {
    if (_submitting) return;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _showErrors = true);
      _nameFocus.requestFocus();
      return;
    }
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
    // 별칭은 필수다 — 비어 있으면 _submit 이 막는다.
    final resolvedName = _nameCtrl.text.trim();
    final institution = brand.isEmpty ? null : brand;
    final memo = _memoCtrl.text.trim();
    // 추가만 하고 이름을 안 채운 미연동 행은 버린다 — 이름 빈 미연동은 서버가 400 으로 막는다.
    // 순서는 이 목록의 순서 그대로다 — 서버가 배열 인덱스로 sortOrder 를 매긴다(QA #91).
    // 예전엔 여기서 번호를 다시 매겨 실어 보냈는데, 서버가 그 필드를 안 받아 버려졌다.
    final holdings = [
      for (final h in _holdings)
        if (h.linked || (h.holdingName?.trim().isNotEmpty ?? false)) h,
    ];
    // 평가액은 **서버가** 시세×수량을 BigDecimal 로 산정한다 — 클라이언트 계산값은 보내지 않는다.
    // 보유가 없으면 남는 건 예수금뿐이라 입력값을 보낸다 — 0 으로 밀면 전량 매도 대금이 사라진다.
    final int? balance = holdings.isEmpty
        ? (parseAmountField(_cashCtrl) ?? 0)
        : null;
    // 환율은 외화일 때만 보낸다 — 원화로 되돌리면 명시적 null 로 지운다.
    final fxRate = isForeignCurrency(_currency)
        ? double.tryParse(_fxRateCtrl.text.replaceAll(',', ''))
        : null;

    setState(() {
      _failed = false;
      _submitting = true;
    });
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      if (_isEdit) {
        // 메모·통화·환율은 이 화면이 소유한 칸이라 비운 상태 그대로 실어야 지워진다 —
        // 키를 빼면 서버가 옛 값을 지킨다(QA #99).
        //
        // 통화는 이제 이 화면의 칸이다(D1). 종전엔 고르는 자리가 없어 일부러 안 실었다
        // — 안 그러면 웹에서 USD 로 만든 해외 증권계좌가 앱 편집 한 번에 원화가 되고
        // 서버가 환산율까지 1 로 정규화했다(`Asset.normalizeRate`). 이제 화면이
        // 지금 통화를 읽어 와 보여 주므로 그대로 실어도 값이 바뀌지 않는다.
        await repo.update(
          id: widget.edit!.rowId,
          assetName: resolvedName,
          assetType: 'INVESTMENT',
          balance: balance,
          currency: _currency,
          exchangeRate: Patch.set(fxRate),
          institution: institution,
          memo: Patch.set(memo.isEmpty ? null : memo),
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          isAmountHidden: _hideAmount ? 'Y' : 'N',
          holdings: holdings,
          silent: true,
        );
      } else {
        // 메모는 생성 화면에도 칸이 있다 — 종전엔 안 실어서, 적어 넣고 저장하면
        // 그대로 사라졌다. 비었으면 키를 빼 서버 기본값(없음)에 맡긴다.
        await repo.create(
          assetName: resolvedName,
          assetType: 'INVESTMENT',
          balance: balance,
          currency: _currency,
          exchangeRate: fxRate,
          institution: institution,
          memo: memo.isEmpty ? null : memo,
          isIncludedInTotal: _includeInTotal ? 'Y' : 'N',
          isAmountHidden: _hideAmount ? 'Y' : 'N',
          holdings: holdings,
          silent: true,
        );
      }
      // 자산이 하나 늘거나 줄면 순자산·추이·청구·실적이 함께 달라진다 —
      // 전부 별도 조회라 목록만 비우면 옛 값이 남는다.
      invalidateAfterAssetChange(ref);
      ref.invalidate(investmentValuationMapProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException {
      // 폼은 열린 채 쓴 값 · 단계가 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      if (!mounted) return;
      setState(() => _failed = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) revealBelowFog(ctx);
      });
    } finally {
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
    final unitMap = _unitKrwMap();
    final total = _totalOf(unitMap, _holdings);
    final unit = currencyUnit(_currency);
    return AssetFormFrame(
      title: _isEdit
          ? l.assetFormTitleEdit(l.assetTypeInvestment)
          : l.assetFormTitleAdd(l.assetTypeInvestment),
      submitLabel: _isEdit ? l.actionSave : l.calAdd,
      onBack: widget.onBack,
      submitting: _submitting,
      errorMessage: _failed ? l.assetSaveFailed : null,
      errorKey: _errorKey,
      onSubmit: _submit,
      fields: [
        PickerField(
          label: l.assetBrokerExchange,
          placeholder: l.assetInstitutionPlaceholder,
          value: _brand.isEmpty ? null : _brand,
          onOpen: _pickBrand,
        ),
        AssetNameField(
          controller: _nameCtrl,
          placeholder: l.assetProductPlaceholder,
          errorMessage: _showErrors && _nameCtrl.text.trim().isEmpty
              ? l.assetNicknameRequired
              : null,
          focusNode: _nameFocus,
        ),
        _HoldingsEditor(
          rows: _rows,
          total: total,
          unitMap: unitMap,
          allowStock: _allowStock,
          manualAddTypes: _manualAddTypes,
          onAddStock: _openStockSheet,
          onAddTyped: _addTyped,
          onChanged: _updateRow,
          onRemove: _removeRow,
        ),
        // 예수금 — 보유가 없을 때만 노출한다. 보유가 있으면 평가금액은 서버가 시세로 산정하고 예수금은 입금·매도로만 움직여야 해서,
        // 여기서 총액을 적으면 이중 계상된다. 보유가 있으면 합계를 읽기 전용으로 보인다(연동 합계는 원화로 환산한 값이라 단위가 원이다).
        if (_rows.isEmpty)
          AssetAmountField(
            label: l.assetCashBalance,
            controller: _cashCtrl,
            unit: unit,
            onChanged: (_) => setState(() {}),
          )
        else
          PField(
            label: l.assetHoldingValueLabel,
            description: l.assetBalanceAutoHelp,
            child: PInput(
              key: const ValueKey('holdings-total'),
              readOnly: true,
              initialValue: formatAmountInput(total),
              suffixText: wonUnit(),
              tabularFigures: true,
            ),
          ),
        AssetCurrencyFields(
          currency: _currency,
          rateController: _fxRateCtrl,
          onCurrencyChanged: (v) => setState(() => _currencyPick = v),
        ),
        AssetMemoField(controller: _memoCtrl),
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

/// 투자의 "보유 종목" 칸(I-17 16) — 머리(칸 이름 + 오른쪽 요약), 종목 추가 줄, 유형 묶음(주식 · 금 · 코인)별 보유 줄.
/// 보유 줄은 이름(연동 = 글 + "연동" 배지 · 직접 = 입력) · 수량 · 평가액(연동 = 읽기 전용 · 직접 = 금액 칸) · 매수원가 · 지우기.
class _HoldingsEditor extends StatelessWidget {
  const _HoldingsEditor({
    required this.rows,
    required this.total,
    required this.unitMap,
    required this.allowStock,
    required this.manualAddTypes,
    required this.onAddStock,
    required this.onAddTyped,
    required this.onChanged,
    required this.onRemove,
  });

  final List<_EditRow> rows;
  final int total;
  final Map<String, double?> unitMap;
  final bool allowStock;
  final List<AssetHoldingType> manualAddTypes;
  final VoidCallback onAddStock;
  final ValueChanged<AssetHoldingType> onAddTyped;
  final void Function(String key, AssetHolding next) onChanged;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return PField(
      label: l.assetHoldings,
      headerTrailing: Text(
        keepAll(l.assetHoldingsSummary(rows.length, krw(total))),
        textAlign: TextAlign.end,
        // 머리 값 글 — slider.yaml headerValue(t5 · 700 · fg-neutral · 고른 숫자 모양)
        style: PTypography.t5.copyWith(
          color: c.fgNeutral,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x2,
        children: [
          // 종목 추가 — 주식은 검색 시트, 금 · 코인은 검색 대상이 아니라 직접 추가로만 담는다(토스 · 마스터 모두 미제공).
          // 기관이 유형을 정하므로 증권사면 금 · 코인 단추가 없다.
          if (allowStock || manualAddTypes.isNotEmpty)
            Wrap(
              spacing: PSpacing.x2,
              runSpacing: PSpacing.x2,
              children: [
                if (allowStock)
                  PButton(
                    label: l.assetAddStock,
                    variant: PButtonVariant.neutralOutline,
                    size: PButtonSize.small,
                    prefixIcon: LucideIcons.plus,
                    onPressed: onAddStock,
                  ),
                for (final type in manualAddTypes)
                  PButton(
                    label: type == AssetHoldingType.gold
                        ? l.assetHoldingAddGold
                        : l.assetHoldingAddCrypto,
                    variant: PButtonVariant.neutralOutline,
                    size: PButtonSize.small,
                    prefixIcon: LucideIcons.plus,
                    onPressed: () => onAddTyped(type),
                  ),
              ],
            ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PSpacing.x0_5),
              child: Text(
                keepAll(
                  allowStock
                      ? l.assetHoldingsEmptyEdit
                      : l.assetHoldingsEmptyManual,
                ),
                style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
              ),
            )
          else
            // 유형별 섹션 — 해당 유형이 없으면 섹션 자체를 그리지 않는다. 라벨과 목록은 한 묶음이라 유형이 하나뿐이어도 어떤 단위인지 드러난다.
            for (final type in AssetHoldingType.values)
              if (rows.any((r) => r.holding.holdingType == type))
                Column(
                  // 다른 유형 섹션이 사라져도 이 섹션의 행 State(입력 중 값)가 유지되도록.
                  key: ValueKey(type),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PListHeader(
                      title: holdingTypeLabel(l, type),
                      headingLevel: 3,
                      inset: 0,
                    ),
                    for (final r in rows)
                      if (r.holding.holdingType == type)
                        _HoldingEditRow(
                          key: ValueKey(r.key),
                          holding: r.holding,
                          unitKrw: r.holding.linked
                              ? unitMap[r.holding.tossSymbol]
                              : null,
                          onChanged: (next) => onChanged(r.key, next),
                          onRemove: () => onRemove(r.key),
                        ),
                  ],
                ),
        ],
      ),
    );
  }
}

/// 보유 종목 편집 1행 — 연동: 이름·배지 + 수량 + 평가액(시세 계산, 읽기 전용) /
/// 미연동: 이름 입력 + 수량(선택) + 평가액 입력. 매수원가(실현손익의 기준)와 지우기.
class _HoldingEditRow extends StatefulWidget {
  const _HoldingEditRow({
    super.key,
    required this.holding,
    required this.unitKrw,
    required this.onChanged,
    required this.onRemove,
  });
  final AssetHolding holding;
  final double? unitKrw; // 연동 1주 KRW 환산가 (미확보 시 null)
  final ValueChanged<AssetHolding> onChanged;
  final VoidCallback onRemove;

  @override
  State<_HoldingEditRow> createState() => _HoldingEditRowState();
}

class _HoldingEditRowState extends State<_HoldingEditRow> {
  late final TextEditingController _qtyCtrl;
  // 미연동 전용 — 이름·평가액 직접 입력.
  late final TextEditingController _nameCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _costCtrl;

  /// 연동 줄의 평가액(읽기 전용) — 시세가 바뀔 때마다 글만 바꾼다.
  final TextEditingController _linkedValueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final h = widget.holding;
    // 입력 중 '3.' 같은 중간 상태는 controller 가 들고 있으므로 모델에서 되쓰지 않는다.
    // 수량은 이미 문자열이라 그대로 띄운다 — 숫자를 거치면 소수 표기가 흔들린다.
    _qtyCtrl = TextEditingController(text: h.quantity ?? '');
    _nameCtrl = TextEditingController(text: h.holdingName ?? '');
    _valueCtrl = TextEditingController(
      text: initialAmountText(h.holdingValue ?? 0),
    );
    // 매수원가 — 비어 있으면 안 보내고 서버가 기존 값을 잇는다.
    _costCtrl = TextEditingController(
      text: h.totalCost != null && h.totalCost! > 0
          ? initialAmountText(h.totalCost)
          : '',
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _costCtrl.dispose();
    _linkedValueCtrl.dispose();
    super.dispose();
  }

  void _onQtyChanged(String v) =>
      widget.onChanged(widget.holding.copyWith(quantity: holdingQtyText(v)));

  void _onValueChanged(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    widget.onChanged(widget.holding.copyWith(holdingValue: n));
  }

  void _onCostChanged(String v) {
    final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
    widget.onChanged(widget.holding.copyWith(totalCost: n));
  }

  void _onNameChanged(String v) =>
      widget.onChanged(widget.holding.copyWith(holdingName: v));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final h = widget.holding;
    final name = (h.holdingName?.isNotEmpty ?? false)
        ? h.holdingName!
        : (h.tossSymbol ?? '');
    final value = widget.unitKrw != null
        ? (widget.unitKrw! * h.quantityValue).round()
        : null;
    final linkedText = value != null ? formatAmountInput(value) : '—';
    if (_linkedValueCtrl.text != linkedText) _linkedValueCtrl.text = linkedText;

    // 평단가 — 원가와 수량이 있을 때만(원가 ÷ 수량)
    final cost =
        int.tryParse(_costCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final avg = cost > 0 && h.quantityValue > 0
        ? (cost / h.quantityValue).round()
        : null;

    final quantityField = PField(
      label: l.assetHoldingQuantity,
      child: PInput(
        controller: _qtyCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: const [HoldingQtyInputFormatter()],
        suffixText: holdingUnitLabel(l, h.holdingType),
        tabularFigures: true,
        onChanged: _onQtyChanged,
      ),
    );
    // 평가액 — 연동은 시세로 계산(읽기 전용), 미연동은 직접 입력
    final valueField = PField(
      label: l.assetHoldingValueLabel,
      child: h.linked
          ? PInput(
              controller: _linkedValueCtrl,
              readOnly: true,
              // 시세가 아직 없어 "—" 이면 단위를 붙이지 않는다("—원" 금지)
              suffixText: value != null ? wonUnit() : null,
              tabularFigures: true,
            )
          : PInput(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [AmountInputFormatter(max: kBalanceMax)],
              suffixText: wonUnit(),
              tabularFigures: true,
              onChanged: _onValueChanged,
            ),
    );
    // 글자가 커지면 두 칸을 아래 위로 쌓아 값이 가려지지 않게 한다
    final wide = MediaQuery.textScalerOf(context).scale(16) <= 24;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x3,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: PSpacing.x2,
            children: [
              Expanded(
                child: h.linked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: PSpacing.x0_5,
                        children: [
                          Wrap(
                            spacing: PSpacing.x2,
                            runSpacing: PSpacing.x1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                keepAll(name),
                                style: PTypography.t5.copyWith(
                                  color: c.fgNeutral,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              PBadge(
                                label: l.assetHoldingLinkedBadge,
                                tone: PBadgeTone.informative,
                              ),
                            ],
                          ),
                          Text(
                            keepAll(
                              widget.unitKrw != null
                                  ? l.assetHoldingLinkedSub(
                                      krwSigned(
                                        widget.unitKrw!.round(),
                                        false,
                                        unit: true,
                                      ),
                                    )
                                  : l.assetHoldingLinkedBadge,
                            ),
                            style: PTypography.t3.copyWith(
                              color: c.fgNeutralSubtle,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      )
                    // 미연동은 이름도 고칠 수 있어야 한다 — 금·코인은 검색으로 이름을 받지 못한다.
                    : PInput(
                        controller: _nameCtrl,
                        semanticLabel: l.assetHoldingItemName,
                        placeholder: l.assetHoldingNamePlaceholder,
                        onChanged: _onNameChanged,
                      ),
              ),
              PButton.icon(
                icon: LucideIcons.trash2,
                semanticLabel: l.assetHoldingRemoveOf(name),
                variant: PButtonVariant.ghost,
                ghostColor: PButtonGhostColor.neutralSubtle,
                size: PButtonSize.small,
                onPressed: widget.onRemove,
              ),
            ],
          ),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x3,
              children: [
                Expanded(flex: 2, child: quantityField),
                Expanded(flex: 3, child: valueField),
              ],
            )
          else ...[
            quantityField,
            valueField,
          ],
          // 매수원가 — 실현손익의 기준. 매수·매도로 쌓이지만 앱을 쓰기 전부터 갖고 있던 보유는 여기서 적어 넣어야 손익이 맞는다.
          // 비워 두면 서버가 같은 종목의 기존 원가를 잇는다.
          PField(
            label: l.holdingTotalCost,
            description: avg == null
                ? null
                : l.holdingAvgPriceInline(krwSigned(avg, false, unit: true)),
            child: PInput(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [AmountInputFormatter(max: kBalanceMax)],
              placeholder: '0',
              suffixText: wonUnit(),
              tabularFigures: true,
              onChanged: (v) {
                _onCostChanged(v);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
