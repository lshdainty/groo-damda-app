// 결제 문자를 다 읽지 못하면 2단계 맨 위에 "일부 항목을 읽지 못했어요" 안내가 뜬다(QA damda-full-1116 B3).
//
// 서버는 카드사만 알아보면 거래처 · 날짜가 없어도 MEDIUM 을 준다("신한카드 12,000원 승인") — 확신(LOW)만 보면
// 빈 거래처를 알리지 못한다. 그래서 확신이 낮거나 금액 · 거래처 · 날짜 중 하나라도 비면 안내를 띄운다(웹 `smsNeedsReview`).
// 거래처가 공백뿐이어도 못 읽은 것이다.
//
// 바꾸지 않는 것: 문자로 채운 창을 [×] 로 닫을 때 묻지 않는다(사용자 결정 — `_seed` 가 처음 값을 다시 잡는다).
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

const _account = Asset(
  rowId: 10,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

const _notice = '일부 항목을 읽지 못했어요. 확인하고 채워주세요.';

SmsParseResult _parsed({
  String confidence = 'HIGH',
  int? amount = 12000,
  String? merchant = '스타벅스',
  String? expenseDate = '2026-11-16T13:22',
}) => SmsParseResult(
  matched: true,
  confidence: confidence,
  cancel: false,
  amount: amount,
  merchant: merchant,
  expenseDate: expenseDate,
  assetRemembered: true,
  assetCandidates: const [],
);

/// 문자 해석만 정해 둔 값으로 돌려주는 가짜 레포지토리.
class _Repo extends SmsRepository {
  _Repo(this.result) : super(Dio());

  final SmsParseResult result;

  @override
  Future<SmsParseResult> parse(String text, {bool silent = false}) async =>
      result;
}

/// 새 거래 시트를 열고 1단계 "결제 문자 붙여넣기" → 문자 읽기까지 간다.
Future<void> _readSms(WidgetTester tester, SmsParseResult result) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => [_expenseCategory]),
        assetsProvider.overrideWith((ref) async => [_account]),
        presetListProvider.overrideWith((ref) async => []),
        smsRepositoryProvider.overrideWith((ref) async => _Repo(result)),
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
              onPressed: () => showAddTxSheet(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('tx-sms-row')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('tx-sub-sms')),
      matching: find.byType(EditableText),
    ),
    '[Web발신] 신한카드 12,000원 승인',
  );
  await tester.pump();
  await tester.tap(findText('문자 읽기'));
  await tester.pumpAndSettle();
}

void main() {
  group('SmsParseResult.needsReview', () {
    test('다 읽은 HIGH 는 확인하지 않아도 된다', () {
      expect(_parsed().needsReview, isFalse);
    });
    test('LOW 는 칸이 다 차도 확인한다', () {
      expect(_parsed(confidence: 'LOW').needsReview, isTrue);
    });
    test('MEDIUM 이라도 거래처 · 날짜가 없으면 확인한다', () {
      expect(
        _parsed(
          confidence: 'MEDIUM',
          merchant: null,
          expenseDate: null,
        ).needsReview,
        isTrue,
      );
    });
    test('금액 · 거래처 · 날짜 하나만 비어도 확인한다', () {
      expect(_parsed(amount: null).needsReview, isTrue);
      expect(_parsed(merchant: null).needsReview, isTrue);
      expect(_parsed(merchant: '   ').needsReview, isTrue);
      expect(_parsed(expenseDate: null).needsReview, isTrue);
      expect(_parsed(expenseDate: '').needsReview, isTrue);
    });
  });

  testWidgets('거래처 · 날짜 없는 MEDIUM("신한카드 12,000원 승인") — 2단계에 안내가 뜬다', (
    tester,
  ) async {
    await _readSms(
      tester,
      _parsed(confidence: 'MEDIUM', merchant: null, expenseDate: null),
    );
    expect(findText(_notice), findsOneWidget);
  });

  testWidgets('거래처가 공백뿐이면 못 읽은 것이다 — 안내가 뜬다', (tester) async {
    await _readSms(tester, _parsed(merchant: '  '));
    expect(findText(_notice), findsOneWidget);
  });

  testWidgets('다 읽은 문자에는 안내가 없다', (tester) async {
    await _readSms(tester, _parsed());
    expect(findText(_notice), findsNothing);
  });

  testWidgets('문자로 채운 직후 [×] 는 묻지 않고 닫힌다(사용자 결정 — 고정)', (tester) async {
    await _readSms(
      tester,
      _parsed(confidence: 'MEDIUM', merchant: null, expenseDate: null),
    );
    expect(findText(_notice), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('닫기').first);
    await tester.pumpAndSettle();
    expect(findText('작성한 내용이 사라져요'), findsNothing);
    expect(findText(_notice), findsNothing, reason: '시트가 닫혔다');
  });
}
