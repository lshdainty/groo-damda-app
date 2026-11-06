// 통계 기간 시트(I-28 28-2) — ds Date Picker 기간: 칸 하나(시작 · 끝 두 칸 없음) · 빠른 기간 칩 · 바닥 "초기화" + "완료".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_range_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/widgets/p_date_input.dart';
import '../../support/plain_text.dart';

final _today = DateTime(2026, 10, 29, 13);

Future<void> _open(
  WidgetTester tester,
  StatsPeriod current,
  void Function(StatsPeriod?) onResult,
) async {
  tester.view.physicalSize = const Size(780, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await showStatsRangeSheet(context, current, today: _today),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

Finder _done() => find.widgetWithText(PButton, '완료');

void main() {
  final month = StatsPeriod.thisMonth(_today);

  group('statsPeriodOfRange', () {
    StatsPeriod pick(DateTime f, DateTime t) => statsPeriodOfRange(month, f, t);

    test('바뀐 게 없으면 지금 값 그대로(구분을 잃지 않는다)', () {
      expect(identical(pick(month.from, month.to), month), isTrue);
    });
    test('달력 달 · 분기 · 해 하나를 정확히 덮으면 그 보기 — 지난 기간도', () {
      expect(
        pick(DateTime(2026, 9), DateTime(2026, 9, 30)).seg,
        StatsSeg.month,
      );
      expect(
        pick(DateTime(2026, 7), DateTime(2026, 9, 30)).seg,
        StatsSeg.quarter,
      );
    });
    test('분기 · 해 · 윤달 경계', () {
      expect(pick(DateTime(2026), DateTime(2026, 12, 31)).seg, StatsSeg.year);
      expect(
        pick(DateTime(2024, 2), DateTime(2024, 2, 29)).seg,
        StatsSeg.month,
      );
      // 2월부터 석 달은 분기가 아니다
      expect(
        pick(DateTime(2026, 2), DateTime(2026, 4, 30)).seg,
        StatsSeg.custom,
      );
    });
    test('아무 기간은 직접', () {
      expect(
        pick(DateTime(2026, 10, 3), DateTime(2026, 10, 9)).seg,
        StatsSeg.custom,
      );
      expect(
        pick(DateTime(2026, 9), DateTime(2026, 10, 31)).seg,
        StatsSeg.custom,
      );
    });
  });

  group('기간 이름 — 오늘을 품으면 상대 말, 아니면 실제 이름', () {
    final l = lookupAppLocalizations(const Locale('ko'));
    StatsPeriod pick(DateTime f, DateTime t) => statsPeriodOfRange(month, f, t);

    test('이번 달 → 이번 달 / 지난 달', () {
      final p = pick(DateTime(2026, 10), DateTime(2026, 10, 31));
      expect(p.now(l, _today), '이번 달');
      expect(p.previous(l, _today), '지난 달');
    });
    test('지난 달 → 2026년 9월 / 2026년 8월', () {
      final p = pick(DateTime(2026, 9), DateTime(2026, 9, 30));
      expect(p.now(l, _today), '2026년 9월');
      expect(p.previous(l, _today), '2026년 8월');
    });
    test('7/1~9/30 → 2026년 3분기 / 2026년 2분기', () {
      final p = pick(DateTime(2026, 7), DateTime(2026, 9, 30));
      expect(p.now(l, _today), '2026년 3분기');
      expect(p.previous(l, _today), '2026년 2분기');
    });
    test('오늘이 든 해 → 올해 / 작년 · 지난 해 → 2025년 / 2024년', () {
      final y = pick(DateTime(2026), DateTime(2026, 12, 31));
      expect(y.now(l, _today), '올해');
      expect(y.previous(l, _today), '작년');
      final old = pick(DateTime(2025), DateTime(2025, 12, 31));
      expect(old.now(l, _today), '2025년');
      expect(old.previous(l, _today), '2024년');
    });
    test('영어 — 올해 칸 이름은 This year / Last year, 문장 안은 소문자', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final y = pick(DateTime(2026), DateTime(2026, 12, 31));
      expect(y.now(en, _today), 'This year');
      expect(y.previous(en, _today), 'Last year');
      expect(en.statsMomMonth('last month'), 'vs. last month');
      expect(
        lookupAppLocalizations(const Locale('ko')).statsMomMonth('2026년 8월'),
        '2026년 8월 대비',
      );
      expect(
        en.statsTooFewTx('this month'),
        'Too few transactions in this month',
      );
    });
    test('직접은 그대로', () {
      final p = pick(DateTime(2026, 10, 3), DateTime(2026, 10, 9));
      expect(p.now(l, _today), '선택 기간');
      expect(p.previous(l, _today), '이전 기간');
    });
  });

  group('showStatsRangeSheet', () {
    testWidgets('칸 하나 — 날짜 입력칸 두 개와 월 · 분기 · 년 · 직접 탭이 없다', (tester) async {
      await _open(tester, month, (_) {});
      expect(find.byType(PDatePicker), findsOneWidget);
      expect(find.byType(PDateInput), findsNothing);
      expect(findText('분기'), findsNothing);
      expect(findText('직접'), findsNothing);
    });

    testWidgets('빠른 기간 칩 다섯(내보내기 시트와 같게) · 바닥 "초기화" + "완료"', (tester) async {
      await _open(tester, month, (_) {});
      for (final n in ['이번 주', '이번 달', '지난 달', '최근 3개월', '올해']) {
        expect(findText(n), findsOneWidget, reason: n);
      }
      expect(find.widgetWithText(PButton, '초기화'), findsOneWidget);
      expect(_done(), findsOneWidget);
    });

    testWidgets('초기화하면 완료가 막힌다 · 칩 지난 달 → 월 보기', (tester) async {
      StatsPeriod? got;
      await _open(tester, month, (p) => got = p);
      expect(tester.widget<PButton>(_done()).onPressed, isNotNull);
      await tester.tap(find.widgetWithText(PButton, '초기화'));
      await tester.pumpAndSettle();
      expect(tester.widget<PButton>(_done()).onPressed, isNull);
      await tester.tap(findText('지난 달'));
      await tester.pumpAndSettle();
      await tester.tap(_done());
      await tester.pumpAndSettle();
      // 지난 달 칩 → 9월 월 보기, 이전 기간 비교는 그 전달(8월)
      expect(got!.seg, StatsSeg.month);
      expect(got!.from, DateTime(2026, 9));
      expect(got!.to, DateTime(2026, 9, 30));
      expect(got!.prev.from, DateTime(2026, 8));
      expect(got!.prev.to, DateTime(2026, 8, 31));
    });

    testWidgets('완료 없이 닫으면 null — 고르던 것은 버린다', (tester) async {
      StatsPeriod? got = month;
      await _open(tester, month, (p) => got = p);
      await tester.tap(findText('지난 달'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(got, isNull);
    });
  });
}
