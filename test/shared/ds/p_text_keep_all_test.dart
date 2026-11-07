// 낱말 단위 줄바꿈(v114) 누락 가드 — 화면의 읽는 글이 `Text` 로 맨 채 남지 않았는지 소스에서 센다.
//
// 띄어쓰기가 든 글(l10n 키 · 글 리터럴)을 `Text(` / `Text.rich(` 에 맨 채 주면 글자 단위로 줄이 바뀐다(한국어 낱말 중간에서
// 끊김). 읽는 글은 [PText] 로 그린다. 금액이 든 글([keepAllAmount]) · 숫자만 있는 글은 아래 목록에 이유와 함께 둔다.
// 새 화면이 이 목록에 없는 맨 `Text` 를 들이면 이 시험이 파일:줄로 알려 준다(전수 grep 가드 — I-wrap-b3 가.4).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

import '../../support/line_breaks.dart';

/// 맨 `Text` 로 둬도 되는 곳 — (파일 끝 경로, 첫 인자 전체[공백 정리]) : 이유. 첫 인자가 고유 표식이라 같은 파일에 새 맨 Text 가
/// 생겨도 지나가지 않는다.
const _allowed = <(String, String), String>{
  (
    'settings/presentation/account_screen.dart',
    r"'$hiddenCount / $hiddenTotal'",
  ): '숫자만 있는 글',
  (
    'subscription/presentation/subscription_screen.dart',
    "f.free ? 'Free · Pro' : 'Pro'",
  ): '요금제 이름(고정 영문 표기)',
};

/// `Text(` 호출의 본문(괄호 안) — 문자열 속 괄호는 건너뛴다.
String? _bodyAt(String s, int start) {
  var i = start;
  var depth = 1;
  while (depth > 0 && i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      i = _skipString(s, i);
      continue;
    } else if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
    }
    i++;
  }
  return depth == 0 ? s.substring(start, i - 1) : null;
}

/// [i] 의 따옴표에서 시작하는 문자열 끝 다음 위치(`${…}` 안의 따옴표도 건너뛴다).
int _skipString(String s, int i) {
  final q = s[i];
  i++;
  while (i < s.length && s[i] != q) {
    if (s[i] == r'\') {
      i += 2;
      continue;
    }
    if (s[i] == r'$' && i + 1 < s.length && s[i + 1] == '{') {
      var d = 1;
      i += 2;
      while (i < s.length && d > 0) {
        if (s[i] == "'" || s[i] == '"') {
          i = _skipString(s, i);
          continue;
        }
        if (s[i] == '{') d++;
        if (s[i] == '}') d--;
        i++;
      }
      continue;
    }
    i++;
  }
  return i + 1;
}

/// 첫 인자 — 괄호 · 중괄호 · 문자열 밖의 첫 쉼표 앞까지(삼항 · switch 의 가지를 포함한다).
String _firstArg(String body) {
  var depth = 0;
  var i = 0;
  while (i < body.length) {
    final c = body[i];
    if (c == "'" || c == '"') {
      i = _skipString(body, i);
      continue;
    }
    if (c == '(' || c == '{' || c == '[') depth++;
    if (c == ')' || c == '}' || c == ']') depth--;
    if (c == ',' && depth == 0) break;
    i++;
  }
  return body.substring(0, i).trim();
}

/// 첫 인자가 읽는 글로 보이는 값들 — `l.키` 의 한국어 값과 글 리터럴(`${…}` 안은 코드라 뺀다).
List<String> _texts(String first, Map<String, dynamic> arb) {
  final out = <String>[];
  for (final m in RegExp(r'(?<![\w.])l\.(\w+)').allMatches(first)) {
    final v = arb[m.group(1)];
    if (v is String) out.add(v);
  }
  var i = 0;
  while (i < first.length) {
    final c = first[i];
    if (c == "'" || c == '"') {
      final end = _skipString(first, i);
      final lit = first.substring(i + 1, end - 1);
      out.add(_stripInterpolation(lit));
      i = end;
    } else {
      i++;
    }
  }
  return out;
}

String _stripInterpolation(String lit) {
  final b = StringBuffer();
  var i = 0;
  while (i < lit.length) {
    if (lit[i] == r'$' && i + 1 < lit.length && lit[i + 1] == '{') {
      var d = 1;
      i += 2;
      while (i < lit.length && d > 0) {
        if (lit[i] == '{') d++;
        if (lit[i] == '}') d--;
        i++;
      }
      continue;
    }
    b.write(lit[i]);
    i++;
  }
  return b.toString();
}

void main() {
  // 한계 — 첫 인자만 본다. `Text.rich(TextSpan(…))` 와, 변수에 담았다가 넘기는 글은 못 본다. 삼항 · switch 로 넘기는 글은
  // 첫 인자 안의 `l.키` · 글 리터럴 가지를 모두 본다. 금액이 든 글은 `PText.amount`, 읽는 글은 `PText`.
  test('읽는 글은 PText — 띄어쓰기가 든 글(삼항 · switch 가지 포함)을 맨 Text 로 그리는 곳이 없다', () {
    final arb =
        jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
            as Map<String, dynamic>;
    final call = RegExp(r'(?<![A-Za-z_.])Text\(');
    final bad = <String>[];
    final used = <(String, String)>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path;
      if (path.contains('shared/ds/') ||
          path.contains('l10n/generated') ||
          path.endsWith('_demo.dart')) {
        continue;
      }
      final s = f.readAsStringSync();
      for (final m in call.allMatches(s)) {
        final body = _bodyAt(s, m.end);
        if (body == null || body.contains('keepAll')) continue;
        final first = _firstArg(body);
        final values = _texts(first, arb);
        final spaced = values.where(
          (v) => v.replaceAll(RegExp(r'\{[^}]*\}'), '0').trim().contains(' '),
        );
        if (spaced.isEmpty) continue;
        final rel = path.replaceFirst('lib/features/', '');
        final norm = first.replaceAll(RegExp(r'\s+'), ' ');
        final hit = _allowed.keys.where(
          (a) => rel.endsWith(a.$1) && norm == a.$2,
        );
        if (hit.isNotEmpty) {
          used.addAll(hit);
          continue;
        }
        final line = '\n'.allMatches(s.substring(0, m.start)).length + 1;
        bad.add('$path:$line  "${spaced.first.trim()}"');
      }
    }
    expect(
      bad,
      isEmpty,
      reason:
          'Text 대신 PText(금액이면 PText.amount)를 쓴다(숫자만 있는 글이면 _allowed 에):\n${bad.join('\n')}',
    );
    // 목록이 낡지 않게 — 없어진 곳은 지운다
    expect(
      _allowed.keys.toSet().difference(used),
      isEmpty,
      reason: '더는 맨 Text 가 아닌 항목이 _allowed 에 남았다',
    );
  });

  test(r'가드 자체 — 삼항 · switch 가지와 ${…} 안 공백', () {
    final arb = <String, dynamic>{'a': '가나 다라', 'b': '가나'};
    expect(_texts(_firstArg('c ? l.a : l.b, style: s'), arb), ['가나 다라', '가나']);
    expect(
      _texts(_firstArg("switch (x) { 'k' => l.a, _ => l.b, }, style: s"), arb),
      contains('가나 다라'),
    );
    // 코드 안 공백은 글이 아니다
    expect(
      _texts(_firstArg(r"'−${f.of(M.e) ? '••' : krw(1)}', maxLines: 1"), arb),
      ['−'],
    );
  });

  Future<void> pumpIn(WidgetTester tester, Widget child, {double scale = 1}) =>
      tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: SizedBox(width: 160, child: child)),
          ),
        ),
      );

  testWidgets('PText — 글자 사이에 이음 문자, 읽는 이름은 원래 글', (tester) async {
    await pumpIn(tester, const PText('가계부 데이터는 보관해요'));
    final t = tester.widget<Text>(find.byType(Text));
    expect(t.data, keepAll('가계부 데이터는 보관해요'));
    expect(t.data, contains('⁠'));
    expect(t.semanticsLabel, '가계부 데이터는 보관해요');
  });

  testWidgets('PText — semanticsLabel 을 주면 그것을 읽는다', (tester) async {
    await pumpIn(tester, const PText('1 / 3단계', semanticsLabel: '3단계 중 1단계'));
    expect(tester.widget<Text>(find.byType(Text)).semanticsLabel, '3단계 중 1단계');
  });

  // 검수 M6 — 이음 문자는 문자 묶음(grapheme) 사이에만 들어간다
  test('keepAll — 이모지 · 국기 · ZWJ · 피부색 · 결합 문자 · NFD 한글 자모 묶음을 가르지 않는다', () {
    final nfdSyllable = String.fromCharCodes([0x1112, 0x1161, 0x11AB]); // 한
    for (final name in [
      '❤️', // VS16
      '👨‍👩‍👧', // ZWJ 가족
      '🇰🇷', // 국기
      '👍🏽', // 피부색
      'e\u0301', // 결합 문자
      nfdSyllable, // NFD 자모 셋
    ]) {
      expect(name.characters.length, 1, reason: '시험 전제: 한 묶음 $name');
      expect(keepAll(name), name, reason: '한 묶음 안에는 이음 문자가 없다: $name');
    }
    // 묶음 사이에는 들어간다 — 이모지 이름 · NFD 두 음절
    expect(keepAll('❤️집'), '❤️\u2060집');
    expect(keepAll('A 👍🏽B'), 'A 👍🏽\u2060B');
    expect(
      keepAll('$nfdSyllable$nfdSyllable'),
      '$nfdSyllable\u2060$nfdSyllable',
    );
    expect(
      keepAll('🇰🇷 한국 여행 😀😀').replaceAll('\u2060', ''),
      '🇰🇷 한국 여행 😀😀',
    );
  });

  testWidgets('PText.amount — 쉼표 뒤에서만 끊고 읽는 이름은 원래 글', (tester) async {
    await pumpIn(tester, const PText.amount('합계: 1,234,567원'));
    final t = tester.widget<Text>(find.byType(Text));
    expect(t.data, keepAllAmount('합계: 1,234,567원'));
    expect(t.semanticsLabel, '합계: 1,234,567원');
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'PText — 폭 160 · 글자 ${(scale * 100).round()}% 에서 낱말 중간을 끊지 않는다',
      (tester) async {
        await pumpIn(
          tester,
          const PText('종료가 시작보다 빠를 수 없어요 그대로 기록됩니다'),
          scale: scale,
        );
        expect(midWordBreaks(tester, find.byType(PText)), isEmpty);
        // 맨 Text 는 같은 자리에서 낱말 중간을 끊는다 — 가드가 필요한 이유
        await pumpIn(
          tester,
          const Text('종료가 시작보다 빠를 수 없어요 그대로 기록됩니다'),
          scale: scale,
        );
        expect(midWordBreaks(tester, find.byType(Text)), isNotEmpty);
      },
    );
  }
}
