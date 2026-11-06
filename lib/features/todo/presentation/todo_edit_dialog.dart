import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_ledger.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';
import 'package:groo_damda_app/features/todo/domain/todo_tag.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/widgets/markdown_preview.dart';

/// 제목 · 메모 입력 상한 — 서버 `FieldLimits`(TITLE_MAX 200 · CONTENT_MAX 10,000)와 같은 값(웹과 같다).
const int kTodoTitleMax = 200;
const int kTodoContentMax = 10000;

/// 할 일 추가 · 수정 폼(I-10 20) — ds Bottom Sheet 입력 폼. 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 "작성한 내용이
/// 사라져요" 를 묻는다. 칸은 한 줄에 하나씩 세로로: 제목 · 마감일 · 태그 · 우선순위(칩) · 메모. 바닥은 [추가] / [저장] 하나.
///
/// 새 할 일의 마감일은 오늘로 미리 채운다(웹과 같다). 편집 ↔ 미리보기(마크다운)는 메모 칸의 Segmented Control 이다 — 앱에만 있다.
void showTodoEditDialog(BuildContext context, {Todo? edit}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  // 새 폼은 제목 칸에 초점(시트가 처음 초점을 컨테이너에 두므로 첫 초점 노드를 넘긴다), 수정 폼은 키보드 없이 표면
  final titleFocus = FocusNode(debugLabel: 'Todo title');
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
    builder: (_) =>
        TodoFormSheet(edit: edit, probe: probe, titleFocus: titleFocus),
  );
}

/// 시트가 바뀐 값을 가졌는지 — 입력칸의 주인은 시트 State 라, 닫을 때 그쪽에 묻는다.
class _DirtyProbe {
  bool Function() dirty = () => false;
}

class TodoFormSheet extends ConsumerStatefulWidget {
  const TodoFormSheet({super.key, this.edit, this.probe, this.titleFocus});

  final Todo? edit;
  final Object? probe;

  /// 제목 칸 초점 노드 — 호출처가 시트의 첫 초점으로 넘기면 폼 State 가 버린다. 없으면 자기 것.
  final FocusNode? titleFocus;

  @override
  ConsumerState<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<TodoFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final FocusNode _titleFocus = widget.titleFocus ?? FocusNode();

  late final String _initialTitle;
  late final String _initialContent;
  late final String? _initialTag;
  late final String _initialPriority;
  late final DateTime? _initialDue;

  /// 고른 태그 이름 — **null 이면 태그 없음**. 담기는 곳은 기존 `category` 필드다. 목록은 서버 태그 마스터가 SoT 라 앱이 이름을
  /// 지어내지 않는다(메모 편집기와 같은 모양 — QA #98 · #105).
  late String? _tag;
  late String _priority;
  DateTime? _due;
  bool _previewContent = false;
  bool _submitting = false;
  bool _failed = false;
  final _errorKey = GlobalKey();
  String? _titleError;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _initialTitle = e?.title ?? '';
    _initialContent = e?.content ?? '';
    // 새 할 일은 '태그 없음' 으로 연다. 목록의 첫 태그를 채워 두면 제목만 쓰고 저장해도 그 태그가 붙는다 — 사용자가 시키지 않은 쓰기다.
    final tag = e?.category?.trim() ?? '';
    _initialTag = tag.isEmpty ? null : tag;
    _initialPriority = e?.priority ?? 'MEDIUM';
    // 새 할 일의 마감일은 오늘 — 웹과 같다(I-10 20). 고치는 할 일은 가진 값 그대로(없으면 없음).
    final now = DateTime.now();
    _initialDue = _isEdit ? e!.due : DateTime(now.year, now.month, now.day);
    _titleCtrl = TextEditingController(text: _initialTitle);
    _contentCtrl = TextEditingController(text: _initialContent);
    _tag = _initialTag;
    _priority = _initialPriority;
    _due = _initialDue;
    final probe = widget.probe;
    if (probe is _DirtyProbe) {
      probe.dirty = () =>
          _titleCtrl.text != _initialTitle ||
          _contentCtrl.text != _initialContent ||
          _tag != _initialTag ||
          _priority != _initialPriority ||
          _due != _initialDue;
    }
  }

  @override
  void dispose() {
    final probe = widget.probe;
    if (probe is _DirtyProbe) probe.dirty = () => false;
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// 태그 선택지 — 서버 마스터 목록 + 지금 값(목록에 없으면 맨 앞에 보존).
  ///
  /// 목록이 비거나(태그를 하나도 안 만든 계정) 조회가 실패해도 select 는 비지 않는다: "태그 없음" 항목이 늘 맨 앞에 붙고, 편집 중인
  /// 할 일이 들고 있던 태그는 여기서 살아남는다. 조회가 실패해도 **지금 값이 지워지지 않는다** — 못 고르게 될 뿐이다. 없는
  /// 태그를 끼워 넣으면 저장할 때 서버가 그 이름의 마스터를 새로 만들어, 사용자가 지운 태그가 되살아난다.
  List<String> _tagChoices(List<TodoTag> server) {
    final names = [for (final t in server) t.tagName];
    final current = _tag;
    return [if (current != null && !names.contains(current)) current, ...names];
  }

  String _fmtDate(DateTime d) => todoYmd(d);

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<DateTime>(
      context,
      builder: (sheetContext) {
        DateTime? draft = _due;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final l = AppLocalizations.of(ctx);
            return PBottomSheetContent(
              title: l.todoDueDate,
              closeLabel: l.actionClose,
              flushBody: true,
              body: PDatePicker.single(
                labels: PDatePickerLabels.of(ctx),
                semanticLabel: l.todoDueDate,
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
    setState(() => _due = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = l.todoTitleRequired);
      _titleFocus.requestFocus();
      return;
    }
    setState(() {
      _failed = false;
      _submitting = true;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      final content = _contentCtrl.text.trim();
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: title,
          // 메모를 지우고, 기한을 없앤 채 저장하면 그대로 지워져야 한다 — 키를 빼면 서버가 옛 값을 지킨다(QA #99).
          content: Patch.set(content.isEmpty ? null : content),
          priority: _priority,
          // 태그도 이 화면이 비울 수 있는 칸이다 — "태그 없음" 을 고르면 키를 빼지 말고 명시적 null 로 실어야 서버가 지운다.
          category: Patch.set(_tag),
          dueDate: Patch.set(_due == null ? null : _fmtDate(_due!)),
          silent: true,
        );
      } else {
        await repo.create(
          title: title,
          content: content.isEmpty ? null : content,
          priority: _priority,
          category: _tag,
          dueDate: _due == null ? null : _fmtDate(_due!),
          silent: true,
        );
      }
      ref.invalidate(todoListProvider);
      // 홈 위젯(할 일 개수·최근 할 일)의 원본 — 셸 상주라 스스로 안 받는다.
      ref.invalidate(dashboardSummaryProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException {
      // 폼은 열린 채 쓴 값이 남는다 — 실패는 폼 맨 위 Callout 한 문장(우리 글, 서버 글 아님)이 말한다.
      if (!mounted) return;
      setState(() => _failed = true);
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
    final server = ref.watch(todoTagListProvider).value ?? const <TodoTag>[];
    final choices = _tagChoices(server);
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    Widget field(Widget child) => Padding(padding: gutter, child: child);
    return PBottomSheetContent(
      title: _isEdit ? l.todoEditTitle : l.todoAdd,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x4,
        children: [
          if (_failed)
            field(FormErrorCallout(key: _errorKey, message: l.todoSaveFailed)),
          field(
            PField(
              label: l.calFieldTitle,
              indicator: PFieldIndicator.required,
              required: true,
              invalid: _titleError != null,
              errorMessage: _titleError,
              child: PInput(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                placeholder: l.todoTitlePlaceholder,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kTodoTitleMax),
                ],
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
            ),
          ),
          field(
            PField(
              label: l.todoDueDate,
              child: PInputButton(
                value: _due == null ? null : monthDayDow(_due!),
                placeholder: l.todoDueDatePlaceholder,
                suffixIcon: LucideIcons.calendar,
                clearLabel: l.todoDueClear,
                onPressed: _pickDate,
                onClear: _due == null
                    ? null
                    : () => setState(() => _due = null),
              ),
            ),
          ),
          field(
            PField(
              label: l.todoTag,
              // 태그가 하나도 없으면 어디서 만드는지 알린다.
              description: server.isEmpty ? l.todoTagEmptyHint : null,
              child: PSelect<String>(
                // "태그 없음" 은 늘 맨 앞(고르는 값은 sentinel — 저장할 때 null 로 바꿔 싣는다).
                groups: [
                  PSelectGroup<String>(
                    items: [
                      PSelectItem<String>(
                        value: kTodoNoTagKey,
                        label: l.todoTagNone,
                      ),
                      for (final name in choices)
                        PSelectItem<String>(value: name, label: name),
                    ],
                  ),
                ],
                value: _tag ?? kTodoNoTagKey,
                placeholder: l.todoTagSelect,
                onChanged: (v) =>
                    setState(() => _tag = v == kTodoNoTagKey ? null : v),
              ),
            ),
          ),
          field(
            PField(
              label: l.todoPriorityLabel,
              child: PChipRadioGroup<String>(
                value: _priority,
                semanticLabel: l.todoPriorityLabel,
                onChanged: (v) => setState(() => _priority = v),
                children: [
                  for (final p in kTodoPrios)
                    PChipRadio<String>(
                      value: p.code,
                      label: todoPrioLabel(l, p.code),
                    ),
                ],
              ),
            ),
          ),
          field(
            PField(
              label: l.todoContentLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: PSpacing.x2,
                children: [
                  // 편집 ↔ 미리보기(마크다운) — 앱에만 있다.
                  PSegmentedControl<bool>(
                    value: _previewContent,
                    semanticLabel: l.todoContentLabel,
                    onChanged: (v) => setState(() => _previewContent = v),
                    items: [
                      PSegmentedItem(value: false, label: l.todoEditMode),
                      PSegmentedItem(value: true, label: l.todoPreview),
                    ],
                  ),
                  if (_previewContent)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 96),
                      child: _contentCtrl.text.trim().isEmpty
                          ? Text(
                              l.todoNoContent,
                              style: PTypography.t4.copyWith(
                                color: context.colors.fgNeutralSubtle,
                              ),
                            )
                          : MarkdownPreview(_contentCtrl.text),
                    )
                  else
                    PTextarea(
                      controller: _contentCtrl,
                      placeholder: l.todoContentPlaceholder,
                      maxHeight: 200,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(kTodoContentMax),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x2),
        ],
      ),
      footer: [
        PButton(
          // 고치는 폼의 주 버튼은 "저장"(수정이 아니다 — 웹과 같다)
          label: _isEdit ? l.actionSave : l.calAdd,
          size: PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _onSubmit,
        ),
      ],
    );
  }
}
