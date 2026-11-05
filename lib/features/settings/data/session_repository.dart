import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';
import 'package:groo_damda_app/features/settings/domain/device_session.dart';

/// "로그인된 기기" — 본인 세션 조회·해지.
///
/// SSO 가 아니라 desk 백엔드를 부른다. desk 는 로그인할 때마다 자기 세션 테이블에
/// 한 행을 남기므로 그것만으로 목록이 나온다.
class SessionRepository {
  SessionRepository(this._dio);
  final Dio _dio;

  /// 살아 있는 기기 목록. 최근 사용 순으로 온다(서버가 정렬).
  Future<List<DeviceSession>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me/sessions');
      // data 가 바로 배열이다 — 감싸는 키가 없다.
      final body = ApiResponse<List<dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as List<dynamic>?) ?? const [],
      );
      if (!body.success) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data ?? const [])
          .map((e) => DeviceSession.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 기기 하나 로그아웃.
  Future<void> revoke(String sessionId) async {
    try {
      // 실패 알림은 화면이 하나만 띄운다(I-12 31) — 전역 그물은 끈다
      await _dio.delete<void>(
        '/users/me/sessions/$sessionId',
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 모든 기기에서 로그아웃 — 지금 이 기기도 포함된다.
  Future<void> revokeAll() async {
    try {
      await _dio.delete<void>(
        '/users/me/sessions',
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
