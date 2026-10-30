import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';

/// `/expenses`, `/expense/categories`, `/expense` 호출.
class ExpenseRepository {
  ExpenseRepository(this._dio);
  final Dio _dio;

  /// 실패 알림을 전역 스낵바로 띄우지 않는 요청(시트 안에서 따로 말하는 자리).
  static Options? _quiet(bool silent) =>
      silent ? Options(extra: {kSilentErrorToast: true}) : null;

  // ─────────────────────────────────────────────
  // Expense
  // ─────────────────────────────────────────────

  Future<List<Expense>> list({
    String? startDate, // 'YYYY-MM-DD'
    String? endDate,
    int? categoryId,
    int? assetId,
    String? expenseType,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses',
        queryParameters: {
          'startDate': ?startDate,
          'endDate': ?endDate,
          'categoryId': ?categoryId,
          'assetId': ?assetId,
          'expenseType': ?expenseType,
        },
      );
      return _unwrapList(res, 'expenses', Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Expense> create({
    required int categoryRowId,
    int? assetRowId, // 자산 미연결 거래 허용 — 서버도 nullable
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,

    /// 고정 수입·지출 — 안 실으면 서버가 변동으로 만든다. 이체에는 쓰지 않는다.
    bool? isFixed,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense',
        data: {
          'categoryRowId': categoryRowId,
          'assetRowId': assetRowId,
          'expenseType': expenseType,
          'amount': amount,
          'expenseDate': expenseDate,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'installmentMonths': ?installmentMonths,
          'originalAmount': ?originalAmount,
          'originalCurrency': ?originalCurrency,
          'exchangeRate': ?exchangeRate,
          'isFixed': ?isFixed,
        },
        options: _quiet(silent),
      );
      return _unwrap(res, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 수정 — 편집 시트가 소유한 칸만 키를 싣는다(QA #99).
  ///
  /// 시트에서 지울 수 있는 칸은 전부 [Patch] 다 — 자산 연결을 끊고, 설명·거래처를
  /// 비우고, 할부를 일시불로 되돌리고, 통화를 원화로 되돌려 외화 3종을 걷는 저장이
  /// 그대로 반영돼야 한다. 키를 빼면 서버가 옛 값을 지킨다.
  ///
  /// 환불 표식은 여기로 안 온다. 찍고 걷는 자리는 전용 경로 둘뿐이다([refund] ·
  /// [cancelRefund]) — 수정 본문에 폐기된 `refundOfExpenseRowId` 가 섞이면 서버가
  /// EXP_044 로 400 을 낸다. 환불된 거래는 아예 못 고친다(서버 EXP_043).
  ///
  /// [splits] 가 non-null 이면 금액과 함께 분할을 원자적으로 교체(PUT body 에 splits 포함).
  /// null 이면 분할 미변경(백엔드가 기존 분할 유지). 금액↔분할 합 일치화(reconcile) 저장에 사용.
  Future<Expense> update({
    required int id,
    required int categoryRowId,
    // 자산 미연결 거래 허용 — 서버도 nullable
    Patch<int> assetRowId = const Patch.keep(),
    required String expenseType,
    required int amount,
    required String expenseDate,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    Patch<int> installmentMonths = const Patch.keep(),
    Patch<double> originalAmount = const Patch.keep(),
    Patch<String> originalCurrency = const Patch.keep(),
    Patch<double> exchangeRate = const Patch.keep(),
    // 고정 수입·지출 — 안 실으면 서버가 지금 표식을 지킨다(옛 앱의 수정이 표식을 지우지 않는다).
    Patch<bool> isFixed = const Patch.keep(),
    List<SplitInput>? splits,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense/$id',
        data: {
          'categoryRowId': categoryRowId,
          if (assetRowId.present) 'assetRowId': assetRowId.value,
          'expenseType': expenseType,
          'amount': amount,
          'expenseDate': expenseDate,
          if (description.present) 'description': description.value,
          if (merchant.present) 'merchant': merchant.value,
          if (paymentMethod.present) 'paymentMethod': paymentMethod.value,
          if (installmentMonths.present)
            'installmentMonths': installmentMonths.value,
          if (originalAmount.present) 'originalAmount': originalAmount.value,
          if (originalCurrency.present)
            'originalCurrency': originalCurrency.value,
          if (exchangeRate.present) 'exchangeRate': exchangeRate.value,
          if (isFixed.present) 'isFixed': isFixed.value,
          if (splits != null)
            'splits': [
              for (final s in splits)
                {
                  'categoryRowId': s.categoryRowId,
                  'amount': s.amount,
                  'label': ?s.label,
                  'sortOrder': ?s.sortOrder,
                },
            ],
        },
        options: _quiet(silent),
      );
      return _unwrap(res, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 고쳐 쓰기 — 결제가 끝나 돈 칸이 잠긴 거래를 새 거래로 바꾼다
  /// (`POST /expense/{id}/replace`, D13).
  ///
  /// 본문은 [create] 와 같다. 서버가 한 트랜잭션에서 옛 거래를 지우고 새 거래를 만들며
  /// 분할·더치페이·반복 규칙·일정·할 일 연결을 새 거래로 옮긴다. 응답은 **새 거래**다
  /// (새 rowId) — 열린 회차에서 미리 낸 돈이 남으면 `refundedAmount` 가 실린다(D4).
  ///
  /// [splits] 가 null 이면 키를 안 싣는다 — 서버가 옛 분할을 옮긴다(합이 새 금액과
  /// 다르면 400). 리스트면 그것으로 새 분할을 만든다(시트가 적재·일치화한 값).
  Future<Expense> replace(
    int id, {
    required int categoryRowId,
    int? assetRowId,
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,

    /// 고정 수입·지출 — 안 실으면 서버가 옛 거래의 표식을 잇는다.
    bool? isFixed,
    List<SplitInput>? splits,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/$id/replace',
        data: {
          'categoryRowId': categoryRowId,
          'assetRowId': assetRowId,
          'expenseType': expenseType,
          'amount': amount,
          'expenseDate': expenseDate,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'installmentMonths': ?installmentMonths,
          'originalAmount': ?originalAmount,
          'originalCurrency': ?originalCurrency,
          'exchangeRate': ?exchangeRate,
          'isFixed': ?isFixed,
          if (splits != null)
            'splits': [
              for (final s in splits)
                {
                  'categoryRowId': s.categoryRowId,
                  'amount': s.amount,
                  'label': ?s.label,
                  'sortOrder': ?s.sortOrder,
                },
            ],
        },
        options: _quiet(silent),
      );
      return _unwrap(res, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 환불 표식을 찍는다 — 전용 경로다(`POST /expense/{id}/refund`).
  ///
  /// 수정 PUT 으로는 만들 수 없다. 환불은 원거래를 그 자리에서 합계에서 빼는 일이라
  /// "칸 하나 고치기" 와 무게가 다르다. 결제가 끝난 회차의 카드 거래는 통계에서만
  /// 빠지고(D1), 열린 회차에서 미리 낸 돈이 남으면 서버가 결제계좌로 돌려준다 —
  /// 그 금액이 응답의 `refundedAmount` 다(D3·D4).
  ///
  /// [refundedAt] 은 사용자가 고른 **환불일**이다(정오로 온다 — 자정이면 같은 날
  /// 앞서 찍힌 거래보다 과거가 되어 카드 회차 판정이 하루 밀린다). 거래일부터
  /// 오늘까지만 받는다(D16). 안 고르면 키를 안 싣고 서버가 제 시각으로 찍는다.
  ///
  /// [silent] 면 실패를 전역 스낵바로 띄우지 않는다 — 부르는 쪽이 시트 안(보이는 자리)에서 말한다(I-21 21-1).
  Future<Expense> refund(
    int id, {
    String? refundedAt,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/$id/refund',
        data: {'refundedAt': ?refundedAt},
        options: _quiet(silent),
      );
      return _unwrap(res, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 환불 표식을 걷는다(`DELETE /expense/{id}/refund`).
  ///
  /// 표식만 풀린다. 옛 환급 이체가 묶인 거래(`refundTransferRowId`)만 그 이체까지
  /// 되돌린다 — 통장에서 다시 빠진다.
  Future<Expense> cancelRefund(int id, {bool silent = false}) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/expense/$id/refund',
        options: _quiet(silent),
      );
      return _unwrap(res, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 지운다.
  ///
  /// 열린 회차에서 미리 낸 돈이 남아 결제계좌로 돌려줬다면 그 금액이 함께 온다
  /// (없으면 null, D3·D4). 옛 서버는 본문 없이 200 을 주므로 그때도 null 이다.
  Future<int?> delete(int id, {bool silent = false}) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/expense/$id',
        options: _quiet(silent),
      );
      final data = res.data?['data'];
      return data is Map<String, dynamic>
          ? data['refundedAmount'] as int?
          : null;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// /expenses/search — 키워드/카테고리/자산/기간/금액 범위 등 멀티 조건 검색.
  Future<List<Expense>> search({
    int? categoryId,
    int? assetId,
    String? expenseType,
    String? keyword,
    String? merchant,
    int? minAmount,
    int? maxAmount,
    String? startDate,
    String? endDate,

    /// true = 고정만, false = 변동만, null = 전부.
    bool? fixed,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/search',
        queryParameters: {
          'categoryId': ?categoryId,
          'assetId': ?assetId,
          'expenseType': ?expenseType,
          'keyword': ?keyword,
          'merchant': ?merchant,
          'minAmount': ?minAmount,
          'maxAmount': ?maxAmount,
          'startDate': ?startDate,
          'endDate': ?endDate,
          'fixed': ?fixed,
        },
      );
      return _unwrapList(res, 'expenses', Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 고정 표식 일괄 변경(`PUT /expenses/fixed`) — 고른 거래를 한꺼번에 고정/변동으로.
  ///
  /// 돈·잔액은 안 움직인다. 남의 거래가 섞이면 서버가 전체를 거절한다. 한 번에 500건까지.
  /// 실제로 바뀐 건수를 돌려준다(이미 그 값이던 거래는 세지 않는다).
  Future<int> bulkMarkFixed(
    List<int> expenseIds, {
    required bool isFixed,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expenses/fixed',
        data: {'expenseIds': expenseIds, 'isFixed': isFixed},
      );
      final data = res.data?['data'];
      return data is Map<String, dynamic>
          ? (data['updatedCount'] as num?)?.toInt() ?? 0
          : 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─────────────────────────────────────────────
  // ExpenseCategory
  // ─────────────────────────────────────────────

  Future<List<ExpenseCategory>> categories() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/expense/categories');
      return _unwrapList(res, 'categories', ExpenseCategory.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ExpenseCategory> createCategory({
    required String categoryName,
    String? icon,
    String? color,
    required String expenseType, // 'EXPENSE' | 'INCOME' | 'TRANSFER'
    int? parentRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/category',
        data: {
          'categoryName': categoryName,
          'icon': ?icon,
          'color': ?color,
          'expenseType': expenseType,
          'parentRowId': ?parentRowId,
        },
      );
      return _unwrap(res, ExpenseCategory.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ExpenseCategory> updateCategory({
    required int id,
    required String categoryName,
    String? icon,
    String? color,
    String? expenseType,
    int? sortOrder,
    // parentRowId 는 null 자체가 의미("최상위로 이동")라 ?-skip 불가 —
    // [includeParentRowId] 로 명시 전송 여부를 구분 (웹은 항상 포함 전송).
    bool includeParentRowId = false,
    int? parentRowId,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense/category/$id',
        data: {
          'categoryName': categoryName,
          'icon': ?icon,
          'color': ?color,
          'expenseType': ?expenseType,
          'sortOrder': ?sortOrder,
          if (includeParentRowId) 'parentRowId': parentRowId,
        },
      );
      return _unwrap(res, ExpenseCategory.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete<void>('/expense/category/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 카테고리에 달린 거래를 다른 카테고리로 일괄 이동.
  /// POST /expense/category/{id}/move-transactions
  ///
  /// 거래가 직접 달린 카테고리는 부모가 될 수 없어 하위를 만들 수 없는데, 그걸 푸는 방법.
  Future<int> moveCategoryTransactions(int id, int targetCategoryRowId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/category/$id/move-transactions',
        data: {'targetCategoryRowId': targetCategoryRowId},
      );
      return _movedCount(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 하위 카테고리를 만들면서 이 카테고리의 거래를 그리로 옮긴다.
  /// POST /expense/category/{id}/split-into-child
  ///
  /// 거래가 있어 하위를 못 만들고, 옮길 하위가 없어 거래도 못 옮기는 교착을 푼다.
  Future<int> splitCategoryIntoChild(
    int id, {
    required String childName,
    required String icon,
    required String color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/category/$id/split-into-child',
        data: {'childName': childName, 'icon': icon, 'color': color},
      );
      return _movedCount(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 이동 응답(거래·반복거래·분할)의 합계 — 사용자에겐 "몇 건 옮겼는지"만 보여준다.
  int _movedCount(Map<String, dynamic>? raw) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      raw ?? const {},
      (d) => (d as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final d = body.data ?? const <String, dynamic>{};
    return ((d['expenses'] as num?)?.toInt() ?? 0) +
        ((d['recurring'] as num?)?.toInt() ?? 0) +
        ((d['splits'] as num?)?.toInt() ?? 0);
  }

  /// 카테고리 정렬 순서 + 부모 변경. PATCH /expense/categories/reorder.
  /// [items] = (categoryRowId, sortOrder, parentRowId?) tuple 목록.
  Future<void> reorderCategories(
    List<({int categoryRowId, int sortOrder, int? parentRowId})> items,
  ) async {
    try {
      await _dio.patch<dynamic>(
        '/expense/categories/reorder',
        data: {
          'items': [
            for (final i in items)
              {
                'categoryRowId': i.categoryRowId,
                'sortOrder': i.sortOrder,
                'parentRowId': ?i.parentRowId,
              },
          ],
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

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
