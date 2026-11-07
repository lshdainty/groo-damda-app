// 내보내기 공유 문구의 기간 — 밖으로 나가는 글이라 연도를 늘 넣는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/features/export/presentation/export_screen.dart';

void main() {
  setUpAll(() async => initializeDateFormatting());
  tearDown(() => Intl.defaultLocale = null);

  test('ko — "2026년 10월 1일~10월 31일"', () {
    Intl.defaultLocale = 'ko';
    expect(
      exportShareRange('2026-10-01', '2026-10-31'),
      '2026년 10월 1일~10월 31일',
    );
    expect(
      exportShareRange('2025-12-29', '2026-01-04'),
      '2025년 12월 29일~2026년 1월 4일',
    );
  });

  test('en — 같은 달 "Oct 1–31, 2026" · 같은 해 다른 달 "Oct 1–Nov 4, 2026"', () {
    Intl.defaultLocale = 'en';
    expect(exportShareRange('2026-10-01', '2026-10-31'), 'Oct 1–31, 2026');
    expect(exportShareRange('2026-10-01', '2026-11-04'), 'Oct 1–Nov 4, 2026');
  });

  test('en — 다른 해 "Dec 29, 2025–Jan 4, 2026"', () {
    Intl.defaultLocale = 'en';
    expect(
      exportShareRange('2025-12-29', '2026-01-04'),
      'Dec 29, 2025–Jan 4, 2026',
    );
    expect(exportShareRange('몰라', '2026-01-04'), isNull);
  });
}
