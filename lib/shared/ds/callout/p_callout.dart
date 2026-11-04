import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/callout/feedback_parts.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 톤 — neutral(일반, 기본) · informative(정보 · 가이드 · 팁) · positive(성공 · 혜택) · warning(주의 · 미리 알릴 문제)
/// · critical(오류 · 바로 조치할 일). 바탕은 옅은 톤(bg-*-weak), 글 · 아이콘 · 링크 · 화살표 · 닫기는 모두 같은
/// fg-*-contrast 색이다(neutral 은 fg-neutral).
enum PCalloutTone { neutral, informative, positive, warning, critical }

/// 상호작용 — display(보이기만, 기본 — 링크를 둘 수 있다) · actionable(상자 전체가 버튼 — 뒤 화살표, 링크는 두지
/// 않는다) · dismissible(닫기 — 한 번 보면 되는 안내에만, 경고 · 오류는 닫지 못한다).
enum PCalloutInteraction { display, actionable, dismissible }

/// 링크 — 보조 내용(자세히 · 약관)으로 갈 때만. 행동을 이끌려고 두지 않는다.
class PCalloutLink {
  const PCalloutLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// 톤의 색 — 바탕 · 누름 바탕 · 글(아이콘 · 링크 · 화살표 · 닫기도 같은 색). 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
({Color background, Color pressedBackground, Color foreground})
resolvePCalloutColors(PColors c, PCalloutTone tone) => switch (tone) {
  PCalloutTone.neutral => (
    background: c.bgNeutralWeak,
    pressedBackground: c.bgNeutralWeakPressed,
    foreground: c.fgNeutral,
  ),
  PCalloutTone.informative => (
    background: c.bgInformativeWeak,
    pressedBackground: c.bgInformativeWeakPressed,
    foreground: c.fgInformativeContrast,
  ),
  PCalloutTone.positive => (
    background: c.bgPositiveWeak,
    pressedBackground: c.bgPositiveWeakPressed,
    foreground: c.fgPositiveContrast,
  ),
  PCalloutTone.warning => (
    background: c.bgWarningWeak,
    pressedBackground: c.bgWarningWeakPressed,
    foreground: c.fgWarningContrast,
  ),
  PCalloutTone.critical => (
    background: c.bgCriticalWeak,
    pressedBackground: c.bgCriticalWeakPressed,
    foreground: c.fgCriticalContrast,
  ),
};

/// 톤의 기본 앞 아이콘 — lucide 선 아이콘(neutral · informative info, positive circle-check, warning triangle-alert,
/// critical circle-alert).
@visibleForTesting
IconData pCalloutToneIcon(PCalloutTone tone) => switch (tone) {
  PCalloutTone.neutral || PCalloutTone.informative => LucideIcons.info,
  PCalloutTone.positive => LucideIcons.circleCheck,
  PCalloutTone.warning => LucideIcons.triangleAlert,
  PCalloutTone.critical => LucideIcons.circleAlert,
};

/// 상자 · 글 · 아이콘 치수(callout.yaml 공통).
const double _minHeight = 50;
const double _padding = PSpacing.x3_5;
const double _gap = PSpacing.x3;
const double _radius = PRounded.r2_5;
const double _iconSize = 16;
const double _closeBox = 40;

/// 본문 ↔ 버튼 줄 · 버튼 사이(웹 Callout 안 `mt-x2` · `gap-x2`).
const double _actionsGap = PSpacing.x2;

/// Callout — 화면 안, 그 기능 · 내용 가까이에 늘 보이는 안내 상자(팁 · 제약 · 주의, 그 자리에서 난 오류). 구조는
/// SEED Callout(2026-10-02), 수치 원본은 groo-design `specs/components/callout.yaml`(값은
/// `test/fixtures/design_spec/callout.json`). 웹(desk-front `src/shared/ds/callout`)과 같은 값이다.
///
///   [tone]         다섯 톤 — 바탕 bg-*-weak, 글 · 아이콘 · 링크 · 화살표 · 닫기는 모두 fg-*-contrast
///   [interaction]  display · actionable([onPressed], 뒤 화살표) · dismissible([dismissLabel] 닫기)
///   [title]        성격을 나타내는 짧은 말(안내 · 주의 · 새 기능) — 본문과 한 문단
///   [description]  본문 — 제목을 되풀이하지 않는다
///   [link]         display · dismissible 에만, 보조 내용으로 갈 때만
///   [icon]         앞 아이콘 — 없으면 톤의 기본 아이콘, [hideIcon] 이면 두지 않는다
///   [alert]        나중에 나타나는 경고 · 위험(저장 실패)은 보조 기술에 알린다(웹 role="alert") — 처음부터 있던
///                  안내는 알리지 않는다
///
/// 상자 — 안쪽 14 · 최소 50 · 모서리 10 · 아이콘 16 · 사이 12, 여러 줄이면 아이콘 · 화살표 · 닫기가 가운데에 선다.
/// 제목(700) · 본문(400) · 링크(400 + 밑줄)는 모두 t4 이고 한 문단으로 흐른다 — 사이는 띄어쓰기 두 칸. 단어 단위
/// 줄바꿈(v114). 밑줄 띄움 2 는 Flutter 가 정하지 못해 글꼴의 기본 밑줄이다.
/// Actionable — 상자 전체가 버튼이다. 누르면 톤의 누름 바탕(bg-*-weak-pressed) + 상자 전체 세로 2px 거리 축소(기준
///   max(높이, 폭 ÷ 4, 24) — 누르는 순간 잰다). 모션 줄이기면 축소하지 않는다.
/// Dismissible — 닫기는 투명 상자 40 × 40 · 모서리 8, 아이콘은 오른쪽 끝에서 14. 누르면 톤의 누름 바탕 + 2px 축소(기준
///   40). 닫으면 바로 걷고(모션 없음) 초점이 닫기에 있었으면 다음 요소로 간다. [open] · [onDismiss] 로 닫음을
///   기억해 다시 띄우지 않는다 — [open] 을 주지 않으면 스스로 닫는다.
/// 웹의 hover · 키보드 포커스 링은 앱에 없다.
class PCallout extends StatefulWidget {
  const PCallout({
    super.key,
    required this.description,
    this.tone = PCalloutTone.neutral,
    this.interaction = PCalloutInteraction.display,
    this.title,
    this.icon,
    this.hideIcon = false,
    this.link,
    this.onPressed,
    this.open,
    this.onDismiss,
    this.dismissLabel,
    this.alert = false,
    this.moreDescriptions = const [],
    this.actions = const [],
  }) : assert(
         interaction != PCalloutInteraction.actionable || onPressed != null,
         'actionable 은 상자를 누르면 하는 일(onPressed)이 있다',
       ),
       assert(
         interaction != PCalloutInteraction.actionable || link == null,
         'actionable 은 상자 전체를 누르므로 링크를 두지 않는다',
       ),
       assert(
         interaction == PCalloutInteraction.actionable || onPressed == null,
         'onPressed 는 actionable 에만 쓴다',
       ),
       assert(
         interaction != PCalloutInteraction.dismissible ||
             (dismissLabel != null && dismissLabel != ''),
         'dismissible 의 닫기에는 이름(dismissLabel)이 꼭 있다',
       ),
       assert(
         interaction == PCalloutInteraction.dismissible ||
             (open == null && onDismiss == null),
         'open · onDismiss 는 dismissible 에만 쓴다',
       );

  final PCalloutTone tone;
  final PCalloutInteraction interaction;
  final String? title;
  final String description;

  /// 앞 아이콘 — 주지 않으면 톤의 기본 아이콘.
  final IconData? icon;

  /// 앞 아이콘을 두지 않는다.
  final bool hideIcon;
  final PCalloutLink? link;

  /// 상자를 누르면 하는 일 — actionable 에만.
  final VoidCallback? onPressed;

  /// 보이는지 — 주면 부르는 쪽이 정한다(닫은 것을 기억해 다시 띄우지 않는다). 주지 않으면 스스로 닫는다.
  final bool? open;

  /// 닫기를 누르면.
  final VoidCallback? onDismiss;

  /// 닫기 버튼의 이름("닫기") — 호출하는 쪽이 지역화해 넘긴다.
  final String? dismissLabel;

  /// 나중에 나타나는 경고 · 위험이면 보조 기술에 알린다.
  final bool alert;

  /// [description] 다음 문단들 — 문단 사이 8(웹 Callout 안 문단 `mt-x2`). 글만 받는다(제목 · 링크는 첫 문단에만).
  final List<String> moreDescriptions;

  /// 본문 아래 작은 버튼(웹 Callout 안 `Button small` 줄) — 글 칸 안, 본문 아래 8, 버튼 사이 가로 · 세로 8, 넘치면 줄을 바꾼다.
  /// 앞 아이콘 자리는 비우고 글 시작에 맞춘다. display 에만(상자 전체가 버튼이면 안에 버튼을 두지 않는다).
  final List<Widget> actions;

  @override
  State<PCallout> createState() => _PCalloutState();
}

class _PCalloutState extends State<PCallout> {
  bool _selfOpen = true;
  final FocusNode _closeFocus = FocusNode(debugLabel: 'PCallout close');

  bool get _dismissible =>
      widget.interaction == PCalloutInteraction.dismissible;

  @override
  void initState() {
    super.initState();
    assert(
      widget.actions.isEmpty ||
          widget.interaction == PCalloutInteraction.display,
      '본문 아래 버튼(actions)은 display 에만 둔다',
    );
  }

  @override
  void dispose() {
    _closeFocus.dispose();
    super.dispose();
  }

  void _dismiss() {
    moveFocusAfterDismiss(_closeFocus);
    widget.onDismiss?.call();
    if (widget.open == null) setState(() => _selfOpen = false);
  }

  /// 첫 문단 + 다음 문단들(사이 8).
  Widget _body(Color color) {
    if (widget.moreDescriptions.isEmpty) return _paragraph(color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x2,
      children: [
        _paragraph(color),
        for (final d in widget.moreDescriptions)
          Text(
            keepAll(d),
            semanticsLabel: d,
            style: PTypography.t4.copyWith(
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }

  /// 제목 · 본문 · 링크가 이어 흐르는 한 문단.
  Widget _paragraph(Color color) {
    final link = widget.link;
    return Text.rich(
      key: const ValueKey('callout-text'),
      TextSpan(
        style: PTypography.t4.copyWith(
          color: color,
          fontWeight: FontWeight.w400,
        ),
        children: [
          if (widget.title != null) ...[
            TextSpan(
              text: keepAll(widget.title!),
              semanticsLabel: widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '  '),
          ],
          TextSpan(
            text: keepAll(widget.description),
            semanticsLabel: widget.description,
          ),
          if (link != null) ...[
            const TextSpan(text: '  '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: FeedbackPress(
                link: true,
                onPressed: link.onPressed,
                builder: (context, pressed, scale) => Text(
                  link.label,
                  // WidgetSpan 은 자리째 글자 배율을 받는다 — 안의 글이 또 받으면 두 번 커진다(03F-018)
                  textScaler: TextScaler.noScaling,
                  style: PTypography.t4.copyWith(
                    color: color,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissible && !(widget.open ?? _selfOpen)) {
      return const SizedBox.shrink();
    }
    final c = context.colors;
    final look = resolvePCalloutColors(c, widget.tone);
    final actionable = widget.interaction == PCalloutInteraction.actionable;
    final icon = widget.hideIcon
        ? null
        : (widget.icon ?? pCalloutToneIcon(widget.tone));

    // 줄 전체가 상자 — 가장자리 · 위아래 여백를 줄 안의 것마다 둬서 닫기 · 화살표의 누르는 자리가 상자 안에 들어온다
    final row = Row(
      children: [
        const SizedBox(width: _padding),
        if (icon != null) ...[
          Icon(
            icon,
            key: const ValueKey('callout-icon'),
            size: _iconSize,
            color: look.foreground,
          ),
          const SizedBox(width: _gap),
        ],
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _padding),
            child: widget.actions.isEmpty
                ? _body(look.foreground)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _body(look.foreground),
                      const SizedBox(height: _actionsGap),
                      Wrap(
                        key: const ValueKey('callout-actions'),
                        spacing: _actionsGap,
                        runSpacing: _actionsGap,
                        children: widget.actions,
                      ),
                    ],
                  ),
          ),
        ),
        if (actionable) ...[
          const SizedBox(width: _gap),
          Icon(
            LucideIcons.chevronRight,
            key: const ValueKey('callout-chevron'),
            size: _iconSize,
            color: look.foreground,
          ),
        ],
        // 닫기는 아래 Stack 에서 40 × 40 으로 얹는다 — 여기는 글이 걸리지 않게 자리만 둔다
        if (_dismissible) const SizedBox(width: _gap + _iconSize),
        const SizedBox(width: _padding),
      ],
    );

    Widget box({required Color background}) {
      final body = Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          row,
          if (_dismissible)
            // 아이콘은 오른쪽 끝에서 14 — 40 × 40 상자는 오른쪽 가장자리에서 2(= 14 − 12)
            Positioned(
              right: _padding - (_closeBox - _iconSize) / 2,
              top: 0,
              bottom: 0,
              width: _closeBox,
              child: Center(child: _closeButton(look)),
            ),
        ],
      );
      return DecoratedBox(
        key: const ValueKey('callout-box'),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: body,
        ),
      );
    }

    Widget result;
    if (actionable) {
      result = FeedbackPress(
        onPressed: widget.onPressed,
        builder: (context, pressed, scale) => FeedbackScale(
          scale: scale,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: pressed ? look.pressedBackground : look.background,
            ),
            duration: PDuration.colorTransition,
            curve: PEasing.easing,
            builder: (context, background, _) => box(background: background!),
          ),
        ),
      );
    } else {
      result = Semantics(
        container: true,
        liveRegion: widget.alert,
        child: box(background: look.background),
      );
    }
    return result;
  }

  /// 닫기 — 투명 상자 40 × 40 · 모서리 8, 누르면 톤의 누름 바탕 + 2px 축소(기준 40).
  Widget _closeButton(
    ({Color background, Color pressedBackground, Color foreground}) look,
  ) {
    return FeedbackPress(
      focusNode: _closeFocus,
      semanticLabel: widget.dismissLabel,
      excludeChildSemantics: true,
      onPressed: _dismiss,
      builder: (context, pressed, scale) => FeedbackScale(
        scale: scale,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: pressed ? look.pressedBackground : const Color(0x00000000),
          ),
          duration: PDuration.colorTransition,
          curve: PEasing.easing,
          builder: (context, background, child) => Container(
            key: const ValueKey('callout-close'),
            width: _closeBox,
            height: _closeBox,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(PRounded.r2),
            ),
            child: child,
          ),
          child: Icon(LucideIcons.x, size: _iconSize, color: look.foreground),
        ),
      ),
    );
  }
}
