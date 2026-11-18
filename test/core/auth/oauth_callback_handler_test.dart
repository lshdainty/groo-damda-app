import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/auth/oauth_callback_handler.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import '../../support/memory_secure_storage.dart';

void main() {
  late MemorySecureStorage storage;
  late OAuthFlowStore store;
  late List<({String code, String verifier})> exchanged;
  late OAuthCallbackHandler handler;

  setUp(() {
    storage = MemorySecureStorage();
    store = OAuthFlowStore(storage);
    exchanged = [];
    handler = OAuthCallbackHandler(
      store: store,
      exchange:
          ({
            required String code,
            required String codeVerifier,
            required bool forcedPrompt,
          }) async {
            exchanged.add((code: code, verifier: codeVerifier));
            return true;
          },
    );
  });

  Uri callback({String? code, String? state}) => Uri.parse(
    'porestdesk://oauth/callback'
    '?${code != null ? 'code=$code&' : ''}${state != null ? 'state=$state' : ''}',
  );

  group('정상 콜백', () {
    test('state 일치 → 보관한 verifier 로 교환하고 흐름을 소비한다', () async {
      await store.savePending(verifier: 'v1', state: 's1');

      final result = await handler.handle(callback(code: 'c1', state: 's1'));

      expect(result, OAuthCallbackResult.exchanged);
      expect(exchanged, [(code: 'c1', verifier: 'v1')]);
      expect(await store.restorePending(), isNull, reason: '재배달 방어 — 흐름 소비');
    });

    test('교환 성공 시 로그아웃의 폼 강제 예약도 해제된다', () async {
      await store.markForceLoginPrompt();
      await store.savePending(verifier: 'v1', state: 's1');

      await handler.handle(callback(code: 'c1', state: 's1'));

      expect(await store.isForceLoginPrompt(), isFalse);
    });
  });

  group('위조·잡음 콜백', () {
    test('state 불일치 → 교환하지 않고, 진행 중 흐름은 남긴다', () async {
      await store.savePending(verifier: 'v1', state: 's1');

      final result = await handler.handle(
        callback(code: 'evil', state: 'wrong'),
      );

      expect(result, OAuthCallbackResult.stateMismatch);
      expect(exchanged, isEmpty);
      expect(
        await store.restorePending(),
        isNotNull,
        reason: '위조 콜백이 진짜 흐름을 지우면 안 된다',
      );
    });

    test('진행 중 흐름이 없으면(중복 배달) 무시한다', () async {
      final result = await handler.handle(callback(code: 'c1', state: 's1'));

      expect(result, OAuthCallbackResult.noPendingFlow);
      expect(exchanged, isEmpty);
    });

    test('code 가 없으면 무시한다', () async {
      await store.savePending(verifier: 'v1', state: 's1');

      final result = await handler.handle(callback(state: 's1'));

      expect(result, OAuthCallbackResult.noCode);
      expect(exchanged, isEmpty);
    });

    test('콜백 스킴이 아니면 손대지 않는다', () async {
      final result = await handler.handle(
        Uri.parse('https://damda.hangroo.io/x'),
      );

      expect(result, OAuthCallbackResult.notCallback);
    });
  });

  group('교환 실패', () {
    test('exchange 가 던지면 그대로 전파된다 (흐름은 이미 소비 — 코드는 1회용)', () async {
      handler = OAuthCallbackHandler(
        store: store,
        exchange:
            ({
              required String code,
              required String codeVerifier,
              required bool forcedPrompt,
            }) async {
              throw StateError('exchange down');
            },
      );
      await store.savePending(verifier: 'v1', state: 's1');

      await expectLater(
        handler.handle(callback(code: 'c1', state: 's1')),
        throwsA(isA<StateError>()),
      );
      expect(await store.restorePending(), isNull);
    });

    test('exchange 가 던지면 폼 강제 예약은 건드리지 않는다 — 남아 있던 것은 남는다', () async {
      handler = OAuthCallbackHandler(
        store: store,
        exchange:
            ({
              required String code,
              required String codeVerifier,
              required bool forcedPrompt,
            }) async {
              throw StateError('exchange down');
            },
      );
      await store.markForceLoginPrompt();
      await store.savePending(verifier: 'v1', state: 's1', forcedPrompt: true);

      await expectLater(
        handler.handle(callback(code: 'c1', state: 's1')),
        throwsA(isA<StateError>()),
      );
      expect(await store.isForceLoginPrompt(), isTrue);
    });
  });

  // 담다에서 로그아웃한 그루 계정 로그인으로 돌아온 코드는 서버가 AUTH_030 으로 거절한다(보안 점검 CLI-6).
  // 교환(AuthNotifier)이 폼을 강제해 한 번 다시 시작할지 가르는데, 그 기준 — 이 시도가 이미 prompt=login
  // 이었는가 — 은 보관분에 있고 처리기가 넘긴다. 실제 배선은 logged_out_sso_login_test.dart 가 태운다.
  group('폼을 강제한 시도인지(prompt=login)', () {
    Future<bool?> forcedSeenByExchange({bool? saved}) async {
      bool? seen;
      handler = OAuthCallbackHandler(
        store: store,
        exchange:
            ({
              required String code,
              required String codeVerifier,
              required bool forcedPrompt,
            }) async {
              seen = forcedPrompt;
              return true;
            },
      );
      if (saved == null) {
        await store.savePending(verifier: 'v1', state: 's1');
      } else {
        await store.savePending(
          verifier: 'v1',
          state: 's1',
          forcedPrompt: saved,
        );
      }
      await handler.handle(callback(code: 'c1', state: 's1'));
      return seen;
    }

    test('보관한 값을 교환에 그대로 넘긴다', () async {
      expect(await forcedSeenByExchange(saved: true), isTrue);
      expect(await forcedSeenByExchange(saved: false), isFalse);
    });

    test('안 적으면 강제하지 않은 시도다', () async {
      expect(await forcedSeenByExchange(), isFalse);
    });

    test('지난 시도의 값이 다음 시도에 남지 않는다', () async {
      await store.savePending(verifier: 'v0', state: 's0', forcedPrompt: true);
      expect(await forcedSeenByExchange(), isFalse, reason: '덮어쓴 흐름은 강제가 아니다');

      await store.savePending(verifier: 'v0', state: 's0', forcedPrompt: true);
      await store.clearPending();
      expect(storage.map, isEmpty, reason: '소비하면 흔적이 남지 않는다');
    });

    test('옛 버전이 보관한 흐름(값 없음)은 강제하지 않은 시도로 읽는다', () async {
      storage.map['oauth_pending_verifier'] = 'v1';
      storage.map['oauth_pending_state'] = 's1';

      final pending = await store.restorePending();

      expect(pending?.forcedPrompt, isFalse);
    });
  });

  group('교환이 폼을 강제해 로그인을 다시 시작했다(false)', () {
    setUp(() {
      handler = OAuthCallbackHandler(
        store: store,
        exchange:
            ({
              required String code,
              required String codeVerifier,
              required bool forcedPrompt,
            }) async => false,
      );
    });

    test('버린 콜백도 로그인 완료도 아니다', () async {
      await store.savePending(verifier: 'v1', state: 's1');

      final result = await handler.handle(callback(code: 'c1', state: 's1'));

      expect(result, OAuthCallbackResult.restartedWithPrompt);
    });

    test('폼 강제 예약을 지우지 않는다 — 다시 시작한 로그인이 성공할 때까지 남는다', () async {
      await store.markForceLoginPrompt();
      await store.savePending(verifier: 'v1', state: 's1');

      await handler.handle(callback(code: 'c1', state: 's1'));

      expect(await store.isForceLoginPrompt(), isTrue);
    });
  });
}
