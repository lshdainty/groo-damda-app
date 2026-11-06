import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/domain/budget_compliance.dart';

class BudgetRepository {
  BudgetRepository(this._dio);
  final Dio _dio;

  static Options? _opts(bool silent) =>
      silent ? Options(extra: {kSilentErrorToast: true}) : null;

  Future<List<Budget>> list({int? year, int? month}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expense/budgets',
        queryParameters: {'year': ?year, 'month': ?month},
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['budgets'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// [silent] 면 전역 오류 토스트를 띄우지 않는다 — 호출한 화면이 자기 스낵바("…하지 못했어요 + 다시 시도")로
  /// 알릴 때 쓴다(옛 토스트와 새 띠가 같은 아래쪽에서 겹치지 않게).
  ///
  /// 만든 예산의 rowId 를 돌려준다(응답에 없으면 null) — 지난달 복사의 "되돌리기"가 방금 만든 것만 지운다.
  Future<int?> create({
    int? categoryRowId,
    required int budgetAmount,
    required int budgetYear,
    required int budgetMonth,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        '/expense/budget',
        data: {
          // null 이면 '월 전체 상한' 으로 백엔드 처리 (web 동일).
          'categoryRowId': ?categoryRowId,
          'budgetAmount': budgetAmount,
          'budgetYear': budgetYear,
          'budgetMonth': budgetMonth,
        },
        options: _opts(silent),
      );
      final body = res.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      final id = data is Map<String, dynamic> ? data['rowId'] : null;
      return id is num ? id.toInt() : null;
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<void> update({
    required int id,
    required int budgetAmount,
    bool silent = false,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/expense/budget/$id',
        data: {'budgetAmount': budgetAmount},
        options: _opts(silent),
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<void> delete(int id, {bool silent = false}) async {
    try {
      await _dio.delete<void>('/expense/budget/$id', options: _opts(silent));
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// N개월 예산 준수율. GET /expense/budgets/compliance?months=N (기본 6).
  Future<List<BudgetComplianceMonth>> compliance({int months = 6}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expense/budgets/compliance',
        queryParameters: {'months': months},
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['months'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => BudgetComplianceMonth.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}
