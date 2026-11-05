import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_manage_forms.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_surface_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart' as ds;
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as dsb;
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 설정 진입 — 캘린더 관리·공유 (user_calendar 기반).
///
/// 개인 캘린더 자체를 공유 단위로. 이 화면은 목록 — 줄을 누르면 캘린더 관리 페이지(`calendar_manage_screen.dart`)로 옮긴다.
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
                // 다시 받기가 실패해도 받아 둔 목록은 남긴다(웹과 같다)
                skipError: true,
                loading: () => _ShareSkeleton(
                  onCreate: () => showCalendarCreateSheet(context),
                ),
                error: (e, _) => CalendarSurfaceFailure(
                  title: l.calCalendarLoadError,
                  onRetry: () => ref.invalidate(userCalendarListProvider),
                ),
                data: (calendars) => _CalendarSections(
                  calendars: calendars,
                  onCreate: () => showCalendarCreateSheet(context),
                ),
              ),
              PListHeader(
                title: l.calJoinSectionTitle,
                variant: PListHeaderVariant.boldSolid,
                topInset: PSpacing.x6,
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
                        onPressed: () => showCalendarJoinSheet(context),
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

class _ShareSkeleton extends StatelessWidget {
  const _ShareSkeleton({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        // 추가 버튼은 정적 UI라 로딩에도 진짜를 쓴다 — 개수 글과 줄만 데이터 자리
        CalendarSurfaceHeaderSkeleton(
          action: PTextButton(label: l.calNewCalendar, onPressed: onCreate),
        ),
        const CalendarSurfaceRowSkeleton(),
        const CalendarSurfaceRowSkeleton(),
        const CalendarSurfaceHeaderSkeleton(topInset: PSpacing.x6),
        const CalendarSurfaceRowSkeleton(),
      ],
    );
  }
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
          topInset: PSpacing.x6,
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

class _CalendarList extends StatelessWidget {
  const _CalendarList({
    required this.title,
    required this.calendars,
    required this.emptyText,
  });
  final String title;
  final List<UserCalendar> calendars;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (calendars.isEmpty) return CalendarSurfaceEmptyLine(emptyText);
    final l = AppLocalizations.of(context);
    return PList(
      semanticLabel: title,
      children: [
        for (final cal in calendars)
          // 누르면 캘린더 관리 페이지로 옮긴다(I-09b 21) — 화면을 옮기는 줄이라 꺾쇠 18 subtle(list.md:122)
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
            suffix: const ExcludeSemantics(
              child: Icon(LucideIcons.chevronRight),
            ),
            onTap: () => context.push('/settings/calendar-share/${cal.rowId}'),
          ),
      ],
    );
  }
}

/// 공유받은 캘린더의 권한 배지(소유한 캘린더는 부르지 않는다 — OWNER 갈래 없음) — 편집 가능 positive + 연필 · 읽기 전용 informative + 눈(badge.md 예시).
Widget _roleBadge(AppLocalizations l, String role) => switch (role) {
  'EDIT' => ds.PBadge(
    label: l.calRoleEditor,
    variant: ds.PBadgeVariant.outline,
    tone: ds.PBadgeTone.positive,
    prefixIcon: LucideIcons.pencil,
  ),
  _ => ds.PBadge(
    label: l.calRoleViewer,
    variant: ds.PBadgeVariant.outline,
    tone: ds.PBadgeTone.informative,
    prefixIcon: LucideIcons.eye,
  ),
};
