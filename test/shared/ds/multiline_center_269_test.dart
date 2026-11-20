// 글이 여러 줄일 때 아이콘 · 컨트롤은 글 전체의 세로 가운데 — 스낵바(아이콘 · 액션) · 체크박스 줄 · 라디오 줄 · 메뉴 줄 ·
// 도넛 범례 줄(groo-design #269). 그 밖의 부품(스위치 · 폼 도움말 · 배너 · 머리 닫기)은 첫 줄 가운데 그대로라 여기서 재지 않는다
// (header_button_first_line_test). 좁은 폭 320 · 큰 글자(200% · 안드로이드 200%)에서 글이 정말 여러 줄인지 먼저 보고 잰다.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/android_font_scale.dart';
import '../../support/real_fonts.dart';

const _scalers = <(String, TextScaler)>[
  ('200%', TextScaler.linear(2)),
  ('안드로이드 200%', AndroidNonlinearTextScaler()),
];

const _long = '이번 달 고정 지출로 묶어 둔 생활비 · 통신비 · 보험료가 모두 들어갑니다';

Future<void> _pump(WidgetTester tester, TextScaler scaler, Widget child) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: scaler),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// 글 [of] 의 줄 수.
int _lines(WidgetTester tester, Finder of) {
  final rp = tester.renderObject<RenderParagraph>(
    find.descendant(of: of, matching: find.byType(RichText), matchRoot: true),
  );
  return rp
      .getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: rp.text.toPlainText().length,
        ),
      )
      .map((b) => b.top.round())
      .toSet()
      .length;
}

double _centerY(WidgetTester tester, Finder f) => tester.getRect(f).center.dy;

/// 여러 [Finder] 를 묶은 상자의 세로 가운데.
double _unionCenterY(WidgetTester tester, List<Finder> fs) {
  final rects = [for (final f in fs) tester.getRect(f)];
  final top = rects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
  final bottom = rects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
  return (top + bottom) / 2;
}

Finder _named(String name) =>
    find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == name);

void main() {
  setUpAll(loadRealFonts);

  for (final (name, scaler) in _scalers) {
    testWidgets('스낵바 $name — 아이콘 · 액션이 여러 줄 글의 가운데', (tester) async {
      await _pump(
        tester,
        scaler,
        PSnackbarView(
          message: _long,
          closeLabel: '닫기',
          tone: PSnackbarTone.positive,
          action: PSnackbarAction(label: '되돌리기', onPressed: () {}),
        ),
      );
      const message = ValueKey('snackbar-message');
      expect(_lines(tester, find.byKey(message)), greaterThan(1));
      final want = _centerY(tester, find.byKey(message));
      expect(
        _centerY(tester, find.byKey(const ValueKey('snackbar-icon'))),
        closeTo(want, 0.5),
      );
      expect(
        _centerY(tester, find.byKey(const ValueKey('snackbar-action'))),
        closeTo(want, 0.5),
      );
    });

    testWidgets('체크박스 줄 $name — 칸이 여러 줄 라벨의 가운데', (tester) async {
      await _pump(
        tester,
        scaler,
        PCheckbox(label: _long, checked: true, onChanged: (_) {}),
      );
      final label = _named(_long);
      expect(_lines(tester, label), greaterThan(1));
      expect(
        _centerY(tester, find.byType(PCheckmark)),
        closeTo(_centerY(tester, label), 0.5),
      );
    });

    testWidgets('라디오 줄 $name — 동그라미가 여러 줄 라벨의 가운데', (tester) async {
      await _pump(
        tester,
        scaler,
        PRadioGroup<int>(
          value: 1,
          onChanged: (_) {},
          children: const [PRadio<int>(value: 1, label: _long)],
        ),
      );
      final label = _named(_long);
      expect(_lines(tester, label), greaterThan(1));
      expect(
        _centerY(tester, find.byType(PRadiomark)),
        closeTo(_centerY(tester, label), 0.5),
      );
    });

    testWidgets('메뉴 줄 $name — 앞 아이콘이 여러 줄 이름 · 설명 묶음의 가운데', (tester) async {
      await _pump(
        tester,
        scaler,
        PMenuSheetView(
          content: PMenuSheetContent(
            title: '주간 회의 메모',
            groups: [
              PMenuSheetGroup([
                PMenuSheetItem(
                  label: '이 메모를 파일로 내보내기',
                  description: '선택한 기간의 메모를 한 파일로 저장해요.',
                  icon: LucideIcons.folderOutput,
                  onSelect: () {},
                ),
              ]),
            ],
          ),
        ),
      );
      const labelKey = ValueKey('p-menu-sheet-item-label');
      const descKey = ValueKey('p-menu-sheet-item-description');
      expect(_lines(tester, find.byKey(labelKey)), greaterThan(1));
      expect(
        _centerY(tester, find.byKey(const ValueKey('p-menu-sheet-item-icon'))),
        closeTo(
          _unionCenterY(tester, [find.byKey(labelKey), find.byKey(descKey)]),
          0.5,
        ),
      );
    });

    testWidgets('도넛 범례 줄 $name · 좁은 줄 — 네모가 이름 · % · 금액 묶음 전체의 가운데', (
      tester,
    ) async {
      await _pump(
        tester,
        scaler,
        const PChartDonutLegend(
          items: [
            PChartDonutLegendItem(
              key: 'fixed',
              label: _long,
              color: PChartColor.blue,
              percent: '31%',
              amount: '384,400원',
            ),
          ],
        ),
      );
      const label = ValueKey('chart-donut-label');
      const amount = ValueKey('chart-donut-amount');
      expect(_lines(tester, find.byKey(label)), greaterThan(1));
      // 좁은 줄 — % · 금액이 이름 아래로 내려갔다
      expect(
        tester.getRect(find.byKey(amount)).top,
        greaterThanOrEqualTo(tester.getRect(find.byKey(label)).bottom),
      );
      expect(
        _centerY(tester, find.byKey(const ValueKey('chart-donut-swatch'))),
        closeTo(
          _unionCenterY(tester, [find.byKey(label), find.byKey(amount)]),
          0.5,
        ),
      );
    });
  }

  testWidgets('도넛 범례 줄 100% · 넓은 줄 — 이름이 줄을 바꾸면 네모 · % · 금액이 줄 전체의 가운데', (
    tester,
  ) async {
    await _pump(
      tester,
      TextScaler.noScaling,
      const PChartDonutLegend(
        items: [
          PChartDonutLegendItem(
            key: 'fixed',
            label: _long,
            color: PChartColor.blue,
            percent: '31%',
            amount: '384,400원',
          ),
        ],
      ),
    );
    const label = ValueKey('chart-donut-label');
    expect(_lines(tester, find.byKey(label)), greaterThan(1));
    final want = _centerY(tester, find.byKey(label));
    for (final key in const [
      'chart-donut-swatch',
      'chart-donut-percent',
      'chart-donut-amount',
    ]) {
      expect(
        _centerY(tester, find.byKey(ValueKey(key))),
        closeTo(want, 0.5),
        reason: key,
      );
    }
  });
}
