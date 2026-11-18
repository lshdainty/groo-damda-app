import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 앱이 쓰는 보안 저장소 — **옵션은 이 한 곳에서만 정한다.**
///
/// 같은 키 공간을 옵션이 다른 인스턴스로 읽으면 Android 에서 값이 비어 보인다. 예전 로그인 흐름 보관소
/// (`OAuthFlowStore`)가 기본 옵션을 쓰고 쿠키 저장소는 EncryptedSharedPreferences 를 써서, 브라우저에 가 있는
/// 동안 앱이 죽었다 다시 뜨면(콜드 스타트) 보관해 둔 verifier · state 를 못 읽어 로그인이 조용히 버려졌다
/// (`noPendingFlow`). 그래서 둘이 이 상수 하나를 같이 쓴다.
const FlutterSecureStorage appSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
