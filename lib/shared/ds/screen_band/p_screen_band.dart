import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_content.dart';

/// 띠 사이 간격 — 회색 바닥이 8 만큼 비친다(SEED Divider "강함"). 맨 위 · 맨 아래에는 두지 않는다(I-05 74).
const double kScreenBandGap = PSpacing.x2;

/// 띠 안쪽 위 · 아래 여백.
const double kScreenBandPaddingTop = PSpacing.x1;
const double kScreenBandPaddingBottom = PSpacing.x2;

/// 바탕은 화면 끝까지, 내용은 [PScreenContent] 로 좌우 안전 영역 안 · 넓은 화면에서 720 가운데에 둔다.
///
/// 화면 폭 흰 띠(`bg-layer-default`) 하나 — 띠 화면(설정 · 전체 · 캘린더 · 알림 · 폼)이 묶음마다 이것을 둔다.
/// 바닥은 `bg-layer-basement` 이고 띠는 그 위에 8 띄워 쌓인다([PScreenBands]). 띠 안은 위 4 · 아래 8 이며 좌우는
/// 안의 내용이 정한다(화면 가장자리 24). 숫자 · 그림 구역은 안쪽 24 를 가진 [PScreenSection] 이고,
/// 흰 화면은 가계부 거래 목록뿐이다.
class PScreenBand extends StatelessWidget {
  const PScreenBand({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('screen-band'),
      color: context.colors.bgLayerDefault,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(
            top: kScreenBandPaddingTop,
            bottom: kScreenBandPaddingBottom,
          ),
          child: PScreenContent(child: child),
        ),
      ),
    );
  }
}

/// 띠를 세로로 쌓는다 — 띠 사이 8 만(맨 위 · 맨 아래 틈 없음). 스크롤 목록 안의 자식으로 풀어 쓸 때는 [PScreenBands.children] 을 쓴다.
class PScreenBands {
  const PScreenBands._();

  /// 띠 사이마다 8 을 낀 자식 목록.
  static List<Widget> children(List<Widget> bands) => [
    for (var i = 0; i < bands.length; i++) ...[
      if (i > 0) const SizedBox(height: kScreenBandGap),
      bands[i],
    ],
  ];
}

/// 구역 띠 하나 — Desk 폰 구역 화면(홈 · 자산 · 통계 · 예산 · 카드 상세 · 밤하늘 · 숲 리포트 · 증권)이 구역마다 둔다.
/// 화면 폭 `bg-layer-default` 면이고 모서리 · 테두리 · 그림자가 없다. 띠 안은 카드 안과 같은 값 — 사방 24(띠 안 위 4 ·
/// 아래 8 은 이 안에 든다). 띠 사이는 [kScreenBandGap](8) — 회색 바닥이 보이는 틈이다
/// (groo-design DESIGN Layout "화면 바탕" — 2026-10-21 사용자 결정 I-01 결정 3: 폰에는 카드 화면이 없다).
/// 목록 구역은 줄이 제 좌우 24 를 가지므로 [padding] 의 좌우를 0 으로 준다.
class PScreenSection extends StatelessWidget {
  const PScreenSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PSpacing.x6),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('screen-section'),
      color: context.colors.bgLayerDefault,
      child: SizedBox(
        width: double.infinity,
        child: PScreenContent(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 띠 화면의 본문 전체를 **하나의 흰 띠**로 감싼다 — 머리 바로 아래부터 화면 폭 흰 띠가 남은 높이를 채운다.
/// 묶음마다 띠를 나누지 않은 화면(목록 · 폼)이 쓰는 한 장 띠다. 묶음이 나뉘는 화면은 [PScreenBands] 로 띠를 직접 쌓는다.
class PScreenBandBody extends StatelessWidget {
  const PScreenBandBody({super.key, required this.child, this.color});

  final Widget child;

  /// 띠 바탕 — 기본 `bg-layer-default`. 강조 줄 하나로 된 띠(List Highlight)는 줄의 강조 바탕을 띠가 화면 끝까지
  /// 깐다 — 줄이 칠하는 바탕은 안전 영역 안 내용 자리에서 멈춘다.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('screen-band-body'),
      color: color ?? context.colors.bgLayerDefault,
      child: SizedBox(
        width: double.infinity,
        child: PScreenContent(child: child),
      ),
    );
  }
}
