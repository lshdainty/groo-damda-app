import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/callout/feedback_parts.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 톤 — neutral(기본, 아이콘 없음) · positive(체크 — 성공을 눈에 띄게 알릴 때) · critical(느낌표 — 다시 하면 되는 가벼운
/// 실패). 아이콘 색만 바뀐다(짙은 띠 위에서 보이는 반전 짝 fg-*-inverted).
enum PSnackbarTone { neutral, positive, critical }

/// 액션 — 하나, 동작 이름 한두 마디("되돌리기" · "잔액 고치기"). "확인" · "취소" 로 뭉뚱그리지 않는다.
/// 누르면 그 일을 하고 띠를 닫는다. 띠는 시간이 지나면 사라지므로 같은 일을 할 다른 길(목록 · 상세)도 둔다.
class PSnackbarAction {
  const PSnackbarAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// 띄우고 닫는 쪽 — [PSnackbar.of] 가 돌려준다(웹 `useSnackbar()`). 돌려주는 것은 늘 같다.
abstract interface class PSnackbarApi {
  /// 띠를 띄운다 — 떠 있는 띠가 있으면 바로 바꾼다(한 번에 하나). 단 떠 있는 띠에 액션이 있으면 그 띠가 끝날 때까지 지키고 새 띠는
  /// 그 뒤에 온다. 기다리는 띠는 하나 — 그 사이(내보내는 중 포함) 또 오면 마지막 것만 남는다.
  ///
  /// [message] 는 해요체 문장 + 마침표, 무엇이 됐는지 먼저("거래를 저장했어요."). 서버가 보낸 글 · 영어 · 코드는 쓰지
  /// 않는다. [action] 이 있으면 6초, 없으면 4초.
  void show({
    required String message,
    PSnackbarTone tone = PSnackbarTone.neutral,
    PSnackbarAction? action,
  });

  /// 떠 있는 띠를 닫는다(기다리는 띠도 버린다).
  void dismiss();
}

/// Snackbar 를 띄우는 길 — 앱 맨 위에 [PSnackbarHost] 를 한 번 두고, 화면에서는 `PSnackbar.of(context).show(...)`.
///
/// ```dart
/// PSnackbar.of(context).show(message: '거래를 저장했어요.');
/// PSnackbar.of(context).show(
///   message: '거래를 삭제했어요.',
///   action: PSnackbarAction(label: '되돌리기', onPressed: () => restore(id)),
/// );
/// ```
abstract final class PSnackbar {
  /// 시간 — 액션이 없으면 4초(snackbar.yaml root.duration).
  static const Duration duration = Duration(milliseconds: 4000);

  /// 액션이 있으면 6초(사용자 결정 2026-10-02 — SEED 는 늘 4초).
  static const Duration durationWithAction = Duration(milliseconds: 6000);

  /// 가장 가까운 [PSnackbarHost] 의 띄우는 쪽. 없으면 어디에 호스트를 두는지 알려 준다.
  static PSnackbarApi of(BuildContext context) {
    final api = maybeOf(context);
    assert(
      api != null,
      'PSnackbar.of 는 PSnackbarHost 안에서 쓴다 — 앱 맨 위(MaterialApp.builder)에 PSnackbarHost 를 한 번 둔다.',
    );
    return api!;
  }

  /// 앱 맨 위 호스트의 키 — 딥링크 · 수명주기처럼 BuildContext 가 없는 자리가 띠를 띄우는 가장 작은 길.
  /// 앱의 [PSnackbarHost] 한 곳만 이 키를 단다(키는 트리에서 하나만 쓸 수 있다).
  static final GlobalKey<PSnackbarHostState> appHostKey =
      GlobalKey<PSnackbarHostState>(debugLabel: 'app snackbar host');

  static PSnackbarApi? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PSnackbarScope>()?.host;
}

// ── 치수(snackbar.yaml 공통) ───────────────────────────────────
const double _maxWidth = 464;
const double _minHeight = 44;
const double _padding = PSpacing.x2_5;
const double _radius = PRounded.r2;
const double _iconBox = 24;
const double _iconPaddingRight = PSpacing.x0_5;
const double _contentPaddingX = PSpacing.x1_5;
const double _contentGap = PSpacing.x2_5;
const double _regionPadding = PSpacing.x2;
const double _closeBox = 44;
const double _closeIcon = 16;
const double _actionSlopX = PSpacing.x2;

/// 띠를 띄울 때 한 번에 하나 — 떠 있는 띠 하나 + 그 뒤를 기다리는 것 하나.
class _Options {
  const _Options(this.message, this.tone, this.action);

  final String message;
  final PSnackbarTone tone;
  final PSnackbarAction? action;
}

class _Entry {
  const _Entry(this.id, this.options, {required this.open});

  final int id;
  final _Options options;
  final bool open;

  _Entry closed() => _Entry(id, options, open: false);
}

class _PSnackbarScope extends InheritedWidget {
  const _PSnackbarScope({required this.host, required super.child});

  final PSnackbarHostState host;

  // 호스트는 늘 같다 — 쓰는 쪽이 다시 그려질 까닭이 없다
  @override
  bool updateShouldNotify(_PSnackbarScope oldWidget) => false;
}

/// Snackbar 호스트(웹 `SnackbarProvider`) — 앱 맨 위에 한 번 둔다. 화면 아래 가운데 자리를 **화면 위**에 그린다.
///
/// 구조는 SEED Snackbar(2026-10-02), 수치 원본은 groo-design `specs/components/snackbar.yaml`(값은
/// `test/fixtures/design_spec/snackbar.json`). 웹(desk-front `src/shared/ds/snackbar`)과 같은 값이다.
///
/// ```dart
/// MaterialApp(builder: (context, child) => PSnackbarHost(closeLabel: l10n.close, child: child!))
/// ```
/// 호스트는 길잡이(Navigator) **바깥**에 선다 — 시트 · 대화상자 · 확인창도 길잡이 안이므로 띠가 그 위에 그려지고
/// (z L6, z-snackbar 400), 띠를 눌러도 그 창은 닫히지 않는다(바깥 누르기가 아니다).
///
/// 자리 — 어느 폭이든 화면 아래 가운데, 좌우 · 아래 8(+ 안전 영역). 아래는 안전 영역과 피할 자리(탭 바 · 바닥 버튼
/// · 떠 있는 버튼 — [PSnackbarAvoidOverlap]) 중 **큰 쪽**이다 — 둘을 더하지 않는다(SEED 와 다르다). 피할 자리가 옮겨
/// 가면 200ms 로 따라가고, 모션 줄이기면 바로 간다. 키보드가 올라와 있으면 그 위에 선다(웹의 화면 아래는 키보드
/// 위다).
///
/// 띠 — 짙은 바탕(bg-neutral-inverted, 다크는 밝은 띠) · 최소 44 · 여백 10 + 글 좌우 6 · 모서리 8 · **그림자 없음**
/// (면 색으로 뜬다) · 최대 464. 글은 t4 · 400 · 단어 단위 줄바꿈이고 줄을 자르지 않는다. 액션은 t4 · 700 — 누르는
/// 영역은 글 + 좌우 8 × 44, 누르면 글만 2px 거리 축소. 아이콘(positive · critical 에만)은 24 칸 · 그림 22.
///
/// 시간 — 4초, 액션이 있으면 6초. 마우스를 올리거나 · 손가락으로 누르고 있거나 · 키보드 초점이 띠 안에 있거나 ·
/// 스크린 리더 초점이 띠에 있으면 멈추고, 떠나면 처음부터 다시 센다. 한 번에 하나 — 새 [PSnackbarApi.show] 는 지금
/// 띠를 바로 내보내고(100ms) 새 띠를 띄운다. 액션을 누르면 그 일을 하고 닫는다. 뒤로 가기 · 밀기 · 글 누르기로는
/// 닫히지 않는다 — 시간 · 액션 · 보조 기술용 닫기로만.
///
/// 모션 — 나타남 150ms enter(가운데에서 0.8 → 1 + 투명도) · 사라짐 100ms exit. 모션 줄이기면 투명도만.
///
/// 접근성 — 띠는 라이브 영역(웹 role="status" + aria-atomic)이라 초점을 옮기지 않고 읽힌다. 보조 기술용 닫기 버튼
/// ([closeLabel])은 평소에 보이지 않고(읽힌다) 키보드 초점이 오면 띠 오른쪽 끝에 X 16 · 상자 44 로 보인다. 사라지는
/// 동안은 읽지 않는다. 초점이 띠 안에 있다가 닫히면 띠에 들어오기 전 자리로 돌려준다.
class PSnackbarHost extends StatefulWidget {
  const PSnackbarHost({
    super.key,
    required this.closeLabel,
    required this.child,
  });

  /// 보조 기술용 닫기 버튼의 이름("닫기") — 앱이 지역화해 넘긴다.
  final String closeLabel;
  final Widget child;

  @override
  State<PSnackbarHost> createState() => PSnackbarHostState();
}

class PSnackbarHostState extends State<PSnackbarHost>
    with WidgetsBindingObserver
    implements PSnackbarApi {
  _Entry? _entry;
  _Options? _pending;
  int _nextId = 1;
  double _avoidOffset = 0;
  bool _measureScheduled = false;
  final Set<_PSnackbarAvoidOverlapState> _avoided = {};

  /// 피할 자리를 지금 얼마나 띄우는지(화면 아래부터) — 테스트가 본다.
  @visibleForTesting
  double get avoidOffset => _avoidOffset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 창 크기 · 방향이 바뀌면 피할 자리를 다시 잰다(웹 resize)
  @override
  void didChangeMetrics() => _scheduleMeasure();

  /// 상태를 바꾼다 — 그리는 중에 불렸으면 그 프레임이 끝난 뒤에.
  void _update(VoidCallback change) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(change);
      });
      return;
    }
    setState(change);
  }

  @override
  void show({
    required String message,
    PSnackbarTone tone = PSnackbarTone.neutral,
    PSnackbarAction? action,
  }) {
    final options = _Options(message, tone, action);
    _update(() {
      final entry = _entry;
      if (entry == null) {
        _entry = _Entry(_nextId++, options, open: true);
        _pending = null;
        return;
      }
      // 지금 띠에 액션(되돌리기 · 다시 시도)이 있으면 그 띠가 끝날 때까지(시간 · 액션 · 닫기) 지키고 새 띠는 그 뒤에 온다.
      // 액션이 없으면 지금 띠를 내보내고 새 띠는 기다린다. 기다리는 띠는 하나 — 그 사이 또 오면 마지막 것만 남는다
      // (알림 결정 1B, I-04 19)
      if (entry.open && entry.options.action == null) _entry = entry.closed();
      _pending = options;
    });
    // 새 띠가 뜰 때도 다시 잰다 — 크기는 그대로 자리만 옮긴 바닥 요소가 있을 수 있다
    _scheduleMeasure();
  }

  @override
  void dismiss() => _update(() {
    final entry = _entry;
    if (entry != null && entry.open) _entry = entry.closed();
    _pending = null;
  });

  /// 그 띠만 닫는다 — 액션이 show() 를 불러 이미 새 띠를 기다리게 했으면 그대로 둔다.
  void _close(int id) => _update(() {
    final entry = _entry;
    if (entry != null && entry.id == id && entry.open) _entry = entry.closed();
  });

  /// 사라지는 모습이 끝났다 — 걷고, 기다리는 띠가 있으면 띄운다.
  void _exited(int id) => _update(() {
    final entry = _entry;
    if (entry == null || entry.id != id || entry.open) return;
    final pending = _pending;
    if (pending == null) {
      _entry = null;
      return;
    }
    _entry = _Entry(_nextId++, pending, open: true);
    _pending = null;
  });

  // ── 피할 자리 ───────────────────────────────────────────────
  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
  }

  /// 감싼 것들 중 가장 위 요소의 윗변에서 호스트 아래까지(띠는 그 위 8 — 자리의 아래 여백).
  void _measure() {
    _measureScheduled = false;
    if (!mounted) return;
    final hostBox = context.findRenderObject();
    if (hostBox is! RenderBox || !hostBox.hasSize) return;
    double? top;
    for (final target in _avoided) {
      if (!target.visible) continue;
      final box = target.context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      if (box.size.isEmpty) continue;
      final y = box.localToGlobal(Offset.zero, ancestor: hostBox).dy;
      top = top == null ? y : math.min(top, y);
    }
    final offset = top == null ? 0.0 : math.max(0.0, hostBox.size.height - top);
    if ((offset - _avoidOffset).abs() > 0.01) {
      setState(() => _avoidOffset = offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final media = MediaQuery.of(context);
    final safe = media.viewPadding;
    final reduceMotion = media.disableAnimations;
    // 아래 — 안전 영역 · 키보드 · 피할 자리 중 큰 쪽(더하지 않는다). 8 은 띠 아래 여백
    final bottom = math.max(
      math.max(safe.bottom, media.viewInsets.bottom),
      _avoidOffset,
    );

    return _PSnackbarScope(
      host: this,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (entry != null)
            AnimatedPositioned(
              duration: reduceMotion ? Duration.zero : PDuration.d4,
              curve: PEasing.easing,
              left: 0,
              right: 0,
              bottom: bottom,
              child: Padding(
                padding: EdgeInsets.only(
                  left: _regionPadding + safe.left,
                  right: _regionPadding + safe.right,
                  bottom: _regionPadding,
                ),
                child: _PSnackbarItem(
                  key: ValueKey(entry.id),
                  entry: entry,
                  host: this,
                  closeLabel: widget.closeLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 피할 자리(웹 `SnackbarAvoidOverlap`) — 화면 아래에 붙은 것(탭 바 · 바닥 버튼 · 떠 있는 버튼)을 감싼다. 띠는
/// 감싼 것들 중 가장 위 요소의 윗변 위 8 에 선다(안전 영역보다 높을 때).
///
/// 감싼 것이 붙고 · 떨어지고 · 크기가 바뀌고 · 창 크기가 바뀌고 · 새 띠가 뜰 때 다시 잰다(스크롤은 재지 않는다 —
/// 스크롤하는 본문은 감싸지 않는다). 지금 보이지 않는 길(위에 다른 길이 덮은 것)에 있으면 피하지 않는다.
/// 호스트 밖이면 아무것도 하지 않는다.
class PSnackbarAvoidOverlap extends StatefulWidget {
  const PSnackbarAvoidOverlap({super.key, required this.child});

  final Widget child;

  @override
  State<PSnackbarAvoidOverlap> createState() => _PSnackbarAvoidOverlapState();
}

class _PSnackbarAvoidOverlapState extends State<PSnackbarAvoidOverlap> {
  PSnackbarHostState? _host;

  /// 보이는지 — 위에 다른 길이 덮으면(애니메이션이 꺼진다) 거짓.
  bool visible = true;

  @override
  void initState() {
    super.initState();
    _host = context.getInheritedWidgetOfExactType<_PSnackbarScope>()?.host;
    _host?._avoided.add(this);
    _host?._scheduleMeasure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 시트 · 확인창이 위에 올라와 있으면 아래 화면의 버튼(FAB 등)은 가려져 있다 — 피할 자리로 세지 않는다
    final shown =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (shown != visible) {
      visible = shown;
      _host?._scheduleMeasure();
    }
  }

  @override
  void dispose() {
    _host?._avoided.remove(this);
    _host?._scheduleMeasure();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _host?._scheduleMeasure();
        return false;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }
}

/// 나타남은 enter, 사라짐은 exit 곡선 — 지금 가는 쪽을 따른다. CurvedAnimation 의 reverseCurve 는 처음 시작한 쪽을 끝까지
/// 붙들어(나타나는 중에 닫히면 사라짐에도 enter 곡선이 쓰인다) 쓰지 않는다.
class _DirectionalCurve extends Animation<double>
    with AnimationWithParentMixin<double> {
  _DirectionalCurve(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.status == AnimationStatus.reverse
      ? PEasing.exit.flipped.transform(parent.value)
      : PEasing.enter.transform(parent.value);
}

/// 띠 하나 — 시간 · 나타남 · 사라짐 · 멈춤 · 초점을 맡는다. 모양은 [_Band].
class _PSnackbarItem extends StatefulWidget {
  const _PSnackbarItem({
    super.key,
    required this.entry,
    required this.host,
    required this.closeLabel,
  });

  final _Entry entry;
  final PSnackbarHostState host;
  final String closeLabel;

  @override
  State<_PSnackbarItem> createState() => _PSnackbarItemState();
}

class _PSnackbarItemState extends State<_PSnackbarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final _DirectionalCurve _curve;
  final FocusNode _bandNode = FocusNode(debugLabel: 'PSnackbar band');
  Timer? _timer;
  FocusNode? _lastOutside;

  // 멈춤 — 하나라도 참이면 시간을 세지 않는다
  bool _hovered = false;
  bool _pressed = false;
  bool _keyboard = false;
  bool _screenReader = false;

  bool get _paused => _hovered || _pressed || _keyboard || _screenReader;
  bool get _open => widget.entry.open;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: PDuration.d3,
      reverseDuration: PDuration.d2,
      // 모션 줄이기는 크기만 걷고 투명도의 시간은 그대로다(v104) — 플랫폼이 시간을 줄이지 않게
      animationBehavior: AnimationBehavior.preserve,
    );
    _curve = _DirectionalCurve(_anim);
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !_open) {
        widget.host._exited(widget.entry.id);
      }
    });
    _lastOutside = FocusManager.instance.primaryFocus;
    FocusManager.instance.addListener(_trackFocus);
    _bandNode.addListener(_onFocusChange);
    if (_open) {
      _anim.forward();
      _syncTimer();
    } else {
      // 한 번에 여러 show() 가 오면 앞 띠는 닫힌 채로 붙는다 — 그려진 적 없는 띠는 사라지는 모습 없이 바로 걷는다
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.host._exited(widget.entry.id);
      });
    }
  }

  @override
  void didUpdateWidget(_PSnackbarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.open && !_open) _startExit();
    // 호스트가 다시 그려질 때마다(피할 자리 · 안전 영역이 바뀔 때) 시간을 처음부터 세지 않는다 — 열림 · 닫힘이 바뀐 때만
    if (oldWidget.entry.open != _open) _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    FocusManager.instance.removeListener(_trackFocus);
    _bandNode.removeListener(_onFocusChange);
    _bandNode.dispose();
    _anim.dispose();
    super.dispose();
  }

  // 띠에 들어오기 전 초점 자리를 기억한다 — 띠가 사라질 때 돌려준다
  void _trackFocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || _bandNode.hasFocus) return;
    _lastOutside = focus;
  }

  void _onFocusChange() {
    // 키보드로 닿은 초점만 멈춘다(웹 :focus-visible) — 손가락으로 닿은 것은 누름이 멈춘다
    final keyboard =
        _bandNode.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (keyboard == _keyboard) return;
    _keyboard = keyboard;
    _syncTimer();
  }

  /// 시간 — 멈춘 동안은 세지 않고, 멈춤이 끝나면 처음부터 다시 센다.
  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_open || _paused) return;
    final duration = widget.entry.options.action == null
        ? PSnackbar.duration
        : PSnackbar.durationWithAction;
    _timer = Timer(duration, () => widget.host._close(widget.entry.id));
  }

  void _setPause({bool? hovered, bool? pressed, bool? screenReader}) {
    _hovered = hovered ?? _hovered;
    _pressed = pressed ?? _pressed;
    _screenReader = screenReader ?? _screenReader;
    _syncTimer();
  }

  /// 사라지기 시작 — 초점이 안에 있었으면 들어오기 전 자리로 돌려준다(초점을 가린 채 두지 않는다).
  void _startExit() {
    _timer?.cancel();
    _timer = null;
    if (_bandNode.hasFocus) {
      final back = _lastOutside;
      if (back != null && back.context != null && back.canRequestFocus) {
        back.requestFocus();
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
    _anim.reverse();
  }

  void _runAction(PSnackbarAction action) {
    // 일이 던져도 닫는다 — 던진 것은 삼키지 않는다
    try {
      action.onPressed();
    } finally {
      widget.host._close(widget.entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.entry.options;
    final open = _open;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final action = options.action;

    Widget band = _Band(
      message: options.message,
      tone: options.tone,
      action: action,
      closeLabel: widget.closeLabel,
      onAction: action == null ? null : () => _runAction(action),
      onClose: () => widget.host._close(widget.entry.id),
      liveRegion: true,
      onScreenReaderFocus: (focused) => _setPause(screenReader: focused),
    );
    band = Focus(
      focusNode: _bandNode,
      canRequestFocus: open,
      // 키보드로 띠에 올 수 있다(웹 tabindex 0) — 글을 눌러도 아무 일도 없다
      child: Listener(
        onPointerDown: (_) => _setPause(pressed: true),
        onPointerUp: (_) => _setPause(pressed: false),
        onPointerCancel: (_) => _setPause(pressed: false),
        child: MouseRegion(
          onEnter: (_) => _setPause(hovered: true),
          onExit: (_) => _setPause(hovered: false),
          child: band,
        ),
      ),
    );
    // 나타남 — 가운데에서 0.8 → 1 + 투명도. 모션 줄이기면 투명도만
    if (!reduceMotion) {
      band = ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1).animate(_curve),
        child: band,
      );
    }
    return FadeTransition(
      opacity: _curve,
      // 사라지는 동안은 누르지 않고 읽지 않는다(웹 pointer-events: none · aria-hidden)
      child: IgnorePointer(
        ignoring: !open,
        child: ExcludeSemantics(excluding: !open, child: band),
      ),
    );
  }
}

/// 띠를 제자리에 그린다(웹 `SnackbarView` — 카탈로그와 테스트용). 모양 · 멈춤 · 초점은 호스트의 띠와 같고, 시간 ·
/// 닫기 · 액션은 아무것도 걷지 않는다(닫히지 않는다). 화면은 쓰지 않는다 — `PSnackbar.of(context).show` 로 띄운다.
class PSnackbarView extends StatelessWidget {
  const PSnackbarView({
    super.key,
    required this.message,
    required this.closeLabel,
    this.tone = PSnackbarTone.neutral,
    this.action,
  });

  final String message;
  final String closeLabel;
  final PSnackbarTone tone;
  final PSnackbarAction? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return _Band(
      message: message,
      tone: tone,
      action: action,
      closeLabel: closeLabel,
      onAction: action?.onPressed,
      onClose: () {},
      liveRegion: false,
    );
  }
}

/// 띠의 모양 — 아이콘 · 글 · 액션, 보조 기술용 닫기. 호스트의 띠와 [PSnackbarView] 가 같이 쓴다.
class _Band extends StatefulWidget {
  const _Band({
    required this.message,
    required this.tone,
    required this.action,
    required this.closeLabel,
    required this.onAction,
    required this.onClose,
    required this.liveRegion,
    this.onScreenReaderFocus,
  });

  final String message;
  final PSnackbarTone tone;
  final PSnackbarAction? action;
  final String closeLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;
  final bool liveRegion;
  final ValueChanged<bool>? onScreenReaderFocus;

  @override
  State<_Band> createState() => _BandState();
}

class _BandState extends State<_Band> {
  /// 보조 기술용 닫기가 키보드 초점으로 보이는 동안 — 띠 오른쪽 끝에 상자 44 가 서고 글이 그만큼 비킨다.
  bool _closeVisible = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (IconData? icon, Color iconColor) = switch (widget.tone) {
      PSnackbarTone.neutral => (null, c.fgNeutralInverted),
      PSnackbarTone.positive => (LucideIcons.circleCheck, c.fgPositiveInverted),
      PSnackbarTone.critical => (LucideIcons.circleAlert, c.fgCriticalInverted),
    };
    final action = widget.action;

    // 줄 하나 — 띠 안쪽 여백 · 글 좌우 6 을 줄 안의 것마다 둬서 줄이 띠 높이를 꽉 채운다(액션의 누르는 자리 44 가
    // 줄 안에 들어온다)
    final row = Row(
      children: [
        const SizedBox(width: _padding),
        if (icon != null)
          // 칸 24 안에 오른쪽 2 — 그림은 22(글은 띠 가장자리에서 40)
          SizedBox(
            width: _iconBox,
            height: _iconBox,
            child: Padding(
              padding: const EdgeInsets.only(right: _iconPaddingRight),
              child: Icon(
                icon,
                key: const ValueKey('snackbar-icon'),
                size: _iconBox - _iconPaddingRight,
                color: iconColor,
              ),
            ),
          ),
        const SizedBox(width: _contentPaddingX),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _padding),
            child: Text(
              keepAll(widget.message),
              key: const ValueKey('snackbar-message'),
              semanticsLabel: widget.message,
              style: PTypography.t4.copyWith(
                color: c.fgNeutralInverted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: _contentGap),
          _actionButton(action, c),
        ],
        const SizedBox(width: _contentPaddingX),
        // 닫기가 보이면 그 자리(44 − 오른쪽 여백 10)를 비운다
        if (_closeVisible) const SizedBox(width: _closeBox - _padding),
        const SizedBox(width: _padding),
      ],
    );

    final band = DecoratedBox(
      key: const ValueKey('snackbar-band'),
      // 그림자 없이 면 색으로 뜬다(SEED · Elevation) — boxShadow 를 두지 않는다
      decoration: BoxDecoration(
        color: c.bgNeutralInverted,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minHeight),
            child: row,
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _HiddenClose(
                label: widget.closeLabel,
                color: c.fgNeutralInverted,
                onPressed: widget.onClose,
                onVisibleChanged: (visible) =>
                    setState(() => _closeVisible = visible),
              ),
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Semantics(
          container: true,
          liveRegion: widget.liveRegion,
          onDidGainAccessibilityFocus: widget.onScreenReaderFocus == null
              ? null
              : () => widget.onScreenReaderFocus!(true),
          onDidLoseAccessibilityFocus: widget.onScreenReaderFocus == null
              ? null
              : () => widget.onScreenReaderFocus!(false),
          child: band,
        ),
      ),
    );
  }

  /// 액션 — t4 · 700, 보이는 것은 글이고 누르는 영역은 글 + 좌우 8 × 44. 누르면 글만 2px 거리 축소.
  Widget _actionButton(PSnackbarAction action, PColors c) {
    return FeedbackPress(
      onPressed: widget.onAction,
      slop: const EdgeInsets.symmetric(horizontal: _actionSlopX),
      minHeight: PTouch.min,
      builder: (context, pressed, scale) => FeedbackScale(
        scale: scale,
        child: Text(
          action.label,
          key: const ValueKey('snackbar-action'),
          maxLines: 1,
          softWrap: false,
          style: PTypography.t4.copyWith(
            color: c.fgBrandInverted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 보조 기술용 닫기 — 평소에는 보이지 않고(읽힌다) 키보드 초점이 오면 띠 오른쪽 끝에 상자 44 · X 16 으로 보인다.
class _HiddenClose extends StatefulWidget {
  const _HiddenClose({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.onVisibleChanged,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final ValueChanged<bool> onVisibleChanged;

  @override
  State<_HiddenClose> createState() => _HiddenCloseState();
}

class _HiddenCloseState extends State<_HiddenClose> {
  bool _visible = false;

  // 초점이 오가는 때(그리는 중이 아니다)에 불린다 — 띠도 글이 비키게 같이 알린다
  void _setVisible(bool value) {
    if (_visible == value) return;
    setState(() => _visible = value);
    widget.onVisibleChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: widget.label,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        includeFocusSemantics: false,
        onShowFocusHighlight: _setVisible,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: ExcludeSemantics(
          child: IgnorePointer(
            ignoring: !_visible,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: _visible
                  ? SizedBox(
                      key: const ValueKey('snackbar-close'),
                      width: _closeBox,
                      height: _closeBox,
                      child: Center(
                        child: Icon(
                          LucideIcons.x,
                          size: _closeIcon,
                          color: widget.color,
                        ),
                      ),
                    )
                  // 보이지 않는 한 점 — 읽히기만 한다
                  : const SizedBox(
                      key: ValueKey('snackbar-close-hidden'),
                      width: 1,
                      height: 1,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
