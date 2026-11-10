import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart'
    show CalendarSaveErrorCallout;
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart'
    show PLeaveConfirmCopy;
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/color_pick.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 캘린더 이름 최대 글자 수 — 서버 `FieldLimits.NAME_MAX`.
const int kCalendarNameMax = 50;

/// 초대 코드 길이 — 서버 코드는 대문자 16진 8자(`UserCalendar.java`).
const int kInviteCodeLength = 8;

/// 새 캘린더 · 캘린더 이름 바꾸기 · 초대 코드로 참여(I-09b 24 · 34 · 36) — 모두 ds Bottom Sheet 입력 폼이다.
/// 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 "작성한 내용이 사라져요" 를 묻는다. 바닥은 버튼 하나.
/// 비워 두고 눌러도 [저장] 은 켜 둔 채 칸 아래 오류로 알린다(field.md:86). 요청 실패는 맨 위 Callout, 요청은 silent 표식을 싣는다.

class _DirtyProbe {
  bool Function() dirty = () => false;
}

PLeaveConfirmCopy _leaveCopy(AppLocalizations l) => PLeaveConfirmCopy(
  title: l.sheetLeaveTitle,
  description: l.sheetLeaveDescription,
  stayLabel: l.sheetLeaveStay,
  leaveLabel: l.sheetLeaveLeave,
);

Future<void> _showForm(
  BuildContext context, {
  required Widget Function(_DirtyProbe probe, FocusNode focus) build,
}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  // 새 폼은 첫 칸에 초점 — 시트가 처음 초점을 컨테이너에 두므로 첫 초점 노드를 넘긴다
  final focus = FocusNode(debugLabel: 'CalendarForm first');
  return PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: focus,
    isDirty: () => probe.dirty(),
    leaveCopy: _leaveCopy(l),
    builder: (_) => build(probe, focus),
  ).whenComplete(focus.dispose);
}

// ─── 새 캘린더 ──────────────────────────────────────────────

/// 캘린더 추가 — 이름 칸 + "색상" 줄. 처음 색은 내 캘린더가 아직 쓰지 않은 첫 색.
Future<void> showCalendarCreateSheet(BuildContext context) => _showForm(
  context,
  build: (probe, focus) => _CreateForm(probe: probe, nameFocus: focus),
);

class _CreateForm extends ConsumerStatefulWidget {
  const _CreateForm({required this.probe, required this.nameFocus});
  final _DirtyProbe probe;
  final FocusNode nameFocus;

  @override
  ConsumerState<_CreateForm> createState() => _CreateFormState();
}

class _CreateFormState extends ConsumerState<_CreateForm> {
  final _nameCtrl = TextEditingController();
  late String _color;
  late final String _initialColor;
  bool _submitting = false;
  String? _nameError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final calendars = ref.read(userCalendarListProvider).value ?? const [];
    _color = firstUnusedHex([
      for (final c in calendars)
        if (c.isOwner) c.color,
    ]);
    _initialColor = _color;
    widget.probe.dirty = () =>
        _nameCtrl.text.trim().isNotEmpty || _color != _initialColor;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    FocusScope.of(context).unfocus();
    final picked = await showColorPickSheet(
      context,
      title: AppLocalizations.of(context).calFieldColor,
      hex: _color,
    );
    if (picked == null || !mounted) return;
    setState(() => _color = picked);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l.calNameRequired);
      widget.nameFocus.requestFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(userCalendarRepositoryProvider.future);
      await repo.create(calendarName: name, color: _color, silent: true);
      container.invalidate(userCalendarListProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비우고 실패라 하지 않는다(검수 M3)
      if (isUnconfirmedSave(e)) container.invalidate(userCalendarListProvider);
      if (!mounted) return;
      setState(() => _saveError = saveFailureText(l, e, l.calCreateFailed));
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return PBottomSheetContent(
      title: l.calNewCalendar,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saveError != null)
            CalendarSaveErrorCallout(message: _saveError!),
          // 머리 바로 아래 — 위 0 · 좌우 24 · 아래 8
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PField(
              invalid: _nameError != null,
              errorMessage: _nameError,
              child: PInput(
                controller: _nameCtrl,
                focusNode: widget.nameFocus,
                semanticLabel: l.calFieldName,
                placeholder: l.calCalendarNamePlaceholder,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kCalendarNameMax),
                ],
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          PList(
            semanticLabel: l.calNewCalendar,
            children: [
              PickerRow(
                title: l.calFieldColor,
                prefix: const ExcludeSemantics(
                  child: Icon(LucideIcons.palette),
                ),
                value: colorPickName(context, _color),
                leading: PickerDot(
                  color: resolveChartColor(
                    context,
                    _color,
                    fallback: c.fgBrand,
                  ),
                ),
                onTap: _pickColor,
              ),
            ],
          ),
        ],
      ),
      footer: [
        PButton(
          label: l.calCreate,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

// ─── 이름 바꾸기 ────────────────────────────────────────────

/// 캘린더 이름 바꾸기 — 지금 이름이 채워져 열린다. 저장은 이름만 보낸다(서버는 보낸 칸만 바꾼다).
Future<void> showCalendarRenameSheet(
  BuildContext context, {
  required UserCalendar calendar,
  ValueChanged<String>? onRenamed,
}) => _showForm(
  context,
  build: (probe, focus) => _RenameForm(
    calendar: calendar,
    probe: probe,
    nameFocus: focus,
    onRenamed: onRenamed,
  ),
);

class _RenameForm extends ConsumerStatefulWidget {
  const _RenameForm({
    required this.calendar,
    required this.probe,
    required this.nameFocus,
    this.onRenamed,
  });
  final UserCalendar calendar;
  final _DirtyProbe probe;
  final FocusNode nameFocus;

  /// 저장이 끝났다 — 목록을 다시 받는 동안 옛 이름이 보이지 않게 부모가 새 이름을 먼저 보인다.
  final ValueChanged<String>? onRenamed;

  @override
  ConsumerState<_RenameForm> createState() => _RenameFormState();
}

class _RenameFormState extends ConsumerState<_RenameForm> {
  late final TextEditingController _nameCtrl;
  bool _submitting = false;
  String? _nameError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.calendar.calendarName);
    widget.probe.dirty = () => _nameCtrl.text != widget.calendar.calendarName;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l.calNameRequired);
      widget.nameFocus.requestFocus();
      return;
    }
    // 이름을 안 바꿨으면 보낼 것이 없다
    if (name == widget.calendar.calendarName) {
      PBottomSheet.of(context).close();
      return;
    }
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(userCalendarRepositoryProvider.future);
      await repo.update(
        id: widget.calendar.rowId,
        calendarName: name,
        silent: true,
      );
      widget.onRenamed?.call(name);
      container.invalidate(userCalendarListProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException catch (e) {
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비우고 실패라 하지 않는다(검수 M3)
      if (isUnconfirmedSave(e)) container.invalidate(userCalendarListProvider);
      if (!mounted) return;
      setState(() => _saveError = saveFailureText(l, e, l.calManageSaveFailed));
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PBottomSheetContent(
      title: l.calManageNameTitle,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saveError != null)
            CalendarSaveErrorCallout(message: _saveError!),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PField(
              invalid: _nameError != null,
              errorMessage: _nameError,
              child: PInput(
                controller: _nameCtrl,
                focusNode: widget.nameFocus,
                semanticLabel: l.calManageNameTitle,
                placeholder: l.calCalendarNameFieldPlaceholder,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kCalendarNameMax),
                ],
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
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

// ─── 초대 코드로 참여 ───────────────────────────────────────

/// 초대 코드로 참여 — 칸 하나. 틀린 코드 · 이미 참여한 캘린더는 칸 아래 오류(서버 글이 아니라 우리 글), 성공은 닫고 스낵바.
Future<void> showCalendarJoinSheet(BuildContext context) => _showForm(
  context,
  build: (probe, focus) => _JoinForm(probe: probe, codeFocus: focus),
);

class _JoinForm extends ConsumerStatefulWidget {
  const _JoinForm({required this.probe, required this.codeFocus});
  final _DirtyProbe probe;
  final FocusNode codeFocus;

  @override
  ConsumerState<_JoinForm> createState() => _JoinFormState();
}

class _JoinFormState extends ConsumerState<_JoinForm> {
  final _codeCtrl = TextEditingController();
  bool _submitting = false;
  String? _codeError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () => _codeCtrl.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Enter 연타로 요청이 겹치지 않게
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _codeError = l.calJoinCodeRequired);
      widget.codeFocus.requestFocus();
      return;
    }
    // 시트가 닫히면 이 context 가 없다 — 알림 길은 미리 쥔다
    final snack = PSnackbar.maybeOf(context);
    setState(() {
      _submitting = true;
      _codeError = null;
      _saveError = null;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(userCalendarRepositoryProvider.future);
      final joined = await repo.joinByCode(code);
      container.invalidate(userCalendarListProvider);
      // 그 캘린더의 일정도 이제 내 조회 결과에 들어온다(웹과 같게)
      container.invalidate(monthEventsProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
      snack?.show(
        message: l.calJoinedCalendar(joined.calendarName),
        tone: PSnackbarTone.positive,
      );
    } on ApiException catch (e) {
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비우고 실패라 하지 않는다(검수 M3)
      if (isUnconfirmedSave(e)) {
        container.invalidate(userCalendarListProvider);
        container.invalidate(monthEventsProvider);
      }
      if (!mounted) return;
      setState(() {
        switch (e.code) {
          case 'CAL_012':
            _codeError = l.calJoinInvalidCode;
          case 'CAL_011':
            _codeError = l.calJoinAlreadyMember;
          default:
            _saveError = saveFailureText(l, e, l.calJoinFailed);
        }
      });
      if (_codeError != null) widget.codeFocus.requestFocus();
    } finally {
      sheet?.setBusy(false);
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PBottomSheetContent(
      title: l.calJoinByCode,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saveError != null)
            CalendarSaveErrorCallout(message: _saveError!),
          // 칸이 하나뿐이라 보이는 이름 "초대 코드" — 좌우 24 · 아래 16
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x4,
            ),
            child: PField(
              label: l.calInviteCode,
              invalid: _codeError != null,
              errorMessage: _codeError,
              child: PInput(
                controller: _codeCtrl,
                focusNode: widget.codeFocus,
                placeholder: l.calInviteCodePlaceholder,
                // 영문 · 숫자만, 최대 8 — 보내기 전에 대문자로 바꾼다
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(kInviteCodeLength),
                ],
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_codeError != null) setState(() => _codeError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
        ],
      ),
      footer: [
        PButton(
          label: l.calJoin,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
