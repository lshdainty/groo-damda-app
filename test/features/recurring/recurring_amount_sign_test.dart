// 반복 거래 목록의 금액 부호 — 지출은 U+2212(−), 수입은 +, 이체는 부호 없음. 묶음 머리 합도 같다. 0 이면 부호를 떼고 합 없는 묶음은 그리지 않는다.
// (옛 요약 카드가 걷혀 "매월 고정 지출" 셈 대신 묶음 머리의 이번 달 합을 잠근다 — I-20 D 22)
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_screen.dart';

import 'recurring_test_support.dart';

Future<void> _pumpRecurring(
  WidgetTester tester,
  List<RecurringTransaction> items,
) => pumpApp(tester, const RecurringScreen(), [
  recurringListProvider.overrideWith((ref) async => items),
  categoriesProvider.overrideWith((ref) async => const []),
]);

void main() {
  testWidgets('지출 줄은 U+2212 로 찍는다 — ASCII 하이픈이 아니다', (tester) async {
    await _pumpRecurring(tester, [rec(1, '관리비', 51750)]);
    expect(plain('−51,750원'), findsOneWidget);
    expect(plain('-51,750원'), findsNothing);
  });

  testWidgets('묶음 머리 합 — 지출은 이번 달 −, 수입은 +', (tester) async {
    await _pumpRecurring(tester, [
      rec(1, '관리비', 51750, start: '2026-01-01', dom: 1),
      rec(2, '급여', 990000, type: 'INCOME', dom: 1, start: '2026-01-01'),
    ]);
    expect(plainStarts('이번 달 −'), findsOneWidget);
    expect(plainStarts('이번 달 +'), findsOneWidget);
  });

  testWidgets('수입 줄은 +, 이체 줄은 부호 없음', (tester) async {
    await _pumpRecurring(tester, [
      rec(2, '급여', 990000, type: 'INCOME'),
      rec(3, '적금', 100000, type: 'TRANSFER', dom: 10),
    ]);
    expect(plain('+990,000원'), findsOneWidget);
    expect(plain('100,000원'), findsOneWidget);
  });

  testWidgets('금액이 0 인 반복 줄에는 부호가 없다', (tester) async {
    await _pumpRecurring(tester, [
      rec(1, '무료', 0),
      rec(2, '무료 수입', 0, type: 'INCOME'),
    ]);
    expect(plain('+0원'), findsNothing);
    expect(plain('−0원'), findsNothing);
    expect(plain('0원'), findsWidgets);
  });

  testWidgets('반복이 없으면 묶음 머리를 그리지 않는다', (tester) async {
    await _pumpRecurring(tester, const []);
    expect(plainStarts('이번 달'), findsNothing);
    expect(plain('반복 거래가 없어요'), findsOneWidget);
  });
}
