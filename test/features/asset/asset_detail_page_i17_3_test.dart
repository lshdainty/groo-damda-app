// I-17-3 앱 — 자산 상세 페이지 · 거래 기록 상세 시트 · 거래 취소 확인창.
// (작성만 — 이 묶음은 시험 실행을 하지 않는다. 렌더 하네스는 ~/qa/design-work/impl-audit/harness-i17-3-app.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_trade.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

const _sell = AssetTrade(
  rowId: 2,
  assetRowId: 109,
  tradeType: 'SELL',
  holdingType: 'STOCK',
  holdingKey: '숲빛전자',
  quantity: '30',
  amount: 2100000,
  fee: 0,
  realizedPl: 250000,
  tradeDate: '2026-10-09T10:00:00',
);

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('거래 기록 상세 — 키-값 줄 · 바닥 [거래 취소] · ⋮ 없음', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      _host(
        TradeDetailBody(
          trade: _sell,
          masked: false,
          onCancelTrade: () => cancelled = true,
        ),
      ),
    );
    expect(find.text('거래 기록'), findsOneWidget);
    for (final k in ['종류', '종목', '수량', '단가', '거래대금', '실현손익', '거래 일시']) {
      expect(find.text(k), findsOneWidget, reason: k);
    }
    // 수수료 0 은 줄을 그리지 않는다
    expect(find.text('수수료 · 세금'), findsNothing);
    expect(find.text('70,000원'), findsOneWidget);
    expect(find.text('+250,000원'), findsOneWidget);
    expect(plainOf('2026-10-09 10:00'), '2026-10-09 10:00');
    expect(find.byIcon(Icons.more_vert), findsNothing);
    await tester.tap(find.text('거래 취소'));
    expect(cancelled, isTrue);
  });

  testWidgets('가린 자산이면 금액 줄이 ••••', (tester) async {
    await tester.pumpWidget(
      _host(TradeDetailBody(trade: _sell, masked: true, onCancelTrade: () {})),
    );
    expect(find.text('2,100,000원'), findsNothing);
    expect(find.text('••••'), findsWidgets);
  });

  testWidgets('없는 id — 자산을 찾을 수 없어요 + [자산으로]', (tester) async {
    await tester.pumpWidget(
      _host(
        const AssetDetailScreen(assetId: 999),
        overrides: [
          assetsProvider.overrideWith((ref) async => const <Asset>[]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('자산을 찾을 수 없어요'), findsOneWidget);
    expect(find.text('자산으로'), findsOneWidget);
  });

  testWidgets('목록 실패 — Result Section + 다시 시도', (tester) async {
    await tester.pumpWidget(
      _host(
        const AssetDetailScreen(assetId: 1),
        overrides: [
          assetsProvider.overrideWith((ref) async => throw Exception('x')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('자산을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
