// 증권사 연결 실패 — 키 입력 폼 위 Callout 한 문장(4xx = 인증정보 틀림 · 그 밖 = 연결 실패), 값 남김, silent, 서버 글 없음.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/broker_connect_card.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';

import '../../support/plain_text.dart';

const _conn = BrokerConnection(
  broker: 'NAMU',
  displayName: '나무증권',
  issueUrl: 'https://example.test/issue',
  keyLabel: 'App Key',
  secretLabel: 'App Secret',
  connected: false,
  verified: false,
  primary: false,
);

class _Repo extends SubscriptionRepository {
  _Repo(this.status) : super(Dio());
  final int status;
  final silent = <bool>[];

  @override
  Future<void> registerBrokerCredential(
    String broker,
    String apiKey,
    String apiSecret, {
    bool silent = false,
  }) async {
    this.silent.add(silent);
    throw ApiException(code: 'X', message: '서버 원문', statusCode: status);
  }
}

Future<_Repo> _run(WidgetTester tester, int status) async {
  final repo = _Repo(status);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: BrokerConnectCard(
              connection: _conn,
              showPrimaryAction: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.enterText(find.byType(TextField).at(0), 'KEY123');
  await tester.enterText(find.byType(TextField).at(1), 'SECRET456');
  await tester.tap(find.text('연결하기'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('4xx — 인증정보가 올바르지 않아요. Callout · silent · 서버 글 없음', (
    tester,
  ) async {
    final repo = await _run(tester, 400);
    expect(repo.silent, [true]);
    expect(find.byType(FormErrorCallout), findsOneWidget);
    expect(findPlain('인증정보가 올바르지 않아요.'), findsOneWidget);
    expect(find.textContaining('서버 원문'), findsNothing);
  });

  testWidgets('5xx — 증권사를 연결하지 못했어요. Callout · 값 유지', (tester) async {
    await _run(tester, 500);
    expect(findPlain(l.subBrokerConnectFailed), findsOneWidget);
    expect(l.subBrokerConnectFailed, '증권사를 연결하지 못했어요.');
    expect(find.byType(FormErrorCallout), findsOneWidget);
  });
}
