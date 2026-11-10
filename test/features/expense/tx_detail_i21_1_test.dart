// I-21 21-1 — 거래 상세(B) · 상세 안 한 단계(A) · 이체 상세(C) · 환불(I). **작성만 했다(돌리지 않음).**
//
//   ① 머리: 타일 48 · 이름 · 금액 · 날짜 — 금액 · 날짜 줄은 없다, 값이 없는 줄은 그리지 않는다
//   ② "더 하기" 줄 갈래(지출 4 · 수입 3 · 환불됨 2 · 자동 막힘 2) · 연결 값
//   ③ 내역 분할 — 접기 없음 · 줄 누름 없음 · 실패 Result Section · 원문 없음
//   ④ 이 가맹점 이번 달 — 머리는 이 달 전체, 줄은 5개, 6건 이상이면 "최근 5건만 보여요", 줄 누름 없음
//   ⑤ 환불은 같은 시트 안 한 단계 — ← 는 상세로, 바뀐 채 ← 는 먼저 묻는다, 처리하면 상세로 돌아와 "환불됨"
//   ⑥ 삭제 — 실패는 확인창을 닫고 시트 안 Callout(스낵바 아님), 지운 뒤 버튼이 다시 열리지 않는다
//   ⑦ 이체 상세 — 제목 · "보내는 계좌 · 받는 계좌" · Logo Tile · 값 줄 · 자동 이체 바닥 없음
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/transfer_detail_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/expense_split/domain/expense_split.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import '../../support/plain_text.dart';

const _card = Asset(
  rowId: 9,
  assetName: '별빛카드',
  institution: '삼성카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 14,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);
const _bank = Asset(
  rowId: 3,
  assetName: '생활비 통장',
  institution: '하늘은행',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
);
const _loan = Asset(
  rowId: 4,
  assetName: '전세자금대출',
  assetType: 'LOAN',
  balance: -50000000,
);

const _parent = ExpenseCategory(
  rowId: 10,
  categoryName: '쇼핑',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'shopping-bag',
  color: '#2c70bf',
);
const _child = ExpenseCategory(
  rowId: 11,
  categoryName: '가전·가구',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  parentRowId: 10,
  icon: 'sofa',
  color: '#2c70bf',
);
const _income = ExpenseCategory(
  rowId: 12,
  categoryName: '월급',
  expenseType: 'INCOME',
  sortOrder: 0,
  icon: 'wallet',
  color: '#1a8f5a',
);

/// 가장 나쁜 값 — 22자 가맹점 · 128,000,000원 · 할부 12 · 긴 메모.
const _worst = Expense(
  rowId: 733,
  categoryRowId: 11,
  categoryName: '가전·가구',
  assetRowId: 9,
  assetName: '별빛카드',
  expenseType: 'EXPENSE',
  amount: 128000000,
  merchant: '아주 길고 긴 이름의 온라인 종합 쇼핑몰 본점',
  description:
      '이사 가구 · 커튼 · 조명 일괄 구매. 배송 일정 확인하고 설치 기사님 방문 시간 조율하기. 영수증은 따로 보관.',
  paymentMethod: 'CARD',
  installmentMonths: 12,
  expenseDate: '2026-10-28T12:00:00',
);

const _plain = Expense(
  rowId: 5,
  categoryRowId: 11,
  categoryName: '가전·가구',
  assetRowId: 3,
  assetName: '생활비 통장',
  expenseType: 'EXPENSE',
  amount: 12000,
  merchant: '점심',
  expenseDate: '2026-10-28T00:00:00',
);

Expense _other(int i) => _plain.copyWith(
  rowId: 9000 + i,
  merchant: _worst.merchant,
  amount: 16000,
  expenseDate: '2026-10-${(20 - i).toString().padLeft(2, '0')}T12:00:00',
);

class _FakeRepo extends ExpenseRepository {
  _FakeRepo({this.failDelete = false, this.failRefund = false})
    : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  bool failDelete;
  bool failRefund;
  bool failCancel = false;
  final cancelled = <int>[];

  @override
  Future<Expense> cancelRefund(int id, {bool silent = false}) async {
    if (failCancel) {
      throw ApiException(code: 'SERVER', message: '서버 원문', statusCode: 500);
    }
    cancelled.add(id);
    return _plain;
  }

  final deleted = <int>[];
  final silentFlags = <bool>[];
  String? refundedAt;

  /// 달 목록을 다시 받은 횟수 — 요청 뒤 목록 갱신을 본다.
  int listCalls = 0;

  @override
  Future<List<Expense>> list({
    String? startDate,
    String? endDate,
    int? categoryId,
    int? assetId,
    String? expenseType,
  }) async {
    listCalls++;
    return const [];
  }

  @override
  Future<int?> delete(int id, {bool silent = false}) async {
    silentFlags.add(silent);
    if (failDelete) {
      throw ApiException(code: 'SERVER', message: '서버 원문', statusCode: 500);
    }
    deleted.add(id);
    return null;
  }

  @override
  Future<Expense> refund(
    int id, {
    String? refundedAt,
    bool silent = false,
  }) async {
    silentFlags.add(silent);
    if (failRefund) {
      throw ApiException(code: 'SERVER', message: '서버 원문', statusCode: 500);
    }
    this.refundedAt = refundedAt;
    return _plain.copyWith(refundedAt: refundedAt);
  }
}

class _FakeAssetRepo extends AssetRepository {
  _FakeAssetRepo()
    : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));
  final deleted = <int>[];
  bool? silent;
  bool fail = false;

  @override
  Future<void> deleteTransfer(int id, {bool silent = false}) async {
    this.silent = silent;
    if (fail) {
      throw ApiException(code: 'SERVER', message: '서버 원문', statusCode: 500);
    }
    deleted.add(id);
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  _FakeRepo? repo,
  _FakeAssetRepo? assetRepo,
  List<ExpenseSplit> splits = const [],
  bool splitsFail = false,
  List<Expense> history = const [],
  bool historyFail = false,
  List<RecurringTransaction> recurring = const [],
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith(
          (ref) async => repo ?? _FakeRepo(),
        ),
        assetRepositoryProvider.overrideWith(
          (ref) async => assetRepo ?? _FakeAssetRepo(),
        ),
        assetsProvider.overrideWith((ref) async => const [_card, _bank, _loan]),
        categoriesProvider.overrideWith(
          (ref) async => const [_parent, _child, _income],
        ),
        expenseSplitsProvider.overrideWith((ref, id) async {
          if (splitsFail) throw Exception('서버 원문 — 화면에 그리지 않는다');
          return splits;
        }),
        merchantMonthExpensesProvider.overrideWith((ref, key) async {
          if (historyFail) throw Exception('서버 원문 — 화면에 그리지 않는다');
          return history;
        }),
        recurringListProvider.overrideWith((ref) async => recurring),
        dutchPayListProvider.overrideWith((ref) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          // 앱과 같은 자리 — 길잡이 바깥이라 시트 · 확인창 위에 뜬다
          child: Material(
            type: MaterialType.transparency,
            child: PSnackbarHost(closeLabel: '닫기', child: child!),
          ),
        ),
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

Future<void> _openDetail(WidgetTester tester) async {
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

/// ds 글은 낱말 단위 줄바꿈 U+2060 · 금액은 U+200B 가 끼어 있다 — 그 글자를 뺀 글로 찾는다.
Finder _plainText(String needle) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? w.textSpan?.toPlainText() ?? '')
          .replaceAll('⁠', '')
          .replaceAll('​', '')
          .contains(needle),
);

void main() {
  group('규칙 — 순수 함수', () {
    test('날짜 · 시각 글: 00:00 이면 날짜만, 아니면 오전/오후 시각', () {
      expect(
        txDetailDateTimeLabel('2026-10-28T00:00:00'),
        isNot(contains('오')),
      );
      expect(
        txDetailDateTimeLabel('2026-10-28T12:00:00'),
        contains('오후 12:00'),
      );
      expect(txDetailDateTimeLabel(null), isNull);
    });

    test('가맹점 묶음: 이 거래는 줄에서 빼고 머리는 이 달 전체(이 거래 포함)', () {
      final all = [_worst, for (var i = 0; i < 8; i++) _other(i)];
      final h = txHistoryOf(all, _worst.rowId);
      expect(h.rows.length, 5);
      expect(h.overflow, isTrue, reason: '다른 거래가 8건 > 5');
      expect(h.monthCount, 9, reason: '이 달 전체 — 이 거래 포함');
      // 환불된 거래는 합계에서 뺀다(건수는 그대로)
      final refunded = txHistoryOf([
        _worst,
        _other(0).copyWith(refundedAt: '2026-10-29T12:00:00'),
      ], _worst.rowId);
      expect(refunded.monthCount, 2);
      expect(refunded.monthTotal, _worst.amount);
      final three = txHistoryOf([_worst, _other(0), _other(1)], _worst.rowId);
      expect(three.overflow, isFalse);
      expect(three.rows.length, 2);
    });

    test('카테고리 줄: 하위면 "{상위} · {하위}", 못 찾으면 거래가 든 이름', () {
      expect(
        txCategoryLabel(_worst, const [_parent, _child], '미분류'),
        '쇼핑 · 가전·가구',
      );
      expect(txCategoryLabel(_worst, const [], '미분류'), '가전·가구');
    });
  });

  group('거래 상세', () {
    testWidgets('머리 값이 있고 금액 · 날짜 줄은 없다 — 메모 없으면 줄도 없다', (tester) async {
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, _plain)));
      await _openDetail(tester);

      expect(findText('지출 상세'), findsOneWidget);
      expect(find.byKey(const ValueKey('tx-detail-head')), findsOneWidget);
      expect(find.byKey(const ValueKey('tx-detail-name')), findsOneWidget);
      // 머리와 같은 값 두 번 — 키-값 줄에 금액 · 날짜 · 시간이 없다
      expect(findText('금액'), findsNothing);
      expect(findText('날짜 · 시간'), findsNothing);
      expect(findText('메모'), findsNothing, reason: '값이 없는 줄은 그리지 않는다');
      expect(findText('쇼핑 · 가전·가구'), findsOneWidget);
    });

    testWidgets('금액은 쉼표 뒤에서만 줄이 바뀌고 자르지 않는다(360 · 200%)', (tester) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _worst)),
        width: 360,
        textScale: 2,
      );
      await _openDetail(tester);

      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('tx-detail-amount')),
      );
      expect(amount.semanticsLabel, '−128,000,000원');
      final visible = amount.data ?? '';
      expect(
        RegExp(r'\d​\d').hasMatch(visible),
        isFalse,
        reason: '숫자 한가운데에서 끊지 않는다',
      );
      expect(tester.takeException(), isNull, reason: 'overflow 오류 0');
    });

    testWidgets('"더 하기" 줄 — 지출 넷', (tester) async {
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, _plain)));
      await _openDetail(tester);

      for (final k in ['refund', 'split', 'recurring', 'dutch']) {
        expect(find.byKey(ValueKey('more-$k')), findsOneWidget, reason: k);
      }
      expect(findText('더 하기'), findsOneWidget);
    });

    testWidgets('"더 하기" 줄 — 수입은 환불 · 분할 없이 셋', (tester) async {
      final income = _plain.copyWith(
        expenseType: 'INCOME',
        categoryRowId: 12,
        categoryName: '월급',
        merchant: '월급',
      );
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, income)));
      await _openDetail(tester);

      expect(findText('수입 상세'), findsOneWidget);
      expect(find.byKey(const ValueKey('more-refund')), findsNothing);
      expect(find.byKey(const ValueKey('more-split')), findsOneWidget);
      expect(find.byKey(const ValueKey('more-recurring')), findsOneWidget);
    });

    testWidgets('값 줄 이름 — 수입은 수입 방식 · 입금 계좌, 지출은 결제 수단 · 계좌 · 카드', (
      tester,
    ) async {
      final income = _plain.copyWith(
        expenseType: 'INCOME',
        categoryRowId: 12,
        categoryName: '월급',
        paymentMethod: 'TRANSFER',
      );
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, income)));
      await _openDetail(tester);
      expect(findText('수입 방식'), findsOneWidget);
      expect(findText('입금 계좌'), findsOneWidget);
      expect(findText('결제 수단'), findsNothing);
      expect(findText('계좌 · 카드'), findsNothing);
    });

    testWidgets('값 줄 이름 — 지출은 결제 수단 · 계좌 · 카드 그대로', (tester) async {
      final expense = _plain.copyWith(paymentMethod: 'CASH');
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, expense)));
      await _openDetail(tester);
      expect(findText('결제 수단'), findsOneWidget);
      expect(findText('계좌 · 카드'), findsOneWidget);
      expect(findText('수입 방식'), findsNothing);
      expect(findText('입금 계좌'), findsNothing);
    });

    testWidgets('연결 값 — 나눈 개수 · 연결됨', (tester) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        splits: const [
          ExpenseSplit(
            rowId: 1,
            expenseRowId: 5,
            categoryRowId: 11,
            categoryName: '가전·가구',
            amount: 7000,
            label: '커튼',
          ),
          ExpenseSplit(
            rowId: 2,
            expenseRowId: 5,
            categoryRowId: 10,
            categoryName: '쇼핑',
            amount: 5000,
          ),
        ],
        recurring: const [
          RecurringTransaction(
            rowId: 1,
            sourceExpenseRowId: 5,
            expenseType: 'EXPENSE',
            amount: 12000,
            frequency: 'MONTHLY',
          ),
        ],
      );
      await _openDetail(tester);

      expect(findText('2개로 나눔'), findsOneWidget);
      expect(findText('연결됨'), findsOneWidget);
      // 나눈 내역 묶음 — 접기 없음, 줄을 누르지 않는다
      expect(findText('내역 분할 2개'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronUp), findsNothing);
      expect(find.byIcon(LucideIcons.chevronDown), findsNothing);
    });

    testWidgets('나눈 내역을 못 받으면 우리 글의 Result Section — 서버 원문 없음', (tester) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        splitsFail: true,
      );
      await _openDetail(tester);

      expect(find.byType(PResultSection), findsOneWidget);
      expect(findText('나눈 내역을 불러오지 못했어요'), findsOneWidget);
      expect(findTextContaining('서버 원문'), findsNothing);
    });

    testWidgets('이 가맹점 이번 달을 처음 받지 못하면 "처음 이용" 처럼 비지 않고 그 자리 실패 + 다시 시도', (
      tester,
    ) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _worst)),
        historyFail: true,
      );
      await _openDetail(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tx-detail-history-failure')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(findText('이전 거래 정보를 불러오지 못했어요'), findsOneWidget);
      expect(findText('이 가맹점 이번 달'), findsNothing);
      expect(findTextContaining('서버 원문'), findsNothing);
    });

    testWidgets('이 가맹점: 다른 거래 3건이면 보조 글 없음, 9건이면 줄 5 + "최근 5건만 보여요"', (
      tester,
    ) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _worst)),
        history: [_worst, _other(0), _other(1), _other(2)],
      );
      await _openDetail(tester);
      expect(findText('이 가맹점 이번 달'), findsOneWidget);
      expect(find.byKey(const ValueKey('tx-detail-recent-only')), findsNothing);
    });

    testWidgets('이 가맹점 9건 — 줄 5 + 보조 글, 줄은 누르지 않는다', (tester) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _worst)),
        history: [_worst, for (var i = 0; i < 8; i++) _other(i)],
      );
      await _openDetail(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tx-detail-recent-only')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(findText('최근 5건만 보여요'), findsOneWidget);
      expect(
        find.byType(PListButtonItem),
        findsWidgets,
        reason: '"더 하기" 줄은 누르는 줄',
      );
      // 가맹점 묶음 안 거래 줄은 PListItem(누르지 않는 줄)이다
      final history = find.byKey(const ValueKey('tx-detail-history'));
      expect(
        find.descendant(of: history, matching: find.byType(PListButtonItem)),
        findsNothing,
      );
      expect(
        find.descendant(of: history, matching: find.byType(PListItem)),
        findsNWidgets(5),
      );
    });
  });

  group('환불 — 같은 시트 안 한 단계', () {
    Future<void> toRefund(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('more-refund')));
      await tester.pumpAndSettle();
    }

    testWidgets('[환불] 줄 → 같은 시트가 환불 단계로 — 새 시트 · 확인창 · 날짜 칸 없음', (
      tester,
    ) async {
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, _plain)));
      await _openDetail(tester);
      await toRefund(tester);

      expect(find.byKey(const ValueKey('refund-step')), findsOneWidget);
      expect(find.byKey(const ValueKey('refund-date-row')), findsOneWidget);
      // 문장 안 금액은 낱말 하나로 통째로 넘어간다(쉼표 뒤 줄바꿈 예외 없음 — 그 예외는 줄 값 칸뿐)
      final sentence = tester.widget<Text>(
        find.byKey(const ValueKey('refund-text')),
      );
      expect(sentence.textSpan!.toPlainText(), isNot(contains('\u200B')));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(findText('지출 상세'), findsNothing, reason: '같은 시트의 머리가 바뀐다');
    });

    testWidgets('← 는 상세로 — 바꾼 값이 없으면 묻지 않는다', (tester) async {
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, _plain)));
      await _openDetail(tester);
      await toRefund(tester);

      await tester.tap(find.bySemanticsLabel('뒤로'));
      await tester.pumpAndSettle();
      expect(findText('지출 상세'), findsOneWidget);
      expect(findText('작성한 내용이 사라져요'), findsNothing);
    });

    testWidgets('[환불 처리] → 정오로 보내고, 상세로 돌아와 "환불됨" Callout', (tester) async {
      final repo = _FakeRepo();
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        repo: repo,
      );
      await _openDetail(tester);
      await toRefund(tester);
      await tester.tap(findWidgetWithText(PButton, '환불 처리'));
      await tester.pumpAndSettle();

      expect(repo.refundedAt, endsWith('T12:00:00'));
      expect(repo.silentFlags, [true], reason: '전역 스낵바와 겹치지 않게 조용히');
      expect(findText('지출 상세'), findsOneWidget);
      expect(findTextContaining('합계에서 빠져 있어요.'), findsOneWidget);
      expect(find.byKey(const ValueKey('more-refund')), findsNothing);
      expect(find.byKey(const ValueKey('more-split')), findsNothing);
    });

    testWidgets('환불됨 Callout 의 버튼은 Callout 상자 안에 있다', (tester) async {
      await _pump(tester, _opener((ctx) => showTxDetailDialog(ctx, _plain)));
      await _openDetail(tester);
      await toRefund(tester);
      await tester.tap(findWidgetWithText(PButton, '환불 처리'));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byKey(const ValueKey('callout-box')));
      final cancel = tester.getRect(findWidgetWithText(PButton, '환불 취소'));
      expect(box.contains(cancel.topLeft), isTrue);
      expect(box.contains(cancel.bottomRight), isTrue);
      expect(find.byKey(const ValueKey('callout-actions')), findsOneWidget);
    });

    testWidgets('처리가 실패하면 단계에 남고 단계 위에 우리 글의 Callout', (tester) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        repo: _FakeRepo(failRefund: true),
      );
      await _openDetail(tester);
      await toRefund(tester);
      await tester.tap(findWidgetWithText(PButton, '환불 처리'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('refund-step')), findsOneWidget);
      expect(findText('환불하지 못했어요. 잠시 뒤에 다시 시도해주세요.'), findsOneWidget);
    });
  });

  group('삭제', () {
    testWidgets('실패하면 확인창은 닫히고 critical 스낵바 + [다시 시도] — 시트 안 Callout 아님', (
      tester,
    ) async {
      final repo = _FakeRepo(failDelete: true);
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        repo: repo,
      );
      await _openDetail(tester);

      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();

      expect(repo.silentFlags, [true], reason: '전역 오류 알림은 끄고 화면이 말한다');
      expect(find.byType(AlertDialog), findsNothing, reason: '확인창은 닫혔다');
      expect(find.byKey(const ValueKey('tx-detail-failure')), findsNothing);
      expect(findText('거래를 삭제하지 못했어요.'), findsOneWidget);
      expect(findText('다시 시도'), findsOneWidget);
      // 시트는 그대로 열려 있고 버튼은 풀려 있다
      expect(
        tester.widget<PButton>(findWidgetWithText(PButton, '삭제')).onPressed,
        isNotNull,
      );
    });

    testWidgets('[다시 시도] 는 확인창을 다시 거치지 않고 바로 지운다', (tester) async {
      final repo = _FakeRepo(failDelete: true);
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        repo: repo,
      );
      await _openDetail(tester);
      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();

      repo.failDelete = false;
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing, reason: '다시 묻지 않는다');
      expect(repo.deleted, [5]);
      expect(findText('지출 상세'), findsNothing, reason: '지운 뒤 시트가 닫힌다');
    });

    testWidgets('시트를 닫은 뒤 [다시 시도] 를 눌러도 요청이 나가고 목록이 갱신된다', (tester) async {
      final repo = _FakeRepo(failDelete: true);
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        repo: repo,
      );
      await _openDetail(tester);
      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(findText('다시 시도'), findsOneWidget);

      // 스낵바가 떠 있는 동안 시트를 닫는다(State 가 사라진다)
      Navigator.of(
        tester.element(find.byType(PBottomSheetContent)),
        rootNavigator: true,
      ).pop();
      await tester.pumpAndSettle();
      expect(findText('지출 상세'), findsNothing);
      expect(findText('다시 시도'), findsOneWidget, reason: '스낵바는 시트 밖이라 남아 있다');

      repo.failDelete = false;
      final before = repo.listCalls;
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();

      expect(repo.deleted, [5], reason: '시트가 없어도 요청이 나간다');
      expect(repo.listCalls, greaterThan(before), reason: '지운 뒤 달 목록을 다시 받는다');
    });

    testWidgets('환불 취소: 실패 → 스낵바, 시트를 닫은 뒤 [다시 시도] 도 요청이 나가고 목록이 갱신된다', (
      tester,
    ) async {
      final repo = _FakeRepo()..failCancel = true;
      await _pump(
        tester,
        _opener(
          (ctx) => showTxDetailDialog(
            ctx,
            _plain.copyWith(refundedAt: '2026-10-29T12:00:00'),
          ),
        ),
        repo: repo,
      );
      await _openDetail(tester);
      await tester.tap(findWidgetWithText(PButton, '환불 취소'));
      await tester.pumpAndSettle();
      await tester.tap(findText('환불 취소').last);
      await tester.pumpAndSettle();
      expect(findText('환불을 취소하지 못했어요.'), findsOneWidget);

      Navigator.of(
        tester.element(find.byType(PBottomSheetContent)),
        rootNavigator: true,
      ).pop();
      await tester.pumpAndSettle();

      repo.failCancel = false;
      final before = repo.listCalls;
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();

      expect(repo.cancelled, [5]);
      expect(repo.listCalls, greaterThan(before));
    });

    testWidgets('지우면 시트가 닫히고, 닫히는 동안 버튼은 다시 열리지 않는다', (tester) async {
      final repo = _FakeRepo();
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        repo: repo,
      );
      await _openDetail(tester);
      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(repo.deleted, [5]);
      // 닫히는 중인 확인창의 [삭제] 는 빼고 상세 바닥의 단추만 본다
      bool inDialog(Element e) {
        var found = false;
        e.visitAncestorElements((a) {
          if (a.widget is PAlertDialogView) found = true;
          return !found;
        });
        return found;
      }

      for (final e in findWidgetWithText(PButton, '삭제').evaluate()) {
        if (inDialog(e)) continue;
        expect(
          (e.widget as PButton).onPressed,
          isNull,
          reason: '지운 뒤 닫히는 동안 막는다',
        );
      }
      await tester.pumpAndSettle();
      expect(findText('지출 상세'), findsNothing);
    });
  });

  group('이체 상세', () {
    const transfer = AssetTransfer(
      rowId: 7001,
      fromAssetRowId: 3,
      fromAssetName: '하늘은행 월급 통장 아주아주 긴 이름의 통장 별칭이에요',
      toAssetRowId: 4,
      toAssetName: '전세자금대출',
      amount: 900000,
      fee: 1500,
      interestAmount: 120000,
      principalAmount: 780000,
      description: '월 저축',
      transferDate: '2026-10-29T10:00:00',
    );

    testWidgets('제목 · 이름 · 계좌 줄(Logo Tile) · 값 줄', (tester) async {
      await _pump(
        tester,
        _opener((ctx) => showTransferDetailSheet(ctx, transfer)),
      );
      await _openDetail(tester);

      expect(findText('이체 상세'), findsOneWidget);
      expect(findText('보내는 계좌'), findsOneWidget);
      expect(findText('받는 계좌'), findsOneWidget);
      expect(findText('보낼 자산'), findsNothing);
      expect(find.byType(PLogoTile), findsNWidgets(2));
      expect(findText('수수료'), findsOneWidget);
      expect(findText('출금 합계'), findsOneWidget);
      expect(findText('이자'), findsOneWidget);
      expect(findText('원금'), findsOneWidget);
      expect(findText('금액'), findsNothing);
      expect(findText('날짜'), findsNothing);
      expect(find.byKey(const ValueKey('more-recurring')), findsOneWidget);
    });

    testWidgets('자동 이체는 바닥도 반복 설정 줄도 없고 이유를 적는다', (tester) async {
      await _pump(
        tester,
        _opener(
          (ctx) => showTransferDetailSheet(
            ctx,
            AssetTransfer(
              rowId: transfer.rowId,
              fromAssetRowId: transfer.fromAssetRowId,
              fromAssetName: transfer.fromAssetName,
              toAssetRowId: transfer.toAssetRowId,
              toAssetName: transfer.toAssetName,
              amount: transfer.amount,
              transferDate: transfer.transferDate,
              autoSource: 'CARD_PAYMENT',
            ),
          ),
        ),
      );
      await _openDetail(tester);

      expect(findWidgetWithText(PButton, '삭제'), findsNothing);
      expect(findWidgetWithText(PButton, '수정'), findsNothing);
      expect(find.byKey(const ValueKey('more-recurring')), findsNothing);
      expect(_plainText('따로 고칠 수 없어요.'), findsOneWidget);
    });

    testWidgets('이체 삭제가 실패하면 스낵바 + [다시 시도], 다시 시도는 바로 요청', (tester) async {
      final assetRepo = _FakeAssetRepo()..fail = true;
      await _pump(
        tester,
        _opener((ctx) => showTransferDetailSheet(ctx, transfer)),
        assetRepo: assetRepo,
      );
      await _openDetail(tester);
      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(findText('이체를 삭제하지 못했어요.'), findsOneWidget);
      expect(assetRepo.deleted, isEmpty);

      assetRepo.fail = false;
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing, reason: '다시 묻지 않는다');
      expect(assetRepo.deleted, [7001]);
      expect(findText('이체 상세'), findsNothing);
    });

    testWidgets('이체: 시트를 닫은 뒤 [다시 시도] 도 요청이 나가고 목록이 갱신된다', (tester) async {
      final assetRepo = _FakeAssetRepo()..fail = true;
      final repo = _FakeRepo();
      await _pump(
        tester,
        _opener((ctx) => showTransferDetailSheet(ctx, transfer)),
        assetRepo: assetRepo,
        repo: repo,
      );
      await _openDetail(tester);
      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();

      Navigator.of(
        tester.element(find.byType(PBottomSheetContent)),
        rootNavigator: true,
      ).pop();
      await tester.pumpAndSettle();
      expect(findText('이체 상세'), findsNothing);

      assetRepo.fail = false;
      final before = repo.listCalls;
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();

      expect(assetRepo.deleted, [7001]);
      expect(repo.listCalls, greaterThan(before));
    });

    testWidgets('삭제 확인창 제목은 "이체 삭제" — 조용한 요청', (tester) async {
      final assetRepo = _FakeAssetRepo();
      await _pump(
        tester,
        _opener((ctx) => showTransferDetailSheet(ctx, transfer)),
        assetRepo: assetRepo,
      );
      await _openDetail(tester);
      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pumpAndSettle();

      expect(findText('이체 삭제'), findsOneWidget);
      expect(
        _plainText('양쪽 계좌 잔액이 이체 전으로 돌아가요. 삭제한 이체는 되돌릴 수 없어요.'),
        findsOneWidget,
      );
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(assetRepo.deleted, [7001]);
      expect(assetRepo.silent, isTrue);
    });
  });

  group('7a — 수정은 같은 시트 안 한 단계', () {
    testWidgets('[수정] → ← 로 상세로 돌아오고 시트는 하나다', (tester) async {
      await _pump(
        tester,
        _opener((ctx) => showTxDetailDialog(ctx, _plain)),
        repo: _FakeRepo(),
      );
      await _openDetail(tester);
      expect(find.byType(PBottomSheetContent), findsOneWidget);
      expect(findText('지출 상세'), findsOneWidget);

      await tester.tap(findWidgetWithText(PButton, '수정'));
      await tester.pumpAndSettle();
      expect(find.byType(PBottomSheetContent), findsOneWidget);
      expect(findText('거래 수정'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('뒤로').first);
      await tester.pumpAndSettle();
      expect(find.byType(PBottomSheetContent), findsOneWidget);
      expect(findText('지출 상세'), findsOneWidget);
    });
  });
}
