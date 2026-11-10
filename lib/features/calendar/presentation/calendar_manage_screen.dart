import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_manage_forms.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_surface_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/forms/color_pick.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart'
    show PChartColor;
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 캘린더 관리 — 캘린더 하나 = 페이지(I-09b 22 · 3-B). `/settings/calendar-share/:calendarId`.
///
/// 흰 면 하나 — 소유자는 "캘린더"(이름 · 색상 줄) · "초대 코드" · "멤버" 목록 제목이 가르고, 공유받은 캘린더는 멤버만 보인다.
/// 이름 · 색은 줄마다 그 자리에서 저장한다(한 번의 [저장] 없음). 목록에서 이 캘린더를 못 찾으면(지움 · 내보내짐 · 틀린 주소) 돌아간다.
class CalendarManageScreen extends ConsumerStatefulWidget {
  const CalendarManageScreen({super.key, required this.calendarId});

  final int? calendarId;

  @override
  ConsumerState<CalendarManageScreen> createState() =>
      _CalendarManageScreenState();
}

class _CalendarManageScreenState extends ConsumerState<CalendarManageScreen> {
  bool _leaving = false;

  // 이름 · 색을 저장한 뒤 목록을 다시 받는 동안 옛 값이 보이지 않게 성공한 값을 먼저 보인다.
  // 다시 받은 목록의 값이 [base] 에서 바뀌면(다시 받음 끝) 더는 쓰지 않는다.
  String? _nameOverride;
  String? _nameBase;
  String? _colorOverride;
  String? _colorBase;

  /// 목록으로 돌아간다 — 한 번만. 이 화면이 맨 위일 때만(나가는 중이거나 가려졌으면 부르지 않는다: go_router 의
  /// pop 은 맨 위 라우트를 닫으므로 두 번 부르면 목록까지 닫힌다).
  void _leave() {
    if (_leaving || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _leaving = true;
    _back();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings/calendar-share');
    }
  }

  UserCalendar _effective(UserCalendar c) {
    final name = _nameOverride != null && c.calendarName == _nameBase
        ? _nameOverride!
        : c.calendarName;
    final color = _colorOverride != null && c.color == _colorBase
        ? _colorOverride
        : c.color;
    if (name == c.calendarName && color == c.color) return c;
    return UserCalendar(
      rowId: c.rowId,
      ownerRowId: c.ownerRowId,
      ownerName: c.ownerName,
      calendarName: name,
      color: color,
      sortOrder: c.sortOrder,
      isDefault: c.isDefault,
      isVisible: c.isVisible,
      inviteCode: c.inviteCode,
      isShared: c.isShared,
      isOwner: c.isOwner,
      myRole: c.myRole,
      memberCount: c.memberCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(userCalendarListProvider);
    final calendars = listAsync.value;
    UserCalendar? cal;
    if (calendars != null) {
      for (final c in calendars) {
        if (c.rowId == widget.calendarId) cal = _effective(c);
      }
      // 못 찾음은 다시 받는 중이 아닐 때만 — 지운 직후 다시 받는 사이에 두 번 닫지 않게
      if (cal == null && !listAsync.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
      }
    }

    return Scaffold(
      backgroundColor: context.colors.bgLayerDefault,
      // 머리 = 상단 바(← + 캘린더 이름 한 줄 말줄임). 이름 전체는 "이름" 줄에 있다. 불러오는 동안은 제목 자리를 비운다
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: cal?.calendarName ?? '',
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: _back,
          ),
        ),
      ),
      body: PScreenBandBody(
        child: PPullToRefresh(
          onRefresh: () async {
            ref.invalidate(userCalendarListProvider);
            if (cal != null) ref.invalidate(calendarMembersProvider(cal.rowId));
            await ref.read(userCalendarListProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.only(
              bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (cal != null)
                _ManageBody(
                  calendar: cal,
                  onLeave: _leave,
                  onRenamed: (name) => setState(() {
                    _nameBase = calendars!
                        .firstWhere((c) => c.rowId == cal!.rowId)
                        .calendarName;
                    _nameOverride = name;
                  }),
                  onRecolored: (color) => setState(() {
                    _colorBase = calendars!
                        .firstWhere((c) => c.rowId == cal!.rowId)
                        .color;
                    _colorOverride = color;
                  }),
                )
              else if (listAsync.hasError && calendars == null)
                CalendarSurfaceFailure(
                  title: l.calCalendarLoadError,
                  retrying: listAsync.isLoading,
                  onRetry: () => ref.invalidate(userCalendarListProvider),
                )
              else if (calendars == null)
                loadingRegion(const _ManageSkeleton()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 목록을 처음 불러오는 동안 — 목록 제목 셋 + 줄 모양.
class _ManageSkeleton extends StatelessWidget {
  const _ManageSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      CalendarSurfaceHeaderSkeleton(),
      CalendarSurfaceRowSkeleton(),
      CalendarSurfaceRowSkeleton(),
      CalendarSurfaceHeaderSkeleton(topInset: PSpacing.x6),
      CalendarSurfaceRowSkeleton(),
      CalendarSurfaceHeaderSkeleton(topInset: PSpacing.x6),
      CalendarSurfaceRowSkeleton(),
      CalendarSurfaceRowSkeleton(),
    ],
  );
}

class _ManageBody extends ConsumerStatefulWidget {
  const _ManageBody({
    required this.calendar,
    required this.onLeave,
    required this.onRenamed,
    required this.onRecolored,
  });
  final UserCalendar calendar;

  /// 목록으로 돌아간다(화면이 한 번만 부른다).
  final VoidCallback onLeave;
  final ValueChanged<String> onRenamed;
  final ValueChanged<String> onRecolored;

  @override
  ConsumerState<_ManageBody> createState() => _ManageBodyState();
}

class _ManageBodyState extends ConsumerState<_ManageBody> {
  bool _regenerating = false;
  bool _colorBusy = false;

  UserCalendar get cal => widget.calendar;

  Future<void> _pickColor() async {
    if (_colorBusy) return;
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.maybeOf(context);
    final stored = cal.color ?? chartHexOf(PChartColor.blue);
    final foreign = chartColorOfHex(stored) == null ? stored : null;
    final picked = await showColorPickSheet(
      context,
      title: l.calFieldColor,
      hex: stored,
      foreignHex: foreign,
    );
    if (picked == null || picked == stored || !mounted) return;
    _colorBusy = true;
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(userCalendarRepositoryProvider.future);
      // 색만 보낸다. 바로 반영하는 값이라 실패하면 줄 값은 옛 색 그대로 — 알림만, [다시 시도] 없음
      await repo.update(id: cal.rowId, color: picked, silent: true);
      container.invalidate(userCalendarListProvider);
      container.invalidate(monthEventsProvider);
      // 부모 setState 라 화면이 나간 뒤엔 던진다 — 비우기 뒤에, 살아 있을 때만
      if (mounted) widget.onRecolored(picked);
    } on ApiException {
      snack?.show(
        message: l.calColorChangeFailed,
        tone: PSnackbarTone.critical,
      );
    } finally {
      _colorBusy = false;
    }
  }

  Future<void> _regenerate() async {
    if (_regenerating) return;
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.maybeOf(context);
    final container = ProviderScope.containerOf(context);
    final id = cal.rowId;
    Future<void> request() async {
      final repo = await container.read(userCalendarRepositoryProvider.future);
      await repo.regenerateInviteCode(id);
      container.invalidate(userCalendarListProvider);
      snack?.show(
        message: l.calInviteCodeRegenerated,
        tone: PSnackbarTone.positive,
      );
    }

    setState(() => _regenerating = true);
    try {
      await request();
    } catch (e) {
      showConfirmFailSnackbar(
        snack,
        error: e,
        message: l.calRegenerateFailed,
        retryLabel: l.actionRetry,
        retry: request,
        // 응답을 못 받았다 — 새 코드가 생겼을 수 있다. 다시 받아 보이는 코드를 맞춘다
        unconfirmedMessage: unconfirmedWriteText(l, WriteKind.process),
        onUnconfirmed: () => container.invalidate(userCalendarListProvider),
      );
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _copyCode() async {
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: cal.inviteCode ?? ''));
    snack?.show(message: l.calInviteCodeCopied, tone: PSnackbarTone.positive);
  }

  Future<void> _changeRole(CalendarMember member, String permission) async {
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.maybeOf(context);
    final container = ProviderScope.containerOf(context);
    final id = cal.rowId;
    Future<void> request() async {
      final repo = await container.read(userCalendarRepositoryProvider.future);
      await repo.changeMemberRole(id, member.rowId, permission);
      container.invalidate(calendarMembersProvider(id));
      container.invalidate(userCalendarListProvider);
    }

    try {
      await request();
    } catch (e) {
      showConfirmFailSnackbar(
        snack,
        error: e,
        message: l.calRoleChangeFailed,
        retryLabel: l.actionRetry,
        retry: request,
        unconfirmedMessage: unconfirmedWriteText(l, WriteKind.save),
        onUnconfirmed: () => container
          ..invalidate(calendarMembersProvider(id))
          ..invalidate(userCalendarListProvider),
      );
    }
  }

  Future<void> _removeMember(CalendarMember member) async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final id = cal.rowId;
    await askConfirmThenRequest(
      context,
      title: l.calRemoveMember,
      description: l.calRemoveMemberConfirm(member.userName),
      cancelLabel: l.actionCancel,
      actionLabel: l.calRemove,
      request: () async {
        final repo = await container.read(
          userCalendarRepositoryProvider.future,
        );
        await repo.removeMember(id, member.rowId);
        container.invalidate(calendarMembersProvider(id));
        container.invalidate(userCalendarListProvider);
      },
      failedMessage: l.calRemoveMemberFailed,
      retryLabel: l.actionRetry,
      kind: WriteKind.process,
      onUnconfirmed: () => container
        ..invalidate(calendarMembersProvider(id))
        ..invalidate(userCalendarListProvider),
    );
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final id = cal.rowId;
    final ok = await askConfirmThenRequest(
      context,
      title: l.calDeleteCalendar,
      description: l.calDeleteCalendarConfirm(cal.calendarName),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      request: () => _deleteCalendarRequest(container, id),
      failedMessage: l.calDeleteCalendarFailed,
      retryLabel: l.actionRetry,
      // 스낵바는 화면을 떠난 뒤에도 남는다 — 아직 이 화면이 맨 위일 때만 돌아간다
      onRetried: () {
        if (mounted) widget.onLeave();
      },
      kind: WriteKind.delete,
      // 응답을 못 받았다 — 지워졌을 수 있다. 목록 · 일정만 다시 받는다(화면을 떠나는 성공 뒷정리는 하지 않는다)
      onUnconfirmed: () => container
        ..invalidate(userCalendarListProvider)
        ..invalidate(monthEventsProvider),
    );
    if (ok && mounted) widget.onLeave();
  }

  void _openMenu(CalendarMember member) {
    final l = AppLocalizations.of(context);
    PMenuSheet.show(
      context,
      title: member.userName,
      layout: PMenuSheetLayout.textOnly,
      groups: [
        // 줄이 둘이라 묶음 하나 — 지금 권한이 아닌 쪽 + 내보내기(맨 아래 critical)
        PMenuSheetGroup([
          if (member.permission != 'EDIT')
            PMenuSheetItem(
              label: l.calChangeToEditor,
              onSelect: () => _changeRole(member, 'EDIT'),
            ),
          if (member.permission != 'READ')
            PMenuSheetItem(
              label: l.calChangeToViewer,
              onSelect: () => _changeRole(member, 'READ'),
            ),
          PMenuSheetItem(
            label: l.calRemove,
            tone: PMenuSheetTone.critical,
            onSelect: () => _removeMember(member),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final membersAsync = ref.watch(calendarMembersProvider(cal.rowId));
    final myId = ref.watch(authProvider).value?.rowId;
    final isOwner = cal.isOwner;
    final stored = cal.color ?? chartHexOf(PChartColor.blue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOwner) ...[
          PListHeader(
            title: l.calFieldCalendar,
            variant: PListHeaderVariant.boldSolid,
          ),
          PList(
            semanticLabel: l.calFieldCalendar,
            children: [
              PickerRow(
                title: l.calFieldName,
                prefix: const ExcludeSemantics(child: Icon(LucideIcons.type)),
                value: cal.calendarName,
                onTap: () => showCalendarRenameSheet(
                  context,
                  calendar: cal,
                  onRenamed: widget.onRenamed,
                ),
              ),
              PickerRow(
                title: l.calFieldColor,
                prefix: const ExcludeSemantics(
                  child: Icon(LucideIcons.palette),
                ),
                value: colorPickName(context, stored),
                leading: PickerDot(
                  color: resolveChartColor(
                    context,
                    stored,
                    fallback: c.fgBrand,
                  ),
                ),
                onTap: _pickColor,
              ),
            ],
          ),
          PListHeader(
            title: l.calInviteCode,
            variant: PListHeaderVariant.boldSolid,
            topInset: PSpacing.x6,
          ),
          _InviteBlock(
            code: (cal.inviteCode ?? '').trim(),
            hint: l.calInviteHint,
            regenerating: _regenerating,
            onCopy: _copyCode,
            onRegenerate: _regenerate,
          ),
        ],
        PListHeader(
          title: membersAsync.hasValue
              ? l.calMembersCount(membersAsync.value!.length)
              : l.calMembers,
          variant: PListHeaderVariant.boldSolid,
          topInset: isOwner ? PSpacing.x6 : null,
        ),
        membersAsync.when(
          skipError: true,
          loading: () => loadingRegion(
            const Column(children: [_MemberSkeleton(), _MemberSkeleton()]),
          ),
          error: (e, _) => CalendarSurfaceFailure(
            title: l.calMemberLoadFailed,
            retrying: membersAsync.isLoading,
            onRetry: () => ref.invalidate(calendarMembersProvider(cal.rowId)),
          ),
          data: (members) => PList(
            semanticLabel: l.calMembers,
            children: [
              for (final m in members)
                _memberRow(
                  context,
                  m,
                  isMe: m.userRowId != null && m.userRowId == myId,
                  canManage:
                      isOwner && m.permission != 'OWNER' && m.userRowId != myId,
                ),
            ],
          ),
        ),
        if (isOwner && !cal.isDefault) ...[
          // 되돌릴 수 없는 동작을 멤버 줄과 떼어 놓는 흰 여백
          const SizedBox(height: PSpacing.x2),
          PList(
            semanticLabel: l.calDeleteCalendar,
            children: [
              PListButtonItem(
                title: l.calDeleteCalendar,
                titleColor: c.fgCritical,
                onTap: _delete,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _memberRow(
    BuildContext context,
    CalendarMember m, {
    required bool isMe,
    required bool canManage,
  }) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final (label, tone, icon) = switch (m.permission) {
      'OWNER' => (l.calRoleOwner, PBadgeTone.neutral, LucideIcons.crown),
      'EDIT' => (l.calRoleEditor, PBadgeTone.positive, LucideIcons.pencil),
      _ => (l.calRoleViewer, PBadgeTone.informative, LucideIcons.eye),
    };
    final email = (m.userEmail ?? '').trim();
    final avatar = PAvatar(
      name: m.userName,
      size: PAvatarSize.s36,
      decorative: true,
    );
    final suffix = PBadge(
      label: label,
      variant: PBadgeVariant.outline,
      tone: tone,
      prefixIcon: icon,
    );
    final meSuffix = [
      if (isMe)
        Text(
          l.calMeSuffix,
          style: PTypography.t5.copyWith(color: c.fgNeutralSubtle),
        ),
    ];
    // 소유자에게만 누르는 줄 — 눌러서 권한 바꾸기 · 내보내기 Menu Sheet 를 연다(줄 끝 ⋮ 없음, 10-25)
    if (canManage) {
      return PListButtonItem(
        key: ValueKey('cal-member-${m.rowId}'),
        prefix: avatar,
        title: m.userName,
        titleSuffix: meSuffix,
        detail: email.isEmpty ? null : email,
        suffix: suffix,
        semanticHint: l.calMemberManage(m.userName),
        onTap: () => _openMenu(m),
      );
    }
    return PListItem(
      key: ValueKey('cal-member-${m.rowId}'),
      prefix: avatar,
      title: m.userName,
      titleSuffix: meSuffix,
      detail: email.isEmpty ? null : email,
      suffix: suffix,
    );
  }
}

/// 초대 코드 덩어리 — 코드(t8 700 · 고정폭 숫자) + [복사] [새로 만들기], 아래 안내. 좁으면 버튼 묶음이 다음 줄로 내려간다.
class _InviteBlock extends StatelessWidget {
  const _InviteBlock({
    required this.code,
    required this.hint,
    required this.regenerating,
    required this.onCopy,
    required this.onRegenerate,
  });

  final String code;
  final String hint;
  final bool regenerating;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x1,
        PSpacing.globalGutter,
        PSpacing.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: PSpacing.x3,
            runSpacing: PSpacing.x3,
            children: [
              // 코드가 없는 캘린더(옛 캘린더 — 초대 코드 칸이 비어 있다)는 값 자리에 글, [복사] 는 숨긴다
              if (code.isEmpty)
                PText(
                  l.calInviteNone,
                  style: PTypography.t8.copyWith(
                    color: c.fgNeutralSubtle,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              else
                Text(
                  code,
                  style: PTypography.t8.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: PSpacing.x2,
                children: [
                  if (code.isNotEmpty)
                    PButton(
                      label: l.calCopy,
                      variant: PButtonVariant.neutralWeak,
                      size: PButtonSize.small,
                      onPressed: onCopy,
                    ),
                  PButton(
                    label: l.calRegenerate,
                    variant: PButtonVariant.neutralWeak,
                    size: PButtonSize.small,
                    loading: regenerating,
                    onPressed: regenerating ? null : onRegenerate,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: PSpacing.x2),
          Text(hint, style: PTypography.t3.copyWith(color: c.fgNeutralSubtle)),
        ],
      ),
    );
  }
}

class _MemberSkeleton extends StatelessWidget {
  const _MemberSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.globalGutter,
      vertical: PSpacing.x3,
    ),
    child: Row(
      children: [
        const PSkeleton(width: 36, height: 36, radius: PSkeletonRadius.full),
        const SizedBox(width: PSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x0_5,
            children: [
              PSkeleton.text(PTypography.t5, width: 120),
              PSkeleton.text(PTypography.t3, width: 160),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 캘린더 삭제 요청 — 컨테이너로 한다([다시 시도] 도 이걸 부른다). 실패는 던진다.
Future<void> _deleteCalendarRequest(ProviderContainer container, int id) async {
  final repo = await container.read(userCalendarRepositoryProvider.future);
  await repo.delete(id);
  container.invalidate(userCalendarListProvider);
  // 서버가 이 캘린더의 일정을 기본 캘린더로 옮긴다(UserCalendarServiceImpl).
  // 월 일정을 다시 받지 않으면 지운 캘린더 소속인 채로(색·소속 모두 옛것) 남는다.
  container.invalidate(monthEventsProvider);
}
