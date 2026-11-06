import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/domain/stats_summaries.dart';

class StatsRepository {
  StatsRepository(this._dio);
  final Dio _dio;

  /// 임의 기간 요약. GET /expenses/summary/range?startDate&endDate.
  Future<RangeSummary> range({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/range',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return _unwrap(res, RangeSummary.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<List<MonthlyTrend>> trend({int months = 6}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/trend',
        queryParameters: {'months': months},
      );
      return _unwrapList(res, 'trends', MonthlyTrend.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<List<MerchantSummary>> byMerchant({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/by-merchant',
        queryParameters: {'startDate': ?startDate, 'endDate': ?endDate},
      );
      return _unwrapList(res, 'merchants', MerchantSummary.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<List<AssetExpenseSummary>> byAsset({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/by-asset',
        queryParameters: {'startDate': ?startDate, 'endDate': ?endDate},
      );
      return _unwrapList(res, 'assets', AssetExpenseSummary.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<List<HeatmapCell>> heatmap({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/heatmap',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return _unwrapList(res, 'cells', HeatmapCell.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 일별 요약. GET /expenses/summary/daily?date=YYYY-MM-DD.
  Future<DailySummary> daily(String date) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/daily',
        queryParameters: {'date': date},
      );
      return _unwrap(res, DailySummary.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  T _unwrap<T>(
    Response<Map<String, dynamic>> res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<T>.fromJson(
      res.data ?? const {},
      (raw) => fromJson(raw! as Map<String, dynamic>),
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    return body.data!;
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
