// 매매 거래일에 **기기 시계를 보내지 않는다** (감사 2026-09-08 A1-②).
//
// 매매 시트엔 거래일 칸이 없다. 그런데 `DateTime.now()` 를 잘라 실어 보냈다. 그 문자열엔
// 시간대가 없어(`2026-09-08T13:22:41`) 사용자 시계와 갈라진다 — 해외에서 앱을 켜면
// 하루 어긋난 날짜로 예수금·실현손익이 계산된다.
//
// 서버는 `tradeDate` 를 필수로 받지 않고(`CreateTradeRequest` 에 `@NotNull` 이 없다),
// 없으면 사용자 시계의 지금을 쓴다(`AssetTradeServiceImpl` 의 `userClock.now`).
// 화면에 칸이 없으면 그쪽에 맡기는 게 맞다.
//
// 여기서 고정하는 것은 둘이다.
//   ① 저장이 거래일을 안 싣는다
//   ② 미리보기도 안 싣는다 — 한쪽만 보내면 미리보기와 저장이 **다른 시점**의 예수금을 본다
//
// (며칠 전 매매를 그날로 적는 건 날짜 칸이 생겨야 되는 별건이다.)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_trade_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

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

/// 시트가 넘긴 인자를 그대로 잡아 둔다.
class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  bool createCalled = false;
  bool previewCalled = false;
  String? createdTradeDate;
  String? previewedTradeDate;

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
  }) async {
    createCalled = true;
    createdTradeDate = tradeDate;
    return const AssetTrade(
      rowId: 1,
      assetRowId: 12,
      tradeType: 'BUY',
      holdingType: 'STOCK',
      holdingKey: 'SPY',
      quantity: '3',
      amount: 150000,
    );
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
  }) async {
    previewCalled = true;
    previewedTradeDate = tradeDate;
    return const AssetTradePreview(cashDelta: -150000, cashAfter: 4850000);
  }

  @override
  Future<List<AssetTrade>> getTrades(int assetRowId) async => const [];
}

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _openSheet(WidgetTester tester) async {
  final repo = _CapturingRepo();
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
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('저장·미리보기 둘 다 거래일을 안 넘긴다', (tester) async {
    final repo = await _openSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), '3');
    await tester.enterText(find.byType(TextField).at(1), '150000');
    // 미리보기는 350ms 디바운스 뒤에 간다.
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(repo.previewCalled, isTrue, reason: '미리보기가 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(
      repo.previewedTradeDate,
      isNull,
      reason: '미리보기만 날짜를 보내면 저장과 다른 시점의 예수금을 보여 준다',
    );

    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.createCalled, isTrue, reason: '저장이 안 불렸다');
    expect(
      repo.createdTradeDate,
      isNull,
      reason: '기기 시계 문자열엔 시간대가 없다 — 서버 사용자 시계에 맡긴다',
    );
  });

  // I-17 56 — 주 버튼을 막지 않고, 누르면 칸 아래 오류가 뜬다(저장 요청은 안 나간다).
  testWidgets('비운 채 저장을 누르면 수량 · 거래대금 오류가 뜨고 요청은 없다', (tester) async {
    final repo = await _openSheet(tester);
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(find.text('수량을 넣어주세요.'), findsOneWidget);
    expect(find.text('거래대금을 넣어주세요.'), findsOneWidget);
    expect(repo.createCalled, isFalse);
  });
}
