// Chip 이 스펙 값(test/fixtures/design_spec/chip.json)대로인지 — 변형 × 크기 × 모양 × 고름 × 상태(기본 · 누름 · 비활성) ×
// 라이트 · 다크의 칩 상자 · 아이콘 · 글 · 색 · 누름 축소와, 입력값 칩 · 묶음(줄바꿈 · 가로 스크롤) · 동작 · 읽는 말.
// 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 상태(웹의 hovered · focused — 올림 · 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 —
// 누르는 영역("44 × 44")은 누른 자리로, 누름 축소("칩 전체 2px")는 그려진 배율로, 가로 스크롤은 스크롤해 본다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/chip_demo.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('chip');

/// 앱의 상태 — 웹의 hovered(올림) · focused(키보드 포커스 링)는 앱에 없다.
final _appStates = _spec.states
    .where((s) => s != 'hovered' && s != 'focused')
    .toList();

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  double width = 312,
  Alignment alignment = Alignment.topLeft,
}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: Align(
        alignment: alignment,
        child: SizedBox(
          width: width,
          // 칩은 놓인 자리가 폭을 정하지 않는다 — 글만큼이다(Wrap · Row 안과 같다)
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
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

Finder get _box => find.byKey(const ValueKey('chip-box'));
Finder get _pillBox => find.byKey(const ValueKey('input-chip-box'));
Finder get _remove => find.byKey(const ValueKey('input-chip-remove'));

BoxDecoration _decoration(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;

/// 그려지는 배율 — 그 상자에서 화면까지 겹친 변환의 확대(레이아웃 크기에는 안 잡히는 누름 축소를 잰다).
double _paintedScale(WidgetTester tester, Finder finder) =>
    tester.renderObject(finder).getTransformTo(null).entry(0, 0);

/// 칩을 누른 채로 두고(누름), 전환(색 150ms · 누름 축소 150ms)이 끝나게 기다린다.
Future<TestGesture?> _settle(
  WidgetTester tester,
  String state,
  Finder target,
) async {
  TestGesture? gesture;
  if (state == 'pressed') {
    gesture = await tester.startGesture(tester.getCenter(target));
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

  /// 안쪽 1px 선 — 스펙에 두께가 있으면 그 색 · 두께로 그리고, 없거나 0 이면 투명이다. 선은 늘 안쪽에 그려
  /// 크기가 변하지 않는다(웹 inset box-shadow).
  void border(String slot, BoxDecoration deco) {
    final border = deco.border as Border?;
    if (border == null) {
      fail('$slot 선이 없다 — 안쪽 선은 늘 그려 두고 색으로 나타난다');
      return;
    }
    if (border.top.width != 1) {
      fail('$slot.borderWidth: 그리는 두께 스펙 1 · 실제 ${border.top.width}');
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

/// 다른 테스트가 재는 값 — 입력값 칩 · 묶음 · 스크롤 줄(아래 group)과, 동작으로 보는 값(누르는 영역 · 전환이 무엇을 바꾸는지).
const _elsewhere = {
  'root.touchTarget',
  'root.transitionProperty',
  'removeButton.color',
  'removeButton.size',
  'removeButton.scale',
  'group.gap',
  'group.rowGap',
  'group.minHeight',
  'group.outlineWidth',
  'group.outlineOffset',
  'group.outlineColor',
  'scrollRow.paddingX',
  'scrollRow.paddingY',
  'scrollRow.marginY',
  'scrollRow.overflowX',
  'scrollRow.fog',
  'scrollRow.scrollPadding',
  // 줄 폭에서 멈추고 글 끝을 말줄임한다(03-E 결정 2 A) — 아래 "줄 폭" 묶음이 잰다
  'root.maxWidth',
  'label.overflow',
};

PChipVariant _variant(String name) => PChipVariant.values.byName(name);
PChipSize _size(String name) => PChipSize.values.byName(name);

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos([
      'variant',
      'size',
      'layout',
      'selected',
    ])) {
      for (final state in _appStates) {
        final title =
            '${mode.name} ${combo['variant']} ${combo['size']} ${combo['layout']} ${combo['selected']} $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          final selected = combo['selected'] == 'selected';
          final iconOnly = combo['layout'] == 'iconOnly';
          final disabled = state == 'disabled';
          final onPressed = disabled ? null : () {};
          // 글이 있는 칩은 앞 · 뒤 아이콘을 모두 둔다 — 크기마다 14 · 16 · 16 / 14 · 14 · 16 을 한 번에 잰다
          final chip = iconOnly
              ? PChip.icon(
                  icon: LucideIcons.rotateCcw,
                  semanticLabel: '필터 지우기',
                  variant: _variant(combo['variant']!),
                  size: _size(combo['size']!),
                  selected: selected,
                  onPressed: onPressed,
                )
              : PChip(
                  label: '식비 외 2개',
                  variant: _variant(combo['variant']!),
                  size: _size(combo['size']!),
                  selected: selected,
                  prefixIcon: LucideIcons.tag,
                  suffixIcon: LucideIcons.chevronDown,
                  onPressed: onPressed,
                );
          await tester.pumpWidget(_host(mode, chip));
          // 놓인 자리는 누르기 전에 잰다 — 누르면 칩 전체가 줄어 화면에 그려진 사각형이 작아진다
          final rect = tester.getRect(_box);
          final iconRects = [
            for (final e
                in find
                    .descendant(of: _box, matching: find.byType(Icon))
                    .evaluate())
              tester.getRect(find.byElementPredicate((x) => x == e)),
          ];
          final labelRect = iconOnly
              ? Rect.zero
              : tester.getRect(
                  find.descendant(of: _box, matching: find.byType(Text)),
                );
          final gesture = await _settle(tester, state, _box);
          final k = _Check(mode, _spec.resolve(combo, state), title);
          final measured = <String>{};
          void m(Iterable<String> keys) => measured.addAll(keys);

          final deco = _decoration(tester, _box);

          // 상자 — 높이 · 모서리 · 아이콘만 있으면 원
          k.px('root.height', rect.height);
          if (iconOnly) k.px('root.width', rect.width);
          k.radius('root.radius', deco);
          m(['root.height', 'root.width', 'root.radius']);

          // 색 — 바탕 · 안쪽 1px 선 · 글자(글자색은 글 · 아이콘이 따른다)
          k.color('root.background', deco.color!);
          k.border('root', deco);
          m([
            'root.background',
            'root.borderColor',
            'root.borderWidth',
            'root.foreground',
          ]);

          // 커서 · 전환
          k.cursor(
            'root.cursor',
            tester
                .widget<MouseRegion>(
                  find
                      .ancestor(of: _box, matching: find.byType(MouseRegion))
                      .first,
                )
                .cursor,
          );
          final colors = tester.widget<TweenAnimationBuilder<dynamic>>(
            find
                .ancestor(
                  of: _box,
                  matching: find.byWidgetPredicate(
                    (w) => w.runtimeType.toString().startsWith(
                      'TweenAnimationBuilder<',
                    ),
                  ),
                )
                .first,
          );
          k.motion(
            'root.transitionDuration',
            'root.transitionEasing',
            colors.duration,
            colors.curve,
          );
          m([
            'root.cursor',
            'root.transitionDuration',
            'root.transitionEasing',
          ]);

          // 누름 축소 — 칩 전체(놓인 자리는 그대로)
          final scale = tester.widget<AnimatedScale>(
            find.ancestor(of: _box, matching: find.byType(AnimatedScale)).first,
          );
          k.pressScale('root.scale', scale.scale, rect.size);
          k.motion(
            'root.scaleDuration',
            'root.scaleEasing',
            scale.duration,
            scale.curve,
          );
          m(['root.scale', 'root.scaleDuration', 'root.scaleEasing']);

          final icons = tester
              .widgetList<Icon>(
                find.descendant(of: _box, matching: find.byType(Icon)),
              )
              .toList();
          if (iconOnly) {
            // 아이콘만 — 칩 가운데, 크기 14 · 16 · 16, 안쪽 여백 없다
            k.px('icon.size', icons.single.size!);
            k.px('root.paddingX', 0);
            final iconRect = iconRects.single;
            if ((iconRect.center - rect.center).distance > 0.5) {
              k.fail('icon: 칩 가운데가 아니다 $iconRect · $rect');
            }
            if (icons.single.color != null) {
              final fg = pickMode(k.want['root.foreground'], mode);
              if (!sameColor(specColor(fg), icons.single.color!)) {
                k.fail('icon 색: 스펙 $fg · 실제 ${colorHex(icons.single.color!)}');
              }
            }
          } else {
            // 앞 아이콘 · 글 · 뒤 아이콘 — 크기 · 가장자리 ↔ 아이콘 · 아이콘 ↔ 글 6
            k.px('prefixIcon.size', icons[0].size!);
            k.px('suffixIcon.size', icons[1].size!);
            final prefix = iconRects.first;
            final suffix = iconRects.last;
            final label = labelRect;
            k.px('root.paddingX', prefix.left - rect.left);
            k.px('root.paddingX', rect.right - suffix.right);
            k.px('root.gap', label.left - prefix.right);
            k.px('root.gap', suffix.left - label.right);
            for (final i in icons) {
              final fg = pickMode(k.want['root.foreground'], mode);
              if (!sameColor(specColor(fg), i.color!)) {
                k.fail('icon 색: 스펙 $fg · 실제 ${colorHex(i.color!)}');
              }
            }
            // 글 — t4 14 / 19 · 500 · 한 줄(줄바꿈 · 말줄임 없다)
            final text = tester.widget<Text>(
              find.descendant(of: _box, matching: find.byType(Text)),
            );
            k.typo('label.typography', text.style!);
            k.weight('label.fontWeight', text.style!);
            k.color('root.foreground', text.style!.color!);
            if (text.softWrap != false || text.maxLines != 1) {
              k.fail('label: 줄바꿈하지 않는다 — 한 줄');
            }
            // 말줄임은 줄 폭에 닿을 때만 보인다 — 짧은 글은 그대로(아래 "줄 폭" 묶음)
            if (text.overflow != TextOverflow.ellipsis) {
              k.fail('label.overflow: 말줄임(…) 이어야 한다');
            }
            // 글만큼 넓어진다 — 가장자리 + 아이콘 + 6 + 글 + 6 + 아이콘 + 가장자리
            k.px(
              'root.paddingX',
              (rect.width -
                      (prefix.width + label.width + suffix.width + 2 * 6)) /
                  2,
            );
          }
          m([
            'icon.size',
            'prefixIcon.size',
            'suffixIcon.size',
            'root.paddingX',
            'root.gap',
            'label.typography',
            'label.fontWeight',
          ]);
          // 최소 폭은 아래 "글이 짧아도" 에서 잰다
          m(['root.minWidth']);

          k.coverage(measured, {..._webOnly, ..._elsewhere});
          await gesture?.up();
          await tester.pump(const Duration(milliseconds: 400));
          if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
        });
      }
    }
  }

  group('크기', () {
    testWidgets('글이 짧아도 최소 폭 44 · 48 · 52 — 글이 길면 글만큼 넓어진다', (tester) async {
      for (final size in PChipSize.values) {
        final want = _spec.resolve({'size': size.name}, 'enabled');
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PChip(label: '가', size: size, onPressed: () {}),
          ),
        );
        expect(
          tester.getSize(_box).width,
          want['root.minWidth'],
          reason: size.name,
        );
        // 긴 글 — 줄바꿈 없이 한 줄, 폭은 글 + 좌우 여백
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PChip(label: '신한카드 마이 포인트 플러스 체크카드', size: size, onPressed: () {}),
            width: 600,
          ),
        );
        final label = tester.getRect(
          find.descendant(of: _box, matching: find.byType(Text)),
        );
        expect(label.height, lessThan(24), reason: '한 줄 ${size.name}');
        expect(
          tester.getSize(_box).width,
          closeTo(label.width + 2 * (want['root.paddingX']! as num), 0.01),
        );
        expect(tester.getSize(_box).height, want['root.height']);
      }
    });

    testWidgets('크기 표가 스펙과 같다(small 32 · medium 36 · large 40)', (
      tester,
    ) async {
      for (final size in PChipSize.values) {
        final want = _spec.resolve({'size': size.name}, 'enabled');
        final m = PChipMetrics.of(size);
        expect(m.height, want['root.height']);
        expect(m.paddingX, want['root.paddingX']);
        expect(m.minWidth, want['root.minWidth']);
        expect(m.prefixIcon, want['prefixIcon.size']);
        expect(m.suffixIcon, want['suffixIcon.size']);
        expect(m.removeIcon, want['removeButton.size']);
        expect(m.icon, want['icon.size']);
      }
    });
  });

  group('줄 폭', () {
    const longLabel = '이름이 아주 길어서 한 줄에 다 들어가지 않는 카드 혜택 모음 이야기';
    Widget scaled(double factor, Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(factor)),
        child: child,
      ),
    );

    testWidgets('root.maxWidth — 놓인 줄 폭에서 멈추고 글 끝을 말줄임한다(아이콘은 남는다)', (
      tester,
    ) async {
      final want = _spec.resolve({}, 'enabled');
      expect(want['root.maxWidth'], '100%');
      expect(want['label.overflow'], '말줄임(…)');
      for (final size in PChipSize.values) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PChipGroup(
              children: [
                PChip(
                  label: longLabel,
                  size: size,
                  prefixIcon: LucideIcons.tag,
                  suffixIcon: LucideIcons.chevronDown,
                  onPressed: () {},
                ),
              ],
            ),
            width: 200,
          ),
        );
        expect(tester.getSize(_box).width, 200, reason: '줄 폭 ${size.name}');
        final text = tester.widget<Text>(
          find.descendant(of: _box, matching: find.byType(Text)),
        );
        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.maxLines, 1);
        // 아이콘은 줄지 않고 남는다
        final icons = find.descendant(of: _box, matching: find.byType(Icon));
        final m = PChipMetrics.of(size);
        expect(tester.getSize(icons.first).width, m.prefixIcon);
        expect(tester.getSize(icons.last).width, m.suffixIcon);
        final box = tester.getRect(_box);
        expect(
          tester.getRect(icons.last).right,
          closeTo(box.right - m.paddingX, 0.01),
        );
        expect(tester.takeException(), isNull, reason: '넘침 없음 ${size.name}');
      }
    });

    testWidgets('줄보다 짧은 칩은 그대로 글만큼 넓다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PChipGroup(
            children: [PChip(label: '식비', onPressed: () {})],
          ),
          width: 200,
        ),
      );
      expect(tester.getSize(_box).width, lessThan(100));
    });

    testWidgets('입력값 칩 — 줄 폭에서 멈추고 글만 말줄임, 지우기 ×는 남는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PChipGroup(
            children: [
              PInputChip(
                label: longLabel,
                removeLabel: '$longLabel 지우기',
                onRemove: () {},
              ),
            ],
          ),
          width: 200,
        ),
      );
      expect(tester.getSize(_pillBox).width, 200);
      final remove = find.byKey(const ValueKey('input-chip-remove'));
      expect(tester.getSize(remove).width, 14);
      expect(
        tester.getRect(remove).right,
        closeTo(tester.getRect(_pillBox).right - 14, 0.01),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('가로 스크롤 줄 — 보이는 줄 폭(화면 여백 24 안)에서 멈춘다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PChipGroup(
            layout: PChipGroupLayout.scroll,
            children: [
              PChip(label: longLabel, onPressed: () {}),
              PChip(label: '식비', onPressed: () {}),
            ],
          ),
          width: 312,
        ),
      );
      expect(tester.getSize(_box.first).width, 312 - 2 * 24);
      expect(tester.getSize(_box.last).width, lessThan(100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('글자 200% 에서도 줄 폭 안이고 칩은 글을 따라 늘어난다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          scaled(
            2,
            PChipGroup(
              children: [PChip(label: longLabel, onPressed: () {})],
            ),
          ),
          width: 200,
        ),
      );
      expect(tester.getSize(_box).width, 200);
      expect(tester.takeException(), isNull);
    });
  });

  group('큰 글자 — 높이는 최소 높이다', () {
    Widget scaled(double factor, Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(factor)),
        child: child,
      ),
    );

    testWidgets(
      '100% 는 32 · 36 · 40, 200% 는 (높이 − 19) + 19 × 2 = 51 · 55 · 59 — 글을 따라 늘어난다',
      (tester) async {
        const expected = {
          PChipSize.small: [32.0, 51.0],
          PChipSize.medium: [36.0, 55.0],
          PChipSize.large: [40.0, 59.0],
        };
        for (final e in expected.entries) {
          for (var i = 0; i < 2; i++) {
            final factor = i == 0 ? 1.0 : 2.0;
            await tester.pumpWidget(
              _host(
                Brightness.light,
                scaled(
                  factor,
                  PChip(label: '식비', size: e.key, onPressed: () {}),
                ),
              ),
            );
            expect(
              tester.getSize(_box).height,
              closeTo(e.value[i], 0.01),
              reason: '${e.key.name} × $factor',
            );
          }
        }
      },
    );

    testWidgets('입력값 칩도 200% 에서 늘어난다(55)', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          scaled(
            2,
            PInputChip(label: '김하나', removeLabel: '김하나 지우기', onRemove: () {}),
          ),
        ),
      );
      expect(tester.getSize(_pillBox).height, closeTo(55, 0.01));
    });
  });

  group('막힌 Solid', () {
    testWidgets(
      '안 고른 solid 는 막혀도 바탕이 bg-neutral-weak-alpha 이고 글 · 아이콘만 fg-disabled 다',
      (tester) async {
        for (final mode in Brightness.values) {
          await tester.pumpWidget(
            _host(
              mode,
              const PChip(
                label: '식비',
                variant: PChipVariant.solid,
                prefixIcon: LucideIcons.tag,
                onPressed: null,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
          final c = mode == Brightness.dark ? PColors.dark : PColors.light;
          expect(
            _decoration(tester, _box).color,
            c.bgNeutralWeakAlpha,
            reason: mode.name,
          );
          final text = tester.widget<Text>(
            find.descendant(of: _box, matching: find.byType(Text)),
          );
          expect(text.style!.color, c.fgDisabled);
          final icon = tester.widget<Icon>(
            find.descendant(of: _box, matching: find.byType(Icon)),
          );
          expect(icon.color, c.fgDisabled);
        }
      },
    );
  });

  group('입력값 칩', () {
    for (final mode in Brightness.values) {
      for (final size in PChipSize.values) {
        for (final state in ['enabled', 'disabled']) {
          testWidgets('${mode.name} ${size.name} $state — 스펙 값이다', (
            tester,
          ) async {
            // 입력값 칩은 Outline Weak 의 고른 모습이다 — 막히면 회색 바탕 + 짙은 1px
            final combo = {
              'variant': 'outlineWeak',
              'selected': 'selected',
              'size': size.name,
            };
            final k = _Check(
              mode,
              _spec.resolve(combo, state),
              '${mode.name} ${size.name} $state',
            );
            await tester.pumpWidget(
              _host(
                mode,
                PInputChip(
                  label: '김하나',
                  removeLabel: '김하나 지우기',
                  size: size,
                  onRemove: state == 'disabled' ? null : () {},
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 400));
            final rect = tester.getRect(_pillBox);
            final deco = _decoration(tester, _pillBox);
            k.px('root.height', rect.height);
            k.radius('root.radius', deco);
            k.color('root.background', deco.color!);
            k.border('root', deco);
            // 글 · 지우기 아이콘은 글자색 그대로 — 지우기 아이콘 14 · 14 · 16
            final text = tester.widget<Text>(
              find.descendant(of: _pillBox, matching: find.byType(Text)),
            );
            k.color('root.foreground', text.style!.color!);
            k.typo('label.typography', text.style!);
            k.weight('label.fontWeight', text.style!);
            final removeIcon = tester.widget<Icon>(
              find.descendant(of: _remove, matching: find.byType(Icon)),
            );
            k.px('removeButton.size', removeIcon.size!);
            k.px('removeButton.size', tester.getSize(_remove).width);
            if (!sameColor(
              specColor(pickMode(k.want['root.foreground'], mode)),
              removeIcon.color!,
            )) {
              k.fail('removeButton.color: 글자색 그대로 — ${removeIcon.color}');
            }
            // 가장자리 ↔ 글 · 글 ↔ 지우기 6 · 지우기 ↔ 가장자리
            final label = tester.getRect(
              find.descendant(of: _pillBox, matching: find.byType(Text)),
            );
            final remove = tester.getRect(_remove);
            k.px('root.paddingX', label.left - rect.left);
            k.px('root.paddingX', rect.right - remove.right);
            k.px('root.gap', remove.left - label.right);
            if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
          });
        }
      }
    }

    testWidgets('칩은 누르지 않는다 — 지우기만 눌리고, 지우기의 누르는 영역은 24 × 24 다', (
      tester,
    ) async {
      var removed = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: PInputChip(
              label: '김하나',
              removeLabel: '김하나 지우기',
              onRemove: () => removed++,
            ),
          ),
          alignment: Alignment.center,
        ),
      );
      // 칩 글을 눌러도 아무 일이 없다
      await tester.tap(findText('김하나'));
      expect(removed, 0);
      // 지우기 아이콘(14) 둘레 24 × 24 까지 받는다
      final c = tester.getCenter(_remove);
      await tester.tapAt(c + const Offset(11, 0));
      expect(removed, 1);
      await tester.tapAt(c + const Offset(0, -11));
      expect(removed, 2);
      await tester.tapAt(c + const Offset(13, 0));
      expect(removed, 2);
    });

    testWidgets('누르면 지우기만 2px 거리 준다 — 기준 24, 칩은 줄지 않는다(모션 줄이기면 줄지 않는다)', (
      tester,
    ) async {
      final want = _spec.resolve({
        'variant': 'outlineWeak',
        'selected': 'selected',
      }, 'pressed');
      expect(want['removeButton.scale'], isNotNull);
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PInputChip(label: '김하나', removeLabel: '김하나 지우기', onRemove: () {}),
            reduceMotion: reduce,
          ),
        );
        final pill = tester.getRect(_pillBox);
        final before = _paintedScale(tester, _remove);
        final g = await tester.startGesture(tester.getCenter(_remove));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.getRect(_pillBox), pill);
        expect(_paintedScale(tester, _pillBox), 1);
        expect(
          _paintedScale(tester, _remove) / before,
          closeTo(reduce ? 1 : 22 / 24, 1e-3),
          reason: 'reduce=$reduce',
        );
        await g.up();
        await tester.pump(const Duration(milliseconds: 400));
      }
    });

    testWidgets('막힌 입력값 칩은 지울 수 없다 · 읽는 이름은 쓰는 쪽이 준 글이다', (tester) async {
      final semantics = tester.ensureSemantics();
      var removed = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputChip(label: '김하나', removeLabel: '김하나 지우기', onRemove: null),
        ),
      );
      await tester.tap(_remove, warnIfMissed: false);
      expect(removed, 0);
      expect(
        tester.getSemantics(find.bySemanticsLabel('김하나 지우기')),
        isSemantics(
          label: '김하나 지우기',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PInputChip(
            label: '김하나',
            removeLabel: '김하나 지우기',
            onRemove: () => removed++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('김하나 지우기')),
        isSemantics(
          label: '김하나 지우기',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('묶음', () {
    testWidgets('줄바꿈 묶음은 칩 사이 8 · 줄 사이 8 이다', (tester) async {
      final want = _spec.resolve({}, 'enabled');
      expect(want['group.gap'], 8);
      expect(want['group.rowGap'], 8);
      expect(PSpacing.betweenChips, 8);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PChipGroup(
            semanticLabel: '카테고리',
            children: [
              for (final n in const [
                '식비',
                '교통',
                '쇼핑',
                '의료',
                '문화',
                '교육',
                '통신',
                '주거',
              ])
                PChip(label: n, onPressed: () {}),
            ],
          ),
          width: 200,
        ),
      );
      final rects = [for (var i = 0; i < 8; i++) tester.getRect(_box.at(i))];
      // 같은 줄은 8 간격, 줄이 바뀌면 36 + 8
      final rows = <double>{for (final r in rects) r.top};
      expect(rows.length, greaterThan(1));
      final sorted = rows.toList()..sort();
      for (var i = 1; i < sorted.length; i++) {
        expect(sorted[i] - sorted[i - 1], 36 + 8);
      }
      for (var i = 1; i < rects.length; i++) {
        if (rects[i].top == rects[i - 1].top) {
          expect(rects[i].left - rects[i - 1].right, 8);
        } else {
          expect(rects[i].left, rects.first.left);
        }
      }
      // 칩 20개 · 폰 폭에서도 칩은 줄지 않고 줄만 늘어난다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const SingleChildScrollView(child: ChipDemo()),
          width: 312,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('빈 묶음은 칩 한 줄(36) 높이를 남긴다', (tester) async {
      final want = _spec.resolve({}, 'enabled');
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PChipGroup(semanticLabel: '참여자 없음', children: []),
        ),
      );
      expect(
        tester.getSize(find.byType(ChipLayout)).height,
        want['group.minHeight'],
      );
    });

    testWidgets(
      '가로 스크롤 줄 — 안쪽 좌우 24 · 위아래 6 을 두되 줄 높이는 칩 그대로다 · 한 줄 · 양 끝 흐림',
      (tester) async {
        final want = _spec.resolve({}, 'enabled');
        final names = [for (var i = 0; i < 20; i++) '카테고리$i'];
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PChipGroup(
              layout: PChipGroupLayout.scroll,
              semanticLabel: '카테고리 20개',
              children: [
                for (final n in names)
                  PChip(
                    label: n,
                    variant: PChipVariant.solid,
                    onPressed: () {},
                  ),
              ],
            ),
            width: 360,
          ),
        );
        final row = find.byKey(const ValueKey('chip-scroll-row'));
        final scroll = tester.widget<SingleChildScrollView>(row);
        expect(scroll.scrollDirection, Axis.horizontal);
        final padding = scroll.padding! as EdgeInsets;
        expect(padding.left, want['scrollRow.paddingX']);
        expect(padding.right, want['scrollRow.paddingX']);
        // 위아래 안쪽 6 은 칩마다 둔다 — 줄(스크롤 칸) 높이 = 칩 36 + 12 이고 칩은 그 가운데에 선다
        final viewport = tester.getRect(row);
        expect(viewport.height, 36 + 2 * (want['scrollRow.paddingY']! as num));
        expect(
          tester.getRect(_box.first).top - viewport.top,
          want['scrollRow.paddingY'],
        );
        expect(
          viewport.bottom - tester.getRect(_box.first).bottom,
          want['scrollRow.paddingY'],
        );
        // marginY −6 — 줄 높이는 칩 그대로(36)
        expect(want['scrollRow.marginY'], '−6px');
        expect(tester.getSize(find.byType(ChipLayout)).height, 36);
        expect(tester.getRect(_box.first).left, 24);
        // 한 줄 — 칩 20개가 모두 같은 높이에 서고 360 을 넘어 이어진다
        expect(
          {for (var i = 0; i < 20; i++) tester.getRect(_box.at(i)).top}.length,
          1,
        );
        // 칩 사이 8
        final first = tester.getRect(_box.at(0));
        final second = tester.getRect(_box.at(1));
        expect(second.left - first.right, want['group.gap']);
        // 스크롤하면 끝 칩이 화면 여백 24 에서 끝난다 — 마지막 칩 오른쪽이 360 − 24
        await tester.drag(row, const Offset(-5000, 0));
        await tester.pumpAndSettle();
        expect(tester.getRect(_box.at(19)).right, 360 - 24);
        // 양 끝 20 은 늘 흐린다(Scroll Fog row)
        expect(want['scrollRow.fog'], '좌우 20px');
        expect(
          find.descendant(
            of: find.byType(ChipLayout),
            matching: find.byType(ShaderMask),
          ),
          findsNWidgets(2),
        );
        // 스크롤바는 숨긴다
        expect(find.byType(Scrollbar), findsNothing);
      },
    );

    testWidgets('스크롤 줄 안의 칩은 위아래 누르는 영역 44 까지 받는다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: PChipGroup(
              layout: PChipGroupLayout.scroll,
              semanticLabel: '필터',
              children: [PChip(label: '기간', onPressed: () => taps++)],
            ),
          ),
          width: 360,
        ),
      );
      final r = tester.getRect(_box);
      // 칩은 36 — 위아래 4 씩 넘친 자리(44)까지 받는다
      await tester.tapAt(Offset(r.center.dx, r.top - 3));
      await tester.tapAt(Offset(r.center.dx, r.bottom + 3));
      expect(taps, 2);
      await tester.tapAt(Offset(r.center.dx, r.top - 5));
      expect(taps, 2);
    });
  });

  group('누르기 · 고르기', () {
    testWidgets('누르는 영역은 보이는 칩과 따로 44 × 44 까지 넓다 — 놓인 자리는 그대로다', (
      tester,
    ) async {
      for (final size in PChipSize.values) {
        var taps = 0;
        await tester.pumpWidget(
          _host(
            Brightness.light,
            Center(
              child: PChip.icon(
                icon: LucideIcons.rotateCcw,
                semanticLabel: '필터 지우기',
                size: size,
                onPressed: () => taps++,
              ),
            ),
            alignment: Alignment.center,
          ),
        );
        final r = tester.getRect(_box);
        // 아이콘만 있는 칩 32 · 36 · 40 은 가로도 44 까지
        await tester.tapAt(r.center + const Offset(21, 0));
        await tester.tapAt(r.center + const Offset(0, 21));
        expect(taps, 2, reason: size.name);
        await tester.tapAt(r.center + const Offset(23, 0));
        expect(taps, 2, reason: size.name);
        expect(tester.getSize(_box), Size.square(PChipMetrics.of(size).height));
      }
    });

    testWidgets('버튼 칩 — 누르면 부른다, 막히면 누를 수 없고 Space · Enter 로도 누른다', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(Brightness.light, PChip(label: '10만', onPressed: () => taps++)),
      );
      await tester.tap(findText('10만'));
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 3);
      await tester.pumpWidget(
        _host(Brightness.light, const PChip(label: '10만', onPressed: null)),
      );
      await tester.tap(findText('10만'), warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(taps, 3);
      // 막힌 칩은 포커스를 받지 않는다(Tab 에서 빠진다) — Space · Enter 도 닿지 않는다
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 3);
    });

    testWidgets(
      '여럿 고르기 — 다시 누르면 풀린다 · 칩마다 Tab 이 선다 · Space 로 누른다 · 막히면 누를 수 없다',
      (tester) async {
        final calls = <bool>[];
        var on = false;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _host(
            Brightness.light,
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return PChipGroup(
                  semanticLabel: '알림',
                  children: [
                    PChipToggle(
                      label: '당일',
                      checked: on,
                      onChanged: (v) {
                        calls.add(v);
                        setOuter(() => on = v);
                      },
                    ),
                    PChipToggle(
                      label: '1일 전',
                      checked: false,
                      onChanged: (_) {},
                    ),
                  ],
                );
              },
            ),
          ),
        );
        await tester.tap(findText('당일'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(findText('당일'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(calls, [true, false]);
        // 칩마다 Tab 이 선다
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(calls, [true, false, true]);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = FocusManager.instance.primaryFocus!.rect;
        expect(
          focused.center.dx,
          closeTo(tester.getRect(_box.at(1)).center.dx, 1),
        );
        // Enter 는 누르지 않는다(폼 제출에 둔다)
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(calls, [true, false, true]);
      },
    );

    testWidgets('하나 고르기 — 다시 눌러도 풀리지 않는다 · Tab 은 고른 칩 하나에만 · 화살표로 옮기면 고른다', (
      tester,
    ) async {
      final calls = <String>[];
      var value = 'income';
      final after = FocusNode();
      addTearDown(after.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                PChipRadioGroup<String>(
                  semanticLabel: '거래 종류',
                  value: value,
                  onChanged: (v) => setState(() {
                    calls.add(v);
                    value = v;
                  }),
                  children: const [
                    PChipRadio(value: 'expense', label: '지출'),
                    PChipRadio(value: 'income', label: '수입'),
                    PChipRadio(value: 'transfer', label: '이체', enabled: false),
                    PChipRadio(value: 'etc', label: '기타'),
                  ],
                ),
                Focus(focusNode: after, child: const SizedBox(height: 10)),
              ],
            ),
          ),
        ),
      );
      // 고른 칩을 다시 눌러도 그대로 — 부르지 않는다
      await tester.tap(findText('수입'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, isEmpty);
      // Tab 은 고른 칩 하나에 선다
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus!.rect.center.dx,
        closeTo(tester.getRect(_box.at(1)).center.dx, 1),
      );
      // 화살표로 옮기면 바로 고른다 — 막힌 칩은 건너뛰고 끝에서 처음으로 돈다
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['etc']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['etc', 'expense']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['etc', 'expense', 'etc']);
      // 다음 Tab 은 묶음을 나간다
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);
    });

    testWidgets('막힌 묶음은 누르지도 키로 움직이지도 않는다 · Field 의 막힘 · 오류 · 필수를 받는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final calls = <String>[];
      PChipRadioGroup<String> group({bool? disabled}) =>
          PChipRadioGroup<String>(
            semanticLabel: '거래 종류',
            value: 'a',
            disabled: disabled,
            onChanged: calls.add,
            children: const [
              PChipRadio(value: 'a', label: '지출'),
              PChipRadio(value: 'b', label: '수입'),
            ],
          );
      await tester.pumpWidget(_host(Brightness.light, group(disabled: true)));
      await tester.tap(findText('수입'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, isEmpty);
      // Field 가 막으면 묶음도 막힌다 — 직접 준 값이 이긴다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(label: '거래 종류', disabled: true, child: group()),
        ),
      );
      await tester.tap(findText('수입'));
      expect(calls, isEmpty);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(label: '거래 종류', disabled: true, child: group(disabled: false)),
        ),
      );
      await tester.tap(findText('수입'));
      expect(calls, ['b']);
      semantics.dispose();
    });
  });

  group('읽는 말', () {
    testWidgets(
      '버튼 칩은 버튼 — 글이 이름이고, 아이콘만 있는 칩은 쓰는 쪽이 준 이름이다(aria-pressed 는 쓰지 않는다)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Brightness.light,
            Row(
              children: [
                PChip(
                  label: '식비 외 2개',
                  selected: true,
                  suffixIcon: LucideIcons.chevronDown,
                  onPressed: () {},
                ),
                PChip.icon(
                  icon: LucideIcons.rotateCcw,
                  semanticLabel: '필터 지우기',
                  onPressed: () {},
                ),
                const PChip(label: '막힘', onPressed: null),
              ],
            ),
            width: 600,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('식비 외 2개')),
          isSemantics(
            label: '식비 외 2개',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            // 고른 모습은 모습일 뿐 — 읽는 상태가 없다
            hasSelectedState: false,
            hasToggledState: false,
            hasCheckedState: false,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('필터 지우기')),
          isSemantics(label: '필터 지우기', isButton: true, hasTapAction: true),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('막힘')),
          isSemantics(
            label: '막힘',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
        semantics.dispose();
      },
    );

    testWidgets('여럿 고르기는 체크박스, 하나 고르기는 이름 있는 라디오 묶음 속 라디오다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: [
              PChipToggle(label: '당일', checked: true, onChanged: (_) {}),
              PChipToggle(label: '1일 전', checked: false, onChanged: (_) {}),
              PChipRadioGroup<String>(
                semanticLabel: '거래 종류',
                value: 'a',
                onChanged: (_) {},
                children: const [
                  PChipRadio(value: 'a', label: '지출'),
                  PChipRadio(value: 'b', label: '수입'),
                ],
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('당일')),
        isSemantics(
          label: '당일',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('1일 전')),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
        ),
      );
      final group = tester.getSemantics(find.bySemanticsLabel('거래 종류'));
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      expect(
        tester.getSemantics(find.bySemanticsLabel('지출')),
        isSemantics(
          label: '지출',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('수입')),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('움직임', () {
    testWidgets('누르면 칩 전체가 2px 거리 준다 — 자리는 그대로, 모션 줄이기면 줄지 않는다', (
      tester,
    ) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PChip(label: '긴 글이 들어가는 칩입니다', onPressed: () {}),
            reduceMotion: reduce,
          ),
        );
        final rect = tester.getRect(_box);
        final before = _paintedScale(tester, _box);
        final g = await tester.startGesture(rect.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // 자리는 그대로 — 가운데가 같다(그려진 사각형은 줄어든다)
        expect(
          (tester.getRect(_box).center - rect.center).distance,
          lessThan(0.01),
        );
        // 기준 max(36, 폭 ÷ 4, 24) — 폭이 144 보다 넓으면 폭 ÷ 4 가 기준이다
        final basis = math.max(rect.height, math.max(rect.width / 4, 24));
        expect(
          _paintedScale(tester, _box) / before,
          closeTo(reduce ? 1 : (basis - 2) / basis, 1e-3),
          reason: 'reduce=$reduce',
        );
        await g.up();
        await tester.pump(const Duration(milliseconds: 400));
      }
    });

    testWidgets('쓰는 쪽이 값을 바꾸면 색이 150ms 에 따라온다', (tester) async {
      final duration = specMs(
        _spec.resolve({}, 'enabled')['root.transitionDuration'],
      );
      Widget chip(bool on) => _host(
        Brightness.light,
        PChip(label: '기간', selected: on, onPressed: () {}),
      );
      await tester.pumpWidget(chip(false));
      final c = GrooTheme.light().extension<PColors>()!;
      // 안 고른 Outline Weak 는 투명
      expect(_decoration(tester, _box).color!.a, 0);
      await tester.pumpWidget(chip(true));
      await tester.pump(duration ~/ 2);
      final mid = _decoration(tester, _box).color!;
      await tester.pump(duration);
      final end = _decoration(tester, _box).color!;
      expect(sameColor(c.bgNeutralWeak, end), isTrue);
      expect(sameColor(end, mid), isFalse, reason: '반쯤은 아직 도착 전이다');
    });
  });

  testWidgets('견본이 폰 폭 312 에서 넘침 없이 그려진다', (tester) async {
    for (final mode in Brightness.values) {
      await tester.pumpWidget(
        _host(mode, const SingleChildScrollView(child: ChipDemo()), width: 312),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: mode.name);
    }
  });
}
