// 매매 저장 실패 — 시트는 열린 채 맨 위에 우리 글 Callout 한 문장, 서버 글 전역 토스트 없음(silent), 쓴 값은 남는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_trade_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';

import '../../support/plain_text.dart';

const _invest = Asset(
  rowId: 12,
  assetName: 'IBKR',
  assetType: 'INVESTMENT',
  balance: 5000000,
  institution: '키움증권',
  isIncludedInTotal: 'Y',
);

const _settlement = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

const _holding = AssetHolding(
  rowId: 3,
  linked: true,
  tossSymbol: 'SPY',
  quantity: '10',
);

/// 저장을 서버 오류로 거절하는 가짜 — silent 로 불렸는지도 센다.
class _FailingRepo extends AssetRepository {
  _FailingRepo([this.code = 'ASSET_011']) : super(Dio());
  final String code;
  final silentFlags = <bool>[];

  @override
  Future<AssetTrade> createTrade({
    required int assetRowId,
    required String tradeType,
    required String holdingType,
    required String holdingKey,
    required bool linked,
    required String quantity,
    required int amount,
    int? fee,
    String? tradeDate,
    String? description,
    int? settlementAssetRowId,
    bool silent = false,
  }) async {
    silentFlags.add(silent);
    throw ApiException(code: code, message: '서버 원문');
  }

  @override
  Future<AssetTradePreview> previewTrade({
    required int assetRowId,
    required String tradeType,
    required String holdingType,
    required String holdingKey,
    required bool linked,
    required String quantity,
    required int amount,
    int? fee,
    String? tradeDate,
    int? settlementAssetRowId,
  }) async => const AssetTradePreview(cashDelta: -150000, cashAfter: 4850000);

  @override
  Future<List<AssetTrade>> getTrades(int assetRowId) async => const [];
}

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

void main() {
  testWidgets('매매 저장 실패 — 맨 위 Callout · silent · 값 유지 · 서버 글 없음', (
    tester,
  ) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = _FailingRepo();
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetsProvider.overrideWith((ref) async => [_invest, _settlement]),
          assetRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () =>
                    showAssetTradeSheet(ctx, asset: _invest, holding: _holding),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '3');
    await tester.enterText(find.byType(TextField).at(1), '150000');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.byType(FormErrorCallout), findsNothing);

    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.silentFlags, [true]);
    expect(l.tradeSaveFailed, '매매를 처리하지 못했어요.');
    expect(findPlain(l.tradeSaveFailed), findsOneWidget);
    expect(find.byType(FormErrorCallout), findsOneWidget);
    expect(find.textContaining('서버 원문'), findsNothing);
    // 시트는 닫히지 않았고 쓴 값이 남는다.
    expect(_submitButton(l.actionSave), findsOneWidget);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('매매 저장 실패 ASSET_012 — 수량 부족 문장 · 서버 글 없음', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = _FailingRepo('ASSET_012');
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetsProvider.overrideWith((ref) async => [_invest, _settlement]),
          assetRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () =>
                    showAssetTradeSheet(ctx, asset: _invest, holding: _holding),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '3');
    await tester.enterText(find.byType(TextField).at(1), '150000');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.byType(FormErrorCallout), findsNothing);

    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.silentFlags, [true]);
    expect(l.tradeSaveInsufficientQty, '보유 수량이 부족해요.');
    expect(findPlain(l.tradeSaveInsufficientQty), findsOneWidget);
    expect(findPlain(l.tradeSaveFailed), findsNothing);
    expect(find.byType(FormErrorCallout), findsOneWidget);
    expect(find.textContaining('서버 원문'), findsNothing);
    // 시트는 닫히지 않았고 쓴 값이 남는다.
    expect(_submitButton(l.actionSave), findsOneWidget);
    expect(find.text('3'), findsWidgets);
  });
}
