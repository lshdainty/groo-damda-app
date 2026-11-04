// 카드 상세 시트(I-20 E 34) — 바닥 버튼 없음 · 키-값 · 혜택 모두 펼치기 · 유의사항 Callout · 실패는 고정 글(원문 없음).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_benefit_detail_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';

CardCatalogDetail _detail({bool cautions = true, int benefits = 2}) =>
    CardCatalogDetail(
      summary: const CardCatalogSummary(
        rowId: 1,
        cardName: '지어낸 카드',
        company: CardCompany(name: '신한카드'),
        cardType: 'CREDIT',
        benefitType: 'DISCOUNT',
        annualFee: CardAnnualFee(amount: 0, label: '국내 5000원'),
        performance: CardPerformance(requiredAmount: 300000, isRequired: 'Y'),
      ),
      brands: const ['국내전용', '해외겸용'],
      benefits: [
        for (var i = 0; i < benefits; i++)
          CardBenefit(category: '커피$i', summary: '10% 할인', detail: '자세한 글$i'),
      ],
      cautions: cautions
          ? const [CardBenefit(detail: '실적은 승인 기준이에요.')]
          : const [],
    );

Widget _app(Object Function() detail) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    cardCatalogDetailProvider.overrideWith((ref, id) async {
      final r = detail();
      if (r is CardCatalogDetail) return r;
      throw r;
    }),
  ],
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Builder(
      builder: (c) => Scaffold(
        body: TextButton(
          onPressed: () => showCardBenefitDetailSheet(c, 1),
          child: const Text('열기'),
        ),
      ),
    ),
  ),
);

String _plain(Widget w) => w is Text ? (w.data ?? '').replaceAll('⁠', '') : '';
Finder _text(String s) => find.byWidgetPredicate((w) => _plain(w) == s);

Future<void> _open(WidgetTester t) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.tap(find.text('열기'));
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('본문 — 바닥 버튼 0, 키-값 쉼표, 브랜드 줄, 혜택 n개, 유의사항 Callout', (t) async {
    await t.pumpWidget(_app(_detail));
    await _open(t);
    expect(_text('카드 상세'), findsOneWidget);
    expect(_text('닫기'), findsNothing, reason: '바닥 [닫기] 버튼 없음(닫기 원 하나는 이름만)');
    expect(_text('국내 5,000원'), findsOneWidget);
    expect(_text('300,000원 이상'), findsOneWidget);
    expect(_text('브랜드'), findsOneWidget);
    expect(_text('혜택 2개'), findsOneWidget);
    expect(find.byType(PCallout), findsOneWidget);
  });

  testWidgets('유의사항 없으면 묶음을 그리지 않고, 혜택 0 이면 안내 글', (t) async {
    await t.pumpWidget(_app(() => _detail(cautions: false, benefits: 0)));
    await _open(t);
    expect(find.byType(PCallout), findsNothing);
    expect(_text('유의사항'), findsNothing);
    expect(_text('등록된 혜택이 없어요.'), findsOneWidget);
  });

  testWidgets('모두 펼치기 ↔ 모두 접기', (t) async {
    await t.pumpWidget(_app(_detail));
    await _open(t);
    expect(_text('자세한 글0'), findsNothing);
    await t.tap(_text('모두 펼치기'));
    await t.pump(const Duration(milliseconds: 500));
    expect(_text('자세한 글0'), findsOneWidget);
    expect(_text('모두 접기'), findsOneWidget);
  });

  testWidgets('실패 — 고정 글 + 다시 시도, 서버 원문은 보이지 않는다', (t) async {
    await t.pumpWidget(_app(() => Exception('ApiException(E500): boom')));
    await _open(t);
    expect(_text('카드 정보를 불러오지 못했어요'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    expect(_text('다시 시도'), findsOneWidget);
  });

  testWidgets('유의사항이 둘이면 한 Callout 안 두 문단, 사이 8', (t) async {
    await t.pumpWidget(
      _app(
        () => _detail().copyWith(
          cautions: const [
            CardBenefit(detail: '첫째 유의예요.'),
            CardBenefit(detail: '둘째 유의예요.'),
          ],
        ),
      ),
    );
    await _open(t);
    expect(find.byType(PCallout), findsOneWidget);
    final a = t.getRect(find.byKey(const ValueKey('callout-text')));
    final b = t.getRect(_text('둘째 유의예요.'));
    expect(b.top - a.bottom, closeTo(8, 1.0));
  });
}
