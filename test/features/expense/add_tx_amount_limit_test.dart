import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/add_tx_drive.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/domain/sms_draft.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../../support/plain_text.dart';

// 거래 추가 — 100억을 넘겨 치면 막고 칸 아래에 알린다(대표 칸). 하위 단계에 다시 들어오면 지난 오류는 지워진다.
const _category = ExpenseCategory(
  rowId: 11,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith(
          (ref) async => ExpenseRepository(Dio()),
        ),
        assetsProvider.overrideWith((ref) async => const <Asset>[]),
        categoriesProvider.overrideWith((ref) async => const [_category]),
        presetListProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
        defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => Material(
          type: MaterialType.transparency,
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
        ),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAddTxSheet(ctx, defaultDate: '2026-10-10'),
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
  testWidgets('금액 칸 — 100억 넘게 치면 막고 알린다, 다음 유효한 입력에서 사라진다', (tester) async {
    await _open(tester);
    const msg = '금액은 100억원까지 입력할 수 있어요.';
    final field = find.byType(EditableText).first;
    await tester.enterText(field, '10000000000');
    await tester.pump();
    expect(findPlain(msg), findsNothing);

    await tester.enterText(field, '100000000000');
    await tester.pump();
    expect(findPlain(msg), findsOneWidget);
    expect(
      tester.widget<EditableText>(field).controller.text,
      '10,000,000,000',
      reason: '넘는 글자는 받지 않는다',
    );

    await tester.enterText(field, '5000');
    await tester.pump();
    expect(findPlain(msg), findsNothing);
  });
}
