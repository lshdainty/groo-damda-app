import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

/// 글 버튼(SEED Text Button) — 카드 머리 "전체 보기" · 모두 펼치기 · 결과 둘째 버튼 · 목록 제목 동작의 모양.
/// 수치 원본은 card.yaml `headerAction`(2026-10-16 사용자 결정, 글자 역할 D2): 보이는 상자 높이 36 · 좌우 14 · 모서리 8,
/// 글 14/19 · 700 · `fg-neutral-muted`, 아이콘 · 꺾쇠 없음. 누르는 영역은 위아래로 넓혀 44(보이는 자리는 그대로)이고,
/// 누르면 바탕 `bg-layer-default-pressed` + 2px 거리 축소다. 이름은 [semanticLabel] (없으면 글 그대로).
///
/// [loading] 이면 웹 Button ghost 로딩과 같다 — 바탕 `bg-layer-default-pressed` 를 깔고 글자는 투명하게(자리는 그대로, 이름은 계속 읽는다)
/// 그 위에 로딩 원(14 · 두께 2 · 트랙 gray-500 · 원 fg-neutral), 누르기는 삼키고 "불러오는 중" 을 알린다(aria-busy).
///
/// [bleedEnd] 면 줄 끝에서 오른쪽 14 만큼 바깥으로 내어 글자 끝이 부모 여백에 선다(머리 줄의 오른쪽 끝).
class PTextButton extends StatefulWidget {
  const PTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.bleedEnd = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool bleedEnd;

  /// 요청 중 — 누름을 막고 로딩 원을 그린다. 비활성(onPressed null)과 달리 글자색은 그대로다.
  final bool loading;

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
    final active = widget.onPressed != null && !widget.loading;
    final label = Text(
      widget.label,
      key: const ValueKey('text-button-label'),
      maxLines: 1,
      softWrap: false,
      style: PTypography.t4.copyWith(
        color: widget.onPressed != null ? c.fgNeutralMuted : c.fgDisabled,
        fontWeight: FontWeight.w700,
      ),
    );
    // 로딩 — 글자 자리는 그대로 두고(투명) 그 위에 원
    final labelStack = widget.loading
        ? Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0, child: label),
              PProgressCircle.inherit(
                diameter: 14,
                thickness: 2,
                trackColor: c.gray500,
                rangeColor: c.fgNeutral,
              ),
            ],
          )
        : label;
    final box = TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: _pressed || widget.loading
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
      child: labelStack,
    );
    final button = PTouchTarget(
      minSize: PTouch.min,
      child: Semantics(
        container: true,
        button: true,
        enabled: active,
        label: widget.semanticLabel ?? widget.label,
        value: widget.loading
            ? AppLocalizations.of(context).dsProgressCircleLabel
            : null,
        excludeSemantics: true,
        onTap: active ? widget.onPressed : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: active ? (_) => _setPressed(true) : null,
          onTapUp: active ? (_) => _setPressed(false) : null,
          onTapCancel: active ? () => _setPressed(false) : null,
          onTap: active ? widget.onPressed : null,
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
