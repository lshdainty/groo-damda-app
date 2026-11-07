// 증권사 연동 — 결정 B(I-wrap-b1 β). 첫 단계는 줄 목록, 다음 단계는 별도 라우트 `/settings/securities/:broker`.
//
// 나가기(I-wrap-b2b 5): 키 · 시크릿에 친 값이 있으면 안드로이드 뒤로 · 예측형 뒤로 · ← 모두 "작성한 내용이 사라져요" 를 묻는다.
// 연결 요청이 나가 있는 동안(busy)은 묻지 않고 막는다. PopScope 는 단계 화면(branch)에 있고 목록 화면에는 없다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/broker_connect_screen.dart';
import 'package:groo_damda_app/features/subscription/presentation/securities_link_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';

import '../../support/plain_text.dart';

const _toss = BrokerConnection(
  broker: 'TOSS',
  displayName: '토스증권',
  issueUrl: '',
  keyLabel: 'Client ID',
  secretLabel: 'Client Secret',
  connected: true,
  verified: true,
  primary: true,
  verifiedAt: '2026-11-05T03:00:00Z',
);
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
const _namuOn = BrokerConnection(
  broker: 'NAMU',
  displayName: '나무증권',
  issueUrl: '',
  keyLabel: 'App Key',
  secretLabel: 'App Secret',
  connected: true,
  verified: true,
  primary: false,
  verifiedAt: '2026-11-06T03:00:00Z',
);

const _tossOff = BrokerConnection(
  broker: 'TOSS',
  displayName: '토스증권',
  issueUrl: '',
  keyLabel: 'Client ID',
  secretLabel: 'Client Secret',
  connected: false,
  verified: false,
  primary: false,
);

class _Repo extends SubscriptionRepository {
  _Repo() : super(Dio());
  final gate = Completer<void>();
  final disconnected = <String>[];
  final primaries = <String>[];

  @override
  Future<void> registerBrokerCredential(
    String broker,
    String apiKey,
    String apiSecret, {
    bool silent = false,
  }) => gate.future;

  @override
  Future<void> disconnectBrokerCredential(
    String broker, {
    bool silent = false,
  }) async => disconnected.add(broker);

  @override
  Future<void> setPrimaryBroker(String broker, {bool silent = false}) async =>
      primaries.add(broker);
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  _Repo? repo,
  List<BrokerConnection> connections = const [_toss, _namu],
  String open = '/settings/securities',
}) async {
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
            routes: [
              GoRoute(
                path: ':broker',
                builder: (_, s) =>
                    BrokerConnectScreen(broker: s.pathParameters['broker']!),
              ),
            ],
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
        brokerConnectionsProvider.overrideWith((ref) async => connections),
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
  // 사용자가 가는 길 그대로 — 목록을 거쳐 증권사 줄로
  router.push('/settings/securities');
  await tester.pumpAndSettle();
  if (open != '/settings/securities') {
    router.push(open);
    await tester.pumpAndSettle();
  }
  return router;
}

Finder get _list => find.byType(SecuritiesLinkScreen);
Finder get _detail => find.byType(BrokerConnectScreen);
Finder get _dialog => find.byType(PAlertDialogView);

/// 단계 화면의 PopScope — 셸 · 라우터가 두는 것은 빼고 이 화면 아래 것만.
Finder _popScopeIn(Finder screen) => find.descendant(
  of: screen,
  matching: find.byWidgetPredicate((w) => w is PopScope),
);

Future<void> _enterKeys(WidgetTester tester, [String key = 'abc']) async {
  await tester.enterText(find.byType(TextField).at(0), key);
  await tester.pumpAndSettle();
}

void main() {
  group('첫 단계 — 증권사 줄 목록', () {
    testWidgets('줄마다 이름 · 상태 글을 보이고, 기본은 이름 옆 배지 하나', (tester) async {
      await _pump(tester);
      expect(findText('토스증권'), findsOneWidget);
      expect(findText('나무증권'), findsOneWidget);
      expect(findText('연결됨 · 11월 5일 확인'), findsOneWidget);
      expect(findText('연결 안 됨'), findsOneWidget);
      expect(findText('기본'), findsOneWidget);
    });

    testWidgets('PopScope 가 없다 — 입력이 없는 화면이 뒤로를 가로채지 않는다', (tester) async {
      await _pump(tester);
      expect(_popScopeIn(_list), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_list, findsNothing);
      expect(findText('설정 목록'), findsOneWidget);
    });

    testWidgets('줄을 누르면 별도 라우트로 간다 — 뒤로 가면 목록', (tester) async {
      final router = await _pump(tester);
      await tester.tap(findText('나무증권'));
      await tester.pumpAndSettle();
      expect(_detail, findsOneWidget);
      expect(
        router.state.uri.path,
        '/settings/securities/NAMU',
        reason: '같은 화면 안 교체가 아니라 주소가 바뀐다',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_detail, findsNothing);
      expect(_list, findsOneWidget);
    });
  });

  group('둘째 단계 — 미연결 입력', () {
    testWidgets('친 값이 없으면 뒤로 가기는 묻지 않고 나간다', (tester) async {
      await _pump(tester, open: '/settings/securities/NAMU');
      expect(_detail, findsOneWidget);
      expect(
        tester.widget<PopScope>(_popScopeIn(_detail).first).canPop,
        isTrue,
        reason: '예측형 뒤로가기가 그대로 먹는다',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);
      expect(_detail, findsNothing);
      expect(_list, findsOneWidget, reason: '단계는 라우트라 첫 단계(목록)로 돌아온다');
    });

    testWidgets('키를 치면 안드로이드 뒤로 · ← 모두 확인창 — [취소] 는 남고 [나가기] 는 목록으로', (
      tester,
    ) async {
      await _pump(tester, open: '/settings/securities/NAMU');
      await _enterKeys(tester);
      expect(tester.widget<PopScope>(_popScopeIn(_detail).first).canPop, false);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
      expect(findText('저장하지 않고 나가기'), findsOneWidget);
      expect(findText('작성한 내용이 사라져요.'), findsOneWidget);
      await tester.tap(findText('취소'));
      await tester.pumpAndSettle();
      expect(_detail, findsOneWidget);
      expect(find.text('abc'), findsWidgets, reason: '친 값은 그대로');

      await tester.tap(find.bySemanticsLabel('뒤로'));
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget, reason: '← 도 같은 PopScope 를 지난다');
      await tester.tap(findText('나가기').last);
      await tester.pumpAndSettle();
      expect(_detail, findsNothing);
      expect(_list, findsOneWidget);
    });

    testWidgets('연결 요청이 나가 있는 동안은 canPop=false — 묻지 않고 막는다', (tester) async {
      final repo = _Repo();
      await _pump(tester, repo: repo, open: '/settings/securities/NAMU');
      await tester.enterText(find.byType(TextField).at(0), 'abc');
      await tester.enterText(find.byType(TextField).at(1), 'def');
      await tester.pumpAndSettle();
      await tester.tap(findText('연결하기'));
      await tester.pump();
      expect(tester.widget<PopScope>(_popScopeIn(_detail).first).canPop, false);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_dialog, findsNothing);
      expect(_detail, findsOneWidget);
      repo.gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('눈 Toggle 은 칸마다 이름이 있고 누르면 그 칸만 벗겨진다', (tester) async {
      await _pump(tester, open: '/settings/securities/NAMU');
      final eye = find.bySemanticsLabel('App Key 보기');
      expect(eye, findsOneWidget);
      expect(find.bySemanticsLabel('App Secret 보기'), findsOneWidget);
      bool obscured(int i) => tester
          .widgetList<EditableText>(find.byType(EditableText))
          .elementAt(i)
          .obscureText;
      expect(obscured(0), isTrue);
      await tester.tap(eye);
      await tester.pump();
      expect(obscured(0), isFalse);
      expect(obscured(1), isTrue);

      // 칸 안 오른쪽 끝 — 보이는 원 40 밖이라도 누르는 영역 44 안(위아래 2)이면 눌린다
      final center = tester.getCenter(eye);
      final box = tester.getRect(find.byType(TextField).first);
      expect(center.dx, greaterThan(box.center.dx), reason: '칸 안 오른쪽');
      await tester.tapAt(center + const Offset(0, 21));
      await tester.pump();
      expect(obscured(0), isTrue, reason: '44 영역 가장자리(원 밖 1px)도 누른다');
    });
  });

  group('눈 Toggle 바탕', () {
    testWidgets('눈 Toggle 은 켜도 꺼도 칸 안에 바탕 상자를 칠하지 않는다 — 켬은 아이콘으로만', (
      tester,
    ) async {
      await _pump(tester, open: '/settings/securities/NAMU');
      Color? fill() {
        final box = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('toggle-box')).first,
        );
        return (box.decoration as BoxDecoration).color;
      }

      expect(fill(), const Color(0x00000000), reason: '끔');
      await tester.tap(find.bySemanticsLabel('App Key 보기'));
      await tester.pumpAndSettle();
      expect(fill(), const Color(0x00000000), reason: '켬(손을 뗀 뒤)');
      final icon = tester.widget<Icon>(
        find.byKey(const ValueKey('toggle-icon')).first,
      );
      expect(icon.icon, LucideIcons.eyeOff500, reason: '켬 상태는 아이콘이 말한다');
    });
  });

  group('둘째 단계 — 연결됨', () {
    testWidgets('[연결 해제] 는 확인창 한 번 — 취소하면 보내지 않고, 확인하면 해제한다', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        repo: repo,
        connections: const [_toss, _namuOn],
        open: '/settings/securities/NAMU',
      );
      await tester.tap(findText('연결 해제'));
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
      expect(findText('나무증권 연결을 해제할까요?'), findsOneWidget);
      await tester.tap(findText('취소'));
      await tester.pumpAndSettle();
      expect(repo.disconnected, isEmpty);

      await tester.tap(findText('연결 해제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('연결 해제').last);
      await tester.pumpAndSettle();
      expect(repo.disconnected, ['NAMU']);
      expect(_detail, findsNothing, reason: '해제되면 첫 단계로 돌아간다');
      expect(_list, findsOneWidget);
    });

    testWidgets('[기본으로 쓰기] 는 연결이 둘 이상이고 기본이 아닐 때만', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        repo: repo,
        connections: const [_toss, _namuOn],
        open: '/settings/securities/NAMU',
      );
      await tester.tap(findText('기본으로 쓰기'));
      await tester.pumpAndSettle();
      expect(repo.primaries, ['NAMU']);
    });

    testWidgets('이미 기본이면 버튼 없이 이름 옆 배지 — [연결 해제] 만 왼쪽', (tester) async {
      await _pump(tester, open: '/settings/securities/TOSS');
      expect(findText('기본으로 쓰기'), findsNothing);
      expect(findText('기본'), findsOneWidget);
      expect(findText('연결 해제'), findsOneWidget);
      expect(findText('연결됨 · 11월 5일 확인'), findsOneWidget);
    });

    testWidgets('연결이 하나뿐이면 [기본으로 쓰기] 를 감춘다', (tester) async {
      await _pump(
        tester,
        connections: const [_namuOn, _tossOff],
        open: '/settings/securities/NAMU',
      );
      expect(findText('기본으로 쓰기'), findsNothing);
    });
  });
}
