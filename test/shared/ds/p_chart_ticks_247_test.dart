// 차트 눈금 — groo-design #247(chart.md "큰 글자" 아래 네 줄, 사용자 결정).
//
// ⓐ 끝 글 자리는 비워 둔다 — 그리는 자리 오른쪽에 끝 눈금 글 폭의 절반을 비워 끝 글이 차트 끝을 넘지 않는다. 축 수와 관계없다
//    (이중 축도). 끝 글을 안으로 당기지 않으므로 건너뛴 간격이 끝까지 고르다.
// ⓒ 세로 눈금이 겹치면 수를 줄인다 — 눈금 글 줄 높이(글자 크기를 따름)가 눈금 사이보다 크면 칸 수를 줄여 1 · 2 · 5 축을 다시
//    센다. 낮은 차트(폰 띠 140) · 글자 200% 에서도 세로 눈금 글이 겹치지 않고, 이중 축은 두 축 눈금이 같은 높이에 선다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget chart, {
  required double scale,
  double width = 312,
}) async {
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
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: chart),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(tester.takeException(), isNull);
}

/// [of] 안에서 [labels] 가운데 그려진 글의 자리(왼쪽부터).
List<({String text, Rect rect})> _shown(
  WidgetTester tester,
  Finder of,
  List<String> labels,
) {
  final out = <({String text, Rect rect})>[];
  for (final label in labels) {
    final f = find.descendant(of: of, matching: findText(label));
    if (f.evaluate().isEmpty) continue;
    out.add((text: label, rect: tester.getRect(f.first)));
  }
  out.sort((a, b) => a.rect.left.compareTo(b.rect.left));
  return out;
}

/// 차트 안 글 가운데 [exclude](가로 눈금)를 뺀 것 — 세로 눈금 글.
List<Rect> _valueTicks(WidgetTester tester, Finder of, Set<String> exclude) => [
  for (final e
      in find.descendant(of: of, matching: find.byType(Text)).evaluate())
    if (!exclude.contains(plainOf((e.widget as Text).data ?? '')))
      tester.getRect(find.byWidget(e.widget)),
];

void main() {
  // 긴 가로 눈금 글("2026. 12.") · 오른쪽 축은 짧은 글("0" ~ "10") — 끝 글 반 폭이 오른쪽 축 자리보다 넓은 가장 나쁜 값
  final cats = [for (var m = 1; m <= 12; m++) '2026. $m.'];
  PLineChart dual({double height = 200}) => PLineChart(
    label: '수입 · 지출',
    height: height,
    categories: cats,
    series: [
      PChartSeries(
        key: 'in',
        label: '수입',
        color: PChartColor.blue,
        values: [for (var i = 0; i < 12; i++) 1e6 + i * 2.5e5],
      ),
      PChartSeries(
        key: 'out',
        label: '지출',
        color: PChartColor.red,
        onRight: true,
        values: [for (var i = 0; i < 12; i++) (i % 9) + 1.0],
      ),
    ],
  );

  group('ⓐ 끝 글 자리 — 이중 축도 끝 글이 차트 끝을 넘지 않고 간격이 고르다', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('이중 축 · 글자 ${(scale * 100).round()}%', (tester) async {
        await _pump(tester, dual(), scale: scale);
        final chart = find.byType(PLineChart);
        final box = tester.getRect(chart);
        final shown = _shown(tester, chart, cats);
        expect(shown, isNotEmpty);
        expect(shown.last.text, cats.last, reason: '끝(가장 최근) 글은 늘 남는다');
        for (final s in shown) {
          expect(
            s.rect.right,
            lessThanOrEqualTo(box.right + 0.5),
            reason: '${s.text} 이 차트 끝(${box.right})을 넘는다 — ${s.rect}',
          );
        }
        // 보이는 글이 같은 칸 간격으로 선다 — 끝 글을 안으로 당기지 않는다
        final idx = [for (final s in shown) cats.indexOf(s.text)];
        final centers = [for (final s in shown) s.rect.center.dx];
        for (var k = 1; k < shown.length; k++) {
          expect(
            idx[k] - idx[k - 1],
            idx[1] - idx[0],
            reason: '건너뛴 칸 수가 고르다 $idx',
          );
          expect(
            centers[k] - centers[k - 1],
            moreOrLessEquals(centers[1] - centers[0], epsilon: 0.5),
            reason: '글 사이가 고르다 $centers',
          );
          expect(
            shown[k].rect.left - shown[k - 1].rect.right,
            greaterThanOrEqualTo(PSpacing.x2 - 0.5),
            reason: '글 사이 최소 8',
          );
        }
      });
    }

    testWidgets('축 하나 · 글이 하나만 들어가는 폭 — 끝 글 하나가 당기지 않고도 차트 안에 든다', (
      tester,
    ) async {
      await _pump(
        tester,
        PLineChart(
          label: '추이',
          height: 140,
          categories: cats,
          series: [
            PChartSeries(
              key: 'n',
              label: '순자산',
              color: PChartColor.blue,
              values: [for (var i = 0; i < 12; i++) -3e7 + i * 1e6],
            ),
          ],
        ),
        scale: 2,
      );
      final chart = find.byType(PLineChart);
      final box = tester.getRect(chart);
      final shown = _shown(tester, chart, cats);
      expect([for (final s in shown) s.text], [cats.last]);
      expect(shown.single.rect.right, lessThanOrEqualTo(box.right + 0.5));
    });
  });

  group('ⓒ 세로 눈금 — 높이 140 · 글자 200% 에서 겹치지 않는다', () {
    final single = PLineChart(
      label: '순자산',
      height: 140,
      categories: cats,
      series: [
        PChartSeries(
          key: 'n',
          label: '순자산',
          color: PChartColor.blue,
          values: [for (var i = 0; i < 12; i++) -2.1e7 + i * 4e6],
        ),
      ],
    );
    final bar = PBarChart(
      label: '순저축',
      height: 140,
      categories: cats,
      series: [
        PChartSeries(
          key: 's',
          label: '순저축',
          color: PChartColor.blue,
          values: [for (var i = 0; i < 12; i++) (i.isEven ? 1 : -1) * 3.3e5],
        ),
      ],
    );
    final cases = <String, (Widget, Type)>{
      '선 · 축 하나(음수 포함)': (single, PLineChart),
      '막대 · 음수 포함': (bar, PBarChart),
      '선 · 이중 축': (dual(height: 140), PLineChart),
    };
    for (final scale in [1.0, 2.0]) {
      for (final e in cases.entries) {
        testWidgets('${e.key} · 글자 ${(scale * 100).round()}%', (tester) async {
          await _pump(tester, e.value.$1, scale: scale);
          final chart = find.byType(e.value.$2);
          final box = tester.getRect(chart);
          final ticks = _valueTicks(tester, chart, cats.toSet());
          final left = [
            for (final r in ticks)
              if (r.center.dx < box.center.dx) r,
          ]..sort((a, b) => a.top.compareTo(b.top));
          final right = [
            for (final r in ticks)
              if (r.center.dx >= box.center.dx) r,
          ]..sort((a, b) => a.top.compareTo(b.top));
          expect(left.length, greaterThanOrEqualTo(2), reason: '세로 눈금이 남는다');
          for (final side in [left, right]) {
            for (var k = 1; k < side.length; k++) {
              expect(
                side[k].top,
                greaterThanOrEqualTo(side[k - 1].bottom - 0.5),
                reason: '세로 눈금 글 ${k - 1} · $k 가 겹친다 — $side',
              );
            }
          }
          if (right.isNotEmpty) {
            // 이중 축 — 두 축의 눈금이 같은 높이에 선다(0 을 맞춘 칸 수 그대로)
            expect(right.length, left.length);
            for (var k = 0; k < left.length; k++) {
              expect(
                right[k].center.dy,
                moreOrLessEquals(left[k].center.dy, epsilon: 0.5),
              );
            }
          }
          // 가로 눈금은 그대로 남는다(끝 글)
          expect(
            find.descendant(of: chart, matching: findText(cats.last)),
            findsOneWidget,
          );
        });
      }
    }
  });

  test('chartAxisMaxIntervals — ⌊그리는 높이 ÷ 줄 높이⌋, 적어도 1', () {
    // 높이 140 · 200%: 140 − 맨 위 8 − (눈금 줄 30 + 8) = 94 → 94 ÷ 30 = 3 칸
    expect(chartAxisMaxIntervals(94, 30), 3);
    expect(chartAxisMaxIntervals(90, 30), 3);
    expect(chartAxisMaxIntervals(20, 30), 1);
    // 100% 140: 140 − 8 − 23 = 109 → 7 칸(기본 4 칸 그대로)
    expect(chartAxisMaxIntervals(109, 15), 7);
    // 눈금 글 줄 높이는 글자 크기 설정을 따르지 않는다(chart.md "글자 크기", groo-design #260) — 늘 15
    final style = chartTickStyle(PColors.light);
    expect(chartTickLineHeight(style), moreOrLessEquals(15, epsilon: 0.01));
  });
}
