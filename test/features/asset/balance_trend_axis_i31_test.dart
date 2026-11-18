// I-31 별건 — 잔액 추이 세로축 폭은 가장 긴 눈금 글자("−5,000만")를 재서 잡는다.
// 고정 폭 52 일 때는 360 폭 · 글자 200% 에서 왼쪽 끝이 잘려 `−2,500만` 이 `2,500만` 으로 읽혔다
// (chart.md:46 "세로축의 폭은 가장 긴 글자('−3,000만')가 잘리지 않게" · 결함 D6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import '../../support/plain_text.dart';

const _loan = Asset(
  rowId: 10,
  assetName: '전세자금대출',
  assetType: 'LOAN',
  balance: -85000000,
);

const _trend = [
  AssetBalancePoint(weekStart: '2026-09-07', balance: -82000000),
  AssetBalancePoint(weekStart: '2026-09-14', balance: -83000000),
  AssetBalancePoint(weekStart: '2026-09-21', balance: -84000000),
  AssetBalancePoint(weekStart: '2026-09-28', balance: -85000000),
];

Future<void> _open(WidgetTester tester, double scale) async {
  tester.view.physicalSize = const Size(720, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [_loan]),
        assetBalanceTrendProvider.overrideWith((ref, key) async => _trend),
        assetTransfersProvider.overrideWith(
          (ref, key) async => const <AssetTransfer>[],
        ),
        expensesByAssetProvider.overrideWith((ref, key) async => const []),
        assetPeriodExpensesProvider.overrideWith((ref, key) async => const []),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetDetailRich(ctx, _loan),
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
  for (final scale in [1.0, 2.0]) {
    // I-17 48 — 추이 차트는 ds 선 차트다(축 폭은 ds 가 가장 긴 눈금 글자로 잡는다). 음수 눈금의 U+2212 가 그대로 남는다.
    testWidgets('잔액 추이는 ds 선 차트이고 음수 눈금에 U+2212 가 있다 — 글자 x$scale', (
      tester,
    ) async {
      await _open(tester, scale);
      expect(find.byType(PLineChart), findsOneWidget);
      // 머리 금액("−85,000,000원")이 아니라 눈금 글이 그려진다 — 눈금은 줄인 글("−1억")
      // 가리지 않으면 ds 기본 눈금 글(한 축은 한 단위 — 이 축은 −1억 ~ 0 이라 모두 억 단위). 간격은 100% 0.2억 · 200% 는 눈금
      // 글 줄이 눈금 사이보다 커서 칸 수를 줄여 0.5억(chart.md "세로 눈금이 겹치면 수를 줄입니다")
      expect(
        tester.widget<PLineChart>(find.byType(PLineChart)).axisFormatter,
        isNull,
      );
      expect(findText('−1억'), findsOneWidget);
      expect(findText(scale == 1 ? '−0.2억' : '−0.5억'), findsOneWidget);
      expect(findText('−2,500만'), findsNothing);
    });
  }

  test('chartAxisWidth — 가장 긴 글자(부호 포함) + 여백', () {
    const style = TextStyle(fontSize: 12);
    final wide = measureText('−5,000만', style);
    final w = chartAxisWidth(['0', '−5,000만', '−1억'], style);
    expect(w, wide + kChartTickMargin);
    expect(chartAxisWidth(const [], style), kChartTickMargin);
    expect(
      chartAxisWidth(['−5,000만'], style, scaler: const TextScaler.linear(2)),
      greaterThan(w),
    );
  });
}
