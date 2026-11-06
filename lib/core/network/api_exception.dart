import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 백엔드/네트워크 에러를 사용자 메시지로 변환할 수 있는 단일 형태.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.cause,
  });

  /// 백엔드 도메인 에러 코드 (예: `AUTH_001`, `EXPENSE_404`) 또는 클라이언트 자체 코드.
  final String code;

  /// 사용자에게 표시 가능한 메시지 (백엔드 message 또는 fallback).
  final String message;

  final int? statusCode;
  final Object? cause;

  bool get isUnauthorized => statusCode == 401 || code == 'AUTH_001';
  bool get isForbidden => statusCode == 403 || code == 'AUTH_003';

  /// desk 이용을 해지한 계정으로 들어오려 한 것인가.
  ///
  /// desk-back `TokenExchangeService` 가 해지자의 토큰 교환을 이 코드로 끊는다.
  /// 이걸 못 알아보면 로그인 화면이 보통의 실패로 보고 원문을 그대로 띄우는데,
  /// 사용자는 왜 안 되는지 모른 채 다시 눌러 보게 된다.
  ///
  /// 문구가 아니라 **코드로** 본다 — 문구는 로케일마다 다르고 서버가 고치면 따라 바뀐다.
  bool get isWithdrawn => code == 'USER_021';

  /// DioException 을 ApiException 으로 정규화.
  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res != null) {
      final body = res.data;
      if (body is Map<String, dynamic>) {
        // 정상 에러는 서버가 로케일(ko/en) 메시지를 body.message 로 내려주므로 그대로 사용.
        // 아래 fallback 은 서버가 message 를 안 준 예외적 경우만 → 로케일 문구(코드는 code 에만, 03F-011a).
        return ApiException(
          code: body['code']?.toString() ?? 'HTTP_${res.statusCode}',
          message: body['message']?.toString() ?? _l().apiErrorServer,
          statusCode: res.statusCode,
          cause: e,
        );
      }
      // non-JSON 응답(게이트웨이 502 등) — 서버 메시지 없음. 코드 값은 message 에 섞지 않는다.
      return ApiException(
        code: 'HTTP_${res.statusCode}',
        message: _l().apiErrorServer,
        statusCode: res.statusCode,
        cause: e,
      );
    }
    // 네트워크 무응답 — 서버 응답 자체가 없어 서버 메시지 불가, 로케일 문구.
    return ApiException(
      code: 'NETWORK',
      message: _l().apiErrorNetwork,
      cause: e,
    );
  }

  /// 응답을 읽지 못했다 — 형식이 다른 본문(`fromJson` 의 형 변환 · 날짜 · 숫자 풀기 실패). 서버는 받았을 수 있다.
  /// 화면 글은 고정 글([apiErrorServer] — 원문을 내지 않는다), 원문은 로그에만 남긴다.
  factory ApiException.parse(Object error, StackTrace stack) {
    debugPrint('ApiException.parse — 응답을 읽지 못했다: $error\n$stack');
    return ApiException(
      code: kApiParseErrorCode,
      message: _l().apiErrorServer,
      cause: error,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}

/// 응답 형식 오류의 코드 — [ApiException.parse].
const String kApiParseErrorCode = 'PARSE';

/// 저장소 공용 — 요청 · 응답 풀기에서 난 오류를 [ApiException] 하나로 올린다(저장소마다 `catch (e, s)` 에서 부른다).
///
/// - [DioException] → [ApiException.fromDio]
/// - 응답 형식 오류([TypeError] · [FormatException]) → [ApiException.parse] — 저장 폼의 `on ApiException` 이 맨 위 Callout 으로,
///   불러오기는 실패 갈래로 받는다. 예전에는 아무도 잡지 않아 zone 으로 빠졌다(I-wrap-b2b 3)
/// - 그 밖(이미 [ApiException] 인 것 · 다른 오류)은 그대로 다시 던진다(스택 유지)
Never throwAsApiException(Object error, StackTrace stack) {
  if (error is DioException) throw ApiException.fromDio(error);
  if (error is TypeError || error is FormatException) {
    throw ApiException.parse(error, stack);
  }
  Error.throwWithStackTrace(error, stack);
}

/// 지금 로케일의 문구 — 컨텍스트가 없는 곳이라 앱 로케일 설정으로 고른다(영어를 고른 경우만 en, 아니면 ko).
AppLocalizations _l() =>
    lookupAppLocalizations(Locale(localeIsEn() ? 'en' : 'ko'));
