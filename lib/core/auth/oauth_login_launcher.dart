import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/core/auth/oauth_browser.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_listener.dart';
import 'package:groo_damda_app/core/auth/pkce.dart';

/// 그루 계정 로그인(OAuth 2.0 Authorization Code + PKCE)을 앱 안 창([openOAuthBrowser] —
/// iOS SFSafariViewController · Android Custom Tabs)에서 시작한다.
///
/// 화면 밖에 둔 이유: 시작하는 자리가 둘이다 — 로그인 화면의 버튼, 그리고 교환이
/// `AUTH_030` 으로 거절됐을 때 인증 상태(`AuthNotifier`)가 폼을 강제해 한 번 다시
/// 시작하는 자리. 뒤쪽은 딥링크 복귀에서 돌아 로그인 화면이 아직 없을 수 있다(콜드 스타트).
class OAuthLoginLauncher {
  OAuthLoginLauncher({required this.store, required this.launch});

  final OAuthFlowStore store;

  /// 주소를 앱 안 창으로 연다 — 못 열었거나 불러오기 전에 닫혔으면 false(또는 throw).
  /// 주입받는 이유: 테스트가 플러그인 채널 없이 "어떤 주소로 나갔는가" 를 본다.
  final Future<bool> Function(Uri url) launch;

  /// 그루 계정 주소로 자격증명을 보내도 되는가 — 비-local 환경에서는 HTTPS 만
  /// (평문 전송 · MITM 방지). 로그인 화면은 이걸 먼저 보고 안내 글을 낸다.
  static bool get isSsoOriginSecure =>
      Env.appEnv == 'local' || Uri.tryParse(Env.ssoUrl)?.scheme == 'https';

  /// PKCE 를 만들어 보관하고 authorize 주소를 앱 안 창으로 연다. 복귀는 딥링크
  /// 리스너([oauthLinkListenerProvider])가 받는다. 못 열면 throw.
  ///
  /// `prompt=login`(살아 있는 그루 계정 로그인을 쓰지 않고 폼을 강제)은 기기에 강제
  /// 표시가 있을 때 싣는다 — 해제는 로그인 성공 시(콜백 처리기)에 한다.
  /// [forcePrompt] 를 주면 표시와 상관없이 싣는다(`AUTH_030` 뒤의 다시 시작 — 표시를
  /// 읽지 못해도 폼 없이 되돌아와 같은 거절을 되풀이하지 않게).
  Future<void> start({bool forcePrompt = false}) async {
    if (!isSsoOriginSecure) {
      throw StateError('SSO origin is not HTTPS');
    }
    // 1) PKCE + state 생성(앱이 직접) → 브라우저로 나가기 전에 디스크 보관.
    //    복귀가 콜드 스타트여도 리스너가 이걸 복원해 교환을 이어간다.
    final verifier = generateCodeVerifier();
    final challenge = codeChallengeS256(verifier);
    final state = generateState();
    final prompt = forcePrompt || await store.isForceLoginPrompt();
    await store.savePending(
      verifier: verifier,
      state: state,
      forcedPrompt: prompt,
    );

    // 2) authorize URL 조립. challenge/state 는 base64url(no padding) 이라 URL-safe.
    final authorizeUrl =
        '${Env.ssoUrl}/api/v1/oauth2/authorize'
        '?response_type=code'
        '&client_id=${Env.oauthClientId}'
        '&redirect_uri=${Uri.encodeComponent(Env.oauthRedirectUri)}'
        '&code_challenge=$challenge'
        '&code_challenge_method=S256'
        '&state=${Uri.encodeComponent(state)}'
        '${prompt ? '&prompt=login' : ''}';

    // 3) 앱 안 창으로. 돌아오면 리스너가 창을 닫는다(closeOAuthBrowser).
    final launched = await launch(Uri.parse(authorizeUrl));
    if (!launched) {
      throw StateError('브라우저를 열 수 없습니다');
    }
  }
}

final oauthLoginLauncherProvider = Provider<OAuthLoginLauncher>(
  (ref) => OAuthLoginLauncher(
    store: ref.watch(oauthFlowStoreProvider),
    launch: openOAuthBrowser,
  ),
);
