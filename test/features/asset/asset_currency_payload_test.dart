// 통화·환율은 **세 폼 다 고를 수 있고**, 화면이 보여 주는 값이 그대로 실린다 (D1).
//
// 종전엔 계좌 폼에만 칸이 있었다. 카드·투자 폼은 고르는 자리가 없는데 'KRW' 를 실어
// 보내서, 웹에서 USD 로 만든 해외 카드·증권계좌를 앱에서 한 번 편집하면 원화가 되고
// 서버가 환산율까지 1 로 정규화해(`Asset.normalizeRate`) 총자산이 환산 없이 합쳐졌다.
// 그래서 한동안 **안 싣는 것**으로 막아 뒀다(감사 2026-09-08 A1-①).
//
// 이제 칸이 생겼으므로 막을 이유가 없다 — 화면이 지금 통화를 읽어 와 보여 주고,
// 그 값을 싣는다. 여기서 잠그는 것은 넷이다.
//   ① 편집 폼이 서버 통화·환율을 **채워서** 연다. 안 채우면 저장 한 번에 KRW 로
//      되돌아간다 — 칸이 생겨서 오히려 위험해진 자리다
//   ② 그대로 저장하면 그대로 실린다(USD 는 USD 로 남는다)
//   ③ 원화로 되돌리면 환율이 **명시적 null** 로 지워진다. 키를 빼면 서버가 옛 환율을
//      지켜 KRW × 1380 이 된다
//   ④ 환율 칸은 외화일 때만 보인다 — 원화에 1 을 적게 하는 칸은 뜻이 없다
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) "무엇을 보내는가" 를 위젯 테스트로 잠근다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/asset/presentation/account_add_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/card_add_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/investment_add_dialog.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

/// 웹에서 USD 로 만든 해외 카드.
const _usdCard = Asset(
  rowId: 7,
  assetName: 'Chase Sapphire',
  assetType: 'CREDIT_CARD',
  balance: -1200,
  currency: 'USD',
  exchangeRate: 1380,
  institution: '신한카드',
  isIncludedInTotal: 'Y',
  creditLimit: 5000000,
  paymentDay: 14,
);

/// 웹에서 USD 로 만든 해외 증권계좌.
const _usdInvest = Asset(
  rowId: 12,
  assetName: 'IBKR',
  assetType: 'INVESTMENT',
  balance: 5000,
  currency: 'USD',
  exchangeRate: 1380,
  institution: '키움증권',
  isIncludedInTotal: 'Y',
);

const _krwAccount = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

/// 카드 신규는 카탈로그에서 상품을 골라야 저장이 열린다 — 한 장만 둔다.
const _catalog = CardCatalogPage(
  content: [
    CardCatalogSummary(
      rowId: 101,
      cardName: 'QA 체크카드',
      cardType: 'CHECK',
      company: CardCompany(rowId: 1, name: '국민카드'),
    ),
  ],
  totalElements: 1,
  totalPages: 1,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: false,
);

/// 화면이 넘긴 인자를 그대로 잡아 둔다 — 값뿐 아니라 "넘겼는가" 까지 본다.
class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  Map<String, Object?>? created;
  Map<String, Object?>? updated;

  Asset _fake() => const Asset(rowId: 1, assetName: 'x', assetType: 'CASH');

  @override
  Future<Asset> create({
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal,
    String? isAmountHidden,
    int? sortOrder,
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    bool? isOverdraft,
    List<AssetHolding>? holdings,
    int? dueCarryoverAmount,
    bool silent = false,
  }) async {
    created = {'currency': currency, 'exchangeRate': exchangeRate};
    return _fake();
  }

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
    updated = {
      'currency': currency,
      'exchangeRatePresent': exchangeRate.present,
      'exchangeRate': exchangeRate.present ? exchangeRate.value : null,
    };
    return _fake();
  }
}

Finder _submitButton(String label) => buttonLabeled(label);

/// 통화 select 를 펼쳐 코드를 고른다 — 세 폼 다 `PSelect<String>` 은 통화 하나뿐이다.
Future<void> _pickCurrency(WidgetTester tester, String label) async {
  await tester.tap(find.byType(PSelect<String>));
  await tester.pumpAndSettle();
  await tester.tap(findPlain(label).last);
  await tester.pumpAndSettle();
}

Future<_CapturingRepo> _host(
  WidgetTester tester,
  void Function(BuildContext ctx) open, {
  List<Asset> assets = const [_krwAccount],
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 스크롤이다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        assetRepositoryProvider.overrideWith((ref) async => repo),
        cardCatalogPageProvider.overrideWith((ref, key) async => _catalog),
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
              onPressed: () => open(ctx),
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

  // 카드(신용 · 체크)는 원화만이다(I-13 사용자 결정 4, 서버 AST_037) — 통화 칸이 없고 늘 원화로 보낸다.
  // 웹에서 USD 로 만든 옛 카드도 앱에서 저장하면 원화 · 환율 null 로 나간다(웹 AssetEditDialog.payload 시험과 같은 기대값).
  group('카드', () {
    testWidgets('편집 폼에 통화 · 환율 칸이 없다', (tester) async {
      await _host(
        tester,
        (ctx) => showCardEditDialog(ctx, _usdCard),
        assets: const [_usdCard, _krwAccount],
      );

      expect(find.byType(PSelect<String>), findsNothing);
      expect(fieldWithLabel(l.assetExchangeRate), findsNothing);
    });

    testWidgets('옛 USD 카드를 그대로 저장하면 원화 · 환율 명시적 null 로 나간다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showCardEditDialog(ctx, _usdCard),
        assets: const [_usdCard, _krwAccount],
      );
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.updated, isNotNull, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
      expect(repo.updated!['currency'], 'KRW');
      expect(
        repo.updated!['exchangeRatePresent'],
        isTrue,
        reason: '키가 빠지면 서버가 옛 환율을 지킨다',
      );
      expect(repo.updated!['exchangeRate'], isNull);
    });

    testWidgets('신규 체크카드는 원화로 실린다', (tester) async {
      // 체크카드는 결제일 없이도 저장이 열린다(신용은 결제일이 필수).
      final repo = await _host(
        tester,
        (c) => showAssetKindForm(c, AssetKind.check),
      );
      await pickCardProduct(tester, l.assetCardProduct, 'QA 체크카드');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isNotNull, reason: '생성이 안 불렸다');
      expect(repo.created!['currency'], 'KRW');
      expect(repo.created!['exchangeRate'], isNull);
    });
  });

  group('투자', () {
    testWidgets('편집 폼이 서버 통화·환율을 채워서 연다', (tester) async {
      await _host(
        tester,
        (ctx) => showInvestmentEditDialog(ctx, _usdInvest),
        assets: const [_usdInvest, _krwAccount],
      );

      expect(findPlain('\$ USD'), findsOneWidget);
      expect(textOf(tester, l.assetExchangeRate), '1380');
    });

    testWidgets('그대로 저장하면 USD 가 USD 로 남는다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showInvestmentEditDialog(ctx, _usdInvest),
        assets: const [_usdInvest, _krwAccount],
      );
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.updated, isNotNull, reason: '저장이 안 불렸다');
      expect(
        repo.updated!['currency'],
        'USD',
        reason: 'KRW 를 실으면 USD 증권계좌가 원화가 되고 환산율이 1 이 된다',
      );
      expect(repo.updated!['exchangeRate'], 1380.0);
    });

    testWidgets('원화로 되돌리면 환율이 명시적 null 로 지워진다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showInvestmentEditDialog(ctx, _usdInvest),
        assets: const [_usdInvest, _krwAccount],
      );
      await _pickCurrency(tester, '₩ KRW');
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.updated!['currency'], 'KRW');
      expect(repo.updated!['exchangeRatePresent'], isTrue);
      expect(repo.updated!['exchangeRate'], isNull);
    });

    testWidgets('신규는 고른 통화를 싣는다', (tester) async {
      final repo = await _host(tester, showInvestmentAddDialog);
      await _pickCurrency(tester, '\$ USD');
      await typeInto(tester, l.assetNickname, 'QA 별칭');
      await typeInto(tester, l.assetExchangeRate, '1300');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isNotNull, reason: '생성이 안 불렸다');
      expect(repo.created!['currency'], 'USD');
      expect(repo.created!['exchangeRate'], 1300.0);
    });

    // 외화 자산은 환율이 필수다(서버 AST_036, I-13) — 비우면 요청이 안 나가고 칸 오류가 선다.
    testWidgets('외화인데 환율을 비우면 저장이 안 나가고 칸 오류', (tester) async {
      final repo = await _host(tester, showInvestmentAddDialog);
      await _pickCurrency(tester, '\$ USD');
      await typeInto(tester, l.assetNickname, 'QA 별칭');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isNull, reason: '환율 없는 외화 자산은 서버가 400 으로 막는다');
      expect(find.text(l.assetExchangeRateRequired), findsOneWidget);
    });
  });

  // 계좌 폼은 종전부터 칸이 있었다 — 셋을 한 위젯으로 합치면서 안 깨졌는지 본다.
  group('계좌', () {
    testWidgets('편집은 통화를 그대로 넘긴다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showAccountEditDialog(ctx, _krwAccount),
      );
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.updated, isNotNull, reason: '저장이 안 불렸다');
      expect(repo.updated!['currency'], 'KRW');
    });
  });
}
