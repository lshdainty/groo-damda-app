import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';

/// 1000% 이상 쉼표(2026-11-11) — 가장 나쁜 값(1,234% · 12,345.67%)을 폭 360 · 글자 100% / 200% 로 그려
/// 넘침이 없는지 잰다. 그림은 `PERCENT_OUT` 환경 변수 폴더에 쓴다(없으면 건너뜀). 호스트는 Ahem 글꼴이라 폭은 실제보다 넓다.
Future<void> _shot(
  WidgetTester tester,
  String name,
  double scale,
  Brightness b,
  List<(String, String)> rows,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 900);
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: b == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: w!,
      ),
      home: RepaintBoundary(
        key: key,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, v) in rows) ...[
                  Text(label),
                  PDelta(direction: PDeltaDirection.up, value: v, text: '전일'),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull, reason: '$name 넘침');
  final out = Platform.environment['PERCENT_OUT'];
  if (out == null) return;
  await tester.runAsync(() async {
    final r = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await r.toImage();
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
    File('$out/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  const under = '0.1% 미만';
  final after = <(String, String)>[
    ('등락률 1,234.50', formatChangeRateAbs(1234.5)),
    ('등락률 12,345.67', formatChangeRateAbs(12345.67)),
    ('비중 12,345.7', formatShare(12345.67, underOne: under)),
    ('진행률 1,234', formatProgress(1234)),
  ];
  final before = <(String, String)>[
    ('등락률 1234.50 (전)', '1234.50%'),
    ('등락률 12345.67 (전)', '12345.67%'),
    ('비중 12345.7 (전)', '12345.7%'),
    ('진행률 1234 (전)', '1234%'),
  ];
  for (final s in [1.0, 2.0]) {
    for (final b in [Brightness.light, Brightness.dark]) {
      final tag = '${s == 1.0 ? "x100" : "x200"}-${b.name}';
      testWidgets(
        '쉼표 후 $tag 넘침 없음',
        (t) => _shot(t, 'after-$tag', s, b, after),
      );
      testWidgets('쉼표 전 $tag', (t) => _shot(t, 'before-$tag', s, b, before));
    }
  }
}
