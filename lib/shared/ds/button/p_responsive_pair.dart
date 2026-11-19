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
///
/// [secondaryFitContent] — 보조가 글자만큼인 짝(시트 바닥 왼쪽 [삭제], 웹 `data-fit="content"`). 보조는 반 폭 바탕을 받지 않고
/// 글 폭이며, 남은 폭을 주 버튼이 채운다(bottom-sheet.md "머리 · 본문 · 바닥"). 쌓으면 주 버튼이 위 · 전체 폭, 보조는 아래 왼쪽에
/// 글자만큼 선다(웹 `ResponsivePair` 의 wrap-reverse 와 같다).
class PResponsivePair extends StatelessWidget {
  const PResponsivePair({
    super.key,
    required this.primary,
    required this.secondary,
    this.secondaryFlex = 1,
    this.primaryFlex = 1,
    this.secondaryFitContent = false,
  }) : assert(
         !secondaryFitContent || (secondaryFlex == 1 && primaryFlex == 1),
         '글자만큼인 보조는 비율을 받지 않는다',
       );

  /// 한 줄일 때 보조 : 주 비율 — 기본 1:1(시트 · 확인창 바닥은 균등). 화면 바닥의 Dismiss + CTA 는 3:7(button.md).
  /// 쌓임 판정은 각 라벨이 자기 몫(짝 폭 − 8)을 비율로 나눈 값을 넘는지다.
  final int secondaryFlex;
  final int primaryFlex;

  final PButton primary;
  final PButton secondary;

  /// 보조가 글자만큼인가(웹 `data-fit="content"`) — 시트 바닥 왼쪽 [삭제].
  final bool secondaryFitContent;

  /// 한 줄에 각자 몫(기본 반씩, 비율이면 그 비율)으로 들어가는 폭인가.
  ///
  /// 보조가 글자만큼이면([secondaryFitContent]) 주 버튼의 바탕은 그대로 반 폭이고 글이 길면 그보다 넓어진다 — 보조 글 폭 + 간격 +
  /// max(반 폭, 주 글 폭) 이 짝 폭에 들어가야 한 줄이다. 곧 보조가 반 폭 이하이고, 둘의 글 폭 합이 (짝 폭 − 간격) 이하다.
  @visibleForTesting
  static bool fitsInRow(
    double pairWidth,
    double primaryWidth,
    double secondaryWidth, {
    int primaryFlex = 1,
    int secondaryFlex = 1,
    bool secondaryFitContent = false,
  }) {
    final room = pairWidth - kResponsivePairGap;
    if (secondaryFitContent) {
      return secondaryWidth <= room / 2 &&
          secondaryWidth + primaryWidth <= room;
    }
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
          secondaryFitContent: secondaryFitContent,
        );
        if (fits && secondaryFitContent) {
          return Row(
            key: const ValueKey('pair-row'),
            spacing: kResponsivePairGap,
            children: [
              secondary,
              Expanded(child: primary),
            ],
          );
        }
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
          children: [
            primary,
            if (secondaryFitContent)
              Align(alignment: Alignment.centerLeft, child: secondary)
            else
              secondary,
          ],
        );
      },
    );
  }
}
