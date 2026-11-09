import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';

/// 머리 조각(pinnedTop · header · pinnedBottom) 이음매로 뒤 목록이 한 줄 비치지 않는지 픽셀로 잰다.
/// 조각 높이(소수)와 옮긴 거리(소수)가 물리 픽셀 한 줄에서 맞닿아도 머리 영역 안엔 목록 색이 없어야 한다.
/// 호스트 Skia 렌더러 기준 — 기기 Impeller 는 따로 본다.
const _bg = Color(0xFF232937);
const _listInk = Color(0xFFFFFFFF);

Future<void> _run(WidgetTester tester, double dpr) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(390 * dpr, 800 * dpr);
  addTearDown(tester.view.reset);
  final boundary = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.dark(),
      home: RepaintBoundary(
        key: boundary,
        child: Scaffold(
          body: PScrollAutoHide(
            color: _bg,
            pinnedTop: const SizedBox(height: 52.37),
            header: const SizedBox(height: 101.71),
            pinnedBottom: const SizedBox(height: 60.2),
            builder: (ctx, c, h) => ListView(
              controller: c,
              padding: EdgeInsets.only(top: h),
              children: [
                for (var i = 0; i < 80; i++)
                  Container(height: 47.3, color: _listInk),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final state = tester.state<PScrollAutoHideState>(
    find.byType(PScrollAutoHide),
  );
  var measured = 0;
  // 300 내린 뒤 조금씩 여섯 번 올린다 — 머리가 소수 거리만큼 내려오는 위치마다 잰다
  for (final d in [300.3, -7.31, -13.13, -21.77, -9.4, -33.33, -51.9]) {
    final g = await tester.startGesture(const Offset(200, 600));
    await g.moveBy(Offset(0, -d));
    await tester.pump();
    final ro =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await tester.runAsync(() => ro.toImage(pixelRatio: dpr));
    final bytes = (await tester.runAsync(
      () => img!.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final w = img!.width;
    final bottomPx = (state.visibleBottom * dpr).floor() - 1;
    final leaks = <String>[];
    for (var y = 0; y < bottomPx; y++) {
      final o = (y * w + 195 * dpr.round()) * 4;
      final r = bytes.getUint8(o);
      final gg = bytes.getUint8(o + 1);
      final b = bytes.getUint8(o + 2);
      if ((r - 0x23).abs() > 3 ||
          (gg - 0x29).abs() > 3 ||
          (b - 0x37).abs() > 3) {
        leaks.add('y$y=rgb($r,$gg,$b)');
      }
    }
    expect(
      leaks,
      isEmpty,
      reason: 'dpr=$dpr drag=$d visibleBottom=${state.visibleBottom}',
    );
    measured++;
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(measured, 7);
}

void main() {
  group('PScrollAutoHide 머리 이음매', () {
    testWidgets('dpr 2.625 — 머리 영역 안에 목록 색이 비치지 않는다', (t) => _run(t, 2.625));
    testWidgets('dpr 3 — 머리 영역 안에 목록 색이 비치지 않는다', (t) => _run(t, 3));
  });
}
