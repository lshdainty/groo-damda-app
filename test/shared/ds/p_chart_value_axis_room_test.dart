// 세로축 끝 글 · 막대 위 값 자리 — 큰 글자(200 · 300%)에서도 글이 차트 상자 안에 들고 서로 겹치지 않는다(chart.md "큰 글자",
// groo-design #250).
//
// 세로 눈금 글은 눈금 선 가운데에 서서 맨 위 · 맨 아래 글이 그리는 자리 밖으로 줄 높이의 절반만큼 나간다.
// ⓐ 위 여백 = max(지금 위 여백, ⌈세로 눈금 글 줄 높이 ÷ 2⌉) — 맨 위 글이 차트 위로 나가지 않는다
// ⓑ 가로 눈금 줄은 그리는 자리 아래 max(8, ⌈줄 ÷ 2⌉ + 4) 에서 시작 — 맨 아래 세로 글이 첫 가로 글과 겹치지 않는다
// ⓒ 막대 위 값 자리 = 그 글 줄 높이 + 4 — 글자가 커져도 값이 막대 위에 선다
// 세로 눈금 칸 수(겹치면 줄임)도 이 여백을 뺀 높이로 센다. 최대값이 맨 위 눈금, 0 이 맨 아래 눈금인 값으로 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

final _cats6 = [for (var m = 1; m <= 6; m++) '$m월'];

/// 0 ~ 100만 — 눈금 칸 수를 몇으로 줄여도 맨 위 눈금은 최대값(100만), 맨 아래는 0 이다.
const List<double> _values = [0, 200000, 500000, 300000, 800000, 1000000];

Future<Rect> _pump(
  WidgetTester tester,
  Widget chart,
  double scale,
  Type type,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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
        body: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 360, child: chart),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(tester.takeException(), isNull);
  return tester.getRect(find.byType(type));
}

/// [type] 차트 안 글 가운데 [exclude] 를 뺀 자리.
List<Rect> _texts(WidgetTester tester, Type type, bool Function(String) keep) =>
    [
      for (final e
          in find
              .descendant(of: find.byType(type), matching: find.byType(Text))
              .evaluate())
        if (keep(plainOf((e.widget as Text).data ?? '')))
          tester.getRect(find.byWidget(e.widget)),
    ];

PChartSeries _series(String key, List<double> values, {bool right = false}) =>
    PChartSeries(
      key: key,
      label: key,
      color: right ? PChartColor.red : PChartColor.blue,
      onRight: right,
      values: values,
    );

Widget _chart(String kind, double height, List<String> cats) {
  final values = _values.sublist(_values.length - cats.length);
  return switch (kind) {
    'line' => PLineChart(
      label: '추이',
      height: height,
      categories: cats,
      series: [_series('n', values)],
    ),
    'bar' => PBarChart(
      label: '막대',
      height: height,
      categories: cats,
      series: [_series('n', values)],
    ),
    _ => PLineChart(
      label: '이중 축',
      height: height,
      categories: cats,
      series: [
        _series('in', values),
        _series('out', [for (final v in values) v / 10], right: true),
      ],
    ),
  };
}

void main() {
  group('ⓐ 맨 위 · 맨 아래 세로 눈금 글이 차트 상자 안에 든다', () {
    for (final kind in ['line', 'bar', 'dual']) {
      for (final height in [140.0, 200.0]) {
        for (final scale in [1.0, 2.0, 3.0]) {
          testWidgets(
            '$kind · 높이 ${height.round()} · 글자 ${(scale * 100).round()}%',
            (tester) async {
              final type = kind == 'bar' ? PBarChart : PLineChart;
              final box = await _pump(
                tester,
                _chart(kind, height, _cats6),
                scale,
                type,
              );
              expect(box.height, height, reason: '차트 높이는 그대로');
              final ticks = _texts(tester, type, (t) => !_cats6.contains(t));
              expect(ticks.length, greaterThanOrEqualTo(2));
              for (final r in ticks) {
                expect(
                  r.top,
                  greaterThanOrEqualTo(box.top - 0.5),
                  reason: '세로 눈금 글이 차트 위로 나간다 — $r · 상자 $box',
                );
                expect(
                  r.bottom,
                  lessThanOrEqualTo(box.bottom + 0.5),
                  reason: '세로 눈금 글이 차트 아래로 나간다 — $r · 상자 $box',
                );
              }
              // 맨 위 눈금은 최대값(100만 · 이중 축 오른쪽 10만) — 데이터가 맨 위 선에 닿는 가장 나쁜 값
              expect(
                find.descendant(
                  of: find.byType(type),
                  matching: findText('100만'),
                ),
                findsOneWidget,
              );
              // 같은 쪽 세로 눈금끼리 겹치지 않는다(칸 수는 늘어난 여백을 뺀 높이로 센다)
              for (final left in [true, false]) {
                final side = [
                  for (final r in ticks)
                    if ((r.center.dx < box.center.dx) == left) r,
                ]..sort((a, b) => a.top.compareTo(b.top));
                for (var k = 1; k < side.length; k++) {
                  expect(
                    side[k].top,
                    greaterThanOrEqualTo(side[k - 1].bottom - 0.5),
                  );
                }
              }
            },
          );
        }
      }
    }
  });

  group('ⓑ 맨 아래 세로 눈금 글 ↔ 첫 가로 글 — 겹치지 않는다', () {
    const cats2 = ['1월', '2월'];
    // 이중 축 · 300% 는 360 폭에서 끝 글 하나만 남아 첫 글이 없다 — 첫 글이 보이는 조합만 본다
    for (final kind in ['line', 'dual']) {
      for (final scale in kind == 'line' ? [1.0, 2.0, 3.0] : [1.0, 2.0]) {
        testWidgets('$kind · 2칸(첫 글이 보인다) · 글자 ${(scale * 100).round()}%', (
          tester,
        ) async {
          await _pump(tester, _chart(kind, 200, cats2), scale, PLineChart);
          final xs = _texts(tester, PLineChart, cats2.contains);
          final ys = _texts(tester, PLineChart, (t) => !cats2.contains(t));
          expect(xs, hasLength(2), reason: '첫 가로 글이 세로축 칸까지 걸친다');
          for (final x in xs) {
            for (final y in ys) {
              expect(
                x.overlaps(y.deflate(0.5)),
                isFalse,
                reason: '가로 글 $x 와 세로 글 $y 가 겹친다',
              );
            }
          }
        });
      }
    }
  });

  group('ⓒ 막대 위 값 글 — 막대 위에 서고 차트 안에 든다', () {
    for (final height in [140.0, 180.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('높이 ${height.round()} · 글자 ${(scale * 100).round()}%', (
          tester,
        ) async {
          final box = await _pump(
            tester,
            PBarChart(
              label: '이행률',
              height: height,
              categories: _cats6,
              series: [_series('n', _values)],
              barLabel: (i, v) => '${(v / 10000).round()}회',
            ),
            scale,
            PBarChart,
          );
          // 가장 큰 막대(100만)는 그리는 자리 맨 위 선에 닿는다 — 그 선은 맨 위 세로 눈금 글(100만)의 가운데다
          final top = tester.getRect(
            find.descendant(
              of: find.byType(PBarChart),
              matching: findText('100만'),
            ),
          );
          final label = tester.getRect(
            find.descendant(
              of: find.byType(PBarChart),
              matching: findText('100회'),
            ),
          );
          expect(
            label.bottom,
            lessThanOrEqualTo(top.center.dy + 0.5),
            reason: '값 글이 막대 윗끝($top) 아래로 내려와 막대와 겹친다 — $label',
          );
          expect(label.top, greaterThanOrEqualTo(box.top - 0.5));
        });
      }
    }
  });
}
