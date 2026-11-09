import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';

/// 시각 시트 — 12시간 휠([minuteStep] 분, 기본 1) + "완료". 휠을 안 굴렸으면 지금 값이 들어간다. 닫으면 null.
Future<PTimeValue?> showTimeSheet(
  BuildContext context, {
  required String title,
  required PTimeValue value,
  int minuteStep = 1,
}) => PBottomSheet.show<PTimeValue>(
  context,
  builder: (ctx) {
    PTimeValue draft = value;
    return StatefulBuilder(
      builder: (ctx, setSheet) {
        final l = AppLocalizations.of(ctx);
        return PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          body: Center(
            child: PTimePicker(
              semanticLabel: title,
              value: draft,
              minuteStep: minuteStep,
              onChanged: (v) => setSheet(() => draft = v),
            ),
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
