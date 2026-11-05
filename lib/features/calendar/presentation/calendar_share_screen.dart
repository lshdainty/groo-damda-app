import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/p_badge.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_color_picker.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';
import 'package:groo_damda_app/shared/widgets/p_text_input.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_surface_parts.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart' as ds;
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as dsb;
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';

/// 설정 진입 — 캘린더 관리·공유 (user_calendar 기반).
///
/// 개인 캘린더 자체를 공유 단위로: 생성(개인~공유)·이름/색 편집·삭제·공유(초대코드/멤버권한)를
/// 모두 이 화면에서 관리. 소유 = isOwner, 공유받음 = 그 외.
class CalendarShareScreen extends ConsumerStatefulWidget {
  const CalendarShareScreen({super.key});

  @override
  ConsumerState<CalendarShareScreen> createState() =>
      _CalendarShareScreenState();
}

class _CalendarShareScreenState extends ConsumerState<CalendarShareScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — userCalendarList 는 keepAlive 라 다른 클라이언트 변경 반영 위해 무효화.
    Future.microtask(() {
      if (mounted) ref.invalidate(userCalendarListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(userCalendarListProvider);

    return Scaffold(
      backgroundColor: context.colors.bgLayerDefault,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다. 초대 코드 참여(⊕)는 머리에서
      // 걷었다 — 본문 참여 줄이 같은 일을 한다(I-16 14 · 16, Q5-A)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.calManageShareTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      // 흰 면 하나 — 카드 · 줄 사이 선 · 구역 사이 틈이 없다(I-09 37). 줄 · 목록 제목이 제 좌우 24 를 갖는다
      body: PScreenBandBody(
        child: PPullToRefresh(
          onRefresh: () async {
            ref.invalidate(userCalendarListProvider);
            await ref.read(userCalendarListProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: PSpacing.x6),
            children: [
              CalendarSurfaceCallout(l.calShareIntro),
              listAsync.when(
                loading: () => const _ShareSkeleton(),
                error: (e, _) => CalendarSurfaceFailure(
                  title: l.calCalendarLoadError,
                  onRetry: () => ref.invalidate(userCalendarListProvider),
                ),
                data: (calendars) => _CalendarSections(
                  calendars: calendars,
                  onCreate: () => _showCreateDialog(context, ref),
                ),
              ),
              PListHeader(
                title: l.calJoinSectionTitle,
                variant: PListHeaderVariant.boldSolid,
              ),
              PList(
                semanticLabel: l.calJoinSectionTitle,
                children: [
                  PListItem(
                    prefix: _tile(context, 'gray', LucideIcons.link),
                    title: l.calJoinByCode,
                    detail: l.calJoinCardBody,
                    suffix: PListAction(
                      child: dsb.PButton(
                        label: l.calJoin,
                        variant: dsb.PButtonVariant.neutralWeak,
                        size: dsb.PButtonSize.small,
                        onPressed: () => _showJoinDialog(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 앞 타일 40 — 색 키의 옅은 바탕 + 아이콘 20(`chart-{색}-weak` · `chart-{색}`).
Widget _tile(BuildContext context, String key, IconData icon) {
  final tone = chartToneOfKey(context, key);
  return PListTile(background: tone.weak, color: tone.solid, child: Icon(icon));
}

(String, PBadgeVariant, IconData) _roleStyle(AppLocalizations l, String role) =>
    switch (role) {
      'OWNER' => (l.calRoleOwner, PBadgeVariant.outlineInfo, LucideIcons.crown),
      'EDIT' => (
        l.calRoleEditor,
        PBadgeVariant.outlineSuccess,
        LucideIcons.pencil,
      ),
      _ => (l.calRoleViewer, PBadgeVariant.outline, LucideIcons.eye),
    };

class _ShareSkeleton extends StatelessWidget {
  const _ShareSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      CalendarSurfaceHeaderSkeleton(),
      CalendarSurfaceRowSkeleton(),
      CalendarSurfaceRowSkeleton(),
      CalendarSurfaceHeaderSkeleton(),
      CalendarSurfaceRowSkeleton(),
    ],
  );
}

class _CalendarSections extends StatelessWidget {
  const _CalendarSections({required this.calendars, required this.onCreate});
  final List<UserCalendar> calendars;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = calendars.where((c) => c.isOwner).toList();
    final shared = calendars.where((c) => !c.isOwner).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListHeader(
          title: l.calMyCalendarsCount(owned.length),
          variant: PListHeaderVariant.boldSolid,
          action: PTextButton(label: l.calNewCalendar, onPressed: onCreate),
        ),
        _CalendarList(
          title: l.calMyCalendarsCount(owned.length),
          calendars: owned,
          emptyText: l.calNoOwnedCalendars,
        ),
        PListHeader(
          title: l.calSharedCalendarsCount(shared.length),
          variant: PListHeaderVariant.boldSolid,
        ),
        _CalendarList(
          title: l.calSharedCalendarsCount(shared.length),
          calendars: shared,
          emptyText: l.calNoSharedCalendars,
        ),
      ],
    );
  }
}

class _CalendarList extends ConsumerWidget {
  const _CalendarList({
    required this.title,
    required this.calendars,
    required this.emptyText,
  });
  final String title;
  final List<UserCalendar> calendars;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (calendars.isEmpty) return CalendarSurfaceEmptyLine(emptyText);
    final l = AppLocalizations.of(context);
    return PList(
      semanticLabel: title,
      children: [
        for (final cal in calendars)
          // 누르면 지금의 관리 시트가 그대로 열린다(관리 페이지는 09b-2). 화면을 옮기는 줄이 아니라 꺾쇠가 없다
          PListButtonItem(
            key: ValueKey('cal-share-${cal.rowId}'),
            prefix: PListTile(
              background: chartToneOf(context, cal.color).weak,
              color: chartToneOf(context, cal.color).solid,
              child: const Icon(LucideIcons.calendar),
            ),
            title: cal.calendarName,
            titleSuffix: [
              if (cal.isDefault) ds.PBadge(label: l.calDefault),
              if (!cal.isOwner) _roleBadge(l, cal.myRole),
            ],
            detail: cal.memberCount <= 1
                ? l.calOnlyMe
                : l.calMemberCount(cal.memberCount),
            onTap: () => _showManageSheet(context, ref, cal),
          ),
      ],
    );
  }
}

/// 공유받은 캘린더의 권한 배지 — 편집 가능 positive + 연필 · 읽기 전용 informative + 눈(badge.md 예시).
Widget _roleBadge(AppLocalizations l, String role) => switch (role) {
  'EDIT' => ds.PBadge(
    label: l.calRoleEditor,
    variant: ds.PBadgeVariant.outline,
    tone: ds.PBadgeTone.positive,
    prefixIcon: LucideIcons.pencil,
  ),
  'OWNER' => ds.PBadge(
    label: l.calRoleOwner,
    variant: ds.PBadgeVariant.outline,
    tone: ds.PBadgeTone.brand,
    prefixIcon: LucideIcons.crown,
  ),
  _ => ds.PBadge(
    label: l.calRoleViewer,
    variant: ds.PBadgeVariant.outline,
    tone: ds.PBadgeTone.informative,
    prefixIcon: LucideIcons.eye,
  ),
};

// ─── 새 캘린더 만들기 ────────────────────────────────────────

void _showCreateDialog(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final nameCtrl = TextEditingController();
  final controller = PSheetController();
  var selectedColor = '#2c70bf';

  Future<void> submit() async {
    if (nameCtrl.text.trim().isEmpty) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.create(
        calendarName: nameCtrl.text.trim(),
        color: selectedColor,
      );
      ref.invalidate(userCalendarListProvider);
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
    title: l.calNewCalendar,
    contentBuilder: (ctx, scrollCtrl) {
      final t = ctx.tokens;
      return StatefulBuilder(
        builder: (ctx, setSheet) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(
            PSpace.xl,
            0,
            PSpace.xl,
            PSpace.x16,
          ),
          children: [
            Text(
              l.calFieldName,
              style: PTypo.caption.copyWith(color: t.fgSecondary),
            ),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: nameCtrl,
              placeholder: l.calCalendarNamePlaceholder,
              onChanged: (v) => controller.setCanSubmit(v.trim().isNotEmpty),
            ),
            const SizedBox(height: PSpace.x12),
            Text(
              l.calFieldColor,
              style: PTypo.caption.copyWith(color: t.fgSecondary),
            ),
            const SizedBox(height: PSpace.x8),
            PColorPicker(
              selected: selectedColor,
              onChanged: (hex) => setSheet(() => selectedColor = hex),
            ),
          ],
        ),
      );
    },
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: l.calCreate),
  );
}

// ─── 초대 코드로 참여 ───────────────────────────────────────

void _showJoinDialog(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final codeCtrl = TextEditingController();
  final controller = PSheetController();

  Future<void> submit() async {
    if (codeCtrl.text.trim().isEmpty) return;
    controller.setSubmitting(true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      final joined = await repo.joinByCode(codeCtrl.text.trim().toUpperCase());
      ref.invalidate(userCalendarListProvider);
      if (!context.mounted) return;
      // 시트는 root navigator 소속(p_modal useRootNavigator) — root 명시.
      Navigator.of(context, rootNavigator: true).pop();
      showPSnackBar(
        context,
        l.calJoinedCalendar(joined.calendarName),
        severity: PSnackSeverity.success,
      );
    } on ApiException {
      if (!context.mounted) return;
    } finally {
      controller.setSubmitting(false);
    }
  }

  controller.onSubmit = submit;

  showPSheet<void>(
    context,
    title: l.calJoinByCode,
    contentBuilder: (ctx, scrollCtrl) {
      final t = ctx.tokens;
      return ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
        children: [
          Text(
            l.calInviteCode,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: codeCtrl,
            placeholder: l.calInviteCodePlaceholder,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            onChanged: (v) => controller.setCanSubmit(v.trim().isNotEmpty),
          ),
        ],
      );
    },
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: l.calJoin),
  );
}

// ─── 관리 (편집/공유/멤버/삭제) ──────────────────────────────

void _showManageSheet(
  BuildContext context,
  WidgetRef ref,
  UserCalendar calendar,
) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.calManageTitle(calendar.calendarName),
    // 컨텐츠 높이만큼 wrap (아래 빈 공간 제거).
    shrinkWrap: true,
    contentBuilder: (ctx, _) =>
        _ManageBody(calendar: calendar, controller: controller),
    footerBuilder: (ctx) => calendar.isOwner
        // 관리 시트는 상세 화면이 따로 없어 폼이 곧 상세다 — 삭제를 남기고 닫기는
        // 우상단 X 에 맡긴다(spec drawer.md 액션 구성 · 상세 화면이 없는 흐름).
        ? PSheetFooter(
            controller: controller,
            submitLabel: l.actionSave,
            deleteLabel: l.calDeleteCalendar,
          )
        : Row(
            children: [
              const Spacer(),
              PButton(
                label: l.actionClose,
                variant: PButtonVariant.ghost,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
  );
}

class _ManageBody extends ConsumerStatefulWidget {
  const _ManageBody({required this.calendar, required this.controller});
  final UserCalendar calendar;
  final PSheetController controller;

  @override
  ConsumerState<_ManageBody> createState() => _ManageBodyState();
}

class _ManageBodyState extends ConsumerState<_ManageBody> {
  late final TextEditingController _nameCtrl;
  late String _color;
  late String _baseName;
  late String _baseColor;

  UserCalendar get cal => widget.calendar;
  bool get isOwner => cal.isOwner;
  // 이름/색상이 저장된 값과 달라졌는지 — footer 저장 버튼 활성 기준.
  bool get _dirty => _nameCtrl.text.trim() != _baseName || _color != _baseColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: cal.calendarName);
    _color = cal.color ?? '#2c70bf';
    _baseName = cal.calendarName;
    _baseColor = _color;
    // 소유자만 footer 의 저장/삭제 액션을 가짐 — content 가 controller 에 연결.
    if (isOwner) {
      widget.controller.onSubmit = _saveMeta;
      if (!cal.isDefault) widget.controller.onDelete = _delete;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMeta() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.controller.setSubmitting(true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.update(
        id: cal.rowId,
        calendarName: _nameCtrl.text.trim(),
        color: _color,
      );
      ref.invalidate(userCalendarListProvider);
      _baseName = _nameCtrl.text.trim();
      _baseColor = _color;
      widget.controller.setCanSubmit(false);
    } on ApiException {
      // 토스트는 ErrorToastInterceptor 가 띄운다 — 여기선 흐름만 멈춘다.
    } finally {
      widget.controller.setSubmitting(false);
    }
  }

  Future<void> _regenerate() async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.regenerateInviteCode(cal.rowId);
      ref.invalidate(userCalendarListProvider);
      if (mounted) {
        showPSnackBar(
          context,
          l.calInviteCodeRegenerated,
          severity: PSnackSeverity.success,
        );
      }
    } on ApiException {
      // 토스트는 ErrorToastInterceptor 가 띄운다 — 여기선 흐름만 멈춘다.
    }
  }

  Future<void> _copyCode() async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: cal.inviteCode ?? ''));
    if (mounted) {
      showPSnackBar(
        context,
        l.calInviteCodeCopied,
        severity: PSnackSeverity.success,
      );
    }
  }

  Future<void> _changeRole(CalendarMember member, String permission) async {
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.changeMemberRole(cal.rowId, member.rowId, permission);
      ref.invalidate(calendarMembersProvider(cal.rowId));
      ref.invalidate(userCalendarListProvider);
    } on ApiException {
      // 토스트는 ErrorToastInterceptor 가 띄운다 — 여기선 흐름만 멈춘다.
    }
  }

  Future<void> _removeMember(CalendarMember member) async {
    final l = AppLocalizations.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.calRemoveMember,
      description: l.calRemoveMemberConfirm(member.userName),
      actionLabel: l.calRemove,
      destructive: true,
      cancelLabel: l.actionCancel,
    );
    if (!ok) return;
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.removeMember(cal.rowId, member.rowId);
      ref.invalidate(calendarMembersProvider(cal.rowId));
      ref.invalidate(userCalendarListProvider);
    } on ApiException {
      // 토스트는 ErrorToastInterceptor 가 띄운다 — 여기선 흐름만 멈춘다.
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.calDeleteCalendar,
      description: l.calDeleteCalendarConfirm(cal.calendarName),
      actionLabel: l.calDeleteCalendarAction,
      destructive: true,
      cancelLabel: l.actionCancel,
    );
    if (!ok) return;
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.delete(cal.rowId);
      ref.invalidate(userCalendarListProvider);
      // 서버가 이 캘린더의 일정을 기본 캘린더로 옮긴다(UserCalendarServiceImpl).
      // 월 일정을 다시 받지 않으면 지운 캘린더 소속인 채로(색·소속 모두 옛것) 남는다.
      ref.invalidate(monthEventsProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException {
      // 토스트는 ErrorToastInterceptor 가 띄운다 — 여기선 흐름만 멈춘다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final membersAsync = ref.watch(calendarMembersProvider(cal.rowId));
    final myId = ref.watch(authProvider).value?.rowId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwner) ...[
            Text(
              l.calFieldName,
              style: PTypo.caption.copyWith(color: t.fgSecondary),
            ),
            const SizedBox(height: PSpace.x4),
            PTextInput(
              controller: _nameCtrl,
              placeholder: l.calCalendarNameFieldPlaceholder,
              onChanged: (_) => widget.controller.setCanSubmit(_dirty),
            ),
            const SizedBox(height: PSpace.x12),
            Text(
              l.calFieldColor,
              style: PTypo.caption.copyWith(color: t.fgSecondary),
            ),
            const SizedBox(height: PSpace.x8),
            PColorPicker(
              selected: _color,
              onChanged: (hex) {
                setState(() => _color = hex);
                widget.controller.setCanSubmit(_dirty);
              },
            ),
            const SizedBox(height: PSpace.x16),
            Text(
              l.calInviteCode,
              style: PTypo.caption.copyWith(color: t.fgSecondary),
            ),
            const SizedBox(height: PSpace.x4),
            Row(
              children: [
                Expanded(
                  child: PTextInput(
                    controller: TextEditingController(
                      text: cal.inviteCode ?? '',
                    ),
                    enabled: false,
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                PButton.icon(
                  icon: LucideIcons.copy,
                  tooltip: l.calCopy,
                  onPressed: _copyCode,
                ),
                PButton.icon(
                  icon: LucideIcons.refreshCw,
                  tooltip: l.calRegenerate,
                  onPressed: _regenerate,
                ),
              ],
            ),
            const SizedBox(height: PSpace.x16),
          ],
          Text(
            l.calMembers,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x8),
          membersAsync.when(
            loading: () => const PListSkeleton(rows: 2, showAvatar: true),
            error: (e, _) => Text(
              l.calMemberLoadError,
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
            data: (members) => Column(
              children: [
                for (final m in members)
                  _MemberRow(
                    member: m,
                    tokens: t,
                    isMe: m.userRowId == myId,
                    canManage:
                        isOwner &&
                        m.permission != 'OWNER' &&
                        m.userRowId != myId,
                    onChangeRole: (perm) => _changeRole(m, perm),
                    onRemove: () => _removeMember(m),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.tokens,
    required this.isMe,
    required this.canManage,
    required this.onChangeRole,
    required this.onRemove,
  });
  final CalendarMember member;
  final GrooTokens tokens;
  final bool isMe;
  final bool canManage;
  final void Function(String permission) onChangeRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final (roleLabel, roleVariant, roleIcon) = _roleStyle(l, member.permission);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: roleVariant == PBadgeVariant.outline
                  ? t.bgSunken
                  : softBg(context, _roleColor(context, member.permission)),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              roleIcon,
              size: 16,
              color: _roleColor(context, member.permission),
            ),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PTypo.body.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text(
                        l.calMeSuffix,
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                    ],
                  ],
                ),
                if ((member.userEmail ?? '').isNotEmpty)
                  Text(
                    member.userEmail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
              ],
            ),
          ),
          if (canManage)
            // ⋮ — 폰에서는 떠 있는 메뉴가 아니라 Menu Sheet 다(03-F 4A). 이름은 "{이름} 더보기"
            PButton.icon(
              icon: LucideIcons.ellipsisVertical,
              iconColor: t.fgTertiary,
              tooltip: l.calMemberMore(member.userName),
              onPressed: () => PMenuSheet.show(
                context,
                title: member.userName,
                layout: PMenuSheetLayout.textOnly,
                groups: [
                  PMenuSheetGroup([
                    if (member.permission != 'EDIT')
                      PMenuSheetItem(
                        label: l.calChangeToEditor,
                        onSelect: () => onChangeRole('EDIT'),
                      ),
                    if (member.permission != 'READ')
                      PMenuSheetItem(
                        label: l.calChangeToViewer,
                        onSelect: () => onChangeRole('READ'),
                      ),
                  ]),
                  PMenuSheetGroup([
                    PMenuSheetItem(
                      label: l.calRemove,
                      tone: PMenuSheetTone.critical,
                      onSelect: onRemove,
                    ),
                  ]),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: PBadge(
                label: roleLabel,
                variant: roleVariant,
                icon: roleIcon,
              ),
            ),
        ],
      ),
    );
  }

  Color _roleColor(BuildContext context, String role) {
    final t = context.tokens;
    return switch (role) {
      'OWNER' => t.statusInfoFg,
      'EDIT' => t.statusSuccessFg,
      _ => t.fgTertiary,
    };
  }
}
