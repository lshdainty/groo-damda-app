import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

const _tabular = [FontFeature.tabularFigures()];

/// 고정 금액이 켜져 있고 값이 있는가 — 서버 `resolveAmount`(고정 켬 ⇔ 금액 > 0)와 같은 뜻이다.
bool presetHasAmount(ExpenseTemplate p) =>
    (p.lockAmount ?? 'N') == 'Y' && p.amount != null;

/// 금액 글 — 지출 "−" · 수입 "+" · 이체는 부호 없음. 원까지. 가림이 켜지면 점(웹 `presetAmountText` 와 같은 부호 규칙).
/// 고정 금액이 아니면 null.
String? presetAmountText(ExpenseTemplate p, {bool masked = false}) {
  if (!presetHasAmount(p)) return null;
  final sign = p.expenseType == 'TRANSFER'
      ? ''
      : (p.expenseType == 'EXPENSE' ? kMinus : '+');
  return krwSigned(p.amount!.abs(), masked, sign: sign, unit: true);
}

/// 금액 글 색 — 수입만 `fg-brand`, 지출 · 이체는 `fg-neutral`(list.md Suffix).
Color presetAmountColor(BuildContext context, ExpenseTemplate p) =>
    p.expenseType == 'INCOME'
    ? context.colors.fgBrand
    : context.colors.fgNeutral;

/// 줄 앞 타일(40) — 카테고리 색 옅은 바탕 + 아이콘. 이체는 회색 `arrow-right-left`(list.md "이체 줄은 회색"), 카테고리가 지워져
/// 없으면 회색 `tag`. 상세 머리 · 폼 미리보기는 [size] · [radius] 로 키운다(크기를 바꾸면 모서리도 함께).
Widget presetTile(
  BuildContext context,
  ExpenseTemplate p,
  ExpenseCategory? category, {
  double size = PListTile.size,
  double iconSize = 20,
  double? radius,
}) {
  final c = context.colors;
  final Color bg;
  final Color fg;
  final IconData icon;
  if (p.expenseType == 'TRANSFER') {
    bg = c.chartGrayWeak;
    fg = c.chartGray;
    icon = LucideIcons.arrowRightLeft;
  } else if (category == null) {
    bg = c.chartGrayWeak;
    fg = c.chartGray;
    icon = LucideIcons.tag;
  } else {
    fg = resolveChartColor(context, category.color, fallback: c.fgBrand);
    bg = softBg(context, fg);
    icon = lucideByName(category.icon);
  }
  if (size == PListTile.size && radius == null) {
    return PListTile(background: bg, color: fg, child: Icon(icon));
  }
  return ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius ?? PRounded.r4),
        ),
        child: Center(
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    ),
  );
}

/// 설명 조각 — 지출 · 수입 "{카테고리} · {계좌·카드}"(없는 조각은 뺀다), 이체 "{보내는} → {받는}". 한 줄 말줄임(Tag Group t3).
Widget presetDescription(BuildContext context, ExpenseTemplate p) {
  final l = AppLocalizations.of(context);
  if (p.expenseType == 'TRANSFER') {
    return PTagGroup(
      size: PTagGroupSize.t3,
      overflow: PTagGroupOverflow.truncate,
      items: [PTag(transferPartiesLabel(p.assetName, p.toAssetName))],
    );
  }
  return PTagGroup(
    size: PTagGroupSize.t3,
    overflow: PTagGroupOverflow.truncate,
    items: [
      PTag(p.categoryName ?? l.presetNoCategory),
      if (p.assetName != null && p.assetName!.isNotEmpty)
        PTag(p.assetName!, shrink: 2),
    ],
  );
}

/// 오른쪽 기둥 — 위 금액(또는 "금액 비움") · 아래 "{n}번". **줄 수와 상관없이 오른쪽 맞춤**이다(글 끝 x 가 웹과 같다).
/// 금액 비움은 금액 줄(t5 22)과 같은 줄 높이를 써서 금액 있는 줄 · 비운 줄의 높이가 같다.
Widget presetValueColumn(
  BuildContext context,
  ExpenseTemplate p, {
  bool masked = false,
}) {
  final l = AppLocalizations.of(context);
  final c = context.colors;
  final text = presetAmountText(p, masked: masked);
  return PListValue(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      spacing: PSpacing.x1,
      children: [
        if (text != null)
          Text(
            keepAllAmount(text),
            semanticsLabel: text,
            textAlign: TextAlign.end,
            style: PTypography.t5.copyWith(
              color: presetAmountColor(context, p),
              fontWeight: FontWeight.w700,
              fontFeatures: _tabular,
            ),
          )
        else
          PText(
            l.presetAmountEmpty,
            textAlign: TextAlign.end,
            style: PTypography.t3.copyWith(
              color: c.fgNeutralSubtle,
              // 금액 줄(t5)과 같은 줄 높이
              height: 22 / 13,
            ),
          ),
        Text(
          l.presetUses(p.useCount ?? 0),
          textAlign: TextAlign.end,
          style: PTypography.t3.copyWith(
            color: c.fgNeutralSubtle,
            fontFeatures: _tabular,
          ),
        ),
      ],
    ),
  );
}

/// 프리셋 줄(누르는 줄) — 프리셋 관리 목록과 내역 추가 시트의 "프리셋 고르기" 가 같은 부품을 쓴다. ds `PListButtonItem` 위 맞춤:
/// 앞 타일 40 · 제목 이름 · 설명 한 줄 말줄임 · 오른쪽 기둥. 줄 끝 ⋮ 는 없다(2026-10-25 원칙 — 줄 누름 = 상세).
class PresetListRow extends StatelessWidget {
  const PresetListRow({
    super.key,
    required this.preset,
    required this.category,
    required this.onTap,
    this.masked = false,
  });

  final ExpenseTemplate preset;
  final ExpenseCategory? category;
  final VoidCallback onTap;
  final bool masked;

  @override
  Widget build(BuildContext context) => PListButtonItem(
    title: preset.templateName,
    align: PListAlign.top,
    prefix: presetTile(context, preset, category),
    detailChild: presetDescription(context, preset),
    suffix: presetValueColumn(context, preset, masked: masked),
    onTap: onTap,
  );
}
