import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/calendar/domain/event_comment.dart';

/// 캘린더 이벤트 코멘트 — front `eventCommentApi` 미러.
class EventCommentRepository {
  EventCommentRepository(this._dio);
  final Dio _dio;

  /// 이벤트의 코멘트 목록. GET /calendar/event/{eventId}/comments.
  Future<List<EventComment>> list(int eventId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/calendar/event/$eventId/comments',
      );
      return _unwrapList(res, 'comments', EventComment.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 코멘트 생성. POST /calendar/event/{eventId}/comment.
  Future<EventComment> create({
    required int eventId,
    required String content,
    int? parentRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/calendar/event/$eventId/comment',
        data: {'content': content, 'parentRowId': ?parentRowId},
      );
      return _unwrap(res, EventComment.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 코멘트 수정. PUT /calendar/comment/{commentId}.
  Future<EventComment> update({
    required int commentId,
    required String content,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/calendar/comment/$commentId',
        data: {'content': content},
      );
      return _unwrap(res, EventComment.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 코멘트 삭제. DELETE /calendar/comment/{commentId}.
  Future<void> delete(int commentId) async {
    try {
      await _dio.delete<void>('/calendar/comment/$commentId');
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
