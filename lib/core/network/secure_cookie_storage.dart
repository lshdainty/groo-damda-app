import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:groo_damda_app/core/storage/app_secure_storage.dart';

/// cookie_jar 의 [Storage] 구현 — 쿠키(desk_access_token 포함)를
/// 평문 파일 대신 OS 보안 저장소(Android Keystore 기반 EncryptedSharedPreferences /
/// iOS Keychain)에 암호화 저장한다.
///
/// 기존 FileStorage(`.cookies` 평문 JSON) 의 토큰 탈취 위험을 제거한다.
class SecureCookieStorage implements Storage {
  static const _prefix = 'pcj_'; // PersistCookieJar 키 네임스페이스

  static const FlutterSecureStorage _storage = appSecureStorage;

  /// 쓰는 저장소 — 옵션이 로그인 흐름 보관소와 같은지 시험이 본다.
  @visibleForTesting
  static FlutterSecureStorage get storage => _storage;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _storage.read(key: '$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: '$_prefix$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: '$_prefix$key');
    }
  }
}
