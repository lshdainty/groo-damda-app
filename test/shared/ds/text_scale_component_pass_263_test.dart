// 글자 크기 두 갈래를 컴포넌트 단위까지 — groo-design #263(DESIGN.md Typography "글자 크기 설정을 따르는 것과 그대로 두는 것",
// 사용자 결정 2026-11-19). 100% · 선형 200% · 300% · 안드로이드 200%(비선형)에서 잰다.
//
// ⓐ 그대로 두는 것 — 도넛 가운데 합계 · 라벨(chart.yaml text-t5-static · text-t2-static), 슬라이더 눈금 표식(slider.yaml
//    text-t3-static), Image Frame 장수 표식(image-frame.yaml text-t1-static). 배율 없이 그려지고 크기가 100% 와 같다.
//    도넛 가운데는 넣을 수 있는지 판정과 그림이 같은 글이라, 그려진 글이 늘 구멍 안에 든다.
// ⓑ 커지는 것 — Quantity Picker 값(상자 52 는 최소 높이 — 값을 따라 높아지고 − · + 52 는 그대로 세로 가운데), 도넛 범례 글
//    (색 네모 10 은 그대로 첫 글줄 가운데).
// 첨부(Attachment Input)는 p_attachment_input_spec_test.dart 의 "큰 글자" 묶음이 잰다.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:groo_damda_app/shared/ds/quantity_picker/p_quantity_picker.dart';
import 'package:groo_damda_app/shared/ds/slider/p_slider.dart';

import '../../support/android_font_scale.dart';

const _scalers = <(String, TextScaler)>[
  ('100%', TextScaler.noScaling),
  ('200%', TextScaler.linear(2)),
  ('300%', TextScaler.linear(3)),
  ('안드로이드 200%', AndroidNonlinearTextScaler()),
];

Future<void> _loadFonts() async {
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  for (final family in const ['Pretendard', 'FlutterTest']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required TextScaler scaler,
  double width = 330,
}) async {
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(textScaler: scaler, disableAnimations: true),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

RenderParagraph _paragraph(WidgetTester tester, Finder of) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: of, matching: find.byType(RichText), matchRoot: true),
    );

/// [of] 안의 그려진 글 모두 — 배율 없이 그리고, 크기가 100% 때([base])와 같다. 처음 부르면 [base] 를 채운다.
void _expectStatic(
  WidgetTester tester,
  Finder of,
  List<Size> base,
  String reason,
) {
  final texts = find
      .descendant(of: of, matching: find.byType(RichText), matchRoot: true)
      .evaluate()
      .toList();
  expect(texts, isNotEmpty, reason: reason);
  final sizes = <Size>[];
  for (final e in texts) {
    final rp = e.renderObject! as RenderParagraph;
    expect(rp.textScaler, TextScaler.noScaling, reason: '$reason 배율 없이');
    sizes.add(rp.size);
  }
  if (base.isEmpty) {
    base.addAll(sizes);
  } else {
    expect(sizes, base, reason: '$reason 크기 = 100%');
  }
}

void main() {
  setUpAll(_loadFonts);

  group('그대로 두는 것', () {
    testWidgets('도넛 가운데 합계 · 라벨 — 배율 없이 그리고, 판정대로 구멍 안에 든다', (tester) async {
      const d = 160.0;
      final hole = d - 2 * chartDonutThickness(d);
      final base = <Size>[];
      final fits = <bool>[];
      for (final (name, scaler) in _scalers) {
        await _pump(
          tester,
          PDonutChart(
            label: '10월 카테고리별 지출',
            centerLabel: '10월 지출',
            centerAmount: '927,400원',
            onFitChanged: fits.add,
            slices: const [
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
          scaler: scaler,
        );
        final center = find.byKey(const ValueKey('chart-donut-center'));
        expect(center, findsOneWidget, reason: '$name 가운데 글');
        _expectStatic(tester, center, base, '$name 가운데 글');
        // 그려진 글 묶음의 네 모서리가 구멍(원 — 가장자리에서 4 안쪽) 안이다
        final o = tester.getCenter(find.byKey(const ValueKey('chart-donut')));
        for (final key in const [
          'chart-donut-center-label',
          'chart-donut-center-amount',
        ]) {
          final r = tester.getRect(find.byKey(ValueKey(key)));
          for (final p in [
            r.topLeft,
            r.topRight,
            r.bottomLeft,
            r.bottomRight,
          ]) {
            expect(
              (p - o).distance,
              lessThanOrEqualTo(hole / 2 - kChartHoleInset + 0.01),
              reason: '$name $key 이 구멍 밖',
            );
          }
        }
      }
      // 판정은 글자 크기와 상관없이 늘 들어간다 — 바뀐 적이 없다
      expect(fits, isEmpty);
    });

    testWidgets('도넛 가운데 — 안 든다고 판정하면 어느 배율에서도 그리지 않는다', (tester) async {
      for (final (name, scaler) in _scalers) {
        await _pump(
          tester,
          const PDonutChart(
            label: '큰 합계',
            diameter: 120,
            centerLabel: '10월 지출',
            centerAmount: '927,400,000,000원',
            slices: [
              PDonutSlice(
                key: 'a',
                label: '식비',
                amount: 1,
                color: PChartColor.blue,
              ),
            ],
          ),
          scaler: scaler,
        );
        expect(
          find.byKey(const ValueKey('chart-donut-center')),
          findsNothing,
          reason: name,
        );
      }
    });

    testWidgets('슬라이더 눈금 표식 — 배율 없이 그리고 줄 높이 18 그대로', (tester) async {
      final base = <Size>[];
      for (final (name, scaler) in _scalers) {
        await _pump(
          tester,
          PSlider(value: 40, onChanged: (_) {}, label: '음량', step: 25),
          scaler: scaler,
        );
        final markers = find.byKey(const ValueKey('slider-markers'));
        _expectStatic(tester, markers, base, '$name 표식');
        expect(tester.getSize(markers).height, 18, reason: '$name 표식 줄');
      }
    });

    testWidgets('Image Frame 장수 표식 — 배율 없이 그리고 높이 19 그대로', (tester) async {
      final base = <Size>[];
      Size? box;
      for (final (name, scaler) in _scalers) {
        await _pump(
          tester,
          const Align(
            alignment: Alignment.topLeft,
            child: PImageFrameIndicator(text: '1 / 12', label: '사진 12장 중 1번째'),
          ),
          scaler: scaler,
        );
        final indicator = find.byType(PImageFrameIndicator);
        _expectStatic(tester, indicator, base, '$name 장수');
        final size = tester.getSize(indicator);
        box ??= size;
        expect(size, box, reason: '$name 표식 상자');
        expect(size.height, 19, reason: name);
      }
    });
  });

  group('커지는 것', () {
    testWidgets(
      'Quantity Picker — 값이 커지고 상자는 52 이상으로 따라 높아지며 − · + 는 52 그대로 세로 가운데',
      (tester) async {
        for (final (name, scaler) in _scalers) {
          await _pump(
            tester,
            PQuantityPicker(
              semanticLabel: '횟수',
              defaultValue: 3,
              max: 10,
              getValueText: (v) => '$v회',
            ),
            scaler: scaler,
          );
          final root = tester.getRect(
            find.byKey(const ValueKey('quantity-root')),
          );
          final valueFinder = find.byKey(const ValueKey('quantity-value-text'));
          final rp = _paragraph(tester, valueFinder);
          final line =
              scaler.scale(rp.text.style!.fontSize!) * rp.text.style!.height!;
          // 값은 글자 배율로 그리고 잘리지 않는다(그린 높이 = 한 줄 높이)
          expect(rp.textScaler, scaler, reason: '$name 값 배율');
          expect(rp.size.height, closeTo(line, 0.5), reason: '$name 값 잘림');
          expect(
            root.height,
            closeTo(math.max(52, line), 0.5),
            reason: '$name 상자 = max(52, 값 줄)',
          );
          final value = tester.getRect(valueFinder);
          expect(
            value.top,
            greaterThanOrEqualTo(root.top - 0.01),
            reason: name,
          );
          expect(
            value.bottom,
            lessThanOrEqualTo(root.bottom + 0.01),
            reason: name,
          );
          for (final key in const [
            'quantity-decrement',
            'quantity-increment',
          ]) {
            final b = tester.getRect(
              find
                  .descendant(
                    of: find.byKey(ValueKey(key)),
                    matching: find.byType(Container),
                  )
                  .first,
            );
            expect(b.size, const Size.square(52), reason: '$name $key');
            expect(
              b.center.dy,
              closeTo(root.center.dy, 0.01),
              reason: '$name $key 세로 가운데',
            );
          }
        }
      },
    );

    testWidgets('도넛 범례 — 이름 아래로 내린 줄에서 색 네모(10)는 첫 글줄 가운데', (tester) async {
      for (final (name, scaler) in _scalers) {
        await _pump(
          tester,
          const PChartDonutLegend(
            items: [
              PChartDonutLegendItem(
                key: 'a',
                label: '식비',
                color: PChartColor.blue,
                percent: '56%',
                amount: '700,000원',
              ),
            ],
          ),
          scaler: scaler,
          // 이름 아래로 내리는 폭(16em 보다 좁다) — 100% 에서도 같은 배치로 잰다
          width: 200,
        );
        final swatch = tester.getRect(
          find.byKey(const ValueKey('chart-donut-swatch')),
        );
        expect(swatch.width, closeTo(10, 0.01), reason: '$name 네모');
        expect(swatch.height, closeTo(10, 0.01), reason: '$name 네모');
        final labelFinder = find.byKey(const ValueKey('chart-donut-label'));
        final rp = _paragraph(tester, labelFinder);
        expect(rp.textScaler, scaler, reason: '$name 범례 글 배율');
        final firstLine =
            scaler.scale(rp.text.style!.fontSize!) * rp.text.style!.height!;
        final label = tester.getRect(labelFinder);
        expect(
          swatch.center.dy,
          closeTo(label.top + firstLine / 2, 0.01),
          reason: '$name 네모가 첫 글줄 가운데',
        );
      }
    });
  });
}
