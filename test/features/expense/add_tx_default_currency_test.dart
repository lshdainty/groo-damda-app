// 설정의 **기본 통화**를 새 거래도 쓴다 (D7 · QA #124).
//
// 사용자가 확정한 범위는 **자산 + 거래 둘 다**이고 웹은 이미 그렇게 나갔다
// (desk-front #368). 앱만 안 쓰면 같은 계정인데 브라우저에서는 USD 로 열리는 폼이
// 폰에서는 원화로 열린다.
//
// 여기서 잠그는 것 넷:
//   ① **새 거래**는 기본 통화로 열린다 — 외화면 현지 금액·환율 칸이 함께 열린다
//   ② **편집은 이 거래의 값으로 연다.** 원화 거래는 `originalCurrency` 가 `null` 로
//      오므로, 안 막으면 원화로 적어 둔 거래가 해외 결제 입력으로 열린다.
//      거래 쪽이 자산보다 위험한 자리다
//   ③ **문자 초안도 문자가 맞다.** 외화가 안 실린 결제 문자는 원화 결제다
//   ④ **늦게 도착해도 반영된다** — `/me/preferences` 는 이 시트보다 늦게 온다
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) "무엇이 보이는가" 를 위젯 테스트로 잠근다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

/// 테스트가 손으로 미는 기본 통화 — 늦게 도착하는 상황을 그대로 만든다.
class _DefaultCurrencyStub extends Notifier<String> {
  _DefaultCurrencyStub(this.initial);
  final String initial;

  @override
  String build() => initial;

  void push(String code) => state = code;
}

final _serverDefault = NotifierProvider<_DefaultCurrencyStub, String>(
  () => _DefaultCurrencyStub('KRW'),
);

const _category = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
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

/// 원화로 적어 둔 거래 — `originalCurrency` 가 없다(그게 원화라는 뜻이다).
const _krwTx = Expense(
  rowId: 77,
  categoryRowId: 5,
  assetRowId: 10,
  expenseType: 'EXPENSE',
  amount: 12000,
  expenseDate: '2026-09-01T12:00:00',
  merchant: '스타벅스',
);

/// 외화가 안 실린 승인 문자 — 원화 결제다.
const _krwDraft = SmsDraft(
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

Future<AppLocalizations> _open(
  WidgetTester tester,
  void Function(BuildContext ctx) show, {
  String defaultCurrency = 'KRW',
}) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _serverDefault.overrideWith(
          () => _DefaultCurrencyStub(defaultCurrency),
        ),
        // 실제 provider 는 `/me/preferences` 를 타므로 값만 흘려보낸다.
        defaultCurrencyProvider.overrideWith(
          (ref) => ref.watch(_serverDefault),
        ),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_account]),
        presetListProvider.overrideWith((ref) async => []),
        expenseRepositoryProvider.overrideWith(
          (ref) async => ExpenseRepository(Dio()),
        ),
        smsRepositoryProvider.overrideWith((ref) async => SmsRepository(Dio())),
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
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('ko'));
}

const _chipKey = ValueKey('tx-currency-chip');

/// 1단계 금액을 치고 [다음] — 외화면 2단계에 환율 칸 · 원화 금액 줄이 열린다.
Future<void> _toStepTwo(WidgetTester tester, String amount) async {
  await tester.enterText(find.byType(EditableText).first, amount);
  await tester.tap(findText('다음'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('새 거래는 설정의 기본 통화로 열린다', (tester) async {
    final l = await _open(tester, showAddTxSheet, defaultCurrency: 'USD');

    expect(findText('\$ USD'), findsOneWidget);
    await _toStepTwo(tester, '5.5');
    expect(
      findText(l.expExchangeRate),
      findsOneWidget,
      reason: '외화면 환율 칸 · 원화 금액 줄이 열려야 원 통화 기록이 남는다',
    );
    expect(find.byKey(const ValueKey('tx-row-krw')), findsOneWidget);
  });

  testWidgets('설정이 원화면 종전 그대로 원화다', (tester) async {
    final l = await _open(tester, showAddTxSheet);

    expect(findText('₩ KRW'), findsOneWidget);
    await _toStepTwo(tester, '5500');
    expect(findText(l.expExchangeRate), findsNothing);
    expect(find.byKey(const ValueKey('tx-row-krw')), findsNothing);
  });

  testWidgets('원화로 적어 둔 거래는 기본 통화가 USD 여도 원화로 열린다', (tester) async {
    // 여기가 자산보다 위험하다 — 원화 거래는 `originalCurrency` 가 `null` 이라
    // 막지 않으면 열기만 해도 해외 결제 입력이 펼쳐지고, 그대로 저장하면
    // 원화 거래에 없던 원 통화 기록이 붙는다. 수정은 2단계로 바로 열린다.
    final l = await _open(
      tester,
      (ctx) => showAddTxSheet(ctx, edit: _krwTx),
      defaultCurrency: 'USD',
    );

    expect(findText(l.expExchangeRate), findsNothing);
    expect(find.byKey(const ValueKey('tx-row-krw')), findsNothing);
  });

  testWidgets('외화가 안 실린 결제 문자는 원화로 열린다', (tester) async {
    // 문자에 외화가 없으면 원화 결제다 — 설정이 외화여도 여기선 문자가 맞다.
    final l = await _open(
      tester,
      (ctx) => showAddTxSheet(ctx, smsDraft: _krwDraft),
      defaultCurrency: 'USD',
    );

    expect(findText(l.expExchangeRate), findsNothing);
    expect(find.byKey(const ValueKey('tx-row-krw')), findsNothing);
  });

  testWidgets('기본 통화가 시트보다 늦게 와도 반영된다', (tester) async {
    await _open(tester, showAddTxSheet);
    expect(findText('₩ KRW'), findsOneWidget);

    ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(_serverDefault.notifier).push('USD');
    await tester.pumpAndSettle();

    expect(
      findText('\$ USD'),
      findsOneWidget,
      reason: '열 때 한 번만 읽어 굳히면 첫 렌더의 원화에 잠긴다',
    );
  });

  testWidgets('고른 값이 기본 통화를 이긴다', (tester) async {
    await _open(tester, showAddTxSheet, defaultCurrency: 'USD');

    await tester.tap(find.byKey(_chipKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PListButtonItem && w.title.contains('JPY'),
      ),
    );
    await tester.pumpAndSettle();

    expect(findText('¥ JPY'), findsOneWidget);
    expect(findText('\$ USD'), findsNothing);
  });
}
