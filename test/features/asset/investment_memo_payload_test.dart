// 투자 신규의 메모 칸이 저장에 실린다 (감사 2026-09-08 A2).
//
// 화면에는 신규·편집 둘 다 '메모' 칸이 있는데 생성 요청에는 안 실렸다 —
// 적어 넣고 저장하면 그대로 사라졌고, 다시 열어도 빈칸이라 사라진 줄도 몰랐다.
// 편집은 이미 실었으므로(QA #99) 여기서 잠그는 건 생성 쪽이다.
//
// 반대편(편집)도 같이 잠근다. 이게 없으면 "메모는 생성에서만 보내는 것" 이라는
// 잘못된 교훈이 남는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/investment_add_dialog.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

const _invest = Asset(
  rowId: 12,
  assetName: 'IBKR',
  assetType: 'INVESTMENT',
  balance: 5000000,
  institution: '키움증권',
  memo: '연금저축',
  isIncludedInTotal: 'Y',
);

/// 화면이 넘긴 인자를 그대로 잡아 둔다 — 값뿐 아니라 "키를 실었는가" 까지 본다.
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
    created = {'memo': memo, 'institution': institution, 'name': assetName};
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
      'memoPresent': memo.present,
      'memo': memo.value,
      'institution': institution,
    };
    return _fake();
  }
}

Finder _submitButton(String label) => buttonLabeled(label);

Future<_CapturingRepo> _host(
  WidgetTester tester,
  void Function(BuildContext ctx) open,
) async {
  final repo = _CapturingRepo();
  // 시트 본문은 스크롤이다 — 좁은 화면에서는 아래쪽 메모 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => const [_invest]),
        assetRepositoryProvider.overrideWith((ref) async => repo),
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

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('투자 신규는 적어 넣은 메모를 실어 보낸다', (tester) async {
    final repo = await _host(tester, showInvestmentAddDialog);
    await typeInto(tester, l.assetMemo, '연금저축 계좌');
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();

    expect(repo.created, isNotNull, reason: '생성이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(
      repo.created!['memo'],
      '연금저축 계좌',
      reason: '화면에 칸이 있는데 안 실으면 적은 메모가 저장 순간 사라진다',
    );
  });

  testWidgets('비워 두면 메모 키를 빼 서버 기본값에 맡긴다', (tester) async {
    final repo = await _host(tester, showInvestmentAddDialog);
    await typeInto(tester, l.assetNickname, 'QA 별칭');
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();

    expect(repo.created, isNotNull);
    expect(repo.created!['memo'], isNull);
  });

  // 반대편 — 편집은 종전대로 비운 상태까지 실어야 메모가 지워진다(QA #99).
  testWidgets('투자 편집은 메모를 비운 것까지 실어 보낸다', (tester) async {
    final repo = await _host(
      tester,
      (ctx) => showInvestmentEditDialog(ctx, _invest),
    );
    await typeInto(tester, l.assetMemo, '');
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.updated, isNotNull, reason: '저장이 안 불렸다');
    expect(repo.updated!['memoPresent'], isTrue);
    expect(repo.updated!['memo'], isNull);
  });

  testWidgets('투자 별칭은 필수다 — 비우고 누르면 안내가 뜨고 요청은 안 나간다', (tester) async {
    final repo = await _host(tester, showInvestmentAddDialog);
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();
    expect(findRichPlain(l.assetNicknameRequired), findsOneWidget);
    expect(repo.created, isNull, reason: '"{기관} 투자" 자동 이름으로 저장되면 안 된다');
    await typeInto(tester, l.assetNickname, 'QA 연금');
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();
    expect(repo.created!['name'], 'QA 연금');
    expect(
      (repo.created!['institution'] as String).isNotEmpty,
      isTrue,
      reason: '새 자산은 첫 기관이 기본이다',
    );
  });

  testWidgets('기관이 없는 투자 자산을 고치면 기관을 비워 두고 안 보낸다', (tester) async {
    const gold = Asset(
      rowId: 14,
      assetName: '금 현물',
      assetType: 'INVESTMENT',
      balance: 100,
      isIncludedInTotal: 'Y',
    );
    final repo = await _host(
      tester,
      (ctx) => showInvestmentEditDialog(ctx, gold),
    );
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.updated, isNotNull);
    expect(repo.updated!['institution'], isNull);
  });
}
