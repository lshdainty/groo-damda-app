// PBarChart.stacked · PChartSeries.weak · PChartLegendItem.weak (I-08 36 · 37 · 38 — 통계의 쌓은 막대 · 지난 기간 옅은 색).
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

Widget _host(Widget child, {Brightness mode = Brightness.light}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 330, child: child),
    ),
  ),
);

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    final c = mode == Brightness.dark ? PColors.dark : PColors.light;
    group('쌓은 막대 · 옅은 계열 — $mode', () {
      testWidgets('쌓으면 칸마다 막대 하나, 계열을 아래부터 쌓고 눈금은 합으로 정한다', (tester) async {
        await tester.pumpWidget(
          _host(
            const PBarChart(
              label: '고정 · 변동',
              height: 200,
              stacked: true,
              categories: ['9월', '10월'],
              series: [
                PChartSeries(
                  key: 'fixed',
                  label: '고정',
                  color: PChartColor.blue,
                  values: [300, 100],
                ),
                PChartSeries(
                  key: 'variable',
                  label: '변동',
                  color: PChartColor.green,
                  values: [200, 100],
                ),
              ],
            ),
            mode: mode,
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        final data = tester.widget<BarChart>(find.byType(BarChart)).data;
        expect(data.barGroups.length, 2);
        final rod = data.barGroups[0].barRods.single;
        expect(rod.rodStackItems.length, 2);
        expect(rod.rodStackItems[0].color, c.chartBlue);
        expect(rod.rodStackItems[1].color, c.chartGreen);
        // 두 번째 계열은 첫 계열 끝에서 시작한다(쌓임)
        expect(rod.rodStackItems[1].fromY, rod.rodStackItems[0].toY);
        expect(rod.toY, rod.rodStackItems[1].toY);
        // 눈금은 합 500 을 덮는다(계열 하나의 최대 300 이 아니라)
        expect(data.maxY, greaterThanOrEqualTo(rod.toY));
        expect(
          rod.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(4)),
        );
      });

      testWidgets('weak 계열은 같은 색의 옅은 단계로 그리고 툴팁 네모도 같다', (tester) async {
        await tester.pumpWidget(
          _host(
            const PBarChart(
              label: '요일',
              height: 200,
              categories: ['월', '화'],
              series: [
                PChartSeries(
                  key: 'now',
                  label: '이번 달',
                  color: PChartColor.blue,
                  values: [10, 20],
                ),
                PChartSeries(
                  key: 'prev',
                  label: '지난 달',
                  color: PChartColor.blue,
                  weak: true,
                  values: [5, 25],
                ),
              ],
            ),
            mode: mode,
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        final rods = tester
            .widget<BarChart>(find.byType(BarChart))
            .data
            .barGroups[0]
            .barRods;
        expect(rods[0].color, c.chartBlue);
        expect(rods[1].color, previousPeriodGrayOf(c));
      });

      testWidgets('지표 타일 weak 점은 옅은 색', (tester) async {
        await tester.pumpWidget(
          _host(
            const PChartLegendTiles(
              items: [
                PChartLegendItem(
                  key: 'prev',
                  label: '지난 달',
                  color: PChartColor.blue,
                  total: '1,000원',
                  weak: true,
                ),
              ],
            ),
            mode: mode,
          ),
        );
        final dot = tester.widget<Container>(
          find.byKey(const ValueKey('chart-legend-dot')),
        );
        expect(
          (dot.decoration as BoxDecoration).color,
          previousPeriodGrayOf(c),
        );
      });
    });
  }
}
