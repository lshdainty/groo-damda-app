// 해지 완료 화면 — 웹 /withdrawn 과 같은 화면이 앱에도 있다(2026-09-22 사용자 결정).
//
// 두 길로 들어온다. ① 해지 직후(해지 시트가 보낸다) ② 해지한 계정의 로그인 시도
// (USER_021 — 라우터가 보낸다). 예전엔 ① 은 6초 토스트(폰에서 4줄, 재가입 안내 없음),
// ② 는 로그인 화면의 빨간 에러 글(데이터 안내 없음)이라 사라지거나 서로 다른 말을 했다.
//
// 이 파일이 붙잡는 것:
//  - 화면에 해지 끝 · 데이터 보관·파기 · 재가입 불가가 다 나온다
//  - 로그아웃 상태에서도 이 화면에 머문다(해지 직후 로그아웃이 로그인으로 튕기지 않는다)
//  - [로그인 화면으로] · 뒤로가기 는 로그인 화면으로 — 다시 튕기지도, 앱이 닫히지도 않는다
//  - 해지를 마치면 토스트가 아니라 이 화면이 뜨고 로그아웃한다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/router.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/auth/presentation/withdrawn_screen.dart';
import 'package:groo_damda_app/features/settings/application/withdrawal_providers.dart';
import 'package:groo_damda_app/features/settings/data/withdrawal_repository.dart';
import 'package:groo_damda_app/features/settings/domain/withdrawal_check.dart';
import 'package:groo_damda_app/features/settings/presentation/withdrawal_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import '../../support/plain_text.dart';

const _user = User(
  rowId: 1,
  userId: 'tester',
  userName: 'Tester',
  userEmail: 'tester@example.com',
);

/// 인증 대역. 진짜 로그아웃은 서버·쿠키·SSO 를 물고 있어 상태 자리만 흉내 낸다.
class _FakeAuth extends AuthNotifier {
  _FakeAuth(this._initial);
  final User? _initial;
  int logouts = 0;

  @override
  Future<User?> build() async => _initial;

  @override
  Future<void> logout() async {
    logouts++;
    state = const AsyncData(null);
  }

  /// 딥링크 교환이 실패한 자리 — 진짜 [AuthNotifier.exchangeAndLoginWithCode] 처럼
  /// 에러를 상태에 싣는다.
  void failLogin(Object e) => state = AsyncError(e, StackTrace.current);
}

class _FakeRepo extends WithdrawalRepository {
  _FakeRepo() : super(Dio());

  @override
  Future<WithdrawalCheck> check() async => const WithdrawalCheck(
    blocked: [],
    subscriptionPeriodEnd: null,
    sharedCalendarsOwned: 0,
    calendarMemberships: 0,
    dutchPaysOwned: 0,
    dutchPayParticipations: 0,
  );

  @override
  Future<String> verifyPassword(String password) async => 'ticket';

  @override
  Future<void> withdraw({required String reauthToken, String? reason}) async {}
}

final _l = lookupAppLocalizations(const Locale('ko'));

/// 설명은 두 문단 하나의 글이다 — 보이지 않는 줄바꿈 보호 글자(keepAll)는 빼고 찾는다.
Finder _body(String part) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('\u2060', '').contains(part),
);

MaterialApp _app(GoRouter router) => MaterialApp.router(
  theme: GrooTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

/// 앱의 진짜 라우터(redirect 포함)로 띄운다. 업데이트 안내는 끈다.
Future<ProviderContainer> _pumpRealRouter(
  WidgetTester tester,
  _FakeAuth auth,
) async {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => auth),
      updateStatusProvider.overrideWith(
        (ref) async => const UpdateStatus(currentBuild: 1, latest: null),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _app(container.read(routerProvider)),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({PrefsKeys.locale: 'ko'});
  });

  final withdrawnError = ApiException(
    code: 'USER_021',
    message: '해지한 계정이에요',
    statusCode: 403,
  );

  testWidgets('해지한 계정으로 로그인하면 로그인 에러 글이 아니라 해지 완료 화면이다', (tester) async {
    final auth = _FakeAuth(null);
    await _pumpRealRouter(tester, auth);
    expect(findText(_l.authSsoLogin), findsOneWidget, reason: '로그아웃 → 로그인 화면');

    auth.failLogin(withdrawnError);
    await tester.pumpAndSettle();

    expect(find.byType(WithdrawnScreen), findsOneWidget);
    expect(_body(_l.withdrawnTitle), findsOneWidget);
    expect(_body(_l.withdrawnBody), findsOneWidget);
    expect(_body('감사했습니다'), findsOneWidget);
    expect(_body(_l.withdrawIrreversibleRejoin), findsOneWidget);
    expect(findText(_l.withdrawnToLogin), findsOneWidget);
    expect(findText(_l.authSsoLogin), findsNothing);
  });

  testWidgets('[로그인 화면으로] 는 에러를 걷고 로그인 화면으로 — 다시 튕기지 않는다', (tester) async {
    final auth = _FakeAuth(null);
    final container = await _pumpRealRouter(tester, auth);
    auth.failLogin(withdrawnError);
    await tester.pumpAndSettle();

    await tester.tap(findText(_l.withdrawnToLogin));
    await tester.pumpAndSettle();

    expect(find.byType(WithdrawnScreen), findsNothing);
    expect(findText(_l.authSsoLogin), findsOneWidget);
    expect(container.read(authProvider).hasError, isFalse);
  });

  testWidgets('뒤로가기도 로그인 화면으로 — 앱이 닫히지 않는다', (tester) async {
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final auth = _FakeAuth(null);
    await _pumpRealRouter(tester, auth);
    auth.failLogin(withdrawnError);
    await tester.pumpAndSettle();

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(findText(_l.authSsoLogin), findsOneWidget);
    expect(
      platformCalls.any((c) => c.method == 'SystemNavigator.pop'),
      isFalse,
      reason: '뒤로가기로 앱이 닫히면 해지 안내 뒤에 할 일을 못 찾는다',
    );
  });

  testWidgets('로그아웃 상태에서도 해지 완료 화면에 머문다 — 로그인으로 튕기지 않는다', (tester) async {
    final auth = _FakeAuth(null);
    final container = await _pumpRealRouter(tester, auth);

    container.read(routerProvider).go('/withdrawn');
    await tester.pumpAndSettle();
    expect(find.byType(WithdrawnScreen), findsOneWidget);

    // 해지 직후의 로그아웃과 같은 자리 — 인증 상태가 다시 실려 redirect 가 한 번 더 돈다.
    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.byType(WithdrawnScreen), findsOneWidget);
    expect(findText(_l.authSsoLogin), findsNothing);
  });

  testWidgets('해지를 마치면 토스트가 아니라 완료 화면이 뜨고 로그아웃한다', (tester) async {
    final auth = _FakeAuth(_user);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => showWithdrawalSheet(c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/withdrawn', builder: (_, _) => const WithdrawnScreen()),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          withdrawalRepositoryProvider.overrideWith((ref) async => _FakeRepo()),
        ],
        child: _app(router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'secret');
    await tester.pumpAndSettle();
    await tester.tap(findText(_l.withdrawConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(WithdrawnScreen), findsOneWidget);
    expect(_body('감사했습니다'), findsOneWidget);
    expect(auth.logouts, 1);
    expect(find.byType(SnackBar), findsNothing, reason: '예전 6초 토스트는 없다');
  });

  // I-05 26 · 27 · 77 — 화면 짜임
  for (final dark in [false, true]) {
    testWidgets('${dark ? "다크" : "라이트"} — Result Section done · 흰 면 · 바닥 CTA', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      final auth = _FakeAuth(null);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => auth)],
          child: MaterialApp(
            theme: dark ? GrooTheme.dark() : GrooTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WithdrawnScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final c = (dark ? GrooTheme.dark() : GrooTheme.light())
          .extension<PColors>()!;
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        c.bgLayerDefault,
      );
      final section = tester.widget<PResultSection>(
        find.byType(PResultSection),
      );
      expect(section.kind, PResultKind.done);
      expect(section.size, PResultSize.large);
      expect(section.headingLevel, 1);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('result-section-title')))
            .hasFlag(SemanticsFlag.isHeader),
        isTrue,
      );
      // 버튼은 하나 — ds Button large neutralSolid, 화면 바닥 좌우 24
      expect(find.byType(PButton), findsOneWidget);
      final button = tester.widget<PButton>(find.byType(PButton));
      expect(button.size, PButtonSize.large);
      expect(button.variant, PButtonVariant.neutralSolid);
      final rect = tester.getRect(find.byType(PButton));
      expect(rect.left, 24);
      expect(rect.right, 360 - 24);
      expect(rect.bottom, 780 - 24, reason: '바닥 24');
      handle.dispose();
    });
  }

  testWidgets('글자 200% · 폭 360 — 바닥 버튼 라벨이 오류 없이 다 그려진다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => _FakeAuth(null))],
        child: MaterialApp(
          theme: GrooTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const WithdrawnScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(findText(_l.withdrawnToLogin), findsOneWidget);
  });

  testWidgets('두 문단 사이 8 · 결과와 버튼 사이는 결과의 안쪽 16 만', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => _FakeAuth(null))],
        child: MaterialApp(
          theme: GrooTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WithdrawnScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final first = tester.getRect(_body(_l.withdrawnBody));
    final second = tester.getRect(_body(_l.withdrawIrreversibleRejoin));
    expect(second.top - first.bottom, 8, reason: '문단 사이 8(웹 mt-x2)');
    final content = tester.getRect(
      find.byKey(const ValueKey('result-section-content')),
    );
    expect(content.bottom - second.bottom, 16, reason: '결과 아래 안쪽 16');
    final btn = tester.getRect(find.byType(PButton));
    final section = tester.getRect(find.byType(PResultSection));
    expect(btn.top - section.bottom, greaterThanOrEqualTo(0));
    expect(btn.top, greaterThanOrEqualTo(content.bottom));
  });
}
