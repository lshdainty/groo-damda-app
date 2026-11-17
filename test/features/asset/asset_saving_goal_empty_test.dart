// 자산 탭 저축 목표 구역 — 비어 있으면 Result Section empty(medium) 제목 + [목표 추가], 누르면 저축 목표 추가 시트.
// 예전 안내 "설정에서 저축 목표를 추가해보세요." 는 설정에 그런 메뉴가 없어 틀린 길이었다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_parts.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import '../../support/plain_text.dart';

Future<void> _pump(
  WidgetTester tester, {
  List<SavingGoal> goals = const [],
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [savingGoalListProvider.overrideWith((ref) async => goals)],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AssetSavingGoalsSection(
              goals: goals,
              masked: false,
              loading: false,
              failed: false,
              onRetry: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('비어 있으면 제목 "아직 저축 목표가 없어요" · 설명 + [목표 추가] — 설정 안내는 없다', (
    tester,
  ) async {
    await _pump(tester);

    final section = tester.widget<PResultSection>(find.byType(PResultSection));
    expect(section.kind, PResultKind.empty);
    expect(section.size, PResultSize.medium);
    expect(section.placement, PResultPlacement.card);
    expect(findText('아직 저축 목표가 없어요'), findsOneWidget);
    expect(findText('목표를 만들면 모은 금액과 남은 기간을 여기서 볼 수 있어요.'), findsOneWidget);
    expect(findTextContaining('설정에서'), findsNothing);
    expect(
      find.ancestor(
        of: findText(l.savingGoalAddAction),
        matching: find.byType(PButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('[목표 추가] 를 누르면 저축 목표 추가 시트가 열린다', (tester) async {
    await _pump(tester);
    expect(findText(l.savingGoalAdd), findsNothing);

    await tester.tap(
      find.ancestor(
        of: findText(l.savingGoalAddAction),
        matching: find.byType(PButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(findText(l.savingGoalAdd), findsOneWidget);
    expect(findText(l.savingGoalNameLabel), findsOneWidget);
  });

  testWidgets('목표가 있으면 빈 결과를 그리지 않는다', (tester) async {
    await _pump(
      tester,
      goals: const [SavingGoal(rowId: 1, title: '비상금', targetAmount: 1000000)],
    );
    expect(find.byType(PResultSection), findsNothing);
    expect(findText('비상금'), findsOneWidget);
  });
}
