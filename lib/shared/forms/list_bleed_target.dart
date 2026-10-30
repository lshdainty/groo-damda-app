import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';

/// 줄 뒤 작은 버튼을 오른쪽으로 [bleed] 내어 그리고(레이아웃 자리는 그대로), 보이는 상자 밖 위아래 · 블리드까지 누르는 영역을
/// 44 로 넓힌다 — 버튼 글 끝이 화면 끝 24 에 선다(웹 `-mr-x3_5` 와 같다). [PTouchExtendable] 이라 줄 위에서
/// [PTouchTargetScope] 가 이어 준다. 정사각 minSize 인 `PTouchTarget` 은 가로 블리드를 못 받는다.
///
/// 임시 — ds List 차례에 PListRowFrame 스코프로 걷는다(spec-cleanup-pending). `DevicesScreen` 의 같은 모양(비공개)과 짝이다.
class ListBleedTarget extends SingleChildRenderObjectWidget {
  const ListBleedTarget({super.key, required this.bleed, required super.child});

  final double bleed;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderListBleedTarget(bleed);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderProxyBox renderObject,
  ) {
    (renderObject as _RenderListBleedTarget).bleed = bleed;
  }
}

class _RenderListBleedTarget extends RenderProxyBox
    implements PTouchExtendable {
  _RenderListBleedTarget(this.bleed);

  double bleed;

  @override
  Rect get touchArea {
    final dy = math.max(0.0, (PTouch.min - size.height) / 2);
    // 보이는 상자(bleed 오른쪽)에서 모자란 만큼만 — 왼쪽은 보이는 버튼 왼쪽에서 시작한다
    return Rect.fromLTRB(bleed, -dy, size.width + bleed, size.height + dy);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) context.paintChild(child!, offset + Offset(bleed, 0));
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!touchArea.contains(position)) return false;
    // 보이는 상자는 레이아웃 상자보다 bleed 오른쪽 — 밖의 점은 상자 가운데를 누른 것으로 친다
    final visible = Rect.fromLTWH(bleed, 0, size.width, size.height);
    final inside = visible.contains(position) ? position : visible.center;
    final hit = result.addWithPaintOffset(
      offset: Offset(bleed, 0),
      position: inside,
      hitTest: (r, p) => child?.hitTest(r, position: p) ?? false,
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(bleed, 0, 0, 1);
  }
}
