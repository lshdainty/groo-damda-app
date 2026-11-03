// revealBelowFog — 위 흐림이 켜진 스크롤 상자에서는 올린 요소가 흐림 아래(위 20)에 놓이고, 흐림이 없으면 맨 위에 붙는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';

Widget _body(GlobalKey key) => Column(
  children: [
    const SizedBox(height: 600),
    SizedBox(key: key, height: 40, child: const Text('target')),
    const SizedBox(height: 600),
  ],
);

Widget _app(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 300, height: 300, child: child),
    ),
  ),
);

void main() {
  testWidgets('흐림이 있으면 요소가 상자 위 끝에서 20 아래에 선다', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _app(PScrollFog(use: PScrollFogUse.overlayBody, child: _body(key))),
    );
    revealBelowFog(key.currentContext!, duration: Duration.zero);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(key)).dy, closeTo(20, 0.5));
  });

  testWidgets('흐림이 없으면 요소가 상자 맨 위에 붙는다', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(_app(SingleChildScrollView(child: _body(key))));
    revealBelowFog(key.currentContext!, duration: Duration.zero);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(key)).dy, closeTo(0, 0.5));
  });
}
