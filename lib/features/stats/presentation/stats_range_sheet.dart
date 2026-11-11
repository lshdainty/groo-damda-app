import 'package:flutter/material.dart';

import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';

/// 통계 빠른 기간 — date-picker.md "빠른 기간" 표의 이름 · 범위 한 벌에서 고른다(이름이 같으면 어디서나 같은 기간).
/// 내보내기 기간 시트와 같은 다섯이다(같은 앱 기간 시트끼리 같은 모양). 옛 분기 탭은 달력에서 석 달 고르기로 대신한다.
const statsRangePresets = <PDatePreset>[
  PDatePreset.thisWeek,
  PDatePreset.thisMonth,
  PDatePreset.lastMonth,
  PDatePreset.last3Months,
  PDatePreset.thisYear,
];

/// 통계 기간 고르기 시트 — ds Date Picker 기간(칸 하나 · 이어지는 달 · 빠른 기간 칩 · 바닥 "초기화" + "완료").
/// 시작 · 끝 두 칸을 두지 않는다. "완료" 는 끝까지 고르기 전에는 막힌다. ✕ · 뒤로 가기로 닫으면 null(바깥 누르기 · 끌어내리기로는 닫히지 않는다).
/// [today] 는 시험 · 하네스가 오늘을 고정할 때만 준다.
Future<StatsPeriod?> showStatsRangeSheet(
  BuildContext context,
  StatsPeriod current, {
  DateTime? today,
}) async {
  final l = AppLocalizations.of(context);
  final now = today ?? DateTime.now();
  final picked = await PBottomSheet.show<PDateRange>(
    context,
    // 달력을 위아래로 굴리다 시트째 닫히지 않게 — 웹 RangePickerSheet(dismissible={false}) · 가계부 필터 기간 시트와 같다(DA-36)
    dismissible: false,
    builder: (_) {
      // 열 때는 지금 기간에서 시작한다. 초기화는 비워서 다시 고르게 한다.
      PDateRange? draft = PDateRange(start: current.from, end: current.to);
      return StatefulBuilder(
        builder: (context, setSheet) => PBottomSheetContent(
          title: l.statsPeriodPickerTitle,
          closeLabel: l.actionClose,
          flushBody: true,
          body: SizedBox(
            height: PDatePicker.sheetBodyHeight(context),
            child: PDatePicker.range(
              labels: PDatePickerLabels.of(context),
              semanticLabel: l.statsPeriodPickerTitle,
              visibleRange: PDateVisibleRange.continuous,
              presets: statsRangePresets,
              value: draft,
              today: now,
              onChanged: (v) => setSheet(() => draft = v),
            ),
          ),
          footer: [
            PButton(
              label: l.actionReset,
              size: PButtonSize.large,
              variant: PButtonVariant.neutralWeak,
              onPressed: () => setSheet(() => draft = null),
            ),
            PButton(
              label: l.actionDone,
              size: PButtonSize.large,
              onPressed: draft?.end == null
                  ? null
                  : () => PBottomSheet.of(context).close(draft),
            ),
          ],
        ),
      );
    },
  );
  final end = picked?.end;
  if (picked == null || end == null) return null;
  return statsPeriodOfRange(current, picked.start ?? end, end);
}
