/// 고정 / 변동 나누기 — 통계 화면이 같은 규칙으로 세 숫자(전체 · 고정 · 변동)를 낸다.
/// 웹 `entities/expense/lib/fixed-split.ts` 미러.
///
/// 서버가 내리는 건 **전체**와 그 가운데 **고정인 몫**이다. 변동은 서버가 따로 세지 않고
/// `전체 − 고정` 으로 구한다 — 두 값을 따로 세면 환불·미래분 규칙이 갈릴 수 있어서, 한 목록에서
/// 둘을 함께 내고 나머지를 뺀다(백엔드 `ExpenseAggregates` 가 같은 이유로 그렇게 한다).
///
/// 옛 서버는 고정 몫을 안 보낸다(모델 기본값 0) — 그때는 전부 변동으로 본다. 화면이 깨진
/// 숫자를 그리는 것보다 기존 화면 그대로 나오는 쪽이 안전하다.
library;

/// 화면에 내는 보기 — 전체 · 고정 제외(= 변동만) · 고정만.
enum FixedView { all, variable, fixed }

class FixedSplit {
  const FixedSplit({
    required this.total,
    required this.fixed,
    required this.variable,
    required this.fixedShare,
    required this.variableShare,
  });

  /// 전체
  final int total;

  /// 고정인 몫 (0 이상, 전체를 넘지 않는다)
  final int fixed;

  /// 변동 = 전체 − 고정
  final int variable;

  /// 화면에 보이는 비중(%, 소수 첫째 자리) — 고정 · 변동 둘이 한 자리로 보여도 합이 100.0 이 되게 변동은
  /// 고정의 나머지다. 0 초과 0.05 미만은 반올림하지 않고 그대로 둔다("0.1% 미만" 표기는 `formatShare` 몫).
  final double fixedShare;
  final double variableShare;
}

/// 전체와 고정 몫을 받아 세 숫자와 비율을 만든다.
///
/// 고정이 전체를 넘거나 음수로 들어와도 `0 ≤ 고정 ≤ 전체` 로 끌어와 변동이 음수가 되지 않게 한다 —
/// 환불·타이밍 차이로 두 값이 어긋나더라도 막대가 거꾸로 그려지면 안 된다.
FixedSplit splitFixed(int? total, int? fixed) {
  final t = (total ?? 0) < 0 ? 0 : (total ?? 0);
  final raw = fixed ?? 0;
  final f = raw < 0 ? 0 : (raw > t ? t : raw);
  final shares = _shares(t, f);
  return FixedSplit(
    total: t,
    fixed: f,
    variable: t - f,
    fixedShare: shares.fixed,
    variableShare: shares.variable,
  );
}

/// 보기에 맞는 금액 — 전체 / 변동(고정 제외) / 고정.
int amountFor(FixedSplit split, FixedView view) => switch (view) {
  FixedView.fixed => split.fixed,
  FixedView.variable => split.variable,
  FixedView.all => split.total,
};

/// 고정 · 변동 비중 — 소수 첫째 자리로 반올림하고 변동은 100 − 고정. 한쪽이 0 보다 큰데 반올림이 0 이나 100 으로
/// 밀어내면 그 쪽은 반올림하지 않은 값을 둔다(그래야 "0.1% 미만" 이 된다).
({double fixed, double variable}) _shares(int t, int f) {
  if (t == 0) return (fixed: 0, variable: 0);
  final rawFixed = f * 100 / t;
  final rawVariable = (t - f) * 100 / t;
  var fixed = (rawFixed * 10).round() / 10;
  var variable = (1000 - (rawFixed * 10).round()) / 10;
  if (f > 0 && fixed < 0.05) fixed = rawFixed;
  if (t - f > 0 && variable < 0.05) variable = rawVariable;
  return (fixed: fixed, variable: variable);
}
