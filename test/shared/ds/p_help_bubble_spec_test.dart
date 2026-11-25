// Help Bubble 이 스펙 값(test/fixtures/design_spec/help-bubble.json)대로인지 — 닫기 버튼 없음 · 있음 × 상태(열림 · 누름)
// × 라이트 · 다크의 말풍선 · 화살표 · 제목 · 설명 · 닫기 버튼, 놓는 자리(뒤집기 · 밀기 · 화살표), 여닫는 법 · 움직임 ·
// 키보드 · 읽는 말. 웹은 같은 JSON 을 크로미움에서 잰다(말풍선 자리 계산은 Radix 라 웹 테스트가 값만 맞춘다).
//
// 이 파일이 안 그리는 것 — 마우스를 올려 여는 Tooltip(opens: hover — 터치로는 열리지 않는다, 같은 스펙 파일의 다른 변형, 앱에도 둔다 —
// 마우스 · 키보드만, Q-009)과 웹의
// 포커스 링(focused). 문장으로 된 값은 그린 결과나 동작으로 본다 — 누르는 영역("44 × 44")은 누른 자리로, 쌓임(z-tooltip
// 210)은 오버레이가 늘 위라는 것으로, 자리 값(offset · margin · arrow.margin)은 놓은 결과로 잰다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/help_bubble_demo.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/help_bubble_layout.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/p_help_bubble.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('help-bubble');

const _title = '연차 사용 규정';
const _description = '입사 1년 미만은 한 달에 1일씩 생기고, 1년이 지나면 15일이 생겨요.';

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  Size? size,
}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: child),
  );
  return reduceMotion
      ? MediaQuery(
          data: MediaQueryData(
            size: size ?? const Size(800, 600),
            disableAnimations: true,
          ),
          child: app,
        )
      : app;
}

/// 작은 트리거 — 눌러서 여닫는다. 키는 'trigger'.
Widget _trigger(VoidCallback toggle, {double size = 40}) => GestureDetector(
  key: const ValueKey('trigger'),
  behavior: HitTestBehavior.opaque,
  onTap: toggle,
  child: SizedBox.square(dimension: size),
);

/// 키보드로 닿는 트리거 — 초점을 받고 Enter · Space 로 누른다(앱의 PButton 은 터치 전용이라 초점을 받지 않는다).
Widget _focusTrigger(VoidCallback toggle) => Focus(
  onKeyEvent: (node, event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      toggle();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  },
  child: _trigger(toggle),
);

PHelpBubble _bubble({
  String title = _title,
  String? description = _description,
  bool showCloseButton = false,
  bool closeOnInteractOutside = true,
  PHelpBubbleSide side = PHelpBubbleSide.top,
  bool? open,
  bool defaultOpen = false,
  ValueChanged<bool>? onOpenChange,
  double triggerSize = 40,
}) => PHelpBubble(
  title: title,
  description: description,
  showCloseButton: showCloseButton,
  closeOnInteractOutside: closeOnInteractOutside,
  side: side,
  open: open,
  defaultOpen: defaultOpen,
  onOpenChange: onOpenChange,
  triggerBuilder: (context, toggle, isOpen) =>
      _trigger(toggle, size: triggerSize),
);

Finder get _triggerFinder => find.byKey(const ValueKey('trigger'));
Finder get _bodyFinder => find.byKey(const ValueKey('help-bubble'));
Finder get _titleFinder => find.byKey(const ValueKey('help-bubble-title'));
Finder get _descFinder => find.byKey(const ValueKey('help-bubble-description'));
Finder get _closeBox => find.byKey(const ValueKey('help-bubble-close-box'));
Finder get _closeIcon => find.byKey(const ValueKey('help-bubble-close-icon'));

List<double> _cubicOf(Curve curve) {
  final c = curve as Cubic;
  return [c.a, c.b, c.c, c.d];
}

RenderHelpBubbleLayout _layout(WidgetTester tester) =>
    tester.renderObject<RenderHelpBubbleLayout>(find.byType(HelpBubbleLayout));

/// 열고(처음부터 열린 말풍선은 한 프레임 뒤) 열림 애니메이션(200ms)이 끝나게 기다린다.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  // 열림 · 닫힘(200ms)이 끝나고 내린 오버레이가 치워질 때까지
  await tester.pumpAndSettle();
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

/// 앱에 없는 값 — 포커스 링은 웹 상태(키보드 포커스 링)이고, 닫기 버튼의 모서리는 그 링의 모양에만 쓰인다.
const _webOnly = {
  'focusRing.width',
  'focusRing.offset',
  'focusRing.color',
  'focusRing.rootOffset',
  'focusRing.rootColor',
  'closeButton.radius',
};

/// 동작 · 자리 테스트가 보는 값 — 쌓임(오버레이가 늘 위) · 화면 가장자리 간격 · 화살표와 모서리 간격 · 누르는 영역 44.
const _behavior = {
  'root.zIndex',
  'root.margin',
  'root.marginMin',
  'root.announce',
  'arrow.margin',
  'arrow.position',
  'closeButton.touchTarget',
};

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['closeButton'])) {
      final shown = combo['closeButton'] == 'shown';
      final fullCombo = {'opens': 'press', ...combo};
      // 누를 것은 닫기 버튼뿐 — 닫기 버튼이 없으면 누름 상태가 없다
      for (final state in shown ? ['enabled', 'pressed'] : ['enabled']) {
        final title = '${mode.name} 닫기 버튼 ${combo['closeButton']} $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          await tester.pumpWidget(
            _host(
              mode,
              Center(child: _bubble(showCloseButton: shown, open: true)),
            ),
          );
          await _settle(tester);
          TestGesture? gesture;
          if (state == 'pressed') {
            gesture = await tester.startGesture(tester.getCenter(_closeBox));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
          }
          final k = _Check(mode, _spec.resolve(fullCombo, state), title);
          final measured = <String>{};
          void m(Iterable<String> keys) => measured.addAll(keys);

          final target = tester.getRect(_triggerFinder);
          final body = tester.getRect(_bodyFinder);
          final placement = _layout(tester).placement;

          // 말풍선 — 최대 폭 · 안쪽 여백 · 모서리 · 바탕 · 그림자 없음
          final deco =
              tester.widget<DecoratedBox>(_bodyFinder).decoration
                  as BoxDecoration;
          k.px('root.maxWidth', body.width);
          final titleRect = tester.getRect(_titleFinder);
          final descRect = tester.getRect(_descFinder);
          k.px('root.paddingX', titleRect.left - body.left);
          k.px('root.paddingY', titleRect.top - body.top);
          k.px('root.paddingY', body.bottom - descRect.bottom);
          if (!shown) k.px('root.paddingX', body.right - descRect.right);
          k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
          k.color('root.background', deco.color!);
          if (k.want['root.shadow'] == 'none' &&
              (deco.boxShadow?.isNotEmpty ?? false)) {
            k.fail('root.shadow: 스펙 none · 그림자가 있다');
          }
          // 화살표 끝 ↔ 트리거 4 — 몸통과는 화살표 높이를 더한 12
          k.px('root.offset', target.top - placement.tip.dy);
          k.px(
            'root.offset',
            target.top - body.bottom - (k.want['arrow.height'] as num),
          );
          m([
            'root.maxWidth',
            'root.paddingX',
            'root.paddingY',
            'root.radius',
            'root.background',
            'root.shadow',
            'root.offset',
          ]);

          // 화살표 — 12 × 8 · 말풍선과 같은 색, 트리거 가운데를 가리킨다
          k.px('arrow.width', placement.arrow.width);
          k.px('arrow.height', placement.arrow.height);
          if ((placement.tip.dx - target.center.dx).abs() > 0.5) {
            k.fail('arrow: 트리거 가운데를 가리키지 않는다 ${placement.tip} · $target');
          }
          m(['arrow.width', 'arrow.height']);

          // 제목 · 설명 — t3 13 / 18, 700 · 400, 말풍선 글자색, 제목 ↔ 설명 2
          final title_ = tester.widget<Text>(_titleFinder).style!;
          final desc_ = tester.widget<Text>(_descFinder).style!;
          k.typo('title.typography', title_);
          k.weight('title.fontWeight', title_);
          k.color('title.foreground', title_.color!);
          k.typo('description.typography', desc_);
          k.weight('description.fontWeight', desc_);
          k.color('description.foreground', desc_.color!);
          k.px('description.gap', descRect.top - titleRect.bottom);
          m([
            'title.typography',
            'title.fontWeight',
            'title.foreground',
            'description.typography',
            'description.fontWeight',
            'description.foreground',
            'description.gap',
          ]);

          // 닫기 버튼 — 38 상자가 오른쪽 위 모서리에 붙는다(위 0 · 오른쪽 0), 글과 4, 아이콘 14 · 말풍선 글자색
          if (shown) {
            final box = tester.getRect(_closeBox);
            // 누르는 동안은 아이콘 상자가 줄어 보인다 — 놓인 크기는 그대로다
            final boxSize = tester.getSize(_closeBox);
            k.px('closeButton.size', boxSize.width);
            k.px('closeButton.size', boxSize.height);
            // 놓인 자리(누름 축소 전) — 상자 가운데가 몸통 오른쪽 위 모서리에서 (−19, +19)
            final seat = Offset(
              body.right - boxSize.width / 2,
              body.top + boxSize.height / 2,
            );
            if ((box.center - seat).distance > 0.5) {
              k.fail('closeButton: 오른쪽 위 모서리에 붙지 않았다 $box · $body');
            }
            // 글(줄바꿈한 설명의 오른쪽 끝)과 상자 사이 4 — 상자는 몸통 오른쪽 끝에서 38
            final gap = (body.right - boxSize.width) - descRect.right;
            if ((gap - 4).abs() > 0.5) {
              k.fail('closeButton: 글과 상자 사이 4 · 실제 $gap');
            }
            final icon = tester.widget<Icon>(_closeIcon);
            k.px('closeButton.iconSize', icon.size!);
            k.color('closeButton.color', icon.color!);
            if (icon.icon != LucideIcons.x) k.fail('closeButton 아이콘이 x 가 아니다');
            // 아이콘은 상자 가운데(위 12 · 오른쪽 12 자리)
            final iconRect = tester.getRect(_closeIcon);
            if ((iconRect.center - box.center).distance > 0.5) {
              k.fail('closeButton.iconSize: 아이콘이 상자 가운데가 아니다');
            }
            // 누름 — 아이콘만 2px 거리 줄고(기준 38) 상자는 그대로
            final scale = tester.widget<AnimatedScale>(
              find
                  .ancestor(of: _closeBox, matching: find.byType(AnimatedScale))
                  .first,
            );
            k.pressScale('closeButton.scale', scale.scale, boxSize);
            k.motion(
              'closeButton.scaleDuration',
              'closeButton.scaleEasing',
              scale.duration,
              scale.curve,
            );
            m([
              'closeButton.size',
              'closeButton.iconSize',
              'closeButton.color',
              'closeButton.scale',
              'closeButton.scaleDuration',
              'closeButton.scaleEasing',
            ]);
          } else {
            expect(_closeBox, findsNothing, reason: title);
          }

          k.coverage(measured, {..._webOnly, ..._behavior});
          await gesture?.up();
          await tester.pump(const Duration(milliseconds: 400));
          if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
        });
      }
    }
  }

  group('말풍선 크기', () {
    testWidgets('한 줄 제목은 38, 설명 한 줄이 붙으면 58 — 폭은 내용만큼이다(최대 280)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(child: _bubble(description: null, open: true)),
        ),
      );
      await _settle(tester);
      expect(tester.getSize(_bodyFinder).height, 38);
      // 폭 = 글 폭 + 좌우 12 — Ahem 은 글자마다 13
      expect(tester.getSize(_bodyFinder).width, 8 * 13 + 24);

      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(child: _bubble(description: '짧은 설명', open: true)),
        ),
      );
      await _settle(tester);
      expect(tester.getSize(_bodyFinder).height, 58);
      expect(tester.getSize(_bodyFinder).width, 8 * 13 + 24);
    });

    testWidgets('쓸 수 있는 폭(화면 − 양쪽 16)이 280 보다 좁으면 그만큼이다', (tester) async {
      tester.view.physicalSize = const Size(250, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _bubble(open: true))),
      );
      await _settle(tester);
      expect(tester.getSize(_bodyFinder).width, 250 - 32);
      expect(tester.getRect(_bodyFinder).left, 16);
    });

    testWidgets('줄바꿈 문자는 살리고 낱말 단위로 줄이 바뀐다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: _bubble(title: '첫 줄\n둘째 줄', description: null, open: true),
          ),
        ),
      );
      await _settle(tester);
      // 두 줄 — 18 × 2 + 위아래 10
      expect(tester.getSize(_bodyFinder).height, 56);
    });
  });

  group('놓는 자리', () {
    const view = Size(400, 600);

    HelpBubblePlacement place(
      Rect target, {
      Size bubble = const Size(200, 58),
      PHelpBubbleSide side = PHelpBubbleSide.top,
    }) => placeHelpBubble(
      target: target,
      bubble: bubble,
      viewport: view,
      preferred: side,
    );

    test('기본은 트리거 위 — 몸통은 12 떨어지고 화살표 끝은 4, 화살표는 가운데를 가리킨다', () {
      const target = Rect.fromLTWH(180, 300, 40, 40);
      final p = place(target);
      expect(p.side, PHelpBubbleSide.top);
      expect(p.body, const Rect.fromLTWH(100, 230, 200, 58));
      expect(p.arrow, const Rect.fromLTWH(194, 288, 12, 8));
      expect(p.tip, const Offset(200, 296));
      expect(target.top - p.tip.dy, helpBubbleOffset);
      expect(
        target.top - p.body.bottom,
        helpBubbleOffset + helpBubbleArrowHeight,
      );
    });

    test('아래 · 옆도 같다 — 몸통 12 · 화살표 끝 4, 화살표는 늘 트리거 가운데', () {
      const target = Rect.fromLTWH(180, 300, 40, 40);
      final bottom = place(target, side: PHelpBubbleSide.bottom);
      expect(bottom.side, PHelpBubbleSide.bottom);
      expect(bottom.body.top - target.bottom, 12);
      expect(bottom.tip, Offset(200, target.bottom + 4));
      expect(bottom.arrow.size, const Size(12, 8));

      final right = place(
        const Rect.fromLTWH(20, 300, 40, 40),
        side: PHelpBubbleSide.right,
      );
      expect(right.side, PHelpBubbleSide.right);
      expect(right.body.left - 60, 12);
      expect(right.tip, const Offset(64, 320));
      expect(right.arrow.size, const Size(8, 12));

      final left = place(
        const Rect.fromLTWH(340, 300, 40, 40),
        side: PHelpBubbleSide.left,
      );
      expect(left.side, PHelpBubbleSide.left);
      expect(340 - left.body.right, 12);
      expect(left.tip, const Offset(336, 320));
    });

    test('위에 가장자리 16 이 안 남으면 아래로 뒤집는다 — 아래도 안 되면 넘침이 적은 쪽', () {
      // 위: 트리거 위 (60 − 12 − 58 = −10) 가 16 에 못 미친다 → 아래
      final flipped = place(const Rect.fromLTWH(180, 60, 40, 40));
      expect(flipped.side, PHelpBubbleSide.bottom);
      expect(flipped.body.top, 60 + 40 + 12);
      // 정확히 16 남으면 그대로 위
      final exact = place(const Rect.fromLTWH(180, 16 + 58 + 12, 40, 40));
      expect(exact.side, PHelpBubbleSide.top);
      expect(exact.body.top, 16);
      // 1px 모자라면 뒤집는다
      final short = place(const Rect.fromLTWH(180, 16 + 58 + 12 - 1, 40, 40));
      expect(short.side, PHelpBubbleSide.bottom);
      // 양쪽 다 안 들어가면 넘침이 적은 쪽(키 큰 말풍선)
      final tall = place(
        const Rect.fromLTWH(180, 250, 40, 40),
        bubble: const Size(200, 400),
      );
      // 위 넘침 = 16 − (250 − 12 − 400) = 178, 아래 넘침 = 290 + 12 + 400 − 584 = 118
      expect(tall.side, PHelpBubbleSide.bottom);
    });

    test('옆으로 밀어 가장자리 16 을 남긴다 — 화살표는 그래도 트리거 가운데를 가리킨다', () {
      // 왼쪽 가장자리 트리거(왼쪽 여백 16) — 가운데 x = 36 → 말풍선은 16 에서 시작하고 화살표는 가운데를 가리킨다
      final left = place(const Rect.fromLTWH(16, 300, 40, 40));
      expect(left.body.left, helpBubbleMargin);
      expect(left.tip.dx, 36);
      expect(left.arrowOffset, 36 - 6 - 16);
      // 오른쪽 가장자리
      final right = place(const Rect.fromLTWH(344, 300, 40, 40));
      expect(right.body.right, 400 - helpBubbleMargin);
      expect(right.tip.dx, 364);
      // 말풍선이 화면보다 넓으면 왼쪽 가장자리에 맞춘다
      final wide = place(
        const Rect.fromLTWH(180, 300, 40, 40),
        bubble: const Size(400, 58),
      );
      expect(wide.body.left, helpBubbleMargin);
    });

    test('화살표는 늘 트리거 가운데 — 몸통이 끝으로 밀리고 16 은 0 까지 진다(Q-004), 끝에서 20 안쪽이 남는다', () {
      // 트리거 가운데 x = 22: 가장자리 여백은 22 − 20 = 2 로 줄어 몸통이 2 에서 시작하고, 화살표는 가운데를 가리킨다
      final p = place(const Rect.fromLTWH(2, 300, 40, 40));
      expect(p.body.left, 2);
      expect(p.tip.dx, 22);
      expect(p.arrowOffset, helpBubbleArrowMargin);
      // 왼쪽 끝 0 에 붙은 ⓘ 40 — 가운데 20 → 몸통도 0, 화살표는 모서리에서 14
      final zero = place(const Rect.fromLTWH(0, 300, 40, 40));
      expect(zero.body.left, 0);
      expect(zero.tip.dx, 20);
      expect(zero.arrowOffset, helpBubbleArrowMargin);
      // 오른쪽 끝도 같다
      final q = place(const Rect.fromLTWH(358, 300, 40, 40));
      expect(q.body.right, 400 - 2);
      expect(q.tip.dx, 378);
      expect(q.body.right - q.arrow.right, helpBubbleArrowMargin);
      // 상단 바 끝 금액 가리기(가운데가 끝에서 28) → 끝 8(스펙 예)
      final bar = place(const Rect.fromLTWH(352, 300, 40, 40));
      expect(bar.body.right, 400 - 8);
      expect(bar.tip.dx, 372);
      // 옆에 붙는 한 줄 말풍선(높이 38) — 14 를 남기면 화살표(12)가 들어갈 틈이 모자라 12 · 14 안으로
      final side = place(
        const Rect.fromLTWH(20, 300, 40, 40),
        bubble: const Size(200, 38),
        side: PHelpBubbleSide.right,
      );
      expect(side.arrowOffset, inInclusiveRange(12, 14));
      expect(side.arrow.top, greaterThanOrEqualTo(side.body.top));
      expect(side.arrow.bottom, lessThanOrEqualTo(side.body.bottom));
    });

    testWidgets('그려진 말풍선이 같은 자리에 선다 — 화면 가장자리 · 뒤집기 · 최대 폭', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // 왼쪽 위 모서리 트리거 — 위가 모자라 아래로 뒤집히고 옆으로 밀린다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: _bubble(open: true),
            ),
          ),
        ),
      );
      await _settle(tester);
      final layout = _layout(tester);
      final target = tester.getRect(_triggerFinder);
      final body = tester.getRect(_bodyFinder);
      expect(layout.placement.side, PHelpBubbleSide.bottom);
      expect(body.left, helpBubbleMargin);
      expect(body.top, closeTo(target.bottom + 12, 0.01));
      expect(body.width, 280);
      expect(layout.placement.tip.dx, closeTo(target.center.dx, 0.01));
      expect(layout.placement.tip.dy, closeTo(target.bottom + 4, 0.01));
    });
  });

  group('화면 안에 든다 — 큰 글자(QA 2026-11-25 금액 가리기 ⓘ)', () {
    // iPhone 17 Pro — 393 × 852, 안전 영역 위 59 · 아래 34
    const phone = Size(393, 852);
    const safeTop = 59.0;
    const safeBottom = 34.0;
    const kindTitle = '거래 종류';
    const kindNote =
        '화면과 상관없이 그 종류의 거래 금액을 가려요. 수입이나 지출을 가리면 합계 · 잔액도 함께 가려져요.';

    test('안전 영역 경계부터 16 — 위에 안 들면 아래로, 양쪽 다 안 들면 넓은 쪽에 그 공간만큼의 높이', () {
      const safe = EdgeInsets.only(top: safeTop, bottom: safeBottom);
      // 100% 한 줄 말풍선, 위 90 의 ⓘ — 안전 영역이 없으면 위에 든다(90 − 12 − 58 = 20 ≥ 16)
      final noSafe = placeHelpBubble(
        target: const Rect.fromLTWH(330, 90, 40, 40),
        bubble: const Size(200, 58),
        viewport: phone,
      );
      expect(noSafe.side, PHelpBubbleSide.top);
      // 상태 표시줄 59 가 있으면 16 은 그 아래부터라 위에 안 든다(90 − 12 − 58 = 20 < 59 + 16) → 아래로, 높이는 그대로
      final top = placeHelpBubble(
        target: const Rect.fromLTWH(330, 90, 40, 40),
        bubble: const Size(200, 58),
        viewport: phone,
        safeArea: safe,
      );
      expect(top.side, PHelpBubbleSide.bottom);
      expect(top.body.height, 58);
      // 키 큰 말풍선(600) — 위 공간 400 − 12 − 75 = 313, 아래 공간 852 − 34 − 16 − 440 − 12 = 350 → 아래, 높이 350
      final tall = placeHelpBubble(
        target: const Rect.fromLTWH(330, 400, 40, 40),
        bubble: const Size(280, 600),
        viewport: phone,
        safeArea: safe,
      );
      expect(tall.side, PHelpBubbleSide.bottom);
      expect(tall.body.top, 452);
      expect(tall.body.bottom, phone.height - safeBottom - helpBubbleMargin);
      // 위 공간이 더 넓으면 위 — 몸통 위 끝은 안전 영역 + 16
      final up = placeHelpBubble(
        target: const Rect.fromLTWH(330, 600, 40, 40),
        bubble: const Size(280, 900),
        viewport: phone,
        safeArea: safe,
      );
      expect(up.side, PHelpBubbleSide.top);
      expect(up.body.top, safeTop + helpBubbleMargin);
      expect(up.body.bottom, 600 - 12);
      // 화살표는 그대로 트리거 가운데 · 끝과 4
      expect(up.tip, const Offset(350, 596));
      // 옆 말풍선 — 화면 높이(안전 영역 안) − 위아래 16 까지
      final side = placeHelpBubble(
        target: const Rect.fromLTWH(20, 400, 40, 40),
        bubble: const Size(200, 2000),
        viewport: phone,
        safeArea: safe,
        preferred: PHelpBubbleSide.right,
      );
      expect(side.body.height, phone.height - safeTop - safeBottom - 32);
      expect(side.body.top, safeTop + helpBubbleMargin);
    });

    /// 393 × 852 · 안전 영역 59 / 34 화면의 [at] 자리에 ⓘ(PButton small)를 두고 연다. 말풍선 자리의 MediaQuery 는 앱 바가
    /// 있는 화면처럼 위 · 아래 여백을 지운다 — 말풍선은 오버레이 쪽 안전 영역을 읽어야 한다.
    Future<void> openAt(WidgetTester tester, Offset at, double scale) async {
      tester.view.physicalSize = phone;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        top: safeTop,
        bottom: safeBottom,
      );
      tester.view.viewPadding = const FakeViewPadding(
        top: safeTop,
        bottom: safeBottom,
      );
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Builder(
            builder: (context) => MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: Stack(
                children: [
                  Positioned(
                    left: at.dx,
                    top: at.dy,
                    child: PHelpBubble(
                      title: kindTitle,
                      description: kindNote,
                      triggerBuilder: (context, toggle, open) => PButton.icon(
                        icon: LucideIcons.info,
                        semanticLabel: '거래 종류 안내',
                        variant: PButtonVariant.ghost,
                        size: PButtonSize.small,
                        onPressed: toggle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PButton));
      await _settle(tester);
    }

    // 화면 안 = 안전 영역 + 16 안
    void expectInside(WidgetTester tester) {
      final body = tester.getRect(_bodyFinder);
      expect(body.top, greaterThanOrEqualTo(safeTop + helpBubbleMargin - 0.01));
      expect(
        body.bottom,
        lessThanOrEqualTo(phone.height - safeBottom - helpBubbleMargin + 0.01),
      );
      expect(body.left, greaterThanOrEqualTo(0));
      expect(body.right, lessThanOrEqualTo(phone.width));
      // 화살표는 트리거 가운데를 가리키고 끝과 4
      final target = tester.getRect(find.byType(PButton));
      final p = _layout(tester).placement;
      expect(p.tip.dx, closeTo(target.center.dx, 0.01));
      expect(
        p.side == PHelpBubbleSide.top
            ? target.top - p.tip.dy
            : p.tip.dy - target.bottom,
        closeTo(helpBubbleOffset, 0.01),
      );
    }

    /// 글을 끝까지 내리면 마지막 줄이 말풍선 안(아래 여백 10 위)에 보인다.
    Future<void> expectLastLineReachable(WidgetTester tester) async {
      final scrollable = find.descendant(
        of: _bodyFinder,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0), reason: '넘치면 스크롤');
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final body = tester.getRect(_bodyFinder);
      final desc = tester.getRect(_descFinder);
      expect(desc.bottom, closeTo(body.bottom - PSpacing.x2_5, 0.01));
      expect(tester.takeException(), isNull);
    }

    // (글자 크기, 이름) — iOS AX5 는 선형 3.1 정도, 안드로이드는 200%
    for (final (scale, name) in [(3.1, 'iOS AX5'), (2.0, '안드 200%')]) {
      for (final (y, where) in [
        (400.0, '가운데(QA 자리)'),
        (760.0, '아래쪽'),
        (90.0, '위쪽'),
      ]) {
        testWidgets('$name · ⓘ $where — 말풍선이 화면 안에 들고 마지막 줄까지 스크롤된다', (
          tester,
        ) async {
          await openAt(tester, Offset(337, y), scale);
          expectInside(tester);
          final body = tester.getRect(_bodyFinder);
          final desc = tester.getRect(_descFinder);
          if (desc.bottom > body.bottom - PSpacing.x2_5 + 0.01) {
            await expectLastLineReachable(tester);
          }
          // 큰 글자에서 글은 커지고 화살표는 그대로
          expect(_layout(tester).placement.arrow.shortestSide, 8);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('iOS AX5 · ⓘ 가운데 — 몸통이 남는 공간에 맞춰 줄고 넘친 글은 안에서 스크롤한다', (
      tester,
    ) async {
      await openAt(tester, const Offset(337, 400), 3.1);
      final body = tester.getRect(_bodyFinder);
      final p = _layout(tester).placement;
      // 위 공간(400 − 12 − 75 = 313) < 아래 공간(818 − 16 − 440 − 12 = 350 … 트리거 40) → 넓은 아래, 아래 끝은 안전 영역 + 16
      expect(p.side, PHelpBubbleSide.bottom);
      expect(body.bottom, closeTo(phone.height - safeBottom - 16, 0.01));
      await expectLastLineReachable(tester);
    });

    testWidgets('100% — 지금 모양 그대로: 위로 뜨고 내용만큼, 스크롤 없음', (tester) async {
      await openAt(tester, const Offset(337, 400), 1);
      final target = tester.getRect(find.byType(PButton));
      final body = tester.getRect(_bodyFinder);
      final p = _layout(tester).placement;
      expect(p.side, PHelpBubbleSide.top);
      expect(body.bottom, closeTo(target.top - 12, 0.01));
      expect(body.width, 280);
      // 높이는 내용 그대로 — 글이 다 보이고 스크롤할 것이 없다
      final desc = tester.getRect(_descFinder);
      expect(desc.bottom, closeTo(body.bottom - PSpacing.x2_5, 0.01));
      final scrollable = find.descendant(
        of: _bodyFinder,
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        0,
      );
    });
  });

  group('여닫기', () {
    testWidgets('트리거를 누르면 열고 다시 누르면 닫는다 — 닫힘은 투명해진 뒤 내려간다', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(child: _bubble(onOpenChange: calls.add)),
        ),
      );
      expect(_bodyFinder, findsNothing);
      await tester.tap(_triggerFinder);
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);
      expect(calls, [true]);
      await tester.tap(_triggerFinder);
      await tester.pump();
      // 닫히는 중 — 아직 있고 투명해지는 중
      await tester.pump(const Duration(milliseconds: 100));
      expect(_bodyFinder, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(_bodyFinder, findsNothing);
      expect(calls, [true, false]);
    });

    testWidgets('바깥을 누르면 닫는다 — 뒤 화면은 그대로 눌린다(비모달)', (tester) async {
      var pageTaps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: 100,
                height: 100,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => pageTaps++,
                ),
              ),
              Center(child: _bubble()),
            ],
          ),
        ),
      );
      await tester.tap(_triggerFinder);
      await _settle(tester);
      await tester.tapAt(const Offset(50, 50));
      await _settle(tester);
      expect(_bodyFinder, findsNothing);
      // 닫는 누름이 뒤 화면도 눌렀다 — 말풍선이 뒤 화면을 막지 않는다
      expect(pageTaps, 1);
    });

    testWidgets('말풍선 안을 누르면 닫히지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _bubble())),
      );
      await tester.tap(_triggerFinder);
      await _settle(tester);
      await tester.tap(_titleFinder);
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);
    });

    testWidgets('closeOnInteractOutside 를 끄면 바깥 누르기에 닫지 않는다 — 닫기 버튼으로 닫는다', (
      tester,
    ) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: _bubble(
              showCloseButton: true,
              closeOnInteractOutside: false,
              onOpenChange: calls.add,
            ),
          ),
        ),
      );
      await tester.tap(_triggerFinder);
      await _settle(tester);
      await tester.tapAt(const Offset(5, 5));
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);
      expect(calls, [true]);
      await tester.tap(_closeBox);
      await _settle(tester);
      expect(_bodyFinder, findsNothing);
      expect(calls, [true, false]);
    });

    testWidgets('처음부터 열어 둘 수 있다 — 초점은 옮기지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(child: _bubble(defaultOpen: true, showCloseButton: true)),
        ),
      );
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel ?? '',
        isNot(contains('PHelpBubble')),
      );
    });

    testWidgets('열림을 쓰는 쪽이 쥐면 닫기 버튼은 알리기만 하고 여닫음은 쓰는 쪽이 정한다', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: _bubble(
              open: true,
              showCloseButton: true,
              onOpenChange: calls.add,
            ),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(_closeBox);
      await _settle(tester);
      expect(calls, [false]);
      expect(_bodyFinder, findsOneWidget);

      // 쓰는 쪽이 닫으면 닫힌다 · 다시 열면 열린다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: _bubble(
              open: false,
              showCloseButton: true,
              onOpenChange: calls.add,
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bodyFinder, findsNothing);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: _bubble(
              open: true,
              showCloseButton: true,
              onOpenChange: calls.add,
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);
    });

    testWidgets('기준(anchor)은 자리만 잡는다 — 눌러도 열고 닫지 않고, 팝업 의미를 달지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var anchorTaps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: PHelpBubble.anchor(
              title: '금액을 가릴 수 있어요',
              description: '누르면 화면의 금액이 모두 가려져요.',
              showCloseButton: true,
              closeOnInteractOutside: false,
              side: PHelpBubbleSide.bottom,
              defaultOpen: true,
              anchor: GestureDetector(
                key: const ValueKey('trigger'),
                behavior: HitTestBehavior.opaque,
                onTap: () => anchorTaps++,
                child: Semantics(
                  label: '금액 가리기',
                  button: true,
                  child: const SizedBox.square(dimension: 40),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(_layout(tester).placement.side, PHelpBubbleSide.bottom);
      // 눌러도 말풍선은 그대로 — 기준의 원래 동작만
      await tester.tap(_triggerFinder);
      await _settle(tester);
      expect(anchorTaps, 1);
      expect(_bodyFinder, findsOneWidget);
      // 팝업 의미(열림)를 달지 않는다
      expect(
        tester.getSemantics(find.bySemanticsLabel('금액 가리기')),
        isSemantics(label: '금액 가리기', isButton: true, hasExpandedState: false),
      );
      semantics.dispose();
    });
  });

  group('움직임', () {
    testWidgets('열림은 200ms 에 화살표 끝에서 0.9 → 1 · 투명도 0 → 1 — 모션 줄이기면 크기는 그대로', (
      tester,
    ) async {
      final motion = (_spec.json['motion'] as Map)['열림'] as Map;
      final duration = specMs(motion['duration']);
      final cubic = specCubic(motion['easing']);
      expect(PDuration.d4, duration);
      expect(_cubicOf(PEasing.enter), cubic);

      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            Center(child: _bubble()),
            reduceMotion: reduce,
          ),
        );
        await tester.tap(_triggerFinder);
        await tester.pump();
        await tester.pump();
        final layout = _layout(tester);
        final start = layout.look();
        expect(start.opacity, closeTo(0, 0.05), reason: 'reduce=$reduce');
        expect(start.scale, closeTo(reduce ? 1 : 0.9, 0.02));
        await tester.pump(duration ~/ 2);
        final mid = layout.look();
        expect(mid.opacity, inExclusiveRange(0.05, 0.99));
        if (reduce) {
          expect(mid.scale, 1);
        } else {
          expect(mid.scale, inExclusiveRange(0.9, 1));
        }
        await tester.pump(duration);
        expect(layout.look(), (opacity: 1.0, scale: 1.0));
        // 닫는다 — 투명도만, 크기는 그대로
        await tester.tap(_triggerFinder);
        await tester.pump();
        await tester.pump(duration ~/ 2);
        final closing = layout.look();
        expect(closing.opacity, inExclusiveRange(0.01, 0.99));
        expect(closing.scale, 1);
        await tester.pump(duration);
        await tester.pump();
      }
    });

    testWidgets('닫는 모션 값은 스펙 — 200ms · easing · 투명도', (tester) async {
      final motion = (_spec.json['motion'] as Map)['닫힘'] as Map;
      expect(PDuration.d4, specMs(motion['duration']));
      final cubic = specCubic(motion['easing']);
      expect(_cubicOf(PEasing.easing), cubic);
    });

    testWidgets('트리거가 움직이면 말풍선이 따라간다 — 스크롤', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          ListView(
            controller: controller,
            children: [
              const SizedBox(height: 300),
              Center(
                child: _bubble(defaultOpen: true, side: PHelpBubbleSide.top),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      );
      await _settle(tester);
      final before = tester.getRect(_bodyFinder);
      final targetBefore = tester.getRect(_triggerFinder);
      controller.jumpTo(80);
      await tester.pump();
      final after = tester.getRect(_bodyFinder);
      final targetAfter = tester.getRect(_triggerFinder);
      expect(targetAfter.top, targetBefore.top - 80);
      expect(after.top, closeTo(before.top - 80, 0.01));
    });
  });

  group('키보드', () {
    testWidgets(
      '열린 동안 트리거에서 Tab — 말풍선(닫기 버튼이 있으면 그것)으로, 다시 Tab 이면 닫고 초점은 트리거로',
      (tester) async {
        final after = FocusNode();
        addTearDown(after.dispose);
        await tester.pumpWidget(
          _host(
            Brightness.light,
            Column(
              children: [
                PHelpBubble(
                  title: _title,
                  description: _description,
                  showCloseButton: true,
                  triggerBuilder: (context, toggle, open) =>
                      _focusTrigger(toggle),
                ),
                Focus(focusNode: after, child: const SizedBox(height: 10)),
              ],
            ),
          ),
        );
        // 트리거에 초점을 두고 연다 — 초점은 옮기지 않는다
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final triggerFocus = FocusManager.instance.primaryFocus!;
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _settle(tester);
        expect(_bodyFinder, findsOneWidget);
        expect(FocusManager.instance.primaryFocus, triggerFocus);
        // Tab — 닫기 버튼으로
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'PHelpBubble close',
        );
        // Shift+Tab — 트리거로, 말풍선은 열린 채
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, triggerFocus);
        expect(_bodyFinder, findsOneWidget);
        // 다시 들어가 Tab — 닫고 트리거 다음 칸으로
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await _settle(tester);
        expect(_bodyFinder, findsNothing);
        expect(after.hasPrimaryFocus, isTrue);
      },
    );

    testWidgets('닫기 버튼이 없으면 Tab 은 말풍선 자체로 — Space · Enter 로 닫기 버튼을 누른다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: PHelpBubble(
              title: _title,
              triggerBuilder: (context, toggle, open) => _focusTrigger(toggle),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'PHelpBubble');
    });

    testWidgets('Esc 는 닫는다 — 초점이 말풍선 안에 있었으면 트리거로', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: PHelpBubble(
              title: _title,
              showCloseButton: true,
              triggerBuilder: (context, toggle, open) => _focusTrigger(toggle),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final triggerFocus = FocusManager.instance.primaryFocus!;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      // 트리거에서 Esc
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(_bodyFinder, findsNothing);
      expect(FocusManager.instance.primaryFocus, triggerFocus);

      // 말풍선 안에서 Esc — 초점은 트리거로 돌아온다
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNot(triggerFocus));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(_bodyFinder, findsNothing);
      expect(FocusManager.instance.primaryFocus, triggerFocus);
    });

    testWidgets('초점이 트리거 · 말풍선 밖으로 나가면 닫는다 — 끄면 닫지 않고, 처음부터 밖에 있던 초점은 보지 않는다', (
      tester,
    ) async {
      final outside = FocusNode();
      addTearDown(outside.dispose);
      Widget page({required bool closeOnOutside, bool defaultOpen = false}) =>
          _host(
            Brightness.light,
            Column(
              children: [
                PHelpBubble(
                  title: _title,
                  showCloseButton: true,
                  closeOnInteractOutside: closeOnOutside,
                  defaultOpen: defaultOpen,
                  triggerBuilder: (context, toggle, open) =>
                      _focusTrigger(toggle),
                ),
                Focus(focusNode: outside, child: const SizedBox(height: 10)),
              ],
            ),
          );
      // 켬 — 트리거에 초점이 있다가 밖으로 가면 닫힌다
      await tester.pumpWidget(page(closeOnOutside: true));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);
      outside.requestFocus();
      await _settle(tester);
      expect(_bodyFinder, findsNothing);

      // 끔 — 닫지 않는다
      await tester.pumpWidget(page(closeOnOutside: false));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      outside.requestFocus();
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);

      // 처음부터 열어 둔 안내 — 초점이 아직 안에 들어온 적 없으면 첫 초점 이동에 사라지지 않는다
      await tester.pumpWidget(page(closeOnOutside: true, defaultOpen: true));
      await _settle(tester);
      outside.requestFocus();
      await _settle(tester);
      expect(_bodyFinder, findsOneWidget);
    });

    testWidgets('닫기 버튼은 Space · Enter 로 눌러 닫고 초점은 트리거로', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: PHelpBubble(
              title: _title,
              showCloseButton: true,
              triggerBuilder: (context, toggle, open) => _focusTrigger(toggle),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final triggerFocus = FocusManager.instance.primaryFocus!;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester);
      expect(_bodyFinder, findsNothing);
      expect(FocusManager.instance.primaryFocus, triggerFocus);
    });
  });

  group('누르는 영역 · 읽는 말', () {
    testWidgets('닫기 버튼의 누르는 영역은 38 상자의 사방 3 을 넓힌 44 — 말풍선 안쪽까지다', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: _bubble(
              showCloseButton: true,
              open: true,
              onOpenChange: (_) => closed++,
            ),
          ),
        ),
      );
      await _settle(tester);
      final box = tester.getRect(_closeBox);
      expect(box.size, const Size.square(38));
      // 상자 왼쪽 3 밖 — 44 안이다
      await tester.tapAt(Offset(box.left - 2.5, box.center.dy));
      expect(closed, 1);
      // 상자 왼쪽 4 밖 — 44 밖이다(글 자리)
      await tester.tapAt(Offset(box.left - 4, box.center.dy));
      expect(closed, 1);
      // 말풍선 모서리 안쪽 끝도 닫기 버튼이다
      final body = tester.getRect(_bodyFinder);
      await tester.tapAt(body.topRight + const Offset(-1, 1));
      expect(closed, 2);
    });

    testWidgets(
      '말풍선은 dialog 로 제목 · 설명을 읽고 열릴 때 알린다 — 닫기 버튼은 "닫기", 트리거는 열림을 읽는다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Brightness.light,
            Center(
              child: PHelpBubble(
                title: _title,
                description: _description,
                showCloseButton: true,
                triggerBuilder: (context, toggle, open) => PButton.icon(
                  icon: LucideIcons.info,
                  semanticLabel: '연차 사용 규정 안내',
                  onPressed: toggle,
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('연차 사용 규정 안내')),
          isSemantics(hasExpandedState: true, isExpanded: false),
        );
        await tester.tap(find.byType(PButton));
        await _settle(tester);
        expect(
          tester.getSemantics(find.bySemanticsLabel('연차 사용 규정 안내')),
          isSemantics(hasExpandedState: true, isExpanded: true),
        );
        final dialog = tester.getSemantics(
          find.bySemanticsLabel(RegExp('^$_title\n')),
        );
        expect(dialog.getSemanticsData().role, SemanticsRole.dialog);
        expect(dialog.label, contains(_description));
        expect(dialog.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
        expect(
          tester.getSemantics(find.bySemanticsLabel('닫기')),
          isSemantics(label: '닫기', isButton: true, hasTapAction: true),
        );
        semantics.dispose();
      },
    );
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 견본이 열린 말풍선 · 자리 · 직접 열어 보기를 모두 그린다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          mode,
          const SingleChildScrollView(
            padding: EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
            child: HelpBubbleDemo(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // 늘 열린 말풍선 일곱 — 제목만 · 설명 · 닫기 · 위→아래 뒤집기 · 왼쪽 가장자리 · 아래 · 옆
      expect(find.byType(HelpBubbleLayout), findsNWidgets(7));
      expect(tester.takeException(), isNull);
      // 뒤집기 — 위쪽 가장자리의 ⓘ 는 아래로
      final sides = [
        for (final e in find.byType(HelpBubbleLayout).evaluate())
          (e.renderObject! as RenderHelpBubbleLayout).placement.side,
      ];
      expect(sides, contains(PHelpBubbleSide.bottom));
      expect(sides, contains(PHelpBubbleSide.right));
      expect(sides, contains(PHelpBubbleSide.top));
      // 말풍선은 무대(폭 300 · 높이 160)를 벗어나지 않는다
      for (final e in find.byType(HelpBubbleLayout).evaluate()) {
        final stage = (e.renderObject! as RenderBox).size;
        expect(stage, const Size(300, 160));
      }
    });
  }
}
