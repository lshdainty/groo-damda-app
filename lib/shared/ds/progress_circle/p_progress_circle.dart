import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 크기 — 24(요소 안, 두께 3) · 40(콘텐츠 영역 가운데, 두께 5). 부품 안의 원은 [PProgressCircle.inherit].
enum PProgressCircleSize { s24, s40 }

/// 톤 — neutral(기본) · brand(앱 첫 화면처럼 큰 전환점 하나) · staticWhite(사진 위 딤 · 짙은 채움 위).
enum PProgressCircleTone { neutral, brand, staticWhite }

/// Progress Circle — 작업이 진행 중임을 알리는 원. 구조는 SEED Progress Circle(2026-10-03), 수치 원본은
/// groo-design `specs/components/progress-circle.yaml`(값은 `test/fixtures/design_spec/progress-circle.json`
/// — 테스트가 위젯이 그 값과 같은지 본다). 웹(desk-front `src/shared/ds/progress-circle`)과 같은 모양 · 움직임이다.
///
///   size   s24(요소 안 — 섹션 제목 옆 · 목록 끝 · 올리는 항목 위) · s40(기본 — 콘텐츠 영역 가운데)
///   tone   neutral(원 stroke-neutral-solid · 트랙 stroke-neutral-subtle) · brand(원 stroke-brand-solid ·
///          트랙 bg-brand-weak-pressed) · staticWhite(흰 원 + 흰 30% 트랙)
///   value  없으면 값 없는 원 — 돈다. 있으면 12시부터 (value − min) ÷ (max − min) 만큼 시계 방향으로 채운다.
///          범위를 벗어난 값은 끝에서 멈춘다(0 ~ 5 중 3 이면 60%). 0 이면 호를 지운다(둥근 끝이 점으로 남지 않게)
///
/// 움직임 — 값 없는 원은 원 전체가 1.2초에 한 바퀴(cubic(0.35, 0.25, 0.65, 0.75)) 돌고, 같은 박자로 호 머리가
///   원둘레만큼 늘고(0 ~ 75%, cubic(0.35, 0, 0.65, 1)) 꼬리가 따라와 줄인다(33.33 ~ 100%, cubic(0.35, 0, 0.65, 0.6)).
///   값 있는 원은 값이 바뀔 때 채움이 d6(300ms) · enter 로 따라 찬다 — 처음 그릴 때와, 값 없는 원에서 바뀔 때는
///   움직이지 않고 그 자리에서 시작한다.
/// 모션 줄이기(기기의 애니메이션 끄기) — 돌지 않는다. 값 없는 원은 12시부터 3/4 고정 호, 값 있는 원은 바로 바뀐다(v104).
/// 접근성 — 이름(기본 "불러오는 중" — 기다리는 일을 알면 그 이름)과, 값 있는 원은 값 글(기본 반올림한 "40%").
///   부품 안의 장식([PProgressCircle.inherit] — Button 은 자기가 바쁘다고 알린다)은 읽지 않는다.
class PProgressCircle extends StatefulWidget {
  const PProgressCircle({
    super.key,
    PProgressCircleSize this.size = PProgressCircleSize.s40,
    PProgressCircleTone this.tone = PProgressCircleTone.neutral,
    this.value,
    this.min = 0,
    this.max = 100,
    this.semanticsLabel,
    this.valueText,
    this.animateValue = true,
  }) : diameter = null,
       thickness = null,
       trackColor = null,
       rangeColor = null;

  /// 놓인 부품이 지름 · 두께 · 색을 정한다(스펙 size · tone inherit) — Button 의 로딩 원(14 · 14 · 16 · 18,
  /// 두께 2). 장식이라 읽지 않는다.
  const PProgressCircle.inherit({
    super.key,
    required double this.diameter,
    required double this.thickness,
    required Color this.trackColor,
    required Color this.rangeColor,
    this.value,
    this.min = 0,
    this.max = 100,
  }) : size = null,
       tone = null,
       semanticsLabel = null,
       valueText = null,
       animateValue = true;

  final PProgressCircleSize? size;
  final PProgressCircleTone? tone;

  /// 없으면 값 없는 원(돈다), 있으면 12시부터 값만큼 채운다.
  final double? value;
  final double min;
  final double max;

  /// 기다리는 일 — 기본 "불러오는 중". 영어 · 세 점을 쓰지 않는다.
  final String? semanticsLabel;

  /// 값 있는 원의 값 글 — 기본 반올림한 "40%".
  final String? valueText;

  /// 값이 바뀔 때 채움이 d6 로 따라 차는지 — false 면 바로 바뀐다(손가락을 따라가는 당겨서 새로 고침).
  final bool animateValue;

  final double? diameter;
  final double? thickness;
  final Color? trackColor;
  final Color? rangeColor;

  bool get _decorative => size == null;

  @override
  State<PProgressCircle> createState() => _PProgressCircleState();
}

// 값 없는 원의 세 곡선(progress-circle.yaml motion) — 토큰에 없는 키프레임 곡선이라 여기 둔다(웹도 컴포넌트가 싣는다)
const Duration _spinPeriod = Duration(milliseconds: 1200);
const Cubic _rotateCurve = Cubic(0.35, 0.25, 0.65, 0.75);
const Cubic _headCurve = Cubic(0.35, 0, 0.65, 1);
const Cubic _tailCurve = Cubic(0.35, 0, 0.65, 0.6);

class _PProgressCircleState extends State<PProgressCircle>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _spinPeriod,
  );
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: PDuration.d6,
  );
  double _fillFrom = 0;
  double _fillTo = 0;
  bool _reduceMotion = false;

  bool get _determinate => widget.value?.isFinite ?? false;

  double get _fraction {
    final value = widget.value;
    if (value == null || !value.isFinite || widget.max <= widget.min) {
      return 0;
    }
    return ((value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    // 처음 그릴 때는 움직이지 않는다 — 채움이 바로 그 값이다
    _fillFrom = _fillTo = _fraction;
    _fill.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncSpin();
  }

  @override
  void didUpdateWidget(PProgressCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasDeterminate = oldWidget.value?.isFinite ?? false;
    final next = _fraction;
    if (!_determinate) {
      // 값 없는 원 — 다음에 값이 생기면 그 자리에서 시작한다
    } else if (!wasDeterminate || _reduceMotion || !widget.animateValue) {
      _fill.value = 1;
      _fillFrom = _fillTo = next;
    } else if (next != _fillTo) {
      _fillFrom = _shownFraction;
      _fillTo = next;
      _fill
        ..value = 0
        ..animateTo(1, curve: PEasing.enter);
    }
    _syncSpin();
  }

  double get _shownFraction => _fillFrom + (_fillTo - _fillFrom) * _fill.value;

  void _syncSpin() {
    final spin = !_determinate && !_reduceMotion;
    if (spin && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!spin && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final widget = this.widget;
    final (double diameter, double thickness) = switch (widget.size) {
      PProgressCircleSize.s24 => (24.0, 3.0),
      PProgressCircleSize.s40 => (40.0, 5.0),
      null => (widget.diameter!, widget.thickness!),
    };
    final (Color track, Color range) = switch (widget.tone) {
      PProgressCircleTone.neutral => (
        c.strokeNeutralSubtle,
        c.strokeNeutralSolid,
      ),
      PProgressCircleTone.brand => (c.bgBrandWeakPressed, c.strokeBrandSolid),
      PProgressCircleTone.staticWhite => (
        c.staticWhite.withValues(alpha: 0.3),
        c.staticWhite,
      ),
      null => (widget.trackColor!, widget.rangeColor!),
    };

    final painter = PProgressCirclePainter(
      thickness: thickness,
      track: track,
      range: range,
      arc: _determinate
          ? () => (start: 0.0, sweep: _shownFraction, rotation: 0.0)
          : _reduceMotion
          ? () => (start: 0.0, sweep: 0.75, rotation: 0.0)
          : () => _indeterminateArc(_spin.value),
      repaint: Listenable.merge([_spin, _fill]),
    );
    final circle = SizedBox.square(
      dimension: diameter,
      child: CustomPaint(painter: painter),
    );
    if (widget._decorative) return ExcludeSemantics(child: circle);

    return Semantics(
      label:
          widget.semanticsLabel ??
          AppLocalizations.of(context).dsProgressCircleLabel,
      value: _determinate
          ? (widget.valueText ?? formatProgress(_fraction * 100))
          : null,
      child: circle,
    );
  }
}

/// 그릴 호 — 시작 · 길이는 원둘레를 1 로, 회전은 바퀴로 잰다. 12시가 0 이다.
typedef PProgressCircleArc = ({double start, double sweep, double rotation});

/// 값 없는 원의 한 순간(t = 0 ~ 1) — 웹의 세 키프레임(회전 · 머리 · 꼬리)과 같은 식이다.
/// 길이는 원둘레를 1 로 잰다. 머리는 0 ~ 75% 에서 0 → 1, 꼬리는 33.33 ~ 100% 에서 0 → 1 로 간다.
/// 보이는 호는 [꼬리, min(1, 꼬리 + 머리)] 다(웹의 dasharray 머리 · dashoffset −꼬리).
PProgressCircleArc _indeterminateArc(double t) {
  final head = t < 0.75 ? _headCurve.transform(t / 0.75) : 1.0;
  final tail = t < 1 / 3 ? 0.0 : _tailCurve.transform((t - 1 / 3) / (2 / 3));
  return (
    start: tail,
    sweep: math.max(0, math.min(1, tail + head) - tail),
    rotation: _rotateCurve.transform(t),
  );
}

/// 원을 그린다 — 테스트가 지름 · 두께 · 색을 스펙 값과 맞추려고 밖에서 읽는다.
@visibleForTesting
class PProgressCirclePainter extends CustomPainter {
  PProgressCirclePainter({
    required this.thickness,
    required this.track,
    required this.range,
    required this.arc,
    super.repaint,
  });

  final double thickness;
  final Color track;
  final Color range;
  final PProgressCircleArc Function() arc;

  /// 지금 그릴 호 — 길이는 원둘레를 1 로 잰다.
  PProgressCircleArc get currentArc => arc();

  @override
  void paint(Canvas canvas, Size size) {
    // 선 가운데 반지름 = (지름 − 두께) ÷ 2 — 24 는 10.5, 40 은 17.5
    final radius = (size.shortestSide - thickness) / 2;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = track;
    canvas.drawCircle(center, radius, paint);

    final a = arc();
    // 0 이면 호를 지운다 — 둥근 끝이 점으로 남지 않게
    if (a.sweep <= 0) return;
    paint
      ..color = range
      ..strokeCap = StrokeCap.round;
    // 12시(−90°)에서 시계 방향으로
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + 2 * math.pi * (a.rotation + a.start),
      2 * math.pi * a.sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(PProgressCirclePainter old) =>
      old.thickness != thickness ||
      old.track != track ||
      old.range != range ||
      old.arc != arc;
}
