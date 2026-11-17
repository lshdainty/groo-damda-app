// 그루 계정 로그인 시작(OAuthLoginLauncher) — 브라우저로 나가는 주소와, 나가기 전에 보관하는 것.
//
// 붙잡는 것:
//  - 로그아웃이 남긴 강제 표시가 있을 때만 prompt=login 을 싣는다(없으면 살아 있는 그루 계정 로그인으로 조용히 들어온다)
//  - 이 시도를 prompt=login 으로 보냈는지를 PKCE 와 같이 보관한다 — 교환이 AUTH_030 으로 거절됐을 때
//    "한 번만 다시 시작" 을 가르는 기준이다(보안 점검 CLI-6)
//  - 보관은 브라우저보다 먼저다(브라우저에 가 있는 동안 프로세스가 죽어도 교환을 잇는다)
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_login_launcher.dart';
import 'package:groo_damda_app/core/auth/pkce.dart';
import '../../support/memory_secure_storage.dart';

void main() {
  late OAuthFlowStore store;
  late List<Uri> launched;
  late OAuthLoginLauncher launcher;

  setUp(() {
    store = OAuthFlowStore(MemorySecureStorage());
    launched = [];
    launcher = OAuthLoginLauncher(
      store: store,
      launch: (url) async {
        launched.add(url);
        return true;
      },
    );
  });

  test('그루 계정 authorize 주소로 나간다 — 보관한 PKCE · state 와 짝이 맞는다', () async {
    await launcher.start();

    final url = launched.single;
    final pending = (await store.restorePending())!;
    expect(
      '${url.scheme}://${url.host}${url.path}',
      '${Env.ssoUrl}/api/v1/oauth2/authorize',
    );
    expect(url.queryParameters['response_type'], 'code');
    expect(url.queryParameters['client_id'], Env.oauthClientId);
    expect(url.queryParameters['redirect_uri'], Env.oauthRedirectUri);
    expect(url.queryParameters['code_challenge_method'], 'S256');
    expect(
      url.queryParameters['code_challenge'],
      codeChallengeS256(pending.verifier),
    );
    expect(url.queryParameters['state'], pending.state);
  });

  test('강제 표시가 없으면 prompt 를 싣지 않고, 강제하지 않은 시도로 보관한다', () async {
    await launcher.start();

    expect(launched.single.queryParameters.containsKey('prompt'), isFalse);
    expect((await store.restorePending())!.forcedPrompt, isFalse);
  });

  test('로그아웃이 남긴 강제 표시가 있으면 prompt=login — 강제한 시도로 보관한다', () async {
    await store.markForceLoginPrompt();

    await launcher.start();

    expect(launched.single.queryParameters['prompt'], 'login');
    expect((await store.restorePending())!.forcedPrompt, isTrue);
    expect(
      await store.isForceLoginPrompt(),
      isTrue,
      reason: '표시는 시작이 아니라 로그인 성공이 지운다 — 브라우저를 닫고 다시 눌러도 폼이 뜬다',
    );
  });

  test('forcePrompt 를 주면 표시가 없어도 prompt=login 이다', () async {
    await launcher.start(forcePrompt: true);

    expect(launched.single.queryParameters['prompt'], 'login');
    expect((await store.restorePending())!.forcedPrompt, isTrue);
  });

  test('보관이 브라우저보다 먼저다', () async {
    ({String verifier, String state, bool forcedPrompt})? atLaunch;
    launcher = OAuthLoginLauncher(
      store: store,
      launch: (url) async {
        atLaunch = await store.restorePending();
        return true;
      },
    );

    await launcher.start();

    expect(atLaunch, isNotNull);
  });

  test('브라우저를 못 열면 던진다', () async {
    launcher = OAuthLoginLauncher(store: store, launch: (_) async => false);

    await expectLater(launcher.start(), throwsStateError);
  });
}
