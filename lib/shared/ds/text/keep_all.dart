import 'package:flutter/widgets.dart'
    show
        StringCharacters,
        TextDirection,
        TextPainter,
        TextScaler,
        TextSpan,
        TextStyle;

/// 낱말 단위 줄바꿈(DESIGN.md v114 — 웹의 word-break: keep-all) — 낱말 안의 글자 사이에 이음 문자(U+2060 WORD
/// JOINER)를 넣어 띄어쓰기에서만 줄이 바뀌게 한다. 한 줄보다 긴 낱말은 Flutter 가 칸 끝에서 끊는다(웹의
/// overflow-wrap: break-word 와 같다). 보조 기술은 이음 문자를 읽지 않는다.
///
/// 이음 문자는 **문자 묶음(grapheme) 사이에만** 넣는다 — 코드포인트마다 넣으면 이모지(VS16 · ZWJ · 국기 · 피부색), 결합 문자,
/// 풀어 쓴(NFD) 한글 자모의 묶음이 갈라진다. 사용자가 쓴 이름이 이 함수를 지나도 안전하다.
String keepAll(String text) {
  final out = StringBuffer();
  String? prev;
  for (final g in text.characters) {
    if (prev != null && !_breakable(prev) && !_breakable(g)) {
      out.writeCharCode(0x2060);
    }
    out.write(g);
    prev = g;
  }
  return out.toString();
}

// 공백 · 줄바꿈 자리에서는 끊을 수 있게 둔다(문자 묶음의 첫 코드포인트로 본다. CRLF 도 줄바꿈이다)
bool _breakable(String g) {
  if (g == '\r\n') return true;
  final r = g.runes.first;
  return r == 0x20 || r == 0x0A || r == 0x09 || r == 0x3000;
}

/// 금액 — [keepAll] 처럼 낱말 단위로 묶되 **쉼표 뒤에서만** 줄을 바꿀 수 있게 한다(03-D 결정 2 B, Typography v114 의
/// 예외). 지표 · 순자산 · 목록 금액이 칸보다 길 때 숫자 한가운데(`−123,4` / `56,789,`)가 아니라 `−123,` / `456,` /
/// `789원` 처럼 쉼표 자리에서 끊긴다. 웹은 `<wbr>`, 앱은 쉼표 바로 뒤의 이음 문자(U+2060) 한 자리를 너비 0 공백
/// (U+200B)으로 바꾼다.
///
/// **보이는 글에만** 쓴다. 읽는 이름은 원래 글이어야 해서 `Text(..., semanticsLabel: 원래 글)` 로 함께 넘긴다 —
/// 복사 · 낭독 · 비교에는 이 글이 들어가지 않는다. ds 의 금액 글(지표 · 순자산 · 목록 `PListValue.amount`)은 이 함수 하나로 만든다 — 옛 화면 위젯(`krwMasked` · `MaskedAmount` 등)은 아직 쓰지 않는다(화면 이관 때).
String keepAllAmount(String amount) =>
    keepAll(amount).replaceAll(_commaJoined, _commaBreak);

// 포매터가 \u 이스케이프를 보이지 않는 글자 그대로 풀어 버려, 코드 값으로 만든다
final String _commaJoined = ',${String.fromCharCode(0x2060)}';
final String _commaBreak = ',${String.fromCharCode(0x200B)}';

/// 키-값 줄의 값 — [keepAllAmount] 에 더해 **구간 기호(`~` · `–`) 뒤에서도** 줄을 바꿀 수 있게 한다. "10월 1일~10월 31일" 은 공백이
/// 없어 한 낱말로 묶이는데, 글자 200% 에서 그 낱말이 한 줄보다 길면 Flutter 가 칸 끝에서 끊어 "10 / 월" 처럼 낱말 가운데서
/// 갈라졌다(DA-31). 날짜 한 덩어리(`10월` · `31일`)는 그대로 묶어 두고 구간 기호 뒤에서만 끊는다.
String keepAllRange(String text) => keepAllAmount(text)
    .replaceAll(
      '~${String.fromCharCode(0x2060)}',
      '~${String.fromCharCode(0x200B)}',
    )
    .replaceAll(
      '–${String.fromCharCode(0x2060)}',
      '–${String.fromCharCode(0x200B)}',
    );

/// 칸 폭에 맞춰 줄바꿈 자리를 고른다 — 띄어쓰기에서 먼저 꺾고, **쉼표(구간 기호) 뒤 줄바꿈은 그 낱말 하나만으로 한 줄이 넘칠 때만**
/// 쓴다(금액의 마지막 수단). `한도 1,000,000원` 이 `한도 1,` / `000,000원` 으로 갈라지지 않고 `한도` / `1,000,000원` 이 된다
/// (DA-31). 글자 크기 · 폭이 줄바꿈을 정하므로 [style] · [scaler] · [maxWidth](칸 폭)가 필요하다. 보이는 글에만 쓴다 —
/// 읽는 이름은 원래 글로 넘긴다.
String keepAllFit(
  String text, {
  required TextStyle style,
  required TextScaler scaler,
  required double maxWidth,
}) {
  double width(String t) => (TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout()).width;
  return text
      .split(' ')
      .map(
        (w) => w.isEmpty || width(w) <= maxWidth ? keepAll(w) : keepAllRange(w),
      )
      .join(' ');
}
