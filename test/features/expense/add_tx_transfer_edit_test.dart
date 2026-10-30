// 이체 수정 시트가 **본문을 그린다**.
//
// 릴리스 빌드에서 본문이 통째로 회색 사각형이었다(2026-09-18 사용자 제보) — 그게
// Flutter 의 릴리스 `ErrorWidget` 이다. 즉 본문 build 가 예외로 죽었다.
//
// 원인은 `_isEdit` 의 뜻이 두 개였다는 것이다. 판정은 `edit != null ||
// editTransfer != null` 인데, 편집 모드 분할 적재가 `widget.edit!.rowId` 를 읽었다.
// **이체 수정은 `edit` 이 null** 이라 null check 로 죽었다. 지출·수입 수정만 눌러 보면
// 절대 안 나온다.
//
// 그래서 여기서 잠그는 것은 하나다 — 이체 수정으로 열어도 본문이 서고, 값이 실려 있다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

const _category = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _bank = Asset(
  rowId: 1,
  assetName: 'QA예금',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(
  rowId: 2,
  assetName: 'QA적금',
  assetType: 'SAVINGS',
  institution: '신한',
);

const _transfer = AssetTransfer(
  rowId: 31,
  fromAssetRowId: 1,
  toAssetRowId: 2,
  amount: 120000,
  fee: 500,
  description: '적금 이체',
  transferDate: '2026-09-15T08:28:00',
);

class _FakeAssetRepo extends AssetRepository {
  _FakeAssetRepo() : super(Dio());

  Map<String, Object?>? updated;

  @override
  Future<void> updateTransfer({
    required int rowId,
    required int fromAssetRowId,
    required int toAssetRowId,
    required int amount,
    int? fee,
    int? interestAmount,
    String? description,
    required String transferDate,
    bool silent = false,
  }) async {
    updated = {
      'rowId': rowId,
      'fromAssetRowId': fromAssetRowId,
      'toAssetRowId': toAssetRowId,
      'amount': amount,
      'fee': fee,
      'description': description,
      'transferDate': transferDate,
    };
  }
}

Future<_FakeAssetRepo> _openEdit(WidgetTester tester) async {
  final repo = _FakeAssetRepo();
  // 기본 800x600 은 시트가 넘쳐 레이아웃 경고가 난다 — 실제 폰 크기로 맞춘다.
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_bank, _savings]),
        presetListProvider.overrideWith((ref) async => []),
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
              onPressed: () => showAddTxSheet(ctx, editTransfer: _transfer),
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

  testWidgets('이체 수정으로 열면 본문이 예외 없이 선다', (tester) async {
    await _openEdit(tester);

    // build 가 죽으면 여기서 잡힌다 — 릴리스에서는 그 자리가 회색 사각형이 된다.
    expect(tester.takeException(), isNull);
    expect(find.text(l.expEdit), findsOneWidget);
    // 본문이 실제로 그려졌나 — 제목·푸터는 시트 껍데기라 살아 있다.
    expect(find.byKey(const ValueKey('tx-row-amount')), findsOneWidget);
  });

  testWidgets('열면 이체 값이 실려 있다', (tester) async {
    await _openEdit(tester);

    // 2단계 줄에 실린 값 — 금액 · 수수료 · 날짜 · 메모(값은 줄 끝에 쉼표 · 단위로 보인다)
    expect(find.textContaining('120,000'), findsWidgets, reason: '금액');
    expect(find.textContaining('500'), findsWidgets, reason: '수수료');
    expect(find.byKey(const ValueKey('tx-row-date')), findsOneWidget);
    expect(find.textContaining('적금 이체'), findsWidgets, reason: '메모');
  });

  testWidgets('그대로 저장하면 같은 값이 PUT 으로 나간다', (tester) async {
    final repo = await _openEdit(tester);

    await tester.tap(find.text(l.actionSave).last);
    await tester.pumpAndSettle();

    expect(repo.updated, isNotNull, reason: '저장이 나가지 않았다');
    expect(repo.updated!['rowId'], 31);
    expect(repo.updated!['fromAssetRowId'], 1);
    expect(repo.updated!['toAssetRowId'], 2);
    expect(repo.updated!['amount'], 120000);
    expect(repo.updated!['description'], '적금 이체');
    expect(repo.updated!['transferDate'], '2026-09-15T08:28:00');
  });
}
