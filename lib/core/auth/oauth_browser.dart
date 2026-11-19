import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 그루 계정 화면(로그인 · 소셜 계정 연결)을 여는 방식 — **앱 안 창**.
///
/// iOS 는 SFSafariViewController, Android 는 Custom Tabs 다. 둘 다 진짜 브라우저 엔진이라
/// Google 이 막는 임베디드 WebView(403 disallowed_useragent)가 아니다 — 그래서
/// [LaunchMode.inAppWebView] 가 아니라 이 모드다. 바깥 브라우저 앱으로 나가지 않아
/// 사용자가 앱을 떠났다고 느끼지 않는다.
///
/// 로그인(`OAuthLoginLauncher`)과 소셜 연결(계정 화면)이 같은 값을 쓴다 — 한쪽만 바꾸지 않게 한 곳에 둔다.
const LaunchMode kOAuthBrowserMode = LaunchMode.inAppBrowserView;

/// [url] 을 앱 안 창으로 연다. 복귀는 딥링크 리스너(`oauthLinkListenerProvider`)가 받는다.
///
/// iOS 는 첫 화면을 다 불러온 뒤에 true 로 끝난다 — 그 전에 사용자가 닫으면 false, 불러오지
/// 못하면 throw. Android 는 탭을 띄우면 바로 true, 못 띄우면 throw.
Future<bool> openOAuthBrowser(Uri url) =>
    launchUrl(url, mode: kOAuthBrowserMode);

/// 딥링크로 돌아왔다 — 앱 안 창이 떠 있으면 닫는다. **기다리지 않고, 오류는 삼킨다.**
///
/// 기다리지 않는 이유: 창 닫기 애니메이션이 콜백 교환을 늦추면 안 된다. 삼키는 이유: 띄운 창이
/// 없을 때(콜드 스타트 — 창은 프로세스와 같이 죽었다)나 플랫폼이 닫기를 모를 때 복귀 처리가
/// 깨지면 안 된다.
///
/// Android 의 Custom Tabs 는 플러그인이 닫지 못한다(`url_launcher_android` 의 닫기는
/// [LaunchMode.inAppWebView] 전용) — 그쪽은 아무 일도 없이 지나간다.
void closeOAuthBrowser() {
  unawaited(
    Future<void>.sync(closeInAppWebView).catchError((Object e) {
      debugPrint('OAuth in-app browser close skipped: $e');
    }),
  );
}
