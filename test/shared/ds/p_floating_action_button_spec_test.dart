// Floating Action Button 이 스펙 값(test/fixtures/design_spec/floating-action-button.json)대로인지 — 기본 · 누름 × 라이트 · 다크의
// 원 56 · 바탕 · 그림자 · 아이콘 24(선 2.5 · 흰색) · 오른쪽 아래 20 · 누름 색 · 2px 거리 축소 · 모션과, 안전 영역 · 바닥 고정 요소 ·
// 키보드 · 스낵바 · 읽는 말 · 누르는 영역. 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 값은 재지 않는다 — 웹의 hovered · focused(포커스 링), 쌓임(z-sticky)은 셸 몫이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/floating_action_button_demo.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/p_floating_action_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('floating-action-button');

/// 앱의 상태 — 웹의 hovered · focused 는 앱에 없다.
final _appStates = _spec.states
    .where((s) => s != 'hovered' && s != 'focused')
    .toList();

const _screen = Size(360, 640);

void _viewport(WidgetTester tester, {double bottom = 0, double right = 0}) {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: bottom, right: right);
  tester.view.viewPadding = FakeViewPadding(bottom: bottom, right: right);
  addTearDown(tester.view.reset);
}

Widget _app(
  Brightness mode,
  Widget body, {
  bool snackbar = false,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  builder: (context, child) {
    Widget app = child!;
    if (snackbar) app = PSnackbarHost(closeLabel: '닫기', child: app);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: app,
    );
  },
  home: Material(child: Stack(children: [body])),
);

PFloatingActionButton _fab({
  VoidCallback? onPressed,
  double offsetBottom = 0,
  bool enabled = true,
}) => PFloatingActionButton(
  icon: LucideIcons.plus500,
  label: '할 일 추가',
  offsetBottom: offsetBottom,
  onPressed: enabled ? (onPressed ?? () {}) : null,
);

Finder get _box => find.byKey(const ValueKey('floating-action-button'));

BoxDecoration _deco(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(of: _box, matching: find.byType(DecoratedBox))
                  .first,
            )
            .decoration
        as BoxDecoration;

double _scale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.ancestor(of: _box, matching: find.byType(AnimatedScale)).first,
    )
    .scale;

void main() {
  for (final mode in Brightness.values) {
    for (final state in _appStates) {
      final title = '${mode.name} $state';
      testWidgets('$title — 스펙 값이다', (tester) async {
        _viewport(tester);
        await tester.pumpWidget(_app(mode, _fab()));
        await tester.pump(const Duration(milliseconds: 400));
        final k = SpecCheck(mode, _spec.resolve({}, state), title);

        // 놓인 자리는 누르기 전에 잰다 — 누르면 줄어 그려진 사각형이 작아진다
        final rect = tester.getRect(_box);
        final icon = tester.widget<Icon>(
          find.descendant(of: _box, matching: find.byType(Icon)),
        );
        final anim = tester.widget<AnimatedContainer>(_box);
        final cursor = tester
            .widget<MouseRegion>(
              find.ancestor(of: _box, matching: find.byType(MouseRegion)).first,
            )
            .cursor;

        TestGesture? gesture;
        if (state == 'pressed') {
          gesture = await tester.startGesture(rect.center);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }
        final deco = _deco(tester);

        // 원 56 · 브랜드 채움 · shadow-s3 · 오른쪽 아래 20
        k.px('root.size', rect.width);
        k.px('root.size', rect.height);
        k.m(['root.radius']);
        if (deco.shape != BoxShape.circle) k.fail('root.radius: 원이 아니다');
        k.color('root.background', deco.color!);
        k.m(['root.shadow']);
        if (deco.boxShadow == null ||
            deco.boxShadow!.length != tester.element(_box).shadows.s3.length ||
            deco.boxShadow!.first != tester.element(_box).shadows.s3.first) {
          k.fail('root.shadow: shadow-s3 가 아니다');
        }
        k.px('root.marginRight', _screen.width - rect.right);
        k.px('root.marginBottom', _screen.height - rect.bottom);
        k.cursor('root.cursor', cursor);
        k.motion(
          'root.transitionDuration',
          'root.transitionEasing',
          anim.duration,
          anim.curve,
        );
        k.m(['root.transitionProperty']);

        // 아이콘 — 흰 선 아이콘 24 · 선 2.5(Lucide500 글꼴)
        k.px('icon.size', icon.size!);
        k.color('icon.color', icon.color!);
        k.m(['icon.strokeWidth']);
        if (icon.icon!.fontFamily != 'Lucide500') {
          k.fail(
            'icon.strokeWidth: 선 2.5 글꼴(Lucide500)이 아니다 — ${icon.icon!.fontFamily}',
          );
        }
        final iconRect = tester.getRect(
          find.descendant(of: _box, matching: find.byType(Icon)),
        );
        if ((iconRect.center - tester.getRect(_box).center).distance > 0.5) {
          k.fail('icon: 원 가운데가 아니다');
        }

        // 누름 — 색 + 2px 거리 축소(기준 56)
        if (state == 'pressed') {
          k.pressScale('root.scale', _scale(tester), 56);
          final scaleAnim = tester.widget<AnimatedScale>(
            find.ancestor(of: _box, matching: find.byType(AnimatedScale)).first,
          );
          k.motion(
            'root.scaleDuration',
            'root.scaleEasing',
            scaleAnim.duration,
            scaleAnim.curve,
          );
          await gesture!.up();
        } else {
          k.m(['root.scale', 'root.scaleDuration', 'root.scaleEasing']);
        }

        k.coverage({
          'root.position',
          'root.zIndex',
          'focusRing.width',
          'focusRing.offset',
          'focusRing.color',
        });
        expect(k.failures, isEmpty, reason: k.failures.join('\n'));
      });
    }
  }

  group('자리', () {
    testWidgets('안전 영역을 더한다 — 홈 표시줄 34 · 오른쪽 노치 20', (tester) async {
      _viewport(tester, bottom: 34, right: 20);
      await tester.pumpWidget(_app(Brightness.light, _fab()));
      final rect = tester.getRect(_box);
      expect(_screen.height - rect.bottom, 20 + 34);
      expect(_screen.width - rect.right, 20 + 20);
    });

    testWidgets('바닥 고정 요소 위 끝에서 20 — offsetBottom 은 안전 영역을 뺀 높이', (
      tester,
    ) async {
      _viewport(tester, bottom: 34);
      await tester.pumpWidget(_app(Brightness.light, _fab(offsetBottom: 64)));
      final rect = tester.getRect(_box);
      // 화면 아래 → 홈 표시줄 34 → 바닥 버튼 64 → 20 → 버튼
      expect(_screen.height - rect.bottom, 34 + 64 + 20);
    });

    testWidgets('화면 키보드가 올라오면 가린다', (tester) async {
      _viewport(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpWidget(_app(Brightness.light, _fab()));
      expect(_box, findsNothing);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      expect(_box, findsOneWidget);
    });

    testWidgets('빈 곳은 누름을 통과시킨다 — 아래 화면이 그대로 눌린다', (tester) async {
      _viewport(tester);
      var under = 0;
      await tester.pumpWidget(
        _app(
          Brightness.light,
          Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => under++,
                ),
              ),
              _fab(),
            ],
          ),
        ),
      );
      await tester.tapAt(const Offset(40, 40));
      expect(under, 1);
    });

    testWidgets('스크롤해도 그 자리에 있고 숨지 않는다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _app(
          Brightness.light,
          Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  children: [
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 60, child: Text('항목 $i')),
                  ],
                ),
              ),
              _fab(),
            ],
          ),
        ),
      );
      final before = tester.getRect(_box);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      expect(tester.getRect(_box), before);
    });

    testWidgets('스낵바는 버튼 위 8 에 뜬다', (tester) async {
      _viewport(tester);
      late BuildContext inner;
      await tester.pumpWidget(
        _app(
          Brightness.light,
          Builder(
            builder: (context) {
              inner = context;
              return _fab();
            },
          ),
          snackbar: true,
        ),
      );
      await tester.pump();
      PSnackbar.of(inner).show(message: '할 일을 저장했어요.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final band = tester.getRect(find.byKey(const ValueKey('snackbar-band')));
      expect(tester.getRect(_box).top - band.bottom, closeTo(8, 0.5));
    });
  });

  group('동작', () {
    testWidgets('누르는 영역은 원 56 — 안은 눌리고 바깥은 눌리지 않는다', (tester) async {
      _viewport(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(Brightness.light, _fab(onPressed: () => taps++)),
      );
      final r = tester.getRect(_box);
      await tester.tapAt(r.topLeft + const Offset(1, 1));
      await tester.tapAt(r.bottomRight - const Offset(1, 1));
      expect(taps, 2);
      await tester.tapAt(r.topLeft - const Offset(2, 2));
      await tester.tapAt(r.bottomRight + const Offset(2, 2));
      expect(taps, 2);
    });

    testWidgets('읽는 말 — 이름 있는 버튼이고 글은 보이지 않는다', (tester) async {
      _viewport(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(Brightness.light, _fab()));
      expect(
        tester.getSemantics(find.bySemanticsLabel('할 일 추가')),
        isSemantics(
          label: '할 일 추가',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(findText('할 일 추가'), findsNothing, reason: '보이는 글이 없다');
      handle.dispose();
    });

    testWidgets('onPressed 가 없으면 막힌다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_app(Brightness.light, _fab(enabled: false)));
      final g = await tester.startGesture(tester.getCenter(_box));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_scale(tester), 1);
      await g.up();
    });

    testWidgets('모션 줄이기면 눌러도 줄지 않는다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _app(Brightness.light, _fab(), reduceMotion: true),
      );
      final g = await tester.startGesture(tester.getCenter(_box));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_scale(tester), 1);
      await g.up();
    });
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} 견본이 폰 폭 390 에서 그려진다', (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
              child: FloatingActionButtonDemo(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  }
}
