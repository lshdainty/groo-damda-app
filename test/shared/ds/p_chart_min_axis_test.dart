// 가장 적은 축 · 막대 위 값 바탕 — groo-design #253(chart.md "큰 글자", 사용자 결정).
//
// ⓐ 칸을 가장 적게 줄여도(0 을 품어야 하는 −50만 · 0 · 50만, 양수만이면 0 · 50만) 세로 글이 겹치면 절댓값이 큰 쪽 끝 글 하나를
//    남기고 0 은 함께 들어갈 때만 둔다. 나머지 글은 빼고 격자선 · 차트 높이는 그대로다. 순자산 추이(높이 140 · 12달)가 iOS
//    접근성 최대 글자(약 312%)에서 50만 · 0 · −50만 셋을 겹쳐 그리던 결함(QA app_ios_ax5_asset_trend_overlap).
// ⓑ 막대 위 값 글 뒤에 카드 면 색 바탕(글 상자 크기) — 예산 100% 점선 · 격자가 글 뒤로 숨는다.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/plain_text.dart';

final _months = [for (var m = 1; m <= 12; m++) '$m월'];

/// 순자산 추이 꼴 — 0 이 이어지다 9월에 살짝 음수(−12,000), 그 뒤 47.6만.
final _mixed = [
  for (var i = 0; i < 12; i++) i < 8 ? 0.0 : (i == 8 ? -12000.0 : 476000.0),
];
final _positive = [for (var i = 0; i < 12; i++) i < 9 ? 0.0 : 476000.0];

/// 같은 꼴의 음수 쪽이 큰 값 — 대출이 커진 순자산(−47.6만 ~ 1.2만).
final _negativeBig = [for (final v in _mixed) -v];

Future<void> _pump(
  WidgetTester tester,
  Widget chart, {
  required double scale,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(700, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light
          ? GrooTheme.light()
          : GrooTheme.dark(),
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
          child: SizedBox(width: 700, child: chart),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  expect(tester.takeException(), isNull);
}

/// 순자산 추이와 같은 차트 — 높이 140 · 선 + 점 · 채움 없음.
Widget _netWorth(List<double> values) => PLineChart(
  label: '순자산',
  height: 140,
  area: false,
  dots: true,
  categories: _months,
  series: [
    PChartSeries(
      key: 'n',
      label: '순자산',
      color: PChartColor.blue,
      values: values,
    ),
  ],
);

/// 세로 눈금 글(가로 눈금 달 글을 뺀 것) — 글과 자리.
List<({String text, Rect rect})> _ticks(WidgetTester tester) => [
  for (final e
      in find
          .descendant(of: find.byType(PLineChart), matching: find.byType(Text))
          .evaluate())
    if (!_months.contains(plainOf((e.widget as Text).data ?? '')))
      (
        text: plainOf((e.widget as Text).data ?? ''),
        rect: tester.getRect(find.byWidget(e.widget)),
      ),
];

void _noOverlap(List<({String text, Rect rect})> ticks) {
  final sorted = [...ticks]..sort((a, b) => a.rect.top.compareTo(b.rect.top));
  for (var k = 1; k < sorted.length; k++) {
    expect(
      sorted[k].rect.top,
      greaterThanOrEqualTo(sorted[k - 1].rect.bottom - 0.5),
      reason: '세로 눈금 글이 겹친다 — $sorted',
    );
  }
}

void main() {
  group('ⓐ 가장 적은 축도 들지 않으면 큰 쪽 끝 글만', () {
    // iOS AX3 235% · 300% · AX5 312% — 가장 적은 축(−50만 · 0 · 50만)도 그리는 높이에 들지 않는다
    for (final scale in [2.35, 3.0, 3.12]) {
      testWidgets(
        '음수 섞임(−1.2만 ~ 47.6만) · 글자 ${(scale * 100).round()}% → "50만" 만',
        (tester) async {
          await _pump(tester, _netWorth(_mixed), scale: scale);
          final ticks = _ticks(tester);
          _noOverlap(ticks);
          expect([for (final t in ticks) t.text], ['50만']);
          // 격자선은 그대로(−50만 · 0 · 50만 세 줄)
          final data = tester.widget<LineChart>(find.byType(LineChart)).data;
          expect(data.minY, -1);
          expect(data.maxY, 1);
          expect(data.gridData.show, isTrue);
          // 차트 높이는 그대로
          expect(tester.getSize(find.byType(PLineChart)).height, 140);
        },
      );
    }

    testWidgets('음수 쪽이 큰 값(−47.6만 ~ 1.2만) · 312% → "−50만" 만', (tester) async {
      await _pump(tester, _netWorth(_negativeBig), scale: 3.12);
      final ticks = _ticks(tester);
      _noOverlap(ticks);
      expect([for (final t in ticks) t.text], ['−50만']);
    });

    testWidgets('양수만 · 312%(0칸 — 0 · 50만 두 글이 겹친다) → "50만" 만', (tester) async {
      await _pump(tester, _netWorth(_positive), scale: 3.12);
      final ticks = _ticks(tester);
      _noOverlap(ticks);
      expect([for (final t in ticks) t.text], ['50만']);
    });

    testWidgets('양수만 · 300%(0 이 함께 들어간다) → "0 · 50만"', (tester) async {
      await _pump(tester, _netWorth(_positive), scale: 3);
      final ticks = _ticks(tester);
      _noOverlap(ticks);
      expect({for (final t in ticks) t.text}, {'0', '50만'});
    });

    testWidgets('iOS AX2(194%) — 셋이 들어가 줄이지 않는다(−50만 · 0 · 50만)', (
      tester,
    ) async {
      await _pump(tester, _netWorth(_mixed), scale: 1.94);
      final ticks = _ticks(tester);
      _noOverlap(ticks);
      expect({for (final t in ticks) t.text}, {'−50만', '0', '50만'});
    });
  });

  group('ⓑ 막대 위 값 글 뒤 카드 면 바탕', () {
    for (final brightness in Brightness.values) {
      testWidgets('예산 이행률 · AX5(312%) · ${brightness.name}', (tester) async {
        await _pump(
          tester,
          PBarChart(
            label: '이행률',
            height: 180,
            categories: const ['6월', '7월', '8월', '9월', '10월', '11월'],
            series: const [
              PChartSeries(
                key: 'r',
                label: '이행률',
                color: PChartColor.blue,
                values: [92, 98, 110, 64, 99, 87],
              ),
            ],
            showValueAxis: false,
            referenceLines: const [100],
            barLabel: (i, v) => '${v.round()}%',
            valueFormatter: (v) => '${v.round()}%',
          ),
          scale: 3.12,
          brightness: brightness,
        );
        final colors = brightness == Brightness.light
            ? PColors.light
            : PColors.dark;
        for (var i = 0; i < 6; i++) {
          final bg = find.byKey(ValueKey('chart-bar-label-bg-$i'));
          expect(bg, findsOneWidget, reason: '$i 번째 값 글 바탕');
          expect(
            tester.widget<ColoredBox>(bg).color,
            colors.bgLayerDefault,
            reason: '카드 면 색',
          );
          // 바탕은 글 상자 크기
          final text = find.descendant(of: bg, matching: find.byType(Text));
          expect(tester.getRect(bg), tester.getRect(text));
        }
      });
    }
  });
}
