// 영어 돈 · 요일 — groo-design #250(chart.md · date-picker.md · international-design.mdx, 사용자 결정).
//
// ⓐ 영어 축은 천 단위 K · M · B — 가장 큰 절댓값이 1B 이상 B, 1M 이상 M, 1K 이상 K, 아니면 쉼표 정수(0.5K · 1K · 500K · 1M ·
//    1.5B, 1,000M 이 아니라 1B). 한국어 만 · 억 · 한 축 한 단위는 그대로
// ⓑ 줄이지 않는 돈 — 영어 "₩1,240,000", 한국어 "1,240,000원"(툴팁 · 지표 타일 · 도넛 · 열지도)
// ⓒ 영어 요일 줄(기간 시트 · 달력)은 두 글자 Su Mo Tu We Th Fr Sa, 칸에 들지 않는 폭 · 글자 크기에서만 한 글자 — 줄을 바꾸지 않는다
// 언어는 앱 로케일(`Intl.defaultLocale` — 앱이 화면 로케일로 맞춘다)을 따른다.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';

import '../../support/plain_text.dart';

/// [ticks] 축의 눈금 글 전부.
List<String> _axis(List<double> ticks) => [
  for (final t in ticks) formatAxisWon(t, ticks),
];

Widget _app(Widget child, {required Locale locale, double scale = 1}) =>
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    );

void main() {
  tearDown(() => Intl.defaultLocale = null);

  group('ⓐ 영어 축 — K · M · B', () {
    setUp(() => Intl.defaultLocale = 'en');

    test('문턱 — 1K · 1M · 1B 에서 단위가 바뀐다(한 축은 가장 큰 값으로 한 단위)', () {
      expect(_axis([0, 200, 400, 600, 800]), ['0', '200', '400', '600', '800']);
      expect(_axis([0, 250, 999]), ['0', '250', '999']);
      expect(_axis([0, 500, 1000]), ['0', '0.5K', '1K']);
      expect(_axis([0, 250000, 500000]), ['0', '250K', '500K']);
      expect(_axis([0, 999000]), ['0', '999K']);
      expect(_axis([0, 500000, 1000000]), ['0', '0.5M', '1M']);
      expect(_axis([0, 500000000, 1000000000]), [
        '0',
        '0.5B',
        '1B',
      ], reason: '1,000M 이 아니라 1B');
      expect(_axis([0, 1000000000, 1500000000]), ['0', '1B', '1.5B']);
      expect(_axis([-2000, 0, 2000]), ['−2K', '0', '2K'], reason: '빼기는 U+2212');
      expect(_axis([0, 1200, 2400]), ['0', '1.2K', '2.4K']);
    });
  });

  group('ⓐ 한국어 축 — 만 · 억 그대로', () {
    setUp(() => Intl.defaultLocale = 'ko');

    test('만 · 억 · 쉼표 정수', () {
      expect(_axis([0, 2000, 4000]), ['0', '2,000', '4,000']);
      expect(_axis([0, 5000, 10000]), ['0', '0.5만', '1만']);
      expect(_axis([0, 50000000, 100000000]), ['0', '0.5억', '1억']);
      expect(_axis([0, 25000000, 50000000]), ['0', '2,500만', '5,000만']);
    });
  });

  group('ⓑ 줄이지 않는 돈', () {
    test('영어 ₩1,240,000 · 빼기는 기호 앞', () {
      Intl.defaultLocale = 'en';
      expect(formatWon(1240000), '₩1,240,000');
      expect(formatWon(-1000), '−₩1,000');
      expect(formatWon(0), '₩0');
    });

    test('한국어 1,240,000원', () {
      Intl.defaultLocale = 'ko';
      expect(formatWon(1240000), '1,240,000원');
      expect(formatWon(-1000), '−1,000원');
    });

    testWidgets('영어 툴팁 — 값은 ₩ 앞에 원까지, 눈금은 K', (tester) async {
      Intl.defaultLocale = 'en';
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: PLineChart(
              label: 'Income',
              height: 200,
              categories: const ['Oct 1', 'Oct 2', 'Oct 3'],
              series: const [
                PChartSeries(
                  key: 'in',
                  label: 'Income',
                  color: PChartColor.blue,
                  values: [1240000, 300000, 820000],
                ),
              ],
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(findText('1.5M'), findsOneWidget, reason: '눈금은 M');
      final chart = tester.getRect(find.byType(LineChart));
      await tester.tapAt(Offset(chart.left + 80, chart.center.dy));
      await tester.pump();
      expect(find.byKey(const ValueKey('chart-tooltip')), findsOneWidget);
      expect(findText('₩1,240,000'), findsOneWidget);
      expect(findText('1,240,000원'), findsNothing);
    });
  });

  group('ⓒ 영어 요일 줄 — 두 글자, 안 들면 한 글자, 줄바꿈 없음', () {
    const two = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    const one = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    test('글 — 두 글자 · 한 글자 · 한국어 그대로', () {
      Intl.defaultLocale = 'en';
      expect(weekdayRowLabels(), two);
      expect(weekdayRowNarrowLabels(), one);
      Intl.defaultLocale = 'ko';
      expect(weekdayRowLabels(), ['일', '월', '화', '수', '목', '금', '토']);
    });

    /// [of] 안의 요일 글 — 줄 수(한 줄인가)와 보인 글.
    List<String> shownDays(WidgetTester tester, Finder of) {
      final out = <String>[];
      for (final e
          in find.descendant(of: of, matching: find.byType(Text)).evaluate()) {
        final t = plainOf((e.widget as Text).data ?? '');
        if (two.contains(t) || one.contains(t)) {
          out.add(t);
          final rich = find.descendant(
            of: find.byWidget(e.widget),
            matching: find.byType(RichText),
          );
          final p = tester.renderObject<RenderParagraph>(rich.first);
          // 한 줄 높이 · 제 폭 그대로 — 줄을 바꾸지도, 칸에 잘리지도 않는다
          final one = TextPainter(
            text: p.text,
            textScaler: p.textScaler,
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          expect(
            p.size.height,
            moreOrLessEquals(one.height, epsilon: 0.5),
            reason: '요일 "$t" 이 줄을 바꾼다',
          );
          expect(
            one.width,
            lessThanOrEqualTo(p.size.width + 0.5),
            reason: '요일 "$t" 이 칸에 잘린다',
          );
          final cell = tester.getRect(find.byWidget(e.widget));
          expect(
            one.width,
            lessThanOrEqualTo(cell.width + 0.5),
            reason: '요일 "$t" 이 칸보다 넓다',
          );
          one.dispose();
        }
      }
      return out;
    }

    // 320 · 200% 는 두 글자("We" 40)가 칸(약 40 − 여백)에 들지 않아 한 글자로 준다
    for (final (width, scale, expected) in [
      (360.0, 1.0, two),
      (320.0, 1.0, two),
      (320.0, 2.0, one),
    ]) {
      testWidgets(
        '기간 시트 달력 · 폭 ${width.round()} · 글자 ${(scale * 100).round()}% → ${expected.first}',
        (tester) async {
          Intl.defaultLocale = 'en';
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _app(
              SizedBox(
                width: width,
                child: Builder(
                  builder: (context) => PDatePicker.single(
                    labels: PDatePickerLabels.of(context),
                    today: DateTime(2026, 10, 15),
                  ),
                ),
              ),
              locale: const Locale('en'),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final row = find.byKey(const ValueKey('date-weekdays'));
          expect(shownDays(tester, row), expected);
          // 읽는 이름은 늘 온 이름
          expect(
            find.bySemanticsLabel('Friday'),
            findsOneWidget,
            reason: '보이는 글이 줄어도 읽는 요일은 그대로',
          );
        },
      );
    }

    for (final (width, scale, expected) in [
      (320.0, 1.0, two),
      (320.0, 2.0, one),
    ]) {
      testWidgets(
        '달력 탭 요일 줄 · 폭 ${width.round()} · 글자 ${(scale * 100).round()}% → ${expected.first}',
        (tester) async {
          Intl.defaultLocale = 'en';
          tester.view.physicalSize = Size(width, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _app(
              const SizedBox(width: 320, child: CalendarWeekdayRow()),
              locale: const Locale('en'),
              scale: scale,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(shownDays(tester, find.byType(CalendarWeekdayRow)), expected);
        },
      );
    }
  });
}
