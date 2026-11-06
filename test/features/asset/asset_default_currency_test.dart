// 설정의 **기본 통화**를 새 자산이 실제로 쓴다 (D7 · QA #124).
//
// 표시 설정의 '기본 통화' 는 기기에만 저장됐고 **읽는 곳이 하나도 없었다**. 고르면
// 저장된 것처럼 보이는데 다른 기기에서도, 새 자산 어디에서도 아무 일이 없었다.
// 이제 계정에 딸린 값이고(`/me/preferences` 의 `defaultCurrency`, desk-back #328)
// 웹도 같은 자리를 읽는다(desk-front #368).
//
// 여기서 잠그는 것 넷:
//   ① **새 자산**은 기본 통화로 열리고 그 값이 실린다
//   ② **편집은 이 자산의 값으로 연다.** 기존 자산에까지 쓰면 기본 통화를 USD 로
//      바꾼 순간 원화 계좌가 전부 USD 로 열리고, 그대로 저장만 해도 통화가 바뀐다
//   ③ **통화가 안 적힌 옛 자산도 원화로 연다.** 앱 모델은 `currency` 가 nullable
//      이라(웹은 non-null) 여기서 안 막으면 ②의 구멍이 그대로 남는다
//   ④ **늦게 도착해도 반영된다.** `/me/preferences` 는 설정 화면을 안 들른 세션에서
//      이 폼보다 늦게 온다 — 열 때 한 번만 읽어 굳히면 첫 렌더의 원화에 잠긴다
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
import 'package:groo_damda_app/features/asset/presentation/account_add_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/card_add_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/investment_add_dialog.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

/// 테스트가 손으로 미는 기본 통화 — 늦게 도착하는 상황을 그대로 만든다.
class _DefaultCurrencyStub extends Notifier<String> {
  _DefaultCurrencyStub(this.initial);
  final String initial;

  @override
  String build() => initial;

  void push(String code) => state = code;
}

final _serverDefault = NotifierProvider<_DefaultCurrencyStub, String>(
  () => _DefaultCurrencyStub('KRW'),
);

/// 웹에서 원화로 만든 계좌 — `currency` 가 적혀 있다.
const _krwAccount = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  currency: 'KRW',
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

/// 통화 칸이 생기기 전에 만들어져 통화가 안 적힌 계좌.
const _legacyAccount = Asset(
  rowId: 9,
  assetName: 'QA 옛 계좌',
  assetType: 'BANK_ACCOUNT',
  balance: 30000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

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
    created = {'currency': currency};
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
    updated = {'currency': currency};
    return _fake();
  }
}

Finder _submitButton(String label) => buttonLabeled(label);

Future<_CapturingRepo> _host(
  WidgetTester tester,
  void Function(BuildContext ctx) open, {
  String defaultCurrency = 'KRW',
  List<Asset> assets = const [_krwAccount],
}) async {
  final repo = _CapturingRepo();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _serverDefault.overrideWith(
          () => _DefaultCurrencyStub(defaultCurrency),
        ),
        // 실제 provider 는 `/me/preferences` 를 타므로 값만 흘려보낸다.
        defaultCurrencyProvider.overrideWith(
          (ref) => ref.watch(_serverDefault),
        ),
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
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return repo;
}

/// 열려 있는 폼에 뒤늦게 기본 통화를 밀어 넣는다.
void _pushDefault(WidgetTester tester, String code) {
  ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  ).read(_serverDefault.notifier).push(code);
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('새 자산은 설정의 기본 통화로 연다', () {
    testWidgets('계좌 — 고르지 않아도 USD 가 실린다', (tester) async {
      final repo = await _host(
        tester,
        showAccountAddDialog,
        defaultCurrency: 'USD',
      );

      expect(findPlain('\$ USD'), findsOneWidget);
      await typeInto(tester, l.assetNickname, 'QA 별칭');
      // 외화 자산은 환율이 필수다(서버 AST_036, I-13)
      await typeInto(tester, l.assetExchangeRate, '1300');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isNotNull, reason: '생성이 안 불렸다');
      expect(
        repo.created!['currency'],
        'USD',
        reason: '고른 값을 안 쓰면 설정 화면이 종전처럼 아무 일도 안 하는 칸이 된다',
      );
    });

    // 카드는 원화만이다(I-13 사용자 결정 4, 서버 AST_037) — 기본 통화가 USD 여도 원화로 실린다.
    testWidgets('카드 — 기본 통화가 USD 여도 원화로 실린다', (tester) async {
      final repo = await _host(
        tester,
        (c) => showAssetKindForm(c, AssetKind.check),
        defaultCurrency: 'USD',
      );
      await pickCardProduct(tester, l.assetCardProduct, 'QA 체크카드');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created!['currency'], 'KRW');
    });

    testWidgets('투자 — 고르지 않아도 USD 가 실린다', (tester) async {
      final repo = await _host(
        tester,
        showInvestmentAddDialog,
        defaultCurrency: 'USD',
      );
      await typeInto(tester, l.assetNickname, 'QA 별칭');
      // 외화 자산은 환율이 필수다(서버 AST_036, I-13)
      await typeInto(tester, l.assetExchangeRate, '1300');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created!['currency'], 'USD');
    });

    testWidgets('설정이 원화면 종전 그대로 원화다', (tester) async {
      final repo = await _host(tester, showAccountAddDialog);
      await typeInto(tester, l.assetNickname, 'QA 별칭');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created!['currency'], 'KRW');
    });

    testWidgets('고른 값이 기본 통화를 이긴다', (tester) async {
      final repo = await _host(
        tester,
        showAccountAddDialog,
        defaultCurrency: 'USD',
      );
      // 계좌 폼의 `PSelect<String>` 은 통화 하나뿐이다.
      await tester.tap(find.byType(PSelect<String>));
      await tester.pumpAndSettle();
      await tester.tap(findPlain('¥ JPY').last);
      await tester.pumpAndSettle();
      await typeInto(tester, l.assetNickname, 'QA 별칭');
      // 외화 자산은 환율이 필수다(서버 AST_036, I-13)
      await typeInto(tester, l.assetExchangeRate, '9');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created!['currency'], 'JPY');
    });
  });

  group('편집은 이 자산의 값으로 연다', () {
    testWidgets('기본 통화가 USD 여도 원화 계좌는 원화로 열린다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showAccountEditDialog(ctx, _krwAccount),
        defaultCurrency: 'USD',
      );

      expect(findPlain('₩ KRW'), findsOneWidget);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(
        repo.updated!['currency'],
        'KRW',
        reason: '기본 통화가 기존 자산까지 덮으면 그대로 저장만 해도 통화가 바뀐다',
      );
    });

    testWidgets('통화가 안 적힌 옛 계좌도 원화로 열린다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showAccountEditDialog(ctx, _legacyAccount),
        defaultCurrency: 'USD',
        assets: const [_legacyAccount],
      );

      expect(findPlain('₩ KRW'), findsOneWidget);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(
        repo.updated!['currency'],
        'KRW',
        reason: '앱 모델은 currency 가 nullable 이다 — 여기서 안 막으면 옛 계좌가 USD 가 된다',
      );
    });
  });

  testWidgets('기본 통화가 폼보다 늦게 와도 반영된다', (tester) async {
    // `/me/preferences` 는 설정 화면을 안 들른 세션에서 이 폼보다 늦게 온다.
    final repo = await _host(tester, showAccountAddDialog);
    expect(findPlain('₩ KRW'), findsOneWidget);

    _pushDefault(tester, 'USD');
    await tester.pumpAndSettle();

    expect(
      findPlain('\$ USD'),
      findsOneWidget,
      reason: '열 때 한 번만 읽어 굳히면 첫 렌더의 원화에 잠긴다',
    );
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    // 외화 자산은 환율이 필수다(서버 AST_036, I-13)
    await typeInto(tester, l.assetExchangeRate, '1300');
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();
    expect(repo.created!['currency'], 'USD');
  });
}
