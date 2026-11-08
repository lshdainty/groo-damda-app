import 'package:flutter/material.dart';

import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/forms/month_row.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

// 예산 · 예산 설정 · 저축 목표가 함께 쓰는 틀 — 띠 · 구역 · 머리 · 달 줄 · 큰 숫자 · 키-값 · 카테고리 줄 · 실패 (I-08 공통 값).
// 홈(dashboard_screen.dart)의 구역 틀과 같은 값이다 — 구역이 제 위아래 여백을 갖고(글 24 · 24, 목록 24 · 12), 띠 안 구역 사이는
// 앞 구역 아래 24 + 다음 머리 위 24 = 48.

const tabularFigures = [FontFeature.tabularFigures()];
const kBudgetMask = '••••';

/// 띠 하나 — 화면 폭 흰 면. 안 구역이 제 위아래 여백을 가진다.
Widget budgetBand(List<Widget> sections) => PScreenSection(
  padding: EdgeInsets.zero,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: sections,
  ),
);

/// 구역 머리가 읽는 카드 값(글 구역 = 머리 아래 8, 목록 구역 = 위 24 · 아래 4)과 머리 동작의 누르는 영역 44.
class BudgetScope extends StatelessWidget {
  const BudgetScope({super.key, required this.body, required this.child});

  final PCardBody body;
  final Widget child;

  @override
  Widget build(BuildContext context) => PCardScope(
    variant: PCardVariant.standard,
    body: body,
    child: PTouchTargetScope(child: child),
  );
}

/// 좌우 24 를 받지 않는 자식(목록 · 키-값 줄은 줄이 제 24 를 갖는다)을 [BudgetSection] 안에서 표시한다.
class BudgetFull extends StatelessWidget {
  const BudgetFull({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// 글 · 숫자 · 차트 구역 — 위 [topPadding](24, 달 줄 바로 아래는 12) · 아래 24 · 좌우 24, 머리 ↔ 본문 8.
class BudgetSection extends StatelessWidget {
  const BudgetSection({
    super.key,
    this.header,
    required this.children,
    this.topPadding = PSpacing.x6,
  });

  final Widget? header;
  final List<Widget> children;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    Widget pad(Widget w) => w is BudgetFull
        ? w.child
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: w,
          );
    return BudgetScope(
      body: PCardBody.content,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: PSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [if (header != null) pad(header!), ...children.map(pad)],
        ),
      ),
    );
  }
}

/// 목록 구역 — 머리 위 24 · 좌우 24 · 아래 4, 줄이 제 좌우 24 · 위아래 12, 구역 아래 12.
class BudgetListSection extends StatelessWidget {
  const BudgetListSection({
    super.key,
    required this.header,
    required this.children,
  });

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => BudgetScope(
    body: PCardBody.list,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        ...children,
        const SizedBox(height: PSpacing.x3),
      ],
    ),
  );
}

/// 구역 머리 — 제목 R4 + (오른쪽 보조 글 | 제목 뒤 덧붙임 | 오른쪽 글 버튼).
class BudgetHead extends StatelessWidget {
  const BudgetHead({
    super.key,
    required this.title,
    this.note,
    this.trailing,
    this.suffix,
    this.actionLabel,
    this.onAction,
    this.titleChild,
  }) : assert(
         titleChild == null || note != null || trailing != null,
         '제목을 위젯으로 줄 때는 오른쪽 보조 글 · 위젯과 함께 쓴다(통계 도넛의 "카테고리별 지출 › 부모")',
       );

  final String title;

  /// 제목 글 대신 두는 위젯(눌러서 되돌아가는 제목) — [title] 은 읽는 이름으로 남는다.
  final Widget? titleChild;

  /// 오른쪽 보조 글(t3 · fg-neutral-subtle).
  final String? note;

  /// 머리 오른쪽 끝 위젯(페이스 Badge).
  final Widget? trailing;

  /// 제목 바로 뒤 덧붙임.
  final Widget? suffix;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (note == null && trailing == null) {
      return PCardHeader(
        title: title,
        titleSuffix: suffix,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }
    final scope = PCardScope.maybeOf(context);
    final list = (scope?.body ?? PCardBody.content) != PCardBody.content;
    final c = context.colors;
    return Padding(
      padding: list
          ? const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x6,
              PSpacing.x6,
              PSpacing.x1,
            )
          : const EdgeInsets.only(bottom: PSpacing.x2),
      child: PHeaderRow(
        gap: PSpacing.x2,
        title: Semantics(
          header: true,
          headingLevel: 2,
          child:
              titleChild ??
              Text(
                keepAll(title),
                semanticsLabel: title,
                style: PTypography.t5.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w700,
                ),
              ),
        ),
        action:
            trailing ??
            Text(
              keepAll(note!),
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
      ),
    );
  }
}

/// 달 줄 — 달 글 + 꺾쇠와 오른쪽 동작. 띠 맨 위 4 + 한 줄(44). 달 글을 누르면 달 고르기. 줄 조각은 캘린더와 같은 [MonthRow].
class BudgetMonthRow extends StatelessWidget {
  const BudgetMonthRow({
    super.key,
    required this.month,
    required this.onPick,
    required this.trailing,
  });

  final DateTime month;
  final VoidCallback onPick;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => MonthRow(
    month: month,
    onPick: onPick,
    trailing: trailing,
    // 달 글 상자 안 여백 10 만큼 덜어 글이 화면 여백 24 에 선다
    padding: const EdgeInsets.fromLTRB(
      PSpacing.globalGutter - PSpacing.x2_5,
      // 띠 맨 위 4 + 8
      PSpacing.x3,
      PSpacing.x6,
      0,
    ),
    labelStyle: PTypography.t5,
    tabularFigures: true,
  );
}

/// 눈썹 글 "{n}월 총 예산" — t3 13/18 · 700 · fg-brand.
class BudgetEyebrow extends StatelessWidget {
  const BudgetEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    keepAll(text),
    style: PTypography.t3.copyWith(
      color: context.colors.fgBrand,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// 문장으로 된 보조 글 — t3 · fg-neutral-muted.
class BudgetDesc extends StatelessWidget {
  const BudgetDesc(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    keepAll(text),
    style: PTypography.t3.copyWith(color: context.colors.fgNeutralMuted),
  );
}

/// 큰 숫자 — t9 24/32 · 700 · 고정폭 · 원까지(쉼표 뒤에서만 줄바꿈), 뒤 "/ 한도" t4 · subtle 같은 줄(좁으면 다음 줄).
class BudgetBigAmount extends StatelessWidget {
  const BudgetBigAmount({
    super.key,
    required this.amount,
    this.limit,
    this.color,
  });

  final String amount;
  final String? limit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: PSpacing.x2,
      children: [
        Text(
          keepAllAmount(amount),
          semanticsLabel: amount,
          style: PTypography.t9.copyWith(
            color: color ?? c.fgNeutral,
            fontWeight: FontWeight.w700,
            fontFeatures: tabularFigures,
          ),
        ),
        if (limit != null)
          Text(
            keepAllAmount('/ $limit'),
            semanticsLabel: '/ $limit',
            style: PTypography.t4.copyWith(
              color: c.fgNeutralSubtle,
              fontFeatures: tabularFigures,
            ),
          ),
      ],
    );
  }
}

/// 구역의 막대 — ProgressBar 8, 넘치면 fg-critical 끝까지.
class BudgetBar extends StatelessWidget {
  const BudgetBar({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    this.valueText,
    this.meaning = PProgressMeaning.limit,
  });

  final double value;
  final double max;
  final String label;

  /// 읽는 값 글 — 없으면 "{n}%".
  final String? valueText;
  final PProgressMeaning meaning;

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max * 100) : 0.0;
    return PProgressBar(
      value: value,
      max: max,
      meaning: meaning,
      semanticsLabel: label,
      semanticsValue: valueText ?? formatProgress(pct),
    );
  }
}

/// 막대 아래 한 줄 — 왼쪽 · 오른쪽 t3(오른쪽만 색을 줄 수 있다).
///
/// 오른쪽 글(예: "N원 초과")은 제 폭만 쓰고 줄 끝에 선다. 왼쪽 글이 남은 폭을 다 쓰며, 숫자는 쉼표 뒤에서만 꺾인다.
/// [right] 가 비면 오른쪽 칸을 두지 않는다 — 왼쪽 글이 줄 폭을 다 쓴다.
class BudgetBarCaption extends StatelessWidget {
  const BudgetBarCaption({
    super.key,
    required this.left,
    required this.right,
    this.rightColor,
    this.rightBold = false,
  });

  final String left;
  final String right;
  final Color? rightColor;
  final bool rightBold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = PTypography.t3.copyWith(
      color: c.fgNeutralSubtle,
      fontFeatures: tabularFigures,
    );
    final leftText = Text(
      keepAllAmount(left),
      semanticsLabel: left,
      style: base,
    );
    if (right.isEmpty) return leftText;
    return LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: leftText),
          const SizedBox(width: PSpacing.x2),
          // 제 폭만(줄 폭의 60% 까지) — 왼쪽이 나머지를 쓴다
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
            child: Text(
              keepAllAmount(right),
              semanticsLabel: right,
              textAlign: TextAlign.end,
              style: base.copyWith(
                color: rightColor,
                fontWeight: rightBold ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 키-값 줄 목록 — List 보기만 하는 줄(이름 R6 · 값 t5 · 700 · 고정폭 · 원까지). 폰은 한 줄에 하나.
class BudgetKv {
  const BudgetKv(this.name, this.value, {this.color});

  final String name;
  final String value;
  final Color? color;
}

Widget budgetKvList(BuildContext context, List<BudgetKv> rows) {
  final c = context.colors;
  return BudgetFull(
    child: PList(
      children: [
        for (final r in rows)
          PListItem(
            title: r.name,
            verticalPadding: PSpacing.x2,
            suffix: PListValue.amount(
              r.value,
              style: TextStyle(
                color: r.color ?? c.fgNeutral,
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
      ],
    ),
  );
}

/// 안내 한 줄 — R9 가운데.
class BudgetEmptyLine extends StatelessWidget {
  const BudgetEmptyLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.x6,
      vertical: PSpacing.x3,
    ),
    child: Center(
      child: Text(
        keepAll(text),
        textAlign: TextAlign.center,
        style: PTypography.t3.copyWith(color: context.colors.fgNeutralSubtle),
      ),
    ),
  );
}

/// 한 질의가 실패한 구역 — 그 안에서 Result Section 으로 알리고 그 질의만 다시 받는다(오류 원문은 그리지 않는다).
class BudgetFailure extends StatelessWidget {
  const BudgetFailure({
    super.key,
    required this.title,
    required this.onRetry,
    this.retrying = false,
  });

  final String title;
  final VoidCallback onRetry;

  /// 실패 뒤 다시 받는 중 — [다시 시도] 에 진행 원(skeleton.md:139).
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PResultSection(
      kind: PResultKind.failure,
      size: PResultSize.medium,
      title: title,
      description: l.dashFailDesc,
      headingLevel: 3,
      placement: PResultPlacement.card,
      primaryAction: PResultAction(
        label: l.actionRetry,
        loading: retrying,
        onPressed: onRetry,
      ),
    );
  }
}

/// 금액 글 — 원까지, 가리면 점.
String budgetWon(int n, bool masked, {String sign = ''}) =>
    krwSigned(n, masked, sign: sign, unit: true, mask: kBudgetMask);

/// 카테고리 예산 줄 이름 — 카테고리 → 예산에 적힌 이름 → 번호 순.
String budgetRowName(
  AppLocalizations l,
  ExpenseCategory? category,
  Budget budget,
) =>
    category?.categoryName ??
    budget.categoryName ??
    l.budgetCategoryFallback(budget.categoryRowId!);

/// 카테고리 예산 줄 — 앞 타일 40 · 제목(줄바꿈) · 설명 · 뒤 두 줄(쓴 돈 · / 한도) + 아래 ProgressBar 8.
/// [onTap] 이 있으면 누르는 줄(수정), 없으면 보기만 하는 줄.
class BudgetCategoryRow extends StatelessWidget {
  const BudgetCategoryRow({
    super.key,
    required this.budget,
    required this.category,
    required this.spent,
    required this.masked,
    this.onTap,
    this.overText,
  });

  final Budget budget;
  final ExpenseCategory? category;
  final int spent;
  final bool masked;
  final VoidCallback? onTap;

  /// 넘침 설명 글 — 주지 않으면 "한도 {금액} 초과".
  final String Function(String amount)? overText;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final limit = budget.budgetAmount;
    final over = spent > limit;
    final fg = resolveChartColor(context, category?.color, fallback: c.fgBrand);
    final name = budgetRowName(l, category, budget);
    String amountOf(int n) => budgetWon(n, masked);
    final detail = over
        ? (overText ?? l.budgetOverBy)(amountOf(spent - limit))
        : l.budgetRemaining(amountOf((limit - spent).clamp(0, limit)));
    final tile = PListTile(
      background: softBg(context, fg),
      color: fg,
      child: Icon(lucideByName(category?.icon)),
    );
    final detailChild = Text(
      keepAll(detail),
      style: TextStyle(
        color: over ? c.fgCritical : c.fgNeutralSubtle,
        fontFeatures: tabularFigures,
      ),
    );
    final suffix = PListValue(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keepAllAmount(amountOf(spent)),
            semanticsLabel: amountOf(spent),
            textAlign: TextAlign.end,
            style: PTypography.t5.copyWith(
              color: over ? c.fgCritical : c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: tabularFigures,
            ),
          ),
          Text(
            keepAllAmount('/ ${amountOf(limit)}'),
            semanticsLabel: '/ ${amountOf(limit)}',
            textAlign: TextAlign.end,
            style: PTypography.t3.copyWith(
              color: c.fgNeutralSubtle,
              fontWeight: FontWeight.w500,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        onTap == null
            ? PListItem(
                title: name,
                detailChild: detailChild,
                prefix: tile,
                suffix: suffix,
              )
            : PListButtonItem(
                title: name,
                detailChild: detailChild,
                prefix: tile,
                suffix: suffix,
                onTap: onTap,
              ),
        // 줄 아래 16 에 막대(줄 안 12 + 4), 막대 아래 12
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x1,
            PSpacing.x6,
            PSpacing.x3,
          ),
          child: BudgetBar(
            value: spent.toDouble(),
            max: limit.toDouble(),
            label: l.dashBudgetOf(name),
          ),
        ),
      ],
    );
  }
}
