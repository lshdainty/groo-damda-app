import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/auth/oauth_callback_handler.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_return.dart';

void main() {
  group('parseOAuthLinkReturn', () {
    test('연동 복귀(?linked=google)는 linked', () {
      final r = parseOAuthLinkReturn(
        Uri.parse('porestdesk://oauth/linked?linked=google'),
      );
      expect(r?.kind, OAuthLinkReturnKind.linked);
      expect(r?.provider, 'google');
    });

    test('?linkError 는 서버 글과 상관없이 failed', () {
      final r = parseOAuthLinkReturn(
        Uri.parse('porestdesk://oauth/linked?linkError=Cannot+unlink'),
      );
      expect(r?.kind, OAuthLinkReturnKind.failed);
    });

    test('로그인 콜백 · 다른 스킴은 연동 복귀가 아니다', () {
      expect(
        parseOAuthLinkReturn(Uri.parse('porestdesk://oauth/callback?code=a')),
        isNull,
      );
      expect(parseOAuthLinkReturn(Uri.parse('https://x.test/linked')), isNull);
    });
  });

  test('핸들러는 /linked 를 로그인 흐름으로 넘기지 않는다', () async {
    final handler = OAuthCallbackHandler(
      store: OAuthFlowStore(),
      exchange: ({required code, required codeVerifier}) async {
        fail('연동 복귀가 로그인 교환을 탔다');
      },
    );
    expect(
      await handler.handle(
        Uri.parse('porestdesk://oauth/linked?linked=google'),
      ),
      OAuthCallbackResult.linkReturn,
    );
  });
}
