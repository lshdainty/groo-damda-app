// 23차에서 남은 앱 결함 — 거래 상세·스와이프·금액 단위.
//
//   ① 상세에서 환불하면 footer 의 [수정] 이 그 자리에서 사라진다(누르면 EXP_043 이던 것)
//   ② 카드 이월 거래 상세 — 환불·분할이 없고, 안내가 "원래 거래를 지우면…" 이 아니다
//   ③ 환불된 행을 밀면 [수정] 이 없다(삭제는 있다)
//   ④ 금액을 문장에 넣을 때 단위(원)를 붙인다 — 결제 시트·해외 결제 환산 줄
import 'package:dio/dio.dart';
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
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_select.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../support/plain_text.dart';

const _account = Asset(
  rowId: 3,
  assetName: '생활비 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
);

const _category = ExpenseCategory(
  rowId: 11,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _plain = Expense(
  rowId: 5,
  categoryRowId: 11,
  categoryName: '식비',
  assetRowId: 3,
  assetName: '생활비 통장',
  expenseType: 'EXPENSE',
  amount: 12000,
  merchant: '점심',
  expenseDate: '2026-09-10T12:00:00',
);

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  @override
  Future<Expense> refund(
    int id, {
    String? refundedAt,
    bool silent = false,
  }) async => _plain.copyWith(refundedAt: refundedAt);

  @override
  Future<Expense> cancelRefund(int id, {bool silent = false}) async => _plain;
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => _FakeRepo()),
        assetsProvider.overrideWith((ref) async => const [_account]),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        merchantMonthExpensesProvider.overrideWith(
          (ref, key) async => const [],
        ),
        recurringListProvider.overrideWith((ref) async => const []),
        dutchPayListProvider.overrideWith((ref) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
        // 지우기 · 환불 뒤 그 달 목록을 다시 받을 때까지 기다린다(1a9d9de7) — 가짜 저장소에 list 가 없어 덮는다
        monthExpensesProvider.overrideWith((ref, key) async => const []),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _opener(void Function(BuildContext) open) => Builder(
  builder: (ctx) =>
      TextButton(onPressed: () => open(ctx), child: const Text('open')),
);

void main() {
  testWidgets('상세에서 환불하면 [수정] 이 그 자리에서 사라지고, 취소하면 돌아온다', (tester) async {
    await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, _plain)));
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    expect(findText('수정'), findsOneWidget);
    expect(findText('내역 분할'), findsOneWidget, reason: '보통 거래에는 있다');

    // 환불은 같은 시트의 한 단계다 — "더 하기" 의 [환불] 줄 → 바닥 [환불 처리] → 상세로 돌아와 "환불됨" Callout
    await tester.tap(find.byKey(const ValueKey('more-refund')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PButton, '환불 처리'));
    await tester.pumpAndSettle();

    expect(findText('환불 취소'), findsOneWidget, reason: 'Callout 이 떴다');
    expect(findText('수정'), findsNothing, reason: 'footer 도 환불된 거래를 본다');

    await tester.tap(find.widgetWithText(PButton, '환불 취소'));
    await tester.pumpAndSettle();
    await tester.tap(findText('환불 취소').last);
    await tester.pumpAndSettle();

    expect(findText('수정'), findsOneWidget);
  });

  // 결제 대기 청구분(CARD_CARRYOVER_DUE, 2026-09-22)도 같은 이월이다.
  for (final source in ['CARD_CARRYOVER', 'CARD_CARRYOVER_DUE']) {
    testWidgets('카드 이월 거래 상세($source) — 환불·분할이 없고 이월이라고 말한다', (tester) async {
      final carryover = _plain.copyWith(
        merchant: '이전 미결제 사용액',
        autoSource: source,
      );
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, carryover)));
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();

      expect(findText('환불'), findsNothing);
      expect(findText('내역 분할'), findsNothing);
      expect(
        findText('카드를 등록할 때 적은 이전 미결제 사용액이에요. 금액은 카드 수정에서 바꿔요.'),
        findsOneWidget,
      );
      expect(findTextContaining('원래 거래를 지우면'), findsNothing);
    });
  }

  // 자동 거래는 반복·더치페이의 원본이 될 수 없다 — 숨기지 않고 끈다(2026-09-22 결정).
  for (final source in [
    'CARD_CARRYOVER',
    'CARD_CARRYOVER_DUE',
    'TRADE_REALIZED',
    'TRANSFER_INTEREST',
  ]) {
    testWidgets('$source — [반복 설정]·[더치페이] 가 보이되 꺼져 있다', (tester) async {
      final auto = _plain.copyWith(autoSource: source);
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, auto)));
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();

      // 막힌 줄 — 숨기지 않는다. 누름이 없고(onTap null) 꺾쇠도 없다(비활성 색은 ds 가 입힌다)
      for (final key in ['more-recurring', 'more-dutch']) {
        final row = find.byKey(ValueKey(key));
        expect(row, findsOneWidget, reason: '$key 은 숨기지 않는다');
        expect(tester.widget<PListButtonItem>(row).onTap, isNull);
        expect(
          find.descendant(
            of: row,
            matching: find.byIcon(LucideIcons.chevronRight),
          ),
          findsNothing,
        );
      }
    });
  }

  testWidgets('보통 거래는 [반복 설정]·[더치페이] 가 켜져 있다', (tester) async {
    await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, _plain)));
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();

    for (final key in ['more-recurring', 'more-dutch']) {
      expect(
        tester.widget<PListButtonItem>(find.byKey(ValueKey(key))).onTap,
        isNotNull,
      );
    }
  });

  testWidgets('환불된 행을 밀면 [수정] 은 없고 [삭제] 만 있다', (tester) async {
    final refunded = _plain.copyWith(refundedAt: '2026-09-15T12:00:00');
    late List<PSwipeAction> actions;
    await _pump(
      tester,
      Consumer(
        builder: (ctx, ref, _) {
          actions = expenseActions.dsSwipeActions(
            ctx,
            ref,
            refunded,
            asset: _account,
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(actions.map((a) => a.label), ['삭제']);
  });

  testWidgets('해외 결제 환산 줄에 원화 단위가 붙는다', (tester) async {
    await _pump(tester, _opener((ctx) => showAddTxSheet(ctx)));
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();

    // 1단계 통화 칩 → 고르기 시트 → USD → 현지 금액 → [다음] → 2단계 환율 칸
    await tester.tap(find.byKey(const ValueKey('tx-currency-chip')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PListButtonItem && w.title.contains('USD'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '5.5');
    await tester.tap(findText('다음'));
    await tester.pumpAndSettle();
    // 2단계: 거래처 칸 다음이 환율 칸
    await tester.enterText(find.byType(EditableText).at(1), '1400');
    await tester.pump();

    expect(findTextContaining('= 7,700원'), findsOneWidget);
  });

  group('카드 결제 시트 — 금액에 단위(원)', () {
    const card = Asset(
      rowId: 9,
      assetName: '현대카드',
      assetType: 'CREDIT_CARD',
      balance: -9000,
      paymentDay: 12,
      paymentAssetRowId: 3,
      cardClosedThrough: '2026-08-31',
    );

    testWidgets('사용액 캡 안내와 남은 금액이 "N원" 으로 읽힌다', (tester) async {
      tester.view.physicalSize = const Size(1500, 3600);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetsProvider.overrideWith((ref) async => const [card]),
            hideCardProvider.overrideWith((ref, c) => false),
            cardBillingProvider.overrideWith(
              (ref, id) async => const CardBilling(
                cardAssetRowId: 9,
                upcomingAmount: 40000,
                nextPaymentDate: '2026-10-12',
                upcomingPeriodStart: '2026-09-01',
                upcomingPeriodEnd: '2026-09-30',
                paymentAssetRowId: 3,
              ),
            ),
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
            assetBalanceTrendProvider.overrideWith(
              (ref, key) async => const [],
            ),
            assetTransfersProvider.overrideWith(
              (ref, key) async => const <AssetTransfer>[],
            ),
            expensesByAssetProvider.overrideWith(
              (ref, key) async => const <Expense>[],
            ),
            assetPeriodExpensesProvider.overrideWith(
              (ref, key) async => const <Expense>[],
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
                  onPressed: () => showAssetDetailRich(ctx, card),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();

      await tester.tap(findText('지금 결제'));
      await tester.pumpAndSettle();

      // 빚(9,000)보다 청구(40,000)가 크다 — 계좌에서는 9,000원만 빠진다.
      expect(findTextContaining('사용액으로 잡힌 9,000원만 빠져요'), findsOneWidget);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '40000',
        ),
        '30000',
      );
      await tester.pump();
      expect(findText('남은 10,000원은 결제일에 빠져요'), findsOneWidget);
    });
  });
}
