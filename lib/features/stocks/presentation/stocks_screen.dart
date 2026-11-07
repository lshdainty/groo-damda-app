import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/presentation/securities_gate.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 증권 화면 셸 — 헤더와 증권사 선택을 소유하고 본문만 갈아 끼운다.
///
/// **탭 하나가 그 증권사 한 벌이다.** 호가·체결·오늘 시세·투자자별·장 상태·주문 가능 금액은 두 증권사가
/// 같은 띠 틀로 보여 주고, 토스만(지수·순위·수수료율)·나무만(채권·금현물 등)은 그 증권사 본문에만 둔다.
/// 데이터는 그 탭의 증권사 경로(`/toss/**` · `/namu/**`)로 부른다.
///
/// 가계부 자산은 반대다 — 필요한 게 시세뿐이라 사용자가 고른 기본 소스 하나로 통합돼 있다.
class StocksScreen extends ConsumerStatefulWidget {
  const StocksScreen({super.key});

  @override
  ConsumerState<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends ConsumerState<StocksScreen> {
  String? _broker;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // 개인키 미연결 시 전 화면 연결 유도 (mock 노출 금지). 증권사 API 는 시세 포함 모든
    // 조회가 개인키 토큰을 요구하므로, 어느 증권사든 하나는 연결돼 있어야 조회가 된다.
    // 실패는 "연결 안 됨" 이 아니다 — 원본(실패를 던지는 쪽)을 읽어 실패면 그 자리에서 다시 시도를 준다.
    // 받아 둔 값이 있으면(다시 받기만 실패) 그 값을 그대로 쓴다.
    final featuresAsync = ref.watch(myFeaturesLoadProvider);
    final features = featuresAsync.value;
    final connected = features?.connectedBrokers ?? const <String>[];

    if (featuresAsync.loadFailed) {
      return SecuritiesLoadFailure(
        retrying: featuresAsync.loadRetrying,
        onRetry: () => ref.invalidate(myFeaturesLoadProvider),
      );
    }
    if (!featuresAsync.isLoading && connected.isEmpty) {
      return const _ConnectGate();
    }

    // 연결된 증권사 중에서 고른다. 저장된 선택이 끊겼으면 기본 소스 → 첫 연결 순으로 되돌린다.
    final active = connected.contains(_broker)
        ? _broker!
        : (connected.contains(features?.primaryBroker)
              ? features!.primaryBroker!
              : (connected.isEmpty ? '' : connected.first));

    return Scaffold(
      backgroundColor: context.colors.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-13 5)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.moreItemStocks,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Column(
        children: [
          // 연결이 하나뿐이면 고를 게 없다 — 줄을 감춘다. 증권사 고르기는 1차 Line 탭(Fill · medium 44)이고,
          // 화면 전체를 조절하므로 첫 띠와 한 덩어리다(틈 0 — T1 · T2).
          if (connected.length > 1)
            ColoredBox(
              color: context.colors.bgLayerDefault,
              child: PTabs<String>(
                value: active,
                onChanged: (v) => setState(() => _broker = v),
                size: PTabsSize.medium,
                semanticLabel: l.moreItemStocks,
                items: [
                  for (final b in connected)
                    PTab(value: b, label: _brokerLabel(l, b)),
                ],
              ),
            ),
          Expanded(child: _body(active)),
        ],
      ),
    );
  }

  Widget _body(String broker) {
    // 모르는 증권사 코드는 서버가 앞서 나갔다는 뜻이다 — 빈 화면 대신 안내를 띄운다.
    return switch (broker) {
      'TOSS' => const TossStocksView(),
      'NAMU' => const NamuStocksView(),
      _ => const _UnsupportedBroker(),
    };
  }

  /// 탭 라벨. 앱이 아는 증권사는 자기 번역을, 모르면 코드를 그대로 쓴다 —
  /// 서버가 증권사를 먼저 늘려도 탭이 비지 않는다.
  String _brokerLabel(AppLocalizations l, String broker) => switch (broker) {
    'TOSS' => l.brokerToss,
    'NAMU' => l.brokerNamu,
    _ => broker,
  };
}

/// 앱이 모르는 증권사 — 서버가 앞서 나간 구간.
class _UnsupportedBroker extends StatelessWidget {
  const _UnsupportedBroker();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: PScreenSection(
        child: PText(
          l.stocksBrokerUnsupported,
          textAlign: TextAlign.center,
          style: PTypo.bodySm.copyWith(color: t.fgTertiary),
        ),
      ),
    );
  }
}

/// 연결 0 — Result Section empty "처음"(I-13 Q4 안 A 결정). 끊김(연결은 있는데 조회가 막힘) Page Banner 는 13b:
/// 서버가 토큰 만료 · 키 해지를 다른 오류와 가르지 않는다(`TossApiClient` 가 401 을 한 번 재시도한 뒤 모든 업스트림 오류를
/// `SECURITIES_API_ERROR` 하나로 바꾸고 본문 코드는 로그에만 둔다) — 구분 코드가 생긴 뒤에 넣는다.
class _ConnectGate extends StatelessWidget {
  const _ConnectGate();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.moreItemStocks,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: PScreenBandBody(
        child: PResultSection(
          kind: PResultKind.empty,
          icon: LucideIcons.plug,
          title: l.stocksConnectEmptyTitle,
          description: l.stocksConnectEmptyDesc,
          primaryAction: PResultAction(
            label: l.stocksConnectEmptyAction,
            // 연결은 증권사 연동 화면에서 한다.
            onPressed: () => context.push('/settings/securities'),
          ),
        ),
      ),
    );
  }
}
