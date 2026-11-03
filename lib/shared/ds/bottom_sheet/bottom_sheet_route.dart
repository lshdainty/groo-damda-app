import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_parts.dart';
import 'package:groo_damda_app/shared/ds/overlay/p_overlay.dart';

/// 끌어서 닫는 기준 — 놓을 때 0.4px/ms 보다 빠르거나 높이의 25% 이상 내려왔으면 닫는다(bottom-sheet.md Behavior).
const double kSheetCloseVelocity = 0.4;
const double kSheetCloseFraction = 0.25;

/// 열린 뒤 이 시간 동안은 끌리지 않는다.
const Duration kSheetDragDelay = Duration(milliseconds: 500);

/// 시트 라우트 — 딤 · 시트 · 끌기 · 닫는 길은 [_SheetHost] 가 그린다(시트가 라우트 애니메이션과 끄는 위치를 함께 따른다).
class PBottomSheetRoute<T> extends PopupRoute<T> {
  PBottomSheetRoute({
    required this.themes,
    required this.reduceMotion,
    required this.builder,
    required this.form,
    required this.isDirty,
    required this.leaveCopy,
    required this.snapPoints,
    this.interceptClose,
    this.isForm,
    this.alwaysHandle = false,
    this.topRadius = PRounded.r6,
    this.initialFocus,
  });

  final CapturedThemes themes;
  final bool reduceMotion;
  final WidgetBuilder builder;

  /// 입력 폼 — 바깥 누르기 · 끌기로 닫히지 않고 손잡이도 없다.
  final bool form;

  /// 바뀐 값이 있는가 — 닫기 전에 묻는다. 닫는 순간에 읽는다.
  final bool Function()? isDirty;
  final PLeaveConfirmCopy? leaveCopy;

  /// 스냅 높이 — 화면 높이 비율(0 ~ 1, 낮은 것부터). 있으면 손잡이를 단다(입력 폼은 쓰지 않는다).
  final List<double>? snapPoints;

  /// 닫기 청(닫기 버튼 · 뒤로 가기 · `Esc`)을 먼저 받는다 — 참을 돌려주면 그 청은 쓰였고 시트는 닫히지 않는다(바뀐 값을 묻지도
  /// 않는다). 시트 안에서 한 단계 들어가 있을 때 뒤로 가기 · `Esc` 가 시트 전체가 아니라 그 단계만 닫는 길이다(웹
  /// `onOpenChange(false)` 를 안에서 가로채는 것과 같다).
  final bool Function()? interceptClose;

  /// 단계마다 닫힘 규칙이 갈릴 때(목록 · 상세 = 조회, 폼 = 입력) [form] 대신 누르는 · 끄는 순간에 읽는 판정. 있으면 [form] 은
  /// 스냅 높이 · 손잡이 판단에만 쓰이고(입력 폼이 아니라고 둔다) 바깥 누르기 · 끌기는 이 값을 따른다.
  final bool Function()? isForm;

  /// 지금 바깥 누르기 · 끌기를 무시하는 입력 폼 단계인가.
  bool get formNow => isForm?.call() ?? form;

  /// 손잡이를 늘 단다 — 스냅 높이가 없어도(Menu Sheet). 누르면 닫는다.
  final bool alwaysHandle;

  /// 시트 위 두 모서리 — 기본 24, Menu Sheet 는 20.
  final double topRadius;

  /// 첫 초점 노드 — 내용이 첫 자리를 정할 때(검색 시트의 검색칸). 있으면 열린 첫 프레임 뒤에 시트(컨테이너) 대신 이리로 초점이
  /// 가고, 열린 뒤 다시 옮기지 않는다(Q-007-3 — 웹 `onOpenAutoFocus`). 없으면 초점은 시트에 간다.
  final FocusNode? initialFocus;

  // 바깥 누르기는 시트가 직접 받는다(입력 폼은 무시) — 라우트 장벽은 막기만 한다
  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  // 열림 300ms · 닫힘 200ms. 모션 줄이기면 150ms 서서히 나타나고 사라진다
  @override
  Duration get transitionDuration => reduceMotion ? PDuration.d3 : PDuration.d6;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? PDuration.d3 : PDuration.d4;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(
    DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: _SheetHost(route: this),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// 시트 자리 — 화면 아래, 키보드 위. 라우트 애니메이션(아래에서 올라옴)과 끄는 위치를 함께 따른다.
class _SheetLayoutDelegate extends SingleChildLayoutDelegate {
  _SheetLayoutDelegate({
    required this.host,
    required this.keyboard,
    required Listenable relayout,
  }) : super(relayout: relayout);

  final _SheetHostState host;
  final double keyboard;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // 높이는 화면의 90% 를 넘지 않고, 키보드가 올라오면 그 위에 선다
    final maxHeight = math.min(
      constraints.maxHeight * kBottomSheetMaxHeightFactor,
      constraints.maxHeight - keyboard,
    );
    return BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    host._screenHeight = size.height;
    host._sheetHeight = childSize.height;
    return Offset(
      (size.width - childSize.width) / 2,
      size.height - keyboard - childSize.height + host._translateY(),
    );
  }

  @override
  bool shouldRelayout(_SheetLayoutDelegate oldDelegate) =>
      oldDelegate.keyboard != keyboard || oldDelegate.host != host;
}

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

class _SheetHost extends StatefulWidget {
  const _SheetHost({required this.route});

  final PBottomSheetRoute<dynamic> route;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost>
    with SingleTickerProviderStateMixin
    implements PBottomSheetController {
  PBottomSheetRoute<dynamic> get _route => widget.route;

  @override
  final ScrollController bodyController = ScrollController();

  late final CurvedAnimation _slide;
  late final CurvedAnimation _dim;
  late final AnimationController _move;
  final _Repaint _repaint = _Repaint();
  late final Listenable _layoutSignal;

  // 시트 높이 · 화면 높이 — 자리를 잡을 때(delegate) 적어 둔다
  double _sheetHeight = 0;
  double _screenHeight = 0;

  /// 끄는 · 되돌아가는 중의 위치(열린 자리에서 아래로 px). 비어 있으면 쉬는 자리(스냅 높이 자리).
  double? _dragPos;
  int _snapIndex = 0;

  bool _dragReady = false;
  Timer? _readyTimer;
  bool _asking = false;

  // 끌기
  bool _tracking = false;
  bool _sheetMoved = false;
  VelocityTracker? _tracker;
  double _moveFrom = 0;
  double _moveTo = 0;
  Curve _moveCurve = PEasing.exit;

  List<double> get _snaps =>
      _route.form ? const [] : (_route.snapPoints ?? const []);
  bool get _hasSnaps => _snaps.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final animation = _route.animation!;
    final reduce = _route.reduceMotion;
    // 열림 300ms enter-expressive · 닫힘 200ms exit(곡선은 시간 쪽에서 뒤집어 준다)
    _slide = CurvedAnimation(
      parent: animation,
      curve: reduce ? Curves.linear : PEasing.enterExpressive,
      reverseCurve: reduce ? Curves.linear : PEasing.exit.flipped,
    );
    _dim = CurvedAnimation(
      parent: animation,
      curve: PEasing.enter,
      reverseCurve: PEasing.exit.flipped,
    );
    _move = AnimationController(vsync: this)..addListener(_onMove);
    final first = _route.initialFocus;
    if (first != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && first.context != null && first.canRequestFocus) {
          first.requestFocus();
        }
      });
    }
    _layoutSignal = Listenable.merge([_slide, _repaint]);
    // 열린 뒤 0.5초는 끌리지 않는다
    _readyTimer = Timer(kSheetDragDelay, () => _dragReady = true);
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    _move.dispose();
    _slide.dispose();
    _dim.dispose();
    _repaint.dispose();
    bodyController.dispose();
    super.dispose();
  }

  // ── 위치 ─────────────────────────────────────────────────────
  /// 스냅 높이 자리 — 시트는 화면 90% 로 고정하고 보이는 높이만 남기고 아래로 내린다.
  double _baseOf(int index) {
    if (!_hasSnaps) return 0;
    final visible = math.min(_sheetHeight, _snaps[index] * _screenHeight);
    return math.max(0, _sheetHeight - visible);
  }

  double get _restPos => _baseOf(_snapIndex);
  double get _pos => _dragPos ?? _restPos;

  /// 시트를 그릴 아래쪽 이동 px — 열림 · 닫힘 애니메이션(y: 1 → 0)과 끄는 위치를 한 식으로 잇는다.
  /// 닫힐 때는 끌던 자리에서 이어서 내려간다(pos → 시트 높이).
  double _translateY() {
    if (_route.reduceMotion) return _pos;
    final y = 1 - _slide.value;
    return _pos * (1 - y) + _sheetHeight * y;
  }

  /// 딤 — 라우트 애니메이션 × 끌어 내린 만큼 옅게.
  double _dimOpacity() {
    final drag = _sheetHeight <= 0
        ? 0.0
        : ((_pos - _restPos) / _sheetHeight).clamp(0.0, 1.0);
    return _dim.value * (1 - drag);
  }

  void _setPos(double? value) {
    _dragPos = value;
    _repaint.ping();
  }

  void _animateTo(double target, Duration duration, Curve curve) {
    _moveFrom = _pos;
    _moveTo = target;
    _moveCurve = curve;
    if (duration == Duration.zero || (target - _moveFrom).abs() < 0.01) {
      _move.stop();
      _setPos(_snapIndexIsRest(target) ? null : target);
      return;
    }
    _move.duration = duration;
    _move.forward(from: 0);
  }

  bool _snapIndexIsRest(double target) => (target - _restPos).abs() < 0.01;

  void _onMove() {
    final t = _moveCurve.transform(_move.value);
    final value = _moveFrom + (_moveTo - _moveFrom) * t;
    if (_move.isCompleted) {
      _setPos(_snapIndexIsRest(_moveTo) ? null : _moveTo);
    } else {
      _setPos(value);
    }
  }

  /// 쉬는 자리로 — 끌다 놓아 돌아갈 때 · 묻고 계속 작성할 때. 200ms exit(스냅 높이가 있으면 300ms enter-expressive).
  void _settleBack() => _animateTo(_restPos, _moveDuration, _moveEasing);

  Duration get _moveDuration => _hasSnaps ? PDuration.d6 : PDuration.d4;
  Curve get _moveEasing => _hasSnaps ? PEasing.enterExpressive : PEasing.exit;

  // ── 닫는 길 ──────────────────────────────────────────────────
  @override
  Future<void> requestClose({bool wholeSheet = false}) async {
    if (_asking) return;
    if (!wholeSheet && (_route.interceptClose?.call() ?? false)) return;
    final dirty = _route.isDirty?.call() ?? false;
    final copy = _route.leaveCopy;
    if (!dirty || copy == null) {
      close();
      return;
    }
    _asking = true;
    final leave = await PAlertDialog.confirmLeave(context, copy);
    _asking = false;
    if (!mounted) return;
    if (leave) {
      close();
    } else {
      _settleBack();
    }
  }

  @override
  void close([Object? result]) {
    if (!mounted) return;
    _move.stop();
    Navigator.of(context).pop(result);
  }

  // ── 끌기 ─────────────────────────────────────────────────────
  bool get _canDrag => !_route.formNow && _dragReady && !_asking;

  bool get _bodyScrolled =>
      bodyController.hasClients && bodyController.position.pixels > 0.5;

  void _down(PointerDownEvent e) {
    if (!_canDrag) return;
    _move.stop();
    _tracker = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.position);
    // 본문이 스크롤된 채 시작하면 끌지 않는다(스크롤한다)
    _tracking = !_bodyScrolled;
    _sheetMoved = false;
  }

  void _moveEvent(PointerMoveEvent e) {
    if (!_tracking) return;
    _tracker?.addPosition(e.timeStamp, e.position);
    // 시트를 끌기 전에 본문이 스크롤되기 시작하면 이 손짓은 스크롤이다
    if (!_sheetMoved && _bodyScrolled) {
      _tracking = false;
      return;
    }
    final highest = _hasSnaps ? _baseOf(_snaps.length - 1) : 0.0;
    final next = (_pos + e.delta.dy).clamp(highest, _sheetHeight);
    if ((next - _pos).abs() < 0.001) return;
    _sheetMoved = true;
    _setPos(next);
  }

  void _up(PointerUpEvent e) {
    if (!_tracking || !_sheetMoved) {
      _tracking = false;
      return;
    }
    _tracker?.addPosition(e.timeStamp, e.position);
    final v = (_tracker?.getVelocity().pixelsPerSecond.dy ?? 0) / 1000;
    _tracking = false;
    _release(v);
  }

  void _cancel(PointerCancelEvent e) {
    if (!_tracking || !_sheetMoved) {
      _tracking = false;
      return;
    }
    _tracking = false;
    _settleBack();
  }

  /// 놓았을 때 — 빠르게(0.4px/ms 넘게) 끌었거나 높이의 25% 이상 내려왔으면 닫고, 아니면 제자리로.
  /// 스냅 높이가 있으면 빠른 쪽 · 가까운 쪽 스냅으로 가고, 가장 낮은 높이에서 더 내리면 닫는다.
  void _release(double velocity) {
    if (!_hasSnaps) {
      final closing =
          velocity >= kSheetCloseVelocity ||
          (_sheetHeight > 0 && _pos / _sheetHeight >= kSheetCloseFraction);
      if (closing) {
        // 닫았으면 끌던 자리에서 내려가고, 계속 작성하면 제자리로 돌아온다(requestClose 가 한다). 끌기는 한 단계가 아니라 시트 전체다
        requestClose(wholeSheet: true);
      } else {
        _settleBack();
      }
      return;
    }
    final bases = [for (var i = 0; i < _snaps.length; i++) _baseOf(i)];
    final lowest = bases.first;
    final lowestVisible = _sheetHeight - lowest;
    var target = _snapIndex;
    var closing = false;
    if (velocity >= kSheetCloseVelocity) {
      if (_snapIndex == 0) {
        closing = true;
      } else {
        target = _snapIndex - 1;
      }
    } else if (velocity <= -kSheetCloseVelocity) {
      target = math.min(_snapIndex + 1, _snaps.length - 1);
    } else if (_pos - lowest >= kSheetCloseFraction * lowestVisible) {
      closing = true;
    } else {
      var best = 0.0;
      var bestDistance = double.infinity;
      for (var i = 0; i < bases.length; i++) {
        final d = (bases[i] - _pos).abs();
        if (d < bestDistance) {
          bestDistance = d;
          best = i.toDouble();
        }
      }
      target = best.toInt();
    }
    if (closing) {
      requestClose(wholeSheet: true);
      return;
    }
    _snapIndex = target;
    _animateTo(_restPos, _moveDuration, _moveEasing);
  }

  /// 손잡이 — 다음(더 높은) 스냅 높이로, 가장 높은 높이에서 누르면 닫는다.
  void _handleTap() {
    if (_snapIndex + 1 >= _snaps.length) {
      requestClose(wholeSheet: true);
      return;
    }
    final from = _pos;
    _snapIndex += 1;
    _dragPos = from;
    _animateTo(
      _restPos,
      _route.reduceMotion ? Duration.zero : PDuration.d6,
      PEasing.enterExpressive,
    );
  }

  // ── 그리기 ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    Widget sheet = PBottomSheetScope(
      controller: this,
      child: PBottomSheetSurface(
        showHandle: _hasSnaps || _route.alwaysHandle,
        topRadius: _route.topRadius,
        onHandleTap: _handleTap,
        fixedHeight: _hasSnaps,
        child: Builder(builder: _route.builder),
      ),
    );
    // 끌기 — 입력 폼은 끌리지 않는다. 포인터를 직접 읽는다(본문 스크롤과 다투지 않는다)
    sheet = Listener(
      onPointerDown: _down,
      onPointerMove: _moveEvent,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: sheet,
    );
    // 모션 줄이기 — 미끄러지지 않고 서서히
    if (_route.reduceMotion) {
      sheet = FadeTransition(opacity: _slide, child: sheet);
    }

    Widget out = Stack(
      fit: StackFit.expand,
      children: [
        // 딤 — 조회 · 고르기는 누르면 닫고 입력 폼은 무시한다
        PDimLayer(
          repaint: Listenable.merge([_slide, _dim, _repaint]),
          opacityOf: _dimOpacity,
          // 누르는 순간의 단계로 가른다 — 입력 폼 단계는 무시하고, 조회 · 고르기 단계는 시트 전체를 닫는다
          onTap: () {
            if (!_route.formNow) requestClose(wholeSheet: true);
          },
        ),
        CustomSingleChildLayout(
          delegate: _SheetLayoutDelegate(
            host: this,
            keyboard: keyboard,
            relayout: _layoutSignal,
          ),
          child: sheet,
        ),
      ],
    );
    // 처음 초점은 시트(컨테이너) — 내용이 첫 초점 노드를 넘겼으면 그리로(initState)
    out = Focus(
      autofocus: _route.initialFocus == null,
      debugLabel: 'PBottomSheet',
      skipTraversal: true,
      child: out,
    );
    // Esc 는 늘 닫는다(바뀐 값이 있으면 먼저 묻는다)
    out = Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            requestClose();
            return null;
          },
        ),
      },
      child: out,
    );
    // 뒤로 가기는 늘 닫는다 — 바뀐 값을 살피는 시트(isDirty)는 직접 받아 묻고, 아니면 그대로 닫힌다.
    // 모달 라우트 안에서만 건다(셸의 branch PopScope 와 겹치지 않는다)
    return PopScope(
      canPop: _route.isDirty == null && _route.interceptClose == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) requestClose();
      },
      child: out,
    );
  }
}
