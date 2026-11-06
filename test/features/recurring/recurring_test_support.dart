import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/plain_text.dart';

// 줄 안 글에 끼는 보이지 않는 글자(낱말 이음 · 쉼표 뒤 줄바꿈 · 자리 표시)를 빼고 반복 줄 설명의 줄바꿈 없는 공백(recNoBreak
// U+00A0)은 보통 공백으로 — 공용 support/plain_text.dart 의 plainOf 를 쓴다.
export '../../support/plain_text.dart' show plainOf;

/// 보이는 글이 [s] 와 **같은** 글 — 낱말 이음 문자가 끼어 있어도 찾는다.
Finder plain(String s) => find.byWidgetPredicate(
  (w) => w is RichText && plainOf(w.text.toPlainText()) == plainOf(s),
);

/// 보이는 글이 [s] 로 **시작하는** 글.
Finder plainStarts(String s) => find.byWidgetPredicate(
  (w) => w is RichText && plainOf(w.text.toPlainText()).startsWith(plainOf(s)),
);

RecurringTransaction rec(
  int id,
  String name,
  int amount, {
  String type = 'EXPENSE',
  String freq = 'MONTHLY',
  int? dow,
  int? dom = 25,
  String start = '2026-01-25',
  String? next = '2026-11-25',
  String? end,
  int? max,
  int executed = 9,
  String active = 'Y',
  bool auto = true,
  int category = 2,
}) => RecurringTransaction(
  rowId: id,
  categoryRowId: type == 'TRANSFER' ? 0 : category,
  assetRowId: 1,
  assetName: '주거래',
  expenseType: type,
  amount: amount,
  merchant: name,
  frequency: freq,
  intervalValue: 1,
  dayOfWeek: dow,
  dayOfMonth: dom,
  executionTime: '09:00:00',
  startDate: start,
  endDate: end,
  maxOccurrences: max,
  executedCount: executed,
  nextExecutionDate: next,
  isActive: active,
  autoLog: auto,
);

Future<void> pumpApp(
  WidgetTester tester,
  Widget home,
  List<Override> overrides,
) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, ch) => PSnackbarHost(closeLabel: '닫기', child: ch!),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
