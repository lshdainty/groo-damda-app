/// 토스증권 Open API 연동 Riverpod providers.
/// 화면이 실패 한 벌로 보여 주는 provider 는 오류를 던지고(시세 · 호가 · 체결 · 보유 · 오늘 시세 · 투자자별 · 주문 가능 등),
/// 보조 값(전일 종가 · 마스터 검색 등)만 에러를 삼키고 null/빈 값으로 폴백한다.
library;

import 'package:groo_damda_app/core/clock/clock.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groo_damda_app/features/stocks/application/securities_retry.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/stocks_repository.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';

final stocksRepositoryProvider = FutureProvider<StocksRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return StocksRepository(dio);
});

/// 여러 종목 현재가 (콤마 조인 심볼 키 — 리스트 배치 1콜). 에러 시 빈 목록.
final tossPricesProvider = FutureProvider.family<List<TossPrice>, String>((
  ref,
  joinedSymbols,
) async {
  if (joinedSymbols.isEmpty) return const [];
  // 오류는 던진다 — 한 번 실패한 빈 목록이 "토스 시세 미지원 종목" 으로 읽히지 않는다(M8). 화면은 `.value` 로 이전 값을 둔다
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getPrices(joinedSymbols.split(','));
}, retry: securitiesNoRetry);

/// USD→KRW 환율. 오류는 던진다 — 삼킨 null 이 캐시돼 복구 못 하던 것을 막는다(H3). 화면 타이머가 60초마다 다시 받는다.
final tossExchangeRateProvider = FutureProvider<TossExchangeRate?>((ref) async {
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getExchangeRate();
}, retry: securitiesNoRetry);

/// 전일 종가. 토스 /prices 엔 기준가·등락률이 없어 일봉으로 도출한다.
/// 오늘 날짜 캔들을 제외한 마지막 종가 = 전일 종가 (장 시작 전이면 마지막 캔들이 곧 전일).
///
/// **다시 받는다**(N3): 받은 시장 날짜를 [prevCloseDayProvider] 에 적어 두고, 날이 바뀌면 호출부(목록 · 상세 타이머, 앱 복귀)가
/// [stalePrevCloseSymbols] 로 골라 비운다. **실패(null)는 캐시에 남기지 않는다** — 30초 뒤 스스로 다시 받는다.
final prevCloseProvider = FutureProvider.family<double?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    final page = await repo.getCandles(symbol, '1d', count: 3);
    final today = marketToday(symbol, ref.read(clockProvider)().toUtc());
    final v = prevCloseFromCandles(page.candles, today, symbol: symbol);
    if (ref.mounted) ref.read(prevCloseDayProvider)[symbol] = today;
    return v;
  } catch (_) {
    if (ref.mounted) {
      final t = Timer(const Duration(seconds: 30), ref.invalidateSelf);
      ref.onDispose(t.cancel);
    }
    return null;
  }
}, retry: securitiesNoRetry);

/// 전일 종가를 받은 시장 날짜 — 종목별. 성공한 조회만 적는다.
final prevCloseDayProvider = Provider<Map<String, String>>(
  (ref) => <String, String>{},
);

/// 날이 바뀐 종목의 전일 종가를 비운다(타이머 · 앱 복귀에서 부른다).
void refreshStalePrevCloses(WidgetRef ref) {
  for (final s in stalePrevCloseSymbols(
    ref.read(prevCloseDayProvider),
    ref.read(clockProvider)().toUtc(),
  )) {
    ref.invalidate(prevCloseProvider(s));
  }
}

/// 등락률(%) = (현재가 − 전일종가) / 전일종가. 어느 한쪽이 없으면 null.
double? changePctOf(double? lastPrice, double? prevClose) {
  if (lastPrice == null || prevClose == null || prevClose <= 0) return null;
  return (lastPrice - prevClose) / prevClose * 100;
}

/// 주식 랭킹 (발견 탭). 키 = "type|marketCountry|duration". 오류는 던진다("순위를 불러오지 못했어요").
final tossRankingsProvider = FutureProvider.family<TossRankingResponse, String>(
  (ref, key) async {
    final parts = key.split('|');
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return repo.getRankings(
      type: parts[0],
      marketCountry: parts[1],
      duration: parts[2],
    );
  },
  retry: securitiesNoRetry,
);

/// 국내 지수 현재가 (KOSPI·KOSDAQ). 오류는 던진다 — 시장 띠가 "시장 정보를 불러오지 못했어요" 를 보인다.
final tossIndicatorPricesProvider = FutureProvider<List<TossIndicatorPrice>>((
  ref,
) async {
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getIndicatorPrices(const ['KOSPI', 'KOSDAQ']);
}, retry: securitiesNoRetry);

/// 관심목록 (서버 stock-watch). 오류는 던진다 — 화면이 "관심 종목을 불러오지 못했어요" 로 보인다.
final watchGroupsProvider = FutureProvider<List<StockWatchGroup>>((ref) async {
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getWatchGroups();
});

/// 종목 호가 (라이브). 오류는 던진다.
final tossOrderbookProvider = FutureProvider.family<TossOrderbook?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  // 던진다 — 호가 표가 "호가를 불러오지 못했어요" 를 보인다(비어 있음과 다르다)
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return await repo.getOrderbook(symbol);
}, retry: securitiesNoRetry);

/// 종목 체결 내역 (라이브). 오류는 던진다.
final tossTradesProvider = FutureProvider.family<List<TossTrade>?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  // 던진다 — "체결 내역을 불러오지 못했어요"
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return await repo.getTrades(symbol);
}, retry: securitiesNoRetry);

/// 증권 계좌 목록 (개인 키). 오류는 던진다 — 화면이 "불러오지 못했어요" 로 보이고, 연결 안내와 가른다
/// (연결 여부는 셸이 먼저 거른다). 계좌가 없으면 빈 목록.
final tossAccountsProvider = FutureProvider<List<TossAccount>>((ref) async {
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getAccounts();
});

/// 보유 자산 현황 (첫 계좌 기준). 계좌 없음 → null(빈 상태), 오류 → 던진다(실패 한 벌).
final tossHoldingsProvider = FutureProvider<TossHoldings?>((ref) async {
  final accounts = await ref.watch(tossAccountsProvider.future);
  if (accounts.isEmpty) return null;
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getHoldings(accounts.first.accountSeq);
}, retry: securitiesNoRetry);

/// 지수 추이선 종가 — 실패해도 화면은 멀쩡하다(추이선만 빠진다).
final tossIndicatorClosesProvider = FutureProvider.family<List<double>, String>(
  (ref, symbol) async {
    try {
      final repo = await ref.watch(stocksRepositoryProvider.future);
      return await repo.getIndicatorCloses(symbol);
    } catch (_) {
      return const [];
    }
  },
  retry: securitiesNoRetry,
);

/// 캔들(차트·일별시세·등락률 실산출). interval '1m'(1D) / '1d'(장기).
/// 에러/미설정 시 null → 차트 빈 상태(의사난수 폴백 없음).
typedef CandleArg = ({String symbol, String interval});
final tossCandlesProvider = FutureProvider.family<TossCandlePage?, CandleArg>((
  ref,
  arg,
) async {
  if (arg.symbol.isEmpty) return null;
  // 던진다 — 일별 시세 "불러오지 못했어요"
  final repo = await ref.watch(stocksRepositoryProvider.future);
  // 토스 count 상한 200 초과는 repository 가 before 커서로 페이지네이션.
  final count = arg.interval == '1m' ? 390 : 252;
  return await repo.getCandles(arg.symbol, arg.interval, count: count);
});

/// 종목 기본정보(시장/유형/통화/상장일/발행주식수/거래상태). 에러/미설정 시 null.
final tossStockInfoProvider = FutureProvider.family<TossStockInfo?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  // 던진다 — 정보 실패를 "정상" 으로 그리지 않는다
  final repo = await ref.watch(stocksRepositoryProvider.future);
  final list = await repo.getStocks([symbol]);
  return list.isEmpty ? null : list.first;
});

/// 매수 유의사항. 에러/미설정/없음 시 빈 목록.
final tossWarningsProvider =
    FutureProvider.family<List<TossStockWarning>, String>((ref, symbol) async {
      if (symbol.isEmpty) return const [];
      try {
        final repo = await ref.watch(stocksRepositoryProvider.future);
        return await repo.getStockWarnings(symbol);
      } catch (_) {
        return const [];
      }
    });

/// 상/하한가(국내). 에러/미설정/해외 시 null.
final tossPriceLimitsProvider = FutureProvider.family<TossPriceLimit?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getPriceLimits(symbol);
  } catch (_) {
    return null;
  }
});

/// 국내 장 운영 일정. 오류는 던진다(시장 띠 실패 한 벌).
final tossMarketCalendarKrProvider = FutureProvider<TossKrMarketCalendar>((
  ref,
) async {
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getMarketCalendarKr();
}, retry: securitiesNoRetry);

/// 미국 장 운영 일정. 오류는 던진다(시장 띠 실패 한 벌).
final tossMarketCalendarUsProvider = FutureProvider<TossUsMarketCalendar>((
  ref,
) async {
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getMarketCalendarUs();
}, retry: securitiesNoRetry);

/// 종목 마스터 검색 (서버 stock_master — 국내 + 해외 6개국). 검색어별 캐시.
/// 에러(미기동 등) 시 빈 목록 → 화면은 코드 직접입력 폴백으로 동작.
final stockSearchProvider =
    FutureProvider.family<List<StockMasterItem>, String>((ref, query) async {
      final q = query.trim();
      if (q.isEmpty) return const [];
      try {
        final repo = await ref.watch(stocksRepositoryProvider.future);
        return await repo.searchStocks(q);
      } catch (_) {
        return const [];
      }
    });

/// 종목 찾기 시트의 검색 — 오류를 던진다(시트가 "검색 결과를 불러오지 못했어요" 를 보인다).
/// 자산의 종목 추가는 오류를 삼키는 [stockSearchProvider] 를 그대로 쓴다.
final stockSearchResultProvider =
    FutureProvider.family<List<StockMasterItem>, String>((ref, query) async {
      final q = query.trim();
      if (q.isEmpty) return const [];
      final repo = await ref.watch(stocksRepositoryProvider.future);
      return repo.searchStocks(q);
    });

/// 심볼 → 한글 종목명 (연결된 종목 표시용). 심볼 정확 일치만 취하고 없으면 null.
/// 국내 005930 과 상해 600519 처럼 시장 간 심볼이 겹칠 수 있어 토스 시세 대상(KR/US)을 우선한다.
final stockSymbolNameProvider = FutureProvider.family<String?, String>((
  ref,
  symbol,
) async {
  final sym = symbol.trim();
  if (sym.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    final items = await repo.searchStocks(sym, size: 20);
    final exact = items
        .where((s) => s.symbol.toUpperCase() == sym.toUpperCase())
        .toList();
    if (exact.isEmpty) return null;
    for (final s in exact) {
      if (s.countryCode == 'KR' || s.countryCode == 'US') return s.nameKr;
    }
    return exact.first.nameKr;
  } catch (_) {
    return null;
  }
});

/// 오늘 시세(토스) — 일봉 오늘 봉(시가 · 고가 · 저가 · 거래량). 전일 종가용 [prevCloseProvider] 와 따로 둔다
/// (그쪽은 하루 단위 값이라 갱신하지 않는다). 못 받으면 null.
final tossTodayCandlesProvider = FutureProvider.family<TossCandlePage?, String>(
  (ref, symbol) async {
    if (symbol.isEmpty) return null;
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return repo.getCandles(symbol, '1d', count: 3);
  },
  retry: securitiesNoRetry,
);

/// 투자자별 매매동향(토스, 국내 종목만 — 해외는 서버가 빈 목록). 상세를 열 때 한 번 · 5분.
final tossInvestorProvider = FutureProvider.autoDispose
    .family<List<InvestorTradingDay>, String>((ref, symbol) async {
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 5), link.close);
      ref.onDispose(timer.cancel);
      final repo = await ref.watch(stocksRepositoryProvider.future);
      return repo.getInvestorTrading(symbol);
    });

/// 주문 가능 금액(토스) — 키 = KRW | USD. 60초마다(화면이 보일 때) 다시 받는다. 실패는 던진다(값 "—").
final tossBuyingPowerProvider = FutureProvider.family<BuyingPower, String>((
  ref,
  currency,
) async {
  final accounts = await ref.watch(tossAccountsProvider.future);
  if (accounts.isEmpty) return BuyingPower(currency: currency);
  final repo = await ref.watch(stocksRepositoryProvider.future);
  return repo.getBuyingPower(accounts.first.accountSeq, currency: currency);
}, retry: securitiesNoRetry);
