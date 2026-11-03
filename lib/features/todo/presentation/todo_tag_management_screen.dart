import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/domain/todo_tag.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';
import 'package:groo_damda_app/shared/forms/name_policy.dart';
import 'package:groo_damda_app/shared/widgets/p_color_picker.dart';

/// 할 일 태그 관리(I-10 5A) — 설정 하위 풀스크린 화면. **흰 면 하나**: 안내(Callout · 흰 면 위 예외) · 목록 제목 "할 일 태그 · N" +
/// 오른쪽 글 버튼 "태그 추가" · 줄(색 타일 + 이름 + "N건에 사용 중"). 사용 건수는 서버 집계(`usageCount`)다.
///
/// 줄 끝에 ⋮ 를 두지 않는다(사용자 10-25). 줄을 누르면 수정 시트로 들어가고, 거기서 [삭제] 로 지운다(키보드 · 낭독기로도 닿는다).
/// 밀면 [수정, 삭제] 가 나온다(손가락 지름길). 삭제 확인은 한 번만 묻는다.
class TodoTagManagementScreen extends StatefulWidget {
  const TodoTagManagementScreen({super.key});

  @override
  State<TodoTagManagementScreen> createState() =>
      _TodoTagManagementScreenState();
}

class _TodoTagManagementScreenState extends State<TodoTagManagementScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      // 흰 면 하나 — 띠 · 카드 없이 화면 전체가 흰 층이다
      backgroundColor: context.colors.bgLayerDefault,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-16 14)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.ttagTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: _Body(scrollController: _scrollCtrl),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.scrollController});
  final ScrollController scrollController;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  /// 저장·삭제가 끝나기 전에 화면이 닫혀도 목록을 비울 수 있게 미리 잡아 둔다.
  ///
  /// `ref` 는 unmount 뒤에 쓰면 던지고(`_assertNotDisposed`), 그렇다고 `if (mounted)`
  /// 로 막으면 **무효화 자체가 안 일어난다** — [todoTagListProvider] 는 keepAlive,
  /// [todoListProvider] 는 autoDispose 가 아니라 둘 다 화면보다 오래 산다. 서버엔
  /// 들어간 이름이 목록에는 옛 값으로 남아, 포그라운드 복귀 전까지 안 걷힌다.
  /// 컨테이너는 `ProviderScope` 의 것이라 화면 수명과 무관하다(#348·#351 과 같은 방식).
  late ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — keepAlive provider 라 다른 클라이언트 변경 반영 위해 무효화.
    //
    // 여기만 `mounted` 로 막는다. 이건 **화면에 그리기 전에 새로 읽는 것**이지
    // 내가 방금 쓴 값을 걷어 내는 게 아니다 — 화면이 이미 사라졌으면 걷어 낼
    // 헌 값도, 보여 줄 사람도 없다. 그래도 비우면 아무도 안 보는 GET 만 나간다.
    Future.microtask(() {
      if (mounted) ref.invalidate(todoTagListProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  Future<void> _save(TodoTag? origin, String name, String color) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = await _container.read(todoTagRepositoryProvider.future);
      if (origin == null) {
        await repo.create(tagName: name, color: color);
      } else {
        await repo.update(id: origin.rowId, tagName: name, color: color);
      }
      // 저장 도중에 화면을 닫아도 여기까지 온다 — 서버엔 이미 들어갔으므로
      // 목록은 반드시 걷어 낸다. 그래서 `ref` 가 아니라 컨테이너다.
      _container.invalidate(todoTagListProvider);
      // 개명이면 서버가 그 태그를 쓰던 할 일의 `category` 문자열도 함께 옮긴다
      // (`TodoTagServiceImpl.updateTag` → `renameCategory`) — 목록을 안 걷어 내면
      // 돌아갔을 때 태그 묶음 머리글이 옛 이름을 계속 그린다.
      _container.invalidate(todoListProvider);
      if (mounted) setState(() => _busy = false);
    } on ApiException {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  /// 삭제 — 확인은 여기서 한 번만 묻는다(밀기 · 수정 시트의 [삭제] 둘 다 이 길이다).
  Future<void> _delete(TodoTag tag, int usage) async {
    final l = AppLocalizations.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.todoDeleteTagTitle,
      description: l.todoDeleteTagConfirm(tag.tagName, usage),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = await _container.read(todoTagRepositoryProvider.future);
      await repo.delete(tag.rowId);
      _container.invalidate(todoTagListProvider);
      // 삭제는 그 태그를 쓰던 할 일의 `category` 를 비운다(`clearCategory`) —
      // 목록도 다시 읽어야 그 할 일들이 '태그 없음' 으로 묶인다.
      _container.invalidate(todoListProvider);
      if (mounted) setState(() => _busy = false);
    } on ApiException {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _openEdit(TodoTag? tag) async {
    final result = await showTodoTagEditSheet(
      context,
      tag: tag,
      existing: ref.read(todoTagListProvider).value ?? const [],
    );
    switch (result) {
      case TodoTagSaved(:final name, :final color):
        await _save(tag, name, color);
      case TodoTagDeleteRequested():
        if (tag != null && mounted) await _delete(tag, tag.usageCount);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tagsAsync = ref.watch(todoTagListProvider);

    // 목록 제목의 동작은 정적 UI 라 불러오는 동안에도 진짜를 쓴다 — 수만 기다린다.
    Widget header(int? count) => PListHeader(
      title: count == null ? l.ttagTitle : '${l.ttagTitle} · $count',
      variant: PListHeaderVariant.boldSolid,
      action: PTextButton(
        label: l.ttagAddCta,
        onPressed: _busy ? null : () => _openEdit(null),
      ),
    );

    return PSwipeActionsProvider(
      child: ListView(
        key: const ValueKey('todo-tags-body'),
        controller: widget.scrollController,
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
              icon: LucideIcons.tag,
              description: l.ttagDesc,
            ),
          ),
          // 안내 상자 ↔ 목록 제목: 면 안 8(위 Callout 아래) + 16(T6)
          const SizedBox(height: PSpacing.x4),
          ...tagsAsync.when(
            loading: () => [
              header(null),
              for (var i = 0; i < 4; i++) const _TagRowSkeleton(),
            ],
            error: (e, _) => [
              header(null),
              // 질의 하나 = 실패 상자 하나 — 원문을 그리지 않는다.
              PResultSection(
                kind: PResultKind.failure,
                size: PResultSize.medium,
                title: l.todoTagLoadError,
                description: l.tdmLoadFailedDesc,
                primaryAction: PResultAction(
                  label: l.actionRetry,
                  onPressed: () => ref.invalidate(todoTagListProvider),
                ),
              ),
            ],
            data: (tags) => [
              header(tags.length),
              if (tags.isEmpty)
                PResultSection(
                  size: PResultSize.medium,
                  icon: LucideIcons.tags,
                  title: l.ttagEmpty,
                  description: l.ttagEmptyHint("'${l.ttagAddCta}'"),
                )
              else
                PList(
                  semanticLabel: l.ttagTitle,
                  children: [
                    for (final tag in tags)
                      // 밀면 수정·삭제 — 손가락 지름길이다. 줄을 누르면 수정 시트로 들어가고 거기에 [삭제] 가 있다(WCAG 2.1.1).
                      PSwipeActions(
                        key: ValueKey('todo-tag-${tag.rowId}'),
                        enabled: !_busy,
                        rowLabel: tag.tagName,
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
                            // _delete 가 자체 확인을 띄운다 — 여기서 또 주면 두 번 뜬다.
                            onSelect: () => _delete(tag, tag.usageCount),
                          ),
                        ],
                        child: _TagRow(
                          tag: tag,
                          busy: _busy,
                          onTap: () => _openEdit(tag),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 태그 줄 — 앞 타일 40(그 색의 옅은 바탕 + 태그 아이콘) · 이름(줄바꿈) · "N건에 사용 중". 줄 사이 선 없음.
class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag, required this.busy, required this.onTap});
  final TodoTag tag;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final color = resolveChartColor(context, tag.color, fallback: c.fgBrand);
    return PListButtonItem(
      title: tag.tagName,
      detail: l.ttagUsage(tag.usageCount),
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

/// 태그 편집 시트가 돌려주는 것 — 저장(이름 + hex 색) 또는 삭제 요청(수정일 때만).
sealed class TodoTagEditResult {
  const TodoTagEditResult();
}

class TodoTagSaved extends TodoTagEditResult {
  const TodoTagSaved({required this.name, required this.color});
  final String name;
  final String color;
}

/// [삭제] 를 눌렀다 — 시트는 닫히고 확인(Alert Dialog)은 부른 화면이 한 번 묻는다.
class TodoTagDeleteRequested extends TodoTagEditResult {
  const TodoTagDeleteRequested();
}

/// 태그 편집 시트(I-10 37) — ds Bottom Sheet 입력 폼. 바깥 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 묻는다.
/// 미리보기 카드 · 이름 · 색 고르기는 그대로고 표면만 ds 다. 바닥은 새 태그면 [추가] 하나, 수정이면 왼쪽 [삭제] + [저장].
///
/// 이름은 12자까지이고 같은 이름이 있으면 칸 아래에 오류가 선다 — [existing] 은 지금 있는 태그들이다(웹 `TagEditDialog` 와 같은 규칙 · 글).
Future<TodoTagEditResult?> showTodoTagEditSheet(
  BuildContext context, {
  TodoTag? tag,
  List<TodoTag> existing = const [],
}) {
  final l = AppLocalizations.of(context);
  final probe = _TagDirtyProbe();
  return PBottomSheet.show<TodoTagEditResult>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _TagEditSheet(tag: tag, existing: existing, probe: probe),
  );
}

class _TagDirtyProbe {
  bool Function() dirty = () => false;
}

class _TagEditSheet extends StatefulWidget {
  const _TagEditSheet({this.tag, required this.existing, required this.probe});
  final TodoTag? tag;
  final List<TodoTag> existing;
  final _TagDirtyProbe probe;

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

  /// 이름 이름표 길이 상한 — 웹과 같다.
  static const int _nameMax = 12;

  NameIssue? get _issue => nameIssue(_nameCtrl.text, _nameMax, [
    for (final t in widget.existing)
      if (t.rowId != widget.tag?.rowId) t.tagName,
  ]);

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
    _initialName = widget.tag?.tagName ?? '';
    final c = widget.tag?.color;
    _initialColor = (c != null && c.isNotEmpty) ? c : kPDefaultPalette.first;
    _nameCtrl = TextEditingController(text: _initialName);
    _color = _initialColor;
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

  void _save() {
    setState(() => _touched = true);
    if (_issue != null) {
      _nameFocus.requestFocus();
      return;
    }
    PBottomSheet.of(
      context,
    ).close(TodoTagSaved(name: _nameCtrl.text.trim(), color: _color));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final swatch = resolveChartColor(context, _color, fallback: c.fgBrand);
    final preview = _nameCtrl.text.trim();
    final nameError = _errorOf(l);
    final save = PButton(
      label: _isEdit ? l.actionSave : l.calAdd,
      size: PButtonSize.large,
      onPressed: _save,
    );
    return PBottomSheetContent(
      title: _isEdit ? l.ttagEditTitle : l.todoNewTag,
      closeLabel: l.actionClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x4,
        children: [
          // 미리보기 — 캘린더 라벨 편집 카드와 같은 구성(색 타일 + 이름).
          Container(
            padding: const EdgeInsets.all(PSpacing.x4),
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
                    size: PSpacing.x4_5,
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
                        preview.isEmpty ? l.todoNewTag : preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PTypography.t6.copyWith(
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
            maxGraphemeCount: _nameMax,
            invalid: nameError != null,
            errorMessage: nameError,
            child: PInput(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              placeholder: l.todoTagNamePlaceholder,
              // 웹처럼 치기 시작하면 바로 검사한다(touched)
              onChanged: (_) => setState(() => _touched = true),
            ),
          ),
          PField(
            label: l.ttagColorLabel,
            // 공통 색상 선택기 — 캘린더 라벨과 같다(기본 팔레트).
            child: PColorPicker(
              selected: _color,
              onChanged: (v) => setState(() => _color = v),
            ),
          ),
        ],
      ),
      footer: _isEdit ? const [] : [save],
      footerRow: _isEdit
          ? PFormDeleteFooter(
              deleteLabel: l.actionDelete,
              // 시트를 닫고 확인이 한 번 묻는다 — 쓰던 값은 버려도 되니 묻지 않고 닫는다.
              onDelete: () => PBottomSheet.of(
                context,
              ).close(const TodoTagDeleteRequested()),
              save: save,
            )
          : null,
    );
  }
}
