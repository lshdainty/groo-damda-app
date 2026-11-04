import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/features/recurring/domain/recurring_schedule.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

const _tabular = [FontFeature.tabularFigures()];

/// 줄 앞 타일 — 카테고리 색 옅은 바탕 + 아이콘. 이체는 회색 `arrow-right-left`, 카테고리가 지워져 없으면 회색 `tag`.
/// 상세 머리는 [size] 48 · [iconSize] 24 로 키운다(크기를 바꾸면 모서리도 함께).
Widget recurringTile(
  BuildContext context,
  RecurringTransaction it,
  ExpenseCategory? category, {
  double size = PListTile.size,
  double iconSize = 20,
}) {
  final c = context.colors;
  final Color bg;
  final Color fg;
  final IconData icon;
  if (it.expenseType == 'TRANSFER') {
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
  if (size == PListTile.size) {
    return PListTile(background: bg, color: fg, child: Icon(icon));
  }
  return ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(PRounded.r4),
        ),
        child: Center(
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    ),
  );
}

/// 줄 설명 — "다음 11월 25일 · 매월 25일 · 12번 중 3번". 말줄임 없이 **항목 통째로** 다음 줄로 간다(항목 안 공백은 줄이
/// 안 바뀌는 공백). 공용 Tag Group 은 손대지 않고 wrap 모드를 그대로 쓴다.
Widget recurringDescription(BuildContext context, RecurringTransaction it) {
  final l = AppLocalizations.of(context);
  return PTagGroup(
    size: PTagGroupSize.t3,
    items: [for (final p in recRowDetailParts(l, it)) PTag(recNoBreak(p))],
  );
}

/// 오른쪽 기둥 — 금액(t5 · 700) + 쉬는 줄이면 그 아래 Badge "일시정지". **줄 수와 상관없이 오른쪽 맞춤**이다.
Widget recurringValueColumn(
  BuildContext context,
  RecurringTransaction it, {
  bool masked = false,
}) {
  final l = AppLocalizations.of(context);
  final text = recAmountText(it, masked: masked);
  return PListValue(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      spacing: PSpacing.x1,
      children: [
        Text(
          keepAllAmount(text),
          semanticsLabel: text,
          textAlign: TextAlign.end,
          style: PTypography.t5.copyWith(
            color: recAmountColor(context, it),
            fontWeight: FontWeight.w700,
            fontFeatures: _tabular,
          ),
        ),
        if (isPausedRec(it)) PBadge(label: l.recPausedBadge),
      ],
    ),
  );
}

/// 반복 줄(누르는 줄) — ds `PListButtonItem` 위 맞춤: 앞 타일 40 · 제목(+ 자동 기록이면 `zap` 14) · 설명 · 오른쪽 기둥.
/// 줄 끝 ⋮ 는 없다(2026-10-25 원칙 — 줄 누름 = 상세).
class RecurringListRow extends StatelessWidget {
  const RecurringListRow({
    super.key,
    required this.item,
    required this.category,
    required this.onTap,
    this.masked = false,
  });

  final RecurringTransaction item;
  final ExpenseCategory? category;
  final VoidCallback onTap;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return PListButtonItem(
      title: recDisplayTitle(l, item),
      align: PListAlign.top,
      prefix: recurringTile(context, item, category),
      titleSuffix: item.autoLog
          ? [
              Semantics(
                label: l.recAutoLog,
                child: Icon(LucideIcons.zap, size: 14, color: c.fgBrand),
              ),
            ]
          : null,
      detailChild: recurringDescription(context, item),
      suffix: recurringValueColumn(context, item, masked: masked),
      onTap: onTap,
    );
  }
}
