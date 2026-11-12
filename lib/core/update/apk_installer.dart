import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/core/update/apk_verifier.dart';
import 'package:groo_damda_app/core/update/app_update.dart';

/// 안드로이드에서 새 APK 를 받아 설치 화면까지 데려다준다.
///
/// **자동 설치는 안 된다.** 스토어 밖에서 온 APK 는 시스템이 사용자에게 한 번 더
/// 묻게 돼 있고(Android 보안 정책), 기기 관리자 앱이 아닌 한 그 화면을 건너뛸 방법이
/// 없다. 여기서 줄이는 건 그 앞의 걸음이다 — 브라우저로 나가 받고 알림을 눌러
/// 되돌아오는 대신, 앱 안에서 받아 곧장 설치 화면을 띄운다.
enum ApkStage {
  idle,
  downloading,
  opening,
  failed,

  /// 받은 파일이 이 앱의 새 빌드가 아니다(패키지 이름 · 서명이 다르거나 확인 못 함).
  rejected,
}

/// [ApkInstaller.downloadAndOpen] 의 결과.
enum ApkInstallResult {
  /// 설치 화면을 열었다.
  opened,

  /// 받거나 열지 못했다 — 브라우저로 받아 보는 길이 남아 있다.
  failed,

  /// 받은 파일이 이 앱이 아니라서 설치하지 않았다. **브라우저로도 넘기지 않는다** —
  /// 같은 주소에서 같은 파일을 받게 될 뿐이다.
  rejected,
}

class ApkProgress {
  const ApkProgress({
    this.stage = ApkStage.idle,
    this.received = 0,
    this.total = 0,
  });

  final ApkStage stage;
  final int received;
  final int total;

  /// 0.0~1.0. 서버가 길이를 안 주면(total<=0) null — 그때는 무한 진행 표시를 쓴다.
  double? get ratio => total > 0 ? (received / total).clamp(0.0, 1.0) : null;

  bool get isBusy => stage == ApkStage.downloading || stage == ApkStage.opening;
}

/// 받기 · 저장 위치 · 설치 화면 열기 — 플랫폼에 닿는 세 가지를 한데 둔 이음새(테스트에서 갈아끼운다).
class ApkIo {
  const ApkIo();

  /// 앱 전용 캐시 폴더.
  Future<String> cacheDir() async => (await getTemporaryDirectory()).path;

  Future<void> download(
    String url,
    String path, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => Dio().download(
    url,
    path,
    cancelToken: cancelToken,
    onReceiveProgress: onReceiveProgress,
  );

  /// 시스템 설치 화면을 연다. 열었으면 true.
  Future<bool> openInstaller(String path) async {
    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    return result.type == ResultType.done;
  }
}

final apkIoProvider = Provider<ApkIo>((ref) => const ApkIo());

class ApkInstaller extends Notifier<ApkProgress> {
  CancelToken? _cancel;

  @override
  ApkProgress build() {
    ref.onDispose(() => _cancel?.cancel());
    return const ApkProgress();
  }

  /// 받아서 설치 화면을 연다.
  ///
  /// 저장 위치는 앱 전용 캐시다. 공유 저장소가 아니라서 따로 권한이 필요 없고,
  /// 설치가 끝나면 시스템이 알아서 치워도 그만인 자리다.
  ///
  /// 설치 화면을 열기 전에 받은 파일의 패키지 이름 · 서명 인증서를 지금 앱과 대조한다
  /// ([ApkVerifier], 보안 점검 CLI-3). 다르면 지우고 [ApkInstallResult.rejected].
  Future<ApkInstallResult> downloadAndOpen(AppRelease release) async {
    if (state.isBusy) return ApkInstallResult.failed;

    // 버전 파일을 읽을 때 이미 거르지만, 저장 경로에 붙기 직전에 한 번 더 본다.
    if (!AppRelease.isSafeApkName(release.androidFile)) {
      state = const ApkProgress(stage: ApkStage.rejected);
      return ApkInstallResult.rejected;
    }

    final io = ref.read(apkIoProvider);
    _cancel = CancelToken();
    state = const ApkProgress(stage: ApkStage.downloading);
    try {
      final dir = await io.cacheDir();
      final path = '$dir/${release.androidFile}';

      // 받다 만 파일이 남아 있으면 설치가 "패키지 손상"으로 튕긴다. 늘 새로 받는다.
      final file = File(path);
      if (file.existsSync()) await file.delete();

      await io.download(
        release.androidUrl,
        path,
        cancelToken: _cancel,
        onReceiveProgress: (received, total) {
          state = ApkProgress(
            stage: ApkStage.downloading,
            received: received,
            total: total,
          );
        },
      );

      state = const ApkProgress(stage: ApkStage.opening);
      final verdict = await ref.read(apkVerifierProvider).verify(path);
      if (verdict != ApkVerdict.ok) {
        // 이 앱이 아닌 파일은 남겨 두지 않는다.
        if (file.existsSync()) await file.delete();
        state = const ApkProgress(stage: ApkStage.rejected);
        return ApkInstallResult.rejected;
      }

      if (!await io.openInstaller(path)) {
        state = const ApkProgress(stage: ApkStage.failed);
        return ApkInstallResult.failed;
      }
      state = const ApkProgress();
      return ApkInstallResult.opened;
    } catch (_) {
      // 네트워크가 끊겼거나 저장에 실패했다. 사용자는 다시 누르면 된다 —
      // 어차피 실패해도 잃는 건 받던 파일뿐이다.
      state = const ApkProgress(stage: ApkStage.failed);
      return ApkInstallResult.failed;
    } finally {
      _cancel = null;
    }
  }
}

final apkInstallerProvider = NotifierProvider<ApkInstaller, ApkProgress>(
  ApkInstaller.new,
);

/// "나중에" 를 누른 빌드번호. 그 버전은 전체 화면으로 다시 묻지 않는다.
///
/// 홈 배너는 그대로 남는다 — 미뤘다고 없던 일이 되는 건 아니고, 마음이 바뀌면
/// 거기서 다시 들어갈 수 있어야 한다.
const _kSkippedBuildKey = 'pd-update-skipped-build';

Future<int> loadSkippedBuild() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_kSkippedBuildKey) ?? 0;
}

Future<void> saveSkippedBuild(int buildNumber) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kSkippedBuildKey, buildNumber);
}
