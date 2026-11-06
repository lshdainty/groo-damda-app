// 증권사 연결 실패 — 키 입력 폼 위 Callout 한 문장(4xx = 인증정보 틀림 · 그 밖 = 연결 실패), 값 남김, silent, 서버 글 없음.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/broker_connect_screen.dart';
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
  _Repo(this.status, {this.code = 'X'}) : super(Dio());
  final int? status;
  final String code;
  final silent = <bool>[];
  var connectionReads = 0;

  @override
  Future<List<BrokerConnection>> getBrokerConnections() async {
    connectionReads++;
    return const [_conn];
  }

  @override
  Future<void> registerBrokerCredential(
    String broker,
    String apiKey,
    String apiSecret, {
    bool silent = false,
  }) async {
    this.silent.add(silent);
    throw ApiException(code: code, message: '서버 원문', statusCode: status);
  }
}

Future<_Repo> _run(
  WidgetTester tester,
  int? status, {
  String code = 'X',
}) async {
  final repo = _Repo(status, code: code);
  final container = ProviderContainer(
    overrides: [
      subscriptionRepositoryProvider.overrideWith((ref) async => repo),
    ],
  );
  addTearDown(container.dispose);
  // 연결 상태를 보는 화면이 있는 것처럼 — 무효화되면 다시 받는다
  container.listen(brokerConnectionsProvider, (_, _) {});
  await container.read(brokerConnectionsProvider.future);
  tester.view.physicalSize = const Size(390 * 2, 1400 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const BrokerConnectScreen(broker: 'NAMU'),
      ),
    ),
  );
  await tester.enterText(find.byType(TextField).at(0), 'KEY123');
  await tester.enterText(find.byType(TextField).at(1), 'SECRET456');
  await tester.pump(); // 두 칸이 차야 [연결하기] 가 켜진다
  await tester.tap(findText('연결하기'));
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
    expect(findTextContaining('서버 원문'), findsNothing);
  });

  testWidgets('5xx — 증권사를 연결하지 못했어요. Callout · 값 유지', (tester) async {
    final repo = await _run(tester, 500);
    expect(repo.connectionReads, 1, reason: '실패는 다시 받지 않는다');
    expect(findPlain(l.subBrokerConnectFailed), findsOneWidget);
    expect(l.subBrokerConnectFailed, '증권사를 연결하지 못했어요.');
    expect(find.byType(FormErrorCallout), findsOneWidget);
  });

  for (final code in [kApiNoResponseCode, kApiParseErrorCode]) {
    testWidgets(
      '응답을 못 받음($code) — 실패가 아니라 "연결됐는지 확인하지 못했어요." · 연결 상태를 다시 받는다(판단 ⑤)',
      (tester) async {
        final repo = await _run(tester, null, code: code);
        expect(findPlain('연결됐는지 확인하지 못했어요.'), findsOneWidget);
        expect(findPlain(l.subBrokerConnectFailed), findsNothing);
        expect(
          repo.connectionReads,
          2,
          reason: '처음 한 번 + 연결됐을 수 있어 서버 상태를 다시 받은 한 번',
        );
      },
    );
  }
}
