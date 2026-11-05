import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/core/auth/user.dart';

/// 인증 관련 Desk 백엔드 호출을 모은 얇은 어댑터.
///
/// 모든 메서드는 성공 시 데이터 반환, 실패 시 [ApiException] throw.
/// 쿠키는 [Dio] 의 cookie_jar 가 자동으로 처리하므로 토큰을 직접 다루지 않는다.
class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  /// OAuth2 인가코드(PKCE)를 desk 토큰으로 교환. POST /auth/exchange-code.
  /// 인앱 WebView 가 가로챈 code+codeVerifier 를 BFF 로 교환한다.
  /// 성공 시 응답 쿠키(`desk_access_token`)가 cookie_jar 에 저장된다 — 사용자 정보는 [check] 로.
  ///
  /// 실패는 전역 오류 토스트에 싣지 않는다. 로그인 흐름이 자기 자리에 그린다 — 로그인
  /// 화면의 에러 줄(`loginErrorMessage`), 해지한 계정(USER_021)이면 해지 완료 화면.
  /// 토스트까지 뜨면 겹친다(QA 28 1 — 해지 완료 화면 위에 빨간 토스트).
  Future<void> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/exchange-code',
        data: {
          'code': code,
          'codeVerifier': codeVerifier,
          'redirectUri': redirectUri,
        },
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 현재 세션 유효성 확인. 성공 시 사용자 정보, 실패 시 401 throw.
  Future<User> check() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/check');
      final body = ApiResponse<User>.fromJson(
        res.data ?? const {},
        (raw) => User.fromJson(raw! as Map<String, dynamic>),
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 로그아웃. 백엔드가 쿠키 만료 처리, 클라이언트는 cookie_jar 도 비운다(상위에서).
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 현재 사용자 비밀번호 검증. 일치하면 정상 반환, 불일치 시 [ApiException] throw.
  Future<void> verifyPassword(String password) async {
    try {
      await _dio.post<dynamic>(
        '/users/me/verify-password',
        data: {'password': password},
        // 실패 글은 화면이 코드로 가른 고정 글로 알린다 — 그루 계정이 쓴 글이 전역 알림으로 닿지 않게(I-14 43)
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 비밀번호 변경. PATCH /users/me/password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/users/me/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        // 실패 글은 화면이 코드로 가른 고정 글로 알린다 — 그루 계정이 쓴 글이 전역 알림으로 닿지 않게(I-14 16)
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 사용자 환경설정 조회. GET /users/me/preferences.
  /// 응답: `{ budgetAlertThreshold: int }` (예: 80 = 80%).
  Future<int?> getBudgetAlertThreshold() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me/preferences');
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data!['budgetAlertThreshold'] as num?)?.toInt();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 사용자 환경설정 갱신. PATCH /users/me/preferences.
  Future<int?> updateBudgetAlertThreshold(int threshold) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/me/preferences',
        data: {'budgetAlertThreshold': threshold},
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data!['budgetAlertThreshold'] as num?)?.toInt();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
