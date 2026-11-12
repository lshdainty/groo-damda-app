import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';

/// 화면을 밖으로 내보내지 않아야 하는가 — 앱 잠금을 켰거나 금액을 하나라도 가려 둔 동안.
///
/// 잠금 화면 · 금액 가리기는 Flutter 가 그리는 덮개라, 앱이 백그라운드로 나가는 순간 OS 가
/// 찍는 최근 앱 화면(앱 스위처) 스냅샷보다 늦을 수 있다. 그래서 이 값이 켜진 동안은 OS 쪽에서
/// 막는다(보안 점검 CLI-5) — 안드로이드는 화면 캡처 · 녹화 · 최근 앱 미리보기를 통째로 막고,
/// iOS 는 백그라운드로 나갈 때 가림막을 덮는다(iOS 에는 캡처를 막는 공개 API 가 없다).
final screenProtectionWantedProvider = Provider<bool>((ref) {
  return ref.watch(appLockEnabledProvider) || ref.watch(anyHiddenProvider);
});

/// 네이티브 화면 보호 창구(`porest/screen_privacy`).
///
/// - Android: `MainActivity` 가 창에 `FLAG_SECURE` 를 걸거나 푼다.
/// - iOS: `AppDelegate` 의 `ScreenPrivacyChannel` 이 값을 들고 있다가, 장면이 백그라운드로
///   나갈 때 가림막을 덮고 돌아와 활성이 되면 걷는다.
class ScreenProtection {
  const ScreenProtection([
    this._channel = const MethodChannel('porest/screen_privacy'),
  ]);

  final MethodChannel _channel;

  /// 보호를 켜거나 끈다. 실패해도 앱을 멈추지 않는다 — 보호를 못 거는 플랫폼(데스크톱 ·
  /// 채널이 없는 옛 네이티브)에서는 Flutter 덮개만 남는다.
  Future<void> apply(bool on) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setProtected', {'on': on});
    } on MissingPluginException {
      // 채널이 없는 환경(테스트 등) — 무시한다.
    } on PlatformException {
      // 네이티브가 못 걸었다 — 앱은 계속 쓴다.
    }
  }
}

final screenProtectionProvider = Provider<ScreenProtection>(
  (ref) => const ScreenProtection(),
);
