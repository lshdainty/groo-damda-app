// 더치페이 참여자 줄(실제 DutchStepFlow) — 폭 × 글자 배율에서 직접 입력 칸이 안 잘리는지.
//
// 줄 끝 편집 칸의 문턱은 px 다(글자 배율과 무관) — 줄 안 폭 < 54 + 2 × kDutchCustomFieldWidth(=398) 이면 칸이 이름
// 아래 전폭으로 내려가고, 아니면 줄 끝에 kDutchCustomFieldWidth 로 선다. wrap_b5/dutch_edit_below_test.dart 의
// PList+PInput 표와 같은 값이어야 한다. 줄 안 폭 = 대화상자(480) 또는 폰 폭 − 좌우 여백 24 × 2.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_step.dart'
    show kDutchCustomFieldWidth;
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import '../../support/dutch_flow_harness.dart';
import '../../support/plain_text.dart';
import '../../support/real_fonts.dart';

const _big = '9,999,999,999';

void main() {
  setUpAll(loadRealFonts);
  final rows = <String>[];
  tearDownAll(() {
    // ignore: avoid_print
    print(rows.join('\n'));
  });

  // 폭 → 줄 폭(대화상자는 480 에서 멈춘다)
  for (final (w, rowW) in [
    (360.0, 360.0),
    (390.0, 390.0),
    (480.0, 480.0),
    (1200.0, 480.0),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('폭 ${w.toInt()} · 글자 ${(scale * 100).toInt()}% · 직접 입력 $_big', (
        tester,
      ) async {
        final (_, l) = await openDutchFlow(
          tester,
          size: Size(w, 3000),
          textScale: scale,
        );
        await tester.enterText(find.byType(EditableText).first, '친구A');
        await tester.tap(findWidgetWithText(PButton, l.dutchAdd));
        await tester.pumpAndSettle();
        await tester.tap(findText(l.dutchSplitCustomTitle));
        await tester.pumpAndSettle();

        final row = find.byKey(const ValueKey('dutch-share-p0'));
        final input = find.descendant(of: row, matching: find.byType(PInput));
        expect(input, findsOneWidget);
        await tester.enterText(
          find.descendant(of: input, matching: find.byType(EditableText)),
          '9999999999',
        );
        await tester.pumpAndSettle();

        // (c) 렌더 오류(RenderFlex overflow 포함)가 없다
        expect(tester.takeException(), isNull);

        final rowRect = tester.getRect(row);
        final rect = tester.getRect(input);
        final stacked = find
            .descendant(
              of: row,
              matching: find.byKey(const ValueKey('plist-value-below')),
            )
            .evaluate()
            .isNotEmpty;
        final inner = rowW - 48;
        final threshold = 54.0 + 2 * kDutchCustomFieldWidth;
        expect(
          stacked,
          inner < threshold,
          reason: 'inner $inner threshold $threshold',
        );
        if (stacked) {
          // (b) 이름 아래 전폭 — 줄 안 폭에서 앞 자리(아바타 42 + 12)를 뺀 폭, 줄 안에 든다
          expect(rect.width, closeTo(inner - 54, 0.5));
          expect(rect.width, greaterThan(kDutchCustomFieldWidth));
          final title = tester.getRect(findText('친구A').last);
          expect(rect.top, greaterThanOrEqualTo(title.bottom));
        } else {
          // (a) 줄 끝에 정확히 172 로 선다
          expect(rect.width, kDutchCustomFieldWidth);
          expect(rect.right, closeTo(rowRect.right - 24, 0.5));
        }
        expect(rect.left, greaterThanOrEqualTo(rowRect.left));
        expect(rect.right, lessThanOrEqualTo(rowRect.right));

        final re = tester
            .state<EditableTextState>(
              find.descendant(of: input, matching: find.byType(EditableText)),
            )
            .renderEditable;
        rows.add(
          '폭 ${w.toInt()} | ${(scale * 100).toInt()}% | ${stacked ? '아래 전폭' : '줄 끝'} ${rect.width.toStringAsFixed(1)} | 칸 안쪽 ${re.size.width.toStringAsFixed(0)} | 스크롤 ${re.maxScrollExtent.toStringAsFixed(1)}',
        );
        if (scale == 1.0) {
          // $_big 는 100% 에서 칸 안에 다 보인다(스크롤 0)
          expect(re.maxScrollExtent, lessThanOrEqualTo(0.5));
        }
      });
    }
  }
}
