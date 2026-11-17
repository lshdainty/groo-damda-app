// 더치페이 화면 · 상세 시트(I-15-3) — 받을 돈에서 결제자 제외, 친구 탭, 긴 목록 끝까지 스크롤, 상세 막힌 요청 단추.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_detail_sheet.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
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

DutchPay _d(int id, {bool settled = false}) => DutchPay(
  rowId: id,
  title: '회식 $id',
  totalAmount: 184000,
  dutchPayDate: '2026-10-14',
  isSettled: settled,
  participants: [
    _p(id * 10 + 1, '나', 61334, payer: true),
    _p(id * 10 + 2, '철수', 61333),
    _p(id * 10 + 3, '영희', 61333),
  ],
);

Widget _app(List<DutchPay> items, Widget home) => ProviderScope(
  overrides: [
    dutchPayListProvider.overrideWith((ref) async => items),
    hideCardProvider.overrideWith((ref, card) => false),
  ],
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: home,
  ),
);

void main() {
  testWidgets('받을 돈은 결제자를 뺀 122,666원 · 2명이다', (tester) async {
    tester.view.physicalSize = const Size(780, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app([_d(1)], const DutchPayScreen()));
    await tester.pumpAndSettle();
    expect(findTextContaining('122,666'), findsWidgets);
    expect(findTextContaining('2명에게서'), findsOneWidget);
  });

  testWidgets('친구 탭에 결제자(나)가 없다', (tester) async {
    tester.view.physicalSize = const Size(780, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app([_d(1)], const DutchPayScreen()));
    await tester.pumpAndSettle();
    await tester.tap(findTextContaining('친구'));
    await tester.pumpAndSettle();
    expect(findText('철수'), findsOneWidget);
    expect(findText('나'), findsNothing);
  });

  testWidgets('정산 일곱 개 — 마지막 줄까지 스크롤된다', (tester) async {
    tester.view.physicalSize = const Size(780, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app([for (var i = 1; i <= 7; i++) _d(i)], const DutchPayScreen()),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(findText('회식 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상세 — 송금 요청은 막혀 있고 이유 줄이 있다', (tester) async {
    tester.view.physicalSize = const Size(780, 2000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        [_d(1)],
        Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showDutchPayDetailSheet(ctx, dpId: 1),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PCallout), findsOneWidget);
    expect(findText('송금 요청은 곧 열려요.'), findsOneWidget);
    final disabled = tester
        .widgetList<PButton>(find.byType(PButton))
        .where((b) => b.label == '요청');
    expect(disabled, isNotEmpty);
    expect(disabled.every((b) => b.onPressed == null), isTrue);
    // 1인당 줄: 나머지 1원은 몫이 큰 사람(나)
    expect(findTextContaining('1원은 나'), findsWidgets);
  });

  // iPhone Duo 안전 영역(groo-design Layout "Safe Area" · "콘텐츠 폭") — 탭 줄 · 목록 · [+] 가 옆 상태 칸(오른쪽 84)
  // 밑에 깔리지 않고, 넓은 화면(768 이상)에서는 본문처럼 720 안에 선다. 바탕 띠는 화면 끝까지 간다.
  for (final duo in [
    (name: '접힘', size: const Size(466, 678)),
    (name: '펼침', size: const Size(951, 669)),
  ]) {
    testWidgets('Duo ${duo.name} — 탭 줄 · 줄 · [+] 가 상태 칸 왼쪽(넓으면 720 안)', (
      tester,
    ) async {
      const right = 84.0;
      final size = duo.size;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(right: right);
      tester.view.viewPadding = tester.view.padding;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app([_d(1), _d(2, settled: true)], const DutchPayScreen()),
      );
      await tester.pumpAndSettle();

      final inner = size.width - right;
      final wide = size.width >= 768;
      final left = wide ? (inner - 720) / 2 : 0.0;
      final limit = wide ? left + 720 : inner;

      // 바탕 띠는 상태 칸 앞에서 끊긴다 — 좌우 안전 영역 칸은 뒷배경(groo-design Layout "Safe Area")
      expect(
        tester.getRect(find.byKey(const ValueKey('dutch-list-band'))).right,
        inner,
      );

      void inside(Finder f, String what) {
        final r = tester.getRect(f);
        expect(r.right, lessThanOrEqualTo(limit + 0.01), reason: '$what 오른쪽 끝');
        expect(r.left, greaterThanOrEqualTo(left - 0.01), reason: '$what 왼쪽 끝');
      }

      inside(
        find.byWidgetPredicate((w) => w is PSegmentedControl),
        'Segmented',
      );
      inside(find.byKey(const ValueKey('dutch-1')), '진행 중 줄');
      inside(find.byKey(const ValueKey('floating-action-button')), '[+]');

      // 완료 탭 · 친구 탭 줄도 같은 자리
      await tester.tap(findTextContaining('완료'));
      await tester.pumpAndSettle();
      inside(find.byKey(const ValueKey('dutch-2')), '완료 줄');
    });
  }
}
