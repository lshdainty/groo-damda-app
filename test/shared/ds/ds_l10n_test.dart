// ds 한국어 기본값 → arb(01-043 · 01A-105) — 로케일을 따라 영어로도 나가고, 로케일이 없는 호스트에서는 한국어로 돌아간다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/color_swatch/p_color_swatch.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/p_icon_picker.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';

Future<BuildContext> _ctx(WidgetTester tester, {String? lang}) async {
  late BuildContext out;
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: lang == null
          ? null
          : AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: lang == null ? null : Locale(lang),
      home: Builder(
        builder: (c) {
          out = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return out;
}

void main() {
  testWidgets('영어 — 시간 · 색 · 아이콘 · 날짜 묶음이 영어로 나온다', (tester) async {
    final c = await _ctx(tester, lang: 'en');
    final time = PTimePickerLabels.of(c);
    expect(time.root, 'Select time');
    expect(time.am, 'AM');
    expect(pColorSwatchNamesOf(c).values.first, 'Red');
    final icon = PIconPickerTexts.of(c);
    expect(icon.title, 'Icon');
    expect(icon.emptyTitle('uni'), "No icons for 'uni'");
    expect(icon.countLabel(2), '2 results');
    final date = PDatePickerLabels.of(c);
    expect(date.root, 'Select date');
    // 영어 요일 줄은 두 글자 · 칸에 들지 않으면 한 글자(date-picker.md ⓔ Weekday, groo-design #250)
    expect(date.weekdays.first, 'Su');
    expect(date.weekdaysNarrow?.first, 'S');
    expect(date.weekdaysLong.first, 'Sunday');
    expect(date.day(DateTime(2026, 10, 15)), 'Thursday, Oct 15, 2026');
    expect(date.presetNames[PDatePreset.thisWeek], 'This week');
    expect(
      deltaSentence(
        PDeltaDirection.up,
        '12%',
        'than last month',
        l10n: AppLocalizations.of(c),
      ),
      'than last month 12% increased',
    );
  });

  testWidgets('한국어 — 같은 키가 한국어 문구를 낸다', (tester) async {
    final c = await _ctx(tester, lang: 'ko');
    expect(PTimePickerLabels.of(c).root, '시간 선택');
    expect(pColorSwatchNamesOf(c).values.first, '빨강');
    expect(PIconPickerTexts.of(c).countLabel(2), '검색 결과 2개');
    expect(
      PDatePickerLabels.of(c).day(DateTime(2026, 10, 15)),
      '2026년 10월 15일 목요일',
    );
    expect(
      deltaSentence(
        PDeltaDirection.down,
        '12%',
        '지난달보다',
        l10n: AppLocalizations.of(c),
      ),
      '지난달보다 12% 줄었어요',
    );
  });

  testWidgets('로케일이 없는 호스트는 한국어 기본값으로 돌아간다', (tester) async {
    final c = await _ctx(tester);
    expect(PTimePickerLabels.of(c).root, '시간 선택');
    expect(pColorSwatchNamesOf(c).values.first, '빨강');
    expect(PIconPickerTexts.of(c).title, '아이콘');
    expect(identical(PDatePickerLabels.of(c), PDatePickerLabels.ko), isTrue);
  });
}
