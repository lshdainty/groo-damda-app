// 누르는 영역을 실제 hit-test 로 잰다 — 중심에서 사방으로 쏴 같은 대상이 받는 길이(최대 40 씩).
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [finder] 가 가리키는 위젯 자리의 중심을 누르면 받는 가로 · 세로 크기.
Size hitSize(WidgetTester tester, Finder finder) {
  final center = tester.getCenter(finder);
  final vid = tester.view.viewId;
  Object? target;
  {
    final r = HitTestResult();
    tester.binding.hitTestInView(r, center, vid);
    // 누름을 받는 쪽 — 가장 안쪽의 포인터 수신기(GestureDetector 의 Listener)
    target = r.path
        .map((h) => h.target)
        .firstWhere((t) => t is RenderPointerListener);
  }
  bool hits(Offset q) {
    final r = HitTestResult();
    tester.binding.hitTestInView(r, q, vid);
    return r.path.any((h) => identical(h.target, target));
  }

  int run(Offset d) {
    var n = 0;
    while (n < 40 && hits(center + d * (n + 1.0))) {
      n++;
    }
    return n;
  }

  return Size(
    run(const Offset(-1, 0)) + run(const Offset(1, 0)) + 1.0,
    run(const Offset(0, -1)) + run(const Offset(0, 1)) + 1.0,
  );
}
