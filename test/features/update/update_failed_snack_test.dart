// 앱 업데이트 시트 설치 실패 알림 — ds 스낵바(critical) 한 문장이다(I-28-5-8, 옛 showPSnackBar 걷음).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

void main() {
  test('글은 마침표가 하나인 한 문장이다', () {
    for (final s in [
      AppLocalizationsKo().updateSheetFailed,
      AppLocalizationsEn().updateSheetFailed,
    ]) {
      expect(s.endsWith('.'), isTrue);
      expect('.'.allMatches(s).length, 1);
    }
    expect(AppLocalizationsKo().updateSheetFailed, '앱에서 받지 못해 브라우저로 열어요.');
  });

  test('두 화면 모두 ds 스낵바 critical 로 알린다', () {
    for (final f in [
      'lib/features/update/presentation/update_gate_screen.dart',
      'lib/features/settings/presentation/update_screen.dart',
    ]) {
      final src = File(f).readAsStringSync();
      expect(src.contains('showPSnackBar('), isFalse, reason: f);
      expect(src.contains('PSnackbarTone.critical'), isTrue, reason: f);
    }
  });
}
