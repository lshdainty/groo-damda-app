// 차트 가로 눈금 — 글자가 커져도(textScale 1.0 / 1.3 / 2.0) 보이는 눈금 글끼리 겹치지 않는다(chart.yaml tickLabel,
// 2026-11-11 디자인시스템 판단 "커지면 축 폭을 다시 재고 가로 눈금은 겹치지 않게 건너뛴다"). 가장 나쁜 값 — 칸이 많고 글이 긴 축.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

Widget _host(Widget child, double scale) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 312, child: child),
      ),
    ),
  ),
);

PChartSeries _series(int n) => PChartSeries(
  key: 's',
  label: '값',
  color: PChartColor.blue,
  values: [for (var i = 1; i <= n; i++) i * 1000.0],
);

void main() {
  final cases = <String, List<String>>{
    '31칸 날짜': [for (var i = 1; i <= 31; i++) '10/$i'],
    '12칸 월': [for (var i = 1; i <= 12; i++) '$i월'],
    '12칸 긴 글': [
      for (var i = 1; i <= 12; i++) '2026.${i.toString().padLeft(2, '0')}월',
    ],
    '7칸 요일': ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'],
  };

  for (final bar in [false, true]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final e in cases.entries) {
        testWidgets(
          '${bar ? '막대' : '선'} · ${e.key} · 글자 ${(scale * 100).round()}% — 눈금 글이 겹치지 않는다',
          (tester) async {
            final cats = e.value;
            final series = [_series(cats.length)];
            await tester.pumpWidget(
              _host(
                bar
                    ? PBarChart(
                        label: '차트',
                        height: 180,
                        categories: cats,
                        series: series,
                      )
                    : PLineChart(
                        label: '차트',
                        height: 180,
                        categories: cats,
                        series: series,
                      ),
                scale,
              ),
            );
            await tester.pump(const Duration(seconds: 1));
            expect(tester.takeException(), isNull);
            final rects = <Rect>[];
            for (final c in cats) {
              final f = findText(c);
              if (f.evaluate().isEmpty) continue;
              rects.add(tester.getRect(f.first));
            }
            expect(rects, isNotEmpty);
            // 처음 글은 늘 남는다
            expect(findText(cats.first).evaluate(), isNotEmpty);
            rects.sort((a, b) => a.left.compareTo(b.left));
            for (var k = 1; k < rects.length; k++) {
              expect(
                rects[k].left,
                greaterThanOrEqualTo(rects[k - 1].right),
                reason: '눈금 글 ${k - 1} · $k 가 겹친다',
              );
            }
            // 차트 상자 밖으로 삐져나가지 않는다
            final box = tester.getRect(
              find.byType(bar ? PBarChart : PLineChart),
            );
            for (final r in rects) {
              expect(r.left, greaterThanOrEqualTo(box.left - 0.5));
              expect(r.right, lessThanOrEqualTo(box.right + 0.5));
            }
          },
        );
      }
    }
  }
}
