import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// porest-desk-front `formatDay(dStr)` 포팅 — "M월 D일" + "요일".
class DayLabel {
  const DayLabel({required this.md, required this.dow, required this.date});
  final String md;
  final String dow;
  final DateTime date;
}

const _dows = ['일', '월', '화', '수', '목', '금', '토'];

/// 올해가 아니면 연도를 붙인다 — 반복거래는 내년치를 미리 만들어 두는데, 연도가 없으면
/// 2027-01-01 이 그냥 "1월 1일" 로 보여 올해 것과 구분되지 않는다.
DayLabel formatDay(DateTime d) {
  final otherYear = d.year != DateTime.now().year;
  if (localeIsEn()) {
    // en: 로케일 스켈레톤 (Jul 15 · Mon). intl 내장 en 데이터 → init 불필요.
    return DayLabel(
      md: otherYear
          ? DateFormat.yMMMd('en').format(d)
          : DateFormat.MMMd('en').format(d),
      dow: DateFormat.E('en').format(d),
      date: d,
    );
  }
  // ko: 기존 수동 포맷 그대로 (회귀 0).
  return DayLabel(
    md: otherYear
        ? '${d.year}년 ${d.month}월 ${d.day}일'
        : '${d.month}월 ${d.day}일',
    dow: _dows[d.weekday % 7],
    date: d,
  );
}

/// porest-desk-front `formatMonthDay` 포팅 — ko "M월 D일" / en "Jan 25". **연도를 안 붙인다.**
///
/// 결제일처럼 문장 안에 드는 날짜에 쓴다. 문장은 웹과 한 글자도 같아야 하는데(문구는
/// 웹·앱 한 벌), [formatDay] 는 올해가 아니면 연도를 붙여(반복 거래 목록용) 12월에
/// "2027년 1월 25일에 결제돼요" 가 됐다 — 웹은 "1월 25일에 결제돼요"(QA 28 4).
String monthDay(DateTime d) =>
    localeIsEn() ? DateFormat.MMMd('en').format(d) : '${d.month}월 ${d.day}일';

/// porest-desk-front `formatMonthDayDow` 포팅 — ko "8월 3일 (월)" / en "Aug 3 (Mon)".
///
/// 올해가 아니면 [formatDay] 가 md 에 연도를 넣어 준다 → "2027년 1월 1일 (금)".
/// `'${x.md} (${x.dow})'` 인라인이 여러 화면에 흩어져 있어 한자리로 모은다.
String monthDayDow(DateTime d) {
  // 영어는 요일이 앞이다 — "Fri, Oct 16"(International v106: `E, MMM d`). 다른 해면 연도를 붙인다.
  if (localeIsEn()) {
    final otherYear = d.year != DateTime.now().year;
    return otherYear
        ? DateFormat('E, MMM d, y', 'en').format(d)
        : DateFormat('E, MMM d', 'en').format(d);
  }
  final x = formatDay(d);
  return '${x.md} (${x.dow})';
}

/// 구간 기호 — 로케일 문구(`dateRangeSeparator`): 한국어 "~", 영어 en dash "–". 앞뒤를 붙여 쓴다(DESIGN.desk.md:3652).
String _rangeSeparator() => lookupAppLocalizations(
  Locale(localeIsEn() ? 'en' : 'ko'),
).dateRangeSeparator;

/// 기간 줄 — ko "11월 2일~11월 8일" · en "Nov 2–8"(같은 달) / "Nov 2–Dec 1"(날짜 규칙: 올해 줄임, 0 채움 없음).
/// 둘 중 하나라도 올해가 아니면 두 끝 모두 연도를 붙인다(ko "2025년 12월 29일~2026년 1월 4일" · en "Dec 29, 2025–Jan 4, 2026").
String dateRange(DateTime from, DateTime to) {
  final sep = _rangeSeparator();
  final thisYear = DateTime.now().year;
  final crossYear = from.year != thisYear || to.year != thisYear;
  if (localeIsEn() && !crossYear && from.month == to.month) {
    // "Nov 2–8" — 같은 달은 뒤쪽 달 이름을 줄인다
    return '${monthDay(from)}$sep${to.day}';
  }
  final f = crossYear ? fullDate(from) : monthDay(from);
  final t = crossYear ? fullDate(to) : monthDay(to);
  return '$f$sep$t';
}

/// 월 눈금 글 — 한 해 안이면 ko "1월" · en "Jan"(앞 0 없음), 해가 섞이면 ko 점 표기 "2025. 12." · en "Dec 2025"
/// (점 표기는 한국어 전용, DESIGN.desk.md:3604). 통계 · 순자산 추이가 같이 쓴다.
List<String> monthTicks(List<({int year, int month})> rows) {
  final same = rows.isNotEmpty && rows.every((r) => r.year == rows.first.year);
  return [
    for (final r in rows)
      same
          ? monthOnly(DateTime(r.year, r.month))
          : yearMonthDot(DateTime(r.year, r.month)),
  ];
}

/// 좁은 칸(차트 눈금 · 표 · 목록 끝)의 월 · 일 — ko "10. 29."(점 표기, 앞 0 없음), en "Oct 29".
String monthDayDot(DateTime d) =>
    localeIsEn() ? DateFormat.MMMd('en').format(d) : '${d.month}. ${d.day}.';

/// 연 · 월 점 표기 — ko "2026. 1."(0 채움 없음), en "Jan 2026".
String yearMonthDot(DateTime d) =>
    localeIsEn() ? DateFormat.yMMM('en').format(d) : '${d.year}. ${d.month}.';

/// 시각 — 모든 화면에 오전 · 오후 12시간을 쓰고 초는 쓰지 않는다(International v106 · 01A-101):
/// ko "오후 3:07"(`a h:mm`), en "3:07 PM"(`h:mm a`). 서버로 보내는 "HH:mm" 값은 이것으로 만들지 않는다.
String timeOfDay12(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  if (localeIsEn()) return '$h12:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
  return '${d.hour < 12 ? '오전' : '오후'} $h12:$mm';
}

/// 연도가 붙은 전체 날짜 — ko "2010년 1월 4일" / en "Jan 4, 2010"(International v106). 상장일처럼 연도가 뜻인 값에 쓴다.
String fullDate(DateTime d) => localeIsEn()
    ? DateFormat.yMMMd('en').format(d)
    : '${d.year}년 ${d.month}월 ${d.day}일';

/// 서버 글("2010-01-04" · ISO)을 [fullDate] 로. 읽을 수 없으면 받은 글 그대로.
String fullDateOf(String raw) {
  final d = DateTime.tryParse(raw);
  return d == null ? raw : fullDate(d);
}

/// 'YYYY-MM-DD' 파싱 헬퍼.
DateTime parseIsoDate(String s) => DateTime.parse(s);

/// "YYYY년 M월" 헤더 포맷 (en: "Jul 2026"). ko 는 기존 수동 포맷 그대로.
String yearMonth(DateTime d) =>
    localeIsEn() ? DateFormat.yMMM('en').format(d) : '${d.year}년 ${d.month}월';

/// "YYYY년" (en: "2026"). ko 는 기존 수동 포맷 그대로.
String yearOnly(DateTime d) =>
    localeIsEn() ? DateFormat.y('en').format(d) : '${d.year}년';

/// "M월" (en: "Jul"). ko 는 기존 수동 포맷 그대로.
String monthOnly(DateTime d) =>
    localeIsEn() ? DateFormat.MMM('en').format(d) : '${d.month}월';

/// 요일 헤더 라벨 7개. ko 는 기존 수동 배열 그대로, en 은 DateFormat.E('en').
/// [mondayFirst] true → 월~일, false → 일~토. 인라인 요일 배열 통일용.
List<String> weekdayLabels({bool mondayFirst = false}) {
  if (localeIsEn()) {
    // 2024-01-01 = 월요일 · 2023-12-31 = 일요일 기준으로 7일 라벨 생성.
    final base = mondayFirst ? DateTime(2024, 1, 1) : DateTime(2023, 12, 31);
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E('en').format(base.add(Duration(days: i))),
    ];
  }
  return mondayFirst
      ? const ['월', '화', '수', '목', '금', '토', '일']
      : const ['일', '월', '화', '수', '목', '금', '토'];
}

/// 월간 첫 날.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// `Java LocalDateTime` 호환 ISO_LOCAL_DATE_TIME (`YYYY-MM-DDTHH:mm:ss`).
String toIsoLocal(DateTime d) {
  return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);
}

/// 서버가 준 `[UTC]` 시각을 기기 시간대의 [DateTime] 으로 바꾼다.
///
/// 백엔드는 `LocalDateTime` 을 시간대 없이 직렬화한다 — `2026-08-24T10:30:00`.
/// [DateTime.parse] 는 시간대 표시가 없으면 **로컬**로 읽으므로, 그대로 쓰면 UTC 값이
/// 로컬 시각으로 둔갑해 KST(+9)에서는 방금 일어난 일이 "9시간 전" 으로 보인다.
/// 그래서 UTC 로 못 박은 뒤 로컬로 옮긴다.
///
/// 이미 `Z` 나 오프셋이 붙어 오면 그대로 존중한다 — 서버가 나중에 형식을 바꿔도
/// 이 함수가 두 번 보정하지 않는다.
///
/// **입력은 시각이 있는 값(`LocalDateTime`) 전용이다.** 날짜만 있는 값
/// (`LocalDate` — `expenseDate`·`transferDate`·캘린더 `startDate` 처럼 사용자가 입력한
/// **벽시계 날짜**)은 받지 않고 null 을 돌려준다. 그런 값에는 시간대가 없다 —
/// 자정 UTC 로 읽어 로컬로 옮기면 UTC 뒤쪽 시간대(예: -05:00)에서 `2026-08-24` 가
/// `2026-08-23` 으로 하루 밀린다. KST(+9)에서는 09:00 이 되어 날짜가 그대로라
/// **개발 기기에서만 멀쩡해 보이고** 다른 시간대 사용자에게만 조용히 틀린다.
/// 날짜만 있는 값은 [parseIsoDate]/[DateTime.parse] 로 그대로 읽어야 한다.
DateTime? parseServerUtc(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  // 'YYYY-MM-DD' · 'YYYYMMDD' — Java LocalDate 직렬화 형태. 여기서 잘라 낸다.
  // 지금은 [DateTime.tryParse] 도 '2026-08-24Z' 를 거부해 결과가 같지만, 그건 Dart
  // 파서의 우연이다(V8 은 받아들여 웹이 자정 UTC 로 읽었다). 계약을 그 우연에
  // 맡겨 두면 이 함수를 "웹과 맞춘다" 며 관대하게 고치는 순간 조용히 열린다.
  if (_dateOnly.hasMatch(iso)) return null;
  final hasZone =
      iso.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(iso);
  final dt = DateTime.tryParse(hasZone ? iso : '${iso}Z');
  return dt?.toLocal();
}

/// 시각 없이 날짜만 있는 값(`LocalDate`). 확장·기본 ISO 형태를 모두 잡는다.
final _dateOnly = RegExp(r'^[+-]?\d{4,6}-?\d{2}-?\d{2}$');

/// 로컬 [DateTime] → 서버가 읽는 `[UTC]` ISO 문자열. [parseServerUtc] 의 역변환.
///
/// [parseServerUtc] 가 돌려주는 값은 `isUtc=false` 인 **로컬** DateTime 이다.
/// Dart 의 `toIso8601String()` 은 로컬이면 오프셋을 안 붙이므로, 그대로 직렬화하면
/// "오프셋 없는 로컬 벽시계" 가 나가고 그걸 다시 [parseServerUtc] 로 읽으면 UTC 로
/// 오해해 왕복마다 +9(KST) 씩 밀린다. 그래서 UTC 로 되돌린 뒤(`Z` 가 붙는다) 찍는다.
String? toServerUtc(DateTime? d) => d?.toUtc().toIso8601String();

/// 서버가 준 `[UTC]` 시각 → **로컬** 기준 `yyyy-MM-dd`. 못 읽으면 null.
///
/// 문자열을 `substring(0, 10)`·`startsWith` 로 자르면 UTC 날짜가 그대로 나온다 —
/// KST(+9) 새벽 0~9시에 일어난 일이 전날로 찍혀, [DateTime.now] 로 만든 로컬 '오늘' 이나
/// 로컬 달력으로 그린 요일 칸과 하루씩 어긋난다. 그래서 파싱해 로컬 달력으로 다시 조립한다.
///
/// 웹(porest-desk-front)의 `toLocalDateKey` 와 같은 규칙이다 — 규칙이 갈리면 같은 데이터를
/// 두고 "오늘 완료" 가 웹 1건 · 앱 0건으로 보인다.
///
/// **날짜만 있는 값(`LocalDate`)은 이 함수 대상이 아니다** — [parseServerUtc] 가
/// null 을 주므로 여기서도 null 이 나간다. 벽시계 날짜를 UTC 로 읽으면 시간대에 따라
/// 하루가 밀리는데, 그건 화면에 그럴듯한 날짜로 찍혀 아무도 못 잡는다.
/// 그런 값은 변환 없이 그대로 쓰면 된다(이미 로컬 벽시계다).
String? localDateKey(String? iso) {
  final dt = parseServerUtc(iso);
  if (dt == null) return null;
  final yyyy = dt.year.toString().padLeft(4, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}

/// 서버 `[UTC]` 시각 → 로컬 `yyyy-MM-dd HH:mm`. 못 읽으면 null.
///
/// [localDateKey] 와 같은 이유 — 자르면 UTC 벽시계가 그대로 화면에 나온다.
/// 웹 `toLocalDateTime` 과 같은 모양을 유지한다(로케일 포맷을 태우지 않는다).
///
/// [localDateKey] 와 마찬가지로 **날짜만 있는 값(`LocalDate`)은 대상이 아니다** — null.
String? localDateTime(String? iso) {
  final dt = parseServerUtc(iso);
  if (dt == null) return null;
  final yyyy = dt.year.toString().padLeft(4, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd $hh:$mi';
}

/// 메모 수정 시각(I-15 9) — 올해는 줄임 날짜 + 시각 "10월 22일 오후 5:10", 다른 해는 표준 날짜 "2025년 12월 3일"(웹 `formatMemoStamp` 와 한 벌).
///
/// 서버 `[UTC]` 시각을 파싱해 로컬로 옮긴 뒤 찍는다 — 문자열을 자르면 UTC 벽시계가 그대로 나와 KST(+9)에서 9시간 · 자정 근처엔 하루가 어긋난다.
/// 못 읽는 값은 빈 문자열이다(틀린 시각을 그리지 않는다 — 메타 줄이 빈 조각을 빼므로 끝에 " ·" 만 남지 않는다). [now] 는 시험용(올해를 고정한다).
String formatMemoStamp(String? iso, {DateTime? now}) {
  final dt = parseServerUtc(iso);
  if (dt == null) return '';
  if (dt.year != (now ?? DateTime.now()).year) return fullDate(dt);
  return '${monthDay(dt)} ${timeOfDay12(dt)}';
}
