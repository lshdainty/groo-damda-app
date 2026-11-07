import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_filter.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

/// 필터 조건 본문 부품 여섯(I-07 E) — **조건마다 하나**. 폰 시트(이 PR)가 차례로 쌓고, 07-2 가 팝오버 · 시트에 나눠 담는다.
///
/// 값은 [ExpenseFilter] 의 그 조각을 그대로 받고 돌려준다(모델 · `matchesFilter` 는 바꾸지 않는다). 부품은 자기 머리(조건 이름)를
/// 가진다 — 한 조건만 담는 곳은 [withHeader] 를 false 로 두고 바깥 제목을 쓴다.
const double _gap = PSpacing.x2;

Widget _pad(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
  child: child,
);

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.withHeader,
    required this.children,
  });

  final String title;
  final bool withHeader;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (withHeader) PListHeader(title: title),
      ...children,
    ],
  );
}

// ── 조건 맞추기 ─────────────────────────────────────────────────

/// 조건 맞추기 — 안내 + 라디오 줄 둘("모두 일치" · "하나라도 일치"). 조건이 하나 이하면 두 줄 모두 막힌다(기간 · '빼고' 는 세지 않는다).
class FilterMatchBody extends StatelessWidget {
  const FilterMatchBody({
    super.key,
    required this.value,
    required this.conditionCount,
    required this.onChanged,
    this.withHeader = true,
  });

  final MatchMode value;

  /// 켜진 포함 조건 수(`activeConditionCount`).
  final int conditionCount;
  final ValueChanged<MatchMode> onChanged;
  final bool withHeader;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final locked = conditionCount <= 1;
    return _Section(
      title: l.expFilterMatch,
      withHeader: withHeader,
      children: [
        _pad(
          PText(
            l.expFilterPeriodAlwaysAnd,
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
        const SizedBox(height: PSpacing.x1),
        PListRadioGroup<MatchMode>(
          semanticLabel: l.expFilterMatch,
          value: locked ? MatchMode.all : value,
          onChanged: locked ? null : onChanged,
          children: [
            PListRadioItem<MatchMode>(
              value: MatchMode.all,
              title: l.expFilterMatchAll,
              detail: l.expFilterMatchAllDesc,
            ),
            PListRadioItem<MatchMode>(
              value: MatchMode.any,
              title: l.expFilterMatchAny,
              detail: l.expFilterMatchAnyDesc,
            ),
          ],
        ),
        if (locked)
          _pad(
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x1_5),
              child: PText(
                l.expFilterMatchHint,
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ),
          ),
      ],
    );
  }
}

// ── 기간 ────────────────────────────────────────────────────────

DateTime? _parseDay(String s) {
  final d = DateTime.tryParse(s);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 폰 빠른 기간 — 옛 폰 탭에 있던 이번 주 · 이번 달 · 3개월만(스펙 한 벌의 넓은 기간 지난달 · 올해는 폰에 들이지 않는다).
const kFilterPeriodPresets = [
  PDatePreset.thisWeek,
  PDatePreset.thisMonth,
  PDatePreset.last3Months,
];

/// 기간 고르는 시트 — 달이 위아래로 이어지고 위에 빠른 기간 칩 줄(이번 주 · 이번 달 · 3개월 — 옛 폰에 있던 것만)이 있다. 바닥은 "초기화" + "완료"(끝을 고르기 전에는 "완료" 가 막힌다).
Future<PDateRange?> showFilterPeriodSheet(
  BuildContext context, {
  required PDateRange? current,
}) {
  final l = AppLocalizations.of(context);
  final labels = PDatePickerLabels.of(context);
  return PBottomSheet.show<PDateRange>(
    context,
    builder: (_) {
      PDateRange? draft = current;
      return StatefulBuilder(
        builder: (sheetContext, setState) => PBottomSheetContent(
          title: l.expFilterPeriodPick,
          closeLabel: l.actionClose,
          flushBody: true,
          body: SizedBox(
            height: PDatePicker.sheetBodyHeight(sheetContext),
            child: PDatePicker.range(
              labels: labels,
              semanticLabel: l.expFilterPeriodPick,
              visibleRange: PDateVisibleRange.continuous,
              presets: kFilterPeriodPresets,
              value: draft,
              min: DateTime(2000),
              max: DateTime(2100),
              onChanged: (v) => setState(() => draft = v),
            ),
          ),
          footer: [
            PButton(
              label: l.actionReset,
              size: PButtonSize.large,
              variant: PButtonVariant.neutralWeak,
              onPressed: () => setState(() => draft = null),
            ),
            PButton(
              label: l.actionDone,
              size: PButtonSize.large,
              onPressed: draft?.end == null
                  ? null
                  : () => PBottomSheet.of(sheetContext).close(draft),
            ),
          ],
        ),
      );
    },
  );
}

/// 기간 — 칸마다 Input Button(누르면 기간 시트). 칸은 셋까지, "기간 추가" · 줄 지우기 ✕ 는 그대로. 오류는 칸 아래.
class FilterPeriodBody extends StatelessWidget {
  const FilterPeriodBody({
    super.key,
    required this.periods,
    required this.onChanged,
    this.withHeader = true,
  });

  final List<FilterPeriodRange> periods;
  final ValueChanged<List<FilterPeriodRange>> onChanged;
  final bool withHeader;

  static bool isBad(FilterPeriodRange p) =>
      p.start.isNotEmpty && p.end.isNotEmpty && p.start.compareTo(p.end) > 0;

  Future<void> _pick(BuildContext context, int i) async {
    final p = periods[i];
    final result = await showFilterPeriodSheet(
      context,
      current: PDateRange(start: _parseDay(p.start), end: _parseDay(p.end)),
    );
    if (result?.start == null || result?.end == null) return;
    final next = [...periods];
    next[i] = FilterPeriodRange(
      preset: FilterPeriodPreset.custom,
      start: _ymd(result!.start!),
      end: _ymd(result.end!),
    );
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final today = DateTime.now();
    return _Section(
      title: l.expFilterPeriod,
      withHeader: withHeader,
      children: [
        for (var i = 0; i < periods.length; i++)
          _pad(
            Padding(
              padding: EdgeInsets.only(
                bottom: i == periods.length - 1 ? 0 : _gap,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PInputButton(
                      semanticLabel: l.expFilterPeriod,
                      placeholder: l.expFilterPeriodPick,
                      prefixIcon: LucideIcons.calendar,
                      invalid: isBad(periods[i]),
                      value: formatRangeValue(
                        PDateRange(
                          start: _parseDay(periods[i].start),
                          end: _parseDay(periods[i].end),
                        ),
                        today,
                      ),
                      onPressed: () => _pick(context, i),
                    ),
                  ),
                  if (periods.length > 1)
                    PButton.icon(
                      icon: LucideIcons.x,
                      semanticLabel: l.expFilterRemoveRow,
                      variant: PButtonVariant.ghost,
                      size: PButtonSize.small,
                      onPressed: () => onChanged([...periods]..removeAt(i)),
                    ),
                ],
              ),
            ),
          ),
        if (periods.any(isBad))
          _pad(
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x1_5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PSpacing.x1_5,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: PSpacing.x0_5),
                    child: Icon(
                      LucideIcons.circleAlert,
                      size: PSpacing.x4,
                      color: c.fgCritical,
                    ),
                  ),
                  Expanded(
                    child: PText(
                      l.expDateRangeError,
                      style: PTypography.t4.copyWith(color: c.fgCritical),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (periods.length < ExpenseFilter.maxPeriods)
          _pad(
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PButton(
                label: l.expFilterAddPeriod,
                size: PButtonSize.small,
                variant: PButtonVariant.ghost,
                prefixIcon: LucideIcons.plus,
                onPressed: () => onChanged([
                  ...periods,
                  resolvePeriod(FilterPeriodPreset.month),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

// ── 거래 종류 ───────────────────────────────────────────────────

/// 거래 종류 — 지출 · 수입 둘을 Chip `outlineWeak` 으로 여럿 고른다. 둘 다 끄면 둘 다 켠 것과 같다(`typeActive` 규칙 그대로).
class FilterTypeBody extends StatelessWidget {
  const FilterTypeBody({
    super.key,
    required this.types,
    required this.onChanged,
    this.withHeader = true,
  });

  final Set<String> types;
  final ValueChanged<Set<String>> onChanged;
  final bool withHeader;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void toggle(String code, bool on) {
      final next = {...types};
      on ? next.add(code) : next.remove(code);
      onChanged(next);
    }

    return _Section(
      title: l.expTxType,
      withHeader: withHeader,
      children: [
        _pad(
          PChipGroup(
            semanticLabel: l.expTxType,
            children: [
              PChipToggle(
                label: l.expTypeExpense,
                checked: types.contains('EXPENSE'),
                onChanged: (v) => toggle('EXPENSE', v),
              ),
              PChipToggle(
                label: l.expTypeIncome,
                checked: types.contains('INCOME'),
                onChanged: (v) => toggle('INCOME', v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 카테고리 · 계좌·카드 — "고른 것만 · 고른 것 빼고" 를 먼저 ─────────────

/// 넣기 · 빼기 하나 고르기 칩 둘. 한 조건 안에서 넣기 · 빼기를 섞지 않는다 — 바꾸면 고른 것이 반대쪽 묶음으로 옮겨 간다.
class _ModeChips extends StatelessWidget {
  const _ModeChips({
    required this.condition,
    required this.exclude,
    required this.onChanged,
  });

  /// 조건 이름 — 묶음 이름 "{조건} 고르는 방식" 에 들어간다.
  final String condition;
  final bool exclude;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _pad(
      PChipGroup(
        semanticLabel: l.expFilterModeGroup(condition),
        children: [
          PChip(
            label: l.expFilterModeInclude,
            variant: PChipVariant.outlineStrong,
            selected: !exclude,
            onPressed: () => onChanged(false),
          ),
          PChip(
            label: l.expFilterModeExclude,
            variant: PChipVariant.outlineStrong,
            selected: exclude,
            onPressed: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

/// [IncludeExclude] 의 처음 모드 — 빼기만 채워져 있으면 "고른 것 빼고". 이후 모드는 부품이 상태로 쥔다.
bool _isExcludeMode(IncludeExclude v) =>
    v.include.isEmpty && v.exclude.isNotEmpty;

IncludeExclude _withMode(IncludeExclude v, bool exclude, Set<int> picked) =>
    exclude ? IncludeExclude(exclude: picked) : IncludeExclude(include: picked);

IncludeExclude _switchMode(IncludeExclude v, bool toExclude) {
  final picked = _isExcludeMode(v) ? v.exclude : v.include;
  return _withMode(v, toExclude, {...picked});
}

/// 카테고리 — 모드 칩 + 부모 카테고리 칩 여럿(하위는 `expandCats` 가 펼친다). 모드는 값에서 추론하지 않고 이 부품이 쥔다 —
/// 아무것도 안 고른 채 "고른 것 빼고" 를 먼저 눌러도 그대로 남는다.
class FilterCategoryBody extends ConsumerStatefulWidget {
  const FilterCategoryBody({
    super.key,
    required this.value,
    required this.onChanged,
    this.withHeader = true,
  });

  final IncludeExclude value;
  final ValueChanged<IncludeExclude> onChanged;
  final bool withHeader;

  @override
  ConsumerState<FilterCategoryBody> createState() => _FilterCategoryBodyState();
}

class _FilterCategoryBodyState extends ConsumerState<FilterCategoryBody> {
  late bool _exclude = _isExcludeMode(widget.value);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final parents = categories.where((c) => c.parentRowId == null).toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    if (parents.isEmpty) return const SizedBox.shrink();
    final value = widget.value;
    final picked = _exclude ? value.exclude : value.include;
    return _Section(
      title: l.expCategory,
      withHeader: widget.withHeader,
      children: [
        _ModeChips(
          condition: l.expCategory,
          exclude: _exclude,
          onChanged: (v) {
            setState(() => _exclude = v);
            widget.onChanged(_switchMode(value, v));
          },
        ),
        const SizedBox(height: PSpacing.x2),
        _pad(
          PChipGroup(
            semanticLabel: l.expCategory,
            children: [
              for (final c in parents)
                PChipToggle(
                  label: c.categoryName,
                  checked: picked.contains(c.rowId),
                  onChanged: (on) {
                    final next = {...picked};
                    on ? next.add(c.rowId) : next.remove(c.rowId);
                    widget.onChanged(_withMode(value, _exclude, next));
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 계좌 · 카드 — 모드 칩 + 체크 줄(앞 Logo Tile 40 · 뒤 체크 24). 모드는 부품이 쥔다(위와 같다).
class FilterAssetBody extends ConsumerStatefulWidget {
  const FilterAssetBody({
    super.key,
    required this.value,
    required this.onChanged,
    this.withHeader = true,
  });

  final IncludeExclude value;
  final ValueChanged<IncludeExclude> onChanged;
  final bool withHeader;

  @override
  ConsumerState<FilterAssetBody> createState() => _FilterAssetBodyState();
}

class _FilterAssetBodyState extends ConsumerState<FilterAssetBody> {
  late bool _exclude = _isExcludeMode(widget.value);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final assets = ref.watch(assetsProvider).value ?? const [];
    if (assets.isEmpty) return const SizedBox.shrink();
    final value = widget.value;
    final picked = _exclude ? value.exclude : value.include;
    return _Section(
      title: l.expAccountCard,
      withHeader: widget.withHeader,
      children: [
        _ModeChips(
          condition: l.expAccountCard,
          exclude: _exclude,
          onChanged: (v) {
            setState(() => _exclude = v);
            widget.onChanged(_switchMode(value, v));
          },
        ),
        const SizedBox(height: PSpacing.x1),
        PListCheckGroup(
          semanticLabel: l.expAccountCard,
          children: [
            for (final a in assets)
              PListCheckItem(
                title: a.assetName,
                checked: picked.contains(a.rowId),
                markPosition: PListMarkPosition.suffix,
                prefix: AssetLogo(asset: a),
                onChanged: (on) {
                  final next = {...picked};
                  on ? next.add(a.rowId) : next.remove(a.rowId);
                  widget.onChanged(_withMode(value, _exclude, next));
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ── 금액 ────────────────────────────────────────────────────────

/// 금액 — 구간 줄(최소 ~ 최대, 숫자 키보드 · 뒤 글 "원"). 구간은 셋까지, "구간 추가" · 줄 지우기. 칸 글은 이 부품이 쥔다(리셋은 key 로 다시 만든다).
class FilterAmountBody extends StatefulWidget {
  const FilterAmountBody({
    super.key,
    required this.initial,
    required this.onChanged,
    this.withHeader = true,
  });

  final List<AmountRange> initial;
  final ValueChanged<List<AmountRange>> onChanged;
  final bool withHeader;

  @override
  State<FilterAmountBody> createState() => _FilterAmountBodyState();
}

class _FilterAmountBodyState extends State<FilterAmountBody> {
  late List<(TextEditingController, TextEditingController)> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final r in widget.initial)
        (
          TextEditingController(text: r.min?.toString() ?? ''),
          TextEditingController(text: r.max?.toString() ?? ''),
        ),
    ];
  }

  @override
  void dispose() {
    for (final (mn, mx) in _rows) {
      mn.dispose();
      mx.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged([
    for (final (mn, mx) in _rows)
      AmountRange(min: int.tryParse(mn.text), max: int.tryParse(mx.text)),
  ]);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return _Section(
      title: l.expAmountRange,
      withHeader: widget.withHeader,
      children: [
        for (var i = 0; i < _rows.length; i++)
          _pad(
            Padding(
              padding: const EdgeInsets.only(bottom: PSpacing.x2),
              child: Row(
                children: [
                  Expanded(
                    child: PInput(
                      controller: _rows[i].$1,
                      placeholder: l.expMinAmount,
                      semanticLabel: l.expMinAmount,
                      suffixText: wonUnit(),
                      keyboardType: TextInputType.number,
                      tabularFigures: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PSpacing.x2,
                    ),
                    child: Text(
                      rangeSeparator(),
                      style: PTypography.t5.copyWith(color: c.fgNeutralSubtle),
                    ),
                  ),
                  Expanded(
                    child: PInput(
                      controller: _rows[i].$2,
                      placeholder: l.expMaxAmount,
                      semanticLabel: l.expMaxAmount,
                      suffixText: wonUnit(),
                      keyboardType: TextInputType.number,
                      tabularFigures: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  PButton.icon(
                    icon: LucideIcons.x,
                    semanticLabel: l.expFilterRemoveRow,
                    variant: PButtonVariant.ghost,
                    size: PButtonSize.small,
                    onPressed: () {
                      setState(() {
                        final (mn, mx) = _rows.removeAt(i);
                        mn.dispose();
                        mx.dispose();
                      });
                      _emit();
                    },
                  ),
                ],
              ),
            ),
          ),
        if (_rows.length < ExpenseFilter.maxAmountRanges)
          _pad(
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PButton(
                label: l.expFilterAddAmountRange,
                size: PButtonSize.small,
                variant: PButtonVariant.ghost,
                prefixIcon: LucideIcons.plus,
                onPressed: () {
                  setState(
                    () => _rows.add((
                      TextEditingController(),
                      TextEditingController(),
                    )),
                  );
                  _emit();
                },
              ),
            ),
          ),
      ],
    );
  }
}
