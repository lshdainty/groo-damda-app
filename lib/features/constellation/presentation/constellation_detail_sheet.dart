import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 별자리 상세(I-11 23 · Q2-A) — ds Bottom Sheet 조회. 제목은 별자리 이름이고 바깥 누름 · 끌어내림으로 닫힌다(바닥 버튼 없음).
///
/// 하늘 패널 240(하늘 그림과 같은 역할 색 그라디언트 · 별자리 그림 180) → 설명 → 보기만 하는 줄 둘(별 개수 · 수집).
/// 못 모은 별자리는 실루엣 + 패널 아래 "아직 만나지 못한 별자리예요"(불투명, 흐리지 않는다) · 수집 줄은 "미수집".
///
/// [today] 가 있고 그 별자리가 오늘의 목표면(10-29 사용자 결정 2 · 3) 머리 설명 "오늘의 목표 별자리" · 하늘 패널에 켠 별 + 남은 별 고리
/// · 별빛 Progress 막대("오늘 모은 별빛" · "80%" · "12/15 별빛 · 3별 남음")가 더해지고 "아직 만나지 못한" 안내는 없다.
Future<void> showConstellationDetail(
  BuildContext context,
  CollectionEntry entry, {
  ConstellationToday? today,
}) {
  return PBottomSheet.show<void>(
    context,
    builder: (_) => ConstellationDetailSheet(entry: entry, today: today),
  );
}

/// 하늘 카드 · 썸네일에서 연다 — 도감을 아직 못 받았으면([entry] 없음) 수집 횟수 줄은 두지 않는다.
Future<void> showTodayConstellationDetail(
  BuildContext context,
  ConstellationToday today, {
  CollectionEntry? entry,
}) {
  return PBottomSheet.show<void>(
    context,
    builder: (_) => ConstellationDetailSheet(
      entry:
          entry ??
          CollectionEntry(
            constellation: today.constellation,
            collectCount: today.collected ? 1 : 0,
            lastCollectedDate: null,
          ),
      today: today,
      showCollectRow: entry != null,
    ),
  );
}

class ConstellationDetailSheet extends StatelessWidget {
  const ConstellationDetailSheet({
    super.key,
    required this.entry,
    this.today,
    this.showCollectRow = true,
  });

  final CollectionEntry entry;
  final ConstellationToday? today;
  final bool showCollectRow;

  /// 오늘의 목표 별자리를 여는 중인가.
  bool get isToday =>
      today != null &&
      today!.constellation.constellationKey ==
          entry.constellation.constellationKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final info = entry.constellation;
    final name = constellationName(info);
    final collected = entry.collected;
    final desc = constellationDesc(info);
    final goalToday = isToday ? today : null;
    final lit = goalToday == null
        ? 0
        : math.min(goalToday.points, goalToday.goal);
    // list.yaml 글 값 — t5 · fg-neutral-subtle(굵기 없음), 제목은 fg-neutral(기본)
    final valueStyle = PTypography.t5.copyWith(
      color: c.fgNeutralSubtle,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return PBottomSheetContent(
      title: name,
      description: goalToday == null ? null : l.constDetailTodayDesc,
      closeLabel: l.actionClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('constellation-detail-sky'),
            height: 240,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PRounded.r4),
              gradient: skyGradient(c, three: true),
            ),
            child: Stack(
              children: [
                // 그림(잔별 · 선 · 점등 별)은 이름 붙은 이미지 하나, 안내 글은 그 밖의 글이라 읽힌다.
                Positioned.fill(
                  child: Semantics(
                    image: true,
                    label: l.constDetailSkyName(name),
                    child: ExcludeSemantics(
                      child: Stack(
                        children: [
                          const _DimStars(),
                          Center(
                            child: ConstellationIcon(
                              info: info,
                              // 켠 별 · 선 · 고리 알파는 ConstellationPainter 가 정한다(여기 값은 기본 색 하나일 뿐).
                              color: skyInk(c, 0xFF),
                              size: 180,
                              lit: goalToday != null
                                  ? lit
                                  : (collected ? null : 0),
                              glow: goalToday != null ? lit > 0 : collected,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!collected && goalToday == null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: PSpacing.x3_5,
                    child: Text(
                      keepAll(l.constDetailNotMet),
                      semanticsLabel: l.constDetailNotMet,
                      textAlign: TextAlign.center,
                      style: PTypography.t3.copyWith(
                        color: c.fgNeutralInverted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (goalToday != null)
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x4),
              child: _TodayProgress(today: goalToday, lit: lit),
            ),
          if (desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: PSpacing.x4,
                bottom: PSpacing.x1,
              ),
              child: Text(
                keepAll(desc),
                style: PTypography.t5.copyWith(color: c.fgNeutralMuted),
              ),
            ),
          PList(
            semanticLabel: name,
            children: [
              PListItem(
                title: l.constDetailStarCountLabel,
                gutter: 0,
                suffix: Text(
                  l.constDetailStarCountValue(info.starCount),
                  style: valueStyle,
                  softWrap: false,
                ),
              ),
              if (showCollectRow)
                PListItem(
                  title: l.constDetailCollectLabel,
                  gutter: 0,
                  suffix: Text(
                    collected
                        ? l.constDetailCollectValue(entry.collectCount)
                        : l.constCollectionNotCollected,
                    style: valueStyle,
                    softWrap: false,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 하늘 패널 잔별 14 — 웹 `SKY_DIM_STARS` 와 같은 좌표(장식, 투명도 30%).
class _DimStars extends StatelessWidget {
  const _DimStars();

  static const _stars = <(double, double)>[
    (5, 18),
    (11, 72),
    (17, 30),
    (22, 84),
    (28, 12),
    (33, 52),
    (38, 88),
    (45, 8),
    (55, 90),
    (62, 10),
    (68, 86),
    (75, 20),
    (83, 78),
    (90, 14),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          for (var i = 0; i < _stars.length; i++)
            Positioned(
              left: box.maxWidth * _stars[i].$1 / 100,
              top: box.maxHeight * _stars[i].$2 / 100,
              child: Container(
                width: i % 3 == 0 ? 2.5 : 1.5,
                height: i % 3 == 0 ? 2.5 : 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skyInk(c, 0x4D),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 오늘의 별빛 막대 — 이름 "오늘 모은 별빛"(t4 500) + 오른쪽 "80%"(t3 subtle) · 막대(높이 8) · 아래 "12/15 별빛 · 3별 남음"(t2 subtle).
/// 비율 · 글 둘 다 둔다(10-29 사용자 결정 2). 막대는 progress.yaml 의 [PProgressBar] 그대로.
class _TodayProgress extends StatelessWidget {
  const _TodayProgress({required this.today, required this.lit});

  final ConstellationToday today;
  final int lit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final goal = today.goal;
    final reached = goal > 0 && lit >= goal;
    final pct = formatProgress(
      goal <= 0 ? 0 : ((lit / goal) * 100).clamp(0, 100),
    );
    final remain = math.max(0, goal - lit);
    final tabular = const [FontFeature.tabularFigures()];
    final bottom = remain > 0
        ? l.constDetailTodayRemain(lit, goal, remain)
        : l.constDetailTodayAll(lit, goal);
    return Column(
      key: const ValueKey('constellation-detail-progress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PSpacing.x1_5,
      children: [
        ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: PSpacing.x2,
            children: [
              Expanded(
                child: Text(
                  keepAll(l.constDetailTodayProgress),
                  style: PTypography.t4.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 목표에 닿으면 "100%" 가 아니라 "달성"(fg-neutral · 700 — progress.yaml 의 reached).
              Text(
                reached ? l.dsProgressReached : l.constDetailTodayPct(pct),
                style: PTypography.t3.copyWith(
                  color: reached ? c.fgNeutral : c.fgNeutralSubtle,
                  fontWeight: reached ? FontWeight.w700 : null,
                  fontFeatures: tabular,
                ),
              ),
            ],
          ),
        ),
        PProgressBar(
          value: lit.toDouble(),
          max: math.max(goal, 1).toDouble(),
          meaning: PProgressMeaning.goal,
          semanticsLabel: l.dsProgressSemantics(
            l.constDetailTodayProgress,
            '${math.max(goal, 1)}',
            '$lit',
          ),
          semanticsValue: reached
              ? l.dsProgressReached
              : l.constDetailTodayPct(pct),
        ),
        ExcludeSemantics(
          child: Text(
            keepAll(bottom),
            style: PTypography.t2.copyWith(
              color: c.fgNeutralSubtle,
              fontFeatures: tabular,
            ),
          ),
        ),
      ],
    );
  }
}
