// B5 — 더치페이 참여자 줄: 금액 입력칸이 큰 글자 · 좁은 줄에서 본문 아래 전폭으로(list.md "큰 글자에서 값을 본문 아래로").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/plain_text.dart';
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
                  width: 96,
                  child: PInput(
                    controller: ctrl,
                    semanticLabel: '$name 금액',
                    suffixText: '원',
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
  const names = ['김서연', '아주아주긴이름의참여자 홍길동'];
  final rows = <String>[];
  for (final w in [360.0, 390.0]) {
    for (final s in [1.0, 2.0]) {
      for (final name in names) {
        testWidgets('폭 $w · 글자 ${s * 100}% · $name', (tester) async {
          final ctrl = TextEditingController(text: '987,654,321');
          addTearDown(ctrl.dispose);
          await _pump(
            tester,
            width: w,
            scale: s,
            name: name,
            detail: '987,654,321원',
            ctrl: ctrl,
          );
          expect(tester.takeException(), isNull);
          final input = tester.getRect(find.byType(PInput));
          final row = tester.getRect(find.byKey(const ValueKey('row')));
          final below = find.byKey(const ValueKey('plist-value-below'));
          final stacked = below.evaluate().isNotEmpty;
          // 문턱 — 줄 안 폭(폭 − 24 × 2) < 16em(t5 × 배율)
          final inner = w - 48;
          final threshold = 16 * 16 * s; // t5 = 16
          expect(
            stacked,
            inner < threshold,
            reason: 'inner $inner threshold $threshold',
          );
          if (stacked) {
            expect(input.width, closeTo(inner - 42 - 12 - 0, 60));
            expect(input.width, greaterThan(150));
          } else {
            expect(input.width, 96);
          }
          expect(input.left, greaterThanOrEqualTo(row.left));
          expect(input.right, lessThanOrEqualTo(row.right));
          final title = tester.getRect(findText(name).first);
          // 이름은 입력칸 옆 한 글자 기둥이 아니다 — 폭이 이름의 가장 긴 낱말 폭 이상
          expect(title.width, greaterThan(40));
          rows.add(
            '폭 ${w.toInt()} | ${(s * 100).toInt()}% | ${name.length > 6 ? '긴 이름' : '짧은 이름'} | '
            '${stacked ? '아래 전폭' : '줄 끝 96'} | 입력칸 ${input.width.toStringAsFixed(0)}x${input.height.toStringAsFixed(0)} | '
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
}
