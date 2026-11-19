// 차트 그림 안 글 · 막대 위 값 바탕 — groo-design #260(chart.md "글자 크기", 사용자 결정) · #253.
//
// ⓐ 차트 그림 안 글(세로 · 가로 눈금 · 막대 위 값)은 글자 크기 설정을 따르지 않는다 — 그림 칸이 정해진 디자인 틀이다. 순자산
//    추이(높이 140 · 12달)가 iOS 접근성 최대 글자(약 312%) · 안드로이드 200% 에서도 100% 와 같은 눈금 글을 같은 자리에 그린다
//    — 50만 · 0 · −50만 이 겹치지 않는다(QA app_ios_ax5_asset_trend_overlap).
// ⓑ 막대 위 값 글 뒤에 카드 면 색 바탕(글 상자 크기) — 예산 100% 점선 · 격자가 글 뒤로 숨는다.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/android_font_scale.dart';
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
  required TextScaler scaler,
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
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
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
  group('ⓐ 차트 그림 안 글은 글자 크기를 따르지 않는다 — 큰 글자에서도 100% 와 같은 글 · 같은 자리', () {
    final scalers = <(String, TextScaler)>[
      ('iOS AX2(194%)', const TextScaler.linear(1.94)),
      ('300%', const TextScaler.linear(3)),
      ('iOS AX5(312%)', const TextScaler.linear(3.12)),
      ('안드로이드 200%', const AndroidNonlinearTextScaler()),
    ];
    for (final (data, values) in [
      ('음수 섞임(−1.2만 ~ 47.6만)', _mixed),
      ('양수만', _positive),
      ('음수 쪽이 큰 값(−47.6만 ~ 1.2만)', _negativeBig),
    ]) {
      for (final (name, scaler) in scalers) {
        testWidgets('$data · $name', (tester) async {
          await _pump(tester, _netWorth(values), scaler: TextScaler.noScaling);
          final base = _ticks(tester);
          final baseMonths = [
            for (final m in _months)
              if (findText(m).evaluate().isNotEmpty)
                (m, tester.getRect(findText(m))),
          ];
          await _pump(tester, _netWorth(values), scaler: scaler);
          final big = _ticks(tester);
          expect(
            [for (final t in big) t.text],
            [for (final t in base) t.text],
            reason: '세로 눈금 글이 100% 와 같다',
          );
          for (var k = 0; k < big.length; k++) {
            expect(big[k].rect, base[k].rect, reason: '"${big[k].text}" 자리');
          }
          _noOverlap(big);
          for (final (m, rect) in baseMonths) {
            expect(tester.getRect(findText(m)), rect, reason: '가로 눈금 "$m" 자리');
          }
          // 그려지는 글 모두 배율 없음
          for (final e
              in find
                  .descendant(
                    of: find.byType(PLineChart),
                    matching: find.byType(RichText),
                  )
                  .evaluate()) {
            expect(
              (e.renderObject! as RenderParagraph).textScaler,
              TextScaler.noScaling,
            );
          }
        });
      }
    }

    testWidgets('막대 위 값 — 312% 에서도 100% 와 같은 자리 · 같은 크기', (tester) async {
      Widget bars() => PBarChart(
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
      );
      await _pump(tester, bars(), scaler: TextScaler.noScaling);
      final base = [
        for (var i = 0; i < 6; i++)
          tester.getRect(find.byKey(ValueKey('chart-bar-label-bg-$i'))),
      ];
      await _pump(tester, bars(), scaler: const TextScaler.linear(3.12));
      for (var i = 0; i < 6; i++) {
        expect(
          tester.getRect(find.byKey(ValueKey('chart-bar-label-bg-$i'))),
          base[i],
        );
      }
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
          scaler: const TextScaler.linear(3.12),
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
