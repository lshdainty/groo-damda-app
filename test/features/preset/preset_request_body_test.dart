// 프리셋 폼이 **실제로 서버에 보내는 본문**(I-20 20-2 검수 T1 ~ T7) — dio 어댑터로 나가는 JSON 을 잡는다. 가짜 저장소는
// `'key': ?value`(null 이면 키를 뺀다)가 키를 실었는지를 못 본다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

import '../../support/capture_adapter.dart';
import '../../support/plain_text.dart';

const _food = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
);
const _parent = ExpenseCategory(
  rowId: 2,
  categoryName: '교통',
  expenseType: 'EXPENSE',
  sortOrder: 1,
  hasChildren: true,
);
const _child = ExpenseCategory(
  rowId: 3,
  categoryName: '버스',
  expenseType: 'EXPENSE',
  sortOrder: 2,
  parentRowId: 2,
);
const _bank = Asset(rowId: 7, assetName: '주거래', assetType: 'BANK_ACCOUNT');
const _bank2 = Asset(rowId: 8, assetName: '비상금', assetType: 'SAVINGS');
const _loan = Asset(rowId: 9, assetName: '대출', assetType: 'LOAN');
const _card = Asset(rowId: 10, assetName: '신용카드', assetType: 'CREDIT_CARD');

const _expense = ExpenseTemplate(
  rowId: 5,
  templateName: '점심',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
  assetRowId: 7,
  fee: null,
);
const _loanPreset = ExpenseTemplate(
  rowId: 6,
  templateName: '대출 상환',
  expenseType: 'TRANSFER',
  assetRowId: 7,
  toAssetRowId: 9,
  amount: 300000,
  lockAmount: 'Y',
  interestAmount: 20000,
  fee: 500,
);

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  Future<CaptureAdapter> open(
    WidgetTester tester,
    ExpenseTemplate? edit, {
    Future<List<Asset>>? assets,
    Future<List<ExpenseCategory>>? categories,
    int status = 200,
  }) async {
    final cap = CaptureAdapter()..status = status;
    final repo = PresetRepository(Dio()..httpClientAdapter = cap);
    tester.view.physicalSize = const Size(1170, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presetListProvider.overrideWith(
            (ref) async => [if (edit != null) edit],
          ),
          presetRepositoryProvider.overrideWith((ref) async => repo),
          categoriesProvider.overrideWith(
            (ref) => categories ?? Future.value([_food, _parent, _child]),
          ),
          assetsProvider.overrideWith(
            (ref) => assets ?? Future.value([_bank, _bank2, _loan, _card]),
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showPresetEditDialog(ctx, edit: edit),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    return cap;
  }

  Finder t(String s) => find.byWidgetPredicate(
    (w) =>
        w is Text && plainOf(w.data ?? w.textSpan!.toPlainText()) == plainOf(s),
  );
  Finder btn(String s) => findWidgetWithText(PButton, s).last;
  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  Future<void> step(WidgetTester tester, String row, String text) async {
    await tap(tester, t(row));
    await tester.enterText(find.byType(EditableText).first, text);
    await tap(tester, btn(l.actionDone));
  }

  test('저장소 — 수정 본문은 카테고리 키를 명시 null 로도 싣고, 안 건드리면 뺀다', () async {
    final cap = CaptureAdapter();
    final repo = PresetRepository(Dio()..httpClientAdapter = cap);
    await repo.update(
      id: 5,
      templateName: '점심',
      categoryRowId: const Patch.set(null),
      expenseType: 'TRANSFER',
    );
    expect(cap.lastBody!.containsKey('categoryRowId'), isTrue);
    expect(cap.lastBody!['categoryRowId'], isNull);
    await repo.update(id: 5, templateName: '점심', expenseType: 'EXPENSE');
    expect(cap.lastBody!.containsKey('categoryRowId'), isFalse);
  });

  testWidgets('T2 · T7 지출 프리셋을 이체로 바꿔 저장하면 본문에 categoryRowId: null 이 있다', (
    tester,
  ) async {
    final cap = await open(tester, _expense);
    await tap(tester, t(l.expTypeTransfer));
    await tap(tester, t(l.presetToAccount));
    await tap(tester, t('대출'));
    await tap(tester, btn(l.actionSave));
    expect(cap.requests, hasLength(1));
    expect(cap.lastBody!.containsKey('categoryRowId'), isTrue);
    expect(cap.lastBody!['categoryRowId'], isNull);
    expect(cap.lastBody!['expenseType'], 'TRANSFER');
    expect(cap.lastBody!['toAssetRowId'], 9);
  });

  testWidgets('T3 이체 → 지출로 바꾸면 받는 계좌 · 수수료 · 이자가 명시 null', (tester) async {
    final cap = await open(tester, _loanPreset);
    await tap(tester, t(l.expTypeExpense));
    await tap(tester, t(l.expCategory));
    await tap(tester, t('식비'));
    await tap(tester, btn(l.actionSave));
    final b = cap.lastBody!;
    for (final k in ['toAssetRowId', 'fee', 'interestAmount']) {
      expect(b.containsKey(k), isTrue, reason: k);
      expect(b[k], isNull, reason: k);
    }
    expect(b['categoryRowId'], 1);
  });

  testWidgets('T3 이체 본문 — 받는 · 보내는 계좌 · 수수료 · 이자 · 금액이 그대로 나간다', (
    tester,
  ) async {
    final cap = await open(tester, _loanPreset);
    await tap(tester, btn(l.actionSave));
    final b = cap.lastBody!;
    expect(b['assetRowId'], 7);
    expect(b['toAssetRowId'], 9);
    expect(b['fee'], 500);
    expect(b['interestAmount'], 20000);
    expect(b['amount'], 300000);
    expect(b['lockAmount'], 'Y');
    expect(b['categoryRowId'], isNull);
  });

  testWidgets('T1 자산을 받기 전에 저장해도 본문 이자는 읽어 온 그대로', (tester) async {
    final cap = await open(
      tester,
      _loanPreset,
      assets: Completer<List<Asset>>().future,
    );
    await tap(tester, btn(l.actionSave));
    expect(cap.lastBody!['interestAmount'], 20000);
    expect(cap.lastBody!['toAssetRowId'], 9);
  });

  testWidgets('T4 새 프리셋 — 이름 · 카테고리 · 금액을 넣으면 lockAmount Y + amount', (
    tester,
  ) async {
    final cap = await open(tester, null);
    await tester.enterText(find.byType(EditableText).first, '커피');
    await tap(tester, t(l.expCategory));
    await tap(tester, t('식비'));
    await step(tester, l.presetAmountLabel, '4500');
    expect(t('4,500원'), findsOneWidget);
    await tap(tester, btn(l.presetSubmitAdd));
    expect(cap.lastBody!['lockAmount'], 'Y');
    expect(cap.lastBody!['amount'], 4500);
    expect(cap.lastBody!['categoryRowId'], 1);
  });

  testWidgets('T5 하위 있는 상위는 고르기 목록의 제목이고 고르는 줄은 하위다', (tester) async {
    await open(tester, null);
    await tap(tester, t(l.expCategory));
    expect(t('교통'), findsOneWidget, reason: '상위 제목이 있다');
    expect(t('버스'), findsOneWidget);
    expect(
      find.ancestor(of: t('교통'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('T6 저장 실패 — 폼은 닫히지 않고 맨 위 Callout 고정 글(서버 원문 없음)', (
    tester,
  ) async {
    final cap = await open(tester, _loanPreset, status: 400);
    await tap(tester, btn(l.actionSave));
    expect(cap.requests, hasLength(1));
    expect(t(l.presetSaveFailed), findsOneWidget);
    expect(t(l.presetEditTitle), findsOneWidget, reason: '시트가 그대로');
  });

  testWidgets('D3 보내는 계좌를 받는 계좌와 같게 고르면 받는 계좌가 비고, 저장하면 칸 아래 글', (
    tester,
  ) async {
    final cap = await open(tester, _loanPreset);
    await tap(tester, t(l.presetFromAccount));
    await tap(tester, t('대출'));
    expect(t(l.presetFromAccount), findsOneWidget);
    await tap(tester, btn(l.actionSave));
    expect(t(l.presetToRequired), findsOneWidget);
    expect(cap.requests, isEmpty);
  });

  testWidgets('D4 카드 계좌인 지출 프리셋을 이체로 바꾸면 보내는 계좌를 비우고 칸 아래 글', (tester) async {
    final cap = await open(
      tester,
      const ExpenseTemplate(
        rowId: 5,
        templateName: '점심',
        expenseType: 'EXPENSE',
        categoryRowId: 1,
        assetRowId: 10,
      ),
    );
    await tap(tester, t(l.expTypeTransfer));
    await tap(tester, btn(l.actionSave));
    expect(t(l.presetFromRequired), findsOneWidget);
    expect(cap.requests, isEmpty);
  });

  testWidgets('D4 지운 계좌를 가리키는 프리셋은 받았는데 없으면 비운다(옛 id 가 나가지 않는다)', (
    tester,
  ) async {
    final cap = await open(
      tester,
      const ExpenseTemplate(
        rowId: 5,
        templateName: '점심',
        expenseType: 'EXPENSE',
        categoryRowId: 1,
        assetRowId: 99,
      ),
    );
    await tap(tester, btn(l.actionSave));
    expect(cap.lastBody!.containsKey('assetRowId'), isTrue);
    expect(cap.lastBody!['assetRowId'], isNull);
  });

  testWidgets('D4 하위가 생겨 상위가 된 카테고리는 비우고 칸 아래 글', (tester) async {
    final cap = await open(
      tester,
      const ExpenseTemplate(
        rowId: 5,
        templateName: '점심',
        expenseType: 'EXPENSE',
        categoryRowId: 2,
      ),
    );
    await tap(tester, btn(l.actionSave));
    expect(t(l.presetCategoryRequired), findsOneWidget);
    expect(cap.requests, isEmpty);
  });

  testWidgets('D4 이자가 금액보다 크면 이자 칸 아래 글 · 요청 0', (tester) async {
    final cap = await open(tester, _loanPreset);
    await step(tester, l.presetAmountLabel, '10000');
    await tap(tester, btn(l.actionSave));
    expect(t(l.presetInterestTooLarge), findsOneWidget);
    expect(cap.requests, isEmpty);
  });

  testWidgets('100억 넘는 옛 금액은 저장을 누르면 칸 아래 글', (tester) async {
    final cap = await open(
      tester,
      const ExpenseTemplate(
        rowId: 5,
        templateName: '점심',
        expenseType: 'EXPENSE',
        categoryRowId: 1,
        amount: 20000000000,
        lockAmount: 'Y',
      ),
    );
    await tap(tester, btn(l.actionSave));
    expect(t(l.amountTooLarge), findsOneWidget);
    expect(cap.requests, isEmpty);
  });

  testWidgets('D5 12자 넘는 옛 이름은 이름을 안 바꾸면 저장된다', (tester) async {
    final cap = await open(
      tester,
      const ExpenseTemplate(
        rowId: 5,
        templateName: '아주아주 긴 옛 프리셋 이름입니다',
        expenseType: 'EXPENSE',
        categoryRowId: 1,
      ),
    );
    await tap(tester, btn(l.actionSave));
    expect(cap.requests, hasLength(1));
  });

  testWidgets('D6 수수료 0 은 없음 · null 로 나간다(웹과 같다)', (tester) async {
    final cap = await open(tester, _loanPreset);
    await step(tester, l.presetFeeLabel, '0');
    expect(t(l.presetNoneValue), findsWidgets);
    expect(t('0원'), findsNothing);
    await tap(tester, btn(l.actionSave));
    expect(cap.lastBody!.containsKey('fee'), isTrue);
    expect(cap.lastBody!['fee'], isNull);
  });

  testWidgets('지운 카테고리를 가리키는 프리셋은 열기만 해서 닫을 때는 안 묻는다', (tester) async {
    await open(
      tester,
      const ExpenseTemplate(
        rowId: 5,
        templateName: '점심',
        expenseType: 'EXPENSE',
        categoryRowId: 99,
      ),
    );
    await tap(tester, find.bySemanticsLabel(l.actionClose).first);
    expect(t(l.sheetLeaveTitle), findsNothing);
  });
}
