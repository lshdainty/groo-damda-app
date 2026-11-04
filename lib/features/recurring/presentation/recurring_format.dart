import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_schedule.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 반복 거래 표시 문구 — 목록 줄 · 상세 · 폼이 같은 문장을 쓴다(I-20 D 22 · 24 · 27, 웹 `recurring-format.ts` 와 같은 글).

/// 줄 · 상세 제목 — 거래처 → 메모 → 카테고리 → "반복 거래".
String recDisplayTitle(AppLocalizations l, RecurringTransaction it) {
  for (final s in [it.merchant, it.description, it.categoryName]) {
    if (s != null && s.isNotEmpty) return s;
  }
  return l.recDefaultTitle;
}

String _dowShort(AppLocalizations l, int uiDow) => switch (uiDow % 7) {
  0 => l.recDowShort0,
  1 => l.recDowShort1,
  2 => l.recDowShort2,
  3 => l.recDowShort3,
  4 => l.recDowShort4,
  5 => l.recDowShort5,
  _ => l.recDowShort6,
};

/// 요일 이름(0=일 ~ 6=토) — "일요일"
String recDowLong(AppLocalizations l, int uiDow) => switch (uiDow % 7) {
  0 => l.recDowLong0,
  1 => l.recDowLong1,
  2 => l.recDowLong2,
  3 => l.recDowLong3,
  4 => l.recDowLong4,
  5 => l.recDowLong5,
  _ => l.recDowLong6,
};

/// 주기 문장 — 줄 · 상세 · 폼이 같이 쓴다. 매일 · 매주 월요일 · 매월 25일 · 매년 10월 14일.
/// [dayOfWeek] 는 서버 ISO(1=월 ~ 7=일).
String recCycleSentence(
  AppLocalizations l, {
  required String frequency,
  int? dayOfWeek,
  int? dayOfMonth,
  required String startDate,
}) {
  switch (frequency) {
    case 'DAILY':
      return l.recCycleDaily;
    case 'WEEKLY':
      return l.recCycleWeekly(dayOfWeek == null ? '' : _dowShort(l, dayOfWeek));
    case 'MONTHLY':
      return l.recCycleMonthly(
        dayOfMonth ?? int.tryParse(startDate.substring(8, 10)) ?? 1,
      );
    default:
      return l.recCycleYearly(
        int.tryParse(startDate.substring(5, 7)) ?? 1,
        int.tryParse(startDate.substring(8, 10)) ?? 1,
      );
  }
}

String recCycleOf(AppLocalizations l, RecurringTransaction it) =>
    recCycleSentence(
      l,
      frequency: it.frequency,
      dayOfWeek: it.dayOfWeek,
      dayOfMonth: it.dayOfMonth,
      startDate: it.startDate ?? '1970-01-01',
    );

/// 끝 조각 — 횟수 "12번 중 3번"(먼저) · 끝 날짜 "2027년 12월까지". 없으면 null.
String? recEndPiece(AppLocalizations l, RecurringTransaction it) {
  if (it.maxOccurrences != null) {
    return l.recCountOf(it.maxOccurrences!, it.executedCount);
  }
  final e = it.endDate;
  if (e != null && e.length >= 7) {
    return l.recUntilMonth(
      int.tryParse(e.substring(0, 4)) ?? 0,
      int.tryParse(e.substring(5, 7)) ?? 0,
    );
  }
  return null;
}

/// 날짜 글 — 올해는 "10월 25일", 다른 해는 "2027년 1월 25일"(en "Oct 25" · "Jan 25, 2027").
String recDateText(DateTime d, {DateTime? now}) {
  final sameYear = d.year == (now ?? recurringNow()).year;
  if (localeIsEn()) {
    return sameYear
        ? DateFormat.MMMd('en').format(d)
        : DateFormat.yMMMd('en').format(d);
  }
  return sameYear
      ? '${d.month}월 ${d.day}일'
      : '${d.year}년 ${d.month}월 ${d.day}일';
}

String recDateKeyText(String key, {DateTime? now}) {
  final d = parseDayKey(key);
  return d == null ? key : recDateText(d, now: now);
}

/// 긴 날짜 — "2027년 10월 25일"(en "Oct 25, 2027"). 올해여도 연도를 붙인다.
String recDateLong(DateTime d) => localeIsEn()
    ? DateFormat.yMMMd('en').format(d)
    : '${d.year}년 ${d.month}월 ${d.day}일';

/// 'HH:mm(:ss)' → "오전 9시" · "오전 9:30"(en "9 AM" · "9:30 AM")
String recClockText(String hhmm) {
  final h = int.tryParse(hhmm.substring(0, 2)) ?? 9;
  final m = int.tryParse(hhmm.substring(3, 5)) ?? 0;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final mm = m.toString().padLeft(2, '0');
  if (localeIsEn()) {
    return m == 0
        ? '$h12 ${h < 12 ? 'AM' : 'PM'}'
        : '$h12:$mm ${h < 12 ? 'AM' : 'PM'}';
  }
  final half = h < 12 ? '오전' : '오후';
  return m == 0 ? '$half $h12시' : '$half $h12:$mm';
}

/// 줄 설명 조각 — 켜짐 "다음 10월 25일 · 매월 25일" · 쉬는 중 "쉬는 중 · …" · 끝남 "끝남 · …"(끝 조각이 있으면 이어 붙인다).
/// 항목 안 공백은 줄이 안 바뀌는 공백으로 — 줄이 모자라면 **항목 통째로** 다음 줄로 간다(말줄임 없음).
List<String> recRowDetailParts(AppLocalizations l, RecurringTransaction it) {
  final lead = isFinished(it)
      ? l.recRowFinished
      : it.isActive != 'Y'
      ? l.recRowPaused
      : l.recRowNext(recDateKeyText(it.nextExecutionDate ?? ''));
  final end = recEndPiece(l, it);
  return [lead, recCycleOf(l, it), ?end];
}

/// 줄 안에서 끊기지 않게 항목 안 공백을 줄이 안 바뀌는 공백(U+00A0)으로.
String recNoBreak(String s) => s.replaceAll(' ', ' ');

/// 금액 글 — 지출 "−" · 수입 "+" · 이체는 부호 없음. 원까지. 가림이 켜지면 점.
String recAmountText(RecurringTransaction it, {bool masked = false}) {
  final sign = it.expenseType == 'TRANSFER'
      ? ''
      : (it.expenseType == 'EXPENSE' ? kMinus : '+');
  return krwSigned(it.amount.abs(), masked, sign: sign, unit: true);
}

/// 금액 글 색 — 수입만 `fg-brand`, 지출 · 이체는 `fg-neutral`(빨강으로 칠하지 않는다).
Color recAmountColor(BuildContext context, RecurringTransaction it) =>
    it.expenseType == 'INCOME'
    ? context.colors.fgBrand
    : context.colors.fgNeutral;
