// 매도 · 매수 단추(I-13 20, D3 B) — 단추는 남기고 막고 이유 줄을 둔다. 누르면 뜨던 띠는 없다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/toss_stocks_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('매도 · 매수는 막혀 있고 이유 줄과 읽기 힌트가 있다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 3000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tossHoldingsProvider.overrideWith((ref) async => null),
          tossExchangeRateProvider.overrideWith((ref) async => null),
          watchGroupsProvider.overrideWith((ref) async => <StockWatchGroup>[]),
          tossPricesProvider.overrideWith((ref, k) async => <TossPrice>[]),
          prevCloseProvider.overrideWith((ref, s) async => null),
          tossStockInfoProvider.overrideWith((ref, s) async => null),
          tossWarningsProvider.overrideWith(
            (ref, s) async => <TossStockWarning>[],
          ),
          tossOrderbookProvider.overrideWith((ref, s) async => null),
          tossTradesProvider.overrideWith((ref, s) async => null),
          tossCandlesProvider.overrideWith((ref, a) async => null),
          tossPriceLimitsProvider.overrideWith((ref, s) async => null),
          tossTodayCandlesProvider.overrideWith((ref, s) async => null),
          tossInvestorProvider.overrideWith((ref, s) async => const []),
          stockSearchProvider.overrideWith((ref, q) async => const []),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TossStockDetailPage(symbol: 'A900001'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final buttons = tester
        .widgetList<PButton>(find.byType(PButton))
        .where((b) => b.label == '매도' || b.label == '매수')
        .toList();
    expect(buttons, hasLength(2));
    expect(buttons.every((b) => b.onPressed == null), isTrue);
    expect(findText('주문은 곧 열려요.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('매도')), findsWidgets);
    expect(
      tester.getSemantics(findText('매도')).getSemanticsData().hint +
          tester.getSemantics(findText('매도')).parent!.getSemanticsData().hint,
      contains('주문은 곧 열려요.'),
    );
    await tester.tap(findText('매도'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(findTextContaining('아직 지원하지'), findsNothing);
    expect(findTextContaining('Open API 연동 시 동작'), findsNothing);
    handle.dispose();
  });
}
