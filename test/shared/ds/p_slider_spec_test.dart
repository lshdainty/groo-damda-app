// Slider 가 스펙 값대로인지 — 모드 × 눈금 × 상태 × 라이트 · 다크. 값은 test/fixtures/design_spec/slider.json,
// 웹은 같은 JSON 을 크로미움에서 잰다. 아래 behavior 묶음은 웹 slider.test.tsx 가 잡는 것(누르기 · 끌기 · 키보드 ·
// 접근성 · 막힘)을 앱 위젯으로 같이 잡는다.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/slider/p_slider.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';
import '../../support/plain_text.dart';

Widget _host(
  Brightness mode,
  Widget child, {
  double width = 320,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

/// 제어 값을 들고 있는 견본 — 바뀐 값 · 저장 횟수를 모은다.
class _Harness extends StatefulWidget {
  const _Harness({
    this.range = false,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.initial = 50,
    this.initialRange = (30, 70),
    this.disabled = false,
    this.label = '예산 알림 임계값',
    this.format,
  });

  final bool range;
  final double min;
  final double max;
  final double step;
  final double initial;
  final (double, double) initialRange;
  final bool disabled;
  final String label;
  final String Function(double)? format;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late double value = widget.initial;
  late (double, double) pair = widget.initialRange;
  final changes = <Object>[];
  final commits = <Object>[];

  @override
  Widget build(BuildContext context) {
    if (widget.range) {
      return PRangeSlider(
        label: widget.label,
        min: widget.min,
        max: widget.max,
        step: widget.step,
        values: pair,
        formatValue: widget.format,
        disabled: widget.disabled,
        onChanged: (v) => setState(() {
          pair = v;
          changes.add(v);
        }),
        onChangeEnd: commits.add,
      );
    }
    return PSlider(
      label: widget.label,
      min: widget.min,
      max: widget.max,
      step: widget.step,
      value: value,
      formatValue: widget.format,
      disabled: widget.disabled,
      onChanged: (v) => setState(() {
        value = v;
        changes.add(v);
      }),
      onChangeEnd: commits.add,
    );
  }
}

_HarnessState _state(WidgetTester tester) =>
    tester.state<_HarnessState>(find.byType(_Harness));

/// 고정폭 숫자 — 스펙의 numerals: tabular-nums.
void _tabular(SpecCheck check, String key, TextStyle style) {
  check.m([key]);
  if (check.want[key] != 'tabular-nums') return;
  final on = (style.fontFeatures ?? const []).any(
    (f) => f.feature == 'tnum' && f.value == 1,
  );
  if (!on) check.fail('$key: 스펙 tabular-nums · 실제 고정폭 숫자 아님');
}

final _track = find.byKey(const ValueKey('slider-track'));
Finder _dot(int i) => find.byKey(ValueKey('slider-thumb-dot-$i'));
FocusNode _focusNode(WidgetTester tester, int i) => tester
    .widget<Focus>(
      find
          .descendant(
            of: find.byKey(ValueKey('slider-thumb-$i')),
            matching: find.byType(Focus),
          )
          .first,
    )
    .focusNode!;

final _bubbleBox = find.byKey(const ValueKey('slider-bubble-box'));

/// 손잡이 줄(손잡이 줄 44 — 트랙을 깔고 있는 전체) 상자.
Rect _control(WidgetTester tester) => tester.getRect(_track);

double _centerX(WidgetTester tester, int i) => tester.getCenter(_dot(i)).dx;

// 애니메이션은 상태가 바뀐 다음 프레임에서 시작하므로 한 프레임을 먼저 그린 뒤 시간을 보낸다.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

dynamic _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_track).painter;

/// 이 묶음이 직접 재지 않고 동작 묶음 · 웹 전용이 맡는 스펙 값.
const _elsewhere = {
  'root.width', // 놓인 자리 폭 — 동작 묶음이 360 · 320 에서 본다
  'root.commit', // 손을 뗄 때 한 번 — 동작 묶음
  'control.cursor', // 마우스 모양 — _SliderPress 의 MouseRegion
  'control.touchTarget', // 44 × 폭 — control.height 와 같다
  'control.touchAction', // none — 줄 누름을 스크롤에 안 넘김(_EagerPointerRecognizer)
  'control.dragStart', // 150ms · 3px — 동작 묶음
  'tick.width', // sliderTickGaps 단위 테스트
  'tick.background', // 틈은 색이 아니라 구멍이다(표면이 비친다)
  'tick.backgroundOnFloating',
  'tick.position', // 단계 자리 — 동작 묶음
  'thumb.cursor', // 웹 전용(grab · grabbing)
  'thumb.inset', // sliderCenterOf — 동작 묶음이 끝 자리를 잰다
  'thumb.pageStep', // 10 — 키보드 동작 묶음
  'thumb.keyboard',
  'thumb.snap', // 단계 자리에만 섬 — 동작 묶음
  'thumb.name', // 접근성 동작 묶음
  'fill.span',
  'valueIndicator.clamp', // 트랙 끝에서 상자만 밀림 — 동작 묶음
  'valueIndicator.enterScale',
  'valueIndicator.enterOpacity',
  'valueIndicator.enterOffsetY',
  'valueIndicator.exitOpacity',
  'valueIndicator.exitOffsetY',
  'valueIndicator.target',
  'valueIndicator.arrowWidth', // 동작 묶음이 8 × 6 을 잰다
  'valueIndicator.arrowHeight',
  'markers.align',
  'markers.content',
  'headerValue.content',
  'headerValue.typography', // 머리 값 묶음이 잰다
  'headerValue.fontWeight',
  'headerValue.numerals',
  'headerValue.foreground',
  // 말풍선 글 · 색은 보이는 상태(pressed · focused)에서 잰다 — 숨김 상태는 없는 것을 본다
  'valueIndicator.background',
  'valueIndicator.foreground',
  'valueIndicator.typography',
  'valueIndicator.fontWeight',
  'valueIndicator.numerals',
  'headerValue.position',
};

void main() {
  final spec = DesignSpec.load('slider');

  group('스펙 값 — 모드 × 눈금 × 상태', () {
    for (final mode in Brightness.values) {
      for (final combo in spec.combos(['mode', 'ticks'])) {
        final range = combo['mode'] == 'range';
        final discrete = combo['ticks'] == 'discrete';
        for (final state in spec.states) {
          if (state == 'hovered') continue; // 마우스를 올려 보는 상태 — 웹 전용(앱은 손가락)
          testWidgets('${mode.name} · ${combo.values.join(' · ')} · $state', (
            tester,
          ) async {
            final want = spec.resolve(combo, state);
            final check = SpecCheck(mode, want, '${mode.name} $combo $state');
            final min = discrete ? 0.0 : 50.0;
            final max = discrete ? 100.0 : 100.0;
            final step = discrete ? 25.0 : 5.0;
            await tester.pumpWidget(
              _host(
                mode,
                _Harness(
                  range: range,
                  min: min,
                  max: max,
                  step: step,
                  initial: discrete ? 50 : 75,
                  initialRange: discrete ? (25, 75) : (60, 90),
                  disabled: state == 'disabled',
                  format: (v) => '${v.round()}%',
                ),
              ),
            );
            await _settle(tester);

            if (state == 'pressed') {
              await tester.startGesture(tester.getCenter(_dot(0)));
              await _settle(tester);
            } else if (state == 'focused') {
              // 키보드 포커스 — 키를 눌러 초점과 링 · 말풍선을 띄운다
              _focusNode(tester, 0).requestFocus();
              await tester.pump();
              await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
              await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
              await _settle(tester);
            }

            final c = _control(tester);
            final root = tester.getTopLeft(find.byType(_Harness));
            check.px('control.height', c.height);
            check.px('root.paddingTop', c.top - root.dy);
            // 표식 줄 — 손잡이 줄 아래 gap
            final markers = tester.getRect(
              find.byKey(const ValueKey('slider-markers')),
            );
            check.px('root.gap', markers.top - c.bottom);

            final painter = _painter(tester);
            check.color('track.background', painter.track as Color);
            check.color('fill.background', painter.fill as Color);
            check.px('track.height', 4);
            // 손잡이
            final thumbSize = tester.getSize(_dot(0));
            check.px('thumb.size', thumbSize.width);
            check.px('thumb.size', thumbSize.height);
            final deco =
                tester.widget<AnimatedContainer>(_dot(0)).decoration!
                    as BoxDecoration;
            check.color('thumb.background', deco.color!);
            if (deco.shape != BoxShape.circle) {
              check.fail('thumb.radius: 원이 아니다');
            }
            if (deco.border != null || deco.boxShadow != null) {
              check.fail('thumb.borderWidth · shadow: 없어야 한다');
            }
            // 표식 글 · 색
            final texts = tester.widgetList<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('slider-markers')),
                matching: find.byType(Text),
              ),
            );
            final expectedMarkers = discrete ? 5 : 2;
            if (texts.length != expectedMarkers) {
              check.fail('markers 수: 기대 $expectedMarkers · 실제 ${texts.length}');
            }
            for (final t in texts) {
              check.typo('markers.typography', t.style!);
              check.color('markers.foreground', t.style!.color!);
            }
            // 눈금 틈 — 구간 2 ~ 5 만, 폭 4, 단계 자리에 놓인다
            final gaps = sliderTickGaps(c.width, discrete ? 4 : 0);
            if (gaps.length != (discrete ? 3 : 0)) {
              check.fail('눈금 수: ${gaps.length}');
            }
            for (final g in gaps) {
              check.px('tick.width', g.width);
            }
            final intervals = sliderDiscreteIntervals(min, max, step);
            if (intervals != (discrete ? 4 : 0)) {
              check.fail('눈금 구간: $intervals');
            }
            // 말풍선 — 누름 · 포커스에만
            final shown = state == 'pressed' || state == 'focused';
            final bubbleVisible = tester.any(_bubbleBox);
            if (want['valueIndicator.display'] == '보임' && !bubbleVisible) {
              check.fail('valueIndicator: 보여야 한다');
            }
            if (want['valueIndicator.display'] == '숨김' && bubbleVisible) {
              check.fail('valueIndicator: 숨겨야 한다');
            }
            if (shown && bubbleVisible) {
              final box = tester.getRect(_bubbleBox);
              final style = tester
                  .widget<Text>(
                    find.descendant(
                      of: _bubbleBox,
                      matching: find.byType(Text),
                    ),
                  )
                  .style!;
              check.typo('valueIndicator.typography', style);
              check.weight('valueIndicator.fontWeight', style);
              _tabular(check, 'valueIndicator.numerals', style);
              check.color('valueIndicator.foreground', style.color!);
              final bd =
                  tester.widget<Container>(_bubbleBox).decoration!
                      as BoxDecoration;
              check.color('valueIndicator.background', bd.color!);
              check.px(
                'valueIndicator.radius',
                (bd.borderRadius! as BorderRadius).topLeft.x,
              );
              // 위아래 4 · 좌우 8 — 글자 상자와 바깥 상자의 차
              final textBox = tester.getRect(
                find.descendant(of: _bubbleBox, matching: find.byType(Text)),
              );
              check.px(
                'valueIndicator.paddingY',
                (box.height - textBox.height) / 2,
              );
              if (box.width > 24 + 1) {
                check.px(
                  'valueIndicator.paddingX',
                  (box.width - textBox.width) / 2,
                );
              }
              // 상자 아래 끝 ↔ 손잡이(20) 위 끝 = 12 — 상자는 손잡이 줄 위 끝에 닿는다
              check.px('valueIndicator.offsetY', c.center.dy - 10 - box.bottom);
            }
            if (state == 'focused') {
              final w =
                  (want['focusRing.width'] as num) +
                  (want['focusRing.offset'] as num);
              final ringBox = tester.getSize(
                find.byKey(const ValueKey('slider-ring-0')),
              );
              if (((ringBox.width - thumbSize.width) / 2 - w).abs() > 0.5) {
                check.fail(
                  'focusRing: 손잡이 둘레 ${(ringBox.width - thumbSize.width) / 2} · 스펙 $w',
                );
              }
              final ring =
                  (tester
                                  .widget<Container>(
                                    find.byKey(const ValueKey('slider-ring-0')),
                                  )
                                  .decoration!
                              as ShapeDecoration)
                          .shape
                      as CircleBorder;
              check.color('focusRing.color', ring.side.color);
              check.px('focusRing.width', ring.side.width);
              check.m(['focusRing.offset']);
            }
            check.m([
              'track.height',
              'valueIndicator.display',
              'thumb.borderWidth',
              'thumb.shadow',
              'thumb.radius',
              'track.radius',
              'valueIndicator.minWidth',
              'valueIndicator.paddingX',
              'valueIndicator.paddingY',
              'valueIndicator.radius',
              'valueIndicator.offsetY',
            ]);
            check.coverage(_elsewhere);
            expect(check.failures, isEmpty);
          });
        }
      }
    }
  });

  group('동작', () {
    Future<void> pump(
      WidgetTester tester,
      _Harness h, {
      Brightness mode = Brightness.light,
      double width = 320,
      TextDirection dir = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(_host(mode, h, width: width, direction: dir));
      await _settle(tester);
    }

    testWidgets('트랙을 짧게 누르면 가장 가까운 단계로 건너뛰고 손을 뗄 때 한 번 저장한다 — 말풍선은 안 뜬다', (
      tester,
    ) async {
      await pump(
        tester,
        const _Harness(min: 50, max: 100, step: 5, initial: 80),
      );
      final c = _control(tester);
      // 끝 자리 근처 — 단계에 맞춘다
      final x = c.left + sliderCenterOf(0.2, c.width) + 3;
      final g = await tester.startGesture(Offset(x, c.center.dy));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_state(tester).changes, [60.0]);
      expect(tester.any(_bubbleBox), isFalse);
      expect(_state(tester).commits, isEmpty);
      await g.up();
      await _settle(tester);
      expect(_state(tester).commits, [60.0]);
      expect(tester.any(_bubbleBox), isFalse);
      // 150ms 에 건너뛴 자리에 선다
      expect(
        _centerX(tester, 0),
        closeTo(c.left + sliderCenterOf(0.2, c.width), 0.5),
      );
    });

    testWidgets('손잡이 위아래 12 · 트랙 위아래 20 도 잡힌다(줄 44 전체가 누르는 자리)', (
      tester,
    ) async {
      await pump(tester, const _Harness(initial: 50));
      final c = _control(tester);
      final g = await tester.startGesture(Offset(c.left + 30, c.top + 2));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_state(tester).changes, isNotEmpty);
      await g.up();
      // 줄 밖(위 24 말풍선 자리)은 누르는 자리가 아니다
      final before = _state(tester).changes.length;
      final g2 = await tester.startGesture(Offset(c.left + 200, c.top - 6));
      await g2.up();
      expect(_state(tester).changes.length, before);
    });

    testWidgets('손잡이를 끌면 24 · 말풍선, 놓으면 한 번 저장한다 — 저장은 값이 바뀌었을 때만', (
      tester,
    ) async {
      await pump(
        tester,
        const _Harness(min: 50, max: 100, step: 5, initial: 80),
      );
      final c = _control(tester);
      final g = await tester.startGesture(tester.getCenter(_dot(0)));
      await _settle(tester);
      expect(tester.getSize(_dot(0)), const Size(24, 24));
      expect(_bubbleBox, findsOneWidget);
      await g.moveTo(
        Offset(c.left + sliderCenterOf(0.5, c.width), c.center.dy),
      );
      await g.moveTo(Offset(c.left + sliderCenterOf(0, c.width), c.center.dy));
      await _settle(tester);
      // 끄는 동안 화면만 따라간다 — 저장은 아직
      expect(_state(tester).changes.last, 50.0);
      expect(_state(tester).changes.length, greaterThan(1));
      expect(_state(tester).commits, isEmpty);
      await g.up();
      await _settle(tester);
      expect(_state(tester).commits, [50.0]);
      expect(tester.getSize(_dot(0)), const Size(20, 20));
      expect(tester.any(_bubbleBox), isFalse);

      // 눌렀다 그대로 떼면 저장하지 않는다
      final g2 = await tester.startGesture(tester.getCenter(_dot(0)));
      await _settle(tester);
      await g2.up();
      await _settle(tester);
      expect(_state(tester).commits, hasLength(1));
    });

    testWidgets('끝을 넘겨 끌어도 최솟값 · 최댓값에서 멈춘다', (tester) async {
      await pump(tester, const _Harness(initial: 50), width: 360);
      final c = _control(tester);
      final g = await tester.startGesture(tester.getCenter(_dot(0)));
      await g.moveTo(Offset(c.right + 200, c.center.dy));
      await _settle(tester);
      expect(_state(tester).value, 100);
      expect(_centerX(tester, 0), closeTo(c.right - 10, 0.5));
      await g.moveTo(Offset(c.left - 200, c.center.dy));
      await _settle(tester);
      expect(_state(tester).value, 0);
      expect(_centerX(tester, 0), closeTo(c.left + 10, 0.5));
      await g.up();
      expect(_state(tester).commits, [0.0]);
    });

    testWidgets('잡은 자리가 손가락 밑에 그대로 남는다(손잡이 가장자리를 잡아도 튀지 않는다)', (tester) async {
      await pump(tester, const _Harness(initial: 50));
      final start = tester.getCenter(_dot(0));
      final g = await tester.startGesture(start + const Offset(8, 0));
      await tester.pump();
      expect(_state(tester).changes, isEmpty);
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(_centerX(tester, 0), closeTo(start.dx + 40, 6));
      await g.up();
    });

    testWidgets('범위 — 두 손잡이는 서로를 넘지 않는다', (tester) async {
      await pump(
        tester,
        const _Harness(range: true, step: 10, initialRange: (30, 70)),
      );
      final c = _control(tester);
      final g = await tester.startGesture(tester.getCenter(_dot(0)));
      await g.moveTo(Offset(c.right - 10, c.center.dy));
      await _settle(tester);
      expect(_state(tester).pair, (70.0, 70.0));
      await g.up();
      expect(_state(tester).commits.last, (70.0, 70.0));
      // 같은 자리 — 첫 움직임의 방향으로 어느 손잡이인지 정한다
      final g2 = await tester.startGesture(tester.getCenter(_dot(0)));
      await g2.moveBy(const Offset(-60, 0));
      await _settle(tester);
      expect(_state(tester).pair.$1, lessThan(70));
      expect(_state(tester).pair.$2, 70);
      await g2.up();
    });

    testWidgets('범위 — 트랙을 누르면 가까운 손잡이가 건너뛴다', (tester) async {
      await pump(
        tester,
        const _Harness(range: true, step: 10, initialRange: (30, 70)),
      );
      final c = _control(tester);
      final g = await tester.startGesture(
        Offset(c.left + sliderCenterOf(0.8, c.width), c.center.dy + 10),
      );
      await g.up();
      expect(_state(tester).pair, (30.0, 80.0));
      expect(_state(tester).commits, [(30.0, 80.0)]);
    });

    testWidgets('막힘 — 누르기 · 키보드 모두 안 먹고 Tab 순서에서 빠진다', (tester) async {
      await pump(tester, const _Harness(disabled: true));
      final c = _control(tester);
      final g = await tester.startGesture(Offset(c.left + 100, c.center.dy));
      await g.up();
      expect(_state(tester).changes, isEmpty);
      expect(_focusNode(tester, 0).canRequestFocus, isFalse);
      expect(tester.any(_bubbleBox), isFalse);
    });

    testWidgets('요청 중이라고 막지 않는다 — 저장이 끝나기 전에도 계속 끌고 저장한다', (tester) async {
      await pump(tester, const _Harness(step: 5));
      final c = _control(tester);
      for (final ratio in [0.2, 0.4, 0.9]) {
        final g = await tester.startGesture(
          Offset(c.left + sliderCenterOf(ratio, c.width), c.center.dy),
        );
        await g.up();
      }
      expect(_state(tester).commits, hasLength(3));
    });

    group('키보드', () {
      Future<void> key(
        WidgetTester tester,
        LogicalKeyboardKey k, {
        bool shift = false,
      }) async {
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(k);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
      }

      testWidgets(
        '화살표 한 단계 · Shift · PageUp · PageDown 10단계 · Home · End — 키마다 한 번 저장',
        (tester) async {
          await pump(tester, const _Harness(initial: 50));
          _focusNode(tester, 0).requestFocus();
          await tester.pump();
          await key(tester, LogicalKeyboardKey.arrowRight);
          await key(tester, LogicalKeyboardKey.arrowUp);
          expect(_state(tester).value, 52);
          await key(tester, LogicalKeyboardKey.arrowLeft);
          await key(tester, LogicalKeyboardKey.arrowDown);
          expect(_state(tester).value, 50);
          await key(tester, LogicalKeyboardKey.arrowRight, shift: true);
          expect(_state(tester).value, 60);
          await key(tester, LogicalKeyboardKey.pageUp);
          expect(_state(tester).value, 70);
          await key(tester, LogicalKeyboardKey.pageDown);
          await key(tester, LogicalKeyboardKey.pageDown);
          expect(_state(tester).value, 50);
          await key(tester, LogicalKeyboardKey.end);
          expect(_state(tester).value, 100);
          // 끝에서는 값이 그대로라 저장하지 않는다
          final n = _state(tester).commits.length;
          await key(tester, LogicalKeyboardKey.arrowRight);
          await key(tester, LogicalKeyboardKey.pageUp);
          expect(_state(tester).commits.length, n);
          await key(tester, LogicalKeyboardKey.home);
          expect(_state(tester).value, 0);
          // 키 하나에 저장 한 번
          expect(_state(tester).commits.length, n + 1);
          // 포커스 중 — 링과 말풍선
          expect(find.byKey(const ValueKey('slider-ring-0')), findsOneWidget);
          expect(_bubbleBox, findsOneWidget);
        },
      );

      testWidgets('RTL 은 ← → 만 뒤집고 ↑ 는 늘 늘린다', (tester) async {
        await pump(tester, const _Harness(initial: 50), dir: TextDirection.rtl);
        _focusNode(tester, 0).requestFocus();
        await tester.pump();
        await key(tester, LogicalKeyboardKey.arrowRight);
        expect(_state(tester).value, 49);
        await key(tester, LogicalKeyboardKey.arrowLeft);
        expect(_state(tester).value, 50);
        await key(tester, LogicalKeyboardKey.arrowUp);
        expect(_state(tester).value, 51);
        // RTL — 값이 클수록 왼쪽
        final c = _control(tester);
        expect(
          _centerX(tester, 0),
          closeTo(c.right - sliderCenterOf(0.51, c.width), 0.5),
        );
      });

      testWidgets('범위 — Home · End 는 포커스한 손잡이를 다른 손잡이 값까지 옮긴다', (tester) async {
        await pump(
          tester,
          const _Harness(range: true, step: 10, initialRange: (30, 70)),
        );
        _focusNode(tester, 1).requestFocus();
        await tester.pump();
        await key(tester, LogicalKeyboardKey.home);
        expect(_state(tester).pair, (30.0, 30.0));
        _focusNode(tester, 0).requestFocus();
        await tester.pump();
        await key(tester, LogicalKeyboardKey.end);
        expect(_state(tester).pair, (30.0, 30.0));
        await key(tester, LogicalKeyboardKey.arrowRight);
        expect(_state(tester).pair, (30.0, 30.0));
      });

      testWidgets('손잡이마다 초점이 하나씩 — 범위는 둘', (tester) async {
        await pump(
          tester,
          const _Harness(range: true, step: 10, initialRange: (30, 70)),
        );
        expect(_focusNode(tester, 0).canRequestFocus, isTrue);
        expect(_focusNode(tester, 1).canRequestFocus, isTrue);
      });
    });

    group('접근성', () {
      testWidgets('손잡이가 이름 · 값 글 · 올림 · 내림 값을 읽는다 — 값은 이름 자리에 넣지 않는다', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          _Harness(
            min: 50,
            max: 100,
            step: 5,
            initial: 80,
            format: (v) => '${v.round()}%',
          ),
        );
        final node = tester.getSemantics(find.bySemanticsLabel('예산 알림 임계값'));
        final data = node.getSemanticsData();
        expect(data.label, '예산 알림 임계값');
        expect(data.value, '80%');
        expect(data.increasedValue, '85%');
        expect(data.decreasedValue, '75%');
        expect(data.flagsCollection.isSlider, isTrue);
        expect(data.hasAction(SemanticsAction.increase), isTrue);
        expect(data.hasAction(SemanticsAction.decrease), isTrue);
        // 표식 · 말풍선은 읽지 않는다 — 손잡이 하나만 슬라이더
        expect(find.bySemanticsLabel(RegExp('^50%\$')), findsNothing);
        tester.semantics.performAction(
          find.semantics.byLabel('예산 알림 임계값'),
          SemanticsAction.increase,
        );
        await tester.pump();
        expect(_state(tester).value, 85);
        expect(_state(tester).commits, [85.0]);
        tester.semantics.performAction(
          find.semantics.byLabel('예산 알림 임계값'),
          SemanticsAction.decrease,
        );
        await tester.pump();
        expect(_state(tester).value, 80);
        handle.dispose();
      });

      testWidgets('범위 — 손잡이마다 "{라벨} 최소" · "{라벨} 최대"', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          const _Harness(range: true, step: 10, label: '예산 사용률'),
        );
        expect(find.bySemanticsLabel('예산 사용률 최소'), findsOneWidget);
        expect(find.bySemanticsLabel('예산 사용률 최대'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('막힘 — 막힌 슬라이더로 읽히고 올리기 · 내리기가 없다', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, const _Harness(disabled: true));
        final data = tester
            .getSemantics(find.bySemanticsLabel('예산 알림 임계값'))
            .getSemanticsData();
        expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
        expect(data.hasAction(SemanticsAction.increase), isFalse);
        handle.dispose();
      });
    });

    group('눈금', () {
      test('구간 2 ~ 5 만 눈금 · 단계 표식, 6 이상이면 없다', () {
        expect(sliderDiscreteIntervals(1, 5, 1), 4);
        expect(sliderDiscreteIntervals(0, 100, 50), 2);
        expect(sliderDiscreteIntervals(0, 100, 20), 5);
        expect(sliderDiscreteIntervals(0, 100, 10), 0);
        expect(sliderDiscreteIntervals(50, 100, 5), 0);
        expect(sliderDiscreteIntervals(0, 1, 1), 0); // 구간 1 — 틈 없음
        expect(sliderDiscreteIntervals(0, 10, 3), 0); // 나누어떨어지지 않는다
      });

      test('틈은 양 끝을 뺀 단계 자리 가운데에, 폭 4', () {
        final gaps = sliderTickGaps(320, 4);
        expect(gaps, hasLength(3));
        for (var k = 0; k < 3; k++) {
          expect(gaps[k].width, 4);
          expect(gaps[k].center.dx, sliderCenterOf((k + 1) / 4, 320));
        }
      });

      testWidgets('손잡이는 단계 자리에만 서고 표식은 단계마다 둔다(별점 1 ~ 5)', (tester) async {
        await pump(
          tester,
          _Harness(min: 1, max: 5, initial: 3, format: (v) => '${v.round()}점'),
        );
        final c = _control(tester);
        final g = await tester.startGesture(tester.getCenter(_dot(0)));
        await g.moveTo(
          Offset(c.left + sliderCenterOf(0.75, c.width), c.center.dy),
        );
        await _settle(tester);
        expect(_state(tester).value, 4);
        await g.up();
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('slider-markers')),
            matching: findText('3점'),
          ),
          findsOneWidget,
        );
        // 표식 가운데 = 단계 자리 가운데
        final mid = tester.getCenter(
          find.descendant(
            of: find.byKey(const ValueKey('slider-markers')),
            matching: findText('3점'),
          ),
        );
        expect(mid.dx, closeTo(c.left + sliderCenterOf(0.5, c.width), 0.5));
      });
    });

    group('말풍선 · 머리 값', () {
      testWidgets('트랙 끝에서는 상자만 안으로 밀리고 화살표는 손잡이를 가리킨다', (tester) async {
        await pump(
          tester,
          _Harness(initial: 100, format: (v) => '${v.round()}%'),
          width: 360,
        );
        final c = _control(tester);
        final g = await tester.startGesture(tester.getCenter(_dot(0)));
        await _settle(tester);
        final box = tester.getRect(_bubbleBox);
        expect(box.right, lessThanOrEqualTo(c.right + 0.01));
        expect(box.left, greaterThanOrEqualTo(c.left - 0.01));
        final arrow = tester.getCenter(
          find.byKey(const ValueKey('slider-bubble-arrow')),
        );
        expect(arrow.dx, closeTo(_centerX(tester, 0), 0.5));
        // 화살표 8 × 6 — 상자 바로 아래, 손잡이 줄 위 끝에서 시작
        expect(
          tester.getSize(find.byKey(const ValueKey('slider-bubble-arrow'))),
          const Size(8, 6),
        );
        expect(
          tester
              .getTopLeft(find.byKey(const ValueKey('slider-bubble-arrow')))
              .dy,
          closeTo(c.top, 0.5),
        );
        await g.up();
        await _settle(tester);
        expect(tester.any(_bubbleBox), isFalse);
      });

      testWidgets('말풍선 위 24 안에서 라벨을 가리지 않는다 — 상자 위 끝이 루트 위 2 안쪽', (
        tester,
      ) async {
        await pump(tester, const _Harness(initial: 50));
        final g = await tester.startGesture(tester.getCenter(_dot(0)));
        await _settle(tester);
        final box = tester.getRect(_bubbleBox);
        final root = tester.getTopLeft(find.byType(_Harness));
        expect(box.top, closeTo(root.dy - 2, 0.5));
        expect(box.height, 26);
        await g.up();
      });

      testWidgets('모션 줄이기 — 크기 · 말풍선 이동 없이 투명도만', (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: _host(Brightness.light, const _Harness(initial: 50)),
          ),
        );
        await _settle(tester);
        final g = await tester.startGesture(tester.getCenter(_dot(0)));
        await tester.pump(const Duration(milliseconds: 50));
        final t = tester.widget<Transform>(
          find.ancestor(of: _bubbleBox, matching: find.byType(Transform)).first,
        );
        expect(t.transform.getMaxScaleOnAxis(), 1);
        await g.up();
      });

      for (final mode in Brightness.values) {
        testWidgets('${mode.name} — 머리 값 16 / 22 · 700 · 고정폭 숫자, 보조 기술에는 숨긴다', (
          tester,
        ) async {
          final check = SpecCheck(
            mode,
            spec.resolve({'mode': 'single', 'ticks': 'none'}, 'enabled'),
            'headerValue ${mode.name}',
          );
          await tester.pumpWidget(_host(mode, const PSliderValue('80%')));
          final style = tester.widget<Text>(findText('80%')).style!;
          check.typo('headerValue.typography', style);
          check.weight('headerValue.fontWeight', style);
          _tabular(check, 'headerValue.numerals', style);
          check.color('headerValue.foreground', style.color!);
          expect(check.failures, isEmpty);
          expect(
            find.ancestor(
              of: findText('80%'),
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
          );
          // 막힘 색
          await tester.pumpWidget(
            _host(mode, const PSliderValue('80%', disabled: true)),
          );
          final off =
              SpecCheck(
                mode,
                spec.resolve({'mode': 'single', 'ticks': 'none'}, 'disabled'),
                'headerValue disabled ${mode.name}',
              )..color(
                'headerValue.foreground',
                tester.widget<Text>(findText('80%')).style!.color!,
              );
          expect(off.failures, isEmpty);
        });
      }
    });

    group('가장 나쁜 값', () {
      for (final mode in Brightness.values) {
        testWidgets('${mode.name} · 폭 360 · 10 구간 · 끝값 — 넘치지 않는다', (
          tester,
        ) async {
          await pump(
            tester,
            _Harness(
              range: true,
              step: 10,
              initialRange: (0, 100),
              format: (v) => '${v.round()}%',
            ),
            mode: mode,
            width: 360,
          );
          expect(tester.takeException(), isNull);
          final c = _control(tester);
          expect(_centerX(tester, 0), closeTo(c.left + 10, 0.5));
          expect(_centerX(tester, 1), closeTo(c.right - 10, 0.5));
        });
      }

      testWidgets('한 단계 — 최솟값에서 한 단계 올린다', (tester) async {
        await pump(tester, const _Harness(initial: 0, step: 10));
        _focusNode(tester, 0).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        expect(_state(tester).value, 10);
      });

      testWidgets('소수 단계(0.1) — 부동소수 오차 없이 맞춘다', (tester) async {
        await pump(
          tester,
          const _Harness(min: 0, max: 1, step: 0.1, initial: 0.3),
        );
        _focusNode(tester, 0).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        expect(_state(tester).value, 0.4);
      });
    });
  });
}
