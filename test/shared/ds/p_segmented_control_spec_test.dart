// Segmented Control 이 스펙 값(test/fixtures/design_spec/segmented-control.json)대로인지 — 고름 × 상태(기본 · 누름 ·
// 비활성) × 라이트 · 다크의 트랙 · 칸 · 글 · 고른 알약 · 알림 점과 움직임, 칸 수 · 고른 알약 자리, 키보드 · 읽는 말.
// 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 상태(웹의 hovered · focused — 올림 · 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 —
// 칸 폭("똑같이 나눈다")은 칸 수를 바꿔 가며, 누름 축소("글 2px 거리")는 그려진 배율로, 누르는 영역("칸 전체")은 누른
// 자리로 잰다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/segmented_control_demo.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('segmented-control');

/// 앱의 상태 — 웹의 hovered(올림) · focused(키보드 포커스 링)는 앱에 없다.
final _appStates = _spec.states
    .where((s) => s != 'hovered' && s != 'focused')
    .toList();

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  double width = 312,
}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
  return reduceMotion
      ? MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app,
        )
      : app;
}

PSegmentedItem<String> _item(
  String value,
  String label, {
  bool enabled = true,
  bool notification = false,
}) => PSegmentedItem<String>(
  value: value,
  label: label,
  enabled: enabled,
  notification: notification,
);

/// 견본 — 오늘 · 이번 주 · 전체. 재는 칸은 가운데(이번 주)다.
List<PSegmentedItem<String>> _todo({
  bool middleEnabled = true,
  bool middleNotification = false,
}) => [
  _item('today', '오늘'),
  _item(
    'week',
    '이번 주',
    enabled: middleEnabled,
    notification: middleNotification,
  ),
  _item('all', '전체'),
];

Widget _control({
  String value = 'today',
  ValueChanged<String>? onChanged,
  List<PSegmentedItem<String>>? items,
  String label = '할 일 보기',
}) => PSegmentedControl<String>(
  value: value,
  onChanged: onChanged,
  items: items ?? _todo(),
  semanticLabel: label,
);

/// 값을 쥐는 쓰는 쪽 — 눌러서 고른다.
class _Live extends StatefulWidget {
  const _Live({
    required this.initial,
    required this.items,
    this.onChanged,
    this.disabled = false,
  });

  final String initial;
  final List<PSegmentedItem<String>> items;
  final ValueChanged<String>? onChanged;
  final bool disabled;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) => _control(
    value: value,
    items: widget.items,
    onChanged: widget.disabled
        ? null
        : (next) {
            widget.onChanged?.call(next);
            setState(() => value = next);
          },
  );
}

Finder get _control_ => find.byType(PSegmentedControl<String>);
Finder get _items => find.byKey(const ValueKey('segmented-item'));
Finder get _indicator => find.byKey(const ValueKey('segmented-indicator'));
Finder get _dot => find.byKey(const ValueKey('segmented-dot'));

/// 칸의 글 — 칸 안의 글 하나.
Finder _textIn(Finder item) =>
    find.descendant(of: item, matching: find.byType(Text));

BoxDecoration _decoration(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;

/// 그려지는 배율 — 그 상자에서 화면까지 겹친 변환의 확대(레이아웃 크기에는 안 잡히는 누름 축소를 잰다).
double _paintedScale(WidgetTester tester, Finder finder) =>
    tester.renderObject(finder).getTransformTo(null).entry(0, 0);

/// 칸 안의 칸 바탕 상자 — 칸마다 하나.
Finder _plate(int i) => _items.at(i);

/// 칸을 누른 채로 두고(누름), 전환(색 150ms · 누름 축소 150ms · 알약 200ms)이 끝나게 기다린다.
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

  /// 웹 cursor — pointer 는 손가락(click), not-allowed 는 금지(forbidden).
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

  /// 안쪽 1px 선 — 스펙에 두께가 있으면 그 색 · 두께로 그리고, 없으면 그리지 않는다(투명). 두께는 안쪽에 그려
  /// 크기가 변하지 않는다(웹 inset box-shadow).
  void border(String slot, BoxDecoration deco, {bool invisible = false}) {
    final border = deco.border as Border?;
    if (border == null) {
      fail('$slot 선이 없다 — 안쪽 선은 늘 그려 두고 색으로 나타난다');
      return;
    }
    if (border.top.width != 1) {
      fail('$slot.borderWidth: 스펙 1 · 실제 ${border.top.width}');
    }
    if (border.top.strokeAlign != BorderSide.strokeAlignInside) {
      fail('$slot 선이 안쪽이 아니다');
    }
    final wantWidth = want['$slot.borderWidth'] as num? ?? 0;
    if (wantWidth > 0) {
      color('$slot.borderColor', border.top.color);
    } else if (border.top.color.a != 0) {
      fail('$slot: 스펙에 선이 없는데 ${colorHex(border.top.color)} 로 그렸다');
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

  /// 스펙이 푼 값은 모두 어딘가에서 잰다 — 여기서 재거나([measured]), 동작 테스트가 보거나, 앱에 없는 값이다
  /// ([elsewhere]). 스펙에 새 값이 생기면 여기서 걸린다(재지 않고 지나가지 않게).
  void coverage(Set<String> measured, Set<String> elsewhere) {
    for (final key in want.keys) {
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}

/// 앱에 없는 값 — 포커스 링은 웹 상태(키보드 포커스 링)다.
const _webOnly = {'focusRing.width', 'focusRing.offset', 'focusRing.color'};

/// 동작 테스트가 보는 값 — 트랙 폭 · 칸 수("칸 수로 똑같이 나눈다") · 누르는 영역("칸 전체") · 글 정렬 · 전환이
/// 무엇을 바꾸는지의 글(색 셋이 한 전환으로, 알약은 옮김으로).
const _behavior = {
  'root.width',
  'root.columns',
  'item.touchTarget',
  'item.transitionProperty',
  'indicator.transitionProperty',
};

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['selected'])) {
      for (final state in _appStates) {
        final title = '${mode.name} ${combo['selected']} $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          final selected = combo['selected'] == 'selected';
          final disabled = state == 'disabled';
          // 점은 안 고른 칸에, 막히지 않았을 때 — 막힌 칸의 점은 보여 주지 않는다(견본과 같다)
          final dotted = !selected && state == 'enabled';
          await tester.pumpWidget(
            _host(
              mode,
              _control(
                value: selected ? 'week' : 'today',
                onChanged: (_) {},
                items: _todo(
                  middleEnabled: !disabled,
                  middleNotification: dotted,
                ),
              ),
            ),
          );
          final gesture = await _settle(tester, state, _plate(1));
          final k = _Check(mode, _spec.resolve(combo, state), title);
          final measured = <String>{};
          void m(String key) => measured.add(key);

          final track = tester.getRect(_control_);
          final first = tester.getRect(_plate(0));
          final middle = tester.getRect(_plate(1));
          final last = tester.getRect(_plate(2));

          // 트랙 — 안쪽 4 · 알약 모서리 · 바탕
          final trackDeco = _decoration(
            tester,
            find
                .descendant(of: _control_, matching: find.byType(DecoratedBox))
                .first,
          );
          k.px('root.padding', first.left - track.left);
          k.px('root.padding', first.top - track.top);
          k.px('root.padding', track.right - last.right);
          k.px('root.padding', track.bottom - middle.bottom);
          k.radius('root.radius', trackDeco);
          k.color('root.background', trackDeco.color!);
          for (final key in [
            'root.padding',
            'root.radius',
            'root.background',
          ]) {
            m(key);
          }

          // 칸 — 높이 · 안쪽 여백 · 모서리 · 커서 · 전환
          k.px('item.minHeight', middle.height);
          final pad =
              tester
                      .widget<Padding>(
                        find
                            .descendant(
                              of: _plate(1),
                              matching: find.byType(Padding),
                            )
                            .first,
                      )
                      .padding
                  as EdgeInsets;
          k.px('item.paddingX', pad.left);
          k.px('item.paddingX', pad.right);
          k.px('item.paddingY', pad.top);
          k.px('item.paddingY', pad.bottom);
          final plateDeco = _decoration(tester, _plate(1));
          k.radius('item.radius', plateDeco);
          k.cursor(
            'item.cursor',
            tester
                .widget<MouseRegion>(
                  find
                      .ancestor(
                        of: _plate(1),
                        matching: find.byType(MouseRegion),
                      )
                      .first,
                )
                .cursor,
          );
          // 칸 바탕 · 안쪽 선 — 누름 · 고른 채 막힘에서만 칠해 알약을 덮는다
          final wantsBackground = k.want['item.background'] != null;
          if (wantsBackground) {
            k.color('item.background', plateDeco.color!);
          } else if (plateDeco.color!.a != 0) {
            k.fail(
              'item.background: 스펙에 없는데 ${colorHex(plateDeco.color!)} 로 칠했다',
            );
          }
          k.border('item', plateDeco);
          final colors = tester.widget<TweenAnimationBuilder<SelectionColors>>(
            find.descendant(
              of: find.ancestor(
                of: _plate(1),
                matching: find.byType(GestureDetector),
              ),
              matching: find.byType(TweenAnimationBuilder<SelectionColors>),
            ),
          );
          k.motion(
            'item.transitionDuration',
            'item.transitionEasing',
            colors.duration,
            colors.curve,
          );
          for (final key in [
            'item.minHeight',
            'item.paddingX',
            'item.paddingY',
            'item.radius',
            'item.cursor',
            'item.background',
            'item.borderColor',
            'item.borderWidth',
            'item.transitionDuration',
            'item.transitionEasing',
          ]) {
            m(key);
          }

          // 글 — t5 16 / 22 · 700 · 가운데 · 색은 고름 · 상태가 정한다
          final label = tester.widget<Text>(_textIn(_plate(1)));
          k.typo('label.typography', label.style!);
          k.weight('label.fontWeight', label.style!);
          k.color('label.foreground', label.style!.color!);
          if (k.want['label.textAlign'] == 'center' &&
              label.textAlign != TextAlign.center) {
            k.fail('label.textAlign: 스펙 center · 실제 ${label.textAlign}');
          }
          // 칸 안 가운데에 선다 — 글 상자가 칸 가운데
          final labelRect = tester.getRect(_textIn(_plate(1)));
          final scale = tester.widget<AnimatedScale>(
            find.descendant(
              of: _plate(1),
              matching: find.byType(AnimatedScale),
            ),
          );
          k.pressScale('label.scale', scale.scale, middle.size);
          k.motion(
            'label.scaleDuration',
            'label.scaleEasing',
            scale.duration,
            scale.curve,
          );
          if ((labelRect.center.dx - middle.center.dx).abs() > 0.5) {
            k.fail('label.textAlign: 글이 칸 가운데가 아니다 $labelRect · $middle');
          }
          for (final key in [
            'label.typography',
            'label.fontWeight',
            'label.foreground',
            'label.textAlign',
            'label.scale',
            'label.scaleDuration',
            'label.scaleEasing',
          ]) {
            m(key);
          }

          // 고른 알약 — 고른 칸 번호만큼 옮긴 (트랙 − 8) ÷ 칸 수 폭, 안쪽 4
          final index = selected ? 1 : 0;
          final pill = tester.getRect(_indicator);
          final innerWidth = track.width - 2 * 4;
          k.px('indicator.inset', pill.top - track.top);
          k.px('indicator.inset', track.bottom - pill.bottom);
          // 고른 칸 번호만큼 옮기고 남는 왼쪽 들임
          k.px(
            'indicator.inset',
            pill.left - track.left - index * innerWidth / 3,
          );
          if ((pill.width - innerWidth / 3).abs() > 0.5) {
            k.fail(
              'indicator 폭: (트랙 − 8) ÷ 3 = ${innerWidth / 3} · 실제 ${pill.width}',
            );
          }
          final pillDeco = _decoration(tester, _indicator);
          k.color('indicator.background', pillDeco.color!);
          k.radius('indicator.radius', pillDeco);
          final pillBorder = pillDeco.border! as Border;
          k.px('indicator.borderWidth', pillBorder.top.width);
          k.color('indicator.borderColor', pillBorder.top.color);
          if (pillBorder.top.strokeAlign != BorderSide.strokeAlignInside) {
            k.fail('indicator 선이 안쪽이 아니다');
          }
          final slide = tester.widget<TweenAnimationBuilder<double>>(
            find.ancestor(
              of: _indicator,
              matching: find.byType(TweenAnimationBuilder<double>),
            ),
          );
          k.motion(
            'indicator.transitionDuration',
            'indicator.transitionEasing',
            slide.duration,
            slide.curve,
          );
          for (final key in [
            'indicator.inset',
            'indicator.background',
            'indicator.radius',
            'indicator.borderWidth',
            'indicator.borderColor',
            'indicator.transitionDuration',
            'indicator.transitionEasing',
          ]) {
            m(key);
          }

          // 알림 점 — 6 · 원 · 브랜드 글자색 · 글 끝에서 2 · 글 위쪽. 고른 칸에는 없다
          if (selected) {
            expect(_dot, findsNothing, reason: title);
          } else if (dotted) {
            final dot = tester.getRect(_dot);
            k.px('notification.size', dot.width);
            k.px('notification.size', dot.height);
            k.px('notification.gap', dot.left - labelRect.right);
            if ((dot.top - labelRect.top).abs() > 0.5) {
              k.fail('notification: 글 위쪽이 아니다 $dot · $labelRect');
            }
            final dotDeco = _decoration(tester, _dot);
            k.radius('notification.radius', dotDeco);
            k.color('notification.background', dotDeco.color!);
          }
          for (final key in [
            'notification.size',
            'notification.radius',
            'notification.background',
            'notification.gap',
          ]) {
            m(key);
          }

          k.coverage(measured, {..._webOnly, ..._behavior});
          await gesture?.up();
          await tester.pump(const Duration(milliseconds: 400));
          if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
        });
      }
    }
  }

  group('움직임', () {
    testWidgets('고른 알약은 200ms 로 고른 칸에 미끄러진다 — 모션 줄이기에도 그대로다', (tester) async {
      final motion = (_spec.json['motion'] as Map)['고른 알약 — 미끄러짐'] as Map;
      final duration = specMs(motion['duration']);
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            _Live(initial: 'today', items: _todo()),
            reduceMotion: reduce,
          ),
        );
        final track = tester.getRect(_control_);
        final unit = (track.width - 8) / 3;
        expect(tester.getRect(_indicator).left, track.left + 4);
        await tester.tap(findText(keepAll('전체')));
        await tester.pump();
        await tester.pump(duration ~/ 2);
        // 반쯤 — 두 칸 가는 길의 중간 어딘가에 있다
        final mid = tester.getRect(_indicator).left;
        expect(mid, greaterThan(track.left + 4), reason: 'reduce=$reduce');
        expect(
          mid,
          lessThan(track.left + 4 + 2 * unit),
          reason: 'reduce=$reduce',
        );
        await tester.pump(duration);
        expect(
          tester.getRect(_indicator).left,
          closeTo(track.left + 4 + 2 * unit, 0.01),
        );
      }
    });

    testWidgets('쓰는 쪽이 값을 바꿔도 알약이 따라간다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _control(value: 'today', onChanged: (_) {})),
      );
      final track = tester.getRect(_control_);
      expect(tester.getRect(_indicator).left, track.left + 4);
      await tester.pumpWidget(
        _host(Brightness.light, _control(value: 'all', onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_indicator).left,
        closeTo(track.left + 4 + 2 * (track.width - 8) / 3, 0.01),
      );
    });

    testWidgets('누르면 칸 안의 글만 2px 거리 줄고 칸 바탕 · 알약은 그대로다 — 모션 줄이기면 줄지 않는다', (
      tester,
    ) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            _control(onChanged: (_) {}),
            reduceMotion: reduce,
          ),
        );
        final plate = tester.getRect(_plate(1));
        final pill = tester.getRect(_indicator);
        final unpressed = _paintedScale(tester, _textIn(_plate(1)));
        final g = await tester.startGesture(plate.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // 칸 · 알약 자리는 그대로
        expect(tester.getRect(_plate(1)), plate);
        expect(tester.getRect(_indicator), pill);
        final scale = _paintedScale(tester, _textIn(_plate(1))) / unpressed;
        // 기준 max(34, 폭 ÷ 4, 24) = 34 → 34 에서 2px 줄어 32 ÷ 34, 모션 줄이기면 줄지 않는다
        expect(
          scale,
          closeTo(reduce ? 1 : 32 / 34, 1e-3),
          reason: 'reduce=$reduce',
        );
        await g.up();
        await tester.pump(const Duration(milliseconds: 400));
      }
    });
  });

  group('칸 폭 · 고른 알약 자리', () {
    testWidgets(
      '칸 글은 -static 16 — 글자 200% 에서도 커지지 않아 폰 4칸이 한 글자씩 쪼개지지 않는다(03-B 결정 4 A)',
      (tester) async {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: _host(
                Brightness.light,
                _control(
                  value: 'v0',
                  onChanged: (_) {},
                  items: [
                    for (final l in ['오늘', '내일', '이번', '올해'])
                      _item('v${l.hashCode}', l),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final label in ['오늘', '내일', '이번', '올해']) {
            final text = tester.widget<Text>(
              find.byWidgetPredicate(
                (w) =>
                    w is Text &&
                    (w.data ?? '').replaceAll('\u2060', '') == label,
              ),
            );
            expect(
              text.textScaler,
              TextScaler.noScaling,
              reason: '$label × $scale',
            );
            expect(text.style!.fontSize, 16);
            // 한 줄로 그려진다 — 높이가 글자 한 줄
            expect(
              tester
                  .getSize(
                    find.byWidgetPredicate(
                      (w) =>
                          w is Text &&
                          (w.data ?? '').replaceAll('\u2060', '') == label,
                    ),
                  )
                  .height,
              lessThan(28),
              reason: '$label × $scale',
            );
          }
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('칸이 트랙 폭을 똑같이 나눈다 — 칸 수 2 ~ 4 · 최소 폭이 없다(폰 콘텐츠 폭 312 에 4개)', (
      tester,
    ) async {
      final labels = ['지출', '수입', '이체', '환급'];
      for (final count in [2, 3, 4]) {
        for (final width in [312.0, 280.0, 600.0]) {
          final items = [
            for (var i = 0; i < count; i++) _item('v$i', labels[i]),
          ];
          await tester.pumpWidget(
            _host(
              Brightness.light,
              _control(value: 'v${count - 1}', onChanged: (_) {}, items: items),
              width: width,
            ),
          );
          // 알약이 값이 바뀐 칸으로 미끄러진 뒤
          await tester.pumpAndSettle();
          final unit = (width - 8) / count;
          final track = tester.getRect(_control_);
          expect(track.width, width, reason: '$count × $width');
          for (var i = 0; i < count; i++) {
            final r = tester.getRect(_plate(i));
            expect(r.width, closeTo(unit, 0.01), reason: '$count × $width #$i');
            expect(r.left, closeTo(track.left + 4 + i * unit, 0.01));
          }
          // 고른 칸(끝)에 알약이 놓인다
          expect(
            tester.getRect(_indicator).left,
            closeTo(track.left + 4 + (count - 1) * unit, 0.01),
          );
        }
      }
      // 폰에서 4개면 칸 폭 76
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _control(
            value: 'v0',
            onChanged: (_) {},
            items: [for (var i = 0; i < 4; i++) _item('v$i', labels[i])],
          ),
        ),
      );
      expect(tester.getSize(_plate(0)).width, 76);
    });

    testWidgets('긴 글은 낱말 단위로 줄이 바뀌고 모든 칸이 가장 높은 칸에 맞춘다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _control(
            value: 'most',
            onChanged: (_) {},
            label: '프리셋 정렬',
            items: [
              _item('most', '많이 쓴 순'),
              _item('recent', '최근에 사용한 프리셋'),
              _item('name', '이름순'),
            ],
          ),
        ),
      );
      final heights = [
        for (var i = 0; i < 3; i++) tester.getSize(_plate(i)).height,
      ];
      // 가장 긴 글이 여러 줄이라 34 보다 높고, 세 칸이 같은 높이다
      expect(heights[1], greaterThan(34));
      expect(heights, everyElement(heights[1]));
      // 고른 알약도 칸 높이 그대로(트랙 − 8)
      expect(tester.getSize(_indicator).height, heights[1]);
      expect(tester.getSize(_control_).height, heights[1] + 8);
      // 글은 칸 가운데 — 짧은 글도 칸 높이의 가운데에 선다
      final short = tester.getRect(_textIn(_plate(2)));
      expect(
        short.center.dy,
        closeTo(tester.getRect(_plate(2)).center.dy, 0.5),
      );
      // 줄이 바뀌는 자리는 띄어쓰기뿐 — 낱말 가운데에서 끊지 않는다(DESIGN.md v114)
      final text = tester.widget<Text>(_textIn(_plate(1)));
      expect(text.data, keepAll('최근에 사용한 프리셋'));
    });

    testWidgets('값이 칸에 없으면 알약을 그리지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _control(value: 'nope', onChanged: (_) {})),
      );
      expect(_indicator, findsNothing);
    });

    test('칸은 2 ~ 4개 — 그보다 적거나 많으면 개발 중에 걸린다', () {
      for (final count in [0, 1, 5]) {
        expect(
          () => PSegmentedControl<String>(
            value: 'v0',
            onChanged: (_) {},
            semanticLabel: '보기',
            items: [for (var i = 0; i < count; i++) _item('v$i', '$i')],
          ),
          throwsAssertionError,
          reason: '$count개',
        );
      }
    });
  });

  group('누르기 · 고르기', () {
    testWidgets('누르면 그 칸을 고르고 알린다 — 고른 칸을 다시 눌러도 알리지 않는다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live(initial: 'today', items: _todo(), onChanged: calls.add),
        ),
      );
      await tester.tap(findText(keepAll('전체')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['all']);
      await tester.tap(findText(keepAll('전체')));
      await tester.pump();
      expect(calls, ['all']);
      // 글 · 칸 가장자리 어디를 눌러도 고른다
      final plate = tester.getRect(_plate(0));
      await tester.tapAt(plate.topLeft + const Offset(3, 3));
      expect(calls, ['all', 'today']);
    });

    testWidgets('막힌 칸은 누를 수 없다 — 트랙에 onChanged 가 없으면 칸이 모두 막힌다', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live(
            initial: 'today',
            items: _todo(middleEnabled: false),
            onChanged: calls.add,
          ),
        ),
      );
      await tester.tap(findText(keepAll('이번 주')));
      expect(calls, isEmpty);
      await tester.tap(findText(keepAll('전체')));
      expect(calls, ['all']);

      calls.clear();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live(
            initial: 'today',
            items: _todo(),
            onChanged: calls.add,
            disabled: true,
          ),
        ),
      );
      for (final label in ['오늘', '이번 주', '전체']) {
        await tester.tap(findText(keepAll(label)));
      }
      expect(calls, isEmpty);
      // 값은 그대로 — 알약도 제 자리
      expect(
        tester.getRect(_indicator).left,
        tester.getRect(_control_).left + 4,
      );
    });

    testWidgets('누르는 영역은 칸 전체(34 × 칸 폭) — 트랙의 안쪽 4 는 누르는 자리가 아니다', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live(initial: 'today', items: _todo(), onChanged: calls.add),
        ),
      );
      final track = tester.getRect(_control_);
      final plate = tester.getRect(_plate(2));
      expect(plate.height, 34);
      // 칸 위 · 아래의 안쪽 여백 — 칸이 아니다(웹과 같다)
      await tester.tapAt(Offset(plate.center.dx, track.top + 2));
      await tester.tapAt(Offset(plate.center.dx, track.bottom - 2));
      expect(calls, isEmpty);
      // 칸의 위 · 아래 끝은 칸이다
      await tester.tapAt(Offset(plate.center.dx, plate.top + 0.5));
      expect(calls, ['all']);
    });

    testWidgets('알림 점은 안 고른 칸에만 — 고르면 사라지고, 칸 폭은 바뀌지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live(
            initial: 'today',
            items: [
              _item('today', '오늘'),
              _item('done', '완료', notification: true),
            ],
          ),
        ),
      );
      expect(_dot, findsOneWidget);
      final width = tester.getSize(_plate(1)).width;
      // 점이 있는 칸 이름 뒤에 읽는 글을 덧붙인다 — 점만으로 알리지 않는다
      expect(find.bySemanticsLabel('완료 새 소식'), findsOneWidget);
      await tester.tap(findText(keepAll('완료')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_dot, findsNothing);
      expect(find.bySemanticsLabel('완료 새 소식'), findsNothing);
      expect(find.bySemanticsLabel('완료'), findsOneWidget);
      expect(tester.getSize(_plate(1)).width, width);
      semantics.dispose();
    });
  });

  group('키보드', () {
    testWidgets('Tab 은 고른 칸 하나에만 선다 — 다른 칸은 건너뛴다', (tester) async {
      final after = FocusNode();
      addTearDown(after.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: [
              _Live(initial: 'week', items: _todo()),
              Focus(focusNode: after, child: const SizedBox(height: 10)),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      // 포커스가 고른 칸(이번 주) 하나에 선다
      final plate = tester.getRect(_plate(1));
      final focusedRect = FocusManager.instance.primaryFocus!.rect;
      expect(focusedRect.center.dx, closeTo(plate.center.dx, 1));
      expect(plate.overlaps(focusedRect), isTrue);
      // 한 번 더 누르면 묶음을 나간다 — 다른 칸에 서지 않는다
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);
    });

    testWidgets('화살표로 옮기면 바로 고른다 — 막힌 칸은 건너뛰고 끝에서 처음으로 돈다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live(
            initial: 'today',
            items: _todo(middleEnabled: false),
            onChanged: calls.add,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      // 막힌 "이번 주" 를 건너뛴다
      expect(calls, ['all']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 400));
      // 끝에서 처음으로 돈다
      expect(calls, ['all', 'today']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['all', 'today', 'all']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['all', 'today', 'all', 'today']);
      // 알약이 따라온다
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_indicator).left,
        tester.getRect(_control_).left + 4,
      );
    });

    testWidgets('막힌 트랙에는 초점이 가지 않고 키로 움직이지 않는다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Live(
            initial: 'today',
            items: _todo(),
            onChanged: calls.add,
            disabled: true,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, isEmpty);
    });
  });

  group('읽는 말', () {
    testWidgets('트랙은 이름 있는 라디오 묶음, 칸은 라디오 — 고른 칸 · 묶음 안 · 막힘을 읽는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _control(
            value: 'today',
            onChanged: (_) {},
            items: _todo(middleEnabled: false),
          ),
        ),
      );
      final group = tester.getSemantics(find.bySemanticsLabel('할 일 보기'));
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      expect(
        tester.getSemantics(find.bySemanticsLabel('오늘')),
        isSemantics(
          label: '오늘',
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
        tester.getSemantics(find.bySemanticsLabel('전체')),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('이번 주')),
        isSemantics(isEnabled: false, hasTapAction: false),
      );
      semantics.dispose();
    });

    testWidgets(
      'iOS 는 선택을 selected 로 읽고, 고르지 않은 칸에 "선택되지 않음" 을 덧붙인다(RawRadio 와 같다)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(Brightness.light, _control(value: 'today', onChanged: (_) {})),
        );
        final context = tester.element(_control_);
        expect(
          tester.getSemantics(find.bySemanticsLabel('오늘')),
          isSemantics(isSelected: true, hasSelectedState: true),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('전체')),
          isSemantics(
            isSelected: false,
            hint: WidgetsLocalizations.of(context).radioButtonUnselectedLabel,
          ),
        );
        semantics.dispose();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  testWidgets('견본이 모든 고름 · 상태 · 칸 수를 그린다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
            child: SegmentedControlDemo(),
          ),
        ),
      ),
    );
    final controls = tester
        .widgetList<PSegmentedControl<String>>(_control_)
        .toList();
    // 칸 수 2 · 3 · 4 가 모두 있고, 막힌 트랙 · 막힌 칸 · 알림 점도 있다
    expect(controls.map((c) => c.items.length).toSet(), {2, 3, 4});
    expect(controls.any((c) => c.onChanged == null), isTrue);
    expect(controls.any((c) => c.items.any((i) => !i.enabled)), isTrue);
    expect(controls.any((c) => c.items.any((i) => i.notification)), isTrue);
    // 고름 둘(고른 칸이 가운데인 것 · 아닌 것)
    expect(controls.any((c) => c.value == 'week'), isTrue);
    expect(controls.any((c) => c.value == 'today'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
