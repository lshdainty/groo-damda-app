// 거래를 고정으로 정리하기 — 폰은 시트가 아니라 페이지(I-08 Q5-A): 위 상단 바(←) · 가운데 스크롤 · 바닥 [N건 적용] 하나.
// 실패는 빈 목록이 아니다 — 불러오지 못했다고 말하고 다시 시도한다(오류 원문 없음). 고르면 바닥 버튼이 켜진다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:dio/dio.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/stats/presentation/fixed_bulk_page.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

import '../../support/plain_text.dart';

const _range = (startDate: '2026-10-01', endDate: '2026-10-31');

List<Expense> _txs() => [
  for (var i = 0; i < 3; i++)
    Expense(
      rowId: i + 1,
      expenseType: 'EXPENSE',
      amount: 700000,
      merchant: '아주 아주 긴 이름의 월세 이체 묶음 이름이 두 줄을 넘어가는 경우',
      expenseDate: '2026-10-0${i + 1}T00:00:00',
    ),
  const Expense(
    rowId: 9,
    expenseType: 'EXPENSE',
    amount: 12000,
    merchant: '구독',
    expenseDate: '2026-10-05T00:00:00',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  bool fail = false,
  bool masked = false,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        hideCardProvider.overrideWith((ref, card) => masked),
        rangeExpensesProvider.overrideWith((ref, k) async {
          if (fail) throw Exception('server error 원문');
          return _txs();
        }),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const FixedBulkPage(range: _range),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ApplyRepo extends ExpenseRepository {
  _ApplyRepo() : super(Dio());
  bool sawSilent = false;

  @override
  Future<int> bulkMarkFixed(
    List<int> expenseIds, {
    required bool isFixed,
    bool silent = false,
  }) async {
    sawSilent = silent;
    throw ApiException(code: 'X', message: '서버 원문');
  }
}

void main() {
  testWidgets('상단 바 ← + 제목, 바닥 버튼 하나(0건이면 막힘), 시트가 아니다', (tester) async {
    await _pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(PTopNavigation), findsOneWidget);
    expect(find.byType(PTopNavigationIconButton), findsOneWidget);
    expect(findPlain('거래를 고정으로 정리하기'), findsWidgets);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    final apply = tester.widget<PButton>(find.byType(PButton));
    expect(apply.label, '0건 적용');
    expect(apply.onPressed, isNull);
  });

  testWidgets('묶음 줄: 긴 이름은 모든 글자, 고르면 바닥 버튼이 켜진다', (tester) async {
    await _pump(tester);
    expect(
      findPlainContaining('아주 아주 긴 이름의 월세 이체 묶음 이름이 두 줄을 넘어가는 경우'),
      findsOneWidget,
    );
    await tester.tap(find.byType(PListCheckItem).first);
    await tester.pumpAndSettle();
    final apply = tester.widget<PButton>(find.byType(PButton));
    expect(apply.label, '3건 적용');
    expect(apply.onPressed, isNotNull);
  });

  testWidgets('금액을 가리면 묶음 합계가 점이다', (tester) async {
    await _pump(tester, masked: true);
    expect(findRichPlain('2,100,000원'), findsNothing);
    expect(findRichPlain('••••'), findsWidgets);
  });

  testWidgets('불러오지 못하면 빈 목록이 아니라 실패 상자 + 다시 시도, 원문은 없다', (tester) async {
    await _pump(tester, fail: true);
    expect(find.byType(PResultSection), findsOneWidget);
    expect(findPlain('거래를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.textContaining('정리할 거래가 없어요'), findsNothing);
    expect(find.textContaining('server error'), findsNothing);
  });

  testWidgets('적용이 실패하면 페이지는 그대로, 맨 위에 우리 글 Callout, 요청은 silent', (
    tester,
  ) async {
    final repo = _ApplyRepo();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          hideCardProvider.overrideWith((ref, card) => false),
          expenseRepositoryProvider.overrideWith((ref) async => repo),
          rangeExpensesProvider.overrideWith((ref, k) async => _txs()),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const FixedBulkPage(range: _range),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PListCheckItem).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PButton));
    await tester.pumpAndSettle();
    expect(repo.sawSilent, isTrue);
    expect(findPlain('고정 · 변동을 바꾸지 못했어요. 다시 적용해 보세요.'), findsOneWidget);
    expect(find.textContaining('서버 원문'), findsNothing);
    expect(find.byType(FixedBulkPage), findsOneWidget);
  });
}
