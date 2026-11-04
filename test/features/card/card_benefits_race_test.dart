// 조건이 바뀐 순간 받던 요청이 있어도 새 조건의 요청은 나가고, 옛 조건의 응답은 목록에 붙지 않는다(H1 — 세대 번호).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/card/presentation/card_benefits_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

CardCatalogPage _page(String name, {int total = 1}) => CardCatalogPage(
  content: [CardCatalogSummary(rowId: 1, cardName: name)],
  totalElements: total,
  totalPages: 1,
  number: 0,
  size: 30,
  first: true,
  last: true,
  empty: false,
);

String _plain(Widget w) => w is Text ? (w.data ?? '').replaceAll('⁠', '') : '';
Finder _text(String s) => find.byWidgetPredicate((w) => _plain(w) == s);

void main() {
  testWidgets('받는 중 조건을 바꾸면 새 요청이 나가고 옛 응답은 버려진다', (t) async {
    final keys = <CardSearchKey>[];
    final waits = <Completer<CardCatalogPage>>[];
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          cardCatalogPageProvider.overrideWith((ref, key) {
            keys.add(key);
            final c = Completer<CardCatalogPage>();
            waits.add(c);
            return c.future;
          }),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const CardBenefitsScreen(),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(keys.length, 1);
    expect(keys.first.includeDiscontinued, isNull);

    // 첫 요청이 아직 안 온 채 조건을 바꾼다 — 가드를 건너 새 요청이 나간다
    await t.tap(_text('단종 카드 포함'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(keys.length, 2);
    expect(keys.last.includeDiscontinued, isTrue);

    // 새 조건의 응답이 먼저, 옛 조건의 응답이 늦게 온다 — 늦은 것은 줄에 붙지 않는다
    waits[1].complete(_page('새 조건 카드', total: 1));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    waits[0].complete(_page('옛 조건 카드', total: 99));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(_text('새 조건 카드'), findsOneWidget);
    expect(_text('옛 조건 카드'), findsNothing);
    expect(_text('총 1장'), findsOneWidget);
  });

  testWidgets('다음 쪽을 받는 중 조건을 바꾸면 새 조건 첫 쪽이 나가고 옛 다음 쪽은 붙지 않는다', (t) async {
    final keys = <CardSearchKey>[];
    final waits = <Completer<CardCatalogPage>>[];
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          cardCatalogPageProvider.overrideWith((ref, key) {
            keys.add(key);
            final c = Completer<CardCatalogPage>();
            waits.add(c);
            return c.future;
          }),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const CardBenefitsScreen(),
        ),
      ),
    );
    await t.pump();
    waits[0].complete(_page('첫 쪽 카드', total: 90));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    // 끝까지 내려 다음 쪽 요청을 낸다
    await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await t.pump(const Duration(milliseconds: 100));
    expect(keys.length, 2);
    expect(keys.last.page, 1);
    // 받는 중 조건을 바꾼다 — 새 조건의 첫 쪽이 나간다
    await t.tap(_text('단종 카드 포함'));
    await t.pump(const Duration(milliseconds: 100));
    expect(keys.last.page, 0);
    expect(keys.last.includeDiscontinued, isTrue);
    waits.last.complete(_page('새 조건 카드', total: 1));
    await t.pump(const Duration(milliseconds: 50));
    waits[1].complete(_page('옛 다음 쪽 카드', total: 90));
    await t.pump(const Duration(milliseconds: 50));
    expect(_text('새 조건 카드'), findsOneWidget);
    expect(_text('옛 다음 쪽 카드'), findsNothing);
  });
}
