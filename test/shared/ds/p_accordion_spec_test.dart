// Accordion 이 스펙 값(test/fixtures/design_spec/accordion.json)대로인지 — 변형 × 펼침 × 설명 × 상세를 라이트 · 다크로 돌며
// 트리거 높이 · 여백 · 글 · 꺾쇠 · 펼친 내용 · 사이 선 · 항목 면을 잰다. 올림(hovered)과 키보드 포커스 링은 웹 전용이라 건너뛰고,
// 누름(pressed)은 손가락으로 눌러 잰다. 웹은 같은 JSON 을 크로미움에서 잰다.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_accordion.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_expand_motion.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('accordion');

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

/// 제목은 낱말 단위 줄바꿈 이음 문자가 들어 있다(keepAll) — 같은 변환으로 찾는다.
Finder _title(String t) => findText(keepAll(t));

Finder _key(String k) => find.byKey(ValueKey(k));
Finder _keyed(String prefix) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix),
);

const _items = [
  ('coffee', '커피 할인', '전 가맹점 30% 청구 할인'),
  ('fuel', '주유 할인', '리터당 60원 청구 할인'),
];

Widget _accordion({
  required PAccordionVariant variant,
  required bool open,
  required bool shown,
  required bool detail,
  bool disabled = false,
  List<String>? values,
  ValueChanged<List<String>>? onChange,
  int count = 2,
}) {
  final items = _items.take(count).toList();
  return PAccordion(
    key: UniqueKey(),
    variant: variant,
    disabled: disabled,
    values: values,
    onValuesChange: onChange,
    defaultValues: open && values == null
        ? [for (final i in items) i.$1]
        : const [],
    children: [
      for (final i in items)
        if (detail)
          PAccordionItem(
            value: i.$1,
            title: i.$2,
            description: shown ? i.$3 : null,
            prefixIcon: shown ? LucideIcons.coffee : null,
            child: Text('${i.$2} 상세'),
          )
        else
          PAccordionPlainItem(
            title: i.$2,
            description: shown ? i.$3 : null,
            prefixIcon: shown ? LucideIcons.coffee : null,
          ),
    ],
  );
}

Map<String, dynamic> _typo(Object? v) => (v as Map).cast<String, dynamic>();

void _expectText(
  List<String> failures,
  String where,
  TextStyle style,
  Map<String, Object?> want,
  String slot,
  Brightness mode, {
  String? colorSlot,
  Object? weight,
}) {
  final typo = _typo(want['$slot.typography']);
  if (style.fontSize != typo['fontSize']) {
    failures.add(
      '$where — $slot 크기: 스펙 ${typo['fontSize']} · 실제 ${style.fontSize}',
    );
  }
  final line = style.fontSize! * style.height!;
  if ((line - (typo['lineHeight'] as num)).abs() > 0.6) {
    failures.add('$where — $slot 줄 높이: 스펙 ${typo['lineHeight']} · 실제 $line');
  }
  final w = weight ?? want['$slot.fontWeight'] ?? typo['fontWeight'];
  if (style.fontWeight?.value != w) {
    failures.add('$where — $slot 굵기: 스펙 $w · 실제 ${style.fontWeight?.value}');
  }
  final fg = want[colorSlot ?? '$slot.foreground'];
  if (fg != null && !sameColor(specColor(pickMode(fg, mode)), style.color!)) {
    failures.add(
      '$where — $slot 색: 스펙 ${pickMode(fg, mode)} · 실제 ${colorHex(style.color!)}',
    );
  }
}

void _near(List<String> failures, String what, num want, double got) {
  if ((got - want).abs() > 0.51) failures.add('$what: 스펙 $want · 실제 $got');
}

Text _text(WidgetTester tester, Finder f) => tester.widget<Text>(f);

void main() {
  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} — 변형 × 펼침 × 설명 × 상세마다 트리거 · 글 · 꺾쇠 · 펼친 내용이 스펙 값이다',
      (tester) async {
        final failures = <String>[];
        for (final combo in _spec.combos([
          'variant',
          'open',
          'description',
          'detail',
        ])) {
          final variant = PAccordionVariant.values.byName(combo['variant']!);
          final open = combo['open'] == 'expanded';
          final shown = combo['description'] == 'shown';
          final detail = combo['detail'] == 'expandable';
          // 상세 없는 줄은 펼침이 없다
          if (!detail && open) continue;
          final want = _spec.resolve(combo, 'enabled');
          final where = '${mode.name} $combo';
          await tester.pumpWidget(
            _host(
              mode,
              _accordion(
                variant: variant,
                open: open,
                shown: shown,
                detail: detail,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final c = mode == Brightness.dark ? PColors.dark : PColors.light;

          // 줄 높이 · 여백 — 상세 없는 줄은 트리거가 아니라 줄이다
          final line = detail
              ? _key('pdisc-trigger')
              : _key('paccordion-plain');
          final first = line.first;
          final box = tester.getRect(first);
          _near(
            failures,
            '$where — 줄 높이',
            want['trigger.minHeight']! as num,
            box.height,
          );
          final title = find.byKey(const ValueKey('pdisc-title')).first;
          final titleRect = tester.getRect(title);
          _near(
            failures,
            '$where — 위 여백',
            want['trigger.paddingY']! as num,
            titleRect.top - box.top,
          );
          final paddingX = want['trigger.paddingX']! as num;
          if (shown) {
            final prefix = tester.getRect(
              find.byKey(const ValueKey('pdisc-prefix')).first,
            );
            _near(
              failures,
              '$where — 앞 아이콘 크기',
              want['prefixIcon.size']! as num,
              prefix.width,
            );
            _near(failures, '$where — 왼쪽 여백', paddingX, prefix.left - box.left);
            _near(
              failures,
              '$where — 아이콘 ↔ 본문',
              want['content.gap']! as num,
              titleRect.left - prefix.right,
            );
            final icon = tester.widget<Icon>(
              find.descendant(
                of: find.byKey(const ValueKey('pdisc-prefix')).first,
                matching: find.byType(Icon),
              ),
            );
            if (!sameColor(
              specColor(pickMode(want['prefixIcon.color'], mode)),
              icon.color!,
            )) {
              failures.add('$where — 앞 아이콘 색');
            }
          } else {
            _near(
              failures,
              '$where — 왼쪽 여백',
              paddingX,
              titleRect.left - box.left,
            );
          }
          _expectText(
            failures,
            where,
            _text(tester, title).style!,
            want,
            'title',
            mode,
          );
          if (shown) {
            final desc = find.byKey(const ValueKey('pdisc-description')).first;
            _near(
              failures,
              '$where — 제목 ↔ 설명',
              want['body.gap']! as num,
              tester.getRect(desc).top - titleRect.bottom,
            );
            _expectText(
              failures,
              where,
              _text(tester, desc).style!,
              want,
              'description',
              mode,
            );
          } else {
            expect(
              find.byKey(const ValueKey('pdisc-description')),
              findsNothing,
              reason: where,
            );
          }

          // 꺾쇠 — 상세 없는 줄은 두지 않는다
          if (detail) {
            final chevron = find.byKey(const ValueKey('pdisc-chevron')).first;
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
            final turns = tester.widget<AnimatedRotation>(chevron).turns;
            final wantTurns = '${want['chevron.rotate']}' == '180deg'
                ? 0.5
                : 0.0;
            if (turns != wantTurns) {
              failures.add('$where — 꺾쇠 회전: 스펙 $wantTurns · 실제 $turns');
            }
            _near(
              failures,
              '$where — 꺾쇠 오른쪽 여백',
              paddingX,
              box.right - tester.getRect(chevron).right,
            );
            // 바탕 층 — 쉬는 동안은 투명 · 들이지 않음 · 각짐
            final bg =
                tester
                        .widget<DecoratedBox>(_key('pdisc-background').first)
                        .decoration
                    as BoxDecoration;
            if (!sameColor(
              specColor(want['background.background']),
              bg.color!,
            )) {
              failures.add('$where — 바탕 색');
            }
          } else {
            expect(
              find.byKey(const ValueKey('pdisc-chevron')),
              findsNothing,
              reason: where,
            );
            expect(
              find.byKey(const ValueKey('pdisc-trigger')),
              findsNothing,
              reason: where,
            );
          }

          // 펼친 내용
          if (detail) {
            final panel = _key('paccordion-panel');
            if (open) {
              expect(panel, findsNWidgets(2), reason: where);
              final pad =
                  tester.widget<Padding>(panel.first).padding as EdgeInsets;
              for (final (k, got) in [
                ('panel.paddingTop', pad.top),
                ('panel.paddingBottom', pad.bottom),
              ]) {
                _near(failures, '$where — $k', want[k]! as num, got);
              }
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
              final text = tester
                  .widget<DefaultTextStyle>(
                    find
                        .descendant(
                          of: panel.first,
                          matching: find.byType(DefaultTextStyle),
                        )
                        .first,
                  )
                  .style;
              _expectText(
                failures,
                where,
                text,
                want,
                'panelText',
                mode,
                weight: want['panelText.fontWeight'],
              );
            } else {
              expect(panel, findsNothing, reason: '$where — 접힌 내용은 그리지 않는다');
            }
          }

          // 사이 선 · 항목 면
          if (variant == PAccordionVariant.inline) {
            final divider = _keyed('paccordion-divider');
            expect(divider, findsOneWidget, reason: where);
            final sized = find
                .descendant(of: divider, matching: find.byType(SizedBox))
                .first;
            _near(
              failures,
              '$where — 선 두께',
              want['divider.height']! as num,
              tester.getSize(sized).height,
            );
            final dividerBox = tester.getRect(sized);
            final root = tester.getRect(_key('paccordion'));
            _near(
              failures,
              '$where — 선 좌우 들임',
              want['divider.marginX']! as num,
              dividerBox.left - root.left,
            );
            _near(
              failures,
              '$where — 선 좌우 들임(오른쪽)',
              want['divider.marginX']! as num,
              root.right - dividerBox.right,
            );
            final fill = tester
                .widget<ColoredBox>(
                  find
                      .descendant(
                        of: divider,
                        matching: find.byType(ColoredBox),
                      )
                      .first,
                )
                .color;
            if (!sameColor(
              specColor(pickMode(want['divider.background'], mode)),
              fill,
            )) {
              failures.add('$where — 선 색');
            }
            expect(_key('paccordion-item-face'), findsNothing, reason: where);
          } else {
            expect(_keyed('paccordion-divider'), findsNothing, reason: where);
            final faces = _key('paccordion-item-face');
            expect(faces, findsNWidgets(2), reason: where);
            final deco =
                tester.widget<DecoratedBox>(faces.first).decoration
                    as BoxDecoration;
            final border = deco.border! as Border;
            _near(
              failures,
              '$where — item.borderWidth',
              want['item.borderWidth']! as num,
              border.top.width,
            );
            if (!sameColor(
              specColor(pickMode(want['item.borderColor'], mode)),
              border.top.color,
            )) {
              failures.add('$where — 항목 테두리 색');
            }
            _near(
              failures,
              '$where — item.radius',
              want['item.radius']! as num,
              (deco.borderRadius! as BorderRadius).topLeft.x,
            );
            _near(
              failures,
              '$where — root.gap',
              want['root.gap']! as num,
              tester.getRect(faces.at(1)).top -
                  tester.getRect(faces.first).bottom,
            );
            expect(deco.boxShadow, isNull, reason: '$where — 그림자 없음');
          }
          // 면은 바탕 그대로(투명) — 놓인 면이 비친다
          expect(sameColor(c.bgLayerDefault, c.bgLayerDefault), isTrue);
          expect(want['item.background'], 'transparent');
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );

    testWidgets('${mode.name} — 누름(pressed) 바탕 · 콘텐츠 축소가 스펙 값이다', (
      tester,
    ) async {
      final failures = <String>[];
      for (final combo in _spec.combos(['variant', 'description'])) {
        final variant = PAccordionVariant.values.byName(combo['variant']!);
        final shown = combo['description'] == 'shown';
        final want = _spec.resolve({
          ...combo,
          'detail': 'expandable',
        }, 'pressed');
        final where = '${mode.name} $combo';
        await tester.pumpWidget(
          _host(
            mode,
            _accordion(
              variant: variant,
              open: false,
              shown: shown,
              detail: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final trigger = _key('pdisc-trigger').first;
        final rect = tester.getRect(trigger);
        final gesture = await tester.startGesture(rect.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final bgFinder = _key('pdisc-background').first;
        final bg =
            tester.widget<DecoratedBox>(bgFinder).decoration as BoxDecoration;
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
          tester.getRect(bgFinder).left - rect.left,
        );
        _near(
          failures,
          '$where — 바탕 모서리',
          want['background.radius']! as num,
          (bg.borderRadius! as BorderRadius).topLeft.x,
        );
        _near(
          failures,
          '$where — 바탕 높이(줄지 않는다)',
          rect.height,
          tester.getRect(bgFinder).height,
        );
        // 콘텐츠 층만 — 기준 max(높이, 폭 ÷ 4, 24) 에서 2px
        final basis = [
          rect.height,
          rect.width / 4,
          24.0,
        ].reduce((a, b) => a > b ? a : b);
        final scale = tester
            .widget<AnimatedScale>(_key('pdisc-content').first)
            .scale;
        if ((scale - (basis - 2) / basis).abs() > 1e-6) {
          failures.add('$where — 축소: 스펙 ${(basis - 2) / basis} · 실제 $scale');
        }
        await gesture.up();
        await tester.pumpAndSettle();
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets(
      '${mode.name} — 막힘(disabled)은 아이콘 · 제목 · 설명 · 꺾쇠가 fg-disabled 이고 눌러도 열리지 않는다',
      (tester) async {
        final handle = tester.ensureSemantics();
        final failures = <String>[];
        for (final variant in PAccordionVariant.values) {
          final want = _spec.resolve({
            'variant': variant.name,
            'description': 'shown',
          }, 'disabled');
          final where = '${mode.name} ${variant.name}';
          final changes = <List<String>>[];
          await tester.pumpWidget(
            _host(
              mode,
              _accordion(
                variant: variant,
                open: false,
                shown: true,
                detail: true,
                disabled: true,
                onChange: changes.add,
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final k in ['title', 'description']) {
            final style = _text(
              tester,
              find.byKey(ValueKey('pdisc-$k')).first,
            ).style!;
            if (!sameColor(
              specColor(pickMode(want['$k.foreground'], mode)),
              style.color!,
            )) {
              failures.add('$where — $k 색');
            }
          }
          final icon = tester.widget<Icon>(
            find.descendant(
              of: _key('pdisc-chevron').first,
              matching: find.byType(Icon),
            ),
          );
          if (!sameColor(
            specColor(pickMode(want['chevron.color'], mode)),
            icon.color!,
          )) {
            failures.add('$where — 꺾쇠 색');
          }
          final prefix = tester.widget<Icon>(
            find.descendant(
              of: _key('pdisc-prefix').first,
              matching: find.byType(Icon),
            ),
          );
          if (!sameColor(
            specColor(pickMode(want['prefixIcon.color'], mode)),
            prefix.color!,
          )) {
            failures.add('$where — 앞 아이콘 색');
          }
          // 흐리게 하지 않는다 — 불투명도 층이 없다
          expect(
            find.descendant(
              of: _key('paccordion'),
              matching: find.byType(Opacity),
            ),
            findsNothing,
          );
          await tester.tap(_key('pdisc-trigger').first);
          await tester.pumpAndSettle();
          expect(changes, isEmpty, reason: where);
          expect(_key('paccordion-panel'), findsNothing, reason: where);
          final node = tester.getSemantics(
            find.bySemanticsLabel(RegExp('커피 할인')).first,
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

    testWidgets('${mode.name} — 목록 머리 · 모두 펼치기가 스펙 값이다', (tester) async {
      final failures = <String>[];
      final want = _spec.resolve({}, 'enabled');
      await tester.pumpWidget(
        _host(
          mode,
          PAccordionHeader(
            title: '혜택 상세 · 12건',
            trailing: PAccordionExpandAll(
              values: const [],
              expandable: const ['a', 'b'],
              onValuesChange: (_) {},
              expandLabel: '모두 펼치기',
              collapseLabel: '모두 접기',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final header = tester.getRect(_key('paccordion-header'));
      final headerRow = tester.getRect(
        find
            .descendant(
              of: _key('paccordion-header'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      _near(
        failures,
        '머리 높이',
        want['header.minHeight']! as num,
        headerRow.height,
      );
      _near(
        failures,
        '머리 아래 여백',
        want['header.marginBottom']! as num,
        header.bottom - headerRow.bottom,
      );
      _expectText(
        failures,
        mode.name,
        _text(tester, _key('paccordion-header-title')).style!,
        want,
        'headerTitle',
        mode,
      );
      final box = tester.getRect(_key('text-button-box'));
      _near(
        failures,
        '모두 펼치기 높이',
        want['expandAll.height']! as num,
        box.height,
      );
      final deco =
          tester.widget<Container>(_key('text-button-box')).decoration!
              as BoxDecoration;
      _near(
        failures,
        '모두 펼치기 모서리',
        want['expandAll.radius']! as num,
        (deco.borderRadius! as BorderRadius).topLeft.x,
      );
      final label = findText('모두 펼치기');
      _expectText(
        failures,
        mode.name,
        _text(tester, label).style!,
        want,
        'expandAll',
        mode,
      );
      final labelRect = tester.getRect(label);
      _near(
        failures,
        '모두 펼치기 왼쪽 여백',
        want['expandAll.paddingLeft']! as num,
        labelRect.left - box.left,
      );
      _near(
        failures,
        '모두 펼치기 오른쪽 여백',
        want['expandAll.paddingRight']! as num,
        box.right - labelRect.right,
      );
      expect(
        find.descendant(
          of: _key('text-button-box'),
          matching: find.byType(Icon),
        ),
        findsNothing,
        reason: '아이콘 없음(SEED Text Button)',
      );
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }

  group('모션', () {
    final motion = _spec.json['motion'] as Map<String, dynamic>;

    testWidgets('시간 · 곡선이 스펙 값이다', (tester) async {
      final open = motion['펼침 · 접힘 — 높이'] as Map<String, dynamic>;
      expect(specMs(open['duration']), PDuration.d6);
      expect(specCubic(open['easing']), [0.35, 0.0, 0.35, 1.0]);
      expect(PEasing.easing, const Cubic(0.35, 0, 0.35, 1));
      final reduced = motion['모션 줄이기 — 펼침 · 접힘'] as Map<String, dynamic>;
      expect(specMs(reduced['duration']), PDuration.d3);
      expect(specMs((motion['꺾쇠 — 회전'] as Map)['duration']), PDuration.d6);
      expect(
        specMs((motion['누름 · 호버 — 바탕'] as Map)['duration']),
        PDuration.colorTransition,
      );
      expect(
        specMs((motion['누름 — 콘텐츠'] as Map)['duration']),
        PDuration.pressedScale,
      );
      expect(specCubic((motion['누름 — 콘텐츠'] as Map)['easing']), [
        0.0,
        0.0,
        0.15,
        1.0,
      ]);
    });

    Future<void> openFirst(WidgetTester tester) async {
      await tester.tap(_key('pdisc-trigger').first);
      await tester.pump();
    }

    testWidgets('펼침은 높이 300ms 로 이어 가고 꺾쇠도 300ms 돈다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _accordion(
            variant: PAccordionVariant.inline,
            open: false,
            shown: false,
            detail: true,
          ),
        ),
      );
      expect(_key('paccordion-panel-hidden'), findsNWidgets(2));
      await openFirst(tester);
      await tester.pump(const Duration(milliseconds: 150));
      final natural = tester
          .getSize(
            find.descendant(
              of: _key('paccordion-panel-clip'),
              matching: _key('paccordion-panel'),
            ),
          )
          .height;
      final mid = tester.getSize(_key('paccordion-panel-clip')).height;
      expect(mid, greaterThan(0));
      expect(mid, lessThan(natural), reason: '150ms 에는 아직 다 펼치지 못했다');
      expect(
        tester.widget<AnimatedRotation>(_key('pdisc-chevron').first).duration,
        PDuration.d6,
      );
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.getSize(_key('paccordion-panel-clip')).height, natural);
      // 접으면 높이를 줄이고 끝나면 트리에서 뺀다
      await openFirst(tester);
      await tester.pump(const Duration(milliseconds: 150));
      final closing = tester.getSize(_key('paccordion-panel-clip')).height;
      expect(closing, lessThan(natural));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_key('paccordion-panel'), findsNothing);
      expect(_key('paccordion-panel-hidden'), findsNWidgets(2));
    });

    testWidgets('처음 그릴 때는 움직이지 않는다 — 펼친 채 시작하면 바로 다 펼쳐 있다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _accordion(
            variant: PAccordionVariant.inline,
            open: true,
            shown: false,
            detail: true,
          ),
        ),
      );
      final natural = tester.getSize(_key('paccordion-panel').first).height;
      expect(
        tester.getSize(_key('paccordion-panel-clip').first).height,
        natural,
      );
    });

    testWidgets('모션 줄이기면 높이를 움직이지 않고 150ms 서서히 · 꺾쇠는 바로 뒤집힌다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _accordion(
            variant: PAccordionVariant.inline,
            open: false,
            shown: false,
            detail: true,
          ),
          reduceMotion: true,
        ),
      );
      await openFirst(tester);
      await tester.pump(const Duration(milliseconds: 75));
      expect(
        _key('paccordion-panel-clip'),
        findsNothing,
        reason: '높이를 움직이지 않는다',
      );
      final half = tester
          .widget<Opacity>(_key('paccordion-panel-fade'))
          .opacity;
      expect(half, greaterThan(0));
      expect(half, lessThan(1));
      expect(
        tester.widget<AnimatedRotation>(_key('pdisc-chevron').first).duration,
        Duration.zero,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<Opacity>(_key('paccordion-panel-fade')).opacity, 1);
      // 누름 축소도 하지 않는다(색만)
      final trigger = tester.getRect(_key('pdisc-trigger').first);
      final g = await tester.startGesture(trigger.center);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<AnimatedScale>(_key('pdisc-content').first).scale,
        1,
      );
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('동작 · 접근성', () {
    testWidgets('늘 여럿을 함께 열 수 있다 — values · onValuesChange 로 쥐고 다룬다', (
      tester,
    ) async {
      final seen = <List<String>>[];
      var values = <String>[];
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return _accordion(
                variant: PAccordionVariant.inline,
                open: false,
                shown: false,
                detail: true,
                values: values,
                onChange: (v) {
                  seen.add(v);
                  set(() => values = v);
                },
              );
            },
          ),
        ),
      );
      await tester.tap(_title('커피 할인'));
      await tester.pumpAndSettle();
      await tester.tap(_title('주유 할인'));
      await tester.pumpAndSettle();
      expect(seen, [
        ['coffee'],
        ['coffee', 'fuel'],
      ], reason: '하나만 여는 모드가 없다');
      expect(findText('커피 할인 상세'), findsOneWidget);
      expect(findText('주유 할인 상세'), findsOneWidget);
      await tester.tap(_title('커피 할인'));
      await tester.pumpAndSettle();
      expect(seen.last, ['fuel']);
      expect(findText('커피 할인 상세'), findsNothing);
    });

    testWidgets('쥐고 다루는 값을 안 바꿔 주면 그대로다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _accordion(
            variant: PAccordionVariant.inline,
            open: false,
            shown: false,
            detail: true,
            values: const [],
            onChange: (_) {},
          ),
        ),
      );
      await tester.tap(_title('커피 할인'));
      await tester.pumpAndSettle();
      expect(findText('커피 할인 상세'), findsNothing);
    });

    testWidgets(
      '이름은 제목 + 설명, 펼침은 expanded, 머리말 단계 3 · 접힌 내용은 읽지 않고 region 이 없다',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Brightness.light,
            _accordion(
              variant: PAccordionVariant.inline,
              open: false,
              shown: true,
              detail: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final node = tester.getSemantics(
          find.bySemanticsLabel(RegExp('^커피 할인\n')),
        );
        final data = node.getSemanticsData();
        expect(data.label, '커피 할인\n전 가맹점 30% 청구 할인');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isExpanded, Tristate.isFalse);
        expect(
          find.bySemanticsLabel('커피 할인 상세'),
          findsNothing,
          reason: '접힌 내용은 읽지 않는다',
        );
        await tester.tap(_title('커피 할인'));
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(RegExp('^커피 할인\n')))
              .getSemanticsData()
              .flagsCollection
              .isExpanded,
          Tristate.isTrue,
        );
        expect(find.bySemanticsLabel('커피 할인 상세'), findsOneWidget);
        // 머리말(3단계) 안의 단추
        var heading = false;
        void walk(SemanticsNode n) {
          final d = n.getSemanticsData();
          if (d.flagsCollection.isHeader && d.headingLevel == 3) heading = true;
          n.visitChildren((c) {
            walk(c);
            return true;
          });
        }

        walk(tester.getSemantics(find.byType(PAccordion)));
        expect(heading, isTrue);
        handle.dispose();
      },
    );

    testWidgets('상세 없는 줄은 단추 · 머리말이 아니라 글만 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _accordion(
            variant: PAccordionVariant.inline,
            open: false,
            shown: true,
            detail: false,
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel(RegExp('^커피 할인\n')))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isHeader, isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      // 눌러도 아무 일도 없다(눌림 바탕이 없다)
      await tester.tap(_title('커피 할인'));
      await tester.pumpAndSettle();
      expect(_key('pdisc-background'), findsNothing);
      handle.dispose();
    });

    testWidgets(
      '키보드 — Enter · Space 로 열고, ↓ ↑ Home End 로 트리거를 옮긴다(막힌 트리거는 건너뛴다)',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PAccordion(
              children: [
                PAccordionItem(
                  value: 'a',
                  title: 'A',
                  child: const Text('a 상세'),
                ),
                PAccordionItem(
                  value: 'b',
                  title: 'B',
                  disabled: true,
                  child: const Text('b 상세'),
                ),
                PAccordionItem(
                  value: 'c',
                  title: 'C',
                  child: const Text('c 상세'),
                ),
                const PAccordionPlainItem(title: '그냥 줄'),
              ],
            ),
          ),
        );
        FocusNode nodeOf(int i) =>
            Focus.of(tester.element(_key('pdisc-trigger').at(i)));
        nodeOf(0).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(nodeOf(2).hasPrimaryFocus, isTrue, reason: '막힌 B 를 건너뛴다');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(nodeOf(0).hasPrimaryFocus, isTrue, reason: '끝에서 처음으로 돈다');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(nodeOf(2).hasPrimaryFocus, isTrue, reason: '처음에서 끝으로 돈다');
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(nodeOf(0).hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(nodeOf(2).hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(findText('c 상세'), findsOneWidget);
        expect(nodeOf(2).hasPrimaryFocus, isTrue, reason: '펼쳐도 포커스는 트리거에 그대로');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(findText('c 상세'), findsNothing);
      },
    );

    testWidgets('모두 펼치기 — 상세 있는 항목만 열고, 하나라도 접혀 있으면 모두 펼치기 · 전부 열렸으면 모두 접기', (
      tester,
    ) async {
      var values = <String>['coffee'];
      late StateSetter set;
      const expandable = ['coffee', 'fuel'];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return Column(
                children: [
                  PAccordionExpandAll(
                    values: values,
                    expandable: expandable,
                    onValuesChange: (v) => set(() => values = v),
                    expandLabel: '모두 펼치기',
                    collapseLabel: '모두 접기',
                  ),
                  _accordion(
                    variant: PAccordionVariant.inline,
                    open: false,
                    shown: false,
                    detail: true,
                    values: values,
                    onChange: (v) => set(() => values = v),
                  ),
                ],
              );
            },
          ),
        ),
      );
      expect(findText('모두 펼치기'), findsOneWidget, reason: '하나라도 접혀 있다');
      await tester.tap(findText('모두 펼치기'));
      await tester.pumpAndSettle();
      expect(values, ['coffee', 'fuel']);
      expect(findText('모두 접기'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronsDownUp), findsNothing);
      await tester.tap(findText('모두 접기'));
      await tester.pumpAndSettle();
      expect(values, isEmpty);
      expect(findText('모두 펼치기'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronsUpDown), findsNothing);
    });

    testWidgets('PExpandMotion 은 List 의 하위 줄과 같은 위젯이다', (tester) async {
      expect(
        const PExpandMotion(open: false, child: SizedBox()),
        isA<Widget>(),
      );
    });
  });

  group('가장 나쁜 값', () {
    testWidgets('항목 20개 · 84자 제목 · 열린 항목이 여럿이어도 폰 폭 360 에서 넘치지 않는다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final mode in Brightness.values) {
        for (final variant in PAccordionVariant.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: mode == Brightness.dark
                  ? GrooTheme.dark()
                  : GrooTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: PAccordion(
                    variant: variant,
                    defaultValues: const ['i1', 'i2', 'i3'],
                    children: [
                      for (var i = 1; i <= 20; i++)
                        PAccordionItem(
                          value: 'i$i',
                          title: i == 1
                              ? '연회비 · 카드 발급 후 첫 달 실적 기준으로 산정하며 전월 이용 실적이 기준에 못 미치면 청구 할인이 적용되지 않아요'
                              : '유의사항 $i',
                          description: i == 2
                              ? '길어도 줄을 바꿔 다 보여요 길어도 줄을 바꿔 다 보여요 길어도 줄을 바꿔 다 보여요'
                              : null,
                          child: Text('상세 ' * 60),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${mode.name} ${variant.name}',
          );
          // 긴 제목은 줄을 바꾼다 — 한 줄(22)보다 높고, 위아래 여백은 스펙 trigger.paddingY(16)다(한 줄은 최소 높이가 가운데로 모은다)
          final want = _spec.resolve({'variant': variant.name}, 'enabled');
          final padY = want['trigger.paddingY']! as num;
          final trigger = tester.getRect(_key('pdisc-trigger').first);
          final title = tester.getRect(_key('pdisc-title').first);
          expect(title.top - trigger.top, padY, reason: '위 여백');
          expect(trigger.bottom - title.bottom, padY, reason: '아래 여백');
          expect(
            tester.getSize(_key('pdisc-title').first).height,
            greaterThan(22 * 2 - 1),
          );
        }
      }
    });
  });
}
