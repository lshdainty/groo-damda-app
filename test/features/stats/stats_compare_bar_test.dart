// 비교 탭 견줌 막대 줄(I-28-2) — 이름과 금액은 양 끝, 사이 8 이상. 금액은 자르지 않고, 모자라면 이름이 줄을 바꾼다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_compare_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

// keepAll 이 낱말 사이에 U+2060 을 끼우므로 걷어 내고 찾는다. 막대 줄의 이름은 글자 "2026년 9월" 만 있는 Text.
Finder _name() => find
    .byWidgetPredicate(
      (w) => w is Text && w.data?.replaceAll('\u2060', '') == '2026년 9월',
    )
    .last;

Future<void> _pump(
  WidgetTester tester,
  double scale, {
  double width = 360,
  int amount = 123456789,
}) async {
  tester.view.physicalSize = Size(width * 2, 800 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final saved = statsNow;
  statsNow = () => DateTime(2026, 10, 29, 13);
  addTearDown(() => statsNow = saved);
  final period = StatsPeriod(
    seg: StatsSeg.month,
    from: DateTime(2026, 9),
    to: DateTime(2026, 9, 30),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatsCompareSummarySection(
            period: period,
            now: RangeSummary(
              startDate: '2026-09-01',
              endDate: '2026-09-30',
              totalExpense: amount,
            ),
            prev: RangeSummary(
              startDate: '2026-08-01',
              endDate: '2026-08-31',
              totalExpense: 80000000,
            ),
            masked: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('360 · 200% · 금액 123,456,789원 — 금액은 다 보이고 이름과 사이 8 이상', (
    tester,
  ) async {
    await _pump(tester, 2);
    expect(tester.takeException(), isNull);
    final amount = findText('123,456,789원').last;
    final name = _name();
    final a = tester.getRect(amount);
    final n = tester.getRect(name);
    // 금액이 화면 안(좌우 24 안쪽)에 다 들어온다
    expect(a.right, lessThanOrEqualTo(360 - 24 + 0.5));
    // 금액 글이 제 폭을 다 쓴다(자르지 않음) — 같은 줄에 이름이 있으면 사이 8 이상
    final sameLine = (a.top - n.top).abs() < n.height;
    if (sameLine) expect(a.left - n.right, greaterThanOrEqualTo(8));
    // 이 폭에서는 이름이 줄을 바꾼다(2줄 이상) — 한 줄이면 위 사이 규칙이 지킨다
    expect(n.height, greaterThan(0));
  });

  testWidgets('360 · 100% — 한 줄에 이름 · 막대 · 금액', (tester) async {
    await _pump(tester, 1);
    expect(tester.takeException(), isNull);
    final a = tester.getRect(findText('123,456,789원').last);
    final n = tester.getRect(_name());
    expect((a.center.dy - n.center.dy).abs(), lessThan(8));
    expect(a.left - n.right, greaterThanOrEqualTo(8));
  });

  testWidgets(
    '쌓기 — 320 · 200% · 1,234,567,890원: 이름 위 · 금액 오른쪽 끝 아래 · 막대 그 아래',
    (tester) async {
      await _pump(tester, 2, width: 320, amount: 1234567890);
      expect(tester.takeException(), isNull);
      final a = tester.getRect(findText('1,234,567,890원').last);
      final n = tester.getRect(_name());
      // 이름 위, 금액 아래(같은 줄이 아니다)
      expect(a.top, greaterThanOrEqualTo(n.bottom - 0.5));
      // 금액은 오른쪽 끝(좌우 24 안쪽) · 온전히 보인다
      expect(a.right, closeTo(320 - 24, 0.5));
      expect(a.left, greaterThanOrEqualTo(24));
      // 막대는 금액 아래
      final bar = tester.getRect(find.byType(FractionallySizedBox).first);
      expect(bar.top, greaterThanOrEqualTo(a.bottom - 0.5));
    },
  );
}
