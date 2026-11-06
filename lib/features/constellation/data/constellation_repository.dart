import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';

/// 별자리 게이미피케이션 조회 — 적립은 할일 완료/메모 작성의 부수효과라 별도 API 없음.
class ConstellationRepository {
  ConstellationRepository(this._dio);
  final Dio _dio;

  /// 오늘의 목표 별자리 + 내 별빛 현황. GET /constellations/today.
  Future<ConstellationToday> today() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/constellations/today');
      return _unwrap(res, ConstellationToday.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 나의 밤하늘 — 최근 [days]일 (무행일 REST 포함). GET /constellations/sky.
  Future<List<SkyDay>> sky({int days = 14}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/constellations/sky',
        queryParameters: {'days': days},
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['days'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => SkyDay.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 별자리 도감. GET /constellations/collection.
  Future<ConstellationCollectionData> collection() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/constellations/collection',
      );
      return _unwrap(res, ConstellationCollectionData.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  T _unwrap<T>(
    Response<Map<String, dynamic>> res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data ?? const {},
      (raw) => raw! as Map<String, dynamic>,
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    return fromJson(body.data!);
  }
}
