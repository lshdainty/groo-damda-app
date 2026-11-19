// I-08 53 — 예산 · 저축 목표 en 글은 웹과 한 벌이다. 판정(2026-10-24): 영문 실패 · 안내 글에 "the" 를 넣는다
// (Couldn't load budgets(복수라 the 없음) · the saving goals · lower the category limits).
// 월 눈썹은 달 이름이다 — "Oct total budget"(International Design 날짜: 영어 달은 줄임 MMM, 웹 #649 와 한 벌).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';

void main() {
  final l = AppLocalizationsEn();

  test('"the" 가 든 세 글', () {
    expect(l.budgetManagerLoadFailed, "Couldn't load budgets");
    expect(l.savingGoalFailTitle, "Couldn't load the saving goals");
    expect(
      l.budgetOverAllocatedWarning('₩1'),
      'Category limits exceed the total budget by ₩1. '
      'Raise the total budget or lower the category limits.',
    );
  });

  test('이행률 실패 글 · 월 눈썹 · 예산 0 글', () {
    // 폰 예산 실패 글은 홈과 같은 키 — 복수라 the 없음
    expect(l.dashFailBudget, "Couldn't load budgets");
    expect(l.budgetFailCompliance, "Couldn't load the budget compliance");
    expect(l.budgetMonthOverallCap(10, 'Oct'), 'Oct total budget');
    expect(l.budgetEmptyMonthTitle(10, 'Oct'), 'No budget for Oct yet');
  });
}
