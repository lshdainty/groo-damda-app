import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

/// 계좌 · 카드 고르기 시트의 본문 — 거래 시트 · 프리셋 · 반복 폼이 함께 쓴다.
///
/// 계좌 목록을 시트 안에서 지켜본다(`assetsProvider`). 세 상태를 가른다 — 못 받았으면 Result Section 실패 + [다시 시도]
/// (고정 글 · 서버 원문 없음, "고를 수 있는 계좌가 없어요" 로 읽히지 않게), 처음 받는 중이면 줄 Skeleton, 받았으면 [builder] 에
/// 받은 목록을 넘긴다(다시 받아 오면 시트를 닫지 않아도 목록이 채워진다). 다시 받는 동안은 실패를 그대로 두고 단추에 진행 원.
class AssetPickGate extends ConsumerWidget {
  const AssetPickGate({super.key, required this.builder});

  /// 받은 계좌 목록으로 본문을 그린다 — 거르기(이체 가능 · 결제 수단)는 부르는 쪽이 한다.
  final Widget Function(BuildContext context, List<Asset> assets) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assetsProvider);
    if (async.loadFailed) {
      final l = AppLocalizations.of(context);
      return Padding(
        key: const ValueKey('asset-pick-failure'),
        padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
        child: PResultSection(
          kind: PResultKind.failure,
          size: PResultSize.medium,
          title: l.txfAssetLoadFailed,
          description: l.dashFailDesc,
          primaryAction: PResultAction(
            label: l.actionRetry,
            loading: async.loadRetrying,
            onPressed: () => ref.invalidate(assetsProvider),
          ),
        ),
      );
    }
    if (!async.hasValue) return const _AssetPickSkeleton();
    return builder(context, async.requireValue);
  }
}

/// 처음 받는 중 — 줄 넷(Logo Tile 40 · 이름 t5 줄 높이, 웹 PickSkeleton 과 같은 수).
class _AssetPickSkeleton extends StatelessWidget {
  const _AssetPickSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('asset-pick-skeleton'),
    children: [
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
            vertical: PSpacing.x3,
          ),
          child: Row(
            spacing: PSpacing.x3,
            children: [
              const PSkeleton(
                width: PListTile.size,
                height: PListTile.size,
                radius: PSkeletonRadius.r12,
              ),
              // 이름 자리 — 남은 폭의 2/3(웹 PickSkeleton `w-2/3` 과 같다)
              Expanded(
                child: FractionallySizedBox(
                  widthFactor: 2 / 3,
                  alignment: Alignment.centerLeft,
                  child: PSkeleton.text(PTypography.t5),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
