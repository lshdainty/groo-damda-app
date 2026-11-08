// 분담 몫은 소수 한 자리(B6 나.6) — "33%" 가 "33.3%" 가 되어 PTag 가 넓어져도 줄 안에서 넘치지 않는다.
// 거래 상세 분할 줄(TxSplitSection)을 폭 360 · 글자 100% / 200% 로 재서 오버플로 0 과 PTag 폭을 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart';
import 'package:groo_damda_app/features/expense_split/domain/expense_split.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';

const _cats = [
  ExpenseCategory(rowId: 1, categoryName: '식비'),
  ExpenseCategory(rowId: 2, categoryName: '카페·간식·디저트', parentRowId: 1),
];

ExpenseSplit _s(int id, int amount) => ExpenseSplit(
  rowId: id,
  expenseRowId: 9,
  categoryRowId: 2,
  categoryName: '카페·간식·디저트',
  amount: amount,
);

Future<void> _pump(
  WidgetTester tester,
  List<ExpenseSplit> splits,
  int total,
  double scale,
) async {
  tester.view.physicalSize = Size(360 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3;
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
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: TxSplitSection(
            splits: splits,
            categories: _cats,
            total: total,
            isIncome: false,
            masked: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('몫 글은 소수 한 자리다 — 33.3% · 66.7% · 100.0% · 0.1% 미만', (
    tester,
  ) async {
    await _pump(tester, [_s(1, 1000), _s(2, 2000)], 3000, 1);
    expect(find.text('33.3%'), findsOneWidget);
    expect(find.text('66.7%'), findsOneWidget);
    await _pump(tester, [_s(1, 3000)], 3000, 1);
    expect(find.text('100.0%'), findsOneWidget);
    await _pump(tester, [_s(1, 1), _s(2, 9999999)], 10000000, 1);
    expect(find.text('0.1% 미만'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('폭 360 · 글자 ${scale * 100}% — 넘침 0, PTag 폭을 잰다', (
      tester,
    ) async {
      for (final (label, splits, total) in [
        ('33.3%', [_s(1, 1000), _s(2, 2000)], 3000),
        ('100.0%', [_s(1, 3000)], 3000),
        ('0.1% 미만', [_s(1, 1), _s(2, 9999999)], 10000000),
      ]) {
        await _pump(tester, splits, total, scale);
        expect(tester.takeException(), isNull, reason: '$label $scale');
        final tag = find.text(label).first;
        final group = find.byType(PTagGroup).first;
        final tw = tester.getSize(tag).width;
        final gw = tester.getSize(group).width;
        // ignore: avoid_print
        print(
          'MEASURE scale=$scale "$label" tagText=${tw.toStringAsFixed(1)} group=${gw.toStringAsFixed(1)}',
        );
        expect(tw, lessThanOrEqualTo(gw), reason: '$label 글 폭 $tw ≤ 묶음 폭 $gw');
      }
    });
  }
}
