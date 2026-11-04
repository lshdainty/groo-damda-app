import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_shares.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_form_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/select_box/p_select_box.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/step_done.dart';
import 'package:groo_damda_app/shared/forms/step_probe.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';

/// 참여자 이름 길이 상한 — 웹 `PARTICIPANT_NAME_MAX` 와 같은 값.
const int kDutchParticipantNameMax = 20;

class _Person {
  _Person({required this.id, required this.name});
  final String id;
  final String name;
  String ratio = '1';
  String custom = '';
  late final ratioCtrl = TextEditingController(text: '1');
  late final customCtrl = TextEditingController();
  void dispose() {
    ratioCtrl.dispose();
    customCtrl.dispose();
  }
}

/// 더치페이로 나누기 단계(I-21 G 39 ~ 42) — 같은 시트 안 한 단계. 원 거래 줄 → "나도 포함해서 나누기" → 참여자 칸 → "나누는 법" Select Box
/// 셋 → "몫" 묶음 → 메모 줄 › → 바닥 위 "1인당" → [정산 만들기]. 저장은 켜 두고 누를 때 알린다.
/// 결제자는 늘 나다 — 나 포함을 끄면 나는 목록에 없지만 결제자로 저장되고 남는 원이 내 몫이다.
class DutchStepFlow extends ConsumerStatefulWidget {
  const DutchStepFlow({
    super.key,
    required this.expense,
    required this.probe,
    required this.onBack,
    this.onFinished,
  });

  final Expense expense;
  final StepProbe probe;
  final VoidCallback onBack;
  final VoidCallback? onFinished;

  @override
  ConsumerState<DutchStepFlow> createState() => _DutchStepFlowState();
}

class _DutchStepFlowState extends ConsumerState<DutchStepFlow> {
  DutchSplitMethod _method = DutchSplitMethod.equal;
  bool _includeMe = true;
  final List<_Person> _others = [];
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _noteCtrl = TextEditingController();
  final _noteFocus = FocusNode();
  String _note = '';
  bool _noteStep = false;
  String _noteSnap = '';
  String? _nameErr;
  bool _attempted = false;
  bool _submitting = false;
  bool _leaving = false;
  bool _saveError = false;
  final _saveErrorKey = GlobalKey();
  int _seq = 0;
  late final _Person _me = _Person(id: 'me', name: '');

  Expense get _e => widget.expense;
  int get _total => _e.amount.abs();

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () => mounted && (_submitting || _dirty);
    widget.probe.interceptClose = _intercept;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    widget.probe.interceptClose = () => false;
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _noteCtrl.dispose();
    _noteFocus.dispose();
    _me.dispose();
    for (final p in _others) {
      p.dispose();
    }
    super.dispose();
  }

  bool get _dirty =>
      _method != DutchSplitMethod.equal ||
      !_includeMe ||
      _others.isNotEmpty ||
      _note.isNotEmpty ||
      _nameCtrl.text.isNotEmpty;

  String get _title {
    final m = (_e.merchant ?? '').trim();
    if (m.isNotEmpty) return m;
    final d = (_e.description ?? '').trim();
    return d.isNotEmpty ? d : AppLocalizations.of(context).dutchTitle;
  }

  String get _day {
    final raw = (_e.expenseDate ?? '').trim();
    return raw.length >= 10
        ? raw.substring(0, 10)
        : DateTime.now().toIso8601String().substring(0, 10);
  }

  // ── 몫 ────────────────────────────────────────────────────
  List<_Person> get _list => [if (_includeMe) _me, ..._others];

  DutchShares _shares(List<_Person> list) => computeDutchShares(
    total: _total,
    method: _method,
    count: list.length,
    payerIndex: _includeMe ? 0 : -1,
    ratios: [for (final p in list) p.ratio],
    customs: [for (final p in list) int.tryParse(p.custom) ?? 0],
  );

  // ── 단계 ────────────────────────────────────────────────
  bool _intercept() {
    if (!mounted) return false;
    if (_submitting) return true;
    if (_noteStep) {
      _leaveNote();
    } else {
      _leave();
    }
    return true;
  }

  Future<bool> _confirmLeave() async {
    if (_leaving) return false;
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
    return leave && mounted;
  }

  Future<void> _leave() async {
    if (_submitting || _leaving) return;
    if (_dirty && !await _confirmLeave()) return;
    widget.onBack();
  }

  void _openNote() {
    FocusScope.of(context).unfocus();
    _noteSnap = _note;
    _noteCtrl.text = _note;
    setState(() => _noteStep = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _noteStep) _noteFocus.requestFocus();
    });
  }

  void _doneNote() {
    FocusScope.of(context).unfocus();
    setState(() {
      _note = _noteCtrl.text.trim();
      _noteStep = false;
    });
  }

  Future<void> _leaveNote() async {
    if (_leaving) return;
    if (_noteCtrl.text.trim() != _noteSnap && !await _confirmLeave()) return;
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _noteStep = false);
  }

  // ── 참여자 ────────────────────────────────────────────────
  void _addPerson() {
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameErr = l.dutchNameEmptyErr);
      return;
    }
    final me = ref.read(authProvider).value?.userName ?? l.dutchMe;
    // 같은 이름 둘 · 내 이름과 같은 참여자는 막는다(서버는 이름을 소문자로 견준다)
    final lower = name.toLowerCase();
    if (lower == me.trim().toLowerCase() ||
        _others.any((p) => p.name.toLowerCase() == lower)) {
      setState(() => _nameErr = l.dutchNameAlreadyAdded);
      return;
    }
    setState(() {
      _others.add(_Person(id: 'p${_seq++}', name: name));
      _nameCtrl.clear();
      _nameErr = null;
    });
    _nameFocus.requestFocus();
  }

  void _removePerson(_Person p) {
    setState(() {
      _others.remove(p);
    });
    p.dispose();
  }

  // ── 저장 ────────────────────────────────────────────────
  /// 몫 칸이 못 쓰는 값인가 — 비율은 0 보다 큰 수, 개별 금액은 다른 사람 칸이 0 보다 커야 한다.
  bool _rowBad(_Person p) {
    switch (_method) {
      case DutchSplitMethod.equal:
        return false;
      case DutchSplitMethod.ratio:
        final d = double.tryParse(p.ratio.trim());
        return d == null || d <= 0;
      case DutchSplitMethod.custom:
        return p != _me && (int.tryParse(p.custom) ?? 0) <= 0;
    }
  }

  String? _sumError(AppLocalizations l, bool masked) {
    if (_list.any(_rowBad)) {
      return _method == DutchSplitMethod.ratio
          ? l.dutchErrRatio
          : l.dutchErrCustomEmpty;
    }
    if (_method != DutchSplitMethod.custom) return null;
    final diff = _total - _shares(_list).sum;
    if (diff == 0) return null;
    return diff > 0
        ? l.dutchSharesShortErr(txMoney(diff, masked))
        : l.dutchSharesOverErr(txMoney(-diff, masked));
  }

  void _showSaveError() {
    setState(() => _saveError = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _saveErrorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      revealBelowFog(ctx);
    });
  }

  Future<void> _submit(String meName, int? meRowId, bool masked) async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _attempted = true;
      _saveError = false;
    });
    try {
      final list = _list;
      if (list.isEmpty) return;
      if (_sumError(l, masked) != null) return;
      final shares = _shares(list);
      final repo = await ref.read(dutchPayRepositoryProvider.future);
      await repo.create(
        title: _title,
        description: _note.isEmpty ? null : _note,
        totalAmount: _total,
        splitMethod: switch (_method) {
          DutchSplitMethod.equal => 'EQUAL',
          DutchSplitMethod.ratio => 'RATIO',
          DutchSplitMethod.custom => 'CUSTOM',
        },
        dutchPayDate: _day,
        sourceExpenseRowId: _e.rowId,
        silent: true,
        participants: [
          // "나도 포함" 을 끄면 나는 목록에 없지만 결제자다 — 남는 원이 내 몫이다(서버는 결제자의 0 · 양수를 모두 받는다)
          if (!_includeMe)
            (
              name: meName.trim(),
              userRowId: meRowId,
              amount: shares.payerOut,
              isPayer: true,
            ),
          for (var i = 0; i < list.length; i++)
            (
              name: (list[i] == _me ? meName : list[i].name).trim(),
              userRowId: list[i] == _me ? meRowId : null,
              amount: shares.shares[i],
              isPayer: list[i] == _me,
            ),
        ],
      );
      ref.invalidate(dutchPayListProvider);
      try {
        await ref.read(dutchPayListProvider.future);
      } catch (_) {}
      if (!mounted) return;
      widget.onFinished?.call();
    } on ApiException {
      if (mounted) _showSaveError();
    } catch (_) {
      if (mounted) _showSaveError();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── 그리기 ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_noteStep) return _buildNote(l);
    final c = context.colors;
    final me = ref.watch(authProvider).value;
    final meName = me?.userName ?? l.dutchMe;
    final meRowId = me?.rowId;
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .ofType(_e.expenseType);
    final list = _list;
    final shares = _shares(list);
    final cats = ref.watch(categoriesProvider).value;
    final cat = _e.categoryRowId == null
        ? null
        : cats?.where((x) => x.rowId == _e.categoryRowId).firstOrNull;
    final fg = resolveChartColor(
      context,
      cat?.color ?? _e.categoryColor,
      fallback: c.fgBrand,
    );
    final sumErr = _attempted && !_submitting ? _sumError(l, masked) : null;
    final noOthers = _attempted && !_submitting && list.isEmpty;
    final perPerson = list.isEmpty ? 0 : _total ~/ list.length;

    String? perLine;
    if (_method == DutchSplitMethod.equal && list.isNotEmpty) {
      perLine = _includeMe || shares.payerOut == 0
          ? txMoney(perPerson, masked)
          : l.dutchPerPersonMe(
              txMoney(perPerson, masked),
              txMoney(shares.payerOut, masked),
            );
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_saveError)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
            ),
            child: Container(
              key: _saveErrorKey,
              child: FormErrorCallout(message: l.dutchSaveFailed),
            ),
          ),
        PList(
          semanticLabel: l.dutchStartTitle,
          children: [
            PListItem(
              key: const ValueKey('dutch-source'),
              title: _title,
              detail: txDetailDateTimeLabel(_e.expenseDate),
              prefix: PListTile(
                background: softBg(context, fg),
                color: fg,
                child: Icon(
                  lucideByName(
                    cat?.icon ?? _e.categoryIcon,
                    fallback: LucideIcons.tag,
                  ),
                ),
              ),
              suffix: PListValue.amount(
                txMoney(_total, masked),
                style: TextStyle(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            PListCheckItem(
              key: const ValueKey('dutch-include-me'),
              title: l.dutchMeIncludeTitle,
              detail: _includeMe
                  ? l.dutchMeIncludeOn
                  : l.dutchIncludeMyselfOffDesc,
              checked: _includeMe,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _includeMe = v),
            ),
          ],
        ),
        _participantsField(l, meName, noOthers),
        PListHeader(
          title: l.dutchMethodHeader,
          headingLevel: 3,
          topInset: PSpacing.x1,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
          ),
          child: PRadioSelectBoxGroup<DutchSplitMethod>(
            key: const ValueKey('dutch-method'),
            value: _method,
            columns: 3,
            semanticLabel: l.dutchMethodHeader,
            onChanged: _submitting ? null : (v) => setState(() => _method = v),
            children: [
              PRadioSelectBox<DutchSplitMethod>(
                value: DutchSplitMethod.equal,
                label: l.dutchSplitEqualTitle,
                description: l.dutchEqualSub,
              ),
              PRadioSelectBox<DutchSplitMethod>(
                value: DutchSplitMethod.ratio,
                label: l.dutchSplitRatioTitle,
                description: l.dutchRatioSub,
              ),
              PRadioSelectBox<DutchSplitMethod>(
                value: DutchSplitMethod.custom,
                label: l.dutchSplitCustomTitle,
                description: l.dutchSplitCustomSub,
              ),
            ],
          ),
        ),
        PListHeader(
          title: l.dutchSharesHeader,
          variant: PListHeaderVariant.boldSolid,
          headingLevel: 3,
          topInset: PSpacing.x4,
          trailing: Text(
            l.dutchSharesTotal(txMoney(_total, masked)),
            style: PTypography.t4.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        PList(
          semanticLabel: l.dutchSharesHeader,
          children: [
            for (var i = 0; i < list.length; i++)
              _shareRow(l, list[i], i, shares, meName, masked),
            PListButtonItem(
              key: const ValueKey('dutch-note'),
              title: l.dutchNoteTitle,
              prefix: Icon(
                LucideIcons.messageSquare,
                size: 22,
                color: c.fgNeutral,
              ),
              onTap: _submitting ? null : _openNote,
              suffix: PListSuffix(
                children: [
                  Flexible(
                    child: Text(
                      _note.isEmpty ? l.txfNone : _note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypography.t4.copyWith(
                        color: _note.isEmpty
                            ? c.fgPlaceholder
                            : c.fgNeutralSubtle,
                      ),
                    ),
                  ),
                  const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    return PBottomSheetContent(
      key: const ValueKey('dutch-step'),
      title: l.dutchStartTitle,
      closeLabel: l.actionClose,
      onClose: () => PBottomSheet.of(context).requestClose(wholeSheet: true),
      onBack: _leave,
      backLabel: l.actionBack,
      flushBody: true,
      scrollFog: true,
      body: body,
      footerRow: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sumErr != null)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpacing.x2),
              child: Text(
                sumErr,
                key: const ValueKey('dutch-sum-error'),
                style: PTypography.t3.copyWith(color: c.fgCritical),
              ),
            )
          else if (perLine != null)
            Padding(
              key: const ValueKey('dutch-per-person'),
              padding: const EdgeInsets.only(bottom: PSpacing.x2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.dutchPerPersonLabel,
                      style: PTypography.t4.copyWith(color: c.fgNeutralMuted),
                    ),
                  ),
                  Text(
                    perLine.replaceAll(',', '⁠,​'),
                    semanticsLabel: perLine,
                    style: PTypography.t4.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          PButton(
            label: l.dutchCreate,
            size: PButtonSize.large,
            loading: _submitting,
            onPressed: _submitting
                ? null
                : () => _submit(meName, meRowId, masked),
          ),
        ],
      ),
    );
  }

  Widget _participantsField(AppLocalizations l, String meName, bool noOthers) {
    final count = _list.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x3,
        PSpacing.globalGutter,
        PSpacing.x4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PField(
            label: l.dutchParticipantsLabel(count),
            invalid: noOthers,
            errorMessage: noOthers ? l.dutchErrNoOthers : null,
            child: count == 0
                ? const SizedBox.shrink()
                : PChipGroup(
                    semanticLabel: l.dutchParticipantsLabel(count),
                    children: [
                      if (_includeMe)
                        PChip(
                          key: const ValueKey('dutch-chip-me'),
                          label: meName,
                          leading: PAvatar(name: meName, size: PAvatarSize.s24),
                          onPressed: null,
                        ),
                      for (final p in _others)
                        PInputChip(
                          key: ValueKey('dutch-chip-${p.id}'),
                          label: p.name,
                          leading: PAvatar(name: p.name, size: PAvatarSize.s24),
                          removeLabel: l.dutchChipRemove(p.name),
                          onRemove: _submitting ? null : () => _removePerson(p),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: PSpacing.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x2,
            children: [
              Expanded(
                child: PField(
                  invalid: _nameErr != null,
                  errorMessage: _nameErr,
                  child: PInput(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    semanticLabel: l.dutchParticipant,
                    placeholder: l.dutchAddNamePlaceholder,
                    invalid: _nameErr != null,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        kDutchParticipantNameMax,
                      ),
                    ],
                    onChanged: (_) {
                      if (_nameErr != null) setState(() => _nameErr = null);
                    },
                    onSubmitted: (_) => _addPerson(),
                  ),
                ),
              ),
              PButton(
                label: l.dutchAdd,
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.large,
                onPressed: _submitting ? null : _addPerson,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareRow(
    AppLocalizations l,
    _Person p,
    int i,
    DutchShares shares,
    String meName,
    bool masked,
  ) {
    final c = context.colors;
    final isMe = p == _me;
    final name = isMe ? meName : p.name;
    final amount = shares.shares[i];
    final rest = _method == DutchSplitMethod.equal && isMe
        ? _total - (_total ~/ _list.length) * _list.length
        : 0;
    final amountText = Text(
      txMoney(amount, masked).replaceAll(',', '⁠,​'),
      semanticsLabel: txMoney(amount, masked),
      textAlign: TextAlign.end,
      style: TextStyle(
        color: c.fgNeutral,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    Widget? suffix;
    String? detail;
    switch (_method) {
      case DutchSplitMethod.equal:
        suffix = amountText;
        if (rest > 0) detail = l.dutchRemainIncluded(txMoney(rest, masked));
      case DutchSplitMethod.ratio:
        detail = txMoney(amount, masked);
        suffix = SizedBox(
          width: 96,
          child: PInput(
            controller: p.ratioCtrl,
            semanticLabel: '$name ${l.dutchShareUnit}',
            suffixText: l.dutchShareUnit,
            textAlign: TextAlign.end,
            invalid: _attempted && _rowBad(p),
            tabularFigures: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (v) => setState(() => p.ratio = v),
          ),
        );
      case DutchSplitMethod.custom:
        suffix = isMe
            ? amountText
            : SizedBox(
                width: 96,
                child: PInput(
                  controller: p.customCtrl,
                  semanticLabel: name,
                  placeholder: '0',
                  suffixText: wonUnit(),
                  textAlign: TextAlign.end,
                  invalid: _attempted && _rowBad(p),
                  tabularFigures: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: kWonFormatters,
                  onChanged: (v) =>
                      setState(() => p.custom = '${parseAmountInput(v) ?? 0}'),
                ),
              );
    }
    return PListItem(
      key: ValueKey('dutch-share-${p.id}'),
      title: name,
      titleSuffix: isMe
          ? [
              PBadge(
                label: l.dutchPayerShort,
                size: PBadgeSize.large,
                tone: PBadgeTone.neutral,
              ),
            ]
          : null,
      detail: detail,
      prefix: PAvatar(name: name, size: PAvatarSize.s42),
      suffix: suffix,
    );
  }

  Widget _buildNote(AppLocalizations l) {
    return PBottomSheetContent(
      key: const ValueKey('dutch-note-step'),
      title: l.dutchNoteTitle,
      closeLabel: l.actionClose,
      showCloseButton: false,
      onBack: _leaveNote,
      backLabel: l.actionBack,
      headerAction: StepDoneButton(label: l.actionDone, onPressed: _doneNote),
      flushBody: true,
      scrollFog: true,
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
            controller: _noteCtrl,
            focusNode: _noteFocus,
            semanticLabel: l.dutchNoteTitle,
            placeholder: l.dutchNotePh,
            maxHeight: 200,
          ),
        ),
      ),
    );
  }
}
