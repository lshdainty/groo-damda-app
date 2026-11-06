// 거래 입력의 '현재 입력값 저장'(QA 30 14).
//
//   ① 계좌를 비워 둬도 저장한다 — 서버·리포지토리는 비운 계좌를 받는다. 종전엔 계좌가 비면
//      저장 함수 첫 줄이 안내 없이 끝나, 누른 게 아무 일도 안 한 것처럼 보였다
//   ② 이름을 치면 [저장] 이 바로 켜진다 — 종전엔 이름 칸을 듣는 쪽이 없어 '금액 고정' 을
//      건드려야 켜졌다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/add_tx_drive.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../../support/plain_text.dart';

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
  isIncludedInTotal: 'Y',
);

class _Presets extends PresetRepository {
  _Presets() : super(Dio());
  Map<String, Object?>? created;

  @override
  Future<ExpenseTemplate> create({
    required String templateName,
    int? categoryRowId,
    int? assetRowId,
    int? toAssetRowId,
    int? fee,
    int? interestAmount,
    required String expenseType,
    int? amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? sortOrder,
    bool lockAmount = false,
    bool isFixed = false,
    bool silent = false,
  }) async {
    created = {'templateName': templateName, 'assetRowId': assetRowId};
    return ExpenseTemplate(
      rowId: 1,
      templateName: templateName,
      expenseType: expenseType,
    );
  }
}

Future<(_Presets, AppLocalizations)> _openSaveDialog(
  WidgetTester tester,
) async {
  final presets = _Presets();
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
        categoriesProvider.overrideWith((ref) async => [_category]),
        assetsProvider.overrideWith((ref) async => [_account]),
        presetListProvider.overrideWith((ref) async => []),
        presetRepositoryProvider.overrideWith((ref) async => presets),
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
        builder: (c, ch) => PSnackbarHost(closeLabel: '닫기', child: ch!),
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
  final l = await AppLocalizations.delegate.load(const Locale('ko'));
  // 프리셋 저장은 카테고리가 있어야 한다 — 금액 → 2단계 카테고리, 계좌는 비워 둔다. 1단계로 돌아와 "현재 입력값 저장" 을 누른다.
  await fillNewTx(tester, amount: '13000');
  await tester.tap(find.bySemanticsLabel(l.actionBack).first);
  await tester.pumpAndSettle();
  await tester.tap(findText(l.expPresetSaveCurrent));
  await tester.pumpAndSettle();
  return (presets, l);
}

Finder _saveButton(AppLocalizations l) =>
    find.widgetWithText(PButton, l.actionSave);

void main() {
  testWidgets('이름이 비면 [저장] 은 눌려도 요청 없이 이름 칸 오류를 낸다', (tester) async {
    final (presets, l) = await _openSaveDialog(tester);
    // 버튼은 꺼 두지 않는다 — 누를 때 검증한다
    expect(tester.widget<PButton>(_saveButton(l)).onPressed, isNotNull);
    await tester.tap(_saveButton(l));
    await tester.pumpAndSettle();

    expect(findText(l.txfPresetNameRequired), findsOneWidget);
    expect(presets.created, isNull);
  });

  testWidgets('계좌를 비워 둬도 저장한다 — 안내 없이 끝나지 않는다', (tester) async {
    final (presets, l) = await _openSaveDialog(tester);
    await tester.enterText(find.byType(EditableText).first, '점심 정식');
    await tester.pump();
    await tester.tap(_saveButton(l));
    await tester.pumpAndSettle();

    expect(presets.created, isNotNull, reason: '계좌가 비었다고 저장을 건너뛰었다');
    expect(presets.created!['templateName'], '점심 정식');
    expect(presets.created!['assetRowId'], isNull);
    // 저장 알림은 ds 스낵바(neutral) — 시트 위 호스트에 한 문장 + 마침표
    expect(findText(l.txfPresetSaved('점심 정식')), findsOneWidget);
  });
}
