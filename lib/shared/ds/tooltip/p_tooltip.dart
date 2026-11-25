import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/help_bubble_layout.dart';
import 'package:groo_damda_app/shared/ds/scroll_area/p_scroll_area.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

export 'package:groo_damda_app/shared/ds/help_bubble/help_bubble_layout.dart'
    show PHelpBubbleSide;

/// 마우스를 올린 뒤 열기까지 · 트리거와 말풍선을 모두 벗어난 뒤 닫기까지 · 닫힌 뒤 옆 트리거로 옮기면 바로 여는 시간
/// (help-bubble.yaml 의 `opens: hover` — openDelay · closeDelay · skipDelay).
const Duration kTooltipOpenDelay = Duration(milliseconds: 200);
const Duration kTooltipCloseDelay = Duration(milliseconds: 100);
const Duration kTooltipSkipDelay = Duration(milliseconds: 300);

/// 이어서 여는 툴팁이 기다리지 않게 — 웹 `TooltipProvider` 의 앱 판. 하나가 열려 있거나 닫힌 지 300ms 안이면 "따뜻하다".
abstract final class _TooltipGroup {
  static _PTooltipState? current;
  static Timer? _cooling;
  static bool _warm = false;

  static bool get warm => current != null || _warm;

  static void opened(_PTooltipState s) {
    current = s;
    _cooling?.cancel();
    _warm = true;
  }

  static void closed(_PTooltipState s) {
    if (current == s) current = null;
    _cooling?.cancel();
    _warm = true;
    _cooling = Timer(kTooltipSkipDelay, () {
      _warm = false;
      _cooling = null;
    });
  }

  /// 화면에 툴팁이 하나도 없으면 식힌다(테스트가 남긴 타이머 · 상태를 비운다).
  static void reset() {
    _cooling?.cancel();
    _cooling = null;
    _warm = false;
    current = null;
  }
}

/// 툴팁 그룹을 비운다 — 테스트용.
@visibleForTesting
void resetTooltipGroup() => _TooltipGroup.reset();

/// Tooltip — 마우스를 올리거나 키보드 초점이 오면 트리거 옆에 뜨는 짧은 설명. 구조는 SEED Help Bubble Tooltip(2026-10-02),
/// 수치 원본은 groo-design `specs/components/help-bubble.yaml` 의 `opens: hover`(값은
/// `test/fixtures/design_spec/help-bubble.json` — Help Bubble 과 한 파일, 툴팁 전용 JSON 은 없다).
///
/// 모양은 [PHelpBubble] 과 같다 — 위아래 10 · 좌우 12, 모서리 12, 글 13 / 18 · 굵게(제목 자리, 글 하나), 최대 280, 화살표
/// 12 × 8 이 늘 트리거 가운데를 가리키고 화살표 끝 ↔ 트리거 4, 화면 가장자리 16(모자라면 뒤집고 민다), 그림자 없음.
///
/// **보조다.** 손가락으로 누르면 열지 않는다(길게 눌러도 — 스펙에 없다). 그래서 이름 · 막힌 이유 · 꼭 알아야 하는 것은
/// 툴팁에만 두지 않는다 — 이름은 트리거의 `semanticLabel`(웹 aria-label)에 두고 툴팁은 그 이름을 마우스 · 키보드 사용자에게
/// **보여 주는** 것이다. 막힌 버튼은 초점을 받지 못해 툴팁을 열 수 없으므로 이유는 버튼 가까이 글로 둔다. 폰에서도 읽어야
/// 하는 설명은 [PHelpBubble](눌러서).
///
/// 여는 법 — 마우스를 올리면 [kTooltipOpenDelay] 뒤, 트리거와 말풍선을 모두 벗어나면 [kTooltipCloseDelay] 뒤 닫는다(말풍선 위로
/// 옮겨도 닫히지 않는다 — WCAG 1.4.13). 키보드 초점(Tab)이 오면 바로 열고 초점이 떠나면 닫는다 — 그동안 포인터가 지나가도
/// 닫지 않는다. Esc 는 닫고 초점은 트리거에 그대로. 트리거를 눌러도 열지도 닫지도 않는다(마우스로 기다리던 열기는
/// 거둔다). 하나가 열려 있거나 닫힌 지 [kTooltipSkipDelay] 안에 다른 툴팁으로 옮기면 기다리지 않고 모션 없이 바로 연다.
/// 스크롤하면 트리거를 따라간다.
///
/// 모션 — 열림 200ms 에 화살표 끝에서 0.9 → 1 · 투명도, 닫힘 200ms 에 투명도만(모션 줄이기면 크기는 그대로).
///
/// 읽기 — 트리거에 `tooltip`(웹 aria-describedby)을 달고 이름은 건드리지 않는다. 말풍선의 역할 tooltip 은 Flutter 3.44 가 달 수
/// 없게 막아 두어 글 하나의 묶음으로 읽는다.
class PTooltip extends StatefulWidget {
  const PTooltip({
    super.key,
    required this.message,
    required this.child,
    this.side = PHelpBubbleSide.top,
    this.pinnedOpen = false,
  });

  /// 글 — 한 줄로 짧게. 이름이면 명사 · 동사구 그대로("금액 가리기"), 문장이면 해요체에 마침표.
  final String message;

  /// 트리거 — 아이콘 버튼 · 줄인 글. 이름은 트리거가 가진다.
  final Widget child;

  /// 트리거의 어느 쪽에 띄우나 — 기본 위. 자리가 모자라면 반대편으로 뒤집는다.
  final PHelpBubbleSide side;

  /// 늘 열어 둔다 — 카탈로그의 정지한 견본 · 테스트용(웹 견본의 `open`). 마우스 · 초점 · Esc 가 닫지 못한다.
  final bool pinnedOpen;

  @override
  State<PTooltip> createState() => _PTooltipState();
}

class _PTooltipState extends State<PTooltip>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController(
    debugLabel: 'PTooltip',
  );
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: PDuration.d4,
  );

  Timer? _openTimer;
  Timer? _closeTimer;

  bool _open = false;
  bool _overTrigger = false;
  bool _overBubble = false;
  bool _focusHeld = false;
  bool _instant = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener(_onAnimStatus);
    if (widget.pinnedOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _TooltipGroup.reset();
        _openNow(instant: true);
      });
    }
  }

  @override
  void dispose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    // 화면에서 사라지는 툴팁은 식는 시간을 남기지 않는다
    if (_TooltipGroup.current == this) _TooltipGroup.current = null;
    _anim.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_open && _portal.isShowing) {
      _portal.hide();
    }
  }

  // ── 열고 닫기 ─────────────────────────────────────────────
  void _show({required bool wait}) {
    _closeTimer?.cancel();
    _closeTimer = null;
    if (_open) return;
    if (!wait || _TooltipGroup.warm) {
      _openNow();
      return;
    }
    _openTimer ??= Timer(kTooltipOpenDelay, () {
      _openTimer = null;
      _openNow();
    });
  }

  void _openNow({bool instant = false}) {
    _openTimer?.cancel();
    _openTimer = null;
    if (!mounted || _open) return;
    // 이어서 옆 트리거로 옮겼다 — 기다리지 않고 모션 없이 바로
    final other = _TooltipGroup.current;
    _instant = instant || _TooltipGroup.warm;
    if (other != null && other != this && !other.widget.pinnedOpen) {
      other._closeNow(immediate: true);
    }
    _open = true;
    // 늘 열린 견본은 그룹에 끼지 않는다 — 다른 툴팁의 기다림을 건드리지 않는다
    if (!widget.pinnedOpen) _TooltipGroup.opened(this);
    if (!_portal.isShowing) _portal.show();
    if (_instant) {
      _anim.value = 1;
    } else {
      _anim.forward();
    }
    setState(() {});
  }

  void _hide({required bool wait}) {
    _openTimer?.cancel();
    _openTimer = null;
    if (!_open || widget.pinnedOpen) return;
    if (!wait) {
      _closeNow();
      return;
    }
    _closeTimer ??= Timer(kTooltipCloseDelay, () {
      _closeTimer = null;
      _closeNow();
    });
  }

  void _closeNow({bool immediate = false}) {
    _closeTimer?.cancel();
    _closeTimer = null;
    if (!_open) return;
    _open = false;
    if (!widget.pinnedOpen) _TooltipGroup.closed(this);
    if (immediate || _instant || _reduceMotion) {
      // 이어서 열리는 옆 툴팁에 자리를 내준다 — 모션 없이
      _anim.value = 0;
      if (_portal.isShowing) _portal.hide();
    } else {
      _anim.reverse();
    }
    if (mounted) setState(() {});
  }

  /// 포인터가 트리거도 말풍선도 아니고 초점도 없으면 닫는다.
  void _maybeClose() {
    if (_overTrigger || _overBubble || _focusHeld) return;
    _hide(wait: true);
  }

  // ── 입력 ──────────────────────────────────────────────────
  void _onEnterTrigger(PointerEnterEvent e) {
    // 손가락 · 펜으로는 열지 않는다 — 마우스만
    if (e.kind != PointerDeviceKind.mouse) return;
    _overTrigger = true;
    _show(wait: true);
  }

  void _onExitTrigger(PointerExitEvent e) {
    if (e.kind != PointerDeviceKind.mouse) return;
    _overTrigger = false;
    _openTimer?.cancel();
    _openTimer = null;
    _maybeClose();
  }

  void _onEnterBubble(PointerEnterEvent e) {
    _overBubble = true;
    // 말풍선 위로 옮기는 동안은 열어 둔다
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _onExitBubble(PointerExitEvent e) {
    _overBubble = false;
    _maybeClose();
  }

  /// 트리거를 눌렀다 — 열지도 닫지도 않는다. 기다리던 열기는 거둔다.
  void _onPointerDown(PointerDownEvent e) {
    _openTimer?.cancel();
    _openTimer = null;
  }

  void _onFocusChange(bool focused) {
    if (!focused) {
      _focusHeld = false;
      _hide(wait: false);
      return;
    }
    // 손가락으로 눌러 온 초점은 열지 않는다 — 키보드(전통 모드)로 온 초점만
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return;
    }
    _focusHeld = true;
    _show(wait: false);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_open &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      // 닫는다 — 초점은 트리거에 그대로
      _hide(wait: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── 그리기 ────────────────────────────────────────────────
  HelpBubbleLook _look() {
    final value = _anim.value;
    if (!_open) {
      // 닫힘 — 크기는 그대로, 투명도만
      return (opacity: PEasing.easing.transform(value), scale: 1);
    }
    final t = PEasing.enter.transform(value);
    return (opacity: t, scale: (_reduceMotion || _instant) ? 1 : 0.9 + 0.1 * t);
  }

  Widget _bubble(BuildContext context, OverlayChildLayoutInfo info) {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final c = context.colors;
    final target = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    Widget body = DecoratedBox(
      key: const ValueKey('p-tooltip'),
      decoration: BoxDecoration(
        color: c.bgNeutralInverted,
        borderRadius: BorderRadius.circular(PRounded.r3),
      ),
      // 화면에 다 들지 않으면(큰 글자) 놓는 쪽이 높이를 줄이고 글은 이 안에서 스크롤한다 — Help Bubble 과 같다. 읽는 말은
      // 아래 묶음이 이름으로 읽는다(스크롤 노드가 글을 떼어 가지 않게 뺀다)
      child: ExcludeSemantics(
        child: PScrollArea(
          use: PScrollAreaUse.overlay,
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.x3,
            vertical: PSpacing.x2_5,
          ),
          child: Text(
            keepAll(widget.message),
            key: const ValueKey('p-tooltip-text'),
            semanticsLabel: widget.message,
            style: PTypography.t3.copyWith(
              fontWeight: FontWeight.w700,
              color: c.fgNeutralInverted,
            ),
          ),
        ),
      ),
    );
    // 역할 tooltip 은 Flutter 3.44 가 아직 검사를 두지 않아(SemanticsRole.tooltip 은 debug 에서 assert) 달지 못한다 —
    // 트리거의 tooltip(설명)이 읽는 길이고 말풍선은 글 하나의 묶음이다
    body = Semantics(container: true, label: widget.message, child: body);
    // 말풍선 위로 옮겨도 닫히지 않는다
    body = MouseRegion(
      onEnter: _onEnterBubble,
      onExit: _onExitBubble,
      child: body,
    );
    return Positioned.fill(
      child: HelpBubbleLayout(
        target: target,
        side: widget.side,
        arrowColor: c.bgNeutralInverted,
        look: _look,
        repaint: _anim,
        safeArea: helpBubbleSafeArea(context),
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 이름은 트리거의 것이다 — 툴팁은 tooltip(설명)만 단다
    Widget child = Semantics(tooltip: widget.message, child: widget.child);
    child = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: MouseRegion(
        onEnter: _onEnterTrigger,
        onExit: _onExitTrigger,
        child: child,
      ),
    );
    child = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _onFocusChange,
      onKeyEvent: _onKey,
      child: child,
    );
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: _bubble,
      child: child,
    );
  }
}
