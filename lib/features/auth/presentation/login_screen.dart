import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/oauth_login_launcher.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/shared/brand/groo_wordmark.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_content.dart';

/// SSO 로그인 화면 (OAuth 2.0 Authorization Code + PKCE, 앱 안 브라우저 창 — RFC 8252 in-app browser tab).
///
/// 흐름:
/// 1. 앱이 PKCE(code_verifier/code_challenge) + state 를 직접 생성,
///    [OAuthFlowStore] 에 **먼저 보관**(브라우저에 가 있는 동안 프로세스가 죽어도 복구).
/// 2. 앱 안 창(iOS SFSafariViewController · Android Custom Tabs)으로 SSO `/api/v1/oauth2/authorize` 오픈. SSO 에 Refresh 쿠키가
///    살아 있으면 무음 재인증으로 폼 없이 즉시 복귀한다.
///    (1 · 2 는 [OAuthLoginLauncher] — 교환이 `AUTH_030` 으로 거절됐을 때의 다시 시작도 같은 길이다)
/// 3. 로그인 완료 → SSO 서버가 302 로 `porestdesk://oauth/callback?code=&state=` 를
///    내려보냄 → OS 딥링크로 앱 복귀 → [oauthLinkListenerProvider] 가 state 검증 후
///    desk-back `/auth/exchange-code` 교환(BFF) → router 가 /home 으로. 리스너가 앱 안 창을 닫는다.
///
/// 인앱 WebView 가 아니라 브라우저 엔진 창인 이유: Google 소셜 로그인이 임베디드
/// WebView 를 차단한다(403 disallowed_useragent). 예전 시스템 브라우저 시절의 두 버그는
/// 구조적으로 재발하지 않는다 — iOS 핸드오프는 서버 302 bounce 가, Android 백그라운드
/// 상태 유실은 PKCE 디스크 보관([OAuthFlowStore])이 막는다.
/// 로그인 실패를 사용자 문구로 바꾼다.
///
/// 원문(`ApiException.toString()`)을 그대로 띄우면 사용자에게
/// `ApiException(AUTH_003, ...)` 같은 게 보인다. 아는 경우는 이름을 불러 주고,
/// 나머지는 서버 글을 붙이지 않고 "로그인하지 못했어요." 로 말한다. 화면 밖에 둔 이유는 테스트 때문이다 —
/// 인라인 `switch` 는 로그인 화면을 통째로 띄우지 않으면 확인할 길이 없다.
String loginErrorMessage(Object? e, AppLocalizations l) => switch (e) {
  // 해지한 계정은 "로그인 실패" 가 아니다 — 다시 눌러도 결과가 같다.
  // 무엇이 끝났는지와, 같은 아이디로는 못 돌아온다는 것을 말한다. 보통은 라우터가
  // 해지 완료 화면으로 보내 이 글은 안 보인다 — 그 길이 빠졌을 때의 대비다.
  ApiException(isWithdrawn: true) =>
    '${l.withdrawnTitle}\n${l.withdrawIrreversibleRejoin}',
  // 담다를 쓸 수 없는 그루 계정이다(서버 403 AUTH_003 — AUTH_ACCESS_DENIED). 다시 눌러도
  // 같은 계정이면 결과가 같다 — 담다를 쓸 수 있는 계정으로 다시 로그인하라고 말한다. 다음
  // 로그인 버튼은 폼을 강제해(prompt=login) 계정을 바꿀 수 있다(AuthNotifier).
  ApiException(isServiceAccessDenied: true) => l.authLoginAccessDenied,
  // 서버가 준 글은 붙이지 않는다 — 코드 · 영어가 그대로 보이던 자리다(Writing 오류).
  _ => l.authLoginFailed,
};

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    // 비-local 환경에서 SSO 가 HTTPS 가 아니면 거부 (자격증명 평문 전송/MITM 방지).
    if (!OAuthLoginLauncher.isSsoOriginSecure) {
      setState(() => _error = l.authSecurityNotHttps);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // PKCE 보관 → authorize 주소(로그아웃 직후 첫 로그인은 prompt=login) → 앱 안
      // 창. 복귀는 딥링크 리스너(oauthLinkListenerProvider)가 받는다.
      await ref.read(oauthLoginLauncherProvider).start();
      // 여기서 흐름이 앱 안 창으로 넘어간다 — 버튼은 되돌린다. 사용자가 창을 그냥 닫아도(취소)
      // 로딩이 남지 않고 다시 누를 수 있다.
      // (교환 진행 상태는 authProvider 의 AsyncLoading 이 담당)
      if (!mounted) return;
      setState(() => _busy = false);
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l.authLoginFailed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l.authLoginError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    // 교환은 딥링크 리스너에서 돈다 — 진행(AsyncLoading)은 버튼의 로딩으로,
    // 실패(AsyncError)는 버튼 위 Callout 으로 흘려보낸다.
    final exchanging = ref.watch(authProvider).isLoading;
    ref.listen(authProvider, (prev, next) {
      if (next.hasError && mounted) {
        final e = next.error;
        // 해지한 계정은 라우터가 해지 완료 화면으로 보낸다 — 여기서 에러 글을 그리면
        // 화면이 바뀌기 전 한 프레임 번쩍인다.
        if (e is ApiException && e.isWithdrawn) return;
        setState(() => _error = loginErrorMessage(e, l));
      }
    });
    return Scaffold(
      // 셸 밖 화면은 흰 면 하나(Q11 11B)
      backgroundColor: c.bgLayerDefault,
      body: PScreenContent(
        maxWidth: kFormMaxWidth,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 마크 — 나무 56 + 8 + 이름(5A). 이름이 화면 제목이다(머리말 1단계).
                  const Center(child: GrooWordmark.horizontal(asHeading: true)),
                  const SizedBox(height: PSpacing.x2),
                  PText(
                    l.authLoginPrompt,
                    textAlign: TextAlign.center,
                    style: PTypography.t5.copyWith(color: c.fgNeutralMuted),
                  ),
                  const SizedBox(height: PSpacing.x8),
                  if (_error != null) ...[
                    // 실패는 누른 자리 가까이 — 폼 맨 위 Callout(snackbar.md)
                    PCallout(
                      tone: PCalloutTone.critical,
                      description: _error!,
                      alert: true,
                    ),
                    const SizedBox(height: PSpacing.x4),
                  ],
                  PButton(
                    label: l.authSsoLogin,
                    // 로딩 중에도 막지 않는다 — 막으면 회색 위에 원이 돈다(웹은 누름 색 + 원).
                    // PButton 이 loading 중 누름을 삼킨다.
                    onPressed: _login,
                    loading: _busy || exchanging,
                    size: PButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
