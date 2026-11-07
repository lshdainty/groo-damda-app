// 날짜 규칙(DESIGN.md 날짜 · 요일, I-wrap-b3 가.5) — 앞 0 을 채우지 않고, 요일은 괄호, 기간은 "~".
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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

  group('영어 — 구간은 en dash(로케일 문구), 점 표기는 한국어 전용', () {
    late String? prev;
    setUp(() {
      prev = Intl.defaultLocale;
      Intl.defaultLocale = 'en';
    });
    tearDown(() => Intl.defaultLocale = prev);

    test('기간 줄 — Nov 2–8 · Nov 2–Dec 1 · 해가 섞이면 연도', () {
      final y = DateTime.now().year;
      expect(dateRange(DateTime(y, 11, 2), DateTime(y, 11, 8)), 'Nov 2–8');
      expect(dateRange(DateTime(y, 11, 2), DateTime(y, 12, 1)), 'Nov 2–Dec 1');
      expect(
        dateRange(DateTime(y - 1, 12, 29), DateTime(y, 1, 4)),
        'Dec 29, ${y - 1}–Jan 4, $y',
      );
    });

    test('월 눈금 · 마감 — "Jan" / "Dec 2025 · Jan 2026"(점 표기 없음)', () {
      expect(monthLabels([(year: 2026, month: 1), (year: 2026, month: 12)]), [
        'Jan',
        'Dec',
      ]);
      expect(monthLabels([(year: 2025, month: 12), (year: 2026, month: 1)]), [
        'Dec 2025',
        'Jan 2026',
      ]);
      expect(yearMonthDot(DateTime(2026, 1)), 'Jan 2026');
    });
  });

  test('통계 직접 기간 이름 — 올해는 "10월 29일~11월 7일", 다른 해는 양끝 연도(앞 0 · 슬래시 없음)', () {
    final y = DateTime.now().year;
    expect(
      StatsPeriod(
        seg: StatsSeg.custom,
        from: DateTime(y, 10, 29),
        to: DateTime(y, 11, 7),
      ).label(),
      '10월 29일~11월 7일',
    );
    expect(
      StatsPeriod(
        seg: StatsSeg.custom,
        from: DateTime(y - 1, 12, 29),
        to: DateTime(y, 1, 7),
      ).label(),
      '${y - 1}년 12월 29일~$y년 1월 7일',
    );
  });

  group('요일 · 시각 — 할 일 상세 완료 시각(DESIGN.desk.md:3605)', () {
    // 서버 [UTC] 값 -> 로컬. 기대값은 로컬 시계에서 독립적으로 조립한다.
    String ko(DateTime u) {
      final d = u.toLocal();
      final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final mm = d.minute.toString().padLeft(2, '0');
      final yr = d.year == DateTime.now().year ? '' : '${d.year}년 ';
      return '$yr${d.month}월 ${d.day}일 (${_dow(d)}) '
          '${d.hour < 12 ? '오전' : '오후'} $h12:$mm';
    }

    String iso(DateTime u) => u.toIso8601String().replaceFirst('Z', '');
    final thisYear = DateTime.utc(DateTime.now().year, 6, 15, 12, 5);
    final otherYear = DateTime.utc(2020, 11, 7, 0, 5);

    test('한국어 올해 · 다른 해', () {
      expect(formatDayDowTime(iso(thisYear)), ko(thisYear));
      expect(formatDayDowTime(iso(otherYear)), ko(otherYear));
      expect(formatDayDowTime(iso(otherYear)), startsWith('2020년 '));
      expect(formatDayDowTime(iso(thisYear)), isNot(contains('년')));
      expect(formatDayDowTime(iso(thisYear)), isNot(contains('-')));
    });

    test('영어 올해 "Sat, Nov 7 at 9:05 AM" 꼴 · 다른 해는 연도', () {
      final prev = Intl.defaultLocale;
      Intl.defaultLocale = 'en';
      addTearDown(() => Intl.defaultLocale = prev);
      expect(
        formatDayDowTime(iso(thisYear)),
        matches(
          RegExp(r'^[A-Z][a-z]{2}, [A-Z][a-z]{2} \d{1,2} at \d{1,2}:05 [AP]M$'),
        ),
      );
      expect(
        formatDayDowTime(iso(otherYear)),
        matches(
          RegExp(
            r'^[A-Z][a-z]{2}, [A-Z][a-z]{2} \d{1,2}, 2020 at \d{1,2}:05 [AP]M$',
          ),
        ),
      );
    });

    test('못 읽는 값 · 날짜만 있는 값은 null', () {
      expect(formatDayDowTime(null), isNull);
      expect(formatDayDowTime('알 수 없음'), isNull);
      expect(formatDayDowTime('2026-08-24'), isNull);
    });
  });

  test('좁은 칸 월 · 일 — 점 표기 "10. 29."(슬래시 · 앞 0 없음), 영어 "Oct 29"', () {
    expect(monthDayDot(DateTime(2026, 10, 29)), '10. 29.');
    expect(monthDayDot(DateTime(2026, 9, 7)), '9. 7.');
    final prev = Intl.defaultLocale;
    Intl.defaultLocale = 'en';
    addTearDown(() => Intl.defaultLocale = prev);
    expect(monthDayDot(DateTime(2026, 10, 29)), 'Oct 29');
  });

  test('월 눈금 — 해가 섞이면 해를 붙인다(순자산 추이도 같은 규칙)', () {
    expect(monthTicks([(year: 2025, month: 12), (year: 2026, month: 1)]), [
      '2025. 12.',
      '2026. 1.',
    ]);
  });

  for (final (title, pts, want) in [
    (
      '순자산 추이 x 눈금 — "1월" … "12월"(앞 0 없음)',
      [for (var m = 1; m <= 12; m++) (2026, m)],
      [for (var m = 1; m <= 12; m++) '$m월'],
    ),
    (
      '순자산 추이 x 눈금 — 해를 넘으면 해를 붙인다(통계와 같은 규칙)',
      [(2025, 11), (2025, 12), (2026, 1)],
      ['2025. 11.', '2025. 12.', '2026. 1.'],
    ),
  ]) {
    testWidgets(title, (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hideCardsRepositoryProvider.overrideWith(
              (ref) async => OkHideCardsRepository(),
            ),
            netWorthTrendProvider.overrideWith(
              (ref, months) async => [
                for (final (y, m) in pts)
                  NetWorthPoint(year: y, month: m, netWorth: m * 1000000),
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
      expect(chart.categories, want);
    });
  }
}
