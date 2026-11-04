// 카드 혜택 글 만들기(I-20 E 32 · 34) — 웹 card-format.test.ts 와 같은 갈래.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l;
  setUp(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  test('commaDigits — 네 자리 이상 숫자에만 쉼표', () {
    expect(commaDigits('국내 5000원'), '국내 5,000원');
    expect(commaDigits('국내 500원'), '국내 500원');
    expect(commaDigits('12000 / 150000'), '12,000 / 150,000');
    // int 를 넘는 숫자는 예외 없이 원문 그대로
    expect(commaDigits('99999999999999999999999'), '99999999999999999999999');
  });

  test('줄 연회비 — 금액 · 라벨 · 무료 · 모름 네 갈래', () {
    expect(annualFeeRowText(l, null), '연회비 정보 없음');
    expect(
      annualFeeRowText(l, const CardAnnualFee(amount: 1234567)),
      '연회비 1,234,567원',
    );
    expect(
      annualFeeRowText(l, const CardAnnualFee(amount: 0, label: '국내 5000원')),
      '연회비 국내 5,000원',
    );
    expect(annualFeeRowText(l, const CardAnnualFee(amount: 0)), '연회비 없음');
  });

  test('줄 · 상세 실적 — 필수일 때만 금액, 아니면 실적 없음', () {
    const must = CardPerformance(requiredAmount: 300000, isRequired: 'Y');
    const no = CardPerformance(requiredAmount: 300000, isRequired: 'N');
    expect(performanceRowText(l, must), '실적 300,000원');
    expect(performanceRowText(l, no), '실적 없음');
    expect(performanceRowText(l, null), '실적 없음');
    expect(performanceDetailText(l, must), '300,000원 이상');
    expect(performanceDetailText(l, no), '실적 없음');
    expect(
      performanceDetailText(
        l,
        const CardPerformance(requiredText: '월 30만 원', isRequired: 'Y'),
      ),
      '월 30만 원',
    );
  });

  test('상세 연회비 — 금액은 국내전용, 라벨은 쉼표, 없으면 무료 · 정보 없음', () {
    expect(annualFeeDetailText(l, null), '정보 없음');
    expect(
      annualFeeDetailText(l, const CardAnnualFee(amount: 15000)),
      '국내전용 15,000원',
    );
    expect(
      annualFeeDetailText(l, const CardAnnualFee(amount: 0, label: '국내 5000원')),
      '국내 5,000원',
    );
    expect(annualFeeDetailText(l, const CardAnnualFee(amount: 0)), '무료');
  });

  test('혜택 유형은 셋뿐 — 캐시백 없음, 설명 조각 순서', () {
    expect(benefitTypeText(l, 'POINT'), '적립');
    expect(benefitTypeText(l, 'CASHBACK'), isNull);
    expect(kBenefitFilterValues, [null, 'DISCOUNT', 'POINT', 'MILEAGE']);
    final s = CardCatalogSummary(
      rowId: 1,
      cardName: '지어낸 카드',
      company: const CardCompany(name: '신한카드'),
      cardType: 'CREDIT',
      benefitType: 'MILEAGE',
    );
    expect(cardMetaParts(l, s), ['신한카드', '신용', '마일리지']);
  });

  decodeHtmlTests();
}

// HTML 엔티티 풀기 — 웹 decodeHtml 과 같은 규칙
void decodeHtmlTests() {
  test('decodeHtml 숫자 · 16진 · 이름 엔티티', () {
    expect(decodeHtml('Mc&#39;D · A &amp; B'), "Mc'D · A & B");
    expect(decodeHtml('&#x41;&middot;&unknown;'), 'A·&unknown;');
    expect(decodeHtml(null), '');
    expect(decodeHtml('&#99999999;'), '&#99999999;');
  });
}
