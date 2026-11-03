import 'dart:math' as math;

import 'package:flutter/rendering.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 시트 최대 폭 — 그보다 좁은 화면은 화면 폭 전체, 넓으면 가운데(bottom-sheet.yaml root.maxWidth).
const double kBottomSheetMaxWidth = 480;

/// 시트 최대 높이 — 화면 높이의 90%. 넘을 내용은 시트가 아니라 페이지로 둔다.
const double kBottomSheetMaxHeightFactor = 0.9;

/// 닫기 버튼 — 보이는 원 28 · 누르는 영역 44.
const double _closeCircle = 28;
const double _closeIcon = 14;
const double _handleWidth = 36;

/// 머리 오른쪽 동작([PBottomSheetContent.headerAction]) — 보이는 단추 36, 닫기 원 왼쪽 사이 4.
const double kBottomSheetHeaderActionSize = 36;
const double kBottomSheetHeaderActionGap = 4;
const double _handleHeight = 4;

/// 머리 왼쪽 뒤로 가기([PBottomSheetContent.onBack]) — 보이는 원 40 · 아이콘 24 · 누르는 영역 44. 아이콘이 화면 여백 24 에 오고
/// 제목은 원 오른쪽 사이 4 에서 시작한다(웹 `onBack` 과 같은 값).
const double kBottomSheetBackSize = 40;
const double kBottomSheetBackIcon = 24;
const double kBottomSheetBackGap = 4;

/// 시트 안에서 시트를 닫는 길 — 바닥 버튼 · 닫기 버튼이 부른다(`PBottomSheet.of(context)`).
abstract interface class PBottomSheetController {
  /// 닫기를 청한다 — 입력 폼에 바뀐 값이 있으면 먼저 "작성한 내용이 사라져요" 를 묻고, 계속 작성하면 그대로 둔다.
  /// 닫기 버튼 · 뒤로 가기 · `Esc` · 바깥 누르기 · 끌기가 모두 이 길이다. 시트 안에 한 단계가 열려 있으면(interceptClose) 청은
  /// 그 단계를 닫는 데 쓰인다 — [wholeSheet] 면 그 단계를 건너뛰고 시트 전체를 닫는다(닫기 원 · 바깥 누르기 · 끌기).
  Future<void> requestClose({bool wholeSheet = false});

  /// 묻지 않고 닫는다 — 저장을 마친 뒤처럼 바뀐 값이 이미 처리된 때. [result] 가 `PBottomSheet.show` 의 결과다.
  void close([Object? result]);

  /// 본문 스크롤 — 본문이 스크롤된 동안은 끌어서 닫지 않는다.
  ScrollController get bodyController;
}

/// 가장 가까운 시트의 닫는 길을 내려준다.
class PBottomSheetScope extends InheritedWidget {
  const PBottomSheetScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final PBottomSheetController controller;

  static PBottomSheetController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PBottomSheetScope>()
      ?.controller;

  @override
  bool updateShouldNotify(PBottomSheetScope oldWidget) =>
      controller != oldWidget.controller;
}

/// 시트 표면 — 위 두 모서리만 둥근(24) 면. 그림자 없이 딤과 표면 색으로 뜬다. 최대 폭 480, 아래에 안전 영역을 더한다.
/// 손잡이는 스냅 높이를 둘 때만 단다.
///
/// 높이는 내용만큼이고 놓인 자리 높이의 [maxHeightFactor] 를 넘지 않는다(라우트는 화면 높이의 90% 를 직접 준다).
/// [fixedHeight] 면 그 높이로 고정한다(스냅 높이가 있는 시트 — 아래를 화면 밖으로 내려 보이는 만큼만 보인다).
class PBottomSheetSurface extends StatelessWidget {
  const PBottomSheetSurface({
    super.key,
    required this.child,
    this.showHandle = false,
    this.onHandleTap,
    this.maxHeightFactor = 1,
    this.fixedHeight = false,
    this.topRadius = PRounded.r6,
  });

  final Widget child;
  final bool showHandle;
  final VoidCallback? onHandleTap;

  /// 위 두 모서리 — 기본 24(Bottom Sheet). Menu Sheet 는 20(r5).
  final double topRadius;
  final double maxHeightFactor;
  final bool fixedHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    // 홈 표시줄 만큼 — 키보드가 올라와 있으면 시트가 그 위에 서므로 더하지 않는다
    final safeBottom = math.max(
      0.0,
      media.viewPadding.bottom - media.viewInsets.bottom,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight * maxHeightFactor
            : double.infinity;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kBottomSheetMaxWidth,
            minHeight: fixedHeight && maxHeight.isFinite ? maxHeight : 0,
            maxHeight: maxHeight,
          ),
          child: DecoratedBox(
            key: const ValueKey('p-bottom-sheet-root'),
            decoration: BoxDecoration(
              color: c.bgLayerFloating,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(topRadius),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: safeBottom),
                  child: child,
                ),
                if (showHandle)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ExcludeSemantics(
                      child: Center(
                        child: GestureDetector(
                          key: const ValueKey('p-bottom-sheet-handle'),
                          behavior: HitTestBehavior.opaque,
                          onTap: onHandleTap,
                          // 누르는 영역 44 × 44 — 막대는 시트 위 6
                          child: SizedBox(
                            width: PTouch.min,
                            height: PTouch.min,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: PSpacing.x1_5,
                                ),
                                child: DecoratedBox(
                                  key: const ValueKey(
                                    'p-bottom-sheet-handle-bar',
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.strokeNeutralWeak,
                                    borderRadius: BorderRadius.circular(
                                      PRounded.full,
                                    ),
                                  ),
                                  child: const SizedBox(
                                    width: _handleWidth,
                                    height: _handleHeight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 시트의 머리 · 본문 · 바닥. 라우트 안(`PBottomSheet.show` 의 builder)에서 쓴다.
///
/// 머리 — 위 24 · 아래 16 · 좌우 화면 여백 24, 제목 22 / 30 · 700(늘 있다), 설명 16 / 22 · `fg-neutral-muted`(덧붙일 말이
/// 있을 때만 한 문장), 제목 ↔ 설명 8. 닫기 버튼이 있으면 제목 오른쪽 64 를 비운다. 닫기 버튼은 오른쪽 위 원 28 +
/// 누르는 영역 44 — 조회 · 고르기 · 시트의 입력 폼에 둔다.
/// 본문 — 좌우 24, 넘치면 이 안에서 스크롤. [scrollFog] 면 끝 흐림(위 20 · 아래 80, 늘 켜짐)과 본문 안 여백 위 20 ·
/// 아래 80 을 둔다 — 넘칠 수 있는 본문(목록 · 긴 폼)에만. 바닥이 없으면 본문 아래 16. 목록([PList])을 바로 두면
/// 줄이 제 좌우 여백(24)을 가지므로 [flushBody] 로 본문 좌우를 뺀다.
/// 바닥 — 위 12 · 좌우 24 · 아래 16, 버튼 하나면 폭 전체 · 둘이면 반씩(사이 8). Button large 48 만 둔다.
class PBottomSheetContent extends StatelessWidget {
  PBottomSheetContent({
    super.key,
    required this.title,
    this.description,
    this.eyebrow,
    this.showCloseButton = true,
    this.closeLabel,
    this.onClose,
    required this.body,
    this.footer = const [],
    this.footerRow,
    this.scrollFog = false,
    this.flushBody = false,
    this.closePressed = false,
    this.headerAction,
    this.onBack,
    this.backLabel,
  }) : assert(
         !showCloseButton || closeLabel != null,
         '닫기 버튼의 이름(closeLabel)이 필요하다',
       ),
       assert(
         onBack == null || backLabel != null,
         '뒤로 가기 버튼의 이름(backLabel)이 필요하다',
       ),
       assert(footer.length <= 2, '바닥 버튼은 하나 또는 둘이다'),
       assert(
         footerRow == null || footer.isEmpty,
         '바닥 줄(footerRow)을 직접 주면 바닥 버튼(footer)은 비운다',
       ),
       assert(
         footer.every((b) => b.size == PButtonSize.large),
         '바닥 버튼은 Button large 48 이다',
       );

  /// 무엇을 하는 시트인지("거래 추가" · "기간"). 늘 둔다.
  final String title;

  /// 덧붙일 말이 있을 때만 한 문장(해요체 · 마침표).
  final String? description;

  /// 제목 위 작은 글("1 / 2단계") — t3 13/18 · fg-neutral-subtle, 제목과 사이 2. 단계가 있는 폼 시트에만 둔다.
  final String? eyebrow;

  /// 오른쪽 위 닫기 버튼(기본 켬).
  final bool showCloseButton;

  /// 닫기 버튼의 이름("닫기") — 앱이 지역화해 넘긴다.
  final String? closeLabel;

  /// 닫기 버튼을 누르면 — 비우면 시트의 닫는 길([PBottomSheetController.requestClose]).
  final VoidCallback? onClose;

  final Widget body;

  /// 바닥 버튼 — 입력 폼은 저장 하나, 고르기는 초기화(왼쪽) + 적용(오른쪽).
  final List<PButton> footer;

  /// 바닥 줄을 직접 그린다 — 스펙의 바닥(버튼 하나 · 둘)에 없는 짜임(수정 폼 왼쪽 [삭제] + [저장], I-10 태그)에만. [footer] 와 같은
  /// 여백(위 12 · 좌우 24 · 아래 16) 안에 놓인다.
  final Widget? footerRow;

  /// 끝 흐림 — 넘칠 수 있는 본문에만.
  final bool scrollFog;

  /// 본문 좌우 여백을 뺀다 — [PList] 처럼 줄이 제 여백을 가진 본문.
  final bool flushBody;

  /// 닫기 버튼을 눌린 모습으로 그린다 — 카탈로그의 정지한 견본.
  final bool closePressed;

  /// 머리 오른쪽 동작 자리 — 닫기 원 왼쪽 사이 4 에 서는 단추 하나(Button ghost 아이콘만 36 · "{항목 이름} 더보기").
  /// 들어간 시트 안에서 동작이 여럿일 때 ⋮ 를 둔다(줄 끝 ⋮ 를 두지 않는 원칙, 2026-10-25). 제목은 남은 폭에서 줄을
  /// 바꾸고(겹치지 않는다) 초점 차례는 제목 → 동작 → 닫기다. 닫기 버튼이 없으면 오른쪽 끝(화면 여백 24)에 선다.
  final Widget? headerAction;

  /// 머리 왼쪽 뒤로 가기 — 같은 시트 안에서 한 단계 되돌아갈 때(← 아이콘 단추, 보이는 40 · 누르는 44 · 아이콘 24). 제목은 그
  /// 오른쪽 사이 4 에서 시작한다. 초점 차례는 뒤로 → 제목 → 동작 → 닫기다. 웹 `onBack` 과 같은 이름 · 같은 값이다.
  final VoidCallback? onBack;

  /// 뒤로 가기 버튼의 이름("뒤로") — 앱이 지역화해 넘긴다. [onBack] 이 있으면 필요하다.
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = PBottomSheetScope.maybeOf(context);

    final header = Padding(
      key: const ValueKey('p-bottom-sheet-header'),
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x6,
        PSpacing.globalGutter,
        PSpacing.x4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x2,
        children: [
          if (eyebrow != null)
            Padding(
              padding: EdgeInsets.only(
                left: onBack == null
                    ? 0
                    : kBottomSheetBackSize +
                          kBottomSheetBackGap -
                          (kBottomSheetBackSize - kBottomSheetBackIcon) / 2,
              ),
              child: Text(
                eyebrow!,
                key: const ValueKey('p-bottom-sheet-eyebrow'),
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
          Padding(
            // 닫기 버튼 자리 — 24 + 원 28 + 12 = 64 중 화면 여백 24 를 뺀 40
            padding: EdgeInsets.only(
              left: onBack == null
                  ? 0
                  : kBottomSheetBackSize +
                        kBottomSheetBackGap -
                        (kBottomSheetBackSize - kBottomSheetBackIcon) / 2,
              right:
                  (showCloseButton ? PSpacing.x10 : 0) +
                  (headerAction == null
                      ? 0
                      : kBottomSheetHeaderActionSize +
                            kBottomSheetHeaderActionGap +
                            (showCloseButton ? 0 : PSpacing.x2)),
            ),
            // 제목은 시트의 이름이 읽는다 — 다시 읽지 않는다
            child: ExcludeSemantics(
              child: Text(
                keepAll(title),
                key: const ValueKey('p-bottom-sheet-title'),
                style: PTypography.t8.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (description != null)
            Text(
              keepAll(description!),
              semanticsLabel: description,
              key: const ValueKey('p-bottom-sheet-description'),
              style: PTypography.t5.copyWith(color: c.fgNeutralMuted),
            ),
        ],
      ),
    );

    final headerBox = Stack(
      children: [
        // 읽는 차례: 뒤로 → 제목 → 동작 → 닫기
        if (onBack != null)
          Positioned(
            key: const ValueKey('p-bottom-sheet-back-slot'),
            // 보이는 원 40 의 왼쪽은 화면 여백 24 보다 8 안쪽(아이콘 24 가 여백 24 에 온다), 세로는 제목 첫 줄 가운데에 맞춘다.
            // 누르는 영역은 사방 2 넓은 44 — 제목 첫 줄은 글자 배율을 따라 커지므로 가운데도 따라간다
            top:
                PSpacing.x6 +
                (eyebrow == null
                    ? 0
                    : MediaQuery.textScalerOf(context).scale(18) +
                          PSpacing.x2) +
                MediaQuery.textScalerOf(context).scale(30) / 2 -
                PTouch.min / 2,
            left:
                PSpacing.globalGutter -
                (kBottomSheetBackSize - kBottomSheetBackIcon) / 2 -
                (PTouch.min - kBottomSheetBackSize) / 2,
            width: PTouch.min,
            height: PTouch.min,
            child: _BackButton(label: backLabel!, onTap: onBack!),
          ),
        header,
        if (headerAction != null)
          Positioned(
            key: const ValueKey('p-bottom-sheet-header-action'),
            // 보이는 단추 36 은 닫기 원(위 24 · 높이 28)과 가운데를 맞추고 원 왼쪽 끝에서 4 떨어진다.
            // 누르는 영역은 사방 4 넓은 44 — 닫기의 누르는 영역과 겹치는 자리는 닫기가 이긴다(뒤에 그려진다)
            top:
                PSpacing.x6 +
                (_closeCircle - kBottomSheetHeaderActionSize) / 2 -
                (PTouch.min - kBottomSheetHeaderActionSize) / 2,
            right:
                PSpacing.globalGutter +
                (showCloseButton
                    ? _closeCircle + kBottomSheetHeaderActionGap
                    : 0) -
                (PTouch.min - kBottomSheetHeaderActionSize) / 2,
            width: PTouch.min,
            height: PTouch.min,
            child: Center(child: headerAction!),
          ),
        if (showCloseButton)
          Positioned(
            // 원 28 의 자리는 위 24 · 오른쪽 24 — 누르는 영역 44 는 사방 8 넓다
            top: PSpacing.x6 - (PTouch.min - _closeCircle) / 2,
            right: PSpacing.globalGutter - (PTouch.min - _closeCircle) / 2,
            child: _CloseButton(
              label: closeLabel!,
              pressed: closePressed,
              onTap: onClose ?? () => controller?.requestClose(),
            ),
          ),
      ],
    );

    // 본문 — 넘치면 이 안에서 스크롤. 끝에서 더 끌어도 뒤로 번지지 않는다(clamping)
    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: flushBody ? 0 : PSpacing.globalGutter,
      ),
      child: body,
    );
    final scroll = scrollFog
        ? PScrollFog(
            use: PScrollFogUse.overlayBody,
            controller: controller?.bodyController,
            child: padded,
          )
        : SingleChildScrollView(
            key: const ValueKey('p-bottom-sheet-body'),
            controller: controller?.bodyController,
            // 바닥이 없어 본문이 맨 끝이면 아래 16(바닥의 아래 여백)
            padding: EdgeInsets.only(
              bottom: footer.isEmpty && footerRow == null ? PSpacing.x4 : 0,
            ),
            child: padded,
          );
    final bodyBox = ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(physics: const ClampingScrollPhysics(), scrollbars: false),
      child: scroll,
    );

    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      role: SemanticsRole.dialog,
      label: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 높이를 고정한 시트(스냅 높이)는 본문이 남는 자리를 채운다
          final fills =
              constraints.hasBoundedHeight &&
              constraints.minHeight >= constraints.maxHeight;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerBox,
              Flexible(
                fit: fills ? FlexFit.tight : FlexFit.loose,
                child: bodyBox,
              ),
              if (footer.isNotEmpty || footerRow != null)
                Padding(
                  key: const ValueKey('p-bottom-sheet-footer'),
                  padding: const EdgeInsets.fromLTRB(
                    PSpacing.globalGutter,
                    PSpacing.x3,
                    PSpacing.globalGutter,
                    PSpacing.x4,
                  ),
                  // 둘이면 짝 버튼 — 라벨이 반 폭을 넘으면 세로로 쌓는다(주 버튼이 위, 03A-013)
                  // 바닥 버튼은 스낵바가 피할 자리다(snackbar.md — 바닥 버튼 위 8). 여백이 아니라 버튼 줄을 감싸 띠가 [삭제] ·
                  // [수정] 을 덮지 않고 버튼 윗변 위 8 에 선다
                  child: PSnackbarAvoidOverlap(
                    child: footerRow != null
                        ? footerRow!
                        : footer.length == 2
                        ? PResponsivePair(
                            secondary: footer.first,
                            primary: footer.last,
                          )
                        : Row(
                            spacing: PSpacing.x2,
                            children: [
                              for (final b in footer) Expanded(child: b),
                            ],
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 닫기 버튼 — 원 28 · 아이콘 14, 누르는 영역 44 × 44. 누르면 원 바탕이 눌림 색이 되고 2px 거리 줄어든다(기준 28 →
/// 0.929, 모션 줄이기면 줄지 않는다).
class _CloseButton extends StatefulWidget {
  const _CloseButton({
    required this.label,
    required this.onTap,
    required this.pressed,
  });

  final String label;
  final VoidCallback onTap;
  final bool pressed;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pressed = _down || widget.pressed;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      container: true,
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('p-bottom-sheet-close'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: SizedBox(
          width: PTouch.min,
          height: PTouch.min,
          child: Center(
            child: AnimatedScale(
              scale: pressed && !reduceMotion
                  ? (_closeCircle - 2) / _closeCircle
                  : 1,
              duration: PDuration.pressedScale,
              curve: PEasing.pressedScale,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                  end: pressed ? c.bgNeutralWeakPressed : c.bgNeutralWeak,
                ),
                duration: PDuration.colorTransition,
                curve: PEasing.easing,
                builder: (context, color, child) => DecoratedBox(
                  key: const ValueKey('p-bottom-sheet-close-circle'),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: child,
                ),
                child: SizedBox(
                  width: _closeCircle,
                  height: _closeCircle,
                  child: Icon(
                    LucideIcons.x,
                    size: _closeIcon,
                    color: c.fgNeutral,
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

/// 뒤로 가기 버튼 — 원 40 · 아이콘 24, 누르는 영역은 놓인 상자 44 × 44. 눌린 동안 원 바탕이 눌림 색이 된다(닫기 원과 같은 색).
class _BackButton extends StatefulWidget {
  const _BackButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('p-bottom-sheet-back'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: _down ? c.bgNeutralWeakPressed : const Color(0x00000000),
            ),
            duration: PDuration.colorTransition,
            curve: PEasing.easing,
            builder: (context, color, child) => DecoratedBox(
              key: const ValueKey('p-bottom-sheet-back-circle'),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: child,
            ),
            child: SizedBox(
              width: kBottomSheetBackSize,
              height: kBottomSheetBackSize,
              child: Center(
                child: Icon(
                  LucideIcons.arrowLeft,
                  size: kBottomSheetBackIcon,
                  color: c.fgNeutral,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom Sheet 의 모습 — 라우트 없이 시트 표면만 그린다(카탈로그의 정지한 견본 · 테스트). 실제로는
/// `PBottomSheet.show` 가 시트를 라우트에 띄운다.
///
/// 놓인 자리 높이의 90% 를 넘지 않는다. [showHandle] 은 스냅 높이를 둘 때만.
class PBottomSheetView extends StatelessWidget {
  const PBottomSheetView({
    super.key,
    required this.content,
    this.showHandle = false,
  });

  final Widget content;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: PBottomSheetSurface(
        showHandle: showHandle,
        maxHeightFactor: kBottomSheetMaxHeightFactor,
        child: content,
      ),
    );
  }
}
