// PTextButton loading — 웹 Button ghost 로딩과 같은 모양(바탕 pressed · 글자 투명 · 원 14) · 누름 삼킴 · 불러오는 중 알림.
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

Widget _app(Widget body, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? GrooTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: body)),
);

void main() {
  testWidgets('loading — 누름을 삼키고 원을 그린다', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      _app(PTextButton(label: '모두 읽음', onPressed: () => n++, loading: true)),
    );
    expect(find.byType(PProgressCircle), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('text-button-box')));
    await tester.pump();
    expect(n, 0);
  });

  testWidgets('loading 아니면 원 없음 · 누르면 호출', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      _app(PTextButton(label: '모두 읽음', onPressed: () => n++)),
    );
    expect(find.byType(PProgressCircle), findsNothing);
    await tester.tap(find.byKey(const ValueKey('text-button-box')));
    await tester.pump();
    expect(n, 1);
  });

  testWidgets('loading — 바탕 pressed · 글자 투명 · 자리 그대로', (tester) async {
    await tester.pumpWidget(
      _app(PTextButton(label: '모두 읽음', onPressed: () {})),
    );
    final idle = tester.getSize(find.byKey(const ValueKey('text-button-box')));
    await tester.pumpWidget(
      _app(PTextButton(label: '모두 읽음', onPressed: () {}, loading: true)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final box = tester.widget<Container>(
      find.byKey(const ValueKey('text-button-box')),
    );
    final ctx = tester.element(find.byKey(const ValueKey('text-button-box')));
    expect(
      (box.decoration! as BoxDecoration).color,
      ctx.colors.bgLayerDefaultPressed,
    );
    expect(tester.getSize(find.byKey(const ValueKey('text-button-box'))), idle);
    final op = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const ValueKey('text-button-label')),
        matching: find.byType(Opacity),
      ),
    );
    expect(op.opacity, 0);
    expect(tester.getSize(find.byType(PProgressCircle)), const Size(14, 14));
  });

  testWidgets('loading — 이름은 그대로 · 값 "불러오는 중" · 탭 동작 없음', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(PTextButton(label: '모두 읽음', onPressed: () {}, loading: true)),
    );
    final n = tester.getSemantics(find.bySemanticsLabel('모두 읽음'));
    expect(n.value, '불러오는 중');
    expect(n.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    h.dispose();
  });
}
