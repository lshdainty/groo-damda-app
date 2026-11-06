// 증권 화면 — 기능권한 · 연결 조회가 실패하면 "증권사 연결 안 됨" 으로 읽지 않고 실패 + 다시 시도를 보인다(I-28-5-8).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_screen.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('조회 실패 — 실패 문구 + 다시 시도, 연결 유도 화면은 띄우지 않는다', (tester) async {
    final ko = AppLocalizationsKo();
    await tester.pumpWidget(
      ProviderScope(
        // 기본 재시도를 끈다 — 실패가 곧바로 에러 상태로 남는다.
        retry: (_, _) => null,
        overrides: [
          myFeaturesLoadProvider.overrideWith(
            (ref) async => throw Exception('boom'),
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const StocksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(findText('증권 정보를 불러오지 못했어요'), findsOneWidget);
    expect(findText('다시 시도'), findsOneWidget);
    expect(findText(ko.stocksConnectEmptyTitle), findsNothing);
  });
}
