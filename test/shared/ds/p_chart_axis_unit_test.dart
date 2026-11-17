// 차트 축 — 한 축은 한 단위 · 가로 눈금 글자 사이 최소 8 · 연도는 보이는 눈금에(groo-design#238, chart.md "축 · 격자" · "큰 글자").
// QA: 폰 세로 402 에서 눈금이 촘촘해 해가 바뀌는 칸("2026. 1.")이 건너뛰기로 빠지면 연도가 통째로 사라졌다("12월 · 빈칸 · 2월").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import '../../support/plain_text.dart';

/// [year]년 [month]월부터 [n] 달.
List<({int year, int month})> _months(int year, int month, int n) => [
  for (var i = 0; i < n; i++)
    (year: year + (month - 1 + i) ~/ 12, month: (month - 1 + i) % 12 + 1),
];

/// 글을 직접 지은 월 눈금(로케일과 상관없이 같은 글).
List<PChartXTick> _ticks(List<({int year, int month})> rows) => [
  for (final r in rows)
    (label: '${r.month}월', yearLabel: '${r.year}. ${r.month}.', year: r.year),
];

Widget _host({
  required double width,
  required List<({int year, int month})> rows,
  List<double>? values,
}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: PBarChart(
          label: '추이',
          height: 160,
          categories: chartXTickFullLabels(_ticks(rows)),
          xTicks: monthAxisTicks(rows),
          series: [
            PChartSeries(
              key: 'n',
              label: '지출',
              color: PChartColor.blue,
              values: values ?? [for (var i = 0; i < rows.length; i++) 1000.0],
            ),
          ],
        ),
      ),
    ),
  ),
);

/// 그려진 가로 눈금 글 — 왼쪽부터.
List<String> _shownMonths(WidgetTester tester) {
  final f = findTextContaining(RegExp(r'^(\d+월|\d{4}\. \d+\.)$'));
  final items = [
    for (final e in f.evaluate())
      (
        x: tester.getRect(find.byWidget(e.widget)).left,
        text: (e.widget as Text).data!,
      ),
  ]..sort((a, b) => a.x.compareTo(b.x));
  return [for (final i in items) i.text];
}

void main() {
  group('보이는 눈금의 연도', () {
    test('모두 보이면 해가 바뀌는 첫 눈금에만 연도', () {
      final labels = chartXTickLabels(_ticks(_months(2025, 12, 12)), 1);
      expect(labels.take(3), ['12월', '2026. 1.', '2월']);
      expect(labels.where((l) => l!.contains('.')).length, 1);
    });

    test('해가 바뀌는 칸이 건너뛰기로 빠지면 다음 보이는 눈금이 연도를 이어받는다', () {
      // 25년 11월 ~ 26년 10월, 두 칸마다(끝에서) — 1월이 빠진다
      expect(chartXTickLabels(_ticks(_months(2025, 11, 12)), 2), [
        null,
        '12월',
        null,
        '2026. 2.',
        null,
        '4월',
        null,
        '6월',
        null,
        '8월',
        null,
        '10월',
      ]);
    });

    test('첫 보이는 눈금도 맨 앞 칸과 해가 다르면 연도 · 끝 눈금은 늘 남는다', () {
      final shown = chartXTickLabels(
        _ticks(_months(2025, 12, 12)),
        2,
      ).whereType<String>().toList();
      expect(shown, ['2026. 1.', '3월', '5월', '7월', '9월', '11월']);
      // 여섯 칸마다 — 보이는 눈금끼리 견준다
      expect(
        chartXTickLabels(
          _ticks(_months(2024, 12, 13)),
          6,
        ).whereType<String>().toList(),
        ['12월', '2025. 6.', '12월'],
      );
    });

    test('해가 없는 눈금은 연도를 붙이지 않는다', () {
      expect(
        chartXTickLabels([
          for (final l in ['1주', '2주', '3주'])
            (label: l, yearLabel: null, year: null),
        ], 1),
        ['1주', '2주', '3주'],
      );
    });

    testWidgets('좁은 폭 — 1월이 건너뛰기로 빠져도 연도는 다음 보이는 눈금(2월)이 이어받는다', (
      tester,
    ) async {
      // 25년 11월 ~ 26년 10월. 테스트 글꼴로 가장 긴 글("2026. 1.")이 들어가는 칸이 6 — 두 칸마다(끝에서)
      await tester.pumpWidget(_host(width: 800, rows: _months(2025, 11, 12)));
      await tester.pump(const Duration(seconds: 1));
      expect(_shownMonths(tester), [
        '12월',
        '2026. 2.',
        '4월',
        '6월',
        '8월',
        '10월',
      ]);
    });

    testWidgets('더 좁으면 — 끝 눈금은 남고, 앞에 보이는 눈금과 해가 다르면 끝 눈금이 연도를 받는다', (
      tester,
    ) async {
      await tester.pumpWidget(_host(width: 240, rows: _months(2025, 11, 12)));
      await tester.pump(const Duration(seconds: 1));
      final shown = _shownMonths(tester);
      expect(shown.length, lessThan(6), reason: '$shown');
      expect(shown.last, endsWith('10.'), reason: '끝 눈금(10월)을 지킨다 $shown');
      expect(
        shown.where((s) => s.startsWith('2026. ')),
        hasLength(1),
        reason: '연도가 사라지지 않고 한 눈금에만 $shown',
      );
    });

    testWidgets('넓은 폭 — 모두 보이고 연도는 1월에만', (tester) async {
      tester.view.physicalSize = const Size(2000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(width: 1600, rows: _months(2025, 11, 12)));
      await tester.pump(const Duration(seconds: 1));
      final shown = _shownMonths(tester);
      expect(shown, hasLength(12));
      expect(shown.where((s) => s.contains('.')), ['2026. 1.']);
    });
  });

  testWidgets('세로축 — 한 축은 한 단위(5,000 · 1만 이 섞이지 않는다)', (tester) async {
    await tester.pumpWidget(
      _host(
        width: 400,
        rows: _months(2026, 1, 3),
        values: [15000, 12000, 3000],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(findText('0.5만'), findsOneWidget);
    expect(findText('1.5만'), findsOneWidget);
    expect(findText('5,000'), findsNothing);
  });

  group('눈금 간격 1 · 2 · 5 × 10ⁿ · 한 축은 한 단위(만 · 억)', () {
    /// 값 범위의 눈금 글 — 차트가 그리는 셈 그대로(niceChartAxis → 눈금 → formatAxisWon).
    List<String> drawn(double lo, double hi) {
      final a = niceChartAxis(lo, hi);
      final ticks = [
        for (var v = a.min; v <= a.max + a.step / 2; v += a.step) v,
      ];
      return [for (final v in ticks) formatAxisWon(v, ticks)];
    }

    test('0 ~ 1만 — 0.2만 간격(2,500 간격의 "0.3만" · "0.8만" 이 나오지 않는다)', () {
      expect(drawn(0, 10000), ['0', '0.2만', '0.4만', '0.6만', '0.8만', '1만']);
    });
    test('0 ~ 8,000 — 모두 쉼표 정수', () {
      expect(drawn(0, 8000), ['0', '2,000', '4,000', '6,000', '8,000']);
    });
    test('0 ~ 3만 · 0 ~ 1.5억', () {
      expect(drawn(0, 30000), ['0', '1만', '2만', '3만']);
      expect(drawn(0, 150000000), ['0', '0.5억', '1억', '1.5억']);
    });
    test('5,000만 ~ 1억 이 섞인 값 — 모두 억(5,000만 · 1억 섞임 없음)', () {
      expect(drawn(50000000, 100000000), [
        '0',
        '0.2억',
        '0.4억',
        '0.6억',
        '0.8억',
        '1억',
      ]);
    });
    test('음수 축', () {
      expect(drawn(-25000, 60000), ['−4만', '−2만', '0', '2만', '4만', '6만']);
      expect(drawn(-30000000, 10000000), [
        '−3,000만',
        '−2,000만',
        '−1,000만',
        '0',
        '1,000만',
      ]);
    });
    test('모두 0 — 기본 축 0 ~ 1만도 같은 계열(0.2만 간격)', () {
      expect(drawn(0, 0), drawn(0, 10000));
      final zero = niceChartAxis(0, 0);
      expect((zero.min, zero.max, zero.step), (0, 10000, 2000));
    });
  });
}
