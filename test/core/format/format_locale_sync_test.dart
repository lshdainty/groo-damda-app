// 화면이 영어면 돈 · 날짜 포맷도 영어 — 시스템 따름이어도 같다(DESIGN.md 숫자 · 돈: 영어 = ₩1,234,567).
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';

void main() {
  tearDown(() => Intl.defaultLocale = null);

  test('영어 화면 — 전역 로케일 en, 돈은 ₩ 접두', () {
    syncIntlLocale(const Locale('en'));
    expect(localeIsEn(), isTrue);
    expect(krwSigned(1234567, false, unit: true), '₩1,234,567');
  });

  test('한국어 화면 · 지원하지 않는 언어 — ko, 돈은 원 접미', () {
    syncIntlLocale(const Locale('ko'));
    expect(krwSigned(1234567, false, unit: true), '1,234,567원');
    syncIntlLocale(const Locale('fr'));
    expect(localeIsEn(), isFalse);
  });

  test('영어에서 한국어로 되돌아온다', () {
    syncIntlLocale(const Locale('en'));
    syncIntlLocale(const Locale('ko'));
    expect(localeIsEn(), isFalse);
  });
}
