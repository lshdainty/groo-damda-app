// 이용 해지 시트 — I-05 31 ~ 38 (ds Bottom Sheet 입력 폼 · 바닥 버튼 · 본인 확인 코드 칸 · 덮개).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/settings/application/withdrawal_providers.dart';
import 'package:groo_damda_app/features/settings/data/withdrawal_repository.dart';
import 'package:groo_damda_app/features/settings/domain/withdrawal_check.dart';
import 'package:groo_damda_app/features/settings/presentation/withdrawal_sheet.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_otp/p_input_otp.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/widgets/p_busy_scrim.dart';
import '../../support/plain_text.dart';

const _user = User(
  rowId: 1,
  userId: 'tester',
  userName: 'Tester',
  userEmail: 'tester@example.com',
);

class _Auth extends AuthNotifier {
  @override
  Future<User?> build() async => _user;
  @override
  Future<void> logout() async => state = const AsyncData(null);
}

class _Repo extends WithdrawalRepository {
  _Repo({this.check_, this.verifyCode, this.verifyPw, this.failLoad = false})
    : super(Dio());
  final Future<String> Function(String pw)? verifyPw;
  final bool failLoad;
  final WithdrawalCheck? check_;
  final Future<String> Function(String code)? verifyCode;
  int sent = 0;
  int withdrawCalls = 0;
  Completer<void>? withdrawGate;

  @override
  Future<WithdrawalCheck> check() async {
    if (failLoad) throw ApiException(code: 'X', message: '');
    return _checkValue();
  }

  WithdrawalCheck _checkValue() =>
      check_ ??
      const WithdrawalCheck(
        blocked: [],
        subscriptionPeriodEnd: null,
        sharedCalendarsOwned: 2,
        calendarMemberships: 0,
        dutchPaysOwned: 0,
        dutchPayParticipations: 1,
      );

  @override
  Future<void> sendEmailCode() async {
    sent++;
  }

  @override
  Future<String> verifyEmailCode(String code) =>
      verifyCode?.call(code) ?? Future.value('ticket');

  @override
  Future<String> verifyPassword(String password) =>
      verifyPw?.call(password) ?? Future.value('ticket');

  @override
  Future<void> withdraw({required String reauthToken, String? reason}) async {
    withdrawCalls++;
    await withdrawGate?.future;
  }
}

final _l = lookupAppLocalizations(const Locale('ko'));

Finder _has(String part) => find.byWidgetPredicate((w) {
  final text = w is Text
      ? (w.data ?? w.textSpan?.toPlainText() ?? '')
      : w is RichText
      ? w.text.toPlainText()
      : '';
  return text.replaceAll('\u2060', '').contains(part);
});

/// keepAll 이 끼우는 보이지 않는 글자(U+2060)를 빼고 찾는다.
Finder _t(String part) => find.byWidgetPredicate(
  (w) => w is Text && plainOf(w.data ?? w.textSpan!.toPlainText()) == part,
);

Future<void> _open(
  WidgetTester tester,
  _Repo repo, {
  bool dark = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showWithdrawalSheet(c),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/withdrawn',
        builder: (_, _) => const Scaffold(body: Text('DONE')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_Auth.new),
        withdrawalRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp.router(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1단계 — 제목 · ✕ · 바닥은 [계속] 하나(critical), 취소 버튼 없음', (tester) async {
    await _open(tester, _Repo());
    expect(_t('그루 담다 이용 해지'), findsWidgets);
    expect(_t(_l.withdrawIntro), findsOneWidget);
    expect(find.byKey(const ValueKey('p-bottom-sheet-close')), findsOneWidget);
    final buttons = tester.widgetList<PButton>(find.byType(PButton)).toList();
    expect(buttons, hasLength(1));
    expect(buttons.single.label, _l.withdrawNext);
    expect(buttons.single.variant, PButtonVariant.criticalSolid);
    expect(buttons.single.size, PButtonSize.large);
    expect(findText(_l.actionCancel), findsNothing);
    // 잃는 것 두 줄 + 되돌릴 수 없어요 Callout(warning)
    expect(_t(_l.withdrawImpactCalendarsOwned(2)), findsOneWidget);
    expect(_t(_l.withdrawImpactDutchPayParticipations(1)), findsOneWidget);
    expect(
      tester.widget<PCallout>(find.byType(PCallout)).tone,
      PCalloutTone.warning,
    );
    // 사유 칸 라벨에 "(선택)" 이 없고 부품의 "선택" 표시가 있다
    expect(_has(_l.withdrawReasonLabel), findsWidgets);
    expect(_l.withdrawReasonLabel, isNot(contains('선택')));
  });

  testWidgets('바깥을 눌러도 안 닫히고, 값이 있으면 ✕ 는 먼저 묻는다', (tester) async {
    await _open(tester, _Repo());
    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();
    expect(_t(_l.withdrawIntro), findsOneWidget, reason: '입력 폼은 바깥으로 안 닫힌다');

    // 값 없음 → 바로 닫힘
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(_t(_l.withdrawIntro), findsNothing);

    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '써 보니 어려웠어요');
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    expect(_has(_l.sheetLeaveTitle), findsWidgets);
    await tester.tap(_has(_l.sheetLeaveStay).last);
    await tester.pumpAndSettle();
    expect(_t(_l.withdrawIntro), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
    await tester.pumpAndSettle();
    await tester.tap(_has(_l.sheetLeaveLeave).last);
    await tester.pumpAndSettle();
    expect(_t(_l.withdrawIntro), findsNothing);
  });

  testWidgets('막힘 — Callout warning · 바닥 없음', (tester) async {
    await _open(
      tester,
      _Repo(
        check_: const WithdrawalCheck(
          blocked: [WithdrawalCheck.blockSubscription],
          subscriptionPeriodEnd: '2026-12-31T00:00:00',
          sharedCalendarsOwned: 0,
          calendarMemberships: 0,
          dutchPaysOwned: 0,
          dutchPayParticipations: 0,
        ),
      ),
    );
    expect(find.byType(PButton), findsNothing);
    final callout = tester.widget<PCallout>(find.byType(PCallout));
    expect(callout.tone, PCalloutTone.warning);
    expect(callout.description, _l.withdrawBlockedHint);
    expect(callout.description, isNot(contains('시면')));
  });

  testWidgets('2단계 코드 — 붙여넣기 뒤 6자리로 자름 · 6자리 전 누르면 칸 오류 · 다시 받기 60초', (
    tester,
  ) async {
    final repo = _Repo();
    await _open(tester, repo);
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    final pair = tester.widgetList<PButton>(find.byType(PButton)).toList();
    expect(pair.map((b) => b.label), contains(_l.actionBack));
    expect(
      pair.firstWhere((b) => b.label == _l.withdrawConfirm).variant,
      PButtonVariant.criticalSolid,
    );
    expect(
      pair.firstWhere((b) => b.label == _l.actionBack).variant,
      PButtonVariant.neutralWeak,
    );

    await tester.tap(findText(_l.withdrawUseEmailCode));
    await tester.pumpAndSettle();
    expect(findText(keepAll(_l.withdrawCodeDescription)), findsOneWidget);
    expect(find.byType(PInputOtp), findsOneWidget);

    // 코드를 보내기 전 — [코드 받기]
    await tester.tap(findText(_l.withdrawSendCode));
    await tester.pumpAndSettle();
    expect(repo.sent, 1);
    expect(findText(_l.withdrawResendCooldown(60)), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '인증 코드: 123456');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '123456',
    );

    await tester.enterText(find.byType(TextField).first, '123');
    await tester.pump();
    final confirm = tester.widget<PButton>(
      findWidgetWithText(PButton, _l.withdrawConfirm),
    );
    expect(confirm.onPressed, isNotNull, reason: '6자리 전에도 켜 둔다');
    await tester.tap(findText(_l.withdrawConfirm));
    await tester.pumpAndSettle();
    expect(findText(keepAll(_l.withdrawCodeIncomplete)), findsOneWidget);
    expect(repo.withdrawCalls, 0);
  });

  testWidgets('틀린 코드는 서버 글 대신 화면 글 · 덮개는 걷힌다', (tester) async {
    final repo = _Repo(
      verifyCode: (_) async =>
          throw ApiException(code: 'AUTH_021', message: 'server raw'),
    );
    await _open(tester, repo);
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    await tester.tap(findText(_l.withdrawUseEmailCode));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(findText(_l.withdrawConfirm));
    await tester.pumpAndSettle();
    expect(findText(keepAll(_l.withdrawCodeWrong)), findsOneWidget);
    expect(findText('server raw'), findsNothing);
    expect(find.byType(PBusyScrimLayer), findsNothing);
    expect(find.byType(PProgressCircle), findsNothing);
  });

  testWidgets('해지하는 동안 1초 뒤 덮개 · 뒤 화면 의미 트리에서 빠짐', (tester) async {
    final sem = tester.ensureSemantics();
    final gate = Completer<void>();
    final repo = _Repo()..withdrawGate = gate;
    await _open(tester, repo);
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'secret');
    await tester.pump();
    await tester.tap(findText(_l.withdrawConfirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('busy-scrim-circle')), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    final circle = tester.widget<PProgressCircle>(
      find.byKey(const ValueKey('busy-scrim-circle')),
    );
    expect(circle.semanticsLabel, _l.withdrawBusy);
    expect(circle.size, PProgressCircleSize.s40);
    final labels = [
      for (final n in tester.semantics.simulatedAccessibilityTraversal())
        n.label,
    ];
    expect(labels, contains(_l.withdrawBusy));
    expect(labels.any((s) => s.contains(_l.withdrawConfirm)), isFalse);
    gate.complete();
    await tester.pumpAndSettle();
    expect(findText('DONE'), findsOneWidget);
    expect(find.byType(PBusyScrimLayer), findsNothing);
    sem.dispose();
  });

  testWidgets('전환 링크는 칸 아래 줄 끝(오른쪽) · 스팸함 안내는 다시 받기 아래', (tester) async {
    await _open(tester, _Repo());
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    final link = tester.getRect(
      findWidgetWithText(PButton, _l.withdrawUseEmailCode),
    );
    expect(link.right, greaterThan(360 - 24 - 24), reason: '오른쪽 끝에 붙는다');
    await tester.tap(findText(_l.withdrawUseEmailCode));
    await tester.pumpAndSettle();
    // 사용자 결정(10-24) 05-2 Q1 A — 스팸함 안내는 코드를 보낸 뒤에만 보인다
    expect(
      findTextContaining(_l.withdrawCodeHint),
      findsNothing,
      reason: '보내기 전엔 없다',
    );
    await tester.tap(findText(_l.withdrawSendCode));
    await tester.pumpAndSettle();
    // 보낸 뒤 안내는 "메일로 코드를 보냈어요. {스팸함 안내}" 한 줄이다(2182327a)
    final hintText = '${_l.withdrawCodeSent} ${_l.withdrawCodeHint}';
    expect(_t(hintText), findsOneWidget);
    final resend = tester.getRect(
      findWidgetWithText(PButton, _l.withdrawResendCooldown(60)),
    );
    final hint = tester.getRect(_t(hintText));
    expect(hint.top - resend.bottom, closeTo(PSpacing.x3, 1), reason: '12');
    final back = tester.getRect(
      findWidgetWithText(PButton, _l.withdrawUsePassword),
    );
    // [비밀번호로 확인하기] 위 틈 = 16(웹 gap-x4 와 같은 값)
    expect(back.top - hint.bottom, closeTo(PSpacing.x4, 1));
    expect(back.right, greaterThan(360 - 24 - 24));
  });

  testWidgets('코드 확인 실패는 갈래별 — 틀림은 코드 글, 네트워크는 해지 실패 글', (tester) async {
    final repo = _Repo(
      verifyCode: (_) async =>
          throw ApiException(code: 'NETWORK', message: 'net raw'),
    );
    await _open(tester, repo);
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    await tester.tap(findText(_l.withdrawUseEmailCode));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(findText(_l.withdrawConfirm));
    await tester.pumpAndSettle();
    expect(findText(keepAll(_l.withdrawFailed)), findsOneWidget);
    expect(_t(_l.withdrawCodeWrong), findsNothing);
    expect(findText('net raw'), findsNothing);
  });

  testWidgets('비밀번호 틀림은 화면 글 · 서버 글을 그대로 내지 않는다', (tester) async {
    final repo = _Repo(
      verifyPw: (_) async =>
          throw ApiException(code: 'AUTH_021', message: 'raw pw'),
    );
    await _open(tester, repo);
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    // 비밀번호 칸 자리 글 = 웹과 같은 글
    expect(
      tester.widget<PInput>(find.byType(PInput).first).placeholder,
      _l.withdrawPasswordPlaceholder,
    );
    await tester.enterText(find.byType(TextField).first, 'wrong');
    await tester.pump();
    await tester.tap(findText(_l.withdrawConfirm));
    await tester.pumpAndSettle();
    expect(findText(keepAll(_l.withdrawPasswordWrong)), findsOneWidget);
    expect(findText('raw pw'), findsNothing);
  });

  for (final code in [true, false]) {
    testWidgets('5번 틀려 잠기면(AUTH_022) ${code ? "코드" : "비밀번호"} 방식 모두 같은 글', (
      tester,
    ) async {
      final locked = ApiException(code: 'AUTH_022', message: 'raw lock');
      final repo = _Repo(
        verifyCode: (_) async => throw locked,
        verifyPw: (_) async => throw locked,
      );
      await _open(tester, repo);
      await tester.tap(findText(_l.withdrawNext));
      await tester.pumpAndSettle();
      if (code) {
        await tester.tap(findText(_l.withdrawUseEmailCode));
        await tester.pumpAndSettle();
      }
      await tester.enterText(
        find.byType(TextField).first,
        code ? '123456' : 'secret',
      );
      await tester.pump();
      await tester.tap(findText(_l.withdrawConfirm));
      await tester.pumpAndSettle();
      expect(_has(_l.withdrawLocked), findsWidgets);
      expect(_l.withdrawLocked, '5번 틀렸어요. 코드를 다시 받아주세요.');
      expect(findText('raw lock'), findsNothing);
      expect(findText(keepAll(_l.withdrawFailed)), findsNothing);
    });
  }

  testWidgets('불러오기 실패 — 제목 + 설명 + 다시 시도', (tester) async {
    await _open(tester, _Repo(failLoad: true));
    expect(_t(_l.withdrawLoadFailedTitle), findsOneWidget);
    expect(_t(_l.withdrawLoadFailedDescription), findsOneWidget);
    expect(findWidgetWithText(PButton, _l.actionRetry), findsOneWidget);
  });

  testWidgets('글자 200% · 다크 — 오류 없이 그려진다', (tester) async {
    await _open(tester, _Repo(), dark: true, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(findText(_l.withdrawNext));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('34 — 해지 문구에 옛 이름 desk 가 없고 처리방침과 같은 제목이다', () {
    for (final l in [AppLocalizationsKo(), AppLocalizationsEn()]) {
      for (final line in [
        l.accountWithdraw,
        l.accountWithdrawTitle,
        l.withdrawIntro,
        l.withdrawConfirm,
        l.withdrawFailed,
        l.withdrawBlockedSubscription,
        l.withdrawBlockedSubscriptionUntil('2026-12-31'),
        l.withdrawBlockedHint,
        l.withdrawnTitle,
        l.withdrawnBody,
      ]) {
        expect(line.toLowerCase(), isNot(contains('desk')), reason: line);
      }
    }
    // 그루 계정 처리방침 절 제목(PrivacyPolicyPage)과 같은 글 — 세 레포 문구 잠금
    expect(AppLocalizationsKo().accountWithdrawTitle, '그루 담다 이용 해지');
    expect(AppLocalizationsKo().withdrawnBody, contains('그루 담다를'));
  });
}
