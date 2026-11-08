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
import 'package:groo_damda_app/features/expense/presentation/transfer_detail_sheet.dart';
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
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
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
        // 앱과 같은 자리 — 환불 · 환불 취소 결과 스낵바(ds)가 뜨는 호스트
        builder: (context, child) => Material(
          type: MaterialType.transparency,
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
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

// 삭제 버튼 · 스와이프 [삭제] 는 서버 `deletable` 로 판정한다. 없으면(옛 서버) `autoSource == null` 로 폴백.
// 수정 · 환불 · 분할은 `deletable` 과 무관하게 `autoSource` 그대로.
const _transfer = AssetTransfer(
  rowId: 7001,
  fromAssetRowId: 3,
  fromAssetName: '생활비 통장',
  toAssetRowId: 4,
  toAssetName: '증권 계좌',
  amount: 900000,
  transferDate: '2026-10-29T10:00:00',
);

void main() {
  group('모델 판정', () {
    final auto = _plain.copyWith(autoSource: 'TRADE_REALIZED');
    test('지출', () {
      expect(auto.copyWith(deletable: true).canDelete, isTrue);
      expect(_plain.copyWith(deletable: false).canDelete, isFalse);
      expect(_plain.canDelete, isTrue, reason: '누락 + 손으로 쓴 것');
      expect(auto.canDelete, isFalse, reason: '누락 + 자동 생성');
      expect(
        Expense.fromJson({...auto.toJson(), 'deletable': true}).canDelete,
        isTrue,
      );
    });
    test('이체', () {
      const auto = AssetTransfer(
        rowId: 1,
        fromAssetRowId: 1,
        toAssetRowId: 2,
        amount: 1,
        autoSource: 'TRADE_SETTLEMENT',
      );
      expect(
        AssetTransfer.fromJson({
          'rowId': 1,
          'fromAssetRowId': 1,
          'toAssetRowId': 2,
          'amount': 1,
          'autoSource': 'TRADE_SETTLEMENT',
          'deletable': true,
        }).canDelete,
        isTrue,
      );
      expect(_transfer.canDelete, isTrue);
      expect(auto.canDelete, isFalse);
    });
  });

  Future<void> open(WidgetTester tester, void Function(BuildContext) b) async {
    await _pump(
      tester,
      Builder(
        builder: (ctx) =>
            TextButton(onPressed: () => b(ctx), child: const Text('open')),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
  }

  for (final c in [
    (true, 'TRADE_REALIZED', true),
    (false, 'TRADE_REALIZED', false),
    (null, 'TRADE_REALIZED', false),
    (null, null, true),
  ]) {
    final (deletable, source, shown) = c;
    final e = _plain.copyWith(deletable: deletable, autoSource: source);
    final label = 'deletable=$deletable autoSource=$source';

    testWidgets('지출 상세 — $label 삭제 ${shown ? "보임" : "숨김"}', (tester) async {
      await open(tester, (ctx) => showTxDetailDialog(ctx, e));
      expect(findText('삭제'), shown ? findsOneWidget : findsNothing);
      if (source != null) {
        expect(findText('수정'), findsNothing, reason: '수정은 autoSource 그대로');
        expect(findText('환불'), findsNothing);
      }
    });

    testWidgets('지출 스와이프 — $label', (tester) async {
      late List<PSwipeAction> actions;
      await _pump(
        tester,
        Consumer(
          builder: (ctx, ref, _) {
            actions = expenseActions.dsSwipeActions(
              ctx,
              ref,
              e,
              asset: _account,
            );
            return const SizedBox.shrink();
          },
        ),
      );
      expect(
        actions.map((a) => a.label),
        source != null ? (shown ? ['삭제'] : <String>[]) : ['수정', '삭제'],
      );
    });

    testWidgets('이체 상세 — $label', (tester) async {
      final t = AssetTransfer(
        rowId: 7001,
        fromAssetRowId: 3,
        toAssetRowId: 4,
        amount: 900000,
        transferDate: '2026-10-29T10:00:00',
        deletable: deletable,
        autoSource: source == null ? null : 'TRADE_SETTLEMENT',
      );
      await open(tester, (ctx) => showTransferDetailSheet(ctx, t));
      expect(findText('삭제'), shown ? findsOneWidget : findsNothing);
      if (source != null) expect(findText('수정'), findsNothing);
    });
  }
}
