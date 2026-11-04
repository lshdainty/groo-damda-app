import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType, TextField;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';

/// 입력(PInput) · 여러 줄 입력(PTextarea)이 함께 받는 값 — 상태는 [PTextControlState].
///
/// [PField] 안이면 이름 · 설명 · 오류 · 필수 · 막힘 · 최대 글자 수를 Field 에서 받는다 — 여기 직접 준 값이 이긴다.
abstract class PTextControl extends StatefulWidget {
  const PTextControl({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.placeholder,
    this.onChanged,
    this.disabled,
    this.readOnly,
    this.invalid,
    this.semanticLabel,
    this.autofocus = false,
    this.inputFormatters,
  }) : assert(
         controller == null || initialValue == null,
         'controller 와 initialValue 는 함께 주지 않는다',
       );

  /// 값 — 없으면 안에서 만든다([initialValue] 로 시작한다).
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;

  /// 빈 칸의 예시 글 — 칸 이름 대신 쓰지 않는다("예: 개인 사유").
  final String? placeholder;

  /// 값이 바뀔 때 — 쓰기 · 지우기 버튼. 최대 글자 수가 있으면 자른 값이 온다(한글은 조합이 끝난 뒤).
  final ValueChanged<String>? onChanged;

  /// 비활성 — 값을 바꿀 수 없고 포커스도 받지 않는다. null 이면 Field 의 값.
  final bool? disabled;

  /// 읽기 전용 — 포커스 · 복사는 되고 값은 못 바꾼다. null 이면 Field 의 값.
  final bool? readOnly;

  /// 오류 — 안쪽 2px 빨강(포커스해도 그대로). null 이면 Field 의 값.
  final bool? invalid;

  /// 이름 — Field 밖에서 쓸 때(목록 위 검색칸). Field 안이면 Field 의 라벨이 이름이다.
  final String? semanticLabel;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
}

/// 입력 · 여러 줄 입력의 공통 상태 — 값 · 포커스 · Field 잇기 · 글자 수 · 의미 노드.
///
/// 글자 수는 자소로 센다(국기 이모지도 한 글자). 최대가 있으면 그 수에서 멈춘다 — 한글을 조합하는 동안에는 자르지
/// 않고, 조합이 끝나면 잘라 [PTextControl.onChanged] 로 보낸다(웹과 같다 — MaxLengthEnforcement
/// .truncateAfterCompositionEnds, 플랫폼마다 다르던 기본값을 하나로 둔다).
abstract class PTextControlState<W extends PTextControl> extends State<W> {
  /// 입력(예시 글 + TextField) — 상자의 여백을 누르면 이리로 넘긴다([editableHitArea]).
  final GlobalKey _editableKey = GlobalKey();
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  PFieldScope? _scope;
  bool _focused = false;
  String _text = '';
  bool _empty = true;
  int _count = 0;

  TextEditingController get controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.initialValue));

  FocusNode get focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  /// 둘레의 Field — 없으면 null.
  PFieldControlData? get field => _scope?.data;

  bool get disabled => widget.disabled ?? field?.disabled ?? false;
  bool get readOnly => widget.readOnly ?? field?.readOnly ?? false;
  bool get invalid => widget.invalid ?? field?.invalid ?? false;
  bool get focused => _focused;
  bool get isEmpty => _empty;
  int? get maxGraphemeCount => field?.maxGraphemeCount;

  /// 덧그리는 2px 의 색 — 오류면 빨강(포커스해도 그대로), 포커스면 짙은 선(읽기 전용이면 없다).
  Color? emphasisColor(PColors c) => invalid
      ? c.strokeCriticalSolid
      : focused && !readOnly
      ? c.strokeNeutralContrast
      : null;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleValue);
    focusNode.addListener(_handleFocus);
    _focused = focusNode.hasFocus;
    _text = controller.text;
    _empty = _text.isEmpty;
    _count = countGraphemes(_text);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = PFieldScope.maybeOf(context);
    if (scope?.link != _scope?.link) {
      _scope?.link.detach(focusNode);
      if (scope != null) {
        scope.link.attach(focusNode);
        scope.link.reportGraphemeCount(_count);
      }
    }
    _scope = scope;
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final old = oldWidget.controller ?? _ownController!;
      old.removeListener(_handleValue);
      if (widget.controller == null && _ownController == null) {
        _ownController = TextEditingController(text: old.text);
      }
      controller.addListener(_handleValue);
      _text = controller.text;
      _empty = _text.isEmpty;
      _count = countGraphemes(_text);
      _scope?.link.reportGraphemeCount(_count);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      final old = oldWidget.focusNode ?? _ownFocusNode!;
      old.removeListener(_handleFocus);
      _scope?.link.detach(old);
      focusNode.addListener(_handleFocus);
      _scope?.link.attach(focusNode);
      _focused = focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleValue);
    focusNode.removeListener(_handleFocus);
    _scope?.link.detach(focusNode);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _handleValue() {
    final text = controller.text;
    // 캐럿 · 선택만 바뀐 알림은 건너뛴다
    if (text == _text) return;
    _text = text;
    final count = countGraphemes(text);
    _scope?.link.reportGraphemeCount(count);
    // 빈 칸 ↔ 값(예시 글 · 지우기 버튼) · 글자 수(설명으로 읽는다)가 바뀔 때만 다시 그린다
    final changed =
        text.isEmpty != _empty || (maxGraphemeCount != null && count != _count);
    _empty = text.isEmpty;
    _count = count;
    if (changed) _markNeedsBuild();
  }

  void _handleFocus() {
    if (_focused == focusNode.hasFocus) return;
    _focused = focusNode.hasFocus;
    _markNeedsBuild();
  }

  /// 그리는 중(부모의 build 에서 값을 바꿨다)이면 그 프레임이 끝난 뒤에 다시 그린다.
  void _markNeedsBuild() {
    if (!mounted) return;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      scheduler.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  /// 입력이 상자를 채운다(웹 — 입력이 상자 높이를 채우고, 맨 앞 · 맨 뒤면 상자의 좌우 여백까지 차지한다).
  /// [child](상자 안 전체) 의 위아래 여백 · 바깥쪽 좌우 여백을 누르면 입력을 누른 것으로 넘긴다 — 캐럿이 누른 자리에
  /// 가장 가까운 곳에 놓이고 길게 누르기 · 끌기도 입력이 받는다. 앞 · 뒤에 붙이개가 있으면 그쪽 여백은 붙이개의
  /// 것이라 넘기지 않는다([extendStart] · [extendEnd] — 그 자리는 상자가 받아 포커스만 옮긴다).
  @protected
  Widget editableHitArea({
    required bool extendStart,
    required bool extendEnd,
    required Widget child,
  }) => _EditableHitArea(
    editableKey: _editableKey,
    extendStart: extendStart,
    extendEnd: extendEnd,
    child: child,
  );

  /// 상자를 눌렀다 — 붙이개 · 사이를 눌러도 입력으로 포커스가 간다.
  void focusFromBox() {
    if (disabled || focusNode.hasFocus) return;
    focusNode.requestFocus();
  }

  /// 값을 비우고 입력에 포커스를 둔다 — [PTextControl.onChanged] 로 빈 값을 보낸다.
  void clear() {
    controller.clear();
    widget.onChanged?.call('');
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  /// 입력의 설명 — 웹 aria-describedby 처럼 예시 글(빈 칸일 때) · 붙이개 글 · Field 의 설명 또는 오류 · 글자 수를 잇는다.
  String? semanticsHint(
    AppLocalizations l10n, {
    List<String?> affixes = const [],
  }) {
    final max = maxGraphemeCount;
    final placeholder = widget.placeholder;
    final message = field?.message;
    final parts = <String>[
      if (_empty && placeholder != null && placeholder.isNotEmpty) placeholder,
      for (final affix in affixes)
        if (affix != null && affix.isNotEmpty) affix,
      if (message != null && message.isNotEmpty) message,
      if (max != null) l10n.dsFieldCountSemantics(_count, max),
    ];
    return parts.isEmpty ? null : parts.join('\n');
  }

  /// 입력(TextField) — 이름 · 설명 · 필수 · 오류를 입력의 의미 노드에 싣고, 빈 칸이면 예시 글을 아래에 깐다.
  /// 테두리 · 바탕은 [PTextFrame] 이 그린다(TextField 의 장식은 쓰지 않는다).
  @protected
  Widget buildEditable({
    required TextStyle style,
    required TextStyle placeholderStyle,
    required bool multiline,
    int? minLines,
    int? maxLines = 1,
    bool expands = false,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
    TextInputAction? textInputAction,
    bool obscureText = false,
    ValueChanged<String>? onSubmitted,
    Iterable<String>? autofillHints,
    List<String?> describedAffixes = const [],
  }) {
    final l10n = AppLocalizations.of(context);
    final placeholder = widget.placeholder;
    final editable = Semantics(
      label: widget.semanticLabel ?? field?.label,
      hint: semanticsHint(l10n, affixes: describedAffixes),
      isRequired: (field?.required ?? false) ? true : null,
      validationResult: invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: null,
          style: style,
          // 캐럿은 글자색(fg-neutral) — 고른 글은 기기 기본 하이라이트(input.yaml value.caretColor, 2026-10-08).
          // 막힌 칸은 포커스를 받지 않아 캐럿이 없다
          cursorColor: context.colors.fgNeutral,
          enabled: !disabled,
          readOnly: readOnly,
          autofocus: widget.autofocus,
          minLines: minLines,
          maxLines: maxLines,
          expands: expands,
          keyboardType: keyboardType,
          textAlign: textAlign,
          textInputAction: textInputAction,
          obscureText: obscureText,
          // 가린 칸(비밀번호)은 자격증명 — 키보드 사전 · 추천 · 학습에 남기지 않는다
          autocorrect: obscureText ? false : null,
          enableSuggestions: !obscureText,
          enableIMEPersonalizedLearning: !obscureText,
          maxLength: maxGraphemeCount,
          maxLengthEnforcement:
              MaxLengthEnforcement.truncateAfterCompositionEnds,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          mouseCursor: disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.text,
        ),
      ),
    );
    final showPlaceholder =
        _empty && placeholder != null && placeholder.isNotEmpty;
    return Stack(
      key: _editableKey,
      children: [
        // 예시 글은 입력 아래에 — 캐럿이 글 위에 그려진다. 크기는 입력이 정한다(자리는 늘 두어 입력이 옮겨지지 않는다)
        Positioned.fill(
          child: showPlaceholder
              ? IgnorePointer(
                  child: ExcludeSemantics(
                    child: Align(
                      alignment: multiline
                          ? AlignmentDirectional.topStart
                          : AlignmentDirectional.centerStart,
                      child: Text(
                        placeholder,
                        maxLines: multiline ? null : 1,
                        softWrap: multiline,
                        overflow: multiline
                            ? TextOverflow.clip
                            : TextOverflow.ellipsis,
                        style: placeholderStyle,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        editable,
      ],
    );
  }
}

/// 상자 안의 누름을 입력으로 넘기는 자리 — [PTextControlState.editableHitArea].
class _EditableHitArea extends SingleChildRenderObjectWidget {
  const _EditableHitArea({
    required this.editableKey,
    required this.extendStart,
    required this.extendEnd,
    required super.child,
  });

  final GlobalKey editableKey;
  final bool extendStart;
  final bool extendEnd;

  @override
  _RenderEditableHitArea createRenderObject(BuildContext context) =>
      _RenderEditableHitArea(
        editableKey: editableKey,
        extendStart: extendStart,
        extendEnd: extendEnd,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEditableHitArea renderObject,
  ) {
    renderObject
      ..editableKey = editableKey
      ..extendStart = extendStart
      ..extendEnd = extendEnd
      ..textDirection = Directionality.of(context);
  }
}

class _RenderEditableHitArea extends RenderProxyBox {
  _RenderEditableHitArea({
    required this.editableKey,
    required this.extendStart,
    required this.extendEnd,
    required this.textDirection,
  });

  GlobalKey editableKey;
  bool extendStart;
  bool extendEnd;
  TextDirection textDirection;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    // 붙이개 · 지우기 · 입력을 바로 누른 것이 먼저다
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    final editable = editableKey.currentContext?.findRenderObject();
    if (editable is! RenderBox || !editable.attached || !editable.hasSize) {
      return false;
    }
    final offset = editable.localToGlobal(Offset.zero, ancestor: this);
    final box = offset & editable.size;
    final ltr = textDirection == TextDirection.ltr;
    final left = (ltr ? extendStart : extendEnd) ? 0.0 : box.left;
    final right = (ltr ? extendEnd : extendStart) ? size.width : box.right;
    if (position.dx < left || position.dx > right) return false;
    // 입력 안의 가장 가까운 점으로 — 사건의 자리는 그대로라 입력이 누른 자리에서 가장 가까운 글자를 고른다
    final hit = result.addWithPaintOffset(
      offset: offset,
      position: position,
      hitTest: (result, local) => editable.hitTest(
        result,
        position: Offset(
          local.dx.clamp(0, math.max(0, editable.size.width - 0.5)),
          local.dy.clamp(0, math.max(0, editable.size.height - 0.5)),
        ),
      ),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}

/// 입력칸의 상자 — 바탕 · 안쪽 1px 선 · 포커스 · 오류의 안쪽 2px(input.yaml · textarea.yaml 의 root).
///
/// 1px 선(stroke-neutral-weak)은 늘 있고, 2px 는 그 위에 덧그린다 — 굵어져도 내용이 밀리지 않는다(웹 ::after).
/// 2px 의 색만 d2 · easing 으로 나타나고 사라진다(두께는 바로 — SEED). 모션 줄이기면 바로 바뀐다.
/// 밑줄형은 아래 선만, 모서리 없이. 그리는 차례는 바탕 → 내용 → 1px → 2px 다.
class PTextFrame extends StatelessWidget {
  const PTextFrame({
    super.key,
    required this.underline,
    required this.radius,
    required this.background,
    required this.emphasis,
    required this.child,
  });

  final bool underline;
  final double radius;
  final Color background;

  /// 덧그리는 2px 의 색 — null 이면 없다(투명으로 사라진다).
  final Color? emphasis;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shape = underline ? null : BorderRadius.circular(radius);
    BoxBorder line(double width, Color color) => underline
        ? Border(
            bottom: BorderSide(color: color, width: width),
          )
        : Border.all(color: color, width: width);

    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: shape),
      child: TweenAnimationBuilder<Color>(
        tween: _PremultipliedColorTween(
          end: emphasis ?? const Color(0x00000000),
        ),
        duration: reduceMotion ? Duration.zero : PDuration.d2,
        curve: PEasing.easing,
        builder: (context, color, child) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: line(2, color),
            borderRadius: shape,
          ),
          child: child,
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: line(1, context.colors.strokeNeutralWeak),
            borderRadius: shape,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 색 사이 — 투명에서 나타날 때 그 색 그대로 진해진다(CSS 처럼 미리 곱한 알파로 섞는다 — 투명한 검정을 거치지 않는다).
class _PremultipliedColorTween extends Tween<Color> {
  _PremultipliedColorTween({super.end});

  @override
  Color lerp(double t) {
    final a = begin!;
    final b = end!;
    final alpha = (a.a + (b.a - a.a) * t).clamp(0.0, 1.0);
    if (alpha <= 0) return b.withValues(alpha: 0);
    double channel(double from, double to) =>
        (((from * a.a) + ((to * b.a) - (from * a.a)) * t) / alpha).clamp(
          0.0,
          1.0,
        );
    return Color.from(
      alpha: alpha,
      red: channel(a.r, b.r),
      green: channel(a.g, b.g),
      blue: channel(a.b, b.b),
    );
  }
}
