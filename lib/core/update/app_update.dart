import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';

/// 새 버전 확인 — 스토어를 쓰지 않아 자동 업데이트가 없다.
///
/// 서버가 배포할 때 `/download/version.json` 을 갱신한다(앱 CI 가 만든다).
/// 그걸 읽어 지금 깔린 빌드보다 높으면 알린다.
///
/// 실패는 조용히 넘긴다 — 버전을 못 읽는다고 앱을 못 쓰게 할 이유가 없다.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.androidFile,
    required this.iosFile,
    required this.notes,
    required this.minBuildNumber,
  });

  final String version;
  final int buildNumber;
  final String androidFile;
  final String iosFile;

  /// 이번 버전에서 바뀐 것. CI 가 커밋 제목을 모아 넣는다. 없으면 빈 문자열.
  final String notes;

  /// 이 번호보다 낮은 빌드는 더 쓸 수 없다 — 서버와 앱이 어긋나 잘못된 값을 주고받을
  /// 수 있는 변경에만 올린다(레포 `config/min_build.json` 에서 손으로 관리).
  final int minBuildNumber;

  /// 안드로이드가 직접 받아 설치할 APK 주소.
  String get androidUrl => '${Env.webBaseUrl}/download/$androidFile';

  /// AltStore 소스 주소. CI 가 IPA 와 같이 올린다.
  String get altstoreSourceUrl => '${Env.webBaseUrl}/download/altstore.json';

  /// 받으러 갈 곳.
  ///
  /// 안드로이드는 APK 주소를 그대로 열면 받아서 바로 깔 수 있다.
  ///
  /// 아이폰은 사정이 다르다. 스토어 밖 앱은 스스로를 업데이트할 수 없고, 브라우저로
  /// IPA 를 열어도 서명이 없어 설치가 안 된다 — 파일만 받아지고 아무 일도 안 일어난다.
  /// 그래서 AltStore 에 소스를 넘겨 거기서 받게 한다. 무료 계정의 7일 만료도 AltStore
  /// 쪽에서 갱신되므로, iOS 에서 유일하게 끝까지 이어지는 경로다.
  String get downloadUrl => Platform.isIOS
      ? 'altstore://source?url=$altstoreSourceUrl'
      : '${Env.webBaseUrl}/download/$androidFile';

  /// AltStore 가 안 깔려 있으면 딥링크가 열리지 않는다. 그때 대신 보낼 안내 페이지.
  String get fallbackUrl => '${Env.webBaseUrl}/download';

  /// 버전 파일이 알려 주는 파일 이름의 꼴 — 영문 · 숫자로 시작하고 영문 · 숫자 · `.` `_` `-` 만,
  /// 128자까지(CI 가 쓰는 `groo-desk-1.2.3.apk` 꼴).
  ///
  /// 이 이름은 받을 주소에도, **앱 캐시에 저장할 경로**에도 그대로 붙는다. `../` 나 `/` 가
  /// 섞이면 캐시 밖 앱 내부 파일을 덮어쓸 수 있다(보안 점검 CLI-3) — 꼴이 다르면 버전 파일을
  /// 통째로 믿지 않는다.
  static final RegExp _apkName = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._-]{0,123}\.apk$',
  );
  static final RegExp _ipaName = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._-]{0,123}\.ipa$',
  );

  /// 안드로이드 파일 이름으로 써도 되는가 — 경로 조작(`..` 포함)을 거절한다.
  static bool isSafeApkName(String name) =>
      _apkName.hasMatch(name) && !name.contains('..');

  static bool _isSafeIpaName(String name) =>
      _ipaName.hasMatch(name) && !name.contains('..');

  static AppRelease? tryParse(Object? json) {
    if (json is! Map) return null;
    final version = json['version'];
    final build = json['buildNumber'];
    final android = json['android'];
    final ios = json['ios'];
    if (version is! String || build is! num || android is! String) return null;
    // 파일 이름이 이상하면 버전 파일째 거절한다 — "확인 못 함" 으로 남아 강제 업데이트도 걸지 않는다.
    if (!isSafeApkName(android)) return null;
    final notes = json['notes'];
    final minBuild = json['minBuildNumber'];
    return AppRelease(
      version: version,
      buildNumber: build.toInt(),
      androidFile: android,
      // ios·notes·minBuildNumber 는 나중에 붙었다. 옛 version.json 을 읽어도 죽지
      // 않게 비워 둔다 — 특히 강제 하한은 0 으로 봐야 한다. 값을 못 읽었다고
      // 사용자를 앱 밖으로 밀어내면 안 된다.
      iosFile: ios is String && _isSafeIpaName(ios) ? ios : '',
      notes: notes is String ? notes : '',
      minBuildNumber: minBuild is num ? minBuild.toInt() : 0,
    );
  }
}

/// 받으러 밖으로 내보낸다 — iOS 는 AltStore, 안드로이드는 APK 주소.
///
/// iOS 딥링크는 AltStore 가 없으면 열리지 않고 조용히 실패한다. 그때는 안내가 있는
/// 다운로드 페이지로 대신 보낸다 — 눌렀는데 아무 일도 안 일어나는 게 제일 나쁘다.
///
/// 홈 배너와 업데이트 시트가 같이 쓴다. 두 곳이 따로 놀면 한쪽만 고쳐진다.
Future<void> openReleaseExternally(AppRelease release) async {
  try {
    final ok = await launchUrl(
      Uri.parse(release.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
    if (ok) return;
  } catch (_) {
    // 처리 가능한 앱이 없으면 예외로 떨어진다. 아래 폴백으로 이어 간다.
  }
  await launchUrl(
    Uri.parse(release.fallbackUrl),
    mode: LaunchMode.externalApplication,
  );
}

/// 지금 깔린 빌드의 버전 — 화면에 그대로 보여 줄 문자열.
///
/// 빌드번호를 괄호로 같이 단다. 이름(1.10.0)은 dev·prod 가 같을 수 있어서 그것만으로는
/// 어느 빌드인지 못 가른다 — 새 버전 판정도 빌드번호로 한다.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// 지금 앱이 어떤 상태인가 — 최신인지, 새 버전이 있는지, 더 못 쓰는지.
///
/// 새 버전 유무만으로는 부족하다. 강제 업데이트는 "지금 버전이 하한보다 낮은가" 를
/// 봐야 하는데, 그건 최신이어도 서버 값을 알아야 판정할 수 있다.
class UpdateStatus {
  const UpdateStatus({required this.currentBuild, required this.latest});

  /// 지금 깔린 빌드번호.
  final int currentBuild;

  /// 서버가 알려 준 최신 릴리스. 못 읽었으면 null.
  final AppRelease? latest;

  /// 받을 게 있나.
  bool get hasUpdate => latest != null && latest!.buildNumber > currentBuild;

  /// 이 버전으로는 더 쓸 수 없나 — 받기 전까지 앱을 막는다.
  ///
  /// 서버를 못 읽었으면 막지 않는다. 네트워크가 끊겼다고 앱을 못 쓰게 하면,
  /// 정작 고쳐야 할 문제와 상관없이 사람을 밖에 세워 두는 셈이다.
  bool get mustUpdate =>
      latest != null && currentBuild < latest!.minBuildNumber;

  /// 확인 자체를 못 했나.
  ///
  /// 서버는 항상 json 을 준다 — 성공했는데 latest 가 비는 경우는 없다. 그래서 null 은
  /// "받을 게 없다" 가 아니라 "못 물어봤다" 는 뜻이다. 이걸 구분하지 않으면 서버가
  /// 죽어 있을 때 화면이 "최신 버전이에요" 라고 안심시킨다 — 업데이트 안내가 조용히
  /// 멈추는 게 제일 나쁘다.
  bool get checkFailed => latest == null;

  /// 전체 화면으로 가로막고 알릴 것인가.
  ///
  /// 새 버전이 있어도 한 번 넘긴 빌드는 다시 안 띄운다. 예전에 열 때마다 전체 화면으로
  /// 알리다가 "받을 생각 없는 사람에게는 매번 걷어내야 하는 벽" 이 돼 걷어냈다 —
  /// 그 실패를 되풀이하지 않으려면 넘긴 선택을 존중해야 한다.
  ///
  /// 강제는 예외다. 서버와 어긋난 앱을 계속 쓰게 둘 수는 없어 건너뛰기를 무시한다.
  bool shouldGate(int? skippedBuild) =>
      mustUpdate || (hasUpdate && latest!.buildNumber != skippedBuild);
}

final updateStatusProvider = FutureProvider<UpdateStatus>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final current = int.tryParse(info.buildNumber) ?? 0;
  return UpdateStatus(
    currentBuild: current,
    latest: await ref.watch(_latestReleaseProvider.future),
  );
});

/// 전체 화면 안내를 건너뛴 빌드번호.
///
/// 라우터가 redirect 안에서 읽는데 go_router 의 redirect 는 동기라 await 할 수 없다.
/// 그래서 저장소를 그때 읽지 않고 상태로 들고 있는다.
class SkippedBuildNotifier extends Notifier<int?> {
  /// 저장된 값을 이미 반영했나 — 첫 로드가 늦게 끝나며 뒷값을 덮는 걸 막는다.
  bool _settled = false;

  @override
  int? build() {
    _load();
    // 읽어 오기 전에는 "건너뛴 적 없음" 으로 둔다. 잠깐 게이트가 뜰 수 있지만,
    // 반대로 두면 넘긴 적 없는 새 버전을 놓친다 — 알리는 쪽이 덜 나쁘다.
    return null;
  }

  Future<void> _load() async {
    final prefs = await ref.read(prefsProvider.future);
    // 그 사이 skip() 이 값을 넣었으면 덮지 않는다.
    //
    // build() 가 _load() 를 기다리지 않으므로 둘이 겹칠 수 있다. 겹치면 순서가
    // 이렇게 된다 — skip 이 state 를 넣고 prefs 를 기다리는 동안, 먼저 걸려 있던
    // _load 의 continuation 이 돌아 **저장 전의 옛 값**(대개 null)으로 되돌린다.
    // 그러면 방금 건너뛴 선택이 사라져 게이트가 다시 뜬다.
    if (_settled) return;
    _settled = true;
    state = prefs.getInt(PrefsKeys.updateSkippedBuild);
  }

  /// 이 빌드는 다시 띄우지 않는다.
  ///
  /// 상태를 먼저 바꾼다 — 저장만 하고 상태를 안 바꾸면 라우터가 다시 평가할 게 없어
  /// 앱을 껐다 켤 때까지 게이트에 갇힌다.
  Future<void> skip(int buildNumber) async {
    // 뒤늦게 끝나는 _load 가 이 값을 덮지 못하게 먼저 잠근다.
    _settled = true;
    state = buildNumber;
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setInt(PrefsKeys.updateSkippedBuild, buildNumber);
  }
}

final skippedBuildProvider = NotifierProvider<SkippedBuildNotifier, int?>(
  SkippedBuildNotifier.new,
);

/// 서버가 알려 주는 최신 릴리스 — 지금 버전과 비교하기 전의 날것.
final _latestReleaseProvider = FutureProvider<AppRelease?>((ref) async {
  try {
    final res = await Dio().get<dynamic>(
      '${Env.webBaseUrl}/download/version.json',
      options: Options(
        // 캐시된 옛 버전을 보고 "최신"이라 착각하지 않게.
        headers: const {'Cache-Control': 'no-cache'},
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );
    // 지금 버전과 비교하지 않고 그대로 돌려준다 — 최신이어도 강제 하한을 봐야 해서
    // 서버 값 자체가 필요하다. 비교는 UpdateStatus 가 한다.
    return AppRelease.tryParse(res.data);
  } catch (_) {
    // 배포 전이거나 오프라인 — 알릴 게 없을 뿐이다.
    return null;
  }
});
