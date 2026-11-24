import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/features/calendar/domain/calendar_ownership.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';

/// 새 소유자 고르기 — 나 말고 남은 멤버 줄(아바타 · 이름 · 권한). 누르면 바로 고르고 닫힌다(고르기 시트, 바닥 버튼 없음).
/// 받을 수 없는 줄([canReceiveOwnership] 이 거짓 — 편집 가능 멤버가 있을 때의 읽기 전용 멤버)은 막고 까닭을 적는다.
/// 닫으면(고르지 않으면) null. [others] 는 [otherCalendarMembers] 결과.
Future<CalendarMember?> showCalendarTransferSheet(
  BuildContext context, {
  required List<CalendarMember> others,
}) async {
  final picked = await PBottomSheet.show<int>(
    context,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      return PBottomSheetContent(
        title: l.calTransferPickTitle,
        description: l.calTransferPickHint,
        closeLabel: l.actionClose,
        flushBody: true,
        scrollFog: true,
        body: PickList<int>(
          label: l.calTransferPickTitle,
          selected: null,
          items: [
            for (final m in others)
              _item(l, m, enabled: canReceiveOwnership(m, others)),
          ],
        ),
      );
    },
  );
  if (picked == null) return null;
  for (final m in others) {
    if (m.rowId == picked) return m;
  }
  return null;
}

PickItem<int> _item(
  AppLocalizations l,
  CalendarMember m, {
  required bool enabled,
}) => PickItem<int>(
  value: m.rowId,
  title: m.userName,
  detail: enabled
      ? (m.permission == 'EDIT' ? l.calRoleEditor : l.calRoleViewer)
      : l.calTransferReaderLocked,
  prefix: PAvatar(name: m.userName, size: PAvatarSize.s36, decorative: true),
  enabled: enabled,
);
