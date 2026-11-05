import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as ds;
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_progress.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';

/// 알림 목록(I-15 41 ~ 44) — 상단 바(← "알림" + ⚙ "알림 설정") → 흰 면 하나: 목록 머리 "읽지 않은 알림 N개" +
/// 오른쪽 글 버튼 "모두 읽음" → 날짜 묶음("10월 23일 (금) · 오늘") + 줄. 바닥 고정 띠는 없다.
/// 줄 누름 = 읽음(이동하지 않는다) · 줄 끝 ⋮ → 삭제(확인창을 거친다).
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final listAsync = ref.watch(notificationListProvider);
    // {n} 은 서버가 센 안 읽은 수 — 받아 온 줄(최근 100개)로 세지 않는다. 아직 못 받았으면 받아 온 줄로 잠깐 채운다.
    final serverUnread = ref.watch(unreadCountProvider).value;
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
          loading: () => const _NotiSkeleton(),
          error: (e, _) => ListView(
            children: [
              PResultSection(
                kind: PResultKind.failure,
                title: l.notiLoadFailed,
                description: l.notiLoadFailedDesc,
                primaryAction: PResultAction(
                  label: l.actionRetry,
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
            final unread = serverUnread ?? items.where((n) => !n.isRead).length;
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
                      noti: n,
                      tokens: t,
                      now: now,
                      today: groups[g].isToday,
                      onTap: () async {
                        if (!n.isRead) {
                          try {
                            final repo = await ref.read(
                              notificationRepositoryProvider.future,
                            );
                            await repo.markRead(n.rowId);
                            ref.invalidate(notificationListProvider);
                            ref.invalidate(unreadCountProvider);
                          } catch (_) {}
                        }
                      },
                      onDelete: () => _delete(ref, n),
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
Future<void> _delete(WidgetRef ref, AppNotification n) async {
  final repo = await ref.read(notificationRepositoryProvider.future);
  await repo.delete(n.rowId);
  ref.invalidate(notificationListProvider);
  ref.invalidate(unreadCountProvider);
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
  final yesterdayKey = todayKey.subtract(const Duration(days: 1));
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
        const Padding(
          padding: EdgeInsets.fromLTRB(
            PSpace.x24,
            PSpace.x12,
            PSpace.x24,
            PSpace.x8,
          ),
          child: PSkeleton.line(width: 120, height: 14),
        ),
        for (var i = 0; i < 5; i++) ...[
          if (i == 0 || i == 3)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                PSpace.x24,
                PSpace.x16,
                PSpace.x24,
                PSpace.x8,
              ),
              child: PSkeleton.line(width: 140, height: 14),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x24,
              vertical: PSpace.x12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PSkeleton(
                  width: 40,
                  height: 40,
                  borderRadius: PRadius.brMd,
                ),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PSkeleton.line(width: i.isEven ? 140 : 100, height: 14),
                      const SizedBox(height: 4),
                      const PSkeleton.line(width: double.infinity, height: 12),
                      const SizedBox(height: 4),
                      const PSkeleton.line(width: 180, height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: PSkeleton.line(width: 36, height: 12),
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
    required this.noti,
    required this.tokens,
    required this.now,
    required this.today,
    required this.onTap,
    required this.onDelete,
  });
  final AppNotification noti;
  final GrooTokens tokens;

  /// 상대시각의 기준점 — 호출부에서 `nowTickProvider` 로 받아 내린다.
  ///
  /// 기본값을 두지 않는다. 기본값이 있으면 안 넘긴 호출부가 조용히 [DateTime.now] 로
  /// 돌아가 그 자리만 다시 얼어붙는데, 화면은 멀쩡해 보여 눈으로는 못 잡는다.
  /// 필수로 두면 새 호출부가 생겨도 컴파일이 먼저 붙잡는다.
  final DateTime now;

  /// 오늘 묶음 안의 줄인가 — 오늘 것만 "n시간 전", 다른 날 묶음은 시각("오후 9:00")이다(Q6 B).
  final bool today;

  /// 읽음 처리 — 비동기. 끝날 때까지 행이 스피너를 띄우고 잠긴다.
  final Future<void> Function() onTap;

  /// 지우기 — 메뉴(⋮)의 "삭제" 를 고르고 확인창에서 삭제를 누르면 부른다. 끝날 때까지 확인창이 로딩이다.
  final Future<void> Function() onDelete;

  @override
  State<_NotiRow> createState() => _NotiRowState();
}

class _NotiRowState extends State<_NotiRow> {
  /// notificationType → lucide 아이콘. SoT(notificationVisual) 매핑 정합:
  /// BUDGET_ALERT→AlertTriangle / TODO_REMINDER→ListChecks /
  /// EVENT_REMINDER→CalendarClock / SYSTEM·default→Bell.
  IconData _typeIcon() => switch (noti.notificationType) {
    'BUDGET_ALERT' => LucideIcons.alertTriangle,
    'TODO_REMINDER' => LucideIcons.squareCheckBig,
    'EVENT_REMINDER' => LucideIcons.calendarClock,
    _ => LucideIcons.bell,
  };

  /// notificationType 별 (바탕, 아이콘) — 차트 색의 옅은 바탕 + 그 색(list.md Prefix 타일).
  /// 예산 orange · 할 일 blue · 일정 green · 시스템 gray.
  (Color, Color) _typeTone(PColors c) => switch (noti.notificationType) {
    'BUDGET_ALERT' => (c.chartOrangeWeak, c.chartOrange),
    'TODO_REMINDER' => (c.chartBlueWeak, c.chartBlue),
    'EVENT_REMINDER' => (c.chartGreenWeak, c.chartGreen),
    _ => (c.chartGrayWeak, c.chartGray),
  };

  AppNotification get noti => widget.noti;
  GrooTokens get tokens => widget.tokens;
  DateTime get now => widget.now;
  Future<void> Function() get onDelete => widget.onDelete;

  // 읽음 처리 진행 중 — 안 읽음 점 자리에 스피너, 탭 잠금. 통신이 느리면 눌렀는지
  // 알 수 없어 다시 누르게 됐다(사용자 신고).
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
    final unread = !noti.isRead;
    final c = context.colors;
    final (toneBg, toneFg) = _typeTone(c);
    // SEED List 줄(9-1 · 9-2) — 타일 40 · 제목 16/400 · 설명 13 muted · 시각 13 subtle, 안 읽음은 bg-brand-weak + 점.
    // 역할은 목록이고 **안 읽은 줄만 버튼**이다(누르면 읽음). 읽은 줄은 눌리지 않는다.
    // 읽음 처리를 누르는 자리(왼쪽 내용)와 ⋮ 는 형제다 — ⋮ 를 줄 버튼 안에 넣지 않는다.
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x12,
        PSpace.x4,
        PSpace.x12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: toneBg,
              borderRadius: BorderRadius.circular(PRounded.r2_5),
            ),
            alignment: Alignment.center,
            child: Icon(_typeIcon(), size: 20, color: toneFg),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 — 줄바꿈(말줄임 없음). 안 읽은 점은 제목 글 끝 바로 뒤 6.
                Text.rich(
                  TextSpan(
                    text: noti.title,
                    children: [
                      if (_busy) ...[
                        const WidgetSpan(child: SizedBox(width: 6)),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: PCircularProgressIndicator(
                            size: 8,
                            strokeWidth: 1.5,
                            color: c.fgBrand,
                          ),
                        ),
                      ] else if (unread) ...[
                        const WidgetSpan(child: SizedBox(width: 6)),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            key: const ValueKey('noti-unread-dot'),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.fgBrand,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  style: PTypography.t5.copyWith(color: c.fgNeutral),
                ),
                if ((noti.message ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    noti.message!,
                    style: PTypography.t3.copyWith(color: c.fgNeutralMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 시각은 우측 상단(웹 정합 — 좌측=내용, 우측=시각+⋮).
          if ((noti.createAt ?? '').isNotEmpty) ...[
            const SizedBox(width: PSpace.x8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _timeLabel(l, noti.createAt!, now),
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
          ],
        ],
      ),
    );
    final row = Container(
      color: unread ? c.bgBrandWeak : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: unread
                ? Semantics(
                    button: true,
                    enabled: !_busy,
                    child: InkWell(onTap: _busy ? null : _tap, child: content),
                  )
                : content,
          ),
          // ⋮ — 폰에서는 떠 있는 메뉴가 아니라 Menu Sheet 다. 지우기는 확인창을 거친다(되돌릴 수 없는 동작)
          Padding(
            padding: const EdgeInsets.only(top: PSpace.x12, right: PSpace.x24),
            // ds 아이콘 버튼 — xsmall 32 · ghost neutralSubtle(웹과 같다). 누르는 영역 44 는 버튼이 넓힌다
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
      ),
    );
    return row;
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

  /// 삭제 확인(ds Alert Dialog) → 지움. 실패하면 확인창을 닫고 critical 스낵바 + [다시 시도](묻지 않고 같은 삭제를 바로).
  /// 요청은 전역 오류 알림을 끈다 — 서버 글을 내보내지 않는다. 띠는 앱 뿌리 호스트에 있어 줄이 사라져도 남으므로 호스트 · 글을 미리 잡는다.
  Future<void> _confirmDelete() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.maybeOf(context);
    Object? failure;
    final ok = await PAlertDialog.show(
      context,
      title: l.notiDeleteTitle,
      description: l.notiDeleteDescription,
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
      onAction: () async {
        try {
          await onDelete();
        } catch (e) {
          failure = e;
        }
      },
    );
    if (ok && failure != null) _deleteFailed(snack, l);
  }

  void _deleteFailed(PSnackbarApi? snack, AppLocalizations l) {
    snack?.show(
      message: l.notiDeleteFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () async {
          try {
            await onDelete();
          } catch (_) {
            _deleteFailed(snack, l);
          }
        },
      ),
    );
  }

  /// 줄 끝 시각 — 오늘 묶음은 지난 시간(방금 전 · n분 전 · n시간 전), 다른 날 묶음은 시각("오후 9:00").
  ///
  /// [iso] 는 `createAt` — 백엔드가 시간대 없이 직렬화한 UTC 다. [parseServerUtc] 를 태워 로컬로 읽는다.
  /// [now] 는 기준 시각이며 **인자로 받는다** — `nowTickProvider` 가 주는 흐르는 '지금'.
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
