import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/auth/oauth_callback_handler.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_listener.dart';
import 'package:groo_damda_app/core/auth/oauth_link_return.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

void main() {
  test('시작 링크는 프로세스당 한 번만 묻는다(로그아웃 뒤 다음 사람에게 옛 복귀를 또 주지 않는다)', () {
    resetInitialLinkTurn();
    expect(takeInitialLinkTurn(), isTrue);
    expect(takeInitialLinkTurn(), isFalse);
    expect(takeInitialLinkTurn(), isFalse);
    resetInitialLinkTurn();
  });

  test('연결할 수 없는 소셜(kakao)이나 프로토타입 키는 알림이 없다', () {
    for (final v in ['kakao', 'naver', 'constructor', '__proto__']) {
      final r = parseOAuthLinkReturn(
        Uri.parse('porestdesk://oauth/linked?linked=$v'),
      );
      expect(r?.kind, OAuthLinkReturnKind.unknown, reason: v);
    }
  });

  test('linkError 의 서버 글은 알림 글에 들어가지 않는다', () {
    final back = parseOAuthLinkReturn(
      Uri.parse(
        'porestdesk://oauth/linked?linkError=Cannot+unlink+SERVER-TEXT',
      ),
    )!;
    final msg = oauthLinkReturnMessage(back, AppLocalizationsKo());
    expect(msg, '계정을 연결하지 못했어요.');
    expect(msg, isNot(contains('SERVER-TEXT')));
  });

  test('연결 성공 알림은 Google(대문자 GOOGLE 아님)', () {
    final back = parseOAuthLinkReturn(
      Uri.parse('porestdesk://oauth/linked?linked=GOOGLE'),
    )!;
    expect(
      oauthLinkReturnMessage(back, AppLocalizationsKo()),
      'Google 계정이 연결되었어요',
    );
  });

  group('parseOAuthLinkReturn', () {
    test('연동 복귀(?linked=google)는 linked', () {
      final r = parseOAuthLinkReturn(
        Uri.parse('porestdesk://oauth/linked?linked=google'),
      );
      expect(r?.kind, OAuthLinkReturnKind.linked);
      // 알림 이름은 표의 글이다
      expect(r?.provider, 'Google');
    });

    test('서버가 대문자(GOOGLE)로 줘도 알림 이름은 Google', () {
      final r = parseOAuthLinkReturn(
        Uri.parse('porestdesk://oauth/linked?linked=GOOGLE'),
      );
      expect(r?.provider, 'Google');
    });

    test('표에 없는 값(가짜 linked=)은 알리지 않는다', () {
      final r = parseOAuthLinkReturn(
        Uri.parse('porestdesk://oauth/linked?linked=아무글'),
      );
      expect(r?.kind, OAuthLinkReturnKind.unknown);
      expect(r?.provider, isNull);
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
