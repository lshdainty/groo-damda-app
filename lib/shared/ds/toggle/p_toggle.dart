import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

/// 톤 — defaultTone(흰 표면 · 카드 · 시트 위, 기본) · inverted(브랜드 채움 위 — 순자산 카드. 켬 · 끔 모두 흰 아이콘).
enum PToggleTone { defaultTone, inverted }

/// 아이콘 선 굵기 — 끔 2(lucide 기본), 켬 2.5(v106 — 켜짐 · 선택은 선 2.5). lucide_icons_flutter 는 굵기마다 글꼴이
/// 따로 있다(`LucideIcons.eye` = Lucide · 2, `LucideIcons.eye500` = Lucide500 · 2.5). IconData 를 코드에서 만들면 릴리스
/// 빌드의 아이콘 글꼴 줄이기가 막히므로(상수여야 한다) 굵기를 바꾸지 않고, 켬의 아이콘으로 500 짝을 받는다.
@visibleForTesting
const Set<String> toggleOffFonts = {'Lucide', 'Lucide400'};
@visibleForTesting
const String toggleOnFont = 'Lucide500';

/// Toggle — 켜고 끄는 아이콘 단추. 단추 하나가 상태 하나를 켜고 끈다(관심 등록 · 메모 고정 · 금액 가리기 · App Key 보기).
/// 수치 원본은 groo-design `specs/components/toggle.yaml`(값은 `test/fixtures/design_spec/toggle.json` — 테스트가
/// 위젯이 그 값과 같은지 본다). 웹(desk-front `src/shared/ds/toggle`)과 같은 값이다.
///
/// 이름은 고정이고 켬은 읽는 상태(toggled)가 알린다(웹 aria-pressed) — 상태마다 [semanticLabel] 을 바꾸지 않는다.
/// 아이콘은 지금 상태를 그린다: 기능 단추(눈 · 종)는 lucide 의 -off 짝(눈은 지금 상태 — 가림 끔 `eyeOff` → 보임 켬 `eye500`), 모으기 단추(관심 · 고정)는
/// 사선 없이 같은 아이콘(`star` → `star500`)이다. 켬의 아이콘은 선 2.5 짝(500)을 준다. 켬 · 끔은 아이콘만 바뀐다 — 켬은 진한 색
/// (fg-neutral) + 선 2.5, 끔은 흐린 색(fg-neutral-muted) + 선 2. 바탕은 켬 · 끔에 따라 바뀌지 않는다(옅은 바탕 · 반전은
/// 고르지 않았다). 아이콘의 크기(20) · 색은 단추가 건다.
///
/// 크기는 하나 — 보이는 40 · 누르는 44 · 아이콘 20 · 모서리 8(Button medium 아이콘 단추와 같은 상자). 누르는 동안(올림은
/// 앱에 없다) 바탕 bg-layer-default-pressed 가 150ms 로 나타나고 단추 전체가 2px 거리 준다(기준 40 — 모션 줄이기면 줄지
/// 않는다). 켬 · 끔은 손을 뗄 때 바로 바뀌고 [onChanged] 를 부른다 — 요청을 기다리지 않고 단추를 막지 않는다(실패하면
/// 부르는 쪽이 되돌린다). 막힘은 [onChanged] 가 없을 때 — 아이콘만 fg-disabled 이고 켬의 선 2.5 는 그대로 둔다. 포커스
/// 링은 웹 상태라 앱에는 없다(키보드 포커스는 받는다 — Space · Enter 로 누른다).
///
/// 브랜드 채움 위([PToggleTone.inverted] — 순자산 카드)는 켬 · 끔 모두 흰 아이콘이고 모양 · 굵기로 가른다. 누름 색 짝이 없어
/// 바탕을 칠하지 않고 축소만 한다. 상단 바 안에서는 Top Navigation 의 아이콘 버튼을 쓴다(끔도 fg-neutral).
class PToggle extends StatelessWidget {
  const PToggle({
    super.key,
    required this.semanticLabel,
    required this.pressed,
    required this.onChanged,
    required this.icon,
    required this.pressedIcon,
    this.tone = PToggleTone.defaultTone,
    this.pressFill = true,
  });

  /// 고정 이름 — 켜고 끄는 것 하나("관심 등록" · "금액 가리기"). 상태마다 바꾸지 않는다.
  final String semanticLabel;

  /// 켬.
  final bool pressed;

  /// 눌러 바뀐 값 — 손을 뗄 때 바로. 없으면 비활성.
  final ValueChanged<bool>? onChanged;

  /// 끔일 때의 아이콘(lucide, 선 2 — 눈은 가림이라 `LucideIcons.eyeOff`) — 지금 상태를 그린다.
  final IconData icon;

  /// 켬일 때의 아이콘(선 2.5 짝 — 눈은 보임이라 `LucideIcons.eye500`). 기능 단추(눈 · 종)는 상태를 그리는 짝이고, 모으기 단추(관심 · 고정)는
  /// 사선 없이 같은 아이콘의 500 이다(`LucideIcons.star500`).
  final IconData pressedIcon;
  final PToggleTone tone;

  /// 누르는 동안 바탕을 칠하는가 — 기본 true. 입력 칸 안 뒤 단추 자리([PInput.trailing])에서는 지우기 버튼처럼 상자를 하나 더
  /// 그리지 않는다(false) — 눌림은 축소만, 상태는 아이콘으로만 말한다.
  final bool pressFill;

  /// 보이는 상자 · 아이콘 — 누르는 영역은 44([PTouch.min]).
  static const double box = 40;
  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    assert(
      pressedIcon.fontFamily == toggleOnFont,
      '켬의 아이콘은 선 2.5 짝을 준다 — LucideIcons.eyeOff500 처럼(굵기는 단추가 정하는 값이라 글꼴로만 받는다)',
    );
    assert(
      toggleOffFonts.contains(icon.fontFamily),
      '끔의 아이콘은 선 2 — LucideIcons.eye 처럼 기본 굵기를 준다',
    );
    final c = context.colors;
    final enabled = onChanged != null;
    final inverted = tone == PToggleTone.inverted;
    final foreground = !enabled
        ? c.fgDisabled
        : inverted
        ? c.staticWhite
        : (pressed ? c.fgNeutral : c.fgNeutralMuted);
    final glyph = pressed ? pressedIcon : icon;
    return PressArea(
      enabled: enabled,
      // 키보드 링 — 모서리 8, inverted(브랜드 채움 위)는 흰색(toggle.yaml focusRing)
      focusRing: PFocusRingStyle(
        radius: PRounded.r2,
        color: inverted ? c.staticWhite : null,
      ),
      onTap: enabled ? () => onChanged!(!pressed) : null,
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        toggled: pressed,
        label: semanticLabel,
        onTap: onTap,
        child: child,
      ),
      builder: (context, isPressed, pressSize) {
        // 누름 바탕 — 브랜드 채움 위에는 누름 색 짝이 없어 칠하지 않는다
        final background = isPressed && !inverted && pressFill
            ? c.bgLayerDefaultPressed
            : const Color(0x00000000);
        return PressScale(
          pressed: isPressed,
          size: const Size.square(box),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: background),
            duration: PDuration.colorTransition,
            curve: PEasing.easing,
            builder: (context, color, child) => DecoratedBox(
              key: const ValueKey('toggle-box'),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(PRounded.r2),
              ),
              child: child,
            ),
            child: SizedBox.square(
              dimension: box,
              child: Center(
                // 아이콘 · 굵기 · 색은 바로 바뀐다(전환 없음)
                child: ExcludeSemantics(
                  child: Icon(
                    glyph,
                    key: const ValueKey('toggle-icon'),
                    size: iconSize,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
