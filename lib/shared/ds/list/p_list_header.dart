import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

/// 아이콘만 있는 동작(ⓘ small 36 · 아이콘 16)의 오른쪽 번짐 — 상자 안 아이콘 여백 10.
const double kListHeaderIconActionBleed = PSpacing.x2_5;

/// 목록 제목의 모양 — mediumWeak(기본: 14 · 500 · 옅은 색 — 줄보다 앞서지 않는다) · boldSolid(14 · 700 · 짙은 색 — 화면을
/// 크게 나누는 묶음에만).
enum PListHeaderVariant { mediumWeak, boldSolid }

/// List Header(목록 제목) — 목록 밖, 바로 위에 두는 제목. 수치 원본은 groo-design `specs/components/list-header.yaml`
/// (값은 `test/fixtures/design_spec/list-header.json`). 웹(desk-front `src/shared/ds/list`)과 같은 값이다.
///
/// 좌우 24(줄과 같다 — 제목과 줄의 왼쪽이 맞는다) · 위아래 8 · 제목과 오른쪽 작은 버튼(도움말 · 전체 보기) 사이 10.
/// 제목은 글(String)이고 낱말 단위로 줄을 바꾼다. 화면 맨 위 제목 · 카드 제목은 목록 제목이 아니다.
///
/// 읽기 — 제목은 머리말(header)로 읽는다. 목록 이름에는 제목 글만 쓴다 — 웹의 `aria-labelledby`(목록 → 제목 글에만 id)
/// 대신 [PList.semanticLabel] 에 같은 제목 글을 준다(오른쪽 버튼 글이 목록 이름에 섞이지 않는다). 오른쪽 버튼은 따로
/// 읽힌다.
class PListHeader extends StatelessWidget {
  const PListHeader({
    super.key,
    required this.title,
    this.variant = PListHeaderVariant.mediumWeak,
    this.action,
    this.headingLevel = 2,
    this.topInset,
    this.inset = PSpacing.globalGutter,
    this.trailing,
    this.titleSuffix,
    this.actionBleed = kTextButtonPaddingX,
    this.tabularFigures = false,
    this.flushAction = false,
  }) : assert(action == null || trailing == null, '오른쪽은 글 버튼과 값 글 중 하나');

  final String title;

  /// 머리말 단계 — 기본 2. 0 이면 머리말로 읽지 않는다(상태 줄). 대화상자 · 시트 안의 목록 제목은 한 단계 낮춰 3 으로 준다(제목은 화면 머리말의 아래다).
  final int headingLevel;
  final PListHeaderVariant variant;

  /// 오른쪽 글 버튼([PTextButton]) — 있을 때만(전체 보기).
  final Widget? action;

  /// 위 여백을 이 값으로 바꾼다(기본: 제목만 있으면 8, 오른쪽 버튼이 있으면 0) — 묶음이 이어지는 자리가 정한다(종류 고르기 1단계:
  /// 첫 묶음 0 · 다음 묶음 16). 웹의 `className="pt-*"` 와 같다.
  final double? topInset;

  /// 좌우 여백 — 기본은 줄과 같은 24. 이미 좌우 24 가 있는 칸 묶음 안(폼의 보유 종목)에서는 0 을 준다(웹의 `className="px-0"` 와 같다).
  final double inset;

  /// 오른쪽 값 글(묶음 합계) — 버튼이 아니라 값이라 줄과 같은 위아래 8 을 지킨다. 머리 폭의 절반을 넘으면 제목 아래 오른쪽 끝으로 간다.
  final Widget? trailing;

  /// 제목 글 바로 뒤에 놓는 것 — 아직 모르는 개수 자리의 [PSkeleton] 처럼("메모 태그 · ▭"). 읽는 이름은 [title] 이다.
  final Widget? titleSuffix;

  /// 오른쪽 동작이 줄 끝에서 바깥으로 내미는 폭 — 글 버튼은 좌우 여백 14(기본), 아이콘만 있는 동작(ⓘ)은 아이콘 안쪽
  /// 여백([kListHeaderIconActionBleed] 10)이라 아이콘 끝이 줄 끝선에 선다.
  final double actionBleed;

  /// 제목의 숫자를 고정폭으로(개수가 바뀌어도 폭이 흔들리지 않게).
  final bool tabularFigures;

  /// 동작(36)이 줄 높이를 늘리지 않게 — 위아래 8 씩 번진다(글 줄 20 + 아래 8 이 머리 높이). 스펙 list-header `action` 의 위아래
  /// −8 블리드. 기본 false(기존 머리는 동작 36 이 줄 높이).
  final bool flushAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final strong = variant == PListHeaderVariant.boldSolid;
    final style = PTypography.t4.copyWith(
      color: strong ? c.fgNeutral : c.fgNeutralSubtle,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
      fontFeatures: tabularFigures
          ? const [FontFeature.tabularFigures()]
          : null,
    );
    return PTouchTargetScope(
      // 글 버튼은 보이는 36 + 위 · 아래 4 = 44 — 줄 밖(이웃)까지 받는다
      slack: 4,
      child: Padding(
        key: const ValueKey('plist-header'),
        padding: EdgeInsets.fromLTRB(
          inset,
          // 글 버튼(36)이 있으면 그 36 이 줄 높이다 — 위아래 8 + 20 과 같다(스펙 marginY −8)
          topInset ?? (action == null ? PSpacing.x2 : 0),
          inset,
          action == null || flushAction ? PSpacing.x2 : 0,
        ),
        // 오른쪽 동작이 머리 폭의 절반을 넘으면 제목 아래 줄 오른쪽 끝으로 간다(03-G 4A)
        child: PHeaderRow(
          gap: PSpacing.x2_5,
          actionBleed: trailing != null ? 0 : actionBleed,
          actionBleedY: flushAction ? _kFlushBleedY : 0,
          expandTitle: false,
          title: Semantics(
            // headingLevel 0 은 머리말이 아니다 — 목록 위 상태 줄("읽지 않은 알림 N개")
            header: headingLevel > 0,
            headingLevel: headingLevel > 0 ? headingLevel : null,
            container: true,
            label: title,
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  text: keepAll(title),
                  children: [
                    if (titleSuffix != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: titleSuffix!,
                      ),
                  ],
                ),
                key: const ValueKey('plist-header-title'),
                style: style,
              ),
            ),
          ),
          action: action == null
              ? trailing
              : Transform.translate(
                  offset: Offset(actionBleed, 0),
                  child: flushAction
                      ? _ActionFlush(bleed: _kFlushBleedY, child: action!)
                      : action,
                ),
        ),
      ),
    );
  }
}

const double _kFlushBleedY = PSpacing.x2;

/// 동작을 위아래로 [bleed] 씩 번지게 둔다 — 자기 높이는 자식보다 2 × bleed 작고, 번진 자리도 눌림을 받는다.
class _ActionFlush extends SingleChildRenderObjectWidget {
  const _ActionFlush({required this.bleed, required Widget child})
    : super(child: child);

  final double bleed;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderActionFlush(bleed);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderActionFlush).bleed = bleed;
  }
}

class _RenderActionFlush extends RenderShiftedBox {
  _RenderActionFlush(this._bleed) : super(null);

  double _bleed;
  set bleed(double v) {
    if (_bleed == v) return;
    _bleed = v;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(0, super.computeMinIntrinsicHeight(width) - 2 * _bleed);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(0, super.computeMaxIntrinsicHeight(width) - 2 * _bleed);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child!.getDryLayout(constraints.loosen());
    return constraints.constrain(
      Size(c.width, math.max(0, c.height - 2 * _bleed)),
    );
  }

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(c.size.width, math.max(0, c.size.height - 2 * _bleed)),
    );
    (c.parentData! as BoxParentData).offset = Offset(
      0,
      (size.height - c.size.height) / 2,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (position.dx < 0 ||
        position.dx >= size.width ||
        position.dy < -_bleed ||
        position.dy >= size.height + _bleed) {
      return false;
    }
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
