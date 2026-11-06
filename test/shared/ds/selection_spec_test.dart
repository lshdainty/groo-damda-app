// 5 선택 컨트롤(Checkbox · Radio · Switch)이 스펙 값(test/fixtures/design_spec/{checkbox,radio-group,switch}.json)대로
// 그려지는지 — 조합 × 상태 × 라이트 · 다크를 모두 돈다. 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱에 없는 상태(웹의 hovered · focused — 올림 · 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 —
// 누름 축소("세로 2px 축소")는 그려진 크기로, 누르는 영역("44 × 44")은 넓힌 자리를 눌러서, 줄 맞춤(alignSelf
// flex-start)은 넓은 부모 안에서, 아이콘(lucide Check · Minus, 선 3)은 그린 선으로 잰다.
import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/checkbox/checkbox_demo.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/radio/radio_demo.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';
import 'package:groo_damda_app/shared/ds/switch/switch_demo.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _checkbox = DesignSpec.load('checkbox');
final _radio = DesignSpec.load('radio-group');
final _switch = DesignSpec.load('switch');

/// 앱의 상태 — 웹의 hovered(올림) · focused(키보드 포커스 링)는 앱에 없다.
List<String> _appStates(DesignSpec spec) =>
    spec.states.where((s) => s != 'hovered' && s != 'focused').toList();

Widget _host(Brightness mode, Widget child, {bool reduceMotion = false}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: Center(child: child)),
  );
  return reduceMotion
      ? MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app,
        )
      : app;
}

/// 누름이면 누른 채로 두고, 전환(색 150ms · 누름 축소 150ms · 엄지 150ms)이 끝나게 기다린다.
Future<TestGesture?> _settle(
  WidgetTester tester,
  String state,
  Finder target,
) async {
  TestGesture? gesture;
  if (state == 'pressed') {
    gesture = await tester.startGesture(tester.getCenter(target));
    // 누른 프레임 — 여기서 누름 색 · 축소가 시작된다
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
  return gesture;
}

/// 실패를 모으는 도우미 — 색 · 수 · 글자를 스펙과 맞춘다.
class _Check {
  _Check(this.mode, this.want, this.where);

  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return;
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  void exact(String key, num actual) {
    final w = want[key];
    if (w is num && (w - actual).abs() > 1e-3) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  void typo(String key, TextStyle style) {
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
    final w = want[key];
    if (w is num && style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }

  void family(String key, TextStyle style) {
    final w = want[key];
    if (w is String && w.split(',').first.trim() != style.fontFamily) {
      fail('$key: 스펙 $w · 실제 ${style.fontFamily}');
    }
  }

  /// 웹 cursor — pointer 는 손가락(click), not-allowed 는 금지(forbidden). 마우스를 쓰는 태블릿에서 보인다.
  void cursor(String key, MouseCursor actual) {
    final expected = switch (want[key]) {
      'pointer' => SystemMouseCursors.click,
      'not-allowed' => SystemMouseCursors.forbidden,
      _ => null,
    };
    if (expected != null && actual != expected) {
      fail('$key: 스펙 ${want[key]} · 실제 $actual');
    }
  }

  void radius(String key, BoxDecoration deco) =>
      px(key, (deco.borderRadius! as BorderRadius).topLeft.x);

  /// 테두리 — 스펙에 두께가 없거나 0 이면 그리지 않는다. 안쪽에 그려 크기가 변하지 않는다.
  void border(String slot, BoxDecoration deco) {
    final border = deco.border as Border?;
    final width = border?.top.width ?? 0;
    final wantWidth = want['$slot.borderWidth'] as num? ?? 0;
    if ((wantWidth - width).abs() > 1e-3) {
      fail('$slot.borderWidth: 스펙 $wantWidth · 실제 $width');
    }
    if (width > 0) {
      color('$slot.borderColor', border!.top.color);
      if (border.top.strokeAlign != BorderSide.strokeAlignInside) {
        fail('$slot 테두리가 안쪽이 아니다');
      }
    }
  }

  /// 누름 축소 — 스펙에 그 값이 있으면(누름) 기준 길이 max(높이, 폭 ÷ 4, 24) 에서 세로 2px, 없으면 1.
  void pressScale(String key, double actual, Size size) {
    var expected = 1.0;
    if (want[key] != null) {
      final basis = math.max(size.height, math.max(size.width / 4, 24.0));
      expected = (basis - 2) / basis;
    }
    if ((expected - actual).abs() > 1e-3) {
      fail('$key: 배율 스펙 $expected · 실제 $actual');
    }
  }

  /// 스펙이 푼 값은 모두 어딘가에서 잰다 — 여기서 재거나([measured]), 동작 테스트가 보거나, 앱에 없는 값이다
  /// ([elsewhere]). 스펙에 새 값이 생기면 여기서 걸린다(재지 않고 지나가지 않게).
  void coverage(Set<String> measured, Set<String> elsewhere) {
    for (final key in want.keys) {
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }

  void motion(String durationKey, String easingKey, Duration d, Curve curve) {
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
}

/// 그 상자가 그린 것 — 체크 · 가로줄의 선을 꺼낸다.
List<RecordedInvocation> _paintCalls(WidgetTester tester, Finder finder) {
  final canvas = TestRecordingCanvas();
  tester
      .renderObject(finder)
      .paint(TestRecordingPaintingContext(canvas), Offset.zero);
  return canvas.invocations;
}

/// 라벨 — 줄 안의 글 하나.
Text _labelOf(WidgetTester tester, Finder control) => tester.widget<Text>(
  find.descendant(of: control, matching: find.byType(Text)),
);

/// 줄의 커서 — 줄을 덮는 MouseRegion 의 것.
MouseCursor _cursorOf(WidgetTester tester, Finder control) => tester
    .widget<MouseRegion>(
      find.descendant(of: control, matching: find.byType(MouseRegion)).first,
    )
    .cursor;

BoxDecoration _decoration(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;

/// 앱에 없는 값 · 문장으로 된 값 — 포커스 링은 웹 상태(키보드 포커스 링)이고, transitionProperty 는 무엇이 함께
/// 바뀌는지의 글이다(색 셋이 한 전환으로 바뀐다 — 모션 테스트가 본다).
const _webOnly = {'focusRing.width', 'focusRing.offset', 'focusRing.color'};

/// 줄의 동작 테스트가 보는 값 — 줄 맞춤(alignSelf) · 누르는 영역(touchTarget) · 묶음 줄 사이(group.gap).
const _rowBehavior = {'root.alignSelf', 'root.touchTarget', 'group.gap'};

const _labelKeys = {
  'label.typography',
  'label.fontWeight',
  'label.fontFamily',
  'label.foreground',
};

const _rowKeys = {'root.gap', 'root.minHeight', 'root.cursor'};

// ── Checkbox ───────────────────────────────────────────────

bool? _checkedOf(String value) => switch (value) {
  'checked' => true,
  'unchecked' => false,
  _ => null,
};

Future<void> _checkCheckbox(
  WidgetTester tester,
  Brightness mode,
  Map<String, String> combo,
  String state,
  List<String> failures,
) async {
  await tester.pumpWidget(
    _host(
      mode,
      PCheckbox(
        key: UniqueKey(),
        label: '이 카드 기억하기',
        checked: _checkedOf(combo['checked']!),
        onChanged: state == 'disabled' ? null : (_) {},
        size: PCheckboxSize.values.byName(combo['size']!),
        shape: PCheckboxShape.values.byName(combo['shape']!),
        tone: PCheckboxTone.values.byName(combo['tone']!),
        weight: PCheckboxWeight.values.byName(combo['weight']!),
      ),
    ),
  );
  final control = find.byType(PCheckbox);
  final gesture = await _settle(tester, state, control);
  final k = _Check(
    mode,
    _checkbox.resolve(combo, state),
    '${mode.name} $combo $state',
  );

  // 놓인 자리(누름 축소 전)와 그려진 칸
  final mark = tester.getRect(find.byType(PCheckmark));
  final boxFinder = find.byKey(const ValueKey('checkmark-box'));
  final box = tester.getRect(boxFinder);
  final deco = _decoration(tester, boxFinder);
  final label = _labelOf(tester, control);
  final labelRect = tester.getRect(
    find.descendant(of: control, matching: find.byType(Text)),
  );

  // 줄
  k.px('root.minHeight', tester.getSize(control).height);
  k.px('root.gap', labelRect.left - mark.right);
  k.cursor('root.cursor', _cursorOf(tester, control));

  // 칸
  k.px('checkmark.size', mark.width);
  k.px('checkmark.size', mark.height);
  k.radius('checkmark.radius', deco);
  k.color('checkmark.background', deco.color!);
  k.border('checkmark', deco);
  k.pressScale('checkmark.scale', box.height / mark.height, mark.size);
  final colors = tester.widget<TweenAnimationBuilder<SelectionColors>>(
    find.descendant(
      of: find.byType(PCheckmark),
      matching: find.byType(TweenAnimationBuilder<SelectionColors>),
    ),
  );
  k.motion(
    'checkmark.transitionDuration',
    'checkmark.transitionEasing',
    colors.duration,
    colors.curve,
  );
  final scale = tester.widget<AnimatedScale>(
    find.descendant(
      of: find.byType(PCheckmark),
      matching: find.byType(AnimatedScale),
    ),
  );
  k.motion(
    'checkmark.scaleDuration',
    'checkmark.scaleEasing',
    scale.duration,
    scale.curve,
  );

  // 아이콘 — lucide 24 칸 좌표, 선 3
  final iconFinder = find.byKey(const ValueKey('checkmark-icon'));
  final iconSize = tester.getSize(iconFinder);
  k.px('icon.size', iconSize.width);
  k.px('icon.size', iconSize.height);
  final strokes = _paintCalls(
    tester,
    iconFinder,
  ).where((c) => c.invocation.memberName == #drawPath).toList();
  final glyph = k.want['icon.glyph'];
  if (glyph == 'none') {
    if (strokes.isNotEmpty) k.fail('icon.glyph: 스펙 none · 실제 그렸다');
  } else if (strokes.length != 1) {
    k.fail('icon.glyph: 스펙 $glyph · 실제 선 ${strokes.length}개');
  } else {
    final path = strokes.single.invocation.positionalArguments[0] as Path;
    final paint = strokes.single.invocation.positionalArguments[1] as Paint;
    final u = iconSize.width / 24;
    final want = glyph == 'Check'
        ? Rect.fromLTRB(4 * u, 6 * u, 20 * u, 17 * u)
        : Rect.fromLTRB(5 * u, 12 * u, 19 * u, 12 * u);
    final bounds = path.getBounds();
    if ((bounds.left - want.left).abs() > 0.01 ||
        (bounds.top - want.top).abs() > 0.01 ||
        (bounds.right - want.right).abs() > 0.01 ||
        (bounds.bottom - want.bottom).abs() > 0.01) {
      k.fail('icon.glyph: 스펙 $glyph($want) · 실제 $bounds');
    }
    if ((paint.strokeWidth / u - 3).abs() > 1e-6 ||
        paint.style != PaintingStyle.stroke ||
        paint.strokeCap != StrokeCap.round ||
        paint.strokeJoin != StrokeJoin.round) {
      k.fail('icon 선: 굵기 3 · 둥근 끝이 아니다 — ${paint.strokeWidth / u}');
    }
    k.color('icon.color', paint.color);
  }

  // 라벨
  k.typo('label.typography', label.style!);
  k.weight('label.fontWeight', label.style!);
  k.family('label.fontFamily', label.style!);
  k.color('label.foreground', label.style!.color!);

  k.coverage(
    {
      ..._rowKeys,
      ..._labelKeys,
      'checkmark.size',
      'checkmark.radius',
      'checkmark.background',
      'checkmark.borderColor',
      'checkmark.borderWidth',
      'checkmark.scale',
      'checkmark.transitionDuration',
      'checkmark.transitionEasing',
      'checkmark.scaleDuration',
      'checkmark.scaleEasing',
      'icon.size',
      'icon.glyph',
      'icon.color',
    },
    {..._webOnly, ..._rowBehavior, 'checkmark.transitionProperty'},
  );

  await gesture?.up();
  failures.addAll(k.failures);
}

// ── Radio ──────────────────────────────────────────────────

Future<void> _checkRadio(
  WidgetTester tester,
  Brightness mode,
  Map<String, String> combo,
  String state,
  List<String> failures,
) async {
  await tester.pumpWidget(
    _host(
      mode,
      PRadioGroup<String>(
        key: UniqueKey(),
        value: combo['checked'] == 'checked' ? 'monthly' : null,
        onChanged: (_) {},
        children: [
          PRadio(
            value: 'monthly',
            label: '매월',
            size: PRadioSize.values.byName(combo['size']!),
            tone: PRadioTone.values.byName(combo['tone']!),
            weight: PRadioWeight.values.byName(combo['weight']!),
            enabled: state != 'disabled',
          ),
        ],
      ),
    ),
  );
  final control = find.byType(PRadio<String>);
  final gesture = await _settle(tester, state, control);
  final k = _Check(
    mode,
    _radio.resolve(combo, state),
    '${mode.name} $combo $state',
  );

  final mark = tester.getRect(find.byType(PRadiomark));
  final ringFinder = find.byKey(const ValueKey('radiomark-ring'));
  final ring = tester.getRect(ringFinder);
  final ringDeco = _decoration(tester, ringFinder);
  final dotFinder = find.byKey(const ValueKey('radiomark-dot'));
  final dotDeco = _decoration(tester, dotFinder);
  final label = _labelOf(tester, control);
  final labelRect = tester.getRect(
    find.descendant(of: control, matching: find.byType(Text)),
  );

  // 줄
  k.px('root.minHeight', tester.getSize(control).height);
  k.px('root.gap', labelRect.left - mark.right);
  k.cursor('root.cursor', _cursorOf(tester, control));

  // 동그라미
  k.px('radiomark.size', mark.width);
  k.px('radiomark.size', mark.height);
  k.radius('radiomark.radius', ringDeco);
  k.color('radiomark.background', ringDeco.color!);
  k.border('radiomark', ringDeco);
  k.pressScale('radiomark.scale', ring.height / mark.height, mark.size);
  final colors = tester.widget<TweenAnimationBuilder<SelectionColors>>(
    find.descendant(
      of: find.byType(PRadiomark),
      matching: find.byType(TweenAnimationBuilder<SelectionColors>),
    ),
  );
  k.motion(
    'radiomark.transitionDuration',
    'radiomark.transitionEasing',
    colors.duration,
    colors.curve,
  );
  // 점은 채움과 같은 전환으로 색만 바뀐다
  k.motion(
    'dot.transitionDuration',
    'dot.transitionEasing',
    colors.duration,
    colors.curve,
  );
  final scale = tester.widget<AnimatedScale>(
    find.descendant(
      of: find.byType(PRadiomark),
      matching: find.byType(AnimatedScale),
    ),
  );
  k.motion(
    'radiomark.scaleDuration',
    'radiomark.scaleEasing',
    scale.duration,
    scale.curve,
  );

  // 가운데 점 — 선택 안 됨에도 자리에 있고 색만 투명하다
  final dot = tester.getSize(dotFinder);
  k.px('dot.size', dot.width);
  k.px('dot.size', dot.height);
  k.radius('dot.radius', dotDeco);
  k.color('dot.color', dotDeco.color!);
  final dotCenter = tester.getCenter(dotFinder);
  if ((dotCenter - ring.center).distance > 0.01) {
    k.fail('dot: 가운데가 아니다 ${dotCenter - ring.center}');
  }

  // 라벨
  k.typo('label.typography', label.style!);
  k.weight('label.fontWeight', label.style!);
  k.family('label.fontFamily', label.style!);
  k.color('label.foreground', label.style!.color!);

  k.coverage(
    {
      ..._rowKeys,
      ..._labelKeys,
      'radiomark.size',
      'radiomark.radius',
      'radiomark.background',
      'radiomark.borderColor',
      'radiomark.borderWidth',
      'radiomark.scale',
      'radiomark.transitionDuration',
      'radiomark.transitionEasing',
      'radiomark.scaleDuration',
      'radiomark.scaleEasing',
      'dot.size',
      'dot.radius',
      'dot.color',
      'dot.transitionDuration',
      'dot.transitionEasing',
    },
    {
      ..._webOnly,
      ..._rowBehavior,
      'radiomark.transitionProperty',
      'dot.transitionProperty',
    },
  );

  await gesture?.up();
  failures.addAll(k.failures);
}

// ── Switch ─────────────────────────────────────────────────

PSwitchSize _switchSize(String size) => PSwitchSize.values.byName('s$size');

Future<void> _checkSwitch(
  WidgetTester tester,
  Brightness mode,
  Map<String, String> combo,
  String state,
  List<String> failures,
) async {
  await tester.pumpWidget(
    _host(
      mode,
      PSwitch(
        key: UniqueKey(),
        label: '종일',
        checked: combo['checked'] == 'checked',
        onChanged: state == 'disabled' ? null : (_) {},
        size: _switchSize(combo['size']!),
        tone: PSwitchTone.values.byName(combo['tone']!),
      ),
    ),
  );
  final control = find.byType(PSwitch);
  final gesture = await _settle(tester, state, control);
  final k = _Check(
    mode,
    _switch.resolve(combo, state),
    '${mode.name} $combo $state',
  );

  // 놓인 자리(누름 축소 전) · 그려진 트랙
  final mark = tester.getRect(find.byType(PSwitchmark));
  final trackFinder = find.byKey(const ValueKey('switchmark-track'));
  final track = tester.getRect(trackFinder);
  final trackDeco = _decoration(tester, trackFinder);
  final press = track.height / mark.height;
  final label = _labelOf(tester, control);
  final labelRect = tester.getRect(
    find.descendant(of: control, matching: find.byType(Text)),
  );

  // 줄
  k.px('root.minHeight', tester.getSize(control).height);
  k.px('root.gap', labelRect.left - mark.right);
  k.cursor('root.cursor', _cursorOf(tester, control));

  // 트랙
  k.px('switchmark.width', mark.width);
  k.px('switchmark.height', mark.height);
  k.radius('switchmark.radius', trackDeco);
  k.color('switchmark.background', trackDeco.color!);
  k.border('switchmark', trackDeco);
  k.pressScale('switchmark.scale', press, mark.size);
  final padding =
      tester
              .widget<Padding>(
                find
                    .descendant(of: trackFinder, matching: find.byType(Padding))
                    .first,
              )
              .padding
          as EdgeInsets;
  k.px('switchmark.padding', padding.left);
  k.px('switchmark.padding', padding.top);
  k.px('switchmark.padding', padding.right);
  k.px('switchmark.padding', padding.bottom);
  final colors = tester.widget<TweenAnimationBuilder<SelectionColors>>(
    find.descendant(
      of: find.byType(PSwitchmark),
      matching: find.byType(TweenAnimationBuilder<SelectionColors>),
    ),
  );
  // 색은 20ms 뒤에 시작해 50ms — 전체 시간에서 늦춤을 뺀 것이 전환 시간이다
  final delay = specMs(k.want['switchmark.transitionDelay']);
  k.motion(
    'switchmark.transitionDuration',
    'switchmark.transitionEasing',
    colors.duration - delay,
    (colors.curve as Interval).curve,
  );
  final interval = colors.curve as Interval;
  if ((interval.begin * colors.duration.inMicroseconds - delay.inMicroseconds)
          .abs() >
      1) {
    k.fail('switchmark.transitionDelay: 스펙 $delay · 실제 ${interval.begin}');
  }
  final thumbMotion = tester.widget<TweenAnimationBuilder<double>>(
    find.descendant(
      of: find.byType(PSwitchmark),
      matching: find.byType(TweenAnimationBuilder<double>),
    ),
  );
  k.motion(
    'thumb.transitionDuration',
    'thumb.transitionEasing',
    thumbMotion.duration,
    thumbMotion.curve,
  );
  final scale = tester.widget<AnimatedScale>(
    find.descendant(
      of: find.byType(PSwitchmark),
      matching: find.byType(AnimatedScale),
    ),
  );
  k.motion(
    'switchmark.scaleDuration',
    'switchmark.scaleEasing',
    scale.duration,
    scale.curve,
  );

  // 엄지 — 누름 축소를 걷어 트랙 좌표로 잰다
  final thumbFinder = find.byKey(const ValueKey('switchmark-thumb'));
  final thumbSize = tester.getSize(thumbFinder);
  final thumbRect = tester.getRect(thumbFinder);
  final thumbDeco = _decoration(tester, thumbFinder);
  final center = mark.center + (thumbRect.center - mark.center) / press;
  k.px('thumb.size', thumbSize.width);
  k.px('thumb.size', thumbSize.height);
  k.radius('thumb.radius', thumbDeco);
  k.color('thumb.color', thumbDeco.color!);
  k.exact('thumb.scale', thumbRect.width / press / thumbSize.width);
  k.px(
    'thumb.translateX',
    center.dx - (mark.left + padding.left + thumbSize.width / 2),
  );
  if ((center.dy - mark.center.dy).abs() > 0.01) {
    k.fail('thumb: 세로 가운데가 아니다 ${center.dy - mark.center.dy}');
  }

  // 라벨
  k.typo('label.typography', label.style!);
  k.weight('label.fontWeight', label.style!);
  k.family('label.fontFamily', label.style!);
  k.color('label.foreground', label.style!.color!);

  k.coverage(
    {
      ..._rowKeys,
      ..._labelKeys,
      'switchmark.width',
      'switchmark.height',
      'switchmark.padding',
      'switchmark.radius',
      'switchmark.background',
      'switchmark.borderColor',
      'switchmark.borderWidth',
      'switchmark.scale',
      'switchmark.transitionDuration',
      'switchmark.transitionEasing',
      'switchmark.transitionDelay',
      'switchmark.scaleDuration',
      'switchmark.scaleEasing',
      'thumb.size',
      'thumb.radius',
      'thumb.color',
      'thumb.scale',
      'thumb.translateX',
      'thumb.transitionDuration',
      'thumb.transitionEasing',
    },
    {
      ..._webOnly,
      ..._rowBehavior,
      'switchmark.transitionProperty',
      'thumb.transitionProperty',
    },
  );

  await gesture?.up();
  failures.addAll(k.failures);
}

void main() {
  // ── 조합 × 상태 × 라이트 · 다크 ─────────────────────────
  group('Checkbox 스펙 값', () {
    final states = _appStates(_checkbox);
    final combos = _checkbox.combos([
      'size',
      'shape',
      'tone',
      'weight',
      'checked',
    ]);
    for (final mode in Brightness.values) {
      for (final shape in _checkbox.axes['shape']!) {
        testWidgets('${mode.name} · $shape — 크기 × 톤 × 굵기 × 체크 여부 × 상태', (
          tester,
        ) async {
          final failures = <String>[];
          for (final combo in combos.where((c) => c['shape'] == shape)) {
            for (final state in states) {
              await _checkCheckbox(tester, mode, combo, state, failures);
            }
          }
          if (failures.isNotEmpty) {
            fail(
              '${failures.length}개가 스펙과 다르다\n${failures.take(20).join('\n')}',
            );
          }
        });
      }
    }
  });

  group('Radio 스펙 값', () {
    final states = _appStates(_radio);
    final combos = _radio.combos(['size', 'tone', 'weight', 'checked']);
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기 × 톤 × 굵기 × 선택 여부 × 상태', (tester) async {
        final failures = <String>[];
        for (final combo in combos) {
          for (final state in states) {
            await _checkRadio(tester, mode, combo, state, failures);
          }
        }
        if (failures.isNotEmpty) {
          fail('${failures.length}개가 스펙과 다르다\n${failures.take(20).join('\n')}');
        }
      });
    }
  });

  group('Switch 스펙 값', () {
    final states = _appStates(_switch);
    final combos = _switch.combos(['size', 'tone', 'checked']);
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기 × 톤 × 켬 · 끔 × 상태', (tester) async {
        final failures = <String>[];
        for (final combo in combos) {
          for (final state in states) {
            await _checkSwitch(tester, mode, combo, state, failures);
          }
        }
        if (failures.isNotEmpty) {
          fail('${failures.length}개가 스펙과 다르다\n${failures.take(20).join('\n')}');
        }
      });
    }
  });

  // ── Checkbox 동작 ─────────────────────────────────────────
  group('Checkbox 동작', () {
    testWidgets('칸이나 라벨을 누르면 바뀐다 — 선택 ↔ 선택 안 됨, 일부 선택이면 선택으로', (tester) async {
      final calls = <bool>[];
      Future<void> pump(bool? checked) => tester.pumpWidget(
        _host(
          Brightness.light,
          PCheckbox(
            label: '단종된 카드도 보기',
            checked: checked,
            onChanged: calls.add,
          ),
        ),
      );

      await pump(false);
      await tester.tap(find.byType(PCheckmark));
      await tester.tap(findText(keepAll('단종된 카드도 보기')));
      expect(calls, [true, true]);

      await pump(true);
      await tester.tap(find.byType(PCheckmark));
      expect(calls.last, false);

      await pump(null);
      await tester.tap(findText(keepAll('단종된 카드도 보기')));
      expect(calls.last, true);
    });

    testWidgets('비활성이면 누르지 않는다 — 누름 모습도 없다', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PCheckbox(label: '이 카드 기억하기', checked: false, onChanged: null),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PCheckbox)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<PCheckmark>(find.byType(PCheckmark)).pressed,
        isFalse,
      );
      await gesture.up();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCheckbox(
            label: '이 카드 기억하기',
            checked: false,
            onChanged: (_) => calls++,
          ),
        ),
      );
      await tester.tap(find.byType(PCheckbox));
      expect(calls, 1);
    });

    testWidgets('누르는 영역은 줄과 따로 44 까지 — 줄(32)의 위아래 6px 밖도 받고 줄 높이는 그대로다', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          // 부모 상자는 넓다 — 넓힌 자리는 부모 안에서만 받는다
          SizedBox(
            height: 100,
            child: Center(
              child: PCheckbox(
                label: '이 카드 기억하기',
                checked: false,
                onChanged: (_) => taps++,
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(PCheckbox));
      expect(rect.height, 32);
      await tester.tapAt(Offset(rect.center.dx, rect.top - 5));
      await tester.tapAt(Offset(rect.center.dx, rect.bottom + 5));
      expect(taps, 2);
      // 44 밖은 받지 않는다
      await tester.tapAt(Offset(rect.center.dx, rect.top - 7));
      await tester.tapAt(Offset(rect.center.dx, rect.bottom + 7));
      expect(taps, 2);
    });

    testWidgets(
      '줄은 표시 + 라벨만큼만 차지한다(Checkbox · Radio · Switch) — 넓은 부모 안에서도 앞에 붙고 나머지는 누르지 않는다',
      (tester) async {
        for (final spec in [_checkbox, _radio, _switch]) {
          expect(spec.resolve({}, 'enabled')['root.alignSelf'], 'flex-start');
        }
        var taps = 0;
        for (final (type, control) in <(Type, Widget)>[
          (
            PCheckbox,
            PCheckbox(label: '금액 고정', checked: false, onChanged: (_) => taps++),
          ),
          (
            PRadioGroup<String>,
            PRadioGroup<String>(
              value: null,
              onChanged: (_) => taps++,
              children: const [PRadio(value: 'monthly', label: '매월')],
            ),
          ),
          (
            PSwitch,
            PSwitch(label: '종일', checked: false, onChanged: (_) => taps++),
          ),
        ]) {
          taps = 0;
          await tester.pumpWidget(
            _host(Brightness.light, SizedBox(width: 300, child: control)),
          );
          final box = tester.getRect(find.byType(type));
          final row = tester.getRect(
            find.descendant(of: find.byType(type), matching: find.byType(Row)),
          );
          expect(box.width, 300, reason: '$type');
          expect(row.left, box.left, reason: '$type');
          expect(row.width, lessThan(200), reason: '$type');
          await tester.tapAt(Offset(box.right - 4, row.center.dy));
          expect(taps, 0, reason: '$type — 줄 밖');
          await tester.tapAt(Offset(row.right - 2, row.center.dy));
          expect(taps, 1, reason: '$type — 줄 끝');
        }
      },
    );

    testWidgets('누르면 칸만 세로 2px 거리 준다(기준 24) — 라벨은 줄지 않는다', (tester) async {
      for (final size in PCheckboxSize.values) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PCheckbox(
              key: UniqueKey(),
              label: '이 카드 기억하기',
              checked: true,
              onChanged: (_) {},
              size: size,
            ),
          ),
        );
        final label = findText(keepAll('이 카드 기억하기'));
        final before = tester.getRect(label);
        final gesture = await tester.startGesture(tester.getCenter(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final mark = tester.getRect(find.byType(PCheckmark));
        final box = tester.getRect(find.byKey(const ValueKey('checkmark-box')));
        expect(box.height, closeTo(mark.height * 22 / 24, 1e-6));
        expect(box.center, mark.center);
        expect(tester.getRect(label), before);
        await gesture.up();
        // 손을 뗀 프레임에 되돌아가기가 시작된다
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          tester.getRect(find.byKey(const ValueKey('checkmark-box'))),
          mark,
        );
      }
    });

    testWidgets('모션 줄이기면 누름 축소가 없고 누름 색만 바뀐다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCheckbox(label: '이 카드 기억하기', checked: false, onChanged: (_) {}),
          reduceMotion: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PCheckbox)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final box = find.byKey(const ValueKey('checkmark-box'));
      expect(tester.getRect(box), tester.getRect(find.byType(PCheckmark)));
      expect(
        _decoration(tester, box).color,
        PColors.light.bgLayerDefaultPressed,
      );
      await gesture.up();
    });

    testWidgets('바탕 · 테두리 · 아이콘 색이 150ms 로 함께 바뀐다 — 처음 그릴 때는 바로', (
      tester,
    ) async {
      final motion =
          (_checkbox.json['motion'] as Map)['선택 안 됨 ↔ 선택 ↔ 일부 선택'] as Map;
      Widget box(bool checked) => _host(
        Brightness.light,
        PCheckbox(label: '이 카드 기억하기', checked: checked, onChanged: (_) {}),
      );
      Color fill() => _decoration(
        tester,
        find.byKey(const ValueKey('checkmark-box')),
      ).color!;

      await tester.pumpWidget(box(true));
      expect(fill(), PColors.light.bgNeutralInverted);
      await tester.pumpWidget(box(false));
      await tester.pump(specMs(motion['duration']) ~/ 2);
      expect(fill().a, inExclusiveRange(0, 1));
      await tester.pump(specMs(motion['duration']));
      expect(fill().a, 0);
    });

    testWidgets('선택 · 일부 선택 · 선택 안 됨과 비활성을 읽고, 라벨이 이름이다', (tester) async {
      final semantics = tester.ensureSemantics();
      Future<SemanticsNode> node(bool? checked, {bool enabled = true}) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PCheckbox(
              label: '이 카드 기억하기',
              checked: checked,
              onChanged: enabled ? (_) {} : null,
            ),
          ),
        );
        // 포커스 노드는 막힘을 다음 프레임에 알린다(Focus 가 그렇다)
        await tester.pump();
        return tester.getSemantics(find.bySemanticsLabel('이 카드 기억하기'));
      }

      expect(
        await node(true),
        isSemantics(
          label: '이 카드 기억하기',
          hasCheckedState: true,
          isChecked: true,
          isCheckStateMixed: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        await node(null),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isCheckStateMixed: true,
        ),
      );
      expect(
        await node(false),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isCheckStateMixed: false,
        ),
      );
      expect(
        await node(false, enabled: false),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: false,
          hasTapAction: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('키보드 — 포커스에서 Space 로 누르고, Enter 는 누르지 않는다(폼 제출에 둔다)', (
      tester,
    ) async {
      final calls = <bool>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCheckbox(
            label: '이 카드 기억하기',
            checked: false,
            onChanged: calls.add,
            focusNode: focus,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, [true]);

      // 비활성은 포커스에서 빠진다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCheckbox(
            label: '이 카드 기억하기',
            checked: false,
            onChanged: null,
            focusNode: focus,
          ),
        ),
      );
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      expect(focus.canRequestFocus, isFalse);
    });

    testWidgets('묶음 — 줄 사이 12, 이웃 줄의 누르는 영역이 겹치지 않고 묶음 이름을 읽는다', (
      tester,
    ) async {
      final want = _checkbox.resolve({}, 'enabled');
      final semantics = tester.ensureSemantics();
      final tapped = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCheckboxGroup(
            semanticLabel: '내보낼 데이터',
            children: [
              for (final item in ['거래 내역', '예산', '메모'])
                PCheckbox(
                  label: item,
                  checked: false,
                  onChanged: (_) => tapped.add(item),
                ),
            ],
          ),
        ),
      );
      final rows = [
        for (var i = 0; i < 3; i++)
          tester.getRect(find.byType(PCheckbox).at(i)),
      ];
      expect(rows[1].top - rows[0].bottom, want['group.gap']);
      expect(rows[2].top - rows[1].bottom, want['group.gap']);
      // 줄 사이 12 의 위쪽 6 은 위 줄, 아래쪽 6 은 아래 줄
      await tester.tapAt(Offset(rows[0].center.dx, rows[0].bottom + 5));
      await tester.tapAt(Offset(rows[1].center.dx, rows[1].top - 5));
      expect(tapped, ['거래 내역', '예산']);
      // 줄은 내용만큼 — 앞에 붙는다
      expect(rows.map((r) => r.left).toSet(), hasLength(1));
      expect(
        tester.getSemantics(find.bySemanticsLabel('내보낼 데이터')),
        isSemantics(label: '내보낼 데이터'),
      );
      semantics.dispose();
    });

    testWidgets('긴 라벨은 낱말 단위로 줄을 바꾸고 칸은 줄 가운데에 선다 — 넘치지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          SizedBox(
            width: 160,
            child: PCheckbox(
              label: '단종된 카드도 결제 내역에 함께 보기',
              checked: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(PCheckbox));
      expect(row.height, greaterThan(32));
      expect(
        tester.getCenter(find.byType(PCheckmark)).dy,
        closeTo(row.center.dy, 1e-6),
      );
    });
  });

  // ── Radio 동작 ────────────────────────────────────────────
  group('Checkbox 묶음 — Field 의 막힘 · 오류', () {
    Widget fielded({
      bool disabled = false,
      bool invalid = false,
      bool? groupDisabled,
      bool? groupInvalid,
      required List<bool> calls,
    }) => PField(
      label: '내보낼 데이터',
      disabled: disabled,
      invalid: invalid,
      errorMessage: invalid ? '하나 이상 골라주세요.' : null,
      child: PCheckboxGroup(
        disabled: groupDisabled,
        invalid: groupInvalid,
        children: [
          PCheckbox(label: '거래 내역', checked: false, onChanged: calls.add),
          PCheckbox(label: '예산', checked: false, onChanged: calls.add),
        ],
      ),
    );

    testWidgets('막힌 Field 안의 칸은 눌리지 않는다 — 묶음 · 칸이 막힘으로 읽힌다', (tester) async {
      final semantics = tester.ensureSemantics();
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(Brightness.light, fielded(disabled: true, calls: calls)),
      );
      await tester.tap(findText(keepAll('거래 내역')), warnIfMissed: false);
      await tester.tap(findText(keepAll('예산')), warnIfMissed: false);
      expect(calls, isEmpty);
      // 칸마다 막힘 — 비활성 색으로 그린다(칸에 onChanged 가 있어도)
      for (final box in tester.widgetList<PCheckmark>(
        find.byType(PCheckmark),
      )) {
        expect(box.enabled, isFalse);
      }
      semantics.dispose();
    });

    testWidgets('막히지 않은 Field 안에서는 그대로 누른다', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(_host(Brightness.light, fielded(calls: calls)));
      await tester.tap(findText(keepAll('거래 내역')));
      expect(calls, [true]);
    });

    testWidgets('묶음에 직접 준 disabled 가 Field 보다 이긴다', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          fielded(disabled: true, groupDisabled: false, calls: calls),
        ),
      );
      await tester.tap(findText(keepAll('거래 내역')));
      expect(calls, [true]);
    });

    testWidgets('Field 의 오류는 칸마다 오류로 읽는다 — 모양은 바뀌지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(Brightness.light, fielded(invalid: true, calls: calls)),
      );
      for (final label in ['거래 내역', '예산']) {
        final node = tester.getSemantics(findText(keepAll(label)));
        expect(node.validationResult, SemanticsValidationResult.invalid);
      }
      // 오류여도 칸은 눌린다 · 모양(비활성 색)은 바뀌지 않는다
      await tester.tap(findText(keepAll('거래 내역')));
      expect(calls, [true]);
      for (final box in tester.widgetList<PCheckmark>(
        find.byType(PCheckmark),
      )) {
        expect(box.enabled, isTrue);
      }
      semantics.dispose();
    });

    testWidgets('Field 밖의 묶음은 아무것도 걸지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCheckboxGroup(
            semanticLabel: '내보낼 데이터',
            children: [
              PCheckbox(label: '거래 내역', checked: false, onChanged: calls.add),
            ],
          ),
        ),
      );
      await tester.tap(findText(keepAll('거래 내역')));
      expect(calls, [true]);
      final node = tester.getSemantics(findText(keepAll('거래 내역')));
      expect(node.validationResult, SemanticsValidationResult.none);
      semantics.dispose();
    });
  });

  group('Radio 동작', () {
    Widget repeatGroup({
      required String? value,
      required ValueChanged<String>? onChanged,
      Map<String, FocusNode> focus = const {},
      String? disabled,
    }) => PRadioGroup<String>(
      value: value,
      onChanged: onChanged,
      semanticLabel: '반복',
      children: [
        for (final (v, label) in const [
          ('none', '반복 없음'),
          ('daily', '매일'),
          ('weekly', '매주'),
          ('monthly', '매월'),
        ])
          PRadio(
            value: v,
            label: label,
            enabled: v != disabled,
            focusNode: focus[v],
          ),
      ],
    );

    testWidgets('하나를 고르면 앞에 고른 것이 풀린다 — 동그라미 · 라벨 어디를 눌러도, 다시 눌러도 풀리지 않는다', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => repeatGroup(
              value: calls.isEmpty ? 'none' : calls.last,
              onChanged: (v) => setState(() => calls.add(v)),
            ),
          ),
        ),
      );
      bool selected(String label) => tester
          .widget<PRadiomark>(
            find.descendant(
              of: find.ancestor(
                of: findText(keepAll(label)),
                matching: find.byType(PRadio<String>),
              ),
              matching: find.byType(PRadiomark),
            ),
          )
          .checked;

      await tester.tap(findText(keepAll('매일')));
      await tester.pump();
      expect(calls, ['daily']);
      expect(selected('매일'), isTrue);
      expect(selected('반복 없음'), isFalse);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: findText(keepAll('매주')),
            matching: find.byType(PRadio<String>),
          ),
          matching: find.byType(PRadiomark),
        ),
      );
      await tester.pump();
      expect(calls, ['daily', 'weekly']);
      expect(selected('매주'), isTrue);
      expect(selected('매일'), isFalse);

      // 고른 것을 다시 누르면 아무 일도 없다
      await tester.tap(findText(keepAll('매주')));
      await tester.pump();
      expect(calls, ['daily', 'weekly']);
    });

    testWidgets('막힌 선택지는 누르지 않고, 막힌 묶음은 모두 막힌다 — 고른 것은 채운 원 그대로 색만', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          repeatGroup(value: 'none', onChanged: calls.add, disabled: 'daily'),
        ),
      );
      await tester.tap(findText(keepAll('매일')), warnIfMissed: false);
      expect(calls, isEmpty);

      await tester.pumpWidget(
        _host(Brightness.light, repeatGroup(value: 'none', onChanged: null)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(findText(keepAll('매주')), warnIfMissed: false);
      expect(calls, isEmpty);
      final marks = tester.widgetList<PRadiomark>(find.byType(PRadiomark));
      expect(marks.every((m) => !m.enabled), isTrue);
      final dot = _decoration(
        tester,
        find.byKey(const ValueKey('radiomark-dot')).first,
      );
      final ring = _decoration(
        tester,
        find.byKey(const ValueKey('radiomark-ring')).first,
      );
      expect(dot.color, PColors.light.fgDisabled);
      expect(ring.color, PColors.light.bgDisabled);
      expect(ring.border, isNull);
      final label = tester.widget<Text>(findText(keepAll('반복 없음')));
      expect(label.style!.color, PColors.light.fgDisabled);
    });

    testWidgets(
      '키보드 — 화살표로 옮기며 고르고(막힌 것은 건너뛰고 끝에서 돈다), Space 로 고르고, Enter 는 고르지 않는다',
      (tester) async {
        final focus = {
          for (final v in ['none', 'daily', 'weekly', 'monthly'])
            v: FocusNode(debugLabel: v),
        };
        addTearDown(() {
          for (final node in focus.values) {
            node.dispose();
          }
        });
        var value = 'none';
        await tester.pumpWidget(
          _host(
            Brightness.light,
            StatefulBuilder(
              builder: (context, setState) => repeatGroup(
                value: value,
                onChanged: (v) => setState(() => value = v),
                focus: focus,
                disabled: 'weekly',
              ),
            ),
          ),
        );
        focus['none']!.requestFocus();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(value, 'daily');
        expect(focus['daily']!.hasPrimaryFocus, isTrue);

        // 막힌 매주를 건너뛴다
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(value, 'monthly');
        expect(focus['monthly']!.hasPrimaryFocus, isTrue);

        // 끝에서 처음으로
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(value, 'none');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(value, 'monthly');

        // 포커스만 옮긴 선택지는 Space 로 고르고, Enter 로는 고르지 않는다
        focus['daily']!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(value, 'monthly');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(value, 'daily');
      },
    );

    testWidgets('Tab 으로 들어오면 고른 선택지로 간다', (tester) async {
      final start = FocusNode(debugLabel: 'start');
      final focus = {
        for (final v in ['none', 'daily', 'weekly', 'monthly'])
          v: FocusNode(debugLabel: v),
      };
      addTearDown(() {
        start.dispose();
        for (final node in focus.values) {
          node.dispose();
        }
      });
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: start,
                child: const SizedBox(width: 10, height: 10),
              ),
              repeatGroup(value: 'weekly', onChanged: (_) {}, focus: focus),
            ],
          ),
        ),
      );
      start.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focus['weekly']!.hasPrimaryFocus, isTrue);
    });

    testWidgets('묶음은 radio group 이고 이름을 읽는다 — 선택지는 라벨 · 선택 여부 · 묶음 안임을 읽는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          repeatGroup(value: 'daily', onChanged: (_) {}, disabled: 'monthly'),
        ),
      );
      final group = tester.getSemantics(find.bySemanticsLabel('반복'));
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      expect(
        tester.getSemantics(find.bySemanticsLabel('매일')),
        isSemantics(
          label: '매일',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('반복 없음')),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: false,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('매월')),
        isSemantics(isEnabled: false, hasTapAction: false),
      );
      semantics.dispose();
    });

    testWidgets(
      'iOS 는 선택을 selected 로 읽고, 고르지 않은 선택지에 "선택되지 않음" 을 덧붙인다(RawRadio 와 같다)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Brightness.light,
            repeatGroup(value: 'daily', onChanged: (_) {}),
          ),
        );
        final context = tester.element(find.byType(PRadioGroup<String>));
        expect(
          tester.getSemantics(find.bySemanticsLabel('매일')),
          isSemantics(isSelected: true, hasSelectedState: true),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('매주')),
          isSemantics(
            isSelected: false,
            hint: WidgetsLocalizations.of(context).radioButtonUnselectedLabel,
          ),
        );
        semantics.dispose();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('누르는 영역은 44 까지 넓히고 놓인 자리는 그대로다 — 묶음 줄 사이 12 는 반씩 나눈다', (
      tester,
    ) async {
      final want = _radio.resolve({}, 'enabled');
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          SizedBox(
            height: 300,
            child: Center(
              child: repeatGroup(value: null, onChanged: calls.add),
            ),
          ),
        ),
      );
      final rows = [
        for (var i = 0; i < 4; i++)
          tester.getRect(find.byType(PRadio<String>).at(i)),
      ];
      expect(rows.first.height, 32);
      expect(rows[1].top - rows[0].bottom, want['group.gap']);
      // 묶음 맨 위 줄은 묶음 밖 6 까지 눌린다(03A-010 — 이웃이 있는 부모 안)
      await tester.tapAt(Offset(rows[0].center.dx, rows[0].top - 5));
      await tester.tapAt(Offset(rows[0].center.dx, rows[0].bottom + 5));
      await tester.tapAt(Offset(rows[1].center.dx, rows[1].top - 5));
      expect(calls, ['none', 'none', 'daily']);
    });

    testWidgets('누르면 동그라미만 세로 2px 거리 준다 — 모션 줄이기면 색만', (tester) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PRadioGroup<String>(
              key: UniqueKey(),
              value: null,
              onChanged: (_) {},
              children: const [PRadio(value: 'monthly', label: '매월')],
            ),
            reduceMotion: reduce,
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(PRadio<String>)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final mark = tester.getRect(find.byType(PRadiomark));
        final ring = find.byKey(const ValueKey('radiomark-ring'));
        expect(
          tester.getRect(ring).height,
          closeTo(reduce ? mark.height : mark.height * 22 / 24, 1e-6),
        );
        expect(
          _decoration(tester, ring).color,
          PColors.light.bgLayerDefaultPressed,
        );
        await gesture.up();
      }
    });

    testWidgets('채움 · 테두리 · 점이 150ms 로 함께 바뀐다 — 점은 커지거나 줄지 않는다', (
      tester,
    ) async {
      final motion = (_radio.json['motion'] as Map)['선택 안 됨 ↔ 선택'] as Map;
      Widget group(String? value) => _host(
        Brightness.dark,
        PRadioGroup<String>(
          value: value,
          onChanged: (_) {},
          children: const [
            PRadio(value: 'monthly', label: '매월', tone: PRadioTone.brand),
          ],
        ),
      );
      final dot = find.byKey(const ValueKey('radiomark-dot'));

      await tester.pumpWidget(group(null));
      final size = tester.getSize(dot);
      await tester.pumpWidget(group('monthly'));
      await tester.pump(specMs(motion['duration']) ~/ 2);
      final mid = _decoration(tester, dot).color!;
      // 투명한 검정을 거치지 않는다 — 흰 점은 처음부터 흰색으로 진해진다
      expect(mid.a, inExclusiveRange(0, 1));
      expect(mid.r, closeTo(1, 1e-6));
      expect(tester.getSize(dot), size);
      await tester.pump(specMs(motion['duration']));
      expect(_decoration(tester, dot).color, PColors.dark.staticWhite);
    });

    // Field 의 막힘 · 오류 · 필수가 묶음에 닿는다(웹 useFieldGroupState, field.md 2026-10-08)
    Widget fielded({
      bool disabled = false,
      bool invalid = false,
      bool required = false,
      required ValueChanged<String> onChanged,
      bool? groupDisabled,
    }) => PField(
      label: '반복',
      disabled: disabled,
      invalid: invalid,
      required: required,
      errorMessage: invalid ? '반복을 골라주세요.' : null,
      child: PRadioGroup<String>(
        value: 'none',
        onChanged: onChanged,
        disabled: groupDisabled,
        children: const [
          PRadio(value: 'none', label: '반복 없음'),
          PRadio(value: 'monthly', label: '매월'),
        ],
      ),
    );

    testWidgets('막힌 Field 안의 선택지는 눌리지 않는다 — 묶음이 막힘이다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, fielded(disabled: true, onChanged: calls.add)),
      );
      await tester.tap(findText(keepAll('매월')), warnIfMissed: false);
      expect(calls, isEmpty);
      // 막힘은 골라 둔 선택을 지우지 않는다
      expect(
        tester
            .widget<PRadioGroup<String>>(find.byType(PRadioGroup<String>))
            .value,
        'none',
      );
    });

    testWidgets('막히지 않은 Field 안에서는 그대로 누른다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(Brightness.light, fielded(onChanged: calls.add)),
      );
      await tester.tap(findText(keepAll('매월')));
      expect(calls, ['monthly']);
    });

    testWidgets('묶음에 직접 준 disabled 가 Field 의 막힘보다 이긴다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          fielded(disabled: true, groupDisabled: false, onChanged: calls.add),
        ),
      );
      await tester.tap(findText(keepAll('매월')));
      expect(calls, ['monthly']);
    });

    testWidgets('Field 의 오류 · 필수를 묶음이 읽는다 — 모양은 바뀌지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          fielded(invalid: true, required: true, onChanged: (_) {}),
        ),
      );
      final node = tester.getSemantics(
        find
            .descendant(
              of: find.byType(PRadioGroup<String>),
              matching: find.byType(Semantics),
            )
            .first,
      );
      // Flutter 3.44 의 플래그는 bool 이 아니라 Tristate 다
      expect(node.flagsCollection.isRequired, Tristate.isTrue);
      expect(node.validationResult, SemanticsValidationResult.invalid);
      semantics.dispose();
    });
  });

  // ── Switch 동작 ───────────────────────────────────────────
  group('Switch 동작', () {
    testWidgets('스위치나 라벨을 누르면 켬 ↔ 끔 — 바로 알린다', (tester) async {
      final calls = <bool>[];
      Future<void> pump(bool checked) => tester.pumpWidget(
        _host(
          Brightness.light,
          PSwitch(label: '종일', checked: checked, onChanged: calls.add),
        ),
      );
      await pump(false);
      await tester.tap(find.byType(PSwitchmark));
      await tester.tap(findText(keepAll('종일')));
      expect(calls, [true, true]);
      await pump(true);
      await tester.tap(find.byType(PSwitchmark));
      expect(calls.last, false);
    });

    testWidgets('비활성이면 누르지 않고 포커스에서 빠진다 — 값은 그대로 보인다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PSwitch(label: '결제 알림', checked: true, onChanged: null),
        ),
      );
      await tester.tap(find.byType(PSwitch), warnIfMissed: false);
      expect(
        tester.getSemantics(find.bySemanticsLabel('결제 알림')),
        isSemantics(
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: false,
          hasTapAction: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('켬 · 끔을 toggled 로 읽고, 라벨이 이름이다', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final checked in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PSwitch(label: '푸시 알림', checked: checked, onChanged: (_) {}),
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('푸시 알림')),
          isSemantics(
            label: '푸시 알림',
            hasToggledState: true,
            isToggled: checked,
            hasCheckedState: false,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
          ),
        );
      }
      semantics.dispose();
    });

    testWidgets('키보드 — 포커스에서 Space · Enter 로 누른다', (tester) async {
      final calls = <bool>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSwitch(
            label: '종일',
            checked: false,
            onChanged: calls.add,
            focusNode: focus,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, [true, true]);
    });

    testWidgets('누르는 영역은 44 까지 — 줄(24)의 위아래 10px 밖도 받고 줄 높이는 그대로다', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          SizedBox(
            height: 100,
            child: Center(
              child: PSwitch(
                label: '종일',
                checked: false,
                onChanged: (_) => taps++,
                size: PSwitchSize.s16,
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(PSwitch));
      expect(rect.height, 24);
      await tester.tapAt(Offset(rect.center.dx, rect.top - 9));
      await tester.tapAt(Offset(rect.center.dx, rect.bottom + 9));
      expect(taps, 2);
      await tester.tapAt(Offset(rect.center.dx, rect.top - 11));
      expect(taps, 2);
    });

    testWidgets('엄지가 먼저 150ms 로 옮겨 가며 커지고, 색은 20ms 뒤에 50ms 로 바뀐다', (
      tester,
    ) async {
      final motion = _switch.json['motion'] as Map;
      final thumb = motion['끔 ↔ 켬 — 엄지'] as Map;
      final color = motion['끔 ↔ 켬 — 색'] as Map;
      final delay = specMs(
        _switch.resolve({}, 'enabled')['switchmark.transitionDelay'],
      );
      Widget pumpSwitch(bool checked) => _host(
        Brightness.light,
        PSwitch(label: '종일', checked: checked, onChanged: (_) {}),
      );
      final track = find.byKey(const ValueKey('switchmark-track'));
      final thumbBox = find.byKey(const ValueKey('switchmark-thumb'));
      Color trackColor() => _decoration(tester, track).color!;
      double thumbLeft() => tester.getRect(thumbBox).left;

      await tester.pumpWidget(pumpSwitch(false));
      final offColor = trackColor();
      final offLeft = thumbLeft();
      await tester.pumpWidget(pumpSwitch(true));
      // 늦춤 전 — 색은 그대로, 엄지는 벌써 움직인다
      await tester.pump(delay - const Duration(milliseconds: 5));
      expect(trackColor(), offColor);
      expect(thumbLeft(), greaterThan(offLeft));
      // 늦춤 + 전환 — 색이 다 바뀌었고, 엄지는 아직 가는 중
      await tester.pump(
        specMs(color['duration']) + const Duration(milliseconds: 5),
      );
      expect(trackColor(), PColors.light.bgNeutralInverted);
      final midThumb = tester.getRect(thumbBox);
      // 엄지 전환이 끝나면 14 만큼 가고 크기는 20(배율 1)
      await tester.pump(specMs(thumb['duration']));
      final end = tester.getRect(thumbBox);
      expect(midThumb.left, lessThan(end.left));
      expect(end.width, 20);
      expect(end.center.dx - (offLeft + 8), closeTo(14, 1e-6));
    });

    testWidgets('누르면 색은 그대로, 스위치만 세로 2px 거리 준다(32 는 기준 32) — 모션 줄이기면 축소만 빠진다', (
      tester,
    ) async {
      for (final (size, reduce) in [
        (PSwitchSize.s24, false),
        (PSwitchSize.s32, false),
        (PSwitchSize.s32, true),
      ]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PSwitch(
              key: UniqueKey(),
              label: '종일',
              checked: true,
              onChanged: (_) {},
              size: size,
            ),
            reduceMotion: reduce,
          ),
        );
        final track = find.byKey(const ValueKey('switchmark-track'));
        final before = _decoration(tester, track).color;
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(PSwitch)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final mark = tester.getRect(find.byType(PSwitchmark));
        final basis = math.max(mark.height, math.max(mark.width / 4, 24.0));
        expect(
          tester.getRect(track).height,
          closeTo(
            reduce ? mark.height : mark.height * (basis - 2) / basis,
            1e-6,
          ),
        );
        expect(_decoration(tester, track).color, before);
        await gesture.up();
      }
    });

    testWidgets('모션 줄이기여도 엄지 이동과 색 전환은 그대로다', (tester) async {
      Widget pumpSwitch(bool checked) => _host(
        Brightness.light,
        PSwitch(label: '종일', checked: checked, onChanged: (_) {}),
        reduceMotion: true,
      );
      final thumbBox = find.byKey(const ValueKey('switchmark-thumb'));
      await tester.pumpWidget(pumpSwitch(false));
      final start = tester.getRect(thumbBox).center.dx;
      await tester.pumpWidget(pumpSwitch(true));
      await tester.pump(const Duration(milliseconds: 75));
      final mid = tester.getRect(thumbBox).center.dx;
      await tester.pump(const Duration(milliseconds: 200));
      final end = tester.getRect(thumbBox).center.dx;
      expect(mid, greaterThan(start));
      expect(mid, lessThan(end));
    });
  });

  // ── 카탈로그 견본 ─────────────────────────────────────────
  // 카탈로그 등록부(ds_registry.dart)에 붙기 전에도 견본이 폰 폭(390)에서 라이트 · 다크로 그려지는지 본다 —
  // ds_catalog_test 와 같은 안쪽 폭(목록 여백 16 + 판 여백 20).
  for (final (name, demo) in [
    ('Checkbox', const CheckboxDemo()),
    ('Radio', const RadioDemo()),
    ('Switch', const SwitchDemo()),
  ]) {
    testWidgets('$name 견본이 폰 폭에서 라이트 · 다크로 그려진다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final theme in [GrooTheme.light(), GrooTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
                children: [demo],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: theme.brightness.name);
      }
    });
  }

  testWidgets('Checkbox 견본의 묶음 — 부모를 누르면 모두, 자식을 하나 풀면 부모는 일부 선택', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(child: CheckboxDemo()),
        ),
      ),
    );
    final parent = findWidgetWithText(PCheckbox, keepAll('전체')).last;
    PCheckbox item(String label) =>
        tester.widget<PCheckbox>(findWidgetWithText(PCheckbox, keepAll(label)));
    await tester.ensureVisible(parent);
    await tester.pump();
    expect(tester.widget<PCheckbox>(parent).checked, isNull);
    await tester.tap(parent);
    await tester.pump();
    expect(tester.widget<PCheckbox>(parent).checked, isTrue);
    expect(item('예산').checked, isTrue);
    await tester.tap(findWidgetWithText(PCheckbox, keepAll('메모')));
    await tester.pump();
    expect(tester.widget<PCheckbox>(parent).checked, isNull);
    // 넘어간 예외가 없다
    expect(tester.takeException(), isNull);
  });
}
