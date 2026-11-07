// Date Picker 의 날짜 도구 · 글 · 값 — 수치 원본은 groo-design `specs/components/date-picker.yaml`(값은
// `test/fixtures/design_spec/date-picker.json`). 위젯은 `p_date_picker.dart` 다. 웹(desk-front
// `src/shared/ds/date-picker/date-picker-dates.ts`)과 같은 규칙이다.
//
// 날짜는 모두 **로컬 시간대의 그 날 0시** DateTime 으로 다룬다 — 시간은 보지 않는다. UTC 로 읽지 않는다(`DateTime.utc` ·
// `toUtc` · `toIso8601String` 을 쓰지 않는다 — 로컬 연 · 월 · 일 숫자로 만들고 [dayKey] 로 키를 만든다). 달 · 일 더하기는
// 시 · 분이 아니라 날짜 칸을 움직여(`DateTime(y, m, d + n)`) 서머타임 · 윤년에도 같은 날 0시에 닿는다.

import 'package:flutter/widgets.dart' show BuildContext, Localizations;
import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/l10n/ds_l10n.dart';

String pad2(int n) => n.toString().padLeft(2, '0');

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

/// 한 달 · 한 해 옮기기 — 같은 날, 없으면 그 달 말일(1월 31일 + 1달 = 2월 28일 · 윤년 29일).
DateTime addMonths(DateTime d, int n) {
  final first = DateTime(d.year, d.month + n);
  final last = daysInMonth(first.year, first.month);
  return DateTime(first.year, first.month, d.day < last ? d.day : last);
}

int compareDay(DateTime a, DateTime b) {
  if (a.year != b.year) return a.year - b.year;
  if (a.month != b.month) return a.month - b.month;
  return a.day - b.day;
}

bool sameDay(DateTime? a, DateTime? b) =>
    a != null && b != null && compareDay(a, b) == 0;

/// 달 번호 — 연 × 12 + 월(0 부터). 달끼리 빼면 몇 달 차이인지 나온다.
int monthNumber(DateTime d) => d.year * 12 + (d.month - 1);

DateTime fromMonthNumber(int n) => DateTime((n / 12).floor(), n % 12 + 1);

/// 로컬 연 · 월 · 일의 "YYYY-MM-DD" — UTC 가 아니다.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${pad2(d.month)}-${pad2(d.day)}';

/// 일요일 0 … 토요일 6 — Dart 의 weekday(월 1 … 일 7)를 일요일 시작으로 바꾼다.
int weekdayIndex(DateTime d) => d.weekday % 7;

/// 주는 일요일부터.
DateTime weekStart(DateTime d) => addDays(d, -weekdayIndex(d));

DateTime weekEnd(DateTime d) => addDays(d, 6 - weekdayIndex(d));

/// 그 달의 주 수 — 4 ~ 6.
int weeksInMonth(int year, int month) =>
    ((weekdayIndex(DateTime(year, month)) + daysInMonth(year, month)) / 7)
        .ceil();

DateTime clampDay(DateTime d, DateTime min, DateTime max) =>
    compareDay(d, min) < 0 ? min : (compareDay(d, max) > 0 ? max : d);

// ── 값 ───────────────────────────────────────────────────────

/// 기간 — 시작만 있으면 끝을 고르는 중이다.
class PDateRange {
  const PDateRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  static bool _same(DateTime? a, DateTime? b) =>
      a == null || b == null ? a == b : compareDay(a, b) == 0;

  @override
  bool operator ==(Object other) =>
      other is PDateRange && _same(start, other.start) && _same(end, other.end);

  @override
  int get hashCode => Object.hash(
    start == null ? null : dayKey(start!),
    end == null ? null : dayKey(end!),
  );

  @override
  String toString() =>
      'PDateRange(${start == null ? '-' : dayKey(start!)} ~ ${end == null ? '-' : dayKey(end!)})';
}

// ── 빠른 기간 ─────────────────────────────────────────────────

/// 빠른 기간 이름 — date-picker.md "빠른 기간" 의 한 벌(이름이 같으면 어디서나 같은 기간이다).
enum PDatePreset {
  thisWeek,
  thisMonth,
  lastMonth,
  last7Days,
  last30Days,
  last3Months,
  last6Months,
  last1Year,
  thisYear,
}

/// 빠른 기간의 범위 — 달력 단위(끝은 그 단위의 마지막 날, 앞으로의 날도 든다), 주는 일요일부터. [today] 는 오늘.
/// 이번 달을 넣은 n 달은 n − 1 달 전 1일 ~ 이번 달 말일이다(연초 · 윤년 2월 · 월말에도 달력 날짜로 셈한다).
({DateTime start, DateTime end}) getPresetRange(
  PDatePreset name,
  DateTime today,
) {
  final t = startOfDay(today);
  final y = t.year;
  final m = t.month;
  ({DateTime start, DateTime end}) months(int n) =>
      (start: DateTime(y, m - (n - 1)), end: DateTime(y, m + 1, 0));
  return switch (name) {
    PDatePreset.thisWeek => (start: weekStart(t), end: weekEnd(t)),
    PDatePreset.thisMonth => months(1),
    PDatePreset.lastMonth => (
      start: DateTime(y, m - 1),
      end: DateTime(y, m, 0),
    ),
    PDatePreset.last7Days => (start: addDays(t, -6), end: t),
    PDatePreset.last30Days => (start: addDays(t, -29), end: t),
    PDatePreset.last3Months => months(3),
    PDatePreset.last6Months => months(6),
    PDatePreset.last1Year => months(12),
    PDatePreset.thisYear => (start: DateTime(y), end: DateTime(y, 12, 31)),
  };
}

// ── 글 ───────────────────────────────────────────────────────

/// 달력의 글 한 벌 — 문자열은 호출하는 쪽이 넘긴다(앱 언어). [PDatePickerLabels.ko] 는 한국어 한 벌(카탈로그 · 테스트).
class PDatePickerLabels {
  const PDatePickerLabels({
    required this.root,
    required this.previousMonth,
    required this.nextMonth,
    required this.yearWheel,
    required this.monthWheel,
    required this.readOnlyRangeStart,
    required this.today,
    required this.presets,
    required this.weekdays,
    required this.weekdaysLong,
    required this.month,
    required this.day,
    required this.yearOption,
    required this.monthOption,
    required this.presetNames,
  });

  /// 달력 이름 — 칸 라벨이 없을 때("날짜 선택").
  final String root;
  final String previousMonth;
  final String nextMonth;

  /// 연 · 월 휠의 칼럼 이름.
  final String yearWheel;
  final String monthWheel;

  /// 읽기 전용 시작일 이름 끝에 붙는 말.
  final String readOnlyRangeStart;

  /// 오늘 날짜 이름 끝에 붙는 말 — "2026년 10월 15일 목요일, 오늘"(03C-004).
  final String today;

  /// 빠른 기간 칩 묶음 이름.
  final String presets;

  /// 보이는 요일(일요일부터 일곱) · 읽는 요일.
  final List<String> weekdays;
  final List<String> weekdaysLong;

  /// 달 제목 · 알림 — month 는 1 ~ 12.
  final String Function(int year, int month) month;

  /// 날짜 버튼 이름("2026년 10월 15일 목요일").
  final String Function(DateTime date) day;

  /// 연 · 월 휠 항목.
  final String Function(int year) yearOption;
  final String Function(int month) monthOption;
  final Map<PDatePreset, String> presetNames;

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const _weekdaysLong = [
    '일요일',
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
  ];

  /// 지금 로케일의 한 벌(arb `dsDate…` + 로케일 포맷터) — 로케일이 없는 호스트에서는 한국어([ko]).
  /// 요일 · 달 · 날짜 표기는 International v106 표를 따른다(ko "2026년 10월 15일 목요일" · en "Thursday, Oct 15, 2026").
  factory PDatePickerLabels.of(BuildContext context) {
    final l = dsL(context);
    if (l == null) return ko;
    final en = Localizations.localeOf(context).languageCode == 'en';
    final base = DateTime(2023, 12, 31); // 일요일
    final short = [
      for (var i = 0; i < 7; i++)
        en
            ? DateFormat.E('en').format(base.add(Duration(days: i)))
            : _weekdays[i],
    ];
    final long = [
      for (var i = 0; i < 7; i++)
        en
            ? DateFormat.EEEE('en').format(base.add(Duration(days: i)))
            : _weekdaysLong[i],
    ];
    return PDatePickerLabels(
      root: l.dsDateRoot,
      previousMonth: l.dsDatePrevMonth,
      nextMonth: l.dsDateNextMonth,
      yearWheel: l.dsDateYear,
      monthWheel: l.dsDateMonth,
      readOnlyRangeStart: l.dsDateReadOnlyStart,
      today: l.dsDateToday,
      presets: l.dsDatePresets,
      weekdays: short,
      weekdaysLong: long,
      month: (year, month) => en
          ? DateFormat.yMMM('en').format(DateTime(year, month))
          : '$year년 $month월',
      day: (d) => en
          ? DateFormat('EEEE, MMM d, y', 'en').format(d)
          : '${d.year}년 ${d.month}월 ${d.day}일 ${_weekdaysLong[weekdayIndex(d)]}',
      yearOption: (year) => en ? '$year' : '$year년',
      monthOption: (month) =>
          en ? DateFormat.MMM('en').format(DateTime(2000, month)) : '$month월',
      presetNames: {
        PDatePreset.thisWeek: l.dsDatePresetThisWeek,
        PDatePreset.thisMonth: l.dsDatePresetThisMonth,
        PDatePreset.lastMonth: l.dsDatePresetLastMonth,
        PDatePreset.last7Days: l.dsDatePresetLast7,
        PDatePreset.last30Days: l.dsDatePresetLast30,
        PDatePreset.last3Months: l.dsDatePresetLast3M,
        PDatePreset.last6Months: l.dsDatePresetLast6M,
        PDatePreset.last1Year: l.dsDatePresetLast1Y,
        PDatePreset.thisYear: l.dsDatePresetThisYear,
      },
    );
  }

  static final PDatePickerLabels ko = PDatePickerLabels(
    root: '날짜 선택',
    previousMonth: '이전 달',
    nextMonth: '다음 달',
    yearWheel: '연도',
    monthWheel: '월',
    readOnlyRangeStart: '읽기 전용 시작일',
    today: '오늘',
    presets: '빠른 기간',
    weekdays: _weekdays,
    weekdaysLong: _weekdaysLong,
    month: (year, month) => '$year년 $month월',
    day: (d) =>
        '${d.year}년 ${d.month}월 ${d.day}일 ${_weekdaysLong[weekdayIndex(d)]}',
    yearOption: (year) => '$year년',
    monthOption: (month) => '$month월',
    presetNames: const {
      PDatePreset.thisWeek: '이번 주',
      PDatePreset.thisMonth: '이번 달',
      PDatePreset.lastMonth: '지난 달',
      PDatePreset.last7Days: '최근 7일',
      PDatePreset.last30Days: '최근 30일',
      PDatePreset.last3Months: '최근 3개월',
      PDatePreset.last6Months: '최근 6개월',
      PDatePreset.last1Year: '최근 1년',
      PDatePreset.thisYear: '올해',
    },
  );
}

/// 칸에 넣는 하루 — 올해 "10월 15일 (목)", 다른 해 "2027년 1월 3일 (일)". 비었으면 "". [today] 는 올해를 가르는 오늘.
String formatDateValue(DateTime? date, DateTime today) {
  if (date == null) return '';
  if (localeIsEn()) {
    // en: "Thu, Oct 15" · 다른 해 "Sun, Jan 3, 2027" — 웹 i18n.test.ts 와 같은 꼴
    return date.year == today.year
        ? DateFormat('E, MMM d', 'en').format(date)
        : DateFormat('E, MMM d, y', 'en').format(date);
  }
  final text =
      '${date.month}월 ${date.day}일 (${PDatePickerLabels._weekdays[weekdayIndex(date)]})';
  return date.year == today.year ? text : '${date.year}년 $text';
}

/// 칸에 넣는 기간 — "10월 1일~10월 31일"(물결표를 앞뒤에 붙여 쓴다 — International Design). 올해가 아닌 날이 끼면
/// 양쪽에 연도("2026년 12월 28일~2027년 1월 3일"). 끝이 없으면 "".
String formatRangeValue(PDateRange? range, DateTime today) {
  final start = range?.start;
  final end = range?.end;
  if (start == null || end == null) return '';
  final withYear = start.year != today.year || end.year != today.year;
  if (localeIsEn()) {
    // en: 구간은 en dash — "Oct 1–Oct 31"
    String en(DateTime d) => withYear
        ? DateFormat.yMMMd('en').format(d)
        : DateFormat.MMMd('en').format(d);
    return '${en(start)}${rangeSeparator()}${en(end)}';
  }
  String text(DateTime d) =>
      '${withYear ? '${d.year}년 ' : ''}${d.month}월 ${d.day}일';
  return '${text(start)}${rangeSeparator()}${text(end)}';
}

/// 이어지는 달 스크롤에서 위치가 든 달 — 정렬된 위치 목록에서 이진 탐색.
int monthAt(List<double> offsets, List<double> heights, double offset) {
  var low = 0;
  var high = offsets.length - 1;
  while (low <= high) {
    final mid = (low + high) >> 1;
    final top = offsets[mid];
    if (offset < top) {
      high = mid - 1;
    } else if (offset >= top + heights[mid]) {
      low = mid + 1;
    } else {
      return mid;
    }
  }
  final last = offsets.isEmpty ? 0 : offsets.length - 1;
  return low.clamp(0, last);
}
