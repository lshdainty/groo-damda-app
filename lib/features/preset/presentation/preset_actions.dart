import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';

/// 프리셋 하나를 지우고 목록을 다시 받는다. 실패하면 던진다 — 알리는 일은 부른 쪽 몫이다(전역 오류 토스트는 끈다:
/// 화면이 자기 자리에서 알리므로 둘이 같은 아래쪽에서 겹치지 않게).
///
/// 목록을 **다시 받은 뒤에** 끝난다 — 호출한 쪽이 시트를 닫거나 버튼을 풀 때 줄이 이미 사라져 있다(지운 줄을 한 번 더 누르지 않게).
Future<void> deletePresetRequest(ProviderContainer container, int rowId) async {
  final repo = await container.read(presetRepositoryProvider.future);
  await repo.delete(rowId, silent: true);
  container.invalidate(presetListProvider);
  try {
    await container.read(presetListProvider.future);
  } catch (_) {
    // 지우기는 이미 끝났다 — 목록을 다시 못 받은 것은 목록 화면의 실패 갈래가 알린다
  }
}

/// 삭제 확인창(PAlertDialog destructive) → 확정하면 지운다. [confirmed] 가 true 이고 [failure] 가 있으면 지우기가 실패한 것이다
/// (확인창은 닫혔다 — 알리는 자리는 부른 쪽이 정한다: 목록은 스낵바 + 다시 시도, 상세 시트는 시트 안 Callout).
Future<({bool confirmed, Object? failure})> askDeletePreset(
  BuildContext context,
  ExpenseTemplate p,
) async {
  final l = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  Object? failure;
  final ok = await PAlertDialog.show(
    context,
    title: l.presetDeleteConfirmTitle(p.templateName),
    description: l.presetDeleteConfirm,
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    destructive: true,
    // 확정이 끝날 때까지 확정 버튼이 로딩이고 다음 누름을 버린다 — 지우는 동안 다시 누르지 못한다
    onAction: () async {
      try {
        await deletePresetRequest(container, p.rowId);
      } catch (e) {
        failure = e;
      }
    },
  );
  return (confirmed: ok, failure: failure);
}
