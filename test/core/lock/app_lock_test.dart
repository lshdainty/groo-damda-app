import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/lock/app_lock_gate.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

/// OS 프롬프트 없이 정해진 결과만 돌려주는 가짜 인증.
///
/// 모든 메서드를 override 하므로 감싼 [LocalAuthentication] 은 절대 호출되지 않는다
/// (생성만으로는 플랫폼 채널을 건드리지 않는다).
class _FakeAuth extends AppLockAuth {
  _FakeAuth(this.result) : super(LocalAuthentication());

  final AppLockAuthResult result;
  int calls = 0;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async {
    calls++;
    return result;
  }
}

ProviderContainer _container({AppLockAuth? auth}) {
  final container = ProviderContainer(
    overrides: [if (auth != null) appLockAuthProvider.overrideWithValue(auth)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('appLockedProvider', () {
    test('설정이 꺼져 있으면(기본값) 잠기지 않는다', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      container.listen(appLockedProvider, (_, _) {});
      await container.read(settingsProvider.future);
      expect(container.read(appLockedProvider), false);
    });

    test('콜드 스타트: 저장된 설정이 켜져 있으면 로드 즉시 잠긴다', () async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final container = _container();
      // 설정 로드 전에 게이트가 먼저 구독하는 실제 순서.
      container.listen(appLockedProvider, (_, _) {});
      expect(container.read(appLockedProvider), false);
      await container.read(settingsProvider.future);
      expect(container.read(appLockedProvider), true);
    });

    test('설정이 먼저 로드된 뒤 구독해도 잠긴 초기값을 얻는다', () async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final container = _container();
      await container.read(settingsProvider.future);
      container.listen(appLockedProvider, (_, _) {});
      expect(container.read(appLockedProvider), true);
    });

    test('unlock 후 lock 은 설정이 켜져 있을 때만 다시 잠근다', () async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final container = _container();
      container.listen(appLockedProvider, (_, _) {});
      await container.read(settingsProvider.future);

      container.read(appLockedProvider.notifier).unlock();
      expect(container.read(appLockedProvider), false);

      container.read(appLockedProvider.notifier).lock();
      expect(container.read(appLockedProvider), true);
    });

    test('설정을 끄면 즉시 해제되고 lock 도 듣지 않는다', () async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final container = _container();
      container.listen(appLockedProvider, (_, _) {});
      await container.read(settingsProvider.future);
      expect(container.read(appLockedProvider), true);

      await container.read(settingsProvider.notifier).setAppLock(false);
      expect(container.read(appLockedProvider), false);

      container.read(appLockedProvider.notifier).lock();
      expect(container.read(appLockedProvider), false);
    });

    test('사용 중 설정을 켜는 순간에는 잠기지 않는다 — 방금 인증한 사람을 또 세우지 않는다', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      container.listen(appLockedProvider, (_, _) {});
      await container.read(settingsProvider.future);

      await container.read(settingsProvider.notifier).setAppLock(true);
      expect(container.read(appLockedProvider), false);

      // 다음 백그라운드 진입부터는 잠긴다.
      container.read(appLockedProvider.notifier).lock();
      expect(container.read(appLockedProvider), true);
    });

    test('설정 저장은 SharedPreferences 에 남는다', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setAppLock(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(PrefsKeys.appLock), true);
      expect(container.read(settingsProvider).value?.appLock, true);
    });
  });

  group('AppLockGate', () {
    Future<ProviderContainer> pumpGate(
      WidgetTester tester,
      _FakeAuth auth,
    ) async {
      final container = _container(auth: auth);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                AppLockGate(child: child ?? const SizedBox()),
            home: const Text('콘텐츠'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('잠긴 채 시작 — 자동 프롬프트가 실패하면 잠금 화면을 유지한다', (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final auth = _FakeAuth(AppLockAuthResult.failure);
      final container = await pumpGate(tester, auth);

      expect(container.read(appLockedProvider), true);
      expect(findText('앱 잠금'), findsOneWidget);
      expect(findText('잠금 해제'), findsOneWidget);
      expect(auth.calls, 1); // 마운트 시 자동 프롬프트 1회
    });

    testWidgets('잠금 화면 버튼이 인증을 다시 부른다', (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final auth = _FakeAuth(AppLockAuthResult.failure);
      await pumpGate(tester, auth);
      expect(auth.calls, 1);

      await tester.tap(findText('잠금 해제'));
      await tester.pumpAndSettle();
      expect(auth.calls, 2);
      expect(findText('앱 잠금'), findsOneWidget); // 실패라 여전히 잠김
    });

    testWidgets('자동 프롬프트가 성공하면 잠금 화면이 걷힌다', (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpGate(tester, auth);

      expect(auth.calls, 1);
      expect(container.read(appLockedProvider), false);
      expect(findText('앱 잠금'), findsNothing);
      expect(findText('콘텐츠'), findsOneWidget);
    });

    testWidgets('인증 수단이 사라진 기기는 가두지 않는다 — unavailable 이면 열어 준다', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final auth = _FakeAuth(AppLockAuthResult.unavailable);
      final container = await pumpGate(tester, auth);

      expect(container.read(appLockedProvider), false);
      expect(findText('앱 잠금'), findsNothing);
    });

    testWidgets('설정이 꺼져 있으면 프롬프트 없이 콘텐츠가 보인다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpGate(tester, auth);

      expect(findText('콘텐츠'), findsOneWidget);
      expect(findText('앱 잠금'), findsNothing);
      expect(auth.calls, 0);
    });
  });
}
