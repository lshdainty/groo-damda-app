import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 받은 APK 를 설치 화면에 넘기기 전에 내린 판정.
enum ApkVerdict {
  /// 이 앱과 패키지 이름 · 서명 인증서가 같다 — 설치 화면을 열어도 된다.
  ok,

  /// 다른 앱이다 — 패키지 이름이 다르다.
  packageMismatch,

  /// 같은 이름이지만 서명한 키가 다르다.
  signatureMismatch,

  /// APK 로 읽히지 않거나 확인 자체를 못 했다.
  unreadable;

  static ApkVerdict parse(String? raw) => switch (raw) {
    'ok' => ApkVerdict.ok,
    'packageMismatch' => ApkVerdict.packageMismatch,
    'signatureMismatch' => ApkVerdict.signatureMismatch,
    _ => ApkVerdict.unreadable,
  };
}

/// 받은 APK 가 정말 이 앱의 새 빌드인지 확인한다(보안 점검 CLI-3).
///
/// 버전 파일과 APK 는 HTTPS 로 받지만 그 자체로는 "누가 만든 파일인가" 를 말하지 않는다.
/// 배포 경로가 장악되면 업데이트 화면에서 다른 앱을 깔게 할 수 있다 — 안드로이드는 같은
/// 패키지의 다른 서명은 설치에서 막아 주지만, **패키지 이름이 다른 앱은 새 앱으로 깔린다.**
/// 그래서 설치 화면을 열기 전에 패키지 이름과 서명 인증서 지문을 지금 앱과 대조한다.
///
/// 대조는 네이티브(`porest/app_update` · `ApkVerifier.kt`)가
/// `PackageManager.getPackageArchiveInfo` 로 한다. 채널이 없거나 실패하면 통과시키지
/// 않는다 — 확인하지 못한 파일을 설치로 넘기는 쪽이 더 나쁘다.
class ApkVerifier {
  const ApkVerifier([this._channel = const MethodChannel('porest/app_update')]);

  final MethodChannel _channel;

  Future<ApkVerdict> verify(String path) async {
    try {
      final raw = await _channel.invokeMethod<String>('verifyApk', {
        'path': path,
      });
      return ApkVerdict.parse(raw);
    } on MissingPluginException {
      return ApkVerdict.unreadable;
    } on PlatformException {
      return ApkVerdict.unreadable;
    }
  }
}

final apkVerifierProvider = Provider<ApkVerifier>((ref) => const ApkVerifier());
