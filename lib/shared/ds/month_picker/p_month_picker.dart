import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

/// 달 고르기 — 연 | 월 두 칼럼 Wheel Picker 를 아래 시트에 열고 "완료" 로 넣는다.
///
/// 스펙은 groo-design `specs/components/wheel-picker.md` "달만 고르기" — medium 44 · 보이는 칸 5(220) · 연 120 오른쪽 ·
/// 월 96 왼쪽 반복, 달력 머리의 연 · 월 휠(p_date_picker.dart)과 같은 칼럼이다. 4 × 3 월 격자는 두지 않는다.
/// 바깥 누르기 · 끌어내리기 · 닫기 버튼 · 뒤로 가기는 모두 값을 넣지 않고 닫는다(null) — 고른 값은 "완료" 로만 들어간다.
/// 열 때는 [initial] 달에서 시작하고, 고르면 그 달의 1일을 돌려준다. 연 범위는 기본 오늘 ± 100년.
Future<DateTime?> showPMonthPicker(
  BuildContext context, {
  required DateTime initial,
  String? title,
  ({int start, int end})? yearRange,
}) {
  final today = DateTime.now();
  final range = yearRange ?? (start: today.year - 100, end: today.year + 100);
  return PBottomSheet.show<DateTime>(
    context,
    dismissible: false,
    builder: (sheetContext) {
      var year = initial.year.clamp(range.start, range.end);
      var month = initial.month;
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          final l = AppLocalizations.of(ctx);
          return PBottomSheetContent(
            title: title ?? l.budgetSelectMonth,
            closeLabel: l.actionClose,
            body: PMonthWheel(
              year: year,
              month: month,
              yearRange: range,
              labels: PDatePickerLabels.of(ctx),
              onChanged: (y, m) => setSheet(() {
                year = y;
                month = m;
              }),
            ),
            footer: [
              PButton(
                label: l.actionDone,
                size: PButtonSize.large,
                onPressed: () =>
                    PBottomSheet.of(ctx).close(DateTime(year, month, 1)),
              ),
            ],
          );
        },
      );
    },
  );
}

/// 연 | 월 휠 — 연 120 오른쪽 · 월 96 왼쪽 반복(보이는 칸 5). 시트 · 팝오버가 같이 쓴다.
class PMonthWheel extends StatelessWidget {
  const PMonthWheel({
    super.key,
    required this.year,
    required this.month,
    required this.yearRange,
    required this.labels,
    required this.onChanged,
  });

  final int year;
  final int month;
  final ({int start, int end}) yearRange;
  final PDatePickerLabels labels;

  /// 휠이 멈춘 뒤 (연, 월).
  final void Function(int year, int month) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = labels;
    return PWheelPicker(
      semanticLabel: l.month(year, month),
      children: [
        PWheelPickerColumn<int>(
          semanticLabel: l.yearWheel,
          options: [
            for (var y = yearRange.start; y <= yearRange.end; y++)
              PWheelPickerOption<int>(value: y, label: l.yearOption(y)),
          ],
          value: year,
          align: PWheelPickerAlign.right,
          width: 120,
          onChanged: (value, _) => onChanged(value, month),
        ),
        PWheelPickerColumn<int>(
          semanticLabel: l.monthWheel,
          options: [
            for (var m = 1; m <= 12; m++)
              PWheelPickerOption<int>(value: m, label: l.monthOption(m)),
          ],
          value: month,
          align: PWheelPickerAlign.left,
          width: 96,
          loop: true,
          onChanged: (value, _) => onChanged(year, value),
        ),
      ],
    );
  }
}
