import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/krw.dart';

/// 가린 금액의 점은 어디서나 4개 — 공용 상수 [kHideMask] 하나만 쓴다(2026-11-25 사용자 결정, 웹 `HIDE_AMOUNTS_MASK` 와 같다).
/// 예외는 가계부 달력 칸(아주 좁은 칸)의 [kHideMaskNarrow] 2개뿐.
void main() {
  const core = 'lib/core/format/krw.dart';
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/gen'))
      .map((f) => (path: f.path, text: f.readAsStringSync()))
      .toList();

  test('기본은 4개, 좁은 칸 예외는 2개', () {
    expect(kHideMask, '••••');
    expect(kHideMaskNarrow, '••');
    expect(krwMasked(1250000, true), kHideMask);
    expect(krwSigned(1250000, true, unit: true), kHideMask);
  });

  test('점 두 개 이상을 직접 쓴 곳이 없다 — 상수 정의 파일만', () {
    final dots = RegExp(r'•{2,}|(\\u2022){2,}|(\\u\{2022\}){2,}');
    final hits = [
      for (final s in sources)
        if (s.path != core && dots.hasMatch(s.text)) s.path,
    ];
    expect(hits, isEmpty);
  });

  test('좁은 칸 예외는 가계부 달력 칸에서만 쓴다', () {
    final users = [
      for (final s in sources)
        if (s.path != core && s.text.contains('kHideMaskNarrow')) s.path,
    ];
    expect(users, [
      'lib/features/expense/presentation/widgets/ledger_header.dart',
    ]);
  });
}
