import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/p_help_bubble.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 금액 가리기 화면 — 계정 > 보안 > 금액 가리기(I-14 5-B · 14-3). 흰 화면 하나, 스크롤 하나.
///
/// 위에서 아래로 — 소개 → "거래 종류" ⓘ + 체크 줄 셋 → 탭 줄(1차 Line · Hug) → "가릴 화면 · n / m" + 모두 선택 · 해제 →
/// (전체) 화면 이름마다 묶음 + 체크 줄 / (화면 탭) 그 화면의 체크 줄 → 바닥 띠 [저장]. 탭은 거르기이고 좌우로 밀어 옮기지
/// 않는다.
///
/// 카드를 하나 만질 때마다 저장·인증하지 않는다. 화면에서 고르는 동안에는 아무 일도 일어나지 않고, [저장] 을 눌러야 한 번에
/// 반영된다. 인증은 **푸는 카드가 하나라도 있을 때만** 받는다. 가리기만 늘리는 저장은 그대로 통과.
class HideAmountsScreen extends ConsumerStatefulWidget {
  const HideAmountsScreen({super.key});

  @override
  ConsumerState<HideAmountsScreen> createState() => _HideAmountsScreenState();
}

/// 탭 값 — `null` 은 '전체'(모든 카드를 화면 이름으로 묶어서).
typedef _Tab = HidePage?;

class _HideAmountsScreenState extends ConsumerState<HideAmountsScreen> {
  /// 화면에서 고르는 중인 선택 — 저장 전까지 설정에 반영되지 않는다. 설정을 읽은 뒤에야 잡는다(읽기 전에 빈 고름으로 굳지
  /// 않게).
  Set<String>? _draft;
  _Tab _tab;
  bool _saving = false;

  _HideAmountsScreenState() : _tab = null;

  /// 탭 순서 — 0 은 '전체', 그 뒤로 화면별.
  /// 거래 종류(HidePage.kind)는 화면이 아니라 축이 달라 탭에 넣지 않는다 — 맨 위 별도 영역이다.
  static final _tabs = <_Tab>[
    null,
    ...HidePage.values.where((p) => p != HidePage.kind),
  ];

  bool _dirty(Set<String> saved) {
    final d = _draft;
    return d != null && !_setEquals(d, saved);
  }

  static bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  /// 화면 탭이 다루는 카드 — 종류 3장은 위 별도 영역이 맡는다.
  List<String> _cardsOf(_Tab tab) =>
      tab == null ? kScreenHideCards : cardsOfPage(tab);

  void _toggle(Set<String> draft, String card) => setState(() {
    if (!draft.remove(card)) draft.add(card);
  });

  Future<void> _save(Set<String> saved) async {
    final draft = _draft;
    if (draft == null || _saving) return;
    // 푸는 게 하나라도 있으면 본인 확인 — 가리기만 늘리는 저장은 그냥 통과한다.
    final revealing = saved.difference(draft).isNotEmpty;
    setState(() => _saving = true);
    try {
      if (revealing) {
        final ok = await confirmHideAmountsUnlock(context, ref);
        if (!ok) return;
      }
      await ref.read(settingsProvider.notifier).setHideCards(draft);
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 저장하지 않고 나가려 할 때 — 고른 내용이 날아가는 걸 알리고, 확인하면 화면을 닫는다.
  Future<void> _confirmDiscardAndPop() async {
    final l = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.hideAmountsDiscardTitle,
      description: l.hideAmountsDiscardBody,
      actionLabel: l.hideAmountsDiscardConfirm,
      destructive: true,
      cancelLabel: l.actionCancel,
    );
    if (ok && mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final loaded = settings.hasValue;
    final saved = settings.value?.hideCards ?? const <String>{};
    final draft = loaded ? (_draft ??= {...saved}) : <String>{};
    final tabCards = _cardsOf(_tab);
    final allOnThisTab = tabCards.every(draft.contains);
    final onThisTab = tabCards.where(draft.contains).length;
    final dirty = loaded && _dirty(saved);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !mounted) return;
        _confirmDiscardAndPop();
      },
      child: Scaffold(
        backgroundColor: c.bgLayerDefault,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
          child: PTopNavigation(
            title: l.hideAmountsTitle,
            leading: PTopNavigationIconButton.back(
              label: l.actionBack,
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                key: const ValueKey('hide-amounts-body'),
                padding: const EdgeInsets.only(bottom: PSpacing.x6),
                children: [
                  // 소개 — 이 화면 전체의 설명(위 16 · 아래 8)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PSpacing.globalGutter,
                      PSpacing.x4,
                      PSpacing.globalGutter,
                      PSpacing.x2,
                    ),
                    child: Text(
                      keepAll(l.hideAmountsSectionDesc),
                      style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                    ),
                  ),
                  // 거래 종류 — 화면 축과 다르므로 탭 줄에 끼우지 않고 맨 위 별도 영역에 둔다
                  PListHeader(
                    title: l.hideAmountsKindLabel,
                    variant: PListHeaderVariant.boldSolid,
                    topInset: PSpacing.x2,
                    // 아이콘 동작 — 아이콘 끝이 체크 끝선에 서도록 번짐은 아이콘 안쪽 여백만큼
                    actionBleed: kListHeaderIconActionBleed,
                    action: PHelpBubble(
                      title: l.hideAmountsKindLabel,
                      description: l.hideAmountsKindNote,
                      triggerBuilder: (context, toggle, open) => PButton.icon(
                        icon: LucideIcons.info,
                        semanticLabel: l.hideAmountsKindHelp,
                        variant: PButtonVariant.ghost,
                        ghostColor: PButtonGhostColor.neutralSubtle,
                        size: PButtonSize.small,
                        onPressed: toggle,
                      ),
                    ),
                  ),
                  if (!loaded)
                    const _CheckSkeleton(count: 3)
                  else
                    _CheckGroup(
                      label: l.hideAmountsKindLabel,
                      cards: cardsOfPage(HidePage.kind),
                      draft: draft,
                      onToggle: (card) => _toggle(draft, card),
                    ),
                  // 탭 — 아래 목록(화면 카드)을 거르는 줄이라 그 목록과 한 덩어리(위 8)
                  const SizedBox(height: PSpacing.x2),
                  PTabs<_Tab>(
                    key: const ValueKey('hide-amounts-tabs'),
                    value: _tab,
                    layout: PTabsLayout.hug,
                    size: PTabsSize.small,
                    semanticLabel: l.hideAmountsTabsLabel,
                    items: [
                      for (final tab in _tabs)
                        PTab<_Tab>(
                          value: tab,
                          label: tab == null
                              ? l.hideAmountsTabAll
                              : _pageLabel(l, tab),
                        ),
                    ],
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  PListHeader(
                    // 읽기 전에는 수를 모른다 — 0 이라 말하지 않고 자리만(스켈레톤)
                    title: loaded
                        ? l.hideAmountsScreensCount(onThisTab, tabCards.length)
                        : l.hideAmountsScreensTitle,
                    titleSuffix: loaded
                        ? null
                        : SizedBox(
                            width: 40,
                            child: PSkeleton.text(PTypography.t4),
                          ),
                    tabularFigures: true,
                    topInset: PSpacing.x4,
                    // 읽기 전에도 자리는 같다(머리 높이가 뛰지 않게) — 누르지는 못한다
                    action: PTextButton(
                      label: allOnThisTab
                          ? l.hideAmountsClearAll
                          : l.hideAmountsSelectAll,
                      onPressed: loaded
                          ? () => setState(() {
                              if (allOnThisTab) {
                                draft.removeAll(tabCards);
                              } else {
                                draft.addAll(tabCards);
                              }
                            })
                          : null,
                    ),
                  ),
                  if (!loaded)
                    const _CheckSkeleton(count: 6)
                  else if (_tab == null)
                    // 전체 — 화면 이름마다 목록 제목 + 그 화면의 체크 줄(첫 묶음 위 4 · 다음 묶음 위 12)
                    for (final (i, page) in _tabs.skip(1).indexed) ...[
                      PListHeader(
                        title: _pageLabel(l, page!),
                        variant: PListHeaderVariant.boldSolid,
                        // 화면 묶음은 "가릴 화면" 아래 단계 — 머리말 3
                        headingLevel: 3,
                        topInset: i == 0 ? PSpacing.x1 : PSpacing.x3,
                      ),
                      _CheckGroup(
                        label: _pageLabel(l, page),
                        cards: cardsOfPage(page),
                        draft: draft,
                        onToggle: (card) => _toggle(draft, card),
                      ),
                    ]
                  else
                    // 화면 탭 — 그 화면의 체크 줄만(화면 이름 제목은 탭 이름과 같은 말이라 두지 않는다)
                    _CheckGroup(
                      label: _pageLabel(l, _tab!),
                      cards: tabCards,
                      draft: draft,
                      onToggle: (card) => _toggle(draft, card),
                    ),
                ],
              ),
            ),
            // 저장 — 화면 아래 고정, 위에 끝까지 닿는 선. 고르는 동안에는 아무것도 반영되지 않으므로 여기까지 와야 끝난다.
            DecoratedBox(
              key: const ValueKey('hide-amounts-bottom'),
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
                  child: PButton(
                    label: l.actionSave,
                    size: PButtonSize.large,
                    loading: _saving,
                    onPressed: dirty && !_saving ? () => _save(saved) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 체크 줄 묶음 — 카드 하나 = 줄 하나(이름 + 오른쪽 체크). 줄 전체가 체크를 바꾼다 · 줄 사이 선 없음.
class _CheckGroup extends StatelessWidget {
  const _CheckGroup({
    required this.label,
    required this.cards,
    required this.draft,
    required this.onToggle,
  });

  final String label;
  final List<String> cards;
  final Set<String> draft;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PListCheckGroup(
      semanticLabel: label,
      children: [
        for (final card in cards)
          PListCheckItem(
            key: ValueKey('hide-card-$card'),
            title: _cardLabel(l, card),
            checked: draft.contains(card),
            markPosition: PListMarkPosition.suffix,
            onChanged: (_) => onToggle(card),
          ),
      ],
    );
  }
}

/// 설정을 읽기 전 자리 — 체크 줄 모양의 스켈레톤(이 기기 값이라 오래 걸리지 않는다).
class _CheckSkeleton extends StatelessWidget {
  const _CheckSkeleton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('hide-amounts-skeleton'),
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x3,
            ),
            child: Row(
              children: [
                SizedBox(width: 120, child: PSkeleton.text(PTypography.t5)),
                const Spacer(),
                const PSkeleton(width: 24, height: 24),
              ],
            ),
          ),
      ],
    );
  }
}

String _pageLabel(AppLocalizations l, HidePage page) => switch (page) {
  HidePage.kind => l.hideAmountsKindLabel,
  HidePage.home => l.hideAmountsPageHome,
  HidePage.asset => l.hideAmountsPageAsset,
  HidePage.ledger => l.hideAmountsPageLedger,
  HidePage.stats => l.hideAmountsPageStats,
  HidePage.budget => l.hideAmountsPageBudget,
  HidePage.stocks => l.hideAmountsPageStocks,
  HidePage.dutchpay => l.hideAmountsPageDutchpay,
  HidePage.etc => l.hideAmountsPageEtc,
};

String _cardLabel(AppLocalizations l, String card) => switch (card) {
  'kind.expense' => l.hideCardKindExpense,
  'kind.income' => l.hideCardKindIncome,
  'kind.transfer' => l.hideCardKindTransfer,
  'home.netWorth' => l.hideCardHomeNetWorth,
  'home.monthExpense' => l.hideCardHomeMonthExpense,
  'home.categoryDonut' => l.hideCardHomeCategoryDonut,
  'home.budget' => l.hideCardHomeBudget,
  'home.todaySpend' => l.hideCardHomeTodaySpend,
  'home.upcoming' => l.hideCardHomeUpcoming,
  'asset.netWorth' => l.hideCardAssetNetWorth,
  'asset.composition' => l.hideCardAssetComposition,
  'asset.accounts' => l.hideCardAssetAccounts,
  'asset.investments' => l.hideCardAssetInvestments,
  'asset.cards' => l.hideCardAssetCards,
  'asset.loans' => l.hideCardAssetLoans,
  'asset.savingGoals' => l.hideCardAssetSavingGoals,
  'asset.upcoming' => l.hideCardAssetUpcoming,
  'asset.detail' => l.hideCardAssetDetail,
  'asset.manage' => l.hideCardAssetManage,
  'ledger.monthSummary' => l.hideCardLedgerMonthSummary,
  'ledger.calendar' => l.hideCardLedgerCalendar,
  'ledger.txList' => l.hideCardLedgerTxList,
  'ledger.txDetail' => l.hideCardLedgerTxDetail,
  'stats.category' => l.hideCardStatsCategory,
  'stats.trend' => l.hideCardStatsTrend,
  'stats.compare' => l.hideCardStatsCompare,
  'stats.fixed' => l.hideCardStatsFixed,
  'budget.header' => l.hideCardBudgetHeader,
  'budget.pace' => l.hideCardBudgetPace,
  'budget.status' => l.hideCardBudgetStatus,
  'budget.categories' => l.hideCardBudgetCategories,
  'budget.compliance' => l.hideCardBudgetCompliance,
  'budget.manage' => l.hideCardBudgetManage,
  'stocks.summary' => l.hideCardStocksSummary,
  'stocks.holdings' => l.hideCardStocksHoldings,
  'stocks.detail' => l.hideCardStocksDetail,
  'dutchpay.summary' => l.hideCardDutchpaySummary,
  'dutchpay.sessions' => l.hideCardDutchpaySessions,
  'etc.search' => l.hideCardEtcSearch,
  'etc.recurring' => l.hideCardEtcRecurring,
  'etc.preset' => l.hideCardEtcPreset,
  _ => card,
};
