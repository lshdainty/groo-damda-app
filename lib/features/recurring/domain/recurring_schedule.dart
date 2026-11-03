import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';

/// 반복 회차 셈 — 목록 묶음 머리 합계 · 줄 · 상세의 "다음 예정일" · 폼 안내가 **한 벌**로 쓴다(I-20 D 22 · 29).
/// 서버 `RecurringTransactionServiceImpl` 의 `adjustToFrequency` · `firstOccurrenceOnOrAfter` · `calculateNextDate` 와 같은 규칙이다
/// (웹 `recurring-schedule.ts` 와 같은 함수 · 같은 결과): 시작일에서 주기대로, 매월은 말일을 넘기지 않고, 매년은 시작일의 월 · 일,
/// 격주 · 격월은 `intervalValue`. 끝 날짜를 넘는 날 · 최대 횟수를 넘는 차례는 회차가 아니다. '오늘'은 여기서 만들지 않는다 —
/// 부르는 쪽이 넘긴다(시험이 시계를 고정할 수 있게).
/// 지금 — 목록 합 · 폼 처음 날짜 · 줄 날짜 글이 같은 시계를 본다. 시험 · 렌더 하네스가 시계를 고정할 때만 바꾼다.
DateTime Function() recurringNow = DateTime.now;

class ScheduleRule {
  const ScheduleRule({
    required this.startDate,
    required this.frequency,
    this.intervalValue,
    this.dayOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.maxOccurrences,
  });

  /// 'YYYY-MM-DD'
  final String startDate;

  /// 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY'
  final String frequency;
  final int? intervalValue;

  /// 서버 ISO 1=월 ~ 7=일
  final int? dayOfWeek;
  final int? dayOfMonth;
  final String? endDate;
  final int? maxOccurrences;

  factory ScheduleRule.of(RecurringTransaction r) => ScheduleRule(
    startDate: r.startDate ?? '',
    frequency: r.frequency,
    intervalValue: r.intervalValue,
    dayOfWeek: r.dayOfWeek,
    dayOfMonth: r.dayOfMonth,
    endDate: r.endDate,
    maxOccurrences: r.maxOccurrences,
  );
}

const int _maxSteps = 100000;

/// 'YYYY-MM-DD' → 그 날 0시(해석할 수 없으면 null)
DateTime? parseDayKey(String? key) {
  if (key == null || key.length < 10) return null;
  final y = int.tryParse(key.substring(0, 4));
  final m = int.tryParse(key.substring(5, 7));
  final d = int.tryParse(key.substring(8, 10));
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// 날짜 → 'YYYY-MM-DD'
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int _lengthOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Java `plusMonths` — 말일을 넘으면 그 달 말일로
DateTime _plusMonths(DateTime d, int n) {
  final total = d.year * 12 + (d.month - 1) + n;
  final y = total ~/ 12;
  final m = total % 12 + 1;
  return DateTime(
    y,
    m,
    d.day < _lengthOfMonth(y, m) ? d.day : _lengthOfMonth(y, m),
  );
}

DateTime _plusDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

int _min(int a, int b) => a < b ? a : b;

/// 서버 `adjustToFrequency` — 시작일을 주기에 맞는 첫 회차로
DateTime? firstOccurrence(ScheduleRule rule) {
  final start = parseDayKey(rule.startDate);
  if (start == null) return null;
  if (rule.frequency == 'WEEKLY' && rule.dayOfWeek != null) {
    // Dart weekday: 월 1 ~ 일 7 — 서버 ISO 와 같다
    var diff = rule.dayOfWeek! - start.weekday;
    if (diff < 0) diff += 7;
    return _plusDays(start, diff);
  }
  if (rule.frequency == 'MONTHLY' && rule.dayOfMonth != null) {
    var adj = DateTime(
      start.year,
      start.month,
      _min(rule.dayOfMonth!, _lengthOfMonth(start.year, start.month)),
    );
    if (adj.isBefore(start)) {
      adj = _plusMonths(DateTime(adj.year, adj.month, 1), 1);
      adj = DateTime(
        adj.year,
        adj.month,
        _min(rule.dayOfMonth!, _lengthOfMonth(adj.year, adj.month)),
      );
    }
    return adj;
  }
  return start;
}

/// 서버 `calculateNextDate` — 다음 회차
DateTime stepOccurrence(DateTime cur, ScheduleRule rule) {
  final interval = (rule.intervalValue ?? 0) > 0 ? rule.intervalValue! : 1;
  switch (rule.frequency) {
    case 'DAILY':
      return _plusDays(cur, interval);
    case 'WEEKLY':
      return _plusDays(cur, 7 * interval);
    case 'MONTHLY':
      final next = _plusMonths(cur, interval);
      if (rule.dayOfMonth == null) return next;
      return DateTime(
        next.year,
        next.month,
        _min(rule.dayOfMonth!, _lengthOfMonth(next.year, next.month)),
      );
    default: // YEARLY
      return _plusMonths(cur, 12 * interval);
  }
}

String? _endKey(ScheduleRule rule) {
  final e = rule.endDate;
  return e == null || e.length < 10 ? null : e.substring(0, 10);
}

/// 규칙의 회차 날짜 키들 — [from] ~ [to](둘 다 포함, 'YYYY-MM-DD') 안에 있는 것만. 최대 횟수는 첫 회차부터 센 차례로
/// 따진다(이미 기록된 회차도 한 차례다). 끝 날짜 뒤 · 최대 횟수 밖은 뺀다.
List<String> occurrencesBetween(ScheduleRule rule, String from, String to) {
  var cur = firstOccurrence(rule);
  if (cur == null) return const [];
  final out = <String>[];
  final max = rule.maxOccurrences;
  final end = _endKey(rule);
  for (var n = 1, steps = 0; steps < _maxSteps; n++, steps++) {
    final key = dayKey(cur!);
    if (key.compareTo(to) > 0) break;
    if (end != null && key.compareTo(end) > 0) break;
    if (max != null && n > max) break;
    if (key.compareTo(from) >= 0) out.add(key);
    cur = stepOccurrence(cur, rule);
  }
  return out;
}

/// 다음 예정일 [count] 개 — 서버가 준 `nextExecutionDate` 에서 센다(상세 · 줄). 끝 날짜를 넘는 날 · 남은 횟수(최대 − 실행)를
/// 넘는 날은 뺀다. 쉬는 중이면 빈 목록.
List<String> upcomingDates(
  ScheduleRule rule,
  String nextKey,
  int executedCount,
  int count, {
  bool active = true,
}) {
  if (!active) return const [];
  var cur = parseDayKey(nextKey);
  if (cur == null) return const [];
  final out = <String>[];
  final remaining = rule.maxOccurrences != null
      ? rule.maxOccurrences! - executedCount
      : 1 << 30;
  final end = _endKey(rule);
  for (var i = 0; i < count && i < remaining; i++) {
    final key = dayKey(cur!);
    if (end != null && key.compareTo(end) > 0) break;
    out.add(key);
    cur = stepOccurrence(cur, rule);
  }
  return out;
}

/// 폼 안내 — 시작일에서 센 첫 회차들(끝 · 횟수 안). 지금 폼 값으로. [dayOfWeekUi] 0=일 ~ 6=토.
/// 서버 규칙(시작일이 매월 날보다 뒤면 다음 달)과 같다 — 옛 계산은 시작일 앞 날을 첫 회차로 보였다.
List<String> previewNextDateKeys(
  String startIso,
  String frequency,
  int dayOfWeekUi,
  int dayOfMonth,
  int count, {
  String? endDate,
  int? maxOccurrences,
  int intervalValue = 1,
  DateTime? today,
}) {
  final rule = ScheduleRule(
    startDate: startIso,
    frequency: frequency,
    intervalValue: intervalValue,
    dayOfWeek: dayOfWeekUi == 0 ? 7 : dayOfWeekUi,
    dayOfMonth: frequency == 'MONTHLY' ? dayOfMonth : null,
    endDate: endDate,
    maxOccurrences: maxOccurrences,
  );
  var cur = firstOccurrence(rule);
  if (cur == null) return const [];
  // 서버는 오늘 이후 첫 회차(firstOccurrenceOnOrAfter)부터 만든다 — 지난 회차를 채우지 않는다
  if (today != null) {
    final t = DateTime(today.year, today.month, today.day);
    for (var i = 0; cur!.isBefore(t) && i < _maxSteps * 4; i++) {
      cur = stepOccurrence(cur, rule);
    }
  }
  final out = <String>[];
  final end = _endKey(rule);
  for (var n = 1; out.length < count && n <= _maxSteps; n++) {
    final key = dayKey(cur!);
    if (end != null && key.compareTo(end) > 0) break;
    if (maxOccurrences != null && n > maxOccurrences) break;
    out.add(key);
    cur = stepOccurrence(cur, rule);
  }
  return out;
}

/// 끝남 — 실행 수가 최대 횟수에 닿았거나 다음 날짜가 끝 날짜 뒤다. isActive 와 상관없다 — 서버 markExecuted 가
/// 횟수를 채우면 isActive 를 N 으로 바꾸므로 끝난 반복은 N 이 정상 상태다.
bool isFinished(RecurringTransaction it) {
  if (it.maxOccurrences != null && it.executedCount >= it.maxOccurrences!) {
    return true;
  }
  final end = it.endDate;
  final next = it.nextExecutionDate;
  if (end != null && end.length >= 10 && next != null && next.length >= 10) {
    if (next.substring(0, 10).compareTo(end.substring(0, 10)) > 0) return true;
  }
  return false;
}

/// 쉬는 중 — 꺼져 있고(isActive N) 끝나지 않았다.
bool isPausedRec(RecurringTransaction it) =>
    it.isActive != 'Y' && !isFinished(it);

/// 이번 달 합 — 켜진 반복의 이 달(1일 ~ 말일) 회차 금액을 모두 더한다. 이미 기록된 회차도 포함(규칙으로 센다).
/// 쉬는 반복은 뺀다. [type] 은 'EXPENSE' | 'INCOME'.
int monthTotal(
  Iterable<RecurringTransaction> items,
  String type,
  int year,
  int month,
) {
  final mm = month.toString().padLeft(2, '0');
  final from = '$year-$mm-01';
  final to =
      '$year-$mm-${_lengthOfMonth(year, month).toString().padLeft(2, '0')}';
  var sum = 0;
  for (final it in items) {
    if (isPausedRec(it) || it.expenseType != type) continue;
    final n = occurrencesBetween(ScheduleRule.of(it), from, to).length;
    sum += it.amount.abs() * n;
  }
  return sum;
}
