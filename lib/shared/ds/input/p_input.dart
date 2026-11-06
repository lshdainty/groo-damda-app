import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/input/text_control.dart';

const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

/// 모양 — 상자(기본) · 밑줄(화면에 입력이 하나뿐일 때 — 금액을 먼저 받는 화면 · 목록 위 검색 · 초대 코드 · 잠금 해제).
enum PInputVariant { outline, underline }

/// 크기 — large(기본, 상자 52 · 밑줄 40) · medium(상자 40 · 밑줄 34). 앱은 늘 large 이고 medium 은 상단 바 검색칸(바 56 안 —
/// top-navigation.md "검색칸") 한 자리만 쓴다. responsive(1280 이상 데스크톱 웹)는 앱에 없다.
enum PInputSize { large, medium }

/// 모양마다의 값(input.yaml 모양 × 크기).
typedef _InputSize = ({
  double minHeight,
  double radius,
  double paddingX,
  double paddingY,
  double gap,
  TextStyle text,
  double icon,
  double clear,
});

const _InputSize _outlineLarge = (
  minHeight: 52,
  radius: PRounded.r3,
  paddingX: PSpacing.x4,
  paddingY: 0,
  gap: PSpacing.x2_5,
  text: PTypography.t5,
  icon: 20,
  clear: 22,
);

const _InputSize _outlineMedium = (
  minHeight: 40,
  radius: PRounded.r2,
  paddingX: PSpacing.x3_5,
  paddingY: 0,
  gap: PSpacing.x2,
  text: PTypography.t4,
  icon: 16,
  clear: 18,
);

// 밑줄 — 글자가 한 단계 크고(t6) 좌우 여백 · 모서리가 없다
const _InputSize _underlineLarge = (
  minHeight: 40,
  radius: 0,
  paddingX: 0,
  paddingY: PSpacing.x2,
  gap: PSpacing.x2_5,
  text: PTypography.t6,
  icon: 24,
  clear: 22,
);

const _InputSize _underlineMedium = (
  minHeight: 34,
  radius: 0,
  paddingX: 0,
  paddingY: PSpacing.x1_5,
  gap: PSpacing.x2,
  text: PTypography.t5,
  icon: 20,
  clear: 18,
);

/// Input(Text Input) — 한 줄 글 · 숫자를 직접 치는 입력칸. 구조는 SEED Text Input(2026-10-01), 수치 원본은
/// groo-design `specs/components/input.yaml`(값은 `test/fixtures/design_spec/input.json`). 웹(desk-front
/// `src/shared/ds/input`)과 같은 값이다. 옛 위젯(lib/shared/widgets/p_text_input.dart)과는 따로다.
///
/// 라벨 · 설명 · 오류 · 글자 수는 [PField] 가 둘레에서 그린다 — Field 안에 두면 이름 · 설명 · 상태를 받는다.
/// Field 밖(목록 위 검색칸)이면 [semanticLabel] 이 이름이다.
///
/// 크기 — 앱은 늘 large: 상자 52(모서리 12 · 좌우 16 · 사이 10 · 글자 t5) · 밑줄 40(위아래 8 · 글자 t6). 상단 바 검색칸만
///   [size] medium: 상자 40(모서리 8 · 좌우 14 · 사이 8 · 글자 t4 · 아이콘 16 · 지우기 18).
/// 상태 — 투명 바탕 · 안쪽 1px stroke-neutral-weak. 포커스는 안쪽 2px stroke-neutral-contrast(터치로 눌러도),
///   오류는 안쪽 2px stroke-critical-solid(포커스해도 그대로) — 굵어져도 내용이 밀리지 않고 색만 d2 로 나타난다.
///   비활성 · 읽기 전용은 bg-disabled 바탕(흐리게 하지 않는다), 비활성 글자 · 아이콘은 fg-disabled, 읽기 전용은
///   포커스 테두리가 없다. 밑줄형은 바탕 대신 읽기 전용 글자가 fg-neutral-muted 다.
/// 붙이개 — 글자([prefixText] · [suffixText] — 칸 글자와 같은 크기의 fg-neutral-subtle, 입력의 설명으로도 읽힌다)와
///   아이콘([prefixIcon] · [suffixIcon] — 20 · 밑줄 24, fg-neutral-muted, 읽지 않는다). 단위는 뒤 글자로 둔다.
/// 지우기([clearable]) — 값이 있고 막히지 않았을 때만 22 의 원 X(fg-neutral-subtle). 누르면 값을 비우고([onChanged]
///   에 빈 값) 입력에 포커스를 둔다. 누르는 영역은 44 까지 넓힌다. 키보드 이동 순서에는 없다.
/// 상자 어디를 눌러도 입력으로 포커스가 간다 — 입력이 상자 높이를 채우고 맨 앞 · 맨 뒤면 좌우 여백까지 차지해, 그
/// 여백을 누르면 가장 가까운 글자에 캐럿이 놓인다. 붙이개 · 그 사이를 누르면 포커스만 옮긴다.
class PInput extends PTextControl {
  const PInput({
    super.key,
    super.controller,
    super.initialValue,
    super.focusNode,
    super.placeholder,
    super.onChanged,
    super.disabled,
    super.readOnly,
    super.invalid,
    super.semanticLabel,
    super.autofocus,
    super.inputFormatters,
    this.variant = PInputVariant.outline,
    this.size = PInputSize.large,
    this.prefixText,
    this.prefixIcon,
    this.suffixText,
    this.suffixIcon,
    this.clearable = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.secret = false,
    this.autofillHints,
    this.tabularFigures = false,
    this.placeholderKeepsColorWhenDisabled = false,
  });

  final PInputVariant variant;

  /// 크기 — 기본 large. medium 은 상단 바 검색칸만([PInputSize]).
  final PInputSize size;

  /// 앞 글자 — https:// · 만 · −.
  final String? prefixText;

  /// 앞 아이콘 — 검색 돋보기처럼 칸의 뜻을 돕는다(아이콘만으로 뜻을 알리지 않는다).
  final IconData? prefixIcon;

  /// 뒤 글자 — 단위(원 · % · 일 · 회). 라벨에 "(원)" 을 붙이지 않고 여기에 둔다.
  final String? suffixText;
  final IconData? suffixIcon;

  /// 지우기 버튼 — 검색칸 · 선택 사항인 칸에 둔다(필수 칸에는 두지 않는다).
  final bool clearable;

  /// 숫자 · 금액은 숫자 키보드(TextInputType.number) — 쉼표는 inputFormatters 로 넣는다.
  final TextInputType? keyboardType;

  /// 값 맞춤 — 기본은 시작. 줄 끝 몫 칸이 오른쪽 맞춤으로 쓴다.
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// 가린 칸(비밀번호) — 키보드 사전 · 추천 · 학습에 남기지 않는다.
  final bool obscureText;

  /// 자격증명 칸(API 키 · 시크릿) — 눈 Toggle 로 값을 벗겨 보는 동안([obscureText] false)에도 키보드 사전 · 추천 · 학습에
  /// 남기지 않는다. 가린 칸([obscureText])은 이미 그렇다.
  final bool secret;
  final Iterable<String>? autofillHints;

  /// 고정폭 숫자 — 자리마다 폭이 같은 숫자(인증 코드 칸 · input-otp.yaml value.numerals). 글자 · 예시 글에 건다.
  final bool tabularFigures;

  /// 막혀도 빈 칸의 글을 fg-placeholder 그대로 둔다 — Input 은 fg-disabled 로 바꾸지만 Input OTP 는
  /// 그대로다(input-otp.yaml disabled placeholder.foreground, 2026-10-17 사용자 결정 01T-013).
  final bool placeholderKeepsColorWhenDisabled;

  @override
  State<PInput> createState() => _PInputState();
}

class _PInputState extends PTextControlState<PInput> {
  final GlobalKey _clearKey = GlobalKey();

  /// 상자를 눌렀다 — 지우기 버튼의 넓힌 영역(44)이면 지우고, 아니면 입력으로 포커스.
  void _handleBoxTap(TapUpDetails details) {
    final clearBox = _clearKey.currentContext?.findRenderObject();
    if (clearBox is RenderBox && clearBox.attached) {
      final local = clearBox.globalToLocal(details.globalPosition);
      final size = clearBox.size;
      final dx = math.max(0.0, (PTouch.min - size.width) / 2);
      final dy = math.max(0.0, (PTouch.min - size.height) / 2);
      final area = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
      if (area.contains(local)) {
        clear();
        return;
      }
    }
    focusFromBox();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final underline = widget.variant == PInputVariant.underline;
    final medium = widget.size == PInputSize.medium;
    final s = underline
        ? (medium ? _underlineMedium : _underlineLarge)
        : (medium ? _outlineMedium : _outlineLarge);
    final disabled = this.disabled;
    final readOnly = this.readOnly;

    // 밑줄형은 바탕이 없어 읽기 전용을 글자로 가른다
    final valueColor = disabled
        ? c.fgDisabled
        : underline && readOnly
        ? c.fgNeutralMuted
        : c.fgNeutral;
    final placeholderColor =
        disabled && !widget.placeholderKeepsColorWhenDisabled
        ? c.fgDisabled
        : underline && readOnly
        ? c.fgNeutralMuted
        : c.fgPlaceholder;
    final affixStyle = s.text.copyWith(
      color: disabled ? c.fgDisabled : c.fgNeutralSubtle,
      fontWeight: FontWeight.w400,
    );
    final iconColor = disabled ? c.fgDisabled : c.fgNeutralMuted;
    final showClear = widget.clearable && !isEmpty && !disabled && !readOnly;

    Widget icon(IconData data) => ExcludeSemantics(
      child: Icon(data, size: s.icon, color: iconColor),
    );
    // 붙이개 글은 입력의 설명으로 읽는다 — 여기서는 따로 읽지 않는다
    Widget affix(String text) => ExcludeSemantics(
      child: Text(text, maxLines: 1, softWrap: false, style: affixStyle),
    );

    final row = Row(
      spacing: s.gap,
      children: [
        if (widget.prefixIcon != null) icon(widget.prefixIcon!),
        if (widget.prefixText != null) affix(widget.prefixText!),
        Expanded(
          child: buildEditable(
            style: s.text.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w400,
              fontFeatures: widget.tabularFigures ? _tabular : null,
            ),
            placeholderStyle: s.text.copyWith(
              color: placeholderColor,
              fontWeight: FontWeight.w400,
              fontFeatures: widget.tabularFigures ? _tabular : null,
            ),
            multiline: false,
            keyboardType: widget.keyboardType,
            textAlign: widget.textAlign,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            secret: widget.secret,
            onSubmitted: widget.onSubmitted,
            autofillHints: widget.autofillHints,
            describedAffixes: [widget.prefixText, widget.suffixText],
          ),
        ),
        if (widget.suffixText != null) affix(widget.suffixText!),
        if (widget.suffixIcon != null) icon(widget.suffixIcon!),
        if (showClear)
          _ClearButton(
            key: _clearKey,
            size: s.clear,
            color: c.fgNeutralSubtle,
            label: l10n.dsInputClear,
            onPressed: clear,
          ),
      ],
    );

    return TextFieldTapRegion(
      child: MouseRegion(
        cursor: disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.text,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapUp: disabled ? null : _handleBoxTap,
          child: PTextFrame(
            underline: underline,
            radius: s.radius,
            background: !underline && (disabled || readOnly)
                ? c.bgDisabled
                : const Color(0x00000000),
            emphasis: emphasisColor(c),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: s.minHeight),
              // 입력이 상자 높이를 채우고, 맨 앞 · 맨 뒤면 좌우 여백까지 차지한다
              child: editableHitArea(
                extendStart:
                    widget.prefixIcon == null && widget.prefixText == null,
                extendEnd:
                    widget.suffixText == null &&
                    widget.suffixIcon == null &&
                    !showClear,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: s.paddingX,
                    vertical: s.paddingY,
                  ),
                  child: row,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 지우기 — lucide circle-x(fg-neutral-subtle). 누름은 상자가 받는다(보이는 22 를 44 까지 넓혀서).
/// 이름 "지우기" 로 읽고 누를 수 있다. 키보드 이동 순서에는 없다(포커스 노드가 없다).
class _ClearButton extends StatelessWidget {
  const _ClearButton({
    super.key,
    required this.size,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final double size;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Icon(LucideIcons.circleX, size: size, color: color),
      ),
    );
  }
}
