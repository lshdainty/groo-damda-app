import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/features/settings/application/session_providers.dart';
import 'package:groo_damda_app/features/settings/domain/device_session.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/list_bleed_target.dart';

/// "로그인된 기기" — 계정 > 보안에서 들어온다. 흰 화면 하나(I-12 3-A).
///
/// 이 계정으로 살아 있는 세션을 기기별로 보여 주고, 낯선 기기를 끊게 한다.
/// 목록·해지 모두 desk 백엔드만 부른다(SSO 왕복 없음) — desk 가 로그인마다 자기
/// 세션 테이블에 한 행을 남기기 때문이다.
///
/// 안내 글 → 기기 줄(선 없음) → 위 24 → [모든 기기에서 로그아웃]. 기기가 없거나 못 불러오면 버튼은 없다.
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  /// 해지 중인 세션 — 그 행의 버튼만 잠근다. 목록 전체를 잠그면 다른 기기를
  /// 이어서 끊으려던 손이 멈춘다.
  String? _revoking;

  /// 확인 → 끊기. 확인창 뒤 실패는 공용 [askConfirmThenRequest] — critical 스낵바 + [다시 시도](묻지 않고 바로 끊음).
  /// 끊은 뒤 할 일(이 기기면 로그아웃, 아니면 목록 새로 받기)은 첫 요청과 다시 시도가 같다.
  Future<void> _revoke(DeviceSession device) async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    Future<void> after() async {
      // 지금 이 기기를 끊었으면 여기 머물 이유가 없다 — 로그인 화면으로 보낸다.
      if (device.current) {
        await container.read(authProvider.notifier).logout();
        return;
      }
      container.invalidate(deviceSessionListProvider);
    }

    final ok = await askConfirmThenRequest(
      context,
      title: l.devicesLogoutTitle(device.deviceLabel ?? l.devicesUnknown),
      description: l.devicesLogoutConfirm,
      cancelLabel: l.actionCancel,
      actionLabel: l.devicesLogout,
      request: () async {
        if (mounted) setState(() => _revoking = device.sessionId);
        try {
          final repo = await container.read(sessionRepositoryProvider.future);
          await repo.revoke(device.sessionId);
        } finally {
          if (mounted) setState(() => _revoking = null);
        }
      },
      failedMessage: l.devicesLogoutFailed,
      retryLabel: l.actionRetry,
      onRetried: () => after(),
    );
    if (ok) await after();
  }

  Future<void> _revokeAll() async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    // 전부 끊었으니 이 기기도 끊겼다. 화면에 남겨 두면 다음 요청마다 401 이 난다.
    // 성공 알림은 띄우지 않는다 — 확인창에서 "다시 로그인해야 해요" 라고 이미 말했고,
    // 로그인 화면으로 떨어지는 것 자체가 결과다.
    final ok = await askConfirmThenRequest(
      context,
      title: l.devicesLogoutAllTitle,
      description: l.devicesLogoutAllConfirm,
      cancelLabel: l.actionCancel,
      actionLabel: l.devicesLogoutAll,
      request: () async {
        final repo = await container.read(sessionRepositoryProvider.future);
        await repo.revokeAll();
      },
      failedMessage: l.devicesLogoutFailed,
      retryLabel: l.actionRetry,
      onRetried: () => container.read(authProvider.notifier).logout(),
    );
    if (ok) await container.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(deviceSessionListProvider);
    // 상대시각의 기준점 — 화면을 열어 둔 채로도 흐르게 한다(웹 `useNow` 정합).
    // 한 번 watch 해 행마다 내리면 모든 행이 같은 '지금' 을 쓴다.
    final now = ref.watch(nowTickProvider);

    return Scaffold(
      // 흰 화면 하나 — 띠 · 회색 바닥이 없다(T8 ~ T11)
      backgroundColor: c.bgLayerDefault,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-16 14)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.devicesTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: PPullToRefresh(
        onRefresh: () async {
          ref.invalidate(deviceSessionListProvider);
          await ref.read(deviceSessionListProvider.future);
        },
        child: ListView(
          key: const ValueKey('devices-body'),
          padding: EdgeInsets.only(
            bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            // 안내 — 위 16 · 좌우 24 · 아래 8 (T8 · T9)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x4,
                PSpacing.globalGutter,
                PSpacing.x2,
              ),
              child: Text(
                keepAll(l.devicesIntro),
                key: const ValueKey('devices-intro'),
                style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
            listAsync.when(
              // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
              skipError: true,
              loading: () => const _DevicesSkeleton(),
              error: (e, _) => PResultSection(
                kind: PResultKind.failure,
                size: PResultSize.medium,
                // 오류 원문은 화면에 내지 않는다
                title: l.devicesLoadError,
                description: l.devicesLoadErrorHint,
                primaryAction: PResultAction(
                  label: l.actionRetry,
                  loading: listAsync.loadRetrying,
                  onPressed: () => ref.invalidate(deviceSessionListProvider),
                ),
              ),
              data: (devices) => devices.isEmpty
                  ? PResultSection(
                      size: PResultSize.medium,
                      icon: LucideIcons.monitorOff300,
                      title: l.devicesEmpty,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PList(
                          semanticLabel: l.devicesTitle,
                          children: [
                            for (final d in devices)
                              _DeviceRow(
                                device: d,
                                now: now,
                                busy: _revoking == d.sessionId,
                                onRevoke: () => _revoke(d),
                              ),
                          ],
                        ),
                        // 비상 버튼이라 목록 아래에 둔다 — 위에 두면 기기 하나만
                        // 끊으려던 손이 먼저 닿는다. 위 24 · 좌우 24 (T11)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PSpacing.globalGutter,
                            PSpacing.x6,
                            PSpacing.globalGutter,
                            0,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: PButton(
                              label: l.devicesLogoutAll,
                              variant: PButtonVariant.ghost,
                              ghostColor: PButtonGhostColor.critical,
                              size: PButtonSize.large,
                              onPressed: _revokeAll,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 불러오는 중 — 줄 모양 Skeleton 셋(앞 22 사각 · 제목 40% · 설명 25%, 줄 위아래 12 · 좌우 24).
class _DevicesSkeleton extends StatelessWidget {
  const _DevicesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('devices-skeleton'),
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PSkeleton(
                  width: 22,
                  height: 22,
                  radius: PSkeletonRadius.r4,
                ),
                const SizedBox(width: PSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: PSkeleton.text(PTypography.t5),
                      ),
                      const SizedBox(height: PSpacing.x0_5),
                      FractionallySizedBox(
                        widthFactor: 0.25,
                        child: PSkeleton.text(PTypography.t3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 기기 한 줄 — 보기 줄(줄 자체는 누르지 않는다). 아이콘 22 + 이름(+현재 기기 배지) + 마지막 사용 + 뒤 [로그아웃].
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.now,
    required this.busy,
    required this.onRevoke,
  });

  final DeviceSession device;

  /// 상대시각의 기준점 — 호출부에서 `nowTickProvider` 로 받아 내린다.
  /// 기본값을 두지 않는 이유는 [_relativeTime] 주석 참고.
  final DateTime now;
  final bool busy;
  final VoidCallback onRevoke;

  /// 아이콘은 서버가 준 형태로 고른다 — 기기 이름 문자열을 여기서 다시 뜯지 않는다.
  IconData get _icon => switch (device.deviceKind) {
    DeviceKind.mobile => LucideIcons.smartphone,
    DeviceKind.tablet => LucideIcons.tablet,
    DeviceKind.desktop => LucideIcons.monitor,
    DeviceKind.unknown => LucideIcons.circleHelp,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final when = _relativeTime(l, device.activeAt, now);
    final name = device.deviceLabel ?? l.devicesUnknown;

    // 임시 — ds List 차례에 PListRowFrame 스코프로 걷는다(spec-cleanup-pending). 블리드 버튼의 밖을 이어 준다.
    return PTouchTargetScope(
      child: PListItem(
        // 이름이 두 줄을 넘는다 — 위에 맞춘다
        align: PListAlign.top,
        title: name,
        titleSuffix: device.current
            ? [
                PBadge(
                  label: l.devicesCurrent,
                  variant: PBadgeVariant.outline,
                  tone: PBadgeTone.positive,
                ),
              ]
            : null,
        detail: when == null ? null : l.devicesLastUsed(when),
        prefix: ExcludeSemantics(child: Icon(_icon)),
        // 오른쪽 14 블리드 — 글 끝이 화면 끝 24 에 선다. 누르는 영역은 44 까지.
        suffix: PListAction(
          // 보이는 36 · 블리드 14 밖(위아래 4 · 오른쪽 14)까지 누르는 영역을 넓힌다. 블리드로 부모 줄 상자 밖에
          // 나간 자리는 부모가 거절하므로 줄 위에서 PTouchTargetScope 가 이어 준다(Card 머리 동작과 같은 짝).
          // 임시 — ds List 차례에 PButton 누르는 영역 · PListRowFrame 스코프로 걷는다(spec-cleanup-pending).
          child: ListBleedTarget(
            bleed: kTextButtonPaddingX,
            child: Semantics(
              container: true,
              button: true,
              excludeSemantics: true,
              label: l.devicesLogoutLabel(name),
              onTap: busy ? null : onRevoke,
              child: PButton(
                label: l.devicesLogout,
                variant: PButtonVariant.ghost,
                size: PButtonSize.small,
                loading: busy,
                onPressed: onRevoke,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 서버가 준 `[UTC]` 시각 → "방금 · 3분 전 · 어제 · 2026-08-24".
///
/// [parseServerUtc] 를 거쳐야 한다 — 시간대 없는 문자열을 그대로 파싱하면 UTC 가
/// 로컬로 둔갑해 KST 에서 9시간이 어긋난다.
///
/// [now] 는 기준 시각이며 **인자로 받는다**. 여기서 [DateTime.now] 를 부르면 그 값은
/// 화면을 다시 그릴 때만 바뀌어, 기기 목록을 열어 둔 채로는 "방금" 에 멈춘다.
/// 넘길 값은 `nowTickProvider` 가 주는 흐르는 '지금' 이다. 기본값을 두면 안 넘긴
/// 호출부가 조용히 멈춘 시계로 돌아가므로 필수로 둔다.
String? _relativeTime(AppLocalizations l, String? iso, DateTime now) {
  final dt = parseServerUtc(iso);
  if (dt == null) return null;
  final diff = now.difference(dt);
  final m = diff.inMinutes;
  if (m < 1) return l.dateJustNow;
  if (m < 60) return l.dateMinutesAgo(m);
  final h = diff.inHours;
  if (h < 24) return l.dateHoursAgo(h);
  final d = diff.inDays;
  if (d == 1) return l.dateYesterday;
  if (d < 7) return l.dateDaysAgo(d);
  return formatDay(dt).md;
}
