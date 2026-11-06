// 이체 반복이 **보내는 것**을 고정한다(새 폼 — I-20 D 26).
//
// 이 본문은 밤마다 서버가 그대로 실행한다 — 잘못 저장되면 화면엔 "저장됐다" 가 남고 자정 배치만 조용히 실패한다.
// - 이체로 저장하면 받는 계좌 · 수수료가 실리고 카테고리 · 거래처 · 결제 수단은 안 실린다.
// - 카드는 이체 상대 후보에 없다 — 거래 시트와 같은 규칙(`transfer_rules.dart`).
// - 저장 요청은 silent 이고, 실패하면 시트 안 Callout 고정 글이 서고 쓴 값이 남는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/data/recurring_repository.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';

import 'recurring_test_support.dart';
import '../../support/plain_text.dart';

const _bank = Asset(
  rowId: 7,
  assetName: '주거래',
  assetType: 'BANK_ACCOUNT',
  institution: '신한',
);
const _savings = Asset(
  rowId: 8,
  assetName: '청약',
  assetType: 'SAVINGS',
  institution: '신한',
);
const _card = Asset(
  rowId: 9,
  assetName: '체크',
  assetType: 'CHECK_CARD',
  institution: '신한',
);

class _CapturingRepo extends RecurringRepository {
  _CapturingRepo({this.fail = false}) : super(Dio());
  final bool fail;
  bool called = false;
  bool silent = false;
  Map<String, Object?> created = {};

  @override
  Future<void> create({
    int? categoryRowId,
    int? assetRowId,
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    int? sourceExpenseRowId,
    required String expenseType,
    required int amount,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    String? executionTime,
    required String startDate,
    String? endDate,
    int? maxOccurrences,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool autoLog = false,
    bool notifyDayBefore = false,
    bool isFixed = false,
    bool silent = false,
  }) async {
    called = true;
    this.silent = silent;
    if (fail) throw ApiException(code: 'X', message: '이자는 금액보다 클 수 없습니다.');
    created = {
      'categoryRowId': categoryRowId,
      'assetRowId': assetRowId,
      'toAssetRowId': toAssetRowId,
      'fee': fee,
      'expenseType': expenseType,
      'amount': amount,
      'merchant': merchant,
      'paymentMethod': paymentMethod,
    };
  }
}

Future<_CapturingRepo> _open(WidgetTester tester, {bool fail = false}) async {
  final repo = _CapturingRepo(fail: fail);
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showRecurringFormSheet(ctx),
          child: const Text('open'),
        ),
      ),
    ),
    [
      recurringRepositoryProvider.overrideWith((ref) async => repo),
      categoriesProvider.overrideWith((ref) async => const []),
      assetsProvider.overrideWith((ref) async => [_bank, _savings, _card]),
    ],
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _pickRow(WidgetTester tester, String row, String item) async {
  await tester.tap(plain(row).last);
  await tester.pumpAndSettle();
  await tester.tap(plain(item).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('이체로 저장하면 받는 계좌 · 수수료가 실리고 카테고리는 안 실린다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(plain('이체').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '300000');
    await _pickRow(tester, '출금 계좌', '주거래');
    await _pickRow(tester, '입금 계좌', '청약');
    // 수수료는 같은 시트 안 한 단계 — 쓰고 "완료"
    await tester.tap(plain('수수료').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, '500');
    await tester.tap(plain('완료').last);
    await tester.pumpAndSettle();
    await tester.tap(plain('추가').last);
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(repo.silent, isTrue);
    expect(repo.created['expenseType'], 'TRANSFER');
    expect(repo.created['assetRowId'], 7);
    expect(repo.created['toAssetRowId'], 8);
    expect(repo.created['fee'], 500);
    expect(repo.created['amount'], 300000);
    expect(repo.created['categoryRowId'], isNull);
    expect(repo.created['merchant'], isNull);
    expect(repo.created['paymentMethod'], isNull);
  });

  testWidgets('양쪽 계좌가 없으면 저장이 안 나가고 칸 아래에 알린다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(plain('이체').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '300000');
    await tester.tap(plain('추가').last);
    await tester.pumpAndSettle();

    expect(repo.called, isFalse);
    expect(plain('보내는 계좌를 골라주세요.'), findsOneWidget);
    expect(plain('받는 계좌를 골라주세요.'), findsOneWidget);
  });

  testWidgets('카드는 이체 상대 후보에 없다 — 거래 시트와 같은 규칙', (tester) async {
    await _open(tester);
    await tester.tap(plain('이체').last);
    await tester.pumpAndSettle();
    await tester.tap(plain('출금 계좌').last);
    await tester.pumpAndSettle();

    expect(plain('주거래'), findsWidgets);
    expect(plain('청약'), findsWidgets);
    expect(plain('체크'), findsNothing);
  });

  testWidgets('저장이 실패하면 고정 글 Callout 이 서고 시트가 닫히지 않는다', (tester) async {
    await _open(tester, fail: true);
    await tester.tap(plain('이체').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '300000');
    await _pickRow(tester, '출금 계좌', '주거래');
    await _pickRow(tester, '입금 계좌', '청약');
    await tester.tap(plain('추가').last);
    await tester.pumpAndSettle();

    expect(plain('저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
    expect(findText('이자는 금액보다 클 수 없습니다.'), findsNothing);
    expect(plain('반복 거래 추가'), findsOneWidget);
  });

  testWidgets('끝 횟수 칸은 999 까지 — 999999 를 치면 999', (tester) async {
    await _open(tester);
    await tester.tap(plain('끝').last);
    await tester.pumpAndSettle();
    await tester.tap(plain('횟수만큼').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, '999999');
    await tester.pumpAndSettle();
    expect(findText('999'), findsOneWidget);
  });
}
