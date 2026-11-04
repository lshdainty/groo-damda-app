import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';

class DutchPayRepository {
  DutchPayRepository(this._dio);
  final Dio _dio;

  Future<List<DutchPay>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dutch-pays');
      return _unwrapList(res, 'dutchPays', DutchPay.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<DutchPay> create({
    required String title,
    String? description,
    required int totalAmount,
    String? splitMethod,
    String? dutchPayDate, // YYYY-MM-DD
    int? sourceExpenseRowId,
    required List<({String? name, int? userRowId, int amount, bool isPayer})>
    participants,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/dutch-pay',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
        data: {
          'title': title,
          'description': ?description,
          'totalAmount': totalAmount,
          'splitMethod': splitMethod ?? 'EQUAL',
          'dutchPayDate': ?dutchPayDate,
          'sourceExpenseRowId': ?sourceExpenseRowId,
          'participants': [
            for (final p in participants)
              {
                'participantName': ?p.name,
                'userRowId': ?p.userRowId,
                // 결제자는 순서와 무관하다 — 서버가 저장하고, 화면은 추측하지 않는다.
                'isPayer': p.isPayer,
                'amount': p.amount,
              },
          ],
        },
      );
      return _unwrap(res, DutchPay.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markPaid(int dutchPayId, int participantId) async {
    try {
      await _dio.patch<dynamic>(
        '/dutch-pay/$dutchPayId/participant/$participantId/paid',
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> settle(int id) async {
    try {
      await _dio.patch<dynamic>('/dutch-pay/$id/settle');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/dutch-pay/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
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
