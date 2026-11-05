import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/shared/widgets/p_color_picker.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_swipe_actions.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_surface_parts.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/forms/name_policy.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as dsb;
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 라벨 이름 최대 글자 수 — 카테고리 · 라벨 · 태그 · 목표 이름 12자(웹 d837eedc, 카드 한 줄에 들어가는 길이).
const int kLabelNameMax = 12;

/// 저장할 수 있는 이름인가 — 비어 있지 않고 12자를 넘지 않는다(웹 `nameIssue` 와 같은 판정).
///
/// [original] 은 고치기 전 저장된 이름 — 안 바꾼 옛 이름은 12자 검사에서 뺀다(프리셋과 같다: 12자가 넘는 옛 라벨도 색만 고칠 수
/// 있어야 한다). 이름을 고치기 시작하면 그때부터 12 검사.
bool labelNameSubmittable(String raw, {String? original}) {
  final issue = nameIssue(raw, kLabelNameMax);
  if (issue == NameIssue.tooLong && raw == original) return true;
  return issue == null || issue == NameIssue.duplicate;
}

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

void _showLabelEditor(
  BuildContext context,
  WidgetRef ref,
  EventLabel? existing,
) {
  final l = AppLocalizations.of(context);
  final nameCtrl = TextEditingController(text: existing?.labelName ?? '');
  final controller = PSheetController();
  controller.setCanSubmit(
    labelNameSubmittable(
      existing?.labelName ?? '',
      original: existing?.labelName,
    ),
  );
  String selectedColor = existing?.color ?? '#2c70bf';

  Future<void> submit() async {
    final name = nameCtrl.text.trim();
    if (!labelNameSubmittable(name, original: existing?.labelName)) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      if (existing == null) {
        await repo.createLabel(labelName: name, color: selectedColor);
      } else {
        await repo.updateLabel(
          id: existing.rowId,
          labelName: name,
          color: selectedColor,
        );
      }
      ref.invalidate(eventLabelsProvider);
      // 일정 응답에 라벨 이름·색이 박혀서 온다(CalendarEvent.labelName/labelColor).
      // 라벨을 고치면 이미 받아 둔 월 일정은 옛 이름·옛 색을 그대로 들고 있으므로
      // 함께 무효화한다 — family 는 base 를 넘기면 모든 달이 무효화된다.
      ref.invalidate(monthEventsProvider);
      if (!context.mounted) return;
      // 시트는 root navigator 소속(p_modal useRootNavigator) — root 명시.
      Navigator.of(context, rootNavigator: true).pop();
    } on ApiException {
      if (!context.mounted) return;
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: existing == null ? l.calNewLabel : l.calEditLabel,
    // content 높이에 맞춰 렌더 — 짧은 폼이 85% 고정 높이로 뜨지 않게.
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _LabelEditorBody(
      nameController: nameCtrl,
      initialColor: selectedColor,
      originalName: existing?.labelName,
      controller: controller,
      onColorChanged: (c) => selectedColor = c,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.actionSave,
      // 수정 폼에만 — 밀기로만 닿던 삭제가 들어간 화면에도 있다(swipe-actions.md:76).
      // 09b-2 가 라벨 폼을 새로 짤 때 이 [삭제] 를 옮긴다.
      leftSlotCompact: true,
      leftSlot: existing == null
          ? null
          // 내용 폭 ghost critical — 왼쪽 안쪽 여백 20 을 바깥으로 내어 글이 화면 여백 24 에 선다
          : Transform.translate(
              offset: const Offset(-20, 0),
              child: dsb.PButton(
                label: l.actionDelete,
                variant: dsb.PButtonVariant.ghost,
                ghostColor: dsb.PButtonGhostColor.critical,
                size: dsb.PButtonSize.large,
                onPressed: () async {
                  final ok = await _confirmDelete(
                    ctx,
                    existing,
                    onRetried: () {
                      if (ctx.mounted) {
                        Navigator.of(ctx, rootNavigator: true).pop();
                      }
                    },
                  );
                  if (ok && ctx.mounted) {
                    Navigator.of(ctx, rootNavigator: true).pop();
                  }
                },
              ),
            ),
    ),
  );
}

class _LabelEditorBody extends StatefulWidget {
  const _LabelEditorBody({
    required this.nameController,
    required this.initialColor,
    this.originalName,
    required this.controller,
    required this.onColorChanged,
  });
  final TextEditingController nameController;
  final String initialColor;

  /// 고치기 전 저장된 이름(추가 폼은 null) — 안 바꾼 옛 이름은 12자 오류를 보이지 않는다.
  final String? originalName;
  final PSheetController controller;
  final ValueChanged<String> onColorChanged;

  @override
  State<_LabelEditorBody> createState() => _LabelEditorBodyState();
}

class _LabelEditorBodyState extends State<_LabelEditorBody> {
  late String _color;

  bool get _nameTooLong =>
      nameIssue(widget.nameController.text, kLabelNameMax) == NameIssue.tooLong;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final swatch = solidSwatchColor(context, _color, fallback: t.fgBrand);
    final preview = widget.nameController.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 미리보기
          Container(
            padding: const EdgeInsets.all(PSpace.x16),
            decoration: BoxDecoration(
              color: softBg(context, swatch),
              borderRadius: PRadius.brMd,
            ),
            child: Row(
              children: [
                // 웹 정합 — 40 radius-md 타일 + tag 아이콘 (원형 아님).
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: PRadius.brMd,
                  ),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.tag, size: 18, color: t.fgOnBrand),
                ),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.calPreview,
                        // 웹 badge(11)/600 정합 — 색은 중립(tertiary) 유지.
                        style: PTypo.micro.copyWith(
                          color: t.fgTertiary,
                          fontWeight: PFontWeight.semi,
                          letterSpacing: 0.22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview.isEmpty ? l.calNewLabel : preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // 웹 body-lg(16)/700 정합 — 색은 중립(primary) 유지.
                        style: PTypo.bodyLg.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 이름
          Text(
            l.calFieldName,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x4),
          // 이름은 12자까지 — 카드 한 줄에 들어가는 길이(웹과 같은 제품 규칙). 세는 줄 "n/12", 입력은 12 에서 멈춘다
          PField(
            maxGraphemeCount: kLabelNameMax,
            invalid: _nameTooLong,
            errorMessage: _nameTooLong ? l.nameTooLong(kLabelNameMax) : null,
            child: PInput(
              controller: widget.nameController,
              semanticLabel: l.calFieldName,
              placeholder: l.calLabelNamePlaceholder,
              onChanged: (v) {
                widget.controller.setCanSubmit(
                  labelNameSubmittable(v, original: widget.originalName),
                );
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 색상
          Text(
            l.calFieldColor,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x8),
          PColorPicker(
            selected: _color,
            onChanged: (hex) {
              setState(() => _color = hex);
              widget.onColorChanged(hex);
            },
          ),
        ],
      ),
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
