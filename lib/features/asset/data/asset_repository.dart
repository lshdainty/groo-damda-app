import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/domain/card_billing.dart';
import 'package:groo_damda_app/features/asset/domain/net_worth_point.dart';
import 'package:groo_damda_app/core/network/silent_error_toast.dart';

class AssetRepository {
  AssetRepository(this._dio);
  final Dio _dio;

  // ─────────────────────────────────────────────
  // Asset CRUD
  // ─────────────────────────────────────────────

  Future<List<Asset>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/assets');
      return _unwrapList(res, 'assets', Asset.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 단건 조회. GET /asset/{id}.
  Future<Asset> getById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/asset/$id');
      return _unwrap(res, Asset.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 자산 정렬 순서 변경. PATCH /assets/reorder.
  /// [items] = (assetRowId, sortOrder) pair 목록.
  Future<void> reorder(List<({int assetId, int sortOrder})> items) async {
    try {
      await _dio.patch<dynamic>(
        '/assets/reorder',
        data: {
          'items': [
            for (final i in items)
              {'assetId': i.assetId, 'sortOrder': i.sortOrder},
          ],
        },
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 자산 잔액 추이 (주별). GET /asset/{id}/balance-trend?weeks=N.
  Future<List<AssetBalancePoint>> balanceTrend(int id, {int weeks = 12}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/asset/$id/balance-trend',
        queryParameters: {'weeks': weeks},
      );
      return _unwrapList(res, 'trend', AssetBalancePoint.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 최근 N개월 순자산 추이.
  Future<List<NetWorthPoint>> netWorthTrend({int months = 12}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/assets/net-worth-trend',
        queryParameters: {'months': months},
      );
      return _unwrapList(res, 'trend', NetWorthPoint.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 순자산/자산/부채/지난달 대비 변화 등.
  Future<AssetSummary> summary({int? year, int? month}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/assets/summary',
        queryParameters: {'year': ?year, 'month': ?month},
      );
      return _unwrap(res, AssetSummary.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<Asset> create({
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal, // 'Y' | 'N'
    // 이 자산의 금액만 가림. null 이면 키를 안 싣는다 — 서버 PUT 은 "키 없음=유지" 다.
    String? isAmountHidden, // 'Y' | 'N'
    int? sortOrder,
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    // 마이너스통장 여부 — 서버가 부호를 정할 때 쓴다(QA #17/#19).
    // `BANK_ACCOUNT` 인데 잔액이 빚인 경우라 유형만으로는 서버가 알 수 없다.
    bool? isOverdraft,
    // 투자 보유 종목 (INVESTMENT 전용) — 전달 시 전체 교체.
    List<AssetHolding>? holdings,
    // 신용카드: 결제를 기다리던 지난달 청구분(양수) — 다가오는 결제일에 청구된다. [balance] 는
    // 그 뒤 쓴 금액이다. null 이면 키를 안 싣는다(없음).
    int? dueCarryoverAmount,
    // 폼이 실패를 자리에서 말할 때 — 전역 서버 글 토스트를 끈다.
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset',
        data: {
          'assetName': assetName,
          'assetType': assetType,
          'balance': ?_balanceBody(assetType, balance, holdings),
          'currency': ?currency,
          'exchangeRate': ?exchangeRate,
          'color': ?color,
          'institution': ?institution,
          'memo': ?memo,
          'isIncludedInTotal': ?isIncludedInTotal,
          'isAmountHidden': ?isAmountHidden,
          'sortOrder': ?sortOrder,
          'cardCatalogRowId': ?cardCatalogRowId,
          'creditLimit': ?creditLimit,
          'paymentDay': ?paymentDay,
          'paymentAssetRowId': ?paymentAssetRowId,
          'isOverdraft': ?isOverdraft,
          'holdings': ?holdings?.map(_holdingBody).toList(),
          'dueCarryoverAmount': ?dueCarryoverAmount,
        },
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
      return _unwrap(res, Asset.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 수정 — **호출한 화면이 소유한 칸만** 키를 싣는다(QA #99).
  ///
  /// 이 메서드는 계좌·카드·투자 세 화면이 나눠 쓴다. 셋이 가진 칸이 서로 달라서
  /// "비었으면 지운다" 를 리포지토리가 일괄로 정할 수 없다 — 카드 화면엔 메모 칸이
  /// 없는데 메모를 null 로 실으면, 계좌 화면에서 적어 둔 메모가 카드를 고칠 때마다
  /// 사라진다. 그래서 지울 수 있는 칸을 [Patch] 로 두고 판단을 화면에 맡긴다.
  /// [Patch.keep] 이 기본값이라 안 넘긴 칸은 키가 빠지고 서버가 지금 값을 지킨다.
  ///
  /// 나머지가 [Patch] 가 아닌 이유:
  /// - `assetName`·`assetType`·`isIncludedInTotal`·`isOverdraft` — 세 화면 다
  ///   늘 값을 들고 있어 비워질 일이 없다
  /// - `currency` — 세 화면 다 통화 칸을 가졌고(D1) 그 칸은 지금 통화를 채워서 연다.
  ///   비워질 일이 없어 [Patch] 가 아니다. **화면에 칸이 없는데 실으면 안 된다** —
  ///   'KRW' 를 실으면 웹에서 만든 외화 자산이 앱 편집 한 번에 원화가 되고 서버가
  ///   환산율을 1 로 정규화한다(`Asset.normalizeRate`). 값이 없으면 키가 빠지고
  ///   서버가 지금 통화를 지킨다
  /// - `institution`·`cardCatalogRowId` — 고르는 칸이라 **떼는 조작이 없다**.
  ///   값이 없으면 원래 없던 것이다
  /// - `color` — 앱 어느 화면에도 없는 칸이다(웹에서만 고른다)
  /// - `balance` — null 이 "지운다" 가 아니라 "보유로 서버가 산정해 달라" 다.
  ///   [_balanceBody] 를 보라. 신용카드는 서버가 이 값을 무시한다 — 이월은
  ///   `carryoverAmount` 로만 고친다(D7)
  /// - `carryoverAmount` — 지우는 조작이 없다(0 이 "이월 없음"). null 이면 키가 빠진다
  /// - `holdings` — "null=미변경 · 리스트=교체" 라는 뜻이 이미 확정돼 있다(QA #91)
  Future<Asset> update({
    required int id,
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    Patch<double> exchangeRate = const Patch.keep(),
    String? color,
    String? institution,
    Patch<String> memo = const Patch.keep(),
    String? isIncludedInTotal, // 'Y' | 'N'
    // 이 자산의 금액만 가림. null 이면 키를 안 싣는다 — 서버 PUT 은 "키 없음=유지" 다.
    String? isAmountHidden, // 'Y' | 'N'
    int? cardCatalogRowId,
    Patch<int> creditLimit = const Patch.keep(),
    Patch<int> paymentDay = const Patch.keep(),
    Patch<int> paymentAssetRowId = const Patch.keep(),
    // 마이너스통장 여부 — 서버가 부호를 정할 때 쓴다(QA #17/#19).
    bool? isOverdraft,
    // 투자 보유 종목 (INVESTMENT 전용) — 전달 시 전체 교체.
    List<AssetHolding>? holdings,
    // 신용카드의 이월 금액("이전 미결제 사용액", D7) — 0 이상. null 이면 키를 안 싣는다
    // (서버 PUT 은 "키 없음=유지"). 신용카드는 `balance` 를 서버가 무시하므로 이 키로만
    // 이월을 고친다.
    int? carryoverAmount,
    // 신용카드: 결제 대기 청구분 — null 이면 키가 빠진다(유지), 0 이면 서버가 지운다.
    int? dueCarryoverAmount,
    // 폼이 실패를 자리에서 말할 때 — 전역 서버 글 토스트를 끈다.
    bool silent = false,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/asset/$id',
        data: {
          'assetName': assetName,
          'assetType': assetType,
          'balance': ?_balanceBody(assetType, balance, holdings),
          'currency': ?currency,
          if (exchangeRate.present) 'exchangeRate': exchangeRate.value,
          'color': ?color,
          'institution': ?institution,
          if (memo.present) 'memo': memo.value,
          'isIncludedInTotal': ?isIncludedInTotal,
          'isAmountHidden': ?isAmountHidden,
          'cardCatalogRowId': ?cardCatalogRowId,
          if (creditLimit.present) 'creditLimit': creditLimit.value,
          if (paymentDay.present) 'paymentDay': paymentDay.value,
          if (paymentAssetRowId.present)
            'paymentAssetRowId': paymentAssetRowId.value,
          'isOverdraft': ?isOverdraft,
          'holdings': ?holdings?.map(_holdingBody).toList(),
          'carryoverAmount': ?carryoverAmount,
          'dueCarryoverAmount': ?dueCarryoverAmount,
        },
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
      return _unwrap(res, Asset.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 투자 자산 잔액 — 보유를 함께 보내면 **서버가 평가액을 BigDecimal 로 산정**하므로 싣지 않는다.
  /// 클라이언트가 double 로 계산한 금액을 보내면 DB 에 남는 금액이 깎일 뿐이다.
  /// 보유가 없는 자산(그리고 투자가 아닌 자산)은 기존대로 사용자 입력 잔액을 보낸다.
  static int? _balanceBody(
    String assetType,
    int? balance,
    List<AssetHolding>? holdings,
  ) => assetType == 'INVESTMENT' && (holdings?.isNotEmpty ?? false)
      ? null
      : balance;

  /// holdings 요청 바디 — linked ↔ manual 별 필요한 필드만 직렬화.
  /// 수량은 소수 허용(코인 0.05·금 3.75g)이라 **문자열 그대로** 보낸다 — 서버가 BigDecimal 로 받아
  /// 정밀도가 깎이지 않는다. 미연동도 수량을 남긴다 — 선택이라 없으면 미전송.
  ///
  /// **`sortOrder` 는 싣지 않는다** — 서버 `HoldingRequest` 에 그 필드가 없어 Jackson 이 조용히
  /// 버렸고(QA #91), 실제 순서는 **보낸 배열의 인덱스**로 서버가 정한다. 조회도 그 순서로
  /// 돌아오므로(`sortOrder asc, rowId asc`) 배열 순서만 지키면 왕복이 맞는다. 값을 다시 실으면
  /// "보낸 번호대로 저장된다" 는 착각만 되살아난다 — 배열 순서와 어긋나도 아무도 모른다.
  static Map<String, dynamic> _holdingBody(AssetHolding h) => {
    'rowId': ?h.rowId,
    'holdingType': h.holdingType.wire,
    'linked': h.linked,
    if (h.linked) ...{
      // 시장코드는 선택이다 — 확정 못 했으면 아예 안 보내고 서버가 심볼로 해석한다.
      'marketCode': ?h.marketCode,
      'tossSymbol': h.tossSymbol,
      'quantity': h.quantity ?? '0',
    } else ...{
      'holdingName': h.holdingName,
      'holdingValue': h.holdingValue ?? 0,
      'quantity': ?h.quantity,
    },
    // 안 적었으면 안 보낸다 — 서버가 같은 종목의 기존 원가를 잇는다.
    'totalCost': ?h.totalCost,
  };

  Future<void> delete(int id, {bool silent = false}) async {
    try {
      await _dio.delete<void>(
        '/asset/$id',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  // ─────────────────────────────────────────────
  // Credit Card Billing
  // ─────────────────────────────────────────────

  /// 신용카드 청구 사이클 조회. GET /asset/{id}/billing.
  /// 이번 결제예정액·예정일·결제일·결제계좌 + 청구이력.
  Future<CardBilling> getCardBilling(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/asset/$id/billing');
      return _unwrap(res, CardBilling.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 지금 결제 — 청구액을 결제 출금계좌에서 이체. POST /asset/{id}/pay.
  /// [amount] 미전달이면 남은 청구액 전액, 전달하면 그만큼만(부분 선결제).
  /// 방금 기록된 청구 1건을 반환.
  /// [paymentDate] 는 결제할 회차의 결제일 — 다음 회차를 미리 낼 때 넘긴다. 미전달 = 다가오는 회차.
  Future<BillingItem> payCard(
    int id, {
    int? amount,
    String? paymentDate,
    bool silent = false,
  }) async {
    try {
      final query = <String, dynamic>{
        'amount': ?amount,
        'paymentDate': ?paymentDate,
      };
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset/$id/pay',
        queryParameters: query.isEmpty ? null : query,
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
      return _unwrap(res, BillingItem.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 카드 결제 취소 — 결제로 만든 이체를 무르면 잔액·청구가 그 연쇄로 되돌아간다.
  /// DELETE /card-billing/{billingRowId}.
  Future<void> cancelCardPayment(
    int billingRowId, {
    bool silent = false,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/card-billing/$billingRowId',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 할부 중도 전액 상환 — 남은 원금을 다가오는 청구 회차에 몰아 청구한다.
  /// POST /asset/{cardId}/installments/{expenseId}/payoff.
  Future<void> payoffInstallment(
    int cardId,
    int expenseId, {
    bool silent = false,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/asset/$cardId/installments/$expenseId/payoff',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 할부 상환 취소 — 정상 분할로 되돌린다.
  Future<void> cancelInstallmentPayoff(
    int cardId,
    int expenseId, {
    bool silent = false,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/asset/$cardId/installments/$expenseId/payoff',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  // ─────────────────────────────────────────────
  // Asset Transfer
  // ─────────────────────────────────────────────

  Future<void> createTransfer({
    required int fromAssetRowId,
    required int toAssetRowId,
    required int amount,
    int? fee,
    int? interestAmount,
    String? description,
    required String transferDate, // ISO-LOCAL-DATETIME 'YYYY-MM-DDTHH:mm:ss'
    bool silent = false,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/asset-transfer',
        data: {
          'fromAssetRowId': fromAssetRowId,
          'toAssetRowId': toAssetRowId,
          'amount': amount,
          'fee': ?fee,
          'interestAmount': ?interestAmount,
          'description': ?description,
          'transferDate': transferDate,
        },
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 이체 수정 — 서버가 이자 지출·잔액 이력을 되돌렸다 다시 만든다. rowId 는 유지된다.
  ///
  /// 시스템이 만든 이체(매수 충당·카드 자동결제)는 서버가 거부한다.
  Future<void> updateTransfer({
    required int rowId,
    required int fromAssetRowId,
    required int toAssetRowId,
    required int amount,
    int? fee,
    int? interestAmount,
    String? description,
    required String transferDate,
    bool silent = false,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/asset-transfer/$rowId',
        data: {
          'fromAssetRowId': fromAssetRowId,
          'toAssetRowId': toAssetRowId,
          'amount': amount,
          'fee': ?fee,
          'interestAmount': ?interestAmount,
          'description': ?description,
          'transferDate': transferDate,
        },
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 매수·매도 등록 — 예수금·보유 수량·원가·실현손익이 함께 움직인다.
  ///
  /// [amount] 는 수수료를 뺀 거래대금이다. 수수료는 매수면 취득원가에 들어가고
  /// 매도면 대금에서 빠진다 — 어느 쪽이든 예수금에서 실제로 나간다.
  Future<AssetTrade> createTrade({
    required int assetRowId,
    required String tradeType, // 'BUY' | 'SELL' | 'OPENING'
    required String holdingType,
    required String holdingKey,
    required bool linked,
    required String quantity,
    required int amount,
    int? fee,

    /// 거래일 — **안 보내면 서버가 사용자 시계의 지금으로 채운다**
    /// (`AssetTradeServiceImpl` 의 `userClock.now`). `@NotNull` 이 아니다.
    /// 앱에 거래일 칸이 없는 화면은 여기를 비워라 — 기기 시계로 만든 문자열은
    /// 시간대 정보가 없어 사용자 시계와 갈라진다.
    String? tradeDate, // ISO-LOCAL-DATETIME
    String? description,

    /// 결제 계좌 — null 이면 증권계좌 예수금에서.
    int? settlementAssetRowId,

    /// 폼이 실패를 자리에서 말할 때 — 전역 서버 글 토스트를 끈다.
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset-trade',
        data: {
          'assetRowId': assetRowId,
          'tradeType': tradeType,
          'holdingType': holdingType,
          'holdingKey': holdingKey,
          'linked': linked,
          'quantity': quantity,
          'amount': amount,
          'fee': fee ?? 0,
          'tradeDate': ?tradeDate,
          'description': ?description,
          'settlementAssetRowId': settlementAssetRowId,
        },
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
      return _unwrap(res, AssetTrade.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 저장하기 전에 결과를 물어본다 — 저장에 쓰는 계산 경로를 그대로 탄다.
  ///
  /// 실현손익·예수금 잔액을 앱에서 계산하면 서버와 갈라진다. 이동평균 매수원가
  /// 규칙이 웹·앱·서버 세 군데에 각각 있으면 하나만 고쳐도 값이 달라지고,
  /// Dart 의 `/` 는 double 나눗셈이라 끝자리까지 어긋난다.
  Future<AssetTradePreview> previewTrade({
    required int assetRowId,
    required String tradeType,
    required String holdingType,
    required String holdingKey,
    required bool linked,
    required String quantity,
    required int amount,
    int? fee,

    /// 거래일 — 저장과 같은 규칙이다. 안 보내면 서버가 사용자 시계의 지금으로 잡아
    /// 그 시점 예수금을 계산한다. **저장에서 안 보내면 여기서도 보내지 마라** —
    /// 한쪽만 보내면 미리보기와 저장이 다른 시점을 본다.
    String? tradeDate,
    int? settlementAssetRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset-trade/preview',
        // 입력 중 미리보기 — 실패해도 값을 안 보여줄 뿐이라 토스트로 방해하지 않는다.
        options: Options(extra: {kSilentErrorToast: true}),
        data: {
          'assetRowId': assetRowId,
          'tradeType': tradeType,
          'holdingType': holdingType,
          'holdingKey': holdingKey,
          'linked': linked,
          'quantity': quantity,
          'amount': amount,
          'fee': fee ?? 0,
          'tradeDate': ?tradeDate,
          'settlementAssetRowId': settlementAssetRowId,
        },
      );
      return _unwrap(res, AssetTradePreview.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<List<AssetTrade>> getTrades(int assetRowId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/asset-trades',
        queryParameters: {'assetRowId': assetRowId},
      );
      // 거래 목록은 data 가 바로 배열이다 — 다른 목록처럼 감싸는 키가 없다.
      final body = ApiResponse<List<dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as List<dynamic>?) ?? const [],
      );
      if (!body.success) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data ?? const [])
          .map((e) => AssetTrade.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 거래 취소 — 예수금·수량·원가가 그 거래 직전으로 돌아간다.
  Future<void> deleteTrade(int id, {bool silent = false}) async {
    try {
      await _dio.delete<void>(
        '/asset-trade/$id',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  Future<void> deleteTransfer(int id, {bool silent = false}) async {
    try {
      await _dio.delete<void>(
        '/asset-transfer/$id',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  /// 자산 이체 내역 조회. GET /asset-transfers?startDate&endDate.
  Future<List<AssetTransfer>> listTransfers({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/asset-transfers',
        queryParameters: {'startDate': ?startDate, 'endDate': ?endDate},
      );
      return _unwrapList(res, 'transfers', AssetTransfer.fromJson);
    } catch (e, s) {
      throwAsApiException(e, s);
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  T _unwrap<T>(
    Response<Map<String, dynamic>> res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<T>.fromJson(
      res.data ?? const {},
      (raw) => fromJson(raw! as Map<String, dynamic>),
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    return body.data!;
  }

  List<T> _unwrapList<T>(
    Response<Map<String, dynamic>> res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data ?? const {},
      (raw) => raw! as Map<String, dynamic>,
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    final list = (body.data![listKey] as List<dynamic>?) ?? const [];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
