// Select Box 가 스펙 값(test/fixtures/design_spec/select-box.json)대로인지 — 배치(가로 · 세로) × 고름 × 상태(기본 · 누름 ·
// 비활성) × 라이트 · 다크의 상자 · 누르는 자리 · 앞 · 본문 · 컨트롤, 펼침 · 격자(열 · 같은 높이) · 동작. 웹은 같은 JSON 을
// 크로미움에서 잰다.
//
// 앱에 없는 상태(웹의 hovered · focused — 올림 · 포커스 링)는 재지 않는다.
import 'dart:math' as math;
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/select_box/p_select_box.dart';
import 'package:groo_damda_app/shared/ds/select_box/select_box_demo.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('select-box');

/// 앱의 상태 — 웹의 hovered(올림) · focused(키보드 포커스 링)는 앱에 없다.
final _appStates = _spec.states
    .where((s) => s != 'hovered' && s != 'focused')
    .toList();

Widget _host(Brightness mode, Widget child, {double width = 312}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

Finder get _root => find.byKey(const ValueKey('select-box-root'));
Finder get _trigger => find.byKey(const ValueKey('select-box-trigger'));
Finder get _content => find.byKey(const ValueKey('select-box-content'));
Finder get _label => find.byKey(const ValueKey('select-box-label'));
Finder get _description => find.byKey(const ValueKey('select-box-description'));
Finder get _footer => find.byKey(const ValueKey('select-box-footer'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

BoxDecoration _deco(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;

TextStyle _style(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).style!;

/// 상자 하나 — 앞 아이콘 · 제목 · 설명 · 라디오.
Widget _box({
  required PSelectBoxLayout layout,
  required bool selected,
  required bool disabled,
}) => PRadioSelectBoxGroup<String>(
  value: selected ? 'a' : 'b',
  onChanged: disabled ? null : (_) {},
  semanticLabel: '종료',
  children: [
    PRadioSelectBox<String>(
      value: 'a',
      layout: layout,
      prefix: const Icon(LucideIcons.fileText),
      label: '무기한',
      description: '중지할 때까지 계속 반복',
    ),
  ],
);

class _Check {
  _Check(this.mode, this.want, this.where);

  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];
  final measured = <String>{};

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    measured.add(key);
    final w = pickMode(want[key], mode);
    if (w == null) return fail('$key: 스펙에 없다');
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    measured.add(key);
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if ((w - actual).abs() > 0.5) fail('$key: 스펙 $w · 실제 $actual');
  }

  void typo(String key, TextStyle style) {
    measured.add(key);
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
      fail('$key 글꼴: 스펙 $family · 실제 ${style.fontFamily}');
    }
    final slot = key.split('.').first;
    final w = want['$slot.fontWeight'] ?? t['fontWeight'];
    measured.add('$slot.fontWeight');
    if (style.fontWeight?.value != w) {
      fail('$key: 굵기 스펙 $w · 실제 ${style.fontWeight}');
    }
  }

  void exact(String key, Object? actual) {
    measured.add(key);
    if ('${want[key]}' != '$actual') fail('$key: 스펙 ${want[key]} · 실제 $actual');
  }

  void motion(String durationKey, String easingKey, Duration d, Curve curve) {
    measured.addAll([durationKey, easingKey]);
    if (want[durationKey] != null && specMs(want[durationKey]) != d) {
      fail('$durationKey: 스펙 ${want[durationKey]} · 실제 $d');
    }
    if (want[easingKey] != null) {
      final cubic = specCubic(want[easingKey]);
      if (curve is! Cubic ||
          [curve.a, curve.b, curve.c, curve.d].join(',') != cubic.join(',')) {
        fail('$easingKey: 스펙 ${want[easingKey]} · 실제 $curve');
      }
    }
  }

  void coverage(Set<String> elsewhere) {
    for (final key in want.keys) {
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}

/// 앱에 없는 값 — 포커스 링은 웹 상태(키보드 포커스 링)다.
const _webOnly = {'focusRing.width', 'focusRing.offset', 'focusRing.color'};

/// 다른 테스트가 보는 값 — 펼침 여백(펼침 테스트) · 묶음 사이(격자 테스트) · 제목 옆 배지 사이(배지 테스트).
const _elsewhere = {
  'footer.paddingX',
  'footer.paddingBottom',
  'group.gapY',
  'group.gapX',
  'group.columns',
  'label.gap',
  'trigger.grow',
  'root.touchTarget',
};

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['layout', 'selected'])) {
      for (final state in _appStates) {
        final title =
            '${mode.name} ${combo['layout']} ${combo['selected']} $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          final vertical = combo['layout'] == 'vertical';
          await tester.pumpWidget(
            _host(
              mode,
              _box(
                layout: vertical
                    ? PSelectBoxLayout.vertical
                    : PSelectBoxLayout.horizontal,
                selected: combo['selected'] == 'selected',
                disabled: state == 'disabled',
              ),
            ),
          );
          TestGesture? gesture;
          if (state == 'pressed') {
            gesture = await tester.startGesture(tester.getCenter(_trigger));
            await tester.pump();
          }
          await _settle(tester);

          final want = _spec.resolve(combo, state);
          final k = _Check(mode, want, title);

          // 상자 — 바탕 · 모서리 12 · 1px 선 · 고른 테두리 안쪽 2px
          final boxes = find.descendant(
            of: _root,
            matching: find.byType(DecoratedBox),
          );
          final bg = _deco(tester, boxes.at(0));
          final overlay = _deco(tester, boxes.at(1));
          final base = _deco(tester, boxes.at(2));
          k.color('root.background', bg.color ?? const Color(0x00000000));
          k.px('root.radius', (bg.borderRadius as BorderRadius).topLeft.x);
          final wide = want['root.borderWidth'] == 2;
          final side = wide
              ? (overlay.border! as Border).bottom
              : (base.border! as Border).bottom;
          k.color('root.borderColor', side.color);
          k.px('root.borderWidth', side.width);
          if (!wide && (overlay.border! as Border).bottom.color.a != 0) {
            k.fail('덧그린 2px 가 남아 있다');
          }
          // 안쪽에 그린다 — 내용이 밀리지 않는다(상자 크기에 선 두께가 더해지지 않는다)
          final rest = tester.getSize(_root);
          if (rest.height < 44) k.fail('root.touchTarget: 높이 ${rest.height}');
          k.measured.add('root.touchTarget');
          // 바탕 전환 150ms
          final tween = tester.widget<TweenAnimationBuilder<double>>(
            find
                .ancestor(
                  of: _root,
                  matching: find.byType(TweenAnimationBuilder<double>),
                )
                .first,
          );
          k.motion(
            'root.transitionDuration',
            'root.transitionEasing',
            tween.duration,
            tween.curve,
          );
          k.measured.add('root.transitionProperty');

          // 누르는 자리 — 안쪽 여백 · 정렬 · 사이 6 · 눌림 축소 · 커서
          final padding =
              tester.widget<Padding>(_trigger).padding as EdgeInsets;
          if (vertical) {
            k.px('trigger.paddingX', padding.left);
            if (padding.left != padding.right) k.fail('paddingX 가 좌우 다르다');
            k.px('trigger.paddingY', padding.top);
          } else {
            k.px('trigger.paddingLeft', padding.left);
            k.px('trigger.paddingRight', padding.right);
            k.px('trigger.paddingY', padding.top);
          }
          if (padding.top != padding.bottom) k.fail('paddingY 가 위아래 다르다');
          final row = tester.widget<Row>(
            find.descendant(of: _trigger, matching: find.byType(Row)).first,
          );
          k.px('trigger.gap', row.spacing);
          k.exact(
            'trigger.alignItems',
            row.crossAxisAlignment == CrossAxisAlignment.center
                ? 'center'
                : 'flex-start',
          );
          final scale = tester.widget<AnimatedScale>(
            find.ancestor(of: _trigger, matching: find.byType(AnimatedScale)),
          );
          final size = tester.getSize(_content);
          final basis = math.max(size.height, math.max(size.width / 4, 24.0));
          final wantScale = want['trigger.scale'] != null
              ? (basis - 2) / basis
              : 1.0;
          k.measured.add('trigger.scale');
          if ((scale.scale - wantScale).abs() > 1e-3) {
            k.fail('trigger.scale: 스펙 $wantScale · 실제 ${scale.scale}');
          }
          k.motion(
            'trigger.transitionDuration',
            'trigger.transitionEasing',
            scale.duration,
            scale.curve,
          );
          k.measured.add('trigger.transitionProperty');
          final cursor = tester
              .widget<MouseRegion>(
                find
                    .ancestor(of: _root, matching: find.byType(MouseRegion))
                    .first,
              )
              .cursor;
          k.measured.add('trigger.cursor');
          final wantCursor = want['trigger.cursor'] == 'pointer'
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden;
          if (cursor != wantCursor) {
            k.fail('trigger.cursor: 스펙 ${want['trigger.cursor']} · 실제 $cursor');
          }

          // 앞 · 본문 · 컨트롤
          final icon = find.byIcon(LucideIcons.fileText);
          k.px('prefix.size', tester.getSize(icon).width);
          k.color('prefix.color', IconTheme.of(tester.element(icon)).color!);
          final contentFlow = vertical
              ? tester.widget<Column>(
                  find.ancestor(of: icon, matching: find.byType(Column)).first,
                )
              : null;
          final contentRow = vertical
              ? null
              : tester.widget<Row>(
                  find.ancestor(of: icon, matching: find.byType(Row)).first,
                );
          k.px(
            'content.gap',
            vertical ? contentFlow!.spacing : contentRow!.spacing,
          );
          k.exact('content.direction', vertical ? 'column' : 'row');
          final body = tester.widget<Column>(
            find.ancestor(of: _label, matching: find.byType(Column)).first,
          );
          k.px('body.gap', body.spacing);
          final bodyPad = tester.widget<Padding>(
            find.ancestor(of: _label, matching: find.byType(Padding)).first,
          );
          k.px('body.paddingRight', (bodyPad.padding as EdgeInsets).right);
          k.typo('label.typography', _style(tester, _label));
          k.color('label.foreground', _style(tester, _label).color!);
          k.measured.add('label.fontWeight');
          k.typo('description.typography', _style(tester, _description));
          k.color(
            'description.foreground',
            _style(tester, _description).color!,
          );
          k.px(
            'control.size',
            tester.getSize(find.byType(PRadiomark).first.hitTestable()).width,
          );

          k.coverage(
            {..._webOnly, ..._elsewhere}..removeWhere(k.measured.contains),
          );
          expect(k.failures, isEmpty, reason: k.failures.join('\n'));
          await gesture?.up();
          await _settle(tester);
        });
      }
    }
  }

  group('컨트롤', () {
    testWidgets('하나 고르기는 라디오 · 여럿은 칸 없는 체크(꺼지면 옅은 체크) · 없음은 그리지 않는다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: [
              PRadioSelectBoxGroup<String>(
                value: 'a',
                onChanged: (_) {},
                semanticLabel: '하나',
                children: const [
                  PRadioSelectBox<String>(value: 'a', label: '가'),
                  PRadioSelectBox<String>(
                    value: 'b',
                    label: '나',
                    control: PRadioSelectBoxControl.none,
                  ),
                ],
              ),
              PCheckSelectBoxGroup(
                semanticLabel: '여럿',
                children: [
                  PCheckSelectBox(
                    label: '다',
                    checked: false,
                    onChanged: (_) {},
                  ),
                  PCheckSelectBox(
                    label: '라',
                    checked: true,
                    onChanged: (_) {},
                    control: PCheckSelectBoxControl.none,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.byType(PRadiomark), findsOneWidget);
      expect(find.byType(PCheckmark), findsOneWidget);
      final mark = tester.widget<PCheckmark>(find.byType(PCheckmark));
      expect(mark.shape, PCheckboxShape.ghost);
      expect(mark.checked, isFalse);
      // 컨트롤이 없어도 읽기는 유지된다 — 고른 상태 · 제목이 상자의 이름
      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(findText(keepAll('라')));
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      expect(node.label, contains('라'));
      handle.dispose();
    });
  });

  group('동작', () {
    testWidgets('하나 고르기 — 상자 어디를 눌러도 고르고, 고른 것을 다시 눌러도 풀리지 않는다', (
      tester,
    ) async {
      final picked = <String>[];
      var value = 'a';
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => PRadioSelectBoxGroup<String>(
              value: value,
              semanticLabel: '종료',
              onChanged: (v) => setState(() {
                picked.add(v);
                value = v;
              }),
              children: const [
                PRadioSelectBox<String>(value: 'a', label: '무기한'),
                PRadioSelectBox<String>(
                  value: 'b',
                  label: '횟수 지정',
                  description: '정한 횟수만큼 반복',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(findText(keepAll('무기한')));
      await tester.pump();
      expect(picked, isEmpty);
      // 제목이 아니라 상자의 오른쪽 끝(컨트롤 옆 여백)을 눌러도 고른다
      final second = tester.getRect(_root.at(1));
      await tester.tapAt(Offset(second.right - 3, second.top + 3));
      await tester.pump();
      expect(picked, ['b']);
      await tester.tap(findText(keepAll('횟수 지정')));
      await tester.pump();
      expect(picked, ['b']);
    });

    testWidgets('묶음이 막히면(onChanged 없음) 누를 수 없고, 상자 하나만 막을 수도 있다', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PRadioSelectBoxGroup<String>(
            value: 'a',
            semanticLabel: '종료',
            onChanged: picked.add,
            children: const [
              PRadioSelectBox<String>(value: 'a', label: '무기한'),
              PRadioSelectBox<String>(
                value: 'b',
                label: '막힌 상자',
                enabled: false,
              ),
              PRadioSelectBox<String>(value: 'c', label: '횟수'),
            ],
          ),
        ),
      );
      await tester.tap(findText(keepAll('막힌 상자')));
      await tester.pump();
      expect(picked, isEmpty);
      await tester.tap(findText(keepAll('횟수')));
      await tester.pump();
      expect(picked, ['c']);
    });

    testWidgets('여럿 고르기 — 눌러서 켜고 끈다, Space 로도, Enter 는 누르지 않는다', (
      tester,
    ) async {
      final seen = <bool>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      var checked = false;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => PCheckSelectBoxGroup(
              semanticLabel: '권한',
              children: [
                PCheckSelectBox(
                  label: '휴가 조회',
                  focusNode: node,
                  checked: checked,
                  onChanged: (v) => setState(() {
                    seen.add(v);
                    checked = v;
                  }),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(findText(keepAll('휴가 조회')));
      await tester.pump();
      await tester.tap(findText(keepAll('휴가 조회')));
      await tester.pump();
      expect(seen, [true, false]);
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(seen, hasLength(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(seen, [true, false, true]);
    });

    testWidgets('하나 고르기 키보드 — 화살표로 옮기며 고르고 막힌 상자는 건너뛴다', (tester) async {
      final picked = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              return PRadioSelectBoxGroup<String>(
                value: 'a',
                semanticLabel: '종료',
                onChanged: picked.add,
                children: [
                  PRadioSelectBox<String>(
                    value: 'a',
                    label: '가',
                    focusNode: node,
                  ),
                  const PRadioSelectBox<String>(
                    value: 'b',
                    label: '나',
                    enabled: false,
                  ),
                  const PRadioSelectBox<String>(value: 'c', label: '다'),
                ],
              );
            },
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(picked, ['c']);
    });

    testWidgets('오류 · 필수는 묶음이 읽고 상자의 모양은 바뀌지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(
            label: '종료',
            required: true,
            invalid: true,
            errorMessage: '종료 방식을 골라주세요.',
            child: PRadioSelectBoxGroup<String>(
              value: null,
              onChanged: (_) {},
              children: const [
                PRadioSelectBox<String>(value: 'a', label: '무기한'),
              ],
            ),
          ),
        ),
      );
      final group = tester.getSemantics(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == '종료' &&
              w.properties.isRequired == true,
        ),
      );
      expect(group.flagsCollection.isRequired, Tristate.isTrue);
      expect(group.validationResult, SemanticsValidationResult.invalid);
      // 테두리는 그대로 1px(오류로 굵어지지 않는다)
      final boxes = find.descendant(
        of: _root,
        matching: find.byType(DecoratedBox),
      );
      expect((_deco(tester, boxes.at(1)).border! as Border).bottom.color.a, 0);
      handle.dispose();
    });
  });

  group('펼침', () {
    Widget footerBox(
      Brightness mode,
      PSelectBoxFooterVisibility visibility, {
      required String value,
      bool disableAnimations = false,
    }) => MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: _host(
        mode,
        PRadioSelectBoxGroup<String>(
          value: value,
          onChanged: (_) {},
          semanticLabel: '종료',
          children: [
            PRadioSelectBox<String>(
              value: 'count',
              label: '횟수 지정',
              footerVisibility: visibility,
              footer: const PInput(initialValue: '12', semanticLabel: '반복 횟수'),
            ),
            const PRadioSelectBox<String>(value: 'none', label: '무기한'),
          ],
        ),
      ),
    );

    testWidgets('고르면 상자 아래로 열리고 안쪽 여백은 좌우 20 · 아래 16, 닫히면 보이지 않고 닿지 않는다', (
      tester,
    ) async {
      await tester.pumpWidget(
        footerBox(
          Brightness.light,
          PSelectBoxFooterVisibility.whenSelected,
          value: 'none',
        ),
      );
      await _settle(tester);
      // 닫힘 — 높이 0 · 투명 · 키보드 · 읽기에 닿지 않는다
      final closed = tester.widget<AnimatedAlign>(_footer);
      expect(closed.heightFactor, 0);
      expect(tester.getSize(_root.first).height, lessThan(80));
      expect(
        tester
            .widget<ExcludeFocus>(
              find
                  .ancestor(of: _footer, matching: find.byType(ExcludeFocus))
                  .first,
            )
            .excluding,
        isTrue,
      );
      expect(
        tester
            .widget<ExcludeSemantics>(
              find
                  .ancestor(
                    of: _footer,
                    matching: find.byType(ExcludeSemantics),
                  )
                  .first,
            )
            .excluding,
        isTrue,
      );
      // 열림
      await tester.pumpWidget(
        footerBox(
          Brightness.light,
          PSelectBoxFooterVisibility.whenSelected,
          value: 'count',
        ),
      );
      await tester.pump();
      final opening = tester.widget<AnimatedAlign>(_footer);
      expect(opening.heightFactor, 1);
      // 열 때 높이 400ms · 투명도 300ms
      expect(opening.duration, const Duration(milliseconds: 400));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: _footer,
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .duration,
        PDuration.d6,
      );
      await _settle(tester);
      final inner = tester.getRect(
        find.byKey(const ValueKey('select-box-footer-inner')),
      );
      final input = tester.getRect(find.byType(PInput));
      expect(input.left - inner.left, 20);
      expect(inner.right - input.right, 20);
      expect(inner.bottom - input.bottom, 16);
      // 닫을 때 높이 300ms · 투명도 400ms
      await tester.pumpWidget(
        footerBox(
          Brightness.light,
          PSelectBoxFooterVisibility.whenSelected,
          value: 'none',
        ),
      );
      await tester.pump();
      expect(tester.widget<AnimatedAlign>(_footer).duration, PDuration.d6);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: _footer,
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .duration,
        const Duration(milliseconds: 400),
      );
    });

    testWidgets('펼침 안을 눌러도 고르지 않는다 · 모션 줄이기면 높이는 바로 바뀌고 투명도만 150ms', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PRadioSelectBoxGroup<String>(
            value: 'none',
            onChanged: picked.add,
            semanticLabel: '종료',
            children: const [
              PRadioSelectBox<String>(
                value: 'count',
                label: '횟수 지정',
                footerVisibility: PSelectBoxFooterVisibility.always,
                footer: PInput(initialValue: '12', semanticLabel: '반복 횟수'),
              ),
              PRadioSelectBox<String>(value: 'none', label: '무기한'),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(PInput));
      await tester.pump();
      expect(picked, isEmpty);
      // always — 늘 보인다(접히는 틀이 없다)
      expect(_footer, findsNothing);

      await tester.pumpWidget(
        footerBox(
          Brightness.light,
          PSelectBoxFooterVisibility.whenSelected,
          value: 'count',
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(tester.widget<AnimatedAlign>(_footer).duration, Duration.zero);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: _footer,
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .duration,
        PDuration.d3,
      );
    });

    testWidgets('고르지 않았을 때만 보이는 펼침', (tester) async {
      await tester.pumpWidget(
        footerBox(
          Brightness.light,
          PSelectBoxFooterVisibility.whenNotSelected,
          value: 'none',
        ),
      );
      await _settle(tester);
      expect(tester.widget<AnimatedAlign>(_footer).heightFactor, 1);
    });
  });

  group('격자', () {
    Widget grid(int columns, {required int count, double width = 312}) => _host(
      Brightness.light,
      PRadioSelectBoxGroup<int>(
        value: 0,
        columns: columns,
        onChanged: (_) {},
        semanticLabel: '고르기',
        children: [
          for (var i = 0; i < count; i++)
            PRadioSelectBox<int>(
              value: i,
              control: PRadioSelectBoxControl.none,
              label: i == 1 ? '긴 제목의 상자 하나 둘 셋 넷 다섯' : '짧음',
              description: i == 1
                  ? '설명이 길어서 여러 줄로 늘어나는 상자 하나 둘 셋 넷 다섯 여섯'
                  : null,
            ),
        ],
      ),
      width: width,
    );

    for (final columns in [1, 2, 3]) {
      testWidgets('$columns열 — 상자 사이 가로 · 세로 12, 폭은 똑같이 나눈다', (tester) async {
        await tester.pumpWidget(grid(columns, count: 6));
        final rects = [for (var i = 0; i < 6; i++) tester.getRect(_root.at(i))];
        final cell = (312 - 12.0 * (columns - 1)) / columns;
        for (final r in rects) {
          expect(r.width, closeTo(cell, 0.5));
        }
        if (columns > 1) {
          expect(rects[1].left - rects[0].right, closeTo(12, 0.5));
        }
        // 줄 사이 세로 12
        final rowBelow = rects[columns];
        expect(rowBelow.top - rects[0].bottom, closeTo(12, 0.5));
      });
    }

    testWidgets('2열 이상은 묶음의 모든 줄이 가장 긴 상자의 높이로 같고, 1열은 상자마다 제 높이다', (
      tester,
    ) async {
      await tester.pumpWidget(grid(2, count: 4));
      final heights = [
        for (var i = 0; i < 4; i++) tester.getRect(_root.at(i)).height,
      ];
      expect(
        heights.reduce(math.max) - heights.reduce(math.min),
        lessThan(0.01),
      );
      // 1열은 제 높이 — 긴 상자만 높다
      await tester.pumpWidget(grid(1, count: 4));
      final one = [
        for (var i = 0; i < 4; i++) tester.getRect(_root.at(i)).height,
      ];
      expect(one.reduce(math.max) - one.reduce(math.min), greaterThan(1));
    });

    testWidgets('2 ~ 3열은 세로형(앞이 위) · 1열은 가로형, 같은 높이로 늘면 빈 아래쪽도 눌린다', (
      tester,
    ) async {
      final picked = <int>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PRadioSelectBoxGroup<int>(
            value: 0,
            columns: 2,
            onChanged: picked.add,
            semanticLabel: '고르기',
            children: const [
              PRadioSelectBox<int>(
                value: 0,
                prefix: Icon(LucideIcons.fileText),
                label: '짧음',
              ),
              PRadioSelectBox<int>(
                value: 1,
                prefix: Icon(LucideIcons.fileText),
                label: '긴 제목의 상자 하나 둘 셋 넷 다섯',
                description: '설명이 길어서 여러 줄로 늘어나는 상자 하나 둘 셋 넷 다섯 여섯',
              ),
            ],
          ),
        ),
      );
      // 세로형 — 앞이 본문 위
      final icon = tester.getRect(find.byIcon(LucideIcons.fileText).first);
      final label = tester.getRect(_label.first);
      expect(label.top, greaterThan(icon.bottom));
      // 짧은 상자의 비어 있는 아래쪽을 눌러도 고른다 — 그 상자는 이미 고른 상자(0)라 알리지 않고, 둘째 상자 빈 곳
      final second = tester.getRect(_root.at(1));
      final firstBox = tester.getRect(_root.at(0));
      expect(firstBox.height, second.height);
      await tester.tapAt(Offset(firstBox.center.dx, firstBox.bottom - 4));
      await tester.pump();
      expect(picked, isEmpty);
      await tester.tapAt(Offset(second.center.dx, second.bottom - 4));
      await tester.pump();
      expect(picked, [1]);
    });
  });

  group('제목 옆 배지 · 가장 나쁜 값', () {
    testWidgets('배지는 제목 옆 4', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PRadioSelectBoxGroup<String>(
            value: 'a',
            onChanged: (_) {},
            semanticLabel: '플랜',
            children: const [
              PRadioSelectBox<String>(
                value: 'a',
                label: '연간',
                labelBadge: SizedBox(
                  key: ValueKey('badge'),
                  width: 30,
                  height: 18,
                ),
              ),
            ],
          ),
        ),
      );
      final label = tester.getRect(_label);
      final badge = tester.getRect(find.byKey(const ValueKey('badge')));
      expect(badge.left - label.right, closeTo(4, 0.5));
    });

    testWidgets('긴 제목 · 긴 설명은 줄바꿈하고 낱말 안에서는 끊지 않는다(넘치지 않는다)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PRadioSelectBoxGroup<String>(
            value: 'a',
            columns: 3,
            onChanged: (_) {},
            semanticLabel: '좁음',
            children: const [
              PRadioSelectBox<String>(
                value: 'a',
                control: PRadioSelectBoxControl.none,
                label: '프리미엄 카드의 연회비 환급',
                description: '월 한도 1,234,567,890원까지 합산해서 계산하고 한도를 넘기면 사라져요',
              ),
              PRadioSelectBox<String>(
                value: 'b',
                control: PRadioSelectBoxControl.none,
                label: '초장문테스트용낱말이한줄보다길어서끊겨야하는경우',
              ),
              PRadioSelectBox<String>(
                value: 'c',
                control: PRadioSelectBoxControl.none,
                label: '짧음',
              ),
            ],
          ),
          width: 342,
        ),
      );
      expect(tester.takeException(), isNull);
      final heights = [
        for (var i = 0; i < 3; i++) tester.getRect(_root.at(i)).height,
      ];
      expect(
        heights.reduce(math.max) - heights.reduce(math.min),
        lessThan(0.01),
      );
    });
  });

  testWidgets(
    'density compact(세로형) — 위아래 12 · 앞 ↔ 본문 4, 기본은 20 · 10 (스펙 trigger.paddingY · content.gap)',
    (tester) async {
      Widget box(PSelectBoxDensity d) => PRadioSelectBoxGroup<String>(
        value: null,
        onChanged: (_) {},
        columns: 2,
        children: [
          PRadioSelectBox<String>(
            value: 'a',
            label: '투자',
            prefix: const Icon(LucideIcons.chartLine, size: 22),
            control: PRadioSelectBoxControl.none,
            density: d,
          ),
        ],
      );
      final heights = <double>[];
      final gaps = <double>[];
      for (final d in PSelectBoxDensity.values) {
        await tester.pumpWidget(_host(Brightness.light, box(d)));
        final padding = tester.widget<Padding>(_trigger).padding as EdgeInsets;
        expect(padding.left, 16);
        expect(padding.top, d == PSelectBoxDensity.compact ? 12 : 20);
        expect(padding.bottom, padding.top);
        final col = tester.widget<Column>(
          find.descendant(of: _content, matching: find.byType(Column)).first,
        );
        gaps.add(col.spacing);
        heights.add(tester.getSize(_root).height);
      }
      expect(gaps, [10, 4]);
      expect(heights[0] - heights[1], 8 * 2 + 6); // 위아래 8씩 + 앞 ↔ 본문 6
    },
  );

  testWidgets('카탈로그 견본이 그려진다', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(Brightness.light, const SelectBoxDemo(), width: 342),
    );
    expect(tester.takeException(), isNull);
  });
}
