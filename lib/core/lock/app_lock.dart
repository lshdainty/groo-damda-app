import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import 'package:groo_damda_app/core/settings/settings_notifier.dart';

/// OS 생체인증(Face ID·지문) 결과.
enum AppLockAuthResult {
  /// 본인 확인 성공.
  success,

  /// 불일치·취소 — 잠금을 유지하고 다시 시도하게 둔다.
  failure,

  /// 이 기기에서 인증 수단을 쓸 수 없다(하드웨어 없음·아무것도 등록 안 됨).
  unavailable,
}

/// [LocalAuthentication] 얇은 래퍼 — 테스트에서 프롬프트 없이 갈아끼우기 위한 이음새.
class AppLockAuth {
  AppLockAuth(this._auth);

  final LocalAuthentication _auth;

  /// 켜기 전에 물어본다 — 인증 수단이 아예 없는 기기에서 잠금을 켜면 앱을 영영 못 연다.
  Future<bool> isDeviceSupported() {
    return _auth.isDeviceSupported();
  }

  /// OS 프롬프트를 띄워 본인 확인을 받는다.
  ///
  /// 생체인증이 안 되면 기기 잠금(PIN·패턴·암호)으로 폴백한다(`biometricOnly` 기본
  /// false) — 마스크·장갑 같은 일시 실패로 앱에 갇히는 일을 막는다.
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return AppLockAuthResult.unavailable;
      }
      final ok = await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          // iOS 시스템 버튼은 시스템 언어를 따르고 취소만 앱이 넘긴다.
          IOSAuthMessages(cancelButton: cancelLabel),
          // Android BiometricPrompt 의 제목·취소는 앱 문자열이다 — 안 넘기면 영어가 뜬다.
          AndroidAuthMessages(
            signInTitle: signInTitle,
            cancelButton: cancelLabel,
          ),
        ],
        // 인증 도중 앱이 백그라운드로 밀리면(전화 수신 등) 실패로 끝내지 말고
        // 복귀 시 프롬프트를 다시 띄운다.
        persistAcrossBackgrounding: true,
      );
      return ok ? AppLockAuthResult.success : AppLockAuthResult.failure;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        // 인증 수단이 하나도 없다 — 잠금으로 가둘 수 없는 상태.
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware =>
          AppLockAuthResult.unavailable,
        _ => AppLockAuthResult.failure,
      };
    }
  }
}

final appLockAuthProvider = Provider<AppLockAuth>((ref) {
  return AppLockAuth(LocalAuthentication());
});

/// 이 기기에서 생체 인증 · 화면 잠금을 쓸 수 있는가 — 설정 줄이 스위치를 미리 막는 데 쓴다.
/// 물어보지 못하면(플랫폼 오류) 막지 않는다 — 켤 때의 인증이 다시 가른다.
final appLockSupportedProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    return await ref.read(appLockAuthProvider).isDeviceSupported();
  } on Object {
    return true;
  }
});

/// 켜 보려다 이 기기에서 쓸 수 없다고 나왔다 — 미리 물은 값이 낡았을 때(설정에서 화면 잠금을 지운 뒤) 줄 설명이 그 자리에서 바뀐다.
/// 앱이 앞으로 돌아오면 다시 묻고 비운다.
final appLockUnavailableNowProvider =
    NotifierProvider<AppLockUnavailableNow, bool>(AppLockUnavailableNow.new);

class AppLockUnavailableNow extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// 앱 잠금 설정이 켜져 있는가 (표시 설정 > 개인정보 보호).
final appLockEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).value?.appLock ?? false;
});

/// 지금 잠겨 있는가 — [AppLockGate] 가 이 값으로 잠금 화면을 덮는다.
final appLockedProvider = NotifierProvider<AppLockedNotifier, bool>(
  AppLockedNotifier.new,
);

class AppLockedNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(settingsProvider, (prev, next) {
      final settings = next.value;
      if (settings == null) return;
      final prevLoaded = prev != null && prev.hasValue;
      if (!settings.appLock) {
        // 설정을 끄면 즉시 해제 — 켜진 설정 없이 잠겨 있으면 풀 방법이 없다.
        state = false;
      } else if (!prevLoaded) {
        // 콜드 스타트: 저장된 설정이 로드되는 순간 잠근 채 시작.
        // 켠 직후(data→data 전환)는 잠그지 않는다 — 방금 생체인증을 통과했다.
        state = true;
      }
    });
    // 게이트보다 설정이 먼저 로드된 경우(위 listen 이 전환을 못 본다)를 위한 초기값.
    return ref.read(settingsProvider).value?.appLock ?? false;
  }

  /// 백그라운드 진입 시 게이트가 부른다. 설정이 꺼져 있으면 아무것도 안 한다.
  void lock() {
    if (ref.read(appLockEnabledProvider)) state = true;
  }

  void unlock() => state = false;
}
