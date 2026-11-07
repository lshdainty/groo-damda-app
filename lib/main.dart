import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:groo_damda_app/app/app.dart';
import 'package:groo_damda_app/app/session_scope.dart';
import 'package:groo_damda_app/core/diagnostics/global_error_hooks.dart';
import 'package:groo_damda_app/core/update/update_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 처리되지 않은 오류를 로컬 로그에 남긴다 — 화면 변화 없음.
  installGlobalErrorHooks();
  // 날짜 로케일 심볼 초기화(전 로케일). Intl.defaultLocale 배선 후 DateFormat 이
  // 로케일 데이터를 요구하므로(ko/en 모두) runApp 전에 반드시 로드.
  await initializeDateFormatting();
  // 새 버전 알림 — 실패해도 던지지 않는다. 알림을 못 걸었다고 앱을 막을 이유가 없다.
  // await 하지 않는다. 채널 생성과 작업 등록이 첫 화면을 늦출 이유가 없다.
  unawaited(initUpdateNotifications());
  // 로그인한 사람마다 컨테이너를 새로 만든다 — 앞사람 몫으로 받아 둔 값이 다음
  // 사람에게 넘어가지 않게(SessionScope).
  runApp(const SessionScope(child: GrooDamdaApp()));
}
