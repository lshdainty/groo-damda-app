// 같은 폰에서 계정을 바꿔 로그인해도 앞사람 몫으로 받아 둔 값은 하나도 안 넘어간다.
//
// 앱은 로그인한 사람의 데이터만 중계한다. 증권은 각자의 증권사 키로 받아 온 값이라
// 특히 그렇다. 그런데 조회 provider 는 거의 전부 autoDispose 가 아니어서, 로그아웃해도
// 컨테이너에 그대로 남아 다음 사람 화면에 나왔다 — A 의 기능권한이 B 에게 어느 증권사
// 화면을 보여줄지를 정했고, 그 화면에는 A 의 보유 종목이 떴다.
//
// 앱은 **진짜 `GrooDamdaApp`** 을 `SessionScope` 아래에 띄운다(`main` 과 같은 모양).
// 사람이 바뀐 걸 알아채는 리스너도, 컨테이너를 새로 만드는 자리도 거기 있으므로 배선을
// 흉내 내면 정작 그게 끊겨도 테스트는 통과한다.
//
// 서버 대역은 **쿠키가 가리키는 사람**에 따라 다르게 답한다. 그래서 "다시 물었으면
// B 의 값, 안 물었으면 A 의 값" 이 갈린다.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` · `ProviderBase` 는 flutter_riverpod 본체가 아니라 misc 에서 나온다.
import 'package:flutter_riverpod/misc.dart' show Override, ProviderBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/app.dart';
import 'package:groo_damda_app/app/router.dart';
import 'package:groo_damda_app/app/session_scope.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/oauth_flow_store.dart';
import 'package:groo_damda_app/core/auth/oauth_link_listener.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import '../support/plain_text.dart';

const _alice = User(
  rowId: 1,
  userId: 'alice',
  userName: 'Alice',
  userEmail: 'alice@example.com',
);
const _bob = User(
  rowId: 2,
  userId: 'bob',
  userName: 'Bob',
  userEmail: 'bob@example.com',
);

/// Alice 는 나무증권에 '앨리스전자' 를 들고 있다.
const _aliceHolding = '앨리스전자';

/// Bob 도 나무증권을 쓰지만 들고 있는 종목이 다르다.
const _bobHolding = '밥화학';

/// 홈 맨 위에 뜨는 순자산 — 사람마다 다르다.
const _aliceNetWorth = '1,234,567';
const _bobNetWorth = '7,654,321';

/// 앱 잠금 화면의 안내 문구.
const _lockedNotice = '잠금을 해제하려면 본인 확인이 필요해요.';

/// 세션 쿠키 이름과, 쿠키가 붙는 주소.
const _sessionCookie = 'desk_access_token';
final _api = Uri.parse('https://desk.invalid/api/v1/');

/// 보유 종목 이름 글 — ds 가 keep-all 을 위해 글 사이에 끼운 줄바꿈 자리(U+2060)를 뺀 글로 찾는다.
Finder _holding(String name) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? '').replaceAll('\u2060', '').replaceAll('\u200B', '') == name,
);

void main() {
  // ─── 사람이 바뀐다 ───────────────────────────────────────────
  testWidgets('A 가 나가고 B 가 들어오면 — B 는 자기 기능권한·보유 종목을 본다', (tester) async {
    final h = await _pumpApp(tester, signedInAs: _alice);

    // Alice 가 증권 화면을 본다 — 기능권한과 보유 종목이 컨테이너에 받아진다.
    await h.openStocks();
    expect(_holding(_aliceHolding), findsOneWidget);
    expect(h.features?.connectedBrokers, ['NAMU']);
    expect(h.holdingNames, [_aliceHolding]);
    final aliceContainer = h.container;

    await h.signOut();
    await h.signIn(_bob);

    // Bob 은 아직 증권 화면을 열지도 않았다 — 받아 둔 값이 있다면 그건 Alice 것이다.
    // "다시 받는 중(이전 값 보유)" 도 안 된다. 화면은 값이 있으면 그대로 그린다.
    expect(
      h.container.exists(namuHoldingsProvider('KRW')),
      isFalse,
      reason: 'Bob 이 읽지도 않은 보유 종목이 컨테이너에 있다 — Alice 가 받아 둔 값이다',
    );
    expect(
      h.container.exists(myFeaturesProvider) ||
          h.container.exists(myFeaturesLoadProvider),
      isFalse,
      reason: 'Alice 의 기능권한이 남아 Bob 에게 어느 증권사 화면을 띄울지 정한다',
    );

    await h.openStocks();
    expect(
      _holding(_aliceHolding),
      findsNothing,
      reason: 'Bob 의 증권 화면에 Alice 의 보유 종목이 떴다',
    );
    expect(_holding(_bobHolding), findsOneWidget);
    expect(h.holdingNames, [_bobHolding]);
    expect(h.server.holdingsAskedBy, [
      'alice',
      'bob',
    ], reason: '보유 종목은 사람마다 그 사람 쿠키로 한 번씩 물어야 한다');
    expect(
      identical(h.container, aliceContainer),
      isFalse,
      reason: '값을 하나씩 비운 게 아니라 컨테이너를 새로 만들어야 한다(SessionScope)',
    );
  });

  testWidgets('문제가 됐던 구독·증권 조회는 하나도 안 넘어간다', (tester) async {
    // 넘어가던 값들이다 — 앱 수명 내내 살고, 로그인 직후의 무효화 목록에도 없던 것들.
    // 목록을 늘려 막지 않았으므로 여기 없는 provider 도 똑같이 새로 시작한다. 이 목록은
    // 버그가 보고된 자리를 못 박아 두는 것뿐이다.
    const stock = StockMasterItem(
      countryCode: 'KR',
      marketCode: 'KOSPI',
      symbol: '005930',
      nameKr: '테스트전자',
      securityType: 'STOCK',
      currency: 'KRW',
    );
    final reported = <ProviderBase<Object?>>[
      myFeaturesProvider,
      myFeaturesLoadProvider,
      brokerConnectionsProvider,
      mySubscriptionProvider,
      namuHoldingsProvider('KRW'),
      namuPriceProvider(stock),
      tossAccountsProvider,
      tossHoldingsProvider,
      tossExchangeRateProvider,
      watchGroupsProvider,
      prevCloseProvider('005930'),
      tossRankingsProvider('MARKET_CAP|KR|1D'),
      tossIndicatorPricesProvider,
    ];
    final h = await _pumpApp(tester, signedInAs: _alice);
    final alice = h.container;
    for (final provider in reported) {
      alice.read(provider);
    }
    await h.settle();
    for (final provider in reported) {
      expect(
        alice.exists(provider),
        isTrue,
        reason: '$provider — Alice 가 받아 둔 값',
      );
    }

    await h.signOut();
    await h.signIn(_bob);

    for (final provider in reported) {
      expect(
        h.container.exists(provider),
        isFalse,
        reason: '$provider — Alice 가 받아 둔 값이 Bob 의 컨테이너에 있다',
      );
    }
  });

  testWidgets('B 의 증권 화면은 B 의 연결 증권사로 정해진다 — A 의 기능권한이 남지 않는다', (tester) async {
    // Alice 는 나무, Carol 은 토스를 연결했다. 어느 증권사 화면을 띄울지는 기능권한이
    // 정하므로, Alice 의 값이 남아 있으면 Carol 에게 나무 화면이 뜬다.
    final h = await _pumpApp(tester, signedInAs: _alice);
    await h.openStocks();
    expect(find.byType(NamuStocksView), findsOneWidget);

    await h.signOut();
    await h.signIn(_carol);
    await h.openStocks();

    expect(h.features?.connectedBrokers, ['TOSS']);
    expect(
      find.byType(NamuStocksView),
      findsNothing,
      reason: '토스만 연결한 Carol 에게 Alice 의 나무 화면이 떴다',
    );
    expect(find.byType(TossStocksView), findsOneWidget);
    expect(_holding(_aliceHolding), findsNothing);
  });

  testWidgets('로그아웃 없이 곧바로 다른 사람으로 바뀌어도 새로 시작한다', (tester) async {
    // 로그인한 채로 다른 계정의 로그인 콜백이 들어오는 길(딥링크)이다.
    final h = await _pumpApp(tester, signedInAs: _alice);
    await h.openStocks();
    expect(_holding(_aliceHolding), findsOneWidget);

    // Alice 의 증권 화면이 **떠 있는 채로** 사람이 바뀐다. 그 뒤 그려지는 프레임마다 본다 —
    // 잠깐이라도 비치면 안 된다.
    await h.signIn(
      _bob,
      everyFrame: () => expect(
        _holding(_aliceHolding),
        findsNothing,
        reason: '보고 있던 Alice 의 증권 화면이 Bob 에게 비쳤다',
      ),
    );

    await h.openStocks();
    expect(_holding(_bobHolding), findsOneWidget);
    expect(_holding(_aliceHolding), findsNothing);
  });

  testWidgets('B 의 응답이 늦어도 — 그 사이 B 의 홈에 A 의 순자산이 비치지 않는다', (tester) async {
    // 홈은 껌뻑임을 막으려고 "값이 있으면 그대로 그린다"(다시 받는 중에도 이전 값을
    // 보여 준다). 사람이 바뀐 자리에서 값을 **다시 받게만** 하면, 그 이전 값이 Alice
    // 것이라 Bob 의 응답이 올 때까지 Alice 의 순자산이 Bob 의 홈에 뜬다. 가짜 서버가
    // 곧바로 답하면 그 틈이 안 보이므로 답을 쥐고 있게 한다.
    final h = await _pumpApp(tester, signedInAs: _alice);
    expect(findPlainContaining(_aliceNetWorth), findsWidgets);

    h.server.holdResponses();
    await h.signOut();
    await h.signIn(
      _bob,
      everyFrame: () => expect(
        findPlainContaining(_aliceNetWorth),
        findsNothing,
        reason: 'Bob 의 홈에 Alice 의 순자산이 비쳤다 — 다시 받는 동안 이전 값을 그렸다',
      ),
    );
    expect(
      findPlainContaining(_bobNetWorth),
      findsNothing,
      reason: '아직 서버가 답하지 않았다',
    );

    h.server.releaseResponses();
    await h.settle();
    expect(findPlainContaining(_bobNetWorth), findsWidgets);
  });

  testWidgets('앞사람 화면에 떠 있던 토스트도 넘어가지 않는다', (tester) async {
    // 토스트는 컨테이너가 아니라 ScaffoldMessenger 가 들고 있고, 그 키가 전역이라
    // 컨테이너를 갈아도 플러터가 새 트리로 옮겨 붙인다 — 따로 걷지 않으면 남는다.
    final h = await _pumpApp(tester, signedInAs: _alice);
    appMessengerKey.currentState!.showSnackBar(
      const SnackBar(
        content: Text('앨리스전자 3주를 담았어요'),
        duration: Duration(minutes: 1),
      ),
    );
    await h.settle();
    expect(findText('앨리스전자 3주를 담았어요'), findsOneWidget);

    // 사라지는 애니메이션 동안에도 글자는 읽힌다 — 바뀐 뒤 첫 프레임부터 없어야 한다.
    await h.signIn(
      _bob,
      everyFrame: () => expect(
        findText('앨리스전자 3주를 담았어요'),
        findsNothing,
        reason: 'Alice 화면의 토스트가 Bob 에게 비쳤다',
      ),
    );
  });

  testWidgets('바뀐 사람이 나갔다 앞사람이 돌아와도 — 서로의 값을 보지 않는다', (tester) async {
    final h = await _pumpApp(tester, signedInAs: _alice);
    await h.openStocks();

    await h.signOut();
    await h.signIn(_bob);
    await h.openStocks();
    expect(_holding(_bobHolding), findsOneWidget);

    await h.signOut();
    await h.signIn(_alice);
    await h.openStocks();

    expect(_holding(_bobHolding), findsNothing);
    expect(_holding(_aliceHolding), findsOneWidget);
    expect(h.server.holdingsAskedBy, ['alice', 'bob', 'alice']);
  });

  testWidgets('진짜 AuthNotifier 로도 같다 — 로그아웃하고 다른 사람의 인가코드를 교환한다', (
    tester,
  ) async {
    // 위 테스트들은 인증 대역이 상태만 같은 순서로 밟는다. 여기서는 **진짜
    // `AuthNotifier`** 의 `logout` · `exchangeAndLoginWithCode` 를 그대로 태우고,
    // 쿠키도 진짜 `PersistCookieJar` · `CookieManager` 로 주고받는다. 새 컨테이너는
    // 쿠키 저장소를 새로 열어 세션을 다시 확인하므로, **교환 응답의 쿠키가 기기
    // 저장소에 먼저 내려가 있어야** Bob 으로 들어온다 — 그게 대역으로는 안 보인다.
    final h = await _pumpApp(tester, signedInAs: _alice, realAuth: true);
    await h.openStocks();
    expect(_holding(_aliceHolding), findsOneWidget);
    expect(h.server.sessionChecks, 1, reason: '앱을 켤 때 한 번 확인한다');
    final aliceContainer = h.container;

    await h.auth((auth) => auth.logout());
    expect(await h.storedSession(), isNull, reason: '로그아웃하면 기기에 쿠키가 남지 않는다');
    expect(
      identical(h.container, aliceContainer),
      isTrue,
      reason: '로그아웃만으로는 안 바꾼다',
    );

    await h.auth(
      (auth) => auth.exchangeAndLoginWithCode(
        code: 'code-of-bob',
        codeVerifier: 'verifier',
        redirectUri: 'porestdesk://oauth/callback',
      ),
    );

    expect(identical(h.container, aliceContainer), isFalse);
    expect(await h.storedSession(), 'bob');
    expect(
      h.container.read(authProvider).value,
      _bob,
      reason: '새 컨테이너가 기기에 저장된 쿠키로 세션을 다시 확인해 Bob 으로 들어와야 한다',
    );
    expect(
      h.server.sessionChecks,
      3,
      reason: '교환 직후 한 번, 새 컨테이너가 한 번 — 그보다 많으면 컨테이너를 되풀이해 만들고 있다',
    );

    await h.openStocks();
    expect(_holding(_bobHolding), findsOneWidget);
    expect(_holding(_aliceHolding), findsNothing);
    expect(h.server.sessionChecks, 3);
  });

  testWidgets('앱 잠금을 켜 둔 기기에서는 — 바뀐 사람에게도 잠금이 다시 걸린다', (tester) async {
    // 새 컨테이너는 앱을 새로 켠 것과 같은 길을 밟는다. 잠금 상태도 컨테이너에 있어서
    // 새 컨테이너는 "안 잠김" 에서 시작하는데, 거기서 멈추면 계정을 바꾸는 것으로
    // 잠금을 지나칠 수 있게 된다.
    final lock = _FakeLock();
    final h = await _pumpApp(tester, signedInAs: _alice, appLock: lock);
    expect(lock.prompts, 1, reason: '앱을 켤 때 본인 확인을 한 번 받는다');
    expect(findText(_lockedNotice), findsNothing, reason: '확인을 통과해 열려 있다');

    // 다음 확인은 통과하지 못한다 — 잠금 화면이 남아 있어야 한다.
    lock.result = AppLockAuthResult.failure;
    await h.signIn(_bob);

    expect(lock.prompts, 2, reason: '사람이 바뀐 뒤 본인 확인을 다시 받아야 한다');
    expect(
      findText(_lockedNotice),
      findsOneWidget,
      reason: '새 컨테이너가 잠금 없이 열렸다',
    );
  });

  testWidgets('앱이 가려진 채로 사람이 바뀌면 — 돌아올 때 옛 셸은 손대지 않는다', (tester) async {
    // 가려진 동안에는 프레임이 없어 컨테이너를 못 바꾼다. 돌아오는 신호는 그래서 **옛
    // 셸이 먼저** 받는데, 거기서 복귀 처리를 하면 곧 버려질 컨테이너로 조회가 나가고
    // 대기 중인 결제 문자를 꺼내 버린다(네이티브는 꺼내는 순간 비운다). 문자는
    // 안드로이드 채널이라 여기서 못 보므로, 같은 자리에서 도는 알림 조회를 센다.
    final h = await _pumpApp(tester, signedInAs: _alice);
    await h.signOut();
    final aliceContainer = h.container;

    await h.background();
    await h.signIn(_bob);
    expect(
      identical(h.container, aliceContainer),
      isTrue,
      reason: '전제가 바뀌었다 — 가려진 동안에도 프레임이 돈다면 이 테스트는 다시 봐야 한다',
    );
    final pollsBefore = h.server.notificationPolls;

    await h.foreground();

    expect(identical(h.container, aliceContainer), isFalse);
    expect(h.container.read(authProvider).value, _bob);
    expect(
      h.server.notificationPolls - pollsBefore,
      1,
      reason: '새 컨테이너가 한 번 물어야 한다 — 둘이면 옛 셸도 복귀 처리를 한 것이다',
    );
  });

  // ─── 사람이 그대로다 ─────────────────────────────────────────
  testWidgets('같은 사람의 무음 재인증으로는 새로 시작하지 않는다', (tester) async {
    final h = await _pumpApp(tester, signedInAs: _alice);
    await h.openStocks();
    final container = h.container;
    final asked = h.server.holdingsAskedBy.length;

    await h.reauthenticate();
    await h.reauthenticate();

    expect(
      identical(h.container, container),
      isTrue,
      reason: '같은 사람인데 컨테이너를 갈았다 — 쓰는 도중에 앱이 처음부터 다시 열린다',
    );
    expect(
      _holding(_aliceHolding),
      findsOneWidget,
      reason: '보던 화면이 그대로 있어야 한다',
    );
    expect(h.server.holdingsAskedBy, hasLength(asked), reason: '다시 물을 이유가 없다');
  });

  testWidgets('같은 사람이 나갔다 다시 들어오면 그대로 이어 쓴다', (tester) async {
    final h = await _pumpApp(tester, signedInAs: _alice);
    await h.openStocks();
    final container = h.container;

    await h.signOut();
    await h.signIn(_alice);

    expect(identical(h.container, container), isTrue);
    expect(h.holdingNames, [_aliceHolding], reason: '자기 값이다 — 버릴 이유가 없다');
  });

  // ─── 왜 비우는 것으로는 안 되나 ───────────────────────────────
  test('dio 를 무효화하는 것으로는 부족하다 — 다시 받는 동안 앞사람 값이 남는다', () async {
    // 설계의 근거를 못 박는다. 무효화는 riverpod 에서 "비우기" 가 아니라 "다시 받기" 라,
    // 다시 받는 동안 이전 값을 그대로 들고 있다. 이 앱의 화면은 값이 있으면 그대로
    // 그리므로(껌뻑임 방지) 그 값이 Bob 의 화면에 뜬다. 그래서 컨테이너를 새로 만든다.
    final server = _Server()..signedIn = _alice;
    final container = ProviderContainer.test(overrides: [_fakeDio(server)]);

    final alice = await container.read(namuHoldingsProvider('KRW').future);
    expect(alice.items.single.name, _aliceHolding);

    server.signedIn = _bob;
    container.invalidate(dioProvider);
    final reloading = container.read(namuHoldingsProvider('KRW'));

    expect(reloading.isLoading, isTrue);
    expect(
      reloading.value?.items.single.name,
      _aliceHolding,
      reason:
          '전제가 바뀌었다 — riverpod 이 다시 받는 동안 이전 값을 안 들고 있다면 '
          'SessionScope 의 근거를 다시 봐야 한다',
    );

    // 반면 새 컨테이너는 아무것도 들고 있지 않다.
    final fresh = ProviderContainer.test(overrides: [_fakeDio(server)]);
    expect(fresh.read(namuHoldingsProvider('KRW')).hasValue, isFalse);
    final bob = await fresh.read(namuHoldingsProvider('KRW').future);
    expect(bob.items.single.name, _bobHolding);
  });
}

const _carol = User(
  rowId: 3,
  userId: 'carol',
  userName: 'Carol',
  userEmail: 'carol@example.com',
);

const _everyone = [_alice, _bob, _carol];

// ─── 서버 대역 ─────────────────────────────────────────────────

/// 쿠키가 가리키는 사람에 따라 다르게 답하는 가짜 서버.
class _Server implements HttpClientAdapter {
  /// 지금 쿠키가 가리키는 사람 — 로그인하면 바뀌고, 로그아웃하면 비워진다.
  /// 인증 대역([_FakeAuth])이 쿠키 노릇까지 대신할 때 쓴다.
  User? signedIn;

  /// 켜면 [signedIn] 이 아니라 **요청에 실려 온 쿠키**로 사람을 가린다 — 진짜
  /// `AuthNotifier` 와 진짜 쿠키 저장소를 태울 때.
  bool readsCookie = false;

  /// 알림 목록을 물은 횟수 — 알림 폴러가 한 번 돌 때마다 하나.
  int notificationPolls = 0;

  /// 보유 종목을 **누구 쿠키로** 물었는지, 물은 순서대로.
  final holdingsAskedBy = <String>[];

  /// 세션 확인(`/auth/check`)이 들어온 횟수.
  int sessionChecks = 0;

  /// 잡혀 있으면 요청이 답을 못 받고 기다린다 — 느린 네트워크.
  Completer<void>? _held;

  /// 지금부터 들어오는 요청의 답을 쥐고 있는다.
  void holdResponses() => _held = Completer<void>();

  /// 쥐고 있던 답을 전부 돌려준다.
  void releaseResponses() {
    _held?.complete();
    _held = null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 누구의 요청인지는 **보낼 때의 쿠키**로 정해진다 — 늦게 답해도 바뀌지 않는다.
    final who = _sender(options);
    await _held?.future;
    final path = options.uri.path;

    // 인증 — 진짜 `AuthNotifier` 를 태울 때만 온다.
    if (path.endsWith('/auth/check')) {
      sessionChecks++;
      return who == null ? _json(401, null) : _json(200, who.toJson());
    }
    if (path.endsWith('/auth/exchange-code')) {
      // 인가코드가 곧 로그인하는 사람이다. 세션은 응답의 쿠키로 내려간다.
      final code = (options.data as Map)['code'] as String;
      final user = _everyone.firstWhere((u) => code == 'code-of-${u.userId}');
      return _json(
        200,
        null,
        setCookie: '$_sessionCookie=${user.userId}; Path=/',
      );
    }
    // 로그아웃 — 쿠키는 앱이 자기 저장소에서 지운다.
    if (path.endsWith('/auth/logout')) return _json(200, null);
    if (who == null) return _json(401, null);

    if (path.endsWith('/notifications')) {
      notificationPolls++;
      return _json(200, {'notifications': <Object>[]});
    }
    if (path.endsWith('/assets/summary')) {
      return _json(200, {
        'netWorth': who.userId == 'alice' ? 1234567 : 7654321,
      });
    }
    if (path.endsWith('/users/me/features')) {
      final broker = who.userId == 'carol' ? 'TOSS' : 'NAMU';
      return _json(200, {
        'features': ['SECURITIES'],
        'connectedBrokers': [broker],
        'primaryBroker': broker,
      });
    }
    if (path.endsWith('/namu/holdings')) {
      final krw = options.uri.queryParameters['currency'] == 'KRW';
      // 나무 화면은 국내 · 해외 두 통화를 함께 묻는다 — 사람마다 몇 번 물었는지는 국내 한 통화로 센다.
      if (krw) holdingsAskedBy.add(who.userId);
      return _json(200, {
        'accountNo': '${who.userId}-account',
        'currency': options.uri.queryParameters['currency'],
        'totalEvalAmount': '1000',
        'totalProfitLoss': '10',
        'profitRate': '1.0',
        'items': [
          if (krw)
            {
              'symbol': '000001',
              'name': who.userId == 'alice' ? _aliceHolding : _bobHolding,
              'quantity': '3',
              'evalAmount': '1000',
              'profitLoss': '10',
            },
        ],
      });
    }
    // 이 테스트가 보지 않는 조회 — 화면은 자기 에러 상태를 그린다.
    return _json(404, null);
  }

  User? _sender(RequestOptions options) {
    if (!readsCookie) return signedIn;
    final sent = '${options.headers[HttpHeaders.cookieHeader] ?? ''}';
    final id = RegExp('$_sessionCookie=(\\w+)').firstMatch(sent)?.group(1);
    return _everyone.where((u) => u.userId == id).firstOrNull;
  }

  ResponseBody _json(int status, Object? data, {String? setCookie}) =>
      ResponseBody.fromString(
        jsonEncode({'success': status == 200, 'data': data, 'message': 'fake'}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          if (setCookie != null) HttpHeaders.setCookieHeader: [setCookie],
        },
      );

  @override
  void close({bool force = false}) {}
}

/// 진짜 repository 들이 가짜 서버를 타게 한다 — provider 를 하나씩 덮지 않는다.
/// 덮으면 "다시 물었는가" 를 볼 수 없다.
///
/// [cookies] 를 켜면 앱과 같이 쿠키 저장소를 끼운다 — 응답의 쿠키를 저장하고 요청에 싣는다.
Override _fakeDio(_Server server, {bool cookies = false}) =>
    dioProvider.overrideWith((ref) async {
      final dio = Dio(BaseOptions(baseUrl: '$_api'))
        ..httpClientAdapter = server;
      if (cookies) {
        final jar = await ref.watch(cookieJarProvider.future);
        dio.interceptors.add(CookieManager(jar));
      }
      return dio;
    });

/// 인증 대역 — 서버의 쿠키([_Server.signedIn])와 같이 움직인다.
///
/// 진짜 [AuthNotifier] 는 SSO·쿠키 저장소를 물고 있어 여기서는 못 쓴다. 대신 상태를
/// **같은 순서로** 밟는다(로딩 → 확정). 새 컨테이너가 뜨면 [build] 가 쿠키로 세션을
/// 다시 확인하는 것도 같다.
class _FakeAuth extends AuthNotifier {
  _FakeAuth(this._server);
  final _Server _server;
  int _reauths = 0;

  @override
  Future<User?> build() async => _server.signedIn;

  void signInForTest(User user) {
    state = const AsyncLoading();
    _server.signedIn = user;
    state = AsyncData(user);
  }

  void signOutForTest() {
    state = const AsyncLoading();
    _server.signedIn = null;
    state = const AsyncData(null);
  }

  void reauthenticateForTest() {
    _reauths++;
    state = AsyncData(
      _server.signedIn!.copyWith(userName: 'Reauthenticated $_reauths'),
    );
  }
}

/// 쿠키 저장소 대역 — 기기 보안 저장소 대신 메모리에 둔다.
class _MemoryCookieStorage implements Storage {
  final _values = <String, String>{};

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll(List<String> keys) async =>
      keys.forEach(_values.remove);
}

/// OAuth 흐름 보관소 대역 — 로그아웃이 남기는 "다음 로그인은 폼 강제" 표시만 받는다.
class _MemoryFlowStore extends OAuthFlowStore {
  bool _forcePrompt = false;

  @override
  Future<void> markForceLoginPrompt() async => _forcePrompt = true;

  @override
  Future<bool> isForceLoginPrompt() async => _forcePrompt;

  @override
  Future<void> clearForceLoginPrompt() async => _forcePrompt = false;
}

/// 생체인증 대역 — OS 프롬프트 없이 정해 둔 결과를 돌려준다.
class _FakeLock extends AppLockAuth {
  _FakeLock() : super(LocalAuthentication());

  AppLockAuthResult result = AppLockAuthResult.success;

  /// 본인 확인을 받은 횟수.
  int prompts = 0;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async {
    prompts++;
    return result;
  }
}

// ─── 하네스 ───────────────────────────────────────────────────

class _Harness {
  _Harness(this.tester, this.server, this._device);
  final WidgetTester tester;
  final _Server server;

  /// 기기의 쿠키 저장소 — 컨테이너가 몇 번 바뀌어도 하나다.
  final _MemoryCookieStorage _device;

  /// 기기에 저장된 세션 쿠키가 가리키는 사람. 없으면 `null`.
  ///
  /// 저장소를 **새로 열어** 읽는다 — 새 컨테이너가 보게 될 값이 이것이다.
  Future<String?> storedSession() async {
    final jar = PersistCookieJar(ignoreExpires: true, storage: _device);
    final cookies = await jar.loadForRequest(_api);
    return cookies
        .where((c) => c.name == _sessionCookie)
        .map((c) => c.value)
        .firstOrNull;
  }

  /// 앱을 백그라운드로 — 엔진이 보내는 순서 그대로.
  Future<void> background() => _lifecycle(const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]);

  /// 앱이 앞으로 돌아온다 — 역순.
  Future<void> foreground() => _lifecycle(const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]);

  Future<void> _lifecycle(List<AppLifecycleState> states) async {
    for (final s in states) {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage(s.toString()),
        (_) {},
      );
      await tester.pump();
    }
    await settle();
  }

  /// **지금** 앱이 쓰는 컨테이너 — 사람이 바뀌면 다른 것이 된다.
  ProviderContainer get container => ProviderScope.containerOf(
    tester.element(find.byType(GrooDamdaApp)),
    listen: false,
  );

  _FakeAuth get _auth => container.read(authProvider.notifier) as _FakeAuth;

  /// 진짜 [AuthNotifier] 의 동작을 부르고 끝날 때까지 민다(`realAuth` 로 띄웠을 때).
  Future<void> auth(Future<void> Function(AuthNotifier auth) act) async {
    Object? failure;
    unawaited(
      act(container.read(authProvider.notifier)).catchError((Object e) {
        failure = e;
      }),
    );
    await settle();
    expect(failure, isNull);
  }

  /// 지금 컨테이너가 들고 있는 기능권한 — 증권 화면은 실패를 그대로 던지는 원본(myFeaturesLoadProvider)을 읽는다.
  MyFeatures? get features => container.read(myFeaturesLoadProvider).value;

  /// 지금 컨테이너가 들고 있는 국내 보유 종목 이름들.
  List<String>? get holdingNames => container
      .read(namuHoldingsProvider('KRW'))
      .value
      ?.items
      .map((i) => i.name)
      .toList();

  /// [everyFrame] 을 주면 로그인 뒤 그려지는 프레임마다 부른다.
  Future<void> signIn(User user, {VoidCallback? everyFrame}) async {
    _auth.signInForTest(user);
    await settle(everyFrame: everyFrame);
  }

  Future<void> signOut() async {
    _auth.signOutForTest();
    await settle();
  }

  Future<void> reauthenticate() async {
    _auth.reauthenticateForTest();
    await settle();
  }

  /// 전체 탭의 증권 메뉴가 하는 일 그대로 — `/stocks` 를 push 한다.
  Future<void> openStocks() async {
    container.read(routerProvider).push('/stocks');
    await settle();
  }

  /// 조회가 끝나 화면이 자리를 잡을 때까지 프레임을 민다.
  /// `pumpAndSettle` 은 못 쓴다 — 로딩 스켈레톤이 무한 애니메이션이라 안 끝난다.
  ///
  /// 넉넉히 민다(1초). 로그아웃·로그인은 화면 전환 애니메이션을 끼고 있어서, 전환이
  /// 끝나기 전에 다음 전환을 걸면 셸의 GlobalKey 가 나가는 화면과 들어오는 화면에 동시에
  /// 걸린다. 실제로는 로그인이 브라우저를 다녀오므로 그 사이가 몇 초다.
  Future<void> settle({VoidCallback? everyFrame}) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      everyFrame?.call();
    }
  }
}

Future<_Harness> _pumpApp(
  WidgetTester tester, {
  required User signedInAs,
  bool realAuth = false,
  AppLockAuth? appLock,
}) async {
  // 로그인 화면을 거친다 — 테스트 폰트는 글자마다 정사각형이라 '그루 담다' 한 줄이
  // 390 폭에서 넘친다(테스트 환경 산물). 넘칠 자리를 준다.
  tester.view.physicalSize = const Size(520 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    PrefsKeys.locale: 'ko',
    if (appLock != null) PrefsKeys.appLock: true,
  });
  // 앞 테스트가 백그라운드로 보낸 채 끝났을 수 있다 — 매번 앞에서 시작한다.
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/lifecycle',
    const StringCodec().encodeMessage(AppLifecycleState.resumed.toString()),
    (_) {},
  );

  final server = _Server()
    ..signedIn = signedInAs
    ..readsCookie = realAuth;
  // 기기 저장소는 컨테이너 밖에 있다 — 컨테이너를 새로 만들어도 같은 것을 다시 연다.
  final device = _MemoryCookieStorage();
  final flowStore = _MemoryFlowStore();
  if (realAuth) {
    // 앱을 켜기 전부터 로그인돼 있던 사람의 쿠키.
    await PersistCookieJar(
      ignoreExpires: true,
      storage: device,
    ).saveFromResponse(_api, [
      Cookie(_sessionCookie, signedInAs.userId)..path = '/',
    ]);
  }
  await tester.pumpWidget(
    SessionScope(
      overrides: [
        if (realAuth) ...[
          // 진짜 notifier 가 만지는 기기 저장소만 메모리로 바꾼다(플러그인 채널이 없다).
          cookieJarProvider.overrideWith(
            (ref) async =>
                PersistCookieJar(ignoreExpires: true, storage: device),
          ),
          oauthFlowStoreProvider.overrideWithValue(flowStore),
        ] else
          authProvider.overrideWith(() => _FakeAuth(server)),
        if (appLock != null) appLockAuthProvider.overrideWithValue(appLock),
        _fakeDio(server, cookies: realAuth),
        // 홈 셸이 읽는 것 — 이 테스트가 보는 조회가 아니라 빈 값으로 채워 조용히 둔다.
        // (순자산 요약은 덮지 않는다 — 가짜 서버가 사람마다 다르게 답한다.)
        categoriesProvider.overrideWith(
          (_) => Future.value(<ExpenseCategory>[]),
        ),
        assetsProvider.overrideWith((_) => Future.value(<Asset>[])),
        monthExpensesProvider.overrideWith((_, _) => Future.value(<Expense>[])),
      ],
      child: const GrooDamdaApp(),
    ),
  );
  final h = _Harness(tester, server, device);
  await h.settle();
  return h;
}
