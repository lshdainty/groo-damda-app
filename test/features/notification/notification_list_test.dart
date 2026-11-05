// 알림 목록(I-15 41 ~ 44) — 바닥 고정 띠가 없고, 상단 바 ⚙ "알림 설정" 으로 간다.
// 목록 머리 "읽지 않은 알림 N개" 의 N 은 서버가 센 수(쉼표 포함)이고, 날짜 묶음 머리가 선다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/now_tick.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

// 고정한 '지금' — 2026-10-23(금) 15:00. 알림 시각은 서버 UTC 꼴로 만든다(기기 시간대와 무관하게 같은 날).
final _now = DateTime(2026, 10, 23, 15);

class _FixedNow extends NowTick {
  @override
  DateTime build() => _now;
}

String _at(DateTime local) =>
    local.toUtc().toIso8601String().replaceAll('Z', '');

List<AppNotification> _items() => [
  AppNotification(
    rowId: 1,
    title: '오늘 알림',
    message: '내용 1',
    isRead: false,
    createAt: _at(DateTime(2026, 10, 23, 12)),
    notificationType: 'TODO_REMINDER',
  ),
  AppNotification(
    rowId: 2,
    title: '어제 알림',
    message: '내용 2',
    isRead: true,
    createAt: _at(DateTime(2026, 10, 22, 21)),
    notificationType: 'BUDGET_ALERT',
  ),
  AppNotification(
    rowId: 3,
    title: '지난 알림',
    message: '내용 3',
    isRead: true,
    createAt: _at(DateTime(2026, 10, 18, 14, 15)),
    notificationType: 'SYSTEM',
  ),
  AppNotification(
    rowId: 4,
    title: '지난해 알림',
    message: '내용 4',
    isRead: true,
    createAt: _at(DateTime(2025, 12, 3, 9)),
    notificationType: 'EVENT_REMINDER',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  List<AppNotification> items, {
  Future<int> Function()? count,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        nowTickProvider.overrideWith(_FixedNow.new),
        notificationListProvider.overrideWith((ref) async => items),
        unreadCountProvider.overrideWith(
          (ref) => (count ?? () async => 1234)(),
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
}

void main() {
  testWidgets('바닥 고정 "알림 설정" 띠가 없고 상단 바에 ⚙ 이 있다', (tester) async {
    await _pump(tester, _items());
    expect(find.byIcon(LucideIcons.settings), findsOneWidget);
    expect(find.text('알림 설정'), findsNothing);
  });

  testWidgets('머리 줄은 서버 수를 쉼표로 쓰고 "모두 읽음" 이 있다', (tester) async {
    await _pump(tester, _items());
    expect(find.text('읽지 않은 알림 1,234개'), findsOneWidget);
    expect(find.text('모두 읽음'), findsOneWidget);
  });

  testWidgets('수가 오기 전에는 머리 줄이 없다 — 받은 줄로 세지 않는다', (tester) async {
    final never = Completer<int>();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowTickProvider.overrideWith(_FixedNow.new),
          notificationListProvider.overrideWith((ref) async => _items()),
          unreadCountProvider.overrideWith((ref) => never.future),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const NotificationScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('읽지 않은 알림'), findsNothing);
  });

  testWidgets('수가 0 이면 머리 줄이 없다', (tester) async {
    await _pump(tester, _items(), count: () async => 0);
    expect(find.textContaining('읽지 않은 알림'), findsNothing);
  });

  testWidgets('날짜 묶음 머리 — 오늘 · 어제 · 요일 · 다른 해', (tester) async {
    await _pump(tester, _items());
    expect(find.text('10월 23일 (금) · 오늘'), findsOneWidget);
    expect(find.text('10월 22일 (목) · 어제'), findsOneWidget);
    expect(find.text('10월 18일 (일)'), findsOneWidget);
    expect(find.text('2025년 12월 3일 (수)'), findsOneWidget);
  });

  testWidgets('줄 끝 시각 — 오늘 묶음은 지난 시간, 다른 날은 시각', (tester) async {
    await _pump(tester, _items());
    expect(find.text('3시간 전'), findsOneWidget);
    expect(find.text('오후 9:00'), findsOneWidget);
    expect(find.text('오후 2:15'), findsOneWidget);
    expect(find.text('오전 9:00'), findsOneWidget);
  });

  testWidgets('줄은 ds List 줄 — 타일 40 · 안 읽은 줄에 읽는 글 "안 읽음"', (tester) async {
    await _pump(tester, _items());
    expect(
      tester.getSize(find.byKey(const ValueKey('plist-tile')).first),
      const Size(40, 40),
    );
    expect(find.bySemanticsLabel('안 읽음'), findsOneWidget);
    expect(find.byKey(const ValueKey('noti-unread-dot')), findsOneWidget);
  });

  testWidgets('알림이 없으면 "아직 알림이 없어요"', (tester) async {
    await _pump(tester, const []);
    expect(find.text('아직 알림이 없어요'), findsOneWidget);
  });
}
