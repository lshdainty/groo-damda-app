// Scroll Auto Hide 가 스펙 값(test/fixtures/design_spec/scroll-auto-hide.json)대로인지 — 스크롤 거리 1:1 따라가기 · 맨 위 근처 · 50%
// 스냅(200ms · enter) · 높이 불변(옮기기만) · 모션 줄이기 · 포커스 · 의미 트리. 웹은 같은 JSON 을 크로미움에서 잰다. 웹의
// sticky · ScrollTimeline · 키보드 즉시 스냅은 웹 전용이라 건너뛴다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('scroll-auto-hide');

const _headerHeight = 100.0;
const _boxHeight = 400.0;
final _headerKey = GlobalKey();

Widget _host(
  Brightness mode,
  ScrollController controller, {
  bool reduceMotion = false,
  Widget? header,
  double headerHeight = _headerHeight,
  int count = 40,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 390,
          height: _boxHeight,
          child: PScrollAutoHide(
            controller: controller,
            header:
                header ??
                SizedBox(
                  key: _headerKey,
                  height: headerHeight,
                  child: const Text('월 헤더'),
                ),
            builder: (context, c, h) => ListView.builder(
              controller: c,
              padding: EdgeInsets.only(top: h),
              itemCount: count,
              itemBuilder: (context, i) =>
                  SizedBox(height: 50, child: Text('거래 $i')),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// 영역이 위로 옮겨진 거리(0 ~ −높이).
double _dy(WidgetTester tester) => tester.getTopLeft(find.byKey(_headerKey)).dy;

Future<void> _pumpHost(
  WidgetTester tester,
  ScrollController controller, {
  Brightness mode = Brightness.light,
  bool reduceMotion = false,
  Widget? header,
}) async {
  await tester.pumpWidget(
    _host(mode, controller, reduceMotion: reduceMotion, header: header),
  );
  // 영역 높이를 잰 뒤 목록 위 여백이 들어간다
  await tester.pump();
  await tester.pump();
}

void main() {
  final want = _spec.resolve({}, 'shown');

  test('스펙 값 — 50% 스냅 · 200ms · enter 곡선 · 1:1 · 바탕', () {
    expect(want['root.snapThreshold'], '50%');
    expect(kScrollAutoHideSnapRatio, 0.5);
    expect(want['root.follow'], '1:1');
    expect(specMs(want['root.snapDuration']), PDuration.d4);
    expect(specCubic(want['root.snapEasing']), [0.0, 0.0, 0.15, 1.0]);
    expect(PEasing.enter, const Cubic(0, 0, 0.15, 1));
    final motion = _spec.json['motion'] as Map<String, dynamic>;
    expect(specMs((motion['스크롤 끝 — 스냅'] as Map)['duration']), PDuration.d4);
    final reduced = _spec.resolve({'motionSetting': 'reduced'}, 'shown');
    expect(reduced['root.follow'], '끔');
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 영역 바탕이 스펙 값이고 목록은 영역 높이만큼 아래에서 시작한다', (
      tester,
    ) async {
      final controller = ScrollController();
      await _pumpHost(tester, controller, mode: mode);
      final fill = tester
          .widget<ColoredBox>(
            find
                .ancestor(
                  of: find.byKey(_headerKey),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color;
      expect(
        sameColor(specColor(pickMode(want['root.background'], mode)), fill),
        isTrue,
      );
      expect(_dy(tester), 0, reason: '맨 위에서는 다 드러난다');
      expect(
        tester.getTopLeft(findText('거래 0')).dy,
        _headerHeight,
        reason: '목록은 영역 아래에서 시작',
      );
      // 높이는 바뀌지 않는다
      expect(tester.getSize(find.byKey(_headerKey)).height, _headerHeight);
    });
  }

  testWidgets('스크롤 거리를 1:1 로 따라간다 — 내린 만큼 숨고 올린 만큼 드러난다(영역 높이는 그대로)', (
    tester,
  ) async {
    final controller = ScrollController();
    await _pumpHost(tester, controller);
    final g = await tester.startGesture(const Offset(100, 300));
    await g.moveBy(const Offset(0, -20));
    await tester.pump();
    for (final step in [30.0, 20.0, 15.0]) {
      final before = controller.offset;
      await g.moveBy(Offset(0, -step));
      await tester.pump();
      expect(controller.offset - before, closeTo(step, 0.01));
      // 맨 위 근처 — 스크롤한 거리보다 더 숨지 않는다
      expect(
        _dy(tester),
        closeTo(-controller.offset.clamp(0, _headerHeight), 0.01),
        reason: 'offset ${controller.offset}',
      );
      expect(tester.getSize(find.byKey(_headerKey)).height, _headerHeight);
    }
    // 영역 높이를 넘겨 내리면 다 숨고 더 숨지 않는다
    await g.moveBy(const Offset(0, -200));
    await tester.pump();
    expect(controller.offset, greaterThan(_headerHeight));
    expect(_dy(tester), -_headerHeight);
    // 올리면 같은 거리만큼 드러난다(1:1)
    await g.moveBy(const Offset(0, 25));
    await tester.pump();
    expect(_dy(tester), closeTo(-_headerHeight + 25, 0.01));
    await g.moveBy(const Offset(0, 10));
    await tester.pump();
    expect(_dy(tester), closeTo(-_headerHeight + 35, 0.01));
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('멈추면 절반 기준으로 다 숨거나 다 드러난다 — 200ms · enter', (tester) async {
    final controller = ScrollController();
    await _pumpHost(tester, controller);
    // 절반보다 덜 숨었다 — 다 드러난다
    var g = await tester.startGesture(const Offset(100, 300));
    await g.moveBy(const Offset(0, -30)); // 슬롭 18 + 30
    await tester.pump();
    final hiddenLess = _dy(tester);
    expect(hiddenLess, closeTo(-30, 0.5));
    await g.up();
    await tester.pump(); // 스크롤이 끝난다
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _dy(tester);
    expect(mid, inExclusiveRange(hiddenLess, 0), reason: '200ms 동안 이어 간다');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_dy(tester), 0);

    // 절반보다 더 숨었다 — 다 숨는다
    g = await tester.startGesture(const Offset(100, 300));
    await g.moveBy(const Offset(0, -70));
    await tester.pump();
    expect(_dy(tester), closeTo(-70, 0.5));
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_dy(tester), inExclusiveRange(-_headerHeight, -70));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_dy(tester), -_headerHeight);
    // 높이(레이아웃)는 그대로 — 옮기기만 한다
    expect(tester.getSize(find.byKey(_headerKey)).height, _headerHeight);
    expect(tester.getSize(find.byType(PScrollAutoHide)).height, _boxHeight);
  });

  testWidgets('정확히 50% 는 다 드러난다(visibleRatio ≥ 0.5)', (tester) async {
    final controller = ScrollController();
    await _pumpHost(tester, controller);
    final g = await tester.startGesture(const Offset(100, 300));
    await g.moveBy(const Offset(0, -50));
    await tester.pump();
    expect(_dy(tester), closeTo(-50, 0.5));
    await g.up();
    await tester.pumpAndSettle();
    expect(_dy(tester), 0);
  });

  testWidgets('영역 위를 끌어도 목록이 스크롤된다(웹은 영역이 스크롤 상자 안에 있다)', (tester) async {
    final controller = ScrollController();
    await _pumpHost(tester, controller);
    final g = await tester.startGesture(const Offset(100, 40)); // 영역 위
    await g.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(controller.offset, closeTo(60, 0.01));
    expect(_dy(tester), closeTo(-60, 0.01));
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('모션 줄이기면 자동 숨김을 끈다 — 늘 보인다', (tester) async {
    final controller = ScrollController();
    await _pumpHost(tester, controller, reduceMotion: true);
    final g = await tester.startGesture(const Offset(100, 300));
    await g.moveBy(const Offset(0, -200));
    await tester.pump();
    expect(controller.offset, greaterThan(_headerHeight));
    expect(_dy(tester), 0);
    await g.up();
    await tester.pumpAndSettle();
    expect(_dy(tester), 0);
  });

  testWidgets('숨은 영역 안으로 포커스가 오면 바로 다 드러난다', (tester) async {
    final controller = ScrollController();
    final focus = FocusNode();
    await _pumpHost(
      tester,
      controller,
      header: SizedBox(
        key: _headerKey,
        height: _headerHeight,
        child: Focus(focusNode: focus, child: const Text('월 헤더')),
      ),
    );
    final g = await tester.startGesture(const Offset(100, 300));
    await g.moveBy(const Offset(0, -250));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(_dy(tester), -_headerHeight);
    focus.requestFocus();
    await tester.pump();
    await tester.pump(); // 포커스는 프레임 끝에 알려져 한 프레임 뒤 그려진다
    expect(_dy(tester), 0, reason: '애니메이션 없이 바로');
    focus.dispose();
  });

  testWidgets('숨겨도 의미 트리에서 빼지 않는다(inert · aria-hidden 을 걸지 않는다)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = ScrollController();
    await _pumpHost(tester, controller);
    final g = await tester.startGesture(const Offset(100, 300));
    await g.moveBy(const Offset(0, -250));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(_dy(tester), -_headerHeight);
    final node = tester.getSemantics(find.bySemanticsLabel('월 헤더'));
    expect(node.getSemanticsData().flagsCollection.isHidden, isFalse);
    expect(
      find.descendant(
        of: find.byType(PScrollAutoHide),
        matching: find.byType(ExcludeSemantics),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(PScrollAutoHide),
        matching: find.byType(Offstage),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('영역 높이가 바뀌면 다시 재서 목록 위 여백이 따라간다', (tester) async {
    final controller = ScrollController();
    var height = 100.0;
    late StateSetter set;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: _boxHeight,
            child: StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return PScrollAutoHide(
                  controller: controller,
                  header: SizedBox(key: _headerKey, height: height),
                  builder: (context, c, h) => ListView(
                    controller: c,
                    padding: EdgeInsets.only(top: h),
                    children: const [SizedBox(height: 1000, child: Text('끝'))],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.getTopLeft(findText('끝')).dy, 100);
    set(() => height = 160);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(tester.getTopLeft(findText('끝')).dy, 160);
  });

  testWidgets('가장 나쁜 값 — 키 큰 머리 + 짧은 목록(스크롤이 거의 없다)에서도 넘치지 않는다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: PScrollAutoHide(
              controller: controller,
              header: SizedBox(key: _headerKey, height: 240),
              builder: (context, c, h) => ListView(
                controller: c,
                padding: EdgeInsets.only(top: h),
                children: const [SizedBox(height: 100)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.position.maxScrollExtent, 240 + 100 - 300);
    final g = await tester.startGesture(const Offset(100, 200));
    await g.moveBy(const Offset(0, -400));
    await tester.pump();
    // 스크롤할 수 있는 만큼(40)만 숨는다
    expect(tester.getTopLeft(find.byKey(_headerKey)).dy, -40);
    await g.up();
    await tester.pumpAndSettle();
    // 40 / 240 = 17% 만 숨었다 — 절반보다 덜 숨어 다 드러난다
    expect(tester.getTopLeft(find.byKey(_headerKey)).dy, 0);
  });
}
