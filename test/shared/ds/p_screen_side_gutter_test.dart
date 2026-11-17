import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';

/// groo-design Layout "Safe Area" — 좌우 안전 영역 칸에는 화면의 면을 칠하지 않고 뒷배경만 보인다.
/// iPhone Duo 접힘(466 × 678, 오른쪽 상태 칸 84).
void main() {
  const page = Key('page');
  const popup = Key('popup');

  Future<void> pump(
    WidgetTester tester, {
    EdgeInsets padding = const EdgeInsets.only(right: 84, top: 20),
  }) async {
    tester.view.physicalSize = const Size(466, 678);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: padding),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: SizedBox.expand(
              key: page,
              child: Builder(
                builder: (context) => Text(
                  'L${MediaQuery.paddingOf(context).left} '
                  'R${MediaQuery.paddingOf(context).right} '
                  'T${MediaQuery.paddingOf(context).top}',
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('화면은 오른쪽 상태 칸 앞에서 끊기고, 칸은 뒷배경', (tester) async {
    await pump(tester);
    final r = tester.getRect(find.byKey(page));
    expect(r.left, 0);
    expect(r.right, 466 - 84);
    final gutter = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('screen-side-gutter')),
    );
    expect(gutter.color, PColors.light.bgLayerBasement);
    expect(
      tester.getRect(find.byKey(const ValueKey('screen-side-gutter'))).width,
      466,
    );
  });

  testWidgets('안쪽은 좌우 안전 영역을 0 으로 받고, 위는 그대로', (tester) async {
    await pump(tester);
    expect(find.text('L0.0 R0.0 T20.0'), findsOneWidget);
  });

  testWidgets('좌우 안전 영역이 없으면 칸을 두지 않는다', (tester) async {
    await pump(tester, padding: const EdgeInsets.only(top: 47, bottom: 34));
    expect(find.byKey(const ValueKey('screen-side-gutter')), findsNothing);
    expect(tester.getRect(find.byKey(page)).width, 466);
  });

  testWidgets('위에 뜨는 것(PopupRoute)은 칸 밖 — 화면 폭을 그대로 쓴다', (tester) async {
    await pump(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      RawDialogRoute<void>(
        pageBuilder: (context, _, _) => SizedBox.expand(
          key: popup,
          child: Text(
            'R${MediaQuery.paddingOf(context).right}',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(popup)).width, 466);
    expect(find.text('R84.0'), findsOneWidget);
  });
}
