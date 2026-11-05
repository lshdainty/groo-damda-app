// 카드 상세의 닫힌 회차 — 머리는 **지금 기록 합**, 실제로 나간 돈과 다를 때만 한 줄(D10).
//
// 여기서 잠그는 것은
//   ① 머리 세 갈래 — 기록 > 낸 돈 / 기록 < 낸 돈 / 낸 돈 0("결제 완료" 대신 "기록 회차")
//   ② 닫힌 회차에서는 [지금 결제] 가 없다 — 그 회차는 더 낼 것이 없다
//   ③ 닫힌 회차의 할부 회차분 한 줄("2/3회차 · 원금 … · 기록만"), 정리 버튼 없음
//   ④ [결제 취소] 는 닫힌 회차·환급 나간 회차의 결제면 숨는다(D6)
//   ⑤ 이용 내역 행이 가계부와 같은 행 — "환불됨"·"기록만" 배지·취소선(A3)
//   ⑥ 결제일 없는 카드는 "결제일을 넣어주세요"(D8)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/domain/card_billing.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_performance.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

const _card = Asset(
  rowId: 9,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 12,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);

/// 8월 회차(9/12 결제) — 닫힌 회차.
ClosedCycle _august({
  required int paid,
  required int recorded,
  List<InstallmentDue> dues = const [],
}) => ClosedCycle(
  periodStart: '2026-08-01',
  periodEnd: '2026-08-31',
  paymentDate: '2026-09-12',
  paidAmount: paid,
  recordedAmount: recorded,
  installmentDues: dues,
);

BillingItem _payment({
  required int rowId,
  required String periodStart,
  required String periodEnd,
  required String paymentDate,
  String status = 'COMPLETED',
}) => BillingItem(
  rowId: rowId,
  cardAssetRowId: 9,
  billingAmount: 50000,
  periodStart: periodStart,
  periodEnd: periodEnd,
  paymentDate: paymentDate,
  status: status,
);

Future<void> _open(
  WidgetTester tester, {
  required CardBilling billing,
  Asset card = _card,
  List<Expense> usage = const [],
}) async {
  tester.view.physicalSize = const Size(1500, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [card]),
        hideCardProvider.overrideWith((ref, c) => false),
        cardBillingProvider.overrideWith((ref, id) async => billing),
        cardPerformanceProvider.overrideWith(
          (ref, key) async => const CardPerformance(
            assetRowId: 9,
            yearMonth: '2026-09',
            isRequired: false,
            currentAmount: 0,
            achievementRate: 0,
            isAchieved: false,
          ),
        ),
        assetBalanceTrendProvider.overrideWith((ref, key) async => const []),
        assetTransfersProvider.overrideWith(
          (ref, key) async => const <AssetTransfer>[],
        ),
        expensesByAssetProvider.overrideWith((ref, key) async => usage),
        assetPeriodExpensesProvider.overrideWith((ref, key) async => usage),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetDetailRich(ctx, card),
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

/// 머리 금액 — 숫자와 단위가 따로 그려진다(RichText).
Finder _head(String amount) => find.byWidgetPredicate(
  (w) => w is Text && (w.semanticsLabel ?? w.data) == '$amount원',
);

void main() {
  group('닫힌 회차 머리 — 지금 기록 합', () {
    testWidgets('기록이 더 많으면 나간 돈과 나머지를 말한다', (tester) async {
      await _open(
        tester,
        billing: CardBilling(
          cardAssetRowId: 9,
          upcomingAmount: 0,
          closedCycles: [_august(paid: 100000, recorded: 155000)],
        ),
      );

      expect(_head('155,000'), findsOneWidget);
      expect(find.text('결제 완료'), findsOneWidget);
      expect(
        find.text('계좌에서 나간 돈은 100,000원이에요. 나머지 55,000원은 기록만 남긴 금액이에요'),
        findsOneWidget,
      );
    });

    testWidgets('기록이 더 적으면 기록과 나간 돈을 말한다', (tester) async {
      await _open(
        tester,
        billing: CardBilling(
          cardAssetRowId: 9,
          upcomingAmount: 0,
          closedCycles: [_august(paid: 100000, recorded: 70000)],
        ),
      );

      expect(_head('70,000'), findsOneWidget);
      expect(find.text('기록은 70,000원인데 계좌에서는 100,000원이 나갔어요'), findsOneWidget);
    });

    testWidgets('낸 돈이 0 이면 "결제 완료" 대신 "기록 회차"', (tester) async {
      await _open(
        tester,
        billing: CardBilling(
          cardAssetRowId: 9,
          upcomingAmount: 0,
          closedCycles: [_august(paid: 0, recorded: 25000)],
        ),
      );

      expect(_head('25,000'), findsOneWidget);
      expect(find.text('기록 회차'), findsOneWidget);
      expect(find.text('결제 완료'), findsNothing);
      // "계좌에서 나간 돈은 0원이에요…" 는 "기록 회차" 와 같은 말이라 붙이지 않는다.
      expect(
        find.byKey(const ValueKey('closed-cycle-paid-line')),
        findsNothing,
      );
      expect(find.textContaining('0원이에요'), findsNothing);
    });

    testWidgets('같으면 아래 한 줄이 없다', (tester) async {
      await _open(
        tester,
        billing: CardBilling(
          cardAssetRowId: 9,
          upcomingAmount: 0,
          closedCycles: [_august(paid: 100000, recorded: 100000)],
        ),
      );

      expect(
        find.byKey(const ValueKey('closed-cycle-paid-line')),
        findsNothing,
      );
      expect(find.text('결제 완료'), findsOneWidget);
    });

    testWidgets('옛 서버(기록 합 없음)면 결제액 + 기록만 금액이 머리다', (tester) async {
      await _open(
        tester,
        billing: const CardBilling(
          cardAssetRowId: 9,
          upcomingAmount: 0,
          closedCycles: [
            ClosedCycle(
              periodStart: '2026-08-01',
              periodEnd: '2026-08-31',
              paymentDate: '2026-09-12',
              paidAmount: 100000,
              recordedOnlyAmount: 25000,
            ),
          ],
        ),
      );

      expect(_head('125,000'), findsOneWidget);
    });
  });

  testWidgets('닫힌 회차에서는 [지금 결제] 가 없다', (tester) async {
    await _open(
      tester,
      billing: CardBilling(
        cardAssetRowId: 9,
        upcomingAmount: 0,
        closedCycles: [_august(paid: 100000, recorded: 100000)],
      ),
    );

    expect(find.text('지금 결제'), findsNothing);
    // 한도 · 결제 설정 타일은 없다 — 수정은 머리 하나(I-17 47)
    expect(find.text('한도 · 결제 설정'), findsNothing);
  });

  const upcomingBilling = CardBilling(
    cardAssetRowId: 9,
    upcomingAmount: 40000,
    nextPaymentDate: '2026-10-12',
    upcomingPeriodStart: '2026-09-01',
    upcomingPeriodEnd: '2026-09-30',
  );

  // I-17 53 — 주 버튼을 막지 않고, 누르면 칸 아래에 오류가 뜬다.
  testWidgets('[지금 결제] 시트 — 0 원 · 예정액 초과는 누르면 칸 아래 오류', (tester) async {
    await _open(tester, billing: upcomingBilling);
    await tester.tap(find.text('지금 결제'));
    await tester.pumpAndSettle();

    expect(find.textContaining('결제 예정액 40,000원을 지금 결제할까요?'), findsOneWidget);
    expect(find.textContaining('10월 12일 결제 예정분이에요.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();
    expect(find.text('결제 금액을 넣어주세요.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '50000');
    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();
    expect(find.text('결제 금액은 40,000원까지예요.'), findsOneWidget);
  });

  // I-17 54 — 고르기 시트: 연도 머리 + 라디오 줄, 누르면 바로 고르고 닫힌다.
  testWidgets('회차 단추는 결제 회차 고르기 시트를 연다', (tester) async {
    await _open(tester, billing: upcomingBilling);
    await tester.tap(find.text('10월 12일 결제'));
    await tester.pumpAndSettle();

    expect(find.text('결제 회차'), findsOneWidget);
    expect(find.text('2026년'), findsOneWidget);
    expect(find.text('예정'), findsWidgets);

    await tester.tap(find.text('10월 12일 결제').last);
    await tester.pumpAndSettle();
    expect(find.text('결제 회차'), findsNothing);
  });

  testWidgets('다가오는 회차에서는 [지금 결제] 가 있다', (tester) async {
    await _open(
      tester,
      billing: const CardBilling(
        cardAssetRowId: 9,
        upcomingAmount: 40000,
        nextPaymentDate: '2026-10-12',
        upcomingPeriodStart: '2026-09-01',
        upcomingPeriodEnd: '2026-09-30',
      ),
    );

    expect(find.text('지금 결제'), findsOneWidget);
  });

  // 금액 칸에 남은 청구액이 채워져 있는데 [결제하기] 가 꺼져 있었다 — 금액 칸을 한 번
  // 눌러야 켜졌다. 판정 리스너가 입력이 바뀔 때만 돌았다(2026-09-22 iOS 시뮬레이터 F-2).
  testWidgets('[지금 결제] 시트의 [결제하기] 는 칸을 안 건드려도 켜져 있다', (tester) async {
    await _open(
      tester,
      billing: const CardBilling(
        cardAssetRowId: 9,
        upcomingAmount: 40000,
        nextPaymentDate: '2026-10-12',
        upcomingPeriodStart: '2026-09-01',
        upcomingPeriodEnd: '2026-09-30',
      ),
    );
    await tester.tap(find.text('지금 결제'));
    await tester.pumpAndSettle();

    final pay = find.widgetWithText(PButton, '결제하기');
    expect(pay, findsOneWidget);
    expect(
      tester.widget<PButton>(pay).onPressed,
      isNotNull,
      reason: '채워진 40,000원으로 바로 결제할 수 있어야 한다',
    );
  });

  testWidgets('닫힌 회차의 할부 회차분 — "· 기록만", 정리 버튼 없음', (tester) async {
    await _open(
      tester,
      billing: CardBilling(
        cardAssetRowId: 9,
        upcomingAmount: 0,
        closedCycles: [
          _august(
            paid: 0,
            recorded: 30000,
            dues: const [
              InstallmentDue(
                expenseRowId: 5,
                merchant: 'QC90000',
                principalAmount: 90000,
                installmentMonths: 3,
                sequence: 2,
                amount: 30000,
                recordOnly: true,
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('QC90000 2/3회차'), findsOneWidget);
    expect(find.text('원금 90,000원 · 기록만'), findsOneWidget);
    expect(find.text('남은 할부 한 번에 정리'), findsNothing);
  });

  group('[결제 취소] — 닫힌 회차·환급 나간 회차는 숨긴다(D6)', () {
    CardBilling withHistory(List<BillingItem> history) => CardBilling(
      cardAssetRowId: 9,
      upcomingAmount: 40000,
      nextPaymentDate: '2026-10-12',
      upcomingPeriodStart: '2026-09-01',
      upcomingPeriodEnd: '2026-09-30',
      history: history,
    );

    testWidgets('열린 회차의 선결제면 보인다', (tester) async {
      await _open(
        tester,
        billing: withHistory([
          _payment(
            rowId: 1,
            periodStart: '2026-09-01',
            periodEnd: '2026-09-30',
            // 수동 결제는 누른 날이 찍힌다 — 회차 결제일(10/12)이 아니다.
            paymentDate: '2026-09-18',
          ),
        ]),
      );

      expect(find.text('결제 취소'), findsOneWidget);
    });

    testWidgets('결제일이 된 회차의 결제면 숨는다', (tester) async {
      await _open(
        tester,
        billing: withHistory([
          _payment(
            rowId: 1,
            periodStart: '2026-08-01',
            periodEnd: '2026-08-31',
            paymentDate: '2026-09-12',
          ),
        ]),
      );

      expect(find.text('결제 취소'), findsNothing);
    });

    // 가장 최근 결제가 닫힌 회차의 자동 결제여도, 그 앞의 열린 회차 선결제는 무를 수
    // 있다 — 버튼이 있고, 무르는 대상이 그 선결제다(QA 26 확인 필요).
    testWidgets('닫힌 회차 자동 결제 뒤에 있는 열린 회차 선결제를 고른다', (tester) async {
      await _open(
        tester,
        billing: withHistory([
          _payment(
            rowId: 1,
            periodStart: '2026-09-01',
            periodEnd: '2026-09-30',
            paymentDate: '2026-09-05',
          ),
          _payment(
            rowId: 2,
            periodStart: '2026-08-01',
            periodEnd: '2026-08-31',
            paymentDate: '2026-09-12',
          ),
        ]),
      );

      expect(find.text('결제 취소'), findsOneWidget);
      await tester.tap(find.text('결제 취소'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-09-05에 낸'), findsOneWidget);
      expect(find.textContaining('2026-09-12에 낸'), findsNothing);
    });

    testWidgets('서버가 닫힌 회차로 내려 준 회차의 결제는 고르지 않는다', (tester) async {
      await _open(
        tester,
        card: _card.copyWith(cardClosedThrough: null),
        billing: CardBilling(
          cardAssetRowId: 9,
          upcomingAmount: 40000,
          nextPaymentDate: '2026-10-12',
          upcomingPeriodStart: '2026-09-01',
          upcomingPeriodEnd: '2026-09-30',
          closedCycles: [_august(paid: 50000, recorded: 50000)],
          history: [
            _payment(
              rowId: 2,
              periodStart: '2026-08-01',
              periodEnd: '2026-08-31',
              paymentDate: '2026-09-12',
            ),
          ],
        ),
      );

      expect(find.text('결제 취소'), findsNothing);
    });

    testWidgets('그 회차에 환급이 나갔으면 숨는다', (tester) async {
      await _open(
        tester,
        billing: withHistory([
          _payment(
            rowId: 1,
            periodStart: '2026-09-01',
            periodEnd: '2026-09-30',
            paymentDate: '2026-09-18',
          ),
          _payment(
            rowId: 2,
            periodStart: '2026-09-01',
            periodEnd: '2026-09-30',
            paymentDate: '2026-09-19',
            status: 'REFUNDED',
          ),
        ]),
      );

      expect(find.text('결제 취소'), findsNothing);
    });
  });

  group('이용 내역 행 — 가계부와 같은 배지(A3)', () {
    const base = Expense(
      rowId: 1,
      categoryName: '식비',
      assetRowId: 9,
      assetName: '현대카드',
      expenseType: 'EXPENSE',
      amount: 11000,
      merchant: '환불한 가게',
      expenseDate: '2026-08-10T10:00:00',
    );

    testWidgets('환불됨·기록만 배지와 취소선, 일 합계는 환불을 뺀다', (tester) async {
      await _open(
        tester,
        billing: CardBilling(
          cardAssetRowId: 9,
          upcomingAmount: 0,
          closedCycles: [_august(paid: 0, recorded: 25000)],
        ),
        usage: [
          base.copyWith(refundedAt: '2026-08-15T12:00:00'),
          base.copyWith(
            rowId: 2,
            merchant: '뒤늦게 적은 가게',
            amount: 25000,
            expenseDate: '2026-08-20T10:00:00',
            cardSettledThrough: '2026-08-31',
            recordOnlyAmount: 25000,
          ),
          base.copyWith(
            rowId: 3,
            merchant: '할부 가게',
            amount: 90000,
            installmentMonths: 3,
            expenseDate: '2026-08-20T09:00:00',
            cardSettledThrough: '2026-08-31',
            // 지난 회차분만 기록용 — 행 배지는 안 단다(상세의 "이 중 N원").
            recordOnlyAmount: 30000,
          ),
        ],
      );

      expect(find.text('환불됨'), findsOneWidget);
      expect(find.text('기록만'), findsOneWidget);
      final refunded = tester.widget<Text>(findPlain('−11,000원'));
      expect(refunded.style?.decoration, TextDecoration.lineThrough);
      // 할부는 보조 줄에 개월 수를 붙인다 — 회차 청구와 행 금액이 왜 다른지.
      expect(find.textContaining('할부 3개월'), findsOneWidget);
      // 환불만 있는 날(8/10)은 일 합계가 없다 — 환불은 합계에서 빠진다.
      expect(findPlain('−11,000원'), findsOneWidget, reason: '행 금액 하나뿐');
    });
  });

  testWidgets('결제일 없는 카드는 결제일을 넣으라고 말한다(D8)', (tester) async {
    const noDay = Asset(
      rowId: 9,
      assetName: '현대카드',
      assetType: 'CREDIT_CARD',
      balance: -125000,
    );
    await _open(
      tester,
      card: noDay,
      billing: const CardBilling(cardAssetRowId: 9, upcomingAmount: 125000),
    );

    expect(find.text('결제일을 넣어주세요'), findsOneWidget);
  });
}
