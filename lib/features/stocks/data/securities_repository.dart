/// 증권사 무관 시세 repository — 백엔드 프록시 `/api/v1/securities/**`.
/// Dio baseUrl 이 이미 `/api/v1` 이므로 경로는 `/securities/...`.
///
/// **왜 토스 경로를 안 쓰나** — 가계부 자산 화면은 현재가와 환율만 있으면 되는데,
/// `/toss/**` 를 직접 부르면 **나무만 연결한 사용자가 403 을 맞아 평가액이 0/누락으로**
/// 보인다. 여기서는 서버가 사용자가 고른 기본 소스로 대신 조회한다.
///
/// 증권사별 조회(`/toss/**` · `/namu/**`)는 증권 화면이 그대로 쓴다 — 증권사마다
/// 보여주는 게 달라 합칠 수 없다.
library;

import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';

/// 증권사 무관 현재가. 금액은 JSON 숫자로 온다(서버가 BigDecimal 로 계산해 내린다).
class BrokerQuote {
  const BrokerQuote({
    required this.symbol,
    required this.price,
    required this.currency,
    this.previousClose,
  });

  final String symbol;
  final double price;
  final String currency;

  /// 전일 종가. **못 주는 증권사가 있어 null 이 될 수 있다** — 나무는 시세 응답에 전일대비가
  /// 딸려 와 공짜로 채우지만, 토스는 캔들을 종목마다 따로 받아야 해서 비어 온다.
  /// 등락 표시에만 쓰이고 평가액에는 영향이 없다.
  final double? previousClose;

  factory BrokerQuote.fromJson(Map<String, dynamic> j) => BrokerQuote(
    symbol: (j['symbol'] as String?) ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    currency: (j['currency'] as String?) ?? 'KRW',
    previousClose: (j['previousClose'] as num?)?.toDouble(),
  );
}

class SecuritiesRepository {
  SecuritiesRepository(this._dio);
  final Dio _dio;

  dynamic _payload(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body['data'];
    return body;
  }

  /// 보유 종목 현재가. 심볼이 없으면 호출하지 않는다.
  Future<List<BrokerQuote>> getPrices(List<String> symbols) async {
    if (symbols.isEmpty) return const [];
    try {
      final res = await _dio.get<dynamic>(
        '/securities/prices',
        queryParameters: {'symbols': symbols.join(',')},
      );
      final p = _payload(res);
      if (p is! List) return const [];
      return p
          .whereType<Map<String, dynamic>>()
          .map(BrokerQuote.fromJson)
          .toList();
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 원화 환산 환율. 못 구하면 null — 나무는 해당 통화 보유 종목이 있어야 환율이 나온다.
  /// 캔들 한 페이지 — 증권사는 서버가 고른다(사용자 기본 소스). 응답 모양은 토스 캔들과 같다.
  /// 나무 상세의 일별 시세가 쓴다. [size] 는 서버 상한(200)을 넘기지 않는다.
  Future<TossCandlePage> getCandles(
    String symbol,
    String interval, {
    int? size,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/securities/candles',
        queryParameters: {
          'symbol': symbol,
          'interval': interval,
          'size': ?size,
        },
      );
      final p = _payload(res);
      return TossCandlePage.fromJson(p is Map<String, dynamic> ? p : {});
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<double?> getExchangeRate({
    String base = 'USD',
    String quote = 'KRW',
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/securities/exchange-rate',
        queryParameters: {'base': base, 'quote': quote},
      );
      final p = _payload(res);
      if (p is! Map<String, dynamic>) return null;
      return (p['rate'] as num?)?.toDouble();
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}
