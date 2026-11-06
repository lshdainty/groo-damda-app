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
import '../../support/plain_text.dart';

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

Future<void> _open(
  WidgetTester tester, {
  bool tradesFail = false,
  bool transfersFail = false,
}) async {
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
        assetTradesProvider.overrideWith(
          (ref, id) async => tradesFail ? throw Exception('서버 원문') : [_trade],
        ),
        assetTransfersProvider.overrideWith(
          (ref, key) async => transfersFail
              ? throw Exception('서버 원문')
              : const <AssetTransfer>[],
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
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('거래 기록을 처음 받지 못하면 구역이 사라지지 않고 그 자리 실패 + 다시 시도', (tester) async {
    await _open(tester, tradesFail: true);
    expect(
      find.byKey(const ValueKey('asset-detail-trades-failure')),
      findsOneWidget,
    );
    expect(findText('거래 기록 정보를 불러오지 못했어요'), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
  });

  testWidgets('이체를 처음 받지 못하면 최근 내역이 "이체 없음" 이 아니라 내역 실패 + 다시 시도', (
    tester,
  ) async {
    await _open(tester, transfersFail: true);
    expect(findText('내역을 불러오지 못했어요'), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
  });

  testWidgets('보유 종목 · 거래 기록은 목록 제목 + List 줄이고 차례가 맞다', (tester) async {
    await _open(tester);

    expect(findText('보유 종목 · 1'), findsOneWidget);
    expect(findText('가람전자'), findsOneWidget);
    expect(findText('10주 · 직접 입력'), findsOneWidget);
    expect(findText('매수'), findsOneWidget);
    expect(findText('매도'), findsOneWidget);

    expect(findText('거래 기록 · 1'), findsOneWidget);
    expect(findText('매수 · 가람전자 10주'), findsOneWidget);
    expect(findText('2026-10-19'), findsOneWidget);

    // 거래 기록은 보유 종목 아래, 최근 거래 위
    final holdings = tester.getTopLeft(findText('보유 종목 · 1')).dy;
    final trend = tester.getTopLeft(findTextContaining('평가액 추이').first).dy;
    final trades = tester.getTopLeft(findText('거래 기록 · 1')).dy;
    final recent = tester.getTopLeft(findText('최근 거래')).dy;
    // 보유 종목 → 추이 → 거래 기록 → 최근 거래 (거래 기록은 추이 뒤)
    expect(trend, greaterThan(holdings));
    expect(trades, greaterThan(trend));
    expect(recent, greaterThan(trades));
  });
}
