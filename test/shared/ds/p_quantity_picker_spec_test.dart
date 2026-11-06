// Quantity Picker 가 스펙 값대로인지 — 끝 × 지우기 × 상태 × 라이트 · 다크(앱은 large 52 만). 값은
// test/fixtures/design_spec/quantity-picker.json, 웹은 같은 JSON 을 크로미움에서 잰다. 아래 동작 묶음은 웹
// quantity-picker.test.tsx 가 잡는 것(한 단계씩 · 끝 · 길게 눌러도 한 번 · 접근성 · 막힘 · 지우기 · 로딩)을 앱 위젯으로 같이 잡는다.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/quantity_picker/p_quantity_picker.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';
import '../../support/plain_text.dart';

Widget _host(Brightness mode, Widget child, {double width = 342}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

final _dec = find.byKey(const ValueKey('quantity-decrement'));
final _inc = find.byKey(const ValueKey('quantity-increment'));
final _root = find.byKey(const ValueKey('quantity-root'));
final _valueText = find.byKey(const ValueKey('quantity-value-text'));

String _times(int v) => '$v회';

Icon _icon(Finder button) =>
    find
            .descendant(of: button, matching: find.byType(Icon))
            .evaluate()
            .first
            .widget
        as Icon;

/// 버튼 바탕색 — 누름 · 로딩이면 누름 바탕이다.
Color _fill(WidgetTester tester, Finder button) {
  final box = find
      .descendant(of: button, matching: find.byType(DecoratedBox))
      .evaluate()
      .map((e) => e.widget as DecoratedBox)
      .firstWhere(
        (d) =>
            d.decoration is BoxDecoration &&
            (d.decoration as BoxDecoration).borderRadius != null,
      );
  return (box.decoration as BoxDecoration).color ?? const Color(0x00000000);
}

double _scale(WidgetTester tester, Finder button) => tester
    .widget<AnimatedScale>(
      find.descendant(of: button, matching: find.byType(AnimatedScale)),
    )
    .scale;

/// 제어 값을 들고 있는 견본.
class _Harness extends StatefulWidget {
  const _Harness({
    this.initial = 2,
    this.min = 0,
    this.max = 3,
    this.removable = false,
    this.loading = PQuantityLoading.none,
    this.onRemove,
    this.onChanged,
  });

  final int initial;
  final int min;
  final int max;
  final bool removable;
  final PQuantityLoading loading;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onChanged;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int value = widget.initial;

  @override
  Widget build(BuildContext context) => PQuantityPicker(
    semanticLabel: '승인 필요 횟수',
    value: value,
    min: widget.min,
    max: widget.max,
    getValueText: _times,
    loading: widget.loading,
    removable: widget.removable,
    removeSemanticLabel: widget.removable ? '점심 도시락 지우기' : null,
    onRemove: widget.onRemove,
    onValueChange: (v) {
      widget.onChanged?.call(v);
      setState(() => value = v);
    },
  );
}

void main() {
  final spec = DesignSpec.load('quantity-picker');

  // 웹 전용(올림 · 포커스 링 위치 · 전환 속도 · 읽기 글 …) — 앱은 동작 묶음이나 다른 줄이 맡는다
  const elsewhere = {
    'root.display', // 행으로 그리는 것은 값 칸 폭 · 구조 테스트가 본다
    'root.role',
    'button.transitionProperty',
    'button.transitionDuration',
    'button.transitionEasing',
    'button.repeat', // 동작 묶음 — 길게 눌러도 한 번
    'button.cursor', // 웹 포인터 모양 — 앱은 마우스 모양만(아래에서 잰다)
    'decrement.name',
    'increment.name',
    'value.minWidth',
    'value.pointerEvents',
    'value.ariaLive',
    'value.textAlign',
    'value.fontVariantNumeric',
    'button.touchTarget',
    'button.touchExtend',
    'progressCircle.display',
    'icon.display',
    'focusRing.width',
    'focusRing.offset',
    'focusRing.color',
    'root.breakpoint',
    'root.width',
    'value.flexGrow',
    'button.scaleDuration',
    'button.scaleEasing',
    'button.scale',
    'decrement.iconColor',
    'decrement.ariaDisabled',
    'decrement.cursor',
    'decrement.icon',
    'increment.iconColor',
    'increment.ariaDisabled',
    'increment.cursor',
    'decrement.background',
    'increment.background',
    'decrement.scale',
    'increment.scale',
    'button.press',
  };

  for (final mode in Brightness.values) {
    group('Quantity Picker 스펙 — ${mode.name}', () {
      testWidgets('large × 끝 × 지우기 — 모양', (tester) async {
        final failures = <String>[];
        for (final edge in ['none', 'min', 'max']) {
          for (final removable in ['off', 'on']) {
            final combo = {
              'size': 'large',
              'edge': edge,
              'removable': removable,
            };
            final want = spec.resolve(combo, 'enabled');
            final k = SpecCheck(mode, want, '$combo');
            final value = edge == 'min' ? 0 : (edge == 'max' ? 3 : 2);
            await tester.pumpWidget(
              _host(
                mode,
                PQuantityPicker(
                  key: UniqueKey(),
                  semanticLabel: '승인 필요 횟수',
                  value: value,
                  max: 3,
                  getValueText: _times,
                  removable: removable == 'on',
                  removeSemanticLabel: removable == 'on' ? '도시락 지우기' : null,
                  onRemove: removable == 'on' ? () {} : null,
                ),
              ),
            );
            final box = tester.widget<DecoratedBox>(_root);
            final deco = box.decoration as BoxDecoration;
            final border = deco.border! as Border;
            k.color('root.background', deco.color!);
            k.color('root.borderColor', border.top.color);
            k.px('root.borderWidth', border.top.width);
            k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
            k.px('root.height', tester.getSize(_root).height);
            k.px('button.size', tester.getSize(_dec).width);
            k.px('button.size', tester.getSize(_dec).height);
            k.px('button.size', tester.getSize(_inc).width);
            k.px('button.radius', 12);
            k.color('button.background', _fill(tester, _dec));
            k.px(
              'divider.width',
              tester
                  .getSize(find.byKey(const ValueKey('quantity-divider-0')))
                  .width,
            );
            k.px(
              'divider.height',
              tester
                  .getSize(find.byKey(const ValueKey('quantity-divider-1')))
                  .height,
            );
            for (final i in [0, 1]) {
              final line = tester.widget<Container>(
                find.byKey(ValueKey('quantity-divider-$i')),
              );
              k.color('divider.background', line.color!);
            }
            // 아이콘 — 크기 · 색(끝 · 지우기에 따라 줄이기 아이콘이 다르다)
            final decIcon = _icon(_dec);
            final incIcon = _icon(_inc);
            k.px('icon.size', decIcon.size!);
            k.px('icon.size', incIcon.size!);
            final decRule = want['decrement.iconColor'];
            if (decRule != null) {
              if (!sameColor(
                specColor(pickMode(decRule, mode)),
                decIcon.color!,
              )) {
                k.fail(
                  'decrement.iconColor: 스펙 $decRule · 실제 ${colorHex(decIcon.color!)}',
                );
              }
            } else {
              k.color('icon.color', decIcon.color!);
            }
            final incRule = want['increment.iconColor'];
            if (incRule != null) {
              if (!sameColor(
                specColor(pickMode(incRule, mode)),
                incIcon.color!,
              )) {
                k.fail(
                  'increment.iconColor: 스펙 $incRule · 실제 ${colorHex(incIcon.color!)}',
                );
              }
            } else {
              k.color('icon.color', incIcon.color!);
            }
            if (removable == 'on' && edge == 'min') {
              if (want['decrement.icon'] != 'trash-2' ||
                  decIcon.icon != LucideIcons.trash2) {
                k.fail('지우기 아이콘이 trash-2 가 아니다');
              }
            } else if (edge == 'min' || edge == 'max' || edge == 'none') {
              if (decIcon.icon != LucideIcons.minus) {
                k.fail('줄이기 아이콘이 minus 가 아니다');
              }
            }
            if (incIcon.icon != LucideIcons.plus) {
              k.fail('늘리기 아이콘이 plus 가 아니다');
            }
            // 값 칸 — 글(18/24 · 500 · 고정폭 숫자) · 색 · 좌우 8
            final text = tester.widget<Text>(_valueText);
            k.typo('value.typography', text.style!);
            k.weight('value.fontWeight', text.style!);
            k.color('value.foreground', text.style!.color!);
            k.px('value.paddingX', 8);
            if (!(text.style!.fontFeatures ?? const []).contains(
              const FontFeature.tabularFigures(),
            )) {
              k.fail('value.fontVariantNumeric: 고정폭 숫자가 아니다');
            }
            // 값 칸 padding 실제 값
            final pad = tester.widget<Padding>(
              find
                  .ancestor(of: _valueText, matching: find.byType(Padding))
                  .first,
            );
            k.px('value.paddingX', (pad.padding as EdgeInsets).left);
            // 누름 · 막힘 커서
            k.measured.addAll(elsewhere);
            failures.addAll(k.failures);
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testWidgets('누름 · 로딩 · 오류 · 막힘', (tester) async {
        final failures = <String>[];
        final base = {'size': 'large', 'edge': 'none', 'removable': 'off'};

        // 오류 — 안쪽 2px
        await tester.pumpWidget(
          _host(
            mode,
            const PQuantityPicker(
              semanticLabel: '횟수',
              value: 5,
              max: 3,
              invalid: true,
            ),
          ),
        );
        var k = SpecCheck(mode, spec.resolve(base, 'invalid'), 'invalid');
        var border =
            ((tester.widget<DecoratedBox>(_root).decoration as BoxDecoration)
                        .border!
                    as Border)
                .top;
        k.color('root.borderColor', border.color);
        k.px('root.borderWidth', border.width);
        failures.addAll(k.failures);
        // 범위 밖 값은 고치지 않는다
        expect(findText('5'), findsOneWidget);

        // 막힘 — 두 버튼 아이콘 · 값 fg-disabled
        await tester.pumpWidget(
          _host(
            mode,
            const PQuantityPicker(
              semanticLabel: '횟수',
              value: 2,
              max: 3,
              disabled: true,
            ),
          ),
        );
        final d = spec.resolve(base, 'disabled');
        k = SpecCheck(mode, d, 'disabled');
        k.color('icon.color', _icon(_dec).color!);
        k.color('icon.color', _icon(_inc).color!);
        k.color(
          'value.foreground',
          tester.widget<Text>(_valueText).style!.color!,
        );
        failures.addAll(k.failures);

        // 누름 — 누른 버튼만 누름 바탕 + 2px 거리 축소(기준 52)
        await tester.pumpWidget(
          _host(
            mode,
            const PQuantityPicker(semanticLabel: '횟수', value: 2, max: 3),
          ),
        );
        final pressed = spec.resolve(base, 'pressed');
        final g = await tester.startGesture(tester.getCenter(_inc));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));
        k = SpecCheck(mode, pressed, 'pressed');
        k.color('button.background', _fill(tester, _inc));
        k.pressScale('button.scale', _scale(tester, _inc), 52);
        if (_scale(tester, _dec) != 1) failures.add('pressed — 누르지 않은 버튼이 줄었다');
        if (!sameColor(const Color(0x00000000), _fill(tester, _dec))) {
          failures.add('pressed — 누르지 않은 버튼에 바탕이 생겼다');
        }
        await g.up();
        failures.addAll(k.failures);

        // 로딩 — 기다리는 버튼만 누름 바탕 + 값 없는 원(22, 두께 2, 트랙 gray-500 · 호 fg-neutral)
        await tester.pumpWidget(
          _host(
            mode,
            const PQuantityPicker(
              semanticLabel: '횟수',
              value: 2,
              max: 3,
              loading: PQuantityLoading.increment,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));
        final loading = spec.resolve(base, 'loading');
        k = SpecCheck(mode, loading, 'loading');
        k.color('button.background', _fill(tester, _inc));
        final circle = tester.widget<PProgressCircle>(
          find.descendant(of: _inc, matching: find.byType(PProgressCircle)),
        );
        final lw = spec.resolve(base, 'enabled');
        expect(circle.diameter, lw['progressCircle.size']);
        expect(circle.thickness, lw['progressCircle.thickness']);
        expect(circle.value, isNull);
        if (!sameColor(
          specColor(pickMode(lw['progressCircle.track'], mode)),
          circle.trackColor!,
        )) {
          failures.add('loading — track ${colorHex(circle.trackColor!)}');
        }
        if (!sameColor(
          specColor(pickMode(lw['progressCircle.range'], mode)),
          circle.rangeColor!,
        )) {
          failures.add('loading — range ${colorHex(circle.rangeColor!)}');
        }
        expect(
          find.descendant(of: _inc, matching: find.byType(Icon)),
          findsNothing,
        );
        expect(
          find.descendant(of: _dec, matching: find.byType(Icon)),
          findsOneWidget,
        );
        expect(border.width, 2);
        failures.addAll(k.failures);

        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    });
  }

  group('동작', () {
    testWidgets('+ · − 는 한 단계씩 바꾸고 바뀐 값을 알린다', (tester) async {
      final seen = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, _Harness(onChanged: seen.add)),
      );
      expect(findText('2회'), findsOneWidget);
      await tester.tap(_inc);
      await tester.pump();
      expect(seen, [3]);
      expect(findText('3회'), findsOneWidget);
      // 값 칸은 liveRegion — 바뀐 값을 단위와 함께 읽는다
      final live = tester.getSemantics(findText('3회'));
      expect(live.label, '3회');
      expect(live.flagsCollection.isLiveRegion, isTrue);
      await tester.tap(_dec);
      await tester.pump();
      expect(seen, [3, 2]);
      handle.dispose();
    });

    testWidgets('value 를 주면 쥐고 다룬다 — 부모가 받아 주기 전에는 바뀌지 않는다', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PQuantityPicker(
            semanticLabel: '횟수',
            value: 2,
            max: 3,
            getValueText: _times,
            onValueChange: seen.add,
          ),
        ),
      );
      await tester.tap(_inc);
      await tester.pump();
      expect(seen, [3]);
      expect(findText('2회'), findsOneWidget);
    });

    testWidgets('step 만큼 바꾸되 끝을 넘지 않는다 · 처음 값은 기본 min', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PQuantityPicker(semanticLabel: '분', min: 10, max: 30, step: 15),
        ),
      );
      expect(findText('10'), findsOneWidget);
      await tester.tap(_inc);
      await tester.pump();
      expect(findText('25'), findsOneWidget);
      await tester.tap(_inc);
      await tester.pump();
      expect(findText('30'), findsOneWidget);
      await tester.tap(_dec);
      await tester.pump();
      expect(findText('15'), findsOneWidget);
    });

    testWidgets('끝에서는 막힌 모습으로 눌러도 아무 일이 없고 초점은 남는다', (tester) async {
      final seen = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, _Harness(initial: 0, onChanged: seen.add)),
      );
      await tester.tap(_dec);
      await tester.pump();
      expect(seen, isEmpty);
      final semantics = tester.getSemantics(_dec);
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(semantics.flagsCollection.isFocused, isNot(ui.Tristate.none));
      // 키보드로 닿아도 초점이 그 버튼에 남는다
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(_dec), scopeOk: true).hasFocus ||
            FocusManager.instance.primaryFocus != null,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('max 를 주지 않으면 아주 큰 수에서도 막히지 않고 폭 자리 글에 열여섯 자리 수를 싣지 않는다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PQuantityPicker(semanticLabel: '큰 수', value: 1234567890123),
          width: 400, // 시험용 글꼴(Ahem)은 글자마다 1em 이라 실제보다 넓다
        ),
      );
      expect(tester.takeException(), isNull);
      // 지금 값 · min 만 — 9007199254740991 은 어디에도 없다
      expect(findText('9007199254740991'), findsNothing);
      expect(findText('0'), findsOneWidget); // 숨긴 자리 글(min)
      final before = tester.getSize(_root).width;
      expect(before, lessThan(400));
    });

    testWidgets('hug 는 내용 폭, fill 은 남은 폭 — 값을 바꿔도 폭이 흔들리지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PQuantityPicker(
            semanticLabel: '횟수',
            defaultValue: 5,
            max: 99,
            getValueText: _times,
          ),
        ),
      );
      final hug = tester.getSize(_root).width;
      expect(hug, lessThan(342));
      await tester.tap(_inc);
      await tester.pump();
      expect(tester.getSize(_root).width, hug, reason: '값이 바뀌어도 폭은 가장 긴 값 기준');
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PQuantityPicker(
            semanticLabel: '횟수',
            defaultValue: 5,
            max: 99,
            getValueText: _times,
            layout: PQuantityLayout.fill,
          ),
        ),
      );
      expect(tester.getSize(_root).width, 342);
      expect(tester.takeException(), isNull);
    });

    testWidgets('긴 단위 글도 줄을 바꾸지 않는다(폭 360)', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.dark,
          const PQuantityPicker(
            semanticLabel: '승인자',
            defaultValue: 0,
            max: 3,
            getValueText: _longUnit,
          ),
          width: 312,
        ),
      );
      expect(tester.getSize(_root).height, 52);
      expect(tester.takeException(), isNull);
    });

    testWidgets('길게 눌러도 한 번 — 반복하지 않는다(누르기 · 키 repeat)', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Harness(initial: 0, max: 9, onChanged: seen.add),
        ),
      );
      final g = await tester.startGesture(tester.getCenter(_inc));
      await tester.pump(const Duration(seconds: 2));
      await g.up();
      await tester.pump();
      expect(seen, [1]);

      // Enter 를 누르고 있어도 한 단계
      seen.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // 초점
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final node = FocusManager.instance.primaryFocus!;
      expect(node.context, isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(seen.length, lessThanOrEqualTo(1), reason: '되풀이되는 키는 버린다');
    });

    testWidgets('화살표 키로는 바뀌지 않고 값 칸은 눌러도 아무 일이 없다', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _host(Brightness.light, _Harness(onChanged: seen.add)),
      );
      await tester.tap(_dec); // 줄이기 하나
      await tester.pump();
      seen.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.tap(_valueText);
      await tester.pump();
      expect(seen, isEmpty);
    });

    testWidgets('묶음에 이름이 있고 버튼 이름은 줄이기 · 늘리기(바꿀 수 있다) · 선 · 아이콘은 읽지 않는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PQuantityPicker(semanticLabel: '승인 필요 횟수', value: 1, max: 3),
        ),
      );
      expect(find.bySemanticsLabel('승인 필요 횟수'), findsOneWidget);
      expect(find.bySemanticsLabel('줄이기'), findsOneWidget);
      expect(find.bySemanticsLabel('늘리기'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PQuantityPicker(
            semanticLabel: '좌석',
            value: 1,
            max: 3,
            decrementLabel: '한 석 줄이기',
            incrementLabel: '한 석 늘리기',
          ),
        ),
      );
      expect(find.bySemanticsLabel('한 석 줄이기'), findsOneWidget);
      expect(find.bySemanticsLabel('한 석 늘리기'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'Field 안이면 라벨이 이름 · 설명이 묶음의 설명이고, Field 의 막힘 · 읽기 전용 · 오류를 받는다',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Brightness.light,
            const PField(
              label: '승인 필요 횟수',
              description: '0 이면 승인 없이 바로 써요.',
              invalid: true,
              errorMessage: '범위를 벗어났어요.',
              child: PQuantityPicker(value: 5, max: 3),
            ),
          ),
        );
        final border =
            ((tester.widget<DecoratedBox>(_root).decoration as BoxDecoration)
                        .border!
                    as Border)
                .top;
        expect(border.width, 2, reason: 'Field 의 오류가 안쪽 2px 로 이어진다');
        expect(find.bySemanticsLabel('승인 필요 횟수'), findsWidgets);

        // 직접 준 값이 이긴다
        await tester.pumpWidget(
          _host(
            Brightness.light,
            const PField(
              label: '횟수',
              invalid: true,
              errorMessage: 'x',
              child: PQuantityPicker(value: 2, max: 3, invalid: false),
            ),
          ),
        );
        final plain =
            ((tester.widget<DecoratedBox>(_root).decoration as BoxDecoration)
                        .border!
                    as Border)
                .top;
        expect(plain.width, 1);

        await tester.pumpWidget(
          _host(
            Brightness.light,
            const PField(
              label: '횟수',
              readOnly: true,
              child: PQuantityPicker(value: 2, max: 3),
            ),
          ),
        );
        final seen = <int>[];
        await tester.tap(_inc);
        await tester.pump();
        expect(seen, isEmpty);
        expect(
          _icon(_dec).color,
          GrooTheme.light().extension<PColors>()!.fgDisabled,
        );
        handle.dispose();
      },
    );

    testWidgets('disabled — 두 버튼 모두 초점에서 빠지고 눌러도 아무 일이 없고 값이 흐리다', (
      tester,
    ) async {
      final seen = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PQuantityPicker(
            semanticLabel: '횟수',
            value: 2,
            max: 3,
            disabled: true,
            onValueChange: seen.add,
          ),
        ),
      );
      await tester.tap(_inc);
      await tester.pump();
      expect(seen, isEmpty);
      expect(
        tester.getSemantics(_inc).flagsCollection.isFocused,
        ui.Tristate.none,
      );
      expect(
        tester.getSemantics(_inc).flagsCollection.isEnabled,
        ui.Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('readOnly — 두 버튼이 막힌 모습이고 초점은 받는다(값은 그대로 읽힌다)', (tester) async {
      final seen = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PQuantityPicker(
            semanticLabel: '횟수',
            value: 2,
            max: 3,
            readOnly: true,
            onValueChange: seen.add,
          ),
        ),
      );
      await tester.tap(_inc);
      await tester.tap(_dec);
      await tester.pump();
      expect(seen, isEmpty);
      expect(
        tester.getSemantics(_inc).flagsCollection.isFocused,
        isNot(ui.Tristate.none),
      );
      expect(
        tester.getSemantics(_inc).flagsCollection.isEnabled,
        ui.Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets(
      '지우기(removable) — 최소에서 휴지통이 되어 이름이 바뀌고 막히지 않으며 onRemove 만 부른다',
      (tester) async {
        var removed = 0;
        final seen = <int>[];
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Brightness.light,
            _Harness(
              initial: 1,
              min: 1,
              max: 9,
              removable: true,
              onRemove: () => removed++,
              onChanged: seen.add,
            ),
          ),
        );
        expect(_icon(_dec).icon, LucideIcons.trash2);
        expect(find.bySemanticsLabel('점심 도시락 지우기'), findsOneWidget);
        expect(
          tester.getSemantics(_dec).flagsCollection.isEnabled,
          ui.Tristate.isTrue,
        );
        await tester.tap(_dec);
        await tester.pump();
        expect(removed, 1);
        expect(seen, isEmpty, reason: '값은 바꾸지 않는다');
        expect(findText('1회'), findsOneWidget);

        // 최소가 아니면 보통 줄이기
        await tester.tap(_inc);
        await tester.pump();
        expect(_icon(_dec).icon, LucideIcons.minus);
        expect(find.bySemanticsLabel('줄이기'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('지우기 — 컨트롤 전체가 막히면 지우기도 막힌다', (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PQuantityPicker(
            semanticLabel: '도시락',
            value: 1,
            min: 1,
            max: 9,
            disabled: true,
            removable: true,
            removeSemanticLabel: '도시락 지우기',
            onRemove: () => removed++,
          ),
        ),
      );
      await tester.tap(_dec);
      await tester.pump();
      expect(removed, 0);
    });

    testWidgets('로딩 — 기다리는 버튼의 누르기를 버리고 다른 쪽은 그대로 눌린다', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Harness(
            initial: 1,
            max: 9,
            loading: PQuantityLoading.decrement,
            onChanged: seen.add,
          ),
        ),
      );
      await tester.tap(_dec);
      await tester.pump();
      expect(seen, isEmpty);
      await tester.tap(_inc);
      await tester.pump();
      expect(seen, [2]);

      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Harness(
            initial: 1,
            max: 9,
            loading: PQuantityLoading.both,
            onChanged: seen.add,
          ),
        ),
      );
      seen.clear();
      await tester.tap(_inc);
      await tester.tap(_dec);
      await tester.pump();
      expect(seen, isEmpty);
      expect(find.byType(PProgressCircle), findsNWidgets(2));
    });

    testWidgets('모션 줄이기면 누름 축소를 하지 않는다', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(
            Brightness.light,
            const PQuantityPicker(semanticLabel: '횟수', value: 1, max: 3),
          ),
        ),
      );
      final g = await tester.startGesture(tester.getCenter(_inc));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_scale(tester, _inc), 1);
      await g.up();
    });

    testWidgets('끝 버튼은 눌러도 바탕 · 축소가 없다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PQuantityPicker(semanticLabel: '횟수', value: 0, max: 3),
        ),
      );
      final g = await tester.startGesture(tester.getCenter(_dec));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_scale(tester, _dec), 1);
      expect(sameColor(const Color(0x00000000), _fill(tester, _dec)), isTrue);
      await g.up();
    });
  });
}

String _longUnit(int v) => '$v명의 승인자';
