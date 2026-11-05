/// 구독·기능권한 Riverpod providers. 증권 메뉴 게이트 + 설정.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';

final subscriptionRepositoryProvider = FutureProvider<SubscriptionRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return SubscriptionRepository(dio);
});

/// 내 기능권한 + 증권사 연결상태 — **실패를 그대로 던지는 원본**. 증권 게이트 · 증권 화면만 읽는다
/// (실패를 "권한 없음" · "연결 안 됨" 으로 읽어 사용자를 내보내거나 연결을 권하지 않으려고 — 실패는 실패로 말한다).
/// 나머지 호출처는 아래 [myFeaturesProvider] 를 그대로 쓴다.
final myFeaturesLoadProvider = FutureProvider<MyFeatures>((ref) async {
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getMyFeatures();
});

/// 내 기능권한 + 증권사 연결상태. 메뉴 게이트 단일 소스. 실패 시 empty(권한 없음).
/// 계약은 그대로다 — 원본 [myFeaturesLoadProvider] 를 읽어 실패만 empty 로 삼킨다(호출처 · 폴러 무변경).
final myFeaturesProvider = FutureProvider<MyFeatures>((ref) async {
  try {
    return await ref.watch(myFeaturesLoadProvider.future);
  } catch (_) {
    return MyFeatures.empty;
  }
});

/// 증권 기능권한 보유 여부(동기 — 로딩/에러 시 false).
final hasSecuritiesProvider = Provider<bool>((ref) {
  return ref.watch(myFeaturesProvider).asData?.value.hasSecurities ?? false;
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlanInfo>>((
  ref,
) async {
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getPlans();
});

final mySubscriptionProvider = FutureProvider<SubscriptionInfo?>((ref) async {
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getMySubscription();
});

/// 전 증권사 연결 상태(미연결 포함). 설정 화면이 목록을 그리는 소스.
final brokerConnectionsProvider = FutureProvider<List<BrokerConnection>>((
  ref,
) async {
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getBrokerConnections();
});

/// 증권사를 하나라도 연결했는지(동기 — 로딩/에러 시 false).
final hasBrokerConnectionProvider = Provider<bool>((ref) {
  return ref.watch(myFeaturesProvider).asData?.value.hasBrokerConnection ??
      false;
});
