// 시각 시트는 1분 간격이다(사용자 결정 2026-11-10 — 카드 결제 시각을 정확히 넣는다). 거래 · 일정 · 반복 · 알림이 같은 시트를 쓴다.
// 열 때 지금 시각은 반올림 없이 그대로 짚는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/forms/time_sheet.dart';
import '../../support/plain_text.dart';

Future<void> _open(WidgetTester tester, PTimeValue value) async {
  tester.view.physicalSize = const Size(1170, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showTimeSheet(ctx, title: '시각', value: value),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('시각 휠 기본 간격은 1분이다', () {
    expect(const PTimePicker().minuteStep, 1);
  });

  testWidgets('시트의 분 휠은 60칸이고 13분을 5분으로 반올림하지 않는다', (tester) async {
    await _open(tester, const PTimeValue(21, 13));
    final picker = tester.widget<PTimePicker>(find.byType(PTimePicker));
    expect(picker.minuteStep, 1);
    expect(picker.value, const PTimeValue(21, 13));
    // 분 칼럼 읽는 값이 "13"
    expect(find.bySemanticsLabel('분'), findsWidgets);
    expect(findText('13'), findsWidgets);
    expect(findText('14'), findsWidgets);
  });
}
