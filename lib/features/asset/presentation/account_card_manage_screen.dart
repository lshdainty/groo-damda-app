import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_actions.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_edit_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_parts.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 계좌·카드 관리(I-17 25 ~ 33, 1-B) — 탭 없이 흰 면 하나에 종류별 묶음 한 목록.
///
/// 상단 바(← 제목 + 글 버튼 "추가") 아래 묶음(목록 제목 + 합계 · 줄)이 이어진다. 묶음은 자산 화면과 같은 차례 · 같은 이름이다 —
/// 계좌·예금 → 투자 → 카드 → 대출. 줄을 누르면 상세(17-3 전에는 옛 상세), 밀면 [수정, 삭제].
/// 묶음 사이에 회색 틈은 없다(T1 ~ T3) — 같은 이야기(자산)가 이어지는 한 면이다.
enum _Group { account, invest, card, loan }

const Map<_Group, Set<String>> _groupTypes = {
  _Group.account: {'BANK_ACCOUNT', 'SAVINGS', 'CASH'},
  _Group.invest: {'INVESTMENT'},
  _Group.card: {'CREDIT_CARD', 'CHECK_CARD'},
  _Group.loan: {'LOAN'},
};

/// 계좌·예금 · 카드는 늘 보이고, 투자 · 대출은 있을 때만(자산 화면과 같은 조건).
const _alwaysShown = {_Group.account, _Group.card};

/// 묶음이 말하는 빚 — 합계를 빼기 부호로 보인다(자산 화면의 카드 · 대출 합계와 같다).
const _debtGroups = {_Group.card, _Group.loan};

String _groupTitle(AppLocalizations l, _Group g) => switch (g) {
  _Group.account => l.assetGroupAccount,
  _Group.invest => l.assetGroupInvestment,
  _Group.card => l.assetGroupCard,
  _Group.loan => l.assetGroupDebt,
};

class AccountCardManageScreen extends ConsumerStatefulWidget {
  const AccountCardManageScreen({super.key, this.editAssetId});

  /// 들어오자마자 수정 폼을 열 자산 — 목록에 없으면(지워진 자산) 목록만 보여 준다.
  final int? editAssetId;

  @override
  ConsumerState<AccountCardManageScreen> createState() =>
      _AccountCardManageScreenState();
}

class _AccountCardManageScreenState
    extends ConsumerState<AccountCardManageScreen> {
  /// [AccountCardManageScreen.editAssetId] 를 한 번만 연다 — 폼을 닫고 목록이 다시
  /// 그려질 때마다 또 열리면 빠져나갈 수 없다.
  bool _editHandled = false;

  /// 연동 투자 평가액 갱신 — 자산 화면과 같은 10초 주기, **화면 하나에 타이머 하나**다(줄마다 두지 않는다).
  /// 자산 화면의 타이머는 그 탭이 앞이 아니면 멈추므로(이 화면이 위에 있으면 멈춘다) 여기서 따로 돌린다.
  /// 같은 provider · 같은 갱신 함수를 쓰니 두 화면의 값이 같다. 앱이 뒤로 가면 멈춘다.
  Timer? _valuationTimer;

  @override
  void initState() {
    super.initState();
    ref.listenManual(appForegroundProvider, (_, _) => _syncValuationTimer());
    Future.microtask(_syncValuationTimer);
  }

  void _syncValuationTimer() {
    if (!mounted) return;
    if (!ref.read(appForegroundProvider)) {
      _valuationTimer?.cancel();
      _valuationTimer = null;
      return;
    }
    if (_valuationTimer != null) return;
    _valuationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) refreshLiveValuation(ref.invalidate);
    });
  }

  @override
  void dispose() {
    _valuationTimer?.cancel();
    super.dispose();
  }

  /// 목록이 처음 도착하면 그 자산의 수정 폼(2단계)을 연다.
  ///
  /// 인증은 폼의 몫이다 — 금액을 가린 자산은 숨김을 푸는 저장에서 본인 확인을
  /// 거친다(자산 상세 [수정]으로 들어온 것과 같은 폼이다). 탭이 없으니 옮길 곳도 없다.
  void _openRequestedEdit(List<Asset> assets) {
    if (_editHandled) return;
    final id = widget.editAssetId;
    if (id == null) return;
    _editHandled = true;
    final asset = assets.byRowId(id);
    if (asset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAssetEditForm(context, asset);
    });
  }

  /// [추가] — 묶음을 미리 고르지 않고 1단계(종류 고르기)부터 연다(I-17 8).
  void _onAdd() => showAssetAddFlow(context);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('asset.manage'));
    final assetsAsync = ref.watch(assetsProvider);
    // 값이 아직 없을 때만 "처음 불러오는 중 · 실패" 다 — 다시 받는 동안은 앞 값을 그대로 둔다.
    final failed = assetsAsync.loadFailed;
    final loading = !failed && assetsAsync.isLoading && !assetsAsync.hasValue;

    return Scaffold(
      // 흰 면 하나(25) — 회색 바닥도 띠도 없다
      backgroundColor: context.colors.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.assetManageTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
          // 추가는 상단 바 글 버튼 하나(26) — 묶음마다 [○○ 추가] 를 두지 않는다
          actions: [
            PTopNavigationTextButton(
              label: l.assetManageAdd,
              onPressed: _onAdd,
            ),
          ],
        ),
      ),
      body: PSwipeActionsProvider(
        child: Builder(
          builder: (context) {
            if (loading) return const _ManageSkeleton();
            if (failed) {
              return _CenteredResult(
                kind: PResultKind.failure,
                title: l.assetManageLoadFailed,
                description: l.dashFailDesc,
                action: PResultAction(
                  label: l.actionRetry,
                  loading: assetsAsync.loadRetrying,
                  onPressed: () => ref.invalidate(assetsProvider),
                ),
              );
            }
            final raw = assetsAsync.value ?? const <Asset>[];
            _openRequestedEdit(raw);
            // 자산 화면과 같은 라이브 평가액(`value` — 다시 받는 동안 앞 값을 든다)으로 치환한다
            final invMap =
                ref.watch(investmentValuationMapProvider).value ??
                const <int, InvestmentValuation>{};
            final assets = applyLiveValuation(raw, liveValuationMap(invMap));
            if (assets.isEmpty) {
              // 자산 0개 — 상단 바 "추가" 가 있으니 버튼은 두지 않는다(31)
              return _CenteredResult(
                kind: PResultKind.empty,
                icon: LucideIcons.landmark,
                title: l.assetEmptyState,
                description: l.assetManageEmptyHint,
              );
            }
            return _ManageList(
              assets: assets,
              masked: masked,
              originals: {for (final a in raw) a.rowId: a},
            );
          },
        ),
      ),
    );
  }
}

/// 폰 흰 면 위 결과 — 화면 전체를 차지하는 large.
class _CenteredResult extends StatelessWidget {
  const _CenteredResult({
    required this.kind,
    required this.title,
    required this.description,
    this.icon,
    this.action,
  });

  final PResultKind kind;
  final String title;
  final String description;
  final IconData? icon;
  final PResultAction? action;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
        child: PResultSection(
          kind: kind,
          size: PResultSize.large,
          icon: icon,
          title: title,
          description: description,
          primaryAction: action,
        ),
      ),
    ],
  );
}

class _ManageList extends ConsumerWidget {
  const _ManageList({
    required this.assets,
    required this.masked,
    required this.originals,
  });

  final List<Asset> assets;
  final Map<int, Asset> originals;

  /// 이 화면의 금액 가리기 카드 — 켜지면 합계 · 줄 금액이 모두 점이다(자산 하나의 가림과 합집합).
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final shown = [
      for (final g in _Group.values)
        if (_alwaysShown.contains(g) ||
            assets.any((a) => _groupTypes[g]!.contains(a.assetType)))
          g,
    ];
    return ListView(
      // 끝 여백 24 는 흰 면 안(T3)
      padding: EdgeInsets.only(
        bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        for (var i = 0; i < shown.length; i++)
          _GroupSection(
            // 글 위치 = 목록 제목의 바깥 위 여백 + list-header.yaml 안쪽 위 8(paddingY).
            // 첫 묶음 8 + 8 = 16(바 아래 → 글) · 그다음 16 + 8 = 24(앞 줄 아래 → 글). 웹과 같다.
            topInset: i == 0 ? PSpacing.x4 : PSpacing.x6,
            title: _groupTitle(l, shown[i]),
            items: [
              for (final a in assets)
                if (_groupTypes[shown[i]]!.contains(a.assetType)) a,
            ],
            debt: _debtGroups.contains(shown[i]),
            masked: masked,
            originals: originals,
            invest: shown[i] == _Group.invest,
          ),
      ],
    );
  }
}

/// 묶음 하나 — 목록 제목(boldSolid + 오른쪽 합계) 아래 줄들. 합계는 자산 화면과 한 함수다.
class _GroupSection extends ConsumerWidget {
  const _GroupSection({
    required this.topInset,
    required this.title,
    required this.items,
    required this.debt,
    required this.masked,
    required this.originals,
    this.invest = false,
  });

  final Map<int, Asset> originals;

  /// 투자 묶음 — 평가 시세를 못 받는 동안 머리 아래 띠(I-wrap-b2b 4).
  final bool invest;
  final double? topInset;
  final String title;
  final List<Asset> items;
  final bool debt;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final sum = assetSumIncluded(items);
    final total = debt ? sum.abs() : sum;
    final totalText = masked
        ? kBudgetMask
        : (debt && total != 0
              ? '$kMinus${assetWon(total, false)}'
              : assetWon(total, false));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListHeader(
          title: title,
          variant: PListHeaderVariant.boldSolid,
          topInset: topInset,
          trailing: Text(
            keepAllAmount(totalText),
            semanticsLabel: totalText,
            textAlign: TextAlign.end,
            style: PTypography.t4.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: tabularFigures,
            ),
          ),
        ),
        // 시세를 못 받는 동안 평가액은 서버 잔액 · 직전 시세다 — 숫자는 두고 "지금 시세가 아니다" 를 띠로(I-wrap-b2b 4)
        if (invest &&
            items.isNotEmpty &&
            ref.watch(valuationPriceFailedProvider))
          AssetPriceFailure(
            onRetry: () => refreshLiveValuation(ref.invalidate),
          ),
        if (items.isEmpty)
          BudgetEmptyLine(l.assetGroupEmpty)
        else
          PList(
            semanticLabel: title,
            children: [
              for (final a in items)
                // 줄은 라이브 값으로 그리고, 동작(밀기 · 상세 · 수정)에는 원본을 넘긴다
                // 밀면 수정·삭제 — 손가락 지름길이다. 줄을 누르면 상세로 가고 거기에도 수정 · 삭제가 있다(WCAG 2.1.1).
                PSwipeActions(
                  key: ValueKey('asset-${a.rowId}'),
                  rowLabel: a.assetName,
                  actions: assetActions.dsSwipeActions(
                    context,
                    ref,
                    originals[a.rowId] ?? a,
                  ),
                  child: AssetRow(
                    key: ValueKey('asset-row-${a.rowId}'),
                    asset: a,
                    cardMasked: masked,
                    manage: true,
                    // 어디서 열어도 같은 페이지다(I-17 36) — 삭제는 머리 더보기에 늘 있다.
                    onTap: () => openAssetDetail(context, a.rowId),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// 불러오는 중 — 묶음 제목 둘 + 줄 스켈레톤(타일 40 · 두 줄). 상단 바는 그대로 있다(31).
class _ManageSkeleton extends StatelessWidget {
  const _ManageSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget head(double? top) => Padding(
      padding: EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        top ?? PSpacing.x2,
        PSpacing.globalGutter,
        PSpacing.x2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PSkeleton.text(PTypography.t4, width: PSpacing.x10 * 2),
          PSkeleton.text(PTypography.t4, width: PSpacing.x10 * 2),
        ],
      ),
    );
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        head(PSpacing.x4),
        const AssetRowsSkeleton(),
        head(PSpacing.x6),
        const AssetRowsSkeleton(rows: 2),
      ],
    );
  }
}
