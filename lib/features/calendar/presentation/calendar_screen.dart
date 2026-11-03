import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_visibility.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_day_sheet.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_filter_sheet.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_month_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/month_picker/p_month_picker.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused = calendarNow();

  MonthYM get _key => (year: _focused.year, month: _focused.month);

  void _moveMonth(int delta) => setState(
    () => _focused = DateTime(_focused.year, _focused.month + delta),
  );

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(userCalendarListProvider);
    final calendars = calendarsAsync.value ?? const <UserCalendar>[];
    final eventsAsync = ref.watch(monthEventsProvider(_key));
    // 표시를 끈 캘린더의 일정은 화면에서 뺀다 (웹 CalendarContainer 정합).
    // 그리드 칩·"+N개" 넘침 표시·날짜 시트가 모두 이 목록 하나를 보므로,
    // 여기서 한 번 거르면 "점은 있는데 눌러도 없는" 상태가 생기지 않는다.
    final events = visibleCalendarEvents(
      eventsAsync.value ?? const <CalendarEvent>[],
      calendars,
    );
    final holidayVisible = ref.watch(holidayVisibleProvider);
    // 표시 개수 = 활성 사용자 캘린더 + 활성 내장 소스(공휴일). 웹 CalendarSourceToggle
    // totalCount(visible 캘린더 + enabled builtin) 정합.
    final visibleCount =
        calendars.where((c) => c.isVisible).length + (holidayVisible ? 1 : 0);
    // 점도 표시 중인 캘린더만 — 웹 CalendarSourceToggle dotColors 정합
    // (`userCalendars.filter(c => c.isVisible).slice(0, 3)`).
    final dotColors = calendars
        .where((c) => c.isVisible)
        .take(3)
        .map((c) => chartToneOf(context, c.color).solid)
        .toList();

    final lastDay = DateTime(_key.year, _key.month + 1, 0).day;
    final hStart =
        '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-01';
    final hEnd =
        '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    final holidaysAsync = ref.watch(
      holidayListProvider((startDate: hStart, endDate: hEnd)),
    );
    // 기타 소스 > 공휴일 토글 off 면 빈 맵 → 달력에 공휴일 라벨/색 미표시.
    final holidayMap = holidayVisible
        ? <String, String>{
            for (final h in (holidaysAsync.value ?? const <Holiday>[]))
              h.holidayDate: h.holidayName,
          }
        : const <String, String>{};

    // 일정 질의가 실패하고 받아 둔 값도 없다 — 빈 격자가 아니라 실패 상자 하나(그 질의만 다시 받는다, I-09 12).
    // 공휴일 · 라벨 질의가 실패하면 상자를 두지 않고 그 없이 격자를 그린다.
    final eventsFailed = eventsAsync.hasError && !eventsAsync.hasValue;

    // 첫 로딩(이벤트/캘린더 아직 없음) — 웹 CalendarMonthViewSkeleton 정합.
    final firstLoading =
        (eventsAsync.isLoading && !eventsAsync.hasValue) ||
        (calendarsAsync.isLoading && !calendarsAsync.hasValue);

    // 띠 화면 — 달력 한 장이 머리 바로 아래부터 화면 폭 흰 면 하나다(02-005 / Q-019-3, I-05 74).
    // 달 줄 · 요일 줄 · 격자가 틈 0 으로 이어진다(조절하는 줄은 첫 내용과 한 덩어리, 10-23 기준).
    return ColoredBox(
      key: const ValueKey('calendar-band'),
      color: context.colors.bgLayerDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarMonthRow(
            month: _focused,
            onPick: _showMonthYearPicker,
            calendarCount: visibleCount,
            dotColors: dotColors,
            onFilterTap: _showFilterSheet,
          ),
          const CalendarWeekdayRow(),
          Expanded(
            // 좌우로 밀어 달을 옮긴다(예전 TableCalendar 페이지 넘김과 같은 손놀림)
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v.abs() < 300) return;
                _moveMonth(v < 0 ? 1 : -1);
              },
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (eventsFailed)
                      PResultSection(
                        kind: PResultKind.failure,
                        title: AppLocalizations.of(context).calEventsLoadFailed,
                        description: AppLocalizations.of(context).dashFailDesc,
                        primaryAction: PResultAction(
                          label: AppLocalizations.of(context).actionRetry,
                          onPressed: () =>
                              ref.invalidate(monthEventsProvider(_key)),
                        ),
                      )
                    else if (firstLoading)
                      _CalendarGridSkeleton(month: _focused)
                    else
                      CalendarMonthGrid(
                        month: _focused,
                        events: events,
                        holidays: holidayMap,
                        onDayTap: _openDayEventsSheet,
                      ),
                    // 플로팅 탭바 보상 — 마지막 주가 바 뒤로 가려지지 않게(셸 화면 공통). 틈이 아니다.
                    SizedBox(height: bottomNavigationInset(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthYearPicker() async {
    // 달 고르기(I-27) — 연 | 월 휠 + 완료. 고른 달의 1일로 옮긴다("오늘로" · 4×3 격자는 스펙에 없어 걷었다).
    final picked = await showPMonthPicker(
      context,
      initial: _focused,
      title: AppLocalizations.of(context).calDatePicker,
    );
    if (picked != null && mounted) setState(() => _focused = picked);
  }

  void _showFilterSheet() {
    showCalendarFilterSheet(
      context,
      onManage: () => context.push('/settings/calendar-share'),
    );
  }

  void _openDayEventsSheet(DateTime day) {
    // 그날 시트는 이 달의 일정 · 공휴일을 스스로 읽는다 — 시트 안에서 상세 · 수정 · 삭제가 일어나도 목록이 새 값을 따른다(I-09b 5)
    showCalendarDaySheet(
      context,
      day: day,
      monthKey: _key,
      onAdd: () => showCalendarEventDialog(context, defaultDate: day),
    );
  }
}

// ─── 첫 불러오기 skeleton ─────────────────────────────────────────────────────

/// 격자 자리의 첫 불러오기 — 칸 103 × 주 수, 날 숫자 원 자리와 칩 자리(18)만 ds Skeleton 으로 그린다.
/// 달 줄 · 요일 줄은 처음부터 그려져 있으므로 여기 없다(DESIGN.desk.md "달 이름은 바로, 숫자 · 목록 자리만 기다린다").
class _CalendarGridSkeleton extends StatelessWidget {
  const _CalendarGridSkeleton({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weeks = calendarGridDays(month).length ~/ 7;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCalendarGridInset),
      child: Column(
        children: [
          for (var w = 0; w < weeks; w++)
            SizedBox(
              height: kCalendarCellHeight,
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: c.strokeNeutralSubtle),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            kCalendarCellInset,
                            kCalendarCellTopPad,
                            kCalendarCellInset,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: PSkeleton(
                                  width: kCalendarDayCircle,
                                  height: kCalendarDayCircle,
                                  radius: PSkeletonRadius.full,
                                ),
                              ),
                              const SizedBox(height: kCalendarChipGap),
                              if ((w + d) % 3 == 0)
                                const PSkeleton(
                                  height: kCalendarChipHeight,
                                  radius: PSkeletonRadius.r4,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
