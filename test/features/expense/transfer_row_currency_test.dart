// 이체 줄의 통화(I-13) — 금액 · 수수료는 보내는 계좌 통화, 받는 쪽 관점은 받은 금액(toAmount)을 받는 계좌 통화로.
// 통화가 다른 이체는 금액 아래 작게 "받는 금액 …" 이 붙는다. 외화는 소수 없이("$1,000"). 웹 transfer-row 와 같은 글이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/transfer_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/plain_text.dart';

const _flags = MaskFlags(
  card: false,
  expense: false,
  income: false,
  transfer: false,
);

String? _cur(int id) => switch (id) {
  1 => 'KRW',
  2 => 'USD',
  _ => null,
};

/// 원화 통장(1) → USD 증권계좌(2) 1,300,000원, 서버 toAmount $1,000
const _krwToUsd = AssetTransfer(
  rowId: 1,
  fromAssetRowId: 1,
  fromAssetName: '생활비 통장',
  toAssetRowId: 2,
  toAssetName: '해외 증권계좌',
  amount: 1300000,
  toAmount: 1000,
  transferDate: '2026-11-02T00:00:00',
);

/// USD 증권계좌(2) → 원화 통장(1) $100, 서버 toAmount 130,000원
const _usdToKrw = AssetTransfer(
  rowId: 2,
  fromAssetRowId: 2,
  fromAssetName: '해외 증권계좌',
  toAssetRowId: 1,
  toAssetName: '생활비 통장',
  amount: 100,
  toAmount: 130000,
  transferDate: '2026-11-03T00:00:00',
);

Future<void> _pump(WidgetTester tester, Widget row) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: row),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('가계부(관점 없음) — 보내는 통화 금액 + 받는 금액 작은 글', (tester) async {
    await _pump(
      tester,
      const TransferRow(transfer: _krwToUsd, flags: _flags, currencyOf: _cur),
    );
    expect(findPlain('1,300,000원'), findsOneWidget);
    expect(findPlain(r'받는 금액 $1,000'), findsOneWidget);
  });

  testWidgets('USD 계좌 관점 — 받는 쪽은 받은 금액을 그 통화로 "+\$1,000"', (tester) async {
    await _pump(
      tester,
      const TransferRow(
        transfer: _krwToUsd,
        flags: _flags,
        perspectiveAssetRowId: 2,
        currencyOf: _cur,
      ),
    );
    expect(findPlain(r'+$1,000'), findsOneWidget);
    expect(
      findPlain(r'받는 금액 $1,000'),
      findsNothing,
      reason: '받는 쪽 관점엔 받는 금액 줄이 없다',
    );
  });

  testWidgets('USD 계좌에서 나가는 이체 — "−\$100" + "받는 금액 130,000원"', (tester) async {
    await _pump(
      tester,
      const TransferRow(
        transfer: _usdToKrw,
        flags: _flags,
        perspectiveAssetRowId: 2,
        currencyOf: _cur,
      ),
    );
    expect(findPlain('−\$100'), findsOneWidget);
    expect(findPlain('받는 금액 130,000원'), findsOneWidget);
  });

  testWidgets('통화를 모르면(currencyOf 없음) 원화로 찍는다 — 지금 그대로', (tester) async {
    await _pump(tester, const TransferRow(transfer: _usdToKrw, flags: _flags));
    expect(findPlain('100원'), findsOneWidget);
  });
}
