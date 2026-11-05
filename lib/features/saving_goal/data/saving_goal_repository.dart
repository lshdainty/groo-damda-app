import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';

class SavingGoalRepository {
  SavingGoalRepository(this._dio);
  final Dio _dio;

  static Options? _quiet(bool silent) =>
      silent ? Options(extra: {kSilentErrorToast: true}) : null;

  Future<List<SavingGoal>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/saving-goals');
      return _unwrapList(res, 'goals', SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SavingGoal> create({
    required String title,
    String? description,
    required int targetAmount,
    String? deadlineDate,
    String? icon,
    String? color,
    int? linkedAssetRowId,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/saving-goal',
        data: {
          'title': title,
          'description': ?description,
          'targetAmount': targetAmount,
          'deadlineDate': ?deadlineDate,
          'icon': ?icon,
          'color': ?color,
          'linkedAssetRowId': ?linkedAssetRowId,
        },
        options: _quiet(silent),
      );
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 수정 — 편집 화면이 소유한 칸만 키를 싣는다(QA #99).
  ///
  /// [deadlineDate] 만 [Patch] 다. 목표일은 화면에서 지울 수 있어 명시적 null 을
  /// 실어야 서버가 지운다. 아이콘·색은 화면이 늘 값을 들고 있다(둘 다 기본값이 있다).
  ///
  /// [description] 과 [linkedAssetRowId] 는 **앱 편집 화면에 아예 없는 칸**이라
  /// 값이 없으면 키를 뺀다 — null 로 실으면 웹에서 적어 둔 설명과 연결한 자산이
  /// 앱으로 목표를 고칠 때마다 지워진다.
  Future<SavingGoal> update({
    required int id,
    required String title,
    String? description,
    required int targetAmount,
    Patch<String> deadlineDate = const Patch.keep(),
    String? icon,
    String? color,
    int? linkedAssetRowId,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/saving-goal/$id',
        data: {
          'title': title,
          'description': ?description,
          'targetAmount': targetAmount,
          if (deadlineDate.present) 'deadlineDate': deadlineDate.value,
          'icon': ?icon,
          'color': ?color,
          'linkedAssetRowId': ?linkedAssetRowId,
        },
        options: _quiet(silent),
      );
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SavingGoal> contribute(
    int id, {
    required int amount,
    String? note,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/saving-goal/$id/contribute',
        data: {'amount': amount, 'note': ?note},
        options: _quiet(silent),
      );
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// [silent] 면 전역 오류 토스트를 띄우지 않는다 — 화면이 자기 스낵바로 알린다.
  Future<void> delete(int id, {bool silent = false}) async {
    try {
      await _dio.delete<void>('/saving-goal/$id', options: _quiet(silent));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 단건 조회. GET /saving-goal/{id}.
  Future<SavingGoal> getById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/saving-goal/$id');
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 정렬 순서 변경. PATCH /saving-goals/reorder.
  Future<void> reorder(List<({int id, int sortOrder})> items) async {
    try {
      await _dio.patch<dynamic>(
        '/saving-goals/reorder',
        data: {
          'items': [
            for (final i in items) {'id': i.id, 'sortOrder': i.sortOrder},
          ],
        },
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
