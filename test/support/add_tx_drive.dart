// 거래 추가 폼(I-21 21-2 두 단계)을 누르는 공용 동작 — 옛 한 화면 폼의 "칸에 치고 칩 · 셀렉트를 누른다" 를 새 길로 옮긴 것이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1단계에 금액을 치고 [다음] → 2단계에서 카테고리(고르기 시트)와 계좌·카드(선택)를 고른다.
Future<void> fillNewTx(
  WidgetTester tester, {
  required String amount,
  String category = '식비',
  String? asset,
}) async {
  await tester.enterText(find.byType(EditableText).first, amount);
  await tester.pump();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('tx-row-category')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(category).last);
  await tester.pumpAndSettle();
  if (asset != null) {
    await tester.tap(find.byKey(const ValueKey('tx-row-asset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(asset).last);
    await tester.pumpAndSettle();
  }
}
