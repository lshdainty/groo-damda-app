// 설정을 저장하는 도중에 화면을 닫아도 **터지지 않는다**.
//
// `userPreferencesProvider` 는 autoDispose 다(다음 진입 때 웹에서 바꾼 값을 다시
// 읽으려고 그렇게 뒀다). 그래서 PATCH 가 도는 중에 설정 화면을 닫으면 마지막
// 구독자가 사라져 element 가 폐기되고, `await` 뒤의 `state =` 가
// `UnmountedRefException` 을 던진다(riverpod 3.2.1
// `core/provider/notifier_provider.dart:89` → `core/ref.dart:230`).
// 아무도 안 기다리는 Future 라 그대로 처리되지 않은 비동기 에러가 된다.
//
// **더 나쁜 건 실패한 저장이다.** 롤백 `state = AsyncData(prev)` 는 `catch` 안에
// 있어서, 거기서 두 번째 예외가 나면 원래 실패 이유까지 통째로 삼킨다.
// 그래서 성공·실패 두 경로를 다 잠근다.
//
// 살아 있는지는 `ref.mounted`(`core/ref.dart:110`)로 본다 — 같은 소스가 공개로
// 내주는 값이고, 폐기 뒤에도 던지지 않고 `false` 를 돌려준다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/slider/p_slider.dart';

/// 로그인 조회를 네트워크로 내보내지 않는다 — 설정 화면이 이메일을 본다.
class _NoAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

UserPreferences _prefs(int threshold) => UserPreferences(
  pushEnabled: true,
  notifyPayment: true,
  notifyBudget: true,
  notifyAutoRecord: true,
  notifyDutchPay: true,
  notifyCalendar: true,
  notifyWeeklyReport: false,
  notifyMonthlyReport: false,
  budgetAlertThreshold: threshold,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  notificationSound: NotificationSound.defaultSound,
  vibrationEnabled: true,
  emailEnabled: false,
  emailFrequency: EmailFrequency.weekly,
  timezone: 'Asia/Seoul',
  defaultCurrency: 'KRW',
);

/// 서버 역할 — **PATCH 가 끝나는 시점을 테스트가 정한다.**
class _SlowPrefsRepo extends UserPreferencesRepository {
  _SlowPrefsRepo() : super(Dio());

  final Completer<void> inflight = Completer<void>();
  int threshold = 85;
  bool fail = false;
  final List<Map<String, dynamic>> patches = [];

  @override
  Future<UserPreferences> get() async => _prefs(threshold);

  @override
  Future<UserPreferences> update(
    Map<String, dynamic> fields, {
    bool silent = false,
  }) async {
    patches.add(fields);
    await inflight.future;
    if (fail) throw Exception('저장 실패');
    threshold = fields['budgetAlertThreshold'] as int? ?? threshold;
    return _prefs(threshold);
  }
}

void main() {
  late _SlowPrefsRepo repo;
  late ProviderContainer container;

  Future<void> openSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repo = _SlowPrefsRepo();
    container = ProviderContainer(
      overrides: [
        userPreferencesRepositoryProvider.overrideWith((ref) async => repo),
        authProvider.overrideWith(_NoAuth.new),
        // 게이지가 읽는 별개 조회 — 저장이 끝나면 화면 밖에서 비워진다.
        budgetAlertThresholdProvider.overrideWith(
          (ref) async => repo.threshold,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 슬라이더를 [v] 로 민다 — `_ThresholdBlock` 가 건 콜백 그대로 탄다.
  Future<void> slideTo(WidgetTester tester, double v) async {
    tester.widget<PSlider>(find.byType(PSlider)).onChangeEnd!(v);
    await tester.pump();
    expect(repo.patches, hasLength(1), reason: 'PATCH 가 나가 있어야 이 테스트가 무언가를 본다');
  }

  /// 화면을 닫는다 — 마지막 구독자가 사라져 autoDispose 가 element 를 걷는다.
  Future<void> closeSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold()),
      ),
    );
    await tester.pump();
    expect(
      container.exists(userPreferencesProvider),
      isFalse,
      reason: 'element 가 안 걷히면 `state =` 가 던질 일도 없어 이 테스트는 아무것도 안 본다',
    );
  }

  testWidgets('저장이 끝나기 전에 설정 화면을 닫아도 터지지 않는다', (tester) async {
    await openSettings(tester);
    await slideTo(tester, 70);
    await closeSettings(tester);

    repo.inflight.complete();
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: '폐기된 notifier 에 `state =` 를 쓰면 UnmountedRefException 이 난다',
    );
    expect(repo.threshold, 70, reason: '서버엔 들어갔다 — 화면이 닫힌 것과 별개다');
  });

  testWidgets('저장이 실패한 채로 화면을 닫아도 롤백이 다시 던지지 않는다', (tester) async {
    await openSettings(tester);
    repo.fail = true;
    await slideTo(tester, 70);
    await closeSettings(tester);

    repo.inflight.complete();
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'catch 안의 롤백이 두 번째 예외를 만들면 원래 실패 이유까지 삼킨다',
    );
    expect(repo.threshold, 85, reason: '저장은 실패했으니 서버 값은 그대로다');
  });
}
