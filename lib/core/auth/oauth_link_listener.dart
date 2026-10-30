import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/oauth_callback_handler.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_return.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/features/settings/application/oauth_link_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

/// PKCE 흐름 보관소 — 로그인 화면(저장)과 콜백 리스너(복원)가 같은 인스턴스를 본다.
final oauthFlowStoreProvider = Provider<OAuthFlowStore>(
  (ref) => OAuthFlowStore(),
);

/// OAuth 콜백 딥링크 리스너.
///
/// 앱 기동 시 한 번 켜 둔다(app.dart 에서 watch). 두 경로를 모두 받는다:
/// - 앱이 살아 있는 복귀: [AppLinks.uriLinkStream]
/// - 브라우저에 가 있는 동안 프로세스가 죽었다 떠도: [AppLinks.getInitialLink]
///
/// 후자가 핵심이다 — 예전 flutter_appauth 는 이 경우 진행 상태를 잃어
/// "No stored state" 로 로그인이 깨졌다. 지금은 code_verifier 가
/// [OAuthFlowStore](디스크)에 있으므로 콜드 스타트에서도 교환을 이어간다.
final oauthLinkListenerProvider = Provider<void>((ref) {
  final handler = OAuthCallbackHandler(
    store: ref.watch(oauthFlowStoreProvider),
    exchange: ({required String code, required String codeVerifier}) => ref
        .read(authProvider.notifier)
        .exchangeAndLoginWithCode(
          code: code,
          codeVerifier: codeVerifier,
          redirectUri: Env.oauthRedirectUri,
        ),
  );

  Future<void> onLink(Uri uri) async {
    // 소셜 계정 연동에서 돌아온 주소(`/linked`)는 로그인 콜백으로 넘기지 않는다 — 연결 상태를 다시 받고
    // 결과를 알린다. 서버(그루 계정)가 쓴 글은 내지 않고 고정 글만 쓴다. 콜드 스타트(initial link)도 같은 길이다.
    final back = parseOAuthLinkReturn(uri);
    if (back != null) {
      ref.invalidate(oauthProvidersProvider);
      // 같은 복귀를 두 번 알리지 않는다 — Android 콜드 스타트는 getInitialLink 와 스트림 첫 이벤트가 같은 링크를 준다
      if (!_firstTimeSeen(uri)) return;
      final isError = back.kind == OAuthLinkReturnKind.failed;
      if (back.kind != OAuthLinkReturnKind.unknown) {
        showGlobalSnack(
          (l) => oauthLinkReturnMessage(back, l)!,
          severity: isError ? PSnackSeverity.error : PSnackSeverity.success,
        );
      }
      return;
    }
    try {
      final result = await handler.handle(uri);
      if (result != OAuthCallbackResult.exchanged &&
          result != OAuthCallbackResult.notCallback) {
        // 위조·중복·불완전 콜백 — 사용자에게 띄울 일은 아니고 진단용 로그만.
        debugPrint('OAuth callback ignored: $result');
      }
    } catch (e) {
      // 교환 실패는 authProvider 가 AsyncError 로 들고 있어 로그인 화면이 표시한다.
      debugPrint('OAuth exchange failed: $e');
    }
  }

  final appLinks = AppLinks();
  // 콜드 스타트 분 — 놓친 initial link 를 먼저 소화하고 스트림을 켠다.
  unawaited(
    appLinks.getInitialLink().then((uri) {
      // 같은 프로세스에서 사용자가 바뀌어 리스너가 다시 떠도 옛 시작 링크를 또 처리하지 않는다
      if (uri == null || uri.toString() == _initialHandled) return;
      _initialHandled = uri.toString();
      onLink(uri);
    }),
  );
  final sub = appLinks.uriLinkStream.listen(onLink);
  ref.onDispose(sub.cancel);
});

/// 처리한 시작 링크 — 프로세스 전역이다(리스너가 세션마다 다시 뜬다).
String? _initialHandled;

/// 마지막 연동 복귀와 그 시각 — 2초 안에 같은 주소가 또 오면 무시한다.
Uri? _lastLink;
DateTime? _lastLinkAt;

bool _firstTimeSeen(Uri uri) {
  final now = DateTime.now();
  final dup =
      _lastLink == uri &&
      _lastLinkAt != null &&
      now.difference(_lastLinkAt!) < const Duration(seconds: 2);
  _lastLink = uri;
  _lastLinkAt = now;
  return !dup;
}

/// 연동 복귀의 알림 글 — **서버 글(`linkError=`)은 쓰지 않고 고정 글만**. 알리지 않을 복귀는 null.
@visibleForTesting
String? oauthLinkReturnMessage(OAuthLinkReturn back, AppLocalizations l) =>
    switch (back.kind) {
      OAuthLinkReturnKind.linked => l.accountLinkedToast(back.provider!),
      OAuthLinkReturnKind.failed => l.accountLinkError,
      OAuthLinkReturnKind.unknown => null,
    };
