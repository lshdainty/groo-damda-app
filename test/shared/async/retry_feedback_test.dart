// [다시 시도] 피드백 — 실패 뒤 다시 받는 동안 실패 상자를 그대로 두고 단추가 진행 원(skeleton.md:139). 대표 셋:
// 고르기 시트(CategoryPickBody) · 시트 본문(CardDetailContent, 옛 "받는 중이면 늘 Skeleton") · 공용 실패 부품(StocksFailure).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_benefit_detail_sheet.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/category_pick.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';

import '../../support/plain_text.dart';

Widget _app(List overrides, Widget child) => ProviderScope(
  retry: (_, _) => null,
  overrides: overrides.cast(),
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

PButton _retryButton(WidgetTester tester) => tester.widget<PButton>(
  find.descendant(
    of: find.byType(PResultSection),
    matching: find.byType(PButton),
  ),
);

/// 첫 요청은 실패, 그다음은 끝나지 않는 요청 — [다시 시도] 를 누른 뒤 "다시 받는 중" 에 머문다.
Future<T> Function() _failThenPending<T>(List<int> calls) => () {
  calls.add(1);
  if (calls.length == 1) return Future<T>.error(Exception('RAW_SERVER_TEXT'));
  return Completer<T>().future;
};

void main() {
  testWidgets('CategoryPickBody — 다시 받는 동안 실패 상자 그대로 · 단추 진행 원', (
    tester,
  ) async {
    final calls = <int>[];
    final load = _failThenPending<List<ExpenseCategory>>(calls);
    await tester.pumpWidget(
      _app([
        categoriesProvider.overrideWith((ref) => load()),
      ], const CategoryPickBody(kind: 'EXPENSE', selectedRowId: null)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(PResultSection), findsOneWidget);
    expect(_retryButton(tester).loading, isFalse);
    expect(findTextContaining('RAW_SERVER_TEXT'), findsNothing);

    await tester.tap(findText('다시 시도'));
    await tester.pump();
    expect(calls, hasLength(2));
    expect(find.byType(PResultSection), findsOneWidget);
    expect(_retryButton(tester).loading, isTrue);
  });

  testWidgets('CardDetailContent — 다시 받는 동안 Skeleton 으로 바꾸지 않고 단추 진행 원', (
    tester,
  ) async {
    final calls = <int>[];
    final load = _failThenPending<CardCatalogDetail>(calls);
    await tester.pumpWidget(
      _app([
        cardCatalogDetailProvider.overrideWith((ref, id) => load()),
      ], const CardDetailContent(rowId: 7)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(PResultSection), findsOneWidget);

    await tester.tap(find.byType(PButton));
    await tester.pump();
    expect(calls, hasLength(2));
    expect(find.byType(PResultSection), findsOneWidget);
    expect(_retryButton(tester).loading, isTrue);
  });

  testWidgets('StocksFailure — retrying 이 단추 진행 원으로', (tester) async {
    await tester.pumpWidget(
      _app(const [], StocksFailure(title: '시세', onRetry: () {})),
    );
    expect(_retryButton(tester).loading, isFalse);
    await tester.pumpWidget(
      _app(
        const [],
        StocksFailure(title: '시세', onRetry: () {}, retrying: true),
      ),
    );
    expect(_retryButton(tester).loading, isTrue);
  });
}
