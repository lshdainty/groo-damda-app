part of 'p_attachment_input.dart';

// attachment-input.yaml 의 값 — 토큰이 있는 값은 토큰으로 적는다.
const double _tile = 80; // trigger.size · item.height · 사진 폭
const double _fileWidth = 160; // 파일 카드 폭(kind.file item.width)
const double _itemRadius = PRounded.r3; // item.radius 12
const double _thumb = 48; // thumbnail.size
const double _thumbRadius = PRounded.r2; // thumbnail.radius 8
const double _filePaddingX = PSpacing.x4; // 파일 카드 paddingX 16
const double _fileGap = 10; // item.gap — 썸네일 칸 ↔ 이름
const double _metaWidth = 70; // meta.width
const double _nameClear = PSpacing.x1; // name.maskClear — 첫 줄 오른쪽 4
const int _nameMaxLines = 4; // name.maxLines
const double _removeSize = 20; // removeButton.size
const double _removeIcon = 10; // removeButton.iconSize
const double _removeTouch = 44; // removeButton.touchTarget
const double _maskSize = 24; // removeMask.size — × 둘레 구멍 지름
const double _maskOffset = 6; // removeMask.offset — 모서리에서 구멍 가운데까지
const double _badgeHeight = PSpacing.x6; // badge.height 24
const double _actionIcon = 24; // actionButton.iconSize
const double _icon = 24; // triggerIcon.size · thumbnailIcon.size
const double _ringWidth = 2; // focusRing.width(안쪽)

/// 글자 배율을 따르는 치수 — 글을 담은 상자(첨부 타일 · 사진 80 · 파일 카드 160)만 `MediaQuery.textScalerOf` 를 곱한다. 웹은 rem 이라
/// 이미 그렇다. 200% 에서 사진 160 · 파일 카드 320 × 160. 썸네일 48 · 아이콘 24 · × 20(누르는 44 · 위 여백 16) · × 아이콘 10 ·
/// × 둘레 구멍 · 올리는 중 원 24 · 대표 띠 24 는 px 그대로다(attachment-input.yaml trigger.size 비고, groo-design #263).
/// 이름 폭은 카드에서 좌우 여백 · 썸네일 · 사이를 뺀 나머지다(100% 70 → 200% 230) — 이름 네 줄 + 크기가 다 보인다.
///
/// 배율은 상자가 담는 글(이름 · 개수 · "다시 시도" 12)의 배율이다 — `scale(80)` 을 그대로 쓰면 안드로이드 비선형 글자 크기에서
/// 큰 값이 덜 커져(200% 에서 80 → 82) 두 배가 된 글을 못 담는다.
class _Dims {
  const _Dims(this.factor);

  factory _Dims.of(BuildContext context) {
    final size = PTypography.t2.fontSize!;
    return _Dims(MediaQuery.textScalerOf(context).scale(size) / size);
  }

  /// 상자에 곱하는 글자 배율 — 100% 에서 1.
  final double factor;

  double get tile => _tile * factor;
  double get fileWidth => _fileWidth * factor;

  /// 파일 카드의 이름 · 크기 폭 — 카드 − 좌우 여백 − 썸네일 − 사이.
  double get metaWidth => fileWidth - 2 * _filePaddingX - _thumb - _fileGap;
}

/// 앱의 길게 눌러 끌기 문턱 — 웹 터치와 같은 250ms(Flutter 기본 길게 누름 500ms 가 아니다).
const Duration kAttachmentDragDelay = Duration(
  milliseconds: 250,
); // item.dragDelayApp

/// × 의 누르는 자리가 보이는 원 밖으로 나가는 만큼 — 위 · 오른쪽 12 + 걸침 4. 항목 자리가 이만큼을 레이아웃에 든다.
const double _touchBleed = PSpacing.x4;

/// 누르는 부품 하나 — 바탕 · 누름 축소(2px 거리) · 키보드 초점 링(안쪽 2px) · 이름 있는 버튼 읽기.
///
/// [blocked] 는 웹의 aria-disabled — 막힌 모습이지만 초점은 남고 눌러도 아무 일이 없다. [disabled] 는 초점에서도 빠진다.
class _PressBox extends StatefulWidget {
  const _PressBox({
    super.key,
    required this.radius,
    required this.child,
    required this.label,
    this.onTap,
    this.focusNode,
    this.restColor = const Color(0x00000000),
    this.pressedColor,
    this.border,
    this.basis,
    this.shrink = true,
    this.blocked = false,
    this.disabled = false,
    this.customActions,
    this.touch,
  });

  final double radius;
  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Color restColor;

  /// 누른 바탕 — 없으면 바탕이 바뀌지 않는다(항목).
  final Color? pressedColor;
  final BoxBorder? border;

  /// 누름 축소의 기준 길이(타일 80 은 글자 배율을 곱한다 · × 24 는 px) — 없으면 타일 한 변.
  final double? basis;
  final bool shrink;
  final bool blocked;
  final bool disabled;
  final Map<CustomSemanticsAction, VoidCallback>? customActions;

  /// 누르는 자리 한 변 — 보이는 상자보다 클 때(×: 20 → 44). 상자 가운데에 놓고 부모 안에서만 받는다.
  final double? touch;

  @override
  State<_PressBox> createState() => _PressBoxState();
}

class _PressBoxState extends State<_PressBox> {
  bool _pressed = false;
  bool _focused = false;

  bool get _inert => widget.disabled || widget.blocked || widget.onTap == null;

  void _activate() {
    if (_inert) return;
    widget.onTap!();
  }

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final active = _pressed && !_inert;
    final fill = active && widget.pressedColor != null
        ? widget.pressedColor!
        : widget.restColor;
    final ring =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    final face = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: fill),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, bg, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
          border: widget.border,
        ),
        position: DecorationPosition.background,
        child: child,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (ring)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey('attachment-focus-ring'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(
                      color: c.strokeFocusRing,
                      width: _ringWidth,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final basis = widget.basis ?? _Dims.of(context).tile;
    final scaled = AnimatedScale(
      scale: active && widget.shrink && !reduce ? (basis - 2) / basis : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: face,
    );

    return Semantics(
      container: true,
      button: true,
      enabled: !widget.disabled && !widget.blocked && widget.onTap != null,
      focusable: !widget.disabled,
      label: widget.label,
      customSemanticsActions: widget.customActions,
      onTap: _inert ? null : _activate,
      excludeSemantics: true,
      child: Focus(
        focusNode: widget.focusNode,
        canRequestFocus: !widget.disabled,
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: (node, event) {
          final key = event.logicalKey;
          if (key != LogicalKeyboardKey.enter &&
              key != LogicalKeyboardKey.numpadEnter &&
              key != LogicalKeyboardKey.space) {
            return KeyEventResult.ignored;
          }
          if (widget.disabled) return KeyEventResult.ignored;
          if (event is KeyDownEvent) _activate();
          return KeyEventResult.handled;
        },
        child: MouseRegion(
          cursor: _inert
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: _activate,
            child: widget.touch == null
                ? scaled
                : SizedBox(
                    width: widget.touch,
                    height: widget.touch,
                    child: Center(child: scaled),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 첨부 타일 — 80 · 모서리 12 · 안쪽 1px stroke-neutral-weak · 투명. 아이콘 24 + 개수(12 / 16).
class _TriggerTile extends StatelessWidget {
  const _TriggerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.max,
    required this.blocked,
    required this.disabled,
    required this.onTap,
    this.focusNode,
  });

  final IconData icon;
  final String label;

  /// 지금 개수 · 최대 — 최대가 없으면 개수를 그리지 않는다.
  final int count;
  final int? max;
  final bool blocked;
  final bool disabled;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = _Dims.of(context);
    final dim = blocked || disabled;
    final iconColor = dim ? c.fgDisabled : c.fgNeutralSubtle;
    return _PressBox(
      focusNode: focusNode,
      radius: _itemRadius,
      label: label,
      basis: d.tile,
      blocked: blocked,
      disabled: disabled,
      pressedColor: c.bgLayerDefaultPressed,
      border: Border.all(color: c.strokeNeutralWeak, width: 1),
      onTap: onTap,
      child: SizedBox(
        width: d.tile,
        height: d.tile,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: PSpacing.x1,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: _icon, color: iconColor),
            ),
            if (max != null)
              ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$count',
                        style: PTypography.t2.copyWith(
                          color: dim ? c.fgDisabled : c.fgNeutral,
                        ),
                      ),
                      TextSpan(
                        text: '/$max',
                        style: PTypography.t2.copyWith(
                          color: dim ? c.fgDisabled : c.fgNeutralSubtle,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// × 둘레 구멍 — 지름 24, 가운데가 오른쪽 위 모서리에서 안쪽 6(× 의 가운데와 같다). 사진 · 덮개 · 윤곽이 × 에 닿지 않게 파낸다.
class _HoleClipper extends CustomClipper<Path> {
  const _HoleClipper({required this.radius});

  final double radius;

  @override
  Path getClip(Size size) {
    final box = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final hole = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width - _maskOffset, _maskOffset),
          radius: _maskSize / 2,
        ),
      );
    return Path.combine(PathOperation.difference, box, hole);
  }

  @override
  bool shouldReclip(_HoleClipper old) => old.radius != radius;
}

/// 항목 자리 — 항목(80 · 160) · × · 다시 시도를 한 상자에 담는다. 위 16 · 오른쪽 [rightBleed] 는 × 의 누르는 자리 44 가 들어가는 여백이고,
/// 상자 밖에서 누른 것도 × 가 받는다(Flutter 는 부모 밖 누르기를 자식에게 묻지 않아 이 상자가 직접 받는다).
class _OverflowStack extends Stack {
  const _OverflowStack({super.children});

  @override
  RenderStack createRenderObject(BuildContext context) => _RenderOverflowStack(
    alignment: alignment,
    textDirection: textDirection ?? Directionality.maybeOf(context),
    fit: fit,
    clipBehavior: clipBehavior,
  );
}

class _RenderOverflowStack extends RenderStack {
  _RenderOverflowStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// × 의 누르는 자리(44 × 44) 표지 — [_RemoveFirstScope] 가 이 상자를 먼저 묻는다. [enabled] 가 아니면(막힘 · 읽기 전용) 먼저 받지
/// 않는다.
class _RemoveTouch extends SingleChildRenderObjectWidget {
  const _RemoveTouch({required this.enabled, required super.child});

  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRemoveTouch(enabled);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderRemoveTouch renderObject,
  ) {
    renderObject.enabled = enabled;
  }
}

class _RenderRemoveTouch extends RenderProxyBox {
  _RenderRemoveTouch(this.enabled);

  bool enabled;
}

/// × 를 이웃 항목보다 먼저 묻는다 — 줄(Row)은 뒤 항목부터 묻는데, 항목 사이 8 에서 × 의 누르는 44 가 이웃 사진 위로 8 × 28 만큼
/// 겹친다. 웹은 × 가 z 1 로 위지만 Flutter 는 형제 순서가 곧 묻는 순서라 여기서 × 의 44 안의 점을 먼저 이어 준다(Q-016-3).
class _RemoveFirstScope extends SingleChildRenderObjectWidget {
  const _RemoveFirstScope({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRemoveFirstScope();
}

class _RenderRemoveFirstScope extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      var hit = false;
      void visit(RenderObject node) {
        if (hit) return;
        if (node is _RenderRemoveTouch) {
          if (!node.enabled || !node.attached || !node.hasSize) return;
          final transform = node.getTransformTo(this);
          final det = transform.determinant();
          if (det == 0 || det.isNaN) return;
          final local = MatrixUtils.transformPoint(
            Matrix4.inverted(transform),
            position,
          );
          if (!node.size.contains(local)) return;
          hit = result.addWithPaintTransform(
            transform: transform,
            position: position,
            hitTest: (r, p) => node.hitTest(r, position: p),
          );
          return;
        }
        node.visitChildren(visit);
      }

      visit(this);
      if (hit) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return super.hitTest(result, position: position);
  }
}

/// 위 [pull] 만큼 레이아웃에서 뺀다 — 웹의 `-mt-x4 pt-x4`. × 의 누르는 자리가 위로 나가도 줄이 앞 칸과 같은 간격을 둔다.
/// 자식이 그린 위 [pull] 은 앞 칸 위에 겹치고, 그 자리에서 자식이 받지 않는 누르기는 앞 칸으로 넘어간다.
class _PullUp extends SingleChildRenderObjectWidget {
  const _PullUp({required this.pull, required super.child});

  final double pull;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPullUp(pull);

  @override
  void updateRenderObject(BuildContext context, _RenderPullUp renderObject) {
    renderObject.pull = pull;
  }
}

class _RenderPullUp extends RenderShiftedBox {
  _RenderPullUp(this._pull) : super(null);

  double _pull;
  set pull(double v) {
    if (_pull == v) return;
    _pull = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints, parentUsesSize: true);
    size = Size(c.size.width, (c.size.height - _pull).clamp(0, c.size.height));
    (c.parentData! as BoxParentData).offset = Offset(0, -_pull);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// 줄 수를 재는 도우미 — 글자 단위로 줄을 바꾼 줄들. 첫 줄은 오른쪽 4 를 비운다(66), 나머지는 70.
@visibleForTesting
List<String> attachmentNameLines(
  String name, {
  required TextStyle style,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
  double metaWidth = _metaWidth,
}) {
  double measure(String s) {
    final p = TextPainter(
      text: TextSpan(text: s.trimRight(), style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final w = p.width;
    p.dispose();
    return w;
  }

  double widthOf(int line) => line == 0 ? metaWidth - _nameClear : metaWidth;

  List<String> wrap(String text) {
    final chars = text.characters.toList();
    final lines = <String>[];
    var pos = 0;
    while (pos < chars.length) {
      // 줄 머리의 빈칸은 버린다(break-all 은 줄바꿈 자리의 빈칸을 접는다)
      if (lines.isNotEmpty && chars[pos] == ' ') {
        pos++;
        continue;
      }
      final room = widthOf(lines.length);
      var lo = 1;
      var hi = chars.length - pos;
      while (lo < hi) {
        final mid = (lo + hi + 1) ~/ 2;
        if (measure(chars.sublist(pos, pos + mid).join()) <= room) {
          lo = mid;
        } else {
          hi = mid - 1;
        }
      }
      lines.add(chars.sublist(pos, pos + lo).join());
      pos += lo;
    }
    return lines;
  }

  final all = wrap(name);
  if (all.length <= _nameMaxLines) return all;

  // 넘친다 — 확장자가 있으면 세 줄 + 확장자 줄, 없으면 네 줄 끝을 줄인다
  final dot = name.lastIndexOf('.');
  final ext = dot > 0 && name.length - dot <= 10 ? name.substring(dot) : '';
  final base = ext.isEmpty ? name : name.substring(0, dot);
  final room = ext.isEmpty ? _nameMaxLines : _nameMaxLines - 1;
  final chars = base.characters.toList();
  var lo = 0;
  var hi = chars.length;
  while (lo < hi) {
    final mid = (lo + hi + 1) ~/ 2;
    if (wrap('${chars.sublist(0, mid).join()}…').length <= room) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  final head = '${chars.sublist(0, lo).join().trimRight()}…';
  return [...wrap(head), if (ext.isNotEmpty) ext];
}

/// 파일 이름 — 글자 단위로 줄을 바꾸고 네 줄까지, 넘치면 셋째 줄 끝을 "…" 로 줄이고 넷째 줄에 확장자를 남긴다.
/// 보조 기술은 항목의 이름(전체 파일 이름)이 읽으므로 여기는 읽지 않는다.
class _FileNameText extends StatelessWidget {
  const _FileNameText({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = PTypography.t2.copyWith(
      fontWeight: FontWeight.w500,
      color: color,
    );
    final lines = attachmentNameLines(
      name,
      style: style,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      metaWidth: _Dims.of(context).metaWidth,
    );
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < lines.length; i++)
            Padding(
              key: ValueKey('attachment-name-line-$i'),
              padding: EdgeInsets.only(right: i == 0 ? _nameClear : 0),
              child: Text(
                lines[i],
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

IconData _fileIcon(PAttachmentEntry e) {
  if (attachmentIsPdf(e.type, e.name)) return LucideIcons.fileText;
  if (attachmentIsSheet(e.type, e.name)) return LucideIcons.fileSpreadsheet;
  return LucideIcons.file;
}

/// 항목의 안 — 사진 · 파일 카드 · 덮개 · 원 · 대표 띠. 단추를 담지 않는다(다시 시도 · × 는 형제).
class _ItemFace extends StatelessWidget {
  const _ItemFace({
    required this.entry,
    required this.status,
    required this.readOnly,
    required this.badgeLabel,
  });

  final PAttachmentEntry entry;
  final PAttachmentStatus status;
  final bool readOnly;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = _Dims.of(context);
    final percent = entry.progress == null
        ? null
        : entry.progress!.clamp(0.0, 1.0) * 100;
    Widget circle(PProgressCircleTone tone) => ExcludeSemantics(
      child: PProgressCircle(
        size: PProgressCircleSize.s24,
        tone: tone,
        value: percent,
      ),
    );

    if (!entry.isImage) {
      final dim = readOnly;
      final iconColor = dim ? c.fgDisabled : c.fgNeutralSubtle;
      if (status == PAttachmentStatus.error) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _filePaddingX),
        child: Row(
          spacing: _fileGap,
          children: [
            Container(
              key: const ValueKey('attachment-thumbnail'),
              width: _thumb,
              height: _thumb,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.bgNeutralWeak,
                borderRadius: BorderRadius.circular(_thumbRadius),
              ),
              child: status == PAttachmentStatus.uploading
                  ? circle(PProgressCircleTone.neutral)
                  : ExcludeSemantics(
                      child: Icon(
                        _fileIcon(entry),
                        size: _icon,
                        color: iconColor,
                      ),
                    ),
            ),
            SizedBox(
              width: d.metaWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FileNameText(
                    name: entry.name,
                    color: dim ? c.fgDisabled : c.fgNeutral,
                  ),
                  ExcludeSemantics(
                    child: Text(
                      formatFileSize(entry.size),
                      key: const ValueKey('attachment-size'),
                      maxLines: 1,
                      softWrap: false,
                      style: PTypography.t1.copyWith(
                        color: dim ? c.fgDisabled : c.fgNeutralSubtle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final fallback = ColoredBox(
      color: c.bgNeutralWeak,
      child: Center(
        child: Icon(LucideIcons.image, size: _icon, color: c.fgNeutralSubtle),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        entry.preview == null
            ? fallback
            : Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: c.bgNeutralWeak),
                  Image(
                    image: entry.preview!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => fallback,
                  ),
                ],
              ),
        if (badgeLabel != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _badgeHeight,
            child: ExcludeSemantics(
              child: DecoratedBox(
                key: const ValueKey('attachment-badge'),
                decoration: BoxDecoration(
                  color: PColors.dark.overlayDim,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(_itemRadius),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: PSpacing.x1),
                  // 사진 위 표식이라 띠 24 와 글은 글자 크기 설정을 따르지 않는다(attachment-input.yaml badge
                  // text-t2-static, groo-design #263) — 대표인 사진은 맨 앞 자리와 항목 이름으로도 안다
                  child: Center(
                    child: Text(
                      badgeLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      style: PTypography.t2.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.staticWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (status == PAttachmentStatus.uploading)
          Positioned.fill(
            child: ColoredBox(
              key: const ValueKey('attachment-backdrop'),
              color: c.overlayDim,
              child: Center(child: circle(PProgressCircleTone.staticWhite)),
            ),
          ),
        if (status == PAttachmentStatus.error)
          Positioned.fill(
            child: ColoredBox(
              key: const ValueKey('attachment-backdrop'),
              color: PColors.dark.overlayDim,
            ),
          ),
        // 윤곽 — 사진 위 안쪽 1px 투명 선(v118)
        const PImageStroke(radius: _itemRadius),
      ],
    );
  }
}

/// × — 20 원이 항목 모서리 밖으로 위 4 · 오른쪽 4 걸친다. 누르는 자리 44.
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    super.key,
    required this.label,
    required this.blocked,
    required this.disabled,
    required this.onTap,
    this.focusNode,
  });

  final String label;
  final bool blocked;
  final bool disabled;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _PressBox(
      focusNode: focusNode,
      radius: _removeSize / 2,
      label: label,
      basis: 24,
      touch: _removeTouch,
      blocked: blocked,
      disabled: disabled,
      restColor: c.bgLayerDefault,
      pressedColor: c.bgLayerDefaultPressed,
      border: Border.all(color: c.strokeNeutralWeak, width: 1),
      onTap: onTap,
      child: SizedBox(
        width: _removeSize,
        height: _removeSize,
        child: Center(
          child: ExcludeSemantics(
            child: Icon(
              LucideIcons.x,
              size: _removeIcon,
              color: blocked || disabled ? c.fgDisabled : c.fgNeutral,
            ),
          ),
        ),
      ),
    );
  }
}

/// 항목 몸 — 사진 · 파일 카드 + 덮개 · 원 · 대표 띠. [hole] 이면 × 둘레 구멍을 판다(끄는 중에는 × 와 구멍이 없다 — 13B).
Widget _itemBody(
  BuildContext context, {
  required PAttachmentEntry entry,
  required PAttachmentStatus status,
  required bool readOnly,
  required String? badgeLabel,
  required bool hole,
  Key? key,
}) {
  final c = context.colors;
  final d = _Dims.of(context);
  final image = entry.isImage;
  final face = DecoratedBox(
    // 파일 카드의 안쪽 1px 테두리 — 사진은 윤곽을 _ItemFace 가 그린다
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(_itemRadius),
      border: image ? null : Border.all(color: c.strokeNeutralWeak, width: 1),
    ),
    child: _ItemFace(
      entry: entry,
      status: status,
      readOnly: readOnly,
      badgeLabel: badgeLabel,
    ),
  );
  return SizedBox(
    key: key,
    width: image ? d.tile : d.fileWidth,
    height: d.tile,
    child: hole
        ? ClipPath(
            clipper: const _HoleClipper(radius: _itemRadius),
            child: face,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(_itemRadius),
            child: face,
          ),
  );
}

/// 끄는 중인 항목의 모습(13B) — 2px 줄어든 채 손가락을 따라가고 × 와 구멍이 없다. 사진은 불투명도 0.5, 파일 카드는 글 · 아이콘이
/// `fg-disabled` 다(읽기 전용과 같은 모습).
class _DragGhost extends StatelessWidget {
  const _DragGhost({
    required this.entry,
    required this.status,
    required this.badgeLabel,
  });

  final PAttachmentEntry entry;
  final PAttachmentStatus status;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final image = entry.isImage;
    final tile = _Dims.of(context).tile;
    Widget body = _itemBody(
      context,
      entry: entry,
      status: status,
      readOnly: true,
      badgeLabel: badgeLabel,
      hole: false,
    );
    if (image) body = Opacity(opacity: 0.5, child: body);
    return DefaultTextStyle(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Transform.scale(
        key: const ValueKey('attachment-drag-ghost'),
        scale: (tile - 2) / tile,
        child: body,
      ),
    );
  }
}

/// 항목 한 칸 — 보이는 항목 · 다시 시도 · ×. 위 16 · 오른쪽 [rightBleed] 를 레이아웃에 두어 × 의 누르는 자리가 안에 든다.
class _ItemSlot extends StatelessWidget {
  const _ItemSlot({
    super.key,
    required this.entry,
    required this.status,
    required this.description,
    required this.readOnly,
    required this.disabled,
    required this.rightBleed,
    required this.badgeLabel,
    required this.onRemove,
    this.onRetry,
    this.onPress,
    this.customActions,
    this.itemNode,
    this.removeNode,
    this.canDrag = false,
    this.dragging = false,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  });

  final PAttachmentEntry entry;
  final PAttachmentStatus status;
  final String description;
  final bool readOnly;
  final bool disabled;
  final double rightBleed;
  final String? badgeLabel;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  /// 항목을 눌렀을 때(메뉴 · 읽기 전용의 크게 보기) — 없으면 눌리지 않는 항목.
  final VoidCallback? onPress;
  final Map<CustomSemanticsAction, VoidCallback>? customActions;
  final FocusNode? itemNode;
  final FocusNode? removeNode;

  /// 길게 눌러 끌 수 있나 — 250ms 누른 채 움직이면 끌기다(앱 문턱 attachment-input.yaml item.dragDelayApp). 그 전에 움직이면 줄이
  /// 스크롤하고, 그냥 떼면 누르기(메뉴)다.
  final bool canDrag;

  /// 끌고 있는 항목 — 이 자리는 빈 자리(놓을 곳)로 남고 모습은 [_DragGhost] 가 손가락을 따라간다.
  final bool dragging;
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset>? onDragMove;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = _Dims.of(context);
    final image = entry.isImage;
    final width = image ? d.tile : d.fileWidth;
    final error = status == PAttachmentStatus.error;
    final dim = readOnly && image;

    Widget body = _itemBody(
      context,
      entry: entry,
      status: status,
      readOnly: readOnly,
      badgeLabel: badgeLabel,
      hole: true,
      key: const ValueKey('attachment-item-body'),
    );
    if (dim) {
      body = AnimatedOpacity(
        opacity: 0.5,
        duration: PDuration.d4,
        curve: PEasing.easing,
        child: body,
      );
    }

    // 누를 수 있는 항목 — 이름은 전체 파일 이름 + 크기 + 상태. 누르지 못하면 읽기만
    final Widget item = onPress != null && !error
        ? _PressBox(
            focusNode: itemNode,
            radius: _itemRadius,
            label: description,
            shrink: false,
            disabled: disabled,
            customActions: customActions,
            onTap: onPress,
            child: body,
          )
        : Semantics(
            container: true,
            label: description,
            child: ExcludeSemantics(child: body),
          );

    final Widget draggable = canDrag && !error
        ? RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: {
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(
                    () => LongPressGestureRecognizer(
                      duration: kAttachmentDragDelay,
                    ),
                    (r) {
                      r.onLongPressStart = (d) =>
                          onDragStart?.call(d.globalPosition);
                      r.onLongPressMoveUpdate = (d) =>
                          onDragMove?.call(d.globalPosition);
                      r.onLongPressEnd = (_) => onDragEnd?.call();
                      r.onLongPressCancel = () => onDragCancel?.call();
                    },
                  ),
            },
            child: item,
          )
        : item;

    final stack = _OverflowStack(
      children: [
        SizedBox(width: width + rightBleed, height: d.tile + _touchBleed),
        Positioned(top: _touchBleed, left: 0, child: draggable),
        if (error)
          Positioned(
            top: _touchBleed,
            left: 0,
            width: width,
            height: d.tile,
            child: ClipPath(
              clipper: const _HoleClipper(radius: _itemRadius),
              child: _PressBox(
                key: const ValueKey('attachment-retry'),
                radius: _itemRadius,
                label:
                    dsL(context)?.dsAttachRetryNamed(entry.name) ??
                    '${entry.name} 다시 시도',
                disabled: disabled,
                shrink: true,
                onTap: onRetry ?? () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: PSpacing.x1,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        LucideIcons.rotateCw,
                        size: _actionIcon,
                        color: image ? c.staticWhite : c.fgNeutralSubtle,
                      ),
                    ),
                    ExcludeSemantics(
                      child: Text(
                        dsL(context)?.dsAttachRetry ?? '다시 시도',
                        maxLines: 1,
                        softWrap: false,
                        style: PTypography.t2.copyWith(
                          fontWeight: FontWeight.w500,
                          color: image ? c.staticWhite : c.fgNeutralSubtle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // × — 가운데가 오른쪽 위 모서리에서 안쪽 6. 누르는 44 는 보이는 원 둘레로 12 씩
        Positioned(
          top: _touchBleed + _maskOffset - _removeTouch / 2,
          left: width - _maskOffset - _removeTouch / 2,
          child: _RemoveTouch(
            enabled: !readOnly && !disabled,
            child: _RemoveButton(
              key: const ValueKey('attachment-remove'),
              focusNode: removeNode,
              label:
                  dsL(context)?.dsAttachRemoveNamed(entry.name) ??
                  '${entry.name} 지우기',
              blocked: readOnly,
              disabled: disabled,
              onTap: onRemove,
            ),
          ),
        ),
      ],
    );
    // 끄는 동안은 빈 자리 — 모습은 손가락을 따라가는 것이 대신한다(자리 · 제스처는 그대로 둔다)
    return Opacity(
      opacity: dragging ? 0 : 1,
      child: IgnorePointer(ignoring: dragging, child: stack),
    );
  }
}
