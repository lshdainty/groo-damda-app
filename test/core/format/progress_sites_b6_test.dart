// 진행률 표기 한 규칙(B6 나.6) — 호출처가 formatProgress 를 거치는지 경계 값으로 본다.
// 99.6 → 99%, 100.3 → 101%, 33.6 → 34%, 정확히 100 만 100%.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_trend_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

Widget _host(Widget child, {String locale = 'ko'}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: Locale(locale),
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, child: child)),
  ),
);

void main() {
  group('PProgress 글', () {
    for (final (value, want) in [
      (996.0, '99%'),
      (336.0, '34%'),
      (500.0, '50%'),
    ]) {
      testWidgets('$value / 1000 → $want', (tester) async {
        await tester.pumpWidget(
          _host(
            PProgress(
              label: '목표',
              value: value,
              max: 1000,
              meaning: PProgressMeaning.limit,
            ),
          ),
        );
        expect(find.text(want), findsOneWidget);
      });
    }
  });

  group('PProgressCircle 읽는 값', () {
    for (final (value, want) in [
      (99.6, '99%'),
      (33.6, '34%'),
      (100.0, '100%'),
    ]) {
      testWidgets('$value → $want', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_host(PProgressCircle(value: value, max: 100)));
        expect(
          tester.getSemantics(find.byType(PProgressCircle)),
          matchesSemantics(label: '불러오는 중', value: want),
        );
        semantics.dispose();
      });
    }
  });

  group('BudgetBar 읽는 값', () {
    for (final (value, want) in [
      (99.6, '99%'),
      (100.3, '101%'),
      (33.6, '34%'),
    ]) {
      testWidgets('$value → $want', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(BudgetBar(value: value, max: 100, label: '식비')),
        );
        expect(find.bySemanticsLabel('식비'), findsOneWidget);
        expect(tester.getSemantics(find.bySemanticsLabel('식비')).value, want);
        semantics.dispose();
      });
    }
  });

  group('통계 저축률 링 글', () {
    for (final (rate, want) in [
      (99.6, '99%'),
      (33.6, '34%'),
      (100.0, '100%'),
    ]) {
      testWidgets('$rate → $want', (tester) async {
        await tester.pumpWidget(_host(StatsSavingsRing(rate: rate)));
        final t = tester.widget<Text>(
          find.byKey(const ValueKey('savings-ring-value')),
        );
        expect(t.data, want);
      });
    }
  });

  group('arb — % 는 값에 붙어 오고 문구에는 없다', () {
    testWidgets('ko · en 문구', (tester) async {
      late AppLocalizations ko;
      late AppLocalizations en;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              ko = AppLocalizations.of(c);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              en = AppLocalizations.of(c);
              return const SizedBox();
            },
          ),
          locale: 'en',
        ),
      );
      expect(ko.budgetPercentUsed('99%'), '99% 사용');
      expect(ko.budgetPaceBarValue('99%', '101%'), '99% 사용 · 이번 달 101% 지남');
      expect(ko.budgetMonthElapsed('34%'), '이번 달 34% 경과 ↑');
      expect(ko.statsSavingsInsight('34%'), '월 평균 수입의 34%를 저축하고 있어요');
      expect(ko.assetLimitPctUsed('2000%'), '2000% 사용');
      expect(ko.frpPctBadge('99%'), '99% 달성');
      expect(ko.frpPctBang('100%'), '100% 달성!');
      expect(ko.constDetailTodayPct('99%'), '99%');
      expect(en.budgetPercentUsed('99%'), '99% used');
      expect(en.frpPctBadge('99%'), '99% achieved');
    });
  });
}
