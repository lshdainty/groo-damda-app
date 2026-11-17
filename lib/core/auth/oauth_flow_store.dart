import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 진행 중인 OAuth 흐름의 PKCE 상태 보관소.
///
/// 시스템 브라우저 로그인은 앱이 백그라운드로 밀려나는 동안 프로세스가 죽을 수 있다
/// — 예전 flutter_appauth 가 진행 상태를 메모리에만 들고 있다가 "No stored state" 로
/// 죽던 바로 그 지점이다. code_verifier/state 를 브라우저로 나가기 **전에** 디스크에
/// 박아 두면 콜드 스타트로 돌아와도 교환을 이어갈 수 있다.
///
/// code_verifier 는 인가코드와 교환 가능한 비밀이라 secure storage 에 둔다.
class OAuthFlowStore {
  OAuthFlowStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kVerifier = 'oauth_pending_verifier';
  static const _kState = 'oauth_pending_state';
  static const _kPendingForced = 'oauth_pending_forced_prompt';
  static const _kForcePrompt = 'oauth_force_login_prompt';

  /// 브라우저로 나가기 직전 호출 — 재시도 시 이전 흐름은 덮어쓴다.
  ///
  /// [forcedPrompt] 는 이 시도를 `prompt=login` 으로 보냈는지다. verifier · state 와 수명이
  /// 같다 — 교환이 `AUTH_030` 으로 거절됐을 때 "폼을 강제하고도 거절됐는가" 를 가르는
  /// 기준이라(그러면 다시 보내지 않는다), 브라우저에 가 있는 동안 프로세스가 죽어도 남아야 한다.
  Future<void> savePending({
    required String verifier,
    required String state,
    bool forcedPrompt = false,
  }) async {
    await _storage.write(key: _kVerifier, value: verifier);
    await _storage.write(key: _kState, value: state);
    // 지난 시도의 값이 남지 않게 아닐 때는 지운다.
    if (forcedPrompt) {
      await _storage.write(key: _kPendingForced, value: '1');
    } else {
      await _storage.delete(key: _kPendingForced);
    }
  }

  /// 진행 중 흐름 복원. 없으면 null (콜백이 왔는데 흐름이 없다 = 무시 대상).
  Future<({String verifier, String state, bool forcedPrompt})?>
  restorePending() async {
    final verifier = await _storage.read(key: _kVerifier);
    final state = await _storage.read(key: _kState);
    if (verifier == null ||
        verifier.isEmpty ||
        state == null ||
        state.isEmpty) {
      return null;
    }
    final forced = await _storage.read(key: _kPendingForced);
    return (verifier: verifier, state: state, forcedPrompt: forced == '1');
  }

  /// 교환을 마쳤거나(성공) 흐름을 소비했으면 지운다 — 같은 콜백의 중복 배달 방어.
  Future<void> clearPending() async {
    await _storage.delete(key: _kVerifier);
    await _storage.delete(key: _kState);
    await _storage.delete(key: _kPendingForced);
  }

  /// 로그아웃 직후 첫 로그인은 무음 재인증 없이 폼을 강제한다(prompt=login).
  /// 브라우저 쿠키(SSO Refresh)는 앱이 지울 수 없어, 이 표시가 없으면 로그아웃해도
  /// 로그인 버튼 한 번에 세션이 조용히 되살아난다.
  ///
  /// 남기는 자리는 셋이다 — 로그아웃(`AuthNotifier.logout`), 교환이 `AUTH_030` 으로
  /// 거절됐을 때(`AuthNotifier.exchangeAndLoginWithCode`), 그리고 담다를 쓸 수 없는 그루
  /// 계정이라 교환이 `AUTH_003` 으로 거절됐을 때(같은 자리). 가운데는 이 표시가 사라진
  /// 기기(앱 데이터 삭제 등)를 서버의 거절이 대신 잡아 준 경우고, 마지막은 같은 계정으로
  /// 맴돌지 않고 폼에서 계정을 바꿀 수 있게 하는 것이다.
  Future<void> markForceLoginPrompt() =>
      _storage.write(key: _kForcePrompt, value: '1');

  /// 강제 폼 표시가 예약돼 있는지. 소비(해제)는 로그인 성공 시점에 한다 —
  /// 사용자가 브라우저를 취소하고 다시 눌러도 폼 강제가 유지되게.
  Future<bool> isForceLoginPrompt() async =>
      (await _storage.read(key: _kForcePrompt)) == '1';

  /// 로그인 성공 — 강제 폼 예약 해제.
  Future<void> clearForceLoginPrompt() => _storage.delete(key: _kForcePrompt);
}
