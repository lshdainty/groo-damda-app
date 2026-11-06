// 옛 PCalendar 의 막힌 날 (I-04 03-C) — 스펙(date-picker)대로 바탕 없음 + 흐린 숫자 + 취소선.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_calendar.dart';
import '../support/plain_text.dart';

void main() {
  testWidgets('firstDay 앞의 날은 취소선 + fg-disabled, 이후 날은 그대로', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: PCalendar.single(
            selected: null,
            onChanged: (_) {},
            firstDay: DateTime(2026, 10, 10),
            initialMonth: DateTime(2026, 10),
          ),
        ),
      ),
    );
    TextStyle style(String day) => tester
        .widgetList<Text>(findText(day))
        .map((t) => t.style!)
        .firstWhere((s) => s.fontSize != null);
    final blocked = style('9');
    expect(blocked.decoration, TextDecoration.lineThrough);
    expect(blocked.color, PColors.light.fgDisabled);
    final open = style('15');
    expect(open.decoration, TextDecoration.none);
    expect(open.color, isNot(PColors.light.fgDisabled));
  });
}
