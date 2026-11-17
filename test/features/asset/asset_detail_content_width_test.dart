// 계좌 · 카드 상세 — 넓은 화면(iPad · Duo 펼침)에서 본문이 720 가운데에 서고, 옆 안전 영역 밑에 깔리지 않는다
// (groo-design #231 Layout "Safe Area" · "콘텐츠 폭").
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_content.dart';

const _card = Asset(
  rowId: 9,
  assetName: '숲빛카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 12,
);
const _account = Asset(
  rowId: 3,
  assetName: '숲빛은행 입출금',
  assetType: 'BANK_ACCOUNT',
  balance: 1250000,
);

Future<Rect> _bodyRect(
  WidgetTester tester,
  Asset asset, {
  required Size size,
  double right = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(right: right);
  tester.view.viewPadding = tester.view.padding;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        assetsProvider.overrideWith((ref) async => [_card, _account]),
        hideCardProvider.overrideWith((ref, c) => false),
        cardBillingProvider.overrideWith(
          (ref, id) => Completer<Never>().future,
        ),
        cardPerformanceProvider.overrideWith(
          (ref, key) => Completer<Never>().future,
        ),
        assetBalanceTrendProvider.overrideWith((ref, key) async => const []),
        assetTransfersProvider.overrideWith(
          (ref, key) async => const <AssetTransfer>[],
        ),
        expensesByAssetProvider.overrideWith(
          (ref, key) => Completer<Never>().future,
        ),
        assetPeriodExpensesProvider.overrideWith(
          (ref, key) => Completer<Never>().future,
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: AssetDetailScreen(assetId: asset.rowId),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return tester.getRect(
    find.byWidgetPredicate((w) => w.runtimeType.toString() == '_DetailBody'),
  );
}

void main() {
  for (final asset in [_account, _card]) {
    final what = asset == _card ? '카드 상세' : '계좌 상세';

    testWidgets('$what — iPad 세로(820) · 본문은 720 가운데', (tester) async {
      final r = await _bodyRect(tester, asset, size: const Size(820, 1180));
      expect(r.width, kContentMaxWidth);
      expect(r.left, (820 - kContentMaxWidth) / 2);
    });

    testWidgets('$what — iPad 가로(1180) · 본문은 720 가운데', (tester) async {
      final r = await _bodyRect(tester, asset, size: const Size(1180, 820));
      expect(r.width, kContentMaxWidth);
      expect(r.left, (1180 - kContentMaxWidth) / 2);
    });

    testWidgets('$what — Duo 접힘 · 옆 상태 칸(오른쪽 84) 왼쪽', (tester) async {
      final r = await _bodyRect(
        tester,
        asset,
        size: const Size(466, 678),
        right: 84,
      );
      expect(r.left, 0);
      expect(r.right, 466 - 84);
    });
  }
}
