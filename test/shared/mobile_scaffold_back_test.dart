// 기기(제스처·하드웨어) 뒤로가기가 앱을 끄던 문제를 고정한다(사용자 신고 2026-09-09).
//
// 가계부처럼 홈이 아닌 branch 의 첫 화면은 그 branch 네비게이터에 팝할 것이 없어
// 뒤로가기가 루트까지 올라갔고, 아무도 받지 않아 SystemNavigator.pop 으로 앱이
// 꺼졌다. 셸 안 ← 버튼만 goBranch(0) 을 들고 있었던 탓이다.
//
// 그래서 여기서 보는 건 "홈으로 가느냐" 하나가 아니다. 셸에 PopScope 를 걸면
// 시트·다이얼로그나 branch 안에 push 한 화면까지 가로채 "시트가 안 닫히고 홈으로
// 튀는" 더 나쁜 버그가 되기 쉬워, 그 둘이 먼저 소비되는지도 함께 고정한다.
//
// 뒤로가기는 실제 기기와 같은 경로로 넣는다 — flutter/navigation 채널의 popRoute.
// 앱이 꺼지는지는 SystemChannels.platform 으로 나가는 SystemNavigator.pop 으로 본다
// (아무 observer 도 처리하지 않았을 때 WidgetsBinding 이 마지막에 부르는 것).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/shared/widgets/branch_back_to_home.dart';
import 'package:groo_damda_app/shared/widgets/mobile_scaffold.dart';
import '../support/plain_text.dart';

/// branch 화면 대역 — 실제 화면은 네트워크 provider 를 물고 있어 셸 동작만 본다.
/// 시트·다이얼로그를 여는 버튼은 앱과 같은 헬퍼를 쓴다(showModalBottomSheet / showDialog — 옛 showPSheet 는 걷었다).
class _Screen extends StatelessWidget {
  const _Screen(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name),
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const Text('시트 내용'),
            ),
            child: const Text('시트 열기'),
          ),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(content: Text('다이얼로그 내용')),
            ),
            child: const Text('다이얼로그 열기'),
          ),
        ],
      ),
    );
  }
}

/// 실제 `lib/app/router.dart` 의 셸 모양을 그대로 미러한다 —
/// branch 0 홈 / branch 1 가계부(4 path) / branch 2 캘린더 / branch 3 전체.
/// `/expense/detail` 만 테스트용으로 더 팠다: 지금 branch 안에 push 되는 화면이
/// 하나도 없어서, 생겼을 때 홈으로 튀지 않는다는 걸 미리 못 박아 둔다.
///
/// 홈이 아닌 branch 의 첫 화면은 라우터와 똑같이 BranchBackToHome 으로 감싼다
/// (뒤로가기를 받는 주체가 셸이 아니라 그 화면이다 — 셸에 걸면 예측형 뒤로가기에서
/// 앱이 꺼진다). /expense/detail 은 감싸지 않는다 — 감싸면 상세에서 뒤로가기가
/// 상세를 닫는 대신 홈으로 튄다.
GoRouter _buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const _Screen('home')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expense',
                builder: (_, state) => BranchBackToHome(
                  child: MoneyBundleScreen(
                    tab: MoneyTab.fromQuery(state.uri.queryParameters['tab']),
                    pages: const [
                      _Screen('expense'),
                      _Screen('assets'),
                      _Screen('stats'),
                      _Screen('budget'),
                    ],
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (_, _) => const _Screen('detail'),
                  ),
                ],
              ),
              for (final tab in [
                MoneyTab.assets,
                MoneyTab.stats,
                MoneyTab.budget,
              ])
                GoRoute(path: tab.legacyPath, redirect: (_, _) => tab.location),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('calendar')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('more')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  late List<MethodCall> platformCalls;

  /// 기기 뒤로가기 — 엔진이 보내는 것과 같은 플랫폼 메시지를 넣는다.
  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  bool appExited() =>
      platformCalls.any((c) => c.method == 'SystemNavigator.pop');

  Future<GoRouter> pumpShell(
    WidgetTester tester,
    String initialLocation,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final router = _buildRouter(initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 홈 헤더의 알림 벨이 읽는다 — 네트워크를 태우지 않는다.
          unreadCountProvider.overrideWith((ref) async => 0),
        ],
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

  setUp(() {
    platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('가계부에서 기기 뒤로가기는 홈으로 간다 — 앱이 꺼지지 않는다', (tester) async {
    final router = await pumpShell(tester, '/expense');
    expect(router.state.matchedLocation, '/expense');

    await pressSystemBack(tester);

    expect(router.state.matchedLocation, '/home');
    expect(appExited(), isFalse);
  });

  testWidgets('가계부 안 다른 화면(/assets)에서도 홈으로 간다', (tester) async {
    final router = await pumpShell(tester, '/assets');

    await pressSystemBack(tester);

    expect(router.state.matchedLocation, '/home');
    expect(appExited(), isFalse);
  });

  testWidgets('캘린더·전체 branch 도 같다 — 홈으로 간다', (tester) async {
    for (final start in ['/calendar', '/more']) {
      final router = await pumpShell(tester, start);

      await pressSystemBack(tester);

      expect(router.state.matchedLocation, '/home', reason: start);
      expect(appExited(), isFalse, reason: start);
    }
  });

  testWidgets('홈에서는 종전대로 — 뒤로가기를 막지 않는다', (tester) async {
    final router = await pumpShell(tester, '/home');

    await pressSystemBack(tester);

    // 셸이 삼키지 않으므로 프레임워크가 그대로 앱을 닫는다.
    expect(router.state.matchedLocation, '/home');
    expect(appExited(), isTrue);
  });

  testWidgets('시트가 열려 있으면 시트만 닫는다 — 홈으로 튀지 않는다', (tester) async {
    final router = await pumpShell(tester, '/expense');
    await tester.tap(findText('시트 열기'));
    await tester.pumpAndSettle();
    expect(findText('시트 내용'), findsOneWidget);

    await pressSystemBack(tester);

    expect(findText('시트 내용'), findsNothing);
    expect(router.state.matchedLocation, '/expense');
    expect(appExited(), isFalse);
  });

  testWidgets('다이얼로그가 열려 있으면 다이얼로그만 닫는다', (tester) async {
    final router = await pumpShell(tester, '/expense');
    await tester.tap(findText('다이얼로그 열기'));
    await tester.pumpAndSettle();
    expect(findText('다이얼로그 내용'), findsOneWidget);

    await pressSystemBack(tester);

    expect(findText('다이얼로그 내용'), findsNothing);
    expect(router.state.matchedLocation, '/expense');
    expect(appExited(), isFalse);
  });

  testWidgets('branch 안에 push 한 화면이 있으면 그것부터 닫는다', (tester) async {
    final router = await pumpShell(tester, '/expense');
    router.push('/expense/detail');
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '/expense/detail');

    // 1) 상세부터 닫는다 — 홈으로 튀지 않는다.
    await pressSystemBack(tester);
    expect(router.state.matchedLocation, '/expense');
    expect(appExited(), isFalse);

    // 2) 그다음 뒤로가기가 홈으로 간다.
    await pressSystemBack(tester);
    expect(router.state.matchedLocation, '/home');
    expect(appExited(), isFalse);
  });
}
