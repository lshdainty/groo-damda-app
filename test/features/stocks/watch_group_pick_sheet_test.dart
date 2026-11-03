// 담을 관심 그룹 고르기 — 메뉴(실행)가 아니라 고르기 시트다(웹 detail-parts.tsx 와 같다).
// 그룹이 둘 이상이고 아직 안 담았으면 시트가 열리고, 줄은 그룹 이름 + 담긴 종목 수(stocksUnitCount),
// 본문은 사용자 값 목록이라 scrollFog(Scroll Fog 위 20 · 아래 80)가 걸린다. 고른 그룹에 담긴다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stocks_repository.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';

const _item = WatchItem(
  rowId: 1,
  stockMasterRowId: 1,
  countryCode: 'KR',
  marketCode: 'KOSPI',
  symbol: '005930',
  nameKr: '삼성전자',
  securityType: 'STOCK',
  currency: 'KRW',
);

final _groups = [
  const StockWatchGroup(
    rowId: 1,
    groupName: '관심',
    sortOrder: 0,
    items: [_item, _item],
  ),
  const StockWatchGroup(rowId: 2, groupName: '배당주', sortOrder: 1, items: []),
];

class _Repo extends StocksRepository {
  _Repo() : super(Dio());
  final added = <int>[];

  @override
  Future<WatchItem> addWatchItem(
    int groupId,
    String symbol, {
    String? marketCode,
  }) async {
    added.add(groupId);
    return _item;
  }
}

Finder _plainText(String s) => find.byWidgetPredicate(
  (w) =>
      w is Text && (w.data ?? '').replaceAll('⁠', '').replaceAll('​', '') == s,
);

void main() {
  testWidgets('그룹이 둘이면 고르기 시트가 열리고 이름 · 개수 줄 + scrollFog, 고른 그룹에 담긴다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stocksRepositoryProvider.overrideWith((ref) async => repo),
          watchGroupsProvider.overrideWith((ref) async => _groups),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(watchGroupsProvider);
                return TextButton(
                  onPressed: () => toggleWatch(context, ref, '000660'),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l = lookupAppLocalizations(const Locale('ko'));
    expect(_plainText(l.stocksWatchPickGroup), findsOneWidget);
    expect(find.byType(PScrollFog), findsOneWidget);
    expect(find.byType(PListButtonItem), findsNWidgets(2));
    expect(_plainText('관심'), findsOneWidget);
    expect(_plainText(l.stocksUnitCount(2)), findsOneWidget);
    expect(_plainText(l.stocksUnitCount(0)), findsOneWidget);

    await tester.tap(find.byType(PListButtonItem).last);
    await tester.pumpAndSettle();
    expect(repo.added, [2]);
  });
}
