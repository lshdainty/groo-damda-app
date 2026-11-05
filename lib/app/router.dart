import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/update/presentation/update_gate_screen.dart';
import 'package:groo_damda_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart'
    show AssetDetailScreen;
import 'package:groo_damda_app/features/asset/presentation/asset_screen.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_screen.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_settings_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_labels_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/features/card/presentation/card_benefits_screen.dart';
import 'package:groo_damda_app/features/category/presentation/category_screen.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_share_screen.dart';
import 'package:groo_damda_app/features/export/presentation/export_screen.dart';
import 'package:groo_damda_app/features/sms/domain/sms_paste_args.dart';
import 'package:groo_damda_app/features/sms/presentation/sms_inbox_screen.dart';
import 'package:groo_damda_app/features/sms/presentation/sms_paste_screen.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_screen.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_screen.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_screen.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_screen.dart';
import 'package:groo_damda_app/features/search/presentation/search_screen.dart';
import 'package:groo_damda_app/features/constellation/presentation/forest_report_screen.dart';
import 'package:groo_damda_app/features/constellation/presentation/night_sky_screen.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_screen.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_tag_management_screen.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_tag_management_screen.dart';
import 'package:groo_damda_app/features/auth/presentation/login_screen.dart';
import 'package:groo_damda_app/features/auth/presentation/withdrawn_screen.dart';
import 'package:groo_damda_app/features/auth/presentation/splash_screen.dart';
import 'package:groo_damda_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_screen.dart';
import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/features/more/presentation/more_screen.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/account_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/appearance_section.dart';
import 'package:groo_damda_app/features/settings/presentation/devices_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/hide_amounts_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/settings_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/update_screen.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_screen.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stock_pages.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_screen.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/features/subscription/presentation/securities_gate.dart';
import 'package:groo_damda_app/features/subscription/presentation/securities_link_screen.dart';
import 'package:groo_damda_app/features/subscription/presentation/subscription_screen.dart';
import 'package:groo_damda_app/shared/ds/catalog/ds_catalog_screen.dart';
import 'package:groo_damda_app/shared/widgets/branch_back_to_home.dart';
import 'package:groo_damda_app/shared/widgets/mobile_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      // 첫 부팅 세션 검증 중 (값 없음) → splash 유지
      if (auth.isLoading && !auth.hasValue) return null;

      final loggedIn = auth.hasValue && auth.value != null;
      final atSplash = loc == '/';
      final atLogin = loc == '/login';
      final atWithdrawn = loc == '/withdrawn';

      // 새 버전이 있으면 전체 화면으로 가로막고 알린다.
      //
      // 로그인보다 앞에 둔다. 강제 업데이트는 서버와 앱이 어긋나 잘못된 값을 주고받는
      // 걸 막으려는 건데, 로그인 뒤에 두면 구버전이 로그인 화면과 로그인 API 는 그대로
      // 탄다 — 정작 막아야 할 첫 요청이 빠져나간다.
      //
      // 확인이 끝나기 전(로딩)이나 서버를 못 읽었을 때는 막지 않는다. 네트워크가
      // 끊겼다고 사람을 앱 밖에 세워 둘 이유가 없다.
      //
      // 게이트 화면은 인증이 필요 없다 — version.json 도 APK 도 정적 파일이다.
      final status = ref.read(updateStatusProvider).value;
      final skipped = ref.read(skippedBuildProvider);
      final atGate = loc == '/update-gate';
      if (status?.shouldGate(skipped) ?? false) {
        return atGate ? null : '/update-gate';
      }
      // 알릴 게 없어졌는데 게이트에 남아 있으면(취소 직후 등) 내보낸다.
      if (atGate) return loggedIn ? '/home' : '/login';

      if (!loggedIn) {
        // 해지한 계정으로 로그인하려 했다(USER_021) — 로그인 화면의 에러 글이 아니라 해지
        // 완료 화면이다. 다시 눌러도 결과가 같으니 왜 안 되는지부터 말한다(웹 /withdrawn
        // 과 같은 화면). 여기서 보는 이유: 교환은 딥링크 리스너에서 돌아 로그인 화면이
        // 뜨기 전(콜드 스타트)에 실패가 떨어질 수 있고, 그러면 화면의 listen 은 못 듣는다.
        final e = auth.error;
        if (e is ApiException && e.isWithdrawn) {
          return atWithdrawn ? null : '/withdrawn';
        }
        // 해지 완료 화면은 로그아웃 상태에서 보는 화면이다 — 해지 직후의 로그아웃이
        // 로그인 화면으로 튕기지 않게 둔다. 떠날 때는 화면의 버튼이 /login 으로 보낸다.
        if (atWithdrawn) return null;
        // 로그아웃 상태에서 splash/login 외 접근 시 → /login
        return atLogin ? null : '/login';
      }

      // 로그인 상태에서 splash/login 머무르면 → /home
      if (atSplash || atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/withdrawn', builder: (_, _) => const WithdrawnScreen()),
      // 새 버전 안내 — 리다이렉트로만 들어온다(강제/일반은 화면이 스스로 가른다).
      GoRoute(
        path: '/update-gate',
        builder: (_, _) => const UpdateGateScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      // `?edit=<자산 id>` 면 그 자산의 수정 폼을 바로 연다(D9 — [잔액 고치기]·자산 상세
      // [수정]). 없거나 못 찾으면 목록으로 들어온다.
      // 자산(계좌) 상세 — 최상위 화면(하단 탭 바 없음). ← = pop. 옛 `/assets` 와 겹치지 않는다(I-17 35).
      GoRoute(
        path: '/asset/:assetId',
        builder: (_, state) => AssetDetailScreen(
          assetId: int.tryParse(state.pathParameters['assetId'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        path: '/account-card-manage',
        builder: (_, state) => AccountCardManageScreen(
          editAssetId: int.tryParse(state.uri.queryParameters['edit'] ?? ''),
        ),
      ),
      // /assets, /budget, /stats 는 shell branch 1 (가계부) 안 sub-routes 로
      // 이동 — 하단바 (MoneyTabBar) 가 shell scaffold 가 한 번 build 되어
      // sub-tab 전환 시 사라지지 않게 (사용자 의도: 안정적 고정 bottom bar).
      GoRoute(path: '/recurring', builder: (_, _) => const RecurringScreen()),
      GoRoute(path: '/categories', builder: (_, _) => const CategoryScreen()),
      GoRoute(path: '/presets', builder: (_, _) => const PresetScreen()),
      // 결제 문자로 기록 — 배너·알림에서 들어올 땐 문자를 extra 로 실어 바로 해석한다.
      GoRoute(
        path: '/sms-paste',
        builder: (_, state) {
          final args = SmsPasteArgs.from(state.extra);
          return SmsPasteScreen(
            initialText: args?.text,
            inboxId: args?.inboxId,
          );
        },
      ),
      // 아직 기록하지 않은 수신 문자 목록(안드로이드).
      GoRoute(path: '/sms-inbox', builder: (_, _) => const SmsInboxScreen()),
      // 예산 설정(웹 BudgetManager 정합) — 예산 개요 설정 버튼·설정 메뉴에서 push.
      GoRoute(
        path: '/budget/settings',
        builder: (_, _) => const BudgetSettingsScreen(),
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/memos', builder: (_, _) => const MemoScreen()),
      GoRoute(path: '/todos', builder: (_, _) => const TodoScreen()),
      // 밤하늘(성장·수집)·관측 리포트 — 할일 화면 [밤하늘] 패널에서 push 진입.
      GoRoute(path: '/night-sky', builder: (_, _) => const NightSkyScreen()),
      GoRoute(
        path: '/forest-report',
        builder: (_, _) => const ForestReportScreen(),
      ),
      GoRoute(
        path: '/settings/calendar-share',
        builder: (_, _) => const CalendarShareScreen(),
      ),
      GoRoute(
        path: '/settings/calendar-labels',
        builder: (_, _) => const CalendarLabelsScreen(),
      ),
      GoRoute(
        path: '/settings/todo-tags',
        builder: (_, _) => const TodoTagManagementScreen(),
      ),
      GoRoute(
        path: '/settings/memo-tags',
        builder: (_, _) => const MemoTagManagementScreen(),
      ),
      GoRoute(
        path: '/settings/securities',
        builder: (_, _) => const SecuritiesLinkScreen(),
      ),
      // 구독 관리 — 계정 > 구독·결제 줄에서 push 진입(I-14 3-2A, 옛 바텀시트를 대신한다).
      GoRoute(
        path: '/settings/subscription',
        builder: (_, _) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        builder: (_, _) => const AppearanceScreen(),
      ),
      // 금액 가리기 — 계정 > 보안에서, 그리고 화면의 눈 버튼에서 바로 들어온다.
      GoRoute(
        path: '/settings/hide-amounts',
        builder: (_, _) => const HideAmountsScreen(),
      ),
      // 로그인된 기기 — 계정 > 보안에서 push 진입.
      GoRoute(
        path: '/settings/devices',
        builder: (_, _) => const DevicesScreen(),
      ),
      GoRoute(
        path: '/settings/export-data',
        builder: (_, _) => const ExportScreen(),
      ),
      // 업데이트 — 평소엔 설정에서 들어와 확인하고, 강제일 때는 redirect 가 여기로
      // 몰아넣는다(그때는 뒤로 갈 수 없다).
      GoRoute(
        path: '/settings/update',
        builder: (_, _) => const UpdateScreen(),
      ),
      // 개발 전용 — 새 컴포넌트 라이브러리 카탈로그. 운영 빌드에는 길이 없다(설정 > 개발).
      if (kDebugMode)
        GoRoute(path: '/dev/ds', builder: (_, _) => const DsCatalogScreen()),
      GoRoute(path: '/dutch-pay', builder: (_, _) => const DutchPayScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/saving-goals',
        builder: (_, _) => const SavingGoalScreen(),
      ),
      GoRoute(
        path: '/card-benefits',
        builder: (_, _) => const CardBenefitsScreen(),
      ),
      // 증권 — 카드 혜택과 동일하게 전체(more)에서 push 진입, 뒤로가기로 복귀. 구독 게이트.
      GoRoute(
        path: '/stocks',
        builder: (_, _) => const SecuritiesGate(child: StocksScreen()),
        routes: [
          // 포트폴리오 구성 · 종목 상세는 화면(주소)이다 — 정적 경로가 먼저. 증권사마다 하나씩(토스 · 나무).
          GoRoute(
            path: 'toss/portfolio',
            builder: (_, _) => const SecuritiesGate(child: TossPortfolioPage()),
          ),
          GoRoute(
            path: 'toss/:symbol',
            builder: (_, state) => SecuritiesGate(
              child: TossStockDetailPage(
                symbol: state.pathParameters['symbol']!,
              ),
            ),
          ),
          GoRoute(
            path: 'namu/portfolio',
            builder: (_, _) => const SecuritiesGate(child: NamuPortfolioPage()),
          ),
          GoRoute(
            path: 'namu/:symbol',
            builder: (_, state) => SecuritiesGate(
              child: NamuStockDetailPage(
                symbol: state.pathParameters['symbol']!,
              ),
            ),
          ),
        ],
      ),

      // 옛 경로 — 가계부 묶음에서 그 탭을 고른 채로 간다(딥링크 · 북마크가 깨지지 않게).
      for (final tab in [MoneyTab.assets, MoneyTab.stats, MoneyTab.budget])
        GoRoute(path: tab.legacyPath, redirect: (_, _) => tab.location),

      // 모바일 셸 (홈/가계부/캘린더/전체 4개 분기)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MobileScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: DashboardScreen()),
              ),
            ],
          ),
          // 가계부 branch — 한 라우트(/expense) 안 Tabs 로 네 화면(가계부 · 자산 · 통계 ·
          // 예산)을 담는다. 고른 탭은 ?tab= 이고, 옛 경로(/assets · /stats · /budget)는
          // 위쪽 redirect 가 이 주소로 보낸다.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expense',
                pageBuilder: (_, state) {
                  final month = state.uri.queryParameters['month'];
                  final txId = int.tryParse(
                    state.uri.queryParameters['txId'] ?? '',
                  );
                  final assetId = int.tryParse(
                    state.uri.queryParameters['assetId'] ?? '',
                  );
                  return NoTransitionPage(
                    child: BranchBackToHome(
                      child: MoneyBundleScreen(
                        tab: MoneyTab.fromQuery(
                          state.uri.queryParameters['tab'],
                        ),
                        pages: [
                          ExpenseScreen(
                            key: ValueKey(
                              'expense-${month ?? ''}-${txId ?? ''}-${assetId ?? ''}',
                            ),
                            initialMonth: month,
                            focusTxId: txId,
                            initialAssetId: assetId,
                          ),
                          const AssetScreen(),
                          const StatsScreen(),
                          const BudgetScreen(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (_, _) => const NoTransitionPage(
                  child: BranchBackToHome(child: CalendarScreen()),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                pageBuilder: (_, _) => const NoTransitionPage(
                  child: BranchBackToHome(child: MoreScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// 로그인 상태·업데이트 상태 변화를 GoRouter 에 알려 redirect 를 재평가하게 만드는 브릿지.
///
/// 업데이트 확인은 비동기라 첫 redirect 때는 값이 없다. 여기서 듣지 않으면 "더 못 쓰는
/// 버전" 이라는 답이 와도 이미 지나간 뒤라 아무도 다시 묻지 않는다.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _subs = [
      ref.listen(authProvider, (_, _) => notifyListeners()),
      ref.listen(updateStatusProvider, (_, _) => notifyListeners()),
      // 건너뛰기가 기록되면 게이트가 풀려야 한다 — 안 들으면 재시작까지 갇힌다.
      ref.listen(skippedBuildProvider, (_, _) => notifyListeners()),
    ];
  }
  late final List<ProviderSubscription> _subs;

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    super.dispose();
  }
}
