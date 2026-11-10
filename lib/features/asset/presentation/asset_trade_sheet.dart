import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_limit_guard.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_krw.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart'
    show PLeaveConfirmCopy;
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 매수·매도 입력(I-17 56) — 입력 폼 시트. web `AssetTradeDialog` 미러.
///
/// 예수금이 줄고 느는 진짜 사건을 여기서 기록한다. 보유 목록을 손으로 고치는 것과 다르다 —
/// 평가액 갱신을 보고 예수금을 추측하면 시세 변동·추가 매수·재등록이 구분되지 않는다.
///
/// 거래대금은 수수료를 뺀 순수 금액이다. 수수료는 매수면 취득원가에 들어가고
/// 매도면 대금에서 빠진다 — 어느 쪽이든 예수금에서 실제로 나간다.
///
/// 바깥 · 끌기로 안 닫히고, 쓴 값이 있으면 닫기 전에 묻는다. 새 폼이라 첫 칸(수량)에 초점이 간다.
/// 거래일은 지금까지처럼 보내지 않는다(요청 본문은 그대로 — 서버가 사용자 시계의 지금을 쓴다).
Future<void> showAssetTradeSheet(
  BuildContext context, {
  required Asset asset,

  /// 어떤 종목인지 정해진 채로 들어온다 — 여기서 다시 고르게 하면 편집과 역할이 겹친다.
  required AssetHolding holding,
  String defaultType = 'BUY',
}) {
  final l = AppLocalizations.of(context);
  final probe = _TradeProbe();
  final qtyFocus = FocusNode(debugLabel: 'Trade quantity');
  return PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: qtyFocus,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _TradeBody(
      asset: asset,
      holding: holding,
      defaultType: defaultType,
      probe: probe,
      qtyFocus: qtyFocus,
    ),
  );
}

class _TradeProbe {
  bool Function() dirty = () => false;
}

class _TradeBody extends ConsumerStatefulWidget {
  const _TradeBody({
    required this.asset,
    required this.holding,
    required this.defaultType,
    required this.probe,
    required this.qtyFocus,
  });
  final Asset asset;
  final AssetHolding holding;
  final String defaultType;
  final _TradeProbe probe;
  final FocusNode qtyFocus;

  @override
  ConsumerState<_TradeBody> createState() => _TradeBodyState();
}

class _TradeBodyState extends ConsumerState<_TradeBody> {
  final _qtyCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();

  /// 100억을 넘겨 입력을 막았나(거래 금액 · 수수료) — 칸 아래 오류를 띄우고 다음 유효한 입력에서 걷는다.
  late final _amountLimit = AmountLimitGuard(
    _amountCtrl,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  late final _feeLimit = AmountLimitGuard(
    _feeCtrl,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  final _memoCtrl = TextEditingController();

  late String _type;
  bool _submitting = false;
  bool _failed = false;
  String? _failCode;
  final _errorKey = GlobalKey();
  bool _tried = false;

  /// 결제 계좌 — null 이면 증권계좌 예수금에서. 예수금을 따로 관리하지 않으면 통장을 고른다.
  int? _settlementAssetRowId;

  bool get _viaCash => _settlementAssetRowId == null;

  bool get _isSell => _type == 'SELL';

  AssetHolding get _h => widget.holding;

  /// 종목 식별자 — 연동은 토스 종목코드, 미연동은 항목명.
  /// 보유 목록은 편집할 때마다 통째로 재생성돼서 rowId 로는 거래를 묶을 수 없다.
  String get _holdingKey => (_h.linked ? _h.tossSymbol : _h.holdingName) ?? '';

  /// 티커가 아니라 이름으로 보여 준다 — 편집 화면과 같아야 헷갈리지 않는다.
  String get _holdingName =>
      (_h.linked ? (_h.tossSymbol ?? '') : (_h.holdingName ?? ''));

  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 0;
  int get _amount => int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
  int get _fee => int.tryParse(_feeCtrl.text.replaceAll(',', '')) ?? 0;

  double get _heldQty => double.tryParse(_h.quantity?.toString() ?? '') ?? 0;

  /// 실현손익·예수금 잔액은 서버가 계산한다 — 앱이 같은 규칙을 따로 들고 있으면 갈라진다.
  AssetTradePreview? _preview;
  Timer? _previewDebounce;

  /// 돈이 오가는 방향·크기 — 매수는 수수료까지 빠지고 매도는 떼고 들어온다.
  int? get _cashDelta => _preview?.cashDelta;

  /// 거래 후 예수금 (예수금 결제일 때만 의미 있다).
  int? get _cashAfter => _preview?.cashAfter;

  /// 실현손익 미리보기 — 매도일 때만.
  int? get _realizedPreview => _isSell ? _preview?.realizedPl : null;

  /// 예수금이 모자라 결제 계좌에서 끌어올 금액 — 0 이면 이체가 생기지 않는다.
  int get _fundingAmount => _preview?.fundingAmount ?? 0;

  /// 타이핑하는 중에는 묻지 않는다 — 손을 멈추면 그때 한 번 간다.
  void _schedulePreview() {
    _previewDebounce?.cancel();
    if (!(_holdingKey.isNotEmpty && _qty > 0 && _amount > 0)) {
      if (_preview != null) setState(() => _preview = null);
      return;
    }
    _previewDebounce = Timer(const Duration(milliseconds: 350), _fetchPreview);
  }

  Future<void> _fetchPreview() async {
    final asked = (
      _type,
      _holdingKey,
      _qtyCtrl.text.trim(),
      _amount,
      _fee,
      _settlementAssetRowId,
    );
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      final p = await repo.previewTrade(
        assetRowId: widget.asset.rowId,
        tradeType: _type,
        holdingType: _h.holdingType.wire,
        holdingKey: _holdingKey,
        linked: _h.linked,
        quantity: _qtyCtrl.text.trim(),
        amount: _amount,
        fee: _fee,
        // 거래일은 안 보낸다 — 저장과 같은 규칙이라야 미리보기가 맞는다(_submit 참조).
        settlementAssetRowId: _settlementAssetRowId,
      );
      // 물어본 사이에 입력이 또 바뀌었으면 낡은 답이다 — 버린다.
      final now = (
        _type,
        _holdingKey,
        _qtyCtrl.text.trim(),
        _amount,
        _fee,
        _settlementAssetRowId,
      );
      if (!mounted || asked != now) return;
      setState(() => _preview = p);
    } catch (_) {
      // 미리보기가 실패해도 화면을 막지 않는다. 값을 안 보여 줄 뿐이다.
      if (mounted) setState(() => _preview = null);
    }
  }

  bool get _canSubmit =>
      !_submitting &&
      _holdingKey.isNotEmpty &&
      _qty > 0 &&
      _amount > 0 &&
      (!_isSell || _qty <= _heldQty) &&
      // 예수금으로 살 때만 잔액을 본다 — 결제 계좌는 마이너스를 막지 않는다(서버도 같은 규칙).
      // 예수금이 모자라도 막지 않는다 — 기록용 앱이라 마이너스로 쌓이는 게 정상이다.
      true;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType == 'SELL' ? 'SELL' : 'BUY';
    for (final c in [_qtyCtrl, _amountCtrl, _feeCtrl]) {
      c.addListener(_sync);
    }
    widget.probe.dirty = () =>
        _qtyCtrl.text.isNotEmpty ||
        _amountCtrl.text.isNotEmpty ||
        _feeCtrl.text.isNotEmpty ||
        _memoCtrl.text.isNotEmpty;
  }

  void _sync() {
    if (!mounted) return;
    setState(() {});
    _schedulePreview();
  }

  @override
  void dispose() {
    _amountLimit.dispose();
    _feeLimit.dispose();
    _previewDebounce?.cancel();
    for (final c in [_qtyCtrl, _amountCtrl, _feeCtrl, _memoCtrl]) {
      c.dispose();
    }
    widget.qtyFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    // 주 버튼을 막지 않고 누르면 칸 아래 오류(DESIGN.desk:4081)
    _amountLimit.dismiss();
    _feeLimit.dismiss();
    setState(() => _tried = true);
    if (!_canSubmit) {
      (_qty <= 0 || (_isSell && _qty > _heldQty) ? widget.qtyFocus : null)
          ?.requestFocus();
      return;
    }
    setState(() {
      _failed = false;
      _failCode = null;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(assetRepositoryProvider.future);
      await repo.createTrade(
        assetRowId: widget.asset.rowId,
        tradeType: _type,
        holdingType: _h.holdingType.wire,
        holdingKey: _holdingKey,
        linked: _h.linked,
        quantity: _qtyCtrl.text.trim(),
        amount: _amount,
        fee: _fee,
        // 거래일은 **안 보낸다.** 이 시트엔 날짜 칸이 없어 보낼 수 있는 값이
        // 기기 시계의 지금뿐인데, 그 문자열엔 시간대가 없어 사용자 시계와 갈라진다
        // (해외에서 켜면 하루 어긋난 날짜로 예수금·실현손익이 계산된다).
        // 서버는 `tradeDate` 를 필수로 받지 않고, 없으면 사용자 시계의 지금을 쓴다
        // (`AssetTradeServiceImpl` 의 `userClock.now`) — 그쪽이 정확하다.
        // 며칠 전 매매를 그날로 적는 건 날짜 칸이 생겨야 되는 별건이다.
        description: _memoCtrl.text.trim().isEmpty
            ? null
            : _memoCtrl.text.trim(),
        settlementAssetRowId: _settlementAssetRowId,
        silent: true,
      );
      // 예수금·보유·실현손익이 한꺼번에 바뀐다 — 자산과 거래 목록을 모두 새로 받는다.
      // 순자산·추이도 같은 매매로 움직이므로 자산 변경 묶음을 통째로 비운다.
      invalidateAfterAssetChangeIn(container);
      container.invalidate(assetTradesProvider(widget.asset.rowId));
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 폼은 열린 채 쓴 값이 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
      if (isUnconfirmedSave(e)) {
        invalidateAfterAssetChangeIn(container);
        container.invalidate(assetTradesProvider(widget.asset.rowId));
      }
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

  Future<void> _pickSettlement(List<Asset> options) async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<int>(
      context,
      builder: (sheetContext) => PBottomSheetContent(
        title: l.tradeSettlement,
        closeLabel: l.actionClose,
        flushBody: true,
        scrollFog: true,
        body: PickList<int>(
          label: l.tradeSettlement,
          selected: _settlementAssetRowId ?? -1,
          items: [
            PickItem<int>(value: -1, title: l.tradeSettlementCash),
            for (final a in options)
              PickItem<int>(value: a.rowId, title: _accountLabel(a)),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _settlementAssetRowId = picked == -1 ? null : picked);
    _sync();
  }

  String _accountLabel(Asset a) =>
      a.institution != null && a.institution!.isNotEmpty
      ? '${a.institution} · ${a.assetName}'
      : a.assetName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final realized = _realizedPreview;
    // 결제 계좌 후보 — 이 증권계좌 자신과 카드는 뺀다.
    final settlementOptions =
        (ref.watch(assetsProvider).value ?? const <Asset>[])
            .where(
              (a) =>
                  a.rowId != widget.asset.rowId &&
                  a.assetType != 'CREDIT_CARD' &&
                  a.assetType != 'CHECK_CARD',
            )
            .toList(growable: false);
    final selected = settlementOptions
        .where((a) => a.rowId == _settlementAssetRowId)
        .firstOrNull;
    final qtyError = _tried && _qty <= 0
        ? l.tradeQtyRequired
        : _isSell && _qty > _heldQty
        ? l.tradeInsufficientQty
        : null;
    final amountError = _tried && _amount <= 0 ? l.tradeAmountRequired : null;
    final critical = _viaCash && (_cashAfter ?? 0) < 0;
    // 금액의 통화(I-13 L6) — 거래 후 예수금은 투자 계좌 통화(cashCurrency), 결제 계좌에서 옮기는 금액은 그 계좌 통화(fundingCurrency).
    // 옛 서버(칸 없음)면 계좌 통화로 읽는다. 원화가 아니면 "약 …원" 을 함께 쓴다(그 계좌 환율, HALF_UP). 웹 AssetTradeDialog 와 같다.
    final locale = Localizations.localeOf(context).toString();
    final cashCurrency = _preview?.cashCurrency ?? widget.asset.currency;
    final fundingCurrency =
        _preview?.fundingCurrency ?? selected?.currency ?? kDefaultCurrency;
    ({String main, String? approx}) moneyParts(
      int n,
      String? code,
      double? rate,
    ) {
      if (!isForeignCurrency(code)) {
        return (main: krwSigned(n, false, unit: true), approx: null);
      }
      final won = toKrw(n.abs(), code, rate);
      return (
        main: formatAssetAmount(n, code!, locale),
        approx: l.fxApproxKrw(krwSigned(n < 0 ? -won : won, false, unit: true)),
      );
    }

    final cashParts = moneyParts(
      _cashAfter ?? 0,
      cashCurrency,
      widget.asset.exchangeRate,
    );
    // 결제 계좌에서 나가는 금액 = 충당액(결제 계좌 통화, I-13 L6). 예수금이 넉넉하면 0
    final fundingRate = selected?.exchangeRate;
    final settlementParts = moneyParts(
      -_fundingAmount,
      fundingCurrency,
      fundingRate,
    );
    final fundingParts = moneyParts(
      _fundingAmount,
      fundingCurrency,
      fundingRate,
    );
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    TextStyle value(Color color) => PTypography.t5.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return PBottomSheetContent(
      title: l.tradeTitle,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed)
            Padding(
              padding: gutter,
              child: FormErrorCallout(
                key: _errorKey,
                // 서버 글은 내지 않고 오류 코드로만 가른다(ASSET_012 = 보유 수량 부족).
                message: _failCode == 'ASSET_012'
                    ? l.tradeSaveInsufficientQty
                    : _failCode == kApiParseErrorCode ||
                          _failCode == kApiNoResponseCode
                    ? l.saveUnconfirmed
                    : l.tradeSaveFailed,
              ),
            ),
          // 매수 · 매도 — 2 ~ 4개 폼 값은 칩 하나 고르기
          Padding(
            padding: gutter,
            child: PChipRadioGroup<String>(
              semanticLabel: l.tradeTitle,
              value: _type,
              onChanged: (v) {
                setState(() => _type = v);
                _sync();
              },
              children: [
                PChipRadio<String>(
                  value: 'BUY',
                  label: l.tradeBuy,
                  variant: PChipVariant.outlineStrong,
                  size: PChipSize.medium,
                ),
                PChipRadio<String>(
                  value: 'SELL',
                  label: l.tradeSell,
                  variant: PChipVariant.outlineStrong,
                  size: PChipSize.medium,
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpacing.x4),

          // 어떤 종목인지 — 여기서 고르는 게 아니라 이미 정해져서 들어온다. 종목 추가는 편집(토스 검색)에서 한다.
          PList(
            semanticLabel: l.tradeHolding,
            children: [
              PListItem(
                title: _holdingName,
                detail: l.tradeHeldSummary(
                  _h.quantity?.toString() ?? '0',
                  _h.avgPrice != null
                      ? krwSigned(
                          double.tryParse(_h.avgPrice!)?.round() ?? 0,
                          false,
                        )
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpacing.x4),

          Padding(
            padding: gutter,
            child: PField(
              label: l.tradeQuantity,
              invalid: qtyError != null,
              errorMessage: qtyError,
              child: PInput(
                variant: PInputVariant.underline,
                controller: _qtyCtrl,
                focusNode: widget.qtyFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                tabularFigures: true,
                placeholder: '0',
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x4),

          Padding(
            padding: gutter,
            child: PField(
              label: l.tradeAmount,
              description: l.tradeAmountHelp,
              invalid: amountError != null || _amountLimit.over,
              errorMessage: _amountLimit.over ? l.amountTooLarge : amountError,
              child: PInput(
                variant: PInputVariant.underline,
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: _amountLimit.formatters,
                suffixText: wonUnit(),
                tabularFigures: true,
                placeholder: '0',
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x4),

          Padding(
            padding: gutter,
            child: PField(
              label: l.tradeFee,
              indicator: PFieldIndicator.optional,
              invalid: _feeLimit.over,
              errorMessage: _feeLimit.over ? l.amountTooLarge : null,
              child: PInput(
                variant: PInputVariant.underline,
                controller: _feeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: _feeLimit.formatters,
                suffixText: wonUnit(),
                tabularFigures: true,
                placeholder: '0',
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x4),

          // 결제 계좌는 매수에만. 매도 대금은 예수금에 남기고 사용자가 이체로 관리한다 —
          // 팔았다고 통장으로 자동 이체되지는 않는다.
          if (!_isSell) ...[
            PickerRow(
              title: l.tradeSettlement,
              value: selected == null
                  ? l.tradeSettlementCash
                  : _accountLabel(selected),
              semanticValue: selected == null
                  ? l.tradeSettlementCash
                  : _accountLabel(selected),
              onTap: () => _pickSettlement(settlementOptions),
            ),
            Padding(
              padding: gutter.copyWith(top: PSpacing.x1_5),
              child: PText(
                _viaCash
                    ? l.tradeSettlementCashHelp
                    : l.tradeSettlementAccountHelp,
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
            const SizedBox(height: PSpacing.x4),
          ],

          Padding(
            padding: gutter,
            child: PField(
              label: l.tradeMemo,
              indicator: PFieldIndicator.optional,
              child: PInput(
                variant: PInputVariant.underline,
                controller: _memoCtrl,
                placeholder: l.tradeMemoPlaceholder,
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x4),

          // 저장하고 놀라지 않게 예수금과 손익을 먼저 보여 준다 — 키-값 줄.
          PList(
            semanticLabel: l.tradePreview,
            children: [
              PListItem(
                title: _viaCash ? l.tradeCashAfter : l.tradeSettlementDelta,
                // 서버가 아직 답하기 전에는 자리만 잡아 둔다 — 틀린 값을 잠깐 보여 주느니 낫다.
                suffix: (_cashAfter == null || _cashDelta == null)
                    ? Text(
                        '—',
                        textAlign: TextAlign.end,
                        style: value(c.fgNeutral),
                      )
                    : _moneyValue(
                        _viaCash ? cashParts : settlementParts,
                        value(critical ? c.fgCritical : c.fgNeutral),
                        PTypography.t3.copyWith(
                          color: c.fgNeutralSubtle,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
              if (realized != null)
                PListItem(
                  title: l.tradeRealizedPreview,
                  suffix: Text(
                    krwSigned(
                      realized.abs(),
                      false,
                      sign: realized >= 0 ? '+' : kMinus,
                      unit: true,
                    ),
                    textAlign: TextAlign.end,
                    style: value(c.fgNeutral),
                  ),
                ),
            ],
          ),
          // 예수금이 모자라면 결제 계좌에서 그만큼 끌어온다 — 이체가 한 건 생긴다는 걸 미리 알린다.
          if (_fundingAmount > 0)
            Padding(
              padding: gutter.copyWith(top: PSpacing.x2),
              child: PText(
                // 문장 안 — "$900(약 1,170,000원)"
                l.tradeFundingNotice(
                  fundingParts.approx == null
                      ? fundingParts.main
                      : '${fundingParts.main}(${fundingParts.approx})',
                ),
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
          if (!_isSell && critical)
            Padding(
              padding: gutter.copyWith(top: PSpacing.x2),
              child: PText(
                l.tradeInsufficientCash,
                style: PTypography.t3.copyWith(color: c.fgCritical),
              ),
            ),
          const SizedBox(height: PSpacing.x2),
        ],
      ),
      footer: [
        PButton(
          label: l.actionSave,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// 미리보기 줄 값 — 외화면 아래 작게 "약 …원"(상세 예수금 줄과 같은 모양, I-13).
Widget _moneyValue(
  ({String main, String? approx}) parts,
  TextStyle mainStyle,
  TextStyle approxStyle,
) {
  final main = Text(parts.main, textAlign: TextAlign.end, style: mainStyle);
  if (parts.approx == null) return main;
  return PListValue(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        Text(parts.approx!, textAlign: TextAlign.end, style: approxStyle),
      ],
    ),
  );
}
