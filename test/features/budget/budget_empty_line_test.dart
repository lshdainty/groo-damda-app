// 11-10 4B — 혼자 서는 빈 글은 14(t4)다. 다른 글 없이 단독으로 선 안내(BudgetEmptyLine)는 13 이 아니라 14 · fg-neutral-subtle · 가운데.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import '../todo/todo_test_support.dart';
import '../../support/plain_text.dart';

void main() {
  setUpAll(loadRealFonts);

  for (final scale in [1.0, 2.0]) {
    testWidgets('BudgetEmptyLine — 14 · 옅은 글 · 가운데, 글자 $scale 배에서도 넘치지 않는다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 640),
            textScaler: TextScaler.linear(scale),
          ),
          child: const Scaffold(
            body: BudgetEmptyLine('이번 달에 정한 예산이 아직 없어요. 예산을 정해 보세요'),
          ),
        ),
      );
      final c = tester.element(find.byType(BudgetEmptyLine)).colors;
      final text = tester.widget<Text>(
        findPlain('이번 달에 정한 예산이 아직 없어요. 예산을 정해 보세요'),
      );
      expect(text.style!.fontSize, 14);
      expect(text.style!.color, c.fgNeutralSubtle);
      expect(text.textAlign, TextAlign.center);
      expect(tester.takeException(), isNull);
    });
  }
}
