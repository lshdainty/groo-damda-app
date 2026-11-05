import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 머리 한 줄 — 제목과 오른쪽 동작. 오른쪽 동작이 머리 폭의 절반을 넘으면(제목에 최소 50% 를 남기려면 줄이 모자라면) 동작이
/// **제목 아래 줄 오른쪽 끝**으로 내려간다(03-G 결정 4A). 평소(글자 100% · 130%)에는 한 줄이다.
///
/// 웹의 `flex-wrap [&>:first-child:not(:last-child)]:min-w-[50%] flex-1 [&>:last-child:not(:first-child)]:ml-auto` 와 같은 판정이다:
/// 한 줄이려면 `동작 폭 + 간격 + 머리 폭의 50% ≤ 머리 폭`. 동작은 자연 폭으로 잰다(줄이지 않는다).
///
/// 한 줄이면 제목이 남는 폭을 쓰고([expandTitle] 면 채우고, 아니면 글 폭만) 동작은 오른쪽 끝에 서며 둘은 세로 가운데다.
/// 내려가면 제목은 머리 폭 전체를 쓰고 그 아래 [gap] 을 두고 동작이 오른쪽 끝에 선다. 동작이 없으면 제목만 그린다.
///
/// 쓰는 곳 — 새 공용 머리 셋: [PCardHeader] · [PAccordionHeader] · [PListHeader]. 옛 띠 머리(`PFlatSection` 등)는 건드리지
/// 않는다(화면 이관 때 ds 머리로 바뀌며 따라온다 — 사용자 결정 2026-10-22).
class PHeaderRow extends MultiChildRenderObjectWidget {
  PHeaderRow({
    super.key,
    required Widget title,
    Widget? action,
    this.gap = 8,
    this.expandTitle = true,
    this.actionBleed = 0,
  }) : super(children: [title, ?action]);

  /// 제목과 동작 사이(한 줄) · 내려갔을 때 두 줄 사이.
  final double gap;

  /// 동작이 줄 끝에서 바깥으로 내미는 폭(글 버튼의 좌우 여백 14) — 웹의 `-mr-x3_5` 와 같다. 한 줄 판정과 제목이 쓸 폭을 셀 때 동작
  /// 폭에서 뺀다(그리기를 옮기는 것은 동작 쪽 몫이다).
  final double actionBleed;

  /// 한 줄일 때 제목이 남는 폭을 모두 쓴다(카드 · 아코디언 머리). 아니면 글 폭만(목록 제목).
  final bool expandTitle;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeaderRow(
    gap: gap,
    expandTitle: expandTitle,
    actionBleed: actionBleed,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHeaderRow)
      ..gap = gap
      ..expandTitle = expandTitle
      ..actionBleed = actionBleed;
  }
}

class _HeaderRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeaderRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeaderRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeaderRowParentData> {
  _RenderHeaderRow({
    required double gap,
    required bool expandTitle,
    required double actionBleed,
  }) : _gap = gap,
       _expandTitle = expandTitle,
       _actionBleed = actionBleed;

  double _actionBleed;
  set actionBleed(double value) {
    if (_actionBleed == value) return;
    _actionBleed = value;
    markNeedsLayout();
  }

  double _gap;
  double get gap => _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  bool _expandTitle;
  bool get expandTitle => _expandTitle;
  set expandTitle(bool value) {
    if (_expandTitle == value) return;
    _expandTitle = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeaderRowParentData) {
      child.parentData = _HeaderRowParentData();
    }
  }

  RenderBox? get _title => firstChild;
  RenderBox? get _action {
    final first = firstChild;
    return first == null ? null : childAfter(first);
  }

  /// 한 줄에 둘 수 있는가 — 제목이 50% 를 지키고도 동작이 든다.
  bool _fitsOneLine(double width, double actionWidth) =>
      actionWidth - _actionBleed + _gap + width * 0.5 <= width + 0.01;

  static const _unbounded = BoxConstraints();

  @override
  void performLayout() {
    size = _layout(constraints, ChildLayoutHelper.layoutChild);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild, dry: true);

  Size _layout(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) layoutChild, {
    bool dry = false,
  }) {
    final title = _title;
    final action = _action;
    if (title == null) return constraints.smallest;
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;
    final loose = BoxConstraints(maxWidth: width);

    if (action == null) {
      final t = layoutChild(
        title,
        _expandTitle && width.isFinite
            ? BoxConstraints.tightFor(width: width)
            : loose,
      );
      if (!dry) _parent(title).offset = Offset.zero;
      return constraints.constrain(t);
    }

    final a = layoutChild(action, _unbounded);
    if (width.isFinite && !_fitsOneLine(width, a.width)) {
      // 내려간다 — 제목은 머리 폭 전체, 그 아래 동작이 오른쪽 끝
      final t = layoutChild(
        title,
        _expandTitle ? BoxConstraints.tightFor(width: width) : loose,
      );
      if (!dry) {
        _parent(title).offset = Offset.zero;
        _parent(action).offset = Offset(width - a.width, t.height + _gap);
      }
      return constraints.constrain(Size(width, t.height + _gap + a.height));
    }
    // 한 줄 — 제목이 남는 폭, 동작은 오른쪽 끝, 세로 가운데
    final room = width.isFinite
        ? math.max(0.0, width - (a.width - _actionBleed) - _gap)
        : width;
    final t = layoutChild(
      title,
      _expandTitle && width.isFinite
          ? BoxConstraints.tightFor(width: room)
          : BoxConstraints(maxWidth: room),
    );
    final h = math.max(t.height, a.height);
    final rowWidth = width.isFinite ? width : t.width + _gap + a.width;
    if (!dry) {
      _parent(title).offset = Offset(0, (h - t.height) / 2);
      _parent(action).offset = Offset(rowWidth - a.width, (h - a.height) / 2);
    }
    return constraints.constrain(Size(rowWidth, h));
  }

  _HeaderRowParentData _parent(RenderBox child) =>
      child.parentData! as _HeaderRowParentData;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => null;

  // ── 고유 크기 ──
  @override
  double computeMinIntrinsicWidth(double height) {
    final t = _title?.getMinIntrinsicWidth(height) ?? 0;
    final a = _action?.getMinIntrinsicWidth(height) ?? 0;
    return math.max(t, a);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final t = _title?.getMaxIntrinsicWidth(height) ?? 0;
    final a = _action?.getMaxIntrinsicWidth(height) ?? 0;
    return _action == null ? t : t + _gap + a;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(width);

  double _intrinsicHeight(double width) {
    final title = _title;
    final action = _action;
    if (title == null) return 0;
    if (action == null) return title.getMaxIntrinsicHeight(width);
    final aw = action.getMaxIntrinsicWidth(double.infinity);
    final ah = action.getMaxIntrinsicHeight(aw);
    if (width.isFinite && !_fitsOneLine(width, aw)) {
      return title.getMaxIntrinsicHeight(width) + _gap + ah;
    }
    final room = width.isFinite
        ? math.max(0.0, width - (aw - _actionBleed) - _gap)
        : width;
    return math.max(title.getMaxIntrinsicHeight(room), ah);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  /// 동작이 줄 끝 밖으로 번진 폭([_actionBleed])만큼 오른쪽을 더 받는다 — 보이는 단추가 줄 밖으로 나간 자리가 눌리지 않는
  /// 죽은 띠로 남지 않게(기본 크기 검사는 줄 안만 받는다).
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final bleed = _action == null ? 0.0 : _actionBleed;
    if (position.dx < 0 ||
        position.dx >= size.width + bleed ||
        position.dy < 0 ||
        position.dy >= size.height) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
