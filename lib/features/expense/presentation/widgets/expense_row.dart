import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

/// 아직 오지 않은 거래인가 — 서버가 합계에서 빼는 기준과 같다.
bool _isScheduled(String? expenseDate) {
  if (expenseDate == null) return false;
  final normalized = expenseDate.length == 10
      ? '${expenseDate}T23:59:59'
      : expenseDate;
  return DateTime.parse(normalized).isAfter(DateTime.now());
}

/// 거래 시각 "HH:mm" — 00:00 이면 null(시각이 없는 거래). 웹 `txTimeLabel` 과 같은 규칙.
String? txTimeLabel(String? raw) {
  if (raw == null || raw.length < 16) return null;
  final time = raw.substring(11, 16);
  return time == '00:00' ? null : time;
}

/// 거래 줄 — 가계부 · 검색 · 자산 상세 · 거래 상세 · 홈이 **같이 쓰는 하나뿐인 줄**이다(ds List 줄 값, I-06 28).
///
/// 앞 타일 40(모서리 12 · 카테고리 옅은 바탕) · 제목 t5 400(줄을 바꾼다, 말줄임 없음 — 뒤에 배지가 이어 붙는다) ·
/// 설명 Tag Group t3 한 줄 말줄임(분류 · 통장 · 할부) · 금액 t5 700 고정폭 원까지(지출 `fg-neutral`, 수입만 `fg-brand` + "+").
/// 합계에 안 드는 줄(예정 · 환불)은 줄 전체를 흐리지 않고 제목 · 금액만 `fg-neutral-subtle` 이며 배지가 말한다.
/// 줄이 제 좌우 24 · 위아래 12 를 가지므로 부르는 쪽은 좌우 여백을 두지 않는다.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    required this.expense,
    required this.category,
    required this.flags,
    this.interactive = true,
    this.onTap,
    this.showInstallment = false,
    this.gutter,
    this.highlighted = false,
    super.key,
  });

  final Expense expense;
  final ExpenseCategory? category;

  /// 화면 카드 + 종류 카드. 행이 자기 종류(수입/지출)로 판정한다.
  final MaskFlags flags;

  /// false 면 누르지 않는 줄 — 단순 표시 용도 (예: 가맹점 history).
  final bool interactive;

  /// 탭했을 때 할 일. 안 주면 거래 상세 시트를 연다(목록의 기본 동작).
  ///
  /// 홈의 '오늘 쓴 돈' 은 상세를 띄우는 대신 가계부의 그 거래로 **이동**한다 —
  /// 요약 카드라 거기서 더 볼 게 없고, 맥락째 옮겨 주는 편이 낫다.
  final VoidCallback? onTap;

  /// 할부면 설명에 "할부 N개월" 을 붙인다 — 카드 상세의 이용 내역이 쓴다.
  ///
  /// 할부 행의 금액은 원금(전액)이라, 이 표시가 없으면 회차 청구(예정액)와 행 금액이
  /// 왜 다른지 알 길이 없다. 가계부 목록은 결제 수단을 따지지 않으므로 끈다.
  final bool showInstallment;

  /// **임시 인자** — 기본(null)은 ds List 줄의 24(홈이 쓴다). 좌우 24 를 아직 쥐고 있는 호스트(가계부 · 검색 · 자산 상세 · 거래
  /// 상세)는 0 을 넘겨 글자 자리가 24 로 같게 한다. 그 화면이 바깥 24 를 걷을 때 함께 걷는다.
  final double? gutter;

  /// 알림 · 검색에서 들어온 줄 — ds List `highlighted`(바탕 `bg-brand-weak`, 누름 · 설명 글 보정이 따라온다).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);

    // 카테고리 색은 백엔드 카테고리 우선, 없으면 거래에 임베드된 categoryColor, 없으면 토큰
    final colorRaw = category?.color ?? expense.categoryColor;
    final iconRaw = category?.icon ?? expense.categoryIcon;
    final cName =
        category?.categoryName ?? expense.categoryName ?? l.expUncategorized;

    final scheduled = _isScheduled(expense.expenseDate);
    final refunded = expense.isRefunded;
    // 합계에 안 드는 줄 — 예정(아직 안 빠진 돈) · 환불(취소된 돈)
    final excluded = scheduled || refunded;

    final fg = resolveChartColor(context, colorRaw, fallback: c.fgBrand);
    final bg = softBg(context, fg);
    final icon = lucideByName(iconRaw, fallback: LucideIcons.tag);

    final income = expense.signedAmount > 0;
    final amountColor = excluded
        ? c.fgNeutralSubtle
        : (income ? c.fgBrand : c.fgNeutral);
    final amountText = krwSigned(
      expense.signedAmount.abs(),
      flags.ofType(expense.expenseType),
      sign: income ? '+' : minusOf(expense.signedAmount.abs()),
      unit: true,
    );

    final badges = <Widget>[
      if (scheduled) PBadge(label: l.expScheduled),
      if (refunded) PBadge(label: l.expRefundedBadge),
      // 기록만 — 결제가 끝난 회차에 뒤늦게 적은 카드 지출(닫힌 회차 R2). 합계에는 들어간다.
      if (expense.isRecordOnly) PBadge(label: l.expRecordOnlyBadge),
      // 고정 수입·지출 — 환불된 거래는 합계에서 빠져 있어 표시할 이유가 없다.
      if (expense.isFixed && !refunded)
        PBadge(label: l.fixedBadge, tone: PBadgeTone.brand),
      // 분할 거래 — 분할 아이콘 + 개수
      if (expense.splitCategoryRowIds.isNotEmpty)
        PBadge(
          label: '${expense.splitCategoryRowIds.length}',
          prefixIcon: LucideIcons.split,
          tone: PBadgeTone.brand,
        ),
    ];

    final title = expense.merchant ?? expense.description ?? cName;
    final detail = PTagGroup(
      size: PTagGroupSize.t3,
      overflow: PTagGroupOverflow.truncate,
      items: [
        // 줄어드는 것은 이름 항목이다 — 카테고리 1 · 자산 2, 할부 · 시각은 줄지 않는다(tag-group.md "줄어드는 정도" — 긴 카테고리에서 시각이
        // 잘리거나 겹치지 않게. 웹 ExpenseRow 와 같은 값)
        PTag(cName, shrink: 1),
        PTag(expense.assetName ?? '-', shrink: 2),
        if (showInstallment && (expense.installmentMonths ?? 1) > 1)
          PTag(l.assetInstallmentBadge(expense.installmentMonths!), shrink: 0),
        // 시각 — 분류 · 자산 · 시각 차례(tag-group.md:84), 줄지 않는다. 00:00 이면 두지 않는다
        if (txTimeLabel(expense.expenseDate) case final time?)
          PTag(time, shrink: 0),
      ],
    );
    final prefix = PListTile(background: bg, color: fg, child: Icon(icon));
    // 부호는 **손으로** 붙인다 — U+2212 와 tabular figures 정렬(QA #22). 금액은 쉼표 뒤에서만 줄을 바꾼다.
    final amountNode = PListValue.amount(
      amountText,
      style: TextStyle(
        color: amountColor,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        // 환불된 거래의 금액은 취소선 — 부호는 원래대로 둔다(지출은 −). 뜻은 배지 글이 말한다.
        decoration: refunded ? TextDecoration.lineThrough : null,
        decorationColor: refunded ? c.fgNeutralSubtle : null,
      ),
    );
    final suffix = amountNode;
    final titleColor = excluded ? c.fgNeutralSubtle : null;

    if (!interactive) {
      return PListItem(
        title: title,
        titleSuffix: badges,
        titleColor: titleColor,
        gutter: gutter,
        highlighted: highlighted,
        detailChild: detail,
        prefix: prefix,
        suffix: suffix,
      );
    }
    return PListButtonItem(
      title: title,
      titleSuffix: badges,
      titleColor: titleColor,
      gutter: gutter,
      highlighted: highlighted,
      detailChild: detail,
      prefix: prefix,
      suffix: suffix,
      onTap: onTap ?? () => showTxDetailDialog(context, expense),
    );
  }
}
