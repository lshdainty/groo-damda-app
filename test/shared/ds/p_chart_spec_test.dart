// Chart 가 스펙 값(test/fixtures/design_spec/chart.json)대로인지 — 차트 10색 · 눈금 · 격자 · 선 · 막대 · 도넛 · 열지도 · 툴팁 · 지표
// 타일 · 도넛 범례를 라이트 · 다크로 잰다. 웹은 같은 JSON 을 크로미움에서 잰다. 앱에 없는 상태(hovered · focused — 웹 상태)와
// 웹 전용 값(cursor · transition 이름 · z-index)은 건너뛴다. 그림 안(격자 · 점 · 선)은 fl_chart 에 넘긴 데이터를 읽어 잰다.
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('chart');

Widget _host(
  Brightness mode,
  Widget child, {
  double width = 330,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

PColors _colors(Brightness mode) =>
    mode == Brightness.dark ? PColors.dark : PColors.light;

void _viewport(WidgetTester tester, [Size size = const Size(1000, 1200)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _expectColor(Object? want, Brightness mode, Color actual, String why) {
  expect(
    sameColor(specColor(pickMode(want, mode)), actual),
    isTrue,
    reason: '$why 기대 ${pickMode(want, mode)} 실제 ${colorHex(actual)}',
  );
}

Map<String, dynamic> _typo(Object? v) => (v as Map).cast<String, dynamic>();

/// 글의 크기 · 줄 높이(px) · 굵기 · 고정폭 숫자.
void _expectType(
  TextStyle style,
  Object? typography, {
  Object? weight,
  bool tabular = false,
  String? why,
}) {
  final t = _typo(typography);
  expect(style.fontSize, t['fontSize'], reason: '$why 크기');
  expect(
    style.fontSize! * style.height!,
    closeTo((t['lineHeight'] as num).toDouble(), 0.6),
    reason: '$why 줄 높이',
  );
  expect(style.fontWeight?.value, weight ?? t['fontWeight'], reason: '$why 굵기');
  if (tabular) {
    expect(
      style.fontFeatures,
      contains(const FontFeature.tabularFigures()),
      reason: '$why 고정폭 숫자',
    );
  }
}

TextStyle _style(WidgetTester tester, Finder f) =>
    tester.widget<Text>(f.first).style!;

Rect _rect(WidgetTester tester, Finder f) => tester.getRect(f.first);

const _days = ['1일', '2일', '3일', '4일', '5일', '6일', '7일', '8일'];

PLineChart _line({
  bool dual = false,
  Set<String> hidden = const {},
  List<String> categories = _days,
  List<double?>? income,
  List<double?>? expense,
}) => PLineChart(
  label: '10월 수입 · 지출 추이',
  description: '수입 4,441,000원 · 지출 321,700원',
  categories: categories,
  hidden: hidden,
  headFormatter: (c) => '10월 $c',
  series: [
    PChartSeries(
      key: 'income',
      label: '수입',
      color: PChartColor.blue,
      values: income ?? [0, 4200000, 0, 120000, 0, 35000, 0, 86000],
    ),
    PChartSeries(
      key: 'expense',
      label: '지출',
      color: PChartColor.red,
      onRight: dual,
      values:
          expense ?? [18000, 36000, 12000, 86400, 54000, 9800, 41000, 64500],
    ),
  ],
);

LineChartData _lineData(WidgetTester tester) =>
    tester.widget<LineChart>(find.byType(LineChart)).data;

BarChartData _barData(WidgetTester tester) =>
    tester.widget<BarChart>(find.byType(BarChart)).data;

void main() {
  // 글자 폭이 값을 정하는 자리(가운데 합계가 구멍에 들어가는지 · 지표 타일 줄바꿈)는 실제 글꼴로 잰다 — 기본 테스트 글꼴은 모든
  // 글자가 한 칸이라 폭이 다르다.
  setUpAll(() async {
    final loader = FontLoader('Pretendard')
      ..addFont(
        Future.value(
          ByteData.view(
            File(
              'assets/fonts/PretendardVariable.ttf',
            ).readAsBytesSync().buffer,
          ),
        ),
      );
    await loader.load();
  });

  group('값 · 숫자', () {
    test(
      '도넛 두께 — 지름 ÷ 10 + 6 을 정수로(Q-012-5): 160 → 22 · 120 → 18 · 112 → 17 · 176 → 24 · 180 → 24',
      () {
        for (final (d, t) in [
          (160.0, 22.0),
          (120.0, 18.0),
          (112.0, 17.0),
          (176.0, 24.0),
          (180.0, 24.0),
        ]) {
          expect(chartDonutThickness(d), t, reason: '지름 $d');
        }
      },
    );
    test('formatWon — 돈은 줄이지 않고 원까지, 빼기는 U+2212', () {
      expect(formatWon(0), '0원');
      expect(formatWon(1240000), '1,240,000원');
      expect(formatWon(-26140000), '−26,140,000원');
      expect(formatWon(133230000000), '133,230,000,000원');
      expect(formatWon(1234.5), '1,235원');
    });

    test('formatAxisWon — 1만 미만은 쉼표 정수, 그 위는 만 · 억 · 조 한 자리', () {
      expect(formatAxisWon(0), '0');
      expect(formatAxisWon(9999), '9,999');
      expect(formatAxisWon(10000), '1만');
      expect(formatAxisWon(12000), '1.2만');
      expect(formatAxisWon(4000000), '400만');
      expect(formatAxisWon(-30000000), '−3,000만');
      expect(formatAxisWon(100000000), '1억');
      expect(formatAxisWon(150000000), '1.5억');
      expect(formatAxisWon(99999000), '9,999.9만');
      expect(formatAxisWon(1000000000000), '1조');
      expect(formatAxisWon(double.nan), '');
      expect(formatAxisWon(-12000), '−1.2만');
    });

    test('눈금 — 0 은 늘 범위 안, 깔끔한 간격', () {
      final a = niceChartAxis(0, 4200000);
      expect(a.min, 0);
      expect(a.max, greaterThanOrEqualTo(4200000));
      expect(a.max / a.step, inInclusiveRange(3, 6), reason: '눈금 네 칸 안팎');
      final neg = niceChartAxis(-30000000, 10000000);
      expect(neg.min, lessThanOrEqualTo(-30000000));
      expect(neg.max, greaterThanOrEqualTo(10000000));
      expect(neg.min % neg.step, 0, reason: '0 에 눈금이 선다');
      final zero = niceChartAxis(0, 0);
      expect((zero.min, zero.max), (0, 10000));
      expect(niceChartAxis(0, 18000).max, greaterThanOrEqualTo(18000));
    });
  });

  group('색 배정', () {
    test('색 없는 항목은 배정 순서, 회색은 기타 전용', () {
      final out = assignChartColors<String>(['a', 'b', 'c']);
      expect(
        [for (final o in out) o.color],
        [PChartColor.blue, PChartColor.green, PChartColor.orange],
      );
      expect(kChartOrder, isNot(contains(PChartColor.gray)));
      expect(kChartOrder.length, 9);
    });

    test('저장된 색 먼저 — 같은 색이 두 번 나오지 않는다(저장된 빨강 · 색 없는 구독 · 의료)', () {
      final items = ['식비', '교통', '경조사', '구독', '의료', '쇼핑', '여가'];
      final out = assignChartColors<String>(
        items,
        colorOf: (s) => s == '경조사' ? PChartColor.red : null,
      );
      final colors = [for (final o in out) o.color];
      expect(colors.toSet().length, colors.length, reason: '색이 겹쳤다');
      expect(out[2].color, PChartColor.red);
      // 일곱째 색 순번(red)은 저장된 색이 가져가 색 없는 항목은 건너뛴다
      expect(colors.where((c) => c == PChartColor.red).length, 1);
      expect(colors[6], PChartColor.indigo);
    });

    test('10개를 넘으면 상위 9 + 회색 기타 — 회색은 기타에만', () {
      final items = [for (var i = 0; i < 12; i++) 'c$i'];
      final out = assignChartColors<String>(
        items,
        groupOthers: (rest) => '기타(${rest.length})',
      );
      expect(out.length, 10);
      expect(out.last.item, '기타(3)');
      expect(out.last.color, PChartColor.gray);
      expect(out.take(9).where((o) => o.color == PChartColor.gray), isEmpty);
    });

    test('정확히 10개는 그대로 — 열 번째에 색을 준다(기타로 묶지 않는다)', () {
      final out = assignChartColors<String>([for (var i = 0; i < 10; i++) 'c']);
      expect(out.length, 10);
    });
  });

  for (final mode in Brightness.values) {
    group('${mode.name} — 색', () {
      for (final color in PChartColor.values) {
        test('${color.name} — 계열 색은 스펙 값이다(라이트 700 · 다크 800-dark)', () {
          final want = _spec.resolve({'palette': color.name}, 'enabled');
          _expectColor(
            want['series.color'],
            mode,
            color.of(_colors(mode)),
            color.name,
          );
        });
      }
    });
  }

  for (final mode in Brightness.values) {
    final c = _colors(mode);

    testWidgets('${mode.name} — 툴팁 표면 · 머리 · 줄 · 네모가 스펙 값이다', (tester) async {
      final want = _spec.resolve({'kind': 'line', 'axis': 'single'}, 'enabled');
      await tester.pumpWidget(
        _host(
          mode,
          Align(
            alignment: Alignment.topLeft,
            child: PChartTooltip(
              head: '10월 8일 (목)',
              rows: [
                PChartTooltipRow(
                  swatch: c.chartBlue,
                  name: '수입',
                  value: '120,000원',
                ),
                PChartTooltipRow(
                  swatch: c.chartRed,
                  name: '지출',
                  value: '86,400원',
                ),
              ],
            ),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('chart-tooltip')),
      );
      final deco = box.decoration as BoxDecoration;
      final rect = _rect(tester, find.byKey(const ValueKey('chart-tooltip')));
      expect(rect.width, greaterThanOrEqualTo(want['tooltip.minWidth'] as num));
      expect(
        (deco.borderRadius as BorderRadius).topLeft.x,
        (want['tooltip.radius'] as num).toDouble(),
      );
      _expectColor(want['tooltip.background'], mode, deco.color!, '툴팁 바탕');
      expect(deco.border, isNull, reason: '테두리 없음');
      expect(
        listEquals(
          deco.boxShadow,
          tester.element(find.byType(PChartTooltip)).shadows.s3,
        ),
        isTrue,
        reason: '그림자는 s3',
      );
      // 안쪽 여백 위아래 10 · 좌우 12
      final head = _rect(
        tester,
        find.byKey(const ValueKey('chart-tooltip-head')),
      );
      expect(head.top - rect.top, want['tooltip.paddingY']);
      expect(head.left - rect.left, want['tooltip.paddingX']);
      final rows = find.byKey(const ValueKey('chart-tooltip-row'));
      final lastRow = tester.getRect(rows.last);
      expect(rect.bottom - lastRow.bottom, want['tooltip.paddingY']);
      expect(
        rect.right - tester.getRect(rows.first).right,
        want['tooltip.paddingX'],
      );
      // 머리 ↔ 줄 · 줄 사이 4
      expect(tester.getRect(rows.first).top - head.bottom, want['tooltip.gap']);
      expect(
        lastRow.top - tester.getRect(rows.first).bottom,
        want['tooltip.gap'],
      );
      // 머리 12 / 16 · fg-neutral-subtle
      final headStyle = _style(
        tester,
        find.byKey(const ValueKey('chart-tooltip-head')),
      );
      _expectType(headStyle, want['tooltipHead.typography'], why: '머리');
      _expectColor(
        want['tooltipHead.foreground'],
        mode,
        headStyle.color!,
        '머리 색',
      );
      // 줄 13 / 18 — 라벨 muted, 값 700 · fg-neutral · 고정폭
      final label = _style(
        tester,
        find.byKey(const ValueKey('chart-tooltip-label')),
      );
      _expectType(label, want['tooltipRow.typography'], why: '라벨');
      _expectColor(want['tooltipRow.foreground'], mode, label.color!, '라벨 색');
      final value = _style(
        tester,
        find.byKey(const ValueKey('chart-tooltip-value')),
      );
      _expectType(
        value,
        want['tooltipRow.typography'],
        weight: 700,
        tabular: true,
        why: '값',
      );
      expect(sameColor(c.fgNeutral, value.color!), isTrue);
      // 네모 8 · 모서리 2 · 네모 ↔ 라벨 6
      final sw = find.byKey(const ValueKey('chart-tooltip-swatch')).first;
      expect(
        tester.getSize(sw),
        Size.square((want['swatch.size'] as num).toDouble()),
      );
      final swDeco = tester.widget<Container>(sw).decoration as BoxDecoration;
      expect(
        (swDeco.borderRadius as BorderRadius).topLeft.x,
        want['swatch.radius'],
      );
      expect(swDeco.color, c.chartBlue);
      final labelRect = _rect(
        tester,
        find.byKey(const ValueKey('chart-tooltip-label')),
      );
      expect(labelRect.left - tester.getRect(sw).right, want['tooltipRow.gap']);
      // 값은 오른쪽 맞춤, 라벨 ↔ 값 12 이상
      final valueRect = _rect(
        tester,
        find.byKey(const ValueKey('chart-tooltip-value')),
      );
      expect(rect.right - 12 - valueRect.right, closeTo(0, 0.5));
      expect(valueRect.left - labelRect.right, greaterThanOrEqualTo(12));
    });

    testWidgets('${mode.name} — 지표 타일: 켠 · 끈 타일이 스펙 값이다', (tester) async {
      for (final legend in ['shown', 'hidden']) {
        final want = _spec.resolve({'legend': legend}, 'enabled');
        await tester.pumpWidget(
          _host(
            mode,
            PChartLegendTiles(
              hidden: legend == 'hidden' ? const {'red'} : const {},
              items: const [
                PChartLegendItem(
                  key: 'red',
                  label: '지출',
                  color: PChartColor.red,
                  total: '1,240,000원',
                ),
                PChartLegendItem(
                  key: 'blue',
                  label: '수입',
                  color: PChartColor.blue,
                  total: '4,200,000원',
                ),
              ],
            ),
          ),
        );
        final tile = find.byKey(const ValueKey('chart-legend-tile-red'));
        final deco = tester.widget<Container>(tile).decoration as BoxDecoration;
        final r = _rect(tester, tile);
        // 높이 62(10 + 18 + 2 + 22 + 10) · 폭 100 이상 · 모서리 12
        expect(r.height, 62, reason: '$legend 높이');
        expect(r.width, greaterThanOrEqualTo(100));
        expect(
          (deco.borderRadius as BorderRadius).topLeft.x,
          want['legendTile.radius'],
        );
        final tileBox = tester.widget<Container>(tile);
        if (legend == 'shown') {
          expect(
            deco.color,
            PChartColor.red.subtleOf(c),
            reason: '켠 타일은 옅은 바탕',
          );
          expect(deco.border, isNull);
          expect(tileBox.foregroundDecoration, isNull);
        } else {
          _expectColor(
            want['legendTile.background'],
            mode,
            deco.color!,
            '끈 타일 바탕',
          );
          final border =
              (tileBox.foregroundDecoration! as BoxDecoration).border!
                  as Border;
          expect(border.top.width, want['legendTile.borderWidth']);
          _expectColor(
            want['legendTile.borderColor'],
            mode,
            border.top.color,
            '끈 타일 테두리',
          );
          expect(border.top.strokeAlign, BorderSide.strokeAlignInside);
        }
        // 안쪽 여백 · 점 8 · 이름 13 / 18 muted · 합계 16 / 22 · 700
        final dot = find.byKey(const ValueKey('chart-legend-dot')).first;
        expect(tester.getSize(dot), const Size(8, 8));
        expect(
          (tester.widget<Container>(dot).decoration as BoxDecoration).color,
          c.chartRed,
        );
        final name = find.byKey(const ValueKey('chart-legend-name')).first;
        final nameStyle = _style(tester, name);
        _expectType(nameStyle, want['legendTile.typography'], why: '이름');
        _expectColor(
          want['legendTile.foreground'],
          mode,
          nameStyle.color!,
          '이름 색',
        );
        expect(_rect(tester, dot).left - r.left, want['legendTile.paddingX']);
        expect(_rect(tester, dot).top, greaterThan(r.top + 10));
        expect(_rect(tester, name).left - _rect(tester, dot).right, 6);
        final total = find.byKey(const ValueKey('chart-legend-total')).first;
        final totalStyle = _style(tester, total);
        _expectType(
          totalStyle,
          {'fontSize': 16, 'lineHeight': 22, 'fontWeight': 400},
          weight: 700,
          tabular: true,
          why: '합계',
        );
        expect(sameColor(c.fgNeutral, totalStyle.color!), isTrue);
        expect(_rect(tester, total).top - _rect(tester, name).bottom, 2);
        expect(
          r.bottom - _rect(tester, total).bottom,
          want['legendTile.paddingY'],
        );
        // 타일 사이 8
        final second = _rect(
          tester,
          find.byKey(const ValueKey('chart-legend-tile-blue')),
        );
        expect(second.left - r.right, want['legendTile.gap']);
      }
    });

    testWidgets('${mode.name} — 도넛 범례 줄이 스펙 값이다', (tester) async {
      final want = _spec.resolve({'kind': 'donut'}, 'enabled');
      await tester.pumpWidget(
        _host(
          mode,
          const PChartDonutLegend(
            items: [
              PChartDonutLegendItem(
                key: 'food',
                label: '식비',
                color: PChartColor.orange,
                percent: '41%',
                amount: '384,400원',
              ),
            ],
          ),
        ),
      );
      final row = _rect(tester, find.byKey(const ValueKey('chart-donut-row')));
      expect(
        row.height,
        greaterThanOrEqualTo(want['legendList.minHeight'] as num),
      );
      final label = _style(
        tester,
        find.byKey(const ValueKey('chart-donut-label')),
      );
      _expectType(label, want['legendList.typography'], why: '이름');
      expect(sameColor(c.fgNeutral, label.color!), isTrue);
      final pct = _style(
        tester,
        find.byKey(const ValueKey('chart-donut-percent')),
      );
      expect(sameColor(c.fgNeutralSubtle, pct.color!), isTrue);
      final amount = _style(
        tester,
        find.byKey(const ValueKey('chart-donut-amount')),
      );
      _expectType(
        amount,
        want['legendList.typography'],
        weight: 700,
        tabular: true,
        why: '금액',
      );
      final sw = find.byKey(const ValueKey('chart-donut-swatch'));
      expect(tester.getSize(sw), const Size(10, 10));
      final swDeco = tester.widget<Container>(sw).decoration as BoxDecoration;
      expect((swDeco.borderRadius as BorderRadius).topLeft.x, 2);
      expect(swDeco.color, c.chartOrange);
      // 칸 사이 8
      final amountRect = _rect(
        tester,
        find.byKey(const ValueKey('chart-donut-amount')),
      );
      final pctRect = _rect(
        tester,
        find.byKey(const ValueKey('chart-donut-percent')),
      );
      expect(amountRect.left - pctRect.right, want['legendList.gap']);
      expect(pctRect.left, greaterThan(row.left));
    });

    testWidgets('${mode.name} — 누르는 도넛 줄은 누르는 동안 누름 바탕(알약)이다', (tester) async {
      final want = _spec.resolve({'kind': 'donut'}, 'pressed');
      var taps = 0;
      await tester.pumpWidget(
        _host(
          mode,
          PChartDonutLegend(
            bleed: 24,
            items: [
              PChartDonutLegendItem(
                key: 'food',
                label: '식비',
                color: PChartColor.orange,
                percent: '41%',
                amount: '384,400원',
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      final pill = find.byKey(const ValueKey('chart-donut-pill'));
      Color pillColor() =>
          (tester.widget<AnimatedContainer>(pill).decoration as BoxDecoration)
              .color!;
      expect(pillColor().a, 0, reason: '쉬는 줄은 바탕이 없다');
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('chart-donut-row'))),
      );
      await tester.pump(const Duration(milliseconds: 200));
      _expectColor(want['legendList.background'], mode, pillColor(), '누름 바탕');
      expect(
        (tester.widget<AnimatedContainer>(pill).decoration as BoxDecoration)
            .borderRadius,
        BorderRadius.circular(10),
      );
      await g.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(pillColor().a, 0);
      // 카드 끝까지 — 줄은 부모 폭보다 24 씩 넓고, 알약은 그 안쪽 6
      final rowRect = tester.getRect(
        find.byKey(const ValueKey('chart-donut-pill')),
      );
      expect(rowRect.left, closeTo(-24 + 6, 0.5));
    });
  }

  for (final mode in Brightness.values) {
    final c = _colors(mode);

    testWidgets('${mode.name} — 선: 눈금 · 격자 · 선 · 면이 스펙 값이다', (tester) async {
      final want = _spec.resolve({'kind': 'line', 'axis': 'single'}, 'enabled');
      _viewport(tester);
      await tester.pumpWidget(_host(mode, _line(), width: 400));
      await tester.pump(const Duration(seconds: 1));
      final data = _lineData(tester);
      // 격자 — 가로 점선(3 · 3) 1px stroke-neutral-subtle, 세로 · 축 선 없음
      expect(data.gridData.drawVerticalLine, isFalse);
      expect(data.gridData.drawHorizontalLine, isTrue);
      final grid = data.gridData.getDrawingHorizontalLine(0);
      expect(grid.strokeWidth, want['gridLine.borderWidth']);
      expect(grid.dashArray, [3, 3]);
      _expectColor(want['gridLine.borderColor'], mode, grid.color!, '격자');
      expect(data.borderData.show, isFalse);
      // 선 2 · monotone · 점 없음 · 계열 색
      final bar = data.lineBarsData.first;
      expect(bar.barWidth, want['line.strokeWidth']);
      expect(bar.isCurved, isTrue);
      expect(bar.preventCurveOverShooting, isTrue);
      expect(bar.dotData.show, isFalse, reason: '점은 늘 찍어 두지 않는다');
      expect(bar.color, c.chartBlue);
      expect(data.lineBarsData.last.color, c.chartRed);
      // 면 — 같은 색 25% → 0% 세로 그라디언트
      final fill = bar.belowBarData.gradient! as LinearGradient;
      expect(fill.begin, Alignment.topCenter);
      expect(fill.end, Alignment.bottomCenter);
      expect(fill.colors.first.a, closeTo(0.25, 0.01));
      expect(fill.colors.last.a, 0);
      // 눈금 글자 11 / 15 · 고정폭 · fg-neutral-subtle(축 하나)
      final tick = _style(tester, findText('1일'));
      _expectType(tick, want['tickLabel.typography'], tabular: true, why: '눈금');
      _expectColor(want['tickLabel.foreground'], mode, tick.color!, '눈금 색');
      final yTick = _style(tester, findText('0'));
      _expectColor(want['tickLabel.foreground'], mode, yTick.color!, '세로 눈금 색');
    });

    testWidgets('${mode.name} — 이중 축: 눈금 글자가 그 축이 맡은 계열의 색이다', (tester) async {
      final want = _spec.resolve({'kind': 'line', 'axis': 'dual'}, 'enabled');
      expect(want['tickLabel.foreground'], 'chart-{계열 색}');
      _viewport(tester);
      await tester.pumpWidget(_host(mode, _line(dual: true), width: 400));
      await tester.pump(const Duration(seconds: 1));
      // 왼쪽 수입 blue · 오른쪽 지출 red · 가로축은 fg-neutral-subtle 그대로
      final zeros = findText('0');
      expect(zeros, findsNWidgets(2));
      final colors = {
        for (final z in zeros.evaluate())
          (z.widget as Text).style!.color!: tester
              .getTopLeft(find.byWidget(z.widget))
              .dx,
      };
      expect(colors.keys, containsAll([c.chartBlue, c.chartRed]));
      expect(colors[c.chartBlue]!, lessThan(colors[c.chartRed]!));
      _expectColor(
        want['tickLabel.foreground'] is String
            ? _spec.resolve({}, 'enabled')['tickLabel.foreground']
            : null,
        mode,
        _style(tester, findText('1일')).color!,
        '가로축',
      );
      // 두 축의 0 이 같은 자리 · 같은 칸 수 — 기울기가 서로 다른 크기를 같은 높이에 그린다
      expect(_lineData(tester).minY, 0);
    });

    testWidgets('${mode.name} — 가리킨 점 · 가리킴 선이 스펙 값이다', (tester) async {
      final want = _spec.resolve({'kind': 'line'}, 'enabled');
      _viewport(tester);
      await tester.pumpWidget(_host(mode, _line(), width: 400));
      await tester.pump(const Duration(seconds: 1));
      final bar = _lineData(tester).lineBarsData.first;
      final ind = _lineData(
        tester,
      ).lineTouchData.getTouchedSpotIndicator(bar, [0]).single!;
      // 선 — 세로 점선 1px stroke-neutral-weak
      expect(ind.indicatorBelowLine.strokeWidth, want['crosshair.borderWidth']);
      expect(ind.indicatorBelowLine.dashArray, [3, 3]);
      _expectColor(
        want['crosshair.borderColor'],
        mode,
        ind.indicatorBelowLine.color!,
        '가리킴 선',
      );
      // 점 — 계열 색 r 3 + 카드 면 색 테두리 2 = 바깥 지름 10
      final dot =
          ind.touchedSpotDotData.getDotPainter(const FlSpot(0, 0), 0, bar, 0)
              as FlDotCirclePainter;
      expect(
        dot!.getSize(const FlSpot(0, 0)),
        Size.square((want['point.size'] as num).toDouble()),
      );
      expect(dot.color, c.chartBlue);
      expect(dot.strokeColor, c.bgLayerDefault);
      expect(dot.strokeWidth, 2);
    });

    testWidgets('${mode.name} — 막대: 최대 폭 28 · 위 모서리 4 · 막대 사이 4, 음수는 아래 모서리', (
      tester,
    ) async {
      final want = _spec.resolve({'kind': 'bar'}, 'enabled');
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          mode,
          const PBarChart(
            label: '주별',
            categories: ['1주', '2주', '3주'],
            series: [
              PChartSeries(
                key: 'a',
                label: '수입',
                color: PChartColor.blue,
                values: [100000, -50000, 0],
              ),
              PChartSeries(
                key: 'b',
                label: '지출',
                color: PChartColor.red,
                values: [30000, 20000, null],
              ),
            ],
          ),
          width: 600,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final data = _barData(tester);
      final first = data.barGroups.first;
      expect(
        first.barRods.first.width,
        want['bar.maxWidth'],
        reason: '넓은 칸에서는 최대 폭',
      );
      expect(first.barsSpace, want['bar.gap']);
      expect(
        first.barRods.first.borderRadius,
        BorderRadius.vertical(
          top: Radius.circular((want['bar.radius'] as num).toDouble()),
        ),
      );
      expect(first.barRods.first.color, c.chartBlue);
      // 음수 막대 — 아래 두 모서리
      expect(
        data.barGroups[1].barRods.first.borderRadius,
        BorderRadius.vertical(
          bottom: Radius.circular((want['bar.radius'] as num).toDouble()),
        ),
      );
      expect(data.barGroups[1].barRods.first.toY, lessThan(0));
      // 값이 없는 계열 · 0 은 그리지 않는다(모서리 없음)
      expect(data.barGroups[2].barRods.last.toY, 0);
    });

    testWidgets('${mode.name} — 막대는 좁은 칸에서 최대 폭보다 가늘다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          mode,
          PBarChart(
            label: '일별',
            categories: [for (var i = 1; i <= 31; i++) '$i일'],
            series: [
              PChartSeries(
                key: 'a',
                label: '지출',
                color: PChartColor.red,
                values: [for (var i = 1; i <= 31; i++) i * 1000.0],
              ),
            ],
          ),
          width: 340,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final w = _barData(tester).barGroups.first.barRods.first.width;
      expect(w, lessThan(28));
      expect(w, greaterThan(0));
    });

    testWidgets('${mode.name} — 도넛: 두께 22 · 조각 사이 0 · 12시에서 시계 방향 · 가운데 합계', (
      tester,
    ) async {
      final want = _spec.resolve({'kind': 'donut'}, 'enabled');
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          mode,
          const PDonutChart(
            label: '10월 카테고리별 지출',
            centerLabel: '10월 지출',
            centerAmount: '1,240,000원',
            slices: [
              PDonutSlice(
                key: 'a',
                label: '식비',
                amount: 700,
                color: PChartColor.blue,
              ),
              PDonutSlice(
                key: 'b',
                label: '교통',
                amount: 300,
                color: PChartColor.green,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final pie = tester.widget<PieChart>(find.byType(PieChart)).data;
      // 두께는 지름 ÷ 10 + 6(정수) — 지름 160 에서 22(스펙 값이 문장이라 비율 · 더함 두 값으로 잰다)
      expect(
        pie.sections.first.radius,
        ((want['series.diameter'] as num) *
                    (want['series.thicknessPerDiameter'] as num) +
                (want['series.thicknessOffset'] as num))
            .round(),
      );
      expect(pie.sectionsSpace, 0);
      expect(pie.startDegreeOffset, -90, reason: '12시에서 시계 방향');
      expect(pie.centerSpaceRadius, 80 - 22);
      expect(pie.sections.first.color, c.chartBlue);
      expect(pie.sections.first.showTitle, isFalse);
      // 가운데 — 합계 16 / 22 · 700 · 고정폭, 위 라벨 12
      final amount = _style(
        tester,
        find.byKey(const ValueKey('chart-donut-center-amount')),
      );
      _expectType(
        amount,
        want['donutCenter.typography'],
        weight: want['donutCenter.fontWeight'],
        tabular: true,
        why: '합계',
      );
      _expectColor(want['donutCenter.foreground'], mode, amount.color!, '합계 색');
      final label = _style(
        tester,
        find.byKey(const ValueKey('chart-donut-center-label')),
      );
      expect(label.fontSize, 12);
      expect(sameColor(c.fgNeutralSubtle, label.color!), isTrue);
      // 폰 지름 120 은 두께 18
      await tester.pumpWidget(
        _host(
          mode,
          const PDonutChart(
            label: '폰',
            diameter: 120,
            slices: [
              PDonutSlice(
                key: 'a',
                label: '식비',
                amount: 1,
                color: PChartColor.blue,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widget<PieChart>(find.byType(PieChart))
            .data
            .sections
            .first
            .radius,
        18,
      );
    });

    testWidgets(
      '${mode.name} — 열지도: 글자 배율을 곱한 글이 칸보다 넓으면 칸 폭이 112 를 넘어도 글을 빼고 세기 색만 칠한다(03E-026b)',
      (tester) async {
        _viewport(tester, const Size(1200, 1000));
        const rows = [PHeatmapRow(key: 'am', label: '오전', sub: '6~12시')];
        const cols = [
          PHeatmapColumn(key: 'a', label: '일'),
          PHeatmapColumn(key: 'b', label: '월'),
          PHeatmapColumn(key: 'c', label: '화'),
          PHeatmapColumn(key: 'd', label: '수'),
          PHeatmapColumn(key: 'e', label: '목'),
          PHeatmapColumn(key: 'f', label: '금'),
          PHeatmapColumn(key: 'g', label: '토'),
        ];
        // 가장 나쁜 값 — 999억("99,999,999,999원" 100% 에서 107 이라 112 칸에 든다)
        const values = <List<double?>>[
          [50, 100, 300, 600, 900, 99999999999, 0],
        ];
        final cellText = find.descendant(
          of: find.byKey(const ValueKey('chart-heatmap-cell-0-5')),
          matching: find.byType(Text),
        );
        for (final scale in [1.0, 1.3, 2.0]) {
          await tester.pumpWidget(
            _host(
              mode,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: const PHeatmap(
                    label: '요일 · 시간대별 지출',
                    rows: rows,
                    columns: cols,
                    values: values,
                  ),
                ),
              ),
              width: 960,
            ),
          );
          await tester.pump();
          final cell = tester.getRect(
            find.byKey(const ValueKey('chart-heatmap-cell-0-5')),
          );
          expect(cell.width, greaterThanOrEqualTo(112), reason: '칸은 112 이상');
          expect(tester.takeException(), isNull, reason: 'x$scale 넘침 없음');
          if (scale == 1) {
            expect(cellText, findsOneWidget, reason: 'x$scale 글이 든다');
            expect(
              tester.getSize(cellText).width,
              lessThanOrEqualTo(cell.width - 4),
            );
          } else {
            expect(
              cellText,
              findsNothing,
              reason: 'x$scale 글이 칸보다 넓다 — 세기 색만(130% 139 · 200% 214)',
            );
          }
        }
      },
    );

    testWidgets(
      '${mode.name} — 열지도: 칸 정사각형 · 모서리 4 · 사이 6 · 세기 색 · 글자는 칸 폭 112 이상에서만',
      (tester) async {
        final want = _spec.resolve({'kind': 'heatmap'}, 'enabled');
        _viewport(tester, const Size(1200, 1000));
        const rows = [
          PHeatmapRow(key: 'am', label: '오전', sub: '6~12시'),
          PHeatmapRow(key: 'pm', label: '오후', sub: '12~18시'),
        ];
        const cols = [
          PHeatmapColumn(key: 'a', label: '일'),
          PHeatmapColumn(key: 'b', label: '월'),
          PHeatmapColumn(key: 'c', label: '화'),
          PHeatmapColumn(key: 'd', label: '수'),
          PHeatmapColumn(key: 'e', label: '목'),
          PHeatmapColumn(key: 'f', label: '금'),
          PHeatmapColumn(key: 'g', label: '토'),
        ];
        // 세기 다섯 단계 · 값 없음 · 가장 큰 칸 — 최댓값 1000 의 8 · 22 · 45 · 75%
        const values = <List<double?>>[
          [50, 100, 300, 600, 900, 1000, 0],
          [null, 79.9, 80, 219, 220, 449, 450],
        ];
        Future<void> pump(double width) async {
          await tester.pumpWidget(
            _host(
              mode,
              const PHeatmap(
                label: '요일 · 시간대별 지출',
                rows: rows,
                columns: cols,
                values: values,
              ),
              width: width,
            ),
          );
          await tester.pump();
        }

        // 넓은 칸(폭 960 → 칸 112 이상) — 금액이 보인다
        await pump(960);
        final first = find.byKey(const ValueKey('chart-heatmap-cell-0-0'));
        final cell = tester.getRect(first);
        expect(cell.width, cell.height, reason: '정사각형');
        expect(
          cell.width,
          greaterThanOrEqualTo(want['heatmapValue.threshold'] as num),
        );
        expect(cell.width, closeTo((960 - 56 - 6 * 7) / 7, 0.01));
        final cell2 = tester.getRect(
          find.byKey(const ValueKey('chart-heatmap-cell-0-1')),
        );
        expect(
          cell2.left - cell.right,
          want['heatmapCell.gap'],
          reason: '칸 사이 6',
        );
        final below = tester.getRect(
          find.byKey(const ValueKey('chart-heatmap-cell-1-0')),
        );
        expect(below.top - cell.bottom, 6, reason: '세로도 6');
        expect(cell.left, 56 + 6, reason: '시간대 라벨 열 56 + 사이 6');
        final deco =
            tester
                    .widget<Container>(
                      find.descendant(
                        of: first,
                        matching: find.byType(Container),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        expect(
          (deco.borderRadius as BorderRadius).topLeft.x,
          want['heatmapCell.radius'],
        );
        // 세기 색 — 브랜드 채움을 카드 면에 18 · 35 · 55 · 76 · 100% 섞는다(넷째는 75 → 76, 2026-10-22 #187)
        Color bg(int r, int col) =>
            (tester
                        .widget<Container>(
                          find.descendant(
                            of: find.byKey(
                              ValueKey('chart-heatmap-cell-$r-$col'),
                            ),
                            matching: find.byType(Container),
                          ),
                        )
                        .decoration
                    as BoxDecoration)
                .color!;
        final steps = [for (var i = 0; i < 5; i++) heatStepColor(c, i)];
        expect(kHeatMix, [0.18, 0.35, 0.55, 0.76, 1], reason: '넷째 세기 76%');
        // 라이트 76% 칸 위 흰 글자는 4.5 를 넘는다(스펙 note 4.74)
        if (mode == Brightness.light) {
          double lum(Color x) {
            double ch(double v) => v <= 0.03928
                ? v / 12.92
                : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
            return 0.2126 * ch(x.r) + 0.7152 * ch(x.g) + 0.0722 * ch(x.b);
          }

          final bgL = lum(steps[3]);
          final fgL = lum(c.staticWhite);
          final ratio = (fgL + 0.05) / (bgL + 0.05);
          expect(ratio, greaterThan(4.5), reason: '76% 칸 위 흰 글자 $ratio');
          expect(ratio, closeTo(4.74, 0.05));
        }
        expect(bg(0, 0), steps[0], reason: '50 / 1000 = 5% → 0 단계');
        expect(bg(0, 1), steps[1], reason: '100 → 10%');
        expect(bg(0, 2), steps[2], reason: '300 → 30%');
        expect(bg(0, 3), steps[3], reason: '600 → 60%');
        expect(bg(0, 5), steps[4], reason: '가장 큰 칸');
        expect(bg(1, 0), c.bgNeutralWeak, reason: '값 없음');
        expect(bg(0, 6), c.bgNeutralWeak, reason: '0 은 값 없음');
        // 끊는 자리 8 · 22 · 45 · 75% 는 경계에서 다음 단계
        expect(heatStep(79.9, 1000), 0);
        expect(heatStep(80, 1000), 1);
        expect(heatStep(219, 1000), 1);
        expect(heatStep(220, 1000), 2);
        expect(heatStep(449, 1000), 2);
        expect(heatStep(450, 1000), 3);
        expect(heatStep(749, 1000), 3);
        expect(heatStep(750, 1000), 4);
        expect(heatStep(0, 1000), -1);
        expect(heatStep(null, 1000), -1);
        expect(heatStep(5, 0), -1);
        // 가장 큰 칸에 고리 없음
        expect(
          (tester
                      .widget<Container>(
                        find.descendant(
                          of: find.byKey(
                            const ValueKey('chart-heatmap-cell-0-5'),
                          ),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .border,
          isNull,
        );
        // 금액 — 11 / 15 · 700 · 고정폭, 글자색은 단계마다
        final texts = heatTextColors(c);
        final cellText = tester.widget<Text>(
          find.descendant(of: first, matching: find.byType(Text)),
        );
        expect(cellText.data, '50원');
        _expectType(
          cellText.style!,
          want['heatmapValue.typography'],
          weight: want['heatmapValue.fontWeight'],
          tabular: true,
          why: '칸 금액',
        );
        expect(cellText.style!.color, texts[0]);
        final top = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('chart-heatmap-cell-0-5')),
            matching: find.byType(Text),
          ),
        );
        expect(top.style!.color, texts[4]);
        final none = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('chart-heatmap-cell-1-0')),
            matching: find.byType(Text),
          ),
        );
        expect(none.data, '—');
        expect(sameColor(c.fgNeutralSubtle, none.style!.color!), isTrue);
        // 라이트는 76 · 100% 만 흰 글자, 다크는 전부 fg-neutral
        if (mode == Brightness.light) {
          expect(texts, [
            c.fgNeutral,
            c.fgNeutral,
            c.fgNeutral,
            c.staticWhite,
            c.staticWhite,
          ]);
        } else {
          expect(texts, everyElement(c.fgNeutral));
        }
        // 좁은 칸(폰) — 글 없이 세기 색만
        await pump(292);
        expect(tester.getRect(first).width, lessThan(112));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('chart-heatmap-cell-0-0')),
            matching: find.byType(Text),
          ),
          findsNothing,
        );
        expect(bg(0, 5), steps[4], reason: '색은 그대로');
      },
    );
  }

  group('동작', () {
    testWidgets('차트를 누르면 툴팁이 뜨고, 손을 떼도 남고, 다른 곳을 누르면 닫힌다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: [
              _line(),
              const SizedBox(height: 100, child: Text('바깥')),
            ],
          ),
          width: 400,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('chart-tooltip')), findsNothing);
      final chart = tester.getRect(find.byType(LineChart));
      // 왼쪽 끝 근처 — 첫 날짜
      await tester.tapAt(Offset(chart.left + 45, chart.center.dy));
      await tester.pump();
      expect(find.byKey(const ValueKey('chart-tooltip')), findsOneWidget);
      expect(findText('10월 1일'), findsOneWidget, reason: '머리');
      expect(findText('수입'), findsOneWidget);
      expect(findText('지출'), findsOneWidget);
      expect(findText('0원'), findsOneWidget);
      expect(findText('18,000원'), findsOneWidget);
      // 가리킨 점 — 지금 가리킨 자리가 데이터에 실린다
      expect(_lineData(tester).lineBarsData.first.showingIndicators, [0]);
      // 오른쪽 끝 — 다른 날짜로 옮긴다
      await tester.tapAt(Offset(chart.right - 20, chart.center.dy));
      await tester.pump();
      expect(findText('10월 8일'), findsOneWidget);
      expect(findText('64,500원'), findsOneWidget);
      // 손을 뗀 뒤에도 남는다
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const ValueKey('chart-tooltip')), findsOneWidget);
      // 다른 곳을 누르면 닫힌다
      await tester.tap(findText('바깥'));
      await tester.pump();
      expect(find.byKey(const ValueKey('chart-tooltip')), findsNothing);
      expect(_lineData(tester).lineBarsData.first.showingIndicators, isEmpty);
    });

    testWidgets('막대를 누르면 툴팁과 가리킴 선이 선다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PBarChart(
            label: '주별',
            categories: ['1주', '2주', '3주', '4주'],
            series: [
              PChartSeries(
                key: 'a',
                label: '수입',
                color: PChartColor.blue,
                values: [4200000, 0, 120000, 86000],
              ),
              PChartSeries(
                key: 'b',
                label: '지출',
                color: PChartColor.red,
                values: [310000, 450000, 280000, 200000],
              ),
            ],
          ),
          width: 400,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final chart = tester.getRect(find.byType(BarChart));
      await tester.tapAt(Offset(chart.left + 120, chart.center.dy));
      await tester.pump();
      expect(find.byKey(const ValueKey('chart-tooltip')), findsOneWidget);
      expect(find.byKey(const ValueKey('chart-crosshair')), findsOneWidget);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('chart-crosshair')),
                  )
                  .painter!
              as PChartCrosshairPainter;
      expect(painter.color, PColors.light.strokeNeutralWeak);
    });

    testWidgets('지표 타일을 누르면 계열이 꺼지고 켜진다 — 마지막 하나는 끌 수 없다', (tester) async {
      var hidden = <String>{};
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return PChartLegendTiles(
                hidden: hidden,
                onHiddenChanged: (h) => setState(() => hidden = h),
                items: const [
                  PChartLegendItem(
                    key: 'income',
                    label: '수입',
                    color: PChartColor.blue,
                    total: '1원',
                  ),
                  PChartLegendItem(
                    key: 'expense',
                    label: '지출',
                    color: PChartColor.red,
                    total: '2원',
                  ),
                ],
              );
            },
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      final income = find.byKey(const ValueKey('chart-legend-tile-income'));
      final expense = find.byKey(const ValueKey('chart-legend-tile-expense'));
      expect(tester.getSemantics(income), isNotNull);
      await tester.tap(expense);
      await tester.pump();
      expect(hidden, {'expense'});
      // 남은 하나(수입)는 잠긴다 — 눌러도 그대로
      await tester.tap(income);
      await tester.pump();
      expect(hidden, {'expense'});
      final sem = tester.getSemantics(income);
      expect(
        sem.flagsCollection.isEnabled,
        ui.Tristate.isFalse,
        reason: '잠긴 타일은 막힌 버튼으로 읽힌다',
      );
      // 끈 타일을 다시 누르면 켠다
      await tester.tap(expense);
      await tester.pump();
      expect(hidden, isEmpty);
      set(() {});
      handle.dispose();
    });

    testWidgets(
      '지표 타일 누름 — 2px 거리 축소(기준 = max(높이, 폭 ÷ 4, 24)), 모션 줄이기면 하지 않는다',
      (tester) async {
        for (final reduce in [false, true]) {
          await tester.pumpWidget(
            _host(
              Brightness.light,
              const PChartLegendTiles(
                items: [
                  PChartLegendItem(
                    key: 'a',
                    label: '수입',
                    color: PChartColor.blue,
                    total: '1원',
                  ),
                  PChartLegendItem(
                    key: 'b',
                    label: '지출',
                    color: PChartColor.red,
                    total: '2원',
                  ),
                ],
              ),
              reduceMotion: reduce,
            ),
          );
          final tile = find.byKey(const ValueKey('chart-legend-tile-b'));
          final g = await tester.startGesture(tester.getCenter(tile));
          await tester.pump(const Duration(milliseconds: 200));
          final scale = tester
              .widget<AnimatedScale>(
                find
                    .ancestor(of: tile, matching: find.byType(AnimatedScale))
                    .first,
              )
              .scale;
          if (reduce) {
            expect(scale, 1);
          } else {
            final h = tester.getSize(tile).height;
            final w = tester.getSize(tile).width;
            final basis = [h, w / 4, 24.0].reduce((a, b) => a > b ? a : b);
            expect(scale, closeTo((basis - 2) / basis, 1e-6));
          }
          await g.up();
          await tester.pump();
        }
      },
    );

    testWidgets('도넛 조각을 누르면 "■ 라벨 값" 툴팁이 뜬다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PDonutChart(
            label: '10월 카테고리별 지출',
            slices: [
              PDonutSlice(
                key: 'a',
                label: '식비',
                amount: 700000,
                color: PChartColor.blue,
              ),
              PDonutSlice(
                key: 'b',
                label: '교통',
                amount: 300000,
                color: PChartColor.green,
              ),
            ],
          ),
          width: 330,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final pie = tester.getRect(find.byKey(const ValueKey('chart-donut')));
      // 오른쪽 가장자리 — 시계 방향 처음 조각(식비)
      await tester.tapAt(Offset(pie.right - 10, pie.center.dy));
      await tester.pump();
      expect(find.byKey(const ValueKey('chart-tooltip')), findsOneWidget);
      expect(findText('식비'), findsOneWidget);
      expect(findText('700,000원'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chart-tooltip-head')),
        findsNothing,
        reason: '도넛 툴팁은 머리가 없다',
      );
      // 구멍을 누르면 닫는다
      await tester.tapAt(pie.center);
      await tester.pump();
      expect(find.byKey(const ValueKey('chart-tooltip')), findsNothing);
    });

    testWidgets('도넛 가운데 합계가 구멍에 안 들어가면 가운데 글을 빼고 알린다(줄이지 않는다)', (tester) async {
      _viewport(tester);
      final fits = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PDonutChart(
            label: '큰 합계',
            diameter: 120,
            centerLabel: '10월 지출',
            centerAmount: '927,400,000,000원',
            onFitChanged: fits.add,
            slices: const [
              PDonutSlice(
                key: 'a',
                label: '식비',
                amount: 1,
                color: PChartColor.blue,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(fits, [false]);
      expect(find.byKey(const ValueKey('chart-donut-center')), findsNothing);
      // 작은 합계는 들어간다 — 알리지 않는다
      fits.clear();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PDonutChart(
            key: UniqueKey(),
            label: '작은 합계',
            diameter: 160,
            centerLabel: '10월 지출',
            centerAmount: '1,240,000원',
            onFitChanged: fits.add,
            slices: const [
              PDonutSlice(
                key: 'a',
                label: '식비',
                amount: 1,
                color: PChartColor.blue,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(fits, isEmpty);
      expect(
        find.byKey(const ValueKey('chart-donut-center-amount')),
        findsOneWidget,
      );
    });

    testWidgets('열지도 칸을 누르면 툴팁(머리 · ■ 지출 값 · 세기 색 네모)이 뜨고 다른 곳을 누르면 닫힌다', (
      tester,
    ) async {
      _viewport(tester);
      final c = PColors.light;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: [
              PHeatmap(
                label: '요일 · 시간대별 지출',
                rows: const [
                  PHeatmapRow(key: 'r0', label: '새벽', sub: '0~6시'),
                  PHeatmapRow(key: 'r1', label: '오전', sub: '6~12시'),
                  PHeatmapRow(key: 'r2', label: '오후', sub: '12~18시'),
                  PHeatmapRow(key: 'r3', label: '밤', sub: '22~24시'),
                  PHeatmapRow(key: 'eve', label: '저녁', sub: '18~22시'),
                ],
                columns: const [
                  PHeatmapColumn(key: 'a', label: '수'),
                  PHeatmapColumn(key: 'b', label: '목'),
                ],
                values: const [
                  [0, 0],
                  [0, 0],
                  [0, 0],
                  [0, 0],
                  [35000, 340000],
                ],
                tooltipLabel: (r, col) => '${col.label}요일 ${r.label} ${r.sub}',
              ),
              const SizedBox(height: 200, child: Text('바깥')),
            ],
          ),
          width: 330,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('chart-heatmap-cell-4-0')));
      await tester.pump();
      expect(findText('수요일 저녁 18~22시'), findsOneWidget);
      expect(findText('지출'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chart-tooltip')),
          matching: findText('35,000원'),
        ),
        findsOneWidget,
      );
      final swatch = tester.widget<Container>(
        find.byKey(const ValueKey('chart-tooltip-swatch')),
      );
      expect(
        (swatch.decoration as BoxDecoration).color,
        heatStepColor(c, 1),
        reason: '35,000 / 340,000 = 10% → 1 단계',
      );
      // 툴팁은 칸 위에 뜬다(위에 자리가 모자라면 아래 — 첫 줄)
      final tip = tester.getRect(find.byKey(const ValueKey('chart-tooltip')));
      final cell = tester.getRect(
        find.byKey(const ValueKey('chart-heatmap-cell-4-0')),
      );
      expect(tip.bottom, lessThanOrEqualTo(cell.top));
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.byKey(const ValueKey('chart-tooltip')),
        findsOneWidget,
        reason: '손을 떼도 남는다',
      );
      await tester.tap(findText('바깥'));
      await tester.pump();
      expect(find.byKey(const ValueKey('chart-tooltip')), findsNothing);
    });

    testWidgets(
      '열지도 툴팁은 화면 기준으로 뒤집힌다 — 차트 위에 화면 자리가 있으면 첫 줄도 위, 화면 맨 위면 아래(Q-012-6)',
      (tester) async {
        _viewport(tester);
        Widget heat({double above = 0}) => _host(
          Brightness.light,
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: above),
                const PHeatmap(
                  label: '요일 · 시간대별 지출',
                  rows: [PHeatmapRow(key: 'r0', label: '새벽', sub: '0~6시')],
                  columns: [
                    PHeatmapColumn(key: 'a', label: '수'),
                    PHeatmapColumn(key: 'b', label: '목'),
                  ],
                  values: [
                    [35000, 340000],
                  ],
                ),
              ],
            ),
          ),
          width: 330,
        );
        final cellFinder = find.byKey(const ValueKey('chart-heatmap-cell-0-0'));
        final tipFinder = find.byKey(const ValueKey('chart-tooltip'));
        // 차트 위에 화면 자리가 120 — 첫 줄이어도 칸 위에 뜬다
        await tester.pumpWidget(heat(above: 120));
        await tester.tap(cellFinder);
        await tester.pump();
        var tip = tester.getRect(tipFinder);
        var cell = tester.getRect(cellFinder);
        expect(tip.bottom, cell.top - 8, reason: '칸 위 8');
        expect(tip.top, greaterThanOrEqualTo(8), reason: '화면 가장자리 8');
        await tester.tapAt(const Offset(1, 1));
        await tester.pump();
        expect(tipFinder, findsNothing);
        // 화면 맨 위 — 위에 8 이 안 남아 아래로 뒤집힌다
        await tester.pumpWidget(heat());
        await tester.tap(cellFinder);
        await tester.pump();
        tip = tester.getRect(tipFinder);
        cell = tester.getRect(cellFinder);
        expect(tip.top, greaterThan(cell.top), reason: '아래로 뒤집힘');
        expect(tip.top, cell.top + 8);
      },
    );

    testWidgets('값 없는 열지도 칸의 툴팁은 "없음"', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PHeatmap(
            label: '지출',
            rows: [PHeatmapRow(key: 'a', label: '밤')],
            columns: [
              PHeatmapColumn(key: 'a', label: '월'),
              PHeatmapColumn(key: 'b', label: '화'),
            ],
            values: [
              [null, 100],
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('chart-heatmap-cell-0-0')));
      await tester.pump();
      expect(findText('없음'), findsOneWidget);
      expect(findText('월 밤'), findsOneWidget);
    });
  });

  group('접근성', () {
    testWidgets('차트 상자는 요약 이름 · 대체 글을 갖고 안의 그림은 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      _viewport(tester);
      await tester.pumpWidget(_host(Brightness.light, _line(), width: 400));
      await tester.pump(const Duration(seconds: 1));
      expect(find.bySemanticsLabel('10월 수입 · 지출 추이'), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('10월 수입 · 지출 추이'));
      expect(node.value, '수입 4,441,000원 · 지출 321,700원');
      expect(node.flagsCollection.isImage, isTrue);
      // 눈금 글자 · 툴팁이 따로 읽히지 않는다
      expect(find.bySemanticsLabel('200만'), findsNothing);
      await tester.tapAt(tester.getRect(find.byType(LineChart)).center);
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('원')),
        findsNothing,
        reason: '툴팁은 보조 기술에서 뺀다',
      );
      handle.dispose();
    });

    testWidgets('열지도 · 도넛도 요약 이름을 갖는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const Column(
            children: [
              PHeatmap(
                label: '10월 요일 · 시간대별 지출, 가장 많은 때 토요일 저녁',
                rows: [PHeatmapRow(key: 'a', label: '밤')],
                columns: [PHeatmapColumn(key: 'a', label: '월')],
                values: [
                  [1],
                ],
              ),
              PDonutChart(
                label: '10월 카테고리별 지출',
                slices: [
                  PDonutSlice(
                    key: 'a',
                    label: '식비',
                    amount: 1,
                    color: PChartColor.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.bySemanticsLabel('10월 요일 · 시간대별 지출, 가장 많은 때 토요일 저녁'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('10월 카테고리별 지출'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('지표 타일은 눌림 상태(켬 · 끔)로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PChartLegendTiles(
            hidden: {'b'},
            items: [
              PChartLegendItem(
                key: 'a',
                label: '수입',
                color: PChartColor.blue,
                total: '1원',
              ),
              PChartLegendItem(
                key: 'b',
                label: '지출',
                color: PChartColor.red,
                total: '2원',
              ),
            ],
          ),
        ),
      );
      final on = tester.getSemantics(
        find.byKey(const ValueKey('chart-legend-tile-a')),
      );
      final off = tester.getSemantics(
        find.byKey(const ValueKey('chart-legend-tile-b')),
      );
      expect(on.flagsCollection.isButton, isTrue);
      expect(on.flagsCollection.isToggled, ui.Tristate.isTrue);
      expect(off.flagsCollection.isToggled, ui.Tristate.isFalse);
      expect(find.bySemanticsLabel('범례'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('표로 보기 — 숨긴 표는 줄마다 읽히고, 펼친 표는 보인다', (tester) async {
      final handle = tester.ensureSemantics();
      const columns = [
        PChartDataColumn('날짜'),
        PChartDataColumn('수입'),
        PChartDataColumn('지출'),
      ];
      const rows = [
        ['10월 1일', '0원', '18,000원'],
        ['10월 2일', '4,200,000원', '36,000원'],
      ];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PChartDataTable(
            caption: '10월 날짜별 수입 · 지출',
            columns: columns,
            rows: rows,
          ),
        ),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel('10월 날짜별 수입 · 지출'),
      );
      expect(node.value, contains('10월 2일, 수입 4,200,000원, 지출 36,000원'));
      expect(
        tester.getSize(find.byKey(const ValueKey('chart-data-table'))).height,
        0,
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PChartDataTable(
            visuallyHidden: false,
            caption: '10월 날짜별 수입 · 지출',
            columns: columns,
            rows: rows,
          ),
        ),
      );
      expect(findText('4,200,000원'), findsOneWidget);
      expect(findText('날짜'), findsOneWidget);
      // 첫 열은 왼쪽 · 나머지는 오른쪽(숫자)
      expect(
        tester.getTopLeft(findText('10월 1일')).dx,
        lessThan(tester.getTopLeft(findText('18,000원')).dx),
      );
      handle.dispose();
    });
  });

  group('모션', () {
    testWidgets('선은 처음 한 번 300ms 에 걸쳐 그려지고, 모션 줄이기면 바로 그린다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_host(Brightness.light, _line(), width: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate((w) => w is ClipRect && w.clipper != null),
        findsOneWidget,
        reason: '그리는 중 — 가로로 드러난다',
      );
      await tester.pump(const Duration(milliseconds: 250));
      // 다 그려진 뒤에는 늘 1
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is ClipRect && w.clipper != null),
        findsNothing,
      );
      // 모션 줄이기 — 첫 프레임부터 다 그려져 있다
      await tester.pumpWidget(
        _host(Brightness.light, _line(), width: 400, reduceMotion: true),
      );
      await tester.pump();
      expect(
        find.byWidgetPredicate((w) => w is ClipRect && w.clipper != null),
        findsNothing,
      );
    });

    testWidgets('막대는 높이가 0 에서 자란다 — 모션 줄이기면 바로 자란 모습', (tester) async {
      _viewport(tester);
      Widget bars({bool reduce = false}) => _host(
        Brightness.light,
        const PBarChart(
          label: '주별',
          categories: ['1주', '2주'],
          series: [
            PChartSeries(
              key: 'a',
              label: '지출',
              color: PChartColor.red,
              values: [100000, 200000],
            ),
          ],
        ),
        width: 400,
        reduceMotion: reduce,
      );
      await tester.pumpWidget(bars());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = _barData(tester).barGroups.last.barRods.first.toY;
      await tester.pumpAndSettle();
      final full = _barData(tester).barGroups.last.barRods.first.toY;
      expect(mid, lessThan(full));
      expect(mid, greaterThan(0));
      await tester.pumpWidget(bars(reduce: true));
      await tester.pump();
      expect(_barData(tester).barGroups.last.barRods.first.toY, full);
    });
  });

  group('가장 나쁜 값', () {
    for (final mode in Brightness.values) {
      testWidgets(
        '${mode.name} · 폭 360 — 데이터 1개 · 모두 0 · 음수 · 1억 넘는 금액 · 항목 12개 · 빈 데이터가 깨지지 않는다',
        (tester) async {
          _viewport(tester, const Size(360, 3000));
          Widget col(List<Widget> children) =>
              SingleChildScrollView(child: Column(children: children));
          await tester.pumpWidget(
            _host(
              mode,
              col([
                _line(
                  categories: const ['1일'],
                  income: const [0],
                  expense: const [18000],
                ),
                _line(income: List.filled(8, 0), expense: List.filled(8, 0)),
                _line(
                  dual: true,
                  income: [
                    for (final v in [
                      0.0,
                      4200000,
                      0,
                      120000,
                      0,
                      35000,
                      0,
                      86000,
                    ])
                      v * 30,
                  ],
                  expense: [
                    for (final v in [
                      18000.0,
                      36000,
                      12000,
                      86400,
                      54000,
                      9800,
                      41000,
                      64500,
                    ])
                      v * 1400,
                  ],
                ),
                _line(
                  income: const [null, 100, null, 300, null, 500, null, 700],
                ),
                const PBarChart(
                  label: '순자산 변화',
                  categories: ['7월', '8월', '9월', '10월'],
                  series: [
                    PChartSeries(
                      key: 'a',
                      label: '자산',
                      color: PChartColor.blue,
                      values: [-30000000, -18000000, 2000000, 10000000],
                    ),
                  ],
                ),
                PDonutChart(
                  label: '항목 12개',
                  diameter: 120,
                  centerLabel: '10월 지출',
                  centerAmount: '111,288,000,000원',
                  slices: [
                    for (final s in assignChartColors<int>([
                      for (var i = 0; i < 12; i++) 1000 + i,
                    ], groupOthers: (rest) => rest.fold(0, (a, b) => a + b)))
                      PDonutSlice(
                        key: '${s.item}',
                        label: '$s',
                        amount: s.item.toDouble(),
                        color: s.color,
                      ),
                  ],
                ),
                const PDonutChart(label: '빈 데이터', slices: []),
                const PHeatmap(
                  label: '큰 금액',
                  rows: [PHeatmapRow(key: 'a', label: '밤')],
                  columns: [
                    PHeatmapColumn(key: 'a', label: '월'),
                    PHeatmapColumn(key: 'b', label: '화'),
                  ],
                  values: [
                    [99999999999, 1],
                  ],
                ),
                const PHeatmap(
                  label: '빈 열지도',
                  rows: [],
                  columns: [],
                  values: [],
                ),
              ]),
              width: 360,
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('음수 축 글자("−3,000만")가 잘리지 않는다 — 세로축 폭이 가장 긴 글자에 맞는다', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PBarChart(
            label: '순자산',
            categories: ['7월', '8월'],
            series: [
              PChartSeries(
                key: 'a',
                label: '자산',
                color: PChartColor.blue,
                values: [-30000000, 10000000],
              ),
            ],
          ),
          width: 330,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final tick = findText('−3,000만');
      expect(tick, findsOneWidget);
      expect(tester.getRect(tick).left, greaterThanOrEqualTo(0));
    });

    testWidgets('1억 넘는 금액은 툴팁에서도 원까지 줄이지 않는다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _line(income: [0, 4200000 * 30, 0, 0, 0, 0, 0, 0]),
          width: 400,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final chart = tester.getRect(find.byType(LineChart));
      await tester.tapAt(Offset(chart.left + 100, chart.center.dy));
      await tester.pump();
      expect(findTextContaining('126,000,000원'), findsOneWidget);
    });
  });
}
