import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderProxyBox, BoxHitTestResult;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event_form_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';

/// 고르기 시트에 줄로 오르는 캘린더 · 라벨 — 이름과 앞 색 점.
class CalendarChoiceSource {
  const CalendarChoiceSource({
    required this.rowId,
    required this.name,
    required this.dot,
    this.colorHex,
  });

  factory CalendarChoiceSource.of(
    BuildContext context,
    int rowId,
    String name,
    String? hex,
  ) => CalendarChoiceSource(
    rowId: rowId,
    name: name,
    colorHex: hex,
    dot: chartToneOf(context, hex).solid,
  );

  final int rowId;
  final String name;
  final String? colorHex;
  final Color dot;
}

enum CalendarFormStep { location, description }

const double _rowIcon = 22;

/// 줄의 값 자리 — 값은 줄 수와 상관없이 줄 끝 오른쪽 맞춤이다(모든 줄의 글자 끝이 한 세로선, 꺾쇠 줄은 꺾쇠 앞이 끝선). 좁은 줄에서
/// 제목 아래로 내려오면 왼쪽(list.md) — 글 값은 ds List 가 end → start 로 돌려준다. 폭 제한(제목의 가장 긴 낱말 폭을 남김)도 ds List 가 한다
/// (글 값 · [PListValue] 가 값이다) — 예전에 여기서 제목 글 폭을 재어 값의 최대 폭을 정하던 우회는 걷었다.
///
/// 점은 글 첫 글자 바로 앞에 붙는다(글 흐름 안 [WidgetSpan], 사이 6) — 오른쪽 맞춤에서 첫 줄과 같이 움직이고, 둘째 줄부터는 글만
/// 오른쪽 끝에 맞는다. 점은 px 고정이라 글자 배율을 따르지 않는다.
class CalendarRowValue {
  const CalendarRowValue({required this.text, this.dot, this.maxLines});

  final String text;

  /// 값 앞 색 점(8, px 고정 — 원은 글자 배율을 따르지 않는다).
  final Color? dot;
  final int? maxLines;

  /// 줄 값 — ds 가 값으로 읽는 [Text] 하나다.
  Widget build(BuildContext context) {
    // Flutter 는 WidgetSpan 자식의 자리에 글자 배율을 곱한다 — 점(8)과 사이(6)를 배율로 나눠 줘 늘 px 그대로 서게 한다
    final scale =
        MediaQuery.textScalerOf(context).scale(PTypography.t5.fontSize!) /
        PTypography.t5.fontSize!;
    return Text.rich(
      TextSpan(
        children: [
          if (dot != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: PSpacing.x1_5 / scale),
                child: PickerDot(color: dot!, size: 8 / scale),
              ),
            ),
          // 낱말 단위로 줄을 바꾼다(Typography v114 — keepAll)
          TextSpan(text: keepAll(text)),
        ],
      ),
      textAlign: TextAlign.end,
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      semanticsLabel: text,
    );
  }
}

/// 일정 폼 시트의 본문 — 제목 입력칸 + List 줄 칸 아홉(I-09 22 ~ 28). 상태는 부모가 든다.
class CalendarEventFormRows extends StatelessWidget {
  const CalendarEventFormRows({
    super.key,
    required this.titleController,
    required this.titleFocus,
    required this.titleError,
    required this.onTitleChanged,
    required this.saveError,
    required this.calendars,
    required this.calendarsLoading,
    required this.selectedCalendar,
    required this.onPickCalendar,
    required this.onRetryCalendars,
    required this.labels,
    required this.selectedLabel,
    required this.onPickLabel,
    required this.allDay,
    required this.onAllDay,
    required this.start,
    required this.end,
    required this.today,
    required this.rangeError,
    required this.onPickStartDay,
    required this.onPickStartTime,
    required this.onPickEndDay,
    required this.onPickEndTime,
    required this.recurrence,
    required this.onPickRecurrence,
    required this.reminders,
    required this.onPickReminders,
    required this.location,
    required this.description,
    required this.onStep,
  });

  final TextEditingController titleController;
  final FocusNode titleFocus;
  final String? titleError;
  final ValueChanged<String> onTitleChanged;
  final String? saveError;
  final List<CalendarChoiceSource> calendars;
  final bool calendarsLoading;
  final int? selectedCalendar;
  final VoidCallback onPickCalendar;
  final VoidCallback onRetryCalendars;
  final List<CalendarChoiceSource> labels;
  final int? selectedLabel;
  final VoidCallback onPickLabel;
  final bool allDay;
  final ValueChanged<bool> onAllDay;
  final DateTime start;
  final DateTime end;
  final DateTime today;
  final bool rangeError;
  final VoidCallback onPickStartDay;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndDay;
  final VoidCallback onPickEndTime;
  final CalendarRecurrence recurrence;
  final VoidCallback onPickRecurrence;
  final List<int> reminders;
  final VoidCallback onPickReminders;
  final String location;
  final String description;
  final ValueChanged<CalendarFormStep> onStep;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;

    CalendarChoiceSource? find(List<CalendarChoiceSource> from, int? id) {
      for (final s in from) {
        if (s.rowId == id) return s;
      }
      return null;
    }

    final cal = find(calendars, selectedCalendar);
    final label = find(labels, selectedLabel);
    final none = l.calFormNone;

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;

        /// 값이 있는 줄 — 값은 줄 끝에서 줄바꿈하고 제목은 한 줄이다.
        Widget row({
          required String title,
          required IconData icon,
          required String? value,
          required VoidCallback? onTap,
          Color? dot,
          bool chevron = false,
          int? maxLines,
        }) => PListButtonItem(
          title: title,
          prefix: Icon(icon, size: _rowIcon),
          onTap: onTap,
          suffix: value == null && !chevron
              ? null
              : PListSuffix(
                  children: [
                    if (value != null)
                      CalendarRowValue(
                        text: value,
                        dot: dot,
                        maxLines: maxLines,
                      ).build(context),
                    if (chevron)
                      const ExcludeSemantics(
                        child: Icon(LucideIcons.chevronRight),
                      ),
                  ],
                ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (saveError != null)
              CalendarSaveErrorCallout(message: saveError!),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x3,
                PSpacing.globalGutter,
                PSpacing.x2,
              ),
              child: PField(
                required: true,
                invalid: titleError != null,
                errorMessage: titleError,
                child: PInput(
                  controller: titleController,
                  focusNode: titleFocus,
                  semanticLabel: l.calFieldTitle,
                  placeholder: l.calTitlePlaceholder,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(kCalendarTitleMax),
                  ],
                  onChanged: onTitleChanged,
                ),
              ),
            ),
            PList(
              semanticLabel: l.calFormRows,
              children: [
                // 고를 캘린더가 0 개 — 불러오는 중이면 값 없이, 실패면 "불러오지 못했어요" + 누르면 다시 받는다
                calendars.isNotEmpty
                    ? row(
                        title: l.calFieldCalendar,
                        icon: LucideIcons.calendar,
                        value: cal?.name,
                        dot: cal?.dot,
                        onTap: onPickCalendar,
                      )
                    : row(
                        title: l.calFieldCalendar,
                        icon: LucideIcons.calendar,
                        value: calendarsLoading
                            ? null
                            : l.calFormCalendarLoadFailed,
                        onTap: calendarsLoading ? null : onRetryCalendars,
                      ),
                row(
                  title: l.calFieldLabel,
                  icon: LucideIcons.tag,
                  value: label?.name ?? l.calNoLabel,
                  dot: label?.dot,
                  onTap: onPickLabel,
                ),
                PListSwitchItem(
                  title: l.calAllDay,
                  prefix: const Icon(LucideIcons.sun, size: _rowIcon),
                  checked: allDay,
                  onChanged: onAllDay,
                ),
                _DateRow(
                  title: l.calStartDate,
                  dayName: l.calFormStartDay,
                  timeName: l.calFormStartTime,
                  value: start,
                  today: today,
                  allDay: allDay,
                  rowWidth: width,
                  onDay: onPickStartDay,
                  onTime: onPickStartTime,
                ),
                _DateRow(
                  title: l.calEndDate,
                  dayName: l.calFormEndDay,
                  timeName: l.calFormEndTime,
                  value: end,
                  today: today,
                  allDay: allDay,
                  rowWidth: width,
                  onDay: onPickEndDay,
                  onTime: onPickEndTime,
                ),
              ],
            ),
            if (rangeError)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.globalGutter,
                  0,
                  PSpacing.globalGutter,
                  PSpacing.x2,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l.calFormEndBeforeStart,
                    style: PTypography.t3.copyWith(color: c.fgCritical),
                  ),
                ),
              ),
            PList(
              semanticLabel: l.calFormRowsMore,
              children: [
                row(
                  title: l.calRepeat,
                  icon: LucideIcons.repeat,
                  value: recurrenceLabel(l, recurrence),
                  onTap: onPickRecurrence,
                ),
                row(
                  title: l.calFieldReminder,
                  icon: LucideIcons.bell,
                  value: reminderValueText(l, reminders),
                  onTap: onPickReminders,
                ),
                row(
                  title: l.calLocation,
                  icon: LucideIcons.mapPin,
                  value: location.isEmpty ? none : location,
                  chevron: true,
                  onTap: () => onStep(CalendarFormStep.location),
                ),
                row(
                  title: l.calFieldDescription,
                  icon: LucideIcons.text,
                  // 설명은 값 미리보기라 두 줄까지(list.md:158)
                  value: description.isEmpty ? none : description,
                  maxLines: 2,
                  chevron: true,
                  onTap: () => onStep(CalendarFormStep.description),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 시작 · 종료 줄 — 날짜 조각 + 시각 조각 둘(time-picker.md:71). 조각마다 누르는 자리 44 이상 · 이름을 따로 두고, 종일이면 시각 조각이
/// 없다. 두 조각이 한 줄에 안 들어가면 시각 조각이 다음 줄로 간다(글은 자르지 않는다).
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.title,
    required this.dayName,
    required this.timeName,
    required this.value,
    required this.today,
    required this.allDay,
    required this.rowWidth,
    required this.onDay,
    required this.onTime,
  });

  final String title;
  final String dayName;
  final String timeName;
  final DateTime value;
  final DateTime today;
  final bool allDay;
  final double rowWidth;
  final VoidCallback onDay;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    final dayText = formatDateValue(value, today);
    final timeText = formatTimeValue(
      PTimeValue.fromDateTime(value),
      labels: PTimePickerLabels.of(context),
    );
    return PListItem(
      title: title,
      prefix: const Icon(LucideIcons.clock, size: _rowIcon),
      // 조각 묶음도 값이다(웹: 글 값이면 후손 버튼이 있어도 값으로 본다) — 좁은 줄에서 제목 아래로 내려가고 폭 제한은 ds 가 한다
      suffix: PListValue(
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: PSpacing.x2,
          // 줄 사이 22 — 조각의 누르는 자리 44 가 위아래로 11 씩 줄 밖에 있어 두 줄의 누르는 자리가 맞닿는다(웹 gap-y 22)
          runSpacing: 22,
          children: [
            _Piece(label: '$dayName, $dayText', text: dayText, onTap: onDay),
            if (!allDay)
              _Piece(
                label: '$timeName, $timeText',
                text: timeText,
                onTap: onTime,
              ),
          ],
        ),
      ),
    );
  }
}

/// 시작 · 종료 줄의 조각 — 누르는 자리는 44 이지만 줄 높이는 글 줄 하나(22)다(웹 Piece `-my-[11px] min-h-[44px]`). 위아래 11 은
/// 줄 밖으로 나가 있고 [_BleedHit] 이 그 자리의 누름도 받는다(줄의 위아래 여백 12 안이라 다른 줄과 겹치지 않는다).
class _Piece extends StatelessWidget {
  const _Piece({required this.label, required this.text, required this.onTap});

  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(PTypography.t5.fontSize!) *
        (PTypography.t5.height ?? 1);
    final bleed = math.max(0.0, (PTouch.min - lineHeight) / 2);
    return PListAction(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: _BleedHit(
          bleed: bleed,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              height: lineHeight,
              child: Align(
                widthFactor: 1,
                alignment: Alignment.center,
                child: Text(text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 자식의 위아래로 [bleed] 만큼 누르는 자리를 넓힌다 — 크기(줄 높이)는 그대로다(Material 의 tap target 패딩과 같은 길).
class _BleedHit extends SingleChildRenderObjectWidget {
  const _BleedHit({required this.bleed, required super.child});

  final double bleed;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBleedHit(bleed);

  @override
  void updateRenderObject(BuildContext context, _RenderBleedHit renderObject) =>
      renderObject.bleed = bleed;
}

class _RenderBleedHit extends RenderProxyBox {
  _RenderBleedHit(this.bleed);

  double bleed;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    final inflated = Rect.fromLTRB(0, -bleed, size.width, size.height + bleed);
    if (!inflated.contains(position)) return false;
    // 줄 밖(위아래 bleed)을 누르면 자식 안쪽 가장자리를 누른 것으로 넘긴다
    final clamped = Offset(
      position.dx,
      position.dy.clamp(0.0, size.height - 0.01),
    );
    return c.hitTest(result, position: clamped);
  }
}

/// 한 단계 머리의 오른쪽 "완료" — 닫기 원 자리의 글 버튼(t4 14 · 700 · `fg-neutral` · 보이는 36). 시트 머리의 동작 자리는 44 폭이라
/// 글 버튼이 왼쪽으로 넘쳐 나오게 하고, 바깥 끝은 화면 끝에서 16(웹 `SheetStepDone` 과 같다)에 맞춘다.
class CalendarStepDone extends StatelessWidget {
  const CalendarStepDone({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: 160,
      alignment: Alignment.centerRight,
      child: Transform.translate(
        offset: const Offset(4, 0),
        child: PButton(
          label: label,
          variant: PButtonVariant.ghost,
          ghostColor: PButtonGhostColor.neutral,
          size: PButtonSize.small,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// 폼 맨 위 저장 실패 알림 — 서버가 낸 글이 아니라 우리 글.
class CalendarSaveErrorCallout extends StatelessWidget {
  const CalendarSaveErrorCallout({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x3,
      PSpacing.globalGutter,
      0,
    ),
    child: PCallout(
      tone: PCalloutTone.critical,
      description: message,
      alert: true,
    ),
  );
}
