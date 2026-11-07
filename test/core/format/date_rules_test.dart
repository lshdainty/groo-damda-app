// 날짜 규칙(DESIGN.md 날짜 · 요일, I-wrap-b3 가.5) — 앞 0 을 채우지 않고, 요일은 괄호, 기간은 "~".
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/net_worth_point.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/net_worth_chart.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';

import '../../support/hide_cards_fake.dart';

String _dow(DateTime d) => '월화수목금토일'[d.weekday - 1];

void main() {
  setUpAll(() async => initializeDateFormatting());

  test('기간 줄 — 올해 안이면 "11월 2일~11월 8일"(앞 0 · 점 표기 없음)', () {
    final y = DateTime.now().year;
    expect(dateRange(DateTime(y, 11, 2), DateTime(y, 11, 8)), '11월 2일~11월 8일');
    expect(dateRange(DateTime(y, 1, 1), DateTime(y, 1, 7)), '1월 1일~1월 7일');
  });

  test('기간 줄 — 다른 해가 끼면 두 끝 모두 연도를 붙인다', () {
    final y = DateTime.now().year;
    expect(
      dateRange(DateTime(y - 1, 12, 29), DateTime(y, 1, 4)),
      '${y - 1}년 12월 29일~$y년 1월 4일',
    );
    expect(
      dateRange(DateTime(y + 1, 3, 1), DateTime(y + 1, 3, 7)),
      '${y + 1}년 3월 1일~${y + 1}년 3월 7일',
    );
  });

  test('날짜 머리 — "11월 6일 (금)" 한 글(올해가 아니면 연도 앞)', () {
    final y = DateTime.now().year;
    expect(
      monthDayDow(DateTime(y, 11, 6)),
      '11월 ${6}일 (${_dow(DateTime(y, 11, 6))})',
    );
    expect(monthDayDow(DateTime(2100, 1, 1)), '2100년 1월 1일 (금)');
  });

  test('통계 월 눈금 — 한 해 안이면 "1월", 해가 섞이면 "2026. 1."', () {
    expect(monthLabels([(year: 2026, month: 1), (year: 2026, month: 12)]), [
      '1월',
      '12월',
    ]);
    expect(monthLabels([(year: 2025, month: 12), (year: 2026, month: 1)]), [
      '2025. 12.',
      '2026. 1.',
    ]);
  });

  testWidgets('순자산 추이 x 눈금 — "1월" … "12월"(앞 0 없음)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hideCardsRepositoryProvider.overrideWith(
            (ref) async => OkHideCardsRepository(),
          ),
          netWorthTrendProvider.overrideWith(
            (ref, months) async => [
              for (var m = 1; m <= 12; m++)
                NetWorthPoint(year: 2026, month: m, netWorth: m * 1000000),
            ],
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(body: NetWorthChart()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final chart = tester.widget<PLineChart>(find.byType(PLineChart));
    expect(chart.categories, [for (var m = 1; m <= 12; m++) '$m월']);
    expect(chart.categories.where((c) => c.startsWith('0')), isEmpty);
  });
}
