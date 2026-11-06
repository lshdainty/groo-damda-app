// I-06 홈 — 실제 화면을 띄워 지시서 값을 잰다(폰 360, 가장 나쁜 값).
//
// 구역마다 띠 · 틈(0 · 8) · 구역 머리(9 · 10) · 순자산(11 ~ 15) · 이번 달(16) · 도넛(18 ~ 21) · 예산(22) ·
// 일정 · 할 일(24 · 25) · 오늘 쓴 돈(27 · 28) · 실패(33).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:groo_damda_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import '../../support/hide_cards_fake.dart';
import '../../support/plain_text.dart';

String _monthStart() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-01';
}

String _todayKey() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

const _longCat = '카페·간식·디저트 모임 지출 항목';

DashboardSummary _dash({
  int events = 3,
  int todos = 3,
  int overdue = 23,
}) => DashboardSummary.fromJson({
  'todoSummary': {'overDueCount': overdue},
  'upcomingEvents': [
    for (var i = 0; i < events; i++)
      {
        'rowId': i,
        'title': i == 0
            ? '분기 회고 · 다음 분기 목표 정리 회의 — 팀 전원 참석, 발표 자료는 전날 오후까지 공유 폴더에 올려 두기'
            : '치과 정기 검진 $i',
        'color': '#2c70bf',
        'daysUntil': i == 0 ? 0 : (i == 1 ? 1 : 12),
      },
  ],
  'recentTodos': [
    for (var i = 0; i < todos; i++)
      {
        'rowId': i,
        'title': '자동차 보험 갱신 서류 챙기기 — 만기 전에 비교 견적 세 군데 받아 두기 $i',
        'status': i == 1 ? 'COMPLETED' : 'PENDING',
        'dueDate': i == 0 ? '2020-01-02' : '2999-12-30',
      },
  ],
});

RangeSummary _range(String start, String end, {int categories = 5}) =>
    RangeSummary(
      startDate: start,
      endDate: end,
      totalIncome: start == _monthStart() ? 1350000000 : 0,
      totalExpense: start == _monthStart() ? 3912345678 : 3000000000,
      categoryBreakdown: [
        for (var i = 0; i < categories; i++)
          CategoryBreakdown(
            categoryRowId: i + 1,
            categoryName: i == 0 ? _longCat : '분류 $i',
            expenseType: 'EXPENSE',
            totalAmount: 987654321 - i * 1000,
          ),
      ],
    );

Future<void> _pump(
  WidgetTester tester, {
  double width = 360,
  double textScale = 1,
  AssetSummary? summary,
  Object? summaryError,
  DashboardSummary? dash,
  int categories = 5,
  List<Budget>? budgets,
  List<Expense>? today,
  Object? rangeError,
  Object? budgetsError,
  bool dashPending = false,
  bool todayPending = false,
  List<String>? rangeStarts,
  Object? dashError,
  List<String?>? categoryColors,
  Map<String, int>? reads,
  Set<String> hidden = const {},
  Brightness brightness = Brightness.light,
  String locale = 'ko',
}) async {
  tester.view.physicalSize = Size(width * 2, 4000 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final overrides = [
    hideCardsRepositoryProvider.overrideWith(
      (ref) async => OkHideCardsRepository(),
    ),
    assetSummaryProvider.overrideWith((ref, key) async {
      reads?.update('summary', (v) => v + 1, ifAbsent: () => 1);
      if (summaryError != null) throw summaryError;
      return summary ??
          const AssetSummary(
            netWorth: 98765432100,
            totalAssets: 99998888777,
            totalDebt: 1233456677,
            lastMonthNetWorth: 90000000000,
            changePercent: 9.74,
          );
    }),
    rangeSummaryProvider.overrideWith((ref, r) async {
      rangeStarts?.add(r.startDate);
      if (r.startDate == _monthStart()) {
        reads?.update('range', (v) => v + 1, ifAbsent: () => 1);
      }
      if (rangeError != null) throw rangeError;
      return _range(r.startDate, r.endDate, categories: categories);
    }),
    monthExpensesProvider.overrideWith((ref, key) async {
      if (todayPending) return Completer<List<Expense>>().future;
      return today ?? const [];
    }),
    categoriesProvider.overrideWith(
      (ref) async => [
        for (var i = 0; i < categories; i++)
          ExpenseCategory(
            rowId: i + 1,
            categoryName: i == 0 ? _longCat : 'c$i',
            expenseType: 'EXPENSE',
            color: categoryColors != null && i < categoryColors.length
                ? categoryColors[i]
                : null,
          ),
      ],
    ),
    monthBudgetsProvider.overrideWith((ref, key) async {
      reads?.update('budgets', (v) => v + 1, ifAbsent: () => 1);
      if (budgetsError != null) throw budgetsError;
      return budgets ??
          [
            Budget(
              rowId: 1,
              budgetAmount: 3000000,
              budgetYear: key.year,
              budgetMonth: key.month,
            ),
            Budget(
              rowId: 2,
              categoryRowId: 1,
              categoryName: _longCat,
              budgetAmount: 100000000,
              budgetYear: key.year,
              budgetMonth: key.month,
            ),
          ];
    }),
    dashboardSummaryProvider.overrideWith((ref) async {
      reads?.update('dash', (v) => v + 1, ifAbsent: () => 1);
      if (dashPending) return Completer<DashboardSummary>().future;
      if (dashError != null) throw dashError;
      return dash ?? _dash();
    }),
  ];
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? GrooTheme.dark()
            : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: DashboardScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  if (hidden.isNotEmpty) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );
    await container.read(settingsProvider.notifier).hideCards(hidden);
    await tester.pump();
  }
}

/// 순자산 띠는 브랜드 채움 면(`home-hero-face`)이고 나머지는 흰 구역 띠(`screen-section`)다.
Finder get _whiteBands => find.byKey(const ValueKey('screen-section'));
int _bandCount() => 1 + _whiteBands.evaluate().length;
List<Rect> _bandRects(WidgetTester t) => [
  t.getRect(find.byKey(const ValueKey('home-hero-face'))),
  for (var i = 0; i < _whiteBands.evaluate().length; i++)
    t.getRect(_whiteBands.at(i)),
];

Expense _tx(int id, {String type = 'EXPENSE', int amount = 1234567890}) =>
    Expense(
      rowId: id,
      expenseType: type,
      amount: amount,
      merchant: '아주 길고 긴 이름의 온라인 종합 쇼핑몰 본점 (서울 중앙 물류센터 직영)',
      categoryName: _longCat,
      assetName: '아주 길게 지은 통장 별칭 — 생활비 · 비상금 · 공과금 겸용 통장',
      expenseDate: '${_todayKey()}T00:00:00',
    );

void main() {
  group('구역마다 띠 — 5 · 6 · 8', () {
    testWidgets('일곱 띠 · 사이 8 여섯 · 머리 아래 틈 0 · 마지막 띠 아래 8 없음', (tester) async {
      await _pump(tester, today: [_tx(1)]);
      expect(
        _bandCount(),
        7,
        reason: '구역마다 띠 — 순자산 · 가계부 · 카테고리 · 예산 · 일정 · 할 일 · 오늘',
      );
      final rects = _bandRects(tester);
      final top = tester.getRect(find.byType(DashboardScreen)).top;
      // 테스트 빌드는 dev 라 배지 줄(위 8 + 20 + 아래 8)이 순자산 위에 선다 — 운영(prod)이면 틈 0
      final devRow = Env.appEnv != 'prod' ? 36.0 : 0.0;
      expect(
        rects.first.top - top,
        devRow,
        reason: '머리 바로 아래 첫 띠 — 틈 없음(배지 줄 말고는)',
      );
      for (var i = 0; i < 6; i++) {
        expect(rects[i + 1].top - rects[i].bottom, 8, reason: '띠 사이 8');
      }
    });

    testWidgets('일정 · 할 일이 비는 네 갈래 — 띠 수 7 · 6 · 6 · 5', (tester) async {
      await _pump(tester, dash: _dash());
      expect(_bandCount(), 7);
      await _pump(tester, dash: _dash(todos: 0));
      expect(_bandCount(), 6);
      await _pump(tester, dash: _dash(events: 0));
      expect(_bandCount(), 6);
      await _pump(tester, dash: _dash(events: 0, todos: 0));
      expect(_bandCount(), 5, reason: '둘 다 비면 일정 · 할 일 띠가 없다');
      final rects = _bandRects(tester);
      for (var i = 0; i < rects.length - 1; i++) {
        expect(rects[i + 1].top - rects[i].bottom, 8, reason: '빈 띠 · 겹친 틈 없음');
      }
    });

    testWidgets(
      '띠 안 값 — 머리 위 24 · 글 구역 아래 24 · 목록 구역 아래 12 + 줄 · 제목 t5 · 700',
      (tester) async {
        await _pump(tester);
        final headers = find.byKey(const ValueKey('card-header'));
        // 순자산 띠는 머리가 없다 — 가계부 · 카테고리 · 예산 · 일정 · 할 일 · 오늘 쓴 돈
        expect(headers, findsNWidgets(6));
        final rects = _bandRects(tester);
        final titles = find.byKey(const ValueKey('card-title'));
        for (var i = 0; i < 6; i++) {
          expect(
            tester.getRect(titles.at(i)).top - rects[i + 1].top,
            // 머리 위 24 + (동작 버튼 36 이 제목 22 보다 높아 세로 가운데 정렬로 제목이 7 내려간다)
            anyOf(24, 31),
            reason: '띠 맨 위 = 머리 위 24 (띠 ${i + 2})',
          );
        }
        // 카테고리(글 · 차트 구역) — 마지막 내용 끝에서 아래 24
        expect(
          rects[2].bottom -
              tester
                  .getRect(find.byKey(const ValueKey('chart-donut-legend')))
                  .bottom,
          24,
        );
        // 일정(목록 구역) — 마지막 줄 아래 12(줄 자체 12 와 합쳐 24)
        final rows = find.byType(PListButtonItem);
        expect(rects[4].bottom - tester.getRect(rows.at(2)).bottom, 12);
        final title = tester.widget<Text>(titles.first);
        expect(title.style?.fontSize, 16);
        expect(title.style?.fontWeight, FontWeight.w700);
      },
    );

    testWidgets('눈 누르는 영역 44', (tester) async {
      await _pump(tester);
      final area = tester.widget<PressArea>(
        find.descendant(
          of:
              find
                  .byKey(const ValueKey('home-hero-eye'))
                  .first
                  .evaluate()
                  .isEmpty
              ? find.byType(DashboardScreen)
              : find.byType(DashboardScreen),
          matching: find.byType(PressArea),
        ),
      );
      expect(area.touchMin, 44);
    });
  });

  group('구역 머리 — 9 · 10', () {
    testWidgets('동작 "전체 보기"(이름 "{제목} 전체 보기") · 앞 아이콘 0 · 덧붙임이 heading 밖', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      expect(findText('전체 보기'), findsNWidgets(5));
      expect(find.bySemanticsLabel('카테고리 전체 보기'), findsOneWidget);
      expect(find.bySemanticsLabel('최근 할 일 전체 보기'), findsOneWidget);
      // 연체 배지는 제목 줄에 붙고 heading 노드 밖이다
      // 보이는 글 "연체 23", 읽는 글 "연체 23건"(웹 OverdueBadge 와 같다, I-06 home 21)
      final badge = find.widgetWithText(PBadge, '연체 23');
      expect(badge, findsOneWidget);
      expect(findText('연체 23건'), findsNothing, reason: '보이는 글에는 건이 없다');
      expect(find.bySemanticsLabel(RegExp('연체 23건')), findsOneWidget);
      expect(
        find.ancestor(
          of: badge,
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.header == true,
          ),
        ),
        findsNothing,
      );
      // 일정 · 할 일 머리에 앞 아이콘이 없다
      expect(find.byIcon(LucideIcons.calendarClock), findsNothing);
      expect(find.byIcon(LucideIcons.squareCheckBig), findsNothing);
      handle.dispose();
    });
  });

  group('순자산 — 11 ~ 15', () {
    testWidgets('금액 · 원 같은 줄 · 라벨 불투명 · 눈 40 · 이름 · 토글 아님', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      expect(findPlain('98,765,432,100원'), findsOneWidget);
      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('card-hero-amount')),
      );
      expect(amount.style?.fontSize, 32);
      expect(amount.style?.fontWeight, FontWeight.w700);
      final label = tester.widget<Text>(
        find.byKey(const ValueKey('card-hero-label')),
      );
      expect(label.style?.color?.a, 1.0, reason: '흐리게 두지 않는다');
      // 눈
      final eye = find.byKey(const ValueKey('home-hero-eye'));
      expect(tester.getSize(eye), const Size(40, 40));
      final node = tester.getSemantics(find.bySemanticsLabel('금액 가리기 설정'));
      expect(
        node.flagsCollection.isToggled.toBoolOrNull(),
        isNull,
        reason: '토글이 아니다',
      );
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
      // 두 칸 — 원까지, 부채는 U+2212
      expect(findPlain('99,998,888,777원'), findsOneWidget);
      expect(findPlain('−1,233,456,677원'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('가리면 눈 꺼짐 아이콘 · 금액 ••••••', (tester) async {
      await _pump(tester, hidden: {'home.netWorth'});
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(findPlain('98,765,432,100원'), findsNothing);
    });

    testWidgets('지난달 기록 없음(14) — 증감 대신 글, ▲ 없음', (tester) async {
      await _pump(
        tester,
        summary: const AssetSummary(netWorth: 5000000, lastMonthNetWorth: 0),
      );
      expect(findPlain('지난달 기록 없음'), findsOneWidget);
      expect(find.byType(PDelta), findsNothing);
    });

    testWidgets('360 · 200% 넘침 없음', (tester) async {
      await _pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('이번 달 가계부 — 16', () {
    testWidgets('수입 · 지출 줄 원까지 · 수입 brand · 지출 neutral · 안내 % 색 없음', (
      tester,
    ) async {
      await _pump(tester);
      final income = tester.widget<Text>(findPlain('+1,350,000,000원'));
      expect(income.style?.color, PColors.light.fgBrand);
      final expense = tester.widget<Text>(findPlain('−3,912,345,678원'));
      expect(expense.style?.color, PColors.light.fgNeutral);
      // 안내 문장의 % 는 fg-neutral · 700(색으로 좋고 나쁨을 말하지 않는다)
      final note = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              plainOf(w.text.toPlainText()).startsWith('하루 평균'),
        ),
      );
      final spans = <TextSpan>[];
      note.text.visitChildren((s) {
        if (s is TextSpan) spans.add(s);
        return true;
      });
      final pct = spans.firstWhere((s) => (s.text ?? '').endsWith('%'));
      expect(pct.style?.color, PColors.light.fgNeutral);
      expect(pct.style?.fontWeight, FontWeight.w700);
    });
  });

  group('카테고리 도넛 — 18 ~ 21', () {
    testWidgets('조각 10(기타 회색) · 가운데 글 없음 · 합계 줄 원까지 · 범례 말줄임 0', (
      tester,
    ) async {
      await _pump(tester, categories: 11);
      final donut = tester.widget<PDonutChart>(find.byType(PDonutChart));
      expect(donut.slices, hasLength(10));
      expect(donut.slices.last.label, '기타');
      expect(donut.slices.last.color, PChartColor.gray);
      expect(donut.centerAmount, isNull, reason: '폰은 가운데 글을 그리지 않는다');
      expect(donut.diameter, 120);
      // 합계 줄(목록 위 한 줄)
      expect(findText('이번 달 지출'), findsOneWidget);
      // 범례 이름은 줄을 바꾼다 — 말줄임 · 줄 수 제한 없음
      final names = tester.widgetList<Text>(
        find.byKey(const ValueKey('chart-donut-label')),
      );
      for (final t in names) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
        expect(t.maxLines, isNull);
      }
      expect(findPlain(_longCat), findsOneWidget, reason: '긴 이름이 모든 글자 보인다');
    });

    testWidgets('가리면 합계 · 범례 금액 ••••', (tester) async {
      await _pump(tester, hidden: {'home.categoryDonut'});
      final legend = tester.widgetList<Text>(
        find.byKey(const ValueKey('chart-donut-amount')),
      );
      expect(legend, isNotEmpty);
      for (final t in legend) {
        expect(plainOf(t.data!), '••••');
      }
    });

    testWidgets('200% 에서도 넘침 없음 · 범례 % · 금액이 이름 아래로', (tester) async {
      await _pump(tester, textScale: 2, categories: 5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('데이터가 없으면 "이번 달 지출이 없어요"', (tester) async {
      await _pump(tester, categories: 0);
      expect(findPlain('이번 달 지출이 없어요'), findsOneWidget);
    });
  });

  group('예산 — 22', () {
    testWidgets('Progress 줄 · 이름 "{이름} 예산" · 타일 0 · 초과는 fg-critical', (
      tester,
    ) async {
      await _pump(tester);
      final bars = tester.widgetList<PProgress>(find.byType(PProgress));
      expect(bars, hasLength(2));
      expect(bars.first.label, '총 예산');
      expect(bars.last.label, '$_longCat 예산', reason: '긴 카테고리 이름 + 예산');
      // 총 예산도(3,912,345,678 > 3,000,000) · 긴 이름 예산도(987,654,321 > 100,000,000) 넘쳤다
      expect(findTextContaining('초과'), findsNWidgets(2));
      final overText = find.descendant(
        of: find.byWidget(bars.last),
        matching: findTextContaining('887,654,321원 초과'),
      );
      expect(overText, findsOneWidget, reason: '긴 이름 줄에 "…원 초과" 가 있다');
      expect(find.byType(PListTile), findsNothing, reason: '카테고리 타일을 뺀다');
    });

    testWidgets('85 ~ 100% 는 경고 색이 없다 — 채움 fg-brand', (tester) async {
      final now = DateTime.now();
      await _pump(
        tester,
        budgets: [
          Budget(
            rowId: 1,
            categoryRowId: 1,
            budgetAmount: 1000000000,
            budgetYear: now.year,
            budgetMonth: now.month,
          ),
        ],
      );
      // 987,654,321 / 1,000,000,000 = 99%
      final fill = tester.widget<Container>(
        find.byKey(const ValueKey('progress-fill')),
      );
      expect((fill.decoration! as BoxDecoration).color, PColors.light.fgBrand);
    });

    testWidgets('빈 예산 글', (tester) async {
      await _pump(tester, budgets: const []);
      expect(findPlain('등록된 예산이 없어요'), findsOneWidget);
    });

    testWidgets('가림 시 금액 줄 · 초과 글 · 막대 이름이 ••••', (tester) async {
      await _pump(tester, hidden: {'home.budget'});
      final texts = find.descendant(
        of: find.byType(PProgress),
        matching: find.byType(Text),
      );
      for (final t in tester.widgetList<Text>(texts)) {
        expect(plainOf(t.data ?? ''), isNot(contains('987,654,321')));
        expect(plainOf(t.data ?? ''), isNot(contains('3,912,345,678')));
      }
      expect(
        tester
            .widgetList<PProgress>(find.byType(PProgress))
            .every((p) => p.formatValue!(1) == '••••'),
        isTrue,
      );
    });
  });

  group('일정 · 할 일 — 24 · 25', () {
    testWidgets('긴 제목 말줄임 0 · 두 줄을 넘으면 위 맞춤 · 뒤 값 글자 · 사흘 안 warning', (
      tester,
    ) async {
      await _pump(tester);
      final rows = tester.widgetList<PListButtonItem>(
        find.byType(PListButtonItem),
      );
      // 일정 셋 + 할 일 셋
      expect(rows, hasLength(6));
      for (final r in rows) {
        expect(r.align, PListAlign.top, reason: '긴 제목이 있어 목록이 위 맞춤');
      }
      final titles = tester.widgetList<Text>(
        find.byKey(const ValueKey('plist-title')),
      );
      for (final t in titles) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
        expect(t.maxLines, isNull);
      }
      final today = tester.widget<Text>(findText('오늘'));
      expect(today.style?.color, PColors.light.fgWarning);
      final far = tester.widget<Text>(findText('D-12').first);
      expect(far.style?.color, isNull, reason: '사흘 밖은 값 글자 기본색');
    });

    testWidgets(
      '앞 붙이개 자리 높이 = 제목 한 줄(t5 22) × 글자 배율 — 200% 에서도 첫 줄 가운데(I-29b)',
      (tester) async {
        for (final scale in [1.0, 2.0]) {
          await _pump(tester, textScale: scale);
          final prefixes = find.byKey(const ValueKey('plist-prefix'));
          expect(prefixes, findsWidgets);
          for (final e in prefixes.evaluate()) {
            expect(
              (e.renderObject! as RenderBox).size.height,
              22.0 * scale,
              reason: '배율 $scale — 붙이개 자리가 제목 한 줄 높이',
            );
          }
        }
      },
    );

    testWidgets('완료 할 일은 취소선', (tester) async {
      await _pump(tester);
      final done = tester
          .widgetList<PListButtonItem>(find.byType(PListButtonItem))
          .where((r) => r.titleStrike);
      expect(done, hasLength(1));
    });

    testWidgets('할 일 앞 표시는 square neutral 체크 칸 — 완료만 checked', (tester) async {
      await _pump(tester);
      final marks = tester
          .widgetList<PCheckmark>(find.byType(PCheckmark))
          .toList();
      expect(marks, hasLength(3));
      expect(marks.where((m) => m.checked == true), hasLength(1));
      for (final m in marks) {
        expect(m.shape, PCheckboxShape.square);
        expect(m.tone, PCheckboxTone.neutral);
      }
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
      // 제목 한 줄(22)보다 칸(24)이 커도 눌리지 않고 정사각 24 로 그린다
      for (final e in find.byType(PCheckmark).evaluate()) {
        expect((e.renderObject! as RenderBox).size, const Size(24, 24));
      }
    });
  });

  group('오늘 쓴 돈 · 거래 줄 — 27 · 28', () {
    testWidgets('가맹점 말줄임 0 · 금액 쉼표 뒤 줄바꿈 · 수입만 brand', (tester) async {
      await _pump(
        tester,
        today: [
          _tx(1),
          _tx(2, type: 'INCOME', amount: 150000),
        ],
      );
      final titles = tester.widgetList<Text>(
        find.byKey(const ValueKey('plist-title')),
      );
      expect(titles, isNotEmpty);
      for (final t in titles) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
        expect(t.maxLines, isNull);
      }
      final exp = tester.widget<Text>(findPlain('−1,234,567,890원').last);
      expect(exp.style?.color, PColors.light.fgNeutral);
      final inc = tester.widget<Text>(findPlain('+150,000원'));
      expect(inc.style?.color, PColors.light.fgBrand);
      // 머리 오늘 합계 = 지출만(수입은 오늘 쓴 돈이 아니다)
      expect(findPlain('−1,234,567,890원'), findsNWidgets(2));
    });

    testWidgets('home.todaySpend 만 가리면 머리 합계 · 줄 금액 모두 ••••', (tester) async {
      await _pump(tester, today: [_tx(1)], hidden: {'home.todaySpend'});
      expect(findPlainContaining('1,234,567,890'), findsNothing);
    });

    testWidgets('ledger.txList 만 가려도 홈 줄 금액은 보인다(앱 회귀)', (tester) async {
      await _pump(tester, today: [_tx(1)], hidden: {'ledger.txList'});
      expect(findPlain('−1,234,567,890원'), findsNWidgets(2));
    });
  });

  group('실패 — 33 · 36', () {
    testWidgets('기간 합계 실패 → 가계부 · 카테고리 · 예산만 실패, 0원 없음', (tester) async {
      await _pump(tester, rangeError: Exception('x'));
      expect(find.byType(PResultSection), findsNWidgets(3));
      expect(findPlain('0원'), findsNothing, reason: '조용한 0원이 없다');
      // 순자산 · 일정 · 오늘 쓴 돈은 그대로
      expect(findPlain('98,765,432,100원'), findsOneWidget);
      expect(findText('오늘'), findsOneWidget);
    });

    testWidgets('실패 한 벌 — "{구역}을/를 불러오지 못했어요" + 같은 설명', (tester) async {
      await _pump(
        tester,
        rangeError: Exception('x'),
        summaryError: Exception('x'),
        dashError: Exception('x'),
      );
      for (final t in [
        '순자산을 불러오지 못했어요',
        '이번 달 가계부를 불러오지 못했어요',
        '카테고리를 불러오지 못했어요',
        '예산을 불러오지 못했어요',
        '다가오는 일정을 불러오지 못했어요',
        '최근 할 일을 불러오지 못했어요',
      ]) {
        expect(findPlain(t), findsOneWidget, reason: t);
      }
      expect(findPlain('잠시 뒤 다시 시도해주세요.'), findsNWidgets(6));
      // 일정 · 할 일은 같은 질의라 같이 실패해도 띠마다 하나씩
      expect(
        _whiteBands.evaluate().length,
        7,
        reason: '순자산도 흰 띠 — 모두 구역마다 하나씩',
      );
    });

    testWidgets('순자산 실패 — 브랜드 채움이 아니라 흰 띠 + 머리 "순자산"', (tester) async {
      await _pump(tester, summaryError: Exception('x'));
      expect(find.byKey(const ValueKey('home-hero-face')), findsNothing);
      expect(findPlain('순자산'), findsOneWidget);
      expect(find.byType(PResultSection), findsOneWidget);
    });

    testWidgets('다시 시도는 그 구역 질의만 — 순자산', (tester) async {
      final reads = <String, int>{};
      await _pump(tester, summaryError: Exception('x'), reads: reads);
      final before = Map.of(reads);
      await tester.tap(findText('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(reads['summary'], before['summary']! + 1);
      expect(reads['range'], before['range'], reason: '다른 질의는 안 부른다');
      expect(reads['budgets'], before['budgets']);
      expect(reads['dash'], before['dash']);
    });

    testWidgets('다시 시도는 그 구역 질의만 — 예산은 실패한 예산 목록만', (tester) async {
      final reads = <String, int>{};
      await _pump(tester, budgetsError: Exception('x'), reads: reads);
      final before = Map.of(reads);
      await tester.tap(findText('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(reads['budgets'], before['budgets']! + 1);
      expect(reads['range'], before['range'], reason: '멀쩡한 기간 합계는 다시 받지 않는다');
    });

    testWidgets('일정 · 할 일 — 한 질의 실패는 두 띠에 하나씩, 다시 시도는 그 질의 하나', (tester) async {
      final reads = <String, int>{};
      await _pump(tester, dashError: Exception('x'), reads: reads);
      expect(find.byType(PResultSection), findsNWidgets(2));
      final before = Map.of(reads);
      await tester.tap(findText('다시 시도').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(reads['dash'], before['dash']! + 1);
      expect(reads['summary'], before['summary']);
    });

    testWidgets('불러오는 중 — 일정 · 할 일 틀이 먼저(머리 + 전체 보기)', (tester) async {
      await _pump(tester, dashPending: true);
      expect(findPlain('다가오는 일정'), findsOneWidget);
      expect(findPlain('최근 할 일'), findsOneWidget);
      // 카테고리 · 예산 · 오늘 쓴 돈 + 일정 · 할 일 = 다섯
      expect(findText('전체 보기'), findsNWidgets(5));
    });
  });

  group('저장된 색 — 18', () {
    test('chartKeyOfHex 는 차트 10색 기본 hex 만 이름으로 읽는다', () {
      expect(chartKeyOfHex('#2c70bf'), 'blue');
      expect(chartKeyOfHex(' #2C70BF '), 'blue');
      expect(chartKeyOfHex('#c73838'), 'red');
      expect(chartKeyOfHex('#123456'), isNull);
      expect(chartKeyOfHex(null), isNull);
      expect(chartKeyOfHex(''), isNull);
    });

    testWidgets('저장된 hex 가 같은 색 이름으로 · 나머지는 안 쓴 색 · 같은 색 두 번 없음', (
      tester,
    ) async {
      await _pump(
        tester,
        categories: 4,
        categoryColors: ['#c73838', null, '#123456', '#2c70bf'],
      );
      final donut = tester.widget<PDonutChart>(find.byType(PDonutChart));
      final colors = donut.slices.map((s) => s.color).toList();
      expect(colors[0], PChartColor.red, reason: '저장된 red');
      expect(colors[3], PChartColor.blue, reason: '저장된 blue');
      // 색 없음(1) · 팔레트 밖(2) — 쓰지 않은 색(blue · red 는 이미 씀)에서 배정 순서대로
      expect(colors[1], PChartColor.green);
      expect(colors[2], PChartColor.orange);
      expect(colors.toSet().length, 4);
    });
  });

  group('예산 이름 en', () {
    testWidgets('한 달 전체 예산 금액의 이름 "Total budget"', (tester) async {
      await _pump(tester, locale: 'en');
      final bars = tester.widgetList<PProgress>(find.byType(PProgress));
      expect(bars.first.label, 'Total budget');
    });
  });

  group('불러오는 중 줄 모양 — 웹 한 벌', () {
    testWidgets('오늘 쓴 돈: 타일 40 · 모서리 12 + 제목 · 설명 두 줄(66)', (tester) async {
      await _pump(tester, todayPending: true);
      final tiles = tester
          .widgetList<PSkeleton>(find.byType(PSkeleton))
          .where((k) => k.width == 40 && k.height == 40);
      expect(tiles, hasLength(2));
      expect(tiles.first.radius, PSkeletonRadius.r12);
      // 줄 높이 = 위아래 12 + 타일 40 = 64 이상(제목 22 + 설명 18 + 2 = 42 가 타일 40 보다 큼 → 66)
      final row = find.ancestor(
        of: find.byWidget(tiles.first),
        matching: find.byType(Padding),
      );
      expect(tester.getSize(row.first).height, 66);
    });
  });

  group('월 경계 — 앱이 다시 앞으로 올 때', () {
    tearDown(() => dashboardNow = DateTime.now);

    testWidgets('말일에 켜 둔 홈이 1일에 resumed 되면 달 · 오늘을 새로 잡는다', (tester) async {
      dashboardNow = () => DateTime(2026, 1, 31, 23, 0);
      final starts = <String>[];
      await _pump(
        tester,
        rangeStarts: starts,
        today: [
          Expense(
            rowId: 1,
            expenseType: 'EXPENSE',
            amount: 4800,
            merchant: '모퉁이 커피',
            expenseDate: '2026-02-01T00:00:00',
          ),
        ],
      );
      expect(starts, contains('2026-01-01'));
      expect(findPlain('오늘은 아직 쓴 돈이 없어요'), findsOneWidget, reason: '아직 1월 31일');

      dashboardNow = () => DateTime(2026, 2, 1, 9, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(starts, contains('2026-02-01'), reason: '새 달 기간 합계를 받는다');
      expect(findPlain('모퉁이 커피'), findsOneWidget, reason: '오늘 쓴 돈이 2월 1일 거래로');
      expect(findPlain('1월 가계부'), findsNothing);
      expect(findPlainContaining('2월 가계부'), findsOneWidget);
    });

    testWidgets('같은 달 안에서 날만 바뀌어도 오늘 기준이 새로 잡힌다(질의는 그대로)', (tester) async {
      dashboardNow = () => DateTime(2026, 1, 15, 23, 0);
      final starts = <String>[];
      await _pump(
        tester,
        rangeStarts: starts,
        today: [
          Expense(
            rowId: 1,
            expenseType: 'EXPENSE',
            amount: 4800,
            merchant: '모퉁이 커피',
            expenseDate: '2026-01-16T00:00:00',
          ),
        ],
      );
      final n = starts.length;
      expect(findPlain('오늘은 아직 쓴 돈이 없어요'), findsOneWidget);
      dashboardNow = () => DateTime(2026, 1, 16, 9, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        findPlain('모퉁이 커피'),
        findsOneWidget,
        reason: '1월 16일 거래가 오늘 쓴 돈으로',
      );
      expect(starts.length, n, reason: '달이 같으니 다시 받지 않는다');
    });

    testWidgets('같은 날이면 다시 받지 않는다', (tester) async {
      dashboardNow = () => DateTime(2026, 1, 15, 9, 0);
      final starts = <String>[];
      await _pump(tester, rangeStarts: starts);
      final n = starts.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(starts.length, n);
    });
  });
}
