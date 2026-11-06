// I-29 — 날짜 머리 "26. 10. 29(목) · 오늘": 앞 공백도 비분리(U+00A0)라 " · 오늘" 이 따로 줄을 바꾸지 않는다(웹 LedgerDayDate 와 같다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
