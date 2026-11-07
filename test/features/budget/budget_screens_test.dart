import 'package:lucide_icons_flutter/lucide_icons.dart';
// I-08-1 — 예산 · 예산 설정 · 저축 목표를 가장 나쁜 값(긴 이름 · 큰 금액)으로 실제 화면을 띄워 잰다.
//
// 잰 것: 넘침 오류 0 · 이름 말줄임 0 · 금액 원까지 · 띠 셋 사이 8 · 막대 색(넘침 critical, 경고 구간 색 없음) ·
// 카드 · 줄 사이 선 없음 · 저축 목표 막대 한 색 · 금액 가림.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/data/budget_repository.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/domain/budget_compliance.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_screen.dart';
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
import 'package:fl_chart/fl_chart.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';

class _FakeBudgetRepo extends BudgetRepository {
  _FakeBudgetRepo() : super(Dio());
  final deleted = <int>[];
  final created = <int>[];
  final updated = <int>[];

  /// 다음 delete · update 한 번을 실패시킨다.
  bool failNext = false;
  int _nextId = 100;

  /// delete 를 이 번째(0부터)에서 한 번 실패시킨다.
  int? failDeleteCall;
  int _deleteCalls = 0;

  /// create 를 이 번째(0부터)에서 한 번 실패시킨다.
  int? failCreateCall;
  int _createCalls = 0;

  void _maybeFail() {
    if (failNext) {
      failNext = false;
      throw ApiException(code: 'X', message: 'boom');
    }
  }

  @override
  Future<void> delete(int id, {bool silent = false}) async {
    if (failDeleteCall == _deleteCalls++) {
      failDeleteCall = null;
      throw ApiException(code: 'X', message: 'boom');
    }
    _maybeFail();
    deleted.add(id);
  }

  @override
  Future<int?> create({
    int? categoryRowId,
    required int budgetAmount,
    required int budgetYear,
    required int budgetMonth,
    bool silent = false,
  }) async {
    if (failCreateCall == _createCalls++) {
      failCreateCall = null;
      throw ApiException(code: 'X', message: 'boom');
    }
    created.add(categoryRowId ?? 0);
    return _nextId++;
  }

  @override
  Future<void> update({
    required int id,
    required int budgetAmount,
    bool silent = false,
  }) async {
    _maybeFail();
    updated.add(id);
  }
}

class _FakeGoalRepo extends SavingGoalRepository {
  _FakeGoalRepo() : super(Dio());
  final deleted = <int>[];
  bool failNext = false;
  @override
  Future<void> delete(int id, {bool silent = false}) async {
    if (failNext) {
      failNext = false;
      throw ApiException(code: 'X', message: 'boom');
    }
    deleted.add(id);
  }
}

const _longName = '주거·관리비·공과금·통신 요금 자동이체 묶음';
const _goalName =
    '아주 오래 걸리는 목표 이름 테스트 '
    '가나다라마바사아자차카타파하 '
    '가나다라마바사';

final _cats = [
  const ExpenseCategory(
    rowId: 7,
    categoryName: _longName,
    expenseType: 'EXPENSE',
  ),
  const ExpenseCategory(rowId: 8, categoryName: '식비', expenseType: 'EXPENSE'),
];

List<Budget> _budgets(int y, int m) => [
  Budget(rowId: 1, budgetAmount: 100000000, budgetYear: y, budgetMonth: m),
  Budget(
    rowId: 2,
    categoryRowId: 7,
    budgetAmount: 800000,
    budgetYear: y,
    budgetMonth: m,
  ),
  Budget(
    rowId: 3,
    categoryRowId: 8,
    budgetAmount: 1000000,
    budgetYear: y,
    budgetMonth: m,
  ),
];

RangeSummary _summary(String s, String e) => RangeSummary(
  startDate: s,
  endDate: e,
  totalExpense: 12345678901,
  categoryBreakdown: const [
    CategoryBreakdown(
      categoryRowId: 7,
      expenseType: 'EXPENSE',
      totalAmount: 1234567890,
    ),
    CategoryBreakdown(
      categoryRowId: 8,
      expenseType: 'EXPENSE',
      totalAmount: 900000,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  double textScale = 1.0,
  bool masked = false,
  Brightness brightness = Brightness.light,
  Future<List<Budget>> Function(BudgetMonthKey key)? budgets,
  List<BudgetComplianceMonth>? compliance,
  Future<RangeSummary> Function(({String startDate, String endDate}) range)?
  summaryOf,
}) async {
  tester.view.physicalSize = const Size(360, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hideCardProvider.overrideWith((ref, card) => masked),
        monthBudgetsProvider.overrideWith(
          (ref, key) => budgets != null
              ? budgets(key)
              : Future.value(_budgets(key.year, key.month)),
        ),
        rangeSummaryProvider.overrideWith(
          (ref, r) => summaryOf != null
              ? summaryOf(r)
              : Future.value(_summary(r.startDate, r.endDate)),
        ),
        categoriesProvider.overrideWith((ref) async => _cats),
        budgetComplianceProvider.overrideWith(
          (ref, months) async =>
              compliance ??
              const [
                BudgetComplianceMonth(
                  year: 2026,
                  month: 9,
                  totalLimit: 100,
                  totalSpent: 150,
                  compliancePercent: 150,
                ),
              ],
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? GrooTheme.light()
            : GrooTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 위젯 트리의 모든 글(읽는 이름 포함)에서 [pattern] 이 들어간 것이 있는가.
bool _hasText(WidgetTester tester, String pattern) => tester
    .widgetList<Text>(find.byType(Text))
    .any((t) => (t.semanticsLabel ?? t.data ?? '').contains(pattern));

List<PProgressBar> _bars(WidgetTester tester) =>
    tester.widgetList<PProgressBar>(find.byType(PProgressBar)).toList();

Color _fillOf(WidgetTester tester, int index) {
  final bar = find.byType(PProgressBar).at(index);
  final fill = find.descendant(
    of: bar,
    matching: find.byKey(const ValueKey('progress-fill')),
  );
  final box = tester.widget<Container>(fill);
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  group('예산', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('띠 셋 · 원까지 · 말줄임 0 · 넘침 0 (글자 ${scale * 100}%)', (
        tester,
      ) async {
        await _pump(tester, const BudgetScreen(), textScale: scale);
        expect(tester.takeException(), isNull);

        // 띠 셋 — 총 예산·페이스 / 현황·목록 / 이행률
        expect(find.byKey(const ValueKey('screen-section')), findsNWidgets(3));
        // 큰 금액은 원까지, 말줄임 없음
        expect(_hasText(tester, '12,345,678,901원'), isTrue);
        expect(_hasText(tester, '100,000,000원'), isTrue);
        // 긴 카테고리 이름은 모든 글자가 줄바꿈으로 보인다
        final name = tester
            .widgetList<Text>(find.byType(Text))
            .firstWhere((t) => (t.data ?? '').replaceAll('⁠', '') == _longName);
        expect(name.overflow, isNot(TextOverflow.ellipsis));
        expect(name.maxLines, isNull);
        // 줄 금액에도 원이 붙는다
        expect(_hasText(tester, '1,234,567,890원'), isTrue);
        expect(_hasText(tester, '/ 800,000원'), isTrue);
      });
    }

    testWidgets('띠 사이 8 둘 — 마지막 띠 아래에 빈 띠를 두지 않는다', (tester) async {
      await _pump(tester, const BudgetScreen());
      final bands = find.byKey(const ValueKey('screen-section'));
      final r0 = tester.getRect(bands.at(0));
      final r1 = tester.getRect(bands.at(1));
      final r2 = tester.getRect(bands.at(2));
      expect(r1.top - r0.bottom, kScreenBandGap);
      expect(r2.top - r1.bottom, kScreenBandGap);
      // 머리(화면 맨 위)와 첫 띠 사이 틈 0
      expect(r0.top, 0);
    });

    testWidgets('띠 ① = 달 줄 + 구역 둘(총 예산 · 페이스), 달 줄 위 12', (tester) async {
      await _pump(tester, const BudgetScreen());
      final band0 = find.byKey(const ValueKey('screen-section')).first;
      expect(
        find.descendant(of: band0, matching: find.byType(BudgetMonthRow)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: band0, matching: find.byType(BudgetSection)),
        findsNWidgets(2),
      );
      // 띠 맨 위 4 + 8 = 12 아래에 달 줄(위 24 · 아이콘 상자 자리 포함)
      final row = tester.getRect(find.byType(BudgetMonthRow));
      expect(row.top, 0);
      final label = tester.getRect(
        find
            .descendant(
              of: find.byType(BudgetMonthRow),
              matching: find.byIcon(LucideIcons.chevronDown),
            )
            .first,
      );
      expect(label.top - row.top, greaterThanOrEqualTo(12));
      // ‹ › 는 없다 — 달 글이 화면 여백 24 에서 시작한다(꺾쇠 + 글 상자 안 여백 10 → 글 left 24)
      final text = tester.getRect(
        find
            .descendant(
              of: find.byType(BudgetMonthRow),
              matching: findTextContaining('월'),
            )
            .first,
      );
      expect(text.left, 24);
    });

    testWidgets('페이스: 배지는 머리 오른쪽 끝, 막대 8 · 표시선 2 × 14 (막대 위로 3)', (
      tester,
    ) async {
      await _pump(tester, const BudgetScreen());
      final marker = tester.getRect(find.byKey(const ValueKey('pace-marker')));
      expect(marker.width, 2);
      expect(marker.height, 14);
      final bar = tester.getRect(find.byType(PProgressBar).at(1));
      expect(bar.height, 8);
      expect(bar.top - marker.top, 3);
      // 배지 오른쪽 끝 = 구역 오른쪽 가장자리 24 안쪽
      final badge = tester.getRect(find.byType(PBadge).first);
      expect(360 - badge.right, 24);
      final widget = tester.widget<PBadge>(find.byType(PBadge).first);
      expect(widget.variant, PBadgeVariant.weak);
      expect(widget.size, PBadgeSize.medium);
    });

    testWidgets('키-값 줄 위아래 8 · 글자 왼쪽 24', (tester) async {
      await _pump(tester, const BudgetScreen());
      final eyebrow = tester.getRect(find.byType(BudgetEyebrow));
      expect(eyebrow.left, 24);
      final item = tester.getRect(find.byType(PListItem).first);
      // 줄 높이 = 위아래 8 + 글 한 줄(22)
      expect(item.height, closeTo(8 + 22 + 8, 1.0));
    });

    testWidgets('질의 하나 = 상자 하나 — 요약이 실패하면 띠 ① 에 상자 하나, 띠 ② 는 없고 이행률은 제 몫', (
      tester,
    ) async {
      await _pump(
        tester,
        const BudgetScreen(),
        summaryOf: (r) async => throw Exception('SECRET-RAW-ERROR'),
      );
      // 띠 ① 실패 + 띠 ③ 이행률(제 데이터)
      expect(find.byKey(const ValueKey('screen-section')), findsNWidgets(2));
      expect(findText('다시 시도'), findsOneWidget);
      expect(_hasText(tester, '예산을 불러오지 못했어요'), isTrue);
      expect(_hasText(tester, '예산 현황'), isFalse);
      expect(_hasText(tester, '최근 6개월'), isTrue);
      expect(_hasText(tester, 'SECRET-RAW-ERROR'), isFalse);
    });

    testWidgets('이행률은 ds 막대 — 넘음 red · 이번 달 blue · 지난 달 blue weak · 100% 점선', (
      tester,
    ) async {
      final now = DateTime.now();
      await _pump(
        tester,
        const BudgetScreen(),
        compliance: [
          BudgetComplianceMonth(
            year: now.year,
            month: now.month - 1 == 0 ? 12 : now.month - 1,
            totalLimit: 100,
            totalSpent: 50,
            compliancePercent: 50,
          ),
          BudgetComplianceMonth(
            year: now.year,
            month: now.month,
            totalLimit: 100,
            totalSpent: 60,
            compliancePercent: 60,
          ),
        ],
      );
      expect(find.byType(PBarChart), findsOneWidget);
      final c = tester.element(find.byType(BudgetScreen)).colors;
      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      expect(data.barGroups[0].barRods.first.color, c.chartBlueWeak);
      expect(data.barGroups[1].barRods.first.color, c.chartBlue);
      expect(data.extraLinesData.horizontalLines, hasLength(1));
      expect(data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
    });

    testWidgets('이행률 퍼센트는 정수 — 막대 글 · 말풍선 · 표가 같은 값(76.43 → 76%)', (
      tester,
    ) async {
      final now = DateTime.now();
      await _pump(
        tester,
        const BudgetScreen(),
        compliance: [
          BudgetComplianceMonth(
            year: now.year,
            month: now.month,
            totalLimit: 100,
            totalSpent: 76,
            compliancePercent: 76.43,
          ),
        ],
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chart-bar-label-0')),
          matching: find.text('76%'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('76.4', skipOffstage: false), findsNothing);
      expect(find.text('76%', skipOffstage: false), findsAtLeastNWidgets(1));
    });

    testWidgets('이행률 가장 큰 막대(2,855%) 위 % 글이 차트 위로 잘리지 않는다', (tester) async {
      final now = DateTime.now();
      await _pump(
        tester,
        const BudgetScreen(),
        compliance: [
          BudgetComplianceMonth(
            year: now.year,
            month: now.month,
            totalLimit: 1000,
            totalSpent: 28550,
            compliancePercent: 2855,
          ),
        ],
      );
      final chart = tester.getRect(find.byType(PBarChart));
      final label = tester.getRect(
        find.byKey(const ValueKey('chart-bar-label-0')),
      );
      expect(label.top, greaterThanOrEqualTo(chart.top));
      expect(label.bottom, lessThan(chart.bottom));
    });

    testWidgets('막대 — 넘치면 위험 색, 85~100% 경고 색 없음, 테두리 상자 0', (tester) async {
      await _pump(tester, const BudgetScreen());
      final c = tester.element(find.byType(BudgetScreen)).colors;
      // 총 예산 막대(첫째) = 12,345,678,901 / 100,000,000 → 넘침
      expect(_fillOf(tester, 0), c.fgCritical);
      // 식비 막대(90,000/1,000,000 = 90%) = 경고 구간이어도 브랜드 색
      final bars = _bars(tester);
      expect(bars.length, greaterThanOrEqualTo(4));
      expect(_fillOf(tester, bars.length - 1), c.fgBrand);
      // 띠 안 카드(테두리 상자) 0
      expect(find.byType(PCard), findsNothing);
    });

    testWidgets('금액 가림 — 점만 남고 원 · 부호도 사라진다', (tester) async {
      await _pump(tester, const BudgetScreen(), masked: true);
      expect(_hasText(tester, '12,345,678,901'), isFalse);
      expect(_hasText(tester, '••••'), isTrue);
    });

    testWidgets('실패는 0원이 아니라 그 자리의 다시 시도 — 오류 원문 0', (tester) async {
      await _pump(
        tester,
        const BudgetScreen(),
        budgets: (key) async => throw Exception('SECRET-RAW-ERROR'),
      );
      expect(_hasText(tester, '다시 시도'), isTrue);
      expect(_hasText(tester, 'SECRET-RAW-ERROR'), isFalse);
      expect(_hasText(tester, '0원'), isFalse);
    });

    testWidgets('이번 달 예산이 없으면 빈 결과 + 예산 설정 버튼, 한도 있는 달이 없으면 이행률도 없다', (
      tester,
    ) async {
      await _pump(
        tester,
        const BudgetScreen(),
        budgets: (key) async => const [],
        compliance: const [
          BudgetComplianceMonth(
            year: 2026,
            month: 9,
            totalLimit: 0,
            totalSpent: 0,
            compliancePercent: 0,
          ),
        ],
      );
      expect(find.byKey(const ValueKey('screen-section')), findsOneWidget);
      expect(_hasText(tester, '예산 설정'), isTrue);
      expect(_hasText(tester, '최근 6개월'), isFalse);
    });
  });

  group('예산 설정', () {
    testWidgets('글자 왼쪽 24 · 설정 줄 이름 말줄임 0 · 넘침 설명 "한도 초과"', (tester) async {
      await _pump(tester, const BudgetSettingsScreen());
      expect(tester.getRect(find.byType(BudgetEyebrow)).left, 24);
      final name = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => plainOf(t.data ?? '') == _longName);
      expect(name.overflow, isNot(TextOverflow.ellipsis));
      expect(name.maxLines, isNull);
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .any((t) => plainOf(t.data ?? '').contains('한도 초과 1,233,767,890원')),
        isTrue,
      );
      // 눈썹 줄 높이는 눈썹(18)이다 — 글 버튼 36 이 늘리지 않는다
      final eyebrow = tester.getRect(find.byType(BudgetEyebrow));
      expect(eyebrow.height, closeTo(18, 1));
    });

    testWidgets('글자 200% 다크 — 넘침 0', (tester) async {
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        textScale: 2.0,
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('흰 면 하나 — 카드 · 줄 사이 선 0, 총 예산 막대 넘침 위험 색, 원까지', (tester) async {
      await _pump(tester, const BudgetSettingsScreen());
      expect(tester.takeException(), isNull);
      expect(find.byType(PCard), findsNothing);
      expect(find.byType(Divider), findsNothing);
      final c = tester.element(find.byType(BudgetSettingsScreen)).colors;
      expect(_fillOf(tester, 0), c.fgCritical, reason: '써서 넘치면 파랑이 아니다');
      expect(_hasText(tester, '12,345,678,901원'), isTrue);
      // 할당 가능: 음수 U+2212
      expect(_hasText(tester, '+98,200,000원'), isTrue);
      expect(_hasText(tester, _longName.substring(0, 6)), isTrue);
    });
  });

  group('저축 목표', () {
    final goals = [
      const SavingGoal(
        rowId: 1,
        title: _goalName,
        targetAmount: 10000000000,
        currentAmount: 2283000000,
        color: '#ef4444',
        isAchieved: 'N',
      ),
      const SavingGoal(
        rowId: 2,
        title: '비상금',
        targetAmount: 1000000,
        currentAmount: 1000000,
        color: '#3b82f6',
        isAchieved: 'Y',
      ),
    ];

    testWidgets('막대는 목표 색이 달라도 한 색 · 이름 말줄임 0 · 원까지 · 카드 0', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        overrides: [savingGoalListProvider.overrideWith((ref) async => goals)],
      );
      expect(tester.takeException(), isNull);
      final c = tester.element(find.byType(SavingGoalScreen)).colors;
      expect(_fillOf(tester, 0), c.fgBrand);
      expect(_fillOf(tester, 1), c.fgBrand);
      expect(find.byType(PCard), findsNothing);
      expect(find.byType(Divider), findsNothing);
      expect(_hasText(tester, '2,283,000,000원'), isTrue);
      expect(_hasText(tester, '10,000,000,000원'), isTrue);
      expect(_hasText(tester, '달성'), isTrue);
    });

    testWidgets('글자 200% 다크 — 넘침 0', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        textScale: 2.0,
        brightness: Brightness.dark,
        overrides: [savingGoalListProvider.overrideWith((ref) async => goals)],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('금액 가리기 — 금액은 점, % 는 보인다', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        masked: true,
        overrides: [savingGoalListProvider.overrideWith((ref) async => goals)],
      );
      expect(_hasText(tester, '2,283,000,000'), isFalse);
      expect(_hasText(tester, '••••'), isTrue);
      expect(_hasText(tester, '23%'), isTrue);
    });

    testWidgets('실패는 다시 시도 — 오류 원문 0', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        overrides: [
          savingGoalListProvider.overrideWith(
            (ref) async => throw Exception('SECRET-RAW-ERROR'),
          ),
        ],
      );
      expect(_hasText(tester, '다시 시도'), isTrue);
      expect(_hasText(tester, 'SECRET-RAW-ERROR'), isFalse);
    });
  });

  // I-28 3-6 — 예산 · 저축 목표의 옛 확인창(옛 showPConfirmDialog) → ds Alert Dialog.
  group('확인창 — ds Alert Dialog (I-28 3-6)', () {
    PButton actionOf(WidgetTester tester) => tester.widget<PButton>(
      find
          .descendant(
            of: find.byType(PAlertDialogView),
            matching: find.byType(PButton),
          )
          .last,
    );

    testWidgets('예산 삭제 — 제목이 이름을 짚고 확정은 criticalSolid, 바깥은 닫지 않고, 확정하면 지운다', (
      tester,
    ) async {
      final repo = _FakeBudgetRepo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
      );
      final swipe = tester
          .widgetList<PSwipeActions>(find.byType(PSwipeActions))
          .first;
      swipe.actions.last.onSelect();
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(findPlain('"$_longName" 예산을 삭제할까요?'), findsOneWidget);
      expect(findPlain('삭제한 예산은 되돌릴 수 없어요.'), findsOneWidget);
      expect(actionOf(tester).variant, PButtonVariant.criticalSolid);
      expect(actionOf(tester).label, '삭제');
      // 바깥(딤)을 눌러도 닫히지 않는다
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(repo.deleted, isEmpty);
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.deleted, [2]);
    });

    // 밀기 트레이 [삭제] → 트레이가 먼저 닫히고 확인창 → 지운다 (화면 수준)
    Future<void> trayDelete(WidgetTester tester) async {
      final row = tester
          .widgetList<PSwipeActions>(find.byType(PSwipeActions))
          .first;
      await tester.drag(
        find.byKey(const ValueKey('swipe-row')).first,
        const Offset(-250, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('삭제: ${row.rowLabel}'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      final box = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('swipe-row')).first,
      );
      expect(box.transform!.getTranslation().x, 0, reason: '트레이를 먼저 닫는다');
    }

    Future<void> sheetDelete(WidgetTester tester, Finder row) async {
      await tester.tap(row.first);
      await tester.pumpAndSettle();
      final inSheet = find.descendant(
        of: find.byType(PBottomSheetContent),
        matching: findText('삭제'),
      );
      expect(inSheet, findsOneWidget);
      await tester.tap(inSheet);
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
    }

    testWidgets('예산 — 트레이 [삭제] → 확인창 → 지운다', (tester) async {
      final handle = tester.ensureSemantics();
      final repo = _FakeBudgetRepo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
      );
      await trayDelete(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.deleted, [2]);
      handle.dispose();
    });

    testWidgets('예산 — 수정 시트 바닥 [삭제] → 확인창 한 번 → 지우고 시트가 닫힌다', (tester) async {
      final repo = _FakeBudgetRepo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
      );
      await sheetDelete(tester, find.byType(BudgetCategoryRow));
      expect(repo.deleted, isEmpty);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.deleted, [2]);
      expect(find.byType(PBottomSheetContent), findsNothing);
    });

    testWidgets('예산 삭제 — 취소하면 지우지 않는다', (tester) async {
      final repo = _FakeBudgetRepo();
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
      );
      tester
          .widgetList<PSwipeActions>(find.byType(PSwipeActions))
          .first
          .actions
          .last
          .onSelect();
      await tester.pumpAndSettle();
      await tester.tap(findText('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.deleted, isEmpty);
    });

    Future<void> pumpMonths(
      WidgetTester tester,
      _FakeBudgetRepo repo, {
      required bool curEmpty,
    }) => _pump(
      tester,
      const BudgetSettingsScreen(),
      budgets: (key) async => curEmpty && key.month == DateTime.now().month
          ? <Budget>[]
          : _budgets(key.year, key.month),
      overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
    );

    testWidgets('지난달 복사 — 덮어쓰면 criticalSolid + "복사", 설명에 사라지는 수 · 되돌릴 수 없음', (
      tester,
    ) async {
      final repo = _FakeBudgetRepo();
      await pumpMonths(tester, repo, curEmpty: false);
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(findPlain('지난달 예산을 복사할까요?'), findsOneWidget);
      expect(
        findPlain('이번 달 예산 3개가 지난달 예산으로 바뀌어요. 바꾼 뒤에는 되돌릴 수 없어요.'),
        findsOneWidget,
      );
      expect(actionOf(tester).variant, PButtonVariant.criticalSolid);
      expect(actionOf(tester).label, '복사');
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('복사'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.updated.length, 3);
      expect(repo.created, isEmpty);
    });

    testWidgets('지난달 복사 — 비어 있으면 묻지 않고 복사, 되돌리기가 만든 것만 지워 0개로', (tester) async {
      final repo = _FakeBudgetRepo();
      await pumpMonths(tester, repo, curEmpty: true);
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.created.length, 3);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [100, 101, 102]);
    });

    testWidgets('되돌리기 스낵바는 액션이 있어 6초 — 5초에는 남고 7초에는 사라진다', (tester) async {
      final repo = _FakeBudgetRepo();
      await pumpMonths(tester, repo, curEmpty: true);
      await tester.tap(findText('지난달 복사'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
      // 기본 톤 — 아이콘 없음
      expect(find.byKey(const ValueKey('snackbar-icon')), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(findPlain('지난달 예산을 가져왔어요.'), findsNothing);
    });

    Future<void> pumpCur(
      WidgetTester tester,
      _FakeBudgetRepo repo,
      List<int?> curCategories,
    ) => _pump(
      tester,
      const BudgetSettingsScreen(),
      budgets: (key) async => key.month == DateTime.now().month
          ? [
              for (final (i, c) in curCategories.indexed)
                Budget(
                  rowId: 900 + i,
                  categoryRowId: c,
                  budgetAmount: 1000,
                  budgetYear: key.year,
                  budgetMonth: key.month,
                ),
            ]
          : _budgets(key.year, key.month),
      overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
    );

    testWidgets('지난달 복사 — 겹침 없음(다른 카테고리만 있음)이면 묻지 않고 복사, 되돌리기는 만든 것만 지운다', (
      tester,
    ) async {
      final repo = _FakeBudgetRepo();
      await pumpCur(tester, repo, [99]);
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.created.length, 3);
      expect(repo.updated, isEmpty);
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      // 원래 예산(900)은 지우지 않는다
      expect(repo.deleted, [100, 101, 102]);
    });

    testWidgets('지난달 복사 — 일부 겹치면 확인창 N 은 겹친 개수, 확인 뒤 복사에는 되돌리기가 없다', (
      tester,
    ) async {
      final repo = _FakeBudgetRepo();
      // 이번 달: 전체 상한 · 카테고리 7 (둘 다 지난달에도 있음) · 카테고리 99 (지난달에 없음)
      await pumpCur(tester, repo, [null, 7, 99]);
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(
        findPlain('이번 달 예산 2개가 지난달 예산으로 바뀌어요. 바꾼 뒤에는 되돌릴 수 없어요.'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('복사'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.updated.length, 2);
      expect(repo.created.length, 1);
      expect(findText('되돌리기'), findsNothing);
    });

    testWidgets('되돌리기 도중 하나가 실패해도 나머지는 계속 지우고, 못 지운 수를 알린 뒤 다시 시도는 그것만 지운다', (
      tester,
    ) async {
      final repo = _FakeBudgetRepo()..failDeleteCall = 1;
      await pumpCur(tester, repo, [99]);
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      // 둘째(101)만 실패 — 셋째(102)는 시도한다(첫 실패에서 멈추지 않는다)
      expect(repo.deleted, [100, 102]);
      expect(findPlain('되돌리지 못한 예산이 1개 남았어요.'), findsOneWidget);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [100, 102, 101]);
    });

    testWidgets(
      '지난달 복사 — 덮어쓰다 1개 실패하면 창을 닫고 N=1 알림, 다시 시도는 그 1개만 다시 하고 확인창은 없다',
      (tester) async {
        final repo = _FakeBudgetRepo()..failNext = true;
        await pumpMonths(tester, repo, curEmpty: false);
        await tester.tap(findText('지난달 복사'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(PAlertDialogView),
            matching: findText('복사'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PAlertDialogView), findsNothing);
        expect(repo.updated.length, 2);
        expect(findPlain('가져오지 못한 예산이 1개 있어요.'), findsOneWidget);
        await tester.tap(findText('다시 시도'));
        await tester.pumpAndSettle();
        expect(find.byType(PAlertDialogView), findsNothing);
        expect(repo.updated.length, 3);
        // 덮어쓴 복사에는 되돌리기가 없다
        expect(findText('되돌리기'), findsNothing);
      },
    );

    testWidgets('지난달 복사 — 3개 중 2번째 실패 → N=1 → 다시 시도로 1개만 → 되돌리기가 3개 모두 지운다', (
      tester,
    ) async {
      final repo = _FakeBudgetRepo()..failCreateCall = 1;
      await pumpCur(tester, repo, [99]);
      await tester.tap(findText('지난달 복사'));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.created.length, 2);
      expect(findPlain('가져오지 못한 예산이 1개 있어요.'), findsOneWidget);
      // 실패 알림이 떠 있는 동안 되돌리기 스낵바는 없다(한 번에 하나)
      expect(findText('되돌리기'), findsNothing);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.created.length, 3);
      expect(findPlain('지난달 예산을 가져왔어요.'), findsOneWidget);
      await tester.tap(findText('되돌리기'));
      await tester.pumpAndSettle();
      expect(repo.deleted, [100, 101, 102]);
    });

    testWidgets('예산 삭제 — 실패하면 창을 닫고 스낵바 + 다시 시도는 묻지 않고 바로 지운다', (tester) async {
      final repo = _FakeBudgetRepo()..failNext = true;
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        overrides: [budgetRepositoryProvider.overrideWith((ref) async => repo)],
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
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(findPlain('예산을 삭제하지 못했어요.'), findsOneWidget);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      // 이미 확정한 삭제 — 같은 질문을 두 번 하지 않고 바로 지운다
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.deleted, [2]);
    });

    testWidgets('저축 목표 삭제 — 제목이 이름을 짚고 확정은 criticalSolid, 확정하면 지운다', (
      tester,
    ) async {
      final repo = _FakeGoalRepo();
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
      expect(findPlain('"여행 적금" 목표를 삭제할까요?'), findsOneWidget);
      expect(findPlain('삭제한 저축 목표는 되돌릴 수 없어요.'), findsOneWidget);
      expect(actionOf(tester).variant, PButtonVariant.criticalSolid);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.deleted, [5]);
    });

    testWidgets('저축 목표 — 트레이 [삭제] → 확인창 → 지운다 · 수정 시트 바닥 [삭제] 도 같은 길', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = _FakeGoalRepo();
      const goals = [
        SavingGoal(
          rowId: 5,
          title: '여행 적금',
          targetAmount: 1000000,
          currentAmount: 100000,
          color: '#3b82f6',
          isAchieved: 'N',
        ),
      ];
      final overrides = [
        savingGoalListProvider.overrideWith((ref) async => goals),
        savingGoalRepositoryProvider.overrideWith((ref) async => repo),
      ];
      await _pump(tester, const SavingGoalScreen(), overrides: overrides);
      await trayDelete(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.deleted, [5]);

      // 수정 시트 바닥 [삭제]
      repo.deleted.clear();
      await _pump(tester, const SavingGoalScreen(), overrides: overrides);
      await sheetDelete(tester, findPlain('여행 적금'));
      expect(repo.deleted, isEmpty);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: findText('삭제'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.deleted, [5]);
      expect(find.byType(PBottomSheetContent), findsNothing);
      handle.dispose();
    });

    testWidgets('저축 목표 삭제 — 실패하면 창을 닫고 스낵바 + 다시 시도는 묻지 않고 바로 지운다', (
      tester,
    ) async {
      final repo = _FakeGoalRepo()..failNext = true;
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
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(findPlain('저축 목표를 삭제하지 못했어요.'), findsOneWidget);
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      // 이미 확정한 삭제 — 다시 묻지 않고 바로 지운다
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(repo.deleted, [5]);
    });
  });
}
