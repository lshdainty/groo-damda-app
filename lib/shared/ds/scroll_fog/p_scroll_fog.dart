import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 자리 — 흐림의 방향 · 깊이와 안쪽 여백을 정한다.
enum PScrollFogUse {
  /// 기본 — 카드 · 상자 안의 높이 · 폭을 정한 스크롤. 넘치는 방향의 양 끝 20, 안쪽 여백 20
  box,

  /// 가로 줄 — 칩 필터 바 · 제안 칩 줄 · 가로 카드 줄. 좌우 20, 안쪽 여백은 화면 여백 24
  row,

  /// 시트 · 대화상자 · 팝오버의 넘칠 수 있는 본문. 위 20 · 아래 80, 안쪽 여백도 위 20 · 아래 80
  overlayBody,

  /// 바닥 고정 버튼이 있는 화면 전체 스크롤. 위 20 · 아래 80 — 바닥 버튼 위에서 끝난다
  page,
}

/// 자리의 값(scroll-fog.yaml) — 흐림 깊이와 흐린 쪽 안쪽 여백. 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
({double fogStart, double fogEnd, double padStart, double padEnd})
scrollFogMetrics(PScrollFogUse use) => switch (use) {
  PScrollFogUse.box => (fogStart: 20, fogEnd: 20, padStart: 20, padEnd: 20),
  PScrollFogUse.row => (
    fogStart: 20,
    fogEnd: 20,
    padStart: PSpacing.globalGutter,
    padEnd: PSpacing.globalGutter,
  ),
  PScrollFogUse.overlayBody ||
  PScrollFogUse.page => (fogStart: 20, fogEnd: 80, padStart: 20, padEnd: 80),
};

/// Scroll Fog — 스크롤되는 영역의 끝을 흐려 뒤에 더 있다는 것을 알린다. 구조는 SEED Scroll Fog(2026-10-03), 수치
/// 원본은 groo-design `specs/components/scroll-fog.yaml`(값은 `test/fixtures/design_spec/scroll-fog.json`).
/// 웹(desk-front `src/shared/ds/scroll-fog`)과 같은 값이다.
///
/// 색을 덮지 않는 마스크(gradient-fade-mask — 투명도만 바꾼다)라 어느 바탕에서도 같고, 흐린 자리도 그대로 눌린다.
/// 스크롤 위치 · 넘침을 재지 않고 늘 켜 둔다. 흐린 쪽에 깊이 이상의 안쪽 여백을 둬 끝까지 스크롤하면 흐림이 빈 여백
/// 위에 놓인다. 안쪽 여백은 내용과 함께 스크롤된다.
///
/// 이 위젯이 스크롤 상자다 — 높이 · 폭은 놓인 자리가 정한다. 다른 스크롤 상자(목록 · 시트 본문)에는 [PScrollFogMask] 로
/// 같은 흐림만 건다(여백은 그 부품이 둔다). 부품이 제 안개를 가진 자리(Wheel Picker 등)에는 겹쳐 걸지 않는다.
///
/// 웹의 스크롤 여유(scroll-padding — 키보드로 옮긴 요소가 흐림 아래 멈추지 않게)는 Flutter 에 같은 것이 없다 —
/// 끝의 안쪽 여백이 그 자리를 대신한다.
class PScrollFog extends StatelessWidget {
  const PScrollFog({
    super.key,
    this.use = PScrollFogUse.box,
    this.axis,
    this.controller,
    required this.child,
  });

  final PScrollFogUse use;

  /// 스크롤 방향 — row 는 가로, 나머지는 세로가 기본. box 는 가로로도 넘길 수 있다.
  final Axis? axis;
  final ScrollController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = scrollFogMetrics(use);
    final direction =
        axis ?? (use == PScrollFogUse.row ? Axis.horizontal : Axis.vertical);
    final padding = direction == Axis.vertical
        ? EdgeInsets.only(top: m.padStart, bottom: m.padEnd)
        : EdgeInsets.only(left: m.padStart, right: m.padEnd);

    Widget scroll = SingleChildScrollView(
      controller: controller,
      scrollDirection: direction,
      padding: padding,
      child: child,
    );
    // 가로 줄은 스크롤바를 숨긴다
    if (use == PScrollFogUse.row) {
      scroll = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: scroll,
      );
    }
    // 안쪽 요소를 보이는 자리로 올리는 함수(revealBelowFog)가 흐림 깊이를 알도록 알린다
    return PScrollFogMask(
      axis: direction,
      start: m.fogStart,
      end: m.fogEnd,
      child: PScrollFogInset(
        top: direction == Axis.vertical ? m.fogStart : 0,
        child: scroll,
      ),
    );
  }
}

/// 이 아래 스크롤 상자 위쪽이 흐림으로 덮여 있다는 것을 알린다 — [top] 은 위 흐림 깊이(px).
/// `revealBelowFog` 가 읽어, 올린 요소가 흐림 아래에 놓이게 한다.
class PScrollFogInset extends InheritedWidget {
  const PScrollFogInset({super.key, required this.top, required super.child});

  final double top;

  /// 가장 가까운 흐림의 위 깊이 — 없으면 0.
  static double topOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PScrollFogInset>()?.top ?? 0;

  @override
  bool updateShouldNotify(PScrollFogInset old) => old.top != top;
}

/// 흐림만 — 다른 부품의 스크롤 상자에 같은 마스크를 건다(웹의 useScrollFog). 여백은 그 부품이 둔다.
class PScrollFogMask extends StatelessWidget {
  const PScrollFogMask({
    super.key,
    this.axis = Axis.vertical,
    this.start = 20,
    this.end = 20,
    required this.child,
  });

  final Axis axis;

  /// 시작 쪽(위 · 왼쪽) · 끝 쪽(아래 · 오른쪽) 흐림 깊이(px).
  final double start;
  final double end;
  final Widget child;

  /// 흐린 쪽마다 층 하나 — 시작 쪽 · 끝 쪽. 상자가 두 깊이의 합보다 낮아도 두 층을 곱하므로 양 끝이 함께 흐리다
  /// (웹 `mask-composite: intersect` — scroll-fog.yaml fog.mask, 2026-10-08). 깊이 0 인 쪽은 층이 없다.
  @override
  Widget build(BuildContext context) {
    final fade = context.gradients.fadeMask;
    Widget masked = child;
    // 층마다 따로 dstIn 으로 씌운다 — dstIn 을 겹쳐 쓰면 알파가 곱해진다(intersect 와 같다)
    for (final layer in [(start, false), (end, true)]) {
      final (depth, atEnd) = layer;
      if (depth <= 0) continue;
      masked = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => fogLayer(
          fade,
          axis,
          bounds.size,
          depth,
          atEnd: atEnd,
        ).createShader(bounds),
        child: masked,
      );
    }
    return masked;
  }
}

/// 한 쪽 흐림의 층 — 상자 전체 크기. 시작 쪽은 투명 → 불투명, 끝 쪽은 반대 방향이다. 토큰(위 → 아래 16단계)의
/// 단계는 그 쪽 깊이의 몫이라 깊이 안에서 불투명에 닿고, 그 뒤는 끝까지 불투명이다(곱해도 가리지 않는다).
@visibleForTesting
LinearGradient fogLayer(
  LinearGradient fade,
  Axis axis,
  Size size,
  double depth, {
  required bool atEnd,
}) {
  final length = axis == Axis.vertical ? size.height : size.width;
  // 깊이가 상자보다 길어도 상자 안에서 끝낸다 — 한 쪽만 봐서는 겹치지 않는다
  final share = length <= 0 ? 0.0 : math.min(1.0, depth / length);
  final stops = fade.stops!;
  final colors = <Color>[...fade.colors];
  final at = <double>[for (final s in stops) s * share];
  // 깊이 뒤는 불투명으로 끝까지 — 마지막 단계가 불투명이라 한 점만 더한다
  if (at.last < 1) {
    colors.add(fade.colors.last);
    at.add(1);
  }
  final forward = !atEnd;
  final vertical = axis == Axis.vertical;
  return LinearGradient(
    begin: vertical
        ? (forward ? Alignment.topCenter : Alignment.bottomCenter)
        : (forward ? Alignment.centerLeft : Alignment.centerRight),
    end: vertical
        ? (forward ? Alignment.bottomCenter : Alignment.topCenter)
        : (forward ? Alignment.centerRight : Alignment.centerLeft),
    colors: colors,
    stops: at,
  );
}
