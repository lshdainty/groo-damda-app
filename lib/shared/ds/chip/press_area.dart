import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

// 칩 · 탭 · 토글이 함께 쓰는 부품 — 누르는 자리(누름 상태 · 키보드 · 누르는 영역 44)와 누름 축소. 화면에서 직접 쓰지
// 않는다 — PChip · PTabs · PToggle 이 쓴다.

/// 누르는 자리 — 누름 상태 · 포커스 · Space(와 [activateOnEnter] 면 Enter) · 누르는 영역을 맡는다.
///
///   누르기 — 손을 떼면 [onTap]. 누르는 동안 [builder] 의 pressed 가 true 다(비활성이면 늘 false).
///   누르는 영역 — 보이는 상자와 따로 [touchMin] 까지 넓힌다(웹 ::before — Button 과 같다). 놓인 자리는 그대로이고,
///     부모 상자 안에서만 받는다(Flutter 는 부모 안에서만 자식에게 묻는다). 0 이면 넓히지 않는다(탭은 탭 전체가 영역).
///   읽기 — [semantics] 가 역할 · 이름 · 상태를 단다. 포커스 링은 [focusRing] 을 주면 키보드로 초점이 올 때만 그린다.
///   [enabled] 가 false 면 누르기 · 키보드 · 포커스에서 빠진다(웹 진짜 disabled).
class PressArea extends StatefulWidget {
  const PressArea({
    super.key,
    required this.enabled,
    required this.onTap,
    required this.builder,
    required this.semantics,
    this.activateOnEnter = true,
    this.touchMin = PTouch.min,
    this.focusNode,
    this.skipTraversal = false,
    this.keyboard = true,
    this.focusRing,
  });

  final bool enabled;
  final VoidCallback? onTap;

  /// pressed — 누르는 동안(비활성이면 false). size — 누르는 순간 잰 크기(누름 축소의 기준 길이를 정한다).
  final Widget Function(BuildContext context, bool pressed, Size size) builder;

  /// 읽는 말 — [enabled] 와 [onTap] 을 받아 Semantics 로 감싼다.
  final Widget Function(Widget child, bool enabled, VoidCallback? onTap)
  semantics;

  /// Enter 로도 누른다 — 버튼 · 토글. 체크박스 칩은 Space 만(Enter 는 폼 제출에 둔다).
  final bool activateOnEnter;
  final double touchMin;
  final FocusNode? focusNode;

  /// Tab 순서에서 빠진다 — 탭 목록의 고르지 않은 탭(화살표로만 닿는다).
  final bool skipTraversal;

  /// false 면 Space · Enter 를 받지 않는다 — 라디오 묶음이 키를 맡는 칩.
  final bool keyboard;

  /// 키보드로 초점이 올 때 그릴 링(두께 2 · 띄움 2) — 없으면 그리지 않는다.
  final PFocusRingStyle? focusRing;

  @override
  State<PressArea> createState() => _PressAreaState();
}

class _PressAreaState extends State<PressArea> {
  bool _pressed = false;
  bool _ringVisible = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    // Tab 으로 초점이 온 뒤 손가락으로 바꾸면(또는 반대) 링도 입력 방식을 따라간다
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    final next = _focused && mode == FocusHighlightMode.traditional;
    if (mounted && next != _ringVisible) setState(() => _ringVisible = next);
  }

  /// 누르는 순간 잰 크기 — 눌린 동안 폭이 바뀌어도 배율은 그대로다(웹 --press-basis).
  Size _size = const Size(0, 24);

  @override
  void didUpdateWidget(PressArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 사이 막히면 누름이 남지 않게
    if (!widget.enabled) _pressed = false;
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    Widget body = Focus(
      focusNode: widget.focusNode,
      canRequestFocus: enabled,
      skipTraversal: widget.skipTraversal,
      onFocusChange: widget.focusRing == null
          ? null
          : (focused) {
              _focused = focused;
              final next = focused && keyboardHighlight();
              if (next != _ringVisible) setState(() => _ringVisible = next);
            },
      child: MouseRegion(
        // 웹 cursor pointer · not-allowed
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: enabled
              ? (_) {
                  _size = context.size ?? _size;
                  _setPressed(true);
                }
              : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: enabled ? _activate : null,
          child: PFocusRing(
            visible: _ringVisible && enabled && widget.focusRing != null,
            style: widget.focusRing ?? const PFocusRingStyle(),
            child: widget.builder(context, enabled && _pressed, _size),
          ),
        ),
      ),
    );
    if (enabled && widget.keyboard) {
      body = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _activate,
          if (widget.activateOnEnter) ...{
            const SingleActivator(LogicalKeyboardKey.enter): _activate,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): _activate,
          },
        },
        child: body,
      );
    }
    final semantic = widget.semantics(
      body,
      enabled,
      enabled ? _activate : null,
    );
    if (widget.touchMin <= 0) return semantic;
    // 누르는 영역을 맡는 상자가 가장 바깥이다 — 안쪽 상자는 제 크기 밖에서 누른 것을 받지 않는다
    return TouchTarget(minSize: widget.touchMin, child: semantic);
  }
}

/// 누르는 영역을 보이는 크기와 따로 [minSize] 까지 넓힌다 — 놓인 자리(레이아웃)는 그대로다. 넓힌 자리에서 누르면
/// 상자 가운데를 누른 것으로 친다(Button 의 누르는 영역과 같은 방법).
class TouchTarget extends SingleChildRenderObjectWidget {
  const TouchTarget({super.key, required this.minSize, required super.child});

  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderTouchTarget).minSize = minSize;
  }
}

class _RenderTouchTarget extends RenderProxyBox {
  _RenderTouchTarget(this.minSize);

  double minSize;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final dx = math.max(0.0, (minSize - size.width) / 2);
    final dy = math.max(0.0, (minSize - size.height) / 2);
    final area = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
    if (!area.contains(position)) return false;
    final inside = size.contains(position)
        ? position
        : size.center(Offset.zero);
    if (hitTestChildren(result, position: inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// 누름 축소 — 칸 전체를 세로 2px 거리 줄인다. 배율의 기준 길이는 누르는 순간 잰 [size] 에서 정한다(웹 --press-basis).
/// 모션 줄이기면 줄지 않는다. 놓인 자리는 그대로다.
class PressScale extends StatelessWidget {
  const PressScale({
    super.key,
    required this.pressed,
    required this.size,
    required this.child,
  });

  final bool pressed;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedScale(
      scale: pressed && !reduceMotion ? SelectionPressScale.scaleOf(size) : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: child,
    );
  }
}
