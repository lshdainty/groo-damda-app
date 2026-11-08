import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/clock/clock.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/domain/expense_filter.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';

/// 필터가 걸렸을 때 칩 줄 — 걸린 조건마다 입력값 칩 하나 + 뒤 지우기(I-07 9). 한 줄 가로 스크롤 · 양 끝 Scroll Fog 20.
///
/// 칩 글은 지금 키 그대로, 지우기 이름은 "{글} 지우기". 지우면 그 조건 하나만 비운다.
class LedgerFilterChips extends ConsumerWidget {
  const LedgerFilterChips({
    super.key,
    required this.filter,
    required this.assetId,
    required this.onClearAsset,
    required this.onChange,
    required this.categories,
  });

  final ExpenseFilter filter;
  final int? assetId;
  final VoidCallback onClearAsset;
  final ValueChanged<ExpenseFilter> onChange;
  final List<ExpenseCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final f = filter;
    final chips = <Widget>[];

    void add(String label, VoidCallback onRemove) {
      chips.add(
        PInputChip(
          label: label,
          removeLabel: l.expFilterClearOne(label),
          onRemove: onRemove,
        ),
      );
    }

    if (assetId != null) {
      final all = ref.watch(assetsProvider).value;
      final name = all?.byRowId(assetId!)?.assetName;
      add(name == null ? l.expFiltering : l.expFilteringBy(name), onClearAsset);
    }
    // 조건이 여러 칸이라 항목마다 칩을 세우면 줄이 넘친다. 칸 단위 요약 칩으로 줄이고 지우기는 그 칸을 비운다.
    if (activeConditionCount(f) > 1 && f.match == MatchMode.any) {
      add(
        l.expFilterMatchAny,
        () => onChange(f.copyWith(match: MatchMode.all)),
      );
    }
    if (f.periods.length > 1) {
      add(
        '${l.expFilterPeriod} ${f.periods.length}',
        () => onChange(f.copyWith(periods: [f.periods.first])),
      );
    } else if (f.periods.length == 1) {
      final p = f.periods.first;
      // 날짜 표기 하나(date-picker.md) — 기간 시트의 입력 칸과 같은 함수(`formatRangeValue`)
      DateTime? day(String d) {
        final t = DateTime.tryParse(d);
        return t == null ? null : DateTime(t.year, t.month, t.day);
      }

      final label = formatRangeValue(
        PDateRange(start: day(p.start), end: day(p.end)),
        ref.read(clockProvider)(),
      );
      add(label, () => onChange(f.copyWith(periods: const [])));
    }
    if (f.types.length < 2) {
      add(
        f.types.contains('EXPENSE') ? l.expFilterExpense : l.expFilterIncome,
        () => onChange(f.copyWith(types: const {'EXPENSE', 'INCOME'})),
      );
    }
    if (f.categories.include.isNotEmpty) {
      add(
        f.categories.include.length == 1
            ? (categories.byRowId(f.categories.include.first)?.categoryName ??
                  '${f.categories.include.first}')
            : '${l.expCategory} ${f.categories.include.length}',
        () => onChange(
          f.copyWith(categories: f.categories.copyWith(include: const {})),
        ),
      );
    }
    if (f.categories.exclude.isNotEmpty) {
      add(
        l.expFilterExcluded(f.categories.exclude.length),
        () => onChange(
          f.copyWith(categories: f.categories.copyWith(exclude: const {})),
        ),
      );
    }
    if (f.assets.include.isNotEmpty) {
      final all = ref.watch(assetsProvider).value;
      add(
        f.assets.include.length == 1
            ? (all?.byRowId(f.assets.include.first)?.assetName ??
                  '${f.assets.include.first}')
            : '${l.expAccountCard} ${f.assets.include.length}',
        () =>
            onChange(f.copyWith(assets: f.assets.copyWith(include: const {}))),
      );
    }
    if (f.assets.exclude.isNotEmpty) {
      add(
        l.expFilterExcluded(f.assets.exclude.length),
        () =>
            onChange(f.copyWith(assets: f.assets.copyWith(exclude: const {}))),
      );
    }
    if (f.amountRanges.isNotEmpty) {
      add(
        '${l.expAmountRange} ${f.amountRanges.length}',
        () => onChange(f.copyWith(amountRanges: const [])),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return PChipGroup(
      layout: PChipGroupLayout.scroll,
      semanticLabel: l.expFilter,
      children: chips,
    );
  }
}
