import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
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
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

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
    ref.invalidate(myFeaturesProvider);
  }

  void _refresh() {
    ref.invalidate(myFeaturesProvider);
    ref.invalidate(mySubscriptionProvider);
  }

  Future<void> _subscribe(String planCode) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await repo.subscribe(planCode, silent: true);
      _refresh();
      if (mounted) {
        showPSnackBar(context, l.subStarted, severity: PSnackSeverity.success);
      }
    } catch (_) {
      // 서버 글을 내지 않는다 — 정한 글 하나
      if (mounted) {
        showPSnackBar(context, l.subFailed, severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(String nextBill) async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    Future<void> request() async {
      final repo = await container.read(subscriptionRepositoryProvider.future);
      await repo.cancelSubscription(silent: true);
    }

    void refresh() {
      container.invalidate(myFeaturesProvider);
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
      onRetried: refresh,
    );
    if (!ok) return;
    refresh();
    if (mounted) {
      showPSnackBar(context, l.subCanceled, severity: PSnackSeverity.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final subAsync = ref.watch(mySubscriptionProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final featuresAsync = ref.watch(myFeaturesProvider);

    // 실패는 이전 값이 남아 있어도 실패다 — 옛 값 위에 말없이 얹지 않는다
    final failed = subAsync.hasError || plansAsync.hasError;
    final loading =
        !failed &&
        ((subAsync.isLoading && !subAsync.hasValue) ||
            (plansAsync.isLoading && !plansAsync.hasValue) ||
            (featuresAsync.isLoading && !featuresAsync.hasValue));

    final sub = subAsync.asData?.value;
    final plans = plansAsync.asData?.value ?? const <SubscriptionPlanInfo>[];
    final isPro = sub?.isActive ?? false;

    // 월간(1) · 연간(12). 기간을 안 주는 옛 서버의 단일 플랜은 월간으로 본다
    final monthly = plans
        .where((p) => p.durationMonths == 1 || p.durationMonths == null)
        .firstOrNull;
    final yearly = plans.where((p) => p.durationMonths == 12).firstOrNull;
    // 둘 다 있고 가격이 서버에서 올 때만 주기 고르기를 그린다
    final hasCycles =
        monthly?.price != null && yearly?.price != null && monthly != yearly;
    final cycle = !hasCycles
        ? _Cycle.monthly
        : (_picked ??
              (isPro && sub?.durationMonths == 12
                  ? _Cycle.yearly
                  : _Cycle.monthly));
    final plan = cycle == _Cycle.yearly ? yearly : monthly;
    final planAmount = _amountText(l, plan?.price, plan?.durationMonths);
    final savePct = hasCycles
        ? yearlySavePct(monthly!.price!, yearly!.price!)
        : 0;

    final hasPeriodEnd =
        sub?.currentPeriodEnd != null && sub!.currentPeriodEnd!.length >= 10;
    // currentPeriodEnd 는 서버 UTC 시각 — 자르면 KST 밤 결제분의 갱신일이 하루 앞으로 보인다. 못 읽는 값만 잘라 쓴다
    final nextBill = hasPeriodEnd
        ? (localDateKey(sub.currentPeriodEnd) ??
              sub.currentPeriodEnd!.substring(0, 10))
        : l.subNextBillingDate;
    // 해지한 구독의 날짜는 결제일이 아니라 이용이 끝나는 날이다
    final renews = (sub?.autoRenew ?? true) || !hasPeriodEnd;
    final subAmount = _amountText(l, sub?.price, sub?.durationMonths);

    final String currentDesc = !isPro
        ? l.subFreeLockedDesc
        : !renews
        ? l.subProUntil(nextBill)
        : subAmount != null
        ? l.subNextBilling(nextBill, krwSigned(sub!.price!, false, unit: true))
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
                      onPressed: _retry,
                    ),
                  )
                else if (loading)
                  const _LoadingRows()
                else ...[
                  // ── 지금 플랜 줄
                  PList(
                    semanticLabel: l.subManageTitle,
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
                    title: l.subSpotlightTitle,
                    description: l.subSpotlightDesc,
                  ),
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
                        semanticLabel: l.subManageTitle,
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
                            label: l.subCycleYearlyOff(savePct),
                          ),
                        ],
                      ),
                    ),
                  // ── 요금 — List 줄 둘
                  PList(
                    semanticLabel: l.subManageTitle,
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
                        titleSuffix: isPro
                            ? [PBadge(label: l.subCurrentPlan)]
                            : null,
                        detail: cycle == _Cycle.yearly && hasCycles
                            ? l.subYearlyPerMonth(
                                krwSigned(
                                  (yearly!.price! / 12).round(),
                                  false,
                                  unit: true,
                                ),
                                savePct,
                              )
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
            DecoratedBox(
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

/// 불러오는 중 — 지금 플랜 줄 · 요금 줄 둘 자리에 줄 스켈레톤(아이콘 · 두 줄). 주기 고르기 · 바닥 버튼은 그리지 않는다.
class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('subscription-loading'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: Row(
              spacing: PSpacing.x3,
              children: [
                const PSkeleton(width: 22, height: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x1,
                    children: [
                      SizedBox(
                        width: 120,
                        child: PSkeleton.text(PTypography.t5),
                      ),
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
