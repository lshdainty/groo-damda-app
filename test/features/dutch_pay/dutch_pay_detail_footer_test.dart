// 더치페이 상세 시트 — 바닥은 주 동작 + 왼쪽 [삭제] 둘, [일괄 요청] 은 머리 ⋮ 메뉴(bottom-sheet.yaml headerAction).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_detail_sheet.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_parts.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

import '../../support/plain_text.dart';

DutchPayParticipant _p(
  int id,
  String n,
  int amt, {
  bool payer = false,
  bool paid = false,
}) => DutchPayParticipant(
  rowId: id,
  participantName: n,
  amount: amt,
  isPayer: payer,
  isPaid: paid,
);

DutchPay _d({bool settled = false}) => DutchPay(
  rowId: 1,
  title: '회식 1',
  totalAmount: 184000,
  dutchPayDate: '2026-10-14',
  isSettled: settled,
  participants: [
    _p(11, '나', 61334, payer: true),
    _p(12, '철수', 61333, paid: settled),
    _p(13, '영희', 61333, paid: settled),
  ],
);

final _shot = GlobalKey();

Widget _app(DutchPay d, {double scale = 1}) => ProviderScope(
  overrides: [
    dutchPayListProvider.overrideWith((ref) async => [d]),
    hideCardProvider.overrideWith((ref, card) => false),
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
      child: RepaintBoundary(key: _shot, child: child),
    ),
    home: Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showDutchPayDetailSheet(ctx, dpId: 1),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(780, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

Future<void> _png(WidgetTester tester, String name) async {
  final dir = Platform.environment['DUTCH_SHOT_DIR'];
  if (dir == null) return;
  final ro = _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final img = await tester.runAsync(() => ro.toImage(pixelRatio: 1));
  final data = await tester.runAsync(
    () => img!.toByteData(format: ui.ImageByteFormat.png),
  );
  File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('진행 중 — 바닥 단추는 [삭제] · [모두 받음] 둘, [일괄 요청] 은 바닥에 없다', (
    tester,
  ) async {
    await _open(tester);
    await tester.pumpWidget(_app(_d()));
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    final footer = [
      for (final b in tester.widgetList<PButton>(find.byType(PButton)))
        if (b.size == PButtonSize.large) b.label,
    ];
    expect(footer, ['삭제', '모두 받음']);
    expect(findText('일괄 요청'), findsNothing);
    await _png(tester, 'dutch-detail-open');
  });

  testWidgets('머리 ⋮ — "{정산 이름} 더보기", 누르면 막힌 [일괄 요청] 줄과 이유가 뜬다', (tester) async {
    await _open(tester);
    await tester.pumpWidget(_app(_d()));
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    final more = find.bySemanticsLabel('회식 1 더보기');
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(findText('일괄 요청'), findsOneWidget);
    // 막힌 줄 — 이유 글이 줄 설명으로 붙는다(바닥 Callout 의 같은 글과 둘)
    expect(findText('송금 요청은 곧 열려요.'), findsNWidgets(2));
    await _png(tester, 'dutch-detail-menu');
  });

  testWidgets('완료 — 바닥은 [삭제] 하나 · 머리 ⋮ 없다', (tester) async {
    await _open(tester);
    await tester.pumpWidget(_app(_d(settled: true)));
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    final footer = [
      for (final b in tester.widgetList<PButton>(find.byType(PButton)))
        if (b.size == PButtonSize.large) b.label,
    ];
    expect(footer, ['삭제']);
    expect(find.bySemanticsLabel('회식 1 더보기'), findsNothing);
    expect(find.byType(PBottomSheetContent), findsOneWidget);
  });

  testWidgets('글자 200% — 바닥이 세로로 쌓여도 넘치지 않는다', (tester) async {
    await _open(tester);
    await tester.pumpWidget(_app(_d(), scale: 2));
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _png(tester, 'dutch-detail-200');
  });
}
