/// 구독·기능권한·증권사 크리덴셜 repository. 증권 메뉴 게이트 + 설정(증권사 연결) 백엔드 연동.
/// Dio baseUrl 이 이미 /api/v1 이므로 경로는 /users/me/features, /subscriptions,
/// /users/me/securities-credentials.
library;

import 'package:dio/dio.dart';

import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';

class MyFeatures {
  const MyFeatures({
    required this.features,
    required this.connectedBrokers,
    this.primaryBroker,
  });
  final List<String> features;

  /// 연결된 증권사 코드. 증권사가 늘어도 이 목록만 늘어난다.
  final List<String> connectedBrokers;

  /// 가계부 자산 평가에 쓰는 증권사. 연결이 없으면 null.
  final String? primaryBroker;

  bool get hasSecurities => features.contains('SECURITIES');

  /// 증권사를 가리지 않고 하나라도 연결됐는지 — 증권 화면·자산 연동 노출 판정.
  bool get hasBrokerConnection => connectedBrokers.isNotEmpty;

  bool isConnected(String broker) => connectedBrokers.contains(broker);

  factory MyFeatures.fromJson(Map<String, dynamic> j) {
    final brokers = ((j['connectedBrokers'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    return MyFeatures(
      features: ((j['features'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      // 구버전 서버는 connectedBrokers 를 안 준다 — tossConnected 로 되살린다.
      connectedBrokers: brokers.isNotEmpty
          ? brokers
          : ((j['tossConnected'] as bool?) ?? false
                ? const ['TOSS']
                : const []),
      primaryBroker: j['primaryBroker'] as String?,
    );
  }

  static const empty = MyFeatures(features: [], connectedBrokers: []);
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.planCode,
    required this.planName,
    required this.status,
    this.currentPeriodEnd,
    required this.autoRenew,
    this.price,
    this.durationMonths,
  });
  final String planCode;
  final String planName;
  final String status;
  final String? currentPeriodEnd;
  final bool autoRenew;

  /// 지금 구독한 요금제의 가격(원)과 기간(개월) — 서버 값이다. 옛 서버 응답엔 없을 수 있어 null 을 받는다.
  final int? price;
  final int? durationMonths;

  /// 이용 기간 끝(다음 결제 · 이용 끝나는 날) 날짜 글 — 화면 날짜 규칙(올해면 "11월 11일", 다른 해면 "2027년 11월 11일").
  /// 서버 UTC 시각을 로컬로 읽은 뒤 [formatDay] 를 쓴다. 못 읽는 값은 null.
  String? get periodEndLabel {
    final dt = parseServerUtc(currentPeriodEnd);
    return dt == null ? null : formatDay(dt).md;
  }

  /// `/subscriptions/me` 에 가격 · 기간이 없을 때(옛 서버 · 실패) planCode 로 플랜 목록에서 찾아 채운다.
  /// 정상 경로는 서버가 준 값이다 — 있으면 그대로 둔다.
  SubscriptionInfo resolvedWith(List<SubscriptionPlanInfo> plans) {
    if (price != null && durationMonths != null) return this;
    final plan = plans.where((p) => p.planCode == planCode).firstOrNull;
    if (plan == null) return this;
    return SubscriptionInfo(
      planCode: planCode,
      planName: planName,
      status: status,
      currentPeriodEnd: currentPeriodEnd,
      autoRenew: autoRenew,
      price: price ?? plan.price,
      durationMonths: durationMonths ?? plan.durationMonths,
    );
  }

  /// 지금 Pro 를 쓸 수 있는가 — 해지 뒤 **유예 기간**을 포함한다.
  ///
  /// 서버(desk-back #332)는 해지해도 만료일을 앞당기지 않는다. 응답은
  /// `status=CANCELLED` · `autoRenew=false` · `currentPeriodEnd=<미래>` 로 남고
  /// `features` 에도 `SECURITIES` 가 그대로 있어 증권 기능이 열려 있다. 그래서
  /// `status == 'ACTIVE'` 만 보면 **돈 낸 기간이 남은 사람에게 시트가 "Free 플랜
  /// 이용 중" 이라고 말한다** — 기능은 열려 있는데 화면만 잠긴 척했다.
  ///
  /// [currentPeriodEnd] 는 서버가 시간대 없이 주는 `[UTC]` 시각이라
  /// [parseServerUtc] 로 읽는다 — 구독 시트가 날짜를 찍을 때와 같은 규칙이다.
  /// 여기서 문자열을 잘라 비교하면 KST(+9) 자정 근처에서 하루가 어긋난다.
  ///
  /// **못 읽으면 종전대로 `ACTIVE` 만 본다.** 만료일이 없거나(무제한) 날짜만 있는
  /// 값이면 유예의 끝이 언제인지 모르는데, 모르는 채로 열어 주면 되돌아올 날이 없어
  /// 영영 안 막힌다. 서버도 `CANCELLED` 는 만료일이 있을 때만 센다.
  bool get isActive {
    if (status == 'ACTIVE') return true;
    if (status != 'CANCELLED') return false;
    final end = parseServerUtc(currentPeriodEnd);
    return end != null && end.isAfter(DateTime.now());
  }

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) => SubscriptionInfo(
    planCode: j['planCode'] as String,
    planName: j['planName'] as String,
    status: j['status'] as String,
    currentPeriodEnd: j['currentPeriodEnd'] as String?,
    autoRenew: (j['autoRenew'] as bool?) ?? false,
    price: (j['price'] as num?)?.toInt(),
    durationMonths: (j['durationMonths'] as num?)?.toInt(),
  );
}

class SubscriptionPlanInfo {
  const SubscriptionPlanInfo({
    required this.planCode,
    required this.planName,
    this.durationMonths,
    this.price,
  });
  final String planCode;
  final String planName;
  final int? durationMonths;

  /// 가격(원) — 서버 값. 옛 서버 응답엔 없을 수 있어 null 을 받는다.
  final int? price;

  factory SubscriptionPlanInfo.fromJson(Map<String, dynamic> j) =>
      SubscriptionPlanInfo(
        planCode: j['planCode'] as String,
        planName: j['planName'] as String,
        durationMonths: (j['durationMonths'] as num?)?.toInt(),
        price: (j['price'] as num?)?.toInt(),
      );
}

/// 연간 할인율(%) = round((1 − 연간 ÷ (월간 × 12)) × 100) — 서버 두 가격으로 계산한다.
/// 월간 가격이 0 이하면 0.
int yearlySavePct(int monthly, int yearly) {
  if (monthly <= 0) return 0;
  return ((1 - yearly / (monthly * 12)) * 100).round();
}

/// 증권사 한 곳의 연결 상태 + 입력 폼 라벨.
///
/// 표시명·발급처·라벨을 **서버가 준다.** 증권사가 늘어도 앱 배포 없이 목록에 나타나고,
/// 같은 자리를 회사마다 다르게 부르는 문제(토스 Client ID / 나무 App Key)도 여기서 풀린다.
class BrokerConnection {
  const BrokerConnection({
    required this.broker,
    required this.displayName,
    required this.issueUrl,
    required this.keyLabel,
    required this.secretLabel,
    required this.connected,
    required this.verified,
    required this.primary,
    this.verifiedAt,
  });

  final String broker;
  final String displayName;
  final String issueUrl;
  final String keyLabel;
  final String secretLabel;
  final bool connected;
  final bool verified;
  final bool primary;
  final String? verifiedAt;

  factory BrokerConnection.fromJson(Map<String, dynamic> j) => BrokerConnection(
    broker: (j['broker'] as String?) ?? '',
    displayName: (j['displayName'] as String?) ?? '',
    issueUrl: (j['issueUrl'] as String?) ?? '',
    keyLabel: (j['keyLabel'] as String?) ?? 'API Key',
    secretLabel: (j['secretLabel'] as String?) ?? 'API Secret',
    connected: (j['connected'] as bool?) ?? false,
    verified: (j['verified'] as bool?) ?? false,
    primary: (j['primary'] as bool?) ?? false,
    verifiedAt: j['verifiedAt'] as String?,
  );
}

class SubscriptionRepository {
  SubscriptionRepository(this._dio);
  final Dio _dio;

  dynamic _payload(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body['data'];
    return body;
  }

  Future<MyFeatures> getMyFeatures() async {
    try {
      final res = await _dio.get<dynamic>('/users/me/features');
      final p = _payload(res);
      return p is Map<String, dynamic>
          ? MyFeatures.fromJson(p)
          : MyFeatures.empty;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<SubscriptionPlanInfo>> getPlans() async {
    try {
      final res = await _dio.get<dynamic>('/subscriptions/plans');
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => SubscriptionPlanInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SubscriptionInfo?> getMySubscription() async {
    try {
      final res = await _dio.get<dynamic>('/subscriptions/me');
      final p = _payload(res);
      return p is Map<String, dynamic> ? SubscriptionInfo.fromJson(p) : null;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// [silent] — 전역 서버 원문 알림을 끈다(화면이 정한 글을 띄울 때).
  Future<void> subscribe(String planCode, {bool silent = false}) async {
    try {
      await _dio.post<dynamic>(
        '/subscriptions',
        data: {'planCode': planCode},
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cancelSubscription({String? reason, bool silent = false}) async {
    try {
      await _dio.delete<dynamic>(
        '/subscriptions/me',
        data: {'reason': reason},
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 전 증권사 연결 상태. **미연결 증권사도 포함**해 화면이 목록을 그린다.
  Future<List<BrokerConnection>> getBrokerConnections() async {
    try {
      final res = await _dio.get<dynamic>('/users/me/securities-credentials');
      final p = _payload(res);
      if (p is! List) return const [];
      return p
          .whereType<Map<String, dynamic>>()
          .map(BrokerConnection.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> registerBrokerCredential(
    String broker,
    String apiKey,
    String apiSecret, {
    bool silent = false,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/users/me/securities-credentials/$broker',
        data: {'apiKey': apiKey, 'apiSecret': apiSecret},
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> disconnectBrokerCredential(
    String broker, {
    bool silent = false,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/users/me/securities-credentials/$broker',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 가계부 자산 평가에 쓸 증권사를 지정한다.
  Future<void> setPrimaryBroker(String broker, {bool silent = false}) async {
    try {
      await _dio.put<dynamic>(
        '/users/me/securities-credentials/$broker/primary',
        options: silent ? Options(extra: {kSilentErrorToast: true}) : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
