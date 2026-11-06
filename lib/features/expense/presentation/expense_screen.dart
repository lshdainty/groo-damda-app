import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/domain/expense_filter.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/filter_dialog.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_day_group.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_filter_chips.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/month_picker/p_month_picker.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/scroll/scroll_to_keyed.dart';

/// 가계부 화면 — 백엔드 `/expenses` 직접 호출.
class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({
    this.initialMonth,
    this.focusTxId,
    this.initialAssetId,
    super.key,
  });

  /// "YYYY-MM" — 홈 최근 거래 → 해당 월로 자동 이동.
  final String? initialMonth;

  /// 진입 후 자동 스크롤할 거래 rowId.
  final int? focusTxId;

  /// 자산 상세 → 전체 보기 클릭 시 진입. 해당 자산만 필터링.
  final int? initialAssetId;

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  late DateTime _month = _resolveInitialMonth();
  ExpenseFilter _advFilter = const ExpenseFilter();
  int? _assetIdFilter;
  final Map<int, GlobalKey> _rowKeys = {};
  bool _scrolledToFocus = false;

  // txm 통합 뷰 상태 — 접이식 캘린더/소비 요약/선택일.
  bool _expanded = false;
  bool _sumOpen = false;
  String? _selected;
  final Map<String, GlobalKey> _dayKeys = {};
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _listKey = GlobalKey();

  /// 머리(고정 줄 + 숨는 영역)의 높이 — 목록 맨 위 여백. 고정 줄이 없을 때(필터) 스크롤 스파이의 기준선.
  double _headerH = 0;

  /// 남는 머리(주 달력 · 펼침 꺾쇠 · 구분선) — 그 아래 끝이 스크롤 스파이의 기준선이다(숨는 영역이 숨으면 함께 올라간다).
  final GlobalKey _pinKey = GlobalKey();

  /// 날짜 · 거래로 갈 때 남는 머리 바로 아래에 맞추려고 잡는다(화면 맨 위에 맞추면 주 달력 뒤로 들어간다).
  final GlobalKey<PScrollAutoHideState> _autoHideKey =
      GlobalKey<PScrollAutoHideState>();

  double? _underPin(BuildContext ctx, {double gap = 0}) =>
      _autoHideKey.currentState?.scrollTargetFor(ctx, gap: gap);
  bool _lock = false; // 프로그램 스크롤 중 스파이 무시
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _assetIdFilter = widget.initialAssetId;
    final today = DateTime.now();
    if (today.year == _month.year && today.month == _month.month) {
      _selected = ledgerYmd(today);
    }
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _lockFor(int ms) {
    _lock = true;
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(milliseconds: ms), () => _lock = false);
  }

  bool _spyQueued = false;

  /// 스크롤 · 머리 옮김(스냅)마다 다음 프레임에 스파이를 한 번 돌린다 — 그 프레임의 배치로 재야 한 칸씩 밀리지 않는다(스크롤
  /// 알림은 배치 전에 온다). 스냅은 목록을 스크롤하지 않고 남는 머리 아래 선만 옮기므로 그것도 듣는다.
  void _onScroll() {
    if (_spyQueued) return;
    _spyQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _spyQueued = false;
      if (mounted) _spy();
    });
  }

  /// 스크롤 스파이 — 맨 위 날짜 그룹을 선택일로 동기. 머리 숨기기는 Scroll Auto Hide 가 맡는다.
  void _spy() {
    if (!_scrollCtrl.hasClients || _lock) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    final listTop = listBox.localToGlobal(Offset.zero).dy;
    final line = pinnedHeaderBottom(_pinKey, listTop) ?? _headerH;
    // 보이는 머리 아래(+28) 를 지난 그룹 중 화면상 가장 아래 그룹 = 현재 보는 날짜.
    double best = double.negativeInfinity;
    String? cur;
    for (final e in _dayKeys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy - listTop;
      if (top <= line + 28 && top > best) {
        best = top;
        cur = e.key;
      }
    }
    if (cur != null && cur != _selected) {
      setState(() => _selected = cur);
    }
  }

  DateTime _resolveInitialMonth() {
    final raw = widget.initialMonth;
    if (raw != null && RegExp(r'^\d{4}-\d{2}$').hasMatch(raw)) {
      final parts = raw.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    }
    return monthStart(DateTime.now());
  }

  @override
  void didUpdateWidget(covariant ExpenseScreen old) {
    super.didUpdateWidget(old);
    if (old.initialMonth != widget.initialMonth) {
      setState(() => _month = _resolveInitialMonth());
    }
    if (old.focusTxId != widget.focusTxId) {
      _scrolledToFocus = false;
    }
    if (old.initialAssetId != widget.initialAssetId) {
      setState(() => _assetIdFilter = widget.initialAssetId);
    }
  }

  void _clearAssetFilter() {
    setState(() => _assetIdFilter = null);
    final m = _month;
    final monthQ = '${m.year}-${m.month.toString().padLeft(2, '0')}';
    context.go('/expense?month=$monthQ');
  }

  MonthKey get _key => (year: _month.year, month: _month.month);
  MonthKey get _prevKey {
    final p = DateTime(_month.year, _month.month - 1, 1);
    return (year: p.year, month: p.month);
  }

  Future<void> _openFilter() async {
    final result = await showFilterDialog(
      context,
      _advFilter,
      defaultPeriod: monthPeriodOf(_month),
    );
    if (result != null && mounted) setState(() => _advFilter = result);
  }

  /// 월 라벨 — ko "7월" / en "Jul" (monthnav·prevbtn·empty 공용, web txmMonthLabel 정합).
  static String _monthLabel(DateTime m) => localeIsEn()
      ? const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][m.month - 1]
      : '${m.month}월';

  Future<void> _pickMonth() async {
    final picked = await showPMonthPicker(context, initial: _month);
    if (picked != null && mounted) _setMonth(picked);
  }

  void _goMonth(int dir) =>
      _setMonth(DateTime(_month.year, _month.month + dir, 1));

  void _setMonth(DateTime next) {
    final today = DateTime.now();
    setState(() {
      _month = next;
      _expanded = false;
      _selected = (today.year == next.year && today.month == next.month)
          ? ledgerYmd(today)
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

  /// [order] 는 리스트에 **그려진 순서 그대로**의 날짜 그룹 목록이다. 필드로 들고
  /// 있지 않고 받는 이유 — 그리는 쪽과 어긋날 여지를 아예 없앤다. 필드로 두면 누가
  /// 대입 한 줄을 지우는 순간 순번이 -1 이 되어 **아무 일도 안 하는 상태로 조용히**
  /// 돌아간다(이 버그가 정확히 그렇게 조용했다).
  void _scrollToDay(String ds, List<String> order) {
    // 먼 날짜는 아직 안 만들어져 있어 `ensureVisible` 만으로는 못 간다 —
    // 그래서 순번을 함께 넘긴다(`scroll_to_keyed.dart` 설명 참고).
    // 여러 프레임에 걸쳐 뛰므로 스크롤 스파이를 그동안 재운다.
    _lockFor(1200);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      scrollToKeyedItem(
        controller: _scrollCtrl,
        key: _dayKeys[ds],
        index: order.indexOf(ds),
        count: order.length,
        targetOf: _underPin,
      );
    });
  }

  /// 흰 화면 — 가계부 거래 목록만 바닥(basement) 없이 흰 면 하나다(02-005 / Q-019-3).
  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('expense-white-screen'),
    color: context.colors.bgLayerDefault,
    child: PSwipeActionsProvider(child: _buildBody(context)),
  );

  /// 보고 있는 달의 이체 조회 키 — 조회와 [다시 시도] 가 같은 키를 본다.
  AssetTransfersKey get _transfersKey => (
    startDate: ledgerYmd(DateTime(_month.year, _month.month, 1)),
    endDate: ledgerYmd(DateTime(_month.year, _month.month + 1, 0)),
  );

  Widget _buildBody(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(monthExpensesProvider(_key));
    // 이체는 asset_transfer 별도 테이블이라 거래 목록에 섞여 오지 않는다.
    // 같은 달 범위로 따로 받아 화면 단에서만 합친다(통계·예산 같은 지출 전용 경로 보호).
    final transfersAsync = ref.watch(assetTransfersProvider(_transfersKey));
    // 인사이트(지난달 대비) — 지난달 거래도 함께 구독(family 캐시).
    final prevAsync = ref.watch(monthExpensesProvider(_prevKey));

    // 불러오는 중 · 실패에도 같은 틀(머리 + 목록 자리)을 그린다 — 달 이름은 바로 바뀌고 숫자 · 목록 자리만 기다린다.
    return expensesAsync.when(
      // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
      skipError: true,
      loading: () => _layout(
        categoriesAsync: categoriesAsync,
        transfersAsync: transfersAsync,
        prevAsync: prevAsync,
      ),
      error: (e, _) => _layout(
        categoriesAsync: categoriesAsync,
        transfersAsync: transfersAsync,
        prevAsync: prevAsync,
        failed: true,
        retrying: expensesAsync.isLoading,
      ),
      data: (raw) => _layout(
        categoriesAsync: categoriesAsync,
        transfersAsync: transfersAsync,
        prevAsync: prevAsync,
        raw: raw,
      ),
    );
  }

  Widget _layout({
    required AsyncValue<List<ExpenseCategory>> categoriesAsync,
    required AsyncValue<List<AssetTransfer>> transfersAsync,
    required AsyncValue<List<Expense>> prevAsync,
    List<Expense>? raw,
    bool failed = false,
    bool retrying = false,
  }) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final loading = raw == null && !failed;

    // 배지 대신 칩 줄이 말하는 "필터가 걸린 상태" — 켜진 **포함 조건 수**(웹 filterActiveCount 정합).
    // 기간은 항상 걸려 있고 '빼고' 는 포함 조건이 아니라 세지 않지만, 사람 눈에는 그 둘도 "필터가 걸린 상태" 라 조건이 0
    // 이어도 1 로 쳐서 칩 줄을 띄운다. 기간이 한 칸이어도 보고 있는 달과 다르면 마찬가지다(QA 30 10).
    final baseCount = activeConditionCount(_advFilter);
    final hasExclude =
        _advFilter.categories.exclude.isNotEmpty ||
        _advFilter.assets.exclude.isNotEmpty;
    final periodChanged =
        _advFilter.periods.length == 1 &&
        !samePeriod(_advFilter.periods.first, monthPeriodOf(_month));
    final advCount = baseCount > 0
        ? baseCount
        : (_advFilter.periods.length > 1 || hasExclude || periodChanged
              ? 1
              : 0);
    // 필터 활성 시 — 월선택/총액/캘린더/divider 숨기고 온전히 리스트만(사용자 결정).
    final filterActive = advCount > 0 || _assetIdFilter != null;

    // ── 데이터 ──
    var filtered = const <Expense>[];
    var monthIncome = 0;
    var monthExpense = 0;
    final byDay = <String, ({int out, int inn})>{};
    final groups = <String, List<Expense>>{};
    final transferGroups = <String, List<AssetTransfer>>{};
    var groupKeys = <String>[];
    if (raw != null) {
      final cats = categoriesAsync.value;
      // 부모 카테고리를 고르면 자식 rowId 까지 함께 본다 — **빼고(exclude)에도 같이**
      // 건다. 한쪽만 펼치면 "식비 빼고" 가 하위 '카페' 를 못 걸러 낸다.
      Set<int> expand(Set<int> ids) => ids.isEmpty
          ? ids
          : {
              ...ids,
              if (cats != null)
                for (final c in cats)
                  if (c.parentRowId != null && ids.contains(c.parentRowId))
                    c.rowId,
            };
      final effective = _advFilter.copyWith(
        categories: IncludeExclude(
          include: expand(_advFilter.categories.include),
          exclude: expand(_advFilter.categories.exclude),
        ),
      );

      filtered =
          raw
              .where(
                (e) => matchesFilter(
                  FilterRow(
                    date: e.expenseDateOnly ?? '',
                    amount: e.amount,
                    type: e.expenseType,
                    // 분할 항목 카테고리까지 넣는다 — 포함은 "하나라도",
                    // 제외는 "하나라도 걸리면".
                    categoryIds: [
                      if (e.categoryRowId != null) e.categoryRowId!,
                      ...e.splitCategoryRowIds,
                    ],
                    assetIds: [if (e.assetRowId != null) e.assetRowId!],
                  ),
                  effective,
                ),
              )
              // 자산 상세 "전체 보기" 로 들어온 자산 — 목록을 그 자산 거래로 거른다(옛 앱은 칩만 달고 거르지 않았다).
              .where(
                (e) => _assetIdFilter == null || e.assetRowId == _assetIdFilter,
              )
              .toList()
            ..sort(
              (a, b) => (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''),
            );

      // 환불은 지출 상계, 아직 안 온 건 제외 — 서버 월 요약과 같은 규칙.
      // 필터가 걸려 있으면 **걸러진 목록으로** 다시 센다(조합 15, 사용자 결정).
      final filterOn = !_advFilter.isEmpty || _assetIdFilter != null;
      monthIncome = incomeSum(filterOn ? filtered : raw);
      monthExpense = expenseSum(filterOn ? filtered : raw);

      // 일별 합계 — 캘린더 셀 밑 금액 (필터 적용분 기준).
      for (final e in countableTx(filtered)) {
        final d = e.expenseDateOnly ?? '';
        final cur = byDay[d] ?? (out: 0, inn: 0);
        // 환불된 거래는 `countableTx` 가 이미 뺐다 — 여기서 또 가르지 않는다.
        byDay[d] = e.expenseType == 'EXPENSE'
            ? (out: cur.out + e.amount.abs(), inn: cur.inn)
            : (out: cur.out, inn: cur.inn + e.amount.abs());
      }

      for (final e in filtered) {
        final d = e.expenseDateOnly ?? '';
        groups.putIfAbsent(d, () => []).add(e);
      }

      // 이체도 **같은 술어**로 본다. v1 은 카테고리가 걸리면 통째로 뺐는데,
      // v2 는 이체를 type=null·categoryIds=[] 로 눕혀 규칙이 알아서 판정한다 —
      // '모두 일치' 면 카테고리 조건에서 빠지고, '하나라도' 면 계좌·금액으로 남는다.
      for (final tr in (transfersAsync.value ?? const <AssetTransfer>[])) {
        final rawDate = tr.transferDate ?? '';
        if (rawDate.length < 10) continue;
        final d = rawDate.substring(0, 10);
        final ok = matchesFilter(
          FilterRow(
            date: d,
            amount: tr.amount,
            type: null,
            assetIds: [tr.fromAssetRowId, tr.toAssetRowId],
          ),
          effective,
        );
        if (!ok) continue;
        if (_assetIdFilter != null &&
            tr.fromAssetRowId != _assetIdFilter &&
            tr.toAssetRowId != _assetIdFilter) {
          continue;
        }
        transferGroups.putIfAbsent(d, () => []).add(tr);
      }

      // 이체만 있는 날도 그룹이 나와야 한다.
      groupKeys = <String>{...groups.keys, ...transferGroups.keys}.toList()
        ..sort((a, b) => b.compareTo(a));
      _dayKeys.removeWhere(
        (k, _) => !groups.containsKey(k) && !transferGroups.containsKey(k),
      );
      for (final k in groupKeys) {
        _dayKeys.putIfAbsent(k, () => GlobalKey());
      }
    }

    final summaryFlags = ref.watch(maskFlagsProvider('ledger.monthSummary'));

    // ── 머리 — 달 이동 줄 · 주 달력 · 펼침 꺾쇠는 남고(페이지 전체를 조절하는 줄이라 한 덩어리), 총액 · 지난달 비교 ·
    // [소비 요약](펼친 요약 포함)만 Scroll Auto Hide 로 숨는다. 필터를 걸면 칩 줄이 숨는 자리에 온다(달력은 없다) ──
    final pinnedTop = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: PSpacing.x2),
        LedgerMonthNav(
          label: yearMonth(_month),
          showMonth: !filterActive,
          onPick: _pickMonth,
          onOpenFilter: _openFilter,
          onAddTx: () => showAddTxSheet(context),
        ),
      ],
    );
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 총액 + 인사이트 + [소비 요약]. 필터 활성 시 숨김.
        if (!filterActive) ...[
          LedgerTotalRow(
            loading: loading,
            failed: failed,
            total: loading
                ? null
                : krwSigned(
                    monthExpense,
                    summaryFlags.of(MaskKind.expense),
                    unit: true,
                  ),
            insight: loading || failed
                ? null
                : _insight(
                    l,
                    c,
                    raw!,
                    monthExpense,
                    prevAsync.value,
                    categoriesAsync.value,
                    // 인사이트는 지난달과의 차액을 말한다 — 크기가 드러나 월 합계 카드와 함께 가린다.
                    masked: summaryFlags.of(MaskKind.expense),
                  ),
            summaryOpen: _sumOpen,
            // 월 전체 캘린더와 동시 열면 고정 머리가 화면을 초과(overflow) — 서로 접는다.
            onToggleSummary: () => setState(() {
              _sumOpen = !_sumOpen;
              if (_sumOpen) _expanded = false;
            }),
          ),
          if (_sumOpen && raw != null)
            LedgerSummaryList(
              income: monthIncome,
              expense: monthExpense,
              flags: summaryFlags,
            ),
        ],
      ],
    );
    // 남는 아래 줄 — 주 달력(펼친 월 달력) · 꺾쇠 · 선, 필터 중이면 칩 줄. 칩 줄은 무엇이 걸러져 보이는지 말하는 페이지 전체
    // 조절 줄이라 숨기지 않는다(숨기면 거른 채라는 걸 잊고 "거래가 이것뿐" 으로 읽는다). 캘린더는 필터 중 숨김(사용자 결정 · 웹 정합).
    final pinnedBottom = filterActive
        ? KeyedSubtree(
            key: _pinKey,
            child: LedgerFilterChips(
              filter: _advFilter,
              assetId: _assetIdFilter,
              onClearAsset: _clearAssetFilter,
              onChange: (f) => setState(() => _advFilter = f),
              categories: categoriesAsync.value ?? const [],
            ),
          )
        : Column(
            key: _pinKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LedgerCalendar(
                month: _month,
                selected: _selected,
                expanded: _expanded,
                byDay: byDay,
                loading: loading,
                flags: _calendarFlags(ref),
                onSelect: (ds) {
                  setState(() => _selected = ds);
                  if (byDay.containsKey(ds)) _scrollToDay(ds, groupKeys);
                },
                onToggleExpand: () => setState(() {
                  _expanded = !_expanded;
                  if (_expanded) _sumOpen = false;
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
      final listChildren = <Widget>[];
      // 이체만 못 받았을 때(받아 둔 이체가 없는 채 실패) — 이체 줄이 조용히 빠진 목록을 "이체 없음" 으로 읽지 않게 맨 위에서 말한다.
      // 거래 목록은 그대로 두고, 다시 시도는 이체 조회만 비운다.
      if (!failed && transfersAsync.hasError && !transfersAsync.hasValue) {
        listChildren.add(
          Padding(
            key: const ValueKey('expense-transfers-error'),
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x4,
              PSpacing.globalGutter,
              0,
            ),
            child: PCallout(
              tone: PCalloutTone.critical,
              description: l.expTransfersLoadError,
              alert: true,
              actions: [
                PButton(
                  label: l.actionRetry,
                  variant: PButtonVariant.neutralOutline,
                  size: PButtonSize.small,
                  onPressed: () =>
                      ref.invalidate(assetTransfersProvider(_transfersKey)),
                ),
              ],
            ),
          ),
        );
      }
      if (failed) {
        listChildren.add(
          PResultSection(
            kind: PResultKind.failure,
            title: l.expLoadError,
            description: l.expLoadErrorDesc,
            primaryAction: PResultAction(
              label: l.actionRetry,
              loading: retrying,
              onPressed: () => ref.invalidate(monthExpensesProvider(_key)),
            ),
          ),
        );
      } else if (loading) {
        listChildren.addAll(const [
          LedgerDaySkeleton(rows: 3, first: true),
          LedgerDaySkeleton(rows: 2),
        ]);
      } else if (groupKeys.isEmpty) {
        // 걸러서 0건(필터 · 자산이 걸림) ↔ 이 달 0건 — 갈래가 다르다. 버튼은 두지 않는다(추가는 탭 바 + 가 맡는다).
        listChildren.add(
          filterActive
              ? PResultSection(
                  title: l.expFilteredEmpty,
                  description: l.expFilteredEmptyDesc,
                  icon: LucideIcons.funnelX,
                )
              : PResultSection(
                  title: l.txmEmptyMonth(_monthLabel(_month)),
                  description: l.txmEmptyMonthDesc,
                  icon: LucideIcons.receiptText,
                ),
        );
      } else {
        for (var i = 0; i < groupKeys.length; i++) {
          final key = groupKeys[i];
          listChildren.add(
            KeyedSubtree(
              key: _dayKeys[key],
              child: LedgerDayGroup(
                date: parseIsoDate(key),
                items: groups[key] ?? const [],
                transfers: transferGroups[key] ?? const [],
                categoriesAsync: categoriesAsync,
                flags: ref.watch(maskFlagsProvider('ledger.txList')),
                rowKeys: _rowKeys,
                focusTxId: widget.focusTxId,
                first: i == 0,
              ),
            ),
          );
        }
      }
      // 지난달 이용 내역 보기 — 이 달이 비어 있어도 둔다(지난달로 가는 길). 필터 활성 시 숨김(사용자 결정). 줄을 덧붙이지 않고 달을 옮긴다.
      if (!failed && !filterActive) {
        listChildren.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x6,
              PSpacing.globalGutter,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PButton(
                    label: l.txmPrevMonthBtn(
                      _monthLabel(DateTime(_month.year, _month.month - 1, 1)),
                    ),
                    size: PButtonSize.large,
                    variant: PButtonVariant.neutralWeak,
                    onPressed: () => _goMonth(-1),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return PPullToRefresh(
        onRefresh: () async {
          ref.invalidate(monthExpensesProvider(_key));
          await ref.read(monthExpensesProvider(_key).future);
        },
        child: ListView(
          key: _listKey,
          controller: controller,
          // 위 — 숨는 머리 높이 / 아래 — 플로팅 탭바 보상.
          padding: EdgeInsets.fromLTRB(
            0,
            headerHeight,
            0,
            bottomNavigationInset(ctx),
          ),
          children: listChildren,
        ),
      );
    }

    if (raw != null && widget.focusTxId != null && !_scrolledToFocus) {
      // 알림·검색에서 들어온 거래는 목록 한참 아래일 수 있다 — 그 행은 아직
      // 안 만들어져 있어 바로 `ensureVisible` 하면 조용히 아무 일도 안 했다.
      // 먼저 **그 거래가 속한 날짜 그룹**으로 간 다음(그러면 행이 만들어진다)
      // 행이 만들어지는 것을 기다려 정확히 맞춘다.
      String? focusDay;
      for (final e in filtered) {
        if (e.rowId == widget.focusTxId) {
          focusDay = e.expenseDateOnly;
          break;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrolledToFocus = true;
        if (focusDay != null && focusDay.isNotEmpty) {
          _lockFor(1200);
          scrollToKeyedItem(
            controller: _scrollCtrl,
            key: _dayKeys[focusDay],
            index: groupKeys.indexOf(focusDay),
            count: groupKeys.length,
            alignment: 0.02,
            targetOf: _underPin,
          );
        }
        // 그룹 이동은 여러 프레임에 걸쳐 끝난다 — 한 프레임 뒤에 한 번만 보면
        // 두 홉 이상 걸린 경우 행이 아직 없어 조용히 건너뛴다(QA 22차 추정).
        // 거래 줄은 날짜 머리가 보이게 남는 머리 아래 40 에 둔다
        ensureVisibleWhenReady(
          key: _rowKeys[widget.focusTxId!],
          targetOf: (ctx) => _underPin(ctx, gap: PSpacing.x10),
        );
      });
    }
    return PScrollAutoHide(
      key: _autoHideKey,
      controller: _scrollCtrl,
      onMoved: (_) => _onScroll(),
      pinnedTop: pinnedTop,
      header: header,
      pinnedBottom: pinnedBottom,
      builder: buildList,
    );
  }

  /// 인사이트 문장 — 낱말 단위로 줄을 바꾼다(큰 글자에서 글자 가운데가 끊기지 않게).
  static Widget _plainInsight(String text, TextStyle style) =>
      Text(keepAll(text), semanticsLabel: text, style: style);

  /// 달력 칸 · 칸 툴팁의 가림 — 캘린더 카드와 거래 목록 카드의 합집합(툴팁이 거래 금액을 말하므로 "캘린더 금액"만 가린 사람에게
  /// 툴팁 금액이 보이면 안 된다).
  MaskFlags _calendarFlags(WidgetRef ref) {
    final a = ref.watch(maskFlagsProvider('ledger.calendar'));
    final b = ref.watch(maskFlagsProvider('ledger.txList'));
    return MaskFlags(
      card: a.card || b.card,
      expense: a.expense || b.expense,
      income: a.income || b.income,
      transfer: a.transfer || b.transfer,
    );
  }

  /// 인사이트 한 줄 — 지난달 대비(덜/더/비슷) / 없으면 최다 지출 카테고리.
  Widget? _insight(
    AppLocalizations l,
    PColors c,
    List<Expense> raw,
    int monthExpense,
    List<Expense>? prevRaw,
    List<ExpenseCategory>? categories, {
    bool masked = false,
  }) {
    final subStyle = PTypography.t4.copyWith(
      color: c.fgNeutralMuted,
      fontWeight: FontWeight.w400,
    );
    if (raw.isEmpty) return _plainInsight(l.txmInsightNone, subStyle);
    // 이번 달 지출(monthExpense)과 비교하므로 같은 규칙으로 세야 한다.
    final prevOut = expenseSum(prevRaw ?? const <Expense>[]);
    if (prevOut > 0) {
      final diff = prevOut - monthExpense;
      // 5,000원 미만이면 "비슷해요" — 표기와 무관한 제품 문턱이라 그대로 둔다
      // (예전엔 만원 반올림 결과가 0 이냐로 갈랐다. 경계가 같은 5,000 이다).
      if (diff.abs() < 5000) return _plainInsight(l.txmInsightSame, subStyle);
      // 축약은 차트 축·도넛 중앙과 같은 함수 하나를 쓴다. 예전엔 여기서 만원으로
      // 반올림해 11,881 을 `1만원` 이라고 했다 — 문장이 실제보다 16% 적게 말했다
      // (QA #38). 이제 `1.2만원` 이다.
      final amount = localeIsEn()
          ? '₩${krw(diff.abs())}'
          : '${formatChartAxis(diff.abs().toDouble())}원';
      // 가림 점은 krw.dart 의 기본 마스크(6개)와 한 벌
      final shownAmount = masked ? kHideMask : amount;
      final less = diff > 0;
      return Text.rich(
        TextSpan(
          style: subStyle,
          children: [
            TextSpan(
              text: keepAll(less ? l.txmInsightLessPre : l.txmInsightMorePre),
            ),
            TextSpan(
              text: keepAll(
                less
                    ? l.txmInsightLessHl(shownAmount)
                    : l.txmInsightMoreHl(shownAmount),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: less ? c.fgBrand : c.fgCritical,
              ),
            ),
            TextSpan(
              text: keepAll(less ? l.txmInsightLessPost : l.txmInsightMorePost),
            ),
          ],
        ),
      );
    }
    // 최다 지출 카테고리 fallback.
    final byCat = <int?, int>{};
    // 환불된 거래는 `countableTx` 가 이미 뺐다 — 전액 환불한 카테고리는 저절로
    // 후보에서 빠진다.
    for (final e in countableTx(raw)) {
      if (e.expenseType == 'EXPENSE') {
        byCat[e.categoryRowId] = (byCat[e.categoryRowId] ?? 0) + e.amount.abs();
      }
    }
    if (byCat.isEmpty) return null;
    final topId =
        (byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
    final topName = topId == null
        ? null
        : categories?.byRowId(topId)?.categoryName;
    if (topName == null) return null;
    return Text.rich(
      TextSpan(
        style: subStyle,
        children: [
          TextSpan(text: keepAll(l.txmInsightTopCatPre)),
          TextSpan(
            text: keepAll(topName),
            style: TextStyle(fontWeight: FontWeight.w700, color: c.fgBrand),
          ),
          TextSpan(text: keepAll(l.txmInsightTopCatPost)),
        ],
      ),
    );
  }
}
