import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 구독 관리 화면 — 흰 화면 하나(I-14 3-2A · 14-2). 옛 바텀시트(0.92 고정)를 대신한다.
///
/// 위에서 아래로 — 지금 플랜 줄 → 안내 상자 → 주기 고르기 → 요금(List 줄 둘) → "기능 비교" → 기능 줄 셋, 바닥 띠에
/// [구독 해지] / [Pro 시작하기]. 요금 · 기능 비교는 흰 면 위 테두리 상자 없이 List 줄이다(Q2 = B). 가격은 전부 서버 값
/// (`PlanInfo.price` · `SubscriptionInfo.price`)이고 연간 할인율도 두 가격에서 계산한다. 결제(PG)는 없다 — 구독은 자기
/// 부여, 해지는 취소 표시다.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

enum _Cycle { monthly, yearly }

class _PlanFeature {
  const _PlanFeature(this.label, {required this.free});
  final String label;

  /// Free 에도 있는가 — Pro 는 셋 다 있다.
  final bool free;
}

/// Pro 가 실제로 더 주는 것은 증권 하나다 — 플랜 features 는 `["SECURITIES"]` 뿐이고 서버 게이트도 증권 API 에만 걸려
/// 있다. 표에만 있는 제한은 광고가 된다(QA #161).
List<_PlanFeature> _featuresOf(AppLocalizations l) => <_PlanFeature>[
  _PlanFeature(l.subFeatLedger, free: true),
  _PlanFeature(l.subFeatBudget, free: true),
  _PlanFeature(l.subFeatSecurities, free: false),
];

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  /// 사용자가 고른 주기 — 아직 안 골랐으면 null(처음 값은 지금 구독의 주기).
  _Cycle? _picked;
  bool _busy = false;

  void _retry() {
    ref.invalidate(mySubscriptionProvider);
    ref.invalidate(subscriptionPlansProvider);
    ref.invalidate(myFeaturesLoadProvider);
  }

  Future<void> _subscribe(String planCode) async {
    final l = AppLocalizations.of(context);
    // 요청 중 ← 로 떠나도 무효화가 되도록 컨테이너 · 알림 길을 미리 쥔다(해지와 같다)
    final container = ProviderScope.containerOf(context);
    final snack = PSnackbar.maybeOf(context);
    setState(() => _busy = true);
    try {
      final repo = await container.read(subscriptionRepositoryProvider.future);
      await repo.subscribe(planCode, silent: true);
    } catch (e) {
      // 응답을 못 받았다 — 구독됐을 수 있다(결제). [다시 시도] 를 주면 두 번 구독될 수 있어 다시 받고 확인을 부탁한다(검수 M3)
      if (isUnconfirmedSave(e)) {
        container.invalidate(myFeaturesLoadProvider);
        container.invalidate(mySubscriptionProvider);
        snack?.show(
          message: unconfirmedWriteText(l, WriteKind.process),
          tone: PSnackbarTone.critical,
        );
        if (mounted) setState(() => _busy = false);
        return;
      }
      // 서버 글을 내지 않는다 — 정한 글 하나
      // 서버 글을 내지 않는다 — 정한 글 하나 + [다시 시도](같은 요금제로 구독을 다시)
      snack?.show(
        message: l.subFailed,
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(
          label: l.actionRetry,
          onPressed: () => _subscribe(planCode),
        ),
      );
      if (mounted) setState(() => _busy = false);
      return;
    }
    container.invalidate(myFeaturesLoadProvider);
    container.invalidate(mySubscriptionProvider);
    snack?.show(message: l.subStarted, tone: PSnackbarTone.positive);
    try {
      // 다시 받는 동안 [Pro 시작하기] 가 되살아나 한 번 더 눌리지 않게 busy 를 유지한다
      await container.read(mySubscriptionProvider.future);
    } catch (_) {
      // 구독은 이미 됐다 — 다시 받기 실패는 알리지 않는다(화면은 이전 값을 유지)
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _cancel(String nextBill) async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final snack = PSnackbar.maybeOf(context);
    Future<void> request() async {
      final repo = await container.read(subscriptionRepositoryProvider.future);
      await repo.cancelSubscription(silent: true);
    }

    void refresh() {
      container.invalidate(myFeaturesLoadProvider);
      container.invalidate(mySubscriptionProvider);
    }

    final ok = await askConfirmThenRequest(
      context,
      title: l.subCancelConfirmTitle,
      description: l.subCancelConfirmMsg(nextBill),
      actionLabel: l.subCancel,
      cancelLabel: l.subKeep,
      request: request,
      failedMessage: l.subCancelFailed,
      retryLabel: l.actionRetry,
      // [다시 시도] 로 성공해도 같은 알림 — 확인창에서 바로 성공한 것과 같다
      onRetried: () {
        refresh();
        snack?.show(message: l.subCanceled);
      },
      kind: WriteKind.process,
      onUnconfirmed: refresh,
    );
    if (!ok) return;
    refresh();
    snack?.show(message: l.subCanceled);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final subAsync = ref.watch(mySubscriptionProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final featuresAsync = ref.watch(myFeaturesProvider);

    // 데이터가 아직 없는 채로 실패한 것만 실패다 — 구독 · 해지 뒤 다시 받기만 실패했으면 가진 데이터를 그대로 둔다
    final plans = plansAsync.asData?.value ?? const <SubscriptionPlanInfo>[];
    final sub = subAsync.asData?.value?.resolvedWith(plans);
    final isPro = sub?.isActive ?? false;
    final refetching = subAsync.isLoading || plansAsync.isLoading;
    final dataFailed =
        (subAsync.hasError && !subAsync.hasValue) ||
        (plansAsync.hasError && !plansAsync.hasValue);
    // 요금제가 하나도 없으면 무엇을 구독할지 모른다 — 시작 단추 대신 실패(이미 Pro 면 해지는 할 수 있다)
    final noPlans =
        plansAsync.hasValue && plans.isEmpty && subAsync.hasValue && !isPro;
    final failed = dataFailed || noPlans;
    final loading =
        !failed &&
        ((subAsync.isLoading && !subAsync.hasValue) ||
            (plansAsync.isLoading && !plansAsync.hasValue) ||
            (featuresAsync.isLoading && !featuresAsync.hasValue));

    // 월간(1) · 연간(12). 기간을 안 주는 옛 서버의 단일 플랜은 월간으로 본다
    final monthly = plans
        .where((p) => p.durationMonths == 1 || p.durationMonths == null)
        .firstOrNull;
    final yearly = plans.where((p) => p.durationMonths == 12).firstOrNull;
    // 둘 다 있고 가격이 서버에서 올 때만 주기 고르기를 그린다
    final hasCycles =
        monthly?.price != null && yearly?.price != null && monthly != yearly;
    // 처음 값 = 구독 중이면 구독 주기
    final subCycle = sub?.durationMonths == 12 ? _Cycle.yearly : _Cycle.monthly;
    final cycle = !hasCycles
        ? _Cycle.monthly
        : (_picked ?? (isPro ? subCycle : _Cycle.monthly));
    final plan = cycle == _Cycle.yearly ? yearly : monthly;
    final planAmount = _amountText(l, plan?.price, plan?.durationMonths);
    final savePct = hasCycles
        ? yearlySavePct(monthly!.price!, yearly!.price!)
        : 0;
    // 할인이 없으면(≤ 0 · 월간 행 없음) 할인 표시도 없다
    final hasDiscount = hasCycles && savePct > 0;
    // "현재 플랜" 배지는 고른 주기가 지금 구독 주기와 같을 때만 — 다른 주기면 배지 없이 가격만
    final proIsCurrent = isPro && (!hasCycles || cycle == subCycle);

    final hasPeriodEnd =
        sub?.currentPeriodEnd != null && sub!.currentPeriodEnd!.length >= 10;
    // currentPeriodEnd 는 서버 UTC 시각 — 로컬로 읽어 화면 날짜 규칙(올해 "11월 11일" · 다른 해 연도 붙임)으로 쓴다. 못 읽는 값만 잘라 쓴다
    final nextBill = hasPeriodEnd
        ? (sub.periodEndLabel ?? sub.currentPeriodEnd!.substring(0, 10))
        : l.subNextBillingDate;
    // 해지한 구독의 날짜는 결제일이 아니라 이용이 끝나는 날이다
    final renews = (sub?.autoRenew ?? true) || !hasPeriodEnd;
    final subAmount = _amountText(l, sub?.price, sub?.durationMonths);

    final String currentDesc = !isPro
        ? l.subFreeLockedDesc
        : !renews
        ? (subAmount != null
              ? '${l.subProUntil(nextBill)} · $subAmount'
              : l.subProUntil(nextBill))
        : subAmount != null
        ? l.subNextBilling(nextBill, subAmount)
        : l.subNextBillingNoAmount(nextBill);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.subManageTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('subscription-body'),
              padding: const EdgeInsets.only(bottom: PSpacing.x6),
              children: [
                if (failed)
                  PResultSection(
                    key: const ValueKey('subscription-failed'),
                    kind: PResultKind.failure,
                    size: PResultSize.medium,
                    title: l.subLoadFailed,
                    description: l.subLoadFailedDesc,
                    placement: PResultPlacement.screen,
                    primaryAction: PResultAction(
                      label: l.actionRetry,
                      loading: refetching,
                      onPressed: _retry,
                    ),
                  )
                else if (loading)
                  const _SkeletonRows(
                    key: ValueKey('subscription-loading-current'),
                    count: 1,
                  )
                else ...[
                  // ── 지금 플랜 줄
                  PList(
                    children: [
                      PListItem(
                        key: const ValueKey('subscription-current'),
                        prefix: const ExcludeSemantics(
                          child: Icon(LucideIcons.sparkles),
                        ),
                        title: isPro ? l.subUsingPro : l.subUsingFree,
                        detail: currentDesc,
                      ),
                    ],
                  ),
                ],
                // ── 안내 상자 — 서버 값이 아니라 늘 보인다
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PSpacing.globalGutter,
                    PSpacing.x2,
                    PSpacing.globalGutter,
                    PSpacing.x4,
                  ),
                  child: PCallout(
                    key: const ValueKey('subscription-callout'),
                    tone: PCalloutTone.informative,
                    icon: LucideIcons.trendingUp,
                    description: l.subSpotlightDesc,
                  ),
                ),
                // 불러오는 중 — 요금 줄 둘 자리(안내 상자는 제자리에 있다)
                if (loading)
                  const _SkeletonRows(
                    key: ValueKey('subscription-loading-prices'),
                    count: 2,
                  ),
                if (!failed && !loading) ...[
                  // ── 주기 고르기 — 월간 · 연간 두 요금제가 다 있을 때만
                  if (hasCycles)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        PSpacing.globalGutter,
                        0,
                        PSpacing.globalGutter,
                        PSpacing.x4,
                      ),
                      child: PSegmentedControl<_Cycle>(
                        semanticLabel: l.subCycleLabel,
                        value: cycle,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _picked = v),
                        items: [
                          PSegmentedItem(
                            value: _Cycle.monthly,
                            label: l.subCycleMonthly,
                          ),
                          PSegmentedItem(
                            value: _Cycle.yearly,
                            label: hasDiscount
                                ? l.subCycleYearlyOff(savePct)
                                : l.subCycleYearly,
                          ),
                        ],
                      ),
                    ),
                  // ── 요금 — List 줄 둘
                  PList(
                    children: [
                      PListItem(
                        key: const ValueKey('subscription-price-free'),
                        title: 'Free',
                        titleSuffix: isPro
                            ? null
                            : [PBadge(label: l.subCurrentPlan)],
                        detail: l.subFreeCaption,
                        suffix: PListValue.amount(
                          krwSigned(0, false, unit: true),
                        ),
                      ),
                      PListItem(
                        key: const ValueKey('subscription-price-pro'),
                        title: 'Pro',
                        titleSuffix: proIsCurrent
                            ? [PBadge(label: l.subCurrentPlan)]
                            : null,
                        detail: cycle == _Cycle.yearly && hasCycles
                            ? (hasDiscount
                                  ? l.subYearlyPerMonth(
                                      krwSigned(
                                        (yearly!.price! / 12).round(),
                                        false,
                                        unit: true,
                                      ),
                                      savePct,
                                    )
                                  : null)
                            : l.subMonthlyBilling,
                        suffix: planAmount == null
                            ? null
                            : PListValue.amount(planAmount),
                      ),
                    ],
                  ),
                ],
                // ── 기능 비교 — 768 미만이라 표 대신 줄(table.md:139)
                PListHeader(
                  title: l.subFeatureCompare,
                  variant: PListHeaderVariant.boldSolid,
                  topInset: PSpacing.x6,
                ),
                PList(
                  key: const ValueKey('subscription-features'),
                  semanticLabel: l.subFeatureCompare,
                  children: [
                    for (final f in _featuresOf(l))
                      PListItem(
                        title: f.label,
                        suffix: Text(
                          f.free ? 'Free · Pro' : 'Pro',
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // ── 바닥 띠 — 불러오는 중 · 실패에는 무엇을 누를지 몰라 그리지 않는다
          if (!failed && !loading)
            PSnackbarAvoidOverlap(
              child: DecoratedBox(
                key: const ValueKey('subscription-bottom'),
                decoration: BoxDecoration(
                  color: c.bgLayerDefault,
                  border: Border(top: BorderSide(color: c.strokeNeutralSubtle)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    PSpacing.globalGutter,
                    PSpacing.x3,
                    PSpacing.globalGutter,
                    PSpacing.x4 + bottomInset,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: isPro
                        ? PButton(
                            label: l.subCancel,
                            variant: PButtonVariant.ghost,
                            ghostColor: PButtonGhostColor.critical,
                            size: PButtonSize.large,
                            onPressed: () => _cancel(nextBill),
                          )
                        : PButton(
                            label: l.subStartPro,
                            size: PButtonSize.large,
                            loading: _busy,
                            // 요금제를 못 받았으면 무엇을 구독할지 모른다
                            onPressed: plan == null || _busy
                                ? null
                                : () => _subscribe(plan.planCode),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "{가격} / 월" · "{가격} / 년"(기간 12개월). 가격이 없으면(옛 서버 응답) null.
String? _amountText(AppLocalizations l, int? price, int? months) {
  if (price == null) return null;
  final amount = krwSigned(price, false, unit: true);
  return months == 12 ? l.subPricePerYear(amount) : l.subPricePerMonth(amount);
}

/// 불러오는 중 — 줄 스켈레톤(아이콘 · 두 줄). 지금 플랜 자리 한 줄 · 요금 줄 자리 두 줄로 나눠 안내 상자가 제자리에 있다.
class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x3,
              children: [
                const PSkeleton(width: 22, height: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: PSkeleton.text(PTypography.t5),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 200,
                        child: PSkeleton.text(PTypography.t3),
                      ),
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
