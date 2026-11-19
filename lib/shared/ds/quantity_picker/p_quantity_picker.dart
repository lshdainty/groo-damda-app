import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

// quantity-picker.yaml 의 large 값 — 앱은 늘 large(small 36 · medium 40 · responsive 는 웹 몫이다).
const double _height = 52; // root.height · button.size
const double _radius = PRounded.r3; // root.radius 12
const double _iconSize = 22; // icon.size
const double _circleThickness = 2; // progressCircle.thickness
const double _dividerHeight = PSpacing.x4; // divider.height 16
const double _valuePaddingX = PSpacing.x2; // value.paddingX 8
const double _ringWidth = 2; // focusRing.width
const double _ringOffset = 2; // focusRing.offset
const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

/// 값 칸 · 읽기 글 — 기본은 숫자 그대로.
typedef PQuantityValueText = String Function(int value);

/// 로딩 — 기다리는 버튼. [both] 는 두 버튼, 나머지는 한쪽만.
enum PQuantityLoading { none, decrement, increment, both }

/// 폭 — hug(기본, 값 칸이 가장 긴 값의 폭) · fill(부모의 남은 폭 — 늘어나는 것은 값 칸뿐).
enum PQuantityLayout { hug, fill }

String _defaultValueText(int value) => '$value';

/// Quantity Picker — 작은 정수를 한 단계씩 늘리고 줄이는 컨트롤. 구조는 SEED Quantity Picker(2026-10-15),
/// 수치 원본은 groo-design `specs/components/quantity-picker.yaml`(값은 `test/fixtures/design_spec/quantity-picker.json`
/// — 테스트가 위젯이 그 값과 같은지 본다). 웹(desk-front `src/shared/ds/quantity-picker`)과 같은 값이다.
/// 흔한 값이 열 단계 안쪽인 수(승인 필요 횟수 0 ~ 3 · 부여 시간 0 ~ 7시간)에 쓴다 — 더 멀거나 돈 · 소수면 Input 의 숫자 칸,
/// 띄엄띄엄 이름 붙은 값은 Select, 범위 안의 자리는 Slider 다.
///
/// 앱은 늘 large 52(최소 높이 — 큰 글자에서 값을 따라 높아지고 버튼은 52 그대로 세로 가운데) — 테두리 상자(모서리 12, 안쪽 1px stroke-neutral-weak) 안에 줄이기 · 선(1 × 16) · 값 · 선 · 늘리기.
///   버튼은 정사각 52 · 투명 · 아이콘 22(lucide minus · plus), 값 칸은 좌우 8 · t6(18/24) · 500 · 고정폭 숫자.
///   값 칸 폭은 가장 긴 표시 글([getValueText] 의 min · max · 지금 값) — max 를 주지 않으면 그 글은 뺀다.
///
/// 규칙
///   value · defaultValue · onValueChange   value 를 주면 쥐고 다룬다(부모가 받아 주기 전에는 바뀌지 않는다).
///                                          비제어의 처음 값은 기본 [min].
///   min(0) · max(기본 [maxSafeInteger] — 데이터로 건다) · step(1)
///   getValueText  값 칸 · 읽기 글("3회") — 단위는 이 글로만 붙인다. 제출 값은 단위 없는 정수다
///   loading       기다리는 버튼에 누름 바탕 + 값 없는 원(22, 두께 2), 그 버튼의 누르기를 버린다
///   removable + onRemove + removeSemanticLabel  — 최소에서 줄이기 자리가 휴지통(lucide trash-2)이 된다. 누르면 onRemove 만
///                 부르고 값은 바꾸지 않는다. 이름은 무엇을 지우는지("{항목} 지우기")
///   disabled · readOnly · invalid  Field 안이면 Field 의 값을 받는다(직접 준 값이 이긴다)
///   semanticLabel  묶음의 이름 — Field 안이면 Field 라벨이 이름이다(밖이면 필수)
///
/// 누르기 — 한 번 누르면 한 단계다. **길게 눌러도 반복하지 않고**(키보드 repeat 도 버린다) 화살표 키 · 값 칸 누르기 · 치기가 없다.
///   누른 버튼만 바탕 bg-layer-default-pressed + 2px 거리 축소(기준 52, 모션 줄이기면 하지 않는다).
///   끝(최소 · 최대)과 읽기 전용은 아이콘 fg-disabled(눌러도 바탕 · 축소 없음) — 웹의 aria-disabled 와 같이
///   초점은 남고 "사용할 수 없음"으로 읽는다. 막힘([disabled])은 두 버튼 초점에서도 빠지고 값도 fg-disabled(불투명도로 흐리지 않는다).
/// 오류([invalid]) — 안쪽 2px stroke-critical-solid(내용이 밀리지 않는다). 범위가 데이터로 바뀌어 값이 밖이면 값을 고치지 않고
///   이 모습으로 알린다.
/// 접근성 — 묶음은 이름 있는 그룹, 버튼은 "줄이기" · "늘리기"(바꿀 수 있다). 값 칸은 liveRegion — 바뀐 값을 단위와 함께 한 번 읽는다.
///   선 · 아이콘은 읽지 않는다.
class PQuantityPicker extends StatefulWidget {
  const PQuantityPicker({
    super.key,
    this.value,
    this.defaultValue,
    this.onValueChange,
    this.min = 0,
    this.max = maxSafeInteger,
    this.step = 1,
    this.layout = PQuantityLayout.hug,
    this.getValueText = _defaultValueText,
    this.loading = PQuantityLoading.none,
    this.disabled,
    this.readOnly,
    this.invalid,
    this.semanticLabel,
    this.decrementLabel,
    this.incrementLabel,
    this.removable = false,
    this.onRemove,
    this.removeSemanticLabel,
  }) : assert(
         !removable || (onRemove != null && removeSemanticLabel != null),
         'removable 은 onRemove · removeSemanticLabel 과 함께 쓴다',
       );

  /// 웹 Number.MAX_SAFE_INTEGER — max 를 주지 않은 표시.
  static const int maxSafeInteger = 9007199254740991;

  final int? value;
  final int? defaultValue;
  final ValueChanged<int>? onValueChange;
  final int min;
  final int max;
  final int step;
  final PQuantityLayout layout;
  final PQuantityValueText getValueText;
  final PQuantityLoading loading;
  final bool? disabled;
  final bool? readOnly;
  final bool? invalid;
  final String? semanticLabel;

  /// 줄이기 · 늘리기 버튼 이름 — 주지 않으면 로케일 문구("줄이기" · "늘리기").
  final String? decrementLabel;
  final String? incrementLabel;
  final bool removable;
  final VoidCallback? onRemove;
  final String? removeSemanticLabel;

  @override
  State<PQuantityPicker> createState() => _PQuantityPickerState();
}

class _PQuantityPickerState extends State<PQuantityPicker> {
  late int _inner = widget.defaultValue ?? widget.min;

  int get _value => widget.value ?? _inner;

  void _commit(int next) {
    if (next == _value) return;
    if (widget.value == null) setState(() => _inner = next);
    widget.onValueChange?.call(next);
  }

  bool _busy(bool decrement) => switch (widget.loading) {
    PQuantityLoading.none => false,
    PQuantityLoading.both => true,
    PQuantityLoading.decrement => decrement,
    PQuantityLoading.increment => !decrement,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = PFieldScope.maybeOf(context)?.data;
    final disabled = widget.disabled ?? field?.disabled ?? false;
    final readOnly = widget.readOnly ?? field?.readOnly ?? false;
    final invalid = widget.invalid ?? field?.invalid ?? false;
    final value = _value;
    final atMin = value <= widget.min;
    final atMax = value >= widget.max;
    final isRemove = widget.removable && atMin;
    // 끝 · 읽기 전용은 막힌 모습(초점은 남는다). 지우기는 최소에서도 누를 수 있다
    final decrementBlocked = readOnly || (atMin && !isRemove);
    final incrementBlocked = readOnly || atMax;

    final text = widget.getValueText(value);
    // 값 칸 폭 — 가장 긴 표시 글. max 를 주지 않았으면 그 글(16자리 수)은 뺀다
    final placeholders = <String>{
      widget.getValueText(widget.min),
      if (widget.max < PQuantityPicker.maxSafeInteger)
        widget.getValueText(widget.max),
    }..remove(text);

    final valueStyle = PTypography.t6.copyWith(
      fontWeight: FontWeight.w500,
      fontFeatures: _tabular,
      color: disabled ? c.fgDisabled : c.fgNeutral,
    );
    Widget cell(String t, {bool hidden = false}) => Opacity(
      opacity: hidden ? 0 : 1,
      child: Text(
        t,
        key: hidden ? null : const ValueKey('quantity-value-text'),
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: valueStyle,
      ),
    );
    final valueCell = Padding(
      padding: const EdgeInsets.symmetric(horizontal: _valuePaddingX),
      child: Semantics(
        container: true,
        liveRegion: true,
        label: text,
        excludeSemantics: true,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final p in placeholders) cell(p, hidden: true),
            cell(text),
          ],
        ),
      ),
    );

    Widget divider(int i) => ExcludeSemantics(
      child: Container(
        key: ValueKey('quantity-divider-$i'),
        width: 1,
        height: _dividerHeight,
        color: c.strokeNeutralSubtle,
      ),
    );

    final fill = widget.layout == PQuantityLayout.fill;
    final label = widget.semanticLabel ?? field?.label;
    final row = Row(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _QuantityButton(
          key: const ValueKey('quantity-decrement'),
          icon: isRemove ? LucideIcons.trash2 : LucideIcons.minus,
          label: isRemove
              ? widget.removeSemanticLabel!
              : (widget.decrementLabel ??
                    (Localizations.of<AppLocalizations>(
                          context,
                          AppLocalizations,
                        )?.dsQuantityDecrease ??
                        '줄이기')),
          blocked: decrementBlocked,
          disabled: disabled,
          busy: _busy(true),
          onPressed: () {
            if (isRemove) {
              widget.onRemove?.call();
            } else {
              _commit(math.max(value - widget.step, widget.min));
            }
          },
        ),
        divider(0),
        if (fill) Expanded(child: Center(child: valueCell)) else valueCell,
        divider(1),
        _QuantityButton(
          key: const ValueKey('quantity-increment'),
          icon: LucideIcons.plus,
          label:
              widget.incrementLabel ??
              (Localizations.of<AppLocalizations>(
                    context,
                    AppLocalizations,
                  )?.dsQuantityIncrease ??
                  '늘리기'),
          blocked: incrementBlocked,
          disabled: disabled,
          busy: _busy(false),
          onPressed: () => _commit(math.min(value + widget.step, widget.max)),
        ),
      ],
    );

    // 테두리는 바탕 위 · 버튼 아래에 그린다(웹 inset shadow) — 안쪽에 그려 내용이 밀리지 않는다
    final box = Semantics(
      container: true,
      label: label,
      hint: field?.message,
      enabled: !disabled,
      child: DecoratedBox(
        key: const ValueKey('quantity-root'),
        decoration: BoxDecoration(
          color: c.bgLayerDefault,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: invalid ? c.strokeCriticalSolid : c.strokeNeutralWeak,
            width: invalid ? 2 : 1,
          ),
        ),
        // 테두리는 안쪽에 그리고 버튼은 그 위를 덮는다. 높이 52 는 최소 높이 — 큰 글자에서 값이 높아지면 상자가 따라 높아지고,
        // − · + 버튼(52 정사각 px)은 크기를 그대로 두고 세로 가운데에 선다(quantity-picker.md "글자 크기 설정", groo-design #263)
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _height),
          child: row,
        ),
      ),
    );
    // hug — 세로 Flex(Field)가 폭을 늘려도 내용 폭을 지킨다(웹 w-fit)
    return fill
        ? box
        : Align(alignment: AlignmentDirectional.centerStart, child: box);
  }
}

/// 줄이기 · 늘리기 버튼 — 정사각 52. 올림 없음(터치) · 누름 · 키보드 초점 링은 그 버튼 하나에만 걸린다.
class _QuantityButton extends StatefulWidget {
  const _QuantityButton({
    super.key,
    required this.icon,
    required this.label,
    required this.blocked,
    required this.disabled,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String label;

  /// 끝 · 읽기 전용 — 막힌 모습이지만 초점은 남는다.
  final bool blocked;

  /// 컨트롤 전체 막힘 — 초점에서도 빠진다.
  final bool disabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  State<_QuantityButton> createState() => _QuantityButtonState();
}

class _QuantityButtonState extends State<_QuantityButton> {
  bool _pressed = false;
  bool _hasFocus = false;

  /// 링은 키보드 초점에만 — 터치로 눌러 생긴 초점에는 그리지 않는다.
  bool get _keyboardFocus =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  bool get _inert => widget.disabled || widget.blocked;

  void _activate() {
    if (widget.disabled || widget.blocked || widget.busy) return;
    widget.onPressed();
  }

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // 누름 바탕 — 로딩 중이거나 누르는 중(끝 · 막힘은 바탕 없음)
    final pressedFill = widget.busy || (_pressed && !_inert);
    final shrink = _pressed && !_inert && !widget.busy && !reduceMotion;
    final iconColor = _inert ? c.fgDisabled : c.fgNeutral;

    Widget glyph = widget.busy
        ? PProgressCircle.inherit(
            diameter: _iconSize,
            thickness: _circleThickness,
            trackColor: c.gray500,
            rangeColor: c.fgNeutral,
          )
        : Icon(widget.icon, size: _iconSize, color: iconColor);

    final box = TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: pressedFill ? c.bgLayerDefaultPressed : const Color(0x00000000),
      ),
      duration: PDuration.colorTransition,
      curve: PEasing.easing,
      builder: (context, bg, child) => Container(
        width: _height,
        height: _height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: child,
      ),
      child: glyph,
    );

    final scaled = AnimatedScale(
      scale: shrink ? (_height - 2) / _height : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: box,
    );

    // 키보드 초점 링 — 버튼 바깥 2px · 띄움 2px. 상자 밖으로 나가므로 자리를 차지하지 않고 겹쳐 그린다
    final withRing = Stack(
      clipBehavior: Clip.none,
      children: [
        scaled,
        if (_hasFocus && _keyboardFocus)
          Positioned(
            key: const ValueKey('quantity-focus-ring'),
            left: -(_ringOffset + _ringWidth),
            top: -(_ringOffset + _ringWidth),
            right: -(_ringOffset + _ringWidth),
            bottom: -(_ringOffset + _ringWidth),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    _radius + _ringOffset + _ringWidth,
                  ),
                  border: Border.all(
                    color: c.strokeFocusRing,
                    width: _ringWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      container: true,
      button: true,
      enabled: !widget.disabled && !widget.blocked,
      focusable: !widget.disabled,
      label: widget.label,
      onTap: _inert || widget.busy ? null : _activate,
      excludeSemantics: true,
      child: Focus(
        canRequestFocus: !widget.disabled,
        onFocusChange: (v) => setState(() => _hasFocus = v),
        onKeyEvent: (node, event) {
          final key = event.logicalKey;
          final activate =
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space;
          if (!activate || widget.disabled) return KeyEventResult.ignored;
          // 누르고 있어도 한 번 — 되풀이되는 키 이벤트는 삼킨다
          if (event is KeyDownEvent) _activate();
          return KeyEventResult.handled;
        },
        child: MouseRegion(
          cursor: widget.disabled || widget.blocked
              ? SystemMouseCursors.forbidden
              : widget.busy
              ? SystemMouseCursors.progress
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: _activate,
            child: withRing,
          ),
        ),
      ),
    );
  }
}
