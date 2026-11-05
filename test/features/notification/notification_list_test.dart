// 알림 목록(I-15 41 ~ 44) — 바닥 고정 띠가 없고, 상단 바 ⚙ "알림 설정" 으로 간다.
// 목록 머리 "읽지 않은 알림 N개" 의 N 은 서버가 센 수(쉼표 포함)이고, 날짜 묶음 머리가 선다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

List<AppNotification> _items(int n) => [
  for (int i = 0; i < n; i++)
    AppNotification(
      rowId: i + 1,
      title: '알림 ${i + 1}',
      message: '내용 ${i + 1}',
      isRead: i > 2,
      createAt: '2026-09-14T00:00:00',
      notificationType: 'BUDGET',
    ),
];

Future<void> _pump(WidgetTester tester, List<AppNotification> items) async {
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
        notificationListProvider.overrideWith((ref) async => items),
        unreadCountProvider.overrideWith((ref) async => 1234),
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
    await _pump(tester, _items(3));
    expect(find.byIcon(LucideIcons.settings), findsOneWidget);
    expect(
      find.text('알림 설정'),
      findsNothing,
      reason: '글 띠는 걷었다 — 이름은 아이콘 버튼의 읽는 이름',
    );
  });

  testWidgets('머리 줄은 서버 수를 쉼표로 쓰고 "모두 읽음" 이 있다', (tester) async {
    await _pump(tester, _items(3));
    expect(find.text('읽지 않은 알림 1,234개'), findsOneWidget);
    expect(find.text('모두 읽음'), findsOneWidget);
  });

  testWidgets('날짜 묶음 머리가 선다', (tester) async {
    await _pump(tester, _items(3));
    expect(find.textContaining('9월 14일'), findsWidgets);
  });

  testWidgets('알림이 없으면 "아직 알림이 없어요"', (tester) async {
    await _pump(tester, const []);
    expect(find.text('아직 알림이 없어요'), findsOneWidget);
  });
}
