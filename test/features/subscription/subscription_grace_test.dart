// 해지 뒤 **유예 기간** — 돈 낸 기간이 남은 사람을 Free 취급하지 않는다.
//
// 서버(desk-back #332)는 해지해도 만료일을 앞당기지 않는다. 응답은
// `status=CANCELLED` · `autoRenew=false` · `currentPeriodEnd=<미래>` 로 남고
// `features` 에도 `SECURITIES` 가 그대로 있어 증권 기능은 열려 있다.
// 앱이 `status == 'ACTIVE'` 만 보던 동안 시트는 그 사람에게 "Free 플랜 이용 중" 과
// "Pro 시작하기" 를 내밀었다 — 이미 구독 중이라 서버가 거절하는 버튼이다.
//
// 문구도 같이 갈린다. 해지한 구독에 **다음 결제는 없다** — 그 날짜는 결제일이
// 아니라 이용이 끝나는 날이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import '../../support/plain_text.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/presentation/subscription_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

/// 서버가 주는 모양 — `LocalDateTime` 직렬화라 **시간대 표시가 없다**(UTC 벽시계).
/// 여기서 `Z` 를 붙여 두면 정작 고쳐야 할 경로(무표시 → UTC 로 읽기)를 안 지난다.
String _serverUtc(Duration offset) {
  final iso = DateTime.now().toUtc().add(offset).toIso8601String();
  return iso.endsWith('Z') ? iso.substring(0, iso.length - 1) : iso;
}

SubscriptionInfo _sub({
  required String status,
  String? currentPeriodEnd,
  bool autoRenew = true,
}) => SubscriptionInfo(
  planCode: 'SECURITIES',
  planName: '담다 Pro',
  status: status,
  currentPeriodEnd: currentPeriodEnd,
  autoRenew: autoRenew,
  price: 9900,
  durationMonths: 1,
);

const _plans = [
  SubscriptionPlanInfo(
    planCode: 'SECURITIES',
    planName: '담다 Pro',
    durationMonths: 1,
    price: 9900,
  ),
  SubscriptionPlanInfo(
    planCode: 'SECURITIES_YEARLY',
    planName: '담다 Pro 연간',
    durationMonths: 12,
    price: 99000,
  ),
];

Widget _app(SubscriptionInfo? sub) => ProviderScope(
  overrides: [
    mySubscriptionProvider.overrideWith((ref) async => sub),
    subscriptionPlansProvider.overrideWith((ref) async => _plans),
    myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
  ],
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: const SubscriptionScreen(),
  ),
);

Future<void> _openSheet(WidgetTester tester, SubscriptionInfo? sub) async {
  tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(sub));
  await tester.pumpAndSettle();
}

/// 계정 · 구독 화면이 같은 글 — 서버 값(9,900 · 1개월)에 "/ 월" 이 붙는다.
const _amount = '9,900원 / 월';

void main() {
  final l = AppLocalizationsKo();

  group('SubscriptionInfo.isActive', () {
    test('ACTIVE 는 종전대로 활성이다', () {
      expect(_sub(status: 'ACTIVE').isActive, isTrue);
      expect(
        _sub(
          status: 'ACTIVE',
          currentPeriodEnd: _serverUtc(const Duration(days: 30)),
        ).isActive,
        isTrue,
      );
    });

    test('CANCELLED + 남은 기간 = 활성 — 돈 낸 기간은 끝까지 Pro 다', () {
      expect(
        _sub(
          status: 'CANCELLED',
          currentPeriodEnd: _serverUtc(const Duration(days: 30)),
          autoRenew: false,
        ).isActive,
        isTrue,
      );
    });

    test('CANCELLED + 지난 기간 = 비활성', () {
      expect(
        _sub(
          status: 'CANCELLED',
          currentPeriodEnd: _serverUtc(const Duration(days: -1)),
          autoRenew: false,
        ).isActive,
        isFalse,
      );
    });

    test('날짜를 못 읽으면 종전 동작 — 보수적으로 비활성', () {
      // 만료일 없는(무제한) 해지까지 유예로 봐 주면 되돌아올 날이 없어 영영 안 막힌다.
      expect(_sub(status: 'CANCELLED').isActive, isFalse);
      expect(_sub(status: 'CANCELLED', currentPeriodEnd: '').isActive, isFalse);
      expect(
        _sub(status: 'CANCELLED', currentPeriodEnd: '언젠가').isActive,
        isFalse,
      );
      // 날짜만 있는 값(LocalDate)은 시간대가 없어 [parseServerUtc] 가 거부한다.
      expect(
        _sub(status: 'CANCELLED', currentPeriodEnd: '2099-01-01').isActive,
        isFalse,
      );
    });

    test('EXPIRED 등 다른 상태는 기간이 남아도 비활성이다', () {
      expect(
        _sub(
          status: 'EXPIRED',
          currentPeriodEnd: _serverUtc(const Duration(days: 30)),
        ).isActive,
        isFalse,
      );
    });
  });

  testWidgets('유예 기간 — Pro 로 보이고 "구독하기" 가 없다', (tester) async {
    final end = _serverUtc(const Duration(days: 30));
    await _openSheet(
      tester,
      _sub(status: 'CANCELLED', currentPeriodEnd: end, autoRenew: false),
    );

    expect(findPlain(l.subUsingPro), findsOneWidget);
    expect(findPlain(l.subUsingFree), findsNothing);

    // 이미 구독 중이고 서버가 재구독을 막는다 — 누를 수 없는 버튼을 내밀지 않는다.
    expect(findPlain(l.subStartPro), findsNothing);
    expect(findPlain(l.subCancel), findsOneWidget);
  });

  testWidgets('자동갱신이 꺼지면 날짜 라벨이 "다음 결제" 가 아니다', (tester) async {
    final end = _serverUtc(const Duration(days: 30));
    final date = localDateKey(end)!;
    await _openSheet(
      tester,
      _sub(status: 'CANCELLED', currentPeriodEnd: end, autoRenew: false),
    );

    // 유예 설명 = "{날짜}까지 이용 · {가격}"(웹과 같다)
    expect(findPlain('${l.subProUntil(date)} · $_amount'), findsOneWidget);
    expect(
      findPlain(l.subNextBilling(date, _amount)),
      findsNothing,
      reason: '해지한 구독에 다음 결제는 없다 — 없는 청구를 예고하면 안 된다',
    );
  });

  testWidgets('기간이 지난 해지는 Free 로 보인다', (tester) async {
    await _openSheet(
      tester,
      _sub(
        status: 'CANCELLED',
        currentPeriodEnd: _serverUtc(const Duration(days: -1)),
        autoRenew: false,
      ),
    );

    expect(findPlain(l.subUsingFree), findsOneWidget);
    expect(findPlain(l.subUsingPro), findsNothing);
    expect(findPlain(l.subStartPro), findsOneWidget);
  });

  testWidgets('자동갱신 중인 구독은 종전 문구 그대로다', (tester) async {
    final end = _serverUtc(const Duration(days: 30));
    final date = localDateKey(end)!;
    await _openSheet(tester, _sub(status: 'ACTIVE', currentPeriodEnd: end));

    expect(findPlain(l.subUsingPro), findsOneWidget);
    expect(findPlain(l.subNextBilling(date, _amount)), findsOneWidget);
    expect(findPlain(l.subProUntil(date)), findsNothing);
  });

  testWidgets('만료일이 없는 해지는 Free — 터지지 않는다', (tester) async {
    await _openSheet(tester, _sub(status: 'CANCELLED', autoRenew: false));

    expect(findPlain(l.subUsingFree), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜를 못 읽으면 문구도 종전 그대로다', (tester) async {
    await _openSheet(
      tester,
      _sub(status: 'ACTIVE', currentPeriodEnd: '언젠가', autoRenew: false),
    );

    // 자리 표시자만 있는 날짜에 "…까지 이용" 을 끼우면 더 이상해진다 — 종전 문구.
    expect(findPlain(l.subUsingPro), findsOneWidget);
    expect(
      findPlain(l.subNextBilling(l.subNextBillingDate, _amount)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
