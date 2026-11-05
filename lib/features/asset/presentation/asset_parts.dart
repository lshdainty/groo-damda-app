import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_krw.dart';
import 'package:groo_damda_app/features/asset/domain/asset_type_meta.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_edit_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/net_worth_chart.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

// 자산 화면의 구역 부품(I-05 55 ~ 62) — 웹 `pages/asset/ui/asset-parts.tsx` 와 같은 구조 · 같은 값이다(짝 1).
// 폰은 띠 화면이다: 구역마다 화면 폭 흰 띠, 띠 안은 구역이 제 좌우 24 를 갖고(목록 줄은 줄이 제 24), 띠 사이 8 만 틈이다(74).
// 금액은 원까지 · 가리면 "••••". 카드(띠)마다 따로 불러오고 따로 실패한다(화면 전체 게이트 없음 — 62).

/// 평가 맵 → 자산 rowId 별 라이브 평가액(보유분).
Map<int, int> liveValuationMap(Map<int, InvestmentValuation> inv) => {
  for (final e in inv.entries) e.key: e.value.value,
};

/// 연결 자산의 보유 평가를 라이브 평가액(시세×수량, 원화)으로 치환한다 — 자산 화면 · 계좌·카드 관리 · 상세가 같은 함수다.
/// 라이브 평가는 '보유분'(원화)만이라 보유 평가 자리에만 얹는다 — 통화는 바꾸지 않고, 원화 합계는
/// round(예수금 × 환율) + 라이브(`withLiveHolding`, 서버 balanceInKrw 와 같은 식, I-13). 예수금을 빼먹으면 매수 대기 자금이 목록에서 빠진다.
List<Asset> applyLiveValuation(List<Asset> assets, Map<int, int> valMap) {
  if (valMap.isEmpty) return assets;
  return [
    for (final a in assets)
      valMap.containsKey(a.rowId) ? withLiveHolding(a, valMap[a.rowId]!) : a,
  ];
}

/// 순자산 보정용 delta(라이브 − DB) — 총액 포함 자산만. balance = 예수금 + 보유라 (예수금 + 라이브 − balance) = 라이브 − 보유,
/// 둘 다 원화다(서버 순자산이 새 식 round(예수금 × 환율) + 보유라 원화끼리 차액을 더하면 맞다, I-13).
int liveValuationDelta(List<Asset> assets, Map<int, int> valMap) {
  if (valMap.isEmpty) return 0;
  return assets.fold<int>(
    0,
    (s, a) => (a.isIncludedInTotal == 'Y' && valMap.containsKey(a.rowId))
        ? s + ((a.cashBalance ?? 0) + valMap[a.rowId]! - (a.balance ?? 0))
        : s,
  );
}

/// 묶음 합계 셈(자산 화면 · 계좌·카드 관리가 같은 함수) — 총액 포함 자산만, 원화 합계(서버 balanceInKrw, I-13 길 A)를 더한다.
/// raw 로 더하면 USD 1,000 이 1,000원이 돼 서버 요약과 어긋난다(I-17 Q4).
int assetSumIncluded(List<Asset> arr) => arr
    .where((a) => a.isIncludedInTotal == 'Y')
    .fold<int>(0, (s, a) => s + assetKrw(a));

/// 원까지 금액 글 — 음수는 U+2212, 가리면 점.
String assetWon(int n, bool masked) =>
    budgetWon(n.abs(), masked, sign: n < 0 ? kMinus : '');

/// 금액 값 글 — R13(t5 · 700 · 고정폭), 쉼표 뒤에서만 줄을 바꾼다.
Widget _amount(String text, Color color, {TextAlign? align, TextStyle? base}) =>
    Text(
      keepAllAmount(text),
      semanticsLabel: text,
      textAlign: align,
      style: (base ?? PTypography.t5).copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontFeatures: tabularFigures,
      ),
    );

/// 막대 — ds ProgressBar. 이름 "{이름} {한도} 중 {사용}", 값 글은 "88%" · 넘치면 "{금액} 초과" · 목표는 "달성".
Widget _meterBar(
  BuildContext context, {
  required String label,
  required int value,
  required int max,
  required bool masked,
  PProgressMeaning meaning = PProgressMeaning.limit,
}) {
  final l = AppLocalizations.of(context);
  String fmt(int n) => assetWon(n, masked);
  final ratio = max > 0 ? value / max : (value > 0 ? 1.0 : 0.0);
  final over = meaning == PProgressMeaning.limit && value > max;
  final reached = meaning == PProgressMeaning.goal && value >= max;
  final text = over
      ? l.dsProgressOver(fmt(value - max))
      : reached
      ? l.dsProgressReached
      : '${(math.min(ratio, 1.0) * 100).round()}%';
  return PProgressBar(
    value: value.toDouble(),
    max: max.toDouble(),
    meaning: meaning,
    semanticsLabel: l.dsProgressSemantics(label, fmt(max), fmt(value)),
    semanticsValue: text,
  );
}

// ── 순자산 요약 ─────────────────────────────────────────────────

/// 순자산 요약(55) — 눈(금액 가리기 설정, 보이는 40 · 아이콘 20) · 금액 t12 · 증감 Delta · 추이 차트 · 지표 셋(한 줄에 하나).
/// 지금처럼 흰 띠 — hero 로 바꾸지 않는다(Q2 2A).
class AssetSummarySection extends StatelessWidget {
  const AssetSummarySection({
    super.key,
    required this.loading,
    required this.failed,
    required this.assetsFailed,
    required this.onRetry,
    required this.netWorth,
    required this.changeAmount,
    required this.changePercent,
    required this.hasLastMonth,
    required this.accountsTotal,
    required this.investmentsTotal,
    required this.cardsTotal,
    required this.masked,
    required this.onToggleMask,
  });

  final bool loading;
  final bool failed;

  /// 실패한 질의가 자산 목록인가(아니면 요약) — 폰은 질의 하나 = 상자 하나라 이 띠에만 상자를 둔다.
  final bool assetsFailed;
  final VoidCallback onRetry;
  final int netWorth;
  final int changeAmount;
  final double changePercent;
  final bool hasLastMonth;
  final int accountsTotal;
  final int investmentsTotal;
  final int cardsTotal;
  final bool masked;
  final VoidCallback onToggleMask;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (failed) {
      return Padding(
        padding: const EdgeInsets.all(PSpacing.x6),
        child: BudgetFailure(
          title: assetsFailed
              ? l.assetLoadFailedAssets
              : l.assetLoadFailedSummary,
          onRetry: onRetry,
        ),
      );
    }
    if (loading) return const AssetSummarySkeleton();

    final Widget delta;
    if (!hasLastMonth) {
      delta = Text(
        keepAll(l.dashNoLastMonth),
        style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
      );
    } else {
      delta = PDelta(
        direction: changeAmount == 0
            ? PDeltaDirection.flat
            : (changeAmount > 0 ? PDeltaDirection.up : PDeltaDirection.down),
        value: changeAmount == 0
            ? null
            : '${formatChangeRateAbs(changePercent)}'
                  '${masked ? '' : ' (${assetWon(changeAmount.abs(), false)})'}',
        text: l.assetVsLastMonth,
      );
    }
    final stats = [
      BudgetKv(l.assetSummaryColAccounts, assetWon(accountsTotal, masked)),
      BudgetKv(l.assetGroupInvestment, assetWon(investmentsTotal, masked)),
      BudgetKv(
        l.assetSummaryColCards,
        masked
            ? kBudgetMask
            : (cardsTotal > 0
                  ? '$kMinus${assetWon(cardsTotal, false)}'
                  : assetWon(cardsTotal, false)),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            // 위 24 + 눈 줄 24 + 4 — 눈 단추(40)는 이 줄 위아래로 8 씩 겹쳐 서고, 누르는 40 이 모두 단추다
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                PSpacing.x6 + PSpacing.x6 + PSpacing.x1,
                PSpacing.x6,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _amount(
                    assetWon(netWorth, masked),
                    c.fgNeutral,
                    base: PTypography.t12,
                  ),
                  const SizedBox(height: PSpacing.x2),
                  delta,
                  const SizedBox(height: PSpacing.x4),
                  const NetWorthChart(height: 140),
                ],
              ),
            ),
            Positioned(
              top: PSpacing.x4,
              left: PSpacing.x6,
              right: PSpacing.x6,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      keepAll(l.assetTotalNetWorth),
                      style: PTypography.t3.copyWith(
                        color: c.fgNeutralSubtle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: PSpacing.x1),
                  PButton.icon(
                    key: const ValueKey('asset-eye'),
                    icon: masked ? LucideIcons.eyeOff : LucideIcons.eye,
                    semanticLabel: l.dashHideAmountsSettings,
                    variant: PButtonVariant.ghost,
                    ghostColor: PButtonGhostColor.neutralSubtle,
                    onPressed: onToggleMask,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpacing.x3),
        budgetKvList(context, stats),
        const SizedBox(height: PSpacing.x4),
      ],
    );
  }
}

/// 요약 자리 Skeleton — 실제 줄과 같은 높이(금액 t12 · 증감 t3 · 차트 140 · 지표 38 × 3).
class AssetSummarySkeleton extends StatelessWidget {
  const AssetSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PSpacing.x6, bottom: PSpacing.x4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: 0.25,
                child: PSkeleton.text(PTypography.t3),
              ),
              const SizedBox(height: PSpacing.x2),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: PSkeleton.text(PTypography.t12),
              ),
              const SizedBox(height: PSpacing.x2),
              FractionallySizedBox(
                widthFactor: 0.33,
                child: PSkeleton.text(PTypography.t3),
              ),
              const SizedBox(height: PSpacing.x4),
              const PSkeleton(height: 140),
            ],
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x6,
              vertical: PSpacing.x2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.33,
                    child: PSkeleton.text(PTypography.t5),
                  ),
                ),
                PSkeleton.text(PTypography.t5, width: PSpacing.x10 * 2),
              ],
            ),
          ),
      ],
    ),
  );
}

// ── 자산 줄 ─────────────────────────────────────────────────────

/// 투자 보유 요약 서브라인 — "대표종목 외 N종목" / 단일 이름 / 빈 목록 문구.
String holdingsRep(AppLocalizations l, List<AssetHolding> holdings) {
  if (holdings.isEmpty) return l.assetNoHoldings;
  String nameOf(AssetHolding h) => (h.holdingName?.isNotEmpty ?? false)
      ? h.holdingName!
      : (h.tossSymbol ?? '');
  final first = nameOf(holdings.first);
  if (holdings.length == 1) return first;
  return l.assetHoldingRep(first, holdings.length - 1);
}

const _cardTypeSet = {'CREDIT_CARD', 'CHECK_CARD'};

/// 자산 줄(56) — 앞 로고 타일 40 · 제목 R6 · 설명 Tag Group(t3 · 한 줄 말줄임) · 뒤 금액 R13 + 작은 글 · 화살표 18.
/// 신용카드 한도가 있으면 줄 아래 한도 막대(ds Progress limit — 높이 8 · 채움 fg-brand · 넘치면 fg-critical + "N원 초과",
/// 70% · 90% 에서 색을 바꾸지 않는다) + 막대 아래 왼쪽 "사용 / 한도"(넘치면 오른쪽 "N원 초과").
class AssetRow extends StatelessWidget {
  const AssetRow({
    super.key,
    required this.asset,
    required this.cardMasked,
    this.valuation,
    this.manage = false,
    this.onTap,
  });

  final Asset asset;

  /// 계좌 · 카드 관리의 줄(I-17 27) — 같은 부품에서 오른쪽 화살표를 걷고(Q2 결정 B: 줄 끝은 동작 자리), 설명을 "{기관} · {종류 이름}" 으로
  /// 쓴다(메모는 상세 머리 설명에 남는다 · 투자는 "보유 {n}종목").
  final bool manage;

  /// 줄을 눌렀을 때 — 비우면 자산 상세를 연다(자산 화면).
  final VoidCallback? onTap;

  /// 이 묶음의 화면 카드가 가려졌는가 — 자산 하나의 가림과 합집합이다.
  final bool cardMasked;

  /// 투자 자산 라이브 평가(등락) — 투자 묶음에서만.
  final InvestmentValuation? valuation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final masked = cardMasked || asset.isAmountHidden == 'Y';
    // 외화는 원화 합계(서버 balanceInKrw — 라이브면 보유 자리만 바꾼 값)가 주 표기, 외화 계좌(투자 아님)는 자산 통화 잔액을 밑에 함께 보여 준다.
    final balance = assetKrw(asset);
    final isCard = _cardTypeSet.contains(asset.assetType);
    // 연결계좌형 체크카드는 결제가 계좌에서 즉시 빠져 잔액이 늘 0 이다 — 행 금액은 "이번 달 얼마 썼나"로 바꾼다.
    final checkCardMonthly =
        asset.assetType == 'CHECK_CARD' && asset.paymentAssetRowId != null
        ? (asset.monthlyUsedAmount ?? 0)
        : null;
    // 관리 줄에는 한도 막대 · "사용 / 한도" 를 그리지 않는다(고른 그림 arow 에 없음 — 상세가 보여 준다)
    final limit = !manage && asset.assetType == 'CREDIT_CARD'
        ? asset.creditLimit
        : null;
    final hasBar = limit != null && limit > 0;
    final foreign = isForeignCurrency(asset.currency);

    final tags = <PTag>[
      // 줄어드는 것은 기관 이름뿐이다 — 관리 줄은 종류 · 결제일을 줄이지 않는다(tag-group.md truncate)
      if (asset.institution != null && asset.institution!.isNotEmpty)
        PTag(asset.institution!, shrink: manage ? 1 : 2),
      if (manage) PTag(assetTypeLabelOf(l, asset), shrink: 0),
      if (manage) ...[
        if (asset.assetType == 'INVESTMENT' && asset.holdings.isNotEmpty)
          PTag(l.assetHoldingsCount(asset.holdings.length), shrink: 0),
      ] else if (asset.assetType == 'INVESTMENT' && asset.holdings.isNotEmpty)
        PTag(holdingsRep(l, asset.holdings))
      else if (!isCard && asset.memo != null && asset.memo!.isNotEmpty)
        PTag(asset.memo!),
      if (asset.assetType == 'CREDIT_CARD' && asset.paymentDay != null)
        PTag(l.assetPaymentDayInfo(asset.paymentDay!), shrink: 0),
      if (checkCardMonthly != null) PTag(l.assetCheckCardMonthLabel, shrink: 0),
    ];

    final main = checkCardMonthly != null
        ? assetWon(checkCardMonthly, masked)
        : assetWon(balance, masked);
    final small = PTypography.t3.copyWith(
      color: c.fgNeutralSubtle,
      fontWeight: FontWeight.w500,
      fontFeatures: tabularFigures,
    );
    final val = valuation;
    final change = val?.changeAmt;
    final badges = [
      if (asset.isIncludedInTotal == 'N') l.assetExcludedFromTotal,
      if (asset.isAmountHidden == 'Y') l.assetAmountHiddenBadge,
    ];
    final suffix = PListSuffix(
      children: [
        PListValue(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x0_5,
            children: [
              _amount(main, c.fgNeutral, align: TextAlign.end),
              // 외화 계좌의 자산 통화 잔액(정수 — "$100"). 투자는 줄에 두지 않는다 — 예수금만 자산 통화라 작은 글이 기관 · 종목 설명을
              // 밀어 자른다(I-13 검수, 웹과 같다). 투자 예수금 "$100 + 약 130,000원" 은 상세에서만.
              if (foreign &&
                  checkCardMonthly == null &&
                  asset.assetType != 'INVESTMENT')
                Text(
                  masked
                      ? kBudgetMask
                      : formatAssetAmount(
                          asset.cashBalance ?? asset.balance ?? 0,
                          asset.currency!,
                          Localizations.localeOf(context).toString(),
                        ),
                  textAlign: TextAlign.end,
                  style: small,
                ),
              // 투자 행 등락 — 오름 · 내림 방향 색은 Delta 가 정한다. 가려도 줄은 두고 값만 점이다(웹 `▲ •••`)
              if (val != null && change != null)
                Builder(
                  builder: (context) {
                    final base = val.value - change;
                    final pct = base == 0 ? 0.0 : change / base * 100;
                    return PDelta(
                      key: ValueKey('asset-delta-${asset.rowId}'),
                      direction: change >= 0
                          ? PDeltaDirection.up
                          : PDeltaDirection.down,
                      value: masked
                          ? '•••'
                          : '${formatChangeRateAbs(pct)} '
                                '(${change >= 0 ? '+' : kMinus}${assetWon(change.abs(), false)})',
                    );
                  },
                ),
              if (badges.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: PSpacing.x1,
                  runSpacing: PSpacing.x1,
                  children: [for (final b in badges) PBadge(label: b)],
                ),
            ],
          ),
        ),
        if (!manage)
          const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
      ],
    );

    final row = PListButtonItem(
      title: asset.assetName,
      align: tags.isNotEmpty ? PListAlign.top : PListAlign.center,
      prefix: AssetLogo(asset: asset),
      detailChild: tags.isEmpty
          ? null
          : PTagGroup(
              size: PTagGroupSize.t3,
              overflow: PTagGroupOverflow.truncate,
              items: tags,
            ),
      suffix: suffix,
      onTap: onTap ?? () => showAssetDetailDialog(context, asset),
    );
    if (!hasBar) return row;

    final used = balance.abs();
    final over = used > limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        // 줄 아래 16 에 막대(줄 안 12 + 4), 막대 아래 12
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x1,
            PSpacing.x6,
            PSpacing.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _meterBar(
                context,
                label: l.assetCardLimitName(asset.assetName),
                value: used,
                max: limit,
                masked: masked,
              ),
              const SizedBox(height: PSpacing.x2),
              BudgetBarCaption(
                left: masked
                    ? kBudgetMask
                    : '${assetWon(used, false)} / ${assetWon(limit, false)}',
                right: over
                    ? l.dsProgressOver(assetWon(used - limit, masked))
                    : '',
                rightColor: over ? c.fgCritical : null,
                rightBold: over,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 자산 줄 Skeleton — 실제 줄(두 줄 66)과 같은 높이: 앞 타일 40(모서리 12) + 제목 · 설명 + 금액.
class AssetRowsSkeleton extends StatelessWidget {
  const AssetRowsSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (var i = 0; i < rows; i++) const _SkeletonRow()],
  );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.x6,
      vertical: PSpacing.x3,
    ),
    child: Row(
      spacing: PSpacing.x3,
      children: [
        const PSkeleton(
          width: PSpacing.x10,
          height: PSpacing.x10,
          radius: PSkeletonRadius.r12,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x0_5,
            children: [
              FractionallySizedBox(
                widthFactor: 0.5,
                child: PSkeleton.text(PTypography.t5),
              ),
              FractionallySizedBox(
                widthFactor: 0.33,
                child: PSkeleton.text(PTypography.t3),
              ),
            ],
          ),
        ),
        PSkeleton.text(PTypography.t5, width: PSpacing.x10),
      ],
    ),
  );
}

// ── 구역 틀 ─────────────────────────────────────────────────────

/// 한 질의가 실패한 구역 안 — 제 좌우 24 · 아래 12.
Widget _failureBody(String title, VoidCallback onRetry) => Padding(
  padding: const EdgeInsets.fromLTRB(PSpacing.x6, 0, PSpacing.x6, PSpacing.x3),
  child: BudgetFailure(title: title, onRetry: onRetry),
);

/// 자산 묶음(56) — 머리(R4 제목 + 오른쪽 합계 R13 줄 금액) 아래 줄. 합계 색은 중립이고 빼기 부호가 말한다(D1).
class AssetGroupSection extends StatelessWidget {
  const AssetGroupSection({
    super.key,
    required this.title,
    required this.assets,
    required this.total,
    required this.masked,
    required this.loading,
    this.negativeTotal = false,
    this.valuations = const {},
  });

  final String title;
  final List<Asset> assets;
  final int total;
  final bool masked;
  final bool loading;
  final bool negativeTotal;
  final Map<int, InvestmentValuation> valuations;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final totalText = masked
        ? kBudgetMask
        : (negativeTotal && total != 0
              ? '$kMinus${assetWon(total, false)}'
              : assetWon(total, false));
    return BudgetListSection(
      header: BudgetHead(
        title: title,
        trailing: loading
            ? null
            : _amount(totalText, c.fgNeutral, align: TextAlign.end),
      ),
      children: [
        if (loading)
          const AssetRowsSkeleton()
        else if (assets.isEmpty)
          BudgetEmptyLine(l.assetGroupEmpty)
        else
          PList(
            semanticLabel: title,
            children: [
              for (final a in assets)
                AssetRow(
                  key: ValueKey('asset-row-${a.rowId}'),
                  asset: a,
                  cardMasked: masked,
                  valuation: valuations[a.rowId],
                ),
            ],
          ),
      ],
    );
  }
}

// ── 저축 목표 ───────────────────────────────────────────────────

/// 저축 목표 줄(60) — 앞 타일 40(모서리 12 · 옅은 색 바탕 · 아이콘 20) · 제목(+ 달성 배지) · 설명 "{기한} · {현재 원} / {목표 원}"
/// (원까지, 줄임 없음) · 뒤 % · 줄 아래 Progress goal 막대. 조회 전용 — 추가 · 수정 · 삭제는 설정 > 저축 목표.
class AssetSavingGoalRow extends StatelessWidget {
  const AssetSavingGoalRow({
    super.key,
    required this.goal,
    required this.masked,
  });

  final SavingGoal goal;
  final bool masked;

  String? _deadline() {
    final raw = goal.deadlineDate;
    if (raw == null || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw);
    return d == null ? null : yearMonth(d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final color = resolveChartColor(context, goal.color, fallback: c.fgBrand);
    final pct = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount * 100).round()
        : 0;
    final amounts =
        '${assetWon(goal.currentAmount, masked)} / ${assetWon(goal.targetAmount, masked)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListItem(
          title: goal.title,
          align: PListAlign.top,
          titleSuffix: goal.achieved
              ? [PBadge(label: l.savingGoalAchieved, tone: PBadgeTone.positive)]
              : null,
          detail: '${_deadline() ?? l.savingGoalNoDeadline} · $amounts',
          prefix: PListTile(
            background: softBg(context, color),
            color: color,
            child: Icon(
              lucideByName(goal.icon, fallback: LucideIcons.piggyBank),
            ),
          ),
          suffix: Text(
            '$pct%',
            style: PTypography.t5.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: tabularFigures,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x1,
            PSpacing.x6,
            PSpacing.x3,
          ),
          child: _meterBar(
            context,
            label: goal.title,
            value: goal.currentAmount,
            max: math.max(goal.targetAmount, 0),
            masked: masked,
            meaning: PProgressMeaning.goal,
          ),
        ),
      ],
    );
  }
}

/// 저축 목표 구역 — 머리 오른쪽 "전체 보기"(저축 목표 화면으로).
class AssetSavingGoalsSection extends StatelessWidget {
  const AssetSavingGoalsSection({
    super.key,
    required this.goals,
    required this.masked,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });

  final List<SavingGoal> goals;
  final bool masked;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BudgetListSection(
      header: BudgetHead(
        title: l.navSavingGoals,
        actionLabel: l.dashViewAll,
        onAction: () => context.push('/saving-goals'),
      ),
      children: [
        if (failed)
          _failureBody(l.assetLoadFailedGoals, onRetry)
        else if (loading)
          const _GoalRowsSkeleton()
        else if (goals.isEmpty)
          BudgetEmptyLine(l.savingGoalManagePrompt)
        else
          PList(
            semanticLabel: l.navSavingGoals,
            children: [
              for (final g in goals)
                AssetSavingGoalRow(
                  key: ValueKey('asset-goal-${g.rowId}'),
                  goal: g,
                  masked: masked,
                ),
            ],
          ),
      ],
    );
  }
}

class _GoalRowsSkeleton extends StatelessWidget {
  const _GoalRowsSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < 2; i++) ...[
        const _SkeletonRow(),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x1,
            PSpacing.x6,
            PSpacing.x3,
          ),
          child: PSkeleton(
            height: PProgressBar.height,
            radius: PSkeletonRadius.full,
          ),
        ),
      ],
    ],
  );
}

// ── 빈 화면 ─────────────────────────────────────────────────────

/// 빈 화면(61) — Result Section empty "처음" 갈래, 폰은 띠 안 large. 첫 버튼은 계좌 추가(계좌 · 카드 관리로).
class AssetEmpty extends StatelessWidget {
  const AssetEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(PSpacing.x6),
      child: PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.large,
        icon: LucideIcons.landmark,
        title: l.assetEmptyState,
        description: l.assetEmptyHint,
        placement: PResultPlacement.card,
        primaryAction: PResultAction(
          label: l.assetEmptyCta,
          onPressed: () => context.push('/account-card-manage'),
        ),
      ),
    );
  }
}
