// 큰 글자 잘림 — QA 2026-11-19(담다 앱 #600 · #601 · #602 재확인)에서 본 네 건 + 열지도 요일 머리(groo-design #256).
//
// ① 안드로이드 320 · 글자 200%: 캘린더 두 자리 날짜가 잘린다("10" → "1"). 날 숫자 원이 글 줄 높이로만 커지고 글 폭은 재지 않았다
//    — 안드로이드 비선형 배율에서 줄 높이(19)는 덜 커지고 글(14)은 더 커져 "10" 이 원 폭보다 넓어 두 줄로 꺾여 잘렸다.
// ② 안드로이드 320 · 200%: 저축률 고리에 "BOTTOM OVERFLOWED BY 4.0 PIXELS". 고리 크기를 `scale(108)` 로 셌는데 안드로이드는
//    큰 값(108)을 거의 키우지 않아 고리는 그대로이고 안의 글(12 · 24)만 커졌다.
// ③ iOS AX4 · AX5: 순자산 추이 가로 끝 글 "2026. 11." 이 오른쪽에서 잘린다. 끝 글 자리(chart.md "끝 글 자리는 비워 둔다",
//    #247 D-1)를 셀 때 "모든 눈금이 보일 때의 글"로만 쟀다 — 끝 글 하나만 남으면 끝 글이 연도를 이어받아("11월" → "2026. 11.")
//    잰 글보다 길어진다.
// ④ iOS AX4 · AX5: 예산 탭 "설정" 글 버튼의 글 윗부분이 잘린다. 보이는 상자 36 을 고정 높이로 둬 커진 글을 담지 못했다
//    (DESIGN.md Typography "글이 상자보다 커지는 자리는 그 값이 최소 높이라 글을 따라 늘어난다").
// ⑤ 열지도 요일 머리 — 영어 두 글자(Mo … Su), 칸에 들지 않으면 한 글자, 줄을 바꾸지 않는다(international-design.mdx "날짜").
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show Intl;

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_trend_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

import '../support/android_font_scale.dart';

/// iOS 접근성 글자 — 본문 17 기준 배율(AX4 47 · AX5 53).
const double _ax4 = 47 / 17;
const double _ax5 = 53 / 17;

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  for (final family in const ['Pretendard', 'FlutterTest']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

Widget _app({
  required Widget home,
  required TextScaler scaler,
  Locale locale = const Locale('ko'),
}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: scaler),
    child: child!,
  ),
  home: home,
);

void _size(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// 글이 제 상자 안에 다 그려지는가 — 한 줄로 잰 글 폭 · 높이가 그려진 상자보다 크면(꺾이거나 위아래가 잘리면) 실패.
void _expectWhole(WidgetTester tester, Finder text, {String? reason}) {
  final rp = tester.renderObject<RenderParagraph>(
    find
        .descendant(of: text, matching: find.byType(RichText), matchRoot: true)
        .first,
  );
  final whole = TextPainter(
    text: rp.text,
    textDirection: TextDirection.ltr,
    textScaler: rp.textScaler,
    maxLines: 1,
  )..layout();
  final label = reason ?? rp.text.toPlainText();
  expect(
    rp.size.width,
    greaterThanOrEqualTo(whole.width - 0.01),
    reason: '$label — 글 폭 ${whole.width} 이 상자 ${rp.size.width} 안에 든다',
  );
  expect(
    rp.size.height,
    greaterThanOrEqualTo(whole.height - 0.01),
    reason: '$label — 글 높이 ${whole.height} 가 상자 ${rp.size.height} 안에 든다',
  );
  whole.dispose();
}

void main() {
  setUpAll(_loadFonts);
  tearDown(() => Intl.defaultLocale = null);

  group('① 캘린더 날 숫자', () {
    Future<void> pump(
      WidgetTester tester,
      TextScaler scaler,
      double width,
    ) async {
      _size(tester, width, 800);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userCalendarListProvider.overrideWith(
              (ref) async => const [
                UserCalendar(rowId: 1, calendarName: '개인', isDefault: true),
              ],
            ),
            monthEventsProvider.overrideWith((ref, key) async => const []),
            holidayListProvider.overrideWith((ref, key) async => const []),
          ],
          child: _app(
            scaler: scaler,
            home: const Scaffold(body: CalendarScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    // iOS AX5 는 두 자리 날짜("10" 57 · 줄 59)가 칸(320 45 · 402 57)보다 커 원을 키워도 들지 않는다 — 스펙에 길이 없어 보고(시험 안 함)
    for (final (name, scaler, width) in [
      ('320 · 안드로이드 200%', const AndroidNonlinearTextScaler(), 320.0),
      ('320 · 선형 200%', TextScaler.linear(2), 320.0),
      ('402 · iOS AX4', TextScaler.linear(_ax4), 402.0),
    ]) {
      testWidgets('$name — 두 자리 날짜가 한 줄로 다 보인다', (tester) async {
        await pump(tester, scaler, width);
        final numbers = find.descendant(
          of: find.byType(CalendarDayCell),
          matching: find.byWidgetPredicate(
            (w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? ''),
          ),
        );
        expect(numbers, findsWidgets);
        var twoDigit = 0;
        for (final e in numbers.evaluate()) {
          final f = find.byWidget(e.widget);
          if ((e.widget as Text).data!.length == 2) twoDigit++;
          _expectWhole(tester, f.first);
        }
        expect(twoDigit, greaterThan(0));
      });
    }
  });

  group('② 저축률 고리', () {
    for (final (name, scaler) in [
      ('안드로이드 200%', const AndroidNonlinearTextScaler()),
      ('선형 200%', TextScaler.linear(2)),
    ]) {
      testWidgets('320 · $name · 영어 — 가운데 글이 고리 안에 들고 넘침 0', (tester) async {
        Intl.defaultLocale = 'en';
        _size(tester, 320);
        await tester.pumpWidget(
          _app(
            scaler: scaler,
            locale: const Locale('en'),
            home: const Scaffold(
              body: Center(child: StatsSavingsRing(rate: null)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '고리 안 글 넘침 없음');
        final ring = tester.getRect(find.byType(StatsSavingsRing));
        final label = find.text('Savings rate');
        _expectWhole(tester, label);
        expect(ring.contains(tester.getRect(label).topLeft), isTrue);
        expect(ring.contains(tester.getRect(label).bottomRight), isTrue);
        expect(ring.width, lessThanOrEqualTo(320 - 2 * 24));
      });
    }
  });

  group('③ 순자산 추이 가로 끝 글', () {
    // 12개월 — 2025. 12. ~ 2026. 11.(해가 바뀌는 칸이 있다). 자산 탭 차트(높이 140), iPhone 17 Pro 402 − 좌우 24
    final rows = [
      (year: 2025, month: 12),
      for (var m = 1; m <= 11; m++) (year: 2026, month: m),
    ];
    for (final (name, scale) in [('AX4', _ax4), ('AX5', _ax5)]) {
      testWidgets('iOS $name — 연도를 이어받은 끝 글 "2026. 11." 이 잘리지 않고 차트 안에 선다', (
        tester,
      ) async {
        _size(tester, 402);
        await tester.pumpWidget(
          _app(
            scaler: TextScaler.linear(scale),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 354,
                  child: PLineChart(
                    label: '순자산',
                    height: 140,
                    categories: [for (final r in rows) '${r.month}월'],
                    xTicks: monthAxisTicks(rows),
                    area: false,
                    dots: true,
                    series: [
                      PChartSeries(
                        key: 'netWorth',
                        label: '순자산',
                        color: PChartColor.blue,
                        values: [
                          for (var i = 0; i < 12; i++) i < 9 ? 0 : 476000,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        final chart = tester.getRect(find.byType(PLineChart));
        final end = find.text('2026. 11.');
        expect(end, findsOneWidget, reason: '끝 글 하나만 남고 연도를 이어받는다');
        _expectWhole(tester, end);
        final r = tester.getRect(end);
        expect(r.right, lessThanOrEqualTo(chart.right + 0.01));
      });
    }
  });

  group('④ 글 버튼', () {
    for (final (name, scale) in [('AX4', _ax4), ('AX5', _ax5)]) {
      testWidgets('iOS $name — "설정" 글이 위아래 잘리지 않고 상자가 글을 따라 늘어난다', (
        tester,
      ) async {
        _size(tester, 402);
        await tester.pumpWidget(
          _app(
            scaler: TextScaler.linear(scale),
            home: Scaffold(
              body: Center(
                child: PTextButton(label: '설정', onPressed: () {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final label = find.byKey(const ValueKey('text-button-label'));
        _expectWhole(tester, label);
        final box = tester.getRect(
          find.byKey(const ValueKey('text-button-box')),
        );
        final text = tester.getRect(label);
        expect(box.top, lessThanOrEqualTo(text.top));
        expect(box.bottom, greaterThanOrEqualTo(text.bottom));
      });
    }

    testWidgets('100% — 보이는 상자는 36 그대로', (tester) async {
      await tester.pumpWidget(
        _app(
          scaler: TextScaler.noScaling,
          home: Scaffold(
            body: Center(
              child: PTextButton(label: '설정', onPressed: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('text-button-box'))).height,
        36,
      );
    });
  });

  group('⑤ 열지도 요일 머리', () {
    Future<List<String>> heads(
      WidgetTester tester, {
      required double width,
      required TextScaler scaler,
      Locale locale = const Locale('en'),
    }) async {
      Intl.defaultLocale = locale.languageCode;
      _size(tester, width);
      await tester.pumpWidget(
        _app(
          scaler: scaler,
          locale: locale,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatsHeatmapSection(
                period: StatsPeriod.thisMonth(DateTime(2026, 11, 19)),
                cells: const [
                  HeatmapCell(dayOfWeek: 3, hour: 19, totalAmount: 35000),
                ],
                masked: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      return [
        for (var i = 0; i < 7; i++)
          () {
            final f = find.byKey(ValueKey('chart-heatmap-column-$i'));
            _expectWhole(tester, f);
            return tester.widget<Text>(f).data!;
          }(),
      ];
    }

    testWidgets('영어 · 넓은 폭 — 두 글자 Mo … Su(세 글자로 늘리지 않는다)', (tester) async {
      expect(await heads(tester, width: 1024, scaler: TextScaler.noScaling), [
        'Mo',
        'Tu',
        'We',
        'Th',
        'Fr',
        'Sa',
        'Su',
      ]);
    });

    testWidgets('영어 · 390 · 100% — 두 글자', (tester) async {
      expect(await heads(tester, width: 390, scaler: TextScaler.noScaling), [
        'Mo',
        'Tu',
        'We',
        'Th',
        'Fr',
        'Sa',
        'Su',
      ]);
    });

    testWidgets('영어 · 320 · 200% — 칸에 들지 않으면 한 글자', (tester) async {
      expect(await heads(tester, width: 320, scaler: TextScaler.linear(2)), [
        'M',
        'T',
        'W',
        'T',
        'F',
        'S',
        'S',
      ]);
    });

    testWidgets('한국어 — 월 … 일', (tester) async {
      expect(
        await heads(
          tester,
          width: 390,
          scaler: TextScaler.noScaling,
          locale: const Locale('ko'),
        ),
        ['월', '화', '수', '목', '금', '토', '일'],
      );
    });
  });
}
