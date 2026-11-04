import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/features/card/data/card_repository.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart'
    hide CardPerformance;
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/card/domain/card_performance.dart';

final cardRepositoryProvider = FutureProvider<CardRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return CardRepository(dio);
});

/// 카드 검색 키 — front 4개 필터 + 페이지네이션 모두 지원.
typedef CardSearchKey = ({
  String? keyword,
  String? cardType, // CREDIT/CHECK
  String? benefitType,
  bool? includeDiscontinued,
  int page,
  int size,
});

CardSearchKey defaultCardSearchKey({
  String? keyword,
  String? cardType,
  String? benefitType,
  bool? includeDiscontinued,
  int page = 0,
  int size = 30,
}) => (
  keyword: keyword,
  cardType: cardType,
  benefitType: benefitType,
  includeDiscontinued: includeDiscontinued,
  page: page,
  size: size,
);

/// 한 페이지 검색 결과 (메타 포함).
final cardCatalogPageProvider =
    FutureProvider.family<CardCatalogPage, CardSearchKey>((ref, key) async {
      final repo = await ref.watch(cardRepositoryProvider.future);
      return repo.searchPage(
        keyword: key.keyword,
        cardType: key.cardType,
        benefitType: key.benefitType,
        includeDiscontinued: key.includeDiscontinued,
        page: key.page,
        size: key.size,
      );
    });

/// 호환용 — content 만 반환.
final cardCatalogSearchProvider =
    FutureProvider.family<List<CardCatalogSummary>, CardSearchKey>((
      ref,
      key,
    ) async {
      final p = await ref.watch(cardCatalogPageProvider(key).future);
      return p.content;
    });

final cardCatalogDetailProvider = FutureProvider.autoDispose
    .family<CardCatalogDetail, int>((ref, id) async {
      final repo = await ref.watch(cardRepositoryProvider.future);
      return repo.detail(id);
    });

/// 카드 월 실적 조회 (#371).
typedef CardPerformanceKey = ({int assetRowId, String yearMonth});

final cardPerformanceProvider =
    FutureProvider.family<CardPerformance, CardPerformanceKey>((
      ref,
      key,
    ) async {
      final repo = await ref.watch(cardRepositoryProvider.future);
      return repo.performance(
        assetRowId: key.assetRowId,
        yearMonth: key.yearMonth,
      );
    });
