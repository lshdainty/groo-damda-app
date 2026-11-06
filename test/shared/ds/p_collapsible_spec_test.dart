// Collapsible 이 스펙 값(test/fixtures/design_spec/collapsible.json)대로인지 — 놓인 면 × 펼침 × 설명 × 펼친 내용을 라이트 · 다크로
// 돌며 트리거 · 글 · 꺾쇠 · 펼친 내용 여백 · 카드 면 · 경고 상자 아래 선을 재고, 누름 · 막힘 · 모션 · 접근성을 따로 본다.
// 올림(hovered)과 키보드 포커스 링은 웹 전용이라 건너뛴다. 경고 상자(box)는 화면이 그리는 것이라 이 위젯이 재지 않는다.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/collapsible/p_collapsible.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('collapsible');

Widget _host(Brightness mode, Widget child, {bool reduceMotion = false}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Builder(
            builder: (context) => ColoredBox(
              color: context.colors.bgLayerDefault,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 390, child: child),
              ),
            ),
          ),
        ),
      ),
    );

Finder _key(String k) => find.byKey(ValueKey(k));

const _surfaces = {
  'default': PCollapsibleSurface.standard,
  'card': PCollapsibleSurface.card,
  'warning': PCollapsibleSurface.warning,
};

PCollapsible _collapsible({
  required PCollapsibleSurface surface,
  required bool open,
  required bool shown,
  required PCollapsibleLayout layout,
  bool disabled = false,
  String title = '분할 내역',
  Widget? child,
}) => PCollapsible(
  key: UniqueKey(),
  surface: surface,
  layout: layout,
  defaultOpen: open,
  disabled: disabled,
  title: title,
  description: shown ? '합계 123,456원' : null,
  child: child ?? const SizedBox(height: 40, child: Text('내용')),
);

void _near(List<String> failures, String what, num want, double got) {
  if ((got - want).abs() > 0.51) failures.add('$what: 스펙 $want · 실제 $got');
}

void _expectText(
  List<String> failures,
  String where,
  TextStyle style,
  Map<String, Object?> want,
  String slot,
  Brightness mode,
) {
  final typo = (want['$slot.typography'] as Map).cast<String, dynamic>();
  if (style.fontSize != typo['fontSize']) {
    failures.add(
      '$where — $slot 크기: 스펙 ${typo['fontSize']} · 실제 ${style.fontSize}',
    );
  }
  final line = style.fontSize! * style.height!;
  if ((line - (typo['lineHeight'] as num)).abs() > 0.6) {
    failures.add('$where — $slot 줄 높이: 스펙 ${typo['lineHeight']} · 실제 $line');
  }
  final w = want['$slot.fontWeight'] ?? typo['fontWeight'];
  if (style.fontWeight?.value != w) {
    failures.add('$where — $slot 굵기: 스펙 $w · 실제 ${style.fontWeight?.value}');
  }
  final fg = want['$slot.foreground'];
  if (fg != null && !sameColor(specColor(pickMode(fg, mode)), style.color!)) {
    failures.add('$where — $slot 색');
  }
}

void main() {
  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 놓인 면 × 펼침 × 설명 × 펼친 내용마다 스펙 값이다', (
      tester,
    ) async {
      final failures = <String>[];
      for (final combo in _spec.combos([
        'surface',
        'open',
        'description',
        'layout',
      ])) {
        final surface = _surfaces[combo['surface']]!;
        final open = combo['open'] == 'expanded';
        final shown = combo['description'] == 'shown';
        final layout = PCollapsibleLayout.values.byName(combo['layout']!);
        final want = _spec.resolve(combo, 'enabled');
        final where = '${mode.name} $combo';
        await tester.pumpWidget(
          _host(
            mode,
            _collapsible(
              surface: surface,
              open: open,
              shown: shown,
              layout: layout,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final trigger = tester.getRect(_key('pdisc-trigger'));
        _near(
          failures,
          '$where — 줄 높이',
          want['trigger.minHeight']! as num,
          trigger.height,
        );
        final title = _key('pdisc-title');
        final titleRect = tester.getRect(title);
        _near(
          failures,
          '$where — 왼쪽 여백',
          want['trigger.paddingX']! as num,
          titleRect.left - trigger.left,
        );
        _near(
          failures,
          '$where — 위 여백',
          want['trigger.paddingY']! as num,
          titleRect.top - trigger.top,
        );
        _expectText(
          failures,
          where,
          tester.widget<Text>(title).style!,
          want,
          'title',
          mode,
        );
        if (shown) {
          _near(
            failures,
            '$where — 이름 ↔ 설명',
            want['body.gap']! as num,
            tester.getRect(_key('pdisc-description')).top - titleRect.bottom,
          );
          _expectText(
            failures,
            where,
            tester.widget<Text>(_key('pdisc-description')).style!,
            want,
            'description',
            mode,
          );
        }
        final chevron = _key('pdisc-chevron');
        final icon = tester.widget<Icon>(
          find.descendant(of: chevron, matching: find.byType(Icon)),
        );
        _near(
          failures,
          '$where — 꺾쇠 크기',
          want['chevron.size']! as num,
          icon.size!,
        );
        if (!sameColor(
          specColor(pickMode(want['chevron.color'], mode)),
          icon.color!,
        )) {
          failures.add('$where — 꺾쇠 색');
        }
        _near(
          failures,
          '$where — 꺾쇠 오른쪽 여백',
          want['trigger.paddingX']! as num,
          trigger.right - tester.getRect(chevron).right,
        );
        final turns = tester.widget<AnimatedRotation>(chevron).turns;
        if (turns != ('${want['chevron.rotate']}' == '180deg' ? 0.5 : 0.0)) {
          failures.add('$where — 꺾쇠 회전 $turns');
        }
        final bg =
            tester.widget<DecoratedBox>(_key('pdisc-background')).decoration
                as BoxDecoration;
        if (!sameColor(specColor(want['background.background']), bg.color!)) {
          failures.add('$where — 바탕 색');
        }

        // 펼친 내용 — 좌우는 트리거와 같고 아래는 글 16 · 줄 8 · 카드 24
        final panel = _key('pcollapsible-panel');
        if (open) {
          final pad = tester.widget<Padding>(panel).padding as EdgeInsets;
          _near(
            failures,
            '$where — panel.paddingTop',
            want['panel.paddingTop']! as num,
            pad.top,
          );
          _near(
            failures,
            '$where — panel.paddingBottom',
            want['panel.paddingBottom']! as num,
            pad.bottom,
          );
          _near(
            failures,
            '$where — panel.paddingX',
            want['panel.paddingX']! as num,
            pad.left,
          );
          _near(
            failures,
            '$where — panel.paddingX(오른쪽)',
            want['panel.paddingX']! as num,
            pad.right,
          );
          _near(
            failures,
            '$where — 내용 시작',
            want['panel.paddingX']! as num,
            tester.getRect(findText('내용')).left - trigger.left,
          );
        } else {
          expect(panel, findsNothing, reason: '$where — 접힌 내용은 그리지 않는다');
        }

        // 면
        if (surface == PCollapsibleSurface.card) {
          final deco =
              tester.widget<DecoratedBox>(_key('pcollapsible-card')).decoration
                  as BoxDecoration;
          if (!sameColor(
            specColor(pickMode(want['root.background'], mode)),
            deco.color!,
          )) {
            failures.add('$where — 카드 바탕');
          }
          final border = deco.border! as Border;
          _near(
            failures,
            '$where — root.borderWidth',
            want['root.borderWidth']! as num,
            border.top.width,
          );
          if (!sameColor(
            specColor(pickMode(want['root.borderColor'], mode)),
            border.top.color,
          )) {
            failures.add('$where — 카드 테두리 색');
          }
          _near(
            failures,
            '$where — root.radius',
            want['root.radius']! as num,
            (deco.borderRadius! as BorderRadius).topLeft.x,
          );
        } else {
          expect(_key('pcollapsible-card'), findsNothing, reason: where);
        }
        if (surface == PCollapsibleSurface.warning) {
          final div = _key('pcollapsible-divider');
          _near(
            failures,
            '$where — 선 두께',
            want['divider.height']! as num,
            tester.getSize(div).height,
          );
          final fill = tester
              .widget<ColoredBox>(
                find.descendant(of: div, matching: find.byType(ColoredBox)),
              )
              .color;
          if (!sameColor(
            specColor(pickMode(want['divider.background'], mode)),
            fill,
          )) {
            failures.add('$where — 선 색');
          }
          // 트리거 위 — 상자 폭 끝까지
          _near(
            failures,
            '$where — 선이 트리거 위',
            0,
            tester.getRect(div).bottom - trigger.top,
          );
          _near(failures, '$where — 선 폭', 390, tester.getSize(div).width);
        } else {
          expect(_key('pcollapsible-divider'), findsNothing, reason: where);
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('${mode.name} — 누름(pressed) 바탕 색 · 들임 · 축소가 면마다 스펙 값이다', (
      tester,
    ) async {
      final failures = <String>[];
      for (final combo in _spec.combos(['surface'])) {
        final surface = _surfaces[combo['surface']]!;
        final want = _spec.resolve(combo, 'pressed');
        final where = '${mode.name} $combo';
        await tester.pumpWidget(
          _host(
            mode,
            _collapsible(
              surface: surface,
              open: false,
              shown: false,
              layout: PCollapsibleLayout.text,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final rect = tester.getRect(_key('pdisc-trigger'));
        final g = await tester.startGesture(rect.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final bg =
            tester.widget<DecoratedBox>(_key('pdisc-background')).decoration
                as BoxDecoration;
        if (!sameColor(
          specColor(pickMode(want['background.background'], mode)),
          bg.color!,
        )) {
          failures.add(
            '$where — 누름 바탕 색: 스펙 ${pickMode(want['background.background'], mode)} · 실제 ${colorHex(bg.color!)}',
          );
        }
        _near(
          failures,
          '$where — 바탕 좌우 들임',
          want['background.insetX']! as num,
          tester.getRect(_key('pdisc-background')).left - rect.left,
        );
        _near(
          failures,
          '$where — 바탕 모서리',
          want['background.radius']! as num,
          (bg.borderRadius! as BorderRadius).topLeft.x,
        );
        final basis = [
          rect.height,
          rect.width / 4,
          24.0,
        ].reduce((a, b) => a > b ? a : b);
        final scale = tester.widget<AnimatedScale>(_key('pdisc-content')).scale;
        if ((scale - (basis - 2) / basis).abs() > 1e-6) {
          failures.add('$where — 축소 $scale');
        }
        await g.up();
        await tester.pumpAndSettle();
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets(
      '${mode.name} — 막힘(disabled)은 제목 · 설명 · 꺾쇠가 fg-disabled 이고 눌러도 열리지 않는다',
      (tester) async {
        final handle = tester.ensureSemantics();
        final failures = <String>[];
        for (final combo in _spec.combos(['surface'])) {
          final surface = _surfaces[combo['surface']]!;
          final want = _spec.resolve({
            ...combo,
            'description': 'shown',
          }, 'disabled');
          final where = '${mode.name} $combo';
          await tester.pumpWidget(
            _host(
              mode,
              _collapsible(
                surface: surface,
                open: false,
                shown: true,
                layout: PCollapsibleLayout.text,
                disabled: true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final k in ['title', 'description']) {
            final style = tester.widget<Text>(_key('pdisc-$k')).style!;
            if (!sameColor(
              specColor(pickMode(want['$k.foreground'], mode)),
              style.color!,
            )) {
              failures.add('$where — $k 색');
            }
          }
          final icon = tester.widget<Icon>(
            find.descendant(
              of: _key('pdisc-chevron'),
              matching: find.byType(Icon),
            ),
          );
          if (!sameColor(
            specColor(pickMode(want['chevron.color'], mode)),
            icon.color!,
          )) {
            failures.add('$where — 꺾쇠 색');
          }
          expect(
            find.descendant(
              of: _key('pdisc-trigger'),
              matching: find.byType(Opacity),
            ),
            findsNothing,
          );
          await tester.tap(_key('pdisc-trigger'));
          await tester.pumpAndSettle();
          expect(_key('pcollapsible-panel'), findsNothing, reason: where);
          final node = tester.getSemantics(
            find.bySemanticsLabel(RegExp('분할 내역')).first,
          );
          expect(
            node.getSemanticsData().flagsCollection.isEnabled,
            Tristate.isFalse,
            reason: where,
          );
        }
        handle.dispose();
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );
  }

  group('모션', () {
    final motion = _spec.json['motion'] as Map<String, dynamic>;

    testWidgets('시간 · 곡선이 스펙 값이다', (tester) async {
      final open = motion['펼침 · 접힘 — 높이'] as Map<String, dynamic>;
      expect(specMs(open['duration']), PDuration.d6);
      expect(specCubic(open['easing']), [0.35, 0.0, 0.35, 1.0]);
      expect(
        specMs((motion['모션 줄이기 — 펼침 · 접힘'] as Map)['duration']),
        PDuration.d3,
      );
      expect(specMs((motion['꺾쇠 — 회전'] as Map)['duration']), PDuration.d6);
      expect(
        specMs((motion['누름 · 호버 — 바탕'] as Map)['duration']),
        PDuration.colorTransition,
      );
      expect(
        specMs((motion['누름 — 콘텐츠'] as Map)['duration']),
        PDuration.pressedScale,
      );
    });

    testWidgets('펼침은 높이 300ms · 꺾쇠 300ms, 모션 줄이기면 150ms 서서히 · 꺾쇠는 바로', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _collapsible(
            surface: PCollapsibleSurface.standard,
            open: false,
            shown: false,
            layout: PCollapsibleLayout.text,
          ),
        ),
      );
      await tester.tap(_key('pdisc-trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final natural = tester.getSize(_key('pcollapsible-panel')).height;
      final mid = tester.getSize(_key('pcollapsible-panel-clip')).height;
      expect(mid, inExclusiveRange(0, natural));
      expect(
        tester.widget<AnimatedRotation>(_key('pdisc-chevron')).duration,
        PDuration.d6,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(_key('pcollapsible-panel-clip')).height, natural);

      await tester.pumpWidget(
        _host(
          Brightness.light,
          _collapsible(
            surface: PCollapsibleSurface.standard,
            open: false,
            shown: false,
            layout: PCollapsibleLayout.text,
          ),
          reduceMotion: true,
        ),
      );
      await tester.tap(_key('pdisc-trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(_key('pcollapsible-panel-clip'), findsNothing);
      expect(
        tester.widget<Opacity>(_key('pcollapsible-panel-fade')).opacity,
        inExclusiveRange(0, 1),
      );
      expect(
        tester.widget<AnimatedRotation>(_key('pdisc-chevron')).duration,
        Duration.zero,
      );
      await tester.pumpAndSettle();
    });
  });

  group('동작 · 접근성', () {
    testWidgets('이름은 고정, 펼침은 expanded, 설명은 이름 뒤에 함께 읽힌다 · 접힌 내용은 읽지 않는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _collapsible(
            surface: PCollapsibleSurface.standard,
            open: false,
            shown: true,
            layout: PCollapsibleLayout.text,
          ),
        ),
      );
      final finder = find.bySemanticsLabel(RegExp('^분할 내역\n'));
      var data = tester.getSemantics(finder).getSemanticsData();
      expect(data.label, '분할 내역\n합계 123,456원');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      expect(find.bySemanticsLabel('내용'), findsNothing);
      await tester.tap(_key('pdisc-trigger'));
      await tester.pumpAndSettle();
      data = tester.getSemantics(finder).getSemanticsData();
      expect(data.label, '분할 내역\n합계 123,456원', reason: '이름은 상태마다 바꾸지 않는다');
      expect(data.flagsCollection.isExpanded, Tristate.isTrue);
      expect(find.bySemanticsLabel('내용'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('open · onOpenChange 로 쥐고 다룬다 — 안 바꿔 주면 그대로다', (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCollapsible(
            open: false,
            onOpenChange: seen.add,
            title: '내역 분할',
            child: const Text('내용'),
          ),
        ),
      );
      await tester.tap(findText(keepAll('내역 분할')));
      await tester.pumpAndSettle();
      expect(seen, [true]);
      expect(findText('내용'), findsNothing);
    });

    testWidgets('Enter · Space 로 열고 닫는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _collapsible(
            surface: PCollapsibleSurface.standard,
            open: false,
            shown: false,
            layout: PCollapsibleLayout.text,
          ),
        ),
      );
      Focus.of(tester.element(_key('pdisc-trigger'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(findText('내용'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(findText('내용'), findsNothing);
    });
  });

  testWidgets('가장 나쁜 값 — 긴 이름 · 긴 설명 · 펼친 채 늘어나는 내용이 폰 폭 360 에서 넘치지 않는다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const longTitle =
        '연회비 · 카드 발급 후 첫 달 실적 기준으로 산정하며 전월 이용 실적이 기준에 못 미치면 청구 할인이 적용되지 않아요';
    for (final mode in Brightness.values) {
      for (final surface in PCollapsibleSurface.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: mode == Brightness.dark
                ? GrooTheme.dark()
                : GrooTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: PCollapsible(
                  surface: surface,
                  defaultOpen: true,
                  title: longTitle,
                  description: '$longTitle 합계 1,234,567,890원',
                  child: Text('내용 ' * 200),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${mode.name} ${surface.name}',
        );
        final trigger = tester.getRect(_key('pdisc-trigger'));
        final title = tester.getRect(_key('pdisc-title'));
        expect(title.height, greaterThan(22 * 2 - 1));
        final pad = surface == PCollapsibleSurface.warning ? 16.0 : 24.0;
        expect(title.left - trigger.left, pad);
        expect(
          trigger.bottom - tester.getRect(_key('pdisc-description')).bottom,
          16,
          reason: '아래 여백',
        );
      }
    }
  });
}
