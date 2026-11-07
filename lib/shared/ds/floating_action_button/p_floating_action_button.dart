import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

/// 원 지름 — 아이콘만(SEED extended=false). 누르는 영역도 56.
const double kFabSize = PSpacing.x14;

/// 아이콘 크기.
const double kFabIcon = PSpacing.x6;

/// 화면 끝 · 아래(또는 아래 고정 요소 위)에서의 거리 — 안전 영역 경계부터 잰다.
const double kFabMargin = PSpacing.x5;

/// 화면 키보드가 이만큼 올라오면 버튼을 가린다.
const double kFabKeyboardGap = 150;

/// 떠 있는 버튼 — 화면 위에 떠 있는 그 화면의 주 동작 하나. 오른쪽 아래의 브랜드 원 56 에 흰 아이콘 24. 구조는 SEED Floating
/// Action Button(아이콘만 · extended=false, 2026-10-04), 수치 원본은 groo-design
/// `specs/components/floating-action-button.yaml`(값은 `test/fixtures/design_spec/floating-action-button.json`).
/// 웹(desk-front `src/shared/ds/floating-action-button`)과 같은 값이다.
///
/// 폰의 탭 바가 없는 화면(할 일 · 더치페이)에만 둔다 — 탭 바가 있는 화면의 추가는 Bottom Navigation 가운데 + 가 한다. 화면에
/// 하나만, 글이 붙은 모양(Extended) · 스크롤에 따라 접기는 없다(늘 아이콘만 56).
///
/// 자리는 스스로 잡는다 — 부모의 넓이를 채우고(`Stack` 의 자식 · 본문 위) 오른쪽 아래에 앉는다. 화면 끝에서 20 + 오른쪽 안전
/// 영역, 아래 끝(또는 바닥 고정 요소 위 끝 — [offsetBottom])에서 20 + 아래 안전 영역. 빈 곳은 누름을 통과시킨다. 스크롤해도 그 자리
/// 에 있고 숨거나 접히지 않는다 — 목록 아래에 버튼 높이만큼(56 + 20 + 20) 여백을 두는 것은 쓰는 쪽이다. 화면 키보드가 올라오면 가린다.
///
/// 모양 — bg-brand-solid(바꾸지 않는다) · 흰 아이콘(선 2.5) · shadow-s3. 누르면 bg-brand-solid-pressed + 2px 거리 축소(기준 56).
/// 스낵바는 버튼 위 8 에 뜬다([PSnackbarAvoidOverlap] 로 감쌌다). [label] 은 보이는 글이 없으니 이름이 곧 버튼의 글이다 — 동작
/// 이름("할 일 추가" · "더치페이 만들기"), "추가" · "+" 처럼 뜻이 모호한 이름은 쓰지 않는다.
class PFloatingActionButton extends StatelessWidget {
  const PFloatingActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.offsetBottom = 0,
  });

  /// 선 2.5 판 lucide 아이콘(`LucideIcons.plus500` · `userPlus500`) — 채운 원 위의 흰 아이콘은 선 2.5 다. 글꼴을 코드로 만들면
  /// 릴리스 빌드의 아이콘 트리 셰이킹이 막혀 상수로 받는다.
  final IconData icon;

  /// 동작 이름 — 읽는 말.
  final String label;
  final VoidCallback? onPressed;

  /// 아래에 고정된 것(바닥 버튼)의 높이 — 안전 영역 위에 놓인 높이(안전 영역은 빼고). 버튼은 그 위 끝에서 20 에 선다.
  final double offsetBottom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    final safe = media.padding;
    final reduce = media.disableAnimations;
    final keyboardOpen = media.viewInsets.bottom > kFabKeyboardGap;

    final button = PressArea(
      enabled: onPressed != null,
      onTap: onPressed,
      // 원 56 이 곧 누르는 영역이다
      touchMin: 0,
      focusRing: const PFocusRingStyle(circle: true),
      semantics: (child, enabled, onTap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: label,
        onTap: onTap,
        child: child,
      ),
      builder: (context, pressed, size) => PressScale(
        pressed: pressed,
        size: size,
        child: AnimatedContainer(
          key: const ValueKey('floating-action-button'),
          duration: reduce ? Duration.zero : PDuration.colorTransition,
          curve: PEasing.easing,
          width: kFabSize,
          height: kFabSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? c.bgBrandSolidPressed : c.bgBrandSolid,
            shape: BoxShape.circle,
            boxShadow: context.shadows.s3,
          ),
          child: Icon(icon, size: kFabIcon, color: c.staticWhite),
        ),
      ),
    );

    return Visibility(
      visible: !keyboardOpen,
      maintainState: true,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(
            right: kFabMargin + safe.right,
            bottom: kFabMargin + safe.bottom + offsetBottom,
          ),
          child: PSnackbarAvoidOverlap(child: button),
        ),
      ),
    );
  }
}
