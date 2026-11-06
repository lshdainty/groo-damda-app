// 증권 가드 — 기능권한 조회가 실패하면 "권한 없음" 으로 읽어 홈으로 보내지 않고 그 자리에서 다시 시도를 준다(I-28-5-8).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/securities_gate.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

Future<void> _open(
  WidgetTester tester,
  FutureOr<MyFeatures> Function() load,
) async {
  await tester.pumpWidget(
    ProviderScope(
      // 기본 재시도를 끈다 — 실패가 곧바로 에러 상태로 남는다.
      retry: (_, _) => null,
      overrides: [myFeaturesLoadProvider.overrideWith((ref) async => load())],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const SecuritiesGate(child: Text('증권 본문')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('조회 실패 — 실패 문구 + 다시 시도, 홈으로 보내지 않고 본문도 안 연다', (tester) async {
    await _open(tester, () => throw Exception('boom'));

    expect(findText('증권 정보를 불러오지 못했어요'), findsOneWidget);
    expect(findText('다시 시도'), findsOneWidget);
    expect(findText('증권 본문'), findsNothing);
  });

  testWidgets('다시 시도가 성공하면 본문을 연다', (tester) async {
    var calls = 0;
    await _open(tester, () {
      calls++;
      if (calls == 1) throw Exception('boom');
      return const MyFeatures(
        features: ['SECURITIES'],
        connectedBrokers: ['TOSS'],
        primaryBroker: 'TOSS',
      );
    });
    await tester.tap(findText('다시 시도'));
    await tester.pumpAndSettle();

    expect(findText('증권 정보를 불러오지 못했어요'), findsNothing);
    expect(findText('증권 본문'), findsOneWidget);
  });
}
