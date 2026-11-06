// 나무증권 화면은 웹과 같은 박자로 새로 받는다.
//
// 예전엔 이 화면에 다시 받는 자리가 하나도 없었다. provider 가 autoDispose 가 아니라
// 처음 받은 시세·보유 종목이 앱을 다시 켤 때까지 굳어 있었고, 앱으로 돌아와도 그대로였다.
//
// 그렇다고 토스 화면처럼 10초마다 전부 조르면 안 된다. 나무엔 다건 조회 API 가 없어
// 조회 한 번이 곧 상류 1콜이고 유량 제한(429)이 있다. 그래서 웹 나무 화면
// (`NamuStocksPage` · `useNamu`)이 하는 만큼만 한다.
//
//   관심 시세 — 30초마다. 관심 탭에서 보이는 묶음만. 앱이 가려진 동안은 멈춘다.
//   보유 종목 — 주기로 조르지 않는다. 들어올 때·돌아올 때 30초가 지났으면 다시 받는다.
//   실패      — 자동으로 다시 치지 않는다.
//
// 여기서 세는 건 "타이머가 있다" 가 아니라 **나무 조회가 실제로 몇 번 나갔는가** 다.
// 시간은 위젯 테스트의 가짜 시계로 민다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/sync/query_freshness.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

void main() {
  // ─── 관심 시세 ──────────────────────────────────────────────
  group('관심 시세', () {
    testWidgets('30초마다 다시 받는다 — 그 사이에는 안 받는다', (tester) async {
      final h = await _pumpView(tester);
      await h.openWatch();
      expect(h.namu.priceCalls, 1, reason: '보이는 묶음의 시세를 한 번에 한 번 받는다');

      await h.advanceTo(const Duration(seconds: 29));
      expect(
        h.namu.priceCalls,
        1,
        reason: '30초가 안 됐는데 나무를 또 쳤다 — 조회 한 번이 상류 1콜이다',
      );

      await h.advanceTo(const Duration(seconds: 30));
      expect(
        h.namu.priceCalls,
        2,
        reason: '30초가 지났는데 시세가 그대로다 — 예전엔 앱을 다시 켤 때까지 처음 값이었다',
      );

      await h.advanceTo(const Duration(seconds: 59));
      expect(h.namu.priceCalls, 2);
      await h.advanceTo(const Duration(seconds: 60));
      expect(h.namu.priceCalls, 3);
    });

    testWidgets('보유 탭에서는 관심 시세를 부르지 않는다', (tester) async {
      final h = await _pumpView(tester);

      await h.advanceTo(const Duration(minutes: 2));

      expect(h.namu.priceCalls, 0, reason: '아무도 안 보는 시세를 받았다');
    });

    testWidgets('앱이 가려진 동안은 건너뛰고, 돌아오면 다음 박자에 이어 받는다', (tester) async {
      final h = await _pumpView(tester);
      await h.openWatch();

      await h.advanceTo(const Duration(seconds: 5));
      await h.background();
      await h.advanceTo(const Duration(seconds: 65));
      expect(
        h.namu.priceCalls,
        1,
        reason: '앱이 안 보이는데 30초·60초 박자에 나무를 쳤다 — 웹도 탭이 가려지면 멈춘다',
      );

      await h.foreground();
      await h.advanceTo(const Duration(seconds: 95));
      expect(h.namu.priceCalls, 2, reason: '돌아왔는데 주기가 다시 안 돈다');
    });

    testWidgets('화면을 닫으면 더 묻지 않는다', (tester) async {
      // 타이머가 새는지는 여기 기대값이 아니라 테스트 틀이 잡는다 — 화면을 걷은 뒤에도
      // 남은 타이머가 있으면 "A Timer is still pending" 으로 이 테스트가 깨진다.
      final h = await _pumpView(tester);
      await h.openWatch();

      await h.close();
      await h.advanceTo(const Duration(minutes: 3));

      expect(h.namu.priceCalls, 1, reason: '화면이 없는데 시세를 계속 받는다');
    });

    testWidgets('실패해도 몰아서 다시 치지 않는다 — 다음 박자까지 기다린다', (tester) async {
      // riverpod 은 실패한 provider 를 기본으로 0.2초부터 두 배씩 최대 10번 다시 만든다.
      // 나무가 429(유량 초과)로 거절했을 때 그러면 한도를 넘긴 그 순간에 열 번을 더 친다.
      final h = await _pumpView(tester);
      h.namu.failPrice = true;
      await h.openWatch();
      expect(h.namu.priceCalls, 1);

      await h.advanceTo(const Duration(seconds: 20));
      expect(h.namu.priceCalls, 1, reason: '실패한 시세를 몰아서 다시 쳤다');

      await h.advanceTo(const Duration(seconds: 30));
      expect(h.namu.priceCalls, 2, reason: '다음 박자에는 다시 물어야 한다');
    });
  });

  // ─── 13-1 검수 고침(H2 · H3 · H4) ───────────────────────────
  group('재조회 — 값 유지 · 박자 · 위에 화면이 있을 때', () {
    testWidgets('H2 재조회가 실패해도 보던 보유 종목은 그대로 있고 실패 한 벌로 바뀌지 않는다', (
      tester,
    ) async {
      final h = await _pumpView(tester);
      expect(findTextContaining('보유화학 1차'), findsWidgets);

      h.namu.failHoldings = true;
      await h.background();
      await h.advanceTo(const Duration(seconds: 31));
      await h.foreground();

      expect(h.namu.calls('KRW'), 2, reason: '다시 받으러 갔는지');
      expect(
        findTextContaining('보유화학 1차'),
        findsWidgets,
        reason: '재조회 실패가 보던 값을 지웠다',
      );
      expect(findText('내 투자를 불러오지 못했어요'), findsNothing);
    });

    testWidgets('H3 환율은 10분마다 다시 받는다 — 그 전에는 안 받는다', (tester) async {
      final h = await _pumpView(tester);
      expect(h.namu.fxCalls, 1);

      await h.advanceTo(const Duration(minutes: 9, seconds: 59));
      expect(h.namu.fxCalls, 1, reason: '10분이 안 됐는데 환율을 또 받았다');

      await h.advanceTo(const Duration(minutes: 10));
      expect(h.namu.fxCalls, 2, reason: '10분이 지났는데 환율이 처음 값으로 굳어 있다');
    });

    testWidgets('H4 위에 다른 화면이 올라와 있으면 목록은 시세를 안 부르고, 돌아오면 이어서 부른다', (
      tester,
    ) async {
      final h = await _pumpView(tester);
      await h.openWatch();
      expect(h.namu.priceCalls, 1);

      final nav = Navigator.of(tester.element(find.byType(NamuStocksView)));
      nav.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await h.advanceTo(const Duration(seconds: 70));
      expect(
        h.namu.priceCalls,
        1,
        reason: '상세 · 시트가 위에 있는데 목록이 시세를 불렀다(호출 두 배)',
      );
      expect(h.namu.fxCalls, 1);

      nav.pop();
      await h.advanceTo(const Duration(seconds: 100));
      expect(h.namu.priceCalls, 2, reason: '돌아왔는데 다음 박자에도 안 부른다');
    });

    testWidgets('H4 박자마다 지켜보는 키만 부른다 — 다른 키(상세 시세 등)를 같이 비우지 않는다', (
      tester,
    ) async {
      final h = await _pumpView(tester);
      await h.openWatch();
      await h.advanceTo(const Duration(seconds: 65));
      expect(h.namu.priceCalls, 3);
      expect(h.namu.askedKeys.toSet(), {'A1'});
    });
  });

  // ─── 보유 종목 ──────────────────────────────────────────────
  group('보유 종목', () {
    testWidgets('들어올 때 국내 · 해외 한 번씩, 주기로 조르지 않는다', (tester) async {
      final h = await _pumpView(tester);
      expect(h.namu.calls('KRW'), 1, reason: '들어올 때 한 번 받는다');
      expect(h.namu.calls('USD'), 1);

      await h.advanceTo(const Duration(minutes: 5));

      expect(
        h.namu.holdingsCalls.length,
        2,
        reason: '웹은 보유 종목을 폴링하지 않는다 — 앱만 조르면 나무 유량 제한을 앱이 먼저 쓴다',
      );
    });

    testWidgets('앱으로 돌아왔을 때 30초가 지났으면 다시 받는다', (tester) async {
      final h = await _pumpView(tester);

      await h.background();
      await h.advanceTo(const Duration(seconds: 31));
      await h.foreground();

      expect(h.namu.calls('KRW'), 2);
      expect(h.namu.calls('USD'), 2);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data ?? '').replaceAll('\u2060', '').contains('보유화학 2차'),
        ),
        findsWidgets,
        reason: '새로 받은 값이 화면에 실려야 한다',
      );
    });

    testWidgets('30초가 안 지났으면 돌아와도 그대로 둔다', (tester) async {
      final h = await _pumpView(tester);

      await h.background();
      await h.advanceTo(const Duration(seconds: 20));
      await h.foreground();

      expect(h.namu.holdingsCalls.length, 2);
    });

    testWidgets('화면을 다시 열 때도 같은 규칙이다', (tester) async {
      final h = await _pumpView(tester);
      await h.close();
      await h.advanceTo(const Duration(seconds: 10));
      await h.open();
      expect(h.namu.holdingsCalls.length, 2, reason: '받은 지 10초 — 낡지 않았다');

      await h.close();
      await h.advanceTo(const Duration(seconds: 45));
      await h.open();
      expect(h.namu.calls('KRW'), 2, reason: '받은 지 30초가 넘었다 — 다시 받는다');
      expect(h.namu.calls('USD'), 2);
    });

    testWidgets('실패해도 몰아서 다시 치지 않고, 돌아오면 시각과 무관하게 다시 받는다', (tester) async {
      final h = await _pumpView(tester, failHoldings: true);
      expect(h.namu.holdingsCalls.length, 2);

      await h.advanceTo(const Duration(seconds: 20));
      expect(h.namu.holdingsCalls.length, 2, reason: '실패한 조회를 몰아서 다시 쳤다');

      h.namu.failHoldings = false;
      await h.background();
      await h.foreground();
      expect(h.namu.calls('KRW'), 2, reason: '실패한 조회는 늘 낡은 것으로 읽힌다');
    });
  });

  // ─── 판정 ───────────────────────────────────────────────────
  group('namuHoldingsStale', () {
    final fetchedAt = DateTime(2026, 9, 30, 9);

    test('받은 지 30초가 되기 전까지는 새 값이다', () {
      expect(
        namuHoldingsStale(
          fetchedAt,
          fetchedAt.add(const Duration(seconds: 29)),
        ),
        isFalse,
      );
    });

    test('정확히 30초면 낡았다 — 웹 react-query 와 같은 경계', () {
      expect(
        namuHoldingsStale(
          fetchedAt,
          fetchedAt.add(const Duration(seconds: 30)),
        ),
        isTrue,
      );
    });

    test('받은 적이 없으면 낡은 것이다', () {
      expect(namuHoldingsStale(null, fetchedAt), isTrue);
    });
  });

  test('박자는 웹 나무 화면과 같다', () {
    // 웹: WATCH_POLL_MS = 30_000 (NamuStocksPage) · staleTime: 30_000 (useNamuHoldings).
    // 앱에서 따로 줄이면 나무 유량 제한을 앱이 먼저 쓴다 — 바꿀 땐 웹과 같이 바꾼다.
    expect(namuPricePollInterval, const Duration(seconds: 30));
    expect(namuHoldingsStaleTime, const Duration(seconds: 30));
  });
}

// ─── 대역 ─────────────────────────────────────────────────────

/// 나무 보유 조회 대역 — **몇 번 불렸는지**만 센다. 부를 때마다 값이 달라진다.
class _CountingNamu extends NamuRepository {
  _CountingNamu() : super(Dio());

  /// 보유 종목을 물은 통화, 물은 순서대로.
  final holdingsCalls = <String>[];

  bool failHoldings = false;

  /// 관심 묶음 시세를 물은 횟수 — 시장 띠의 장 상태 조회(대표 종목 '000001')는 세지 않는다.
  int priceCalls = 0;
  int fxCalls = 0;
  int marketStateCalls = 0;

  /// 관심 시세를 물은 키(콤마 심볼 묶음), 물은 순서대로.
  final askedKeys = <String>[];
  bool failPrice = false;

  @override
  Future<List<NamuListQuote>> getListQuotes(List<String> symbols) async {
    if (!symbols.contains('A1')) {
      marketStateCalls++;
      return [
        for (final s in symbols)
          NamuListQuote(
            symbol: s,
            price: 70000,
            currency: 'KRW',
            marketState: 'REGULAR',
          ),
      ];
    }
    priceCalls++;
    askedKeys.add(symbols.join(','));
    if (failPrice) {
      throw ApiException(code: 'SEC_429', message: '유량 초과', statusCode: 429);
    }
    return [
      for (final s in symbols)
        NamuListQuote(
          symbol: s,
          price: 69000.0 + priceCalls * 1000,
          currency: 'KRW',
          previousClose: 69000,
        ),
    ];
  }

  @override
  Future<double?> getExchangeRate({String base = 'USD'}) async {
    fxCalls++;
    return 1385.2;
  }

  @override
  Future<BuyingPower?> getUsdDeposit() async => null;

  int calls(String currency) =>
      holdingsCalls.where((c) => c == currency).length;

  @override
  Future<NamuHoldings> getHoldings({
    String? accountNo,
    String currency = 'KRW',
  }) async {
    holdingsCalls.add(currency);
    if (failHoldings) {
      throw ApiException(code: 'SEC_429', message: '유량 초과', statusCode: 429);
    }
    final nth = calls(currency);
    return NamuHoldings(
      accountNo: 'test-account',
      currency: currency,
      totalEvalAmount: '1000',
      totalProfitLoss: '10',
      profitRate: '1.0',
      items: [
        NamuHoldingItem(
          symbol: '000001',
          name: '보유화학 $nth차',
          quantity: '3',
          avgPrice: '300',
          currentPrice: '333',
          evalAmount: '1000',
          profitLoss: '10',
        ),
      ],
    );
  }
}

/// 보유 종목의 "받은 지" 를 재는 시계 — 가짜 시계와 같이 민다.
class _FakeClock {
  DateTime now = DateTime(2026, 9, 30, 9);
}

StockWatchGroup _group() => StockWatchGroup(
  rowId: 1,
  groupName: '반도체',
  sortOrder: 1,
  items: [
    WatchItem(
      rowId: 11,
      stockMasterRowId: 1,
      countryCode: 'KR',
      marketCode: 'KOSPI',
      symbol: 'A1',
      nameKr: '숲길증권',
      securityType: 'STOCK',
      currency: 'KRW',
    ),
  ],
);

// ─── 하네스 ───────────────────────────────────────────────────

class _Harness {
  _Harness(this.tester, this.namu, this._clock, this._shown);
  final WidgetTester tester;
  final _CountingNamu namu;
  final _FakeClock _clock;
  final ValueNotifier<bool> _shown;

  /// 화면을 띄운 뒤 흐른 시간.
  Duration _elapsed = Duration.zero;

  /// 화면을 띄운 뒤 [sinceOpen] 이 될 때까지 시계를 민다 — 진짜로 기다리지 않는다.
  Future<void> advanceTo(Duration sinceOpen) async {
    assert(sinceOpen >= _elapsed, '이미 지난 시각이다');
    await _advance(sinceOpen - _elapsed);
  }

  Future<void> _advance(Duration d) async {
    _elapsed += d;
    _clock.now = _clock.now.add(d);
    await tester.pump(d);
    await _flush();
  }

  /// 관심 탭을 연다 — 보이는 묶음은 300ms 머문 뒤 시세를 부른다.
  Future<void> openWatch() async {
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w.runtimeType.toString() == 'ChipVisual' &&
            (w as dynamic).label == '관심',
      ),
    );
    await _flush();
    await _advance(const Duration(milliseconds: 400));
  }

  /// 화면을 닫는다(증권 화면에서 뒤로 가기).
  Future<void> close() async {
    _shown.value = false;
    await _flush();
  }

  /// 화면을 다시 연다.
  Future<void> open() async {
    _shown.value = true;
    await _flush();
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
    await _flush();
  }

  /// 조회 한 번은 `await` 를 몇 단계 거친다 — 시계는 안 밀고 프레임만 민다.
  /// `pumpAndSettle` 은 못 쓴다: 로딩 스켈레톤이 무한 애니메이션이라 안 끝난다.
  Future<void> _flush() async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }
}

Future<_Harness> _pumpView(
  WidgetTester tester, {
  bool failHoldings = false,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  // 앞 테스트가 백그라운드로 보낸 채 끝났을 수 있다 — 매번 앞에서 시작한다.
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/lifecycle',
    const StringCodec().encodeMessage(AppLifecycleState.resumed.toString()),
    (_) {},
  );

  final namu = _CountingNamu()..failHoldings = failHoldings;
  final clock = _FakeClock();
  final shown = ValueNotifier(true);
  addTearDown(shown.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        namuRepositoryProvider.overrideWith((ref) async => namu),
        watchGroupsProvider.overrideWith((ref) async => [_group()]),
        freshnessClockProvider.overrideWith(
          (ref) =>
              () => clock.now,
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (_, visible, _) =>
                visible ? const NamuStocksView() : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  final h = _Harness(tester, namu, clock, shown);
  await h._flush();
  return h;
}
