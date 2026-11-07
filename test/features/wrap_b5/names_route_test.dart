// B5-2 — PTopNavigation 제목이 화면 이름(namesRoute)으로 읽힌다.
// 제목이 없어 해당 없는 화면: login · splash · withdrawn · update_gate (PTopNavigation 을 쓰지 않는다).
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/sms/data/sms_repository.dart';
import 'package:groo_damda_app/features/sms/presentation/sms_paste_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

Widget _app(Widget home) => MaterialApp(
  theme: GrooTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// 의미 트리 어디에든 namesRoute 노드가 있고 그 이름이 [label] 인가.
bool _namesRoute(WidgetTester tester, String label) {
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  var found = false;
  void walk(SemanticsNode n) {
    // ignore: deprecated_member_use
    if (n.getSemanticsData().flagsCollection.namesRoute &&
        n.label.contains(label)) {
      found = true;
    }
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(root);
  return found;
}

void main() {
  testWidgets('standard 바 제목이 namesRoute 다', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: PTopNavigation(
            title: '알림 설정',
            leading: PTopNavigationIconButton.back(
              label: '뒤로',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    expect(_namesRoute(tester, '알림 설정'), isTrue);
    h.dispose();
  });

  testWidgets('root 바 제목도 namesRoute 다', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: PTopNavigation(type: PTopNavigationType.root, title: '홈'),
        ),
      ),
    );
    expect(_namesRoute(tester, '홈'), isTrue);
    h.dispose();
  });

  testWidgets('검색 바의 보이지 않는 머리말도 namesRoute 다', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: PTopNavigation.search(
            title: '검색',
            search: const SizedBox(height: 40),
          ),
        ),
      ),
    );
    expect(_namesRoute(tester, '검색'), isTrue);
    h.dispose();
  });

  testWidgets('대표 화면 — 문자 붙여넣기 화면이 이름을 단다', (tester) async {
    final h = tester.ensureSemantics();
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smsRepositoryProvider.overrideWith((ref) async => _NoRepo()),
        ],
        child: _app(const SmsPasteScreen()),
      ),
    );
    await tester.pump();
    final nav = tester.widget<PTopNavigation>(find.byType(PTopNavigation));
    expect(_namesRoute(tester, nav.title), isTrue);
    h.dispose();
  });
}

class _NoRepo implements SmsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
