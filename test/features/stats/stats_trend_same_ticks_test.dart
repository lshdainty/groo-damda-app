// 통계 › 추이 — 같은 화면 · 같은 기간 차트는 같은 날짜 글(chart.md "큰 글자", groo-design #247).
//
// 수입 · 지출 추이(선 · 이중 축)와 일별 · 월별 순저축(막대 · 축 하나)은 같은 점을 먹는다. 축 수가 달라 그리는 폭이 달라도 그리는
// 자리가 가장 좁은 차트로 가로 눈금 건너뛰기를 한 번 세고, 위아래 차트가 같은 날짜 글을 보인다. 가장 나쁜 값 — 폰 320 · 글자 200%.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_trend_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

final _today = DateTime(2026, 11, 30);

/// 30일 — 수입은 며칠에 크게, 지출은 날마다 작게(두 축이 열 배 넘게 다르다).
List<TrendPoint> _daily() => [
  for (var d = 1; d <= 30; d++)
    TrendPoint(
      label: '11. $d.',
      income: d % 10 == 0 ? 4200000 : 0,
      expense: 30000 + d * 4000,
    ),
];

/// 12개월.
List<TrendPoint> _monthly() => [
  for (var m = 1; m <= 12; m++)
    TrendPoint(
      label: '$m월',
      income: 3200000 + m * 50000,
      expense: 2100000 + (m % 4) * 600000,
    ),
];

Future<void> _host(
  WidgetTester tester,
  List<TrendPoint> points, {
  required double width,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final period = StatsPeriod.thisMonth(_today);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatsTrendSection(
                period: period,
                onPickPeriod: () {},
                points: points,
                daily: true,
                masked: false,
              ),
              StatsSavingsBarsSection(
                period: period,
                points: points,
                daily: true,
                masked: false,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// [chart] 안에 그려진 가로 눈금 글(왼쪽부터).
List<String> _xLabels(WidgetTester tester, Type chart, List<String> cats) {
  final of = find.byType(chart);
  return [
    for (final c in cats)
      if (find.descendant(of: of, matching: findText(c)).evaluate().isNotEmpty)
        c,
  ];
}

/// 12개월 · 수입이 억 단위 — 세로축 글이 길어 이중 축 선은 끝 글 하나만, 축 하나인 막대는 둘이 들어가는 가장 나쁜 값.
List<TrendPoint> _monthlyLarge() => [
  for (var m = 1; m <= 12; m++)
    TrendPoint(
      label: '$m월',
      income: m % 3 == 0 ? 420000000 : 210000000,
      expense: 3000000 + m * 1000,
    ),
];

void main() {
  final cases = <String, List<TrendPoint> Function()>{
    '일별 30일': _daily,
    '월별 12개월': _monthly,
    '월별 12개월 · 수입 억 단위': _monthlyLarge,
  };
  for (final e in cases.entries) {
    for (final (width, scale) in [(320.0, 2.0), (320.0, 1.3), (360.0, 1.0)]) {
      testWidgets(
        '${e.key} · 폭 ${width.round()} · 글자 ${(scale * 100).round()}% — 위아래 차트가 같은 날짜 글',
        (tester) async {
          final points = e.value();
          final cats = [for (final p in points) p.label];
          await _host(tester, points, width: width, scale: scale);
          final line = _xLabels(tester, PLineChart, cats);
          final bars = _xLabels(tester, PBarChart, cats);
          expect(line, isNotEmpty);
          expect(line.last, cats.last, reason: '끝(가장 최근) 글은 늘 남는다');
          expect(bars, line, reason: '순저축 막대가 추이 선과 같은 날짜 글을 쓴다');
          // 서로를 짝으로 넘긴다 — 상대의 짝은 비운다(재귀 없이 폭만 잰다)
          final lineChart = tester.widget<PLineChart>(find.byType(PLineChart));
          final barChart = tester.widget<PBarChart>(find.byType(PBarChart));
          expect(lineChart.xTickPeers.single, isA<PBarChart>());
          expect(barChart.xTickPeers.single, isA<PLineChart>());
          expect(lineChart.xTickPeers.single.xTickPeers, isEmpty);
        },
      );
    }
  }

  testWidgets('수입 · 지출이 모두 0 이면 추이 선이 없으니 순저축 막대는 짝 없이 센다', (tester) async {
    final points = [
      for (var d = 1; d <= 30; d++)
        TrendPoint(label: '11. $d.', income: 0, expense: 0),
    ];
    await _host(tester, points, width: 320, scale: 2);
    expect(find.byType(PLineChart), findsNothing);
    expect(
      tester.widget<PBarChart>(find.byType(PBarChart)).xTickPeers,
      isEmpty,
    );
  });
}
