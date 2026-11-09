import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';

/// 일정 폼의 고르는 표면(I-09 24 · 26 · 28) — 폼 시트 위에 고르기 시트가 하나 더 뜬다(bottom-sheet.md:189).
/// 고르는 동안 줄 값은 그대로이고 "완료" 에 들어간다(날짜 · 시각 · 알림). 목록 고르기는 누르면 바로 넣고 닫힌다.

/// 하나 고르기 시트의 줄 — [dot] 은 앞 색 점 10.
class CalendarChoice {
  const CalendarChoice({required this.value, required this.label, this.dot});
  final int value;
  final String label;
  final Color? dot;
}

/// 하나 고르기 — 줄(앞 색 점 10 · 이름 · 고른 줄 뒤 체크). 누르면 바로 넣고 닫힌다, 바닥 버튼 없음. 닫으면(고르지 않으면) null.
/// [footnote] 는 목록 아래 R9 안내(라벨이 0 개일 때).
Future<int?> showCalendarChoiceSheet(
  BuildContext context, {
  required String title,
  required List<CalendarChoice> items,
  required int? selected,
  String? footnote,
}) => PBottomSheet.show<int>(
  context,
  builder: (ctx) {
    final l = AppLocalizations.of(ctx);
    final c = ctx.colors;
    return PBottomSheetContent(
      title: title,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickList<int>(
            label: title,
            selected: selected,
            items: [
              for (final it in items)
                PickItem<int>(
                  value: it.value,
                  title: it.label,
                  prefix: it.dot == null
                      ? null
                      : PickerDot(color: it.dot!, size: 10),
                ),
            ],
          ),
          if (footnote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                PSpacing.x4,
                PSpacing.globalGutter,
                PSpacing.x2,
              ),
              child: Text(
                footnote,
                textAlign: TextAlign.center,
                style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
        ],
      ),
    );
  },
);

/// 여럿 고르기 — 체크 줄 + 바닥 "완료"(고르는 동안 줄 값 그대로, "완료" 에 넣는다). 닫으면 null(바뀐 것 없음).
/// [selected] 가 선택지 밖의 값(웹에서 건 10분 전)을 들고 있어도 그대로 이어진다 — 화면에 안 보인다고 지우지 않는다.
Future<List<int>?> showCalendarMultiChoiceSheet(
  BuildContext context, {
  required String title,
  required List<CalendarChoice> items,
  required List<int> selected,
}) => PBottomSheet.show<List<int>>(
  context,
  builder: (ctx) {
    var draft = [...selected];
    return StatefulBuilder(
      builder: (ctx, setSheet) {
        final l = AppLocalizations.of(ctx);
        return PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          flushBody: true,
          scrollFog: true,
          body: PListCheckGroup(
            semanticLabel: title,
            children: [
              for (final it in items)
                PListCheckItem(
                  title: it.label,
                  checked: draft.contains(it.value),
                  onChanged: (on) => setSheet(() {
                    draft = on
                        ? [...draft, it.value]
                        : [
                            for (final v in draft)
                              if (v != it.value) v,
                          ];
                  }),
                ),
            ],
          ),
          footer: [
            PButton(
              label: l.actionDone,
              size: PButtonSize.large,
              onPressed: () => PBottomSheet.of(ctx).close(draft),
            ),
          ],
        );
      },
    );
  },
);

/// 날짜 — 달이 이어지는 달력 시트 + "완료". 닫으면 null.
Future<DateTime?> showCalendarDaySheet(
  BuildContext context, {
  required String title,
  required DateTime value,
  required DateTime today,
}) => PBottomSheet.show<DateTime>(
  context,
  dismissible: false,
  builder: (ctx) {
    DateTime? draft = value;
    return StatefulBuilder(
      builder: (ctx, setSheet) {
        final l = AppLocalizations.of(ctx);
        return PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          flushBody: true,
          body: SizedBox(
            height: PDatePicker.sheetBodyHeight(ctx),
            child: PDatePicker.single(
              labels: PDatePickerLabels.of(ctx),
              semanticLabel: title,
              value: draft,
              today: today,
              visibleRange: PDateVisibleRange.continuous,
              onChanged: (v) => setSheet(() => draft = v),
            ),
          ),
          footer: [
            PButton(
              label: l.actionDone,
              size: PButtonSize.large,
              onPressed: draft == null
                  ? null
                  : () => PBottomSheet.of(ctx).close(draft),
            ),
          ],
        );
      },
    );
  },
);
