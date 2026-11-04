import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/core/sync/query_freshness.dart';
import 'package:groo_damda_app/core/update/app_update.dart';

/// 거래(expense) 변경 후 파급되는 provider 일괄 무효화.
///
/// 거래 하나가 바뀌면 화면 여러 곳의 숫자가 함께 달라진다. 자산 잔액은 백엔드가
/// 거래 history 로 계산하고, 통계·요약·예산·홈 위젯은 그 거래를 다시 집계한다.
///
/// 여기 든 provider 는 **autoDispose 가 아니다.** 게다가 홈·가계부·통계는 탭
/// 셸(`IndexedStack`)에 계속 mount 되어 dispose 되지도 않는다 — 한 번 읽힌 값은
/// 여기서 비우지 않는 한 앱을 끌 때까지 그대로다. 탭을 오가거나 화면을 다시 열어도
/// 갱신되지 않고, 당겨서 새로고침해야만 풀린다.
///
/// **화면이 실제로 읽는 것만 넣는다.** 아무도 안 읽는 provider 를 끼워 두면 목록만
/// 길어지고 "갱신하고 있다" 는 착시가 생겨, 정작 빠진 것을 못 찾는다.
///
/// family provider 는 base 를 넘기면 모든 인스턴스가 무효화된다.
void invalidateAfterExpenseChange(WidgetRef ref) =>
    _invalidateExpenseChange(ref.invalidate);

/// [invalidateAfterExpenseChange] 의 컨테이너판 — 화면(State)이 사라진 뒤에도 나가야 하는 요청(시트를 닫은 뒤 스낵바의 [다시 시도])이 쓴다.
void invalidateAfterExpenseChangeIn(ProviderContainer container) =>
    _invalidateExpenseChange(container.invalidate);

void _invalidateExpenseChange(
  void Function(ProviderOrFamily provider) invalidate,
) {
  // 자산 — 잔액·순자산은 거래 이력에서 계산된다.
  invalidate(assetsProvider);
  invalidate(assetSummaryProvider);
  invalidate(netWorthTrendProvider);
  invalidate(assetByIdProvider);
  invalidate(expensesByAssetProvider);
  invalidate(assetBalanceTrendProvider);
  invalidate(assetTransfersProvider);
  invalidate(assetPeriodExpensesProvider);

  // 홈 — 이번 달 지출·예산·위젯이 전부 이 거래를 센다.
  // 홈 합계는 `요약 ?? 목록합` 순서라, 옛 요약이 살아 있으면 새 목록으로 폴백조차
  // 하지 않는다. 요약을 비우지 않으면 "오늘 목록만 바뀌는" 비대칭이 남는다.
  invalidate(dashboardSummaryProvider);
  invalidate(monthBudgetsProvider);

  // 통계 — 60초 규칙([_invalidateStale])이 진입·복귀에서 **각자** 판정하는 다섯.
  // 여기서는 시간과 무관하게 다섯을 **함께** 비운다(이 기기에서 바꾼 값이다).
  // rangeSummary 는 홈 합계도 같이 읽는다.
  invalidate(rangeSummaryProvider);
  invalidate(rangeExpensesProvider);
  invalidate(heatmapProvider);
  invalidate(merchantSummaryProvider);
  invalidate(merchantMonthExpensesProvider);

  // 예산·카드 실적도 그 달 지출을 다시 센다.
  invalidate(budgetComplianceProvider);
  invalidate(cardPerformanceProvider);
  // 카드 청구(회차 금액·[결제 취소])도 거래에서 나온다. 빠져 있던 동안 거래를 고치면
  // 자산 목록의 잔액은 바로 맞는데 카드 상세의 회차 금액·버튼만 앱을 다시 켤 때까지 옛
  // 값이었다 — 환급이 나간 회차에 [결제 취소] 가 보이기도 했다(2026-09-22 iOS 시뮬레이터).
  invalidate(cardBillingProvider);

  // 월별 거래 목록(`monthExpensesProvider`)은 부르는 쪽이 바뀐 달만 짚어 비운다 —
  // 여기서 base 로 밀면 안 본 달까지 전부 다시 받는다.
}

/// 자산(계좌·카드·투자) 생성·수정·삭제 후 무효화.
///
/// 자산 목록만 비우면 순자산·추이·청구·실적이 옛 값으로 남는다. 전부 별도 조회이고,
/// 셸에 상주하는 화면이 읽으므로 스스로 다시 받지 않는다.
///
/// 거래는 건드리지 않는다 — 자산을 고쳐도 그 자산에 달린 거래 자체는 그대로다.
/// 거래까지 바뀌는 경로(카드 결제·이체 삭제 등)는 [invalidateAfterExpenseChange] 를 쓴다.
void invalidateAfterAssetChange(WidgetRef ref) {
  ref.invalidate(assetsProvider);
  ref.invalidate(assetSummaryProvider);
  ref.invalidate(netWorthTrendProvider);
  ref.invalidate(assetByIdProvider);
  ref.invalidate(cardBillingProvider);
  ref.invalidate(cardPerformanceProvider);
}

/// 탭이 진입할 때 60초 규칙으로 다시 받는 조회 — **그 화면이 실제로 읽는 것만**.
///
/// 셸(`IndexedStack`)에 상주하는 6화면은 `initState` 가 다시 돌지 않고, 화면이 읽는
/// provider 도 대부분 autoDispose 가 아니다. 그래서 진입할 때 비우지 않으면 다른
/// 기기에서 바꾼 값이 **앱을 다시 켤 때까지** 안 보인다. 예전에는 그 자리를 탭마다
/// 서너 줄씩 **시간과 무관하게 무조건** 비우는 것으로 막았는데, 그러면 탭을 왕복하는
/// 것만으로 같은 조회가 계속 나가고 화면이 스켈레톤으로 껌뻑였다.
///
/// 웹은 이걸 `staleTime: 60_000` 한 줄로 얻는다 — 화면에 붙을 때마다 "60초 지났으면
/// 다시 받는다". 여기 목록이 그 한 줄의 앱 판이다.
///
/// ## 목록에 넣는 것 / 안 넣는 것
///
/// **서버에서 받아 오는 것만 넣는다.** `hideCardProvider`(금액 가리기)·
/// `maskFlagsProvider`·`holidayVisibleProvider`(공휴일 표시)는 조회가 아니라
/// **사용자가 켜 둔 토글**이다. 넣으면 탭을 왕복할 때마다 가려 둔 금액이 드러난다.
///
/// 화면이 안 읽는 provider 도 넣지 않는다. 목록만 길어지고 "갱신하고 있다" 는 착시가
/// 생겨 정작 빠진 것을 못 찾는다.
///
/// 일부러 뺀 것 셋:
/// - `investmentValuationMapProvider` — 자산 화면이 **10초 타이머**로 직접 민다.
///   60초 시계를 얹어도 늘 방금 받은 상태라 아무 일도 안 일어난다
/// - `unreadCountProvider` — 탭이 아니라 셸 헤더(종 배지)가 읽고,
///   알림 폴러가 30초마다 새 알림을 보면 스스로 비운다
/// - `myFeaturesProvider`(전체 탭의 증권 메뉴 노출) — 이 provider 는 실패를
///   `MyFeatures.empty` 로 삼킨다. 자주 비울수록 **한 번의 네트워크 실패로 결제한
///   기능이 메뉴에서 사라질** 확률만 오른다. 구독은 앱 안에서 바뀌면 그 화면이 비운다
const tabQueries = <String, List<ServerQuery>>{
  '/home': [
    ServerQuery.categories,
    ServerQuery.monthExpenses,
    ServerQuery.assetSummary,
    ServerQuery.dashboardSummary,
    ServerQuery.rangeSummary,
    ServerQuery.monthBudgets,
    ServerQuery.budgetAlertThreshold,
  ],
  '/expense': [
    ServerQuery.categories,
    ServerQuery.monthExpenses,
    ServerQuery.assets,
    ServerQuery.assetTransfers,
    // 거래 상세 dialog("이전 거래")는 이 탭의 목록에서 열린다(홈의 오늘 지출도
    // `/expense?txId=` 로 넘어온다). 통계 화면은 이 조회를 읽지 않는다.
    ServerQuery.merchantMonthExpenses,
  ],
  '/assets': [
    ServerQuery.assets,
    ServerQuery.assetSummary,
    ServerQuery.netWorthTrend,
    ServerQuery.savingGoalList,
  ],
  '/stats': [
    ServerQuery.categories,
    ServerQuery.rangeSummary,
    ServerQuery.rangeExpenses,
    ServerQuery.heatmap,
    ServerQuery.merchantSummary,
  ],
  '/budget': [
    ServerQuery.categories,
    ServerQuery.monthBudgets,
    ServerQuery.budgetAlertThreshold,
    ServerQuery.budgetCompliance,
    ServerQuery.rangeSummary,
  ],
  '/calendar': [
    ServerQuery.userCalendarList,
    ServerQuery.monthEvents,
    ServerQuery.holidayList,
    // 라벨은 일정 등록·수정 dialog 가 읽는다 — 캘린더 탭에서만 열리는 dialog 다.
    ServerQuery.eventLabels,
  ],
};

/// keepAlive(앱 세션 캐시) provider 일괄 무효화.
///
/// 이 provider 들은 `ref.keepAlive()` 로 앱 세션 내내 캐시되어 자동 refetch 되지
/// 않는다. 다른 클라이언트(웹 등)에서 변경된 내용을 따라잡기 위해 앱이
/// 포그라운드로 복귀할 때 한 번에 무효화한다(다음 watch 시 refetch).
/// family provider 는 base 를 넘기면 모든 인스턴스가 무효화된다.
///
/// ## 탭이 읽는 것은 시각을 본다
///
/// 화면이 읽는 조회([tabQueries] 에 든 것)는 [_invalidateStale] 을 그대로 태운다 —
/// 진입 갱신과 **같은 판정, 같은 목록**이다. 여기 남는 무조건 무효화는 **어느 탭도
/// 안 읽는** 세션 캐시뿐이다(전체 탭에서 push 로 들어가는 화면들 · 새 버전 확인).
///
/// 낡음은 **흘러간 시간**의 함수지 그동안 앱이 보였느냐의 함수가 아니다. 다른
/// 기기에서 값이 바뀔 확률은 내 앱이 백그라운드에 있었다고 달라지지 않는다.
/// 복귀가 "오래 떠나 있었다" 는 신호인 것은 실제로 오래 걸렸을 때뿐인데, 그건
/// 시계가 이미 재고 있다 — 1분 넘게 나갔다 오면 전부 stale 이라 여기서 무조건
/// 비우는 것과 결과가 같다. 갈리는 건 홈 버튼을 눌렀다 3초 만에 돌아온 경우뿐이고,
/// 거기서 다시 받는 것은 이 앱이 스스로 정한 "60초 안이면 새 값" 과 어긋난다
/// (웹 react-query 의 창 포커스 재조회도 stale 인 것만 다시 받는다).
///
/// 비용은 요청 수만이 아니다 — 화면 카드들은 이전 값을 들고 있어도 `isLoading`
/// 이면 스켈레톤을 그린다. 무조건 비우면 잠깐 나갔다 올 때마다 보고 있던 화면이
/// 껌뻑인다.
///
/// **[ServerQuery.values] 를 통째로 태우는 게 요점이다.** 예전엔 여기에만 든 것과
/// 진입에만 든 것이 갈려 있어서, 통계 탭을 켜 둔 채 앱을 접었다 켜면 합계만 새 값이고
/// 히트맵·가맹점·추이는 옛 값이었다. 목록이 두 벌이면 언젠가 어긋난다.
void invalidateKeepAliveProviders(WidgetRef ref) {
  // 어느 탭도 안 읽는 세션 캐시 — 전체(more) 탭에서 push 로 들어가는 화면들이 읽는다.
  // 그 화면들은 셸에 상주하지 않지만 provider 가 keepAlive 라 값이 굳는다.
  ref.invalidate(todoTagListProvider);
  ref.invalidate(memoTagListProvider);
  // 카드 청구 — 카드 상세(탭이 아니라 자산 탭에서 여는 시트)가 읽는다. 다른 기기에서
  // 거래를 고쳤으면 복귀할 때 회차 금액이 바뀌어야 한다. 안 읽히고 있으면 no-op 이다.
  ref.invalidate(cardBillingProvider);
  // 탭이 읽는 것은 전부 시각을 본다 — 진입 갱신과 **같은 함수·같은 목록**이다.
  _invalidateStale(ref, ServerQuery.values);
  // 새 버전 확인도 여기 태운다 — 예전엔 앱을 켤 때 한 번뿐이라, 오래 띄워 둔 앱은
  // 새 버전이 나와도 끌 때까지 몰랐다. version.json 은 1KB 정적 파일에 5초 타임아웃이라
  // resume 마다 한 번 더 물어봐도 부담이 없다.
  ref.invalidate(updateStatusProvider);
}

/// 셸(IndexedStack) 화면 진입 갱신.
///
/// `/home`·`/expense`·`/assets`·`/stats`·`/budget`·`/calendar` 는 셸에 계속 mount
/// 되어 `initState` 가 재실행되지 않으므로, 라우트가 바뀔 때 **그 화면이 읽는 조회만**
/// ([tabQueries]) 60초 규칙으로 판정한다. 다른 탭 것은 건드리지 않는다.
void invalidateKeepAliveForRoute(WidgetRef ref, String path) {
  _invalidateStale(ref, tabQueries[path] ?? const <ServerQuery>[]);
}

/// [queries] 중 마지막으로 **받아 온 지** 60초가 지난 것만 비운다.
///
/// 부르는 자리는 둘이다: 탭 **진입**([invalidateKeepAliveForRoute])과 **포그라운드
/// 복귀**([invalidateKeepAliveProviders]). 둘 다 "지금 화면에 값을 내놓아야 하는
/// 순간" 이고, 낡았는지는 어느 쪽이든 같은 시계로 잰다.
///
/// 기준은 **마지막 성공 조회 시각**([QueryFreshness])이지 마지막 무효화 시각이
/// 아니다 — 무효화는 아무도 그 provider 를 안 보고 있으면 조회로 이어지지 않으므로,
/// 비운 시각을 기준으로 삼으면 실제로는 한 번도 안 받은 채 시계만 돈다.
///
/// **판정은 provider 마다 따로 한다.** "하나라도 낡았으면 다 비운다" 가 아니다 —
/// 각자 자기 [ServerQuery] 칸의 시각을 보므로, 방금 받은 것은 남이 낡았어도 그대로
/// 두고 낡은 것만 비운다. 탭마다 읽는 것이 다르고 겹치는 것도 일부뿐이라, 칸을
/// 공유하면 남의 탭에 들렀다 온 것만으로 내 탭이 새 값을 못 받는다.
///
/// 60초 안인 것에는 **아무것도 하지 않는다**(요청 0회). 한 번도 안 받은 것은
/// 비운다 — 안 읽힌 provider 를 비우는 것은 no-op 이다.
///
/// 타이머·폴링은 없다. 화면에 들어오는 순간과 포그라운드로 돌아오는 순간에만
/// 비교한다. 거래를 바꿨을 때의 무효화([invalidateAfterExpenseChange])는 시간과
/// 무관하게 즉시 비운다 — **무효화는 "내가 한 것", 시계는 "남이 한 것"** 이다.
void _invalidateStale(WidgetRef ref, Iterable<ServerQuery> queries) {
  final now = ref.read(freshnessClockProvider)();
  final freshness = ref.read(queryFreshnessProvider);
  for (final query in queries) {
    if (freshness.isStaleAt(query, now)) _invalidateQuery(ref, query);
  }
}

/// 키 ↔ provider 짝 — 한 줄이 한 조회다.
///
/// `default` 를 두지 않아 [ServerQuery] 에 값을 더하면 **컴파일이 안 된다.** 셋 중
/// 이 자리만 컴파일러가 지켜 준다 — 나머지 둘(provider 본문의
/// `markQueryFetched` · [tabQueries] 등재)은 테스트가 지킨다.
void _invalidateQuery(WidgetRef ref, ServerQuery query) {
  switch (query) {
    case ServerQuery.categories:
      ref.invalidate(categoriesProvider);
    case ServerQuery.monthExpenses:
      ref.invalidate(monthExpensesProvider);
    case ServerQuery.rangeExpenses:
      ref.invalidate(rangeExpensesProvider);
    case ServerQuery.merchantMonthExpenses:
      ref.invalidate(merchantMonthExpensesProvider);
    case ServerQuery.assetTransfers:
      ref.invalidate(assetTransfersProvider);
    case ServerQuery.assets:
      ref.invalidate(assetsProvider);
    case ServerQuery.assetSummary:
      ref.invalidate(assetSummaryProvider);
    case ServerQuery.netWorthTrend:
      ref.invalidate(netWorthTrendProvider);
    case ServerQuery.savingGoalList:
      ref.invalidate(savingGoalListProvider);
    case ServerQuery.dashboardSummary:
      ref.invalidate(dashboardSummaryProvider);
    case ServerQuery.monthBudgets:
      ref.invalidate(monthBudgetsProvider);
    case ServerQuery.budgetAlertThreshold:
      ref.invalidate(budgetAlertThresholdProvider);
    case ServerQuery.budgetCompliance:
      ref.invalidate(budgetComplianceProvider);
    case ServerQuery.rangeSummary:
      ref.invalidate(rangeSummaryProvider);
    case ServerQuery.heatmap:
      ref.invalidate(heatmapProvider);
    case ServerQuery.merchantSummary:
      ref.invalidate(merchantSummaryProvider);
    case ServerQuery.monthEvents:
      ref.invalidate(monthEventsProvider);
    case ServerQuery.userCalendarList:
      ref.invalidate(userCalendarListProvider);
    case ServerQuery.eventLabels:
      ref.invalidate(eventLabelsProvider);
    case ServerQuery.holidayList:
      ref.invalidate(holidayListProvider);
  }
}
