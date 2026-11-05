import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';

/// 사용자 다중 캘린더 — front `userCalendarApi` 미러.
class UserCalendarRepository {
  UserCalendarRepository(this._dio);

  static final Options _silent = Options(extra: {kSilentErrorToast: true});
  final Dio _dio;

  Future<List<UserCalendar>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/calendar/calendars');
      return _unwrapList(res, 'calendars', UserCalendar.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserCalendar> create({
    required String calendarName,
    String? color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/calendar/calendars',
        data: {'calendarName': calendarName, 'color': ?color},
      );
      return _unwrap(res, UserCalendar.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserCalendar> update({
    required int id,
    required String calendarName,
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/calendar/calendars/$id',
        data: {'calendarName': calendarName, 'color': ?color},
      );
      return _unwrap(res, UserCalendar.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserCalendar> toggleVisibility(int id) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/calendar/calendars/$id/visibility',
      );
      return _unwrap(res, UserCalendar.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/calendar/calendars/$id', options: _silent);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── 공유 ──

  Future<List<CalendarMember>> members(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/calendar/calendars/$id/members',
      );
      return _unwrapList(res, 'members', CalendarMember.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> regenerateInviteCode(int id) async {
    try {
      await _dio.patch<dynamic>(
        '/calendar/calendars/$id/regenerate-invite-code',
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserCalendar> joinByCode(String inviteCode) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/calendar/calendars/join',
        data: {'inviteCode': inviteCode},
      );
      return _unwrap(res, UserCalendar.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeMember(int id, int memberId) async {
    try {
      await _dio.delete<void>('/calendar/calendars/$id/member/$memberId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> changeMemberRole(int id, int memberId, String permission) async {
    try {
      await _dio.patch<dynamic>(
        '/calendar/calendars/$id/member/$memberId/role',
        data: {'permission': permission},
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
