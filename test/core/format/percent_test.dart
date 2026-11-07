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
    });
    test('웹과 같은 반올림 — 이진 오차로 갈리던 동점(Math.round 식)', () {
      expect(formatShare(12.35, underOne: under), '12.4%');
      expect(formatShare(58.15, underOne: under), '58.2%');
      expect(formatShare(0.15, underOne: under), '0.2%');
      expect(formatShare(0.35, underOne: under), '0.4%');
      expect(formatShare(1.15, underOne: under), '1.2%');
      expect(formatShare(1235 * 100 / 10000, underOne: under), '12.4%');
    });
    test('경계 — NaN · 무한은 "—", 음수는 부호 그대로(웹 기준)', () {
      expect(formatShare(double.nan, underOne: under), '—');
      expect(formatShare(double.infinity, underOne: under), '—');
      expect(formatShare(double.negativeInfinity, underOne: under), '—');
      expect(formatShare(-3, underOne: under), '−3.0%');
      expect(formatShare(-2.5, underOne: under), '−2.5%');
      expect(formatShare(-0.04, underOne: under), '0.0%');
    });
    test('formatShareOf — 합 0 이면 0.0%, 범례 합이 101 이 되지 않는다', () {
      expect(formatShareOf(5, 0, underOne: under), '0.0%');
      // 0 자리 반올림이면 58 + 22 + 15 + 5 + 1 = 101 이던 자료
      final parts = [581400, 215100, 151200, 46500, 5800];
      final total = parts.fold<int>(0, (a, b) => a + b);
      final shown = [
        for (final p in parts) formatShareOf(p, total, underOne: under),
      ];
      expect(shown, ['58.1%', '21.5%', '15.1%', '4.7%', '0.6%']);
      final sum = shown
          .map((t) => double.parse(t.replaceAll('%', '')))
          .fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(100, 0.2));
    });
  });
  test('formatProgress 진행률 — 정수 반올림, 100 경계만 예외(웹과 같은 표)', () {
    final table = <double, String>{
      0: '0%',
      76.4: '76%',
      76.43: '76%',
      76.6: '77%',
      99.4: '99%',
      99.6: '99%', // 반올림하면 100 → 99
      99.95: '99%',
      100: '100%',
      100.3: '101%', // 반올림하면 100 → 101
      100.6: '101%',
      112.5: '113%',
      -2.5: '−3%',
      -76.6: '−77%',
      -0.2: '0%',
    };
    table.forEach((v, want) => expect(formatProgress(v), want, reason: '$v'));
    expect(formatProgress(double.nan), '—');
    expect(formatProgress(double.infinity), '—');
    expect(formatProgress(double.negativeInfinity), '—');
  });
}
