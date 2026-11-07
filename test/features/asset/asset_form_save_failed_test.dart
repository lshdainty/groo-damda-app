// 자산 폼(계좌 · 카드 · 투자) 저장 실패 — 폼은 열린 채 맨 위에 우리 글 Callout 한 문장, 서버 글은 띄우지 않음(silent), 쓴 값은 남는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

const _account = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);
const _card = Asset(
  rowId: 7,
  assetName: '신한 Deep Dream',
  assetType: 'CREDIT_CARD',
  balance: -500000,
  institution: '신한카드',
  isIncludedInTotal: 'Y',
  creditLimit: 5000000,
  paymentDay: 14,
  carryoverAmount: 9000,
);
const _invest = Asset(
  rowId: 12,
  assetName: 'IBKR',
  assetType: 'INVESTMENT',
  balance: 5000000,
  institution: '키움증권',
  isIncludedInTotal: 'Y',
);

const _emptyPage = CardCatalogPage(
  content: [],
  totalElements: 0,
  totalPages: 0,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: true,
);

/// 저장을 서버 오류로 거절하는 가짜 — silent 로 불렸는지도 센다.
class _FailingRepo extends AssetRepository {
  _FailingRepo() : super(Dio());
  final silentFlags = <bool>[];

  @override
  Future<Asset> update({
    required int id,
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    Patch<double> exchangeRate = const Patch.keep(),
    String? color,
    String? institution,
    Patch<String> memo = const Patch.keep(),
    String? isIncludedInTotal,
    String? isAmountHidden,
    int? cardCatalogRowId,
    Patch<int> creditLimit = const Patch.keep(),
    Patch<int> paymentDay = const Patch.keep(),
    Patch<int> paymentAssetRowId = const Patch.keep(),
    bool? isOverdraft,
    List<AssetHolding>? holdings,
    int? carryoverAmount,
    int? dueCarryoverAmount,
    bool silent = false,
  }) async {
    silentFlags.add(silent);
    throw ApiException(code: 'X', message: '서버 원문');
  }
}

Future<_FailingRepo> _open(WidgetTester tester, Asset asset) async {
  final repo = _FailingRepo();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [asset]),
        assetRepositoryProvider.overrideWith((ref) async => repo),
        cardCatalogPageProvider.overrideWith((ref, key) async => _emptyPage),
        myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetEditForm(ctx, asset),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  for (final c in [('계좌', _account), ('카드', _card), ('투자', _invest)]) {
    testWidgets('${c.$1} 폼 저장 실패 — 맨 위 Callout · silent · 값 유지 · 서버 글 없음', (
      tester,
    ) async {
      final repo = await _open(tester, c.$2);
      expect(find.byType(FormErrorCallout), findsNothing);
      await tester.tap(buttonLabeled(l.actionSave));
      await tester.pumpAndSettle();
      expect(repo.silentFlags, [true]);
      expect(l.assetSaveFailed, '자산을 저장하지 못했어요.');
      expect(findPlain(l.assetSaveFailed), findsOneWidget);
      expect(find.byType(FormErrorCallout), findsOneWidget);
      expect(findTextContaining('서버 원문'), findsNothing);
      // 시트는 닫히지 않았고 쓴 값이 남는다.
      expect(buttonLabeled(l.actionSave), findsOneWidget);
      expect(findText(c.$2.assetName), findsWidgets);
    });
  }
}
