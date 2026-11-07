import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 일정 삭제 — 확인창(ds Alert Dialog) → 확정하면 [deleteCalendarEventRequest]. 실패하면 확인창을 닫고 critical 스낵바 +
/// [다시 시도](묻지 않고 바로 요청) — 공용 [askConfirmThenRequest]. 상세 [삭제] · 수정 폼 [삭제] 가 같은 길을 쓴다.
///
/// **반복 일정은 모든 회차가 함께 삭제된다고 말한다**: 서버는 일정 행 하나를 삭제하고 회차는 그 행에서 펼쳐지므로
/// 회차만 지우는 길이 없다.
///
/// 시트가 닫혀도 띠는 남으므로 요청 · 무효화 · 재조회는 [container] 로 한다(State · WidgetRef 에 기대지 않는다).
/// 돌려주는 값 — 요청까지 성공했으면 true(성공 뒷정리 중 화면 일은 부른 쪽 몫). 다시 시도가 성공하면 [onRetried] 가
/// 불린다 — 그때 시트가 닫혀 있을 수 있다.
Future<bool> askDeleteCalendarEvent(
  BuildContext context,
  ProviderContainer container,
  CalendarEvent event, {
  required VoidCallback onRetried,
}) {
  final l = AppLocalizations.of(context);
  return askConfirmThenRequest(
    context,
    title: l.calEventDelete,
    description: event.rrule == null
        ? l.calEventDeleteConfirm(event.title)
        : l.calEventDeleteConfirmRecurring(event.title),
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    request: () => deleteCalendarEventRequest(container, event),
    failedMessage: l.calFormDeleteFailed,
    retryLabel: l.actionRetry,
    onRetried: onRetried,
    kind: WriteKind.delete,
    // 응답을 못 받았다 — 지워졌을 수 있다. 지운 뒤와 같은 자리를 다시 받는다
    onUnconfirmed: () =>
        invalidateAfterCalendarEventDeleteIn(container.invalidate, event),
  );
}

/// 일정 삭제 요청 — **컨테이너로** 한다(시트를 닫은 뒤 스낵바의 [다시 시도] 도 이걸 부른다). 실패(`ApiException`)는 던진다.
/// 지운 뒤 다시 받을 것(달 · 홈 위젯)은 무효화하고, 이 일정의 시작 달은 [refetchCalendarMonthIn] 로 부른 쪽이 받는다.
/// 실패는 화면이 말한다(저장소가 `silent` 표식을 싣는다).
Future<void> deleteCalendarEventRequest(
  ProviderContainer container,
  CalendarEvent event,
) async {
  final repo = await container.read(calendarRepositoryProvider.future);
  await repo.deleteEvent(event.rowId);
  invalidateAfterCalendarEventDeleteIn(container.invalidate, event);
}

/// [key] 달을 다시 받는다 — 받지 못해도 흐름은 이어진다(실패 알림은 전역 길이 말한다).
Future<void> refetchCalendarMonthIn(
  ProviderContainer container,
  MonthYM key,
) async {
  try {
    await container.read(monthEventsProvider(key).future);
  } catch (_) {}
}

/// [start] ~ [end] 가 걸친 모든 달(둘 다 포함).
List<MonthYM> calendarMonthsSpanned(DateTime start, DateTime end) {
  final out = <MonthYM>[];
  var y = start.year, m = start.month;
  final last = end.isBefore(start) ? start : end;
  while (y < last.year || (y == last.year && m <= last.month)) {
    out.add((year: y, month: m));
    m++;
    if (m > 12) {
      m = 1;
      y++;
    }
  }
  return out;
}

/// 일정을 쓴(저장 · 삭제) 뒤 다시 받을 달 — **반복 일정이면 받아 둔 모든 달**(회차가 다른 달에도 있다), 아니면 일정이 걸친 모든 달
/// ([ranges] — 옛 날짜 · 새 날짜). 달을 걸친 일정을 뒤쪽 달에서 고치거나 지워도 그 달 키가 함께 비워진다.
void invalidateCalendarMonths(
  WidgetRef ref, {
  required bool recurring,
  required Iterable<(DateTime, DateTime)> ranges,
}) => invalidateCalendarMonthsIn(
  ref.invalidate,
  recurring: recurring,
  ranges: ranges,
);

/// [invalidateCalendarMonths] 의 컨테이너판 — `container.invalidate` 를 넘긴다(시트가 닫힌 뒤에도 쓴다).
void invalidateCalendarMonthsIn(
  void Function(ProviderOrFamily provider) invalidate, {
  required bool recurring,
  required Iterable<(DateTime, DateTime)> ranges,
}) {
  if (recurring) {
    invalidate(monthEventsProvider);
    return;
  }
  final seen = <MonthYM>{};
  for (final (s, e) in ranges) {
    for (final k in calendarMonthsSpanned(s, e)) {
      if (seen.add(k)) invalidate(monthEventsProvider(k));
    }
  }
}

/// 일정을 지운 뒤 다시 받을 것 — [invalidateCalendarMonths] + 홈 위젯(오늘 · 다가오는 일정)의 원본(셸 상주라 스스로 안 받는다).
void invalidateAfterCalendarEventDelete(WidgetRef ref, CalendarEvent event) =>
    invalidateAfterCalendarEventDeleteIn(ref.invalidate, event);

/// [invalidateAfterCalendarEventDelete] 의 컨테이너판.
void invalidateAfterCalendarEventDeleteIn(
  void Function(ProviderOrFamily provider) invalidate,
  CalendarEvent event,
) {
  invalidateCalendarMonthsIn(
    invalidate,
    recurring: event.rrule != null,
    ranges: [(event.start, event.end)],
  );
  invalidate(dashboardSummaryProvider);
}
