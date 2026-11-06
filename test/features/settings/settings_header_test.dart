// 설정 하위 화면 머리(I-16 14 · 15 · 16) — 실제 화면을 띄운 채로 잰다.
//
//  - 열하나 화면 모두 ds 상단 바 하나(높이 56) · Material AppBar 0 · ← 이름 "뒤로"
//  - 제목 글이 웹 SECTIONS 라벨과 같다(18)
//  - ← 를 누르면 pop (앞 화면이 늘 있다 — 9)
//  - 카테고리 관리: 오른쪽 글 버튼 "추가" · 탭이 머리 밖(본문 맨 위)
//  - 캘린더 관리·공유: 머리에 아이콘 버튼 없음(⊕ 걷음 — Q5-A)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_settings_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_labels_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_share_screen.dart';
import 'package:groo_damda_app/features/category/presentation/category_screen.dart';
import 'package:groo_damda_app/features/memo/presentation/memo_tag_management_screen.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_screen.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_screen.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_screen.dart';
import 'package:groo_damda_app/features/settings/presentation/devices_screen.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_tag_management_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import '../../support/plain_text.dart';

/// 화면 · 제목 글(웹 SECTIONS labelKey 와 같다 — 결과표 18).
final _screens = <(String, Widget Function(), String)>[
  ('카테고리 관리', () => const CategoryScreen(), '카테고리 관리'),
  ('예산 설정', () => const BudgetSettingsScreen(), '예산 설정'),
  ('저축 목표', () => const SavingGoalScreen(), '저축 목표'),
  ('반복 거래 관리', () => const RecurringScreen(), '반복 거래 관리'),
  ('프리셋 관리', () => const PresetScreen(), '프리셋 관리'),
  ('캘린더 관리 · 공유', () => const CalendarShareScreen(), '캘린더 관리 · 공유'),
  ('캘린더 라벨', () => const CalendarLabelsScreen(), '캘린더 라벨'),
  ('할 일 태그', () => const TodoTagManagementScreen(), '할 일 태그'),
  ('메모 태그', () => const MemoTagManagementScreen(), '메모 태그'),
  ('알림 설정', () => const NotificationSettingsScreen(), '알림 설정'),
  ('로그인된 기기', () => const DevicesScreen(), '로그인된 기기'),
];

/// 본문(각 화면 지시서 몫)의 넘침은 이 시험이 세지 않는다 — 머리(상단 바)에서 난 오류만 0 이어야 한다.
void _expectHeaderClean(WidgetTester tester) {
  final ex = tester.takeException();
  if (ex == null) return;
  expect(
    ex.toString().contains('top_navigation'),
    isFalse,
    reason: '머리에서 난 오류: $ex',
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  // 앱 안 들어오는 길은 모두 push 다 — 앞 화면이 늘 있다(I-16 9)
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(path: '/s', builder: (_, _) => screen),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  unawaited(router.push('/s'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final (name, build, title) in _screens) {
    for (final dark in [false, true]) {
      testWidgets('$name — ${dark ? "다크" : "라이트"} 상단 바 56 · AppBar 0 · ← 뒤로', (
        tester,
      ) async {
        await _pump(tester, build(), dark: dark);
        expect(find.byType(AppBar), findsNothing);
        final bar = find.byType(PTopNavigation);
        expect(bar, findsOneWidget);
        expect(tester.getSize(bar).height, 56);
        expect(
          find.descendant(of: bar, matching: findText(title)),
          findsOneWidget,
        );
        final back = find.byWidgetPredicate(
          (w) => w is PTopNavigationIconButton && w.label == '뒤로',
        );
        expect(back, findsOneWidget);
        expect(tester.getSize(back).width, 44, reason: '← 상자 44');
        // T1 — 머리 바로 아래부터 본문 면(틈 0)
        // 기기 · 할 일 태그 화면은 흰 면 하나가 되어 띠 본문이 없다 — 본문 목록이 머리 바로 아래
        // 메모 태그 · 알림 설정도 흰 면 하나가 되었다(f294089b · c6d4945a) — 알림 설정은 본문 키가 없어 Scaffold 본문으로 잰다
        final body = name == '알림 설정'
            ? find.byWidget(
                tester.widget<Scaffold>(find.byType(Scaffold).last).body!,
              )
            : find.byKey(
                ValueKey(switch (name) {
                  '로그인된 기기' => 'devices-body',
                  // 할 일 태그도 I-10 에서 흰 면 하나가 되어 띠 본문이 없다
                  '할 일 태그' => 'todo-tags-body',
                  '메모 태그' => 'memo-tags-body',
                  _ => 'screen-band-body',
                }),
              );
        expect(
          tester.getRect(body).top,
          tester.getRect(bar).bottom,
          reason: 'T1 머리 ↔ 본문 0',
        );
        _expectHeaderClean(tester);
      });
    }

    testWidgets('$name — ← 를 누르면 pop', (tester) async {
      await _pump(tester, build());
      _expectHeaderClean(tester);
      expect(find.byType(PTopNavigation), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is PTopNavigationIconButton && w.label == '뒤로',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PTopNavigation), findsNothing);
    });

    testWidgets('$name — 글자 200% 에서도 머리 56 · 넘침 0', (tester) async {
      await _pump(tester, build(), scale: 2);
      expect(tester.getSize(find.byType(PTopNavigation)).height, 56);
      _expectHeaderClean(tester);
    });
  }

  testWidgets('카테고리 관리 — 오른쪽 글 버튼 "추가" 하나 · 탭은 머리 밖', (tester) async {
    await _pump(tester, const CategoryScreen());
    final bar = find.byType(PTopNavigation);
    expect(
      find.descendant(of: bar, matching: find.byType(PTopNavigationTextButton)),
      findsOneWidget,
    );
    expect(find.descendant(of: bar, matching: findText('추가')), findsOneWidget);
    // 아이콘 버튼은 ← 하나뿐 — 글 버튼과 섞지 않는다
    expect(
      find.descendant(of: bar, matching: find.byType(PTopNavigationIconButton)),
      findsOneWidget,
    );
    final barRect = tester.getRect(bar);
    final tabs = findTextContaining('지출');
    expect(tabs, findsWidgets);
    expect(
      tester.getRect(tabs.first).top,
      greaterThanOrEqualTo(barRect.bottom),
      reason: '탭이 머리 밖(본문 맨 위)',
    );
  });

  testWidgets('캘린더 관리 · 공유 — 머리에 아이콘 버튼은 ← 하나(⊕ 걷음)', (tester) async {
    await _pump(tester, const CalendarShareScreen());
    final bar = find.byType(PTopNavigation);
    expect(
      find.descendant(of: bar, matching: find.byType(PTopNavigationIconButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.byType(PTopNavigationTextButton)),
      findsNothing,
    );
    expect(find.byTooltip('초대 코드로 참여'), findsNothing);
  });
}
