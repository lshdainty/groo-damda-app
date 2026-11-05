import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as dsb;
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart' as dsk;
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart'
    show showAssetEditForm;
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart'
    show PLeaveConfirmCopy;
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart' as dsf;
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart'
    show BudgetFailure, kBudgetMask;
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/domain/card_billing.dart';
import 'package:groo_damda_app/features/asset/domain/asset_type_meta.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_actions.dart';
import 'package:groo_damda_app/features/asset/presentation/holding_format.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_trade_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/transfer_detail_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/transfer_row.dart';
import 'package:groo_damda_app/features/stocks/application/live_prices.dart';
import 'package:groo_damda_app/features/stocks/data/securities_repository.dart';

/// 자산 상세 페이지로 간다(I-17 36) — 주소 `/asset/:id`. 라우터 밖(테스트 등)이면 같은 화면을 Navigator 로 연다.
///
/// 상세는 더는 시트가 아니다. 돌아올 곳은 부른 화면이다(← = pop).
void openAssetDetail(BuildContext context, int assetRowId) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/asset/$assetRowId');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AssetDetailScreen(assetId: assetRowId),
    ),
  );
}

/// 옛 이름 — 자산 줄을 누르면 상세 페이지로 간다.
void showAssetDetailRich(BuildContext context, Asset asset) =>
    openAssetDetail(context, asset.rowId);

/// 자산 상세 화면(I-17 35 · 38 · 39 · 41) — 상단 바(← + 제목 + 아이콘 둘 [수정] · [{이름} 더보기]) + 흰 면 하나.
///
/// 자산은 산 목록에서 id 로 찾는다. 불러오는 중은 틀 + Skeleton, 목록 실패는 Result Section(다시 시도), 목록이 왔는데
/// id 가 없으면 "자산을 찾을 수 없어요" + [자산으로]. 삭제는 머리 더보기 → Menu Sheet → 확인창 → 지우면 ← 와 같은 길.
class AssetDetailScreen extends ConsumerStatefulWidget {
  const AssetDetailScreen({super.key, required this.assetId});
  final int assetId;

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  bool _deleting = false;

  void _back() {
    final router = GoRouter.maybeOf(context);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (router != null) {
      // 주소로 바로 열었거나 앞 화면이 없다 — 자산 탭으로.
      router.go('/expense?tab=assets');
    }
  }

  Future<void> _openMenu(Asset asset) async {
    final l = AppLocalizations.of(context);
    await PMenuSheet.show(
      context,
      semanticLabel: l.assetMoreOf(asset.assetName),
      layout: PMenuSheetLayout.textWithIcon,
      groups: [
        PMenuSheetGroup([
          PMenuSheetItem(
            label: l.actionDelete,
            icon: LucideIcons.trash2,
            tone: PMenuSheetTone.critical,
            onSelect: () => _delete(asset),
          ),
        ]),
      ],
    );
  }

  Future<void> _delete(Asset asset) async {
    if (_deleting || !mounted) return;
    setState(() => _deleting = true);
    try {
      // 확인창(밀기 삭제와 같은 부품 · 같은 글, I-17 32) → 삭제. 실패는 확인창이 닫힌 뒤
      // critical 스낵바 + [다시 시도] — 다시 시도가 성공해도 같은 길로 나간다.
      final deleted = await assetActions.confirmAndDelete(
        context,
        asset,
        onRetried: () {
          if (mounted) _back();
        },
      );
      // 지워진 자산의 상세를 열어 둘 수 없다 — ← 와 같은 길. 목록은 지우는 쪽이 이미 다시 받는다(8).
      if (deleted && mounted) _back();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(assetsProvider);
    final list = async.value;
    final Asset? asset = list
        ?.where((a) => a.rowId == widget.assetId)
        .firstOrNull;
    final loading = list == null && async.isLoading;
    final failed = list == null && async.hasError;

    final title = asset == null ? l.assetDetailTitle : _titleFor(l, asset);
    final Widget body;
    if (asset != null) {
      body = _DetailBody(
        asset: asset,
        onEdit: () => showAssetEditForm(context, asset),
      );
    } else if (loading) {
      body = const _DetailSkeleton();
    } else if (failed) {
      body = _DetailResult(
        kind: PResultKind.failure,
        title: l.assetLoadFailTitle,
        description: l.dashFailDesc,
        action: PResultAction(
          label: l.actionRetry,
          onPressed: () => ref.invalidate(assetsProvider),
        ),
      );
    } else {
      body = _DetailResult(
        kind: PResultKind.empty,
        title: l.assetNotFoundTitle,
        description: l.assetNotFoundDesc,
        action: PResultAction(
          label: l.assetNotFoundAction,
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            if (router != null) {
              router.go('/expense?tab=assets');
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      );
    }

    return Scaffold(
      // 흰 면 하나(4-A) — 회색 바닥도 띠도 없다
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: title,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: _back,
          ),
          actions: asset == null
              ? const []
              : [
                  PTopNavigationIconButton(
                    icon: LucideIcons.pencil,
                    label: l.actionEdit,
                    onPressed: () => showAssetEditForm(context, asset),
                  ),
                  PTopNavigationIconButton(
                    icon: LucideIcons.ellipsis,
                    label: l.assetMoreOf(asset.assetName),
                    onPressed: () {
                      if (!_deleting) _openMenu(asset);
                    },
                  ),
                ],
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _DetailResult extends StatelessWidget {
  const _DetailResult({
    required this.kind,
    required this.title,
    required this.description,
    required this.action,
  });
  final PResultKind kind;
  final String title;
  final String description;
  final PResultAction action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PResultSection(
        kind: kind,
        size: PResultSize.large,
        title: title,
        description: description,
        primaryAction: action,
      ),
    );
  }
}

/// 불러오는 중 — 틀은 그리고 머리 · 금액 · 구역 자리만 Skeleton.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(PSpacing.x6, PSpacing.x4, PSpacing.x6, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dsk.PSkeleton(width: 200, height: 48),
          SizedBox(height: PSpacing.x4),
          dsk.PSkeleton(width: 120, height: 20),
          SizedBox(height: PSpacing.x2),
          dsk.PSkeleton(width: 220, height: 32),
          SizedBox(height: PSpacing.x6),
          dsk.PSkeleton(width: double.infinity, height: 140),
        ],
      ),
    );
  }
}

/// 자산 상세의 거래 행 금액을 가리는 판정 — 화면 카드·종류 카드에 **이 자산의 숨김**을
/// 합친다(합집합). 히어로만 가리고 행은 드러나면 가린 뜻이 없다 — 이 판정은 화면
/// 단위로 한 번 만들어 행·일 합계·이체 행에 같이 흘린다(자리마다 따로 걸지 않는다).
MaskFlags _assetMaskFlags(WidgetRef ref, Asset asset) {
  final base = ref.watch(maskFlagsProvider('asset.detail'));
  if (asset.isAmountHidden != 'Y') return base;
  return MaskFlags(
    card: true,
    expense: base.expense,
    income: base.income,
    transfer: base.transfer,
  );
}

String _titleFor(AppLocalizations l, Asset a) {
  if (a.assetType == 'CREDIT_CARD' || a.assetType == 'CHECK_CARD') {
    return l.assetCardDetail;
  }
  if (a.assetType == 'INVESTMENT') return l.assetInvestDetail;
  return l.assetAccountDetail;
}

/// 글 버튼(ghost small 36)의 위아래 4 씩을 걷는 높이 비율 — 웹 `-my-x1`.
const double _kTextLinkHeightFactor = 28 / 36;

enum _Period { p3m, p6m, p1y }

extension on _Period {
  int get weeks => switch (this) {
    _Period.p3m => 12,
    _Period.p6m => 24,
    _Period.p1y => 52,
  };
  String label(AppLocalizations l) => switch (this) {
    _Period.p3m => l.assetPeriod3m,
    _Period.p6m => l.assetPeriod6m,
    _Period.p1y => l.assetPeriod1y,
  };
  String headerLabel(AppLocalizations l) => l.assetWeeksCount(weeks);
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.asset, this.onEdit});
  final Asset asset;
  final VoidCallback? onEdit;
  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  _Period _period = _Period.p3m;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 여는 쪽은 탭 시점의 asset 을 넘긴다 — 시트가 열린 채 매수·취소가 일어나면
    // 목록 provider 는 새 값인데 스냅샷은 옛 수량·평가액이 남는다. 산 목록에서
    // 같은 자산을 다시 찾아 쓴다(웹 AssetDetailDialog 와 같은 처리).
    var asset = widget.asset;
    final liveAssets = ref.watch(assetsProvider).value;
    if (liveAssets != null) {
      final i = liveAssets.indexWhere((a) => a.rowId == widget.asset.rowId);
      if (i >= 0) asset = liveAssets[i];
    }
    // 화면 카드 **또는** 이 자산 자체가 가려져 있으면 가린다 — 합집합이다.
    // 두 축은 서로를 덮지 않는다(하나는 화면 설정, 하나는 자산의 속성).
    final masked =
        ref.watch(hideCardProvider('asset.detail')) ||
        asset.isAmountHidden == 'Y';
    final meta = AssetTypeMeta.of(asset.assetType);

    final isCard =
        asset.assetType == 'CREDIT_CARD' || asset.assetType == 'CHECK_CARD';
    final isInv = asset.assetType == 'INVESTMENT';
    // 연결계좌형 체크카드 — 결제가 계좌에서 즉시 빠져 잔액이 늘 0 이다. 히어로는 잔액
    // 대신 "이번 달 사용액", 내역은 당월 1일~말일 전체(사용자 결정). 미연결 체크카드는
    // 잔액이 실제로 쌓이므로 일반 계좌처럼 그대로다. (web 정합)
    final isCheckLinked =
        asset.assetType == 'CHECK_CARD' && asset.paymentAssetRowId != null;
    final valueLabel = isCheckLinked
        ? l.assetValueLabelCheckCard
        : isCard
        ? l.assetValueLabelCard
        : isInv
        ? l.assetValuationShort
        : l.expSummaryBalance;
    final seriesLabel = isCard
        ? l.assetSeriesUsage
        : isInv
        ? l.assetValuationShort
        : l.expSummaryBalance;
    final trendTitle = l.assetTrendRecent(
      _period.headerLabel(l),
      isCard
          ? l.assetTrendKindUsage
          : isInv
          ? l.assetTrendKindValuation
          : l.assetTrendKindBalance,
    );

    final trendAsync = ref.watch(
      assetBalanceTrendProvider((assetId: asset.rowId, weeks: _period.weeks)),
    );
    // recent tx — web 와 동일 12건. 연결계좌형 체크카드는 "이번 달 뭐 썼나" 가 목적이라
    // 당월(1일~말일) 전체를 다 가져온다 — 12건 컷을 두면 월말엔 월초 내역이 잘린다.
    final now = DateTime.now();
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final recentAsync = isCheckLinked
        ? ref
              .watch(
                assetPeriodExpensesProvider((
                  assetId: asset.rowId,
                  startDate: ymd(DateTime(now.year, now.month, 1)),
                  endDate: ymd(DateTime(now.year, now.month + 1, 0)),
                )),
              )
              // 기간 provider 는 예정분을 안 거른다 — "이번 달 내역" 규칙(지나간 것만)을 여기서 맞춘다.
              .whenData(
                (list) =>
                    list.where((e) => !isScheduledTx(e.expenseDate)).toList(),
              )
        : ref.watch(expensesByAssetProvider((assetId: asset.rowId, limit: 12)));
    // 이체는 expense 가 아니라 asset_transfer — 따로 받아 이 자산에 걸린 것만 추린다.
    // 한 건이 자산 두 개에 걸치므로 보내는 쪽·받는 쪽 둘 다 확인한다(서버 필터는 기간만 지원).
    final monthPrefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final assetTransfers =
        (ref
                    .watch(
                      assetTransfersProvider((startDate: null, endDate: null)),
                    )
                    .value ??
                const <AssetTransfer>[])
            .where(
              (tr) =>
                  (tr.fromAssetRowId == asset.rowId ||
                      tr.toAssetRowId == asset.rowId) &&
                  // 지출과 같은 규칙 — "최근 거래" 에는 지나간 것만 올린다.
                  !isScheduledTx(tr.transferDate) &&
                  // 체크카드 "이번 달 내역" 은 이체도 당월만 — 지출과 기간을 맞춘다.
                  (!isCheckLinked ||
                      (tr.transferDate ?? '').startsWith(monthPrefix)),
            )
            .toList();
    // CREDIT_CARD 는 신판 카드 상세 본문(_CardDetailBody) — 회차 히어로가 금액 담당.
    final isCredit = asset.assetType == 'CREDIT_CARD';

    // 새 부품 줄(List · 목록 제목)이 스스로 좌우 24 를 가지므로 목록은 끝까지 벌리고, 줄이 아닌 것(머리 · 차트 · 내역 줄)만 24 안쪽에 둔다.
    const gutterPad = EdgeInsets.symmetric(horizontal: PSpace.xl);
    final hero = Padding(
      padding: gutterPad,
      child: _HeroCard(
        asset: asset,
        meta: meta,
        valueLabel: valueLabel,
        isCard: isCard,
        masked: masked,
        nameRowOnly: isCredit,
      ),
    );
    final first = !isCard && !isInv;
    return ListView(
      padding: const EdgeInsets.only(bottom: PSpace.x16),
      children: [
        hero,
        if (isCredit) ...[
          _CardDetailBody(asset: asset, masked: masked, onEdit: widget.onEdit),
        ] else ...[
          // 체크카드 — 실적 줄만(청구 회차 없음, design 신판)
          if (isCard) const SizedBox(height: PSpace.x4),
          if (isCard) _CardPerfBadge(assetRowId: asset.rowId, masked: masked),
          if (isInv) ...[
            const SizedBox(height: PSpace.x16),
            Padding(
              padding: gutterPad,
              child: _InvChangeLine(assetRowId: asset.rowId, masked: masked),
            ),
            Padding(
              padding: gutterPad,
              child: _HoldingsSection(asset: asset, masked: masked),
            ),
          ],

          // 잔액 추이(48) — 목록 제목 + Segmented 3개월 · 6개월 · 1년 + 차트(폰 140). 연결계좌형 체크카드는 잔액이 늘 0 이라
          // 평평한 0 선뿐이다. 차트만 빼고 내역은 그대로 둔다. (web 정합)
          if (!isCheckLinked) ...[
            PListHeader(
              title: trendTitle,
              variant: PListHeaderVariant.boldSolid,
              topInset: first ? null : PSpacing.x4,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
                vertical: PSpacing.x1,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PSegmentedControl<_Period>(
                  semanticLabel: l.assetPeriodAria,
                  value: _period,
                  onChanged: (p) => setState(() => _period = p),
                  items: [
                    for (final p in _Period.values)
                      PSegmentedItem(value: p, label: p.label(l)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x2,
                PSpacing.globalGutter,
                0,
              ),
              child: _BalanceTrendChart(
                async: trendAsync,
                seriesLabel: seriesLabel,
                title: trendTitle,
                masked: masked,
                height: 140,
                onRetry: () => ref.invalidate(
                  assetBalanceTrendProvider((
                    assetId: asset.rowId,
                    weeks: _period.weeks,
                  )),
                ),
              ),
            ),
          ],

          // 최근 거래 · 이번 달 내역(49) — 목록 제목 + 오른쪽 글 버튼 "전체 보기" + 가계부 공용 줄
          PListHeader(
            title: (recentAsync.value?.isNotEmpty ?? false)
                ? (isCheckLinked
                      ? l.assetMonthTxCount(recentAsync.value!.length)
                      : l.assetRecentTxCount(recentAsync.value!.length))
                : l.dashRecent,
            variant: PListHeaderVariant.boldSolid,
            topInset: PSpacing.x4,
            action: PTextButton(
              label: l.assetViewAll,
              onPressed: () => context.go('/expense?assetId=${asset.rowId}'),
            ),
          ),
          Padding(
            padding: gutterPad,
            child: _RecentExpenses(
              async: recentAsync,
              transfers: assetTransfers,
              perspectiveAssetRowId: asset.rowId,
              flags: _assetMaskFlags(ref, asset),
              tokens: t,
            ),
          ),
        ],
      ],
    );
  }
}

/// 투자 히어로 아래 등락 라인 — design: "+N% · 오늘 ±M원" (상승=빨강/하락=파랑).
/// 라이브 평가(연동가·전일종가) 가능할 때만 표시.
class _InvChangeLine extends ConsumerWidget {
  const _InvChangeLine({required this.assetRowId, required this.masked});
  final int assetRowId;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 다시 받는 동안 앞 값을 든다(asData 는 그때 비어 등락이 깜빡인다) — asset_screen 과 같다.
    final v = ref.watch(investmentValuationMapProvider).value?[assetRowId];
    final chg = v?.changeAmt;
    if (masked || v == null || chg == null) return const SizedBox.shrink();
    final base = v.value - chg;
    final pct = base == 0 ? 0.0 : chg / base * 100;
    final up = chg >= 0;
    final color = up ? t.statusDangerFg : t.fgBrand;
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x16),
      child: Row(
        children: [
          Text(
            formatChangeRate(pct, signed: true),
            style: PTypo.bodySm.copyWith(
              color: color,
              fontWeight: PFontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          Text(
            l.assetTodayChange(
              krwSigned(chg.abs(), false, sign: up ? '+' : '−'),
            ),
            style: PTypo.caption.copyWith(
              color: t.fgTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 투자 보유 종목 섹션 — design AssetDetailDialog '보유 종목' 플랫 리스트 미러.
/// linked: "N주 · 현재가 X 연동" + 등락% / manual: "직접 입력". 행 탭 → 편집.
/// 레거시 단일 연동(tossSymbol/tossQuantity) 자산은 가상 1건으로 표시(편집에서 이관).
class _HoldingsSection extends ConsumerWidget {
  const _HoldingsSection({required this.asset, required this.masked});
  final Asset asset;
  final bool masked;

  List<AssetHolding> get _holdings {
    if (asset.holdings.isNotEmpty) return asset.holdings;
    if ((asset.tossSymbol?.isNotEmpty ?? false) && asset.tossQuantity != null) {
      return [
        AssetHolding(
          linked: true,
          marketCode: asset.marketCode,
          tossSymbol: asset.tossSymbol,
          quantity: asset.tossQuantity?.toString(),
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final holdings = _holdings;

    // 연동 심볼 시세 — 게이트(프로+토스연결) ON 일 때만 조회.
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final gate =
        (features?.hasSecurities ?? false) &&
        (features?.hasBrokerConnection ?? false);
    final symbols = [
      for (final h in holdings)
        if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) h.tossSymbol!,
    ];
    // 환산 규칙은 livePricesProvider 한 곳에 있다 — 목록·추가/편집과 같은 걸 써야
    // 한 화면에서 총액과 종목별 금액이 어긋나지 않는다.
    final live = gate && symbols.isNotEmpty
        ? ref.watch(livePricesProvider(livePricesKey(symbols))).value
        : null;

    double? unitKrw(String symbol) => live?.unitKrw(symbol);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.assetHoldings,
              style: PTypo.bodySm.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${holdings.length}',
              style: PTypo.bodySm.copyWith(
                color: t.fgBrand,
                fontWeight: PFontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if (holdings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x20),
            child: Center(
              child: Text(
                l.assetHoldingsEmptyDetail,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else
          for (int i = 0; i < holdings.length; i++)
            _HoldingRow(
              holding: holdings[i],
              // 매수·매도는 종목마다 연다 — 어떤 종목인지 정해진 채로 들어가야
              // 다시 고를 일이 없다(종목 추가는 편집에서 토스 검색으로).
              onTrade: (type) => showAssetTradeSheet(
                context,
                asset: asset,
                holding: holdings[i],
                defaultType: type,
              ),
              first: i == 0,
              unitKrw:
                  holdings[i].linked &&
                      (holdings[i].tossSymbol?.isNotEmpty ?? false)
                  ? unitKrw(holdings[i].tossSymbol!)
                  : null,
              rawPrice:
                  holdings[i].linked &&
                      (holdings[i].tossSymbol?.isNotEmpty ?? false)
                  ? live?.quoteOf(holdings[i].tossSymbol!)
                  : null,
              prevUnitKrw:
                  holdings[i].linked &&
                      (holdings[i].tossSymbol?.isNotEmpty ?? false)
                  ? live?.prevUnitKrw(holdings[i].tossSymbol!)
                  : null,
            ),

        // 거래 내역 — 언제 사고 팔았는지, 실현손익이 얼마인지. 취소도 여기서.
        _TradeHistory(assetRowId: asset.rowId, masked: masked),
      ],
    );
  }
}

/// 거래 기록 — 언제 사고 팔았는지. 줄을 누르면 거래 기록 상세 시트로 들어가고, 취소는 그 바닥 왼쪽 [거래 취소] 에서 한다
/// (10-25 줄 끝 ⋮ 원칙 · 10-31 17-3 판정 50). 줄 끝에 ⋮ 도 휴지통도 두지 않는다.
class _TradeHistory extends ConsumerWidget {
  const _TradeHistory({required this.assetRowId, required this.masked});
  final int assetRowId;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final trades = ref.watch(assetTradesProvider(assetRowId)).value ?? const [];
    if (trades.isEmpty) return const SizedBox.shrink();
    final holdings =
        ref
            .watch(assetsProvider)
            .value
            ?.where((a) => a.rowId == assetRowId)
            .firstOrNull
            ?.holdings ??
        const <AssetHolding>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: PSpacing.x4),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: PSpacing.x2),
          child: Text(
            '${l.tradeHistory} · ${trades.length}',
            style: PTypography.t4.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final tr in trades)
          _TradeRow(
            trade: tr,
            holdingName: tradeHoldingName(tr, holdings),
            masked: masked,
            onTap: () => showTradeDetailSheet(
              context,
              trade: tr,
              holdingName: tradeHoldingName(tr, holdings),
              masked: masked,
              assetRowId: assetRowId,
            ),
          ),
      ],
    );
  }
}

/// 거래 기록 줄 — 제목 "{매수 | 매도} · {종목} {수량}{단위}"(`fg-neutral`) · 설명 날짜(+ 매도 실현손익) · 뒤 금액(부호 없음).
/// 보이는 줄 높이 46 이상, 누르는 칸은 줄 전체(≥ 44).
class _TradeRow extends StatelessWidget {
  const _TradeRow({
    required this.trade,
    required this.holdingName,
    required this.masked,
    required this.onTap,
  });
  final AssetTrade trade;
  final String holdingName;
  final bool masked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final tr = trade;
    final title =
        '${tradeKindLabel(l, tr)} · $holdingName ${tradeQtyText(l, tr)}';
    final pl = tr.realizedPl;
    final desc = [
      tradeDateOnly(tr),
      if (tr.tradeType == 'SELL' && pl != null && pl != 0)
        masked ? '••••' : tradeSignedKrw(pl),
    ].join(' · ');
    return Semantics(
      button: true,
      label: l.tradeOpenRow(tradeDateOnly(tr), holdingName),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpacing.x2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PTypography.t5.copyWith(color: c.fgNeutral),
                      ),
                      Text(
                        desc,
                        style: PTypography.t3.copyWith(
                          color: c.fgNeutralSubtle,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PSpacing.x3),
                Text(
                  masked ? '••••' : '${krw(tr.amount ?? 0)}${wonUnit()}',
                  textAlign: TextAlign.end,
                  style: PTypography.t5.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String tradeKindLabel(AppLocalizations l, AssetTrade tr) =>
    tr.tradeType == 'SELL' ? l.tradeSell : l.tradeBuy;

String tradeDateOnly(AssetTrade tr) => (tr.tradeDate ?? '').split('T').first;

/// "2026-10-19 09:30" — 날짜 + 시각(초 아래는 자른다).
String tradeDateTimeText(AssetTrade tr) {
  final raw = tr.tradeDate ?? '';
  final text = raw.length >= 16
      ? raw.substring(0, 16).replaceFirst('T', ' ')
      : raw;
  // 날짜 한가운데서 줄이 바뀌지 않게 — 하이픈 뒤 줄바꿈을 막는다(날짜 · 시각 사이 공백에서만 바뀐다).
  return text.replaceAll('-', '-\u2060');
}

/// 거래 기록에 보이는 종목 이름 — 연동 종목은 보유 목록의 이름(없으면 티커 코드), 직접 입력은 항목명(= holdingKey) 그대로.
String tradeHoldingName(AssetTrade tr, List<AssetHolding> holdings) {
  if (!tr.linked) return tr.holdingKey;
  final name = holdings
      .where((h) => h.tossSymbol == tr.holdingKey)
      .map((h) => h.holdingName)
      .firstWhere((n) => n != null && n.trim().isNotEmpty, orElse: () => null);
  return name ?? tr.holdingKey;
}

String tradeQtyText(AppLocalizations l, AssetTrade tr) {
  final type = AssetHoldingType.values.firstWhere(
    (t) => t.wire == tr.holdingType,
    orElse: () => AssetHoldingType.stock,
  );
  return '${formatHoldingQty(tr.quantity, type)}${holdingUnitLabel(l, type)}';
}

String tradeSignedKrw(int v) =>
    '${v > 0 ? '+' : kMinus}${krw(v.abs())}${wonUnit()}';

/// 키-값 줄(I-17 45) — 키 t5 `fg-neutral`, 값 t5 `fg-neutral-muted` **줄 끝 오른쪽 맞춤**(몇 줄이든 end). 값이 없으면 그리지
/// 않는다. 보이는 줄 높이 46(22 + 위아래 12), 조회 줄이라 눌림은 없다. 웹 21-1 `KvRow` 와 이름 · props 가 같다.
class KvRow extends StatelessWidget {
  const KvRow({
    super.key,
    required this.label,
    required this.value,
    this.inset = PSpacing.x6,
  });
  final String label;
  final String? value;

  /// 좌우 여백 — 시트 안은 24, 이미 24 안쪽에 선 페이지 본문은 0.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset, vertical: PSpacing.x3),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.4),
              child: Text(
                label,
                style: PTypography.t5.copyWith(color: c.fgNeutral),
              ),
            ),
            const SizedBox(width: PSpacing.x4),
            Expanded(
              child: Text(
                v,
                textAlign: TextAlign.end,
                style: PTypography.t5.copyWith(
                  color: c.fgNeutralMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 거래 기록 상세 시트 — 종류 · 종목 · 수량 · 단가 · 거래대금 · (수수료) · (매도 실현손익) · 일시 키-값 줄, ⋮ 없음.
/// 조회라 바깥 · 끌기로 닫힌다. 바닥 왼쪽 [거래 취소] ghost critical → 시트를 닫고 확인창(critical, 글에 대상을 넣음).
Future<void> showTradeDetailSheet(
  BuildContext context, {
  required AssetTrade trade,
  String? holdingName,
  required bool masked,
  required int assetRowId,
}) async {
  final l = AppLocalizations.of(context);
  final cancel = await PBottomSheet.show<bool>(
    context,
    builder: (sheetContext) => TradeDetailBody(
      trade: trade,
      holdingName: holdingName,
      masked: masked,
      onCancelTrade: () => PBottomSheet.of(sheetContext).close(true),
    ),
  );
  if (cancel != true || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  final ok = await askConfirmThenRequest(
    context,
    title: l.tradeDeleteTitle,
    description: l.tradeDeleteConfirmTarget(
      tradeDateOnly(trade),
      holdingName ?? trade.holdingKey,
      tradeQtyText(l, trade),
      tradeKindLabel(l, trade),
    ),
    cancelLabel: l.actionCancel,
    actionLabel: l.tradeDeleteTitle,
    request: () => _cancelTradeRequest(container, trade, assetRowId),
    failedMessage: l.tradeCancelFailed,
    retryLabel: l.actionRetry,
    onRetried: () => PSnackbar.maybeOf(context)?.show(message: l.tradeDeleted),
  );
  if (ok && context.mounted) {
    PSnackbar.maybeOf(context)?.show(message: l.tradeDeleted);
  }
}

/// 거래 취소 요청(silent) + 뒷정리 — 취소 뒤 목록을 다시 받는다(8). 던지면 호출처가 실패 스낵바를 띄운다.
Future<void> _cancelTradeRequest(
  ProviderContainer container,
  AssetTrade trade,
  int assetRowId,
) async {
  final repo = await container.read(assetRepositoryProvider.future);
  await repo.deleteTrade(trade.rowId, silent: true);
  // 예수금·평가액이 되돌아간다 — 순자산·추이까지 다시 받는다.
  for (final p in <ProviderOrFamily>[
    assetsProvider,
    assetSummaryProvider,
    netWorthTrendProvider,
    assetByIdProvider,
    cardBillingProvider,
    cardPerformanceProvider,
    investmentValuationMapProvider,
  ]) {
    container.invalidate(p);
  }
  container.invalidate(assetTradesProvider(assetRowId));
}

/// 거래 기록 상세 본문 — 시트가 감싼다(카탈로그 · 렌더도 이것을 직접 부른다).
class TradeDetailBody extends StatelessWidget {
  const TradeDetailBody({
    super.key,
    required this.trade,
    this.holdingName,
    required this.masked,
    required this.onCancelTrade,
  });
  final AssetTrade trade;
  final String? holdingName;
  final bool masked;
  final VoidCallback onCancelTrade;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tr = trade;
    final sell = tr.tradeType == 'SELL';
    final qtyValue = double.tryParse((tr.quantity ?? '').replaceAll(',', ''));
    final amount = tr.amount ?? 0;
    final unit = (qtyValue != null && qtyValue > 0)
        ? (amount / qtyValue).round()
        : null;
    String money(int v) => masked ? '••••' : '${krw(v)}${wonUnit()}';
    final pl = tr.realizedPl;
    return PBottomSheetContent(
      title: l.tradeDetailTitle,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KvRow(label: l.tradeKind, value: tradeKindLabel(l, tr)),
          KvRow(
            label: l.tradeHoldingLabel,
            value: holdingName ?? tr.holdingKey,
          ),
          KvRow(label: l.tradeQuantity, value: tradeQtyText(l, tr)),
          KvRow(
            label: l.tradeUnitPrice,
            value: unit == null ? null : money(unit),
          ),
          KvRow(label: l.tradeAmountLabel, value: money(amount)),
          KvRow(
            label: l.tradeFeeLabel,
            value: (tr.fee ?? 0) > 0 ? money(tr.fee!) : null,
          ),
          KvRow(
            label: l.tradeRealizedPreview,
            value: sell && pl != null && pl != 0
                ? (masked ? '••••' : tradeSignedKrw(pl))
                : null,
          ),
          KvRow(label: l.tradeDateTime, value: tradeDateTimeText(tr)),
        ],
      ),
      footerRow: Align(
        alignment: Alignment.centerLeft,
        child: dsb.PButton(
          label: l.tradeDeleteTitle,
          variant: dsb.PButtonVariant.ghost,
          ghostColor: dsb.PButtonGhostColor.critical,
          size: dsb.PButtonSize.large,
          onPressed: onCancelTrade,
        ),
      ),
    );
  }
}

/// 보유 종목 1행 — design 플랫 행(이름/서브 · 평가액/등락% · chevron).
class _HoldingRow extends ConsumerWidget {
  const _HoldingRow({
    required this.holding,
    required this.first,
    required this.unitKrw,
    required this.rawPrice,
    required this.prevUnitKrw,
    this.onTrade,
  });
  final AssetHolding holding;
  final bool first;
  final double? unitKrw; // 연동 1주 KRW 환산가 (미확보 시 null)
  final BrokerQuote? rawPrice; // 표시용 원통화 현재가
  /// 전일 종가의 KRW 환산가 — 등락 표시 전용. 부모가 livePricesProvider 에서 받아 넘긴다.
  /// 행에서 직접 캔들을 부르면 나무 사용자에게 종목 수만큼 403 이 나간다.
  final double? prevUnitKrw;

  /// 이 종목에 대한 매수·매도. 종목이 정해진 자리라 시트에서 다시 고를 필요가 없다.
  final ValueChanged<String>? onTrade;

  /// 통화를 하나로 가정하지 않는다 — 나무를 붙이며 JPY·HKD·CNY 가 들어왔다.
  String _fmtRawPrice(BrokerQuote p) {
    final cur = p.currency.toUpperCase();
    if (cur == 'KRW') return krwSigned(p.price.round(), false, unit: true);
    if (cur == 'USD') return '\$${p.price.toStringAsFixed(2)}';
    return '${p.price.toStringAsFixed(2)} $cur';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final h = holding;
    final name = (h.holdingName?.isNotEmpty ?? false)
        ? h.holdingName!
        : (h.tossSymbol ?? '');

    // 서브 — linked: "{qty}주 · 현재가 {price} 연동"(연동은 주식뿐) /
    // manual: 수량을 적어 뒀으면 "{qty}{단위} · 직접 입력", 없으면 "직접 입력".
    final qty = formatHoldingQty(h.quantity, h.holdingType);
    final String sub;
    if (h.linked) {
      sub = rawPrice != null
          ? l.assetHoldingLinkedDetail(qty, _fmtRawPrice(rawPrice!))
          : '${l.assetSharesCount(qty)} · ${l.assetHoldingLinkedBadge}';
    } else {
      sub = h.quantityValue > 0
          ? '${l.assetHoldingQtyUnit(qty, holdingUnitLabel(l, h.holdingType))} · ${l.assetHoldingManualDetail}'
          : l.assetHoldingManualDetail;
    }

    // 평가액 — linked: 라이브(가격×수량), 폴백 서버 스냅샷(holdingValue) / manual: holdingValue.
    final int? value = h.linked
        ? (unitKrw != null
              ? (unitKrw! * h.quantityValue).round()
              : h.holdingValue)
        : (h.holdingValue ?? 0);

    // 등락% — 연동 + 전일종가 확보 시. 원화 환산가끼리 비교해도 비율은 같다.
    double? pct;
    if (h.linked &&
        unitKrw != null &&
        prevUnitKrw != null &&
        prevUnitKrw! > 0) {
      pct = (unitKrw! - prevUnitKrw!) / prevUnitKrw! * 100;
    }

    return DecoratedBox(
      position: DecorationPosition.background,
      decoration: const BoxDecoration(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: t.borderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.caption.copyWith(
                      color: t.fgTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value != null ? krwSigned(value, false, unit: true) : '—',
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (pct != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    formatChangeRate(pct, signed: true),
                    style: PTypo.micro.copyWith(
                      color: pct >= 0 ? t.statusDangerFg : t.fgBrand,
                      fontWeight: PFontWeight.semi,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
            // 매수·매도는 상세를 어디서 열었든 가능해야 한다 — 편집 진입(onTap)
            // 여부에 묶으면 자산 화면에서 연 상세만 매매가 막힌다(웹은 된다).
            if (onTrade != null) const SizedBox(width: PSpace.x8),
            if (onTrade != null) ...[
              PButton(
                label: l.tradeBuy,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: () => onTrade!('BUY'),
              ),
              PButton(
                label: l.tradeSell,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: () => onTrade!('SELL'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.asset,
    required this.meta,
    required this.valueLabel,
    required this.isCard,
    required this.masked,
    this.nameRowOnly = false,
  });
  final Asset asset;
  final AssetTypeMeta meta;
  final String valueLabel;
  final bool isCard;
  final bool masked;

  /// 신용카드 — 이름 행만(구분선·잔액 생략, 회차 히어로가 금액 담당).
  final bool nameRowOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subtitle = [
      asset.institution,
      // 마이너스통장은 BANK_ACCOUNT 라 코드만 보면 '입출금' 으로 나온다.
      assetTypeLabelOf(l, asset),
      asset.memo,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    // 카드만 절대값이다. 카드 잔액은 "미결제 사용액이 음수" 라는 규약이라 화면에는
    // 얼마 썼나로 뒤집어 보여 준다. 그 밖의 자산은 음수가 정상 상태다 — 마이너스 통장,
    // 잔액을 실제와 맞추지 않은 계좌. abs() 를 씌우면 −5,000 이 "5,000원" 으로 보여
    // 목록·편집 폼과 어긋난다.
    final heroIsCard =
        asset.assetType == 'CREDIT_CARD' || asset.assetType == 'CHECK_CARD';
    final rawBalance = asset.balance ?? 0;
    // 연결계좌형 체크카드는 잔액이 늘 0 — 히어로는 이번 달 사용액(서버 계산)을 보여준다.
    final checkLinked =
        asset.assetType == 'CHECK_CARD' && asset.paymentAssetRowId != null;
    final heroBalance = checkLinked
        ? (asset.monthlyUsedAmount ?? 0)
        : heroIsCard
        ? rawBalance.abs()
        : rawBalance;
    // 머리(45) — Logo 48 + 오른쪽 12 + 이름 t6 700 줄바꿈 + 설명 t3 `fg-neutral-subtle`. 구분선 · 띠를 두지 않는다.
    final c = context.colors;
    final amountText = masked
        ? '••••••'
        : '${heroBalance < 0 ? kMinus : ''}${krw(heroBalance.abs())}${wonUnit()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: PSpacing.x4, bottom: PSpacing.x2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssetLogo(asset: asset, size: 48),
              const SizedBox(width: PSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.assetName,
                      style: PTypography.t6.copyWith(
                        color: c.fgNeutral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: PTypography.t3.copyWith(
                          color: c.fgNeutralSubtle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!nameRowOnly) ...[
          const SizedBox(height: PSpacing.x3),
          Text(
            valueLabel,
            style: PTypography.t3.copyWith(
              color: c.fgNeutralSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: PSpacing.x1),
          // 금액 R13 — t9 24/32 · 700 · 고정폭 · 원까지 · 빼기 U+2212. 한 줄에 못 들어가면 쉼표 뒤에서만 줄을 바꾼다.
          Text(
            amountText,
            style: PTypography.t9.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          // 예수금 · 평가금액 — 키-값 줄 둘(예수금이 있을 때만).
          if (asset.assetType == 'INVESTMENT' &&
              (asset.cashBalance ?? 0) != 0) ...[
            const SizedBox(height: PSpacing.x2),
            KvRow(
              inset: 0,
              label: l.assetCashBalance,
              value: masked
                  ? '••••••'
                  : '${krw(asset.cashBalance!)}${wonUnit()}',
            ),
            KvRow(
              inset: 0,
              label: l.assetHoldingBalance,
              value: masked
                  ? '••••••'
                  : '${krw(asset.holdingBalance ?? 0)}${wonUnit()}',
            ),
          ],
        ],
      ],
    );
  }
}

/// 잔액 추이 차트(I-17 48) — 05-3 57 의 변형 하나: ds 선 차트 + 데이터 점마다 점 · 채움 없음 · 눈금 글 줄임("3억") · 툴팁 원까지.
/// 불러오는 중은 Skeleton, 실패는 이 자리에서 다시 시도, 데이터가 없으면 가운데 한 줄. 금액을 가리면 눈금 · 툴팁이 "••••".
class _BalanceTrendChart extends StatelessWidget {
  const _BalanceTrendChart({
    required this.async,
    required this.seriesLabel,
    required this.title,
    required this.masked,
    required this.height,
    required this.onRetry,
  });
  final AsyncValue<List<AssetBalancePoint>> async;
  final String seriesLabel;
  final String title;
  final bool masked;
  final double height;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final list = async.value;
    if (list == null) {
      if (async.hasError) {
        return BudgetFailure(title: l.assetTrendLoadError, onRetry: onRetry);
      }
      return dsk.PSkeleton(height: height);
    }
    if (list.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            l.assetChartNoData,
            style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
      );
    }
    String won(num v) => masked ? kBudgetMask : formatWon(v);
    final labels = [
      for (var i = 0; i < list.length; i++) l.assetWeeksCount(i + 1),
    ];
    final name = '$title, ${won(list.last.balance)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PLineChart(
          label: name,
          height: height,
          categories: labels,
          area: false,
          dots: true,
          series: [
            PChartSeries(
              key: 'balance',
              label: seriesLabel,
              color: PChartColor.blue,
              values: [for (final p in list) p.balance.toDouble()],
            ),
          ],
          axisFormatter: (v) => masked ? kBudgetMask : formatAxisWon(v),
          valueFormatter: won,
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.assetChartTableWeek),
            PChartDataColumn(seriesLabel),
          ],
          rows: [
            for (var i = 0; i < list.length; i++)
              [labels[i], won(list[i].balance)],
          ],
        ),
      ],
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses({
    required this.async,
    required this.flags,
    required this.tokens,
    this.transfers = const [],
    this.perspectiveAssetRowId,
  });
  final AsyncValue<List<Expense>> async;

  /// 화면 카드 + 종류 카드 — 행·일합계마다 자기 종류로 판정한다.
  final MaskFlags flags;
  final GrooTokens tokens;

  /// 이 자산에 걸린 이체. 지출/수입 일 합계에는 넣지 않고 그날 행 뒤에만 붙인다.
  final List<AssetTransfer> transfers;

  /// 부호 기준 자산 — 출금이면 -(금액+수수료), 입금이면 +금액.
  final int? perspectiveAssetRowId;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <Expense>[];
    // 빈 목록도 받아 온 값이다 — 스켈레톤은 값이 아예 없을 때만.
    // 값이 있으면 다시 받는 중에도 그 값을 그대로 그린다.
    if (async.isLoading && !async.hasValue) {
      // 실렌더와 같은 날짜 그룹 구조 — 그룹 사이 16, 헤더(날짜+요일+일 합계) + 행.
      // 평평한 행만 깔면 데이터가 오는 순간 헤더 높이만큼 목록이 밀린다.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int g = 0; g < 2; g++) ...[
            Padding(
              padding: EdgeInsets.only(top: g == 0 ? 0 : PSpace.x16),
              child: const Row(
                children: [
                  PSkeleton.line(width: 56, height: 14),
                  SizedBox(width: PSpace.x8),
                  PSkeleton.line(width: 20, height: 14),
                  Spacer(),
                  PSkeleton.line(width: 72, height: 14),
                ],
              ),
            ),
            for (int i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    PSkeleton(
                      width: 36,
                      height: 36,
                      borderRadius: PRadius.tile(36),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PSkeleton.line(width: 120, height: 14),
                          SizedBox(height: 4),
                          PSkeleton.line(width: 80, height: 11),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const PSkeleton.line(width: 56, height: 14),
                  ],
                ),
              ),
          ],
        ],
      );
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            AppLocalizations.of(context).assetNoLinkedTx,
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
          ),
        ),
      );
    }

    // 가계부 메인 리스트 미러 — 카드 제거, 날짜 그룹 헤더(웹 DateGroupHeader
    // 정합: 날짜 primary/bold + 요일 tertiary + 우측 일 지출/수입 합계) + 플랫 행.
    final dayGroups = <String, List<Expense>>{};
    for (final e in list) {
      dayGroups.putIfAbsent(e.expenseDateOnly ?? '', () => <Expense>[]).add(e);
    }
    final entries = dayGroups.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var gi = 0; gi < entries.length; gi++) ...[
          // 헤더-행 간격은 행 자체 pt 12(웹 LedgerRow py-3)가 담당 — bottom 0.
          Padding(
            padding: EdgeInsets.only(top: gi == 0 ? 0 : PSpace.x16),
            child: _DayGroupHeader(
              dayKey: entries[gi].key,
              items: entries[gi].value,
              flags: flags,
              tokens: tokens,
            ),
          ),
          // 가계부와 같은 행이다 — "환불됨"·"기록만" 배지·취소선·예정 흐림을 그대로
          // 가진다(A3). 여기서 따로 그리면 그 표시가 이 화면에서만 빠진다.
          for (final e in entries[gi].value)
            ExpenseRow(
              gutter: 0,
              expense: e,
              category: null,
              flags: flags,
              showInstallment: true,
            ),
          // 이체는 시각이 없어(LocalDate) 그날의 맨 뒤 — web 정렬과 같은 자리.
          for (final tr in transfers.where(
            (x) =>
                (x.transferDate ?? '').length >= 10 &&
                x.transferDate!.substring(0, 10) == entries[gi].key,
          ))
            TransferRow(
              key: ValueKey('t${tr.rowId}'),
              transfer: tr,
              flags: flags,
              perspectiveAssetRowId: perspectiveAssetRowId,
              // 이 화면이 아직 좌우 24 를 쥔다 — 글자 자리가 24 로 같게 줄의 24 는 끈다.
              gutter: 0,
              onTap: () => showTransferDetailSheet(context, tr),
            ),
        ],
      ],
    );
  }
}

/// 날짜 그룹 헤더 — 웹 DateGroupHeader 미러 ("7월 8일" + "수" + 일 합계).
class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({
    required this.dayKey,
    required this.items,
    required this.flags,
    required this.tokens,
  });
  final String dayKey;
  final List<Expense> items;

  /// 지출합·수입합이 각자 종류를 갖는다.
  final MaskFlags flags;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(dayKey);
    final label = d == null ? null : formatDay(d);
    // 환불·예정은 빼고 **카드 이월은 넣는다** — 이 화면은 "이 카드로 쓴 것" 을 보여 주는
    // 자리라, 목록에 있는 이월 거래가 그날 합계에서만 빠지면 숫자가 안 맞는다(D4).
    final dayExpense = cardExpenseSum(items);
    final dayIncome = cardIncomeSum(items);
    return Row(
      children: [
        Text(
          label?.md ?? dayKey,
          style: PTypo.bodySm.copyWith(
            color: tokens.fgPrimary,
            fontWeight: PFontWeight.bold,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: PSpace.x8),
          Text(
            label.dow,
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
          ),
        ],
        const Spacer(),
        if (dayExpense > 0)
          Text(
            krwSigned(
              dayExpense,
              flags.of(MaskKind.expense),
              sign: '−',
              unit: true,
            ),
            style: PTypo.caption.copyWith(
              color: tokens.fgExpense,
              fontWeight: PFontWeight.semi,
            ),
          ),
        if (dayIncome > 0) ...[
          if (dayExpense > 0) const SizedBox(width: PSpace.x8),
          Text(
            krwSigned(
              dayIncome,
              flags.of(MaskKind.income),
              sign: '+',
              unit: true,
            ),
            style: PTypo.caption.copyWith(
              color: tokens.fgIncome,
              fontWeight: PFontWeight.semi,
            ),
          ),
        ],
      ],
    );
  }
}

/// 신용카드 청구 사이클 — 결제예정액·예정일 + '지금 결제' + 청구이력.
/// GET /asset/{id}/billing 사용. '지금 결제' 후 billing/assets invalidate.
/// 결제 회차(청구월) 항목 — 예정 1건 + 과거 결제 완료(COMPLETED) 이력.
class _CardStatement {
  const _CardStatement({
    required this.label,
    required this.scheduled,
    required this.amount,
    required this.paymentDate,
    this.periodStart,
    this.periodEnd,
    this.upcoming = false,
    this.installments = const [],
    this.lumpSumAmount,
    this.alreadyPaidAmount,
    this.paid,
    this.preRegistration = false,
  });
  final String label;
  final bool scheduled;
  final int amount;
  final String paymentDate;
  final String? periodStart;
  final String? periodEnd;

  /// 다가오는 회차(결제가 임박한 쪽) — 회차를 고르기 전 기본으로 열리는 행.
  final bool upcoming;

  /// 그 회차에 빠지는 할부 구성 — 닫힌 회차도 서버가 내려 준다(24차 8, 옛 서버면 빈 목록).
  final List<InstallmentDue> installments;

  /// 예정 회차의 일시불 순사용액·기결제액 — 예정액 합을 설명하는 요약 행.
  final int? lumpSumAmount;
  final int? alreadyPaidAmount;

  /// 닫힌 회차 — 계좌에서 실제로 나간 순 금액(결제 − 환급). 머리 금액(지금 기록 합)과
  /// 다를 때만 그 아래 한 줄로 말한다(D10). 예정 회차는 null.
  final int? paid;

  /// 카드 등록 전 회차 — 실제와 안 맞을 수 있다는 주의(R4).
  final bool preRegistration;
}

/// 카드 월 실적 배지 — design 신판(달성/잔여 요약, 웹 CardPerfBadge 미러).
/// 달성: cat-green 10% tint / 미달: sunken. 실적 무관 카드면 숨김.
class _CardPerfBadge extends ConsumerWidget {
  const _CardPerfBadge({required this.assetRowId, required this.masked});
  final int assetRowId;
  final bool masked;

  /// 줄 좌우 여백 — 목록이 끝까지 벌어져 있으므로 기본 24.
  double get gutter => PSpacing.globalGutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final ym = _currentYearMonth();
    final async = ref.watch(
      cardPerformanceProvider((assetRowId: assetRowId, yearMonth: ym)),
    );
    final p = async.value;
    if (async.isLoading && p == null) {
      return ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: PSpacing.x3,
          ),
          child: Row(
            children: [
              PSkeleton(width: 40, height: 40, borderRadius: PRadius.tile(40)),
              const SizedBox(width: PSpacing.x3),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PSkeleton.line(width: 110, height: 16),
                    SizedBox(height: 4),
                    PSkeleton.line(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 실적 무관 카드면 줄을 그리지 않는다. 실패도 그리지 않는다(실적은 덧붙임).
    if (p == null || !p.isRequired || p.requiredAmount == null) {
      return const SizedBox.shrink();
    }
    final done = p.isAchieved;
    final pct = (p.achievementRate.clamp(0, 1.5) * 100).truncate();
    final month = int.parse(ym.substring(5, 7));
    String money(int v) => krwSigned(v, false, unit: true);
    return PList(
      semanticLabel: l.assetPerfTitle('$month'),
      children: [
        PListItem(
          gutter: gutter,
          // 앞 타일 40 — 미달 chart-gray-weak + target, 달성 chart-green-weak + check (list.md 타일 · v111)
          prefix: PListTile(
            background: done ? c.chartGreenWeak : c.chartGrayWeak,
            color: done ? c.chartGreen : c.chartGray,
            child: Icon(done ? LucideIcons.check : LucideIcons.target),
          ),
          title: l.assetPerfTitle('$month'),
          detail: masked
              ? '••••••'
              : '${money(p.currentAmount)} / ${money(p.requiredAmount!)} · $pct%',
          suffix: PBadge(
            size: PBadgeSize.large,
            tone: done ? PBadgeTone.positive : PBadgeTone.neutral,
            label: done
                ? l.assetPerfAchieved
                : l.assetPerfRemain(
                    krwSigned(p.remainingAmount ?? 0, masked, unit: true),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 카드 상세 본문 — design card-detail.jsx 신판(현대카드 결제정보 패턴, 웹 CardDetailBody
/// 미러). 회차 히어로(기간 선택 시트) / 결제일·이용 기간 행 / 액션 2타일 /
/// 한도 사용 게이지·실적 배지 / 이용 내역(정렬 칩 + 날짜 그룹). CREDIT_CARD 전용.
class _CardDetailBody extends ConsumerStatefulWidget {
  const _CardDetailBody({
    required this.asset,
    required this.masked,
    this.onEdit,
  });
  final Asset asset;
  final bool masked;
  final VoidCallback? onEdit;

  @override
  ConsumerState<_CardDetailBody> createState() => _CardDetailBodyState();
}

enum _UsageSort { recent, amount, category }

/// 할부 정리가 실제로 청구하는 금액 — 원금에서 **앞 회차(정상 분할)에 이미 나눠 낸 몫**을 뺀 남은 원금.
/// 서버 `Expense.installmentAmountAt`(상환 회차) 와 같은 셈이다: 정상 분할은 원금÷N 이고 나머지는 1회차에 몰리므로
/// 앞 (sequence-1) 회차 합 = (sequence-1)×(원금÷N) + (sequence ≥ 2 ? 원금%N : 0). `InstallmentDue.amount` 는 이번 회차의
/// **정상 분할 몫**이라 이 자리에 쓰면 틀린다. 정리는 다가오는 회차에 걸리고 그 회차의 `sequence` 가 상환 회차다.
int installmentPayoffAmount(InstallmentDue due) {
  final n = due.installmentMonths <= 0 ? 1 : due.installmentMonths;
  final base = due.principalAmount ~/ n;
  final rem = due.principalAmount % n;
  final paidBefore = (due.sequence - 1) * base + (due.sequence >= 2 ? rem : 0);
  return due.principalAmount - paidBefore;
}

class _CardDetailBodyState extends ConsumerState<_CardDetailBody> {
  // null = 아직 고르지 않음 → 다가오는 회차를 기본으로 잡는다. 다음 회차가 맨 위에
  // 오므로 0 을 기본으로 두면 아직 쌓이는 중인 회차가 먼저 열린다.
  int? _stIdx;

  int _activeIdx(List<_CardStatement> stmts) {
    final i = _stIdx ?? stmts.indexWhere((s) => s.upcoming);
    return i.clamp(0, stmts.length - 1);
  }

  _UsageSort _sort = _UsageSort.recent;
  bool _paying = false;

  List<_CardStatement> _statements(CardBilling? b) {
    final out = <_CardStatement>[];
    // 다음 회차(지금 쌓이는 이용분)가 맨 위 — 최신순. 결제일이 지나기 전에도 이번 달 내역이 보인다.
    final n = b?.nextCycle;
    if (n != null) {
      final d = DateTime.tryParse(n.paymentDate);
      out.add(
        _CardStatement(
          label: d != null ? formatDay(d).md : n.paymentDate,
          scheduled: true,
          amount: n.amount,
          paymentDate: n.paymentDate,
          periodStart: n.periodStart,
          periodEnd: n.periodEnd,
          installments: n.installments,
          lumpSumAmount: n.lumpSumAmount,
          alreadyPaidAmount: n.alreadyPaidAmount,
        ),
      );
    }
    if (b?.nextPaymentDate != null) {
      final d = DateTime.tryParse(b!.nextPaymentDate!);
      out.add(
        _CardStatement(
          label: d != null ? formatDay(d).md : b.nextPaymentDate!,
          scheduled: true,
          amount: b.upcomingAmount,
          paymentDate: b.nextPaymentDate!,
          periodStart: b.upcomingPeriodStart,
          periodEnd: b.upcomingPeriodEnd,
          upcoming: true,
          installments: b.upcomingInstallments,
          lumpSumAmount: b.upcomingLumpSumAmount,
          alreadyPaidAmount: b.upcomingAlreadyPaidAmount,
        ),
      );
    }
    // 과거 회차 — 서버가 닫힌 회차를 내려 주면 그대로 쓴다. 결제 기록이 없는 회차(0원이라
    // 건너뜀·카드 등록 전)도 기록용 거래가 있으면 들어 있다. 머리 금액은 그 회차의 **지금
    // 기록 합**이다 — 아래 이용 내역 목록과 맞는다. 실제로 나간 돈이 다르면 그 아래 한
    // 줄로 말한다(D10). 옛 서버(기록 합 없음)면 결제액 + 기록만 금액이다. 웹 미러.
    final closed = b?.closedCycles;
    if (closed != null) {
      for (final c in closed) {
        final d = DateTime.tryParse(c.paymentDate);
        out.add(
          _CardStatement(
            label: d != null ? formatDay(d).md : c.paymentDate,
            scheduled: false,
            amount: c.recordedAmount ?? c.paidAmount + c.recordedOnlyAmount,
            paymentDate: c.paymentDate,
            periodStart: c.periodStart,
            periodEnd: c.periodEnd,
            installments: c.installmentDues,
            paid: c.paidAmount,
            preRegistration: c.preRegistration,
          ),
        );
      }
      return out;
    }
    // 옛 서버 — 결제월별 합산: 같은 달에 여러 번(선결제 등) 결제해도 월 1행(사용자 결정).
    // 라벨은 정규 결제일(paymentDay, 말일 보정), 기간은 결제월의 전월 1일~말일(백엔드 회차 규칙 미러).
    String pad2(int n) => n.toString().padLeft(2, '0');
    final byMonth = <String, ({int amount, String latest})>{};
    for (final h in b?.history ?? const <BillingItem>[]) {
      if (h.status != 'COMPLETED') continue;
      final ym = h.paymentDate.substring(0, 7);
      final cur = byMonth[ym];
      byMonth[ym] = cur == null
          ? (amount: h.billingAmount, latest: h.paymentDate)
          : (
              amount: cur.amount + h.billingAmount,
              latest: h.paymentDate.compareTo(cur.latest) > 0
                  ? h.paymentDate
                  : cur.latest,
            );
    }
    for (final entry in byMonth.entries) {
      final parts = entry.key.split('-');
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      final lastDay = DateTime(y, m + 1, 0).day;
      final rawDay =
          b?.paymentDay ??
          int.tryParse(entry.value.latest.substring(8, 10)) ??
          1;
      final day = rawDay > lastDay ? lastDay : rawDay;
      final paymentDate = '${entry.key}-${pad2(day)}';
      final py = m == 1 ? y - 1 : y;
      final pm = m == 1 ? 12 : m - 1;
      final pLast = DateTime(py, pm + 1, 0).day;
      out.add(
        _CardStatement(
          label: formatDay(DateTime(y, m, day)).md,
          scheduled: false,
          amount: entry.value.amount,
          paymentDate: paymentDate,
          periodStart: '$py-${pad2(pm)}-01',
          periodEnd: '$py-${pad2(pm)}-${pad2(pLast)}',
          // 옛 서버의 결제 완료 행 — 머리 금액이 곧 낸 돈이다.
          paid: entry.value.amount,
        ),
      );
    }
    return out;
  }

  /// 닫힌 회차 머리 아래 한 줄 — 기록 합(머리)과 계좌에서 나간 돈이 다를 때만(D10).
  ///
  /// 기록이 더 많으면(뒤늦게 적은 거래) 나간 돈과 나머지를, 기록이 더 적으면(지우거나
  /// 환불한 거래) 기록과 나간 돈을 말한다. 같으면 말이 없다.
  ///
  /// 낸 돈이 0 인 회차도 말이 없다 — "결제 완료" 자리에 이미 "기록 회차" 가 서 있어,
  /// "계좌에서 나간 돈은 0원이에요…" 는 같은 말을 한 번 더 하는 셈이다(QA 26 확인 필요).
  String? _closedCycleLine(AppLocalizations l, _CardStatement st, bool masked) {
    final paid = st.paid;
    if (paid == null || paid == 0) return null;
    final recorded = st.amount;
    String money(int v) => krwSigned(v, masked, unit: true);
    if (recorded > paid) {
      return l.assetClosedPaidLine(money(paid), money(recorded - paid));
    }
    if (recorded < paid) {
      return l.assetClosedOverpaidLine(money(recorded), money(paid));
    }
    return null;
  }

  /// 지금 결제 = 입력 폼 시트(I-17 53) — 금액을 고칠 수 있다(부분 선결제). 기본값은 남은 청구액.
  /// 일부만 내면 나머지는 결제일에 정상적으로 빠진다(서버가 '사용액 − 이미 결제액'으로 잡는다).
  /// 시트 한 장 — 상세 시트 위에 또 뜨지 않는다(페이지 위). 바깥 · 끌기로 안 닫히고, 금액을 바꾼 채 닫으면 묻는다.
  Future<void> _confirmAndPay(CardBilling b, _CardStatement st) {
    final l = AppLocalizations.of(context);
    // 돈은 잔액에 잡힌 빚까지만 움직인다(서버 payoff 캡). 청구액이 그보다 크면 차액은
    // 청구 기록만 남고 계좌에서 안 빠진다 — 완료만 보고 빠진 줄 아는 일이 없게 미리 알린다.
    final balance = widget.asset.balance ?? 0;
    final debt = balance < 0 ? -balance : 0;
    final focus = FocusNode(debugLabel: 'CardPay amount');
    final probe = _PayProbe();
    return PBottomSheet.show<void>(
      context,
      form: true,
      // 새 폼은 첫 칸(금액)에 초점이 간다
      initialFocus: focus,
      isDirty: () => probe.dirty(),
      leaveCopy: PLeaveConfirmCopy(
        title: l.sheetLeaveTitle,
        description: l.sheetLeaveDescription,
        stayLabel: l.sheetLeaveStay,
        leaveLabel: l.sheetLeaveLeave,
      ),
      builder: (_) => _PaySheet(
        probe: probe,
        focus: focus,
        // 고른 회차의 예정액이 상한 — 다음 회차를 미리 낼 수도 있다.
        upcoming: st.amount,
        paymentDate: st.paymentDate,
        debt: debt,
        hasPayAccount: b.paymentAssetRowId != null,
        masked: widget.masked,
        // 요청 · 금액 · 결제일 · 무효화는 그대로 — 이중 진입은 _paying 이 막는다.
        onPay: (amount) => _pay(amount, st.paymentDate),
      ),
    );
  }

  /// 결제 요청(silent) — 성공이면 true. 실패는 호출한 시트가 맨 위 Callout 으로 보인다.
  Future<bool> _pay(int amount, String paymentDate) async {
    // 진입에서 바로 막는다 — 첫 줄과 setState 사이에 await 가 없어 두 번째 호출은 여기서 끝난다.
    if (_paying) return false;
    setState(() => _paying = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.payCard(
        widget.asset.rowId,
        amount: amount,
        paymentDate: paymentDate,
        silent: true,
      );
      ref.invalidate(cardBillingProvider(widget.asset.rowId));
      // 결제는 이체를 만든다 — 결제 계좌 잔액·홈 순자산·가계부까지 함께 바뀐다.
      invalidateAfterExpenseChange(ref);
      return true;
    } on ApiException {
      return false;
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  /// 되돌릴 수 있는 가장 최근 결제 — 없으면 [결제 취소] 를 숨긴다.
  ///
  /// 결제는 실행하면 되돌릴 길이 없었다 — 그 이체는 청구와 묶여 있어 잠가 뒀고 취소
  /// 경로도 없었다. 잘못 눌렀을 때 바로 무를 수 있게 한 건을 짚어 준다.
  ///
  /// 단 둘은 무를 수 없다(D6, 서버도 400 으로 막는다) — 그런 결제는 **고르지 않고** 그
  /// 앞의 무를 수 있는 결제를 찾는다. 가장 최근 결제만 보고 그게 못 무르는 것이면 버튼을
  /// 숨겼더니, 닫힌 회차 자동 결제 뒤에 있던 열린 회차 선결제까지 무를 길이 없었다
  /// (QA 26 확인 필요). 웹과 같은 판정이다.
  ///   - **결제일이 된 회차**의 결제 — 무르면 그 회차를 다시 낼 길이 없어 빚이 떠돈다.
  ///     회차 말일이 카드의 `cardClosedThrough` 이하이거나 서버가 내려 준 닫힌 회차 목록에
  ///     든 회차다. 결제 행의 날짜는 수동 결제면 누른 날이라 회차의 결제일이 아니다
  ///   - **환급이 나간 회차**의 결제 — 결제만 되돌리면 돌려준 돈이 통장에 남아 유령 빚이
  ///     된다. 같은 회차에 REFUNDED 행이 있으면 그렇다
  BillingItem? _cancellablePayment(CardBilling? b) {
    final history = b?.history ?? const <BillingItem>[];
    final closedThrough = widget.asset.cardClosedThrough;
    final closedStarts = {
      for (final c in b?.closedCycles ?? const <ClosedCycle>[]) c.periodStart,
    };
    final refundedStarts = {
      for (final h in history)
        if (h.status == 'REFUNDED') h.periodStart,
    };
    final cancellable = history.where(
      (h) =>
          h.status == 'COMPLETED' &&
          !(closedThrough != null &&
              h.periodEnd.compareTo(closedThrough) <= 0) &&
          !closedStarts.contains(h.periodStart) &&
          !refundedStarts.contains(h.periodStart),
    );
    if (cancellable.isEmpty) return null;
    return cancellable.reduce(
      (a, x) => x.paymentDate.compareTo(a.paymentDate) > 0 ? x : a,
    );
  }

  /// 확인창 뒤 요청의 공통 모양 — 실패하면 확인창이 닫힌 뒤 critical 스낵바 + [다시 시도](묻지 않고 바로 요청).
  /// 요청은 silent, 성공 뒷정리는 바로 성공(ok)과 다시 시도 성공([onRetried]) 두 길이 같다.
  Future<void> _confirmThen({
    required String title,
    required String description,
    required String failedMessage,
    required Future<void> Function(AssetRepository repo) call,
    bool destructive = false,
    bool block = false,
  }) async {
    if (_paying) return;
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final id = widget.asset.rowId;
    Future<void> request() async {
      final repo = await container.read(assetRepositoryProvider.future);
      await call(repo);
      // 이체·잔액·청구가 함께 바뀐다 — 가계부도 비운다(이자 지출 등).
      container.invalidate(cardBillingProvider(id));
      invalidateAfterExpenseChangeIn(container);
    }

    if (block) setState(() => _paying = true);
    try {
      await askConfirmThenRequest(
        context,
        title: title,
        description: description,
        cancelLabel: l.actionCancel,
        actionLabel: title,
        destructive: destructive,
        request: request,
        failedMessage: failedMessage,
        retryLabel: l.actionRetry,
      );
    } finally {
      if (block && mounted) setState(() => _paying = false);
    }
  }

  /// 할부 중도 전액 상환 — 남은 원금이 다가오는 결제 예정액에 한 번에 잡힌다.
  Future<void> _confirmPayoff(InstallmentDue due) {
    final l = AppLocalizations.of(context);
    return _confirmThen(
      title: l.assetInstallmentPayoff,
      description: l.assetInstallmentPayoffConfirm(
        widget.masked ? '••••' : krw(installmentPayoffAmount(due)),
      ),
      failedMessage: l.assetInstallmentPayoffFailed,
      call: (repo) => repo.payoffInstallment(
        widget.asset.rowId,
        due.expenseRowId,
        silent: true,
      ),
      block: true,
    );
  }

  /// 상환 취소 — 정상 분할로 되돌린다. 잘못 누른 상환을 무르는 경로.
  Future<void> _undoPayoff(InstallmentDue due) {
    final l = AppLocalizations.of(context);
    return _confirmThen(
      title: l.assetInstallmentPayoffUndo,
      description: l.assetInstallmentPayoffUndoConfirm,
      failedMessage: l.assetInstallmentPayoffUndoFailed,
      call: (repo) => repo.cancelInstallmentPayoff(
        widget.asset.rowId,
        due.expenseRowId,
        silent: true,
      ),
      block: true,
    );
  }

  Future<void> _confirmAndCancelPayment(BillingItem billing) {
    final l = AppLocalizations.of(context);
    return _confirmThen(
      title: l.assetCancelPayment,
      description: l.assetCancelPaymentConfirm(
        widget.masked ? '••••' : krw(billing.billingAmount),
        billing.paymentDate,
      ),
      failedMessage: l.assetCancelPaymentFailed,
      call: (repo) => repo.cancelCardPayment(billing.rowId, silent: true),
      destructive: true,
      block: true,
    );
  }

  /// 페이지 위에서 수정 폼 2단계를 연다(39) — 화면을 옮기지 않는다.
  void _goEdit() {
    if (widget.onEdit != null) {
      widget.onEdit!();
    } else {
      showAssetEditForm(context, widget.asset);
    }
  }

  /// 결제 회차 고르기(I-17 54) — 고르기 시트. 연도 묶음 머리 + 라디오 줄, 누르면 바로 고르고 닫힌다.
  Future<void> _openPeriodPicker(List<_CardStatement> stmts) async {
    final activeIdx = _activeIdx(stmts);
    final byYear = <String, List<(int, _CardStatement)>>{};
    for (var i = 0; i < stmts.length; i++) {
      byYear.putIfAbsent(stmts[i].paymentDate.substring(0, 4), () => []).add((
        i,
        stmts[i],
      ));
    }
    final picked = await PBottomSheet.show<int>(
      context,
      builder: (sheetContext) {
        final sl = AppLocalizations.of(sheetContext);
        return PBottomSheetContent(
          title: sl.assetPeriodPick,
          closeLabel: sl.actionClose,
          flushBody: true,
          scrollFog: true,
          body: _PeriodPickBody(
            byYear: byYear,
            activeIdx: activeIdx,
            masked: widget.masked,
            onPick: (i) => PBottomSheet.of(sheetContext).close(i),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _stIdx = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final masked = widget.masked;
    final asset = widget.asset;
    final billingAsync = ref.watch(cardBillingProvider(asset.rowId));
    final b = billingAsync.value;
    final stmts = _statements(b);
    final st = stmts.isEmpty ? null : stmts[_activeIdx(stmts)];

    final limit = asset.creditLimit ?? 0;
    final used = (asset.balance ?? 0).abs();
    // 실사용률 그대로 — 한도의 20배를 썼으면 2000% 로 보인다(사용자 결정).
    // 100 으로 눌러 두면 목록(실퍼센트)과 다른 숫자가 나오고, 얼마나 넘겼는지도
    // 안 보인다. 바 채움만 아래에서 100% 로 캡한다(넘치면 그릴 수 없다).
    final limitPct = limit > 0 ? ((used / limit) * 100).round() : 0;
    final paymentDay = b?.paymentDay ?? asset.paymentDay;
    final cancellable = _cancellablePayment(b);
    // 이용 내역의 금액 가리기 — 화면·종류 카드에 이 카드 자체의 숨김까지(합집합).
    final flags = _assetMaskFlags(ref, asset);
    // 고른 회차 기준 — 다가오는 회차를 다 낸 뒤 다음 회차를 골라도 낼 수 있어야 한다.
    final canPay =
        (st?.scheduled == true ? st!.amount : (b?.upcomingAmount ?? 0)) > 0 &&
        !_paying;
    final periodText = st?.periodStart != null && st?.periodEnd != null
        ? '${_fmtDate(st!.periodStart!)} ~ ${_fmtDate(st.periodEnd!)}'
        : null;
    // 이용 내역 — 선택 회차의 청구 기간(전월 1일~말일)만 조회(사용자 결정).
    // 기간 미확정(폴백 회차)이면 카드 전체 최근 12건.
    final usageAsync = st?.periodStart != null && st?.periodEnd != null
        ? ref.watch(
            assetPeriodExpensesProvider((
              assetId: asset.rowId,
              startDate: st!.periodStart!,
              endDate: st.periodEnd!,
            )),
          )
        : ref.watch(expensesByAssetProvider((assetId: asset.rowId, limit: 12)));
    final t = context.tokens;

    if (billingAsync.isLoading && b == null) {
      // 실렌더 미러 — 회차 단추 / 금액 / 키-값 / 동작. 자리를 잡아야 데이터가 오는 순간 아래가 밀리지 않는다.
      return const ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x3,
            PSpacing.globalGutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PSkeleton.line(width: 130, height: 20),
              SizedBox(height: PSpacing.x3),
              PSkeleton.line(width: 180, height: 32),
              SizedBox(height: PSpacing.x4),
              PSkeleton.line(width: double.infinity, height: 20),
              SizedBox(height: PSpacing.x4),
              PSkeleton(
                width: double.infinity,
                height: 40,
                borderRadius: PRadius.brMd,
              ),
            ],
          ),
        ),
      );
    }

    const gutter = PSpacing.globalGutter;
    final closed = st != null && !st.scheduled;
    final mix = st != null && st.scheduled && st.installments.isNotEmpty;
    final closedMix = closed && st.installments.isNotEmpty;
    // 지금 결제 — 닫힌 회차를 보고 있을 땐 숨긴다(D10). 그 회차는 이미 결제일이 지나 더 낼 것이 없다.
    final showPayNow = st == null || st.scheduled;
    String won(int v) => masked ? '••••••' : krwSigned(v, false, unit: true);

    Widget note(String text, Key key) => Padding(
      padding: const EdgeInsets.fromLTRB(gutter, PSpacing.x1, gutter, 0),
      child: Text(
        text,
        key: key,
        style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
      ),
    );

    // 이번 회차 구성 줄 — 닫힌 회차도 서버가 구성을 내려 준다(24차 8). 기록용 회차분이면 "· 기록만" 을 붙이고,
    // 이미 결제일이 지난 회차라 정리 · 되돌리기는 두지 않는다.
    List<Widget> dueRows() => [
      for (final due in st!.installments)
        PListItem(
          align: PListAlign.top,
          title:
              '${due.merchant ?? due.description ?? l.assetInstallmentFallback} ${l.assetInstallmentSeq(due.sequence, due.installmentMonths)}',
          detailChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${masked ? '••••••' : l.assetInstallmentPrincipal(won(due.principalAmount))}${due.recordOnly ? ' · ${l.expRecordOnlyBadge}' : ''}',
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
              // 정리/되돌리기 — 상환하면 남은 원금이 이 회차에 몰리므로 두 상태가 같은 자리를 쓴다.
              if (mix)
                due.paidOff
                    ? Padding(
                        padding: const EdgeInsets.only(top: PSpacing.x1),
                        child: Wrap(
                          spacing: PSpacing.x2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PBadge(
                              variant: PBadgeVariant.outline,
                              tone: PBadgeTone.positive,
                              label: l.assetInstallmentPaidOffBadge,
                            ),
                            Align(
                              heightFactor: _kTextLinkHeightFactor,
                              child: PListAction(
                                child: dsb.PButton(
                                  label: l.assetInstallmentPayoffUndo,
                                  variant: dsb.PButtonVariant.ghost,
                                  size: dsb.PButtonSize.small,
                                  flush: dsb.PButtonFlush.left,
                                  onPressed: () => _undoPayoff(due),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: PSpacing.x1),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          // 웹 -my-x1 — 보이는 36 은 그대로 두고 자리만 위아래 4 씩 줄인다
                          heightFactor: _kTextLinkHeightFactor,
                          child: PListAction(
                            child: dsb.PButton(
                              label: l.assetInstallmentPayoff,
                              variant: dsb.PButtonVariant.ghost,
                              size: dsb.PButtonSize.small,
                              flush: dsb.PButtonFlush.left,
                              onPressed: () => _confirmPayoff(due),
                            ),
                          ),
                        ),
                      ),
            ],
          ),
          suffix: Text(
            masked ? '••••••' : keepAllAmount(won(due.amount)),
            textAlign: TextAlign.end,
            style: PTypography.t5.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
    ];

    Widget mixHeader() => PListHeader(
      title: l.assetCycleMix,
      variant: PListHeaderVariant.boldSolid,
      topInset: PSpacing.x4,
    );

    // 한도 사용 막대 — 이름 "{이름} {한도} 중 {사용}", 값 글은 "88%" · 넘치면 "{금액} 초과". 80% 경고 색은 없다.
    final over = used > limit;
    final ratio = limit > 0 ? used / limit : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 결제 예정 — 회차 단추 + 금액(R13). 회차가 하나도 없으면 단추 없이 라벨 + "0원".
        if (st == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(gutter, PSpacing.x3, gutter, 0),
            child: Text(
              l.assetDueThisMonth,
              style: PTypography.t3.copyWith(
                color: c.fgNeutralSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(gutter, PSpacing.x2, gutter, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _PeriodButton(
                label: l.assetDueOn(st.label),
                scheduled: st.scheduled,
                onTap: () => _openPeriodPicker(stmts),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(gutter, PSpacing.x1, gutter, 0),
          child: Text(
            masked ? '••••••' : keepAllAmount(won(st?.amount ?? 0)),
            semanticsLabel: masked ? '••••••' : won(st?.amount ?? 0),
            style: PTypography.t9.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        // 낸 돈이 0 인 회차는 "결제 완료" 가 아니다 — 기록만 있는 회차다(D10).
        if (closed)
          Padding(
            padding: const EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: st.paid == 0
                  ? PBadge(
                      key: const ValueKey('record-cycle-label'),
                      label: l.assetRecordCycle,
                    )
                  : PBadge(
                      tone: PBadgeTone.positive,
                      prefixIcon: LucideIcons.check,
                      label: l.assetPaidDone,
                    ),
            ),
          ),
        // 머리 금액(지금 기록 합)과 실제로 나간 돈이 다를 때만 한 줄(D10). 문장은 남기고 금액만 가린다.
        if (closed)
          if (_closedCycleLine(l, st, masked) case final line?)
            note(line, const ValueKey('closed-cycle-paid-line')),
        if (closed && st.preRegistration)
          note(
            l.assetPreRegistrationNote,
            const ValueKey('pre-registration-note'),
          ),

        // 키-값 — 결제일 · 카드 이용 기간. 결제일이 없는 옛 카드는 값 자리에서 넣으라고 말한다(D8, 누르면 수정 폼).
        const SizedBox(height: PSpacing.x1),
        if (paymentDay != null)
          KvRow(
            label: l.assetPaymentDay,
            value: l.assetMonthlyPaymentDay(paymentDay),
          )
        else
          PList(
            children: [
              PListItem(
                title: l.assetPaymentDay,
                suffix: PListAction(
                  child: dsb.PButton(
                    key: const ValueKey('payment-day-missing'),
                    label: l.assetPaymentDayMissing,
                    variant: dsb.PButtonVariant.ghost,
                    size: dsb.PButtonSize.small,
                    flush: dsb.PButtonFlush.right,
                    onPressed: _goEdit,
                  ),
                ),
              ),
            ],
          ),
        if (periodText != null)
          KvRow(label: l.assetUsagePeriodLabel, value: periodText),

        // 이번 회차 구성 — 할부가 있을 때만. 예정액이 이용 내역 합과 다른 이유(과거 할부의 이번 회차분)를 설명한다.
        if (mix) ...[
          mixHeader(),
          PList(
            semanticLabel: l.assetCycleMix,
            children: [
              ...dueRows(),
              // 일시불·선결제 요약 — 할부와 함께 있어야 예정액 합이 설명된다.
              if ((st.lumpSumAmount ?? 0) != 0)
                PListItem(
                  title: l.assetLumpSumLabel,
                  suffix: Text(
                    keepAllAmount(won(st.lumpSumAmount!)),
                    textAlign: TextAlign.end,
                    style: PTypography.t5.copyWith(
                      color: c.fgNeutralMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              if ((st.alreadyPaidAmount ?? 0) > 0)
                PListItem(
                  title: l.assetAlreadyPaidLabel,
                  suffix: Text(
                    masked
                        ? '••••••'
                        : keepAllAmount('$kMinus${won(st.alreadyPaidAmount!)}'),
                    textAlign: TextAlign.end,
                    style: PTypography.t5.copyWith(
                      color: c.fgNeutralMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
        ],
        // 닫힌 회차의 할부 회차분 — 같은 줄, 동작 없음.
        if (closedMix) ...[
          mixHeader(),
          PList(semanticLabel: l.assetCycleMix, children: dueRows()),
        ],

        // 동작(4-3A) — [지금 결제] [결제 취소]. 하나만 보이면 그 하나가 폭 전체.
        if (showPayNow || cancellable != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              gutter,
              PSpacing.x4,
              gutter,
              PSpacing.x1,
            ),
            child: () {
              final pay = dsb.PButton(
                label: l.assetPayNow,
                variant: dsb.PButtonVariant.neutralWeak,
                prefixIcon: LucideIcons.zap,
                // 낼 것이 없으면 막힘(ds disabled)
                onPressed: canPay && b != null && st != null
                    ? () => _confirmAndPay(b, st)
                    : null,
              );
              final cancel = cancellable == null
                  ? null
                  : dsb.PButton(
                      label: l.assetCancelPayment,
                      variant: dsb.PButtonVariant.neutralWeak,
                      prefixIcon: LucideIcons.undo2,
                      onPressed: _paying
                          ? null
                          : () => _confirmAndCancelPayment(cancellable),
                    );
              if (showPayNow && cancel != null) {
                return PResponsivePair(primary: pay, secondary: cancel);
              }
              return SizedBox(width: double.infinity, child: cancel ?? pay);
            }(),
          ),

        // 한도 사용 · 실적
        if (limit > 0) ...[
          PListHeader(
            title: l.assetLimitUsage,
            variant: PListHeaderVariant.boldSolid,
            topInset: PSpacing.x4,
            trailing: Text(
              l.assetLimitPctUsed(limitPct),
              style: PTypography.t4.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              gutter,
              PSpacing.x1,
              gutter,
              PSpacing.x2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PProgressBar(
                  value: used.toDouble(),
                  max: limit.toDouble(),
                  semanticsLabel: l.dsProgressSemantics(
                    l.assetCardLimitName(asset.assetName),
                    won(limit),
                    won(used),
                  ),
                  semanticsValue: over
                      ? l.dsProgressOver(won(used - limit))
                      : '${(math.min(ratio, 1.0) * 100).round()}%',
                ),
                const SizedBox(height: PSpacing.x2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        masked
                            ? '••••••'
                            : l.assetLimitOf(won(used), won(limit)),
                        style: PTypography.t3.copyWith(
                          color: c.fgNeutralSubtle,
                        ),
                      ),
                    ),
                    const SizedBox(width: PSpacing.x2),
                    Flexible(
                      child: Text(
                        masked
                            ? '••••••'
                            : over
                            ? l.dsProgressOver(won(used - limit))
                            : l.assetLimitRemain(won(limit - used)),
                        textAlign: TextAlign.end,
                        style: PTypography.t3.copyWith(
                          color: over ? c.fgCritical : c.fgNeutralSubtle,
                          fontWeight: over ? FontWeight.w700 : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        _CardPerfBadge(assetRowId: asset.rowId, masked: masked),

        // 이용 내역(49)
        _usageSection(l, asset, usageAsync, flags, t),
      ],
    );
  }

  Widget _usageSection(
    AppLocalizations l,
    Asset asset,
    AsyncValue<List<Expense>> usageAsync,
    MaskFlags flags,
    GrooTokens t,
  ) {
    final c = context.colors;
    final n = usageAsync.value?.length ?? 0;
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.globalGutter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 목록 제목 "이용 내역 · {n}" + 오른쪽 글 버튼 "전체 보기"(49) — 옛 구분선 · 꺾쇠 단추를 걷었다.
        PListHeader(
          title: n > 0 ? '${l.assetUsageHistory} · $n' : l.assetUsageHistory,
          variant: PListHeaderVariant.boldSolid,
          topInset: PSpacing.x4,
          action: PTextButton(
            label: l.assetViewAll,
            onPressed: () => context.go('/expense?assetId=${asset.rowId}'),
          ),
        ),
        // 정렬 — ds Segmented Control(최근순 · 고액순 · 카테고리별)
        Padding(
          padding: gutter.copyWith(top: PSpacing.x1, bottom: PSpacing.x1),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PSegmentedControl<_UsageSort>(
              semanticLabel: l.assetSortAria,
              value: _sort,
              onChanged: (v) => setState(() => _sort = v),
              items: [
                PSegmentedItem(
                  value: _UsageSort.recent,
                  label: l.assetSortRecent,
                ),
                PSegmentedItem(
                  value: _UsageSort.amount,
                  label: l.assetSortAmount,
                ),
                PSegmentedItem(
                  value: _UsageSort.category,
                  label: l.assetSortCategory,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: gutter,
          child: _sort == _UsageSort.recent
              ? _RecentExpenses(async: usageAsync, flags: flags, tokens: t)
              : _plainUsage(l, usageAsync, flags, c),
        ),
      ],
    );
  }

  /// 고액순 · 카테고리별 — 날짜 묶음 없이 늘어놓는 줄. 비면 가운데 한 줄.
  Widget _plainUsage(
    AppLocalizations l,
    AsyncValue<List<Expense>> usageAsync,
    MaskFlags flags,
    PColors c,
  ) {
    final list = [...(usageAsync.value ?? const <Expense>[])];
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
        child: Center(
          child: Text(
            l.assetNoUsage,
            style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
      );
    }
    if (_sort == _UsageSort.amount) {
      list.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    } else {
      list.sort(
        (a, b) => (a.categoryName ?? '').compareTo(b.categoryName ?? ''),
      );
    }
    return Column(
      children: [
        for (final e in list)
          ExpenseRow(
            gutter: 0,
            expense: e,
            category: null,
            flags: flags,
            showInstallment: true,
          ),
      ],
    );
  }
}

/// 지금 결제 폼 시트가 "바꾼 값이 있나" 를 시트 밖에 알려 주는 통로.
class _PayProbe {
  bool Function() dirty = () => false;
}

/// 지금 결제 = 입력 폼(I-17 53). 안내 글 → (실패 Callout) → (돈이 다 안 움직이는 안내 Callout) → 결제 금액 칸.
/// 금액 검사(0 < 금액 ≤ 예정액)는 그대로이되 주 버튼을 막지 않고 누르면 칸 아래 오류. 요청은 [onPay] — 실패하면 시트 안에
/// 맨 위가 아니라 안내 아래 Callout(입력 금액 유지 · 시트 유지 · 스낵바 없음).
class _PaySheet extends StatefulWidget {
  const _PaySheet({
    required this.probe,
    required this.focus,
    required this.upcoming,
    required this.paymentDate,
    required this.debt,
    required this.hasPayAccount,
    required this.masked,
    required this.onPay,
  });
  final _PayProbe probe;
  final FocusNode focus;
  final int upcoming;
  final String paymentDate;
  final int debt;
  final bool hasPayAccount;
  final bool masked;
  final Future<bool> Function(int amount) onPay;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  late final TextEditingController _ctrl;
  late final String _initial;
  final _errorKey = GlobalKey();
  bool _tried = false;
  bool _failed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initial = formatAmountInput(widget.upcoming);
    _ctrl = TextEditingController(text: _initial);
    widget.probe.dirty = () => _ctrl.text != _initial;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    widget.focus.dispose();
    super.dispose();
  }

  int get _amount => parseAmountInput(_ctrl.text) ?? 0;

  String _money(int v) => krwSigned(v, widget.masked, unit: true);

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _tried = true);
    final v = _amount;
    if (v <= 0 || v > widget.upcoming) {
      widget.focus.requestFocus();
      return;
    }
    setState(() {
      _failed = false;
      _submitting = true;
    });
    final ok = await widget.onPay(v);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      PBottomSheet.of(context).close();
      return;
    }
    setState(() => _failed = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _errorKey.currentContext;
      if (c != null) revealBelowFog(c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final v = _amount;
    final upcoming = widget.upcoming;
    final d = DateTime.tryParse(widget.paymentDate);
    final dateText = d != null ? formatDay(d).md : widget.paymentDate;
    final error = !_tried
        ? null
        : v <= 0
        ? l.assetPayAmountEmpty
        : v > upcoming
        ? l.assetPayAmountOver(_money(upcoming))
        : null;
    final moveNote = !widget.hasPayAccount
        ? l.assetPayNoAccountNote
        : (widget.debt < v
              ? l.assetPayMoveNote(krwSigned(widget.debt, false, unit: true))
              : null);
    return PBottomSheetContent(
      title: l.assetPayNow,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          0,
          PSpacing.globalGutter,
          PSpacing.x2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l.assetPayConfirmMessage(_money(upcoming))}${l.assetPayConfirmDateSuffix(dateText)}',
              style: PTypography.t5.copyWith(color: c.fgNeutralMuted),
            ),
            const SizedBox(height: PSpacing.x4),
            // 폼 저장 실패 = 안내 아래 Callout(웹과 같은 자리). 다시 누르면 지워진다.
            if (_failed)
              FormErrorCallout(key: _errorKey, message: l.assetPayFailed),
            if (moveNote != null) ...[
              PCallout(tone: PCalloutTone.warning, description: moveNote),
              const SizedBox(height: PSpacing.x4),
            ],
            dsf.PField(
              label: l.assetPayAmount,
              invalid: error != null,
              errorMessage: error,
              description: v > 0 && v < upcoming
                  ? l.assetPayRemainder(_money(upcoming - v))
                  : null,
              child: PInput(
                variant: PInputVariant.underline,
                controller: _ctrl,
                focusNode: widget.focus,
                placeholder: '0',
                suffixText: wonUnit(),
                tabularFigures: true,
                keyboardType: TextInputType.number,
                // 값 범위는 _submit(0 < v <= 예정액)이 잡는다 — 여기서는 숫자만(청구 로직은 건드리지 않는다).
                inputFormatters: const [AmountInputFormatter()],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
      footer: [
        dsb.PButton(
          label: l.assetPayAction,
          size: dsb.PButtonSize.large,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// 결제 회차 고르기 본문(I-17 54) — 연도마다 List Header "{연도}년" + 라디오 줄(제목 "{M월 D일} 결제" + 예정 배지 · 뒤 금액).
/// 열면 고른 줄이 보이게 스크롤한다.
class _PeriodPickBody extends StatefulWidget {
  const _PeriodPickBody({
    required this.byYear,
    required this.activeIdx,
    required this.masked,
    required this.onPick,
  });
  final Map<String, List<(int, _CardStatement)>> byYear;
  final int activeIdx;
  final bool masked;
  final ValueChanged<int> onPick;

  @override
  State<_PeriodPickBody> createState() => _PeriodPickBodyState();
}

class _PeriodPickBodyState extends State<_PeriodPickBody> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _selectedKey.currentContext;
      if (c != null && c.mounted) {
        Scrollable.ensureVisible(c, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in widget.byYear.entries)
          PListRadioGroup<int>(
            semanticLabel: l.assetYearLabel(entry.key),
            value: widget.activeIdx,
            onChanged: widget.onPick,
            children: [
              PListHeader(title: l.assetYearLabel(entry.key)),
              for (final (i, s) in entry.value)
                PListRadioItem<int>(
                  key: i == widget.activeIdx ? _selectedKey : null,
                  value: i,
                  title: l.assetDueOn(s.label),
                  titleSuffix: s.scheduled
                      ? [PBadge(label: l.assetScheduledTag)]
                      : null,
                  detail: widget.masked
                      ? '••••••'
                      : krwSigned(s.amount, false, unit: true),
                ),
            ],
          ),
      ],
    );
  }
}

/// 회차 단추(I-17 46) — ghost small "{M월 D일} 결제" + 예정이면 Badge "예정" + 뒤 꺾쇠 16. 누르면 결제 회차 고르기(54).
class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.scheduled,
    required this.onTap,
  });
  final String label;
  final bool scheduled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dsb.PButton(
          label: label,
          variant: dsb.PButtonVariant.ghost,
          size: dsb.PButtonSize.small,
          flush: dsb.PButtonFlush.left,
          onPressed: onTap,
        ),
        // 배지와 꺾쇠도 같은 단추의 일부다 — 눌러도 열린다(읽는 이름은 앞 단추 하나).
        ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpacing.x2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (scheduled) ...[
                    const SizedBox(width: PSpacing.x1),
                    PBadge(label: l.assetScheduledTag),
                  ],
                  const SizedBox(width: PSpacing.x1),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: c.fgNeutralMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 'yyyy-MM-dd' → 'M.d' 표기.
String _fmtDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || d == null) return iso;
  return '$m.$d';
}

/// stats 차트와 동일한 만/억 단위 — 한글 단위가 KRW 와 어울리고
/// '4.3M'/'-40.4M' 보다 짧게 표현돼 reservedSize 안에 안전히 들어간다.

String _currentYearMonth() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}';
}
