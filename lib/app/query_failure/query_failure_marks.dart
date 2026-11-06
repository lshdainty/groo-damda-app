import 'package:flutter_riverpod/misc.dart' show ProviderBase, ProviderOrFamily;

import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/memo/application/memo_providers.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';

export 'package:groo_damda_app/features/stocks/application/securities_retry.dart'
    show isPollingProvider;

/// 참조 데이터 — 화면이 이름 · 선택지 · 배지를 채우려고 읽어 두는 조회(웹 `meta: { reference: true }` 와 같은 뜻).
///
/// 값 없이 실패하면 [ReferenceFailureNotice] 가 "일부 정보를 불러오지 못했어요." 한 줄 + [다시 시도] 로 알린다. 받아 둔 값이
/// 있는 채 다시 받기에 실패한 것은 값을 그대로 두고 알리지 않는다(웹과 같다). 공용 "새로 고치지 못했어요." 스낵바는 이 조회를
/// 보지 않는다(둘이 함께 뜨지 않게).
///
/// 이름은 웹 훅과 짝이다(결과표 I-wrap-b2b-app-result.md 대응표).
///
/// | 웹 훅(reference: true) | 앱 provider |
/// |---|---|
/// | useExpenseCategories | [categoriesProvider] |
/// | useAssets | [assetsProvider] |
/// | useUserCalendars | [userCalendarListProvider] |
/// | useCalendarHolidays | [holidayListProvider] |
/// | useEventLabels | [eventLabelsProvider] |
/// | useMyFeatures | [myFeaturesProvider] |
/// | useMySubscription | [mySubscriptionProvider] |
/// | useSubscriptionPlans | [subscriptionPlansProvider] |
/// | useMemoTags | [memoTagListProvider] |
/// | useTodoTags | [todoTagListProvider] |
/// | useUnreadCount | [unreadCountProvider] |
/// | useUserPreferences(예산 경고 기준) | [budgetAlertThresholdProvider] |
final List<ProviderOrFamily> referenceProviders = [
  categoriesProvider,
  assetsProvider,
  userCalendarListProvider,
  holidayListProvider,
  eventLabelsProvider,
  myFeaturesProvider,
  mySubscriptionProvider,
  subscriptionPlansProvider,
  memoTagListProvider,
  todoTagListProvider,
  unreadCountProvider,
  budgetAlertThresholdProvider,
];

/// 참조 조회인가 — [referenceProviders] 의 provider 또는 그 family 의 한 칸.
bool isReferenceProvider(ProviderBase<Object?> provider) =>
    referenceProviders.contains(provider) ||
    (provider.from != null && referenceProviders.contains(provider.from));
