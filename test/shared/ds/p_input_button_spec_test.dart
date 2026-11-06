// Input Button 이 스펙 값(test/fixtures/design_spec/input-button.json)대로인지 — 상태 × 라이트 · 다크를 모두 돈다.
// 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱은 늘 large 다 — medium · responsive(1280 이상 데스크톱 웹)는 재지 않는다. 눌림 · 포커스는 실제로 누르고(손가락을
// 대고 있는 채로) 키보드 포커스를 줘서 잰다. 동작 테스트는 아래 별도 group.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/text_control.dart';
import 'package:groo_damda_app/shared/ds/input_button/input_button_demo.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('input-button');

const _transparent = Color(0x00000000);

Widget _host(
  Brightness mode,
  Widget child, {
  double width = 320,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

class _Check {
  _Check(this.mode, this.want, this.where);
  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return fail('$key: 스펙에 없다');
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if ((w - actual).abs() > 0.5) fail('$key: 스펙 $w · 실제 $actual');
  }

  void typo(String key, TextStyle style) {
    final t = want[key] as Map?;
    if (t == null) return fail('$key: 스펙에 없다');
    final lineHeight = style.fontSize! * (style.height ?? 1);
    if (t['fontSize'] != style.fontSize ||
        ((t['lineHeight'] as num) - lineHeight).abs() > 0.01) {
      fail(
        '$key: 스펙 ${t['fontSize']}/${t['lineHeight']} · 실제 ${style.fontSize}/$lineHeight',
      );
    }
    final family = '${t['fontFamily']}'.split(',').first.trim();
    if (style.fontFamily != family) {
      fail('$key: 글꼴 스펙 $family · 실제 ${style.fontFamily}');
    }
  }

  void weight(String key, TextStyle style) {
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if (style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }
}

TextStyle _textStyle(WidgetTester tester, Finder within, String text) => tester
    .widget<Text>(find.descendant(of: within, matching: findText(text)))
    .style!;

Icon _icon(WidgetTester tester, Finder within, IconData data) => tester
    .widget<Icon>(find.descendant(of: within, matching: find.byIcon(data)));

/// 상자의 세 겹 — 바탕 · 덧그린 2px · 안쪽 1px.
List<BoxDecoration> _frame(WidgetTester tester, Finder control) {
  final boxes = find.descendant(
    of: find.descendant(of: control, matching: find.byType(PTextFrame)),
    matching: find.byType(DecoratedBox),
  );
  return [
    for (var i = 0; i < 3; i++)
      tester.widget<DecoratedBox>(boxes.at(i)).decoration as BoxDecoration,
  ];
}

/// 키보드 포커스 링 — 있으면 그 선, 없으면 null.
BorderSide? _ring(WidgetTester tester, Finder control) {
  final rings = find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          (w.decoration as BoxDecoration).color == null &&
          ((w.decoration as BoxDecoration).border! as Border).top.width == 2 &&
          w.position == DecorationPosition.background,
    ),
  );
  if (rings.evaluate().isEmpty) return null;
  return ((tester.widget<DecoratedBox>(rings.first).decoration as BoxDecoration)
              .border!
          as Border)
      .top;
}

AnimatedScale _contentScale(WidgetTester tester, Finder control) =>
    tester.widget<AnimatedScale>(
      find.descendant(of: control, matching: find.byType(AnimatedScale)).first,
    );

void main() {
  group('Input Button — 스펙(large × 상태 × 라이트 · 다크)', () {
    const empty = ValueKey('empty');
    const filled = ValueKey('filled');

    Future<void> check(
      WidgetTester tester,
      Brightness mode,
      String state,
      List<String> failures,
    ) async {
      final disabled = state == 'disabled';
      final readOnly = state == 'readonly';
      final invalid = state == 'invalid';
      await tester.pumpWidget(
        _host(
          mode,
          Column(
            key: UniqueKey(),
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              PInputButton(
                key: empty,
                semanticLabel: '날짜',
                placeholder: '날짜 선택',
                prefixIcon: LucideIcons.utensils,
                prefixText: '만',
                disabled: disabled,
                readOnly: readOnly,
                invalid: invalid,
                onPressed: () {},
              ),
              PInputButton(
                key: filled,
                semanticLabel: '날짜',
                value: '2026년 10월 1일 (목)',
                suffixText: '세',
                suffixIcon: LucideIcons.calendarDays,
                disabled: disabled,
                readOnly: readOnly,
                invalid: invalid,
                onPressed: () {},
                onClear: () {},
              ),
            ],
          ),
        ),
      );
      TestGesture? finger;
      if (state == 'pressed') {
        finger = await tester.startGesture(
          tester.getCenter(find.byKey(filled)),
        );
      } else if (state == 'focused') {
        // 첫 칸(빈 칸) 다음 — 값이 있는 칸
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      // 색 전환 · 눌림 모션이 끝나게 — 첫 프레임에서 시작하고 두 번째에서 끝난다
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final want = _spec.resolve({'size': 'large'}, state);
      final k = _Check(mode, want, '${mode.name} large $state');
      final e = find.byKey(empty);
      final f = find.byKey(filled);

      // 상자
      for (final control in [e, f]) {
        final box = find.descendant(
          of: control,
          matching: find.byType(PTextFrame),
        );
        k.px('root.minHeight', tester.getSize(box).height);
        final padding =
            tester
                    .widget<Padding>(
                      find
                          .descendant(of: box, matching: find.byType(Padding))
                          .first,
                    )
                    .padding
                as EdgeInsets;
        k.px('root.paddingX', padding.left);
        k.px('root.paddingX', padding.right);
        k.px(
          'root.gap',
          tester
              .widget<Row>(
                find.descendant(of: box, matching: find.byType(Row)).first,
              )
              .spacing,
        );
      }
      final deco = _frame(tester, f);
      final pressedFilled =
          state == 'pressed' || state == 'readonly' || disabled;
      k.color('root.background', deco[0].color ?? _transparent);
      if (!pressedFilled && deco[0].color != null && deco[0].color!.a != 0) {
        k.fail('바탕이 칠해져 있다');
      }
      k.px('root.radius', (deco[0].borderRadius! as BorderRadius).topLeft.x);
      // 1px 는 늘, 2px 는 오류에만
      final base = (deco[2].border! as Border).top;
      k.color(
        'root.borderColor',
        invalid ? (deco[1].border! as Border).top.color : base.color,
      );
      k.px(
        'root.borderWidth',
        invalid ? (deco[1].border! as Border).top.width : base.width,
      );
      if (!invalid && (deco[1].border! as Border).top.color.a != 0) {
        k.fail('덧그린 2px 가 남아 있다');
      }
      if (invalid && base.width != 1) k.fail('1px 위에 덧그린다');

      // 커서 — pointer · not-allowed · default
      final wantCursor = switch (want['root.cursor']) {
        'pointer' => SystemMouseCursors.click,
        'not-allowed' => SystemMouseCursors.forbidden,
        'default' => SystemMouseCursors.basic,
        final other => throw ArgumentError('커서 $other'),
      };
      final cursors = tester
          .widgetList<MouseRegion>(
            find.descendant(of: f, matching: find.byType(MouseRegion)),
          )
          .map((m) => m.cursor);
      if (!cursors.contains(wantCursor)) k.fail('root.cursor: 실제 $cursors');

      // 값 · placeholder · 붙이개
      final value = _textStyle(tester, f, '2026년 10월 1일 (목)');
      k.typo('value.typography', value);
      k.weight('value.fontWeight', value);
      k.color('value.foreground', value.color!);
      final placeholder = _textStyle(tester, e, '날짜 선택');
      k.typo('placeholder.typography', placeholder);
      k.weight('placeholder.fontWeight', placeholder);
      k.color('placeholder.foreground', placeholder.color!);
      final prefixText = _textStyle(tester, e, '만');
      k.typo('prefixText.typography', prefixText);
      k.color('prefixText.foreground', prefixText.color!);
      final suffixText = _textStyle(tester, f, '세');
      k.typo('suffixText.typography', suffixText);
      k.color('suffixText.foreground', suffixText.color!);
      final prefixIcon = _icon(tester, e, LucideIcons.utensils);
      k.px('prefixIcon.size', prefixIcon.size!);
      k.color('prefixIcon.color', prefixIcon.color!);
      final suffixIcon = _icon(tester, f, LucideIcons.calendarDays);
      k.px('suffixIcon.size', suffixIcon.size!);
      k.color('suffixIcon.color', suffixIcon.color!);

      // 지우기 — 값이 있고 막히지 않았을 때만
      final clear = find.descendant(
        of: f,
        matching: find.byIcon(LucideIcons.circleX),
      );
      if (disabled || readOnly) {
        if (clear.evaluate().isNotEmpty) k.fail('막힌 칸에 지우기 버튼이 있다');
      } else if (clear.evaluate().isEmpty) {
        k.fail('지우기 버튼이 없다');
      } else {
        final icon = tester.widget<Icon>(clear);
        k.px('clearButton.size', icon.size!);
        k.color('clearButton.color', icon.color!);
      }

      // 포커스 링 — 키보드 포커스에만, 바깥 2px · 띄움 2px
      final ring = _ring(tester, f);
      if (state == 'focused') {
        if (ring == null) {
          k.fail('키보드 포커스에 링이 없다');
        } else {
          k.px('focusRing.width', ring.width);
          k.color('focusRing.color', ring.color);
          final ringBox = tester.getRect(
            find
                .descendant(
                  of: f,
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is DecoratedBox &&
                        (w.decoration as BoxDecoration).color == null &&
                        (w.decoration as BoxDecoration).border is Border &&
                        ((w.decoration as BoxDecoration).border! as Border)
                                .top
                                .width ==
                            2 &&
                        w.position == DecorationPosition.background,
                  ),
                )
                .first,
          );
          final frameBox = tester.getRect(
            find.descendant(of: f, matching: find.byType(PTextFrame)),
          );
          // 링 바깥 가장자리 = 상자 + 띄움 + 두께
          final gap = frameBox.left - ringBox.left;
          if ((gap - 4).abs() > 0.5)
            k.fail('focusRing.offset: 스펙 2+2 · 실제 $gap');
        }
      } else if (ring != null) {
        k.fail('키보드 포커스가 아닌데 링이 있다');
      }

      // 눌림 — 콘텐츠만 2px 거리로 준다(기준 max(높이, 폭 ÷ 4, 24))
      final scale = _contentScale(tester, f);
      if (state == 'pressed') {
        final size = tester.getSize(
          find.descendant(of: f, matching: find.byType(PTextFrame)),
        );
        final basis = [
          size.height,
          size.width / 4,
          24.0,
        ].reduce((a, b) => a > b ? a : b);
        final wantScale = (basis - 2) / basis;
        if ((scale.scale - wantScale).abs() > 0.0005) {
          k.fail('pressed.scale: 스펙 $wantScale · 실제 ${scale.scale}');
        }
        if (scale.duration != specMs(want['root.scaleDuration'])) {
          k.fail('scaleDuration: 실제 ${scale.duration}');
        }
        final cubic = specCubic(want['root.scaleEasing']);
        final curve = scale.curve as Cubic;
        if ([curve.a, curve.b, curve.c, curve.d].toString() !=
            cubic.toString()) {
          k.fail('scaleEasing: 실제 $curve');
        }
      } else if (scale.scale != 1) {
        k.fail('눌리지 않았는데 콘텐츠가 줄었다(${scale.scale})');
      }

      await finger?.up();
      await tester.pump(const Duration(milliseconds: 400));
      failures.addAll(k.failures);
    }

    testWidgets('상태 × 라이트 · 다크가 스펙과 같다', (tester) async {
      expect(_spec.axes['size'], containsAll(['large']));
      final failures = <String>[];
      for (final mode in [Brightness.light, Brightness.dark]) {
        for (final state in _spec.states) {
          await check(tester, mode, state, failures);
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('모션 — 바탕 150ms · 오류 테두리 100ms', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, const PInputButton(value: '값', invalid: true)),
      );
      final motion = _spec.json['motion'] as Map<String, dynamic>;
      final builders = tester
          .widgetList<TweenAnimationBuilder<Color>>(
            find.byType(TweenAnimationBuilder<Color>),
          )
          .toList();
      // 바깥 — 바탕(color-transition), 안쪽 — 오류 테두리(d2)
      final bg = motion['누름 · 호버 — 바탕'] as Map;
      final border = motion['오류 — 테두리'] as Map;
      expect(builders.first.duration, specMs(bg['duration']));
      expect(
        [for (final v in specCubic(bg['easing'])) v].toString(),
        [
          (builders.first.curve as Cubic).a,
          (builders.first.curve as Cubic).b,
          (builders.first.curve as Cubic).c,
          (builders.first.curve as Cubic).d,
        ].toString(),
      );
      expect(builders.last.duration, specMs(border['duration']));
    });
  });

  group('Input Button — 동작', () {
    testWidgets('누르면 onPressed 만 부른다 — 어디를 눌러도(붙이개 · 여백 포함)', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputButton(
            semanticLabel: '날짜',
            placeholder: '날짜 선택',
            prefixIcon: LucideIcons.calendarDays,
            suffixIcon: LucideIcons.chevronDown,
            onPressed: () => presses++,
          ),
        ),
      );
      final box = tester.getRect(find.byType(PInputButton));
      await tester.tapAt(box.center);
      await tester.tapAt(box.topLeft + const Offset(4, 4)); // 여백
      await tester.tap(
        find.byIcon(LucideIcons.calendarDays),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byIcon(LucideIcons.chevronDown),
        warnIfMissed: false,
      );
      expect(presses, 4);
    });

    testWidgets('비활성 · 읽기 전용은 열지 않는다 — 읽기 전용은 포커스는 된다', (tester) async {
      var presses = 0;
      for (final readOnly in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PInputButton(
              key: UniqueKey(),
              value: '값',
              disabled: !readOnly,
              readOnly: readOnly,
              onPressed: () => presses++,
              onClear: () {},
            ),
          ),
        );
        await tester.tap(find.byType(PInputButton));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        // 눌러도 칸이 눌린 모습이 되지 않는다
        expect(_contentScale(tester, find.byType(PInputButton)).scale, 1);
        expect(find.byIcon(LucideIcons.circleX), findsNothing);
        if (readOnly) {
          // 읽기 전용은 키보드로 포커스가 닿는다
          expect(FocusManager.instance.primaryFocus?.context, isNotNull);
          expect(_ring(tester, find.byType(PInputButton)), isNotNull);
        } else {
          expect(_ring(tester, find.byType(PInputButton)), isNull);
        }
      }
      expect(presses, 0);
    });

    testWidgets('키보드 — Enter · Space 로 연다, 링은 키보드 포커스에만', (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputButton(placeholder: '날짜 선택', onPressed: () => presses++),
        ),
      );
      final c = find.byType(PInputButton);
      // 터치로 눌러서는 링이 없다
      await tester.tap(c);
      await tester.pump(const Duration(milliseconds: 300));
      expect(presses, 1);
      expect(_ring(tester, c), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(tester, c), isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(presses, 3);
    });

    testWidgets('지우기 — 열지 않고 onClear 만, 포커스는 칸으로, 칸은 눌리지 않는다', (tester) async {
      var presses = 0;
      var clears = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputButton(
            focusNode: node,
            value: '김하나',
            suffixIcon: LucideIcons.chevronDown,
            onPressed: () => presses++,
            onClear: () => clears++,
          ),
        ),
      );
      final clear = find.byIcon(LucideIcons.circleX);
      // 누르는 동안 — 지우기만 준다(기준 24), 칸의 콘텐츠는 그대로
      final finger = await tester.startGesture(tester.getCenter(clear));
      await tester.pump(const Duration(milliseconds: 400));
      final scales = tester
          .widgetList<AnimatedScale>(find.byType(AnimatedScale))
          .toList();
      expect(scales.first.scale, 1, reason: '콘텐츠');
      expect(scales.last.scale, closeTo(22 / 24, 0.0005), reason: '지우기');
      expect(
        _frame(tester, find.byType(PInputButton))[0].color ?? _transparent,
        _transparent,
        reason: '상자는 눌리지 않는다',
      );
      await finger.up();
      await tester.pump(const Duration(milliseconds: 400));
      expect(clears, 1);
      expect(presses, 0);
      expect(node.hasFocus, isTrue);
    });

    testWidgets('지우기 — 누르는 영역은 44 까지 넓다', (tester) async {
      var clears = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputButton(value: '김하나', onPressed: () {}, onClear: () => clears++),
        ),
      );
      final center = tester.getCenter(find.byIcon(LucideIcons.circleX));
      await tester.tapAt(center + const Offset(-20, 0)); // 22 밖, 44 안
      await tester.pump();
      expect(clears, 1);
    });

    testWidgets('지우기는 onClear 가 있고 값이 있을 때만', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const Column(
            children: [
              PInputButton(value: '값'),
              PInputButton(placeholder: '선택', onClear: _noop),
            ],
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.circleX), findsNothing);
    });

    testWidgets('누름 배율 기준 — max(높이, 폭 ÷ 4, 24): 넓은 칸 · 좁은 칸', (tester) async {
      for (final width in [320.0, 100.0]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PInputButton(key: UniqueKey(), value: '값', onPressed: () {}),
            width: width,
          ),
        );
        final finger = await tester.startGesture(
          tester.getCenter(find.byType(PInputButton)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        final basis = [52.0, width / 4, 24.0].reduce((a, b) => a > b ? a : b);
        expect(
          _contentScale(tester, find.byType(PInputButton)).scale,
          closeTo((basis - 2) / basis, 0.0005),
          reason: '폭 $width',
        );
        await finger.up();
      }
    });

    testWidgets('모션 줄이기 — 줄지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputButton(value: '값', onPressed: () {}),
          reduceMotion: true,
        ),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(PInputButton)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_contentScale(tester, find.byType(PInputButton)).scale, 1);
      await finger.up();
    });

    testWidgets('Field — 라벨을 누르면 포커스만 가고 열리지 않는다 · 오류 · 필수 · 막힘을 받는다', (
      tester,
    ) async {
      var presses = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(
            label: '날짜',
            required: true,
            invalid: true,
            errorMessage: '날짜를 골라주세요.',
            child: PInputButton(
              focusNode: node,
              placeholder: '날짜 선택',
              onPressed: () => presses++,
            ),
          ),
        ),
      );
      await tester.tap(findRichPlain('날짜').first);
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(presses, 0);
      // Field 의 오류가 칸에 온다 — 안쪽 2px 빨강
      final overlay =
          (_frame(tester, find.byType(PInputButton))[1].border! as Border).top;
      expect(overlay.width, 2);
      expect(overlay.color.a, greaterThan(0));
      // 막힘은 Field 에서 받는다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(
            label: '날짜',
            disabled: true,
            child: PInputButton(
              placeholder: '날짜 선택',
              onPressed: () => presses++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PInputButton));
      expect(presses, 0);
    });

    testWidgets('이름 — 라벨 + 고른 값(비었으면 placeholder) · 설명 · 지우기 · 읽는 순서', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PField(
                label: '날짜',
                description: '휴가를 시작하는 날이에요.',
                child: PInputButton(
                  value: '10월 1일 (목)',
                  prefixText: '만',
                  suffixIcon: LucideIcons.calendarDays,
                  expanded: false,
                  onPressed: () {},
                  onClear: () {},
                  clearLabel: '비우기',
                ),
              ),
              const PInputButton(semanticLabel: '시각', placeholder: '시각 선택'),
            ],
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('날짜').first);
      expect(node.label, '날짜');
      expect(node.value, '10월 1일 (목)');
      expect(node.hint, contains('휴가를 시작하는 날이에요.'));
      expect(node.hint, contains('만'));
      // 붙이개 글 · 값은 따로 읽히지 않고 하나의 이름으로 묶인다
      expect(find.bySemanticsLabel('비우기'), findsOneWidget);
      expect(find.bySemanticsLabel('지우기'), findsNothing);
      final empty = tester.getSemantics(find.bySemanticsLabel('시각'));
      expect(empty.label, '시각');
      expect(empty.value, '시각 선택');
      handle.dispose();
    });

    testWidgets('clearLabel 을 안 주면 "지우기"', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, const PInputButton(value: '값', onClear: _noop)),
      );
      expect(find.bySemanticsLabel('지우기'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('긴 값은 한 줄에서 말줄임', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputButton(
            value: '가나다라마바사아자차카타파하 ' * 10,
            suffixIcon: LucideIcons.chevronDown,
            onClear: _noop,
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(PInputButton),
          matching: findTextContaining('가나다라'),
        ),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PInputButton)).height, 52);
    });
  });

  testWidgets('견본이 폰 폭에서 라이트 · 다크로 그려진다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final mode in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
              child: InputButtonDemo(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }
  });
}

void _noop() {}
