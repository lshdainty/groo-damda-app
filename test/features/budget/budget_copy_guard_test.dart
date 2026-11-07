// 예산 설정 — 지난달 복사의 회귀 방지(코드 검수 H1 · M1 · M2 · M5 · L1).
//
// · H1: 이번 달 목록을 못 읽은 채(로딩 · 실패) 복사를 누르면 겹침 0 으로 보고 확인창 없이 덮어쓰고, "되돌리기"가
//   원래 예산 행을 지웠다. → 이번 달 값이 있을 때만 버튼이 켜지고, 되돌리기는 이번에 새로 만든 것만 지운다.
// · M1: 복사 도중/다시 시도 때 달을 옮기면 다른 달에 썼다. → 시작할 때 달을 고정한다.
// · M2: 띠는 앱 뿌리 호스트라 화면을 나가도 남는데, 액션이 죽은 context · ref 를 써서 아무 일도 안 했다.
// · M5: 실패 때 전역 오류 토스트와 새 띠가 함께 떴다. → 이 화면의 쓰기는 모두 silent.
// · L1: 되돌리기가 첫 실패에서 멈췄다. → 나머지는 계속 지우고, 이미 없는 것(404)은 지운 것으로 친다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/data/budget_repository.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/domain/budget_compliance.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_settings_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_screen.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/month_picker/p_month_picker.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import '../../support/plain_text.dart';

class _Repo extends BudgetRepository {
  _Repo() : super(Dio());

  /// (categoryRowId, year, month)
  final created = <(int?, int, int)>[];
  final updated = <int>[];
  final deleted = <int>[];

  /// 모든 쓰기 호출의 silent 값.
  final silents = <bool>[];

  int _createCalls = 0;

  /// create 를 이 번째(0부터)에서 한 번 실패시킨다.
  int? failCreateCall;

  /// update 를 이 번째(0부터)에서 실패시킨다. [failUpdateAgain] 이면 바로 다음 한 번도 실패한다.
  int? failUpdateCall;
  bool failUpdateAgain = false;
  int _updateCalls = 0;

  /// create 를 이 번째(0부터)에서 이 Completer 가 끝날 때까지 붙잡는다.
  int? holdCreateCall;
  Completer<void>? hold;

  int _nextId = 100;

  /// 이 번째 create 가 돌려줄 id(서버 upsert 가 이미 있던 행의 id 를 돌려주는 경우).
  final Map<int, int> createReturns = {};

  /// 이 id 의 delete 는 던진다(상태 코드 지정).
  final Map<int, int> deleteFailsWith = {};

  @override
  Future<int?> create({
    int? categoryRowId,
    required int budgetAmount,
    required int budgetYear,
    required int budgetMonth,
    bool silent = false,
  }) async {
    silents.add(silent);
    final call = _createCalls++;
    if (holdCreateCall == call) await hold!.future;
    if (failCreateCall == call) {
      failCreateCall = null;
      throw ApiException(code: 'X', message: 'boom');
    }
    created.add((categoryRowId, budgetYear, budgetMonth));
    return createReturns[call] ?? _nextId++;
  }

  @override
  Future<void> update({
    required int id,
    required int budgetAmount,
    bool silent = false,
  }) async {
    silents.add(silent);
    final call = _updateCalls++;
    if (failUpdateCall == call) {
      failUpdateCall = failUpdateAgain ? call + 1 : null;
      failUpdateAgain = false;
      throw ApiException(code: 'X', message: 'boom');
    }
    updated.add(id);
  }

  @override
  Future<void> delete(int id, {bool silent = false}) async {
    silents.add(silent);
    final code = deleteFailsWith[id];
    if (code != null) {
      throw ApiException(code: 'X', message: 'boom', statusCode: code);
    }
    deleted.add(id);
  }
}

class _GoalRepo extends SavingGoalRepository {
  _GoalRepo() : super(Dio());
  final deleted = <int>[];
  final silents = <bool>[];
  bool failNext = false;
  @override
  Future<void> delete(int id, {bool silent = false}) async {
    silents.add(silent);
    if (failNext) {
      failNext = false;
      throw ApiException(code: 'X', message: 'boom');
    }
    deleted.add(id);
  }
}

final _now = DateTime.now();

List<Budget> _prev(int y, int m) => [
  Budget(rowId: 1, budgetAmount: 1000, budgetYear: y, budgetMonth: m),
  Budget(
    rowId: 2,
    categoryRowId: 7,
    budgetAmount: 800,
    budgetYear: y,
    budgetMonth: m,
  ),
  Budget(
    rowId: 3,
    categoryRowId: 8,
    budgetAmount: 900,
    budgetYear: y,
    budgetMonth: m,
  ),
];

const _cats = [
  ExpenseCategory(rowId: 7, categoryName: '주거', expenseType: 'EXPENSE'),
  ExpenseCategory(rowId: 8, categoryName: '식비', expenseType: 'EXPENSE'),
];

final _navKey = GlobalKey<NavigatorState>();

/// [cur] 는 이번 달 질의의 동작 — 기본은 빈 목록. 지난달은 늘 [_prev].
Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required List<Override> overrides,
  Future<List<Budget>> Function(BudgetMonthKey key)? budgets,
}) async {
  tester.view.physicalSize = const Size(360, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hideCardProvider.overrideWith((ref, card) => false),
        if (budgets != null)
          monthBudgetsProvider.overrideWith((ref, key) => budgets(key)),
        rangeSummaryProvider.overrideWith(
          (ref, r) async => RangeSummary(
            startDate: r.startDate,
            endDate: r.endDate,
            totalExpense: 0,
            categoryBreakdown: const [],
          ),
        ),
        categoriesProvider.overrideWith((ref) async => _cats),
        budgetComplianceProvider.overrideWith(
          (ref, months) async => const <BudgetComplianceMonth>[],
        ),
        ...overrides,
      ],
      child: MaterialApp(
        navigatorKey: _navKey,
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) =>
            PSnackbarHost(closeLabel: '닫기', child: child!),
        home: const Scaffold(body: Text('홈')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(
    _navKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => screen)),
  );
  await tester.pumpAndSettle();
}

/// 화면을 나간다 — 띠(앱 뿌리 호스트)는 남는다. 띠 시간(6초)이 가지 않게 짧게만 흘린다.
Future<void> _leave(WidgetTester tester) async {
  _navKey.currentState!.pop();
  await tester.pump();
  // 화면 전환이 끝날 때까지(400ms 로는 아직 떠 있다) — 띠 6초보다는 짧게
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 1000));
}

PButton _copyBtn(WidgetTester tester) => tester
    .widgetList<PButton>(find.byType(PButton))
    .firstWhere((b) => b.label == '지난달 복사');

/// 달 줄을 눌러 시트를 열고 [month] 로 옮긴 뒤 "완료".
Future<void> _pickMonth(WidgetTester tester, DateTime month) async {
  tester.widget<BudgetMonthRow>(find.byType(BudgetMonthRow)).onPick();
  await tester.pumpAndSettle();
  tester
      .widget<PMonthWheel>(find.byType(PMonthWheel))
      .onChanged(month.year, month.month);
  await tester.pumpAndSettle();
  await tester.tap(findText('완료'));
  await tester.pumpAndSettle();
}

/// 이번 달 = 빈 목록(또는 [cur]), 지난달 = [_prev].
Future<List<Budget>> Function(BudgetMonthKey) _months({
  List<Budget> cur = const [],
  Future<List<Budget>> Function()? curOverride,
}) {
  return (key) {
    if (key.year == _now.year && key.month == _now.month) {
      return curOverride != null ? curOverride() : Future.value(cur);
    }
    return Future.value(_prev(key.year, key.month));
  };
}

void main() {
  group('H1 — 이번 달 목록을 읽기 전에는 복사 버튼이 꺼져 있다', () {
    testWidgets('이번 달 질의 로딩 중에는 비활성 — 응답이 오면 켜진다', (tester) async {
      final repo = _Repo();
      final gate = Completer<List<Budget>>();
      await _pumpWithoutSettle(
        tester,
        repo,
        _months(curOverride: () => gate.future),
      );
      // 지난달(캐시·즉시 응답)은 있는데 이번 달이 아직 — 옛 코드는 여기서 켜져 있었다
      expect(_copyBtn(tester).onPressed, isNull);
      await tester.tap(findText('지난달 복사'), warnIfMissed: false);
      await tester.pump();
      expect(repo.created, isEmpty);
      expect(repo.updated, isEmpty);
      expect(find.byType(PAlertDialogView), findsNothing);

      gate.complete(const []);
      await tester.pumpAndSettle();
      expect(_copyBtn(tester).onPressed, isNotNull);
    });

    testWidgets('이번 달 질의가 실패한 채에도 비활성 — 눌러도 아무것도 안 쓴다', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(curOverride: () => Future.error(StateError('x'))),
      );
      expect(findText('지난달 복사'), findsOneWidget);
      expect(_copyBtn(tester).onPressed, isNull);
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(repo.created, isEmpty);
      expect(repo.updated, isEmpty);
      expect(repo.deleted, isEmpty);
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsNothing);
    });

    testWidgets('달을 옮긴 직후(새 달 응답 전)에는 지난달이 캐시에 있어도 비활성', (tester) async {
      final repo = _Repo();
      final next = DateTime(_now.year, _now.month + 1, 1);
      final gate = Completer<List<Budget>>();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: (key) {
          if (key.year == next.year && key.month == next.month) {
            return gate.future; // 다음 달 응답 전
          }
          // 다음 달의 "지난달" 은 이번 달이다 — 이번 달에도 예산이 있어야 응답 뒤 복사가 켜진다
          return _months(cur: _prev(_now.year, _now.month))(key);
        },
      );
      expect(_copyBtn(tester).onPressed, isNotNull);
      // 시트 "완료" 뒤 화면이 다음 달로 바뀐다 — pumpAndSettle 이 스켈레톤을 지나 응답 대기로 끝난다
      tester.widget<BudgetMonthRow>(find.byType(BudgetMonthRow)).onPick();
      await tester.pumpAndSettle();
      tester
          .widget<PMonthWheel>(find.byType(PMonthWheel))
          .onChanged(next.year, next.month);
      await tester.pumpAndSettle();
      await tester.tap(findText('완료'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_copyBtn(tester).onPressed, isNull);

      gate.complete(const []);
      await tester.pumpAndSettle();
      expect(_copyBtn(tester).onPressed, isNotNull);
    });

    testWidgets('서버가 이미 있던 행의 id 를 돌려줘도(upsert) 되돌리기는 그 행을 지우지 않는다', (
      tester,
    ) async {
      // 이번 달 목록에는 주거(7)만 rowId 900. 복사 대상 중 식비(8)의 create 가 900 을 돌려주는 경우 —
      // 되돌리기가 이 행(원래 예산)을 하드 삭제하던 것이 H1 의 결과였다.
      final repo = _Repo()..createReturns[1] = 900;
      final cur = [
        const Budget(
          rowId: 900,
          categoryRowId: 99,
          budgetAmount: 5,
          budgetYear: 2000,
          budgetMonth: 1,
        ),
      ];
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(cur: cur),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing); // 겹침 없음
      expect(repo.created.length, 3);
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      // 새로 만든 둘만 — 900 은 원래 있던 행(가짜는 900 을 돌려준 차례에 번호를 쓰지 않아 둘째 새 행이 101 이다)
      expect(repo.deleted, [100, 101]);
      expect(repo.deleted, isNot(contains(900)));
    });

    testWidgets('덮어쓴 복사(확인창을 거침)에는 되돌리기가 없어 아무것도 지우지 않는다', (tester) async {
      final repo = _Repo();
      final cur = [
        Budget(
          rowId: 900,
          categoryRowId: 7,
          budgetAmount: 5,
          budgetYear: _now.year,
          budgetMonth: _now.month,
        ),
      ];
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(cur: cur),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('복사'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.updated, [900]); // 겹친 것은 그 행을 고친다
      expect(findText('되돌리기'), findsNothing);
      expect(repo.deleted, isEmpty);
    });
  });

  group('M1 — 복사는 시작한 달에 끝까지 쓴다', () {
    testWidgets('진행 중 달을 옮겨도 남은 항목이 시작한 달에 만들어진다', (tester) async {
      final repo = _Repo()
        ..holdCreateCall = 1
        ..hold = Completer<void>();
      final next = DateTime(_now.year, _now.month + 1, 1);
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pump(); // 첫 항목 지나 둘째 create 에서 붙잡힘
      await tester.pump(const Duration(milliseconds: 50));
      await _pickMonth(tester, next);
      repo.hold!.complete();
      await tester.pumpAndSettle();
      expect(repo.created.length, 3);
      for (final c in repo.created) {
        expect(
          (c.$2, c.$3),
          (_now.year, _now.month),
          reason: '달을 옮겨도 시작한 달에 쓴다',
        );
      }
    });

    testWidgets('실패 알림의 "다시 시도"는 달을 옮긴 뒤에도 시작한 달에 만든다', (tester) async {
      final repo = _Repo()..failCreateCall = 1;
      final next = DateTime(_now.year, _now.month + 1, 1);
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(findPlain('가져오지 못한 예산이 1개 있어요.'), findsOneWidget);
      await _pickMonth(tester, next);
      // 달을 옮겨도 띠는 남아 있다(한 번에 하나 — 새 화면의 알림이 없으면 그대로)
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.created.length, 3);
      for (final c in repo.created) {
        expect((c.$2, c.$3), (_now.year, _now.month));
      }
    });
  });

  group('M2 — 화면을 나간 뒤에도 띠의 액션이 돈다', () {
    testWidgets('복사 → 화면 나감 → "되돌리기"가 만든 예산을 지운다', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
      await _leave(tester);
      expect(find.byType(BudgetSettingsScreen), findsNothing);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget); // 띠는 남는다
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.deleted, [100, 101, 102]);
    });

    testWidgets('복사 일부 실패 → 화면 나감 → "다시 시도"가 실패한 것을 만들고 완료 띠를 띄운다', (
      tester,
    ) async {
      final repo = _Repo()..failCreateCall = 1;
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(repo.created.length, 2);
      await _leave(tester);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.created.length, 3);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [100, 101, 102], reason: '다시 시도로 만든 것까지 3개');
    });

    testWidgets('복사하는 도중 화면을 나가도 끝까지 만들고 완료 띠를 띄운다', (tester) async {
      final repo = _Repo()
        ..holdCreateCall = 1
        ..hold = Completer<void>();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await _leave(tester);
      repo.hold!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.created.length, 3);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
    });

    testWidgets('덮어쓴 복사가 일부 실패 → 다시 시도 성공 → 되돌리기 없는 "가져왔어요" 안내', (
      tester,
    ) async {
      final repo = _Repo()..failUpdateCall = 0;
      final cur = [
        Budget(
          rowId: 900,
          categoryRowId: 7,
          budgetAmount: 5,
          budgetYear: _now.year,
          budgetMonth: _now.month,
        ),
      ];
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(cur: cur),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('복사'),
        ),
      );
      await tester.pumpAndSettle();
      // 겹친 1개(주거 7)의 update 가 실패, 나머지 둘은 create
      expect(findPlain('가져오지 못한 예산이 1개 있어요.'), findsOneWidget);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsNothing);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.updated, [900]);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
      // 덮어쓴 복사 — 되돌리기는 없다
      expect(findText('되돌리기'), findsNothing);
      expect(find.byKey(const ValueKey('snackbar-icon')), findsNothing);
    });

    testWidgets('덮어쓴 복사가 첫 시도에 다 되면 안내 띠를 띄우지 않는다(닫힌 확인창이 결과)', (tester) async {
      final repo = _Repo();
      final cur = [
        Budget(
          rowId: 900,
          categoryRowId: 7,
          budgetAmount: 5,
          budgetYear: _now.year,
          budgetMonth: _now.month,
        ),
      ];
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(cur: cur),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('복사'),
        ),
      );
      await tester.pumpAndSettle();
      expect(findPlain('지난달 예산을 가져왔어요.'), findsNothing);
      expect(findText('다시 시도'), findsNothing);
    });

    testWidgets('덮어쓴 복사 → 일부 실패 → 다시 시도도 실패하면 실패 띠가 다시 뜨고 성공 안내는 없다', (
      tester,
    ) async {
      final repo = _Repo()
        ..failUpdateCall = 0
        ..failUpdateAgain = true;
      final cur = [
        Budget(
          rowId: 900,
          categoryRowId: 7,
          budgetAmount: 5,
          budgetYear: _now.year,
          budgetMonth: _now.month,
        ),
      ];
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(cur: cur),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('복사'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(findPlain('가져오지 못한 예산이 1개 있어요.'), findsOneWidget);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsNothing);
    });

    testWidgets('예산 삭제 실패 → 화면 나감 → "다시 시도"는 묻지 않고 바로 지운다', (tester) async {
      final repo = _Repo()..deleteFailsWith[2] = 500;
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: (key) => Future.value(_prev(key.year, key.month)),
      );
      tester
          .widgetList<PSwipeActions>(find.byType(PSwipeActions))
          .first
          .actions
          .last
          .onSelect();
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(findPlain('예산을 삭제하지 못했어요.'), findsOneWidget);
      await _leave(tester);
      repo.deleteFailsWith.clear();
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.deleted, [2]);
    });

    testWidgets('화면이 살아 있어도 삭제 "다시 시도"는 묻지 않고, 또 실패하면 같은 띠가 다시 뜬다', (
      tester,
    ) async {
      final repo = _Repo()..deleteFailsWith[2] = 500;
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: (key) => Future.value(_prev(key.year, key.month)),
      );
      tester
          .widgetList<PSwipeActions>(find.byType(PSwipeActions))
          .first
          .actions
          .last
          .onSelect();
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(findPlain('예산을 삭제하지 못했어요.'), findsOneWidget);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing, reason: '다시 묻지 않는다');
      expect(findPlain('예산을 삭제하지 못했어요.'), findsOneWidget, reason: '또 실패');
      repo.deleteFailsWith.clear();
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [2]);
      expect(findText('다시 시도'), findsNothing);
    });

    testWidgets('저축 목표 삭제 실패 → 화면 나감 → "다시 시도"가 지운다', (tester) async {
      final repo = _GoalRepo()..failNext = true;
      final goals = [
        const SavingGoal(
          rowId: 5,
          title: '여행 적금',
          targetAmount: 1000000,
          currentAmount: 100000,
          color: '#3b82f6',
          isAchieved: 'N',
        ),
      ];
      await _pump(
        tester,
        const SavingGoalScreen(),
        overrides: [
          savingGoalListProvider.overrideWith((ref) async => goals),
          savingGoalRepositoryProvider.overrideWith((ref) async => repo),
        ],
      );
      tester
          .widgetList<PSwipeActions>(find.byType(PSwipeActions))
          .first
          .actions
          .last
          .onSelect();
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.deleted, isEmpty);
      await _leave(tester);
      expect(find.byType(SavingGoalScreen), findsNothing);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repo.deleted, [5]);
    });
  });

  group('M5 — 이 화면의 쓰기는 전역 오류 토스트를 끈다', () {
    testWidgets('복사 · 덮어쓰기 · 되돌리기 · 삭제가 모두 silent 로 나간다', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      expect(repo.silents, isNotEmpty);
      expect(repo.silents.every((s) => s), isTrue);
      expect(repo.silents.length, 6, reason: 'create 3 + delete 3');
    });

    testWidgets('예산 삭제 · 저축 목표 삭제도 silent', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: (key) => Future.value(_prev(key.year, key.month)),
      );
      tester
          .widgetList<PSwipeActions>(find.byType(PSwipeActions))
          .first
          .actions
          .last
          .onSelect();
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.silents, [true]);
    });
  });

  group('L1 — 되돌리기는 하나가 안 지워져도 계속한다', () {
    testWidgets('이미 지워진(404) 예산은 지운 것으로 치고 나머지를 지운다 — 못 지운 알림 없음', (
      tester,
    ) async {
      final repo = _Repo()..deleteFailsWith[100] = 404;
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [101, 102]);
      expect(findPlain('되돌리지 못한 예산이 1개 남았어요.'), findsNothing);
      expect(findText('다시 시도'), findsNothing);
    });

    testWidgets('첫 항목이 서버 오류로 실패해도 뒤 항목은 시도하고, 못 지운 수는 실제 실패만 센다', (
      tester,
    ) async {
      final repo = _Repo()..deleteFailsWith[100] = 500;
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
        budgets: _months(),
      );
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [101, 102]);
      expect(findPlain('되돌리지 못한 예산이 1개 남았어요.'), findsOneWidget);
      // 다시 시도는 못 지운 100 만
      repo.deleteFailsWith.clear();
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [101, 102, 100]);
      expect(findText('다시 시도'), findsNothing);
    });
  });
}

/// 이번 달 질의가 끝나지 않은 채로 둔다 — pumpAndSettle 을 쓰지 않는다.
Future<void> _pumpWithoutSettle(
  WidgetTester tester,
  _Repo repo,
  Future<List<Budget>> Function(BudgetMonthKey) budgets,
) async {
  tester.view.physicalSize = const Size(360, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hideCardProvider.overrideWith((ref, card) => false),
        monthBudgetsProvider.overrideWith((ref, key) => budgets(key)),
        rangeSummaryProvider.overrideWith(
          (ref, r) async => RangeSummary(
            startDate: r.startDate,
            endDate: r.endDate,
            totalExpense: 0,
            categoryBreakdown: const [],
          ),
        ),
        categoriesProvider.overrideWith((ref) async => _cats),
        budgetComplianceProvider.overrideWith(
          (ref, months) async => const <BudgetComplianceMonth>[],
        ),
        budgetRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) =>
            PSnackbarHost(closeLabel: '닫기', child: child!),
        home: const BudgetSettingsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
