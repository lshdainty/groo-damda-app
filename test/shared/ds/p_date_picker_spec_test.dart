// Date Picker 가 스펙 값(test/fixtures/design_spec/date-picker.json)대로인지 — 고르기(하루 · 기간 · 여러 날) × 보이는 범위(한 달 ·
// 이어지는 달) × 라이트 · 다크의 머리 · 제목 · 이전 · 다음 · 요일 줄 · 날짜 칸 · 원 · 기간 띠 · 달 이름 · 안개 · 연 · 월 휠 · 빠른 기간 칩 줄,
// 날짜 상태(보통 · 누름 · 오늘 · 고름 · 기간 사이 · 앞뒤 달 · 막힘 · 읽기 전용) 한 칸씩, 그리고 동작(하루 · 기간 · 여러 날 고르기 · 달 옮기기 ·
// 연 · 월 휠 · 빠른 기간 · 이어지는 달 스크롤 · 시트에서 "완료" 로 넣기)과 날짜 계산(윤년 · 월말 · 연말 · 달을 넘는 기간 · 6주 달 · 최소 / 최대).
//
// 앱에 없는 것 — ① 두 달 나란히(twoMonths): 1280 이상 팝오버라 앱에 없다(Dialog · Menu · Popover 와 같다). ② 웹의 호버(마우스) ·
// 키보드 포커스 링(focused) · 방향키 격자 이동(WAI-ARIA Grid) · 열 때 날짜 칸 초점 — 손가락 입력이 기본이다(호버 색은 누름과 같은 값이라
// 누르는 동안 칸으로 잰다). ③ 팝오버 폭 336(root.width) — 앱은 놓인 자리 폭 − 좌우 inset 이고, 시트에서는 그 폭(360 화면 312)을 잰다.
// 날짜는 로컬 시간대 기준이라 이 테스트는 TZ=Asia/Seoul · TZ=UTC 둘 다 돈다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_demo.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('date-picker');
final _labels = PDatePickerLabels.ko;
final _today = DateTime(2026, 10, 15);

Widget _app(Brightness mode, Widget home) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: home),
);

/// 달력을 폭 [width](기본 312 — 360 화면의 시트) · 높이 [height](이어지는 달은 필수)에 놓는다.
Widget _host(
  Brightness mode,
  Widget calendar, {
  double width = 312,
  double? height,
}) => _app(
  mode,
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, height: height, child: calendar),
  ),
);

Finder _day(DateTime d) => find.byKey(ValueKey('date-${dayKey(d)}'));
Finder _outside(DateTime d) =>
    find.byKey(ValueKey('date-outside-${dayKey(d)}'));
Finder _visual(DateTime d) => find.descendant(
  of: _day(d),
  matching: find.byKey(const ValueKey('date-day-visual')),
);
Finder _band(DateTime d) => find.descendant(
  of: _day(d),
  matching: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey &&
        '${(w.key! as ValueKey).value}'.startsWith('date-band-'),
  ),
);

PDatePickerDayState _stateOf(WidgetTester tester, DateTime d) =>
    tester.widget<PDatePickerDayCell>(_day(d)).state;

TextStyle _labelStyle(WidgetTester tester, DateTime d) => tester
    .widget<Text>(find.descendant(of: _day(d), matching: find.byType(Text)))
    .style!;

Color? _circleColor(WidgetTester tester, DateTime d) =>
    ((tester.widget<AnimatedContainer>(_visual(d)).decoration!)
            as BoxDecoration)
        .color;

/// 달력의 날짜 칸 수 — 이 달 날짜 + 앞뒤 달 흐린 날짜.
int _cells(WidgetTester tester) =>
    find.byType(PDatePickerDayCell).evaluate().length +
    find.byType(PDatePickerOutsideCell).evaluate().length;

/// 실패를 모으는 도우미 — 색 · 수 · 글자를 스펙과 맞춘다.
class _Check {
  _Check(this.mode, this.want, this.where);

  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];
  final measured = <String>{};

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color? actual) {
    measured.add(key);
    final w = pickMode(want[key], mode);
    if (w == null) return;
    if (actual == null || !sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${actual == null ? 'null' : colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    measured.add(key);
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  void typo(String key, TextStyle style) {
    measured.add(key);
    final t = want[key] as Map?;
    if (t == null) return;
    final lineHeight = style.fontSize! * (style.height ?? 1);
    if (t['fontSize'] != style.fontSize ||
        ((t['lineHeight'] as num) - lineHeight).abs() > 0.01) {
      fail(
        '$key: 스펙 ${t['fontSize']}/${t['lineHeight']} · 실제 ${style.fontSize}/$lineHeight',
      );
    }
    final family = '${t['fontFamily']}'.split(',').first.trim();
    if (style.fontFamily != family) {
      fail('$key 글꼴: 스펙 $family · 실제 ${style.fontFamily}');
    }
  }

  void weight(String key, TextStyle style) {
    measured.add(key);
    final w = want[key];
    if (w is num && style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }

  void ms(String key, Duration actual) {
    measured.add(key);
    final w = want[key];
    if (w != null && specMs(w) != actual) {
      fail('$key: 스펙 $w · 실제 ${actual.inMilliseconds}ms');
    }
  }

  void easing(String key, Curve actual) {
    measured.add(key);
    final w = want[key];
    if (w == null) return;
    final c = specCubic(w);
    if (actual is! Cubic ||
        actual.a != c[0] ||
        actual.b != c[1] ||
        actual.c != c[2] ||
        actual.d != c[3]) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  /// 스펙이 푼 값은 모두 어딘가에서 잰다 — 여기서 재거나, 앱에 없다([elsewhere]). 스펙에 새 값이 생기면 여기서 걸린다.
  void coverage(Set<String> elsewhere, {String prefix = ''}) {
    for (final key in want.keys) {
      if (!key.startsWith(prefix)) continue;
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}

/// 달력 하나를 그리고 스펙대로 재는 값들 — 고르기 × 보이는 범위. 값은 Date Picker 견본의 것이다.
Widget _calendar(
  String selection, {
  required bool continuous,
  bool wheel = false,
}) {
  final range = continuous
      ? PDateVisibleRange.continuous
      : PDateVisibleRange.month;
  return switch (selection) {
    'single' => PDatePicker.single(
      labels: _labels,
      inset: 0,
      visibleRange: range,
      value: DateTime(2026, 10, 20),
      today: _today,
      defaultWheelOpen: wheel,
    ),
    'range' => PDatePicker.range(
      labels: _labels,
      inset: 0,
      visibleRange: range,
      presets: const [
        PDatePreset.thisWeek,
        PDatePreset.thisMonth,
        PDatePreset.lastMonth,
      ],
      value: PDateRange(
        start: DateTime(2026, 10, 8),
        end: DateTime(2026, 10, 22),
      ),
      today: _today,
      defaultWheelOpen: wheel,
    ),
    _ => PDatePicker.multiple(
      labels: _labels,
      inset: 0,
      visibleRange: range,
      value: [DateTime(2026, 10, 7), DateTime(2026, 10, 14)],
      today: _today,
      defaultWheelOpen: wheel,
    ),
  };
}

/// 새로 올린다 — 같은 종류의 달력을 다시 올려도 고른 달 · 휠이 남지 않게 먼저 비운다.
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(widget);
}

/// 누르고 한 프레임 — 눌러서 값이 바뀌면 다음 누름이 바뀐 값 위에서 일어난다.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
}

Rect _rect(WidgetTester tester, Finder f) => tester.getRect(f);

void main() {
  // ── 달력 전체 — 고르기 × 보이는 범위 × 라이트 · 다크 ────────────────────
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['selection', 'visibleRange'])) {
      // 두 달 나란히는 1280 이상 팝오버 — 앱에 없다
      if (combo['visibleRange'] == 'twoMonths') continue;
      final selection = combo['selection']!;
      final continuous = combo['visibleRange'] == 'continuous';
      final title = '${mode.name} $selection · ${combo['visibleRange']}';
      testWidgets('$title — 스펙 값이다', (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = _Check(mode, _spec.resolve(combo, 'enabled'), title);
        await _pump(
          tester,
          _host(
            mode,
            _calendar(selection, continuous: continuous),
            height: continuous ? 600 : null,
          ),
        );
        await tester.pumpAndSettle();

        // 바탕 — bg-layer-floating. 폭은 놓인 자리 폭(시트 − 24 · 24)
        c.color(
          'root.background',
          tester
              .widget<ColoredBox>(find.byKey(const ValueKey('date-root')))
              .color,
        );
        expect(
          _rect(tester, find.byKey(const ValueKey('date-root'))).width,
          312,
        );

        // 머리 — 한 달만(이어지는 달은 머리 · 제목 · 이전 · 다음이 없다)
        if (continuous) {
          c.px('header.height', 0);
          expect(find.byKey(const ValueKey('date-header')), findsNothing);
          expect(find.byKey(const ValueKey('date-title')), findsNothing);
          expect(find.byType(PButton), findsNothing, reason: '이전 · 다음이 없다');
        } else {
          final header = _rect(
            tester,
            find.byKey(const ValueKey('date-header')),
          );
          c.px('header.height', header.height);
          final titleText = find.descendant(
            of: find.byKey(const ValueKey('date-title')),
            matching: find.byType(Text),
          );
          final style = tester.widget<Text>(titleText).style!;
          c.typo('title.typography', style);
          c.weight('title.fontWeight', style);
          c.color('title.foreground', style.color);
          final textRect = _rect(tester, titleText);
          final iconFinder = find.byKey(const ValueKey('date-title-icon'));
          c.px('title.paddingX', textRect.left - header.left);
          c.px('title.gap', _rect(tester, iconFinder).left - textRect.right);
          final icon = tester.widget<Icon>(
            find.descendant(of: iconFinder, matching: find.byType(Icon)),
          );
          c.px('titleIcon.size', icon.size!);
          c.color('titleIcon.color', icon.color);
          // 이전 · 다음 — Button ghost 40 · 아이콘 18, 둘 사이 0 · 머리 오른쪽 끝
          final buttons = find.byType(PButton);
          expect(buttons, findsNWidgets(2));
          final prev = _rect(tester, buttons.at(0));
          final next = _rect(tester, buttons.at(1));
          c.px('navButton.size', prev.width);
          expect(prev.height, 40);
          expect(next.left - prev.right, 0);
          expect(next.right, header.right);
          final navIcon = tester.widget<Icon>(
            find.descendant(of: buttons.at(0), matching: find.byType(Icon)),
          );
          c.px('navButton.iconSize', navIcon.size!);
          c.color('navButton.color', navIcon.color);
        }

        // 요일 줄 48 · 14 / 19 · 500 · fg-neutral-subtle, 날짜 줄 48 × 6주
        final weekdays = _rect(
          tester,
          find.byKey(const ValueKey('date-weekdays')),
        );
        c.px('weekday.height', weekdays.height);
        final weekdayText = tester.widget<Text>(
          find
              .descendant(
                of: find.byKey(const ValueKey('date-weekdays')),
                matching: find.byType(Text),
              )
              .first,
        );
        c.typo('weekday.typography', weekdayText.style!);
        c.weight('weekday.fontWeight', weekdayText.style!);
        c.color('weekday.foreground', weekdayText.style!.color);

        final enabledDay = _day(DateTime(2026, 10, 13));
        final cell = _rect(tester, enabledDay);
        c.px('cell.height', cell.height);
        expect(cell.width, closeTo(312 / 7, 0.01), reason: '칸 폭 = 달력 폭 ÷ 7');
        if (continuous) {
          // 그 달의 주 수 — 2026년 10월은 5주(앞뒤 달 날짜는 비운다)
          c.px(
            'cell.weeks',
            find.byKey(const ValueKey('date-grid-2026-10')).evaluate().isEmpty
                ? 0
                : 5,
          );
          final grid = _rect(
            tester,
            find.byKey(const ValueKey('date-grid-2026-10')),
          );
          expect(grid.height, 5 * 48);
          expect(
            find
                .byType(PDatePickerOutsideCell)
                .evaluate()
                .every(
                  (e) => (e.widget as PDatePickerOutsideCell).show == false,
                ),
            isTrue,
            reason: '이어지는 달은 앞뒤 달 날짜를 비운다',
          );
        } else {
          c.px('cell.weeks', _cells(tester) / 7);
          expect(
            _rect(
              tester,
              find.byKey(const ValueKey('date-grid-2026-10')),
            ).height,
            6 * 48,
          );
        }

        // 원 42(칸 가운데) · 둥근 · 보통 날은 바탕 없음 · 숫자 16 / 22 · 500 · fg-neutral-muted
        final visual = _rect(tester, _visual(DateTime(2026, 10, 13)));
        c.px('dayVisual.size', visual.width);
        expect(visual.height, visual.width);
        expect(visual.center.dx, closeTo(cell.center.dx, 0.01));
        expect(visual.top - cell.top, closeTo(3, 0.01), reason: '원은 칸 위 3');
        final animated = tester.widget<AnimatedContainer>(
          _visual(DateTime(2026, 10, 13)),
        );
        final deco = animated.decoration! as BoxDecoration;
        c.px(
          'dayVisual.radius',
          (deco.borderRadius! as BorderRadius).topLeft.x,
        );
        c.color('dayVisual.background', deco.color);
        c.ms('dayVisual.transitionDuration', animated.duration);
        c.easing('dayVisual.transitionEasing', animated.curve);
        c.measured.add(
          'dayVisual.transitionProperty',
        ); // 바탕색 하나만 움직인다(AnimatedContainer 의 색)
        final label = _labelStyle(tester, DateTime(2026, 10, 13));
        c.typo('dayLabel.typography', label);
        c.weight('dayLabel.fontWeight', label);
        c.color('dayLabel.foreground', label.color);
        expect(
          label.fontFeatures?.map((f) => f.feature),
          contains('tnum'),
          reason: '숫자 폭을 같게',
        );

        // 기간 띠 — 원과 같은 높이 · bg-neutral-weak(기간만)
        if (selection == 'range') {
          final band = _rect(tester, _band(DateTime(2026, 10, 15)));
          c.px('rangeBand.height', band.height);
          c.color(
            'rangeBand.background',
            tester
                .widget<ColoredBox>(
                  find
                      .descendant(
                        of: _day(DateTime(2026, 10, 15)),
                        matching: find.byType(ColoredBox),
                      )
                      .first,
                )
                .color,
          );
          expect(band.width, closeTo(312 / 7, 0.01), reason: '사이 칸은 칸 폭 전체');
        }

        // 이어지는 달 — 달 이름 48 · 왼쪽 정렬(좌우 4) · 안개 96 · 요일 줄이 위에 붙는다
        if (continuous) {
          final labelBox = find.byKey(const ValueKey('date-month-label')).first;
          final labelRect = _rect(tester, labelBox);
          c.px('monthLabel.height', labelRect.height);
          final text = tester.widget<Text>(
            find.descendant(of: labelBox, matching: find.byType(Text)),
          );
          c.typo('monthLabel.typography', text.style!);
          c.weight('monthLabel.fontWeight', text.style!);
          c.color('monthLabel.foreground', text.style!.color);
          c.px(
            'monthLabel.paddingX',
            _rect(
                  tester,
                  find.descendant(of: labelBox, matching: find.byType(Text)),
                ).left -
                labelRect.left,
          );
          c.px(
            'fog.height',
            _rect(tester, find.byKey(const ValueKey('date-fog'))).height,
          );
          // 요일 줄은 스크롤해도 맨 위에 붙는다(sticky)
          final before = _rect(
            tester,
            find.byKey(const ValueKey('date-weekdays')),
          ).top;
          await tester.drag(
            find.byKey(const ValueKey('date-scroll')),
            const Offset(0, -700),
          );
          await tester.pumpAndSettle();
          c.measured.add('weekday.position');
          expect(
            _rect(tester, find.byKey(const ValueKey('date-weekdays'))).top,
            before,
          );
          expect(want('weekday.position', c.want), 'sticky');
          c.measured.add('root.height');
        } else {
          c.measured.add(
            'monthLabel.height',
          ); // 한 달은 머리 제목이 달 이름이다(이어지는 달 · 두 달 몫)
        }

        // 스펙에 있는데 앱에 없는 것 — 웹 전용(커서 · 제목의 초점 링 모서리 · 팝오버 폭) · 호스트 몫(시트 바닥)
        const elsewhere = {
          'cell.cursor',
          'title.radius',
          'root.width',
          'footer.paddingTop',
          // 연 · 월 휠은 한 달에서 제목을 눌러야 열린다 — 아래 휠 테스트가 잰다
          'wheel.height',
          'wheel.columns',
          'wheel.background',
          // 빠른 기간 칩 줄은 기간 달력 위에서 잰다 — 아래 칩 줄 테스트
          'presets.chip',
          'presets.gap',
          'presets.paddingBottom',
          // 이어지는 달 전용 · 한 달 전용 값은 그 달력에서만 잰다
          'fog.height',
          'weekday.position',
          'monthLabel.paddingX',
          'monthLabel.typography',
          'monthLabel.fontWeight',
          'monthLabel.foreground',
          'rangeBand.height',
          'rangeBand.background',
          'title.typography',
          'title.fontWeight',
          'title.foreground',
          'title.paddingX',
          'title.gap',
          'titleIcon.size',
          'titleIcon.color',
          'navButton.size',
          'navButton.iconSize',
          'navButton.color',
        };
        // 각 달력에서 재지 않는 값은 위 목록에서만 허용한다 — 그 밖의 값이 빠지면 걸린다
        c.coverage(elsewhere);
        expect(c.failures, isEmpty, reason: c.failures.join('\n'));
        expect(tester.takeException(), isNull);
      });
    }
  }

  // ── 연 · 월 휠 ─────────────────────────────────────────────────────────
  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} 연 · 월 휠 — 요일 줄 + 6주(336) 자리에 Wheel Picker medium 7칸, 연 120 · 월 96',
      (tester) async {
        final c = _Check(
          mode,
          _spec.resolve({
            'selection': 'single',
            'visibleRange': 'month',
          }, 'enabled'),
          '${mode.name} wheel',
        );
        await _pump(
          tester,
          _host(mode, _calendar('single', continuous: false, wheel: true)),
        );
        await tester.pumpAndSettle();
        final area = _rect(tester, find.byKey(const ValueKey('date-wheel')));
        c.px('wheel.height', area.height);
        final wheel = _rect(tester, find.byKey(const ValueKey('wheel-root')));
        expect(wheel.height, 308, reason: '44 × 7');
        expect(
          wheel.center.dy,
          closeTo(area.center.dy, 0.01),
          reason: '위아래 14 씩',
        );
        final cols = tester
            .widgetList(find.byWidgetPredicate((w) => w is PWheelPickerColumn))
            .cast<PWheelPickerColumn<dynamic>>()
            .toList();
        expect(cols.map((c) => c.width), [120, 96]);
        expect(cols.map((c) => c.align), [
          PWheelPickerAlign.right,
          PWheelPickerAlign.left,
        ]);
        expect(cols.map((c) => c.loop), [false, true]);
        expect(
          tester.widget<PWheelPicker>(find.byType(PWheelPicker)).visibleItems,
          7,
        );
        c.measured.add('wheel.columns');
        // 바탕 — 달력과 같은 bg-layer-floating
        c.color(
          'wheel.background',
          tester
              .widget<ColoredBox>(find.byKey(const ValueKey('wheel-root')))
              .color,
        );
        // 열린 동안 이전 · 다음은 막힌다, 셰브론은 위로 돈다
        expect(
          tester
              .widget<AnimatedRotation>(
                find.byKey(const ValueKey('date-title-icon')),
              )
              .turns,
          0.5,
        );
        for (final b in tester.widgetList<PButton>(find.byType(PButton))) {
          expect(b.onPressed, isNull);
        }
        expect(c.failures, isEmpty, reason: c.failures.join('\n'));
      },
    );
  }

  // ── 날짜 상태 한 칸씩 ──────────────────────────────────────────────────
  // 웹의 hovered(마우스) · focused(키보드 링)는 앱에 없다 — hovered 의 색은 pressed 와 같은 값이라 누르는 동안의 칸으로 잰다
  const states = [
    'enabled',
    'pressed',
    'today',
    'selected',
    'inRange',
    'outside',
    'disabled',
    'readOnly',
  ];
  const elsewhereState = {'cell.cursor'};
  for (final mode in Brightness.values) {
    for (final state in states) {
      testWidgets('${mode.name} 날짜 칸 $state — 스펙 값이다', (tester) async {
        final title = '${mode.name} day $state';
        final combo = {'selection': 'range', 'visibleRange': 'month'};
        // pressed · hovered 는 같은 색이다
        final want = _spec.resolve(combo, state);
        final c = _Check(mode, want, title);
        final d = DateTime(2026, 10, 14);
        final stateObj = switch (state) {
          'today' => const PDatePickerDayState(today: true),
          'selected' => const PDatePickerDayState(selected: true),
          'inRange' => const PDatePickerDayState(inRange: true, complete: true),
          'disabled' => const PDatePickerDayState(disabled: true),
          'readOnly' => const PDatePickerDayState(
            selected: true,
            rangeStart: true,
            readOnly: true,
          ),
          _ => const PDatePickerDayState(),
        };
        await _pump(
          tester,
          _app(
            mode,
            Align(
              alignment: Alignment.topLeft,
              child: state == 'outside'
                  ? PDatePickerOutsideCell(
                      key: const ValueKey('cell'),
                      date: d,
                      width: 48,
                    )
                  : PDatePickerDayCell(
                      key: const ValueKey('cell'),
                      date: d,
                      state: stateObj,
                      label: _labels.day(d),
                      width: 48,
                      onTap: () {},
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        TestGesture? gesture;
        if (state == 'pressed') {
          gesture = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('cell'))),
          );
          await tester.pumpAndSettle();
        }
        final cell = find.byKey(const ValueKey('cell'));
        final text = tester
            .widget<Text>(
              find.descendant(of: cell, matching: find.byType(Text)),
            )
            .style!;
        c.color('dayLabel.foreground', text.color);
        c.typo('dayLabel.typography', text);
        c.weight('dayLabel.fontWeight', text);
        if (want['dayLabel.textDecoration'] != null) {
          c.measured.add('dayLabel.textDecoration');
          expect(
            text.decoration,
            TextDecoration.lineThrough,
            reason: '막힌 날은 취소선',
          );
        } else {
          expect(text.decoration, isNot(TextDecoration.lineThrough));
        }
        if (state == 'outside') {
          // 앞뒤 달 — 원 · 띠 없이 흐린 숫자, 누르지 못하고 보조 기술에 숨긴다
          expect(find.byKey(const ValueKey('date-day-visual')), findsNothing);
          c.measured.addAll(want.keys.where((k) => k.startsWith('dayVisual')));
        } else {
          final visual = find.descendant(
            of: cell,
            matching: find.byKey(const ValueKey('date-day-visual')),
          );
          final bg =
              ((tester.widget<AnimatedContainer>(visual).decoration!)
                      as BoxDecoration)
                  .color;
          c.color('dayVisual.background', bg);
          final box = tester.getSize(visual);
          c.px('dayVisual.size', box.width);
          expect(box.height, box.width);
          final animated = tester.widget<AnimatedContainer>(visual);
          c.px(
            'dayVisual.radius',
            (((animated.decoration!) as BoxDecoration).borderRadius!
                    as BorderRadius)
                .topLeft
                .x,
          );
          c.ms('dayVisual.transitionDuration', animated.duration);
          c.easing('dayVisual.transitionEasing', animated.curve);
          c.measured.add('dayVisual.transitionProperty');
        }
        if (state == 'inRange') {
          c.color(
            'rangeBand.background',
            tester
                .widget<ColoredBox>(
                  find
                      .descendant(of: cell, matching: find.byType(ColoredBox))
                      .first,
                )
                .color,
          );
          c.px(
            'rangeBand.height',
            tester
                .getSize(
                  find.descendant(
                    of: cell,
                    matching: find.byKey(const ValueKey('date-band-middle')),
                  ),
                )
                .height,
          );
        }
        // 커서 — pointer · not-allowed · default
        if (state != 'outside') {
          final cursor = tester
              .widgetList<MouseRegion>(
                find.descendant(of: cell, matching: find.byType(MouseRegion)),
              )
              .first
              .cursor;
          final expected = switch (want['cell.cursor']) {
            'pointer' => SystemMouseCursors.click,
            'not-allowed' => SystemMouseCursors.forbidden,
            _ => SystemMouseCursors.basic,
          };
          expect(
            cursor,
            expected,
            reason: 'cell.cursor ${want['cell.cursor']}',
          );
        }
        c.measured.add('cell.cursor');
        // 이 상태가 만지지 않는 값(공통)은 달력 전체 테스트가 잰다 — 칸 · 원 · 숫자 · 띠의 값만 본다
        c.coverage(elsewhereState, prefix: 'dayLabel');
        c.coverage(elsewhereState, prefix: 'dayVisual');
        // 기간 띠는 기간 사이 칸의 몫(그 칸에서 위에서 잰다) — 다른 칸에는 띠가 없다
        if (state != 'inRange') {
          c.measured.addAll(want.keys.where((k) => k.startsWith('rangeBand')));
          expect(
            find.descendant(
              of: cell,
              matching: find.byWidgetPredicate(
                (w) =>
                    w.key is ValueKey &&
                    '${(w.key! as ValueKey).value}'.startsWith('date-band-'),
              ),
            ),
            findsNothing,
          );
        }
        c.coverage(elsewhereState, prefix: 'rangeBand');
        await gesture?.up();
        expect(c.failures, isEmpty, reason: c.failures.join('\n'));
      });
    }
  }

  // ── 상태가 겹칠 때 ─────────────────────────────────────────────────────
  group('상태가 겹칠 때', () {
    Future<PDatePickerDayState> pump(
      WidgetTester tester,
      PDatePickerDayState s,
    ) async {
      await _pump(
        tester,
        _app(
          Brightness.light,
          Align(
            alignment: Alignment.topLeft,
            child: PDatePickerDayCell(
              key: const ValueKey('cell'),
              date: DateTime(2026, 10, 15),
              state: s,
              label: '15일',
              width: 48,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return s;
    }

    final light = PColors.light;
    Color? circle(WidgetTester tester) =>
        ((tester
                    .widget<AnimatedContainer>(
                      find.byKey(const ValueKey('date-day-visual')),
                    )
                    .decoration!)
                as BoxDecoration)
            .color;
    TextStyle label(WidgetTester tester) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('cell')),
            matching: find.byType(Text),
          ),
        )
        .style!;

    testWidgets('고름이 이긴다 — 오늘을 고르면 짙은 원이고 굵기는 남는다', (tester) async {
      await pump(
        tester,
        const PDatePickerDayState(today: true, selected: true),
      );
      expect(circle(tester), light.bgNeutralInverted);
      expect(label(tester).color, light.fgNeutralInverted);
      expect(label(tester).fontWeight, FontWeight.w700);
    });

    testWidgets('기간 안의 오늘은 원 없이 띠 위에 굵은 숫자', (tester) async {
      await pump(
        tester,
        const PDatePickerDayState(today: true, inRange: true, complete: true),
      );
      expect(circle(tester)!.a, 0);
      expect(find.byKey(const ValueKey('date-band-middle')), findsOneWidget);
      expect(label(tester).fontWeight, FontWeight.w700);
    });

    testWidgets('오늘인데 막힌 날은 원 없이 굵은 숫자 + 취소선', (tester) async {
      await pump(
        tester,
        const PDatePickerDayState(today: true, disabled: true),
      );
      expect(circle(tester)!.a, 0);
      expect(label(tester).fontWeight, FontWeight.w700);
      expect(label(tester).decoration, TextDecoration.lineThrough);
      expect(label(tester).color, light.fgDisabled);
    });

    testWidgets('고른 날인데 막힌 날은 고른 모양 + 취소선', (tester) async {
      await pump(
        tester,
        const PDatePickerDayState(selected: true, disabled: true),
      );
      expect(circle(tester), light.bgNeutralInverted);
      expect(label(tester).decoration, TextDecoration.lineThrough);
    });

    testWidgets('막힌 날이 기간 안에 있으면 띠는 그대로, 숫자만 흐린 취소선', (tester) async {
      await pump(
        tester,
        const PDatePickerDayState(
          inRange: true,
          disabled: true,
          complete: true,
        ),
      );
      expect(find.byKey(const ValueKey('date-band-middle')), findsOneWidget);
      expect(label(tester).decoration, TextDecoration.lineThrough);
    });

    testWidgets('미완성 기간의 시작일이 막힌 날이어도 시작 원 위에는 취소선을 긋지 않는다', (tester) async {
      await pump(
        tester,
        const PDatePickerDayState(
          selected: true,
          rangeStart: true,
          disabled: true,
        ),
      );
      expect(label(tester).decoration, isNot(TextDecoration.lineThrough));
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              '${(w.key! as ValueKey).value}'.startsWith('date-band-'),
        ),
        findsNothing,
        reason: '미완성 기간은 띠가 없다',
      );
    });

    testWidgets('하루짜리 기간은 띠가 없다', (tester) async {
      await pump(
        tester,
        const PDatePickerDayState(
          selected: true,
          rangeStart: true,
          rangeEnd: true,
          complete: true,
          singleDayRange: true,
        ),
      );
      expect(find.byKey(const ValueKey('date-band-start')), findsNothing);
      expect(find.byKey(const ValueKey('date-band-end')), findsNothing);
    });

    testWidgets(
      '누르는 동안 — 보통 날은 투명 짝, 오늘 · 기간 사이 날은 불투명 한 단계 짙은 색, 고른 날 · 막힌 날 · 읽기 전용은 그대로, 날짜는 줄지 않는다',
      (tester) async {
        Future<Color?> pressed(PDatePickerDayState s) async {
          await pump(tester, s);
          final size = tester.getSize(
            find.byKey(const ValueKey('date-day-visual')),
          );
          final g = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('cell'))),
          );
          await tester.pumpAndSettle();
          final c = circle(tester);
          expect(
            tester.getSize(find.byKey(const ValueKey('date-day-visual'))),
            size,
            reason: '날짜는 줄지 않는다',
          );
          await g.up();
          await tester.pumpAndSettle();
          return c;
        }

        // 보통 날은 투명 짝(03-C 결정 2B), 오늘 · 기간 사이 날은 불투명
        expect(
          await pressed(const PDatePickerDayState()),
          light.bgNeutralWeakAlphaPressed,
        );
        expect(
          await pressed(const PDatePickerDayState(today: true)),
          light.bgNeutralWeakPressed,
        );
        expect(
          await pressed(
            const PDatePickerDayState(inRange: true, complete: true),
          ),
          light.bgNeutralWeakPressed,
        );
        expect(
          await pressed(const PDatePickerDayState(selected: true)),
          light.bgNeutralInverted,
        );
        expect(
          (await pressed(const PDatePickerDayState(disabled: true)))!.a,
          0,
        );
        expect(
          await pressed(
            const PDatePickerDayState(
              selected: true,
              rangeStart: true,
              readOnly: true,
            ),
          ),
          light.strokeNeutralSolid,
        );
      },
    );
  });

  // ── 날짜 계산 ─────────────────────────────────────────────────────────
  group('날짜 도구 — 월 · 일 경계(로컬 시간대)', () {
    test(
      '한 달 더하기는 같은 날, 없으면 말일 — 1/31 + 1달 = 2/28(윤년 2/29), 3/31 − 1달 = 2/28',
      () {
        expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
        expect(addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
        expect(addMonths(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
        expect(addMonths(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
        expect(addMonths(DateTime(2026, 1, 15), -1), DateTime(2025, 12, 15));
        // 한 해 — 윤일에서 평년으로는 2월 28일
        expect(addMonths(DateTime(2028, 2, 29), 12), DateTime(2029, 2, 28));
        expect(addMonths(DateTime(2028, 2, 29), -12), DateTime(2027, 2, 28));
      },
    );

    test('하루 더하기는 월말 · 연말 · 윤일을 넘고 항상 그 날 0시다', () {
      expect(addDays(DateTime(2026, 10, 31), 1), DateTime(2026, 11, 1));
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
      expect(addDays(DateTime(2028, 2, 28), 1), DateTime(2028, 2, 29));
      expect(addDays(DateTime(2027, 2, 28), 1), DateTime(2027, 3, 1));
      expect(addDays(DateTime(2026, 1, 1), -1), DateTime(2025, 12, 31));
      final d = addDays(DateTime(2026, 3, 8, 23, 59), 1);
      expect([d.hour, d.minute], [0, 0], reason: '시각은 버린다(서머타임 · 하루 길이에 상관없이)');
    });

    test('그 달의 주 수 — 2026년 2월은 4주, 8월은 6주(토요일에 시작하는 31일), 2028년 2월은 5주', () {
      expect(weeksInMonth(2026, 2), 4);
      expect(weeksInMonth(2026, 8), 6);
      expect(weeksInMonth(2028, 2), 5);
      expect(weeksInMonth(2026, 10), 5);
      expect(daysInMonth(2028, 2), 29);
      expect(daysInMonth(2027, 2), 28);
      expect(daysInMonth(2100, 2), 28, reason: '100 의 배수는 윤년이 아니다');
      expect(daysInMonth(2000, 2), 29);
    });

    test('주는 일요일부터 — 일요일은 그 날, 토요일은 6일 뒤가 끝', () {
      // 2026-10-04 는 일요일
      expect(weekStart(DateTime(2026, 10, 4)), DateTime(2026, 10, 4));
      expect(weekEnd(DateTime(2026, 10, 4)), DateTime(2026, 10, 10));
      expect(weekStart(DateTime(2026, 10, 10)), DateTime(2026, 10, 4));
      expect(weekEnd(DateTime(2026, 10, 10)), DateTime(2026, 10, 10));
      expect(weekStart(DateTime(2026, 10, 15)), DateTime(2026, 10, 11));
      expect(weekdayIndex(DateTime(2026, 10, 4)), 0);
      expect(weekdayIndex(DateTime(2026, 10, 10)), 6);
    });

    test('키 글은 로컬 연 · 월 · 일이다 — UTC 로 읽지 않는다', () {
      expect(dayKey(DateTime(2026, 1, 1)), '2026-01-01');
      expect(dayKey(DateTime(2026, 1, 1, 0, 0)), '2026-01-01');
      expect(dayKey(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
      expect(
        startOfDay(DateTime(2026, 10, 15, 23, 59)),
        DateTime(2026, 10, 15),
      );
      expect(
        sameDay(DateTime(2026, 10, 15, 23, 59), DateTime(2026, 10, 15)),
        isTrue,
      );
      expect(
        compareDay(DateTime(2026, 10, 15, 23, 59), DateTime(2026, 10, 16)) < 0,
        isTrue,
      );
    });

    test('달 번호 — 연 × 12 + 월, 해를 넘어도 이어진다', () {
      expect(
        monthNumber(DateTime(2026, 10, 1)) - monthNumber(DateTime(2025, 10, 1)),
        12,
      );
      expect(
        fromMonthNumber(monthNumber(DateTime(2026, 12, 31)) + 1),
        DateTime(2027, 1),
      );
      expect(
        fromMonthNumber(monthNumber(DateTime(2026, 1, 1)) - 1),
        DateTime(2025, 12),
      );
    });
  });

  group('getPresetRange — 달력 단위(date-picker.md "빠른 기간")', () {
    final t = DateTime(2026, 10, 2);
    ({DateTime start, DateTime end}) r(PDatePreset p, [DateTime? today]) =>
        getPresetRange(p, today ?? t);

    test('스펙 표(오늘이 2026년 10월 2일) 그대로', () {
      expect(r(PDatePreset.thisWeek), (
        start: DateTime(2026, 9, 27),
        end: DateTime(2026, 10, 3),
      ));
      expect(r(PDatePreset.thisMonth), (
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 31),
      ));
      expect(r(PDatePreset.lastMonth), (
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      ));
      expect(r(PDatePreset.last7Days), (
        start: DateTime(2026, 9, 26),
        end: DateTime(2026, 10, 2),
      ));
      expect(r(PDatePreset.last30Days), (
        start: DateTime(2026, 9, 3),
        end: DateTime(2026, 10, 2),
      ));
      expect(r(PDatePreset.last3Months), (
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 10, 31),
      ));
      expect(r(PDatePreset.last6Months), (
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 10, 31),
      ));
      expect(r(PDatePreset.last1Year), (
        start: DateTime(2025, 11, 1),
        end: DateTime(2026, 10, 31),
      ));
      expect(r(PDatePreset.thisYear), (
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      ));
    });

    test('연초 — 지난 달은 작년 12월, 최근 3개월 · 1년은 작년으로 넘어간다', () {
      final jan = DateTime(2026, 1, 10);
      expect(r(PDatePreset.lastMonth, jan), (
        start: DateTime(2025, 12, 1),
        end: DateTime(2025, 12, 31),
      ));
      expect(r(PDatePreset.last3Months, jan), (
        start: DateTime(2025, 11, 1),
        end: DateTime(2026, 1, 31),
      ));
      expect(r(PDatePreset.last1Year, jan), (
        start: DateTime(2025, 2, 1),
        end: DateTime(2026, 1, 31),
      ));
      expect(r(PDatePreset.last7Days, jan), (
        start: DateTime(2026, 1, 4),
        end: jan,
      ));
    });

    test('윤년 2월 29일 — 이번 달은 29일까지, 지난 달은 1월 31일까지, 최근 1년은 작년 3월부터', () {
      final leap = DateTime(2028, 2, 29);
      expect(r(PDatePreset.thisMonth, leap), (
        start: DateTime(2028, 2, 1),
        end: DateTime(2028, 2, 29),
      ));
      expect(r(PDatePreset.lastMonth, leap), (
        start: DateTime(2028, 1, 1),
        end: DateTime(2028, 1, 31),
      ));
      expect(r(PDatePreset.last1Year, leap), (
        start: DateTime(2027, 3, 1),
        end: DateTime(2028, 2, 29),
      ));
      expect(r(PDatePreset.last30Days, leap), (
        start: DateTime(2028, 1, 31),
        end: leap,
      ));
    });

    test('월말 — 3월 31일의 지난 달은 2월 전체(말일이 28일이어도), 12월 31일의 이번 주는 일요일부터', () {
      expect(r(PDatePreset.lastMonth, DateTime(2026, 3, 31)), (
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 28),
      ));
      expect(r(PDatePreset.lastMonth, DateTime(2028, 3, 31)), (
        start: DateTime(2028, 2, 1),
        end: DateTime(2028, 2, 29),
      ));
      // 2026-12-31 은 목요일 — 주는 12월 27일(일) ~ 1월 2일(토)
      expect(r(PDatePreset.thisWeek, DateTime(2026, 12, 31)), (
        start: DateTime(2026, 12, 27),
        end: DateTime(2027, 1, 2),
      ));
      expect(r(PDatePreset.thisMonth, DateTime(2026, 12, 31)), (
        start: DateTime(2026, 12, 1),
        end: DateTime(2026, 12, 31),
      ));
    });

    test('일요일 · 토요일에 주의 경계가 맞는다', () {
      expect(r(PDatePreset.thisWeek, DateTime(2026, 10, 4)), (
        start: DateTime(2026, 10, 4),
        end: DateTime(2026, 10, 10),
      ));
      expect(r(PDatePreset.thisWeek, DateTime(2026, 10, 10)), (
        start: DateTime(2026, 10, 4),
        end: DateTime(2026, 10, 10),
      ));
    });

    test('오늘에 시각이 있어도 그 날로 셈한다 — 23:59 · 00:00', () {
      expect(
        r(PDatePreset.last7Days, DateTime(2026, 10, 2, 23, 59)),
        r(PDatePreset.last7Days, DateTime(2026, 10, 2, 0, 0)),
      );
      expect(
        r(PDatePreset.last7Days, DateTime(2026, 10, 2, 23, 59)).end,
        DateTime(2026, 10, 2),
      );
    });
  });

  group('칸에 넣는 글 — International Design v106', () {
    test('하루 — 올해는 "10월 15일 (목)", 다른 해는 연도를 붙인다', () {
      expect(formatDateValue(DateTime(2026, 10, 15), _today), '10월 15일 (목)');
      expect(formatDateValue(DateTime(2027, 1, 3), _today), '2027년 1월 3일 (일)');
      expect(
        formatDateValue(DateTime(2025, 12, 31), _today),
        '2025년 12월 31일 (수)',
      );
      expect(
        formatDateValue(DateTime(2028, 2, 29), _today),
        '2028년 2월 29일 (화)',
      );
      expect(formatDateValue(null, _today), '');
    });

    test(
      '하루 en — 올해는 "Thu, Oct 15", 다른 해는 "Sun, Jan 3, 2027"(웹 i18n.test.ts 와 같다)',
      () async {
        await initializeDateFormatting();
        final prev = Intl.defaultLocale;
        Intl.defaultLocale = 'en';
        addTearDown(() => Intl.defaultLocale = prev);
        expect(formatDateValue(DateTime(2026, 10, 15), _today), 'Thu, Oct 15');
        expect(
          formatDateValue(DateTime(2027, 1, 3), _today),
          'Sun, Jan 3, 2027',
        );
      },
    );

    test('기간 — 물결표를 앞뒤에 붙여 쓴다, 올해가 아닌 날이 끼면 양쪽에 연도, 끝이 없으면 빈 글', () {
      expect(
        formatRangeValue(
          PDateRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
          _today,
        ),
        '10월 1일~10월 31일',
      );
      expect(
        formatRangeValue(
          PDateRange(start: DateTime(2026, 9, 28), end: DateTime(2026, 10, 6)),
          _today,
        ),
        '9월 28일~10월 6일',
      );
      expect(
        formatRangeValue(
          PDateRange(start: DateTime(2026, 12, 28), end: DateTime(2027, 1, 3)),
          _today,
        ),
        '2026년 12월 28일~2027년 1월 3일',
      );
      expect(
        formatRangeValue(
          PDateRange(start: DateTime(2027, 3, 1), end: DateTime(2027, 3, 5)),
          _today,
        ),
        '2027년 3월 1일~2027년 3월 5일',
      );
      expect(
        formatRangeValue(PDateRange(start: DateTime(2026, 10, 1)), _today),
        '',
      );
      expect(formatRangeValue(null, _today), '');
    });

    test('monthAt — 이진 탐색, 경계는 다음 달', () {
      const heights = [100.0, 200.0, 150.0];
      const offsets = [0.0, 100.0, 300.0];
      expect(monthAt(offsets, heights, 0), 0);
      expect(monthAt(offsets, heights, 99.9), 0);
      expect(monthAt(offsets, heights, 100), 1);
      expect(monthAt(offsets, heights, 299), 1);
      expect(monthAt(offsets, heights, 300), 2);
      expect(monthAt(offsets, heights, 9999), 2);
    });
  });

  // ── 구조 · 읽는 말 ─────────────────────────────────────────────────────
  group('구조 · 읽는 말', () {
    testWidgets(
      '한 달은 늘 6주 — 4주짜리 2026년 2월 · 6주짜리 2026년 8월 · 윤달 2028년 2월 모두 칸 42, 이 달 날짜만 버튼',
      (tester) async {
        for (final (month, days) in [
          (DateTime(2026, 2), 28),
          (DateTime(2026, 8), 31),
          (DateTime(2028, 2), 29),
        ]) {
          await _pump(
            tester,
            _host(
              Brightness.light,
              PDatePicker.single(
                labels: _labels,
                inset: 0,
                value: month,
                today: _today,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(_cells(tester), 42, reason: '${month.year}-${month.month}');
          expect(find.byType(PDatePickerDayCell), findsNWidgets(days));
          expect(
            _rect(
              tester,
              find.byKey(
                ValueKey('date-grid-${month.year}-${pad2(month.month)}'),
              ),
            ).height,
            288,
          );
        }
      },
    );

    testWidgets(
      '앞뒤 달 날짜는 흐리게 보이기만 한다 — 눌러도 아무 일이 없고, 보조 기술에 숨기되 칸은 남겨 요일 짝을 지킨다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final calls = <DateTime>[];
        await _pump(
          tester,
          _host(
            Brightness.light,
            PDatePicker.single(
              labels: _labels,
              inset: 0,
              value: DateTime(2026, 10, 20),
              today: _today,
              onChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        // 2026년 10월 1일은 목요일 — 앞달 29 · 30 · 9월 27 ~ 30 이 흐리게
        final out = DateTime(2026, 9, 30);
        expect(_outside(out), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.descendant(of: _outside(out), matching: find.byType(Text)),
              )
              .style!
              .color,
          PColors.light.fgDisabled,
        );
        await _tap(tester, _outside(out));
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        expect(
          _rect(tester, _outside(out)).width,
          closeTo(312 / 7, 0.01),
          reason: '칸은 남는다',
        );
        expect(_rect(tester, _outside(out)).height, 48);
        expect(find.bySemanticsLabel('30'), findsNothing, reason: '숫자는 숨긴다');
        expect(find.bySemanticsLabel(_labels.day(out)), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets('날짜 버튼 이름은 "2026년 10월 15일 목요일", 고른 날 · 막힌 날 · 읽기 전용은 상태로 읽힌다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.range(
            labels: _labels,
            inset: 0,
            readOnlyStart: true,
            value: PDateRange(
              start: DateTime(2026, 10, 8),
              end: DateTime(2026, 10, 12),
            ),
            max: DateTime(2026, 10, 25),
            today: _today,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_day(DateTime(2026, 10, 15))),
        isSemantics(
          label: '2026년 10월 15일 목요일, 오늘', // 오늘은 이름 끝에 ", 오늘"
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      // 읽기 전용 시작일 — 이름 끝에 말이 붙고 비활성
      expect(
        tester.getSemantics(_day(DateTime(2026, 10, 8))),
        isSemantics(
          label: '2026년 10월 8일 목요일, 읽기 전용 시작일',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      // 시작 앞은 막힌 날 · 기간 사이는 선택됨
      expect(
        tester.getSemantics(_day(DateTime(2026, 10, 7))),
        isSemantics(
          label: '2026년 10월 7일 수요일',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(
        tester.getSemantics(_day(DateTime(2026, 10, 10))),
        isSemantics(
          label: '2026년 10월 10일 토요일',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_day(DateTime(2026, 10, 26))),
        isSemantics(
          label: '2026년 10월 26일 월요일',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('달력은 이름 있는 묶음 — 칸 라벨 · 기본 "날짜 선택", 요일은 읽는 이름("일요일")', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(labels: _labels, inset: 0, today: _today),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('날짜 선택'), findsOneWidget);
      expect(find.bySemanticsLabel('일요일'), findsOneWidget);
      expect(find.bySemanticsLabel('토요일'), findsOneWidget);
      expect(
        find.bySemanticsLabel('2026년 10월'),
        findsWidgets,
        reason: '제목 · 달 격자의 이름',
      );
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(
            labels: _labels,
            inset: 0,
            today: _today,
            semanticLabel: '일정 날짜',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('일정 날짜'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('글 한 벌을 바꿀 수 있다 — labels', (tester) async {
      final semantics = tester.ensureSemantics();
      final en = PDatePickerLabels(
        root: 'Date',
        previousMonth: 'Previous month',
        nextMonth: 'Next month',
        yearWheel: 'Year',
        monthWheel: 'Month',
        readOnlyRangeStart: 'read-only start',
        today: 'today',
        presets: 'Quick ranges',
        weekdays: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
        weekdaysLong: const [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        ],
        month: (y, m) => '$y-${pad2(m)}',
        day: (d) => dayKey(d),
        yearOption: (y) => '$y',
        monthOption: (m) => '$m',
        presetNames: {for (final p in PDatePreset.values) p: 'x'},
      );
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(labels: en, inset: 0, today: _today),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Previous month'), findsOneWidget);
      expect(find.bySemanticsLabel('Next month'), findsOneWidget);
      expect(find.bySemanticsLabel('Wednesday'), findsOneWidget);
      expect(find.bySemanticsLabel('2026-10-15, today'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('보이는 달이 바뀌면 제목이 "2026년 11월" 로 읽힌다(liveRegion)', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(labels: _labels, inset: 0, today: _today),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byType(PButton).at(1));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(const ValueKey('date-title'))),
        isSemantics(
          label: '2026년 11월',
          isButton: true,
          isLiveRegion: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('이전 · 다음 이름 "이전 달" · "다음 달", 제목은 펼침 상태를 알린다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(labels: _labels, inset: 0, today: _today),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('이전 달'), findsOneWidget);
      expect(find.bySemanticsLabel('다음 달'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('date-title'))),
        isSemantics(
          hasExpandedState: true,
          isExpanded: false,
          isButton: true,
          isLiveRegion: true,
          hasTapAction: true,
          label: '2026년 10월',
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('date-title')));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(const ValueKey('date-title'))),
        isSemantics(
          hasExpandedState: true,
          isExpanded: true,
          isButton: true,
          isLiveRegion: true,
          hasTapAction: true,
          label: '2026년 10월',
        ),
      );
      semantics.dispose();
    });

    testWidgets(
      '좁은 폭(320 화면) — 칸이 44 보다 좁으면 원을 칸 폭 − 2 로 줄이고 띠도 같이, 이웃 원이 겹치지 않는다',
      (tester) async {
        await _pump(
          tester,
          _host(
            Brightness.light,
            PDatePicker.range(
              labels: _labels,
              inset: 0,
              value: PDateRange(
                start: DateTime(2026, 10, 8),
                end: DateTime(2026, 10, 22),
              ),
              today: _today,
            ),
            width: 272,
          ),
        );
        await tester.pumpAndSettle();
        const cellW = 272 / 7;
        final a = _rect(tester, _visual(DateTime(2026, 10, 13)));
        final b = _rect(tester, _visual(DateTime(2026, 10, 14)));
        expect(a.width, closeTo(cellW - 2, 0.01));
        expect(b.left - a.right, closeTo(2, 0.01), reason: '이웃 원 사이 2');
        expect(
          _rect(tester, _band(DateTime(2026, 10, 13))).height,
          closeTo(cellW - 2, 0.01),
        );
        // 360 화면의 시트 — 312 폭이면 42 그대로(칸 44.57)
        await _pump(
          tester,
          _host(
            Brightness.light,
            PDatePicker.single(
              labels: _labels,
              inset: 0,
              value: DateTime(2026, 10, 20),
              today: _today,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_rect(tester, _visual(DateTime(2026, 10, 13))).width, 42);
      },
    );

    testWidgets('날짜가 긴 글자 크기에서도 칸 안에 들어간다 — 두 자리 숫자 2배', (tester) async {
      await _pump(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _host(
            Brightness.light,
            PDatePicker.single(
              labels: _labels,
              inset: 0,
              value: DateTime(2026, 10, 28),
              today: _today,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ── 달 옮기기 · 연 · 월 휠 ─────────────────────────────────────────────
  group('달 옮기기', () {
    PDatePicker single({DateTime? value, ({int start, int end})? years}) =>
        PDatePicker.single(
          labels: _labels,
          inset: 0,
          value: value,
          yearRange: years,
          today: _today,
        );

    testWidgets(
      '이전 · 다음은 한 달씩, 해를 넘고 늘 6주라 칸 수가 그대로다 · 열 때는 값이 든 달(없으면 오늘이 든 달)',
      (tester) async {
        await _pump(
          tester,
          _host(Brightness.light, single(value: DateTime(2026, 12, 31))),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('date-grid-2026-12')), findsOneWidget);
        await _tap(tester, find.byType(PButton).at(1));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('date-grid-2027-01')), findsOneWidget);
        expect(_cells(tester), 42);
        await _tap(tester, find.byType(PButton).at(0));
        await _tap(tester, find.byType(PButton).at(0));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('date-grid-2026-11')), findsOneWidget);
        // 비었으면 오늘이 든 달 — 오늘을 짚기만 한다(고른 것처럼 칠하지 않는다)
        await _pump(tester, _host(Brightness.light, single()));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('date-grid-2026-10')), findsOneWidget);
        expect(_stateOf(tester, _today).today, isTrue);
        expect(_stateOf(tester, _today).selected, isFalse);
      },
    );

    testWidgets('윤년 2월은 29일까지 버튼이 있다 — 2028년은 29일, 2027년은 28일', (tester) async {
      await _pump(
        tester,
        _host(Brightness.light, single(value: DateTime(2028, 2, 10))),
      );
      await tester.pumpAndSettle();
      expect(_day(DateTime(2028, 2, 29)), findsOneWidget);
      expect(find.byType(PDatePickerDayCell), findsNWidgets(29));
      await _pump(
        tester,
        _host(Brightness.light, single(value: DateTime(2027, 2, 10))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PDatePickerDayCell), findsNWidgets(28));
      expect(_day(DateTime(2027, 2, 28)), findsOneWidget);
    });

    testWidgets('연도 범위 끝에서 이전 · 다음이 막힌다 — yearRange', (tester) async {
      await _pump(
        tester,
        _host(
          Brightness.light,
          single(value: DateTime(2026, 1, 5), years: (start: 2026, end: 2027)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<PButton>(find.byType(PButton).at(0)).onPressed,
        isNull,
      );
      expect(
        tester.widget<PButton>(find.byType(PButton).at(1)).onPressed,
        isNotNull,
      );
      await _pump(
        tester,
        _host(
          Brightness.light,
          single(value: DateTime(2027, 12, 5), years: (start: 2026, end: 2027)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<PButton>(find.byType(PButton).at(1)).onPressed,
        isNull,
      );
      expect(
        tester.widget<PButton>(find.byType(PButton).at(0)).onPressed,
        isNotNull,
      );
      // 범위 밖 날짜는 막힌 날 — 12월 31일은 범위 안, 2028 은 달력에 없다
      expect(_stateOf(tester, DateTime(2027, 12, 31)).disabled, isFalse);
    });

    testWidgets('제목을 누르면 연 · 월 휠이 날짜 자리에 뜨고 이전 · 다음은 막힌다, 다시 누르면 고른 달로 옮긴다', (
      tester,
    ) async {
      await _pump(
        tester,
        _host(Brightness.light, single(value: DateTime(2026, 10, 20))),
      );
      await tester.pumpAndSettle();
      final before = _rect(
        tester,
        find.byKey(const ValueKey('date-root')),
      ).height;
      await _tap(tester, find.byKey(const ValueKey('date-title')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('date-wheel')), findsOneWidget);
      expect(
        find.byType(PDatePickerDayCell),
        findsNothing,
        reason: '휠이 날짜 자리를 덮는다',
      );
      expect(
        _rect(tester, find.byKey(const ValueKey('date-root'))).height,
        before,
        reason: '달력 높이는 그대로',
      );
      // 월 휠 — 키보드 Tab · ↓ 두 번째 칼럼으로
      final monthCol = find.byWidgetPredicate(
        (w) => w is PWheelPickerColumn && w.semanticLabel == '월',
      );
      await tester.drag(monthCol, const Offset(0, -44 * 2));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('date-title')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('date-wheel')), findsNothing);
      expect(
        find.byKey(const ValueKey('date-grid-2026-12')),
        findsOneWidget,
        reason: '10월에서 두 칸 → 12월',
      );
      expect(
        tester
            .widget<AnimatedRotation>(
              find.byKey(const ValueKey('date-title-icon')),
            )
            .turns,
        0,
      );
    });

    testWidgets('휠에서 연도를 옮기면 같은 달 · 다른 해로 간다 — 연 칼럼은 반복하지 않는다', (tester) async {
      await _pump(
        tester,
        _host(Brightness.light, single(value: DateTime(2026, 10, 20))),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('date-title')));
      await tester.pumpAndSettle();
      final yearCol = find.byWidgetPredicate(
        (w) => w is PWheelPickerColumn && w.semanticLabel == '연도',
      );
      await tester.drag(yearCol, const Offset(0, -44 * 3));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('date-title')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('date-grid-2029-10')), findsOneWidget);
    });

    testWidgets('휠을 열었다 그대로 닫으면 달은 그대로다', (tester) async {
      await _pump(
        tester,
        _host(Brightness.light, single(value: DateTime(2026, 10, 20))),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('date-title')));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('date-title')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('date-grid-2026-10')), findsOneWidget);
    });
  });

  // ── 하루 고르기 ───────────────────────────────────────────────────────
  group('하루 고르기', () {
    testWidgets(
      '누르면 고른다 — onChanged 는 그 날의 0시 DateTime, 다시 눌러도 풀리지 않고 다시 부르지 않는다',
      (tester) async {
        final calls = <DateTime>[];
        DateTime? value;
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) => _host(
              Brightness.light,
              PDatePicker.single(
                labels: _labels,
                inset: 0,
                value: value,
                today: _today,
                onChanged: (d) {
                  calls.add(d);
                  setState(() => value = d);
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _tap(tester, _day(DateTime(2026, 10, 21)));
        await tester.pumpAndSettle();
        expect(calls, [DateTime(2026, 10, 21)]);
        expect(calls.single.hour, 0);
        expect(_stateOf(tester, DateTime(2026, 10, 21)).selected, isTrue);
        await _tap(tester, _day(DateTime(2026, 10, 21)));
        await tester.pumpAndSettle();
        expect(calls, hasLength(1));
        expect(_stateOf(tester, DateTime(2026, 10, 21)).selected, isTrue);
        // 다른 날을 누르면 옮겨 간다
        await _tap(tester, _day(DateTime(2026, 10, 5)));
        await tester.pumpAndSettle();
        expect(calls.last, DateTime(2026, 10, 5));
        expect(_stateOf(tester, DateTime(2026, 10, 21)).selected, isFalse);
      },
    );

    testWidgets('값에 시각이 들어 있어도 그 날로 본다 — 23:59 · 00:00', (tester) async {
      for (final v in [
        DateTime(2026, 10, 20, 23, 59),
        DateTime(2026, 10, 20, 0, 0),
      ]) {
        await _pump(
          tester,
          _host(
            Brightness.light,
            PDatePicker.single(
              labels: _labels,
              inset: 0,
              value: v,
              today: _today,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_stateOf(tester, DateTime(2026, 10, 20)).selected, isTrue);
        expect(_stateOf(tester, DateTime(2026, 10, 19)).selected, isFalse);
        expect(_stateOf(tester, DateTime(2026, 10, 21)).selected, isFalse);
      }
    });

    testWidgets('오늘을 고르면 고른 모양 + 굵기는 남는다', (tester) async {
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(
            labels: _labels,
            inset: 0,
            value: _today,
            today: _today,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final s = _stateOf(tester, _today);
      expect([s.today, s.selected], [true, true]);
      expect(_circleColor(tester, _today), PColors.light.bgNeutralInverted);
      expect(_labelStyle(tester, _today).fontWeight, FontWeight.w700);
    });

    testWidgets(
      '고를 수 있는 범위 — min · max 밖은 막힌 날, 눌러도 무시. 시각이 있어도 그 날 단위(max 20일 23:59 면 20일은 고른다)',
      (tester) async {
        final calls = <DateTime>[];
        await _pump(
          tester,
          _host(
            Brightness.light,
            PDatePicker.single(
              labels: _labels,
              inset: 0,
              min: DateTime(2026, 10, 10, 18),
              max: DateTime(2026, 10, 20, 23, 59),
              today: _today,
              onChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final d in [
          DateTime(2026, 10, 9),
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 31),
        ]) {
          expect(_stateOf(tester, d).disabled, isTrue, reason: '$d');
          expect(_labelStyle(tester, d).decoration, TextDecoration.lineThrough);
          await _tap(tester, _day(d));
        }
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        for (final d in [DateTime(2026, 10, 10), DateTime(2026, 10, 20)]) {
          expect(_stateOf(tester, d).disabled, isFalse, reason: '$d');
        }
        await _tap(tester, _day(DateTime(2026, 10, 20)));
        expect(calls, [DateTime(2026, 10, 20)]);
      },
    );

    testWidgets('isDateDisabled — 그 밖의 막힌 날(주말 등)', (tester) async {
      final calls = <DateTime>[];
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(
            labels: _labels,
            inset: 0,
            today: _today,
            isDateDisabled: (d) => d.weekday >= DateTime.saturday,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 17))); // 토
      await _tap(tester, _day(DateTime(2026, 10, 18))); // 일
      expect(calls, isEmpty);
      await _tap(tester, _day(DateTime(2026, 10, 19))); // 월
      expect(calls, [DateTime(2026, 10, 19)]);
    });

    testWidgets('연도 범위 밖 날짜는 막힌 날 — yearRange 끝', (tester) async {
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.single(
            labels: _labels,
            inset: 0,
            today: _today,
            value: DateTime(2026, 1, 1),
            yearRange: (start: 2026, end: 2030),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 2026년 1월 달력의 앞달(2025년 12월 28 ~ 31)은 흐린 숫자일 뿐 버튼이 아니다
      expect(_outside(DateTime(2025, 12, 31)), findsOneWidget);
    });
  });

  // ── 기간 고르기 ───────────────────────────────────────────────────────
  group('기간 고르기', () {
    /// 값을 쥔 달력 — 고른 값을 받아 다시 넘긴다.
    Widget holder(
      List<PDateRange> calls, {
      PDateRange? initial,
      bool readOnlyStart = false,
      List<PDatePreset> presets = const [],
      DateTime? min,
      DateTime? max,
      DateTime? today,
      bool continuous = false,
      double? width,
    }) {
      PDateRange? value = initial;
      return StatefulBuilder(
        builder: (context, setState) => _host(
          Brightness.light,
          PDatePicker.range(
            labels: _labels,
            inset: 0,
            value: value,
            readOnlyStart: readOnlyStart,
            presets: presets,
            min: min,
            max: max,
            today: today ?? _today,
            visibleRange: continuous
                ? PDateVisibleRange.continuous
                : PDateVisibleRange.month,
            onChanged: (r) {
              calls.add(r);
              setState(() => value = r);
            },
          ),
          height: continuous ? 600 : null,
          width: width ?? 312,
        ),
      );
    }

    testWidgets('첫 탭이 시작, 시작 뒤의 날이 끝 — {start} 다음 {start, end}', (
      tester,
    ) async {
      final calls = <PDateRange>[];
      await _pump(tester, holder(calls));
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 8)));
      await tester.pumpAndSettle();
      expect(calls.last, PDateRange(start: DateTime(2026, 10, 8)));
      expect(
        find
            .byType(PDatePickerDayCell)
            .evaluate()
            .where((e) => (e.widget as PDatePickerDayCell).state.inRange),
        isEmpty,
        reason: '끝을 고르는 동안 미리 칠하지 않는다',
      );
      await _tap(tester, _day(DateTime(2026, 10, 12)));
      await tester.pumpAndSettle();
      expect(
        calls.last,
        PDateRange(start: DateTime(2026, 10, 8), end: DateTime(2026, 10, 12)),
      );
      expect(_stateOf(tester, DateTime(2026, 10, 10)).inRange, isTrue);
    });

    testWidgets('시작보다 앞을 누르면 그날이 새 시작이다(둘을 바꾸지 않는다)', (tester) async {
      final calls = <PDateRange>[];
      await _pump(tester, holder(calls));
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 12)));
      await _tap(tester, _day(DateTime(2026, 10, 8)));
      await tester.pumpAndSettle();
      expect(calls.last, PDateRange(start: DateTime(2026, 10, 8)));
      expect(calls.last.end, isNull);
    });

    testWidgets('같은 날을 두 번 누르면 하루짜리 기간 — 띠가 없다', (tester) async {
      final calls = <PDateRange>[];
      await _pump(tester, holder(calls));
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 12)));
      await _tap(tester, _day(DateTime(2026, 10, 12)));
      await tester.pumpAndSettle();
      expect(
        calls.last,
        PDateRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 12)),
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              '${(w.key! as ValueKey).value}'.startsWith('date-band-'),
        ),
        findsNothing,
      );
      expect(_stateOf(tester, DateTime(2026, 10, 12)).selected, isTrue);
    });

    testWidgets('기간이 완성된 뒤 다시 누르면 새로 시작한다', (tester) async {
      final calls = <PDateRange>[];
      await _pump(
        tester,
        holder(
          calls,
          initial: PDateRange(
            start: DateTime(2026, 10, 8),
            end: DateTime(2026, 10, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 20)));
      await tester.pumpAndSettle();
      expect(calls.last, PDateRange(start: DateTime(2026, 10, 20)));
      expect(_stateOf(tester, DateTime(2026, 10, 10)).inRange, isFalse);
    });

    testWidgets('띠 — 시작은 원 가운데부터 오른쪽, 사이는 칸 폭 전체, 끝은 왼쪽부터 원 가운데까지', (
      tester,
    ) async {
      await _pump(
        tester,
        holder(
          [],
          initial: PDateRange(
            start: DateTime(2026, 10, 8),
            end: DateTime(2026, 10, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const w = 312 / 7;
      final start = _rect(tester, _band(DateTime(2026, 10, 8)));
      final cell = _rect(tester, _day(DateTime(2026, 10, 8)));
      expect(start.left, closeTo(cell.center.dx, 0.01));
      expect(start.right, closeTo(cell.right, 0.01));
      final mid = _rect(tester, _band(DateTime(2026, 10, 10)));
      expect(mid.width, closeTo(w, 0.01));
      final end = _rect(tester, _band(DateTime(2026, 10, 12)));
      final endCell = _rect(tester, _day(DateTime(2026, 10, 12)));
      expect(end.left, closeTo(endCell.left, 0.01));
      expect(end.right, closeTo(endCell.center.dx, 0.01));
      expect(_stateOf(tester, DateTime(2026, 10, 10)).inRange, isTrue);
      expect(_stateOf(tester, DateTime(2026, 10, 8)).selected, isTrue);
      expect(_stateOf(tester, DateTime(2026, 10, 12)).selected, isTrue);
      expect(
        _circleColor(tester, DateTime(2026, 10, 10))!.a,
        0,
        reason: '사이 날은 원 없이 띠',
      );
    });

    testWidgets(
      '기간이 달을 넘는다 — 10월 28일 ~ 11월 3일: 10월 달력에서는 31일까지 띠, 뒤 달 흐린 날에는 띠가 없다 · 11월로 넘기면 1일부터',
      (tester) async {
        await _pump(
          tester,
          holder(
            [],
            initial: PDateRange(
              start: DateTime(2026, 10, 28),
              end: DateTime(2026, 11, 3),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final d in [28, 29, 30, 31]) {
          expect(
            _band(DateTime(2026, 10, d)),
            findsOneWidget,
            reason: '10월 $d일',
          );
        }
        // 11월 1 · 2 · 3 일은 10월 달력의 뒤 달 흐린 날 — 눌리지 않고 띠도 없다
        for (final d in [1, 2, 3]) {
          expect(_outside(DateTime(2026, 11, d)), findsOneWidget);
        }
        expect(
          find
              .byWidgetPredicate(
                (w) =>
                    w.key is ValueKey &&
                    '${(w.key! as ValueKey).value}'.startsWith('date-band-'),
              )
              .evaluate()
              .length,
          4,
        );
        await _tap(tester, find.byType(PButton).at(1));
        await tester.pumpAndSettle();
        expect(_band(DateTime(2026, 11, 1)), findsOneWidget);
        expect(_band(DateTime(2026, 11, 3)), findsOneWidget);
        expect(find.byKey(const ValueKey('date-band-end')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('date-band-start')),
          findsNothing,
          reason: '시작은 앞 달이다',
        );
        expect(_stateOf(tester, DateTime(2026, 11, 1)).inRange, isTrue);
      },
    );

    testWidgets(
      '해를 넘는 기간 · 윤일을 지나는 기간 — 12월 28일 ~ 1월 3일, 2월 28일 ~ 3월 1일(2028)',
      (tester) async {
        await _pump(
          tester,
          holder(
            [],
            initial: PDateRange(
              start: DateTime(2026, 12, 28),
              end: DateTime(2027, 1, 3),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('date-grid-2026-12')), findsOneWidget);
        expect(_stateOf(tester, DateTime(2026, 12, 31)).inRange, isTrue);
        expect(_stateOf(tester, DateTime(2026, 12, 28)).rangeStart, isTrue);
        await _tap(tester, find.byType(PButton).at(1));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('date-grid-2027-01')), findsOneWidget);
        expect(_stateOf(tester, DateTime(2027, 1, 3)).rangeEnd, isTrue);
        await _pump(
          tester,
          holder(
            [],
            initial: PDateRange(
              start: DateTime(2028, 2, 28),
              end: DateTime(2028, 3, 1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          _stateOf(tester, DateTime(2028, 2, 29)).inRange,
          isTrue,
          reason: '윤일은 사이 날',
        );
        expect(_stateOf(tester, DateTime(2028, 2, 28)).rangeStart, isTrue);
      },
    );

    testWidgets('기간이 열리는 달 — 값이 있으면 시작이 든 달, 없으면 오늘이 든 달', (tester) async {
      await _pump(
        tester,
        holder(
          [],
          initial: PDateRange(
            start: DateTime(2026, 8, 20),
            end: DateTime(2026, 9, 3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('date-grid-2026-08')), findsOneWidget);
      await _pump(tester, holder([]));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('date-grid-2026-10')), findsOneWidget);
    });

    testWidgets('읽기 전용 시작일 — 시작은 그대로, 뒤의 날만 끝이 되고 앞은 막힌 날', (tester) async {
      final calls = <PDateRange>[];
      await _pump(
        tester,
        holder(
          calls,
          readOnlyStart: true,
          initial: PDateRange(
            start: DateTime(2026, 10, 8),
            end: DateTime(2026, 10, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_stateOf(tester, DateTime(2026, 10, 8)).readOnly, isTrue);
      expect(_stateOf(tester, DateTime(2026, 10, 7)).disabled, isTrue);
      // 시작 · 앞의 날을 눌러도 무시
      await _tap(tester, _day(DateTime(2026, 10, 8)));
      await _tap(tester, _day(DateTime(2026, 10, 5)));
      expect(calls, isEmpty);
      // 끝 다시 누르면 무시, 다른 뒤의 날은 끝이 된다
      await _tap(tester, _day(DateTime(2026, 10, 12)));
      expect(calls, isEmpty);
      await _tap(tester, _day(DateTime(2026, 10, 20)));
      expect(calls, [
        PDateRange(start: DateTime(2026, 10, 8), end: DateTime(2026, 10, 20)),
      ]);
      // 읽기 전용 시작 원은 흐린 채움, 숫자는 inverted
      expect(
        _circleColor(tester, DateTime(2026, 10, 8)),
        PColors.light.strokeNeutralSolid,
      );
      expect(
        _labelStyle(tester, DateTime(2026, 10, 8)).color,
        PColors.light.fgNeutralInverted,
      );
    });

    testWidgets('미완성 기간의 시작이 막힌 날이어도 시작 원 위에는 취소선을 긋지 않는다', (tester) async {
      await _pump(
        tester,
        holder(
          [],
          initial: PDateRange(start: DateTime(2026, 10, 8)),
          max: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(_stateOf(tester, DateTime(2026, 10, 8)).disabled, isTrue);
      expect(
        _labelStyle(tester, DateTime(2026, 10, 8)).decoration,
        isNot(TextDecoration.lineThrough),
      );
      expect(
        _labelStyle(tester, DateTime(2026, 10, 9)).decoration,
        TextDecoration.lineThrough,
      );
    });

    testWidgets('막힌 날이 기간 안에 있어도 시작 · 끝이 고를 수 있으면 된다 — 주말은 막힌 날, 띠는 그대로', (
      tester,
    ) async {
      final calls = <PDateRange>[];
      PDateRange? value;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => _host(
            Brightness.light,
            PDatePicker.range(
              labels: _labels,
              inset: 0,
              today: _today,
              value: value,
              isDateDisabled: (d) => d.weekday >= DateTime.saturday,
              onChanged: (r) {
                calls.add(r);
                setState(() => value = r);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 5)));
      await _tap(tester, _day(DateTime(2026, 10, 16)));
      await tester.pumpAndSettle();
      expect(
        calls.last,
        PDateRange(start: DateTime(2026, 10, 5), end: DateTime(2026, 10, 16)),
      );
      expect(_stateOf(tester, DateTime(2026, 10, 10)).inRange, isTrue);
      expect(_stateOf(tester, DateTime(2026, 10, 10)).disabled, isTrue);
      expect(_band(DateTime(2026, 10, 10)), findsOneWidget);
    });
  });

  // ── 여러 날 ──────────────────────────────────────────────────────────
  group('여러 날', () {
    Widget holder(
      List<List<DateTime>> calls, {
      int? max,
      List<DateTime> initial = const [],
    }) {
      var value = initial;
      return StatefulBuilder(
        builder: (context, setState) => _host(
          Brightness.light,
          PDatePicker.multiple(
            labels: _labels,
            inset: 0,
            today: _today,
            value: value,
            maxSelectionCount: max,
            onChanged: (v) {
              calls.add(v);
              setState(() => value = v);
            },
          ),
        ),
      );
    }

    testWidgets('누를 때마다 고르고 풀린다 — 늘 날짜 순 · 겹침 없음 · 띠로 잇지 않는다', (tester) async {
      final calls = <List<DateTime>>[];
      await _pump(tester, holder(calls));
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 20)));
      await _tap(tester, _day(DateTime(2026, 10, 5)));
      await _tap(tester, _day(DateTime(2026, 10, 12)));
      await tester.pumpAndSettle();
      expect(calls.last, [
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 20),
      ]);
      await _tap(tester, _day(DateTime(2026, 10, 12)));
      await tester.pumpAndSettle();
      expect(calls.last, [DateTime(2026, 10, 5), DateTime(2026, 10, 20)]);
      expect(_stateOf(tester, DateTime(2026, 10, 12)).selected, isFalse);
      expect(
        _stateOf(tester, DateTime(2026, 10, 12)).inRange,
        isFalse,
        reason: '띠로 잇지 않는다',
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              '${(w.key! as ValueKey).value}'.startsWith('date-band-'),
        ),
        findsNothing,
      );
    });

    testWidgets('값에 겹친 날 · 시각이 있어도 한 날로 센다', (tester) async {
      await _pump(
        tester,
        holder(
          [],
          initial: [
            DateTime(2026, 10, 12, 9),
            DateTime(2026, 10, 12, 23, 59),
            DateTime(2026, 10, 3),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final selected = find
          .byType(PDatePickerDayCell)
          .evaluate()
          .where((e) => (e.widget as PDatePickerDayCell).state.selected);
      expect(selected, hasLength(2));
    });

    testWidgets('최대 개수에 닿으면 고르지 않은 날이 막힌 날이 된다 — 고른 날은 풀 수 있다', (tester) async {
      final calls = <List<DateTime>>[];
      await _pump(tester, holder(calls, max: 2));
      await tester.pumpAndSettle();
      await _tap(tester, _day(DateTime(2026, 10, 5)));
      await _tap(tester, _day(DateTime(2026, 10, 6)));
      await tester.pumpAndSettle();
      expect(_stateOf(tester, DateTime(2026, 10, 7)).disabled, isTrue);
      expect(
        _labelStyle(tester, DateTime(2026, 10, 7)).decoration,
        TextDecoration.lineThrough,
      );
      final n = calls.length;
      await _tap(tester, _day(DateTime(2026, 10, 7)));
      expect(calls.length, n, reason: '더 넣지 못한다');
      expect(_stateOf(tester, DateTime(2026, 10, 5)).disabled, isFalse);
      await _tap(tester, _day(DateTime(2026, 10, 5)));
      await tester.pumpAndSettle();
      expect(calls.last, [DateTime(2026, 10, 6)]);
      expect(
        _stateOf(tester, DateTime(2026, 10, 7)).disabled,
        isFalse,
        reason: '풀면 다시 고를 수 있다',
      );
    });
  });

  // ── 빠른 기간 ────────────────────────────────────────────────────────
  group('빠른 기간', () {
    const presets = [
      PDatePreset.thisWeek,
      PDatePreset.thisMonth,
      PDatePreset.lastMonth,
      PDatePreset.last3Months,
      PDatePreset.thisYear,
    ];

    Widget holder(
      List<PDateRange> calls, {
      PDateRange? initial,
      DateTime? min,
      DateTime? max,
      bool continuous = false,
      List<PDatePreset> list = presets,
    }) {
      var value = initial;
      return StatefulBuilder(
        builder: (context, setState) => _host(
          Brightness.light,
          PDatePicker.range(
            labels: _labels,
            inset: 0,
            today: _today,
            value: value,
            presets: list,
            min: min,
            max: max,
            visibleRange: continuous
                ? PDateVisibleRange.continuous
                : PDateVisibleRange.month,
            onChanged: (r) {
              calls.add(r);
              setState(() => value = r);
            },
          ),
          height: continuous ? 600 : null,
        ),
      );
    }

    Finder chip(String label) => find.byWidgetPredicate(
      (w) => w is PChipRadio<PDatePreset> && w.label == label,
    );

    testWidgets(
      '칩 줄은 이름 있는 묶음 · Chip outlineStrong medium — 누르면 그 기간을 칠하고 시작이 든 달로 옮긴다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final calls = <PDateRange>[];
        await _pump(tester, holder(calls));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('빠른 기간'), findsOneWidget);
        for (final c in tester.widgetList<PChipRadio<PDatePreset>>(
          find.byType(PChipRadio<PDatePreset>),
        )) {
          expect(c.variant, PChipVariant.outlineStrong);
          expect(c.size, PChipSize.medium);
        }
        await _tap(tester, chip('지난 달'));
        await tester.pumpAndSettle();
        expect(
          calls.last,
          PDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
        );
        expect(
          find.byKey(const ValueKey('date-grid-2026-09')),
          findsOneWidget,
          reason: '시작이 든 달로',
        );
        expect(_stateOf(tester, DateTime(2026, 9, 15)).inRange, isTrue);
        // 칩 사이 8 · 칩 줄 ↔ 머리 12
        final chips = find.byType(PChipRadio<PDatePreset>);
        expect(
          tester.getRect(chips.at(1)).left - tester.getRect(chips.at(0)).right,
          8,
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('date-header'))).top -
              tester.getRect(chips.last).bottom,
          closeTo(12, 0.01),
        );
        semantics.dispose();
      },
    );

    testWidgets('이번 주는 일요일부터 · 이번 달은 1일 ~ 말일 · 최근 3개월은 석 달 전체(앞으로의 날도 든다)', (
      tester,
    ) async {
      final calls = <PDateRange>[];
      await _pump(tester, holder(calls));
      await tester.pumpAndSettle();
      await _tap(tester, chip('이번 주'));
      await tester.pumpAndSettle();
      expect(
        calls.last,
        PDateRange(start: DateTime(2026, 10, 11), end: DateTime(2026, 10, 17)),
      );
      await _tap(tester, chip('이번 달'));
      await tester.pumpAndSettle();
      expect(
        calls.last,
        PDateRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
      );
      await _tap(tester, chip('최근 3개월'));
      await tester.pumpAndSettle();
      expect(
        calls.last,
        PDateRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 10, 31)),
      );
      expect(find.byKey(const ValueKey('date-grid-2026-08')), findsOneWidget);
    });

    testWidgets(
      '달력에서 다른 날을 누르면 칩 고름이 풀린다 · 처음 그릴 때 값이 어느 칩의 범위와 같으면 그 칩이 골라져 있다',
      (tester) async {
        final calls = <PDateRange>[];
        await _pump(
          tester,
          holder(
            calls,
            initial: PDateRange(
              start: DateTime(2026, 10, 1),
              end: DateTime(2026, 10, 31),
            ),
          ),
        );
        await tester.pumpAndSettle();
        bool checked(String label) =>
            tester
                .widget<PChipRadioGroup<PDatePreset>>(
                  find.byType(PChipRadioGroup<PDatePreset>),
                )
                .value ==
            presets.firstWhere((p) => _labels.presetNames[p] == label);
        expect(checked('이번 달'), isTrue);
        await _tap(tester, _day(DateTime(2026, 10, 20)));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PChipRadioGroup<PDatePreset>>(
                find.byType(PChipRadioGroup<PDatePreset>),
              )
              .value,
          isNull,
        );
        // 다시 칩을 누르면 골라진다
        await _tap(tester, chip('이번 달'));
        await tester.pumpAndSettle();
        expect(checked('이번 달'), isTrue);
      },
    );

    testWidgets('값이 바뀌어 그 범위가 아니게 되면 칩 고름이 풀린다(초기화 등)', (tester) async {
      Widget build(PDateRange? v) => _host(
        Brightness.light,
        PDatePicker.range(
          labels: _labels,
          inset: 0,
          today: _today,
          value: v,
          presets: presets,
          onChanged: (_) {},
        ),
      );
      await _pump(
        tester,
        build(
          PDateRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PChipRadioGroup<PDatePreset>>(
              find.byType(PChipRadioGroup<PDatePreset>),
            )
            .value,
        PDatePreset.thisMonth,
      );
      await _pump(tester, build(null));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PChipRadioGroup<PDatePreset>>(
              find.byType(PChipRadioGroup<PDatePreset>),
            )
            .value,
        isNull,
      );
    });

    testWidgets(
      '고를 수 있는 범위 밖에 걸친 기간의 칩은 막는다 — 잘라서 넣지 않는다 · 사이에 막힌 날이 있는 칩은 괜찮다',
      (tester) async {
        final calls = <PDateRange>[];
        await _pump(tester, holder(calls, max: DateTime(2026, 10, 20)));
        await tester.pumpAndSettle();
        bool enabled(String label) =>
            tester.widget<PChipRadio<PDatePreset>>(chip(label)).enabled;
        expect(enabled('이번 달'), isFalse, reason: '10월 31일이 max 밖');
        expect(enabled('이번 주'), isTrue, reason: '10월 17일은 max 안');
        expect(enabled('지난 달'), isTrue);
        expect(enabled('최근 3개월'), isFalse);
        expect(enabled('올해'), isFalse);
        await _tap(tester, chip('이번 달'));
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        // 사이의 막힌 날은 괜찮다
        await _pump(
          tester,
          _host(
            Brightness.light,
            PDatePicker.range(
              labels: _labels,
              inset: 0,
              today: _today,
              presets: const [PDatePreset.thisMonth],
              isDateDisabled: (d) => d.day == 15,
              onChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<PChipRadio<PDatePreset>>(chip('이번 달')).enabled,
          isTrue,
        );
      },
    );

    testWidgets(
      'scroll 은 한 줄 가로 스크롤(시트의 이어지는 달) · wrap 은 줄바꿈(한 달) — 하루 · 여러 날 달력에는 칩 줄이 없다',
      (tester) async {
        await _pump(tester, holder([], continuous: true));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PChipRadioGroup<PDatePreset>>(
                find.byType(PChipRadioGroup<PDatePreset>),
              )
              .layout,
          PChipGroupLayout.scroll,
        );
        await _pump(tester, holder([]));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PChipRadioGroup<PDatePreset>>(
                find.byType(PChipRadioGroup<PDatePreset>),
              )
              .layout,
          PChipGroupLayout.wrap,
        );
        await _pump(
          tester,
          _host(
            Brightness.light,
            PDatePicker.single(labels: _labels, inset: 0, today: _today),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PChipRadioGroup<PDatePreset>), findsNothing);
      },
    );

    testWidgets('이어지는 달에서 칩을 누르면 그 달로 스크롤한다', (tester) async {
      final calls = <PDateRange>[];
      await _pump(
        tester,
        holder(
          calls,
          continuous: true,
          list: const [PDatePreset.last3Months, PDatePreset.thisMonth],
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, chip('최근 3개월'));
      await tester.pumpAndSettle();
      expect(calls.last.start, DateTime(2026, 8, 1));
      expect(find.byKey(const ValueKey('date-grid-2026-08')), findsOneWidget);
      // 맨 위는 8월 달 이름
      final labelTop = tester
          .getRect(
            find.descendant(
              of: find.byKey(const ValueKey('date-month-${2026 * 12 + 7}')),
              matching: find.byKey(const ValueKey('date-month-label')),
            ),
          )
          .top;
      final weekdayBottom = tester
          .getRect(find.byKey(const ValueKey('date-weekdays')))
          .bottom;
      expect(labelTop, closeTo(weekdayBottom, 0.5));
    });
  });

  // ── 이어지는 달 ───────────────────────────────────────────────────────
  group('이어지는 달(continuous)', () {
    Widget calendar({
      PDateRange? value,
      void Function(PDateRange)? onChanged,
    }) => _host(
      Brightness.light,
      PDatePicker.range(
        labels: _labels,
        inset: 0,
        today: _today,
        value: value,
        visibleRange: PDateVisibleRange.continuous,
        onChanged: onChanged,
      ),
      height: 600,
    );

    testWidgets('머리 · 연 · 월 휠이 없고 달마다 그 달의 주 수 — 앞뒤 달 날짜는 비운다, 위아래로 이어진다', (
      tester,
    ) async {
      await _pump(tester, calendar());
      await tester.pumpAndSettle();
      // 10월(5주) 바로 아래가 11월(5주) — 달 이름 48 + 5 × 48 + 아래 16
      final oct = tester.getRect(
        find.byKey(const ValueKey('date-grid-2026-10')),
      );
      final nov = tester.getRect(
        find.byKey(const ValueKey('date-grid-2026-11')),
      );
      expect(oct.height, 240);
      expect(nov.top - oct.bottom, 16 + 48);
      expect(find.byKey(const ValueKey('date-title')), findsNothing);
      expect(_day(DateTime(2026, 10, 31)), findsOneWidget);
      expect(_day(DateTime(2026, 11, 1)), findsOneWidget);
    });

    testWidgets('보이는 달 ± 몇 달만 그린다 — 수백 달을 한꺼번에 그리지 않는다, 아래 안개 96', (
      tester,
    ) async {
      await _pump(tester, calendar());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('date-month-label')).evaluate().length,
        lessThan(8),
      );
      expect(find.byType(PDatePickerDayCell).evaluate().length, lessThan(300));
      expect(tester.getSize(find.byKey(const ValueKey('date-fog'))).height, 96);
      // 안개는 눌러도 아래가 눌린다(IgnorePointer)
    });

    testWidgets(
      '스크롤로 달을 넘기면 보이는 달이 바뀐다 — 맨 위 달이 liveRegion 으로 읽힌다 · 두 달에 걸친 기간을 고를 수 있다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final calls = <PDateRange>[];
        PDateRange? value;
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) => calendar(
              value: value,
              onChanged: (r) {
                calls.add(r);
                setState(() => value = r);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        // 10월(5주 · 240 + 16 + 48)에서 한 달 위로 → 11월이 맨 위
        await tester.drag(
          find.byKey(const ValueKey('date-scroll')),
          const Offset(0, -308),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('2026년 11월'), findsWidgets);
        // 10월 28일 ~ 11월 3일 — 두 달에 걸친 기간
        await tester.drag(
          find.byKey(const ValueKey('date-scroll')),
          const Offset(0, 200),
        );
        await tester.pumpAndSettle();
        await _tap(tester, _day(DateTime(2026, 10, 28)));
        await _tap(tester, _day(DateTime(2026, 11, 3)));
        await tester.pumpAndSettle();
        expect(
          calls.last,
          PDateRange(start: DateTime(2026, 10, 28), end: DateTime(2026, 11, 3)),
        );
        expect(_stateOf(tester, DateTime(2026, 10, 31)).inRange, isTrue);
        expect(_stateOf(tester, DateTime(2026, 11, 1)).inRange, isTrue);
        semantics.dispose();
      },
    );

    testWidgets('값이 있는 달에서 열린다 — 시작이 든 달이 맨 위', (tester) async {
      await _pump(
        tester,
        calendar(
          value: PDateRange(
            start: DateTime(2027, 3, 4),
            end: DateTime(2027, 3, 9),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final top = tester
          .getRect(find.byKey(const ValueKey('date-weekdays')))
          .bottom;
      final label = tester
          .getRect(
            find.descendant(
              of: find.byKey(ValueKey('date-month-${2027 * 12 + 2}')),
              matching: find.byKey(const ValueKey('date-month-label')),
            ),
          )
          .top;
      expect(label, closeTo(top, 0.5));
    });

    testWidgets('연도 범위 끝까지 스크롤해도 오류가 없다 — yearRange 2026 ~ 2026', (
      tester,
    ) async {
      await _pump(
        tester,
        _host(
          Brightness.light,
          PDatePicker.range(
            labels: _labels,
            inset: 0,
            today: _today,
            yearRange: (start: 2026, end: 2026),
            visibleRange: PDateVisibleRange.continuous,
          ),
          height: 600,
        ),
      );
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(const ValueKey('date-scroll')),
        const Offset(0, -5000),
        5000,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('date-grid-2026-12')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ── 시트에서 "완료" 로 넣는다 ───────────────────────────────────────────
  group('시트 — 고르는 동안 칸은 그대로, "완료" 로 넣는다', () {
    Widget opener(
      void Function(Future<Object?> Function()) bind,
      Future<Object?> Function(BuildContext) open,
    ) => _app(
      Brightness.light,
      Builder(
        builder: (context) => Center(
          child: GestureDetector(
            key: const ValueKey('open'),
            behavior: HitTestBehavior.opaque,
            onTap: () => open(context),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    testWidgets(
      '날짜 하나 — 고르기 전에는 "완료" 가 막히고, 고르면 넣고 닫힌다 · 바깥을 눌러 닫으면 버린다(null)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        DateTime? result;
        var closed = 0;
        await _pump(
          tester,
          opener((_) {}, (context) async {
            result = await showDatePickerSheet(context);
            closed++;
            return result;
          }),
        );
        await _tap(tester, find.byKey(const ValueKey('open')));
        await tester.pumpAndSettle();
        // 달력 폭 = 시트 폭 360 − 24 · 24 = 312, 칸 44.57
        expect(
          tester.getSize(find.byKey(const ValueKey('date-root'))).width,
          360,
        );
        expect(
          _rect(tester, _day(DateTime(2026, 10, 13))).width,
          closeTo(312 / 7, 0.01),
        );
        expect(
          _rect(tester, _day(DateTime(2026, 10, 13))).left,
          closeTo(24 + (312 / 7) * 2, 0.01),
        );
        final done = findWidgetWithText(PButton, '완료');
        expect(
          tester.widget<PButton>(done).onPressed,
          isNull,
          reason: '하루를 고르기 전에는 막힌다',
        );
        // 오늘이 든 달 — 오늘을 짚기만 한다
        expect(_stateOf(tester, _today).selected, isFalse);
        await _tap(tester, _day(DateTime(2026, 10, 21)));
        await tester.pumpAndSettle();
        expect(tester.widget<PButton>(done).onPressed, isNotNull);
        expect(result, isNull, reason: '고르는 동안 칸 값은 그대로');
        await _tap(tester, done);
        await tester.pumpAndSettle();
        expect(result, DateTime(2026, 10, 21));
        expect(closed, 1);

        // 바깥을 눌러 닫으면 버린다
        result = DateTime(2000);
        await _tap(tester, find.byKey(const ValueKey('open')));
        await tester.pumpAndSettle();
        await _tap(tester, _day(DateTime(2026, 10, 22)));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(180, 20));
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '기간 — 이어지는 달 + 칩 줄 + "초기화" · "완료", 끝을 고르기 전에는 "완료" 가 막힌다 · 시트 안에서 넘치지 않는다',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        PDateRange? result;
        await _pump(
          tester,
          opener((_) {}, (context) async {
            result = await showRangePickerSheet(context);
            return result;
          }),
        );
        await _tap(tester, find.byKey(const ValueKey('open')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // 시트는 화면 높이의 90%(702) — 달력이 그 안을 채운다
        final sheet = tester.getRect(
          find.byKey(const ValueKey('p-bottom-sheet-root')),
        );
        expect(sheet.height, closeTo(780 * 0.9, 1));
        final done = findWidgetWithText(PButton, '완료');
        final reset = findWidgetWithText(PButton, '초기화');
        expect(tester.widget<PButton>(done).onPressed, isNull);
        await _tap(tester, _day(DateTime(2026, 10, 8)));
        await tester.pumpAndSettle();
        expect(
          tester.widget<PButton>(done).onPressed,
          isNull,
          reason: '끝을 고르기 전에는 막힌다',
        );
        await _tap(tester, _day(DateTime(2026, 10, 12)));
        await tester.pumpAndSettle();
        expect(tester.widget<PButton>(done).onPressed, isNotNull);
        // 초기화 — 고른 기간이 지워지고 "완료" 가 다시 막힌다
        await _tap(tester, reset);
        await tester.pumpAndSettle();
        expect(_stateOf(tester, DateTime(2026, 10, 8)).selected, isFalse);
        expect(tester.widget<PButton>(done).onPressed, isNull);
        // 빠른 기간 — 이번 달을 누르면 10월 전체가 칠해지고 "완료" 로 넣는다
        await _tap(
          tester,
          find.byWidgetPredicate(
            (w) => w is PChipRadio<PDatePreset> && w.label == '이번 달',
          ),
        );
        await tester.pumpAndSettle();
        expect(_stateOf(tester, DateTime(2026, 10, 1)).rangeStart, isTrue);
        expect(_stateOf(tester, DateTime(2026, 10, 31)).rangeEnd, isTrue);
        await _tap(tester, done);
        await tester.pumpAndSettle();
        expect(
          result,
          PDateRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
        );
      },
    );

    testWidgets('최소 / 최대 범위가 있는 시트 — 환불일은 거래일 ~ 오늘만', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        opener(
          (_) {},
          (context) => showDatePickerSheet(
            context,
            min: DateTime(2026, 10, 10),
            max: _today,
            title: '환불일',
          ),
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      expect(_stateOf(tester, DateTime(2026, 10, 9)).disabled, isTrue);
      expect(_stateOf(tester, DateTime(2026, 10, 10)).disabled, isFalse);
      expect(_stateOf(tester, DateTime(2026, 10, 15)).disabled, isFalse);
      expect(_stateOf(tester, DateTime(2026, 10, 16)).disabled, isTrue);
    });
  });

  // ── 견본 ─────────────────────────────────────────────────────────────
  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} — 견본이 상태 · 달력 · 가장 나쁜 값 · 시트 칸 · 날짜 + 시각을 모두 그린다(폰 폭 360)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pump(
          tester,
          _app(
            mode,
            const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: DatePickerDemo(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(
          math.max(1, find.byType(PDatePicker).evaluate().length),
          greaterThan(1),
        );
        await _pump(tester, const SizedBox());
      },
    );
  }
}

dynamic want(String key, Map<String, Object?> map) => map[key];
