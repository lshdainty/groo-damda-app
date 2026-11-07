import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 앱 잠금 스위치 — 켤 때만 생체인증을 거친다.
///
/// 켜는 순간이 곧 작동 검증이다: 인증이 안 되는 상태(미등록·미지원)로 잠가 두면
/// 다음 실행부터 앱을 못 연다. 끄는 건 그냥 꺼진다 — 이 화면까지 왔다는 것 자체가
/// 이미 잠금을 통과했다는 뜻이다.
///
/// 금액 가리기의 [setHideCardsWithUnlock] 과 같은 자리의 헬퍼로, 화면은 스위치만
/// 그리고 인증 여부 판단은 여기서 한다.
Future<void> setAppLockWithAuth(
  BuildContext context,
  WidgetRef ref,
  bool on,
) async {
  final notifier = ref.read(settingsProvider.notifier);
  if (!on) {
    await notifier.setAppLock(false);
    return;
  }
  final l = AppLocalizations.of(context);
  final result = await ref
      .read(appLockAuthProvider)
      .authenticate(
        reason: l.appLockPromptReason,
        signInTitle: l.appLockTitle,
        cancelLabel: l.actionCancel,
      );
  switch (result) {
    case AppLockAuthResult.success:
      await notifier.setAppLock(true);
    case AppLockAuthResult.unavailable:
      // 안내는 스낵바가 아니라 줄 설명이 한다 — 미리 물은 값이 낡았던 경우라 줄이 그 자리에서 막히고 까닭이 보인다
      ref.read(appLockUnavailableNowProvider.notifier).set(true);
    case AppLockAuthResult.failure:
      // 취소·불일치 — 켜지 않고 그대로 둔다.
      break;
  }
}
