import 'package:flutter/rendering.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/help_bubble_layout.dart';
import 'package:groo_damda_app/shared/ds/scroll_area/p_scroll_area.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

export 'package:groo_damda_app/shared/ds/help_bubble/help_bubble_layout.dart'
    show PHelpBubbleSide;

/// 트리거를 만드는 함수 — [toggle] 이 말풍선을 열고 닫는다(열려 있으면 닫는다). [open] 은 지금 열려 있는지.
typedef PHelpBubbleTriggerBuilder =
    Widget Function(BuildContext context, VoidCallback toggle, bool open);

/// 닫기 버튼 — 38 상자(100% 에서 오른쪽 위 모서리, 큰 글자에서는 제목 첫 줄 가운데를 따라 내려간다), 아이콘 14, 누르는 영역 44(사방
/// 3 넓힌다).
const double _closeSize = 38;
const double _closeIcon = 14;
const double _closeTouch = 44;

/// Help Bubble — 트리거를 누르면 옆에 뜨는 짙은 도움말 말풍선. 구조는 SEED Help Bubble(2026-10-02), 수치 원본은
/// groo-design `specs/components/help-bubble.yaml`(값은 `test/fixtures/design_spec/help-bubble.json` — Tooltip 과 한
/// 파일). 웹(desk-front `src/shared/ds/help-bubble`)과 같은 값이다.
///
/// 화면에 늘 두기에는 길고 몰라도 일은 할 수 있는 설명(규정 · 계산 방법 · 기능 안내)을 ⓘ 를 눌러 보인다. 터치에서도 닿는
/// 도움말이라 눌러서([opens: press]) 연다 — 마우스를 올려 여는 Tooltip(opens: hover)은 터치로는 열리지 않아 앱에 두지
/// 않는다. 일을 하려면 꼭 읽어야 하는 안내는 화면 안 글, 버튼 · 입력이 있는 내용은 Popover(앱은 Bottom Sheet)다.
///
///   [PHelpBubble] — 트리거를 [triggerBuilder] 로 그린다. 누르면 열고 열려 있으면 닫는다(ⓘ 아이콘 버튼 — 이름 "{무엇} 안내")
///   [PHelpBubble.anchor] — 자리만 잡는다(웹 HelpBubbleAnchor). 처음부터 열어 두는 안내를 다른 버튼에 붙일 때 — 누르면 그
///     버튼의 원래 동작이고, 열고 닫는 것은 [open] · [defaultOpen] 이 한다
///
/// 모양 — 폭은 내용만큼 최대 280(여백 포함), 위아래 10 · 좌우 12 · 모서리 12 · bg-neutral-inverted(다크는 밝은 말풍선) ·
/// 그림자 없음. 제목 t3 13 / 18 · 700, 설명 t3 · 400(사이 2), 글은 fg-neutral-inverted — 낱말 단위로 줄을 바꾸고 줄바꿈
/// 문자는 살린다. 화살표는 12 × 8 로 늘 트리거 가운데를 가리키고 말풍선 모서리와 14 를 남긴다. 화살표 끝 ↔ 트리거 4, 화면
/// 가장자리 16(안전 영역 경계부터) — 모자라면 반대편으로 뒤집고 옆으로 민다. 양쪽 다 모자라면(큰 글자) 남는 공간이 넓은
/// 쪽에 그 공간만큼의 높이로 띄우고 글은 말풍선 안에서 스크롤한다 — 화면 밖으로 넘쳐 잘리지 않는다. 트리거가 움직이면(스크롤)
/// 따라간다. 닫기 버튼은 오른쪽 위 모서리에 붙은 38 투명 상자 · 아이콘 14 · 글과 4, 누르면 아이콘만 2px 거리 줄고(바탕
/// 없음) 이름은 "닫기".
/// 열림은 200ms 에 화살표 끝에서 0.9 → 1 · 투명도, 닫힘은 200ms 에 투명도만(모션 줄이기면 크기는 그대로).
///
/// 닫는 법 — 트리거(또는 기준) 다시 누르기 · 바깥 누르기 · 닫기 버튼 · Esc. [closeOnInteractOutside] 를 끄면 바깥 누르기 ·
/// 바깥으로 간 초점에는 닫히지 않는다 — 닫기 버튼이 있는 남겨 둘 안내(처음 쓰는 기능의 설명)에만 쓴다. 시간으로 닫지
/// 않는다(스펙에 없다 — 열고 닫는 지연 200 · 100 · 300ms 는 마우스로 여는 Tooltip 의 값이다).
///
/// 초점(키보드) — 열어도 초점을 옮기지 않는다. 열린 동안 트리거에서 Tab 은 말풍선으로(닫기 버튼이 있으면 그리로), 거기서
/// 다시 Tab 이면 닫고 트리거 다음 칸으로, Shift+Tab 은 트리거로 돌아간다. Esc 는 닫고 초점이 말풍선 안에 있었으면 트리거로
/// 돌려준다. 웹의 초점 링(focused)은 앱에 없다 — 초점은 받고 링은 그리지 않는다.
///
/// 읽기 — 말풍선은 dialog 로 제목 · 설명을 읽고 열릴 때 알린다(live region — 초점을 옮기지 않으므로 화면 읽기가 열린 것을
/// 알아챌 길이 이것이다). 트리거는 열림(expanded)을 읽는다 — 이름은 트리거를 만드는 쪽이 준다. 화살표는 장식이다.
class PHelpBubble extends StatefulWidget {
  const PHelpBubble({
    super.key,
    required this.title,
    required PHelpBubbleTriggerBuilder this.triggerBuilder,
    this.description,
    this.showCloseButton = false,
    this.closeOnInteractOutside = true,
    this.side = PHelpBubbleSide.top,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
  }) : anchor = null;

  /// 자리만 잡는 기준 — [anchor] 는 팝업 의미를 달지 않고 눌러도 말풍선을 열고 닫지 않는다.
  const PHelpBubble.anchor({
    super.key,
    required this.title,
    required Widget this.anchor,
    this.description,
    this.showCloseButton = false,
    this.closeOnInteractOutside = true,
    this.side = PHelpBubbleSide.top,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
  }) : triggerBuilder = null;

  /// 제목 — 무엇의 설명인지("연차 사용 규정"). 한 줄로 끝나면 이것만.
  final String title;

  /// 설명 — 해요체 문장 2 ~ 3줄. 제목을 풀어 줄 때만.
  final String? description;

  /// 오른쪽 위 닫기 버튼 — 닫기 전까지 남겨 둘 안내(처음부터 열어 두는 말풍선)에만.
  final bool showCloseButton;

  /// 바깥 누르기 · 바깥으로 간 초점에 닫힌다(기본 켬). 끄면 Esc · 닫기 버튼 · Tab 으로 나가기로만 닫는다 — 닫기 버튼과
  /// 함께.
  final bool closeOnInteractOutside;

  /// 트리거의 어느 쪽에 띄우나 — 기본 위. 자리가 모자라면 반대편으로 뒤집는다.
  final PHelpBubbleSide side;

  /// 열림을 쓰는 쪽이 쥘 때 — 닫기 버튼 · 바깥 누르기 · Esc 는 [onOpenChange] 로 알리기만 하고 여닫음은 쓰는 쪽이 정한다.
  final bool? open;

  /// 처음부터 열어 둔다 — 처음 쓰는 사람에게 한 번 보이는 안내(닫기 버튼과 함께). [open] 을 쥐지 않을 때만.
  final bool defaultOpen;

  /// 열림이 바뀌려 할 때(같은 값을 거듭 알리지 않는다).
  final ValueChanged<bool>? onOpenChange;

  final PHelpBubbleTriggerBuilder? triggerBuilder;
  final Widget? anchor;

  @override
  State<PHelpBubble> createState() => _PHelpBubbleState();
}

class _PHelpBubbleState extends State<PHelpBubble>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController(
    debugLabel: 'PHelpBubble',
  );
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: PDuration.d4,
  );

  /// 트리거와 말풍선을 한 영역으로 묶는다 — 트리거를 누르는 것은 "바깥" 이 아니다(트리거가 스스로 여닫는다).
  final Object _tapGroup = Object();

  /// 트리거(기준) 둘레 — 초점이 돌아갈 자리를 찾고 Tab · Esc 를 듣는다. 스스로는 초점을 받지 않는다.
  final FocusNode _originNode = FocusNode(
    debugLabel: 'PHelpBubble origin',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// 말풍선 둘레 — Tab · Esc 를 듣는다.
  final FocusNode _scopeNode = FocusNode(
    debugLabel: 'PHelpBubble scope',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// 말풍선 자체 — 닫기 버튼이 없을 때 Tab 으로 들어오는 곳.
  final FocusNode _bubbleNode = FocusNode(debugLabel: 'PHelpBubble');
  final FocusNode _closeNode = FocusNode(debugLabel: 'PHelpBubble close');

  bool _inner = false;
  bool _focusWasInside = false;
  bool _reduceMotion = false;

  bool get _open => widget.open ?? _inner;

  @override
  void initState() {
    super.initState();
    _inner = widget.defaultOpen;
    _anim.addStatusListener(_onAnimStatus);
    FocusManager.instance.addListener(_onFocusChange);
    if (_open) WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(PHelpBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 쓰는 쪽이 열림을 바꿨다 — 그리는 중에 오버레이를 건드리지 않게 다음 프레임에 맞춘다
    if (_open !=
        (_portal.isShowing && _anim.status != AnimationStatus.reverse)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    _anim.dispose();
    _originNode.dispose();
    _scopeNode.dispose();
    _bubbleNode.dispose();
    _closeNode.dispose();
    super.dispose();
  }

  /// 열림에 맞춰 오버레이 · 애니메이션을 맞춘다 — 열면 올리고 커지고, 닫으면 투명해진 뒤 내린다.
  void _apply() {
    if (!mounted) return;
    if (_open) {
      if (!_portal.isShowing) {
        _focusWasInside = _focusInside;
        _portal.show();
      }
      _anim.forward();
    } else if (_portal.isShowing) {
      _anim.reverse();
    }
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_open && _portal.isShowing) {
      _portal.hide();
    }
  }

  void _setOpen(bool next) {
    if (next == _open) return;
    if (widget.open == null) {
      setState(() => _inner = next);
    }
    widget.onOpenChange?.call(next);
    if (widget.open == null) _apply();
  }

  // ── 초점 ───────────────────────────────────────────────────

  /// 초점이 돌아갈 곳 — 트리거(기준) 안의 첫 초점 자리.
  FocusNode? get _originTarget {
    for (final node in _originNode.traversalDescendants) {
      if (node.canRequestFocus) return node;
    }
    return null;
  }

  void _focusOrigin() {
    _originTarget?.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
  }

  FocusNode get _enterTarget =>
      widget.showCloseButton ? _closeNode : _bubbleNode;

  /// 지금 초점이 트리거 · 말풍선 안에 있나.
  bool get _focusInside {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    bool inside(FocusNode scope) =>
        focus == scope || focus.ancestors.contains(scope);
    return inside(_originNode) || inside(_scopeNode);
  }

  /// 초점이 트리거 · 말풍선 안에 있었다가 밖으로 나가면 닫는다(바깥 누르기와 같은 말). 처음부터 밖에 있던 초점은 보지
  /// 않는다 — 처음부터 열어 둔 안내가 화면의 첫 초점 이동에 사라지지 않게. 열 때 초점이 이미 트리거에 있었으면 안에 있던
  /// 것으로 친다.
  void _onFocusChange() {
    if (!_open) {
      _focusWasInside = false;
      return;
    }
    if (FocusManager.instance.primaryFocus == null) return;
    if (_focusInside) {
      _focusWasInside = true;
    } else if (_focusWasInside) {
      _focusWasInside = false;
      if (widget.closeOnInteractOutside) _setOpen(false);
    }
  }

  static bool _plainTab(KeyEvent event) =>
      event is KeyDownEvent &&
      event.logicalKey == LogicalKeyboardKey.tab &&
      !HardwareKeyboard.instance.isAltPressed &&
      !HardwareKeyboard.instance.isControlPressed &&
      !HardwareKeyboard.instance.isMetaPressed;

  KeyEventResult _onOriginKey(FocusNode node, KeyEvent event) {
    if (!_open) return KeyEventResult.ignored;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _setOpen(false);
      return KeyEventResult.handled;
    }
    // 열린 동안 Tab — 말풍선으로(오버레이는 트리의 다른 곳에 있어 기본 순서에 맡기면 건너뛴다)
    if (_plainTab(event) && !HardwareKeyboard.instance.isShiftPressed) {
      _enterTarget.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onBubbleKey(FocusNode node, KeyEvent event) {
    if (!_open) return KeyEventResult.ignored;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      // 초점이 말풍선 안에 있었으면 트리거로
      final inside = _scopeNode.hasFocus;
      _setOpen(false);
      if (inside) _focusOrigin();
      return KeyEventResult.handled;
    }
    if (!_plainTab(event)) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isShiftPressed) {
      // Shift+Tab — 트리거로(말풍선은 트리거 바로 뒤다). 말풍선은 열린 채
      _focusOrigin();
      return KeyEventResult.handled;
    }
    // 마지막 칸(닫기 버튼, 없으면 말풍선)에서 Tab — 닫고 초점을 트리거에 두어 기본 순서가 트리거 다음 칸으로 보낸다
    if (_enterTarget.hasFocus) {
      _focusOrigin();
      _setOpen(false);
    }
    return KeyEventResult.ignored;
  }

  // ── 그리기 ──────────────────────────────────────────────────

  HelpBubbleLook _look() {
    final value = _anim.value;
    if (!_open) {
      // 닫힘 — 크기는 그대로, 투명도만
      return (opacity: PEasing.easing.transform(value), scale: 1);
    }
    final t = PEasing.enter.transform(value);
    return (opacity: t, scale: _reduceMotion ? 1 : 0.9 + 0.1 * t);
  }

  Widget _bubble(BuildContext context, OverlayChildLayoutInfo info) {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final c = context.colors;
    final target = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    Widget body = _BubbleBody(
      title: widget.title,
      description: widget.description,
      closeNode: widget.showCloseButton ? _closeNode : null,
      onClose: () {
        _setOpen(false);
        _focusOrigin();
      },
    );
    body = Focus(
      focusNode: _bubbleNode,
      canRequestFocus: !widget.showCloseButton,
      child: body,
    );
    body = Semantics(
      container: true,
      role: SemanticsRole.dialog,
      liveRegion: true,
      // 제목 · 설명 — 글은 스크롤 상자 안이라(스크롤 상자는 제 노드를 따로 세운다) 말풍선이 직접 이름으로 읽는다. 글이 말풍선
      // 안에서 스크롤해 가려져 있어도 화면 읽기는 전부 읽는다
      label: [widget.title, ?widget.description].join('\n'),
      child: body,
    );
    body = Focus(focusNode: _scopeNode, onKeyEvent: _onBubbleKey, child: body);
    body = TapRegion(
      groupId: _tapGroup,
      onTapOutside: widget.closeOnInteractOutside
          ? (_) => _setOpen(false)
          : null,
      child: body,
    );
    return Positioned.fill(
      child: HelpBubbleLayout(
        target: target,
        side: widget.side,
        safeArea: helpBubbleSafeArea(context),
        arrowColor: c.bgNeutralInverted,
        look: _look,
        repaint: _anim,
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.triggerBuilder;
    Widget child = trigger != null
        ? MergeSemantics(
            // 열림을 읽는다 — 이름은 트리거를 만드는 쪽이 준다. 트리거 하나의 노드로 합친다
            child: Semantics(
              expanded: _open,
              child: trigger(context, () => _setOpen(!_open), _open),
            ),
          )
        : widget.anchor!;
    child = Focus(
      focusNode: _originNode,
      onKeyEvent: _onOriginKey,
      child: TapRegion(groupId: _tapGroup, child: child),
    );
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: _bubble,
      child: child,
    );
  }
}

/// 말풍선 몸통 — 짙은 바탕 · 제목 · 설명 · 닫기 버튼. 폭은 내용만큼(최대는 놓는 쪽이 정한다).
class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.title,
    required this.description,
    required this.closeNode,
    required this.onClose,
  });

  final String title;
  final String? description;

  /// 닫기 버튼의 초점 — 없으면 닫기 버튼이 없다.
  final FocusNode? closeNode;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showClose = closeNode != null;
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x0_5,
      children: [
        Text(
          keepAll(title),
          semanticsLabel: title,
          key: const ValueKey('help-bubble-title'),
          style: PTypography.t3.copyWith(
            fontWeight: FontWeight.w700,
            color: c.fgNeutralInverted,
          ),
        ),
        if (description != null)
          Text(
            keepAll(description!),
            semanticsLabel: description,
            key: const ValueKey('help-bubble-description'),
            style: PTypography.t3.copyWith(color: c.fgNeutralInverted),
          ),
      ],
    );
    return DecoratedBox(
      key: const ValueKey('help-bubble'),
      decoration: BoxDecoration(
        color: c.bgNeutralInverted,
        borderRadius: BorderRadius.circular(PRounded.r3),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: showClose ? _closeSize : 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 글 — 말풍선이 화면에 다 들지 않으면(큰 글자) 놓는 쪽이 높이를 줄이고 글은 이 안에서 스크롤한다. 닫기 버튼은 스크롤
            // 밖이라 늘 그 자리에 있다(스크롤 전에는 제목 첫 줄 가운데). 읽는 말은 말풍선(dialog)이 이름으로 한 번에 읽는다 —
            // 스크롤 노드가 글을 따로 떼어 가지 않게 뺀다
            ExcludeSemantics(
              child: PScrollArea(
                use: PScrollAreaUse.overlay,
                // 닫기 버튼이 있으면 글과 그 상자 사이 4 — 상자는 오른쪽 끝에 붙는다
                padding: EdgeInsetsDirectional.fromSTEB(
                  PSpacing.x3,
                  PSpacing.x2_5,
                  showClose ? PSpacing.x1 + _closeSize : PSpacing.x3,
                  PSpacing.x2_5,
                ),
                child: text,
              ),
            ),
            if (showClose)
              // 38 상자의 사방 3 을 넓힌 44(말풍선 모서리 밖은 Flutter 가 받지 않는다 — 말풍선 안쪽만). 상자 가운데는 제목 첫 줄
              // 가운데 — 위 여백 10 + (제목 t3 의 실제 줄 높이 − 38) ÷ 2. 100% 는 줄 18 이라 0(오른쪽 위 모서리), 글자를 키우면
              // 크기를 그대로 두고 첫 줄을 따라 내려간다(help-bubble 레시피, groo-design #263)
              PositionedDirectional(
                top:
                    PSpacing.x2_5 +
                    (MediaQuery.textScalerOf(
                                  context,
                                ).scale(PTypography.t3.fontSize!) *
                                PTypography.t3.height! -
                            _closeSize) /
                        2 -
                    (_closeTouch - _closeSize) / 2,
                end: -(_closeTouch - _closeSize) / 2,
                width: _closeTouch,
                height: _closeTouch,
                child: _CloseButton(focusNode: closeNode!, onClose: onClose),
              ),
          ],
        ),
      ),
    );
  }
}

/// 닫기 — 바탕 없이 아이콘(lucide x 14, fg-neutral-inverted)만. 누르면 아이콘이 2px 거리 줄고(기준 38, 모션 줄이기면
/// 없다), 키보드는 Space · Enter. 이름은 "닫기".
class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.focusNode, required this.onClose});

  final FocusNode focusNode;
  final VoidCallback onClose;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: AppLocalizations.of(context).actionClose,
      onTap: widget.onClose,
      child: Focus(
        focusNode: widget.focusNode,
        onKeyEvent: _onKey,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onClose,
            child: Center(
              child: SelectionPressScale(
                pressed: _pressed,
                size: const Size.square(_closeSize),
                child: SizedBox.square(
                  key: const ValueKey('help-bubble-close-box'),
                  dimension: _closeSize,
                  child: Center(
                    child: Icon(
                      LucideIcons.x,
                      key: const ValueKey('help-bubble-close-icon'),
                      size: _closeIcon,
                      color: c.fgNeutralInverted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
