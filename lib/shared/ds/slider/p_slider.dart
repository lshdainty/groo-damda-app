import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';

// slider.yaml 의 값 — 토큰이 있는 값은 토큰으로 적는다.
const double _controlHeight = PTouch.min; // control.height 44 — 줄 전체가 누르는 자리
const double _trackHeight = 4; // track.height
const double _thumb = 20; // thumb.size
const double _thumbPressed = 24; // pressed 의 thumb.size(스케일이 아니라 크기)
const double _inset =
    _thumb / 2; // thumb.inset 10 — 손잡이 가운데는 트랙 끝에서 이만큼 들어온 자리까지
const double _tickWidth = 4; // tick.width
const double _rootPaddingTop = PSpacing.x6; // root.paddingTop 24 — 말풍선 자리
const double _rootGap = PSpacing.x0_5; // root.gap 2 — 손잡이 줄 ↔ 표식
const double _focusRingWidth = 2; // focusRing.width
const double _focusRingOffset = 2; // focusRing.offset
const double _arrowW = 8; // valueIndicator.arrowWidth
const double _arrowH = 6; // valueIndicator.arrowHeight
const double _indicatorMinWidth = 24; // valueIndicator.minWidth
// 짧게 누르기(Tap jump)와 끌기를 가르는 시간 · 거리 — dragStart 150ms · 3px
const Duration _holdTime = Duration(milliseconds: 150);
const double _moveSlop = 3;
// 말풍선 나타남 — enterScale 0.9 · enterOffsetY 5
const double _enterScale = 0.9;
const double _enterOffsetY = 5;

/// 막대 길이 식 — 손잡이 가운데가 트랙 끝에서 [_inset] 들어온 자리. 위젯과 테스트가 같은 식을 쓴다.
@visibleForTesting
double sliderCenterOf(double ratio, double width) =>
    _inset + ratio * math.max(0, width - _inset * 2);

/// 눈금 틈 — 양 끝을 뺀 단계 자리마다 폭 4 의 틈(트랙 · 채움을 끊는다). 구간이 2 ~ 5개일 때만.
@visibleForTesting
List<Rect> sliderTickGaps(double width, int intervals) => [
  for (var k = 1; k < intervals; k++)
    Rect.fromCenter(
      center: Offset(sliderCenterOf(k / intervals, width), _trackHeight / 2),
      width: _tickWidth,
      height: _trackHeight,
    ),
];

/// 구간((max − min) ÷ step)이 2 ~ 5개면 눈금 · 단계 표식. 6개 이상이면 눈금 없이 양 끝 표식만.
@visibleForTesting
int sliderDiscreteIntervals(double min, double max, double step) {
  final intervals = (max - min) / step;
  final rounded = intervals.round();
  if ((intervals - rounded).abs() > 1e-9) return 0;
  return rounded >= 2 && rounded <= 5 ? rounded : 0;
}

int _decimalsOf(double n) {
  final s = '$n';
  if (s.contains('e')) return 0;
  final at = s.indexOf('.');
  if (at < 0) return 0;
  final frac = s.substring(at + 1);
  return frac == '0' ? 0 : frac.length;
}

String _plain(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// Slider 의 키 — 방향키 한 단계 · Shift + 방향키 · PageUp · PageDown 10단계 · Home · End 는 끝(범위면 다른 손잡이까지).
@visibleForTesting
double? sliderKeyTarget({
  required LogicalKeyboardKey key,
  required bool shift,
  required bool rtl,
  required double value,
  required double step,
  required double low,
  required double high,
}) {
  final big = step * 10;
  final delta = shift ? big : step;
  if (key == LogicalKeyboardKey.arrowRight) {
    return value + (rtl ? -1 : 1) * delta;
  }
  if (key == LogicalKeyboardKey.arrowLeft) {
    return value + (rtl ? 1 : -1) * delta;
  }
  if (key == LogicalKeyboardKey.arrowUp) return value + delta;
  if (key == LogicalKeyboardKey.arrowDown) return value - delta;
  if (key == LogicalKeyboardKey.pageUp) return value + big;
  if (key == LogicalKeyboardKey.pageDown) return value - big;
  if (key == LogicalKeyboardKey.home) return low;
  if (key == LogicalKeyboardKey.end) return high;
  return null;
}

/// Slider — 정해진 범위에서 값을 끌어 고르는 컨트롤(예산 알림 임계값 · 별점). 구조는 SEED Slider(2026-10-09),
/// 수치 원본은 groo-design `specs/components/slider.yaml`(값은 `test/fixtures/design_spec/slider.json`). 웹(desk-front
/// `src/shared/ds/slider`)과 같은 값이다. 정확한 숫자 · 금액은 Input 이다.
///
/// 모양 — 손잡이 줄 44(줄 전체가 누르는 자리) 가운데에 트랙 4 `stroke-neutral-weak` · 채움 `fg-neutral` · 손잡이 20
///   `bg-neutral-inverted`(테두리 · 그림자 없음, 누르는 동안 24 — 스케일이 아니라 크기). 손잡이 가운데는 트랙 양 끝에서
///   10 들어온 자리까지만 간다. 위 24 는 말풍선 자리, 줄 아래 2 에 표식(양 끝 값 — 구간이 2 ~ 5개면 단계마다).
/// 눈금 — 구간이 2 ~ 5개면 단계 자리마다 트랙 · 채움을 끊는 틈 4 와 단계 표식. 6개 이상이면 눈금 없이 양 끝 표식.
/// 말풍선 — 끄는 동안 · 키보드 포커스일 때 손잡이 위(13 / 18 · 500, 위아래 4 · 좌우 8 · 모서리 6 · 아래 8 × 6 화살표).
///   트랙 끝에서는 상자만 안으로 밀린다. 트랙을 눌러 건너뛰기만 하면 뜨지 않는다.
/// 누르기 — 손잡이를 누르면 바로 끈다. 손잡이 밖을 누르면 가장 가까운 손잡이가 그 자리(가장 가까운 단계)로 150ms 에
///   건너뛰고, 150ms 넘게 누르고 있거나 3px 넘게 움직이면 끌기가 된다. 끄는 동안은 손가락을 1:1 로 따른다. 두 손잡이는
///   서로 넘지 않는다. 줄에서 시작한 누름은 스크롤에 넘기지 않는다(웹 touch-action: none).
/// 저장 — 손을 뗄 때 한 번 [onChangeEnd](값이 바뀌었을 때만). 키보드 · 접근성 동작은 한 번에 한 번. 요청 중이라고 스스로
///   막지 않는다. 끄는 동안 [onChanged] 는 화면만 바꾼다.
/// 접근성 — 손잡이가 슬라이더 역할로 이름(Field 라벨 · 범위면 "{라벨} 최소")과 값 글([formatValue] — "80%")을 읽고, 올리기 ·
///   내리기가 한 단계다. 말풍선 · 표식 · 머리 값은 숨긴다. 이름 자리에 값을 넣지 않는다.
/// 막힘 — 전용 색(트랙 bg-disabled · 채움 · 손잡이 · 표식 fg-disabled), 흐리게 하지 않는다. 오류는 모양을 바꾸지 않는다.
class PSlider extends StatelessWidget {
  const PSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.formatValue,
    this.label,
    this.disabled,
    this.bubbleSpace = true,
  }) : assert(max > min, '최댓값은 최솟값보다 커야 한다'),
       assert(step > 0, '단계는 0 보다 커야 한다');

  /// 위쪽 값 말풍선 자리(24) — 기본 켬. 머리 줄 바로 아래에 붙는 화면(알림 설정 예산 기준)이 끈다(웹 `!pt-0`).
  final bool bubbleSpace;

  final double value;

  /// 움직일 때마다 — 화면만 바꾼다. 막혔으면 null 이어도 된다.
  final ValueChanged<double>? onChanged;

  /// 손을 뗄 때 · 키마다 한 번(값이 바뀌었을 때만) — 바로 적용하는 저장은 여기서. 폼의 값이면 두지 않는다.
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final double step;

  /// 단위를 붙인 글("80%") — 값 읽기 · 말풍선 · 표식. 기본은 숫자 그대로.
  final String Function(double value)? formatValue;

  /// 손잡이 이름 — 칸 이름("예산 알림 임계값"). Field 안이면 Field 의 라벨.
  final String? label;

  /// 막힘 — 주지 않으면 Field 의 막힘.
  final bool? disabled;

  @override
  Widget build(BuildContext context) => _SliderCore(
    values: [value],
    onChanged: (v) => onChanged?.call(v[0]),
    onChangeEnd: (v) => onChangeEnd?.call(v[0]),
    min: min,
    max: max,
    step: step,
    formatValue: formatValue ?? _plain,
    label: label,
    disabled: disabled,
    bubbleSpace: bubbleSpace,
  );
}

/// 값 둘 — 두 손잡이 사이를 채운다. 손잡이 이름은 "{라벨} {thumbLabels}"(기본 "최소" · "최대").
class PRangeSlider extends StatelessWidget {
  const PRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.formatValue,
    this.label,
    this.disabled,
    this.thumbLabels,
  }) : assert(max > min, '최댓값은 최솟값보다 커야 한다'),
       assert(step > 0, '단계는 0 보다 커야 한다');

  /// [최소, 최대]
  final (double, double) values;
  final ValueChanged<(double, double)>? onChanged;
  final ValueChanged<(double, double)>? onChangeEnd;
  final double min;
  final double max;
  final double step;
  final String Function(double value)? formatValue;
  final String? label;
  final bool? disabled;

  /// 범위 손잡이 이름 `[작은 쪽, 큰 쪽]` — 주지 않으면 로케일 문구("최소" · "최대").
  final List<String>? thumbLabels;

  @override
  Widget build(BuildContext context) => _SliderCore(
    values: [values.$1, values.$2],
    onChanged: (v) => onChanged?.call((v[0], v[1])),
    onChangeEnd: (v) => onChangeEnd?.call((v[0], v[1])),
    min: min,
    max: max,
    step: step,
    formatValue: formatValue ?? _plain,
    label: label,
    disabled: disabled,
    thumbLabels: thumbLabels,
  );
}

/// 머리 값 — Field 머리 오른쪽의 지금 값(16 / 22 · 700 · 고정폭 숫자). 늘 보이고 보조 기술에는 숨긴다(값은 손잡이가 읽는다).
class PSliderValue extends StatelessWidget {
  const PSliderValue(this.text, {super.key, this.disabled});

  final String text;

  /// 막힘 — 주지 않으면 Field 의 막힘.
  final bool? disabled;

  @override
  Widget build(BuildContext context) {
    final off =
        disabled ?? PFieldScope.maybeOf(context)?.data.disabled ?? false;
    return ExcludeSemantics(
      child: Text(
        text,
        style: PTypography.t5.copyWith(
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: off ? context.colors.fgDisabled : context.colors.fgNeutral,
        ),
      ),
    );
  }
}

class _SliderCore extends StatefulWidget {
  const _SliderCore({
    required this.values,
    required this.onChanged,
    required this.onChangeEnd,
    required this.min,
    required this.max,
    required this.step,
    required this.formatValue,
    required this.label,
    required this.disabled,
    this.thumbLabels,
    this.bubbleSpace = true,
  });

  final bool bubbleSpace;
  final List<double> values;
  final ValueChanged<List<double>> onChanged;
  final ValueChanged<List<double>> onChangeEnd;
  final double min;
  final double max;
  final double step;
  final String Function(double) formatValue;
  final String? label;
  final bool? disabled;
  final List<String>? thumbLabels;

  @override
  State<_SliderCore> createState() => _SliderCoreState();
}

/// 손을 대고 있는 동안의 상태.
class _Interaction {
  _Interaction({
    required this.pointer,
    required this.index,
    required this.offset,
    required this.downX,
    required this.startValues,
    required this.dragging,
  });

  final int pointer;

  /// 움직이는 손잡이 — 두 손잡이가 같은 자리에서 눌렸으면 첫 움직임의 방향으로 정한다(-1).
  int index;

  /// 손잡이를 잡은 자리 ↔ 손잡이 가운데 — 잡은 자리가 손가락 밑에 그대로 남는다.
  final double offset;
  final double downX;
  final List<double> startValues;
  bool dragging;
  Timer? timer;
}

class _SliderCoreState extends State<_SliderCore> {
  // 손을 대는 동안의 값 — 렌더한 값으로 맞춰 두고, 이벤트가 바꾼 값은 다음 렌더 전까지 여기에 둔다.
  late List<double> _latest = widget.values;
  _Interaction? _it;
  int? _dragging;
  int? _keyboard;
  int _top = 0;
  late final List<FocusNode> _nodes = [
    for (var i = 0; i < widget.values.length; i++)
      FocusNode(debugLabel: 'p-slider-thumb-$i'),
  ];
  double _width = 0;

  bool get _range => widget.values.length > 1;
  double get _span => widget.max - widget.min;
  int get _precision =>
      math.max(_decimalsOf(widget.step), _decimalsOf(widget.min));

  @override
  void didUpdateWidget(_SliderCore old) {
    super.didUpdateWidget(old);
    if (_it == null) _latest = widget.values;
  }

  @override
  void dispose() {
    _it?.timer?.cancel();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  double _ratio(double v) =>
      _span > 0 ? (v.clamp(widget.min, widget.max) - widget.min) / _span : 0;

  double _snap(double v) {
    final k = ((v - widget.min) / widget.step).round();
    final snapped = double.parse(
      (widget.min + k * widget.step).toStringAsFixed(_precision),
    );
    return snapped.clamp(widget.min, widget.max).toDouble();
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// 손잡이 줄의 시작 쪽(LTR 왼쪽 · RTL 오른쪽)에서 잰 거리.
  double _logicalX(double dx) => _rtl ? _width - dx : dx;

  double _valueAt(double x) {
    final p = _width > _inset * 2
        ? ((x - _inset) / (_width - _inset * 2)).clamp(0.0, 1.0)
        : 0.0;
    return _snap(widget.min + p * _span);
  }

  double _centerOf(double v) => sliderCenterOf(_ratio(v), _width);

  /// 한 손잡이를 옮긴 값들 — 두 손잡이는 서로를 넘지 않는다.
  List<double> _withValue(int index, double v) {
    final cur = _latest;
    final lo = index > 0 ? cur[index - 1] : widget.min;
    final hi = index < cur.length - 1 ? cur[index + 1] : widget.max;
    final next = [...cur];
    next[index] = _snap(v).clamp(lo, hi).toDouble();
    return next;
  }

  bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _emit(List<double> next) {
    if (_same(next, _latest)) return false;
    _latest = next;
    widget.onChanged(next);
    return true;
  }

  /// 누른 자리에서 가장 가까운 손잡이(같은 거리면 앞) — 겹쳐 있으면 정하지 않는다(-1, 첫 움직임의 방향으로).
  int _closest(double v) {
    final cur = _latest;
    if (cur.length == 1) return 0;
    final a = cur[0];
    final b = cur[1];
    if (a == b) return v < a ? 0 : (v > b ? 1 : -1);
    return (v - a).abs() <= (v - b).abs() ? 0 : 1;
  }

  bool get _disabled =>
      widget.disabled ?? PFieldScope.maybeOf(context)?.data.disabled ?? false;

  void _startDrag(_Interaction it) {
    it.dragging = true;
    it.timer?.cancel();
    setState(() => _dragging = it.index);
  }

  void _down(PointerDownEvent e) {
    if (_disabled || _it != null || e.buttons > 1) return;
    final x = _logicalX(e.localPosition.dx);
    final start = _latest;
    // 손잡이를 누르면 바로 끈다 — 잡은 자리를 그대로 둔다. 위에 그려진 손잡이가 먼저 잡히고,
    // 겹쳐 있으면 첫 움직임의 방향으로 정한다.
    final order = [
      _top.clamp(0, start.length - 1),
      for (var k = 0; k < start.length; k++)
        if (k != _top.clamp(0, start.length - 1)) k,
    ];
    final dy = (e.localPosition.dy - _controlHeight / 2).abs();
    for (final i in order) {
      final c = _centerOf(start[i]);
      if ((x - c).abs() <= _thumb / 2 && dy <= _thumb / 2) {
        final coincide = start.length > 1 && start[0] == start[1];
        _it = _Interaction(
          pointer: e.pointer,
          index: coincide ? -1 : i,
          offset: x - c,
          downX: x,
          startValues: start,
          dragging: true,
        );
        setState(() {
          _top = i;
          _dragging = coincide ? null : i;
          _keyboard = null;
        });
        return;
      }
    }
    // 손잡이 밖 — 가장 가까운 손잡이가 그 자리로 건너뛴다(150ms). 그대로 누르고 있거나 움직이면 끌기.
    final v = _valueAt(x);
    final index = _closest(v);
    final it = _Interaction(
      pointer: e.pointer,
      index: index,
      offset: 0,
      downX: x,
      startValues: start,
      dragging: false,
    );
    _it = it;
    setState(() => _keyboard = null);
    if (index >= 0) {
      setState(() => _top = index);
      _emit(_withValue(index, v));
      it.timer = Timer(_holdTime, () {
        if (_it == it && !it.dragging) _startDrag(it);
      });
    }
  }

  void _move(PointerMoveEvent e) {
    final it = _it;
    if (it == null || e.pointer != it.pointer) return;
    final x = _logicalX(e.localPosition.dx);
    // 짧은 떨림은 끌기가 아니다 — 겹친 두 손잡이는 방향이 뚜렷해질 때까지 기다린다.
    if ((!it.dragging || it.index < 0) && (x - it.downX).abs() < _moveSlop) {
      return;
    }
    if (it.index < 0) {
      it.index = x < it.downX ? 0 : 1;
      setState(() {
        _top = it.index;
        _dragging = it.index;
      });
    }
    if (!it.dragging) _startDrag(it);
    _emit(_withValue(it.index, _valueAt(x - it.offset)));
  }

  void _end(PointerEvent e) {
    final it = _it;
    if (it == null || e.pointer != it.pointer) return;
    it.timer?.cancel();
    _it = null;
    setState(() => _dragging = null);
    // 손을 뗄 때 한 번 — 값이 바뀌었을 때만
    if (!_same(_latest, it.startValues)) widget.onChangeEnd(_latest);
  }

  /// 키 · 접근성 동작 하나 — 키마다 한 번 commit.
  void _step(int index, double target) {
    final next = _withValue(index, target);
    setState(() {
      _keyboard ??= index;
      _top = index;
    });
    if (_emit(next)) widget.onChangeEnd(next);
  }

  KeyEventResult _onKey(int index, KeyEvent e) {
    if (_disabled || e is KeyUpEvent) return KeyEventResult.ignored;
    final cur = _latest;
    final target = sliderKeyTarget(
      key: e.logicalKey,
      shift: HardwareKeyboard.instance.isShiftPressed,
      rtl: _rtl,
      value: cur[index],
      step: widget.step,
      low: index > 0 ? cur[index - 1] : widget.min,
      high: index < cur.length - 1 ? cur[index + 1] : widget.max,
    );
    if (target == null) return KeyEventResult.ignored;
    _keyboard = index;
    _step(index, target);
    return KeyEventResult.handled;
  }

  String _thumbName(BuildContext context, int i) {
    final base = widget.label ?? PFieldScope.maybeOf(context)?.data.label;
    if (!_range) return base ?? '';
    final part = widget.thumbLabels != null && i < widget.thumbLabels!.length
        ? widget.thumbLabels![i]
        : (i == 0
              ? (Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    )?.dsSliderMin ??
                    '최소')
              : (Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    )?.dsSliderMax ??
                    '최대'));
    return base == null ? part : '$base $part';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = _disabled;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final intervals = sliderDiscreteIntervals(
      widget.min,
      widget.max,
      widget.step,
    );
    final markers = intervals > 0
        ? [
            for (var k = 0; k <= intervals; k++)
              double.parse(
                (widget.min + k * widget.step).toStringAsFixed(_precision),
              ),
          ]
        : [widget.min, widget.max];
    final values = _it == null ? widget.values : _latest;
    final message = PFieldScope.maybeOf(context)?.data.message;

    return Padding(
      padding: EdgeInsets.only(top: widget.bubbleSpace ? _rootPaddingTop : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: _rootGap,
        children: [
          SizedBox(
            height: _controlHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _width = constraints.maxWidth;
                final w = _width;
                final animate = _dragging == null && !reduce;
                return _SliderPress(
                  onDown: _down,
                  onMove: _move,
                  onEnd: _end,
                  enabled: !disabled,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 트랙 · 채움 · 눈금 틈
                      Positioned.fill(
                        child: _Eased(
                          values: [for (final v in values) _ratio(v)],
                          duration: animate ? PDuration.d3 : Duration.zero,
                          builder: (context, ratios) => CustomPaint(
                            key: const ValueKey('slider-track'),
                            painter: _TrackPainter(
                              ratios: ratios,
                              range: _range,
                              intervals: intervals,
                              track: disabled
                                  ? c.bgDisabled
                                  : c.strokeNeutralWeak,
                              fill: disabled ? c.fgDisabled : c.fgNeutral,
                              rtl: _rtl,
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < values.length; i++)
                        // 말풍선 — 상자 아래 끝이 손잡이 줄 위, 아래 8 × 6 화살표가 손잡이 가운데를 가리킨다.
                        // 줄 밖(위)에 그려져 누름을 받지 않는다.
                        Positioned(
                          top: -_bubbleBoxHeight,
                          left: 0,
                          width: w,
                          height: _bubbleBoxHeight + _arrowH,
                          child: IgnorePointer(
                            child: _Bubble(
                              key: ValueKey('slider-bubble-$i'),
                              shown:
                                  !disabled &&
                                  (_dragging == i || _keyboard == i),
                              reduce: reduce,
                              text: widget.formatValue(values[i]),
                              centerX: _rtl
                                  ? w - sliderCenterOf(_ratio(values[i]), w)
                                  : sliderCenterOf(_ratio(values[i]), w),
                            ),
                          ),
                        ),
                      for (var i = 0; i < values.length; i++)
                        _Thumb(
                          key: ValueKey('slider-thumb-$i'),
                          index: i,
                          value: values[i],
                          ratio: _ratio(values[i]),
                          width: w,
                          rtl: _rtl,
                          top: _top == i,
                          pressed: _dragging == i,
                          keyboard: _keyboard == i && !disabled,
                          disabled: disabled,
                          animate: animate,
                          reduce: reduce,
                          node: _nodes[i],
                          name: _thumbName(context, i),
                          hint: message,
                          text: widget.formatValue(values[i]),
                          up: widget.formatValue(
                            _withValue(i, values[i] + widget.step)[i],
                          ),
                          down: widget.formatValue(
                            _withValue(i, values[i] - widget.step)[i],
                          ),
                          onKey: (e) => _onKey(i, e),
                          onFocusChange: (f) {
                            if (!f && _keyboard == i) {
                              setState(() => _keyboard = null);
                            } else if (f &&
                                FocusManager.instance.highlightMode ==
                                    FocusHighlightMode.traditional) {
                              // Tab 으로 닿으면 바로 링 + 말풍선(키를 누르기 전에도)
                              setState(() => _keyboard = i);
                            }
                          },
                          onIncrease: () => _step(i, values[i] + widget.step),
                          onDecrease: () => _step(i, values[i] - widget.step),
                          formatValue: widget.formatValue,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 표식 — 양 끝 값(구간 2 ~ 5 면 단계마다). 보조 기술에는 숨긴다.
          ExcludeSemantics(
            child: SizedBox(
              height: PTypography.t3.fontSize! * PTypography.t3.height!,
              child: LayoutBuilder(
                builder: (context, constraints) => _Markers(
                  key: const ValueKey('slider-markers'),
                  texts: [for (final m in markers) widget.formatValue(m)],
                  width: constraints.maxWidth,
                  rtl: _rtl,
                  color: disabled ? c.fgDisabled : c.fgNeutralMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 값 목록의 애니메이션 — 건너뛰기는 150ms easing, 끄는 동안 · 모션 줄이기면 바로(손가락을 1:1 로 따른다).
class _Eased extends StatefulWidget {
  const _Eased({
    required this.values,
    required this.duration,
    required this.builder,
  });

  final List<double> values;
  final Duration duration;
  final Widget Function(BuildContext, List<double>) builder;

  @override
  State<_Eased> createState() => _EasedState();
}

class _EasedState extends State<_Eased> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late List<double> _from = widget.values;
  late List<double> _to = widget.values;

  @override
  void didUpdateWidget(_Eased old) {
    super.didUpdateWidget(old);
    if (listEquals(old.values, widget.values)) return;
    final shown = _current();
    _from = shown;
    _to = widget.values;
    if (widget.duration == Duration.zero) {
      _c.value = 1;
    } else {
      _c.duration = widget.duration;
      _c.forward(from: 0);
    }
  }

  List<double> _current() {
    final t = PEasing.easing.transform(_c.value);
    return [
      for (var i = 0; i < _to.length; i++)
        (i < _from.length ? _from[i] : _to[i]) +
            (_to[i] - (i < _from.length ? _from[i] : _to[i])) * t,
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(
      context,
      _c.isAnimating || _c.value < 1 ? _current() : _to,
    ),
  );
}

/// 줄 위의 누름을 곧바로 가져가는 인식기 — 손잡이 줄은 스크롤에 넘기지 않는다(웹 touch-action: none).
class _EagerPointerRecognizer extends OneSequenceGestureRecognizer {
  _EagerPointerRecognizer({
    required this.onDown,
    required this.onMove,
    required this.onEnd,
  });

  final void Function(PointerDownEvent) onDown;
  final void Function(PointerMoveEvent) onMove;
  final void Function(PointerEvent) onEnd;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onDown(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onMove(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      onEnd(event);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'p-slider-press';
}

class _SliderPress extends StatelessWidget {
  const _SliderPress({
    required this.onDown,
    required this.onMove,
    required this.onEnd,
    required this.enabled,
    required this.child,
  });

  final void Function(PointerDownEvent) onDown;
  final void Function(PointerMoveEvent) onMove;
  final void Function(PointerEvent) onEnd;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _EagerPointerRecognizer:
              GestureRecognizerFactoryWithHandlers<_EagerPointerRecognizer>(
                () => _EagerPointerRecognizer(
                  onDown: onDown,
                  onMove: onMove,
                  onEnd: onEnd,
                ),
                (r) {},
              ),
        },
        child: child,
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.ratios,
    required this.range,
    required this.intervals,
    required this.track,
    required this.fill,
    required this.rtl,
  });

  final List<double> ratios;
  final bool range;
  final int intervals;
  final Color track;
  final Color fill;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - _trackHeight) / 2;
    canvas.save();
    if (rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.translate(0, top);
    final shape = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, _trackHeight),
      const Radius.circular(PRounded.full),
    );
    // 눈금 — 트랙(채움 포함)을 틈으로 끊어 놓인 표면이 비친다.
    final clip = Path()..addRRect(shape);
    final gaps = sliderTickGaps(size.width, intervals);
    final cut = gaps.isEmpty
        ? clip
        : Path.combine(
            PathOperation.difference,
            clip,
            Path()..addPath(_gapsPath(gaps), Offset.zero),
          );
    canvas.clipPath(cut, doAntiAlias: true);
    canvas.drawRect(shape.outerRect, Paint()..color = track);
    final startX = range ? sliderCenterOf(ratios[0], size.width) : 0.0;
    final endX = sliderCenterOf(range ? ratios[1] : ratios[0], size.width);
    canvas.drawRect(
      Rect.fromLTRB(startX, 0, endX, _trackHeight),
      Paint()..color = fill,
    );
    canvas.restore();
  }

  Path _gapsPath(List<Rect> gaps) {
    final p = Path();
    for (final g in gaps) {
      p.addRect(g);
    }
    return p;
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      !listEquals(old.ratios, ratios) ||
      old.range != range ||
      old.intervals != intervals ||
      old.track != track ||
      old.fill != fill ||
      old.rtl != rtl;
}

class _Markers extends StatelessWidget {
  const _Markers({
    super.key,
    required this.texts,
    required this.width,
    required this.rtl,
    required this.color,
  });

  final List<String> texts;
  final double width;
  final bool rtl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = PTypography.t3.copyWith(color: color);
    final last = texts.length - 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var k = 0; k <= last; k++)
          if (k == 0)
            PositionedDirectional(
              start: 0,
              top: 0,
              child: Text(texts[k], style: style, softWrap: false),
            )
          else if (k == last)
            PositionedDirectional(
              end: 0,
              top: 0,
              child: Text(texts[k], style: style, softWrap: false),
            )
          else
            Positioned(
              left: (rtl
                  ? width - sliderCenterOf(k / last, width)
                  : sliderCenterOf(k / last, width)),
              top: 0,
              child: FractionalTranslation(
                translation: const Offset(-0.5, 0),
                child: Text(texts[k], style: style, softWrap: false),
              ),
            ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    super.key,
    required this.index,
    required this.value,
    required this.ratio,
    required this.width,
    required this.rtl,
    required this.top,
    required this.pressed,
    required this.keyboard,
    required this.disabled,
    required this.animate,
    required this.reduce,
    required this.node,
    required this.name,
    required this.hint,
    required this.text,
    required this.up,
    required this.down,
    required this.onKey,
    required this.onFocusChange,
    required this.onIncrease,
    required this.onDecrease,
    required this.formatValue,
  });

  final int index;
  final double value;
  final double ratio;
  final double width;
  final bool rtl;
  final bool top;
  final bool pressed;
  final bool keyboard;
  final bool disabled;
  final bool animate;
  final bool reduce;
  final FocusNode node;
  final String name;
  final String? hint;
  final String text;
  final String up;
  final String down;
  final KeyEventResult Function(KeyEvent) onKey;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final String Function(double) formatValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = pressed ? _thumbPressed : _thumb;
    final center = sliderCenterOf(ratio, width);
    final left = rtl ? width - center : center;
    final thumbDuration = reduce ? Duration.zero : PDuration.d3;

    return Positioned(
      left: left - _controlHeight / 2,
      top: 0,
      width: _controlHeight,
      height: _controlHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 키보드 포커스 링 — 손잡이 둘레 2px · 띄움 2px
          if (keyboard)
            IgnorePointer(
              child: Container(
                key: ValueKey('slider-ring-$index'),
                width: size + (_focusRingOffset + _focusRingWidth) * 2,
                height: size + (_focusRingOffset + _focusRingWidth) * 2,
                decoration: ShapeDecoration(
                  shape: CircleBorder(
                    side: BorderSide(
                      color: c.strokeFocusRing,
                      width: _focusRingWidth,
                    ),
                  ),
                ),
              ),
            ),
          Semantics(
            container: true,
            slider: true,
            enabled: !disabled,
            focusable: !disabled,
            label: name.isEmpty ? null : name,
            value: text,
            increasedValue: up,
            decreasedValue: down,
            hint: hint,
            onIncrease: disabled ? null : onIncrease,
            onDecrease: disabled ? null : onDecrease,
            child: Focus(
              focusNode: node,
              // Focus 자신의 읽기 노드를 만들지 않는다 — 위 Semantics 가 이름 · 값 · 동작을 다 가진 단 하나의 노드다
              // (03A-008: 이름 없는 초점 노드가 슬라이더 안에 하나 더 있었다)
              includeSemantics: false,
              canRequestFocus: !disabled,
              skipTraversal: disabled,
              onKeyEvent: (_, e) => onKey(e),
              onFocusChange: onFocusChange,
              child: AnimatedContainer(
                key: ValueKey('slider-thumb-dot-$index'),
                duration: thumbDuration,
                curve: PEasing.easing,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: disabled ? c.fgDisabled : c.bgNeutralInverted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const double _bubbleBoxHeight = 26; // 13 / 18 + 위아래 4

/// 말풍선 — 상자(13 / 18 · 500 · 고정폭 숫자) + 아래 화살표. 트랙 끝에서는 상자만 안으로 밀리고 화살표는 손잡이를 가리킨다.
/// 나타남 200ms enter(0.9배 · 투명 · 아래 5 에서), 사라짐 200ms easing. 모션 줄이기면 투명도만.
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.shown,
    required this.reduce,
    required this.text,
    required this.centerX,
  });

  final bool shown;
  final bool reduce;
  final String text;

  /// 층(손잡이 줄 폭)에서 손잡이 가운데.
  final double centerX;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: shown ? 1 : 0),
      duration: PDuration.d4,
      curve: shown ? PEasing.enter : PEasing.easing,
      builder: (context, t, child) {
        if (t == 0 && !shown) return const SizedBox.shrink();
        final scale = reduce ? 1.0 : _enterScale + (1 - _enterScale) * t;
        final dy = reduce ? 0.0 : _enterOffsetY * (1 - t);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: _BubbleBody(
        text: text,
        background: c.bgNeutralInverted,
        foreground: c.fgNeutralInverted,
        centerX: centerX,
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.text,
    required this.background,
    required this.foreground,
    required this.centerX,
  });

  final String text;
  final Color background;
  final Color foreground;
  final double centerX;

  @override
  Widget build(BuildContext context) {
    return _BubbleLayout(
      centerX: centerX,
      box: Container(
        key: const ValueKey('slider-bubble-box'),
        constraints: const BoxConstraints(minWidth: _indicatorMinWidth),
        padding: const EdgeInsets.symmetric(
          horizontal: PSpacing.x2,
          vertical: PSpacing.x1,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(PRounded.r1_5),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          softWrap: false,
          style: PTypography.t3.copyWith(
            color: foreground,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      arrow: CustomPaint(
        key: const ValueKey('slider-bubble-arrow'),
        size: const Size(_arrowW, _arrowH),
        painter: _ArrowPainter(background),
      ),
    );
  }
}

/// 상자는 가운데를 [centerX] 에 두되 층 안으로 밀고, 화살표는 [centerX] 그대로.
class _BubbleLayout extends StatelessWidget {
  const _BubbleLayout({
    required this.centerX,
    required this.box,
    required this.arrow,
  });

  final double centerX;
  final Widget box;
  final Widget arrow;

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
    delegate: _BubbleDelegate(centerX),
    children: [
      LayoutId(id: #box, child: box),
      LayoutId(id: #arrow, child: arrow),
    ],
  );
}

class _BubbleDelegate extends MultiChildLayoutDelegate {
  _BubbleDelegate(this.centerX);

  final double centerX;

  @override
  void performLayout(Size size) {
    final box = layoutChild(
      #box,
      BoxConstraints.loose(Size(size.width, size.height)),
    );
    final arrow = layoutChild(
      #arrow,
      BoxConstraints.tight(const Size(_arrowW, _arrowH)),
    );
    final left = (centerX - box.width / 2)
        .clamp(0.0, math.max(0.0, size.width - box.width))
        .toDouble();
    positionChild(#box, Offset(left, 0));
    positionChild(#arrow, Offset(centerX - arrow.width / 2, _bubbleBoxHeight));
  }

  @override
  bool shouldRelayout(_BubbleDelegate old) => old.centerX != centerX;
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // 8 × 6, 아래를 가리키고 끝을 둥글린다 — 웹 ARROW_PATH 와 같은 모양
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(8, 0)
      ..lineTo(4.67, 5)
      ..arcToPoint(const Offset(3.33, 5), radius: const Radius.circular(0.8))
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
