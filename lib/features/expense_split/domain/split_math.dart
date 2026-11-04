// 거래 나누기의 금액 셈 — 화면과 시험이 같은 함수를 쓴다. 항목은 자리(차례)로 이어지므로 항목의 `rowId` 는 셈 밖에서 그대로 따라간다.

/// 금액 배열의 합이 정확히 [target] 이 되도록 잔차를 나눠 흡수한다(항상 균형). [target] 이 항목 수 이상이면 모든 항목이 1 이상이다.
List<int> settleRemainder(List<int> amts, int target) {
  final n = amts.length;
  if (n == 0) return amts;
  final floor = target >= n ? 1 : 0;
  final out = [for (final v in amts) v < floor ? floor : v];
  final diff = target - out.fold<int>(0, (s, v) => s + v);
  final order = [for (int i = 0; i < n; i++) i]
    ..sort((a, b) => out[b] - out[a]);
  if (diff > 0) {
    out[order[0]] += diff;
  } else if (diff < 0) {
    var need = -diff;
    for (final idx in order) {
      if (need <= 0) break;
      final cap = out[idx] - floor;
      final take = cap < need ? cap : need;
      out[idx] -= take;
      need -= take;
    }
  }
  return out;
}

/// 비례 배분 — 지금 비중대로 새 총액에 맞춘다(잔차까지 정확히 흡수).
List<int> proportionalAmounts(List<int> amts, int target) {
  final base = amts.fold<int>(0, (s, v) => s + v);
  final b = BigInt.from(base == 0 ? 1 : base);
  final t = BigInt.from(target);
  // 100억 원 × 항목도 64비트를 넘지 않게 BigInt 로 곱하고, 반올림(반은 올림)은 정수로 한다
  return settleRemainder([
    for (final v in amts)
      ((BigInt.from(v) * t * BigInt.two + b) ~/ (b * BigInt.two)).toInt(),
  ], target);
}

/// 큰 항목 반영 — 가장 큰 항목에 차액을 싣는다(모자라면 다음 큰 항목으로 흘린다).
List<int> toLargestAmounts(List<int> amts, int target) =>
    settleRemainder(amts, target);

/// 균등 분배 — 나머지는 첫 항목.
List<int> evenAmounts(int count, int total) {
  if (count <= 0) return const [];
  final each = total ~/ count;
  final rest = total - each * count;
  return [for (var i = 0; i < count; i++) i == 0 ? each + rest : each];
}
