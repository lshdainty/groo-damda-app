import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/category_icons.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/p_icon_picker.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/color_pick.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';

/// 이름 길이 상한 — 웹 `GOAL_NAME_MAX` · 카테고리와 같은 값(QA #52).
const _kNameMax = 12;

/// 저축 목표 폼 — 추가 · 수정을 한 시트로(I-19 D). 치는 값(이름 · 금액 둘)은 칸, 고르는 값(목표일 · 아이콘 · 색)은 줄.
/// 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 묻는다.
void showSavingGoalEditDialog(BuildContext context, {SavingGoal? edit}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  // 새 폼은 이름 칸에 초점(시트가 처음 초점을 컨테이너에 두므로 첫 초점 노드를 넘긴다), 수정 폼은 키보드 없이 표면
  final titleFocus = FocusNode(debugLabel: 'SavingGoal title');
  PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: edit == null ? titleFocus : null,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _GoalForm(edit: edit, probe: probe, titleFocus: titleFocus),
  );
}

/// 저축 목표 삭제 — ds 확인창(Alert Dialog)으로 묻고(삭제는 criticalSolid), 확정하면 지운다. 밀기 트레이와 수정 시트 바닥
/// [삭제] 가 같은 길이다. 실패하면 확인창을 닫고 스낵바(critical + 다시 시도)로 알린다 — 다시 시도는 묻지 않고 바로 지운다.
/// 띠는 앱 뿌리 호스트에 있어 화면을 나가도 남는다(그때 [context] 는 죽었으므로 미리 잡아 둔 컨테이너로 돈다).
/// 확인창에서 지우기를 눌렀으면(성공이든 실패든) true.
Future<bool> confirmDeleteSavingGoal(
  BuildContext context,
  SavingGoal goal,
) async {
  final l = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final snack = PSnackbar.of(context);
  Object? failure;
  final ok = await PAlertDialog.show(
    context,
    title: l.savingGoalDeleteTitle(goal.title),
    description: l.savingGoalDeleteConfirm,
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    destructive: true,
    onAction: () async {
      try {
        await _deleteGoal(container, goal);
      } catch (e) {
        failure = e;
      }
    },
  );
  if (ok && failure != null) {
    // 응답을 못 받았으면 지워졌을 수 있다 — [다시 시도] 없이 다시 받고 한 문장(판단 ①)
    showConfirmFailSnackbar(
      snack,
      error: failure,
      message: l.savingGoalDeleteFailed,
      retryLabel: l.actionRetry,
      retry: () => _deleteGoal(container, goal),
      unconfirmedMessage: unconfirmedWriteText(l, WriteKind.delete),
      onUnconfirmed: () => container.invalidate(savingGoalListProvider),
    );
  }
  return ok;
}

/// 실패하면 던진다 — 호출한 쪽 스낵바가 알리므로 전역 오류 토스트는 끈다.
Future<void> _deleteGoal(ProviderContainer container, SavingGoal goal) async {
  final repo = await container.read(savingGoalRepositoryProvider.future);
  await repo.delete(goal.rowId, silent: true);
  container.invalidate(savingGoalListProvider);
}

class _DirtyProbe {
  bool Function() dirty = () => false;
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.edit, required this.probe, required this.titleFocus});
  final SavingGoal? edit;
  final _DirtyProbe probe;

  /// 이름 칸 초점 노드 — 호출처가 시트의 첫 초점으로 넘기고 폼 State 가 버린다.
  final FocusNode titleFocus;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _currentCtrl;
  late final FocusNode _titleFocus = widget.titleFocus;
  final _amountFocus = FocusNode();
  final _currentFocus = FocusNode();

  late final String _initialTitle;
  late final String _initialAmount;
  late final String _initialCurrent;
  late final DateTime? _initialDeadline;
  late final String _initialIcon;
  late final String _initialColor;

  DateTime? _deadline;
  late String _icon;

  /// 저장할 색 — 팔레트 색이면 그 색의 저장 hex, 팔레트 밖이면 저장된 값 그대로(고르지 않으면 바꾸지 않는다).
  late String _color;

  /// 고치는 항목이 팔레트 밖 색을 들고 있으면 그 값 — "지금 색" 칸이 된다.
  String? _foreignColor;

  bool _submitting = false;

  Future<void> _delete() async {
    final sheet = PBottomSheet.of(context);
    final ok = await confirmDeleteSavingGoal(context, widget.edit!);
    if (ok && mounted) sheet.close();
  }

  bool _failed = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _errorKey = GlobalKey();
  String? _nameError;
  String? _amountError;
  String? _currentError;

  /// 100억을 넘겨 입력을 막았나(목표 금액 · 지금 모은 금액) — 칸 아래 오류를 띄우고 다음 유효한 입력에서 걷는다.
  bool _amountOver = false;
  bool _currentOver = false;
  late final List<TextInputFormatter> _amountFormatters = [
    AmountInputFormatter(
      onLimit: (over) {
        if (over != _amountOver && mounted) setState(() => _amountOver = over);
      },
    ),
  ];
  late final List<TextInputFormatter> _currentFormatters = [
    AmountInputFormatter(
      onLimit: (over) {
        if (over != _currentOver && mounted) {
          setState(() => _currentOver = over);
        }
      },
    ),
  ];

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _initialTitle = e?.title ?? '';
    _initialAmount = e == null ? '' : formatAmountInput(e.targetAmount);
    _initialCurrent = e == null || e.currentAmount == 0
        ? ''
        : formatAmountInput(e.currentAmount);
    _titleCtrl = TextEditingController(text: _initialTitle);
    _amountCtrl = TextEditingController(text: _initialAmount);
    _currentCtrl = TextEditingController(text: _initialCurrent);
    _initialDeadline = e?.deadlineDate == null
        ? null
        : DateTime.tryParse(e!.deadlineDate!);
    _deadline = _initialDeadline;
    // 저장된 이름을 그대로 존중한다 — 세트 밖 이름은 "지금 아이콘" 으로 보인다.
    final editIcon = e?.icon;
    _icon = editIcon != null && editIcon.isNotEmpty ? editIcon : 'piggy-bank';
    _initialIcon = _icon;

    final stored = e?.color?.trim();
    if (stored != null && stored.isNotEmpty) {
      final color = chartColorOfHex(stored);
      if (color == null) {
        _foreignColor = stored;
        _color = stored;
      } else {
        _color = chartHexOf(color);
      }
    } else {
      _color = _firstUnused();
    }
    _initialColor = _color;

    widget.probe.dirty = () =>
        _titleCtrl.text != _initialTitle ||
        _amountCtrl.text != _initialAmount ||
        _currentCtrl.text != _initialCurrent ||
        _deadline != _initialDeadline ||
        _icon != _initialIcon ||
        _color != _initialColor;
  }

  /// 같은 목록(저축 목표)이 아직 쓰지 않은 첫 색(v110 배정 순서).
  String _firstUnused() {
    final goals = ref.read(savingGoalListProvider).value ?? const [];
    return firstUnusedHex([for (final g in goals) g.color]);
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _currentCtrl.dispose();
    _titleFocus.dispose();
    _amountFocus.dispose();
    _currentFocus.dispose();
    super.dispose();
  }

  String get _titleTrim => _titleCtrl.text.trim();

  /// 같은 이름 목표가 둘이면 목록 · 알림에서 어느 쪽인지 알 수 없다. 목록 캐시가 비어 있으면 못 잡는다 — 최종 게이트는 서버다.
  bool get _duplicate =>
      _titleTrim.isNotEmpty &&
      (ref.read(savingGoalListProvider).value ?? const <SavingGoal>[]).any(
        (g) => g.title.trim() == _titleTrim && g.rowId != widget.edit?.rowId,
      );

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateText(BuildContext context, DateTime d) {
    if (Localizations.localeOf(context).languageCode == 'en') {
      return DateFormat.yMMMd('en').format(d);
    }
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<DateTime>(
      context,
      builder: (sheetContext) {
        DateTime? draft = _deadline;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final l = AppLocalizations.of(ctx);
            return PBottomSheetContent(
              title: l.savingGoalDeadlineLabel,
              closeLabel: l.actionClose,
              flushBody: true,
              body: PDatePicker.single(
                labels: PDatePickerLabels.of(ctx),
                semanticLabel: l.savingGoalDeadlineLabel,
                value: draft,
                onChanged: (v) => setSheet(() => draft = v),
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
    if (picked == null || !mounted) return;
    setState(() => _deadline = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickIcon() async {
    FocusScope.of(context).unfocus();
    await showPIconPickerSheet(
      context,
      value: _icon,
      onChanged: (id) => setState(() => _icon = id),
    );
  }

  Future<void> _pickColor() async {
    FocusScope.of(context).unfocus();
    final picked = await showColorPickSheet(
      context,
      title: AppLocalizations.of(context).savingGoalColorLabel,
      hex: _color,
      foreignHex: _foreignColor,
    );
    if (picked == null || !mounted) return;
    setState(() => _color = picked);
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    String? nameErr;
    if (_titleTrim.isEmpty) {
      nameErr = l.savingGoalErrName;
    } else if (_titleTrim.length > _kNameMax) {
      nameErr = l.savingGoalErrNameTooLong(_kNameMax);
    } else if (_duplicate) {
      nameErr = l.savingGoalNameDuplicate;
    }
    final target = parseAmountInput(_amountCtrl.text);
    final current = parseAmountInput(_currentCtrl.text) ?? 0;
    String? amountErr;
    if (target == null || target <= 0) {
      amountErr = l.savingGoalErrAmount;
    } else if (target > kAmountMax) {
      amountErr = l.savingGoalErrAmountTooLarge;
    }
    String? currentErr;
    if (amountErr == null && current > target!) {
      currentErr = l.savingGoalErrCurrentExceeds;
    }
    if (nameErr != null || amountErr != null || currentErr != null) {
      setState(() {
        _nameError = nameErr;
        _amountError = amountErr;
        _currentError = currentErr;
      });
      if (nameErr != null) {
        _titleFocus.requestFocus();
      } else if (amountErr != null) {
        _amountFocus.requestFocus();
      } else {
        _currentFocus.requestFocus();
      }
      return;
    }
    final amt = target!;
    setState(() {
      _failed = false;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await ref.read(savingGoalRepositoryProvider.future);
      // 현재 모은 금액은 update/create 필드가 아니라 contribute API 로 차액 반영(웹 동일 로직).
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: _titleTrim,
          targetAmount: amt,
          // 목표일을 지운 채 저장하면 지워져야 한다 — 키를 빼면 옛 날짜가 남는다(QA #99).
          deadlineDate: Patch.set(
            _deadline == null ? null : _fmtDate(_deadline!),
          ),
          color: _color,
          icon: _icon,
          silent: true,
        );
        final diff = current - widget.edit!.currentAmount;
        if (diff != 0) {
          await repo.contribute(widget.edit!.rowId, amount: diff, silent: true);
        }
      } else {
        final created = await repo.create(
          title: _titleTrim,
          targetAmount: amt,
          deadlineDate: _deadline == null ? null : _fmtDate(_deadline!),
          color: _color,
          icon: _icon,
          silent: true,
        );
        if (current > 0) {
          // 만들기는 성공했다 — 그 목표는 이미 있다. 첫 납입만 실패하면 폼을 열어 두지 않는다
          // (다시 누르면 같은 목표가 또 생긴다). 닫고 스낵바 + [다시 시도](납입만).
          try {
            await repo.contribute(created.rowId, amount: current, silent: true);
          } on ApiException catch (e) {
            ref.invalidate(savingGoalListProvider);
            if (!mounted) return;
            final l = AppLocalizations.of(context);
            final container = ProviderScope.containerOf(context);
            final snack = PSnackbar.of(context);
            PBottomSheet.of(context).close();
            // 납입 응답만 못 읽었다(서버는 납입했다) — [다시 시도] 를 주면 두 번 납입된다. 확인을 부탁한다(검수 M3)
            if (isUnconfirmedSave(e)) {
              snack.show(
                message: unconfirmedWriteText(l, WriteKind.save),
                tone: PSnackbarTone.critical,
              );
              return;
            }
            _firstContributionFailed(
              container,
              l,
              snack,
              created.rowId,
              current,
            );
            return;
          }
        }
      }
      ref.invalidate(savingGoalListProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 폼은 열린 채 쓴 값이 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      if (!mounted) return;
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다
      if (isUnconfirmedSave(e)) ref.invalidate(savingGoalListProvider);
      setState(() {
        _failed = true;
        _failure = e;
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

  /// 첫 납입 실패 스낵바 — [다시 시도] 는 만든 목표 id 로 납입만 다시 한다(만들기 재요청 금지).
  /// 또 실패하면 같은 띠를 다시 띄운다. 시트가 닫힌 뒤에도 쓰이므로 State 를 쓰지 않는다.
  static void _firstContributionFailed(
    ProviderContainer container,
    AppLocalizations l,
    PSnackbarApi snack,
    int goalId,
    int amount,
  ) {
    snack.show(
      message: l.savingGoalFirstContributeFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () async {
          try {
            final repo = await container.read(
              savingGoalRepositoryProvider.future,
            );
            await repo.contribute(goalId, amount: amount, silent: true);
            container.invalidate(savingGoalListProvider);
          } on ApiException catch (e) {
            // 응답을 못 받았다 — 납입됐을 수 있다. 또 [다시 시도] 를 주지 않는다(두 번 납입, 검수 M3)
            if (isUnconfirmedSave(e)) {
              container.invalidate(savingGoalListProvider);
              snack.show(
                message: unconfirmedWriteText(l, WriteKind.save),
                tone: PSnackbarTone.critical,
              );
              return;
            }
            _firstContributionFailed(container, l, snack, goalId, amount);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final colorName = colorPickName(context, _color);
    final iconEntry = findCategoryIcon(_icon);
    final iconName =
        iconEntry?.name ?? PIconPickerTexts.of(context).currentIconName;

    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    return PBottomSheetContent(
      title: _isEdit ? l.savingGoalEdit : l.savingGoalAdd,
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
                message: saveFailureText(l, _failure, l.savingGoalSaveFailed),
              ),
            ),
          Padding(
            padding: gutter,
            child: PField(
              label: l.savingGoalNameLabel,
              maxGraphemeCount: _kNameMax,
              invalid: _nameError != null,
              errorMessage: _nameError,
              child: PInput(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                placeholder: l.savingGoalNameHint,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x6),
          Padding(
            padding: gutter,
            child: PField(
              label: l.savingGoalAmountLabel,
              invalid: _amountError != null || _amountOver,
              errorMessage: _amountOver
                  ? l.savingGoalErrAmountTooLarge
                  : _amountError,
              child: _amountInput(
                _amountCtrl,
                _amountFocus,
                _amountFormatters,
                () {
                  if (_amountError != null || _currentError != null) {
                    setState(() {
                      _amountError = null;
                      _currentError = null;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x6),
          Padding(
            padding: gutter,
            child: PField(
              label: l.savingGoalCurrentLabel,
              indicator: PFieldIndicator.optional,
              invalid: _currentError != null || _currentOver,
              errorMessage: _currentOver ? l.amountTooLarge : _currentError,
              child: _amountInput(
                _currentCtrl,
                _currentFocus,
                _currentFormatters,
                () {
                  if (_currentError != null) {
                    setState(() => _currentError = null);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          PickerRow(
            title: l.savingGoalDeadlineLabel,
            value: _deadline == null
                ? l.savingGoalDeadlineHint
                : _dateText(context, _deadline!),
            onTap: _pickDate,
            onClear: _deadline == null
                ? null
                : () => setState(() => _deadline = null),
            clearLabel: l.savingGoalDeadlineClear,
          ),
          PickerRow(
            title: l.savingGoalIconLabel,
            value: iconName,
            leading: Icon(
              categoryGlyph(_icon),
              size: 20,
              color: c.fgNeutralMuted,
            ),
            onTap: _pickIcon,
          ),
          PickerRow(
            title: l.savingGoalColorLabel,
            value: colorName,
            leading: PickerDot(
              size: 12,
              color: resolveChartColor(context, _color, fallback: c.fgBrand),
            ),
            onTap: _pickColor,
          ),
          const SizedBox(height: PSpacing.x2),
        ],
      ),
      footer: _isEdit
          ? const []
          : [
              PButton(
                label: l.savingGoalSubmitAdd,
                size: PButtonSize.large,
                loading: _submitting,
                onPressed: _submitting ? null : _onSubmit,
              ),
            ],
      // 수정 — 바닥 왼쪽 [삭제](밀기와 같은 동작 · 확인창 한 번). 밀기는 지름길이라 닫는 길은 여기에도 있다
      footerRow: _isEdit
          ? Row(
              spacing: PSpacing.x2,
              children: [
                // 내용 폭 ghost critical — 안쪽 여백 20 을 바깥으로 내어 글이 화면 여백 24 에 선다
                Transform.translate(
                  offset: const Offset(-20, 0),
                  child: PButton(
                    label: l.actionDelete,
                    variant: PButtonVariant.ghost,
                    ghostColor: PButtonGhostColor.critical,
                    size: PButtonSize.large,
                    onPressed: _submitting ? null : _delete,
                  ),
                ),
                Expanded(
                  child: PButton(
                    label: l.actionSave,
                    size: PButtonSize.large,
                    loading: _submitting,
                    onPressed: _submitting ? null : _onSubmit,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _amountInput(
    TextEditingController ctrl,
    FocusNode focus,
    List<TextInputFormatter> formatters,
    VoidCallback onEdited,
  ) => PInput(
    controller: ctrl,
    focusNode: focus,
    placeholder: '0',
    suffixText: wonUnit(),
    tabularFigures: true,
    keyboardType: TextInputType.number,
    inputFormatters: formatters,
    onChanged: (_) => onEdited(),
  );
}
