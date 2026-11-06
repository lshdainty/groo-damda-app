// 증권 연결 화면 나가기 확인(I-wrap-b2b 5) — 키 · 시크릿 칸에 친 값이 있으면 안드로이드 뒤로 · 예측형 뒤로 · 앱바 ← 모두
// 금액 가리기와 같은 확인창을 거친다. 친 값이 없으면 묻지 않는다. 연결 요청이 나가 있는 동안은 묻지 않고 막는다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/securities_link_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/widgets/p_back_button.dart';

import '../../support/plain_text.dart';

const _namu = BrokerConnection(
  broker: 'NAMU',
  displayName: '나무증권',
  issueUrl: '',
  keyLabel: 'App Key',
  secretLabel: 'App Secret',
  connected: false,
  verified: false,
  primary: false,
);

class _Repo extends SubscriptionRepository {
  _Repo() : super(Dio());
  final gate = Completer<void>();

  @override
  Future<void> registerBrokerCredential(
    String broker,
    String apiKey,
    String apiSecret, {
    bool silent = false,
  }) => gate.future;
}

Future<GoRouter> _pump(WidgetTester tester, {_Repo? repo}) async {
  tester.view.physicalSize = const Size(390 * 2, 1400 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('설정 목록')),
        routes: [
          GoRoute(
            path: 'securities',
            builder: (_, _) => const SecuritiesLinkScreen(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        brokerConnectionsProvider.overrideWith((ref) async => const [_namu]),
        subscriptionRepositoryProvider.overrideWith(
          (ref) async => repo ?? _Repo(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  router.push('/settings/securities');
  await tester.pumpAndSettle();
  return router;
}

Finder get _screen => find.byType(SecuritiesLinkScreen);
Finder get _dialog => find.byType(PAlertDialogView);

void main() {
  testWidgets('친 값이 없으면 뒤로 가기는 묻지 않고 나간다', (tester) async {
    await _pump(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_dialog, findsNothing);
    expect(_screen, findsNothing);
  });

  testWidgets('키를 치면 안드로이드 뒤로 · 앱바 ← 모두 확인창 — [취소] 는 남고 [나가기] 는 나간다', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_dialog, findsOneWidget);
    expect(findText('저장하지 않고 나가기'), findsOneWidget);
    expect(findText('입력한 내용이 사라져요.'), findsOneWidget);
    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();
    expect(_screen, findsOneWidget);
    expect(findText('abc'), findsWidgets, reason: '친 값은 그대로');

    await tester.tap(find.byType(PBackButton));
    await tester.pumpAndSettle();
    expect(_dialog, findsOneWidget, reason: '앱바 ← 도 같은 PopScope 를 지난다');
    await tester.tap(findText('나가기').last);
    await tester.pumpAndSettle();
    expect(_screen, findsNothing);
    expect(findText('설정 목록'), findsOneWidget);
  });

  testWidgets('연결 요청이 나가 있는 동안은 묻지 않고 막는다', (tester) async {
    final repo = _Repo();
    await _pump(tester, repo: repo);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'abc');
    await tester.enterText(fields.at(1), 'def');
    await tester.pumpAndSettle();
    await tester.tap(findText('연결하기'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_dialog, findsNothing);
    expect(_screen, findsOneWidget);
    repo.gate.complete();
    await tester.pumpAndSettle();
  });
}
