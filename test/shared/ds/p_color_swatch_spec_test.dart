// Color Swatch 가 스펙 값대로인지 — 색 10 × 고름 × 지금 색 · 자동 × 상태 × 라이트 · 다크. 값은
// test/fixtures/design_spec/color-swatch.json, 웹은 같은 JSON 을 크로미움에서 잰다. 올림(hovered)은 마우스를 올려 보는
// 상태라 웹 전용이다(앱은 손가락 — 모양이 바뀌지 않는다). 아래 동작 묶음은 웹 color-swatch.test.tsx 가 잡는 것(라디오 ·
// 키보드 · 지금 색 · 첫 안 쓴 색 · 대비 · 막힘 · 접근성)을 앱 위젯으로 같이 잡는다.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/color_swatch/p_color_swatch.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/tooltip/p_tooltip.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';

Widget _host(
  Brightness mode,
  Widget child, {
  double width = 360,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

/// 값을 들고 있는 견본.
class _Harness extends StatefulWidget {
  const _Harness({
    super.key,
    this.initial,
    this.currentColor,
    this.autoColor,
    this.disabled,
  });

  final PColorSwatchValue? initial;
  final Color? currentColor;
  final PChartColor? autoColor;
  final bool? disabled;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late PColorSwatchValue? value = widget.initial;
  final picks = <PColorSwatchValue>[];

  @override
  Widget build(BuildContext context) => PColorSwatchGroup(
    semanticLabel: '색상',
    value: value,
    currentColor: widget.currentColor,
    autoColor: widget.autoColor,
    disabled: widget.disabled,
    onChanged: (v) => setState(() {
      value = v;
      picks.add(v);
    }),
  );
}

_HarnessState _state(WidgetTester tester) =>
    tester.state<_HarnessState>(find.byType(_Harness));

Finder _cell(int i) => find.byKey(ValueKey('swatch-$i'));
Finder _paint(int i) =>
    find.descendant(of: _cell(i), matching: find.byType(CustomPaint)).first;
// 칸의 초점 노드 — 툴팁도 Focus 를 하나 두므로(노드 없음) 칸의 것(노드를 준 것)을 고른다
FocusNode _node(WidgetTester tester, int i) => tester
    .widgetList<Focus>(
      find.descendant(of: _cell(i), matching: find.byType(Focus)),
    )
    .firstWhere((f) => f.focusNode != null)
    .focusNode!;

const _gray = Color(0xFF9E9E9E);
final _colors = pColorSwatchOrder;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// 키보드 초점으로 만든다 — 키 이벤트가 먼저 있어야 초점 모드가 keyboard 가 된다.
Future<void> _keyboardFocus(WidgetTester tester, int i) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
  _node(tester, i).requestFocus();
  await _settle(tester);
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool settle = true,
}) async {
  await tester.sendKeyEvent(key);
  if (settle) await tester.pump();
}

void main() {
  final spec = DesignSpec.load('color-swatch');

  group('스펙 값 — 색 × 고름 × 지금 색 × 상태', () {
    for (final mode in Brightness.values) {
      for (final state in spec.states) {
        if (state == 'hovered') continue; // 마우스를 올려 보는 상태 — 웹 전용
        testWidgets('${mode.name} · $state', (tester) async {
          final failures = <String>[];
          for (final combo in spec.combos(['color', 'selected', 'current'])) {
            final color = PChartColor.values.byName(combo['color']!);
            final selected = combo['selected'] == 'selected';
            final current = combo['current']!;
            final want = spec.resolve(combo, state);
            final k = SpecCheck(mode, want, '${mode.name} $combo $state');
            await tester.pumpWidget(
              _host(
                mode,
                _Harness(
                  key: UniqueKey(),
                  initial: selected ? PColorSwatchValue.color(color) : null,
                  currentColor: current == 'custom' ? _gray : null,
                  autoColor: current == 'auto' ? PChartColor.brown : null,
                  disabled: state == 'disabled',
                ),
              ),
            );
            await _settle(tester);
            final offset = current == 'none' ? 0 : 1;
            final i = _colors.indexOf(color) + offset;
            final cell = _cell(i);
            TestGesture? held;

            if (state == 'pressed') {
              held = await tester.startGesture(tester.getCenter(cell));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 400));
              final scale = tester
                  .widget<AnimatedScale>(
                    find.descendant(
                      of: cell,
                      matching: find.byType(AnimatedScale),
                    ),
                  )
                  .scale;
              k.pressScale('swatch.scale', scale, 40);
              final anim = tester.widget<AnimatedScale>(
                find.descendant(of: cell, matching: find.byType(AnimatedScale)),
              );
              k.motion(
                'swatch.scaleDuration',
                'swatch.scaleEasing',
                anim.duration,
                anim.curve,
              );
            } else if (state == 'focused') {
              await _keyboardFocus(tester, i);
              final ring = tester.getSize(
                find.byKey(const ValueKey('swatch-focus-ring')),
              );
              final w =
                  (want['focusRing.offset'] as num) +
                  (want['focusRing.width'] as num);
              if ((ring.width - 40) / 2 != w) {
                k.fail('focusRing: 칸 둘레 ${(ring.width - 40) / 2} · 스펙 $w');
              }
              final border =
                  (tester
                              .widget<DecoratedBox>(
                                find.byKey(const ValueKey('swatch-focus-ring')),
                              )
                              .decoration
                          as BoxDecoration)
                      .border!
                      .top;
              k.color('focusRing.color', border.color);
              k.px('focusRing.width', border.width);
              k.m(['focusRing.offset']);
            }

            // 칸 — 원 40, 차트 색으로 꽉 채운다
            final box = tester.getRect(cell);
            k.px('swatch.size', box.width);
            k.px('swatch.size', box.height);
            final chart = color.of(
              mode == Brightness.dark ? PColors.dark : PColors.light,
            );
            k.color('swatch.background', chart);
            expect(
              tester.renderObject(_paint(i)),
              paints..circle(radius: 20, color: chart),
              reason: k.where,
            );
            k.m(['swatch.radius']);

            // 고름 — 고리 + 체크
            final ringFinder = find.descendant(
              of: cell,
              matching: find.byKey(const ValueKey('swatch-ring')),
            );
            final checkFinder = find.descendant(
              of: cell,
              matching: find.byKey(const ValueKey('swatch-check')),
            );
            final shown = selected;
            if ((want['check.display'] == '보임') != shown ||
                (want['ring.display'] == '보임') != shown) {
              k.fail('check · ring display 가 고름과 다르다');
            }
            if ((ringFinder.evaluate().isNotEmpty) != shown ||
                (checkFinder.evaluate().isNotEmpty) != shown) {
              k.fail('고른 칸의 고리 · 체크: 기대 $shown');
            }
            if (shown) {
              final ring = tester.getSize(ringFinder);
              final w =
                  (want['ring.outlineWidth'] as num) +
                  (want['ring.outlineOffset'] as num);
              if ((ring.width - 40) / 2 != w) {
                k.fail('ring: 칸 둘레 ${(ring.width - 40) / 2} · 스펙 $w');
              }
              final line =
                  (tester.widget<DecoratedBox>(ringFinder).decoration
                          as BoxDecoration)
                      .border!
                      .top;
              k.color('ring.outlineColor', line.color);
              k.px('ring.outlineWidth', line.width);
              k.m(['ring.outlineOffset']);
              k.px('check.size', tester.getSize(checkFinder).width);
              // 체크 선 2.5(24 칸 좌표 → 16 으로 줄어 1.667)와 색
              final checkWant = pickMode(want['check.color'], mode);
              expect(
                tester.renderObject(checkFinder),
                paints..path(
                  // 지금 색 칸의 체크는 대비가 큰 쪽 — 값이 색이 아니라 규칙이라 아래 동작 묶음이 잰다
                  color: checkWant is String && checkWant.startsWith('#')
                      ? specColor(checkWant)
                      : null,
                  // 24 칸 좌표의 2.5 가 16 으로 줄어 1.667(Paint 는 32비트 실수)
                  strokeWidth: Float32List.fromList([2.5 * 16 / 24])[0],
                ),
                reason: '${k.where} 체크',
              );
              k.m(['check.strokeWidth', 'check.color']);
            }
            k.m(['check.display', 'ring.display']);

            // 커서 — 막힘이면 금지
            final cursor = tester
                .widget<MouseRegion>(
                  find
                      .descendant(of: cell, matching: find.byType(MouseRegion))
                      .first,
                )
                .cursor;
            k.cursor('swatch.cursor', cursor);

            // 묶음 — 5 × 2, 사이 12, 폭 248
            final grid = tester.getRect(
              find.byKey(const ValueKey('swatch-grid')),
            );
            k.px('group.width', grid.width);
            k.px('group.columns', 5);
            final a = tester.getRect(_cell(offset));
            final b = tester.getRect(_cell(offset + 1));
            final below = tester.getRect(_cell(offset + 5));
            k.px('group.gap', b.left - a.right);
            k.px('group.gap', below.top - a.bottom);
            if (below.left != a.left) k.fail('둘째 줄은 첫 칸 아래에서 시작한다');
            k.m(['group.columns', 'group.order']);

            // 지금 색 · 자동 칸
            if (current != 'none') {
              final cur = tester.getRect(_cell(0));
              k.px('current.size', cur.width);
              final fill = current == 'custom'
                  ? _gray
                  : PChartColor.brown.of(
                      mode == Brightness.dark ? PColors.dark : PColors.light,
                    );
              expect(
                tester.renderObject(_paint(0)),
                paints..circle(radius: 20, color: fill),
                reason: '${k.where} 지금 색',
              );
              if (current == 'auto') {
                // 점선 2px — 둘레를 끊어 그린다
                expect(
                  tester.renderObject(_paint(0)),
                  paints
                    ..circle()
                    ..path(
                      style: PaintingStyle.stroke,
                      strokeWidth: (want['current.borderWidth'] as num)
                          .toDouble(),
                      color: specColor(
                        pickMode(want['current.borderColor'], mode),
                      ),
                    ),
                  reason: '${k.where} 점선',
                );
                k.m([
                  'current.borderWidth',
                  'current.borderColor',
                  'current.borderStyle',
                ]);
              }
              final label = tester.widget<Text>(
                find.byKey(const ValueKey('swatch-current-label')),
              );
              final labelBox = tester.getRect(
                find.byKey(const ValueKey('swatch-current-label')),
              );
              k.typo('currentLabel.typography', label.style!);
              k.color('currentLabel.foreground', label.style!.color!);
              k.px('currentLabel.marginTop', labelBox.top - cur.bottom);
              final name = current == 'custom' ? '지금 색' : '자동';
              if (label.data != name) k.fail('current.name: ${label.data}');
              // 선 — 폭 360 이라 옆으로(≥ 321), 지금 색 ↔ 선 ↔ 격자 사이 16
              final div = tester.getRect(
                find.byKey(const ValueKey('swatch-divider')),
              );
              k.px('divider.width', div.width);
              // 지금 색 칸 열 — 글이 칸(40)보다 넓으면 열이 그만큼 넓다(웹 flex-col 과 같다)
              final column = tester.getRect(
                find.byKey(const ValueKey('swatch-current-column')),
              );
              k.px('divider.gap', div.left - column.right);
              k.px('divider.gap', grid.left - div.right);
              final divBox = tester
                  .widget<Container>(
                    find.byKey(const ValueKey('swatch-divider')),
                  )
                  .color!;
              k.color('divider.color', divBox);
              k.m([
                'current.background',
                'current.name',
                'divider.stackBelow',
                'current.size',
                'check.color',
              ]);
            }
            k.coverage({
              'swatch.name', // 색 이름 — 접근성 묶음
              'swatch.tooltip', // 툴팁 — 동작 묶음
              'swatch.touchTarget', // 44 — 동작 묶음
              'group.keyboard', // 키보드 — 동작 묶음
              // 고른 칸에서만 그려진다
              if (!selected) ...[
                'check.size',
                'check.strokeWidth',
                'check.color',
                'ring.outlineWidth',
                'ring.outlineOffset',
                'ring.outlineColor',
              ],
              // 지금 색 · 자동 칸이 있을 때만 그려진다
              if (current == 'none') ...[
                'currentLabel.typography',
                'currentLabel.foreground',
                'currentLabel.marginTop',
                'divider.width',
                'divider.color',
                'divider.gap',
                'divider.stackBelow',
              ],
            });
            // 누른 채 잰 뒤 놓는다 — 놓으면 고르기가 된다
            await held?.cancel();
            failures.addAll(k.failures);
          }
          expect(failures.toSet().toList(), isEmpty);
        });
      }
    }
  });

  group('동작', () {
    const red = PColorSwatchValue.color(PChartColor.red);
    const blue = PColorSwatchValue.color(PChartColor.blue);
    const current = PColorSwatchValue.current();

    Future<void> pump(
      WidgetTester tester,
      _Harness h, {
      Brightness mode = Brightness.light,
      double width = 360,
      TextDirection dir = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(_host(mode, h, width: width, direction: dir));
      await _settle(tester);
    }

    testWidgets('고르면 한 번 알리고, 고른 칸을 다시 누르면 알리지 않는다(라디오)', (tester) async {
      await pump(tester, const _Harness(initial: red));
      await tester.tap(_cell(4));
      await tester.pump();
      expect(_state(tester).picks, [blue]);
      await tester.tap(_cell(4));
      await tester.pump();
      expect(_state(tester).picks, [blue]);
    });

    test('색상환 차례 · 색 이름', () {
      expect(pColorSwatchOrder.map((c) => c.name), [
        'red',
        'orange',
        'yellow',
        'green',
        'blue',
        'indigo',
        'violet',
        'pink',
        'brown',
        'gray',
      ]);
      expect(
        [for (final c in pColorSwatchOrder) pColorSwatchNames[c]],
        ['빨강', '주황', '노랑', '초록', '파랑', '남색', '보라', '분홍', '갈색', '회색'],
      );
    });

    group('첫 안 쓴 색 pFirstUnusedColor', () {
      test('v110 배정 순서 — 파랑 → 초록 → 주황 → 보라 → 분홍 → 남색 → 빨강 → 노랑 → 갈색', () {
        expect(pFirstUnusedColor(const []), PChartColor.blue);
        expect(pFirstUnusedColor([PChartColor.blue]), PChartColor.green);
        expect(
          pFirstUnusedColor([PChartColor.blue, PChartColor.orange, null]),
          PChartColor.green,
        );
        expect(
          pFirstUnusedColor([
            PChartColor.blue,
            PChartColor.green,
            PChartColor.orange,
            PChartColor.violet,
            PChartColor.pink,
            PChartColor.indigo,
            PChartColor.red,
            PChartColor.yellow,
          ]),
          PChartColor.brown,
        );
      });

      test('아홉 색을 다 쓰면 파랑부터, 회색은 주지 않는다', () {
        final all = [
          for (final c in PChartColor.values)
            if (c != PChartColor.gray) c,
        ];
        expect(pFirstUnusedColor(all), PChartColor.blue);
        expect(pFirstUnusedColor([...all, PChartColor.gray]), PChartColor.blue);
        expect(pFirstUnusedColor([PChartColor.gray]), PChartColor.blue);
      });
    });

    group('키보드', () {
      testWidgets('Tab 하나 — 고른 칸만, 고른 칸이 없으면 첫 칸', (tester) async {
        await pump(tester, const _Harness(initial: blue));
        for (var i = 0; i < 10; i++) {
          final node = _node(tester, i);
          expect(node.skipTraversal, i != 4, reason: '$i');
        }
        await pump(tester, _Harness(key: UniqueKey()));
        expect(_node(tester, 0).skipTraversal, isFalse);
        expect(_node(tester, 1).skipTraversal, isTrue);
      });

      testWidgets('← → 는 차례대로 옮기며 고른다 — 줄 끝에서 다음 줄로, 끝에서 처음으로', (tester) async {
        await pump(tester, const _Harness(initial: red));
        await _keyboardFocus(tester, 0);
        await _key(tester, LogicalKeyboardKey.arrowRight);
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.orange),
        );
        expect(_node(tester, 1).hasFocus, isTrue);
        await _key(tester, LogicalKeyboardKey.arrowLeft);
        await _key(tester, LogicalKeyboardKey.arrowLeft); // 처음에서 끝(회색)으로
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.gray),
        );
        await _key(tester, LogicalKeyboardKey.arrowRight); // 끝에서 처음으로
        expect(_state(tester).value, red);
        // 줄 끝(파랑 다음 남색은 같은 줄, 노랑 → 초록 → 파랑 → 남색 → 보라 — 다섯째 다음은 아랫줄 첫 칸)
        for (var i = 0; i < 5; i++) {
          await _key(tester, LogicalKeyboardKey.arrowRight);
        }
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.indigo),
        );
      });

      testWidgets('↑ ↓ 는 위아래 줄의 같은 칸 — 두 줄이라 오간다', (tester) async {
        await pump(tester, const _Harness(initial: red));
        await _keyboardFocus(tester, 0);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.indigo),
        );
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_state(tester).value, red);
        await _key(tester, LogicalKeyboardKey.arrowUp);
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.indigo),
        );
      });

      testWidgets(
        'Home · End · PageUp · PageDown 은 받지 않는다 — 초점도 고른 칸도 그대로, Space 는 초점의 칸을 고른다',
        (tester) async {
          await pump(tester, const _Harness(initial: blue));
          await _keyboardFocus(tester, 4);
          for (final key in [
            LogicalKeyboardKey.home,
            LogicalKeyboardKey.end,
            LogicalKeyboardKey.pageUp,
            LogicalKeyboardKey.pageDown,
          ]) {
            await _key(tester, key);
            expect(_state(tester).value, blue, reason: key.keyLabel);
            expect(_state(tester).picks, isEmpty, reason: key.keyLabel);
            expect(_node(tester, 4).hasFocus, isTrue, reason: key.keyLabel);
          }
          // Space — 초점은 그대로 두고 그 칸을 고른다
          await pump(tester, _Harness(key: UniqueKey()));
          await _keyboardFocus(tester, 2);
          expect(_state(tester).value, isNull);
          await _key(tester, LogicalKeyboardKey.space);
          expect(
            _state(tester).value,
            const PColorSwatchValue.color(PChartColor.yellow),
          );
          expect(_node(tester, 2).hasFocus, isTrue);
        },
      );

      testWidgets('지금 색 칸은 차례의 맨 앞 — ↑ ↓ 는 줄 밖이라 그대로', (tester) async {
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
        );
        await _keyboardFocus(tester, 0);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_state(tester).value, current);
        expect(_node(tester, 0).hasFocus, isTrue);
        await _key(tester, LogicalKeyboardKey.arrowRight);
        expect(_state(tester).value, red);
        await _key(tester, LogicalKeyboardKey.arrowLeft);
        expect(_state(tester).value, current);
        await _key(tester, LogicalKeyboardKey.arrowLeft); // 맨 앞에서 끝으로
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.gray),
        );
      });

      testWidgets('RTL — ← → 가 반대', (tester) async {
        await pump(
          tester,
          const _Harness(initial: red),
          dir: TextDirection.rtl,
        );
        await _keyboardFocus(tester, 0);
        await _key(tester, LogicalKeyboardKey.arrowRight);
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.gray),
        );
        await _key(tester, LogicalKeyboardKey.arrowLeft);
        expect(_state(tester).value, red);
        // 격자도 오른쪽부터 — 첫 칸(빨강)이 오른쪽 끝
        expect(
          tester.getCenter(_cell(0)).dx,
          greaterThan(tester.getCenter(_cell(1)).dx),
        );
      });

      testWidgets('키보드로 초점이 오면 링, 손가락으로 눌러서는 링이 없다', (tester) async {
        await pump(tester, const _Harness(initial: red));
        await tester.tap(_cell(2));
        await tester.pump();
        expect(find.byKey(const ValueKey('swatch-focus-ring')), findsNothing);
        await _keyboardFocus(tester, 3);
        expect(find.byKey(const ValueKey('swatch-focus-ring')), findsOneWidget);
      });
    });

    group('누르는 영역 44', () {
      testWidgets('원 40 의 바깥 2 까지 누르면 고르고 그 밖은 아니다', (tester) async {
        await pump(tester, const _Harness(initial: red));
        // 격자 안쪽 칸(둘째 줄 둘째 칸 — 보라 ← 남색)의 왼쪽 · 위쪽 바깥
        final c = tester.getRect(_cell(6)); // 보라
        await tester.tapAt(Offset(c.left - 1.5, c.center.dy));
        await tester.pump();
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.violet),
        );
        // 3px 바깥은 44 밖 — 이웃 칸과 겹치지 않는다(사이 12 가운데)
        await tester.tapAt(Offset(c.right + 6, c.center.dy));
        await tester.pump();
        expect(_state(tester).picks, hasLength(1));
        // 위로도 — 윗줄과 사이 12 안
        await tester.tapAt(Offset(c.center.dx, c.top - 1.5));
        await tester.pump();
        expect(_state(tester).picks, hasLength(1)); // 이미 고른 칸 — 알리지 않는다
        final d = tester.getRect(_cell(7)); // 분홍
        await tester.tapAt(Offset(d.center.dx, d.top - 1.5));
        await tester.pump();
        expect(
          _state(tester).value,
          const PColorSwatchValue.color(PChartColor.pink),
        );
      });
    });

    group('막힘', () {
      testWidgets('색은 그대로, 누르기 · 키보드 모두 막고 Tab 에서 빠진다 — 고른 칸의 고리는 회색', (
        tester,
      ) async {
        await pump(tester, const _Harness(initial: blue, disabled: true));
        await tester.tap(_cell(0), warnIfMissed: false);
        await tester.pump();
        expect(_state(tester).picks, isEmpty);
        expect(_node(tester, 4).canRequestFocus, isFalse);
        final ring =
            (tester
                        .widget<DecoratedBox>(
                          find.byKey(const ValueKey('swatch-ring')),
                        )
                        .decoration
                    as BoxDecoration)
                .border!
                .top
                .color;
        expect(ring, PColors.light.strokeNeutralSolid);
      });

      testWidgets('Field 의 막힘을 받는다', (tester) async {
        await pump(tester, const _Harness(initial: blue));
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PField(
              label: '색상',
              disabled: true,
              child: PColorSwatchGroup(
                value: blue,
                onChanged: (_) => fail('막힌 묶음은 알리지 않는다'),
              ),
            ),
          ),
        );
        await tester.tap(_cell(0), warnIfMissed: false);
        await tester.pump();
      });
    });

    group('지금 색 · 자동', () {
      testWidgets('폭 321 이상이면 옆으로, 좁으면 격자 위 줄 + 가로 선 — 사이는 그대로 16', (
        tester,
      ) async {
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
          width: 342,
        );
        var cur = tester.getRect(_cell(0));
        var grid = tester.getRect(find.byKey(const ValueKey('swatch-grid')));
        expect(cur.right, lessThan(grid.left));
        expect(cur.top, grid.top);
        var div = tester.getRect(find.byKey(const ValueKey('swatch-divider')));
        expect(div.width, 1);
        expect(div.height, grid.height);

        // 360 폰 본문 312 — 위 줄
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
          width: 312,
        );
        cur = tester.getRect(_cell(0));
        grid = tester.getRect(find.byKey(const ValueKey('swatch-grid')));
        div = tester.getRect(find.byKey(const ValueKey('swatch-divider')));
        final column = tester.getRect(
          find.byKey(const ValueKey('swatch-current-column')),
        );
        expect(column.bottom, lessThan(div.top));
        expect(div.height, 1);
        expect(div.width, grid.width); // 선은 격자 폭
        expect(div.top - column.bottom, 16);
        expect(grid.top - div.bottom, 16);
        expect(cur.left, grid.left);
      });

      testWidgets('경계 — 321 은 옆으로, 320 은 위로', (tester) async {
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
          width: pColorSwatchStackBelow,
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('swatch-divider'))).width,
          1,
        );
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
          width: pColorSwatchStackBelow - 1,
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('swatch-divider'))).height,
          1,
        );
      });

      testWidgets('지금 색 칸을 고르면 값은 current — 몰래 빨강으로 바꾸지 않는다', (tester) async {
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
        );
        // 처음부터 골라져 있다 — 체크가 지금 색 칸에
        expect(
          find.descendant(
            of: _cell(0),
            matching: find.byKey(const ValueKey('swatch-check')),
          ),
          findsOneWidget,
        );
        await tester.tap(_cell(0));
        await tester.pump();
        expect(_state(tester).picks, isEmpty); // 이미 고른 칸
        await tester.tap(_cell(1));
        await tester.pump();
        expect(_state(tester).picks, [red]);
        await tester.tap(_cell(0));
        await tester.pump();
        expect(_state(tester).picks.last, current);
      });

      testWidgets('이름 — "지금 색" · "자동"(칸 아래 글과 같다)', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
        );
        expect(find.bySemanticsLabel('지금 색'), findsOneWidget);
        await pump(
          tester,
          const _Harness(initial: current, autoColor: PChartColor.brown),
        );
        expect(find.bySemanticsLabel('자동'), findsOneWidget);
        handle.dispose();
      });

      test('체크는 fg-neutral · fg-neutral-inverted 가운데 그 색 위 대비가 큰 쪽', () {
        for (final colors in [PColors.light, PColors.dark]) {
          // 밝은 회색(#9E9E9E) — 짙은 글자가 읽힌다, 짙은 색 — 밝은 글자
          final onGray = pColorSwatchCheckOn(colors, _gray);
          final onDark = pColorSwatchCheckOn(colors, const Color(0xFF202020));
          final onLight = pColorSwatchCheckOn(colors, const Color(0xFFF0F0F0));
          double ratio(Color a, Color b) {
            final la = a.computeLuminance();
            final lb = b.computeLuminance();
            return (la > lb ? la + 0.05 : lb + 0.05) /
                (la > lb ? lb + 0.05 : la + 0.05);
          }

          for (final (bg, chosen) in [
            (_gray, onGray),
            (const Color(0xFF202020), onDark),
            (const Color(0xFFF0F0F0), onLight),
          ]) {
            final other = chosen == colors.fgNeutral
                ? colors.fgNeutralInverted
                : colors.fgNeutral;
            expect(ratio(chosen, bg), greaterThanOrEqualTo(ratio(other, bg)));
          }
        }
      });

      testWidgets('모드가 바뀌면 지금 색 칸의 체크를 다시 정한다', (tester) async {
        Future<Color> checkColor(Brightness mode) async {
          await pump(
            tester,
            const _Harness(initial: current, currentColor: _gray),
            mode: mode,
          );
          final r = tester.renderObject<RenderCustomPaint>(
            find.byKey(const ValueKey('swatch-check')),
          );
          // paints 로 색만 읽는다
          for (final c in [
            PColors.light.fgNeutral,
            PColors.light.fgNeutralInverted,
            PColors.dark.fgNeutral,
            PColors.dark.fgNeutralInverted,
          ]) {
            try {
              expect(r, paints..path(color: c));
              return c;
            } catch (_) {}
          }
          throw StateError('체크 색을 못 읽는다');
        }

        final light = await checkColor(Brightness.light);
        final dark = await checkColor(Brightness.dark);
        expect(light, isNotNull);
        expect(dark, isNotNull);
      });
    });

    group('접근성', () {
      testWidgets('묶음은 Field 라벨로, 칸은 색 이름 · 고른 상태로 읽힌다', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, const _Harness(initial: blue));
        final node = tester.getSemantics(find.bySemanticsLabel('파랑'));
        final data = node.getSemanticsData();
        expect(data.label, '파랑');
        expect(data.flagsCollection.isChecked, ui.CheckedState.isTrue);
        expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
        final other = tester.getSemantics(find.bySemanticsLabel('빨강'));
        expect(
          other.getSemanticsData().flagsCollection.isChecked,
          ui.CheckedState.isFalse,
        );
        expect(find.bySemanticsLabel('색상'), findsWidgets);
        handle.dispose();
      });

      testWidgets(
        '묶음은 radioGroup 역할 · 이름은 Field 라벨만 — 첫 칸 툴팁이 묶음 이름에 붙지 않는다(03B-004b)',
        (tester) async {
          final handle = tester.ensureSemantics();
          await pump(tester, const _Harness(initial: blue));
          final group = tester.getSemantics(find.bySemanticsLabel('색상').first);
          final data = group.getSemanticsData();
          expect(data.role, ui.SemanticsRole.radioGroup);
          expect(data.label, '색상');
          expect(data.tooltip, isEmpty, reason: '툴팁이 묶음 노드에 붙지 않는다');
          // 칸 노드는 묶음 노드의 바로 아래다 — 툴팁 노드가 사이에 끼지 않는다
          final children = <SemanticsNode>[];
          group.visitChildren((c) {
            children.add(c);
            return true;
          });
          expect(children.length, 10);
          for (final cell in children) {
            final d = cell.getSemanticsData();
            expect(d.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
            expect(d.label, isNotEmpty);
          }
          expect(
            [for (final c in children) c.getSemanticsData().label],
            ['빨강', '주황', '노랑', '초록', '파랑', '남색', '보라', '분홍', '갈색', '회색'],
          );
          handle.dispose();
        },
      );

      testWidgets(
        '"지금 색" 글은 글자 설정을 따라 자라고 위아래가 잘리지 않는다 — 16 고정이 아니다(03B-006)',
        (tester) async {
          for (final scale in [1.0, 2.0]) {
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: _host(
                  Brightness.light,
                  _Harness(
                    key: UniqueKey(),
                    initial: current,
                    currentColor: _gray,
                  ),
                ),
              ),
            );
            await _settle(tester);
            final label = find.byKey(const ValueKey('swatch-current-label'));
            final text = tester.getSize(label).height;
            final box = tester.getSize(
              find
                  .ancestor(of: label, matching: find.byType(OverflowBox))
                  .first,
            );
            expect(text, closeTo(16 * scale, 0.01), reason: 'x$scale 글 높이');
            expect(
              box.height,
              closeTo(text, 0.01),
              reason: 'x$scale 상자는 글을 따른다',
            );
            expect(tester.takeException(), isNull);
          }
        },
      );

      testWidgets(
        '11-10 5A — 위로 올리는 판정은 놓인 자리의 실제 폭이다 — 글자 1 · 2배 × 폭 312 · 320 · 321 · 360 에서 같고 넘치지 않는다',
        (tester) async {
          for (final scale in [1.0, 2.0]) {
            for (final width in [312.0, 320.0, 321.0, 360.0]) {
              await tester.pumpWidget(
                MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: _host(
                    Brightness.light,
                    _Harness(
                      key: UniqueKey(),
                      initial: current,
                      currentColor: _gray,
                    ),
                    width: width,
                  ),
                ),
              );
              await _settle(tester);
              final reason = 'x$scale · 폭 $width';
              final div = tester.getRect(
                find.byKey(const ValueKey('swatch-divider')),
              );
              final grid = tester.getRect(
                find.byKey(const ValueKey('swatch-grid')),
              );
              final column = tester.getRect(
                find.byKey(const ValueKey('swatch-current-column')),
              );
              // 판정은 폭만 본다 — 글자를 키워도 옆 ↔ 위가 바뀌지 않는다
              final side = width >= pColorSwatchStackBelow;
              expect(div.width == 1, side, reason: reason);
              expect(div.height == 1, !side, reason: reason);
              if (!side) expect(column.bottom, lessThan(div.top));
              // 칸 · 격자는 자리 안에 들고, 글 높이는 글자를 따른다
              expect(grid.right, lessThanOrEqualTo(40 + width), reason: reason);
              expect(
                tester
                    .getSize(find.byKey(const ValueKey('swatch-current-label')))
                    .height,
                closeTo(16 * scale, 0.01),
                reason: reason,
              );
              expect(tester.takeException(), isNull, reason: reason);
            }
          }
        },
      );

      testWidgets('칸마다 같은 이름의 툴팁 — 지금 색 칸은 두지 않는다', (tester) async {
        await pump(tester, const _Harness(initial: blue));
        expect(find.byType(PTooltip), findsNWidgets(10));
        await pump(
          tester,
          const _Harness(initial: current, currentColor: _gray),
        );
        expect(find.byType(PTooltip), findsNWidgets(10)); // 격자 10 — 지금 색 칸은 제외
        expect(
          find.descendant(of: _cell(0), matching: find.byType(PTooltip)),
          findsNothing,
        );
      });

      testWidgets('모션 줄이기 — 누르면 줄지 않는다', (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: _host(Brightness.light, const _Harness(initial: red)),
          ),
        );
        await _settle(tester);
        final g = await tester.startGesture(tester.getCenter(_cell(2)));
        await _settle(tester);
        final scale = tester
            .widget<AnimatedScale>(
              find.descendant(
                of: _cell(2),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale;
        expect(scale, 1);
        await g.cancel();
      });
    });

    group('가장 나쁜 값', () {
      for (final mode in Brightness.values) {
        testWidgets('${mode.name} · Field 안 폭 312 · 지금 색 + 막힘 + 오류 — 넘치지 않는다', (
          tester,
        ) async {
          await tester.pumpWidget(
            _host(
              mode,
              PField(
                label: '색상',
                invalid: true,
                errorMessage: '색을 골라주세요.',
                child: PColorSwatchGroup(
                  value: current,
                  currentColor: _gray,
                  onChanged: (_) {},
                ),
              ),
              width: 312,
            ),
          );
          await _settle(tester);
          expect(tester.takeException(), isNull);
        });
      }
    });
  });
}
