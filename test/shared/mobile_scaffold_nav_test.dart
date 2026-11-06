// 모바일 셸의 틀 — 상단 바(root) · 가계부 Line Tabs · 하단 탭 바(+ 이름 · 다시 누르기).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/mobile_scaffold.dart';
import '../support/plain_text.dart';

class _Screen extends StatelessWidget {
  const _Screen(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text(name),
      for (var i = 0; i < 60; i++) SizedBox(height: 60, child: Text('$name$i')),
    ],
  );
}

/// 입력 상태를 가진 화면 — 탭을 옮겨도 남는지 본다.
class _Counter extends StatefulWidget {
  const _Counter(this.name);
  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      TextButton(
        key: ValueKey('inc-${widget.name}'),
        onPressed: () => setState(() => n++),
        child: Text('${widget.name}:$n'),
      ),
    ],
  );
}

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    for (final tab in [MoneyTab.assets, MoneyTab.stats, MoneyTab.budget])
      GoRoute(path: tab.legacyPath, redirect: (_, _) => tab.location),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
      branches:
          [
            for (final paths in [
              ['/home'],
              ['/calendar'],
              ['/more'],
            ])
              StatefulShellBranch(
                routes: [
                  for (final p in paths)
                    GoRoute(
                      path: p,
                      builder: (_, _) => _Screen(p.substring(1)),
                    ),
                ],
              ),
          ]..insert(
            1,
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/expense',
                  builder: (_, state) => MoneyBundleScreen(
                    tab: MoneyTab.fromQuery(state.uri.queryParameters['tab']),
                    pages: const [
                      _Counter('expense'),
                      _Counter('assets'),
                      _Counter('stats'),
                      _Counter('budget'),
                    ],
                  ),
                ),
              ],
            ),
          ),
    ),
  ],
);

void main() {
  Future<GoRouter> pump(
    WidgetTester tester,
    String initial, {
    int unread = 0,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final router = _router(initial);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [unreadCountProvider.overrideWith((ref) async => unread)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder tab(String name) => find.bySemanticsLabel(name);

  testWidgets('홈 — root 상단 바 제목 · 검색 + 알림, + 는 거래 추가', (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, '/home');
    final bar = tester.widget<PTopNavigation>(find.byType(PTopNavigation));
    expect(bar.type, PTopNavigationType.root);
    expect(bar.title, '홈');
    expect(bar.actions, hasLength(2));
    expect(find.byType(PTabs<String>), findsNothing);
    expect(find.bySemanticsLabel('거래 추가'), findsOneWidget);
    h.dispose();
  });

  testWidgets('안 읽은 알림이 있으면 벨에 점과 이름이 붙는다', (tester) async {
    await pump(tester, '/home', unread: 3);
    final bell = tester
        .widgetList<PTopNavigationIconButton>(
          find.byType(PTopNavigationIconButton),
        )
        .last;
    expect(bell.notification, isTrue);
    expect(bell.label, '알림, 새 알림 있음');
  });

  testWidgets('캘린더 — 검색만, + 는 일정 추가', (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, '/calendar');
    final bar = tester.widget<PTopNavigation>(find.byType(PTopNavigation));
    expect(bar.title, '캘린더');
    expect(bar.actions, hasLength(1));
    expect(find.bySemanticsLabel('일정 추가'), findsOneWidget);
    h.dispose();
  });

  testWidgets('가계부 — 탭 바는 "가계부" 현재, 위 Line Tabs(medium)가 네 화면을 오간다', (
    tester,
  ) async {
    final router = await pump(tester, '/expense?tab=assets');
    final tabs = tester.widget<PTabs<MoneyTab>>(find.byType(PTabs<MoneyTab>));
    expect(tabs.value, MoneyTab.assets);
    expect(tabs.size, PTabsSize.medium);
    expect(tabs.items.map((t) => t.label), ['가계부', '자산', '통계', '예산']);
    expect(
      tester.widget<PTopNavigation>(find.byType(PTopNavigation)).title,
      '가계부',
    );
    for (final t in MoneyTab.values) {
      router.go(t.location);
      await tester.pumpAndSettle();
      final bar = tester.widget<PBottomNavigation>(
        find.byType(PBottomNavigation),
      );
      expect(bar.items.map((i) => i.current), [false, true, false, false]);
    }
    await tester.tap(findText('예산').first);
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters['tab'], 'budget');
    expect(
      tester.widget<PTabs<MoneyTab>>(find.byType(PTabs<MoneyTab>)).value,
      MoneyTab.budget,
    );
  });

  testWidgets('탭을 옮겨도 앞 탭의 상태가 남는다', (tester) async {
    await pump(tester, '/expense');
    await tester.tap(find.byKey(const ValueKey('inc-expense')));
    await tester.pump();
    expect(findText('expense:1'), findsOneWidget);

    await tester.tap(findText('통계').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(PTabs<MoneyTab>),
        matching: findText('가계부'),
      ),
    );
    await tester.pumpAndSettle();
    expect(findText('expense:1'), findsOneWidget);
  });

  testWidgets('좌우로 밀면 탭이 옮겨진다', (tester) async {
    final router = await pump(tester, '/expense');
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters['tab'], 'assets');
    expect(
      tester.widget<PTabs<MoneyTab>>(find.byType(PTabs<MoneyTab>)).value,
      MoneyTab.assets,
    );
  });

  testWidgets('옛 경로(/assets /stats /budget)는 그 탭을 고른 채 묶음으로 간다', (
    tester,
  ) async {
    for (final t in [MoneyTab.assets, MoneyTab.stats, MoneyTab.budget]) {
      final router = await pump(tester, t.legacyPath);
      expect(router.state.matchedLocation, '/expense', reason: t.query);
      expect(
        tester.widget<PTabs<MoneyTab>>(find.byType(PTabs<MoneyTab>)).value,
        t,
      );
    }
  });

  testWidgets('이미 묶음에 있어도 다른 경로의 링크가 탭을 고른다', (tester) async {
    final router = await pump(tester, '/expense');
    router.go('/stats');
    await tester.pumpAndSettle();
    expect(
      tester.widget<PTabs<MoneyTab>>(find.byType(PTabs<MoneyTab>)).value,
      MoneyTab.stats,
    );
  });

  testWidgets('가계부 탭을 다시 누르면 첫 탭(/expense)으로 간다', (tester) async {
    final router = await pump(tester, '/expense?tab=stats');
    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(1),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/expense');
  });

  testWidgets('지금 탭을 다시 누르면 맨 위로 올라간다', (tester) async {
    await pump(tester, '/home');
    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      greaterThan(0),
    );

    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(0),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
  });

  testWidgets('다른 탭을 누르면 그 branch 로 간다', (tester) async {
    final router = await pump(tester, '/home');
    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(3),
    );
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '/more');
  });

  testWidgets('탭을 옮겼다 돌아오면 그 탭의 스크롤 자리가 남는다(탭 기억)', (tester) async {
    await pump(tester, '/calendar');
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    double offset() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    final before = offset();
    expect(before, greaterThan(0));
    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(0),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(2),
    );
    await tester.pumpAndSettle();
    expect(offset(), before);
  });
}
