import 'package:flutter/material.dart' show Theme;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/notification_badge/p_notification_badge.dart';
import 'package:groo_damda_app/shared/ds/checkbox/selection_control.dart';
import 'package:groo_damda_app/shared/ds/support_width.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 칸 하나 — 고르는 값 · 글 · 막힘 · 알림 점. 칸은 [PSegmentedControl.items] 에 차례대로 놓는다.
@immutable
class PSegmentedItem<T> {
  const PSegmentedItem({
    required this.value,
    required this.label,
    this.enabled = true,
    this.notification = false,
  });

  /// 이 칸의 값 — 트랙의 값과 같으면 고른 칸이다.
  final T value;

  /// 글 — 짧게("이름순" · "최근 사용"). 길면 낱말 단위로 줄이 바뀌고 모든 칸이 가장 높은 칸에 맞춘다.
  final String label;

  /// false 면 이 칸만 막힌다 — 누를 수 없고 화살표 이동에서 건너뛴다.
  final bool enabled;

  /// 새 소식이 있는 칸의 알림 점 — 안 고른 칸에만 그린다(고르면 사라진다).
  final bool notification;
}

/// 칸 하나의 색 — 고름 · 상태에서 정해진다(segmented-control.yaml 의 고름 규칙). 바탕 · 안쪽 1px 선은 칸에 칠해 알약을
/// 덮고(누름 · 막힘), 평소에는 투명이다 — 고른 칸의 알약은 트랙이 따로 그린다. 앱 상태는 enabled · pressed · disabled
/// (웹의 hovered 는 누름과 같고 focused 는 링이다 — 둘 다 앱에는 없다).
/// [narrow](320 보다 좁은 화면)면 칸 폭이 고르지 않을 수 있어 미끄러지는 알약 대신 고른 칸이 알약의 바탕 · 안쪽 1px 를 칠한다.
SelectionColors _look(
  PColors c, {
  required bool selected,
  required bool enabled,
  required bool pressed,
  required bool dark,
  bool narrow = false,
}) {
  const clear = Color(0x00000000);
  if (!enabled) {
    // 막힘 — 흐리게 하지 않는다. 고른 채 막히면 칸에 회색 바탕 + 짙은 1px 를 칠해 무엇을 골랐는지 남긴다
    return selected
        ? (
            background: c.bgDisabled,
            border: c.strokeNeutralSolid,
            foreground: c.fgDisabled,
          )
        : (background: clear, border: clear, foreground: c.fgDisabled);
  }
  if (selected) {
    return pressed
        ? (
            background: c.bgLayerDefaultPressed,
            border: c.strokeNeutralContrast,
            foreground: c.fgNeutral,
          )
        : narrow
        ? (
            background: c.bgLayerDefault,
            border: c.strokeNeutralContrast,
            foreground: c.fgNeutral,
          )
        : (background: clear, border: clear, foreground: c.fgNeutral);
  }
  // 안 고른 칸 — 누르면 바탕 + 안쪽 1px, 글은 한 단계 짙게(누름 바탕 위 fg-neutral-subtle 은 다크 3.91:1)
  return pressed
      ? (
          background: c.bgNeutralWeakPressed,
          border: c.strokeNeutralWeak,
          foreground: c.fgNeutralMuted,
        )
      : (
          background: clear,
          border: clear,
          // 다크에서는 subtle 이 트랙 위 4.50 아래라 muted(01-040 B 후속)
          foreground: dark ? c.fgNeutralMuted : c.fgNeutralSubtle,
        );
}

/// 칸 최소 높이 — 트랙 안쪽 4 를 더해 42.
const double _itemMinHeight = 34;

/// 알림 점 — 6px, 글 끝에서 2.
const double _dotSize = 6;
const double _dotGap = 2;

/// 칸 글 — t5 16 · 700, 글자 크기 설정을 따르지 않는다(t5-static).
final TextStyle _labelStyle = PTypography.t5.copyWith(
  fontWeight: FontWeight.w700,
);

/// 칸 글에서 가장 긴 낱말의 폭 — 낱말 안에서 꺾지 않으려면 글 자리가 이만큼은 있어야 한다.
double _longestWord(String label, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(text: keepAll(label), style: _labelStyle),
    textDirection: direction,
    textScaler: TextScaler.noScaling,
  )..layout();
  final width = painter.minIntrinsicWidth.ceilToDouble();
  painter.dispose();
  return width;
}

/// 320 보다 좁은 화면의 칸 폭 — 칸은 트랙 폭을 똑같이 나누되 [mins](가장 긴 낱말 + 좌우 여백) 아래로 줄지 않는다. 최소가
/// 몫보다 큰 칸은 최소로 두고 남은 폭을 나머지 칸이 똑같이 나눈다(웹 grid auto-cols-fr + min-content). 합이 [available] 보다
/// 크면 트랙이 가로로 스크롤한다.
@visibleForTesting
List<double> segmentedNarrowWidths(List<double> mins, double available) {
  final fixed = List<bool>.filled(mins.length, false);
  while (true) {
    var rest = available;
    var free = 0;
    for (var i = 0; i < mins.length; i++) {
      if (fixed[i]) {
        rest -= mins[i];
      } else {
        free++;
      }
    }
    if (free == 0) return List<double>.of(mins);
    final share = rest / free;
    var changed = false;
    for (var i = 0; i < mins.length; i++) {
      if (!fixed[i] && mins[i] > share) {
        fixed[i] = true;
        changed = true;
      }
    }
    if (!changed) {
      return [for (var i = 0; i < mins.length; i++) fixed[i] ? mins[i] : share];
    }
  }
}

/// Segmented Control — 같은 내용을 2 ~ 4가지로 바로 거르거나 · 정렬하거나 · 다르게 보는 컨트롤. 구조는 SEED Segmented
/// Control(2026-10-02), 수치 원본은 groo-design `specs/components/segmented-control.yaml`(값은
/// `test/fixtures/design_spec/segmented-control.json` — 테스트가 위젯이 그 값과 같은지 본다). 웹(desk-front
/// `src/shared/ds/segmented-control`)과 같은 값이다.
///
/// 트랙은 놓인 자리 폭을 채우는 알약(안쪽 4 · bg-neutral-weak)이고, 칸이 그 폭을 칸 수로 똑같이 나눈다(최소 폭 없음 —
/// 폰 콘텐츠 폭 312 에도 4개가 들어간다). 칸은 34 이상 · 좌우 12 · 위아래 6 · 알약 모서리. 글은 t5 16 · 700(고르든 안
/// 고르든) · 가운데이고 낱말 단위로 줄을 바꾼다(v114) — 길어 여러 줄이 되면 모든 칸이 가장 높은 칸에 맞춘다. 고른 알약은
/// 트랙에 하나 — 칸 뒤에 깔리고 폭 (트랙 − 8) ÷ 칸 수, 고른 칸 번호만큼 옆으로 옮겨 200ms 에 미끄러진다. 바탕
/// bg-layer-default + 안쪽 1px stroke-neutral-contrast(고른 칸을 트랙과 3:1 로 가른다).
///
/// 상태(바탕 · 글자 · 선은 150ms) — 안 고른 칸을 누르면 bg-neutral-weak-pressed + 안쪽 1px stroke-neutral-weak, 글
/// fg-neutral-muted. 고른 칸을 누르면 칸에 bg-layer-default-pressed + 짙은 1px 를 칠해 알약을 덮는다. 막힘은 글
/// fg-disabled(흐리게 하지 않는다), 고른 채 막히면 bg-disabled + stroke-neutral-solid. 누르면 칸 바탕은 그대로 두고
/// 안의 글만 2px 거리 줄인다(모션 줄이기면 하지 않는다 — 배율 = (기준 − 2) ÷ 기준, 기준 = max(칸 높이, 칸 폭 ÷ 4, 24)).
/// 올림(hovered) · 포커스 링(focused)은 웹 상태라 앱에는 없다 — 키보드 포커스는 받고 링은 그리지 않는다.
/// 알림 점은 6px fg-brand — 글 끝에서 2 · 글 위쪽에 띄워 칸 폭을 바꾸지 않는다. 고른 칸에는 그리지 않는다.
///
/// 누르면 그 칸을 고르고 [onChanged] 로 알린다(값은 쓰는 쪽이 쥔다) — 고른 칸을 다시 눌러도 부르지 않는다. 키보드는 라디오
/// 묶음 그대로다(Flutter 의 RadioGroup — 웹 Radix 와 같은 APG 동작): Tab 은 고른 칸 하나에만 서고, ← → ↑ ↓ 로 옮기면
/// 바로 고른다(막힌 칸은 건너뛰고 끝에서 처음으로 돈다), Space 로 포커스된 칸을 고른다. [onChanged] 가 없으면 칸이 모두
/// 막힌다.
///
/// 읽기 — 트랙은 라디오 묶음이고 [semanticLabel] 이 이름이다(웹 aria-label — 없으면 이름 없는 묶음이 된다). 칸은
/// 라디오(checked) 로 읽고, 알림 점이 있는 칸은 이름 뒤에 "새 소식"([notificationBadgeName] — 호출부가 넘기지 않는다)을 덧붙인다.
///
/// 320 보다 좁은 화면(Layout "지원 폭" — 작은 기기 · 분할 화면)에서 칸이 글보다 좁아지면 낱말 안에서 꺾지 않는다 — 칸은 가장 긴
/// 낱말 + 좌우 여백 아래로 줄지 않고 줄 전체가 가로로 스크롤한다. 칸 폭이 고르지 않을 수 있어 미끄러지는 알약 대신 고른 칸이
/// 알약의 바탕 · 안쪽 1px 를 칠한다. 320 이상에서는 아무것도 바뀌지 않는다.
///
/// 칸은 2 ~ 4개다 — 5개 이상이면 Chip 의 하나 고르기 줄 · Select. 한 화면에 하나, 바꾸는 내용 바로 위에 둔다. 다른
/// 구역으로 옮기면 Tabs, 저장할 폼 값은 Chip · Select 다. 칸 높이 34 는 스펙이 정한 값이다(누르는 영역 AAA 44 에는
/// 모자라다 — 스펙 · SEED 와 같다).
class PSegmentedControl<T> extends StatelessWidget {
  const PSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.semanticLabel,
  }) : itemInset = PSpacing.x3,
       assert(
         items.length >= 2 && items.length <= 4,
         '칸은 2 ~ 4개다 — 5개 이상은 Chip 의 하나 고르기 줄 · Select',
       );

  /// 차트 기간 5칸(1일 · 1주 · 1개월 · 3개월 · 1년) **전용** — 일반 호출은 2 ~ 4칸이다. 폰 콘텐츠 폭 312 에 5칸이 들도록
  /// 칸 좌우를 12 가 아니라 4(웹 `px-x1`)로 줄인다. 글은 t5 static 이라 글자 배율 200% 에서도 "3개월" 이 꺾이지 않는다.
  /// 다른 화면에서 5칸을 쓰려면 이 생성자를 쓰지 말고 Chip Tabs · Select 를 쓴다.
  const PSegmentedControl.chartPeriod({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.semanticLabel,
  }) : itemInset = PSpacing.x1,
       assert(items.length == 5, '차트 기간 전용 — 5칸');

  /// 칸 글의 좌우 여백 — 기본 12, 차트 기간 5칸은 4.
  final double itemInset;

  /// 고른 값 — 늘 하나를 골라 둔다. [items] 에 없는 값이면 알약을 숨긴다.
  final T value;

  /// 다른 칸을 고르면 그 값. 없으면 트랙 전체가 비활성.
  final ValueChanged<T>? onChanged;

  /// 칸 2 ~ 4개 — 차례대로 놓는다.
  final List<PSegmentedItem<T>> items;

  /// 트랙의 이름(웹 aria-label) — 무엇을 바꾸는지("할 일 보기").
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selectedIndex = items.indexWhere((item) => item.value == value);
    final round = BorderRadius.circular(PRounded.full);
    final narrow = belowSupportWidth(context);
    final Widget cells;
    if (narrow) {
      cells = LayoutBuilder(
        builder: (context, constraints) {
          final direction = Directionality.of(context);
          final mins = [
            for (final item in items)
              _longestWord(item.label, direction) + 2 * itemInset,
          ];
          final widths = segmentedNarrowWidths(mins, constraints.maxWidth);
          return SingleChildScrollView(
            key: const ValueKey('segmented-scroll'),
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    SizedBox(
                      width: widths[i],
                      child: _SegmentedItem<T>(
                        item: items[i],
                        selected: items[i].value == value,
                        groupEnabled: onChanged != null,
                        inset: itemInset,
                        narrow: true,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      cells = Stack(
        children: [
          if (selectedIndex >= 0)
            Positioned.fill(
              child: _Indicator(index: selectedIndex, count: items.length),
            ),
          // 모든 칸이 같은 폭 · 가장 높은 칸에 맞춘 높이
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items)
                  Expanded(
                    child: _SegmentedItem<T>(
                      item: item,
                      selected: item.value == value,
                      groupEnabled: onChanged != null,
                      inset: itemInset,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    return RadioGroup<T>(
      groupValue: value,
      onChanged: (next) {
        // 고른 칸을 다시 눌러도 그대로다
        if (onChanged == null || next == null || next == value) return;
        onChanged!(next);
      },
      child: Semantics(
        label: semanticLabel,
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.bgNeutralWeakAlpha,
              borderRadius: round,
            ),
            child: Padding(
              padding: const EdgeInsets.all(PSpacing.x1),
              child: cells,
            ),
          ),
        ),
      ),
    );
  }
}

/// 고른 알약 — 트랙의 안쪽을 칸 수로 나눈 폭, 고른 칸 번호만큼 옆으로 옮겨 200ms 로 미끄러진다.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: index.toDouble()),
      duration: PDuration.d4,
      curve: PEasing.easing,
      builder: (context, t, _) => FractionallySizedBox(
        // -1(첫 칸) ~ 1(끝 칸) — 폭 1/칸 수의 알약이 칸 번호만큼 옮겨 간다
        alignment: AlignmentDirectional(-1 + 2 * t / (count - 1), 0),
        widthFactor: 1 / count,
        child: DecoratedBox(
          key: const ValueKey('segmented-indicator'),
          decoration: BoxDecoration(
            color: c.bgLayerDefault,
            borderRadius: BorderRadius.circular(PRounded.full),
            // 안쪽 1px — DecoratedBox 는 테두리를 안쪽에 그리고 자리를 바꾸지 않는다(웹 inset-ring)
            border: Border.all(color: c.strokeNeutralContrast),
          ),
        ),
      ),
    );
  }
}

/// 칸 — 누르는 자리 · 글 · 알림 점. 라디오 묶음([RadioGroup])의 한 선택지다.
class _SegmentedItem<T> extends StatefulWidget {
  const _SegmentedItem({
    required this.item,
    required this.selected,
    required this.groupEnabled,
    required this.inset,
    this.narrow = false,
  });

  final double inset;

  /// 320 보다 좁은 화면 — 고른 칸이 알약을 칠한다.
  final bool narrow;
  final PSegmentedItem<T> item;
  final bool selected;
  final bool groupEnabled;

  @override
  State<_SegmentedItem<T>> createState() => _SegmentedItemState<T>();
}

class _SegmentedItemState<T> extends State<_SegmentedItem<T>>
    with RadioClient<T> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'PSegmentedItem');
  bool _pressed = false;

  /// 누르는 순간 잰 칸 크기 — 눌린 글의 배율이 이 칸에서 정해진다(웹 --press-basis).
  Size _size = const Size(0, _itemMinHeight);

  @override
  FocusNode get focusNode => _focusNode;

  @override
  T get radioValue => widget.item.value;

  @override
  bool get tristate => false;

  // 화살표가 건너뛸 칸 — 이 칸 또는 트랙이 막혔다
  @override
  bool get enabled => widget.item.enabled && widget.groupEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registry = RadioGroup.maybeOf<T>(context);
  }

  @override
  void didUpdateWidget(_SegmentedItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 사이 막히면 누름이 남지 않게
    if (!enabled) _pressed = false;
  }

  @override
  void dispose() {
    registry = null;
    _focusNode.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _select() {
    // 이미 고른 칸을 다시 눌러도 그대로다
    if (widget.selected) return;
    registry?.onChanged(widget.item.value);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      registry != null,
      '_SegmentedItem 은 같은 값 타입(T)의 PSegmentedControl 안에서만 쓴다 — T: $T',
    );
    final c = context.colors;
    final item = widget.item;
    final enabled = this.enabled;
    final selected = widget.selected;
    final pressed = enabled && _pressed;
    final look = _look(
      dark: Theme.brightnessOf(context) == Brightness.dark,
      c,
      selected: selected,
      enabled: enabled,
      pressed: pressed,
      narrow: widget.narrow,
    );
    // 알림 점은 안 고른 칸에만 — 고르면 점도 "새 소식" 도 사라진다
    final showDot = item.notification && !selected;
    // iOS 의 VoiceOver 는 선택을 selected 로 읽는다 — 고르지 않은 칸은 "선택되지 않음" 을 덧붙인다(PRadio 와 같다)
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    final name = showDot
        ? '${item.label} ${notificationBadgeNameOf(context)}'
        : item.label;
    final round = BorderRadius.circular(PRounded.full);

    // 글 — 색은 칸의 색과 함께 150ms 로 바뀐다
    // 이름은 칸의 읽는 말이 맡는다 — 글 · 점은 따로 읽지 않는다
    Widget label(Color color) => ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Text(
            keepAll(item.label),
            textAlign: TextAlign.center,
            // 칸 글은 -static 16 — 글자 크기 설정을 따르지 않는다(1.4.4 예외: 4칸이 한 줄에 들게, 03-B 결정 4 A)
            textScaler: TextScaler.noScaling,
            style: _labelStyle.copyWith(color: color),
          ),
          if (showDot)
            // 글 끝에서 2 · 글 위쪽 — 띄워 두므로 칸 폭이 바뀌지 않는다
            PositionedDirectional(
              top: 0,
              end: -(_dotGap + _dotSize),
              child: SizedBox.square(
                dimension: _dotSize,
                child: DecoratedBox(
                  key: const ValueKey('segmented-dot'),
                  decoration: BoxDecoration(
                    color: c.fgBrand,
                    borderRadius: round,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      container: true,
      enabled: enabled,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      selected: apple ? selected : null,
      hint: apple && !selected
          ? WidgetsLocalizations.of(context).radioButtonUnselectedLabel
          : null,
      label: name,
      onTap: enabled ? _select : null,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: enabled,
        child: MouseRegion(
          // 웹 cursor pointer · not-allowed
          cursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: enabled
                ? (_) {
                    _size = context.size ?? _size;
                    _setPressed(true);
                  }
                : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onTap: enabled ? _select : null,
            child: TweenAnimationBuilder<SelectionColors>(
              tween: SelectionColorsTween(end: look),
              duration: PDuration.colorTransition,
              curve: PEasing.easing,
              builder: (context, colors, _) => DecoratedBox(
                key: const ValueKey('segmented-item'),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: round,
                  border: Border.all(color: colors.border),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _itemMinHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.inset,
                      vertical: PSpacing.x1_5,
                    ),
                    child: Center(
                      child: SelectionPressScale(
                        pressed: pressed,
                        size: _size,
                        child: label(colors.foreground),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
