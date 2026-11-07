import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_unlock_step.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 금액 보기 비밀번호 시트(I-14 44) — 금액 가리기 화면이 부르는 표면. ds 입력 폼 시트(위 닫기 원 + 바닥 [금액 보기])이고,
/// 본문은 자산 수정 폼의 같은 시트 단계와 한 부품([HideAmountsUnlockStep])이다. 바깥 누름 · 끌어내림으로 닫히지 않고, 칸에 값이
/// 있는 채 닫으면 "작성한 내용이 사라져요" 를 묻는다. 비밀번호 검증이 성공하면 [true], 닫으면 [false].
Future<bool> showHideAmountsUnlockSheet(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final probe = HideAmountsUnlockProbe();
  final ok = await PBottomSheet.show<bool>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (sheetContext) => HideAmountsUnlockStep(
      probe: probe,
      onVerified: () => PBottomSheet.of(sheetContext).close(true),
    ),
  );
  return ok == true;
}

/// 금액을 다시 보기 위한 본인 확인 — 생체인증을 먼저, 안 되면 비밀번호.
///
/// 앱 잠금을 켠 사람은 이미 이 앱에서 생체인증을 쓰기로 한 것이다. 그 사람에게까지
/// 카드를 풀 때마다 비밀번호를 치게 하면 화면·카드별로 골라 보는 기능 자체를 안 쓰게 된다.
/// 앱 잠금이 꺼져 있으면 프롬프트를 띄우지 않는다 — 켠 적 없는 사람에게 갑자기 Face ID 가
/// 뜨는 건 놀랄 일이다.
///
/// 생체를 취소하거나 실패하면 비밀번호로 물러선다. 풀려던 의도는 분명하니 길을 막지 않되,
/// 거기서도 취소할 수 있다.
Future<bool> confirmHideAmountsUnlock(
  BuildContext context,
  WidgetRef ref,
) async {
  if (await tryHideAmountsBiometric(context, ref)) return true;
  if (!context.mounted) return false;
  return showHideAmountsUnlockSheet(context);
}

/// 생체인증만 시도한다 — 앱 잠금이 켜져 있고 인증이 되면 true. 꺼져 있거나 취소 · 실패 · 수단 없음이면 false(비밀번호로 물러선다).
///
/// 앱 잠금이 꺼져 있으면 프롬프트를 띄우지 않는다 — 켠 적 없는 사람에게 갑자기 Face ID 가 뜨는 건 놀랄 일이다. 비밀번호 칸을
/// 어디에 보일지(금액 가리기의 시트 · 자산 폼의 같은 시트 단계)는 부르는 쪽이 정한다.
Future<bool> tryHideAmountsBiometric(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!ref.read(appLockEnabledProvider)) return false;
  final l = AppLocalizations.of(context);
  final result = await ref
      .read(appLockAuthProvider)
      .authenticate(
        reason: l.unlockBiometricReason,
        signInTitle: l.unlockTitle,
        cancelLabel: l.actionCancel,
      );
  return result == AppLockAuthResult.success;
}

/// 자산 수정 폼의 "금액 가리기" 를 **끄고 저장**할 때 본인 확인이 필요한가.
///
/// 앱은 자산 상세에 이 토글이 없어(사용자 결정) 수정 폼이 **유일한 해제 경로**다. 여기에 확인이 없으면 "풀 때는 본인 확인" 규칙
/// 자체가 없는 것과 같다 — 스위치를 끄고 저장만 누르면 그냥 풀렸다(QA 22차 #2). 켜는 쪽(`false → true`)과 안 건드린 저장은 확인이
/// 필요 없다. 폼은 이게 true 면 생체인증([tryHideAmountsBiometric])을 먼저 하고, 안 되면 같은 시트의 비밀번호 단계
/// (`HideAmountsUnlockStep`)로 넘어간다 — 취소하면 저장도 안 한다(폼의 체크는 끈 채로 남지만 서버 값은 숨김 그대로다).
bool assetUnhideNeedsConfirm({
  required bool wasHidden,
  required bool nowHidden,
}) => wasHidden && !nowHidden;

/// 카드 묶음 토글 — 켜기는 그냥, 풀기는 본인 확인을 거친다.
///
/// 여러 장을 한 번에 넘기면 **인증도 한 번**이다. 카드마다 확인을 받으면
/// 페이지·전체 잠그기를 쓸 수가 없다.
Future<void> setHideCardsWithUnlock(
  BuildContext context,
  WidgetRef ref, {
  required Iterable<String> cards,
  required bool hide,
}) async {
  final notifier = ref.read(settingsProvider.notifier);
  final snack = PSnackbar.maybeOf(context);
  final l = AppLocalizations.of(context);
  if (!hide) {
    final ok = await confirmHideAmountsUnlock(context, ref);
    if (!ok) return;
  }
  final outcome = hide
      ? await notifier.hideCards(cards)
      : await notifier.revealCards(cards);
  // 누르는 순간 바뀌는 값 — 액션이 없어 두 문장("… 잠시 뒤 다시 시도해주세요."), [다시 시도] 없음(디자인시스템 판단 ②). 서버가 받지 못하면 로컬도 그대로다.
  // 응답을 못 받았으면 서버 값을 다시 받아 맞췄다 — "바뀌었는지 확인하지 못했어요."
  final message = switch (outcome) {
    WriteOutcome.done => null,
    WriteOutcome.failed => l.hideAmountsSaveFailedToast,
    WriteOutcome.unconfirmed => l.unconfirmedToggle,
  };
  if (message != null) {
    snack?.show(message: message, tone: PSnackbarTone.critical);
  }
}
