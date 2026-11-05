// I-17 50 — 투자 상세: 보유 종목 List 줄 + 거래 기록 List 줄, 차례는 평가액 → 보유 종목 → 추이 → 거래 기록 → 최근 거래.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

const _holding = AssetHolding(
  linked: false,
  holdingName: '가람전자',
  quantity: '10',
  holdingValue: 500000,
);

const _invest = Asset(
  rowId: 20,
  assetName: '연금 증권',
  assetType: 'INVESTMENT',
  balance: 500000,
  holdings: [_holding],
);

const _trade = AssetTrade(
  rowId: 1,
  assetRowId: 20,
  tradeType: 'BUY',
  holdingKey: '가람전자',
  quantity: '10',
  amount: 500000,
  tradeDate: '2026-10-19T09:30:00',
);

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [_invest]),
        assetBalanceTrendProvider.overrideWith(
          (ref, key) async => const <AssetBalancePoint>[],
        ),
        assetTradesProvider.overrideWith((ref, id) async => [_trade]),
        assetTransfersProvider.overrideWith(
          (ref, key) async => const <AssetTransfer>[],
        ),
        expensesByAssetProvider.overrideWith((ref, key) async => const []),
        assetPeriodExpensesProvider.overrideWith((ref, key) async => const []),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetDetailRich(ctx, _invest),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('보유 종목 · 거래 기록은 목록 제목 + List 줄이고 차례가 맞다', (tester) async {
    await _open(tester);

    expect(find.text('보유 종목 · 1'), findsOneWidget);
    expect(find.text('가람전자'), findsOneWidget);
    expect(find.text('10주 · 직접 입력'), findsOneWidget);
    expect(find.text('매수'), findsOneWidget);
    expect(find.text('매도'), findsOneWidget);

    expect(find.text('거래 기록 · 1'), findsOneWidget);
    expect(find.text('매수 · 가람전자 10주'), findsOneWidget);
    expect(find.text('2026-10-19'), findsOneWidget);

    // 거래 기록은 보유 종목 아래, 최근 거래 위
    final holdings = tester.getTopLeft(find.text('보유 종목 · 1')).dy;
    final trend = tester.getTopLeft(find.textContaining('평가액 추이').first).dy;
    final trades = tester.getTopLeft(find.text('거래 기록 · 1')).dy;
    final recent = tester.getTopLeft(find.text('최근 거래')).dy;
    // 보유 종목 → 추이 → 거래 기록 → 최근 거래 (거래 기록은 추이 뒤)
    expect(trend, greaterThan(holdings));
    expect(trades, greaterThan(trend));
    expect(recent, greaterThan(trades));
  });
}
