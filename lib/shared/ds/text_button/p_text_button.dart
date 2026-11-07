import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

/// 글 버튼(SEED Text Button) — 카드 머리 "전체 보기" · 모두 펼치기 · 결과 둘째 버튼 · 목록 제목 동작의 모양.
/// 수치 원본은 card.yaml `headerAction`(2026-10-16 사용자 결정, 글자 역할 D2): 보이는 상자 높이 36 · 좌우 14 · 모서리 8,
/// 글 14/19 · 700 · `fg-neutral-muted`, 아이콘 · 꺾쇠 없음. 누르는 영역은 위아래로 넓혀 44(보이는 자리는 그대로)이고,
/// 누르면 바탕 `bg-layer-default-pressed` + 2px 거리 축소다. 이름은 [semanticLabel] (없으면 글 그대로).
///
/// [bleedEnd] 면 줄 끝에서 오른쪽 14 만큼 바깥으로 내어 글자 끝이 부모 여백에 선다(머리 줄의 오른쪽 끝).
class PTextButton extends StatefulWidget {
  const PTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.bleedEnd = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool bleedEnd;

  @override
  State<PTextButton> createState() => _PTextButtonState();
}

/// 보이는 상자 높이 · 좌우 여백.
const double kTextButtonHeight = 36;
const double kTextButtonPaddingX = PSpacing.x3_5;

class _PTextButtonState extends State<PTextButton> {
  bool _pressed = false;
  bool _ringVisible = false;
  bool _focused = false;
  double _basis = 24;

  @override
  void initState() {
    super.initState();
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

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) _basis = cardPressBasis(size);
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final active = widget.onPressed != null;
    final box = TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: _pressed
            ? c.bgLayerDefaultPressed
            : c.bgLayerDefaultPressed.withValues(alpha: 0),
      ),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, background, child) => Container(
        key: const ValueKey('text-button-box'),
        height: kTextButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: kTextButtonPaddingX),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(PRounded.r2),
        ),
        child: child,
      ),
      child: Text(
        widget.label,
        key: const ValueKey('text-button-label'),
        maxLines: 1,
        softWrap: false,
        style: PTypography.t4.copyWith(
          color: active ? c.fgNeutralMuted : c.fgDisabled,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final button = PTouchTarget(
      minSize: PTouch.min,
      child: Semantics(
        container: true,
        button: true,
        enabled: active,
        label: widget.semanticLabel ?? widget.label,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: active ? (_) => _setPressed(true) : null,
          onTapUp: active ? (_) => _setPressed(false) : null,
          onTapCancel: active ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          excludeFromSemantics: true,
          // Tab 으로 초점을 받고 Space · Enter 로 누른다 — 링은 키보드로 올 때만(터치는 그리지 않는다)
          child: CallbackShortcuts(
            bindings: {
              if (active) ...{
                const SingleActivator(LogicalKeyboardKey.space):
                    widget.onPressed!,
                const SingleActivator(LogicalKeyboardKey.enter):
                    widget.onPressed!,
                const SingleActivator(LogicalKeyboardKey.numpadEnter):
                    widget.onPressed!,
              },
            },
            child: Focus(
              canRequestFocus: active,
              onFocusChange: (focused) {
                _focused = focused;
                final next = focused && keyboardHighlight();
                if (next != _ringVisible) setState(() => _ringVisible = next);
              },
              child: MouseRegion(
                cursor: active
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.forbidden,
                child: PFocusRing(
                  visible: _ringVisible && active,
                  style: const PFocusRingStyle(radius: PRounded.r2),
                  child: AnimatedScale(
                    key: const ValueKey('text-button-scale'),
                    scale: _pressed && !reduceMotion
                        ? (_basis - 2) / _basis
                        : 1,
                    duration: PDuration.pressedScale,
                    curve: PEasing.pressedScale,
                    child: box,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return widget.bleedEnd
        ? Transform.translate(
            offset: const Offset(kTextButtonPaddingX, 0),
            child: button,
          )
        : button;
  }
}
