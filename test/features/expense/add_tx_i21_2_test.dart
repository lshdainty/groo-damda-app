// I-21 21-2 — 거래 추가 · 수정 두 단계 폼.
//
// 잠그는 것: 1단계(빈 금액 [다음] = 칸 오류 · 요청 0) · 2단계 제목 · ← 로 1단계(값 유지) · 프리셋(금액 있음 = 2단계 · 빈 금액 = 1단계에 남음 ·
// 칩 모두 outlineWeak · 적용한 칩만 selected · 금액 칸 잠금 없음) · 외화 원화 줄(H1: 원화만 바뀐다) · 이자 > 금액은 요청 전에 막힘(M4) ·
// 저장 실패는 시트 안 Callout + silent 요청(M1) · 바뀐 채 닫기는 묻는다(M3).
//
// 작성만 했다 — 로컬에서 돌리지 않는다(UI 이관이 끝날 때까지 시험 실행 금지).
import 'dart:async';

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
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

const _cat = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);
const _bank = Asset(
  rowId: 10,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);
const _loan = Asset(
  rowId: 11,
  assetName: '전세대출',
  assetType: 'LOAN',
  balance: -5000000,
  isIncludedInTotal: 'Y',
);

const _fixedPreset = ExpenseTemplate(
  rowId: 1,
  templateName: '점심',
  expenseType: 'EXPENSE',
  categoryRowId: 5,
  amount: 9000,
  lockAmount: 'Y',
  useCount: 3,
);
const _emptyPreset = ExpenseTemplate(
  rowId: 2,
  templateName: '커피',
  expenseType: 'EXPENSE',
  categoryRowId: 5,
  amount: 0,
  lockAmount: 'N',
  useCount: 1,
);

const _card = Asset(
  rowId: 12,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  balance: -1000,
  isIncludedInTotal: 'Y',
);

const _installTx = Expense(
  rowId: 78,
  categoryRowId: 5,
  assetRowId: 12,
  expenseType: 'EXPENSE',
  amount: 120000,
  expenseDate: '2026-10-20T12:00:00',
  merchant: '가전',
  paymentMethod: 'CARD',
  installmentMonths: 12,
);

const _foreignTx = Expense(
  rowId: 77,
  categoryRowId: 5,
  assetRowId: 10,
  expenseType: 'EXPENSE',
  amount: 7425,
  expenseDate: '2026-10-01T12:00:00',
  merchant: 'Cafe',
  originalAmount: 5.5,
  originalCurrency: 'USD',
  exchangeRate: 1350,
);

class _Repo extends ExpenseRepository {
  _Repo() : super(Dio());
  final calls = <Map<String, Object?>>[];
  bool fail = false;

  @override
  Future<Expense> create({
    required int categoryRowId,
    int? assetRowId,
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
    bool? isFixed,
    bool silent = false,
  }) async {
    calls.add({
      'op': 'create',
      'amount': amount,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'exchangeRate': exchangeRate,
      'silent': silent,
    });
    if (fail) throw ApiException(code: 'X', message: 'x', statusCode: 500);
    return _foreignTx;
  }

  @override
  Future<Expense> update({
    required int id,
    required int categoryRowId,
    Patch<int> assetRowId = const Patch.keep(),
    required String expenseType,
    required int amount,
    required String expenseDate,
    Patch<String> description = const Patch.keep(),
    Patch<String> merchant = const Patch.keep(),
    Patch<String> paymentMethod = const Patch.keep(),
    Patch<int> installmentMonths = const Patch.keep(),
    Patch<double> originalAmount = const Patch.keep(),
    Patch<String> originalCurrency = const Patch.keep(),
    Patch<double> exchangeRate = const Patch.keep(),
    Patch<bool> isFixed = const Patch.keep(),
    List<SplitInput>? splits,
    bool silent = false,
  }) async {
    calls.add({
      'op': 'update',
      'amount': amount,
      'originalAmount': originalAmount.value,
      'exchangeRate': exchangeRate.value,
      'installment': installmentMonths.value,
      'installmentPresent': installmentMonths.present,
      'silent': silent,
    });
    if (fail) throw ApiException(code: 'X', message: 'x', statusCode: 500);
    return _foreignTx.copyWith(amount: amount);
  }
}

class _TransferRepo extends AssetRepository {
  _TransferRepo() : super(Dio());
  final updates = <Map<String, Object?>>[];

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
    updates.add({'interest': interestAmount, 'fee': fee, 'amount': amount});
  }
}

const _loanTransfer = AssetTransfer(
  rowId: 31,
  fromAssetRowId: 10,
  toAssetRowId: 11,
  amount: 900000,
  interestAmount: 120000,
  principalAmount: 780000,
  transferDate: '2026-10-25T10:00:00',
);

Future<_Repo> _open(
  WidgetTester tester,
  void Function(BuildContext) show, {
  List<ExpenseTemplate> presets = const [],
  bool assetsFail = false,
  Future<List<Asset>>? assetsLate,
  Future<List<ExpenseCategory>>? categoriesLate,
  Size size = const Size(1170, 2532),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final repo = _Repo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_cat]),
        assetsProvider.overrideWith(
          (ref) async =>
              assetsFail ? throw Exception('network') : [_bank, _loan],
        ),
        presetListProvider.overrideWith((ref) async => presets),
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        assetRepositoryProvider.overrideWith(
          (ref) async => AssetRepository(Dio()),
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
              onPressed: () => show(ctx),
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
  testWidgets('빈 금액에서 [다음] 은 칸 오류를 내고 2단계로 가지 않는다', (tester) async {
    await _open(tester, (c) => showAddTxSheet(c));
    expect(find.text('1 / 2단계'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('금액을 입력해주세요.'), findsOneWidget);
    expect(find.text('1 / 2단계'), findsOneWidget);
  });

  testWidgets('금액을 치고 [다음] → 2단계 제목 · ← 는 1단계로(값 유지)', (tester) async {
    await _open(tester, (c) => showAddTxSheet(c));
    await tester.enterText(find.byType(EditableText).first, '12000');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.textContaining('지출 12'), findsOneWidget);
    expect(find.text('2 / 2단계'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('뒤로').first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2단계'), findsOneWidget);
    expect(find.text('12000'), findsOneWidget);
  });

  testWidgets('프리셋 — 금액 있음은 2단계로, 빈 금액은 1단계에 남고 금액 칸이 잠기지 않는다', (tester) async {
    await _open(
      tester,
      (c) => showAddTxSheet(c),
      presets: const [_fixedPreset, _emptyPreset],
    );
    // 칩 묶음은 한 변형(outlineWeak)
    final chips = tester.widgetList<PChip>(
      find.descendant(
        of: find.byKey(const ValueKey('tx-preset-chips')),
        matching: find.byType(PChip),
      ),
    );
    expect(chips.every((c) => c.variant == PChipVariant.outlineWeak), isTrue);
    await tester.tap(find.byKey(const ValueKey('tx-preset-chip-2')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2단계'), findsOneWidget);
    expect(find.textContaining('금액이 비어 있어요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tx-preset-chip-1')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2단계'), findsOneWidget);
    // 금액을 고치러 ← — 금액 칸은 잠기지 않았다
    await tester.tap(find.bySemanticsLabel('뒤로').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '12000');
    expect(find.text('12000'), findsOneWidget);
    // 적용한 칩만 selected
    final after = tester
        .widgetList<PChip>(
          find.descendant(
            of: find.byKey(const ValueKey('tx-preset-chips')),
            matching: find.byType(PChip),
          ),
        )
        .toList();
    expect(after.where((c) => c.selected).length, 1);
  });

  testWidgets('H1 — 외화 거래에서 원화 금액 줄은 원화만 고친다', (tester) async {
    final repo = await _open(
      tester,
      (c) => showAddTxSheet(c, edit: _foreignTx),
    );
    await tester.tap(find.byKey(const ValueKey('tx-row-krw')));
    await tester.pumpAndSettle();
    // 현지 금액 칸이 아니라 원화 전용 칸 — 통화 칩이 없다
    expect(find.byKey(const ValueKey('tx-currency-chip')), findsNothing);
    await tester.enterText(find.byType(EditableText).first, '7500');
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final c = repo.calls.single;
    expect(c['amount'], 7500);
    expect(c['originalAmount'], 5.5);
    expect(c['exchangeRate'], 1350);
    expect(c['silent'], isTrue);
  });

  testWidgets('M1 — 저장 실패는 시트 안 Callout 이고 고친 값이 남는다', (tester) async {
    final repo = await _open(
      tester,
      (c) => showAddTxSheet(c, edit: _foreignTx),
    );
    repo.fail = true;
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
    expect(repo.calls.single['silent'], isTrue);
    expect(find.text('거래 수정'), findsOneWidget);
  });

  testWidgets('M3 — 바뀐 채 닫으면 묻는다', (tester) async {
    await _open(tester, (c) => showAddTxSheet(c));
    await tester.enterText(find.byType(EditableText).first, '500');
    await tester.tap(find.bySemanticsLabel('닫기').first);
    await tester.pumpAndSettle();
    expect(find.text('작성한 내용이 사라져요'), findsOneWidget);
  });

  testWidgets('M3 — 안 바꿨으면 바로 닫힌다', (tester) async {
    await _open(tester, (c) => showAddTxSheet(c));
    await tester.tap(find.bySemanticsLabel('닫기').first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2단계'), findsNothing);
  });

  testWidgets('수정은 2단계로 바로 열리고 종류 칩은 지금 종류 하나다', (tester) async {
    await _open(tester, (c) => showAddTxSheet(c, edit: _foreignTx));
    expect(find.text('거래 수정'), findsOneWidget);
    expect(find.text('1 / 2단계'), findsNothing);
    expect(
      tester
          .widget<PChip>(find.byKey(const ValueKey('tx-type-INCOME')))
          .onPressed,
      isNull,
      reason: '막힌 칩은 보이되 비활성이다',
    );
  });

  testWidgets('쉼표가 보이는 외화 금액 · 환율도 요청에는 쉼표 없는 숫자로 나간다', (tester) async {
    final repo = await _open(tester, (c) => showAddTxSheet(c));
    // 통화 칩 → USD → 현지 금액 → [다음] → 환율 → 카테고리 → [추가]
    await tester.tap(find.byKey(const ValueKey('tx-currency-chip')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PListButtonItem && w.title.contains('USD'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '98765.43');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(1), '1388.75');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('tx-row-category')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PListButtonItem && w.title.contains('식비'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    final c = repo.calls.single;
    expect(c['originalAmount'], 98765.43);
    expect(c['exchangeRate'], 1388.75);
    expect(c['originalCurrency'], 'USD');
    expect(c['amount'], 137160491, reason: '현지 × 환율 = 원화(쉼표 없는 정수)');
  });

  testWidgets('N2 — 프리셋 저장에서 금액 줄을 열었다 닫아도 ← 는 1단계, 저장 뒤에도 연 단계로 간다', (
    tester,
  ) async {
    await _open(tester, (c) => showAddTxSheet(c));
    await tester.enterText(find.byType(EditableText).first, '9000');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tx-row-category')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PListButtonItem && w.title.contains('식비'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('뒤로').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('현재 입력값 저장'));
    await tester.pumpAndSettle();
    // 금액 › → 완료 → 프리셋 저장 단계로 돌아온다
    await tester.tap(find.byKey(const ValueKey('tx-preset-amount-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.text('프리셋으로 저장'), findsOneWidget);
    // ← → 연 단계(1단계)
    await tester.tap(find.bySemanticsLabel('뒤로').first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2단계'), findsOneWidget);
  });

  testWidgets('N1 — 자산 목록을 못 받으면 저장 요청을 보내지 않고 Callout 을 낸다', (tester) async {
    final repo = await _open(
      tester,
      (c) => showAddTxSheet(c, edit: _foreignTx),
      assetsFail: true,
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty, reason: '값을 추측해 보내지 않는다');
    expect(find.text('저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
  });

  testWidgets('N1 — 자산 목록이 오기 전에 이체 수정을 저장해도 이자가 본문에 남는다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final late = Completer<List<Asset>>();
    final repo = _TransferRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => [_cat]),
          assetsProvider.overrideWith((ref) => late.future),
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
                onPressed: () =>
                    showAddTxSheet(ctx, editTransfer: _loanTransfer),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 500));
    // 목록이 오기 전에 [저장]
    await tester.tap(find.text('저장'));
    await tester.pump();
    late.complete([_bank, _loan]);
    await tester.pumpAndSettle();

    expect(repo.updates, hasLength(1));
    expect(
      repo.updates.single['interest'],
      120000,
      reason: '목록이 없다고 이자를 지우지 않는다',
    );
  });

  testWidgets('N1 — 자산 목록이 늦게 와도 할부가 본문에 남는다(신용카드 지출)', (tester) async {
    final late = Completer<List<Asset>>();
    final repo = await _open(
      tester,
      (c) => showAddTxSheet(c, edit: _installTx),
      assetsLate: late.future,
    );
    await tester.tap(find.text('저장'));
    await tester.pump();
    late.complete([_bank, _loan, _card]);
    await tester.pumpAndSettle();
    // 닫힌 회차 확인창이 뜰 수 있다 — 뜨면 [저장]
    if (find.text('저장할까요?').evaluate().isNotEmpty ||
        find.text('거래 수정').evaluate().length > 1) {
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();
    }
    final c = repo.calls.single;
    expect(c['installmentPresent'], isTrue);
    expect(c['installment'], 12, reason: '목록이 늦게 와도 할부를 지우지 않는다');
  });

  testWidgets('카테고리 목록이 늦게 오는 동안 "지운 카테고리" 로 보이지 않는다', (tester) async {
    final late = Completer<List<ExpenseCategory>>();
    await _open(
      tester,
      (c) => showAddTxSheet(c, edit: _foreignTx),
      categoriesLate: late.future,
    );
    expect(find.text('지운 카테고리'), findsNothing);
    late.complete([_cat]);
    await tester.pumpAndSettle();
    expect(find.text('지운 카테고리'), findsNothing);
    expect(find.textContaining('식비'), findsWidgets);
  });

  testWidgets('M1 — 내려간 채 저장이 실패하면 본문이 맨 위로 올라가 Callout 이 보인다', (tester) async {
    final repo = await _open(
      tester,
      (c) => showAddTxSheet(c, edit: _foreignTx),
      size: const Size(1170, 1500),
    );
    final scrollable = find
        .descendant(
          of: find.byType(PBottomSheetContent),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.drag(scrollable, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );
    repo.fail = true;
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
    expect(find.text('저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
  });

  testWidgets('자산 목록을 기다리는 동안 [추가] 를 두 번 눌러도 요청은 한 번이다', (tester) async {
    final late = Completer<List<Asset>>();
    final repo = await _open(
      tester,
      (c) => showAddTxSheet(c, edit: _foreignTx),
      assetsLate: late.future,
    );
    await tester.tap(find.text('저장'));
    await tester.pump();
    await tester.tap(find.text('저장'), warnIfMissed: false);
    await tester.pump();
    late.complete([_bank, _loan, _card]);
    await tester.pumpAndSettle();
    expect(repo.calls, hasLength(1), reason: '같은 거래가 둘 저장되면 안 된다');
  });

  testWidgets('자산 목록을 기다리는 동안 이체 수정 [저장] 을 두 번 눌러도 요청은 한 번이다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final late = Completer<List<Asset>>();
    final repo = _TransferRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => [_cat]),
          assetsProvider.overrideWith((ref) => late.future),
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
                onPressed: () =>
                    showAddTxSheet(ctx, editTransfer: _loanTransfer),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('저장'));
    await tester.pump();
    await tester.tap(find.text('저장'), warnIfMissed: false);
    await tester.pump();
    late.complete([_bank, _loan]);
    await tester.pumpAndSettle();
    expect(repo.updates, hasLength(1));
  });
}
