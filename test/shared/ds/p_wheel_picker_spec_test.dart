// Wheel Picker 가 스펙 값(test/fixtures/design_spec/wheel-picker.json)대로인지 — 크기 × 보이는 칸 × 상태(기본 · 막힘) ×
// 라이트 · 다크의 휠 높이 · 항목 · 글자 · 선택 띠 · 안개 · 띠 안 · 밖 글자색, 그리고 움직임(밀기 · 누르기 · 키 · 반복 ·
// 값이 멈춘 뒤 한 번 정해짐 · 지나는 항목마다 알림 · 쓰는 쪽이 바꾼 값 따라가기)과 읽는 말(조절 가능한 값). 웹은 같은 JSON 을
// 크로미움에서 잰다.
//
// 앱에 없는 것 — 웹의 키보드 포커스 링(focused)과 마우스 끌기 · 휠 입력의 움직임(3px 넘게 끌기, 놓을 때 속도로 ±3칸,
// 220 ~ 360ms, 휠 120ms 뒤 160ms — 손가락 입력은 플랫폼 스크롤이 맡는다). 문장으로 된 값은 그린 결과나 동작으로 본다 —
// 휠 높이("항목 높이 × 보이는 수") · 칼럼 폭("항목 글 폭 + 좌우 16") · 안개 높이("min(휠 높이 × 40%, 항목 3칸)")는 계산한
// 숫자로, 띠에 걸친 글자색은 띠 안 · 밖을 가른 그리기로 잰다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/wheel_picker_demo.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('wheel-picker');

final List<PWheelPickerOption<int>> _years = [
  for (var i = 0; i < 11; i++)
    PWheelPickerOption(value: 2021 + i, label: '${2021 + i}년'),
];
final List<PWheelPickerOption<int>> _months = [
  for (var i = 1; i <= 12; i++) PWheelPickerOption(value: i, label: '$i월'),
];

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  TextScaler? textScaler,
}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 280, child: child),
      ),
    ),
  );
  if (!reduceMotion && textScaler == null) return app;
  return MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduceMotion,
      textScaler: textScaler ?? TextScaler.noScaling,
    ),
    child: app,
  );
}

/// 연 | 월 휠 — 연 120 오른쪽 · 월 96 왼쪽 반복(달만 고르기와 같은 모양).
Widget _picker({
  PWheelPickerSize size = PWheelPickerSize.medium,
  int visibleItems = 5,
  bool disabled = false,
  int? yearValue,
  int yearInitial = 2026,
  int monthInitial = 10,
  PWheelPickerChanged<int>? onYear,
  PWheelPickerChanged<int>? onMonth,
  void Function(int, int)? onYearIndex,
  PWheelPickerValueChange yearValueChange = PWheelPickerValueChange.auto,
}) => PWheelPicker(
  semanticLabel: '월 선택',
  size: size,
  visibleItems: visibleItems,
  disabled: disabled,
  children: [
    PWheelPickerColumn<int>(
      semanticLabel: '연도',
      options: _years,
      value: yearValue,
      initialValue: yearInitial,
      align: PWheelPickerAlign.right,
      width: 120,
      onChanged: onYear,
      onIndexChange: onYearIndex,
      valueChange: yearValueChange,
    ),
    PWheelPickerColumn<int>(
      semanticLabel: '월',
      options: _months,
      initialValue: monthInitial,
      align: PWheelPickerAlign.left,
      width: 96,
      loop: true,
      onChanged: onMonth,
    ),
  ],
);

Finder _col(String name) => find.byWidgetPredicate(
  (w) => w is PWheelPickerColumn && w.semanticLabel == name,
  description: '칼럼 $name',
);
Finder _layerA(String name) =>
    find.descendant(of: _col(name), matching: find.byType(ListWheelScrollView));
Finder _layerB(String name) => find.descendant(
  of: _col(name),
  matching: find.byKey(const ValueKey('wheel-selected-layer')),
);
Finder _textA(String name, String label) =>
    find.descendant(of: _layerA(name), matching: findText(label));
Finder _wheelRoot() => find.byKey(const ValueKey('wheel-root'));

/// 띠(가운데 줄)에 놓인 항목의 글 — 휠 가운데 높이에 가운데가 오는 글.
String? _centerLabel(WidgetTester tester, String name) {
  final y = tester.getRect(_wheelRoot()).center.dy;
  for (final e
      in find
          .descendant(of: _layerA(name), matching: find.byType(Text))
          .evaluate()) {
    final box = e.renderObject! as RenderBox;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    if ((center.dy - y).abs() < 1) return (e.widget as Text).data;
  }
  return null;
}

TextStyle _styleOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder.first).style!;

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

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['size', 'visibleItems'])) {
      // 앱의 상태 — 웹의 focused(키보드 포커스 링)는 앱에 없다
      for (final state in ['enabled', 'disabled']) {
        final title =
            '${mode.name} ${combo['size']} · ${combo['visibleItems']}칸 $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          final size = PWheelPickerSize.values.byName(combo['size']!);
          final count = int.parse(combo['visibleItems']!);
          await tester.pumpWidget(
            _host(
              mode,
              _picker(
                size: size,
                visibleItems: count,
                disabled: state == 'disabled',
              ),
            ),
          );
          await tester.pumpAndSettle();
          final k = _Check(mode, _spec.resolve(combo, state), title);
          final measured = <String>{};
          void m(Iterable<String> keys) => measured.addAll(keys);
          final item = (k.want['item.height'] as num).toDouble();

          // 휠 — 높이 = 항목 높이 × 보이는 수 · 바탕
          final root = tester.getRect(_wheelRoot());
          if ((root.height - item * count).abs() > 0.01) {
            k.fail(
              'root.height: 항목 높이 × 보이는 수 ${item * count} · 실제 ${root.height}',
            );
          }
          final rootColor = tester.widget<ColoredBox>(_wheelRoot()).color;
          k.color('root.background', rootColor);
          m(['root.height', 'root.background']);

          // 항목 — 높이 · 좌우 16 · 글자 · 굵기 · 숫자 폭 같게 · 띠 밖 글자색(글자 크기 설정을 따르지 않는다)
          final other = _textA('연도', '2025년');
          final otherBox = tester.getRect(
            find.ancestor(of: other, matching: find.byType(SizedBox)).first,
          );
          k.px('item.height', otherBox.height);
          final pad =
              tester
                      .widget<Padding>(
                        find
                            .ancestor(of: other, matching: find.byType(Padding))
                            .first,
                      )
                      .padding
                  as EdgeInsets;
          k.px('item.paddingX', pad.left);
          k.px('item.paddingX', pad.right);
          final style = _styleOf(tester, other);
          k.typo('item.typography', style);
          k.weight('item.fontWeight', style);
          if (k.want['item.numerals'] == 'tabular-nums' &&
              !(style.fontFeatures ?? []).contains(
                const FontFeature.tabularFigures(),
              )) {
            k.fail('item.numerals: 숫자 폭이 같지 않다');
          }
          if (tester.widget<Text>(other.first).textScaler !=
              TextScaler.noScaling) {
            k.fail('item.typography: 글자 크기 설정을 따른다(px 로 고정해야 한다)');
          }
          k.color('item.foreground', style.color!);
          m([
            'item.height',
            'item.paddingX',
            'item.typography',
            'item.fontWeight',
            'item.numerals',
            'item.foreground',
          ]);

          // 띠에 걸친 글자 — 띠 높이만 잘라 그린 고른 색(막히면 흐리게)
          final selected = find.descendant(
            of: _layerB('연도'),
            matching: findText('2026년'),
          );
          k.color('item.selectedForeground', _styleOf(tester, selected).color!);
          m(['item.selectedForeground']);

          // 선택 띠 — 휠 좌우 끝에서 16 · 항목 높이 · 모서리 8 · 가운데 줄
          final band = tester.getRect(
            find.byKey(const ValueKey('wheel-indicator')),
          );
          k.px('indicator.insetX', band.left - root.left);
          k.px('indicator.insetX', root.right - band.right);
          k.px('indicator.height', band.height);
          if ((band.center.dy - root.center.dy).abs() > 0.01) {
            k.fail('indicator: 가운데 줄이 아니다 $band · $root');
          }
          final bandDeco =
              tester
                      .widget<DecoratedBox>(
                        find.byKey(const ValueKey('wheel-indicator')),
                      )
                      .decoration
                  as BoxDecoration;
          k.px(
            'indicator.radius',
            (bandDeco.borderRadius! as BorderRadius).topLeft.x,
          );
          k.color('indicator.background', bandDeco.color!);
          m([
            'indicator.insetX',
            'indicator.height',
            'indicator.radius',
            'indicator.background',
          ]);

          // 안개 — 위아래 min(휠 높이 × 40%, 항목 3칸), 휠 바탕색으로 흐려진다(위 판은 뒤집는다) · 띠와 겹치지 않는다
          final fogTop = tester.getRect(
            find.byKey(const ValueKey('wheel-fog-top')),
          );
          final fogBottom = tester.getRect(
            find.byKey(const ValueKey('wheel-fog-bottom')),
          );
          final fogH = math.min(root.height * 0.4, item * 3);
          for (final fog in [fogTop, fogBottom]) {
            if ((fog.height - fogH).abs() > 0.01) {
              k.fail(
                'fog.height: min(휠 높이 × 40%, 항목 3칸) $fogH · 실제 ${fog.height}',
              );
            }
          }
          if (fogTop.top != root.top || fogBottom.bottom != root.bottom) {
            k.fail('fog: 휠 위 · 아래 끝에 붙지 않았다');
          }
          if (fogTop.bottom > band.top + 0.01 ||
              fogBottom.top < band.bottom - 0.01) {
            k.fail('fog: 띠와 겹친다 (5 · 7칸에서 안개 끝 ≤ 띠)');
          }
          final fade = mode == Brightness.dark
              ? PGradients.dark.fadeMask
              : PGradients.light.fadeMask;
          for (final top in [true, false]) {
            final g =
                (tester
                                .widget<DecoratedBox>(
                                  find.byKey(
                                    ValueKey(
                                      top
                                          ? 'wheel-fog-top'
                                          : 'wheel-fog-bottom',
                                    ),
                                  ),
                                )
                                .decoration
                            as BoxDecoration)
                        .gradient!
                    as LinearGradient;
            // 아래 판은 위 → 아래로 불투명해지고, 위 판은 뒤집어 아래로 투명해진다
            final begin = top ? Alignment.bottomCenter : Alignment.topCenter;
            if (g.begin != begin) k.fail('fog 방향: ${top ? '위' : '아래'} 판');
            if (g.colors.length != fade.colors.length) k.fail('fog 단계 수');
            for (var i = 0; i < g.colors.length; i++) {
              // 색은 휠 바탕색, 불투명도는 gradient-fade-mask 그대로
              if (!sameColor(
                    rootColor.withValues(alpha: fade.colors[i].a),
                    g.colors[i],
                  ) ||
                  g.stops![i] != fade.stops![i]) {
                k.fail('fog.height: 마스크 ${i + 1}번째 단계가 토큰과 다르다');
                break;
              }
            }
          }
          m(['fog.height']);

          k.coverage(measured, {..._webOnly, 'column.width'});
          if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
        });
      }
    }
  }

  group('칼럼 폭', () {
    testWidgets('항목 글 폭 + 좌우 16 — 폭을 정하면 그 폭, 칼럼 묶음은 휠 가운데', (tester) async {
      final wide = PWheelPickerOption(value: 1, label: '가나다라마');
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PWheelPicker(
            semanticLabel: '시각 선택',
            children: [
              PWheelPickerColumn<int>(
                semanticLabel: '시',
                options: [
                  wide,
                  const PWheelPickerOption(value: 2, label: '나'),
                ],
              ),
              PWheelPickerColumn<int>(
                semanticLabel: '분',
                width: 96,
                options: [const PWheelPickerOption(value: 2, label: '나')],
              ),
            ],
          ),
        ),
      );
      // 가장 넓은 글(다섯 글자)의 폭 + 32 — 그 글을 같은 글자 모양으로 따로 재서 맞춘다
      final painter = TextPainter(
        text: TextSpan(
          text: wide.label,
          style: PTypography.t10.copyWith(
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      final hour = tester.getSize(_col('시'));
      expect(hour.width, closeTo(painter.width + 32, 0.01));
      expect(tester.getSize(_col('분')).width, 96);
      // 두 칼럼이 휠(280) 가운데에 모인다
      final root = tester.getRect(_wheelRoot());
      final left = tester.getRect(_col('시')).left;
      final right = tester.getRect(_col('분')).right;
      expect(left - root.left, closeTo(root.right - right, 0.01));
      painter.dispose();
    });

    testWidgets('글자 크기 설정을 키워도 휠 칸 · 글자는 그대로다 — 휠 칸이 넘치지 않는다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, _picker()));
      await tester.pumpAndSettle();
      final before = tester.getSize(_textA('연도', '2025년').first);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _picker(),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(_textA('연도', '2025년').first), before);
      expect(tester.getSize(_wheelRoot()).height, 220);
    });
  });

  group('띠 안 · 밖 글자', () {
    testWidgets(
      '띠에 걸친 글자는 고른 색으로 띠 높이만 잘라 그리고, 띠 밖은 그 줄을 빼고 그린다 — 겹쳐 그리지 않는다',
      (tester) async {
        await tester.pumpWidget(_host(Brightness.light, _picker()));
        await tester.pumpAndSettle();
        final root = tester.getRect(_wheelRoot());
        final y = root.center.dy;
        // 밖 층 — 칼럼마다, 띠 줄이 빠진 자름(evenOdd)으로 그린다. 눌리는 자리는 그대로다
        final punch = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_BandPunch',
        );
        expect(punch, findsNWidgets(2));
        final canvas = TestRecordingCanvas();
        tester
            .renderObject(punch.first)
            .paint(TestRecordingPaintingContext(canvas), Offset.zero);
        final clips = canvas.invocations
            .where((i) => i.invocation.memberName == #clipPath)
            .map((i) => i.invocation.positionalArguments.first as Path)
            .toList();
        expect(clips, isNotEmpty);
        final path = clips.first;
        final col = tester.getRect(_col('연도'));
        final x = col.center.dx - root.left;
        expect(path.contains(Offset(x, 4)), isTrue); // 위 줄들은 그린다
        expect(path.contains(Offset(x, root.height - 4)), isTrue);
        expect(path.contains(Offset(x, y - root.top)), isFalse); // 띠 줄은 빼고
        expect(path.contains(Offset(x, y - root.top - 21)), isFalse);
        expect(path.contains(Offset(x, y - root.top + 21)), isFalse);
        expect(path.contains(Offset(x, y - root.top - 23)), isTrue);
        // 띠 줄은 안 층이 그린다 — 띠 높이로 잘라
        final layerB = tester.getRect(_layerB('연도'));
        expect(layerB.height, 44);
        expect(layerB.center.dy, y);
        // 그리기만 자르고 눌리는 자리는 그대로 — 띠 위에서 끌어도 휠이 구른다
        final calls = <(int, int)>[];
        await tester.pumpWidget(
          _host(Brightness.light, _picker(onYear: (v, d) => calls.add((v, d)))),
        );
        await tester.pumpAndSettle();
        // 띠 줄(안 층 한가운데)에서 시작해 끈다
        await tester.drag(
          _layerB('연도'),
          const Offset(0, -88),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(calls, [(2028, 2)]);
      },
    );

    testWidgets('굴리는 동안 항목이 띠를 지나는 만큼 띠 안 글자도 함께 움직인다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, _picker()));
      await tester.pumpAndSettle();
      final root = tester.getRect(_wheelRoot());
      final controller =
          tester.widget<ListWheelScrollView>(_layerA('연도')).controller!
              as FixedExtentScrollController;
      final g = await tester.startGesture(
        tester.getCenter(_textA('연도', '2025년')),
      );
      await g.moveBy(const Offset(0, -20));
      await g.moveBy(const Offset(0, -20));
      await tester.pump();
      // 칸 사이에 있다 — 두 항목이 띠에 걸친다
      final pixels = controller.offset;
      expect(pixels % 44, isNot(0));
      final first = (pixels / 44).floor();
      final bandTop = root.center.dy - 22;
      final b = find.descendant(of: _layerB('연도'), matching: find.byType(Text));
      final ys = [
        for (final e in b.evaluate())
          (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dy,
      ]..sort();
      expect(ys.length, 2);
      // 항목 p 의 자리 = 띠 윗줄 + (p × 44 − 스크롤) — 글 상자는 칸 안에서 4.5 아래
      expect(ys.first, closeTo(bandTop + (first * 44 - pixels) + 4.5, 0.01));
      expect(
        ys.last,
        closeTo(bandTop + ((first + 1) * 44 - pixels) + 4.5, 0.01),
      );
      // 굴리는 동안은 값을 정하지 않았다 — 읽는 값은 그대로
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('값 정하기', () {
    testWidgets('↓ 는 다음 항목 — 멈춘 뒤 값이 한 번 정해진다(stepDelta +1)', (tester) async {
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(Brightness.light, _picker(onYear: (v, d) => calls.add((v, d)))),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      // 굴리는 동안에는 정하지 않는다
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, isEmpty);
      await tester.pumpAndSettle();
      expect(calls, [(2027, 1)]);
      expect(_centerLabel(tester, '연도'), '2027년');
    });

    testWidgets('↑ 는 이전, Home · End 는 처음 · 끝 — 처음에서 ↑ 는 그대로', (tester) async {
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(Brightness.light, _picker(onYear: (v, d) => calls.add((v, d)))),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(calls.last, (2025, -1));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(calls.last, (2031, 6));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(calls.last, (2021, -10));
      final n = calls.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(calls.length, n);
      expect(_centerLabel(tester, '연도'), '2021년');
    });

    testWidgets('빠르게 거듭 누르면 가던 자리에서 이어 가고, 값은 멈춘 뒤 한 번만', (tester) async {
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(Brightness.light, _picker(onYear: (v, d) => calls.add((v, d)))),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(calls, [(2029, 3)]);
    });

    testWidgets('반복 칼럼 — 12월 다음은 1월, stepDelta 로 넘어간 것을 안다', (tester) async {
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _picker(monthInitial: 12, onMonth: (v, d) => calls.add((v, d))),
        ),
      );
      await tester.pumpAndSettle();
      // 두 번째 Tab 자리가 월
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(calls, [(1, 1)]);
      expect(_centerLabel(tester, '월'), '1월');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(calls.last, (12, -1));
      // 끝 → 처음이 이어져 위아래 어디서든 아래 항목은 다음 값이다 — 1 이 12 아래로 이어진다
      expect(_centerLabel(tester, '월'), '12월');
      final below = find.descendant(of: _layerA('월'), matching: findText('1월'));
      final belowY = (below.evaluate().first.renderObject! as RenderBox)
          .localToGlobal(Offset.zero)
          .dy;
      expect(belowY, greaterThan(tester.getRect(_wheelRoot()).center.dy));
    });

    testWidgets('연 칼럼은 반복하지 않는다 — 끝 항목 아래는 비어 있다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _picker(yearInitial: 2031)),
      );
      await tester.pumpAndSettle();
      expect(_centerLabel(tester, '연도'), '2031년');
      // 2021 이 2031 아래에 이어지지 않는다
      expect(
        find.descendant(of: _layerA('연도'), matching: findText('2021년')),
        findsNothing,
      );
    });

    testWidgets('밀면 멈춘 뒤 가까운 칸에 서고 값이 한 번 정해진다', (tester) async {
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(Brightness.light, _picker(onYear: (v, d) => calls.add((v, d)))),
      );
      await tester.pumpAndSettle();
      await tester.drag(_textA('연도', '2028년'), const Offset(0, -88));
      await tester.pumpAndSettle();
      expect(calls, [(2028, 2)]);
      expect(_centerLabel(tester, '연도'), '2028년');
      // 칸 사이에서 천천히 놓아도 가까운 칸에 선다 — 반 칸을 못 넘기면 제자리(끌기 시작 거리 18 은 빼고 센다)
      await tester.timedDrag(
        _textA('연도', '2029년'),
        const Offset(0, -35),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(_centerLabel(tester, '연도'), '2028년');
      expect(calls.length, 1);
    });

    testWidgets('보이는 항목을 누르면 그 항목을 가운데로 — 멈춘 뒤 값을 정한다', (tester) async {
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(Brightness.light, _picker(onYear: (v, d) => calls.add((v, d)))),
      );
      await tester.pumpAndSettle();
      await tester.tap(_textA('연도', '2028년'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, isEmpty);
      await tester.pumpAndSettle();
      expect(calls, [(2028, 2)]);
      expect(_centerLabel(tester, '연도'), '2028년');
      // 가운데 항목을 눌러도 그대로
      await tester.tap(_textA('연도', '2028년'));
      await tester.pumpAndSettle();
      expect(calls.length, 1);
    });

    testWidgets('모션 줄이기면 누르기 · 키 이동을 바로 한다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _picker(), reduceMotion: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(_textA('연도', '2028년'));
      await tester.pump();
      // 한 프레임 안에 옮겼다(부드럽게 가는 중이 아니다)
      expect(_centerLabel(tester, '연도'), '2028년');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_centerLabel(tester, '연도'), '2029년');
      await tester.pumpAndSettle();
    });

    testWidgets('굴리는 동안 띠를 지나는 항목마다 onIndexChange — 값은 아직 정하지 않는다', (
      tester,
    ) async {
      final ticks = <(int, int)>[];
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _picker(
            onYearIndex: (i, v) => ticks.add((i, v)),
            onYear: (v, d) => calls.add((v, d)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      // 굴러 지나는 동안 항목마다 알린다 — 값은 아직이다
      expect(ticks, isNotEmpty);
      expect(calls, isEmpty);
      await tester.pumpAndSettle();
      expect(ticks, [(6, 2027), (7, 2028), (8, 2029), (9, 2030), (10, 2031)]);
      expect(calls, [(2031, 5)]);
    });

    testWidgets('굴리는 동안 쓰는 쪽이 다시 그려도(onIndexChange 로 상태를 바꿔도) 멈춘 뒤 값이 정해진다', (
      tester,
    ) async {
      final calls = <(int, int)>[];
      var ticks = 0;
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return _picker(
                onYearIndex: (_, _) => set(() => ticks++),
                onYear: (v, d) => calls.add((v, d)),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(ticks, 1);
      expect(calls, [(2027, 1)]);
    });

    testWidgets('쓰는 쪽이 값을 바꿔 옮길 때는 지나는 항목을 알리지 않는다', (tester) async {
      final ticks = <int>[];
      Widget page(int year) => _host(
        Brightness.light,
        _picker(yearValue: year, onYearIndex: (i, _) => ticks.add(i)),
      );
      await tester.pumpWidget(page(2026));
      await tester.pumpAndSettle();
      await tester.pumpWidget(page(2030));
      await tester.pumpAndSettle();
      expect(_centerLabel(tester, '연도'), '2030년');
      expect(ticks, isEmpty);
    });
  });

  group('쓰는 쪽이 쥔 값', () {
    testWidgets('바깥에서 값을 바꾸면 그 자리로 옮긴다 — 반복 칼럼은 가까운 쪽으로', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _picker(yearValue: 2026)),
      );
      await tester.pumpAndSettle();
      expect(_centerLabel(tester, '연도'), '2026년');
      await tester.pumpWidget(
        _host(Brightness.light, _picker(yearValue: 2030)),
      );
      await tester.pumpAndSettle();
      expect(_centerLabel(tester, '연도'), '2030년');
    });

    testWidgets('smooth 면 부드럽게 간다 — 가는 도중에는 가운데가 아니다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _picker(
            yearValue: 2026,
            yearValueChange: PWheelPickerValueChange.smooth,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _picker(
            yearValue: 2030,
            yearValueChange: PWheelPickerValueChange.smooth,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final controller =
          tester.widget<ListWheelScrollView>(_layerA('연도')).controller!
              as FixedExtentScrollController;
      expect(controller.offset, inExclusiveRange(5 * 44.0, 9 * 44.0));
      await tester.pumpAndSettle();
      expect(controller.offset, 9 * 44.0);
    });

    testWidgets('사용자가 고른 값은 onChanged 로만 알리고 번호는 쓰는 쪽이 정한다 — 읽는 값은 그대로다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _picker(yearValue: 2026, onYear: (v, d) => calls.add((v, d))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(calls, [(2027, 1)]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('연도')),
        isSemantics(label: '연도', value: '2026년'),
      );
      semantics.dispose();
    });

    testWidgets('사용자가 만지는 동안에는 쓰는 쪽이 바꾼 값으로 덮어쓰지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _picker(yearValue: 2026)),
      );
      await tester.pumpAndSettle();
      final g = await tester.startGesture(
        tester.getCenter(_textA('연도', '2028년')),
      );
      await g.moveBy(const Offset(0, -20));
      await g.moveBy(const Offset(0, -20));
      await tester.pump();
      final controller =
          tester.widget<ListWheelScrollView>(_layerA('연도')).controller!
              as FixedExtentScrollController;
      final held = controller.offset;
      expect(held, greaterThan(5 * 44.0));
      await tester.pumpWidget(
        _host(Brightness.light, _picker(yearValue: 2021)),
      );
      await tester.pump();
      await tester.pump();
      // 손가락 아래에 있던 자리 그대로 — 2021 자리(0)로 튀지 않는다
      expect(controller.offset, held);
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('막힘', () {
    testWidgets('막힌 휠 — 초점이 가지 않고 굴릴 수도 눌러 옮길 수도 없다, 값은 그대로 읽힌다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _picker(disabled: true, onYear: (v, d) => calls.add((v, d))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.drag(_textA('연도', '2028년'), const Offset(0, -88));
      await tester.tap(_textA('연도', '2028년'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(_centerLabel(tester, '연도'), '2026년');
      final node = tester.getSemantics(find.bySemanticsLabel('연도'));
      expect(
        node,
        isSemantics(
          label: '연도',
          value: '2026년',
          hasEnabledState: true,
          isEnabled: false,
          hasIncreaseAction: false,
          hasDecreaseAction: false,
        ),
      );
      semantics.dispose();
    });
  });

  group('읽는 말', () {
    testWidgets(
      '휠은 이름 있는 묶음, 칼럼은 조절 가능한 값 — 이름 · 지금 값 · 다음 · 이전 값의 글, 항목은 숨긴다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_host(Brightness.light, _picker()));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('월 선택'), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel('연도')),
          isSemantics(
            label: '연도',
            value: '2026년',
            increasedValue: '2027년',
            decreasedValue: '2025년',
            hasEnabledState: true,
            isEnabled: true,
            hasIncreaseAction: true,
            hasDecreaseAction: true,
            isFocusable: true,
          ),
        );
        // 반복 칼럼은 끝에서도 이어진다(10월의 다음 · 이전)
        expect(
          tester.getSemantics(find.bySemanticsLabel('월')),
          isSemantics(
            label: '월',
            value: '10월',
            increasedValue: '11월',
            decreasedValue: '9월',
            hasIncreaseAction: true,
            hasDecreaseAction: true,
          ),
        );
        // 항목은 보조 기술에 숨긴다
        expect(find.bySemanticsLabel('2027년'), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets('처음 · 끝에서는 그 방향 동작이 없다 — 반복 칼럼은 끝에서 처음으로', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, _picker(yearInitial: 2021, monthInitial: 12)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('연도')),
        isSemantics(
          value: '2021년',
          increasedValue: '2022년',
          hasIncreaseAction: true,
          hasDecreaseAction: false,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('월')),
        isSemantics(
          value: '12월',
          increasedValue: '1월',
          decreasedValue: '11월',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('올리기 · 내리기 동작은 한 칸 옮기고 멈춘 뒤 값을 정한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final calls = <(int, int)>[];
      await tester.pumpWidget(
        _host(Brightness.light, _picker(onYear: (v, d) => calls.add((v, d)))),
      );
      await tester.pumpAndSettle();
      tester.semantics.performAction(
        find.semantics.byLabel('연도'),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(calls, [(2027, 1)]);
      tester.semantics.performAction(
        find.semantics.byLabel('연도'),
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      expect(calls.last, (2026, -1));
      semantics.dispose();
    });

    testWidgets('읽는 글은 항목의 semanticLabel 이 우선이다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PWheelPicker(
            semanticLabel: '시각 선택',
            children: [
              PWheelPickerColumn<String>(
                semanticLabel: '오전 오후',
                initialValue: 'pm',
                options: const [
                  PWheelPickerOption(
                    value: 'am',
                    label: 'AM',
                    semanticLabel: '오전',
                  ),
                  PWheelPickerOption(
                    value: 'pm',
                    label: 'PM',
                    semanticLabel: '오후',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('오전 오후')),
        isSemantics(value: '오후', decreasedValue: '오전'),
      );
      semantics.dispose();
    });
  });

  test('칸 수는 5 · 7 — 가운데 줄이 있어야 해서 홀수만', () {
    expect(
      () => PWheelPicker(
        semanticLabel: '월 선택',
        visibleItems: 6,
        children: const [],
      ),
      throwsAssertionError,
    );
    expect(
      () => PWheelPickerColumn<int>(semanticLabel: '월', options: const []),
      throwsAssertionError,
    );
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 견본이 크기 × 칸 수 · 막힘 · 직접 굴려 보기를 모두 그린다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
              child: WheelPickerDemo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final wheels = tester
          .widgetList<PWheelPicker>(find.byType(PWheelPicker))
          .toList();
      // 크기 둘 × 칸 수 둘 + 막힘 둘 + 직접 굴려 보기 둘
      expect(wheels.length, 8);
      expect(wheels.where((w) => w.disabled).length, 2);
      expect(
        {for (final w in wheels) (w.size, w.visibleItems)},
        containsAll([
          (PWheelPickerSize.medium, 5),
          (PWheelPickerSize.medium, 7),
          (PWheelPickerSize.small, 5),
          (PWheelPickerSize.small, 7),
        ]),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
