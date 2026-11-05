// 구독 가격은 서버 값이다 — 앱에 9,900 · 99,000 · 할인율 17 을 박아 두지 않는다(I-14 29 · 34).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';

void main() {
  test('연간 할인율 = round((1 − 연간 ÷ (월간 × 12)) × 100) — 서버 두 가격으로 계산한다', () {
    expect(yearlySavePct(9900, 99000), 17);
    expect(yearlySavePct(10000, 100000), 17);
    expect(yearlySavePct(5000, 60000), 0);
    expect(yearlySavePct(0, 99000), 0);
  });

  test('요금제 · 구독 JSON — 가격 · 기간을 읽고, 옛 서버 응답(칸 없음)에도 죽지 않는다', () {
    final plan = SubscriptionPlanInfo.fromJson({
      'planCode': 'SECURITIES_YEARLY',
      'planName': '담다 Pro 연간',
      'durationMonths': 12,
      'price': 99000,
    });
    expect(plan.price, 99000);
    expect(plan.durationMonths, 12);

    final old = SubscriptionPlanInfo.fromJson({
      'planCode': 'SECURITIES',
      'planName': '담다 Pro',
    });
    expect(old.price, isNull);

    final sub = SubscriptionInfo.fromJson({
      'planCode': 'SECURITIES_YEARLY',
      'planName': '담다 Pro',
      'status': 'ACTIVE',
      'autoRenew': true,
      'price': 99000,
      'durationMonths': 12,
    });
    expect(sub.price, 99000);
    expect(sub.durationMonths, 12);
    expect(
      SubscriptionInfo.fromJson({
        'planCode': 'S',
        'planName': 'P',
        'status': 'ACTIVE',
      }).price,
      isNull,
    );
  });
}
