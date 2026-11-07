/// 증권 화면이 함께 쓰는 조각 — 토스 · 나무가 같은 줄 · 실패 한 벌 · 찾는 칸을 쓴다(I-13 13-3).
/// toss_stocks_view.dart 에서 옮겼다(내용 불변, 이름만 공개).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/stale_value_callout.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_donut.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

/// 숫자 정렬용 tabular figures.
const List<FontFeature> kStocksTnum = [FontFeature.tabularFigures()];

// ---- 공용 조각 --------------------------------------------------------------

/// 띠 구역 제목 — 위 24 · 좌우 24 · 아래 4 (R4 t5 · 700).
class StocksBandTitle extends StatelessWidget {
  const StocksBandTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x1,
      ),
      child: Semantics(
        header: true,
        headingLevel: 2,
        child: Text(
          text,
          style: PTypography.t5.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.fgNeutral,
          ),
        ),
      ),
    );
  }
}

PDeltaDirection stocksDir(StockDirection d) => switch (d) {
  StockDirection.up => PDeltaDirection.up,
  StockDirection.down => PDeltaDirection.down,
  StockDirection.flat => PDeltaDirection.flat,
};

/// 등락률 Delta — ▲/▼ + "12.23%". 0 이면 "0.00%" 화살표 없이 옅은 색.
class StocksPctDelta extends StatelessWidget {
  const StocksPctDelta(this.pct, {super.key});
  final double pct;

  @override
  Widget build(BuildContext context) {
    final d = directionOfPct(pct);
    if (d == StockDirection.flat) {
      return Text(
        '0.00%',
        style: PTypography.t3.copyWith(
          color: context.colors.fgNeutralSubtle,
          fontWeight: FontWeight.w500,
          fontFeatures: kStocksTnum,
        ),
      );
    }
    return PDelta(direction: stocksDir(d), value: formatChangeRateAbs(pct));
  }
}

/// 손익 금액 + 수익률 Delta ("▲ 338,749,027원 · 10.26%") — 가리면 금액 대신 점.
///
/// [currency] 는 금액의 통화다 — 미국 종목 손익은 "$123.45"(원이 아니다). [pct] 가 null 이면 금액만("▲ $123.45").
/// 0 이면 방향 없는 "변화 없음"(card.md Delta flat).
PDelta stocksPnlDelta(
  num pnl,
  double? pct,
  bool masked, {
  String currency = 'KRW',
  String? text,
}) {
  final d = directionOf(pnl.toDouble());
  final amount = masked
      ? '••••'
      : fmtByCurrency(pnl.abs().toDouble(), currency);
  return PDelta(
    direction: stocksDir(d),
    value: d == StockDirection.flat
        ? null
        : (pct == null ? amount : '$amount · ${formatChangeRateAbs(pct)}'),
    text: text,
  );
}

TextStyle stocksMoneyStyle(BuildContext context) => PTypography.t5.copyWith(
  fontWeight: FontWeight.w700,
  color: context.colors.fgNeutral,
  fontFeatures: kStocksTnum,
);

/// 종목 줄 — ds List 누르는 줄. 앞 타일 없음(1T-다), 뒤 = 금액 + Delta.
class StocksLine extends StatelessWidget {
  const StocksLine({
    super.key,
    required this.name,
    required this.detail,
    required this.onTap,
    this.amount,
    this.pct,
    this.rank,
    this.topRank = false,
  });

  final String name;
  final String detail;
  final VoidCallback onTap;
  final String? amount;
  final double? pct;
  final int? rank;
  final bool topRank;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = MediaQuery.sizeOf(context).width;
    return PListButtonItem(
      title: name,
      detail: detail,
      onTap: onTap,
      prefix: rank == null
          ? null
          : SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: PTypography.t4.copyWith(
                  fontWeight: FontWeight.w700,
                  color: topRank ? c.fgBrand : c.fgNeutralSubtle,
                  fontFeatures: kStocksTnum,
                ),
              ),
            ),
      suffix: PListValue(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: w * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                keepAllAmount(amount ?? '—'),
                textAlign: TextAlign.right,
                style: stocksMoneyStyle(context),
              ),
              if (pct != null) ...[
                const SizedBox(height: 2),
                StocksPctDelta(pct!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 구역 실패 한 벌 — 제목 + "잠시 뒤 다시 시도해주세요." + [다시 시도]. 오류 원문은 그리지 않는다.
class StocksFailure extends StatelessWidget {
  const StocksFailure({
    super.key,
    required this.title,
    required this.onRetry,
    this.description,
    this.retrying = false,
  });
  final String title;
  final VoidCallback onRetry;

  /// 실패 뒤 다시 받는 중 — [다시 시도] 에 진행 원(skeleton.md:139).
  final bool retrying;

  /// 설명 — 비우면 "잠시 뒤 다시 시도해주세요.".
  final String? description;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ColoredBox(
      color: context.colors.bgLayerDefault,
      child: PResultSection(
        kind: PResultKind.failure,
        size: PResultSize.medium,
        title: title,
        description: description ?? l.stocksFailDesc,
        primaryAction: PResultAction(
          label: l.actionRetry,
          loading: retrying,
          onPressed: onRetry,
        ),
        headingLevel: 3,
      ),
    );
  }
}

/// 시세 조회 실패 — 자리의 값 유무로 모양이 갈린다(I-wrap-b2b 4, 디자인시스템 판단).
///
/// - [stale] 참(받아 둔 숫자 · 대신 그린 값이 보인다): 섹션 머리 아래 Callout critical · actionable(상자 전체가 다시 시도)
///   — 제목 "시세를 불러오지 못했어요", 본문 "보이는 값은 마지막으로 받은 시세예요."([description] 으로 바꿀 수 있다).
///   이미 보이는 내용 위에 실패 Result Section 을 얹지 않는다(result-section.md:53 · callout.md:3) — 폴링이 실패할 때마다
///   화면이 밀리지 않게. Callout 은 로딩 상태가 없어 진행 원을 걸지 않고, 다시 받는 동안([retrying]) 다시 누름을 무시한다.
/// - [stale] 거짓(값이 하나도 없는 처음 실패): 그 자리 Result Section + [다시 시도](진행 원 — B2a).
///
/// 다음 받기가 성공하면 부르는 쪽 조건이 거짓이 되어 저절로 걷힌다. 스낵바는 쓰지 않는다.
class StocksPriceFailure extends StatelessWidget {
  const StocksPriceFailure({
    super.key,
    required this.stale,
    required this.onRetry,
    this.retrying = false,
    this.description,
    this.gutter = true,
  });

  final bool stale;

  /// Callout 이 화면 여백을 스스로 두는가 — 머리 칸처럼 이미 여백 안이면 끈다.
  final bool gutter;
  final VoidCallback onRetry;

  /// 다시 받는 중 — Result Section 이면 [다시 시도] 에 진행 원, Callout 이면 누름을 무시한다.
  final bool retrying;

  /// Callout 본문 — 비우면 "보이는 값은 마지막으로 받은 시세예요.".
  final String? description;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!stale) {
      return StocksFailure(
        key: const ValueKey('stocks-price-failure'),
        title: l.stocksFailPrice,
        retrying: retrying,
        onRetry: onRetry,
      );
    }
    return StaleValueCallout(
      key: const ValueKey('stocks-price-stale'),
      title: l.stocksFailPrice,
      description: description ?? l.stocksStaleLastPrice,
      retrying: retrying,
      onRetry: onRetry,
      gutter: gutter,
    );
  }
}

/// 목록 줄 Skeleton — 제목 · 설명 · 오른쪽 두 줄.
class StocksLineSkeleton extends StatelessWidget {
  const StocksLineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.x6,
        vertical: PSpacing.x3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 글 자리 = 줄 높이 — 이름 t5 · 설명 t3(List 줄과 같다)
                PSkeleton.text(PTypography.t5, width: 120),
                const SizedBox(height: 4),
                PSkeleton.text(PTypography.t3, width: 80),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 금액 t5 · 등락률 t3
              PSkeleton.text(PTypography.t5, width: 84),
              const SizedBox(height: 4),
              PSkeleton.text(PTypography.t3, width: 52),
            ],
          ),
        ],
      ),
    );
  }
}

class StocksGroupSkeleton extends StatelessWidget {
  const StocksGroupSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).stocksRankingLoading,
      child: ColoredBox(
        color: context.colors.bgLayerDefault,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                PSpacing.x2,
                PSpacing.x6,
                PSpacing.x2,
              ),
              child: PSkeleton(width: 96, height: 19),
            ),
            for (var i = 0; i < 3; i++) const StocksLineSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// 찾는 칸(입구) — Searchable List 칸 모양의 단추. 누르면 찾기 시트(밑줄형 large 40 · 돋보기 24 · 글 t6).
class StocksSearchEntry extends StatefulWidget {
  const StocksSearchEntry({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<StocksSearchEntry> createState() => _StocksSearchEntryState();
}

class _StocksSearchEntryState extends State<StocksSearchEntry> {
  /// 누르면 초점이 입구에 오고, 시트를 닫으면 route 가 그 초점을 돌려준다(키보드 · 화면 낭독 사용자가 제자리로 돌아온다).
  final _focus = FocusNode(debugLabel: 'stocks search entry');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    _focus.requestFocus();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x2,
        PSpacing.x6,
        0,
      ),
      // 누르는 자리 — ds PressArea. 누르는 동안 바탕 bg-layer-default-pressed + 내용 2px 축소(Input Button 의 누름과 같다).
      // Material 물결은 두지 않는다
      child: PressArea(
        key: const ValueKey('stocks-search-entry'),
        enabled: true,
        focusNode: _focus,
        onTap: _open,
        // 보이는 상자는 40(input.md 가 받아들인 값) — 누르는 영역만 44 까지 넓힌다. 위는 부모 여백 안이라 받고,
        // 아래는 부모 상자가 끝이라 넓히지 못한다(Flutter 는 부모 안에서만 자식에게 묻는다)
        touchMin: PTouch.min,
        // 키보드 초점 링 — 밑줄 칸이지만 다른 칸(Input Button)과 같은 링을 입구 전체 상자에 그린다
        focusRing: const PFocusRingStyle(radius: PRounded.r3),
        semantics: (child, enabled, tap) => Semantics(
          container: true,
          button: true,
          label: l.stocksSearch,
          excludeSemantics: true,
          onTap: tap,
          child: child,
        ),
        builder: (context, pressed, size) => Container(
          height: 40,
          decoration: BoxDecoration(
            color: pressed ? c.bgLayerDefaultPressed : const Color(0x00000000),
            border: Border(bottom: BorderSide(color: c.strokeNeutralWeak)),
          ),
          child: PressScale(
            pressed: pressed,
            size: size,
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 24, color: c.fgNeutralSubtle),
                const SizedBox(width: PSpacing.x2),
                Expanded(
                  child: PText(
                    l.stocksSearchPlaceholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypography.t6.copyWith(color: c.fgPlaceholder),
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

String stocksQty(double q) {
  if (q != q.roundToDouble()) {
    final whole = q.truncate();
    return '${krw(whole)}.${q.toStringAsFixed(4).split('.').last}';
  }
  return krw(q.round());
}

// ---- 색 헬퍼 ---------------------------------------------------------------

/// 상승/하락 색 — 국내 증권 통념: 상승=빨강, 하락=파랑. (호가 · 체결 표가 쓴다)
Color stocksRoleTrend(BuildContext context, double pct) =>
    pct >= 0 ? context.colors.fgCritical : context.colors.fgInformative;

// ---- 매수 유의사항 라벨 (토스 warningType → 한글) ----------------------------

/// 토스 warningType → 로케일 라벨 (웹 `warning.*` 키 미러). 모르는 타입은 원문 노출.
String stocksWarningLabel(AppLocalizations l, String type) => switch (type) {
  'LIQUIDATION_TRADING' => l.stocksWarningLiquidationTrading,
  'OVERHEATED' => l.stocksWarningOverheated,
  'SHORT_TERM_OVERHEAT' => l.stocksWarningShortTermOverheat,
  'EXCESSIVE_RISE' => l.stocksWarningExcessiveRise,
  'INVESTMENT_WARNING' => l.stocksWarningInvestmentWarning,
  'INVESTMENT_RISK' => l.stocksWarningInvestmentRisk,
  'INVESTMENT_CAUTION' => l.stocksWarningInvestmentCaution,
  'INVESTMENT_ATTENTION' => l.stocksWarningInvestmentAttention,
  'VI' || 'VI_STATIC_AND_DYNAMIC' => l.stocksWarningVi,
  'VI_STATIC' => l.stocksWarningViStatic,
  'VI_DYNAMIC' => l.stocksWarningViDynamic,
  'STOCK_WARRANTS' => l.stocksWarningStockWarrants,
  'ADMINISTRATIVE' => l.stocksWarningAdministrative,
  'ADJUSTMENT_OF_SHARES' => l.stocksWarningAdjustmentOfShares,
  _ => type,
};

// ---- 차트 기간 (식별자는 임베드 주소 값이라 그대로, 표시 글만 바꾼다) -------------

const kStockRanges = ['1D', '1주', '1개월', '3개월', '1년'];

String stockRangeLabel(AppLocalizations l, String range) => switch (range) {
  '1주' => l.stocksRange1w,
  '1개월' => l.stocksRange1m,
  '3개월' => l.stocksRange3m,
  '1년' => l.stocksRange1y,
  _ => l.stocksRange1d,
};

/// 심볼 정확 일치 마스터 항목 (KR/US 우선 — 시장 간 심볼 중복 대비).
StockMasterItem? findMasterBySymbol(
  List<StockMasterItem> items,
  String symbol,
) {
  final up = symbol.toUpperCase();
  final exact = [
    for (final s in items)
      if (s.symbol.toUpperCase() == up) s,
  ];
  if (exact.isEmpty) return null;
  for (final s in exact) {
    if (s.countryCode == 'KR' || s.countryCode == 'US') return s;
  }
  return exact.first;
}

/// 키-값 줄 — 키는 옅게, 값은 오른쪽 굵게. 보기만 하는 줄.
Widget stocksKvLine(
  BuildContext context,
  String key,
  String value, {
  Color? valueColor,
  Widget? valueWidget,
}) {
  final c = context.colors;
  return PListItem(
    title: key,
    titleColor: c.fgNeutralSubtle,
    // 키-값 줄은 ds List 값 그대로(위아래 12 는 PListItem 기본) — 따로 줄이지 않는다(사용자 정정 10-30 "ds 그대로").
    // 키 글 t4 는 PListItem 이 t5 로 고정이라 ds 몫.
    suffix: PListValue(
      child:
          valueWidget ??
          Text(
            keepAllAmount(value),
            textAlign: TextAlign.right,
            style: stocksMoneyStyle(context).copyWith(color: valueColor),
          ),
    ),
  );
}

/// 포트폴리오 구성 본문 — 도넛 112 + 범례(색 칸 10 · 종목 이름 · 비중). 토스 · 나무 페이지가 함께 쓴다.
class StocksCompositionBody extends StatelessWidget {
  const StocksCompositionBody({
    super.key,
    required this.comp,
    this.masked = false,
  });
  final List<CompositionSlice> comp;

  /// 금액 가리기 — 도넛 조각 금액도 범례 비중도 가린다.
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    const palette = PChartColor.values;
    final colors = [
      for (var i = 0; i < comp.length; i++) palette[i % palette.length],
    ];
    return Padding(
      padding: const EdgeInsets.all(PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: PDonutChart(
              label: l.stocksPortfolioTitle,
              diameter: 112,
              centerAmount: l.stocksPortfolioCount(comp.length),
              valueFormatter: masked ? (_) => '••••' : null,
              slices: [
                for (var i = 0; i < comp.length; i++)
                  PDonutSlice(
                    key: comp[i].symbol,
                    label: comp[i].name,
                    amount: comp[i].krwValue,
                    color: colors[i],
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          PList(
            semanticLabel: l.stocksPortfolioTitle,
            children: [
              for (var i = 0; i < comp.length; i++)
                PListItem(
                  title: comp[i].name,
                  gutter: 0,
                  prefix: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i].of(c),
                      borderRadius: BorderRadius.circular(PRounded.r0_5),
                    ),
                  ),
                  suffix: PListValue(
                    child: PText(
                      masked
                          ? '••••'
                          : formatShare(
                              comp[i].weightPct,
                              underOne: l.percentUnderTenth,
                            ),
                      style: stocksMoneyStyle(context),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 스크롤로 화면 밖에 나가도 지어 둔 채 둔다(차트 WebView · 고른 탭). 폐기됐다 다시 지어지지 않게(M13).
class StocksKeepAlive extends StatefulWidget {
  const StocksKeepAlive({super.key, required this.child});
  final Widget child;

  @override
  State<StocksKeepAlive> createState() => _StocksKeepAliveState();
}

class _StocksKeepAliveState extends State<StocksKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
