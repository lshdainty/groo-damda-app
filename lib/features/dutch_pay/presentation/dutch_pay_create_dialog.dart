import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay_model.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_shares.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 참여자 이름 길이 상한 — 웹 `PARTICIPANT_NAME_MAX` 와 같은 값.
const int kDutchPersonNameMax = 20;

/// 정산 만들기(I-15 35 ~ 37 · 7-1A) — ds Bottom Sheet 입력 폼 두 단계. 머리 = 제목 "정산 정보" · "참여자" + 그 아래 "{n} / 2단계"(ds 머리에 제목 위 자리가
/// 없어 설명 줄로 둔다). 1단계 = 정산 이름 · 총 금액 · 날짜 · 장소(선택) 한 줄에 하나, 바닥 [다음] 폭 전체. 2단계 = "{n}명 · 1인당 …" · 참여자 칩(나는 × 없음) ·
/// 이름 + [추가] · 함께 정산했던 사람 제안 칩 · 결제한 사람 · 바닥 [이전] [정산 만들기] 반씩.
/// 바깥 · 끌어내림으로 안 닫히고 값이 바뀐 채 닫으면 "작성한 내용이 사라져요"(2단계에서도 1단계 값까지 묻는다). 저장 실패는 맨 위 Callout.
/// 나머지 원은 결제자에게(`computeDutchShares`).
Future<void> showDutchPayCreateDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  return PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _CreateSheet(probe: probe),
  );
}

class _DirtyProbe {
  bool Function() dirty = () => false;
}

/// 참여자 한 명 — 나(`isMe`)는 × 가 없고 늘 참여한다.
class _Person {
  const _Person(this.name, {this.isMe = false});
  final String name;
  final bool isMe;
}

class _CreateSheet extends ConsumerStatefulWidget {
  const _CreateSheet({required this.probe});
  final _DirtyProbe probe;

  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _errorKey = GlobalKey();
  late final DateTime _today;
  late DateTime _date;
  int _step = 1;
  bool _attempted1 = false;
  bool _attempted2 = false;
  bool _submitting = false;
  bool _saveError = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  String? _nameErr;

  /// 참여자(나 제외) — 나는 늘 있다.
  final List<String> _others = [];

  /// 결제한 사람 — null 이면 나.
  String? _payer;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _today = DateTime(n.year, n.month, n.day);
    _date = _today;
    widget.probe.dirty = () =>
        mounted &&
        (_titleCtrl.text.isNotEmpty ||
            _amountCtrl.text.isNotEmpty ||
            _placeCtrl.text.isNotEmpty ||
            _date != _today ||
            _others.isNotEmpty ||
            _nameCtrl.text.isNotEmpty);
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    for (final c in [_titleCtrl, _amountCtrl, _placeCtrl, _nameCtrl]) {
      c.dispose();
    }
    for (final f in [_titleFocus, _amountFocus, _nameFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  int get _total => parseAmountInput(_amountCtrl.text) ?? 0;
  String get _dateIso =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  String _meName() =>
      ref.read(authProvider).value?.userName ??
      AppLocalizations.of(context).dutchMe;

  /// 목록 차례 — 나 → 더한 사람. 결제자는 그중 한 명.
  List<_Person> _list() => [
    _Person(_meName(), isMe: true),
    for (final n in _others) _Person(n),
  ];

  int get _payerIndex {
    final i = _payer == null ? 0 : _others.indexOf(_payer!) + 1;
    return i < 0 ? 0 : i;
  }

  void _next() {
    setState(() => _attempted1 = true);
    if (_titleCtrl.text.trim().isEmpty) {
      _titleFocus.requestFocus();
      return;
    }
    if (_total <= 0) {
      _amountFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = 2);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<DateTime>(
      context,
      builder: (sheetContext) {
        DateTime draft = _date;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final l = AppLocalizations.of(ctx);
            return PBottomSheetContent(
              title: l.dutchDateLabel,
              closeLabel: l.actionClose,
              flushBody: true,
              body: PDatePicker.single(
                labels: PDatePickerLabels.of(ctx),
                semanticLabel: l.dutchDateLabel,
                value: draft,
                onChanged: (v) => setSheet(() => draft = v),
              ),
              footer: [
                PButton(
                  label: l.actionDone,
                  size: PButtonSize.large,
                  onPressed: () => PBottomSheet.of(ctx).close(draft),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  void _add(String raw) {
    final l = AppLocalizations.of(context);
    final name = raw.trim();
    if (name.isEmpty) {
      setState(() => _nameErr = l.dutchNameEmptyErr);
      return;
    }
    // 같은 이름 둘 · 내 이름과 같은 참여자는 막는다(서버는 이름을 소문자로 견준다)
    final lower = name.toLowerCase();
    if (lower == _meName().trim().toLowerCase() ||
        _others.any((p) => p.toLowerCase() == lower)) {
      setState(() => _nameErr = l.dutchNameAlreadyAdded);
      return;
    }
    setState(() {
      _others.add(name);
      _nameCtrl.clear();
      _nameErr = null;
    });
  }

  void _remove(String name) {
    setState(() {
      _others.remove(name);
      // 결제자였던 사람이 빠지면 나로 되돌린다
      if (_payer == name) _payer = null;
    });
  }

  Future<void> _pickPayer() async {
    FocusScope.of(context).unfocus();
    final people = _list();
    final picked = await PBottomSheet.show<int>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        return PBottomSheetContent(
          title: l.dutchPayerSelect,
          closeLabel: l.actionClose,
          flushBody: true,
          scrollFog: true,
          body: PickList<int>(
            label: l.dutchPayerSelect,
            selected: _payerIndex,
            items: [
              for (var i = 0; i < people.length; i++)
                PickItem(
                  value: i,
                  title: people[i].name,
                  prefix: PAvatar(name: people[i].name, size: PAvatarSize.s36),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _payer = picked == 0 ? null : people[picked].name);
  }

  Future<void> _submit() async {
    // 이중 제출은 await 앞에서 막는다
    if (_submitting) return;
    setState(() => _attempted2 = true);
    if (_others.isEmpty) {
      _nameFocus.requestFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _saveError = false;
    });
    final c = ProviderScope.containerOf(context, listen: false);
    final me = ref.read(authProvider).value;
    final people = _list();
    final shares = computeDutchShares(
      total: _total,
      method: DutchSplitMethod.equal,
      count: people.length,
      payerIndex: _payerIndex,
    );
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await c.read(dutchPayRepositoryProvider.future);
      await repo.create(
        title: _titleCtrl.text.trim(),
        description: _placeCtrl.text.trim().isEmpty
            ? null
            : _placeCtrl.text.trim(),
        totalAmount: _total,
        splitMethod: 'EQUAL',
        dutchPayDate: _dateIso,
        silent: true,
        participants: [
          for (var i = 0; i < people.length; i++)
            (
              name: people[i].name,
              userRowId: people[i].isMe ? me?.rowId : null,
              amount: shares.shares[i],
              isPayer: i == _payerIndex,
            ),
        ],
      );
      c.invalidate(dutchPayListProvider);
      try {
        await c.read(dutchPayListProvider.future);
      } on Object {
        // 저장은 끝났다 — 화면은 보던 목록을 그대로 둔다
      }
      if (mounted) PBottomSheet.of(context).close();
    } catch (e) {
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
      if (isUnconfirmedSave(e)) c.invalidate(dutchPayListProvider);
      if (!mounted) return;
      setState(() {
        _saveError = true;
        _failure = e;
        _submitting = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) revealBelowFog(ctx);
      });
    } finally {
      sheet?.setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final step1 = _step == 1;
    return PBottomSheetContent(
      eyebrow: l.dutchStepLabel(_step, 2),
      title: step1 ? l.dutchInfoTitle : l.dutchParticipant,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saveError)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
              ),
              child: FormErrorCallout(
                key: _errorKey,
                message: saveFailureText(l, _failure, l.dutchSaveFailed),
              ),
            ),
          step1 ? _step1(l) : _step2(l),
        ],
      ),
      footer: step1
          ? [
              PButton(
                label: l.dutchNext,
                size: PButtonSize.large,
                onPressed: _next,
              ),
            ]
          : const [],
      footerRow: step1
          ? null
          : Row(
              spacing: PSpacing.x2,
              children: [
                Expanded(
                  child: PButton(
                    label: l.dutchPrev,
                    variant: PButtonVariant.neutralWeak,
                    size: PButtonSize.large,
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _step = 1),
                  ),
                ),
                Expanded(
                  child: PButton(
                    label: l.dutchCreate,
                    size: PButtonSize.large,
                    loading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _step1(AppLocalizations l) {
    final emptyTitle = _attempted1 && _titleCtrl.text.trim().isEmpty;
    final emptyAmount = _attempted1 && _total <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x5,
        children: [
          PField(
            label: l.dutchNameLabel,
            indicator: PFieldIndicator.required,
            required: true,
            invalid: emptyTitle,
            errorMessage: emptyTitle ? l.dutchTitleRequired : null,
            child: PInput(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              autofocus: true,
              placeholder: l.dutchNamePlaceholder,
              onChanged: (_) {
                if (_attempted1) setState(() {});
              },
            ),
          ),
          PField(
            label: l.dutchTotalLabel,
            indicator: PFieldIndicator.required,
            required: true,
            invalid: emptyAmount,
            errorMessage: emptyAmount ? l.dutchAmountRequired : null,
            child: PInput(
              controller: _amountCtrl,
              focusNode: _amountFocus,
              placeholder: '0',
              suffixText: wonUnit(),
              tabularFigures: true,
              keyboardType: TextInputType.number,
              inputFormatters: const [AmountInputFormatter()],
              onChanged: (_) => setState(() {}),
            ),
          ),
          PField(
            label: l.dutchDateLabel,
            child: PInputButton(
              value: monthDayDow(_date),
              placeholder: l.dutchDateLabel,
              semanticLabel: l.dutchDateLabel,
              onPressed: _pickDate,
            ),
          ),
          PField(
            label: l.dutchPlaceLabel,
            indicator: PFieldIndicator.optional,
            child: PInput(
              controller: _placeCtrl,
              placeholder: l.dutchPlacePlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _step2(AppLocalizations l) {
    final c = context.colors;
    final masked = ref.watch(hideCardProvider('dutchpay.sessions'));
    final people = _list();
    final shares = computeDutchShares(
      total: _total,
      method: DutchSplitMethod.equal,
      count: people.length,
      payerIndex: _payerIndex,
    );
    final per = dutchPerPersonOf(shares.shares, [
      for (final p in people) p.name,
    ]);
    final perAmount = txMoney(per.each, masked);
    final perText = !per.shown
        ? null
        : per.even
        ? l.dutchPerPersonOf(txMoney(per.each, masked))
        : l.dutchPerPersonRestOf(
            txMoney(per.each, masked),
            txMoney(per.rest, masked),
            per.restName!,
          );
    // 함께 정산했던 사람 — 아직 안 고른 친구만(같은 사람이 두 번 보이지 않는다)
    // 최근 정산 차례(같은 날은 목록 차례) 로 한 번씩, 개수 제한 없음 — 웹과 같다
    final recent = [...(ref.watch(dutchPayListProvider).value ?? const [])]
      ..sort((a, b) => (b.dutchPayDate ?? '').compareTo(a.dutchPayDate ?? ''));
    final taken = {
      _meName().toLowerCase(),
      ..._others.map((e) => e.toLowerCase()),
    };
    final seen = <String>{};
    final suggestions = <String>[
      for (final d in recent)
        for (final p in d.participants)
          if ((p.participantName ?? '').trim().isNotEmpty &&
              !taken.contains(p.participantName!.trim().toLowerCase()) &&
              seen.add(p.participantName!.trim().toLowerCase()))
            p.participantName!.trim(),
    ];
    final noOthers = _attempted2 && _others.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x5,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.dutchNPeople(people.length)),
                if (perText != null) ...[
                  const TextSpan(text: ' · '),
                  ..._boldAmount(perText, perAmount),
                ],
              ],
            ),
            style: PTypography.t5.copyWith(color: c.fgNeutral),
          ),
          PField(
            label: l.dutchParticipant,
            invalid: noOthers,
            errorMessage: noOthers ? l.dutchNeedOne : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PSpacing.x3,
              children: [
                PChipGroup(
                  semanticLabel: l.dutchParticipant,
                  children: [
                    // 나는 고른 모양으로 두고 누름만 없앤다(막힌 칩이 아니다)
                    IgnorePointer(
                      child: PChip(
                        key: const ValueKey('dutch-chip-me'),
                        label: people.first.name,
                        leading: PAvatar(
                          name: people.first.name,
                          size: PAvatarSize.s20,
                        ),
                        size: PChipSize.small,
                        selected: true,
                        onPressed: () {},
                      ),
                    ),
                    for (final n in _others)
                      PInputChip(
                        key: ValueKey('dutch-chip-$n'),
                        label: n,
                        size: PChipSize.small,
                        leading: PAvatar(name: n, size: PAvatarSize.s20),
                        removeLabel: l.dutchChipRemove(n),
                        onRemove: _submitting ? null : () => _remove(n),
                      ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: PSpacing.x2,
                  children: [
                    Expanded(
                      child: PField(
                        invalid: _nameErr != null,
                        errorMessage: _nameErr,
                        maxGraphemeCount: kDutchPersonNameMax,
                        child: PInput(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          semanticLabel: l.dutchParticipant,
                          placeholder: l.dutchAddNamePlaceholder,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) {
                            if (_nameErr != null) {
                              setState(() => _nameErr = null);
                            }
                          },
                          onSubmitted: _add,
                        ),
                      ),
                    ),
                    PButton(
                      label: l.dutchAdd,
                      variant: PButtonVariant.neutralWeak,
                      size: PButtonSize.large,
                      onPressed: _submitting
                          ? null
                          : () => _add(_nameCtrl.text),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (suggestions.isNotEmpty)
            PField(
              label: l.dutchSuggestHeader,
              labelWeight: PFieldLabelWeight.medium,
              child: PChipGroup(
                semanticLabel: l.dutchSuggestHeader,
                children: [
                  for (final n in suggestions)
                    PChip(
                      key: ValueKey('dutch-suggest-$n'),
                      label: n,
                      prefixIcon: LucideIcons.plus,
                      size: PChipSize.small,
                      onPressed: _submitting ? null : () => _add(n),
                    ),
                ],
              ),
            ),
          PField(
            label: l.dutchPayerSelect,
            child: PInputButton(
              value: people[_payerIndex].name,
              semanticLabel: l.dutchPayerSelect,
              suffixIcon: LucideIcons.chevronDown,
              onPressed: _pickPayer,
            ),
          ),
        ],
      ),
    );
  }
}

/// "1인당 36,800원 · 1원은 나" 에서 금액만 700 으로 — 글의 나머지는 그대로.
List<InlineSpan> _boldAmount(String text, String amount) {
  final i = text.indexOf(amount);
  if (i < 0) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, i)),
    TextSpan(
      text: amount,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    TextSpan(text: text.substring(i + amount.length)),
  ];
}
