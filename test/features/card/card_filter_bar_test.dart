// 카드 거르기 칩 줄(I-20 E 31) — 칩 둘 · 혜택은 할인 · 적립 · 마일리지(캐시백 없음) · 걸리면 ↺ 로 둘 다 지움.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/card/presentation/widgets/card_filter_bar.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

String _plain(Widget w) => w is Text ? (w.data ?? '').replaceAll('⁠', '') : '';
Finder _text(String s) => find.byWidgetPredicate((w) => _plain(w) == s);

Widget _app(
  String? type,
  String? benefit,
  void Function(String?) onType,
  void Function(String?) onBenefit,
) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: CardFilterBar(
      type: type,
      benefit: benefit,
      onType: onType,
      onBenefit: onBenefit,
    ),
  ),
);

void main() {
  testWidgets('조건이 없으면 칩 둘뿐(↺ 없음), 혜택 시트는 넷 · 캐시백 없음', (t) async {
    await t.pumpWidget(_app(null, null, (_) {}, (_) {}));
    expect(_text('카드 종류'), findsOneWidget);
    expect(_text('혜택'), findsOneWidget);
    expect(find.bySemanticsLabel('조건 모두 지우기'), findsNothing);
    await t.tap(_text('혜택'));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    for (final s in ['전체', '할인', '적립', '마일리지']) {
      expect(_text(s), findsOneWidget);
    }
    expect(_text('캐시백'), findsNothing);
  });

  testWidgets('걸린 조건은 값이 칩 글이고 ↺ 가 둘 다 지운다', (t) async {
    String? type = 'CREDIT', benefit = 'POINT';
    await t.pumpWidget(
      _app(type, benefit, (v) => type = v, (v) => benefit = v),
    );
    expect(_text('신용'), findsOneWidget);
    expect(_text('적립'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('조건 모두 지우기'));
    expect(type, isNull);
    expect(benefit, isNull);
  });
}
