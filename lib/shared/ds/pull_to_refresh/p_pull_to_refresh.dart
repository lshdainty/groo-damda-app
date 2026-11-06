import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 문턱 — 당긴 거리가 88 을 넘으면 놓았을 때 새로 고친다(손가락으로 약 117). pull-to-refresh.yaml `root.threshold`.
const double kPullToRefreshThreshold = 88;

/// 당긴 거리 = 손가락 이동 × 0.75. pull-to-refresh.yaml `root.multiplier`.
const double kPullToRefreshMultiplier = 0.75;

/// 지금 돌고 있는 당겨서 새로 고침 수 — 그동안 난 조회 실패는 이 자리가 스낵바 "새로 고치지 못했어요." + [다시 시도] 로
/// 알리므로, 앱 공용 "새로 고치지 못했어요." 는 띄우지 않는다(같은 글이 두 번 뜨지 않게, I-wrap-b2b 2-1).
final ValueNotifier<int> pPullToRefreshInFlight = ValueNotifier<int>(0);

/// 지금 어디까지 왔는가 — 테스트와 호출부가 읽는다.
enum PPullToRefreshPhase { idle, pulling, ready, refreshing }

/// Pull To Refresh(당겨서 새로 고침) — 앱 화면(탭)의 목록 · 대시보드를 맨 위에서 아래로 당기면 같은 내용을 다시 받는다.
/// 수치 원본은 groo-design `specs/components/pull-to-refresh.yaml`(값은 `test/fixtures/design_spec/pull-to-refresh.json`).
/// 웹은 두지 않는다(폰 브라우저는 당기면 페이지를 다시 연다).
///
/// 지시자는 원판 없는 Progress Circle 24(neutral)다 — 영역 맨 위의 높이 88 칸 가운데에 내용과 겹친다.
/// - 당기는 동안 내용이 당긴 만큼(손가락 이동 × 0.75, 상한 없음) 내려오고, 원이 당긴 비율(당긴 거리 ÷ 88)만큼 채워지며
///   짙어진다. 지시자 칸도 따라 내려와 문턱에서 제자리에 선다. 처음 아래로 움직인 자리부터 세고 위로 되돌리면 0 에 머문다.
/// - 놓으면 문턱을 넘겼을 때 원이 돌고 내용이 88 로 300ms(d6 · enter)에 돌아가 [onRefresh] 가 끝날 때까지(성공 · 실패
///   모두) 머문다. 끝나면 300ms 에 제자리로. 문턱 전에 놓으면 그대로 제자리, 새로 고치지 않는다. 모션 줄이기면 바로.
/// - 새로 고치는 동안 끌기는 받지 않는다. 보던 내용은 그대로 둔다(스켈레톤으로 바꾸지 않는다). 실패하면 내용을 둔 채
///   Snackbar(critical + "다시 시도" — 누르면 같은 새로 고침을 다시)로 알린다.
/// - 쉬는 동안 · 당기는 동안 지시자는 보조 기술에 숨기고, 새로 고치는 동안만 "새로 고치는 중" 진행 표시로 읽힌다.
///
/// [child] 는 맨 위에 스크롤하는 것(ListView · CustomScrollView …)이다. 가장 바깥 세로 스크롤의 끌기만 센다 —
/// 가로로 넘기는 영역 · 안쪽 스크롤 · 끌어서 쓰는 줄(스와이프 · 순서 바꾸기)에서 시작한 끌기는 당기기가 아니다.
/// 안쪽 스크롤은 클램핑 + 항상 스크롤 가능으로 바뀐다(내용이 짧아도 당겨진다 · 늘어나는 효과는 이 부품이 대신 그린다).
/// [onRefresh] 는 새로 받기가 끝날 때 끝나야 한다 — 기다리지 않으면 원이 0.5초 만에 사라지고 내용은 아직 옛것이다.
class PPullToRefresh extends StatefulWidget {
  const PPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// 어느 스크롤의 알림을 셀지 — 기본은 가장 바깥(깊이 0).
  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<PPullToRefresh> createState() => PPullToRefreshState();
}

/// 상태 객체 — 테스트가 [state] 로 지금 단계를 읽는다.
@visibleForTesting
class PPullToRefreshState extends State<PPullToRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle;

  /// 내용이 내려온 거리(= 당긴 거리). 그림은 모두 이 값 하나에서 나온다.
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  PPullToRefreshPhase _state = PPullToRefreshPhase.idle;

  /// 손가락이 아래로 움직인 거리(배율 전). 처음 아래로 움직인 자리부터 센다.
  double _finger = 0;
  bool _tracking = false;
  Animation<double>? _settleAnim;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(vsync: this, duration: PDuration.d6);
  }

  PPullToRefreshPhase get state => _state;
  double get offset => _offset.value;

  @override
  void dispose() {
    _settle.dispose();
    _offset.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _setState(PPullToRefreshPhase next) {
    if (_state == next) return;
    setState(() => _state = next);
  }

  bool _onScroll(ScrollNotification n) {
    if (!widget.notificationPredicate(n)) return false;
    if (n.metrics.axis != Axis.vertical ||
        n.metrics.axisDirection != AxisDirection.down) {
      return false;
    }
    // 새로 고치는 동안 끌기는 받지 않는다
    if (_state == PPullToRefreshPhase.refreshing) return false;
    if (n is ScrollStartNotification) {
      _tracking = n.dragDetails != null && n.metrics.extentBefore == 0;
      if (_tracking) {
        _settle.stop();
        _finger = 0;
      }
    } else if (n is OverscrollNotification) {
      // 맨 위를 넘어 아래로 끈 만큼(overscroll < 0) 더하고, 위로 되돌리면 뺀다
      if (_tracking && n.dragDetails != null) _drag(-n.overscroll);
    } else if (n is ScrollUpdateNotification) {
      // 당겨 둔 채 위로 끌면 먼저 당긴 거리를 줄인다
      if (_tracking && n.dragDetails != null && _finger > 0) {
        _drag(-(n.scrollDelta ?? 0));
      }
    } else if (n is ScrollEndNotification) {
      if (_tracking) {
        _tracking = false;
        _release();
      }
    }
    return false;
  }

  void _drag(double delta) {
    _finger = math.max(0, _finger + delta);
    final pull = _finger * kPullToRefreshMultiplier;
    _offset.value = pull;
    _setState(
      pull >= kPullToRefreshThreshold
          ? PPullToRefreshPhase.ready
          : (pull > 0 ? PPullToRefreshPhase.pulling : PPullToRefreshPhase.idle),
    );
  }

  void _animateTo(double target, {VoidCallback? then}) {
    final from = _offset.value;
    if (_reduceMotion || from == target) {
      // 돌고 있던 이동(예: 88 로 가는 중)이 뒤늦게 이 값을 덮지 않게 먼저 세운다
      _settle.stop();
      _settleAnim?.removeListener(_onSettleTick);
      _offset.value = target;
      then?.call();
      return;
    }
    _settleAnim?.removeListener(_onSettleTick);
    _settleAnim = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(parent: _settle, curve: PEasing.enter),
    )..addListener(_onSettleTick);
    _settle
      ..value = 0
      ..animateTo(1).whenComplete(() => then?.call());
  }

  void _onSettleTick() => _offset.value = _settleAnim!.value;

  Future<void> _release() async {
    if (_state != PPullToRefreshPhase.ready) {
      // 문턱 전에 놓음 — 새로 고치지 않고 제자리로
      _animateTo(0, then: () => _setState(PPullToRefreshPhase.idle));
      _finger = 0;
      return;
    }
    _finger = 0;
    await _refresh();
  }

  /// 새로 고친다 — 내용이 88 에 머물고 [PPullToRefresh.onRefresh] 가 끝나면(성공 · 실패 모두) 제자리로. 실패하면 Snackbar.
  Future<void> _refresh() async {
    _setState(PPullToRefreshPhase.refreshing);
    _animateTo(kPullToRefreshThreshold);
    pPullToRefreshInFlight.value += 1;
    try {
      await widget.onRefresh();
    } catch (_) {
      if (mounted) _notifyFailed();
    } finally {
      pPullToRefreshInFlight.value -= 1;
    }
    if (!mounted) return;
    _animateTo(
      0,
      then: () {
        if (mounted) _setState(PPullToRefreshPhase.idle);
      },
    );
  }

  /// 다시 하면 되는 가벼운 실패 — ds Snackbar critical + "다시 시도"(snackbar.md:71). 고정 문구만(서버 글 금지, :128).
  /// 액션은 같은 새로 고침을 다시 부른다. 호스트가 없는 자리(일부 테스트)는 조용히 둔다.
  void _notifyFailed() {
    final l = dsL(context);
    PSnackbar.maybeOf(context)?.show(
      message: l?.dsPullToRefreshFailed ?? '새로 고치지 못했어요.',
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l?.dsCommonRetry ?? '다시 시도',
        onPressed: () {
          // 그 사이 다른 새로 고침이 돌고 있거나 끌고 있으면 겹쳐 돌리지 않는다
          if (mounted && _state == PPullToRefreshPhase.idle) _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context).copyWith(
      overscroll: false,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
    );
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ClipRect(
        child: Stack(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _offset,
              child: ScrollConfiguration(
                behavior: behavior,
                child: widget.child,
              ),
              builder: (context, offset, child) =>
                  Transform.translate(offset: Offset(0, offset), child: child),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: kPullToRefreshThreshold,
              child: IgnorePointer(
                child: ValueListenableBuilder<double>(
                  valueListenable: _offset,
                  builder: (context, offset, _) =>
                      _Indicator(offset: offset, state: _state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 지시자 칸 — 높이 88, 원 24 가운데. 칸은 내용을 따라 내려오다 문턱에서 제자리에 서고, 투명도는 당긴 거리 ÷ 88 이다.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.offset, required this.state});

  final double offset;
  final PPullToRefreshPhase state;

  @override
  Widget build(BuildContext context) {
    final fraction = (offset / kPullToRefreshThreshold).clamp(0.0, 1.0);
    final refreshing = state == PPullToRefreshPhase.refreshing;
    final circle = PProgressCircle(
      key: const ValueKey('pull-to-refresh-circle'),
      size: PProgressCircleSize.s24,
      value: refreshing ? null : fraction * 100,
      // 당기는 동안은 손가락을 바로 따라간다 — 값이 바뀔 때 300ms 로 따라 차지 않는다
      animateValue: false,
      semanticsLabel: dsL(context)?.dsPullToRefreshLabel ?? '새로 고치는 중',
    );
    return Transform.translate(
      offset: Offset(0, math.min(offset - kPullToRefreshThreshold, 0)),
      child: Opacity(
        opacity: fraction,
        child: Center(
          // 쉬는 동안 · 당기는 동안은 보조 기술에 숨긴다 — 새로 고치는 동안만 읽힌다
          child: ExcludeSemantics(excluding: !refreshing, child: circle),
        ),
      ),
    );
  }
}
