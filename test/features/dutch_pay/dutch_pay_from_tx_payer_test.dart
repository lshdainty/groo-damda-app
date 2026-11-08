// 거래에서 만드는 더치페이의 결제자는 늘 나다(QA 30 3).
//
// "나도 포함" 을 끄면 "내가 전액 결제, 다른 사람 몫만 받아요" 다 — 나는 결제자이고 내 몫은 0원.
// 종전엔 나를 빼고 전원 isPayer false 로 보내 서버가 400 "결제한 사람을 한 명 골라 주세요" 로
// 막아 토스트만 뜨고 정산이 안 생겼다. 이제 나를 0원 결제자로 함께 싣는다(서버는 결제자에게만
// 0원을 받는다, desk-back #360).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import '../../support/dutch_flow_harness.dart';
import '../../support/plain_text.dart';

Future<(DutchFakeRepo, AppLocalizations)> _open(WidgetTester tester) =>
    openDutchFlow(tester);

Future<void> _addFriend(WidgetTester tester, AppLocalizations l) async {
  await tester.enterText(find.byType(EditableText).first, '친구A');
  await tester.tap(findWidgetWithText(PButton, l.dutchAdd));
  await tester.pumpAndSettle();
}

Future<void> _create(WidgetTester tester, AppLocalizations l) async {
  await tester.tap(findWidgetWithText(PButton, l.dutchCreate));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('나도 포함(기본): 내가 결제자, 친구는 아니다', (tester) async {
    final (repo, l) = await _open(tester);
    await _addFriend(tester, l);
    await _create(tester, l);

    expect(repo.sent, isNotNull, reason: '정산을 안 만들었다');
    expect(repo.sent!.map((p) => (p.name, p.amount, p.isPayer)).toList(), [
      ('나', 1500, true),
      ('친구A', 1500, false),
    ]);
  });

  testWidgets('나도 포함 끔: 나를 0원 결제자로 싣고 친구가 총액을 낸다', (tester) async {
    final (repo, l) = await _open(tester);
    await _addFriend(tester, l);
    await tester.tap(findText(l.dutchMeIncludeTitle));
    await tester.pumpAndSettle();
    await _create(tester, l);

    expect(repo.sent, isNotNull, reason: '정산을 안 만들었다 — 결제자 없는 요청은 서버가 400 이다');
    expect(repo.sent!.map((p) => (p.name, p.amount, p.isPayer)).toList(), [
      ('나', 0, true),
      ('친구A', 3000, false),
    ]);
    expect(repo.sent!.where((p) => p.isPayer), hasLength(1));
  });
}
