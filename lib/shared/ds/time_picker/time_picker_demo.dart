import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';

/// 시각 칸이 누르면 여는 시트 — 고르는 동안 칸 값은 그대로이고 "완료" 로 넣는다. 바깥 · 끌어내리기로 닫으면 버린다(null).
/// 칸이 비었으면 지금을 분 간격에 맞춰 반올림한 자리를 짚어 열기만 한다 — "완료" 는 그 자리를 넣는다.
Future<PTimeValue?> showTimePickerSheet(
  BuildContext context, {
  PTimeValue? current,
  int minuteStep = 1,
  String title = '시각 선택',
  String? semanticLabel,
  DateTime? now,
}) {
  final fallback = roundDateTimeToStep(now ?? DateTime.now(), minuteStep);
  return PBottomSheet.show<PTimeValue>(
    context,
    builder: (_) {
      PTimeValue? draft = current;
      return StatefulBuilder(
        builder: (context, setState) => PBottomSheetContent(
          title: title,
          closeLabel: '닫기',
          body: PTimePicker(
            value: draft ?? PTimeValue.fromDateTime(fallback),
            minuteStep: minuteStep,
            semanticLabel: semanticLabel ?? title,
            onChanged: (v) => setState(() => draft = v),
          ),
          footer: [
            PButton(
              label: '완료',
              size: PButtonSize.large,
              onPressed: () => PBottomSheet.of(
                context,
              ).close(draft ?? PTimeValue.fromDateTime(fallback)),
            ),
          ],
        ),
      );
    },
  );
}

/// 카탈로그(/dev/ds) — 분 간격 × 값(오전 · 오후 · 정오 · 자정 경계), 막힘, 시각 칸 + 시트("완료" 로 넣는다), 날짜 칸 옆의
/// 시각 칸. 예는 time-picker.md 의 것이다(웹 `time-picker.demo.tsx` 와 같은 구성).
class TimePickerDemo extends StatelessWidget {
  const TimePickerDemo({super.key});

  static const _width = 280.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '분 간격 — 1 · 5(기본) · 10 · 15 · 30. 칼럼에는 그 간격의 분만 있다(60 · 12 · 6 · 4 · 2칸)',
          children: [
            for (final step in pMinuteSteps)
              DemoRow(
                label: '간격 $step${step == 5 ? ' (기본)' : ''}',
                children: [
                  SizedBox(
                    width: _width,
                    child: PTimePicker(
                      value: const PTimeValue(15, 30),
                      minuteStep: step,
                      semanticLabel: '분 간격 $step',
                    ),
                  ),
                ],
              ),
          ],
        ),
        const DemoBlock(
          title: '가장 나쁜 값 — 정오 · 자정 · 하루의 끝(23:58 은 간격에 맞춰 오전 12:00 으로 보인다)',
          children: [
            DemoRow(
              label: '오전 12 00 — 자정',
              children: [
                SizedBox(
                  width: _width,
                  child: PTimePicker(
                    value: PTimeValue(0, 0),
                    semanticLabel: '자정',
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '오후 12 00 — 정오',
              children: [
                SizedBox(
                  width: _width,
                  child: PTimePicker(
                    value: PTimeValue(12, 0),
                    semanticLabel: '정오',
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '23:58 → 오전 12 00',
              children: [
                SizedBox(
                  width: _width,
                  child: PTimePicker(
                    value: PTimeValue(23, 58),
                    semanticLabel: '하루의 끝',
                  ),
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title: '상태 — 막힘(값은 그대로, 고른 항목도 흐리게, 띠는 남는다)',
          children: [
            DemoRow(
              label: 'disabled',
              children: [
                SizedBox(
                  width: _width,
                  child: PTimePicker(
                    value: PTimeValue(15, 30),
                    disabled: true,
                    semanticLabel: '막힌 시각',
                  ),
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title:
              '직접 굴려 본다 — 칸을 누르면 시트가 열리고, 고르는 동안 칸은 그대로 · "완료" 로 넣는다 · 바깥으로 닫으면 버린다',
          children: [_TryTime(), _TryDateTime()],
        ),
      ],
    );
  }
}

class _TryTime extends StatefulWidget {
  const _TryTime();

  @override
  State<_TryTime> createState() => _TryTimeState();
}

class _TryTimeState extends State<_TryTime> {
  PTimeValue? _time;
  bool _open = false;

  Future<void> _openSheet() async {
    setState(() => _open = true);
    final result = await showTimePickerSheet(
      context,
      current: _time,
      title: '일정 시작 시각',
    );
    if (!mounted) return;
    setState(() {
      _open = false;
      if (result != null) _time = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PField(
      label: '시작 시각',
      child: PInputButton(
        placeholder: '시간 선택',
        value: _time == null ? null : formatTimeValue(_time),
        suffixIcon: LucideIcons.clock,
        expanded: _open,
        onPressed: _openSheet,
      ),
    );
  }
}

/// 날짜 칸 옆에 시각 칸을 나란히 — 날짜 칸은 글이 다 들어가는 폭 이상, 시각 칸은 144. 한 줄에 둘이 들어가지 않으면 시각 칸이
/// 다음 줄로 내려간다. 칸 글은 자르지 않는다. (이 견본의 날짜 칸은 값을 보이기만 한다 — 달력은 Date Picker 견본에 있다)
class _TryDateTime extends StatefulWidget {
  const _TryDateTime();

  @override
  State<_TryDateTime> createState() => _TryDateTimeState();
}

class _TryDateTimeState extends State<_TryDateTime> {
  PTimeValue? _time = const PTimeValue(15, 30);

  Future<void> _openSheet() async {
    final result = await showTimePickerSheet(
      context,
      current: _time,
      title: '거래 시각',
    );
    if (!mounted) return;
    if (result != null) setState(() => _time = result);
  }

  @override
  Widget build(BuildContext context) {
    const date = '2027년 1월 3일 (일)';
    return LayoutBuilder(
      builder: (context, constraints) {
        // 날짜 칸이 글이 다 들어가는 폭 — 좌우 16 · 아이콘 20 · 사이 10 + 글
        final painter = TextPainter(
          text: TextSpan(text: date, style: PTypography.t5),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final need = painter.width + PSpacing.x4 * 2 + 20 + PSpacing.x2_5;
        painter.dispose();
        final oneLine =
            constraints.maxWidth >= math.max(need, 0) + PSpacing.x2 + 144;
        final dateField = PField(
          label: '날짜',
          child: PInputButton(
            value: date,
            placeholder: '날짜 선택',
            suffixIcon: LucideIcons.calendarDays,
            onPressed: () {},
          ),
        );
        final timeField = PField(
          label: '시각',
          child: PInputButton(
            value: _time == null ? null : formatTimeValue(_time),
            placeholder: '시간 선택',
            suffixIcon: LucideIcons.clock,
            onPressed: _openSheet,
          ),
        );
        if (oneLine) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x2,
            children: [
              Expanded(child: dateField),
              SizedBox(width: 144, child: timeField),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PSpacing.x2,
          children: [
            dateField,
            SizedBox(width: 144, child: timeField),
          ],
        );
      },
    );
  }
}
