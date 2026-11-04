import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';

class RecurringRepository {
  RecurringRepository(this._dio);
  final Dio _dio;

  /// [silent] 면 전역 오류 스낵바를 끈다 — 화면이 자기 자리에서 고정 글로 알린다(서버 글을 보이지 않고, 겹치지 않게).
  static Options? _opts(bool silent) =>
      silent ? Options(extra: {kSilentErrorToast: true}) : null;

  Future<List<RecurringTransaction>> list({bool? upcoming, int? limit}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/recurring-transactions',
        queryParameters: {'upcoming': ?upcoming, 'limit': ?limit},
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list =
          (body.data!['recurringTransactions'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 이체 반복은 [categoryRowId] 가 없고 [toAssetRowId] 가 있다 — 서버가 둘을 짝으로 본다
  /// (`RecurringTransferValidator`). 지출·수입에 이체 칸이 실려 가면 400 이다.
  Future<void> create({
    int? categoryRowId,
    int? assetRowId, // 자산 미연결 반복거래 허용 — 서버도 nullable
    /// 이체면 받는 자산.
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    int? sourceExpenseRowId,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek, // ISO 1=월 ~ 7=일
    int? dayOfMonth,
    String? executionTime, // 'HH:mm:ss'
    required String startDate, // 'YYYY-MM-DD'
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,

    /// 고정 수입·지출 — 이체에는 싣지 않는다(서버도 무시한다).
    bool isFixed = false,
    bool silent = false,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/recurring-transaction',
        options: _opts(silent),
        data: {
          'categoryRowId': ?categoryRowId,
          'assetRowId': assetRowId,
          'toAssetRowId': ?toAssetRowId,
          'fee': ?fee,
          'interestAmount': ?interestAmount,
          'sourceExpenseRowId': ?sourceExpenseRowId,
          'expenseType': expenseType,
          'amount': amount,
          'frequency': frequency,
          'intervalValue': ?intervalValue,
          'dayOfWeek': ?dayOfWeek,
          'dayOfMonth': ?dayOfMonth,
          'executionTime': ?executionTime,
          'startDate': startDate,
          'endDate': ?endDate,
          'maxOccurrences': ?maxOccurrences,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'autoLog': autoLog,
          'notifyDayBefore': notifyDayBefore,
          'isFixed': isFixed,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> update({
    required int id,
    int? categoryRowId,
    int? assetRowId, // 자산 미연결 반복거래 허용 — 서버도 nullable
    /// 이체면 받는 자산. 안 실으면 서버가 지운다(이 화면의 PUT 은 전체 치환이다).
    int? toAssetRowId,

    /// 거래에서 만든 반복이면 그 거래 — PUT 은 빠진 키를 지우므로 연결을 지키려면 싣는다.
    int? sourceExpenseRowId,
    int? fee,
    int? interestAmount,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    String? executionTime, // 'HH:mm:ss'
    required String startDate,
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,

    /// 고정 수입·지출 — 이체에는 싣지 않는다(서버도 무시한다).
    bool isFixed = false,
    bool silent = false,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/recurring-transaction/$id',
        options: _opts(silent),
        data: {
          'categoryRowId': ?categoryRowId,
          'assetRowId': assetRowId,
          'sourceExpenseRowId': ?sourceExpenseRowId,
          'toAssetRowId': ?toAssetRowId,
          'fee': ?fee,
          'interestAmount': ?interestAmount,
          'expenseType': expenseType,
          'amount': amount,
          'frequency': frequency,
          'intervalValue': ?intervalValue,
          'dayOfWeek': ?dayOfWeek,
          'dayOfMonth': ?dayOfMonth,
          'executionTime': ?executionTime,
          'startDate': startDate,
          'endDate': ?endDate,
          'maxOccurrences': ?maxOccurrences,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'autoLog': autoLog,
          'notifyDayBefore': notifyDayBefore,
          'isFixed': isFixed,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id, {bool silent = false}) async {
    try {
      await _dio.delete<void>(
        '/recurring-transaction/$id',
        options: _opts(silent),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// isActive 토글 (PATCH).
  Future<void> toggle(int id, {bool silent = false}) async {
    try {
      await _dio.patch<dynamic>(
        '/recurring-transaction/$id/toggle',
        options: _opts(silent),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
