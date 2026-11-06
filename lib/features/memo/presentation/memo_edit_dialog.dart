import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_colors.dart';
import 'package:groo_damda_app/features/memo/domain/memo_meta.dart';
import 'package:groo_damda_app/features/memo/domain/memo_tag.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/forms/color_pick.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/forms/utf16_limit.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 제목 · 본문 입력 상한 — 서버 `FieldLimits`(TITLE_MAX 200 · CONTENT_MAX 10,000)와 같은 값.
const int kMemoTitleMax = 200;
const int kMemoContentMax = 10000;

/// 메모 추가 · 수정 폼(I-15 13) — 줄 칸 폼: ds Bottom Sheet 입력 폼. 제목 Input large → 내용 Textarea(3줄에서 자라고 시트 안 최대 높이 =
/// 화면 높이의 32%) → 선 → List 줄 [태그 · 색상 · 상단에 고정 스위치]. 태그 · 색 줄은 꺾쇠 없이 값 글만, 누르면 고르기 시트이고 고르면 바로
/// 넣고 닫힌다. 바닥은 [저장] 하나. [저장] 은 켜 두고 누를 때 제목이 비면 칸 아래 오류 + 초점. 값이 바뀐 채 닫으면 "작성한 내용이 사라져요" 를
/// 묻고 바깥 누름 · 끌어내림으로는 닫히지 않는다. 저장이 실패하면 시트 맨 위 Callout(고정 글) — 시트는 열려 있고 쓴 값은 그대로다.
void showMemoEditDialog(BuildContext context, {Memo? edit}) {
  final l = AppLocalizations.of(context);
  final probe = _DirtyProbe();
  PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _MemoForm(edit: edit, probe: probe),
  );
}

/// 저장에 쓰는 값 — 폼이 닫힌 뒤 다시 시도할 때도 같은 값을 쓴다.
class _SaveArgs {
  const _SaveArgs({
    required this.editId,
    required this.title,
    required this.content,
    required this.tag,
    required this.color,
    required this.pinChanged,
  });
  final int? editId;
  final String title;
  final String content;
  final String? tag;
  final String color;
  final bool pinChanged;
}

/// 서버에 쓰고 목록 · 홈 · 별자리를 다시 받는다 — 폼과 상관없는 요청이라 컨테이너만 쓴다. 던지면 실패다.
Future<Memo> _saveMemo(ProviderContainer c, _SaveArgs a) async {
  final repo = await c.read(memoRepositoryProvider.future);
  final Memo saved;
  if (a.editId != null) {
    saved = await repo.update(
      id: a.editId!,
      title: a.title,
      // 본문을 지우고 저장하면 지워져야 한다 — 키를 빼면 서버가 옛 본문을 지킨다.
      content: Patch.set(a.content),
      // "태그 없음" 은 키를 빼지 말고 명시적 null 로 실어야 서버가 지운다(QA #99). sentinel 은 서버로 안 나간다.
      tag: Patch.set(a.tag),
      color: a.color,
    );
  } else {
    saved = await repo.create(
      title: a.title,
      content: a.content,
      tag: a.tag,
      color: a.color,
    );
  }
  c.invalidate(memoListProvider);
  // 홈 위젯(메모 개수·최근 메모)의 원본 — 셸 상주라 스스로 안 받는다.
  c.invalidate(dashboardSummaryProvider);
  // 별자리 게이미피케이션 — 메모 작성 별빛(+1, 일 2회) 반영
  c
    ..invalidate(constellationTodayProvider)
    ..invalidate(constellationSkyProvider)
    ..invalidate(constellationCollectionProvider);
  // 목록을 다시 받은 뒤에 끝낸다 — 받기 전에 시트를 닫으면 옛 값이 잠깐 비친다
  try {
    await c.read(memoListProvider.future);
  } on Object {
    // 저장은 끝났다 — 화면은 보던 목록을 그대로 둔다
  }
  return saved;
}

class _DirtyProbe {
  bool Function() dirty = () => false;
}

class _MemoForm extends ConsumerStatefulWidget {
  const _MemoForm({this.edit, required this.probe});
  final Memo? edit;
  final _DirtyProbe probe;

  @override
  ConsumerState<_MemoForm> createState() => _MemoFormState();
}

class _MemoFormState extends ConsumerState<_MemoForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  final _titleFocus = FocusNode();

  late final String _initialTitle;
  late final String _initialContent;
  late final String _initialTag;
  late final bool _initialPinned;
  late final String _initialColor;

  /// 고른 태그 — [kMemoNoTagKey] 면 태그 없음. 목록은 서버 마스터가 SoT 라 앱이 이름을 지어내지 않는다(QA #98).
  late String _tag;
  late bool _pinned;

  /// 저장할 색 — 팔레트 색이면 그 색의 저장 hex, 팔레트 밖이면 저장된 값 그대로(고르지 않으면 바꾸지 않는다).
  late String _color;
  String? _foreignColor;

  bool _submitting = false;
  bool _titleError = false;
  bool _saveError = false;

  /// 실패한 저장의 오류 — 응답을 읽지 못한 쓰기(PARSE)면 실패가 아니라 "저장됐는지 확인하지 못했어요"(검수 M3).
  Object? _failure;
  final _errorKey = GlobalKey();
  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _initialTitle = e?.title ?? '';
    _initialContent = e?.content ?? '';
    // 있는 메모는 지금 태그(없으면 '태그 없음'), 새 메모도 '태그 없음' — 태그를 몰래 붙이지 않는다
    _initialTag = e == null ? kMemoNoTagKey : memoTagKey(e);
    _initialPinned = e?.pinned ?? false;
    _initialColor = memoColorOrDefault(e?.color);
    _titleCtrl = TextEditingController(text: _initialTitle);
    _contentCtrl = TextEditingController(text: _initialContent);
    _tag = _initialTag;
    _pinned = _initialPinned;
    _color = _initialColor;
    if (chartColorOfHex(_color) == null) _foreignColor = _color;
    widget.probe.dirty = () =>
        _titleCtrl.text != _initialTitle ||
        _contentCtrl.text != _initialContent ||
        _tag != _initialTag ||
        _pinned != _initialPinned ||
        _color != _initialColor;
  }

  @override
  void dispose() {
    widget.probe.dirty = () => false;
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// 태그 선택지 — 서버 마스터 목록 + 지금 값(목록에 없으면 맨 앞에 보존). 둘 다 비어도 "태그 없음" 은 늘 앞에 붙는다.
  /// (웹의 "다른 메모에만 남은 이름" 은 더하지 않는다 — 지시서 13 4 의 선택지 그대로)
  List<String> _tagChoices(List<MemoTag> server) {
    final names = [for (final t in server) t.tagName];
    final current = _tag;
    return [
      if (current != kMemoNoTagKey && !names.contains(current)) current,
      ...names,
    ];
  }

  Future<void> _pickTag() async {
    FocusScope.of(context).unfocus();
    final picked = await PBottomSheet.show<String>(
      context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        final c = sheetContext.colors;
        return PBottomSheetContent(
          title: l.memoFieldTag,
          closeLabel: l.actionClose,
          flushBody: true,
          // 태그 수는 사용자 데이터라 늘어나는 목록 — 끝 흐림을 건다(spec-cleanup-pending: 개수가 데이터에 따라 느는 목록)
          scrollFog: true,
          // 목록이 시트를 연 뒤에 도착해도 바뀐다(스냅숏이 아니다)
          body: Consumer(
            builder: (context, ref, _) {
              final tags = ref.watch(memoTagListProvider);
              final choices = _tagChoices(tags.value ?? const <MemoTag>[]);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PickList<String>(
                    label: l.memoFieldTag,
                    selected: _tag,
                    items: [
                      // "{칸 이름} 없음" 을 맨 앞에
                      PickItem(value: kMemoNoTagKey, title: l.memoTagNone),
                      for (final name in choices)
                        PickItem(value: name, title: name),
                    ],
                  ),
                  // 태그가 0개로 **확인됐을 때만** 어디서 만드는지 알린다(불러오는 중 · 실패에는 "없다" 고 말하지 않는다 — 이름을 지어 넣지 않는다 QA #105)
                  if (tags.hasValue && choices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        PSpacing.globalGutter,
                        PSpacing.x4,
                        PSpacing.globalGutter,
                        PSpacing.x2,
                      ),
                      child: Text(
                        l.memoTagEmptyHint,
                        textAlign: TextAlign.center,
                        style: PTypography.t4.copyWith(
                          color: c.fgNeutralSubtle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _tag = picked);
  }

  Future<void> _pickColor() async {
    FocusScope.of(context).unfocus();
    final picked = await showColorPickSheet(
      context,
      title: AppLocalizations.of(context).memoFieldColor,
      hex: _color,
      foreignHex: _foreignColor,
    );
    if (picked == null || !mounted) return;
    setState(() => _color = picked);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      _titleFocus.requestFocus();
      return;
    }
    // 본문은 trim 하지 않는다(들여쓰기 · 빈 줄도 사용자 글) — 웹과 같다. 비었으면 ""(서버는 "" 도 null 도 지운 것으로 읽는다)
    final content = _contentCtrl.text;
    // 요청이 끝나기 전에 시트가 닫혀도 목록을 비울 수 있게 미리 잡아 둔다(`ref` 는 unmount 뒤에 던진다)
    final c = ProviderScope.containerOf(context, listen: false);
    final snack = PSnackbar.maybeOf(context);
    final l = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _saveError = false;
    });
    final args = _SaveArgs(
      editId: widget.edit?.rowId,
      title: title,
      content: content,
      tag: _tag == kMemoNoTagKey ? null : _tag,
      color: _color,
      // 고정은 저장 본문에 칸이 없고 토글 하나로만 바뀐다 — 폼의 '상단에 고정' 이 지금과 다르면 저장 뒤 한 번 더 부른다(QA 30 8)
      pinChanged: (widget.edit?.pinned ?? false) != _pinned,
    );
    Memo saved;
    final sheet = PBottomSheet.maybeOf(context)?..setBusy(true);
    try {
      saved = await _saveMemo(c, args);
    } catch (e) {
      // 응답만 못 읽었다(서버는 저장했다) — 성공 때와 같은 목록을 비운다(검수 M3)
      if (isUnconfirmedSave(e)) {
        c
          ..invalidate(memoListProvider)
          ..invalidate(dashboardSummaryProvider)
          ..invalidate(constellationTodayProvider)
          ..invalidate(constellationSkyProvider)
          ..invalidate(constellationCollectionProvider);
      }
      if (!mounted) {
        // 저장 중에 시트를 닫았다 — 실패 Callout 을 둘 자리가 없으니 스낵바 + [다시 시도] 로 알린다(L8 · N4)
        _retrySnack(c, snack, l, args);
        return;
      }
      setState(() {
        _saveError = true;
        _failure = e;
        _submitting = false;
      });
      // 키보드 · 큰 글자로 맨 위 Callout 이 화면 밖이면 올린다(M2)
      revealFormError(_errorKey);
      return;
    } finally {
      sheet?.setBusy(false);
    }
    if (mounted) PBottomSheet.of(context).close();
    if (args.pinChanged) {
      await memoActions.pinDetached(c, snack, l, saved);
    }
  }

  /// 닫힌 폼의 저장 실패 — 스낵바 + [다시 시도]. 다시 시도는 **폼을 건드리지 않고** 쓴 값 그대로 바로 요청한다(컨테이너 · 호스트 · 글을 미리 잡아
  /// 둔다). 성공 · 실패 모두 스낵바로 알린다 — 그새 연 다른 폼이 닫히거나 Callout 이 그 위에 뜨지 않는다(N2).
  static void _retrySnack(
    ProviderContainer c,
    PSnackbarApi? snack,
    AppLocalizations l,
    _SaveArgs args,
  ) {
    snack?.show(
      message: l.memoSaveFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () async {
          try {
            final saved = await _saveMemo(c, args);
            snack.show(message: l.memoSaved, tone: PSnackbarTone.positive);
            if (args.pinChanged) {
              await memoActions.pinDetached(c, snack, l, saved);
            }
          } catch (_) {
            _retrySnack(c, snack, l, args);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final colorSwatch = resolveChartColor(context, _color, fallback: c.fgBrand);
    // 시트 안 내용 칸 최대 높이 — 화면 높이의 32%(웹 `32dvh`), 칸의 최소 최대값(3줄 94) 아래로는 내리지 않는다
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.32).clamp(
      94.0,
      double.infinity,
    );
    return PBottomSheetContent(
      title: _isEdit ? l.memoEditTitle : l.memoNew,
      closeLabel: l.actionClose,
      flushBody: true,
      // 끝 흐림은 390 × 844 보통 값에서 본문이 시트 90%(759.6)에 닿을 때만 건다 — 이 폼은 10,000자여도 653(내용 칸 최대 32%)이라 걸지 않는다
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
                message: saveFailureText(l, _failure, l.memoSaveFailed),
              ),
            ),
          // 제목 — Input large. 위 12 · 좌우 24 · 아래 8
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x3,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: PField(
              required: true,
              invalid: _titleError,
              errorMessage: _titleError ? l.memoTitleRequired : null,
              child: PInput(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                autofocus: !_isEdit,
                semanticLabel: l.memoFieldTitle,
                placeholder: l.memoFieldTitle,
                // 서버가 세는 단위(UTF-16)로 막는다 — 이모지로 한도를 넘겨 400 이 나지 않게(M6)
                inputFormatters: const [
                  Utf16LengthLimitingFormatter(kMemoTitleMax),
                ],
                onChanged: (_) {
                  if (_titleError) setState(() => _titleError = false);
                },
              ),
            ),
          ),
          // 내용 — Textarea 자동 높이(3줄에서 시작해 자란다)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            // 최대 길이가 있으면 글자 수를 붙인다(textarea.md:60 · :139) — 초과 붙여넣기는 잘리고 "10,000/10,000" 으로 보인다.
            // 자르는 단위는 서버(UTF-16)다 — 이모지로 한도를 넘기지 못한다(M6)
            child: PField(
              maxGraphemeCount: kMemoContentMax,
              child: PTextarea(
                controller: _contentCtrl,
                semanticLabel: l.memoFieldContent,
                placeholder: l.memoContentPlaceholder,
                maxHeight: maxHeight,
                inputFormatters: const [
                  Utf16LengthLimitingFormatter(kMemoContentMax),
                ],
              ),
            ),
          ),
          // 한 면 안에서 묶음이 바뀐다 — 끝까지 선 1px, 위 8 · 아래 0
          const SizedBox(height: PSpacing.x2),
          Container(height: 1, color: c.strokeNeutralSubtle),
          PList(
            children: [
              PickerRow(
                title: l.memoFieldTag,
                prefix: const Icon(LucideIcons.tag, size: 22),
                value: _tag == kMemoNoTagKey ? l.memoTagNone : _tag,
                onTap: _pickTag,
              ),
              PickerRow(
                title: l.memoFieldColor,
                prefix: const Icon(LucideIcons.palette, size: 22),
                value: colorPickName(context, _color),
                leading: PickerDot(size: 12, color: colorSwatch),
                onTap: _pickColor,
              ),
              PListSwitchItem(
                title: l.memoPinToTop,
                prefix: const Icon(LucideIcons.pin, size: 22),
                checked: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
              ),
            ],
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
