import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/collection_card.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_detail_sheet.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/constellation/presentation/my_sky_card.dart';
import 'package:groo_damda_app/features/constellation/presentation/night_sky_hero.dart';
import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 밤하늘 화면(I-11 7 ~ 12) — 상단 바 + 띠 셋: ① 오늘(하늘 그림 + 관측 리포트 줄) ② 나의 밤하늘 ③ 별자리 도감.
///
/// 할 일 화면에서는 [밤하늘] 패널의 "밤하늘" 단추로 들어온다. 질의 하나 = 실패 상자 하나 — 오늘이 실패하면 화면 전체,
/// 나의 밤하늘 · 도감은 자기 띠 안에서만(서버 오류 원문은 그리지 않는다).
class NightSkyScreen extends ConsumerWidget {
  const NightSkyScreen({super.key});

  static const TodoFilter _allFilter = (status: null, priority: null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final todayQ = ref.watch(constellationTodayProvider);
    final skyQ = ref.watch(constellationSkyProvider);
    final collectionQ = ref.watch(constellationCollectionProvider);
    final todos = ref.watch(todoListProvider(_allFilter)).value;

    final now = DateTime.now();
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // completedAt 은 서버가 준 `[UTC]` 라 로컬 날짜로 바꿔 비교한다(KST 새벽 완료가 전날로 밀리지 않게).
    final doneToday = (todos ?? const [])
        .where((x) => x.done && localDateKey(x.completedAt) == todayIso)
        .length;

    final today = todayQ.hasValue ? todayQ.requireValue : null;
    final sky = skyQ.hasValue ? skyQ.requireValue : null;
    final collection = collectionQ.hasValue ? collectionQ.requireValue : null;

    final Widget body;
    if (todayQ.loadFailed) {
      body = ListView(
        children: [
          PScreenSection(
            padding: EdgeInsets.zero,
            child: PResultSection(
              kind: PResultKind.failure,
              title: l.constFailToday,
              description: l.constLoadFailedDesc,
              primaryAction: PResultAction(
                label: l.actionRetry,
                loading: todayQ.loadRetrying,
                onPressed: () {
                  ref.invalidate(constellationTodayProvider);
                  ref.invalidate(constellationSkyProvider);
                  ref.invalidate(constellationCollectionProvider);
                },
              ),
            ),
          ),
        ],
      );
    } else {
      body = ListView(
        children: PScreenBands.children([
          PScreenSection(
            padding: EdgeInsets.zero,
            child: today == null
                ? const _TodaySkeleton()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          PSpacing.x6,
                          PSpacing.x6,
                          PSpacing.x6,
                          0,
                        ),
                        child: NightSkyHero(
                          today: today,
                          doneToday: doneToday,
                          onOpen: () => showTodayConstellationDetail(
                            context,
                            today,
                            entry: _entryOf(collection, today),
                          ),
                        ),
                      ),
                      const SizedBox(height: PSpacing.x4),
                      _ReportRow(
                        today: today,
                        sky: sky ?? const [],
                        onOpen: () => context.push('/forest-report'),
                      ),
                      const SizedBox(height: PSpacing.x2),
                    ],
                  ),
          ),
          if (sky == null || today == null) ...[
            PScreenSection(
              child: _SkyBand(
                today: today,
                sky: sky,
                entries: const [],
                failed: skyQ.loadFailed,
                retrying: skyQ.loadRetrying,
                onRetry: () => ref.invalidate(constellationSkyProvider),
              ),
            ),
          ] else
            PScreenSection(
              child: MySkyCard(
                sky: sky,
                today: today,
                entries: collection?.entries ?? const [],
              ),
            ),
          PScreenSection(
            padding: EdgeInsets.zero,
            child: collection == null
                ? _CollectionBand(
                    failed: collectionQ.loadFailed,
                    retrying: collectionQ.loadRetrying,
                    onRetry: () =>
                        ref.invalidate(constellationCollectionProvider),
                  )
                : CollectionCard(
                    collection: collection,
                    todayKey: today?.constellation.constellationKey ?? '',
                    today: today,
                  ),
          ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.nightSkyTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: PPullToRefresh(
        onRefresh: () async {
          ref.invalidate(constellationTodayProvider);
          ref.invalidate(constellationSkyProvider);
          ref.invalidate(constellationCollectionProvider);
          await ref.read(constellationTodayProvider.future);
        },
        child: body,
      ),
    );
  }
}

/// 띠 ② — 실패면 자기 띠 안 실패 상자, 아직이면 머리 + 칸 스켈레톤. (오늘 · 도감이 아직 없을 때도 이 자리를 쓴다.)
class _SkyBand extends StatelessWidget {
  const _SkyBand({
    required this.today,
    required this.sky,
    required this.entries,
    required this.failed,
    required this.onRetry,
    this.retrying = false,
  });

  final ConstellationToday? today;
  final List<SkyDay>? sky;
  final List<CollectionEntry> entries;
  final bool failed;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
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
        const SizedBox(height: PSpacing.x3),
        if (failed)
          PResultSection(
            kind: PResultKind.failure,
            size: PResultSize.medium,
            placement: PResultPlacement.card,
            title: l.constFailSky,
            description: l.constLoadFailedDesc,
            primaryAction: PResultAction(
              label: l.actionRetry,
              loading: retrying,
              onPressed: onRetry,
            ),
          )
        else
          Column(
            children: [
              for (var r = 0; r < 2; r++) ...[
                if (r > 0) const SizedBox(height: PSpacing.x2),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: PSpacing.x1_5),
                      const Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: PSkeleton(radius: PSkeletonRadius.r8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// 띠 ③ 도감 — 실패 상자 또는 머리 + 줄 스켈레톤 다섯.
class _CollectionBand extends StatelessWidget {
  const _CollectionBand({
    required this.failed,
    required this.onRetry,
    this.retrying = false,
  });

  final bool failed;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
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
        if (failed)
          PResultSection(
            kind: PResultKind.failure,
            size: PResultSize.medium,
            placement: PResultPlacement.listCard,
            title: l.constFailCollection,
            description: l.constLoadFailedDesc,
            primaryAction: PResultAction(
              label: l.actionRetry,
              loading: retrying,
              onPressed: onRetry,
            ),
          )
        else
          for (var i = 0; i < 5; i++) const _RowSkeleton(),
      ],
    );
  }
}

/// List 줄 자리 스켈레톤 — 타일 40 + 두 줄.
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.x6,
        vertical: PSpacing.x3,
      ),
      child: Row(
        children: [
          const PSkeleton(
            width: PSpacing.x10,
            height: PSpacing.x10,
            radius: PSkeletonRadius.r6,
          ),
          const SizedBox(width: PSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PSkeleton.text(PTypography.t5, width: 140),
                const SizedBox(height: PSpacing.x1_5),
                PSkeleton.text(PTypography.t3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 띠 ① 불러오는 중 — 하늘 그림 자리(모서리 16 · 높이 168) + 리포트 줄 자리.
class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x6,
            PSpacing.x6,
            PSpacing.x4,
          ),
          child: PSkeleton(height: 168, radius: PSkeletonRadius.r16),
        ),
        const _RowSkeleton(),
        const SizedBox(height: PSpacing.x2),
      ],
    );
  }
}

/// 관측 리포트로 가는 줄(I-11 9) — 앞 하늘 타일 40 + 제목 + 오늘의 목표 배지, 아래 6 에 최근 7일 점.
class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.today,
    required this.sky,
    required this.onOpen,
  });

  final ConstellationToday today;
  final List<SkyDay> sky;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final days = sky.length > 7 ? sky.sublist(sky.length - 7) : sky;
    final todayDate = sky.isNotEmpty ? sky.last.date : '';
    final name = constellationName(today.constellation);

    return Semantics(
      button: true,
      label: l.frpRowName(name),
      onTap: onOpen,
      excludeSemantics: true,
      child: PList(
        children: [
          PListButtonItem(
            title: l.forestReportTitle,
            onTap: onOpen,
            prefix: Container(
              width: PListTile.size,
              height: PListTile.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PRounded.r3),
                gradient: skyGradient(c),
              ),
              child: Icon(
                LucideIcons.telescope,
                size: PSpacing.x5,
                color: c.fgNeutralInverted,
              ),
            ),
            suffix: Icon(
              LucideIcons.chevronRight,
              size: PSpacing.x4_5,
              color: c.fgNeutralSubtle,
            ),
            titleSuffix: [
              PBadge(
                label: name,
                prefixIcon: LucideIcons.star,
                variant: PBadgeVariant.solid,
                tone: PBadgeTone.brand,
              ),
            ],
            detailChild: Padding(
              padding: const EdgeInsets.only(top: PSpacing.x1_5),
              child: Row(
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: PSpacing.x1 + 1),
                    _WeekDot(
                      day: days[i],
                      isToday: days[i].date == todayDate,
                      stageIcon: skyStageIcon(today.points),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 주간 점(지름 22) — 오늘 = 단계 아이콘(brand 채움), 수집 = 별(차트 옅은 바탕), 흐린 밤 = 구름, 쉰 날 = 점 4.
class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.day,
    required this.isToday,
    required this.stageIcon,
  });

  final SkyDay day;
  final bool isToday;
  final IconData stageIcon;

  static const double size = 22;
  static const double iconSize = 12;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final grown = day.isGrown && day.colorKey != null;
    final colors = constellationRoleColors(c, day.colorKey ?? 'gray');

    final Color bg;
    final Widget glyph;
    if (isToday) {
      bg = c.bgBrandSolid;
      glyph = Icon(stageIcon, size: iconSize, color: c.staticWhite);
    } else if (grown) {
      bg = colors.weak;
      glyph = Icon(LucideIcons.star, size: iconSize, color: colors.strong);
    } else if (day.isWithered) {
      bg = c.bgNeutralWeak;
      glyph = Icon(
        LucideIcons.cloudy,
        size: iconSize,
        color: c.fgNeutralSubtle,
      );
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
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: glyph,
    );
  }
}

/// 오늘의 목표 별자리의 도감 줄 — 도감을 아직 못 받았으면 null.
CollectionEntry? _entryOf(
  ConstellationCollectionData? collection,
  ConstellationToday today,
) {
  if (collection == null) return null;
  for (final e in collection.entries) {
    if (e.constellation.constellationKey ==
        today.constellation.constellationKey) {
      return e;
    }
  }
  return null;
}
