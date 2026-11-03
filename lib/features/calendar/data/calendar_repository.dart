import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';

/// 일정 종류 기본값. 앱에는 종류를 고르는 자리가 없어 웹과 같은 값을 쓴다
/// (웹 `EventForm` 도 신규 일정에 `PERSONAL` 을 고정으로 싣는다).
const kDefaultCalendarEventType = 'PERSONAL';

/// 저장 요청에 실을 일정 종류를 정한다.
///
/// 서버 enum(`CalendarEventType`)은 `PERSONAL`·`WORK`·`BIRTHDAY`·`HOLIDAY` 넷뿐이다.
/// 여기 없는 값을 실으면 본문을 읽는 단계에서 걸려 저장이 400 으로 끝나고, 키를 아예
/// 빼면 `event_type` 이 비어 저장이 깨진다 — 어느 쪽도 일정이 저장되지 않는다.
/// 그래서 **항상 값을 싣되, 비어 있을 때만** 기본값으로 채운다.
///
/// 아는 값 목록으로 걸러내지는 않는다. 서버가 종류를 늘렸을 때, 그 값을 모르는 옛 앱이
/// 수정 저장 한 번으로 사용자가 고른 종류를 기본값으로 되돌리면 안 된다.
String eventTypeOrDefault(String? eventType) {
  final trimmed = eventType?.trim();
  return (trimmed == null || trimmed.isEmpty)
      ? kDefaultCalendarEventType
      : trimmed;
}

class CalendarRepository {
  CalendarRepository(this._dio);
  final Dio _dio;

  /// 일정 쓰기(추가 · 수정 · 삭제)는 전역 오류 스낵바를 끈다 — 시트 · 폼이 자기 자리의 Callout 으로 알린다(스낵바는 시트 뒤 화면에 떠서 가려진다).
  static final Options _silent = Options(extra: {kSilentErrorToast: true});

  // ─── Events ────────────────────────────────────

  Future<List<CalendarEvent>> events({
    required String startDate, // ISO LocalDateTime
    required String endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/calendar/events',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return _unwrapList(res, 'events', CalendarEvent.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    int? labelRowId,
    String? location,
    // 반복 규칙(RFC 5545 RRULE 본문) — 'FREQ=WEEKLY' 처럼 화면 칩이 고른 값.
    String? rrule,
    // 알림 사전분 목록. 생성은 '안 보냄 = 알림 없음' 이라 빈 목록과 뜻이 같다.
    List<int>? reminderMinutes,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/calendar/event',
        options: _silent,
        data: {
          'title': title,
          'description': ?description,
          'eventType': eventTypeOrDefault(eventType),
          'color': ?color,
          'calendarRowId': ?calendarRowId,
          'startDate': startDate,
          'endDate': endDate,
          'isAllDay': isAllDay ? 'Y' : 'N',
          'labelRowId': ?labelRowId,
          'location': ?location,
          'rrule': ?rrule,
          'reminderMinutes': ?reminderMinutes,
        },
      );
      return _unwrap(res, CalendarEvent.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 수정 — 일정 시트가 소유한 칸만 키를 싣는다(QA #99 의 계약을 캘린더로 넓힌다).
  ///
  /// 서버는 수정 본문의 [description]·[color]·[labelRowId]·[location]·[rrule] 을
  /// `Optional` 로 읽는다(desk-back #325) — 키가 없으면 유지, 명시적 null 이면 지움.
  /// 그래서 시트에서 **비울 수 있는** 칸은 [Patch] 로 받는다: 설명·장소는 입력을 지울 수
  /// 있고, 라벨에는 '라벨 없음' 이 있다. 키를 빼면 셋 다 비우고 저장해도 옛 값이 남는다.
  ///
  /// [color] 는 [Patch] 가 아니다 — 색 선택기는 늘 값을 들고 있어(기본값이 있다) 비는
  /// 상태 자체가 없다. [eventType] 도 마찬가지로 `eventTypeOrDefault` 가 늘 채운다.
  ///
  /// [calendarRowId] 도 [Patch] 가 아니다. 서버 `UpdateRequest` 의 이 칸은 `Optional` 이
  /// 아닌 맨 `Long` 이고 서비스가 `if (calendarRowId != null)` 로만 읽어 **"소속 캘린더를
  /// 뗀다" 라는 동작이 아예 없다**(일정은 늘 어느 캘린더엔가 속한다). 시트의 캘린더
  /// 선택기에도 '선택 안 함' 이 없어 null 이 될 수 없다 — 키를 빼는 지금이 맞다.
  ///
  /// [reminderMinutes] 는 [Patch] 로 옮기지 않는다 — "null=무변경 / 리스트=전체 교체" 라는
  /// 뜻이 이미 확정돼 있고(빈 리스트가 "전부 지움"), 거래 `splits`·자산 `holdings` 와 같다.
  Future<CalendarEvent> updateEvent({
    required int id,
    required String title,
    Patch<String> description = const Patch.keep(),
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    Patch<int> labelRowId = const Patch.keep(),
    Patch<String> location = const Patch.keep(),
    // 반복 규칙 — 이 화면이 소유한 칸이라 [Patch] 로 싣는다. 키를 빼면 서버가 지금
    // 값을 지키므로(2026-09-08 계약), 칩에서 '반복 없음' 을 골라도 반복이 안 풀린다.
    // 비우는 것까지 동작하게 하려면 명시적 null 을 실어야 한다.
    Patch<String> rrule = const Patch.keep(),
    // 알림 사전분 목록. 서버는 **null=무변경 / 리스트=전체 교체** 로 읽는다 —
    // 빈 리스트가 "전부 지움" 이다. 화면이 기존 알림을 읽어 채운 뒤에만 실어야 한다.
    List<int>? reminderMinutes,
    // 반복 일정에서 연 회차의 원래 시작 — 목록 응답이 그 회차에 준 startDate 그대로.
    // 수정은 반복 전체에 적용되는데 시트는 연 회차의 날짜로 채워진다. 이 값이 없으면
    // 서버가 시트의 날짜를 반복의 새 시작으로 써서, 뒤 회차를 열어 저장만 해도 앞
    // 회차들이 사라졌다(QA 30 2). 실으면 그 회차에서 바뀐 만큼만 반복 전체가 옮겨진다.
    String? occurrenceStartDate,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/calendar/event/$id',
        options: _silent,
        data: {
          'title': title,
          if (description.present) 'description': description.value,
          'eventType': eventTypeOrDefault(eventType),
          'color': ?color,
          'calendarRowId': ?calendarRowId,
          'startDate': startDate,
          'endDate': endDate,
          'isAllDay': isAllDay ? 'Y' : 'N',
          if (labelRowId.present) 'labelRowId': labelRowId.value,
          if (location.present) 'location': location.value,
          if (rrule.present) 'rrule': rrule.value,
          'reminderMinutes': ?reminderMinutes,
          'occurrenceStartDate': ?occurrenceStartDate,
        },
      );
      return _unwrap(res, CalendarEvent.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      await _dio.delete<void>('/calendar/event/$id', options: _silent);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─── Labels ────────────────────────────────────

  Future<List<EventLabel>> labels() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/calendar/labels');
      return _unwrapList(res, 'labels', EventLabel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 라벨 생성. POST /calendar/label.
  Future<EventLabel> createLabel({
    required String labelName,
    String? color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/calendar/label',
        data: {'labelName': labelName, 'color': ?color},
      );
      return _unwrap(res, EventLabel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 라벨 수정. PUT /calendar/label/{id}.
  Future<EventLabel> updateLabel({
    required int id,
    required String labelName,
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/calendar/label/$id',
        data: {'labelName': labelName, 'color': ?color},
      );
      return _unwrap(res, EventLabel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 라벨 삭제. DELETE /calendar/label/{id}.
  Future<void> deleteLabel(int id) async {
    try {
      await _dio.delete<void>('/calendar/label/$id');
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
