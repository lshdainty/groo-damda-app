import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/filter_bodies.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_day_group.dart';

/// 유형 거르기 — 전체 · 지출 · 수입(서버 expenseType, 전체는 보내지 않는다).
const String _typeAll = 'ALL';

/// 고급 필터 조건 — 금액 범위와 기간(웹 AdvancedFilter 와 같은 두 조건).
typedef _Advanced = ({int? min, int? max, DateTime? start, DateTime? end});

const _Advanced _noAdvanced = (min: null, max: null, start: null, end: null);

bool _hasAdvanced(_Advanced a) =>
    a.min != null || a.max != null || a.start != null || a.end != null;

/// 거래 검색 — 키워드 + 유형(전체 · 지출 · 수입) + 고급 필터(금액 범위 · 기간). 웹 `SearchPage` 와 같은 화면이다
/// (top-navigation.md "거래 검색 화면").
///
/// 상단 바는 standard — ← · 제목 자리의 검색칸(Text Field 상자형 medium 40 · 앞 돋보기 · 지우기, 보이지 않는 머리말 "검색") ·
/// 오른쪽 고급 필터 아이콘 버튼(걸리면 알림 점 + 이름 "고급 필터, 적용 중"). 칩 줄(전체 · 지출 · 수입 — Chip outlineStrong
/// medium 하나 고르기)은 스크롤 상자 맨 위의 Scroll Auto Hide 라 목록을 내리면 숨는다. 바탕은 흰 면 하나(DESIGN.desk.md
/// "흰 화면 — 거래 검색", 2026-10-23 5-A) — 결과는 가계부 원장과 같은 날짜 묶음(머리 + 거래 줄, 묶음 위 12 · 첫 묶음 4).
///
/// 실패는 그 자리 Result Section failure — 고정 글 + [다시 시도](다시 받는 동안 단추에 진행 원). 서버 글 · 예외 글은 화면에
/// 내지 않는다.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _type = _typeAll;
  _Advanced _advanced = _noAdvanced;
  Timer? _debounce;
  bool _loading = false;
  bool _failed = false;

  /// 실패 화면에서 [다시 시도] 를 눌러 다시 받는 중 — 실패 화면은 그대로, 단추만 진행 원.
  bool _retrying = false;

  /// 늦게 온 앞 요청의 답이 새 답을 덮지 않게 요청마다 올린다.
  int _seq = 0;
  List<Expense> _results = [];

  bool get _idle =>
      _ctrl.text.trim().isEmpty &&
      _type == _typeAll &&
      !_hasAdvanced(_advanced);

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // 비우면(✕ · 다 지움) 기다리지 않고 바로 처음으로 — 지운 검색어의 결과 · 진행 중 요청을 남기지 않는다(옛 화면 동작)
    if (value.trim().isEmpty) {
      _runSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openAdvanced() async {
    final next = await PBottomSheet.show<_Advanced>(
      context,
      form: true,
      builder: (_) => _AdvancedSheet(initial: _advanced),
    );
    if (next == null || !mounted) return;
    setState(() => _advanced = next);
    _runSearch();
  }

  Future<void> _runSearch({bool retry = false}) async {
    _debounce?.cancel();
    final seq = ++_seq;
    if (_idle) {
      setState(() {
        _results = [];
        _failed = false;
        _retrying = false;
        _loading = false;
      });
      return;
    }
    setState(() {
      if (retry && _failed) {
        _retrying = true;
      } else {
        _failed = false;
        _loading = true;
      }
    });
    final q = _ctrl.text.trim();
    final a = _advanced;
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final list = await repo.search(
        keyword: q.isEmpty ? null : q,
        expenseType: _type == _typeAll ? null : _type,
        minAmount: a.min,
        maxAmount: a.max,
        startDate: a.start == null ? null : _fmtDate(a.start!),
        endDate: a.end == null ? null : _fmtDate(a.end!),
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = list;
        _loading = false;
        _failed = false;
        _retrying = false;
      });
    } catch (_) {
      // 서버 글 · 예외 글은 화면에 내지 않는다 — 실패 화면의 고정 글이 말한다.
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        _failed = true;
        _retrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final active = _hasAdvanced(_advanced);

    return Scaffold(
      // 흰 화면(흰 면 하나) — DESIGN.desk.md 거래 검색(2026-10-23 5-A)
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation.search(
          title: l.searchHeading,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
          search: PInput(
            key: const ValueKey('search-field'),
            controller: _ctrl,
            size: PInputSize.medium,
            autofocus: true,
            placeholder: l.searchHint,
            semanticLabel: l.searchHint,
            prefixIcon: LucideIcons.search,
            clearable: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
          ),
          actions: [
            PTopNavigationIconButton(
              icon: LucideIcons.slidersHorizontal,
              // 걸린 것은 점만으로 알리지 않는다 — 이름에도 넣는다
              label: active ? l.searchAdvancedOn : l.searchAdvancedFilter,
              notification: active,
              onPressed: _openAdvanced,
            ),
          ],
        ),
      ),
      body: PScrollAutoHide(
        header: Padding(
          // 칩 줄 — 위아래 6(웹 py-x1_5). 좌우 24 는 칩 줄이 스스로 둔다
          padding: const EdgeInsets.symmetric(vertical: PSpacing.x1_5),
          child: PChipRadioGroup<String>(
            key: const ValueKey('search-type-chips'),
            layout: PChipGroupLayout.scroll,
            semanticLabel: l.searchTypeGroup,
            value: _type,
            onChanged: (v) {
              setState(() => _type = v);
              _runSearch();
            },
            children: [
              for (final (value, label) in [
                (_typeAll, l.expFilterAll),
                ('EXPENSE', l.expFilterExpense),
                ('INCOME', l.expFilterIncome),
              ])
                PChipRadio<String>(
                  value: value,
                  label: label,
                  variant: PChipVariant.outlineStrong,
                ),
            ],
          ),
        ),
        builder: (context, controller, headerHeight) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(padding: EdgeInsets.only(top: headerHeight)),
            ..._body(l),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 자리 하나를 채우는 결과(처음 · 결과 없음 · 실패) — 남는 높이의 가운데.
  Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  List<Widget> _body(AppLocalizations l) {
    if (_idle) {
      return [
        _fill(
          PResultSection(icon: LucideIcons.search300, title: l.searchEmptyHint),
        ),
      ];
    }
    if (_failed) {
      return [
        _fill(
          PResultSection(
            kind: PResultKind.failure,
            title: l.searchFailed,
            description: l.searchFailedDesc,
            primaryAction: PResultAction(
              label: l.actionRetry,
              loading: _retrying,
              onPressed: () => _runSearch(retry: true),
            ),
          ),
        ),
      ];
    }
    if (_loading) {
      return const [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LedgerDaySkeleton(rows: 3, first: true),
              LedgerDaySkeleton(rows: 2),
            ],
          ),
        ),
      ];
    }
    if (_results.isEmpty) {
      return [
        _fill(
          PResultSection(
            icon: LucideIcons.receiptText300,
            title: l.searchNoResults,
          ),
        ),
      ];
    }
    // 가계부 원장과 **같은 조각** — 날짜 머리는 PDayHeader, 줄은 ExpenseRow(앱에 거래 줄 위젯은 이것 하나).
    final flags = ref.watch(maskFlagsProvider('etc.search'));
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final groups = _groupByDay(_results);
    return [
      SliverList.builder(
        itemCount: groups.length,
        itemBuilder: (_, i) {
          final g = groups[i];
          return Padding(
            // 묶음 위 12 · 첫 묶음 4(원장 LedgerDayGroup 과 같다)
            padding: EdgeInsets.only(top: i == 0 ? PSpacing.x1 : PSpacing.x3),
            child: Column(
              key: ValueKey('search-day-${g.date.toIso8601String()}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PDayHeader(date: g.date, items: g.items, flags: flags),
                for (final e in g.items)
                  ExpenseRow(
                    expense: e,
                    category: _findCategory(categories, e.categoryRowId),
                    flags: flags,
                  ),
              ],
            ),
          );
        },
      ),
    ];
  }

  /// 결과를 날짜별로 묶는다 — 최신 날짜가 위(서버 정렬과 같은 방향).
  List<({DateTime date, List<Expense> items})> _groupByDay(List<Expense> rows) {
    final byDay = <String, List<Expense>>{};
    for (final e in rows) {
      final d = e.expenseDate;
      if (d == null || d.length < 10) continue;
      byDay.putIfAbsent(d.substring(0, 10), () => []).add(e);
    }
    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (date: parseIsoDate(k), items: byDay[k]!)];
  }

  ExpenseCategory? _findCategory(List<ExpenseCategory> categories, int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      if (c.rowId == rowId) return c;
    }
    return null;
  }
}

/// 고급 필터 시트 — 금액 범위(최소 ~ 최대) · 기간(Input Button → 기간 고르기 시트). 고르는 동안 결과는 그대로이고 [적용] 에서만
/// 돌려준다(웹 AdvancedFilter 의 draft). 최소 > 최대면 칸 아래 오류 + [적용] 막힘. 폼 시트라 바깥을 눌러도 닫히지 않고 ✕ 는 바꾼
/// 것을 버리고 닫는다(가계부 거르기 시트와 같다). 바닥은 [초기화](왼쪽 · 보조) · [적용](오른쪽) 반씩.
class _AdvancedSheet extends StatefulWidget {
  const _AdvancedSheet({required this.initial});

  final _Advanced initial;

  @override
  State<_AdvancedSheet> createState() => _AdvancedSheetState();
}

class _AdvancedSheetState extends State<_AdvancedSheet> {
  late final TextEditingController _min = TextEditingController(
    text: widget.initial.min?.toString() ?? '',
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.initial.max?.toString() ?? '',
  );
  late DateTime? _start = widget.initial.start;
  late DateTime? _end = widget.initial.end;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? get _minValue => _tooLarge(_min.text) ? null : int.tryParse(_min.text);
  int? get _maxValue => _tooLarge(_max.text) ? null : int.tryParse(_max.text);

  /// 금액 상한(100억 — 거래 · 예산 · 목표와 같은 [kAmountMax], 웹 `parseAmount` 와 같다)을 넘었나. 64비트를 넘는 자릿수도 읽어야
  /// 해서 글자로 견준다 — 칸에 보이는 숫자와 걸리는 조건이 달라지지 않게 넘으면 칸 오류 + [적용] 을 막는다.
  static bool _tooLarge(String digits) {
    final d = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final limit = kAmountMax.toString();
    if (d.length != limit.length) return d.length > limit.length;
    return d.compareTo(limit) > 0;
  }

  bool get _overAmount => _tooLarge(_min.text) || _tooLarge(_max.text);

  bool get _badAmount =>
      _minValue != null && _maxValue != null && _minValue! > _maxValue!;

  bool get _blocked => _overAmount || _badAmount;

  Future<void> _pickPeriod() async {
    final result = await showFilterPeriodSheet(
      context,
      current: _start == null ? null : PDateRange(start: _start, end: _end),
    );
    if (result?.start == null || result?.end == null || !mounted) return;
    setState(() {
      _start = result!.start;
      _end = result.end;
    });
  }

  void _reset() => setState(() {
    _min.clear();
    _max.clear();
    _start = null;
    _end = null;
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    // 이름은 "최소 금액" · "최대 금액"(칸마다 다른 이름), 보이는 예시 글은 "최소" · "최대"(웹과 같다)
    Widget amount(TextEditingController ctrl, String hint, String name) =>
        Expanded(
          child: PInput(
            controller: ctrl,
            placeholder: hint,
            semanticLabel: name,
            suffixText: wonUnit(),
            keyboardType: TextInputType.number,
            tabularFigures: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
        );
    return PBottomSheetContent(
      title: l.searchAdvancedFilter,
      closeLabel: l.actionClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // 폼 안 Field 사이 24(field.yaml form)
        spacing: PSpacing.x6,
        children: [
          PField(
            label: l.expAmountRange,
            invalid: _blocked,
            errorMessage: _overAmount ? l.amountTooLarge : l.searchBadAmount,
            child: Row(
              children: [
                amount(_min, l.expFilterMin, l.expMinAmount),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: PSpacing.x2),
                  child: ExcludeSemantics(
                    child: Text(
                      rangeSeparator(),
                      style: PTypography.t5.copyWith(color: c.fgNeutralSubtle),
                    ),
                  ),
                ),
                amount(_max, l.expFilterMax, l.expMaxAmount),
              ],
            ),
          ),
          PField(
            label: l.expFilterPeriod,
            child: PInputButton(
              key: const ValueKey('search-period'),
              placeholder: l.expFilterPeriodPick,
              suffixIcon: LucideIcons.calendarDays,
              value: _start == null
                  ? null
                  : formatRangeValue(
                      PDateRange(start: _start, end: _end),
                      DateTime.now(),
                    ),
              onPressed: _pickPeriod,
              onClear: _start == null
                  ? null
                  : () => setState(() {
                      _start = null;
                      _end = null;
                    }),
            ),
          ),
        ],
      ),
      footer: [
        PButton(
          label: l.actionReset,
          size: PButtonSize.large,
          variant: PButtonVariant.neutralWeak,
          onPressed: _reset,
        ),
        PButton(
          label: l.actionApply,
          size: PButtonSize.large,
          onPressed: _blocked
              ? null
              : () => PBottomSheet.of(context).close((
                  min: _minValue,
                  max: _maxValue,
                  start: _start,
                  end: _end,
                )),
        ),
      ],
    );
  }
}
