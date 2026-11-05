import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/lock/app_lock_toggle.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/settings/application/oauth_link_providers.dart';
import 'package:groo_damda_app/features/settings/data/oauth_link_repository.dart';
import 'package:groo_damda_app/features/settings/presentation/password_change_dialog.dart';
import 'package:groo_damda_app/features/settings/presentation/withdrawal_sheet.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/list_bleed_target.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

/// 계정 화면 — 흰 화면 하나(I-14 1-B · 14-1).
///
/// 머리(아바타 80 · 이름 · 이메일 · [수정] · 배지 · 가입 달)는 카드 없이 흰 면 위에 서고, 아래는 목록 제목
/// (boldSolid · 위 16) + 줄 묶음 다섯 — 보안 · 연결된 계정 · 구독·결제 · (Pro 일 때) 증권 데이터 연동 · 계정 관리. 띠 ·
/// 회색 틈 · 줄 사이 선이 없다. 웹 `AccountSection` 의 폰 갈래와 같은 줄 · 같은 글이다.
///
/// 기능 연동: 프로필 표시, 비밀번호 변경, 앱 잠금, Google 연결 · 해제, 로그아웃.
/// 2단계 인증 스위치는 뺐다 — 켜도 서버·로컬 어디에도 남지 않고 백엔드에 2FA 자체가
/// 없다. 문구 키(`accountTwoFa`)는 남겨 둔다(웹 desk-front #360 과 같은 처리).
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with WidgetsBindingObserver {
  /// Google 연결을 시작해 브라우저에 가 있는 동안 — 버튼이 `loading` 이다.
  bool _linking = false;
  bool _unlinking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 브라우저에서 그냥 돌아온 경우(딥링크가 없다) — 목록을 다시 받고 `loading` 을 푼다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_linking) return;
    setState(() => _linking = false);
    ref.invalidate(oauthProvidersProvider);
  }

  void _toast(String message, PSnackSeverity severity) {
    if (!mounted) return;
    showPSnackBar(context, message, severity: severity);
  }

  Future<void> _link() async {
    if (_linking) return;
    final l = AppLocalizations.of(context);
    setState(() => _linking = true);
    try {
      final repo = await ref.read(oauthLinkRepositoryProvider.future);
      final startUrl = await repo.startLink('google', Env.oauthLinkReturnUri);
      // 로그인과 같은 까닭으로 시스템 브라우저 — 복귀는 딥링크 리스너가 받는다.
      final launched = await launchUrl(
        Uri.parse(startUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('browser');
      // 흐름이 앱 밖으로 나갔다 — loading 은 돌아올 때(resumed · 딥링크) 푼다.
    } catch (_) {
      if (!mounted) return;
      setState(() => _linking = false);
      _toast(l.accountLinkError, PSnackSeverity.error);
    }
  }

  Future<void> _unlink() async {
    if (_unlinking) return;
    final l = AppLocalizations.of(context);
    setState(() => _unlinking = true);
    try {
      final repo = await ref.read(oauthLinkRepositoryProvider.future);
      await repo.unlink('google');
    } catch (_) {
      // 서버 거절(마지막 로그인 수단 · 네트워크 오류 포함)은 글을 가르지 않고 고정 글 하나(웹과 같다)
      if (mounted) {
        setState(() => _unlinking = false);
        // 다시 시도 — 같은 해제를 다시 요청한다(snackbar.md:71)
        showPSnackBar(
          context,
          l.accountUnlinkError,
          severity: PSnackSeverity.error,
          duration: const Duration(seconds: 6),
          actionLabel: l.actionRetry,
          onAction: _unlink,
        );
      }
      return;
    }
    _toast(l.accountUnlinkedToast, PSnackSeverity.success);
    try {
      // 목록을 다시 받은 뒤 푼다 — 줄이 이전 상태로 잠깐 되돌아 보이지 않게. 다시 받기 실패는 줄이 [다시 시도] 로 말한다
      ref.invalidate(oauthProvidersProvider);
      await ref.read(oauthProvidersProvider.future);
    } catch (_) {
      // 해제는 이미 됐다 — 실패 알림을 띄우지 않는다
    } finally {
      if (mounted) setState(() => _unlinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;
    final subscriptionAsync = ref.watch(mySubscriptionProvider);
    final subscription = subscriptionAsync.asData?.value;
    final hasSecurities = ref.watch(hasSecuritiesProvider);
    final appLockOn = ref.watch(appLockEnabledProvider);
    final hiddenCount =
        ref.watch(settingsProvider).value?.hideCards.length ?? 0;
    final hiddenTotal = kAllHideCards.length;
    final isSubscribed = subscription?.isActive ?? false;
    // currentPeriodEnd 는 서버 UTC 시각 — 자르면 KST 밤 결제분의 갱신일이 하루
    // 앞으로 보인다(구독 화면과 같은 규칙). 못 읽는 값만 잘라 쓴다.
    final periodEnd =
        subscription?.currentPeriodEnd != null &&
            subscription!.currentPeriodEnd!.length >= 10
        ? (localDateKey(subscription.currentPeriodEnd) ??
              subscription.currentPeriodEnd!.substring(0, 10))
        : null;
    // 유예 기간(해지했는데 기간이 남음)에는 다음 결제가 없다 — 그 날짜는 결제일이
    // 아니라 이용이 끝나는 날이다. 구독 시트와 같은 문구를 쓴다.
    final proDesc = !isSubscribed
        ? l.accountProPromo
        : (periodEnd != null && !subscription!.autoRenew)
        ? l.subProUntil(periodEnd)
        : '${periodEnd != null ? l.accountNextBilling(periodEnd) : ''}'
              '${l.accountProActive}';
    // 값은 서버 가격 — 불러오는 중이면 값 자리 Skeleton, 실패면 값 없이 설명만(I-14 34)
    final Widget? priceText =
        subscriptionAsync.isLoading && !subscriptionAsync.hasValue
        ? SizedBox(width: 72, child: PSkeleton.text(PTypography.t4))
        : isSubscribed && subscription?.price != null
        ? Text(
            subscription!.durationMonths == 12
                ? l.subPricePerYear(
                    krwSigned(subscription.price!, false, unit: true),
                  )
                : l.subPricePerMonth(
                    krwSigned(subscription.price!, false, unit: true),
                  ),
            textAlign: TextAlign.end,
          )
        : null;
    final name = user?.userName.isNotEmpty == true
        ? user!.userName
        : l.accountDefaultName;

    return Scaffold(
      // 흰 화면 하나 — 띠 · 회색 바닥이 없다(T1 ~ T5)
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.accountTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: ListView(
        key: const ValueKey('account-body'),
        // 맨 아래 24 + 안전 영역(T5) — 흰 면이 화면 끝까지 닿는다
        padding: EdgeInsets.only(
          bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _AccountHead(
            name: name,
            email: user?.userEmail ?? '',
            isPro: isSubscribed,
            joined: user?.joinedAt == null
                ? null
                : l.accountJoined(yearMonth(user!.joinedAt!)),
          ),
          // ── 보안
          _Group(
            label: l.accountSecurity,
            children: [
              PListButtonItem(
                prefix: _icon(LucideIcons.keyRound),
                title: l.navChangePassword,
                detail: l.accountPasswordDesc,
                onTap: () => showPasswordChangeDialog(context),
              ),
              // 앱 잠금 — 로그인 세션과 별개로 앱 자체를 생체인증으로 잠근다. 켤 때만 인증을 거친다.
              // 상태는 스위치가 말한다 — 옛 "사용 중 · 사용 안 함" 글은 걷었다.
              PListSwitchItem(
                prefix: _icon(LucideIcons.fingerprint),
                title: l.appLockTitle,
                checked: appLockOn,
                onChanged: (v) => setAppLockWithAuth(context, ref, v),
              ),
              // 금액 가리기 — 화면·카드 37장을 훑는 목록이라 자기 화면으로 보낸다. 몇 장을 가렸는지 줄에서 보인다.
              PListButtonItem(
                prefix: _icon(
                  hiddenCount == 0 ? LucideIcons.eye : LucideIcons.eyeOff,
                ),
                title: l.hideAmountsTitle,
                suffix: PListSuffix(
                  children: [
                    Text(
                      '$hiddenCount / $hiddenTotal',
                      textAlign: TextAlign.end,
                    ),
                    const Icon(LucideIcons.chevronRight),
                  ],
                ),
                onTap: () => context.push('/settings/hide-amounts'),
              ),
              PListButtonItem(
                prefix: _icon(LucideIcons.monitor),
                title: l.accountDevices,
                suffix: PListSuffix(
                  children: [
                    Text(l.accountCurrentDevice, textAlign: TextAlign.end),
                    const Icon(LucideIcons.chevronRight),
                  ],
                ),
                onTap: () => context.push('/settings/devices'),
              ),
            ],
          ),
          // ── 연결된 계정 — 연결할 수 있는 소셜은 Google 하나다(I-14 10)
          _Group(
            label: l.accountConnected,
            children: [
              _GoogleRow(
                linking: _linking,
                unlinking: _unlinking,
                onLink: _link,
                onUnlink: _unlink,
              ),
            ],
          ),
          // ── 구독·결제 — 14-1 은 지금 구독 시트를 연다(꺾쇠 없음 · 가격은 지금 값, 14-2 가 페이지 · 서버 값으로)
          _Group(
            label: l.accountBilling,
            children: [
              PListButtonItem(
                // 설명이 두 줄을 넘을 수 있어 위에 맞춘다
                align: PListAlign.top,
                prefix: _icon(LucideIcons.sparkles),
                title: '담다 Pro',
                detail: proDesc,
                suffix: PListSuffix(
                  children: [?priceText, const Icon(LucideIcons.chevronRight)],
                ),
                onTap: () => context.push('/settings/subscription'),
              ),
            ],
          ),
          // ── 증권 데이터 연동 — 구독(Pro) 시에만. 증권사가 둘 이상이라 화면으로 분리했다.
          if (hasSecurities)
            _Group(
              label: l.subBrokerSectionTitle,
              children: [
                PListButtonItem(
                  prefix: _icon(LucideIcons.link),
                  title: l.settingsSecuritiesLink,
                  detail: l.accountSecuritiesDesc,
                  suffix: const Icon(LucideIcons.chevronRight),
                  onTap: () => context.push('/settings/securities'),
                ),
              ],
            ),
          // ── 계정 관리 — 로그아웃 · 이용 해지는 확인 · 시트를 여는 줄이라 꺾쇠가 없다
          _Group(
            label: l.accountManage,
            children: [
              PListButtonItem(
                prefix: _icon(LucideIcons.logOut),
                title: l.navLogout,
                detail: l.accountLogoutDesc,
                onTap: () => _confirmLogout(context, ref),
              ),
              PListButtonItem(
                prefix: _icon(LucideIcons.trash2, color: c.fgCritical),
                title: l.accountWithdraw,
                titleColor: c.fgCritical,
                detail: l.accountWithdrawDesc,
                onTap: () => showWithdrawalSheet(context),
              ),
            ],
          ),
          // 앱 버전 — 화면 맨 아래에 조용히 둔다. 스토어를 안 거치니 지금 깔린 게 어느 빌드인지 알 데가 여기밖에 없다.
          const _AppVersionLine(),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    // ds 확인창 — 다시 로그인하면 돌아오는 일이라 빨강이 아니다(neutralSolid).
    final ok = await PAlertDialog.show(
      context,
      title: l.navLogout,
      description: l.accountLogoutConfirm,
      actionLabel: l.navLogout,
      cancelLabel: l.actionCancel,
    );
    if (ok) {
      ref.read(authProvider.notifier).logout();
    }
  }
}

/// 줄 앞 아이콘 — 크기 · 색은 줄이 입힌다(22 · `fg-neutral`). 이름은 제목이 말한다.
Widget _icon(IconData icon, {Color? color}) =>
    ExcludeSemantics(child: Icon(icon, color: color));

/// 묶음 — 목록 제목(boldSolid · 위 16) + 목록. 묶음이 이어져도 띠 · 틈이 없다(T2 · T3).
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: PSpacing.x4),
        PListHeader(title: label, variant: PListHeaderVariant.boldSolid),
        PList(semanticLabel: label, children: children),
      ],
    );
  }
}

/// 머리 — 카드 없이 흰 면 위, 가운데 맞춤 세로. 위 24 · 좌우 24, 맨 끝은 이유 Callout(그 아래 16 은 목록 제목의 위 16, T1 · T2).
class _AccountHead extends StatelessWidget {
  const _AccountHead({
    required this.name,
    required this.email,
    required this.isPro,
    required this.joined,
  });

  final String name;
  final String email;
  final bool isPro;
  final String? joined;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('account-head'),
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x6,
        PSpacing.globalGutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PAvatar(name: name, size: PAvatarSize.s80),
          const SizedBox(height: PSpacing.x3),
          // 이름은 낱말 단위로 줄을 바꾸고, 낱말이 한 줄보다 길면 칸 끝에서 끊는다
          Text(
            keepAll(name),
            key: const ValueKey('account-name'),
            textAlign: TextAlign.center,
            style: PTypography.t7.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: PSpacing.x1),
            // 이메일은 끊을 자리가 없다 — keepAll 을 쓰지 않고 줄 끝에서 끊는다
            Text(
              email,
              key: const ValueKey('account-email'),
              textAlign: TextAlign.center,
              style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
          const SizedBox(height: PSpacing.x3),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x2,
            children: [
              // [수정] 은 개인정보 변경 자리 — 아직 열리지 않아 막아 둔다(D3 B: 누르면 가짜 알림이 뜨던 것을 걷는다)
              Semantics(
                hint: l.accountEditComingSoon,
                child: PButton(
                  label: l.actionEdit,
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: null,
                ),
              ),
              PBadge(
                label: isPro ? 'Pro' : 'Free',
                tone: isPro ? PBadgeTone.brand : PBadgeTone.neutral,
              ),
            ],
          ),
          if (joined != null) ...[
            const SizedBox(height: PSpacing.x2),
            Text(
              joined!,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
          // 막은 단추의 이유 줄(D3 B) — 머리 바로 아래 16, 읽는 이름은 이 글과 잇는다
          const SizedBox(height: PSpacing.x4),
          PCallout(
            key: const ValueKey('account-edit-callout'),
            tone: PCalloutTone.informative,
            description: l.accountEditComingSoon,
          ),
        ],
      ),
    );
  }
}

/// Google 줄 — 남는 연결된 계정 줄. 줄 자체는 누르지 않고 뒤 버튼만 누른다(I-14 10).
///
/// 서버 목록은 카카오 · 네이버도 주지만 연결할 수 없어 `GOOGLE` 하나만 그린다. 불러오는 중에는 설명 자리에
/// Skeleton + 버튼 막힘, 실패하면 설명 "연결 상태를 불러오지 못했어요" + [다시 시도]. 실패 글은 서버 글이 아니라 고정 글이다.
class _GoogleRow extends ConsumerWidget {
  const _GoogleRow({
    required this.linking,
    required this.unlinking,
    required this.onLink,
    required this.onUnlink,
  });

  final bool linking;
  final bool unlinking;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final providers = ref.watch(oauthProvidersProvider);
    // 실패는 이전 값이 남아 있어도 실패다(해제 · 복귀 뒤 다시 받기가 실패하면 옛 "연결됨" 대신 [다시 시도]) — 웹과 같다
    final failed = providers.hasError;
    final loading =
        providers.isLoading && !providers.hasValue && !providers.hasError;
    final google = providers.value
        ?.where((p) => p.type == 'GOOGLE')
        .cast<OAuthProviderInfo?>()
        .firstOrNull;
    final linked = google?.linked ?? false;

    final String? detail = loading
        ? null
        : failed
        ? l.accountProvidersError
        : linked
        ? l.accountLinked
        : l.accountNotConnected;

    final String label;
    final bool busy;
    final VoidCallback? onPressed;
    if (failed) {
      label = l.actionRetry;
      busy = providers.isLoading;
      onPressed = () => ref.invalidate(oauthProvidersProvider);
    } else if (linked) {
      label = l.accountDisconnect;
      busy = unlinking;
      onPressed = loading ? null : onUnlink;
    } else {
      label = l.accountConnect;
      busy = linking;
      onPressed = loading ? null : onLink;
    }

    // 임시 — ds List 차례에 PListRowFrame 스코프로 걷는다(spec-cleanup-pending). 블리드 버튼의 밖을 이어 준다.
    return PTouchTargetScope(
      child: PListItem(
        prefix: ExcludeSemantics(
          child: SizedBox.square(
            dimension: 22,
            child: Center(
              child: Text(
                'G',
                style: PTypography.t5.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        title: 'Google',
        detail: detail,
        detailChild: loading
            ? SizedBox(width: 96, child: PSkeleton.text(PTypography.t3))
            : null,
        // 바탕이 보이는 버튼 — 상자 끝이 끝선 24 에 선다(오른쪽 블리드 없음). 위아래 겹침 · 누르는 영역 44 는 그대로.
        suffix: PListAction(
          child: ListBleedTarget(
            bleed: 0,
            child: Semantics(
              container: true,
              button: true,
              excludeSemantics: true,
              label: failed ? label : 'Google $label',
              onTap: busy ? null : onPressed,
              child: PButton(
                label: label,
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.small,
                loading: busy,
                onPressed: onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 앱 버전과 최신 여부 한 줄 — 위 16 · 좌우 24(T4), 아래 24 는 목록의 끝 여백이 준다(T5).
///
/// 버전을 읽기 전에는 아무것도 그리지 않는다 — 빈 자리가 잠깐 보였다 채워지는 게
/// 자리만 잡아 두는 것보다 낫다.
///
/// 최신 여부는 새 버전 확인과 같은 근거(`/download/version.json`)를 쓴다. 그 요청이
/// 실패해도 provider 가 null 을 주므로 "최신"으로 보인다 — 서버를 못 읽었다고 굳이
/// 알릴 일은 아니고, 홈 배너도 같은 조건이라 두 곳이 어긋나지 않는다.
class _AppVersionLine extends ConsumerWidget {
  const _AppVersionLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);

    final version = ref.watch(appVersionProvider).value;
    if (version == null) return const SizedBox.shrink();

    final statusAsync = ref.watch(updateStatusProvider);
    final status = statusAsync.value;
    final hasUpdate = status?.hasUpdate ?? false;

    // 서버를 못 읽었으면 아무 말도 안 한다 — "최신이에요" 는 실제로 비교해 봤을 때만.
    // 못 읽은 걸 최신으로 적으면 서버가 죽어 있는 동안 새 버전을 영영 모른다.
    final suffix = statusAsync.isLoading || status == null || status.checkFailed
        ? null
        : hasUpdate
        ? l.accountAppVersionUpdate(status.latest!.version)
        : l.accountAppVersionLatest;

    return Padding(
      key: const ValueKey('account-version'),
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x4,
        PSpacing.globalGutter,
        0,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: l.accountAppVersion(version)),
            if (suffix != null) ...[
              const TextSpan(text: ' · '),
              TextSpan(
                text: suffix,
                // 새 버전이 있을 때만 눈에 걸리게. 최신이면 나머지와 같은 톤으로 묻는다.
                style: hasUpdate
                    ? TextStyle(color: c.fgBrand, fontWeight: FontWeight.w700)
                    : null,
              ),
            ],
          ],
        ),
        style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
      ),
    );
  }
}
