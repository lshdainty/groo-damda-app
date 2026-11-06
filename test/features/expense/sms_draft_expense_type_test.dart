// 결제 문자 초안에서도 **지출/수입을 고를 수 있다** (QA #123 의 앱 쪽).
//
// 한동안 잠가 뒀다(#326). 저장 경로인 `/import/sms/commit` 이 `expenseType` 을 안 받고
// 서버가 `EXPENSE` 를 박아 넣어서, 토글을 수입으로 바꿔 저장해도 지출로 남았기
// 때문이다 — 환불·입금 문자가 지출로 잡혀 그 달 지출이 부풀고 그 돈은 수입에 안 잡혔다.
// 화면만 수입이라 말하느니 못 고르게 두는 게 나았다.
//
// **서버가 이제 그 값을 받는다**(desk-back #326 — `CommitRequest.expenseType`,
// 안 오면 지출). 그래서 잠금을 풀고 값을 싣는다. 여기서 잠그는 것은 넷이다.
//   ① 문자 초안에서 '수입' 이 실제로 눌린다 — 화면이 바뀐다
//   ② 종류를 바꾸면 안 맞는 카테고리를 놓는다. 서버가 종류≠카테고리 종류를 400 으로
//      막으므로(`ExpenseServiceImpl.createExpense`) 들고 있어 봐야 저장이 실패한다.
//      문자 초안은 지출 카테고리를 미리 채워 오므로 바로 걸리는 자리다(웹 정합)
//   ③ 고른 종류가 **본문에 실린다** — 이게 없으면 화면만 바뀌고 서버는 지출로 남긴다
//   ④ 이체는 여전히 없다. 저장이 일반 이체 경로로 새면 취소 문자 차단·카드 기억이
//      조용히 빠진다 — 그 가드는 문자 경로에만 있다
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) "무엇을 보내는가" 를 여기서 고정한다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';

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
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
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
class _CapturingSmsRepo extends SmsRepository {
  _CapturingSmsRepo() : super(Dio());

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

Future<(_CapturingSmsRepo, AppLocalizations)> _open(
  WidgetTester tester, {
  SmsDraft? draft,
}) async {
  final repo = _CapturingSmsRepo();
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

void main() {
  // 종류가 바뀌면 이 라벨이 '수입처' 로 바뀐다 — 화면에서 종류를 읽는 자리다.
  testWidgets('문자 초안에서 수입으로 바꿀 수 있다', (tester) async {
    final (_, l) = await _open(tester, draft: _draft);

    expect(findText(l.expPayee), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tx-type-INCOME')));
    await tester.pumpAndSettle();

    expect(
      findText(l.expIncomeSource),
      findsOneWidget,
      reason: '잠겨 있으면 환불·입금 문자를 수입으로 남길 방법이 없다',
    );
    expect(findText(l.expPayee), findsNothing);
  });

  testWidgets('수입으로 바꾸면 지출 카테고리를 놓는다', (tester) async {
    final (repo, l) = await _open(tester, draft: _draft);

    await tester.tap(find.byKey(const ValueKey('tx-type-INCOME')));
    await tester.pumpAndSettle();
    // 카테고리를 놓았으니 [추가] 는 요청 없이 카테고리 오류를 낸다 — 지출 카테고리를 든 채 저장하면 서버가 400 으로 막는다
    await tester.tap(
      find
          .ancestor(of: findText(l.expAddShort), matching: find.byType(PButton))
          .first,
    );
    await tester.pumpAndSettle();

    expect(findText(l.txfErrCategory), findsOneWidget);
    expect(repo.called, isFalse);
  });

  testWidgets('수입으로 저장하면 INCOME 이 실린다', (tester) async {
    final (repo, l) = await _open(tester, draft: _draft);

    await tester.tap(find.byKey(const ValueKey('tx-type-INCOME')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tx-row-category')));
    await tester.pumpAndSettle();
    await tester.tap(findText('급여').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(of: findText(l.expAddShort), matching: find.byType(PButton))
          .first,
    );
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(
      repo.expenseType,
      'INCOME',
      reason: '안 실으면 서버가 지출로 본다 — 화면만 수입이고 기록은 지출이 된다',
    );
    expect(repo.categoryRowId, _incomeCategory.rowId);
  });

  testWidgets('지출 그대로 저장하면 EXPENSE 가 실린다', (tester) async {
    final (repo, l) = await _open(tester, draft: _draft);

    await tester.tap(
      find
          .ancestor(of: findText(l.expAddShort), matching: find.byType(PButton))
          .first,
    );
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '저장이 안 불렸다');
    expect(repo.expenseType, 'EXPENSE');
    expect(repo.categoryRowId, _expenseCategory.rowId);
  });

  testWidgets('문자 초안의 이체 칩은 보이되 막혀 있다', (tester) async {
    await _open(tester, draft: _draft);
    final chip = tester.widget<PChip>(
      find.byKey(const ValueKey('tx-type-TRANSFER')),
    );
    expect(
      chip.onPressed,
      isNull,
      reason: '이체를 고르면 저장이 일반 이체 경로로 새 취소 문자 차단 · 카드 기억이 빠진다',
    );
  });

  testWidgets('일반 추가에는 이체가 그대로 있다', (tester) async {
    final (_, l) = await _open(tester);
    expect(findText(l.expTypeTransfer), findsOneWidget);
  });

  // ─── 리포지토리 본문 ──────────────────────────────
  test('commit 본문에 expenseType 이 실린다', () async {
    final captured = <Map<String, dynamic>>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add((options.data as Map).cast<String, dynamic>());
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'success': true,
                'code': 'COMMON_200',
                'message': 'OK',
                'data': {'expenseRowId': 1, 'cardRemembered': false},
              },
            ),
          );
        },
      ),
    );

    await SmsRepository(dio).commit(
      text: '문자 원문',
      assetRowId: 10,
      categoryRowId: 6,
      expenseType: 'INCOME',
      amount: 12000,
      expenseDate: '2026-09-08T12:00:00',
      rememberCard: false,
    );

    expect(
      captured.single['expenseType'],
      'INCOME',
      reason: '키가 빠지면 서버가 지출로 채운다(CommitRequest.expenseType 은 nullable)',
    );
  });
}
