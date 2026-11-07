// 다시 받는 동안 이전 값을 그대로 보여 준다 — 여섯 탭 화면의 껌뻑임 방지.
//
// 탭 진입 재조회(`ref.invalidate`)는 Riverpod 에서 **이전 값을 들고 있는** 로딩
// 상태를 만든다(`isLoading && hasValue` 가 동시에 참). 화면이 `isLoading` 만 보고
// 스켈레톤을 그리면, 들고 있는 값을 버리고 회색 박스를 깔았다가 응답이 오면 다시
// 그린다 — 탭을 옮길 때마다 화면이 껌뻑인다. 재조회가 늘어날수록 더 나빠진다.
//
// 그래서 기준은 하나다: **이전 값이 있으면 그대로 그린다. 없을 때만 스켈레톤.**
// 빈 목록도 **받아 온 값**이라 스켈레톤이 아니라 빈 상태 문구가 맞다.
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 직접 띄워 확인한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 는 flutter_riverpod 본체가 아니라 misc 에서 나온다.
import 'package:flutter_riverpod/misc.dart' show Override, ProviderOrFamily;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../support/plain_text.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart' as dsskel;

import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_screen.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/domain/budget_compliance.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_screen.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:groo_damda_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_screen.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_screen.dart';

/// 첫 조회만 값을 주고 **그 뒤 재조회는 끝나지 않는다** — 화면을
/// "다시 받는 중(이전 값 보유)" 상태로 굳혀 놓고 무엇을 그리는지 본다.
///
/// family provider 는 키마다 따로 센다. 한 벌로 세면 `rangeSummary` 처럼
/// 이번 기간·지난 기간 두 키를 쓰는 자리에서 지난 기간이 첫 조회조차 못 받는다.
class _ServeOnce<K, T> {
  _ServeOnce(this._build);
  final T Function(K key) _build;
  final _served = <K>{};

  Future<T> call(K key) {
    if (!_served.add(key)) return Completer<T>().future;
    return Future<T>.value(_build(key));
  }
}

/// 키가 없는 provider 용.
class _ServeOnceSingle<T> {
  _ServeOnceSingle(this._build);
  final T Function() _build;
  var _served = false;

  Future<T> call() {
    if (_served) return Completer<T>().future;
    _served = true;
    return Future<T>.value(_build());
  }
}

ProviderContainer _containerOf(WidgetTester tester, Finder screen) =>
    ProviderScope.containerOf(tester.element(screen), listen: false);

/// 탭 진입 재조회를 그대로 재현한다 — `ref.invalidate` 한 뒤 한 프레임.
///
/// **`Duration.zero` 를 빼면 안 된다.** Riverpod 은 무효화를 0초 `Timer` 로
/// 흘려보내는데(`UncontrolledProviderScope._flutterVsync`), 인자 없는 `pump()` 는
/// 가짜 시계를 돌리지 않아 그 타이머가 뜨지 않는다. 그러면 화면은 재조회를
/// 아예 못 보고 테스트는 **아무것도 확인하지 않은 채** 통과한다.
Future<void> _refetch(
  WidgetTester tester,
  ProviderContainer container,
  ProviderOrFamily provider,
) async {
  container.invalidate(provider);
  await tester.pump(Duration.zero);
}

/// 한 화면이 세로로 다 들어가는 뷰포트 — 화면 아래쪽 카드도 build 된다
/// (`ListView` 는 화면 밖 자식을 mount 하지 않아 `find` 가 못 본다).
void _tallView(WidgetTester tester, {double height = 3600}) {
  tester.view.physicalSize = Size(390 * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: home),
  ),
);

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  final now = DateTime.now();

  // ─── 홈 ────────────────────────────────────────────────────────────────
  group('홈 — 예산 섹션', () {
    Future<void> pump(WidgetTester tester, {required bool serveBudgets}) async {
      _tallView(tester, height: 2400);
      final budgets = _ServeOnce<BudgetMonthKey, List<Budget>>(
        (_) => const <Budget>[],
      );
      await tester.pumpWidget(
        _app(const DashboardScreen(), [
          assetSummaryProvider.overrideWith(
            (ref, key) async => const AssetSummary(),
          ),
          rangeSummaryProvider.overrideWith(
            (ref, range) async => RangeSummary(
              startDate: range.startDate,
              endDate: range.endDate,
            ),
          ),
          monthExpensesProvider.overrideWith(
            (ref, key) async => const <Expense>[],
          ),
          categoriesProvider.overrideWith((ref) async => const []),
          budgetAlertThresholdProvider.overrideWith((ref) async => 85),
          dashboardSummaryProvider.overrideWith(
            (ref) async => DashboardSummary.fromJson(const <String, dynamic>{}),
          ),
          monthBudgetsProvider.overrideWith(
            serveBudgets
                ? (ref, key) => budgets(key)
                : (ref, key) => Completer<List<Budget>>().future,
          ),
        ]),
      );
    }

    testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
      await pump(tester, serveBudgets: false);
      await tester.pump();

      // 스켈레톤은 무한 애니메이션이라 pumpAndSettle 이 아니라 pump 로 본다.
      expect(find.byType(dsskel.PSkeleton), findsWidgets);
    });

    testWidgets('빈 목록은 스켈레톤이 아니라 빈 상태 문구다', (tester) async {
      await pump(tester, serveBudgets: true);
      await tester.pumpAndSettle();

      expect(findPlain('등록된 예산이 없어요'), findsOneWidget);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });

    testWidgets('재조회 중에도 빈 상태 문구가 그대로 — 스켈레톤이 끼어들지 않는다', (tester) async {
      await pump(tester, serveBudgets: true);
      await tester.pumpAndSettle();

      await _refetch(
        tester,
        _containerOf(tester, find.byType(DashboardScreen)),
        monthBudgetsProvider,
      );

      expect(findPlain('등록된 예산이 없어요'), findsOneWidget);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });
  });

  // ─── 통계 ──────────────────────────────────────────────────────────────
  group('통계 — 카테고리 도넛', () {
    Future<void> pump(WidgetTester tester, {required bool serveRange}) async {
      _tallView(tester, height: 1200);
      final range = _ServeOnce<DateRange, RangeSummary>(
        (key) => RangeSummary(
          startDate: key.startDate,
          endDate: key.endDate,
          totalExpense: 120000,
          categoryBreakdown: const [
            CategoryBreakdown(
              categoryRowId: 1,
              categoryName: '식비',
              expenseType: 'EXPENSE',
              totalAmount: 120000,
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        _app(const StatsScreen(), [
          categoriesProvider.overrideWith((ref) async => const []),
          rangeExpensesProvider.overrideWith((ref, key) async => const []),
          merchantSummaryProvider.overrideWith(
            (ref, range) async => const <MerchantSummary>[],
          ),
          heatmapProvider.overrideWith(
            (ref, range) async => const <HeatmapCell>[],
          ),
          rangeSummaryProvider.overrideWith(
            serveRange
                ? (ref, key) => range(key)
                : (ref, key) => Completer<RangeSummary>().future,
          ),
        ]),
      );
    }

    testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
      await pump(tester, serveRange: false);
      await tester.pump();

      expect(find.byType(dsskel.PSkeleton), findsWidgets);
    });

    testWidgets('재조회 중에도 이전 카테고리가 그대로 보인다', (tester) async {
      await pump(tester, serveRange: true);
      await tester.pumpAndSettle();
      expect(findPlain('식비'), findsWidgets);
      expect(find.byType(dsskel.PSkeleton), findsNothing);

      await _refetch(
        tester,
        _containerOf(tester, find.byType(StatsScreen)),
        rangeSummaryProvider,
      );

      expect(findPlain('식비'), findsWidgets);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });
  });

  // ─── 가계부 ────────────────────────────────────────────────────────────
  group('가계부 — 거래 목록', () {
    testWidgets('재조회 중에도 이전 거래가 그대로 보인다', (tester) async {
      _tallView(tester, height: 1600);
      final tx = _ServeOnce<MonthKey, List<Expense>>(
        (_) => [
          Expense(
            rowId: 1,
            expenseType: 'EXPENSE',
            amount: 12000,
            description: '점심값',
            expenseDate: '${_ymd(now)}T00:00:01',
          ),
        ],
      );
      await tester.pumpWidget(
        _app(const ExpenseScreen(), [
          categoriesProvider.overrideWith((ref) async => const []),
          assetsProvider.overrideWith((ref) async => const <Asset>[]),
          assetTransfersProvider.overrideWith((ref, key) async => const []),
          monthExpensesProvider.overrideWith((ref, key) => tx(key)),
        ]),
      );
      await tester.pumpAndSettle();
      expect(findPlain('점심값'), findsWidgets);

      await _refetch(
        tester,
        _containerOf(tester, find.byType(ExpenseScreen)),
        monthExpensesProvider,
      );

      expect(findPlain('점심값'), findsWidgets);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });
  });

  // ─── 자산 ──────────────────────────────────────────────────────────────
  group('자산 — 저축 목표', () {
    Future<void> pump(WidgetTester tester, {required bool serveGoals}) async {
      _tallView(tester, height: 2400);
      final goals = _ServeOnceSingle<List<SavingGoal>>(
        () => const <SavingGoal>[],
      );
      await tester.pumpWidget(
        _app(const AssetScreen(), [
          // 자산이 하나도 없으면 화면 전체가 빈 상태로 바뀌어 저축 목표 섹션이
          // 아예 그려지지 않는다 — 계좌 하나를 둔다.
          assetsProvider.overrideWith(
            (ref) async => const [
              Asset(
                rowId: 1,
                assetName: '주거래',
                assetType: 'BANK_ACCOUNT',
                balance: 1000000,
                isIncludedInTotal: 'Y',
              ),
            ],
          ),
          assetSummaryProvider.overrideWith(
            (ref, key) async => const AssetSummary(),
          ),
          netWorthTrendProvider.overrideWith((ref, months) async => const []),
          investmentValuationMapProvider.overrideWith((ref) async => const {}),
          savingGoalListProvider.overrideWith(
            serveGoals
                ? (ref) => goals()
                : (ref) => Completer<List<SavingGoal>>().future,
          ),
        ]),
      );
    }

    testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
      await pump(tester, serveGoals: false);
      await tester.pump();

      expect(find.byType(dsskel.PSkeleton), findsWidgets);
    });

    testWidgets('재조회 중에도 빈 상태 문구가 그대로 — 스켈레톤이 끼어들지 않는다', (tester) async {
      await pump(tester, serveGoals: true);
      await tester.pumpAndSettle();
      expect(findPlain('설정에서 저축 목표를 추가해보세요.'), findsOneWidget);

      await _refetch(
        tester,
        _containerOf(tester, find.byType(AssetScreen)),
        savingGoalListProvider,
      );

      expect(findPlain('설정에서 저축 목표를 추가해보세요.'), findsOneWidget);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });
  });

  // ─── 예산 ──────────────────────────────────────────────────────────────
  group('예산 — 이행률 카드', () {
    Future<void> pump(
      WidgetTester tester, {
      required bool serveCompliance,
    }) async {
      _tallView(tester, height: 3200);
      final compliance = _ServeOnce<int, List<BudgetComplianceMonth>>(
        (_) => const <BudgetComplianceMonth>[],
      );
      await tester.pumpWidget(
        _app(const BudgetScreen(), [
          categoriesProvider.overrideWith((ref) async => const []),
          budgetAlertThresholdProvider.overrideWith((ref) async => 85),
          rangeSummaryProvider.overrideWith(
            (ref, range) async => RangeSummary(
              startDate: range.startDate,
              endDate: range.endDate,
            ),
          ),
          // 전체 상한이 하나는 있어야 이행률 카드가 그려진다(없으면 빈 화면).
          monthBudgetsProvider.overrideWith(
            (ref, key) async => [
              Budget(
                rowId: 1,
                budgetAmount: 500000,
                budgetYear: key.year,
                budgetMonth: key.month,
              ),
            ],
          ),
          budgetComplianceProvider.overrideWith(
            serveCompliance
                ? (ref, months) => compliance(months)
                : (ref, months) =>
                      Completer<List<BudgetComplianceMonth>>().future,
          ),
        ]),
      );
    }

    testWidgets('첫 로딩 — 값이 아직 없으면 스켈레톤을 그린다', (tester) async {
      await pump(tester, serveCompliance: false);
      await tester.pump();

      expect(find.byType(dsskel.PSkeleton), findsWidgets);
    });

    testWidgets('재조회 중에도 빈 상태 문구가 그대로 — 스켈레톤이 끼어들지 않는다', (tester) async {
      await pump(tester, serveCompliance: true);
      await tester.pumpAndSettle();
      expect(findPlain('아직 이행률 데이터가 없어요'), findsOneWidget);

      await _refetch(
        tester,
        _containerOf(tester, find.byType(BudgetScreen)),
        budgetComplianceProvider,
      );

      expect(findPlain('아직 이행률 데이터가 없어요'), findsOneWidget);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });
  });

  // ─── 캘린더 ────────────────────────────────────────────────────────────
  group('캘린더 — 월 그리드', () {
    testWidgets('재조회 중에도 월 그리드가 그대로 보인다', (tester) async {
      _tallView(tester, height: 900);
      final events = _ServeOnce<MonthYM, List<CalendarEvent>>(
        (_) => [
          CalendarEvent(
            rowId: 1,
            title: '치과',
            startDate: '${_ymd(now)}T09:00:00',
            endDate: '${_ymd(now)}T10:00:00',
          ),
        ],
      );
      await tester.pumpWidget(
        _app(const CalendarScreen(), [
          userCalendarListProvider.overrideWith(
            (ref) async => const [
              UserCalendar(rowId: 1, calendarName: '개인', isDefault: true),
            ],
          ),
          holidayListProvider.overrideWith((ref, key) async => <Holiday>[]),
          monthEventsProvider.overrideWith((ref, key) => events(key)),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CalendarMonthGrid), findsOneWidget);

      await _refetch(
        tester,
        _containerOf(tester, find.byType(CalendarScreen)),
        monthEventsProvider,
      );

      expect(find.byType(CalendarMonthGrid), findsOneWidget);
      expect(find.byType(dsskel.PSkeleton), findsNothing);
    });
  });
}
