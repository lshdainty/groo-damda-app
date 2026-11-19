// 지원 폭 — 320 이상(DESIGN.md Layout "지원 폭"). 320 보다 좁으면(작은 기기 · 분할 화면) 모양은 덜 다듬어져도 되지만 겹침 · 가림 ·
// 잘림은 막는다. 부품마다 좁은 폭(200 언저리)은 규칙대로, 보통 폭(360)은 아무것도 바뀌지 않는지 본다.
//
//   Segmented Control — 칸이 글보다 좁으면 낱말 안에서 꺾지 않고 줄 전체 가로 스크롤
//   Chart(도넛)        — 자리가 지름보다 좁으면 자리 폭에 맞춰 지름 · 두께(지름 ÷ 10 + 6)를 다시 셈
//   Date Picker        — 시트의 이어지는 달은 요일 줄 + 2주에서 멈추고 시트 본문이 스크롤(머리 · 바닥은 보인다)
//   Bottom Navigation  — 칸이 + 원 44 보다 좁으면 줄어든 바처럼 라벨 숨김 · 원 36(라벨은 이름으로 남는다)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker_day.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/support_width.dart';

/// 논리 폭 [width] 의 화면(배율 1).
void _screen(WidgetTester tester, double width, {double height = 640}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

void main() {
  test('지원 폭 하한은 320', () => expect(kSupportMinWidth, 320));

  group('Segmented Control', () {
    // 웹 QA 와 같은 칸 넷 — 폭 200 이면 칸 약 48 · 글 자리 24 로 "이번 주" 가 글자 단위로 꺾였다
    const labels = ['오늘', '이번 주', '다음 주', '전체'];
    Future<void> pump(WidgetTester tester, double width) async {
      _screen(tester, width);
      var value = 'b';
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: StatefulBuilder(
                builder: (context, set) => PSegmentedControl<String>(
                  semanticLabel: '할 일 보기',
                  value: value,
                  onChanged: (v) => set(() => value = v),
                  items: [
                    for (var i = 0; i < labels.length; i++)
                      PSegmentedItem(
                        value: String.fromCharCode(97 + i),
                        label: labels[i],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder label(String text) => find.byWidgetPredicate(
      (w) => w is Text && w.data?.replaceAll('⁠', '') == text,
    );
    // 글 한 줄 높이(t5 22) — 낱말 안에서 꺾이면 두 줄 이상이 된다
    double lines(WidgetTester tester, String text) =>
        tester.getSize(label(text)).height / 22;

    testWidgets('360 — 그대로다: 칸이 트랙을 똑같이 나누고 미끄러지는 알약 · 스크롤 없음', (tester) async {
      await pump(tester, 360);
      expect(find.byKey(const ValueKey('segmented-scroll')), findsNothing);
      expect(find.byKey(const ValueKey('segmented-indicator')), findsOneWidget);
      final widths = tester
          .widgetList(find.byKey(const ValueKey('segmented-item')))
          .map((w) => tester.getSize(find.byWidget(w)).width)
          .toSet();
      expect(widths.length, 1);
      expect(widths.single, closeTo((360 - 8 - 8) / 4, 0.01));
    });

    testWidgets('320 — 그대로다(하한 포함)', (tester) async {
      await pump(tester, 320);
      expect(find.byKey(const ValueKey('segmented-scroll')), findsNothing);
      expect(find.byKey(const ValueKey('segmented-indicator')), findsOneWidget);
    });

    testWidgets('200 — 낱말 안에서 꺾지 않고 줄 전체가 가로로 스크롤한다 · 고른 칸이 알약을 칠한다', (
      tester,
    ) async {
      await pump(tester, 200);
      final scroll = find.byKey(const ValueKey('segmented-scroll'));
      expect(scroll, findsOneWidget);
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      // 낱말 하나뿐인 글은 한 줄, "이번 주" 는 낱말 사이에서만 꺾인다(두 줄 이하)
      for (final text in labels) {
        expect(
          lines(tester, text),
          lessThanOrEqualTo(text.contains(' ') ? 2 : 1),
          reason: text,
        );
      }
      // 칸 폭이 고르지 않을 수 있어 미끄러지는 알약은 없고, 고른 칸이 알약의 바탕 · 안쪽 1px 를 칠한다
      expect(find.byKey(const ValueKey('segmented-indicator')), findsNothing);
      final c = tester.element(find.byType(PSegmentedControl<String>)).colors;
      final selected = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('segmented-item')).at(1),
      );
      final box = selected.decoration as BoxDecoration;
      expect(box.color, c.bgLayerDefault);
      expect((box.border! as Border).top.color, c.strokeNeutralContrast);
      // 고르기는 그대로다 — 끝 칸으로 스크롤해 누른다
      await tester.ensureVisible(label('전체'));
      await tester.pumpAndSettle();
      await tester.tap(label('전체'));
      await tester.pumpAndSettle();
      final last = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('segmented-item')).at(3),
      );
      expect((last.decoration as BoxDecoration).color, c.bgLayerDefault);
    });

    test('칸 폭 — 최소가 몫보다 큰 칸만 최소로 두고 남은 폭을 나눈다', () {
      expect(segmentedNarrowWidths([40, 40, 40, 40], 200), [50, 50, 50, 50]);
      // 90 을 빼고 남은 110 ÷ 3 이 40 보다 작다 — 모두 최소, 합 210 이 넘쳐 스크롤한다
      expect(segmentedNarrowWidths([40, 90, 40, 40], 200), [40, 90, 40, 40]);
      expect(segmentedNarrowWidths([60, 90, 60, 60], 200), [60, 90, 60, 60]);
      expect(segmentedNarrowWidths([30, 100, 30], 200), [50, 100, 50]);
    });
  });

  group('Chart 도넛', () {
    Future<void> pump(WidgetTester tester, double room) async {
      _screen(tester, 360);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: room,
                child: const PDonutChart(
                  label: '10월 카테고리별 지출',
                  diameter: 180,
                  slices: [
                    PDonutSlice(
                      key: 'a',
                      label: '식비',
                      amount: 700,
                      color: PChartColor.blue,
                    ),
                    PDonutSlice(
                      key: 'b',
                      label: '교통',
                      amount: 300,
                      color: PChartColor.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('자리가 지름 이상(312)이면 그대로다 — 지름 180 · 두께 24', (tester) async {
      await pump(tester, 312);
      expect(
        tester.getSize(find.byKey(const ValueKey('chart-donut'))),
        const Size(180, 180),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('chart-frame'))).height,
        180,
      );
      final pie = tester.widget<PieChart>(find.byType(PieChart)).data;
      expect(pie.sections.first.radius, 24);
      expect(pie.centerSpaceRadius, 90 - 24);
    });

    testWidgets('자리가 지름보다 좁으면(150) 자리 폭이 지름 — 두께는 150 ÷ 10 + 6 = 21, 잘리지 않는다', (
      tester,
    ) async {
      await pump(tester, 150);
      final donut = tester.getRect(find.byKey(const ValueKey('chart-donut')));
      final frame = tester.getRect(find.byKey(const ValueKey('chart-frame')));
      expect(donut.size, const Size(150, 150));
      expect(frame.height, 150);
      expect(donut.left, greaterThanOrEqualTo(frame.left));
      expect(donut.right, lessThanOrEqualTo(frame.right));
      final pie = tester.widget<PieChart>(find.byType(PieChart)).data;
      expect(pie.sections.first.radius, chartDonutThickness(150));
      expect(pie.sections.first.radius, 21);
      expect(pie.centerSpaceRadius, 75 - 21);
    });
  });

  group('Date Picker 시트의 이어지는 달', () {
    Future<void> open(WidgetTester tester, Size size, {double text = 1}) async {
      _screen(tester, size.width, height: size.height);
      tester.platformDispatcher.textScaleFactorTestValue = text;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => PBottomSheet.show<void>(
                  context,
                  dismissible: false,
                  builder: (context) => PBottomSheetContent(
                    title: '기간',
                    closeLabel: '닫기',
                    flushBody: true,
                    body: SizedBox(
                      height: PDatePicker.sheetBodyHeight(context),
                      child: PDatePicker.range(
                        labels: PDatePickerLabels.of(context),
                        visibleRange: PDateVisibleRange.continuous,
                        presets: const [
                          PDatePreset.thisWeek,
                          PDatePreset.thisMonth,
                        ],
                        today: DateTime(2026, 10, 29),
                        onChanged: (_) {},
                      ),
                    ),
                    footer: [
                      PButton(
                        label: '초기화',
                        size: PButtonSize.large,
                        variant: PButtonVariant.neutralWeak,
                        onPressed: () {},
                      ),
                      PButton(
                        label: '완료',
                        size: PButtonSize.large,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// 이어지는 달 — 요일 줄(48 — 칸 안 글이라 글자 크기를 따르지 않는다) + 달 스크롤의 높이.
    double calendar(WidgetTester tester) =>
        kDatePickerCellHeight +
        tester.getSize(find.byKey(const ValueKey('date-scroll'))).height;

    testWidgets('보통 폭(360 × 640)은 그대로다 — 본문 = 90% − 머리 70 − 바닥 76', (
      tester,
    ) async {
      await open(tester, const Size(360, 640));
      expect(
        tester.getSize(find.byKey(const ValueKey('date-root'))).height,
        640 * 0.9 - 70 - 76,
      );
    });

    for (final text in const [1.0, 2.0]) {
      testWidgets(
        '좁고 낮은 화면(200 × 330 · 글자 ${text * 100}%) — 요일 줄 + 2주에서 멈추고 시트 본문이 스크롤한다',
        (tester) async {
          await open(tester, const Size(200, 330), text: text);
          // 요일 줄 + 2주 — 칸 · 요일 줄은 48 그대로(groo-design #260)
          const floor = 3 * kDatePickerCellHeight;
          expect(calendar(tester), greaterThanOrEqualTo(floor - 0.01));
          // 시트 본문이 스크롤한다
          final body = tester
              .state<ScrollableState>(
                find
                    .descendant(
                      of: find.byKey(const ValueKey('p-bottom-sheet-body')),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              )
              .position;
          expect(body.maxScrollExtent, greaterThan(0));
          // 머리 · 바닥은 화면 안에 그대로 보인다
          final header = tester.getRect(
            find.byKey(const ValueKey('p-bottom-sheet-header')),
          );
          final footer = tester.getRect(
            find.byKey(const ValueKey('p-bottom-sheet-footer')),
          );
          expect(header.top, greaterThanOrEqualTo(0));
          expect(footer.bottom, lessThanOrEqualTo(330));
          expect(footer.top, greaterThanOrEqualTo(header.bottom));
        },
      );
    }
  });

  group('Bottom Navigation', () {
    Widget bar(PBottomNavigationController controller) => PBottomNavigation(
      semanticLabel: '주 메뉴',
      controller: controller,
      add: PBottomNavigationAdd(label: '거래 추가', onPressed: () {}),
      items: [
        for (final (i, label) in ['홈', '가계부', '캘린더', '전체'].indexed)
          PBottomNavigationItem(
            icon: LucideIcons.house,
            selectedIcon: LucideIcons.house500,
            label: label,
            current: i == 0,
            onTap: () {},
          ),
      ],
    );

    Future<PBottomNavigationController> pump(
      WidgetTester tester,
      double width,
    ) async {
      _screen(tester, width);
      final controller = PBottomNavigationController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: bar(controller),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    final labels = find.byKey(const ValueKey('bottom-navigation-label'));
    Size add(WidgetTester tester) =>
        tester.getSize(find.byKey(const ValueKey('bottom-navigation-add')));

    test('칸 폭 — 320 화면에서 52.8(44 이상), 276 아래에서 44 미만', () {
      expect(bottomNavigationCellWidth(320), closeTo(52.8, 0.01));
      expect(bottomNavigationNarrow(320), isFalse);
      expect(bottomNavigationNarrow(277), isFalse);
      expect(bottomNavigationNarrow(275), isTrue);
      expect(bottomNavigationNarrow(200), isTrue);
    });

    testWidgets('360 — 그대로다: 라벨 넷 · + 원 44', (tester) async {
      await pump(tester, 360);
      expect(labels, findsNWidgets(4));
      expect(add(tester), const Size.square(44));
    });

    testWidgets('200 — 라벨을 숨기고 + 원 36, 라벨은 칸의 이름으로 남는다', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, 200);
      expect(labels, findsNothing);
      expect(add(tester), const Size.square(36));
      // 바 높이는 펼침 66 그대로
      expect(
        tester
            .getSize(find.byKey(const ValueKey('bottom-navigation-bar')))
            .height,
        kBottomNavigationHeight,
      );
      for (final name in ['홈', '가계부', '캘린더', '전체']) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      // 아이콘끼리 겹치지 않는다
      final cells = find.byKey(const ValueKey('bottom-navigation-item'));
      for (var i = 0; i < 3; i++) {
        expect(
          tester.getRect(cells.at(i)).right,
          lessThanOrEqualTo(tester.getRect(cells.at(i + 1)).left),
        );
      }
      handle.dispose();
    });

    testWidgets('200 — 줄었다가 펴도(화면 바뀜) 라벨은 숨은 채 · 원 36 — 서로 덮어쓰지 않는다', (
      tester,
    ) async {
      final controller = await pump(tester, 200);
      controller.setCompact(true);
      await tester.pumpAndSettle();
      expect(labels, findsNothing);
      controller.expand();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(controller.compact, isFalse);
      expect(labels, findsNothing);
      expect(add(tester), const Size.square(36));
    });

    testWidgets('360 — 줄었다가 펴면 라벨이 다시 보인다(좁음이 줄어듦을 덮어쓰지 않는다)', (tester) async {
      final controller = await pump(tester, 360);
      controller.setCompact(true);
      await tester.pumpAndSettle();
      expect(labels, findsNothing);
      controller.expand();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(labels, findsNWidgets(4));
      expect(add(tester), const Size.square(44));
    });
  });
}
