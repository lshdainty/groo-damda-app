// Button 이 스펙 값(test/fixtures/design_spec/button.json)대로 그려지는지 — 변형 × 크기 × 배치(ghost 는 글자색까지)
// × 상태 × 라이트 · 다크를 모두 돈다. 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱에 없는 상태(웹의 hovered · focused)와 문장으로 된 값(커서 · 모션 · "세로 2px 축소")은 재지 않는다 —
// 누름 축소 · 누르는 영역 · 로딩의 누르기 막기 · 누른 동작이 끝날 때까지 한 번은 아래의 동작 테스트가 본다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('button');

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: Center(child: child)),
);

PButton _button(Map<String, String> combo, String state, {VoidCallback? tap}) {
  final variant = PButtonVariant.values.byName(combo['variant']!);
  final size = PButtonSize.values.byName(combo['size']!);
  final ghostColor = PButtonGhostColor.values.byName(
    combo['ghostColor'] ?? 'neutral',
  );
  final onPressed = state == 'disabled' ? null : (tap ?? () {});
  final loading = state == 'loading';
  return combo['layout'] == 'iconOnly'
      ? PButton.icon(
          icon: LucideIcons.plus,
          semanticLabel: '추가',
          onPressed: onPressed,
          variant: variant,
          size: size,
          ghostColor: ghostColor,
          loading: loading,
        )
      : PButton(
          label: '추가',
          prefixIcon: LucideIcons.plus,
          onPressed: onPressed,
          variant: variant,
          size: size,
          ghostColor: ghostColor,
          loading: loading,
        );
}

/// 한 조합 · 상태 · 모드를 그려 스펙 값과 맞춘다. 다른 값은 [failures] 에 모은다.
Future<void> _check(
  WidgetTester tester,
  Brightness mode,
  Map<String, String> combo,
  String state,
  List<String> failures,
) async {
  await tester.pumpWidget(
    _host(mode, KeyedSubtree(key: UniqueKey(), child: _button(combo, state))),
  );
  TestGesture? gesture;
  if (state == 'pressed') {
    gesture = await tester.startGesture(tester.getCenter(find.byType(PButton)));
    // 누른 프레임 — 여기서 색 전환이 시작된다
    await tester.pump();
  }
  // 색 전환(150ms) · 누름 축소가 끝나게 — 로딩 원은 계속 돌아 settle 하지 않는다
  await tester.pump(const Duration(milliseconds: 400));

  final want = _spec.resolve(combo, state);
  final where = '${mode.name} $combo $state';
  void px(String key, double actual) {
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      failures.add('$where — $key: 스펙 $w · 실제 $actual');
    }
  }

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return;
    if (!sameColor(specColor(w), actual)) {
      failures.add('$where — $key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  final box = find.descendant(
    of: find.byType(PButton),
    matching: find.byType(Container),
  );
  final deco =
      tester
              .widget<DecoratedBox>(
                find
                    .descendant(of: box, matching: find.byType(DecoratedBox))
                    .last,
              )
              .decoration
          as BoxDecoration;
  final size = tester.getSize(box);
  final iconOnly = combo['layout'] == 'iconOnly';

  // 상자
  px('root.height', size.height);
  if (iconOnly) px('root.width', size.width);
  px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
  color('root.background', deco.color ?? const Color(0x00000000));
  // 테두리는 여백을 늘리지 않게 안쪽에 덧그린다(foregroundDecoration) — 높이가 최소 높이 그대로다
  final foreground = tester.widget<Container>(box.first).foregroundDecoration;
  final borderDeco = foreground as BoxDecoration?;
  if (deco.border != null) {
    failures.add('$where — 테두리를 바탕 장식에 두면 여백이 늘어 높이가 커진다');
  }
  if (want.containsKey('root.borderColor')) {
    final border = borderDeco?.border as Border?;
    if (border == null) {
      failures.add('$where — root.borderColor: 테두리가 없다');
    } else {
      color('root.borderColor', border.top.color);
      px('root.borderWidth', border.top.width);
    }
  } else if (borderDeco != null) {
    failures.add('$where — 스펙에 없는 테두리가 있다');
  }
  final padding =
      tester
              .widget<Padding>(
                find.descendant(of: box, matching: find.byType(Padding)).first,
              )
              .padding
          as EdgeInsets;
  // 테두리가 있으면 가로 여백에 1씩 더해져 있다(웹 border-box 와 같은 폭) — 뺀 값이 스펙 paddingX
  final borderW = borderDeco?.border == null ? 0 : 1;
  px('root.paddingX', padding.left - borderW);
  px('root.paddingY', padding.top);
  px('root.padding', padding.top);

  // 글자 · 아이콘
  final icon = tester.widget<Icon>(
    find.descendant(of: box, matching: find.byType(Icon)),
  );
  px(iconOnly ? 'icon.size' : 'prefixIcon.size', icon.size!);
  if (!iconOnly) {
    final text = tester.widget<Text>(
      find.descendant(of: box, matching: find.byType(Text)),
    );
    final style = text.style!;
    final typo = want['label.typography'] as Map<String, dynamic>?;
    if (typo != null) {
      px('label.typography', style.fontSize!);
      final lineHeight = style.fontSize! * style.height!;
      if (((typo['lineHeight'] as num) - lineHeight).abs() > 0.5) {
        failures.add(
          '$where — label.typography 줄 높이: 스펙 ${typo['lineHeight']} · 실제 $lineHeight',
        );
      }
      if (((typo['fontSize'] as num) - style.fontSize!).abs() > 0.5) {
        failures.add(
          '$where — label.typography 크기: 스펙 ${typo['fontSize']} · 실제 ${style.fontSize}',
        );
      }
    }
    if (style.fontWeight?.value != want['label.fontWeight']) {
      failures.add(
        '$where — label.fontWeight: 스펙 ${want['label.fontWeight']} · 실제 ${style.fontWeight}',
      );
    }
    px(
      'root.gap',
      tester
          .widget<Row>(find.descendant(of: box, matching: find.byType(Row)))
          .spacing,
    );
    if (want['label.color'] != 'transparent') {
      color('root.foreground', style.color!);
    }
  }
  if (want['label.color'] != 'transparent') {
    color('root.foreground', icon.color!);
  }

  // 로딩 — 글자 · 아이콘은 투명하게(자리는 그대로), 그 위에 로딩 원
  final circle = find.descendant(
    of: box,
    matching: find.byType(PProgressCircle),
  );
  if (state == 'loading') {
    final hidden = find.ancestor(
      of: find.byType(Icon),
      matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0),
    );
    if (hidden.evaluate().isEmpty) {
      failures.add('$where — label.color: 글자 · 아이콘이 투명하지 않다');
    }
    if (circle.evaluate().isEmpty) {
      failures.add('$where — 로딩 원이 없다');
    } else {
      final c = tester.widget<PProgressCircle>(circle);
      px('progressCircle.size', c.diameter!);
      px('progressCircle.thickness', c.thickness!);
      color('progressCircle.track', c.trackColor!);
      color('progressCircle.range', c.rangeColor!);
    }
  } else if (circle.evaluate().isNotEmpty) {
    failures.add('$where — 로딩이 아닌데 로딩 원이 있다');
  }

  await gesture?.up();
}

void main() {
  const states = ['enabled', 'pressed', 'loading', 'disabled'];
  final layouts = _spec.combos(['variant', 'size', 'layout']);

  for (final mode in Brightness.values) {
    for (final variant in _spec.axes['variant']!) {
      testWidgets('${mode.name} · $variant — 크기 × 배치 × 상태가 스펙 값이다', (
        tester,
      ) async {
        final failures = <String>[];
        final combos = [
          for (final c in layouts.where((c) => c['variant'] == variant))
            if (variant == 'ghost')
              for (final g in _spec.axes['ghostColor']!) {...c, 'ghostColor': g}
            else
              c,
        ];
        for (final combo in combos) {
          for (final state in states) {
            await _check(tester, mode, combo, state, failures);
          }
        }
        if (failures.isNotEmpty) {
          fail('${failures.length}개가 스펙과 다르다\n${failures.take(20).join('\n')}');
        }
      });
    }
  }

  for (final mode in [Brightness.light, Brightness.dark]) {
    testWidgets(
      '${mode.name} — 로딩이 막힘보다 먼저다: 저장 중 onPressed 를 비워도 누름 색 위 진행 원(비활성 색 아님)',
      (tester) async {
        Future<Color?> bgOf(PButton b) async {
          await tester.pumpWidget(
            _host(mode, KeyedSubtree(key: UniqueKey(), child: b)),
          );
          await tester.pump(const Duration(milliseconds: 400));
          final box = find.descendant(
            of: find.byType(PButton),
            matching: find.byType(Container),
          );
          return (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: box,
                              matching: find.byType(DecoratedBox),
                            )
                            .last,
                      )
                      .decoration
                  as BoxDecoration)
              .color;
        }

        for (final variant in PButtonVariant.values) {
          final withTap = await bgOf(
            PButton(
              label: '저장',
              variant: variant,
              loading: true,
              onPressed: () {},
            ),
          );
          final noTap = await bgOf(
            PButton(
              label: '저장',
              variant: variant,
              loading: true,
              onPressed: null,
            ),
          );
          final disabled = await bgOf(
            PButton(label: '저장', variant: variant, onPressed: null),
          );
          expect(noTap, withTap, reason: '$variant — 로딩 색');
          // 바탕을 칠하는 변형만 — 테두리 · ghost 는 로딩 · 비활성 모두 바탕이 없다(button.yaml)
          if (!{
            PButtonVariant.ghost,
            PButtonVariant.brandOutline,
            PButtonVariant.neutralOutline,
          }.contains(variant)) {
            expect(noTap == disabled, isFalse, reason: '$variant — 비활성 색이 아니다');
          }
        }
      },
    );
  }

  testWidgets('로딩이면 누르기를 삼킨다 — 두 번 제출 방지', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Brightness.light,
        PButton(label: '저장', loading: true, onPressed: () => taps++),
      ),
    );
    await tester.tap(find.byType(PButton));
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 0);
  });

  testWidgets('누른 동작이 끝날 때까지 한 번 — Future 가 끝나기 전의 누름은 버리고 끝나면 다시 누른다', (
    tester,
  ) async {
    var calls = 0;
    final done = Completer<void>();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        PButton(
          label: '저장',
          onPressed: () {
            calls++;
            return done.future;
          },
        ),
      ),
    );
    await tester.tap(find.byType(PButton));
    await tester.tap(find.byType(PButton));
    await tester.tap(find.byType(PButton));
    expect(calls, 1);

    done.complete();
    await tester.pump();
    await tester.tap(find.byType(PButton));
    expect(calls, 2);
  });

  testWidgets('Future 가 거부돼도 잠금은 풀린다 — 거부는 삼키지 않고 그대로 넘어간다', (tester) async {
    var calls = 0;
    final failed = Completer<void>();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        PButton(
          label: '저장',
          onPressed: () {
            calls++;
            // 잡지 않은 오류가 되지 않게 이 테스트가 직접 받는다 — 위젯은 거부를 그대로 넘긴다
            return failed.future.catchError((_) {});
          },
        ),
      ),
    );
    await tester.tap(find.byType(PButton));
    await tester.tap(find.byType(PButton));
    expect(calls, 1);

    failed.completeError(StateError('저장 실패'));
    await tester.pump();
    await tester.tap(find.byType(PButton));
    expect(calls, 2);
  });

  testWidgets('Future 를 돌려주지 않으면 잠그지 않는다 — 연달아 눌러도 그때마다 불린다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(Brightness.light, PButton(label: '저장', onPressed: () => calls++)),
    );
    await tester.tap(find.byType(PButton));
    await tester.tap(find.byType(PButton));
    expect(calls, 2);
  });

  testWidgets('비활성이면 누르지 않고, 활성이면 한 번 누른다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(Brightness.light, PButton(label: '저장', onPressed: () => taps++)),
    );
    await tester.tap(find.byType(PButton));
    expect(taps, 1);
    await tester.pumpWidget(
      _host(Brightness.light, const PButton(label: '저장', onPressed: null)),
    );
    await tester.tap(find.byType(PButton), warnIfMissed: false);
    expect(taps, 1);
  });

  testWidgets('누르는 영역은 보이는 크기와 따로 44 까지 — xsmall(32) 의 위아래 6px 밖도 받는다', (
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
            child: PButton(
              label: '저장',
              size: PButtonSize.xsmall,
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(PButton));
    expect(rect.height, 32);
    await tester.tapAt(Offset(rect.center.dx, rect.top - 5));
    await tester.tapAt(Offset(rect.center.dx, rect.bottom + 5));
    expect(taps, 2);
    // 44 밖은 받지 않는다
    await tester.tapAt(Offset(rect.center.dx, rect.top - 8));
    expect(taps, 2);
  });

  testWidgets('누르면 세로 2px 거리만큼 줄어든다 — 배율 (기준 − 2) ÷ 기준', (tester) async {
    await tester.pumpWidget(
      _host(Brightness.light, PButton(label: '저장', onPressed: () {})),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    // medium 40 — 폭 ÷ 4 가 40 보다 작으니 기준은 높이
    final width = tester.getSize(find.byType(PButton)).width;
    final basis = [40.0, width / 4, 24.0].reduce((a, b) => a > b ? a : b);
    expect(scale.scale, closeTo((basis - 2) / basis, 1e-9));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('모션 줄이기면 누름 축소가 없다', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(Brightness.light, PButton(label: '저장', onPressed: () {})),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PButton)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
  });

  testWidgets('아이콘만 있는 버튼은 이름을 읽고, 로딩이면 바쁘다고 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        PButton.icon(
          icon: LucideIcons.plus,
          semanticLabel: '거래 추가',
          loading: true,
          onPressed: () {},
        ),
      ),
    );
    expect(
      // 누르는 영역 상자가 가장 바깥이라, 버튼의 의미 노드는 그 안에 있다
      tester.getSemantics(find.bySemanticsLabel('거래 추가')),
      matchesSemantics(
        label: '거래 추가',
        value: '불러오는 중',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    semantics.dispose();
  });

  group('큰 글자 — 높이는 최소 높이다(사용자 결정 2026-10-22)', () {
    Widget scaled(double factor, Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(factor)),
        child: child,
      ),
    );

    // 100% 는 36 · 40 · 48 그대로, 130% 는 글 줄 × 1.3 이 더해지고, 200% 는 small 54 · medium 58 · large 72 다
    const heights = {
      PButtonSize.small: [36.0, 54.0],
      PButtonSize.medium: [40.0, 58.0],
      PButtonSize.large: [48.0, 72.0],
    };
    for (final variant in [
      PButtonVariant.brandSolid,
      PButtonVariant.neutralOutline,
    ]) {
      testWidgets(
        '${variant.name} — 글자 100% · 200% 에서 상자가 글을 따라 늘어나고 글은 잘리지 않는다',
        (tester) async {
          for (final e in heights.entries) {
            for (var i = 0; i < 2; i++) {
              final factor = i == 0 ? 1.0 : 2.0;
              await tester.pumpWidget(
                _host(
                  Brightness.light,
                  scaled(
                    factor,
                    PButton(
                      label: '다시 시도',
                      variant: variant,
                      size: e.key,
                      onPressed: () {},
                    ),
                  ),
                ),
              );
              final box = tester.getSize(
                find.descendant(
                  of: find.byType(PButton),
                  matching: find.byType(Container),
                ),
              );
              expect(
                box.height,
                closeTo(e.value[i], 0.01),
                reason: '${e.key.name} × $factor',
              );
              expect(tester.takeException(), isNull);
            }
          }
        },
      );
    }

    testWidgets('아이콘만 있는 버튼은 글자가 커져도 정사각 그대로다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          scaled(
            2,
            PButton.icon(
              icon: LucideIcons.plus,
              semanticLabel: '추가',
              onPressed: () {},
            ),
          ),
        ),
      );
      final size = tester.getSize(
        find.descendant(
          of: find.byType(PButton),
          matching: find.byType(Container),
        ),
      );
      expect(size.width, size.height);
      expect(size.height, 40);
    });
  });

  testWidgets('윤곽 버튼은 채움 버튼보다 2px 넓다(테두리 1px × 2 — 웹 border-box 와 같은 폭)', (
    tester,
  ) async {
    Future<double> width(PButtonVariant v) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Align(
            alignment: Alignment.topLeft,
            child: PButton(label: '취소', variant: v, onPressed: () {}),
          ),
        ),
      );
      return tester
          .getSize(
            find.descendant(
              of: find.byType(PButton),
              matching: find.byType(Container),
            ),
          )
          .width;
    }

    final solid = await width(PButtonVariant.neutralWeak);
    final outline = await width(PButtonVariant.neutralOutline);
    expect(outline - solid, 2);
  });

  testWidgets(
    '라벨 두 줄(labelLines 2) — 글에 넣은 줄바꿈에서만 바뀌고 버튼이 따라 자란다, 한 줄 버튼은 그대로 36',
    (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PButton(
                label: '2025-01-01 ~\n2026-03-31',
                labelLines: 2,
                size: PButtonSize.small,
                variant: PButtonVariant.neutralOutline,
                suffixIcon: LucideIcons.chevronDown,
                onPressed: () {},
              ),
              const SizedBox(height: 8),
              PButton(
                label: '2026년 10월',
                size: PButtonSize.small,
                variant: PButtonVariant.neutralOutline,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      final sizes = [
        for (final e in find.byType(PButton).evaluate())
          tester.getSize(find.byElementPredicate((x) => x == e)),
      ];
      expect(sizes[0].height, greaterThan(36));
      expect(sizes[1].height, 36);
    },
  );
}
