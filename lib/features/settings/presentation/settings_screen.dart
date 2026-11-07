import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

class _SettingsItem {
  const _SettingsItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.external = false,
    this.desc,
  });
  final String label;

  /// 앞 아이콘 22 — 웹 `SECTIONS` 의 아이콘과 같은 이름(I-12 9).
  final IconData icon;
  final void Function(BuildContext ctx) onTap;

  /// 바깥 주소로 가는 줄(처리방침 · 설명서) — 링크 줄.
  final bool external;

  /// 줄 설명 — 웹 설정과 같은 글(List 줄 설명 자리).
  final String? desc;
}

class _SettingsGroup {
  const _SettingsGroup({required this.label, required this.items});
  final String label;
  final List<_SettingsItem> items;
}

List<_SettingsGroup> _buildGroups(BuildContext ctx) {
  final l = AppLocalizations.of(ctx);
  return [
    _SettingsGroup(
      label: l.settingsGroupDataMgmt,
      items: [
        _SettingsItem(
          label: l.settingsMenuCategory,
          desc: l.settingsDescCategory,
          icon: LucideIcons.tag,
          onTap: (c) => c.push('/categories'),
        ),
        _SettingsItem(
          label: l.settingsMenuAccountCard,
          desc: l.settingsDescAccountCard,
          icon: LucideIcons.creditCard,
          onTap: (c) => c.push('/account-card-manage'),
        ),
        _SettingsItem(
          label: l.settingsMenuBudget,
          desc: l.settingsDescBudget,
          icon: LucideIcons.filePen,
          // 웹 정합: 전체 > 설정 > 예산 설정 → BudgetManager 페이지 (개요 /budget 아님).
          onTap: (c) => c.push('/budget/settings'),
        ),
        _SettingsItem(
          label: l.navSavingGoals,
          desc: l.settingsDescSavingGoal,
          icon: LucideIcons.piggyBank,
          onTap: (c) => c.push('/saving-goals'),
        ),
        _SettingsItem(
          label: l.settingsMenuRecurring,
          desc: l.settingsDescRecurring,
          icon: LucideIcons.repeat,
          onTap: (c) => c.push('/recurring'),
        ),
        _SettingsItem(
          label: l.settingsMenuPreset,
          desc: l.settingsDescPreset,
          icon: LucideIcons.bookmark,
          onTap: (c) => c.push('/presets'),
        ),
      ],
    ),
    // 태그 · 라벨 — design screens-settings.jsx 신판(할 일 태그 + 캘린더 라벨).
    _SettingsGroup(
      label: l.settingsGroupTagsLabels,
      items: [
        _SettingsItem(
          label: l.settingsMenuTodoTag,
          desc: l.settingsDescTodoTag,
          icon: LucideIcons.tags,
          onTap: (c) => c.push('/settings/todo-tags'),
        ),
        // 메모 태그는 할 일 태그 바로 아래다 — 웹 설정도 같은 순서로 놓는다.
        _SettingsItem(
          label: l.settingsMenuMemoTag,
          desc: l.settingsDescMemoTag,
          icon: LucideIcons.notebookTabs,
          onTap: (c) => c.push('/settings/memo-tags'),
        ),
        _SettingsItem(
          label: l.settingsMenuCalendarLabel,
          desc: l.settingsDescCalendarLabel,
          icon: LucideIcons.tag,
          onTap: (c) => c.push('/settings/calendar-labels'),
        ),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupShare,
      items: [
        _SettingsItem(
          label: l.settingsMenuCalendarShare,
          desc: l.settingsDescCalendarShare,
          icon: LucideIcons.calendarCog,
          onTap: (c) => c.push('/settings/calendar-share'),
        ),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupApp,
      items: [
        _SettingsItem(
          label: l.settingsMenuAppearance,
          desc: l.settingsDescAppearance,
          icon: LucideIcons.palette,
          onTap: (c) => c.push('/settings/appearance'),
        ),
        // 알림 '목록' 이 아니라 알림 '설정' 으로 간다 — 내비 라벨(navNotifications,
        // 종 아이콘이 여는 목록)을 여기 쓰면 같은 말이 두 화면을 가리킨다.
        // 화면 제목과 같은 키를 쓴다(위 표시 설정·아래 업데이트와 같은 방식).
        _SettingsItem(
          label: l.notiSettings,
          desc: l.settingsDescNotifications,
          icon: LucideIcons.bell,
          onTap: (c) => c.push('/settings/notifications'),
        ),
        // 스토어를 안 쓰니 새 버전을 알 데가 없다. 예전엔 앱을 열 때마다 알렸는데
        // 받을 생각이 없는 사람에겐 매번 걷어내야 하는 벽이라, 확인은 이 자리로 모았다.
        _SettingsItem(
          label: l.updateTitle,
          icon: LucideIcons.refreshCw,
          onTap: (c) => c.push('/settings/update'),
        ),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupData,
      items: [
        _SettingsItem(
          label: l.exportTitle,
          desc: l.settingsDescExport,
          icon: LucideIcons.download,
          onTap: (c) => c.push('/settings/export-data'),
        ),
      ],
    ),
    // 계정 → 도움말 차례 — 웹 설정 · 데스크톱 왼쪽 목록과 같다(I-12 Q1 결정 A).
    _SettingsGroup(
      label: l.settingsGroupAccount,
      items: [
        // 메뉴 이름 = 그 화면의 제목 — 화면 제목 `accountTitle` 과 같은 키를 쓴다.
        _SettingsItem(
          label: l.accountTitle,
          desc: l.settingsDescAccount,
          icon: LucideIcons.user,
          onTap: (c) => c.push('/account'),
        ),
        _SettingsItem(
          label: l.settingsMenuPrivacyPolicy,
          desc: l.settingsDescPrivacyPolicy,
          icon: LucideIcons.shieldCheck,
          onTap: _openPrivacyPolicy,
          external: true,
        ),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupHelp,
      items: [
        _SettingsItem(
          label: l.settingsMenuGuide,
          desc: l.settingsDescGuide,
          icon: LucideIcons.bookOpen,
          onTap: _openGuide,
          external: true,
        ),
      ],
    ),
    // 개발 전용 — 새 컴포넌트 라이브러리 카탈로그(lib/shared/ds/catalog). 운영 빌드에는
    // 길도 이 줄도 없다(kDebugMode). 개발 도구라 글은 l10n 을 거치지 않는다.
    if (kDebugMode)
      _SettingsGroup(
        label: '개발',
        items: [
          _SettingsItem(
            label: '컴포넌트 카탈로그',
            icon: LucideIcons.code,
            onTap: (c) => c.push('/dev/ds'),
          ),
        ],
      ),
  ];
}

/// 개인정보 처리방침을 브라우저로 연다.
///
/// 문서는 SSO 에 한 벌만 두고(계정·인증을 SSO 가 총괄) 웹·앱 모두 그곳을 가리킨다.
/// 앱에 문구를 복사해 두면 개정 때 한쪽만 고쳐져 내용이 갈라진다.
Future<void> _openPrivacyPolicy(BuildContext ctx) async {
  final l = AppLocalizations.of(ctx);
  final uri = Uri.parse('${Env.ssoUrl}/privacy');

  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // 처리 가능한 앱이 없으면 예외로 떨어진다 — 아래에서 함께 알린다
  }

  // 눌렀는데 아무 일도 안 일어나는 게 제일 나쁘다
  if (!ctx.mounted) return;
  PSnackbar.maybeOf(
    ctx,
  )?.show(message: l.settingsPrivacyOpenFailed, tone: PSnackbarTone.critical);
}

/// 설명서(porest-desk-guide)를 브라우저로 연다.
///
/// 설명서는 desk 웹과 같은 호스트의 /guide/ 에 한 벌만 떠 있다 — 앱에 문서를 복사하지 않는다.
Future<void> _openGuide(BuildContext ctx) async {
  final l = AppLocalizations.of(ctx);
  final uri = Uri.parse('${Env.webBaseUrl}/guide/');

  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // 처리 가능한 앱이 없으면 예외로 떨어진다 — 아래에서 함께 알린다
  }

  if (!ctx.mounted) return;
  PSnackbar.maybeOf(
    ctx,
  )?.show(message: l.settingsGuideOpenFailed, tone: PSnackbarTone.critical);
}

/// 줄 뒤 화살표 — 18 · 옅은 색은 줄이 입힌다(PListRowFrame). 장식이라 읽지 않는다.
const Widget _chevron = ExcludeSemantics(child: Icon(LucideIcons.chevronRight));

/// 설정 메뉴(폰) — 흰 면 하나(I-12 1-B · 1-2A · 1-3A).
///
/// 상단 바(← "설정") → 계정 줄 → 묶음 일곱(목록 제목 + 줄) → 끝 여백. 띠를 나누지 않고 묶음은
/// 목록 제목(boldSolid) + 위 16 으로 가른다. 줄 앞 아이콘 22 는 웹 `SECTIONS` 의 아이콘이다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.value;
    final groups = _buildGroups(context);

    return Scaffold(
      // 흰 화면 하나 — 띠 · 회색 바닥이 없다(T1 ~ T3)
      backgroundColor: context.colors.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.navSettings,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: ListView(
        key: const ValueKey('settings-menu'),
        // 끝 여백 24 — 흰 면 안(T3), 안전 영역은 더한다
        padding: EdgeInsets.only(
          bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // 내 정보 — 받는 동안은 Skeleton 줄, 정보가 없거나 실패면 줄을 숨긴다
          if (user != null)
            _AccountRow(
              name: user.userName.isNotEmpty
                  ? user.userName
                  : l.accountDefaultName,
              // 둘째 줄 = 이메일(I-12 Q1(d)), 없으면 "계정 관리"
              detail: user.userEmail.isNotEmpty
                  ? user.userEmail
                  : l.settingsMenuAccountMgmt,
              onTap: () => context.push('/account'),
            )
          else if (auth.isLoading)
            const _AccountRowSkeleton(),

          for (final group in groups)
            // 목록 제목 위 16 — 첫 묶음도 계정 줄 아래 16(T2)
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PListHeader(
                    title: group.label,
                    variant: PListHeaderVariant.boldSolid,
                  ),
                  PList(
                    semanticLabel: group.label,
                    children: [
                      for (final item in group.items)
                        item.external
                            ? PListLinkItem(
                                title: item.label,
                                detail: item.desc,
                                prefix: ExcludeSemantics(
                                  child: Icon(item.icon),
                                ),
                                suffix: _chevron,
                                onTap: () => item.onTap(context),
                              )
                            : PListButtonItem(
                                title: item.label,
                                detail: item.desc,
                                prefix: ExcludeSemantics(
                                  child: Icon(item.icon),
                                ),
                                suffix: _chevron,
                                onTap: () => item.onTap(context),
                              ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 계정 줄 — List 누르는 줄 + 앞 Avatar 42(이니셜 + 이름 색). 제목 = 이름, 설명 = 이메일(없으면 "계정 관리").
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.name,
    required this.detail,
    required this.onTap,
  });

  final String name;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PListButtonItem(
      key: const ValueKey('settings-account-row'),
      title: name,
      detail: detail,
      // 이름이 길면 두 줄 · 이메일이 길면 줄바꿈 — 아바타는 위에 맞춘다
      align: PListAlign.center,
      prefix: PAvatar(name: name, size: PAvatarSize.s42),
      suffix: _chevron,
      onTap: onTap,
    );
  }
}

/// 사용자 정보를 받는 동안의 자리 — 원 42 + 제목 · 설명 막대(줄 값 그대로: 위아래 12 · 좌우 24 · 앞 붙이개 뒤 12).
class _AccountRowSkeleton extends StatelessWidget {
  const _AccountRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('settings-account-skeleton'),
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.globalGutter,
        vertical: PSpacing.x3,
      ),
      child: Row(
        children: [
          const PSkeleton(width: 42, height: 42, radius: PSkeletonRadius.full),
          const SizedBox(width: PSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PSkeleton.text(PTypography.t5, width: 120),
                const SizedBox(height: PSpacing.x0_5),
                PSkeleton.text(PTypography.t3, width: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
