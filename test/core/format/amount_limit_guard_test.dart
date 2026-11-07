// 금액 상한 규칙 네 줄(웹 useAmountLimit 과 같은 규칙) — 대표 칸으로 잠근다.
//  3-a 줄이는 입력은 늘 받는다(옛 초과 값을 줄여 나갈 수 있다), 여전히 상한 위면 오류는 계속 보인다
//  3-b 오류는 지금 값에서 나온다 — 칸 밖에서 값이 바뀌어(프리셋 칩 · 비우기) 상한 안이 되면 사라진다
//  3-c 최근 일이 이긴다 — 거절한 순간엔 상한 오류, 저장을 누른 순간엔 [dismiss]
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/amount_limit_guard.dart';

TextEditingValue _edit(AmountLimitGuard g, String next) {
  final old = g.controller.value;
  var v = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: next.length),
  );
  for (final f in g.formatters) {
    v = f.formatEditUpdate(old, v);
  }
  g.controller.value = v;
  return v;
}

void main() {
  late TextEditingController c;
  late AmountLimitGuard g;
  var changes = 0;
  setUp(() {
    changes = 0;
    c = TextEditingController();
    g = AmountLimitGuard(c, onChanged: () => changes++);
  });
  tearDown(() {
    g.dispose();
    c.dispose();
  });

  test('거절하면 오류가 서고, 다음 유효한 입력에서 사라진다', () {
    _edit(g, '10000000000');
    expect(g.over, isFalse, reason: '정확히 100억은 받는다');
    _edit(g, '100000000000');
    expect(c.text, '10,000,000,000', reason: '넘는 글자는 받지 않는다');
    expect(g.over, isTrue);
    _edit(g, '5000');
    expect(g.over, isFalse);
  });

  test('3-a 줄이는 입력은 늘 받는다 — 옛 초과 값은 처음부터 오류, 줄여도 상한 위면 계속 오류', () {
    c.text = '99,999,999,999'; // 상한 전에 저장된 값
    expect(g.over, isTrue, reason: '열자마자 오류 — 저장은 호출처 검증이 막는다');
    _edit(g, '9,999,999,999,9'); // 한 자리 늘림은 거절
    expect(c.text, '99,999,999,999');
    _edit(g, '50,000,000,000'); // 줄이는 입력: 받는다(500억 — 여전히 상한 위)
    expect(c.text, '50,000,000,000');
    expect(g.over, isTrue, reason: '여전히 상한 위면 오류는 계속 보인다');
    _edit(g, '60,000,000,000'); // 다시 키우는 입력은 거절
    expect(c.text, '50,000,000,000');
    _edit(g, '9,999,999,999'); // 상한 안
    expect(g.over, isFalse);
  });

  test('3-b 칸 밖에서 값을 바꾸면(프리셋 칩 · 비우기) 지금 값으로 다시 계산한다', () {
    _edit(g, '100000000000');
    expect(g.over, isTrue);
    c.text = '1,500,000'; // 칩이 값을 넣는다
    expect(g.over, isFalse);
    _edit(g, '100000000000');
    c.clear(); // 비우기
    expect(g.over, isFalse);
  });

  test('3-c 저장을 누르면 거절 오류를 내려놓는다 — 다음 거절은 다시 선다', () {
    _edit(g, '100000000000');
    expect(g.over, isTrue);
    g.dismiss();
    expect(g.over, isFalse, reason: '폼 검증 오류가 자리를 받는다');
    _edit(g, '100000000000');
    expect(g.over, isTrue);
    expect(changes, greaterThan(0));
  });

  test('쉼표 없는 칸(필터) — 숫자만, 같은 규칙', () {
    final c2 = TextEditingController();
    final g2 = AmountLimitGuard(c2, grouped: false, onChanged: () {});
    addTearDown(() {
      g2.dispose();
      c2.dispose();
    });
    _edit(g2, '100000000000');
    expect(c2.text, '', reason: '빈 칸에 넘는 값을 붙이면 받지 않는다');
    expect(g2.over, isTrue);
    _edit(g2, '123');
    expect(c2.text, '123');
    expect(g2.over, isFalse);
  });
}
