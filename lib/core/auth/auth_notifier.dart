import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/auth/auth_events.dart';
import 'package:groo_damda_app/core/auth/oauth_link_listener.dart';
import 'package:groo_damda_app/core/auth/oauth_login_launcher.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/auth/auth_repository.dart';
import 'package:groo_damda_app/core/auth/user.dart';

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return AuthRepository(dio);
});

/// 인증 상태 = `AsyncValue<User?>`.
/// - loading: 세션 검증 중
/// - data(user): 로그인됨
/// - data(null): 로그아웃 / 미인증
/// - error: 검증 자체가 네트워크 등으로 실패
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // 401(세션 만료) 신호 구독 — dio 인터셉터가 신호를 올리면 강제 로그아웃.
    // dio 는 auth 를 직접 참조하지 않고 신호만 올리므로 dio↔auth 순환이 끊긴다.
    ref.listen(sessionExpiredProvider, (prev, next) {
      if ((prev ?? 0) < next) {
        logout();
      }
    });

    final repo = await ref.watch(authRepositoryProvider.future);
    try {
      return await repo.check();
    } on ApiException catch (e) {
      // 401 = 미로그인 상태로 간주 (정상 케이스)
      if (e.isUnauthorized) return null;
      rethrow;
    }
  }

  /// OAuth2 인가코드(PKCE)를 desk 토큰으로 교환 후 인증 상태 갱신 (표준 흐름, BFF).
  ///
  /// 인앱 WebView 가 가로챈 인가코드(code)+codeVerifier 를 desk-back 으로 교환한다.
  /// 1. `/auth/exchange-code` → desk_access_token 쿠키 발급
  /// 2. `/auth/check` → 사용자 정보 (rowId 포함)
  /// 3. AsyncData(user) → router redirect 가 /home 으로 이동
  ///
  /// 실패 시 [ApiException] 등을 그대로 throw — LoginScreen 의 catch 가 사용자에게 표시.
  ///
  /// **돌려주는 값** — 로그인이 끝났으면 `true`. `false` 는 실패가 아니라 "비밀번호를 다시
  /// 받는 로그인으로 다시 보냈다" 다(로그인은 아직이다):
  ///
  /// 담다 로그아웃은 담다만 끝내고 그루 계정 로그인은 남긴다(보안 점검 CLI-6). 서버는
  /// 로그아웃한 그 로그인으로 돌아온 코드를 `AUTH_030` 으로 거절한다. 평소에는 기기의
  /// 강제 표시가 `prompt=login` 을 실어 이 거절을 만나지 않는다 — 만나는 것은 표시가
  /// 없는데 그 로그인이 살아 있을 때다(앱 데이터를 지웠다 · 브라우저 쪽 로그인이 남았다).
  /// 그때 강제 표시를 남기고 `prompt=login` 으로 **한 번** 다시 시작한다. 사용자에게는
  /// 그루 계정의 로그인 폼이 뜨는 것으로 충분해 에러로 올리지 않는다.
  ///
  /// [forcedPrompt] 는 이 코드를 받아 온 시도가 이미 `prompt=login` 이었는지다. 폼을
  /// 강제하고도 또 거절됐으면 다시 보내도 같다 — 맴돌지 않고 보통의 로그인 실패로 올린다.
  ///
  /// 담다를 쓸 수 없는 그루 계정(`AUTH_003`)으로 거절되면 강제 표시만 남기고 로그인 실패로
  /// 올린다 — 저절로 다시 시작하지 않는다(고르는 건 사용자다). 그루 계정 로그인이 살아 있어
  /// 표시 없이 다시 누르면 같은 계정으로 코드가 나와 같은 거절이 끝없이 되풀이된다. 표시가
  /// 있으면 다음 로그인 버튼이 `prompt=login` 으로 폼을 띄워 계정을 바꿀 수 있다.
  Future<bool> exchangeAndLoginWithCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    bool forcedPrompt = false,
  }) async {
    final repo = await ref.read(authRepositoryProvider.future);
    state = const AsyncLoading();
    try {
      await repo.exchangeCode(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );
      final user = await repo.check();
      state = AsyncData(user);
      return true;
    } catch (e, st) {
      if (!forcedPrompt &&
          e is ApiException &&
          e.isLoggedOutSsoLogin &&
          await _restartWithLoginPrompt()) {
        // 에러로 올리면 브라우저가 다시 뜨기 전 로그인 화면에 실패 글이 번쩍인다.
        state = const AsyncData(null);
        return false;
      }
      if (e is ApiException && e.isServiceAccessDenied) {
        await _markForceLoginPromptQuietly();
      }
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 살아 있는 그루 계정 로그인을 쓰지 않게 폼을 강제해(`prompt=login`) 로그인을 다시
  /// 시작한다. 강제 표시도 남긴다 — 사용자가 브라우저를 닫고 버튼을 다시 눌러도 폼이
  /// 뜨게(해제는 로그인 성공 시 콜백 처리기). 다시 시작하지 못했으면 `false` — 부른 쪽이
  /// 원래 거절을 로그인 실패로 올린다.
  Future<bool> _restartWithLoginPrompt() async {
    try {
      await ref.read(oauthFlowStoreProvider).markForceLoginPrompt();
      await ref.read(oauthLoginLauncherProvider).start(forcePrompt: true);
      return true;
    } catch (e) {
      debugPrint('OAuth restart with prompt=login failed: $e');
      return false;
    }
  }

  /// 강제 표시를 남긴다 — 저장에 실패해도 원래 거절을 그대로 올리도록 삼킨다.
  Future<void> _markForceLoginPromptQuietly() async {
    try {
      await ref.read(oauthFlowStoreProvider).markForceLoginPrompt();
    } catch (e) {
      debugPrint('OAuth mark force prompt failed: $e');
    }
  }

  /// 로그인 실패를 확인했다 — 에러를 걷고 로그아웃 상태로 돌린다.
  ///
  /// 해지한 계정(`USER_021`)은 라우터가 해지 완료 화면으로 보낸다. 그 화면에서 로그인
  /// 화면으로 갈 때 부른다 — 에러가 남아 있으면 라우터가 다시 완료 화면으로 돌려보낸다.
  void dismissLoginError() {
    if (state.hasError) state = const AsyncData(null);
  }

  /// 로그아웃: 서버 호출 + 쿠키 정리 + 상태 초기화.
  Future<void> logout() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final jar = await ref.read(cookieJarProvider.future);
    state = const AsyncLoading();
    try {
      await repo.logout();
    } on ApiException {
      // transient 실패 대비 1회 재시도 — 서버 세션이 살아있는 채 클라만 비는 상황 최소화.
      try {
        await repo.logout();
      } on ApiException {
        // 그래도 실패하면 클라이언트 세션만 정리(UI 로그아웃 보장).
        // 서버 세션 무효화는 토큰 만료 시점에 처리됨.
      }
    }
    await jar.deleteAll();
    // SSO Refresh 쿠키는 브라우저 쪽(앱 안 창 · 바깥 브라우저)에 있어 앱이 지울 수 없다 — 다음 로그인에
    // prompt=login 을 실어 무음 재인증이 로그아웃을 조용히 되살리는 것을 막는다.
    // (해제는 다음 로그인 성공 시 콜백 처리기가 한다)
    await ref.read(oauthFlowStoreProvider).markForceLoginPrompt();
    state = const AsyncData(null);
  }
}
