/// 증권사 공통 맞춤 구역(I-13b 13b-1) — 오늘 시세 · 투자자별 매매동향 · 나무 장 상태 글.
/// 토스 · 나무 상세가 같은 부품을 쓴다. 값 없는 줄은 그리지 않고, 줄이 하나도 없으면 띠를 그리지 않는다.
library;

import 'package:flutter/material.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/market_state.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

/// 오늘 시세 한 줄의 값.
typedef TodayRow = ({String label, String value, Color? color});

/// 오늘 시세 여섯 줄(시가 · 고가 · 저가 · 거래량 · 상한가 · 하한가) — 값이 있는 줄만.
/// 상한가는 `fg-critical`, 하한가는 `fg-informative`(기본 정보에 있던 때의 색 그대로).
List<TodayRow> todayRowsOf(
  BuildContext context, {
  required String currency,
  double? open,
  double? high,
  double? low,
  double? volume,
  double? upper,
  double? lower,
}) {
  final l = AppLocalizations.of(context);
  final c = context.colors;
  String money(double v) => fmtByCurrency(v, currency);
  return [
    if (open != null)
      (label: l.stocksOpenPrice, value: money(open), color: null),
    if (high != null)
      (label: l.stocksHighPrice, value: money(high), color: null),
    if (low != null) (label: l.stocksLowPrice, value: money(low), color: null),
    if (volume != null)
      (
        label: l.stocksVolume,
        value: l.stocksSharesUnit(stocksQty(volume)),
        color: null,
      ),
    if (upper != null)
      (label: l.stocksUpperLimit, value: money(upper), color: c.fgCritical),
    if (lower != null)
      (label: l.stocksLowerLimit, value: money(lower), color: c.fgInformative),
  ];
}

/// 띠 — 오늘 시세. [rows] 가 비고 불러오는 중도 실패도 아니면 그리지 않는다.
class StocksTodayBand extends StatelessWidget {
  const StocksTodayBand({
    super.key,
    required this.rows,
    this.loading = false,
    this.failTitle,
    this.onRetry,
  });
  final List<TodayRow> rows;
  final bool loading;

  /// 실패면 제목(예: "오늘 시세를 불러오지 못했어요").
  final String? failTitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Widget body;
    if (failTitle != null && rows.isEmpty) {
      // 실패 자리에서 받는 중 = 다시 받는 중 — [다시 시도] 에 진행 원
      body = StocksFailure(
        title: failTitle!,
        retrying: loading,
        onRetry: onRetry ?? () {},
      );
    } else if (loading && rows.isEmpty) {
      body = Semantics(
        label: l.stocksTodayQuote,
        child: Column(
          children: [for (var i = 0; i < 4; i++) const StocksLineSkeleton()],
        ),
      );
    } else if (rows.isEmpty) {
      return const SizedBox.shrink();
    } else {
      body = PList(
        semanticLabel: l.stocksTodayQuote,
        children: [
          for (final r in rows)
            stocksKvLine(context, r.label, r.value, valueColor: r.color),
        ],
      );
    }
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [StocksBandTitle(l.stocksTodayQuote), body],
      ),
    );
  }
}

/// 순매수 값 — ▲ 순매수 `fg-critical` / ▼ 순매도 `fg-informative`, 쉼표 · 부호 없음 · 단위 없음. 0 은 "0" 옅게. null 은 "—".
Widget _investorValue(BuildContext context, double? v) {
  final c = context.colors;
  if (v == null) {
    return Text('—', style: PTypography.t3.copyWith(color: c.fgNeutralSubtle));
  }
  final n = v.round();
  if (n == 0) {
    return Text(
      '0',
      style: PTypography.t3.copyWith(
        color: c.fgNeutralSubtle,
        fontWeight: FontWeight.w500,
        fontFeatures: kStocksTnum,
      ),
    );
  }
  return PDelta(
    direction: n > 0 ? PDeltaDirection.up : PDeltaDirection.down,
    value: keepAllAmount(krw(n.abs())),
  );
}

/// 띠 — 투자자별 매매동향(국내 종목만). 폰 List 줄 다섯: 날짜 + 오른쪽 세 줄(개인 · 외국인 · 기관).
/// [days] 가 null 이고 불러오는 중이면 Skeleton, 빈 목록이면 안내 줄, 실패면 실패 한 벌.
class StocksInvestorBand extends StatelessWidget {
  const StocksInvestorBand({
    super.key,
    required this.days,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });
  final List<InvestorTradingDay>? days;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final Widget body;
    if (failed && days == null) {
      body = StocksFailure(
        title: l.stocksFailInvestor,
        retrying: loading,
        onRetry: onRetry,
      );
    } else if (loading && days == null) {
      body = Semantics(
        label: l.stocksInvestorTitle,
        child: Column(
          children: [for (var i = 0; i < 5; i++) const StocksLineSkeleton()],
        ),
      );
    } else if (days == null || days!.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.x6,
          PSpacing.x1,
          PSpacing.x6,
          PSpacing.x3,
        ),
        child: PText(
          l.stocksInvestorEmpty,
          style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
        ),
      );
    } else {
      // 줄 이름 칸은 고정 폭이 아니다 — 낱말 폭(최소 40)까지 넓어지고 낱말 안에서 꺾이지 않는다(영어 "Individual" ·
      // 큰 글자 한국어 "외국인" 이 한 글자씩 쪼개지던 것). 묶음의 세 줄 중 **하나라도** 이름 + 값이 한 줄에 못 들어가면
      // **세 줄 모두** 이름 아래로 값을 내린다(List "큰 글자에서 값을 본문 아래로" — 한 묶음에 두 모양이 섞이지 않게).
      // 줄 폭 상한을 두지 않는다(웹이 60cqw 상한을 해제한 것과 같다). 값만으로도 넘치면 값이 줄어들고 이름은 안 줄어든다.
      Widget labelled(String label, double? v, {required bool stacked}) {
        final name = ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.left,
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
        );
        final value = Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, box) => ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _investorValue(context, v),
              ),
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [name, value],
        );
      }

      body = PList(
        semanticLabel: l.stocksInvestorTitle,
        children: [
          for (final d in days!.take(5))
            PListItem(
              title: _dayLabel(l, d.date),
              suffix: PListValue(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final labels = [
                      l.stocksInvestorIndividual,
                      l.stocksInvestorForeigner,
                      l.stocksInvestorInstitution,
                    ];
                    final values = [d.individual, d.foreigner, d.institution];
                    final stacked =
                        box.maxWidth.isFinite &&
                        investorLinesNeedStacking(
                          context,
                          labels,
                          values,
                          box.maxWidth,
                        );
                    if (stacked) {
                      // 값이 이름 아래로 내려간 모양 — List 규칙대로 모두 왼쪽(list.md "큰 글자에서 값을 본문 아래로")
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(height: 2),
                            labelled(labels[i], values[i], stacked: true),
                          ],
                        ],
                      );
                    }
                    // 한 줄 모양 — 이름 칸 · 값 칸이 묶음 안 가장 넓은 폭으로 맞춰지고 둘 다 오른쪽 맞춤이다(웹과 같다).
                    // "—" · "0" 도 값 칸 오른쪽 끝에 붙어 같은 묶음의 숫자 끝과 나란하다.
                    return Table(
                      defaultColumnWidth: const IntrinsicColumnWidth(),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        for (var i = 0; i < 3; i++)
                          TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  right: PSpacing.x2,
                                  bottom: i < 2 ? 2 : 0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                    ),
                                    child: Text(
                                      labels[i],
                                      maxLines: 1,
                                      softWrap: false,
                                      textAlign: TextAlign.right,
                                      style: PTypography.t3.copyWith(
                                        color: c.fgNeutralSubtle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: i < 2 ? 2 : 0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _investorValue(context, values[i]),
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      );
    }
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x6,
              PSpacing.x6,
              PSpacing.x1,
            ),
            // 제목과 단위 글은 한 줄에 못 들어가면 줄을 나눠 쌓는다(웹 cc2814ea `flex-wrap`) — 글자 200% · 영어에서
            // 단위 글이 줄바꿈 없는 한 줄이라 넘치던 것(M12). 한 줄이면 단위 글이 오른쪽 끝에 붙는다.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: PSpacing.x2,
              runSpacing: 2,
              children: [
                Semantics(
                  header: true,
                  headingLevel: 2,
                  child: PText(
                    l.stocksInvestorTitle,
                    style: PTypography.t5.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.fgNeutral,
                    ),
                  ),
                ),
                PText(
                  l.stocksInvestorUnit,
                  style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                ),
              ],
            ),
          ),
          body,
        ],
      ),
    );
  }

  static String _dayLabel(AppLocalizations l, String date) {
    final d = date.length >= 10
        ? DateTime.tryParse(date.substring(0, 10))
        : null;
    return d == null ? date : l.stocksDailyDate(d.month, d.day);
  }
}

/// 나무 `marketState` → 시장 띠 글. 모르는 값은 null(그 시장 항목을 그리지 않는다).
/// `REGULAR` 는 "장중 · {지금}" — 보이는 시각은 토스 장 상태 줄과 같이 모두 한국 시각이다(13-1). 열려 있는 것은 정규장뿐이다.
({bool open, String text})? namuMarketStateText(
  AppLocalizations l,
  String? state,
) {
  switch (state) {
    case 'REGULAR':
      return (
        open: true,
        text: l.stocksMarketTrading(timeOfDay12(stocksKstNow())),
      );
    case 'PRE':
      return (open: false, text: l.stocksMarketPre);
    case 'AFTER':
      return (open: false, text: l.stocksMarketAfter);
    case 'DAYTIME':
      return (open: false, text: l.stocksMarketDaytime);
    case 'SINGLE_PRICE':
      return (open: false, text: l.stocksMarketSinglePrice);
    case 'HALTED':
      return (open: false, text: l.stocksMarketHalted);
    case 'BEFORE_OPEN':
      return (open: false, text: l.stocksMarketBeforeOpen);
    case 'CLOSED':
      return (open: false, text: l.stocksMarketClosed);
  }
  return null;
}

/// 주문 가능 금액 줄 — 값이 null 이면 호출부가 줄을 안 만든다. 불러오는 중이면 Skeleton, 실패면 "—".
Widget stocksBuyingPowerRow(
  BuildContext context, {
  required String title,
  required AsyncValue3 state,
  required bool masked,
  required String Function(double) format,
}) {
  final c = context.colors;
  final Widget value;
  if (state.loading) {
    // 값 글(stocksMoneyStyle = t5) 줄 높이
    value = PSkeleton.text(PTypography.t5, width: 96);
  } else if (state.failed) {
    value = Text('—', style: stocksMoneyStyle(context));
  } else {
    value = Text(
      masked ? '••••' : keepAllAmount(format(state.amount!)),
      textAlign: TextAlign.right,
      style: stocksMoneyStyle(context),
    );
  }
  return PListItem(
    title: title,
    titleColor: c.fgNeutralSubtle,
    suffix: PListValue(child: value),
  );
}

/// 값 상태 셋 — 불러오는 중 · 실패 · 값(amount). 값이 null 이고 둘 다 아니면 줄을 만들지 않는다.
class AsyncValue3 {
  const AsyncValue3({this.loading = false, this.failed = false, this.amount});
  final bool loading;
  final bool failed;
  final double? amount;
  bool get hasRow => loading || failed || amount != null;
}

/// 장 상태 줄 — "● 국내 장마감   ● 미국 개장 22:30". 줄바꿈 허용(항목 사이 16 · 줄 사이 4). 토스 · 나무 공용.
class StocksMarketStatusLine extends StatelessWidget {
  const StocksMarketStatusLine({super.key, required this.markets});
  final List<({String name, bool open, String detail})> markets;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
      child: Wrap(
        spacing: PSpacing.x4,
        runSpacing: 4,
        children: [
          for (final m in markets)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.open ? c.fgPositive : c.strokeNeutralSolid,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: m.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: c.fgNeutral,
                          ),
                        ),
                        TextSpan(text: ' ${m.detail}'),
                      ],
                    ),
                    style: PTypography.t4.copyWith(
                      color: c.fgNeutralSubtle,
                      fontFeatures: kStocksTnum,
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

/// 달러 시가총액 — 환율이 없어 원으로 못 바꿀 때만 쓴다(원으로 지어내지 않는다).
/// 1만 달러 미만은 외화 규칙 그대로(`$` + 소수 둘째 자리), 그 위는 큰 값 줄임(ko "9,900억 달러" · en "$990B").
/// 한국어 단위(억 · 조)에 `$` 를 붙이면 "$9,900억" 으로 두 표기가 섞여 읽히므로 ko 는 "달러" 를 뒤에 둔다.
String fmtCapUsd(double v) {
  if (v < 10000) return fmtByCurrency(v, 'USD');
  final body = formatChartAxis(v);
  return localeIsEn() ? '\$$body' : '$body 달러';
}

/// 글자 배율을 반영한 한 줄 글 폭.
double investorTextWidth(BuildContext context, String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  return tp.width;
}

/// 투자자별 세 줄 중 하나라도 이름 + 간격 + 값이 [maxWidth] 한 줄에 안 들어가는가(글자 배율을 반영해 잰다).
/// 값은 화살표 자리(글자 크기 + 4)를 더해 넉넉히 잡는다. 하나라도 넘치면 세 줄을 모두 쌓는다.
@visibleForTesting
bool investorLinesNeedStacking(
  BuildContext context,
  List<String> labels,
  List<double?> values,
  double maxWidth,
) {
  final scaler = MediaQuery.textScalerOf(context);
  double width(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  final labelStyle = PTypography.t3;
  final valueStyle = PTypography.t3.copyWith(fontWeight: FontWeight.w500);
  final arrow = scaler.scale(13) + 4;
  // 한 줄 모양은 이름 칸 · 값 칸이 묶음 안 가장 넓은 폭으로 맞춰지므로 두 칸의 최댓값으로 잰다.
  var labelMax = 40.0;
  var valueMax = 0.0;
  for (var i = 0; i < labels.length; i++) {
    final v = values[i];
    final text = v == null ? '—' : krw(v.round().abs());
    final hasArrow = v != null && v.round() != 0;
    final lw = width(labels[i], labelStyle);
    if (lw > labelMax) labelMax = lw;
    final vw = width(text, valueStyle) + (hasArrow ? arrow : 0);
    if (vw > valueMax) valueMax = vw;
  }
  return labelMax + PSpacing.x2 + valueMax > maxWidth;
}
