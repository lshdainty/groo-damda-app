// 구독 관리 화면 — 고른 주기의 planCode · 처음 주기 · 배지 · 주기 고르기 유무 · 요금제 0개(I-14 29 · 32).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/subscription_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';
import '../../support/plain_text.dart';

const _monthly = SubscriptionPlanInfo(
  planCode: 'M',
  planName: '담다 Pro',
  durationMonths: 1,
  price: 9900,
);
const _yearly = SubscriptionPlanInfo(
  planCode: 'Y',
  planName: '담다 Pro 연간',
  durationMonths: 12,
  price: 99000,
);

class _FakeRepo extends SubscriptionRepository {
  _FakeRepo() : super(Dio());
  String? sent;
  bool? sentSilent;

  @override
  Future<void> subscribe(String planCode, {bool silent = false}) async {
    sent = planCode;
    sentSilent = silent;
  }
}

String _end() {
  final iso = DateTime.now()
      .toUtc()
      .add(const Duration(days: 30))
      .toIso8601String();
  return iso.substring(0, iso.length - 1);
}

Future<_FakeRepo> _open(
  WidgetTester tester, {
  required List<SubscriptionPlanInfo> plans,
  SubscriptionInfo? sub,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWith((ref) async => repo),
        mySubscriptionProvider.overrideWith((ref) async => sub),
        subscriptionPlansProvider.overrideWith((ref) async => plans),
        myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const SubscriptionScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  final l = AppLocalizationsKo();

  testWidgets('연간을 골라 [Pro 시작하기] 를 누르면 연간 planCode 를 보낸다', (tester) async {
    final repo = await _open(tester, plans: [_monthly, _yearly]);
    await tester.tap(findPlain(l.subCycleYearlyOff(17)));
    await tester.pumpAndSettle();
    await tester.tap(findText(l.subStartPro));
    await tester.pumpAndSettle();
    expect(repo.sent, 'Y');
    expect(repo.sentSilent, isTrue, reason: '서버 글을 내지 않는다 — 요청은 silent');
  });

  testWidgets('처음은 월간 — 월간 planCode', (tester) async {
    final repo = await _open(tester, plans: [_monthly, _yearly]);
    await tester.tap(findText(l.subStartPro));
    await tester.pumpAndSettle();
    expect(repo.sent, 'M');
  });

  testWidgets('연간 구독자는 연간으로 서고 "현재 플랜" 은 구독 주기에서만 붙는다', (tester) async {
    await _open(
      tester,
      plans: [_monthly, _yearly],
      sub: SubscriptionInfo(
        planCode: 'Y',
        planName: '담다 Pro',
        status: 'ACTIVE',
        currentPeriodEnd: _end(),
        autoRenew: true,
        price: 99000,
        durationMonths: 12,
      ),
    );
    expect(findPlain('99,000원 / 년'), findsWidgets);
    expect(findPlain(l.subCurrentPlan), findsOneWidget);

    // 다른 주기(월간)를 누르면 배지 없이 가격만
    await tester.tap(findPlain(l.subCycleMonthly));
    await tester.pumpAndSettle();
    expect(findPlain(l.subCurrentPlan), findsNothing);
    expect(findPlain('9,900원 / 월'), findsOneWidget);
  });

  testWidgets('/me 에 가격 · 기간이 없어도 planCode 로 플랜에서 찾는다', (tester) async {
    await _open(
      tester,
      plans: [_monthly, _yearly],
      sub: SubscriptionInfo(
        planCode: 'Y',
        planName: '담다 Pro',
        status: 'ACTIVE',
        currentPeriodEnd: _end(),
        autoRenew: true,
      ),
    );
    expect(findPlain('99,000원 / 년'), findsWidgets);
  });

  testWidgets('연간 행이 없으면 주기 고르기 없이 월간 하나', (tester) async {
    await _open(tester, plans: [_monthly]);
    expect(findPlain(l.subCycleMonthly), findsNothing);
    expect(findPlain('9,900원 / 월'), findsOneWidget);
  });

  testWidgets('할인이 없으면(연간이 12달 이상) 할인 표시가 없다', (tester) async {
    await _open(
      tester,
      plans: [
        _monthly,
        const SubscriptionPlanInfo(
          planCode: 'Y',
          planName: '연간',
          durationMonths: 12,
          price: 118800,
        ),
      ],
    );
    expect(findPlain(l.subCycleYearly), findsOneWidget);
    expect(findTextContaining('%'), findsNothing);
  });

  testWidgets('요금제가 0개면 시작 단추 대신 실패 화면', (tester) async {
    await _open(tester, plans: const []);
    expect(findPlain(l.subLoadFailed), findsOneWidget);
    expect(findText(l.subStartPro), findsNothing);
  });
}
