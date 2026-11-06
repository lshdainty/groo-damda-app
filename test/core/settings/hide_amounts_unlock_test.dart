import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/hide_cards_fake.dart';
import '../../support/plain_text.dart';

/// OS 프롬프트 없이 정해진 결과만 돌려주는 가짜 인증.
class _FakeAuth extends AppLockAuth {
  _FakeAuth(this.result) : super(LocalAuthentication());

  final AppLockAuthResult result;
  int calls = 0;
  String? lastReason;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async {
    calls++;
    lastReason = reason;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 금액 가리기 해제를 부르는 최소 화면 — 버튼 하나로 [setHideCardsWithUnlock] 호출.
  Future<ProviderContainer> pumpUnlocker(
    WidgetTester tester, {
    required _FakeAuth auth,
    required bool appLock,
  }) async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.appLock: appLock,
      // 홈 카드 하나를 가려 둔 상태에서 시작 — 풀기를 눌러야 인증이 돈다.
      PrefsKeys.hideCards: <String>['home.netWorth'],
    });
    final container = ProviderContainer(
      overrides: [
        appLockAuthProvider.overrideWithValue(auth),
        hideCardsRepositoryProvider.overrideWith(
          (ref) async => OkHideCardsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    // 게이트 없이도 잠금 상태가 굴러가도록 구독만 열어 둔다.
    container.listen(appLockedProvider, (_, _) {});
    await container.read(settingsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: GrooTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => setHideCardsWithUnlock(
                  context,
                  ref,
                  cards: const ['home.netWorth'],
                  hide: false,
                ),
                child: const Text('풀기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  group('금액 가리기 해제', () {
    testWidgets('앱 잠금이 켜져 있으면 생체인증으로 풀린다 — 비밀번호를 묻지 않는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpUnlocker(tester, auth: auth, appLock: true);

      await tester.tap(findText('풀기'));
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      // 금액 보기용 문구 — 앱 잠금 해제 문구를 돌려 쓰지 않는다.
      expect(auth.lastReason, '금액을 다시 보려면 본인 확인이 필요해요.');
      expect(findPlain('금액 보기 인증'), findsNothing);
      expect(
        container.read(settingsProvider).value?.isHidden('home.netWorth'),
        false,
      );
    });

    testWidgets('생체인증을 취소하면 비밀번호 시트로 물러선다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.failure);
      final container = await pumpUnlocker(tester, auth: auth, appLock: true);

      await tester.tap(findText('풀기'));
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      expect(findPlain('금액 보기 인증'), findsOneWidget);
      // 시트를 닫으면(위 닫기 원) 가린 채로 남는다.
      await tester.tap(find.bySemanticsLabel('닫기').last);
      await tester.pumpAndSettle();
      expect(
        container.read(settingsProvider).value?.isHidden('home.netWorth'),
        true,
      );
    });

    testWidgets('인증 수단이 없는 기기도 비밀번호로 물러선다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.unavailable);
      await pumpUnlocker(tester, auth: auth, appLock: true);

      await tester.tap(findText('풀기'));
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      expect(findPlain('금액 보기 인증'), findsOneWidget);
    });

    testWidgets('앱 잠금이 꺼져 있으면 프롬프트 없이 바로 비밀번호를 묻는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpUnlocker(tester, auth: auth, appLock: false);

      await tester.tap(findText('풀기'));
      await tester.pumpAndSettle();

      // 켠 적 없는 사람에게 Face ID 를 들이밀지 않는다.
      expect(auth.calls, 0);
      expect(findPlain('금액 보기 인증'), findsOneWidget);
    });

    testWidgets('가리기는 인증 없이 바로 걸린다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      SharedPreferences.setMockInitialValues({PrefsKeys.appLock: true});
      final container = ProviderContainer(
        overrides: [
          appLockAuthProvider.overrideWithValue(auth),
          hideCardsRepositoryProvider.overrideWith(
            (ref) async => OkHideCardsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(appLockedProvider, (_, _) {});
      await container.read(settingsProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => setHideCardsWithUnlock(
                    context,
                    ref,
                    cards: kAllHideCards,
                    hide: true,
                  ),
                  child: const Text('가리기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(findText('가리기'));
      await tester.pumpAndSettle();

      expect(auth.calls, 0);
      expect(
        container.read(settingsProvider).value?.hideCards.length,
        kAllHideCards.length,
      );
    });
  });
}
