// 뒤를 만지면 안 되는 처리 덮개 — I-05 37 · 49.
// 1초 전에는 보이지 않고(손만 막는다), 1초에 딤 + 흰 원 40 이 뜨며 뒤 화면이 의미 트리에서 빠진다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/widgets/p_busy_scrim.dart';
import '../../support/plain_text.dart';

List<String> _labels(WidgetTester t) => [
  for (final n in t.semantics.simulatedAccessibilityTraversal()) n.label,
];

void main() {
  late PBusyScrimHandle handle;
  var taps = 0;

  Future<void> pump(WidgetTester tester, {bool dark = false}) async {
    taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => taps++,
                  child: const Text('뒤 화면 버튼'),
                ),
                TextButton(
                  onPressed: () =>
                      handle = PBusyScrim.show(context, label: '해지하는 중'),
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('1초 전에는 원이 없고 손은 막힌다', (tester) async {
    await pump(tester);
    await tester.tap(findText('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 999));
    expect(find.byType(PProgressCircle), findsNothing);
    await tester.tap(findText('뒤 화면 버튼'), warnIfMissed: false);
    expect(taps, 0, reason: '처음부터 손을 막는다');
    handle.hide();
    await tester.pump();
  });

  for (final dark in [false, true]) {
    testWidgets('${dark ? "다크" : "라이트"} 1초에 딤 + 흰 원 40 · 뒤 화면 숨김 · 걷으면 사라짐', (
      tester,
    ) async {
      final sem = tester.ensureSemantics();
      await pump(tester, dark: dark);
      await tester.tap(findText('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      final circle = tester.widget<PProgressCircle>(
        find.byType(PProgressCircle),
      );
      expect(circle.size, PProgressCircleSize.s40);
      expect(circle.tone, PProgressCircleTone.staticWhite);
      expect(circle.value, isNull);
      expect(circle.semanticsLabel, '해지하는 중');
      final c = (dark ? GrooTheme.dark() : GrooTheme.light())
          .extension<PColors>()!;
      final dim = tester.widget<ColoredBox>(
        find.byKey(const ValueKey('busy-scrim-dim')),
      );
      expect(dim.color, c.overlayDim);
      expect(_labels(tester), isNot(contains('뒤 화면 버튼')));
      expect(_labels(tester), contains('해지하는 중'));
      handle.hide();
      await tester.pump();
      expect(find.byType(PProgressCircle), findsNothing);
      expect(_labels(tester), contains('뒤 화면 버튼'));
      sem.dispose();
    });
  }
}
