import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all_fit_text.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

/// Card 의 부품 — 머리 · 본문 · 지표 · 증감 · 순자산 글. 규칙은 [PCard] 머리 설명이다.

const _tabular = [FontFeature.tabularFigures()];

/// 면 — standard(기본, 바닥 위 흰 면 + 1px 테두리) · hero(순자산 — 브랜드 채움 · 흰 글자, 한 화면에 하나).
enum PCardVariant { standard, hero }

/// 본문 — content(기본, 여백 24) · list(List 를 담는다 — 좌우 0, 카드 아래 12) · accordion([PAccordion] 을 담는다 —
/// 좌우 0, 카드 아래 8).
enum PCardBody { content, list, accordion }

/// 누름 — none(기본, 보기만) · whole(카드 전체가 한 곳 — 누름 색 + 2px 축소) · peers(카드를 누르면 열리고 안에 대등한
/// 동작이 더 있다 — 색만 바뀌고 안의 버튼이 따로 눌린다).
enum PCardPress { none, whole, peers }

/// 카드 안의 머리 · 증감이 읽는 값 — 면의 종류와 본문.
class PCardScope extends InheritedWidget {
  const PCardScope({
    super.key,
    required this.variant,
    required this.body,
    required super.child,
    this.titleNamedByCard = false,
  });

  final PCardVariant variant;
  final PCardBody body;

  /// 카드가 이름 있는 카드 링크(peers)라서 보이는 제목을 따로 읽지 않는다 — 카드의 이름이 제목이다(03D-014, card.md ARIA
  /// "peers 는 카드 링크 + 버튼이 형제"). 한 카드를 같은 이름으로 두 번 읽지 않게.
  final bool titleNamedByCard;

  static PCardScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PCardScope>();

  @override
  bool updateShouldNotify(PCardScope oldWidget) =>
      variant != oldWidget.variant ||
      body != oldWidget.body ||
      titleNamedByCard != oldWidget.titleNamedByCard;
}

/// 누르는 순간 기준 길이 max(높이, 폭 ÷ 4, 24) — 넓은 카드도 세로 2px 만큼만 준다(Button · List 와 같은 식).
double cardPressBasis(Size size) =>
    math.max(size.height, math.max(size.width / 4, 24));

/// 누르는 영역을 보이는 크기와 따로 [minSize] 까지 넓힌다 — 놓인 자리(레이아웃)는 그대로다(Button 의 것과 같은 방법). 부모
/// 상자 밖의 점은 부모가 먼저 거절하므로 이것만으로는 부모 줄 안에서만 넓어진다 — 부모 밖(머리 줄 위아래 6)까지 받으려면 더
/// 위에서 [PTouchTargetScope] 가 감싸야 한다. Card 머리 동작 · Accordion 모두 펼치기가 같이 쓴다.
class PTouchTarget extends SingleChildRenderObjectWidget {
  const PTouchTarget({super.key, required this.minSize, required super.child});

  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchTarget(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderProxyBox renderObject,
  ) {
    (renderObject as _RenderTouchTarget).minSize = minSize;
  }
}

/// 보이는 상자 밖까지 누르는 영역을 넓힌 렌더 객체 — [PTouchTargetScope] 가 찾아 부모 상자 밖의 점을 이어 준다.
abstract interface class PTouchExtendable implements RenderBox {
  /// 넓힌 누르는 영역(이 객체의 지역 좌표 — 보이는 상자 밖은 음수 · 큰 값).
  Rect get touchArea;
}

class _RenderTouchTarget extends RenderProxyBox implements PTouchExtendable {
  _RenderTouchTarget(this.minSize);

  double minSize;

  @override
  Rect get touchArea => area;

  /// 넓힌 누르는 영역 — 보이는 상자에서 모자란 만큼 사방으로.
  Rect get area {
    final dx = math.max(0.0, (minSize - size.width) / 2);
    final dy = math.max(0.0, (minSize - size.height) / 2);
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!area.contains(position)) return false;
    final inside = size.contains(position)
        ? position
        : size.center(Offset.zero);
    if (hitTestChildren(result, position: inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// [PTouchTarget] 이 넓힌 누르는 영역을 부모 상자 밖에서도 받게 한다 — 안쪽 [PTouchTarget] 들을 찾아, 보이는 상자 밖 · 넓힌
/// 영역 안의 점을 그 대상으로 이어 준다(보이는 자리 · 레이아웃은 그대로). Card 가 머리 동작의 44 를 지킨다 — 머리 줄은 32 라
/// 위아래 6 은 줄 밖이다(Q-011-8, 6B 44 × 44).
///
/// [slack] 을 주면 이 상자의 위 · 아래 · 옆으로 그만큼 바깥의 점도 받는다 — 놓인 자리는 그대로이고, 부모가 그 점을 이
/// 상자에 넘겨 주는 곳(이웃 요소가 있는 부모 안)에서만 쓸모가 있다. 목록 제목 글 버튼(36 → 44 = 4)과 Field 밖 단독 체크 ·
/// 라디오 묶음(줄 32 → 44 = 6)이 쓴다.
class PTouchTargetScope extends SingleChildRenderObjectWidget {
  const PTouchTargetScope({super.key, this.slack = 0, required super.child});

  final double slack;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTouchTargetScope(slack);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderProxyBox renderObject,
  ) {
    (renderObject as _RenderTouchTargetScope).slack = slack;
  }
}

class _RenderTouchTargetScope extends RenderProxyBox {
  _RenderTouchTargetScope(this.slack);

  double slack;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // 이 상자 밖의 점 — 자식이 스스로 넘친 자리를 받는 경우(Field 머리 동작)가 있어 자식에게 그대로 넘긴다
    if (!(Offset.zero & size).inflate(slack).contains(position)) {
      return child?.hitTest(result, position: position) ?? false;
    }
    var extended = false;
    {
      void visit(RenderObject node) {
        // 가장 먼저 닿은 하나만 — 이웃 줄의 넓힌 영역이 맞닿아도 한 점은 한 줄만 받는다
        if (extended) return;
        if (node is PTouchExtendable) {
          if (!node.attached || !node.hasSize) return;
          final transform = node.getTransformTo(this);
          final det = transform.determinant();
          if (det == 0 || det.isNaN) return;
          final local = MatrixUtils.transformPoint(
            Matrix4.inverted(transform),
            position,
          );
          // 보이는 상자 안은 보통 길로 받는다 — 밖 · 넓힌 영역 안만 여기서 잇는다
          if (node.size.contains(local) || !node.touchArea.contains(local)) {
            return;
          }
          extended |= result.addWithPaintTransform(
            transform: transform,
            position: position,
            hitTest: (r, p) => node.hitTest(r, position: p),
          );
          return;
        }
        node.visitChildren(visit);
      }

      visit(this);
    }
    // 대상이 먼저 — 가장 깊은 것이 앞에 와야 제스처 경쟁에서 이긴다
    // 넓힌 영역으로 이미 받았으면 보통 길은 다시 타지 않는다 — 같은 대상이 두 번 등록되면 제스처가 깨진다
    if (extended) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return size.contains(position)
        ? super.hitTest(result, position: position)
        : (child?.hitTest(result, position: position) ?? false);
  }
}

// ── 머리 ─────────────────────────────────────────────────────

/// 머리 — 제목과 오른쪽 동작 한 줄. 글 카드는 카드 여백 안 · 아래 8, 목록 · 아코디언 카드는 위 24 · 좌우 24 · 아래 4.
///
/// [actionLabel] · [onAction] 을 주면 오른쪽에 "전체 보기" 같은 동작이 선다 — 글 버튼(SEED Text Button — 보이는 36 · 누르는 44), 읽는 이름은
/// "{제목} {글}"(무엇의 동작인지 넣는다 — 글은 부르는 쪽이 넘긴다).
class PCardHeader extends StatelessWidget {
  const PCardHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.headingLevel = 2,
    this.titleSuffix,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         '동작은 글(actionLabel)과 누를 때(onAction)를 함께 준다',
       );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 제목 단계(웹 `as` — 기본 2, 화면 제목 아래 단계)
  final int headingLevel;

  /// 제목 글 바로 뒤 같은 줄에 붙는 덧붙임(배지 · 합계) — 제목 `Semantics(header)` 밖에 둔다(제목 이름에 섞이지 않게).
  /// 제목 칸이 좁으면 제목과 함께 다음 줄로 넘어간다(I-06 10 — 화면 몫, 스펙의 "제목 하나" 는 제목 글을 말한다).
  final Widget? titleSuffix;

  @override
  Widget build(BuildContext context) {
    final scope = PCardScope.maybeOf(context);
    final body = scope?.body ?? PCardBody.content;
    final padding = switch (body) {
      PCardBody.content => const EdgeInsets.only(bottom: PSpacing.x2),
      PCardBody.list || PCardBody.accordion => const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x1,
      ),
    };
    final titleText = Text(
      keepAll(title),
      key: const ValueKey('card-title'),
      semanticsLabel: title,
      style: PTypography.t5.copyWith(
        color: context.colors.fgNeutral,
        fontWeight: FontWeight.w700,
      ),
    );
    final titleNode = scope?.titleNamedByCard == true
        // 카드 링크가 이 제목을 이름으로 갖는다 — 같은 글을 두 번 읽지 않는다
        ? ExcludeSemantics(child: titleText)
        : Semantics(header: true, headingLevel: headingLevel, child: titleText);
    return Padding(
      key: const ValueKey('card-header'),
      padding: padding,
      // 오른쪽 동작이 머리 폭의 절반을 넘으면 제목 아래 줄 오른쪽 끝으로 간다(03-G 4A)
      child: PHeaderRow(
        gap: PSpacing.x2,
        actionBleed: kTextButtonPaddingX,
        title: titleSuffix == null
            ? titleNode
            : Wrap(
                key: const ValueKey('card-title-wrap'),
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: PSpacing.x1_5,
                children: [titleNode, titleSuffix!],
              ),
        action: actionLabel == null
            ? null
            : PTextButton(
                label: actionLabel!,
                semanticLabel: '$title $actionLabel',
                onPressed: onAction,
                bleedEnd: true,
              ),
      ),
    );
  }
}

// ── 본문 ─────────────────────────────────────────────────────

/// 본문 — 카드 여백 안, 요소 사이 12. 목록 카드는 이것 없이 [PList] 를 바로 넣는다.
class PCardContent extends StatelessWidget {
  const PCardContent({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: PSpacing.x3,
    children: children,
  );
}

// ── 증감 ─────────────────────────────────────────────────────

/// 증감의 방향 — 좋고 나쁨이 아니라 방향이다. up ▲ `fg-critical`(빨강) · down ▼ `fg-informative`(파랑) · flat 은 화살표
/// 없이 "변화 없음".
enum PDeltaDirection { up, down, flat }

/// 값 앞의 부호(+ − ± 와 공백)를 뗀다 — "+12%" · "−12%" · "+-12.5%" 를 화살표와 겹쳐 쓰지 않는다.
@visibleForTesting
String unsignedDelta(String value) =>
    value.replaceFirst(RegExp(r'^[\s+\-−±]+'), '');

/// 보조 기술이 읽는 기본 문장 — "{text} {value} 늘었어요 · 줄었어요"(flat 은 "{text} 변화가 없어요").
@visibleForTesting
String deltaSentence(
  PDeltaDirection direction,
  String? value,
  String? text, {
  AppLocalizations? l10n,
}) {
  final base = (text ?? '').trim();
  if (direction == PDeltaDirection.flat) {
    return [
      base,
      l10n?.dsDeltaNoChangeSentence ?? '변화가 없어요',
    ].where((s) => s.isNotEmpty).join(' ');
  }
  final amount = unsignedDelta(value ?? '').trim();
  return [
    base,
    amount,
    direction == PDeltaDirection.up
        ? (l10n?.dsDeltaIncreased ?? '늘었어요')
        : (l10n?.dsDeltaDecreased ?? '줄었어요'),
  ].where((s) => s.isNotEmpty).join(' ');
}

/// 증감 줄 — [direction] 에 따라 ▲ · ▼ + [value]("12%"), 뒤에 기준 [text]("지난달보다"). 13 · 500(값) · 400(글), 고정폭
/// 숫자. 순자산 카드 안에서는 모두 흰 글자(채움 위 빨강 · 파랑은 1.66 · 1.65 — 하나뿐인 예외).
///
/// 읽기 — 화면의 조각(화살표 · 값 · 글)은 읽지 않고 [srText] 한 문장을 읽는다. 기본은 방향에서 만든 문장이고, 좋고 나쁨을
/// 말하려면 직접 준다("지난달보다 12% 더 썼어요"). flat 은 "변화 없음" 만 보이고 기준 글은 읽는 문장에만 쓴다.
class PDelta extends StatelessWidget {
  const PDelta({
    super.key,
    required this.direction,
    this.value,
    this.text,
    this.srText,
  });

  final PDeltaDirection direction;

  /// 변화량 — "12%" · "1,240원". 부호는 화살표가 말한다(앞의 + − ± 는 뗀다).
  final String? value;

  /// 기준 — "지난달보다"
  final String? text;

  /// 읽는 문장 — 기본은 [deltaSentence]
  final String? srText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hero = PCardScope.maybeOf(context)?.variant == PCardVariant.hero;
    final tone = hero
        ? c.staticWhite
        : switch (direction) {
            PDeltaDirection.up => c.fgCritical,
            PDeltaDirection.down => c.fgInformative,
            PDeltaDirection.flat => c.fgNeutralSubtle,
          };
    final arrow = switch (direction) {
      PDeltaDirection.up => '▲',
      PDeltaDirection.down => '▼',
      PDeltaDirection.flat => null,
    };
    final shown = arrow == null
        ? (dsL(context)?.dsDeltaNone ?? '변화 없음')
        : '$arrow ${unsignedDelta(value ?? '')}'.trimRight();
    return Semantics(
      container: true,
      label:
          srText ?? deltaSentence(direction, value, text, l10n: dsL(context)),
      excludeSemantics: true,
      child: Wrap(
        spacing: PSpacing.x1,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text(
            keepAll(shown),
            key: const ValueKey('delta-value'),
            style: PTypography.t3.copyWith(
              color: tone,
              fontWeight: FontWeight.w500,
              fontFeatures: _tabular,
            ),
          ),
          // flat 은 "변화 없음" 만 — "변화 없음 지난달보다" 가 되지 않게
          if (direction != PDeltaDirection.flat &&
              text != null &&
              text!.isNotEmpty)
            Text(
              keepAll(text!),
              key: const ValueKey('delta-text'),
              style: PTypography.t3.copyWith(
                color: hero ? c.staticWhite : c.fgNeutralSubtle,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

// ── 지표 ─────────────────────────────────────────────────────

/// 지표 크기 — large(기본, 24/32 — 폰은 카드 하나에 숫자 하나) · small(20/27 — 데스크톱 격자에 셋 · 넷씩).
enum PCardStatSize { large, small }

/// 지표 — [label](13 · 500 · 무엇의 숫자인지) · [value](700 · 고정폭 숫자, 위 4) · [delta](위 4).
///
/// 숫자는 쓰는 쪽이 원까지 만든다("1,240,000원" · 빼기는 U+2212) — 1억이 넘어도 줄이지 않고, 칸보다 길면 줄이 바뀐다.
/// 숫자가 굴러가는 애니메이션을 두지 않는다.
class PCardStat extends StatelessWidget {
  const PCardStat({
    super.key,
    required this.label,
    required this.value,
    this.size = PCardStatSize.large,
    this.delta,
    this.fit = false,
  });

  final String label;
  final String value;
  final PCardStatSize size;
  final PDelta? delta;

  /// 값이 "앞 말 + 금액"("≈ 1,234,567원")일 때 켠다 — 칸 폭을 보고 띄어쓰기에서 먼저 넘기고, 쉼표 뒤 줄바꿈은 금액 낱말이 칸보다
  /// 길 때만 쓴다([KeepAllFitText], Typography v114). 폭을 재므로 **부모 폭이 정해진 자리에서만** 쓴다(IntrinsicWidth 같은
  /// 고유치 부모 아래에서는 끈다). 기본(끔)은 금액 하나를 쉼표 뒤에서 꺾는 [keepAllAmount] 다.
  final bool fit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = size == PCardStatSize.large
        ? PTypography.t9
        : PTypography.t7;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keepAll(label),
            key: const ValueKey('card-stat-label'),
            semanticsLabel: label,
            style: PTypography.t3.copyWith(
              color: c.fgNeutralSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: PSpacing.x1),
            child: fit
                ? KeepAllFitText(
                    value,
                    key: const ValueKey('card-stat-value'),
                    style: valueStyle.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  )
                : Text(
                    keepAllAmount(value),
                    key: const ValueKey('card-stat-value'),
                    semanticsLabel: value,
                    style: valueStyle.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  ),
          ),
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x1),
              child: delta,
            ),
        ],
      ),
    );
  }
}

// ── 순자산 ───────────────────────────────────────────────────

/// 순자산 카드의 라벨 — 13 · 500, 흰 글자(흐리게 두지 않는다).
class PCardHeroLabel extends StatelessWidget {
  const PCardHeroLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    keepAll(text),
    key: const ValueKey('card-hero-label'),
    semanticsLabel: text,
    style: PTypography.t3.copyWith(
      color: context.colors.staticWhite,
      fontWeight: FontWeight.w500,
    ),
  );
}

/// 순자산 카드의 금액 — 32/42 · 700 · 고정폭 숫자, 위 6, 흰 글자.
class PCardHeroAmount extends StatelessWidget {
  const PCardHeroAmount(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PSpacing.x1_5),
    child: Text(
      keepAllAmount(text),
      key: const ValueKey('card-hero-amount'),
      semanticsLabel: text,
      style: PTypography.t12.copyWith(
        color: context.colors.staticWhite,
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
      ),
    ),
  );
}

/// 순자산 카드 아래 글 — 13 · 400, 위 4, 흰 글자. 글([text]) 대신 [PDelta] 같은 위젯([child])도 둔다.
class PCardHeroDetail extends StatelessWidget {
  const PCardHeroDetail({super.key, this.text, this.child})
    : assert((text == null) != (child == null), '글(text)이나 위젯(child) 하나만 준다');

  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PSpacing.x1),
    child:
        child ??
        Text(
          keepAll(text!),
          key: const ValueKey('card-hero-detail'),
          semanticsLabel: text,
          style: PTypography.t3.copyWith(
            color: context.colors.staticWhite,
            fontWeight: FontWeight.w400,
          ),
        ),
  );
}
