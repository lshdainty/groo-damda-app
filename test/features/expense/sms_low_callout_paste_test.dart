// 붙여넣기 화면 길로 연 시트(`smsDraft` 를 받은 AddTxSheet)에서도 확신 낮은 문자의
// "일부 항목을 읽지 못했어요" 안내가 **한 번** 뜬다. B5 에서 붙여넣기 화면의 스낵바를
// 걷으며 시트 Callout 에 맡겼는데, initState 가 `_smsLow` 를 세우지 않아 아무 데도 안 떴다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

const _expenseCategory = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

const _incomeCategory = ExpenseCategory(
  rowId: 6,
  categoryName: '급여',
  expenseType: 'INCOME',
  sortOrder: 0,
  icon: 'wallet',
  color: '#2c70bf',
);

const _account = Asset(
  rowId: 10,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

/// 승인 문자 하나 — 파서가 알아보고 지출 카테고리까지 채워 온 상태.
const _draft = SmsDraft(
  text: '[Web발신] 국민카드 승인 12,000원 스타벅스',
  parsed: SmsParseResult(
    matched: true,
    confidence: 'HIGH',
    cancel: false,
    amount: 12000,
    merchant: '스타벅스',
    categoryRowId: 5,
    categoryName: '식비',
    assetRemembered: true,
    assetCandidates: [],
  ),
);

/// 문자 저장 경로로 넘어간 인자를 잡는 가짜 레포지토리.
class _Repo extends SmsRepository {
  _Repo() : super(Dio());

  bool called = false;
  String? expenseType;
  int? categoryRowId;

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
    called = true;
    this.expenseType = expenseType;
    this.categoryRowId = categoryRowId;
    return const SmsCommitResult(expenseRowId: 1, cardRemembered: false);
  }
}

/// 저장 버튼 — onPressed 가 null 이면 잠긴 상태.

Future<(_Repo, AppLocalizations)> _open(
  WidgetTester tester, {
  SmsDraft? draft,
}) async {
  final repo = _Repo();
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith(
          (ref) async => [_expenseCategory, _incomeCategory],
        ),
        assetsProvider.overrideWith((ref) async => [_account]),
        presetListProvider.overrideWith((ref) async => []),
        smsRepositoryProvider.overrideWith((ref) async => repo),
        // `_submit` 은 문자 경로로 갈라지기 전에 지출 레포지토리를 먼저 읽는다 —
        // 안 갈아 끼우면 실제 Dio 를 만들려다 테스트가 그 자리에서 멈춘다.
        expenseRepositoryProvider.overrideWith(
          (ref) async => ExpenseRepository(Dio()),
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
              onPressed: () => showAddTxSheet(ctx, smsDraft: draft),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return (repo, await AppLocalizations.delegate.load(const Locale('ko')));
}

SmsDraft _with(String confidence) => SmsDraft(
  text: _draft.text,
  parsed: SmsParseResult(
    matched: true,
    confidence: confidence,
    cancel: false,
    amount: 12000,
    merchant: '스타벅스',
    categoryRowId: 5,
    categoryName: '식비',
    assetRemembered: true,
    assetCandidates: const [],
  ),
);

void main() {
  testWidgets('확신 낮은 문자 초안으로 열면 안내가 한 번 뜬다', (tester) async {
    final (_, l) = await _open(tester, draft: _with('LOW'));
    expect(findText(l.smsLowConfidence), findsOneWidget);
  });

  testWidgets('확신 높은 문자 초안에는 안내가 없다', (tester) async {
    final (_, l) = await _open(tester, draft: _with('HIGH'));
    expect(findText(l.smsLowConfidence), findsNothing);
  });

  testWidgets('문자 없이 열면 안내가 없다', (tester) async {
    final (_, l) = await _open(tester);
    expect(findText(l.smsLowConfidence), findsNothing);
  });
}
