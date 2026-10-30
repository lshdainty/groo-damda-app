import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/api_response.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';

// ─── 모델 (백엔드 dataimport.sms 미러) ─────────────────────────

/// 어느 카드로 기록할지 고를 후보.
class SmsAssetCandidate {
  const SmsAssetCandidate({
    required this.rowId,
    required this.assetName,
    this.institution,
    this.assetType,
  });
  final int rowId;
  final String assetName;
  final String? institution;
  final String? assetType;

  factory SmsAssetCandidate.fromJson(Map<String, dynamic> j) =>
      SmsAssetCandidate(
        rowId: (j['rowId'] as num?)?.toInt() ?? 0,
        assetName: j['assetName'] as String? ?? '',
        institution: j['institution'] as String?,
        assetType: j['assetType'] as String?,
      );
}

/// 문자 한 통의 해석 결과 — 저장 전 초안.
class SmsParseResult {
  const SmsParseResult({
    required this.matched,
    required this.confidence,
    required this.cancel,
    this.amount,
    this.merchant,
    this.expenseDate,
    this.installmentMonths,
    this.cardHint,
    this.issuerName,
    this.cardLast4,
    this.assetRowId,
    required this.assetRemembered,
    required this.assetCandidates,
    this.categoryRowId,
    this.categoryName,
    this.originalAmount,
    this.originalCurrency,
  });

  final bool matched;

  /// HIGH / MEDIUM / LOW — 어디까지 사용자에게 물을지의 기준.
  final String confidence;

  /// 취소·승인취소 문자 — 저장을 막고 안내만 한다.
  final bool cancel;

  final int? amount;
  final String? merchant;

  /// 오프셋 없는 로컬 시각(`2026-08-13T13:22`). UTC 로 바꾸면 자정 근처 날짜가 밀린다.
  final String? expenseDate;

  final int? installmentMonths;
  final String? cardHint;
  final String? issuerName;
  final String? cardLast4;

  final int? assetRowId;

  /// 자산이 기억해 둔 매핑에서 나왔는가 — false 면 "이 카드로 기억" 을 물어볼 만하다.
  final bool assetRemembered;

  final List<SmsAssetCandidate> assetCandidates;
  final int? categoryRowId;
  final String? categoryName;
  final num? originalAmount;
  final String? originalCurrency;

  bool get isLowConfidence => confidence == 'LOW';

  factory SmsParseResult.fromJson(Map<String, dynamic> j) => SmsParseResult(
    matched: j['matched'] as bool? ?? false,
    confidence: j['confidence'] as String? ?? 'LOW',
    cancel: j['cancel'] as bool? ?? false,
    amount: (j['amount'] as num?)?.toInt(),
    merchant: j['merchant'] as String?,
    expenseDate: j['expenseDate'] as String?,
    installmentMonths: (j['installmentMonths'] as num?)?.toInt(),
    cardHint: j['cardHint'] as String?,
    issuerName: j['issuerName'] as String?,
    cardLast4: j['cardLast4'] as String?,
    assetRowId: (j['assetRowId'] as num?)?.toInt(),
    assetRemembered: j['assetRemembered'] as bool? ?? false,
    assetCandidates: ((j['assetCandidates'] as List?) ?? const [])
        .map(
          (e) => SmsAssetCandidate.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(),
    categoryRowId: (j['categoryRowId'] as num?)?.toInt(),
    categoryName: j['categoryName'] as String?,
    originalAmount: j['originalAmount'] as num?,
    originalCurrency: j['originalCurrency'] as String?,
  );
}

/// 저장 결과.
class SmsCommitResult {
  const SmsCommitResult({
    required this.expenseRowId,
    required this.cardRemembered,
    this.refundedAmount,
  });
  final int? expenseRowId;
  final bool cardRemembered;

  /// 이 저장이 결제계좌로 **방금** 돌려준 금액(열린 회차 선결제 과납, D3·D4).
  ///
  /// 거래 생성 응답(`ExpenseResponse.refundedAmount`)과 같은 뜻이다. 지금 서버의 문자
  /// 저장 응답에는 없어 늘 null 이다 — 서버가 실어 주면 그때부터 토스트가 뜬다.
  final int? refundedAmount;

  factory SmsCommitResult.fromJson(Map<String, dynamic> j) => SmsCommitResult(
    expenseRowId: (j['expenseRowId'] as num?)?.toInt(),
    cardRemembered: j['cardRemembered'] as bool? ?? false,
    refundedAmount: (j['refundedAmount'] as num?)?.toInt(),
  );
}

/// 기억해 둔 카드 연결 한 건.
class SmsCardMapping {
  const SmsCardMapping({
    required this.rowId,
    required this.cardHint,
    required this.assetRowId,
    this.assetName,
  });
  final int rowId;
  final String cardHint;
  final int assetRowId;
  final String? assetName;

  factory SmsCardMapping.fromJson(Map<String, dynamic> j) => SmsCardMapping(
    rowId: (j['rowId'] as num?)?.toInt() ?? 0,
    cardHint: j['cardHint'] as String? ?? '',
    assetRowId: (j['assetRowId'] as num?)?.toInt() ?? 0,
    assetName: j['assetName'] as String?,
  );
}

// ─── 리포지토리 ────────────────────────────────────────────────

class SmsRepository {
  SmsRepository(this._dio);
  final Dio _dio;

  /// 문자 해석 — 저장하지 않는다.
  Future<SmsParseResult> parse(String text, {bool silent = false}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/import/sms/parse',
        data: {'text': text},
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      return SmsParseResult.fromJson(api.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 확정 값으로 지출 생성.
  ///
  /// [text] 원문을 함께 보내는 건 값을 뽑으려는 게 아니라 서버 가드용이다 —
  /// 취소 문자를 막고 카드 매핑 키를 서버가 도출한다.
  /// [expenseType] 은 `EXPENSE` · `INCOME`. 안 실으면 서버가 지출로 본다 —
  /// 이 키를 모르는 옛 앱이 계속 돌아야 해서 기본값이 지출이다(desk-back #326).
  /// 환불·입금 문자를 수입으로 남기려면 반드시 실어야 한다.
  Future<SmsCommitResult> commit({
    required String text,
    required int? assetRowId,
    required int? categoryRowId,
    required String expenseType,
    required int amount,
    String? merchant,
    String? description,
    required String expenseDate,
    String? paymentMethod,
    int? installmentMonths,
    num? originalAmount,
    String? originalCurrency,
    num? exchangeRate,
    required bool rememberCard,
    bool silent = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/import/sms/commit',
        data: {
          'text': text,
          'assetRowId': assetRowId,
          'categoryRowId': categoryRowId,
          'expenseType': expenseType,
          'amount': amount,
          'merchant': merchant,
          'description': description,
          'expenseDate': expenseDate,
          'paymentMethod': paymentMethod,
          'installmentMonths': installmentMonths,
          'originalAmount': originalAmount,
          'originalCurrency': originalCurrency,
          'exchangeRate': exchangeRate,
          'rememberCard': rememberCard,
        },
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      return SmsCommitResult.fromJson(api.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 기억해 둔 카드 연결 목록.
  Future<List<SmsCardMapping>> cardMappings() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/import/sms/cards');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data!,
        (o) => (o as Map).cast<String, dynamic>(),
      );
      final list = (api.data?['mappings'] as List?) ?? const [];
      return list
          .map(
            (e) => SmsCardMapping.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 카드 연결 해제 — 다음 문자부터 다시 물어본다.
  Future<void> deleteCardMapping(int rowId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/import/sms/cards/$rowId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final smsRepositoryProvider = FutureProvider<SmsRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return SmsRepository(dio);
});
