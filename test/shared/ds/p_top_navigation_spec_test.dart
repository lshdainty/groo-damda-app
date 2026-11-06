// Top Navigation 이 스펙 값(test/fixtures/design_spec/top-navigation.json)대로인지 — 타입(root · standard) × 왼쪽 버튼(← · ✕ · ☰) ×
// 상태(기본 · 누름 · 막힘) × 라이트 · 다크의 바 · 제목 · 아이콘 버튼 · 글 버튼 · 알림 점 · 누름 축소와, 안전 영역 · 글자 크기 · 읽는
// 말 · 콜백. 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 값은 재지 않는다 — 웹의 hovered · focused(포커스 링), desktop 타입(768 이상 Desk 의 머리 — 앱에 없다), 쌓임(z-sticky)과
// 맨 위에 붙기(sticky)는 셸 몫이다. 스펙의 문장("아이콘 3개까지")은 그린 결과 · 단언으로 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/notification_badge/p_notification_badge.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/top_navigation_demo.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('top-navigation');

/// 앱의 상태 — 웹의 hovered · focused 는 앱에 없다.
final _appStates = _spec.states
    .where((s) => s != 'hovered' && s != 'focused')
    .toList();

/// 앱의 타입 — desktop 은 768 이상 전용이다.
const _appTypes = ['root', 'standard'];

Widget _host(
  Brightness mode,
  Widget child, {
  EdgeInsets padding = EdgeInsets.zero,
  TextScaler textScaler = TextScaler.noScaling,
  bool reduceMotion = false,
  double width = 360,
}) {
  return MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    // 견본의 검색칸(PInput)이 지우기 이름을 번역 문구에서 읽는다
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: padding,
        textScaler: textScaler,
        disableAnimations: reduceMotion,
      ),
      child: app!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

Finder _in(String scope, Finder f) =>
    find.descendant(of: find.byKey(ValueKey(scope)), matching: f);
Finder get _iconButtonBox =>
    find.byKey(const ValueKey('top-navigation-icon-button'));
Finder get _textButtonBox =>
    find.byKey(const ValueKey('top-navigation-text-button'));

BoxDecoration _deco(WidgetTester tester, Finder box) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(of: box, matching: find.byType(DecoratedBox))
                  .first,
            )
            .decoration
        as BoxDecoration;

double _scaleOf(WidgetTester tester, Finder box) => tester
    .widget<AnimatedScale>(
      find.ancestor(of: box, matching: find.byType(AnimatedScale)).first,
    )
    .scale;

IconData _glyph(String leading) => switch (leading) {
  'back' => LucideIcons.chevronLeft,
  'close' => LucideIcons.x,
  _ => LucideIcons.menu,
};

PTopNavigationIconButton _leading(String leading, {bool enabled = true}) =>
    switch (leading) {
      'back' => PTopNavigationIconButton.back(
        label: '뒤로',
        onPressed: () {},
        enabled: enabled,
      ),
      'close' => PTopNavigationIconButton.close(
        label: '닫기',
        onPressed: () {},
        enabled: enabled,
      ),
      _ => PTopNavigationIconButton.menu(
        label: '주 메뉴',
        onPressed: () {},
        enabled: enabled,
      ),
    };

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['type', 'leadingIcon'])) {
      final type = combo['type']!;
      if (!_appTypes.contains(type)) continue;
      final root = type == 'root';
      // root 는 왼쪽 버튼이 없다 — 왼쪽 버튼 축은 standard 에서만 돈다
      if (root && combo['leadingIcon'] != _spec.defaults['leadingIcon']) {
        continue;
      }
      for (final state in _appStates) {
        final title =
            '${mode.name} $type ${root ? '' : '${combo['leadingIcon']} '}$state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          final disabled = state == 'disabled';
          final pType = PTopNavigationType.values.byName(type);
          await tester.pumpWidget(
            _host(
              mode,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: const ValueKey('icons'),
                    child: PTopNavigation(
                      type: pType,
                      // 긴 제목 — 오른쪽 자리 앞 8 에서 말줄임
                      title: '카드 혜택 · 이번 달 결제 예정 금액과 실적 조건 한눈에 보기',
                      leading: root
                          ? null
                          : _leading(combo['leadingIcon']!, enabled: !disabled),
                      actions: [
                        PTopNavigationIconButton(
                          icon: LucideIcons.search,
                          label: '검색',
                          enabled: !disabled,
                          onPressed: () {},
                        ),
                        PTopNavigationIconButton(
                          icon: LucideIcons.bell,
                          label: '알림, 새 알림 있음',
                          notification: true,
                          enabled: !disabled,
                          onPressed: () {},
                        ),
                        PTopNavigationIconButton(
                          icon: LucideIcons.ellipsis,
                          label: '더보기',
                          enabled: !disabled,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  KeyedSubtree(
                    key: const ValueKey('text'),
                    child: PTopNavigation(
                      type: pType,
                      title: '알림',
                      leading: root
                          ? null
                          : _leading(combo['leadingIcon']!, enabled: !disabled),
                      actions: [
                        PTopNavigationTextButton(
                          label: '모두 읽음',
                          enabled: !disabled,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));

          final k = SpecCheck(mode, _spec.resolve(combo, state), title);
          final want = k.want;
          final bars = tester.widgetList<Container>(
            find.byKey(const ValueKey('top-navigation')),
          );
          final bar1 = tester.getRect(
            find.byKey(const ValueKey('top-navigation')).first,
          );
          final bar2 = tester.getRect(
            find.byKey(const ValueKey('top-navigation')).last,
          );

          // 바 — 높이 56 · 불투명 바탕 · 선 · 그림자 없음 · 좌우 6
          k.px('root.height', bar1.height);
          k.px('root.height', bar2.height);
          for (final bar in bars) {
            k.color('root.background', bar.color!);
            // 선 · 그림자를 긋지 않는다 — 바탕색만 칠한 상자다
            if (bar.decoration != null || bar.foregroundDecoration != null) {
              k.fail('root.shadow · borderBottomWidth: 선 · 그림자가 있다');
            }
          }
          k.m(['root.shadow', 'root.borderBottomWidth', 'trailing.items']);
          final buttons1 = tester
              .widgetList(_in('icons', _iconButtonBox))
              .length;
          final firstBox = tester.getRect(_in('icons', _iconButtonBox).first);
          final lastBox = tester.getRect(_in('icons', _iconButtonBox).last);
          final left = root ? null : firstBox;
          if (left != null) k.px('root.paddingX', left.left - bar1.left);
          k.px('root.paddingX', bar1.right - lastBox.right);
          if (buttons1 != (root ? 3 : 4)) {
            k.fail('trailing.items: 아이콘 버튼 수 $buttons1');
          }

          // 제목 — 700 · fg-neutral · 한 줄 말줄임 · 화면 끝에서 16 / 56 · 오른쪽 자리 앞 8
          final titleText = tester.widget<Text>(
            _in('icons', find.byKey(const ValueKey('top-navigation-title'))),
          );
          final titleRect = tester.getRect(
            _in('icons', find.byKey(const ValueKey('top-navigation-title'))),
          );
          final actionsLeft = tester
              .getRect(_in('icons', _iconButtonBox).at(root ? 0 : 1))
              .left;
          k.typo('title.typography', titleText.style!);
          k.weight('title.fontWeight', titleText.style!);
          k.color('title.foreground', titleText.style!.color!);
          if (titleText.maxLines != 1 ||
              titleText.overflow != TextOverflow.ellipsis) {
            k.fail('title.lineClamp: 한 줄 말줄임이 아니다');
          }
          k.m(['title.lineClamp']);
          k.px('title.marginLeft', titleRect.left - bar1.left);
          k.px(
            'title.marginLeft',
            tester
                    .getRect(
                      _in(
                        'text',
                        find.byKey(const ValueKey('top-navigation-title')),
                      ),
                    )
                    .left -
                bar2.left,
          );
          k.px('title.gap', actionsLeft - titleRect.right);

          // 오른쪽 자리 — 버튼끼리 붙는다(아이콘 중심 간격 44)
          final trailing = tester
              .widgetList(_in('icons', _iconButtonBox))
              .toList()
              .asMap()
              .keys
              .skip(root ? 0 : 1)
              .map((i) => tester.getRect(_in('icons', _iconButtonBox).at(i)))
              .toList();
          for (var i = 1; i < trailing.length; i++) {
            k.px('trailing.gap', trailing[i].left - trailing[i - 1].right);
          }

          // 아이콘 버튼 — 상자 44 · 모서리 8 · 아이콘 24 · 선 2 · 색 · 바탕
          final box = _in('icons', _iconButtonBox).at(root ? 1 : 2);
          final boxRect = tester.getRect(box);
          final icon = tester.widget<Icon>(
            find.descendant(of: box, matching: find.byType(Icon)),
          );
          k.px('iconButton.size', boxRect.width);
          k.px('iconButton.size', boxRect.height);
          k.px('iconButton.iconSize', icon.size!);
          k.px(
            'iconButton.radius',
            (_deco(tester, box).borderRadius! as BorderRadius).topLeft.x,
          );
          k.color('iconButton.color', icon.color!);
          k.m(['iconButton.strokeWidth']);
          if (icon.icon!.fontFamily != 'Lucide') {
            k.fail(
              'iconButton.strokeWidth: 선 2 글꼴(Lucide)이 아니다 — ${icon.icon!.fontFamily}',
            );
          }
          final animated = tester.widget<AnimatedContainer>(box);
          k.motion(
            'iconButton.transitionDuration',
            'iconButton.transitionEasing',
            animated.duration,
            animated.curve,
          );
          k.m(['iconButton.transitionProperty', 'iconButton.touchTarget']);
          k.cursor(
            'iconButton.cursor',
            tester
                .widget<MouseRegion>(
                  find
                      .ancestor(of: box, matching: find.byType(MouseRegion))
                      .first,
                )
                .cursor,
          );

          // 왼쪽 버튼 — 글자(← · ✕ · ☰) · 이름
          if (!root) {
            final lead = tester.widget<Icon>(
              find.descendant(
                of: _in('icons', _iconButtonBox).first,
                matching: find.byType(Icon),
              ),
            );
            if (lead.icon != _glyph(combo['leadingIcon']!)) {
              k.fail('leading.glyph: ${combo['leadingIcon']} 글자가 아니다');
            }
          }
          k.m(['leading.glyph']);

          // 알림 점 — 6 · 브랜드 글자색 · 아이콘 상자 위 1 · 오른쪽 1
          final dot = _in(
            'icons',
            find.byKey(const ValueKey('notification-badge')),
          );
          if (tester.widgetList(dot).length != 1) {
            k.fail('notification: 점이 벨 하나에만 달려야 한다');
          } else {
            final dotRect = tester.getRect(dot);
            final bellIcon = tester.getRect(
              find.descendant(
                of: _in('icons', _iconButtonBox).at(root ? 1 : 2),
                matching: find.byType(Icon),
              ),
            );
            // 벨은 둘째 아이콘 버튼 — root 는 [검색, 알림, 더보기] 의 둘째, standard 는 ← 다음 둘째
            k.px('notification.size', dotRect.width);
            k.px('notification.size', dotRect.height);
            k.px('notification.top', dotRect.top - bellIcon.top);
            k.px('notification.right', bellIcon.right - dotRect.right);
            k.color(
              'notification.background',
              (tester.widget<Container>(dot).decoration! as BoxDecoration)
                  .color!,
            );
          }

          // 글 버튼 — 높이 44 · 좌우 10 · 모서리 8 · t5 · 500
          final tb = _in('text', _textButtonBox);
          final tbRect = tester.getRect(tb);
          final label = find.descendant(of: tb, matching: findText('모두 읽음'));
          final labelRect = tester.getRect(label);
          final labelText = tester.widget<Text>(label);
          k.px('textButton.height', tbRect.height);
          k.px('textButton.paddingX', labelRect.left - tbRect.left);
          k.px('textButton.paddingX', tbRect.right - labelRect.right);
          k.px(
            'textButton.radius',
            (_deco(tester, tb).borderRadius! as BorderRadius).topLeft.x,
          );
          k.typo('textButton.typography', labelText.style!);
          k.weight('textButton.fontWeight', labelText.style!);
          k.color('textButton.foreground', labelText.style!.color!);
          final tbAnim = tester.widget<AnimatedContainer>(tb);
          k.motion(
            'textButton.transitionDuration',
            'textButton.transitionEasing',
            tbAnim.duration,
            tbAnim.curve,
          );
          k.m(['textButton.transitionProperty']);
          k.cursor(
            'textButton.cursor',
            tester
                .widget<MouseRegion>(
                  find
                      .ancestor(of: tb, matching: find.byType(MouseRegion))
                      .first,
                )
                .cursor,
          );
          // 누름 — 바탕 + 2px 거리 축소(아이콘 기준 44 · 글 버튼 기준 max(44, 폭 ÷ 4, 24))
          if (state == 'pressed') {
            final g1 = await tester.startGesture(boxRect.center);
            final g2 = await tester.startGesture(tbRect.center);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            k.color('iconButton.background', _deco(tester, box).color!);
            k.color('textButton.background', _deco(tester, tb).color!);
            k.pressScale('iconButton.scale', _scaleOf(tester, box), 44);
            final basis = [
              44.0,
              tbRect.width / 4,
              24.0,
            ].reduce((a, b) => a > b ? a : b);
            k.pressScale('textButton.scale', _scaleOf(tester, tb), basis);
            final scaleAnim = tester.widget<AnimatedScale>(
              find
                  .ancestor(of: box, matching: find.byType(AnimatedScale))
                  .first,
            );
            k.motion(
              'iconButton.scaleDuration',
              'iconButton.scaleEasing',
              scaleAnim.duration,
              scaleAnim.curve,
            );
            final scaleAnim2 = tester.widget<AnimatedScale>(
              find.ancestor(of: tb, matching: find.byType(AnimatedScale)).first,
            );
            k.motion(
              'textButton.scaleDuration',
              'textButton.scaleEasing',
              scaleAnim2.duration,
              scaleAnim2.curve,
            );
            await g1.up();
            await g2.up();
          } else {
            // 눌리지 않았으면 바탕이 없다(누를 때만 보인다)
            k.color('iconButton.background', _deco(tester, box).color!);
            k.color('textButton.background', _deco(tester, tb).color!);
            k.m([
              'iconButton.scale',
              'iconButton.scaleDuration',
              'iconButton.scaleEasing',
              'textButton.scale',
              'textButton.scaleDuration',
              'textButton.scaleEasing',
            ]);
          }

          // 웹 전용 · 셸 몫 — 포커스 링 · 호버 · 맨 위에 붙기 · 쌓임
          k.coverage({
            'root.position',
            'root.zIndex',
            'iconButton.strokeWidthOn', // 켜고 끄는 단추 동작 테스트가 잰다
            'focusRing.width',
            'focusRing.offset',
            'focusRing.color',
            // 데스크톱 머리(768 이상 Desk 웹) 전용 — 앱은 폰 틀뿐이라 재지 않는다
            'trailing.bell',
            'searchField.width',
            'searchField.height',
            'searchField.heading',
            'searchField.textField',
            'screenTitle.typography',
            'screenTitle.fontWeight',
            'screenTitle.foreground',
            'screenTitle.marginTop',
            'screenTitle.gap',
            'screenDescription.typography',
            'screenDescription.fontWeight',
            'screenDescription.foreground',
            'screenDescription.marginTop',
            'screenActions.buttonSize',
            'screenActions.gap',
            'screenActions.align',
          });
          expect(k.failures, isEmpty, reason: k.failures.join('\n'));
          expect(want.isNotEmpty, isTrue);
        });
      }
    }
  }

  group('동작', () {
    testWidgets('켜고 끄는 단추 — 켬 선 2.5 · 끔 선 2, 색은 같고 이름은 그대로다', (tester) async {
      for (final mode in Brightness.values) {
        var hidden = false;
        late StateSetter set;
        await tester.pumpWidget(
          _host(
            mode,
            StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return PTopNavigation(
                  title: '자산',
                  type: PTopNavigationType.root,
                  actions: [
                    PTopNavigationIconButton(
                      icon: hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                      selectedIcon: LucideIcons.eyeOff500,
                      selected: hidden,
                      label: '금액 가리기',
                      onPressed: () => set(() => hidden = !hidden),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        // 테마가 바뀌는 애니메이션이 끝나야 색이 다크 값이다
        await tester.pump(const Duration(milliseconds: 400));
        final want = _spec.resolve({
          'type': 'root',
          'leadingIcon': 'back',
        }, 'enabled');
        final colorWant = specColor(pickMode(want['iconButton.color'], mode));
        Icon icon() => tester.widget<Icon>(
          find.descendant(of: _iconButtonBox, matching: find.byType(Icon)),
        );
        expect(
          icon().icon!.fontFamily,
          'Lucide',
          reason: '끔 선 ${want['iconButton.strokeWidth']}',
        );
        expect(sameColor(colorWant, icon().color!), isTrue);
        await tester.tap(_iconButtonBox);
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          icon().icon!.fontFamily,
          'Lucide500',
          reason: '켬 선 ${want['iconButton.strokeWidthOn']}',
        );
        expect(
          sameColor(colorWant, icon().color!),
          isTrue,
          reason: '켬 · 끔 색이 같다',
        );
        expect(want['iconButton.strokeWidth'], 2);
        expect(want['iconButton.strokeWidthOn'], 2.5);
      }
    });

    testWidgets('누르는 영역은 상자 44 — 모서리 안은 눌리고 밖은 눌리지 않는다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTopNavigation(
            title: '알림',
            leading: PTopNavigationIconButton.back(
              label: '뒤로',
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      final r = tester.getRect(_iconButtonBox);
      await tester.tapAt(r.topLeft + const Offset(1, 1));
      await tester.tapAt(r.bottomRight - const Offset(1, 1));
      expect(taps, 2);
      await tester.tapAt(r.topLeft - const Offset(2, 2));
      await tester.tapAt(r.bottomRight + const Offset(2, 2));
      expect(taps, 2, reason: '보이지 않는 여백을 더하지 않는다');
    });

    testWidgets('막힌 버튼은 눌리지 않고 읽는 말에서 막힘이다', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTopNavigation(
            title: '메모',
            actions: [
              PTopNavigationTextButton(
                label: '완료',
                enabled: false,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(_textButtonBox, warnIfMissed: false);
      expect(taps, 0);
      final node = tester.getSemantics(find.bySemanticsLabel('완료'));
      expect(node, isSemantics(hasEnabledState: true, isEnabled: false));
      handle.dispose();
    });

    testWidgets('읽는 말 — 제목은 머리, 버튼은 이름 있는 버튼, 켜고 끄는 단추는 토글', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTopNavigation(
            title: '알림',
            leading: PTopNavigationIconButton.back(
              label: '뒤로',
              onPressed: () {},
            ),
            actions: [
              PTopNavigationIconButton(
                icon: LucideIcons.eye,
                selectedIcon: LucideIcons.eyeOff500,
                selected: false,
                label: '금액 가리기',
                onPressed: () {},
              ),
              PTopNavigationIconButton(
                icon: LucideIcons.bell,
                label: '알림, 새 알림 있음',
                notification: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      final title = tester.getSemantics(find.bySemanticsLabel('알림').first);
      expect(title, isSemantics(isHeader: true));
      final back = tester.getSemantics(find.bySemanticsLabel('뒤로'));
      expect(back, isSemantics(isButton: true, hasTapAction: true));
      final toggle = tester.getSemantics(find.bySemanticsLabel('금액 가리기'));
      expect(
        toggle,
        isSemantics(isButton: true, hasToggledState: true, isToggled: false),
      );
      // 알림 점은 읽지 않는다 — 이름이 "새 알림 있음" 을 알린다
      expect(find.bySemanticsLabel('알림, 새 알림 있음'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('왼쪽 버튼 · 글 버튼 · 아이콘 버튼의 콜백이 불린다 — 뒤로 가기는 스스로 처리하지 않는다', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTopNavigation(
            title: '카드',
            leading: PTopNavigationIconButton.close(
              label: '닫기',
              onPressed: () => calls.add('close'),
            ),
            actions: [
              PTopNavigationIconButton(
                icon: LucideIcons.search,
                label: '검색',
                onPressed: () => calls.add('search'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.tap(find.bySemanticsLabel('검색'));
      expect(calls, ['close', 'search']);
    });

    test('오른쪽은 아이콘 3개까지 또는 글 버튼 하나 — 섞거나 넘으면 막는다', () {
      PTopNavigationIconButton icon() => PTopNavigationIconButton(
        icon: LucideIcons.search,
        label: '검색',
        onPressed: () {},
      );
      final text = PTopNavigationTextButton(label: '완료', onPressed: () {});
      expect(
        () => PTopNavigation(title: 'a', actions: [icon(), icon(), icon()]),
        returnsNormally,
      );
      expect(
        () => PTopNavigation(
          title: 'a',
          actions: [icon(), icon(), icon(), icon()],
        ),
        throwsAssertionError,
      );
      expect(
        () => PTopNavigation(title: 'a', actions: [text]),
        returnsNormally,
      );
      expect(
        () => PTopNavigation(title: 'a', actions: [text, text]),
        throwsAssertionError,
      );
      expect(
        () => PTopNavigation(title: 'a', actions: [icon(), text]),
        throwsAssertionError,
      );
      expect(
        () => PTopNavigation(
          type: PTopNavigationType.root,
          title: 'a',
          leading: PTopNavigationIconButton.back(label: '뒤로', onPressed: () {}),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('위 안전 영역만큼 높아지고 바탕은 끝까지 · 내용은 그 아래 56 · 좌우 안전 영역을 더한다', (
      tester,
    ) async {
      for (final mode in Brightness.values) {
        await tester.pumpWidget(
          _host(
            mode,
            PTopNavigation(
              title: '알림',
              leading: PTopNavigationIconButton.back(
                label: '뒤로',
                onPressed: () {},
              ),
              actions: [
                PTopNavigationIconButton(
                  icon: LucideIcons.bell,
                  label: '알림',
                  onPressed: () {},
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 47, left: 20, right: 12),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        final bar = tester.getRect(
          find.byKey(const ValueKey('top-navigation')),
        );
        expect(bar.height, 56 + 47);
        final first = tester.getRect(_iconButtonBox.first);
        expect(first.top, 47 + 6, reason: '버튼은 안전 영역 아래 56 안에 가운데로 선다');
        expect(first.left, 6 + 20);
        expect(bar.right - tester.getRect(_iconButtonBox.last).right, 6 + 12);
        final c = tester.widget<Container>(
          find.byKey(const ValueKey('top-navigation')),
        );
        expect(
          c.color,
          (mode == Brightness.dark ? PColors.dark : PColors.light)
              .bgLayerDefault,
        );
      }
    });

    testWidgets('글자 크기 설정은 1.2배까지만 따른다 — 바 높이는 56 그대로', (tester) async {
      for (final (scale, expected) in [
        (0.8, 1.0),
        (1.0, 1.0),
        (1.1, 1.1),
        (2.0, 1.2),
      ]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PTopNavigation(
              type: PTopNavigationType.root,
              title: '홈',
              actions: [
                PTopNavigationTextButton(label: '모두 읽음', onPressed: () {}),
              ],
            ),
            textScaler: TextScaler.linear(scale),
          ),
        );
        final title = tester.widget<Text>(
          find.byKey(const ValueKey('top-navigation-title')),
        );
        expect(
          title.textScaler!.scale(10),
          closeTo(10 * expected, 1e-6),
          reason: '배율 $scale',
        );
        final label = tester.widget<Text>(findText('모두 읽음'));
        expect(label.textScaler!.scale(10), closeTo(10 * expected, 1e-6));
        expect(
          tester.getRect(find.byKey(const ValueKey('top-navigation'))).height,
          56,
        );
      }
    });

    testWidgets('모션 줄이기면 눌러도 줄지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTopNavigation(
            title: '알림',
            leading: PTopNavigationIconButton.back(
              label: '뒤로',
              onPressed: () {},
            ),
          ),
          reduceMotion: true,
        ),
      );
      final g = await tester.startGesture(tester.getCenter(_iconButtonBox));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_scaleOf(tester, _iconButtonBox), 1);
      await g.up();
    });

    testWidgets('알림 점은 점만 — 숫자 알약을 두지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTopNavigation(
            title: '홈',
            type: PTopNavigationType.root,
            actions: [
              PTopNavigationIconButton(
                icon: LucideIcons.bell,
                label: '알림, 새 알림 있음',
                notification: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.byType(PNotificationBadge), findsOneWidget);
      expect(
        tester.widget<PNotificationBadge>(find.byType(PNotificationBadge)).size,
        PNotificationBadgeSize.small,
      );
    });
  });

  group('검색칸(제목 자리)', () {
    Widget searchHost(TextScaler scaler, {List<Widget>? actions}) =>
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: app!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 390,
                child: PTopNavigation.search(
                  title: '검색',
                  leading: PTopNavigationIconButton.back(
                    label: '뒤로',
                    onPressed: () {},
                  ),
                  search: const PInput(
                    size: PInputSize.medium,
                    semanticLabel: '거래 검색',
                    placeholder: '거래 검색',
                    prefixIcon: LucideIcons.search,
                    clearable: true,
                  ),
                  actions:
                      actions ??
                      [
                        PTopNavigationIconButton(
                          icon: LucideIcons.slidersHorizontal,
                          label: '고급 필터',
                          onPressed: () {},
                        ),
                      ],
                ),
              ),
            ),
          ),
        );

    testWidgets('칸은 ← 다음 6(화면 끝 56)부터 오른쪽 버튼 앞 8 까지 · 높이 40 · 바 가운데', (
      tester,
    ) async {
      await tester.pumpWidget(searchHost(TextScaler.noScaling));
      final want = _spec.resolve(const {}, 'enabled');
      final field = tester.getRect(find.byType(PInput));
      final bar = tester.getRect(find.byKey(const ValueKey('top-navigation')));
      final action = tester.getRect(_iconButtonBox.last);
      expect(field.left, closeTo(56, 0.5));
      expect(field.right, closeTo(action.left - kTopNavigationTitleGap, 0.5));
      expect(field.height, closeTo(want['searchField.height']! as num, 0.5));
      expect(field.center.dy, closeTo(bar.center.dy, 0.5));
      expect(bar.height, 56);
      // 칸은 Text Field 상자형 medium(40) 이다
      final input = tester.widget<PInput>(find.byType(PInput));
      expect(input.size, PInputSize.medium);
      expect(input.variant, PInputVariant.outline);
    });

    testWidgets('화면 이름은 보이지 않는 머리말 1단계 "검색" — 글은 그리지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(searchHost(TextScaler.noScaling));
      expect(
        tester.getSemantics(
          find.byKey(const ValueKey('top-navigation-search-heading')),
        ),
        isSemantics(label: '검색', isHeader: true),
      );
      expect(findText('검색'), findsNothing);
      expect(find.byKey(const ValueKey('top-navigation-title')), findsNothing);
      handle.dispose();
    });

    testWidgets('글자 200% 에서도 칸은 1.2배까지만 따르고 바 높이는 56 그대로', (tester) async {
      await tester.pumpWidget(searchHost(const TextScaler.linear(2)));
      final scaler = MediaQuery.textScalerOf(
        tester.element(find.byType(PInput)),
      );
      expect(scaler.scale(10), closeTo(12, 1e-6));
      expect(
        tester.getRect(find.byKey(const ValueKey('top-navigation'))).height,
        56,
      );
      expect(tester.takeException(), isNull);
    });
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} 견본이 폰 폭 390 에서 그려진다', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          mode,
          const SingleChildScrollView(child: TopNavigationDemo()),
          width: 390,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  }
}
