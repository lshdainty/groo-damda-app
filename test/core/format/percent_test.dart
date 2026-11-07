import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/core/format/percent.dart';

void main() {
  const under = '0.1% 미만';
  group('formatShare 비중 — 늘 소수 첫째 자리', () {
    test('경계 0 · 0.04 · 0.05 · 99.95 · 100', () {
      expect(formatShare(0, underOne: under), '0.0%');
      expect(formatShare(0.04, underOne: under), under);
      expect(formatShare(0.05, underOne: under), '0.1%');
      expect(formatShare(99.95, underOne: under), '100.0%');
      expect(formatShare(100, underOne: under), '100.0%');
    });
    test('늘 한 자리', () {
      expect(formatShare(30, underOne: under), '30.0%');
      expect(formatShare(58.14, underOne: under), '58.1%');
      expect(formatShare(double.nan, underOne: under), '0.0%');
    });
    test('formatShareOf — 합 0 이면 0.0%, 범례 합이 101 이 되지 않는다', () {
      expect(formatShareOf(5, 0, underOne: under), '0.0%');
      final parts = [581400, 215100, 151200, 46500, 5800];
      final total = parts.fold<int>(0, (a, b) => a + b);
      final sum = parts
          .map((p) => p * 100 / total)
          .map((v) => double.parse(v.toStringAsFixed(1)))
          .fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(100, 0.2));
    });
  });
  test('formatProgress 진행률 — 정수', () {
    expect(formatProgress(0), '0%');
    expect(formatProgress(76.43), '76%');
    expect(formatProgress(99.95), '100%');
    expect(formatProgress(112.5), '113%');
  });
}
