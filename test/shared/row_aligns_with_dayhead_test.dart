// 거래 행이 **날짜 헤더와 같은 지점에서 시작**하는지 고정한다
// (사용자 신고 2026-09-14 — 헤더 24 / 행 34 로 목록 전체가 오른쪽으로 밀려 보였다).
//
// 웹은 이 결정을 2026-08-19 에 했다 — `porest-desk-front` f8899d6
// "fix(ledger): 거래 행이 날짜 헤더와 같은 지점에서 시작하도록".
// 앱에는 한동안 행 위젯이 둘이었고(가계부용 ExpenseRow / 공용 PExpenseRow),
// 이 결정이 가계부 쪽에만 들어가 있었다. 지금은 **하나로 합쳤다** — 가계부 ·
// 검색 · 거래상세 · 홈이 모두 ExpenseRow 를 쓴다.
//
// 로딩 자리표시(PDayGroupSkeleton)는 처음부터 0 이었다. 그래서 10 인 채로 두면
// 데이터가 오는 순간 행이 10 튄다 — 그쪽 주석이 "실제 행과 같은 여백" 이라고
// 적고 있었는데 사실이 아니었다. 셋을 한 자리에서 같이 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import '../support/plain_text.dart';

const _pagePad = 24.0;

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}:00';

Expense _e({String type = 'EXPENSE', DateTime? date, int amount = 3000}) =>
    Expense(
      rowId: 1,
      expenseType: type,
      amount: amount,
      expenseDate: date == null ? '2026-09-12T11:20:00' : _iso(date),
      merchant: '스타벅스',
      categoryName: '식비',
      assetName: '신한카드',
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Padding(
          // 좌우 여백은 목록(페이지)이 쥔다 — 행은 여기에 더 얹지 않는다.
          padding: const EdgeInsets.symmetric(horizontal: _pagePad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [child],
          ),
        ),
      ),
    ),
  );
  // 스켈레톤 셔머는 끝나지 않으므로 pumpAndSettle 을 쓰지 않는다.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// 행 안 앞 타일(ds `PListTile` 40 × 40) — 그 왼쪽이 행의 시작점이다.
double _contentLeft(WidgetTester tester, Finder row) => tester
    .getRect(find.descendant(of: row, matching: find.byType(PListTile)).first)
    .left;

void main() {
  testWidgets('날짜 헤더와 행이 같은 지점에서 시작한다', (tester) async {
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PDayHeader(
            date: DateTime(2026, 9, 12),
            items: [_e()],
            flags: const MaskFlags.cardOnly(false),
            gutter: 0,
          ),
          ExpenseRow(
            gutter: 0,
            expense: _e(),
            category: null,
            flags: const MaskFlags.cardOnly(false),
          ),
        ],
      ),
    );
    final head = tester.getRect(findTextContaining('26. 9. 12')).left;
    expect(head, closeTo(_pagePad, 0.5));
    // 고치기 전에는 34 였다(= 24 + 행이 얹던 10).
    expect(_contentLeft(tester, find.byType(ExpenseRow)), closeTo(head, 0.5));
  });

  testWidgets('스켈레톤도 같은 지점 — 데이터가 와도 행이 안 튄다', (tester) async {
    await _pump(tester, const PDayGroupSkeleton(rows: 2, gutter: 0));
    final skeletonRow = tester
        .getRect(
          find
              .descendant(
                of: find.byType(PDayGroupSkeleton),
                matching: find.byType(Row),
              )
              .last,
        )
        .left;
    expect(skeletonRow, closeTo(_pagePad, 0.5));
  });

  testWidgets('행 금액 색 — 지출은 fg-neutral, 수입만 fg-brand (list.md D1)', (
    tester,
  ) async {
    final colors = <String, Color?>{};
    for (final type in ['EXPENSE', 'INCOME']) {
      await _pump(
        tester,
        ExpenseRow(
          gutter: 0,
          expense: _e(type: type),
          category: null,
          flags: const MaskFlags.cardOnly(false),
        ),
      );
      colors[type] = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(ExpenseRow),
              matching: find.byWidgetPredicate(
                (w) => w is Text && plainOf(w.data ?? '').endsWith('원'),
              ),
            ),
          )
          .style
          ?.color;
    }
    // 테스트 테마는 다크 — 역할 색으로 비교한다
    expect(colors['EXPENSE'], PColors.dark.fgNeutral);
    expect(colors['INCOME'], PColors.dark.fgBrand);
  });

  testWidgets('예정(미래) 거래 — 줄 전체를 흐리지 않고 제목 · 금액만 fg-neutral-subtle', (
    tester,
  ) async {
    // list.md "합계에 안 드는 줄" — 불투명도(0.6)를 걷고 배지가 말한다. 지나간 거래는 보통 색이다.
    final past = DateTime.now().subtract(const Duration(days: 1));
    final future = DateTime.now().add(const Duration(days: 3));
    Color? amountColor(WidgetTester t) => t
        .widget<Text>(
          find.descendant(
            of: find.byType(ExpenseRow),
            matching: find.byWidgetPredicate(
              (w) => w is Text && plainOf(w.data ?? '').endsWith('원'),
            ),
          ),
        )
        .style
        ?.color;

    await _pump(
      tester,
      ExpenseRow(
        gutter: 0,
        expense: _e(date: past),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    expect(amountColor(tester), PColors.dark.fgNeutral);

    await _pump(
      tester,
      ExpenseRow(
        gutter: 0,
        expense: _e(date: future),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    expect(amountColor(tester), PColors.dark.fgNeutralSubtle);
    expect(
      find.descendant(
        of: find.byType(ExpenseRow),
        matching: find.byType(Opacity),
      ),
      findsNothing,
      reason: '줄 전체를 흐리면 배지까지 흐려진다',
    );
  });

  testWidgets('행 금액의 마이너스는 U+2212 — 헤더 합계와 같은 기호다', (tester) async {
    // NumberFormat 이 음수에 찍는 ASCII 하이픈은 U+2212 와 폭이 달라, 같은 카드
    // 안에서 섞이면 tabular figures 정렬이 어긋난다(QA #22 가 잡았던 자리).
    // 행은 오래 ASCII 를 쓰고 있었는데, 헤더 합계만 손으로 U+2212 를 붙여
    // 가계부 목록이 내내 두 기호를 섞고 있었다.
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PDayHeader(
            date: DateTime(2026, 9, 12),
            items: [_e()],
            flags: const MaskFlags.cardOnly(false),
            gutter: 0,
          ),
          ExpenseRow(
            gutter: 0,
            expense: _e(),
            category: null,
            flags: const MaskFlags.cardOnly(false),
          ),
        ],
      ),
    );
    expect(findPlain('−3,000원'), findsNWidgets(2)); // U+2212 가 있다 — 헤더 합계 + 행
    expect(findTextContaining('-3,000'), findsNothing); // ASCII 하이픈
  });

  testWidgets('수입은 +, 0 원은 부호 없음', (tester) async {
    await _pump(
      tester,
      ExpenseRow(
        gutter: 0,
        expense: _e(type: 'INCOME'),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    expect(findPlain('+3,000원'), findsOneWidget);

    await _pump(
      tester,
      ExpenseRow(
        gutter: 0,
        expense: _e(amount: 0),
        category: null,
        flags: const MaskFlags.cardOnly(false),
      ),
    );
    // 빈 계정에서 `−0원` 으로 보이던 자리(QA #1).
    expect(findPlain('0원'), findsOneWidget);
  });
}
