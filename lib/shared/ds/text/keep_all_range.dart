import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 구간 글 — "{시작}~{끝}" 한 글로 읽히고, 줄은 이 차례로 바뀐다(DESIGN.desk.md 날짜 구간, 웹 RangePiece 와 같은 규칙).
///
/// 1. 첫째 자리는 구간 기호 **뒤**다 — 시작 날짜에 기호가 붙어("10월 25일 (일)~") 한 덩어리로 다니고, 끝 날짜는 통째로
///    다음 줄로 내려간다. 기호가 줄 첫머리에 오거나 혼자 한 줄이 되지 않는다.
/// 2. 그래도 한 덩어리가 줄보다 길면 **그 날짜 안의 띄어쓰기**에서만 바뀐다("12월 29일 | (월)~"). 낱말 안("2025년 1|2월")에서는
///    끊지 않는다([keepAll]).
///
/// 두 조각을 간격 0 으로 감싸(Wrap) 한 줄에 들어가면 붙어 보인다. 읽는 이름은 원래 글 하나다.
class KeepAllRange extends StatelessWidget {
  const KeepAllRange({
    super.key,
    required this.from,
    required this.separator,
    required this.to,
    this.style,
    this.textAlign = TextAlign.end,
  });

  final String from;
  final String separator;
  final String to;
  final TextStyle? style;
  final TextAlign textAlign;

  /// 읽는 글 — 보이는 글에서 줄바꿈 글자를 뺀 한 글.
  String get plain => '$from$separator$to';

  @override
  Widget build(BuildContext context) {
    final align = switch (textAlign) {
      TextAlign.start || TextAlign.left => WrapAlignment.start,
      TextAlign.center => WrapAlignment.center,
      _ => WrapAlignment.end,
    };
    return Semantics(
      label: plain,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: align,
          children: [
            Text(
              keepAll('$from$separator'),
              style: style,
              textAlign: textAlign,
            ),
            Text(keepAll(to), style: style, textAlign: textAlign),
          ],
        ),
      ),
    );
  }
}
