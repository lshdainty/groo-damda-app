import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_detail_sheet.dart';
import 'package:groo_damda_app/features/constellation/presentation/night_sky_hero.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/features/todo/application/todo_providers.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_ledger.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_detail_dialog.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:groo_damda_app/features/todo/presentation/widgets/todo_filter_sheet.dart';
import 'package:groo_damda_app/features/todo/presentation/widgets/todo_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/month_picker/p_month_picker.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/icons/filled_star.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/p_floating_action_button.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/scroll/hold_ids.dart';
import 'package:groo_damda_app/shared/scroll/scroll_to_keyed.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 같은 줄의 두 번째 완료 누름을 무시하는 시간 — 따닥 막기(웹 `DOUBLE_CLICK_GUARD_MS`). 붙들기([kListHold] 700)보다 짧아야 한다.
const Duration kTodoDoubleTapGuard = Duration(milliseconds: 600);

/// 할 일 — 폰 원장(I-10 1A · 2B). 흰 화면 하나에 머리(달 이동 · 오늘 할 일 · 주 달력)와 날짜 묶음 목록이 끝까지 선 하나로 이어진다.
///
/// 머리는 ds Scroll Auto Hide 가 통째로 숨긴다(가계부와 같은 부품 — [LedgerMonthNav] · [LedgerTotalRow] · [LedgerCalendarGrid]).
/// 묶음 안은 남은 일 위 · 끝낸 일 아래이고, 누른 줄은 700ms 제자리에 남았다가 내려간다(QA #29). 완료는 누르는 순간 바뀐다(낙관 갱신).
/// 밤하늘 게임 요소는 [밤하늘] 패널 + 전용 화면(/night-sky, /forest-report)으로 분리 — 들어가는 길만 이 화면이 잇는다.
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});
  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  /// 전체(status=null) fetch — 상세/칸반과 동일 family 키 공유.
  static const TodoFilter _allFilter = (status: null, priority: null);

  late DateTime _month = monthStart(DateTime.now());
  String? _selected;
  bool _expanded = false;
  bool _skyOpen = false;
  TodoFilterState _filter = TodoFilterState.empty;

  final Map<String, GlobalKey> _dayKeys = {};
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _listKey = GlobalKey();

  /// 숨는 머리(Scroll Auto Hide)의 높이 — 목록 맨 위 여백이자 스크롤 스파이가 기준으로 삼는 선.
  double _headerH = 0;
  bool _lock = false;
  Timer? _lockTimer;

  /// 낙관 갱신 — 누른 줄의 끝냄 여부를 서버 응답 전에 먼저 바꿔 그린다. 실패하면 지워 되돌린다.
  final Map<int, bool> _optimisticDone = {};
  final Map<int, int> _optimisticToken = {};
  final Map<int, DateTime> _lastToggleAt = {};

  /// 방금 끝냄을 누른 줄 — 700ms 제자리에 남긴다(정렬 · 완료 숨기기 둘 다).
  final HoldIds _hold = HoldIds();

  @override
  void initState() {
    super.initState();
    _selected = todoYmd(DateTime.now());
    _scrollCtrl.addListener(_onScroll);
    _hold.addListener(_onHoldChanged);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _hold
      ..removeListener(_onHoldChanged)
      ..dispose();
    super.dispose();
  }

  void _onHoldChanged() {
    if (mounted) setState(() {});
  }

  void _lockFor(int ms) {
    _lock = true;
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(milliseconds: ms), () => _lock = false);
  }

  /// 스크롤 스파이 — 맨 위 날짜 그룹을 선택일로 동기. 머리 숨기기는 Scroll Auto Hide 가 맡는다.
  void _onScroll() {
    if (!_scrollCtrl.hasClients || _lock) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    final listTop = listBox.localToGlobal(Offset.zero).dy;
    double best = double.negativeInfinity;
    String? cur;
    for (final e in _dayKeys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy - listTop;
      if (top <= _headerH + 28 && top > best) {
        best = top;
        cur = e.key;
      }
    }
    if (cur != null && cur != _selected) {
      setState(() => _selected = cur);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showPMonthPicker(context, initial: _month);
    if (picked != null && mounted) _setMonth(picked);
  }

  void _setMonth(DateTime next) {
    final today = DateTime.now();
    setState(() {
      _month = next;
      _expanded = false;
      _selected = (today.year == next.year && today.month == next.month)
          ? todoYmd(today)
          : null;
    });
    _lockFor(800);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// [order] 는 리스트에 **그려진 순서 그대로**의 그룹 목록이다(가계부와 같은 이유로 필드가 아니라 인자다).
  void _scrollToDay(String ds, List<String> order) {
    // 여러 프레임에 걸쳐 뛰므로 스크롤 스파이를 그동안 재운다.
    _lockFor(1200);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      scrollToKeyedItem(
        controller: _scrollCtrl,
        key: _dayKeys[ds],
        index: order.indexOf(ds),
        count: order.length,
      );
    });
  }

  /// 서버 값에 낙관 갱신을 덮은 할 일.
  Todo _effective(Todo x) {
    final done = _optimisticDone[x.rowId];
    if (done == null || done == x.done) return x;
    return x.copyWith(status: done ? 'COMPLETED' : 'PENDING');
  }

  /// 완료 누름 — 누르는 순간 바뀌고(스피너 · 막힘 없음), 실패하면 되돌리고 그 자리에서 한 번 알린다.
  ///
  /// 따닥 막기는 그대로다 — 같은 줄 600ms 안의 두 번째 누름은 무시한다. 그 뒤 다시 누르면(앞 요청이 아직 안 끝났어도) 그 뒤 상태로 다시
  /// 보낸다(줄마다 토큰을 두어 앞 요청이 늦게 끝나도 뒤 낙관 값을 지우지 않는다).
  Future<void> _toggleDone(Todo x) async {
    final now = DateTime.now();
    final last = _lastToggleAt[x.rowId];
    if (last != null && now.difference(last) < kTodoDoubleTapGuard) return;
    _lastToggleAt[x.rowId] = now;
    final nextDone = !x.done;
    final token = (_optimisticToken[x.rowId] ?? 0) + 1;
    _optimisticToken[x.rowId] = token;
    setState(() => _optimisticDone[x.rowId] = nextDone);
    _hold.hold(x.rowId);
    final l = AppLocalizations.of(context);
    // 요청이 끝나기 전에 화면이 닫혀도 목록을 비울 수 있게 컨테이너를 미리 잡는다(`ref` 는 unmount 뒤에 던진다 — 태그 화면과 같다).
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(todoRepositoryProvider.future);
      // 서버가 이번 토글의 실제 적립량을 돌려준다 — 낙관 예측으로 띄우면 평생 1회
      // 정책에 걸려 적립이 0 이어도 "+N" 이 떠서 거짓말이 된다(웹 TodoPage 정합).
      final gain = await repo.setStatus(
        x.rowId,
        nextDone ? 'COMPLETED' : 'PENDING',
      );
      container.invalidate(todoListProvider);
      // 별빛 적립/회수 부수효과 — 별자리 상태 일괄 갱신.
      final constToday = container.read(constellationTodayProvider).value;
      container
        ..invalidate(constellationTodayProvider)
        ..invalidate(constellationSkyProvider)
        ..invalidate(constellationCollectionProvider);
      if (mounted && gain > 0 && constToday != null && !constToday.collected) {
        final left = constToday.goal - (constToday.points + gain);
        PSnackbar.maybeOf(context)?.show(
          message: left <= 0
              ? l.tdmStarToastCollected(gain)
              : l.tdmStarToastGain(gain, left),
          tone: PSnackbarTone.positive,
        );
      }
      // 새 목록이 올 때까지 낙관 값을 쥐고 있는다 — 먼저 걷으면 옛 서버 값으로 한 번 되돌아가 깜빡인다.
      try {
        await container.read(todoListProvider(_allFilter).future);
      } on Object {
        // 목록을 다시 못 받아도 저장은 끝났다 — 화면은 이전 목록을 그대로 둔다.
      }
    } on ApiException {
      // 서버 원문을 띄우지 않는다(전역 오류 알림은 이 요청에서 껐다) — 되돌리고 새 글 한 번.
      if (mounted) {
        PSnackbar.maybeOf(context)?.show(
          message: l.todoToggleFailed,
          tone: PSnackbarTone.critical,
          action: PSnackbarAction(
            label: l.actionRetry,
            onPressed: () => _toggleDone(x),
          ),
        );
      }
    } finally {
      if (_optimisticToken[x.rowId] == token) {
        _optimisticToken.remove(x.rowId);
        if (mounted) {
          setState(() => _optimisticDone.remove(x.rowId));
        } else {
          _optimisticDone.remove(x.rowId);
        }
      }
    }
  }

  /// 거르기 시트의 태그 칩 — 설정 태그 차례 → 할 일에만 남은 이름 → "태그 없음"(그런 할 일이 있을 때만, 맨 뒤).
  List<String> _tagChoices(List<Todo> all) {
    final server = ref.read(todoTagListProvider).value ?? const [];
    final names = <String>[for (final t in server) t.tagName];
    var hasNone = false;
    for (final x in all) {
      final key = todoTagOf(x);
      if (key == kTodoNoTagKey) {
        hasNone = true;
      } else if (!names.contains(key)) {
        names.add(key);
      }
    }
    return [...names, if (hasNone) kTodoNoTagKey];
  }

  Future<void> _openFilter(List<Todo> all) => showTodoFilterSheet(
    context,
    initial: _filter,
    allTags: _tagChoices(all),
    onApply: (f) => setState(() => _filter = f),
  );

  /// 흰 화면 — 상단 바 아래가 끝까지 흰 면 하나다(1A). 띠 · 테두리 카드 · 그림자 카드를 두지 않는다.
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(todoListProvider(_allFilter));
    // 다시 받는 동안에도 이전 목록을 그대로 둔다 — 완료 누름 뒤 스켈레톤으로 돌아가지 않는다.
    final all = listAsync.hasValue ? listAsync.requireValue : null;
    final failed = all == null && listAsync.hasError;
    return Scaffold(
      backgroundColor: c.bgLayerDefault,
      // 머리 = ds 상단 바(← + "할 일") — 높이 56, 스크롤해도 선이 없다
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.todoTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Stack(
        key: const ValueKey('todo-white-screen'),
        children: [
          PSwipeActionsProvider(
            child: _layout(
              all: all == null ? null : [for (final x in all) _effective(x)],
              failed: failed,
            ),
          ),
          // 떠 있는 [+] — 추가 시트를 연다(빠른 입력칸은 두지 않는다, 09-08).
          PFloatingActionButton(
            icon: LucideIcons.plus500,
            label: l.todoAdd,
            onPressed: () => showTodoEditDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _layout({required List<Todo>? all, required bool failed}) {
    final l = AppLocalizations.of(context);
    final loading = all == null && !failed;
    final constToday = ref.watch(constellationTodayProvider).value;
    final sky = ref.watch(constellationSkyProvider).value ?? const <SkyDay>[];
    // 하늘 카드 상세의 "수집" 줄 — 밤하늘을 펼쳤을 때만 도감을 받는다.
    final collection = _skyOpen
        ? ref.watch(constellationCollectionProvider).value
        : null;
    final skyByDate = {for (final d in sky) d.date: d};

    final today = DateTime.now();
    final todayYmd = todoYmd(today);
    final ym =
        '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';

    // 이 달 할 일(마감일 기준) + 마감일 없는 할 일(맨 아래 별도 묶음 — 유실 방지). 묶음 안은 남은 일 위 · 끝낸 일 아래.
    final byDay = all == null
        ? const <String, List<Todo>>{}
        : groupByDay(
            monthTodos(all, ym, _filter, held: _hold.ids),
            held: _hold.ids,
          );
    final groupKeys = byDay.keys.toList();
    _dayKeys.removeWhere((k, _) => !byDay.containsKey(k));
    for (final k in groupKeys) {
      _dayKeys.putIfAbsent(k, () => GlobalKey());
    }
    final left = all == null ? 0 : todayLeft(all, todayYmd);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: PSpacing.x2),
        LedgerMonthNav(
          label: yearMonth(_month),
          onPick: _pickMonth,
          onOpenFilter: () => _openFilter(all ?? const []),
          filterOn: _filter.active,
        ),
        // 오늘 할 일 + 별빛 한 줄 + [밤하늘]. [밤하늘] 과 월 달력은 하나만 펼친다.
        LedgerTotalRow(
          loading: loading,
          failed: failed,
          total: loading
              ? null
              : (left > 0 ? l.tdmTodayLeft(left) : l.tdmTodayDone),
          insight: loading || failed || constToday == null
              ? null
              : _StarlightHint(today: constToday),
          summaryOpen: _skyOpen,
          buttonLabel: l.tdmNightSkyBtn,
          buttonIcon: LucideIcons.sparkles,
          onToggleSummary: () => setState(() {
            _skyOpen = !_skyOpen;
            if (_skyOpen) _expanded = false;
          }),
        ),
        // 밤하늘 패널 — 히어로 + 관측 리포트/도감 진입 (들어가는 길만 — 안은 밤하늘 배치).
        if (_skyOpen && constToday != null && all != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x3_5,
              PSpacing.globalGutter,
              0,
            ),
            child: Column(
              children: [
                NightSkyHero(
                  today: constToday,
                  // completedAt 은 서버 `[UTC]` — 자르면 UTC 날짜가 나와 로컬 '오늘'(todayYmd)과 어긋난다.
                  doneToday: all
                      .where(
                        (x) =>
                            x.done && localDateKey(x.completedAt) == todayYmd,
                      )
                      .length,
                  onOpen: () => showTodayConstellationDetail(
                    context,
                    constToday,
                    entry: _collectionEntryOf(collection, constToday),
                  ),
                ),
                const SizedBox(height: PSpacing.x2),
                _SkyLinks(
                  reportLabel: l.forestReportTitle,
                  skyLabel: l.nightSkyTitle,
                  onReport: () => context.push('/forest-report'),
                  onSky: () => context.push('/night-sky'),
                ),
              ],
            ),
          ),
        // 접이식 캘린더 — 칸 아래 표시: 수집 ★ / 남은 수 / 키운 별자리 ★ / 놓친 날 구름 / 다 끝냄 ✓.
        LedgerCalendarGrid(
          month: _month,
          selected: _selected,
          expanded: _expanded,
          cellLabel: (context, ds) =>
              _cellLabel(context, ds, todayYmd, byDay, skyByDate, constToday),
          markBuilder: (context, ds) => _CellMark(
            mark: all == null
                ? null
                : todoCellMarkOf(
                    ds,
                    todayYmd,
                    byDay,
                    skyByDate,
                    constToday: constToday,
                  ),
            loading: loading,
          ),
          onSelect: (ds) {
            setState(() => _selected = ds);
            if (byDay.containsKey(ds)) _scrollToDay(ds, groupKeys);
          },
          onToggleExpand: () => setState(() {
            _expanded = !_expanded;
            if (_expanded) _skyOpen = false;
          }),
        ),
        const LedgerHeaderDivider(),
      ],
    );

    Widget buildList(
      BuildContext ctx,
      ScrollController controller,
      double headerHeight,
    ) {
      _headerH = headerHeight;
      final children = <Widget>[];
      if (failed) {
        // 질의 하나 = 실패 상자 하나 — 원문을 그리지 않는다.
        children.add(
          PResultSection(
            kind: PResultKind.failure,
            title: l.todoLoadError,
            description: l.tdmLoadFailedDesc,
            primaryAction: PResultAction(
              label: l.actionRetry,
              onPressed: () => ref.invalidate(todoListProvider(_allFilter)),
            ),
          ),
        );
      } else if (loading) {
        children.addAll(const [
          TodoDaySkeleton(rows: 3, first: true),
          TodoDaySkeleton(rows: 2),
        ]);
      } else if (groupKeys.isEmpty) {
        // 걸러서 0건 ↔ 이 달 0건 — 갈래가 다르다. 버튼은 두지 않는다(추가는 [+] 가 맡는다).
        children.add(
          _filter.active
              ? PResultSection(
                  title: l.tdmEmptyFilter,
                  description: l.tdmEmptyFilterDesc,
                  icon: LucideIcons.funnelX,
                )
              : PResultSection(
                  title: l.tdmEmptyMonth(monthOnly(_month)),
                  description: l.tdmEmptyMonthDesc,
                  icon: LucideIcons.listChecks,
                ),
        );
      } else {
        for (var i = 0; i < groupKeys.length; i++) {
          final key = groupKeys[i];
          children.add(
            KeyedSubtree(
              key: _dayKeys[key],
              child: TodoDayGroup(
                ymd: key == kTodoNoDueKey ? null : key,
                items: byDay[key]!,
                today: today,
                first: i == 0,
                onToggle: _toggleDone,
                onOpen: (x) => showTodoDetailDialog(context, x),
              ),
            ),
          );
        }
      }
      return PPullToRefresh(
        onRefresh: () async {
          ref.invalidate(todoListProvider(_allFilter));
          invalidateConstellation(ref);
          await ref.read(todoListProvider(_allFilter).future);
        },
        child: ListView(
          key: _listKey,
          controller: controller,
          // 위 — 숨는 머리 높이 / 아래 — 떠 있는 [+] 가 마지막 줄을 가리지 않게 96(흰 면 안이다).
          padding: EdgeInsets.fromLTRB(0, headerHeight, 0, 96),
          children: children,
        ),
      );
    }

    return PScrollAutoHide(
      controller: _scrollCtrl,
      header: header,
      builder: buildList,
    );
  }

  /// 칸의 읽는 이름 — "10월 22일, 남은 할 일 3개" · "10월 19일, 별자리 수집" · "10월 20일, 놓친 날" · "10월 18일, 다 끝냄".
  /// 표시가 없는 칸은 이름을 달지 않는다(날 숫자 글이 그대로 읽힌다).
  String? _cellLabel(
    BuildContext context,
    String ds,
    String todayYmd,
    Map<String, List<Todo>> byDay,
    Map<String, SkyDay> skyByDate,
    ConstellationToday? constToday,
  ) {
    final mark = todoCellMarkOf(
      ds,
      todayYmd,
      byDay,
      skyByDate,
      constToday: constToday,
    );
    if (mark == null) return null;
    final l = AppLocalizations.of(context);
    final date = monthDay(DateTime.parse(ds));
    return switch (mark) {
      TodoCellLeft(:final count) => l.tdmCellLeft(date, count),
      TodoCellCollected() || TodoCellGrown() => l.tdmCellCollected(date),
      TodoCellMissed() => l.tdmCellMissed(date),
      TodoCellDone() => l.tdmCellDone(date),
    };
  }
}

/// 별빛 인사이트 한 줄 — "별빛 l/g · N개 더 모으면 {별자리} 수집" / 수집 완료. t4 400 `fg-neutral-muted`, 낱말 단위 줄바꿈.
class _StarlightHint extends StatelessWidget {
  const _StarlightHint({required this.today});
  final ConstellationToday today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final name = constellationName(today.constellation);
    final lit = today.points > today.goal ? today.goal : today.points;
    final text = today.collected
        ? l.tdmCollectedHint(name, today.streak)
        : l.tdmStarlightHint(lit, today.goal, today.goal - lit, name);
    return Text(
      keepAll(text),
      semanticsLabel: text,
      style: PTypography.t4.copyWith(
        color: c.fgNeutralMuted,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

/// 달력 칸 아래 표시 — 높이 15(t1 11 / 15). 장식이다(뜻은 칸 이름이 읽는다).
/// 오늘의 남은 수는 `fg-brand` 700, 그 밖 남은 수는 `fg-neutral-subtle` 400, ★ 는 별자리 색, 구름은 `fg-neutral-subtle`, ✓ 는 `fg-positive`.
class _CellMark extends StatelessWidget {
  const _CellMark({required this.mark, required this.loading});
  final TodoCellMark? mark;
  final bool loading;

  static const double height = 15;
  static const double iconSize = 10;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final Widget? child = switch (mark) {
      _ when loading => null,
      TodoCellCollected(:final colorKey) ||
      TodoCellGrown(:final colorKey) => PFilledStar(
        size: iconSize,
        color: constellationColor(context, colorKey),
      ),
      TodoCellMissed() => Icon(
        LucideIcons.cloudy,
        size: iconSize,
        color: c.fgNeutralSubtle,
      ),
      TodoCellLeft(:final count, :final today) => Text(
        l.frpTileDoneVal(count),
        maxLines: 1,
        softWrap: false,
        style: PTypography.t1.copyWith(
          color: today ? c.fgBrand : c.fgNeutralSubtle,
          fontWeight: today ? FontWeight.w700 : FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      TodoCellDone() => Icon(
        LucideIcons.check,
        size: iconSize,
        color: c.fgPositive,
      ),
      null => null,
    };
    return ExcludeSemantics(
      // 높이 15 는 100% 의 값 — 글자가 커지면 칸이 글을 따라 늘고 잘리지 않는다(I-10 9)
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: height),
        child: Center(child: child),
      ),
    );
  }
}

/// [밤하늘] 안의 두 진입 단추 — 한 줄에 반씩, 글자가 커져 한 칸에 안 들어가면 세로로 쌓는다(웹 `flex-wrap`).
class _SkyLinks extends StatelessWidget {
  const _SkyLinks({
    required this.reportLabel,
    required this.skyLabel,
    required this.onReport,
    required this.onSky,
  });

  final String reportLabel;
  final String skyLabel;
  final VoidCallback onReport;
  final VoidCallback onSky;

  @override
  Widget build(BuildContext context) {
    final report = PButton(
      label: reportLabel,
      prefixIcon: LucideIcons.telescope,
      variant: PButtonVariant.neutralOutline,
      size: PButtonSize.small,
      onPressed: onReport,
    );
    final sky = PButton(
      label: skyLabel,
      prefixIcon: LucideIcons.sparkles,
      variant: PButtonVariant.neutralOutline,
      size: PButtonSize.small,
      onPressed: onSky,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final half = (box.maxWidth - PSpacing.x2) / 2;
        final fits =
            report.naturalWidth(context) <= half &&
            sky.naturalWidth(context) <= half;
        if (fits) {
          return Row(
            spacing: PSpacing.x2,
            children: [
              Expanded(child: report),
              Expanded(child: sky),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PSpacing.x2,
          children: [report, sky],
        );
      },
    );
  }
}

/// 오늘의 목표 별자리의 도감 줄 — 도감을 아직 못 받았으면 null(상세에서 수집 줄을 뺀다).
CollectionEntry? _collectionEntryOf(
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
