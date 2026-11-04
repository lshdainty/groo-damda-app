import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/features/card/presentation/card_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';

/// 거르기 칩 줄 — 필터 바(I-20 E 31 · I-07 28). 칩 둘 "카드 종류 ▾" · "혜택 ▾", 누르면 그 조건 하나만 고르기 시트로 열고
/// 줄 하나를 누르면 바로 고른다. 걸린 조건은 짙은 채움 + 값("신용" · "적립"), 하나라도 걸리면 맨 앞에 ↺(모두 지움).
/// "캐시백" 칩은 없다 — 서버 혜택 유형은 할인 · 적립 · 마일리지 셋이다.
class CardFilterBar extends StatelessWidget {
  const CardFilterBar({
    super.key,
    required this.type,
    required this.benefit,
    required this.onType,
    required this.onBenefit,
  });

  /// null = 전체.
  final String? type;
  final String? benefit;
  final ValueChanged<String?> onType;
  final ValueChanged<String?> onBenefit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String typeName(String? k) => switch (k) {
      'CREDIT' => l.assetCardShortCredit,
      'CHECK' => l.assetCardShortCheck,
      _ => l.expFilterAll,
    };
    String benefitName(String? k) => benefitTypeText(l, k) ?? l.expFilterAll;
    Future<void> pick(
      String title,
      List<String?> values,
      String Function(String?) name,
      String? selected,
      ValueChanged<String?> on,
    ) async {
      final picked = await PBottomSheet.show<_Pick>(
        context,
        builder: (_) => PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          flushBody: true,
          scrollFog: true,
          body: PickList<_Pick>(
            label: title,
            selected: _Pick(selected),
            items: [
              for (final v in values) PickItem(value: _Pick(v), title: name(v)),
            ],
          ),
        ),
      );
      if (picked != null) on(picked.value);
    }

    return PChipGroup(
      layout: PChipGroupLayout.scroll,
      semanticLabel: l.cardFilterBar,
      children: [
        if (type != null || benefit != null)
          PChip.icon(
            icon: LucideIcons.rotateCcw,
            semanticLabel: l.cardFilterClear,
            variant: PChipVariant.outlineStrong,
            onPressed: () {
              onType(null);
              onBenefit(null);
            },
          ),
        PChip(
          label: type == null ? l.cardTypeChip : typeName(type),
          variant: PChipVariant.solid,
          selected: type != null,
          suffixIcon: LucideIcons.chevronDown,
          onPressed: () =>
              pick(l.cardTypeChip, kTypeFilterValues, typeName, type, onType),
        ),
        PChip(
          label: benefit == null ? l.cardBenefitChip : benefitName(benefit),
          variant: PChipVariant.solid,
          selected: benefit != null,
          suffixIcon: LucideIcons.chevronDown,
          onPressed: () => pick(
            l.cardBenefitChip,
            kBenefitFilterValues,
            benefitName,
            benefit,
            onBenefit,
          ),
        ),
      ],
    );
  }
}

/// 고르기 시트가 null(전체)도 돌려줄 수 있게 감싼다 — 시트를 그냥 닫은 것(null)과 "전체" 를 가른다.
class _Pick {
  const _Pick(this.value);
  final String? value;

  @override
  bool operator ==(Object other) => other is _Pick && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
