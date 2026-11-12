import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/update/apk_installer.dart';
import 'package:groo_damda_app/core/update/apk_verifier.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

/// 앱 업데이트가 받은 파일을 확인한다(보안 점검 CLI-3).
///
/// - 버전 파일의 파일 이름은 앱 캐시 경로에 그대로 붙는다 — 경로 조작을 거절한다.
/// - 받은 APK 는 패키지 이름 · 서명 인증서가 지금 앱과 같을 때만 설치 화면을 연다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object?> versionJson(String android, {String ios = 'a.ipa'}) => {
    'version': '1.2.3',
    'buildNumber': 2100,
    'android': android,
    'ios': ios,
  };

  group('AppRelease.tryParse — 파일 이름', () {
    test('CI 가 쓰는 이름은 받는다', () {
      final r = AppRelease.tryParse(versionJson('groo-desk-1.2.3.apk'));
      expect(r?.androidFile, 'groo-desk-1.2.3.apk');
      expect(r?.iosFile, 'a.ipa');
    });

    for (final bad in [
      '../shared_prefs/x.apk',
      '../../files/flutter_assets.apk',
      'sub/dir.apk',
      '/data/data/x.apk',
      r'..\x.apk',
      '..apk',
      'a..b.apk',
      '.hidden.apk',
      'groo-desk.exe',
      'groo-desk.apk.txt',
      'groo desk.apk',
      '',
    ]) {
      test('"$bad" 이면 버전 파일째 믿지 않는다', () {
        expect(AppRelease.tryParse(versionJson(bad)), isNull);
        expect(AppRelease.isSafeApkName(bad), isFalse);
      });
    }

    test('너무 긴 이름은 거절한다', () {
      expect(AppRelease.isSafeApkName('${'a' * 124}.apk'), isTrue);
      expect(AppRelease.isSafeApkName('${'a' * 125}.apk'), isFalse);
    });

    test('iOS 파일 이름이 이상하면 비워 둔다 — 안드로이드 쪽은 그대로 쓴다', () {
      final r = AppRelease.tryParse(
        versionJson('groo-desk-1.2.3.apk', ios: '../x.ipa'),
      );
      expect(r, isNotNull);
      expect(r!.iosFile, '');
    });
  });

  group('ApkVerifier — 네이티브 판정 읽기', () {
    const channel = MethodChannel('porest/app_update');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('verifyApk 에 경로를 넘기고 판정을 읽는다', () async {
      final calls = <MethodCall>[];
      for (final (raw, want) in [
        ('ok', ApkVerdict.ok),
        ('packageMismatch', ApkVerdict.packageMismatch),
        ('signatureMismatch', ApkVerdict.signatureMismatch),
        ('unreadable', ApkVerdict.unreadable),
        ('???', ApkVerdict.unreadable),
      ]) {
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return raw;
        });
        expect(await const ApkVerifier().verify('/c/a.apk'), want);
      }
      expect(calls.first.method, 'verifyApk');
      expect(calls.first.arguments, {'path': '/c/a.apk'});
    });

    test('채널이 없거나 실패하면 통과시키지 않는다', () async {
      expect(
        await const ApkVerifier().verify('/c/a.apk'),
        ApkVerdict.unreadable,
      );
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom');
      });
      expect(
        await const ApkVerifier().verify('/c/a.apk'),
        ApkVerdict.unreadable,
      );
    });
  });

  group('ApkInstaller — 대조가 통과해야 설치 화면을 연다', () {
    late Directory cache;
    late _FakeIo io;

    setUp(() {
      cache = Directory.systemTemp.createTempSync('apk_verify_test');
      io = _FakeIo(cache.path);
    });
    tearDown(() => cache.deleteSync(recursive: true));

    ProviderContainer container(ApkVerdict verdict) {
      final c = ProviderContainer(
        overrides: [
          apkIoProvider.overrideWithValue(io),
          apkVerifierProvider.overrideWithValue(_FakeVerifier(verdict)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    AppRelease release(String file) => AppRelease(
      version: '1.2.3',
      buildNumber: 2100,
      androidFile: file,
      iosFile: '',
      notes: '',
      minBuildNumber: 0,
    );

    test('같은 앱이면 설치 화면을 연다', () async {
      final c = container(ApkVerdict.ok);
      final result = await c
          .read(apkInstallerProvider.notifier)
          .downloadAndOpen(release('groo-desk-1.2.3.apk'));
      expect(result, ApkInstallResult.opened);
      expect(io.opened, ['${cache.path}/groo-desk-1.2.3.apk']);
    });

    for (final verdict in [
      ApkVerdict.packageMismatch,
      ApkVerdict.signatureMismatch,
      ApkVerdict.unreadable,
    ]) {
      test('$verdict 이면 설치 화면을 열지 않고 받은 파일을 지운다', () async {
        final c = container(verdict);
        final result = await c
            .read(apkInstallerProvider.notifier)
            .downloadAndOpen(release('groo-desk-1.2.3.apk'));
        expect(result, ApkInstallResult.rejected);
        expect(c.read(apkInstallerProvider).stage, ApkStage.rejected);
        expect(io.opened, isEmpty);
        expect(File('${cache.path}/groo-desk-1.2.3.apk').existsSync(), isFalse);
      });
    }

    test('경로를 조작하는 이름은 받지도 않는다', () async {
      final c = container(ApkVerdict.ok);
      final result = await c
          .read(apkInstallerProvider.notifier)
          .downloadAndOpen(release('../evil.apk'));
      expect(result, ApkInstallResult.rejected);
      expect(io.downloaded, isEmpty);
      expect(io.opened, isEmpty);
    });
  });

  test('거절 안내는 ko · en 모두 있고 한 문장이다', () {
    for (final s in [
      AppLocalizationsKo().updateApkRejected,
      AppLocalizationsEn().updateApkRejected,
    ]) {
      expect(s, isNotEmpty);
      expect('.'.allMatches(s).length, 1);
      expect(s.endsWith('.'), isTrue);
    }
  });

  test('두 업데이트 화면 모두 거절이면 브라우저로 넘기지 않고 알린다', () {
    for (final f in [
      'lib/features/update/presentation/update_gate_screen.dart',
      'lib/features/settings/presentation/update_screen.dart',
    ]) {
      final src = File(f).readAsStringSync();
      final rejected = src.indexOf('result == ApkInstallResult.rejected');
      expect(rejected, greaterThan(0), reason: f);
      final block = src.substring(rejected, src.indexOf('return;', rejected));
      expect(block.contains('updateApkRejected'), isTrue, reason: f);
      expect(block.contains('openReleaseExternally'), isFalse, reason: f);
    }
  });
}

class _FakeVerifier extends ApkVerifier {
  _FakeVerifier(this.verdict);

  final ApkVerdict verdict;

  @override
  Future<ApkVerdict> verify(String path) async => verdict;
}

class _FakeIo extends ApkIo {
  _FakeIo(this.dir);

  final String dir;
  final downloaded = <String>[];
  final opened = <String>[];

  @override
  Future<String> cacheDir() async => dir;

  @override
  Future<void> download(
    String url,
    String path, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    downloaded.add(url);
    File(path).writeAsBytesSync([0x50, 0x4b, 0x03, 0x04]);
  }

  @override
  Future<bool> openInstaller(String path) async {
    opened.add(path);
    return true;
  }
}
