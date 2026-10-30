import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 확인창 뒤 요청이 실패했을 때의 표시 — 디자인 확정(alert-dialog.md): **확인창 닫기 + critical 스낵바(6초) +
/// [다시 시도](묻지 않고 바로 요청)**. 스낵바 호스트는 길잡이 바깥이라 시트 · 확인창 **위**에 뜬다(snackbar.md).
///
/// 쓰는 자리는 "삭제 · 취소 · 해제 · 환불 취소" 같은 확인창 뒤 요청이다. 폼 저장 실패는 이게 아니다 — 창을 연 채 고쳐야 하니
/// 폼 맨 위 Callout 이 맞다.
///
/// - 요청(`request`)은 **silent** 로 보낸다(저장소 메서드의 `silent: true`) — 전역 서버 원문 토스트와 겹치지 않게.
/// - 실패 글(`failedMessage`)은 호출처가 준다(해요체 + 마침표, 서버 글 아님). [다시 시도] 글자(`retryLabel`)는 보통 `l.actionRetry`.
/// - 요청은 실패하면 **던진다**.
/// - 성공 뒷정리(무효화 · 시트 닫기)는 **두 길**이다. 확인창에서 바로 성공하면 돌려받은 `true`(ok)로, 실패한 뒤 [다시 시도] 로
///   성공하면 [onRetried] 로 한다. 둘 다 같은 일을 해야 지운 항목을 그린 시트가 남지 않는다.
///   [onRetried] 는 시트가 이미 닫힌 뒤에 불릴 수 있다 — 그 안에서 `context` 에 기대지 말고 `ProviderContainer` ·
///   미리 쥔 값을 쓴다(`mounted` 확인).
///
/// 확인창을 띄우고 확정하면 [request] 를 한다. 돌려주는 값 — 요청까지 성공했으면 true. 취소했거나 실패했으면 false
/// (실패면 확인창이 닫힌 뒤 스낵바가 떠 있다).
///
/// ```dart
/// final ok = await askConfirmThenRequest(
///   context,
///   title: l.xxxDeleteTitle(name),
///   description: l.xxxDeleteConfirm,
///   actionLabel: l.actionDelete,
///   request: () => deleteXxx(container, id),
///   failedMessage: l.xxxDeleteFailed,
///   retryLabel: l.actionRetry,
///   onRetried: () => container.invalidate(xxxListProvider),
/// );
/// if (ok) container.invalidate(xxxListProvider);
/// ```
Future<bool> askConfirmThenRequest(
  BuildContext context, {
  String? title,
  required String description,
  String? cancelLabel,
  required String actionLabel,
  bool destructive = true,
  required Future<void> Function() request,
  required String failedMessage,
  required String retryLabel,
  VoidCallback? onRetried,
  bool useRootNavigator = true,
}) async {
  // 확인창이 닫히면 이 context 가 없을 수 있다(시트가 함께 닫힘) — 스낵바 길은 미리 쥔다.
  final snack = PSnackbar.maybeOf(context);
  Object? failure;
  var succeeded = false;
  final confirmed = await PAlertDialog.show(
    context,
    title: title,
    description: description,
    cancelLabel: cancelLabel,
    actionLabel: actionLabel,
    destructive: destructive,
    useRootNavigator: useRootNavigator,
    // 확정이 끝날 때까지 버튼이 로딩이고 다음 누름을 버린다. 던지면 확인창이 열린 채 남으므로 여기서 삼킨다.
    onAction: () async {
      try {
        await request();
        succeeded = true;
      } catch (e) {
        failure = e;
      }
    },
  );
  if (confirmed && failure != null) {
    showConfirmFailSnackbar(
      snack,
      message: failedMessage,
      retryLabel: retryLabel,
      retry: request,
      onRetried: onRetried,
    );
  }
  return confirmed && succeeded;
}

/// critical 스낵바 + [다시 시도]. 다시 시도는 **묻지 않고** [retry] 를 바로 하고, 또 실패하면 같은 띠를 다시 띄운다.
/// [snack] 이 없으면(호스트 밖) 아무것도 하지 않는다 — 시험 · 호스트 없는 화면.
///
/// 다시 시도가 성공했을 때 할 일은 [onRetried] 로 준다(목록 무효화 · 시트 닫기 …). 확인창을 거친 첫 요청의 뒷정리와 같은 일이다.
void showConfirmFailSnackbar(
  PSnackbarApi? snack, {
  required String message,
  required String retryLabel,
  required Future<void> Function() retry,
  VoidCallback? onRetried,
}) {
  if (snack == null) return;
  snack.show(
    message: message,
    tone: PSnackbarTone.critical,
    action: PSnackbarAction(
      label: retryLabel,
      onPressed: () {
        unawaited(() async {
          try {
            await retry();
          } catch (_) {
            showConfirmFailSnackbar(
              snack,
              message: message,
              retryLabel: retryLabel,
              retry: retry,
              onRetried: onRetried,
            );
            return;
          }
          onRetried?.call();
        }());
      },
    ),
  );
}
