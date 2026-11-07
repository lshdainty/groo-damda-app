import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';

class NotificationRepository {
  NotificationRepository(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> list({bool? unread, int? limit}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'unread': ?unread, 'limit': ?limit},
      );
      return _unwrapList(res, 'notifications', AppNotification.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data!['count'] as int?) ?? 0;
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<void> markRead(int id) async {
    try {
      // 읽음 표시는 배경 동작 — 실패해도 토스트로 방해하지 않는다.
      await _dio.patch<dynamic>(
        '/notification/$id/read',
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<void> markAllRead() async {
    try {
      // 실패는 화면이 고정 글 + [다시 시도] 로 알린다 — 서버 원문이 화면에 닿지 않게 silent 표식을 싣는다
      await _dio.patch<dynamic>(
        '/notifications/read-all',
        options: Options(extra: {kSilentErrorToast: true}),
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<void> delete(int id) async {
    try {
      // 오류 알림은 화면이 확인창을 열어 둔 채 띄운다 — silent 표식을 싣는다
      await _dio.delete<void>(
        '/notification/$id',
        options: Options(extra: {kSilentErrorToast: true}),
      );
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
