import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 키보드 포커스 링 — 두께 2 · 띄움 2 · `stroke-focus-ring`(DESIGN.desk.md State v106). 앱도 **키보드로 옮길 때만** 그린다
/// (사용자 결정 2026-10-08, E2) — 손가락으로 눌러 생긴 초점에는 링이 없다.
const double kFocusRingWidth = 2;
const double kFocusRingOffset = 2;

/// 지금 초점이 키보드로 온 것인가 — `FocusHighlightMode.traditional`.
bool keyboardHighlight() =>
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

/// 링의 모양 — 보이는 상자의 [radius](둥근 사각), [circle] 이면 원. [color] 가 없으면 `stroke-focus-ring`
/// (inverted 토글은 흰색).
@immutable
class PFocusRingStyle {
  const PFocusRingStyle({
    this.radius = 0,
    this.circle = false,
    this.color,
    this.inset = false,
  });

  final double radius;
  final bool circle;
  final Color? color;

  /// 상자 안쪽에 그린다(offset −2) — 화면 폭 줄 · 상단 바 단추처럼 바깥 링이 잘리는 자리(list.yaml focused,
  /// top-navigation.md). [radius] 는 상자의 모서리 그대로다.
  final bool inset;
}

/// [visible] 이면 [child] 둘레에 링을 그린다 — 자리를 차지하지 않는다(바깥으로 띄움 2 + 두께 2).
class PFocusRing extends StatelessWidget {
  const PFocusRing({
    super.key,
    required this.visible,
    required this.style,
    required this.child,
  });

  final bool visible;
  final PFocusRingStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    if (style.inset) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('focus-ring'),
                decoration: BoxDecoration(
                  shape: style.circle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: style.circle
                      ? null
                      : BorderRadius.circular(style.radius),
                  border: Border.all(
                    color: style.color ?? context.colors.strokeFocusRing,
                    width: kFocusRingWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    const out = kFocusRingOffset + kFocusRingWidth;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: -out,
          top: -out,
          right: -out,
          bottom: -out,
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('focus-ring'),
              decoration: BoxDecoration(
                shape: style.circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: style.circle
                    ? null
                    : BorderRadius.circular(style.radius + kFocusRingOffset),
                border: Border.all(
                  color: style.color ?? context.colors.strokeFocusRing,
                  width: kFocusRingWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
