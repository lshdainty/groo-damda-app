// 고쳐 쓰기(D13)의 가장자리 셋 — QA 26 3·5 · 확인 필요(분할 로딩).
//
//   ① 서버가 교체를 받지 않는 잠긴 거래(중도 정리한 할부, `replaceable: false`)엔 버튼이
//      없고, 안내도 없는 버튼을 가리키지 않는다. 판정이 없는 옛 서버면 잠금으로 본다
//   ② 교체가 404(옛 거래가 이미 없다)면 가계부·자산을 다시 읽게 하고 시트를 닫는다 —
//      응답만 못 받고 다시 눌렀을 때 옛 행이 남아 보이지 않게. 그 밖의 실패는 시트를 둔다
//   ③ 원거래의 분할을 다 불러오기 전엔 저장을 막는다 — 빈 채로 나가면 서버가 옛 분할을
//      옮겨, 금액을 바꿨다면 합이 안 맞아 400 이다
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/data/expense_split_repository.dart';
import 'package:groo_damda_app/features/expense_split/domain/expense_split.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';

const _lockedNote = '결제가 끝난 거래예요. 금액·날짜를 바꾸려면 고쳐 쓰기를 눌러주세요';
const _paidOffNote = '결제가 끝난 거래예요. 중도 정리한 할부라 금액·날짜를 바꿀 수 없어요.';

const _card = Asset(
  rowId: 9,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 12,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);

const _category = ExpenseCategory(
  rowId: 11,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

/// 닫힌 회차의 카드 지출 — 서버가 잠갔다.
const _locked = Expense(
  rowId: 77,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 40000,
  merchant: '버스',
  paymentMethod: 'CARD',
  expenseDate: '2026-08-20T10:00:00',
  moneyLocked: true,
);

class _FakeRepo extends ExpenseRepository {
  _FakeRepo({this.replaceError})
    : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  final ApiException? replaceError;
  int replaced = 0;

  @override
  Future<Expense> replace(
    int id, {
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
    List<SplitInput>? splits,
    bool? isFixed,
    bool silent = false,
  }) async {
    replaced++;
    final err = replaceError;
    if (err != null) throw err;
    return _locked.copyWith(rowId: 78, amount: amount, moneyLocked: false);
  }
}

/// 가계부 한 달을 지켜보는 자리 — 다시 읽혔는지 센다.
int _monthFetches = 0;

Future<_FakeRepo> _open(
  WidgetTester tester,
  Expense edit, {
  _FakeRepo? repo,
  Future<List<ExpenseSplit>> Function()? splits,
}) async {
  final r = repo ?? _FakeRepo();
  _monthFetches = 0;
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => r),
        assetsProvider.overrideWith((ref) async => const [_card]),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith(
          (ref, id) => splits?.call() ?? Future.value(const <ExpenseSplit>[]),
        ),
        monthExpensesProvider.overrideWith((ref, key) async {
          _monthFetches++;
          return const <Expense>[];
        }),
        hideCardProvider.overrideWith((ref, card) => false),
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Consumer(
            builder: (ctx, ref, _) {
              // 가계부 화면처럼 한 달을 지켜본다 — 무효화되면 다시 읽는다.
              ref.watch(monthExpensesProvider((year: 2026, month: 8)));
              return TextButton(
                onPressed: () => showAddTxSheet(ctx, edit: edit),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return r;
}

Finder _submit(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<void> _openRewrite(WidgetTester tester) async {
  await tester.tap(find.text('고쳐 쓰기'));
  await tester.pumpAndSettle();
}

void main() {
  group('① 고쳐 쓸 수 없는 잠긴 거래', () {
    testWidgets('replaceable=false 면 버튼이 없고 안내가 그 이유를 말한다', (tester) async {
      await _open(
        tester,
        _locked.copyWith(installmentMonths: 3, replaceable: false),
      );

      expect(find.text(_paidOffNote), findsOneWidget);
      expect(find.text(_lockedNote), findsNothing);
      expect(find.text('고쳐 쓰기'), findsNothing);
    });

    testWidgets('replaceable=true 면 버튼과 종전 안내', (tester) async {
      await _open(tester, _locked.copyWith(replaceable: true));

      expect(find.text(_lockedNote), findsOneWidget);
      expect(find.text('고쳐 쓰기'), findsOneWidget);
    });

    testWidgets('판정이 없는 옛 서버면 잠금으로 본다 — 버튼이 있다', (tester) async {
      await _open(tester, _locked);

      expect(find.text(_lockedNote), findsOneWidget);
      expect(find.text('고쳐 쓰기'), findsOneWidget);
    });
  });

  group('② 교체 실패의 뒷정리', () {
    testWidgets('404 면 가계부를 다시 읽게 하고 시트를 닫는다', (tester) async {
      final repo = _FakeRepo(
        replaceError: ApiException(
          code: 'EXPENSE_NOT_FOUND',
          message: '거래를 찾을 수 없어요',
          statusCode: 404,
        ),
      );
      await _open(tester, _locked, repo: repo);
      await _openRewrite(tester);
      final before = _monthFetches;

      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();

      expect(repo.replaced, 1);
      expect(find.text('고쳐 쓰기'), findsNothing, reason: '시트가 닫혔다');
      expect(_monthFetches, greaterThan(before), reason: '목록을 다시 읽었다');
    });

    testWidgets('그 밖의 실패는 시트를 둔다 — 고친 값을 잃지 않는다', (tester) async {
      final repo = _FakeRepo(
        replaceError: ApiException(
          code: 'EXP_047',
          message: '중도 정리한 할부는 고쳐 쓸 수 없어요',
          statusCode: 400,
        ),
      );
      await _open(tester, _locked, repo: repo);
      await _openRewrite(tester);

      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();

      expect(repo.replaced, 1);
      expect(find.text('고쳐 쓰기'), findsOneWidget, reason: '시트가 그대로다');
      expect(
        tester.widget<PButton>(_submit('저장')).onPressed,
        isNotNull,
        reason: '다시 시도할 수 있다',
      );
    });
  });

  group('③ 분할을 불러오는 동안', () {
    testWidgets('고쳐 쓰기 저장이 막혀 있다가 다 불러오면 풀린다', (tester) async {
      final pending = Completer<List<ExpenseSplit>>();
      await _open(tester, _locked, splits: () => pending.future);
      await _openRewrite(tester);

      expect(tester.widget<PButton>(_submit('저장')).onPressed, isNull);

      pending.complete(const [
        ExpenseSplit(
          rowId: 1,
          expenseRowId: 77,
          categoryRowId: 11,
          amount: 40000,
          sortOrder: 0,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(tester.widget<PButton>(_submit('저장')).onPressed, isNotNull);
    });

    testWidgets('못 불러왔으면 막지 않는다 — 서버가 옛 분할로 판정한다', (tester) async {
      await _open(
        tester,
        _locked,
        splits: () => Future.error(Exception('network')),
      );
      await _openRewrite(tester);

      expect(tester.widget<PButton>(_submit('저장')).onPressed, isNotNull);
    });
  });
}
