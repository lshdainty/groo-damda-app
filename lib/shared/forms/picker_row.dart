import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

/// 폼 안 "고르는 값" 줄 — 제목 + 값(앞 점 · 아이콘 포함) 한 줄. 치는 값은 칸(PField + PInput), 고르는 값은 이 줄이다
/// (I-19 폼 문법). 꺾쇠는 두지 않는다 — 화살표는 화면을 옮기는 줄에만(list.md).
///
/// [onTap] 이 없으면 보기만 하는 줄(누름 · 호버 없음)이다. 값이 없으면 [placeholder] 를 `fg-placeholder` 로 보인다.
/// 오류는 줄 아래 한 줄(좌우 24)로 알린다. 값 글은 줄바꿈하고 줄 안 폭이 좁으면 제목 아래로 내려간다(List 의 규칙).
class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.title,
    required this.onTap,
    this.value,
    this.placeholder,
    this.semanticValue,
    this.leading,
    this.prefix,
    this.errorMessage,
    this.onClear,
    this.clearLabel,
    this.focusNode,
  });

  final String title;
  final VoidCallback? onTap;

  /// 고른 값 글 — 없으면 [placeholder].
  final String? value;
  final String? placeholder;

  /// 읽는 값 — 보이는 글과 다를 때(아직 고르지 않았으면 "선택 안 함").
  final String? semanticValue;

  /// 값 앞 그림(점 · 아이콘) — 값 글과 함께 줄바꿈한다.
  final Widget? leading;

  /// 줄 앞 아이콘(22 · `fg-neutral`) — 제목 앞에 서서 줄 칸의 뜻을 돕는다(카테고리 폼의 종류 · 상위 · 색상 · 아이콘 줄). 값 앞
  /// 그림은 [leading] 이다.
  final Widget? prefix;
  final String? errorMessage;

  /// 값 끝 지우기 버튼 — 값이 있을 때만 보인다. 누르면 값만 비우고 고르기를 열지 않는다.
  final VoidCallback? onClear;
  final String? clearLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasValue = value != null && value!.isNotEmpty;
    final shown = hasValue ? value! : (placeholder ?? '');
    final valueText = Text.rich(
      TextSpan(
        children: [
          if (leading != null && hasValue)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: PSpacing.x2),
                child: leading,
              ),
            ),
          TextSpan(text: shown),
        ],
        style: hasValue ? null : TextStyle(color: c.fgPlaceholder),
      ),
      // 값은 줄 수와 상관없이 줄 끝 오른쪽 맞춤 — 둘째 줄도 오른쪽(본문 아래로 내려간 값만 ds 가 왼쪽으로 돌린다)
      textAlign: TextAlign.end,
      semanticsLabel: hasValue ? (semanticValue ?? shown) : semanticValue,
    );
    Widget? suffix = shown.isEmpty ? null : valueText;
    if (hasValue && onClear != null) {
      suffix = PListSuffix(
        children: [
          valueText,
          PListAction(
            child: Semantics(
              button: true,
              label: clearLabel,
              excludeSemantics: true,
              onTap: onClear,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: SizedBox.square(
                  dimension: PTouch.min,
                  child: Center(
                    child: Icon(
                      LucideIcons.circleX,
                      size: 22,
                      color: c.fgNeutralSubtle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final row = onTap == null
        ? PListItem(title: title, prefix: prefix, suffix: suffix)
        : PListButtonItem(
            title: title,
            prefix: prefix,
            suffix: suffix,
            onTap: onTap,
            focusNode: focusNode,
            // 오류 글은 줄의 설명으로도 읽힌다(웹 aria-describedby)
            semanticHint: errorMessage,
          );
    if (errorMessage == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [row, PickerErrorLine(errorMessage!)],
    );
  }
}

/// 줄 아래 오류 한 줄 — ⓘ + 글(field.md 꼬리 오류). PickerRow 와 손으로 만든 줄(치는 값 단계 줄)이 같은 모양을 쓴다.
class PickerErrorLine extends StatelessWidget {
  const PickerErrorLine(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        0,
        PSpacing.globalGutter,
        PSpacing.x2,
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PSpacing.x1_5,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x0_5),
              child: ExcludeSemantics(
                child: Icon(
                  LucideIcons.circleAlert,
                  size: 16,
                  color: c.fgCritical,
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: PTypography.t4.copyWith(color: c.fgCritical),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 값 앞 색 점 — 카테고리 줄은 8, 색 줄은 12.
class PickerDot extends StatelessWidget {
  const PickerDot({super.key, required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
