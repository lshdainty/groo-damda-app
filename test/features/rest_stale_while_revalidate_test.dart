// 다시 받는 동안 이전 값을 그대로 보여 준다 — **탭 밖에 남아 있던** 자리들.
//
// 규칙은 PR #347(여섯 탭 화면)이 정한 것 그대로다: 판정은 `isLoading && !hasValue`
// 하나. 이전 값이 있으면 그대로 그리고, 값이 아예 없을 때만 스켈레톤이다.
// 빈 목록도 **받아 온 값**이라 스켈레톤이 아니라 빈 상태 문구가 맞다.
//
// 여기서 잠그는 자리와 그 자리를 껌뻑이게 하던 재조회:
//   - 예산 설정 카테고리 카드 — 당겨서 새로고침(`rangeSummary` 무효화)
//   - 프리셋 목록·통계 3카드 — 당겨서 새로고침(`presetList` 무효화)
//   - 자산 상세 잔액 추이·최근 거래 — 거래/자산 변경 후 일괄 무효화
//   - 증권 호가·체결·일별 시세 — `TossStocksView` 의 **10초 시세 폴링**
//   - 증권 발견 랭킹 — 같은 규칙(폴링 대상은 아니지만 판정을 한 벌로 맞춘다)
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 직접 띄워 확인한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 는 flutter_riverpod 본체가 아니라 misc 에서 나온다.
import 'package:flutter_riverpod/misc.dart' show Override, ProviderOrFamily;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../support/plain_text.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart' as dsskel;
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';

import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_settings_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_screen.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';

/// 첫 조회만 값을 주고 **그 뒤 재조회는 끝나지 않는다** — 화면을
/// "다시 받는 중(이전 값 보유)" 상태로 굳혀 놓고 무엇을 그리는지 본다.
///
/// family provider 는 키마다 따로 센다 — 한 벌로 세면 키가 여럿인 자리에서
/// 두 번째 키가 첫 조회조차 못 받는다.
class _ServeOnce<K, T> {
  _ServeOnce(this._build);
  final T Function(K key) _build;
  final _served = <K>{};

  Future<T> call(K key) {
    if (!_served.add(key)) return Completer<T>().future;
    return Future<T>.value(_build(key));
  }
}

/// 키가 없는 provider 용.
class _ServeOnceSingle<T> {
  _ServeOnceSingle(this._build);
  final T Function() _build;
  var _served = false;

  Future<T> call() {
    if (_served) return Completer<T>().future;
    _served = true;
    return Future<T>.value(_build());
  }
}

ProviderContainer _containerOf(WidgetTester tester, Finder anchor) =>
    ProviderScope.containerOf(tester.element(anchor), listen: false);

/// 재조회를 그대로 재현한다 — `ref.invalidate` 한 뒤 한 프레임.
///
/// **`Duration.zero` 를 빼면 안 된다.** Riverpod 은 무효화를 0초 `Timer` 로
/// 흘려보내는데(`UncontrolledProviderScope._flutterVsync`), 인자 없는 `pump()` 는
/// 가짜 시계를 돌리지 않아 그 타이머가 뜨지 않는다. 그러면 화면은 재조회를
/// 아예 못 보고 테스트는 **아무것도 확인하지 않은 채** 통과한다.
Future<void> _refetch(
  WidgetTester tester,
  ProviderContainer container,
  ProviderOrFamily provider,
) async {
  container.invalidate(provider);
  await tester.pump(Duration.zero);
}

/// 한 화면이 세로로 다 들어가는 뷰포트 — 화면 아래쪽 카드도 build 된다
/// (`ListView` 는 화면 밖 자식을 mount 하지 않아 `find` 가 못 본다).
void _tallView(WidgetTester tester, {double height = 3600}) {
  tester.view.physicalSize = Size(390 * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: home),
  ),
);

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  final now = DateTime.now();

  // ─── 예산 설정 ──────────────────────────────────────────────────────────
  //
  // 카테고리 예산 카드는 **`rangeSummary`**(카테고리별 사용액)를 보고 스켈레톤을
  // 그렸다. 당겨서 새로고침이 그 조회를 비우므로, 카테고리 예산이 하나도 없는
  // 사용자는 새로고침할 때마다 빈 상태 문구가 스켈레톤으로 바뀌었다.
  group('예산 설정 — 카테고리 예산 카드', () {
    Future<void> pump(WidgetTester tester, {required bool serveSummary}) async {
      _tallView(tester, height: 2000);
      final summary = _ServeOnce<DateRange, RangeSummary>(
        (key) => RangeSummary(startDate: key.startDate, endDate: key.endDate),
      );
      await tester.pumpWidget(
        _app(const BudgetSettingsScreen(), [
          categoriesProvider.overrideWith((ref) async => const []),
          monthBudgetsProvider.overrideWith(
            (ref, key) async => const <Budget>[],
          ),
          rangeSummaryProvider.overrideWith(
            serveSummary
                ? (ref, key) => summary(key)
                : (ref, key) => Completer<RangeSummary>().future,
          ),
        ]),
      );
    }

    testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
      await pump(tester, serveSummary: false);
      await tester.pump();

      // 스켈레톤은 무한 애니메이션이라 pumpAndSettle 이 아니라 pump 로 본다.
      expect(find.byType(dsskel.PSkeleton), findsWidgets);
    });

    testWidgets('빈 목록은 스켈레톤이 아니라 빈 상태 문구다', (tester) async {
      await pump(tester, serveSummary: true);
      await tester.pumpAndSettle();

      expect(findPlain('설정된 카테고리 예산이 없어요'), findsOneWidget);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });

    testWidgets('재조회 중에도 빈 상태 문구가 그대로 — 스켈레톤이 끼어들지 않는다', (tester) async {
      await pump(tester, serveSummary: true);
      await tester.pumpAndSettle();

      await _refetch(
        tester,
        _containerOf(tester, find.byType(BudgetSettingsScreen)),
        rangeSummaryProvider,
      );

      expect(findPlain('설정된 카테고리 예산이 없어요'), findsOneWidget);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });
  });

  // ─── 프리셋 ────────────────────────────────────────────────────────────
  group('프리셋 — 목록·통계', () {
    Future<void> pump(WidgetTester tester, {required bool serveList}) async {
      _tallView(tester, height: 2000);
      final list = _ServeOnceSingle<List<ExpenseTemplate>>(
        () => const [
          ExpenseTemplate(
            rowId: 1,
            templateName: '점심 커피',
            expenseType: 'EXPENSE',
            amount: 4500,
          ),
        ],
      );
      await tester.pumpWidget(
        _app(const PresetScreen(), [
          categoriesProvider.overrideWith((ref) async => const []),
          presetListProvider.overrideWith(
            serveList
                ? (ref) => list()
                : (ref) => Completer<List<ExpenseTemplate>>().future,
          ),
        ]),
      );
    }

    testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
      await pump(tester, serveList: false);
      await tester.pump();

      expect(find.byType(PSkeleton), findsWidgets);
    });

    testWidgets('재조회 중에도 이전 프리셋이 그대로 보인다', (tester) async {
      await pump(tester, serveList: true);
      await tester.pumpAndSettle();
      expect(findText('점심 커피'), findsOneWidget);

      await _refetch(
        tester,
        _containerOf(tester, find.byType(PresetScreen)),
        presetListProvider,
      );

      expect(findText('점심 커피'), findsOneWidget);
      expect(find.byType(PSkeleton), findsNothing);
    });
  });

  // ─── 자산 상세 ──────────────────────────────────────────────────────────
  //
  // 상세 시트는 열린 채로 거래를 고칠 수 있고, 그때 잔액 추이·최근 거래가
  // 함께 무효화된다(`invalidateAfterExpenseChange`). 두 자리는 "값이 없다" 를
  // `list.isEmpty` 로 봤다 — 거래가 하나도 없는 자산은 고칠 때마다 빈 상태
  // 문구가 스켈레톤으로 바뀌었다 돌아온다. 빈 목록도 **받아 온 값**이다.
  group('자산 상세 — 잔액 추이·최근 거래', () {
    const asset = Asset(
      rowId: 7,
      assetName: '주거래',
      assetType: 'BANK_ACCOUNT',
      balance: 1000000,
      isIncludedInTotal: 'Y',
    );

    Future<void> open(
      WidgetTester tester, {
      required bool serve,
      List<AssetBalancePoint> trendValue = const [],
      List<Expense> recentValue = const [],
    }) async {
      _tallView(tester, height: 2600);
      final trend = _ServeOnce<AssetBalanceTrendKey, List<AssetBalancePoint>>(
        (_) => trendValue,
      );
      final recent = _ServeOnce<AssetExpensesKey, List<Expense>>(
        (_) => recentValue,
      );
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetDetailRich(ctx, asset),
              child: const Text('열기'),
            ),
          ),
          [
            assetsProvider.overrideWith((ref) async => const [asset]),
            assetTransfersProvider.overrideWith((ref, key) async => const []),
            assetBalanceTrendProvider.overrideWith(
              serve
                  ? (ref, key) => trend(key)
                  : (ref, key) => Completer<List<AssetBalancePoint>>().future,
            ),
            expensesByAssetProvider.overrideWith(
              serve
                  ? (ref, key) => recent(key)
                  : (ref, key) => Completer<List<Expense>>().future,
            ),
          ],
        ),
      );
      await tester.tap(findText('열기'));
      // 스켈레톤은 무한 애니메이션이라 `pumpAndSettle` 이 영원히 안 끝난다 —
      // 시트 열림 애니메이션 + 응답 반영에 필요한 만큼만 프레임을 민다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(Duration.zero);
    }

    testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
      await open(tester, serve: false);
      await tester.pump();

      expect(find.byType(PSkeleton), findsWidgets);
    });

    testWidgets('빈 목록은 스켈레톤이 아니라 빈 상태 문구다', (tester) async {
      await open(tester, serve: true);

      expect(findText('표시할 데이터가 없어요'), findsOneWidget);
      expect(findText('연결된 거래 내역이 없어요.'), findsOneWidget);
      expect(find.byType(PSkeleton), findsNothing);
    });

    testWidgets('재조회 중에도 빈 상태 문구가 그대로 — 스켈레톤이 끼어들지 않는다', (tester) async {
      await open(tester, serve: true);

      final container = _containerOf(tester, find.byType(MaterialApp));
      await _refetch(tester, container, assetBalanceTrendProvider);
      await _refetch(tester, container, expensesByAssetProvider);

      expect(findText('표시할 데이터가 없어요'), findsOneWidget);
      expect(findText('연결된 거래 내역이 없어요.'), findsOneWidget);
      expect(find.byType(PSkeleton), findsNothing);
    });

    testWidgets('재조회 중에도 이전 거래가 그대로 보인다', (tester) async {
      await open(
        tester,
        serve: true,
        trendValue: const [
          AssetBalancePoint(weekStart: '2026-08-01', balance: 900000),
          AssetBalancePoint(weekStart: '2026-09-01', balance: 1000000),
        ],
        recentValue: [
          Expense(
            rowId: 1,
            expenseType: 'EXPENSE',
            amount: 12000,
            description: '점심값',
            expenseDate: '${_ymd(now)}T00:00:01',
          ),
        ],
      );
      expect(findPlain('점심값'), findsWidgets);

      final container = _containerOf(tester, find.byType(MaterialApp));
      await _refetch(tester, container, assetBalanceTrendProvider);
      await _refetch(tester, container, expensesByAssetProvider);

      expect(findPlain('점심값'), findsWidgets);
      expect(find.byType(PSkeleton), findsNothing);
    });
  });

  // ─── 증권 ──────────────────────────────────────────────────────────────
  //
  // `TossStocksView` 는 **10초마다** 호가·체결·캔들을 통째로 무효화한다
  // (`_priceTimer`). 그때마다 스켈레톤을 깔면 들고 있던 시세가 10초마다
  // 사라졌다 돌아온다 — 시세판은 새 값이 닿을 때까지 직전 값을 보여 주는 자리다.
  group('증권', () {
    const symbol = '005930';

    /// 오버라이드하지 않은 증권 provider 는 전부 저장소 에러를 삼키고
    /// null/빈 값으로 떨어진다 — 이 테스트가 보는 네 조회만 남는다.
    /// `dioProvider` 도 막아 차트 WebView 가 컨트롤러를 만들지 않게 한다
    /// (테스트 바인딩에는 WebView 플랫폼 구현이 없다).
    List<Override> base() => [
      dioProvider.overrideWith((ref) async => throw StateError('no dio')),
      stocksRepositoryProvider.overrideWith(
        (ref) async => throw StateError('no repo'),
      ),
    ];

    Future<void> pumpDiscover(
      WidgetTester tester,
      List<Override> overrides,
    ) async {
      _tallView(tester, height: 3200);
      await tester.pumpWidget(_app(const TossStocksView(), overrides));
      await tester.pump(Duration.zero);
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w.runtimeType.toString() == 'ChipVisual' &&
              (w as dynamic).label == '발견',
        ),
      );
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
    }

    // ── 발견 랭킹 ────────────────────────────────────────────────────────
    group('발견 랭킹', () {
      _ServeOnce<String, TossRankingResponse> rankings() =>
          _ServeOnce<String, TossRankingResponse>(
            (_) => const TossRankingResponse(
              rankings: [
                TossRankingItem(
                  rank: 1,
                  symbol: symbol,
                  currency: 'KRW',
                  price: TossRankingPrice(
                    lastPrice: '71000',
                    basePrice: '70000',
                  ),
                  tradingVolume: '100',
                  tradingAmount: '1000',
                ),
              ],
            ),
          );

      testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
        await pumpDiscover(tester, [
          ...base(),
          tossRankingsProvider.overrideWith(
            (ref, key) => Completer<TossRankingResponse>().future,
          ),
        ]);

        expect(find.byType(dsskel.PSkeleton), findsWidgets);
      });

      testWidgets('재조회 중에도 이전 랭킹이 그대로 보인다', (tester) async {
        final serve = rankings();
        await pumpDiscover(tester, [
          ...base(),
          tossRankingsProvider.overrideWith((ref, key) => serve(key)),
        ]);
        // `_StockRow` 는 이름(마스터 미조회 → 심볼 폴백)과 부제로 심볼을 두 번 쓴다.
        expect(findPlain(symbol), findsNWidgets(2));

        await _refetch(
          tester,
          _containerOf(tester, find.byType(TossStocksView)),
          tossRankingsProvider,
        );

        expect(findPlain(symbol), findsNWidgets(2));
        expect(find.byType(dsskel.PSkeleton), findsNothing);
      });
    });

    // ── 종목 상세: 호가 · 체결 · 일별 시세 ─────────────────────────────────
    //
    // 세 조회가 다 오면 이 시트에는 스켈레톤이 하나도 없다 — `PSkeleton` 이
    // 다시 나타나면 그게 곧 껌뻑임이다.
    group('종목 상세', () {
      const orderbook = TossOrderbook(
        asks: [TossOrderbookEntry(price: '71200', volume: '10')],
        bids: [TossOrderbookEntry(price: '71100', volume: '20')],
      );
      const trades = [
        TossTrade(price: '71150', volume: '7', timestamp: '10:11:12'),
      ];
      const candles = TossCandlePage(
        candles: [
          TossCandle(
            timestamp: '2026-09-01T00:00:00',
            openPrice: '70000',
            highPrice: '70500',
            lowPrice: '69500',
            closePrice: '70000',
            volume: '100',
          ),
          TossCandle(
            timestamp: '2026-09-02T00:00:00',
            openPrice: '70000',
            highPrice: '71500',
            lowPrice: '70000',
            closePrice: '71300',
            volume: '120',
          ),
        ],
      );

      /// 상세 화면(주소로 여는 페이지)을 바로 띄운다.
      Future<void> openDetail(
        WidgetTester tester,
        List<Override> overrides,
      ) async {
        _tallView(tester, height: 3200);
        await tester.pumpWidget(
          _app(const TossStockDetailPage(symbol: symbol), [
            ...base(),
            // 통화를 모르면 숫자만 보인다(M10) — 시세 응답이 통화를 준다
            tossPricesProvider.overrideWith(
              (ref, k) async => const [
                TossPrice(symbol: symbol, lastPrice: '71000', currency: 'KRW'),
              ],
            ),
            ...overrides,
          ]),
        );
        // 스켈레톤은 무한 애니메이션이라 `pumpAndSettle` 이 안 끝난다 —
        // 응답 반영에 필요한 만큼만 프레임을 민다.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(Duration.zero);
      }

      testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
        await openDetail(tester, [
          tossOrderbookProvider.overrideWith(
            (ref, s) => Completer<TossOrderbook?>().future,
          ),
          tossTradesProvider.overrideWith(
            (ref, s) => Completer<List<TossTrade>?>().future,
          ),
          tossCandlesProvider.overrideWith(
            (ref, a) => Completer<TossCandlePage?>().future,
          ),
        ]);

        expect(find.byType(dsskel.PSkeleton), findsWidgets);
      });

      testWidgets('10초 폴링 재조회 — 호가가 그대로 남는다', (tester) async {
        final serve = _ServeOnce<String, TossOrderbook?>((_) => orderbook);
        await openDetail(tester, [
          tossOrderbookProvider.overrideWith((ref, s) => serve(s)),
          tossTradesProvider.overrideWith((ref, s) async => trades),
          tossCandlesProvider.overrideWith((ref, a) async => candles),
        ]);
        expect(findText('71,200원'), findsOneWidget);
        expect(find.byType(dsskel.PSkeleton), findsNothing);

        await _refetch(
          tester,
          _containerOf(tester, find.byType(TossStockDetailPage)),
          tossOrderbookProvider,
        );

        expect(findText('71,200원'), findsOneWidget);
        expect(find.byType(dsskel.PSkeleton), findsNothing);
      });

      testWidgets('10초 폴링 재조회 — 체결 테이프가 그대로 남는다', (tester) async {
        final serve = _ServeOnce<String, List<TossTrade>?>((_) => trades);
        await openDetail(tester, [
          tossOrderbookProvider.overrideWith((ref, s) async => orderbook),
          tossTradesProvider.overrideWith((ref, s) => serve(s)),
          tossCandlesProvider.overrideWith((ref, a) async => candles),
        ]);
        await tester.tap(findPlain('체결'));
        await tester.pump(Duration.zero);
        expect(findText('오전 10:11'), findsOneWidget);
        expect(find.byType(dsskel.PSkeleton), findsNothing);

        await _refetch(
          tester,
          _containerOf(tester, find.byType(TossStockDetailPage)),
          tossTradesProvider,
        );

        expect(findText('오전 10:11'), findsOneWidget);
        expect(find.byType(dsskel.PSkeleton), findsNothing);
      });

      testWidgets('10초 폴링 재조회 — 일별 시세 표가 그대로 남는다', (tester) async {
        final serve = _ServeOnce<CandleArg, TossCandlePage?>((_) => candles);
        await openDetail(tester, [
          tossOrderbookProvider.overrideWith((ref, s) async => orderbook),
          tossTradesProvider.overrideWith((ref, s) async => trades),
          tossCandlesProvider.overrideWith((ref, a) => serve(a)),
        ]);
        expect(findPlain('9월 2일'), findsOneWidget);
        expect(find.byType(dsskel.PSkeleton), findsNothing);

        await _refetch(
          tester,
          _containerOf(tester, find.byType(TossStockDetailPage)),
          tossCandlesProvider,
        );

        expect(findPlain('9월 2일'), findsOneWidget);
        expect(find.byType(dsskel.PSkeleton), findsNothing);
      });
    });
  });
}
