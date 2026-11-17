import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 홈 · 가계부 · 캘린더 · 전체 — 탭 칸 순서 = branch index(캘린더 2 · 전체 3).
const int _kBranchCalendar = 2;

/// 모바일 셸 — 상단 바 + (가계부면 Line Tabs) + 본문(navigationShell) + 떠 있는 하단 탭 바.
/// `+` 는 [PBottomNavigation] 가운데 칸이다.
class MobileScaffold extends ConsumerStatefulWidget {
  const MobileScaffold({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends ConsumerState<MobileScaffold> {
  String? _lastPath;
  // iOS 27 Liquid Glass tabBarMinimizeBehavior — 스크롤 방향 누적 판정.
  final PBottomNavigationController _tabBarCompact =
      PBottomNavigationController();

  // branch 마다 마지막으로 스크롤한 세로 위치 — 탭을 다시 누르면 맨 위로 올린다.
  final Map<int, ScrollPosition> _positions = {};

  @override
  void dispose() {
    _tabBarCompact.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n is! ScrollEndNotification) {
      final ctx = n.context;
      final position = ctx == null ? null : Scrollable.maybeOf(ctx)?.position;
      if (position != null) {
        _positions[widget.navigationShell.currentIndex] = position;
      }
    }
    return _tabBarCompact.handleScroll(n);
  }

  /// 지금 탭을 다시 눌렀다 — 첫 화면이 아니면 첫 화면으로, 그리고 맨 위로.
  void _reselect(int branch) {
    widget.navigationShell.goBranch(branch, initialLocation: true);
    final position = _positions[branch];
    if (position != null && position.hasPixels && position.pixels > 0) {
      position.animateTo(0, duration: PDuration.d4, curve: PEasing.easing);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 셸(IndexedStack) 화면은 계속 mount 되어 initState 진입 갱신이 안 되므로,
    // 라우트가 바뀔 때 진입 경로가 watch 하는 keepAlive provider 를 갱신한다.
    // build 직전 호출이라 provider 변경은 microtask 로 다음 프레임에 미룬다.
    final router = GoRouterState.of(context);
    // 가계부 묶음(/expense)은 고른 탭의 경로로 적는다 — 탭이 바뀌어도 이 자리가 다시 돈다.
    final path = shellActivePath(router.uri, router.matchedLocation);
    if (path != _lastPath) {
      _lastPath = path;
      // 보는 화면이 바뀌었다(branch 또는 가계부 묶음 탭) — 줄어든 바를 편다. 줄어든 채로
      // 옮기면 라벨 없는 바만 남는다(bottom-navigation.md "줄어들기").
      _tabBarCompact.expand();
      Future.microtask(() {
        if (!mounted) return;
        // 지금 어느 화면이 앞인지 적어 둔다 — 상주 화면이 "내가 보이는가" 를 알 수
        // 있는 유일한 자리다(화면 안 GoRouterState 는 늘 자기 라우트를 돌려준다).
        // 진입 갱신보다 먼저 적는다: 갱신이 부르는 조회를 그 화면이 이어받으려면
        // 그때 이미 자기가 앞이라는 걸 알고 있어야 한다.
        ref.read(activeShellRouteProvider.notifier).setPath(path);
        invalidateKeepAliveForRoute(ref, path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final navigationShell = widget.navigationShell;
    final idx = navigationShell.currentIndex;
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    // 제목은 탭 이름 — 가계부 안 네 화면은 Line Tabs 가 가르므로 제목은 늘 "가계부".
    final titles = [l.navHome, l.navExpense, l.navCalendar, l.navMore];

    void onAddTx() {
      if (idx == _kBranchCalendar) {
        // 캘린더 탭 — 일정 등록
        showCalendarEventDialog(context, defaultDate: DateTime.now());
      } else {
        showAddTxSheet(context);
      }
    }

    PBottomNavigationItem item(
      int branch,
      IconData icon,
      IconData selectedIcon,
      String label,
    ) => PBottomNavigationItem(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      current: idx == branch,
      onTap: () => navigationShell.goBranch(branch),
      onReselect: () => _reselect(branch),
    );

    // 기기(제스처·하드웨어) 뒤로가기는 여기가 아니라 **branch 안 화면**이 받는다 —
    // lib/shared/widgets/branch_back_to_home.dart 의 BranchBackToHome 이고,
    // router.dart 가 홈이 아닌 branch 의 첫 화면마다 감싼다.
    //
    // 여기(셸 = 루트 네비게이터)에 걸었더니 옛 방식 뒤로가기만 받고 **예측형
    // (OnBackInvokedCallback)에서는 앱이 그대로 꺼졌다.** 이유와 근거는 그 위젯의
    // 주석에 있다. 두 겹으로 두면 어느 쪽이 진짜인지 헷갈려 여기서는 걷었다.
    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      body: Stack(
        children: [
          // 본문 — 상단 바 아래. 읽는 순서상 상단 바보다 **먼저** 그린다: 안쪽 Navigator 의
          // 경로가 앞서 그려진 형제를 가리는(BlockSemantics) 탓에, 상단 바를 본문 앞에 두면
          // 제목 · 검색 · 알림이 낭독 트리에서 통째로 사라진다.
          Positioned.fill(
            top: PTopNavigation.heightOf(context),
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: navigationShell,
            ),
          ),
          // 오른쪽 — 홈은 검색 + 알림, 그 외는 검색(임시 선택, Q-017).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PTopNavigation(
              type: PTopNavigationType.root,
              title: titles[idx],
              actions: [
                PTopNavigationIconButton(
                  icon: LucideIcons.search,
                  label: l.actionSearch,
                  onPressed: () => context.push('/search'),
                ),
                if (idx == 0)
                  PTopNavigationIconButton(
                    icon: LucideIcons.bell,
                    label: unread > 0
                        ? l.navNotificationsNew
                        : l.navNotifications,
                    notification: unread > 0,
                    onPressed: () => context.push('/notifications'),
                  ),
              ],
            ),
          ),
          // 떠 있는 알약 — 본문 위에 얹는다. 여백은 바가 가진다.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PBottomNavigation(
              semanticLabel: l.navMainMenu,
              controller: _tabBarCompact,
              items: [
                item(0, LucideIcons.house, LucideIcons.house500, l.navHome),
                item(
                  1,
                  LucideIcons.receiptText,
                  LucideIcons.receiptText500,
                  l.navExpense,
                ),
                item(
                  _kBranchCalendar,
                  LucideIcons.calendar1,
                  LucideIcons.calendar1500,
                  l.navCalendar,
                ),
                item(3, LucideIcons.menu, LucideIcons.menu500, l.navMore),
              ],
              add: PBottomNavigationAdd(
                label: idx == _kBranchCalendar ? l.calEventAdd : l.expAdd,
                onPressed: onAddTx,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
