// 로그인 화면(I-05 5 ~ 10 · 75 · 86) — 실제 화면을 띄운 채로 잰다.
//
//  - 문구: ko · en 어디에도 "SSO" 가 없다 · "그루 계정으로 로그인"
//  - 마크: 나무 56 + 8 + 이름, 이름이 화면 제목(머리말 1단계), 나무는 의미 트리에 없다
//  - 버튼: ds Button large · neutralSolid, 바닥은 흰 면, 브라우저를 여는 동안 딤 · 원 덮개가 없다
//  - 실패: Callout(critical) 이 버튼 위에, 서버 글을 붙이지 않는다
//  - 시작: 버튼은 로그인 시작(OAuthLoginLauncher)을 탄다 — 로그아웃 표시가 있으면 prompt=login
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/session_scope.dart' show appProviderRetry;
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_login_launcher.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/auth/presentation/login_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/brand/groo_tree.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import '../../support/memory_secure_storage.dart';
import '../../support/plain_text.dart';

class _FakeAuth extends AuthNotifier {
  _FakeAuth({this.bootError});

  /// 앱을 켤 때 세션 확인(`/auth/check`)이 401 이 아닌 오류로 실패했다 — 네트워크 끊김 · 시간 초과.
  final Object? bootError;

  @override
  Future<User?> build() async {
    if (bootError != null) throw bootError!;
    return null;
  }

  void failLogin(Object e) => state = AsyncError(e, StackTrace.current);

  void startExchange() => state = const AsyncLoading<User?>();
}

Future<_FakeAuth> _pump(
  WidgetTester tester, {
  String locale = 'ko',
  bool dark = false,
  double width = 360,
  double textScale = 1,
  List<Override> overrides = const [],
  Object? bootError,
}) async {
  tester.view.physicalSize = Size(width * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final auth = _FakeAuth(bootError: bootError);
  await tester.pumpWidget(
    ProviderScope(
      // 앱과 같이 Riverpod 재시도를 끈다 — 켜 두면 켤 때 실패한 세션 확인이 재시도 로딩으로 남는다
      retry: appProviderRetry,
      overrides: [authProvider.overrideWith(() => auth), ...overrides],
      child: MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pump();
  return auth;
}

void main() {
  for (final locale in ['ko', 'en']) {
    testWidgets('$locale — 화면의 모든 글에 SSO 가 없고 그루 계정을 말한다', (tester) async {
      await _pump(tester, locale: locale);
      final l = lookupAppLocalizations(Locale(locale));
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => plainOf(t.data ?? t.textSpan?.toPlainText() ?? ''))
          .join('\n');
      expect(texts, isNot(contains('SSO')));
      expect(l.authLoginPrompt, isNot(contains('SSO')));
      expect(l.authSsoLogin, isNot(contains('SSO')));
      expect(l.authLoginFailed, isNot(contains('SSO')));
      expect(l.authSecurityNotHttps, isNot(contains('SSO')));
      expect(texts, contains(l.authSsoLogin));
      expect(texts, contains(l.authLoginPrompt));
      expect(texts, contains(l.appTitle));
    });
  }

  testWidgets('ko 문구 — 그루 계정으로 로그인해주세요. · 그루 계정으로 로그인', (tester) async {
    await _pump(tester);
    expect(findText('그루 계정으로 로그인해주세요.'), findsOneWidget);
    expect(findText('그루 계정으로 로그인'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      '${dark ? "다크" : "라이트"} — 마크 나무 56 + 8 + 이름 · 바닥 흰 면 · 버튼 large',
      (tester) async {
        await _pump(tester, dark: dark);
        final c = (dark ? GrooTheme.dark() : GrooTheme.light())
            .extension<PColors>()!;
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          c.bgLayerDefault,
        );
        final tree = tester.getRect(find.byType(GrooTree));
        expect(tree.height, 56);
        final name = tester.getRect(findText('그루 담다'));
        expect(name.left - tree.right, 8, reason: '나무 ↔ 이름 8');
        // 안내 = t5 · 400 · fg-neutral-muted, 마크 ↔ 안내 8 · 안내 ↔ 버튼 32
        final promptFinder = findText('그루 계정으로 로그인해주세요.');
        final prompt = tester.widget<Text>(promptFinder).style!;
        expect(prompt.fontSize, 16);
        expect(prompt.fontWeight, FontWeight.w400);
        expect(prompt.color, c.fgNeutralMuted);
        final markBottom = tester.getRect(find.byType(GrooTree)).bottom;
        expect(
          tester.getRect(promptFinder).top - markBottom,
          closeTo(8, 1),
          reason: '마크 ↔ 안내 8',
        );
        expect(
          tester.getRect(find.byType(PButton)).top -
              tester.getRect(promptFinder).bottom,
          32,
          reason: '안내 ↔ 버튼 32',
        );
        final button = tester.widget<PButton>(find.byType(PButton));
        expect(button.size, PButtonSize.large);
        expect(button.variant, PButtonVariant.neutralSolid);
        expect(tester.getSize(find.byType(PButton)).height, 48);
        expect(
          tester.getSize(find.byType(PButton)).width,
          360.0 - 48,
          reason: '전체 폭(좌우 24)',
        );
        // 브라우저를 여는 동안의 덮개(딤 + 원)가 없다 — 로딩은 버튼 몫
        expect(
          find.descendant(
            of: find.byType(SafeArea),
            matching: find.byType(PProgressCircle),
          ),
          findsNothing,
        );
      },
    );
  }

  testWidgets('이름이 화면 제목(머리말 1단계)이고 나무는 의미 트리에 없다', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final node = tester.getSemantics(findText('그루 담다'));
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(find.bySemanticsLabel('그루 담다'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('글자 130% · 폭 360 — 넘치지 않는다', (tester) async {
    await _pump(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(findText('그루 담다'), findsOneWidget);
  });

  // 글자 200% · 폭 360 — ds Button 라벨은 한 줄을 지키고, 버튼보다 넓으면 끝을 "…" 로 줄여 버튼 안에 둔다
  // (button.md "글자 크기 설정", groo-design #263). 전체 라벨은 보조 기술이 읽는다.
  testWidgets('글자 200% · 폭 360 — 오류 없이 라벨이 한 줄로 버튼 안에 든다', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    final label = findText('그루 계정으로 로그인');
    expect(label, findsOneWidget);
    expect(tester.getSize(label).height, lessThan(60), reason: '한 줄');
    final button = tester.getRect(find.byType(PButton));
    final r = tester.getRect(label);
    expect(r.left, greaterThanOrEqualTo(button.left), reason: '버튼 안');
    expect(r.right, lessThanOrEqualTo(button.right), reason: '버튼 안');
    expect(find.bySemanticsLabel('그루 계정으로 로그인'), findsOneWidget);
  });

  testWidgets('실패는 버튼 위 Callout(critical) — 서버 글을 붙이지 않는다', (tester) async {
    final auth = await _pump(tester);
    auth.failLogin(
      ApiException(code: 'AUTH_099', message: '서버가 준 영어 error text'),
    );
    await tester.pump();
    final callout = find.byType(PCallout);
    expect(callout, findsOneWidget);
    expect(tester.widget<PCallout>(callout).tone, PCalloutTone.critical);
    expect(findText('로그인하지 못했어요.'), findsOneWidget);
    expect(findTextContaining('서버가 준'), findsNothing);
    expect(
      tester.getRect(callout).bottom,
      lessThan(tester.getRect(find.byType(PButton)).top),
      reason: '자리는 버튼 위',
    );
  });

  // 버튼은 로그인 시작(OAuthLoginLauncher)을 탄다 — 교환이 AUTH_030 으로 거절됐을 때의 다시 시작과 같은 길이다.
  testWidgets('버튼을 누르면 그루 계정 로그인 주소로 나간다 — 로그아웃 표시가 있으면 prompt=login', (
    tester,
  ) async {
    final store = OAuthFlowStore(MemorySecureStorage());
    final launched = <Uri>[];
    await _pump(
      tester,
      overrides: [
        oauthLoginLauncherProvider.overrideWithValue(
          OAuthLoginLauncher(
            store: store,
            launch: (url) async {
              launched.add(url);
              return true;
            },
          ),
        ),
      ],
    );

    await tester.tap(find.byType(PButton));
    await tester.pumpAndSettle();
    expect(launched.single.path, '/api/v1/oauth2/authorize');
    expect(launched.single.queryParameters.containsKey('prompt'), isFalse);
    expect(await store.restorePending(), isNotNull);

    // 브라우저에서 돌아와 다시 누를 수 있다(버튼이 로딩에 묶여 있지 않다).
    await store.markForceLoginPrompt();
    await tester.tap(find.byType(PButton));
    await tester.pumpAndSettle();
    expect(launched, hasLength(2));
    expect(launched.last.queryParameters['prompt'], 'login');
    expect(find.byType(PCallout), findsNothing);
  });

  // QA 2026-11-20(안드 3048): 앱을 켤 때 세션 확인이 네트워크로 실패한 채 로그인하니, 딥링크 교환
  // 3초(exchange-code 14:05:12 → 200 14:05:16) 동안 "로그인하지 못했어요." 가 버튼의 원과 같이 떴다가
  // 홈으로 들어갔다. Riverpod 는 `state = AsyncLoading()` 에 앞 오류를 실어 두어(로딩이면서 hasError)
  // 화면이 그것을 실패로 읽었다.
  group('교환 중 실패 글 — 교환이 실제로 실패했을 때만', () {
    late List<Uri> launched;
    late List<Override> launcher;

    setUp(() {
      launched = [];
      launcher = [
        oauthLoginLauncherProvider.overrideWithValue(
          OAuthLoginLauncher(
            store: OAuthFlowStore(MemorySecureStorage()),
            // Android Custom Tabs — 탭을 띄우면 바로 true(창을 닫아도 아무 신호가 없다)
            launch: (url) async {
              launched.add(url);
              return true;
            },
          ),
        ),
      ];
    });

    testWidgets('켤 때 세션 확인 실패 → 로그인 → 교환 대기 중에는 실패 글 없이 원만', (tester) async {
      final auth = await _pump(
        tester,
        overrides: launcher,
        bootError: ApiException(code: 'NETWORK', message: 'timeout'),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<PButton>(find.byType(PButton)).loading, isFalse);

      // 누르면 앞 글은 걷힌다 — 흐름이 앱 안 창으로 넘어간다
      await tester.tap(find.byType(PButton));
      await tester.pumpAndSettle();
      expect(launched, hasLength(1));
      expect(find.byType(PCallout), findsNothing);

      // 앱 안 창에서 [계속] → 딥링크 → 교환 시작(AuthNotifier.exchangeAndLoginWithCode 의 첫 줄과 같다)
      auth.startExchange();
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      );
      expect(
        container.read(authProvider).hasError,
        isTrue,
        reason: '로딩 상태가 앞 오류를 들고 있다(이 결함의 전제)',
      );
      expect(tester.widget<PButton>(find.byType(PButton)).loading, isTrue);
      expect(find.byType(PCallout), findsNothing);
      expect(findText('로그인하지 못했어요.'), findsNothing);
    });

    testWidgets('교환이 실패하면 그때 실패 글 — 다음 교환이 시작되면 걷힌다', (tester) async {
      final auth = await _pump(tester, overrides: launcher);
      auth.startExchange();
      await tester.pump();
      expect(find.byType(PCallout), findsNothing);

      auth.failLogin(ApiException(code: 'AUTH_004', message: 'used code'));
      await tester.pump();
      expect(findText('로그인하지 못했어요.'), findsOneWidget);
      expect(tester.widget<PButton>(find.byType(PButton)).loading, isFalse);

      // 딥링크가 버튼을 거치지 않고 다시 교환을 시작해도(AUTH_030 다시 시작 등) 대기 중엔 글이 없다
      auth.startExchange();
      await tester.pump();
      expect(find.byType(PCallout), findsNothing);
      expect(tester.widget<PButton>(find.byType(PButton)).loading, isTrue);
    });

    testWidgets('창을 그냥 닫으면(취소) 원이 남지 않고 다시 누를 수 있다', (tester) async {
      await _pump(
        tester,
        overrides: launcher,
        bootError: ApiException(code: 'NETWORK', message: 'timeout'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PButton));
      await tester.pumpAndSettle();
      // 딥링크가 오지 않는다 — 교환도 없다
      expect(tester.widget<PButton>(find.byType(PButton)).loading, isFalse);
      expect(find.byType(PCallout), findsNothing);

      await tester.tap(find.byType(PButton));
      await tester.pumpAndSettle();
      expect(launched, hasLength(2));
      expect(tester.widget<PButton>(find.byType(PButton)).loading, isFalse);
    });
  });

  testWidgets('브라우저를 열지 못하면 버튼 위 Callout — 다시 누를 수 있다', (tester) async {
    await _pump(
      tester,
      overrides: [
        oauthLoginLauncherProvider.overrideWithValue(
          OAuthLoginLauncher(
            store: OAuthFlowStore(MemorySecureStorage()),
            launch: (_) async => false,
          ),
        ),
      ],
    );

    await tester.tap(find.byType(PButton));
    await tester.pumpAndSettle();

    expect(findText('로그인을 처리하지 못했어요.'), findsOneWidget);
    expect(tester.widget<PButton>(find.byType(PButton)).loading, isFalse);
  });

  // 로딩은 누름 색 위 원이다 — 막힌(disabled) 회색 위가 아니다(웹 button.tsx: aria-busy + 누름 삼킴).
  for (final dark in [false, true]) {
    testWidgets('교환 중 버튼 — ${dark ? '다크' : '라이트'} 누름 색 + 원, 막히지 않는다', (
      tester,
    ) async {
      final auth = await _pump(tester, dark: dark);
      auth.startExchange();
      await tester.pump();
      final c = (dark ? GrooTheme.dark() : GrooTheme.light())
          .extension<PColors>()!;
      final button = tester.widget<PButton>(find.byType(PButton));
      expect(button.loading, isTrue);
      expect(button.onPressed, isNotNull, reason: 'disabled 상태로 내려가지 않는다');
      expect(
        find.descendant(
          of: find.byType(PButton),
          matching: find.byType(PProgressCircle),
        ),
        findsOneWidget,
      );
      final bgs = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(PButton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color)
          .toList();
      expect(bgs, contains(c.bgNeutralInvertedPressed), reason: '누름 색');
      expect(bgs, isNot(contains(c.bgNeutralInverted)));
    });
  }
}
