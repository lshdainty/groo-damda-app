// 더치페이 몫 셈 — 화면과 시험이 같은 함수를 쓴다(I-21 G 40).
//
// 남는 원은 결제자(늘 나)의 몫이다. N분의 1 은 `내림(총액 ÷ 인원)` 을 모두에게, 비율도 사람마다 내림하고 나머지를 결제자에게 준다.
// "나도 포함" 을 끄면 나는 목록에 없지만 결제자이고, 남는 원이 [DutchShares.payerOut] 으로 나온다(내 몫).

enum DutchSplitMethod { equal, ratio, custom }

/// 비율 입력의 소수 자릿수 상한. 이보다 잘게 쓰는 경우는 없고, 가중치가 커져 넘치는 것도 막는다.
const int kDutchRatioMaxDecimals = 6;

class DutchShares {
  const DutchShares(this.shares, this.payerOut);

  /// 목록의 사람마다 몫(목록 차례 그대로).
  final List<int> shares;

  /// 나를 목록에서 뺐을 때 결제자(나)에게 남는 몫 — 목록에 내가 있으면 0.
  final int payerOut;

  int get sum => shares.fold<int>(0, (s, v) => s + v) + payerOut;
}

/// '1.5' + scale 2 → 150. 소수점을 지우고 자릿수만 맞추므로 부동소수점을 거치지 않는다.
int scaledRatio(String raw, int scale) {
  final s = raw.trim();
  if (s.isEmpty) return 0;
  final dot = s.indexOf('.');
  final intPart = dot < 0 ? s : s.substring(0, dot);
  var frac = dot < 0 ? '' : s.substring(dot + 1);
  if (frac.length > scale) frac = frac.substring(0, scale);
  frac = frac.padRight(scale, '0');
  final v = int.tryParse('$intPart$frac') ?? 0;
  return v < 0 ? 0 : v;
}

/// 비율 문자열들을 공통 배수로 올린 정수 가중치로 바꾼다('1.5','1' → 15,10).
List<int> ratioWeights(List<String> ratios) {
  var scale = 0;
  for (final r in ratios) {
    final s = r.trim();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > scale) scale = s.length - dot - 1;
  }
  if (scale > kDutchRatioMaxDecimals) scale = kDutchRatioMaxDecimals;
  return [for (final r in ratios) scaledRatio(r, scale)];
}

/// [payerIndex] — 목록에서 결제자(나)의 차례, 목록에 없으면 -1. [ratios] · [customs] 는 목록 차례 그대로.
DutchShares computeDutchShares({
  required int total,
  required DutchSplitMethod method,
  required int count,
  required int payerIndex,
  List<String> ratios = const [],
  List<int> customs = const [],
}) {
  if (count <= 0) return const DutchShares([], 0);
  final shares = List<int>.filled(count, 0);
  var rest = 0;
  switch (method) {
    case DutchSplitMethod.equal:
      final each = total ~/ count;
      for (var i = 0; i < count; i++) {
        shares[i] = each;
      }
      rest = total - each * count;
    case DutchSplitMethod.ratio:
      final w = ratioWeights(ratios);
      final tw = w.fold<int>(0, (s, v) => s + v);
      if (tw <= 0) return DutchShares(shares, 0);
      var assigned = 0;
      for (var i = 0; i < count; i++) {
        shares[i] = (total * w[i]) ~/ tw;
        assigned += shares[i];
      }
      rest = total - assigned;
    case DutchSplitMethod.custom:
      for (var i = 0; i < count; i++) {
        if (i != payerIndex) shares[i] = customs[i];
      }
      if (payerIndex >= 0) {
        final others = shares.fold<int>(0, (s, v) => s + v);
        shares[payerIndex] = total - others < 0 ? 0 : total - others;
      }
      return DutchShares(shares, 0);
  }
  if (payerIndex >= 0) {
    shares[payerIndex] += rest;
    return DutchShares(shares, 0);
  }
  return DutchShares(shares, rest);
}
