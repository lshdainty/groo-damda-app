import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// Chart 의 값 · 숫자 · 색 — 수치 원본은 groo-design `specs/components/chart.yaml`(값은
/// `test/fixtures/design_spec/chart.json`), 색은 DESIGN.md v110(차트 10색 — 라이트 팔레트 700 · 다크 800-dark) ·
/// v111(옅은 바탕). 웹(desk-front `src/shared/ds/chart/chart-variants.ts` · `chart-heatmap-variants.ts`)과 같은 값이다.
///
/// 이 파일은 위젯이 아닌 것 — 색 배정 · 숫자 · 축 값 · 열지도 세기. 위젯은 p_chart.dart 에서 내보낸다.

// ── 색 ───────────────────────────────────────────────────────

/// 차트 10색. 회색은 "기타" 전용이다 — 색이 없다고 주지 않는다.
enum PChartColor {
  blue,
  green,
  orange,
  violet,
  pink,
  indigo,
  red,
  yellow,
  brown,
  gray;

  /// 계열 색 — 라이트 팔레트 700 · 다크 800-dark(생성 토큰).
  Color of(PColors c) => switch (this) {
    PChartColor.blue => c.chartBlue,
    PChartColor.green => c.chartGreen,
    PChartColor.orange => c.chartOrange,
    PChartColor.violet => c.chartViolet,
    PChartColor.pink => c.chartPink,
    PChartColor.indigo => c.chartIndigo,
    PChartColor.red => c.chartRed,
    PChartColor.yellow => c.chartYellow,
    PChartColor.brown => c.chartBrown,
    PChartColor.gray => c.chartGray,
  };

  /// 같은 계열 색의 옅은 단계(weak) — 강조하지 않는 비교 계열(지난 달 · 지난 기간).
  ///
  /// **파랑(통계 비교의 지난 기간)은 회색**(DA-10, 사용자 결정 2026-11-11 "B 회색") — 옛 `chart-blue-weak` 는 라이트 1.26:1 · 다크
  /// 1.38:1 로 바탕에 묻혔다. 이번 기간 색(chart-blue)과 색상이 갈려 구별되고 바탕 대비 3:1 이상이다([previousPeriodGrayOf]).
  Color weakOf(PColors c) => switch (this) {
    PChartColor.blue => previousPeriodGrayOf(c),
    PChartColor.green => c.chartGreenWeak,
    PChartColor.orange => c.chartOrangeWeak,
    PChartColor.violet => c.chartVioletWeak,
    PChartColor.pink => c.chartPinkWeak,
    PChartColor.indigo => c.chartIndigoWeak,
    PChartColor.red => c.chartRedWeak,
    PChartColor.yellow => c.chartYellowWeak,
    PChartColor.brown => c.chartBrownWeak,
    PChartColor.gray => c.chartGrayWeak,
  };

  /// 넓은 면 옅은 바탕(v111 subtle) — 켠 지표 타일.
  Color subtleOf(PColors c) => switch (this) {
    PChartColor.blue => c.chartBlueSubtle,
    PChartColor.green => c.chartGreenSubtle,
    PChartColor.orange => c.chartOrangeSubtle,
    PChartColor.violet => c.chartVioletSubtle,
    PChartColor.pink => c.chartPinkSubtle,
    PChartColor.indigo => c.chartIndigoSubtle,
    PChartColor.red => c.chartRedSubtle,
    PChartColor.yellow => c.chartYellowSubtle,
    PChartColor.brown => c.chartBrownSubtle,
    PChartColor.gray => c.chartGraySubtle,
  };
}

/// 색이 없는 항목의 배정 순서(v110) — 회색은 "기타" 전용이라 없다. 수입은 blue, 지출은 red.
const List<PChartColor> kChartOrder = [
  PChartColor.blue,
  PChartColor.green,
  PChartColor.orange,
  PChartColor.violet,
  PChartColor.pink,
  PChartColor.indigo,
  PChartColor.red,
  PChartColor.yellow,
  PChartColor.brown,
];

/// 항목이 이 개수를 넘으면 상위 9 + 회색 "기타" 로 묶는다.
const int kChartMaxItems = 10;

/// 항목과 배정된 색.
typedef PChartColored<T> = ({T item, PChartColor color});

/// 저장된 색 먼저, 나머지는 그 차트에서 아직 쓰지 않은 색부터 배정 순서로(사용자 결정 9A) — 저장된 색과 같은 색이 두 번
/// 나오지 않는다. 10개를 넘으면 상위 9 + 회색 "기타"(항목은 큰 순서로 넘긴다). 회색은 "기타" 에만 — 색이 없다고 주지 않는다.
///
/// [colorOf] 저장된 색(카테고리 · 계좌에 사용자가 고른 색, 없으면 null). [groupOthers] 상위 9 뒤의 항목을 하나로 묶은
/// "기타" — 주지 않으면 10번째부터 각각 회색으로 둔다.
List<PChartColored<T>> assignChartColors<T>(
  List<T> items, {
  PChartColor? Function(T item)? colorOf,
  T Function(List<T> rest)? groupOthers,
}) {
  final over = items.length > kChartMaxItems;
  final head = over ? items.sublist(0, 9) : [...items];
  final rest = over ? items.sublist(9) : <T>[];
  final saved = [for (final i in head) colorOf?.call(i)];
  final used = {for (final c in saved) ?c};
  final free = [
    for (final c in kChartOrder)
      if (!used.contains(c)) c,
  ];
  var next = 0;
  final out = <PChartColored<T>>[];
  for (var i = 0; i < head.length; i++) {
    var color = saved[i];
    if (color == null) {
      // 쓰지 않은 색이 다 떨어지면(저장된 색이 많을 때) 배정 순서를 처음부터 다시 쓴다
      color = next < free.length
          ? free[next]
          : kChartOrder[(next - free.length) % kChartOrder.length];
      next++;
    }
    out.add((item: head[i], color: color));
  }
  if (over) {
    if (groupOthers != null) {
      out.add((item: groupOthers(rest), color: PChartColor.gray));
    } else {
      for (final item in rest) {
        out.add((item: item, color: PChartColor.gray));
      }
    }
  }
  return out;
}

// ── 숫자 ─────────────────────────────────────────────────────

/// 빼기는 U+2212 하나 — 같은 차트 안에서 "-" 와 "−" 를 섞지 않는다.
const String kChartMinus = '−';

double _round1(double x) => (x * 10 + 0.5).floorToDouble() / 10;

String _group(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

int _jsRound(double x) => (x + 0.5).floor();

/// 눈금 글자 — 1만 미만은 쉼표 정수, 그 위는 만 · 억 · 조에 소수 한 자리(.0 은 버린다). 빼기는 U+2212.
String formatAxisWon(num value) {
  final v = value.toDouble();
  if (!v.isFinite) return '';
  final sign = v < 0 ? kChartMinus : '';
  final n = v.abs();
  if (n < 10000) return sign + _group(_jsRound(n));
  var scaled = n / 10000;
  var unit = '만';
  for (final bigger in const ['억', '조']) {
    if (_round1(scaled) < 10000) break;
    scaled /= 10000;
    unit = bigger;
  }
  final r = _round1(scaled);
  final whole = r.truncate();
  final tenth = ((r - whole) * 10).round();
  return '$sign${_group(whole)}${tenth == 0 ? '' : '.$tenth'}$unit';
}

/// 돈은 줄이지 않고 원까지(툴팁 · 지표 타일 · 도넛 가운데 · 열지도 칸 · 대체 표) — 빼기는 U+2212.
String formatWon(num value) {
  final v = value.toDouble();
  return '${v < 0 ? kChartMinus : ''}${_group(_jsRound(v.abs()))}원';
}

// ── 축 · 격자 ─────────────────────────────────────────────────

/// 눈금 글자 크기(px) — 11 / 15 · 고정폭 숫자.
const double kChartTickSize = 11;

/// 눈금과 그리는 자리 사이.
const double kChartTickMargin = PSpacing.x2;

const _tabular = [FontFeature.tabularFigures()];

/// 눈금 글자 — 11 / 15 · fg-neutral-subtle(이중 축이면 계열 색) · 고정폭 숫자.
TextStyle chartTickStyle(PColors c, {PChartColor? color}) =>
    PTypography.t1.copyWith(
      color: color == null ? c.fgNeutralSubtle : color.of(c),
      fontFeatures: _tabular,
    );

/// 세로축 폭 — 눈금 글자들 가운데 가장 긴 것을 재서 [margin] 을 더한다.
///
/// 앱의 모든 차트 세로축이 이 계산 하나를 쓴다(고정 폭이면 `−2,500만` 의 부호가
/// 잘려 양수로 읽힌다 — chart.md:46 · 결함 D6). 웹 `useAxisWidth` 와 같은 규칙.
double chartAxisWidth(
  Iterable<String> labels,
  TextStyle style, {
  TextScaler scaler = TextScaler.noScaling,
  double margin = kChartTickMargin,
}) {
  var w = 0.0;
  for (final t in labels) {
    w = math.max(w, measureText(t, style, scaler: scaler));
  }
  return w + margin;
}

/// 눈금 하나의 폭을 잰다 — 세로축의 폭은 가장 긴 글자("−3,000만")가 잘리지 않게 잡는다.
/// 글자는 화면의 글자 배율로 그려지므로 [scaler] 로 같은 배율을 넣어 잰다(안 넣으면 1배 — 200% 에서 눈금이 잘린다).
double measureText(
  String text,
  TextStyle style, {
  TextScaler scaler = TextScaler.noScaling,
}) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final w = p.width;
  p.dispose();
  return w;
}

/// 눈금 — [min] ~ [max] 를 [step] 간격으로. 값은 0 을 지난다(0 아래 · 위로 둘 다 있어도 0 에 눈금이 선다).
typedef PChartAxis = ({double min, double max, double step});

/// 값 범위 [lo] ~ [hi] 를 눈금 네 칸 안팎의 깔끔한 수로 늘린다 — 0 은 늘 범위 안이다. 값이 모두 0 이면 0 ~ 10,000.
PChartAxis niceChartAxis(double lo, double hi, {int intervals = 4}) {
  var low = math.min(lo, 0.0);
  var high = math.max(hi, 0.0);
  if (high == low) {
    return (min: 0, max: 10000, step: 10000 / intervals);
  }
  final raw = (high - low) / intervals;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  var step = mag * 10;
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (mag * m >= raw - 1e-9) {
      step = mag * m;
      break;
    }
  }
  low = (low / step).floorToDouble() * step;
  high = (high / step).ceilToDouble() * step;
  return (min: low, max: high, step: step);
}

// ── 도넛 ─────────────────────────────────────────────────────

/// 도넛 두께 — 지름 ÷ 10 + 6 을 정수로 반올림한다(chart.yaml series.thicknessPerDiameter 0.1 · thicknessOffset 6px — Q-012-5).
/// 160 → 22 · 120 → 18 · 대시보드 112 → 17 · 통계 176 → 24 · 자산 180 → 24.
double chartDonutThickness(double diameter) =>
    (diameter * 0.1 + 6).round().toDouble();

/// 가운데 글 묶음의 모서리와 구멍 가장자리 사이 — 조각에 붙지 않게.
const double kChartHoleInset = PSpacing.x1;

// ── 열지도 ────────────────────────────────────────────────────

/// 칸 폭이 이 값 이상일 때만 칸에 금액을 적는다(px) — "99,999,999,999원" 이 107 이라 999억까지 들어간다.
const double kHeatTextMinCellWidth = 112;

/// 칸 글 좌우에 남기는 여백의 합 — 글(글자 배율 포함)이 칸 폭 − 이 값보다 넓으면 글을 빼고 세기 색만 칠한다.
/// 100% 에서 가장 넓은 글("99,999,999,999원" 107)이 112 칸에 드는 값이다.
const double kHeatCellTextPadding = 4;

/// 왼쪽 시간대 라벨 열 폭(px).
const double kHeatLabelColumn = 56;

/// 칸 사이(가로 · 세로 같다).
const double kHeatGap = PSpacing.x1_5;

/// 세기 다섯 — bg-brand-solid 를 카드 면에 섞은 비율(18 · 35 · 55 · 76 · 100%). 넷째는 75 였다 — 그루 초록(이음)에서 어느 글자도
/// 4.5 에 못 미쳐 두 브랜드 함께 76% 로 올렸다(2026-10-22 사용자 결정 B, groo-design #187). 끊는 자리는 그대로다.
const List<double> kHeatMix = [0.18, 0.35, 0.55, 0.76, 1];

/// 가장 큰 칸 값에 대한 비율로 끊는 자리 — 8 · 22 · 45 · 75%.
const List<double> kHeatCuts = [0.08, 0.22, 0.45, 0.75];

/// 값 → 세기 단계(0 ~ 4). 값이 없으면(0 · null · 음수 · 가장 큰 값이 0) -1.
int heatStep(num? value, double max) {
  if (value == null || !(value > 0) || !(max > 0)) return -1;
  final ratio = value / max;
  if (ratio < kHeatCuts[0]) return 0;
  if (ratio < kHeatCuts[1]) return 1;
  if (ratio < kHeatCuts[2]) return 2;
  if (ratio < kHeatCuts[3]) return 3;
  return 4;
}

/// 세기 단계의 칸 색 — 브랜드 채움을 카드 면에 섞는다.
Color heatStepColor(PColors c, int step) =>
    Color.lerp(c.bgLayerDefault, c.bgBrandSolid, kHeatMix[step])!;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// 단계마다 칸 글자색 — 그 단계 바탕 위 fg-neutral 이 4.5 를 넘으면 fg-neutral, 아니면 흰 글자(static-white).
/// 칸마다 재지 않는다. 라이트는 18 · 35 · 55% 가 fg-neutral · 75 · 100% 가 흰 글자, 다크는 모두 fg-neutral.
List<Color> heatTextColors(PColors c) => [
  for (var i = 0; i < kHeatMix.length; i++)
    () {
      final bg = heatStepColor(c, i);
      final onFg = _contrast(c.fgNeutral, bg);
      return onFg >= 4.5 || onFg >= _contrast(c.staticWhite, bg)
          ? c.fgNeutral
          : c.staticWhite;
    }(),
];

/// 지난 기간 막대 색 — 라이트 gray-500 `#8A91A0`(흰 바탕 3.16:1) · 다크 gray-600 `#838997`(카드 `#242938` 4.13:1). 팔레트 값이다
/// (웹 · 디자인시스템과 같은 hex). 바탕이 어두운지는 `bgLayerDefault` 의 밝기로 가른다.
Color previousPeriodGrayOf(PColors c) =>
    c.bgLayerDefault.computeLuminance() < 0.5 ? c.gray600 : c.gray500;
