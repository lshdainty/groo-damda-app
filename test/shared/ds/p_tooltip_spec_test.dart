// Tooltip 이 스펙 값(test/fixtures/design_spec/help-bubble.json 의 `opens: hover` — Tooltip 전용 JSON 은 없다)대로인지 —
// 라이트 · 다크의 말풍선 · 화살표 · 글, 여는 법(마우스 200ms · 닫기 100ms · 키보드 바로 · 이어서 옮기면 바로 · 손가락은 열지 않음),
// 읽는 말, "이름 · 막힌 이유를 툴팁에만 두지 않는다" 규칙. 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 문장으로 된 값은 그린 결과나 동작으로 본다 — 자리 값(offset · margin · arrow.margin)은 놓은 결과로, 시간은 흐르는 시간으로 잰다.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/help_bubble_layout.dart';
import 'package:groo_damda_app/shared/ds/tooltip/p_tooltip.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('help-bubble');

const _hover = {'opens': 'hover', 'closeButton': 'hidden'};

Widget _host(Brightness mode, Widget child, {bool reduceMotion = false}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: child),
  );
  return reduceMotion
      ? MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            disableAnimations: true,
          ),
          child: app,
        )
      : app;
}

/// 트리거 — 키보드 초점을 받는 아이콘 버튼 모양 칸. 이름은 [name](웹 aria-label).
Widget _button(String name, {Key? key, bool focusable = true}) => Focus(
  canRequestFocus: focusable,
  child: Semantics(
    label: name,
    button: true,
    child: SizedBox.square(key: key, dimension: 40),
  ),
);

Widget _tip(
  String message, {
  Key key = const ValueKey('a'),
  PHelpBubbleSide side = PHelpBubbleSide.top,
  bool pinnedOpen = false,
  bool focusable = true,
  String? name,
}) => PTooltip(
  message: message,
  side: side,
  pinnedOpen: pinnedOpen,
  child: _button(name ?? message, key: key, focusable: focusable),
);

Finder get _bubble => find.byKey(const ValueKey('p-tooltip'));
Finder get _text => find.byKey(const ValueKey('p-tooltip-text'));

RenderHelpBubbleLayout _layout(WidgetTester tester) =>
    tester.renderObject<RenderHelpBubbleLayout>(find.byType(HelpBubbleLayout));

Future<TestGesture> _mouse(WidgetTester tester) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: const Offset(700, 500));
  addTearDown(g.removePointer);
  await tester.pump();
  return g;
}

void main() {
  setUp(resetTooltipGroup);
  tearDown(resetTooltipGroup);

  for (final mode in [Brightness.light, Brightness.dark]) {
    testWidgets('${mode.name} — 말풍선 · 화살표 · 글이 스펙 값이다', (tester) async {
      final want = _spec.resolve(_hover, 'enabled');
      final colors = mode == Brightness.dark ? PColors.dark : PColors.light;
      await tester.pumpWidget(
        _host(mode, Center(child: _tip('금액 가리기', pinnedOpen: true))),
      );
      await tester.pumpAndSettle();

      final body = tester.getRect(_bubble);
      final target = tester.getRect(find.byKey(const ValueKey('a')));
      final placement = _layout(tester).placement;
      // 말풍선 — 위아래 10 · 좌우 12 · 모서리 12 · 그림자 없음
      final textRect = tester.getRect(_text);
      expect(textRect.left - body.left, want['root.paddingX']);
      expect(body.right - textRect.right, want['root.paddingX']);
      expect(textRect.top - body.top, want['root.paddingY']);
      expect(body.bottom - textRect.bottom, want['root.paddingY']);
      final deco =
          tester.widget<DecoratedBox>(_bubble).decoration as BoxDecoration;
      expect(want['root.radius'], 12);
      expect(deco.borderRadius, BorderRadius.circular(12));
      expect(
        sameColor(
          specColor(pickMode(want['root.background'], mode)),
          deco.color!,
        ),
        isTrue,
      );
      expect(deco.color, colors.bgNeutralInverted);
      expect(want['root.shadow'], 'none');
      expect(deco.boxShadow, isNull);
      // 글 — 하나, 13 / 18 · 굵게 · 말풍선 위의 반전 글자색
      final style = tester.widget<Text>(_text).style!;
      final t = want['title.typography'] as Map<String, dynamic>;
      expect(style.fontSize, (t['fontSize'] as num).toDouble());
      expect(
        style.fontSize! * style.height!,
        closeTo((t['lineHeight'] as num).toDouble(), 0.01),
      );
      expect(style.fontWeight, FontWeight.w700);
      expect(want['title.fontWeight'], 700);
      expect(
        sameColor(
          specColor(pickMode(want['title.foreground'], mode)),
          style.color!,
        ),
        isTrue,
      );
      expect(style.color, colors.fgNeutralInverted);
      // 설명 · 닫기 버튼은 없다 — 글 하나
      expect(
        find.byKey(const ValueKey('help-bubble-description')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('help-bubble-close-box')), findsNothing);
      // 화살표 12 × 8 · 끝 ↔ 트리거 4 · 늘 트리거 가운데
      expect(placement.arrow.width, want['arrow.width']);
      expect(placement.arrow.height, want['arrow.height']);
      expect(target.top - placement.tip.dy, want['root.offset']);
      expect(placement.tip.dx, closeTo(target.center.dx, 0.01));
      // 화살표 끝 ↔ 몸통 = 화살표 높이
      expect(placement.body, body);
      expect(
        body.bottom + (want['arrow.height'] as num),
        closeTo(placement.tip.dy, 0.01),
      );
    });
  }

  testWidgets('긴 글은 최대 280(여백 포함)에서 줄을 바꾼다', (tester) async {
    final want = _spec.resolve(_hover, 'enabled');
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Center(
          child: _tip(
            '연차는 입사일 기준으로 계산하고 한 해가 지나면 새로 생겨요. 쓰지 않은 연차는 정해진 날 사라져요.',
            pinnedOpen: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(_bubble).width, want['root.maxWidth']);
    expect(tester.getRect(_text).height, greaterThan(18));
  });

  testWidgets('화면이 좁으면 가장자리 16 을 남기고, 자리가 모자라면 반대편으로 뒤집는다', (tester) async {
    final want = _spec.resolve(_hover, 'enabled');
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Align(
          alignment: Alignment.topLeft,
          child: _tip('연차는 입사일 기준으로 계산하고 한 해가 지나면 새로 생겨요.', pinnedOpen: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final placement = _layout(tester).placement;
    // 위가 모자라 아래로
    expect(placement.side, PHelpBubbleSide.bottom);
    // 가장자리 16 은 지는 값이다(root.marginMin 0 — Q-004): 트리거 가운데가 끝에서 20 안쪽이면 그만큼만 남기고 0 까지 붙는다
    final trigger = tester.getRect(find.byKey(const ValueKey('a')));
    final gap = (trigger.center.dx - 20).clamp(
      want['root.marginMin'] as num,
      want['root.margin'] as num,
    );
    expect(placement.body.left, gap);
    expect(placement.tip.dx, trigger.center.dx, reason: '화살표는 늘 트리거 가운데');
    expect(placement.body.width, 300 - 2 * (want['root.margin'] as num));
  });

  group('여는 법', () {
    testWidgets('마우스를 올리면 200ms 뒤 열고 벗어나면 100ms 뒤 닫는다', (tester) async {
      final want = _spec.resolve(_hover, 'enabled');
      expect(specMs(want['root.openDelay']), kTooltipOpenDelay);
      expect(specMs(want['root.closeDelay']), kTooltipCloseDelay);
      expect(specMs(want['root.skipDelay']), kTooltipSkipDelay);
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('검색'))),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump(const Duration(milliseconds: 199));
      expect(_bubble, findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(_bubble, findsOneWidget);
      await tester.pumpAndSettle();

      await mouse.moveTo(const Offset(700, 500));
      await tester.pump(const Duration(milliseconds: 99));
      // 아직 열려 있다
      expect(_bubble, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      // 닫힘 — 200ms 동안 투명도만 줄고 크기는 그대로
      await tester.pump(const Duration(milliseconds: 100));
      expect(_layout(tester).look().scale, 1);
      expect(_layout(tester).look().opacity, lessThan(1));
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
    });

    testWidgets('열림은 200ms 에 0.9 → 1 로 커지며 나타난다 — 모션 줄이기면 크기는 그대로', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('검색'))),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump(kTooltipOpenDelay);
      await tester.pump(const Duration(milliseconds: 1));
      final look = _layout(tester).look();
      expect(look.scale, lessThan(1));
      expect(look.scale, greaterThanOrEqualTo(0.9));
      expect(look.opacity, lessThan(1));
      await tester.pumpAndSettle();
      expect(_layout(tester).look().scale, 1);
      expect(_layout(tester).look().opacity, 1);
    });

    testWidgets('말풍선 위로 포인터를 옮겨도 닫히지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('검색'))),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump(kTooltipOpenDelay);
      await tester.pumpAndSettle();
      await mouse.moveTo(tester.getCenter(_bubble));
      await tester.pump(const Duration(seconds: 1));
      expect(_bubble, findsOneWidget);
      // 말풍선도 벗어나면 100ms 뒤 닫는다
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump(kTooltipCloseDelay);
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
    });

    testWidgets('손가락으로 누르거나 길게 눌러도 열지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('검색'))),
      );
      final center = tester.getCenter(find.byKey(const ValueKey('a')));
      await tester.tapAt(center);
      await tester.pump(const Duration(seconds: 1));
      expect(_bubble, findsNothing);
      final g = await tester.startGesture(center);
      await tester.pump(const Duration(seconds: 2));
      expect(_bubble, findsNothing);
      await g.up();
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      // 터치로 초점이 와도 열지 않는다
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
    });

    testWidgets('트리거를 누르면 열지도 닫지도 않는다 — 기다리던 열기는 거둔다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('검색'))),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump(const Duration(milliseconds: 100));
      await mouse.down(tester.getCenter(find.byKey(const ValueKey('a'))));
      await mouse.up();
      await tester.pump(const Duration(seconds: 1));
      // 기다리던 열기를 거뒀다
      expect(_bubble, findsNothing);
      // 열려 있을 때 누르면 닫지 않는다
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump(const Duration(milliseconds: 200));
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump(kTooltipOpenDelay);
      await tester.pumpAndSettle();
      expect(_bubble, findsOneWidget);
      await mouse.down(tester.getCenter(find.byKey(const ValueKey('a'))));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(_bubble, findsOneWidget);
    });

    testWidgets('키보드 초점(Tab)이 오면 바로 열고 떠나면 닫는다 — 그동안 포인터가 지나가도 닫지 않는다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tip('금액 가리기', key: const ValueKey('a')),
                _tip('알림', key: const ValueKey('b')),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      // 기다림 없이 바로
      expect(_bubble, findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(_text).semanticsLabel, '금액 가리기');

      // 포인터가 지나가도 닫지 않는다
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump(const Duration(seconds: 1));
      expect(_bubble, findsOneWidget);

      // 다음 칸으로 — 앞 것은 닫히고 다음 것이 바로 열린다(모션 없이)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_bubble, findsOneWidget);
      expect(tester.widget<Text>(_text).semanticsLabel, '알림');
      expect(_layout(tester).look().scale, 1);
      expect(_layout(tester).look().opacity, 1);
    });

    testWidgets('Esc 는 닫고 초점은 트리거에 그대로', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('검색'))),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_bubble, findsOneWidget);
      final focused = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      expect(FocusManager.instance.primaryFocus, focused);
    });

    testWidgets('이어서 옆 트리거로 옮기면 기다리지 않고 모션 없이 바로 열고, 300ms 가 지나면 다시 기다린다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tip('금액 가리기', key: const ValueKey('a')),
                const SizedBox(width: 20),
                _tip('알림', key: const ValueKey('b')),
              ],
            ),
          ),
        ),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump(kTooltipOpenDelay);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(_text).semanticsLabel, '금액 가리기');

      // 옆으로 — 바로, 모션 없이
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('b'))));
      await tester.pump();
      expect(find.byKey(const ValueKey('p-tooltip')), findsOneWidget);
      expect(tester.widget<Text>(_text).semanticsLabel, '알림');
      expect(_layout(tester).look().opacity, 1);
      expect(_layout(tester).look().scale, 1);

      // 모두 벗어나 닫힌 뒤 300ms 안에 다시 올리면 바로
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump(kTooltipCloseDelay);
      await tester.pump(const Duration(milliseconds: 200));
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump();
      expect(_bubble, findsOneWidget);
      expect(_layout(tester).look().opacity, 1);

      // 300ms 넘게 쉬면 다시 200ms 를 기다린다
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump(kTooltipCloseDelay);
      await tester.pumpAndSettle();
      await tester.pump(kTooltipSkipDelay + const Duration(milliseconds: 1));
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('b'))));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_bubble, findsNothing);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_bubble, findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('스크롤하면 트리거를 따라간다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          SizedBox(
            height: 600,
            child: ListView(
              controller: controller,
              children: [
                const SizedBox(height: 300),
                _tip('검색', pinnedOpen: true),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.getRect(_bubble).top;
      controller.jumpTo(100);
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(_bubble).top, closeTo(before - 100, 0.5));
    });
  });

  group('읽기 · 이름은 툴팁에만 두지 않는다', () {
    testWidgets('트리거는 이름을 그대로 읽고 툴팁은 설명(tooltip)으로만 붙는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('금액 가리기', name: '금액 가리기'))),
      );
      final node = tester.getSemantics(find.byKey(const ValueKey('a')));
      expect(node.label, contains('금액 가리기'));
      expect(node.tooltip, '금액 가리기');
      handle.dispose();
    });

    testWidgets('툴팁은 이름을 대신 달아 주지 않는다 — 이름 없는 트리거는 이름 없이 남는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: PTooltip(
              message: '금액 가리기',
              child: Focus(
                child: Semantics(
                  button: true,
                  child: const SizedBox.square(
                    key: ValueKey('nameless'),
                    dimension: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byKey(const ValueKey('nameless')));
      // 이름(label)은 비어 있고 툴팁 글은 설명 자리에만 있다
      expect(node.label, isEmpty);
      expect(node.tooltip, '금액 가리기');
      handle.dispose();
    });

    testWidgets('말풍선은 글을 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, Center(child: _tip('검색', pinnedOpen: true))),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('검색'), findsWidgets);
      handle.dispose();
    });

    testWidgets('막힌 버튼은 초점을 받지 못해 키보드로 툴팁을 열 수 없다 — 이유는 가까운 글로', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tip('지난달 예산 복사', focusable: false),
                const Text('복사할 지난달 예산이 없어요.'),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      // 이유는 보이는 글로 있다
      expect(findText('복사할 지난달 예산이 없어요.'), findsOneWidget);
    });
  });
}
