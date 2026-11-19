// I-09 09-1 월 격자 칩 줄 배치 — 웹 `calculateMonthEventPositions` · `buildMonthModel` 과 같은 규칙.
// 공용 표본(fixtures/month_position_fixture.json — 웹 시험이 같은 파일을 쓴다)의 같은 입력이 같은 줄 번호를 낸다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_month_model.dart';

/// 캘린더 칸의 칩 자리(칸 안 글은 글자 크기를 따르지 않아 고정 — groo-design #260).
const _metrics100 = kCalendarChipMetrics;

/// 칩이 큰 좁은 자리 — 모델 셈(웹 `planSlots` 와 같다)을 가장 나쁜 값으로 본다.
const _metricsTight = ChipMetrics(avail: 61, chip: 36, more: 32, gap: 2);

Map<String, dynamic> _fixture() =>
    jsonDecode(
          File(
            'test/features/calendar/fixtures/month_position_fixture.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

/// 표본 한 건을 앱이 쓰는 길(일정 · 공휴일)로 격자 한 건으로 만든다.
CalendarGridItem _build(Map<String, dynamic> m) {
  final start = m['startDate'] as String;
  final end = m['endDate'] as String;
  if (m['holiday'] == true) {
    return CalendarGridItem.ofHoliday(
      start.substring(0, 10),
      m['title'] as String,
    );
  }
  return CalendarGridItem.ofEvent(
    CalendarEvent(
      rowId: int.parse(m['id'] as String),
      title: m['title'] as String,
      startDate: start,
      endDate: end,
      isAllDay: (m['isAllDay'] as bool) ? 'Y' : 'N',
    ),
  );
}

void main() {
  final fx = _fixture();
  final month = DateTime(
    (fx['month'] as Map)['year'] as int,
    (fx['month'] as Map)['month'] as int,
  );
  final items = [
    for (final m in (fx['items'] as List).cast<Map<String, dynamic>>())
      _build(m),
  ];
  final titleByKey = {
    for (final m in (fx['items'] as List).cast<Map<String, dynamic>>())
      '${m['id']}-${m['startDate']}': m['title'] as String,
  };

  test('공용 표본 — 웹과 같은 입력에 같은 줄 번호(이어지는 종일 × 공휴일 · 긴 일정 여럿 · 달 경계)', () {
    final positions = calculateMonthPositions(items, month);
    final byTitle = {for (final i in items) i.title: positions[i.key]};
    final expected = (fx['expectedPositions'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(titleByKey[k]!, v as int),
    );
    expect(byTitle, expected);
  });

  test('이어지는 일정은 걸친 모든 날이 같은 줄이다 — 공휴일이 첫 줄을 먼저 차지하지 않는다', () {
    final positions = calculateMonthPositions(items, month);
    final model = buildMonthModel(
      calendarGridDays(month),
      month,
      items,
      positions,
      _metrics100,
    );
    CellModel at(int d) =>
        model.firstWhere((c) => c.day == DateTime(2026, 10, d));
    int rowOf(CellModel c, String title) =>
        c.slots.indexWhere((s) => s?.item.title == title);
    // 8 · 9일 "이틀 종일 일정" 이 같은 줄, 9일 공휴일은 그 아래 줄(계단이 아니다)
    expect(rowOf(at(8), '이틀 종일 일정'), rowOf(at(9), '이틀 종일 일정'));
    expect(rowOf(at(9), '한글날 (공휴일)'), greaterThan(rowOf(at(9), '이틀 종일 일정')));
  });

  test('달 경계 — 이번 달 밖 날은 잘라 내고 달에 걸치지 않는 일정은 줄이 없다', () {
    final out = CalendarGridItem(
      key: 'x-1',
      title: '지난달 일정',
      startAt: DateTime(2026, 9, 3, 9),
      endAt: DateTime(2026, 9, 3, 10),
      allDay: false,
    );
    final positions = calculateMonthPositions([...items, out], month);
    expect(positions.containsKey('x-1'), isFalse);
    // 9월 29일에 시작해 10월 2일에 끝나는 일정은 10월 1 · 2일에 앉는다
    final model = buildMonthModel(
      calendarGridDays(month),
      month,
      items,
      calculateMonthPositions(items, month),
      _metrics100,
    );
    final oct1 = model.firstWhere((c) => c.day == DateTime(2026, 10, 1));
    expect(
      oct1.slots.whereType<ChipSlot>().map((s) => s.item.title),
      contains('전달에서 걸친 긴 일정'),
    );
  });

  test('보이는 줄 수는 칸 높이가 정하고 나머지는 +N개 — 22일 칩 둘 · 좁은 칩 자리면 칩 0', () {
    final positions = calculateMonthPositions(items, month);
    CellModel cell22(ChipMetrics m) => buildMonthModel(
      calendarGridDays(month),
      month,
      items,
      positions,
      m,
    ).firstWhere((c) => c.day == DateTime(2026, 10, 22));
    // 하루 종일 1 + 일정 다섯 = 6 줄 → 칩 둘 + "+4개"
    final a = cell22(_metrics100);
    expect(a.slots.length, 2);
    expect(a.hidden, 4);
    expect(a.total, 6);
    // 좁은 칩 자리: 한 줄도 못 그리고 전부 "+6개"
    final b = cell22(_metricsTight);
    expect(b.slots, isEmpty);
    expect(b.hidden, 6);
  });

  test('이어지는 일정의 제목은 주마다 한 번, 그 주에서 띠가 처음 보이는 칸에', () {
    final positions = calculateMonthPositions(items, month);
    final model = buildMonthModel(
      calendarGridDays(month),
      month,
      items,
      positions,
      _metrics100,
    );
    // "나흘 이어지는 종일 일정"(17 ~ 20) — 17일(토)은 그 주 마지막 칸이라 거기 한 줄 · 18일(일)에서 다음 주 3칸
    final hosts = <(int, int)>[];
    for (final c in model) {
      for (final s in c.slots) {
        if (s != null && s.item.title == '나흘 이어지는 종일 일정' && s.labelDays > 0) {
          hosts.add((c.day.day, s.labelDays));
        }
      }
    }
    expect(hosts, [(17, 1), (18, 3)]);
  });

  test('다음 칸이 접혀 "+N개" 만 남으면 제목 띠는 보이는 칸까지만 — 빈 칩만 남지 않는다', () {
    final two = [
      CalendarGridItem(
        key: 'a',
        title: '이틀 종일 일정',
        startAt: DateTime(2026, 10, 8),
        endAt: DateTime(2026, 10, 9, 23, 59, 59),
        allDay: true,
      ),
      CalendarGridItem.ofHoliday('2026-10-09', '한글날'),
    ];
    final model = buildMonthModel(
      calendarGridDays(month),
      month,
      two,
      calculateMonthPositions(two, month),
      _metricsTight,
    );
    CellModel at(int d) =>
        model.firstWhere((c) => c.day == DateTime(2026, 10, d));
    final s8 = at(8).slots.whereType<ChipSlot>().single;
    expect(s8.item.title, '이틀 종일 일정');
    expect(s8.labelDays, 1, reason: '9일 칸은 접혀 칩이 없다');
    expect(at(9).slots, isEmpty);
    expect(at(9).hidden, 2);
  });

  test('캘린더 칩 자리 — (103 − 2 − 원 26 − 2) · 칩 18 · "+N개" 16 · 사이 2', () {
    expect(kCalendarChipMetrics.avail, 73);
    expect(kCalendarChipMetrics.chip, 18);
    expect(kCalendarChipMetrics.more, 16);
    expect(kCalendarChipMetrics.gap, 2);
  });

  test('planSlots — 웹 planSlots 와 같다', () {
    expect(planSlots(0, _metrics100), (shown: 0, more: false));
    expect(planSlots(3, _metrics100), (
      shown: 3,
      more: false,
    )); // 3*18+2*2=58 <= 73
    expect(planSlots(4, _metrics100), (
      shown: 2,
      more: true,
    )); // 4*18+3*2=78 > 73
    expect(planSlots(1, _metricsTight), (shown: 1, more: false));
    expect(planSlots(2, _metricsTight), (shown: 0, more: true));
  });
}
