import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

/// 나의 밤하늘 — 최근 2주 관측 격자(I-11 10). 머리 + "누적 n개" · 설명 · 7열 칸(최대 폭 448 · 가로 6 · 세로 8).
///
/// 칸은 누르지 않는다. 칸마다 이름 있는 이미지 의미("10월 21일, 수집 {이름}" · "흐린 밤" · "쉰 밤" · "오늘").
/// 수집한 날 `chart-{색}-weak` + 별자리 선 `chart-{색}`, 흐린 밤은 `bg-neutral-weak` + 구름(불투명도 없음),
/// 오늘은 `bg-brand-weak` + 안쪽 2px `fg-brand`.
class MySkyCard extends StatelessWidget {
  const MySkyCard({
    super.key,
    required this.sky,
    required this.today,
    required this.entries,
  });

  final List<SkyDay> sky;
  final ConstellationToday today;
  final List<CollectionEntry> entries;

  static const double maxWidth = 448;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final byKey = {
      for (final e in entries) e.constellation.constellationKey: e,
    };
    final todayDate = sky.isNotEmpty ? sky.last.date : '';
    final rows = <List<SkyDay>>[];
    for (var i = 0; i < sky.length; i += 7) {
      rows.add(sky.sublist(i, i + 7 > sky.length ? sky.length : i + 7));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                headingLevel: 2,
                child: Text(
                  keepAll(l.constMySkyTitle),
                  style: PTypography.t5.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: PSpacing.x2),
            PText(
              l.constMySkyTotal(today.totalCollected),
              style: PTypography.t4.copyWith(
                color: c.fgNeutralSubtle,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpacing.x1),
        Text(
          keepAll(l.constMySkySubtitle),
          style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
        ),
        const SizedBox(height: PSpacing.x3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: PSpacing.x2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: PSpacing.x1_5),
                      Expanded(
                        child: i < rows[r].length
                            ? _DayCell(
                                day: rows[r][i],
                                isToday: rows[r][i].date == todayDate,
                                todayPoints: today.points,
                                entry: rows[r][i].constellationKey != null
                                    ? byKey[rows[r][i].constellationKey]
                                    : null,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.todayPoints,
    required this.entry,
  });

  final SkyDay day;
  final bool isToday;
  final int todayPoints;
  final CollectionEntry? entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final parsed = DateTime.tryParse(day.date);
    final dateLabel = parsed == null ? day.date : monthDay(parsed);
    final dayNum = day.date.length >= 10
        ? int.tryParse(day.date.substring(8, 10)) ?? 0
        : 0;
    final colors = constellationRoleColors(c, day.colorKey ?? 'gray');

    final Color bg;
    final Widget glyph;
    final String name;
    if (isToday) {
      bg = c.bgBrandWeak;
      glyph = Icon(
        skyStageIcon(todayPoints),
        size: PSpacing.x4,
        color: c.fgBrand,
      );
      name = l.constMySkyCellToday(dateLabel);
    } else if (day.isGrown) {
      // 도감이 아직 없거나 못 받았으면 별자리 선 대신 별 하나로 — 칸의 뜻(수집)은 그대로다.
      bg = colors.weak;
      glyph = entry == null
          ? Icon(LucideIcons.star, size: PSpacing.x4, color: colors.strong)
          : ConstellationIcon(
              info: entry!.constellation,
              color: colors.strong,
              size: 22,
              linesOnly: true,
            );
      name = entry == null
          ? dateLabel
          : l.constMySkyCellCollected(
              dateLabel,
              constellationName(entry!.constellation),
            );
    } else if (day.isWithered) {
      bg = c.bgNeutralWeak;
      glyph = Icon(
        LucideIcons.cloudy,
        size: PSpacing.x4,
        color: c.fgNeutralSubtle,
      );
      name = l.constMySkyCellCloudy(dateLabel);
    } else {
      bg = c.bgNeutralWeak;
      glyph = Container(
        width: PSpacing.x1,
        height: PSpacing.x1,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.strokeNeutralSolid,
        ),
      );
      name = l.constMySkyCellRest(dateLabel);
    }

    return Semantics(
      image: true,
      label: name,
      child: ExcludeSemantics(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(PRounded.r2_5),
                  border: isToday
                      ? Border.all(color: c.fgBrand, width: 2)
                      : null,
                ),
                child: Center(child: glyph),
              ),
            ),
            const SizedBox(height: PSpacing.x1),
            Text(
              '$dayNum',
              style: PTypography.t2.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? c.fgBrand : c.fgNeutralSubtle,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
