// Bottom Navigation 이 스펙 값(test/fixtures/design_spec/bottom-navigation.json)대로인지 — 크기(펼침 · 줄어듦) × 고름(지금 탭 · 다른 탭)
// × 상태(기본 · 누름) × 라이트 · 다크의 바 · 칸 · 아이콘 · 라벨 · 가운데 + · 알림 점 · 누름 배율과, 줄어들기(아래 20 · 위 28 · 맨 위 40)
// · 줄어든 바를 누르면 펴짐 · 라벨 숨김 · 안전 영역 · 키보드 · 읽는 말 · 본문 아래 여백. 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 값은 재지 않는다 — 웹의 focused(포커스 링), 쌓임(z-sticky)은 셸 몫이다. 스펙의 문장("칸 전체", "칸 2px 거리 축소")은 눌러 보는 동작과
// 그려진 배율로 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/bottom_navigation_demo.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';

final _spec = DesignSpec.load('bottom-navigation');

/// 앱의 상태 — 웹의 focused(키보드 포커스 링)는 앱에 없다.
final _appStates = _spec.states.where((s) => s != 'focused').toList();

const _screen = Size(360, 640);

void _viewport(
  WidgetTester tester, {
  Size size = _screen,
  double bottom = 0,
  double left = 0,
  double right = 0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(
    bottom: bottom,
    left: left,
    right: right,
  );
  tester.view.viewPadding = FakeViewPadding(
    bottom: bottom,
    left: left,
    right: right,
  );
  addTearDown(tester.view.reset);
}

const _icons = [
  LucideIcons.house,
  LucideIcons.wallet,
  LucideIcons.calendar,
  LucideIcons.layoutGrid,
];
const _selectedIcons = [
  LucideIcons.house500,
  LucideIcons.wallet500,
  LucideIcons.calendar500,
  LucideIcons.layoutGrid500,
];

PBottomNavigation _bar({
  PBottomNavigationController? controller,
  int current = 1,
  Set<int> badges = const {0, 1},
  List<String> labels = const ['홈', '가계부', '캘린더', '전체'],
  String addLabel = '거래 추가',
  void Function(int)? onTap,
  void Function(int)? onReselect,
  VoidCallback? onAdd,
}) => PBottomNavigation(
  semanticLabel: '주 메뉴',
  controller: controller,
  add: PBottomNavigationAdd(label: addLabel, onPressed: onAdd ?? () {}),
  items: [
    for (var i = 0; i < 4; i++)
      PBottomNavigationItem(
        icon: _icons[i],
        selectedIcon: _selectedIcons[i],
        label: labels[i],
        current: i == current,
        notification: badges.contains(i),
        onTap: () => onTap?.call(i),
        onReselect: () => onReselect?.call(i),
      ),
  ],
);

Widget _app(
  Brightness mode,
  Widget bar, {
  Widget? body,
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
  home: Material(
    child: Stack(
      children: [
        ?body,
        Positioned(left: 0, right: 0, bottom: 0, child: bar),
      ],
    ),
  ),
);

Finder get _pill => find.byKey(const ValueKey('bottom-navigation-bar'));
Finder get _cells => find.byKey(const ValueKey('bottom-navigation-item'));
Finder get _addCell => find.byKey(const ValueKey('bottom-navigation-add-cell'));
Finder get _addCircle => find.byKey(const ValueKey('bottom-navigation-add'));
Finder get _label => find.byKey(const ValueKey('bottom-navigation-label'));

double _scaleOf(WidgetTester tester, Finder inside) => tester
    .widget<AnimatedScale>(
      find.descendant(of: inside, matching: find.byType(AnimatedScale)).first,
    )
    .scale;

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['size', 'selected'])) {
      for (final state in _appStates) {
        final title =
            '${mode.name} ${combo['size']} ${combo['selected']} $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          _viewport(tester);
          final compact = combo['size'] == 'compact';
          final selected = combo['selected'] == 'selected';
          await tester.pumpWidget(
            _app(
              mode,
              _bar(controller: PBottomNavigationController(compact: compact)),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          final k = SpecCheck(mode, _spec.resolve(combo, state), title);

          // 놓인 자리는 누르기 전에 잰다 — 누르면 줄어 그려진 사각형이 작아진다
          final pill = tester.getRect(_pill);
          final cells = [
            for (var i = 0; i < 4; i++) tester.getRect(_cells.at(i)),
          ];
          final add = tester.getRect(_addCell);
          final item = _cells.at(selected ? 1 : 0);
          final itemRect = tester.getRect(item);
          final circle = tester.getRect(_addCircle);

          // 바 — 높이 · 좌우 · 아래 · 안쪽 여백 · 모서리 · 바탕 · 그림자 · 테두리 · 다섯 칸 · 사이 2
          final pillBox = tester.widget<AnimatedContainer>(_pill);
          final deco = pillBox.decoration! as BoxDecoration;
          final fore = pillBox.foregroundDecoration! as BoxDecoration;
          k.px('root.height', pill.height);
          k.px('root.marginX', pill.left);
          k.px('root.marginX', _screen.width - pill.right);
          k.px('root.marginBottom', _screen.height - pill.bottom);
          k.px('root.paddingX', cells[0].left - pill.left);
          k.px('root.paddingX', pill.right - cells[3].right);
          k.px('root.paddingY', cells[0].top - pill.top);
          k.px('root.paddingY', pill.bottom - cells[0].bottom);
          k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
          k.color('root.background', deco.color!);
          k.m(['root.shadow']);
          if (deco.boxShadow == null ||
              deco.boxShadow!.first != tester.element(_pill).shadows.s3.first) {
            k.fail('root.shadow: shadow-s3 가 아니다');
          }
          final border = (fore.border! as Border).top;
          k.color('root.borderColor', border.color);
          k.px('root.borderWidth', border.width);
          // 안쪽 1px 은 자리를 차지하지 않는다 — 높이가 스펙 그대로다
          final all = [cells[0], cells[1], add, cells[2], cells[3]];
          k.px('root.columns', all.length);
          for (var i = 1; i < all.length; i++) {
            k.px('root.gap', all[i].left - all[i - 1].right);
          }
          final w0 = all.first.width;
          if (all.any((c) => (c.width - w0).abs() > 0.01)) {
            k.fail('root.columns: 칸 폭이 똑같지 않다 ${all.map((c) => c.width)}');
          }
          k.motion(
            'root.transitionDuration',
            'root.transitionEasing',
            pillBox.duration,
            pillBox.curve,
          );
          k.m(['root.transitionProperty']);
          if (cells[0].top < pill.top - 0.01 ||
              cells[0].bottom > pill.bottom + 0.01) {
            k.fail('root.height: 칸이 바 밖으로 나간다');
          }

          // 칸 — 세로(아이콘 위 · 라벨 아래) · 사이 2 · 눌리는 손가락 모양
          final icon = tester.widget<Icon>(
            find.descendant(of: item, matching: find.byType(Icon)),
          );
          final iconRect = tester.getRect(
            find.descendant(of: item, matching: find.byType(Icon)),
          );
          k.px('icon.size', icon.size!);
          k.color('icon.color', icon.color!);
          k.m(['icon.strokeWidth']);
          final stroke = want(k, 'icon.strokeWidth');
          final family = stroke == 2.5 ? 'Lucide500' : 'Lucide';
          if (icon.icon!.fontFamily != family) {
            k.fail(
              'icon.strokeWidth: 스펙 $stroke · 글꼴 ${icon.icon!.fontFamily}',
            );
          }
          k.cursor(
            'item.cursor',
            tester
                .widget<MouseRegion>(
                  find
                      .descendant(of: item, matching: find.byType(MouseRegion))
                      .first,
                )
                .cursor,
          );
          k.m(['item.direction', 'item.gap', 'item.touchTarget']);

          // 라벨 — 줄어든 바에서는 보이지 않는다(그리지 않고 칸의 이름으로 남는다)
          final label = find.descendant(of: item, matching: _label);
          k.m(['label.display']);
          if (compact) {
            if (label.evaluate().isNotEmpty) {
              k.fail('label.display: 줄어든 바는 라벨을 보이지 않게 한다');
            }
            if (tester.widgetList(_label).isNotEmpty) {
              k.fail('label.display: 어느 칸에도 라벨이 보이면 안 된다');
            }
          } else {
            final text = tester.widget<Text>(label);
            final labelRect = tester.getRect(label);
            k.typo('label.typography', text.style!);
            k.weight('label.fontWeight', text.style!);
            k.color('label.foreground', text.style!.color!);
            if (text.maxLines != 1) k.fail('label.lineClamp: 한 줄이 아니다');
            if (text.textScaler != TextScaler.noScaling) {
              k.fail('label.typography: 글자 크기 설정을 따른다');
            }
            k.px('item.gap', labelRect.top - iconRect.bottom);
            if (iconRect.bottom > labelRect.top) {
              k.fail('item.direction: 아이콘이 라벨 아래다');
            }
            // 칸 안 가운데 — 아이콘 + 라벨 묶음
            if ((iconRect.center.dx - itemRect.center.dx).abs() > 0.5) {
              k.fail('item: 아이콘이 칸 가운데가 아니다');
            }
          }
          k.m([
            'label.typography',
            'label.fontWeight',
            'label.foreground',
            'label.lineClamp',
          ]);

          // 알림 점 — 아이콘 상자 위 1 · 오른쪽 1
          final dot = find.descendant(
            of: item,
            matching: find.byKey(const ValueKey('notification-badge')),
          );
          final dotRect = tester.getRect(dot);
          k.m(['notification.position']);
          if ((dotRect.top - iconRect.top - 1).abs() > 0.5 ||
              (iconRect.right - dotRect.right - 1).abs() > 0.5 ||
              (dotRect.width - 6).abs() > 0.01) {
            k.fail('notification.position: 점 $dotRect · 아이콘 $iconRect');
          }

          // 가운데 + — 브랜드 원(44 · 36) · 흰 + 24 · 20(선 2.5) · 라벨 없음 · 그림자 없음
          final addDeco =
              tester.widget<AnimatedContainer>(_addCircle).decoration!
                  as BoxDecoration;
          final plus = tester.widget<Icon>(
            find.descendant(of: _addCircle, matching: find.byType(Icon)),
          );
          k.px('addButton.size', circle.width);
          k.px('addButton.size', circle.height);
          k.m(['addButton.radius', 'addButton.shadow']);
          if (addDeco.shape != BoxShape.circle) {
            k.fail('addButton.radius: 원이 아니다');
          }
          if (addDeco.boxShadow != null) k.fail('addButton.shadow: 그림자가 있다');
          k.px('addIcon.size', plus.size!);
          k.color('addIcon.color', plus.color!);
          k.m(['addIcon.strokeWidth']);
          if (plus.icon!.fontFamily != 'Lucide500') {
            k.fail('addIcon.strokeWidth: 선 2.5 가 아니다');
          }
          if ((circle.center - add.center).distance > 0.5) {
            k.fail('addButton: 칸 가운데가 아니다');
          }

          // 누름 — 칸은 색 그대로 + 2px 거리 축소, +는 누름 색 + 축소
          if (state == 'pressed') {
            final g1 = await tester.startGesture(itemRect.center);
            final g2 = await tester.startGesture(add.center);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            final basis = [
              itemRect.height,
              itemRect.width / 4,
              24.0,
            ].reduce((a, b) => a > b ? a : b);
            k.pressScale('item.scale', _scaleOf(tester, item), basis);
            // 색은 그대로
            final pressedIcon = tester.widget<Icon>(
              find.descendant(of: item, matching: find.byType(Icon)),
            );
            k.color('icon.color', pressedIcon.color!);
            final pressedAdd =
                tester.widget<AnimatedContainer>(_addCircle).decoration!
                    as BoxDecoration;
            k.color('addButton.background', pressedAdd.color!);
            k.pressScale(
              'addButton.scale',
              _scaleOf(tester, _addCell),
              circle.width,
            );
            final a1 = tester.widget<AnimatedScale>(
              find
                  .descendant(of: item, matching: find.byType(AnimatedScale))
                  .first,
            );
            k.motion(
              'item.scaleDuration',
              'item.scaleEasing',
              a1.duration,
              a1.curve,
            );
            await g1.up();
            await g2.up();
          } else {
            k.color('addButton.background', addDeco.color!);
            k.m([
              'item.scale',
              'item.scaleDuration',
              'item.scaleEasing',
              'addButton.scale',
            ]);
          }

          k.coverage({
            'root.maxWidth', // 넓은 화면 테스트
            'root.zIndex',
            'bodyInset.paddingBottom', // 본문 여백 테스트
            'item.tabMemory', // 셸의 몫(IndexedStack 이 탭마다 화면 · 스크롤을 쥔다) — mobile_scaffold_nav_test 가 잰다
            'focusRing.width',
            'focusRing.offset',
            'focusRing.radius',
            'focusRing.color',
          });
          expect(k.failures, isEmpty, reason: k.failures.join('\n'));
        });
      }
    }
  }

  group('크기 · 자리', () {
    testWidgets('넓은 화면에서는 480 으로 가운데에 선다', (tester) async {
      _viewport(tester, size: const Size(800, 600));
      await tester.pumpWidget(_app(Brightness.light, _bar()));
      final pill = tester.getRect(_pill);
      expect(pill.width, 480);
      expect(pill.center.dx, 400);
    });

    testWidgets('안전 영역 — 홈 표시줄 34 면 아래 28 · 줄어들면 26, 좌우 안전 영역을 더한다', (
      tester,
    ) async {
      _viewport(tester, bottom: 34, left: 20, right: 12);
      final controller = PBottomNavigationController();
      await tester.pumpWidget(
        _app(Brightness.light, _bar(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      var pill = tester.getRect(_pill);
      expect(_screen.height - pill.bottom, 28);
      expect(pill.left, 14 + 20);
      expect(_screen.width - pill.right, 14 + 12);
      expect(pill.height, 66);
      controller.setCompact(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      pill = tester.getRect(_pill);
      expect(_screen.height - pill.bottom, 26);
      expect(pill.height, 48);
      expect(pill.left, 36 + 20);
    });

    testWidgets('본문 아래 여백 — 바의 아래 자리 + 66 + 24', (tester) async {
      for (final (bottom, expected) in [(0.0, 104.0), (34.0, 118.0)]) {
        _viewport(tester, bottom: bottom);
        late double inset;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                inset = bottomNavigationInset(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(inset, expected);
      }
    });

    testWidgets('화면 키보드가 올라오면 바를 가린다', (tester) async {
      _viewport(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpWidget(_app(Brightness.light, _bar()));
      expect(_pill, findsNothing);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      expect(_pill, findsOneWidget);
    });

    testWidgets('스낵바는 바 위 8 에 뜬다', (tester) async {
      _viewport(tester);
      late BuildContext inner;
      await tester.pumpWidget(
        _app(
          Brightness.light,
          Builder(
            builder: (context) {
              inner = context;
              return _bar();
            },
          ),
          snackbar: true,
        ),
      );
      await tester.pump();
      PSnackbar.of(inner).show(message: '거래를 저장했어요.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final band = tester.getRect(find.byKey(const ValueKey('snackbar-band')));
      expect(tester.getRect(_pill).top - band.bottom, closeTo(8, 0.5));
    });

    test('칸은 넷 · 알림 점은 2칸까지 — 늘리면 막는다', () {
      PBottomNavigationItem item(int i, {bool badge = false}) =>
          PBottomNavigationItem(
            icon: _icons[i % 4],
            selectedIcon: _selectedIcons[i % 4],
            label: '칸$i',
            onTap: () {},
            notification: badge,
          );
      PBottomNavigation make(List<PBottomNavigationItem> items) =>
          PBottomNavigation(
            semanticLabel: '주 메뉴',
            items: items,
            add: PBottomNavigationAdd(label: '거래 추가', onPressed: () {}),
          );
      expect(
        () => make([for (var i = 0; i < 4; i++) item(i)]),
        returnsNormally,
      );
      expect(
        () => make([for (var i = 0; i < 3; i++) item(i)]),
        throwsAssertionError,
      );
      expect(
        () => make([for (var i = 0; i < 5; i++) item(i)]),
        throwsAssertionError,
      );
      expect(
        () => make([
          item(0, badge: true),
          item(1, badge: true),
          item(2),
          item(3),
        ]),
        returnsNormally,
      );
      expect(
        () => make([
          item(0, badge: true),
          item(1, badge: true),
          item(2, badge: true),
          item(3),
        ]),
        throwsAssertionError,
      );
    });
  });

  group('줄어들기', () {
    Future<(PBottomNavigationController, ScrollController)> mount(
      WidgetTester tester, {
      Axis axis = Axis.vertical,
      bool reduceMotion = false,
    }) async {
      _viewport(tester);
      final controller = PBottomNavigationController();
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _bar(controller: controller),
          reduceMotion: reduceMotion,
          body: Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: controller.handleScroll,
              child: ListView.builder(
                controller: scroll,
                scrollDirection: axis,
                itemCount: 60,
                itemBuilder: (_, i) => SizedBox(
                  height: axis == Axis.vertical ? 60 : null,
                  width: axis == Axis.horizontal ? 120 : null,
                  child: Text('줄 $i'),
                ),
              ),
            ),
          ),
        ),
      );
      return (controller, scroll);
    }

    testWidgets('아래로 20 이상이면 줄고, 위로 28 이상이면 펴진다(방향이 바뀌면 다시 센다)', (
      tester,
    ) async {
      final (c, s) = await mount(tester);
      expect(c.compact, isFalse);
      s.jumpTo(100);
      await tester.pump();
      expect(c.compact, isTrue);
      s.jumpTo(80); // 위로 20 — 아직
      await tester.pump();
      expect(c.compact, isTrue);
      s.jumpTo(73); // 위로 27 — 아직
      await tester.pump();
      expect(c.compact, isTrue);
      s.jumpTo(72); // 위로 28
      await tester.pump();
      expect(c.compact, isFalse);
      s.jumpTo(91); // 아래로 19 — 아직
      await tester.pump();
      expect(c.compact, isFalse);
      s.jumpTo(92); // 아래로 20
      await tester.pump();
      expect(c.compact, isTrue);
    });

    testWidgets('펴면(expand) 거리를 다시 센다 — 아래로 20 을 더 내려야 준다', (tester) async {
      final (c, s) = await mount(tester);
      s.jumpTo(300);
      await tester.pump();
      expect(c.compact, isTrue);
      c.expand();
      await tester.pump();
      expect(c.compact, isFalse);
      s.jumpTo(301); // 아래로 1 — 남은 거리로 바로 줄면 안 된다
      await tester.pump();
      expect(c.compact, isFalse);
      s.jumpTo(320); // 아래로 20
      await tester.pump();
      expect(c.compact, isTrue);
    });

    testWidgets('맨 위 40 안으로 오면 펴진다', (tester) async {
      final (c, s) = await mount(tester);
      s.jumpTo(300);
      await tester.pump();
      expect(c.compact, isTrue);
      s.jumpTo(40);
      await tester.pump();
      expect(c.compact, isFalse);
      s.jumpTo(41);
      await tester.pump();
      // 41 은 40 밖 — 아래로 1 이라 아직 줄지 않는다
      expect(c.compact, isFalse);
    });

    testWidgets('가로 스크롤은 세지 않는다', (tester) async {
      final (c, s) = await mount(tester, axis: Axis.horizontal);
      s.jumpTo(500);
      await tester.pump();
      expect(c.compact, isFalse);
    });

    testWidgets('줄어든 바는 높이 48 · 라벨이 사라지고 이름은 남는다', (tester) async {
      final handle = tester.ensureSemantics();
      final (c, s) = await mount(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_label, findsNWidgets(4));
      s.jumpTo(200);
      await tester.pump();
      // 줄어들기 시작하면 라벨이 바로 사라진다
      expect(_label, findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getRect(_pill).height, 48);
      expect(find.bySemanticsLabel('가계부 새 소식'), findsOneWidget);
      expect(c.compact, isTrue);
      handle.dispose();
    });

    testWidgets('펴질 때 라벨은 다 펴진 뒤(200ms)에 나타난다', (tester) async {
      final (c, _) = await mount(tester);
      c.setCompact(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_label, findsNothing);
      c.setCompact(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_label, findsNothing, reason: '아직 펴지는 중');
      await tester.pump(const Duration(milliseconds: 150));
      expect(_label, findsNWidgets(4));
    });

    testWidgets('모션 줄이기면 바로 바뀌고 라벨도 바로 나온다 · 눌러도 줄지 않는다', (tester) async {
      final (c, _) = await mount(tester, reduceMotion: true);
      c.setCompact(true);
      await tester.pump();
      expect(tester.getRect(_pill).height, 48);
      c.setCompact(false);
      await tester.pump();
      expect(tester.getRect(_pill).height, 66);
      expect(_label, findsNWidgets(4));
      final g = await tester.startGesture(tester.getCenter(_cells.first));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_scaleOf(tester, _cells.first), 1);
      await g.up();
    });

    testWidgets('줄어든 바를 누르면 펴지고, 칸을 누르면 그 탭으로 가면서 펴진다', (tester) async {
      _viewport(tester);
      final controller = PBottomNavigationController(compact: true);
      final taps = <int>[];
      var adds = 0;
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _bar(controller: controller, onTap: taps.add, onAdd: () => adds++),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      // 바의 칸 사이 · 가장자리를 누르면 펴지기만 한다
      final pill = tester.getRect(_pill);
      await tester.tapAt(Offset(pill.left + 2, pill.center.dy));
      expect(controller.compact, isFalse);
      expect(taps, isEmpty);
      controller.setCompact(true);
      await tester.pump();
      await tester.tap(_cells.at(2));
      expect(taps, [2]);
      expect(controller.compact, isFalse);
      controller.setCompact(true);
      await tester.pump();
      await tester.tap(_addCell);
      expect(adds, 1);
      expect(controller.compact, isFalse);
    });
  });

  group('동작', () {
    testWidgets('다른 탭은 onTap, 지금 탭은 onReselect, 가운데 + 는 추가', (tester) async {
      _viewport(tester);
      final calls = <String>[];
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _bar(
            onTap: (i) => calls.add('tap$i'),
            onReselect: (i) => calls.add('reselect$i'),
            onAdd: () => calls.add('add'),
          ),
        ),
      );
      await tester.tap(_cells.at(0));
      await tester.tap(_cells.at(1));
      await tester.tap(_addCell);
      expect(calls, ['tap0', 'reselect1', 'add']);
    });

    testWidgets('누르는 영역은 칸 전체 — 칸 모서리 안은 눌린다', (tester) async {
      _viewport(tester);
      final taps = <int>[];
      await tester.pumpWidget(_app(Brightness.light, _bar(onTap: taps.add)));
      final r = tester.getRect(_cells.at(2));
      await tester.tapAt(r.topLeft + const Offset(1, 1));
      await tester.tapAt(r.bottomRight - const Offset(1, 1));
      expect(taps, [2, 2]);
    });

    testWidgets('읽는 말 — 바 이름 · 칸은 버튼 + 선택 + 이름(새 소식) · + 는 화면마다 이름', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _viewport(tester);
      await tester.pumpWidget(_app(Brightness.light, _bar(addLabel: '일정 추가')));
      expect(find.bySemanticsLabel('주 메뉴'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('가계부 새 소식')),
        isSemantics(
          label: '가계부 새 소식',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('캘린더')),
        isSemantics(
          label: '캘린더',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('일정 추가')),
        isSemantics(
          label: '일정 추가',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('라벨은 글자 크기 설정을 따르지 않는다 · 5자 라벨도 칸 안에 들어간다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Material(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _bar(labels: const ['홈', '가계부가', '캘린더입', '전체보기']),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 4; i++) {
        final label = tester.getRect(
          find.descendant(of: _cells.at(i), matching: _label),
        );
        final cell = tester.getRect(_cells.at(i));
        expect(
          label.left >= cell.left - 0.01 && label.right <= cell.right + 0.01,
          isTrue,
          reason: '칸 $i',
        );
      }
      expect(tester.takeException(), isNull);
      final first = tester.widget<Text>(_label.first);
      expect(first.textScaler, TextScaler.noScaling);
    });

    testWidgets('컨트롤러를 주지 않으면 바가 하나 갖는다', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_app(Brightness.light, _bar()));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getRect(_pill).height, 66);
    });
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} 견본이 폰 폭 390 에서 그려진다', (tester) async {
      tester.view.physicalSize = const Size(390, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
              child: BottomNavigationDemo(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  }
}

/// 스펙 값(숫자) 한 줄 — SpecCheck 가 쥔 want 에서 꺼낸다.
num? want(SpecCheck k, String key) => k.want[key] as num?;
