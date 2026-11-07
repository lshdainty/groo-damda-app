// B5-6 — 누르는 영역 44 실측(실제 hit-test). 줄은 "측정표" 로 출력하고 44 미만이면 실패한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hit_probe.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

Widget _app(Widget body) => MaterialApp(
  theme: GrooTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: body),
    ),
  ),
);

final _rows = <String>[];

void main() {
  tearDownAll(() => print(_rows.join('\n'))); // ignore: avoid_print

  Future<void> check(
    WidgetTester tester,
    String name,
    Widget body,
    Finder target,
  ) async {
    await tester.pumpWidget(_app(body));
    await tester.pumpAndSettle();
    final s = hitSize(tester, target);
    _rows.add(
      '$name | ${s.width.toStringAsFixed(0)}x${s.height.toStringAsFixed(0)}',
    );
    expect(s.height, greaterThanOrEqualTo(44), reason: name);
  }

  testWidgets('가계부 월 줄 — 달 글 없는 줄의 거르기 · 추가 단추', (t) async {
    await check(
      t,
      'LedgerMonthNav(showMonth:false) 추가 단추',
      LedgerMonthNav(
        label: '2026년 11월',
        showMonth: false,
        onPick: () {},
        onOpenFilter: () {},
        onAddTx: () {},
      ),
      find.byIcon(Icons.add).evaluate().isEmpty
          ? find.bySemanticsLabel('거래 추가').first
          : find.byIcon(Icons.add),
    );
  });

  testWidgets('소비 요약 토글', (t) async {
    await check(
      t,
      'LedgerTotalRow 소비 요약',
      LedgerTotalRow(
        total: '1,234,000원',
        insight: null,
        summaryOpen: false,
        onToggleSummary: () {},
      ),
      find.byType(PButton),
    );
  });

  testWidgets('종목 찾기 입구', (t) async {
    await check(
      t,
      'StocksSearchEntry',
      StocksSearchEntry(onTap: () {}),
      find.byKey(const ValueKey('stocks-search-entry')),
    );
  });
}
