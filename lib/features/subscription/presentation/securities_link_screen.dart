import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/broker_connect_card.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/widgets/p_back_button.dart';
import 'package:groo_damda_app/shared/widgets/p_empty_state.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';

/// 증권사 연동 화면.
///
/// 예전에는 토스 키 입력이 계정 설정 안에 인라인 카드로 덩그러니 있었다. 증권사가 둘 이상이
/// 되면 그 자리에 카드를 쌓을 수 없어 화면으로 분리했다.
///
/// **목록은 서버가 준다.** 미연결 증권사까지 내려오므로 증권사가 늘어도 앱 배포 없이 나타난다.
///
/// 키 · 시크릿 칸에 친 값이 있으면 나가기 전에 묻는다(안드로이드 뒤로 · 예측형 뒤로 · 앱바 ←, I-wrap-b2b 5) — 금액 가리기 화면과
/// 같은 확인창 · 같은 PopScope 방식이다. 요청이 나가 있는 동안은 묻지 않고 막는다.
class SecuritiesLinkScreen extends ConsumerStatefulWidget {
  const SecuritiesLinkScreen({super.key});

  @override
  ConsumerState<SecuritiesLinkScreen> createState() =>
      _SecuritiesLinkScreenState();
}

class _SecuritiesLinkScreenState extends ConsumerState<SecuritiesLinkScreen> {
  /// 친 값이 있는 증권사 · 요청이 나가 있는 증권사.
  final Set<String> _dirty = {};
  final Set<String> _busy = {};

  void _mark(Set<String> set, String broker, bool on) {
    if (!mounted) return;
    setState(() => on ? set.add(broker) : set.remove(broker));
  }

  /// 저장하지 않고 나가려 할 때 — 친 값이 사라지는 걸 알리고, 확인하면 화면을 닫는다(금액 가리기와 같은 글).
  Future<void> _confirmDiscardAndPop() async {
    final l = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.hideAmountsDiscardTitle,
      description: l.securitiesLeaveBody,
      actionLabel: l.hideAmountsDiscardConfirm,
      destructive: true,
      cancelLabel: l.actionCancel,
    );
    if (ok && mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final connectionsAsync = ref.watch(brokerConnectionsProvider);

    return PopScope(
      canPop: _dirty.isEmpty && _busy.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        // 요청이 나가 있는 동안은 묻지 않고 막는다 — 묻는 확인창은 그 뒤에만
        if (didPop || !mounted || _busy.isNotEmpty) return;
        _confirmDiscardAndPop();
      },
      child: Scaffold(
        backgroundColor: context.colors.bgLayerBasement,
        appBar: AppBar(
          leadingWidth: PBackButton.leadingWidth,
          titleSpacing: 0,
          // 화면의 PopScope 를 지나게 — 친 값이 있으면 묻는다
          leading: PBackButton(onPressed: () => Navigator.maybePop(context)),
          title: Text(l.settingsSecuritiesLink),
          backgroundColor: t.bgSurface,
          foregroundColor: t.fgPrimary,
          elevation: 0,
        ),
        body: PScreenBandBody(
          child: connectionsAsync.when(
            // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
            skipError: true,
            loading: () => const _LoadingList(),
            error: (_, _) => Center(
              child: PEmptyState(
                icon: LucideIcons.unplug,
                message: l.securitiesLoadError,
              ),
            ),
            data: (connections) => _List(
              connections: connections,
              onDirty: (b, on) => _mark(_dirty, b, on),
              onBusy: (b, on) => _mark(_busy, b, on),
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.connections,
    required this.onDirty,
    required this.onBusy,
  });

  final List<BrokerConnection> connections;
  final void Function(String broker, bool on) onDirty;
  final void Function(String broker, bool on) onBusy;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 연결이 하나뿐이면 기본 소스를 고를 게 없다 — 버튼을 감춘다.
    final connectedCount = connections.where((c) => c.connected).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: [
        Text(
          l.settingsSecuritiesLinkDesc,
          style: PTypo.caption.copyWith(color: t.fgSecondary, height: 1.6),
        ),
        const SizedBox(height: PSpace.x16),
        for (final c in connections) ...[
          BrokerConnectCard(
            connection: c,
            showPrimaryAction: connectedCount > 1,
            onDirtyChanged: (on) => onDirty(c.broker, on),
            onBusyChanged: (on) => onBusy(c.broker, on),
          ),
          const SizedBox(height: PSpace.x12),
        ],
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: const [
        PSkeleton(height: 180),
        SizedBox(height: PSpace.x12),
        PSkeleton(height: 180),
      ],
    );
  }
}
