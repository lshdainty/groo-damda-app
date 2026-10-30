import 'package:groo_damda_app/app/env.dart';

/// 소셜 연동에서 돌아온 결과의 종류.
enum OAuthLinkReturnKind {
  /// `?linked=google` — 연결됐다.
  linked,

  /// `?linkError=…` — 실패했다. 그루 계정이 쓴 글은 화면에 내지 않는다.
  failed,

  /// 아무 값도 없다 — 목록만 다시 받는다.
  unknown,
}

class OAuthLinkReturn {
  const OAuthLinkReturn(this.kind, {this.provider});
  final OAuthLinkReturnKind kind;

  /// 소문자 provider(`google`) — 실패 · 모름이면 null.
  final String? provider;
}

/// 연동 복귀 딥링크(`porestdesk://oauth/linked?linked=google`)인가. 아니면 null.
///
/// 로그인 콜백(`porestdesk://oauth/callback`)과 같은 스킴 · 호스트라 **경로로 먼저 가른다** —
/// 스킴만 보면 이 주소가 로그인 흐름으로 넘어가 진행 중이던 로그인 상태를 건드린다.
OAuthLinkReturn? parseOAuthLinkReturn(Uri uri) {
  if (uri.scheme != Env.authCallbackScheme) return null;
  if (uri.host != 'oauth' || uri.path != Env.oauthLinkReturnPath) return null;
  final error = uri.queryParameters['linkError'];
  if (error != null && error.isNotEmpty) {
    return const OAuthLinkReturn(OAuthLinkReturnKind.failed);
  }
  final linked = uri.queryParameters['linked'];
  if (linked != null && linked.isNotEmpty) {
    return OAuthLinkReturn(OAuthLinkReturnKind.linked, provider: linked);
  }
  return const OAuthLinkReturn(OAuthLinkReturnKind.unknown);
}
