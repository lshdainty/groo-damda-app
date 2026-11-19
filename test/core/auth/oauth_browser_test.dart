// 로그인 · 소셜 연결을 앱 안 창(iOS SFSafariViewController · Android Custom Tabs)으로 연다.
//
// 붙잡는 것:
//  - 로그인 런처와 소셜 연결이 바깥 브라우저가 아니라 앱 안 창으로 연다
//  - 딥링크로 돌아오면 로그인 콜백 · 연동 복귀(`/linked`) 두 길 모두 앱 안 창을 닫는다
//  - 닫기가 실패하거나(닫을 창이 없는 콜드 스타트 · 플랫폼이 모름) 플러그인이 없어도 복귀 처리는 그대로 돈다
//
// url_launcher 는 시험에서 기본 메서드 채널(`plugins.flutter.io/url_launcher`)로 나간다 — 그 채널을 가로채
// "어떤 방식으로 열었나 · 닫기를 불렀나" 를 본다.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/core/auth/oauth_browser.dart';
import 'package:groo_damda_app/core/auth/oauth_callback_handler.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_listener.dart';
import 'package:groo_damda_app/core/auth/oauth_login_launcher.dart';
import '../../support/memory_secure_storage.dart';

const _channel = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  /// 채널을 가로챈다. [closeFails] 를 켜면 닫기가 플랫폼 오류로 실패한다.
  void mockChannel({bool closeFails = false}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          if (call.method == 'closeWebView' && closeFails) {
            throw PlatformException(code: 'NO_VIEW');
          }
          return call.method == 'launch' ? true : null;
        });
  }

  setUp(() {
    calls = [];
    mockChannel();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  /// 마이크로태스크를 비운다 — 닫기는 기다리지 않고 부른다.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Iterable<MethodCall> named(String method) =>
      calls.where((c) => c.method == method);

  group('앱 안 창으로 연다', () {
    test('방식은 inAppBrowserView — 임베디드 WebView 도 바깥 브라우저도 아니다', () {
      // inAppWebView 는 Google 이 막는다(403 disallowed_useragent).
      expect(kOAuthBrowserMode, LaunchMode.inAppBrowserView);
    });

    test('로그인 런처가 앱 안 창으로 연다', () async {
      final container = ProviderContainer(
        overrides: [
          oauthFlowStoreProvider.overrideWithValue(
            OAuthFlowStore(MemorySecureStorage()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final url = Uri.parse('https://sso.test/api/v1/oauth2/authorize?x=1');

      final launched = await container
          .read(oauthLoginLauncherProvider)
          .launch(url);

      expect(launched, isTrue);
      final call = named('launch').single;
      expect(call.arguments['url'], url.toString());
      expect(
        call.arguments['useSafariVC'],
        isTrue,
        reason: '바깥 브라우저(externalApplication)면 false 다',
      );
      expect(call.arguments['useWebView'], isTrue);
    });

    test('소셜 연결이 쓰는 열기도 앱 안 창이다', () async {
      final url = Uri.parse('https://sso.test/oauth/link/start');

      await openOAuthBrowser(url);

      final call = named('launch').single;
      expect(call.arguments['url'], url.toString());
      expect(call.arguments['useSafariVC'], isTrue);
      expect(call.arguments['useWebView'], isTrue);
    });
  });

  group('돌아오면 앱 안 창을 닫는다', () {
    late OAuthFlowStore store;
    late List<String> exchanged;
    late ProviderContainer container;

    setUp(() async {
      store = OAuthFlowStore(MemorySecureStorage());
      await store.savePending(verifier: 'v-1', state: 's-1');
      exchanged = [];
      container = ProviderContainer(
        overrides: [
          oauthFlowStoreProvider.overrideWithValue(store),
          oauthCallbackHandlerProvider.overrideWithValue(
            OAuthCallbackHandler(
              store: store,
              exchange:
                  ({
                    required String code,
                    required String codeVerifier,
                    required bool forcedPrompt,
                  }) async {
                    exchanged.add(code);
                    return true;
                  },
            ),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    Future<void> comeBack(String uri) async {
      await container.read(oauthLinkHandlerProvider)(Uri.parse(uri));
      await flush();
    }

    test('로그인 콜백 — 닫고 교환한다', () async {
      await comeBack('${Env.oauthRedirectUri}?code=c-1&state=s-1');

      expect(named('closeWebView'), hasLength(1));
      expect(exchanged, ['c-1']);
    });

    test('소셜 연동 복귀(/linked) — 닫는다, 로그인 교환으로 넘기지 않는다', () async {
      await comeBack('${Env.oauthLinkReturnUri}?linked=google');

      expect(named('closeWebView'), hasLength(1));
      expect(exchanged, isEmpty);
    });

    test('연동 실패 복귀(linkError)도 닫는다', () async {
      await comeBack('${Env.oauthLinkReturnUri}?linkError=x');

      expect(named('closeWebView'), hasLength(1));
    });

    test('닫기가 실패해도(콜드 스타트 — 닫을 창이 없다) 교환은 그대로 돈다', () async {
      mockChannel(closeFails: true);

      await comeBack('${Env.oauthRedirectUri}?code=c-2&state=s-1');

      expect(named('closeWebView'), hasLength(1));
      expect(exchanged, ['c-2']);
    });

    test('플러그인이 아예 없어도 교환은 그대로 돈다', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);

      await comeBack('${Env.oauthRedirectUri}?code=c-3&state=s-1');

      expect(exchanged, ['c-3']);
    });
  });
}
