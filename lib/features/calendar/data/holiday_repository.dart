import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';

/// 공휴일 — front `holidayApi` 미러.
///
/// 공휴일은 백엔드 스케줄러가 한국천문연구원 특일정보 API 와 매일 동기화하므로 조회 전용이다.
class HolidayRepository {
  HolidayRepository(this._dio);
  final Dio _dio;

  /// 기간 내 공휴일 목록. GET /holidays?startDate&endDate.
  Future<List<Holiday>> list({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/holidays',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return _unwrapList(res, 'holidays', Holiday.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  List<T> _unwrapList<T>(
    Response<Map<String, dynamic>> res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data ?? const {},
      (raw) => raw! as Map<String, dynamic>,
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    final list = (body.data![listKey] as List<dynamic>?) ?? const [];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
