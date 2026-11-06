// 강제 업데이트에서 취소를 눌렀을 때 — 넘어가지지 않아야 한다.
//
// 모델(shouldGate)은 강제면 건너뛰기를 무시하도록 이미 고정돼 있다. 여기서 보는 건
// 화면이다. 취소가 건너뛰기를 기록해 버리면 다음에 앱을 켤 때 게이트가 안 열린다 —
// 서버와 어긋난 앱을 계속 쓰게 된다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/update/presentation/update_gate_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

AppRelease _release({required int build, int minBuild = 0}) => AppRelease(
  version: '9.9.9',
  buildNumber: build,
  androidFile: 'a.apk',
  iosFile: 'a.ipa',
  notes: '새 기능\n- 무엇',
  minBuildNumber: minBuild,
);

Future<ProviderContainer> _pumpGate(
  WidgetTester tester, {
  required bool forced,
}) async {
  final status = UpdateStatus(
    currentBuild: 100,
    latest: _release(build: 101, minBuild: forced ? 101 : 0),
  );
  final container = ProviderContainer(
    overrides: [updateStatusProvider.overrideWith((ref) async => status)],
  );
  addTearDown(container.dispose);

  // 취소(일반)는 context.go('/home') 로 빠져나간다 — 라우터가 없으면 거기서 터진다.
  final router = GoRouter(
    initialLocation: '/gate',
    routes: [
      GoRoute(path: '/gate', builder: (_, _) => const UpdateGateScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('홈')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

// 띄어쓰기 단위 줄바꿈(keepAll)이 글 사이에 넣는 보이지 않는 글자는 빼고 찾는다.
Finder _text(String s) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('\u2060', '') == s,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('강제 — 취소를 눌러도 건너뛰기가 기록되지 않는다', (tester) async {
    final container = await _pumpGate(tester, forced: true);

    expect(container.read(updateStatusProvider).value!.mustUpdate, isTrue);

    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();

    // 왜 못 넘어가는지 알린다.
    expect(_text('꼭 필요한 업데이트가 들어 있어요.'), findsOneWidget);
    // 그리고 건너뛰기는 안 남는다 — 남으면 다음에 켤 때 게이트가 안 열린다.
    expect(container.read(skippedBuildProvider), isNull);
  });

  testWidgets('강제 — 기록이 없으니 다시 켜도 막힌다', (tester) async {
    final container = await _pumpGate(tester, forced: true);
    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();

    final status = container.read(updateStatusProvider).value!;
    expect(status.shouldGate(container.read(skippedBuildProvider)), isTrue);
  });

  testWidgets('일반 — 취소하면 그 빌드를 건너뛴다', (tester) async {
    final container = await _pumpGate(tester, forced: false);

    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();

    expect(container.read(skippedBuildProvider), 101);
    // 경고 다이얼로그는 안 뜬다 — 넘어가도 되는 업데이트다. 게이트를 빠져나간다.
    expect(_text('꼭 필요한 업데이트가 들어 있어요.'), findsNothing);
    expect(findText('홈'), findsOneWidget);
  });
}
