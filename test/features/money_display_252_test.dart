// 돈 표기 · 요일 글 상한 — groo-design #252(international-design.mdx · date-picker.md, 사용자 결정).
//
// ⓐ 요일 줄 글자 크기는 200% 에서 멈춘다(기간 시트 · 달력 탭 · 가계부 달력) — 300% 에서도 한 줄 · 칸 안. 날짜 숫자는 그대로 커진다
// ⓑ 금액 프리셋 칩은 줄이지 않는다 — "12,000원" · "₩12,000"
// ⓒ 규모 값(시가총액 · 주식 수)만 줄인다 — 차트 축과 같은 셈(한 단위 · 소수 한 자리, 조 · 억 · 만 / T · B · M · K)
// ⓓ 문장 속 돈은 영어도 ₩ — 영어 ARB 에 "won" 이 없다
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_form_parts.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart'
    show fmtCapKrw, fmtShares;
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';

import '../support/plain_text.dart';

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  double scale = 1,
}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

const _two = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
const _one = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// [of] 안의 요일 글 — 한 줄 · 칸 안 · 글자 배율 200% 이하인지 보고 보인 글을 돌려준다.
List<String> _weekdays(WidgetTester tester, Finder of) {
  final out = <String>[];
  for (final e
      in find.descendant(of: of, matching: find.byType(Text)).evaluate()) {
    final t = plainOf((e.widget as Text).data ?? '');
    if (!_two.contains(t) && !_one.contains(t)) continue;
    out.add(t);
    final p = tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byWidget(e.widget),
            matching: find.byType(RichText),
          )
          .first,
    );
    expect(
      p.textScaler.scale(10),
      lessThanOrEqualTo(20.0 + 1e-6),
      reason: '요일 "$t" 글자 크기가 200% 를 넘는다',
    );
    final one = TextPainter(
      text: p.text,
      textScaler: p.textScaler,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    expect(
      p.size.height,
      moreOrLessEquals(one.height, epsilon: 0.5),
      reason: '요일 "$t" 이 줄을 바꾼다',
    );
    expect(
      one.width,
      lessThanOrEqualTo(tester.getRect(find.byWidget(e.widget)).width + 0.5),
      reason: '요일 "$t" 이 칸보다 넓다',
    );
    one.dispose();
  }
  return out;
}

void _viewport(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  tearDown(() => Intl.defaultLocale = null);

  group('ⓐ 요일 줄 글자 크기 200% 상한 — 320 · 300% 에서도 한 줄 · 칸 안', () {
    setUp(() => Intl.defaultLocale = 'en');

    for (final scale in [2.0, 3.0]) {
      testWidgets('기간 시트 달력 · 글자 ${(scale * 100).round()}%', (tester) async {
        _viewport(tester, 320);
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 320,
              child: Builder(
                builder: (context) => PDatePicker.single(
                  labels: PDatePickerLabels.of(context),
                  today: DateTime(2026, 10, 15),
                ),
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          _weekdays(tester, find.byKey(const ValueKey('date-weekdays'))),
          _one,
        );
        // 날짜 숫자는 그대로 커진다
        final day = tester.renderObject<RenderParagraph>(
          find
              .descendant(
                of: find.byKey(const ValueKey('date-2026-10-15')),
                matching: find.byType(RichText),
              )
              .first,
        );
        expect(day.textScaler.scale(10), moreOrLessEquals(10 * scale));
      });

      testWidgets('달력 탭 요일 줄 · 글자 ${(scale * 100).round()}%', (tester) async {
        _viewport(tester, 320);
        await tester.pumpWidget(
          _app(
            const SizedBox(width: 320, child: CalendarWeekdayRow()),
            scale: scale,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(_weekdays(tester, find.byType(CalendarWeekdayRow)), _one);
      });

      testWidgets('가계부 달력 요일 줄 · 글자 ${(scale * 100).round()}%', (tester) async {
        _viewport(tester, 320);
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 320,
              child: LedgerCalendarGrid(
                month: DateTime(2026, 10),
                selected: '2026-10-15',
                expanded: true,
                onSelect: (_) {},
                onToggleExpand: () {},
                markBuilder: (context, ds) => const SizedBox.shrink(),
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(_weekdays(tester, find.byType(LedgerCalendarGrid)), _one);
      });
    }
  });

  group('ⓑ 금액 프리셋 칩 — 줄이지 않는다', () {
    const preset = ExpenseTemplate(
      rowId: 7,
      templateName: '점심',
      expenseType: 'EXPENSE',
      amount: 12000,
      lockAmount: 'Y',
    );
    for (final (locale, text) in [
      (const Locale('ko'), '점심  12,000원'),
      (const Locale('en'), '점심  ₩12,000'),
    ]) {
      testWidgets('${locale.languageCode} — "$text"', (tester) async {
        Intl.defaultLocale = locale.languageCode;
        _viewport(tester, 360);
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 360,
              child: TxPresetBlock(
                presets: const [preset],
                categories: const [],
                appliedId: null,
                title: 'Presets',
                onTap: (_) {},
                onSave: () {},
                onShowAll: () {},
                loadFailed: false,
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pump();
        expect(findText(text), findsOneWidget);
        expect(findTextContaining(RegExp(r'1\.2(만|K)')), findsNothing);
      });
    }
  });

  group('ⓒ 규모 값 줄임 — 차트 축과 같은 셈', () {
    test('영어 T · B · M · K — 한 단위 · 소수 한 자리', () {
      Intl.defaultLocale = 'en';
      expect(formatChartAxis(999), '999');
      expect(formatChartAxis(1000), '1K');
      expect(formatChartAxis(1234), '1.2K', reason: 'compact 의 1.23K 가 아니다');
      expect(formatChartAxis(999949), '999.9K');
      expect(formatChartAxis(999999), '1M', reason: '1,000K 가 아니라 1M');
      expect(formatChartAxis(1.2e9), '1.2B');
      expect(formatChartAxis(1.2e12), '1.2T');
      expect(formatChartAxis(-5200000), '−5.2M');
      expect(fmtCapKrw(1.2e12), '₩1.2T');
      expect(fmtShares(5.9e8), '590M');
    });

    test('한국어 조 · 억 · 만 그대로', () {
      Intl.defaultLocale = 'ko';
      expect(formatChartAxis(9999), '9,999');
      expect(formatChartAxis(12000), '1.2만');
      expect(formatChartAxis(99999999), '1억');
      expect(formatChartAxis(1.2e12), '1.2조');
      expect(fmtCapKrw(1.2e12), '1.2조원');
    });
  });

  test('ⓓ 영어 ARB 에 "won" 이 없다 — 문장 속 돈은 ₩', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final ko =
        jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
            as Map<String, dynamic>;
    final won = RegExp(r"\bwon\b(?!')"); // won't 는 다른 낱말
    final hits = [
      for (final e in en.entries)
        if (!e.key.startsWith('@') &&
            e.value is String &&
            won.hasMatch(e.value))
          '${e.key}: ${e.value}',
    ];
    expect(hits, isEmpty);
    // 한국어가 "{금액}원" 인 문장은 영어도 "₩{금액}"
    final missing = <String>[];
    for (final e in ko.entries) {
      if (e.key.startsWith('@') || e.value is! String) continue;
      for (final m in RegExp(r'\{(\w+)\}\s?원').allMatches(e.value)) {
        if (!(en[e.key] as String).contains('₩{${m.group(1)}}')) {
          missing.add('${e.key}: ${en[e.key]}');
        }
      }
    }
    expect(missing, isEmpty);
    expect(en['amountTooLarge'], 'Amount can be up to ₩10,000,000,000.');
  });
}
