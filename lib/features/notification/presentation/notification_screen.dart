import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart'
    show PTouchTargetScope;
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as ds;
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';

/// 알림 목록(I-15 41 ~ 44) — 상단 바(← "알림" + ⚙ "알림 설정") → 흰 면 하나: 목록 머리 "읽지 않은 알림 N개" +
/// 오른쪽 글 버튼 "모두 읽음" → 날짜 묶음("10월 23일 (금) · 오늘") + 줄. 바닥 고정 띠는 없다.
/// 줄 누름 = 읽음(이동하지 않는다) · 줄 끝 ⋮ → 삭제(확인창을 거친다).
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final listAsync = ref.watch(notificationListProvider);
    // {n} 은 서버가 센 안 읽은 수 — 받아 온 줄(최근 100개)로 세지 않는다. 아직 못 받았으면 받아 온 줄로 잠깐 채운다.
    // 수가 오기 전(불러오는 중 · 다시 받는 중 · 실패)에는 머리 줄을 두지 않는다 — 받은 줄로 세지 않고 낡은 수를 남기지 않는다.
    final countAsync = ref.watch(unreadCountProvider);
    final unread = (countAsync.isLoading || countAsync.hasError)
        ? 0
        : (countAsync.value ?? 0);
    final container = ProviderScope.containerOf(context, listen: false);
    // 상대시각의 기준점 — 화면을 열어 둔 채로도 흐르게 한다(웹 `useNow` 정합).
    // 여기서 한 번 watch 해 행마다 내리는 건 모든 행이 **같은 '지금'** 을 쓰게 하려는 것이다.
    final now = ref.watch(nowTickProvider);

    Future<void> refresh() async {
      ref.invalidate(notificationListProvider);
      ref.invalidate(unreadCountProvider);
      try {
        await ref.read(notificationListProvider.future);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.notiTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
          actions: [
            PTopNavigationIconButton(
              icon: LucideIcons.settings,
              label: l.notiSettings,
              onPressed: () => context.push('/settings/notifications'),
            ),
          ],
        ),
      ),
      body: PPullToRefresh(
        onRefresh: refresh,
        child: listAsync.when(
          // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
          skipError: true,
          loading: () => const _NotiSkeleton(),
          error: (e, _) => ListView(
            children: [
              PResultSection(
                kind: PResultKind.failure,
                title: l.notiLoadFailed,
                description: l.notiLoadFailedDesc,
                primaryAction: PResultAction(
                  label: l.actionRetry,
                  loading: listAsync.loadRetrying,
                  onPressed: () => ref.invalidate(notificationListProvider),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  PResultSection(icon: LucideIcons.bell, title: l.notiEmpty),
                ],
              );
            }
            final groups = _groupByDay(items, now);
            return ListView(
              padding: const EdgeInsets.only(bottom: PSpacing.x6),
              children: [
                if (unread > 0)
                  _UnreadHead(
                    count: unread,
                    onMarkAll: () => _markAllRead(context, ref),
                  ),
                for (var g = 0; g < groups.length; g++) ...[
                  PListHeader(
                    title: groups[g].label(l),
                    // 첫 날짜 머리 위 8 · 그 뒤 묶음 위 16
                    topInset: g == 0 ? PSpacing.x2 : PSpacing.x4,
                  ),
                  for (final n in groups[g].items)
                    _NotiRow(
                      key: ValueKey('noti-${n.rowId}'),
                      noti: n,
                      now: now,
                      today: groups[g].isToday,
                      onTap: () async {
                        if (!n.isRead) {
                          await _markReadOne(context, ref, n.rowId);
                        }
                      },
                      onDelete: () => _delete(container, n),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 서버에서 지우고 목록 · 안 읽은 수를 비운다. 던지면 실패다.
/// 화면(ref)이 아니라 컨테이너로 — [다시 시도] 가 화면을 떠난 뒤 눌려도 죽지 않는다.
Future<void> _delete(ProviderContainer c, AppNotification n) async {
  final repo = await c.read(notificationRepositoryProvider.future);
  await repo.delete(n.rowId);
  c.invalidate(notificationListProvider);
  c.invalidate(unreadCountProvider);
}

/// 알림 하나 읽음 — 실패하면 critical 스낵바 + [다시 시도].
Future<void> _markReadOne(
  BuildContext context,
  WidgetRef ref,
  int rowId,
) async {
  final c = ProviderScope.containerOf(context, listen: false);
  final snack = PSnackbar.maybeOf(context);
  final l = AppLocalizations.of(context);
  await _markReadOneDetached(c, snack, l, rowId);
}

Future<void> _markReadOneDetached(
  ProviderContainer c,
  PSnackbarApi? snack,
  AppLocalizations l,
  int rowId,
) async {
  try {
    final repo = await c.read(notificationRepositoryProvider.future);
    await repo.markRead(rowId);
    c.invalidate(notificationListProvider);
    c.invalidate(unreadCountProvider);
  } catch (_) {
    snack?.show(
      message: l.notiMarkReadFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () => _markReadOneDetached(c, snack, l, rowId),
      ),
    );
  }
}

/// 모두 읽음 — 실패하면 critical 스낵바 + [다시 시도](같은 요청을 바로). 요청은 전역 오류 알림을 끈다.
Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
  final c = ProviderScope.containerOf(context, listen: false);
  final snack = PSnackbar.maybeOf(context);
  final l = AppLocalizations.of(context);
  await _markAllReadDetached(c, snack, l);
}

Future<void> _markAllReadDetached(
  ProviderContainer c,
  PSnackbarApi? snack,
  AppLocalizations l,
) async {
  try {
    final repo = await c.read(notificationRepositoryProvider.future);
    await repo.markAllRead();
    c.invalidate(notificationListProvider);
    c.invalidate(unreadCountProvider);
  } catch (_) {
    snack?.show(
      message: l.notiMarkAllFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () => _markAllReadDetached(c, snack, l),
      ),
    );
  }
}

/// 날짜(기기 시간대 달력 날) 하나의 알림 묶음 — 새것 위(서버 차례 그대로, 묶음 안 차례도).
class _DayGroup {
  _DayGroup(this.day, this.today, this.yesterday);
  final DateTime? day;
  final bool today;
  final bool yesterday;
  final List<AppNotification> items = [];

  bool get isToday => today;

  /// "10월 23일 (금) · 오늘" · "10월 22일 (목) · 어제" · 그 밖 "10월 18일 (일)" · 다른 해 "2025년 12월 3일 (수)".
  String label(AppLocalizations l) {
    final d = day;
    if (d == null) return '';
    final base = monthDayDow(d);
    if (today) return '$base · ${l.dateToday}';
    if (yesterday) return '$base · ${l.dateYesterday}';
    return base;
  }
}

List<_DayGroup> _groupByDay(List<AppNotification> items, DateTime now) {
  final todayKey = DateTime(now.year, now.month, now.day);
  final yesterdayKey = DateTime(now.year, now.month, now.day - 1);
  final groups = <_DayGroup>[];
  DateTime? lastKey;
  for (final n in items) {
    final dt = parseServerUtc(n.createAt);
    // 시각을 못 읽는 줄은 앞 줄과 같은 날로 둔다
    final key = dt == null ? lastKey : DateTime(dt.year, dt.month, dt.day);
    if (groups.isEmpty || key != lastKey) {
      groups.add(_DayGroup(key, key == todayKey, key == yesterdayKey));
      lastKey = key;
    }
    groups.last.items.add(n);
  }
  return groups;
}

/// 목록 머리 — "읽지 않은 알림 N개"(천 단위 쉼표) + 오른쪽 글 버튼 "모두 읽음". 머리말이 아니다(목록 위 상태 줄).
class _UnreadHead extends StatefulWidget {
  const _UnreadHead({required this.count, required this.onMarkAll});
  final int count;
  final Future<void> Function() onMarkAll;

  @override
  State<_UnreadHead> createState() => _UnreadHeadState();
}

class _UnreadHeadState extends State<_UnreadHead> {
  // 요청 중에는 그 버튼만 막는다(같은 요청을 겹쳐 보내지 않는다)
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onMarkAll();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PListHeader(
      title: l.notiUnreadHead(
        NumberFormat.decimalPattern().format(widget.count),
      ),
      headingLevel: 0,
      action: PTextButton(
        label: l.notiMarkAllRead,
        onPressed: _busy ? null : _run,
      ),
    );
  }
}

/// 알림 목록 skeleton — 틀(상단 바)은 그리고 머리 줄 · 날짜 머리 · 줄 자리만(타일 40 + 제목 · 본문 · 시각).
class _NotiSkeleton extends StatelessWidget {
  const _NotiSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i == 0 || i == 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                // 날짜 머리 = PListHeader t4 줄 높이
                child: PSkeleton.text(PTypography.t4, width: 140),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PSkeleton(
                  width: 40,
                  height: 40,
                  radius: PSkeletonRadius.r12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 글 자리 = 그 글의 줄 높이 — 제목 t5 · 본문 t3 두 줄(skeleton.md:40)
                      PSkeleton.text(
                        PTypography.t5,
                        width: i.isEven ? 140 : 100,
                      ),
                      const SizedBox(height: 4),
                      PSkeleton.text(PTypography.t3, width: double.infinity),
                      const SizedBox(height: 4),
                      PSkeleton.text(PTypography.t3, width: 180),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  // 시각 t3
                  child: PSkeleton.text(PTypography.t3, width: 36),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NotiRow extends StatefulWidget {
  const _NotiRow({
    super.key,
    required this.noti,
    required this.now,
    required this.today,
    required this.onTap,
    required this.onDelete,
  });
  final AppNotification noti;

  /// 상대시각의 기준점 — 호출부에서 `nowTickProvider` 로 받아 내린다. 기본값을 두지 않는다(안 넘긴 호출부가
  /// 조용히 [DateTime.now] 로 돌아가 얼어붙는 것을 컴파일이 붙잡는다).
  final DateTime now;

  /// 오늘 묶음 안의 줄인가 — 오늘 것만 "n시간 전", 다른 날 묶음은 시각("오후 9:00")이다(Q6 B).
  final bool today;

  /// 읽음 처리 — 비동기. 끝날 때까지 행이 스피너를 띄우고 잠긴다.
  final Future<void> Function() onTap;

  /// 지우기 — 메뉴(⋮)의 "삭제" → 확인창에서 삭제를 누르면 부른다. 던지면 실패다.
  final Future<void> Function() onDelete;

  @override
  State<_NotiRow> createState() => _NotiRowState();
}

class _NotiRowState extends State<_NotiRow> {
  AppNotification get noti => widget.noti;

  /// notificationType → lucide 아이콘 (웹 notificationVisual 과 같다).
  IconData _typeIcon() => switch (noti.notificationType) {
    'BUDGET_ALERT' => LucideIcons.triangleAlert,
    'TODO_REMINDER' => LucideIcons.listChecks,
    'EVENT_REMINDER' => LucideIcons.calendarClock,
    _ => LucideIcons.bell,
  };

  /// notificationType 별 (바탕, 아이콘) — 차트 색의 옅은 바탕 + 그 색(list.md Prefix 타일).
  (Color, Color) _typeTone(PColors c) => switch (noti.notificationType) {
    'BUDGET_ALERT' => (c.chartOrangeWeak, c.chartOrange),
    'TODO_REMINDER' => (c.chartBlueWeak, c.chartBlue),
    'EVENT_REMINDER' => (c.chartGreenWeak, c.chartGreen),
    _ => (c.chartGrayWeak, c.chartGray),
  };

  // 읽음 처리 진행 중 — 점 자리에 스피너, 탭 잠금.
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final unread = !noti.isRead;
    final (toneBg, toneFg) = _typeTone(c);
    final time = (noti.createAt ?? '').isEmpty
        ? ''
        : _timeLabel(l, noti.createAt!, widget.now);
    // 역할은 목록이고 **안 읽은 줄만 버튼**이다(누르면 읽음). 시각 + ⋮ 는 줄 끝 — ⋮ 는 줄 버튼 안이 아니라 형제다.
    final suffix = PListSuffix(
      children: [
        if (time.isNotEmpty)
          // 웹과 같다 — t3 13 · fg-neutral-subtle
          Text(time, style: PTypography.t3.copyWith(color: c.fgNeutralSubtle)),
        PListAction(
          child: ds.PButton.icon(
            key: ValueKey('noti-more-${noti.rowId}'),
            icon: LucideIcons.ellipsisVertical,
            semanticLabel: l.notiMore(noti.title),
            variant: ds.PButtonVariant.ghost,
            ghostColor: ds.PButtonGhostColor.neutralSubtle,
            size: ds.PButtonSize.xsmall,
            onPressed: () => _openMenu(l),
          ),
        ),
      ],
    );
    final prefix = PListTile(
      background: toneBg,
      color: toneFg,
      child: Icon(_typeIcon()),
    );
    // 안 읽은 점은 제목 글 끝 바로 뒤 — 읽는 글 "안 읽음"
    final titleSuffix = <Widget>[
      if (_busy)
        PProgressCircle.inherit(
          diameter: 8,
          thickness: 1.5,
          trackColor: c.fgBrand.withValues(alpha: 0),
          rangeColor: c.fgBrand,
        )
      else if (unread)
        Semantics(
          label: l.notiUnreadMark,
          child: Container(
            key: const ValueKey('noti-unread-dot'),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.fgBrand, shape: BoxShape.circle),
          ),
        ),
    ];
    final message = (noti.message ?? '').isEmpty ? null : noti.message;
    return PTouchTargetScope(
      child: unread
          ? PListButtonItem(
              title: noti.title,
              detail: message,
              prefix: prefix,
              suffix: suffix,
              titleSuffix: titleSuffix,
              highlighted: true,
              align: PListAlign.top,
              endInset: 24,
              onTap: _busy ? null : _tap,
            )
          : PListItem(
              title: noti.title,
              detail: message,
              prefix: prefix,
              suffix: suffix,
              align: PListAlign.top,
              endInset: 24,
            ),
    );
  }

  /// ⋮ → Menu Sheet(제목 = 알림 제목, 위험 줄 "삭제" 하나) → 시트가 다 닫힌 뒤 Alert Dialog "알림 삭제".
  Future<void> _openMenu(AppLocalizations l) {
    return PMenuSheet.show(
      context,
      title: noti.title,
      groups: [
        PMenuSheetGroup([
          PMenuSheetItem(
            label: l.actionDelete,
            icon: LucideIcons.trash2,
            tone: PMenuSheetTone.critical,
            onSelect: _confirmDelete,
          ),
        ]),
      ],
    );
  }

  /// 삭제 확인 → 지움. 실패하면 확인창을 닫고 critical 스낵바 + [다시 시도](묻지 않고 바로). 공용 함수가 요청 실패를 삼키고
  /// 띠를 띄운다. 요청은 silent(저장소) · 뒷정리는 [_delete] 안(컨테이너)이라 줄이 사라진 뒤 다시 시도해도 죽지 않는다.
  Future<void> _confirmDelete() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    await askConfirmThenRequest(
      context,
      title: l.notiDeleteTitle,
      description: l.notiDeleteDescription,
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      request: widget.onDelete,
      failedMessage: l.notiDeleteFailed,
      retryLabel: l.actionRetry,
    );
  }

  /// 줄 끝 시각 — 오늘 묶음은 지난 시간(방금 전 · n분 전 · n시간 전), 다른 날 묶음은 시각("오후 9:00").
  ///
  /// [iso] 는 `createAt` — 백엔드가 시간대 없이 직렬화한 UTC 다. [parseServerUtc] 를 태워 로컬로 읽는다.
  String _timeLabel(AppLocalizations l, String iso, DateTime now) {
    final dt = parseServerUtc(iso);
    if (dt == null) return '';
    if (!widget.today) return timeOfDay12(dt);
    final diff = now.difference(dt);
    final m = diff.inMinutes;
    if (m < 1) return l.dateJustNow;
    if (m < 60) return l.dateMinutesAgo(m);
    return l.dateHoursAgo(diff.inHours);
  }
}
