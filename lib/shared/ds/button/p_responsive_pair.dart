import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

/// 짝 버튼 사이 간격.
const double kResponsivePairGap = PSpacing.x2;

/// 짝 버튼(SEED ResponsivePair, 03A-013) — 주 버튼과 보조 버튼 둘을 폭이 허락하면 한 줄에 비율대로(기본 1:1 반씩, 3:7 도 가능) 놓고,
/// **한 라벨이 자기 몫(짝 폭 − 간격의 비율분)을 넘으면 세로로 쌓는다**(주 버튼이 위, 둘 다 전체 폭). 라벨은 어느 쪽이든 한 줄이다 — 줄을
/// 바꾸지 않고, 쌓아도 버튼 폭을 넘으면 끝을 "…" 로 줄인다(button.md, groo-design #263).
///
/// 한 줄일 때 보조(왼쪽) · 주(오른쪽) 순서고, 쌓으면 주 · 보조 순서다. 글자 크기 설정으로 라벨이 커지면 폭을 다시 재서
/// 알아서 쌓인다(200% 에서 라벨이 자기 몫을 넘는 대가는 쌓는 것으로 받는다).
class PResponsivePair extends StatelessWidget {
  const PResponsivePair({
    super.key,
    required this.primary,
    required this.secondary,
    this.secondaryFlex = 1,
    this.primaryFlex = 1,
  });

  /// 한 줄일 때 보조 : 주 비율 — 기본 1:1(시트 · 확인창 바닥은 균등). 화면 바닥의 Dismiss + CTA 는 3:7(button.md).
  /// 쌓임 판정은 각 라벨이 자기 몫(짝 폭 − 8)을 비율로 나눈 값을 넘는지다.
  final int secondaryFlex;
  final int primaryFlex;

  final PButton primary;
  final PButton secondary;

  /// 한 줄에 각자 몫(기본 반씩, 비율이면 그 비율)으로 들어가는 폭인가.
  @visibleForTesting
  static bool fitsInRow(
    double pairWidth,
    double primaryWidth,
    double secondaryWidth, {
    int primaryFlex = 1,
    int secondaryFlex = 1,
  }) {
    final room = pairWidth - kResponsivePairGap;
    final total = primaryFlex + secondaryFlex;
    return primaryWidth <= room * primaryFlex / total &&
        secondaryWidth <= room * secondaryFlex / total;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = fitsInRow(
          constraints.maxWidth,
          primary.naturalWidth(context),
          secondary.naturalWidth(context),
          primaryFlex: primaryFlex,
          secondaryFlex: secondaryFlex,
        );
        if (fits) {
          return Row(
            key: const ValueKey('pair-row'),
            spacing: kResponsivePairGap,
            children: [
              Expanded(flex: secondaryFlex, child: secondary),
              Expanded(flex: primaryFlex, child: primary),
            ],
          );
        }
        return Column(
          key: const ValueKey('pair-column'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: kResponsivePairGap,
          children: [primary, secondary],
        );
      },
    );
  }
}
