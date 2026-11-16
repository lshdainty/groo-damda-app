import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/ds/screen_band/p_screen_content.dart';

/// groo-design Layout "Safe Area" · "콘텐츠 폭 — 밀도" — 본문 내용 자리.
void main() {
  const box = Key('content');

  Future<Rect> pump(
    WidgetTester tester, {
    required Size size,
    EdgeInsets padding = EdgeInsets.zero,
    Widget Function(Widget child)? wrap,
    double maxWidth = kContentMaxWidth,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget content = PScreenContent(
      maxWidth: maxWidth,
      child: const SizedBox.expand(key: box),
    );
    if (wrap != null) content = wrap(content);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
          viewPadding: padding,
        ),
        child: Directionality(textDirection: TextDirection.ltr, child: content),
      ),
    );
    return tester.getRect(find.byKey(box));
  }

  testWidgets('폰 폭 — 좌우 안전 영역만큼 들인다(옆 상태 칸)', (tester) async {
    final r = await pump(
      tester,
      size: const Size(466, 678),
      padding: const EdgeInsets.only(right: 84),
    );
    expect(r.left, 0);
    expect(r.right, 466 - 84);
  });

  testWidgets('넓은 화면(768 이상) — 내용은 720 에서 멈추고 가운데', (tester) async {
    final r = await pump(tester, size: const Size(951, 669));
    expect(r.width, kContentMaxWidth);
    expect(r.left, (951 - kContentMaxWidth) / 2);
  });

  testWidgets('넓은 화면 + 옆 안전 영역 — 안전 영역 안에서 가운데', (tester) async {
    final r = await pump(
      tester,
      size: const Size(951, 669),
      padding: const EdgeInsets.only(right: 84),
    );
    expect(r.width, kContentMaxWidth);
    expect(r.left, (951 - 84 - kContentMaxWidth) / 2);
    expect(r.right, lessThanOrEqualTo(951 - 84));
  });

  testWidgets('혼자 서는 폼은 480 에서 멈춘다', (tester) async {
    final r = await pump(
      tester,
      size: const Size(951, 669),
      maxWidth: kFormMaxWidth,
    );
    expect(r.width, kFormMaxWidth);
  });

  testWidgets('768 미만은 폭을 멈추지 않는다', (tester) async {
    final r = await pump(tester, size: const Size(740, 900));
    expect(r.width, 740);
  });

  testWidgets('넓은 화면이어도 이미 좁은 자리는 다시 줄이지 않는다', (tester) async {
    final r = await pump(
      tester,
      size: const Size(951, 669),
      wrap: (child) => Center(child: SizedBox(width: 300, child: child)),
    );
    expect(r.width, 300);
  });

  testWidgets('겹쳐 써도 한 번만 들인다', (tester) async {
    final r = await pump(
      tester,
      size: const Size(466, 678),
      padding: const EdgeInsets.only(right: 84),
      wrap: (child) => PScreenContent(child: child),
    );
    expect(r.right, 466 - 84);
  });

  testWidgets('시트처럼 처리한 자리 안에서는 들이지 않는다', (tester) async {
    final r = await pump(
      tester,
      size: const Size(951, 669),
      padding: const EdgeInsets.only(right: 84),
      wrap: (child) => PScreenContent.handled(child: child),
    );
    expect(r, const Rect.fromLTWH(0, 0, 951, 669));
  });
}
