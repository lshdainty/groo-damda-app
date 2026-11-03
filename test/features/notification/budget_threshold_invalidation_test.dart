// 예산 경고 임계값을 바꾸면 게이지 경고선이 **곧바로** 새 값이 된다.
//
// 알림 설정의 임계값 슬라이더는 `/users/me/preferences` 로 PATCH 하고
// `userPreferences` 만 갱신했다. 그런데 예산 화면의 게이지 경고선은 같은 엔드포인트를
// **따로 GET 하는** `budgetAlertThresholdProvider` 에서 온다. 이 provider 는
// autoDispose 가 아니고 홈은 셸(IndexedStack)에 상주해 dispose 되지도 않으므로,
// 저장 뒤 비우지 않으면 방금 내가 민 눈금이 60초 신선도 규칙이 돌 때까지 게이지에
// 안 선다 — **무효화는 내가 한 것, 시계는 남이 한 것**.
//
// I-06 — 홈은 예산 막대에 경고 색을 쓰지 않아 기준을 읽지 않는다. I-08 14 로 **예산 화면의 막대에서도 경고 색이 사라졌다** —
// 막대는 브랜드 · 넘침(위험) 둘뿐이다. 그래도 기준은 "예산 현황" 의 **"여유 n 카테고리"** 를 셀 때 남아 있으므로, 예산 화면이
// 그 수로 기준을 읽는지 잰다.
//
// 78% 쓴 카테고리 예산 하나: 기준 85 에서 여유 1, 70 으로 내리면 여유 0 이다. 수가 안 바뀌면 기준이 옛 값에 굳어 있다는 뜻이다.
//
// 설정 화면과 홈을 한 트리에 함께 띄우는 건 실제 상황 그대로다 — 설정은 홈 위로
// push 되고, 홈은 셸에 mount 된 채 남는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_slider.dart';

/// 이번 달 1일 (`_BudgetScreenState._ymdStart` 와 같은 규칙).
String _monthStart() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-01';
}

/// 로그인 조회를 네트워크로 내보내지 않는다 — 설정 화면이 이메일을 본다.
class _NoAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

UserPreferences _prefs(int threshold) => UserPreferences(
  pushEnabled: true,
  notifyPayment: true,
  notifyBudget: true,
  notifyAutoRecord: true,
  notifyDutchPay: true,
  notifyCalendar: true,
  notifyWeeklyReport: false,
  notifyMonthlyReport: false,
  budgetAlertThreshold: threshold,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  notificationSound: NotificationSound.defaultSound,
  vibrationEnabled: true,
  emailEnabled: false,
  emailFrequency: EmailFrequency.weekly,
  timezone: 'Asia/Seoul',
  defaultCurrency: 'KRW',
);

/// 서버 대신 값을 들고 있는 가짜. `serverThreshold` 는 게이지가 **따로** 물어보는
/// 그 자리다 — PATCH 가 성공해야만 바뀐다.
class _FakePrefsRepo extends UserPreferencesRepository {
  _FakePrefsRepo() : super(Dio());

  int serverThreshold = 85;

  /// PATCH 본문들 — 몇 번, 무엇이 나갔는지.
  final List<Map<String, dynamic>> patches = [];

  /// true 면 저장이 실패한다(낙관적 반영은 롤백된다).
  bool failNext = false;

  @override
  Future<UserPreferences> get() async => _prefs(serverThreshold);

  @override
  Future<UserPreferences> update(
    Map<String, dynamic> fields, {
    bool silent = false,
  }) async {
    patches.add(fields);
    if (failNext) throw Exception('저장 실패');
    serverThreshold = fields['budgetAlertThreshold'] as int? ?? serverThreshold;
    return _prefs(serverThreshold);
  }
}

/// "예산 현황" 의 "여유 n 카테고리" 의 n — 값 글(`PListValue.amount`)의 읽는 이름 "n 카테고리" 둘 중 둘째(첫째는 초과).
int _healthyCount(WidgetTester tester) {
  final labels = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.semanticsLabel)
      .whereType<String>()
      .where((s) => RegExp(r'^\d+ 카테고리$').hasMatch(s))
      .toList();
  expect(labels, hasLength(2), reason: '초과 · 여유 두 줄');
  return int.parse(labels[1].split(' ').first);
}

void main() {
  /// 임계값 provider 가 실제로 **다시 조회된 횟수**.
  late int thresholdReads;
  late _FakePrefsRepo repo;

  Future<void> pump(WidgetTester tester) async {
    // 예산 화면의 게이지와 설정의 슬라이더가 둘 다 만들어질 만큼 길게.
    tester.view.physicalSize = const Size(430, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    thresholdReads = 0;
    repo = _FakePrefsRepo();
    final start = _monthStart();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesRepositoryProvider.overrideWith((ref) async => repo),
          authProvider.overrideWith(_NoAuth.new),
          // 게이지가 읽는 별개 조회 — 비울 때마다 서버 값을 다시 본다.
          budgetAlertThresholdProvider.overrideWith((ref) async {
            thresholdReads++;
            return repo.serverThreshold;
          }),
          // 이번 달: 총 예산 10만 + 카테고리 예산 10만 중 7만 8천을 썼다 → 78%.
          monthBudgetsProvider.overrideWith(
            (ref, key) async => [
              Budget(
                rowId: 1,
                budgetAmount: 100000,
                budgetYear: key.year,
                budgetMonth: key.month,
              ),
              Budget(
                rowId: 2,
                categoryRowId: 7,
                budgetAmount: 100000,
                budgetYear: key.year,
                budgetMonth: key.month,
              ),
            ],
          ),
          rangeSummaryProvider.overrideWith(
            (ref, range) async => RangeSummary(
              startDate: range.startDate,
              endDate: range.endDate,
              totalExpense: range.startDate == start ? 78000 : 0,
              categoryBreakdown: range.startDate == start
                  ? const [
                      CategoryBreakdown(
                        categoryRowId: 7,
                        expenseType: 'EXPENSE',
                        totalAmount: 78000,
                      ),
                    ]
                  : const [],
            ),
          ),
          assetSummaryProvider.overrideWith(
            (ref, key) async => const AssetSummary(),
          ),
          budgetComplianceProvider.overrideWith(
            (ref, months) async => const [],
          ),
          monthExpensesProvider.overrideWith((ref, key) async => const []),
          categoriesProvider.overrideWith((ref) async => const []),
          dashboardSummaryProvider.overrideWith(
            (ref) async => DashboardSummary.fromJson(const <String, dynamic>{}),
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(
            body: Column(
              children: [
                // 셸에 상주하는 예산 화면.
                Expanded(child: BudgetScreen()),
                // 그 위로 push 된 설정 화면.
                Expanded(child: NotificationSettingsScreen()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 슬라이더를 [v] 로 민다 — `_ThresholdCard` 가 건 콜백 그대로 탄다.
  Future<void> slideTo(WidgetTester tester, double v) async {
    tester.widget<PSlider>(find.byType(PSlider)).onChanged!(v);
    await tester.pumpAndSettle();
  }

  testWidgets('임계값을 내리면 예산 현황의 여유 수가 60초를 안 기다리고 새 기준으로 센다', (tester) async {
    await pump(tester);

    // 78% <= 85% — 여유 1.
    expect(
      _healthyCount(tester),
      1,
      reason: '시작 상태가 이미 기준 밖이면 이 테스트는 아무것도 안 본다',
    );
    expect(thresholdReads, 1);

    await slideTo(tester, 70);

    // 그 키 하나만 나간다(부분 수정).
    expect(repo.patches, [
      {'budgetAlertThreshold': 70},
    ]);
    expect(
      _healthyCount(tester),
      0,
      reason:
          '78% 는 70% 기준을 넘었는데 여유가 그대로다 — '
          '저장 뒤 budgetAlertThresholdProvider 를 안 비웠다',
    );
    // 수가 바뀐 이유가 **다시 조회했기 때문**임을 못 박는다.
    expect(thresholdReads, 2);
  });

  testWidgets('저장이 실패하면 비우지 않는다 — 서버 값은 그대로다', (tester) async {
    await pump(tester);
    expect(thresholdReads, 1);

    repo.failNext = true;
    await slideTo(tester, 70);

    expect(repo.patches, hasLength(1), reason: 'PATCH 는 나갔다');
    expect(thresholdReads, 1, reason: '롤백된 저장까지 비우면 바뀌지도 않은 값을 헛되이 다시 물어본다');
    expect(_healthyCount(tester), 1);
  });
}
