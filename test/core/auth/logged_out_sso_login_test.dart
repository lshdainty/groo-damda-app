// 담다에서 로그아웃한 그루 계정 로그인으로 돌아온 교환(AUTH_030) — 보안 점검 CLI-6.
//
// 담다 로그아웃은 담다만 끝내고 그루 계정(SSO) 로그인은 남긴다. 서버는 로그아웃한 그 로그인을 기억해 두고,
// 같은 로그인으로 돌아온 인가코드 교환을 401 · AUTH_030 으로 거절한다. 평소에는 기기의 강제 표시가
// prompt=login 을 실어 이 거절을 만나지 않는다. 만나는 것은 **표시가 없는데 그 로그인이 살아 있을 때**다
// (앱 데이터를 지웠다 · 같은 기기 브라우저의 그루 계정 로그인이 남았다).
//
// 붙잡는 것:
//  - AUTH_030 → 강제 표시를 남기고 prompt=login 으로 **한 번** 다시 시작한다. 로그인 화면에 실패 글이 뜨지 않는다
//  - 폼을 강제한 시도가 또 AUTH_030 → 다시 시작하지 않고 보통의 로그인 실패다(맴돌지 않는다)
//  - 다른 오류는 그대로 로그인 실패다 — 다시 시작하지도, 강제 표시를 남기지도 않는다
//  - 강제 표시는 직접 누른 로그아웃이 남기고 로그인 성공이 지운다
//
// 대역은 서버(HTTP 어댑터) · 브라우저(주소 받아 적기) · 기기 저장소뿐이다. `AuthNotifier` · 콜백 처리기 ·
// 로그인 시작(`OAuthLoginLauncher`)과 그 사이의 배선은 진짜다 — 딥링크가 들어온 자리부터 그대로 태운다.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/auth/auth_events.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/oauth_callback_handler.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_listener.dart';
import 'package:groo_damda_app/core/auth/oauth_login_launcher.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/network/interceptors/auth_interceptor.dart';
import 'package:groo_damda_app/features/auth/presentation/login_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/memory_secure_storage.dart';

const _user = User(
  rowId: 1,
  userId: 'tester',
  userName: 'Tester',
  userEmail: 'tester@example.com',
);

/// 서버 대역 — 인가코드마다 정해 둔 대로 교환에 답한다.
class _Server implements HttpClientAdapter {
  /// 인가코드 → 거절(HTTP 상태 · 오류 코드). 없는 코드는 받아 준다.
  final _rejections = <String, ({int status, String code})>{};

  /// 세션 쿠키 노릇 — 교환을 받아 주면 켜지고 로그아웃하면 꺼진다.
  bool signedIn = false;

  /// 받은 요청의 경로, 받은 순서대로.
  final paths = <String>[];

  void reject(String code, {required int status, required String error}) =>
      _rejections[code] = (status: status, code: error);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    paths.add(path);
    if (path.endsWith('/auth/exchange-code')) {
      final rejection = _rejections[(options.data as Map)['code']];
      if (rejection != null) {
        return _json(rejection.status, rejection.code, null);
      }
      signedIn = true;
      return _json(200, 'COMMON_200', null);
    }
    if (path.endsWith('/auth/logout')) {
      signedIn = false;
      return _json(200, 'COMMON_200', null);
    }
    if (path.endsWith('/auth/check')) {
      return signedIn
          ? _json(200, 'COMMON_200', _user.toJson())
          : _json(401, 'AUTH_001', null);
    }
    return _json(404, 'COMMON_404', null);
  }

  ResponseBody _json(int status, String code, Object? data) =>
      ResponseBody.fromString(
        jsonEncode({
          'success': status == 200,
          'code': code,
          // 서버가 쓴 글 — 화면에 그대로 닿으면 안 된다.
          'message': 'server said $code',
          'data': data,
        }),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

/// 쿠키 저장소 대역 — 기기 보안 저장소 대신 메모리에 둔다.
class _MemoryCookieStorage implements Storage {
  final _values = <String, String>{};

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll(List<String> keys) async =>
      keys.forEach(_values.remove);
}

class _Harness {
  _Harness._(this.container, this.server, this.store);

  final ProviderContainer container;
  final _Server server;
  final OAuthFlowStore store;

  /// 브라우저 대역 — 나간 authorize 주소, 나간 순서대로.
  final launched = <Uri>[];

  /// 켜면 브라우저가 열리지 않는다.
  bool browserBroken = false;

  /// 인증 상태가 밟은 값 전부 — 로그인 화면은 `hasError` 인 값을 보면 실패 글을 그린다.
  final states = <AsyncValue<User?>>[];

  /// 로그아웃 상태로 앱을 켠다.
  ///
  /// [sessionExpiryOn401] 을 켜면 dio 에 운영과 같은 401 인터셉터를 끼운다(`dio_provider.dart` 와 같은
  /// 배선 — 401 → 세션 만료 신호 → `AuthNotifier.logout()`).
  static Future<_Harness> start({bool sessionExpiryOn401 = false}) async {
    final server = _Server();
    final store = OAuthFlowStore(MemorySecureStorage());
    late final _Harness h;
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWith((ref) async {
          final dio = Dio(BaseOptions(baseUrl: 'https://damda.test/api/v1'))
            ..httpClientAdapter = server;
          if (sessionExpiryOn401) {
            dio.interceptors.add(
              AuthInterceptor(
                onUnauthorized: () => Future.microtask(() {
                  if (!ref.mounted) return;
                  ref.read(sessionExpiredProvider.notifier).bump();
                }),
              ),
            );
          }
          return dio;
        }),
        cookieJarProvider.overrideWith(
          (ref) async => PersistCookieJar(
            ignoreExpires: true,
            storage: _MemoryCookieStorage(),
          ),
        ),
        oauthFlowStoreProvider.overrideWithValue(store),
        oauthLoginLauncherProvider.overrideWith(
          (ref) => OAuthLoginLauncher(
            store: ref.watch(oauthFlowStoreProvider),
            launch: (url) async {
              if (h.browserBroken) return false;
              h.launched.add(url);
              return true;
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    h = _Harness._(container, server, store);
    container.listen(authProvider, (_, next) => h.states.add(next));
    expect(await container.read(authProvider.future), isNull);
    h.states.clear();
    return h;
  }

  AsyncValue<User?> get auth => container.read(authProvider);

  /// 사용자가 로그인 버튼을 눌렀다 — 로그인 화면이 하는 일 그대로.
  Future<void> pressLogin() =>
      container.read(oauthLoginLauncherProvider).start();

  /// **방금 나간** 로그인 시도가 [code] 를 들고 돌아왔다 — 딥링크가 들어온 자리.
  Future<OAuthCallbackResult> comeBackWith(String code) {
    final state = launched.last.queryParameters['state']!;
    return container
        .read(oauthCallbackHandlerProvider)
        .handle(
          Uri.parse(
            'porestdesk://oauth/callback'
            '?code=$code&state=${Uri.encodeComponent(state)}',
          ),
        );
  }

  int get exchanges =>
      server.paths.where((p) => p.endsWith('/auth/exchange-code')).length;

  bool get everShowedError => states.any((s) => s.hasError);
}

final _l = lookupAppLocalizations(const Locale('ko'));

Matcher _apiError(String code) =>
    isA<ApiException>().having((e) => e.code, 'code', code);

void main() {
  group('AUTH_030 — 강제 표시 없이 살아 있는 그루 계정 로그인으로 돌아왔다', () {
    test('강제 표시를 남기고 prompt=login 으로 한 번 다시 시작한다 — 실패 글은 없다', () async {
      final h = await _Harness.start();
      h.server.reject('silent', status: 401, error: 'AUTH_030');
      await h.pressLogin();
      expect(
        h.launched.single.queryParameters.containsKey('prompt'),
        isFalse,
        reason: '전제 — 강제 표시가 없어 그루 계정이 폼 없이 코드를 내준다',
      );

      final result = await h.comeBackWith('silent');

      expect(result, OAuthCallbackResult.restartedWithPrompt);
      expect(h.launched, hasLength(2), reason: '브라우저가 한 번 더 열린다');
      expect(h.launched.last.queryParameters['prompt'], 'login');
      expect(await h.store.isForceLoginPrompt(), isTrue);
      expect(
        (await h.store.restorePending())?.forcedPrompt,
        isTrue,
        reason: '다시 시작한 시도는 폼을 강제한 시도로 보관된다 — 또 거절되면 멈추는 기준',
      );
      expect(h.auth, const AsyncData<User?>(null));
      expect(h.everShowedError, isFalse, reason: '로그인 화면에 실패 글이 번쩍이면 안 된다');
    });

    test('다시 시작한 로그인에서 비밀번호를 넣으면 들어오고, 강제 표시가 지워진다', () async {
      final h = await _Harness.start();
      h.server.reject('silent', status: 401, error: 'AUTH_030');
      await h.pressLogin();
      await h.comeBackWith('silent');

      final result = await h.comeBackWith('fresh');

      expect(result, OAuthCallbackResult.exchanged);
      expect(h.auth.value, _user);
      expect(await h.store.isForceLoginPrompt(), isFalse);
      expect(h.launched, hasLength(2));
      expect(h.everShowedError, isFalse);
    });

    test('폼을 강제한 시도가 또 AUTH_030 이면 — 다시 시작하지 않고 로그인 실패다', () async {
      final h = await _Harness.start();
      h.server
        ..reject('silent', status: 401, error: 'AUTH_030')
        ..reject('again', status: 401, error: 'AUTH_030');
      await h.pressLogin();
      await h.comeBackWith('silent');
      expect(h.launched, hasLength(2));

      await expectLater(
        h.comeBackWith('again'),
        throwsA(_apiError('AUTH_030')),
      );

      expect(h.launched, hasLength(2), reason: '맴돌지 않는다 — 브라우저를 더 열지 않는다');
      expect(h.exchanges, 2);
      expect(h.auth.error, _apiError('AUTH_030'));
      expect(
        loginErrorMessage(h.auth.error, _l),
        _l.authLoginFailed,
        reason: '보통의 로그인 실패 글 — 새 문구도 서버 글도 아니다',
      );
      expect(await h.store.restorePending(), isNull);
      expect(
        await h.store.isForceLoginPrompt(),
        isTrue,
        reason: '다시 눌러도 폼이 뜬다 — 표시는 로그인 성공만 지운다',
      );
    });

    test('로그아웃 직후처럼 처음부터 폼을 강제한 시도도 — AUTH_030 이면 다시 시작하지 않는다', () async {
      final h = await _Harness.start();
      await h.store.markForceLoginPrompt();
      h.server.reject('again', status: 401, error: 'AUTH_030');
      await h.pressLogin();
      expect(h.launched.single.queryParameters['prompt'], 'login');

      await expectLater(
        h.comeBackWith('again'),
        throwsA(_apiError('AUTH_030')),
      );

      expect(h.launched, hasLength(1));
      expect(h.auth.error, _apiError('AUTH_030'));
    });

    test('브라우저를 다시 열지 못하면 로그인 실패로 올린다 — 강제 표시는 남는다', () async {
      final h = await _Harness.start();
      h.server.reject('silent', status: 401, error: 'AUTH_030');
      await h.pressLogin();
      h.browserBroken = true;

      await expectLater(
        h.comeBackWith('silent'),
        throwsA(_apiError('AUTH_030')),
      );

      expect(h.launched, hasLength(1));
      expect(h.auth.error, _apiError('AUTH_030'));
      expect(await h.store.isForceLoginPrompt(), isTrue);
    });

    test('운영과 같은 401 인터셉터가 끼어 있어도 — 한 번만 다시 시작하고 그 로그인으로 들어온다', () async {
      // 운영 dio 는 `/auth/exchange-code` 의 401 도 세션 만료로 읽어 `logout()` 을 같이 부른다
      // (`AuthInterceptor` 의 예외 경로에 교환이 없다). 그 로그아웃이 다시 시작한 흐름을 밟으면 안 된다.
      final h = await _Harness.start(sessionExpiryOn401: true);
      h.server.reject('silent', status: 401, error: 'AUTH_030');
      await h.pressLogin();

      final result = await h.comeBackWith('silent');
      await pumpEventQueue();

      expect(result, OAuthCallbackResult.restartedWithPrompt);
      expect(h.launched, hasLength(2));
      expect(h.launched.last.queryParameters['prompt'], 'login');
      expect(h.auth, const AsyncData<User?>(null));
      expect(h.everShowedError, isFalse);
      expect(
        (await h.store.restorePending())?.forcedPrompt,
        isTrue,
        reason: '다시 시작한 흐름의 보관분이 남아 있어야 복귀를 받는다',
      );

      expect(await h.comeBackWith('fresh'), OAuthCallbackResult.exchanged);
      await pumpEventQueue();
      expect(h.auth.value, _user);
      expect(await h.store.isForceLoginPrompt(), isFalse);
    });
  });

  group('다른 오류는 그대로 로그인 실패다', () {
    for (final (status, error) in [
      (401, 'AUTH_003'),
      (403, 'USER_021'),
      (400, 'AUTH_099'),
      (500, 'COMMON_500'),
    ]) {
      test('$status · $error — 다시 시작하지도, 강제 표시를 남기지도 않는다', () async {
        final h = await _Harness.start();
        h.server.reject('bad', status: status, error: error);
        await h.pressLogin();

        await expectLater(h.comeBackWith('bad'), throwsA(_apiError(error)));

        expect(h.launched, hasLength(1));
        expect(h.auth.error, _apiError(error));
        expect(await h.store.isForceLoginPrompt(), isFalse);
        expect(await h.store.restorePending(), isNull);
      });
    }
  });

  group('강제 표시 — 직접 누른 로그아웃이 남기고 로그인 성공이 지운다', () {
    test('로그아웃하면 다음 로그인은 prompt=login 이고, 들어오면 표시가 지워진다', () async {
      final h = await _Harness.start();
      await h.pressLogin();
      expect(await h.comeBackWith('first'), OAuthCallbackResult.exchanged);
      expect(h.auth.value, _user);
      expect(await h.store.isForceLoginPrompt(), isFalse);

      await h.container.read(authProvider.notifier).logout();

      expect(h.auth, const AsyncData<User?>(null));
      expect(await h.store.isForceLoginPrompt(), isTrue);

      await h.pressLogin();
      expect(h.launched.last.queryParameters['prompt'], 'login');
      expect(
        await h.store.isForceLoginPrompt(),
        isTrue,
        reason: '브라우저를 닫고 다시 눌러도 폼이 뜬다 — 시작만으로는 지우지 않는다',
      );
      await h.pressLogin();
      expect(h.launched.last.queryParameters['prompt'], 'login');

      expect(await h.comeBackWith('second'), OAuthCallbackResult.exchanged);
      expect(await h.store.isForceLoginPrompt(), isFalse);

      // 표시가 지워졌으니 그다음 로그인(세션이 끝나 다시 들어올 때)은 폼을 강제하지 않는다.
      await h.pressLogin();
      expect(h.launched.last.queryParameters.containsKey('prompt'), isFalse);
    });
  });
}
