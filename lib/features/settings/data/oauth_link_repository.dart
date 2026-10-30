import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';

/// 서버가 준 소셜 연동 상태 한 줄 — 연결할 수 있는 소셜은 Google 하나다(I-14 10).
class OAuthProviderInfo {
  const OAuthProviderInfo({
    required this.type,
    required this.name,
    required this.linked,
  });

  /// 대문자 provider 타입 — "GOOGLE".
  final String type;
  final String name;

  /// 지금 계정과 연동돼 있는가.
  final bool linked;

  factory OAuthProviderInfo.fromJson(Map<String, dynamic> json) =>
      OAuthProviderInfo(
        type: json['type'] as String? ?? '',
        name: json['name'] as String? ?? '',
        linked: json['linked'] as bool? ?? false,
      );
}

/// 소셜 계정 연동 — 웹 `oauthLinkApi.ts` 와 같은 세 길(I-14 10).
///
/// desk 백엔드가 그루 계정에서 연동 티켓을 받아 `startUrl` 을 돌려주고, 브라우저가 거기로 가
/// 연동한 뒤 복귀 주소(`porestdesk://oauth/linked`)로 `?linked=` · `?linkError=` 를 달고 돌아온다.
///
/// **세 요청 모두 전역 오류 알림을 끈다** — 그루 계정이 쓴 글("Cannot unlink the only
/// authentication method" 같은 영어 · 합니다체)이 화면에 닿지 않게, 실패는 화면이 고정 글로 알린다.
class OAuthLinkRepository {
  OAuthLinkRepository(this._dio);
  final Dio _dio;

  static final _quiet = Options(extra: {kSilentErrorToast: true});

  /// 연동 상태 목록 — 서버는 GOOGLE · KAKAO · NAVER 셋을 주지만 화면은 GOOGLE 하나만 그린다.
  Future<List<OAuthProviderInfo>> providers() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/oauth/providers',
        options: _quiet,
      );
      final body = ApiResponse<List<dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as List<dynamic>?) ?? const [],
      );
      if (!body.success) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data ?? const [])
          .map((e) => OAuthProviderInfo.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 연동 시작 — 브라우저로 열 주소(`startUrl`)를 받는다.
  Future<String> startLink(String provider, String returnUrl) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/oauth/link/$provider',
        data: {'returnUrl': returnUrl},
        options: _quiet,
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as Map<String, dynamic>?) ?? const {},
      );
      final url = body.data?['startUrl'] as String?;
      if (!body.success || url == null || url.isEmpty) {
        throw ApiException(code: body.code, message: body.message);
      }
      return url;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 연동 해제. 유일한 로그인 수단이면 그루 계정이 거절한다 — 확인은 더하지 않는다.
  Future<void> unlink(String provider) async {
    try {
      await _dio.delete<void>('/oauth/link/$provider', options: _quiet);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
