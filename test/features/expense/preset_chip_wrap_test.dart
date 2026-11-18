// 거래 폼 금액 프리셋 칩 묶음은 줄을 바꾼다 — chip.md "묶음 배치"(groo-design #254, 사용자 결정).
//
// 폼 · 시트 안의 고르기 묶음은 줄바꿈하고(칩 사이 · 줄 사이 8 — `spacing-between-chips`), 목록 위 필터 바 · 제안 줄만 한
// 줄 가로 스크롤이다. 금액을 줄이지 않아(#252) 칩이 길어지므로 가장 나쁜 값 — 폰 320 · 글자 200%.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_form_parts.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';

ExpenseTemplate _preset(int id, String name, int amount) => ExpenseTemplate(
  rowId: id,
  templateName: name,
  expenseType: 'EXPENSE',
  amount: amount,
  lockAmount: 'Y',
);

void main() {
  tearDown(() => Intl.defaultLocale = null);

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      '320 · 글자 ${(scale * 100).round()}% — 칩이 줄을 바꾸고 칩 사이 · 줄 사이가 8',
      (tester) async {
        Intl.defaultLocale = 'ko';
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            builder: (context, c) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: c!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: TxPresetBlock(
                  presets: [
                    _preset(1, '점심', 12000),
                    _preset(2, '월세', 650000),
                    _preset(3, '통신비', 59000),
                    _preset(4, '커피', 4500),
                  ],
                  categories: const [],
                  appliedId: null,
                  title: '프리셋',
                  onTap: (_) {},
                  onSave: () {},
                  onShowAll: () {},
                  loadFailed: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final block = tester.getRect(
          find.byKey(const ValueKey('tx-preset-chips')),
        );
        final chips = [
          for (final e
              in find
                  .descendant(
                    of: find.byKey(const ValueKey('tx-preset-chips')),
                    matching: find.byType(PChip),
                  )
                  .evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ];
        expect(chips, hasLength(4));
        // 줄로 묶는다(같은 top)
        final rows = <double, List<Rect>>{};
        for (final r in chips) {
          rows.putIfAbsent(r.top, () => []).add(r);
        }
        expect(rows.length, greaterThan(1), reason: '320 폭에 다 들지 않아 줄을 바꾼다');
        final tops = rows.keys.toList()..sort();
        for (var k = 1; k < tops.length; k++) {
          final prevBottom = rows[tops[k - 1]]!
              .map((r) => r.bottom)
              .reduce((a, b) => a > b ? a : b);
          expect(
            tops[k] - prevBottom,
            moreOrLessEquals(PSpacing.betweenChips),
            reason: '줄 사이 8',
          );
        }
        for (final row in rows.values) {
          row.sort((a, b) => a.left.compareTo(b.left));
          for (var k = 1; k < row.length; k++) {
            expect(
              row[k].left - row[k - 1].right,
              moreOrLessEquals(PSpacing.betweenChips),
              reason: '칩 사이 8',
            );
          }
        }
        // 칩은 화면 여백 안 — 줄 밖으로 나가지 않는다
        for (final r in chips) {
          expect(
            r.left,
            greaterThanOrEqualTo(block.left + PSpacing.globalGutter - 0.5),
          );
          expect(
            r.right,
            lessThanOrEqualTo(block.right - PSpacing.globalGutter + 0.5),
          );
        }
      },
    );
  }
}
