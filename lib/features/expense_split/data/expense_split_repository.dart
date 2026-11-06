import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';
import 'package:groo_damda_app/features/expense_split/domain/expense_split.dart';

/// `/expense/{id}/splits` GET/PUT/DELETE.
class ExpenseSplitRepository {
  ExpenseSplitRepository(this._dio);
  final Dio _dio;

  /// [silent] 면 전역 오류 스낵바를 끈다 — 화면이 자기 자리에서 고정 글로 알린다.
  static Options? _opts(bool silent) =>
      silent ? Options(extra: {kSilentErrorToast: true}) : null;

  Future<List<ExpenseSplit>> list(int expenseId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expense/$expenseId/splits',
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['splits'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<List<ExpenseSplit>> replace(
    int expenseId, {
    required List<SplitInput> splits,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense/$expenseId/splits',
        options: _opts(silent),
        data: {
          'splits': [
            for (final s in splits)
              {
                'rowId': ?s.rowId,
                'categoryRowId': s.categoryRowId,
                'amount': s.amount,
                'label': ?s.label,
                'sortOrder': ?s.sortOrder,
              },
          ],
        },
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['splits'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<void> deleteAll(int expenseId, {bool silent = false}) async {
    try {
      await _dio.delete<void>(
        '/expense/$expenseId/splits',
        options: _opts(silent),
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}

class SplitInput {
  const SplitInput({
    required this.categoryRowId,
    required this.amount,
    this.label,
    this.sortOrder,
    this.rowId,
  });

  /// 저장된 항목이면 그 rowId — 보내면 서버가 제자리 수정한다(없으면 새로 만들고 옛 행을 지운다).
  final int? rowId;
  final int categoryRowId;
  final int amount;
  final String? label;
  final int? sortOrder;
}
