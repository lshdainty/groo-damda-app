// 저축 목표(설정 > 저축 목표) 결과 구역 — 빈 화면 · 불러오기 실패는 상단 바 아래 남은 높이의 세로 가운데에 선다
// (result-section.md "놓인 자리의 가운데" · content-placeholder.md "화면 전체는 large" · 프리셋 관리와 같다).
// 빈 화면에는 목록 제목 · "목표 추가" 글 버튼이 없고, 결과 구역의 첫 버튼 "목표 추가" 가 추가 시트를 바로 연다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import '../../support/plain_text.dart';

Future<void> _pump(
  WidgetTester tester,
  Future<List<SavingGoal>> Function() load, {
  Locale locale = const Locale('ko'),
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        hideCardProvider.overrideWith((ref, card) => false),
        savingGoalListProvider.overrideWith((ref) => load()),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const SavingGoalScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 결과 구역이 상단 바 바로 아래에서 시작한 본문 안에서 위 · 아래 여백이 같다.
void _expectCentered(WidgetTester tester) {
  final bar = tester.getRect(find.byType(PTopNavigation)).bottom;
  final area = tester.getRect(find.byType(CustomScrollView));
  expect(area.top, closeTo(bar, 1), reason: '본문은 상단 바 아래에서 시작한다');
  final r = tester.getRect(
    find.byKey(const ValueKey('result-section-content')),
  );
  final above = r.top - area.top;
  final below = area.bottom - r.bottom;
  expect(above, greaterThan(100), reason: '상단 바 바로 아래에 붙어 서지 않는다');
  expect(above, closeTo(below, 1));
}

void main() {
  testWidgets('목표 0개 — 목록 제목 · 글 버튼 없이 큰 빈 결과(돼지 저금통) · 남은 자리 세로 가운데', (
    tester,
  ) async {
    await _pump(tester, () async => const <SavingGoal>[]);
    final section = tester.widget<PResultSection>(find.byType(PResultSection));
    expect(section.kind, PResultKind.empty);
    expect(section.size, PResultSize.large);
    expect(section.icon, LucideIcons.piggyBank);
    expect(findText('아직 저축 목표가 없어요'), findsOneWidget);
    expect(findText('목표를 만들면 모은 금액과 남은 기간을 여기서 볼 수 있어요.'), findsOneWidget);
    expect(find.byType(PListHeader), findsNothing);
    expect(findText('목표 목록 · 0개'), findsNothing);
    // "목표 추가" 는 결과 구역의 첫 버튼 하나뿐이다
    expect(findText('목표 추가'), findsOneWidget);
    _expectCentered(tester);
  });

  testWidgets('목표 0개 — en 글', (tester) async {
    await _pump(
      tester,
      () async => const <SavingGoal>[],
      locale: const Locale('en'),
    );
    expect(findText('No savings goals yet'), findsOneWidget);
    expect(
      findText(
        "Create a goal to track how much you've saved and how long is left.",
      ),
      findsOneWidget,
    );
    expect(findText('Add goal'), findsOneWidget);
  });

  testWidgets('목표 0개 — 첫 버튼 "목표 추가" 가 추가 시트를 바로 연다', (tester) async {
    await _pump(tester, () async => const <SavingGoal>[]);
    await tester.tap(findText('목표 추가'));
    await tester.pumpAndSettle();
    expect(findText('저축 목표 추가'), findsOneWidget);
  });

  testWidgets('불러오기 실패 — 큰 실패 결과 · 남은 자리 세로 가운데 · 오류 원문 0', (tester) async {
    await _pump(tester, () async => throw Exception('SECRET-RAW-ERROR'));
    final section = tester.widget<PResultSection>(find.byType(PResultSection));
    expect(section.kind, PResultKind.failure);
    expect(section.size, PResultSize.large);
    expect(findText('저축 목표를 불러오지 못했어요'), findsOneWidget);
    expect(findText('다시 시도'), findsOneWidget);
    expect(findTextContaining('SECRET-RAW-ERROR'), findsNothing);
    _expectCentered(tester);
  });

  testWidgets('목표 0개 — 가운데 결과 구역에서도 당겨서 새로 고침이 된다', (tester) async {
    var calls = 0;
    await _pump(tester, () async {
      calls++;
      return const <SavingGoal>[];
    });
    expect(calls, 1);
    await tester.fling(
      find.byKey(const ValueKey('result-section-content')),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
