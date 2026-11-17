import 'package:flutter/widgets.dart';

/// 지원 폭의 하한 — 논리 폭 320(DESIGN.md Layout "지원 폭 — 320 이상", WCAG 1.4.10 Reflow). 이 폭까지는 모든 스펙이
/// 그대로다. 웹 `src/shared/ds/support-width.ts` 와 같은 값이다.
const double kSupportMinWidth = 320;

/// 화면이 지원 폭보다 좁은가(작은 기기 · 분할 화면) — 320 미만은 모양이 덜 다듬어져도 되지만 글 · 누르는 것이 겹치거나
/// 가려지지 않고, 내용이 잘려 사라지지 않는다. 부품마다의 동작은 그 부품 스펙에 있다(Segmented Control 등). 폭 0(아직 화면
/// 크기를 모른다)은 좁은 화면으로 치지 않는다.
bool belowSupportWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width > 0 && width < kSupportMinWidth;
}
