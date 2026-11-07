// 열지도 칸 글 규칙(I-08 34 · chart.md:110) — 칸 폭이 112 미만이면 칸에 글이 없고(세기 색만), 값은 칸을 누르면 뜨는 툴팁에서
// 원까지 읽는다. 좁다고 금액을 줄여 쓰지 않는다(옛 `5천` · `1.2만` 줄임 글을 걷었다 — 03E-006 사용자 결정).
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 띄워 글자를 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_screen.dart';
import '../../support/plain_text.dart';

/// 히트맵이 있는 '카테고리' 탭(기본 탭)을 띄우고 히트맵 카드까지 스크롤한다.
Future<void> _pumpHeatmap(WidgetTester tester, int cellAmount) async {
  tester.view.physicalSize = const Size(480 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => const []),
        rangeExpensesProvider.overrideWith((ref, key) async => const []),
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
            totalExpense: cellAmount,
          ),
        ),
        merchantSummaryProvider.overrideWith(
          (ref, range) async => const <MerchantSummary>[],
        ),
        heatmapProvider.overrideWith(
          // 월요일 12시 한 칸만 채운다 — 나머지 칸은 0(`—`)이다.
          (ref, range) async => [
            HeatmapCell(dayOfWeek: 1, hour: 12, totalAmount: cellAmount),
          ],
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

  await tester.scrollUntilVisible(
    findPlain('요일 · 시간대 지출 패턴'),
    300,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey('stats-category')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('칸 폭 112 미만(폰) — 칸에 글이 없다, 줄임 글(5천 · 1.2만)도 없다', (tester) async {
    await _pumpHeatmap(tester, 4900);

    final heat = find.byKey(const ValueKey('chart-heatmap'));
    expect(heat, findsOneWidget);
    // 열지도 안에는 금액 글이 하나도 없다 — 라벨(아침 · 06~10시)과 요일만
    for (final amountLike in ['5천', '4,900', '4,900원', '—']) {
      expect(
        find.descendant(of: heat, matching: findText(amountLike)),
        findsNothing,
        reason: "칸 글 \"$amountLike\" 이 남아 있다",
      );
    }
  });

  testWidgets('칸을 누르면 툴팁이 원까지 값을 읽어 준다 — 줄이지 않는다', (tester) async {
    await _pumpHeatmap(tester, 11881);

    // 월요일 12시 = 둘째 줄(10~14시) · 첫 칸
    await tester.tap(find.byKey(const ValueKey('chart-heatmap-cell-1-0')));
    await tester.pump();
    expect(findText('11,881원'), findsOneWidget);
    expect(findText('1.2만'), findsNothing);
    expect(findPlainContaining('월 점심'), findsWidgets);
  });
}
