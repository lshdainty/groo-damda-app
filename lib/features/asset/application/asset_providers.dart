import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groo_damda_app/features/stocks/application/securities_retry.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/sync/query_freshness.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/domain/card_billing.dart';
import 'package:groo_damda_app/features/asset/domain/net_worth_point.dart';
import 'package:groo_damda_app/features/stocks/application/live_prices.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';

final assetRepositoryProvider = FutureProvider<AssetRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return AssetRepository(dio);
});

final assetsProvider = FutureProvider<List<Asset>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(assetRepositoryProvider.future);
  final assets = await repo.list();
  ref.markQueryFetched(ServerQuery.assets);
  return assets;
});

typedef AssetSummaryKey = ({int? year, int? month});

final assetSummaryProvider =
    FutureProvider.family<AssetSummary, AssetSummaryKey>((ref, key) async {
      final repo = await ref.watch(assetRepositoryProvider.future);
      final summary = await repo.summary(year: key.year, month: key.month);
      ref.markQueryFetched(ServerQuery.assetSummary);
      return summary;
    });

/// 최근 N개월 순자산 추이 (기본 12개월).
final netWorthTrendProvider = FutureProvider.family<List<NetWorthPoint>, int>((
  ref,
  months,
) async {
  ref.keepAlive();
  final repo = await ref.watch(assetRepositoryProvider.future);
  final points = await repo.netWorthTrend(months: months);
  ref.markQueryFetched(ServerQuery.netWorthTrend);
  return points;
});

/// 단건 자산 (상세 화면 진입용).
final assetByIdProvider = FutureProvider.family<Asset, int>((ref, id) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getById(id);
});

/// 자산 잔액 추이 (주별, 기본 12주).
typedef AssetBalanceTrendKey = ({int assetId, int weeks});

final assetBalanceTrendProvider =
    FutureProvider.family<List<AssetBalancePoint>, AssetBalanceTrendKey>((
      ref,
      key,
    ) async {
      final repo = await ref.watch(assetRepositoryProvider.future);
      return repo.balanceTrend(key.assetId, weeks: key.weeks);
    });

/// 자산 이체 내역 (옵션 startDate/endDate).
typedef AssetTransfersKey = ({String? startDate, String? endDate});

final assetTransfersProvider =
    FutureProvider.family<List<AssetTransfer>, AssetTransfersKey>((
      ref,
      key,
    ) async {
      final repo = await ref.watch(assetRepositoryProvider.future);
      final transfers = await repo.listTransfers(
        startDate: key.startDate,
        endDate: key.endDate,
      );
      ref.markQueryFetched(ServerQuery.assetTransfers);
      return transfers;
    });

/// 신용카드 청구 사이클 (결제예정액·예정일·청구이력).
/// 카드 상세 진입 시 조회. `payCard` 후 invalidate.
final cardBillingProvider = FutureProvider.family<CardBilling, int>((
  ref,
  assetId,
) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getCardBilling(assetId);
});

/// 통화가 KRW 가 아니면(해외 종목) 환율 환산 대상.
/// 투자 자산 라이브 평가 1건 — 평가액(KRW) + 전일 대비 등락액(계산 가능할 때만).
typedef InvestmentValuation = ({int value, int? changeAmt});

/// 투자 자산 라이브 평가 맵 (assetRowId → 평가액·등락액).
///
/// - holdings 가 있는 자산(신규 모델): 평가액 = Σ 직접입력(holdingValue)
///   + Σ 연동(현재가 × 수량, 해외 종목은 환율로 KRW 환산).
///   시세·환율은 **증권사 무관 경로**(/securities/**)로 받는다 — 서버가 사용자가 고른 기본
///   소스로 대신 조회하므로 앱이 증권사를 알 필요가 없다. 예전에는 토스 경로를 직접 불러
///   나무만 연결한 사용자의 평가액이 0/누락으로 보였다.
///   연동 보유의 가격을 하나라도 못 구하면 그 자산은 맵에서 제외(서버 스냅샷 잔액 유지).
///   등락액 = Σ 연동 (현재가 − 전일종가) × 수량 — 전일종가가 조회된 종목만 합산,
///   하나도 없으면 null(등락 미표시).
/// - holdings 가 없는 자산: 기존 tossSymbol/tossQuantity 단일 연동 경로(deprecated) 유지.
/// - 직접입력만 있는 자산은 시세가 불필요하므로 게이트(프로+증권사연결)와 무관하게 평가.
/// - **시세를 새로 받으려면 [refreshLiveValuation] 을 쓴다.** 이 provider 만 무효화하면 받아
///   둔 시세로 다시 계산할 뿐이다 — 시세는 [livePricesProvider] 에 있고 그건 스스로 안 비워진다.
/// - 다시 받다 실패하면 **직전 시세로** 평가한다. 한 번도 못 받았을 때만 서버 잔액이다.
final investmentValuationMapProvider =
    FutureProvider<Map<int, InvestmentValuation>>((ref) async {
      final features = ref.watch(myFeaturesProvider).asData?.value;
      final enabled =
          (features?.hasSecurities ?? false) &&
          (features?.hasBrokerConnection ?? false);
      final assets = await ref.watch(assetsProvider.future);

      final targets = assets.where((a) => a.assetType == 'INVESTMENT').toList();
      if (targets.isEmpty) return const {};

      // 시세가 필요한 심볼 수집 — holdings 의 linked + 레거시 단일 연동.
      final symbols = valuationSymbolsOf(targets);

      // 시세·통화별 환율·전일종가 조달은 livePricesProvider 한 곳에 있다 —
      // 자산 상세·추가/편집도 같은 걸 써야 한 화면에서 금액이 어긋나지 않는다.
      LivePrices live = const LivePrices.empty();
      if (enabled && symbols.isNotEmpty) {
        final key = livePricesKey(symbols);
        try {
          live = await ref.watch(livePricesProvider(key).future);
        } catch (_) {
          // 다시 받다 실패하면 직전에 받은 시세로 평가한다 — 웹(react-query)이 실패한 재조회
          // 동안 앞 데이터를 그대로 보여 주는 것과 같다. 안 그러면 증권사가 한 번 거절할
          // 때마다 평가액이 서버 잔액으로 뛰었다가 10초 뒤 돌아온다. 실패 상태도 앞 값을
          // 들고 있다(riverpod `AsyncError.copyWithPrevious`). 한 번도 못 받았으면 빈 시세다.
          live =
              ref.read(livePricesProvider(key)).value ??
              const LivePrices.empty();
        }
      }

      double? unitKrw(String symbol) => live.unitKrw(symbol);
      double? unitPrevKrw(String symbol) => live.prevUnitKrw(symbol);

      final map = <int, InvestmentValuation>{};
      for (final a in targets) {
        if (a.holdings.isNotEmpty) {
          var total = 0.0;
          var change = 0.0;
          var hasChange = false;
          var priceable = true;
          for (final h in a.holdings) {
            if (h.linked) {
              final sym = h.tossSymbol ?? '';
              final unit = sym.isEmpty ? null : unitKrw(sym);
              if (unit == null) {
                priceable = false;
                break; // 연동가 미확보 — 서버 스냅샷 잔액 유지.
              }
              // 라이브 표시용 오버레이 계산 — 저장되는 평가액은 서버가 BigDecimal 로 산정한다.
              final qty = h.quantityValue;
              total += unit * qty;
              final prevUnit = unitPrevKrw(sym);
              if (prevUnit != null) {
                change += (unit - prevUnit) * qty;
                hasChange = true;
              }
            } else {
              total += (h.holdingValue ?? 0).toDouble();
            }
          }
          if (!priceable) continue;
          map[a.rowId] = (
            value: total.round(),
            changeAmt: hasChange ? change.round() : null,
          );
        } else if ((a.tossSymbol?.isNotEmpty ?? false) &&
            a.tossQuantity != null) {
          final unit = unitKrw(a.tossSymbol!);
          if (unit == null) continue;
          final qty = a.tossQuantity!;
          final prevUnit = unitPrevKrw(a.tossSymbol!);
          map[a.rowId] = (
            value: (unit * qty).round(),
            changeAmt: prevUnit != null
                ? ((unit - prevUnit) * qty).round()
                : null,
          );
        }
      }
      return map;
    }, retry: securitiesNoRetry);

/// 평가에 시세가 필요한 심볼 — holdings 의 linked + 레거시 단일 연동.
Set<String> valuationSymbolsOf(Iterable<Asset> investments) {
  final symbols = <String>{};
  for (final a in investments) {
    if (a.holdings.isNotEmpty) {
      for (final h in a.holdings) {
        if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) {
          symbols.add(h.tossSymbol!);
        }
      }
    } else if ((a.tossSymbol?.isNotEmpty ?? false) && a.tossQuantity != null) {
      symbols.add(a.tossSymbol!);
    }
  }
  return symbols;
}

/// 평가에 쓰는 시세를 지금 못 받고 있다(처음 · 다시 받기 모두) — 그동안 평가액은 서버 잔액(한 번도 못 받음) 또는 직전 시세다.
/// 숫자는 두고 그 카드에 "시세를 불러오지 못했어요" 띠를 단다(I-wrap-b2b 4). 시세를 쓰지 않는 사용자(게이트 꺼짐 · 연동 보유
/// 없음)는 늘 거짓이다. [investmentValuationMapProvider] 와 같은 키를 지켜봐 요청이 더 나가지 않는다.
final valuationPriceFailedProvider = Provider<bool>((ref) {
  final features = ref.watch(myFeaturesProvider).asData?.value;
  final enabled =
      (features?.hasSecurities ?? false) &&
      (features?.hasBrokerConnection ?? false);
  if (!enabled) return false;
  final assets = ref.watch(assetsProvider).value ?? const <Asset>[];
  final symbols = valuationSymbolsOf(
    assets.where((a) => a.assetType == 'INVESTMENT'),
  );
  if (symbols.isEmpty) return false;
  return ref.watch(livePricesProvider(livePricesKey(symbols))).hasError;
});

/// 자산 화면의 실시간 평가를 새로 받는다 — **시세 조회까지** 무효화한다.
///
/// 평가 맵([investmentValuationMapProvider])만 무효화하면 받아 둔 시세로 다시 계산할 뿐이다.
/// 시세는 [livePricesProvider] 에 들어 있고 그 provider 는 스스로 비워지지 않는다.
/// 2026-08-25 시세 조회를 그쪽으로 모은 뒤(`31105a0`) 자산 화면의 10초 타이머가 평가 맵만
/// 밀어서, 앱을 켤 때 받은 시세가 다시 켤 때까지 그대로였다(웹은 10초마다 다시 받았다).
///
/// 시세가 바뀌면 그걸 읽는 평가 맵·상세·추가/편집이 함께 다시 계산된다. 평가 맵도 같이 미는
/// 건 시세 말고 다른 것(자산 목록 등)이 바뀐 경우까지 한 번에 맞추려는 것이다.
///
/// [invalidate] 는 화면이면 `ref.invalidate`, 테스트면 `container.invalidate` 를 넘긴다.
void refreshLiveValuation(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(livePricesProvider);
  invalidate(investmentValuationMapProvider);
}

/// (호환) 토스 연동 투자 자산의 라이브 평가액(KRW) 맵 — investmentValuationMapProvider 의 value 투영.
final tossValuationMapProvider = FutureProvider<Map<int, int>>((ref) async {
  final m = await ref.watch(investmentValuationMapProvider.future);
  return {for (final e in m.entries) e.key: e.value.value};
});

extension AssetListX on List<Asset> {
  Asset? byRowId(int rowId) {
    for (final a in this) {
      if (a.rowId == rowId) return a;
    }
    return null;
  }
}

/// 자산의 매수·매도 내역 — 언제 사고 팔았는지, 실현손익이 얼마인지.
final assetTradesProvider = FutureProvider.family<List<AssetTrade>, int>((
  ref,
  assetRowId,
) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getTrades(assetRowId);
});
