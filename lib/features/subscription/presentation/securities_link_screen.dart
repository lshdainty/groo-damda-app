import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/broker_status.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 증권사 연동 — 첫 단계: 증권사 줄 목록(결정 B, I-wrap-b1 β).
///
/// 줄 하나 = 증권사 하나(로고 타일 · 이름 · 기본 배지 · 상태 글 · ›). 줄을 누르면 **별도 라우트**
/// `/settings/securities/:broker` 로 간다 — 키 입력 · 해제 · 기본 지정은 [BrokerConnectScreen] 이 맡는다. 같은 화면 안에서
/// 단계를 바꾸며 PopScope 로 ← 를 가로채지 않는다(예측형 뒤로가기가 깨진다). 이 화면에는 입력이 없어 PopScope 도 없다.
///
/// **목록은 서버가 준다.** 미연결 증권사까지 내려오므로 증권사가 늘어도 앱 배포 없이 나타난다.
class SecuritiesLinkScreen extends ConsumerWidget {
  const SecuritiesLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final connectionsAsync = ref.watch(brokerConnectionsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.settingsSecuritiesLink,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: PScreenBandBody(
        child: connectionsAsync.when(
          // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
          skipError: true,
          loading: () => const _LoadingList(),
          error: (_, _) => connectionsAsync.isLoading
              // 다시 받는 중 — 오류를 들고 있어도 진행 표시(눌렀는데 아무 일도 없어 보이지 않게)
              ? const _LoadingList()
              : PResultSection(
                  key: const ValueKey('securities-list-failed'),
                  kind: PResultKind.failure,
                  title: l.securitiesLoadError,
                  description: l.subLoadFailedDesc,
                  primaryAction: PResultAction(
                    label: l.actionRetry,
                    onPressed: () => ref.invalidate(brokerConnectionsProvider),
                  ),
                ),
          data: (connections) => _List(connections: connections),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.connections});

  final List<BrokerConnection> connections;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x4,
            PSpacing.globalGutter,
            PSpacing.x2,
          ),
          child: Text(
            keepAll(l.settingsSecuritiesLinkDesc),
            style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
        PList(
          semanticLabel: l.settingsSecuritiesLink,
          children: [
            for (final b in connections)
              PListButtonItem(
                key: ValueKey('broker-row-${b.broker}'),
                prefix: PLogoTile(name: b.displayName),
                title: b.displayName,
                titleSuffix: [if (b.primary) PBadge(label: l.subBrokerPrimary)],
                detail: brokerStatusText(l, b),
                suffix: const ExcludeSemantics(
                  child: Icon(LucideIcons.chevronRight),
                ),
                onTap: () => context.push(
                  '/settings/securities/${Uri.encodeComponent(b.broker)}',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('securities-list-skeleton'),
      children: [
        for (var i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: Row(
              spacing: PSpacing.x3,
              children: [
                const PSkeleton(
                  width: 40,
                  height: 40,
                  radius: PSkeletonRadius.r6,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x1,
                    children: [
                      PSkeleton.text(PTypography.t5, width: 96),
                      PSkeleton.text(PTypography.t4, width: 140),
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
