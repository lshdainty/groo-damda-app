import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';

/// 동작의 종류 — 곁 동작(고정 · 보관 · 공유) · 주 동작(수정) · 되돌리기 어려운 동작(삭제). 색은 배지만 갖는다.
enum PSwipeActionKind { neutral, primary, destructive }

/// 원형 배지 지름 — 줄 높이 안에 배지 + 라벨이 함께 들어가는 최대치(40 은 라벨과 합쳐 넘친다).
const double kSwipeBadgeSize = PSpacing.x9;

/// 배지 안 아이콘.
const double kSwipeIconSize = PSpacing.x4_5;

/// 줄 내용과 첫 동작 사이. 바짝 붙으면 배지가 줄에 얹힌 것처럼 보인다.
const double kSwipeGapLead = PSpacing.x5;

/// 동작끼리 사이. 배지 둘이 붙으면 하나의 알약처럼 뭉쳐 보인다.
const double kSwipeGapBetween = PSpacing.x3;

/// 배지 ↔ 라벨.
const double kSwipeBadgeLabelGap = PSpacing.x0_5;

/// 칸 최소 높이 — 줄이 56 보다 낮으면 56.
const double kSwipeMinHeight = PSpacing.x14;

/// 동작은 하나에서 셋까지 — 넷부터는 트레이가 줄 폭을 먹어 무엇을 미는지 안 보인다.
const int kSwipeMaxActions = 3;

/// 닫힌 줄을 트레이 폭의 이 비율 이상 밀고 놓으면 열린 채 자리를 잡는다.
const double kSwipeOpenThreshold = 0.4;

/// 열린 줄을 되돌려 민 거리가 트레이 폭의 이 비율 이상이면 닫는다(여는 문턱과 같이 걸면 두 범위가 맞물려 아예 열리지 않는다).
const double kSwipeCloseThreshold = 0.25;

/// 이보다 짧은 이동은 누르기로 본다 — 축을 판정하지 않는다(px).
const double kSwipeDeadZone = PSpacing.x2;

/// 가로로 확정하는 기울기 — abs(dx) > abs(dy) × 1.5(≈ 33.7° 이내). 45° 면 세로로 훑는 중 스크롤이 끊긴다.
const double kSwipeAxisRatio = 1.5;

/// 라벨 줄 높이 배율 — 칸 폭 48 이 좁아 기본 줄 높이(16)면 두 줄에서 넘친다.
const double kSwipeLabelLineHeight = 1.3;

/// 누름 · 호버 밝기.
const double kSwipePressedBrightness = 0.88;

/// 동작 하나가 차지하는 폭 — 글 자리 + 그 앞 간격(첫 칸 +20 · 다음부터 +12). 글 자리는 배지 36 이 최소이고 라벨이 더 길면
/// 라벨 폭만큼 넓어진다(영어 "Delete" 가 두 줄로 꺾이지 않게 — 한글 두 글자는 36 안이라 그대로 56 · 48). 간격은 앞에만 둔다(뒤에도
/// 두면 마지막 배지와 화면 끝이 벌어져 덜 열린 것처럼 보인다).
double swipeSlotWidth(int index, {double label = 0}) =>
    math.max(kSwipeBadgeSize, label) +
    (index == 0 ? kSwipeGapLead : kSwipeGapBetween);

/// 트레이 전체 폭 — 라벨이 모두 36 안이면 하나 56 · 둘 104 · 셋 152. [labels] 는 칸 차례(안쪽부터)의 라벨 폭.
double swipeTrayWidth(int count, {List<double>? labels}) {
  var sum = 0.0;
  for (var i = 0; i < count; i++) {
    sum += swipeSlotWidth(i, label: labels == null ? 0 : labels[i]);
  }
  return sum;
}

/// 라벨 한 줄의 폭 — 칸 폭을 정한다(t2 · 700, 글자 크기 설정을 따른다).
double swipeLabelWidth(BuildContext context, String label) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: PTypography.t2.copyWith(fontWeight: FontWeight.w700),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width.ceilToDouble();
  painter.dispose();
  return width;
}

enum PSwipeAxis { none, x, y }

/// 데드존을 넘은 뒤 어느 축의 제스처인지 확정한다.
PSwipeAxis resolveSwipeAxis(double dx, double dy) {
  if (math.sqrt(dx * dx + dy * dy) < kSwipeDeadZone) return PSwipeAxis.none;
  return dx.abs() > dy.abs() * kSwipeAxisRatio ? PSwipeAxis.x : PSwipeAxis.y;
}

/// 트레이 폭에서 멈춘다 — 끝까지 밀어도 거기까지다. 반대 방향으로 밀면 0 에 머문다.
double clampSwipeOffset(double dragged, double tray) =>
    math.max(0, math.min(dragged, tray));

/// 놓았을 때 열린 채로 둘지 — 닫혀 있던 줄은 트레이 폭의 40% 이상 밀었으면 열고, 열려 있던 줄은 되돌려 민 거리가
/// 25% 미만이면 열린 채로 둔다.
bool settleSwipeOpen(bool wasOpen, double offset, double tray) => wasOpen
    ? tray - offset < tray * kSwipeCloseThreshold
    : offset >= tray * kSwipeOpenThreshold;

/// 동작 하나 — 트레이 칸과 ⋮ 시트의 줄이 한 배열에서 나온다.
class PSwipeAction {
  const PSwipeAction({
    required this.label,
    required this.onSelect,
    this.kind = PSwipeActionKind.neutral,
    this.icon,
    this.disabled = false,
  });

  /// 라벨 — 한글 두 글자 동사("수정" · "삭제" · "고정"). 그보다 길면 줄바꿈된다.
  final String label;

  final PSwipeActionKind kind;

  /// 배지 안 아이콘(18).
  final IconData? icon;
  final bool disabled;

  /// destructive 는 여기서 바로 지우지 말고 확인 창(Alert Dialog)부터 — 제목 · 설명은 상세에서 지울 때와 같은 문구를
  /// 부르는 쪽이 넘긴다. 트레이는 먼저 닫히고 나서 부른다(열어 둔 채 띄우면 취소하고 돌아왔을 때 그대로 열려 있다).
  final VoidCallback onSelect;
}

/// 배지 · 아이콘 · 라벨 색 — 위젯과 테스트가 같은 표를 본다. 색은 배지만(트레이는 칠하지 않는다).
@visibleForTesting
({Color badge, Color? border, Color icon, Color label}) resolveSwipeColors(
  PColors c, {
  required PSwipeActionKind kind,
  bool disabled = false,
}) {
  if (disabled) {
    return (
      badge: c.bgDisabled,
      // 스펙 값 — 곁 동작 배지의 안쪽 1px 은 막혀도 그대로다(neutral 규칙의 테두리를 막힘이 덮지 않는다)
      border: kind == PSwipeActionKind.neutral ? c.strokeNeutralWeak : null,
      icon: c.fgDisabled,
      label: c.fgDisabled,
    );
  }
  return switch (kind) {
    PSwipeActionKind.neutral => (
      badge: c.bgNeutralWeak,
      border: c.strokeNeutralWeak,
      icon: c.fgNeutral,
      label: c.fgNeutralMuted,
    ),
    // 주 동작도 라벨은 회색 — 색은 배지가 말한다
    PSwipeActionKind.primary => (
      badge: c.fgInformative,
      border: null,
      icon: c.fgNeutralInverted,
      label: c.fgNeutralMuted,
    ),
    PSwipeActionKind.destructive => (
      badge: c.fgCritical,
      border: null,
      icon: c.fgNeutralInverted,
      label: c.fgCritical,
    ),
  };
}

// ── 한 번에 한 줄 ─────────────────────────────────────────────

/// 열린 줄의 id 하나 — 조상이 가진다. 줄 하나는 다른 줄의 상태를 모른다.
class PSwipeActionsController extends ValueNotifier<Object?> {
  PSwipeActionsController() : super(null);

  Object? get openId => value;

  void open(Object id) => value = id;

  /// [id] 가 열려 있으면 닫는다 — 같은 틱에 다른 줄이 열렸을 수 있다.
  void close(Object id) {
    if (value == id) value = null;
  }

  void closeAll() => value = null;
}

class _PSwipeActionsScope extends InheritedNotifier<PSwipeActionsController> {
  const _PSwipeActionsScope({
    required PSwipeActionsController super.notifier,
    required super.child,
  });
}

/// 목록의 조상 — 한 번에 한 줄만 열리고(다른 줄을 끌면 열린 줄이 닫힌다), 스크롤하면 열린 줄이 닫힌다.
/// 폰 셸마다 하나 둔다(화면마다 새로 두지 않는다). 없어도 줄은 제 상태로 열고 닫는다.
class PSwipeActionsProvider extends StatefulWidget {
  const PSwipeActionsProvider({super.key, required this.child});

  final Widget child;

  @override
  State<PSwipeActionsProvider> createState() => _PSwipeActionsProviderState();
}

class _PSwipeActionsProviderState extends State<PSwipeActionsProvider> {
  final _controller = PSwipeActionsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    // 줄을 미는 제스처는 스크롤이 아니다 — 여기 오는 알림은 목록(또는 화면)의 스크롤이다
    if (_controller.openId != null &&
        (n is ScrollStartNotification || n is ScrollUpdateNotification)) {
      _controller.closeAll();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => _PSwipeActionsScope(
    notifier: _controller,
    child: NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    ),
  );
}

// ── 동작 칸 ───────────────────────────────────────────────────

/// 동작 한 칸(원형 배지 + 라벨) — 트레이가 쓴다. 카탈로그 견본이 칸 하나를 직접 보일 수 있게 내보낸다.
///
/// 폭은 첫 칸 56 · 다음부터 48(앞 간격 20 · 12 + 배지 36), 높이는 줄을 따르되 56 보다 낮으면 56. 누르는 자리는 칸 전체다.
/// 누름은 밝기 88% 만 — 움직이지 않는다(손가락으로 밀어 둔 트레이와 이중으로 움직이면 어지럽다). 막히면 전용 색이고 밝기는
/// 그대로다. 이름은 "라벨: 줄 제목". [previewPressed] 는 카탈로그용 멈춘 누름.
class PSwipeActionCell extends StatelessWidget {
  const PSwipeActionCell({
    super.key,
    required this.action,
    this.index = 0,
    this.labelWidth = 0,
    this.rowLabel,
    this.onTap,
    this.previewPressed = false,
  });

  final PSwipeAction action;

  /// 트레이 안 자리 — 0 이 가장 안쪽(화면에서 가장 왼쪽): 앞 간격 20, 다음부터 12.
  final int index;

  /// 라벨 한 줄의 폭 — 36 보다 길면 칸이 그만큼 넓어진다([swipeLabelWidth]).
  final double labelWidth;

  /// 동작 이름에 붙는 줄 제목 — "삭제: 스타벅스".
  final String? rowLabel;

  /// 칸을 눌렀을 때 — 트레이가 닫은 뒤 [PSwipeAction.onSelect] 를 부르게 묶는다. 없으면 [PSwipeAction.onSelect] 만.
  final VoidCallback? onTap;

  final bool previewPressed;

  @override
  Widget build(BuildContext context) {
    final colors = resolveSwipeColors(
      context.colors,
      kind: action.kind,
      disabled: action.disabled,
    );
    final name = rowLabel == null ? action.label : '${action.label}: $rowLabel';
    return PressArea(
      enabled: !action.disabled,
      onTap: onTap ?? action.onSelect,
      touchMin: 0,
      semantics: (child, enabled, tap) => Semantics(
        button: true,
        enabled: enabled,
        label: name,
        onTap: tap,
        excludeSemantics: true,
        child: child,
      ),
      builder: (context, pressed, size) {
        final dim = !action.disabled && (pressed || previewPressed);
        Widget body = SizedBox(
          key: ValueKey('swipe-action-${action.label}'),
          width: swipeSlotWidth(index, label: labelWidth),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: index == 0 ? kSwipeGapLead : kSwipeGapBetween,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kSwipeMinHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: kSwipeBadgeLabelGap,
                children: [
                  _Badge(colors: colors, icon: action.icon),
                  Text(
                    action.label,
                    key: ValueKey('swipe-label-${action.label}'),
                    textAlign: TextAlign.center,
                    style: PTypography.t2.copyWith(
                      fontWeight: FontWeight.w700,
                      height: kSwipeLabelLineHeight,
                      color: colors.label,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        // 누름 · 호버는 밝기 88% — 막힌 칸은 그대로
        if (dim) {
          body = ColorFiltered(
            key: const ValueKey('swipe-action-dim'),
            colorFilter: const ColorFilter.matrix(<double>[
              kSwipePressedBrightness, 0, 0, 0, 0, //
              0, kSwipePressedBrightness, 0, 0, 0, //
              0, 0, kSwipePressedBrightness, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
            child: body,
          );
        }
        return body;
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.colors, required this.icon});

  final ({Color badge, Color? border, Color icon, Color label}) colors;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('swipe-badge'),
    width: kSwipeBadgeSize,
    height: kSwipeBadgeSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: colors.badge,
      // 안쪽 1px — 바깥으로 나가지 않고 배지 지름은 그대로다(웹 inset 그림자)
      border: colors.border == null
          ? null
          : Border.all(
              color: colors.border!,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
    ),
    child: icon == null
        ? null
        : Icon(icon, size: kSwipeIconSize, color: colors.icon),
  );
}

// ── 제스처 ────────────────────────────────────────────────────

/// 줄 미는 제스처 — 데드존 8 · 축 1.5배. 가로로 확정되면 그 자리에서 겨루기를 이기고(아래 탭 · 세로 스크롤이 진다),
/// 세로로 확정되면 포기해 스크롤에 맡기며 손을 뗄 때까지 가로로 되돌리지 않는다.
class _SwipeRecognizer extends OneSequenceGestureRecognizer {
  _SwipeRecognizer({super.debugOwner});

  void Function()? onStart;
  void Function(double dx)? onUpdate;
  void Function(double dx)? onEnd;

  int? _pointer;
  Offset _down = Offset.zero;
  PSwipeAxis _axis = PSwipeAxis.none;
  double _dx = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // 손가락 하나만 — 다른 손가락은 겨루기에 끼지 않는다
    if (_pointer != null) return;
    startTrackingPointer(event.pointer, event.transform);
    _pointer = event.pointer;
    _down = event.position;
    _axis = PSwipeAxis.none;
    _dx = 0;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      final d = event.position - _down;
      if (_axis == PSwipeAxis.none) {
        final next = resolveSwipeAxis(d.dx, d.dy);
        if (next == PSwipeAxis.none) return;
        _axis = next;
        if (next == PSwipeAxis.y) {
          // 세로로 확정 — 이번 제스처는 포기한다. 스크롤은 스크롤러가 맡는다
          resolve(GestureDisposition.rejected);
          stopTrackingPointer(event.pointer);
          _pointer = null;
          return;
        }
        resolve(GestureDisposition.accepted);
        onStart?.call();
      }
      if (_axis == PSwipeAxis.x) {
        _dx = d.dx;
        onUpdate?.call(_dx);
      }
    } else if (event is PointerUpEvent) {
      _finish(event.pointer, cancel: false);
    } else if (event is PointerCancelEvent) {
      _finish(event.pointer, cancel: true);
    }
  }

  void _finish(int pointer, {required bool cancel}) {
    final wasX = _axis == PSwipeAxis.x;
    stopTrackingPointer(pointer);
    _pointer = null;
    if (wasX) onEnd?.call(_dx);
    _axis = PSwipeAxis.none;
  }

  @override
  void rejectGesture(int pointer) {
    // 다른 제스처(가로 스크롤 · 페이지 넘김)가 이겼다 — 끌던 중이면 지금 자리에서 놓은 것으로 본다
    if (pointer == _pointer) _finish(pointer, cancel: true);
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'swipe actions';
}

// ── 줄 감싸기 ─────────────────────────────────────────────────

/// Swipe Actions — 폰 목록 줄을 왼쪽으로 밀면 오른쪽에서 동작 칸이 드러나는 지름길. groo 에만 있는 패턴이다(SEED 에는
/// 줄 밀기가 없다). 수치 원본은 groo-design `specs/components/swipe-actions.yaml`(값은
/// `test/fixtures/design_spec/swipe-actions.json`). 웹(desk-front `src/shared/ds/swipe-actions`)과 같은 값이다.
///
///   [PSwipeActions]          줄을 감싼다 — [actions](1 ~ 3개, 뜻의 차례로), [enabled](768 이상은 통과 — 앱은 쓸 일이 없지만
///                            API 는 둔다), [rowLabel]("삭제: 스타벅스" 의 줄 제목). 줄은 다시 만들지 않고 감싸기만 한다.
///   [PSwipeActionsMore]      줄 끝 ⋮ — 같은 [actions] 를 [PMenuSheet] 로 연다(같은 이름 · 같은 차례). 스와이프로만 닿는
///                            동작은 없다 — 키보드 · 스크린리더 · 미는 법을 모르는 사람은 이 ⋮ 가 맡는다.
///   [PSwipeActionsProvider]  목록의 조상 — 한 번에 한 줄, 스크롤하면 닫힘. 폰 셸마다 하나.
///   [PSwipeActionCell]       동작 한 칸.
///
/// 판정 — 데드존 8 · 축 1.5배(세로로 확정되면 손을 뗄 때까지 가로로 되돌리지 않는다) · 열기 40% · 닫기 25%(두 문턱이 다르다)
/// · 트레이 폭에서 멈춘다 · 끝까지 밀어도 실행하지 않는다 · 오른쪽으로 끌어도 반응하지 않는다. 끄는 동안은 손가락을 1:1 로
/// 따라가고, 놓은 뒤 자리를 잡는 것만 150ms 감속(모션 줄이기면 바로). 뒤집어 그려 삭제가 가장 안쪽이다.
///
/// 열린 줄을 누르면 닫기만 한다(줄이 눌리지 않는다). 닫힌 트레이는 의미 트리에서 뺀다(줄마다 "수정 삭제" 를 읽지 않게).
/// 밀고 난 뒤의 탭은 제스처 겨루기에서 진다(웹의 click 삼키기와 같은 결과). 맞춤 접근성 동작은 두지 않는다 — ⋮ 가 그 길이다.
class PSwipeActions extends StatefulWidget {
  const PSwipeActions({
    super.key,
    required this.actions,
    required this.child,
    this.enabled = true,
    this.rowLabel,
  });

  /// 1 ~ 3개 — 뜻의 차례로(그리는 쪽이 뒤집어 destructive 를 가장 안쪽에 둔다). 비면 줄만 그린다
  /// (줄에서 동작이 성립하지 않을 때 — [enabled] = false 와 다른 뜻이다).
  final List<PSwipeAction> actions;

  /// 폰일 때만 true — false 면 트레이 없이 줄만 그린다(데스크톱 통과 전용).
  final bool enabled;

  /// 동작 이름에 붙는 줄 제목 — "삭제: 스타벅스".
  final String? rowLabel;

  final Widget child;

  @override
  State<PSwipeActions> createState() => _PSwipeActionsState();
}

class _PSwipeActionsState extends State<PSwipeActions> {
  final Object _id = Object();
  final _rowFocus = FocusNode(debugLabel: 'swipe-row', skipTraversal: true);
  PSwipeActionsController? _group;
  bool _localOpen = false;

  /// 끄는 동안의 위치(px) — 끄지 않을 땐 null.
  double? _drag;
  double _last = 0;
  double _from = 0;

  @override
  void dispose() {
    _rowFocus.dispose();
    super.dispose();
  }

  /// 칸 차례(안쪽부터 = 뒤집은 차례)의 라벨 폭.
  List<double> get _labelWidths => [
    for (final a in widget.actions.reversed) swipeLabelWidth(context, a.label),
  ];

  double get _tray =>
      swipeTrayWidth(widget.actions.length, labels: _labelWidths);

  bool get _open => _group != null ? _group!.openId == _id : _localOpen;

  void _commit(bool next) {
    final group = _group;
    if (group != null) {
      next ? group.open(_id) : group.close(_id);
    } else {
      setState(() => _localOpen = next);
    }
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  void _start() {
    _from = _open ? _tray : 0;
    _last = _from;
    // 이 줄을 끌기 시작했다 — 열려 있던 다른 줄은 닫힌다
    _group?.open(_id);
    setState(() => _drag = _last);
  }

  void _update(double dx) {
    // RTL 은 미는 방향이 뒤집힌다 — 트레이가 드러나는 거리를 양수로 맞춘다
    _last = clampSwipeOffset(_from + (_rtl ? dx : -dx), _tray);
    setState(() => _drag = _last);
  }

  void _end(double dx) {
    setState(() => _drag = null);
    // 열 때와 닫을 때가 다른 문턱 — 같은 값을 걸면 두 범위가 맞물려 아예 열리지 않는다
    _commit(settleSwipeOpen(_from > 0, _last, _tray));
  }

  void _close() {
    _commit(false);
    _rowFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    _group = context
        .dependOnInheritedWidgetOfExactType<_PSwipeActionsScope>()
        ?.notifier;
    assert(widget.actions.length <= kSwipeMaxActions, '동작은 셋까지 — 넷부터는 ⋮ 에만 둔다');
    if (!widget.enabled || widget.actions.isEmpty) return widget.child;

    final c = context.colors;
    final open = _open;
    final labelWidths = _labelWidths;
    final tray = swipeTrayWidth(widget.actions.length, labels: labelWidths);
    final offset = _drag ?? (open ? tray : 0);
    final rtl = _rtl;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final dragging = _drag != null;
    final reversed = widget.actions.reversed.toList();

    return CallbackShortcuts(
      bindings: {
        // 열린 트레이를 Esc 로 닫고 초점을 줄로 — 숨긴 트레이 버튼에 초점이 남지 않게
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (open) _close();
        },
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          _SwipeRecognizer:
              GestureRecognizerFactoryWithHandlers<_SwipeRecognizer>(
                () => _SwipeRecognizer(debugOwner: this),
                (r) => r
                  ..onStart = _start
                  ..onUpdate = _update
                  ..onEnd = _end,
              ),
        },
        child: ClipRect(
          child: Stack(
            key: const ValueKey('swipe-actions'),
            children: [
              // 트레이는 줄 뒤에 늘 있다 — 닫혀 있을 땐 보조 기술에서 감춘다. 바탕을 칠하지 않는다
              Positioned.directional(
                textDirection: Directionality.of(context),
                top: 0,
                bottom: 0,
                end: 0,
                width: tray,
                child: ExcludeSemantics(
                  excluding: !open,
                  child: ExcludeFocus(
                    excluding: !open,
                    child: Row(
                      key: const ValueKey('swipe-tray'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 뒤집어 그린다 — 조금만 밀면 바깥쪽부터 드러나므로, 차례대로 두면 파괴적 동작이 제일 먼저 손에 닿는다
                        for (var i = 0; i < reversed.length; i++)
                          PSwipeActionCell(
                            action: reversed[i],
                            index: i,
                            labelWidth: labelWidths[i],
                            rowLabel: widget.rowLabel,
                            // 트레이를 먼저 닫고 실행한다
                            onTap: () {
                              _commit(false);
                              reversed[i].onSelect();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                key: const ValueKey('swipe-row'),
                // 줄은 목록의 폭 전체다 — 줄이 내용만큼 쪼그라들면 밀 자리도 누를 자리도 좁아진다
                width: double.infinity,
                // 줄이 56 보다 낮으면 56 으로 — 동작 칸(56)이 줄 높이에 눌려 넘치지 않게(스펙 swipe-actions.md Size)
                constraints: const BoxConstraints(minHeight: kSwipeMinHeight),
                // 끄는 동안에는 손가락을 1:1 로 — 손을 뗀 뒤 자리를 잡을 때만 150ms 감속(모션 줄이기면 바로)
                duration: dragging || reduceMotion
                    ? Duration.zero
                    : PDuration.d3,
                curve: PEasing.enter,
                transform: Matrix4.translationValues(
                  (rtl ? 1 : -1) * offset,
                  0,
                  0,
                ),
                color: c.bgLayerDefault,
                child: Focus(
                  focusNode: _rowFocus,
                  child: GestureDetector(
                    // 열려 있으면 누르기는 닫기만 한다(열어 둔 걸 못 보고 누르는 일이 많다)
                    behavior: HitTestBehavior.opaque,
                    onTap: open ? _close : null,
                    excludeFromSemantics: true,
                    child: AbsorbPointer(
                      absorbing: open || dragging,
                      // 낮은 줄은 56 안에서 세로 가운데 — 높이는 줄을 따른다(Column min)
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [widget.child],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ⋮ ────────────────────────────────────────────────────────

/// 줄 끝 ⋮ — 같은 [actions] · [rowLabel] 을 [PMenuSheet] 로 연다(이름 "{rowLabel} 더보기" · destructive 는 critical 톤 ·
/// 같은 차례). 트레이와 시트가 한 배열에서 나온다. Button ghost · iconOnly · medium(보이는 40 · 누르는 44).
class PSwipeActionsMore extends StatelessWidget {
  const PSwipeActionsMore({
    super.key,
    required this.actions,
    required this.rowLabel,
    this.moreLabel,
  });

  final List<PSwipeAction> actions;

  /// 줄 제목 — ⋮ 의 이름 "{rowLabel} 더보기" · Menu Sheet 의 제목.
  final String rowLabel;

  /// ⋮ 의 이름을 통째로 바꿔야 할 때(다른 언어) — 기본은 "{rowLabel} 더보기".
  final String? moreLabel;

  @override
  Widget build(BuildContext context) => PButton.icon(
    icon: LucideIcons.ellipsisVertical,
    semanticLabel:
        moreLabel ?? dsL(context)?.dsSwipeMore(rowLabel) ?? '$rowLabel 더보기',
    variant: PButtonVariant.ghost,
    size: PButtonSize.medium,
    onPressed: () => PMenuSheet.show(
      context,
      title: rowLabel,
      groups: [
        PMenuSheetGroup([
          for (final a in actions)
            PMenuSheetItem(
              label: a.label,
              icon: a.icon,
              tone: a.kind == PSwipeActionKind.destructive
                  ? PMenuSheetTone.critical
                  : PMenuSheetTone.neutral,
              enabled: !a.disabled,
              onSelect: a.onSelect,
            ),
        ]),
      ],
    ),
  );
}
