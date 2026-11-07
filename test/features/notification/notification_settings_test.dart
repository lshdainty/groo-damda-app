// 알림 설정(I-15 48 ~ 54) — 푸시 끔(Q1 C) · 저장 실패 되돌림(M1) · 슬라이더 표식 하나 · 구역 설명 없음.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../../support/plain_text.dart';

class _NoAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

UserPreferences _prefs({bool push = true}) => UserPreferences(
  pushEnabled: push,
  notifyPayment: true,
  notifyBudget: true,
  notifyAutoRecord: true,
  notifyDutchPay: true,
  notifyCalendar: true,
  notifyWeeklyReport: false,
  notifyMonthlyReport: false,
  budgetAlertThreshold: 80,
  quietHoursEnabled: true,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  notificationSound: NotificationSound.defaultSound,
  vibrationEnabled: true,
  emailEnabled: true,
  emailFrequency: EmailFrequency.weekly,
  timezone: 'Asia/Seoul',
  defaultCurrency: 'KRW',
);

class _Repo extends UserPreferencesRepository {
  _Repo({this.push = true, this.fail = false}) : super(Dio());
  final bool push;
  bool fail;
  int updates = 0;

  @override
  Future<UserPreferences> get() async => _prefs(push: push);

  @override
  Future<UserPreferences> update(
    Map<String, dynamic> fields, {
    bool silent = false,
  }) async {
    updates++;
    expect(silent, isTrue, reason: '서버 글을 내보내지 않는다');
    if (fail) throw Exception('저장 실패');
    return _prefs(push: push);
  }
}

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userPreferencesRepositoryProvider.overrideWith((ref) async => repo),
        authProvider.overrideWith(_NoAuth.new),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (_, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
        home: const NotificationSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('구역 설명 줄이 없고 묶음 제목 다섯이 있다', (tester) async {
    await _pump(tester, _Repo());
    expect(findText('필요한 알림만 켜두면 더 편해요.'), findsNothing);
    for (final t in ['알림 종류', '예산 알림 기준', '방해 금지 시간', '소리 · 진동', '이메일 알림']) {
      expect(findText(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('예산 기준 양 끝 표식은 한 벌만 그려진다', (tester) async {
    await _pump(tester, _Repo());
    expect(findText('50%'), findsOneWidget);
    expect(findText('100%'), findsOneWidget);
  });

  testWidgets('푸시를 끄면 종류 · 방해 금지 · 소리 · 진동이 막히고 이메일은 그대로다', (tester) async {
    await _pump(tester, _Repo(push: false));
    final switches = tester.widgetList<PListSwitchItem>(
      find.byType(PListSwitchItem),
    );
    // 푸시 · 이메일은 켜져 있고 나머지(종류 7 + 방해 금지 + 진동)는 막힘
    final enabled = switches
        .where((s) => s.onChanged != null)
        .map((s) => s.title);
    expect(enabled, ['푸시 알림', '이메일 받기']);
    // 방해 금지가 켜져 있어도 푸시가 꺼지면 시작 줄이 막혀 값은 그대로 보인다
    expect(findText('오후 10:00'), findsOneWidget);
  });

  testWidgets('저장하지 못하면 스위치가 되돌아가고 고정 글 띠가 뜬다 — 다시 시도 없음', (tester) async {
    final repo = _Repo(fail: true);
    await _pump(tester, repo);
    await tester.tap(findText('결제 알림'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.updates, 1);
    final row = tester.widget<PListSwitchItem>(
      findWidgetWithText(PListSwitchItem, '결제 알림'),
    );
    expect(row.checked, isTrue, reason: '낙관 반영이 서버 값으로 되돌아온다');
    expect(findText('알림 설정을 저장하지 못했어요. 잠시 뒤 다시 시도해주세요.'), findsOneWidget);
    expect(findText('다시 시도'), findsNothing);
  });
}
