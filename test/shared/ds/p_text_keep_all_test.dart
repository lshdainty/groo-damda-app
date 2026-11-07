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

/// 맨 `Text` 로 둬도 되는 곳 — (파일 끝 경로, 첫 인자에 든 글) : 이유.
const _allowed = <(String, String), String>{
  ('budget/presentation/budget_screen.dart', 'budgetCurrentCategorySum'):
      '금액이 든 글',
  ('stats/presentation/stats_parts.dart', 'statsTotalPrefix'): '금액이 든 글',
  ('dutch_pay/presentation/dutch_pay_step.dart', 'dutchSharesTotal'):
      '금액(가림 포함)이 든 글',
  ('asset/presentation/asset_detail_dialog.dart', 'assetInstallmentPrincipal'):
      '금액 · 가림 표식이 든 글',
  ('settings/presentation/account_screen.dart', 'hiddenCount'): '숫자만 있는 글',
  ('stocks/presentation/toss_stocks_view.dart', "'≈ \${"): '금액이 든 글',
  ('expense/presentation/widgets/ledger_header.dart', 'MaskKind.expense'):
      '금액 글',
  ('expense/presentation/widgets/ledger_header.dart', 'MaskKind.income'):
      '금액 글',
};

/// `Text(` 호출의 본문(괄호 안) — 문자열 속 괄호는 건너뛴다.
String? _bodyAt(String s, int start) {
  var i = start;
  var depth = 1;
  while (depth > 0 && i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      final q = c;
      i++;
      while (i < s.length && s[i] != q) {
        if (s[i] == r'\') i++;
        i++;
      }
    } else if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
    }
    i++;
  }
  return depth == 0 ? s.substring(start, i - 1) : null;
}

void main() {
  test('읽는 글은 PText — 띄어쓰기가 든 글을 맨 Text 로 그리는 곳이 없다', () {
    final arb =
        jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync())
            as Map<String, dynamic>;
    final call = RegExp(r'(?<![A-Za-z_.])Text(\.rich)?\(');
    final literal = RegExp(r'''^['"]([^'"]*)['"]''');
    final key = RegExp(r'^l\.(\w+)');
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
        final first = body.trim();
        String? value;
        final k = key.firstMatch(first);
        if (k != null && arb[k.group(1)] is String) {
          value = arb[k.group(1)] as String;
        }
        final lit = literal.firstMatch(first);
        if (lit != null) value = lit.group(1);
        if (value == null) continue;
        final plain = value.replaceAll(RegExp(r'\{[^}]*\}'), '0');
        if (!plain.trim().contains(' ')) continue;
        final rel = path.replaceFirst('lib/features/', '');
        final hit = _allowed.keys.where(
          (a) => rel.endsWith(a.$1) && body.contains(a.$2),
        );
        if (hit.isNotEmpty) {
          used.addAll(hit);
          continue;
        }
        final line = '\n'.allMatches(s.substring(0, m.start)).length + 1;
        bad.add('$path:$line  "${plain.trim()}"');
      }
    }
    expect(
      bad,
      isEmpty,
      reason:
          'Text 대신 PText 를 쓴다(금액 · 숫자만 있는 글이면 _allowed 에 이유와 함께):\n${bad.join('\n')}',
    );
    // 목록이 낡지 않게 — 없어진 곳은 지운다
    expect(
      _allowed.keys.toSet().difference(used),
      isEmpty,
      reason: '더는 맨 Text 가 아닌 항목이 _allowed 에 남았다',
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
