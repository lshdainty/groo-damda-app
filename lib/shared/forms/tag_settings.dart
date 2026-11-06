import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/color_swatch/p_color_swatch.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/core/format/color_parse.dart';
import 'package:groo_damda_app/shared/forms/color_pick.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/name_policy.dart';

/// 태그 설정 본문 — 메모 태그 · 할 일 태그가 한 부품을 쓴다(I-15 20 ~ 24 · I-10 33 ~ 37 · Q4 B). 웹 `TagSettings` 와 같은 짜임이다.
/// 글은 [TagSettingsCopy] 로 받는다 — 키만 다르고 구조는 같다.
///
/// 흰 면 하나 — 안내 Callout(informative · 제목 없음) → 목록 제목 "… 태그 · N" + 글 버튼 "태그 추가" → 색 타일 40 줄.
/// 줄 누름 = 수정 시트, 밀기 = [수정, 삭제]. 줄 끝 ⋮ 는 두지 않는다(좁은 목록 줄 — 10-25).
///
/// 실패 안내는 서버 원문이 아니라 고정 글이다(부르는 쪽 요청은 전역 오류 알림을 끈다) — 저장 실패는 시트 안 Callout,
/// 삭제 실패는 확인창을 닫고 critical 스낵바 + [다시 시도]. 저장 · 삭제는 목록을 다시 받은 뒤에 끝나야 한다(부르는 쪽 몫).
class TagItem {
  const TagItem({
    required this.rowId,
    required this.name,
    required this.color,
    required this.usageCount,
  });
  final int rowId;
  final String name;
  final String? color;
  final int usageCount;
}

/// 한 화면의 글 모음 — 메모 / 할 일이 각자 [AppLocalizations] 에서 채운다.
class TagSettingsCopy {
  const TagSettingsCopy({
    required this.title,
    required this.desc,
    required this.addCta,
    required this.emptyTitle,
    required this.emptyHint,
    required this.loadFailedTitle,
    required this.loadFailedDesc,
    required this.usage,
    required this.deleteTitle,
    required this.deleteConfirm,
    required this.saveFailed,
    required this.deleteFailed,
    required this.editTitle,
    required this.newPlaceholder,
    required this.namePlaceholder,
  });

  final String title;
  final String desc;

  /// 목록 제목 오른쪽 글 버튼 · 새 태그 폼 제목 · 빈 이름 자리 글 — "태그 추가".
  final String addCta;
  final String emptyTitle;

  /// "'태그 추가' 버튼으로 첫 태그를 만들어보세요." — 버튼 이름을 따옴표로 감싸 받는다.
  final String Function(String label) emptyHint;
  final String loadFailedTitle;
  final String loadFailedDesc;
  final String Function(int count) usage;
  final String deleteTitle;
  final String Function(String name, int count) deleteConfirm;
  final String saveFailed;
  final String deleteFailed;
  final String editTitle;

  /// 미리보기에서 이름을 아직 안 쳤을 때 보이는 글.
  final String newPlaceholder;
  final String namePlaceholder;
}

const int kTagNameMax = 12;

class TagSettings extends StatefulWidget {
  const TagSettings({
    super.key,
    required this.copy,
    required this.tags,
    required this.failed,
    required this.onRetry,
    this.retrying = false,
    required this.create,
    required this.update,
    required this.remove,
    this.bodyKey,
    this.controller,
  });

  final TagSettingsCopy copy;

  /// null 이면 불러오는 중. [failed] 면 실패 상자.
  final List<TagItem>? tags;
  final bool failed;
  final VoidCallback onRetry;

  /// 실패 뒤 다시 받는 중 — [다시 시도] 에 진행 원.
  final bool retrying;

  /// 만든다 · 고친다 · 지운다 — 던지면 실패다. 목록을 다시 받은 뒤에 끝나야 한다.
  final Future<void> Function(String name, String color) create;
  final Future<void> Function(int id, String name, String color) update;
  final Future<void> Function(int id) remove;

  final Key? bodyKey;
  final ScrollController? controller;

  @override
  State<TagSettings> createState() => _TagSettingsState();
}

class _TagSettingsState extends State<TagSettings> {
  bool _busy = false;

  Future<void> _openEdit(TagItem? tag) async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.maybeOf(context);
    final outcome = await showTagEditSheet(
      snack: snack,
      context,
      copy: widget.copy,
      tag: tag,
      existing: widget.tags ?? const [],
      onSave: (name, color) async {
        if (tag == null) {
          await widget.create(name, color);
        } else {
          await widget.update(tag.rowId, name, color);
        }
      },
    );
    if (outcome == TagEditOutcome.deleteRequested && tag != null && mounted) {
      await _confirmDelete(tag, snack, l);
    }
  }

  /// 삭제 — 확인은 한 번만 묻는다(밀기 · 수정 시트의 [삭제] 둘 다 이 길이다). 실패하면 확인창을 닫고 스낵바 + [다시 시도].
  Future<void> _confirmDelete(
    TagItem tag, [
    PSnackbarApi? snackApi,
    AppLocalizations? loc,
  ]) async {
    if (_busy) return;
    final l = loc ?? AppLocalizations.of(context);
    final snack = snackApi ?? PSnackbar.maybeOf(context);
    Object? failure;
    setState(() => _busy = true);
    final ok = await PAlertDialog.show(
      context,
      title: widget.copy.deleteTitle,
      description: widget.copy.deleteConfirm(tag.name, tag.usageCount),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
      onAction: () async {
        try {
          await widget.remove(tag.rowId);
        } catch (e) {
          failure = e;
        }
      },
    );
    if (mounted) setState(() => _busy = false);
    if (ok && failure != null) _failedSnack(snack, l, tag);
  }

  void _failedSnack(PSnackbarApi? snack, AppLocalizations l, TagItem tag) {
    snack?.show(
      message: widget.copy.deleteFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        // 묻지 않고 같은 삭제를 바로 — 이미 확인창에서 한 번 확정했다
        onPressed: () async {
          try {
            await widget.remove(tag.rowId);
          } catch (_) {
            _failedSnack(snack, l, tag);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final copy = widget.copy;
    final tags = widget.tags;

    // 목록 제목의 동작은 정적 UI 라 불러오는 동안에도 진짜를 쓴다 — 수만 기다린다.
    final header = PListHeader(
      // 불러오는 동안에도 버튼은 진짜, 수 자리만 Skeleton(웹 TagSettings 와 같다 — 실패에서는 수를 비운다)
      title: tags == null
          ? (widget.failed ? copy.title : '${copy.title} · ')
          : '${copy.title} · ${tags.length}',
      titleSuffix: tags == null && !widget.failed
          ? PSkeleton.text(PTypography.t4, width: PSpacing.x4)
          : null,
      variant: PListHeaderVariant.boldSolid,
      action: PTextButton(
        label: copy.addCta,
        onPressed: _busy ? null : () => _openEdit(null),
      ),
    );

    final List<Widget> body;
    if (widget.failed) {
      body = [
        header,
        // 질의 하나 = 실패 상자 하나 — 원문을 그리지 않는다.
        PResultSection(
          kind: PResultKind.failure,
          size: PResultSize.medium,
          title: copy.loadFailedTitle,
          description: copy.loadFailedDesc,
          primaryAction: PResultAction(
            label: l.actionRetry,
            loading: widget.retrying,
            onPressed: widget.onRetry,
          ),
        ),
      ];
    } else if (tags == null) {
      body = [header, for (var i = 0; i < 4; i++) const _TagRowSkeleton()];
    } else if (tags.isEmpty) {
      body = [
        header,
        PResultSection(
          size: PResultSize.medium,
          icon: LucideIcons.tags,
          title: copy.emptyTitle,
          description: copy.emptyHint('"${copy.addCta}"'),
        ),
      ];
    } else {
      body = [
        header,
        PList(
          semanticLabel: copy.title,
          children: [
            for (final tag in tags)
              // 밀면 수정·삭제 — 손가락 지름길이다. 줄을 누르면 수정 시트로 들어가고 거기에 [삭제] 가 있다(WCAG 2.1.1).
              PSwipeActions(
                key: ValueKey('tag-${tag.rowId}'),
                enabled: !_busy,
                rowLabel: tag.name,
                actions: [
                  PSwipeAction(
                    label: l.actionEdit,
                    icon: LucideIcons.pencil,
                    kind: PSwipeActionKind.primary,
                    onSelect: () => _openEdit(tag),
                  ),
                  PSwipeAction(
                    label: l.actionDelete,
                    icon: LucideIcons.trash2,
                    kind: PSwipeActionKind.destructive,
                    // _confirmDelete 가 자체 확인을 띄운다 — 여기서 또 주면 두 번 뜬다.
                    onSelect: () => _confirmDelete(tag),
                  ),
                ],
                child: _TagRow(
                  tag: tag,
                  usage: copy.usage(tag.usageCount),
                  busy: _busy,
                  onTap: () => _openEdit(tag),
                ),
              ),
          ],
        ),
      ];
    }

    return PSwipeActionsProvider(
      child: ListView(
        key: widget.bodyKey,
        controller: widget.controller,
        padding: const EdgeInsets.only(bottom: PSpacing.screenBottom),
        children: [
          // 안내 — Callout informative(흰 면 위 예외) · 제목 없음. 위 16 · 아래 8 · 좌우 24.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x4,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PCallout(
              tone: PCalloutTone.informative,
              description: copy.desc,
            ),
          ),
          // 안내 상자 ↔ 목록 제목: 면 안 8(위 Callout 아래) + 16(T8)
          const SizedBox(height: PSpacing.x4),
          ...body,
        ],
      ),
    );
  }
}

/// 태그 줄 — 앞 타일 40(그 색의 옅은 바탕 + 태그 아이콘) · 이름(줄바꿈) · "N건에 사용 중". 줄 사이 선 없음.
class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.usage,
    required this.busy,
    required this.onTap,
  });
  final TagItem tag;
  final String usage;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = resolveChartColor(context, tag.color, fallback: c.fgBrand);
    return PListButtonItem(
      title: tag.name,
      detail: usage,
      onTap: busy ? null : onTap,
      prefix: PListTile(
        background: softBg(context, color),
        color: color,
        child: const Icon(LucideIcons.tag),
      ),
    );
  }
}

/// 불러오는 동안의 줄 — 실제 줄과 같은 여백(타일 40 · 제목 t5 · 설명 t3).
class _TagRowSkeleton extends StatelessWidget {
  const _TagRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.globalGutter,
        vertical: PSpacing.x3,
      ),
      child: Row(
        children: [
          const PSkeleton(
            width: PListTile.size,
            height: PListTile.size,
            radius: PSkeletonRadius.r12,
          ),
          const SizedBox(width: PSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x0_5,
              children: [
                PSkeleton.text(PTypography.t5, width: 120),
                PSkeleton.text(PTypography.t3, width: 72),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 태그 편집 시트가 돌려주는 것 — 저장을 마쳤다(시트 안에서 요청까지 끝냈다) 또는 삭제 요청(수정일 때만).
enum TagEditOutcome { saved, deleteRequested }

/// 태그 편집 시트(I-15 23 · I-10 37) — ds Bottom Sheet 입력 폼. 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 묻는다.
/// 미리보기(타일 + 이름) → 이름(필수 · 12자 · 겹침 검사, 글자 수는 칸 아래) → 색상(ds Color Swatch 5 × 2, 칸 이름 = 색 이름).
/// 저장된 색이 팔레트 밖이면 격자 앞 "지금 색" 칸이 골라져 열리고, 고르지 않으면 바꾸지 않는다.
/// 바닥은 새 태그면 [저장] 하나, 수정이면 왼쪽 [삭제] + [저장]. 저장은 시트 안에서 [onSave] 를 기다리고, 던지면 시트 맨 위 Callout
/// (고정 글) — 시트는 열려 있고 쓴 값은 그대로다. 성공하면 닫는다.
Future<TagEditOutcome?> showTagEditSheet(
  BuildContext context, {
  PSnackbarApi? snack,
  required TagSettingsCopy copy,
  TagItem? tag,
  List<TagItem> existing = const [],
  required Future<void> Function(String name, String color) onSave,
}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  return PBottomSheet.show<TagEditOutcome>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _TagEditSheet(
      copy: copy,
      tag: tag,
      existing: existing,
      onSave: onSave,
      probe: probe,
      snack: snack,
    ),
  );
}

class _DirtyProbe {
  bool Function() dirty = () => false;
}

class _TagEditSheet extends StatefulWidget {
  const _TagEditSheet({
    required this.copy,
    required this.tag,
    required this.existing,
    required this.onSave,
    required this.probe,
    this.snack,
  });
  final PSnackbarApi? snack;
  final TagSettingsCopy copy;
  final TagItem? tag;
  final List<TagItem> existing;
  final Future<void> Function(String name, String color) onSave;
  final _DirtyProbe probe;

  @override
  State<_TagEditSheet> createState() => _TagEditSheetState();
}

class _TagEditSheetState extends State<_TagEditSheet> {
  late final TextEditingController _nameCtrl;
  final _nameFocus = FocusNode();
  late final String _initialName;
  late final String _initialColor;
  late String _color;
  bool _touched = false;
  bool _submitting = false;
  bool _saveError = false;
  final _errorKey = GlobalKey();

  /// 저장된 색이 팔레트 밖이면 그 값 — "지금 색" 칸이 격자를 고른 뒤에도 남아 되돌릴 수 있다(color-swatch.md)
  String? _foreignColor;

  NameIssue? get _issue {
    final issue = nameIssue(_nameCtrl.text, kTagNameMax, [
      for (final t in widget.existing)
        if (t.rowId != widget.tag?.rowId) t.name,
    ]);
    // 안 바꾼 옛 이름은 12자 검사에서 뺀다 — 색만 고치려 해도 막히지 않게(고친 이름은 그대로 검사)
    if (issue == NameIssue.tooLong &&
        _isEdit &&
        _nameCtrl.text.trim() == _initialName.trim()) {
      return null;
    }
    return issue;
  }

  String? _errorOf(AppLocalizations l) => !_touched
      ? null
      : switch (_issue) {
          NameIssue.required => l.ttagNameRequired,
          NameIssue.tooLong => l.ttagNameTooLong,
          NameIssue.duplicate => l.ttagNameDuplicate,
          null => null,
        };

  bool get _isEdit => widget.tag != null;

  @override
  void initState() {
    super.initState();
    _initialName = widget.tag?.name ?? '';
    final c = widget.tag?.color;
    // 새 태그는 안 쓴 첫 색 — 늘 빨강으로 시작하지 않는다. 고치는 태그는 저장된 색 그대로(팔레트 밖이어도 바꾸지 않는다)
    _initialColor = (c != null && c.isNotEmpty)
        ? c
        : firstUnusedHex([for (final t in widget.existing) t.color]);
    _nameCtrl = TextEditingController(text: _initialName);
    _color = _initialColor;
    if (chartColorOfHex(_initialColor) == null) {
      _foreignColor = _initialColor;
    }
    widget.probe.dirty = () =>
        _nameCtrl.text != _initialName || _color != _initialColor;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    setState(() => _touched = true);
    if (_issue != null) {
      _nameFocus.requestFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _saveError = false;
    });
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      await widget.onSave(_nameCtrl.text.trim(), _color);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = true;
          _submitting = false;
        });
        // 키보드 · 큰 글자로 맨 위 Callout 이 화면 밖이면 올린다
        revealFormError(_errorKey);
      } else {
        // 저장 중에 시트를 닫았다 — Callout 을 둘 자리가 없으니 스낵바로 알린다
        widget.snack?.show(
          message: widget.copy.saveFailed,
          tone: PSnackbarTone.critical,
        );
      }
      return;
    } finally {
      sheet?.setBusy(false);
    }
    if (!mounted) return;
    PBottomSheet.of(context).close(TagEditOutcome.saved);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final copy = widget.copy;
    final swatch = resolveChartColor(context, _color, fallback: c.fgBrand);
    final preview = _nameCtrl.text.trim();
    final nameError = _errorOf(l);
    final key = chartColorOfHex(_color);
    final save = PButton(
      label: l.actionSave,
      size: PButtonSize.large,
      loading: _submitting,
      onPressed: _submitting ? null : _save,
    );
    return PBottomSheetContent(
      title: _isEdit ? copy.editTitle : copy.addCta,
      closeLabel: l.actionClose,
      // 칸 두셋처럼 늘 들어맞는 본문이라 끝 흐림을 걸지 않는다(bottom-sheet.md)
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x4,
        children: [
          if (_saveError)
            FormErrorCallout(key: _errorKey, message: copy.saveFailed),
          // 미리보기 — 색 타일 + 이름.
          Container(
            padding: const EdgeInsets.all(PSpacing.x3_5),
            decoration: BoxDecoration(
              color: softBg(context, swatch),
              borderRadius: BorderRadius.circular(PRounded.r3),
            ),
            child: Row(
              spacing: PSpacing.x3,
              children: [
                Container(
                  width: PSpacing.x10,
                  height: PSpacing.x10,
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(PRounded.r3),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.tag,
                    size: PSpacing.x5,
                    color: c.staticWhite,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x0_5,
                    children: [
                      Text(
                        l.calPreview,
                        style: PTypography.t2.copyWith(
                          color: c.fgNeutralSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        preview.isEmpty ? copy.addCta : preview,
                        style: PTypography.t5.copyWith(
                          color: c.fgNeutral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PField(
            label: l.ttagNameLabel,
            indicator: PFieldIndicator.required,
            required: true,
            maxGraphemeCount: kTagNameMax,
            invalid: nameError != null,
            errorMessage: nameError,
            child: PInput(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              placeholder: copy.namePlaceholder,
              // 웹처럼 치기 시작하면 바로 검사한다(touched)
              onChanged: (_) => setState(() => _touched = true),
            ),
          ),
          PField(
            label: l.ttagColorLabel,
            child: PColorSwatchGroup(
              value: key == null
                  ? const PColorSwatchValue.current()
                  : PColorSwatchValue.color(key),
              // 팔레트 밖 색을 들고 열었으면 격자를 고른 뒤에도 "지금 색" 칸을 남긴다
              currentColor: _foreignColor == null
                  ? null
                  : parseColor(
                      _foreignColor!,
                      fallback: const Color(0xFF9E9E9E),
                    ),
              onChanged: (v) {
                // "지금 색" 칸을 고르면 저장된 값으로 돌아간다 — 몰래 바꾸지 않는다
                setState(
                  () => _color = v.isCurrent
                      ? (_foreignColor ?? _color)
                      : chartHexOf(v.color!),
                );
              },
            ),
          ),
        ],
      ),
      footer: _isEdit ? const [] : [save],
      footerRow: _isEdit
          ? PFormDeleteFooter(
              deleteLabel: l.actionDelete,
              // 시트를 닫고 확인이 한 번 묻는다 — 쓰던 값은 버려도 되니 묻지 않고 닫는다.
              onDelete: _submitting
                  ? null
                  : () => PBottomSheet.of(
                      context,
                    ).close(TagEditOutcome.deleteRequested),
              save: save,
            )
          : null,
    );
  }
}
