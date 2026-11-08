import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 관측 리포트(I-11 15 ~ 21) — 상단 바 + 흰 면 하나: 주 고르기 → 날 줄 → 날짜 줄 → 관측 결과 → 별빛 모으기 → 별빛 분석 →
/// 못다 켠 별. 주 · 날을 고르면 그 아래 전부가 바뀐다 — 조절하는 줄은 첫 내용과 한 덩어리다(틈 표 T7).
///
/// 데이터: 관측 결과 · 모은 별빛 = 서버(sky/today), 우선순위 분해 · 못다 켠 별 = 할 일 목록 클라 집계(completedAt · due 기준).
/// 거슬러 가는 범위는 지난주까지(Q3-B — 웹 · 앱 같다, 하늘 14일 질의 하나).
class ForestReportScreen extends ConsumerStatefulWidget {
  const ForestReportScreen({super.key});

  @override
  ConsumerState<ForestReportScreen> createState() => _ForestReportScreenState();
}

class _ForestReportScreenState extends ConsumerState<ForestReportScreen> {
  static const TodoFilter _allFilter = (status: null, priority: null);

  /// 0=지난주, 1=이번주 (월요일 시작).
  int _week = 1;
  late String _sel = _ymd(DateTime.now());

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime get _thisMonday {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  List<DateTime> _weekDays(int week) {
    final start = _thisMonday.subtract(Duration(days: week == 0 ? 7 : 0));
    return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  /// 주를 넘긴다 — 그 주의 **같은 요일**을 고른다(아래 전부가 그날 것). 그 요일이 오는 날이면 오늘(10-29 사용자 결정 4).
  void _goWeek(int week) => setState(() {
    _week = week;
    _sel = weekNavSelect(sel: _sel, week: week, now: DateTime.now());
  });

  /// 우선순위 가중치 — 중요 3 · 보통 2 · 여유 1 (design FOREST_WEIGHT).
  static int _weight(String? prio) => switch (prio) {
    'HIGH' => 3,
    'LOW' => 1,
    _ => 2,
  };

  /// 그날 완료한 할 일 — completedAt 은 서버 `[UTC]` 라 로컬 날짜로 바꿔 비교한다(웹 `doneKey` 와 같다).
  List<Todo> _doneOn(List<Todo> todos, String ymd) =>
      todos.where((x) => x.done && localDateKey(x.completedAt) == ymd).toList();

  /// 그날 못다 켠 별 — due=그날 && 미완료.
  List<Todo> _missedOn(List<Todo> todos, String ymd) => todos
      .where((x) => !x.done && x.due != null && _ymd(x.due!) == ymd)
      .toList();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final todayQ = ref.watch(constellationTodayProvider);
    final todosQ = ref.watch(todoListProvider(_allFilter));
    final skyQ = ref.watch(constellationSkyProvider);
    final collectionQ = ref.watch(constellationCollectionProvider);
    final sky = skyQ.value ?? const <SkyDay>[];
    final collection = collectionQ.value;
    final today = todayQ.hasValue ? todayQ.requireValue : null;
    final todos = todosQ.hasValue ? todosQ.requireValue : null;
    // 날별 관측(sky) · 모은 별빛(collection)도 이 리포트의 내용이다 — 처음 받기 실패가 "관측 0" · 수집 줄 없음으로 읽히지
    // 않게 같은 실패 자리로 간다(result-section.md:52)
    final queries = [todayQ, todosQ, skyQ, collectionQ];
    final failed = queries.any((q) => q.loadFailed);

    final todayYmd = _ymd(DateTime.now());
    final days = _weekDays(_week);
    final dows = weekdayLabels(mondayFirst: true);
    final selDate = DateTime.parse(_sel);
    final isToday = _sel == todayYmd;
    final rangeLabel = dateRange(days.first, days.last);

    final Widget content;
    if (failed) {
      content = PResultSection(
        kind: PResultKind.failure,
        title: l.frpLoadFailed,
        description: l.constLoadFailedDesc,
        primaryAction: PResultAction(
          label: l.actionRetry,
          loading: anyLoadRetrying(queries),
          onPressed: () {
            ref.invalidate(constellationTodayProvider);
            ref.invalidate(todoListProvider(_allFilter));
            ref.invalidate(constellationSkyProvider);
            ref.invalidate(constellationCollectionProvider);
          },
        ),
      );
    } else if (today == null ||
        todos == null ||
        !skyQ.hasValue ||
        !collectionQ.hasValue) {
      content = loadingRegion(const _ReportSkeleton());
    } else {
      content = _Body(
        today: today,
        sky: sky,
        collection: collection,
        todos: todos,
        sel: _sel,
        days: days,
        dows: dows,
        todayYmd: todayYmd,
        weight: _weight,
        doneOn: _doneOn,
        missedOn: _missedOn,
        ymd: _ymd,
      );
    }

    return Scaffold(
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.forestReportTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: ListView(
        children: [
          ForestWeekPicker(
            label: rangeLabel,
            canPrev: _week == 1,
            canNext: _week == 0,
            onPrev: () => _goWeek(0),
            onNext: () => _goWeek(1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x3),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _DayCell(
                      date: days[i],
                      dow: dows[i],
                      isToday: _ymd(days[i]) == todayYmd,
                      selected: _ymd(days[i]) == _sel,
                      future: _ymd(days[i]).compareTo(todayYmd) > 0,
                      onTap: () => setState(() => _sel = _ymd(days[i])),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x3,
              PSpacing.x6,
              0,
            ),
            child: _DateRow(date: selDate, showAsOf: isToday),
          ),
          content,
        ],
      ),
    );
  }
}

/// 주 고르기 — ghost 아이콘 버튼 둘 + 가운데 범위(고정폭 · 700). 갈 수 없는 쪽은 막힌 버튼(흐리지 않는다).
@visibleForTesting
class ForestWeekPicker extends StatelessWidget {
  const ForestWeekPicker({
    super.key,
    required this.label,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x1,
        PSpacing.x6,
        PSpacing.x1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PButton.icon(
            icon: LucideIcons.chevronLeft,
            semanticLabel: l.frpPrevWeek,
            variant: PButtonVariant.ghost,
            onPressed: canPrev ? onPrev : null,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PSpacing.x2),
              child: PText(
                label,
                textAlign: TextAlign.center,
                style: PTypography.t5.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          PButton.icon(
            icon: LucideIcons.chevronRight,
            semanticLabel: l.frpNextWeek,
            variant: PButtonVariant.ghost,
            onPressed: canNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// 날 줄 한 칸 — 요일(오늘이면 "오늘" brand 700) + 날짜 원(고른 날 brand 채움 · 오는 날 옅은 글, 누르지 못한다).
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.dow,
    required this.isToday,
    required this.selected,
    required this.future,
    required this.onTap,
  });

  final DateTime date;
  final String dow;
  final bool isToday;
  final bool selected;
  final bool future;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        // 원은 글자 크기를 따라 늘되 칸 폭을 넘지 않는다(200% 에서도 7칸이 한 줄).
        final circle = math.min(
          box.maxWidth,
          math.max(PSpacing.x9, scaler.scale(22) + PSpacing.x2),
        );
        return Semantics(
          button: true,
          enabled: !future,
          selected: selected,
          label: monthDayDow(date) + (isToday ? ', ${l.dateToday}' : ''),
          onTap: future ? null : onTap,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: future ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: PTouch.min),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpacing.x1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isToday ? l.dateToday : dow,
                      maxLines: 1,
                      style: PTypography.t3.copyWith(
                        color: isToday ? c.fgBrand : c.fgNeutralSubtle,
                        fontWeight: isToday ? FontWeight.w700 : null,
                      ),
                    ),
                    const SizedBox(height: PSpacing.x1),
                    Container(
                      width: circle,
                      height: circle,
                      alignment: Alignment.center,
                      decoration: selected
                          ? BoxDecoration(
                              color: c.bgBrandSolid,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Text(
                        '${date.day}',
                        style: PTypography.t5.copyWith(
                          color: selected
                              ? c.staticWhite
                              : (future ? c.fgNeutralSubtle : c.fgNeutral),
                          fontWeight: future && !selected
                              ? FontWeight.w500
                              : FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 날짜 줄 — 왼쪽 "10월 22일 (목)", 오른쪽(오늘일 때만) "오후 11:58 기준". 좁으면 오른쪽 글이 줄을 바꾼다.
class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.showAsOf});

  final DateTime date;
  final bool showAsOf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: PSpacing.x1,
      spacing: PSpacing.x2,
      children: [
        PText(
          monthDayDow(date),
          style: PTypography.t5.copyWith(
            color: c.fgNeutral,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (showAsOf)
          PText(
            l.frpAsOf(timeOfDay12(DateTime.now())),
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
      ],
    );
  }
}

/// 불러오는 중 — 관측 결과 · 지표 · 막대 · 줄 자리만 스켈레톤(날 줄 틀은 위에서 이미 그렸다).
class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x4,
        PSpacing.x6,
        PSpacing.x6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PSkeleton(
                width: PSpacing.x8,
                height: PSpacing.x8,
                radius: PSkeletonRadius.r8,
              ),
              const SizedBox(width: PSpacing.x3),
              Expanded(child: PSkeleton.text(PTypography.t5)),
            ],
          ),
          const SizedBox(height: 36),
          PSkeleton.text(PTypography.t5, width: 120),
          const SizedBox(height: PSpacing.x3),
          const PSkeleton(height: 96),
          const SizedBox(height: 36),
          PSkeleton.text(PTypography.t5, width: 120),
          const SizedBox(height: PSpacing.x3),
          const PSkeleton(height: 160),
        ],
      ),
    );
  }
}

/// 구역 머리 — 왼쪽 제목(t5 700) + 오른쪽 자리.
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            headingLevel: 2,
            child: Text(
              keepAll(title),
              style: PTypography.t5.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.today,
    required this.sky,
    required this.collection,
    required this.todos,
    required this.sel,
    required this.days,
    required this.dows,
    required this.todayYmd,
    required this.weight,
    required this.doneOn,
    required this.missedOn,
    required this.ymd,
  });

  final ConstellationToday today;
  final List<SkyDay> sky;
  final ConstellationCollectionData? collection;
  final List<Todo> todos;
  final String sel;
  final List<DateTime> days;
  final List<String> dows;
  final String todayYmd;
  final int Function(String?) weight;
  final List<Todo> Function(List<Todo>, String) doneOn;
  final List<Todo> Function(List<Todo>, String) missedOn;
  final String Function(DateTime) ymd;

  /// 그날 별빛 — 오늘 = 서버 points(메모 포함), 지난날 = 하늘 기록 points, 기록이 없으면 null.
  int? _skyPoints(String ds, Map<String, SkyDay> byDate) =>
      ds == todayYmd ? today.points : byDate[ds]?.points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final byDate = {for (final d in sky) d.date: d};
    final entryByKey = {
      if (collection != null)
        for (final e in collection!.entries)
          e.constellation.constellationKey: e,
    };
    final isToday = sel == todayYmd;
    final selSky = byDate[sel];
    final doneList = doneOn(todos, sel);
    final todoPts = doneList.fold<int>(0, (s, x) => s + weight(x.priority));
    final pts = isToday ? today.points : (selSky?.points ?? todoPts);
    final goal = isToday
        ? today.goal
        : (selSky?.constellationKey != null
              ? (entryByKey[selSky!.constellationKey!]
                        ?.constellation
                        .starCount ??
                    today.goal)
              : today.goal);
    final pctRaw = goal <= 0 ? 0 : ((pts / goal) * 100).clamp(0, 100);
    final pct = formatProgress(pctRaw);
    final missed = missedOn(todos, sel);
    final selEntry = selSky?.constellationKey != null
        ? entryByKey[selSky!.constellationKey!]
        : null;

    // 주간 막대 최대값 — 목표 이상 보장.
    int dayTotal(String ds) {
      final t = doneOn(
        todos,
        ds,
      ).fold<int>(0, (s, x) => s + weight(x.priority));
      final p = _skyPoints(ds, byDate);
      return p != null && p > t ? p : t;
    }

    var weekMax = goal;
    for (final d in days) {
      final v = dayTotal(ymd(d));
      if (v > weekMax) weekMax = v;
    }

    const pad = EdgeInsets.symmetric(horizontal: PSpacing.x6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 관측 결과 (T7 날짜 줄 아래 16) ──
        Padding(
          padding: pad.copyWith(top: PSpacing.x4),
          child: _ResultLine(
            today: today,
            isToday: isToday,
            selEntry: selEntry,
            selSky: selSky,
          ),
        ),
        // ── 별빛 모으기 (T8 앞 내용 아래 16 + 구역 위 20) ──
        Padding(
          padding: pad.copyWith(top: PSpacing.x4 + PSpacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHead(
                title: l.frpStarGather,
                trailing: PBadge(
                  label: pctRaw >= 100 ? l.frpPctBang(pct) : l.frpPctBadge(pct),
                  tone: PBadgeTone.positive,
                ),
              ),
              const SizedBox(height: PSpacing.x3),
              _Metric(label: l.frpTileStar, value: l.frpTileStarVal(pts)),
              const SizedBox(height: PSpacing.x4),
              _Metric(
                label: l.frpTileDone,
                value: l.frpTileDoneVal(doneList.length),
              ),
            ],
          ),
        ),
        // ── 별빛 분석 ──
        Padding(
          padding: pad.copyWith(top: PSpacing.x4 + PSpacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHead(title: l.frpAnalysis),
              const SizedBox(height: PSpacing.x3),
              _Legend(
                counts: {
                  for (final p in kTodoPrios)
                    p.code: doneList
                        .where((x) => (x.priority ?? 'MEDIUM') == p.code)
                        .length,
                },
                weight: weight,
                memoPts: isToday
                    ? math.max(0, today.points - todoPts)
                    : (selSky != null
                          ? math.max(0, selSky.points - todoPts)
                          : 0),
              ),
              const SizedBox(height: PSpacing.x4),
              Semantics(
                image: true,
                label: l.frpBarsName,
                child: ExcludeSemantics(
                  child: _Bars(
                    days: days,
                    dows: dows,
                    ymd: ymd,
                    sel: sel,
                    weekMax: weekMax,
                    partsOf: (ds) {
                      final todoParts = {
                        for (final p in kTodoPrios)
                          p.code:
                              doneOn(todos, ds)
                                  .where(
                                    (x) => (x.priority ?? 'MEDIUM') == p.code,
                                  )
                                  .length *
                              weight(p.code),
                      };
                      final t = todoParts.values.fold<int>(0, (s, v) => s + v);
                      final p = _skyPoints(ds, byDate);
                      return (
                        todo: todoParts,
                        memo: p != null && p > t ? p - t : 0,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── 못다 켠 별 ──
        if (missed.isNotEmpty || isToday) ...[
          Padding(
            padding: pad.copyWith(top: PSpacing.x4 + PSpacing.x5),
            child: _SectionHead(
              title: l.frpMissed,
              trailing: missed.isEmpty
                  ? null
                  : Text(
                      l.frpMissedCount(missed.length),
                      style: PTypography.t4.copyWith(
                        color: c.fgNeutralSubtle,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
          ),
          if (missed.isEmpty)
            Padding(
              padding: pad.copyWith(top: PSpacing.x2),
              child: Text(
                keepAll(l.frpMissedAllDone),
                style: PTypography.t4.copyWith(color: c.fgNeutralMuted),
              ),
            )
          else
            PList(
              semanticLabel: l.frpMissed,
              children: [
                for (final t in missed)
                  PListItem(
                    title: t.title,
                    detail: l.frpMissedWeight(weight(t.priority)),
                    align: PListAlign.top,
                    suffix: PBadge(
                      label: todoPrioLabel(l, t.priority),
                      tone: t.priority == 'HIGH'
                          ? PBadgeTone.critical
                          : PBadgeTone.neutral,
                    ),
                  ),
              ],
            ),
        ],
        const SizedBox(height: PSpacing.x6),
      ],
    );
  }
}

/// 관측 결과 한 줄 + 도장.
class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.today,
    required this.isToday,
    required this.selEntry,
    required this.selSky,
  });

  final ConstellationToday today;
  final bool isToday;
  final CollectionEntry? selEntry;
  final SkyDay? selSky;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final valueStyle = PTypography.t5.copyWith(
      color: c.fgNeutral,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final Widget value;
    if (isToday) {
      value = Text(
        keepAll(
          l.frpObsToday(
            constellationName(today.constellation),
            today.points > today.goal ? today.goal : today.points,
            today.goal,
          ),
        ),
        style: valueStyle,
      );
    } else if (selEntry != null) {
      value = Row(
        children: [
          ExcludeSemantics(
            child: ConstellationIcon(
              info: selEntry!.constellation,
              color: constellationColor(
                context,
                selEntry!.constellation.colorKey,
              ),
              size: PSpacing.x5,
              linesOnly: true,
            ),
          ),
          const SizedBox(width: PSpacing.x1_5),
          Expanded(
            child: Text(
              keepAll(
                l.frpObsCollected(constellationName(selEntry!.constellation)),
              ),
              style: valueStyle,
            ),
          ),
        ],
      );
    } else {
      final withered = selSky?.isWithered == true;
      value = Text(
        keepAll(
          withered
              ? (selSky!.guardUsed ? l.frpObsWitheredGuard : l.frpObsWithered)
              : l.frpObsRest,
        ),
        style: valueStyle.copyWith(color: c.fgNeutralSubtle),
      );
    }

    final stamp = isToday && today.streak > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: PSpacing.x8,
          height: PSpacing.x8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.bgNeutralWeak,
            borderRadius: BorderRadius.circular(PRounded.r2_5),
          ),
          child: Icon(
            LucideIcons.telescope,
            size: PSpacing.x5,
            color: c.fgNeutralMuted,
          ),
        ),
        const SizedBox(width: PSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PText(
                l.frpObsResult,
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
              value,
            ],
          ),
        ),
        if (stamp) ...[
          const SizedBox(width: PSpacing.x3),
          _Stamp(streak: today.streak),
        ],
      ],
    );
  }
}

/// 연속 관측 도장 — 지름 72 · 안쪽 2px · −8° 기울임. 줄 안 오른쪽에 자리를 가져 글과 겹치지 않는다.
///
/// 글을 줄여 맞추지 않는다 — 사용자가 키운 글자 크기를 화면이 다시 줄이는 꼴이라서, 원이 글자 배율을 따라 커진다
/// (72 × 배율, 안쪽 여백 12 도 같은 비율. 저축률 고리와 같은 방식). 글 상자는 원에 내접한다.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.streak});

  final int streak;

  static const double base = 72;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final k = MediaQuery.textScalerOf(context).scale(1);
    final size = base * k;
    return Semantics(
      container: true,
      label: l.frpStampName(streak),
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: -8 * math.pi / 180,
          child: Container(
            key: const ValueKey('report-stamp'),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.bgCriticalWeak,
              border: Border.all(color: c.strokeCriticalSolid, width: 2),
            ),
            child: Padding(
              padding: EdgeInsets.all(PSpacing.x3 * k),
              child: OverflowBox(
                maxWidth: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.frpStampDays(streak),
                      softWrap: false,
                      style: PTypography.t4.copyWith(
                        color: c.fgCriticalContrast,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    PText(
                      l.frpStampLabel,
                      softWrap: false,
                      style: PTypography.t1.copyWith(
                        color: c.fgCriticalContrast,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 지표 하나 — 라벨(t3 500) 아래 4 값(t9 700). 폰은 한 줄에 하나.
class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          keepAll(label),
          style: PTypography.t3.copyWith(
            color: c.fgNeutralSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: PSpacing.x1),
        Text(
          value,
          style: PTypography.t9.copyWith(
            color: c.fgNeutral,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// 막대 색 — 차트 배정 순서: 중요 파랑 · 보통 초록 · 여유 주황 · 메모 별빛 보라.
Color _prioBarColor(PColors c, String code) => switch (code) {
  'HIGH' => c.chartBlue,
  'LOW' => c.chartOrange,
  _ => c.chartGreen,
};

/// 범례 — 세로 6. 색 칸 10 + "{우선순위} 완료 {n}" + "+{무게}", 넷째는 "메모 별빛" + "+{n}".
class _Legend extends StatelessWidget {
  const _Legend({
    required this.counts,
    required this.weight,
    required this.memoPts,
  });

  final Map<String, int> counts;
  final int Function(String?) weight;
  final int memoPts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    Widget item(Color color, String label, String trailing) => Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(PRounded.r0_5),
          ),
        ),
        const SizedBox(width: PSpacing.x2),
        Flexible(
          child: Text(
            keepAll(label),
            style: PTypography.t4.copyWith(color: c.fgNeutral),
          ),
        ),
        const SizedBox(width: PSpacing.x2),
        Text(
          trailing,
          style: PTypography.t3.copyWith(
            color: c.fgNeutralSubtle,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x1_5,
      children: [
        for (final p in kTodoPrios)
          item(
            _prioBarColor(c, p.code),
            l.frpLegendItem(todoPrioLabel(l, p.code), counts[p.code] ?? 0),
            '+${weight(p.code)}',
          ),
        item(c.chartViolet, l.frpLegendMemo, '+$memoPts'),
      ],
    );
  }
}

/// 요일 막대 7열 — 사이 4 · 폭 20 · 위 모서리 4 · 영역 120 · 아래부터 중요 → 보통 → 여유 → 메모. 막대는 누르지 않는다.
class _Bars extends StatelessWidget {
  const _Bars({
    required this.days,
    required this.dows,
    required this.ymd,
    required this.sel,
    required this.weekMax,
    required this.partsOf,
  });

  final List<DateTime> days;
  final List<String> dows;
  final String Function(DateTime) ymd;
  final String sel;
  final int weekMax;
  final ({Map<String, int> todo, int memo}) Function(String) partsOf;

  static const double areaHeight = 120;
  static const double barWidth = 20;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: PSpacing.x1),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: areaHeight,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _Bar(parts: partsOf(ymd(days[i])), weekMax: weekMax),
                  ),
                ),
                Container(height: 1, color: c.strokeNeutralSubtle),
                const SizedBox(height: PSpacing.x2),
                Container(
                  // 최소 28 — 글자가 커지면 원도 따라 커진다(200% 글이 28 상자에 갇히지 않는다)
                  width: math.max(
                    PSpacing.x7,
                    MediaQuery.textScalerOf(context).scale(18),
                  ),
                  height: math.max(
                    PSpacing.x7,
                    MediaQuery.textScalerOf(context).scale(18),
                  ),
                  alignment: Alignment.center,
                  decoration: ymd(days[i]) == sel
                      ? BoxDecoration(
                          color: c.bgBrandSolid,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    dows[i],
                    style: PTypography.t3.copyWith(
                      color: ymd(days[i]) == sel
                          ? c.staticWhite
                          : c.fgNeutralSubtle,
                      fontWeight: ymd(days[i]) == sel ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.parts, required this.weekMax});

  final ({Map<String, int> todo, int memo}) parts;
  final int weekMax;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 아래부터 중요 → 보통 → 여유 → 메모.
    final segs = <(Color, int)>[
      for (final p in kTodoPrios)
        if ((parts.todo[p.code] ?? 0) > 0)
          (_prioBarColor(c, p.code), parts.todo[p.code]!),
      if (parts.memo > 0) (c.chartViolet, parts.memo),
    ];
    final total = segs.fold<int>(0, (s, e) => s + e.$2);
    if (total == 0) return const SizedBox.shrink();
    final frac = weekMax <= 0 ? 0.0 : (total / weekMax).clamp(0.0, 1.0);
    final h = _Bars.areaHeight * (frac < 0.08 ? 0.08 : frac);
    final heights = barPieceHeights([for (final e in segs) e.$2], h);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(PRounded.r1),
      ),
      child: SizedBox(
        width: _Bars.barWidth,
        height: h,
        child: Column(
          // 첫 조각이 맨 아래 — 위에서부터 거꾸로 그린다.
          children: [
            for (var k = segs.length - 1; k >= 0; k--)
              SizedBox(
                width: _Bars.barWidth,
                height: heights[k],
                child: ColoredBox(color: segs[k].$1),
              ),
          ],
        ),
      ),
    );
  }
}

/// 조각 높이(px) — 0 이 아닌 조각마다 max(2, 비율 높이), 막대 전체 높이 [total] 은 그대로 두고 넘친 만큼을 가장 큰 조각에서 뺀다
/// (고른 그림 `.stk i{min-height:2px}` — 범례에 있는 색이 막대에서 사라지지 않게). 합이 [total] 보다 작을 수는 없다.
@visibleForTesting
List<double> barPieceHeights(List<int> values, double total) {
  final sum = values.fold<int>(0, (s, v) => s + v);
  if (sum <= 0) return [for (final _ in values) 0.0];
  const minPiece = 2.0;
  final out = [for (final v in values) math.max(minPiece, total * v / sum)];
  final over = out.fold<double>(0, (s, v) => s + v) - total;
  if (over > 0) {
    var big = 0;
    for (var k = 1; k < out.length; k++) {
      if (out[k] > out[big]) big = k;
    }
    out[big] = math.max(minPiece, out[big] - over);
  }
  return out;
}

/// 주 넘기기 규칙 — 지금 고른 날 [sel] 에서 이전 주([week] 0)는 7일 앞, 다음 주(1)는 7일 뒤 = **같은 요일**. 그 날이 오는 날이면
/// 오늘. 웹 · 앱 같은 규칙이다(10-29 사용자 결정 4 · 웹 표본 27 줄이 달 · 해 · 윤년 경계를 잠근다).
@visibleForTesting
String weekNavSelect({
  required String sel,
  required int week,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final s = DateTime.parse(sel);
  final candidate = DateTime(s.year, s.month, s.day + (week == 0 ? -7 : 7));
  final picked = candidate.isAfter(today) ? today : candidate;
  return '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
}
