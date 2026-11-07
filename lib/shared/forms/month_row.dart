import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart';

/// 달 줄 — 달 글 + 아래 꺾쇠(‹ › 없음, 10-29 — 연 · 월은 휠로만 옮긴다)와 오른쪽 동작(스펙 부품이 아니라 ds 를 조합한 줄 조각). 달 글을 누르면 달 고르기.
/// 예산 · 캘린더가 함께 쓰고, 둘레 여백 · 글 크기 · 최소 높이만 화면이 정한다.
class MonthRow extends StatelessWidget {
  const MonthRow({
    super.key,
    required this.month,
    required this.onPick,
    required this.trailing,
    required this.padding,
    required this.labelStyle,
    this.minHeight = 0,
    this.tabularFigures = false,
  });

  final DateTime month;
  final VoidCallback onPick;
  final Widget trailing;
  final EdgeInsets padding;
  final TextStyle labelStyle;

  /// 줄 최소 높이 — 캘린더 52. 글자가 커지면 늘어난다.
  final double minHeight;

  /// 달 글 숫자를 고정폭으로 — 웹 `MonthTitle`(`tabular-nums`)을 쓰는 예산이 켠다. 캘린더 머리 글은 웹도 끈다.
  final bool tabularFigures;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: padding,
        // 한 줄에 안 들어가면(좁은 폭 · 큰 글자) 오른쪽 동작이 아래 줄 오른쪽 끝으로 내려간다(03G-029 A — 웹 `ml-auto` 와 같다)
        child: Align(
          alignment: Alignment.centerLeft,
          child: _MonthBar(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: PressArea(
                      enabled: true,
                      onTap: onPick,
                      touchMin: 0,
                      focusRing: const PFocusRingStyle(radius: PRounded.r2),
                      semantics: (child, enabled, onTap) => Semantics(
                        container: true,
                        button: true,
                        label: yearMonth(month),
                        onTap: onTap,
                        excludeSemantics: true,
                        child: child,
                      ),
                      builder: (context, pressed, size) => Container(
                        constraints: const BoxConstraints(
                          minHeight: PTouch.min,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: PSpacing.x2_5,
                        ),
                        decoration: BoxDecoration(
                          color: pressed
                              ? c.bgLayerDefaultPressed
                              : c.bgLayerDefaultPressed.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(PRounded.r2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: PSpacing.x1,
                          children: [
                            Flexible(
                              child: Text(
                                yearMonth(month),
                                style: labelStyle.copyWith(
                                  color: c.fgNeutral,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: tabularFigures
                                      ? const [FontFeature.tabularFigures()]
                                      : null,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: c.fgNeutralMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 글 버튼은 가운데 맞춤 상자라 폭을 다 채우려 한다 — 제 폭만 쓰게 푼다
              UnconstrainedBox(child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}

/// 달 글(첫째)과 오른쪽 동작(둘째)을 한 줄에 두되, 둘이 한 줄에 안 들어가면(큰 글자) 동작을 아래 줄 오른쪽 끝으로 내린다.
/// 달 글은 어느 쪽이든 내용 폭만 쓰고 왼쪽에 선다(OverflowBar 는 내릴 때 모든 자식을 한 쪽으로 맞춰 달 글이 밀렸다).
class _MonthBar extends MultiChildRenderObjectWidget {
  const _MonthBar({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMonthBar();
}

class _MonthBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderMonthBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MonthBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MonthBarParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MonthBarParentData) {
      child.parentData = _MonthBarParentData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final loose = constraints.loosen();
    final a = firstChild!.getDryLayout(loose);
    final b = lastChild!.getDryLayout(loose);
    final fits = a.width + b.width <= constraints.maxWidth;
    return constraints.constrain(
      Size(
        constraints.maxWidth,
        fits
            ? (a.height > b.height ? a.height : b.height)
            : a.height + b.height,
      ),
    );
  }

  @override
  void performLayout() {
    final loose = constraints.loosen();
    final a = firstChild!;
    final b = lastChild!;
    a.layout(loose, parentUsesSize: true);
    b.layout(loose, parentUsesSize: true);
    final w = constraints.maxWidth;
    final aData = a.parentData! as _MonthBarParentData;
    final bData = b.parentData! as _MonthBarParentData;
    if (a.size.width + b.size.width <= w) {
      final h = a.size.height > b.size.height ? a.size.height : b.size.height;
      aData.offset = Offset(0, (h - a.size.height) / 2);
      bData.offset = Offset(w - b.size.width, (h - b.size.height) / 2);
      size = constraints.constrain(Size(w, h));
    } else {
      aData.offset = Offset.zero;
      bData.offset = Offset(w - b.size.width, a.size.height);
      size = constraints.constrain(Size(w, a.size.height + b.size.height));
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      firstChild!.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      firstChild!.getMaxIntrinsicHeight(width) +
      lastChild!.getMaxIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
