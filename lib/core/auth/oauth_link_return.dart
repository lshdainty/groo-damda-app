import 'package:groo_damda_app/app/env.dart';

/// 소셜 연동에서 돌아온 결과의 종류.
enum OAuthLinkReturnKind {
  /// `?linked=google` — 연결됐다(표에 있는 값만).
  linked,

  /// `?linkError=…` — 실패했다. 그루 계정이 쓴 글은 화면에 내지 않는다.
  failed,

  /// 아무 값도 없다 — 목록만 다시 받는다.
  unknown,
}

/// 알림에 쓰는 제공자 이름 표 — **허용 값 화이트리스트**다. 복귀 주소의 `linked` 값은 소문자로 바꿔 이 표에서만 찾고,
/// 서버가 대문자(`GOOGLE`)로 줘도 · 아무 글이 와도 알림 이름은 표의 글이다. 표에 없으면 알리지 않는다(웹 `OAUTH_PROVIDER_LABELS` 와 짝).
/// 지금 연결할 수 있는 소셜은 Google 하나지만 서버 목록이 늘면 이 표에 더한다.
const Map<String, String> kOAuthProviderLabels = {
  'google': 'Google',
  'kakao': '카카오',
  'naver': '네이버',
};

class OAuthLinkReturn {
  const OAuthLinkReturn(this.kind, {this.provider});
  final OAuthLinkReturnKind kind;

  /// 표에 있는 제공자의 이름(`Google`) — 실패 · 모름이면 null.
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
  final linked = uri.queryParameters['linked']?.toLowerCase();
  final label = linked == null ? null : kOAuthProviderLabels[linked];
  if (label != null) {
    return OAuthLinkReturn(OAuthLinkReturnKind.linked, provider: label);
  }
  return const OAuthLinkReturn(OAuthLinkReturnKind.unknown);
}
