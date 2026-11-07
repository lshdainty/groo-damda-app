import 'package:flutter/foundation.dart';

import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/fixed_split.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

// 통계 화면의 기간 · 집계(웹 `stats-model.ts` · `stats-range.ts` 짝). 화면 부품은 이것을 받아 그리기만 한다.

/// 기간의 종류 — 월 · 분기 · 해 · 직접.
enum StatsSeg { month, quarter, year, custom }

/// 통계 탭 — 눌러서만 바뀐다(2차 탭은 밀어 넘기지 않는다 — Tabs 7A).
enum StatsTab { category, trend, compare, fixed }

String ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

typedef DateSpan = ({DateTime from, DateTime to});

DateSpan monthRangeOf(DateTime base) => (
  from: DateTime(base.year, base.month, 1),
  to: DateTime(base.year, base.month + 1, 0),
);

DateSpan quarterRangeOf(DateTime base) {
  final q = (base.month - 1) ~/ 3;
  return (
    from: DateTime(base.year, q * 3 + 1, 1),
    to: DateTime(base.year, q * 3 + 4, 0),
  );
}

DateSpan yearRangeOf(DateTime base) =>
    (from: DateTime(base.year, 1, 1), to: DateTime(base.year, 12, 31));

/// 통계가 보는 "지금" — 기간 이름("이번 달" ↔ 실제 이름)이 이 값으로 갈린다. 시험 · 렌더 하네스가 오늘을 고정한다(홈의 dashboardNow 와 같은 결).
DateTime Function() statsNow = DateTime.now;

/// 시트에서 고른 기간 → 통계 기간. 달력에는 월 · 분기 · 년 구분이 없으므로(칸 하나 · 달력 하나), 고른 기간이
/// 어떤 달력 달 · 분기 · 해 하나를 정확히 덮으면 그 보기(월 · 분기 · 년)로 두고 — 옛 탭이 ‹ › 로 지난 기간을 보던 것과 같다
/// (지난 달 → 그 달 월 보기, 이전 기간 비교는 그 전달) — 그 밖은 직접이다. 바뀐 게 없으면 지금 값을 그대로 돌려준다.
StatsPeriod statsPeriodOfRange(
  StatsPeriod current,
  DateTime from,
  DateTime to,
) {
  bool same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool covers(DateSpan s) => same(from, s.from) && same(to, s.to);
  if (same(from, current.from) && same(to, current.to)) return current;
  final seg = covers(monthRangeOf(from))
      ? StatsSeg.month
      : (from.month - 1) % 3 == 0 && covers(quarterRangeOf(from))
      ? StatsSeg.quarter
      : covers(yearRangeOf(from))
      ? StatsSeg.year
      : StatsSeg.custom;
  return StatsPeriod(
    seg: seg,
    from: DateTime(from.year, from.month, from.day),
    to: DateTime(to.year, to.month, to.day),
  );
}

/// 고른 기간 — 종류와 시작 · 끝.
@immutable
class StatsPeriod {
  const StatsPeriod({required this.seg, required this.from, required this.to});

  factory StatsPeriod.thisMonth([DateTime? now]) {
    final r = monthRangeOf(now ?? DateTime.now());
    return StatsPeriod(seg: StatsSeg.month, from: r.from, to: r.to);
  }

  final StatsSeg seg;
  final DateTime from;
  final DateTime to;

  StatsPeriod ofSeg(StatsSeg next, [DateTime? now]) {
    final base = now ?? DateTime.now();
    return switch (next) {
      StatsSeg.month => StatsPeriod(
        seg: next,
        from: monthRangeOf(base).from,
        to: monthRangeOf(base).to,
      ),
      StatsSeg.quarter => StatsPeriod(
        seg: next,
        from: quarterRangeOf(base).from,
        to: quarterRangeOf(base).to,
      ),
      StatsSeg.year => StatsPeriod(
        seg: next,
        from: yearRangeOf(base).from,
        to: yearRangeOf(base).to,
      ),
      // 직접 — 지금 시작 · 끝을 그대로 둔다
      StatsSeg.custom => StatsPeriod(seg: next, from: from, to: to),
    };
  }

  DateRange get range => (startDate: ymd(from), endDate: ymd(to));

  /// 이전 동등 기간.
  DateSpan get prev => switch (seg) {
    StatsSeg.month => (
      from: DateTime(from.year, from.month - 1, 1),
      to: DateTime(from.year, from.month, 0),
    ),
    StatsSeg.quarter => (
      from: DateTime(from.year, from.month - 3, 1),
      to: DateTime(from.year, from.month, 0),
    ),
    StatsSeg.year => (
      from: DateTime(from.year - 1, 1, 1),
      to: DateTime(from.year - 1, 12, 31),
    ),
    StatsSeg.custom => () {
      final days = to.difference(from).inDays + 1;
      final t = from.subtract(const Duration(days: 1));
      return (from: t.subtract(Duration(days: days - 1)), to: t);
    }(),
  };

  DateRange get prevRange => (startDate: ymd(prev.from), endDate: ymd(prev.to));

  /// 단일 월 또는 직접 기간이면 일평균, 그 외엔 월평균.
  bool get useDailyAvg => seg == StatsSeg.month || seg == StatsSeg.custom;

  /// 단일 월 또는 1개월 이내 직접 기간이면 추이를 일별로, 그 외엔 월별로.
  bool useDailyTrend(int monthlyBucketCount) =>
      seg == StatsSeg.month ||
      (seg == StatsSeg.custom && monthlyBucketCount <= 1);

  /// 다른 해에 걸친 직접 기간 — 버튼 글이 길어진다.
  bool get spansYears => seg == StatsSeg.custom && from.year != to.year;

  int get days => to.difference(from).inDays + 1;

  /// 기간 버튼 글 — 다른 해에 걸친 직접 기간은 "~" 뒤에서만 줄을 바꾼 두 줄("2025-01-01 ~ ⏎ 2026-03-31").
  String buttonLabel() => spansYears
      ? '${fullDate(from)}${rangeSeparator()}\n${fullDate(to)}'
      : label();

  String label() {
    switch (seg) {
      case StatsSeg.month:
        return yearMonth(from);
      case StatsSeg.quarter:
        final q = (from.month - 1) ~/ 3 + 1;
        return localeIsEn() ? 'Q$q ${from.year}' : '${from.year}년 $q분기';
      case StatsSeg.year:
        return yearOnly(from);
      case StatsSeg.custom:
        // 날짜 규칙 — 올해는 "10월 29일~11월 7일", 해가 섞이면 양끝 연도(앞 0 · 슬래시 표기 없음)
        return dateRange(from, to);
    }
  }

  /// 이 기간이 오늘을 품은 달 · 분기 · 해인가(직접은 아니다).
  bool containsToday([DateTime? today]) {
    if (seg == StatsSeg.custom) return false;
    final t = today ?? statsNow();
    final d = DateTime(t.year, t.month, t.day);
    return !d.isBefore(from) && !d.isAfter(to);
  }

  /// 기간 이름 — 오늘을 품은 달 · 분기 · 해는 상대 말("이번 달"), 지난 기간은 실제 이름("2026년 9월"), 직접은 "선택 기간".
  String now(AppLocalizations l, [DateTime? today]) {
    if (seg == StatsSeg.custom) return l.statsCustomPeriod;
    if (!containsToday(today)) return label();
    return switch (seg) {
      StatsSeg.month => l.expThisMonth,
      StatsSeg.quarter => l.statsThisQuarter,
      _ => l.statsThisYear,
    };
  }

  /// 이전 기간 이름 — [now] 와 같은 규칙(오늘을 품으면 "지난 달", 아니면 이전 기간의 실제 이름).
  String previous(AppLocalizations l, [DateTime? today]) {
    if (seg == StatsSeg.custom) return l.statsPrevPeriod;
    if (!containsToday(today)) {
      return StatsPeriod(seg: seg, from: prev.from, to: prev.to).label();
    }
    return switch (seg) {
      StatsSeg.month => l.statsLastMonth,
      StatsSeg.quarter => l.statsLastQuarter,
      _ => l.statsLastYear,
    };
  }

  String avgLabel(AppLocalizations l) =>
      useDailyAvg ? l.statsDailyAvg : l.statsMonthlyAvg;

  @override
  bool operator ==(Object other) =>
      other is StatsPeriod &&
      other.seg == seg &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(seg, from, to);
}

// ─── 추이 ──────────────────────────────────────────────────

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
  final String label;
  final int income;
  final int expense;
  int get savings => income - expense;
}

/// 일별 추이 — 기간의 하루하루에 (수입, 지출)을 모은다. 거래가 없는 날도 0 으로 선다.
///
/// 서버 집계와 같은 규칙(`countableTx`) — 아직 안 온 것·환불된 것·카드 이월은 세지
/// 않는다. 안 그러면 같은 화면의 저축률 위젯(서버 값)과 선 그래프가 어긋난다(23차 12 —
/// 이월이 카드를 등록한 날 지출로 솟았다).
List<({String label, int income, int expense})> dailyTrendOf(
  List<Expense> exps,
  DateTime from,
  DateTime to,
) {
  final fromDay = DateTime(from.year, from.month, from.day);
  final toDay = DateTime(to.year, to.month, to.day);
  final days = toDay.difference(fromDay).inDays + 1;
  final byDate = <String, ({int income, int expense, String label})>{};
  for (var i = 0; i < days; i++) {
    final d = fromDay.add(Duration(days: i));
    byDate[ymd(d)] = (income: 0, expense: 0, label: monthDayDot(d));
  }
  for (final e in countableTx(exps)) {
    final raw = e.expenseDate ?? '';
    if (raw.length < 10) continue;
    final key = raw.substring(0, 10);
    final cur = byDate[key];
    if (cur == null) continue;
    byDate[key] = e.expenseType == 'INCOME'
        ? (
            income: cur.income + e.amount,
            expense: cur.expense,
            label: cur.label,
          )
        : (
            income: cur.income,
            expense: cur.expense + e.amount,
            label: cur.label,
          );
  }
  return byDate.values.toList();
}

/// 지출 건수 — 합계와 같은 규칙으로 센다(`countableTx`). 환불한 거래·카드 이월은
/// 금액 합계에서 빠지는데 건수에만 남으면 "건당 평균" 이 틀린다(23차 12).
int statsExpenseCount(List<Expense> exps) =>
    countableTx(exps).where((x) => x.expenseType == 'EXPENSE').length;

/// 요일별 지출 합. index 0=월 .. 6=일 (DateTime.weekday 1=월~7=일).
///
/// 합계와 같은 규칙(`countableTx`) — 환불·카드 이월·아직 안 온 거래는 뺀다(23차 12).
List<int> statsWeekdaySums(List<Expense> exps) {
  final res = List<int>.filled(7, 0);
  for (final e in countableTx(exps)) {
    if (e.expenseType != 'EXPENSE') continue;
    final d = DateTime.tryParse(e.expenseDate ?? '');
    if (d == null) continue;
    res[d.weekday - 1] += e.amount;
  }
  return res;
}

/// 월 라벨 — [monthTicks](한 해 안이면 "1월", 해가 섞이면 점 표기 "2026. 1." · 영어 "Jan 2026").
List<String> monthLabels(List<({int year, int month})> rows) =>
    monthTicks(rows);

/// 추이 점 — 일별(단일 월 · 짧은 직접 기간) 또는 월별.
List<TrendPoint> trendPoints(
  StatsPeriod period,
  RangeSummary? summary,
  List<Expense> expenses,
) {
  final buckets = summary?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
  if (period.useDailyTrend(buckets.length)) {
    return [
      for (final v in dailyTrendOf(expenses, period.from, period.to))
        TrendPoint(label: v.label, income: v.income, expense: v.expense),
    ];
  }
  final labels = monthLabels([
    for (final b in buckets) (year: b.year, month: b.month),
  ]);
  return [
    for (final (i, b) in buckets.indexed)
      TrendPoint(
        label: labels[i],
        income: b.totalIncome,
        expense: b.totalExpense,
      ),
  ];
}

// ─── 도넛 ──────────────────────────────────────────────────

class DonutRow {
  DonutRow({
    required this.rowId,
    required this.name,
    required this.amount,
    this.color,
  });
  final int rowId;
  final String name;
  int amount;
  final String? color;
  bool hasChildren = false;
}

/// 부모 카테고리 단위로 묶은 도넛 줄 — 보기(전체 · 고정 제외 · 고정만)에 맞는 금액, 큰 순.
List<DonutRow> donutParents(
  List<CategoryBreakdown> bd,
  FixedView view,
  Map<int, ExpenseCategory> byId,
  String unassigned,
) {
  final map = <int, DonutRow>{};
  for (final c in bd) {
    if (c.expenseType != 'EXPENSE') continue;
    final groupId = c.parentCategoryRowId ?? c.categoryRowId;
    if (groupId == null) continue;
    final row = map.putIfAbsent(
      groupId,
      () => DonutRow(
        rowId: groupId,
        name: c.parentCategoryName ?? c.categoryName ?? unassigned,
        amount: 0,
        color: byId[groupId]?.color,
      ),
    );
    row.amount += amountFor(splitFixed(c.totalAmount, c.fixedAmount), view);
    if (c.parentCategoryRowId != null) row.hasChildren = true;
  }
  // 고정 제외·고정만 보기에서는 몫이 0 인 카테고리를 뺀다 — 0원 조각이 범례에 남으면 헷갈린다.
  return map.values.where((r) => view == FixedView.all || r.amount > 0).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

List<DonutRow> donutChildren(
  List<CategoryBreakdown> bd,
  int parentId,
  FixedView view,
  Map<int, ExpenseCategory> byId,
  String unassigned,
) {
  final map = <int, DonutRow>{};
  for (final c in bd) {
    if (c.expenseType != 'EXPENSE' || c.parentCategoryRowId != parentId) {
      continue;
    }
    final id = c.categoryRowId;
    if (id == null) continue;
    final row = map.putIfAbsent(
      id,
      () => DonutRow(
        rowId: id,
        name: c.categoryName ?? unassigned,
        amount: 0,
        color: byId[id]?.color,
      ),
    );
    row.amount += amountFor(splitFixed(c.totalAmount, c.fixedAmount), view);
  }
  return map.values.where((r) => view == FixedView.all || r.amount > 0).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

// ─── 열지도 ────────────────────────────────────────────────

/// 시간대 여섯 — 줄마다 네 시각.
const heatRowHours = [
  [6, 7, 8, 9],
  [10, 11, 12, 13],
  [14, 15, 16, 17],
  [18, 19, 20, 21],
  [22, 23, 0, 1],
  [2, 3, 4, 5],
];

/// 요일 일곱 — 월 → 일(서버 1 ~ 7).
const heatColDays = [1, 2, 3, 4, 5, 6, 7];

/// 줄 × 칸 합계 행렬(시간대 × 요일).
List<List<int>> heatMatrix(List<HeatmapCell> cells) {
  final m = List.generate(
    heatRowHours.length,
    (_) => List.filled(heatColDays.length, 0),
  );
  for (final c in cells) {
    final col = heatColDays.indexOf(c.dayOfWeek);
    final row = heatRowHours.indexWhere((r) => r.contains(c.hour));
    if (col < 0 || row < 0) continue;
    m[row][col] += c.totalAmount;
  }
  return m;
}

/// 시간대 구간 글 — 한국어 `06~10시`, 영어 `6–10 AM`.
String heatSub(int i) {
  final s = rangeSeparator();
  final en = [
    '6${s}10 AM',
    '10 AM${s}2 PM',
    '2${s}6 PM',
    '6${s}10 PM',
    '10 PM${s}2 AM',
    '2${s}6 AM',
  ];
  final ko = [
    '06${s}10시',
    '10${s}14시',
    '14${s}18시',
    '18${s}22시',
    '22${s}02시',
    '02${s}06시',
  ];
  return localeIsEn() ? en[i] : ko[i];
}

String heatRowLabel(AppLocalizations l, int i) => switch (i) {
  0 => l.statsTimeMorning,
  1 => l.statsTimeLunch,
  2 => l.statsTimeAfternoon,
  3 => l.statsTimeEvening,
  4 => l.statsTimeLateNight,
  _ => l.statsTimeDawn,
};

/// 문장 속 기간 이름 — 영어는 소문자("last month"), 한국어는 그대로("지난 달").
String periodInSentence(String name) =>
    localeIsEn() ? name.toLowerCase() : name;

/// "{기간}과 비슷해요" 의 앞 — 한국어는 받침에 따라 과 · 와("지난 달과" · "지난 분기와"), 영어는 그대로.
String periodWithJosa(String name) {
  if (localeIsEn() || name.isEmpty) return periodInSentence(name);
  final last = name.runes.last;
  final hasBatchim =
      last >= 0xAC00 && last <= 0xD7A3 && (last - 0xAC00) % 28 != 0;
  return '$name${hasBatchim ? '과' : '와'}';
}

/// 요일별 지출 비교에서 말할 요일 — 변화(이번 − 지난)의 절댓값이 가장 큰 요일(웹과 같은 규칙, 같으면 앞 요일). 모두 0 이면 -1.
({int index, int delta}) weekdayBiggestChange(List<int> now, List<int> prev) {
  var idx = -1;
  var best = 0;
  for (var i = 0; i < 7; i++) {
    final d = now[i] - prev[i];
    if (d.abs() > best.abs()) {
      best = d;
      idx = i;
    }
  }
  return (index: idx, delta: best);
}
