import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 증권 라우트 가드 — 구독(SECURITIES) 미보유 시 홈으로 리다이렉트(딥링크 직접 접근 차단).
/// 메뉴 숨김은 UX, 이 가드는 클라이언트 차단(서버는 별도 403 게이트).
///
/// **조회 실패는 "권한 없음" 이 아니다.** 실패하면 홈으로 보내지 않고 그 자리에서 [다시 시도] 를 준다.
/// 이미 받아 둔 값이 있으면(다시 받기만 실패) 그 값을 그대로 쓴다 — 재조회 실패로 Pro 사용자를 내보내지 않는다.
class SecuritiesGate extends ConsumerWidget {
  const SecuritiesGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(myFeaturesLoadProvider);
    final value = features.value;
    if (value == null) {
      if (features.loadFailed) {
        return SecuritiesLoadFailure(
          retrying: features.loadRetrying,
          onRetry: () => ref.invalidate(myFeaturesLoadProvider),
        );
      }
      // 첫 진입 — 틀(상단 바)을 그리고 콘텐츠 영역 가운데 Progress Circle 40(progress-circle.md "첫 진입" — 틀 없이 가운데
      // 원 하나는 두지 않는다). Material 기본 원은 쓰지 않는다
      return const _SecuritiesFrame(
        body: Center(
          child: PProgressCircle(key: ValueKey('securities-gate-loading')),
        ),
      );
    }
    if (!value.hasSecurities) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return child;
  }
}

/// 증권 권한 · 연결 조회 실패 — 화면 자리에서 말하고 [다시 시도] 를 준다(뒤로 가기는 상단 바).
class SecuritiesLoadFailure extends StatelessWidget {
  const SecuritiesLoadFailure({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });
  final VoidCallback onRetry;

  /// 다시 받는 중 — [다시 시도] 에 진행 원.
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _SecuritiesFrame(
      body: PResultSection(
        key: const ValueKey('securities-load-failed'),
        kind: PResultKind.failure,
        title: l.secLoadFailed,
        description: l.subLoadFailedDesc,
        primaryAction: PResultAction(
          label: l.actionRetry,
          loading: retrying,
          onPressed: onRetry,
        ),
      ),
    );
  }
}

/// 증권 가드의 틀 — 상단 바(← · "증권") + 한 장 흰 띠 본문. 불러오는 중 · 실패가 같은 틀을 쓴다.
class _SecuritiesFrame extends StatelessWidget {
  const _SecuritiesFrame({required this.body});

  final Widget body;

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
      body: PScreenBandBody(child: body),
    );
  }
}
