import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/core/auth/auth_events.dart';
import 'package:groo_damda_app/core/network/interceptors/auth_interceptor.dart';
import 'package:groo_damda_app/core/network/interceptors/lang_interceptor.dart';
import 'package:groo_damda_app/core/network/interceptors/log_interceptor.dart';
import 'package:groo_damda_app/core/network/interceptors/read_retry_interceptor.dart';
import 'package:groo_damda_app/core/network/secure_cookie_storage.dart';
import 'package:groo_damda_app/core/network/user_agent.dart';

/// 증권 조회 경로 — 읽기 10초 한도는 받지만 저절로 다시 보내지 않는다(`securitiesNoRetry` 와 같다).
const List<String> kSecuritiesPathPrefixes = [
  '/namu',
  '/toss',
  '/securities',
  '/stock-watch',
  '/stocks',
];

/// 영속 cookie_jar (`desk_access_token` 보존) — OS 보안 저장소(Keystore/Keychain)에
/// 암호화 저장(SecureCookieStorage). 단일 인스턴스를 dio 와 로그아웃 헬퍼가 공유.
final cookieJarProvider = FutureProvider<PersistCookieJar>((ref) async {
  return PersistCookieJar(ignoreExpires: true, storage: SecureCookieStorage());
});

/// Dio 인스턴스 (싱글톤). cookie_jar 가 응답 쿠키를 자동 저장·재전송한다.
final dioProvider = FutureProvider<Dio>((ref) async {
  final jar = await ref.watch(cookieJarProvider.future);
  // 안 보내면 dart:io 기본값이 나가고, 서버는 어떤 기기인지 알 수 없다 —
  // "로그인된 기기" 목록이 전부 "Groo 앱" 으로만 보인다.
  final userAgent = await buildUserAgent();
  final dio =
      Dio(
          BaseOptions(
            baseUrl: '${Env.apiBase}/api/v1',
            headers: {'User-Agent': userAgent},
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            contentType: 'application/json',
            responseType: ResponseType.json,
          ),
        )
        ..interceptors.add(CookieManager(jar))
        ..interceptors.add(
          AuthInterceptor(
            onUnauthorized: () {
              // 다음 microtask 에서 처리해 onError 콜체인이 끝난 뒤 신호 발행.
              // dio 는 "세션 만료" 신호만 올리고(auth 의존성 없음), AuthNotifier 가
              // 이를 구독해 logout 한다 — dio↔auth 순환(CircularDependencyError) 제거.
              Future.microtask(() {
                // 계정이 바뀌어 컨테이너가 버려진 뒤에 도착한 401 은 알릴 곳이 없다 —
                // 새 컨테이너는 자기 dio 를 쓴다. 폐기된 ref 는 읽으면 던진다.
                if (!ref.mounted) return;
                ref.read(sessionExpiredProvider.notifier).bump();
              });
            },
          ),
        )
        ..interceptors.add(LangInterceptor())
        ..interceptors.add(
          AppLogInterceptor(
            Logger(
              // release 빌드는 debug 로그(요청/응답 URL 등) 출력 차단 — warning 이상만.
              level: kDebugMode ? Level.debug : Level.warning,
              printer: SimplePrinter(printTime: true),
            ),
          ),
        );

  // 읽기(GET)는 처음 요청부터 다시 시도까지 합쳐 10초 안에 끝낸다 — 그 안에서 5xx · 네트워크 실패만 1초 · 2초 뒤 두 번 다시
  // 보내고, 4xx 와 쓰기는 다시 보내지 않는다(skeleton.md "요청 제한 10초", 03E-021). 맨 앞에 두어 다시 시도로 살아난 요청의
  // 첫 실패를 뒤 인터셉터(401 처리 · 로그)가 보지 못하게 한다.
  dio.httpClientAdapter = ReadDeadlineAdapter(dio.httpClientAdapter);
  dio.interceptors.insert(
    0,
    ReadRetryInterceptor(dio, noRetryPathPrefixes: kSecuritiesPathPrefixes),
  );

  ref.onDispose(dio.close);
  return dio;
});
