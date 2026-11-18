// 돈 단위 · 평균 반올림 · 금액 줄바꿈 — QA 2026-11-19(담다 앱 #600 · #601 재확인).
//
// ⓐ 문장 속 돈의 단위는 코드가 금액에 붙인다(krwWithUnit — ko "1,548원" · en "₩1,548"). 글(ARB)이 "원" 을 들고 숫자만 받던
//    자리는 영어에서 ₩ 가 빠졌다("Daily average 1,548 spent.")
// ⓑ 평균은 한 함수 · 한 반올림(half-up, DESIGN.md "반올림은 반올림") — 홈 1,548(버림) · 통계 비교 · 예산 1,549(반올림)이 갈렸다
// ⓒ 툴팁 금액은 쉼표 뒤에서만 줄을 바꾼다(DESIGN.md "줄바꿈" 의 금액 예외) — 세 자리 묶음 가운데서 갈라지지 않는다
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

void main() {
  tearDown(() => Intl.defaultLocale = null);

  group('ⓐ 단위는 금액에 붙는다', () {
    test('krwWithUnit — ko 원 · en ₩ · 음수', () {
      Intl.defaultLocale = 'ko';
      expect(krwWithUnit(1548), '1,548원');
      expect(krwWithUnit(-1000), '−1,000원');
      Intl.defaultLocale = 'en';
      expect(krwWithUnit(1548), '₩1,548');
      expect(krwWithUnit(-1000), '−₩1,000');
    });

    test('ARB — 글이 금액 단위를 들지 않는다(ko "{금액}원" · "원 썼어요" · en "₩{금액}" 이 0)', () {
      Map<String, dynamic> read(String f) =>
          jsonDecode(File('lib/l10n/$f').readAsStringSync())
              as Map<String, dynamic>;
      final ko = read('app_ko.arb');
      final en = read('app_en.arb');
      final hits = <String>[
        for (final e in ko.entries)
          if (!e.key.startsWith('@') &&
              e.value is String &&
              (RegExp(r'\{\w+\}\s?원').hasMatch(e.value as String) ||
                  RegExp(r'^원 [가-힣]+요').hasMatch(e.value as String)))
            'ko ${e.key}: ${e.value}',
        for (final e in en.entries)
          if (!e.key.startsWith('@') &&
              e.value is String &&
              (e.value as String).contains('₩{'))
            'en ${e.key}: ${e.value}',
      ];
      expect(hits, isEmpty);
    });
  });

  group('ⓑ 평균은 반올림(half-up)', () {
    test('averageWon', () {
      expect(
        averageWon(29430, 19),
        1549,
        reason: '1,548.9 → 1,549(버림이면 1,548)',
      );
      expect(averageWon(3, 2), 2, reason: '.5 는 올린다');
      expect(averageWon(5, 2), 3);
      expect(averageWon(1, 3), 0);
      expect(averageWon(100, 0), 0);
    });
  });

  testWidgets('ⓒ 툴팁 금액 — 쉼표 뒤에서만 줄을 바꾸는 금액 글(keepAllAmount) · 읽는 이름은 원래 글', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: const Scaffold(
          body: PChartTooltip(
            head: 'Nov 19',
            rows: [
              PChartTooltipRow(
                swatch: Colors.red,
                name: 'Spent',
                value: '₩1,234,567',
              ),
            ],
          ),
        ),
      ),
    );
    final value = find.byKey(const ValueKey('chart-tooltip-value'));
    final text = tester.widget<Text>(value);
    // 쉼표 뒤만 줄바꿈 자리(U+200B), 나머지 글자 사이는 이음(U+2060) — ₩ 와 숫자 · 세 자리 묶음이 갈라지지 않는다
    expect(text.data, keepAllAmount('₩1,234,567'));
    expect(text.data, contains(',\u200B'));
    expect(
      text.data!.replaceAll('\u2060', '').replaceAll('\u200B', ''),
      '₩1,234,567',
    );
    expect(text.semanticsLabel, '₩1,234,567');
  });
}
