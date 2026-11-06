import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';

/// 알림음 옵션 — 백엔드 enum 미러.
class NotificationSound {
  static const chime = 'CHIME';
  static const defaultSound = 'DEFAULT';
  static const none = 'NONE';
}

/// 이메일 발송 주기 — 백엔드 enum 미러.
class EmailFrequency {
  static const daily = 'DAILY';
  static const weekly = 'WEEKLY';
  static const monthly = 'MONTHLY';
}

/// 사용자 알림/환경설정 전체 모델 (GET/PATCH /users/me/preferences).
///
/// 백엔드 계약(camelCase) 전 필드를 그대로 담는다. PATCH 는 부분 업데이트라
/// [toPatch] 가 아닌, 변경 필드만 직접 Map 으로 보낸다([UserPreferencesRepository.update]).
class UserPreferences {
  const UserPreferences({
    required this.pushEnabled,
    required this.notifyPayment,
    required this.notifyBudget,
    required this.notifyAutoRecord,
    required this.notifyDutchPay,
    required this.notifyCalendar,
    required this.notifyWeeklyReport,
    required this.notifyMonthlyReport,
    required this.budgetAlertThreshold,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.notificationSound,
    required this.vibrationEnabled,
    required this.emailEnabled,
    required this.emailFrequency,
    required this.timezone,
    required this.defaultCurrency,
  });

  /// 마스터 토글.
  final bool pushEnabled;
  final bool notifyPayment;
  final bool notifyBudget;
  final bool notifyAutoRecord;
  final bool notifyDutchPay;
  final bool notifyCalendar;
  final bool notifyWeeklyReport;
  final bool notifyMonthlyReport;

  /// 예산 임계값 — 50~100.
  final int budgetAlertThreshold;

  final bool quietHoursEnabled;

  /// "HH:mm" 24h.
  final String quietHoursStart;

  /// "HH:mm" 24h.
  final String quietHoursEnd;

  /// CHIME | DEFAULT | NONE.
  final String notificationSound;
  final bool vibrationEnabled;
  final bool emailEnabled;

  /// DAILY | WEEKLY | MONTHLY.
  final String emailFrequency;

  /// 표시 기준 지역(IANA 타임존 ID). 서버가 이 값으로 "오늘"을 판단한다.
  final String timezone;

  /// 새 자산·거래가 처음 고르는 통화(KRW·USD·EUR·JPY) — desk-back #328.
  ///
  /// 종전엔 기기 `SharedPreferences` 에만 있었고 **읽는 곳이 하나도 없었다**
  /// (QA #124). 고르면 저장된 것처럼 보이는데 다른 기기에서도, 새 자산·거래
  /// 어디에서도 아무 일이 없었다. 지역 설정과 같은 자리로 옮겼다.
  final String defaultCurrency;

  /// 서버 응답 누락 필드는 합리적 기본값으로 보강 (방어적 디코딩).
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      notifyPayment: json['notifyPayment'] as bool? ?? true,
      notifyBudget: json['notifyBudget'] as bool? ?? true,
      notifyAutoRecord: json['notifyAutoRecord'] as bool? ?? true,
      notifyDutchPay: json['notifyDutchPay'] as bool? ?? true,
      notifyCalendar: json['notifyCalendar'] as bool? ?? true,
      notifyWeeklyReport: json['notifyWeeklyReport'] as bool? ?? false,
      notifyMonthlyReport: json['notifyMonthlyReport'] as bool? ?? false,
      budgetAlertThreshold:
          (json['budgetAlertThreshold'] as num?)?.toInt() ?? 85,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00',
      notificationSound:
          json['notificationSound'] as String? ??
          NotificationSound.defaultSound,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      emailFrequency:
          json['emailFrequency'] as String? ?? EmailFrequency.weekly,
      timezone: json['timezone'] as String? ?? 'Asia/Seoul',
      // 서버가 이 칸을 아직 안 실어 주면 원화로 본다 — 종전 동작과 같다.
      defaultCurrency: json['defaultCurrency'] as String? ?? kDefaultCurrency,
    );
  }

  UserPreferences copyWith({
    bool? pushEnabled,
    bool? notifyPayment,
    bool? notifyBudget,
    bool? notifyAutoRecord,
    bool? notifyDutchPay,
    bool? notifyCalendar,
    bool? notifyWeeklyReport,
    bool? notifyMonthlyReport,
    int? budgetAlertThreshold,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? notificationSound,
    bool? vibrationEnabled,
    bool? emailEnabled,
    String? emailFrequency,
    String? timezone,
    String? defaultCurrency,
  }) {
    return UserPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      notifyPayment: notifyPayment ?? this.notifyPayment,
      notifyBudget: notifyBudget ?? this.notifyBudget,
      notifyAutoRecord: notifyAutoRecord ?? this.notifyAutoRecord,
      notifyDutchPay: notifyDutchPay ?? this.notifyDutchPay,
      notifyCalendar: notifyCalendar ?? this.notifyCalendar,
      notifyWeeklyReport: notifyWeeklyReport ?? this.notifyWeeklyReport,
      notifyMonthlyReport: notifyMonthlyReport ?? this.notifyMonthlyReport,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      notificationSound: notificationSound ?? this.notificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      emailFrequency: emailFrequency ?? this.emailFrequency,
      timezone: timezone ?? this.timezone,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    );
  }
}

/// 사용자 환경설정 GET/PATCH 어댑터.
///
/// [AuthRepository.getBudgetAlertThreshold]/[updateBudgetAlertThreshold] 와 동일한
/// `/users/me/preferences` 엔드포인트를 쓰되, 전 필드를 다룬다.
/// PATCH 는 부분 업데이트 — 변경 필드만 [update] 의 `fields` 로 전달한다.
class UserPreferencesRepository {
  UserPreferencesRepository(this._dio);
  final Dio _dio;

  /// 전체 환경설정 조회. GET /users/me/preferences.
  Future<UserPreferences> get() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me/preferences');
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return UserPreferences.fromJson(body.data!);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 부분 갱신. PATCH /users/me/preferences. [fields] 의 키만 전송한다.
  /// 응답 전체 환경설정을 반환.
  ///
  /// [silent] 면 실패를 전역 오류 알림으로 띄우지 않는다 — 화면이 고정 글로 알릴 때만(표시 설정). 기본은 전역 알림을 유지한다
  /// (알림 설정 화면은 결과를 따로 알리지 않는다).
  Future<UserPreferences> update(
    Map<String, dynamic> fields, {
    bool silent = false,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/me/preferences',
        data: fields,
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return UserPreferences.fromJson(body.data!);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}
