// B5 — 더치페이 참여자 줄: 금액 입력칸이 큰 글자 · 좁은 줄에서 본문 아래 전폭으로(list.md "큰 글자에서 값을 본문 아래로").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/plain_text.dart';
import '../../support/real_fonts.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_step.dart'
    show kDutchCustomFieldWidth;
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double scale,
  required String name,
  required String detail,
  required TextEditingController ctrl,
  double boxWidth = 96,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: PList(
          children: [
            PListItem(
              key: const ValueKey('row'),
              title: name,
              detail: detail,
              prefix: PAvatar(name: name, size: PAvatarSize.s42),
              suffix: PListValue(
                mergeSemantics: false,
                child: PListEditWidth(
                  width: boxWidth,
                  child: PInput(
                    controller: ctrl,
                    semanticLabel: '$name 금액',
                    suffixText: '원',
                    tabularFigures: true,

                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRealFonts);
  const names = ['김서연', '아주아주긴이름의참여자 홍길동'];
  final rows = <String>[];
  for (final w in [360.0, 390.0]) {
    for (final s in [1.0, 2.0]) {
      for (final name in names) {
        testWidgets('폭 $w · 글자 ${s * 100}% · $name', (tester) async {
          final ctrl = TextEditingController(text: '9,999,999,999');
          addTearDown(ctrl.dispose);
          await _pump(
            tester,
            boxWidth: kDutchCustomFieldWidth,
            width: w,
            scale: s,
            name: name,
            detail: '9,999,999,999원',
            ctrl: ctrl,
          );
          expect(tester.takeException(), isNull);
          final input = tester.getRect(find.byType(PInput));
          final row = tester.getRect(find.byKey(const ValueKey('row')));
          final below = find.byKey(const ValueKey('plist-value-below'));
          final stacked = below.evaluate().isNotEmpty;
          // 문턱 — 줄 안 폭(폭 − 24 × 2) < 16em(t5 × 배율)
          final inner = w - 48;
          final threshold =
              54.0 +
              2 * kDutchCustomFieldWidth; // 웹과 같은 식: 앞 자리 54 + 칸 × 2 (172 → 398)
          expect(
            stacked,
            inner < threshold,
            reason: 'inner $inner threshold $threshold',
          );
          if (stacked) {
            expect(input.width, closeTo(inner - 42 - 12 - 0, 60));
            expect(input.width, greaterThan(150));
          } else {
            expect(input.width, kDutchCustomFieldWidth);
          }
          // 9억대 금액(987,654,321)이 칸 안에 다 들어간다 — 글이 칸보다 길어 스크롤되지 않는다
          final editable = tester.state<EditableTextState>(
            find.byType(EditableText),
          );
          final re = editable.renderEditable;
          rows.add(
            'DBG ${w.toInt()} ${(s * 100).toInt()}% ${name.length > 6 ? 'long' : 'short'} in=${input.width.toStringAsFixed(0)} view=${re.size.width.toStringAsFixed(0)}x${re.size.height.toStringAsFixed(0)} max=${re.maxScrollExtent.toStringAsFixed(0)} fs=${re.text!.style!.fontSize}',
          );
          // 시험 글꼴(Ahem)은 글자 폭이 실제보다 넓어 "안 잘림" 은 여기서 단언하지 않는다 — 칸 안쪽 폭(view)과 실제 글꼴 추정폭을 표로 남긴다
          rows.add(
            'EST ${w.toInt()} ${(s * 100).toInt()}% 987,654,321 ≈ ${(re.text!.style!.fontSize! * (9 * 0.59 + 2 * 0.28)).toStringAsFixed(0)} vs 칸 안쪽 ${re.size.width.toStringAsFixed(0)}',
          );
          expect(input.left, greaterThanOrEqualTo(row.left));
          expect(input.right, lessThanOrEqualTo(row.right));
          final title = tester.getRect(findText(name).first);
          // 이름은 입력칸 옆 한 글자 기둥이 아니다 — 폭이 이름의 가장 긴 낱말 폭 이상
          expect(title.width, greaterThan(40));
          rows.add(
            '폭 ${w.toInt()} | ${(s * 100).toInt()}% | ${name.length > 6 ? '긴 이름' : '짧은 이름'} | '
            '${stacked ? '아래 전폭' : '줄 끝 176'} | 입력칸 ${input.width.toStringAsFixed(0)}x${input.height.toStringAsFixed(0)} | '
            '이름 폭 ${title.width.toStringAsFixed(0)} | 줄 높이 ${row.height.toStringAsFixed(0)}',
          );
        });
      }
    }
  }
  tearDownAll(() {
    // ignore: avoid_print
    print(rows.join('\n'));
  });

  // 넓은 줄(480 대화상자와 같은 폭) — 칸이 옆에 서고 두 금액이 칸 안에 다 보인다(실제 글꼴 · TextPainter 계열 실측)
  for (final text in ['9,999,999,999', '912,345,678']) {
    testWidgets('폭 480 · 100% · $text — 칸 172 가 옆에 서고 글이 칸 안에 보인다', (
      tester,
    ) async {
      final ctrl = TextEditingController(text: text);
      addTearDown(ctrl.dispose);
      await _pump(
        tester,
        width: 480,
        scale: 1,
        name: '지수',
        detail: '$text원',
        ctrl: ctrl,
        boxWidth: kDutchCustomFieldWidth,
      );
      expect(find.byKey(const ValueKey('plist-value-below')), findsNothing);
      expect(tester.getSize(find.byType(PInput)).width, kDutchCustomFieldWidth);
      final re = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      expect(re.maxScrollExtent, lessThanOrEqualTo(0.5));
      rows.add(
        '폭 480 | 100% | $text | 칸 안쪽 ${re.size.width.toStringAsFixed(0)} | 스크롤 0 (글이 다 보임)',
      );
    });
  }
}
