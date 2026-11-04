import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_return.dart';

/// OAuth 콜백 딥링크(`porestdesk://oauth/callback?code=&state=`) 처리기.
///
/// 시스템 브라우저에서 로그인이 끝나면 OS 딥링크로 이 URI 가 들어온다 — 앱이
/// 살아 있으면 스트림으로, 죽었다 떠도 initial link 로. 어느 경로든 여기 한 곳에서:
///
/// 1. 보관해 둔 진행 중 흐름([OAuthFlowStore])을 복원하고
/// 2. state 를 대조(CSRF — 다른 앱이 스킴을 하이재킹해 위조 콜백을 쏴도,
///    state 도 verifier 도 모르는 코드는 여기서 버려진다)
/// 3. 인가코드를 BFF 교환([exchange])에 넘긴다.
///
/// 교환 함수를 주입받는 이유: 이 클래스는 URI 검증·상태 대조라는 순수 로직만 지고,
/// Riverpod/네트워크는 바깥(리스너 프로바이더)이 묶는다 — 테스트가 저장소 페이크와
/// 함수 하나로 끝난다.
class OAuthCallbackHandler {
  OAuthCallbackHandler({required this.store, required this.exchange});

  final OAuthFlowStore store;

  /// BFF 교환 — (code, codeVerifier) 를 받아 로그인 완료까지 책임진다. 실패는 throw.
  final Future<void> Function({
    required String code,
    required String codeVerifier,
  })
  exchange;

  /// 처리 결과 — 호출측(리스너)이 로그로 남길 수 있게 이유를 돌려준다.
  /// 사용자에게 보여줄 에러는 exchange 실패(throw)뿐이다 — 나머지는 위조·중복·잡음이라
  /// 조용히 버리는 게 맞다.
  Future<OAuthCallbackResult> handle(Uri uri) async {
    if (uri.scheme != Env.authCallbackScheme) {
      return OAuthCallbackResult.notCallback;
    }
    // 소셜 연동 복귀(`porestdesk://oauth/linked`)는 로그인 흐름이 아니다 — 경로로 먼저 가른다(I-14 10).
    if (parseOAuthLinkReturn(uri) != null) {
      return OAuthCallbackResult.linkReturn;
    }

    final pending = await store.restorePending();
    if (pending == null) {
      // 진행 중 흐름이 없다 — 이미 소비한 콜백의 중복 배달이거나 위조.
      return OAuthCallbackResult.noPendingFlow;
    }

    final state = uri.queryParameters['state'];
    if (state != pending.state) {
      // CSRF 의심 — 진짜 흐름은 아직 콜백이 올 수 있으므로 보관분은 지우지 않는다.
      return OAuthCallbackResult.stateMismatch;
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      return OAuthCallbackResult.noCode;
    }

    // state 까지 맞은 진짜 콜백 — 재배달·재사용 방어를 위해 교환 전에 소비 처리.
    // (인가코드는 1회용이라 교환 실패 후 재시도해도 어차피 처음부터 다시다)
    await store.clearPending();
    await exchange(code: code, codeVerifier: pending.verifier);
    await store.clearForceLoginPrompt();
    return OAuthCallbackResult.exchanged;
  }
}

enum OAuthCallbackResult {
  notCallback,

  /// 연동 복귀 딥링크 — 로그인 콜백이 아니라 연결된 계정 줄이 받는다.
  linkReturn,
  noPendingFlow,
  stateMismatch,
  noCode,
  exchanged,
}
