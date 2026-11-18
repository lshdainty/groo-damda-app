// 빠른 기간 칩 줄은 어디서나 한 줄 가로 스크롤(양 끝 흐림) — date-picker.md "빠른 기간" · chip.md "묶음 배치"(groo-design #255,
// 사용자 결정). 시트 안의 칩 묶음은 보통 줄을 바꾸지만, 이 줄이 늘면 달력(이어지는 달)이 그만큼 낮아지므로 예외다.
// 가장 나쁜 값 — 폰 320 · 글자 200%, 빠른 기간 아홉 개.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';

void main() {
  for (final mode in PDateVisibleRange.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${mode.name} · 320 · 글자 ${(scale * 100).round()}% — 빠른 기간은 한 줄 가로 스크롤 · 양 끝 흐림',
        (tester) async {
          tester.view.physicalSize = const Size(320, 1400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: GrooTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ko'),
              builder: (context, c) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: c!,
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 320,
                    height: mode == PDateVisibleRange.continuous ? 1200 : null,
                    child: PDatePicker.range(
                      labels: PDatePickerLabels.ko,
                      today: DateTime(2026, 10, 15),
                      visibleRange: mode,
                      presets: PDatePreset.values,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final chips = find.byWidgetPredicate((w) => w is PChipRadio);
          expect(chips, findsNWidgets(PDatePreset.values.length));
          final rects = [
            for (final e in chips.evaluate())
              tester.getRect(find.byWidget(e.widget)),
          ];
          // 한 줄 — 모든 칩의 위가 같다
          expect(
            rects.map((r) => r.top.roundToDouble()).toSet(),
            hasLength(1),
            reason: '칩 줄이 줄을 바꾼다',
          );
          // 줄 높이 = 칩 높이(스크롤 줄의 위아래 6 은 바깥에서 되돌린다)
          final row = find.byKey(const ValueKey('chip-scroll-row'));
          expect(row, findsOneWidget, reason: '가로 스크롤 줄');
          final group = find.byWidgetPredicate((w) => w is PChipRadioGroup);
          expect(
            tester.getSize(group).height,
            moreOrLessEquals(
              chipHeight(PChipSize.medium, TextScaler.linear(scale)),
            ),
          );
          expect(rects.first.height, tester.getSize(group).height);
          final rowBox = find.ancestor(
            of: row,
            matching: find.byType(PScrollFogMask),
          );
          expect(rowBox, findsOneWidget, reason: '양 끝 흐림');
          final fog = tester.widget<PScrollFogMask>(rowBox);
          expect(fog.axis, Axis.horizontal);
          expect(
            (fog.start, fog.end),
            (20.0, 20.0),
            reason: '좌우 흐림 20(chip.md)',
          );
          // 가로로 스크롤된다 — 끝 칩이 화면 밖에 있다가 끌면 들어온다
          final scrollable = tester.state<ScrollableState>(
            find.descendant(of: row, matching: find.byType(Scrollable)).first,
          );
          expect(scrollable.position.axis, Axis.horizontal);
          expect(scrollable.position.maxScrollExtent, greaterThan(0));
          await tester.drag(row, const Offset(-400, 0));
          await tester.pumpAndSettle();
          expect(scrollable.position.pixels, greaterThan(0));
        },
      );
    }
  }
}
