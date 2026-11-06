/// 나무증권(NH PLUG) 조회 repository — 백엔드 프록시 `/api/v1/namu/**`.
/// Dio baseUrl 이 이미 `/api/v1` 이므로 경로는 `/namu/...`.
///
/// **토스와 나눠 둔 이유** — 증권사마다 응답 모양이 달라(필드 이름 · 단위 · 호출 박자) 서버가 증권사별
/// 경로(`/toss/**` · `/namu/**`)로 나눠 둔다. 화면은 공통 구역 + 증권사별 구역으로 같은 틀을 쓰고,
/// 그 탭의 데이터는 **그 탭의 경로**로 부른다(`/namu/prices` · `/namu/candles` · `/namu/exchange-rate` —
/// 기본 증권사를 따르는 `/securities/*` 는 가계부 자산용이다).
library;

import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';

/// 증권사 무관 현재가. 백엔드가 증권사별 필드명 차이를 흡수해 이 모양으로 준다
/// (나무 국내 `stck_prpr` / 나무 해외 `trdprc`).
class BrokerPrice {
  const BrokerPrice({
    required this.symbol,
    required this.price,
    required this.currency,
  });

  final String symbol;
  final double price;
  final String currency;

  factory BrokerPrice.fromJson(Map<String, dynamic> j) => BrokerPrice(
    symbol: (j['symbol'] as String?) ?? '',
    price: double.tryParse('${j['price']}') ?? 0,
    currency: (j['currency'] as String?) ?? 'KRW',
  );
}

/// 나무 계좌 1건.
class NamuAccount {
  const NamuAccount({required this.accountNo, required this.accountType});

  final String accountNo;
  final String accountType;

  factory NamuAccount.fromJson(Map<String, dynamic> j) => NamuAccount(
    accountNo: (j['accountNo'] as String?) ?? '',
    accountType: (j['accountType'] as String?) ?? '',
  );
}

/// 보유 종목 1건. 국내·해외 필드명 차이는 서버가 흡수해 이 모양으로 준다.
class NamuHoldingItem {
  const NamuHoldingItem({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.evalAmount,
    required this.profitLoss,
    this.sellableQuantity,
  });

  final String symbol;
  final String name;
  final String quantity;

  /// 매도 가능 수량 — 해외(미국)만. 국내 잔고에는 이 칸이 없어 null(화면이 줄을 그리지 않는다).
  final String? sellableQuantity;
  final String avgPrice;
  final String currentPrice;
  final String evalAmount;
  final String profitLoss;

  /// 금액은 문자열로 온다(정밀도 보존). 화면이 계산에 쓸 때만 숫자로 바꾼다.
  double get evalAmountValue => double.tryParse(evalAmount) ?? 0;
  double get profitLossValue => double.tryParse(profitLoss) ?? 0;

  factory NamuHoldingItem.fromJson(Map<String, dynamic> j) => NamuHoldingItem(
    symbol: (j['symbol'] as String?) ?? '',
    name: (j['name'] as String?) ?? '',
    quantity: (j['quantity'] as String?) ?? '0',
    avgPrice: (j['avgPrice'] as String?) ?? '0',
    currentPrice: (j['currentPrice'] as String?) ?? '0',
    evalAmount: (j['evalAmount'] as String?) ?? '0',
    profitLoss: (j['profitLoss'] as String?) ?? '0',
    sellableQuantity: _blankToNull(j['sellableQuantity']),
  );
}

String? _blankToNull(Object? v) {
  if (v == null) return null;
  final t = '$v'.trim();
  return t.isEmpty ? null : t;
}

/// 계좌 하나의 보유 현황 — 요약 + 종목별.
class NamuHoldings {
  const NamuHoldings({
    required this.accountNo,
    required this.currency,
    required this.totalEvalAmount,
    required this.totalProfitLoss,
    required this.profitRate,
    required this.items,
    this.deposit,
    this.orderableAmount,
  });

  /// 예수금 · 주문 가능 금액(100%) — 국내(KRW) 잔고 요약에서만 온다. 해외는 null.
  final String? deposit;
  final String? orderableAmount;
  double? get orderableValue =>
      orderableAmount == null ? null : double.tryParse(orderableAmount!);

  final String accountNo;
  final String currency;
  final String totalEvalAmount;
  final String totalProfitLoss;
  final String profitRate;
  final List<NamuHoldingItem> items;

  double get totalEvalValue => double.tryParse(totalEvalAmount) ?? 0;
  double get totalProfitLossValue => double.tryParse(totalProfitLoss) ?? 0;
  double get profitRateValue => double.tryParse(profitRate) ?? 0;

  factory NamuHoldings.fromJson(Map<String, dynamic> j) => NamuHoldings(
    accountNo: (j['accountNo'] as String?) ?? '',
    currency: (j['currency'] as String?) ?? 'KRW',
    totalEvalAmount: (j['totalEvalAmount'] as String?) ?? '0',
    totalProfitLoss: (j['totalProfitLoss'] as String?) ?? '0',
    profitRate: (j['profitRate'] as String?) ?? '0',
    items: ((j['items'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NamuHoldingItem.fromJson)
        .toList(),
    deposit: _blankToNull(j['deposit']),
    orderableAmount: _blankToNull(j['orderableAmount']),
  );

  static const empty = NamuHoldings(
    accountNo: '',
    currency: 'KRW',
    totalEvalAmount: '0',
    totalProfitLoss: '0',
    profitRate: '0',
    items: [],
  );
}

class NamuRepository {
  NamuRepository(this._dio);
  final Dio _dio;

  dynamic _payload(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body['data'];
    return body;
  }

  /// 국내주식 현재가. [marketCode] 는 KRX(기본)·NXT·UNT —
  /// 종목이 NXT 거래 대상인지는 서버 stock_master 가 안다.
  Future<BrokerPrice?> getKrPrice(String symbol, {String? marketCode}) async {
    return _price('/namu/kr/price', {
      'symbol': symbol,
      'marketCode': ?marketCode,
    });
  }

  /// 해외주식 현재가.
  Future<BrokerPrice?> getGbPrice(String symbol) async {
    return _price('/namu/gb/price', {'symbol': symbol});
  }

  /// 본인 계좌 목록.
  Future<List<NamuAccount>> getAccounts() async {
    try {
      final res = await _dio.get<dynamic>('/namu/accounts');
      final p = _payload(res);
      if (p is! List) return const [];
      return p
          .whereType<Map<String, dynamic>>()
          .map(NamuAccount.fromJson)
          .toList();
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 보유 종목. [currency] 가 KRW 면 국내, 그 밖(USD·CNY·HKD·JPY)이면 해외.
  /// [accountNo] 를 안 주면 서버가 첫 계좌를 쓴다.
  Future<NamuHoldings> getHoldings({
    String? accountNo,
    String currency = 'KRW',
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/namu/holdings',
        queryParameters: {'currency': currency, 'accountNo': ?accountNo},
      );
      final p = _payload(res);
      return p is Map<String, dynamic>
          ? NamuHoldings.fromJson(p)
          : NamuHoldings.empty;
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<BrokerPrice?> _price(String path, Map<String, dynamic> query) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      final p = _payload(res);
      return p is Map<String, dynamic> ? BrokerPrice.fromJson(p) : null;
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  // ---- 그 탭 증권사 경로 (13b-0 8) — 기본 증권사를 따르는 /securities/* 가 아니다 ----------

  /// 관심 시세 · 장 상태 — 심볼을 한 번에(서버 상한 50 · 캐시 20초). 장 상태가 종목마다 딸려 온다.
  Future<List<NamuListQuote>> getListQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const [];
    try {
      final res = await _dio.get<dynamic>(
        '/namu/prices',
        queryParameters: {'symbols': symbols.join(',')},
      );
      final p = _payload(res);
      if (p is! List) return const [];
      return p
          .whereType<Map<String, dynamic>>()
          .map(NamuListQuote.fromJson)
          .toList();
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 캔들 한 페이지 — 나무 제공자를 바로(기본 증권사 아님). 응답 모양은 `/securities/candles` 와 같다.
  Future<TossCandlePage> getCandles(
    String symbol,
    String interval, {
    int? size,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/namu/candles',
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

  /// USD→KRW 환율. 못 구하면 null.
  Future<double?> getExchangeRate({String base = 'USD'}) async {
    try {
      final res = await _dio.get<dynamic>(
        '/namu/exchange-rate',
        queryParameters: {'base': base},
      );
      final p = _payload(res);
      if (p is! Map<String, dynamic>) return null;
      return (p['rate'] as num?)?.toDouble() ?? double.tryParse('${p['rate']}');
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 종목 상세 시세 — 머리 · 오늘 시세 · 호가 · 경고 · 기본 정보가 한 응답이다.
  Future<NamuQuoteDetail> getQuoteDetail(
    String symbol, {
    required bool us,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        us ? '/namu/gb/quote' : '/namu/kr/quote',
        queryParameters: {'symbol': symbol},
      );
      final p = _payload(res);
      return NamuQuoteDetail.fromJson(p is Map<String, dynamic> ? p : {});
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 체결 — 토스 `Trade` 와 같은 모양, 최신이 먼저.
  Future<List<TossTrade>> getExecutions(
    String symbol, {
    required bool us,
    int count = 20,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        us ? '/namu/gb/executions' : '/namu/kr/executions',
        queryParameters: {'symbol': symbol, 'count': count},
      );
      return tradesFromJson(_payload(res));
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 투자자별 매매동향(국내 종목만).
  Future<List<InvestorTradingDay>> getInvestors(
    String symbol, {
    int count = 5,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/namu/kr/investors',
        queryParameters: {'symbol': symbol, 'count': count},
      );
      return investorDaysFromJson(_payload(res));
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 해외 증거금 — 달러 예수금(`fc_dca`). USD 행이 없으면 null.
  Future<BuyingPower?> getUsdDeposit() async {
    try {
      final res = await _dio.get<dynamic>('/namu/margin');
      final p = _payload(res);
      if (p is! Map<String, dynamic>) return null;
      final raw = _blankToNull(p['foreignDeposit']);
      if (raw == null) return null;
      return BuyingPower(currency: 'USD', amount: double.tryParse(raw));
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }
}
