import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

CompositionSlice _s(String n, double pct) =>
    CompositionSlice(symbol: n, name: n, krwValue: pct, weightPct: pct);

Future<void> _pump(WidgetTester t, Locale locale) => t.pumpWidget(
  MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: SingleChildScrollView(
        child: StocksCompositionBody(
          comp: [
            _s('가', 58.14),
            _s('나', 21.51),
            _s('다', 15.12),
            _s('라', 5.2),
            _s('마', 0.03),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('증권 구성 비중 — 소수 첫째 자리 늘 한 자리, 0.05% 미만은 "0.1% 미만"', (t) async {
    await _pump(t, const Locale('ko'));
    for (final v in ['58.1%', '21.5%', '15.1%', '5.2%', '0.1% 미만']) {
      expect(findPlain(v), findsOneWidget, reason: v);
    }
    expect(findPlain('58.14%'), findsNothing);
  });

  testWidgets('영어 — "<0.1%"', (t) async {
    await _pump(t, const Locale('en'));
    expect(findPlain('<0.1%'), findsOneWidget);
  });
}
