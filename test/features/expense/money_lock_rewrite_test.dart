// 결제가 끝난 카드 거래의 돈 칸 잠금(D12)과 [고쳐 쓰기](D13).
//
// 결제일이 된 회차분이 있는 카드 거래는 금액·날짜·시간·자산·할부·유형·통화 3칸·
// 결제수단을 못 고친다. 카테고리·가맹점·메모는 고친다. 돈 칸을 바꾸려면 [고쳐 쓰기] 가
// 같은 값이 채워진 새 거래 시트를 열고, 저장은 `POST /expense/{id}/replace` 다.
// 여기서 잠그는 것은
//   ① 잠긴 거래의 편집 시트 — 돈 칸 전부 회색, 안내 + [고쳐 쓰기], 분류 칸은 열림
//   ② 잠긴 거래의 저장은 묻지 않고, 돈 칸을 원래 값 그대로 돌려보낸다(서버가 "바뀌었다"
//      로 안 보게)
//   ③ [고쳐 쓰기] 저장 = replace 본문(생성 본문 + 적재한 분할) · 확인창 두 갈래 · 토스트
//   ④ 열린 회차 거래는 지금처럼 고친다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/patch.dart';
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
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_date_input.dart';
import 'package:groo_damda_app/shared/widgets/p_select.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../../support/plain_text.dart';

/// 결제일 12일 카드 — 8월분(9/12 결제)까지 닫혔다.
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

/// 닫힌 회차의 카드 지출 — 서버가 잠갔다. 시각에 초가 있다(되돌려 보낼 때 깎이면 안 된다).
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
  expenseDate: '2026-08-20T10:00:37',
  moneyLocked: true,
);

class _Call {
  _Call(this.kind, this.args);
  final String kind;
  final Map<String, Object?> args;
}

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  final calls = <_Call>[];

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
    List<SplitInput>? splits,
    Patch<bool> isFixed = const Patch.keep(),
    bool silent = false,
  }) async {
    calls.add(
      _Call('update', {
        'id': id,
        'categoryRowId': categoryRowId,
        'assetRowId': assetRowId,
        'expenseType': expenseType,
        'amount': amount,
        'expenseDate': expenseDate,
        'merchant': merchant,
        'paymentMethod': paymentMethod,
        'installmentMonths': installmentMonths,
        'originalCurrency': originalCurrency,
        'splits': splits,
      }),
    );
    return _locked;
  }

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
    calls.add(
      _Call('replace', {
        'id': id,
        'assetRowId': assetRowId,
        'amount': amount,
        'expenseDate': expenseDate,
        'merchant': merchant,
        'paymentMethod': paymentMethod,
        'splits': splits,
      }),
    );
    return _locked.copyWith(rowId: 78, amount: amount, moneyLocked: false);
  }
}

Future<_FakeRepo> _open(
  WidgetTester tester,
  Expense edit, {
  List<ExpenseSplit> splits = const [],
  Asset card = _card,
}) async {
  final repo = _FakeRepo();
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        assetsProvider.overrideWith((ref) async => [card]),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => splits),
        hideCardProvider.overrideWith((ref, card) => false),
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        // 앱과 같은 자리 — 결과 스낵바(ds)가 뜨는 호스트
        builder: (context, child) => Material(
          type: MaterialType.transparency,
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
        ),
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
  return repo;
}

/// 컨트롤러 글자로 찾는 입력칸 — 금액·날짜 칸.
Finder _fieldWith(String text) => find.byWidgetPredicate(
  (w) => w is EditableText && w.controller.text == text,
);

/// 줄 칸이 막혔나 — 막힌 줄은 누름이 없다(값은 보인다).
bool _rowLocked(WidgetTester tester, String key) =>
    tester
        .widget<PListButtonItem>(
          find.descendant(
            of: find.byKey(ValueKey('tx-row-$key')),
            matching: find.byType(PListButtonItem),
          ),
        )
        .onTap ==
    null;

/// 금액 줄 › 한 단계에서 값을 바꾸고 "완료".
Future<void> _setAmount(WidgetTester tester, String v) async {
  await tester.tap(find.byKey(const ValueKey('tx-row-amount')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(EditableText).first, v);
  await tester.pump();
  await tester.tap(findText('완료'));
  await tester.pumpAndSettle();
}

Finder _submit(String label) =>
    find.ancestor(of: findText(label), matching: find.byType(PButton)).last;

void main() {
  group('잠긴 거래의 편집 시트(D12)', () {
    testWidgets('돈 칸은 전부 회색이고 분류 칸은 열려 있다', (tester) async {
      await _open(tester, _locked);

      // 돈 칸(금액 · 계좌 · 결제 수단 · 할부 · 날짜)은 막힌 줄 — 값은 보이고 누름이 없다
      expect(_rowLocked(tester, 'amount'), isTrue);
      expect(_rowLocked(tester, 'asset'), isTrue);
      expect(_rowLocked(tester, 'method'), isTrue);
      expect(find.byType(FormPiece), findsNothing, reason: '날짜 조각이 없다(막힌 줄)');
      // 분류 칸(거래처 · 카테고리 · 메모)은 열려 있다
      expect(_rowLocked(tester, 'category'), isFalse);
      expect(tester.widget<EditableText>(_fieldWith('버스')).readOnly, isFalse);

      expect(
        findText('결제가 끝난 거래예요. 금액 · 날짜를 바꾸려면 고쳐 쓰기를 눌러주세요'),
        findsOneWidget,
      );
      expect(findText('고쳐 쓰기'), findsOneWidget);
    });

    testWidgets('서버 플래그가 없어도 닫힌 회차 카드 거래면 잠근다', (tester) async {
      await _open(tester, _locked.copyWith(moneyLocked: false));

      expect(_rowLocked(tester, 'amount'), isTrue);
      expect(findText('고쳐 쓰기'), findsOneWidget);
    });

    testWidgets('열린 회차 거래는 지금처럼 고친다', (tester) async {
      await _open(
        tester,
        _locked.copyWith(
          moneyLocked: false,
          expenseDate: '2026-09-10T10:00:00',
        ),
      );

      expect(_rowLocked(tester, 'amount'), isFalse);
      expect(findText('고쳐 쓰기'), findsNothing);
    });

    // 잠긴 거래는 카테고리·가맹점·메모만 바뀐다 — 통장에 일어나는 일이 없으니 묻지
    // 않고 바로 저장한다(사용자 결정 2026-09-21). 확인창은 돈과 기록이 갈리는 자리에만.
    testWidgets('저장은 확인 없이 한 번에, 돈 칸은 원래 값 그대로 돌려보낸다', (tester) async {
      final repo = await _open(tester, _locked);

      await tester.enterText(_fieldWith('버스'), '시내버스');
      await tester.pump();
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(findTextContaining('이미 결제가 끝난 회차예요'), findsNothing);
      expect(repo.calls, hasLength(1));

      final args = repo.calls.single.args;
      expect(repo.calls.single.kind, 'update');
      expect(args['amount'], 40000);
      expect(
        args['expenseDate'],
        '2026-08-20T10:00:37',
        reason: '초를 깎아 보내면 서버가 날짜가 바뀌었다고 본다',
      );
      expect((args['assetRowId']! as Patch<int>).present, isFalse);
      expect((args['paymentMethod']! as Patch<String>).present, isFalse);
      expect((args['installmentMonths']! as Patch<int>).present, isFalse);
      expect((args['originalCurrency']! as Patch<String>).present, isFalse);
      expect((args['merchant']! as Patch<String>).value, '시내버스');
      expect(args['splits'], isNull);
    });
  });

  group('[고쳐 쓰기](D13)', () {
    Future<void> openRewrite(WidgetTester tester) async {
      await tester.tap(findText('고쳐 쓰기'));
      await tester.pumpAndSettle();
    }

    testWidgets('같은 값이 채워진 새 거래 시트가 열리고 돈 칸이 풀린다', (tester) async {
      await _open(tester, _locked);
      await openRewrite(tester);

      // 편집 시트는 닫히고 고쳐 쓰기 시트가 열렸다(제목 + 버튼 라벨이 같은 말).
      expect(findText('거래 수정'), findsNothing);
      expect(findText('고쳐 쓰기'), findsOneWidget);
      expect(_rowLocked(tester, 'amount'), isFalse);
      expect(_fieldWith('버스'), findsOneWidget);
      expect(find.byType(FormPiece), findsWidgets, reason: '날짜 조각이 열린다');
      expect(find.byKey(const ValueKey('money-lock-note')), findsNothing);
      expect(
        tester
            .widget<PChip>(find.byKey(const ValueKey('tx-type-TRANSFER')))
            .onPressed,
        isNull,
        reason: 'replace 본문은 지출·수입 생성 본문이다',
      );
    });

    testWidgets('닫힌 회차로 고쳐 쓰면 기록만 바뀐다고 묻고 replace 로 보낸다', (tester) async {
      final repo = await _open(tester, _locked);
      await openRewrite(tester);

      await _setAmount(tester, '45000');
      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();

      expect(
        findText('원래 거래는 지워지고 새 거래로 바뀌어요. 기록만 바뀌고 계좌 잔액은 그대로예요.'),
        findsOneWidget,
      );
      await tester.tap(findText('저장').last);
      await tester.pumpAndSettle();

      final call = repo.calls.single;
      expect(call.kind, 'replace');
      expect(call.args['id'], 77);
      expect(call.args['amount'], 45000);
      expect(call.args['assetRowId'], 9);
      expect(call.args['expenseDate'], '2026-08-20T10:00:00');
      expect(call.args['paymentMethod'], 'CARD');
      expect(call.args['splits'], isNull, reason: '분할이 없으면 키를 빼고 서버가 옮긴다');
      // 결제가 끝난 회차 거래를 고쳐 썼다 — 결제계좌 잔액을 고칠 길을 준다(D9).
      expect(findText('결제가 끝난 회차라 기록만 바뀌고 계좌 잔액은 그대로예요.'), findsOneWidget);
      expect(findText('잔액 고치기'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    });

    // 결제일 변경이 대기 중인 카드 — 9월분이 아직 옛 결제일(10/20)로 나간다. 지금
    // 결제일(12일)로 세면 "10월 12일" 이라는 틀린 날짜를 말한다(QA 26 4).
    testWidgets('물러나면 보내지 않는다', (tester) async {
      final repo = await _open(tester, _locked);
      await openRewrite(tester);

      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();
      await tester.tap(findText('취소').last);
      await tester.pumpAndSettle();

      expect(repo.calls, isEmpty);
    });

    testWidgets('적재한 분할을 본문에 싣는다', (tester) async {
      final repo = await _open(
        tester,
        _locked,
        splits: const [
          ExpenseSplit(
            rowId: 1,
            expenseRowId: 77,
            categoryRowId: 11,
            amount: 30000,
            label: '출근',
            sortOrder: 0,
          ),
          ExpenseSplit(
            rowId: 2,
            expenseRowId: 77,
            categoryRowId: 11,
            amount: 10000,
            label: '퇴근',
            sortOrder: 1,
          ),
        ],
      );
      await openRewrite(tester);

      await tester.tap(_submit('저장'));
      await tester.pumpAndSettle();
      await tester.tap(findText('저장').last);
      await tester.pumpAndSettle();

      final splits = repo.calls.single.args['splits']! as List<SplitInput>;
      expect([for (final s in splits) s.amount], [30000, 10000]);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    });

    testWidgets('금액을 바꿔 분할 합과 어긋나면 저장을 막는다', (tester) async {
      await _open(
        tester,
        _locked,
        splits: const [
          ExpenseSplit(
            rowId: 1,
            expenseRowId: 77,
            categoryRowId: 11,
            amount: 40000,
            sortOrder: 0,
          ),
        ],
      );
      await openRewrite(tester);

      await _setAmount(tester, '45000');

      // 저장은 켜 둔다 — 누르면 요청 없이 "나눈 내역 맞추기" 로 간다(Callout 이 먼저 말한다)
      expect(find.byKey(const ValueKey('tx-split-mismatch')), findsOneWidget);
      expect(findText('나눈 내역 맞추고 저장'), findsOneWidget);
    });
  });

  group('replace 본문', () {
    (Dio, List<RequestOptions>) capturing() {
      final seen = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen.add(options);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'code': 'COMMON_200',
                  'message': 'OK',
                  'data': {
                    'rowId': 78,
                    'expenseType': 'EXPENSE',
                    'amount': 45000,
                    'refundedAmount': 5000,
                  },
                },
              ),
            );
          },
        ),
      );
      return (dio, seen);
    }

    test('POST /expense/{id}/replace — 생성 본문과 같은 칸', () async {
      final (dio, seen) = capturing();

      final saved = await ExpenseRepository(dio).replace(
        77,
        categoryRowId: 11,
        assetRowId: 9,
        expenseType: 'EXPENSE',
        amount: 45000,
        expenseDate: '2026-09-10T10:00:00',
        merchant: '버스',
        paymentMethod: 'CARD',
      );

      expect(seen.single.method, 'POST');
      expect(seen.single.path, '/expense/77/replace');
      expect(seen.single.data, {
        'categoryRowId': 11,
        'assetRowId': 9,
        'expenseType': 'EXPENSE',
        'amount': 45000,
        'expenseDate': '2026-09-10T10:00:00',
        'merchant': '버스',
        'paymentMethod': 'CARD',
      });
      expect(saved.rowId, 78, reason: '응답은 새 거래다');
      expect(saved.refundedAmount, 5000);
    });

    test('분할을 넘기면 splits 로 싣는다', () async {
      final (dio, seen) = capturing();

      await ExpenseRepository(dio).replace(
        77,
        categoryRowId: 11,
        expenseType: 'EXPENSE',
        amount: 40000,
        expenseDate: '2026-08-20T10:00:00',
        splits: const [
          SplitInput(categoryRowId: 11, amount: 30000, label: '출근'),
          SplitInput(categoryRowId: 12, amount: 10000),
        ],
      );

      final body = seen.single.data as Map<String, dynamic>;
      expect(body['splits'], [
        {'categoryRowId': 11, 'amount': 30000, 'label': '출근'},
        {'categoryRowId': 12, 'amount': 10000},
      ]);
    });
  });
}
