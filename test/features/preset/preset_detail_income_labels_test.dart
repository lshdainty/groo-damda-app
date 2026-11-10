// 프리셋 상세 값 줄 — 수입이면 "수입 방식 / 입금 계좌", 지출이면 "결제 수단 / 계좌 · 카드"(2026-11-10).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_detail_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

class _Repo extends PresetRepository {
  _Repo() : super(Dio());
}

ExpenseTemplate _t(String type) => ExpenseTemplate(
  rowId: 5,
  templateName: '프리셋',
  expenseType: type,
  assetRowId: 7,
  assetName: '주거래',
  paymentMethod: 'TRANSFER',
  amount: 4500,
);

Future<void> _open(WidgetTester tester, ExpenseTemplate p) async {
  tester.view.physicalSize = const Size(1170, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetRepositoryProvider.overrideWith((ref) async => _Repo()),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showPresetDetailSheet(ctx, template: p),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  testWidgets('수입 프리셋 상세 — 수입 방식 · 입금 계좌', (tester) async {
    await _open(tester, _t('INCOME'));
    expect(findText(l.expIncomeMethod), findsOneWidget);
    expect(findText(l.expDepositAccount), findsOneWidget);
    expect(findText(l.expPaymentMethod), findsNothing);
    expect(findText(l.presetAssetCard), findsNothing);
  });

  testWidgets('지출 프리셋 상세 — 결제 수단 · 계좌 · 카드 그대로', (tester) async {
    await _open(tester, _t('EXPENSE'));
    expect(findText(l.expPaymentMethod), findsOneWidget);
    expect(findText(l.presetAssetCard), findsOneWidget);
    expect(findText(l.expIncomeMethod), findsNothing);
    expect(findText(l.expDepositAccount), findsNothing);
  });
}
