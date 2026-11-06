// 통계 4탭(카테고리/추이/비교/고정·변동) — 칩 탭(2차 탭)은 눌러서만 바뀌고 좌우로 밀어도 넘어가지 않는다.
//
// Tabs 7A(2026-10-16 사용자 결정): "폰 1차만 밀어 넘김" — 통계 안의 2차 밀어 넘기기(PageView)는 걷었다(I-08 30, 10-25 고침).
// 1차 탭(가계부 묶음)의 밀어 넘기기는 셸 몫이라 여기서 다루지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import '../../support/plain_text.dart';

Future<void> _pumpStats(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // 데이터는 이 테스트의 관심사가 아니다 — 탭 전환만 본다.
        categoriesProvider.overrideWith((ref) async => const []),
        rangeExpensesProvider.overrideWith((ref, key) async => const []),
        rangeSummaryProvider.overrideWith(
          (ref, range) async =>
              RangeSummary(startDate: range.startDate, endDate: range.endDate),
        ),
        heatmapProvider.overrideWith(
          (ref, range) async => const <HeatmapCell>[],
        ),
        merchantSummaryProvider.overrideWith(
          (ref, range) async => const <MerchantSummary>[],
        ),
        // 고정·변동 탭이 한 달만 고른 기간에 쓰는 최근 6개월 추이.
        monthlyTrendProvider.overrideWith(
          (ref, months) async => const <MonthlyTrend>[],
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const StatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 지금 고른 칩 탭의 값(PChipTabs 의 value).
StatsTab _selected(WidgetTester tester) =>
    tester.widget<PChipTabs<StatsTab>>(find.byType(PChipTabs<StatsTab>)).value;

void main() {
  testWidgets('칩 탭은 solid · large 이고 PageView 가 없다 — 본문이 옆으로 밀리지 않는다', (
    tester,
  ) async {
    await _pumpStats(tester);
    final tabs = tester.widget<PChipTabs<StatsTab>>(
      find.byType(PChipTabs<StatsTab>),
    );
    expect(tabs.variant, PChipTabsVariant.solid);
    expect(tabs.size, PChipTabsSize.large);
    expect(tabs.items.length, 4);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('좌우로 밀어도 탭이 넘어가지 않는다', (tester) async {
    await _pumpStats(tester);
    final before = _selected(tester);

    await tester.fling(
      find.byType(ListView).first,
      const Offset(-400, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(_selected(tester), before, reason: '왼쪽으로 밀어도 그대로');

    await tester.fling(find.byType(ListView).first, const Offset(400, 0), 1200);
    await tester.pumpAndSettle();
    expect(_selected(tester), before, reason: '오른쪽으로 밀어도 그대로');
  });

  testWidgets('칩을 누르면 탭이 바뀐다 — 눌러서만', (tester) async {
    await _pumpStats(tester);
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    final first = _selected(tester);

    await tester.tap(findText(l.statsTabCompare));
    await tester.pumpAndSettle();
    final compare = _selected(tester);
    expect(compare, isNot(first));

    await tester.tap(findText(l.statsTabFixed));
    await tester.pumpAndSettle();
    expect(_selected(tester), isNot(compare));

    await tester.tap(findText(l.expCategory).first);
    await tester.pumpAndSettle();
    expect(_selected(tester), first);
  });
}
