// 영어 문구의 달 · 개수 — QA "11 ledger" · "Month 11 total budget" · "1 categories" · "1 people" 의 회귀 시험(웹 #649 와 한 벌).
// ① 달은 숫자가 아니라 달 이름이다(international-design.mdx "날짜" · DESIGN.md 날짜 표 — 영어 달은 줄임 `MMM`:
//    "Sep 30" · "Wed, Sep 30"). 달 이름은 기존 날짜 유틸([monthNameOf] · [monthOnly] · [monthDay] · [yearMonth])이 만든다.
// ② 개수는 1 이면 단수다 — ARB ICU plural(`{count, plural, =1{…} other{…}}`). 쉼표를 넣은 글은 보이는 글로 따로 넘기고,
//    단 · 복수는 숫자로 고른다.
// 한국어는 그대로다(`{month}월` · "1명").
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> _values(Map<String, dynamic> arb) => {
  for (final e in arb.entries)
    if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
};

RecurringTransaction _rec({String? endDate}) => RecurringTransaction(
  rowId: 1,
  expenseType: 'EXPENSE',
  frequency: 'YEARLY',
  startDate: '2026-11-05',
  endDate: endDate,
);

/// 늘 2 이상이거나 고정 값인 자리 — 단수가 나올 수 없어 복수형으로 나누지 않는다(웹 #649 의 예외와 같은 성격).
const _alwaysMany = {
  // 상한(고정 값) — "{max} characters" · "up to {max} times"
  'nameTooLong',
  'savingGoalErrNameTooLong',
  'dsFieldCountSemantics',
  'recErrCountMax',
  // 할부는 2개월부터(kTxInstallmentMonths)
  'expInstallmentMonths',
  'txfInstallmentValue',
  // "n days ago" 는 2 ~ 6일 — 1일은 "Yesterday"(International Design "지난 시간")
  'dateDaysAgo',
  // 앞의 n건만 보일 때만 — 전체가 보이는 수보다 크다
  'importFailuresCapped',
  // 한 문장에 수가 셋(행 · 종류 · 합계) — 복수형 하나로 못 맞춘다. 따로 다룬다(웹 export:section.previewFooter 와 같다)
  'exportPreviewFooter',
};

void main() {
  final en = AppLocalizationsEn();
  final ko = AppLocalizationsKo();

  // 앱은 main.dart 에서 부른다 — 테스트도 같은 상태로.
  setUpAll(() async => initializeDateFormatting());
  tearDown(() => Intl.defaultLocale = null);

  group('달 — 영어는 달 이름(Nov), 한국어는 그대로(11월)', () {
    test('QA — 홈 가계부 제목 "11 ledger" → "Nov ledger"', () {
      Intl.defaultLocale = 'en';
      expect(en.dashMonthLedger(11, monthNameOf(11)), 'Nov ledger');
      expect(
        en.dashMonthLedger(11, monthOnly(DateTime(2026, 11))),
        'Nov ledger',
      );
      expect(
        en.dashCategoryChartLabel(11, '₩1,000', monthNameOf(11)),
        'Nov spending by category, total ₩1,000',
      );
      Intl.defaultLocale = 'ko';
      expect(ko.dashMonthLedger(11, monthNameOf(11)), '11월 가계부');
      expect(
        ko.dashCategoryChartLabel(11, '1,000원', monthNameOf(11)),
        '11월 카테고리별 지출, 합계 1,000원',
      );
    });

    test('예산 · 카드 실적 · 결제일 바꿈 확인', () {
      Intl.defaultLocale = 'en';
      final nov = monthNameOf(11);
      expect(en.budgetMonthOverallCap(11, nov), 'Nov total budget');
      expect(en.budgetMonthTotal(11, nov), 'Nov Total Budget');
      expect(en.budgetEmptyMonthTitle(11, nov), 'No budget for Nov yet');
      expect(en.assetPerfTitle('11', nov), 'Nov target');
      expect(
        en.assetPaymentDayChangeConfirm(11, 'Dec 25', nov),
        'The new payment day applies from the next cycle. '
        'Nov charges are still paid on Dec 25.',
      );
      Intl.defaultLocale = 'ko';
      expect(ko.budgetMonthOverallCap(11, monthNameOf(11)), '11월 총 예산');
      expect(ko.assetPerfTitle('11', monthNameOf(11)), '11월 실적');
    });

    test('반복 거래 — 매년 · 끝 달은 숫자 "11/5" · "12/2027" 가 아니다', () {
      Intl.defaultLocale = 'en';
      final it = _rec(endDate: '2027-12-31');
      expect(recCycleOf(en, it), 'Yearly on Nov 5');
      expect(recEndPiece(en, it), 'Until Dec 2027');
      Intl.defaultLocale = 'ko';
      expect(recCycleOf(ko, it), '매년 11월 5일');
      expect(recEndPiece(ko, it), '2027년 12월까지');
    });

    test('프리셋 마지막 쓴 날 · 일별 시세 날짜', () {
      Intl.defaultLocale = 'en';
      final d = DateTime(2026, 11, 5);
      expect(en.presetNoteLast(11, 5, monthDay(d)), 'Last used Nov 5');
      expect(en.stocksDailyDate(11, 5, monthDay(d)), 'Nov 5');
      Intl.defaultLocale = 'ko';
      expect(ko.presetNoteLast(11, 5, monthDay(d)), '마지막 11월 5일');
      expect(ko.stocksDailyDate(11, 5, monthDay(d)), '11월 5일');
    });

    test('지킴 — 한국어가 `{x}월` 인 문구의 영어는 그 숫자 달(`{x}`)을 쓰지 않는다', () {
      final koArb = _values(_arb('ko'));
      final enArb = _values(_arb('en'));
      final bad = <String>[];
      for (final e in koArb.entries) {
        for (final m in RegExp(r'\{(\w+)\}월').allMatches(e.value)) {
          final p = m.group(1)!;
          final v = enArb[e.key] ?? '';
          if (RegExp('\\{$p[},]').hasMatch(v)) bad.add('${e.key}: $v');
        }
      }
      expect(bad, isEmpty);
    });
  });

  group('개수 — 영어는 1 이면 단수', () {
    test('QA — 카테고리 · 사람', () {
      expect(en.budgetCategoryCount(1), '1 category');
      expect(en.budgetCategoryCount(2), '2 categories');
      expect(en.dutchNPeople(1), '1 person');
      expect(en.dutchNPeople(2), '2 people');
      expect(en.dutchFromPeople(1), 'from 1 person');
      expect(en.dutchToPeople(3), 'to 3 people');
      expect(ko.budgetCategoryCount(1), '1 카테고리');
      expect(ko.dutchNPeople(1), '1명');
    });

    test('대표 — 거래 · 주식 수 · 카드 수 · 반복 횟수 · 탈퇴 안내 · 가져오기', () {
      expect(en.expTxCount(1), '1 item');
      expect(en.expTxCount(3), '3 items');
      // 보이는 수는 쉼표를 넣은 글, 단 · 복수는 숫자로 고른다
      expect(en.stocksSharesUnit('1', 1), '1 share');
      expect(en.stocksSharesUnit('1,234', 1234), '1,234 shares');
      expect(en.stocksSharesUnit('0.5', 0.5), '0.5 shares');
      expect(en.cardTotalCount(1, '1'), '1 card');
      expect(en.cardTotalCount(1234, '1,234'), '1,234 cards');
      expect(ko.cardTotalCount(1234, '1,234'), '총 1,234장');
      expect(ko.stocksSharesUnit('1,234', 1234), '1,234주');
      expect(
        en.withdrawImpactCalendarsOwned(1),
        '1 shared calendar you created will be deleted — members lose access too',
      );
      expect(
        en.withdrawImpactDutchPayParticipations(2),
        'You will appear as "a former member" in 2 settlements you joined',
      );
      expect(en.recEndSentenceCount(1, 0), 'repeats 1 time (0 done)');
      expect(en.recEndSentenceCount(12, 3), 'repeats 12 times (3 done)');
      expect(en.importRowsDetected(1, 1), '1 row · 1 valid');
      expect(en.importRowsDetected(20, 18), '20 rows · 18 valid');
      expect(en.ttagUsage(1), 'Used by 1 to-do');
      expect(en.tdmTodayLeft(1), '1 to-do today');
      expect(ko.recEndSentenceCount(1, 0), '1번 반복해요(0번 했어요)');
    });

    test('지킴 — `{수} 명사s` 영어 문구는 복수형(plural)이다', () {
      final koArb = _arb('ko');
      final enArb = _values(_arb('en'));
      // 수를 담는 자리 — 한국어 템플릿이 숫자 타입으로 둔 것, 또는 수를 글로 넘기는 이름
      const countText = {'count', 'countText', 'n', 'qty', 'total', 'dup'};
      bool isCount(String key, String p) {
        final meta = koArb['@$key'] as Map<String, dynamic>?;
        final ph = meta?['placeholders'] as Map<String, dynamic>?;
        final type = (ph?[p] as Map<String, dynamic>?)?['type'];
        return countText.contains(p) ||
            type == 'int' ||
            type == 'num' ||
            type == 'double';
      }

      final noun = RegExp(
        r'\{(\w+)\}\s+(?:[A-Za-z-]+\s+){0,2}([a-z-]+s|people)\b',
      );
      // 수 뒤의 낱말이 명사가 아닌 것("{count} as fixed" · "in progress")
      final notNoun = RegExp(r'^(is|was|has|this|its|as|progress|less)$');
      final bad = <String>[];
      for (final e in enArb.entries) {
        if (_alwaysMany.contains(e.key)) continue;
        if (e.value.contains('(s)')) bad.add('${e.key}: ${e.value}');
        if (e.value.contains(', plural,')) continue;
        for (final m in noun.allMatches(e.value)) {
          if (isCount(e.key, m.group(1)!) && !notNoun.hasMatch(m.group(2)!)) {
            bad.add('${e.key}: ${e.value}');
          }
        }
      }
      expect(bad, isEmpty);
    });

    test('지킴 — 예외 목록은 실제로 있는 키다(지운 키가 남지 않게)', () {
      final enArb = _values(_arb('en'));
      expect(_alwaysMany.where((k) => !enArb.containsKey(k)), isEmpty);
    });
  });
}
