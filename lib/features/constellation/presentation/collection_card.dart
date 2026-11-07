import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_detail_sheet.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

/// 별자리 도감(I-11 11) — 머리 + 설명 + ds List 보기 줄(87줄 모두, 줄 사이 선 없음, 맞춤 위) + 뒤 작은 버튼.
///
/// 줄 자체는 누르지 않는다(누르는 것은 단추 하나). 앞 타일 40, 제목 = 별자리 이름(못 모았어도 같은 색), 배지 묶음 =
/// 오늘의 목표 · NEW(마지막 수집 하나) · n회 / 미수집, 설명은 별자리 설명 / 모으는 법.
class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.todayKey,
    this.today,
  });

  final ConstellationCollectionData collection;
  final String todayKey;

  /// 오늘의 목표 — 있으면 도감에서 그 별자리를 열 때 하늘 카드와 같은 상세(켠 별 · 별빛 막대)가 열린다.
  final ConstellationToday? today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final newest = newestCollectedKey(collection.entries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x6,
            PSpacing.x6,
            PSpacing.x1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  headingLevel: 2,
                  child: Text(
                    keepAll(l.constCollectionTitle),
                    style: PTypography.t5.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PSpacing.x2),
              PText(
                l.constCollectionProgress(
                  collection.collectedKinds,
                  collection.entries.length,
                ),
                style: PTypography.t4.copyWith(
                  color: c.fgNeutralSubtle,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            0,
            PSpacing.x6,
            PSpacing.x1,
          ),
          child: Text(
            keepAll(l.constCollectionSubtitle),
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
        PList(
          semanticLabel: l.constCollectionTitle,
          children: [
            for (final e in collection.entries)
              _CollectionRow(
                entry: e,
                isToday: e.constellation.constellationKey == todayKey,
                isNew: e.constellation.constellationKey == newest,
                today: today,
              ),
          ],
        ),
      ],
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.entry,
    required this.isToday,
    required this.isNew,
    this.today,
  });

  final CollectionEntry entry;
  final bool isToday;
  final bool isNew;
  final ConstellationToday? today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final owned = entry.collected;
    final info = entry.constellation;
    final name = constellationName(info);
    final cta = owned ? l.fcolViewCta : l.fcolPreviewCta;
    final ctaName = owned
        ? l.constCollectionViewOwnedNamed(name)
        : l.constCollectionViewLockedNamed(name);
    void open() => showConstellationDetail(context, entry, today: today);

    final tile = owned
        ? Container(
            width: PListTile.size,
            height: PListTile.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PRounded.r3),
              gradient: skyGradient(c),
            ),
            child: ConstellationIcon(
              info: info,
              color: skyInk(c, 0xFF),
              size: 30,
              glow: true,
            ),
          )
        : PListTile(
            background: c.bgNeutralWeak,
            color: c.fgNeutralSubtle,
            child: const Icon(LucideIcons.lock),
          );

    return PListItem(
      title: name,
      align: PListAlign.top,
      prefix: ExcludeSemantics(child: tile),
      detailChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: PSpacing.x0_5),
            child: Wrap(
              spacing: PSpacing.x1,
              runSpacing: PSpacing.x1,
              children: [
                if (isToday)
                  PBadge(
                    label: l.constCollectionTodayBadge,
                    variant: PBadgeVariant.solid,
                    tone: PBadgeTone.brand,
                  ),
                if (isNew && owned)
                  PBadge(
                    label: l.constCollectionBadgeNew,
                    tone: PBadgeTone.warning,
                  ),
                if (owned)
                  PBadge(
                    label: l.constCollectionTimes(entry.collectCount),
                    tone: PBadgeTone.informative,
                  )
                else
                  PBadge(label: l.constCollectionNotCollected),
              ],
            ),
          ),
          const SizedBox(height: PSpacing.x0_5),
          Text(
            keepAll(
              owned
                  ? constellationDesc(info)
                  : l.fcolLockedHint(info.starCount),
            ),
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
        ],
      ),
      suffix: Semantics(
        button: true,
        label: ctaName,
        onTap: open,
        excludeSemantics: true,
        child: PButton(
          label: cta,
          size: PButtonSize.small,
          variant: PButtonVariant.neutralOutline,
          onPressed: open,
        ),
      ),
    );
  }
}
