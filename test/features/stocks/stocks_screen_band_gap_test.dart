// 증권 화면(I-13 틈 표 T1 · T2) — 증권사 Line 은 화면 전체를 조절하는 줄이라 첫 띠와 한 덩어리(틈 0)이고,
// 머리 바로 아래도 0 이다.
// 본문은 모르는 증권사 안내(띠 하나)로 그려 네트워크 없이 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_screen.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';

Future<void> _pump(WidgetTester tester, List<String> brokers) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myFeaturesLoadProvider.overrideWith(
          (ref) async => MyFeatures(
            features: const ['SECURITIES'],
            connectedBrokers: brokers,
            primaryBroker: brokers.first,
          ),
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StocksScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('연결 둘 — Line 과 본문 첫 띠 사이 0 (T2), 머리 바로 아래 Line (T1)', (
    tester,
  ) async {
    await _pump(tester, ['ZZZ', 'YYY']);
    final line = find.byType(PTabs<String>);
    expect(line, findsOneWidget);
    final body = find.byKey(const ValueKey('screen-section'));
    expect(body, findsOneWidget, reason: '본문 띠 하나(모르는 증권사 안내)');
    expect(
      tester.getRect(line).top,
      tester.getRect(find.byKey(const ValueKey('top-navigation'))).bottom,
    );
    expect(tester.getRect(body).top - tester.getRect(line).bottom, 0);
    expect(tester.getRect(line).height, 44);
  });

  testWidgets('연결 하나 — 탭이 없고 본문 띠가 머리 바로 아래(틈 0)', (tester) async {
    await _pump(tester, ['ZZZ']);
    final bands = find.byKey(const ValueKey('screen-section'));
    expect(bands, findsOneWidget);
    expect(
      tester.getRect(bands).top,
      tester.getRect(find.byKey(const ValueKey('top-navigation'))).bottom,
    );
  });
}
