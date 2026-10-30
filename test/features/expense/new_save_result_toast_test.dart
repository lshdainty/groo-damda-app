// 새 거래·문자 저장 뒤의 결과 토스트(QA 26 1) — 웹 `notifyResult(created, …)` 미러.
//
// 생성 응답에도 선결제 환급액(`refundedAmount`)이 실린다 — 열린 회차에 카드 수입을 넣어
// 미리 낸 돈이 청구보다 많아지면 서버가 그만큼 결제계좌로 돌려준다(D3). 앱은 생성 응답을
// 버려 통장이 움직였는데 아무 말이 없었다. 여기서 잠그는 것은
//   ① 새 저장 응답에 환급액이 있으면 "미리 낸 돈 중 N원이 계좌로 돌아왔어요"(D4)
//   ② 결제가 끝난 회차로 들어간 새 입력은 저장 뒤 토스트가 없다 — [잔액 고치기](D9)는 환불·
//      삭제·고쳐 쓰기의 자리다(웹 `notifyResult(created)` 도 같다). 저장 전 확인창이 이미 말했다
//   ③ 열린 회차 + 환급 없음이면 조용하다
//   ④ 문자 저장도 같은 토스트다(응답의 환급액은 서버가 실어 줄 때만)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';

const _closedLine = '이미 결제가 끝난 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요.';

/// 결제일 12일 카드 — 8월분(9/12 결제)까지 닫혔다. 결제계좌 3.
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

class _FakeRepo extends ExpenseRepository {
  _FakeRepo({this.refundedAmount})
    : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  final int? refundedAmount;
  int created = 0;

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
    created++;
    return Expense(
      rowId: 100,
      categoryRowId: categoryRowId,
      assetRowId: assetRowId,
      expenseType: expenseType,
      amount: amount,
      expenseDate: expenseDate,
      refundedAmount: refundedAmount,
    );
  }
}

class _FakeSmsRepo extends SmsRepository {
  _FakeSmsRepo({this.refundedAmount}) : super(Dio());

  final int? refundedAmount;
  int committed = 0;

  @override
  Future<SmsCommitResult> commit({
    required String text,
    required int? assetRowId,
    required int? categoryRowId,
    required String expenseType,
    required int amount,
    String? merchant,
    String? description,
    required String expenseDate,
    String? paymentMethod,
    int? installmentMonths,
    num? originalAmount,
    String? originalCurrency,
    num? exchangeRate,
    required bool rememberCard,
    bool silent = false,
  }) async {
    committed++;
    return SmsCommitResult(
      expenseRowId: 100,
      cardRemembered: false,
      refundedAmount: refundedAmount,
    );
  }
}

Future<void> _open(
  WidgetTester tester, {
  required String date,
  _FakeRepo? repo,
  _FakeSmsRepo? smsRepo,
  SmsDraft? draft,
  List<Asset> assets = const [_card],
}) async {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith(
          (ref) async => repo ?? _FakeRepo(),
        ),
        smsRepositoryProvider.overrideWith(
          (ref) async => smsRepo ?? _FakeSmsRepo(),
        ),
        assetsProvider.overrideWith((ref) async => assets),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
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
                  showAddTxSheet(ctx, defaultDate: date, smsDraft: draft),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 금액 · 카테고리 · 카드를 채운다(문자 초안은 이미 채워져 온다).
Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, '13000');
  await tester.pump();
  await tester.tap(find.text('식비').last);
  await tester.pumpAndSettle();
  await _pickCard(tester);
}

Future<void> _pickCard(WidgetTester tester) async {
  // '선택 안 함' 이 둘(결제 수단·자산)이라 마지막 것이 자산이다.
  await tester.tap(find.text('선택 안 함').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('현대카드').last);
  await tester.pumpAndSettle();
}

Finder _submit(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

/// 토스트가 스스로 닫히게 둔다 — 남은 타이머가 있으면 테스트가 끝나며 실패한다.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('새 저장 응답에 환급액이 있으면 알린다(D4)', (tester) async {
    final repo = _FakeRepo(refundedAmount: 30000);
    await _open(tester, date: '2026-09-10', repo: repo);
    await _fill(tester);

    await tester.tap(_submit('추가'));
    await tester.pumpAndSettle();

    expect(repo.created, 1);
    expect(find.text('미리 낸 돈 중 30,000원이 계좌로 돌아왔어요'), findsOneWidget);
    expect(find.text('잔액 고치기'), findsNothing, reason: '열린 회차 — 통장이 이미 맞다');
    await _drain(tester);
  });

  testWidgets('열린 회차에 환급도 없으면 조용하다', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, date: '2026-09-10', repo: repo);
    await _fill(tester);

    await tester.tap(_submit('추가'));
    await tester.pumpAndSettle();

    expect(repo.created, 1);
    expect(find.textContaining('계좌로 돌아왔어요'), findsNothing);
    expect(find.text(_closedLine), findsNothing);
  });

  testWidgets('닫힌 회차 새 입력은 저장 전 확인창만 — 저장 뒤 토스트·[잔액 고치기] 없음', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, date: '2026-08-20', repo: repo);
    await _fill(tester);

    await tester.tap(_submit('추가'));
    await tester.pumpAndSettle();
    // 저장 전 확인창(같은 한 문구) — 저장.
    expect(find.text(_closedLine), findsOneWidget);
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();

    expect(repo.created, 1);
    expect(find.text(_closedLine), findsNothing, reason: '저장 뒤 토스트 없음');
    expect(find.text('잔액 고치기'), findsNothing);
  });

  testWidgets('결제계좌 없는 카드의 닫힌 회차 입력은 버튼도 토스트도 없다', (tester) async {
    final repo = _FakeRepo();
    await _open(
      tester,
      date: '2026-08-20',
      repo: repo,
      assets: [_card.copyWith(paymentAssetRowId: null)],
    );
    await _fill(tester);

    await tester.tap(_submit('추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();

    expect(repo.created, 1);
    expect(find.text(_closedLine), findsNothing);
    expect(find.text('잔액 고치기'), findsNothing);
  });

  group('문자 저장', () {
    const draft = SmsDraft(
      text: '[Web발신] 현대카드 승인 13,000원 스타벅스',
      parsed: SmsParseResult(
        matched: true,
        confidence: 'HIGH',
        cancel: false,
        amount: 13000,
        merchant: '스타벅스',
        categoryRowId: 11,
        categoryName: '식비',
        expenseDate: '2026-08-20T10:00:00',
        assetRemembered: true,
        assetCandidates: [],
      ),
    );

    testWidgets('닫힌 회차여도 저장 뒤 토스트·[잔액 고치기] 는 없다', (tester) async {
      final sms = _FakeSmsRepo();
      await _open(tester, date: '2026-08-20', smsRepo: sms, draft: draft);
      await _pickCard(tester);

      await tester.tap(_submit('추가'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();

      expect(sms.committed, 1);
      expect(find.text(_closedLine), findsNothing);
      expect(find.text('잔액 고치기'), findsNothing);
    });

    testWidgets('응답에 환급액이 실리면 알린다', (tester) async {
      final sms = _FakeSmsRepo(refundedAmount: 4000);
      await _open(
        tester,
        date: '2026-09-10',
        smsRepo: sms,
        draft: const SmsDraft(
          text: '[Web발신] 현대카드 승인 13,000원 스타벅스',
          parsed: SmsParseResult(
            matched: true,
            confidence: 'HIGH',
            cancel: false,
            amount: 13000,
            merchant: '스타벅스',
            categoryRowId: 11,
            categoryName: '식비',
            expenseDate: '2026-09-10T10:00:00',
            assetRemembered: true,
            assetCandidates: [],
          ),
        ),
      );
      await _pickCard(tester);

      await tester.tap(_submit('추가'));
      await tester.pumpAndSettle();

      expect(sms.committed, 1);
      expect(find.text('미리 낸 돈 중 4,000원이 계좌로 돌아왔어요'), findsOneWidget);
      await _drain(tester);
    });
  });

  test('문자 저장 응답의 환급액은 있으면 읽고 없으면 null', () {
    expect(
      SmsCommitResult.fromJson({
        'expenseRowId': 1,
        'cardRemembered': false,
        'refundedAmount': 4000,
      }).refundedAmount,
      4000,
    );
    expect(
      SmsCommitResult.fromJson({
        'expenseRowId': 1,
        'cardRemembered': false,
      }).refundedAmount,
      isNull,
    );
  });
}
