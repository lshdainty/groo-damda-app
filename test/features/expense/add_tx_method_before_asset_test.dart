// 거래 추가 · 수정 2단계 — 결제 수단 줄이 계좌 · 카드 줄보다 **먼저** 온다(사용자 결정 2026-11-10).
//
// 결제 수단을 먼저 고르면 그 수단에 맞는 계좌 · 카드만 후보로 나온다(`allowTxAsset`). 여기서 잠그는 것은
//   ① 줄 순서 — 카테고리 → 결제 수단(수입은 수입 방식) → 계좌 · 카드(수입은 입금 계좌) → 할부 → 날짜 → 메모 (추가 · 수정)
//   ② 수단별 후보 — 카드는 카드만, 현금은 현금만, 계좌이체는 입출금만(지출에서 적금 제외), 기타는 가리지 않는다
//   ③ 맞는 게 없으면 "이 결제 수단에 맞는 계좌 · 카드가 없어요."
//   ④ 결제 수단을 바꾸면 안 맞는 계좌 · 카드는 비워지고 맞는 것은 남는다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

class _Repo extends ExpenseRepository {
  _Repo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));
}

const _expCat = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);
const _incCat = ExpenseCategory(
  rowId: 6,
  categoryName: '월급',
  expenseType: 'INCOME',
  sortOrder: 1,
  icon: 'wallet',
  color: '#2c70bf',
);

Asset _a(int id, String name, String type) => Asset(
  rowId: id,
  assetName: name,
  assetType: type,
  balance: 100000,
  isIncludedInTotal: 'Y',
);

final _bank = _a(1, '주거래통장', 'BANK_ACCOUNT');
final _savings = _a(2, '비상적금', 'SAVINGS');
final _cash = _a(3, '지갑현금', 'CASH');
final _credit = _a(4, '신용카드A', 'CREDIT_CARD');
final _check = _a(5, '체크카드B', 'CHECK_CARD');
final _all = [_bank, _savings, _cash, _credit, _check];

Future<void> _open(
  WidgetTester tester, {
  List<Asset>? assets,
  Expense? edit,
}) async {
  tester.view.physicalSize = const Size(1170, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_expCat, _incCat]),
        assetsProvider.overrideWith((ref) async => assets ?? _all),
        presetListProvider.overrideWith((ref) async => []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        expenseRepositoryProvider.overrideWith((ref) async => _Repo()),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAddTxSheet(ctx, edit: edit),
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

/// 추가 흐름 — 1단계 금액(+ 종류) → [다음] → 2단계.
Future<void> _toStepTwo(WidgetTester tester, {bool income = false}) async {
  if (income) {
    await tester.tap(find.byKey(const ValueKey('tx-type-INCOME')));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byType(EditableText).first, '12000');
  await tester.tap(findText('다음'));
  await tester.pumpAndSettle();
}

const _method = ValueKey('tx-row-method');
const _asset = ValueKey('tx-row-asset');

double _y(WidgetTester tester, Key k) => tester.getTopLeft(find.byKey(k)).dy;

void _expectOrder(WidgetTester tester) {
  final cat = _y(tester, const ValueKey('tx-row-category'));
  final method = _y(tester, _method);
  final asset = _y(tester, _asset);
  final date = _y(tester, const ValueKey('tx-row-date'));
  final memo = _y(tester, const ValueKey('tx-row-memo'));
  expect(cat < method, isTrue, reason: '카테고리 → 결제 수단');
  expect(method < asset, isTrue, reason: '결제 수단 → 계좌 · 카드');
  expect(asset < date, isTrue, reason: '계좌 · 카드 → 날짜');
  expect(date < memo, isTrue, reason: '날짜 → 메모');
}

Future<void> _pickMethod(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(_method));
  await tester.pumpAndSettle();
  await tester.tap(findText(label).last);
  await tester.pumpAndSettle();
}

/// 계좌 · 카드 시트를 열어 후보 이름들을 돌려주고 닫는다.
Future<List<String>> _assetCandidates(WidgetTester tester) async {
  await tester.tap(find.byKey(_asset));
  await tester.pumpAndSettle();
  final names = [
    for (final a in _all)
      if (findText(a.assetName).evaluate().isNotEmpty) a.assetName,
  ];
  return names;
}

Future<void> _closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

String _rowValueText(WidgetTester tester, Key k) => [
  for (final e
      in find
          .descendant(of: find.byKey(k), matching: find.byType(Text))
          .evaluate())
    plainOf(
      (e.widget as Text).data ??
          (e.widget as Text).textSpan?.toPlainText() ??
          '',
    ),
].join('|');

void main() {
  testWidgets('추가 · 지출 — 결제 수단 줄이 계좌 · 카드 줄 위에 있다', (tester) async {
    await _open(tester);
    await _toStepTwo(tester);
    _expectOrder(tester);
  });

  testWidgets('추가 · 수입 — 수입 방식 줄이 입금 계좌 줄 위에 있다', (tester) async {
    await _open(tester);
    await _toStepTwo(tester, income: true);
    expect(findText('수입 방식'), findsOneWidget);
    expect(findText('입금 계좌'), findsOneWidget);
    _expectOrder(tester);
  });

  testWidgets('수정 — 같은 순서다', (tester) async {
    await _open(
      tester,
      edit: const Expense(
        rowId: 50,
        categoryRowId: 5,
        assetRowId: 1,
        expenseType: 'EXPENSE',
        amount: 12000,
        expenseDate: '2026-11-10',
        paymentMethod: 'TRANSFER',
      ),
    );
    _expectOrder(tester);
  });

  testWidgets('수단별 후보 — 카드 · 현금 · 계좌이체 · 기타', (tester) async {
    final cases = <String, List<String>>{
      '카드': ['신용카드A', '체크카드B'],
      '현금': ['지갑현금'],
      '계좌이체': ['주거래통장'], // 지출 — 적금은 결제 · 출금이 안 나간다
      '기타': ['주거래통장', '지갑현금', '신용카드A', '체크카드B'],
    };
    for (final e in cases.entries) {
      await _open(tester);
      await _toStepTwo(tester);
      await _pickMethod(tester, e.key);
      expect(await _assetCandidates(tester), e.value, reason: e.key);
      expect(findText('이 결제 수단에 맞는 계좌 · 카드가 없어요.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('맞는 계좌 · 카드가 없으면 안내를 띄운다', (tester) async {
    await _open(tester, assets: [_bank]);
    await _toStepTwo(tester);
    await _pickMethod(tester, '카드');
    expect(await _assetCandidates(tester), isEmpty);
    expect(findText('이 결제 수단에 맞는 계좌 · 카드가 없어요.'), findsOneWidget);
    // 결제 수단을 안 고른 상태면 안내가 없다
    await _closeSheet(tester);
    await _pickMethod(tester, '결제 수단 없음');
    await tester.tap(find.byKey(_asset));
    await tester.pumpAndSettle();
    expect(findText('주거래통장'), findsOneWidget);
    expect(findText('이 결제 수단에 맞는 계좌 · 카드가 없어요.'), findsNothing);
  });

  testWidgets('수입 — 맞는 입금 계좌가 없으면 수입 말로 안내한다(지출 문구는 안 나온다)', (tester) async {
    await _open(tester, assets: [_bank]);
    await _toStepTwo(tester, income: true);
    await _pickMethod(tester, '카드');
    expect(await _assetCandidates(tester), isEmpty);
    expect(findText('이 수입 방식에 맞는 입금 계좌가 없어요.'), findsOneWidget);
    expect(findText('이 결제 수단에 맞는 계좌 · 카드가 없어요.'), findsNothing);
  });

  testWidgets('결제 수단을 바꾸면 안 맞는 계좌 · 카드는 비워지고 맞는 것은 남는다', (tester) async {
    await _open(tester);
    await _toStepTwo(tester);
    await _pickMethod(tester, '기타');
    await tester.tap(find.byKey(_asset));
    await tester.pumpAndSettle();
    await tester.tap(findText('주거래통장').last);
    await tester.pumpAndSettle();
    expect(_rowValueText(tester, _asset), contains('주거래통장'));

    // 카드로 바꾸면 통장은 안 맞아 비워진다
    await _pickMethod(tester, '카드');
    expect(_rowValueText(tester, _asset), isNot(contains('주거래통장')));
    expect(_rowValueText(tester, _asset), contains('계좌 · 카드 없음'));

    // 맞는 카드를 고른 뒤 다시 카드(같은 수단)로 바꿔도 남는다 — 계좌이체로 바꾸면 비워진다
    await tester.tap(find.byKey(_asset));
    await tester.pumpAndSettle();
    await tester.tap(findText('신용카드A').last);
    await tester.pumpAndSettle();
    expect(_rowValueText(tester, _asset), contains('신용카드A'));
    await _pickMethod(tester, '기타');
    expect(
      _rowValueText(tester, _asset),
      contains('신용카드A'),
      reason: '기타는 가리지 않는다',
    );
    await _pickMethod(tester, '계좌이체');
    expect(_rowValueText(tester, _asset), isNot(contains('신용카드A')));
  });
}
