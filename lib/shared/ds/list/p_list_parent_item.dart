import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_expand_motion.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';

/// 하위 줄을 접는 부모 줄 — 카테고리처럼 부모 · 하위 두 단계로 된 목록에서 줄 자체는 편집을 열고 하위 줄만 접을 때. 구조는
/// 줄 앞 꺾쇠 단추 + 줄 + 하위 줄 묶음이다(groo-design `specs/components/list.md` "하위 줄", 2026-10-10 사용자 결정 7C ·
/// 17B). 웹(desk-front `src/shared/ds/list`)의 `ListParentItem` 과 같은 값이다.
///
///   꺾쇠 단추 — 보이는 상자가 곧 누르는 영역 44 · 모서리 10 · lucide `chevron-right` 20(`fg-neutral-subtle`). 접히면 오른쪽,
///     펼치면 아래로 90° 돈다(300ms — 모션 줄이기면 바로). 줄 앞 4 · 단추 뒤 4 를 지나 앞 붙이개가 52 에서 시작한다.
///     줄과 따로 눌린다 — 단추를 눌러도 줄의 편집([onTap])은 열리지 않고, 줄을 눌러도 접히지 않는다. 누르면 단추만
///     누름 색 + 2px 거리 축소(기준 44)다.
///   이름 — 호출하는 쪽이 넘기는 [expandLabel]("{카테고리} 하위 카테고리")로 고정이다. 상태마다 "접기 · 펼치기" 로 바꾸지
///     않고, 펼침은 expanded 상태로 읽힌다.
///   하위 줄 — 부모의 제목 자리 104 에서 시작한다(누름 바탕은 줄 폭 그대로). 펼침 · 접힘은 높이 300ms, 모션 줄이기면 높이
///     없이 150ms 서서히 나타나고 사라진다. 접힘이 끝나면 하위 줄은 트리에서 빠진다(그리지 않고 · 읽지 않고 · 포커스도
///     받지 않는다).
///   하위가 없는 부모 줄 · 늘 펼쳐 두는 화면([collapsible] 이 false 인 편집 모드)도 꺾쇠 자리를 같은 폭으로 비운다 —
///     부모 타일이 모두 52 에 선다. 빈 자리는 읽는 말에서 숨는다.
///   늘 펼침 — `collapsible: false`(groo-design Q-002, Tree View 의 collapsible 과 같은 이름 · 같은 뜻). 꺾쇠 자리는 비우고
///     하위 줄은 늘 보이며 expanded 로 읽히지 않는다. 접는 줄(기본)은 하위가 없어도 [expandLabel] 이 필수다(생성자 assert).
/// 이 줄은 편집을 여는 줄이라 오른쪽 화살표를 달지 않는다(화살표는 화면을 옮기는 줄에만). 한 목록에 [PListParentItem] 이
/// 있으면 그 목록의 맨 위 단계 줄은 모두 [PListParentItem] 이다(타일 자리를 맞춘다).
///
/// 읽는 순서 — 꺾쇠 단추 → 줄 → 펼친 하위 줄 → 다음 부모의 꺾쇠 단추.
/// [onTap] 이 없으면 줄이 막히지만 꺾쇠 단추는 따로 눌린다.
class PListParentItem extends StatefulWidget {
  const PListParentItem({
    super.key,
    required this.title,
    required this.onTap,
    this.detail,
    this.detailChild,
    this.titleColor,
    this.highlighted = false,
    this.align = PListAlign.center,
    this.prefix,
    this.suffix,
    this.endInset,
    this.readOnly = false,
    this.collapsible = true,
    this.expandLabel,
    this.open,
    this.defaultOpen,
    this.onOpenChange,
    this.children = const [],
    this.focusNode,
  }) : assert(
         detail == null || detailChild == null,
         '설명은 글(detail)이나 위젯(detailChild) 하나만 준다',
       ),
       assert(
         !collapsible || (expandLabel != null && expandLabel != ''),
         '접는 줄은 하위가 없어도 expandLabel(꺾쇠 단추의 이름)이 필수다',
       ),
       assert(
         collapsible ||
             (expandLabel == null &&
                 open == null &&
                 defaultOpen == null &&
                 onOpenChange == null),
         'collapsible 이 false 면(늘 펼침) expandLabel · open · defaultOpen · onOpenChange 를 주지 않는다',
       );

  final String title;
  final String? detail;
  final Widget? detailChild;
  final Color? titleColor;
  final bool highlighted;
  final PListAlign align;
  final Widget? prefix;
  final Widget? suffix;

  /// 줄 오른쪽 끝 여백 — 줄 끝 조작 요소(끄는 손잡이)를 화면 끝에서 안쪽으로 세울 때(기본은 좌우 여백 24). [PListItem] 의
  /// `endInset` 과 같은 이름 · 같은 뜻이다.
  final double? endInset;

  /// 보기만 하는 줄 — 줄을 누르지 못하고(눌림 · 포커스 없음) 글 · 타일 색은 보통 줄 그대로다. [onTap] 이 없어서 막힌 줄
  /// (비활성 색)과 다르다. 꺾쇠 단추는 따로 눌린다. 순서 바꾸기 모드의 부모 줄이 쓴다.
  final bool readOnly;

  /// 줄을 누르면 하는 일(편집) — 없으면 줄이 막힌다.
  final VoidCallback? onTap;

  /// 접는 줄(기본 true) — 꺾쇠 단추로 하위 줄을 접고 편다. false 면 늘 펼친 화면(편집 모드): 꺾쇠 자리는 같은 폭으로
  /// 비우고(읽지 않는다) 하위 줄은 늘 보이며 펼침 상태가 없다.
  final bool collapsible;

  /// 꺾쇠 단추의 고정 이름 — "{카테고리} 하위 카테고리". 접는 줄은 하위가 없어도 필수, 늘 펼친 줄은 주지 않는다.
  final String? expandLabel;

  /// 하위 줄 펼침 — 쥐고 다룰 때. 주면 이 값을 따르고 [onOpenChange] 로 바꾸려는 값을 알린다(안 바꿔 주면 그대로).
  final bool? open;

  /// 처음 펼침 — 화면이 정한다(카테고리는 모두 펼친 채 연다). [open] 이 없을 때만. 없으면 접힘.
  final bool? defaultOpen;
  final ValueChanged<bool>? onOpenChange;

  /// 하위 줄([PListButtonItem] …). 비면 꺾쇠 자리만 비운다.
  final List<Widget> children;
  final FocusNode? focusNode;

  @override
  State<PListParentItem> createState() => _PListParentItemState();
}

class _PListParentItemState extends State<PListParentItem> {
  late bool _inner = widget.defaultOpen ?? false;
  final String _subId = 'plist-sub-${UniqueKey()}';

  bool get _foldable => widget.children.isNotEmpty && widget.collapsible;

  // collapsible 이 false 면(늘 펼쳐 두는 화면) 하위 줄은 늘 보인다
  bool get _open =>
      _foldable ? (widget.open ?? _inner) : widget.children.isNotEmpty;

  void _toggle() {
    final next = !_open;
    if (widget.open == null) setState(() => _inner = next);
    widget.onOpenChange?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListRowFrame(
          title: widget.title,
          detail: widget.detail,
          detailChild: widget.detailChild,
          titleColor: widget.titleColor,
          prefix: widget.prefix,
          suffix: widget.suffix,
          endInset: widget.endInset,
          highlighted: widget.highlighted,
          align: widget.align,
          nest: PListNest.parent,
          expandButton: _foldable
              ? PListExpandButton(
                  label: widget.expandLabel!,
                  open: open,
                  controlsId: _subId,
                  onToggle: _toggle,
                )
              : null,
          interactive: !widget.readOnly,
          onActivate: widget.readOnly ? null : widget.onTap,
          focusNode: widget.focusNode,
          semantics: widget.readOnly
              ? const PListRowSemantics()
              : const PListRowSemantics(button: true),
        ),
        if (widget.children.isNotEmpty)
          _PListSubList(id: _subId, open: open, children: widget.children),
      ],
    );
  }
}

/// 줄 앞 꺾쇠 단추 — 보이는 상자 = 누르는 영역 44 · 모서리 10. 줄과 따로 눌린다(줄의 누름 바탕은 생기지 않는다).
///
/// 누르면 단추만 `bg-layer-default-pressed`(150ms) + 2px 거리 축소(기준 44 → (44 − 2) ÷ 44 — 모션 줄이기면 색만).
/// 꺾쇠는 접히면 오른쪽(0°), 펼치면 아래(90°)로 300ms 돈다(모션 줄이기면 바로). 이름은 [label] 로 고정하고 펼침은
/// expanded 로 읽는다. 키보드 — 포커스에서 Enter · Space.
class PListExpandButton extends StatefulWidget {
  const PListExpandButton({
    super.key,
    required this.label,
    required this.open,
    required this.onToggle,
    this.controlsId,
  });

  final String label;
  final bool open;
  final VoidCallback onToggle;

  /// 펼치고 접는 하위 줄 묶음의 식별자(웹 aria-controls).
  final String? controlsId;

  @override
  State<PListExpandButton> createState() => _PListExpandButtonState();
}

class _ToggleIntent extends Intent {
  const _ToggleIntent();
}

class _PListExpandButtonState extends State<PListExpandButton> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onMode);
    super.dispose();
  }

  void _onMode(FocusHighlightMode _) {
    if (mounted) setState(() {});
  }

  static const Map<ShortcutActivator, Intent> _keys = {
    SingleActivator(LogicalKeyboardKey.space): _ToggleIntent(),
    SingleActivator(LogicalKeyboardKey.enter): _ToggleIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): _ToggleIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = {
    _ToggleIntent: CallbackAction<_ToggleIntent>(
      onInvoke: (_) {
        widget.onToggle();
        return null;
      },
    ),
  };

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final tracker = PListRowScope.maybeOf(context)?.tracker;
    // 카탈로그가 누름을 멈춰 그리는 중이면 눌린 모습
    final pressed =
        _pressed ||
        PListPressedPreview.of(context, PListPreviewTarget.expandButton);

    // 보이는 상자 44 — 누름 색(150ms) · 꺾쇠(접히면 오른쪽, 펼치면 아래로 300ms)
    final box = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: pressed ? 1 : 0),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, t, child) => DecoratedBox(
        key: const ValueKey('plist-expand-button'),
        decoration: BoxDecoration(
          color: _lerpPremultiplied(
            const Color(0x00000000),
            c.bgLayerDefaultPressed,
            t,
          ),
          borderRadius: BorderRadius.circular(PRounded.r2_5),
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: PTouch.min,
        child: Center(
          child: AnimatedRotation(
            key: const ValueKey('plist-expand-icon'),
            turns: widget.open ? 0.25 : 0,
            duration: reduceMotion ? Duration.zero : PDuration.d6,
            curve: PEasing.easing,
            child: Icon(
              LucideIcons.chevronRight,
              size: PSpacing.x5,
              color: c.fgNeutralSubtle,
            ),
          ),
        ),
      ),
    );

    // 누름 축소 — 기준 길이 44(보이는 상자 = 누르는 영역)에서 2px
    final scaled = AnimatedScale(
      key: const ValueKey('plist-expand-scale'),
      scale: pressed && !reduceMotion ? (PTouch.min - 2) / PTouch.min : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: box,
    );

    final tappable = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onToggle,
        child: scaled,
      ),
    );

    // Tab 은 꺾쇠 단추가 줄보다 먼저다(단추는 줄의 포커스 안에 얹혀 있다 — list_row.dart)
    final focusable = FocusTraversalOrder(
      order: const NumericFocusOrder(0),
      // 키보드 초점 링 — 단추 바깥 2px · 단추 모서리 10 (터치로 눌러 생긴 초점에는 없다)
      child: Focus(
        child: Builder(
          builder: (context) => PFocusRing(
            visible: Focus.of(context).hasPrimaryFocus && keyboardHighlight(),
            style: const PFocusRingStyle(radius: 10),
            child: tappable,
          ),
        ),
      ),
    );

    final button = Semantics(
      container: true,
      button: true,
      label: widget.label,
      expanded: widget.open,
      controlsNodes: widget.controlsId == null ? null : {widget.controlsId!},
      onTap: widget.onToggle,
      child: Shortcuts(
        shortcuts: _keys,
        child: Actions(actions: _actions, child: focusable),
      ),
    );
    if (tracker == null) return button;
    // 누르는 동안 줄은 눌린 모습이 되지 않는다
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => tracker.down(e.pointer),
      onPointerUp: (e) => tracker.up(e.pointer),
      onPointerCancel: (e) => tracker.up(e.pointer),
      child: button,
    );
  }
}

Color _lerpPremultiplied(Color a, Color b, double t) {
  final alpha = (a.a + (b.a - a.a) * t).clamp(0.0, 1.0);
  if (alpha <= 0) return b.withValues(alpha: 0);
  double channel(double from, double to) =>
      ((from * a.a + (to * b.a - from * a.a) * t) / alpha).clamp(0.0, 1.0);
  return Color.from(
    alpha: alpha,
    red: channel(a.r, b.r),
    green: channel(a.g, b.g),
    blue: channel(a.b, b.b),
  );
}

/// 하위 줄 묶음 — 부모 줄 바로 아래에서 펼치고 접힌다. 움직임은 Accordion 과 같은 [PExpandMotion] 이다 — 높이 300ms
/// (`motion-ease-easing`), 모션 줄이기면 높이 없이 150ms 서서히. 접힘이 끝나면 하위 줄은 트리에서 빠진다.
class _PListSubList extends StatelessWidget {
  const _PListSubList({
    required this.id,
    required this.open,
    required this.children,
  });

  final String id;
  final bool open;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scope = PListScope.of(context);
    return PExpandMotion(
      open: open,
      keyPrefix: 'plist-sub-list',
      child: PListScope(
        itemRadius: scope.itemRadius,
        nest: PListNest.child,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          identifier: id,
          child: Column(
            key: const ValueKey('plist-sub-list'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
