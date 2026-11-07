import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

/// 모서리 — 화면 폭 사진 0 · 그림 자리 4 · 6 · 8(Image Frame — 폭으로) · 글 8 · 타일 12 · 카드 면 16 · 원 full.
enum PSkeletonRadius {
  /// 화면 끝에 붙는 사진(상세 위 사진)
  r0,

  /// 폭 24 이하의 그림 자리 — Image Frame 모서리
  r4,

  /// 폭 25 ~ 48 의 그림 자리 — 목록 앞 썸네일 40 · 48
  r6,

  /// 글 · 숫자 · 작은 조각 · 폭 49 이상의 그림 자리 — 기본
  r8,

  /// 목록 앞 타일 — List 타일 · Logo Tile 40
  r12,

  /// 카드 면 — Card 모양 자리 전체만
  r16,

  /// 아바타 · 원 아이콘 · 칩
  full,
}

/// 기다리는 영역의 시간표(skeleton.yaml 의 region) — 요청 설정에도 쓴다.
abstract final class PLoadingTiming {
  /// 처음 1초는 틀만 — 1초 안에 오면 아무것도 깜빡이지 않는다
  static const Duration showAfter = Duration(milliseconds: 1000);

  /// 오래 걸림 글을 더한다
  static const Duration slowAfter = Duration(milliseconds: 5000);

  /// 요청 제한 — 처음 요청부터 다시 시도까지 합쳐. 넘으면 끊고 실패
  static const Duration timeout = Duration(milliseconds: 10000);

  /// 저절로 다시 시도 — 읽기만 2번, 1초 · 2초 뒤(4xx 와 쓰기는 다시 보내지 않는다)
  static const List<Duration> retryDelays = [
    Duration(milliseconds: 1000),
    Duration(milliseconds: 2000),
  ];
}

/// Skeleton — 불러오는 동안 곧 나타날 내용 하나의 자리를 그리는 회색 면 + 그 위를 지나는 흰 띠. 구조는 SEED
/// Skeleton(2026-10-03), 수치 원본은 groo-design `specs/components/skeleton.yaml`(값은
/// `test/fixtures/design_spec/skeleton.json`). 웹(desk-front `src/shared/ds/skeleton`)과 같은 모양 · 박자다.
///
/// 면 — bg-neutral-weak. 흰 면(bg-layer-default · bg-layer-floating) 위에만 둔다 — 페이지 바탕과 같은 색이라
///   바탕 위에서는 사라진다. 글 자리는 [PSkeleton.text] — 높이가 그 글자의 줄 높이다(글로 바뀌어도 줄이 밀리지 않는다).
/// 반짝임 — 면과 같은 폭의 흰 띠(gradient-shimmer-neutral, 다크는 흰 10%)가 자기 폭만큼 왼쪽 밖에서 오른쪽 밖으로
///   loop(1.5초) · easing 으로 쉬지 않고 지난다. 같은 화면의 띠는 한 박자로 지난다 — 띠의 위치를 프레임 시계에서
///   구해 늦게 붙은 띠도 먼저 붙은 띠와 같은 자리를 지난다. 모션 줄이기면 띠를 지운다 — 면만 남는다.
/// 늘 보조 기술에 숨긴다 — 기다리는 상태는 [PLoadingRegion] 이 알린다.
class PSkeleton extends StatelessWidget {
  const PSkeleton({
    super.key,
    this.width,
    this.height,
    this.radius = PSkeletonRadius.r8,
  });

  /// 글 자리 — 높이를 그 글자의 줄 높이로(t4 14 → 19). 폭은 그 자리에 올 글 길이와 비슷하게.
  PSkeleton.text(
    TextStyle style, {
    super.key,
    this.width,
    this.radius = PSkeletonRadius.r8,
  }) : height = style.fontSize! * (style.height ?? 1);

  final double? width;
  final double? height;
  final PSkeletonRadius radius;

  /// 모서리(px).
  static double radiusOf(PSkeletonRadius radius) => switch (radius) {
    PSkeletonRadius.r0 => 0,
    PSkeletonRadius.r4 => PRounded.r1,
    PSkeletonRadius.r6 => PRounded.r1_5,
    PSkeletonRadius.r8 => PRounded.r2,
    PSkeletonRadius.r12 => PRounded.r3,
    PSkeletonRadius.r16 => PRounded.r4,
    PSkeletonRadius.full => PRounded.full,
  };

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radiusOf(radius)),
          child: DecoratedBox(
            decoration: BoxDecoration(color: context.colors.bgNeutralWeak),
            child: reduceMotion
                ? const SizedBox.expand()
                : _Shimmer(band: context.gradients.shimmerNeutral),
          ),
        ),
      ),
    );
  }
}

/// 반짝임 띠 — 프레임 시계에서 위치를 구한다(같은 화면의 띠가 한 박자로 지난다).
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.band});

  final LinearGradient band;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _phase = ValueNotifier(_now());

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _phase.value = _now())..start();
  }

  /// 0 ~ 1 — 지금 프레임 시각 ÷ loop 의 나머지. 모든 띠가 같은 값이다
  static double _now() {
    final stamp = SchedulerBinding.instance.currentFrameTimeStamp;
    final loop = PDuration.loop.inMicroseconds;
    return (stamp.inMicroseconds % loop) / loop;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: PSkeletonShimmerPainter(band: widget.band, phase: _phase),
      ),
    );
  }
}

/// 띠를 그린다 — 테스트가 띠의 위치 · 그라디언트를 밖에서 읽는다.
@visibleForTesting
class PSkeletonShimmerPainter extends CustomPainter {
  PSkeletonShimmerPainter({required this.band, required this.phase})
    : super(repaint: phase);

  final LinearGradient band;
  final ValueListenable<double> phase;

  /// 띠의 왼쪽 끝 — 면 폭에 대한 비율. −1(왼쪽 밖) → 1(오른쪽 밖), easing 으로
  double get offset => -1 + 2 * PEasing.easing.transform(phase.value);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(offset * size.width, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..shader = band.createShader(rect));
  }

  @override
  bool shouldRepaint(PSkeletonShimmerPainter old) =>
      old.band != band || old.phase != phase;
}

/// 기다린 시간 — 0 ~ 1초 quiet · 1초 ~ waiting · 5초 ~ slow.
enum PWaitPhase { quiet, waiting, slow }

/// 화면의 상태 글 — 앱 맨 위에 한 번 둔다. [PLoadingRegion] 들이 여기에 알리고, 한 번의 기다림(기다리는 영역이
/// 하나라도 있는 동안)에 같은 글은 한 번만 읽힌다 — 1초 "불러오는 중…", 5초 "평소보다 오래 걸리고 있어요.".
/// 다 오면 비우고 처음부터 센다. 실패 · 비어 있음은 Result Section 이 알린다.
class PLoadingAnnouncer extends StatefulWidget {
  const PLoadingAnnouncer({required this.child, super.key});

  final Widget child;

  static _PLoadingAnnouncerState? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AnnouncerScope>()?.announcer;

  @override
  State<PLoadingAnnouncer> createState() => _PLoadingAnnouncerState();
}

class _PLoadingAnnouncerState extends State<PLoadingAnnouncer> {
  final Map<Object, PWaitPhase> _phases = {};
  final Set<String> _said = {};

  /// 알림을 받지 않는 플랫폼(MediaQuery.supportsAnnounce 가 false — 안드로이드 등)에서 읽힐 글. 화면 밖 라이브
  /// 영역에 두면 글이 바뀔 때 읽힌다(Field 의 오류와 같은 길).
  String? _live;

  /// 라이브 영역 글을 바꾼다 — 영역의 빌드 · 정리 중에 불리므로 그 프레임이 끝난 뒤에 바꾼다.
  void _setLive(String? text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _live != text) setState(() => _live = text);
    });
  }

  /// 영역 하나가 기다리기를 멈췄다(다 왔다 · 실패 · 떠남). 모두 끝나면 다음 기다림은 처음부터 센다.
  /// 떠날 때는 새 글을 넣지 않는다 — 남은 영역의 글은 이미 읽혔다.
  void leave(Object region) {
    _phases.remove(region);
    if (_phases.isEmpty) {
      _said.clear();
      if (_live != null) _setLive(null);
    }
  }

  /// 5초 글을 화면에 보이는 영역인가 — 한 번의 기다림에서 맨 처음 알린 영역(화면 맨 위 영역)만. 나머지는 알림만 받는다.
  bool ownsSlowText(Object region) =>
      _phases.isEmpty || _phases.keys.first == region;

  /// 영역 하나의 기다림 — [context] 는 그 영역의 것(글 · 방향을 읽는다).
  void report(Object region, PWaitPhase phase, BuildContext context) {
    _phases[region] = phase;
    final l10n = AppLocalizations.of(context);
    final all = _phases.values;
    final next = all.contains(PWaitPhase.slow)
        ? l10n.dsLoadingSlow
        : all.contains(PWaitPhase.waiting)
        ? l10n.dsLoadingWaiting
        : null;
    // 같은 글은 한 번만
    if (next != null && _said.add(next)) {
      if (MediaQuery.supportsAnnounceOf(context)) {
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            next,
            Directionality.of(context),
          ),
        );
      } else {
        _setLive(next);
      }
    }
  }

  @override
  Widget build(BuildContext context) => _AnnouncerScope(
    announcer: this,
    // 앱 맨 위에 두므로 자리를 바꾸지 않는다 — 받은 제약을 그대로 넘기고(passthrough), 방향 없이 놓는다
    child: Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.passthrough,
      children: [
        widget.child,
        // 보이지 않는 상태 글 — 알림을 받지 않는 플랫폼에서만 쓴다
        if (_live != null)
          Positioned(
            left: 0,
            top: 0,
            width: 1,
            height: 1,
            child: Semantics(
              container: true,
              liveRegion: true,
              label: _live,
              child: const SizedBox.shrink(),
            ),
          ),
      ],
    ),
  );
}

class _AnnouncerScope extends InheritedWidget {
  const _AnnouncerScope({required this.announcer, required super.child});

  final _PLoadingAnnouncerState announcer;

  @override
  bool updateShouldNotify(_AnnouncerScope old) => old.announcer != announcer;
}

/// 기다리는 영역 — 데이터 자리 하나(쿼리 하나). skeleton.yaml 의 region.
///
///   pending   처음 받는 중 — 보일 내용이 아직 없다. 내용이 이미 있으면(다시 받는 중) false — 내용을 그대로 둔다
///   failed    내용 없이 실패 — [failure] 를 그린다(10초 요청 제한도 실패다)
///   fallback  기다리는 동안 — 스켈레톤(틀은 그리고 데이터 자리만). [PLoadingRegion.circle] 은 영역 가운데 원(40)
///   시간표 — 0 ~ 1초는 fallback 을 보이지 않게 그려 높이만 지키고, 1초부터 보이고, 5초부터 오래 걸림 글(t4 · 400 ·
///   fg-neutral-muted)을 스켈레톤 위(왼쪽 맞춤)나 원 아래(가운데 맞춤)에 16 띄워 더한다. 기다린 뒤 내용으로 바뀌면
///   투명도로 나타난다(d3 · enter, 모션 줄이기면 바로). 처음부터 내용이 있으면 그대로 보인다.
class PLoadingRegion extends StatefulWidget {
  const PLoadingRegion({
    super.key,
    required this.pending,
    this.failed = false,
    required Widget this.fallback,
    this.failure,
    this.showSlowText = true,
    required this.child,
  }) : inline = false;

  /// 기다리는 동안 영역 가운데 Progress Circle(40) — 구조를 미리 그릴 수 없는 화면 · 시트 · 카드 전체.
  const PLoadingRegion.circle({
    super.key,
    required this.pending,
    this.failed = false,
    this.failure,
    this.showSlowText = true,
    required this.child,
  }) : fallback = null,
       inline = false;

  final bool pending;
  final bool failed;

  /// null 이면 원(circle).
  final Widget? fallback;
  final Widget? failure;

  /// 5초에 오래 걸림 글을 화면에 더하는가. false 여도 보조 기술 알림([PLoadingAnnouncer])은 그대로 읽는다 —
  /// 화면에 보이는 5초 글은 주요 화면(홈 · 가계부 · 자산 · 통계 · 예산 · 캘린더)만 켜고 나머지는 B6 에서 정한다.
  final bool showSlowText;
  final Widget child;

  /// 값 조각용 — 줄 끝 · 칸 안 값 자리처럼 폭이 정해지지 않은 곳. 0 ~ 1초는 보이지 않게 그려 크기만 지키고 1초부터 보인다.
  /// 5초 글 · 보조 기술 알림은 없다(알림은 앱 맨 위 하나와 같은 화면의 다른 영역이 맡는다). 내용으로 바뀌어도 서서히 나타나지 않는다.
  const PLoadingRegion.inline({super.key, required Widget this.fallback})
    : pending = true,
      failed = false,
      failure = null,
      showSlowText = false,
      child = const SizedBox.shrink(),
      inline = true;

  final bool inline;

  @override
  State<PLoadingRegion> createState() => _PLoadingRegionState();
}

class _PLoadingRegionState extends State<PLoadingRegion> {
  PWaitPhase _phase = PWaitPhase.quiet;
  Timer? _show;
  Timer? _slow;
  Timer? _limit;
  _PLoadingAnnouncerState? _announcer;

  /// 요청 제한 10초에 닿았다 — 요청이 아직 안 끝났어도 기다림을 끊고 실패 자리를 보인다(내용이 오면 그 내용이 이긴다).
  bool _timedOut = false;

  /// 기다리는 모습을 그린 적이 있다 — 내용이 오면 투명도로 나타난다. 처음부터 내용이 있었으면 그대로 보인다
  bool _waited = false;

  bool get _waiting => widget.pending && !widget.failed && !_timedOut;

  @override
  void initState() {
    super.initState();
    _waited = _waiting || widget.failed;
    if (_waiting) _startClock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = PLoadingAnnouncer._maybeOf(context);
    if (next != _announcer) {
      _announcer?.leave(this);
      _announcer = next;
    }
    _report();
  }

  @override
  void didUpdateWidget(PLoadingRegion old) {
    super.didUpdateWidget(old);
    final wasWaiting = old.pending && !old.failed && !_timedOut;
    if (!widget.pending || widget.failed) {
      // 요청이 끝났다(내용이 왔거나 스스로 실패했다) — 10초 표시를 푼다
      _timedOut = false;
    }
    if (_waiting && !wasWaiting) {
      _startClock();
    } else if (!_waiting && wasWaiting) {
      _stopClock();
      _phase = PWaitPhase.quiet;
    }
    if (_waiting || widget.failed) _waited = true;
    _report();
  }

  void _startClock() {
    _stopClock();
    _phase = PWaitPhase.quiet;
    _timedOut = false;
    _show = Timer(PLoadingTiming.showAfter, () => _advance(PWaitPhase.waiting));
    _slow = Timer(PLoadingTiming.slowAfter, () => _advance(PWaitPhase.slow));
    // 처음 요청부터 10초가 지나면 실패로 — 실패 자리([PLoadingRegion.failure])가 없는 영역은 그대로 기다린다
    if (widget.failure != null) {
      _limit = Timer(PLoadingTiming.timeout, _giveUp);
    }
  }

  void _giveUp() {
    if (!mounted || !widget.pending || widget.failed) return;
    setState(() {
      _timedOut = true;
      _phase = PWaitPhase.quiet;
    });
    _report();
  }

  void _stopClock() {
    _show?.cancel();
    _slow?.cancel();
    _limit?.cancel();
  }

  void _advance(PWaitPhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
    _report();
  }

  void _report() {
    if (widget.inline) return;
    if (_waiting) {
      _announcer?.report(this, _phase, context);
    } else {
      _announcer?.leave(this);
    }
  }

  @override
  void dispose() {
    _stopClock();
    _announcer?.leave(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inline) {
      return Visibility(
        visible: _phase != PWaitPhase.quiet,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: widget.fallback!,
      );
    }
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final slow =
        _waiting &&
        _phase == PWaitPhase.slow &&
        widget.showSlowText &&
        (_announcer?.ownsSlowText(this) ?? true);
    final circle = widget.fallback == null;
    final slowText = Text(
      l10n.dsLoadingSlow,
      textAlign: circle ? TextAlign.center : TextAlign.start,
      style: PTypography.t4.copyWith(
        color: c.fgNeutralMuted,
        fontWeight: FontWeight.w400,
      ),
    );

    if (widget.failed || _timedOut) {
      return widget.failure ?? const SizedBox.shrink();
    }
    if (!_waiting) {
      if (!_waited || reduceMotion) return widget.child;
      // 기다린 뒤 — 투명도로 나타난다
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: PDuration.d3,
        curve: PEasing.enter,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: widget.child,
      );
    }

    final Widget body = circle
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: PSpacing.x4,
              children: [const PProgressCircle(), if (slow) slowText],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x4,
            children: [if (slow) slowText, widget.fallback!],
          );
    // 0 ~ 1초 — 그려 두되 보이지 않게(높이는 지킨다)
    return Visibility(
      visible: _phase != PWaitPhase.quiet,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: body,
    );
  }
}
