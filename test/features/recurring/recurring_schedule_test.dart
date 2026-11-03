// 반복 회차 셈 — 서버 `adjustToFrequency` · `firstOccurrenceOnOrAfter` · `calculateNextDate` 와 같은 규칙(웹 `recurring-schedule.test.ts` 와 같은 표).
// 목록 묶음 머리 합 · 줄 · 상세의 "다음 예정일" · 폼 안내가 한 벌로 쓴다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/recurring/domain/recurring_schedule.dart';

import 'recurring_test_support.dart';

void main() {
  group('이번 달 합(그림 셈표 — 지출 다섯 · 수입 하나 · 쉬는 이체)', () {
    final items = [
      rec(1, '관리비', 234560, dom: 25, start: '2026-01-25'),
      rec(
        2,
        '주차 정기권',
        12000,
        freq: 'WEEKLY',
        dow: 1,
        dom: null,
        start: '2026-01-05',
      ),
      rec(3, '사무실 임대료', 123456789, dom: 1, start: '2026-01-01'),
      rec(4, '영상 구독', 17000, dom: 2, start: '2026-01-02'),
      rec(5, '자동차 보험료', 1234560, freq: 'YEARLY', dom: 14, start: '2025-10-14'),
      rec(6, '급여', 123456789, type: 'INCOME', dom: 21, start: '2026-01-21'),
      rec(7, '적금 이체', 1000000, type: 'TRANSFER', dom: 10, active: 'N'),
    ];

    test('10월 지출 = −124,990,909 (월요일 넷 · 보험료 포함)', () {
      expect(monthTotal(items, 'EXPENSE', 2026, 10), 124990909);
    });
    test('11월 지출 = −123,768,349 (월요일 다섯 · 보험료 없음)', () {
      expect(monthTotal(items, 'EXPENSE', 2026, 11), 123768349);
    });
    test('10월 수입 = +123,456,789', () {
      expect(monthTotal(items, 'INCOME', 2026, 10), 123456789);
    });
    test('거절된 셈(매월만 · 한 달 평균)이 아니다', () {
      expect(monthTotal(items, 'EXPENSE', 2026, 10), isNot(123708349));
      expect(monthTotal(items, 'EXPENSE', 2026, 10), isNot(123863229));
    });
    test('쉬는 반복은 뺀다', () {
      expect(
        monthTotal([rec(7, 'x', 100, active: 'N')], 'EXPENSE', 2026, 10),
        0,
      );
    });
    test('끝 날짜 · 최대 횟수를 넘는 회차는 뺀다', () {
      final ended = rec(8, 'e', 1000, start: '2026-01-25', end: '2026-09-15');
      expect(monthTotal([ended], 'EXPENSE', 2026, 10), 0);
      final capped = rec(9, 'c', 1000, start: '2026-01-25', max: 3);
      expect(monthTotal([capped], 'EXPENSE', 2026, 10), 0);
      expect(monthTotal([capped], 'EXPENSE', 2026, 3), 1000);
    });
  });

  group('previewNextDateKeys — 서버 첫 회차 규칙', () {
    test('시작일이 매월 날보다 뒤면 다음 달부터(옛 계산은 앞 날을 첫 회차로 보였다)', () {
      expect(previewNextDateKeys('2026-10-16', 'MONTHLY', 0, 1, 3), [
        '2026-11-01',
        '2026-12-01',
        '2027-01-01',
      ]);
    });
    test('시작일이 매월 날과 같거나 앞이면 그 달', () {
      expect(previewNextDateKeys('2026-10-16', 'MONTHLY', 0, 25, 3), [
        '2026-10-25',
        '2026-11-25',
        '2026-12-25',
      ]);
    });
    test('매월 31일은 그달 마지막 날', () {
      expect(previewNextDateKeys('2026-01-31', 'MONTHLY', 0, 31, 4), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
      ]);
    });
    test('매주는 그 요일까지 앞으로(UI 0=일 ~ 6=토)', () {
      // 2026-10-31 은 토요일 — 월요일(1)은 11월 2일
      expect(previewNextDateKeys('2026-10-31', 'WEEKLY', 1, 1, 3), [
        '2026-11-02',
        '2026-11-09',
        '2026-11-16',
      ]);
    });
    test('매년은 시작일의 월 · 일', () {
      expect(previewNextDateKeys('2025-10-14', 'YEARLY', 0, 14, 3), [
        '2025-10-14',
        '2026-10-14',
        '2027-10-14',
      ]);
    });
    test('끝 날짜 · 횟수를 넘지 않는다', () {
      expect(
        previewNextDateKeys(
          '2026-10-25',
          'MONTHLY',
          0,
          25,
          3,
          endDate: '2026-11-30',
        ),
        ['2026-10-25', '2026-11-25'],
      );
      expect(
        previewNextDateKeys(
          '2026-10-25',
          'MONTHLY',
          0,
          25,
          3,
          maxOccurrences: 1,
        ),
        ['2026-10-25'],
      );
    });
  });

  group('upcomingDates — 서버가 준 다음 날짜에서', () {
    final rule = ScheduleRule.of(rec(1, 'a', 1, end: '2026-12-31'));
    test('끝 날짜를 넘는 날은 뺀다', () {
      expect(upcomingDates(rule, '2026-11-25', 9, 3), [
        '2026-11-25',
        '2026-12-25',
      ]);
    });
    test('남은 횟수(최대 − 실행)를 넘는 날은 뺀다', () {
      final r = ScheduleRule.of(rec(1, 'a', 1, max: 12, executed: 11));
      expect(upcomingDates(r, '2026-11-25', 11, 3), ['2026-11-25']);
    });
    test('쉬는 중이면 없다', () {
      expect(upcomingDates(rule, '2026-11-25', 9, 3, active: false), isEmpty);
    });
  });

  group('isFinished', () {
    test('횟수를 채워 서버가 N 으로 바꾼 반복도 끝남이다(쉬는 중 아님)', () {
      final it = rec(1, 'a', 1, max: 3, executed: 3, active: 'N');
      expect(isFinished(it), isTrue);
      expect(isPausedRec(it), isFalse);
    });
    test('끝나지 않고 꺼진 반복은 쉬는 중', () {
      final it = rec(1, 'a', 1, max: 3, executed: 1, active: 'N');
      expect(isFinished(it), isFalse);
      expect(isPausedRec(it), isTrue);
    });
    test('실행 수가 최대 횟수에 닿으면 끝남', () {
      expect(isFinished(rec(1, 'a', 1, max: 3, executed: 3)), isTrue);
    });
    test('다음 날짜가 끝 날짜 뒤면 끝남', () {
      expect(
        isFinished(rec(1, 'a', 1, end: '2026-09-15', next: '2026-10-15')),
        isTrue,
      );
      expect(
        isFinished(rec(1, 'a', 1, end: '2027-09-15', next: '2026-10-15')),
        isFalse,
      );
    });
  });
}
