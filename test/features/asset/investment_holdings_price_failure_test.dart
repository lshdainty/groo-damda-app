// 자산 편집 보유 미리보기 — 연동 시세를 처음부터 못 받으면 평가액 · 합계가 비어 "평가 0" 처럼 읽히지 않게 그 자리
// Result Section medium + [다시 시도](디자인시스템 판단 5, B2a 분할 실패와 같은 꼴). 다시 받으면 걷힌다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/stocks/application/live_prices.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

const _invest = Asset(
  rowId: 12,
  assetName: '숲길증권 위탁',
  assetType: 'INVESTMENT',
  balance: 5000000,
  institution: '키움증권',
  isIncludedInTotal: 'Y',
  holdings: [AssetHolding(linked: true, tossSymbol: '005930', quantity: '10')],
);

void main() {
  testWidgets('시세를 처음부터 못 받으면 보유 위에 실패 + [다시 시도] — 누르면 다시 받고, 받으면 걷힌다', (
    tester,
  ) async {
    var down = true;
    var calls = 0;
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          assetsProvider.overrideWith((ref) async => const [_invest]),
          myFeaturesProvider.overrideWith(
            (ref) async => const MyFeatures(
              features: ['SECURITIES'],
              connectedBrokers: ['TOSS'],
              primaryBroker: 'TOSS',
            ),
          ),
          livePricesProvider.overrideWith((ref, key) async {
            calls++;
            if (down) throw StateError('서버 원문');
            return const LivePrices.empty();
          }),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showInvestmentEditDialog(ctx, _invest),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    final failure = find.byKey(const ValueKey('holdings-price-failure'));
    expect(failure, findsOneWidget);
    expect(findText('시세를 불러오지 못했어요'), findsWidgets);
    expect(findTextContaining('서버 원문'), findsNothing);
    down = false;
    final before = calls;
    await tester.tap(find.descendant(of: failure, matching: findText('다시 시도')));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(before));
    expect(failure, findsNothing);
  });
}
