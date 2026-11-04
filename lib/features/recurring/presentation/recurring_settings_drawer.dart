import 'package:flutter/material.dart';

import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';

/// 반복 설정 열기 — 추가 · 수정 · 이체 씨앗은 새 폼([showRecurringFormSheet]). 거래에서 만들기는 거래 상세 안 한 단계다
/// ([RecurringFormFlow], I-21 H 44).
///
/// [transferSeed] — 새로 만들되 값만 물려받는다(이체 상세의 "반복 설정"). 이미 일어난 이체와 앞으로 실행될 규칙은 별개라, 여기서
/// 금액을 고쳐도 그 이체는 그대로다(사용자 결정 2026-09-14).
void showRecurringSettingsDialog(
  BuildContext context, {
  RecurringTransaction? recurring,
  AssetTransfer? transferSeed,
}) {
  showRecurringFormSheet(
    context,
    recurring: recurring,
    transferSeed: transferSeed,
  );
}
