import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_krw.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_parts.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';

const _accountTypes = {'BANK_ACCOUNT', 'SAVINGS', 'CASH'};
const _cardTypes = {'CREDIT_CARD', 'CHECK_CARD'};
const _investmentTypes = {'INVESTMENT'};
const _loanTypes = {'LOAN'};

/// 이 화면이 셸에서 차지하는 라우트 — "지금 내가 앞인가" 를 이 값으로 판정한다.
const assetRoute = '/assets';

class AssetScreen extends ConsumerStatefulWidget {
  const AssetScreen({super.key});

  @override
  ConsumerState<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends ConsumerState<AssetScreen> {
  Timer? _valuationTimer;
  // 한 번이라도 돌린 적이 있는가 — 첫 시작과 **재시작**을 가른다.
  bool _startedOnce = false;

  @override
  void initState() {
    super.initState();
    // 연동 평가액 라이브 갱신 — 시세(현재가)를 10초마다 다시 받는다(웹과 같은 주기).
    // **시세 조회까지 민다**(refreshLiveValuation) — 평가 맵만 밀면 받아 둔 시세로 다시
    // 계산할 뿐이라, 2026-08-25 부터 한 달 넘게 앱을 켤 때 시세에 멈춰 있었다.
    // 게이트 OFF(비프로/미연결)·연결 자산 없음이면 빈 맵이라 NOP.
    //
    // **보고 있을 때만 돈다.** 이 화면은 탭 셸(IndexedStack)에 상주해 다른 탭으로
    // 가도 dispose 되지 않는다 — dispose 의 cancel 만 믿으면 타이머는 앱을 끌 때까지
    // 돌고, 아무도 안 보는 시세를 10초마다 받아 배터리·데이터를 쓴다.
    // 그래서 라우트와 포그라운드를 각각 듣고 그때마다 다시 판정한다.
    ref.listenManual(activeShellRouteProvider, (_, _) => _syncValuationTimer());
    ref.listenManual(appForegroundProvider, (_, _) => _syncValuationTimer());
    // 첫 판정은 microtask 로 미룬다 — initState 안에서는 provider 를 읽지도 비우지도
    // 못한다(빌드 중이다). 셸이 첫 라우트를 적는 것도 같은 이유로 microtask 라,
    // 먼저 예약된 그쪽이 먼저 돌아 여기서는 이미 어느 화면이 앞인지 알고 있다.
    Future.microtask(_syncValuationTimer);
  }

  /// 보이면 돌리고, 안 보이면 멈춘다 — 라우트·포그라운드 어느 쪽이 바뀌어도 여기로 모인다.
  void _syncValuationTimer() {
    if (!mounted) return;
    if (!isScreenVisible(ref, assetRoute)) {
      _valuationTimer?.cancel();
      _valuationTimer = null;
      return;
    }
    // 이미 돌고 있으면 그대로 둔다. 부르는 자리가 둘이라 그냥 만들면 타이머가 겹쳐
    // 같은 조회가 배로 나간다(멈추는 쪽은 한 번뿐이라 겹친 하나는 영영 안 꺼진다).
    if (_valuationTimer != null) return;
    // **재시작**이면 돌아온 직후 한 번은 바로 받는다 — 안 그러면 10초 동안 떠나기 전
    // 시세를 본다. 진입·복귀 무효화(core/sync/keep_alive_refresh.dart)는 이 조회를
    // 일부러 안 태운다(시세는 60초 신선도 규칙에 안 맞는다) — 여기서 안 밀면 아무도 안 민다.
    // 첫 시작은 밀지 않는다: 화면이 build 에서 막 읽어 조회가 이미 나간 참이라,
    // 여기서 또 비우면 자산 탭에 들어올 때마다 같은 조회가 두 번 나간다.
    if (_startedOnce) refreshLiveValuation(ref.invalidate);
    _startedOnce = true;
    _valuationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) refreshLiveValuation(ref.invalidate);
    });
  }

  @override
  void dispose() {
    _valuationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final assetsAsync = ref.watch(assetsProvider);
    final summaryAsync = ref.watch(
      assetSummaryProvider((year: null, month: null)),
    );
    final goalsAsync = ref.watch(savingGoalListProvider);
    // 투자 자산 라이브 평가(평가액·등락) 맵 — holdings/레거시 연동 공용. 게이트 OFF·미평가 시 빈 맵.
    // `asData` 가 아니라 `value` 다 — 10초마다 다시 받는 동안 상태가 로딩으로 바뀌는데,
    // asData 는 그때 비어서 평가액이 서버 잔액으로 깜빡였다가 돌아온다. value 는 앞 값을 든다.
    final invMap =
        ref.watch(investmentValuationMapProvider).value ??
        const <int, InvestmentValuation>{};
    final valMap = liveValuationMap(invMap);

    // 카드(띠)마다 따로 불러오고 따로 실패한다(I-05 62) — 화면 전체를 한 번에 스켈레톤 ↔ 실패로 돌리지 않는다.
    // 값이 아직 없을 때만 "처음 불러오는 중" 이다(다시 받는 동안은 앞 값을 그대로 둔다).
    final assetsLoading = assetsAsync.isLoading && !assetsAsync.hasValue;
    final assetsFailed = assetsAsync.hasError && !assetsAsync.hasValue;
    final summaryLoading = summaryAsync.isLoading && !summaryAsync.hasValue;
    final summaryFailed = summaryAsync.hasError && !summaryAsync.hasValue;

    // 연결 자산 balance 를 라이브 평가액(시세×수량)으로 치환(관리 화면과 같은 함수) + 순자산 보정용 delta(라이브−DB).
    final assets = assetsAsync.value ?? const <Asset>[];
    final liveAssets = applyLiveValuation(assets, valMap);
    final summaryDelta = liveValuationDelta(assets, valMap);

    List<Asset> of(Set<String> types) =>
        liveAssets.where((a) => types.contains(a.assetType)).toList();
    final accounts = of(_accountTypes);
    final cards = of(_cardTypes);
    final investments = of(_investmentTypes);
    final loans = of(_loanTypes);

    // 외화는 환산해서 더한다 — 셈은 관리 화면과 같은 함수다.
    final sumIncluded = assetSumIncluded;
    final accountsTotal = sumIncluded(accounts);
    final cardsTotal = sumIncluded(cards).abs();
    final investmentsTotal = sumIncluded(investments);
    final loansTotal = sumIncluded(loans).abs();

    // summary(DB 기준)에 라이브 평가액 보정.
    final summary = summaryAsync.value;
    final netWorth = (summary?.netWorth ?? 0) + summaryDelta;
    final changeAmount = (summary?.changeAmount ?? 0) + summaryDelta;
    final lastMonth = summary?.lastMonthNetWorth ?? 0;
    final changePercent = netWorthChangePercent(
      changeAmount,
      lastMonth,
      fallback: summary?.changePercent ?? 0.0,
    );

    final masks = (
      netWorth: ref.watch(hideCardProvider('asset.netWorth')),
      accounts: ref.watch(hideCardProvider('asset.accounts')),
      investments: ref.watch(hideCardProvider('asset.investments')),
      cards: ref.watch(hideCardProvider('asset.cards')),
      loans: ref.watch(hideCardProvider('asset.loans')),
      savingGoals: ref.watch(hideCardProvider('asset.savingGoals')),
    );

    void retrySummary() {
      if (assetsFailed) ref.invalidate(assetsProvider);
      if (summaryFailed) ref.invalidate(assetSummaryProvider);
    }

    final empty =
        !assetsLoading &&
        !summaryLoading &&
        !assetsFailed &&
        accounts.isEmpty &&
        cards.isEmpty &&
        investments.isEmpty &&
        loans.isEmpty;

    // 폰 구역 화면 — 순자산 요약 · 자산 묶음마다 화면 폭 흰 띠, 사이 8 은 회색 바닥(I-01 결정 3).
    // 첫 띠 위 · 마지막 띠 아래 틈은 없다(74) — 띠 사이에만 [PScreenBands.children] 이 8 을 낀다.
    final bands = <Widget>[
      if (empty)
        budgetBand([const AssetEmpty()])
      else ...[
        budgetBand([
          AssetSummarySection(
            loading: assetsLoading || summaryLoading,
            failed: assetsFailed || summaryFailed,
            assetsFailed: assetsFailed,
            onRetry: retrySummary,
            netWorth: netWorth,
            changeAmount: changeAmount,
            changePercent: changePercent,
            hasLastMonth: lastMonth != 0,
            accountsTotal: accountsTotal,
            investmentsTotal: investmentsTotal,
            cardsTotal: cardsTotal,
            masked: masks.netWorth,
            onToggleMask: () => context.push('/settings/hide-amounts'),
          ),
        ]),
        // 자산 목록 질의가 실패하면 실패 상자는 요약 띠 하나다 — 같은 질의를 여러 상자로 반복하지 않는다(폰)
        if (!assetsFailed)
          budgetBand([
            AssetGroupSection(
              title: AppLocalizations.of(context).assetGroupAccount,
              assets: accounts,
              total: accountsTotal,
              masked: masks.accounts,
              loading: assetsLoading,
            ),
          ]),
        if (investments.isNotEmpty)
          budgetBand([
            AssetGroupSection(
              title: AppLocalizations.of(context).assetGroupInvestment,
              assets: investments,
              total: investmentsTotal,
              masked: masks.investments,
              loading: false,
              valuations: invMap,
              // 시세를 못 받는 동안 평가액은 서버 잔액 · 직전 시세다 — 숫자는 두고 "지금 시세가 아니다" 를 띠로(I-wrap-b2b 4)
              notice: ref.watch(valuationPriceFailedProvider)
                  ? AssetPriceFailure(
                      onRetry: () => refreshLiveValuation(ref.invalidate),
                    )
                  : null,
            ),
          ]),
        if (!assetsFailed)
          budgetBand([
            AssetGroupSection(
              title: AppLocalizations.of(context).assetGroupCard,
              assets: cards,
              total: cardsTotal,
              negativeTotal: true,
              masked: masks.cards,
              loading: assetsLoading,
            ),
          ]),
        if (loans.isNotEmpty)
          budgetBand([
            AssetGroupSection(
              title: AppLocalizations.of(context).assetGroupDebt,
              assets: loans,
              total: loansTotal,
              negativeTotal: true,
              masked: masks.loans,
              loading: false,
            ),
          ]),
        budgetBand([
          AssetSavingGoalsSection(
            goals: goalsAsync.value ?? const [],
            masked: masks.savingGoals,
            loading: goalsAsync.isLoading && !goalsAsync.hasValue,
            failed: goalsAsync.hasError && !goalsAsync.hasValue,
            onRetry: () => ref.invalidate(savingGoalListProvider),
          ),
        ]),
      ],
    ];

    return Scaffold(
      // 카드 화면 — 회색 바닥(basement) 위 흰 띠(02-005 / Q-019-3)
      backgroundColor: c.bgLayerBasement,
      // appBar 제거 — shell MobileScaffold 의 MobileHeader 가 title='자산' +
      // actions(theme/eye/bell/search) 일관 표시.
      // bottomNavigationBar 는 shell MobileScaffold 가 path-aware MoneyTabBar 표시.
      // FAB 미사용 — 계좌·카드 추가는 관리 화면(설정 > 계좌·카드 관리)에서.
      body: PPullToRefresh(
        onRefresh: () async {
          ref.invalidate(assetsProvider);
          ref.invalidate(assetSummaryProvider);
          ref.invalidate(netWorthTrendProvider);
          refreshLiveValuation(ref.invalidate); // 당겨서 새로고침도 시세까지 다시 받는다
          ref.invalidate(savingGoalListProvider);
          // 비운 것을 모두 기다린다 — 하나만 기다리면 늦게 실패한 것이 당겨서 새로 고침이 끝난 뒤 와서 같은 글이 한 번 더
          // 뜬다(검수 L2). 하나라도 실패하면 던져 그 자리가 한 번 알린다
          await Future.wait<Object?>([
            ref.read(assetsProvider.future),
            ref.read(assetSummaryProvider((year: null, month: null)).future),
            ref.read(savingGoalListProvider.future),
          ]);
        },
        child: ListView(
          padding: EdgeInsets.only(
            // 떠 있는 하단 바 보상
            bottom: bottomNavigationInset(context),
          ),
          children: PScreenBands.children(bands),
        ),
      ),
    );
  }
}
