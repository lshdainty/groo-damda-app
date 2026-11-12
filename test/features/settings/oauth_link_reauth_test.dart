// 소셜 계정 연결 전 본인 확인(보안 점검 S-2).
//
// 로그인 쿠키만 훔친 사람이 자기 Google 을 붙이면 계정을 영구히 가져간다. 그래서 못 박는다.
//
// - 연결 시작(startLink)은 본인 확인이 **성공한 뒤에만** 부른다 — 실패 · 닫기면 부르지 않는다
// - 연결 시작은 방금 받은 티켓을 `X-Reauth-Token` 헤더에 싣는다
// - 연결용 확인은 purpose 를 `oauth-link` 로, 해지는 `withdraw` 로 밝힌다 — 빼면 서버가 해지로 읽는다
// - 연결 시작이 실패하면 다시 누를 때 본인 확인부터 다시 한다(티켓은 단회)
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';
import 'package:groo_damda_app/features/settings/application/oauth_link_providers.dart';
import 'package:groo_damda_app/features/settings/application/reauth_providers.dart';
import 'package:groo_damda_app/features/settings/data/oauth_link_repository.dart';
import 'package:groo_damda_app/features/settings/data/reauth_repository.dart';
import 'package:groo_damda_app/features/settings/data/withdrawal_repository.dart';
import 'package:groo_damda_app/features/settings/presentation/account_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/oauth_link_reauth_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import '../../support/plain_text.dart';

/// 요청을 받아 적고 정해진 몸통을 돌려준다.
class _Capture implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = options.path.contains('/oauth/link/')
        ? {'startUrl': 'https://sso.example/start'}
        : {'reauthToken': 'T-1'};
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'code': 'OK', 'message': '', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 무엇을 어떤 차례로 불렀는지 — 확인 전에 연결 시작을 부르면 안 된다.
final _log = <String>[];

class _Reauth extends ReauthRepository {
  _Reauth({this.verifyPw, this.verifyCode}) : super(Dio());
  final Future<String> Function(String pw)? verifyPw;
  final Future<String> Function(String code)? verifyCode;
  final purposes = <String>[];
  int sent = 0;
  int _n = 0;

  @override
  Future<void> sendEmailCode() async => sent++;

  @override
  Future<String> verifyPassword(
    String password, {
    required String purpose,
  }) async {
    purposes.add(purpose);
    _log.add('verifyPassword');
    return verifyPw?.call(password) ?? 'ticket-${++_n}';
  }

  @override
  Future<String> verifyEmailCode(String code, {required String purpose}) async {
    purposes.add(purpose);
    _log.add('verifyEmailCode');
    return verifyCode?.call(code) ?? 'ticket-${++_n}';
  }
}

class _Link extends OAuthLinkRepository {
  _Link() : super(Dio());
  final tickets = <String>[];
  Object? error;

  @override
  Future<String> startLink(
    String provider,
    String returnUrl, {
    required String reauthToken,
  }) async {
    _log.add('startLink');
    tickets.add(reauthToken);
    final e = error;
    if (e != null) throw e;
    return 'https://sso.example/start';
  }

  /// 해제에 실린 티켓 — 확인 전에 해제를 부르면 안 된다(S-2 잔여)
  final unlinkTickets = <String>[];
  bool linked = false;

  @override
  Future<void> unlink(String provider, {required String reauthToken}) async {
    _log.add('unlink');
    unlinkTickets.add(reauthToken);
    final e = error;
    if (e != null) throw e;
  }

  @override
  Future<List<OAuthProviderInfo>> providers() async => [
    OAuthProviderInfo(type: 'GOOGLE', name: 'Google', linked: linked),
  ];
}

/// 해제 시트를 띄우는 단추 — 시트가 돌려준 값을 [_UnlinkHarness.result] 에 적는다.
class _UnlinkHarness {
  bool? result;
}

Future<_UnlinkHarness> _openUnlink(
  WidgetTester tester, {
  required _Reauth reauth,
  required _Link link,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final h = _UnlinkHarness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reauthRepositoryProvider.overrideWith((ref) async => reauth),
        oauthLinkRepositoryProvider.overrideWith((ref) async => link),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () async {
                h.result = await showOAuthUnlinkReauthSheet(
                  c,
                  provider: 'google',
                  providerName: 'Google',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return h;
}

final _l = lookupAppLocalizations(const Locale('ko'));

/// 시트를 띄우는 단추 하나 — 시트가 돌려준 값을 [result] 에 적는다.
class _Harness {
  String? result;
  bool closed = false;
}

Future<_Harness> _open(
  WidgetTester tester, {
  required _Reauth reauth,
  required _Link link,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final h = _Harness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reauthRepositoryProvider.overrideWith((ref) async => reauth),
        oauthLinkRepositoryProvider.overrideWith((ref) async => link),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () async {
                h.result = await showOAuthLinkReauthSheet(
                  c,
                  provider: 'google',
                  providerName: 'Google',
                  returnUrl: 'porestdesk://oauth/linked',
                );
                h.closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  setUp(_log.clear);

  group('요청 모양', () {
    test('연결용 확인은 purpose=oauth-link 를 싣고 티켓을 돌려준다', () async {
      final adapter = _Capture();
      final repo = ReauthRepository(Dio()..httpClientAdapter = adapter);
      expect(
        await repo.verifyPassword('pw', purpose: ReauthPurpose.oauthLink),
        'T-1',
      );
      expect(
        await repo.verifyEmailCode('123456', purpose: ReauthPurpose.oauthLink),
        'T-1',
      );
      final pw = adapter.requests[0];
      expect(pw.path, '/users/me/reauth/password');
      expect(pw.data, {'password': 'pw', 'purpose': 'oauth-link'});
      final code = adapter.requests[1];
      expect(code.path, '/users/me/reauth/email-code/verify');
      expect(code.data, {'code': '123456', 'purpose': 'oauth-link'});
    });

    // 서버가 실제로 읽는 리터럴로 본다 — 상수끼리 견주면 둘 다 틀려도 초록불이 난다.
    test('해지는 purpose=withdraw 를 밝힌다(빼지 않는다)', () async {
      final adapter = _Capture();
      final repo = WithdrawalRepository(Dio()..httpClientAdapter = adapter);
      await repo.verifyPassword('pw');
      await repo.verifyEmailCode('123456');
      expect(adapter.requests[0].data, {
        'password': 'pw',
        'purpose': 'withdraw',
      });
      expect(adapter.requests[1].data, {
        'code': '123456',
        'purpose': 'withdraw',
      });
    });

    test('연결 시작은 티켓을 X-Reauth-Token 헤더에 싣는다', () async {
      final adapter = _Capture();
      final repo = OAuthLinkRepository(Dio()..httpClientAdapter = adapter);
      final url = await repo.startLink(
        'google',
        'porestdesk://oauth/linked',
        reauthToken: 'T-9',
      );
      expect(url, 'https://sso.example/start');
      final req = adapter.requests.single;
      expect(req.path, '/oauth/link/google');
      expect(req.method, 'POST');
      expect(req.headers['X-Reauth-Token'], 'T-9');
      expect(req.data, {'returnUrl': 'porestdesk://oauth/linked'});
      // 서버 글이 화면에 닿지 않게 — 실패는 화면이 고정 글로 알린다
      expect(req.extra[kSilentErrorToast], isTrue);
    });
  });

  group('본인 확인 시트', () {
    testWidgets('제목 · 안내 · 비밀번호 칸 · 바닥 [연결하기] 하나', (tester) async {
      await _open(tester, reauth: _Reauth(), link: _Link());
      expect(findText(_l.linkReauthTitle('Google')), findsWidgets);
      expect(findText(keepAll(_l.linkReauthIntro('Google'))), findsOneWidget);
      expect(_l.linkReauthIntro('Google'), contains('Google'));
      final buttons = tester
          .widgetList<PButton>(find.byType(PButton))
          .where((b) => b.size == PButtonSize.large)
          .toList();
      expect(buttons.single.label, _l.linkReauthConfirm);
      expect(buttons.single.variant, PButtonVariant.neutralSolid);
      expect(buttons.single.onPressed, isNull, reason: '비밀번호를 넣기 전엔 막는다');
    });

    testWidgets('비밀번호 확인이 된 뒤에만 연결을 시작하고, 그 티켓을 싣는다', (tester) async {
      final reauth = _Reauth();
      final link = _Link();
      final h = await _open(tester, reauth: reauth, link: link);
      await tester.enterText(find.byType(TextField).first, 'secret');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(_log, ['verifyPassword', 'startLink']);
      expect(reauth.purposes, ['oauth-link']);
      expect(link.tickets, ['ticket-1']);
      // 시트는 열 주소를 들고 닫힌다
      expect(h.closed, isTrue);
      expect(h.result, 'https://sso.example/start');
      expect(findText(_l.linkReauthTitle('Google')), findsNothing);
    });

    testWidgets('비밀번호가 틀리면 연결을 시작하지 않는다 · 서버 글을 내지 않는다', (tester) async {
      final reauth = _Reauth(
        verifyPw: (_) async =>
            throw ApiException(code: 'AUTH_021', message: 'raw pw'),
      );
      final link = _Link();
      final h = await _open(tester, reauth: reauth, link: link);
      await tester.enterText(find.byType(TextField).first, 'wrong');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(_log, ['verifyPassword']);
      expect(link.tickets, isEmpty);
      expect(findText(keepAll(_l.withdrawPasswordWrong)), findsOneWidget);
      expect(findText('raw pw'), findsNothing);
      expect(h.closed, isFalse, reason: '시트는 남아 다시 넣게 한다');
    });

    testWidgets('잠김(AUTH_022)은 해지와 같은 글', (tester) async {
      final reauth = _Reauth(
        verifyPw: (_) async =>
            throw ApiException(code: 'AUTH_022', message: 'raw lock'),
      );
      await _open(tester, reauth: reauth, link: _Link());
      await tester.enterText(find.byType(TextField).first, 'secret');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(findTextContaining(_l.withdrawLocked), findsWidgets);
      expect(_log, ['verifyPassword']);
    });

    testWidgets('연결 시작이 실패하면 시트에 남고, 다시 누르면 본인 확인부터 다시', (tester) async {
      final reauth = _Reauth();
      final link = _Link()
        ..error = ApiException(code: 'AUTH_023', message: 'ticket raw');
      final h = await _open(tester, reauth: reauth, link: link);
      await tester.enterText(find.byType(TextField).first, 'secret');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(findText(keepAll(_l.linkReauthStartFailed)), findsOneWidget);
      expect(findText('ticket raw'), findsNothing);
      expect(h.closed, isFalse);
      // 티켓을 이미 썼을 수 있다 — 칸을 비워 본인 확인부터 다시 하게 한다(웹과 같다)
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
      expect(
        tester
            .widget<PButton>(findWidgetWithText(PButton, _l.linkReauthConfirm))
            .onPressed,
        isNull,
      );

      link.error = null;
      await tester.enterText(find.byType(TextField).first, 'secret');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(_log, [
        'verifyPassword',
        'startLink',
        'verifyPassword',
        'startLink',
      ]);
      // 앞서 쓴 티켓을 다시 내밀지 않는다
      expect(link.tickets, ['ticket-1', 'ticket-2']);
      expect(h.result, 'https://sso.example/start');
    });

    testWidgets('본인 확인 단계 실패(네트워크 · 쿨다운)는 확인 실패 글 · 칸은 그대로', (tester) async {
      final reauth = _Reauth(
        verifyPw: (_) async =>
            throw ApiException(code: 'NETWORK', message: 'net raw'),
      );
      await _open(tester, reauth: reauth, link: _Link());
      await tester.enterText(find.byType(TextField).first, 'secret');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(findText(keepAll(_l.linkReauthFailed)), findsOneWidget);
      expect(findText(keepAll(_l.linkReauthStartFailed)), findsNothing);
      expect(findText('net raw'), findsNothing);
      expect(_log, ['verifyPassword']);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'secret',
      );
    });

    testWidgets('메일 코드 — 코드 받기 · 6자리 확인 뒤 oauth-link 로 연결', (tester) async {
      final reauth = _Reauth();
      final link = _Link();
      final h = await _open(tester, reauth: reauth, link: link);
      await tester.tap(findText(_l.withdrawUseEmailCode));
      await tester.pumpAndSettle();
      await tester.tap(findText(_l.withdrawSendCode));
      await tester.pumpAndSettle();
      expect(reauth.sent, 1);

      // 6자리 전 — 칸 오류, 아무것도 부르지 않는다
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(findText(keepAll(_l.withdrawCodeIncomplete)), findsOneWidget);
      expect(_log, isEmpty);

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(findText(_l.linkReauthConfirm));
      await tester.pumpAndSettle();
      expect(_log, ['verifyEmailCode', 'startLink']);
      expect(reauth.purposes, ['oauth-link']);
      expect(h.result, 'https://sso.example/start');
    });

    testWidgets('닫기만 하면 아무것도 부르지 않고 null', (tester) async {
      final h = await _open(tester, reauth: _Reauth(), link: _Link());
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
      await tester.pumpAndSettle();
      expect(h.closed, isTrue);
      expect(h.result, isNull);
      expect(_log, isEmpty);
    });

    testWidgets('다크 · 글자 200% — 오류 없이 그려진다', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reauthRepositoryProvider.overrideWith((ref) async => _Reauth()),
            oauthLinkRepositoryProvider.overrideWith((ref) async => _Link()),
          ],
          child: MaterialApp(
            theme: GrooTheme.dark(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (c) => TextButton(
                  onPressed: () => showOAuthLinkReauthSheet(
                    c,
                    provider: 'google',
                    providerName: 'Google',
                    returnUrl: 'porestdesk://oauth/linked',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(findText(_l.withdrawUseEmailCode));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // S-2 잔여 — 해제도 로그인 쿠키만으로 되면 쿠키를 쥔 사람이 구글 연결을 끊어 복구 수단을 없앤다
  group('해제 전 본인 확인', () {
    test('해제는 티켓을 X-Reauth-Token 헤더에 싣는다', () async {
      final adapter = _Capture();
      final repo = OAuthLinkRepository(Dio()..httpClientAdapter = adapter);
      await repo.unlink('google', reauthToken: 'ticket-u');
      final req = adapter.requests.single;
      expect(req.method, 'DELETE');
      expect(req.path, '/oauth/link/google');
      expect(req.headers['X-Reauth-Token'], 'ticket-u');
      expect(req.extra[kSilentErrorToast], isTrue);
    });

    testWidgets('비밀번호 확인(oauth-link) 뒤에만 해제하고, 그 티켓을 싣고, true 로 닫힌다', (
      tester,
    ) async {
      final reauth = _Reauth();
      final link = _Link();
      final h = await _openUnlink(tester, reauth: reauth, link: link);
      expect(findText(keepAll(_l.unlinkReauthIntro('Google'))), findsOneWidget);
      expect(_log, isEmpty, reason: '열기만 해서는 해제하지 않는다');
      await tester.enterText(find.byType(TextField).first, 'secret');
      await tester.pump();
      await tester.tap(findText(_l.unlinkReauthConfirm));
      await tester.pumpAndSettle();
      expect(_log, ['verifyPassword', 'unlink']);
      expect(reauth.purposes, ['oauth-link']);
      expect(link.unlinkTickets, ['ticket-1']);
      expect(h.result, isTrue);
    });

    testWidgets('해제가 실패하면 시트가 남아 본인 확인부터 다시 받는다', (tester) async {
      final link = _Link()..error = ApiException(code: 'X', message: 'raw');
      final h = await _openUnlink(tester, reauth: _Reauth(), link: link);
      await tester.enterText(find.byType(TextField).first, 'secret');
      await tester.pump();
      await tester.tap(findText(_l.unlinkReauthConfirm));
      await tester.pumpAndSettle();
      expect(findText(keepAll(_l.unlinkReauthFailed)), findsOneWidget);
      expect(findText('raw'), findsNothing);
      expect(h.result, isNull, reason: '시트는 닫히지 않았다');
    });
  });

  testWidgets('계정 화면 — Google [연결] 은 본인 확인 시트부터 연다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final link = _Link();
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_User.new),
          reauthRepositoryProvider.overrideWith((ref) async => _Reauth()),
          oauthLinkRepositoryProvider.overrideWith((ref) async => link),
        ],
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
    final connect = findWidgetWithText(PButton, _l.accountConnect);
    await tester.ensureVisible(connect);
    await tester.pumpAndSettle();
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(findText(keepAll(_l.linkReauthIntro('Google'))), findsOneWidget);
    expect(_log, isEmpty, reason: '본인 확인 전에는 연결을 시작하지 않는다');
    expect(link.tickets, isEmpty);
  });

  // 웹 translations.csv `account.unlinkReauth.*` 와 글자 그대로 같다 — 한쪽만 고치지 마라.
  testWidgets('계정 화면 — Google [해제] 도 본인 확인 시트부터 연다(S-2 잔여)', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final link = _Link()..linked = true;
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_User.new),
          reauthRepositoryProvider.overrideWith((ref) async => _Reauth()),
          oauthLinkRepositoryProvider.overrideWith((ref) async => link),
        ],
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
    final connect = findWidgetWithText(PButton, _l.accountDisconnect);
    await tester.ensureVisible(connect);
    await tester.pumpAndSettle();
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(findText(keepAll(_l.unlinkReauthIntro('Google'))), findsOneWidget);
    expect(_log, isEmpty, reason: '본인 확인 전에는 해제하지 않는다');
    expect(link.unlinkTickets, isEmpty);
  });

  // 웹 translations.csv `account.unlinkReauth.*` 와 글자 그대로 같다 — 한쪽만 고치지 마라.
  test('해제 문구가 웹과 한 벌이다', () {
    final ko = AppLocalizationsKo();
    final en = AppLocalizationsEn();
    expect(ko.unlinkReauthTitle('Google'), 'Google 연결 해제');
    expect(en.unlinkReauthTitle('Google'), 'Disconnect your Google account');
    expect(ko.unlinkReauthIntro('Google'), 'Google 계정 연결을 해제하려면 본인 확인이 필요해요.');
    expect(
      en.unlinkReauthIntro('Google'),
      "To disconnect your Google account, we need to confirm it's you.",
    );
    expect(ko.unlinkReauthConfirm, '해제하기');
    expect(en.unlinkReauthConfirm, 'Disconnect');
    expect(ko.unlinkReauthFailed, '연결을 해제하지 못했어요. 본인 확인부터 다시 해주세요.');
    expect(
      en.unlinkReauthFailed,
      "Couldn't disconnect the account. Please confirm it's you again.",
    );
  });

  test('문구 — ko · en 모두 있고 provider 이름을 끼운다', () {
    for (final l in [AppLocalizationsKo(), AppLocalizationsEn()]) {
      expect(l.linkReauthTitle('Google'), contains('Google'));
      expect(l.linkReauthIntro('Google'), contains('Google'));
      expect(l.linkReauthConfirm, isNotEmpty);
      expect(l.linkReauthFailed, isNotEmpty);
      expect(l.linkReauthStartFailed, isNotEmpty);
    }
  });

  // 웹 translations.csv `account.linkReauth.*` 와 글자 그대로 같다 — 한쪽만 고치지 마라.
  test('문구가 웹과 한 벌이다', () {
    final ko = AppLocalizationsKo();
    final en = AppLocalizationsEn();
    expect(ko.linkReauthTitle('Google'), 'Google 계정 연결');
    expect(en.linkReauthTitle('Google'), 'Connect your Google account');
    expect(ko.linkReauthIntro('Google'), 'Google 계정을 연결하려면 본인 확인이 필요해요.');
    expect(
      en.linkReauthIntro('Google'),
      "To connect your Google account, we need to confirm it's you.",
    );
    expect(ko.linkReauthConfirm, '연결하기');
    expect(en.linkReauthConfirm, 'Connect');
    expect(ko.linkReauthFailed, '본인 확인을 하지 못했어요. 잠시 뒤 다시 시도해주세요.');
    expect(
      en.linkReauthFailed,
      "Couldn't confirm it's you. Please try again shortly.",
    );
    expect(ko.linkReauthStartFailed, '계정을 연결하지 못했어요. 본인 확인부터 다시 해주세요.');
    expect(
      en.linkReauthStartFailed,
      "Couldn't connect the account. Please confirm it's you again.",
    );
  });
}

class _User extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
    rowId: 1,
    userId: 'tester',
    userName: 'Tester',
    userEmail: 'tester@example.com',
  );
}
