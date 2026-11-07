// B5-1 — 화면의 loading 분기가 PLoadingRegion 시간표(0~1초 틀만 · 1초 스켈레톤 · 5초 오래 걸림)를 따르고,
// 앱 맨 위 PLoadingAnnouncer 가 "불러오는 중…" · "평소보다 오래 걸리고 있어요." 를 보조 기술에 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/plain_text.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

Widget _app(Widget body) => MaterialApp(
  theme: GrooTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // 안드로이드처럼 알림을 받지 않는 플랫폼 — 라이브 영역으로 읽힌다(알림을 받는 플랫폼은 sendAnnouncement 로 같은 글)
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(supportsAnnounce: false),
    child: child!,
  ),
  home: PLoadingAnnouncer(child: Scaffold(body: body)),
);

/// 의미 트리에서 liveRegion 노드의 글 모음.
List<String> _liveLabels(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.flagsCollection.isLiveRegion && d.label.isNotEmpty) out.add(d.label);
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

bool _skeletonVisible(WidgetTester tester) => tester
    .widget<Visibility>(
      find.ancestor(
        of: find.byType(PSkeleton).first,
        matching: find.byType(Visibility),
      ),
    )
    .visible;

void main() {
  const frame = Text('틀');

  for (final main in [false, true]) {
    testWidgets('시간표 — ${main ? '주요 화면(글 있음)' : '그 밖 화면(알림만)'}', (
      tester,
    ) async {
      final h = tester.ensureSemantics();
      final skeleton = const PSkeleton(height: 40);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              frame,
              main ? loadingRegionWithText(skeleton) : loadingRegion(skeleton),
            ],
          ),
        ),
      );
      // 0 ~ 1초 — 틀만
      expect(findText('틀'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      expect(_skeletonVisible(tester), isFalse);
      expect(_liveLabels(tester), isEmpty);
      // 1초 — 스켈레톤 + "불러오는 중…"
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(_skeletonVisible(tester), isTrue);
      expect(_liveLabels(tester).join(), contains('불러오는 중…'));
      expect(findPlain('평소보다 오래 걸리고 있어요.'), findsNothing);
      // 5초 — 알림은 둘 다, 화면 글은 주요 화면만
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(_liveLabels(tester).join(), contains('평소보다 오래 걸리고 있어요.'));
      expect(
        findPlain('평소보다 오래 걸리고 있어요.'),
        main ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      // 영역이 사라지면 알림도 거둔다
      await tester.pumpWidget(_app(const Column(children: [frame])));
      await tester.pump();
      await tester.pump();
      expect(_liveLabels(tester), isEmpty);
      h.dispose();
    });
  }

  testWidgets('1초 안에 오면 스켈레톤이 한 번도 보이지 않는다', (tester) async {
    await tester.pumpWidget(
      _app(Column(children: [loadingRegion(const PSkeleton(height: 40))])),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(_skeletonVisible(tester), isFalse);
    await tester.pumpWidget(_app(const Column(children: [Text('내용')])));
    await tester.pump(const Duration(seconds: 2));
    expect(findText('내용'), findsOneWidget);
    expect(find.byType(PSkeleton), findsNothing);
  });

  testWidgets('같은 기다림의 영역이 여럿이어도 알림 글은 한 번이다', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            loadingRegion(const PSkeleton(height: 20)),
            loadingRegion(const PSkeleton(height: 20)),
            loadingRegion(const PSkeleton(height: 20)),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    expect(_liveLabels(tester), ['불러오는 중…']);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(_liveLabels(tester), ['평소보다 오래 걸리고 있어요.']);
    h.dispose();
  });
}
