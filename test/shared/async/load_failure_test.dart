// 불러오기 실패 판정(AsyncLoadFailure) · 계좌 고르기 본문(AssetPickGate) — 실패 · 받는 중 · 다시 받는 중 · 받음을 가른다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/pickers/asset_pick_gate.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

import '../../support/plain_text.dart';

const _bank = Asset(
  rowId: 1,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000,
  isIncludedInTotal: 'Y',
);

void main() {
  group('AsyncLoadFailure', () {
    final err = AsyncError<int>(Exception('x'), StackTrace.empty);

    test('처음 받는 중은 실패가 아니다', () {
      const v = AsyncLoading<int>();
      expect(v.loadFailed, isFalse);
      expect(v.loadRetrying, isFalse);
    });

    test('값 없이 실패 — 실패, 다시 받는 중 아님', () {
      expect(err.loadFailed, isTrue);
      expect(err.loadRetrying, isFalse);
    });

    test('실패 뒤 다시 받는 중 — 실패 화면 그대로 · 단추 진행 원', () {
      final v = const AsyncLoading<int>().copyWithPrevious(err);
      expect(v.isLoading, isTrue);
      expect(v.loadFailed, isTrue);
      expect(v.loadRetrying, isTrue);
    });

    test('값이 있으면 다시 받기가 실패해도 실패 화면이 아니다', () {
      final v = AsyncError<int>(
        Exception('x'),
        StackTrace.empty,
      ).copyWithPrevious(const AsyncData(3));
      expect(v.hasValue, isTrue);
      expect(v.loadFailed, isFalse);
    });

    test('anyLoadRetrying — 실패한 것 중 하나가 다시 받는 중일 때만', () {
      final retrying = const AsyncLoading<int>().copyWithPrevious(err);
      expect(anyLoadRetrying([err, const AsyncLoading<int>()]), isFalse);
      expect(anyLoadRetrying([err, retrying]), isTrue);
    });
  });

  group('AssetPickGate', () {
    late List<Completer<List<Asset>>> calls;

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            assetsProvider.overrideWith((ref) {
              final c = Completer<List<Asset>>();
              calls.add(c);
              return c.future;
            }),
          ],
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: AssetPickGate(
                builder: (_, assets) => Column(
                  children: [
                    for (final a in assets) Text(a.assetName),
                    if (assets.isEmpty) const Text('EMPTY'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() => calls = []);

    testWidgets('받는 중 → Skeleton, 실패 → 고정 글 + [다시 시도], 다시 받는 동안 진행 원, 받으면 목록', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('asset-pick-skeleton')), findsOneWidget);
      expect(find.text('EMPTY'), findsNothing);

      calls.last.completeError(Exception('RAW_SERVER_TEXT'));
      await tester.pump();
      expect(find.byKey(const ValueKey('asset-pick-failure')), findsOneWidget);
      expect(findText('계좌 · 카드를 불러오지 못했어요'), findsOneWidget);
      expect(findText('잠시 뒤 다시 시도해주세요.'), findsOneWidget);
      expect(findTextContaining('RAW_SERVER_TEXT'), findsNothing);
      expect(find.text('EMPTY'), findsNothing);
      PButton retry() => tester.widget<PButton>(find.byType(PButton));
      expect(retry().loading, isFalse);

      await tester.tap(findText('다시 시도'));
      await tester.pump();
      expect(calls, hasLength(2));
      // 다시 받는 동안 — 실패 화면 그대로 · 단추가 진행 원
      expect(find.byKey(const ValueKey('asset-pick-failure')), findsOneWidget);
      expect(retry().loading, isTrue);

      calls.last.complete(const [_bank]);
      await tester.pump();
      expect(find.byKey(const ValueKey('asset-pick-failure')), findsNothing);
      expect(find.text('주거래 통장'), findsOneWidget);
    });

    testWidgets('빈 목록은 실패가 아니다 — builder 가 빈 목록을 받는다', (tester) async {
      await pump(tester);
      calls.last.complete(const []);
      await tester.pump();
      expect(find.text('EMPTY'), findsOneWidget);
      expect(find.byKey(const ValueKey('asset-pick-failure')), findsNothing);
    });
  });
}
