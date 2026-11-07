// 관심 종목 묶음 머리 높이 — 오른쪽 ⋮ 는 스펙(list-header.yaml:34)대로 ghost small iconOnly(36)라서 머리가
// 위 여백 + 20 + 아래 8 = 36(첫 묶음, 윗여백 8) / 44(다음 묶음, 윗여백 16)다(검수 M1 — medium 40 이면 40 / 48).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';

void main() {
  for (final (first, want) in [(true, 36.0), (false, 44.0)]) {
    testWidgets('머리 높이 ${first ? "첫 묶음" : "다음 묶음"} = $want', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: WatchGroupBlock(
                  group: const StockWatchGroup(
                    rowId: 1,
                    groupName: '관심',
                    sortOrder: 0,
                    items: [],
                  ),
                  first: first,
                  onShown: () {},
                  onHidden: () {},
                  lineBuilder: (_) => const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(PListHeader)).height, want);
    });
  }
}
