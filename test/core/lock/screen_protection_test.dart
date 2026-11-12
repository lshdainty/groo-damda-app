import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/lock/app_lock_gate.dart';
import 'package:groo_damda_app/core/lock/screen_protection.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 앱 잠금 · 금액 가리기 중 네이티브 화면 보호(보안 점검 CLI-5).
///
/// 안드로이드는 FLAG_SECURE, iOS 는 백그라운드 가림막 — 둘 다 `porest/screen_privacy`
/// 채널의 `setProtected` 하나로 켜고 끈다. 여기서는 Dart 가 언제 무엇을 보내는지를 고정한다.
const _channel = MethodChannel('porest/screen_privacy');

class _AlwaysUnlock extends AppLockAuth {
  _AlwaysUnlock() : super(LocalAuthentication());

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async => AppLockAuthResult.success;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<bool> sent;

  setUp(() {
    sent = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          expect(call.method, 'setProtected');
          sent.add((call.arguments as Map)['on'] as bool);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [appLockAuthProvider.overrideWithValue(_AlwaysUnlock())],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('screenProtectionWantedProvider', () {
    test('잠금도 가리기도 없으면 보호하지 않는다', () async {
      SharedPreferences.setMockInitialValues({});
      final c = container();
      await c.read(settingsProvider.future);
      expect(c.read(screenProtectionWantedProvider), false);
    });

    test('앱 잠금을 켰으면 보호한다', () async {
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final c = container();
      await c.read(settingsProvider.future);
      expect(c.read(screenProtectionWantedProvider), true);
    });

    test('금액을 하나라도 가려 두었으면 보호한다', () async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.hideCards: ['home.netWorth'],
      });
      final c = container();
      await c.read(settingsProvider.future);
      expect(c.read(screenProtectionWantedProvider), true);
    });
  });

  group('ScreenProtection.apply', () {
    test('안드로이드 · iOS 에서는 채널로 값을 보낸다', () async {
      for (final p in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = p;
        await const ScreenProtection().apply(true);
        await const ScreenProtection().apply(false);
      }
      debugDefaultTargetPlatformOverride = null;
      expect(sent, [true, false, true, false]);
    });

    test('그 밖의 플랫폼에서는 보내지 않는다', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await const ScreenProtection().apply(true);
      debugDefaultTargetPlatformOverride = null;
      expect(sent, isEmpty);
    });

    test('네이티브가 없거나 실패해도 던지지 않는다', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            throw PlatformException(code: 'boom');
          });
      await expectLater(const ScreenProtection().apply(true), completes);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
      await expectLater(const ScreenProtection().apply(true), completes);
    });
  });

  group('AppLockGate 가 보호를 켜고 끈다', () {
    Future<ProviderContainer> pumpGate(
      WidgetTester tester,
      Map<String, Object> prefs,
    ) async {
      SharedPreferences.setMockInitialValues(prefs);
      final c = container();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
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
      return c;
    }

    testWidgets('잠금이 켜진 채 시작하면 보호를 건다', (tester) async {
      await pumpGate(tester, {PrefsKeys.appLock: true});
      expect(sent.last, true);
    });

    testWidgets('금액을 가려 둔 채 시작하면 보호를 건다', (tester) async {
      await pumpGate(tester, {
        PrefsKeys.hideCards: ['home.netWorth'],
      });
      expect(sent.last, true);
    });

    testWidgets('둘 다 없으면 보호를 걸지 않는다', (tester) async {
      await pumpGate(tester, {});
      expect(sent.contains(true), false);
    });

    testWidgets('잠금을 켜고 끄면 보호도 따라 켜고 끈다 — 같은 값은 다시 보내지 않는다', (tester) async {
      final c = await pumpGate(tester, {});
      sent.clear();

      await tester.runAsync(
        () => c.read(settingsProvider.notifier).setAppLock(true),
      );
      await tester.pumpAndSettle();
      expect(sent, [true]);

      await tester.runAsync(
        () => c.read(settingsProvider.notifier).setAppLock(false),
      );
      await tester.pumpAndSettle();
      expect(sent, [true, false]);
    });
  });
}
