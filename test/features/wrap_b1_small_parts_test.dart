// I-wrap-b1 α 앱 작은 것 — 옛 부품을 걷은 자리를 잠근다.
//
// - 누르는 자리: 가계부 주 띠 날짜 칸 · 캘린더 월 격자 칸 · 종목 찾기 입구의 raw InkWell(Material 물결) → ds PressArea
//   (누르는 동안 bg-layer-default-pressed, DESIGN.md 눌림 = 역할의 -pressed 색)
// - 가계부 주 띠 칸 금액의 길게 누르기 툴팁은 걷었다(tooltip.md Q-009-2 — 옛 길게 누르기 툴팁은 옮길 때 걷는다)
// - 자산 상세 불러오는 중: 옛 맥박 PSkeleton(shared/widgets) → ds 반짝임 Skeleton, 글 자리 높이 = 그 글의 줄 높이
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart' as ds;
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart' as old;

Widget _app(Widget child, {List<dynamic> overrides = const []}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: [...overrides.cast()],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(body: child),
      ),
    );

/// 누르는 동안 [area] 안에 [color] 를 칠한 상자가 있는지.
bool _paints(WidgetTester tester, Finder area, Color color) {
  for (final w in tester.widgetList(
    find.descendant(of: area, matching: find.byWidgetPredicate((_) => true)),
  )) {
    if (w is ColoredBox && w.color == color) return true;
    if (w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == color) {
      return true;
    }
    if (w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == color) {
      return true;
    }
  }
  return false;
}

void main() {
  group('가계부 주 띠 날짜 칸', () {
    Future<void> pump(WidgetTester tester, {ValueChanged<String>? onSelect}) =>
        tester.pumpWidget(
          _app(
            LedgerCalendar(
              month: DateTime(2026, 11),
              selected: '2026-11-05',
              expanded: false,
              byDay: const {
                '2026-11-03': (out: 123456789, inn: 0),
                '2026-11-05': (out: 4500, inn: 30000),
              },
              flags: const MaskFlags.cardOnly(false),
              onSelect: onSelect ?? (_) {},
              onToggleExpand: () {},
            ),
          ),
        );

    testWidgets('Material 물결(InkWell)이 없고 누르는 동안 bg-layer-default-pressed', (
      tester,
    ) async {
      String? picked;
      await pump(tester, onSelect: (d) => picked = d);
      final grid = find.byType(LedgerCalendarGrid);
      expect(
        find.descendant(of: grid, matching: find.byType(InkWell)),
        findsNothing,
      );
      final c = tester.element(grid).colors;
      final day = find.descendant(of: grid, matching: find.text('3'));
      final g = await tester.startGesture(tester.getCenter(day));
      await tester.pump();
      expect(_paints(tester, grid, c.bgLayerDefaultPressed), isTrue);
      await g.up();
      await tester.pump();
      expect(picked, '2026-11-03');
      expect(_paints(tester, grid, c.bgLayerDefaultPressed), isFalse);
    });

    testWidgets('칸 금액을 길게 눌러도 툴팁이 뜨지 않는다 — 옛 길게 누르기 툴팁은 걷었다', (tester) async {
      await pump(tester);
      expect(find.byType(Tooltip), findsNothing);
      // 칸에 안 들어가는 금액은 이제 말줄임 대신 점이다(B3-나 2A) — 그 점을 길게 눌러도 툴팁은 없다
      final amount = find.byKey(const ValueKey('ledger-cell-dot')).first;
      await tester.longPress(amount);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Tooltip), findsNothing);
      expect(find.textContaining('123,456,789원'), findsNothing);
    });
  });

  testWidgets(
    '캘린더 월 격자 칸 — InkWell 없이 누르는 동안 bg-layer-default-pressed, 누르면 그날',
    (tester) async {
      DateTime? tapped;
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: CalendarMonthGrid(
              month: DateTime(2026, 11),
              events: const [],
              holidays: const {},
              onDayTap: (d) => tapped = d,
            ),
          ),
        ),
      );
      final grid = find.byType(CalendarMonthGrid);
      expect(
        find.descendant(of: grid, matching: find.byType(InkWell)),
        findsNothing,
      );
      final c = tester.element(grid).colors;
      final cell = find
          .ancestor(
            of: find.descendant(of: grid, matching: find.text('12')).first,
            matching: find.byKey(const ValueKey('calendar-day-cell')),
          )
          .first;
      final g = await tester.startGesture(tester.getCenter(cell));
      await tester.pump();
      expect(_paints(tester, cell, c.bgLayerDefaultPressed), isTrue);
      await g.up();
      await tester.pump();
      expect(tapped, DateTime(2026, 11, 12));
    },
  );

  testWidgets(
    '종목 찾기 입구 — InkWell 없이 누르는 동안 bg-layer-default-pressed · 이름 있는 버튼',
    (tester) async {
      var opened = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(StocksSearchEntry(onTap: () => opened++)));
      final entry = find.byKey(const ValueKey('stocks-search-entry'));
      expect(
        find.descendant(of: entry, matching: find.byType(InkWell)),
        findsNothing,
      );
      final c = tester.element(entry).colors;
      final g = await tester.startGesture(tester.getCenter(entry));
      await tester.pump();
      expect(_paints(tester, entry, c.bgLayerDefaultPressed), isTrue);
      await g.up();
      await tester.pump();
      expect(opened, 1);
      expect(
        tester.getSemantics(entry),
        isSemantics(label: '종목 검색', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    },
  );

  group('자산 상세 불러오는 중', () {
    const card = Asset(
      rowId: 9,
      assetName: '숲빛카드',
      assetType: 'CREDIT_CARD',
      balance: -125000,
      paymentDay: 12,
    );
    const account = Asset(
      rowId: 3,
      assetName: '숲빛은행 입출금',
      assetType: 'BANK_ACCOUNT',
      balance: 1250000,
    );

    Future<void> pump(WidgetTester tester, Asset asset) async {
      tester.view.physicalSize = const Size(390 * 3, 1100 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          AssetDetailScreen(assetId: asset.rowId),
          overrides: [
            assetsProvider.overrideWith((ref) async => [card, account]),
            hideCardProvider.overrideWith((ref, c) => false),
            cardBillingProvider.overrideWith(
              (ref, id) => Completer<Never>().future,
            ),
            cardPerformanceProvider.overrideWith(
              (ref, key) => Completer<Never>().future,
            ),
            assetBalanceTrendProvider.overrideWith(
              (ref, key) async => const [],
            ),
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
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('카드 — 옛 맥박 스켈레톤이 없고 청구 자리는 ds Skeleton, 금액 자리 높이 = t9 줄 높이', (
      tester,
    ) async {
      await pump(tester, card);
      expect(find.byType(old.PSkeleton), findsNothing);
      final billing = find.byKey(const ValueKey('card-billing-skeleton'));
      expect(billing, findsOneWidget);
      final faces = tester
          .widgetList<ds.PSkeleton>(
            find.descendant(of: billing, matching: find.byType(ds.PSkeleton)),
          )
          .toList();
      final t9 = PTypography.t9.fontSize! * PTypography.t9.height!;
      expect(faces.any((f) => f.height == t9), isTrue, reason: '금액 자리');
      // 회차 단추 자리 — 단추 높이 36 안에 글 t4 의 줄 높이
      final t4 = PTypography.t4.fontSize! * PTypography.t4.height!;
      expect(faces.any((f) => f.height == t4), isTrue, reason: '회차 단추 글');
      // 동작 버튼 자리 — Button medium 40 폭 전체
      expect(
        faces.any((f) => f.height == 40 && f.width == double.infinity),
        isTrue,
      );
    });

    testWidgets('계좌 — 최근 거래 자리가 ds Skeleton(타일 40 · 모서리 12), 옛 맥박 스켈레톤 없음', (
      tester,
    ) async {
      await pump(tester, account);
      expect(find.byType(old.PSkeleton), findsNothing);
      final tiles = tester
          .widgetList<ds.PSkeleton>(find.byType(ds.PSkeleton))
          .where((f) => f.width == 40 && f.height == 40);
      expect(tiles, isNotEmpty);
      expect(tiles.every((f) => f.radius == ds.PSkeletonRadius.r12), isTrue);
    });
  });
}
