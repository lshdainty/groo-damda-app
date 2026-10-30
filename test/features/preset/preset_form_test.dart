// 프리셋 추가 · 수정 폼(I-20 C 19) — 시트를 실제로 조작해 **무엇을 보내는가** 를 잠근다.
// 금액은 "고정 금액 사용" 스위치 없이 줄 하나다: 금액 > 0 ⇔ lockAmount Y, 비우면 N + 이자도 비운다.
// 비운 칸(거래처 · 메모 · 결제 수단 · 계좌)은 명시적 null 로 실려야 지워진다(서버가 키가 없으면 유지로 읽는다).
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

const _food = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
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
  sortOrder: 0,
  parentRowId: 2,
);
const _bank = Asset(
  rowId: 7,
  assetName: '주거래',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(rowId: 8, assetName: '비상금', assetType: 'SAVINGS');
const _loan = Asset(rowId: 9, assetName: '대출', assetType: 'LOAN');
const _card = Asset(rowId: 10, assetName: '신용카드', assetType: 'CREDIT_CARD');

const _filled = ExpenseTemplate(
  rowId: 5,
  templateName: '점심 도시락',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
  assetRowId: 7,
  merchant: '김밥천국',
  paymentMethod: 'CARD',
  description: '회사 근처',
  amount: 4500,
  lockAmount: 'Y',
);
const _loanTransfer = ExpenseTemplate(
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

class _Repo extends PresetRepository {
  _Repo() : super(Dio());
  Map<String, Object?>? sent;
  Patch<int> assetRowId = const Patch.keep();
  Patch<String> merchant = const Patch.keep();
  Patch<String> paymentMethod = const Patch.keep();
  Patch<String> description = const Patch.keep();
  Patch<int> interestAmount = const Patch.keep();
  bool? lock;
  int? amountSent;

  @override
  Future<ExpenseTemplate> update({
    required int id,
    required String templateName,
    int? categoryRowId,
    Patch<int> assetRowId = const Patch.keep(),
    Patch<int> toAssetRowId = const Patch.keep(),
    Patch<int> fee = const Patch.keep(),
    Patch<int> interestAmount = const Patch.keep(),
    required String expenseType,
    int? amount,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    bool lockAmount = false,
    bool isFixed = false,
    bool silent = false,
  }) async {
    sent = {'id': id, 'silent': silent};
    this.assetRowId = assetRowId;
    this.merchant = merchant;
    this.paymentMethod = paymentMethod;
    this.description = description;
    this.interestAmount = interestAmount;
    lock = lockAmount;
    amountSent = amount;
    return _filled;
  }

  @override
  Future<ExpenseTemplate> create({
    required String templateName,
    int? categoryRowId,
    int? assetRowId,
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    required String expenseType,
    int? amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? sortOrder,
    bool lockAmount = false,
    bool isFixed = false,
    bool silent = false,
  }) async {
    sent = {'name': templateName, 'category': categoryRowId, 'silent': silent};
    lock = lockAmount;
    amountSent = amount;
    return _filled;
  }
}

Future<_Repo> _open(
  WidgetTester tester,
  ExpenseTemplate? edit, {
  Future<List<Asset>>? assetsFuture,
}) async {
  final repo = _Repo();
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
          (ref) async => [_food, _parent, _child],
        ),
        assetsProvider.overrideWith(
          (ref) async => [_bank, _savings, _loan, _card],
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
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Finder _t(String s) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('⁠', '') == s,
);
Finder _btn(String s) => find.widgetWithText(PButton, s).last;

Future<void> _step(WidgetTester tester, String row, String text) async {
  await tester.tap(_t(row).first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(EditableText).first, text);
  await tester.tap(_btn('완료'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  testWidgets('고정 금액 스위치가 없고 금액은 줄 하나다 — 비었으면 "비워 둠"', (tester) async {
    await _open(tester, null);
    expect(find.text('고정 금액 사용'), findsNothing);
    expect(_t(l.presetAmountLabel), findsOneWidget);
    expect(_t(l.presetAmountBlank), findsOneWidget);
  });

  testWidgets('금액을 넣으면 lockAmount Y + amount, 안 건드리면 지금 값 그대로', (tester) async {
    final repo = await _open(tester, _filled);
    expect(_t('4,500원'), findsOneWidget);
    await tester.tap(_btn(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.lock, isTrue);
    expect(repo.amountSent, 4500);
    expect(repo.merchant.value, '김밥천국');
    expect(repo.paymentMethod.value, 'CARD');
    expect(repo.assetRowId.value, 7);
    expect(repo.description.value, '회사 근처');
    expect(repo.sent!['silent'], isTrue, reason: '전역 서버 원문 토스트를 끈다');
  });

  testWidgets('금액을 비우면 lockAmount N + amount 키 없음', (tester) async {
    final repo = await _open(tester, _filled);
    await _step(tester, l.presetAmountLabel, '');
    expect(_t(l.presetAmountBlank), findsOneWidget);
    await tester.tap(_btn(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.lock, isFalse);
    expect(repo.amountSent, isNull);
  });

  testWidgets('거래처 · 메모를 지우면 명시적 null 로 실린다', (tester) async {
    final repo = await _open(tester, _filled);
    await _step(tester, l.presetMerchant, '');
    await _step(tester, l.expDescription, '');
    await tester.tap(_btn(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.merchant.present, isTrue);
    expect(repo.merchant.value, isNull);
    expect(repo.description.present, isTrue);
    expect(repo.description.value, isNull);
  });

  testWidgets('계좌 · 결제 수단을 "없음" 으로 고르면 명시적 null', (tester) async {
    final repo = await _open(tester, _filled);
    await tester.tap(_t(l.presetAssetCard).first);
    await tester.pumpAndSettle();
    await tester.tap(_t(l.presetNoAccount).first);
    await tester.pumpAndSettle();
    await tester.tap(_t(l.expPaymentMethod).first);
    await tester.pumpAndSettle();
    await tester.tap(_t(l.presetNoPayment).last);
    await tester.pumpAndSettle();
    await tester.tap(_btn(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.assetRowId.present, isTrue);
    expect(repo.assetRowId.value, isNull);
    expect(repo.paymentMethod.present, isTrue);
    expect(repo.paymentMethod.value, isNull);
  });

  testWidgets('빈 채 추가를 누르면 칸 아래에 알리고 요청은 0', (tester) async {
    final repo = await _open(tester, null);
    await tester.tap(_btn(l.presetSubmitAdd));
    await tester.pumpAndSettle();
    expect(_t(l.presetNameRequired), findsOneWidget);
    expect(_t(l.presetCategoryRequired), findsOneWidget);
    expect(repo.sent, isNull);
  });

  testWidgets('이체는 보내는 · 받는 계좌를 칸 아래에 알린다', (tester) async {
    final repo = await _open(tester, null);
    await tester.tap(_t(l.expTypeTransfer).first);
    await tester.pumpAndSettle();
    await tester.tap(_btn(l.presetSubmitAdd));
    await tester.pumpAndSettle();
    expect(_t(l.presetFromRequired), findsOneWidget);
    expect(_t(l.presetToRequired), findsOneWidget);
    expect(repo.sent, isNull);
  });

  testWidgets('하위 있는 상위는 고르기 목록에서 제목이고 고를 수 없다', (tester) async {
    await _open(tester, null);
    await tester.tap(_t(l.expCategory).first);
    await tester.pumpAndSettle();
    expect(_t('식비'), findsWidgets);
    expect(_t('버스'), findsOneWidget);
    // 상위 "교통" 은 목록 제목 — 누르는 줄(PListButtonItem)이 아니다
    expect(
      find.ancestor(of: _t('교통'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('금액을 비우면 이자도 비운다(이자는 금액을 따라간다)', (tester) async {
    final repo = await _open(tester, _loanTransfer);
    expect(_t(l.expInterest), findsOneWidget);
    await _step(tester, l.presetAmountLabel, '');
    expect(_t(l.expInterest), findsNothing, reason: '금액이 없으면 이자 줄이 없다');
    await tester.tap(_btn(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.interestAmount.present, isTrue);
    expect(repo.interestAmount.value, isNull);
  });

  testWidgets('한 단계에서 친 글을 버리면 묻고, 안 바꿨으면 묻지 않는다', (tester) async {
    await _open(tester, _filled);
    await tester.tap(_t(l.presetMerchant).first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(l.actionBack).first);
    await tester.pumpAndSettle();
    expect(_t(l.sheetLeaveTitle), findsNothing);
    await tester.tap(_t(l.presetMerchant).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '다른 곳');
    await tester.tap(find.bySemanticsLabel(l.actionBack).first);
    await tester.pumpAndSettle();
    expect(_t(l.sheetLeaveTitle), findsOneWidget);
  });

  // 웹 20-2 후속에서 찾은 순서 문제 — 자산을 받기 전에는 "받는 계좌가 대출인가" 를 모른다. 모르는 채로 이자를 지우거나 저장에서 빼면
  // 자산이 온 뒤에도 비어 이자가 사라진다.
  testWidgets('자산이 오기 전에 저장해도 읽어 온 이자는 그대로 실린다', (tester) async {
    final late = Completer<List<Asset>>();
    final repo = await _open(tester, _loanTransfer, assetsFuture: late.future);
    await tester.tap(_btn(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.interestAmount.present, isTrue);
    expect(repo.interestAmount.value, 20000);
  });

  testWidgets('자산이 오기 전에 다른 칸을 고쳐도 이자 줄이 지워지지 않는다', (tester) async {
    final late = Completer<List<Asset>>();
    await _open(tester, _loanTransfer, assetsFuture: late.future);
    await _step(tester, l.expDescription, '메모');
    expect(_t(l.expInterest), findsOneWidget);
    late.complete([_bank, _savings, _loan, _card]);
    await tester.pumpAndSettle();
    expect(_t(l.expInterest), findsOneWidget, reason: '자산이 온 뒤에도 대출 이자 줄이 남는다');
  });
}
