// 선 차트 축 — 눈금 글이 온전한지, 가로축 마지막 글자가 앞 글자와 겹치지 않는지(I-05 57). 눈금 칸은 가장 긴 눈금 글 폭으로
// 잡힌다("1,500억" 이 "1,5" 로 잘리지 않는다). 차트 그림 안 글은 글자 크기 설정을 따르지 않으므로(chart.md "글자 크기",
// groo-design #260) 축 자리 · 눈금 글은 큰 글자에서도 100% 와 같다.
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import '../../support/plain_text.dart';

Widget _host(double scale, {int months = 12}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 312,
        child: PLineChart(
          label: '추이',
          height: 140,
          area: false,
          dots: true,
          categories: [
            for (var i = 1; i <= months; i++)
              '${i.toString().padLeft(2, '0')}월',
          ],
          series: [
            PChartSeries(
              key: 'n',
              label: '순자산',
              color: PChartColor.blue,
              values: [for (var i = 0; i < months; i++) 100e9 + i * 5e9],
            ),
          ],
        ),
      ),
    ),
  ),
);

Future<FlTitlesData> _titles(WidgetTester t, double scale) async {
  await t.pumpWidget(_host(scale));
  await t.pump(const Duration(seconds: 1));
  return t.widget<LineChart>(find.byType(LineChart)).data.titlesData;
}

void main() {
  for (final scale in [2.0, 3.0]) {
    testWidgets(
      '${(scale * 100).round()}% — 세로축 칸 폭 · 가로축 자리 · 눈금 글이 100% 와 같다',
      (tester) async {
        final style = chartTickStyle(PColors.light);
        final t1 = await _titles(tester, 1);
        final widest = [
          '1,500억',
          '1,000억',
          '500억',
          '0',
        ].map((s) => measureText(s, style)).reduce((a, b) => a > b ? a : b);
        expect(
          t1.leftTitles.sideTitles.reservedSize,
          greaterThanOrEqualTo(widest),
          reason: '세로축 칸 폭 ≥ 눈금 글자 폭($widest) — 안 그러면 "1,5" 로 잘린다',
        );
        // 가로축 자리 = 눈금 줄 높이 15 + 그리는 자리와 사이 max(8, ⌈줄 ÷ 2⌉ + 4)(chart.md "세로축 끝 글의 자리를 비웁니다")
        expect(
          t1.bottomTitles.sideTitles.reservedSize,
          moreOrLessEquals(15 + math.max(8, (15 / 2).ceilToDouble() + 4)),
        );
        final ticks1 = findTextContaining(
          RegExp(r'억$|^0$'),
        ).evaluate().map((e) => (e.widget as Text).data).toList();
        final months1 = findTextContaining(
          RegExp(r'^\d\d월$'),
        ).evaluate().length;
        final t2 = await _titles(tester, scale);
        expect(
          t2.leftTitles.sideTitles.reservedSize,
          t1.leftTitles.sideTitles.reservedSize,
        );
        expect(
          t2.bottomTitles.sideTitles.reservedSize,
          t1.bottomTitles.sideTitles.reservedSize,
        );
        expect(
          findTextContaining(
            RegExp(r'억$|^0$'),
          ).evaluate().map((e) => (e.widget as Text).data).toList(),
          ticks1,
          reason: '세로 눈금 글이 같다',
        );
        expect(
          findTextContaining(RegExp(r'^\d\d월$')).evaluate().length,
          months1,
          reason: '보이는 달 수가 같다',
        );
        expect(findText('1,500억'), findsOneWidget, reason: '"1,500억" 이 그대로');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('100% 12개월 — 보이는 달 글자끼리 겹치지 않고 끝(마지막) 달을 지키고 앞에서부터 건너뛴다', (
    tester,
  ) async {
    await tester.pumpWidget(_host(1));
    await tester.pump(const Duration(seconds: 1));
    final labels = findTextContaining(RegExp(r'^\d\d월$'));
    final rects = [
      for (final e in labels.evaluate())
        tester.getRect(find.byWidget(e.widget)),
    ]..sort((a, b) => a.left.compareTo(b.left));
    expect(rects.length, greaterThan(2));
    for (var i = 0; i < rects.length - 1; i++) {
      expect(
        rects[i].right,
        lessThan(rects[i + 1].left),
        reason: '달 글자가 붙지 않는다',
      );
    }
    final shown =
        tester
            .widgetList<Text>(labels)
            .map((w) => int.parse(w.data!.substring(0, 2)))
            .toList()
          ..sort();
    final gaps = [
      for (var i = 0; i < shown.length - 1; i++) shown[i + 1] - shown[i],
    ];
    expect(gaps.toSet().length, 1, reason: '모두 같은 간격(마지막만 따로 찍히지 않는다) $shown');
    expect(shown.last, 12, reason: '끝 글을 지킨다');
  });
}
