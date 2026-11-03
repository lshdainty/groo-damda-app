import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';

class PresetRepository {
  PresetRepository(this._dio);
  final Dio _dio;

  Future<List<ExpenseTemplate>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/expense-templates');
      return _unwrapList(res, 'templates', ExpenseTemplate.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 이체 프리셋은 [categoryRowId] 가 없고 [toAssetRowId] 가 있다 — 서버가 둘을 짝으로
  /// 본다(`RecurringTransferValidator`). 지출·수입에 이체 칸이 실려 가면 400 이다.
  Future<ExpenseTemplate> create({
    required String templateName,
    int? categoryRowId,
    int? assetRowId,

    /// 이체면 받는 자산.
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    required String expenseType,
    int? amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? sortOrder,
    bool lockAmount = false,

    /// 고정 수입·지출 기본값 — 이체에는 싣지 않는다(서버도 무시한다).
    bool isFixed = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense-template',
        data: {
          'templateName': templateName,
          'categoryRowId': ?categoryRowId,
          'assetRowId': ?assetRowId,
          'toAssetRowId': ?toAssetRowId,
          'fee': ?fee,
          'interestAmount': ?interestAmount,
          'expenseType': expenseType,
          'amount': ?amount,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'sortOrder': ?sortOrder,
          'lockAmount': lockAmount ? 'Y' : 'N',
          'isFixed': isFixed,
        },
      );
      return _unwrap(res, ExpenseTemplate.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 수정 — 편집 시트가 소유한 칸만 키를 싣는다(QA #99 의 계약을 프리셋으로 넓힌다).
  ///
  /// 서버는 프리셋 수정 본문도 `Optional` 로 읽는다(desk-back #325) — 키가 없으면 유지,
  /// 명시적 null 이면 지움. 그래서 시트에서 **비울 수 있는** 칸은 [Patch] 로 받는다:
  /// [assetRowId]·[paymentMethod] 는 '선택 안 함' 이 있고 [merchant] 는 입력을 지울 수 있다.
  /// 키를 빼면 셋 다 화면에서 비우고 저장해도 옛 값이 그대로 남는다.
  ///
  /// [description] 도 [Patch] 다. 종전엔 편집 시트에 메모 칸이 아예 없어서 화면이
  /// 읽어 온 값을 그대로 되돌려 보냈는데(#326), 이제 시트에 칸이 생겼으므로(D2)
  /// **비운 상태 그대로 실어야 지워진다.**
  ///
  /// [categoryRowId] 는 폼이 필수로 강제한다(비면 저장 버튼이 안 눌린다) — 늘 값이 실린다.
  ///
  /// [amount] 는 [lockAmount] 가 정한다. 서버 `resolveAmount` 가 `lockAmount != 'Y'` 면
  /// 실린 금액과 상관없이 null 로 접으므로, 고정을 끄면 키가 빠져도 금액이 지워진다.
  /// 고정이 켜져 있으면 폼이 0 보다 큰 값을 강제하므로 키가 빠질 일이 없다.
  Future<ExpenseTemplate> update({
    required int id,
    required String templateName,

    /// 이 시트가 가진 칸이라 **늘 싣는다** — 이체로 바꿔 저장하면 명시적 null 로 옛 카테고리를 지운다. 서버는 키가 없으면 유지로
    /// 읽어(`ExpenseTemplateServiceImpl`) 옛 카테고리와 TRANSFER 가 짝이 안 맞아 400 이 된다.
    Patch<int> categoryRowId = const Patch.keep(),
    Patch<int> assetRowId = const Patch.keep(),

    /// 이체 칸도 이 시트의 칸이다 — 지출·수입으로 바꿔 저장하면 null 을 실어 지운다.
    Patch<int> toAssetRowId = const Patch.keep(),
    Patch<int> fee = const Patch.keep(),
    Patch<int> interestAmount = const Patch.keep(),
    required String expenseType,
    int? amount,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    bool lockAmount = false,

    /// 고정 수입·지출 기본값 — 이 시트가 그리는 칸이라 늘 싣는다. 이체는 호출처가 false 를 준다.
    bool isFixed = false,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense-template/$id',
        data: {
          'templateName': templateName,
          if (categoryRowId.present) 'categoryRowId': categoryRowId.value,
          if (assetRowId.present) 'assetRowId': assetRowId.value,
          if (toAssetRowId.present) 'toAssetRowId': toAssetRowId.value,
          if (fee.present) 'fee': fee.value,
          if (interestAmount.present) 'interestAmount': interestAmount.value,
          'expenseType': expenseType,
          'amount': ?amount,
          if (description.present) 'description': description.value,
          if (merchant.present) 'merchant': merchant.value,
          if (paymentMethod.present) 'paymentMethod': paymentMethod.value,
          'lockAmount': lockAmount ? 'Y' : 'N',
          'isFixed': isFixed,
        },
      );
      return _unwrap(res, ExpenseTemplate.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/expense-template/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 템플릿으로 거래 1건 즉시 생성.
  Future<void> use(int id, {required String expenseDate}) async {
    try {
      await _dio.post<dynamic>(
        '/expense-template/$id/use',
        data: {'expenseDate': expenseDate},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 프리셋을 불러왔지만 사용자가 폼을 수정해 일반 거래로 저장한 경우 호출.
  /// useCount/lastUsedAt 만 갱신.
  Future<void> touch(int id) async {
    try {
      // 사용 기록 갱신은 best-effort — 실패해도 사용자에게 알릴 일이 아니다.
      await _dio.post<dynamic>(
        '/expense-template/$id/touch',
        options: Options(extra: {kSilentErrorToast: true}),
      );
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
