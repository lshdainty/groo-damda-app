import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/actions/item_actions.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart'
    as ds;

/// 자산 하나에 할 수 있는 일 — 상세 시트와 목록 행이 같은 것을 부른다.
///
/// 삭제는 원래 편집 폼 세 곳(계좌·카드·투자)의 State 안에 각각 있었다. 셋이 거의
/// 같은 코드였는데 투자만 평가액 무효화가 한 줄 더 있어서, 나머지 둘에 같은 줄이
/// 필요해지는 날 한 곳만 고쳐질 수밖에 없는 모양이었다. 삭제가 상세로 올라오면서
/// 그 코드를 옮겨야 했고, 옮기는 김에 셋을 하나로 합쳤다.
const assetActions = AssetActions();

/// 자산 종류 — l10n 키와 무효화 범위가 이걸로 갈린다.
enum _AssetKind { account, card, invest }

class AssetActions implements ItemActions<Asset> {
  const AssetActions();

  @override
  bool canDelete(Asset a) => true;

  @override
  bool canEdit(Asset a) => true;

  @override
  String deleteConfirmTitle(BuildContext context, Asset a) {
    final l = AppLocalizations.of(context);
    return switch (_kindOf(a)) {
      _AssetKind.account => l.assetAccountDelete,
      _AssetKind.card => l.assetCardDelete,
      _AssetKind.invest => l.assetInvestDelete,
    };
  }

  @override
  String deleteConfirmMessage(BuildContext context, Asset a) {
    final l = AppLocalizations.of(context);
    return switch (_kindOf(a)) {
      _AssetKind.account => l.assetAccountDeleteConfirm(a.assetName),
      _AssetKind.card => l.assetCardDeleteConfirm(a.assetName),
      _AssetKind.invest => l.assetInvestDeleteConfirm(a.assetName),
    };
  }

  @override
  Future<bool> delete(BuildContext context, WidgetRef ref, Asset a) async {
    try {
      await _request(ProviderScope.containerOf(context), a);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// 확인창 → 삭제. 실패하면 확인창이 닫힌 뒤 critical 스낵바 + [다시 시도](묻지 않고 바로 요청).
  /// 요청은 silent 라 전역 서버 원문 토스트와 겹치지 않는다. 성공은 true — 바로 성공했을 때만 돌려받고,
  /// [다시 시도] 로 성공하면 [onRetried] 가 불린다(둘 다 같은 뒷정리를 해야 한다).
  Future<bool> confirmAndDelete(
    BuildContext context,
    Asset a, {
    VoidCallback? onRetried,
  }) {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    return askConfirmThenRequest(
      context,
      title: deleteConfirmTitle(context, a),
      description: deleteConfirmMessage(context, a),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      request: () => _request(container, a),
      failedMessage: l.assetDetailDeleteFailed,
      retryLabel: l.actionRetry,
      onRetried: onRetried,
    );
  }

  /// 서버에 지우고 뒷정리까지 — 던지면 호출처가 실패로 본다. 위젯 수명과 무관하게 container 로만 한다.
  Future<void> _request(ProviderContainer container, Asset a) async {
    final kind = _kindOf(a);
    final repo = await container.read(assetRepositoryProvider.future);
    await repo.delete(a.rowId, silent: true);
    // 자산이 하나 늘거나 줄면 순자산·추이·청구·실적이 함께 달라진다 —
    // 전부 별도 조회라 목록만 비우면 옛 값이 남는다.
    for (final p in <ProviderOrFamily>[
      assetsProvider,
      assetSummaryProvider,
      netWorthTrendProvider,
      assetByIdProvider,
      cardBillingProvider,
      cardPerformanceProvider,
      // 투자는 잔액이 보유수량 × 시세라, 자산만 무효화하면 지워진 종목의 평가액이
      // 캐시에 남아 합계가 어긋난다.
      if (kind == _AssetKind.invest) investmentValuationMapProvider,
    ]) {
      container.invalidate(p);
    }
  }

  /// 밀면 나오는 [수정, 삭제](I-17 28) — 줄을 누르면 상세로 간다(밀기는 지름길이다). 삭제는 상세에서 지울 때와 같은 확인 글을 먼저 묻는다.
  List<ds.PSwipeAction> dsSwipeActions(
    BuildContext context,
    WidgetRef ref,
    Asset a,
  ) {
    final l = AppLocalizations.of(context);
    return [
      if (canEdit(a))
        ds.PSwipeAction(
          label: l.actionEdit,
          icon: LucideIcons.pencil,
          kind: ds.PSwipeActionKind.primary,
          onSelect: () => edit(context, ref, a),
        ),
      if (canDelete(a))
        ds.PSwipeAction(
          label: l.actionDelete,
          icon: LucideIcons.trash2,
          kind: ds.PSwipeActionKind.destructive,
          onSelect: () => confirmAndDelete(context, a),
        ),
    ];
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Asset a) async {
    showAssetEditForm(context, a);
  }

  /// [showAssetEditForm] 의 분기와 같은 기준 — 편집 폼이 갈리는 대로 삭제 문구도 갈린다.
  _AssetKind _kindOf(Asset a) => switch (a.assetType) {
    'INVESTMENT' => _AssetKind.invest,
    'CREDIT_CARD' || 'CHECK_CARD' => _AssetKind.card,
    _ => _AssetKind.account,
  };
}
