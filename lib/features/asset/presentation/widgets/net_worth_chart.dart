import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 12개월 순자산 추이 — ds 선 차트. **영역 채움 없이 선 + 데이터 점마다 점**(I-05 57, 사용자 고침 — chart.md 선 줄
/// "점이 적은 추이는 선 + 점도 된다"). 점은 지름 6 · 계열 색 · 테두리 없음(이 화면 값), 가리킨 점은 스펙 그대로.
///
/// 눈금 글자는 "400만" 로 줄이고 툴팁은 원까지(빼기 U+2212). 접근성은 차트 이름 + 표로 보기(03E-004b).
/// 이 차트만 제 쿼리로 불러오고 제 자리에서 실패한다(62) — 실패하면 이 자리에서 다시 시도한다.
class NetWorthChart extends ConsumerWidget {
  const NetWorthChart({super.key, this.height = 140, this.months = 12});

  final double height;
  final int months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final trendAsync = ref.watch(netWorthTrendProvider(months));
    final masked = ref.watch(hideCardProvider('asset.netWorth'));

    final points = trendAsync.value;
    if (points == null) {
      if (trendAsync.hasError) {
        return BudgetFailure(
          title: l.assetLoadFailedTrend,
          retrying: trendAsync.isLoading,
          onRetry: () => ref.invalidate(netWorthTrendProvider(months)),
        );
      }
      // 불러오는 중 — 차트 높이 그대로(옛 화면 전체 게이트가 아니라 이 자리만)
      return PSkeleton(height: height);
    }
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            keepAll(l.assetTrendEmpty),
            textAlign: TextAlign.center,
            style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
      );
    }

    // 날짜 규칙 — 월은 앞 0 을 채우지 않는다("1월" … "12월")
    String monthLabel(int month) => monthOnly(DateTime(2000, month));
    String won(num v) => masked ? kBudgetMask : formatWon(v);
    final labels = [for (final p in points) monthLabel(p.month)];
    final latest = won(points.last.netWorth);
    final name = l.assetChartNetWorthName(latest);
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
              key: 'netWorth',
              label: l.assetNetWorth,
              color: PChartColor.blue,
              values: [for (final p in points) p.netWorth.toDouble()],
            ),
          ],
          axisFormatter: (v) => masked ? kBudgetMask : formatAxisWon(v),
          valueFormatter: won,
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.assetChartTableMonth),
            PChartDataColumn(l.assetNetWorth),
          ],
          rows: [
            for (var i = 0; i < points.length; i++)
              [labels[i], won(points[i].netWorth)],
          ],
        ),
      ],
    );
  }
}
