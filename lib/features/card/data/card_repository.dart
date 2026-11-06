import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart'
    hide CardPerformance;
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/card/domain/card_performance.dart';

class CardRepository {
  CardRepository(this._dio);
  final Dio _dio;

  /// 카드 카탈로그 검색 — content + 페이지 메타. front `cardCatalogApi.search` 미러.
  Future<CardCatalogPage> searchPage({
    String? keyword,
    String? cardType, // CREDIT/CHECK
    String? benefitType,
    bool? includeDiscontinued,
    int page = 0,
    int size = 30,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/card-catalogs',
        queryParameters: {
          'keyword': ?keyword,
          'cardType': ?cardType,
          'benefitType': ?benefitType,
          'includeDiscontinued': ?includeDiscontinued,
          'page': page,
          'size': size,
        },
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return CardCatalogPage.fromJson(body.data!);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 카드 카탈로그 검색 (호환용, content 만). 신규 코드는 [searchPage] 권장.
  Future<List<CardCatalogSummary>> search({
    String? keyword,
    String? cardType,
    String? benefitType,
    bool? includeDiscontinued,
    int page = 0,
    int size = 30,
  }) async {
    final p = await searchPage(
      keyword: keyword,
      cardType: cardType,
      benefitType: benefitType,
      includeDiscontinued: includeDiscontinued,
      page: page,
      size: size,
    );
    return p.content;
  }

  Future<CardCatalogDetail> detail(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/card-catalogs/$id');
      final body = ApiResponse<CardCatalogDetail>.fromJson(
        res.data ?? const {},
        (raw) => CardCatalogDetail.fromJson(raw! as Map<String, dynamic>),
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!;
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 카드(자산) 실적 조회. GET /card-performance?assetRowId&yearMonth=YYYY-MM.
  Future<CardPerformance> performance({
    required int assetRowId,
    required String yearMonth,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/card-performance',
        queryParameters: {'assetRowId': assetRowId, 'yearMonth': yearMonth},
      );
      final body = ApiResponse<CardPerformance>.fromJson(
        res.data ?? const {},
        (raw) => CardPerformance.fromJson(raw! as Map<String, dynamic>),
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!;
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}
