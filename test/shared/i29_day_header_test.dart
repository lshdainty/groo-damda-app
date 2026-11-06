// I-29 — 날짜 머리 "10월 29일 (목) · 오늘": 앞 공백도 비분리(U+00A0)라 " · 오늘" 이 따로 줄을 바꾸지 않는다(웹 LedgerDayDate 와 같다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import '../support/plain_text.dart';

void main() {
  testWidgets('오늘 머리 — 점 앞뒤가 비분리 공백이라 쪼개지지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: PDayHeader(
            date: DateTime.now(),
            items: const [],
            flags: MaskFlags.cardOnly(false),
          ),
        ),
      ),
    );
    final text = tester
        .widgetList<Text>(findTextContaining('·'))
        .map((t) => t.data!)
        .first;
    expect(text, contains(' · '));
    expect(text, isNot(contains(' · ')), reason: '보통 공백이면 점 앞에서 줄이 바뀐다');
  });

  group('날짜 규칙(DESIGN "날짜" 표 — 요일) — 올해 M월 d일 (E) · 다른 해 표준 · 영어 E, MMM d', () {
    Future<String> headOf(
      WidgetTester tester,
      DateTime d, {
      String lang = 'ko',
    }) async {
      final before = Intl.defaultLocale;
      Intl.defaultLocale = lang;
      addTearDown(() => Intl.defaultLocale = before);
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(lang),
          home: Scaffold(
            body: PDayHeader(
              date: d,
              items: const [],
              flags: MaskFlags.cardOnly(false),
            ),
          ),
        ),
      );
      final t = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(PDayHeader),
              matching: find.byType(Text),
            )
            .first,
      );
      return t.data!;
    }

    final now = DateTime.now();
    // 오늘 · 어제가 아닌 올해 날 — 1월 1 · 2일은 오늘 · 어제일 수 있어 비켜 간다
    final thisYear = now.month == 1 && now.day <= 3
        ? DateTime(now.year, 6, 15)
        : DateTime(now.year, 1, 1);

    testWidgets('올해 — "M월 d일 (E)"', (tester) async {
      final dow = ['일', '월', '화', '수', '목', '금', '토'][thisYear.weekday % 7];
      expect(
        await headOf(tester, thisYear),
        '${thisYear.month}월 ${thisYear.day}일 ($dow)',
      );
    });

    testWidgets('다른 해 — "2025년 10월 25일 (토)"', (tester) async {
      expect(await headOf(tester, DateTime(2025, 10, 25)), '2025년 10월 25일 (토)');
    });

    testWidgets('오늘 · 어제 — 붙임 그대로(비분리 공백)', (tester) async {
      final y = now.subtract(const Duration(days: 1));
      final dow = ['일', '월', '화', '수', '목', '금', '토'];
      expect(
        await headOf(tester, now),
        '${now.month}월 ${now.day}일 (${dow[now.weekday % 7]})\u00A0·\u00A0오늘',
      );
      final yd = y.year == now.year
          ? '${y.month}월 ${y.day}일'
          : '${y.year}년 ${y.month}월 ${y.day}일';
      expect(
        await headOf(tester, y),
        '$yd (${dow[y.weekday % 7]})\u00A0·\u00A0어제',
      );
    });

    testWidgets('영어 — "E, MMM d"', (tester) async {
      expect(
        await headOf(tester, thisYear, lang: 'en'),
        DateFormat('E, MMM d', 'en').format(thisYear),
      );
      expect(
        await headOf(tester, DateTime(2025, 10, 25), lang: 'en'),
        'Sat, Oct 25, 2025',
      );
    });
  });
}
