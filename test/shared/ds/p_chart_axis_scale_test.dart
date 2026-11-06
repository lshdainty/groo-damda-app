// 선 차트 축 — 글자 배율 200% 에서도 눈금 글이 온전한지, 가로축 마지막 글자가 앞 글자와 겹치지 않는지(I-05 57).
// 눈금 칸은 글자 배율을 곱한 폭으로 잡힌다 — 1배로 재면 "1,500억" 이 "1,5" 로 잘렸다.
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
  testWidgets('200% — 세로축 칸 폭이 눈금 글자(배율 곱) 폭 이상 · 가로축 자리도 배율을 곱한다', (
    tester,
  ) async {
    final style = chartTickStyle(PColors.light);
    final t1 = await _titles(tester, 1);
    final t2 = await _titles(tester, 2);
    for (final scale in [1.0, 2.0]) {
      final titles = scale == 1 ? t1 : t2;
      final widest = ['1,500억', '1,000억', '500억', '0']
          .map((s) => measureText(s, style, scaler: TextScaler.linear(scale)))
          .reduce((a, b) => a > b ? a : b);
      expect(
        titles.leftTitles.sideTitles.reservedSize!,
        greaterThanOrEqualTo(widest),
        reason:
            '${scale * 100}% 세로축 칸 폭 ≥ 눈금 글자 폭($widest) — 안 그러면 "1,5" 로 잘린다',
      );
      expect(
        titles.bottomTitles.sideTitles.reservedSize,
        TextScaler.linear(scale).scale(15) + 8,
        reason: '가로축 자리 = 눈금 높이(배율 곱) + 8',
      );
    }
    expect(
      t2.bottomTitles.sideTitles.interval!,
      greaterThan(t1.bottomTitles.sideTitles.interval!),
      reason: '글이 커지면 달 글자 간격이 넓어져 붙지 않는다',
    );
  });

  testWidgets('200% — 눈금 글이 온전하다("1,500억" 이 그대로 그려진다)', (tester) async {
    await tester.pumpWidget(_host(2));
    await tester.pump(const Duration(seconds: 1));
    expect(findText('1,500억'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('100% 12개월 — 보이는 달 글자끼리 겹치지 않고 간격에 안 맞는 마지막 달은 그리지 않는다', (
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
  });
}
