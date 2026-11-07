import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/features/stats/domain/fixed_split.dart';

void main() {
  group('splitFixed — 전체 · 고정 · 변동', () {
    test('변동은 전체에서 고정을 뺀 값이다', () {
      final s = splitFixed(1530000, 1400000);
      expect(s.total, 1530000);
      expect(s.fixed, 1400000);
      expect(s.variable, 130000);
      expect(s.fixedShare, 91.5);
      expect(s.variableShare, 8.5);
    });

    test('옛 서버가 고정을 안 보내면 전부 변동이다 — 기존 화면 그대로', () {
      final s = splitFixed(500000, null);
      expect(s.fixed, 0);
      expect(s.variable, 500000);
      expect(s.fixedShare, 0);
    });

    test('전체가 0 이면 비율도 0 이다 — 0 으로 나누지 않는다', () {
      final s = splitFixed(0, 0);
      expect((s.total, s.fixed, s.variable, s.fixedShare), (0, 0, 0, 0));
    });

    test('고정이 전체를 넘어도 변동이 음수가 되지 않는다', () {
      final s = splitFixed(100, 150);
      expect(s.fixed, 100);
      expect(s.variable, 0);
      expect(s.fixedShare, 100);
    });

    test('음수·null 은 0 으로 본다', () {
      expect(splitFixed(-5, 3).total, 0);
      expect(splitFixed(100, -3).fixed, 0);
      expect(splitFixed(null, null).total, 0);
    });
  });

  group('화면 비중 — 소수 첫째 자리, 합 100.0', () {
    test('1/3 → 33.3 + 66.7', () {
      final s = splitFixed(3, 1);
      expect(s.fixedShare, 33.3);
      expect(s.variableShare, 66.7);
    });
    test('0.05% 미만은 반올림하지 않는다 — 고정 · 변동 어느 쪽이든', () {
      expect(splitFixed(100000, 10).fixedShare, lessThan(0.05));
      expect(splitFixed(100000, 10).fixedShare, greaterThan(0));
      expect(splitFixed(100000, 99990).variableShare, lessThan(0.05));
      expect(splitFixed(100000, 99990).variableShare, greaterThan(0));
    });
    test('전체 0 이면 0', () {
      final s = splitFixed(0, 0);
      expect((s.fixedShare, s.variableShare), (0, 0));
    });
  });

  test('amountFor — 보기에 맞는 금액', () {
    final s = splitFixed(1000, 700);
    expect(amountFor(s, FixedView.all), 1000);
    expect(amountFor(s, FixedView.variable), 300);
    expect(amountFor(s, FixedView.fixed), 700);
  });
}
