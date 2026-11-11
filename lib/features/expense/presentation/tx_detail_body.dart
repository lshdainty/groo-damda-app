import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/features/expense_split/domain/expense_split.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';

/// 거래 상세 · 이체 상세가 함께 쓰는 본문 조각(I-21 B · C). 상세는 읽는 상세다 — 머리(타일 + 이름 + 금액 + 날짜) → 상태 Callout →
/// 키-값 줄 → "더 하기" 동작 줄 → 내역 분할 → 이 가맹점 이번 달.

const double _rowIcon = 22;

/// 상세 머리 — 타일 48(모서리 14 = 크기 × 0.3) + 이름 t7 700(줄바꿈, 사이 12) · 금액 t9 700 고정폭(쉼표 뒤에서만 줄바꿈) · 날짜 t4.
/// 이름 줄 아래 12 · 금액 아래 2 · 날짜 아래 12(T7). 좌우 24.
class TxDetailHead extends StatelessWidget {
  const TxDetailHead({
    super.key,
    required this.tileBackground,
    required this.tileColor,
    required this.tileIcon,
    required this.name,
    required this.amountText,
    required this.amountColor,
    this.dateTime,
  });

  final Color tileBackground;
  final Color tileColor;
  final IconData tileIcon;
  final String name;

  /// 부호 · 단위까지 만든 금액 글 — 가리면 점이다.
  final String amountText;
  final Color amountColor;
  final String? dateTime;

  /// 타일 한 변.
  static const double tile = 48;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      key: const ValueKey('tx-detail-head'),
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        0,
        PSpacing.globalGutter,
        PSpacing.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: tile,
                  child: DecoratedBox(
                    key: const ValueKey('tx-detail-tile'),
                    decoration: BoxDecoration(
                      color: tileBackground,
                      borderRadius: BorderRadius.circular(PRounded.r3_5),
                    ),
                    child: Icon(tileIcon, size: 24, color: tileColor),
                  ),
                ),
              ),
              const SizedBox(width: PSpacing.x3),
              Expanded(
                child: Text(
                  keepAll(name),
                  key: const ValueKey('tx-detail-name'),
                  semanticsLabel: name,
                  style: PTypography.t7.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpacing.x3),
          Text(
            keepAllAmount(amountText),
            key: const ValueKey('tx-detail-amount'),
            semanticsLabel: amountText,
            style: PTypography.t9.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (dateTime != null) ...[
            const SizedBox(height: PSpacing.x0_5),
            Text(
              dateTime!,
              key: const ValueKey('tx-detail-datetime'),
              style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
        ],
      ),
    );
  }
}

/// 상태 Callout 한 칸 — 좌우 24 · 위 4 · 아래 12(T8).
class TxStatusSlot extends StatelessWidget {
  const TxStatusSlot({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x1,
      PSpacing.globalGutter,
      PSpacing.x3,
    ),
    child: child,
  );
}

/// 환불됨 · 기록만 · 자동 거래 Callout(neutral) — 있을 때만, 이 차례로. [actions] 는 Callout 안 본문 아래 작은 버튼(환불됨의
/// [잔액 고치기][환불 취소]).
class TxNoticeCallout extends StatelessWidget {
  const TxNoticeCallout({
    super.key,
    required this.icon,
    required this.text,
    this.actions = const [],
  });

  final IconData icon;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => TxStatusSlot(
    child: PCallout(icon: icon, description: text, actions: actions),
  );
}

/// 요청 실패 알림(critical) — 서버가 낸 글이 아니라 우리 글이다. 시트 안 보이는 자리에 둔다(스낵바는 시트 위에 뜨지만, 상세의 실패는 자기 자리에서 말한다).
class TxFailureCallout extends StatelessWidget {
  const TxFailureCallout({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x1,
        PSpacing.globalGutter,
        PSpacing.x3,
      ),
      child: PCallout(
        key: const ValueKey('tx-detail-failure'),
        tone: PCalloutTone.critical,
        description: message,
        alert: true,
        link: onRetry == null
            ? null
            : PCalloutLink(label: l.actionRetry, onPressed: onRetry!),
      ),
    );
  }
}

/// 키-값 줄 — 열쇠 t5 `fg-neutral`, 값은 줄 끝 오른쪽 맞춤(`fg-neutral-muted`, 몇 줄이든 마지막 글자가 오른쪽 끝에 맞는다). 값이 없으면
/// 줄을 그리지 않는다. 값은 글 [Text] 하나로 넘긴다 — ds List 가 값으로 읽어 폭 제한을 건다(큰 글자에서 제목 아래로 내려가면 ds
/// 규칙대로 왼쪽 맞춤이다 — list.md "큰 글자에서 값을 본문 아래로").
class TxKvRow extends StatelessWidget {
  const TxKvRow({super.key, required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return PListItem(title: label, suffix: txKvValue(context, value!));
  }
}

/// 값 위젯 — 줄 수와 상관없이 오른쪽 맞춤(규칙 ①).
Widget txKvValue(BuildContext context, String value, {Color? color}) {
  final c = context.colors;
  // 값 노드(PListValue)라야 ds List 가 값으로 읽는다(본문 최소 폭만 남기고 줄고, 좁으면 본문 아래로 내려간다).
  // 칸 폭을 보고 띄어쓰기에서 먼저 넘기고 쉼표 · 구간 기호 뒤는 낱말 하나가 칸보다 길 때만 꺾는다.
  return PListValue.fit(
    value,
    style: TextStyle(color: color ?? c.fgNeutralMuted),
  );
}

/// 키-값 목록 — 줄 사이 선 없음.
class TxKvList extends StatelessWidget {
  const TxKvList({super.key, required this.rows, this.semanticLabel});
  final List<TxKvRow> rows;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final r in rows)
        if (r.value != null && r.value!.isNotEmpty) r,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('tx-detail-kv'),
      padding: const EdgeInsets.only(top: PSpacing.x1),
      child: PList(semanticLabel: semanticLabel, children: shown),
    );
  }
}

/// "더 하기" 한 줄.
class TxMoreRow {
  const TxMoreRow({
    required this.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.disabled = false,
  });

  final String key;
  final IconData icon;
  final String label;

  /// 연결 수 글 — "연결됨" · "3건" · "2개로 나눔". 없으면 값 글 없음.
  final String? value;

  /// 막힌 줄 — 누름 없음, 제목 · 아이콘 비활성 색, 꺾쇠 없음(자동 거래의 반복 · 더치페이).
  final bool disabled;
  final VoidCallback? onTap;
}

/// 묶음 제목(List Header boldSolid) — 오른쪽 값 글이 있으면 그 자리에 둔다.
class TxSectionHeader extends StatelessWidget {
  const TxSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.topInset = PSpacing.x2,
  });
  final String title;
  final Widget? trailing;

  /// 위 여백 — 같은 시트 안 다른 묶음을 가르는 목록 제목은 위 8 + 제목 위아래 8(T9).
  final double topInset;

  @override
  Widget build(BuildContext context) => PListHeader(
    title: title,
    variant: PListHeaderVariant.boldSolid,
    headingLevel: 3,
    topInset: topInset,
    trailing: trailing,
  );
}

/// "더 하기" 동작 줄 — 환불 · 내역 분할 · 반복 설정 · 더치페이(2-A). 앞 아이콘 22 `fg-neutral`, 값 + 꺾쇠.
class TxMoreSection extends StatelessWidget {
  const TxMoreSection({super.key, required this.rows});
  final List<TxMoreRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      key: const ValueKey('tx-detail-more'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TxSectionHeader(title: l.expDetailMore),
        PList(
          semanticLabel: l.expDetailMore,
          children: [
            for (final r in rows)
              PListButtonItem(
                key: ValueKey('more-${r.key}'),
                title: r.label,
                prefix: Icon(r.icon, size: _rowIcon, color: c.fgNeutral),
                onTap: r.disabled ? null : r.onTap,
                suffix: r.disabled
                    ? null
                    : PListSuffix(
                        children: [
                          if (r.value != null)
                            Text(
                              r.value!,
                              style: PTypography.t4.copyWith(
                                color: c.fgNeutralSubtle,
                              ),
                            ),
                          const ExcludeSemantics(
                            child: Icon(LucideIcons.chevronRight),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "내역 분할 n개" 묶음 — 접지 않는다. 막대 8 + 줄(누르지 않는다).
class TxSplitSection extends StatelessWidget {
  const TxSplitSection({
    super.key,
    required this.splits,
    required this.categories,
    required this.total,
    required this.isIncome,
    required this.masked,
  });

  final List<ExpenseSplit> splits;
  final List<ExpenseCategory> categories;
  final int total;
  final bool isIncome;

  /// 머리 금액과 같은 값이라 같이 가린다.
  final bool masked;

  Color _colorOf(BuildContext context, int categoryRowId) => resolveChartColor(
    context,
    categories.byRowId(categoryRowId)?.color,
    fallback: context.colors.fgBrand,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      key: const ValueKey('tx-detail-split'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TxSectionHeader(
          title: l.expSplitHeader(splits.length),
          trailing: Text(
            keepAllAmount('${l.expTotal} ${txMoney(total, masked)}'),
            semanticsLabel: '${l.expTotal} ${txMoney(total, masked)}',
            style: PTypography.t4.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            0,
            PSpacing.globalGutter,
            PSpacing.x2,
          ),
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PRounded.full),
              child: SizedBox(
                key: const ValueKey('tx-detail-split-bar'),
                height: PSpacing.x2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.bgNeutralWeak),
                  child: Row(
                    children: [
                      for (final s in splits)
                        if (total > 0 && s.amount > 0)
                          Flexible(
                            flex: s.amount,
                            child: ColoredBox(
                              color: _colorOf(context, s.categoryRowId),
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        PList(
          semanticLabel: l.expSplitHeader(splits.length),
          children: [for (final s in splits) _splitRow(context, s)],
        ),
      ],
    );
  }

  Widget _splitRow(BuildContext context, ExpenseSplit s) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final cat = categories.byRowId(s.categoryRowId);
    final parent = cat?.parentRowId == null
        ? null
        : categories.byRowId(cat!.parentRowId!);
    final fg = _colorOf(context, s.categoryRowId);
    final pct = formatShareOf(s.amount, total, underOne: l.percentUnderTenth);
    final title = (s.label?.trim().isNotEmpty ?? false)
        ? s.label!
        : (s.categoryName ?? l.expItem);
    final amountText = krwSigned(
      s.amount,
      masked,
      sign: isIncome ? '+' : kMinus,
      unit: true,
    );
    return PListItem(
      title: title,
      prefix: PListTile(
        background: softBg(context, fg),
        color: fg,
        child: Icon(lucideByName(cat?.icon, fallback: LucideIcons.tag)),
      ),
      detailChild: PTagGroup(
        size: PTagGroupSize.t3,
        overflow: PTagGroupOverflow.truncate,
        items: [
          // 좁은 줄(큰 글자)에서도 비율이 잘리지 않게 — 줄어드는 쪽은 상위 · 카테고리 이름이고 비율은 줄지 않는다
          if (parent != null) PTag(parent.categoryName, shrink: 2),
          PTag(s.categoryName ?? '-', shrink: 1),
          PTag(pct, shrink: 0),
        ],
      ),
      suffix: PListValue.amount(
        amountText,
        style: TextStyle(
          color: c.fgNeutral,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// 나눈 내역을 못 불러왔을 때 — 묶음 자리 Result Section(medium failure). 앱 원문 걷음.
class TxSplitFailure extends StatelessWidget {
  const TxSplitFailure({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });
  final VoidCallback onRetry;

  /// 실패 뒤 다시 받는 중 — [다시 시도] 에 진행 원(skeleton.md:139).
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PResultSection(
      key: const ValueKey('tx-detail-split-failure'),
      kind: PResultKind.failure,
      size: PResultSize.medium,
      title: l.expSplitLoadFailed,
      description: l.expSplitLoadFailedDesc,
      primaryAction: PResultAction(
        label: l.actionRetry,
        loading: retrying,
        onPressed: onRetry,
      ),
    );
  }
}

/// "이 가맹점 이번 달"(이전 거래)을 처음 받지 못했을 때 — 그 자리 Result Section medium + [다시 시도]. 글은 웹
/// `query.failedNamed`(name: `txDetail.historyName`) 와 같다.
class TxHistoryFailure extends StatelessWidget {
  const TxHistoryFailure({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });
  final VoidCallback onRetry;

  /// 실패 뒤 다시 받는 중 — [다시 시도] 에 진행 원(skeleton.md:139).
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PResultSection(
      key: const ValueKey('tx-detail-history-failure'),
      kind: PResultKind.failure,
      size: PResultSize.medium,
      title: l.txHistoryLoadFailed,
      description: l.expSplitLoadFailedDesc,
      primaryAction: PResultAction(
        label: l.actionRetry,
        loading: retrying,
        onPressed: onRetry,
      ),
    );
  }
}

/// 나눈 내역 불러오는 중 — 머리 + 줄 Skeleton 둘.
class TxSplitSkeleton extends StatelessWidget {
  const TxSplitSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('tx-detail-split-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          PSpacing.x4,
          PSpacing.globalGutter,
          PSpacing.x2,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: PSkeleton.text(PTypography.t4, width: 112),
        ),
      ),
      for (var i = 0; i < 2; i++)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
            vertical: PSpacing.x3,
          ),
          child: Row(
            spacing: PSpacing.x3,
            children: [
              const PSkeleton(
                width: 40,
                height: 40,
                radius: PSkeletonRadius.r12,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PSkeleton.text(PTypography.t5, width: 128),
                ),
              ),
              PSkeleton.text(PTypography.t5, width: 64),
            ],
          ),
        ),
    ],
  );
}

/// "이 가맹점 이번 달" 묶음 — 줄을 누르지 않는다. 다른 거래가 5건을 넘으면 끝에 보조 글 "최근 5건만 보여요".
class TxHistorySection extends StatelessWidget {
  const TxHistorySection({
    super.key,
    required this.history,
    required this.categories,
    required this.flags,
    required this.isIncome,
    required this.masked,
  });

  final TxHistory history;
  final List<ExpenseCategory> categories;
  final MaskFlags flags;
  final bool isIncome;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final total = krwSigned(
      history.monthTotal,
      masked,
      sign: isIncome ? '+' : kMinus,
      unit: true,
    );
    final headerRight = '${l.expTxCount(history.monthCount)} · $total';
    return Column(
      key: const ValueKey('tx-detail-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TxSectionHeader(
          title: l.expMerchantMonth,
          trailing: Text(
            keepAllAmount(headerRight),
            semanticsLabel: headerRight,
            style: PTypography.t4.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        for (final (day, items) in txHistoryByDay(history.rows)) ...[
          _DayHead(day: day),
          for (final h in items)
            ExpenseRow(
              expense: h,
              category: h.categoryRowId == null
                  ? null
                  : categories.byRowId(h.categoryRowId!),
              flags: flags,
              interactive: false,
            ),
        ],
        if (history.overflow)
          Padding(
            key: const ValueKey('tx-detail-recent-only'),
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x1,
              PSpacing.globalGutter,
              PSpacing.x3,
            ),
            child: PText(
              l.expRecentOnly,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
      ],
    );
  }
}

/// 날짜 묶음 머리 — 가계부와 같은 부품(List Header mediumWeak 값). 요일까지 붙은 "10월 28일 (수)".
class _DayHead extends StatelessWidget {
  const _DayHead({required this.day});
  final String day;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(day);
    return PDayHeaderRow(text: d == null ? day : monthDayDow(d));
  }
}

/// 상세 불러오는 중 — 타일 48 · 이름 한 줄 · 금액 · 날짜 · 키-값 넷 · "더 하기" 줄 넷.
class TxDetailSkeleton extends StatelessWidget {
  const TxDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('tx-detail-skeleton'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          0,
          PSpacing.globalGutter,
          PSpacing.x3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: PSpacing.x3,
              children: [
                const PSkeleton(
                  width: 48,
                  height: 48,
                  radius: PSkeletonRadius.r16,
                ),
                PSkeleton.text(PTypography.t7, width: 160),
              ],
            ),
            const SizedBox(height: PSpacing.x3),
            PSkeleton.text(PTypography.t9, width: 208),
            const SizedBox(height: PSpacing.x0_5),
            PSkeleton.text(PTypography.t4, width: 128),
          ],
        ),
      ),
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
            vertical: PSpacing.x3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PSkeleton.text(PTypography.t5, width: 64),
              PSkeleton.text(PTypography.t5, width: 112),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          PSpacing.x4,
          PSpacing.globalGutter,
          PSpacing.x2,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: PSkeleton.text(PTypography.t4, width: 64),
        ),
      ),
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
            vertical: PSpacing.x3,
          ),
          child: Row(
            spacing: PSpacing.x3,
            children: [
              const PSkeleton(width: 24, height: 24),
              PSkeleton.text(PTypography.t5, width: 96),
            ],
          ),
        ),
    ],
  );
}
