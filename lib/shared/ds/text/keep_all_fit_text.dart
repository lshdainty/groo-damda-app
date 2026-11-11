import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 칸 폭을 보고 줄바꿈 자리를 고르는 글(`keepAllFit`) — 띄어쓰기에서 먼저 꺾고 쉼표 뒤 줄바꿈은 낱말 하나가 칸보다 길 때만 쓴다.
/// 금액이 든 키-값 줄 · 한도 줄처럼 "앞 말 + 금액" 이 한 문장인 자리에 쓴다. 읽는 이름은 원래 글이다.
class KeepAllFitText extends StatelessWidget {
  const KeepAllFitText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) => Text(
        box.maxWidth.isFinite
            ? keepAllFit(
                text,
                style: resolved,
                scaler: scaler,
                maxWidth: box.maxWidth,
              )
            : keepAllAmount(text),
        semanticsLabel: text,
        textAlign: textAlign,
        maxLines: maxLines,
        style: style,
      ),
    );
  }
}
