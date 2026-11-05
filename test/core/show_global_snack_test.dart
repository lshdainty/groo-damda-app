// showGlobalSnack — 딥링크 · 수명주기처럼 BuildContext 가 없는 자리가 ds 스낵바 호스트(앱 맨 위 키)로 띄운다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../support/plain_text.dart';

void main() {
  testWidgets('호스트 키로 neutral 한 문장을 띄운다(호스트가 없으면 조용히 건너뜀)', (tester) async {
    showGlobalSnack((l) => l.passwordChanged); // 호스트 전 — 던지지 않는다
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => Material(
          type: MaterialType.transparency,
          child: PSnackbarHost(
            key: PSnackbar.appHostKey,
            closeLabel: '닫기',
            child: child!,
          ),
        ),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    showGlobalSnack((l) => l.passwordChanged);
    await tester.pumpAndSettle();
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(findPlain(l.passwordChanged), findsOneWidget);
  });
}
