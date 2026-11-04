import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

/// API 에러가 아무 데도 안 보이고 사라지는 걸 막는 마지막 그물.
///
/// 앱은 화면마다 `on ApiException catch` 로 토스트를 띄운다(72곳). 문맥을 붙일 수
/// 있어서 좋지만, 한 군데라도 빠뜨리면 사용자는 눌렀는데 아무 일도 안 일어난 것처럼
/// 느낀다. 웹은 axios 인터셉터가 전부 받아 그 구멍이 구조적으로 안 생긴다
/// (`shared/api/base.ts`).
///
/// 여기서는 웹처럼 "무조건 전역" 으로 가지 않는다. 그러면 화면이 이미 띄운 토스트와
/// 겹쳐 두 개가 뜬다. 대신 **짧게 미뤘다가 띄우고, 그 사이 화면이 자기 에러 토스트를
/// 띄우면 취소**한다. 결과적으로
///   - 화면이 처리한 에러 → 화면의 문맥 있는 메시지 하나 (`삭제 실패: …`)
///   - 아무도 처리 안 한 에러 → 서버 메시지가 그물에 걸려 뜬다
///
/// 조회(GET)는 건너뛴다 — 화면이 자기 에러 상태를 그리고, 폴링이 토스트를 쏟는다.
/// 값을 바꾸는 요청만 띄운다.
///
/// 401 은 건너뛴다 — AuthInterceptor 가 세션 만료 신호를 올리고 로그인으로 보낸다.
/// 특정 요청만 빼려면 `Options(extra: {kSilentErrorToast: true})`.
const String kSilentErrorToast = 'silentErrorToast';

/// 같은 메시지 연타 방지 — 병렬 요청이 같은 에러로 떨어질 때.
const Duration _throttle = Duration(seconds: 3);

GlobalKey<ScaffoldMessengerState>? _messengerKey;
final Map<String, DateTime> _recent = {};

/// 앱 시작 시 한 번 등록. 인터셉터에는 BuildContext 가 없어 이 키로 토스트를 띄운다.
void registerErrorToastMessenger(GlobalKey<ScaffoldMessengerState> key) {
  _messengerKey = key;
}

/// 화면 밖(딥링크 · 수명주기)에서 알림을 띄운다 — 등록된 messenger 에 건다.
///
/// 문구는 그 messenger 의 로케일로 만든다(딥링크에는 BuildContext 가 없다). 아직 등록 전이면 조용히 건너뛴다.
void showGlobalSnack(
  String Function(AppLocalizations l) message, {
  PSnackSeverity severity = PSnackSeverity.info,
}) {
  final key = _messengerKey;
  final ctx = key?.currentContext;
  final state = key?.currentState;
  if (ctx == null || state == null || !ctx.mounted) return;
  showPSnackBar(
    ctx,
    message(AppLocalizations.of(ctx)),
    severity: severity,
    messenger: state,
  );
}

/// 테스트용 — throttle 기록을 비운다.
@visibleForTesting
void resetGlobalErrorToastState() => _recent.clear();

class ErrorToastInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 예약을 먼저 한다. handler.next 는 dio 체인을 이어가며 제어를 넘기므로
    // 그 뒤 코드는 돌지 않을 수 있다.
    schedule(err);
    handler.next(err);
  }

  /// 토스트 예약 — [onError] 가 하는 일 전부. dio 체인 없이 검증할 수 있게 분리했다.
  @visibleForTesting
  void schedule(DioException err) {
    if (err.requestOptions.extra[kSilentErrorToast] == true) return;
    if (err.response?.statusCode == 401) return;
    // 조회 실패는 화면이 자기 자리에서 그린다(빈 목록·에러 상태·재시도). 여기서
    // 또 띄우면 겹치고, 시세·알림 폴링처럼 주기적으로 도는 조회는 토스트가 쏟아진다.
    // 조용히 사라져서 문제인 건 값을 바꾸는 요청 쪽이다.
    if (err.requestOptions.method.toUpperCase() == 'GET') return;

    final message = ApiException.fromDio(err).message;
    final last = _recent[message];
    if (last != null && DateTime.now().difference(last) < _throttle) return;

    final key = _messengerKey;
    final ctx = key?.currentContext;
    final state = key?.currentState;
    if (ctx == null || state == null || !ctx.mounted) return;
    _recent[message] = DateTime.now();
    // ctx 는 테마·로케일 조회용(둘 다 messenger 위에 있다), state 는 표시용.
    showPSnackBar(
      ctx,
      message,
      severity: PSnackSeverity.error,
      messenger: state,
    );
  }
}
