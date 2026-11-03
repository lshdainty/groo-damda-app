import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event_detail_rules.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_visibility.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_actions.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_detail_body.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_text.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_grid.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_tone.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 날을 누르면 뜨는 그날 시트(I-09 11) — ds Bottom Sheet. 제목 "10월 22일 (목)", 본문은 일정 줄 목록(공휴일 먼저, 그다음 시작 시각
/// 차례), 바닥 "일정 추가" 폭 전체. 높이는 내용만큼 · 90% 상한.
///
/// **일정 줄을 누르면 같은 시트가 상세로 바뀐다**(I-09b 5 · 1-A) — 머리 ← · "일정 상세" · 닫기. ← · 뒤로 가기 = 그날 목록,
/// 닫기 · 바깥 · 끌기 = 시트 전체. 상세의 [수정] 은 같은 시트가 수정 폼으로 바뀐다(9) — 시트를 닫았다 다시 열지 않는다.
/// 목록 · 상세는 조회라 바깥 · 끌기로 닫히고, 수정 폼은 입력이라 닫히지 않는다(단계마다 규칙이 바뀐다).
Future<void> showCalendarDaySheet(
  BuildContext context, {
  required DateTime day,
  required MonthYM monthKey,
  required VoidCallback onAdd,
}) {
  final l = AppLocalizations.of(context);
  final hooks = _DayFlowHooks();
  return PBottomSheet.show<void>(
    context,
    isForm: () => hooks.isForm(),
    isDirty: () => hooks.isDirty(),
    interceptClose: () => hooks.interceptClose(),
    leaveCopy: _leaveCopy(l),
    builder: (_) => _CalendarDayFlow(
      day: day,
      monthKey: monthKey,
      onAdd: onAdd,
      hooks: hooks,
    ),
  );
}

PLeaveConfirmCopy _leaveCopy(AppLocalizations l) => PLeaveConfirmCopy(
  title: l.sheetLeaveTitle,
  description: l.sheetLeaveDescription,
  stayLabel: l.sheetLeaveStay,
  leaveLabel: l.sheetLeaveLeave,
);

/// 시트의 닫는 길이 그 순간의 단계를 묻는 자리 — 단계의 주인은 [_CalendarDayFlowState] 라 시트 밖에서 이 줄로 닿는다.
class _DayFlowHooks {
  bool Function() isForm = () => false;
  bool Function() isDirty = () => false;
  bool Function() interceptClose = () => false;
}

enum _DayStep { list, detail, edit }

class _CalendarDayFlow extends ConsumerStatefulWidget {
  const _CalendarDayFlow({
    required this.day,
    required this.monthKey,
    required this.onAdd,
    required this.hooks,
  });

  final DateTime day;
  final MonthYM monthKey;
  final VoidCallback onAdd;
  final _DayFlowHooks hooks;

  @override
  ConsumerState<_CalendarDayFlow> createState() => _CalendarDayFlowState();
}

class _CalendarDayFlowState extends ConsumerState<_CalendarDayFlow> {
  _DayStep _step = _DayStep.list;

  /// 연 일정 — 목록에서 (`rowId`, 연 회차의 시작 날)로 다시 찾는다(반복이 아니면 `rowId` 만). 서버가 새 값을 주면 상세가 새 값으로 바뀐다.
  int? _openRowId;
  String? _openDay;

  /// 상세에서 [삭제] 가 실패했다 — 상세 본문 맨 위 Callout 으로 알린다(전역 스낵바는 시트 뒤에 가려진다).

  /// 목록 단계를 떠날 때 보던 스크롤 · 연 줄 — 돌아오면 그대로(I-09b 5).
  double _listOffset = 0;
  final Map<int, FocusNode> _rowFocus = {};

  final CalendarFormProbe _probe = CalendarFormProbe();
  bool _busy = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hooks;
    h.isForm = () => mounted && _step == _DayStep.edit;
    h.isDirty = () => mounted && _step == _DayStep.edit && _probe.dirty();
    h.interceptClose = _intercept;
  }

  @override
  void dispose() {
    final h = widget.hooks;
    h.isForm = () => false;
    h.isDirty = () => false;
    h.interceptClose = () => false;
    for (final n in _rowFocus.values) {
      n.dispose();
    }
    _probe.titleFocus.dispose();
    super.dispose();
  }

  // ── 단계 ────────────────────────────────────────────────
  ScrollController get _body => PBottomSheet.of(context).bodyController;

  void _openDetail(CalendarEvent e) {
    final body = _body;
    _listOffset = body.hasClients ? body.offset : 0;
    setState(() {
      _openRowId = e.rowId;
      _openDay = calendarDateKey(e.start);
      _step = _DayStep.detail;
    });
  }

  /// 목록 단계로 — 보던 스크롤 그대로, 초점은 연 줄로.
  void _goList() {
    final opened = _openRowId;
    setState(() {
      _step = _DayStep.list;
      _openRowId = null;
      _openDay = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _step != _DayStep.list) return;
      final body = _body;
      if (body.hasClients) {
        body.jumpTo(_listOffset.clamp(0.0, body.position.maxScrollExtent));
      }
      if (opened != null) _rowFocus[opened]?.requestFocus();
    });
  }

  void _goDetail() => setState(() => _step = _DayStep.detail);

  void _openEdit() => setState(() => _step = _DayStep.edit);

  /// 뒤로 가기 · `Esc` 한 번 = 한 단계 뒤(상세 → 목록, 수정 → 상세). 시트의 닫는 길이 먼저 묻는다.
  bool _intercept() {
    if (!mounted) return false;
    switch (_step) {
      case _DayStep.list:
        return false;
      case _DayStep.detail:
        _goList();
        return true;
      case _DayStep.edit:
        // 장소 · 설명 안 단계가 열려 있으면 그 단계만 닫는다
        if (_probe.interceptClose()) return true;
        _leaveEdit();
        return true;
    }
  }

  /// 수정 폼 → 상세. 바뀐 값이 있으면 먼저 "작성한 내용이 사라져요".
  Future<void> _leaveEdit() async {
    if (_leaving) return;
    if (!_probe.dirty()) {
      _goDetail();
      return;
    }
    _leaving = true;
    final leave = await PAlertDialog.confirmLeave(
      context,
      _leaveCopy(AppLocalizations.of(context)),
    );
    _leaving = false;
    if (leave && mounted) _goDetail();
  }

  /// 저장 · 삭제 뒤 — 쓰는 쪽이 일정이 걸친 모든 달(반복이면 받아 둔 모든 달)을 비웠으므로 이 달을 새로 받은 다음에 단계를 옮긴다
  /// (받기 전에 옮기면 옛 값이 잠깐 비친다).
  Future<void> _refreshMonth() async {
    try {
      await ref.read(monthEventsProvider(widget.monthKey).future);
    } catch (_) {
      // 받지 못해도 단계는 옮긴다 — 실패 알림은 전역 길이 말한다
    }
  }

  Future<void> _afterSaved(DateTime savedStart) async {
    await _refreshMonth();
    if (!mounted) return;
    // 반복 일정은 저장한 시작일로 다시 찾는다 — 회차를 다른 날로 옮겼으면 이 날 목록에 없어 목록 단계로 수렴한다
    _openDay = calendarDateKey(savedStart);
    // 상세는 목록에서 다시 찾는다 — 날짜를 옮겨 이 날에 없으면 build 가 목록 단계로 돌린다
    _goDetail();
  }

  Future<void> _afterFormDelete() async {
    await _refreshMonth();
    if (mounted) _goList();
  }

  /// 삭제 — 확인창 · 요청 · 실패 스낵바 + [다시 시도] 는 공용 [askDeleteCalendarEvent]. 시트를 닫아도 띠가 남고 [다시 시도] 가
  /// 동작하도록 요청 · 무효화 · 재조회는 컨테이너로 한다.
  Future<void> _delete(CalendarEvent e) async {
    if (_busy) return;
    final container = ProviderScope.containerOf(context);
    final key = widget.monthKey;
    final ok = await askDeleteCalendarEvent(
      context,
      container,
      e,
      onRetried: () => unawaited(_afterRetried(container, key)),
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await _refreshMonth();
      if (!mounted) return;
      _goList();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 확인창 실패 뒤 [다시 시도] 가 성공했을 때 — 달을 다시 받고, 시트가 아직 열려 있으면 목록으로.
  Future<void> _afterRetried(ProviderContainer container, MonthYM key) async {
    await refetchCalendarMonthIn(container, key);
    if (mounted) _goList();
  }

  // ── 그리기 ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final calendarsAsync = ref.watch(userCalendarListProvider);
    final calendars = calendarsAsync.value ?? const <UserCalendar>[];
    final all =
        ref.watch(monthEventsProvider(widget.monthKey)).value ??
        const <CalendarEvent>[];
    // 그리드와 같은 규칙 — 표시를 끈 캘린더의 일정은 시트에도 올리지 않는다
    final events = eventsOnDay(
      visibleCalendarEvents(all, calendars),
      widget.day,
    );
    final opened = _openRowId == null
        ? null
        : events
              .where(
                (e) =>
                    e.rowId == _openRowId &&
                    (e.rrule == null || calendarDateKey(e.start) == _openDay),
              )
              .firstOrNull;
    if (_step != _DayStep.list && opened == null) {
      // 지워졌거나 날짜를 옮겨 이 날에 없다 — 그날 목록 단계로
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step != _DayStep.list && _busy == false) _goList();
      });
    }

    if (_step == _DayStep.edit && opened != null) {
      return CalendarEventFormSheet(
        edit: opened,
        probe: _probe,
        onBack: _leaveEdit,
        onSaved: _afterSaved,
        onDeleted: _afterFormDelete,
      );
    }
    if (_step == _DayStep.detail && opened != null) {
      return _buildDetail(l, opened, calendarsAsync);
    }
    return _buildList(l, events, calendars);
  }

  Widget _buildList(
    AppLocalizations l,
    List<CalendarEvent> events,
    List<UserCalendar> calendars,
  ) {
    final title = monthDayDow(widget.day);
    return PBottomSheetContent(
      // 단계마다 다른 시트 내용이다 — 키가 없으면 같은 위젯으로 보고 스크롤 위치가 다음 단계에 따라온다
      key: const ValueKey('calendar-day-list'),
      title: title,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: CalendarDaySheetBody(
        title: title,
        events: events,
        holidays: _holidays(),
        calendars: calendars,
        focusNodeOf: (e) => _rowFocus.putIfAbsent(e.rowId, FocusNode.new),
        onTapEvent: _openDetail,
      ),
      footer: [
        PButton(
          label: l.calEventAdd,
          size: PButtonSize.large,
          onPressed: () {
            PBottomSheet.of(context).close();
            widget.onAdd();
          },
        ),
      ],
    );
  }

  /// 그날의 공휴일 — 그리드와 같이 holidayVisible 게이트 + 월 범위에서 그날만.
  List<Holiday> _holidays() {
    if (!ref.watch(holidayVisibleProvider)) return const <Holiday>[];
    final key = widget.monthKey;
    final lastDay = DateTime(key.year, key.month + 1, 0).day;
    String ym(int d) =>
        '${key.year.toString().padLeft(4, '0')}-${key.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final dayKey = calendarDateKey(widget.day);
    return (ref
                .watch(
                  holidayListProvider((startDate: ym(1), endDate: ym(lastDay))),
                )
                .value ??
            const <Holiday>[])
        .where((h) => h.holidayDate == dayKey)
        .toList();
  }

  Widget _buildDetail(
    AppLocalizations l,
    CalendarEvent e,
    AsyncValue<List<UserCalendar>> calendarsAsync,
  ) {
    final canEdit = canEditCalendarEvent(
      event: e,
      myUserRowId: ref.watch(authProvider).value?.rowId,
      calendars: calendarsAsync.value,
    );
    return PBottomSheetContent(
      key: const ValueKey('calendar-day-detail'),
      title: l.calEventDetailTitle,
      closeLabel: l.actionClose,
      // 닫기 원은 한 단계가 아니라 시트 전체(← · 뒤로 가기가 한 단계)
      onClose: () => PBottomSheet.of(context).requestClose(wholeSheet: true),
      onBack: _goList,
      backLabel: l.actionBack,
      flushBody: true,
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarEventDetailBody(
            event: e,
            calendars: calendarsAsync.value ?? const <UserCalendar>[],
            today: calendarNow(),
          ),
        ],
      ),
      // 버튼이 없으면 바닥 자체를 두지 않는다(읽기 전용 · 권한을 모르는 남의 일정)
      footer: canEdit
          ? [
              PButton(
                label: l.actionDelete,
                variant: PButtonVariant.ghost,
                ghostColor: PButtonGhostColor.critical,
                size: PButtonSize.large,
                loading: _busy,
                onPressed: _busy ? null : () => _delete(e),
              ),
              PButton(
                label: l.actionEdit,
                size: PButtonSize.large,
                onPressed: _busy ? null : _openEdit,
              ),
            ]
          : const [],
    );
  }
}

/// 그날 시트 본문 — 일정 줄 목록. 줄 사이 선 없음 · 꺾쇠 없음(상세를 여는 줄).
class CalendarDaySheetBody extends StatelessWidget {
  const CalendarDaySheetBody({
    super.key,
    required this.title,
    required this.events,
    required this.holidays,
    required this.calendars,
    required this.onTapEvent,
    this.focusNodeOf,
  });

  /// 줄의 초점 — 상세에서 돌아오면 연 줄로 돌려놓는다(I-09b 5).
  final FocusNode? Function(CalendarEvent)? focusNodeOf;

  /// 목록의 이름 — 시트 제목과 같은 글.
  final String title;
  final List<CalendarEvent> events;
  final List<Holiday> holidays;
  final List<UserCalendar> calendars;
  final ValueChanged<CalendarEvent> onTapEvent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (events.isEmpty && holidays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpacing.x6,
          vertical: PSpacing.x8,
        ),
        child: Text(
          keepAll(l.calNoEventsThisDay),
          textAlign: TextAlign.center,
          style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
        ),
      );
    }
    final red = holidayTone(context);
    return PList(
      semanticLabel: title,
      children: [
        // 공휴일(종일) 먼저 — 보기만 하는 줄
        for (final h in holidays)
          PListItem(
            title: h.holidayName,
            detail: l.calHolidays,
            prefix: ExcludeSemantics(
              child: PListTile(
                background: red.weak,
                color: red.solid,
                child: const Icon(LucideIcons.flag),
              ),
            ),
          ),
        for (final e in events)
          _EventRow(
            event: e,
            calendars: calendars,
            focusNode: focusNodeOf?.call(e),
            onTap: () => onTapEvent(e),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.calendars,
    required this.onTap,
    this.focusNode,
  });

  final CalendarEvent event;
  final List<UserCalendar> calendars;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tone = eventTone(context, event);
    final calName = event.calendarRowId == null
        ? null
        : calendars
              .where((c) => c.rowId == event.calendarRowId)
              .firstOrNull
              ?.calendarName;
    // "{시각} · {캘린더} · {라벨} · {반복}" — 없는 조각은 뺀다
    final detail = [
      eventTimeText(l, event),
      ?calName,
      ?event.labelName,
      ?eventRepeatLabel(l, event.rrule),
    ].where((s) => s.isNotEmpty).join(' · ');
    return PListButtonItem(
      title: event.title,
      detail: detail,
      prefix: ExcludeSemantics(
        child: PListTile(
          background: tone.weak,
          color: tone.solid,
          child: Icon(event.isAllDayBool ? LucideIcons.sun : LucideIcons.clock),
        ),
      ),
      focusNode: focusNode,
      onTap: onTap,
    );
  }
}
