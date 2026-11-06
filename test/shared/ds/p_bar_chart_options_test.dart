// PBarChart 선택 인자(I-08 13 — 예산 이행률): 막대마다 색 · 막대 위 값 글 · 가로 기준선 · 세로축 숨김 · 강조 칸 · 툴팁 덧줄.
// 기본(인자 없음)은 p_chart_spec_test 가 스펙대로 잰다 — 여기는 인자를 줬을 때만.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import '../../support/plain_text.dart';

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

PBarChart _chart({
  bool showValueAxis = true,
  bool labels = false,
  List<double> refs = const [],
  int? emphasized,
}) => PBarChart(
  label: '이행률',
  height: 180,
  categories: const ['7월', '8월', '9월'],
  series: const [
    PChartSeries(
      key: 'p',
      label: '한도 대비',
      color: PChartColor.blue,
      values: [40, 150, null],
    ),
  ],
  barColor: (i, c) => i == 1 ? c.chartRed : c.chartBlueWeak,
  barLabel: labels ? (i, v) => '${v.round()}%' : null,
  referenceLines: refs,
  showValueAxis: showValueAxis,
  emphasizedIndex: emphasized,
  tooltipFooter: (i) => [(name: '지출', value: '1,000원')],
);

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    final c = mode == Brightness.dark ? PColors.dark : PColors.light;
    group('PBarChart 선택 인자 — $mode', () {
      testWidgets('막대마다 색 · 기준선 · 세로축 숨김', (tester) async {
        await tester.pumpWidget(
          _host(_chart(showValueAxis: false, refs: const [100]), mode: mode),
        );
        await tester.pump(const Duration(seconds: 1));
        final data = tester.widget<BarChart>(find.byType(BarChart)).data;
        expect(data.barGroups[0].barRods.first.color, c.chartBlueWeak);
        expect(data.barGroups[1].barRods.first.color, c.chartRed);
        final line = data.extraLinesData.horizontalLines.single;
        expect(line.color, c.strokeNeutralWeak);
        expect(line.dashArray, kChartDash);
        expect(line.strokeWidth, 1);
        // 세로축 눈금 · 격자 없음
        expect(data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
        expect(data.gridData.show, isFalse);
        // 기준선이 눈금 범위 안(100 < maxY × step)
        expect(line.y, lessThanOrEqualTo(data.maxY));
      });

      testWidgets('막대 위 값 글 — 값이 없는 칸은 글 없음, 글은 t2 700 fg-neutral', (
        tester,
      ) async {
        await tester.pumpWidget(_host(_chart(labels: true), mode: mode));
        await tester.pump(const Duration(seconds: 1));
        expect(find.byKey(const ValueKey('chart-bar-label-0')), findsOneWidget);
        expect(find.byKey(const ValueKey('chart-bar-label-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('chart-bar-label-2')), findsNothing);
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('chart-bar-label-1')),
            matching: find.byType(Text),
          ),
        );
        expect(text.data, '150%');
        expect(text.style!.fontWeight, FontWeight.w700);
        expect(text.style!.fontSize, 12);
        expect(text.style!.color, c.fgNeutral);
      });

      testWidgets('강조 칸의 가로축 글만 700 · fg-neutral', (tester) async {
        await tester.pumpWidget(_host(_chart(emphasized: 2), mode: mode));
        await tester.pump(const Duration(seconds: 1));
        final on = tester.widget<Text>(findText('9월'));
        final off = tester.widget<Text>(findText('8월'));
        expect(on.style!.fontWeight, FontWeight.w700);
        expect(on.style!.color, c.fgNeutral);
        expect(off.style!.fontWeight, isNot(FontWeight.w700));
      });
    });
  }

  testWidgets('툴팁 덧줄 — 색 네모 없이 글만', (tester) async {
    await tester.pumpWidget(
      _host(
        const PChartTooltip(
          head: '9월',
          rows: [
            PChartTooltipRow(
              swatch: Color(0xFF000000),
              name: '한도 대비',
              value: '150.0%',
            ),
            PChartTooltipRow(name: '지출', value: '1,000원'),
          ],
        ),
      ),
    );
    expect(find.byKey(const ValueKey('chart-tooltip-swatch')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-tooltip-row')), findsNWidgets(2));
    expect(findText('지출'), findsOneWidget);
  });
}
