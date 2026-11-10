// PLoadingRegion.inline — 값 조각만 기다려도 상태 글에 등록된다(WCAG 4.1.3). 5초 글은 화면에 없고,
// 같은 화면의 일반 영역이 5초 글의 주인 자리를 뺏기지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

Widget _app(Widget body, {bool supportsAnnounce = false}) => MaterialApp(
  theme: GrooTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(supportsAnnounce: supportsAnnounce),
    child: child!,
  ),
  home: PLoadingAnnouncer(child: Scaffold(body: body)),
);

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

void main() {
  testWidgets('inline 만 기다려도 1초에 "불러오는 중…" 라이브 영역이 생긴다', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const PLoadingRegion.inline(fallback: PSkeleton(width: 60, height: 20)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(_liveLabels(tester), isEmpty);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(_liveLabels(tester), ['불러오는 중…']);
    // 5초 — 오래 걸림 알림, 화면 글은 없다
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(_liveLabels(tester), ['평소보다 오래 걸리고 있어요.']);
    expect(find.text('평소보다 오래 걸리고 있어요.'), findsNothing);
    h.dispose();
  });

  testWidgets('알림을 받는 플랫폼은 sendAnnouncement 로 같은 글을 보낸다', (tester) async {
    final sent = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        sent.add(message);
        return null;
      },
    );
    await tester.pumpWidget(
      _app(
        const PLoadingRegion.inline(fallback: PSkeleton(width: 60, height: 20)),
        supportsAnnounce: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1100));
    expect(sent.toString(), contains('불러오는 중…'));
  });

  testWidgets('inline 이 먼저여도 일반 영역이 5초 글의 주인이다', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            PLoadingRegion.inline(fallback: PSkeleton(width: 60, height: 20)),
            PLoadingRegion(
              pending: true,
              fallback: PSkeleton(height: 40),
              child: Text('내용'),
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5, milliseconds: 100));
    expect(find.text('평소보다 오래 걸리고 있어요.'), findsOneWidget);
  });

  testWidgets('값이 오면(inline 이 사라지면) 상태 글이 비워진다', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const PLoadingRegion.inline(fallback: PSkeleton(width: 60, height: 20)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    expect(_liveLabels(tester), isNotEmpty);
    await tester.pumpWidget(_app(const Text('값')));
    await tester.pump();
    await tester.pump();
    expect(_liveLabels(tester), isEmpty);
    h.dispose();
  });
}
