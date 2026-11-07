import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 낱말 단위로 줄이 바뀌는 글 — [Text] 에 [keepAll] 을 적용하고 읽는 이름은 원래 글로 둔다(DESIGN.md v114).
///
/// 화면에서 읽는 글(문장 · 이름 · 안내)을 그릴 때 `Text` 대신 이것을 쓴다. 띄어쓰기에서만 줄이 바뀌고, 한 줄보다 긴
/// 낱말은 칸 끝에서 끊긴다. 보조 기술에는 이음 문자가 들어가지 않은 원래 글이 읽힌다([semanticsLabel] 로 바꿀 수 있다).
///
/// **쓰지 않는 자리** — 입력 중인 글(글자 단위로 줄이 바뀐다 — 스펙), 금액([keepAllAmount] 로 `Text` 에 직접), 숫자 ·
/// 기호만 있는 글(`0 / 0`). ds 부품 안의 글은 부품이 [keepAll] 을 직접 적용한다.
class PText extends StatelessWidget {
  const PText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;

  /// 읽는 이름 — 기본은 [data] 그대로(이음 문자 없음).
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;

  @override
  Widget build(BuildContext context) => Text(
    keepAll(data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel ?? data,
    textWidthBasis: textWidthBasis,
  );
}
