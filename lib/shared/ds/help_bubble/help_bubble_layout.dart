import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// 말풍선을 트리거 옆에 놓는 계산과 그리기 — Help Bubble(p_help_bubble.dart)이 쓴다. 웹은 Radix Popper(floating-ui)가
// 같은 일을 한다: 기본 자리에 놓고, 화면 가장자리 16 을 넘으면 반대편으로 뒤집고, 옆으로 밀고, 화살표는 늘 트리거 가운데를
// 가리키고(비키지 않는다) 말풍선 모서리와 14 를 남긴다. 값은 help-bubble.yaml(root.offset · root.margin · root.maxWidth · arrow.*)이다.

/// 말풍선이 트리거의 어느 쪽에 뜨나 — 기본은 [top]. 웹 Radix 의 side 와 같다.
enum PHelpBubbleSide { top, bottom, left, right }

/// 화살표 끝 ↔ 트리거(root.offset).
const double helpBubbleOffset = 4;

/// 화면(오버레이) 가장자리와 남기는 간격(root.margin).
const double helpBubbleMargin = 16;

/// 말풍선 최대 폭 — 여백 포함(root.maxWidth). 쓸 수 있는 폭(화면 − 양쪽 16)이 더 좁으면 그만큼.
const double helpBubbleMaxWidth = 280;

/// 화살표 폭 · 높이(arrow.width · arrow.height) — 높이는 말풍선 몸통 밖으로 나온 길이다.
const double helpBubbleArrowWidth = 12;
const double helpBubbleArrowHeight = 8;

/// 화살표와 말풍선 모서리 사이의 최소 간격(arrow.margin).
const double helpBubbleArrowMargin = 14;

/// 화살표 가운데 ↔ 몸통 끝 — 화살표 모서리 14 + 화살표 반 폭 6.
const double arrowEdge = helpBubbleArrowMargin + helpBubbleArrowWidth / 2;

PHelpBubbleSide _opposite(PHelpBubbleSide side) => switch (side) {
  PHelpBubbleSide.top => PHelpBubbleSide.bottom,
  PHelpBubbleSide.bottom => PHelpBubbleSide.top,
  PHelpBubbleSide.left => PHelpBubbleSide.right,
  PHelpBubbleSide.right => PHelpBubbleSide.left,
};

bool _vertical(PHelpBubbleSide side) =>
    side == PHelpBubbleSide.top || side == PHelpBubbleSide.bottom;

/// 말풍선이 비켜야 할 안전 영역 — 말풍선이 그려지는 오버레이(대개 앱 전체 화면)의 상태 표시줄 · 홈 표시줄 · 화면 키보드.
/// [context] 는 OverlayPortal 의 overlayChildBuilder 것이다. 그 자리의 MediaQuery 는 트리거 쪽에서 물려받아 Scaffold 가 위 ·
/// 아래 여백을 지워 두었을 수 있으므로 오버레이 쪽 값을 읽는다(의존은 걸지 않는다 — 트리거가 움직일 때마다 빌더가 다시 돈다).
EdgeInsets helpBubbleSafeArea(BuildContext context) {
  final overlay = Overlay.maybeOf(context)?.context;
  final data =
      overlay?.getInheritedWidgetOfExactType<MediaQuery>()?.data ??
      MediaQuery.maybeOf(context);
  if (data == null) return EdgeInsets.zero;
  return data.padding + data.viewInsets;
}

/// 말풍선을 놓은 결과 — 몸통 · 화살표 상자 · 화살표 끝. 좌표는 오버레이 안이다.
@immutable
class HelpBubblePlacement {
  const HelpBubblePlacement({
    required this.side,
    required this.body,
    required this.arrow,
    required this.tip,
    required this.arrowOffset,
  });

  /// 실제로 뜬 쪽 — 자리가 모자라면 기본의 반대편이다.
  final PHelpBubbleSide side;

  /// 말풍선 몸통(화살표 제외).
  final Rect body;

  /// 화살표 상자 — 12 × 8(위 · 아래) 또는 8 × 12(옆), 몸통 가장자리에 붙는다.
  final Rect arrow;

  /// 화살표 끝 — 트리거 쪽을 가리키는 점. 트리거와 [helpBubbleOffset] 떨어진다.
  final Offset tip;

  /// 화살표 상자가 몸통 모서리에서 떨어진 거리(가로면 왼쪽, 세로면 위에서).
  final double arrowOffset;
}

/// 말풍선 몸통 크기 [bubble] 을 트리거 [target] 의 [preferred] 쪽에 놓는다 — [viewport] 는 오버레이 크기, [safeArea] 는
/// 그 안에서 비켜야 할 안전 영역(상태 표시줄 · 홈 표시줄 · 화면 키보드)이다. 가장자리 16 은 안전 영역 경계부터 잰다.
///
/// 1. 몸통은 트리거에서 화살표 높이 + 4 = 12 떨어진 곳에 놓는다(화살표 끝이 트리거와 4).
/// 2. 그 쪽에 가장자리 16 을 남기고 들어가지 않으면 반대편으로 뒤집는다. 양쪽 다 안 들어가면 넘침이 적은 쪽 — 곧 남는
///    공간이 넓은 쪽(floating-ui bestFit).
/// 2-1. 고른 쪽에도 다 들지 않으면(큰 글자) 몸통 높이를 그 쪽에 남는 공간까지로 줄인다 — 화면 밖으로 넘치지 않고 글은 말풍선
///    안에서 스크롤한다(Popover 의 "가용 높이까지 — 넘치면 본문 스크롤" 과 같은 길, WCAG 1.4.4 — 글이 잘리지 않는다). 옆
///    말풍선은 화면 높이 − 위아래 16 까지다.
/// 3. 화살표는 늘 트리거 가운데를 가리키고 몸통 모서리와 14 를 남긴다(화살표 가운데가 몸통 끝에서 20 안쪽).
/// 4. 트리거 가운데에 맞춰 놓고 가장자리 16 안으로 옆으로 민다. 16 은 지는 값이다 — 트리거 가운데가 끝에서 20 안쪽이면 그만큼
///    남기고 0 까지 붙는다(root.marginMin 0). 말풍선이 화면보다 넓으면 왼쪽 가장자리에 맞춘다.
HelpBubblePlacement placeHelpBubble({
  required Rect target,
  required Size bubble,
  required Size viewport,
  PHelpBubbleSide preferred = PHelpBubbleSide.top,
  EdgeInsets safeArea = EdgeInsets.zero,
}) {
  const gap = helpBubbleOffset + helpBubbleArrowHeight;
  // 놓을 수 있는 곳 — 오버레이에서 안전 영역을 뺀 사각형
  final bounds = Rect.fromLTRB(
    safeArea.left,
    safeArea.top,
    viewport.width - safeArea.right,
    viewport.height - safeArea.bottom,
  );
  // 그 쪽에 가장자리 16 을 남기고 몸통이 쓸 수 있는 길이(위 · 아래는 높이, 옆은 폭)
  double space(PHelpBubbleSide side) => switch (side) {
    PHelpBubbleSide.top => target.top - gap - (bounds.top + helpBubbleMargin),
    PHelpBubbleSide.bottom =>
      bounds.bottom - helpBubbleMargin - target.bottom - gap,
    PHelpBubbleSide.left =>
      target.left - gap - (bounds.left + helpBubbleMargin),
    PHelpBubbleSide.right =>
      bounds.right - helpBubbleMargin - target.right - gap,
  };
  // 그 쪽으로 놓았을 때 가장자리 16 밖으로 나가는 길이 — 0 이하면 들어간다
  double overflow(PHelpBubbleSide side) =>
      (_vertical(side) ? bubble.height : bubble.width) - space(side);
  final other = _opposite(preferred);
  final side = overflow(preferred) <= 0
      ? preferred
      : overflow(other) <= 0
      ? other
      : (overflow(other) < overflow(preferred) ? other : preferred);
  // 몸통 높이 — 고른 쪽에 남는 공간까지(넘치면 말풍선 안에서 스크롤)
  final height = math.max(
    0.0,
    math.min(
      bubble.height,
      _vertical(side) ? space(side) : bounds.height - 2 * helpBubbleMargin,
    ),
  );

  // 옆으로 미는 쪽(가로 말풍선은 x, 세로 말풍선은 y)의 시작 — 트리거 가운데에 맞춰 놓고 가장자리 안으로 민다. 가장자리 16 은
  // 지는 값이다(root.marginMin 0): 트리거 가운데가 끝에서 20 안쪽이면 그만큼만 남기고 0 까지 붙는다. 화살표는 그대로 트리거
  // 가운데를 가리키고, 말풍선만 밀린다(Q-004).
  double slide(double center, double length, double from, double to) {
    final lo =
        from +
        math.max(0.0, math.min(helpBubbleMargin, center - from - arrowEdge));
    final hi =
        to -
        math.max(0.0, math.min(helpBubbleMargin, to - center - arrowEdge)) -
        length;
    final start = hi < lo ? lo : (center - length / 2).clamp(lo, hi);
    // 화살표 가운데가 몸통 끝에서 20 안쪽에 남게(작은 몸통이면 그 반까지)
    final m = math.min(arrowEdge, length / 2);
    return start.clamp(center - length + m, center - m).toDouble();
  }

  final vertical = _vertical(side);
  final x = vertical
      ? slide(target.center.dx, bubble.width, bounds.left, bounds.right)
      : (side == PHelpBubbleSide.left
            ? target.left - gap - bubble.width
            : target.right + gap);
  final y = vertical
      ? (side == PHelpBubbleSide.top
            ? target.top - gap - height
            : target.bottom + gap)
      : slide(target.center.dy, height, bounds.top, bounds.bottom);
  final body = Rect.fromLTWH(x, y, bubble.width, height);

  // 화살표 — 늘 트리거 가운데를 가리킨다(비키지도 지우지도 않는다). 말풍선이 밀려 몸통 끝에서 20 안쪽을 지키므로 clamp 가 없다
  final center = vertical
      ? target.center.dx - body.left
      : target.center.dy - body.top;
  final arrowOffset = center - helpBubbleArrowWidth / 2;
  final arrow = switch (side) {
    PHelpBubbleSide.top => Rect.fromLTWH(
      body.left + arrowOffset,
      body.bottom,
      helpBubbleArrowWidth,
      helpBubbleArrowHeight,
    ),
    PHelpBubbleSide.bottom => Rect.fromLTWH(
      body.left + arrowOffset,
      body.top - helpBubbleArrowHeight,
      helpBubbleArrowWidth,
      helpBubbleArrowHeight,
    ),
    PHelpBubbleSide.left => Rect.fromLTWH(
      body.right,
      body.top + arrowOffset,
      helpBubbleArrowHeight,
      helpBubbleArrowWidth,
    ),
    PHelpBubbleSide.right => Rect.fromLTWH(
      body.left - helpBubbleArrowHeight,
      body.top + arrowOffset,
      helpBubbleArrowHeight,
      helpBubbleArrowWidth,
    ),
  };
  final tip = switch (side) {
    PHelpBubbleSide.top => Offset(arrow.center.dx, arrow.bottom),
    PHelpBubbleSide.bottom => Offset(arrow.center.dx, arrow.top),
    PHelpBubbleSide.left => Offset(arrow.right, arrow.center.dy),
    PHelpBubbleSide.right => Offset(arrow.left, arrow.center.dy),
  };
  return HelpBubblePlacement(
    side: side,
    body: body,
    arrow: arrow,
    tip: tip,
    arrowOffset: arrowOffset.toDouble(),
  );
}

/// 화살표 그림 — SVG `M0,0 H12 L8,6 Q6,8 4,6 Z`(12 × 8, 끝 모서리 2)를 [placement] 쪽에 맞춰 돌렸다. 밑변이 몸통에 붙고
/// 끝이 트리거를 향한다. 몸통과의 이음매가 비치지 않게 밑변을 몸통 안으로 0.5 겹친다(같은 색이라 보이지 않는다).
Path helpBubbleArrowPath(HelpBubblePlacement placement) {
  final a = placement.arrow;
  // (x, y): x 는 밑변을 따라 0 ~ 12, y 는 몸통에서 바깥으로 0 ~ 8
  Offset at(double x, double y) => switch (placement.side) {
    PHelpBubbleSide.top => Offset(a.left + x, a.top + y),
    PHelpBubbleSide.bottom => Offset(a.left + x, a.bottom - y),
    PHelpBubbleSide.left => Offset(a.left + y, a.top + x),
    PHelpBubbleSide.right => Offset(a.right - y, a.top + x),
  };
  final path = Path()
    ..moveTo(at(0, 0).dx, at(0, 0).dy)
    ..lineTo(at(12, 0).dx, at(12, 0).dy)
    ..lineTo(at(8, 6).dx, at(8, 6).dy)
    ..quadraticBezierTo(at(6, 8).dx, at(6, 8).dy, at(4, 6).dx, at(4, 6).dy)
    ..close()
    ..addPolygon([at(0, -0.5), at(12, -0.5), at(12, 0), at(0, 0)], true);
  return path;
}

/// 그릴 때의 모습 — 열림(scale 0.9 → 1 · opacity 0 → 1)과 닫힘(opacity → 0)이 정한다. 화살표 끝을 기준점으로 커진다.
typedef HelpBubbleLook = ({double opacity, double scale});

/// 말풍선 몸통을 [target] 옆에 놓고 화살표를 그린다 — 오버레이 전체를 채우되 몸통만 눌린다(뒤 화면은 그대로 눌린다 —
/// 비모달).
@visibleForTesting
class HelpBubbleLayout extends SingleChildRenderObjectWidget {
  const HelpBubbleLayout({
    super.key,
    required this.target,
    required this.side,
    required this.arrowColor,
    required this.look,
    required this.repaint,
    this.safeArea = EdgeInsets.zero,
    required Widget child,
  }) : super(child: child);

  /// 트리거(또는 기준)의 자리 — 오버레이 좌표.
  final Rect target;
  final PHelpBubbleSide side;
  final Color arrowColor;
  final ValueGetter<HelpBubbleLook> look;

  /// 오버레이 안에서 비켜야 할 안전 영역 — 상태 표시줄 · 홈 표시줄 · 화면 키보드. 가장자리 16 은 이 경계부터 잰다.
  final EdgeInsets safeArea;

  /// [look] 이 바뀌는 때 — 다시 그린다.
  final Listenable repaint;

  @override
  RenderHelpBubbleLayout createRenderObject(BuildContext context) =>
      RenderHelpBubbleLayout(
        target: target,
        side: side,
        arrowColor: arrowColor,
        look: look,
        repaint: repaint,
        safeArea: safeArea,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderHelpBubbleLayout renderObject,
  ) {
    renderObject
      ..target = target
      ..side = side
      ..arrowColor = arrowColor
      ..look = look
      ..repaint = repaint
      ..safeArea = safeArea;
  }
}

@visibleForTesting
class RenderHelpBubbleLayout extends RenderShiftedBox {
  RenderHelpBubbleLayout({
    required Rect target,
    required PHelpBubbleSide side,
    required Color arrowColor,
    required this.look,
    required Listenable repaint,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) : _target = target,
       _side = side,
       _arrowColor = arrowColor,
       _repaint = repaint,
       _safeArea = safeArea,
       super(null);

  ValueGetter<HelpBubbleLook> look;

  Rect _target;
  Rect get target => _target;
  set target(Rect value) {
    if (value == _target) return;
    _target = value;
    markNeedsLayout();
  }

  PHelpBubbleSide _side;
  set side(PHelpBubbleSide value) {
    if (value == _side) return;
    _side = value;
    markNeedsLayout();
  }

  EdgeInsets _safeArea;
  set safeArea(EdgeInsets value) {
    if (value == _safeArea) return;
    _safeArea = value;
    markNeedsLayout();
  }

  Color _arrowColor;
  set arrowColor(Color value) {
    if (value == _arrowColor) return;
    _arrowColor = value;
    markNeedsPaint();
  }

  Listenable _repaint;
  set repaint(Listenable value) {
    if (value == _repaint) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint.addListener(markNeedsPaint);
  }

  /// 놓은 결과 — 테스트가 몸통 · 화살표 자리를 읽는다.
  HelpBubblePlacement get placement => _placement!;
  HelpBubblePlacement? _placement;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    // 최대 폭 280 — 쓸 수 있는 폭이 더 좁으면 그만큼. 위 · 아래는 화면(안전 영역 안) − 양쪽 16, 옆은 트리거 옆의 넓은 쪽
    const gap = helpBubbleOffset + helpBubbleArrowHeight;
    final left = _safeArea.left;
    final right = size.width - _safeArea.right;
    final available =
        (_side == PHelpBubbleSide.top || _side == PHelpBubbleSide.bottom)
        ? right - left - 2 * helpBubbleMargin
        : math.max(_target.left - left, right - _target.right) -
              gap -
              helpBubbleMargin;
    final maxWidth = math.max(0.0, math.min(helpBubbleMaxWidth, available));
    // 먼저 내용만큼 재어 놓을 쪽을 고르고, 그 쪽에 남는 공간보다 크면 그 높이로 다시 잰다 — 넘친 글은 몸통 안에서 스크롤한다
    child.layout(BoxConstraints(maxWidth: maxWidth), parentUsesSize: true);
    _placement = placeHelpBubble(
      target: _target,
      bubble: child.size,
      viewport: size,
      preferred: _side,
      safeArea: _safeArea,
    );
    if (_placement!.body.height < child.size.height) {
      child.layout(
        BoxConstraints(maxWidth: maxWidth, maxHeight: _placement!.body.height),
        parentUsesSize: true,
      );
    }
    (child.parentData! as BoxParentData).offset = _placement!.body.topLeft;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    final placement = _placement;
    if (child == null || placement == null) return;
    final l = look();
    if (l.opacity <= 0) return;
    void paintBubble(PaintingContext ctx, Offset at) {
      ctx.canvas.drawPath(
        helpBubbleArrowPath(placement).shift(at),
        Paint()
          ..color = _arrowColor
          ..isAntiAlias = true,
      );
      ctx.paintChild(child, at + placement.body.topLeft);
    }

    void scaled(PaintingContext ctx, Offset at) {
      if (l.scale == 1) {
        paintBubble(ctx, at);
        return;
      }
      // 화살표 끝을 기준점으로
      final tip = placement.tip;
      final matrix = Matrix4.identity()
        ..translateByDouble(tip.dx, tip.dy, 0, 1)
        ..scaleByDouble(l.scale, l.scale, 1, 1)
        ..translateByDouble(-tip.dx, -tip.dy, 0, 1);
      ctx.pushTransform(needsCompositing, at, matrix, paintBubble);
    }

    if (l.opacity >= 1) {
      scaled(context, offset);
    } else {
      context.pushOpacity(offset, (l.opacity * 255).round(), scaled);
    }
  }

  @override
  bool hitTestSelf(Offset position) => false;
}
