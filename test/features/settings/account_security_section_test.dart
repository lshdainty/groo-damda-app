import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/features/settings/presentation/account_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/appearance_section.dart';
import 'package:groo_damda_app/features/settings/presentation/hide_amounts_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

/// OS 프롬프트 없이 정해진 결과만 돌려주는 가짜 인증.
class _FakeAuth extends AppLockAuth {
  _FakeAuth(this.result) : super(LocalAuthentication());

  final AppLockAuthResult result;
  int calls = 0;

  /// false 면 이 기기는 생체 인증 · 화면 잠금을 쓸 수 없다.
  bool supported = true;

  @override
  Future<bool> isDeviceSupported() async => supported;

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

class _FakeAuthUser extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
    rowId: 1,
    userId: 'tester',
    userName: 'Tester',
    userEmail: 'tester@example.com',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpAccount(
    WidgetTester tester, {
    required _FakeAuth auth,
  }) async {
    final container = ProviderContainer(
      overrides: [
        appLockAuthProvider.overrideWithValue(auth),
        authProvider.overrideWith(_FakeAuthUser.new),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        GoRoute(
          path: '/settings/hide-amounts',
          builder: (_, _) => const HideAmountsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: GrooTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  group('계정 > 보안', () {
    testWidgets('앱 잠금·금액 가리기 행이 보안 섹션에 있다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pumpAccount(
        tester,
        auth: _FakeAuth(AppLockAuthResult.success),
      );
      await container.read(settingsProvider.future);
      await tester.pump();

      expect(findText('앱 잠금'), findsOneWidget);
      expect(findText('금액 가리기'), findsOneWidget);
      // 가려진 카드 수 / 전체 — 들어가 보지 않아도 상태가 보여야 한다.
      expect(findText('0 / ${kAllHideCards.length}'), findsOneWidget);
      // '준비중' 자리표시 행은 사라졌다.
      expect(findText('준비중'), findsNothing);
      // [수정] 은 막혀 있고 이유 Callout 이 머리 아래에 선다(D3 B)
      expect(findText('프로필 수정은 곧 열려요.'), findsOneWidget);
      // 누를 수 없던 줄 넷(로그인 기록 · Apple · 카카오 · 네이버)은 걷었다(I-14 9)
      expect(findText('로그인 기록'), findsNothing);
      expect(findText('Apple ID'), findsNothing);
      expect(findText('카카오'), findsNothing);
      expect(findText('네이버'), findsNothing);
    });

    testWidgets('2단계 인증 행은 메뉴에 없다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pumpAccount(
        tester,
        auth: _FakeAuth(AppLockAuthResult.success),
      );
      await container.read(settingsProvider.future);
      await tester.pump();

      // 켜도 서버·로컬 어디에도 안 남고 백엔드에 2FA 가 아예 없었다 — 켠 줄 알고
      // 안심하게 만드는 행이라 뺐다(웹은 desk-front #360 에서 먼저 뺐다).
      expect(findText('2단계 인증'), findsNothing);
      // 바로 아래 앱 잠금은 진짜 기능이다 — 같이 사라지면 안 된다.
      expect(findText('앱 잠금'), findsOneWidget);
    });

    testWidgets('앱 잠금 스위치는 인증을 통과해야 켜진다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = _FakeAuth(AppLockAuthResult.failure);
      final container = await pumpAccount(tester, auth: auth);
      await container.read(settingsProvider.future);
      await tester.pump();

      // 2단계 인증을 뺀 뒤 보안 섹션의 스위치는 앱 잠금 하나뿐이다.
      // 스위치 줄은 ds List 스위치 줄이다(옛 shared/widgets PSwitch 아님)
      final switches = find.byType(PListSwitchItem);
      expect(switches, findsOneWidget);
      await tester.tap(switches.first);
      // 계정 화면의 다른 구역(구독 등)은 받는 중이라 Skeleton 이 늘 돈다 — 가라앉기를 기다리지 않는다
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(auth.calls, 1);
      // 인증 실패 → 꺼진 채로 남는다.
      expect(container.read(appLockEnabledProvider), false);
    });

    testWidgets('생체 인증을 쓸 수 없는 기기 — 스낵바 없이 스위치가 막히고 까닭이 줄에 늘 보인다', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final auth = _FakeAuth(AppLockAuthResult.unavailable)..supported = false;
      final container = await pumpAccount(tester, auth: auth);
      await container.read(settingsProvider.future);
      await tester.pump();

      expect(findText('이 기기에서는 생체 인증을 쓸 수 없어요.'), findsOneWidget);
      final item = tester.widget<PListSwitchItem>(find.byType(PListSwitchItem));
      expect(item.onChanged, isNull); // 막힌 줄
      expect(item.checked, isFalse);

      await tester.tap(find.byType(PListSwitchItem), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(auth.calls, 0); // 인증을 부르지도 않는다
      expect(container.read(appLockEnabledProvider), false);
      // 스낵바로는 더 이상 말하지 않는다 — 글이 한 군데(줄 설명)에만 있다
      expect(findText('이 기기에서는 생체 인증을 쓸 수 없어요.'), findsOneWidget);
    });

    testWidgets('생체 인증을 쓸 수 있으면 안내 글이 없고 스위치가 열려 있다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pumpAccount(
        tester,
        auth: _FakeAuth(AppLockAuthResult.success),
      );
      await container.read(settingsProvider.future);
      await tester.pump();

      expect(findText('이 기기에서는 생체 인증을 쓸 수 없어요.'), findsNothing);
      expect(
        tester.widget<PListSwitchItem>(find.byType(PListSwitchItem)).onChanged,
        isNotNull,
      );
    });

    testWidgets('금액 가리기 행을 누르면 전용 화면으로 간다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pumpAccount(
        tester,
        auth: _FakeAuth(AppLockAuthResult.success),
      );
      await container.read(settingsProvider.future);
      await tester.pump();

      await tester.tap(findText('금액 가리기'));
      await tester.pumpAndSettle();

      // 전용 화면 — '전체' 탭에서 카드 목록이 바로 보이고, 저장 버튼이 아래 붙는다.
      expect(findPlain('전체'), findsOneWidget);
      expect(findPlain('순자산'), findsOneWidget);
      expect(findPlain('저장'), findsOneWidget);
    });
  });

  group('표시 설정', () {
    testWidgets('개인정보 보호 섹션이 빠지고 값 줄 넷만 남는다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWith((_) => SharedPreferences.getInstance()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppearanceScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(findText('테마'), findsOneWidget);
      expect(findText('언어'), findsOneWidget);
      expect(findText('기준 지역'), findsOneWidget);
      expect(findText('기본 통화'), findsOneWidget);
      expect(findText('개인정보 보호'), findsNothing);
      expect(findText('앱 잠금'), findsNothing);
      expect(findText('금액 가리기'), findsNothing);
    });
  });
}
