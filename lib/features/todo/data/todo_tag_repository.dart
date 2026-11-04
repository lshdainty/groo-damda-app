import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/features/todo/domain/todo_tag.dart';

class TodoTagRepository {
  TodoTagRepository(this._dio);
  final Dio _dio;

  /// 서버 원문을 띄우는 전역 오류 알림을 끈다 — 화면이 고정 글로 알린다(I-15 12 · 13 · 21: 저장 실패는 시트 안 Callout, 삭제 · 고정 실패는 스낵바 + 다시 시도).
  static final Options _silent = Options(extra: {kSilentErrorToast: true});

  Future<List<TodoTag>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/todo-tags',
        options: _silent,
      );
      return _unwrapList(res, 'tags', TodoTag.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TodoTag> create({required String tagName, String? color}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/todo-tag',
        options: _silent,
        data: {'tagName': tagName, 'color': ?color},
      );
      return _unwrap(res, TodoTag.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TodoTag> update({
    required int id,
    required String tagName,
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/todo-tag/$id',
        options: _silent,
        data: {'tagName': tagName, 'color': ?color},
      );
      return _unwrap(res, TodoTag.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/todo-tag/$id', options: _silent);
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
