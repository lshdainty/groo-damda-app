// 카드 혜택 목록(CardBenefitsScreen)의 끝없이 불러오기 — 03-D 03D-003. 첫 쪽을 못 불러오면 목록 자리가 Result Section 실패 +
// 다시 시도(예외 글을 보이지 않는다), 둘째 쪽부터 못 불러오면 목록 끝 자리가 "더 불러오지 못했어요." + 다시 시도(받은 줄은 그대로),
// 끝에 닿으면 "카드를 모두 봤어요."(한 쪽으로 끝나는 짧은 목록에는 두지 않는다).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/card/presentation/card_benefits_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

List<CardCatalogSummary> _cards(int from, int count) => [
  for (var i = from; i < from + count; i++)
    CardCatalogSummary(rowId: i, cardName: '지어낸 카드 $i'),
];

CardCatalogPage _page(int number, int count, {required bool last}) =>
    CardCatalogPage(
      content: _cards(number * 20, count),
      totalElements: 25,
      totalPages: 2,
      number: number,
      size: 20,
      first: number == 0,
      last: last,
      empty: count == 0,
    );

/// 쪽마다 [responses] 가 정한다 — Exception 이면 던지고 CardCatalogPage 면 돌려준다.
Widget _app(Map<int, Object Function()> responses, {List<int>? asked}) =>
    ProviderScope(
      // riverpod 은 실패한 읽기를 기본으로 거듭 다시 시도한다 — 화면의 실패 처리를 보려면 끈다
      retry: (_, _) => null,
      overrides: [
        cardCatalogPageProvider.overrideWith((ref, key) async {
          asked?.add(key.page);
          final r = responses[key.page]!();
          if (r is CardCatalogPage) return r;
          throw r;
        }),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const CardBenefitsScreen(),
      ),
    );

/// 낱말 안에 이음 문자(U+2060)가 끼므로 글을 지우고 견준다.
Finder _text(String s) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? w.textSpan?.toPlainText() ?? '').replaceAll(
            String.fromCharCode(0x2060),
            '',
          ) ==
          s,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('첫 쪽 실패 — Result Section 실패 + 다시 시도, 예외 글은 보이지 않는다', (
    tester,
  ) async {
    var fail = true;
    await tester.pumpWidget(
      _app({
        0: () => fail
            ? Exception('ApiException(E500, 500): internal boom')
            : _page(0, 5, last: true),
      }),
    );
    await _settle(tester);
    expect(_text('카드를 불러오지 못했어요'), findsOneWidget);
    expect(findTextContaining('boom'), findsNothing);
    expect(findTextContaining('Exception'), findsNothing);
    expect(_text('다시 시도'), findsOneWidget);
    // 다시 시도 → 목록
    fail = false;
    await tester.tap(_text('다시 시도'));
    await _settle(tester);
    expect(_text('카드를 불러오지 못했어요'), findsNothing);
    expect(_text('지어낸 카드 0'), findsOneWidget);
  });

  testWidgets('둘째 쪽 실패 — 목록 끝 자리가 글 + 다시 시도, 받은 줄은 그대로, 다시 시도하면 이어 붙는다', (
    tester,
  ) async {
    var fail = true;
    final asked = <int>[];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app({
        0: () => _page(0, 20, last: false),
        1: () => fail ? Exception('boom') : _page(1, 5, last: true),
      }, asked: asked),
    );
    await _settle(tester);
    expect(asked, [0]);
    // 끝까지 내리면 둘째 쪽을 부른다(300 안) — 실패한다
    await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(asked, [0, 1]);
    await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
    await _settle(tester);
    expect(_text('더 불러오지 못했어요.'), findsOneWidget);
    expect(findTextContaining('boom'), findsNothing);
    expect(_text('지어낸 카드 19'), findsOneWidget, reason: '받은 줄은 그대로');
    // 못 불러온 동안 스크롤해도 거듭 부르지 않는다
    expect(asked, [0, 1]);
    // 다시 시도
    fail = false;
    await tester.tap(_text('다시 시도'));
    await _settle(tester);
    expect(asked, [0, 1, 1]);
    expect(_text('더 불러오지 못했어요.'), findsNothing);
    await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
    await _settle(tester);
    expect(_text('지어낸 카드 24'), findsOneWidget);
    expect(_text('카드를 모두 봤어요.'), findsOneWidget);
  });

  testWidgets('한 쪽으로 끝나는 짧은 목록에는 끝 글을 두지 않는다', (tester) async {
    await tester.pumpWidget(_app({0: () => _page(0, 5, last: true)}));
    await _settle(tester);
    expect(_text('지어낸 카드 4'), findsOneWidget);
    expect(_text('카드를 모두 봤어요.'), findsNothing);
    expect(_text('더 불러오지 못했어요.'), findsNothing);
  });
}
