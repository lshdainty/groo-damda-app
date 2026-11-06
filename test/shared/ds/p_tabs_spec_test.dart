// Tabs 가 스펙 값(test/fixtures/design_spec/tabs.json · chip-tabs.json)대로인지 — Line 은 레이아웃 × 크기 × 고름 × 상태(기본 ·
// 누름 · 비활성) × 라이트 · 다크의 목록 · 탭 · 글 · 막대 · 알림 점 · 누름 축소, Chip Tabs 는 변형 × 크기의 목록 · 칩 · 알림 점,
// 그리고 키보드 · 막대 미끄러짐 · 가로 스크롤 · 읽는 말 · 내용 칸(상태 보존 · 밀어 넘기기). 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 상태(웹의 focused — 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 — 칸 나눔("똑같이")은 폭으로,
// 가로 스크롤은 스크롤해 보고, 누름 축소("탭 2px")는 그려진 배율로 잰다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/tabs/tabs_demo.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('tabs');
final _chipTabsSpec = DesignSpec.load('chip-tabs');
final _chipSpec = DesignSpec.load('chip');

/// 앱의 상태 — 웹의 focused(키보드 포커스 링)는 앱에 없다(tabs 에는 hovered 가 없다).
final _appStates = _spec.states.where((s) => s != 'focused').toList();

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  double width = 360,
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

PTab<String> _tab(
  String value,
  String label, {
  bool enabled = true,
  bool notification = false,
}) => PTab<String>(
  value: value,
  label: label,
  enabled: enabled,
  notification: notification,
);

/// 견본 — 카테고리 · 추이 · 비교. 재는 탭은 가운데(추이)이고, 알림 점은 첫 탭(안 고른 탭)에 둔다.
List<PTab<String>> _three({bool middleEnabled = true, bool dot = false}) => [
  _tab('category', '카테고리', notification: dot),
  _tab('trend', '추이', enabled: middleEnabled),
  _tab('compare', '비교'),
];

Finder get _list => find.byKey(const ValueKey('tabs-list'));
Finder get _bar => find.byKey(const ValueKey('tabs-indicator'));
Finder get _lineDot => find.byKey(const ValueKey('tabs-dot'));
Finder get _chipDot => find.byKey(const ValueKey('chip-tabs-dot'));
Finder get _chipBox => find.byKey(const ValueKey('chip-box'));

/// 이름으로 탭 하나(읽는 말이 붙은 칸).
Finder _tabOf(String label) =>
    find.ancestor(of: findText(label), matching: find.byType(PressArea));

BoxDecoration _decoration(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as BoxDecoration;

double _paintedScale(WidgetTester tester, Finder finder) =>
    tester.renderObject(finder).getTransformTo(null).entry(0, 0);

/// 실패를 모으는 도우미.
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

  void coverage(Set<String> measured, Set<String> elsewhere) {
    for (final key in want.keys) {
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}

const _webOnly = {
  'focusRing.width',
  'focusRing.offset',
  'focusRing.color',
  // 화면 맨 위 1차 — 상단 바 아래 고정: 셸의 몫이라 test/shared/nav_frame_audit_test.dart 가 잰다
  'list.position',
};

/// 동작 테스트가 보는 값 — 누르는 영역("탭 전체") · 막대가 무엇을 바꾸는지의 글 · 가로 스크롤 · 스크롤 여유.
const _lineBehavior = {
  'trigger.touchTarget',
  'indicator.transitionProperty',
  'list.overflowX',
  'list.scrollPadding',
};

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['layout', 'size', 'selected'])) {
      for (final state in _appStates) {
        final title =
            '${mode.name} ${combo['layout']} ${combo['size']} ${combo['selected']} $state';
        testWidgets('$title — Line 스펙 값이다', (tester) async {
          final selected = combo['selected'] == 'selected';
          final hug = combo['layout'] == 'hug';
          final disabled = state == 'disabled';
          final size = PTabsSize.values.byName(combo['size']!);
          await tester.pumpWidget(
            _host(
              mode,
              PTabs<String>(
                value: selected ? 'trend' : 'compare',
                onChanged: (_) {},
                semanticLabel: '통계',
                layout: PTabsLayout.values.byName(combo['layout']!),
                size: size,
                items: _three(middleEnabled: !disabled, dot: true),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          // 놓인 자리는 누르기 전에 잰다 — 누르면 탭이 줄어 그려진 사각형이 작아진다
          final list = tester.getRect(_list);
          final tab = tester.getRect(_tabOf('추이'));
          final label = tester.getRect(findText('추이'));
          final tab0 = tester.getRect(_tabOf('카테고리'));
          final tab2 = tester.getRect(_tabOf('비교'));
          final barRect = tester.getRect(_bar);
          TestGesture? gesture;
          if (state == 'pressed') {
            gesture = await tester.startGesture(tab.center);
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 400));
          final k = _Check(mode, _spec.resolve(combo, state), title);
          final measured = <String>{};
          void m(Iterable<String> keys) => measured.addAll(keys);

          // 목록 — 불투명 바탕 · 안쪽 1px 구획 선(높이를 밀지 않는다) · 폭을 채운다 · 최소 높이
          final listDeco = _decoration(tester, _list);
          k.color('list.background', listDeco.color!);
          final bottom = (listDeco.border! as Border).bottom;
          k.color('list.borderBottomColor', bottom.color);
          k.px('list.borderBottomWidth', bottom.width);
          k.px('list.minHeight', list.height);
          if ((list.width - 360).abs() > 0.01) k.fail('list: 놓인 폭을 채운다');
          k.px('list.paddingX', tab0.left - list.left);
          m([
            'list.background',
            'list.borderBottomColor',
            'list.borderBottomWidth',
            'list.minHeight',
            'list.paddingX',
          ]);

          // 탭 — 최소 높이 · 안쪽 여백 10 · 글을 아래로 붙인다 · 커서 · 칸 나눔 / 글 + 20
          k.px('trigger.minHeight', tab.height);
          if (hug) {
            k.px('trigger.paddingX', label.left - tab.left);
            k.px('trigger.paddingX', tab.right - label.right);
            k.px('trigger.grow', 0);
            if ((tab.width - (label.width + 20)).abs() > 0.5) {
              k.fail(
                'trigger.grow: Hug 는 글 + 좌우 10 — 폭 ${tab.width} · 글 ${label.width}',
              );
            }
          } else {
            // 글은 칸 가운데에 선다(좌우 여백 10 은 칸이 좁아질 때의 최소다)
            if ((label.center.dx - tab.center.dx).abs() > 0.5 ||
                label.left - tab.left < 10) {
              k.fail('trigger.paddingX: 글이 칸 가운데가 아니다 $label · $tab');
            }
            // 칸을 똑같이 나눈다
            if ((tab.width - 360 / 3).abs() > 0.01 ||
                (tab0.width - 360 / 3).abs() > 0.01 ||
                (tab2.width - 360 / 3).abs() > 0.01) {
              k.fail(
                'trigger.grow: 칸을 똑같이 나눈다 ${tab0.width} · ${tab.width} · ${tab2.width}',
              );
            }
          }
          k.px('trigger.paddingY', tab.bottom - label.bottom);
          // alignItems flex-end — 글 아래 10, 남는 높이는 위로
          if ((label.top - tab.top) < 10 - 0.01) {
            k.fail('trigger.alignItems: 글이 위 여백 10 안에 있다');
          }
          k.cursor(
            'trigger.cursor',
            tester
                .widget<MouseRegion>(
                  find
                      .descendant(
                        of: _tabOf('추이'),
                        matching: find.byType(MouseRegion),
                      )
                      .first,
                )
                .cursor,
          );
          m([
            'trigger.minHeight',
            'trigger.paddingX',
            'trigger.paddingY',
            'trigger.alignItems',
            'trigger.grow',
            'trigger.cursor',
          ]);

          // 글 — t4 14 / 19 · t5 16 / 22 · 700 · 색은 고름 · 막힘이 정한다
          final text = tester.widget<Text>(findText('추이'));
          k.typo('label.typography', text.style!);
          k.weight('label.fontWeight', text.style!);
          k.color('label.foreground', text.style!.color!);
          if (text.softWrap != false || text.maxLines != 1) {
            k.fail('label: 줄바꿈 · 말줄임하지 않는다');
          }
          m(['label.typography', 'label.fontWeight', 'label.foreground']);

          // 막대 — 2px · 각진 끝 · 고른 탭 아래 · Fill 은 탭에서 좌우 16 들이고 Hug 는 탭 폭 그대로
          final selectedTab = selected ? tab : tab2;
          final barDeco = _decoration(
            tester,
            find
                .descendant(of: _bar, matching: find.byType(DecoratedBox))
                .first,
          );
          k.px('indicator.height', barRect.height);
          k.color('indicator.background', barDeco.color!);
          if (barDeco.borderRadius != null) {
            k.fail('indicator.radius: 끝이 각져야 한다');
          }
          k.px('indicator.radius', 0);
          k.px('indicator.insetX', barRect.left - selectedTab.left);
          k.px('indicator.insetX', selectedTab.right - barRect.right);
          if ((barRect.bottom - list.bottom).abs() > 0.5) {
            k.fail('indicator: 목록 바닥에 붙는다 $barRect · $list');
          }
          final slide = tester.widget<AnimatedPositioned>(_bar);
          k.motion(
            'indicator.transitionDuration',
            'indicator.transitionEasing',
            PDuration.d4,
            slide.curve,
          );
          m([
            'indicator.height',
            'indicator.background',
            'indicator.radius',
            'indicator.insetX',
            'indicator.transitionDuration',
            'indicator.transitionEasing',
          ]);

          // 알림 점 — 첫 탭(안 고른 탭)의 글 끝에서 2 · 글 위쪽, 6px 원 · 브랜드 글자색
          final dot = tester.getRect(_lineDot);
          final label0 = tester.getRect(findText('카테고리'));
          k.px('notification.size', dot.width);
          k.px('notification.size', dot.height);
          k.px('notification.gap', dot.left - label0.right);
          if ((dot.top - label0.top).abs() > 0.5) {
            k.fail('notification: 글 위쪽이 아니다 $dot · $label0');
          }
          final dotDeco = _decoration(tester, _lineDot);
          k.px(
            'notification.radius',
            (dotDeco.borderRadius! as BorderRadius).topLeft.x,
          );
          k.color('notification.background', dotDeco.color!);
          m([
            'notification.size',
            'notification.radius',
            'notification.background',
            'notification.gap',
          ]);

          // 누름 축소 — 탭만(기준 max(높이, 폭 ÷ 4, 24)), 색은 그대로
          final scale = tester.widget<AnimatedScale>(
            find
                .descendant(
                  of: _tabOf('추이'),
                  matching: find.byType(AnimatedScale),
                )
                .first,
          );
          k.pressScale('trigger.scale', scale.scale, tab.size);
          k.motion(
            'trigger.scaleDuration',
            'trigger.scaleEasing',
            scale.duration,
            scale.curve,
          );
          m(['trigger.scale', 'trigger.scaleDuration', 'trigger.scaleEasing']);

          k.coverage(measured, {..._webOnly, ..._lineBehavior});
          await gesture?.up();
          await tester.pump(const Duration(milliseconds: 400));
          if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
        });
      }
    }
  }

  group('Chip Tabs 스펙', () {
    for (final mode in Brightness.values) {
      for (final combo in _chipTabsSpec.combos(['variant', 'size'])) {
        testWidgets('${mode.name} ${combo['variant']} ${combo['size']} — 스펙 값이다', (
          tester,
        ) async {
          final variant = PChipTabsVariant.values.byName(combo['variant']!);
          final size = PChipTabsSize.values.byName(combo['size']!);
          final where = '${mode.name} ${combo['variant']} ${combo['size']}';
          final want = _chipTabsSpec.resolve(combo, 'enabled');
          final k = _Check(mode, want, where);
          await tester.pumpWidget(
            _host(
              mode,
              PChipTabs<String>(
                value: 'holding',
                onChanged: (_) {},
                semanticLabel: '자산',
                variant: variant,
                size: size,
                items: [
                  _tab('all', '전체', notification: true),
                  _tab('holding', '보유'),
                  _tab('watch', '관심'),
                ],
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          final scroll = find.byKey(const ValueKey('chip-tabs-scroll'));
          final viewport = tester.getRect(scroll);
          final chips = [
            for (var i = 0; i < 3; i++) tester.getRect(_chipBox.at(i)),
          ];

          // 목록 — 좌우 화면 여백 24 · 위아래 8 · 칩 사이 8 · 한 줄 가로 스크롤 · 스크롤바 숨김
          k.px('list.paddingX', chips.first.left - viewport.left);
          k.px('list.paddingY', chips.first.top - viewport.top);
          k.px('list.paddingY', viewport.bottom - chips.first.bottom);
          k.px('list.gap', chips[1].left - chips[0].right);
          k.px('list.gap', chips[2].left - chips[1].right);
          final widgetScroll = tester.widget<SingleChildScrollView>(scroll);
          if (widgetScroll.scrollDirection != Axis.horizontal) {
            k.fail('list.overflowX: 가로 스크롤이 아니다');
          }
          if (find.byType(Scrollbar).evaluate().isNotEmpty) {
            k.fail('list.overflowX: 스크롤바는 숨긴다');
          }
          // 바탕 · 바닥 선이 없다 — 목록에 칠하는 것이 없다
          if (find
              .descendant(
                of: scroll,
                matching: find.byKey(const ValueKey('tabs-list')),
              )
              .evaluate()
              .isNotEmpty) {
            k.fail('list: 바탕 · 바닥 선이 없다');
          }
          // 양 끝 흐림 — Scroll Fog row(좌우 20)
          final fog = tester.widget<PScrollFogMask>(
            find.byType(PScrollFogMask),
          );
          if (fog.axis != Axis.horizontal || fog.start != 20 || fog.end != 20) {
            k.fail('list.fog: 좌우 20 — ${fog.axis} ${fog.start} ${fog.end}');
          }
          // 칩 — Chip 그대로: 높이는 Chip medium · large 가 정한다(chip.json root.height — Q-010-2), 변형은 Solid → solid ·
          // Outline → outlineStrong
          final visual = tester.widget<ChipVisual>(
            find.byType(ChipVisual).first,
          );
          final wantVariant = combo['variant'] == 'solid'
              ? PChipVariant.solid
              : PChipVariant.outlineStrong;
          if (visual.variant != wantVariant) {
            k.fail(
              'trigger.chip: ${want['trigger.chip']} — 실제 ${visual.variant}',
            );
          }
          final chipSize = combo['size'] == 'medium' ? 'medium' : 'large';
          final chipWant = _chipSpec.resolve({
            'variant': wantVariant.name,
            'size': chipSize,
          }, 'enabled');
          final chipHeight = (chipWant['root.height']! as num).toDouble();
          if ((chips.first.height - chipHeight).abs() > 0.01) {
            k.fail(
              'trigger.chipSize: ${want['trigger.chipSize']} — Chip 높이 $chipHeight · 실제 ${chips.first.height}',
            );
          }
          // 고른 칩(보유)은 Chip 의 고른 모습, 안 고른 칩은 안 고른 모습
          final selectedDeco = _decoration(tester, _chipBox.at(1));
          final unselectedDeco = _decoration(tester, _chipBox.at(2));
          final selWant = _chipSpec.resolve({
            'variant': wantVariant.name,
            'size': chipSize,
            'selected': 'selected',
          }, 'enabled');
          final unWant = _chipSpec.resolve({
            'variant': wantVariant.name,
            'size': chipSize,
          }, 'enabled');
          if (!sameColor(
            specColor(pickMode(selWant['root.background'], mode)),
            selectedDeco.color!,
          )) {
            k.fail('고른 칩 바탕이 Chip 과 다르다');
          }
          final unBg = unWant['root.background'];
          if (unBg is String && unBg == 'transparent') {
            if (unselectedDeco.color!.a != 0) k.fail('안 고른 칩 바탕이 Chip 과 다르다');
          } else if (!sameColor(
            specColor(pickMode(unBg, mode)),
            unselectedDeco.color!,
          )) {
            k.fail('안 고른 칩 바탕이 Chip 과 다르다');
          }
          // 알림 점 — 안 고른 첫 칩의 글 뒤 6 · 세로 가운데 · 6px 원 · 브랜드 글자색, 칩 폭이 그만큼 넓어진다
          final dot = tester.getRect(_chipDot);
          final label = tester.getRect(
            find.descendant(of: _chipBox.first, matching: find.byType(Text)),
          );
          k.px('notification.size', dot.width);
          k.px('notification.size', dot.height);
          k.px('notification.gap', dot.left - label.right);
          if ((dot.center.dy - chips.first.center.dy).abs() > 0.5) {
            k.fail('notification: 세로 가운데가 아니다');
          }
          final dotDeco = _decoration(tester, _chipDot);
          k.px(
            'notification.radius',
            (dotDeco.borderRadius! as BorderRadius).topLeft.x,
          );
          k.color('notification.background', dotDeco.color!);
          // 줄어들지 않는다 — 좁은 폭에서도 칩은 제 폭
          k.px('trigger.shrink', 0);
          if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
        });
      }
    }
  });

  group('Chip Tabs 줄 폭', () {
    testWidgets('Chip Tabs — 보이는 줄 폭에서 멈춘다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PChipTabs<int>(
            value: 0,
            onChanged: (_) {},
            semanticLabel: '모아보기',
            items: const [
              PTab(value: 0, label: '이름이 아주 길어서 한 줄에 다 들어가지 않는 카드 혜택 모음 이야기'),
              PTab(value: 1, label: '식비'),
            ],
          ),
          width: 312,
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('chip-box')).first).width,
        312 - 2 * 24,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Line 동작', () {
    testWidgets(
      'Fill — 360 폰에서 2 · 3 · 4 · 5개면 막대는 148 · 88 · 58 · 40(탭 폭 − 32), Hug 는 탭 폭 그대로',
      (tester) async {
        final names = ['가계부', '자산', '통계', '예산', '목표'];
        const widths = {2: 148.0, 3: 88.0, 4: 58.0, 5: 40.0};
        for (final count in [2, 3, 4, 5]) {
          await tester.pumpWidget(
            _host(
              Brightness.light,
              PTabs<String>(
                value: 'v0',
                onChanged: (_) {},
                semanticLabel: '구역',
                items: [for (var i = 0; i < count; i++) _tab('v$i', names[i])],
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.getSize(_bar).width, widths[count], reason: '$count개');
          expect(
            tester.getSize(_tabOf(names[0])).width,
            closeTo(360 / count, 0.01),
          );
        }
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PTabs<String>(
              value: 'v0',
              onChanged: (_) {},
              semanticLabel: '구역',
              layout: PTabsLayout.hug,
              items: [for (var i = 0; i < 3; i++) _tab('v$i', names[i])],
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          tester.getSize(_bar).width,
          tester.getSize(_tabOf(names[0])).width,
        );
        // Hug 의 첫 글은 26 에서 시작한다(목록 16 + 탭 10)
        expect(tester.getRect(findText(names[0])).left, 26);
      },
    );

    testWidgets('막대는 고른 탭 아래로 200ms 에 미끄러진다 — 모션 줄이기에도 그대로, 크기가 바뀌면 바로 놓는다', (
      tester,
    ) async {
      final duration = specMs(
        ((_spec.json['motion'] as Map)['막대 — 미끄러짐'] as Map)['duration'],
      );
      for (final reduce in [false, true]) {
        var value = 'category';
        late StateSetter set;
        await tester.pumpWidget(
          _host(
            Brightness.light,
            StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return PTabs<String>(
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                  semanticLabel: '통계',
                  items: _three(),
                );
              },
            ),
            reduceMotion: reduce,
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        final start = tester.getRect(_bar).left;
        await tester.tap(findText('비교'));
        await tester.pump();
        await tester.pump();
        await tester.pump(duration ~/ 2);
        final mid = tester.getRect(_bar).left;
        expect(mid, greaterThan(start), reason: 'reduce=$reduce');
        await tester.pump(duration);
        final end = tester.getRect(_bar).left;
        expect(mid, lessThan(end), reason: 'reduce=$reduce');
        expect(end, closeTo(start + 2 * 120, 0.01));
        // 쓰는 쪽이 값을 바꿔도 따라간다
        set(() => value = 'trend');
        await tester.pump();
        await tester.pump();
        await tester.pump(duration + const Duration(milliseconds: 50));
        expect(tester.getRect(_bar).left, closeTo(start + 120, 0.01));
      }
    });

    testWidgets('글자색은 전환 없이 바로 바뀐다 — 굵기 · 크기는 그대로(폭이 흔들리지 않는다)', (
      tester,
    ) async {
      Widget build(String v) => _host(
        Brightness.light,
        PTabs<String>(
          value: v,
          onChanged: (_) {},
          semanticLabel: '통계',
          layout: PTabsLayout.hug,
          items: _three(),
        ),
      );
      await tester.pumpWidget(build('category'));
      final c = GrooTheme.light().extension<PColors>()!;
      final width = tester.getSize(_tabOf('추이')).width;
      expect(
        tester.widget<Text>(findText('추이')).style!.color,
        c.fgNeutralSubtle,
      );
      await tester.pumpWidget(build('trend'));
      // 한 프레임 만에
      expect(tester.widget<Text>(findText('추이')).style!.color, c.fgNeutral);
      expect(tester.getSize(_tabOf('추이')).width, width);
    });

    testWidgets('누르면 부르고 — 고른 탭을 다시 눌러도 부르지 않는다 · 막힌 탭 · 막힌 목록은 누를 수 없다', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabs<String>(
            value: 'category',
            onChanged: calls.add,
            semanticLabel: '통계',
            items: _three(middleEnabled: false),
          ),
        ),
      );
      await tester.tap(findText('비교'));
      await tester.tap(findText('카테고리'));
      await tester.tap(findText('추이'));
      expect(calls, ['compare']);
      calls.clear();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabs<String>(
            value: 'category',
            onChanged: null,
            semanticLabel: '통계',
            items: _three(),
          ),
        ),
      );
      for (final t in ['카테고리', '추이', '비교']) {
        await tester.tap(findText(t));
      }
      expect(calls, isEmpty);
      // 목록 전체가 막혀 고른 탭이 막히면 막대도 전용 색
      final c = GrooTheme.light().extension<PColors>()!;
      expect(
        _decoration(
          tester,
          find.descendant(of: _bar, matching: find.byType(DecoratedBox)).first,
        ).color,
        c.fgDisabled,
      );
    });

    testWidgets('누르는 영역은 탭 전체다 — 탭의 위 · 아래 끝도 탭이다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabs<String>(
            value: 'category',
            onChanged: calls.add,
            semanticLabel: '통계',
            items: _three(),
          ),
        ),
      );
      final tab = tester.getRect(_tabOf('비교'));
      expect(tab.height, 40);
      await tester.tapAt(Offset(tab.center.dx, tab.top + 0.5));
      await tester.tapAt(Offset(tab.left + 0.5, tab.center.dy));
      await tester.tapAt(Offset(tab.center.dx, tab.bottom - 0.5));
      expect(calls, ['compare', 'compare', 'compare']);
    });

    testWidgets('Hug 는 넘치면 가로 스크롤 — 고른 탭이 밖이면 가장자리에서 16 띄워 따라가고 스크롤바는 없다', (
      tester,
    ) async {
      final names = [for (var i = 0; i < 9; i++) '구역 ${i + 1}'];
      var value = 'v0';
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return PTabs<String>(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: '구역',
                layout: PTabsLayout.hug,
                items: [for (var i = 0; i < 9; i++) _tab('v$i', names[i])],
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final scroll = find.byKey(const ValueKey('tabs-scroll'));
      expect(
        tester.widget<SingleChildScrollView>(scroll).scrollDirection,
        Axis.horizontal,
      );
      expect(find.byType(Scrollbar), findsNothing);
      // 처음엔 처음 탭이 보이고 끝 탭은 밖에 있다
      expect(tester.getRect(_tabOf(names[8])).left, greaterThan(360));
      set(() => value = 'v8');
      await tester.pumpAndSettle();
      final view = tester.getRect(scroll);
      final last = tester.getRect(_tabOf(names[8]));
      // 맨 끝까지 스크롤하면 끝 탭 오른쪽에 목록 안쪽 16 이 남는다
      expect(view.right - last.right, closeTo(16, 0.01));
      // 막대도 따라온다
      expect(tester.getRect(_bar).right, closeTo(last.right, 0.01));
      // 가운데 탭을 고르면 가장자리와 16 을 두고 드러낸다(이미 보이면 그대로)
      set(() => value = 'v4');
      await tester.pumpAndSettle();
      final mid = tester.getRect(_tabOf(names[4]));
      expect(mid.left, greaterThanOrEqualTo(view.left + 16 - 0.01));
      expect(mid.right, lessThanOrEqualTo(view.right - 16 + 0.01));
      // 첫 탭으로 돌아오면 처음으로 돌아간다
      set(() => value = 'v0');
      await tester.pumpAndSettle();
      expect(tester.getRect(findText(names[0])).left, 26);
    });

    testWidgets(
      'Fill 이 넘치면(360 · 영어 긴 탭 넷) 칸을 나누지 않고 가로 스크롤 — 줄이 넘치지 않고 고른 넷째 탭이 보인다(03-G 3B)',
      (tester) async {
        final names = [
          'Monthly overview',
          'Spending by category',
          'Recurring payments',
          'Budget settings',
        ];
        var value = 'v0';
        late StateSetter set;
        await tester.pumpWidget(
          _host(
            Brightness.light,
            StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return PTabs<String>(
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                  semanticLabel: 'Stats',
                  items: [for (var i = 0; i < 4; i++) _tab('v$i', names[i])],
                );
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: '줄이 넘치지 않는다');
        final scroll = find.byKey(const ValueKey('tabs-scroll'));
        expect(scroll, findsOneWidget, reason: '넘치면 스크롤 목록');
        expect(find.byType(Scrollbar), findsNothing);
        final view = tester.getRect(scroll);
        expect(view.width, 360);
        // 칸을 나누지 않는다 — 탭 폭은 글 + 좌우 10
        for (final n in names) {
          final tab = tester.getRect(_tabOf(n));
          final label = tester.getRect(findText(n));
          expect(tab.width, closeTo(label.width + 20, 0.5), reason: n);
        }
        // 첫 탭에서 시작 — 내용 폭이 줄 폭보다 크다
        final position = tester
            .state<ScrollableState>(
              find.descendant(of: scroll, matching: find.byType(Scrollable)),
            )
            .position;
        expect(position.maxScrollExtent, greaterThan(0));
        expect(tester.getRect(_tabOf(names[3])).right, greaterThan(360));
        // 넷째 탭을 고르면 보이는 자리로 따라온다
        set(() => value = 'v3');
        await tester.pumpAndSettle();
        final last = tester.getRect(_tabOf(names[3]));
        expect(last.right, lessThanOrEqualTo(view.right + 0.01));
        expect(last.left, greaterThanOrEqualTo(view.left));
        // 막대 들임 16 은 fill 값 그대로
        final bar = tester.getRect(_bar);
        expect(bar.left - last.left, closeTo(16, 0.01));
        expect(last.right - bar.right, closeTo(16, 0.01));
        // 글 폭 합이 줄 폭에 들면 다시 칸을 똑같이 나눈다(360 폰 2개면 막대 148)
      },
    );

    test('fillTabWidths — 칸보다 긴 탭만 글 폭, 나머지가 남은 폭을 똑같이', () {
      // 360 에 글 폭 100 · 200 · 40 → 똑같이 120 이면 둘째(200)가 넘는다 → 200 고정, 남은 160 은 80 씩인데 첫째(100)도 넘으니 100 고정 → 셋째 60
      expect(fillTabWidths([100, 200, 40], 360), [100, 200, 60]);
      expect(fillTabWidths([48, 160, 48], 360), [100, 160, 100]);
      // 모두 칸 안이면 똑같이
      expect(fillTabWidths([60, 70, 50], 360), [120, 120, 120]);
      // 합이 총 폭
      final w = fillTabWidths([150, 100, 40, 30], 360);
      expect(w.fold<double>(0, (a, b) => a + b), closeTo(360, 0.001));
    });

    testWidgets('Fill — 합은 줄 안이지만 한 탭 글이 칸보다 길면 그 탭만 넓어진다(글이 칸 밖으로 넘치지 않는다)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabs<String>(
            value: 'a',
            onChanged: (_) {},
            semanticLabel: 'Stats',
            items: [_tab('a', 'Ab'), _tab('b', 'Long label'), _tab('c', 'Cd')],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('tabs-scroll')), findsNothing);
      final a = tester.getSize(_tabOf('Ab')).width;
      final b = tester.getSize(_tabOf('Long label')).width;
      final c = tester.getSize(_tabOf('Cd')).width;
      expect(a + b + c, closeTo(360, 0.5));
      expect(b, greaterThan(120), reason: '그 탭만 넓어진다');
      expect(a, lessThan(120));
      expect(
        tester.getSize(findText('Long label')).width,
        lessThanOrEqualTo(b - 20 + 0.5),
        reason: '글이 칸 안에 든다',
      );
    });

    testWidgets('알림 점은 안 고른 탭에만 — 고르면 사라지고 탭 폭은 바뀌지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      var value = 'a';
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return PTabs<String>(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: '진행',
                layout: PTabsLayout.hug,
                items: [_tab('a', '진행 중'), _tab('b', '완료', notification: true)],
              );
            },
          ),
        ),
      );
      expect(_lineDot, findsOneWidget);
      final width = tester.getSize(_tabOf('완료')).width;
      // 점이 있는 탭 이름 뒤에 읽는 글을 덧붙인다 — 점만으로 알리지 않는다
      expect(find.bySemanticsLabel('완료 새 소식, 탭 2/2'), findsOneWidget);
      set(() => value = 'b');
      await tester.pump();
      expect(_lineDot, findsNothing);
      expect(find.bySemanticsLabel('완료 새 소식, 탭 2/2'), findsNothing);
      expect(find.bySemanticsLabel('완료, 탭 2/2'), findsOneWidget);
      expect(tester.getSize(_tabOf('완료')).width, width);
      semantics.dispose();
    });

    test('탭은 2개 이상 — 알림 점의 읽는 글("새 소식")은 컴포넌트가 갖는다', () {
      expect(
        () => PTabs<String>(
          value: 'a',
          onChanged: (_) {},
          semanticLabel: '구역',
          items: [_tab('a', '하나')],
        ),
        throwsAssertionError,
      );
    });

    testWidgets('누르면 탭만 2px 거리 준다 — 색 · 막대는 그대로, 모션 줄이기면 줄지 않는다', (
      tester,
    ) async {
      final c = GrooTheme.light().extension<PColors>()!;
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PTabs<String>(
              value: 'category',
              onChanged: (_) {},
              semanticLabel: '통계',
              items: _three(),
            ),
            reduceMotion: reduce,
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        final tab = tester.getRect(_tabOf('추이'));
        final bar = tester.getRect(_bar);
        final g = await tester.startGesture(tab.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // 기준 max(40, 120 ÷ 4, 24) = 40
        expect(
          _paintedScale(tester, findText('추이')),
          closeTo(reduce ? 1 : 38 / 40, 1e-3),
          reason: 'reduce=$reduce',
        );
        expect(tester.getRect(_bar), bar);
        // 누르는 동안 색은 그대로(손을 떼기 전에 고른 것처럼 보이지 않는다)
        expect(
          tester.widget<Text>(findText('추이')).style!.color,
          c.fgNeutralSubtle,
        );
        await g.up();
        await tester.pump(const Duration(milliseconds: 400));
      }
    });
  });

  group('키보드', () {
    Future<List<String>> pumpFocus(
      WidgetTester tester, {
      bool dot = false,
    }) async {
      final calls = <String>[];
      var value = 'category';
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: [
              StatefulBuilder(
                builder: (context, setState) => PTabs<String>(
                  value: value,
                  onChanged: (v) => setState(() {
                    calls.add(v);
                    value = v;
                  }),
                  semanticLabel: '통계',
                  items: [
                    _tab('category', '카테고리'),
                    _tab('trend', '추이', enabled: false),
                    _tab('compare', '비교'),
                    _tab('budget', '예산'),
                  ],
                ),
              ),
              const Focus(child: SizedBox(height: 10)),
            ],
          ),
        ),
      );
      return calls;
    }

    testWidgets('Tab 은 고른 탭 하나에만 선다 — 다음 Tab 은 목록을 나간다', (tester) async {
      await pumpFocus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.rect;
      expect(
        focused.center.dx,
        closeTo(tester.getRect(_tabOf('카테고리')).center.dx, 1),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus!.rect.top,
        greaterThan(tester.getRect(_list).bottom - 1),
      );
    });

    testWidgets('← → 로 옮기면 바로 고른다 — 막힌 탭은 건너뛰고 끝에서 처음으로 돈다', (tester) async {
      final calls = await pumpFocus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(calls, ['compare']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      // 끝(예산)에서 처음(카테고리)으로 돈다
      expect(calls, ['compare', 'budget', 'category']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(calls.last, 'budget');
      // 포커스가 새로 고른 탭을 따라간다 — 다음 Tab 은 그 탭에서 나간다
      expect(
        FocusManager.instance.primaryFocus!.rect.center.dx,
        closeTo(tester.getRect(_tabOf('예산')).center.dx, 1),
      );
    });

    testWidgets('Home · End 는 첫 · 마지막 탭(막히지 않은)이다', (tester) async {
      final calls = await pumpFocus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(calls, ['budget']);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(calls, ['budget', 'category']);
    });

    testWidgets('Space · Enter 로 포커스된 탭을 고른다 — 막힌 목록에는 초점이 가지 않는다', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabs<String>(
            value: 'category',
            onChanged: null,
            semanticLabel: '통계',
            items: _three(),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(calls, isEmpty);
      expect(
        FocusManager.instance.primaryFocus?.rect.center.dx,
        isNot(closeTo(tester.getRect(_tabOf('추이')).center.dx, 1)),
      );
    });
  });

  group('읽는 말', () {
    testWidgets('목록은 이름 있는 탭 목록, 탭은 선택을 가진 탭 — 막힘 · 알림 점을 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabs<String>(
            value: 'category',
            onChanged: (_) {},
            semanticLabel: '통계',
            items: [
              _tab('category', '카테고리'),
              _tab('trend', '추이', enabled: false),
              _tab('compare', '비교', notification: true),
            ],
          ),
        ),
      );
      final list = tester.getSemantics(find.bySemanticsLabel('통계'));
      expect(list.getSemanticsData().role, SemanticsRole.tabBar);
      final selected = tester.getSemantics(
        find.bySemanticsLabel('카테고리, 탭 1/3'),
      );
      expect(selected.getSemanticsData().role, SemanticsRole.tab);
      expect(
        selected,
        isSemantics(
          label: '카테고리, 탭 1/3',
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('추이, 탭 2/3')),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('비교 새 소식, 탭 3/3')),
        isSemantics(
          label: '비교 새 소식, 탭 3/3',
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('Chip Tabs 도 탭 목록 · 탭이다 — 고른 칩 · 알림 점', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PChipTabs<String>(
            value: 'holding',
            onChanged: (_) {},
            semanticLabel: '자산',
            items: [
              _tab('all', '전체', notification: true),
              _tab('holding', '보유'),
            ],
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('자산'))
            .getSemanticsData()
            .role,
        SemanticsRole.tabBar,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('보유, 탭 2/2')),
        isSemantics(
          label: '보유, 탭 2/2',
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel('전체 새 소식, 탭 1/2'), findsOneWidget);
      // 안드로이드 · iOS 는 tab 역할을 전달하지 않아 이름 끝 "탭 n/m" 이 위치를 알린다(Material TabBar 와 같다)
      semantics.dispose();
    });
  });

  testWidgets('영어 — 탭 이름 끝은 "Tab n of m"', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: PTabs<String>(
            value: 'a',
            onChanged: (_) {},
            semanticLabel: 'Stats',
            items: [_tab('a', 'Spending'), _tab('b', 'Budget')],
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Spending, Tab 1 of 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Budget, Tab 2 of 2'), findsOneWidget);
    semantics.dispose();
  });

  group('Chip Tabs 동작', () {
    testWidgets('누르면 고른다 · 고른 탭의 알림 점은 사라지고 칩 폭은 점만큼 줄어든다', (tester) async {
      var value = 'holding';
      late StateSetter set;
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return PChipTabs<String>(
                value: value,
                onChanged: (v) => setState(() {
                  calls.add(v);
                  value = v;
                }),
                semanticLabel: '자산',
                items: [
                  _tab('all', '전체', notification: true),
                  _tab('holding', '보유'),
                ],
              );
            },
          ),
        ),
      );
      final withDot = tester.getSize(_chipBox.first).width;
      expect(_chipDot, findsOneWidget);
      await tester.tap(findText('전체'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['all']);
      expect(_chipDot, findsNothing);
      // 점이 있을 때는 글 뒤 6 + 점 6 만큼 넓었다
      expect(withDot - tester.getSize(_chipBox.first).width, closeTo(12, 0.01));
      // 고른 칩을 다시 눌러도 부르지 않는다
      await tester.tap(findText('전체'));
      expect(calls, ['all']);
      set(() => value = 'holding');
    });

    testWidgets('칩 12개는 가로 스크롤 — 고른 칩이 밖이면 화면 여백 24 를 두고 따라간다', (tester) async {
      var value = 'c0';
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return PChipTabs<String>(
                value: value,
                onChanged: (v) => setState(() => value = v),
                semanticLabel: '카테고리',
                items: [for (var i = 0; i < 12; i++) _tab('c$i', '카테고리 $i')],
              );
            },
          ),
        ),
      );
      final scroll = find.byKey(const ValueKey('chip-tabs-scroll'));
      final view = tester.getRect(scroll);
      expect(tester.getRect(_chipBox.at(11)).left, greaterThan(view.right));
      set(() => value = 'c11');
      await tester.pumpAndSettle();
      // 끝까지 스크롤하면 끝 칩 오른쪽에 화면 여백 24 가 남는다
      expect(
        view.right - tester.getRect(_chipBox.at(11)).right,
        closeTo(24, 0.01),
      );
      set(() => value = 'c0');
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_chipBox.first).left - view.left,
        closeTo(24, 0.01),
      );
    });

    testWidgets('막힌 칩은 누를 수 없고 화살표가 건너뛴다 · Tab 은 고른 칩 하나에만 선다', (tester) async {
      final calls = <String>[];
      var value = 'a';
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => PChipTabs<String>(
              value: value,
              onChanged: (v) => setState(() {
                calls.add(v);
                value = v;
              }),
              semanticLabel: '진행',
              items: [
                _tab('a', '진행 중'),
                _tab('b', '완료', enabled: false),
                _tab('c', '전체'),
              ],
            ),
          ),
        ),
      );
      await tester.tap(findText('완료'), warnIfMissed: false);
      expect(calls, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(calls, ['c']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(calls, ['c', 'a']);
    });
  });

  group('내용 칸', () {
    Widget panels({
      required String value,
      ValueChanged<String>? onChanged,
      bool swipe = false,
      List<bool> enabled = const [true, true, true],
    }) => _host(
      Brightness.light,
      PTabPanels<String>(
        value: value,
        onChanged: onChanged,
        swipe: swipe,
        panels: [
          PTabPanel(
            value: 'a',
            enabled: enabled[0],
            child: const _Counter('A'),
          ),
          PTabPanel(
            value: 'b',
            enabled: enabled[1],
            child: const _Counter('B'),
          ),
          PTabPanel(
            value: 'c',
            enabled: enabled[2],
            child: const _Counter('C'),
          ),
        ],
      ),
    );

    testWidgets('고른 칸만 보이고 바로 바뀐다 · 칸마다 상태를 남긴다(다녀와도 그대로)', (tester) async {
      await tester.pumpWidget(panels(value: 'a'));
      expect(findText('A 0'), findsOneWidget);
      // 고르지 않은 칸은 그려 두되 보이지 않는다(상태를 남긴다)
      expect(findText('B 0', skipOffstage: false), findsOneWidget);
      expect(findText('B 0'), findsNothing);
      await tester.tap(findText('A 0'));
      await tester.pump();
      expect(findText('A 1'), findsOneWidget);
      await tester.pumpWidget(panels(value: 'b'));
      // 애니메이션 없이 바로
      expect(findText('B 0'), findsOneWidget);
      expect(findText('A 1'), findsNothing);
      await tester.pumpWidget(panels(value: 'a'));
      expect(findText('A 1'), findsOneWidget);
    });

    testWidgets('고른 칸이 높이를 정한다 — 다른 칸의 높이는 상관없다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabPanels<String>(
            value: 'a',
            panels: const [
              PTabPanel(value: 'a', child: SizedBox(height: 100)),
              PTabPanel(value: 'b', child: SizedBox(height: 500)),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(PTabPanels<String>)).height, 100);
    });

    testWidgets('밀어 넘기기 — 칸 폭의 25% 를 넘기면 이웃 탭으로 넘어간다(왼쪽으로 밀면 다음)', (
      tester,
    ) async {
      final calls = <String>[];
      var value = 'a';
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return PTabPanels<String>(
                value: value,
                swipe: true,
                onChanged: (v) {
                  calls.add(v);
                  setState(() => value = v);
                },
                panels: const [
                  PTabPanel(
                    value: 'a',
                    child: SizedBox(height: 200, child: Text('칸 A')),
                  ),
                  PTabPanel(
                    value: 'b',
                    child: SizedBox(height: 200, child: Text('칸 B')),
                  ),
                  PTabPanel(
                    value: 'c',
                    child: SizedBox(height: 200, child: Text('칸 C')),
                  ),
                ],
              );
            },
          ),
        ),
      );
      // 25% = 90 — 조금(60) 끌고 놓으면 제자리로
      var g = await tester.startGesture(const Offset(200, 100));
      await g.moveBy(const Offset(-30, 0));
      await g.moveBy(const Offset(-30, 0));
      await tester.pump();
      // 끄는 동안 이웃이 옆에서 들어온다
      expect(tester.getRect(findText('칸 B')).left, closeTo(300, 12));
      await tester.pump(const Duration(milliseconds: 300));
      await g.up();
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(findText('칸 A'), findsOneWidget);
      expect(findText('칸 B'), findsNothing);
      // 멈춰 놓고(속도 없이) 100 을 끌고 놓으면 넘어간다
      g = await tester.startGesture(const Offset(300, 100));
      await g.moveBy(const Offset(-50, 0));
      await g.moveBy(const Offset(-50, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await g.up();
      await tester.pump();
      // 값은 손을 뗄 때 바뀐다
      expect(calls, ['b']);
      await tester.pumpAndSettle();
      expect(findText('칸 B'), findsOneWidget);
      expect(findText('칸 A'), findsNothing);
      expect(tester.getRect(findText('칸 B')).left, closeTo(0, 0.01));
      set(() => value = 'a');
    });

    testWidgets('빠르게 튕기면 25% 가 안 돼도 넘어간다 — 24 보다 적으면 넘어가지 않는다', (tester) async {
      final calls = <String>[];
      var value = 'b';
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => PTabPanels<String>(
              value: value,
              swipe: true,
              onChanged: (v) {
                calls.add(v);
                setState(() => value = v);
              },
              panels: const [
                PTabPanel(
                  value: 'a',
                  child: SizedBox(height: 200, child: Text('칸 A')),
                ),
                PTabPanel(
                  value: 'b',
                  child: SizedBox(height: 200, child: Text('칸 B')),
                ),
                PTabPanel(
                  value: 'c',
                  child: SizedBox(height: 200, child: Text('칸 C')),
                ),
              ],
            ),
          ),
        ),
      );
      // 짧게(40) 빠르게 — 오른쪽으로 튕기면 이전 칸
      await tester.fling(findText('칸 B'), const Offset(40, 0), 1500);
      await tester.pumpAndSettle();
      expect(calls, ['a']);
      // 20 만 튕기면 거리가 모자란다
      await tester.fling(findText('칸 A'), const Offset(-20, 0), 1500);
      await tester.pumpAndSettle();
      expect(calls, ['a']);
    });

    testWidgets('이웃이 없는 쪽은 손의 1/3 만 따라온다 · 막힌 탭은 건너뛴다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => PTabPanels<String>(
              value: 'a',
              swipe: true,
              onChanged: calls.add,
              panels: const [
                PTabPanel(
                  value: 'a',
                  child: SizedBox(height: 200, child: Text('칸 A')),
                ),
                PTabPanel(
                  value: 'b',
                  enabled: false,
                  child: SizedBox(height: 200, child: Text('칸 B')),
                ),
                PTabPanel(
                  value: 'c',
                  child: SizedBox(height: 200, child: Text('칸 C')),
                ),
              ],
            ),
          ),
        ),
      );
      final g = await tester.startGesture(const Offset(100, 100));
      // 오른쪽으로 — 이전 칸이 없다: 120 을 끌어도 1/3 = 40 만
      await g.moveBy(const Offset(60, 0));
      await g.moveBy(const Offset(60, 0));
      await tester.pump();
      // 10 의 slop 을 넘긴 만큼부터 센다 — 끌린 양의 1/3 이하
      final moved = tester.getRect(findText('칸 A')).left;
      expect(moved, lessThan(60));
      expect(moved, greaterThan(0));
      await g.up();
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      // 왼쪽으로 크게 — 막힌 b 를 건너뛰어 c 로
      await tester.fling(findText('칸 A'), const Offset(-200, 0), 1000);
      await tester.pumpAndSettle();
      expect(calls, ['c']);
    });

    testWidgets('모션 줄이기면 손을 뗀 뒤 미끄러지지 않고 바로 바뀐다', (tester) async {
      var value = 'a';
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => PTabPanels<String>(
              value: value,
              swipe: true,
              onChanged: (v) => setState(() => value = v),
              panels: const [
                PTabPanel(
                  value: 'a',
                  child: SizedBox(height: 200, child: Text('칸 A')),
                ),
                PTabPanel(
                  value: 'b',
                  child: SizedBox(height: 200, child: Text('칸 B')),
                ),
              ],
            ),
          ),
          reduceMotion: true,
        ),
      );
      await tester.fling(findText('칸 A'), const Offset(-250, 0), 1500);
      await tester.pump();
      await tester.pump();
      expect(findText('칸 B'), findsOneWidget);
      expect(tester.getRect(findText('칸 B')).left, closeTo(0, 0.01));
    });

    testWidgets('쓰는 쪽이 값을 받지 않으면 제자리로 돌아온다', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabPanels<String>(
            value: 'a',
            swipe: true,
            onChanged: calls.add,
            panels: const [
              PTabPanel(
                value: 'a',
                child: SizedBox(height: 200, child: Text('칸 A')),
              ),
              PTabPanel(
                value: 'b',
                child: SizedBox(height: 200, child: Text('칸 B')),
              ),
            ],
          ),
        ),
      );
      await tester.fling(findText('칸 A'), const Offset(-250, 0), 1500);
      await tester.pumpAndSettle();
      expect(calls, ['b']);
      expect(findText('칸 A'), findsOneWidget);
      expect(findText('칸 B'), findsNothing);
      expect(tester.getRect(findText('칸 A')).left, closeTo(0, 0.01));
    });

    testWidgets('가로로 스크롤하는 칸 안에서 시작한 끌기는 그 칸이 맡는다 · 세로 스크롤은 그대로', (
      tester,
    ) async {
      final calls = <String>[];
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTabPanels<String>(
            value: 'a',
            swipe: true,
            onChanged: calls.add,
            panels: [
              PTabPanel(
                value: 'a',
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    children: const [
                      SizedBox(width: 1000, child: Text('가로 칸')),
                    ],
                  ),
                ),
              ),
              const PTabPanel(value: 'b', child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
      await tester.dragFrom(const Offset(100, 50), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(controller.offset, greaterThan(0));
    });
  });

  testWidgets('견본이 폰 폭 360 에서 넘침 없이 그려진다', (tester) async {
    for (final mode in Brightness.values) {
      await tester.pumpWidget(
        _host(mode, const SingleChildScrollView(child: TabsDemo())),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: mode.name);
    }
  });
}

/// 눌러서 세는 칸 — 칸을 오가도 숫자가 남는지 본다.
class _Counter extends StatefulWidget {
  const _Counter(this.name);

  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => count++),
    child: SizedBox(height: 100, child: Text('${widget.name} $count')),
  );
}
