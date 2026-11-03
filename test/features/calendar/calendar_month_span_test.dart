// 일정이 걸친 달 목록 — 달을 걸친 일정을 뒤쪽 달에서 고치거나 지워도 걸친 모든 달 키를 비우는 근거(I-09b 코드 검수 A1).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/calendar/presentation/calendar_event_actions.dart';

void main() {
  test('한 달 안의 일정은 그 달 하나', () {
    expect(
      calendarMonthsSpanned(DateTime(2026, 10, 3), DateTime(2026, 10, 31)),
      [(year: 2026, month: 10)],
    );
  });

  test('달을 걸치면 시작 달부터 끝 달까지 모두', () {
    expect(
      calendarMonthsSpanned(
        DateTime(2026, 10, 30, 10),
        DateTime(2026, 11, 2, 11),
      ),
      [(year: 2026, month: 10), (year: 2026, month: 11)],
    );
  });

  test('해를 넘기면 12월 다음이 1월이다', () {
    expect(
      calendarMonthsSpanned(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
      [(year: 2026, month: 12), (year: 2027, month: 1)],
    );
  });

  test('끝이 시작보다 앞서도(저장 전 잘못된 값) 시작 달 하나로 멈춘다', () {
    expect(calendarMonthsSpanned(DateTime(2026, 10, 5), DateTime(2026, 9, 1)), [
      (year: 2026, month: 10),
    ]);
  });
}
