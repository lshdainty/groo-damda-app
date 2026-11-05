import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart'
    show CalendarSaveErrorCallout;
import 'package:groo_damda_app/features/calendar/presentation/calendar_surface_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart'
    show PLeaveConfirmCopy;
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as dsb;
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/color_pick.dart';
import 'package:groo_damda_app/shared/forms/name_policy.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/widgets/p_swipe_actions.dart';

/// 라벨 이름 최대 글자 수 — 카테고리 · 라벨 · 태그 · 목표 이름 12자(웹 d837eedc, 카드 한 줄에 들어가는 길이).
const int kLabelNameMax = 12;

/// 설정 진입 — 캘린더 라벨 관리 (전 캘린더 공용).
///
/// design `LabelManagerSection` 미러: 안내 카드 + "전체 라벨 N" 리스트
/// (색칩 + 이름 + 삭제) + 추가/편집(이름 + palette 색) + 삭제 확인.
///
/// 백엔드 `EventLabel` 에 icon 필드가 없으므로 design 의 icon picker 는 생략 —
/// 라벨은 "이름 + 색"만 영속한다. 색은 chart palette tone(base hex).
class CalendarLabelsScreen extends ConsumerStatefulWidget {
  const CalendarLabelsScreen({super.key});

  @override
  ConsumerState<CalendarLabelsScreen> createState() =>
      _CalendarLabelsScreenState();
}

class _CalendarLabelsScreenState extends ConsumerState<CalendarLabelsScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — eventLabels 는 keepAlive 라 다른 클라이언트 변경 반영 위해 무효화.
    Future.microtask(() {
      if (mounted) ref.invalidate(eventLabelsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labelsAsync = ref.watch(eventLabelsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgLayerDefault,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-16 14)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.calLabelsTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      // 흰 면 하나 — 카드 · 줄 사이 선 · 구역 틈이 없다(I-09 44)
      body: PScreenBandBody(
        child: PPullToRefresh(
          onRefresh: () async {
            ref.invalidate(eventLabelsProvider);
            await ref.read(eventLabelsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: PSpacing.x6),
            children: [
              CalendarSurfaceCallout(l.calLabelsIntro),
              labelsAsync.when(
                // 다시 받기가 실패해도 받아 둔 목록은 남긴다(웹과 같다)
                skipError: true,
                // 추가 버튼은 정적 UI라 로딩에도 진짜를 쓴다 — 개수 글과 줄만 데이터 자리
                loading: () => Column(
                  children: [
                    CalendarSurfaceHeaderSkeleton(
                      action: PTextButton(
                        label: l.calNewLabel,
                        onPressed: () => _showLabelEditor(context, ref, null),
                      ),
                    ),
                    for (var i = 0; i < 4; i++)
                      const CalendarSurfaceRowSkeleton(),
                  ],
                ),
                error: (e, _) => CalendarSurfaceFailure(
                  title: l.calLabelLoadError,
                  onRetry: () => ref.invalidate(eventLabelsProvider),
                ),
                data: (labels) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PListHeader(
                      title: l.calAllLabelsCount(labels.length),
                      variant: PListHeaderVariant.boldSolid,
                      action: PTextButton(
                        label: l.calNewLabel,
                        onPressed: () => _showLabelEditor(context, ref, null),
                      ),
                    ),
                    if (labels.isEmpty)
                      CalendarSurfaceEmptyLine(
                        l.calLabelsEmpty,
                        hint: l.calLabelsEmptyHint,
                      )
                    else
                      PList(
                        semanticLabel: l.calAllLabelsCount(labels.length),
                        children: [
                          for (final label in labels)
                            // 밀면 수정·삭제(폰 지름길). 줄 누름은 지금 그대로 편집 시트다
                            // — 화면을 옮기지 않으니 꺾쇠가 없다(list.md:122)
                            PSwipeActions(
                              key: ValueKey('cal-label-${label.rowId}'),
                              groupTag: 'cal-label-list',
                              actions: [
                                PSwipeAction(
                                  label: l.actionEdit,
                                  icon: LucideIcons.pencil,
                                  kind: PSwipeKind.primary,
                                  onSelect: () =>
                                      _showLabelEditor(context, ref, label),
                                ),
                                PSwipeAction(
                                  label: l.actionDelete,
                                  icon: LucideIcons.trash2,
                                  kind: PSwipeKind.destructive,
                                  // _confirmDelete 가 자체 확인을 띄운다 — 여기서 또 주면 두 번 뜬다
                                  onSelect: () =>
                                      _confirmDelete(context, label),
                                ),
                              ],
                              child: PListButtonItem(
                                prefix: PListTile(
                                  background: chartToneOf(
                                    context,
                                    label.color,
                                  ).weak,
                                  color: chartToneOf(
                                    context,
                                    label.color,
                                  ).solid,
                                  child: const Icon(LucideIcons.tag),
                                ),
                                title: label.labelName,
                                detail: l.calLabelUsage(label.usageCount),
                                onTap: () =>
                                    _showLabelEditor(context, ref, label),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 추가/편집 ──────────────────────────────────────────────

/// 라벨 추가 · 수정 폼(I-09b 39 · 40) — ds Bottom Sheet 입력 폼. 이름 칸(12자 · 세는 줄) + "색상" 줄, 미리보기는 없다.
/// 바닥은 추가 [추가], 수정 [삭제][저장](삭제는 내용 폭 ghost critical 왼쪽, 글 시작 24). 비워 두고 눌러도 [저장] 은 켜 둔다.
void _showLabelEditor(
  BuildContext context,
  WidgetRef ref,
  EventLabel? existing,
) {
  final l = AppLocalizations.of(context);
  final probe = _LabelProbe();
  final focus = FocusNode(debugLabel: 'Label name');
  PBottomSheet.show<void>(
    context,
    form: true,
    initialFocus: existing == null ? focus : null,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) =>
        _LabelForm(existing: existing, probe: probe, nameFocus: focus),
  ).whenComplete(focus.dispose);
}

class _LabelProbe {
  bool Function() dirty = () => false;
}

class _LabelForm extends ConsumerStatefulWidget {
  const _LabelForm({
    required this.existing,
    required this.probe,
    required this.nameFocus,
  });
  final EventLabel? existing;
  final _LabelProbe probe;
  final FocusNode nameFocus;

  @override
  ConsumerState<_LabelForm> createState() => _LabelFormState();
}

class _LabelFormState extends ConsumerState<_LabelForm> {
  late final TextEditingController _nameCtrl;
  late String _color;
  late final String _initialName;
  late final String _initialColor;
  String? _foreignColor;
  bool _submitting = false;
  String? _nameError;
  String? _saveError;

  EventLabel? get _edit => widget.existing;

  @override
  void initState() {
    super.initState();
    _initialName = _edit?.labelName ?? '';
    _nameCtrl = TextEditingController(text: _initialName);
    final stored = _edit?.color?.trim();
    if (stored != null && stored.isNotEmpty) {
      final color = chartColorOfHex(stored);
      if (color == null) {
        // 팔레트 밖 색 — "지금 색" 칸. 고르지 않으면 바꾸지 않는다
        _foreignColor = stored;
        _color = stored;
      } else {
        _color = chartHexOf(color);
      }
    } else {
      // 추가 — 라벨 목록이 아직 쓰지 않은 첫 색
      final labels = ref.read(eventLabelsProvider).value ?? const [];
      _color = firstUnusedHex([for (final x in labels) x.color]);
    }
    _initialColor = _color;
    widget.probe.dirty = () =>
        _nameCtrl.text != _initialName || _color != _initialColor;
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
      foreignHex: _foreignColor,
    );
    if (picked == null || !mounted) return;
    setState(() => _color = picked);
  }

  /// 칸 아래에 보일 오류 — 빈 이름 · 같은 이름 · 12자 초과(안 바꾼 옛 이름은 면제 — 색만 고칠 수 있다).
  String? _issueText(AppLocalizations l) {
    final raw = _nameCtrl.text;
    final taken = [
      for (final x
          in ref.read(eventLabelsProvider).value ?? const <EventLabel>[])
        if (x.rowId != _edit?.rowId) x.labelName,
    ];
    final issue = nameIssue(raw, kLabelNameMax, taken);
    return switch (issue) {
      NameIssue.required => l.calLabelNameRequired,
      NameIssue.duplicate => l.calLabelNameDuplicate,
      NameIssue.tooLong =>
        raw == _edit?.labelName ? null : l.nameTooLong(kLabelNameMax),
      null => null,
    };
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final err = _issueText(l);
    if (err != null) {
      setState(() => _nameError = err);
      widget.nameFocus.requestFocus();
      return;
    }
    final name = _nameCtrl.text.trim();
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      if (_edit == null) {
        await repo.createLabel(labelName: name, color: _color);
      } else {
        await repo.updateLabel(
          id: _edit!.rowId,
          labelName: name,
          color: _color,
        );
      }
      ref.invalidate(eventLabelsProvider);
      // 일정 응답에 라벨 이름·색이 박혀서 온다 — 이미 받아 둔 월 일정도 함께 무효화한다
      ref.invalidate(monthEventsProvider);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException {
      if (!mounted) return;
      setState(() => _saveError = l.calLabelSaveFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final edit = _edit!;
    final sheet = PBottomSheet.of(context);
    final ok = await _confirmDelete(
      context,
      edit,
      onRetried: () => sheet.close(),
    );
    if (ok && mounted) sheet.close();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final isEdit = _edit != null;
    final save = dsb.PButton(
      label: isEdit ? l.actionSave : l.calAdd,
      size: dsb.PButtonSize.large,
      loading: _submitting,
      onPressed: _submitting ? null : _submit,
    );
    return PBottomSheetContent(
      title: isEdit ? l.calEditLabel : l.calNewLabel,
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
            // 이름은 12자까지 — 세는 줄 "n/12", 입력은 12 에서 멈춘다. 12자 넘는 옛 이름은 "13/12" 로 보인다
            child: PField(
              // 입력 상한은 저장된 이름 길이와 12 중 큰 값(긴 옛 이름에 글자를 더해도 안 잘린다), 세는 줄 분모는 규칙 12
              maxGraphemeCount: math.max(
                _initialName.characters.length,
                kLabelNameMax,
              ),
              counterMax: kLabelNameMax,
              invalid: _nameError != null,
              errorMessage: _nameError,
              child: PInput(
                controller: _nameCtrl,
                focusNode: widget.nameFocus,
                semanticLabel: l.calFieldName,
                placeholder: l.calLabelNamePlaceholder,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          PList(
            semanticLabel: isEdit ? l.calEditLabel : l.calNewLabel,
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
      footer: isEdit ? const [] : [save],
      footerRow: isEdit
          ? Row(
              spacing: PSpacing.x2,
              children: [
                // 내용 폭 ghost critical — 안쪽 여백 20 을 바깥으로 내어 글이 화면 여백 24 에 선다
                Transform.translate(
                  offset: const Offset(-20, 0),
                  child: dsb.PButton(
                    label: l.actionDelete,
                    variant: dsb.PButtonVariant.ghost,
                    ghostColor: dsb.PButtonGhostColor.critical,
                    size: dsb.PButtonSize.large,
                    onPressed: _submitting ? null : _delete,
                  ),
                ),
                Expanded(child: save),
              ],
            )
          : null,
    );
  }
}

// ─── 삭제 ──────────────────────────────────────────────────

/// 라벨 삭제 — 확인창 → 지움. 실패하면 확인창을 닫고 고정 한 문장 critical 스낵바 + [다시 시도](묻지 않고 바로 지움).
/// 돌려주는 값 — 지우기까지 성공했으면 true. 밀기 삭제와 편집 시트 바닥 [삭제] 가 같은 길을 쓴다.
Future<bool> _confirmDelete(
  BuildContext context,
  EventLabel label, {
  VoidCallback? onRetried,
}) {
  final l = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  return askConfirmThenRequest(
    context,
    title: l.calDeleteLabelTitle,
    description: l.calDeleteLabelConfirm(label.labelName),
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    request: () => _deleteLabelRequest(container, label),
    failedMessage: l.calLabelDeleteFailed,
    retryLabel: l.actionRetry,
    onRetried: onRetried,
  );
}

/// 라벨 삭제 요청 — 컨테이너로 한다(시트가 닫힌 뒤 [다시 시도] 도 이걸 부른다). 실패는 던진다.
Future<void> _deleteLabelRequest(
  ProviderContainer container,
  EventLabel label,
) async {
  final repo = await container.read(calendarRepositoryProvider.future);
  await repo.deleteLabel(label.rowId);
  container.invalidate(eventLabelsProvider);
  // 지운 라벨이 박힌 일정도 다시 받는다 — 안 그러면 없는 라벨이 계속 붙어 보인다.
  container.invalidate(monthEventsProvider);
}
