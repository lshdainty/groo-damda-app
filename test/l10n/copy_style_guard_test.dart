// 글쓰기 규칙 가드 — arb 전수(ko · en)로 다시 생기지 않게 잠근다.
// 근거: DESIGN.desk.md Writing 가운뎃점(11-07) — 가운뎃점은 앞뒤를 띄우고, 구간 기호 "~" 는 붙이고(로케일 문구
// `dateRangeSeparator`), 글은 해요체다(합니다체 금지).
//
// 걸리면 글을 고친다. 허용 목록을 늘리려면 사용자 결정이 있어야 한다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 사용자 결정으로 합니다체를 남긴 키 — withdrawn "감사했습니다" (2026-09-22, 이용 해지 완료 화면 인사).
const _politeAllowed = {'withdrawnBody'};

Map<String, String> _load(String lang) {
  final raw =
      jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

List<String> _offenders(
  Map<String, String> arb,
  RegExp pattern, {
  Set<String> allowed = const {},
}) => [
  for (final e in arb.entries)
    if (!allowed.contains(e.key) && pattern.hasMatch(e.value))
      '${e.key}: ${e.value}',
];

void main() {
  for (final lang in const ['ko', 'en']) {
    final arb = _load(lang);

    test('$lang — 가운뎃점은 앞뒤를 띄운다 ("계좌 · 카드")', () {
      // U+00B7 한 글자가 공백 없이 글자에 붙은 곳(앞이나 뒤 어느 한쪽이라도)
      expect(_offenders(arb, RegExp('(?<! )·|·(?! )')), isEmpty);
    });

    test('$lang — 구간 기호 "~" 는 띄우지 않는다 (붙임 + 로케일 구간 기호)', () {
      // 줄바꿈 없는 공백(U+00A0 · U+202F)으로 띄운 것도 띄운 것이다
      expect(
        _offenders(arb, RegExp('[ \u00A0\u202F]~|~[ \u00A0\u202F]')),
        isEmpty,
      );
    });

    if (lang == 'en') {
      test('en — 구간 기호는 "~" 가 아니라 en dash(로케일 문구 dateRangeSeparator)', () {
        expect(_offenders(arb, RegExp('~')), isEmpty);
      });
    }
  }

  test('ko — 합니다체를 쓰지 않는다 (해요체)', () {
    final arb = _load('ko');
    expect(
      _offenders(
        arb,
        // 평서 · 의문(습니까) 모두
        RegExp(r'[가-힣]니(?:다|까)(?=[.!?,\s)…]|$)'),
        allowed: _politeAllowed,
      ),
      isEmpty,
    );
  });
}
